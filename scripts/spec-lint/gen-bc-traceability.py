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

Usage:
  python3 gen-bc-traceability.py [--dry-run]
"""
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


def update_bc_file(bc_file: Path, arch_value: str, dry_run: bool) -> bool:
    """
    Update the Architecture Module row in a BC file.
    Returns True if file was changed (or would change in dry-run).
    """
    content = bc_file.read_text(encoding="utf-8")
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
            print(f"  WARNING: {bc_file.name}: markers found but replacement failed", file=sys.stderr)
            return False
        if new_content == original:
            return False
        if not dry_run:
            bc_file.write_text(new_content, encoding="utf-8")
        return True

    # Case 2: no markers — find existing Architecture Module row and wrap it
    arch_row_pattern = re.compile(
        r"^(\| Architecture Module \|[^\n]+\|)\s*$",
        re.MULTILINE,
    )
    m = arch_row_pattern.search(content)
    if m:
        replacement = generated_block
        new_content = content[:m.start()] + replacement + content[m.end():]
        if new_content == original:
            return False
        if not dry_run:
            bc_file.write_text(new_content, encoding="utf-8")
        return True

    # Case 3: no Architecture Module row — append to Traceability table
    # Find the last row of the Traceability table (just before ## Related BCs or EOF)
    traceability_match = re.search(r"^## Traceability\b", content, re.MULTILINE)
    if not traceability_match:
        print(f"  SKIP: {bc_file.name}: no ## Traceability section found")
        return False

    # Find the end of the traceability table (blank line or next ## section)
    after_trace = content[traceability_match.end():]
    next_section = re.search(r"\n##\s", after_trace)
    if next_section:
        insert_pos = traceability_match.end() + next_section.start()
    else:
        insert_pos = len(content)

    insertion = f"\n{generated_block}\n"
    new_content = content[:insert_pos] + insertion + content[insert_pos:]
    if new_content == original:
        return False
    if not dry_run:
        bc_file.write_text(new_content, encoding="utf-8")
    return True


def main() -> int:
    dry_run = "--dry-run" in sys.argv

    bc_data = parse_bc_module_map()
    if not bc_data:
        print("ERROR: parsed 0 BC entries from bc-module-map.md — aborting", file=sys.stderr)
        sys.exit(1)

    adr_titles = load_adr_titles()
    if not adr_titles:
        print("WARNING: no ADR titles loaded — ADR descriptions will be omitted", file=sys.stderr)

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
