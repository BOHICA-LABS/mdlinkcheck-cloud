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

# Pattern 4: E-class error-code namespace (BI-056)
#   Matches error-class codes of the form E-XXX-NNN (e.g. E-IO-002, E-CLI-001)
#   INDEPENDENTLY of prose shape — these are NOT reason codes and are NOT passed
#   through _is_reason_code_candidate.  Validated against the E-code registry in
#   error-taxonomy.md §1 (currently empty → all occurrences are violations).
#
#   Structural proof that this pattern is incapable of reintroducing the 22 false
#   positives removed in PR #11: it requires a 2-4 uppercase-letter namespace
#   component between the 'E-' prefix and the '-NNN' suffix.  The false positives
#   were lowercase reason-code tokens matched by the prior broad backtick pattern;
#   none match E-[A-Z]{2,4}-\d{3}.  Corpus-wide population is exactly 8 occurrences
#   (6× E-IO-002, 2× E-CLI-001 across 3 files).
E_CLASS_CODE_RE = re.compile(r"(?<![A-Za-z0-9])(E-[A-Z]{2,4}-\d{3})(?!\d)")

# Independent canary regex for E-class population accounting (NIT-1 alignment fix).
# Deliberately WIDER than E_CLASS_CODE_RE — no {2,4} cap on namespace width, no {3}
# cap on digit suffix — so narrowing the detector also surfaces as a gap rather than
# shrinking both sides together.  Defined at module level so BOTH the frontmatter
# bucket in check_broad_corpus() AND the canary probe in main() use the SAME regex
# and the SAME per-line dedup (set()), keeping both sides of the invariant in lock-step.
# Previously defined only inside main(); the frontmatter bucket used the narrower
# E_CLASS_CODE_RE with no dedup, creating two latent false-alarm paths (NIT-1).
E_CLASS_CANARY_RE = re.compile(r"(?<![A-Za-z0-9])E-[A-Z]+-\d+")


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


def extract_valid_e_class_codes(taxonomy_path: Path) -> set[str]:
    """
    Extract the closed set of E-class error codes (E-XXX-NNN) from error-taxonomy.md.
    E-class codes are defined in §1 (error-class registry) if that section exists.

    Currently error-taxonomy.md defines ZERO E-class codes (§3 Closed-Set Invariant
    covers only reason codes).  All corpus E-code occurrences are therefore violations
    until explicit E-codes are registered here.  This function is the live source-of-truth
    so future codes can be whitelisted without changing the checker.
    """
    codes: set[str] = set()
    if not taxonomy_path.exists():
        return codes
    in_eclass = False
    for line in slp.cm_splitlines(taxonomy_path.read_text(encoding="utf-8")):
        # §1 is the error-class registry (not yet populated — kept for future use)
        if re.match(r"^## 1\.", line):
            in_eclass = True
        if in_eclass and line.startswith("## ") and not re.match(r"^## 1\.", line):
            in_eclass = False
        if not in_eclass:
            continue
        # Extract backtick-quoted E-class codes like `E-IO-002`
        for m in re.finditer(r"`(E-[A-Z]{2,4}-\d{3})`", line):
            codes.add(m.group(1))
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


def check_broad_corpus(
    path: Path,
    valid_reason_codes: set[str],
    valid_e_codes: set[str],
    e_class_only: bool = False,
) -> tuple[list[str], int, int, int]:
    """
    POLICY 19: check any spec file for reason code and E-class code violations.
    Returns (violations, reason_code_occurrences, e_code_occurrences, frontmatter_e_skipped).

    frontmatter_e_skipped: count of E-class code occurrences in YAML frontmatter that
    are legitimately excluded from violation scanning (D-081) but counted here so the
    E-class population reconciles to its corpus total (AC-1 fix).

    Detection patterns:
      Pattern 1: backtick-quoted codes with POSITIONAL predicate (BLOCKING-3):
                 - In table rows: only the column whose header is 'Reason' or 'Reason Code'
                 - In prose: only tokens immediately after 'reason code', 'reason:', 'sub_reason'
      Pattern 2: verdict + parenthetical "broken (malformed-fragment)"
      Pattern 3: taxonomy-reference "(consistent with E-CLI-001 taxonomy)" — E-class codes
                 are excluded here (AC-7 fix) and routed to Pattern 4 instead.
      Pattern 4: E-class code namespace (BI-056) — any occurrence of E-[A-Z]{2,4}-NNN,
                 prose-shape-independent.  Uses its own seen_e_codes_this_line set (not
                 shared with Patterns 1-3) so E-class codes are never shadowed by Pattern 3
                 claiming them first into the reason-code registry (AC-7 fix).

    Patterns 1-3 apply _is_reason_code_candidate() to exclude spec reference IDs and
    CLI flags (BLOCKING-2).  Pattern 4 does NOT — E-codes are a different namespace.

    Position-based predicate (D-081): YAML frontmatter is excluded from violation scanning.
    Frontmatter is identified as the content between the first and second "---" markers
    when the first "---" appears on line 1 of the file.  This covers the modified:/
    changelog: fields that document historical reason code names without asserting
    them as current.  No file-path-keyed exclusion list is used.  E-class codes found
    in frontmatter are counted in frontmatter_e_skipped (not as violations) so the
    population reconciliation is complete and every occurrence is disclosed.

    e_class_only: if True, run Pattern 4 (E-class detection) only; skip
        Patterns 1-3 (reason-code detection).  Used for the ADR path to avoid
        double-counting with check_adr(), which already performs POLICY 19
        reason-code scanning.  When True, reason_code_occurrences in the return
        value is always 0.  Table-structure parsing state is also skipped.
    """
    violations: list[str] = []
    occurrences = 0
    e_code_occurrences = 0
    frontmatter_e_skipped = 0  # AC-1: E-class codes in frontmatter — disclosed, not violations
    lines = slp.cm_splitlines(path.read_text(encoding="utf-8"))

    # Position-based frontmatter tracking (D-081)
    in_frontmatter = False
    frontmatter_closed = False
    dash_count = 0

    # Pattern 1 state: track which column is the Reason column in the current table section.
    # (BLOCKING-3 positional predicate — position 1: table Reason column)
    # (BLOCKING-5c) Updated ONLY when a separator row confirms the previous row was a header —
    # prevents data cells whose value is exactly "reason" from hijacking the column index.
    current_reason_col_p1: int | None = None
    prev_row_cells: list[str] | None = None  # previous table row, for separator-based confirmation

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
        # (position-based predicate per D-081; no file-path exclusion).
        # AC-1 (Defect 3): count E-class codes in frontmatter as disclosed skips rather
        # than silently dropping them.  The exclusion itself is LEGITIMATE (these are
        # historical changelog entries, not live assertions); the defect was that they
        # vanished without being counted, hiding 2 of the 8 corpus E-code occurrences.
        # NIT-1 alignment fix: use E_CLASS_CANARY_RE (wide) + set() dedup, matching
        # the canary probe in main() exactly.  The previous E_CLASS_CODE_RE (narrow)
        # + no-dedup logic had two latent false-alarm paths: (a) a wide-only code like
        # E-VERBOSE-001 (7-letter namespace) was counted 1 by the canary but 0 by the
        # bucket → gate fired a spurious accounting gap; (b) the same narrow code
        # appearing twice on one frontmatter line was counted 2 by the bucket but 1
        # by the canary (set() dedup) → gate fired in the other direction.
        if in_frontmatter:
            for _code in set(E_CLASS_CANARY_RE.findall(line)):
                frontmatter_e_skipped += 1
            continue

        # ── Patterns 1-3: reason-code detection (BLOCKING-2 fix: skip in e_class_only mode) ──
        # When e_class_only=True (ADR path), check_adr() already handles POLICY 19
        # reason-code scanning; running these patterns too would double-count violations.
        if not e_class_only:
            # Parse table structure for Pattern 1 positional predicate
            cells = slp.split_table_cells(line)
            is_table_line = bool(cells)

            # Section-boundary reset: when we leave a table (any non-table line — blank,
            # prose, heading, HR `---`), clear the Reason column tracking. The next table
            # section's header will set it fresh. Prevents a §2 "Reason" column index from
            # bleeding into an adjacent §3 "Notes" column (different schema). (BLOCKING-3)
            if not is_table_line:
                current_reason_col_p1 = None
                prev_row_cells = None

            if is_table_line:
                if slp.is_table_separator_row(cells):
                    # Separator confirms the previous row was a table header.
                    # (BLOCKING-5c) Only update current_reason_col_p1 from a confirmed header
                    # row — never from a data row, which prevents a data cell whose value is
                    # exactly "reason" from hijacking the column index and masking phantoms.
                    if prev_row_cells is not None:
                        for i, cell in enumerate(prev_row_cells):
                            if cell.lower() in ("reason", "reason code"):
                                current_reason_col_p1 = i
                                break
                    prev_row_cells = None
                else:
                    # Non-separator row: remember it as a candidate header row.
                    # It is confirmed as a header only if the NEXT line is a separator.
                    prev_row_cells = cells

            # Per-line dedup for Patterns 1-3 (reason-code namespace).
            # AC-7 (Defect 4): kept SEPARATE from seen_e_codes_this_line (Pattern 4)
            # so E-class codes are never shadowed by Pattern 3 claiming them first.
            seen_codes_this_line: set[str] = set()

            # ── Pattern 1: positional predicate (BLOCKING-3) ─────────────────────
            # Replaces the broad keyword-in-line context guard with position-based detection.
            # Only tokens in syntactic reason-code positions are candidates.
            if is_table_line:
                # Table row: only scan the Reason column cell (if known and this is a data row).
                # Separator-confirmed header detection (BLOCKING-5c) means current_reason_col_p1
                # is only set AFTER the separator row — true header rows are never processed here.
                # The `current_reason_col_p1 is not None` guard below prevents any confusion.
                # The old `is_header_row` variable (any cell == "reason") was redundant and caused
                # BLOCKING-6: data rows whose first cell was literally "reason" were silently
                # skipped, hiding phantom codes in the Reason column of those rows.
                if (not slp.is_table_separator_row(cells)
                        and current_reason_col_p1 is not None
                        and current_reason_col_p1 < len(cells)):
                    reason_cell = cells[current_reason_col_p1]
                    reason_stripped = reason_cell.strip()
                    # Two-branch token guard (BLOCKING-3 repair, BLOCKING-5a/5b, WARNING-8):
                    #
                    # Branch A — backtick-quoted cell: extract the leading backtick-quoted token,
                    #   allowing optional trailing annotation that starts with '(' or '[' only
                    #   (e.g., `phantom-gamma` (per D-018)).  WARNING-8: the trailing annotation
                    #   anchor `(?:\s*[([].*)?$` excludes prose cells like
                    #   `` `pulldown-cmark` handles this correctly per CommonMark `` whose trailing
                    #   text starts with a letter, not '(' or '['.
                    #   (BLOCKING-5a) [A-Za-z] catches uppercase-leading codes like `E-IO-002`.
                    #   (BLOCKING-5b) re.match (not fullmatch) allows trailing annotation text.
                    #
                    # Branch B — bare token: the entire cell must be a single lowercase hyphenated
                    #   token (re.fullmatch, [a-z]).  This preserves the BLOCKING-3 guard against
                    #   CapCase prose cells like "Dot-dir skipped by default" or "Non-UTF-8
                    #   reported as I/O error" — they fail [a-z] (uppercase first letter) and are
                    #   silently excluded, exactly as before.  Bare lowercase annotated cells like
                    #   "file-not-found (default)" are also handled here via re.match + [a-z].
                    if reason_stripped.startswith("`"):
                        # Branch A: backtick-quoted leading token — allows trailing annotation
                        # that begins with '(' or '[' (e.g., `phantom-gamma` (per D-018)).
                        # WARNING-8: the `(?:\s*[([].*)?$` anchor prevents prose cells whose
                        # trailing text starts with a letter from matching as reason codes.
                        m_simple = re.match(r"`?([A-Za-z][a-zA-Z0-9-]{2,})`?(?:\s*[([].*)?$", reason_stripped)
                    else:
                        # Branch B: bare token — the entire cell must be a single lowercase
                        # hyphenated token (re.fullmatch + [a-z]).  This preserves the
                        # BLOCKING-3 guard: prose cells like "Dot-dir skipped by default" or
                        # "edge-case match" fail fullmatch (trailing words) or fail [a-z]
                        # (CapCase), so they are silently excluded exactly as before.
                        m_simple = re.fullmatch(r"([a-z][a-z0-9-]{2,})", reason_stripped)
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

            # ── Pattern 2: verdict + parenthetical reason code ────────────────────
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

            # ── Pattern 3: taxonomy-reference parenthetical ──────────────────────
            # BLOCKING-2: apply _is_reason_code_candidate() to exclude spec ref IDs.
            # AC-7 (Defect 4): E-class codes (E-[A-Z]{2,4}-NNN) are explicitly excluded
            # here and routed to Pattern 4 instead.  TAXONOMY_CODE_RE can match
            # "(consistent with E-CLI-001 taxonomy)" but E-CLI-001 is an E-class code,
            # not a reason code; validating it against valid_reason_codes (the reason-code
            # registry) is the wrong registry and suppresses the Pattern 4 E-class finding.
            for m in TAXONOMY_CODE_RE.finditer(line):
                code = m.group(1)
                if code in seen_codes_this_line:
                    continue
                if not _is_reason_code_candidate(code):
                    continue
                # AC-7: route E-class codes to Pattern 4, not the reason-code path
                if re.fullmatch(r"E-[A-Z]{2,4}-\d{3}", code):
                    continue
                seen_codes_this_line.add(code)
                occurrences += 1
                if code not in valid_reason_codes:
                    violations.append(
                        f"{path}:{lineno}: taxonomy reference '{code}' not in closed taxonomy "
                        f"(POLICY 19)\n"
                        f"  {line.strip()[:100]}"
                    )

        # ── Pattern 4: E-class code namespace detector (BI-056) ──────────────────
        # Detects error-class codes (E-[A-Z]{2,4}-NNN) INDEPENDENTLY of prose shape.
        # These are a different namespace from reason codes and are validated against
        # error-taxonomy.md §1 (the E-code registry, currently empty).
        # Does NOT use _is_reason_code_candidate — no interaction with reason-code
        # false-positive logic.
        # AC-7 (Defect 4): uses seen_e_codes_this_line (separate from seen_codes_this_line)
        # so E-class codes are never shadowed by Pattern 3.  Previously Pattern 3 could
        # claim E-CLI-001 from "(consistent with E-CLI-001 taxonomy)", add it to
        # seen_codes_this_line, count it as a reason-code occurrence (wrong registry),
        # and Pattern 4 would silently skip it via `if code in seen_codes_this_line`.
        # Declared here (outside the e_class_only guard) so Pattern 4 always has its
        # dedup set regardless of mode.
        seen_e_codes_this_line: set[str] = set()
        for m in E_CLASS_CODE_RE.finditer(line):
            code = m.group(1)
            if code in seen_e_codes_this_line:
                continue  # dedup within Pattern 4 (intra-line)
            seen_e_codes_this_line.add(code)
            e_code_occurrences += 1
            if code not in valid_e_codes:
                violations.append(
                    f"{path}:{lineno}: E-class code '{code}' not defined in error-taxonomy.md "
                    f"(POLICY 19 — E-code namespace)\n"
                    f"  {line.strip()[:100]}"
                )

    return violations, occurrences, e_code_occurrences, frontmatter_e_skipped


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
    # ADR files are handled separately in main(): check_adr() for POLICY 12 AND
    # check_broad_corpus() for POLICY 19 (AC-2/AC-3 fix — additive, not replacing).
    # The broad-corpus loop skips them here to avoid double-counting in broad_files_checked.
    if "/architecture/decisions/" in s:
        return False
    return True


def main() -> int:
    valid_codes = extract_closed_reason_codes(ERROR_TAX)
    if not valid_codes:
        print(f"ERROR: Could not extract reason codes from {ERROR_TAX}")
        return 2

    valid_e_codes = extract_valid_e_class_codes(ERROR_TAX)
    # valid_e_codes is currently empty (error-taxonomy.md §1 not yet populated);
    # all corpus E-code occurrences are violations (BI-056).

    print(f"Closed reason code set ({len(valid_codes)} codes): {sorted(valid_codes)}")

    violations: list[str] = []
    adrs_checked = 0
    broad_files_checked = 0
    total_occurrences = 0
    total_e_occurrences = 0
    total_frontmatter_e_skipped = 0  # AC-1: E-class codes in frontmatter (disclosed skips)

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

    # ── POLICY 12 + POLICY 19 for ADRs ───────────────────────────────────────
    # AC-2/AC-3 fix: ADRs now receive BOTH policies.
    #   check_adr()          → POLICY 12 (exit code, verdict class, reason code — ADR-specific)
    #   check_broad_corpus() → POLICY 19 (Pattern 4 E-class detection + occurrence counting)
    # ADDITIVE: check_adr() is called without modification; check_broad_corpus() is the
    # new addition.  No existing POLICY 12 check is removed or weakened.
    if not ADR_DIR.exists():
        print(f"ERROR: ADR directory not found: {ADR_DIR}")
        return 2

    for adr_file in sorted(ADR_DIR.glob("ADR-*.md")):
        adrs_checked += 1
        # POLICY 12: ADR-specific checks (unchanged)
        file_violations = check_adr(adr_file, valid_codes)
        violations.extend(file_violations)
        # POLICY 19 Pattern 4: E-class detection only for ADRs (BLOCKING-2 fix).
        # Patterns 1/2/3 (reason-code detection) are NOT applied to the ADR path;
        # check_adr() above already covers POLICY 19 reason-code violations for ADRs,
        # and running check_broad_corpus() with all patterns would double-count them.
        # ADR reason-code occurrences are therefore NOT counted in total_occurrences;
        # disclosed explicitly below (named gap, not silent omission — anti-BI-047).
        new_v, new_occ, new_e_occ, new_fm_e_skipped = check_broad_corpus(
            adr_file, valid_codes, valid_e_codes, e_class_only=True
        )
        violations.extend(new_v)
        total_occurrences += new_occ  # always 0 with e_class_only=True
        total_e_occurrences += new_e_occ
        total_frontmatter_e_skipped += new_fm_e_skipped

    # ── POLICY 19 for non-ADR spec files (BI-050 repair) ─────────────────────
    for spec_file in sorted(SPECS.rglob("*.md")):
        if not should_check_for_broad_p19(spec_file):
            continue
        broad_files_checked += 1
        new_v, new_occ, new_e_occ, new_fm_e_skipped = check_broad_corpus(
            spec_file, valid_codes, valid_e_codes
        )
        violations.extend(new_v)
        total_occurrences += new_occ
        total_e_occurrences += new_e_occ
        total_frontmatter_e_skipped += new_fm_e_skipped

    # POSITIVE-COVERAGE completeness assertion (D-057 / POLICY 11):
    # Parts must sum to the independently-computed corpus total.
    total_scanned = broad_files_checked + adrs_checked
    if total_scanned != total_corpus:
        print(
            f"ERROR: scope gap — {broad_files_checked} non-ADR + {adrs_checked} ADRs "
            f"= {total_scanned} scanned, but corpus total is {total_corpus}; "
            f"check _in_spec_corpus / should_check_for_broad_p19 filter alignment"
        )
        return 2

    # Named gap disclosure (BLOCKING-2 fix): ADR reason-code occurrences are NOT
    # counted in total_occurrences.  Pattern 2/3 (reason-code detection) was not
    # applied to the {adrs_checked} ADR files; POLICY 19 reason-code violations
    # for ADRs are detected by check_adr() above.  Named explicitly to prevent
    # BI-047-class silent omissions.
    print(
        f"ADR reason-code occurrences: 0 counted toward reason-code total "
        f"({adrs_checked} ADR files; Patterns 1-3 not applied — "
        f"deliberate named gap, avoids check_adr() overlap)"
    )

    # ── E-class population reconciliation (AC-1 acceptance test) ──────────────
    # INDEPENDENT GROUND-TRUTH PROBE: scans the corpus with E_CLASS_CANARY_RE,
    # the module-level wide regex (no {2,4} cap on namespace width, no {3} cap
    # on digit suffix — wider than E_CLASS_CODE_RE) that does NOT reuse
    # check_broad_corpus()'s routing or continue logic.  This probe is the same
    # regex used by the frontmatter bucket (NIT-1 alignment fix); both sides of
    # the invariant now share the same regex and per-line dedup (set()).
    #
    # Invariant: every E-class occurrence found by the canary must be accounted
    # for in one of the two named buckets (examined | frontmatter-skipped).
    # A mismatch means an occurrence is dropped by an undeclared routing path
    # (e.g., a future `if is_table_line: continue` before Pattern 4).
    #
    # Uses print+return 2, NOT assert.  assert is stripped entirely under
    # python -O; the three sibling completeness gates above use the same pattern.
    e_population = 0
    for f in sorted(SPECS.rglob("*.md")):
        if not _in_spec_corpus(f):
            continue
        for line in slp.cm_splitlines(f.read_text(encoding="utf-8")):
            e_population += len(set(E_CLASS_CANARY_RE.findall(line)))

    if e_population != total_e_occurrences + total_frontmatter_e_skipped:
        print(
            f"ERROR: E-class accounting gap — population={e_population} != "
            f"examined={total_e_occurrences} + skipped={total_frontmatter_e_skipped}; "
            f"an E-class occurrence is being dropped by an undeclared routing path"
        )
        return 2

    e_recon_line = (
        f"E-class population: population={e_population}, "
        f"examined={total_e_occurrences}, "
        f"skipped={total_frontmatter_e_skipped} (frontmatter, D-081)"
    )
    print(e_recon_line)

    if violations:
        for v in violations:
            print(v)
        print(
            f"\nCheck FAILED: {len(violations)} violations found "
            f"({total_occurrences} reason-code occurrences + {total_e_occurrences} E-class code "
            f"occurrences validated across "
            f"{broad_files_checked} non-ADR + {adrs_checked} ADRs (POLICY 12 + POLICY 19) "
            f"= {total_scanned} of {total_corpus} spec files (complete), "
            f"{len(violations)} non-conforming)"
        )
        return 1

    print(
        f"Check passed: {total_occurrences} reason-code occurrences + "
        f"{total_e_occurrences} E-class code occurrences validated across "
        f"{broad_files_checked} non-ADR + {adrs_checked} ADRs (POLICY 12 + POLICY 19) "
        f"= {total_scanned} of {total_corpus} spec files (complete), 0 non-conforming"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
