# PR #3 Review — `feature/spec-lint-hardening` → `develop`

**Reviewed SHA:** `031ca5b04279c83355b8b0e956ab238e6ba1d485`
**Verdict:** REQUEST_CHANGES

Scope: the fix delta `1fc1bce..031ca5b` (B-9, B-10, F-12, F-13, F-14, F-15, F-16) plus
the `origin/develop` merge. `Spec lint` advisory failure (25 Phase-2 placeholders) is
not treated as a finding per D-029/D-032. MUT-1 (near-miss capture) is not raised, per
the binding operator ruling.

---

## Disposition of the claimed fixes

| Claim | Verdict |
|-------|---------|
| **B-9** — `raw.strip()` normalisation closes the V-9 leading-space bypass | ✅ **VERIFIED** (V-1 A6, V-4 MUT-B) |
| **B-9** — accounting invariant replaces the `len(hs_mapping) == 0` guard | ❌ **PARTIAL — see B-11.** The invariant is real and tested, but its denominator is computed *inside* the same pre-filter chain as the classifier, so it is blind to pre-filter skips. Demonstrated false pass, and a regression vs `1fc1bce`. |
| **B-10** — tests 10e/10f/10g/G3 added, count 17→21 | ✅ **VERIFIED** (V-2, V-3, V-4, V-5, V-6) |
| **F-12** — `in_authored_scenarios` + `found_separator` scoping | ⚠️ **Behaviourally correct, untested** (F-18); and it is the proximate cause of B-11 |
| **F-12** — `in_authored_scenarios=True` default for heading-less fixtures | ✅ **Probed, acceptable** (V-1 A5) |
| **F-13** — `near_misses` as `list[str]` | ✅ **VERIFIED** (V-1 A8) |
| **F-14** — `$SUPPRESSION_PATTERN` interpolated into remediation text | ✅ **VERIFIED** |
| **F-15** — fail-open documented, ordering load-bearing | ⚠️ **Residual accepted as MINOR** (V-7) — see judgment below |
| **F-16** — overclaim softened | ✅ **VERIFIED** |
| Merge came through clean, PR #4/#5 not reverted | ✅ **VERIFIED** (V-8) |
| Real-tree output as claimed | ✅ **VERIFIED verbatim** (V-9) |
| PR description accurate as to test count | ❌ **FAIL** (F-17) |

---

## BLOCKING

### B-11 [BLOCKING] The accounting invariant shares its pre-filter chain with the classifier, so rows skipped by the pre-filters are invisible to *both* — a demonstrated false pass, and a regression from `1fc1bce`

**File:** `scripts/spec-lint/check-index-integrity.py:188-211` (the pre-filter chain), with
the invariant itself at `:450-463`.

`hs_rows_seen` is documented as the invariant's independent denominator:

> `hs_rows_seen`: count of data rows … computed by cell-splitting, **structurally
> independent of the four parser patterns**. … any row that defeats the parser is
> reported rather than silently dropped.

The first clause is true; the second is not. `hs_rows_seen += 1` is at line **211**, which
is *after* five `continue` pre-filters at lines 188, 190, 195, 198 and 202. Any row skipped
by a pre-filter is never counted **and** never classified, so `hs_rows_seen == hs_canonical
+ hs_nonconforming` holds vacuously and the invariant cannot fire. The denominator is
independent of the four regexes but shares every pre-filter with them — which is precisely
the B-9 failure mode (guard and parser sharing a failure mode) wearing its third hat, and
the BI-023 variant this review was asked to hunt for.

Three reachable instances, all confirmed by execution (V-1). Each injects
`HS-042 → EC-999` with **no** `wave-scenarios/EC-999-*.md` file — the exact defect the
forward check exists to catch:

| Probe | Malformed row | New checker | Checker @ `1fc1bce` |
|-------|---------------|-------------|---------------------|
| **A1** | row placed *above* the `\|---\|` separator | **exit 0** — `HS (1 validated, 0 non-conforming, 1 rows seen)` | **exit 1** — violation reported |
| **A2a** | first cell empty: `\|  \| EC-999 \| …` | **exit 0** | exit 0 (pre-existing) |
| **A2b** | first cell `-`: `\| - \| EC-999 \| …` | **exit 0** | exit 0 (pre-existing) |

**A1 is a regression introduced by this delta.** The row parsed fine at `1fc1bce` (no
scoping existed) and the forward check reported it. The F-12 scoping fix closed an
over-matching hole and opened this under-matching one — the fifth instance this session of
a remediation introducing a defect, and the third where closing a false-pass hole opened a
new one.

**A2a/A2b are not regressions** but they matter more for realism: unlike A1, a row with an
empty or `-` first cell **renders as a perfectly normal Markdown table**, so there is no
visual signal. The mechanism is line 198 — `set(first_cell) <= set("-: ")` is `True` for the
empty string and for any cell made only of ASCII `-`, `:`, or spaces, so such rows are
misclassified as *separator* rows, skipped, and additionally reset `found_separator = True`.
These are exactly the "row that defeats the parser" cases the invariant advertises catching,
and it does not catch them.

For completeness, two related pre-filter escapes fail *closed* and are **not** part of this
finding: removing the separator row (A3) and renaming the `## Authored Scenarios` heading
(A4) both exit 1 via the reverse check. The reverse check is not a general backstop, though
— it only fires for EC IDs that *have* a wave-scenarios file, which is why A1/A2a/A2b get
through it.

**Suggestion.** Make the denominator genuinely independent by counting before the scoping
and separator pre-filters, and classify header/separator rows explicitly rather than by
early `continue`. Concretely: in the loop, for every line where
`line.startswith("|")`, increment a raw `hs_pipe_lines` counter, and account for each such
line in exactly one bucket — `header`, `separator`, `canonical`, `malformed`, `near_miss`,
or `unaccounted` — then assert
`hs_pipe_lines == header + separator + canonical + malformed + near_miss` with
`unaccounted == 0`. That keeps the F-12 scoping benefit (header rows still are not
*matched*) while making mispositioned and blank-ID rows land in `unaccounted` instead of
vanishing. A minimal alternative: move `hs_rows_seen += 1` above line 198 and add an
explicit `if not first_cell:` violation branch — but the bucket form is what actually
delivers the docstring's claim.

**Also fix the docstring at `:142-147` and the comment at `:450-452`**, which currently
assert a guarantee the code does not provide. Add a selftest: clean tree, then append
`|  | EC-999 | … |` (no `EC-999` file) and assert non-zero exit. That test fails today.

---

## MAJOR

### F-17 [MAJOR] The PR description is stale — it advertises 17/17 and a function that no longer exists

**File:** PR #3 body (not a tracked file).

The body still describes the pre-`1fc1bce` state throughout:

- `"All 17 selftest cases converted to isolated temp trees"` — actual count is **21**.
- `"After both restores: Selftest passed: 17/17 negative tests verified"` — actual is **21/21**.
- Two guard-fire evidence blocks quote `Selftest FAILED: 1/17` and `"all 15 other tests unaffected"`.
- Test plan: `` just spec-lint-selftest `` passes with `17/17`.
- `"replaced dead get_actual_hs_files() stub with get_hs_ec_mapping()"` — `get_hs_ec_mapping` was renamed to `get_hs_data` in this very delta and no longer exists.
- All six test-plan checkboxes are unchecked (`- [ ]`), and no PR comment carries the 21/21 evidence (verified: `gh pr view 3 --json comments | grep -c 21/21` → `0`).

A reviewer or auditor reading the PR body would conclude the delivered suite is 17 tests
and would look for a function that is not in the tree. Nothing about B-9's accounting
invariant, F-12 scoping, F-13, F-14, F-15 or F-16 appears in the description at all.

**Suggestion.** Update the body: test count 17→21, add 10e/10f/10g/G3 to the enumeration,
replace `get_hs_ec_mapping()` with `get_hs_data()`, paste the current
`Selftest passed: 21/21 …` and the real-tree `80 structural checks … HS (7 validated,
0 non-conforming, 7 rows seen)` lines, tick the test-plan boxes, and add a short section
covering the B-9/F-12..F-16 remediation. This is not a merge-blocker on its own, but it
should land in the same push as the B-11 fix.

---

## MINOR

### F-18 [MINOR] The F-12 section-scoping fix has zero selftest coverage

**File:** `scripts/spec-lint/check-index-integrity.py:183-189`.

MUT-E — replacing `in_authored_scenarios = "Authored Scenarios" in line` with
`in_authored_scenarios = True`, i.e. deleting the entire F-12 fix — leaves the suite at
**21/21 PASS** (V-6). No test distinguishes scoped from unscoped matching.

Downgraded from blocking on two grounds. First, the mutation direction is *over*-reporting,
not under-reporting: it cannot produce a false pass. Second, it is caught by the real-tree
invocation — under MUT-E the checker exits 1 on the real tree with
`17 data row(s) seen … but only 7 classified (10 row(s) unaccounted for)`, because the
Reserved-IDs table gets pulled into scope. So the fix is not unverified in practice, only
unverified by the suite. D-040 asks for a negative test proving a check *can fail*; F-12 is
a suppression of reporting, so its natural test is a positive one.

**Suggestion.** Add a clean-pass-only assertion: an HS-INDEX with a valid
`## Authored Scenarios` table plus a `## Reserved IDs` table whose first column holds
`EC-` and `HS-`-prefixed cells, asserting exit 0. That flips MUT-E and pins the scoping.
Note the existing fixtures already cover the *opposite* direction well — MUT-F (drop the
`found_separator` pre-filter) and MUT-G (drop separator detection) both drive the suite to
exit 2 via `only 14/21 tests had a clean-pass assertion`, because the header row starts
being counted on the clean trees.

### F-15 residual [MINOR] `run_suppression_guard` still fails open on `grep` read errors — accepted, with a follow-up

**File:** `scripts/spec-lint/selftest/run-selftests.sh:83` (guard 2) vs `:60` (guard 1);
ordering comment at `:115-121`.

**Judgment: MINOR, not blocking. Accept for this merge with a tracked follow-up.**

The fail-open is real and I reproduced it in isolation (V-7). Given a checker that genuinely
contains `KNOWN_COLLISIONS = {'EC-001'}` — an unambiguous D-039 violation — but is mode
`000`:

```
run_suppression_guard "$dir"
Pre-flight guard passed: 1 checkers scanned, 0 suppression constructs found
rc=0
```

The guard reports a clean scan of a file it could not read. The same file at mode `644`
correctly returns `rc=2`. Cause: `if grep -qE … 2>/dev/null` treats grep's exit 2 (read
error) as "no match", whereas guard 1's `if ! grep -qE …` treats it as "pattern absent" and
fires.

What makes this MINOR rather than blocking is that it is **unreachable through the real
entry point**, and I verified that end-to-end rather than taking the comment's word for it.
Guard 1 is invoked at line 104, guard 2 at line 123. Running the full suite against a tree
with `check-index-integrity.py` at mode `000`:

```
Pre-flight structural guard: checking SPEC_LINT_REPO_OVERRIDE in all checkers...
STRUCTURAL GUARD FAILED: check-index-integrity.py lacks SPEC_LINT_REPO_OVERRIDE support
```

Guard 1 aborts with exit 2 before guard 2 sees the file. So D-039's actual protection —
that the suppression guard cannot be defeated — holds today: *any* checker grep cannot read
terminates the run. The exposure is not "a suppression allowlist can ship undetected"; it is
"a future edit that reorders the guards, inserts a guard between them, or relaxes guard 1's
`!` would silently convert a fail-closed run into a fail-open one," with nothing but a
comment preventing it. G3 covers only the `count -eq 0` branch, not the unreadable-file
branch.

**Suggestion (follow-up, not this PR).** Two lines and one test close it permanently:
capture grep's status explicitly in guard 2 —

```bash
grep -qE "$SUPPRESSION_PATTERN" "$f"; rc=$?
if [[ $rc -eq 0 ]]; then …fire suppression violation…
elif [[ $rc -gt 1 ]]; then echo "STRUCTURAL GUARD FAILED: cannot read $f"; return 2; fi
```

— which makes guard 2 self-sufficient and removes the ordering dependency entirely. Then
add a G4 asserting both guards return non-zero for an unreadable `check-*.py`, so the
property is pinned rather than commented.

---

## NITs

- **N-1** — `check-index-integrity.py:198`: `set(first_cell) <= set("-: ")` is `True` for the
  empty string. Even after B-11 is fixed, an explicit `if not first_cell:` branch would make
  the blank-ID case an intentional, named outcome rather than an accident of subset
  semantics. Note the near-miss pattern *does* correctly handle non-ASCII: `| — | EC-999 |`
  (em-dash) is counted and lands as unaccounted, so only ASCII `-`/`:`/space cells escape.
- **N-2** — `check-index-integrity.py:179`: `raw.strip()` means an indented Markdown code
  block inside `## Authored Scenarios` containing a `|`-prefixed line is now parsed as a
  table row. Over-reporting only, and the correct trade for the B-9 fix — worth one comment
  line so the next reader does not treat it as a bug.
- **N-3** — `check-index-integrity.py:518`: the hardcoded `0 non-conforming` in the success
  line. I checked this rather than assuming: the `print` at `:514-519` is unreachable when
  `violations` is non-empty (`:506-513` returns 1 first), and every near-miss and every
  `MALFORMED` row appends a violation. So the literal is sound. It is still a literal that
  will lie the moment someone adds a non-conforming class that does not append a violation;
  `{len(near_misses) + malformed_count}` costs nothing.

---

## Verification performed

All commands run from `/Users/jmagady/Dev/mdlinkcheck-cloud` at HEAD `031ca5b`. Mutation
sandboxes were `mktemp -d` copies of `scripts/`; the working tree was left untouched
(`git status --porcelain` empty and HEAD unchanged, re-confirmed at the end). No commit,
push, amend, branch, or GitHub write operation was performed.

### V-1 — Direct attack on the accounting invariant (11 probes)

Driver built minimal `.factory` trees and ran the checker under
`SPEC_LINT_REPO_OVERRIDE`. Actual observed output:

```
--- BASELINE clean: exit=0
    Check passed: 14 structural checks — … HS (1 validated, 0 non-conforming, 1 rows seen) all consistent

--- A1 data row ABOVE separator (bogus EC-999): exit=0
    Check passed: 14 structural checks — … HS (1 validated, 0 non-conforming, 1 rows seen) all consistent

--- A2a data row with EMPTY first cell (bogus EC-999): exit=0
    Check passed: 14 structural checks — … HS (1 validated, 0 non-conforming, 1 rows seen) all consistent

--- A2b data row with first cell '-' (bogus EC-999): exit=0
    Check passed: 14 structural checks — … HS (1 validated, 0 non-conforming, 1 rows seen) all consistent

--- A2c row after a stray '|' line (bogus EC-999): exit=1
    HS entry 'HS-042' maps to 'EC-999' — no wave-scenarios file found for this EC ID

--- A3 separator row REMOVED (bogus EC-999): exit=1
    wave-scenarios file for 'EC-156' has no corresponding HS-INDEX entry

--- A4 heading renamed to '## Scenario Table' (bogus EC-999): exit=1
    wave-scenarios file for 'EC-156' has no corresponding HS-INDEX entry

--- A5 NO ## headings, second (Reserved) table present: exit=1
    3 data row(s) seen in Authored Scenarios table but only 1 classified
    (2 row(s) unaccounted for — parser or whitespace-normalisation mismatch)

--- A6 V-9 REPRO: one leading space on rows w/ nonexistent ECs: exit=1
    HS entry 'HS-004' maps to 'EC-165' — no wave-scenarios file found for this EC ID
    HS entry 'HS-005' maps to 'EC-166' — no wave-scenarios file found for this EC ID

--- A7 duplicate canonical HS-ID, differing EC (dict overwrite attack): exit=1
    2 data row(s) seen … but only 1 classified (1 row(s) unaccounted for …)
    HS entry 'HS-001' maps to 'EC-999' — no wave-scenarios file found for this EC ID
    wave-scenarios file for 'EC-156' has no corresponding HS-INDEX entry
    duplicate HS-INDEX entry 'HS-001'

--- A8 two near-miss rows normalising to same id (F-13): exit=1
    HS row with non-canonical ID 'hs-002' — expected 'HS-<digits>' or '~~HS-<digits>~~'
    HS row with non-canonical ID 'hs-002' — expected 'HS-<digits>' or '~~HS-<digits>~~'
```

Reading: **A1/A2a/A2b are false passes → B-11.** A6 is the V-9 leading-space scenario
re-run and now fails closed — **B-9's core fix is genuine.** A8 emits two distinct
violations for two rows normalising to the same ID — **F-13 is genuine.** A5 probes the
`in_authored_scenarios=True` fallback: a heading-less file with a second table fails closed
rather than silently mis-scoping, so **the permissive default is acceptable.** A7 shows the
invariant *does* close the dict-overwrite hole (mapping is keyed, so two rows collapse to one
entry and the count mismatch fires). A3/A4 fail closed via the reverse check.

### V-2 — Full suite at HEAD

```
bash scripts/spec-lint/selftest/run-selftests.sh
```

```
── selftest 10e: check-index-integrity: near-miss HS ID in HS-INDEX ──
  PASS (clean-pass confirmed; near-miss ID 'hs-002' correctly detected)
── selftest 10f: check-index-integrity: accounting invariant (unaccounted rows) ──
  PASS (clean-pass confirmed; unaccounted data row correctly detected by accounting invariant)
── selftest 10g: check-index-integrity: leading-whitespace bypass (B-9 / V-9) ──
  PASS (clean-pass confirmed; leading-space HS rows correctly parsed and forward-checked)
── guard selftest G3: guards fail closed when no check-*.py files found ──
  PASS (clean-pass confirmed; both guards fail closed on empty checker directory)

Selftest passed: 21/21 negative tests verified (each proved clean-pass + defect-fail)
```

Genuinely **21/21**, exit 0.

### V-3 — `EXPECTED_TEST_COUNT` actually gates

Deleted the whole test-10g block from a sandbox copy (3092 chars) and ran the suite:

```
STRUCTURAL GUARD FAILED: expected 21 tests, ran 20
  Update EXPECTED_TEST_COUNT when adding or removing tests.
```

Exit 2. The count is **not** a decorative literal — a deliberately skipped test is caught.
The companion `TESTS_WITH_CLEAN_PASS -ne TESTS_RUN` guard also demonstrably fires (see V-6,
MUT-F/MUT-G: `only 14/21 tests had a clean-pass assertion`, exit 2).

### V-4 — Mutation: B-10's new tests are load-bearing

Each mutation applied to a fresh sandbox copy; suite run in full.

| Mutation | Change | Result |
|----------|--------|--------|
| **MUT-A** | `if hs_rows_seen != …` → `if False and …` | **exit 1**, `Selftest FAILED: 1/21` — flips **10f** only |
| **MUT-B** | `line = raw.strip()` → `line = raw` | **exit 1**, `Selftest FAILED: 1/21` — flips **10g** only |
| **MUT-C** | `for real_id in near_misses:` → `for real_id in []:` | **exit 1**, `Selftest FAILED: 1/21` — flips **10e** only |
| **MUT-H** | forward check `if ec_id not in wave_ec_ids:` → `if False:` | **exit 1**, `Selftest FAILED: 2/21` — flips **10** and **10g** |

MUT-A/B/C each flip exactly the intended new test. **B-10 is genuinely closed** for the
accounting invariant, the `strip()` normalisation, and the near-miss emission path.

### V-5 — Mutation: MUT-D (near-miss capture), per operator ruling

```
=== MUT-D neuter near-miss CAPTURE: exit=0
    Selftest passed: 21/21 negative tests verified
```

Recorded for completeness only; **not raised as a finding** per the binding ruling. I did
confirm the ruling's factual premise independently: the accounting invariant catches the same
row and MUT-C (emission) does flip 10e, so the path is not untested.

### V-6 — Mutation: F-12 scoping and the pre-filters

| Mutation | Change | Result |
|----------|--------|--------|
| **MUT-E** | `in_authored_scenarios = "Authored Scenarios" in line` → `= True` | **21/21 PASS**, exit 0 → **F-18** |
| **MUT-F** | `if not found_separator:` → `if False:` | exit 2, `only 14/21 tests had a clean-pass assertion` |
| **MUT-G** | `if set(first_cell) <= set("-: "):` → `if False:` | exit 2, `only 14/21 tests had a clean-pass assertion` |

MUT-E direction check on the real tree confirms it is a fail-closed mutation, which is why
I downgraded F-18:

```
SPEC_LINT_REPO_OVERRIDE=<repo> python3 /tmp/mutE.py
.factory/holdout-scenarios/HS-INDEX.md: 17 data row(s) seen in Authored Scenarios table
  but only 7 classified (10 row(s) unaccounted for — parser or whitespace-normalisation mismatch)
Check FAILED: 1 index integrity violations found (80 structural checks)
EXIT=1
```

### V-7 — F-15 fail-open: reproduced, then shown unreachable

Guard 2 in isolation, against a checker containing a real `KNOWN_COLLISIONS = {'EC-001'}`:

```
-- guard 2 with file READABLE (should fire, return 2):
STRUCTURAL GUARD FAILED: check-victim.py contains a hardcoded suppression allowlist
  Remove any variable matching: (ALLOWLIST|_DEFERRAL|SKIP_LIST|SKIP_SET|KNOWN_COLLISIONS|…)[[:space:]]*[=:]
rc=2
-- guard 2 with file UNREADABLE (mode 000) — fail-open if rc=0:
Pre-flight guard passed: 1 checkers scanned, 0 suppression constructs found
rc=0
```

Fail-open confirmed. Then the full suite against a sandbox with
`check-index-integrity.py` at mode `000`:

```
Pre-flight structural guard: checking SPEC_LINT_REPO_OVERRIDE in all checkers...
STRUCTURAL GUARD FAILED: check-index-integrity.py lacks SPEC_LINT_REPO_OVERRIDE support
```

Guard 1 (line 104) aborts before guard 2 (line 123) is reached. Also confirmed the
remediation text now interpolates `$SUPPRESSION_PATTERN` (`:87`) from the single definition
at `:48` — **F-14 verified.**

### V-8 — Merge integrity: PR #4 and PR #5 not reverted

```
git diff origin/develop 031ca5b -- .github/workflows/ci.yml         → (empty)
git diff origin/develop 031ca5b -- .github/workflows/hardening.yml  → (empty)
git rev-parse origin/develop                                        → 2776d94e6c02…
git log -1 --format='%H %P' 031ca5b   → 031ca5b  f7cd8bc 2776d94
git diff --stat origin/develop 031ca5b
 .gitignore                                        |    5 +
 scripts/spec-lint/check-ec-injectivity.py         |   13 -
 scripts/spec-lint/check-index-integrity.py        |  236 +++-
 .../selftest/fixtures/bad-adr-exit-code.md        |    3 +-
 scripts/spec-lint/selftest/run-selftests.sh       | 1221 +++++++++++++++++---
```

Both workflow files are **byte-identical** to develop's; merge parents are exactly
`f7cd8bc` + `2776d94`; and the branch-vs-develop diff touches **no workflow files at all**.
The macOS-only `ci.yml` from PR #4 and the version pins in `hardening.yml` from PR #5 are
intact. Merge is clean and reverted nothing.

### V-9 — Real-tree output matches the claim verbatim

```
python3 scripts/spec-lint/check-index-integrity.py
Check passed: 80 structural checks — BC (66 entries), VP (26 entries), ADR, ARCH, L2,
HS (7 validated, 0 non-conforming, 7 rows seen) all consistent
EXIT=0
```

Identical to the claimed string, including all counts.

### V-10 — Regression baseline: same probes against `1fc1bce`

```
git show 1fc1bce:scripts/spec-lint/check-index-integrity.py > /tmp/old-checker.py

--- A1 row above separator [OLD]: exit=1
    HS entry 'HS-042' maps to 'EC-999' — no wave-scenarios file found for this EC ID
--- A2a empty first cell [OLD]: exit=0
--- A2b dash first cell [OLD]: exit=0
```

This is what establishes A1 as a **regression** rather than a pre-existing gap, and confines
A2a/A2b to pre-existing status.

### V-11 — PR metadata and description

```
gh pr view 3 → baseRefName=develop  headRefName=feature/spec-lint-hardening
               mergeable=MERGEABLE  mergeStateStatus=UNSTABLE
gh pr view 3 --json comments -q '.comments[].body' | grep -c "21/21"  → 0
```

Body contains `17` selftest references throughout and names `get_hs_ec_mapping()`. → **F-17.**

### Working tree left as found

```
git status --porcelain   → (empty)
git rev-parse HEAD       → 031ca5b04279c83355b8b0e956ab238e6ba1d485
```

CI was not re-run or re-triggered; nothing was posted to GitHub.

---

## Review checklist

| # | Item | Result |
|---|------|--------|
| 1 | Diff coherence | **PASS** — delta touches only the two spec-lint files plus the develop merge; every hunk traces to B-9/B-10/F-12..F-16 |
| 2 | Description accuracy | **FAIL** — F-17: body describes 17 tests and a renamed function |
| 3 | Test coverage | **PARTIAL** — 21/21 with MUT-A/B/C each flipping exactly one new test (strong); F-12 scoping uncovered (F-18); B-11's false-pass class uncovered |
| 4 | Demo evidence | **N/A** — CI-tooling change with no user-visible surface; the selftest transcript and real-tree output are the appropriate evidence and both were reproduced |
| 5 | Commit quality | **PASS** — conventional format, finding IDs in subjects, merge commit clearly labelled |
| 6 | Diff size | **PASS** for the delta (462 lines); the cumulative branch diff is ~1263 lines but is dominated by mechanical per-test fixture blocks |
| 7 | Missing changes | **FAIL** — B-9's stated goal ("any row that defeats the parser is reported rather than silently dropped") is not achieved; B-11 |
| 8 | Dependency status | **PASS** — PR #4 and PR #5 merged into develop and present at HEAD (V-8) |

### Governance

- **D-039** — Upheld. No allowlist, skip-list, or suppression set anywhere in the delta; the
  pre-flight suppression guard passes over all checkers; F-14 removes the drift-prone echo.
  F-15's fail-open does not defeat it today (V-7).
- **D-040** — Satisfied for B-9's `strip()` fix, the accounting invariant, the near-miss
  emission path, and both guards' fail-closed branches (V-4, V-2). Not satisfied for the
  F-12 scoping (F-18) or for B-11's pre-filter-skip class.
- **D-057** — The runtime positive-coverage count is emitted (`7 validated … 7 rows seen`) and
  `EXPECTED_TEST_COUNT` genuinely gates (V-3). Mutation verification was treated as
  necessary-not-sufficient: B-11 was found by direct input construction, not by mutation —
  every mutation in V-4 passed cleanly on the very code path that carries the false pass.
- **BI-023** — **Third variant found.** B-9 was literal `^\|` anchor matching; B-11 is
  positional matching (row position relative to the separator) plus silent skip of
  blank/punctuation-only ID cells, with the fail-closed counter sharing the classifier's
  pre-filters exactly as the old guard shared its regex anchor.

---

## Summary

The three fixes I could attack hardest all hold up. B-9's `strip()` normalisation genuinely
closes the V-9 leading-space bypass (A6, MUT-B). B-10 is genuinely closed: 21/21, the count
actually gates, and MUT-A/MUT-B/MUT-C each flip exactly one of the new tests. F-13 and F-14
are verified. The develop merge is clean and reverted nothing from PR #4 or PR #5. The
real-tree output matches the claim verbatim. F-15's residual is real but unreachable through
the real entry point, and I am comfortable calling it MINOR rather than blocking.

One blocking finding. The accounting invariant that replaced the `len(hs_mapping) == 0`
guard increments its denominator at line 211, *after* five `continue` pre-filters — so it is
independent of the four parser regexes but shares every pre-filter with them. Rows the
pre-filters skip are invisible to the invariant, and `hs_rows_seen == hs_canonical +
hs_nonconforming` holds vacuously. Three reachable inputs put a bogus `HS-042 → EC-999`
(no wave-scenarios file) past the checker at exit 0, and one of them — a row positioned above
the table separator — was correctly reported at `1fc1bce`. The F-12 scoping fix closed an
over-matching hole and opened an under-matching one, which is the same fix-introduces-defect
pattern this PR has now hit five times, and it is BI-023's third variant.

The fix is small and local: count every `|`-prefixed line in scope and account for each into
exactly one bucket (header / separator / canonical / malformed / near-miss), asserting zero
unaccounted, so the denominator is genuinely independent of both the regexes and the
pre-filters. The docstring at `:142-147` and the comment at `:450-452` need to be corrected
to match whatever guarantee the code actually provides. Add the one selftest that fails today
(`|  | EC-999 | … |` → expect non-zero), the F-18 clean-pass test to pin F-12, and refresh
the PR body to 21/21 in the same push.
