# PR Review — Cycle 4 (fresh, formally recorded)

**VERDICT: REQUEST_CHANGES** (1 blocking finding)

**Reviewed head:** `72db5580a98d8f8b2cf4326a83b6a7f0fc55441e` (`72db558`)
**Base:** `develop` @ `da86271`
**Branch:** `fix/checker-completeness-gate35`
**Diff:** 9 files, +2040 −232
**Reviewed:** 2026-08-09

> Posted as a `gh pr comment` verdict, not a `gh pr review` event. The authenticated identity
> (`drbothen`) is this PR's author and GitHub structurally forbids `--approve` /
> `--request-changes` on one's own PR (BI-039 / D-021 / D-105). The verdict line above is the
> review verdict; treat it as REQUEST_CHANGES for gating purposes.

## Why this cycle exists

Head `72db558` postdated the last recorded verdict (cycle 2, `REQUEST_CHANGES`,
2026-08-09T03:07:02Z) with no subsequent recorded verdict, and the audit file still carried the
cycle-1 verdict. Five recorded blocking findings had no recorded resolution. This cycle
adjudicates each one against the code at `72db558`, by execution rather than by inspection.

## Method

Every "reportedly fixed" claim was treated as unverified. I re-derived each result myself:

- Full selftest suite run at head: **99/99**.
- Unmutated `check-adr-consistency` run on the live corpus.
- The cycle-2 tautology mutant re-injected **out of tree** (checker copied to `/tmp`,
  `SPEC_LINT_REPO_OVERRIDE` pointed back at the real corpus) so the working tree was never dirtied.
- A **counter-factual** run of the same mutant against the `fd74bd7` (pre-fix) checker, to prove
  the new gate is load-bearing rather than incidentally correct.
- `check_adr()` extracted via `ast.get_source_segment` at both `da86271` and `72db558` and diffed.
- A hermetic ADR fixture built under `/tmp` to count violations for a single reason-code defect,
  run against both the head and `fd74bd7` checkers.
- **Three independent canary-defeat attempts**, each run against both the arithmetic gate and the
  full 99-test suite.
- Two mutants applied in-place with a guaranteed restore; `git status --short` verified empty after
  each. `.factory/specs/` was never touched. The tree is clean.

---

## Adjudication of the five prior blocking findings

### Cycle 1, BLOCKING-1 — vacuous EI-4 skip assertion → **RESOLVED**

The zero-skip branch no longer emits a string the positive assertion can match.

- `check-ec-injectivity.py:672-674` emits `"no TV rows skipped"` in the zero case (the ternary's
  `else` arm), not `"0 TV rows skipped"`.
- `run-selftests.sh:4958` asserts `grep -qE "[1-9][0-9]* TV rows skipped"`, which is lexically
  disjoint from that message.
- I confirmed `"0 TV rows skipped"` is **unreachable**, not merely avoided:
  `total_tv_skipped = total_tv_skipped_col + total_tv_skipped_no_ec` (line 658), and both
  `skip_detail_parts` appends are guarded on those same two counters — so a non-empty detail list
  implies `total_tv_skipped >= 1`. There is no input that produces a zero count with a detail
  parenthetical.
- **Mutation kill confirmed.** I re-ran the exact mutation that survived in cycle 1 — adding
  `"expected exit"` to `_COMPARABLE_KEYWORDS` — in-place at head. Result: suite exit 2 with
  `STRUCTURAL FAIL: coverage line does not report positive skip count (schema-aware extraction not
  working; expected '[1-9][0-9]* TV rows skipped')`. In cycle 1 this same mutation left the suite
  93/93 green. The mutation now dies. Tree restored.

### Cycle 1, BLOCKING-2 — `"link"` in `_COMPARABLE_KEYWORDS` → **RESOLVED**

`"link"` is absent at head. `check-ec-injectivity.py:216-219` reads:

```python
_COMPARABLE_KEYWORDS = [
    "description", "input", "source md content", "scenario",
    "filesystem", "heading", "mock server",
]
```

Live corpus at head: **174 EC citations compared, 42 divergent, 22 require adjudication.** That is
exactly the `"link"`-reverted row from the cycle-1 review's own table (174 / 42 / 22) rather than
the as-written row (174 / 40 / 11) — confirming the claim that row coverage is unchanged at 174
while the suppressed findings across the 11 EC IDs are restored. Widening is the intended direction
under D-122.

### Cycle 2, BLOCKING-1 — E-class reconciliation was a tautology → **RESOLVED** (strongest result)

The `assert x == x` is gone. `check-adr-consistency.py:698-711` now computes `e_population` from an
**independent** probe — its own file iteration (`_in_spec_corpus`, not
`should_check_for_broad_p19`), its own line iteration (no routing or `continue` logic), and a
deliberately wider regex (`E_CLASS_CANARY_RE = (?<![A-Za-z0-9])E-[A-Z]+-\d+`, no `{2,4}` namespace
cap and no `{3}` digit cap) — then compares it against the parts with `print(...) + return 2`, not
`assert`. The `python -O` stripping concern is therefore also addressed.

**I re-ran the mandated mutation proof independently.** Inserting

```python
if slp.split_table_cells(line):
    continue
```

immediately before `seen_e_codes_this_line: set[str] = set()` in the Pattern 4 block yields exactly
the predicted failure:

```
ERROR: E-class accounting gap — population=8 != examined=3 + skipped=2; an E-class occurrence is being dropped by an undeclared routing path
EXIT=2
```

**Counter-factual (this is what makes the fix credible).** I applied the identical mutant to the
`fd74bd7` checker — the tautology version — against the same live corpus:

| | exit | ledger | E-class detections |
|---|---|---|---|
| `fd74bd7` + mutant (tautology) | **1** | closed silently, no gap message | **3** (halved from 6) |
| `72db558` + mutant (canary) | **2** | `population=8 != examined=3 + skipped=2` | gate fires before reporting |

So the mutant that previously halved live detections while the ledger closed and every selftest
passed is now caught. The gate is load-bearing, not decorative. Baseline unmutated at head:
`E-class population: population=8, examined=6, skipped=2 (frontmatter, D-081)`.

### Cycle 2, BLOCKING-2 — ADR reason-code violations double-reported → **RESOLVED**

`e_class_only` is plumbed (`check-adr-consistency.py:288`, guard at `383`, ADR call site at
`640-641`), so Patterns 1-3 no longer run on the ADR path. Verified on a hermetic fixture — one ADR
with a single phantom reason code in a Reason column:

| checker | `grep -c "not in closed taxonomy"` | reported |
|---|---|---|
| `fd74bd7` (pre-fix) | **2** | `2 violations found` |
| `72db558` (head) | **1** | `1 violations found` |

One defect, exactly one violation entry.

**No POLICY 12 ADR check was lost.** I extracted `check_adr()` via `ast.get_source_segment` at both
`da86271` and `72db558` and diffed the source segments: **byte-identical**, 37 lines at both
revisions. The named gap is disclosed rather than hidden — the checker prints
`ADR reason-code occurrences: 0 counted toward reason-code total (8 ADR files; Patterns 1-3 not
applied — deliberate named gap, avoids check_adr() overlap)`.

### Cycle 2, BLOCKING-3 — stale evidence bundle and PR body → **NOT RESOLVED**

This finding had two halves. The substantive half is fixed; the record half has recurred, and for
the PR body it was never addressed at all.

**Resolved — the headline deliverable now has evidence.** `AC-007-eclass-population-gate.txt`
exercises the reconciliation *and* its fail case, which is precisely what cycle 2 said no artifact
did. I re-ran both and they reproduce exactly at head: the unmutated line
`population=8, examined=6, skipped=2` and the mutant line
`population=8 != examined=3 + skipped=2 ... Exit code: 2`. `AC-005` and `AC-006` also match fresh
head runs line-for-line (9 violations / 78 reason-code + 6 E-class; 174 compared / 42 divergent /
22 adjudication).

**Not resolved — see BLOCKING-A below.** `ca8c1c0` refreshed `evidence-report.md` only. The PR body
was never updated by any commit, and `72db558` then re-staled the evidence bundle.

---

## BLOCKING-A (new / recurrence of C2-BLOCKING-3) — the PR body is stale by six commits and materially false at head

**Severity:** blocking · **Category:** description accuracy (checklist item 2)

The PR body still describes `d3085d9`, six commits behind head. It is not merely out of date — its
quantitative claims are wrong, it cites an evidence file that does not exist, and its documented
rollback procedure does not work. Because the entire reason this review cycle exists is record
integrity, and because this is a recurrence of an already-blocked finding, it blocks.

| PR body claim | Actual at `72db558` |
|---|---|
| `**Head SHA:** d3085d9` | `72db558` (6 commits later) |
| selftests badge `93/93`; `AC-2 ... 93/93 pass` | **99/99** |
| cites `docs/.../AC-002-selftest-93of93.txt` | **file does not exist** (bundle has `AC-002-selftest-98of98.txt`) |
| `9 violations (79 reason-code + 5 E-class occ)` | **78 reason-code + 6 E-class** |
| `AC-5 ... 9 violations (4 reason-code + 5 E-class)` | **78 + 6** — and internally contradicts the line above it |
| `40 DIVERGENT + 11 ADJUDICATION` | **42 divergent + 22 adjudication** |
| `New selftests this PR: 2 (5k, EI-7)` | **8** (5k, 5l, 5m, 5n, 5o, 5o-b, 5p, EI-7) |
| `BI-056 ... 5 new E-class detections` | **6** |
| rollback: `git revert d3085d9 2349184` | leaves `1dd7721`, `fd74bd7`, `b4bbbc3`, `ca8c1c0`, `72db558` in place — procedure is wrong |

The body also never mentions the cycle-2 headline deliverable (the independent E-class canary /
population reconciliation) or the `e_class_only` ADR change, so a reader of the PR page cannot tell
that the two most significant changes in the diff exist.

**Residual, same class, lower magnitude — the evidence bundle re-staled at `72db558`:**

- `evidence-report.md` header: `**Head SHA:** b4bbbc3`; summary table rows AC-1 and AC-2 claim
  `98/98`, false at head (99/99).
- `AC-002-selftest-98of98.txt` contains `Selftest passed: 98/98`; the filename itself asserts a
  stale count.
- No artifact anywhere in the bundle references `72db558`, `5o-b`, `NIT-1`, or `99/99` — the NIT-1
  behavioural change to the frontmatter bucket has no evidence coverage.

**Suggested fix (no source change required):** update the PR body to head `72db558` with the eight
corrected figures above and a working rollback range; re-run and recapture `AC-001`/`AC-002` at
head (renaming to `AC-002-selftest-99of99.txt`); bump `evidence-report.md` to `72db558` / 99/99 and
add a line covering `5o-b`.

---

## Canary-defeat probe — three attempts, all killed by the suite

Cycle 2's standard was that a mutant must survive both the gate and the new selftests. I tried to
construct a change that loses real coverage while the gate still closes.

| Attempt | Gate result | Live coverage | Suite result |
|---|---|---|---|
| **A** — route table lines into the skip bucket as a "declared skip" (one-place, plausible refactor a developer would write to silence the gate) | **closes**, `8 = 3 + 5`, exit 1 | 6 → **3** detections lost | **KILLED** by 5l (`E-class code in ADR table cell not detected`) |
| **B** — narrow `E_CLASS_CANARY_RE` back to detector width (NIT-2 Path 2) | **closes**, ledger identical to unmutated (`8, 6, 2`) | unchanged today | **KILLED** by 5o + 5o-b (4 failing assertions) |
| **C** — coordinated two-place file-scope narrowing (exclude `prd-supplements` from *both* `should_check_for_broad_p19` and `_in_spec_corpus`, so the scope-gap gate closes too) | **closes**, `7 = 5 + 2` | 6 → **5** detections lost | **KILLED** by 9 failing assertions |

I could not construct a change that loses real coverage while the gate closes **and** the suite
passes. That is a materially stronger posture than cycle 2, where a single-place mutant survived the
gate and all four new selftests. Attempt B is the notable positive result: it confirms the wide
canary regex is genuinely load-bearing and genuinely pinned by a test, which is what NIT-2 asked
for.

---

## SUGGESTION-1 — the gate pins the sum, not the split

`check-adr-consistency.py:705` asserts only
`population == examined + frontmatter_e_skipped`. It does not constrain how occurrences are
*distributed* between those buckets. Any change that reroutes occurrences out of `examined` and
into the skip bucket keeps the ledger closed while losing detections — and worse, the disclosure
line then **mislabels** the loss, since it is hard-coded as
`skipped={n} (frontmatter, D-081)` regardless of why the occurrence was skipped. Attempt A above is
exactly this shape: it reported `skipped=5 (frontmatter, D-081)` when only 2 were actually in
frontmatter.

Today the selftests (5l, 5m) are what prevent this, not the gate. Consider a second invariant
pinning `frontmatter_e_skipped` to occurrences on lines the frontmatter predicate actually matched
(e.g. accumulate the skip bucket with its provenance and assert the provenance set is
`{"frontmatter"}`), so the disclosure cannot silently become a dumping ground. Not blocking —
the realistic instances die in the suite — but it would move this from test-enforced to
gate-enforced.

---

## Suite-wide sweep for the cycle-1 BLOCKING-1 defect class — **CLEAN**

I swept all 6583 lines of `run-selftests.sh` for any remaining assertion that greps a substring the
producing checker's zero/empty-result message also satisfies.

**Result: zero remaining instances.** The `TV rows skipped` archetype was the only one, and it is
fixed. Coverage: 52 `grep` invocations, of which 40 are checker-output substring assertions (the
in-scope population, spanning 32 of the 99 tests); the other 12 are pre-flight meta-guards that scan
checker *source* (no zero-result message) or `grep -qx` exact-line membership tests. The remaining
67 tests assert exit codes only. I also swept for non-`grep` substring assertions (`[[ == *glob* ]]`,
`=~`, `case`, `wc -l`, `test -n/-z`) — none exist.

The five count-shaped assertions were each traced to their producing format string and their zero
case probed empirically in hermetic trees:

| Line | Test | Pattern | Zero-case output | Matched? |
|---|---|---|---|---|
| 4866 | EI-3 | `"1 require adjudication"` | `0 require adjudication` | no |
| 6522 | EI-7 | `"1 EC citation"` | `0 EC citations compared` | no |
| 5667 | 5j | `"[1-9][0-9]* reason-code occurrences"` | `0 reason-code occurrences` | no |
| 5936 / 6231 | 5m / 5o-b | `"skipped=1"` | `skipped=0` | no |
| 6322 | 5p | `grep -c ... -ne 1` | count `0` | exact-count compare |

I specifically checked and cleared the two nearest structural analogues: the
`"[filled by architect]"` greps (`check-placeholders.py:495` prints a literal `[filled by]` in its
*pass* message, but it is not a superstring of the role-qualified forms), and the unconditional
`Closed reason code set (...)` / `Active holdout pool: [...]` lines — no test greps for a token
present in its own fixture's taxonomy or pool.

## NIT-A — count assertions match any count *ending* in 1

`run-selftests.sh:4866`, `6522`, `5936`, `6231`. `grep -q "1 require adjudication"` also matches
`11 require adjudication`; `grep -q "skipped=1"` also matches `skipped=11` (both confirmed by
probe). These assert "a count ending in 1" rather than "exactly 1" or ">= 1". They are **not** in the
cycle-1 defect class — the zero case still cannot satisfy them, so they are falsifiable — but
tightening to `grep -qE "\b1 EC citation"` / `"skipped=1$"` would match the hardening already
applied at line 4958.

## NIT-B — EI-5's mutation-verify comment names a kill mechanism that does not exist

`run-selftests.sh:6340-6344` claims that reverting the synonym set makes EI-5 die because
"STRUCTURAL FAIL fires because the coverage line shows `0 EC citations compared`". EI-5's clean-pass
block (`6369-6377`) asserts the **exit code only** — there is no coverage-line grep anywhere in the
test.

I verified the substance rather than assuming: reverting `_COMPARABLE_KEYWORDS` to `["description"]`
does kill EI-5, but via its *defect* assertion
(`FAIL (checker returned 0 — Input column rows not being compared; synonym set too narrow)`), not via
the STRUCTURAL FAIL the comment describes. **The test is sound; only its comment is wrong.** Worth
correcting because an inaccurate mutation-kill claim is precisely what cycle-1 BLOCKING-1 was about —
a future reader trusting this comment would believe a coverage assertion is protecting them when it
is not.

## NIT adjudication

- **NIT-1 (canary/bucket asymmetry) — RESOLVED.** `E_CLASS_CANARY_RE` lifted to module level
  (`check-adr-consistency.py:86`); the frontmatter bucket now uses
  `set(E_CLASS_CANARY_RE.findall(line))` (lines 375-377) — same regex and same per-line dedup as the
  probe in `main()` (line 703). Both false-alarm directions the NIT described are closed. New test
  5o-b pins it, and I confirmed the reverting mutant (attempt B) kills 5o-b's `skipped=1` assertion.
- **NIT-2 (5o mutation comment incomplete) — RESOLVED.** `run-selftests.sh:6070-6078` now documents
  both mutation paths explicitly (`Path 1 —` / `Path 2 —`). Verified empirically: Path 2 is a real
  path — narrowing the canary leaves the live ledger looking perfectly normal yet kills four
  assertions.

## Verified correct (not rubber-stamped)

- Selftests **99/99** at head; `EXPECTED_TEST_COUNT` bumped to 99 in step with the new test.
- All four required CI checks pass at `72db558`: `Build release (macos-latest)`,
  `Clippy (deny warnings)`, `Format check`, `Test (macos-latest)`.
- `Spec lint` FAILURE is correct and intended — advisory-only, not a required check (D-128). It
  reports real content violations these repairs newly expose. Counts widened as designed
  (`check-adr-consistency` 4 → 9; `check-ec-injectivity` 9 → 42 divergent, 5 → 22 adjudication),
  which is the expected direction under D-122.
- No detection regression: the E-class detection set is a strict superset of base, and
  `check_adr()` is byte-identical, so nothing POLICY 12 was traded away for the POLICY 19 gain.
- Diff coherence: all 9 changed files are in `scripts/spec-lint/` or the story's evidence
  directory. No unrelated changes, no `.factory/specs/` modification, no operator-authorization
  field touched.
- Commit quality: conventional format with story/finding IDs throughout
  (`fix(gate35/cycle2): ...`, `fix(gate35/nit1+nit2): ...`).
- Diff size 2040/232 exceeds the 500-line flag threshold, but ~900 lines are selftest fixtures and
  ~600 are evidence text; the checker changes are ~840 lines across two files. Acceptable for a
  test-integrity repair.
- Working tree clean after all mutation work; every mutant either ran out-of-tree or was restored
  and verified.

## Bottom line

The engineering in this PR is sound and the two cycle-2 blocking findings that mattered most —
the tautology and the double-count — are genuinely and verifiably fixed. I reproduced the
tautology mutation proof independently, and the counter-factual against `fd74bd7` shows the new
gate catches what the old one missed. Four of five prior blocking findings are RESOLVED.

What blocks is the record, not the code. The PR body describes a commit from six commits ago,
states eight figures that are wrong at head, cites an evidence file that does not exist, and gives
a rollback command that would not roll the change back. That is the same finding cycle 2 raised,
and it is the exact failure mode — an artifact that disagrees with reality — that this whole review
cycle was convened to correct. Fixing it requires no source change.
