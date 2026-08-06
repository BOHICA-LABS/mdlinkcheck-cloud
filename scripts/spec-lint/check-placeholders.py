#!/usr/bin/env python3
"""
check-placeholders — POL-14 / POL-15 (generalized)
====================================================
Fail on any of the following placeholders remaining in spec artifacts
after Phase 1b:

  VP-TBD       — POL-14: no VP-TBD placeholders after Phase 1b
  SS-TBD       — POL-15: no SS-TBD subsystem placeholders after Phase 1b
  [filled by * — any "[filled by ...]" marker (73 remain per audit)

Scope: .factory/specs/behavioral-contracts/ (primary)
       .factory/specs/ (secondary, for any stray occurrences elsewhere)

Excludes: policies.yaml verification_steps (they document the pattern, not instances)

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
            for pattern, name in PLACEHOLDER_PATTERNS:
                for m in pattern.finditer(line):
                    violations.append((str(md_file), lineno, m.group(0), name))

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

    print(f"Check passed: {files_checked} spec files checked — no VP-TBD, SS-TBD, or [filled by] placeholders")
    return 0


if __name__ == "__main__":
    sys.exit(main())
