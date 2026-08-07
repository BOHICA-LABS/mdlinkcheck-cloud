"""
test_spec_lint_primitives.py — unit tests for spec_lint_primitives (BI-040 Stage 1)
====================================================================================
9 tests covering the public API of spec_lint_primitives.py.

Runs standalone: python3 test_spec_lint_primitives.py
  Exit 0: all 9 tests passed.
  Exit 1: one or more tests failed.
  Exit 2: structural failure (wrong test count).

The discovery-based tests (test_cm_splitlines_closed_under_discovery,
test_cm_strip_cell_closed_under_discovery) iterate U+0000–U+10FFFF to derive
the divergent codepoint sets programmatically at test time. They do NOT
hardcode the specific codepoints; they assert the count and the behavioral
property for each member of the derived set. If future Python/Unicode versions
expand either set, these tests will fail automatically — which is the intent.

These tests run in a separate runner (test_primitives.sh) and do NOT count
toward run-selftests.sh's EXPECTED_TEST_COUNT / TESTS_RUN.
"""
import os
import sys
import tempfile
import shutil
from pathlib import Path

# Add scripts/spec-lint/ to sys.path so `import spec_lint_primitives` works
# regardless of the current working directory.
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import spec_lint_primitives as slp

# ── Test registry ────────────────────────────────────────────────────────────

TESTS: list = []
EXPECTED_PRIMITIVE_TEST_COUNT = 10


def register(fn):
    """Decorator: register fn as a test case."""
    TESTS.append(fn)
    return fn


# ── Test 1: cm_splitlines — closed under discovery ───────────────────────────

@register
def test_cm_splitlines_closed_under_discovery() -> None:
    """
    Property: cm_splitlines() handles every codepoint where Python's splitlines()
    diverges from CommonMark's line-ending semantics.

    Method: iterate all Unicode codepoints, identify divergent codepoints
    programmatically (no hardcoded list), assert cm_splitlines() agrees with
    split('\\n') for each non-CR divergent codepoint.

    Asserts:
    - Total count of splitlines-divergent codepoints == 9.
    - Non-CR count == 8.
    - cm_splitlines() agrees with split('\\n') for all 8 non-CR divergent codepoints.

    This test FAILS under Mutation 1 (revert cm_splitlines to str.splitlines):
    splitlines() would split on U+000C etc., producing a different result from
    split('\\n') for those codepoints, violating the assertion.
    """
    # Positive: verify cm_splitlines actually splits on LF (B2 regression guard).
    # The property-test below checks divergent codepoints but not the basic LF case.
    assert slp.cm_splitlines("a\nb\nc") == ["a", "b", "c"], "cm_splitlines must split on LF"
    assert slp.cm_splitlines("") == [""], "cm_splitlines('') must return ['']"
    assert slp.cm_splitlines("a\n") == ["a", ""], "cm_splitlines trailing LF"
    assert slp.cm_splitlines("\n") == ["", ""], "cm_splitlines lone LF"

    # Derive the full divergent set (including CR)
    all_divergent = []
    divergent_non_cr = []
    for cp in range(0x110000):
        ch = chr(cp)
        s = ch + "x"
        if s.splitlines() != s.split("\n"):
            all_divergent.append(cp)
            if cp != 0x000D:
                # Exclude CR: it IS a CommonMark line ending; cm_splitlines
                # intentionally defers CRLF handling (see CRLF residual in docstring).
                divergent_non_cr.append(cp)

    # Count assertion: detects growth OR shrinkage of the divergent class.
    assert len(all_divergent) == 9, (
        f"Expected exactly 9 splitlines-divergent codepoints (total), "
        f"found {len(all_divergent)}: "
        f"{[hex(cp) for cp in all_divergent]}"
    )
    assert len(divergent_non_cr) == 8, (
        f"Expected exactly 8 non-CR splitlines-divergent codepoints, "
        f"found {len(divergent_non_cr)}: "
        f"{[hex(cp) for cp in divergent_non_cr]}"
    )

    # Behavioral assertion: cm_splitlines agrees with split("\n") for all
    # non-CR divergent codepoints. This is the correctness proof.
    for cp in divergent_non_cr:
        ch = chr(cp)
        test_string = f"before{ch}## Heading"
        result = slp.cm_splitlines(test_string)
        expected = test_string.split("\n")
        assert result == expected, (
            f"cm_splitlines split on U+{cp:04X} (not a CommonMark line ending): "
            f"got {result!r}, expected {expected!r}"
        )


# ── Test 2: cm_strip_cell — closed under discovery ───────────────────────────

@register
def test_cm_strip_cell_closed_under_discovery() -> None:
    """
    Property: cm_strip_cell() strips only CommonMark whitespace, not the 23
    additional codepoints that Python's str.strip() removes.

    Method: iterate all Unicode codepoints, identify codepoints where Python's
    strip() diverges from CommonMark's whitespace definition, assert cm_strip_cell
    does NOT strip those codepoints.

    Asserts:
    - Total count of strip-divergent codepoints == 23.
    - cm_strip_cell() does NOT strip any of those 23 codepoints.

    This test FAILS under Mutation 2 (revert cm_strip_cell to str.strip):
    str.strip() would remove the divergent codepoints, violating the assertion.
    """
    # CommonMark §2.1 whitespace: U+0009 U+000A U+000B U+000C U+000D U+0020
    cm_ws = {0x0009, 0x000A, 0x000B, 0x000C, 0x000D, 0x0020}

    # Derive codepoints where Python strips but CommonMark does not
    divergent_strip = []
    for cp in range(0x110000):
        ch = chr(cp)
        py_strips = (ch.strip() == "")
        cm_would_strip = cp in cm_ws
        if py_strips and not cm_would_strip:
            divergent_strip.append(cp)

    # Count assertion: detects growth OR shrinkage of the divergent class.
    assert len(divergent_strip) == 23, (
        f"Expected exactly 23 strip-divergent codepoints, "
        f"found {len(divergent_strip)}: "
        f"{[hex(cp) for cp in divergent_strip]}"
    )

    # Behavioral assertion: cm_strip_cell does NOT strip any divergent codepoint.
    for cp in divergent_strip:
        ch = chr(cp)
        cell = f"{ch}word"
        result = slp.cm_strip_cell(cell)
        assert result == cell, (
            f"cm_strip_cell incorrectly stripped U+{cp:04X} (not a CommonMark "
            f"whitespace character): got {result!r}, expected {cell!r}"
        )


# ── Test 3: is_conforming_vp_cell ────────────────────────────────────────────

@register
def test_is_conforming_vp_cell() -> None:
    """
    Conforming VP-cell values (R2-RULE):
    - VP-NNN (exactly 3 decimal digits)
    - Multiple VP-NNN tokens separated by comma or slash
    - VP-NONE, ONLY when proof_method is non-empty (D-078)

    Non-conforming: em-dash, VP-TBD, VP-NONE with empty proof, VP-1234 (4 digits),
    empty string, etc.

    This test FAILS if the grammar is relaxed (e.g. accepting em-dashes or
    VP-TBD as conforming).
    """
    # Conforming cases
    assert slp.is_conforming_vp_cell("VP-001", "unit test"), "VP-001 should be conforming"
    assert slp.is_conforming_vp_cell("VP-123", "integration test"), "VP-123 should be conforming"
    assert slp.is_conforming_vp_cell("VP-999", "any proof"), "VP-999 should be conforming"
    assert slp.is_conforming_vp_cell("VP-001,VP-002", "proof"), "comma-sep should be conforming"
    assert slp.is_conforming_vp_cell("VP-001/VP-002", "proof"), "slash-sep should be conforming"
    assert slp.is_conforming_vp_cell("VP-NONE", "explicit N/A: axiom"), (
        "VP-NONE with non-empty proof_method should be conforming"
    )

    # Non-conforming cases
    assert not slp.is_conforming_vp_cell("", "proof"), "empty cell should be non-conforming"
    assert not slp.is_conforming_vp_cell("—", "proof"), "em-dash should be non-conforming"
    assert not slp.is_conforming_vp_cell("–", "proof"), "en-dash should be non-conforming"
    assert not slp.is_conforming_vp_cell("VP-TBD", "proof"), "VP-TBD should be non-conforming"
    assert not slp.is_conforming_vp_cell("VP-NONE", ""), (
        "VP-NONE with empty proof_method should be non-conforming (D-078)"
    )
    assert not slp.is_conforming_vp_cell("VP-NONE", "   "), (
        "VP-NONE with whitespace-only proof_method should be non-conforming (D-078)"
    )
    assert not slp.is_conforming_vp_cell("VP-1234", "proof"), "4 digits should be non-conforming"
    assert not slp.is_conforming_vp_cell("VP-12", "proof"), "2 digits should be non-conforming"
    assert not slp.is_conforming_vp_cell("TBD", "proof"), "TBD should be non-conforming"
    assert not slp.is_conforming_vp_cell("none", "proof"), "'none' should be non-conforming"
    assert not slp.is_conforming_vp_cell("[filled by story-writer]", "proof"), (
        "filled-by placeholder should be non-conforming"
    )

    # Punctuation-only cells: must be non-conforming (B1 regression guard).
    # These split into empty tokens; the old code used `if t.strip(...)` guard
    # inside all(), which made all() vacuously True on an all-empty token list.
    assert not slp.is_conforming_vp_cell(",", "proof"), "comma-only must be non-conforming"
    assert not slp.is_conforming_vp_cell("/", "proof"), "slash-only must be non-conforming"
    assert not slp.is_conforming_vp_cell(",,,", "proof"), "all-commas must be non-conforming"
    assert not slp.is_conforming_vp_cell(",/,", "proof"), "punctuation-only must be non-conforming"


# ── Test 4: is_conforming_ec_cell ────────────────────────────────────────────

@register
def test_is_conforming_ec_cell() -> None:
    """
    EC_CELL_RE: ^~{0,2}EC-\\d{1,4}[a-z]?~{0,2}$
    Conforming: EC-NNN, EC-NNNx (1-4 digits, optional lowercase), strikethrough-tolerant.
    Non-conforming: triple-segment (EC-NEW-3), 5+ digits, empty.

    This test FAILS if the grammar is widened (e.g. accepting EC-NEW-3).
    """
    # Conforming cases
    assert slp.is_conforming_ec_cell("EC-001"), "EC-001 should be conforming"
    assert slp.is_conforming_ec_cell("EC-1"), "EC-1 (1 digit) should be conforming"
    assert slp.is_conforming_ec_cell("EC-9999"), "EC-9999 (4 digits) should be conforming"
    assert slp.is_conforming_ec_cell("EC-1a"), "EC-1a (with suffix) should be conforming"
    assert slp.is_conforming_ec_cell("EC-99z"), "EC-99z should be conforming"
    assert slp.is_conforming_ec_cell("~~EC-001~~"), "~~EC-001~~ (strikethrough) should be conforming"
    assert slp.is_conforming_ec_cell("~~EC-1a~~"), "~~EC-1a~~ should be conforming"
    assert slp.is_conforming_ec_cell("~EC-001~"), "~EC-001~ (1-tilde) should be conforming"

    # Non-conforming cases
    assert not slp.is_conforming_ec_cell("EC-NEW-3"), "EC-NEW-3 (triple-segment) non-conforming"
    assert not slp.is_conforming_ec_cell("EC-DRAFT"), "EC-DRAFT non-conforming"
    assert not slp.is_conforming_ec_cell("EC-10000"), "EC-10000 (5 digits) non-conforming"
    assert not slp.is_conforming_ec_cell(""), "empty cell non-conforming"
    assert not slp.is_conforming_ec_cell("EC-001A"), "EC-001A (uppercase suffix) non-conforming"
    assert not slp.is_conforming_ec_cell("EC-"), "EC- with no digits non-conforming"
    assert not slp.is_conforming_ec_cell("TV-001"), "TV-001 (wrong family) non-conforming"


# ── Test 5: is_conforming_ec_token ───────────────────────────────────────────

@register
def test_is_conforming_ec_token() -> None:
    """
    EC_TOKEN_RE: \\bEC-(\\d{1,4})([a-z]?)\\b
    is_conforming_ec_token strips leading/trailing ~ before fullmatch.

    This test FAILS if the token grammar is widened (e.g. accepting EC-NEW-3).
    """
    # Conforming tokens
    assert slp.is_conforming_ec_token("EC-001"), "EC-001 should be conforming"
    assert slp.is_conforming_ec_token("EC-1"), "EC-1 (1 digit) should be conforming"
    assert slp.is_conforming_ec_token("EC-9999"), "EC-9999 (4 digits) should be conforming"
    assert slp.is_conforming_ec_token("EC-1a"), "EC-1a should be conforming"
    assert slp.is_conforming_ec_token("~~EC-001~~"), "~~EC-001~~ after stripping ~ should be conforming"

    # Non-conforming tokens
    assert not slp.is_conforming_ec_token("EC-NEW-3"), "EC-NEW-3 non-conforming"
    assert not slp.is_conforming_ec_token("EC-TMP-4"), "EC-TMP-4 non-conforming"
    assert not slp.is_conforming_ec_token("EC-10000"), "EC-10000 (5 digits) non-conforming"
    assert not slp.is_conforming_ec_token(""), "empty string non-conforming"
    assert not slp.is_conforming_ec_token("EC-"), "EC- with no digits non-conforming"
    assert not slp.is_conforming_ec_token("DI-PENDING-2"), "DI-PENDING-2 non-conforming"


# ── Test 6: split_table_cells ────────────────────────────────────────────────

@register
def test_split_table_cells() -> None:
    """
    split_table_cells returns [] when there is non-whitespace before the first
    pipe (prose lines containing pipes are rejected). Leading CM whitespace IS
    allowed. Strips trailing empty cell and applies cm_strip_cell to each cell.

    Key property: NBSP (U+00A0) in a cell is NOT stripped (cm_strip_cell uses
    only CM whitespace). This distinguishes split_table_cells from a naive
    line.split("|") + strip() implementation.

    Also tests is_table_separator_row.
    """
    # Standard table row
    assert slp.split_table_cells("| VP-001 | some text | unit test |") == [
        "VP-001", "some text", "unit test"
    ], "standard 3-cell row"

    # Trailing pipe present
    assert slp.split_table_cells("| EC-001 | description |") == [
        "EC-001", "description"
    ], "trailing pipe stripped"

    # No trailing pipe
    assert slp.split_table_cells("| EC-001 | description") == [
        "EC-001", "description"
    ], "no trailing pipe handled"

    # Single cell
    assert slp.split_table_cells("| VP-001 |") == ["VP-001"], "single cell row"

    # Line with no pipe
    assert slp.split_table_cells("no pipe line") == [], "no pipe returns empty list"

    # NBSP (U+00A0) in cell is NOT stripped — distinguishes cm_strip_cell from str.strip()
    nbsp = " "
    result = slp.split_table_cells(f"| {nbsp}VP-001{nbsp} | text |")
    assert result[0] == f"{nbsp}VP-001{nbsp}", (
        f"NBSP in cell should NOT be stripped by cm_strip_cell, got {result[0]!r}"
    )

    # Separator row detection
    sep_cells = slp.split_table_cells("| --- | :---: | ---: |")
    assert slp.is_table_separator_row(sep_cells), "separator row should be detected"

    data_cells = slp.split_table_cells("| VP-001 | some text |")
    assert not slp.is_table_separator_row(data_cells), "data row should not be detected as separator"

    # Empty list → not a separator
    assert not slp.is_table_separator_row([]), "empty list is not a separator row"

    # Ragged row (1 cell)
    assert slp.split_table_cells("| a |") == ["a"], "ragged 1-cell row"

    # W7 contract: prose before the first pipe is not a table row
    assert slp.split_table_cells("See: | EC-001 | desc |") == [], (
        "non-whitespace before first '|' must not be parsed as a table row"
    )
    # W7 contract: leading CommonMark whitespace IS allowed (table row with indent)
    assert slp.split_table_cells("  | VP-001 | x |") == ["VP-001", "x"], (
        "leading CM whitespace before first '|' is still a table row"
    )


# ── Test 7: find_repo_root — fail closed ─────────────────────────────────────

@register
def test_find_repo_root_fail_closed() -> None:
    """
    find_repo_root raises RuntimeError when a .git boundary is found before
    .factory/specs/. This is the fail-CLOSED behavior (D-082).

    We do NOT use SPEC_LINT_REPO_OVERRIDE in this test — we use a unique env
    var name to ensure the test is hermetic against any ambient override.
    """
    tmpdir = tempfile.mkdtemp(prefix="slp_test_failclosed_")
    try:
        # Create a .git file (as in linked worktrees) inside tmpdir, but no .factory/specs/
        (Path(tmpdir) / ".git").write_text("gitdir: /fake")

        try:
            slp.find_repo_root(env_var="SLP_TEST_NONEXISTENT_VAR_BF040_7", start=Path(tmpdir))
            raise AssertionError(
                "find_repo_root should have raised RuntimeError at .git boundary, "
                "but it returned without error"
            )
        except RuntimeError as e:
            # Must mention the boundary stop, not a generic error
            assert "repository boundary" in str(e) or "find_repo_root" in str(e), (
                f"RuntimeError message should mention boundary or find_repo_root, got: {e}"
            )
    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)


# ── Test 8: find_repo_root — override honored ────────────────────────────────

@register
def test_find_repo_root_override_honored() -> None:
    """
    find_repo_root returns the env var path when the env var is set, without
    performing any filesystem walk.

    Uses a unique env var name (not SPEC_LINT_REPO_OVERRIDE) to keep this
    test hermetic.
    """
    TEST_VAR = "SLP_TEST_OVERRIDE_BF040_8"
    sentinel_path = "/tmp/slp_test_override_sentinel_bf040"

    # Set the test-specific env var, ensure it isn't already set
    original = os.environ.get(TEST_VAR)
    os.environ[TEST_VAR] = sentinel_path

    try:
        # start points to a dir with no .factory/specs/ — the env var must take priority
        result = slp.find_repo_root(env_var=TEST_VAR, start=Path("/tmp"))
        # find_repo_root calls Path(override).resolve() which expands symlinks
        # (e.g. /tmp → /private/tmp on macOS). Compare resolved paths.
        expected = Path(sentinel_path).resolve()
        assert result == expected, (
            f"Expected find_repo_root to return override path {expected!r} "
            f"(resolved from {sentinel_path!r}), got {result!r}"
        )
    finally:
        if original is None:
            del os.environ[TEST_VAR]
        else:
            os.environ[TEST_VAR] = original


# ── Test 9: find_repo_root — hermetic (ambient SPEC_LINT_REPO_OVERRIDE ignored)

@register
def test_find_repo_root_hermetic() -> None:
    """
    find_repo_root(env_var="CUSTOM_VAR") ignores an ambient SPEC_LINT_REPO_OVERRIDE.

    This is the BI-045 lesson: when a test passes env_var="CUSTOM_VAR", the
    ambient SPEC_LINT_REPO_OVERRIDE must have no effect. find_repo_root should
    walk the filesystem from `start` and find .factory/specs/ there, NOT
    return the ambient SPEC_LINT_REPO_OVERRIDE path.
    """
    TEST_VAR = "SLP_TEST_HERMETIC_BF040_9"
    # Unique sentinel so we can verify the ambient override is NOT used
    AMBIENT_SENTINEL = "/tmp/slp_test_hermetic_AMBIENT_bf040_9"

    tmpdir = tempfile.mkdtemp(prefix="slp_test_hermetic_")
    original_override = os.environ.get("SPEC_LINT_REPO_OVERRIDE")
    original_test_var = os.environ.get(TEST_VAR)

    try:
        # Create .factory/specs/ inside tmpdir so the walk succeeds
        (Path(tmpdir) / ".factory" / "specs").mkdir(parents=True)

        # Set ambient SPEC_LINT_REPO_OVERRIDE to a DIFFERENT path (red herring)
        os.environ["SPEC_LINT_REPO_OVERRIDE"] = AMBIENT_SENTINEL

        # Ensure TEST_VAR is not set (so the walk fires, not the override)
        if TEST_VAR in os.environ:
            del os.environ[TEST_VAR]

        # Call with env_var=TEST_VAR — must walk from tmpdir, ignore SPEC_LINT_REPO_OVERRIDE
        result = slp.find_repo_root(env_var=TEST_VAR, start=Path(tmpdir))

        assert result == Path(tmpdir).resolve(), (
            f"find_repo_root should have found .factory/specs/ in tmpdir={tmpdir!r} "
            f"(resolved: {Path(tmpdir).resolve()!r}), but got {result!r}. "
            f"Possible contamination: ambient SPEC_LINT_REPO_OVERRIDE={AMBIENT_SENTINEL!r} "
            f"was used instead of walking. "
            f"Note: resolved comparison required because find_repo_root calls Path(start).resolve() "
            f"(W3 — BI-040), which may change /tmp to /private/tmp on macOS."
        )
        assert str(result) != AMBIENT_SENTINEL, (
            f"find_repo_root returned the ambient SPEC_LINT_REPO_OVERRIDE path, "
            f"not the walked-to root. env_var isolation is broken."
        )

    finally:
        # Restore original env state
        if original_override is None:
            os.environ.pop("SPEC_LINT_REPO_OVERRIDE", None)
        else:
            os.environ["SPEC_LINT_REPO_OVERRIDE"] = original_override

        if original_test_var is None:
            os.environ.pop(TEST_VAR, None)
        else:
            os.environ[TEST_VAR] = original_test_var

        shutil.rmtree(tmpdir, ignore_errors=True)


# ── Test 10: is_historical_changelog_line ────────────────────────────────────

@register
def test_is_historical_changelog_line() -> None:
    """Pin behavior of is_historical_changelog_line — including known overreach.

    The function has two disjuncts for in_quotes:
      1. '"' before AND '"' after the match position on the same line.
      2. _CHANGELOG_VERSION_RE matches anywhere on the line (quoted version marker).

    Disjunct 2 is a known over-approximation: if a quoted version string appears
    anywhere on the line, ALL matches on that line are suppressed, even those
    outside the quoted section. This test pins that behaviour so a future
    tightening is an explicit visible change. (W6 — BI-040)
    """
    # Canonical case: match inside quoted changelog entry (disjunct 1 + version)
    line = '  - "v1.2: renamed EC-001 to EC-002 — CLOSED"'
    assert slp.is_historical_changelog_line(line, "EC-001"), (
        "match inside quotes with version marker should return True"
    )

    # Negative: plain non-changelog line (no quotes, no version marker)
    line2 = "EC-NEW-3 is used here"
    assert not slp.is_historical_changelog_line(line2, "EC-NEW-3"), (
        "plain line with no quotes and no version marker should return False"
    )

    # Known overreach (disjunct 2): a quoted version string on the same line
    # suppresses a match that is OUTSIDE the quotes. Current impl sets in_quotes=True
    # via _CHANGELOG_VERSION_RE even though EC-NEW-3 appears after the closing quote.
    line3 = '- "v1.2: replaced EC-001" but EC-NEW-3 is still outside'
    assert slp.is_historical_changelog_line(line3, "EC-NEW-3"), (
        "known overreach: match outside quotes suppressed if quoted version marker present"
    )

    # Negative: missing version marker (only bare quotes, no v\d+\.\d+)
    line4 = '"EC-001 appears here but no version marker"'
    assert not slp.is_historical_changelog_line(line4, "EC-001"), (
        "quotes present but no version marker — has_version is False, must return False"
    )

    # Negative: matched_text not found on line at all
    line5 = '- "v1.0: renamed EC-001 to EC-002"'
    assert not slp.is_historical_changelog_line(line5, "EC-999"), (
        "matched_text absent from line should return False"
    )

    # S3: version marker alone (no quotes) must NOT suppress — quote logic is load-bearing
    assert not slp.is_historical_changelog_line(
        "v1.2 mentions EC-001 in plain prose, no quotes", "EC-001"
    ), "version marker without quotes must not suppress"

    # S3: disjunct 1 — quote-bracketed match where version marker is outside the quotes
    assert slp.is_historical_changelog_line('v1.2 - "EC-001 renamed"', "EC-001"), (
        "quote-bracketed match with version marker outside quotes should suppress"
    )


# ── Test runner ──────────────────────────────────────────────────────────────

if __name__ == "__main__":
    # Structural guard: ensure all 9 tests are actually registered.
    # A silently-skipped test would reduce this count.
    if len(TESTS) != EXPECTED_PRIMITIVE_TEST_COUNT:
        print(
            f"STRUCTURAL FAILURE: expected {EXPECTED_PRIMITIVE_TEST_COUNT} registered tests, "
            f"found {len(TESTS)}. "
            "Check that all test functions are decorated with @register.",
            file=sys.stderr,
        )
        sys.exit(2)

    failed = 0
    for t in TESTS:
        try:
            t()
            print(f"  PASS: {t.__name__}")
        except AssertionError as exc:
            print(f"  FAIL: {t.__name__}: {exc}")
            failed += 1
        except Exception as exc:
            print(f"  ERROR: {t.__name__}: {type(exc).__name__}: {exc}")
            failed += 1

    total = len(TESTS)
    print(f"\n{total - failed}/{total} primitive tests passed")

    if failed > 0:
        sys.exit(1)
    sys.exit(0)
