#!/usr/bin/env python3
"""
gen-bc-traceability — regenerate Architecture Module rows in BC Traceability tables
====================================================================================
Reads bc-module-map.md (canonical BC → module mapping) and updates every BC file's
"Architecture Module" row in its ## Traceability section.

WHY THIS EXISTS (BI-012):
  bc-module-map.md v1.3+ holds the CORRECT ADR values (ADR-008 for SS-06,
  ADR-003 for BC-2.05.003). Without a generator, fixes to bc-module-map.md must
  be manually back-propagated to 66 BC files — a class of recurring divergence.

MARKER STRATEGY:
  The Architecture Module row is wrapped with:
    <!-- @GENERATED:BEGIN bc-arch-module -->
    <!-- @GENERATED:END bc-arch-module -->
  On first run (no markers): the generator finds the existing Architecture Module
  row and wraps it with markers + updated value.
  On re-runs (markers exist): the generator replaces content between markers.

READ-ONLY with respect to canonical-facts.toml — never writes to that file.

DEFAULT-SAFE POLICY (concurrency gate):
  Bare invocation with no arguments does NOT write. A concurrent editor may
  hold .factory/specs/ at any time, and an accidental bare invocation is a
  realistic failure mode. Explicit opt-in required: use --write to enable
  write mode. --check and --dry-run are always available without opt-in.

  Even with --write present, a SECOND independent gate (BI-041) refuses write
  mode until hand-authored annotation loss is adjudicated — see below.

Usage:
  python3 gen-bc-traceability.py [--check] [--dry-run] [--write]

--check mode: regenerates all Architecture Module rows in memory, compares
  each BC file byte-for-byte against its committed content, exits 0 if
  identical, exits 1 with a unified diff if any file differs. Never writes.
  NOTE: --check currently returns FAIL (786 diff lines across 66 BC files)
  on the live tree. This is expected pre-adjudication — the @GENERATED markers
  have not yet been added to any BC file.

--dry-run mode: previews what would be written without modifying any file.

--write mode: explicit opt-in for write mode. Still blocked by the BI-041
  guard until annotation loss is adjudicated.
"""
import difflib
import os
import re
import sys
from pathlib import Path

REPO = Path(os.environ.get("SPEC_LINT_REPO_OVERRIDE", "")).resolve() if os.environ.get("SPEC_LINT_REPO_OVERRIDE") else Path(__file__).resolve().parent.parent.parent
SPECS = REPO / ".factory" / "specs"
BC_DIR = SPECS / "behavioral-contracts"
BC_MODULE_MAP = SPECS / "architecture" / "bc-module-map.md"
ADR_DIR = SPECS / "architecture" / "decisions"

BEGIN_MARKER = "<!-- @GENERATED:BEGIN bc-arch-module -->"
END_MARKER   = "<!-- @GENERATED:END bc-arch-module -->"


def load_adr_titles() -> dict[str, str]:
    """Load short ADR titles from ADR files (strip 'ADR-NNN: ' prefix)."""
    titles: dict[str, str] = {}
    if not ADR_DIR.exists():
        return titles
    for adr_file in sorted(ADR_DIR.glob("ADR-*.md")):
        m = re.match(r"(ADR-\d+)", adr_file.name)
        if not m:
            continue
        adr_id = m.group(1)
        text = adr_file.read_text(encoding="utf-8")
        h1 = re.search(r"^#\s+(ADR-\d+:\s+.+)$", text, re.MULTILINE)
        if h1:
            title = re.sub(r"^ADR-\d+:\s+", "", h1.group(1)).strip()
            titles[adr_id] = title
    return titles


def parse_bc_module_map() -> dict[str, dict]:
    """
    Parse bc-module-map.md to extract per-BC data.

    Returns {bc_id: {primary_module, secondary_module, pe, tier, key_adrs, formal_vps}}
    """
    if not BC_MODULE_MAP.exists():
        print(f"ERROR: bc-module-map.md not found at {BC_MODULE_MAP}", file=sys.stderr)
        sys.exit(1)

    text = BC_MODULE_MAP.read_text(encoding="utf-8")
    result: dict[str, dict] = {}

    for line in text.splitlines():
        # Match rows like: | BC-2.NN.NNN | `module` | ... | Pure | CRITICAL | ADR-NNN | ...
        m = re.match(
            r"^\|\s*(BC-\d+\.\d+\.\d+)\s*\|\s*(`[^`]+`)\s*\|([^|]*)\|([^|]*)\|([^|]*)\|([^|]*)\|([^|]*)\|",
            line,
        )
        if not m:
            continue
        bc_id         = m.group(1).strip()
        primary_raw   = m.group(2).strip()   # backtick-wrapped module name
        secondary_raw = m.group(3).strip()
        pe_raw        = m.group(4).strip()
        tier_raw      = m.group(5).strip()
        key_adrs_raw  = m.group(6).strip()
        formal_vps_raw = m.group(7).strip()

        # Strip backticks from primary module name
        primary_module = primary_raw.strip("`")

        # Secondary module: extract just the module name (before the space/paren)
        secondary_module = ""
        sm = re.match(r"`([^`]+)`", secondary_raw)
        if sm and secondary_raw != "—":
            secondary_module = sm.group(1)

        # Parse P/E: "Pure", "Effectful", "Pure / Effectful", "Effectful / Pure"
        pe = pe_raw.split("/")[0].strip()  # use primary P/E

        # Parse tier: use first token (primary)
        tier = tier_raw.split("/")[0].strip()

        # Parse key ADRs: comma-separated ADR IDs
        key_adrs = [a.strip() for a in key_adrs_raw.split(",") if re.match(r"ADR-\d+", a.strip())]

        # Parse formal VPs (just for reference, not currently written)
        formal_vps = [v.strip() for v in formal_vps_raw.split(",") if re.match(r"VP-\d+", v.strip())]

        result[bc_id] = {
            "primary_module":   primary_module,
            "secondary_module": secondary_module,
            "pe":               pe,
            "tier":             tier,
            "key_adrs":         key_adrs,
            "formal_vps":       formal_vps,
        }

    return result


def ss_id_from_bc(bc_id: str) -> str:
    """BC-2.06.001 → 'SS-06'"""
    m = re.match(r"BC-\d+\.(\d+)\.", bc_id)
    if m:
        return f"SS-{m.group(1)}"
    return "SS-??"


def pe_to_str(pe: str) -> str:
    """'Pure' → 'pure core', 'Effectful' → 'effectful shell'"""
    if pe.lower().startswith("pure"):
        return "pure core"
    if pe.lower().startswith("effectful"):
        return "effectful shell"
    return pe.lower()


def format_arch_module_value(bc_id: str, info: dict, adr_titles: dict[str, str]) -> str:
    """
    Build the canonical Architecture Module value string.

    Example: '`slug.rs` (SS-06, pure core, CRITICAL tier) — ADR-008 (Clean-Room github-slugger v2 Reimplementation)'
    """
    ss = ss_id_from_bc(bc_id)
    module = info["primary_module"]
    pe_str = pe_to_str(info["pe"])
    tier_str = info["tier"].upper()
    key_adrs = info["key_adrs"]

    # Format ADRs with their titles
    adr_parts: list[str] = []
    for adr in key_adrs:
        title = adr_titles.get(adr, "")
        if title:
            adr_parts.append(f"{adr} ({title})")
        else:
            adr_parts.append(adr)
    adrs_str = ", ".join(adr_parts) if adr_parts else "—"

    value = f"`{module}.rs` ({ss}, {pe_str}, {tier_str} tier) — {adrs_str}"

    # Add secondary module note if present
    sec = info.get("secondary_module", "")
    if sec:
        value += f"; secondary: `{sec}.rs`"

    return value


def compute_new_bc_content(content: str, arch_value: str) -> str | None:
    """
    Compute the updated BC file content given the new arch_value.
    Returns the new content string if the file would change, None if already current.

    Pure function — never reads or writes files.
    """
    original = content
    new_row = f"| Architecture Module | {arch_value} |"
    generated_block = f"{BEGIN_MARKER}\n{new_row}\n{END_MARKER}"

    # Case 1: markers already present — replace between them
    pattern = re.compile(
        re.escape(BEGIN_MARKER) + r".*?" + re.escape(END_MARKER),
        re.DOTALL,
    )
    if BEGIN_MARKER in content:
        new_content, n = pattern.subn(generated_block, content)
        if n == 0:
            return None  # markers present but replacement failed — warn handled by caller
        return new_content if new_content != original else None

    # Case 2: no markers — find existing Architecture Module row and wrap it
    arch_row_pattern = re.compile(
        r"^(\| Architecture Module \|[^\n]+\|)\s*$",
        re.MULTILINE,
    )
    m = arch_row_pattern.search(content)
    if m:
        new_content = content[:m.start()] + generated_block + content[m.end():]
        return new_content if new_content != original else None

    # Case 3: no Architecture Module row — append to Traceability table
    traceability_match = re.search(r"^## Traceability\b", content, re.MULTILINE)
    if not traceability_match:
        return None  # no Traceability section; skip handled by caller

    after_trace = content[traceability_match.end():]
    next_section = re.search(r"\n##\s", after_trace)
    if next_section:
        insert_pos = traceability_match.end() + next_section.start()
    else:
        insert_pos = len(content)

    new_content = content[:insert_pos] + f"\n{generated_block}\n" + content[insert_pos:]
    return new_content if new_content != original else None


def update_bc_file(bc_file: Path, arch_value: str, dry_run: bool) -> bool:
    """
    Update the Architecture Module row in a BC file.
    Returns True if file was changed (or would change in dry-run).

    FUNCTION-LEVEL WRITE GATE (BI-041): write mode is blocked at this level
    independently of main(). This prevents write mode from being reached via
    import, even when dry_run=False is passed directly. Remove alongside Gate 2
    in main() when BI-041 is adjudicated and annotation round-tripping is fixed.
    """
    content = bc_file.read_text(encoding="utf-8")
    new_content = compute_new_bc_content(content, arch_value)

    if new_content is None:
        # Either unchanged or a skip condition; check for the markers-present-but-failed case
        pattern = re.compile(re.escape(BEGIN_MARKER) + r".*?" + re.escape(END_MARKER), re.DOTALL)
        if BEGIN_MARKER in content:
            _, n = pattern.subn("", content)
            if n == 0:
                print(f"  WARNING: {bc_file.name}: markers found but replacement failed", file=sys.stderr)
        elif not re.search(r"^## Traceability\b", content, re.MULTILINE):
            print(f"  SKIP: {bc_file.name}: no ## Traceability section found")
        return False

    if not dry_run:
        # ── FUNCTION-LEVEL WRITE GATE (BI-041) ────────────────────────────────
        # Defense-in-depth backstop: blocks writes even when called via import
        # rather than through argv. This message intentionally contains "BI-041"
        # so test 26's grep assertion matches via this path when Gate 2 in main()
        # is absent (they are not independently mutation-verifiable for this reason).
        # Remove alongside Gate 2 when BI-041 is adjudicated.
        raise RuntimeError(
            f"update_bc_file({bc_file.name}): write mode blocked pending BI-041 "
            "adjudication. See Gate 2 guard in main(). Remove alongside Gate 2 "
            "when BI-041 is resolved."
        )
    return True


def main() -> int:
    check_mode = "--check" in sys.argv
    dry_run = "--dry-run" in sys.argv
    write_mode = "--write" in sys.argv

    # ── GATE 1: CONCURRENCY SAFETY (bare-invocation default-safe) ─────────────
    # Bare invocation must not write. A concurrent editor may hold .factory/specs/
    # at any time; an accidental bare invocation is a realistic failure mode (D-039
    # compliant: no bypass flag). Explicit --write opt-in required to proceed to
    # write mode. --check and --dry-run are always available without opt-in.
    #
    # Mutation-verify status: NOT independently verifiable for this generator.
    # Removing only Gate 1 does not flip selftest 27: bare invocation reaches Gate 2
    # (write_mode=False so Gate 2 skips), then hits the function-level RuntimeError
    # in update_bc_file before any write, still exiting non-zero with file unchanged.
    # The guard is correct and defense-in-depth contributes to the total protection,
    # but no single test can isolate Gate 1 alone from this generator. See selftest 28
    # (gen-slug-corpus) for an equivalent gate that IS fully mutation-verifiable
    # because that generator has no function-level write backstop.
    if not check_mode and not dry_run and not write_mode:
        print(
            "gen-bc-traceability: bare invocation does not write.\n"
            "  A concurrent editor may hold .factory/specs/ and accidental bare\n"
            "  invocation is a realistic failure mode. Explicit opt-in required.\n"
            "  Use --write to enable write mode (still subject to BI-041 gate).\n"
            "  Use --check to inspect divergence without writing.\n"
            "  Use --dry-run to preview changes without writing.",
            file=sys.stderr,
        )
        return 1

    # ── GATE 2: BI-041 WRITE-MODE GUARD ───────────────────────────────────────
    # gen-bc-traceability write mode is BLOCKED pending BI-041 adjudication.
    # This gate is INDEPENDENT of Gate 1: even when --write is explicitly present,
    # write mode is still refused until hand-authored annotation loss is resolved.
    #
    # The generator's model does not preserve hand-authored annotations in
    # Architecture Module rows. Running write mode silently destroys INC-MAP
    # traceability obligations and other human-authored notes, including:
    #
    #   INC-MAP-002  (BC-2.03.002) — non-http clean verdict routing obligation
    #   INC-MAP-003  (BC-2.14.002) — invalid glob exits via config_error: bool
    #   INC-MAP-004  (BC-2.01.003) — VP-016 formal assignment to anchor_table
    #   ... and any future hand-authored annotations in Architecture Module rows
    #
    # Until BI-041 is adjudicated (generator updated to round-trip annotations
    # OR annotations migrated outside the generated block), write mode must
    # refuse to prevent irreversible data loss in .factory/specs/.
    #
    # --check mode is NOT blocked and remains fully functional (non-destructive).
    # --dry-run mode is NOT blocked (it never writes files).
    #
    # Mutation-verify status: NOT independently verifiable for this gate alone.
    # Removing only Gate 2 does not flip selftest 26: --write then reaches the
    # function-level RuntimeError in update_bc_file, which also prints "BI-041"
    # in its message. Test 26 checks grep for "BI-041", which still matches via
    # the function-level guard. Both Gate 2 AND the function-level guard must be
    # removed simultaneously for --write to actually write files and exit 0.
    if write_mode:
        print(
            "gen-bc-traceability: BLOCKED — write mode disabled pending BI-041 adjudication.\n"
            "  The generator destroys hand-authored INC-MAP annotations (INC-MAP-002,\n"
            "  INC-MAP-003, INC-MAP-004) and any other notes in Architecture Module rows.\n"
            "  Use --check to inspect divergence without writing.\n"
            "  Use --dry-run to preview changes without writing.\n"
            "  Resolve BI-041 before enabling write mode.",
            file=sys.stderr,
        )
        return 1

    bc_data = parse_bc_module_map()
    if not bc_data:
        print("ERROR: parsed 0 BC entries from bc-module-map.md — aborting", file=sys.stderr)
        sys.exit(1)

    adr_titles = load_adr_titles()
    if not adr_titles:
        print("WARNING: no ADR titles loaded — ADR descriptions will be omitted", file=sys.stderr)

    if check_mode:
        # Regenerate in memory and compare byte-for-byte; never write.
        diffs: list[str] = []
        checked = 0
        missing = 0
        for bc_id in sorted(bc_data.keys()):
            info = bc_data[bc_id]
            ss_num = re.search(r"BC-\d+\.(\d+)\.", bc_id).group(1)
            bc_file = BC_DIR / f"ss-{ss_num}" / f"{bc_id}.md"
            if not bc_file.exists():
                missing += 1
                continue
            checked += 1
            arch_value = format_arch_module_value(bc_id, info, adr_titles)
            content = bc_file.read_text(encoding="utf-8")
            new_content = compute_new_bc_content(content, arch_value)
            if new_content is not None:
                rel = str(bc_file.relative_to(REPO))
                diff_lines = list(difflib.unified_diff(
                    content.splitlines(keepends=True),
                    new_content.splitlines(keepends=True),
                    fromfile=rel,
                    tofile=f"{rel} (generated)",
                ))
                diffs.extend(diff_lines)
        if diffs:
            print(
                f"gen-bc-traceability --check: FAIL — {len(diffs)} diff line(s) across "
                f"{checked} checked files ({missing} missing on disk)"
            )
            sys.stdout.writelines(diffs)
            return 1
        print(
            f"gen-bc-traceability --check: OK — {checked} BC files match generated output "
            f"({missing} missing on disk, counted as not checked)"
        )
        return 0

    updated = 0
    skipped = 0
    missing = 0

    for bc_id in sorted(bc_data.keys()):
        info = bc_data[bc_id]
        ss_num = re.search(r"BC-\d+\.(\d+)\.", bc_id).group(1)
        bc_file = BC_DIR / f"ss-{ss_num}" / f"{bc_id}.md"

        if not bc_file.exists():
            missing += 1
            continue

        arch_value = format_arch_module_value(bc_id, info, adr_titles)
        changed = update_bc_file(bc_file, arch_value, dry_run)
        if changed:
            updated += 1
            if dry_run:
                print(f"  DRY-RUN would update: {bc_file.name}")
            else:
                print(f"  Updated: {bc_file.name}")
        else:
            skipped += 1

    verb = "Would update" if dry_run else "Updated"
    print(
        f"{verb}: {updated} BC files | already current: {skipped} | "
        f"missing on disk: {missing} | total in map: {len(bc_data)}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
