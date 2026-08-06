#!/usr/bin/env python3
"""
check-placeholders — POL-14 / POL-15 (generalized)
====================================================
Fail on any of the following placeholders remaining in spec artifacts
after Phase 1b:

  VP-TBD       — POL-14: no VP-TBD placeholders after Phase 1b
  SS-TBD       — POL-15: no SS-TBD subsystem placeholders after Phase 1b
  [filled by * — any "[filled by ...]" marker (73 remain per audit)
  test-sufficient in VP-NNN column — POL-14: VP-NNN must be a real VP
                   reference; the literal string "test-sufficient" is NOT
                   a valid VP ID and must not appear as a table row key in
                   the VP-NNN column of a Verification Properties table.

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

Exit 1 if any placeholder found.
"""
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent.parent
SPECS = REPO / ".factory" / "specs"

# Patterns and their policy origins
PLACEHOLDER_PATTERNS = [
    (re.compile(r"\bVP-TBD\b"), "VP-TBD (POL-14)"),
    (re.compile(r"\bSS-TBD\b"), "SS-TBD (POL-15)"),
    (re.compile(r"\[filled by [^\]]+\]", re.IGNORECASE), "[filled by ...] (POL-14/15 generalized)"),
]

# Regex to detect test-sufficient in the VP-NNN column of a VP table row.
# Pattern: | test-sufficient | <anything> |
TEST_SUFFICIENT_IN_VP_COL = re.compile(r"^\|\s*test-sufficient\s*\|")

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


def main() -> int:
    violations: list[tuple[str, int, str, str]] = []  # (filepath, lineno, matched, pattern_name)
    files_checked = 0

    for md_file in sorted(SPECS.rglob("*.md")):
        if not should_check(md_file):
            continue
        files_checked += 1
        lines = md_file.read_text(encoding="utf-8").splitlines()
        for lineno, line in enumerate(lines, 1):
            # Check for test-sufficient in VP-NNN column (POL-14 violation)
            if TEST_SUFFICIENT_IN_VP_COL.match(line):
                violations.append((str(md_file), lineno, "test-sufficient",
                                    "test-sufficient in VP-NNN column (POL-14)"))
                continue  # no point checking other patterns on the same row

            for pattern, name in PLACEHOLDER_PATTERNS:
                for m in pattern.finditer(line):
                    matched = m.group(0)
                    # Skip VP-TBD / SS-TBD if they are inside a historical
                    # changelog entry (quoted string with a version prefix).
                    if matched in ("VP-TBD", "SS-TBD"):
                        if is_historical_changelog_line(line, matched):
                            continue
                    violations.append((str(md_file), lineno, matched, name))

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

    print(f"Check passed: {files_checked} spec files checked — no VP-TBD, SS-TBD, [filled by], or test-sufficient placeholders")
    return 0


if __name__ == "__main__":
    sys.exit(main())
