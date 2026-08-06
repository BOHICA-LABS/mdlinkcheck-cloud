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
    Looks for table rows matching | EC-NNNN... | description... | verdict... |
    """
    rows = []
    lines = path.read_text(encoding="utf-8").splitlines()
    start = parse_frontmatter_end(lines)

    for lineno, line in enumerate(lines[start:], start=start + 1):
        # Match table rows starting with EC-NNN (possibly sub-lettered)
        m = re.match(r"^\|\s*(EC-(\d+[a-z]?))\s*\|\s*(.+?)\s*\|\s*(.+?)\s*\|", line)
        if m:
            ec_id = m.group(1)    # e.g. EC-060, EC-079b
            desc = m.group(3).strip()
            verdict_raw = m.group(4).strip()
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

        # Check for description collisions
        descs = [o[1] for o in occurrences]
        verdicts = [normalize_verdict(o[2]) for o in occurrences]

        unique_descs = set(descs)
        unique_verdicts = set(verdicts)

        has_desc_collision = len(unique_descs) > 1
        has_verdict_collision = len(unique_verdicts) > 1

        if has_desc_collision or has_verdict_collision:
            collision_ids.add(ec_id)
            hdr = f"COLLISION {ec_id}:"
            if has_desc_collision:
                hdr += " description-mismatch"
            if has_verdict_collision:
                hdr += " verdict-mismatch"
            violations.append(hdr)
            for filepath, desc, verdict_raw, lineno in occurrences:
                violations.append(
                    f"  {filepath}:{lineno}: desc={desc[:80]!r} verdict={verdict_raw[:40]!r}"
                )

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
