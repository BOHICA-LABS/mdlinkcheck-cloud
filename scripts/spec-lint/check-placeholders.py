#!/usr/bin/env python3
"""
check-placeholders — POL-14 / POL-15 (generalized)
====================================================
Fail on any of the following placeholders remaining in spec artifacts
after Phase 1b:

  VP-TBD       — POL-14: no VP-TBD placeholders after Phase 1b
  SS-TBD       — POL-15: no SS-TBD subsystem placeholders after Phase 1b
  [filled by * — any "[filled by ...]" marker, EXCEPT the operator-ruled
                 exemption below (Phase-1 gate with Phase-2 deferral)
  non-conforming VP-NNN column value — POL-14: in any Verification Properties
                   table (header row first cell exactly "VP-NNN"), every data
                   row's first cell MUST be a non-empty comma-or-slash-separated
                   list of VP-\\d{3} tokens, the sentinel VP-NONE (only when
                   the Proof Method column is non-empty), OR the sentinel
                   'test-sufficient' (ONLY when VP-INDEX classifies that BC as
                   test-sufficient — cross-checked at runtime). Any other first-cell
                   content (em-dash, en-dash, TBD, none, empty, etc.) is a
                   POL-14 violation — R2-RULE (D-069).

Operator-ruled exemptions (Phase-1 gate, Phase-2 deferral):

  [filled by ...] EXEMPT in Traceability 'Stories' field:
    Shape 1: '| Stories | [filled by ...] |' — any table row whose
             field-name cell is exactly "Stories".
    Shape 2: '- [filled by ...]' bullet item under a "## Story Anchor" heading.
    Rationale: Stories do not exist until Phase-2 decomposition; this field
    is legitimately unfilled at the Phase-1 gate.

  'test-sufficient' sentinel in VP-NNN column:
    Accepted ONLY when VP-INDEX classifies the file's BC ID as
    'test-sufficient'. The cross-check is performed at runtime against
    .factory/specs/verification-properties/VP-INDEX.md. This is a JOIN
    against VP-INDEX (not an allowlist, D-039) — the sentinel is rejected
    if VP-INDEX assigns a real VP or has no row for the BC.

Scope: .factory/specs/ — ALL 134 spec files; no file-path-keyed
       exclusions (D-081, D-113). prd.md enters scope.

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

D-081 position-based predicates (no file-path-keyed exclusion sets):
  Two additional position-based predicates exempt tokens that appear in
  historically-documented context — these predicates fire on WHERE in a document
  a token appears, not on WHICH file it is in:

  Predicate 1 — Changelog narrative section:
    An H3 heading (### ...) whose text starts with a version marker (v\d+,
    e.g. "### v1.4 — ...") begins a changelog narrative section. All
    placeholder tokens appearing inside such a section are historical records
    of past state and are exempt. The section ends when any H1, H2, or a
    non-version H3 heading is encountered.
    Calibrated against prd.md §changelog:
      - prd.md:509 `[filled by architect]` under ### v1.9 — EXEMPT
      - prd.md:644 VP-TBD (×3) under ### v1.4 — EXEMPT
      - prd.md:650 SS-TBD (×3) under ### v1.4 — EXEMPT

  Predicate 2 — Inline backtick span:
    A placeholder token that occurs inside a CommonMark inline code span
    (delimited by a single backtick on each side) is a cited reference, not a
    live placeholder, and is exempt. Detected by counting single backtick
    delimiters before the match position; an odd count indicates the match is
    inside a span.

Exit 1 if any placeholder found.
"""
import re
import sys
from pathlib import Path
import spec_lint_primitives as slp

REPO = slp.find_repo_root(start=Path(__file__).resolve().parent)  # honors SPEC_LINT_REPO_OVERRIDE
SPECS = REPO / ".factory" / "specs"

# Patterns and their policy origins
PLACEHOLDER_PATTERNS = [
    (re.compile(r"\bVP-TBD\b"), "VP-TBD (POL-14)"),
    (re.compile(r"\bSS-TBD\b"), "SS-TBD (POL-15)"),
    (re.compile(r"\[filled by [^\]]+\]", re.IGNORECASE), "[filled by ...] (POL-14/15 generalized)"),
]

# R2-RULE: VP-ID-COLUMN CONFORMANCE.
# A VP table header has exactly "VP-NNN" as its first cell.
_VP_TABLE_HEADER_CELL = "VP-NNN"

# A conforming VP-NNN cell value: single VP-NNN token (canonical 3-digit form)
_VP_TOKEN_RE = re.compile(r"^VP-\d{3}$")

# BC ID grammar: BC-S.SS.NNN (e.g. BC-2.10.004)
_BC_ID_RE = re.compile(r"^BC-\d+\.\d+\.\d+$")

# Table cell parsing and changelog scoping use shared primitives (BI-040 Stage 2):
#   slp.split_table_cells(), slp.is_table_separator_row(), slp.is_historical_changelog_line()


def _extract_bc_id(path: Path) -> "str | None":
    """Return the BC ID from a filename (e.g. BC-2.10.004.md -> 'BC-2.10.004'), or None.

    Only files whose stem matches the canonical BC-S.SS.NNN pattern are recognised.
    Selftest fixtures (SELFTEST-*.md) and non-BC spec files return None.
    """
    stem = path.stem
    return stem if _BC_ID_RE.match(stem) else None


def _load_vp_index_classifications(repo: Path) -> dict:
    """Parse VP-INDEX.md BC-to-VP table and return {bc_id: classification}.

    Scans for the BC-to-VP mapping table whose header row first cell is "BC".
    Returns the VP(s) column value for each recognised BC row, e.g.:
      "test-sufficient", "VP-001", "VP-001, VP-002", etc.

    Returns empty dict if VP-INDEX does not exist or has no BC-to-VP table.

    This is a JOIN, not an allowlist: the returned dict reflects what VP-INDEX
    actually says, and the caller enforces the cross-check (D-039).
    """
    vp_index_path = (
        repo / ".factory" / "specs" / "verification-properties" / "VP-INDEX.md"
    )
    if not vp_index_path.exists():
        return {}

    classifications: dict = {}
    lines = slp.cm_splitlines(vp_index_path.read_text(encoding="utf-8"))

    # State machine mirrors the VP-table state machine in check_file_lines.
    table_header_first_cell: "str | None" = None
    in_bc_vp_data = False

    for line in lines:
        if not line.startswith("|"):
            table_header_first_cell = None
            in_bc_vp_data = False
            continue
        cells = slp.split_table_cells(line)
        if not cells:
            table_header_first_cell = None
            in_bc_vp_data = False
            continue
        if slp.is_table_separator_row(cells):
            if table_header_first_cell == "BC":
                in_bc_vp_data = True
            else:
                in_bc_vp_data = False
            continue
        # Non-separator row
        if in_bc_vp_data:
            bc = cells[0] if cells else ""
            if _BC_ID_RE.match(bc) and len(cells) >= 3:
                # cells[2] is the VP(s) column (e.g. "test-sufficient", "VP-001")
                classifications[bc] = cells[2]
        else:
            table_header_first_cell = cells[0] if cells else None
            in_bc_vp_data = False

    return classifications


def _is_valid_vp_cell(
    first_cell: str,
    proof_method: str,
    bc_id: "str | None" = None,
    vp_classifications: "dict | None" = None,
) -> "tuple[bool, str]":
    """Return (is_valid, violation_detail_or_empty_string).

    Conforming values (R2-RULE + D-078 sentinel + operator-ruled sentinel):
      - One or more VP-NNN tokens (3-digit), comma- or slash-separated
      - VP-NONE sentinel, ONLY when proof_method is non-empty (D-078)
      - 'test-sufficient' sentinel, ONLY when VP-INDEX classifies the BC as
        test-sufficient (cross-checked via bc_id + vp_classifications)

    The 'test-sufficient' check is a JOIN (D-039): accepted only when
    VP-INDEX has a row for this BC and that row says 'test-sufficient'.
    If VP-INDEX assigns a real VP, or has no row for the BC, the sentinel
    is rejected with a distinct, actionable message.

    Everything else (em-dash, en-dash, TBD, none, empty, etc.) is non-conforming.
    """
    if not first_cell:
        return False, "non-conforming VP-NNN column value '' (POL-14)"

    # ── test-sufficient sentinel (operator-ruled; MUST be cross-checked) ──────
    if first_cell == "test-sufficient":
        if bc_id is None or vp_classifications is None:
            # File is not a recognisable BC (selftest fixture, non-BC spec, etc.)
            return False, (
                "non-conforming VP-NNN column value 'test-sufficient' (POL-14) — "
                "sentinel requires a BC filename (BC-S.SS.NNN) and VP-INDEX context"
            )
        if bc_id not in vp_classifications:
            return False, (
                f"non-conforming VP-NNN column value 'test-sufficient' (POL-14) — "
                f"'{bc_id}' has no row in VP-INDEX; assign a real VP or add a "
                f"'test-sufficient' row to VP-INDEX"
            )
        classification = vp_classifications[bc_id]
        if classification != "test-sufficient":
            return False, (
                f"non-conforming VP-NNN column value 'test-sufficient' (POL-14) — "
                f"VP-INDEX classifies '{bc_id}' as '{classification}'; "
                f"remove the sentinel and cite the real VP"
            )
        # D-078 precondition (symmetric with VP-NONE): Proof Method must be non-empty.
        # A row that names no test at all cannot assert test-sufficiency.
        if not bool(proof_method.strip()):
            return False, (
                "non-conforming VP-NNN column value 'test-sufficient' (POL-14) — "
                "Proof Method cell must be non-empty (D-078 precondition)"
            )
        return True, ""

    # ── VP-NONE sentinel (D-078): admitted only when Proof Method is non-empty ──
    if first_cell == "VP-NONE":
        if bool(proof_method.strip()):
            return True, ""
        return False, "non-conforming VP-NNN column value 'VP-NONE' (POL-14)"

    # ── Comma- or slash-separated list of VP-NNN tokens ──────────────────────
    # Filter empty tokens BEFORE the all() call: re.split(",", ",") yields ['', ''],
    # and all() over an empty iterator returns True — silently passing punctuation-only cells.
    tokens = [t.strip() for t in re.split(r"[,/]", first_cell) if t.strip()]
    if bool(tokens) and all(_VP_TOKEN_RE.match(t) for t in tokens):
        return True, ""
    return False, f"non-conforming VP-NNN column value '{first_cell}' (POL-14)"


# ── D-081 position-based predicates (no file-path-keyed exclusion sets) ─────

# Predicate 1: Changelog narrative section.
# An H3 heading text starting with a version marker (v\d+) begins a changelog
# narrative section. All placeholder tokens inside are historical — exempt.
_CHANGELOG_VERSION_H3_RE = re.compile(r'^v\d+')


def _is_changelog_narrative(current_h3_heading: "str | None") -> bool:
    """Return True if currently inside a changelog/version-history narrative section.

    A changelog narrative section begins when an H3 heading (### ...) whose text
    starts with a version marker (e.g. 'v1.4', 'v1.9') is encountered.  The
    section ends when any H1, H2, or non-version H3 heading is encountered.
    Position-based: fires on WHERE in the document a token appears, not which file.
    """
    if current_h3_heading is None:
        return False
    return bool(_CHANGELOG_VERSION_H3_RE.match(current_h3_heading))


# Predicate 2: Inline backtick span.
# A placeholder token inside a single-backtick inline code span is a cited
# reference, not a live placeholder — exempt.
_SINGLE_BACKTICK_RE = re.compile(r'(?<!`)`(?!`)')


def _is_inside_backtick_span(line: str, match_start: int) -> bool:
    """Return True if match_start is inside a single-backtick inline code span.

    Counts single backticks (not double or triple) before the match position.
    An odd count indicates the match is inside a code span.
    Position-based: fires on WHERE on a line a token appears, not which file.
    """
    before = line[:match_start]
    single_bts = _SINGLE_BACKTICK_RE.findall(before)
    return len(single_bts) % 2 == 1


def check_file_lines(
    md_file: Path,
    lines: list,
    bc_id: "str | None" = None,
    vp_classifications: "dict | None" = None,
) -> list:
    """Check a list of lines from md_file for placeholder violations.

    bc_id: the BC ID extracted from the filename (e.g. 'BC-2.10.004'), or None
           for non-BC files. Used for the test-sufficient VP-INDEX cross-check.
    vp_classifications: dict from _load_vp_index_classifications(), or None.

    Returns a list of (filepath, lineno, matched, pattern_name) tuples.
    """
    violations = []
    filepath = str(md_file)

    # Per-file state for R2-RULE table-context tracking
    in_fenced_code = False
    table_header_first_cell = None  # first cell of last non-separator | row
    in_vp_table_data = False        # True after VP-NNN header + separator row seen

    # Change 2 / S1-fix: track the current H2 heading for Stories-field exemption.
    # Set when a "## " heading is seen; cleared by ANY other ATX heading (H1, H3, …).
    # This bounds the exemption zone: a subheading under "## Story Anchor" resets it.
    # Only updated outside fenced blocks.
    current_h2_heading: "str | None" = None

    # D-081 Predicate 1: track the current H3 heading for changelog narrative exemption.
    # Set when a "### " heading is seen; cleared by H1, H2, or a new H3.
    # H4+ headings do NOT clear the H3 context (changelog sections extend through sub-headings).
    # If current_h3_heading starts with v\d+, the current position is inside a
    # changelog narrative section — all placeholder tokens are exempt.
    current_h3_heading: "str | None" = None

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

        # ── ATX heading tracking ──────────────────────────────────────────────
        # H2 headings: set current_h2_heading (Stories-field exemption, Change 2/S1-fix).
        #   Any non-H2 heading (H1, H3, H4…) clears current_h2_heading — this bounds the
        #   Shape 2 exemption zone (a subheading inside ## Story Anchor resets context).
        # H3 headings: set current_h3_heading (changelog narrative exemption, D-081 P1).
        #   H1 and H2 clear current_h3_heading.  H4+ do NOT clear it (changelog sections
        #   extend through sub-headings within the same narrative block).
        if not in_fenced_code and line.startswith("#"):
            _atx_rest = line.lstrip("#")
            if _atx_rest.startswith(" ") or not _atx_rest:
                if line.startswith("## ") and not line.startswith("### "):
                    current_h2_heading = _atx_rest.strip()
                    current_h3_heading = None  # H2 resets H3 context
                elif line.startswith("### ") and not line.startswith("#### "):
                    current_h3_heading = _atx_rest.strip()
                    current_h2_heading = None  # H3 resets H2 context (S1-fix preserved)
                elif line.startswith("# ") and not line.startswith("## "):
                    # H1: clear both H2 and H3 context
                    current_h2_heading = None
                    current_h3_heading = None
                else:
                    # H4+: clears H2 context (existing behavior preserved for Story Anchor)
                    # but does NOT clear H3 context (changelog sections extend through H4+)
                    current_h2_heading = None

        # ── Table-context state machine (R2-RULE, gated: suppressed inside fenced blocks) ──
        # VP-TBD, SS-TBD, and [filled by] are still checked inside fenced blocks via
        # PLACEHOLDER_PATTERNS below. Only the structural R2-RULE VP-NNN column check
        # is suppressed (fenced content is documentation, not live spec data).
        if not in_fenced_code:
            if line.startswith("|"):
                cells = slp.split_table_cells(line)
                if cells:
                    if slp.is_table_separator_row(cells):
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
                        is_valid, detail = _is_valid_vp_cell(
                            first_cell,
                            proof_method,
                            bc_id=bc_id,
                            vp_classifications=vp_classifications,
                        )
                        if not is_valid:
                            violations.append((filepath, lineno, first_cell, detail))
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
                # D-081 Predicate 1: skip if inside a changelog narrative section.
                # Fires on WHERE in the document (H3 version heading context), not on
                # which file. Covers prd.md:509 ([filled by architect] under ### v1.9),
                # prd.md:644 (VP-TBD ×3 under ### v1.4), prd.md:650 (SS-TBD ×3 under
                # ### v1.4), and any similar historical records in any other spec file.
                if _is_changelog_narrative(current_h3_heading):
                    continue
                # D-081 Predicate 2: skip if inside a backtick inline code span.
                # Fires on WHERE on the line (odd single-backtick count before match),
                # not on which file. A token inside `` `VP-TBD` `` is a cited reference.
                if _is_inside_backtick_span(line, m.start()):
                    continue
                # Skip VP-TBD / SS-TBD if they are inside a historical
                # changelog entry (quoted string with a version prefix).
                if matched in ("VP-TBD", "SS-TBD"):
                    if slp.is_historical_changelog_line(line, matched):
                        continue
                # Change 2: [filled by ...] in the Traceability Stories field is
                # EXEMPT (operator-ruled: stories unfillable at Phase-1 gate).
                # Two syntactic shapes:
                #   Shape 1: table row — field-name cell is exactly "Stories"
                #   Shape 2: bullet item under a "## Story Anchor" heading
                # All other [filled by ...] occurrences (different field-names,
                # prose, non-Stories contexts) remain violations.
                if "[filled by" in name:
                    # Shape 1: `| Stories | [filled by ...] |`
                    if line.startswith("|"):
                        row_cells = slp.split_table_cells(line)
                        if row_cells and row_cells[0] == "Stories":
                            continue
                    # Shape 2: `- [filled by ...]` under "## Story Anchor"
                    if (
                        current_h2_heading == "Story Anchor"
                        and line.lstrip().startswith("- ")
                    ):
                        continue
                violations.append((filepath, lineno, matched, name))

    return violations


def main() -> int:
    if not SPECS.exists():
        print(f"ERROR: Spec tree not found at {SPECS} — cannot run check (no spec files to validate)", file=sys.stderr)
        sys.exit(1)
    violations: list[tuple[str, int, str, str]] = []  # (filepath, lineno, matched, pattern_name)

    # Corpus size: compute once for completeness assertion (D-113 / D-081).
    # All .md files under .factory/specs/ are in scope — no file-path-keyed exclusions.
    total_files = sum(1 for _ in SPECS.rglob("*.md"))
    files_checked = 0

    # Load VP-INDEX classifications once (used for test-sufficient cross-check).
    vp_classifications = _load_vp_index_classifications(REPO)

    for md_file in sorted(SPECS.rglob("*.md")):
        files_checked += 1
        lines = slp.cm_splitlines(md_file.read_text(encoding="utf-8"))
        bc_id = _extract_bc_id(md_file)
        violations.extend(
            check_file_lines(
                md_file,
                lines,
                bc_id=bc_id,
                vp_classifications=vp_classifications,
            )
        )

    # Corpus completeness assertion: parts must sum to total (D-081, D-113).
    completeness = (
        "complete"
        if files_checked == total_files
        else f"INCOMPLETE — only {files_checked} of {total_files} scanned"
    )

    if violations:
        # Group by type for summary
        by_type: dict[str, int] = {}
        for filepath, lineno, matched, name in violations:
            print(f"{filepath}:{lineno}: placeholder '{matched}' [{name}]")
            by_type[name] = by_type.get(name, 0) + 1
        print()
        for name, count in sorted(by_type.items()):
            print(f"  {count:3d}  {name}")
        print(
            f"\nCheck FAILED: {len(violations)} placeholder occurrences found "
            f"across {files_checked} of {total_files} spec files ({completeness})"
        )
        return 1

    print(
        f"Check passed: 0 live placeholders found across "
        f"{files_checked} of {total_files} spec files ({completeness}) — "
        f"no VP-TBD, SS-TBD, [filled by], or non-conforming VP-NNN column values"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
