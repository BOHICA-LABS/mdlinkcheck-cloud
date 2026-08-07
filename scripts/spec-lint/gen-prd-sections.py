#!/usr/bin/env python3
"""
gen-prd-sections — regenerate prd.md §2.x BC tables from BC file H1s + frontmatter
====================================================================================
Reads every BC-S.SS.NNN.md file and regenerates the per-subsystem BC summary tables
in prd.md §2. BC H1 is the authoritative title.

MARKER STRATEGY:
  Each subsystem table in prd.md §2 is delimited by:
    <!-- BEGIN GENERATED: prd-s2-ss-NN -->
    <!-- END GENERATED: prd-s2-ss-NN -->

  The section headers (### 2.NN ...) and introductory "> Full contracts: ..." lines
  are OUTSIDE the markers and will NOT be modified.

  If prd.md does not yet have these markers, the generator reports exactly which
  lines need them and exits with instructions rather than auto-modifying the file.
  The user can add the markers and then re-run.

Idempotent: running twice produces identical output.

Usage:
  python3 gen-prd-sections.py [--dry-run]
"""
import re
import sys
from pathlib import Path
import spec_lint_primitives as slp

REPO = slp.find_repo_root(start=Path(__file__).resolve().parent)  # honors SPEC_LINT_REPO_OVERRIDE
SPECS = REPO / ".factory" / "specs"
BC_DIR = SPECS / "behavioral-contracts"
PRD = SPECS / "prd.md"

# Subsystem section number -> subsystem metadata (from prd.md §2 headings)
# Maps "01" -> ("File Discovery", "CAP-001", "SS-01")
SS_META: dict[str, tuple[str, str, str]] = {
    "01": ("File Discovery", "CAP-001", "SS-01"),
    "02": ("Markdown Parsing", "CAP-002", "SS-02"),
    "03": ("Link Extraction", "CAP-003", "SS-03"),
    "04": ("Code Context Exclusion", "CAP-004", "SS-04"),
    "05": ("Anchor Table Construction", "CAP-005", "SS-05"),
    "06": ("Heading Slug Computation", "CAP-006", "SS-06"),
    "07": ("Relative Path Resolution", "CAP-007", "SS-07"),
    "08": ("Anchor Resolution", "CAP-008", "SS-08"),
    "09": ("External URL Syntax Validation", "CAP-009", "SS-09"),
    "10": ("External URL Liveness Checking", "CAP-010", "SS-10"),
    "11": ("Filter Application", "CAP-011", "SS-11"),
    "12": ("Text Report Generation", "CAP-012", "SS-12"),
    "13": ("JSON Report Generation", "CAP-013", "SS-13"),
    "14": ("Exit Code Determination", "CAP-014", "SS-14"),
}


def parse_frontmatter_end(lines: list[str]) -> int:
    if lines and lines[0].rstrip() == "---":
        for i in range(1, len(lines)):
            if lines[i].rstrip() == "---":
                return i + 1
    return 0


def get_bc_h1_title(path: Path) -> str | None:
    """Return the BC title from H1 (strip 'BC-S.SS.NNN: ' prefix)."""
    lines = slp.cm_splitlines(path.read_text(encoding="utf-8"))
    start = parse_frontmatter_end(lines)
    for line in lines[start:]:
        if line.startswith("# "):
            title = line[2:].strip()
            title = re.sub(r"^BC-\d+\.\d+\.\d+:\s*", "", title)
            return title
    return None


def collect_ss_bcs(ss_num: str) -> list[tuple[str, str, str]]:
    """
    Collect (bc_id, title, priority) for all BCs in a subsystem.
    Priority is read from BC-INDEX.md (authoritative).
    """
    bc_index = BC_DIR / "BC-INDEX.md"
    priorities: dict[str, str] = {}
    for line in slp.cm_splitlines(bc_index.read_text(encoding="utf-8")):
        m = re.match(r"^\|\s*(BC-\d+\." + re.escape(ss_num) + r"\.\d+)\s*\|[^|]+\|\s*(P\d)\s*\|", line)
        if m:
            priorities[m.group(1)] = m.group(2)

    ss_dir = BC_DIR / f"ss-{ss_num}"
    if not ss_dir.exists():
        return []

    bcs = []
    for bc_file in sorted(ss_dir.glob("BC-*.md")):
        m = re.match(r"(BC-\d+\." + re.escape(ss_num) + r"\.\d+)\.md$", bc_file.name)
        if not m:
            continue
        bc_id = m.group(1)
        title = get_bc_h1_title(bc_file)
        if title is None:
            continue
        priority = priorities.get(bc_id, "P0")
        bcs.append((bc_id, title, priority))

    return bcs


def build_ss2_table(ss_num: str) -> str:
    """Build the PRD §2 table for a subsystem."""
    bcs = collect_ss_bcs(ss_num)
    if not bcs:
        return ""
    lines = [
        "| BC ID | Title | Priority |",
        "|-------|-------|----------|",
    ]
    for bc_id, title, priority in bcs:
        lines.append(f"| {bc_id} | {title} | {priority} |")
    return "\n".join(lines) + "\n"


MARKER_START = "<!-- BEGIN GENERATED: prd-s2-ss-{ss} -->"
MARKER_END = "<!-- END GENERATED: prd-s2-ss-{ss} -->"


def inject_generated_region(content: str, ss: str, new_body: str) -> tuple[str, bool]:
    start_marker = MARKER_START.format(ss=ss)
    end_marker = MARKER_END.format(ss=ss)
    pattern = re.compile(
        re.escape(start_marker) + r".*?" + re.escape(end_marker),
        re.DOTALL,
    )
    replacement = f"{start_marker}\n{new_body}{end_marker}"
    new_content, count = pattern.subn(replacement, content)
    return new_content, count > 0


def main() -> int:
    dry_run = "--dry-run" in sys.argv

    content = PRD.read_text(encoding="utf-8")
    original_content = content
    changed = False
    missing_markers: list[str] = []

    for ss_num in sorted(SS_META.keys()):
        new_table = build_ss2_table(ss_num)
        if not new_table:
            continue

        new_content, injected = inject_generated_region(content, ss_num, new_table)
        if injected:
            content = new_content
            changed = (content != original_content)
        else:
            missing_markers.append(ss_num)

    if missing_markers:
        print(f"NOTICE: prd.md §2 is missing GENERATED markers for SS: {missing_markers}")
        print("To enable auto-regen, wrap each subsystem table in prd.md §2 with:")
        for ss in missing_markers:
            print(f"  {MARKER_START.format(ss=ss)}")
            print(f"  (existing table rows here)")
            print(f"  {MARKER_END.format(ss=ss)}")
        print()
        print("Until markers are added, use check-title-sync.py to detect drift manually.")

    if not changed:
        print(f"No changes needed: prd.md §2 is already up to date (or markers not yet added)")
        return 0

    if dry_run:
        print(f"-- DRY RUN: would update {PRD} --")
        # Show what changed
        orig_lines = slp.cm_splitlines(original_content)
        new_lines = slp.cm_splitlines(content)
        diffs = [(i+1, o, n) for i, (o, n) in enumerate(zip(orig_lines, new_lines)) if o != n]
        print(f"  {len(diffs)} lines changed")
        for lineno, old, new in diffs[:10]:
            print(f"  L{lineno}: {repr(old)[:60]} -> {repr(new)[:60]}")
        if len(diffs) > 10:
            print(f"  ... and {len(diffs)-10} more")
        return 0

    PRD.write_text(content, encoding="utf-8")
    print(f"Updated: {PRD}")
    print(f"  §2 BC tables regenerated from BC file H1 headings")
    if missing_markers:
        print(f"  WARNING: {len(missing_markers)} sections still need GENERATED markers")
    return 0


if __name__ == "__main__":
    sys.exit(main())
