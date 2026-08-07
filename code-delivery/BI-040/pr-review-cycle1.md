## PR Review — BI-040 Cycle 1 (fresh-eyes, diff-only)

Reviewed all 19 changed files in `e1299b0..ae03356`. I did not re-run the operator's
output-identity / 55-55 / mutation evidence and I am not restating it as my own work.
What follows is what I found independently, plus the results of five probes I executed
against the diff (marked **[executed]**).

Import-smoke-tested all 15 scripts under `SPEC_LINT_REPO_OVERRIDE`: all 15 load cleanly,
and no file that dropped `import os` still references `os.` — **no import-ordering or
missing-import defects.** Grep confirms **zero** remaining raw `.splitlines()` and **zero**
remaining `parent.parent.parent` outside `test_spec_lint_primitives.py:29` (a `sys.path`
insert, correctly not a repo-root resolution) — **no missed migration sites** for the two
classes BI-040/BI-043 target.

Two blocking findings. Both are in new code, both are confirmed by execution, and both are
one- or two-line fixes.

---

## BLOCKING

### B1 — `slp.is_conforming_vp_cell` reintroduces the exact fail-open that the function it replaces documents and guards against
`scripts/spec-lint/spec_lint_primitives.py:143-148`

```python
tokens = re.split(r"[,/]", first_cell)
return bool(tokens) and all(
    _VP_TOKEN_RE.match(t.strip(_CM_WHITESPACE))
    for t in tokens
    if t.strip(_CM_WHITESPACE)
)
```

`bool(tokens)` is evaluated on the **unfiltered** list while the generator filters empties
out. For a punctuation-only cell the list is non-empty but the generator is empty, and
`all()` over an empty iterator is `True`.

The live implementation this was extracted from — `check-placeholders._is_valid_vp_cell`,
still in the tree at `check-placeholders.py:86-89` — filters *before* `all()` and carries a
comment naming this trap verbatim:

> `# Filter empty tokens BEFORE the all() call: re.split(",", ",") yields ['', ''], and
> all() over an empty iterator returns True — silently passing punctuation-only cells.`

**[executed]** divergence between the new primitive and the live checker:

```
slp.is_conforming_vp_cell(",",   "proof") -> True     <-- fail-open
slp.is_conforming_vp_cell("/",   "proof") -> True     <-- fail-open
slp.is_conforming_vp_cell(",,,", "proof") -> True     <-- fail-open
check-placeholders._is_valid_vp_cell(",", "proof") -> False
```

Failure scenario: a BC row `| , | unit test |` in a `VP-NNN`-headed table is a
non-conforming VP column value. `check-placeholders` reports it today. The moment
`check-placeholders` is migrated onto the primitive (which is the stated point of BI-044),
the finding disappears silently and POL-14 stops covering that cell shape.

Blast radius today is zero — `is_conforming_vp_cell` has **0 production call sites** (see
W1) — which is exactly why this must be fixed now rather than discovered after WS-4
migrates the call site. The fix is the line already written and justified elsewhere in this
repo:

```python
tokens = [t.strip(_CM_WHITESPACE) for t in re.split(r"[,/]", first_cell) if t.strip(_CM_WHITESPACE)]
return bool(tokens) and all(_VP_TOKEN_RE.match(t) for t in tokens)
```

Please also add the `","` case to `test_is_conforming_vp_cell` — it is absent from all 18
assertions in that test, which is why the regression got through.

### B2 — `test_cm_splitlines_closed_under_discovery` is tautological against its own oracle: a no-op splitter passes 9/9
`scripts/spec-lint/selftest/test_spec_lint_primitives.py:93-101`

```python
test_string = f"before{ch}## Heading"
result = slp.cm_splitlines(test_string)
expected = test_string.split("\n")
assert result == expected
```

Two compounding problems:

1. The oracle **is** the implementation. `cm_splitlines` is literally `text.split("\n")`,
   so this asserts `x.split("\n") == x.split("\n")`.
2. No test string in the entire 9-test suite contains an LF. Every `test_string` here is
   `"before<cp>## Heading"`, so `expected` is always the single-element list
   `[test_string]`.

Consequence: the suite never once verifies that `cm_splitlines` actually splits.

**[executed]** mutation — replace the body of `cm_splitlines` with `return [text]` (a
splitter that never splits, which would break line numbering in all 15 checkers):

```
PASS: test_cm_splitlines_closed_under_discovery
PASS: test_cm_strip_cell_closed_under_discovery
PASS: test_is_conforming_vp_cell
PASS: test_is_conforming_ec_cell
PASS: test_is_conforming_ec_token
PASS: test_split_table_cells
PASS: test_find_repo_root_fail_closed
PASS: test_find_repo_root_override_honored
PASS: test_find_repo_root_hermetic

9/9 primitive tests passed
exit=0
```

G3 — the gate this PR installs for the primitive layer — passes green on a completely
broken `cm_splitlines`. The documented mutation (revert to `str.splitlines()`) does fail, so
the test is not *fully* vacuous; but the AC-1 evidence in
`docs/demo-evidence/BI-040/evidence-report.md` reads as proof of `cm_splitlines`
correctness, and it is not.

Fix — assert against literals rather than restating the implementation, and add the
positive case:

```python
assert slp.cm_splitlines("a\nb\nc") == ["a", "b", "c"]
assert slp.cm_splitlines("") == [""]
assert slp.cm_splitlines("a\n") == ["a", ""]
# then, per divergent codepoint:
assert slp.cm_splitlines(f"before{ch}## Heading") == [f"before{ch}## Heading"]
```

The last form has real teeth against both mutants (the length-1 literal fails nothing under
`[text]`, but combined with the LF cases the mutant dies on the first assertion).

---

## WARNINGS

### W1 — BI-044's "single source of truth" is not delivered; one docstring asserts an interpolation that does not exist
The PR title and body claim BI-044 closes the *EC/VP ID grammar single source of truth*.
Measured across the diff:

| Primitive | production call sites |
|---|---|
| `cm_splitlines` | 53 |
| `find_repo_root` | 16 |
| `split_table_cells` | 5 |
| `is_table_separator_row` | 2 |
| `is_historical_changelog_line` | 2 |
| `is_conforming_ec_cell` | 1 |
| `EC_TOKEN_RE` | 9 |
| **`is_conforming_vp_cell`** | **0** |
| **`is_conforming_ec_token`** | **0** |
| **`EC_CELL_RE`** | **0** (used transitively) |
| **`cm_strip_cell`** | **0** (used transitively) |

The EC grammar literal `EC-\d{1,4}[a-z]?` is still hand-written in five live regexes:
`check-index-integrity.py:353,358,537`, `gen-ec-registry.py:73`, `check-counts.py:378`,
`check-ec-injectivity.py:145`. The VP grammar is duplicated wholesale:
`check-placeholders.py:61` keeps its own `_VP_TOKEN_RE = re.compile(r"^VP-\d{3}$")` and its
own `_is_valid_vp_cell`.

Most concretely, `check-ec-injectivity.py:138` states:

> `BI-044: EC ID column now uses the shared grammar (EC-\d{1,4}[a-z]?) via EC_TOKEN_RE.pattern.`

Line 145 does not use `EC_TOKEN_RE.pattern` — it hardcodes the literal. A reader auditing
BI-044 will believe the grammar is single-sourced there when it is not, and W2 below is the
first bug this duplication has already produced.

Suggestion: export `EC_INNER = r"\d{1,4}[a-z]?"` (or interpolate `EC_TOKEN_RE.pattern`) and
build the five row regexes from it, so a grammar change cannot silently diverge across
six files. Either migrate `check-placeholders` onto `slp.is_conforming_vp_cell` (after B1)
or drop the dead primitive — shipping both, with divergent semantics, is the worst of the
three options.

### W2 — `check-index-integrity.py:537` silently truncates a 5+ digit EC filename into a different, valid-looking ID
```python
m = re.match(r"^(EC-\d{1,4}[a-z]?)", f.name)
```
`re.match` is not end-anchored and `\d{1,4}` is bounded, so the pattern matches a *prefix*.
**[executed]**: `EC-15600-foo.md` → captured group is `EC-1560`. The old `EC-\d+` captured
`EC-15600`.

Failure scenario: a malformed holdout file `EC-15600-x.md` lands in
`.factory/specs/holdout-scenarios/wave-N/`. `get_actual_wave_scenario_ec_ids()` now returns
`EC-1560`. If `EC-1560` is a real indexed scenario, the unlisted-file / phantom-entry
reconciliation both pass, and the malformed file is never reported. The old regex would have
produced `EC-15600` and surfaced it as an unlisted file.

The primitive's `EC_TOKEN_RE` has the trailing `\b` that prevents exactly this. This is W1
biting: the inline copy dropped the guard the shared constant has. Fix: use
`slp.EC_TOKEN_RE.match(f.name)`, or anchor with `(?!\d)`.

### W3 — `find_repo_root` does not resolve an explicit `start`, so a relative `start` returns a cwd-relative root
`spec_lint_primitives.py:209`

```python
candidate = (Path(start) if start else Path(__file__).resolve().parent)
```

The default branch resolves; the explicit-`start` branch does not.

**[executed]**, from the repo root: `find_repo_root(env_var="NOPE", start=Path("scripts/spec-lint"))`
returns `Path(".")`. The walk reaches `Path(".")`, whose `.parent` is also `Path(".")`, and
`./.factory/specs` exists relative to **cwd** — so it returns a cwd-dependent root and never
raises. That is precisely the hermeticity property BI-043 is supposed to establish.

All 14 call sites pass `start=Path(__file__).resolve().parent` today, so this is latent. But
it is invisibly latent: G1 only greps for the string `SPEC_LINT_REPO_OVERRIDE` on the `REPO=`
line (see W4), so an edit to `start=Path(__file__).parent` passes every guard in the suite.

Fix: `candidate = (Path(start).resolve() if start else Path(__file__).resolve().parent)`.

Heads-up on the coupling: `test_find_repo_root_hermetic:412` asserts
`str(result) == tmpdir`, which currently *depends on* the non-resolution — on macOS
`mkdtemp` returns `/var/folders/...` while the resolved form is `/private/var/folders/...`.
That assertion needs `Path(tmpdir).resolve()` alongside the fix.

### W4 — G1 (the override guard) is now satisfiable by a comment
`run-selftests.sh:47` — `OVERRIDE_PATTERN='^REPO[[:space:]]*=.*SPEC_LINT_REPO_OVERRIDE'`

Before this PR the pattern matched executable code:
`REPO = Path(os.environ.get("SPEC_LINT_REPO_OVERRIDE", ""))...`. In 13 of 15 files it now
matches only the trailing comment:

```python
REPO = slp.find_repo_root(start=Path(__file__).resolve().parent)  # honors SPEC_LINT_REPO_OVERRIDE
```

`REPO = Path("/hardcoded")  # honors SPEC_LINT_REPO_OVERRIDE` passes G1 unchanged. The
run-selftests comment acknowledges the widening ("pattern matches both forms"), so this is a
knowing trade — but it is a guard-strength regression, not a neutral refactor, and it is the
guard that protects the property BI-043 exists to establish. Selftests 25 and 30 pin real
fail-closed behavior for `check-canonical-facts.py` only; the other 14 files have no
behavioral pin.

Suggestion: tighten to `^REPO[[:space:]]*=.*(slp\.find_repo_root|os\.environ\.get\(.SPEC_LINT_REPO_OVERRIDE)`
so the match lands on code, and/or strip trailing comments before grepping
(`sed 's/#.*//'`) as `run_splitlines_guard` already does for full-line comments.

### W5 — `run_splitlines_guard`'s two exemptions are dead code, and the primitive module is consequently unscanned
`run-selftests.sh:122-123`

```bash
[[ "$(basename "$f")" == "spec_lint_primitives.py" ]] && continue
[[ "$(basename "$f")" == "test_spec_lint_primitives.py" ]] && continue
```

Neither basename can ever appear in the loop's file list, which is
`check-*.py` + six explicitly named `gen-*.py`. The `continue` statements are unreachable —
consistent with the AC-4 evidence reporting exactly `15 files checked` (9 checkers + 6
generators, i.e. the unexempted set).

Answering the scoping question directly: the guard exempts the right files *by accident*,
via the glob rather than the exemptions. The cost is that `spec_lint_primitives.py` is not
scanned at all, so a raw `.splitlines()` added anywhere in the primitive module outside
`cm_splitlines` would not fire G4. Either widen the loop to `"$dir"/*.py` (making the
exemptions live and the guard actually complete), or delete the two lines so the scope the
code implies matches the scope it enforces.

### W6 — `is_historical_changelog_line` is a suppression predicate with zero unit tests, and its docstring overstates what it enforces
`spec_lint_primitives.py:171-176`

```python
in_quotes = (
    ('"' in before and '"' in after)
    or _CHANGELOG_VERSION_RE.search(line) is not None
)
has_version = bool(re.search(r"v\d+\.\d+", line))
return in_quotes and has_version
```

The docstring says "the match is bracketed by double-quotes on the same line **AND** the
line contains a version marker". The second disjunct makes the bracketing requirement inert:
if the line contains any quoted `v\d+\.\d+` string, `in_quotes` is `True` regardless of
where the match sits, and `has_version` is then also `True`. The predicate collapses to
"line contains a quoted version string" and suppresses *every* match on that line.

Failure scenario:
`- "v1.2: replaced non-conforming EC-NEW-3 with EC-164" — but DI-PENDING-2 is still live`
The live `DI-PENDING-2` R3-B violation is outside the quotes but is suppressed anyway.

This logic is carried over verbatim from `check-id-resolution`/`check-placeholders`, so it
is **not a regression** — I am flagging it because promoting a suppression predicate into
the shared layer is the moment to pin it. `is_historical_changelog_line` and
`WOULD_BE_ID_RE` are the only two public primitives with **no test at all**, and they are
precisely the two that turn findings *off*. At minimum, add tests that fix current behavior
so a future tightening is a deliberate, visible change, and correct the docstring to
describe the disjunction that is actually implemented.

### W7 — `split_table_cells` accepts lines that merely contain pipes, and `check-ec-injectivity` dropped the `startswith("|")` guard that used to compensate
`spec_lint_primitives.py:86` discards `parts[0]` unconditionally, even when non-empty.

**[executed]**: `split_table_cells("See row: | EC-001 | dup desc |")` → `['EC-001', 'dup desc']`

`check-placeholders.py:139` and `check-id-resolution.py:336` both keep
`if line.startswith("|")` before calling it. `check-ec-injectivity.extract_ec_rows`
(`check-ec-injectivity.py:114-120`) replaced a regex that *required* `^\|` with a bare
`split_table_cells` call and no such guard.

Failure scenario: a prose line in a BC file, `Duplicate of: | EC-001 | disk full |`, is now
parsed as an EC data row and enters the injectivity map as a second `(EC-001, "disk full")`
pair — producing a spurious description collision, or masking a real one. `extract_ec_rows`
has no fenced-code gating either, so an illustrative row inside a code fence is affected the
same way.

Fix (either): add `if not line.startswith("|"): continue` in `extract_ec_rows`, or make the
primitive honest about its docstring ("Split a CommonMark table **row**") by returning `[]`
when `cm_strip_cell(parts[0]) != ""`. I'd prefer the latter — it fixes all five call sites
and the invariant then lives in one place, which is the point of the PR.

### W8 — `EC-\d+` → `EC_TOKEN_RE` is not an output-neutral substitution in general; only on today's corpus
`check-counts.py:385,390,457` and `check-holdout-boundary.py:56,65,119`.

The old `r"\bEC-(\d+)\b"` **does not** match `EC-079a` — the trailing `\b` fails before the
`a`. `EC_TOKEN_RE` (`\bEC-(\d{1,4})([a-z]?)\b`) does, and the call sites take `group(1)`, so
sub-lettered ECs now fold into their base number. That changes three predicates:

- `ec_base_nums` in the POL-16 declared-EC-count check (`check-counts.py:385`)
- the §4 `EC-lo through EC-hi` range check (`check-counts.py:457`)
- `parse_active_holdout_ec_ids()`, which now accepts sub-lettered `HS-INDEX` cells that
  `\|\s*(EC-(\d+))\s*\|` previously skipped (`check-holdout-boundary.py:65`)

The byte-identical output the operator measured establishes that today's corpus contains no
sub-lettered EC in those positions — it does not establish that the predicates are
equivalent. Both directions are arguably improvements, but they belong in the PR body as
deliberate semantic changes, so a future count movement isn't misattributed to spec content
during WS-4.

### W9 — the `--property-test` lazy-REPO residual is documented in the code but the *reason* is nowhere in the diff, and the error-path handling is inconsistent across the 14 migrated files
Answering the question directly: **partially.** `check-index-integrity.py:20` names the
residual in an inline comment ("None in --property-test mode"), which is adequate for a
reader of that line. What is missing:

- The *reason* — that module-level fail-closed resolution raises inside a linked worktree —
  appears nowhere in the diff, the docstring, or `evidence-report.md`. A future maintainer
  will read the ternary as arbitrary and "simplify" it back.
- `SPECS` and `FACTORY` become `None` too, so any future property-test code path touching
  them gets `TypeError: unsupported operand type(s) for /: 'NoneType' and 'str'` rather than
  a named refusal. A `_require_repo()` accessor would make the failure legible.
- `sys.argv[1] == "--property-test"` inspects only `argv[1]`, so
  `check-index-integrity.py --verbose --property-test` would take the fail-closed branch and
  raise. Fine today (no other flags), fragile as soon as one is added.
- Error-path asymmetry: `check-canonical-facts.py` catches `RuntimeError` and prints the
  operator guidance before `sys.exit(1)`. The other 13 migrated files let it propagate as a
  traceback. Fail-closed still holds (non-zero exit, and `find_repo_root`'s message does
  carry "Set SPEC_LINT_REPO_OVERRIDE..."), but BI-021's stated goal was a *loud, legible*
  refusal, and 13 files now deliver it wrapped in a stack trace. Worth a shared
  `slp.resolve_repo_or_exit(name)` helper.

### W10 — no checker-level negative selftest for the bypass class BI-040 closes
`EXPECTED_TEST_COUNT` stays at 55 and the diff adds zero numbered selftest cases. The
`\f## Heading` / `\v## Heading` phantom-line bypass in `check-index-integrity.py` — whose
comment this PR rewrites from "Known residual" to "CLOSED via slp.cm_splitlines()" — has no
end-to-end regression test. The teeth are entirely (a) primitive-level unit tests, which B2
shows are weaker than they appear, and (b) G4's grep over an explicitly enumerated file list.

The suite's own convention (55 negative tests, each proving clean-pass *and* defect-fail) is
the right home for one fixture: a `HS-INDEX.md` containing `\f## Heading`, asserted to no
longer kill section scope. Without it, a newly added checker outside G4's generator list, or
a change to the heading/fence bucketing, breaks the closure claim silently.

### W11 — three write-generators newly accept an env-var-controlled root
`gen-bc-index.py:34`, `gen-prd-sections.py:30`, `gen-rtm.py:41` (and `gen-ec-registry.py:26`)
previously resolved `REPO` from `__file__` with no environment input. They now honor
`SPEC_LINT_REPO_OVERRIDE`, and three of them write files into `REPO`. This is consistent with
BI-043 and with the pre-existing generators, and it is what makes them testable in an
isolated tree — but it is a new env-controlled write path arriving as a side effect of
"consolidate repo-root resolution". It deserves an explicit line in the PR body.

### W12 — demo evidence is text-only, and records only success paths
`docs/demo-evidence/BI-040/` contains 4 `.txt` transcripts + `evidence-report.md`; there is
no `.gif`/`.webm`. My standing review checklist classifies text-only demo evidence as
BLOCKING. I am recording it as a WARNING instead, and want to be explicit about why: BI-040
has no visual surface, the transcripts are complete and reproducible, and
`docs/demo-evidence/` contains no other story, so there is no established recording
tooling in this repo to have ignored. A single `vhs`/`asciinema` cast of the guard run would
satisfy the letter of the rule cheaply, and this PR is setting the repo precedent either way.

Separately, all four ACs record the **success** path. The most probative evidence for this PR
is the negative path: G4 firing on a poisoned checker, and the fail-closed refusal inside a
linked worktree. The PR body states those were executed; they are not in
`docs/demo-evidence/BI-040/`. Adding an `AC-005-mutation-teeth.txt` would make the artifact
self-supporting to a reviewer who cannot see the pipeline.

---

## NITS

- **N1** — `import spec_lint_primitives as slp` is appended to the stdlib import block with
  no blank line separating first-party from stdlib, in all 15 files (PEP 8 grouping).
  Cosmetic, but it is the one convention a linter would flag across the whole diff.
- **N2** — answering the `start`-is-a-file question: `find_repo_root(start=Path(__file__))`
  does **not** crash. The nonexistent-child `.exists()` probes return `False` and `.parent`
  reaches the directory, so it silently absorbs one of the 8 walk levels. That tolerance is
  accidental, not documented. Either note it ("`start` may be a file; treated as its
  parent") or make it explicit: `start = start.parent if start.is_file() else start`.
- **N3** — stale-on-arrival comments in `run-selftests.sh`: the guard-4 header still reads
  "Stage 3 generators are excluded until Stage 3 migration is complete" and describes scope
  as "Stage-2 generators (gen-bc-traceability.py, gen-slug-corpus.py)", while
  `run_splitlines_guard`'s own comment correctly says "Stage 3 scope: check-*.py + all
  generators". Stage 3 shipped in this same PR. The G3 header ("If this guard fires, Stage 1
  is incomplete") and `spec_lint_primitives.py:14` ("Stage 1: nothing imports it yet") are
  stale in the same way.
- **N4** — diff is ~1,272 lines across 19 files, over the 500-line flag threshold.
  Acceptable here: 11 of 19 files are a single `REPO=` line plus mechanical `cm_splitlines`
  substitutions, and the substantive surface is `spec_lint_primitives.py` (223) +
  `test_spec_lint_primitives.py` (469) + the guards. Not a request to split.

---

## What I verified clean

- **No missed migration sites.** Zero raw `.splitlines()` and zero `parent.parent.parent`
  repo-root resolutions remain in any `.py` under `scripts/`. The only surviving
  `parent.parent` is `test_spec_lint_primitives.py:29`, a `sys.path` insert.
- **No import defects.** All 15 scripts import cleanly under an override; every file that
  dropped `import os` has zero remaining `os.` references.
- **`extract_tv_rows` group renumbering is correct.** Collapsing `(EC-(\d+[a-z]?))` to a
  single group shifted groups 4/6 → 3/5, and `check-ec-injectivity.py:150-152` was updated
  consistently. This is the kind of off-by-one a mechanical migration usually gets wrong.
- **BI-041 boundary respected.** `gen-bc-traceability.py`'s diff touches only imports, the
  `REPO=` line, and one `cm_splitlines` call. `--write` is not enabled.
- **`cm_strip_cell`'s CommonMark whitespace set is right** (`\t\n\x0b\x0c\r ` = the six
  §2.1 codepoints), and `test_cm_strip_cell_closed_under_discovery` is the strongest test in
  the suite — its oracle is independent of the implementation, which is exactly what B2 is
  missing.
- **Fail-closed ordering in `find_repo_root` is correct.** `.factory/specs` is probed before
  `.git` at each candidate, so a main checkout (which has both at the root) resolves rather
  than refusing.
- **Test-count structural guards are real.** Both `EXPECTED_PRIMITIVE_TEST_COUNT` (9) and
  `EXPECTED_TEST_COUNT` (55) hard-fail on drift; the `@register` decorator makes a silently
  skipped test impossible.
- **Not a portability problem:** I checked `grep -v '^\s*#'` in `run_splitlines_guard`
  against `/usr/bin/grep` on macOS — `\s` is honored, indented comments are correctly
  filtered, and `sss#` does not match. No BSD-grep false positive.

## Explicitly out of scope — flagged, not absorbed

Per the dispatch, I did not evaluate and am not blocking on: the 80/10 spec-content baseline
findings (WS-4, gated on this merge), the ~53 POLICY-5 quoted-excerpt fabrications (BI-027),
or `gen-bc-traceability --write` (BI-041, prohibited until adjudicated). I confirmed the diff
does not enable the latter.

The two disclosed residuals are handled correctly as residuals: the CRLF non-split is a named,
documented deviation with a do-not-remove marker in the `cm_splitlines` docstring, and I am
not treating it as a defect. The `--property-test` lazy-REPO deviation is real and correctly
flagged for attention rather than hidden — see W9 for the documentation gap, which is a
suggestion, not a block.

---

**VERDICT: REQUEST_CHANGES**

B1 and B2 are the merge blockers. Both are confined to `spec_lint_primitives.py` and
`test_spec_lint_primitives.py`, both are a few lines, and neither requires re-running the
migration. W1/W2 travel together (the hardcoded EC grammar has already produced one silent
truncation bug) and I would fix them in the same pass, but I am not blocking on them. The
migration itself is careful, mechanically consistent across 15 files, and the two hardest
things to get right — the `extract_tv_rows` group renumbering and the `.git`-vs-`.factory`
probe ordering — are both correct.

**covered_sha:** ae033562f55a9b29b1d8997601bfd6b09e6229ea
