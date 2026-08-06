#!/usr/bin/env python3
"""
check-ec-injectivity — POL-16 (the big one)
============================================
Every EC-NNN must denote exactly ONE scenario. Detect same EC ID used with differing
scenario descriptions or differing expected verdicts across BC edge-case tables and
test-vectors.md.

The canonical EC registry is test-vectors.md. BC files cite ECs in their Edge Cases
tables. If the same bare EC-NNN (not sub-lettered) appears in multiple BC files with
different scenario descriptions, or the same EC-NNN appears in both test-vectors.md
and a BC with a different expected verdict, that is a collision.

Sub-lettered variants (EC-079b, EC-094a) are distinct IDs and should not be confused
with their base. However: if a sub-lettered variant's BASE ID is a holdout, the
presence of concrete sub-lettered rows in visible BCs is also flagged (handled by
check-holdout-boundary.py) — this check focuses on description/verdict collisions.

Exit 1 if any injective-map violation found.
"""
import re
import sys
from collections import defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent.parent
SPECS = REPO / ".factory" / "specs"
BC_DIR = SPECS / "behavioral-contracts"
TV_FILE = SPECS / "prd-supplements" / "test-vectors.md"


def parse_frontmatter_end(lines: list[str]) -> int:
    if lines and lines[0].rstrip() == "---":
        for i in range(1, len(lines)):
            if lines[i].rstrip() == "---":
                return i + 1
    return 0


def normalize_verdict(raw: str) -> str:
    """Normalize a verdict string for comparison (lower-case, strip parens content)."""
    raw = raw.strip().lower()
    # Extract the primary verdict word
    m = re.match(r"^(alive|broken|indeterminate|clean|dead|valid)", raw)
    if m:
        return m.group(1)
    return raw[:40]  # fallback


def extract_ec_rows(path: Path) -> list[tuple[str, str, str, int]]:
    """
    Parse a Markdown file for EC table rows.
    Returns list of (ec_id, description, verdict_raw, lineno).
    Handles both 2-column (EC-ID | desc) and 3-column (EC-ID | desc | verdict) formats.
    """
    rows = []
    lines = path.read_text(encoding="utf-8").splitlines()
    start = parse_frontmatter_end(lines)

    for lineno, line in enumerate(lines[start:], start=start + 1):
        # Match table rows starting with EC-NNN (possibly sub-lettered)
        # Use flexible match: EC-ID followed by at least one more column
        m = re.match(r"^\|\s*(EC-(\d+[a-z]?))\s*\|(.+)", line)
        if not m:
            continue
        ec_id = m.group(1)
        rest = m.group(3)
        # Split remaining columns, skip separator rows (e.g. |---|---|)
        cols = [c.strip() for c in rest.split("|") if c.strip() and not re.match(r"^-+$", c.strip())]
        if not cols:
            continue
        desc = cols[0]
        verdict_raw = cols[1] if len(cols) > 1 else ""
        rows.append((ec_id, desc, verdict_raw, lineno))
    return rows


def extract_tv_rows(path: Path) -> list[tuple[str, str, str, int]]:
    """
    Parse test-vectors.md for EC references.
    TV rows look like: | TV-NNN | EC-NNN | Description | ... | exit_code | verdict | reason |
    Returns list of (ec_id, description, verdict_raw, lineno).
    """
    rows = []
    lines = path.read_text(encoding="utf-8").splitlines()
    for lineno, line in enumerate(lines, 1):
        # Match TV table row that contains an EC-NNN column
        m = re.match(
            r"^\|\s*(TV-[\w]+)\s*\|\s*(EC-(\d+[a-z]?))\s*\|\s*(.+?)\s*\|.*?\|\s*(\d|n/a)\s*\|\s*(.+?)\s*\|",
            line,
        )
        if m:
            ec_id = m.group(2)
            desc = m.group(4).strip()
            verdict_raw = m.group(6).strip()
            rows.append((ec_id, desc, verdict_raw, lineno))
    return rows


def main() -> int:
    if not SPECS.exists():
        print(f"ERROR: Spec tree not found at {SPECS} — cannot run check (no spec files to validate)", file=sys.stderr)
        sys.exit(1)
    # Map: ec_id -> list of (source_file, description, verdict_raw, lineno)
    ec_map: dict[str, list[tuple[str, str, str, int]]] = defaultdict(list)

    # Walk all BC files
    bc_files = sorted(BC_DIR.rglob("BC-*.md"))
    for bc_file in bc_files:
        for ec_id, desc, verdict, lineno in extract_ec_rows(bc_file):
            ec_map[ec_id].append((str(bc_file), desc, verdict, lineno))

    # Walk test-vectors.md
    if TV_FILE.exists():
        for ec_id, desc, verdict, lineno in extract_tv_rows(TV_FILE):
            ec_map[ec_id].append((str(TV_FILE), desc, verdict, lineno))

    violations: list[str] = []
    collision_ids: set[str] = set()

    for ec_id, occurrences in sorted(ec_map.items()):
        if len(occurrences) <= 1:
            continue

        # Separate BC-file occurrences from test-vectors.md occurrences
        tv_file_str = str(TV_FILE)
        bc_occs = [(f, d, v, l) for f, d, v, l in occurrences if f != tv_file_str]
        tv_occs = [(f, d, v, l) for f, d, v, l in occurrences if f == tv_file_str]

        has_desc_collision = False
        has_verdict_collision = False
        collision_detail: list[str] = []

        # Description collision: only within BC files that have explicit verdicts
        # 2-column citation rows (verdict_raw="") are paraphrases — not canonical descriptions
        if len(bc_occs) > 1:
            explicit_bc_occs = [(f, d, v, l) for f, d, v, l in bc_occs if v.strip()]
            if len(explicit_bc_occs) > 1:
                descs = [o[1] for o in explicit_bc_occs]
                if len(set(descs)) > 1:
                    has_desc_collision = True
                    for filepath, desc, verdict_raw, lineno in explicit_bc_occs:
                        collision_detail.append(
                            f"  {filepath}:{lineno}: desc={desc[:80]!r} verdict={verdict_raw[:40]!r}"
                        )

        # Verdict collision: BC file vs test-vectors.md — only when BOTH have explicit verdicts
        if bc_occs and tv_occs:
            tv_verdicts = [normalize_verdict(o[2]) for o in tv_occs if o[2].strip()]
            for bc_filepath, bc_desc, bc_verdict_raw, bc_lineno in bc_occs:
                if not bc_verdict_raw.strip():
                    continue  # BC row has no verdict column — skip verdict comparison
                bc_norm = normalize_verdict(bc_verdict_raw)
                for tv_norm in tv_verdicts:
                    if tv_norm and bc_norm != tv_norm:
                        has_verdict_collision = True
                        if not collision_detail:  # avoid duplicate headers
                            for filepath, desc, verdict_raw, lineno in tv_occs:
                                collision_detail.append(
                                    f"  {filepath}:{lineno}: desc={desc[:80]!r} verdict={verdict_raw[:40]!r}"
                                )
                        collision_detail.append(
                            f"  {bc_filepath}:{bc_lineno}: desc={bc_desc[:80]!r} verdict={bc_verdict_raw[:40]!r}"
                        )

        if has_desc_collision or has_verdict_collision:
            collision_ids.add(ec_id)
            hdr = f"COLLISION {ec_id}:"
            if has_desc_collision:
                hdr += " description-mismatch"
            if has_verdict_collision:
                hdr += " verdict-mismatch"
            violations.append(hdr)
            violations.extend(collision_detail)

    total_ec_ids = len(ec_map)
    multi_occurrence = sum(1 for v in ec_map.values() if len(v) > 1)

    if violations:
        for v in violations:
            print(v)
        print(
            f"\nCheck FAILED: {len(collision_ids)} EC ID collisions found "
            f"({total_ec_ids} unique EC IDs scanned; {multi_occurrence} appear in multiple files)"
        )
        return 1

    print(
        f"Check passed: {total_ec_ids} EC IDs validated — all injective "
        f"({multi_occurrence} appear in multiple files but are consistent)"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
