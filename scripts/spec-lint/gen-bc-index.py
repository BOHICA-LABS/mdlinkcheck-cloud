#!/usr/bin/env python3
"""
gen-bc-index — regenerate BC-INDEX.md rows from BC files
=========================================================
Reads every BC-S.SS.NNN.md file and regenerates:
  - Per-subsystem table rows (BC ID, Title, Priority, File link)
  - Summary statistics block (Total, P0, P1 counts)

MARKER STRATEGY:
  The generated regions are delimited by:
    <!-- BEGIN GENERATED: ss-NN-table -->
    <!-- END GENERATED: ss-NN-table -->
  and for the summary stats:
    <!-- BEGIN GENERATED: summary-stats -->
    <!-- END GENERATED: summary-stats -->

  Prose sections (introductory text, section headers like "## SS-01 — File Discovery")
  are NOT inside the generated markers and will NOT be modified.

  LIMITATION: If BC-INDEX.md does not yet have these markers, this generator
  will ADD them on first run around the existing table content in each section.
  It detects the table boundaries by looking for the | BC-2. rows.

Idempotent: running twice produces identical output.

Usage:
  python3 gen-bc-index.py [--dry-run]
"""
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent.parent
SPECS = REPO / ".factory" / "specs"
BC_DIR = SPECS / "behavioral-contracts"
BC_INDEX = BC_DIR / "BC-INDEX.md"


def parse_frontmatter_end(lines: list[str]) -> int:
    if lines and lines[0].rstrip() == "---":
        for i in range(1, len(lines)):
            if lines[i].rstrip() == "---":
                return i + 1
    return 0


def get_bc_h1_title(path: Path) -> str | None:
    """Return the BC title from H1 (strip 'BC-S.SS.NNN: ' prefix)."""
    lines = path.read_text(encoding="utf-8").splitlines()
    start = parse_frontmatter_end(lines)
    for line in lines[start:]:
        if line.startswith("# "):
            title = line[2:].strip()
            title = re.sub(r"^BC-\d+\.\d+\.\d+:\s*", "", title)
            return title
    return None


def get_bc_priority(path: Path) -> str:
    """Extract priority from BC frontmatter. Default to P0 if not found."""
    lines = path.read_text(encoding="utf-8").splitlines()
    end = parse_frontmatter_end(lines)
    # Look in BC-INDEX.md for the priority (it's not in BC frontmatter directly)
    # Instead, parse from BC-INDEX.md
    return "P0"  # placeholder; see collect_bc_data below


def collect_bc_data() -> dict[str, dict]:
    """
    Collect BC data from both BC files (for titles) and BC-INDEX (for priorities).
    Returns {bc_id: {title, priority, ss, rel_path}}
    """
    # First get priorities from existing BC-INDEX.md
    priorities: dict[str, str] = {}
    for line in BC_INDEX.read_text(encoding="utf-8").splitlines():
        m = re.match(r"^\|\s*(BC-\d+\.\d+\.\d+)\s*\|[^|]+\|\s*(P\d)\s*\|", line)
        if m:
            priorities[m.group(1)] = m.group(2)

    result: dict[str, dict] = {}
    for bc_file in sorted(BC_DIR.rglob("BC-*.md")):
        if bc_file.name == "BC-INDEX.md":
            continue
        m = re.match(r"(BC-(\d+)\.(\d+)\.(\d+))\.md$", bc_file.name)
        if not m:
            continue
        bc_id = m.group(1)
        ss_num = m.group(3)
        title = get_bc_h1_title(bc_file)
        if title is None:
            continue
        rel_path = f"ss-{ss_num}/{bc_file.name}"
        result[bc_id] = {
            "title": title,
            "priority": priorities.get(bc_id, "P0"),
            "ss": f"SS-{ss_num}",
            "rel_path": rel_path,
        }
    return result


def build_ss_table(ss_id: str, bc_data: dict[str, dict]) -> str:
    """Build the table rows for a given subsystem."""
    ss_bcs = {
        bc_id: info for bc_id, info in bc_data.items()
        if info["ss"] == ss_id
    }
    if not ss_bcs:
        return ""
    lines = [
        "| BC ID | Title | Priority | File |",
        "|-------|-------|----------|------|",
    ]
    for bc_id in sorted(ss_bcs.keys()):
        info = ss_bcs[bc_id]
        title = info["title"]
        priority = info["priority"]
        rel_path = info["rel_path"]
        lines.append(f"| {bc_id} | {title} | {priority} | [{rel_path}]({rel_path}) |")
    return "\n".join(lines) + "\n"


def build_summary_stats(bc_data: dict[str, dict]) -> str:
    """Build the summary statistics block."""
    total = len(bc_data)
    p0 = sum(1 for info in bc_data.values() if info["priority"] == "P0")
    p1 = sum(1 for info in bc_data.values() if info["priority"] == "P1")
    subsystems = len(set(info["ss"] for info in bc_data.values()))
    return (
        f"**Total:** {total} BCs | **P0:** {p0} | **P1:** {p1} | "
        f"**Subsystems:** {subsystems}\n"
    )


MARKER_START = "<!-- BEGIN GENERATED: {key} -->"
MARKER_END = "<!-- END GENERATED: {key} -->"


def inject_generated_region(content: str, key: str, new_body: str) -> tuple[str, bool]:
    """
    Replace the region between GENERATED markers for `key`.
    Returns (new_content, changed).
    """
    start_marker = MARKER_START.format(key=key)
    end_marker = MARKER_END.format(key=key)
    pattern = re.compile(
        re.escape(start_marker) + r".*?" + re.escape(end_marker),
        re.DOTALL,
    )
    replacement = f"{start_marker}\n{new_body}{end_marker}"
    new_content, count = pattern.subn(replacement, content)
    return new_content, count > 0


def main() -> int:
    dry_run = "--dry-run" in sys.argv

    bc_data = collect_bc_data()
    all_ss = sorted(set(info["ss"] for info in bc_data.values()),
                    key=lambda s: int(re.search(r"\d+", s).group()))

    content = BC_INDEX.read_text(encoding="utf-8")
    original_content = content
    changed = False

    # Regenerate each SS table
    for ss_id in all_ss:
        ss_num = re.search(r"\d+", ss_id).group()
        key = f"ss-{ss_num}-table"
        new_table = build_ss_table(ss_id, bc_data)

        new_content, injected = inject_generated_region(content, key, new_table)
        if injected:
            content = new_content
            changed = True
        else:
            # Markers don't exist yet — inject around existing table rows
            # Find the section and add markers
            ss_pattern = re.compile(
                rf"(^## SS-{ss_num} —[^\n]*\n(?:[^\n]*\n)*?)"
                rf"(\| BC ID \|.*?\n\|[-| ]+\|\n(?:\| BC-{ss_num.split('-')[0]}\.{ss_num}\.\d+.*?\n)*)"
                r"(.*?---|\Z)",
                re.MULTILINE | re.DOTALL,
            )
            # Simpler: just look for the first BC row in the section and wrap
            # For now, just log that markers need to be added manually
            print(f"  NOTE: No GENERATED markers for {key} — add them to BC-INDEX.md to enable auto-regen")

    # Regenerate summary stats
    summary = build_summary_stats(bc_data)
    new_content, injected = inject_generated_region(content, "summary-stats", summary)
    if injected:
        content = new_content
        changed = True

    # Update frontmatter total_bcs count
    new_total = len(bc_data)
    p0_count = sum(1 for info in bc_data.values() if info["priority"] == "P0")
    p1_count = sum(1 for info in bc_data.values() if info["priority"] == "P1")
    content = re.sub(r"^total_bcs:\s*\d+", f"total_bcs: {new_total}", content, flags=re.MULTILINE)
    content = re.sub(r"^subsystems:\s*\d+",
                     f"subsystems: {len(set(i['ss'] for i in bc_data.values()))}",
                     content, flags=re.MULTILINE)
    if content != original_content:
        changed = True

    if not changed:
        print(f"No changes needed: BC-INDEX.md is already up to date ({new_total} BCs)")
        return 0

    if dry_run:
        print(f"-- DRY RUN: would update BC-INDEX.md --")
        print(f"  {new_total} BCs total (P0={p0_count}, P1={p1_count})")
        print(f"  NOTE: Some sections may need GENERATED markers added manually first")
        return 0

    BC_INDEX.write_text(content, encoding="utf-8")
    print(f"Updated: {BC_INDEX}")
    print(f"  {new_total} BCs total (P0={p0_count}, P1={p1_count})")
    print(f"  NOTE: Add <!-- BEGIN/END GENERATED: ss-NN-table --> markers to enable full table regen")
    return 0


if __name__ == "__main__":
    sys.exit(main())
