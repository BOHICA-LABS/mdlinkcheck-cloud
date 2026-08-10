# PR #13 — Fresh-eyes review, CYCLE 2 (gate-#28 v3)

**covered_sha:** `7739995e7e3f25c0af3dd9bcad535af2a7774fbb`
**PR:** #13 — `feat(GATE42-step0): harden verify-evidence-figures.py before nine-checker sweep`
**Branch:** `fix/verifier-hardening-sweep-step0` (11 commits ahead of `develop` @ `2ac2c3e`)
**Reviewer mode:** read-only on the repository under review; audit file is the only write.
**Prior cycle:** `pr-review-cycle1.md` — REQUEST_CHANGES, B-1..B-5 (BI-061).

---

## Verdict

**REQUEST_CHANGES**

Four of the five claimed closures are real *as coded against the cases the author
enumerated*. Two are not closed against their own stated criterion (**B-5**, **B-3**), one
is closed only for the enumerated shapes and ships a new suppression channel (**B-1**), and
the tool's own evidence artifact carries a **provably false provenance SHA that the
B-4 redesign passes** (**B-4 residual**).

**Was mechanism number five found? YES — two, one of them with hard CI evidence.**

---

## 0. Corroboration of the orchestrator's independent verifications

Every item was re-run by me at `covered_sha` = `7739995`. All corroborated.

| Orchestrator claim | My result | Status |
|---|---|---|
| Selftests 26/26, exit 0 | `PASS  26/26 tests verified` — T17 and T18 both **PASS** (gh present, no loud skip) | CORROBORATED |
| End-to-end no-flag run exits 0 with `PASS — all figure checks match live output and git state` | exit 0; `adr 8 occ / ledger 4 / ei cmp 14, div 15, adj 14`; 2 declared novel-spelling sites enumerated | CORROBORATED |
| CI at `7739995`: Build/Clippy/Format/Test/GitGuardian SUCCESS, `Spec lint` FAILURE advisory | `gh pr checks 13` matches exactly | CORROBORATED |
| `Spec lint` failure is the three tracked `develop` checker failures (D-128) | confirmed, `scripts/spec-lint/` untouched in the diff | CORROBORATED |
| B-5: run `31340914559` shows `Verify evidence figures (advisory)` = **success** (was `skipped`) | **step status is success — and the step verified nothing.** See B2-1. | CORROBORATED AS TO STATUS, **REFUTED AS TO MEANING** |
| `headRefOid`→`headSha` mutation drives suite to 24/26 with T17+T18 failing | Not re-mutated (read-only mandate); mechanism audited statically and found genuinely structural — see §2 B-2 | CORROBORATED BY CODE AUDIT |

The mutation test was *not* re-executed because it requires editing the file under
review. The single-source-of-truth extraction was audited instead and is sound (§2, B-2).

---

## 1. Findings

Severity in ranges per PG-012.

| # | Severity | Category | Finding |
|---|---|---|---|
| **B2-1** | **blocking (high)** | ci-wiring / fail-open | **Mechanism 5(a).** B-5's fix makes the advisory step *run*, and the step is **structurally incapable of verifying anything in CI**. Both runs at head show the verifier exiting 2 on a `gh` auth failure, which the wrapper prints as "not a failure" → green. Inert is now reported as **success** instead of `skipped` — strictly worse than the cycle-1 state. |
| **B2-2** | **blocking (high–mid)** | soundness | **B-3's structural guarantee is falsified on the production path.** `check2a-e-cli-001` calls `record_comparison()` after executing **zero** comparison — the real `pr-description.md` contains no `E-CLI-001` at all. ATTACK-A's shape survives at a different key. The docstring's "unrepresentable" claim and the "11 of ~14" coverage number are both overstated. |
| **B2-3** | **blocking (mid–high)** | soundness / suppression | **B-1 closes only the enumerated shapes.** Six wrong-figure injections still PASS clean, including one where the `EI_NOVEL_DECLARED` exemption suppresses an **arbitrary** wrong figure by ±40-char proximity. **Mechanism 5(b).** |
| **B2-4** | **blocking (mid)** | evidence-integrity | `evidence-report.md` states `**Captured at SHA:** 3dc681b`. At `3dc681b` the evidence directory **did not exist** and `test-vef.py` had **21** tests, not 26. The AC artifacts' own stamps say `16b3513`. B-4's redesigned `check9` accepts any of the 11 branch commits and **passes this false claim**. |
| **B2-5** | **blocking (low)** | description-accuracy | Risk Assessment states "**no CI workflow changes**" and omits `.github/workflows/ci.yml` from "Systems affected", while the diff changes it by +35 lines — that change *is* the B-5 fix. |
| S2-1 | suggestion (mid) | test-coverage | `check7-provenance-stamps` remains unregistered **and** fully skipped in test mode → zero coverage for the only check that reads git object content. It also excludes `AC-002` and `AC-007`, the two artifacts carrying the headline figures. |
| S2-2 | suggestion (mid) | soundness | **26/26 — the PR's headline figure — is the one figure the verifier never derives from a live run.** `check1` validates the nine-checker 99/99 only. `AC-007`'s number is asserted, not verified. |
| S2-3 | suggestion (mid) | test-coverage | Cycle-1 S-3 is still open: **nothing runs `test-vef.py`** — not CI, not `just`. Combined with B2-1, neither the probe nor the CI step protects the verifier. |
| S2-4 | suggestion (low) | evidence-integrity | `AC-002-selftest-99of99.txt` is a 3-line hand-trimmed excerpt beginning mid-output (`  PASS (clean-pass with §2-shape…`), unstamped and outside `STAMPED`. Calling it a "run" in `evidence-report.md` is thin. |
| S2-5 | suggestion (low) | maintainability | `anchor_check(key, …)` still accepts `key` and never uses it — a live trap for precisely the entry-vs-registration confusion B-3 was about. |
| N2-1 | nit | diff-size | 2,048 insertions / 176 deletions (>500 threshold). Justified (824-line new test file + 266-line AC-006 capture), stated for the record. |
| N2-2 | nit | test-harness | Suite exits **0** printing `PASS 24/26 (2 loud-skip)` when `gh` is absent. The skip is loud, but the exit code is a pass. |

---

## 2. Audit of each claimed closure

### B-2 — field contract · **GENUINELY CLOSED** (with one caveat)

`test-vef.py:35-43` extracts the `gh --json` field list from the verifier source with
`re.findall` and asserts exactly one match site. This is the right shape:

- The regex `"gh",\s*"pr",\s*"view",\s*"--json",\s*"([^"]+)"` matches only the
  PR-resolution call (`verify-evidence-figures.py:271`). The check8 call at `:1071`
  interposes `str(pr_number)` between `"view"` and `"--json"`, so it is not matched.
- Either kind of drift is **fail-closed and loud**: adding a positional arg to the
  resolution call → 0 matches → `AssertionError` at import; removing the positional from
  the check8 call → 2 matches → `AssertionError`. The suite cannot run on an ambiguous
  source.
- T18 drives the **real** `gh` path (no `_VEF_TEST_PR_NUM`, no `_VEF_TEST_NO_OPEN_PR`) and
  distinguishes the mutation by a message that `gh` — not the verifier — generates.
  T17 is fully independent: it asks `gh` directly.

This is a probe that does not share the code path it validates. It meets the lesson-60
standard. **Caveat:** it is never executed by anything automated (S2-3), and CI cannot
detect the regression it guards because the bad-field path exits 2 (B2-1). So the
guarantee exists in the repo and is enforced nowhere in the pipeline.

### B-4 — de-hardcoding · **CLOSED for check7, NOT SOUND for check9**

check7 is correct: `_branch_sha_set` is derived from `git rev-list develop..HEAD`, the
comparison is a set difference (catches both missing SHAs and count drift), the empty-set
case is an explicit `fail()` rather than a vacuous pass, and the bare `if count_m:` now
has `else: fail()`. T19/T20 are paired controls. `39efec2` is gone from the tree.

check9 is where it breaks. The redesign replaced a **circular** predicate with one so weak
that the artifact it ships with is wrong and still passes:

```
evidence-report.md      : **Captured at SHA:** 3dc681b
AC-001/005/006 stamps   : Captured at: 16b351354fe0148fd1f2254b6eb9c022c4906602
git ls-tree 3dc681b -- docs/demo-evidence/VERIFIER-HARDENING-SWEEP-STEP0/  → EMPTY
git show 3dc681b:scripts/tests/test-vef.py | grep -cE '^    t[0-9]+_'      → 21  (not 26)
AC-007-vef-selftest.txt added at 7739995 (HEAD), content claims 26/26
```

At `3dc681b` none of this evidence existed, and the 26/26 result was not obtainable —
the suite had 21 tests. `check9` asks only *"is this SHA somewhere in `develop..HEAD`?"*,
which 11 distinct values satisfy. The document's own AC artifacts contradict it and the
verifier reports PASS.

**Structural fix (non-circular, and it removes a free variable):** require
`**Captured at SHA:**` to **equal the `Captured at:` stamp carried by the AC artifacts** —
a value `check7-provenance-stamps` already verifies against git object content via
`git show <sha>:<path>`. Then the report-level claim is pinned to content that provably
existed at that commit, with no reliance on set membership.

### B-3 — registration semantics · **NOT CLOSED**

`checks_ran` has exactly one write site (`:188`, inside `record_comparison`), and
`anchor_check()` no longer registers. That part is verified:

```
$ grep -n "checks_ran" scripts/verify-evidence-figures.py
146:checks_ran: set = set()
188:    checks_ran.add(key)
1096:missing_checks = REQUIRED_CHECKS - checks_ran
```

But the docstring claims more than that, and the claim is false as shipped
(`:47-50`): *"anchor found but comparison skipped is unrepresentable for every key in
`REQUIRED_CHECKS`"*. Here is the counterexample, on the production path, no mutation
required — `check2a-e-cli-001` (`:928-939`):

```python
_ecli_m = re.search(r"E-CLI-001", adr_out)                  # TRUE in production
if anchor_check("check2a-e-cli-001", _ecli_m, …):
    if re.search(r"E-CLI-001.*?test-vectors|…", pr):        # FALSE in production
        … fail(…)                                           # never runs
    record_comparison("check2a-e-cli-001")                  # registers anyway
```

Verified against the real documents at `covered_sha`:

```
grep -n "E-CLI-001\|test-vectors" .factory/code-delivery/…/pr-description.md → (none)
grep -n "E-CLI-001" docs/demo-evidence/…/AC-005-adr-consistency-live.txt     → line 14 (present)
```

So on the live run that exits 0, `check2a-e-cli-001` is in `checks_ran` having compared
nothing. The same is true of the shipped clean test fixture (`PR_FIXTURE` contains no
`E-CLI-001`), which is why the suite is green: **the ATTACK-A shape cycle 1 blocked on has
not been eliminated, it has been relocated from `check4a` to `check2a`.**

The registry-coverage claim inherits the defect. `check2a` is not a live-vs-document
comparison at all — it is a negative assertion whose only two reachable outcomes are
"register having compared nothing" and "register a failure". Counting it makes "11 of ~14
comparison sites" an overcount.

**Fix (structural, not additive):** make registration a *consequence* of comparing rather
than a statement adjacent to it. Two shapes both work:
1. Have the comparison helper do the registering — `compare(key, expected, actual)`
   fails-or-registers, and make `record_comparison` private to it. A check that reaches no
   `compare()` call cannot register.
2. Remove pure absence-assertions like `check2a` from `REQUIRED_CHECKS` and give them a
   separate registry (`ASSERTED_ABSENT`) with its own gate, so coverage counts stay honest.

Option 1 is the one that makes bad state unrepresentable; option 2 alone only fixes the
count.

### B-1 — novel-spelling inversion · **CLOSED FOR THE ENUMERATED SHAPES ONLY**

The EI per-metric scan (`:773-804`) is a genuine inversion for the three spellings it
knows, and the control fires. I re-ran cycle-1's Case D shape and it is caught:

```
P-E control (T24 shape: "…gave 99 divergent citations…")        : CAUGHT(rc=1)
```

Six injections against the same fixture still pass clean:

```
P-A  ADR wrong rc, single-metric  ("77 reason-code occurrences were observed…")     : PASS(rc=0)
P-A2 ADR wrong ec, single-metric  ("9 E-class code occurrences were observed.")     : PASS(rc=0)
P-B  ADR wrong rc on a line that ALSO carries a correct RC_EC_PAT match             : PASS(rc=0)
P-C  EI  wrong div, other spelling ("divergence count came to 99…")                 : PASS(rc=0)
P-C2 EI  wrong cmp ("99 citations examined, adjudication complete.")                : PASS(rc=0)
P-D  EI  wrong div INSIDE the declared-exemption window                             : PASS(rc=0)
```

Two of these are structural, not shape-enumeration:

**(a) The ADR scan is line-granular where the EI scan is span-granular.** `:502`
`if RC_EC_PAT.search(_line): continue` discards the whole line once any structured match
lands on it, so P-B's wrong figure is never examined. The EI side does this correctly with
`_ei_covered` character spans (`:750`, `:786`). The same author knew the better shape and
did not apply it on both sides.

**(b) The ADR scan requires BOTH context words on one line**, so a wrong `rc` stated
without `E-class` nearby (P-A) is never scanned. The comment justifies the pairing as
false-positive avoidance for `ec=6` — a real concern for `6`, not for `79`. Per-metric
scanning with a per-metric decision (as the EI side does) resolves it.

### Judgement requested — is `EI_NOVEL_DECLARED` the right mechanism, or suppression in disguise?

**It is not a D-039 violation, and it is still the wrong mechanism.** The disclosure
discipline is genuinely met: both entries print on every run (I saw them), and S-7
stale-detection exists. But the *binding* is wrong, and that is what makes it a
suppression:

- The exemption is matched by `if d[0] in _site_ctx` where `_site_ctx` is a ±40-char
  window (`:752`, `:791`). It therefore exempts **any** uncovered figure that happens to
  sit within ~80 characters of the fragment `110 of 190 TV rows` — not the two historical
  values it was written for. P-D demonstrates it: injecting
  `Baseline note: 7 divergent; 110 of 190 TV rows; 3 adjudication.` passes clean, and `7`
  and `3` are not historical values of anything.
- The declaration binds **no metric and no expected value**. It cannot state "this site is
  allowed to say `div=9`"; it says "anything near this string is fine".
- **The file already contains the correct pattern and it was not applied here.** The
  `PREV_LABEL` baseline exclusion asserts an exact multiplicity —
  `if len(prev_lines) != 2: fail("exclusion set has drifted")` (`:394-398`). The declared
  exemptions have no multiplicity bound, so the exemption can silently widen from 2 sites
  to N without any signal. That asymmetry, inside one file, is the finding.

**Fix, in preference order:** (1) apply the `PREV_LABEL`-style historical-column filtering
to `pr-description.md` as well as `evidence-report.md` — `docs_no_prev = pr + "\n" +
ev_no_prev` currently filters only the evidence report, which is the entire reason the
exemption is needed — with the same exact-count assertion; or (2) if a declaration must
stay, make it a 4-tuple `(fragment, metric, expected_wrong_value, exact_site_count)` and
`fail()` when the observed site count differs, so it cannot widen.

### B-5 — advisory CI step · **NOT CLOSED. This is mechanism number five.**

The `if: ${{ !cancelled() }}` change is correct and the step does now run. The claimed
closure is that it reports `success` where it previously reported `skipped`. That closure
criterion measures the wrong thing. Here is the **complete** verifier output from the step,
at `covered_sha`, in **both** runs (`31341597048` push, `31341598764` pull_request):

```
branch 'develop' set up to track 'origin/develop'.

REFUSED — no open pull request found for current branch.
  Create a PR first, or pass --pr N explicitly.
  (gh said: gh: To use GitHub CLI in a GitHub Actions workflow, set the GH_TOKEN
   environment variable. Example:
  env:
    GH_TOKEN:)
verify-evidence-figures: REFUSED (context not applicable — not a failure)
```

The verifier ran zero checks. It could not ask GitHub anything. The step is green.

This is structural, not a transient environment glitch:

- The step sets **no `GH_TOKEN`**, the job grants **`permissions: contents: read`** only,
  and `Checkout` uses **`persist-credentials: false`** (`ci.yml:212-218`). `gh` can never
  authenticate in this job as configured.
- The verifier collapses three semantically different conditions into exit 2:
  benign context (on `develop` / nothing ahead), **environment failure** (`gh` missing,
  `gh` unauthenticated, unparseable metadata), and **self-diagnosed verifier bug**
  (`"possible bad JSON field name in verifier"`, `:284-289`). The CI wrapper maps
  exit 2 → "not a failure" → success.
- Consequence: **a broken verifier reports success in CI.** Mutate `headRefOid`→`headSha`
  and CI stays green — exit 2, "not a failure" — while the only thing that catches it
  (`test-vef.py`) is run by nothing (S2-3). B-2's structural guarantee and B-5's CI wiring
  each rely on the other, and neither is connected.
- Even with a token, `pull_request` runs checkout the **merge commit**, so `head` ≠ PR head
  and both the `headRefOid` coherence check and the `**Head SHA:**` artifact discovery
  refuse (exit 2 → green). The `pull_request` path is guaranteed-inert independent of auth.

Against lesson 60 this fails both durable designs: the bad state ("verifier inert") is
**representable as success**, and the probe (CI) **shares the failure classification** of
the thing it is validating. Cycle 1 said "wired but inert". After the fix it is wired,
running, still inert, and now indistinguishable from verified — which is worse for a human
reader than `skipped`, because `skipped` is honestly self-describing.

**Fix:**
1. `permissions: {contents: read, pull-requests: read}` and
   `env: GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}` on the step.
2. On `pull_request`, check out `${{ github.event.pull_request.head.sha }}` and pass
   `--pr ${{ github.event.pull_request.number }}`; or restrict the step to `push`.
3. **Split the exit codes.** `2` = benign context only. Add `3` = environment/tooling
   unavailable and `4` = self-diagnosed verifier bug. The CI wrapper must **fail** (or at
   minimum emit `::error`) on 3 and 4, and must never print a success line for them.
4. Add a `test-vef.py` step to CI so B-2's probe is actually executed (closes S2-3).

---

## 3. Answers to the six questions asked

**1. Is B-3's structural guarantee real?** No. `checks_ran` has exactly one write path, so
that half is real. But "registered ⇒ compared" is false on the production path today:
`check2a-e-cli-001` registers with zero comparison because the real `pr-description.md`
never mentions `E-CLI-001`. The bypass did not need constructing — it is the shipped
behaviour of the run that exits 0.

**2. Did B-1's fix reopen anything, or over-fire?** It over-claims rather than over-fires.
No false positives observed. The declared exemption is not a D-039 violation — the entries
are printed loudly and stale-detection works — but it binds by ±40-char proximity rather
than by metric and value, so it suppresses arbitrary wrong figures near the fragment (P-D).
The file already demonstrates the correct discipline in `PREV_LABEL`'s exact-count
assertion; the exemptions have no multiplicity bound. **Stale-declaration detection does
fire correctly** — I confirmed both entries match live sites and are enumerated in output;
the mechanism is honest about *presence*, blind about *breadth*.

**3. Was the test fixture bent to fit?** **No — this one is legitimate.** The
historical-baseline table row added to `PR_FIXTURE` mirrors a row that genuinely exists in
`pr-description.md:135`, with the same shape and the same purpose. Without it the fixture
would be *less* realistic than the document it models, and the exemption would be
untested. This is fixture realism, not shaping. The criticism belongs on the exemption's
binding (finding B2-3), not on the fixture.

**4. Evidence integrity.** Mixed, with one hard failure.
- Live figures **match**: `79 reason-code + 6 E-class`, `pop=8/examined=6/skipped=2`,
  `174 compared / 42 divergent / 22 adjudication` all reproduced from live runs at
  `covered_sha`, and `AC-005`/`AC-006` contents match. The stale-78 problem that made
  GATE35's evidence unusable (D-177/D-181) is genuinely absent here — this PR carries 79.
- `AC-001`/`AC-005`/`AC-006` are provenance-stamped at `16b3513` and pass
  `check7-provenance-stamps`, i.e. their content is verified obtainable at that commit.
  Nothing looks copied or extrapolated.
- **`AC-002` and `AC-007` are unstamped and outside `STAMPED`** — the two artifacts holding
  the headline figures (99/99 and 26/26) are the two that carry no provenance guarantee.
  `AC-002` is additionally a 3-line excerpt starting mid-output, not a run capture.
- **`**Captured at SHA:** 3dc681b` is false** (B2-4): the evidence directory did not exist
  at that commit and the suite had 21 tests. This is the finding that matters most for
  "was anything extrapolated" — the report attributes a 26/26 result to a commit where it
  was not obtainable.
- **AC-002 vs AC-007 distinction: stated honestly, not conflated.** `AC-2 | Nine-checker
  selftest suite: 99/99` vs `AC-7 | VEF selftest suite: 26/26`, separate file descriptions,
  separate sections (`## Selftest Run (99/99 confirmed)` / `## VEF Selftest Evidence`), and
  the pre-merge checklist labels them distinctly. I looked for the conflation and did not
  find it. Related gap: the verifier validates the 99/99 figure against a live run and
  validates 26/26 against nothing (S2-2).

**5. S-1 residual — is leaving `check7-provenance-stamps` unregistered acceptable?**
Leaving it **out of `REQUIRED_CHECKS`** is acceptable and arguably correct: it is skipped
in test mode, so registering it would make the gate fire on every test run and force a
test-mode exemption — a worse shape. The **real** hole is not registration, it is that the
only check reading git object content has **zero test coverage** and does not cover the two
artifacts that carry the headline numbers. B2-4 is what that hole costs: a wrong
provenance SHA shipped, and no test would have caught it. Recommended: add `AC-002` and
`AC-007` to `STAMPED`, and add a test mode that runs the check against a throwaway git repo
in the tmpdir instead of skipping it. Suggestion, not blocking on its own — but it is the
enabling condition for B2-4, so it should be fixed in the same round.

**6. Mechanism number five — found?** **Yes, two.**
- **5(a), the primary one (B2-1):** exit-code conflation plus an unauthenticated CI step.
  A verifier that cannot run — including one that has diagnosed *itself* as buggy — exits 2,
  and CI prints "not a failure" and goes green. B-5's fix is what made this path reachable:
  before, the step was skipped, so the exit-code semantics never mattered. The fix
  converted an honestly-inert step into a dishonestly-green one. Evidenced in both CI runs
  at `covered_sha`, not inferred.
- **5(b) (B2-3):** the declared-exemption channel. Round 5 introduced a suppression that
  exempts by textual proximity with no metric binding, no value binding, and no
  multiplicity bound — in a file that already contains the correctly-bounded version of the
  same idea 300 lines earlier.

The four-round lineage therefore continues to five. The pattern across all five rounds is
constant and is worth naming: **each round's fix is verified against the enumerated failure
list, and the verification is then described in the code as a structural guarantee.** Four
of the five fixes in this round carry a comment asserting something is "unrepresentable"
(`:48`, `:499`, `:771`, `:1035`); three of those four assertions are false as shipped
(B2-2, B2-3 twice). The durable move is not another round of cases — it is to stop writing
the word "unrepresentable" unless a *type or a single code path* makes it so, and to accept
"validated against these N shapes" as the honest description of everything else.

---

## 4. Prescribed fix order

Ordered so each step's verification is not invalidated by the next.

1. **B2-1 (CI wiring + exit-code split).** Do this first: it is the only finding whose fix
   changes what CI can tell you about all the others. Split exit codes 2/3/4, fail CI on
   3/4, add `GH_TOKEN` + `pull-requests: read`, handle the `pull_request` merge-commit case,
   and add a `test-vef.py` CI step (closes S2-3 in the same edit). Add a `test-vef.py` case
   asserting an environment failure yields the env exit code, not the benign one.
2. **B2-2 (registration ⇒ comparison).** Route registration through the comparison helper,
   or move absence-assertions to a separate registry. Then correct the docstring at
   `:37-50` and the coverage count at `:133-145`. Add a test that a check reaching no
   comparison fails the gate — the current suite cannot detect this class.
3. **B2-4 + S2-1 (provenance).** Pin `**Captured at SHA:**` to the AC artifacts' stamp
   value; add `AC-002`/`AC-007` to `STAMPED`; give `check7-provenance-stamps` real test
   coverage. **Then correct `evidence-report.md` to the true capture SHA** and re-capture
   `AC-002` as a full run rather than an excerpt (closes S2-4).
4. **B2-3 (novel-spelling breadth).** Apply `PREV_LABEL` filtering to `pr-description.md`
   with an exact-count assertion so the exemption becomes unnecessary; if any declaration
   survives, bind it to `(fragment, metric, expected_value, exact_count)`. Make the ADR
   scan span-granular and per-metric to match the EI side. Add the six probe shapes above
   as paired controls.
5. **B2-5 + S2-2 + S2-5 (documentation and honesty).** Correct the Risk Assessment ("no CI
   workflow changes" → the ci.yml change, listed in Systems affected); either derive 26/26
   from a live run or state in `evidence-report.md` that it is unverified; drop the unused
   `key` parameter from `anchor_check`.
6. Re-run: `test-vef.py`, the end-to-end no-flag run, and **read the CI advisory step's log
   body** — not its status — to confirm it now prints `verify-evidence-figures: PASS`.

Explicitly out of scope per the cycle-2 mandate and not raised as blocking: cycle-1 NIT-A
and NIT-B (D-183, `scripts/spec-lint/` frozen for PR #13); the three tracked `develop`
spec-lint failures (D-128); the `spec-lint` REQUIRED flip (D-117/D-122/D-133).

---

## 5. Checklist (8 items)

| # | Item | Result |
|---|---|---|
| 1 | Diff coherence | **PASS.** All 10 files relate to sweep step 0. The one cross-story edit — GATE35 `evidence-report.md`, removing "99/99 selftests" from the AC-1 row — is cycle-1's endorsed NIT-E fix. `scripts/spec-lint/` and `.factory/specs/` untouched, as claimed. |
| 2 | Description accuracy | **FAIL** — B2-5 (Risk Assessment denies the CI workflow change that is the B-5 fix) and B2-1 (B-5 closure claim rests on step status, not step behaviour). |
| 3 | Test coverage | **PARTIAL.** 26 paired tests, real defect/clean pairs, no vacuous asserts. Gaps: `check7-provenance-stamps` (zero coverage), register-without-comparing (undetectable by the suite), the six B2-3 shapes, environment-failure exit classification. |
| 4 | Demo evidence | **PARTIAL.** CLI-tool evidence as `.txt` is correct for this artifact class (no `.gif`/`.webm` expected). 5 ACs covered, 3 provenance-stamped and verified. Fails on B2-4 (false capture SHA) and S2-4 (`AC-002` excerpt). |
| 5 | Commit quality | **PASS.** 11 conventional commits, all scoped `gate42/sweep-step0`, each naming its finding (B-1..B-5). Readable history. |
| 6 | Diff size | **NOTED** — 2,048 insertions (N2-1). Justified by the new test file and captured output. |
| 7 | Missing changes | **PASS** against the stated scope; the shortfalls are quality of closure, not absent work. |
| 8 | Dependency status | **PASS.** GATE35 (`2ac2c3e`) merged; branch is 11 commits ahead of `develop` with no unmerged upstream dependency. |

---

## 6. Blocked, denied, or refused commands — recorded verbatim

No command issued during this review was denied by the auto-mode classifier. Nothing was
retried to satisfy a checker, and no control was routed around.

Per gate-#28 v3 I did **not** attempt `gh pr review --approve` / `--request-changes`
(structurally impossible per BI-039/D-021/D-105 — self-authored PR) and did **not** post
any PR comment. This audit file is the deliverable.

**BI-060 defect c / D-182 — hook note:** this artifact is deliberately named
`pr-review-cycle2.md`, following the GATE35 cycle-keyed precedent (`pr-review-cycle7.md`).
The `validate-pr-review-posted` hook matches the literal filename `pr-review.md` and will
therefore false-negative on this name. **I did not rename the artifact to silence the
hook.** Any hook output produced by writing this file is recorded verbatim below.

> (no hook block or message was returned to me at write time)

---

## 7. Working tree at review time

Clean at `7739995e7e3f25c0af3dd9bcad535af2a7774fbb`; no source file was modified by this
review. The only writes were this audit file and two scratch files under `/tmp`
(`/tmp/probe-vef.py`, `/tmp/vef-live.txt`).

---

## Bottom line

`covered_sha: 7739995e7e3f25c0af3dd9bcad535af2a7774fbb` — **REQUEST_CHANGES**.

Real progress: `39efec2` is gone, the field contract is a genuine single-source-of-truth
probe, the empty-set and bare-`if` fail-open holes are closed, live figures are correct at
79, and the suite's 26 tests are honest paired controls. The blocking problems are all one
problem wearing four hats: **the closure criterion each fix was verified against is weaker
than the guarantee the code claims.** The step that "runs" verifies nothing; the registry
that "cannot register without comparing" does exactly that on the production path; the scan
whose miss is "unrepresentable" misses six shapes; and the provenance check that replaced a
circular predicate passes a provenance claim that is false. Fix B2-1 first — until CI can
distinguish a working verifier from a broken one, no later round's green means anything.
