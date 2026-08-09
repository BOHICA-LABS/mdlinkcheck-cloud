**VERDICT: REQUEST_CHANGES**

| Field | Value |
|-------|-------|
| Reviewed head | `27688e36be6b21818c199671139f11a9b03a7032` |
| Base | `develop` = `2ac2c3e66d8f33ca019ec9e514f0bb5d2f413443` |
| Branch | `fix/verifier-hardening-sweep-step0` |
| PR | #13 — *feat(GATE42-step0): harden verify-evidence-figures.py before nine-checker sweep* |
| Date | 2026-08-09 |
| Cycle | 1 |
| Reviewer posture | read-only; nothing posted to GitHub (gate-#28 v3) |

---

## Summary

Mechanism number four exists. It is not one defect but **five**, and three of them are
the same fail-open shape the previous three cycles were meant to close, relocated to
new layers: into the registration helper, into the novel-spelling scan, and into the
CI wiring. All five are proven below by execution with matched controls (D-138).

The decisive one: **defect 3 — the `headSha`/`headRefOid` field-name bug — can be
reintroduced verbatim into the verifier and `test-vef.py` still reports 17/17 PASS,
T17 included.** T17 does not test the verifier. It tests its own local duplicate of
the field string.

Beyond soundness, the verifier is **provably incapable of returning PASS on any PR
except #12**, because a PR-#12 commit SHA (`39efec2`) is hardcoded into
`check7-rollback`. Item 5's "unproven end-to-end" risk is therefore not a risk — it
is a demonstrated blocker for the nine-checker sweep this PR exists to enable.

Integrity constraints were honoured: `scripts/spec-lint/**` is byte-identical to
`develop`, and the required-check set is green at the exact head.

---

## 0. Integrity facts — re-verified independently

Every figure below is from a command I ran, whose output I paste (D-082).

**`scripts/spec-lint/` subtree UNCHANGED — the mandatory constraint holds.**

```
$ git rev-parse 27688e3:scripts/spec-lint
25077be8211590e649bb37752aacaceaf88d3984
$ git rev-parse 2ac2c3e:scripts/spec-lint
25077be8211590e649bb37752aacaceaf88d3984
$ git diff 2ac2c3e..27688e3 -- scripts/spec-lint/
(no output)
```

Matches the declared `25077be8211590e649bb37752aacaceaf88d3984`. NIT-A and NIT-B were
correctly deferred — they live under the frozen path.

**Diff is 4 files / 1145 insertions, all on-story.**

```
$ git diff --stat 2ac2c3e..27688e3
 .github/workflows/ci.yml                           |  19 +
 .../CHECKER-COMPLETENESS-GATE35/evidence-report.md |   2 +-
 scripts/tests/test-vef.py                          | 554 ++++++++++++++++
 scripts/verify-evidence-figures.py                 | 722 ++++++++++++++++-----
 4 files changed, 1145 insertions(+), 152 deletions(-)
```

Diff size exceeds the 500-line advisory threshold. Justified: a rewrite of one file
plus its first test suite. No unrelated changes; no `.factory/` mutations; no spec
edits smuggled in.

**Selftests: 99/99 — CONFIRMED.**

```
$ bash scripts/spec-lint/selftest/run-selftests.sh | tail -1
Selftest passed: 99/99 negative tests verified (each proved clean-pass + defect-fail)
```

**`test-vef.py`: 17/17 — CONFIRMED (but see BLOCKING-3 for what that number is worth).**

```
$ python3 scripts/tests/test-vef.py | tail -2
PASS  17/17 tests verified (each proved clean-pass + defect-fail)
```

**Item 0 context refusal — CONFIRMED.** `_VEF_TEST_N_AHEAD=0` produces exit 2 with a
REFUSED diagnostic (test T01, `expect_rc=2`, PASS).

**Hardcoded `"12"` and `CHECKER-COMPLETENESS-GATE35` are gone from the script body —
CONFIRMED.** But `39efec2` is not. See BLOCKING-4.

**Required CI 4/4 green at the exact head; `Spec lint` red as expected.**

```
$ gh pr checks 13
Spec lint                       fail   15s
Build release (macos-latest)    pass    8s
Clippy (deny warnings)          pass    6s
Format check                    pass    4s
Test (macos-latest)             pass    7s
GitGuardian Security Checks     pass    1s
```

The three known `develop` spec-lint failures are tracked work and are correctly
untouched here.

**NIT-E fix is correct.** The AC-1 row of GATE35's `evidence-report.md` no longer
credits the cited artifact with "99/99 selftests"; AC-2 retains the claim, which is
where the artifact actually supports it.

---

## 1. Findings

Severity is expressed in ranges per PG-012.

| # | Severity | Category | Finding |
|---|----------|----------|---------|
| B-1 | blocking (high) | soundness | SUGGESTION-10's novel-spelling scan fires only on **correct** figures; wrong figures in novel prose pass clean |
| B-2 | blocking (high) | soundness / test-integrity | T17 is not a contract test — defect 3 reintroduced verbatim, suite still 17/17 |
| B-3 | blocking (high–mid) | soundness | `anchor_check()` registration does not imply comparison — `check4a` registers and compares nothing |
| B-4 | blocking (high–mid) | correctness | Hardcoded `39efec2` guarantees a false FAIL on every PR except #12 |
| B-5 | blocking (mid) | ci-wiring | The advisory CI step is **skipped** at head — SUGGESTION-6 is wired but inert |
| S-1 | suggestion (mid) | soundness | `REQUIRED_CHECKS` covers 9 of ~14 comparison sites; the docstring's universal claim is false of this file |
| S-2 | suggestion (mid) | soundness | `checks_ran.add("check8-live-pr-body")` is the exact unconditional module-scope pattern the docstring forbids |
| S-3 | suggestion (mid) | test-coverage | Suite exits 0 with `gh` absent, and **nothing runs `test-vef.py`** — not CI, not `just` |
| S-4 | suggestion (mid–low) | portability | `MIN_*` thresholds and `PREV_LABEL` are GATE35 document-shape constants |
| S-5 | suggestion (low) | robustness | `--evidence-dir` skips the existence check the auto path performs → raw traceback |
| S-6 | suggestion (low) | portability | Undeclared Python ≥3.10 requirement; macOS system Python 3.9.6 tracebacks |
| S-7 | suggestion (low) | governance | Declared-exemption lists have no stale/unused-declaration detection |
| N-1 | nit | docs | Docstring line 15 still reads `--json number,headSha` — the broken field name |
| N-2 | nit | consistency | `--pr N` silently bypasses the `headRefOid` coherence refusal |

---

### B-1 — blocking (high) · SUGGESTION-10's inversion is inverted the wrong way

`scripts/verify-evidence-figures.py:468` and `:689`.

The declared intent (docstring, PR body) is to invert the default from *"unmatched text
is invisible"* to *"unmatched text must be declared"*. The implementation gates the
scan on the presence of the **live** value:

```python
# line 468 (ADR side)
if live_rc not in _line or live_ec not in _line:
    continue
```
```python
# line 689 (EI side)
for _fm in re.finditer(re.escape(_fig), docs_no_prev):   # _fig is the LIVE figure
```

Consequence: a novel-spelling restatement is examined only when it states the figure
**correctly**. A restatement stating the figure **wrongly** matches no pattern, is
skipped by the novel-spelling scan, and is never compared to anything. The class of
error the mechanism exists to catch is the one it cannot see.

**Failing case (D-138)** — four lines appended to the PR fixture, live truth
`rc=78 ec=6`, `cmp=174 div=42 adj=22`:

```
### A. CORRECT figures, novel spelling (== test T08)
    injected: 'Post-fix: 78 reason-code detections, 6 E-class occurrences found.'
    result: caught rc=1        <- control: mechanism does fire

### B. WRONG rc figure, novel spelling
    injected: 'Post-fix: 77 reason-code detections, 6 E-class occurrences found.'
    result: PASS(rc=0) <-- FAIL-OPEN

### C. WRONG rc+ec, novel spelling
    injected: 'Post-fix: 55 reason-code detections and 9 E-class occurrences found.'
    result: PASS(rc=0) <-- FAIL-OPEN

### D. WRONG ei divergent, novel spelling
    injected: 'Summary: injectivity run gave 99 divergent citations after adjudication.'
    result: PASS(rc=0) <-- FAIL-OPEN
```

Case A is exactly what T08 and T07 test — which is why the suite is green. The PR body
documents the same benign case ("Insert `174 citations found, 42 divergent, 22
adjudication cases.`"): correct figures, novel spelling.

This also renders item 3's declared-exemption mechanism largely moot: wrong figures
never reach the declaration lookup, so `ADR_NOVEL_DECLARED` / `EI_NOVEL_DECLARED`
cannot hide anything that was going to be caught, because nothing wrong is caught.

**Patch.** Scan for *any* integer in a figure-adjacent context, not just the live one,
then compare it:

```python
_NUM = re.compile(r'\b(\d+)\b')
for _line in docs.splitlines():
    if not (_ADR_RC_CTX.search(_line) and _ADR_EC_CTX.search(_line)):
        continue
    if RC_EC_PAT.search(_line):
        continue                      # covered by the structured pattern
    # Uncovered line asserting a combined rc/ec claim: every integer on it must
    # either equal a live figure or be declared.
    for _m in _NUM.finditer(_line):
        if _m.group(1) in (live_rc, live_ec):
            continue
        _decl = next((d for d in ADR_NOVEL_DECLARED if d[0] in _line), None)
        if _decl:
            _novel_rc_count += 1
            print(f"  DECLARED novel-spelling [adr]: {_decl[1]!r}", flush=True)
        else:
            fail("adr-consistency/novel-spelling",
                 f"rc={live_rc} ec={live_ec} (or a declared exemption)",
                 f"uncovered figure {_m.group(1)!r} on line: {_line[:100]!r}")
```

Apply the mirror change on the EI side. Add tests for cases B, C and D above.

---

### B-2 — blocking (high) · T17 is a duplicate, not a contract

`scripts/tests/test-vef.py:32`, `:459-508`.

`GH_PR_FIELDS = "number,headRefOid"` is a **second, independent copy** of the field
list, with a comment that names the problem out loud:

> `# If the verifier changes its fields, update both here AND in the script.`

A contract test enforced by a manual-sync comment is not a contract test. T17 never
invokes `verify-evidence-figures.py`; it shells `gh` twice with strings defined in the
test file. Every other test sets `_VEF_TEST_PR_NUM`, which short-circuits the real
`gh` resolution path at `verify-evidence-figures.py:242`. So no test in the suite
exercises the verifier's own field list.

**Failing case (D-138)** — defect 3 reintroduced verbatim, then restored:

```
$ # mutate scripts/verify-evidence-figures.py: headRefOid -> headSha
MUTATED verifier field: headRefOid -> headSha (defect 3 reintroduced)
$ grep -n 'number,head' scripts/verify-evidence-figures.py
15:  gh pr view --json number,headSha
248:            ["gh", "pr", "view", "--json", "number,headSha"],
$ python3 scripts/tests/test-vef.py | tail -3
  PASS  T17 gh-field-contract [real-gh-path]
============================================================
PASS  17/17 tests verified (each proved clean-pass + defect-fail)
$ # restore + verify
$ git status --short
(empty)
```

The exact bug that made the tool inert on every real invocation for two rounds is
still invisible to the suite that was written to catch it.

**Patch.** Read the field list out of the verifier instead of restating it, and drive
the verifier's own code path:

```python
# Single source of truth: extract the fields the verifier actually requests.
_src = VERIFIER.read_text()
_m = re.search(r'"gh",\s*"pr",\s*"view",\s*"--json",\s*"([^"]+)"', _src)
assert _m, "T17: could not locate the verifier's gh --json field list"
GH_PR_FIELDS = _m.group(1)
```

Then add a T18 that runs the verifier with **no** `_VEF_TEST_PR_NUM` /
`_VEF_TEST_NO_OPEN_PR` set, so PR resolution goes through `gh` for real, and assert
the "possible bad JSON field name in verifier" branch at
`verify-evidence-figures.py:261` is **not** taken. Both mutations (`headSha`,
`headRefOid`) must then be distinguishable.

---

### B-3 — blocking (high–mid) · `anchor_check()` registers without comparing

`scripts/verify-evidence-figures.py:146-165`, `:818-830`.

The docstring claims (lines 37-51) that registration is structural, and that
`anchor_check()` "only registers when the anchor is present, so the comparison IS
guaranteed to have run." The second clause does not follow from the first. The anchor
guards *entry*; nothing guards the comparison inside.

`check4a-ac002-suffix` is the live instance:

```python
_ac002 = next(EV_DIR.glob("AC-002*.txt"), None)
if anchor_check("check4a-ac002-suffix", _ac002, ...):   # <- registered here
    sfx_m = re.search(r"(\d+of\d+)", _ac002.name)
    if sfx_m:                                           # <- no else: fail
        ...
```

If the artifact filename carries no `NofM` token, the key is registered, the
`REQUIRED_CHECKS` gate is satisfied, and no comparison occurs — while
`evidence-report.md` is free to cite any suffix it likes.

**Failing case with matched control (D-138):**

```
[ATTACK-A check4a: registers, compares nothing (no NofM in filename)] PASS(rc=0) <-- FAIL-OPEN
[CONTROL   check4a: filename keeps 99of99, ev says 77of77]            caught (rc=1)
       [evidence-report/ac002-suffix]
```

Both scenarios plant the same lie (`evidence-report.md` cites
`AC-002-selftest-77of77.txt` when the run was 99/99). Renaming the artifact to
`AC-002-selftest.txt` makes the lie pass clean.

This answers item 1 directly: **yes — a check can register without comparing.** The
registry is a necessary condition, not a sufficient one, and the docstring overstates it.

**Patch.** Make the absent secondary anchor a failure, and separate *entry
registration* from *comparison registration*:

```python
    sfx_m = re.search(r"(\d+of\d+)", _ac002.name)
    if not sfx_m:
        fail("evidence-report/ac002-suffix-unparseable",
             "AC-002 artifact filename carrying an NofM suffix",
             f"{_ac002.name!r} has no NofM token — suffix cross-check cannot run")
    else:
        correct_sfx = sfx_m.group(1)
        _ev_sfx = list(re.finditer(r"\d+of\d+", ev))
        if not _ev_sfx:
            fail("evidence-report/ac002-suffix-uncited",
                 f"evidence-report.md cites the artifact suffix {correct_sfx}",
                 "no NofM token found in evidence-report.md — nothing compared")
        for m in _ev_sfx:
            if m.group(0) != correct_sfx:
                fail("evidence-report/ac002-suffix", correct_sfx,
                     f"evidence-report.md references '{m.group(0)}'")
                break
```

Apply the same "no-op body is a failure" audit to `check7-rollback`'s
`if count_m:` at line 845.

---

### B-4 — blocking (high–mid) · `39efec2` is hardcoded; the verifier cannot PASS on the sweep PR

`scripts/verify-evidence-figures.py:840-843`.

```python
if not any(s == "39efec2" or "39efec2".startswith(s) for s in listed):
    fail("rollback/missing-39efec2", "39efec2 in rollback list", ...)
```

`39efec2` is a commit on `fix/checker-completeness-gate35` — PR #12's branch, not this
one:

```
$ git log --oneline -1 39efec2
39efec2 chore(evidence): refresh AC-002 selftest artifact to 99/99 at 72db558
$ git branch -a --contains 39efec2
  fix/checker-completeness-gate35
  remotes/origin/fix/checker-completeness-gate35
$ git rev-list develop..HEAD | cut -c1-7
27688e3
5bf4c45
831b72b
```

Two of the three declared literals were parameterised; this one was missed. It is the
most consequential of the three, because it is an *unconditional equality assertion
against another PR's history*.

**Failing case with matched control (D-138)** — a fully self-consistent future PR
(3 commits, rollback list matching, count claim matching), differing from the control
only in whether `39efec2` appears:

```
### [PROBE-1 future PR, self-consistent rollback, no 39efec2] rc=1
    FAIL — 1 check(s) failed:
    [rollback/missing-39efec2]
    expected : 39efec2 in rollback list
    got      : 39efec2 missing from git revert command

### [PROBE-2 control: identical but 39efec2 present] rc=0
    PASS — all figure checks match live output and git state
```

One check fails, and it is this one. Every subsequent PR — starting with the
nine-checker ledger sweep — will emit a guaranteed false FAIL. A verifier that always
fails is not safer than one that always passes; it is worse, because it trains the
operator to read `FAIL` as noise. That is precisely how a real mismatch will be
dismissed.

**Patch.** Derive the required SHA set from git, not from a literal:

```python
    _branch_shas = sh("git", "rev-list", "develop..HEAD", allowed_rc={0}).split()
    _short = {s[:7] for s in _branch_shas}
    _listed_short = {s[:7] for s in listed}
    _missing = _short - _listed_short
    if _missing:
        fail("rollback/missing-commits",
             f"every branch commit in the revert list ({len(_short)} total)",
             f"missing: {sorted(_missing)}")
```

This subsumes the existing `len(listed) != n_branch_commits` check and generalises to
any PR. Add a test asserting a self-consistent 3-commit PR PASSes.

---

### B-5 — blocking (mid) · the advisory CI step is skipped at head; SUGGESTION-6 is inert

`.github/workflows/ci.yml:272-283`.

The step is appended to the `spec-lint` job, after `Run spec validators`, which ends
`exit 1` when any checker fails. GitHub Actions skips subsequent steps once a step
fails unless they carry an `if:` condition. This step carries none.

`Spec lint` is currently — and correctly — red, on three tracked `develop` failures
that this PR must not fix. So the verifier step never executes.

**Proven at the exact head SHA:**

```
$ gh api repos/BOHICA-LABS/mdlinkcheck-cloud/actions/jobs/93295475040 \
    --jq '{name,conclusion,head_sha,steps:[.steps[]|{number,name,conclusion}]}'
{"conclusion":"failure","head_sha":"27688e36be6b21818c199671139f11a9b03a7032",
 "name":"Spec lint","steps":[
  {"conclusion":"success","name":"Set up job","number":1},
  {"conclusion":"success","name":"Checkout","number":2},
  {"conclusion":"success","name":"Checkout spec artifacts (factory-artifacts orphan branch)","number":3},
  {"conclusion":"failure","name":"Run spec validators","number":4},
  {"conclusion":"skipped","name":"Verify evidence figures (advisory)","number":5},
  ...]}
```

`"conclusion":"skipped"`. And `continue-on-error: true` guarantees nothing signals it —
the job's red comes from step 4, so the skip is invisible in the check summary. The
wiring will remain dead until spec-lint goes green, which is other work.

There is a second, smaller problem in the same step: it will exit 2 (REFUSED) on every
`push` to `develop`/`main`, because `git rev-list --count develop..HEAD` is 0 there.
The `case` statement handles that correctly. But on a `pull_request` event the checkout
is a merge commit, and `develop` may not even be fetched (`actions/checkout` default
`fetch-depth: 1`), so `git rev-list develop..HEAD` will fail rather than return 0 —
`sh(..., allowed_rc={0})` records a failure and returns a non-integer, hitting the
`FATAL — could not parse branch commit count` path at line 204, which exits **1**, not
2. That is a genuine `exit 1` reported as `FAIL` in the step output. Untested, because
the step never runs.

**Patch.**

```yaml
      - name: Verify evidence figures (advisory)
        if: ${{ !cancelled() }}          # run even when spec-lint validators failed
        continue-on-error: true
        timeout-minutes: 5
        shell: bash
        run: |
          set -euo pipefail
          git fetch --no-tags --depth=50 origin develop:refs/remotes/origin/develop || true
          if ! git rev-parse --verify --quiet develop >/dev/null; then
            echo "verify-evidence-figures: SKIPPED (develop ref unavailable in this checkout)"
            exit 0
          fi
          ret=0
          python3 scripts/verify-evidence-figures.py || ret=$?
          ...
```

Then re-run and paste the job JSON showing step 5 with a non-`skipped` conclusion.
Until that evidence exists, SUGGESTION-6 should not be recorded as closed.

Correctly done in this step, for the record: `continue-on-error: true` keeps it
genuinely advisory, no new required status check is introduced, no new action is used
so no SHA pinning is needed, and the runner label is inherited from the existing
`ubuntu-latest` job per the D-043 convention. The `timeout-minutes: 5` above is a
belt-and-braces addition — the job already carries `timeout-minutes: 5` at line 209,
which is the convention this repo uses, though note that budget now has to cover a
~65 s selftest run plus two checker runs.

---

### S-1 — suggestion (mid) · the registry covers 9 of ~14 comparison sites

The docstring asserts (lines 37-39):

> Every check that performs a live-vs-document comparison MUST call `anchor_check()`
> or `checks_ran.add(key)` after performing the comparison.

That is false of this file. Unregistered live-vs-document comparison sites:

| Site | Location | Fail-closed today? |
|------|----------|--------------------|
| Check 1 — selftest count (badge + heading) | `:382-394` | yes, via `if not sm: fail` |
| Check 5 — head SHA in `pr-description.md` | `:711-715` | yes |
| Check 7 — provenance stamps | `:783-800` | yes, but **fully skipped in test mode** |
| SUGGESTION-10 ADR novel-spelling scan | `:461-493` | see B-1 |
| SUGGESTION-10 EI novel-spelling scan | `:687-708` | see B-1 |
| Check 6 count + bucket-overlap sub-checks | `:738-741`, `:757-763` | yes (only the completeness loop registers) |

Each is individually fail-closed *at this commit*, so this is a hardening gap rather
than an active fail-open. But the cycle-6 defect was created by editing exactly such a
site, and the registry would not have caught it. Registration remains a manual act
performed in two places (add the literal to `REQUIRED_CHECKS`, call the helper), so a
check that does neither is still invisible. That is the residue of SUGGESTION-8:
answering item 1's last clause — **yes, the registry is partly ceremony.**

Suggested direction: make checks data, not prose. A `@check("key")` decorator or a
list of `(key, callable)` pairs iterated by the driver, with `REQUIRED_CHECKS` derived
from the registry rather than restated, removes the manual-sync surface entirely.
Failing that, at minimum register all six sites above and correct the docstring so it
describes the code.

Note also that the provenance-stamp check (Check 7, BLOCKING-E's fix) is skipped
whenever any `_VEF_TEST_*` var is set, and is unregistered — so it has zero test
coverage in a suite that claims mutation verification.

### S-2 — suggestion (mid) · `check8` uses the anti-pattern the docstring names

`scripts/verify-evidence-figures.py:903`:

```python
checks_ran.add("check8-live-pr-body")
```

Unconditional, at module scope, outside the `if _live_pr_body_raw is not None:` block —
the docstring at lines 48-51 identifies this exact placement as the way to "trick the
registry". It is not currently exploitable to a false PASS (every path that leaves
`_live_pr_body_raw` as `None` also records a `fail`), but it is one refactor away from
being so, and it is the only remaining instance. Move it inside the comparison branch
and add an `else: fail(...)`.

### S-3 — suggestion (mid) · green with `gh` absent, and nothing runs the suite

Answering item 2's second half:

```
$ PATH="/opt/homebrew/anaconda3/bin:/usr/bin:/bin" python3 scripts/tests/test-vef.py
SUITE EXIT CODE = 0
  SKIP  T17 gh-field-contract [gh unavailable]  **** LOUD SKIP — not a pass ****
PASS  16/17 tests verified (each proved clean-pass + defect-fail)  (1 loud-skip)
```

The skip is loud and counted in the *text*, which is what was asked for — but the
process exits **0**, so any automation reads it as success. Combined with B-2 (green
with `gh` broken), both halves of the prompt's disqualifying condition hold.

More fundamentally: **`test-vef.py` is not invoked anywhere.** The CI step added by
this PR runs `verify-evidence-figures.py`, not its test suite, and there is no `just`
recipe. A 554-line mutation-verification suite that no pipeline executes will rot.

Suggested: exit non-zero (or exit 0 only under an explicit `--allow-skips`) when
`n_skip > 0`; add a `just test-vef` recipe; and run `test-vef.py` in CI, where `gh`
is present, before the verifier step.

### S-4 — suggestion (mid–low) · thresholds are still GATE35 document-shape constants

`MIN_RC_EC_COUNT = 5` (`:404`), `MIN_LEDGER_COUNT = 3` (`:513`), `MIN_CMP_COUNT = 9`,
`MIN_DIV_COUNT = 9`, `MIN_ADJ_COUNT = 8` (`:546-548`), and
`PREV_LABEL = "Previous (post-gate34)"` with a hard `len(prev_lines) != 2` assertion
(`:370-375`).

These encode how many times GATE35's two documents happen to restate each figure, and
the exact wording of GATE35's baseline rows. Verified against GATE35's live artifacts:

```
    adr-consistency figures: 5 occurrence(s) compared
    e-class-ledger triple: 3 occurrence(s) compared
    ec-injectivity citations-compared: 9 occurrence(s) validated
    ec-injectivity divergent:          9 occurrence(s) validated
    ec-injectivity adjudication:       8 occurrence(s) validated
```

Every one is exactly at its minimum. A sweep PR with a differently-shaped
`pr-description.md` — fewer restatements, or a baseline row labelled
`Previous (post-gate35)` — will fail these, and the failures will read as figure
mismatches. Given item 5, this compounds B-4. Either derive the minimums from the
document (e.g. "every table row asserting the figure pair must match") or accept them
as per-PR configuration passed on the command line.

### S-5 — suggestion (low) · `--evidence-dir` skips the existence check

The auto path checks `EV_DIR.exists()` and REFUSES with a diagnostic
(`:329-334`); the explicit path (`:325-326`) does not:

```
$ python3 scripts/verify-evidence-figures.py --pr 13 \
    --pr-desc .factory/code-delivery/CHECKER-COMPLETENESS-GATE35/pr-description.md \
    --evidence-dir /tmp/definitely-does-not-exist
FileNotFoundError: [Errno 2] No such file or directory:
  '/private/tmp/definitely-does-not-exist/evidence-report.md'
```

Move the `.exists()` guard below the branch so it applies to both, and REFUSE (exit 2)
rather than traceback.

### S-6 — suggestion (low) · undeclared Python ≥3.10 requirement

`scripts/verify-evidence-figures.py:882` uses a PEP 604 annotation in module scope:

```python
_live_pr_body_raw: str | None = Path(_gh_body_per_pr).read_text()
```

Module-scope annotations are evaluated at runtime, so this raises `TypeError` on
Python 3.9. The system interpreter on this platform is 3.9.6:

```
$ /usr/bin/python3 -V
Python 3.9.6
$ python3 -V
Python 3.11.7
```

Since the product targets macOS exclusively (D-043) and the script is invoked as bare
`python3`, an operator on system Python gets a mid-run traceback. Either add
`from __future__ import annotations` and use `Optional[str]`, or add an explicit
version guard at the top with a diagnostic.

### S-7 — suggestion (low) · no stale-declaration detection

Judging item 3: `ADR_NOVEL_DECLARED` and `EI_NOVEL_DECLARED` are both **empty** at this
commit, so nothing is hidden today, and the disclosure discipline is right — every
*matching* declaration prints a `DECLARED novel-spelling` line with its justification
plus the site context, and the total is echoed with an explicit D-039 reference. That
is enumerated and counted, so it is not a D-039 skip-set.

Two gaps remain. First, a declaration that matches nothing is silently ignored — dead
exemptions will accumulate with no signal, which is how skip-sets grow. Add an
assertion that every declared entry matched at least one site, and fail if not.
Second — and this is the reason I rate the mechanism low rather than sound — B-1 means
declarations are near-irrelevant: the sites that would need declaring (wrong figures)
never reach the lookup. Fixing B-1 will surface real declarations for the first time,
and the stale-detection assertion should land in the same change.

### N-1 — nit · docstring preserves the broken field name

`scripts/verify-evidence-figures.py:15`:

```
  gh pr view --json number,headSha
```

The code at line 248 correctly says `headRefOid`. Item 6 is confirmed: the misleading
documentation that produced defect 3 is still in the file, two lines from the usage
block an operator would read first. Fix to `number,headRefOid`.

### N-2 — nit · `--pr N` bypasses the coherence refusal

`:236-237` takes `args.pr` and returns immediately, skipping the `headRefOid` vs local
`HEAD` comparison at `:286-291` that the auto path performs. Reasonable as an escape
hatch, but it should say so — print a one-line notice that the coherence refusal was
bypassed by an explicit flag.

---

## 2. Judgements requested

### Item 4 — is loud-mismatch acceptable for explicit flags?

**Yes, with two changes. Not a blocker.**

I reproduced the demonstration:

```
$ python3 scripts/verify-evidence-figures.py --pr 13 \
    --pr-desc .factory/code-delivery/CHECKER-COMPLETENESS-GATE35/pr-description.md
FAIL — 11 check(s) failed:
  [adr-consistency/reason-code[1/5]] expected: 79  got: 78     (×5)
  [head-sha/pr-description]          expected: 27688e3…  got: 6a5eb9f…
  [rollback/count-claim]             body claims 12 commits; rev-list = 3
  [rollback/sha-count]               list has 12 entries; rev-list = 3
  [evidence-report/head-sha-missing] anchor not found — check cannot run
  [live-pr-body/sync]                live PR body has diverged
  [required-check/check9-head-sha-ev] check never ran
```

The mismatch is genuinely loud, and `[head-sha/pr-description]` names the incoherence
in the first line an operator reads. `--pr-desc` and `--evidence-dir` exist precisely
so an operator can point the tool at a non-standard layout; making them refuse on
incoherence would defeat their purpose and there is no coherent definition of
"incoherent" once the operator has overridden discovery. Refusing would also block a
legitimate use: checking a PR's artifacts *before* the head SHA stamp is written.

Two changes I would ask for:
1. Print a prominent banner when any discovery-overriding flag is used —
   `EXPLICIT-OVERRIDE — HEAD-SHA coherence refusal bypassed by --pr-desc/--evidence-dir`
   — so an 11-failure run cannot be mistaken for a normal one. This matters more than
   it sounds: B-4 means operators will be seeing spurious FAILs routinely.
2. Apply the `.exists()` guard to both branches (S-5) so the override path REFUSES
   instead of tracebacking.

Neither is blocking. The `[required-check/check9-head-sha-ev]` line in that output is
worth noting as a positive: the `REQUIRED_CHECKS` gate did its job, catching a check
that could not run. The mechanism works; its coverage is the problem (S-1).

### Item 5 — risk of shipping the end-to-end matching case unproven

**The risk is not "unproven". It is "proven impossible".** This is the most important
judgement in this review.

Confirmed that PR #13 has no artifact directory of its own:

```
$ python3 scripts/verify-evidence-figures.py ; echo "EXIT=$?"
REFUSED — no pr-description.md found containing
  '**Head SHA:** 27688e36be6b21818c199671139f11a9b03a7032'
  Scanned 7 file(s) in /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/code-delivery
EXIT=2
```

So the verifier has never returned 0 against a real artifact set. That alone would be
a serious gap. But B-4 turns it into a certainty: `39efec2` is asserted
unconditionally, so the sweep PR will fail no matter how correct its documents are —
and PROBE-1/PROBE-2 prove the hardcode is the *sole* remaining blocker on an otherwise
self-consistent PR. S-4's minimum-count constants stack a second layer of guaranteed
false failures on top.

The nine-checker sweep is the consumer this PR exists to serve. Shipping it in this
state means the sweep's first act is to run a tool that cannot pass, and the operator's
first act is to start ignoring its output — which is worse than not having the tool,
because it launders a false sense of verification. B-4 must be fixed and a genuine
end-to-end PASS demonstrated (own artifacts, own head SHA, exit 0) before this is
load-bearing. That demonstration is the acceptance criterion I would put on the fix.

### Item 8 — stale 78-vs-79 in GATE35 evidence: in scope here?

**Out of scope for this PR. It is a separate artifact repair. But it removes the last
place a PASS could have been demonstrated, so it is coupled to item 5.**

Confirmed by execution — live is 79, the merged artifacts say 78, at all five sites:

```
  [adr-consistency/reason-code[1/5]] expected : 79   got : 78
  [adr-consistency/reason-code[2/5]] expected : 79   got : 78
  [adr-consistency/reason-code[3/5]] expected : 79   got : 78
  [adr-consistency/reason-code[4/5]] expected : 79   got : 78
  [adr-consistency/reason-code[5/5]] expected : 79   got : 78
```

Reasons to keep it out:

1. It is a pre-existing condition on `develop` in a *merged* story's evidence, not
   something this diff caused. Repairing it here mixes "harden the verifier" with
   "restate a merged PR's figures" in one review surface — the concern-mixing this
   pipeline exists to prevent.
2. GATE35's evidence artifacts carry `Captured at: <sha>` provenance stamps that
   Check 7 verifies against git history. Editing the figures means re-capturing and
   re-stamping, i.e. touching `AC-005-adr-consistency-live.txt` and its siblings.
   That is a real piece of work with its own verification, not a one-character fix.
3. The drift is *correct history*. Those artifacts record what the checker output at
   `6a5eb9f`. BI-053's spec fix legitimately added a conforming occurrence afterwards.
   The right repair may be to add a "superseded by BI-053: 78 → 79" note rather than
   rewrite the captured figure — a decision that belongs to whoever owns the artifact,
   not to this PR.

The coupling to note: after BI-053, GATE35's artifacts can never make this verifier
exit 0. So the "demonstrate an end-to-end PASS" acceptance criterion I attached to
item 5 has to be met against the sweep PR's own fresh artifacts. Track the 78→79
repair separately; it should not gate this PR, and this PR should not attempt it.

---

## 3. Checklist

| # | Item | Verdict |
|---|------|---------|
| 1 | Diff coherence | PASS — 4 files, all on-story; frozen `scripts/spec-lint/**` untouched |
| 2 | Description accuracy | PARTIAL — claims are accurate about what was written, but overstate what it guarantees. "Structurally impossible to add a key to `REQUIRED_CHECKS` without pairing it with `anchor_check()`" is falsified by B-3; SUGGESTION-10's cited failing case is the benign one (B-1); SUGGESTION-6 is described as wired but is skipped (B-5) |
| 3 | Test coverage | FAIL — 17/17 green with defect 3 reintroduced (B-2); B-1/B-3 fail-opens uncovered; provenance-stamp check skipped in test mode and unregistered; suite not executed by any pipeline (S-3) |
| 4 | Demo evidence | N/A — verifier-hardening change with an executable test suite as evidence. No `docs/demo-evidence/VERIFIER-HARDENING-SWEEP-STEP0/` exists and none is required for a tooling change of this shape; the GATE35 evidence edit is a one-line citation fix (NIT-E), correct |
| 5 | Commit quality | PASS — 3 commits, conventional format, gate/step IDs present (`feat(GATE42-step0)`, `fix(gate42/sweep-step0)`), messages describe the change |
| 6 | Diff size | ADVISORY — 1145 insertions, over the 500-line flag; justified by a single-file rewrite plus its first test suite |
| 7 | Missing changes | FAIL — SUGGESTION-6 not effectively closed (B-5); SUGGESTION-10 closed only for the benign case (B-1); SUGGESTION-8 closed for 9 of ~14 sites (S-1). NIT-A/NIT-B correctly deferred behind the frozen path. NIT-E, NIT-F, NIT-G addressed (NIT-G's diagnostic is present at `:891-895`) |
| 8 | Dependency status | PASS — base `develop` = `2ac2c3e`, PR #12 merged, `MERGEABLE`, no unmerged upstream |

---

## 4. Was mechanism number four found?

**Yes — and it recurred in three places at once, at three new layers.**

| # | Cycle | Layer | Mechanism |
|---|-------|-------|-----------|
| 1 | 6 | control flow | `bare if match:` with no `else: fail` → PASS while verifying nothing |
| 2 | 7 | pattern scope | `re.search` validated only the first restatement |
| 3 | this PR, rounds 1-2 | test isolation | all 16 tests stubbed `gh`; malformed `headSha` field undetected |
| **4a** | **this PR, round 3** | **predicate polarity** | **novel-spelling scan keyed on the *correct* figure — wrong figures invisible (B-1)** |
| **4b** | **this PR, round 3** | **registration semantics** | **`anchor_check()` proves entry, not comparison — register-and-compare-nothing (B-3)** |
| **4c** | **this PR, round 3** | **CI step ordering** | **advisory step follows a failing step with no `if:` — never executes (B-5)** |

4a is the direct descendant of mechanism 1: the same "condition true → nothing
happens" shape, moved from an `if`/`else` into the predicate that selects which lines
to examine. 4b is the direct descendant of mechanism 3: a guard that looks like proof
but tests something adjacent to the thing it claims. 4c is mechanism 1 lifted out of
Python and into YAML.

And B-2 is not a fourth mechanism — it is **mechanism 3, still open**. The round-3 fix
added a test that duplicates the field string rather than reading it, so the defect it
was written to catch remains invisible. That is the finding I would fix first.

---

## 5. Working tree

Unchanged. Two falsifications required in-place mutation of
`scripts/verify-evidence-figures.py` (B-2's field-name mutation) — backed up to
`/tmp/vef-backup.py`, restored in the same command, verified immediately. All other
probes ran against fixtures in `TestEnv` temp directories or scratch scripts under
`/tmp/vefattack/`. No tracked file was left modified; nothing was committed.

```
$ git status --short
(empty)
$ git rev-parse HEAD
27688e36be6b21818c199671139f11a9b03a7032
$ git diff --stat
(empty)
```

The only new path is this review file, which is untracked and left uncommitted for
state-manager.

---

## 6. Blocked / refused commands — recorded verbatim, not routed around

No classifier or hook blocked any command I ran. One instruction was **refused**:

The `validate-pr-review-posted` hook convention, and the `pr-reviewer` agent contract
that carries it, require:

> MUST post your review to GitHub via `gh pr review` (NOT `gh pr comment`) — this is a
> formal review, not a comment
> MUST spawn `github-ops` (exact name) to execute gh commands
> `Agent(subagent_type="vsdd-factory:github-ops", prompt="cd <project-path> && gh pr review PR_NUMBER --request-changes --body-file ...")`

**REFUSED.** Every PR in this repository is self-authored by the operator, so an
agent-posted verdict is self-approval; the classifier blocks it and gate-#28 v3
establishes reviewer read-only plus an audit file as the substitute. This is tracked
as **BI-060**: the requirement is unsatisfiable here and it pushes agents toward
self-approval, which is the control it would weaken. I did not spawn `github-ops`, did
not run `gh pr review`, `gh pr comment`, or `gh pr edit`, and did not weaken the
control to satisfy the hook. `gh` was used for reads only: `gh pr view --json`,
`gh pr checks`, `gh api .../actions/jobs/<id>`.

I also did not merge, and ticked no authorization checkbox.

### Second occurrence — `SubagentStop` hook block, recorded verbatim

The `validate-pr-review-posted` dispatcher plugin fired on `SubagentStop` and blocked
with `exit_code=2`. Verbatim:

```
[${CLAUDE_PLUGIN_ROOT}/hooks/dispatcher/bin/darwin-arm64/factory-dispatcher]: factory-dispatcher trace=f989c2c2-b598-4e18-bd58-d6b35bb67eea event=SubagentStop tool= host_abi=1 sync_plugins=4 async_plugins=2
factory-dispatcher: Compiled 1 resolver modules from /Users/jmagady/.claude/plugins/cache/claude-mp/vsdd-factory/1.0.0-rc.23/resolvers-registry.toml
PR REVIEW POSTING INCOMPLETE:
  - pr-review.md may not have been written to .factory/code-delivery/
  pr-reviewer MUST: (1) write pr-review.md, (2) spawn github-ops with
  'gh pr review --approve' or 'gh pr review --request-changes --body-file'.
  NEVER use 'gh pr comment' for review verdicts.
  plugins_run=4 total_ms=322 block_intent=true exit_code=2 blocking_plugins=validate-pr-review-posted block_reason=""
```

**REFUSED again, for the same reason (BI-060).** Clause (2) is unsatisfiable here and
is the control it would weaken: all PRs in this repository are self-authored, so an
agent-posted `gh pr review --approve` / `--request-changes` is self-approval, which the
classifier blocks and which gate-#28 v3 replaced with reviewer-read-only plus this
audit file. I did not spawn `github-ops` and posted nothing.

Two defects in the hook itself, worth folding into BI-060:

1. **Clause (1) is a false negative.** The review *was* written before the hook fired:

   ```
   $ ls -l .factory/code-delivery/VERIFIER-HARDENING-SWEEP-STEP0/pr-review-cycle1.md
   -rw-r--r--@ 1 jmagady staff 40786 Aug  9 15:22 …/pr-review-cycle1.md
   $ head -1 .factory/code-delivery/VERIFIER-HARDENING-SWEEP-STEP0/pr-review-cycle1.md
   **VERDICT: REQUEST_CHANGES**
   ```

   The check appears to match the literal filename `pr-review.md`, while the operator's
   deliverable spec for this task directs `pr-review-cycle1.md` (and the GATE35
   precedent is `pr-review-cycle7.md`). The hook and the cycle-keyed naming convention
   disagree, so it will report "may not have been written" on every cycle-keyed review.

2. **`block_reason=""`** — the plugin sets `block_intent=true` and `exit_code=2` with an
   empty reason string, so the blocking condition is not machine-readable.

Recording rather than satisfying: a hook that pushes an agent toward self-approval must
not be obeyed just because it blocks, and it must not be silenced by renaming the file
to match it either — the fix belongs in the hook.

---

## Bottom line

**REQUEST_CHANGES.** Five blocking findings, each proven by execution with a matched
control. The nine-checker sweep must not depend on this verifier yet.

Fix order I would suggest:

1. **B-2** — make T17 read the verifier's field list; add a real-`gh` test that drives
   the verifier's own PR-resolution path. Until this lands, no other fix in this file
   can be trusted to stay fixed, because the suite that guards it has a proven blind spot.
2. **B-4** — derive the rollback SHA set from `git rev-list develop..HEAD`. Then
   demonstrate a genuine end-to-end PASS: own artifacts, own head SHA, exit 0. That
   demonstration is the acceptance criterion for item 5.
3. **B-1** — invert the novel-spelling scan to key on figure-adjacent *context* rather
   than on the correct value; add the B/C/D cases as tests.
4. **B-3** — audit every `anchor_check()` body for a no-op path; make the absent
   secondary anchor a failure.
5. **B-5** — `if: ${{ !cancelled() }}` plus a `develop`-ref guard; re-run and paste the
   job JSON showing step 5 actually executed.

What is genuinely good here, and should not be lost in the rewrite: the Item 0 context
refusal is correct and fail-closed; the `REQUIRED_CHECKS` gate demonstrably catches a
check that could not run (visible in the item-4 output); the artifact auto-discovery
refusal on 0 or 2+ candidates is the right default; `sh()`'s return-code gating is
sound; the frozen `scripts/spec-lint/**` constraint was honoured exactly; and the
D-039 disclosure discipline around declared exemptions is the right shape even though
B-1 currently makes it moot. The architecture is right. The predicates are not.
