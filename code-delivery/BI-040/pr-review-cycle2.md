# PR Review — Cycle 2 (BI-040 shared spec-lint primitive layer)

**covered_sha:** `21ec86549f143651a0003957d596fc3e86103729`
**Range reviewed:** `ae03356..21ec865` (4 files, +109/−27)
**Verdict:** **CHANGES REQUESTED** — 1 blocking, 4 suggestions, 2 nits

Every claim below was verified by execution, not by reading. Method for each fix:
apply the reverse mutation, then run both test layers (`test_spec_lint_primitives.py`
= 10 unit tests, `run-selftests.sh` = 55 negative selftests) and check whether
anything flips. A fix whose reverse mutation survives both layers is unprotected.

---

## Cycle 1 findings — disposition

| ID | Status | Evidence |
|----|--------|----------|
| **B1** | ✅ **FIXED, mutation-proven** | `is_conforming_vp_cell(",", "proof")` → `False`. Also `/`, `,,,`, `,/,` → `False`; `VP-001`, `VP-001,VP-002`, `VP-NONE` still `True`. Reverting to the old `if t.strip(...)`-inside-`all()` form flips `test_is_conforming_vp_cell` → `FAIL: comma-only must be non-conforming`. |
| **B2** | ✅ **FIXED, mutation-proven** | Replacing the `cm_splitlines` body with `return [text]` now flips `test_cm_splitlines_closed_under_discovery` → `FAIL: cm_splitlines must split on LF`. Confirmed the four new assertions are non-tautological. |
| **W2** | ✅ **FIXED** | `\b` is effective and the `group(0)` choice is correct — see verification note below. |
| **W3** | ✅ **FIXED, mutation-proven** | On macOS `find_repo_root(start=/var/folders/.../tmpX)` returns `/private/var/folders/.../tmpX`, so `str(result) == tmpdir` is `False` and the resolved comparison is genuinely required. Dropping `.resolve()` flips `test_find_repo_root_hermetic`. |
| **W4** | ⚠️ **PARTIALLY FIXED** — still comment-satisfiable for one file. See **S2**. |
| **W5** | ✅ **FIXED** | Loop now covers all 16 `.py` in `$LINT_DIR`, exempts 1, scans 15 — guard reports `15 files checked, 0 raw .splitlines() uses`. Exemption logic correct. One dead exemption, see **N1**. |
| **W6** | ✅ Docstring now accurate; test added. Test has two blind spots — see **S3**. |
| **W7** | ⚠️ Behaviour correct and output-identical, but **completely untested**. See **BLOCKING-1**. |
| **W9** | ✅ **FIXED** | Comment expanded; explanation is accurate and matches the observed `RuntimeError` in a linked worktree. |

Regression baseline at HEAD: **55/55 selftests**, **10/10 primitive tests**, both green.

---

## BLOCKING-1 — the W7 fix has zero test coverage, and the existing test now documents the *old* contract

`scripts/spec-lint/spec_lint_primitives.py:87` (and `selftest/test_spec_lint_primitives.py:276`)

W7 changed the published contract of `split_table_cells` — a primitive with four
production call sites — and nothing pins the new behaviour. I removed the guard
entirely:

```python
    if len(parts) < 2:          # W7 guard deleted
```

Result: **10/10 primitive tests pass** and **55/55 selftests pass**. The whole fix
is invisible to the test suite. A second mutation that keeps the guard but drops
the CommonMark-whitespace handling (`parts[0] != ""` instead of
`cm_strip_cell(parts[0]) != ""`) also survives both layers, even though it silently
breaks every indented table row.

What makes this blocking rather than a coverage nit is that `test_split_table_cells`
still *asserts the pre-W7 contract in its docstring*:

```
split_table_cells splits on '|', discards first part (pre-first-pipe), strips
```

It no longer discards the pre-first-pipe part — it rejects the line. So the test
documents behaviour the code deliberately stopped having. That is the same
false-assurance class as cycle-1 B2 (a test that claimed coverage it did not
provide), which was treated as blocking. This is strictly worse: B2 had a weak
assertion, W7 has none.

**Failure scenario this leaves open:** anyone "simplifying" the guard back —
exactly the change the new docstring warns against — gets a fully green
`run-selftests.sh`, and `check-ec-injectivity.py:115` / `check-holdout-boundary.py:66`
silently resume treating prose lines with pipes as table rows.

Remedy — three lines, and I verified each assertion kills its mutant:

```python
    # W7: prose before the first pipe means this is not a table row.
    assert slp.split_table_cells("See: | EC-001 | desc |") == [], (
        "non-whitespace before first '|' must not be parsed as a table row"
    )
    # ...but leading CommonMark whitespace still is one.
    assert slp.split_table_cells("  | VP-001 | x |") == ["VP-001", "x"], (
        "leading CM whitespace before first '|' is still a table row"
    )
```

`split_table_cells("See: | EC-001 | desc |")` returns `['EC-001', 'desc']` under the
guard-deleted mutant and `[]` under HEAD. `split_table_cells("  | VP-001 | x |")`
returns `[]` under the no-strip mutant and `['VP-001', 'x']` under HEAD. Please also
update the docstring's "discards first part (pre-first-pipe)" line.

---

## SUGGESTION S2 — W4 is not actually closed for the one file it was about

`scripts/spec-lint/selftest/run-selftests.sh:47`

```bash
OVERRIDE_PATTERN='^REPO[[:space:]]*=.*(slp\.find_repo_root|os\.environ\.get[^#]*SPEC_LINT_REPO_OVERRIDE)'
```

The `[^#]*` comment-exclusion was applied to the second alternative only. The first
alternative, `slp\.find_repo_root`, is still reachable through a comment — and
`check-index-integrity.py` is the single file that depends on that, because its
`REPO =` line is a multi-line expression whose real call sits on a continuation line:

```python
REPO = (  # honors SPEC_LINT_REPO_OVERRIDE via slp.find_repo_root; None in --property-test mode
    ...
    else slp.find_repo_root(start=Path(__file__).resolve().parent)   # ← line 26, not the REPO= line
)
```

Proven: I replaced line 26 with `else Path("/hardcoded/repo/root")` — destroying
override support outright — and the guard still passed, matching on line 20's
trailing comment. For that one checker the guard provides zero coverage, which is
precisely the defect W4 was raised to close. The other 14 files are genuinely
covered (their real call is on the `REPO =` line).

Note the obvious tightening does *not* work: adding `[^#]*` to the first alternative
makes the guard fire on `check-index-integrity.py` (false positive, verified),
because the real call is not on that line at all. A two-part check does work — I
ran it against all 15 files (all pass) and against the mutant (fires):

```bash
grep -qE '^REPO[[:space:]]*=' "$f" \
  && grep -v '^[[:space:]]*#' "$f" \
     | grep -qE '(slp\.find_repo_root\(|os\.environ\.get\([^)]*SPEC_LINT_REPO_OVERRIDE)'
```

If you keep the single-regex form instead, please drop a comment on line 47 stating
that `check-index-integrity.py` satisfies it via comment only, so the residual is
visible rather than latent.

---

## SUGGESTION S3 — the new W6 test leaves the entire quote-bracketing branch unpinned

`scripts/spec-lint/selftest/test_spec_lint_primitives.py:456`

The new test is a real improvement (3 of 5 mutations caught), but two survive both
test layers, and together they cover all of the quote logic:

| Mutation | Survives? | Unpinned input |
|---|---|---|
| `return in_quotes and has_version` → `return has_version` | **yes** | `("v1.2 mentions EC-001 in plain prose, no quotes", "EC-001")` → HEAD `False`, mutant `True` |
| remove disjunct 1 (`'"' in before and '"' in after`) | **yes** | `('v1.2 - "EC-001 renamed"', "EC-001")` → HEAD `True`, mutant `False` |

The first is the significant one: `in_quotes` can be deleted entirely and the test
still passes, i.e. the function could degrade to "line contains a version marker"
undetected. The second shows disjunct 1 is load-bearing (for a version marker
*outside* the quoted region, where `_CHANGELOG_VERSION_RE` does not fire) but
untested. Two assertions close both — verified against the mutants:

```python
    # A version marker alone must not suppress — the quote logic is load-bearing.
    assert not slp.is_historical_changelog_line(
        "v1.2 mentions EC-001 in plain prose, no quotes", "EC-001"
    ), "version marker without quotes must not suppress"

    # Disjunct 1: quote-bracketed match, version marker outside the quotes.
    assert slp.is_historical_changelog_line('v1.2 - "EC-001 renamed"', "EC-001"), (
        "quote-bracketed match with version marker outside quotes should suppress"
    )
```

---

## SUGGESTION S4 — W5 widened G4's scope without adding G4's proof arm

`scripts/spec-lint/selftest/run-selftests.sh:107`

`run_override_guard` and `run_suppression_guard` each have a guard-selftest (G1, G2)
proving they fire on a planted defect, plus G3 proving both fail closed on an empty
directory. `run_splitlines_guard` — labelled G4 at line 181 — has neither. Grepping
for `G4` finds only the pre-flight invocation; there is no G4 arm in the selftest
body. It is now the only guard in the file whose firing behaviour is unverified,
and this commit is what changed its scope.

Per the repo's own D-040 recursion ("`run_override_guard` must itself be proven to
fire"), G4 should get a matching arm: a temp dir containing a `check-x.py` with a
raw `.splitlines()` (guard must return 2), a clean one (must return 0), and an empty
dir (must return 2). Flagging in case the deferred W10 was intended to cover this —
if so, say so explicitly, because W10 as scoped reads as *checker*-level, not
*guard*-level.

---

## NIT N1 — one of W5's two exemptions is dead code

`scripts/spec-lint/selftest/run-selftests.sh:124`

`run_splitlines_guard` is only ever called with `$LINT_DIR` = `scripts/spec-lint`,
but `test_spec_lint_primitives.py` lives in `scripts/spec-lint/selftest/`. The
`"$dir"/*.py` glob is non-recursive, so that exemption is unreachable — confirmed by
the reported count (16 `.py` in the directory, 1 exempted, `15 files checked`).

Harmless as defence-in-depth, but the commit message says W5 made "the two
exemptions (spec_lint_primitives.py, test_spec_lint_primitives.py) live" — only one
became live. Either note it as forward-looking, or scan `selftest/` too (in which
case the exemption becomes real and the guard also covers future selftest modules).

---

## NIT N2 — W7 docstring says "all 5 call sites"; there are 4

`scripts/spec-lint/spec_lint_primitives.py:80`

Production call sites: `check-holdout-boundary.py:66`, `check-id-resolution.py:337`,
`check-placeholders.py:140`, `check-ec-injectivity.py:115`. The count also appears in
the commit message.

---

## Review-focus answers

**1. Are B1 and B2 genuinely fixed?** Yes, both mutation-proven — see the table
above. Neither new assertion set is tautological.

**2. Does W7 break any of the call sites?** No — verified by output identity, not by
inspection. I ran all 9 checkers against the real corpus (134 artifact files) twice,
once at HEAD and once with the W7 guard reverted, capturing stdout+stderr+exit codes:
the two transcripts are **byte-identical**, including the 10 `check-id-resolution`
violations and the ~80 `check-placeholders` violations. Mechanism:

- `check-id-resolution.py:336` and `check-placeholders.py:139` are gated by
  `line.startswith("|")`, which implies `cm_strip_cell(parts[0]) == ""`. W7 is a
  strict no-op at those two.
- `check-holdout-boundary.py:66` and `check-ec-injectivity.py:115` are ungated, so
  W7 is live there — the intended tightening — and no real corpus line is affected.

Worth knowing (pre-existing, not introduced here, WS-4 territory): W7's guard accepts
leading CommonMark whitespace, but the two gated call sites' own `startswith("|")`
does not, so `  | EC-NEW-1 | x |` still bypasses R3-A in `check-id-resolution.py`.
The primitive is now more permissive than its callers.

**3. Does W4's tightened pattern still pass for all 15 scripts?** Yes — the pre-flight
guard reports `15 checkers/generators support SPEC_LINT_REPO_OVERRIDE`. But for one
of the 15 it passes for the wrong reason: see **S2**.

**4. Does W5's widened loop correctly exempt both files?** `spec_lint_primitives.py` —
yes, correctly exempt and now genuinely in the loop's path.
`test_spec_lint_primitives.py` — the exemption is dead code (**N1**). All 15 other
`.py` files are scanned. Logic is correct.

**5. New issues introduced by the fixes?** No behavioural regressions. Everything
above is either a residual (S2) or a test-coverage gap in the new code (BLOCKING-1,
S3, S4). Two things I checked specifically and cleared:

- **W2 `group(0)` vs `group(1)`** — `group(0)` is correct, not a bug. The HS-INDEX
  side (`check-index-integrity.py:357,362`) captures `EC-\d{1,4}[a-z]?` *including*
  the letter suffix, so a hypothetical `EC-156a-*.md` yields `EC-156a` on both sides.
  `group(1)` would have desynchronised them.
- **W2 `\b` tightening is fail-closed.** `EC-15678.md` → no match (the old inline
  pattern silently truncated it to `EC-1567`); `ECX-156.md`, `EC-156_x.md` → no
  match. An unmatched filename drops out of `wave_ec_ids`, which makes the forward
  check at line 799 emit *"no wave-scenarios file found for this EC ID"* — loud, not
  silent. All 7 real `wave-scenarios/*.md` filenames still match. Note the reverse
  check (line 807) can't see a file it failed to parse, so a stray
  `EC-156_x.md` with no HS-INDEX entry would go unreported; edge case, no corpus
  instance, mentioning only for the record.

## Out of scope (confirmed, not re-litigated)

The **Spec lint CI failure is pre-existing and out of scope**. I pulled the job log
at `21ec865` and diffed it against my local run: it is exactly the known WS-4
spec-content set — `Check FAILED: 10 unresolvable ID references` (`TV-BV013`,
`EC-NEW-1/2/10..16`) plus ~80 `check-placeholders` hits (`—`, `[filled by
story-writer]`). Identical at `ae03356`. All other checks green: Format, Clippy,
Test (macos-latest), Build release, GitGuardian.

Also not re-raised, per the agreed scope: the 80/10 spec-content findings (WS-4),
BI-027, BI-041 write-mode, W1 remaining inline grammars (the HS-INDEX row patterns at
`check-index-integrity.py:357,362` are in this class), W10, W12.

One observation outside the diff, for whoever picks up WS-4: `check-ec-injectivity.py`,
`check-id-resolution.py`, and `check-placeholders.py` emit
`SyntaxWarning: invalid escape sequence '\d'` from module docstrings. Present on
`develop`, untouched by this PR, so not a finding here — but `spec_lint_primitives.py`
is clean (it escapes as `\\d`), so the new module sets the right precedent.

---

## Summary

The nine fixes are technically sound and the refactor is output-identical on the real
corpus — I verified that rather than assuming it. B1, B2 and W3 are properly
mutation-proven, which is exactly what cycle 1 asked for.

The one thing standing between this and approval is that **W7 — the only fix in the
commit that changes a primitive's published contract — shipped with no test at all,
while the existing test's docstring still describes the behaviour it replaced.** For a
PR whose entire thesis is "a shared, mutation-proven primitive layer", that gap sits
at the centre of the claim. It is a three-line fix and I have verified the exact
assertions that close it.

Bundle S3's two assertions with it and cycle 3 should be a single small commit.
