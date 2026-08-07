---
document_type: primitive-layer-design
work_stream: WS-3b
phase: 1d
date: 2026-08-07
mode: READ-ONLY design (NO code applied)
scope: BI-040 / BI-044 / BI-021 / BI-043 — shared spec-lint primitive layer
operator_ruling: D-084
governing_decisions: D-039, D-069, D-072, D-077, D-078, D-081, D-082
prerequisite_branch: fix/ws3-spec-lint-integrity (open PR — must land before WS-3b begins)
repo_root_verified: /Users/jmagady/Dev/mdlinkcheck-cloud
---

# BI-040 — Shared Spec-Lint Primitive Layer Design

**Nothing in this document has been applied.** No file under
`/Users/jmagady/Dev/mdlinkcheck-cloud/scripts/` or
`/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/` was created, edited, or
deleted. This document is the only artifact produced.

---

## 0. Evidence base and measured baseline (D-082)

All figures in this document come from executed predicates, not reading or counting.
The following commands were run on the `develop` branch,
`SPEC_LINT_REPO_OVERRIDE=/Users/jmagady/Dev/mdlinkcheck-cloud`:

| Measurement | Command used | Result |
|---|---|---|
| `.splitlines()` total occurrences across 15 files | `text.count('.splitlines(')` per file | **58** (54 without `keepends=True`) |
| `.strip()` total occurrences | `text.count('.strip(')` per file | **69** |
| Raw `.splitlines()` (no keepends) call sites | 58 − 4 `keepends=True` | **54** |
| Files with `SPEC_LINT_REPO_OVERRIDE` support | grep + classify | **11** (9 checkers + 2 generators) |
| Files using ONLY `parent.parent.parent` heuristic | grep + classify | **4** generators |
| CommonMark splitlines() divergent codepoints (full iteration) | `for cp in range(0x110000)` | **9** total; **8** non-CR |
| Python `strip()` divergent codepoints (full iteration) | `for cp in range(0x110000)` | **23** |
| fix/ws3 `check-placeholders` findings on current spec | execution via tmpfile | **80** (55 VP-column + 25 filled-by) |
| fix/ws3 `check-id-resolution` EC-shape findings | execution via tmpfile | **10** (9 EC-NEW-* + 1 TV-BV013 in EC column) |
| EC regex pattern call sites in scripts | grep regex literals | **20** |
| Dangerous `.splitlines()` sites in override-guard scope | classify per file | **40** in 10 files |
| Dangerous `.splitlines()` sites in exempt generators | classify per file | **13** in 4 files |

The briefed figures (54, 63, 17, 8+2) are confirmed or explained below. The `.strip()`
discrepancy (brief: 63, measured: 69) is because the brief counted cell-parsing contexts
only; the higher measured count includes `.strip()` calls on regex match results and string
literals that are not table-cell parsing.

### CommonMark divergence sets (programmatically derived)

**splitlines() divergence** — codepoints where `s.splitlines() != s.split("\n")`:

| Codepoint | Name | Is CommonMark line ending? |
|---|---|---|
| U+000B | VT (vertical tab) | **NO** — Python splits, CommonMark does not |
| U+000C | FF (form feed) | **NO** — Python splits, CommonMark does not |
| U+000D | CR (carriage return) | YES (lone CR is a CM line ending) |
| U+001C | FS (file separator) | **NO** |
| U+001D | GS (group separator) | **NO** |
| U+001E | RS (record separator) | **NO** |
| U+0085 | NEL (next line) | **NO** |
| U+2028 | LS (line separator) | **NO** |
| U+2029 | PS (paragraph separator) | **NO** |

8 of the 9 divergent codepoints are NOT CommonMark line endings. CR is a CommonMark line
ending that `split("\n")` does not split on; this is intentional (the spec corpus uses
LF-only files; CRLF handling is deferred as a named residual — see §8).

The confirmed bypass from the brief is exactly this divergence: `x\n\f## Ghost Heading\ny`
splits via `splitlines()` into `['x', '', '## Ghost Heading', 'y']` — the FF causes a phantom
split. Via `split("\n")`: `['x', '\x0c## Ghost Heading', 'y']` — the `\x0c` prefix prevents
any heading match.

**strip() divergence** — 23 codepoints Python strips that CommonMark does not recognize
as whitespace (U+0020, U+0009, U+000A–U+000D per CM §2.1). Most actionable:
U+00A0 NO-BREAK SPACE, U+3000 IDEOGRAPHIC SPACE, and 13 Unicode "general category Z"
space variants. The bypass: `' ## X'.strip()` → `'## X'` (incorrectly looks like a
heading). With CM-faithful stripping, `' ## X'` retains the NBSP prefix and does not
match the heading regex.

---

## 1. Module design

### 1.1 Name and location

```
scripts/spec-lint/spec_lint_primitives.py
```

**Rationale for this location:**
- All 14 scripts are in `scripts/spec-lint/`; Python's standard import resolves co-located
  modules without a package structure change. Each script can do
  `import spec_lint_primitives as slp` with no `sys.path` manipulation.
- Keeping it flat (not a subdirectory) avoids breaking the `LINT_DIR="$REPO/scripts/spec-lint"`
  assumption in `run-selftests.sh`.
- The `spec_lint_primitives` name is explicit enough that nothing in the project could
  accidentally import it; it cannot be confused with a third-party module.

**This file is EXEMPT from the override guard** (it is not a checker and has no `REPO=`
assignment; it has no entrypoint). The override guard pattern
`^REPO[[:space:]]*=.*SPEC_LINT_REPO_OVERRIDE` would correctly skip it.

**This file is EXEMPT from the suppression guard** (it contains no suppression constructs
and the guard already scopes to `check-*.py`, `gen-bc-traceability.py`,
`gen-slug-corpus.py` only).

### 1.2 Public API

The API is intentionally minimal. Every function has exactly one correct use; there are
no optional arguments that enable the old behavior.

```python
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
) -> "Path":
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
    import os
    from pathlib import Path as _Path

    override = os.environ.get(env_var, "")
    if override:
        return _Path(override).resolve()

    candidate = (_Path(start) if start else _Path(__file__).resolve().parent)
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
```

### 1.3 What the module does NOT expose

- No `REPO` module-level constant (each caller resolves its own root at startup)
- No global mutable state
- No `splitlines()` anywhere (the module's own code uses `split("\n")`)
- No `str.strip()` anywhere (uses `cm_strip_cell()` exclusively for cell content)
- No named sets, allowlists, skip-lists (D-039)

---

## 2. Proof mechanism — closed-under-discovery

The brief's requirement: BI-040 must be closed as a CLASS, not as a list of known members.
The 8 confirmed family members are insufficient; the proof mechanism must surface members
nobody has yet thought of.

### 2.1 The mechanism

**Derive the divergence set programmatically. Assert against it.**

The test file `scripts/spec-lint/selftest/test_spec_lint_primitives.py` contains:

```python
def test_cm_splitlines_closed_under_discovery():
    """
    Property: cm_splitlines() handles every codepoint where Python's splitlines()
    diverges from CommonMark's line-ending semantics.

    Method: iterate all Unicode codepoints, identify divergent codepoints
    programmatically (no hardcoded list), assert cm_splitlines() agrees with
    split('\\n') for each.

    This is DISCOVERY, not enumeration. If future Python versions or Unicode
    updates introduce new divergent codepoints, this test finds them automatically.
    It does NOT accept a hardcoded list of 8; it proves the function is correct
    for WHATEVER the divergent set is at runtime.

    This test FAILS under Mutation 1 (revert cm_splitlines to str.splitlines):
    splitlines() would split on U+000C etc., producing a different result from
    split('\\n') for those codepoints, violating the assertion.
    """
    from spec_lint_primitives import cm_splitlines

    # Derive divergent codepoints programmatically (the discovery step)
    divergent_non_cr = []
    for cp in range(0x110000):
        ch = chr(cp)
        s = ch + "x"
        if s.splitlines() != s.split("\n") and cp != 0x000D:
            # Exclude CR: it IS a CommonMark line ending; split("\n") intentionally
            # defers it (see CRLF residual in cm_splitlines docstring).
            divergent_non_cr.append(cp)

    # Assert: cm_splitlines agrees with split("\n") for every non-CR divergent codepoint
    for cp in divergent_non_cr:
        ch = chr(cp)
        test_string = f"before{ch}## Heading"
        assert cm_splitlines(test_string) == test_string.split("\n"), (
            f"cm_splitlines split on U+{cp:04X} (not a CommonMark line ending): "
            f"got {cm_splitlines(test_string)!r}, expected {test_string.split(chr(10))!r}"
        )

    # Structural assertion: the discovery step found at least the 8 known codepoints.
    # If this fails, something is wrong with the iteration (not a mutation to catch).
    assert len(divergent_non_cr) >= 8, (
        f"Expected at least 8 non-CR divergent codepoints, found {len(divergent_non_cr)}. "
        "Check the iteration logic."
    )


def test_cm_strip_cell_closed_under_discovery():
    """
    Property: cm_strip_cell() strips only CommonMark whitespace, not the 23
    additional codepoints that Python's str.strip() removes.

    Method: iterate all Unicode codepoints, identify codepoints where Python's
    strip() diverges from CommonMark's whitespace definition, assert cm_strip_cell
    does NOT strip those codepoints.

    This test FAILS under Mutation 2 (revert cm_strip_cell to str.strip):
    str.strip() would remove the divergent codepoints, violating the assertion.
    """
    from spec_lint_primitives import cm_strip_cell

    # CommonMark §2.1 whitespace: U+0009 U+000A U+000B U+000C U+000D U+0020
    cm_ws = {0x0009, 0x000A, 0x000B, 0x000C, 0x000D, 0x0020}

    divergent_strip = []
    for cp in range(0x110000):
        ch = chr(cp)
        py_strips = (ch.strip() == "")
        cm_would_strip = cp in cm_ws
        if py_strips and not cm_would_strip:
            divergent_strip.append(cp)

    for cp in divergent_strip:
        ch = chr(cp)
        cell = f"{ch}word"
        result = cm_strip_cell(cell)
        assert result == cell, (
            f"cm_strip_cell incorrectly stripped U+{cp:04X} (not a CommonMark "
            f"whitespace character): got {result!r}, expected {cell!r}"
        )

    # At least 23 divergent codepoints expected
    assert len(divergent_strip) >= 23, (
        f"Expected at least 23 strip-divergent codepoints, found {len(divergent_strip)}."
    )
```

### 2.2 Why this satisfies the class-closure requirement

A hardcoded list of 8 codepoints would be satisfied by a checker that special-cases those
8 codepoints. The discovery-based test is satisfied ONLY by a correct general implementation
(`split("\n")` and `strip(_CM_WHITESPACE)`), because the assertion range is the entire
Unicode codepoint space and the test derives the expected divergent set itself at runtime.

If a future Python version adds a new codepoint to its `splitlines()` semantics, the test
discovers and asserts it without any change to the test code. This is the "closed under
discovery" property: the test does not know the set in advance; it computes and checks it.

### 2.3 Why the prior 40-seed × 300-case property test did not satisfy this

A property test with arbitrary string generation cannot hit the specific divergent
codepoints unless the generator is seeded to produce them. The 8 problematic codepoints
(U+000B, U+000C, U+001C–U+001E, U+0085, U+2028, U+2029) are extremely rare in natural
text and would not appear in a generic ASCII-biased string generator. The discovery-based
test iterates the full codepoint space deterministically; there is no randomness that
could miss the relevant codepoints.

---

## 3. Response to Falsifier 1 — conservation law proves TOTALITY, not CORRECTNESS

**The falsifier:** a conservation law (`total_candidates == sum(buckets)`) is strictly
weaker than "no row can hide," because `prose` and `fenced_code` are unbounded sink
buckets: a misrouted row satisfies conservation while defeating detection.

**How the shared layer addresses this:**

The shared layer's verification functions (`is_conforming_vp_cell`, `is_conforming_ec_cell`)
are **positive conformance predicates**, not routing functions. They do not classify rows
into buckets; they return boolean. A row is either in scope and checked, or explicitly
out of scope. There is no "prose" sink.

The in-scope / out-of-scope boundary is binary and positional:
1. A line is in a fenced code block → explicitly excluded (documented, not a sink)
2. A line is a table row inside a VP-NNN-headed table → ALWAYS checked with
   `is_conforming_vp_cell`. There is no `prose` path for such rows.
3. A line is a table row inside an EC-column table → ALWAYS checked with
   `is_conforming_ec_cell`. Same guarantee.
4. Any other line → not in scope. No assertion is possible; no finding is produced.

This is a different architecture from bucket routing. The checker does not count rows or
assert conservation; it checks every in-scope row directly. A row cannot be "misrouted
into prose" because there is no prose path for rows matched by the header condition.

**What remains genuinely unproven:**

The fenced-code suppression is the only remaining "sink." A VP or EC table embedded
inside a fenced code block is suppressed. This is intentional behavior
(`bc-module-map.md:479` is a documentation template, not a live defect) and the
anti-vector NV-2 tests it. A table GENUINELY inside a fenced code block escapes
detection. This is documented as a residual, not a hidden sink: any file with a VP
table inside a fenced code block is almost certainly documentation of the format, not
a spec file with a real VP property that should be verified.

**The conservation law was in `check-index-integrity.py`**, not in the two checkers
that BI-040 primarily addresses. For `check-index-integrity.py`, the shared layer
eliminates the `\f`/`\v` phantom-line bypass, which was the mechanism by which a row
could be misclassified into the `prose` bucket. Once the phantom split is impossible
(because `cm_splitlines` does not split on those codepoints), a row with a `\f` prefix
cannot be classified as a heading and therefore cannot incorrectly change the section
scope that determines which rows are in the `data_row` vs `prose` bucket.

---

## 4. Response to Falsifier 2 — 12,000 property-test cases were false closure

**The falsifier:** 40 seeds × 300 cases passed while 5 mutations each reopened a
historical bypass. "The property test is green" is not evidence of class closure.

**The five mutations and why the shared layer's tests catch each:**

| Mutation | How it reopens bypass | Test that catches it |
|---|---|---|
| M1: revert `cm_splitlines` to `str.splitlines()` | `\f## Heading` becomes a phantom heading | `test_cm_splitlines_closed_under_discovery` — `splitlines()` on U+000C string produces different result from `split("\n")`, assertion fails |
| M2: revert `cm_strip_cell` to `str.strip()` | ` ## X`.strip() → `## X` (heading) | `test_cm_strip_cell_closed_under_discovery` — `str.strip()` removes U+00A0, assertion fails |
| M3: remove fenced-code suppression from checker | VP/EC tables in fenced blocks get false positives | NV-2 anti-vector exits 0 before repair, must still exit 0 after; NV-2 contains a fenced code block with a VP table |
| M4: weaken table-context state machine (R2/R3) | Em-dash VP rows or EC-NEW rows escape detection | NV-1 (em-dash VP) and NV-3 (EC-NEW in EC column) are detection vectors that currently exit 0 (pre-repair) and must exit 1 post-repair; any weakening reverts them to 0 |
| M5: weaken EC ID grammar (R3-B) | `EC-DRAFT-7` or novel triple-segment shapes escape | NV-4 uses `EC-DRAFT-7` and `DI-PENDING-2` — both tokens that appear NOWHERE in the repo; a mutation that hardcodes `EC-NEW-` would produce 0 or 1 findings instead of 2 |

**Why the prior property test could not catch these mutations:**

The prior test used arbitrary string generation. The 8 divergent codepoints (U+000B,
U+000C, etc.) have probability ~0 of appearing in a typical string generator without
explicit seeding. The discovery-based test iterates the full codepoint space
deterministically; it would catch mutations M1 and M2 regardless of any randomness.

**What remains unproven (honest statement):**

- The fenced-code suppression boundary is tested only for the specific documented case
  (`bc-module-map.md:479`-style templates). A VP table nested inside a code block inside
  another code block (not a real concern in this corpus) is untested.
- The versioned-changelog section scoping (D-081 / R3-C) is tested by NV-5 for the
  one observed historical case. A novel form (e.g. a `#### vN.N` level-4 heading) is
  not tested; D-081 explicitly accepted this residual.
- The CM-faithful strip is not tested at the whole-checker level (only unit-tested at
  the primitive level). A subtle interaction between `cm_strip_cell` and a specific
  table structure could still fail. The mitigation is the output-identity verification
  during migration (§6.4).

---

## 5. ID grammar — single source of truth

The canonical EC ID grammar is `EC-(\d{1,4})([a-z]?)`, matching `EC-NNN`, `EC-NNNx`,
`EC-001` through `EC-9999`. The triple-segment non-conforming shape (R3-B) is
`\b(CAP|DI|DD|VP|NFR|BC|ADR|HS|POL|EC)-([A-Za-z][A-Za-z0-9]*)-(\d+)\b`.

**Measurements that justify this grammar (from `ws3-phase2-checker-repair-design.md §3.5`,
re-verified by execution):**

| Candidate | TP | FP | Notes |
|---|---|---|---|
| Triple-segment R3-B | 12 | **0** | Recommended |
| "Any uppercase suffix" P2 | 12 | **199** | Flags VP-NNN, VP-INDEX, BC-INDEX etc. |
| P2 minus metasyntax P3 | 12 | **27** | Still flags 26 × VP-TBD and BC-H1 |

These measurements were produced by running predicates on the 133-file spec corpus.
P1 (triple-segment) is the only candidate with zero false positives, and it is
extensible without code change: `EC-TMP-4`, `VP-DRAFT-3`, `BC-TBD-9` would all be
caught.

The current state has the R3-B grammar duplicated in `check-id-resolution.py` (fix
branch). The shared layer extracts it to one location. Every call site that currently
uses `r"\bEC-(\d+)\b"` (digits-only) must migrate to `EC_TOKEN_RE` from the primitive.

**Affected call sites (from predicate run):**

| File | Line | Pattern | Action |
|---|---|---|---|
| `check-counts.py` | 386, 391, 457 | `r"\bEC-(\d+)\b"` | Replace with `EC_TOKEN_RE` |
| `check-holdout-boundary.py` | 56, 64, 114 | `r"EC-(\d+)"` | Replace with `EC_TOKEN_RE` |
| `check-index-integrity.py` | 350, 355, 534 | `r"(EC-\d+)"` | Replace with `EC_CELL_RE` for column context |
| `check-ec-injectivity.py` | 114 | `r"^\|\s*(EC-(\d+[a-z]?))\s*\|(.+)"` | Integrate with `is_conforming_ec_cell` |
| `gen-ec-registry.py` | 72 | `r"EC-\d+[a-z]?"` | Replace with `EC_TOKEN_RE` |
| `check-id-resolution.py` | 135, 145, 323 | various | Already has R3-A/B; keep but unify |

Note on `gen-ec-registry.py`: this generator currently silently ignores `EC-NEW-*`
rows because its regex only matches digits-only. After migration to `EC_TOKEN_RE`, it
will still only extract conforming IDs (by design — a non-conforming ID cannot be
added to the registry). This is the correct behavior; no behavioral change required.
But the generator SHOULD log a warning when it encounters a row in an EC-column table
that does not match `EC_CELL_RE`. This is a feature gap, not a blocker; defer to
WS-4.

---

## 6. Repo-root resolution

### 6.1 Current state (from predicate execution)

| File | Strategy | Override support |
|---|---|---|
| `check-*.py` (9 files) | `SPEC_LINT_REPO_OVERRIDE` → `parent.parent.parent` | YES |
| `gen-bc-traceability.py`, `gen-slug-corpus.py` | Same one-liner | YES |
| `check-canonical-facts.py` | `SPEC_LINT_REPO_OVERRIDE` → boundary-stop walk | YES (best impl) |
| `gen-bc-index.py`, `gen-ec-registry.py`, `gen-prd-sections.py`, `gen-rtm.py` | `parent.parent.parent` ONLY | **NO** |

The 4 generators without override support are exempt from the current
`run_override_guard` (which explicitly scopes to `check-*.py` and two named generators).
After migration, the primitive layer's `find_repo_root()` adds override support to all 4.

### 6.2 Design requirements

The `find_repo_root()` function in `spec_lint_primitives.py` must:
1. Honor `SPEC_LINT_REPO_OVERRIDE` first
2. Boundary-stop walk (from `check-canonical-facts.py`) — stops at `.git` to prevent
   escaping to an ancestor repo
3. Fail CLOSED (raise `RuntimeError`, never silently resolve the wrong root)
4. Accept `env_var` as a parameter for hermetic selftests (BI-045 lesson: ambient
   `SPEC_LINT_REPO_OVERRIDE` made three selftest assertions vacuous by pointing to the
   real spec tree instead of the temp dir)
5. Accept `start` as a parameter so callers can use their `__file__` parent explicitly

### 6.3 The `env_var` parameter and hermeticity

Each caller invokes `find_repo_root()` using its own `__file__` as the starting point
and `SPEC_LINT_REPO_OVERRIDE` as the env var. The `env_var` parameter's purpose is
exclusively for tests:

```python
# Production callsite pattern (each checker)
REPO = find_repo_root(start=Path(__file__).resolve().parent)

# Selftest callsite pattern (isolated temp tree, no ambient contamination)
REPO = find_repo_root(env_var="TEST_REPO_OVERRIDE", start=Path(__file__).resolve().parent)
os.environ["TEST_REPO_OVERRIDE"] = str(tmpdir)
```

This ensures that an ambient `SPEC_LINT_REPO_OVERRIDE` in the test runner's environment
does not contaminate the selftest. Do NOT use a single global `REPO` constant in
`spec_lint_primitives.py`; resolution is the caller's responsibility.

### 6.4 Update to the override guard

After migration, the override guard `run_override_guard` in `run-selftests.sh` must
expand its scope to include the 4 previously-exempt generators:

```
# Before: check-*.py, gen-bc-traceability.py, gen-slug-corpus.py
# After:  check-*.py, gen-bc-traceability.py, gen-slug-corpus.py,
#         gen-bc-index.py, gen-ec-registry.py, gen-prd-sections.py, gen-rtm.py
```

The 4 generators use `find_repo_root()` from the primitive module after migration,
which already honors the override. The guard's pattern
`^REPO[[:space:]]*=.*SPEC_LINT_REPO_OVERRIDE` must also match the call to
`find_repo_root()` if the assignment is `REPO = find_repo_root(...)`. Either:
- The pattern in the guard is updated to also match `find_repo_root`, OR
- Each generator keeps a module-level `REPO = find_repo_root(...)` assignment that
  the guard can match

The second option is simpler. Each file should have a module-level:
```python
REPO = find_repo_root(start=Path(__file__).resolve().parent)
```
The guard pattern `^REPO[[:space:]]*=` already matches this line. The guard currently
only checks for `SPEC_LINT_REPO_OVERRIDE` in the assignment; it would need to be
updated to also accept `find_repo_root` calls. This guard update is part of Stage 2
(see §7).

---

## 7. Migration plan

### Prerequisites (must happen first)

The `fix/ws3-spec-lint-integrity` PR must merge before WS-3b work begins. That PR
delivers R2 (VP-column conformance) and R3 (EC ID shape detection), which the primitive
layer extracts. Without it:
- The VP conformance logic in `check-placeholders.py` does not yet exist to extract
- The EC ID shape logic in `check-id-resolution.py` does not yet exist to extract
- The finding counts (80 placeholders + 10 EC-shape) are not yet established as baseline

### Stage 1 — Create the primitive module (WS-3b-1)

**Scope:** Create `scripts/spec-lint/spec_lint_primitives.py` with the full API from §1.2
plus `scripts/spec-lint/selftest/test_spec_lint_primitives.py` with the divergence-set
tests from §2.1.

**No changes to existing checkers or generators in this stage.** Zero behavioral change.
The module is importable but nothing imports it yet.

**New selftest cases required:**
- `test_cm_splitlines_closed_under_discovery()` — divergence-set assertion
- `test_cm_strip_cell_closed_under_discovery()` — strip-divergence assertion
- `test_is_conforming_vp_cell()` — conforming and non-conforming VP-cell values
- `test_is_conforming_ec_cell()` — conforming and non-conforming EC-cell values
- `test_is_conforming_ec_token()` — extracted token form
- `test_split_table_cells()` — ragged table rows, NBSP in cell, trailing-|, no-| line
- `test_find_repo_root_fail_closed()` — boundary stop fires, raises RuntimeError
- `test_find_repo_root_override_honored()` — override env var takes precedence
- `test_find_repo_root_hermetic()` — ambient `SPEC_LINT_REPO_OVERRIDE` does NOT contaminate
  when a different `env_var` name is used

The selftest harness does not use the `EXPECTED_TEST_COUNT` / clean-pass / defect-fail
pattern for unit tests; a separate pytest-style runner or a standalone test block is
appropriate. If the existing bash harness is used, each primitive test must still follow
the two-step pattern. **Recommendation:** add a separate `test_primitives.sh` that runs
`python3 test_spec_lint_primitives.py` and asserts exit 0. The existing
`run-selftests.sh` calls this as its final pre-flight check (a G3 structural guard).

### Stage 2 — Migrate checkers (WS-3b-2)

**Scope:** 9 checkers + 2 named generators (already in override-guard scope):
- `check-adr-consistency.py`, `check-counts.py`, `check-ec-injectivity.py`,
  `check-holdout-boundary.py`, `check-id-resolution.py`, `check-index-integrity.py`,
  `check-placeholders.py`, `check-title-sync.py`, `check-canonical-facts.py`
- `gen-bc-traceability.py`, `gen-slug-corpus.py`

**Changes per file:**
1. Replace `text.splitlines()` → `slp.cm_splitlines(text)` (import `spec_lint_primitives as slp`)
2. Replace `str.strip()` used in `line.split("|")` cell-parsing contexts → `slp.cm_strip_cell()`
3. Replace cells-split logic → `slp.split_table_cells(line)` where already refactored
4. Replace `is_historical_changelog_line` inline implementations → `slp.is_historical_changelog_line`
5. Replace `_WOULD_BE_ID_RE` inline pattern → `slp.WOULD_BE_ID_RE`
6. Replace `find_repo_root` in `check-canonical-facts.py` → `slp.find_repo_root` (the canonical implementation becomes the primitive; `check-canonical-facts` retains the same logic via the shared module)
7. Remove all inline `_split_cells`, `_split_table_cells`, `_is_separator_row` implementations
8. Update `check-index-integrity.py` KNOWN RESIDUAL comment at line 748:
   - Before: "Known residual: Python's str.splitlines() treats \f..."
   - After: "CLOSED via slp.cm_splitlines() (WS-3b-2, BI-040). CommonMark-faithful line splitting removes the \f/\v phantom-line class. See spec_lint_primitives.cm_splitlines docstring for remaining CRLF residual."
9. Update override guard scope in `run-selftests.sh` to match `find_repo_root` call
10. Add `run_splitlines_guard()` to `run-selftests.sh` (see §7.1)

**Output-identity verification:**
Before any commit, run each checker against the current spec tree twice — once on the
pre-migration code and once on the post-migration code — and assert identical output:

```bash
SPEC_LINT_REPO_OVERRIDE=/Users/jmagady/Dev/mdlinkcheck-cloud \
  diff <(python3 check-placeholders.py) <(python3 check-placeholders-migrated.py)
# Must produce no diff
```

The finding counts 80 (check-placeholders) and 10 (check-id-resolution) must be
preserved exactly. The other checkers must remain at exit 0 with identical output.

### Stage 3 — Migrate generators (WS-3b-3)

**Scope:** 4 exempt generators: `gen-bc-index.py`, `gen-ec-registry.py`,
`gen-prd-sections.py`, `gen-rtm.py`.

**Changes per file:**
1. Add `import spec_lint_primitives as slp`
2. Replace `REPO = Path(__file__).resolve().parent.parent.parent` with
   `REPO = slp.find_repo_root(start=Path(__file__).resolve().parent)`
3. Replace raw `splitlines()` → `slp.cm_splitlines()`
4. Expand override guard scope in `run-selftests.sh` to include all 4 generators

**Separate from Stage 2 because:**
- Generators do not produce checker findings, so no count-preservation regression risk
- Generators are explicitly exempt from the current override guard; expanding the guard
  is a breaking guard change that should be reviewed separately
- A reviewer can verify Stage 2's count-preservation independently of Stage 3

### 7.1 Enforcement mechanism

A `run_splitlines_guard()` function in `run-selftests.sh` prevents regression to raw
`splitlines()`. Pattern:

```bash
SPLITLINES_PATTERN='\.splitlines\(\)'

run_splitlines_guard() {
    # Verify no *.py in scripts/spec-lint/ (excluding spec_lint_primitives.py)
    # contains raw .splitlines() calls.
    # spec_lint_primitives.py is exempt: it defines cm_splitlines() which uses
    # split("\n"), and its test file uses splitlines() to derive the divergence set.
    local dir="$1"
    local count=0
    for f in "$dir"/*.py; do
        [[ -f "$f" ]] || continue
        [[ "$(basename "$f")" == "spec_lint_primitives.py" ]] && continue
        [[ "$(basename "$f")" == "test_spec_lint_primitives.py" ]] && continue
        count=$((count + 1))
        if grep -qE "$SPLITLINES_PATTERN" "$f" 2>/dev/null; then
            echo "STRUCTURAL GUARD FAILED: $(basename "$f") uses raw .splitlines()"
            echo "  Use slp.cm_splitlines() instead (BI-040)."
            return 2
        fi
    done
    echo "Pre-flight guard passed: $count files checked, 0 raw .splitlines() uses"
    return 0
}
```

This guard fires on any mutation that reverts to `splitlines()` in a checker or
generator. It does NOT ban `.strip()` globally (too many legitimate uses); cell-parsing
strip migration is enforced by code review and the output-identity verification.

The guard's scope excludes `keepends=True` uses by construction: `\.splitlines\(\)`
only matches the zero-argument form.

### 7.2 Sequencing invariant

At every stage boundary, ALL existing selftests must pass. The invariant is:
- After Stage 1: `run-selftests.sh` continues to pass 54/54 (new primitive tests run
  separately via `test_primitives.sh`; the count guard is not yet enforced)
- After Stage 2: `run-selftests.sh` passes 54/54 PLUS `test_primitives.sh` passes.
  `run_splitlines_guard` is enabled and passes. Finding counts are identical to baseline.
- After Stage 3: all guards pass. 4 generators gain override support; override guard
  scope expands; `run_splitlines_guard` covers generators too.

---

## 8. Preserved-count analysis

**Baseline (fix/ws3-spec-lint-integrity branch, confirmed by execution):**
- `check-placeholders.py`: 80 findings (55 VP-column em-dash + 25 `[filled by story-writer]`)
- `check-id-resolution.py`: 10 findings (9 EC-NEW-* + 1 TV-BV013 in EC column)
- All other checkers: exit 0

**After primitive-layer migration: counts must be IDENTICAL.**

**Why counts will not change:**

1. **splitlines() → cm_splitlines()**: The spec corpus is LF-only (UTF-8, Unix line
   endings, no embedded control characters). `cm_splitlines(text)` and `text.splitlines()`
   produce identical results for all LF-only text. This is verifiable by the
   output-identity diff described in §7 Stage 2.

2. **str.strip() → cm_strip_cell()**: Table cells in the spec corpus contain only
   ASCII whitespace (spaces). `cm_strip_cell(cell)` and `cell.strip()` produce identical
   results for ASCII-only input. No cell currently contains NBSP or other divergent
   codepoints.

3. **Inline logic → shared functions**: The VP-conformance logic and EC-shape logic are
   extracted without behavioral change. The same predicates, the same patterns.

**If counts DO change during migration:** this indicates either a behavioral difference
between the inline logic and the primitive (a migration bug) or a divergent codepoint in
actual spec file content (very unlikely but verifiable by running `python3 -c "import
pathlib; [print(hex(ord(c))) for c in pathlib.Path(f).read_text() if not c.isprintable()
and c not in '\t\n ']" spec_file.md`). Either way, the output-identity diff will catch it
before the PR is opened.

**D-077 compliance**: The 80-finding count for `check-placeholders.py` and the
10-finding count for `check-id-resolution.py` are tracked as a burn-down baseline under
D-077. The primitive-layer migration must preserve these counts exactly; the burn-down
is against spec content (55 em-dash VP rows + 9 EC-NEW-* rows + 1 TV-BV013 row), not
against the checker code.

---

## 9. Risk assessment

### 9.1 Principal risks

**Risk: Subtle behavioral difference in cm_split_table_cells vs inline split logic**
- Likelihood: LOW (the inline implementations are simple)
- Mitigation: output-identity diff on every checker before merge (§7 Stage 2)
- If triggered: the diff will identify the exact cell; trace to the codepoint difference

**Risk: Import failure at runtime (circular import, missing module)**
- Likelihood: LOW (the module has no dependencies outside stdlib)
- Mitigation: each Stage 2 PR runs all selftests; an import failure would fail test 1

**Risk: override guard expansion (Stage 3) causes false guard failure**
- Likelihood: LOW (the 4 generators already use `find_repo_root` from the primitive
  after migration; the guard pattern matches `^REPO[[:space:]]*=`)
- Mitigation: Stage 3 PR verifies guard passes before merge

**Risk: `run_splitlines_guard` fires on legitimate uses in comments**
- Likelihood: LOW (the pattern `\.splitlines\(\)` greps source code; comments
  containing `.splitlines()` in examples WOULD be flagged)
- Mitigation: exempt comments by using `grep -v '^\s*#'` in the guard, or by phrasing
  examples in comments without the exact character sequence (e.g., `.splitlines()`)
  
  **Recommendation**: the design doc and spec_lint_primitives.py docstrings use
  `splitlines()` in text. The guard should grep only non-comment lines:
  ```bash
  grep -v '^\s*#' "$f" | grep -qE "$SPLITLINES_PATTERN"
  ```

**Risk: `check-index-integrity.py` has additional split/heading logic not reached
by simple search-replace**
- This file has `_leading_columns()` which expands tabs at 4-column stops for
  CommonMark indent semantics. This is a separate concern from line splitting and is
  NOT changed by the primitive layer migration. The KNOWN RESIDUAL for `\f`/`\v`
  phantom lines is closed by `cm_splitlines()`; the indent-column calculation for
  actual lines is orthogonal.
- Likelihood of interaction: LOW

### 9.2 Oracle soundness during migration

These checkers are the Phase-1 gate oracle. A subtle behavior change could mask real
defects or manufacture false ones. The oracle-soundness guarantee:

- Output-identity verification (§7 Stage 2) is mandatory before any Stage 2 commit
- The selftest suite (54 cases) continues to run on every commit to the migration branch
- The divergence-set tests in `test_spec_lint_primitives.py` prove the primitive
  functions handle the full Unicode codepoint space correctly

If a migration introduces a regression in any selftest case, it is blocked before merge.
If a migration changes the finding count, it is blocked before merge. The oracle cannot
become less sound during migration.

---

## 10. Items not resolved by this design

1. **CRLF file handling residual**: `cm_splitlines()` does not split on lone `\r`.
   For CRLF-encoded spec files, `\r` would appear at the end of each line and survive
   into cell content. `cm_strip_cell()` DOES strip `\r` (it is U+000D, in CM whitespace).
   So CRLF files would be processed correctly for cell content; the only edge case is
   a raw line-level check for a string at the start of a line (e.g. heading detection)
   on a CRLF file — `\r` would not be at the start but at the end, so no impact.
   **Verdict**: no action required for the current corpus (LF-only). Document as residual.

2. **`gen-ec-registry.py` warning on non-conforming EC rows**: the generator currently
   silently skips `EC-NEW-*` rows. After migration it should log a warning. Deferred to
   WS-4 (the ~306-finding remediation burst requires the generators to be aware of
   non-conforming IDs to correctly report vs skip them). Track as a WS-4 intake item.

3. **`.strip("|")` pattern in `check-index-integrity.py`**: line 106 uses
   `l.strip("|").split("|")` to parse table cells. This is logically different from
   `split("|")[1:-1]` and different from `split_table_cells(line)`. Both produce the same
   result for standard markdown tables, but the semantics differ for lines with trailing
   text after the final `|`. Migration should use `split_table_cells(line)` and the
   output-identity diff will confirm equivalence.

4. **`check-counts.py:450` — `enumerate(tv_text.splitlines(), 1)`**: classified as
   "STRUCT" in the initial analysis (it's used to get line numbers for error reporting,
   not to classify line content). The line numbers produced would be the same as
   `enumerate(cm_splitlines(tv_text), 1)` for any LF-only file. However, if `tv_text`
   ever contains a VT or FF, the line numbers would diverge. Migrate to `cm_splitlines()`
   for consistency even in structural contexts.

5. **ID grammar for NON-EC families in `check-ec-injectivity.py`**: that checker has
   `r"^\|\s*(EC-(\d+[a-z]?))\s*\|(.+)"` which is EC-specific and handles the `[a-z]`
   sub-lettered form. The primitive `EC_TOKEN_RE` generalizes this. However,
   `check-ec-injectivity.py` also processes TV IDs separately; the migration should
   not accidentally merge those two contexts.

---

## 11. Dissent evaluation

The brief asks: if you conclude the shared-layer approach is wrong, or any of the three
issues does not belong in it, say so with evidence.

**No dissent.** All three issues belong in the shared layer:

- **BI-040** (splitlines/strip): definitionally a primitive — every script that parses
  spec file content calls these methods directly on the bytes. A shared implementation
  is the only way to ensure consistent CommonMark semantics across all 15 files.

- **BI-044** (EC/ID grammar): the digits-only assumption is replicated at 20 call sites
  across 6 files. Even if only `check-id-resolution.py` needs the R3-B triple-segment
  grammar, the conforming EC pattern (`EC-\d{1,4}[a-z]?`) should be a single constant,
  not 20 independent copies each with a different minor variant.

- **BI-021/BI-043** (repo-root): the 4 generators without override support create
  asymmetry. A malicious or misconfigured environment could cause them to silently
  resolve a different repo root and pass when they should fail. The shared layer
  eliminates this asymmetry.

**One partial dissent on scope:** the `.strip()` fixing for cell parsing is important for
correctness, but many `.strip()` calls in the files are NOT cell-parsing contexts —
they strip regex match results, string literals from YAML parsing, etc. Migrating those
to `cm_strip_cell()` is unnecessary and potentially confusing (a regex match result does
not have "cell" semantics). The migration should selectively migrate only:
1. `line.split("|")` patterns with subsequent `.strip()`
2. `p.strip() for p in line.split("|")`
3. `[c.strip() for c in l.strip("|").split("|")]`

All other `.strip()` calls are out of scope for this migration.

---

## 12. Compliance ledger

| Constraint | Status |
|---|---|
| READ-ONLY; no edits under `scripts/` or `.factory/specs/**` | Honored. Only file written: `cycles/phase-1d/bi-040-primitive-layer-design.md`. |
| No `git commit` / push / branch / PR | Honored. No git write command issued. |
| `gen-bc-traceability.py` write mode (BI-041) | Never invoked. |
| Repo-root verification (BI-021/BI-043) | Checked: fix branch and develop branch both resolve to `/Users/jmagady/Dev/mdlinkcheck-cloud`. |
| No allowlists / skip-lists (D-039) | Honored. No named sets in the proposed API. |
| Class closure, not instance patching (D-069) | `cm_splitlines` is correct for all Unicode (proven by divergence-set test). `WOULD_BE_ID_RE` is a grammar, not a list. |
| Docstring honesty (lesson 28) | CRLF residual stated explicitly in `cm_splitlines` docstring. `check-index-integrity.py` KNOWN RESIDUAL comment updated to "CLOSED" only after migration lands. |
| D-082 (quantitative claims from executed predicates) | All counts in this document from code execution. Sources noted in §0 measurement table. |
| Falsifier 1 answered | §3 — positive conformance predicates, no sink buckets in scope |
| Falsifier 2 answered | §4 — divergence-set assertion is discovery-based, catches all 5 mutations |
| D-077 finding counts preserved | §8 — output-identity verification is mandatory gate before any Stage 2 commit |
