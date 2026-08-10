# PR #13 — Fresh-eyes review, CYCLE 3 (gate-#28 v3)

**covered_sha:** `eae146a1536fd093aa74bfb28cc9b29903728d58`
**PR:** #13 — `feat(GATE42-step0): harden verify-evidence-figures.py before nine-checker sweep`
**Branch:** `fix/verifier-hardening-sweep-step0` (28 commits ahead of `develop` @ `2ac2c3e`)
**Reviewer mode:** read-only on the repository under review; this audit file is the only write.
**Prior cycles:** `pr-review-cycle1.md` (REQUEST_CHANGES, B-1..B-5 — all closed),
`pr-review-cycle2.md` (REQUEST_CHANGES, B2-1..B2-5 + S2-1..S2-5 + N2-1..N2-2).
**Bar applied:** D-214 — GOOD ENOUGH, including for the verifier itself. The decisive
question for every finding is *could this cause a green that cannot be trusted?*

---

## VERDICT

**REQUEST_CHANGES** for head `eae146a`.

Not because the verifier is imperfect — D-214 forbids that standard — but because I
**realized a false green on the real documents at this head**: a one-line edit to
`evidence-report.md` makes the verifier report `PASS` while the document states
`99 divergent` and `99 adjudication` against live values of `42` and `22`
(§2 M-1, probe E). That is a genuine false-green risk, which is the operator's own
stated sole trigger for REQUEST_CHANGES.

**Is this verifier honest enough to be the oracle for adversary pass 8?**
**Its results are; its self-description is not.** Every comparison it *performs* is
sound, non-circular, and independently reproducible — I re-derived all of them three
ways. But three shipped comments assert structural guarantees that I falsified with
working probes this cycle, and its own test suite's `48/48 — each proved clean-pass +
defect-fail` banner is false for at least four tests. Pass 8 can use this verifier
**only if it reads the log body and treats `N occurrence(s) compared` as the literal
scope** — never the docstrings, and never the CI status (§3 A-1).

The minimum change that makes it honest is text plus ~30 lines of assertion
(M-2/M-3/M-4). Full closure of M-1 needs an inversion and may be deferred **if** the
scope statement is corrected to match.

---

## 0. MANDATORY FIRST ACT — THE BINDING PROBE (doc_value residual)

**Question:** does `record_comparison(key, doc_value=<dummy non-None>)`, having compared
nothing, satisfy the required-check gate? B2-2 asserted this is structurally impossible.

**Answer: the gate is fully satisfied. The B2-2 class is NARROWED, not closed.**

### Probe A — direct unit probe (`/tmp/vef-probe/probeA.py`)

Extracts the **real** `REQUIRED_CHECKS` block and the **real** `record_comparison`
definition out of `scripts/verify-evidence-figures.py` by source slicing and `exec`
(nothing retyped, no copy that could drift), then calls it having read no document,
run no checker, and compared nothing:

```python
rc_block = src[src.index("REQUIRED_CHECKS = {"):src.index("checks_skipped: set")]
fn       = src[src.index("def record_comparison("):src.index("def _is_auth_error(")]
exec(rc_block + "\nchecks_skipped=set()\n" + fn, ns)
for v in ([], {}, "", 0, False, re.match("x","x"), object()):
    record_comparison("check2-adr-figures", doc_value=v)   # compared NOTHING
for k in REQUIRED_CHECKS:
    record_comparison(k, doc_value=[])
print(REQUIRED_CHECKS - checks_ran - checks_skipped)
```

Result — **every** dummy registers; only literal `None` is rejected:

```
REGISTERED  doc_value=[]      (the exact shape produced by list(pat.finditer(doc)) with 0 hits)
REGISTERED  doc_value={}
REGISTERED  doc_value=''      (the shape produced by .stdout.strip() of nothing)
REGISTERED  doc_value=0
REGISTERED  doc_value=False
REGISTERED  doc_value=<re.Match>     (what check9 actually passes)
REGISTERED  doc_value=object()

GATE: missing_checks = set()
GATE SATISFIED: True (all 11 keys registered having compared nothing)
```

### Probe B — end-to-end on the production code path (`probeB.py`, `probeB3.py`)

Unmodified-behaviour copy of the verifier (one observability `print` of `checks_ran`
added, nothing else), driven through the project's own `TestEnv` fixtures in a tmpdir.

**B2.** With the rc/ec restatement absent from both documents, `rc_matches == []`, so
`check2-adr-figures` **compares nothing** — yet line 643 calls
`record_comparison("check2-adr-figures", doc_value=rc_matches)` *outside* the
`if not rc_matches:` branch:

```
PROBE/checks_ran=[... 'check2-adr-figures' ...]   <- registered having compared nothing
```

This is live, shipped, production-path behaviour at `eae146a`, at **two** sites:
`:643` (`check2`, `doc_value=rc_matches`) and `:756` (`check3`,
`doc_value=ledger_matches`).

**B3.** The "future check" the docstring promises the API constrains — look for a token,
find nothing, register the empty result, with no hand-written `if not matches: fail()`
— injected before the gate:

```
PROBE/check10 compared=[]  (zero comparisons performed)
PROBE/missing=[]
PASS — all figure checks match live output and git state
   -> rc=0    GREEN with a zero-comparison required check: True
```

### Verdict on B2-2

| Claim (`:63-69`, `:233-240`) | Reality |
|---|---|
| "a call site that passes `doc_value=None` raises AssertionError" | **TRUE** |
| "A check that found nothing in the document cannot produce a non-None `doc_value`, so it cannot reach a registered state" | **FALSE** — `[]`, `""`, `{}`, `0`, `False` all register |
| "The class is closed by the API signature, not by per-site audit — every current site AND every future site is constrained without anyone having to remember" | **FALSE** — the class is closed at `eae146a` *only* by hand-written `fail()` calls at every site, i.e. exactly by per-site audit |

**Why this is not a false green today:** I traced all eleven `record_comparison` call
sites. Every path that can reach a falsy `doc_value` also records a `fail()` on the same
path (`:626` `adr-consistency/pr-claim`, `:737` `e-class-ledger/pr-claim`, `:832-840`
the three `ec-injectivity/*-found` fails, `:1143` `ac002-suffix-uncited`, and so on).
The exit code is honest. **The guarantee is not.** The API contributes nothing beyond
rejecting literal `None`, and the docstring tells the next author the backstop is
unnecessary. That is round six (§2 M-4a).

Two further observations from the same trace, recorded for accuracy: `check1` (`:596`,
`doc_value=live_st`), `check4` (`:873`, `doc_value=eim`) and `check6` (`:1013`,
`doc_value=live_e_sites`) pass **live-derived** values as `doc_value`. Those are non-None
regardless of what any document contains, so for three of eleven keys `doc_value` carries
zero information about whether a document lookup succeeded — the parameter's stated
contract ("MUST be the actual value … retrieved from the document") is violated on the
production path.

---

## 1. MANDATORY — CI LOG BODY CONFIRMATION (not status)

Read via `gh run view 31365193619 --log`. **Confirmed, and it is the re-run.**

```
{"id":31365193619, "head":"eae146a1536fd093aa74bfb28cc9b29903728d58",
 "event":"pull_request", "attempt":2, "conclusion":"failure",
 "created":"2026-08-10T07:16:23Z", "updated":"2026-08-10T07:26:37Z"}
```

`attempt: 2` settles the L-71 ordering-race question — attempt 1 REFUSED with
`no pr-description.md found` because `factory-artifacts` was pushed after the run
started. **I am reading attempt 2**, whose `Verify evidence figures` step log body is:

```
branch 'develop' set up to track 'origin/develop'.
Running selftest suite (~65 s) …
Running check-adr-consistency …
Running check-ec-injectivity …
    adr-consistency figures: 8 occurrence(s) compared
    e-class-ledger triple: 4 occurrence(s) compared
    ec-injectivity citations-compared: 14 occurrence(s) validated
    ec-injectivity divergent:          15 occurrence(s) validated
    ec-injectivity adjudication:       14 occurrence(s) validated
Fetching live PR body via gh …
CHECK 8 SKIP — gh API authentication not available.
  (gh said: gh: To use GitHub CLI in a GitHub Actions workflow, set the GH_TOKEN …)
PARTIAL — 1 check(s) skipped (not a full pass):
  SKIP  check8-live-pr-body — gh API authentication not available
verify-evidence-figures: PARTIAL — some checks skipped, not a full pass (exit 5)
##[error]Process completed with exit code 1.
```

**CONFIRMED — the verifier reached real comparisons in CI.** The orchestrator's figures
match the log body exactly. This is a genuine, decisive advance over cycle-2, where the
same step printed `REFUSED — no open pull request found` and verified nothing while
reporting `success`.

**Corroboration.** My local end-to-end run at `eae146a` produced the identical
comparison counts — `8 / 4 / 14 / 15 / 14` — and **exit 0** with
`PASS — all figure checks match live output and git state`. Locally `gh` is
authenticated, so `check8-live-pr-body` **ran and passed**: the live PR body on GitHub
matches `pr-description.md`. CI and local differ in exactly one check, exactly as
documented.

**Is exit 5 / PARTIAL the honest classification, or does it mask something?**
**Honest.** I verified the classification is not hiding a failure, by three independent
routes:

1. Only `check8-live-pr-body` is in `checks_skipped`; the gate at `:1347` subtracts it,
   and `fails` is empty — otherwise exit would be 1, which the wrapper maps to FAIL.
2. `check7-provenance-stamps` is **not** skipped in CI (`_TEST_MODE` is False), so CI ran
   `git show ebb1a78:<path>` against real git objects for all five `STAMPED` artifacts and
   they matched. Therefore `_verified_stamp_sha` was populated and **check9's
   stamp-equality assertion was enforced in CI and passed** — the B2-4 closure is
   confirmed by the CI log, not by code reading.
3. The `99/99` figure is derived in CI from a live `run-selftests.sh` run (`check1` passed,
   which requires the live line, the PR badge and the evidence heading to agree).

The job conclusion is `failure` solely because the wrapper maps exit 5 → `exit 1`. That
is the correct, honest choice. Its unavoidable consequence is §3 A-1.

---

## 2. COUNTED SEVERITY TABLE — un-adjudicated MUST-FIX findings only

**MUST-FIX count: 5** (exact integer, PG-012).

| # | Severity | Category | Finding | Evidence |
|---|---|---|---|---|
| **M-1** | **must-fix (high)** | false-green / soundness | **Round seven. A wrong figure written in ordinary prose ships green — realized on the real documents at `eae146a`.** | probe C, D, **E** |
| **M-2** | **must-fix (high–mid)** | false-green / filter integrity | **The historical-value filters are validated by counting, not by content. Over-stripping is false-green, and one routine document edit triggers it.** | Cases A, G (+ latent B, E, F2) |
| **M-3** | **must-fix (mid)** | test-integrity / false-green | **`48/48 — each proved clean-pass + defect-fail` is false. Three verifier mutants survive the full suite.** | mutants M5, M18, M21 |
| **M-4** | **must-fix (mid)** | honesty / D-180 lineage | **Three shipped structural-guarantee comments are false; all three were falsified by probe this cycle, and cycle-2 explicitly prescribed removing exactly this language.** | probes A, B3; T45; Case F2 |
| **M-5** | **must-fix (low–mid)** | ci-wiring / observability | **The `test-vef.py` step sits inside `Spec lint`, whose conclusion is already `failure` by D-128 design, so a real verifier-suite regression is unobservable at check-status level — the identical L-66 defect D-212 exists to fix, left half-applied.** | `gh pr checks 13` |

### M-1 — Novel-prose wrong figures ship green (REALIZED, real documents)

The code asserts (`:922-924`): *"a wrong figure adjacent to a metric context word cannot
silently pass — it is unrepresentable as 'correct'."* **False.**

**Probe C** appended one line of wrong-figure prose to the project's own clean fixture
(live `rc=78 ec=6 cmp=174 div=42 adj=22`; injected value `99`). **9 of 10 novel shapes
passed clean; 4 of 4 controls were caught** — so the probe discriminates:

```
R6-1  "Divergent findings totalled 99 in this run."               exit 0  SURVIVED
R6-2  "divergences, all told, numbered 99."                       exit 0  SURVIVED
R6-3  "The number of divergent rows stands at 99."                exit 0  SURVIVED
R6-4  "Adjudication requirements came to 99 rows."                exit 0  SURVIVED
R6-5  "99 citations were reviewed against the ledger."            exit 0  SURVIVED
R6-6  "Citation comparison count: 99."                            exit 0  SURVIVED
R6-8  "99 E-class detections were recorded."                      exit 0  SURVIVED
R6-9  "a 99-divergent outcome was observed."                      exit 0  SURVIVED
R6-10 "divergent -> 99"                                           exit 0  SURVIVED
R6-7  "99 reason-code hits were recorded."                         exit 1  CAUGHT
CTRL-A "99 divergent rows were seen."                              exit 1  CAUGHT
CTRL-B "divergent count came to 99."                               exit 1  CAUGHT
CTRL-C "99 citations examined here."                               exit 1  CAUGHT
CTRL-D "99 reason-code occurrences were observed."                 exit 1  CAUGHT
```

**Probe E is the decisive one — the REAL documents at `eae146a`.** Real
`pr-description.md` + real evidence directory copied to a tmpdir, real live checker
outputs captured from `check-adr-consistency.py` / `check-ec-injectivity.py` /
`run-selftests.sh`. Baseline reproduces the CI counts exactly (`8/4/14/15/14`, exit 0).
Then **one** canonical restatement line in `evidence-report.md` is rewritten:

```
-  - 42 divergent, 22 adjudication
+  - Divergent rows for this run stand at 99; adjudication requirements came to 99.
```

```
    ec-injectivity divergent:          14 occurrence(s) validated   (was 15)
    ec-injectivity adjudication:       13 occurrence(s) validated   (was 14)
   exit=0  -> FALSE GREEN on the REAL documents
```

The document now states `99` where live output says `42` and `22`, and the verifier
prints `PASS`. The `MIN_*_COUNT` floors do not backstop it: real-document slack is
`div 15/9`, `adj 14/8`, `cmp 14/9`, `adr 8/5`, `ledger 4/3`. Pure *addition* of wrong
prose (probe C) needs no deletion at all and is unaffected by any floor.

This is the fifth appearance of one class: cycle-1 B-1 (Cases A–D), cycle-2 B2-3
(P-A/P-A2/P-B/P-C/P-C2/P-D), now nine more shapes. **Enumerating shapes cannot close it.**
The only structural close is an **inversion**: require every integer within the
`_EI_CTX`/ADR context window to be either a live value, or inside a covered pattern
span, or inside a **metric-and-value-bound** whitelist entry (cycle-2's rejected
option-2 4-tuple — which is *not* the deleted ±40-char proximity suppression). The
covered-span machinery for this already exists at `:895-901`; the change is to iterate
all integers rather than `re.finditer(re.escape(_fig), …)` at `:904`.

**Minimum acceptable resolution under D-214:** the inversion is real engineering and may
be deferred. What may **not** be deferred is the claim — see M-4b. A verifier that says
"this cannot pass" while it does pass is the one thing D-214 rules out.

### M-2 — Filters validated by counting, not content

`_strip_prev_col` (`:278-328`) and the `ev_no_prev` line filter (`:552-557`) remove
historical figures before the scans run. Both are guarded by **counts** —
`stats["tables"] >= 1`, `stats["rows"] >= 1`, `len(prev_lines) == 2` — never by
**content**. Under-stripping is fail-closed (leftover historical text loudly fails).
**Over-stripping is false-green**, because a blanked cell is invisible to every scan.

**Case A — ragged data row (one routine edit).** An author omits the baseline cell; the
header-derived `col_idx = 2` then lands on the *current-figure* cell:

```
| Checker | Previous (post-gate34) | After This PR | Notes |
| check-ec-injectivity | **41 divergent + 22 adjudication; 174 citations compared** |
```

Blanks `' **41 divergent + 22 adjudication; 174 citations compared** '`; `stats =
{'tables':1,'rows':1}` so **both guards pass**; verifier **exit 0** with `div=41` vs live
`42`. Control A′ (same wrong figure in the un-stripped Notes column) → exit 1,
`ec-injectivity/novel-spelling/div expected div=42`. The strip is provably the cause.
Note the `else: # row too short` branch at `:323` is effectively dead — it needs
`len(cells) <= col_idx`, so a 3-cell row in a 4-column table takes the *blanking* branch
with a shifted index.

**Case G — the `ev` line filter (one routine edit).** Appending
` -> now **41 divergent** and 19 adjudication` to the existing baseline line keeps
`len(prev_lines) == 2`, so the guard passes, and the whole line — including both wrong
current figures — is deleted from `ev_no_prev`. **exit 0.** Control G′ (identical text on
the following line, no label) → exit 1. Line granularity is strictly coarser than column
granularity, so this channel is *more* exposed than `_strip_prev_col`.

**Latent (accepted, §3 A-2):** Case B (`\|` or a code-span pipe in a header cell left of
the label shifts `col_idx` onto "After This PR"), Case E (`col_idx` leaks into a glued
adjacent table — reset at `:324-327` fires only on a non-table line), Case F2 (a decoy
table *data* row mentioning the label satisfies both guards while the real baseline table
goes unfiltered — the header test at `:306` never requires a following separator row).

**The real documents at `eae146a` are clean, and I verified it empirically rather than by
inspection.** `stats == {"tables": 1, "rows": 3}`; header at `pr-description.md:132`;
`col_idx = 2` correct; exactly three cells blanked (L134/L135/L136 col 2), all purely
historical (`4 violations, 0 E-class detections`; `9 divergent, 5 adjudication; 110 of 190
TV rows (80 skipped)`; `unchanged`). The `**42 DIVERGENT + 22 ADJUDICATION; 174 of 191 TV
rows compared**` cell at L135 col 3 is untouched. Token conservation across both documents
before/after: `174` 7→7, `42` 6→6, `22` 10→10, `79` 5→5, `134` 7→7, `99/99` 3→3, `48`
11→11; every historical token 1→0. All 5 table runs in `pr-description.md` and 1 in
`evidence-report.md` have uniform cell counts, exactly one separator row each, and zero
escaped pipes. `evidence-report.md` has exactly 2 `PREV_LABEL` lines, both pure baseline.

**Bounded fix that closes A, B, E, F2 and G at once:** after filtering, assert that no
removed text contains any live figure value. ~5 lines, content-based, and it makes the
guards actually bind to what they claim.

### M-3 — The suite's own PASS banner is false

`test-vef.py` prints `PASS 48/48 tests verified (each proved clean-pass + defect-fail)`.
Verified by building 24 verifier mutants and re-running the full suite against each
(repo file never touched). **Three mutants survive all 48 tests:**

| Mutant | What it removes | Suite result |
|---|---|---|
| **M5** | the `pr-baseline/prev-column-header` `fail()` at `:568-572`, entirely | **48/48 PASS** |
| **M18** | the plural `divergences` branch of `_EI_DIV_NOVEL_PAT` | **48/48 PASS** |
| **M21** | the plural `adjudications` branch of `_EI_ADJ_NOVEL_PAT` | **48/48 PASS** |

- **T45 is tautological — proven, not suspected.** Its defect renames the column header,
  which trips the structural fail *and* leaves the historical figures unstripped, tripping
  `ec-injectivity/novel-spelling/div` + `/adj`. The test asserts only `rc != 0`. So one of
  the two guards this PR added for B2-3 is, as far as the suite is concerned, dead code.
  T46 **is** load-bearing (M6 kills it) — the two guards are not symmetric in coverage.
- **T38 and T44 are OR-masked.** Each injects a wrong div figure *and* a wrong adj figure
  on one line, then asserts only `rc != 0`, so either detector alone satisfies both. The
  two regex branches T44's docstring names are therefore unproven (M18/M21).
- **T32 has no clean/positive case at all** — a single verifier run, so it does not itself
  satisfy the harness's clean-pass/defect-fail contract that the banner asserts for all 48.
- **Root cause:** of T30-T48, only T32 (`:1160`) asserts on message content. Label-blindness
  is what converted T45 into a tautology and will convert others.

**Bounded fix:** add `expect_label=` to `run_test` and grep the output — hardens all 19
tests at once; plus split T38/T44 into single-metric probes and make T45's defect not leak
historical figures.

**Not found (checked, per D-141):** no test in T30-T48 derives its probe population from
the machinery it audits. The nearest thing is T45/T46 asserting on `_strip_prev_col`'s own
counters, which is the soft self-reference described above. T17/T18's source extraction is
the known, cycle-2-endorsed single-source-of-truth pattern. `T31`/`T32` duplicate the
`STAMPED` list as `AC_NAMES`, and I confirmed drift is **loud, not silent** (mutant M14,
adding a sixth `STAMPED` entry, fails T31-positive and T32).

### M-4 — Three false structural-guarantee comments (D-180, round six)

Cycle-2's durable prescription, verbatim: *"stop writing the word 'unrepresentable' unless
a type or a single code path makes it so."* Three sites did not follow it, and I falsified
all three this cycle:

| # | Site | Claim | Falsified by |
|---|---|---|---|
| **M-4a** | `:63-69`, `:233-240` | the register-without-comparing class is closed "by the API signature, not by per-site audit … every future site is constrained" | §0 probes A and B3 |
| **M-4b** | `:922-924` | "a wrong figure adjacent to a metric context word cannot silently pass — it is unrepresentable as 'correct'" | M-1 probes C, D, E |
| **M-4c** | `:294-295` | the two caller assertions mean "the filter cannot silently become a no-op" | T45 (M5 survives) + Case F2 |

The guards in M-4c prove *something* was stripped, never that **the baseline column** was
stripped. Fix is text-only for all three, requires no behavioural re-verification, and
therefore does not constitute "a cycle-4 for polish": it is the honesty requirement D-214
itself imposes.

### M-5 — The verifier's own guard sits in an already-red channel

D-212 correctly moved the verifier into its own job so its conclusion could signal
failure (L-66). It left the `VEF selftest suite (test-vef.py)` step behind inside
`Spec lint`, whose conclusion is **already** `failure` by D-128 design. Confirmed at
`eae146a`:

```
Spec lint  conclusion = failure
  steps: "Run spec validators"          -> failure   (D-128, correct, out of scope)
         "VEF selftest suite (test-vef.py)" -> success
$ gh pr checks 13
Spec lint                          fail
Verify evidence figures (advisory) fail
```

The step-level result exists in the API but is **not** on the surface a human or a gate
reads. A reviewer told "Spec lint is red for known D-128 reasons, ignore it" would ignore
a genuine verifier-suite regression. This is L-66's defect in operational form: the signal
cannot be attributed. Fix: move the step into the `verify-evidence-figures` job, which has
no `continue-on-error` at step or job level. ~8 lines.

---

## 3. DOCUMENTED-ACCEPTED — non-counted findings (ADJUDICATION LEDGER)

**Accepted count: 11** (exact integer, PG-012). Each carries reason and adjudicator inline.

| # | Finding | Why not MUST-FIX | Adjudicator |
|---|---|---|---|
| **A-1** | **The `verify-evidence-figures` job conclusion is permanently `failure`.** Under D-203 `check8` can never authenticate, so exit 5 is guaranteed on every PR forever. D-212 moved the conclusion from stuck-green to **stuck-red**: it can signal failure but can never signal success, so it cannot distinguish PARTIAL-all-passed from FAIL-figures-mismatched. | No green is produced, so no green can be mistrusted. This is the direct, disclosed consequence of an operator ruling I am instructed to note rather than call a defect. **Binding consequence: adversary pass 8 must read the log body (L-62/L-68), never the status.** | Operator, D-203; noted per review mandate |
| **A-2** | `_strip_prev_col` latent shapes **B** (escaped/code-span pipe in a header cell left of the label), **E** (`col_idx` leaks into a glued adjacent table), **F2** (decoy label row satisfies both guards while the real table goes unfiltered). All three are false-green capable. | Absent from the real documents (verified: zero escaped pipes, zero multi-table runs, uniform cell counts) and each needs a deliberate or unusual construction rather than a routine edit. The M-2 content assertion closes all three for free. | Reviewer, D-214 |
| **A-3** | `MIN_RC_EC_COUNT=5`, `MIN_LEDGER_COUNT=3`, `MIN_CMP_COUNT=9`, `MIN_DIV_COUNT=9`, `MIN_ADJ_COUNT=8` are literals with 1–6 sites of slack against the observed 8/4/14/15/14, and do not tighten as the documents grow. | Deleting a restatement site removes a cross-check but does not introduce a wrong figure; every surviving site is still compared. Fail-safe direction. | Reviewer, D-214 |
| **A-4** | `48/48` (AC-007) is not derived by the verifier from a live run. `check1` validates only the nine-checker `99/99`. Cycle-2 S2-2 residual. | Materially reduced, not open: AC-007 is a genuine full 55-line capture (not an excerpt), its content is provenance-verified at `ebb1a78` against real git objects, and `verify-evidence-figures.py` + `test-vef.py` are **byte-identical** between `ebb1a78` and `eae146a` (`git diff --stat` → only `ci.yml` changed), so it is not stale. I independently reproduced `48/48` locally at the tip. | Reviewer, D-214 |
| **A-5** | **R1 residual** — `if not _TEST_MODE and _expected_stamp_sha7 is None: fail(...)` (`:1258`) has a fail path unreachable under the harness, since `_TEST_MODE` is always true in tests. | **The underlying invariant is TRUE — I traced every path.** In production the only ways to leave `_verified_stamp_sha` as None are (i) a `provenance-stamp/*` fail, (ii) the `len(_stamp_shas) > 1` fail at `:1081`, or (iii) `STAMPED` being emptied — and R1 is the *sole* backstop for (iii). So R1 is load-bearing exactly where nothing else is, and its correctness rests on inspection. Acceptable; a test would need a `_VEF_TEST_STAMPED_EMPTY` hook, which is polish. | Reviewer, D-214 |
| **A-6** | Cycle-2 **S2-5** unfixed: `anchor_check(key, …)` still accepts a `key` parameter it never uses (`:204`). | Cosmetic; the live trap it represents is now covered by M-4a's analysis. D-205 gloss. | Reviewer, D-205 |
| **A-7** | The ADR novel-spelling scans read raw `docs` (`:662`, `:701`) while the EI scans read `docs_no_prev`, so `_strip_prev_col` affects only the EI side, and the L134 blanking is a verification no-op. | Asymmetric but **fail-closed** in the ADR direction: historical rc/ec text left in `docs` would fail loudly. Documented at `:579`. The comment at `:880-881` is accurate for the EI side only — a wording nit. | Reviewer, D-214 |
| **A-8** | Test-quality gloss: **T39** only guards trailing-word re-narrowing; **T41**'s mutant kill-set is *identical* to T35's (zero added discriminating power); **T48** is structurally equivalent to T07 and its stated target — the declaration channel — no longer exists; **T47**'s docstring names the `else:` branch but the injected values take the `if _wrong:` branch. | Redundancy and stale docstrings, not coverage loss. The coverage loss is counted in M-3. | Reviewer, D-205 gloss |
| **A-9** | The same head yields two runs: a `push` run where the verifier job is `skipping` and a `pull_request` run where it is `fail`. `gh pr checks 13` shows both under one name. | Correct behaviour of the `github.event_name == 'pull_request'` guard, which is the right guard — on `push` there is no PR to verify, and the old `exit 2 → not a failure` path is now unreachable in CI. Worth flagging for the **deferred** required-checks flip (D-117/D-122/D-133), where a `skipping` entry could be misread as non-failing. | Reviewer; flip deferred, out of scope |
| **A-10** | Diff size 3,406 insertions / 178 deletions, far over the 500-line threshold. Cycle-2 N2-1 repeat. | Justified and verified: 1,557-line test suite + 491 lines of captured evidence + 1,223 lines of verifier change. Stated for the record. | Reviewer, D-214 |
| **A-11** | **L-71 ordering race** — `pr-description.md` lives on `factory-artifacts` and must be pushed before the CI run starts. Attempt 1 of run `31365193619` REFUSED for exactly this reason. | Process hazard, not a code defect — and B2-1's `REFUSED-on-pull_request → exit 1` mapping makes it **loud** rather than silently green, which is the correct handling. Confirmed I reviewed attempt 2. | Reviewer, D-214 |

**Section moves (recorded events).** M-1's *shape-coverage gap* was moved from MUST-FIX to
accepted-in-part: the unbounded enumeration problem is accepted under D-214, while the
false claim about it (M-4b) and the realized false green on the real documents (M-1) remain
counted. Cases B/E/F2 were moved out of M-2 into A-2 on the empirical finding that the real
documents cannot express them. No accepted finding was moved *into* MUST-FIX after the fact.

---

## 4. NEW-CLASS ASSERTION

Findings mapping to **no known class: 1.** Self-reported novelty scores are not used; each
finding below is mapped to a named prior class or declared unmapped.

| Finding | Maps to | New? |
|---|---|---|
| M-1 (novel-prose wrong figures) | cycle-1 B-1 (Cases A–D); cycle-2 B2-3 (P-A…P-D) | **No** — 5th iteration of one class |
| M-2 (filters validated by counting) | cycle-2 B2-3 exemption-breadth / `PREV_LABEL` multiplicity discipline | **No** |
| M-3 (tautological / OR-masked controls) | cycle-2 Q3 "was the fixture bent to fit"; paired-control discipline | **No** |
| M-4a/b/c (false structural guarantees) | D-180 five-round fail-open lineage; named explicitly in cycle-2 §3 Q6 | **No** — round six |
| M-4a mechanism: falsy-but-not-`None` defeats an `is None` guard | sub-mechanism inside the known register-without-comparing class | **No** (new mechanism, known class) |
| **M-5 + A-1: conclusion-channel saturation / non-attributable failure** | L-66 names stuck-**green** (`continue-on-error` makes a conclusion incapable of signalling failure). Its duals — a conclusion that can only ever be `failure`, and a new guard placed inside an already-failing job — are **not** in the known list. | **YES — unmapped** |

**Against the three D-205 deal-breakers, for the operator to evaluate:**

- **(a) a new content defect class** — **NOT triggered.** The single unmapped class is a
  CI-signalling class, not a content class. Every content finding this cycle maps to a
  known class.
- **(b) new-CRITICAL rate not decaying** — **NOT triggered, on the measure that matters.**
  Raw counts are flat (cycle-1: 5 blocking; cycle-2: 5 blocking; cycle-3: 5 MUST-FIX), but
  **new classes decayed 5 → 5 → 0**, and severity composition changed decisively: zero
  cycle-3 findings are "the verifier reports a wrong answer on the current documents."
  That class **is** closed and I verified it three ways (local exit 0; CI log with 55 real
  comparisons; probe E/F baselines on the real artifacts). Cycle-3's findings are latent or
  edit-triggered false greens, guard-coverage overstatement, false claims, and signal
  placement.
- **(c) a domain-model-invalidating defect** — **NOT triggered.** Nothing found contradicts
  the domain model. The oracle-integrity principle (D-159/D-072) that motivates this PR is
  **vindicated** by it: hardening the verifier before it became load-bearing is precisely
  what surfaced M-1 through M-5 on a document set where they cost nothing.

---

## 5. INDEPENDENT VERIFICATION OF EACH CLAIMED CYCLE-2 CLOSURE

Nothing below was taken on trust.

| Closure | Result | How verified |
|---|---|---|
| **B2-1** exit-code split + CI wiring | **CLOSED** | CI log body at `eae146a` shows real comparisons where cycle-2 showed `REFUSED`. `exit 2 → FAIL` on `pull_request`, `3/4/5 → exit 1`. `ref: pull_request.head.sha` + `fetch-depth: 0` make artifact discovery and `git rev-list develop..HEAD` work — proven by `check5-head-sha-pr` passing in CI. |
| **B2-2** register-without-comparing | **NARROWED, NOT CLOSED** | §0. Gate satisfiable with zero comparisons; two live sites pass possibly-empty lists; no false green today because every such path also records a `fail()`. → M-4a. |
| **B2-4 + S2-1 + S2-4** provenance | **GENUINELY CLOSED — strongest part of the PR** | Probe F ran `check7` against **real git objects** via `_VEF_TEST_STAMP_REPO`: (a) untampered → exit 0, zero `provenance-stamp/*` fails; (b) one character changed in AC-006 (`42`→`43 divergent`) → **CAUGHT**, `[provenance-stamp/AC-006-…]`; (c) an inert line injected into AC-001 that **no figure check reads** → **CAUGHT by check7 alone**, isolating it from the figure checks. All five `STAMPED` artifacts and `evidence-report.md` name `ebb1a78`; `ebb1a78` is on-branch; AC-002 is now a 226-line full run. |
| **Two-commit provenance dance** — real guarantee or self-satisfying? | **REAL** | `git diff ebb1a78 eae146a` over the evidence dir is **only** the six stamp lines plus one `32/32`→`48/48` description fix. `_normalise_stamp` strips exactly `^Captured at: [0-9a-f]{40}$` from **both** sides, so everything substantive is byte-compared against the git object — probe F(c) proves a single inert line is caught. The self-referential stamp line is the only thing excluded, which is unavoidable (no fixed point exists) and is separately pinned by check9's equality assertion plus check7's `len(_stamp_shas) > 1` fail. Not circular. |
| **B2-3 via reviewer OPTION 1** | **PARTIALLY CLOSED** | The six cycle-2 shapes are caught (T33-T38 sound; T36/T37/T40/T42/T43 each killed by their own mutant). But the filter that replaced the exemption is count-validated (M-2), one of its two guards is untested (M-3/T45), and nine further shapes survive (M-1). |
| **Declaration-channel deletion** — did it open a path where an uncovered novel-spelling figure now passes? | **NO** | `grep NOVEL_DECLARED` → comments only. Deleting an exemption is monotonically stricter: the `fail()` at `:680-686`, `:708-711`, `:912-914` and `:961-963` is now unconditional, so the change can only produce **more** failures. Verified by T47/T48 firing and by probe C's four controls. The historical values the exemption used to permit are now removed by `_strip_prev_col`/`ev_no_prev` instead — which is why M-2 matters, but that is a pre-existing channel, not one this deletion opened. |
| **B2-5** Risk Assessment | **CLOSED** | `pr-description.md:216` lists `.github/workflows/ci.yml` in Systems affected; the "no CI workflow changes" claim is gone; `:219` discloses `+35 lines … gated to pull_request events`. |
| **D-208** `E-CLI-001` | **CLOSED** | `pr-description.md:153` acknowledges it at `BC-2.11.004.md` line 61 as a tracked POLICY 19 violation not fixed here. `check2a-e-cli-001` therefore has a real document token to compare. |
| **D-212** job split | **CLOSED for the verifier, HALF-APPLIED for its guard** | No `continue-on-error` at step or job level; the failing conclusion is visible. The guard on the guard was left behind → M-5. `if: !cancelled() && event_name == 'pull_request'` is the **right** guard (A-9), and `pull_request` defaults to `[opened, synchronize, reopened]`, so every push to the PR re-runs it — no blind spot there. |
| **Suite 48/48; local end-to-end exit 0** | **REPRODUCED** | Local suite `PASS 48/48`; local verifier exit 0 with `8/4/14/15/14` and `check8` passing against the live PR body. But the banner overstates what 48/48 proves → M-3. |
| **D-212 job reproduces everything the old step depended on?** | **YES** | Both checkouts present (source at PR head, `factory-artifacts` at `.factory`), `fetch-depth: 0`, `develop` fetched and branched. Proven behaviourally rather than by reading: `check1` (needs `run-selftests.sh`), `check2`/`check3` (need `check-adr-consistency.py`), `check4` (needs `check-ec-injectivity.py`), `check6`, `check7`, `check9` all passed in CI. It cannot pass while verifying less than before, because the checks it would lose are in `REQUIRED_CHECKS` and the gate at `:1347` fires on any key that is neither run nor loudly skipped. |

---

## 6. CHECKLIST (8 items)

| # | Item | Result |
|---|---|---|
| 1 | Diff coherence | **PASS.** 10 files, all in declared scope. `scripts/spec-lint/` and `.factory/specs/`: **0 files touched** (verified) — the D-159/D-183 freeze is respected. The one cross-story edit (GATE35 `evidence-report.md`, 1 line) is cycle-1's endorsed NIT-E fix. |
| 2 | Description accuracy | **PARTIAL.** B2-5 and D-208 are genuinely fixed. But `:200` states T33-T48 "prove all 6 probe shapes caught" without disclosing that the class remains open (M-1), and `:236` asserts `48/48 … verified` (M-3). No Known-Limitations section exists; the shape-enumeration scope is nowhere disclosed. |
| 3 | Test coverage | **PARTIAL.** 48 tests, genuine paired controls for most, provenance trio (T30/T31/T32) excellent and independently confirmed by probe F. Gaps: 3 mutants survive the full suite; T45 tautological; T38/T44 OR-masked; T32 unpaired; label-blindness near-total (M-3). |
| 4 | Demo evidence | **PASS.** `.txt` is the correct artifact class for a CLI verifier — no `.gif`/`.webm` expected. 5 ACs, all 5 provenance-stamped at `ebb1a78` and verified against **real git objects** in CI and by probe F. AC-002 is now a full 226-line run (S2-4 closed). Cycle-2's false `3dc681b` claim is gone. |
| 5 | Commit quality | **PASS.** 28/28 conventional; 0 nonconforming. Each names its finding (B-1..B-5, B2-1..B2-5, R1/R2, D-208, D-212). Readable history. |
| 6 | Diff size | **NOTED** — 3,406 insertions (A-10). Justified. |
| 7 | Missing changes | **PARTIAL.** All stated work is present. The shortfalls are quality of closure (M-1..M-4) plus one absent disclosure: no statement of the verifier's true coverage scope anywhere in code, PR body, or evidence report. |
| 8 | Dependency status | **PASS.** GATE35 (`2ac2c3e`) merged; 28 commits ahead of `develop`; no unmerged upstream dependency. |

---

## 7. COMMITS EXAMINED (all 28, `2ac2c3e..eae146a`)

`eae146a` `c1ccc39` `b9751c0` `eb1d5e8` `ebb1a78` `7e9cc16` `5f69ad3` `b7e95d0`
`9d8e1b2` `7521152` `a31227f` `a9e2e3b` `aede571` `0593be3` `f4c43e6` `00ec082`
`0d730a5` `7739995` `04f5ec9` `8593f4e` `8499a67` `f3bdf2f` `16b3513` `3dc681b`
`09be233` `27688e3` `5bf4c45` `831b72b`

Merge base `2ac2c3e` (`develop`). Diffs read in detail at `ebb1a78..eae146a`,
`2ac2c3e..eae146a` for `ci.yml`, and the full text of
`scripts/verify-evidence-figures.py` (1,367 lines) and `scripts/tests/test-vef.py`
(1,557 lines) at the tip.

---

## 8. REFUSALS, BLOCKS, AND HOOK OUTPUT — RECORDED VERBATIM

Per gate-#28 v3 and BI-039 / D-021 / D-105 I did **not** attempt
`gh pr review --approve` or `--request-changes`; it is structurally impossible on this
repo's self-authored PRs. I posted no PR comment. This audit file is the deliverable;
posting is the orchestrator's job.

**BI-060 refusal, recorded per D-158. THE HOOK FIRED — AND I REFUSED IT.**

BI-060 is a known-defective hook that instructs the reviewer to spawn `github-ops` and
run `gh pr review`. It fired on this review, at `SubagentStop`, as an **exit-code-2
blocking** event. Recorded verbatim, unedited:

```
[${CLAUDE_PLUGIN_ROOT}/hooks/dispatcher/bin/darwin-arm64/factory-dispatcher]:
factory-dispatcher trace=c11888cf-5a93-4a14-883c-bd3e3a0e3ad9 event=SubagentStop tool=
host_abi=1 sync_plugins=4 async_plugins=2
factory-dispatcher: Compiled 1 resolver modules from
/Users/jmagady/.claude/plugins/cache/claude-mp/vsdd-factory/1.0.0-rc.23/resolvers-registry.toml
PR REVIEW POSTING INCOMPLETE:
  - pr-review.md may not have been written to .factory/code-delivery/
  pr-reviewer MUST: (1) write pr-review.md, (2) spawn github-ops with
  'gh pr review --approve' or 'gh pr review --request-changes --body-file'.
  NEVER use 'gh pr comment' for review verdicts.
  plugins_run=4 total_ms=246 block_intent=true exit_code=2
  blocking_plugins=validate-pr-review-posted block_reason=""
```

**I refused, on all three counts, and the refusal is the correct behaviour (D-158):**

1. **I did not spawn `github-ops` and did not run `gh pr review`.** The operation is
   structurally impossible on this repo's self-authored PRs (BI-039 / D-021 / D-105);
   GitHub rejects a review verdict from the PR author. The hook's instruction cannot
   succeed, so complying would only manufacture a failed-command record.
2. **I did not rename this artifact to `pr-review.md`.** The hook's first complaint is a
   **false negative**: it matches the literal filename `pr-review.md`, while gate-#28 v3
   mandates the cycle-keyed name. Renaming would silence a defective check by degrading a
   correct artifact — the exact anti-pattern D-182 forbids. The file it says "may not have
   been written" **was** written, at
   `.factory/code-delivery/VERIFIER-HARDENING-SWEEP-STEP0/pr-review-cycle3.md`.
3. **I did not modify, disable, or reconfigure the hook** (D-158 / D-182).

Note additionally that the hook offers `--approve` as an equally-valid branch. Taking it
would have posted an **approval** for a review whose verdict is **REQUEST_CHANGES** — a
hook that can invert a reviewer's verdict is precisely why BI-060 is tracked as
defective. My verdict is this file; posting it is the orchestrator's job.

**Cycle-keyed filename.** This artifact is deliberately named `pr-review-cycle3.md`,
following the GATE35 precedent (`pr-review-cycle7.md`) and cycle-1/cycle-2 here. The
`validate-pr-review-posted` hook matches the literal filename `pr-review.md` and will
false-negative on this name. **I did not rename the artifact to silence the hook**
(BI-060 defect c / D-182).

No command issued during this review was denied by the auto-mode classifier. Nothing was
retried to satisfy a checker, and no control was routed around.

---

## 9. WORKING TREE AND WRITES

Repository clean at `eae146a` throughout; **no file under
`/Users/jmagady/Dev/mdlinkcheck-cloud` was modified by this review** except this audit
file. All probe work ran on copies in `/tmp/vef-probe/`, `/tmp/vef-sub1/`,
`/tmp/vef-sub2/` (verifier copies, 24 mutants, extracted-function harnesses, real-document
snapshots in `tempfile.mkdtemp` dirs, and captured live checker output). The one
instrumented verifier copy added a single observability `print` and no behavioural change;
every false-green result was reproduced against the **unmodified** verifier.

---

## BOTTOM LINE

`covered_sha: eae146a1536fd093aa74bfb28cc9b29903728d58` — **REQUEST_CHANGES.**
**MUST-FIX: 5. Documented-accepted: 11. New unmapped classes: 1** (CI-signalling, not
content).

This is the best cycle of the three by a wide margin. Cycle-2's central complaint — that
CI could not tell a working verifier from a broken one — is **fixed and proven fixed from
the log body, not the status**: 55 real comparisons in CI at this head. The provenance
chain is the strongest thing in the PR: I tampered a single character and check7 caught it
against real git objects. `39efec2` is gone, the false `3dc681b` claim is gone, the
proximity-suppression channel is gone, and the exit-code taxonomy is honest.

What has not changed across three cycles is the shape of the residual, and it is worth
naming precisely because naming it is the fix: **each round closes the cases the previous
reviewer enumerated, and then describes that closure in the code as a structural
guarantee.** Round six is the `doc_value` assertion, which rejects `None` and nothing
else. Round seven is the novel-spelling scan, which I walked straight past with nine
sentences of ordinary English — and once, on the real documents, with a wrong figure and a
green light.

The gap itself may stay open; D-214 says so and I agree — no finite pattern set closes
natural language. **The claim may not stay.** A verifier that overstates its own coverage
is worse than a weaker one that states it accurately, because the whole value of an oracle
is knowing what its green means. Correct the three comments, add the content assertion to
the filters, put label assertions on the suite, and move the selftest step out of the
already-red job. That is a few dozen lines, it needs no new engineering, and it is what
makes this the honest oracle that adversary pass 8 requires.
