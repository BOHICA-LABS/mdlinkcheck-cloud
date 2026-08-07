#!/usr/bin/env python3
"""
check-id-resolution — POL-16
==============================
Every ID reference in any .factory/specs/ file must resolve to a definition
in its source of truth. Unresolvable references are reported.

ID families and their registries:
  CAP-NNN   -> domain-spec/capabilities.md (## CAP-NNN headings)
  DI-NNN    -> domain-spec/invariants.md (## DI-NNN headings)
  DD-NNN    -> domain-spec/decisions.md (## DD-NNN headings)
  BC-S.SS.NNN -> behavioral-contracts/ss-SS/BC-S.SS.NNN.md (file existence)
  VP-NNN    -> verification-properties/VP-INDEX.md (| VP-NNN |)
  ADR-NNN   -> architecture/decisions/ADR-NNN-*.md (file existence by prefix)
  NFR-NNN   -> prd-supplements/nfr-catalog.md (| NFR-NNN | headings)
  EC-NNN    -> prd-supplements/test-vectors.md (TABLE ROWS only) OR holdout pool
              Sub-lettered EC-NNNx valid if base EC-NNN is registered.
              NOTE: prose/changelog mentions of EC IDs in test-vectors.md or
              prd.md are NOT registrations — only table rows count.
  T-NN      -> prd-supplements/test-vectors.md (section 8 T1-T16 trap map)
              NOTE: existence check only. Semantic correctness (whether the
              cited trap is topically relevant to the citing row) is NOT
              mechanically automatable — requires human review.
  R-NN      -> product-brief.md (R1..R8 requirement IDs)
  HS-NNN    -> holdout-scenarios/HS-INDEX.md (| HS-NNN |)
  POL-NN    -> .factory/policies.yaml (- id: NN)

Non-conforming ID shape detection (R3-A + R3-B, D-069):
  R3-A (positional): in any markdown table whose header row's first cell is
    "EC" or "ID", every data row's first cell MUST match
    ^~?~?EC-\d{1,4}[a-z]?~?~?$ (strikethrough-tolerant). Any other first-cell
    value is "non-conforming EC ID in ID column".
  R3-B (class-level grammar): any token matching
    \b(CAP|DI|DD|VP|NFR|BC|ADR|HS|POL|EC)-[A-Za-z][A-Za-z0-9]*-\d+\b
    — a registered family prefix followed by an alphabetic segment and a
    numeric segment — is a non-conforming ID shape (e.g. EC-NEW-1, VP-DRAFT-3).
    Zero false positives on 133-file corpus (D-069).
  R3-C (historical scoping): R3-B findings are suppressed in two cases, both
    implemented as positional state or functions — never as named sets (D-039):
    1. Quoted YAML-changelog strings: line contains version marker v\d+.\d+ AND
       the match is in a quoted context. is_historical_changelog_line().
    2. Versioned-changelog sections (D-081): a non-conforming ID under a
       `### vN.N` ATX heading is a historical record immutable under D-034.
       Tracked via in_versioned_changelog_section state (check_file()).
       Entry: `^### v\d+\.\d+` (level-3 versioned heading).
       Exit:  any level-1/2/3 heading NOT matching the versioned pattern.
       Level-4+ headings are subsections and inherit the current state.
       Residual: a genuine live defect authored inside a versioned changelog
       section would be missed. Operator accepted this trade-off (D-081).
  Fenced code blocks (triple-backtick, CommonMark §4.5) are suppressed from
    both R3-A and R3-B.

Exit 1 if any unresolvable reference found.
"""
import os
import re
import sys
from pathlib import Path

REPO = Path(os.environ.get("SPEC_LINT_REPO_OVERRIDE", "")).resolve() if os.environ.get("SPEC_LINT_REPO_OVERRIDE") else Path(__file__).resolve().parent.parent.parent
SPECS = REPO / ".factory" / "specs"
FACTORY = REPO / ".factory"

# Source-of-truth files
CAPABILITIES = SPECS / "domain-spec" / "capabilities.md"
INVARIANTS = SPECS / "domain-spec" / "invariants.md"
DECISIONS = SPECS / "domain-spec" / "decisions.md"
VP_INDEX = SPECS / "verification-properties" / "VP-INDEX.md"
NFR_CATALOG = SPECS / "prd-supplements" / "nfr-catalog.md"
TEST_VECTORS = SPECS / "prd-supplements" / "test-vectors.md"
BRIEF = SPECS / "product-brief.md"
HS_INDEX = FACTORY / "holdout-scenarios" / "HS-INDEX.md"
POLICIES = FACTORY / "policies.yaml"
ADR_DIR = SPECS / "architecture" / "decisions"
BC_DIR = SPECS / "behavioral-contracts"

# R3-B: class-level non-conforming ID shape (would-be identifiers, D-069).
# Triple-segment shape: <FAMILY>-<alphabetic-word>-<digits>.
# An alphabetic word was interpolated where only registry digits belong.
# Precision: 12/12 true positives, 0 false positives on 133-file corpus
# (ws3-phase2-checker-repair-design.md §3.5).
_WOULD_BE_ID_RE = re.compile(
    r"\b(CAP|DI|DD|VP|NFR|BC|ADR|HS|POL|EC)-([A-Za-z][A-Za-z0-9]*)-(\d+)\b"
)

# R3-C: historical-changelog scoping (ported from check-placeholders.py).
# A line whose match is inside a quoted YAML changelog string
# (version marker present) is a historical record, not a live reference.
_IR_CHANGELOG_QUOTED = re.compile(r'"[^"]*v\d+\.\d+[^"]*"')

# R3-A: conforming EC-column first cell pattern (strikethrough-tolerant)
_EC_ID_CELL_RE = re.compile(r"^~{0,2}EC-\d{1,4}[a-z]?~{0,2}$")

# Table separator cell pattern
_TABLE_SEP_CELL_RE = re.compile(r"^:?-{2,}:?$")

# R3-C extended (D-081): versioned-changelog heading positional scoping.
# A ### vN.N ATX heading (exactly level 3, starting with a version token) marks
# a versioned changelog section. Non-conforming IDs inside such a section are
# historical records immutable under D-034 and must not be flagged.
# Level restriction to `###` (not `##` or `#`) is intentional: all observed
# versioned changelog entries in the corpus use level-3 headings; wider matching
# would risk extending the scope to non-changelog content.
_VERSIONED_CHANGELOG_HEADING_RE = re.compile(r"^### v\d+\.\d+")


def is_historical_changelog_line(line: str, matched_text: str) -> bool:
    """Return True if matched_text appears inside a quoted changelog entry on this line.

    R3-C: ported from check-placeholders.is_historical_changelog_line.
    A quoted changelog entry is a YAML list item like:
      - "v1.2: P2-M09 — replaced non-conforming EC-NEW-3 with registry-compliant EC-164"

    The predicate: the match is bracketed by double-quotes on the same line
    AND the line contains a version marker (v\\d+.\\d+).
    Implemented as a function (not a named set) per the suppression guard (D-039).
    """
    pos = line.find(matched_text)
    if pos == -1:
        return False
    before = line[:pos]
    after = line[pos + len(matched_text):]
    in_quotes = ('"' in before and '"' in after) or _IR_CHANGELOG_QUOTED.search(line) is not None
    has_version = bool(re.search(r"v\d+\.\d+", line))
    return in_quotes and has_version


def _split_cells(line: str) -> list:
    """Split a markdown table row into stripped cell values (ragged-safe)."""
    parts = line.split("|")
    if len(parts) < 2:
        return []
    inner = parts[1:]
    if inner and inner[-1].strip() == "":
        inner = inner[:-1]
    return [p.strip() for p in inner]


def _is_separator_row(cells: list) -> bool:
    """Return True if all non-empty cells are table separator cells (---, :--:, etc.)."""
    non_empty = [c for c in cells if c]
    return bool(non_empty) and all(_TABLE_SEP_CELL_RE.match(c) for c in non_empty)


def build_heading_ids(path: Path, pattern: str) -> set[str]:
    """Extract IDs from # headings matching `pattern` (e.g. 'CAP-\\d+')."""
    if not path.exists():
        return set()
    ids: set[str] = set()
    for line in path.read_text(encoding="utf-8").splitlines():
        m = re.search(pattern, line)
        if m and line.startswith("#"):
            ids.add(m.group(0))
    return ids


def build_table_ids(path: Path, pattern: str) -> set[str]:
    """Extract IDs from Markdown table rows matching `pattern`."""
    if not path.exists():
        return set()
    ids: set[str] = set()
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.startswith("|"):
            continue
        for m in re.finditer(pattern, line):
            ids.add(m.group(0))
    return ids


def build_file_ids(directory: Path, pattern: str) -> set[str]:
    """Extract IDs by scanning filenames in a directory for `pattern`."""
    if not directory.exists():
        return set()
    ids: set[str] = set()
    for p in directory.iterdir():
        m = re.search(pattern, p.name)
        if m:
            ids.add(m.group(0))
    return ids


def build_yaml_ids(path: Path, pattern: str) -> set[str]:
    """Extract IDs from a YAML file (plain text scan)."""
    if not path.exists():
        return set()
    ids: set[str] = set()
    for line in path.read_text(encoding="utf-8").splitlines():
        for m in re.finditer(pattern, line):
            ids.add(m.group(0))
    return ids


def build_valid_bc_ids() -> set[str]:
    """Return all BC-S.SS.NNN IDs for which a file exists."""
    ids: set[str] = set()
    for f in BC_DIR.rglob("BC-*.md"):
        if f.name.startswith("BC-INDEX"):
            continue
        m = re.match(r"(BC-\d+\.\d+\.\d+)\.md", f.name)
        if m:
            ids.add(m.group(1))
    return ids


def build_valid_ec_ids() -> set[str]:
    """Return all registered EC-NNN and EC-NNNx IDs.

    POL-16: the EC registry is test-vectors.md TABLE ROWS only.
    Prose mentions in test-vectors.md or prd.md (e.g. changelog entries
    like 'EC-102 was replaced by EC-151') are NOT registrations.

    Sub-lettered variants EC-NNNx (e.g. EC-015b, EC-094a) are valid if
    their base EC-NNN is registered. This matches how test-vectors.md
    references them: TV-015b → EC-015 (not EC-015b).

    The holdout pool declared in prd.md §5b is also a valid source:
    those IDs are registered even though they have no visible TV row.
    """
    base_nums: set[int] = set()  # numeric parts of registered base IDs

    # From test-vectors.md: scan TABLE ROWS ONLY (lines starting with |).
    # Any EC-NNN that appears in a table row is registered.
    if TEST_VECTORS.exists():
        for line in TEST_VECTORS.read_text(encoding="utf-8").splitlines():
            if not line.startswith("|"):
                continue  # skip prose, blockquotes, section headers
            for m in re.finditer(r"\bEC-(\d+)\b", line):
                base_nums.add(int(m.group(1)))

    # From prd.md: holdout pool only — the canonical declaration line.
    # Pattern: "Holdout vectors **(EC-079, EC-093, ...)**"
    prd = SPECS / "prd.md"
    if prd.exists():
        text = prd.read_text(encoding="utf-8")
        holdout_m = re.search(r"Holdout vectors\s+\*\*\(([^)]+)\)\*\*", text)
        if holdout_m:
            for m in re.finditer(r"\bEC-(\d+)\b", holdout_m.group(1)):
                base_nums.add(int(m.group(1)))

    # Build the full valid set: base IDs + sub-lettered variants
    ids: set[str] = set()
    for n in base_nums:
        # Also accept zero-padded and unpadded forms
        ids.add(f"EC-{n}")
        ids.add(f"EC-{n:03d}")
        # Sub-lettered: EC-NNNa through EC-NNNz
        for c in "abcdefghijklmnopqrstuvwxyz":
            ids.add(f"EC-{n}{c}")
            ids.add(f"EC-{n:03d}{c}")

    return ids


def build_valid_adr_ids() -> set[str]:
    """Return ADR-NNN IDs from ADR filenames."""
    if not ADR_DIR.exists():
        return set()
    ids: set[str] = set()
    for f in ADR_DIR.iterdir():
        m = re.match(r"(ADR-\d+)", f.name)
        if m:
            ids.add(m.group(1))
    return ids


def build_valid_r_ids() -> set[str]:
    """Return R-NN requirement IDs from product-brief.md.

    product-brief.md defines R1..R8 (R2 has sub-letters a/b/c).
    All equivalent reference forms are stored so lookup succeeds
    regardless of style: bare (R1), hyphenated (R-1), zero-padded
    hyphenated (R-001), zero-padded bare (R001).
    """
    # Bootstrap seed: covers R1..R9 in all reference styles.
    # R-009 is retained here because spec files legitimately cite it
    # as an oracle-run label (VP-026); removing it would introduce
    # false violations. The scraper below adds any IDs found in the
    # brief dynamically.
    ids = {
        # Bare forms: R1..R9 (R2 has sub-letters a/b/c per brief)
        "R1", "R2", "R2a", "R2b", "R2c", "R3", "R4", "R5", "R6", "R7", "R8", "R9",
        # Hyphenated single-digit: R-1..R-9
        "R-1", "R-2", "R-2a", "R-2b", "R-2c", "R-3", "R-4", "R-5", "R-6", "R-7", "R-8", "R-9",
        # Zero-padded hyphenated: R-001..R-009
        "R-001", "R-002", "R-002a", "R-002b", "R-002c",
        "R-003", "R-004", "R-005", "R-006", "R-007", "R-008", "R-009",
        # Zero-padded bare: R001..R009
        "R001", "R002", "R002a", "R002b", "R002c",
        "R003", "R004", "R005", "R006", "R007", "R008", "R009",
    }
    if BRIEF.exists():
        for line in BRIEF.read_text(encoding="utf-8").splitlines():
            for m in re.finditer(r"\bR-?(\d+[a-c]?)\b", line):
                num_str = m.group(1)
                # Store all equivalent reference forms so lookup succeeds
                # regardless of style used in citing documents.
                ids.add(f"R{num_str}")            # bare: R10
                ids.add(f"R-{num_str}")           # hyphenated: R-10
                try:
                    # Zero-padded: R-010 (3-digit minimum)
                    numeric_part = re.match(r"^(\d+)", num_str)
                    if numeric_part:
                        n = int(numeric_part.group(1))
                        suffix = num_str[len(numeric_part.group(1)):]  # any letter suffix
                        ids.add(f"R-{n:03d}{suffix}")   # e.g., R-010, R-002a
                        ids.add(f"R{n:03d}{suffix}")     # e.g., R010, R002a
                except ValueError:
                    pass
    return ids


def build_valid_pol_ids() -> set[str]:
    """Return POL-NN IDs from policies.yaml."""
    ids: set[str] = set()
    if POLICIES.exists():
        for line in POLICIES.read_text(encoding="utf-8").splitlines():
            m = re.match(r"\s*-\s*id:\s*(\d+)", line)
            if m:
                ids.add(f"POL-{int(m.group(1))}")
    return ids


# Build all registries
VALID_CAP = build_heading_ids(CAPABILITIES, r"CAP-\d+")
VALID_DI = build_heading_ids(INVARIANTS, r"DI-\d+")
# DD entries are in table rows in decisions.md (| DD-NNN | ... ), not headings
VALID_DD = build_table_ids(DECISIONS, r"DD-\d+")
VALID_VP = build_table_ids(VP_INDEX, r"VP-\d+")
VALID_NFR = build_table_ids(NFR_CATALOG, r"NFR-\d+")
VALID_HS = build_table_ids(HS_INDEX, r"HS-\d+")
VALID_BC = build_valid_bc_ids()
VALID_EC = build_valid_ec_ids()
VALID_ADR = build_valid_adr_ids()
VALID_R = build_valid_r_ids()
VALID_POL = build_valid_pol_ids()
# T-NN trap map: T1..T16 per test-vectors.md section 8
# Both "T1" and "T-1" forms are accepted (both appear in specs).
VALID_T = {f"T-{i}" for i in range(1, 17)} | {f"T{i}" for i in range(1, 17)}

# Files to skip (the registries themselves to avoid circular validation)
REGISTRY_FILES = {
    str(CAPABILITIES), str(INVARIANTS), str(DECISIONS),
    str(VP_INDEX), str(NFR_CATALOG), str(TEST_VECTORS),
    str(BRIEF), str(HS_INDEX), str(POLICIES),
}


def check_file(path: Path) -> list[str]:
    violations = []
    if str(path) in REGISTRY_FILES:
        return violations
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()

    def v(lineno, ref, family, valid_set):
        if ref not in valid_set:
            violations.append(
                f"{path}:{lineno}: unresolvable {family} reference '{ref}'"
            )

    # State for R3-A (EC-ID-column conformance) and fenced-code suppression
    in_fenced_code = False
    table_header_first_cell = None  # first cell of last non-separator | row
    in_ec_id_column_table = False   # True: in data rows of an EC/ID-column table

    # State for R3-C D-081 positional scoping: True when current position is
    # inside a versioned changelog section (under a `### vN.N` heading).
    in_versioned_changelog_section = False

    for lineno, line in enumerate(lines, 1):
        # ── Fenced code block suppression (CommonMark §4.5) ──────────────────
        # A line whose leftmost content starts with ``` and has fewer than 4
        # columns of indent is a fenced code block delimiter, not spec content.
        indent = len(line) - len(line.lstrip())
        if line.lstrip().startswith("```") and indent < 4:
            in_fenced_code = not in_fenced_code
            in_ec_id_column_table = False
            table_header_first_cell = None
            continue
        # ── Table-state tracking for R3-A (gated: suppressed inside fenced blocks) ──
        # Track whether we are in the data section of an EC/ID-column table.
        # r3a_first_cell is set when R3-A checks the first cell; used to
        # suppress R3-B double-reporting on the same token.
        # The existing EC/CAP/DI/DD/VP/NFR/BC/ADR/HS/POL resolution checks below
        # run regardless of in_fenced_code — only R3-A and R3-B are suppressed.
        r3a_first_cell = None

        if not in_fenced_code:
            if line.startswith("|"):
                cells = _split_cells(line)
                if cells:
                    if _is_separator_row(cells):
                        # Separator row: determine if this table's header was EC.
                        # "ID" is intentionally excluded: prd.md uses "| ID | Differentiator |"
                        # whose first-column cells are KD-NNN (Key Differentiators), not EC IDs.
                        if table_header_first_cell == "EC":
                            in_ec_id_column_table = True
                        else:
                            in_ec_id_column_table = False
                        # Separator rows carry no ID content; skip to next line
                        continue
                    elif in_ec_id_column_table:
                        # Data row in an EC-column table: apply R3-A
                        first_cell = cells[0]
                        r3a_first_cell = first_cell  # mark for R3-B suppression
                        if not _EC_ID_CELL_RE.match(first_cell):
                            violations.append(
                                f"{path}:{lineno}: non-conforming EC ID in ID column '{first_cell}'"
                            )
                        # Fall through so existing ID checks run on the full row
                    else:
                        # Header-candidate row (no separator yet for this table)
                        table_header_first_cell = cells[0]
                        in_ec_id_column_table = False
            else:
                # Non-| line: leave any current table context
                table_header_first_cell = None
                in_ec_id_column_table = False
                # D-081: update versioned-changelog section state on ATX headings.
                # Level 1-3 headings (# / ## / ###) change the section scope;
                # level 4+ are subsections that inherit the current scope.
                if line.startswith("#"):
                    m_hd = re.match(r"^(#{1,6})\s", line)
                    if m_hd and len(m_hd.group(1)) <= 3:
                        in_versioned_changelog_section = bool(
                            _VERSIONED_CHANGELOG_HEADING_RE.match(line)
                        )

        # ── Existing ID resolution checks ─────────────────────────────────────

        for m in re.finditer(r"\bCAP-(\d+)\b", line):
            ref = f"CAP-{m.group(1)}"
            v(lineno, ref, "CAP", VALID_CAP)

        for m in re.finditer(r"\bDI-(\d+)\b", line):
            ref = f"DI-{m.group(1)}"
            v(lineno, ref, "DI", VALID_DI)

        for m in re.finditer(r"\bDD-(\d+)\b", line):
            ref = f"DD-{m.group(1)}"
            v(lineno, ref, "DD", VALID_DD)

        # VP-(\d+): the guard "if ref != 'VP-TBD'" was removed.
        # The pattern r"\bVP-(\d+)\b" requires digits after VP-,
        # so it can never yield "VP-TBD" — the guard was unreachable (latent bug,
        # ws3-phase2-checker-repair-design.md §3.2 / §3.7 note).
        for m in re.finditer(r"\bVP-(\d+)\b", line):
            ref = f"VP-{m.group(1)}"
            v(lineno, ref, "VP", VALID_VP)

        for m in re.finditer(r"\bNFR-(\d+)\b", line):
            ref = f"NFR-{m.group(1)}"
            v(lineno, ref, "NFR", VALID_NFR)

        for m in re.finditer(r"\b(BC-\d+\.\d+\.\d+)\b", line):
            ref = m.group(1)
            if ref not in VALID_BC:
                violations.append(
                    f"{path}:{lineno}: unresolvable BC reference '{ref}'"
                )

        for m in re.finditer(r"\b(ADR-\d+)\b", line):
            ref = m.group(1)
            v(lineno, ref, "ADR", VALID_ADR)

        for m in re.finditer(r"\b(HS-\d+)\b", line):
            ref = m.group(1)
            v(lineno, ref, "HS", VALID_HS)

        for m in re.finditer(r"\b(POL-\d+)\b", line):
            ref = m.group(1)
            v(lineno, ref, "POL", VALID_POL)

        # R-NN requirement IDs: must be in product-brief.md
        for m in re.finditer(r"\bR-?(\d{1,3}[a-c]?)\b", line):
            ref = m.group(0)
            # Normalize to R-NNN form for lookup
            normalized = ref if ref.startswith("R-") else f"R-{m.group(1)}"
            if normalized not in VALID_R and ref not in VALID_R:
                violations.append(
                    f"{path}:{lineno}: unresolvable R requirement reference '{ref}'"
                )

        # EC-NNN and EC-NNNx: must be registered in test-vectors.md table rows
        # or holdout pool. Prose mentions and changelog entries are NOT registrations.
        for m in re.finditer(r"\bEC-(\d+)([a-z]?)\b", line):
            ref = f"EC-{m.group(1)}{m.group(2)}"
            if ref not in VALID_EC:
                violations.append(
                    f"{path}:{lineno}: unresolvable EC reference '{ref}' "
                    f"(not in test-vectors.md table rows or holdout pool)"
                )

        # T-NN trap citations: out-of-range values are violations.
        # Valid range is T1..T16 (both "T1" and "T-1" forms accepted).
        # NOTE: semantic correctness (whether the cited trap is topically relevant
        # to the citing row) is NOT mechanically automatable and requires human review.
        for m in re.finditer(r"\bT-?(\d{1,2})\b", line):
            ref = m.group(0)
            num = int(m.group(1))
            if num < 1 or num > 16:
                violations.append(
                    f"{path}:{lineno}: trap reference '{ref}' out of range (valid range T1..T16)"
                )
            # T references within T1..T16 are valid — no action needed

        # ── R3-B: class-level non-conforming ID shape (D-069) ─────────────────
        # Any token of shape <FAMILY>-<alpha-segment>-<digits> is a non-conforming
        # would-be ID. The alpha segment distinguishes a placeholder from a
        # well-formed ID (digits-only suffix). Zero FPs on 133-file corpus.
        # Gated: suppressed inside fenced code blocks (CommonMark §4.5).
        if not in_fenced_code:
            for m in _WOULD_BE_ID_RE.finditer(line):
                token = m.group(0)
                # R3-A priority: skip tokens already handled by R3-A on this line
                # (avoids double-reporting the same first-cell violation)
                if r3a_first_cell is not None and token == r3a_first_cell:
                    continue
                # R3-C(1): quoted YAML-changelog line — not a live reference
                if is_historical_changelog_line(line, token):
                    continue
                # R3-C(2): versioned-changelog section positional scoping (D-081).
                # Under a `### vN.N` heading, the entry is an immutable historical
                # record (D-034) — flagging it would create a permanently-unresolvable
                # finding. Positional state, not a named set.
                if in_versioned_changelog_section:
                    continue
                family = m.group(1)
                violations.append(
                    f"{path}:{lineno}: non-conforming {family} ID shape '{token}' "
                    f"(expected {family}-NNN)"
                )

    return violations


def main() -> int:
    if not SPECS.exists():
        print(f"ERROR: Spec tree not found at {SPECS} — cannot run check (no spec files to validate)", file=sys.stderr)
        sys.exit(1)
    all_violations: list[str] = []
    files_checked = 0

    # Check all .md files under .factory/specs/
    for md_file in sorted(SPECS.rglob("*.md")):
        violations = check_file(md_file)
        all_violations.extend(violations)
        files_checked += 1

    # Also check .factory/policies.yaml and other yaml
    for yaml_file in sorted(FACTORY.glob("*.yaml")):
        violations = check_file(yaml_file)
        all_violations.extend(violations)

    if all_violations:
        for v in all_violations:
            print(v)
        print(
            f"\nCheck FAILED: {len(all_violations)} unresolvable ID references found "
            f"({files_checked} files checked)"
        )
        return 1

    print(f"Check passed: {files_checked} files checked — all ID references resolve")
    return 0


if __name__ == "__main__":
    sys.exit(main())
