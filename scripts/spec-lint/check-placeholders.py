#!/usr/bin/env python3
"""
check-placeholders — POL-14 / POL-15 (generalized)
====================================================
Fail on any of the following placeholders remaining in spec artifacts
after Phase 1b:

  VP-TBD       — POL-14: no VP-TBD placeholders after Phase 1b
  SS-TBD       — POL-15: no SS-TBD subsystem placeholders after Phase 1b
  [filled by * — any "[filled by ...]" marker (73 remain per audit)
  non-conforming VP-NNN column value — POL-14: in any Verification Properties
                   table (header row first cell exactly "VP-NNN"), every data
                   row's first cell MUST be a non-empty comma-or-slash-separated
                   list of VP-\d{3} tokens, or the sentinel VP-NONE (only when
                   the Proof Method column is non-empty). Any other first-cell
                   content (em-dash, en-dash, TBD, none, empty, etc.) is a
                   POL-14 violation — R2-RULE (D-069).

Scope: .factory/specs/behavioral-contracts/ (primary)
       .factory/specs/ (secondary, for any stray occurrences elsewhere)

Excludes: policies.yaml verification_steps (they document the pattern, not instances)

Scoping rule for VP-TBD / SS-TBD:
  YAML frontmatter changelog entries (modified: list items containing
  version strings like "v1.x: ...") are historical records of past state
  and must be excluded from the live-placeholder check. A VP-TBD inside
  a quoted string in a modified: entry is NOT a live placeholder.

  Concretely: skip VP-TBD / SS-TBD matches on lines that:
    - are inside a quoted string (the match is bracketed by " ... "
      on the same line) AND the line looks like a changelog entry
      (contains a version prefix like "v1." or "v2.").

R2-RULE scoping:
  Fenced code blocks (triple-backtick, not 4-space-indented per CommonMark §4.5)
  are suppressed — content inside them is documentation, not live spec content.

Exit 1 if any placeholder found.
"""
import os
import re
import sys
from pathlib import Path

REPO = Path(os.environ.get("SPEC_LINT_REPO_OVERRIDE", "")).resolve() if os.environ.get("SPEC_LINT_REPO_OVERRIDE") else Path(__file__).resolve().parent.parent.parent
SPECS = REPO / ".factory" / "specs"

# Patterns and their policy origins
PLACEHOLDER_PATTERNS = [
    (re.compile(r"\bVP-TBD\b"), "VP-TBD (POL-14)"),
    (re.compile(r"\bSS-TBD\b"), "SS-TBD (POL-15)"),
    (re.compile(r"\[filled by [^\]]+\]", re.IGNORECASE), "[filled by ...] (POL-14/15 generalized)"),
]

# R2-RULE: VP-ID-COLUMN CONFORMANCE (replaces TEST_SUFFICIENT_IN_VP_COL).
# A VP table header has exactly "VP-NNN" as its first cell.
_VP_TABLE_HEADER_CELL = "VP-NNN"

# A conforming VP-NNN cell value: single VP-NNN token (canonical 3-digit form)
_VP_TOKEN_RE = re.compile(r"^VP-\d{3}$")

# Separator row detection: cells matching :?-{2,}:? (ignoring spaces)
_SEP_CELL_RE = re.compile(r"^:?-{2,}:?$")

# Pattern to detect if VP-TBD/SS-TBD is inside a quoted changelog entry.
# Changelog entries look like: - "v1.x: some description VP-TBD something"
# The version prefix may be inside or outside the quotes.
_CHANGELOG_QUOTED = re.compile(r'"[^"]*v\d+\.\d+[^"]*"')


def is_historical_changelog_line(line: str, matched_text: str) -> bool:
    """Return True if matched_text appears inside a quoted changelog entry on this line.

    A quoted changelog entry is a YAML list item like:
      - "v1.1: (F-007) VP-TBD backfill from VP-INDEX v1.1"
    or:
      - v1.4: "D-019/P2-M08 — ..."

    We detect this by checking if the match is bracketed by double-quotes
    on the same line AND the line looks like a changelog item (contains v\\d.\\d).
    """
    # Find the position of matched_text in the line
    pos = line.find(matched_text)
    if pos == -1:
        return False
    # Check if there's an opening quote before the match and version-like text
    before = line[:pos]
    after = line[pos + len(matched_text):]
    in_quotes = ('"' in before and '"' in after) or _CHANGELOG_QUOTED.search(line) is not None
    has_version = bool(re.search(r"v\d+\.\d+", line))
    return in_quotes and has_version


def _split_table_cells(line: str) -> list:
    """Split a markdown table row into stripped cell values.

    Handles ragged rows: returns whatever cells are present.
    E.g. '| VP-001 | some text | unit test |' -> ['VP-001', 'some text', 'unit test']
    """
    parts = line.split("|")
    # parts[0] is empty (before leading |), parts[-1] may be empty (after trailing |)
    if len(parts) < 2:
        return []
    # Strip leading/trailing empty parts
    inner = parts[1:]
    if inner and inner[-1].strip() == "":
        inner = inner[:-1]
    return [p.strip() for p in inner]


def _is_separator_row(cells: list) -> bool:
    """Return True if all non-empty cells look like table separators (e.g. '---', ':---:', etc.)."""
    non_empty = [c for c in cells if c]
    return bool(non_empty) and all(_SEP_CELL_RE.match(c) for c in non_empty)


def _is_valid_vp_cell(first_cell: str, proof_method: str) -> bool:
    """Return True if first_cell is a conforming VP-NNN column value.

    Conforming values (R2-RULE + D-078 sentinel):
      - One or more VP-NNN tokens (3-digit), separated by commas or slashes
      - VP-NONE sentinel, but ONLY when proof_method is non-empty

    Everything else (em-dash, en-dash, TBD, none, n/a, empty, etc.) is non-conforming.
    """
    if not first_cell:
        return False

    # VP-NONE sentinel (D-078): admitted only when Proof Method is non-empty
    if first_cell == "VP-NONE":
        return bool(proof_method.strip())

    # Comma- or slash-separated list of VP-NNN tokens.
    # Filter empty tokens BEFORE the all() call: re.split(",", ",") yields ['', ''],
    # and all() over an empty iterator returns True — silently passing punctuation-only cells.
    tokens = [t.strip() for t in re.split(r"[,/]", first_cell) if t.strip()]
    return bool(tokens) and all(_VP_TOKEN_RE.match(t) for t in tokens)


# Files/paths to exclude (they document the pattern)
EXCLUDE_PATHS = {
    str(REPO / ".factory" / "policies.yaml"),
    str(SPECS / "prd.md"),  # prd.md may mention the policy but not have BC-level placeholders
}

# Exception: prd.md §5b / holdout list may mention VP-TBD in historical context
# We check all BC files and spec supplements except what's in EXCLUDE_PATHS
def should_check(path: Path) -> bool:
    """Return True if this file should be checked for placeholders."""
    s = str(path)
    for ex in EXCLUDE_PATHS:
        if s == ex:
            return False
    # Don't check cycle logs or planning docs
    if "/.factory/cycles/" in s or "/.factory/planning/" in s:
        return False
    return True


def check_file_lines(md_file: Path, lines: list) -> list:
    """Check a list of lines from md_file for placeholder violations.

    Returns a list of (filepath, lineno, matched, pattern_name) tuples.
    """
    violations = []
    filepath = str(md_file)

    # Per-file state for R2-RULE table-context tracking
    in_fenced_code = False
    table_header_first_cell = None  # first cell of last non-separator | row
    in_vp_table_data = False        # True after VP-NNN header + separator row seen

    for lineno, line in enumerate(lines, 1):
        # ── Fenced code block suppression (CommonMark §4.5) ──────────────────
        # A line starting with ``` (not 4-space indented) is a fence delimiter.
        indent = len(line) - len(line.lstrip())
        stripped_line = line.lstrip()
        if stripped_line.startswith("```") and indent < 4:
            in_fenced_code = not in_fenced_code
            # Exiting or entering a fence resets table context
            in_vp_table_data = False
            table_header_first_cell = None
            continue
        # ── Table-context state machine (R2-RULE, gated: suppressed inside fenced blocks) ──
        # VP-TBD, SS-TBD, and [filled by] are still checked inside fenced blocks via
        # PLACEHOLDER_PATTERNS below. Only the structural R2-RULE VP-NNN column check
        # is suppressed (fenced content is documentation, not live spec data).
        if not in_fenced_code:
            if line.startswith("|"):
                cells = _split_table_cells(line)
                if cells:
                    if _is_separator_row(cells):
                        # Separator row: transition to data mode if header was VP-NNN
                        if table_header_first_cell == _VP_TABLE_HEADER_CELL:
                            in_vp_table_data = True
                        else:
                            in_vp_table_data = False
                        # Separator rows have no ID content; skip other checks
                        continue
                    elif in_vp_table_data:
                        # Data row inside a VP-NNN-headed table: apply R2-RULE
                        first_cell = cells[0] if cells else ""
                        proof_method = cells[2] if len(cells) > 2 else ""
                        if not _is_valid_vp_cell(first_cell, proof_method):
                            violations.append((filepath, lineno, first_cell,
                                               f"non-conforming VP-NNN column value '{first_cell}' (POL-14)"))
                        # Do NOT apply the general PLACEHOLDER_PATTERNS to this row
                        # (the first cell is a structural ID, not free text)
                        # Still check non-first cells for [filled by] etc. below
                        # by falling through to PLACEHOLDER_PATTERNS after skipping
                        # the first-cell check — but we do that by not continuing here.
                        # Actually: run PLACEHOLDER_PATTERNS on the full line (VP-TBD etc.
                        # in the Property or Proof Method cells are still violations).
                    else:
                        # Header candidate row (no separator seen yet for this table)
                        table_header_first_cell = cells[0] if cells else None
                        in_vp_table_data = False
            else:
                # Non-| line: leave any current table context
                table_header_first_cell = None
                in_vp_table_data = False

        # ── General placeholder pattern scan ─────────────────────────────────
        for pattern, name in PLACEHOLDER_PATTERNS:
            for m in pattern.finditer(line):
                matched = m.group(0)
                # Skip VP-TBD / SS-TBD if they are inside a historical
                # changelog entry (quoted string with a version prefix).
                if matched in ("VP-TBD", "SS-TBD"):
                    if is_historical_changelog_line(line, matched):
                        continue
                violations.append((filepath, lineno, matched, name))

    return violations


def main() -> int:
    if not SPECS.exists():
        print(f"ERROR: Spec tree not found at {SPECS} — cannot run check (no spec files to validate)", file=sys.stderr)
        sys.exit(1)
    violations: list[tuple[str, int, str, str]] = []  # (filepath, lineno, matched, pattern_name)
    files_checked = 0

    for md_file in sorted(SPECS.rglob("*.md")):
        if not should_check(md_file):
            continue
        files_checked += 1
        lines = md_file.read_text(encoding="utf-8").splitlines()
        violations.extend(check_file_lines(md_file, lines))

    if violations:
        # Group by type for summary
        by_type: dict[str, int] = {}
        for filepath, lineno, matched, name in violations:
            print(f"{filepath}:{lineno}: placeholder '{matched}' [{name}]")
            by_type[name] = by_type.get(name, 0) + 1
        print()
        for name, count in sorted(by_type.items()):
            print(f"  {count:3d}  {name}")
        print(f"\nCheck FAILED: {len(violations)} placeholder occurrences found ({files_checked} files checked)")
        return 1

    print(f"Check passed: {files_checked} spec files checked — no VP-TBD, SS-TBD, [filled by], or non-conforming VP-NNN column values")
    return 0


if __name__ == "__main__":
    sys.exit(main())
