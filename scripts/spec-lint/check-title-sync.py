#!/usr/bin/env python3
"""
check-title-sync — POL-13 / POL-7
==================================
For every BC in the spec, the BC file H1 heading is the authoritative title.
This check verifies:
  1. BC-INDEX.md table row title == BC file H1 (stripped of "BC-S.SS.NNN: " prefix)
  2. prd.md §2.x table row title == BC file H1

Exits 1 if any mismatch is found. Prints file:line style output.
"""
import os
import re
import sys
from pathlib import Path
import spec_lint_primitives as slp

REPO = Path(os.environ.get("SPEC_LINT_REPO_OVERRIDE", "")).resolve() if os.environ.get("SPEC_LINT_REPO_OVERRIDE") else Path(__file__).resolve().parent.parent.parent
SPECS = REPO / ".factory" / "specs"
BC_INDEX = SPECS / "behavioral-contracts" / "BC-INDEX.md"
PRD = SPECS / "prd.md"
BC_DIR = SPECS / "behavioral-contracts"


def parse_frontmatter_end(lines):
    """Return the line index immediately after the closing '---' of YAML frontmatter."""
    if lines and lines[0].rstrip() == "---":
        for i in range(1, len(lines)):
            if lines[i].rstrip() == "---":
                return i + 1
    return 0


def get_bc_h1(path: Path) -> tuple[str | None, int]:
    """Return (title, line_number) from the first H1 after frontmatter, or (None, -1)."""
    lines = slp.cm_splitlines(path.read_text(encoding="utf-8"))
    start = parse_frontmatter_end(lines)
    for i, line in enumerate(lines[start:], start=start):
        if line.startswith("# "):
            # Strip "BC-S.SS.NNN: " prefix
            title = line[2:].strip()
            title = re.sub(r"^BC-\d+\.\d+\.\d+:\s*", "", title)
            return title, i + 1  # 1-indexed
    return None, -1


def parse_bc_index_rows() -> dict[str, tuple[str, int]]:
    """Parse BC-INDEX.md and return {bc_id: (title, line_number)}."""
    result = {}
    lines = slp.cm_splitlines(BC_INDEX.read_text(encoding="utf-8"))
    for lineno, line in enumerate(lines, 1):
        # Match table rows like: | BC-2.SS.NNN | Title | Priority | [file](file) |
        m = re.match(r"^\|\s*(BC-\d+\.\d+\.\d+)\s*\|\s*(.+?)\s*\|\s*P[012]\s*\|", line)
        if m:
            bc_id = m.group(1)
            title = m.group(2).strip()
            result[bc_id] = (title, lineno)
    return result


def parse_prd_bc_rows() -> dict[str, tuple[str, int]]:
    """Parse prd.md §2.x tables and return {bc_id: (title, line_number)}."""
    result = {}
    lines = slp.cm_splitlines(PRD.read_text(encoding="utf-8"))
    # Only look in section 2 (lines between "## 2." and "## 3.")
    in_section_2 = False
    for lineno, line in enumerate(lines, 1):
        if re.match(r"^## 2\.", line):
            in_section_2 = True
        elif re.match(r"^## \d+\.", line) and not re.match(r"^## 2\.", line):
            in_section_2 = False
        if not in_section_2:
            continue
        m = re.match(r"^\|\s*(BC-\d+\.\d+\.\d+)\s*\|\s*(.+?)\s*\|\s*P[012]\s*\|", line)
        if m:
            bc_id = m.group(1)
            title = m.group(2).strip()
            result[bc_id] = (title, lineno)
    return result


def find_bc_file(bc_id: str) -> Path | None:
    """Locate the BC file for a given BC-S.SS.NNN id."""
    # BC-2.SS.NNN -> ss-SS/BC-2.SS.NNN.md
    m = re.match(r"BC-(\d+)\.(\d+)\.(\d+)", bc_id)
    if not m:
        return None
    major, ss, nnn = m.group(1), m.group(2), m.group(3)
    path = BC_DIR / f"ss-{ss}" / f"{bc_id}.md"
    return path if path.exists() else None


def main() -> int:
    violations: list[str] = []

    if not BC_INDEX.exists():
        print(f"ERROR: Required file not found: {BC_INDEX}", file=sys.stderr)
        return 1
    if not PRD.exists():
        print(f"ERROR: Required file not found: {PRD}", file=sys.stderr)
        return 1

    bc_index_rows = parse_bc_index_rows()
    prd_rows = parse_prd_bc_rows()

    # Collect all BC IDs from BC-INDEX (authoritative catalog)
    all_bc_ids = set(bc_index_rows.keys())

    checked = 0
    for bc_id in sorted(all_bc_ids):
        bc_file = find_bc_file(bc_id)
        if bc_file is None:
            violations.append(
                f"{BC_INDEX}:{bc_index_rows[bc_id][1]}: {bc_id} listed in BC-INDEX but file not found"
            )
            continue

        authoritative_title, h1_line = get_bc_h1(bc_file)
        if authoritative_title is None:
            violations.append(
                f"{bc_file}:1: {bc_id} has no H1 heading after frontmatter"
            )
            continue

        checked += 1

        # Check BC-INDEX title vs H1
        if bc_id in bc_index_rows:
            index_title, index_lineno = bc_index_rows[bc_id]
            # Strip backtick escapes for comparison (preserve content)
            if index_title != authoritative_title:
                violations.append(
                    f"{BC_INDEX}:{index_lineno}: {bc_id} title mismatch (BC-INDEX vs H1)\n"
                    f"  BC-INDEX: {index_title!r}\n"
                    f"  H1 (auth): {authoritative_title!r}"
                )

        # Check PRD §2 title vs H1
        if bc_id in prd_rows:
            prd_title, prd_lineno = prd_rows[bc_id]
            if prd_title != authoritative_title:
                violations.append(
                    f"{PRD}:{prd_lineno}: {bc_id} title mismatch (prd.md §2 vs H1)\n"
                    f"  prd.md: {prd_title!r}\n"
                    f"  H1 (auth): {authoritative_title!r}"
                )
        else:
            violations.append(
                f"{PRD}:?: {bc_id} is in BC-INDEX but missing from prd.md §2.x tables"
            )

    if violations:
        for v in violations:
            print(v)
        print(f"\nCheck FAILED: {len(violations)} title-sync violations found ({checked} BCs checked)")
        return 1

    print(f"Check passed: {checked} BC titles validated (BC-INDEX + prd.md §2 all match H1)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
