# PR Review — Cycle 6 (closing review)

**VERDICT: REQUEST_CHANGES** (2 blocking findings, both inside the newly-added
`scripts/verify-evidence-figures.py`; zero source change required in `scripts/spec-lint/`)

**Reviewed head:** `f6dfa582b3911ddce155921043efec0c429578d3` (`f6dfa58`)
**Base:** `develop` @ `da86271`
**Branch:** `fix/checker-completeness-gate35`
**Reviewed:** 2026-08-09

> Posted via `gh pr comment`. `gh pr review --approve` / `--request-changes` are structurally
> impossible on a self-authored PR here (BI-039 / D-021 / D-105). The `VERDICT:` line is the review
> verdict for gating purposes.

## Summary

Everything I raised in cycles 4 and 5 is now **RESOLVED**, and I verified each one by execution
rather than accepting the report. BLOCKING-B's arithmetic is correct, BLOCKING-C's new stamps survive
the same falsification test that condemned the old ones, and the spec-lint deliverable is untouched
and still sound.

**What blocks is the new verifier itself.** It contains a vacuous-gate hole of exactly the class this
PR spent three cycles eliminating: under a plausible failure mode it prints `PASS` while verifying
nothing. I proved this by execution. Its provenance check is also materially weaker than the finding
it was built to close — I reintroduced BLOCKING-C in a form the check accepts.

I recommended this tool, so I want to be direct: the idea was sound and the implementation is 80%
right, but shipping it with these two holes would propagate the very pattern we have been removing
into the nine-checker sweep that will depend on it. Both fixes are small and I give them below.

---

## 1. Prior findings — all RESOLVED

### BLOCKING-B (detection set / population arithmetic) — RESOLVED

`pr-description.md` now reads:

> Detection confirmed at: `BC-2.01.009.md:44,52,71,73`, `BC-2.11.004.md:61`, and
> `interface-definitions.md:237`. `BC-2.01.009.md:23` carries two further occurrences inside YAML
> frontmatter, excluded by the D-081 predicate and disclosed as `skipped=2`, bringing the corpus
> population to 8.

Six enumerated sites for six claimed occurrences; `BC-2.11.004.md:61` restored; and the
`population=8 / examined=6 / skipped=2` relationship is now stated correctly, with `:23` in the
excluded bucket where it belongs and its two codes accounted for. This matches a fresh live run
exactly. The self-contradiction is gone.

### BLOCKING-C (false provenance stamps) — RESOLVED, falsification-tested

The stamps are now `b4bbbc39cef22dbc25d150eec1a6e621a211847a`. I applied the **same standard** I used
to condemn `fd74bd7` rather than accepting the correction: I checked out the `b4bbbc3` spec-lint tree
and ran both checkers against the live corpus.

| | `check-adr-consistency` summary | `check-ec-injectivity` summary |
|---|---|---|
| `b4bbbc3` actual run | `9 violations (78 reason-code + 6 E-class …)`; `population=8, examined=6, skipped=2` | `174 compared … 42 divergent, 22 require adjudication` |
| AC-005 / AC-006 contents | **identical** | **identical** |

So `b4bbbc3` genuinely is a commit at which these artifact contents were obtainable. Contrast
`fd74bd7`, which produced **79** reason-code occurrences against the recorded 78 — the basis on which
I falsified the old stamp. Fixed correctly.

### Cycle-5 suggestions and nits — all RESOLVED

- **SUGGESTION-2** — `E-CLI-001` now attributed to `BC-2.11.004.md:61`, not `test-vectors`.
- **SUGGESTION-3** — `evidence-report.md` heading now `## Selftest Run (99/99 confirmed)`.
- **SUGGESTION-4** — `98of98` references gone; all read `99of99`, and the file exists.
- **NIT-D** — field relabelled `**Captured at SHA:**`.

### The four earlier RESOLVED adjudications — still hold

`scripts/spec-lint/` subtree hash is **identical** at `72db558`, `39efec2` and `f6dfa58`
(`25077be8211590e649bb37752aacaceaf88d3984`), so C1-BLOCKING-1/2, C2-BLOCKING-1/2 and both NITs are
mechanically preserved. Re-executed anyway at `f6dfa58`: suite **99/99**; ledger
`population=8, examined=6, skipped=2`; `9 violations (78 + 6)`; ec-injectivity `174 / 42 / 22`.

### Corrections to the handoff report

Two claims in the brief need adjusting, neither affecting the conclusion:

- **`.factory/` *is* gitignored.** `git check-ignore -v .factory` → `.gitignore:1:.factory/`. It is
  *both* an ignore entry and a separate worktree on `factory-artifacts` (`git worktree list`
  confirms the mount at `c8b37bc`). The implementer's premise was therefore not wrong, and claims
  resting on it do not need extra suspicion. Both mechanisms independently prevent this branch from
  touching `.factory/`, and `git diff --name-only da86271 f6dfa58 -- .factory/` is empty.
- **Frozen perimeter now confirmed directly** (I could not resolve this last cycle): the
  `factory-artifacts` worktree gives `specs` tree
  `ace1745871122cd1fa2c46cf27c5493cc1083411` — exactly the claimed value.

`pr-description.md` and the live PR body agree (they differ only by one trailing newline).
`- [ ] Operator merge authorization — pending` is unticked and unmodified. All four required CI checks
**SUCCESS** at `f6dfa58`; `Spec lint` FAILURE correct per D-128, widened counts intended per D-122.

---

## 2. Audit of `scripts/verify-evidence-figures.py`

### Credit first — what it genuinely does well

- Expected values really are derived from live runs and git state, never from the document under
  check. The `x == x` trap is avoided.
- **Positive control passed.** I reintroduced BLOCKING-B by deleting `BC-2.11.004.md:61` from the
  enumeration. Both arms fired with precise messages:
  `[enumerated-sites/count] expected: 6 sites … got: 5 sites found: [...]` and
  `[enumerated-sites/completeness] BC-2.11.004.md:61 missing from 'Detection confirmed at:' list`.
- The bucket-overlap check (lines 144-151) is a genuinely good idea — it structurally prevents the
  "validated *and* excluded" contradiction that was BLOCKING-B's third defect.
- Checks 1 and 6 correctly `fail()` when their pattern is absent.

### BLOCKING-D — Checks 2, 3, 4 and Check 6's completeness arm silently evaporate when live output is unparseable

**Severity:** blocking · **Location:** lines 61, 72, 88 (and 136)

Checks 2, 3 and 4 are each guarded by a bare truthiness test on the *live* regex match, with no
`else`:

```python
am = re.search(r"(\d+) violations found \(...\)", adr_out)
if am:            # ← if the live output does not match, the entire check vanishes
    ...
pop_m = re.search(r"population=(\d+), examined=(\d+), skipped=(\d+)", adr_out)
if pop_m:         # ← same
eim = re.search(r"(\d+) EC citations compared.*?", ei_out)
if eim:           # ← same
```

This is the asymmetry: Check 1 says `if not sm: fail(...)`, Check 6 says
`if not det_m: fail(...)`. Checks 2/3/4 say nothing.

**Proven by execution.** I ran the verifier with `sh()` stubbed so the selftest line stayed valid but
the two checkers' summaries were unparseable (simulating a future output-format change or a partial
failure):

```
Running selftest suite … / check-adr-consistency … / check-ec-injectivity …

PASS — all figure checks match live output and git state
EXIT=0
```

It verified **nothing** about the adr figures, the ec figures, or the E-class ledger, and reported
success. Silently lost in that state:

- Check 2 — reason-code and E-class occurrence counts
- Check 3 — the ledger triple **and** the `population == examined + skipped` invariant
- Check 4 — citations / divergent / adjudication
- Check 6's **completeness** arm — `live_e_sites` (line 136) becomes `[]`, so the loop body never
  runs and the exact BLOCKING-B guarantee disappears. (Check 6's *count* arm survives, since both
  operands come from the document.)

`sh()` compounds this: it runs without `check=True` and merges stdout+stderr, so a crashed or
non-zero checker is indistinguishable from normal output.

**Fix.** Give the three checks the same treatment Check 1 already has, and make `sh()` surface
failure:

```python
def sh(*cmd, timeout=180):
    r = subprocess.run(cmd, capture_output=True, text=True, cwd=REPO, timeout=timeout)
    if r.returncode not in ALLOWED_RC.get(cmd[-1], {0, 1}):
        fail(f"live-run/{cmd[-1]}", "checker exits 0 or 1", f"exit {r.returncode}")
    return (r.stdout + r.stderr).strip()

if not am:
    fail("adr-consistency/live", "violations-found summary line", "not parseable from live output")
else:
    ...
```

A completeness gate that cannot distinguish "verified" from "could not verify" is the defect this PR
exists to remove. It should not ship in the instrument built to prevent it.

### BLOCKING-E — Check 7's provenance test is weaker than the finding it closes

**Severity:** blocking · **Location:** lines 153-170

The check accepts a stamp if the SHA appears **anywhere in the artifact's git log**:

```python
elif stamp_m.group(1) not in file_log:
```

That is a different, much weaker proposition than the one I used to falsify the old stamps. Mine was:
*is this artifact's content obtainable at the stamped commit?* Check 7's is: *did this commit ever
touch this file?*

AC-005's accepted set is `{f6dfa58, b4bbbc3, 879efff}`. At `879efff` the file's content was:

```
Check FAILED: 9 violations found (79 reason-code occurrences + 5 E-class code occurrences validated
across 126 files scanned + 8 ADRs routed to POLICY 12 = 134 of 134 spec files (complete), …)
```

— i.e. `79 + 5`, not the current `78 + 6`.

**Proven by execution.** I restamped AC-005 to `879efff` and ran the verifier:

```
PASS — all figure checks match live output and git state
```

So BLOCKING-C can be reintroduced in a form Check 7 accepts. It caught the `fd74bd7` instance only
because `fd74bd7` happens not to appear in these files' histories — a coincidence of which commits
touched which files, not a property the check establishes. It also accepts `f6dfa58`, the
stamp-correction commit, which is not a capture point at all.

**Fix.** Assert the stamped commit is one at which the current content was reproducible:

```python
blob_at_stamp = sh("git", "show", f"{stamp}:{ac_path.relative_to(REPO)}")
# compare on the figure-bearing lines, ignoring the stamp line itself
if normalise(blob_at_stamp) != normalise(content):
    fail(f"provenance-stamp/{ac_path.name}",
         "stamp names a commit whose file content matches the current artifact",
         f"content at {stamp[:7]} differs — artifact was not captured there")
```

The comment at lines 154-156 explains that the full log is used "so this stays correct after a
stamp-correction commit". That problem is real but the chosen remedy is too broad; normalising away
the stamp line before comparison solves it without accepting every historical revision.

### On the `pop=` relaxation — it did **not** create a hole

Answering the specific question: line 77's `pop(?:ulation)?=` is sound. The body contains exactly
**one** ledger triple (line 225, the AC-7 row, `pop=8, examined=6, skipped=2`) and it matches live
output. More importantly the invariant at line 74 (`population == examined + skipped`) is computed
purely from live output, so it cannot be weakened by a document-side spelling change. The relaxation
broadens an accepted spelling; it does not widen what passes. No hole. The residual weakness near it
is SUGGESTION-5, which is structural and predates the relaxation.

---

## 3. Suggestions and nits

- **SUGGESTION-5 — Checks 2 and 4 validate only the *first* restatement of each figure.** They use
  `re.search`, so later contradictory restatements pass. **Proven:** I changed the third occurrence
  (line 223, the AC-5 evidence row) from `78 reason-code + 6 E-class` to `79 … + 5 …`, left the first
  intact, and the verifier reported `PASS`. This matters because every defect in this PR's history
  has been an internal contradiction between multiple statements of one figure — including the
  `98/98` heading, which was caught only because Check 1 checks the badge and the heading as two
  named locations. Use `re.finditer` and assert every occurrence.
- **SUGGESTION-6 — the verifier is not wired into anything.** `grep -rl verify-evidence-figures`
  matches only the file itself. `ci.yml`'s `spec-lint` job iterates `scripts/spec-lint/${check}.py`;
  the new script sits at `scripts/` and is not in the `CHECKS` array. As a manual-only script it
  cannot prevent the drift it was built to prevent — the recommendation was a mechanical gate. Add it
  to CI (advisory or required) or to the `just` recipe.
- **SUGGESTION-7 — the rollback command is wrong again, and now leaves a source file.** Body line 319
  lists 9 commits and line 322 claims "all 9 commits", but `git rev-list --count develop..HEAD` is
  **10**; `f6dfa58` is omitted. Because `f6dfa58` *adds* `scripts/verify-evidence-figures.py`,
  reverting the documented 9 leaves that script orphaned, referencing artifacts the revert deleted.
  This is the third consecutive cycle the rollback has been wrong. Note the verifier deliberately
  exempts this (lines 193-195) and its `rollback/count-claim` arm only checks 9-against-9 internal
  consistency, so it passes while both numbers are wrong. Either include head, or state the rule as
  "reverts all *source* commits" and check that.
- **NIT-E — `evidence-report.md:12` credits AC-001 with "99/99 selftests"**, but `AC-001-preflight.txt`
  contains no selftest total; it is a truncated preflight capture ending mid-suite at
  `selftest 2: check-counts`. The other two figures in that row (0 unproven, 10/10 primitives) are
  present. The 99/99 figure is true and evidenced in AC-002 — just not in the artifact the row cites.
- Cycle-4 **NIT-A** (count assertions matching any count ending in 1) and **NIT-B** (EI-5's
  mutation-verify comment naming a kill mechanism that does not exist) remain open and unaddressed.
  Both still non-blocking.

## 4. Did this pass introduce a new defect?

Yes — one, plus two inherited into the new file:

- **SUGGESTION-7** (rollback now off by one and orphaning a source file) is new in `f6dfa58`.
- **BLOCKING-D** and **BLOCKING-E** are new code in `f6dfa58`.

Against that, this pass fixed six findings and introduced no defect in `scripts/spec-lint/`. The
trend is improving: cycles 3-5 each broke something in the artifact being corrected; this one only
has defects in genuinely new code.

## Bottom line

The spec-lint deliverable is **clean and unchanged** — 99/99, mutation proof reproduces, ledger
`8 = 6 + 2`, all four required CI checks green at `f6dfa58`, frozen perimeter confirmed at
`ace1745`, authorization field untouched. Every finding from cycles 1 through 5 is now RESOLVED, and
BLOCKING-C's replacement stamp survives the same falsification test that killed its predecessor.

**REQUEST_CHANGES** rests entirely on the new verifier: it reports `PASS` when it cannot parse the
live output it is supposed to compare against (BLOCKING-D), and its provenance test accepts stamps
that assert a capture point at which the content did not exist (BLOCKING-E). Both proven by
execution, both a few lines to fix, neither touching `scripts/spec-lint/`. Fix those two and I expect
to approve.
