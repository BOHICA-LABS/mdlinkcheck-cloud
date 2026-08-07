#!/usr/bin/env python3
"""
check-adr-consistency — POL-12 / POL-19
=========================================
No ADR may assert an exit code, verdict class, or reason code that contradicts
error-taxonomy.md or frozen brief R7.

Checks:
  1. Exit code 2 misapplied to broken-link outcomes (instead of I/O errors)
  2. Reason codes: every named reason code must exist verbatim in the 13-code
     closed set from error-taxonomy.md
  3. Verdict class: external URLs use alive/broken/indeterminate as liveness outcomes;
     link verdicts are clean/broken/indeterminate. The term "valid" is NOT a verdict.
  4. Known bad patterns from pass-1/2/3 adversary findings:
     - Assigning exit 2 to broken links (must be exit 1)
     - Assigning dns-failure or tls-error to indeterminate (both are broken)
     - Using the word "valid" as a verdict label

Exit 1 if any violation found.
"""
import re
import sys
from pathlib import Path
import spec_lint_primitives as slp

REPO = slp.find_repo_root(start=Path(__file__).resolve().parent)  # honors SPEC_LINT_REPO_OVERRIDE
SPECS = REPO / ".factory" / "specs"
ADR_DIR = SPECS / "architecture" / "decisions"
ERROR_TAX = SPECS / "prd-supplements" / "error-taxonomy.md"


def extract_closed_reason_codes(taxonomy_path: Path) -> set[str]:
    """
    Extract the closed set of reason codes from error-taxonomy.md.
    Reason codes appear as `code` in backtick-delimited table cells.
    """
    codes: set[str] = set()
    if not taxonomy_path.exists():
        return codes
    in_catalog = False
    for line in slp.cm_splitlines(taxonomy_path.read_text(encoding="utf-8")):
        # Section 2 is the catalog
        if "## 2." in line:
            in_catalog = True
        if in_catalog and line.startswith("## ") and "## 2." not in line:
            in_catalog = False
        if not in_catalog:
            continue
        # Extract backtick-quoted reason codes like `file-not-found`
        for m in re.finditer(r"`([a-z][a-z0-9-]+)`", line):
            code = m.group(1)
            # Filter to hyphenated codes that look like reason codes
            if "-" in code and not any(kw in code for kw in ("sub_reason", "schema_version")):
                codes.add(code)
    return codes


# Patterns that indicate wrong semantics (exit 2 for broken links)
def _dns_tls_indeterminate(line: str) -> bool:
    """Return True if line affirmatively classifies dns-failure or tls-error as indeterminate.
    Excludes negation patterns like 'not indeterminate', 'moved from indeterminate to broken',
    'broken, not indeterminate', which are the CORRECT statements."""
    line_lower = line.lower()
    # Negation guards — these are correct statements, not violations
    negation_patterns = [
        "not indeterminate",
        "from indeterminate to broken",
        "are `broken`, not",
        "broken, not indeterminate",
        "classified as broken",
    ]
    if any(neg in line_lower for neg in negation_patterns):
        return False
    # Changelog entries describing historical fixes are not violations
    if "|" in line and ("1.1" in line or "1.0" in line or "remediation" in line.lower()):
        return False
    # Affirmative misclassification: "dns-failure → indeterminate" or "dns-failure: indeterminate"
    has_dns_tls = bool(re.search(r"\b(dns.failure|tls.error)\b", line_lower))
    has_indeterminate = bool(re.search(r"\bindeterminate\b", line_lower))
    has_affirmative = bool(re.search(r"(→|->|maps to|yields|is|:\s*`?indeterminate)", line_lower))
    return has_dns_tls and has_indeterminate and has_affirmative


WRONG_EXIT_PATTERNS = [
    # "exit 2" or "exit code 2" applied to "broken" outcome (not I/O)
    (re.compile(r"broken[^.]*exit\s+(?:code\s+)?2", re.IGNORECASE),
     "exit 2 applied to broken-link outcome (must be exit 1)"),
    (re.compile(r"exit\s+(?:code\s+)?2[^.]*broken link", re.IGNORECASE),
     "exit 2 applied to broken-link outcome (must be exit 1)"),
    # "valid" as a verdict label — but NOT in a negation context
    (re.compile(r"(?<!not )\b(?:verdict|outcome)\s+[`'\"]?valid[`'\"]?\b", re.IGNORECASE),
     "'valid' used as a verdict/outcome label (use 'alive' for liveness or 'clean' for link verdict)"),
]


def check_adr(path: Path, valid_reason_codes: set[str]) -> list[str]:
    violations = []
    lines = slp.cm_splitlines(path.read_text(encoding="utf-8"))

    for lineno, line in enumerate(lines, 1):
        # Skip changelog and history sections (document what was wrong, not what is)
        # But do check the main body

        # Check for wrong exit-code semantics
        for pattern, message in WRONG_EXIT_PATTERNS:
            if pattern.search(line):
                violations.append(
                    f"{path}:{lineno}: {message}\n"
                    f"  {line.strip()[:100]}"
                )

        # Check for dns-failure/tls-error misclassified as indeterminate
        if _dns_tls_indeterminate(line):
            violations.append(
                f"{path}:{lineno}: dns-failure or tls-error affirmatively mapped to indeterminate "
                f"(both must be 'broken' per error-taxonomy.md)\n"
                f"  {line.strip()[:100]}"
            )

        # Check all backtick-quoted reason codes that look like reason codes
        for m in re.finditer(r"`([a-z][a-z0-9-]{3,})`", line):
            code = m.group(1)
            if "-" in code and code not in valid_reason_codes:
                # Exclude codes that are clearly not reason codes
                if code not in {
                    "--insecure", "--online", "--ignore", "--allow", "--format",
                    "sub_reason", "schema_version", "http-indeterminate",
                    "https-downgrade", "private-ip",
                }:
                    # Is it in a "Reason codes" context?
                    context = line.lower()
                    if any(kw in context for kw in ("reason", "verdict", "broken", "exit")):
                        violations.append(
                            f"{path}:{lineno}: reason code '{code}' not in closed taxonomy\n"
                            f"  {line.strip()[:100]}"
                        )

    return violations


def main() -> int:
    valid_codes = extract_closed_reason_codes(ERROR_TAX)
    if not valid_codes:
        print(f"ERROR: Could not extract reason codes from {ERROR_TAX}")
        return 2

    print(f"Closed reason code set ({len(valid_codes)} codes): {sorted(valid_codes)}")

    violations: list[str] = []
    adrs_checked = 0

    if not ADR_DIR.exists():
        print(f"ERROR: ADR directory not found: {ADR_DIR}")
        return 2

    for adr_file in sorted(ADR_DIR.glob("ADR-*.md")):
        adrs_checked += 1
        file_violations = check_adr(adr_file, valid_codes)
        violations.extend(file_violations)

    if violations:
        for v in violations:
            print(v)
        print(
            f"\nCheck FAILED: {len(violations)} ADR consistency violations found "
            f"({adrs_checked} ADRs checked)"
        )
        return 1

    print(
        f"Check passed: {adrs_checked} ADRs checked — all exit codes and reason codes "
        f"consistent with error-taxonomy.md"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
