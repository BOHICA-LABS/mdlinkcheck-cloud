#!/usr/bin/env python3
"""
check-adr-consistency — POL-12 / POL-19
=========================================
No ADR may assert an exit code, verdict class, or reason code that contradicts
error-taxonomy.md or frozen brief R7.

POLICY 12 (ADR-specific):
  Checks exit code semantics and verdict class misuse in ADR files only:
  1. Exit code 2 misapplied to broken-link outcomes (instead of I/O errors)
  2. Verdict class: external URLs use alive/broken/indeterminate as liveness outcomes;
     link verdicts are clean/broken/indeterminate. The term "valid" is NOT a verdict.
  3. Known bad patterns from pass-1/2/3 adversary findings:
     - Assigning exit 2 to broken links (must be exit 1)
     - Assigning dns-failure or tls-error to indeterminate (both are broken)
     - Using the word "valid" as a verdict label

POLICY 19 (whole spec corpus — BI-050 repair):
  All reason codes in spec artifacts must exist VERBATIM in the closed set defined
  in error-taxonomy.md.  Enforced across BC bodies, test-vectors, prd.md,
  prd-supplements, domain-spec, and architecture — not just ADRs.
  Reason codes are read at runtime from error-taxonomy.md §2.

Scoping:
  - POLICY 12 checks: ADR files only (.factory/specs/architecture/decisions/ADR-*.md)
  - POLICY 19 checks: all spec files EXCEPT ADR files (which are already covered),
    holdout-scenarios, and cycle/planning artifacts
  - YAML frontmatter (between first and second "---" marker) is excluded from POLICY 19
    scanning — frontmatter modified/changelog entries record historical names (D-081
    position-based predicate; no file-path-keyed exclusion set is introduced).

Exit 1 if any violation found.

POSITIVE-COVERAGE (D-057): emits on every run:
  "N reason-code occurrences validated across M files, K non-conforming"
"""
import re
import sys
from pathlib import Path
import spec_lint_primitives as slp

REPO = slp.find_repo_root(start=Path(__file__).resolve().parent)  # honors SPEC_LINT_REPO_OVERRIDE
SPECS = REPO / ".factory" / "specs"
ADR_DIR = SPECS / "architecture" / "decisions"
ERROR_TAX = SPECS / "prd-supplements" / "error-taxonomy.md"

# ── POLICY 19 detection patterns (BI-050) ────────────────────────────────────

# Pattern 2: verdict followed by parenthetical reason code
#   e.g. "broken (malformed-fragment)", "indeterminate (phantom-code)"
VERDICT_PAREN_CODE_RE = re.compile(
    r"\b(?:broken|indeterminate|alive|clean)\s+\(([a-zA-Z][a-zA-Z0-9-]+)\)",
    re.IGNORECASE,
)

# Pattern 3: taxonomy-reference parenthetical
#   e.g. "(consistent with E-CLI-001 taxonomy)"
#   This is the exact prose shape from adversary finding P7-S5-018.
TAXONOMY_CODE_RE = re.compile(
    r"\(consistent with\s+([A-Za-z][A-Za-z0-9-]+)\s+taxonomy\)",
    re.IGNORECASE,
)


def extract_closed_reason_codes(taxonomy_path: Path) -> set[str]:
    """
    Extract the closed set of reason codes from error-taxonomy.md.
    Reason codes appear as `code` in backtick-delimited table cells.

    Scans:
      §2 (main catalog): primary reason codes (file-not-found, dns-failure, etc.)
      §3b (optional sub_reason field): sub-reason codes (https-downgrade, private-ip)
    Both sets are returned as a single flat set — the distinction between primary
    reason code and sub_reason is not material for POLICY 19 validation.
    """
    codes: set[str] = set()
    if not taxonomy_path.exists():
        return codes
    in_catalog = False
    in_subreason = False
    for line in slp.cm_splitlines(taxonomy_path.read_text(encoding="utf-8")):
        # Section 2 is the main catalog
        if "## 2." in line:
            in_catalog = True
        if in_catalog and line.startswith("## ") and "## 2." not in line:
            in_catalog = False
        # Section 3b is the optional sub_reason field (https-downgrade, private-ip)
        if "## 3b." in line:
            in_subreason = True
        if in_subreason and line.startswith("## ") and "## 3b." not in line:
            in_subreason = False
        if not (in_catalog or in_subreason):
            continue
        # Extract backtick-quoted reason codes like `file-not-found`
        for m in re.finditer(r"`([a-z][a-z0-9-]+)`", line):
            code = m.group(1)
            # Filter to hyphenated codes that look like reason codes
            if "-" in code and not any(kw in code for kw in ("sub_reason", "schema_version")):
                codes.add(code)
    return codes


# ── POLICY 12 patterns ────────────────────────────────────────────────────────

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
    """POLICY 12 + POLICY 19 check for ADR files (original scope, unchanged)."""
    violations = []
    lines = slp.cm_splitlines(path.read_text(encoding="utf-8"))

    for lineno, line in enumerate(lines, 1):
        # Check for wrong exit-code semantics (POLICY 12)
        for pattern, message in WRONG_EXIT_PATTERNS:
            if pattern.search(line):
                violations.append(
                    f"{path}:{lineno}: {message}\n"
                    f"  {line.strip()[:100]}"
                )

        # Check for dns-failure/tls-error misclassified as indeterminate (POLICY 12)
        if _dns_tls_indeterminate(line):
            violations.append(
                f"{path}:{lineno}: dns-failure or tls-error affirmatively mapped to indeterminate "
                f"(both must be 'broken' per error-taxonomy.md)\n"
                f"  {line.strip()[:100]}"
            )

        # Check all backtick-quoted reason codes that look like reason codes (POLICY 19)
        for m in re.finditer(r"`([a-z][a-z0-9-]{3,})`", line):
            code = m.group(1)
            if not _is_reason_code_candidate(code):
                continue
            if code not in valid_reason_codes:
                # Is it in a "Reason codes" context?
                context = line.lower()
                if any(kw in context for kw in ("reason", "verdict", "broken", "exit")):
                    violations.append(
                        f"{path}:{lineno}: reason code '{code}' not in closed taxonomy\n"
                        f"  {line.strip()[:100]}"
                    )

    return violations


# ── POLICY 19 broad corpus check (BI-050 repair) ─────────────────────────────

# Spec reference ID patterns (position-based discriminator):
# uppercase prefix immediately followed by a digit, e.g. DD-007, EC-123, ADR-001.
# These are spec cross-references, NOT reason codes.  E-CLI-001 and E-IO-002 do NOT
# match this pattern because they have letters between the prefix and the numeric
# suffix (E-CLI-001: prefix="E", separator="-", then "CLI" letters before digits).
_SPEC_REF_ID_RE = re.compile(r'^[A-Z]{1,5}-\d')


def _is_spec_ref_id(code: str) -> bool:
    """Return True if the code looks like a spec cross-reference ID (DD-007, EC-123, etc.)
    rather than a reason code.  Uses a position-based test on the token structure."""
    return bool(_SPEC_REF_ID_RE.match(code))


def _is_reason_code_candidate(code: str) -> bool:
    """Return True if code is a plausible reason-code candidate for POLICY 19 checking.

    Applies ALL structural discriminators to avoid false positives:
      - Must contain a hyphen (single-word tokens are not reason codes)
      - Must not start with '--' (CLI flags like --insecure)
      - Must not be a schema/sub_reason technical term
      - Must not be a spec cross-reference ID (DD-007, EC-123, D-018, DI-010, etc.)

    BLOCKING-2: apply this to ALL three patterns (Pattern 1, 2, 3) so spec reference
    IDs like DI-010 and D-018 are never treated as reason codes even in Pattern 2/3
    contexts like 'broken (D-018)' or '(consistent with DI-010 taxonomy)'.
    """
    if "-" not in code:
        return False
    if code.startswith("--"):
        return False
    if code.lower() in {"sub_reason", "schema_version"}:
        return False
    if _is_spec_ref_id(code):
        return False
    return True


# Pattern for positional reason-code detection in prose (BLOCKING-3):
# A backtick-quoted token is a reason-code candidate in prose ONLY when it
# appears immediately after one of these trigger phrases:
#   1. "reason code `...`"
#   2. "reason: `...`"    (YAML-style inline)
#   3. "sub_reason `...`"
_PROSE_REASON_CODE_RE = re.compile(
    r"(?i)(?:reason\s+code|reason:|sub_reason)\s+`([A-Za-z][A-Za-z0-9-]{2,})`"
)


def check_broad_corpus(path: Path, valid_reason_codes: set[str]) -> tuple[list[str], int]:
    """
    POLICY 19: check any spec file (non-ADR) for reason code violations.
    Returns (violations, occurrences_count).

    Detection patterns:
      Pattern 1: backtick-quoted codes with POSITIONAL predicate (BLOCKING-3):
                 - In table rows: only the column whose header is 'Reason' or 'Reason Code'
                 - In prose: only tokens immediately after 'reason code', 'reason:', 'sub_reason'
      Pattern 2: verdict + parenthetical "broken (malformed-fragment)"
      Pattern 3: taxonomy-reference "(consistent with E-CLI-001 taxonomy)"

    All three patterns now apply _is_reason_code_candidate() to exclude spec reference
    IDs (D-018, DI-010, EC-123) and CLI flags (BLOCKING-2).

    Position-based predicate (D-081): YAML frontmatter is excluded from scanning.
    Frontmatter is identified as the content between the first and second "---" markers
    when the first "---" appears on line 1 of the file.  This covers the modified:/
    changelog: fields that document historical reason code names without asserting
    them as current.  No file-path-keyed exclusion list is used.
    """
    violations: list[str] = []
    occurrences = 0
    lines = slp.cm_splitlines(path.read_text(encoding="utf-8"))

    # Position-based frontmatter tracking (D-081)
    in_frontmatter = False
    frontmatter_closed = False
    dash_count = 0

    # Pattern 1 state: track which column is the Reason column in the current table section.
    # Updated when a header row is encountered that contains a 'Reason' or 'Reason Code' cell.
    # (BLOCKING-3 positional predicate — position 1: table Reason column)
    current_reason_col_p1: int | None = None

    for lineno, line in enumerate(lines, 1):
        stripped = line.strip()

        # Track YAML frontmatter boundaries
        if stripped == "---" and not frontmatter_closed:
            if dash_count == 0 and lineno == 1:
                # First "---" on line 1 opens frontmatter
                in_frontmatter = True
                dash_count = 1
                continue
            elif dash_count == 1:
                # Second "---" closes frontmatter
                in_frontmatter = False
                frontmatter_closed = True
                dash_count = 2
                continue

        # Skip YAML frontmatter — modified/changelog entries record historical names
        # (position-based predicate per D-081; no file-path exclusion)
        if in_frontmatter:
            continue

        # Parse table structure for Pattern 1 positional predicate
        cells = slp.split_table_cells(line)
        is_table_line = bool(cells)

        # Section-boundary reset: when we leave a table (any non-table line — blank,
        # prose, heading, HR `---`), clear the Reason column tracking. The next table
        # section's header will set it fresh. Prevents a §2 "Reason" column index from
        # bleeding into an adjacent §3 "Notes" column (different schema). (BLOCKING-3)
        if not is_table_line:
            current_reason_col_p1 = None

        if is_table_line and not slp.is_table_separator_row(cells):
            # Check if this is a table header row (contains a 'Reason' or 'Reason Code' cell)
            found_reason_col = None
            for i, cell in enumerate(cells):
                if cell.lower() in ("reason", "reason code"):
                    found_reason_col = i
                    break
            if found_reason_col is not None:
                # Update Reason column tracking for subsequent data rows
                current_reason_col_p1 = found_reason_col

        # Per-line deduplication: avoid double-counting same code on same line
        seen_codes_this_line: set[str] = set()

        # ── Pattern 1: positional predicate (BLOCKING-3) ─────────────────────────
        # Replaces the broad keyword-in-line context guard with position-based detection.
        # Only tokens in syntactic reason-code positions are candidates.
        if is_table_line:
            # Table row: only scan the Reason column cell (if known and this is a data row)
            is_header_row = any(cell.lower() in ("reason", "reason code") for cell in cells)
            if (not is_header_row
                    and not slp.is_table_separator_row(cells)
                    and current_reason_col_p1 is not None
                    and current_reason_col_p1 < len(cells)):
                reason_cell = cells[current_reason_col_p1]
                # Simple-value guard (BLOCKING-3 repair): only check cells whose entire
                # content is a single lowercase hyphenated token (optionally in backticks).
                # Long notes cells (library names, anchor slug examples, explanatory text)
                # are excluded — they are not in a syntactic reason-code position even
                # though they share the Reason column. Matches: `file-not-found`, dns-failure.
                # Does NOT match: "CommonMark ... `pulldown-cmark` handles correctly",
                # "`foo-1`; `Foo-1` normalizes", or any cell with spaces.
                m_simple = re.fullmatch(r"`?([a-z][a-z0-9-]{2,})`?", reason_cell.strip())
                if m_simple:
                    code = m_simple.group(1)
                    if code not in seen_codes_this_line and _is_reason_code_candidate(code):
                        seen_codes_this_line.add(code)
                        occurrences += 1
                        if code not in valid_reason_codes:
                            violations.append(
                                f"{path}:{lineno}: reason code '{code}' not in closed taxonomy "
                                f"(POLICY 19)\n"
                                f"  {line.strip()[:100]}"
                            )
        else:
            # Prose line: use positional patterns (BLOCKING-3 positions 2 and 3)
            # Matches: "reason code `X`", "reason: `X`", "sub_reason `X`"
            for m in _PROSE_REASON_CODE_RE.finditer(line):
                code = m.group(1)
                if code in seen_codes_this_line:
                    continue
                if not _is_reason_code_candidate(code):
                    continue
                seen_codes_this_line.add(code)
                occurrences += 1
                if code not in valid_reason_codes:
                    violations.append(
                        f"{path}:{lineno}: reason code '{code}' not in closed taxonomy "
                        f"(POLICY 19)\n"
                        f"  {line.strip()[:100]}"
                    )

        # ── Pattern 2: verdict + parenthetical reason code ────────────────────────
        # BLOCKING-2: apply _is_reason_code_candidate() to exclude spec ref IDs (D-018, DI-010)
        for m in VERDICT_PAREN_CODE_RE.finditer(line):
            code = m.group(1)
            if code in seen_codes_this_line:
                continue
            if not _is_reason_code_candidate(code):
                continue
            seen_codes_this_line.add(code)
            occurrences += 1
            if code not in valid_reason_codes:
                violations.append(
                    f"{path}:{lineno}: verdict reason code '{code}' not in closed taxonomy "
                    f"(POLICY 19)\n"
                    f"  {line.strip()[:100]}"
                )

        # ── Pattern 3: taxonomy-reference parenthetical ───────────────────────────
        # BLOCKING-2: apply _is_reason_code_candidate() to exclude spec ref IDs
        for m in TAXONOMY_CODE_RE.finditer(line):
            code = m.group(1)
            if code in seen_codes_this_line:
                continue
            if not _is_reason_code_candidate(code):
                continue
            seen_codes_this_line.add(code)
            occurrences += 1
            if code not in valid_reason_codes:
                violations.append(
                    f"{path}:{lineno}: taxonomy reference '{code}' not in closed taxonomy "
                    f"(POLICY 19)\n"
                    f"  {line.strip()[:100]}"
                )

    return violations, occurrences


def should_check_for_broad_p19(path: Path) -> bool:
    """
    Position-based predicate: which files to scan for POLICY 19 broad-corpus check.
    Uses directory position, not file names or a skip list.
    """
    s = str(path)
    # Holdout scenario files are not visible artifacts
    if "holdout-scenarios" in s:
        return False
    # Cycle logs and planning artifacts are not spec files
    if "/.factory/cycles/" in s or "/.factory/planning/" in s:
        return False
    # ADR files are already covered by check_adr() which handles POLICY 12 + 19
    if "/architecture/decisions/" in s:
        return False
    return True


def main() -> int:
    valid_codes = extract_closed_reason_codes(ERROR_TAX)
    if not valid_codes:
        print(f"ERROR: Could not extract reason codes from {ERROR_TAX}")
        return 2

    print(f"Closed reason code set ({len(valid_codes)} codes): {sorted(valid_codes)}")

    violations: list[str] = []
    adrs_checked = 0
    broad_files_checked = 0
    total_occurrences = 0

    # CORRECTION 2 (D-057 / POLICY 11): independently compute the ground-truth
    # spec corpus total (all .md files under SPECS excluding holdout-scenarios,
    # cycles, and planning — regardless of routing to broad vs ADR path).
    # This total must equal broad_files_checked + adrs_checked after the loops;
    # any divergence means a scope gap and we fail loudly.
    def _in_spec_corpus(path: Path) -> bool:
        s = str(path)
        if "holdout-scenarios" in s:
            return False
        if "/.factory/cycles/" in s or "/.factory/planning/" in s:
            return False
        return True

    total_corpus = sum(1 for f in SPECS.rglob("*.md") if _in_spec_corpus(f))

    # ── POLICY 12 + 19 for ADRs (original scope, unchanged) ──────────────────
    if not ADR_DIR.exists():
        print(f"ERROR: ADR directory not found: {ADR_DIR}")
        return 2

    for adr_file in sorted(ADR_DIR.glob("ADR-*.md")):
        adrs_checked += 1
        file_violations = check_adr(adr_file, valid_codes)
        violations.extend(file_violations)

    # ── POLICY 19 for whole spec corpus (BI-050 repair) ───────────────────────
    for spec_file in sorted(SPECS.rglob("*.md")):
        if not should_check_for_broad_p19(spec_file):
            continue
        broad_files_checked += 1
        new_v, new_occ = check_broad_corpus(spec_file, valid_codes)
        violations.extend(new_v)
        total_occurrences += new_occ

    # POSITIVE-COVERAGE completeness assertion (D-057 / POLICY 11):
    # Parts must sum to the independently-computed corpus total.
    total_scanned = broad_files_checked + adrs_checked
    if total_scanned != total_corpus:
        print(
            f"ERROR: scope gap — {broad_files_checked} broad + {adrs_checked} ADRs "
            f"= {total_scanned} scanned, but corpus total is {total_corpus}; "
            f"check _in_spec_corpus / should_check_for_broad_p19 filter alignment"
        )
        return 2

    if violations:
        for v in violations:
            print(v)
        print(
            f"\nCheck FAILED: {len(violations)} violations found "
            f"({total_occurrences} reason-code occurrences validated across "
            f"{broad_files_checked} files scanned + {adrs_checked} ADRs routed to POLICY 12 "
            f"= {total_scanned} of {total_corpus} spec files (complete), "
            f"{len(violations)} non-conforming)"
        )
        return 1

    print(
        f"Check passed: {total_occurrences} reason-code occurrences validated across "
        f"{broad_files_checked} files scanned + {adrs_checked} ADRs routed to POLICY 12 "
        f"= {total_scanned} of {total_corpus} spec files (complete), 0 non-conforming"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
