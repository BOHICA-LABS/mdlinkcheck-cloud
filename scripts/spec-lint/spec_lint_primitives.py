"""
spec_lint_primitives — shared primitives for spec-lint checkers (BI-040)
========================================================================
CommonMark-faithful text processing functions for use by all spec-lint
checkers and generators. This module has no entry point and produces no
side effects when imported.

Stage 1 (WS-3b-1): module is importable; nothing imports it yet.
Stages 2-3 will migrate checkers and generators to use these primitives.

EXEMPT from override guard: this module has no REPO= assignment and is not
a checker or generator. The pattern '^REPO[[:space:]]*=.*SPEC_LINT_REPO_OVERRIDE'
correctly skips this file.

EXEMPT from suppression guard: this module contains no suppression constructs
(no ALLOWLIST, SKIP_LIST, SKIP_SET, KNOWN_COLLISIONS, KNOWN_VIOLATIONS,
KNOWN_ISSUES, WHITELIST, or SUPPRESS_SET assignments).

Governing decisions: D-039, D-069, D-072, D-077, D-078, D-081, D-082
Work stream: WS-3b / BI-040
"""
import os
import re
from pathlib import Path


# ── Line splitting ──────────────────────────────────────────────────────────

def cm_splitlines(text: str) -> list[str]:
    """Split text on U+000A (LF) only, matching CommonMark §2.3 line endings.

    Python's str.splitlines() treats 8 additional codepoints as line endings
    that CommonMark does not (U+000B VT, U+000C FF, U+001C–U+001E FS/GS/RS,
    U+0085 NEL, U+2028 LS, U+2029 PS). Splitting on those codepoints allows
    embedded control characters to create phantom line-starts, enabling the
    '\\f## Heading' bypass (BI-040, confirmed against GFM).

    Derived programmatically: iterates U+0000–U+10FFFF, finds every cp where
    splitlines() != split('\\n'), and asserts this function produces the same
    result as split('\\n') for each. See test_cm_splitlines_divergence_set().

    KNOWN RESIDUAL (CRLF files): lone CR (U+000D) is a CommonMark line ending
    but this function does not split on it, leaving '\\r' at the end of lines
    in CRLF-encoded files. The spec corpus uses LF-only encoding; CRLF support
    is deferred. Tracked as a named residual — do not remove this comment.
    """
    return text.split("\n")


# ── Whitespace stripping ────────────────────────────────────────────────────

# CommonMark §2.1: space U+0020, tab U+0009, newline U+000A, VT U+000B,
# FF U+000C, CR U+000D. Python str.strip() additionally removes 23 codepoints
# not in this set (U+00A0, U+3000, etc.). Derived programmatically.
_CM_WHITESPACE = "\t\n\x0b\x0c\r "


def cm_strip_cell(s: str) -> str:
    """Strip leading/trailing CommonMark whitespace from a table cell value.

    Uses only the 6 CommonMark whitespace codepoints (§2.1). Python's str.strip()
    additionally strips 23 codepoints not recognized by CommonMark as whitespace
    (most notably U+00A0 NO-BREAK SPACE and U+3000 IDEOGRAPHIC SPACE), which can
    make a cell value match a pattern it should not (BI-040).
    """
    return s.strip(_CM_WHITESPACE)


# ── Table parsing ───────────────────────────────────────────────────────────

_SEP_CELL_RE = re.compile(r"^:?-{2,}:?$")


def split_table_cells(line: str) -> list[str]:
    """Split a CommonMark table row into cm_strip_cell-stripped cell values.

    Ragged-safe: returns whatever cells are present. The leading and trailing
    empty parts produced by splitting on '|' are discarded.

    Example: '| VP-001 | some text | unit test |' →
             ['VP-001', 'some text', 'unit test']
    """
    parts = line.split("|")
    if len(parts) < 2:
        return []
    inner = parts[1:]
    if inner and cm_strip_cell(inner[-1]) == "":
        inner = inner[:-1]
    return [cm_strip_cell(p) for p in inner]


def is_table_separator_row(cells: list[str]) -> bool:
    """Return True if all non-empty cells are CommonMark table separator cells."""
    non_empty = [c for c in cells if c]
    return bool(non_empty) and all(_SEP_CELL_RE.match(c) for c in non_empty)


# ── EC ID grammar ───────────────────────────────────────────────────────────

# Conforming EC reference: EC-NNN or EC-NNNx (1–4 digits, optional lowercase letter)
EC_TOKEN_RE = re.compile(r"\bEC-(\d{1,4})([a-z]?)\b")

# Conforming EC-column first cell: same pattern, strikethrough-tolerant (~~EC-NNN~~)
EC_CELL_RE = re.compile(r"^~{0,2}EC-\d{1,4}[a-z]?~{0,2}$")

# Non-conforming triple-segment shape (R3-B, D-069):
# <FAMILY>-<alphabetic-segment>-<numeric-segment>
# Measured precision on 133-file corpus: 12/12 TP, 0/12 FP
# (ws3-phase2-checker-repair-design.md §3.5)
WOULD_BE_ID_RE = re.compile(
    r"\b(CAP|DI|DD|VP|NFR|BC|ADR|HS|POL|EC)-([A-Za-z][A-Za-z0-9]*)-(\d+)\b"
)


def is_conforming_ec_cell(cell: str) -> bool:
    """Return True if cell is a conforming EC-column first cell (EC-NNN or EC-NNNx)."""
    return bool(EC_CELL_RE.match(cell))


def is_conforming_ec_token(token: str) -> bool:
    """Return True if token is a syntactically conforming EC ID reference."""
    return bool(EC_TOKEN_RE.fullmatch(token.strip("~")))


# ── VP-NNN column grammar ───────────────────────────────────────────────────

_VP_TOKEN_RE = re.compile(r"^VP-\d{3}$")


def is_conforming_vp_cell(first_cell: str, proof_method: str) -> bool:
    """Return True if first_cell is a conforming VP-NNN column value (R2-RULE).

    Conforming values:
      - One or more VP-NNN tokens (3 decimal digits) separated by commas or slashes
      - VP-NONE sentinel, ONLY when proof_method is non-empty (D-078)

    Everything else (em-dash, en-dash, TBD, none, empty, etc.) is non-conforming.
    """
    if not first_cell:
        return False
    if first_cell == "VP-NONE":
        return bool(proof_method.strip(_CM_WHITESPACE))
    tokens = re.split(r"[,/]", first_cell)
    return bool(tokens) and all(
        _VP_TOKEN_RE.match(t.strip(_CM_WHITESPACE))
        for t in tokens
        if t.strip(_CM_WHITESPACE)
    )


# ── Historical changelog scoping (R3-C) ────────────────────────────────────

_CHANGELOG_VERSION_RE = re.compile(r'"[^"]*v\d+\.\d+[^"]*"')


def is_historical_changelog_line(line: str, matched_text: str) -> bool:
    """Return True if matched_text appears inside a quoted YAML changelog string.

    A quoted changelog entry is a YAML list item like:
      - "v1.2: P2-M09 — replaced non-conforming EC-NEW-3 with registry-compliant EC-164"

    Predicate: match is bracketed by double-quotes on the same line AND the line
    contains a version marker (v\\d+.\\d+). Implemented as a function, never as a
    named set, per D-039 and the selftest suppression guard.
    """
    pos = line.find(matched_text)
    if pos == -1:
        return False
    before = line[:pos]
    after = line[pos + len(matched_text):]
    in_quotes = (
        ('"' in before and '"' in after)
        or _CHANGELOG_VERSION_RE.search(line) is not None
    )
    has_version = bool(re.search(r"v\d+\.\d+", line))
    return in_quotes and has_version


# ── Repo-root resolution ────────────────────────────────────────────────────

def find_repo_root(
    env_var: str = "SPEC_LINT_REPO_OVERRIDE",
    start: "Path | None" = None,
) -> Path:
    """Locate the repository root. Fail CLOSED if not found.

    Resolution order:
    1. Environment variable `env_var` (default: SPEC_LINT_REPO_OVERRIDE).
       Supports secondary worktrees and selftest isolation.
    2. Boundary-stop walk from `start` (default: caller's __file__.parent).
       Traverses ancestors looking for .factory/specs/. Stops at .git (either
       a file in linked worktrees or a directory in main checkouts). Returns
       the first ancestor containing .factory/specs/ before .git is found.
    3. If walk hits .git before .factory/specs/, or exceeds 8 levels: raises
       RuntimeError (fail CLOSED, not fall back to an ancestor).

    The `env_var` parameter exists to support hermetic selftests: a test can
    pass a dummy env var name to avoid contamination from an ambient
    SPEC_LINT_REPO_OVERRIDE. Never hardcode the env var name in call sites.

    Based on check-canonical-facts._find_repo_root() (the reference impl in
    the codebase). That implementation returns None on failure; this raises
    so the caller cannot accidentally ignore the failure.
    """
    override = os.environ.get(env_var, "")
    if override:
        return Path(override).resolve()

    candidate = (Path(start) if start else Path(__file__).resolve().parent)
    for _ in range(8):
        if (candidate / ".factory" / "specs").exists():
            return candidate
        if (candidate / ".git").exists():
            raise RuntimeError(
                f"find_repo_root: repository boundary (.git) encountered before "
                f".factory/specs/ was found. "
                f"Set {env_var} to the repo root to override."
            )
        candidate = candidate.parent
    raise RuntimeError(
        f"find_repo_root: .factory/specs/ not found within 8 ancestor levels. "
        f"Set {env_var} to the repo root to override."
    )
