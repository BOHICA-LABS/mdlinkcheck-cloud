#!/usr/bin/env python3
"""
gen-rtm — regenerate PRD §7 requirements-traceability matrix from BC frontmatter
==================================================================================
Reads every BC-S.SS.NNN.md file's Traceability section and regenerates the §7 RTM
in prd.md.

The RTM columns are:
  BC ID | Source (L2 CAP) | L2 Invariants | Brief Req | Priority | Test Type

These are derived from:
  - capability:    frontmatter (CAP-NNN)
  - L2 Invariants: Traceability table "L2 Domain Invariants" row
  - Brief Req:     Traceability table "Brief Requirement" row
  - Priority:      BC-INDEX.md (authoritative)
  - Test Type:     Traceability table rows or existing RTM (not auto-inferred)

MARKER STRATEGY:
  The RTM table in prd.md §7 is delimited by:
    <!-- BEGIN GENERATED: prd-s7-rtm -->
    <!-- END GENERATED: prd-s7-rtm -->

  The section header "## 7. Requirements Traceability Matrix" and description prose
  are OUTSIDE the markers.

Idempotent. Does NOT add or modify other §7 content.

Known limitation: "Test Type" column cannot be fully derived from BC frontmatter
(it requires knowledge of the VP tool assignment). The generator preserves existing
Test Type values from the current RTM; it only updates BC ID, CAP, Invariants,
Brief Req, and Priority columns.

Usage:
  python3 gen-rtm.py [--dry-run]
"""
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent.parent
SPECS = REPO / ".factory" / "specs"
BC_DIR = SPECS / "behavioral-contracts"
PRD = SPECS / "prd.md"

MARKER_START = "<!-- BEGIN GENERATED: prd-s7-rtm -->"
MARKER_END = "<!-- END GENERATED: prd-s7-rtm -->"


def parse_frontmatter(path: Path) -> dict[str, str]:
    """Parse YAML frontmatter as a flat key:value dict."""
    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0].rstrip() != "---":
        return {}
    result: dict[str, str] = {}
    for i in range(1, len(lines)):
        if lines[i].rstrip() == "---":
            break
        m = re.match(r'^(\w+):\s*"?([^"#\n]*)"?', lines[i])
        if m:
            result[m.group(1).strip()] = m.group(2).strip().strip('"')
    return result


def parse_traceability_section(path: Path) -> dict[str, str]:
    """
    Parse the Traceability table from a BC file.
    Returns {field: value} for all rows in the Traceability table.
    """
    lines = path.read_text(encoding="utf-8").splitlines()
    in_traceability = False
    result: dict[str, str] = {}
    for line in lines:
        if line.strip() == "## Traceability":
            in_traceability = True
            continue
        if in_traceability and line.startswith("## ") and "Traceability" not in line:
            in_traceability = False
        if not in_traceability:
            continue
        # Match table rows: | Field | Value |
        m = re.match(r"^\|\s*([^|]+)\s*\|\s*([^|]+)\s*\|", line)
        if m:
            field = m.group(1).strip()
            value = m.group(2).strip()
            if field and field != "Field":
                result[field] = value
    return result


def get_bc_priorities() -> dict[str, str]:
    """Get BC priorities from BC-INDEX.md."""
    priorities: dict[str, str] = {}
    bc_index = BC_DIR / "BC-INDEX.md"
    for line in bc_index.read_text(encoding="utf-8").splitlines():
        m = re.match(r"^\|\s*(BC-\d+\.\d+\.\d+)\s*\|[^|]+\|\s*(P\d)\s*\|", line)
        if m:
            priorities[m.group(1)] = m.group(2)
    return priorities


def get_existing_test_types() -> dict[str, str]:
    """Parse existing RTM in prd.md to preserve Test Type values."""
    test_types: dict[str, str] = {}
    content = PRD.read_text(encoding="utf-8")
    for line in content.splitlines():
        # | BC-S.SS.NNN | CAP-NNN | DI-... | R... | P0 | test-type |
        m = re.match(
            r"^\|\s*(BC-\d+\.\d+\.\d+)\s*\|[^|]+\|[^|]+\|[^|]+\|\s*P\d\s*\|\s*([^|]+)\s*\|",
            line,
        )
        if m:
            test_types[m.group(1)] = m.group(2).strip()
    return test_types


def build_rtm_table(priorities: dict[str, str], test_types: dict[str, str]) -> str:
    """Build the full RTM table from BC files."""
    rows: list[tuple[str, str, str, str, str, str]] = []

    for bc_file in sorted(BC_DIR.rglob("BC-*.md")):
        if bc_file.name == "BC-INDEX.md":
            continue
        m = re.match(r"(BC-\d+\.\d+\.\d+)\.md$", bc_file.name)
        if not m:
            continue
        bc_id = m.group(1)

        fm = parse_frontmatter(bc_file)
        tr = parse_traceability_section(bc_file)

        cap = fm.get("capability", "—")
        # Clean up CAP value (may have description text after the ID)
        cap_m = re.search(r"CAP-\d+", cap)
        cap_clean = cap_m.group(0) if cap_m else cap

        # L2 Invariants from traceability
        inv_raw = tr.get("L2 Domain Invariants", "—")
        # Normalize: strip long descriptions, keep just DI-NNN references
        inv_ids = re.findall(r"DI-\d+", inv_raw)
        inv = ",".join(inv_ids) if inv_ids else "—"

        # Brief Requirement
        req_raw = tr.get("Brief Requirement", "—")
        # Normalize: keep R-format refs
        req = req_raw.strip().rstrip(".")

        priority = priorities.get(bc_id, "P0")
        test_type = test_types.get(bc_id, "unit")

        rows.append((bc_id, cap_clean, inv, req, priority, test_type))

    lines = [
        "| BC ID | Source (L2 CAP) | L2 Invariants | Brief Req | Priority | Test Type |",
        "|-------|----------------|---------------|-----------|----------|-----------|",
    ]
    for bc_id, cap, inv, req, priority, test_type in rows:
        lines.append(f"| {bc_id} | {cap} | {inv} | {req} | {priority} | {test_type} |")

    lines.append("")
    lines.append(f"*{len(rows)} BCs in traceability matrix.*")
    lines.append("")
    return "\n".join(lines)


def inject_generated_region(content: str, new_body: str) -> tuple[str, bool]:
    pattern = re.compile(
        re.escape(MARKER_START) + r".*?" + re.escape(MARKER_END),
        re.DOTALL,
    )
    replacement = f"{MARKER_START}\n{new_body}{MARKER_END}"
    new_content, count = pattern.subn(replacement, content)
    return new_content, count > 0


def main() -> int:
    dry_run = "--dry-run" in sys.argv

    content = PRD.read_text(encoding="utf-8")

    if MARKER_START not in content:
        print(f"NOTICE: prd.md §7 RTM is missing GENERATED markers.")
        print(f"To enable auto-regen, wrap the §7 table in prd.md with:")
        print(f"  {MARKER_START}")
        print(f"  (existing RTM table rows here)")
        print(f"  {MARKER_END}")
        print()
        print("Until markers are added, use check-counts.py to detect RTM drift manually.")
        return 0

    priorities = get_bc_priorities()
    test_types = get_existing_test_types()
    rtm_table = build_rtm_table(priorities, test_types)

    new_content, injected = inject_generated_region(content, rtm_table)

    if not injected:
        print(f"ERROR: Failed to inject RTM table — check markers in {PRD}")
        return 2

    if new_content == content:
        print(f"No changes needed: prd.md §7 RTM is already up to date")
        return 0

    if dry_run:
        print(f"-- DRY RUN: would update {PRD} §7 RTM --")
        bc_count = len(priorities)
        print(f"  {bc_count} BCs in RTM")
        return 0

    PRD.write_text(new_content, encoding="utf-8")
    print(f"Updated: {PRD}")
    print(f"  §7 RTM regenerated from BC frontmatter + traceability sections")
    print(f"  {len(priorities)} BCs included")
    return 0


if __name__ == "__main__":
    sys.exit(main())
