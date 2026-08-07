# D-028 Scoped Confirmatory Review — PR #6 @ `0ad5c5e`

**Head SHA verified:** `0ad5c5e81be0ee3a9614b46f163cdad09ed63104` — matches mandate, no drift.
**Delta reviewed:** `a642d24..0ad5c5e` (6 files, +222/−16). Base `develop` @ `651ee3a`.
**`Spec lint` CI FAILURE treated as ADVISORY** per D-029/D-032 (25 `[filled by story-writer]`
placeholders — independently re-counted: 25).
**Not re-litigated:** the write-gate attack matrix, cherry-pick integrity audit, and mutation
results from the `a642d24` review, all confirmed sound there.

## Verdict

APPROVE

Both in-scope items are genuinely closed, and I verified closure by execution rather than by
reading the diff. BLOCKING-1 is closed end-to-end: the checker is in both runner arrays, both
runners actually invoke it, and a non-zero exit propagates to a job failure. MAJOR-2's fail-open
is eliminated — the checker can no longer bind an unrelated ancestor's facts and print OK. The
write gates were not weakened; they were strengthened, because the write call was **removed**
from `gen-bc-traceability.py` rather than merely guarded. Nothing regressed.

Two things the operator should merge with eyes open, neither blocking. First, the new meta-guard
is defeated by the single most idiomatic way a checker gets disabled — commenting the array entry
out. Second, the `.git` boundary stop that fixes MAJOR-2 also reintroduces BI-021 from a real
linked worktree, as a **fail-closed** error with actionable guidance. The mandate asked whether
both properties hold simultaneously; they do not. The direction is safe and it puts this checker
on par with its 8 peers, so I am not blocking on it, but the PR body currently claims the BI-021
fix works where it no longer does.

---

## 1. Delta scope confirmation — `a642d24..0ad5c5e`

```
.github/workflows/ci.yml                    |   1 +
justfile                                    |   1 +
scripts/spec-lint/check-canonical-facts.py  |  46 ++++++--
scripts/spec-lint/gen-bc-traceability.py    |  15 ++-
scripts/spec-lint/gen-slug-corpus.py        |   3 +
scripts/spec-lint/selftest/run-selftests.sh | 172 +++++++++++++++++++--
6 files changed, 222 insertions(+), 16 deletions(-)
```

**Confined to the intended fixes.** Every hunk maps to BLOCKING-1, MAJOR-2, or a named MINOR. No
unrelated change, no drive-by refactor, no new dependency, nothing under `.factory/`.

**`check-index-integrity.py` is untouched and byte-identical to develop.** It is absent from the
delta *and* from the entire PR diff (`651ee3a..0ad5c5e` touches only the 6 files above):

```
git show 0ad5c5e:scripts/spec-lint/check-index-integrity.py | shasum -> 0035ab6922ea9c
git show 651ee3a:scripts/spec-lint/check-index-integrity.py | shasum -> 0035ab6922ea9c
```

Matches the hash recorded in the prior review. The 11-cycle-reviewed version was preserved.

---

## 2. BLOCKING-1 closure + meta-guard attack results

### Closure: the checker is executed, not merely mentioned

`"check-canonical-facts"` is present in the `CHECKS=(...)` array in both
`.github/workflows/ci.yml:242` and `justfile:206`. I confirmed both **execute** it and both
**propagate** a non-zero exit:

- **Real invocation.** `just spec-lint` prints `── check-canonical-facts ──` followed by
  `canonical-facts: OK — all 31 bindings match canonical values (11 facts)`. It runs.
- **Propagation.** Replaying the exact `ci.yml` loop body against a checker forced to `exit 3`:
  `FAIL (spec violation found)` → `spec-lint FAILED: 1/1` → **loop exit code 1** → job fails.
- **No silent-pass class.** `ci.yml` `case` counts rc=2 as `ERROR (infrastructure)` and increments
  `FAILURES`; every other non-zero counts as `FAIL`. The `justfile` arm lumps all non-zero into
  `FAIL`. There is no rc value that passes silently.
- `set -euo pipefail` does not abort the loop early: `ci.yml` uses `|| ret=$?` and the `justfile`
  uses an `if` guard, both of which suspend `errexit` correctly.

BLOCKING-1 is genuinely closed.

### Meta-guard (selftest 29) attack results

The guard globs `$LINT_DIR/check-*.py` and, per name, runs
`grep -qF "\"${name}\"" ci.yml` and `grep -qF "\"${name}\"" justfile`.

| # | Attack | Result |
|---|---|---|
| A1 | Entry deleted from array; name added inside a **YAML comment** elsewhere | **DEFEATED** — guard reports nothing missing |
| A2 | Array entry **commented out in place** (`# "check-canonical-facts"`) | **DEFEATED** — proved bash skips the entry, guard still clean |
| A3 | Entry deleted; name appears in an unrelated `run: echo "check-canonical-facts"` | **DEFEATED** |
| B | Present in `ci.yml`, **missing from `justfile`** | correctly detected (`missing_just=[check-canonical-facts]`) |
| C | Single-quoted entry `'check-canonical-facts'` (functional in bash) | guard fires — fail-closed false positive (safe) |
| D | Bare unquoted entry (functional in bash) | guard fires — fail-closed false positive (safe) |
| E | Checker in a **subdirectory** (`spec-lint/extra/check-x.py`) | unscanned by the non-recursive glob — but also unrun by either runner, so consistent |
| F | Prefix-substring collision (`check-count` vs `check-counts`) | **resisted** — the quotes anchor both ends, no false match |
| M9 | Mutation: neuter the `ci.yml` detection (`if false`) | **test 29 flips**, suite rc=1 — ci.yml arm **is** mutation-verified |
| M10 | Mutation: delete the **`justfile` arm** entirely | **suite stays 49/49 GREEN** — that arm is **not** mutation-verified |

Attacks A1–A3 share one root cause: the guard greps the **whole file** for a quoted name rather
than parsing the `CHECKS` array. It therefore proves "this string appears somewhere in the file,"
not "this checker is in the runner's array." A2 is the important one — commenting a line out is
the ordinary way an engineer disables a check under time pressure, and it is exactly the state
BLOCKING-1 described. See MAJOR-4.

The guard's positive value is real: it catches outright deletion of the line (M9), and it catches
one-runner-only omission (B). It is mutation-verified for `ci.yml` and unverified for `justfile`.

---

## 3. MAJOR-2 closure + `_find_repo_root()` attack matrix

The fail-open is eliminated. `_find_repo_root()` now returns `None` on a `.git` boundary hit or an
8-level exhaustion, and module scope exits 1 with guidance naming `SPEC_LINT_REPO_OVERRIDE`.
Mutation **M11** (delete the two boundary-stop lines) flips selftest 30 and exits the suite rc=2,
so the stop is load-bearing.

Critically, the ordering inside the loop is correct: `.factory/specs/canonical-facts.toml` is
tested **before** `.git`. That is what lets the real main checkout — which has both — still
resolve. Reversing those two checks would break every live invocation.

| # | Scenario | Result | Verdict |
|---|---|---|---|
| 1 | `.git` as a **FILE** (linked worktree) | walk stops, `None`, rc=1 + guidance | terminates ✓ |
| 2 | `.git` as a **DIRECTORY** (main checkout) | walk stops, rc=1 | terminates ✓ |
| 3 | Main checkout, `.factory/` mounted | binds repo root, rc=0, `all 31 bindings match (11 facts)` | correct ✓ |
| 4 | Decoy `.factory/` in ancestor, inner repo has `.git` (selftest 30) | rc=1, no escape, no false OK | fail-closed ✓ |
| 5 | Decoy `.factory/` **inside** the repo at `scripts/` (above script, below root) | binds the **nearest** decoy: `REPO=<tmp>/scripts`, prints `OK` | nearest-wins shadowing; in-repo only, no escape — MINOR-D |
| 6 | Working tree with **no `.git` entry** (tarball export, `git archive` extraction, vendored copy, external `GIT_DIR`) nested under a decoy ancestor | **ESCAPES** to ancestor, binds `FACT-ALIEN`, prints `OK`, rc=0 | residual fail-open — MINOR-E |
| 7 | **Symlinked** path into a proper repo | `Path.resolve()` normalizes to the physical path → rc=0, correct binding | ✓ |
| 8 | Script >8 levels below the facts root, no `.git` | rc=1 + guidance | fail-closed ✓ |
| 9 | **BI-021: real linked worktree** `.worktrees/ws-b-generators/scripts/spec-lint/` | **rc=1, fail-closed** — auto-resolution LOST | see MAJOR-5 |

Cases 1 and 2 both terminate the walk, which is what the docstring claims and what `.exists()`
delivers for file and directory alike. Case 3 is the one that matters operationally and it works.
Case 6 is a genuine residual: the boundary predicate is `.git` *existence*, so any checkout form
that lacks a `.git` entry cannot trigger the stop. I reached it with a real `git archive | tar -x`
extraction, which is not an exotic configuration.

### The BI-021-still-fixed check — it is NOT

I ran the shipped checker from the real linked worktree on this machine
(`.worktrees/ws-b-generators/.git` is a 76-byte pointer **file**, and the main checkout does hold
`.factory/specs/canonical-facts.toml`):

```
$ python3 .worktrees/ws-b-generators/scripts/spec-lint/check-canonical-facts-probe.py
check-canonical-facts: REPO root not found — no ancestor of this script
  contains .factory/specs/canonical-facts.toml within the repository
  boundary (walk stopped at .git or exceeded 8-level limit).
  If .factory/ is a separate worktree, ensure it is mounted.
  Set SPEC_LINT_REPO_OVERRIDE to the repo root to override path resolution.
rc=1
```

The walk stops at `.worktrees/ws-b-generators/.git` before it can reach the main checkout's
`.factory/`. **The two properties do not hold simultaneously.** The delta's own docstring concedes
this ("handled correctly in the selftest tree (which has no `.git` file) and in production via
`SPEC_LINT_REPO_OVERRIDE`").

I am not blocking on it, for three reasons: the failure is **fail-closed**, the message is
actionable and names the override, and per the prior review's MAJOR-3 the other 8 checkers already
fail closed in this exact scenario — so this change makes `check-canonical-facts` *consistent*
with its peers rather than uniquely broken. Net safety versus `a642d24` is a clear improvement: a
silent false GREEN was traded for a loud, self-documenting refusal.

But selftest 25 no longer tests what it says it tests — see MAJOR-5.

---

## 4. MINOR closure table

| # | Prior MINOR | Status | Evidence |
|---|---|---|---|
| 1 | Generator docstrings omit that `--check` currently FAILS | **CLOSED** | `gen-bc-traceability.py:38–40` records "FAIL (786 diff lines across 66 BC files)"; `gen-slug-corpus.py:41–43` records "2 cosmetic diffs" |
| 2 | Pre-flight guards glob `check-*.py` only; both `gen-*.py` unscanned | **PARTIAL** | Both guards now iterate `check-*.py` + the two new generators explicitly; live output `11 checkers/generators`. The 4 pre-existing generators remain unscanned **and have zero `SPEC_LINT_REPO_OVERRIDE` support**, so a `gen-*.py` glob would fail today. Tradeoff is documented in-code. |
| 3 | Module-level `update_bc_file` writes with no gate (reachable via import) | **CLOSED, strongly** | Verified via import against a real BC file: `RuntimeError` raised, **file byte-identical**. And `grep` finds **no `write_text` / `open(...,'w')` / `.write(` anywhere in the file** — the write capability was removed, not merely gated. |
| 4 | PR body baseline "17 →" should be "36 →" | **CLOSED** | Body now reads "Selftest baseline: 36 → 40" and "tests 18–30 (36 → 49)" |
| 5 | `01736e7` fails its own selftest (37 vs `EXPECTED_TEST_COUNT=36`) | **CLOSED as disclosed** | Body line 52 discloses it as a pre-squash history artifact. Unfixable without history rewrite. |
| 6 | PR body claim "Gate 2 prevents independent mutation-verify of Gate 1" is false | **NOT CLOSED** | Rewritten into a new inaccuracy — see MINOR-A / MINOR-B |
| — | Prior MINOR-4: BI-041 blast radius understated (~20+ rows) | **STILL OPEN** | Comment still names only INC-MAP-002/003/004 "and any future"; no count recorded. Out of mandate scope. |

---

## 5. Write-gate spot-check

All runs in an isolated `SPEC_LINT_REPO_OVERRIDE` temp tree seeded with a 140-file copy of
`.factory/specs`. Verification after every invocation was a full recursive `shasum` manifest diff.
The real `.factory/specs/` was never a write target.

| Generator | argv | rc | tree | gate that fired |
|---|---|---|---|---|
| `gen-bc-traceability` | *(bare)* | 1 | CLEAN | Gate 1 (concurrency) |
| `gen-bc-traceability` | `--write` | 1 | CLEAN | Gate 2 (BI-041) |
| `gen-bc-traceability` | `--dry-run` | 0 | CLEAN | preview only |
| `gen-bc-traceability` | `--check` | 1 | CLEAN | ran, non-destructive |
| `gen-slug-corpus` | *(bare)* | 1 | CLEAN | `bare invocation does not write.` |

**Not weakened — strengthened.** The delta replaced `bc_file.write_text(new_content, ...)` with a
`RuntimeError`, so `gen-bc-traceability` has no write statement left at all. Every refusal path
leaves the tree byte-identical.

One consequence, verified by mutation (see MINOR-A): because the write is gone, **neither gate in
`main()` is independently mutation-verifiable any more.**

| Mutation | Suite | `gen-bc-traceability` behavior | tree |
|---|---|---|---|
| Neuter Gate 1 (`if not check_mode and not dry_run and not write_mode:` → `if False:`) | **49/49 GREEN**, test 27 does **not** flip | bare invocation rc=1 via function-level gate | CLEAN |
| Neuter Gate 2 (`if write_mode:` → `if False:`) | **49/49 GREEN**, test 26 does **not** flip | `--write` rc=1 via function-level gate | CLEAN |

Safety is unaffected in both cases — the tree stays clean. What is affected is D-040 coverage:
tests 26 and 27 can no longer detect removal of the gates they nominally prove.

---

## 6. No regression

| Check | Result |
|---|---|
| Selftest count — **counted myself, not accepted** | `TESTS_RUN` increments: **49**. `EXPECTED_TEST_COUNT=49`. Run: **49 PASS, 0 FAIL, rc=0**, `Selftest passed: 49/49`. Consistent. |
| All checkers clean on live tree | **PASS** — 8/9 rc=0; only `check-placeholders` rc=1 |
| `check-placeholders` = 25 known advisory placeholders | **PASS** — `25 placeholder occurrences found (133 files checked)` |
| `check-canonical-facts` on live tree | **PASS** — `OK — all 31 bindings match canonical values (11 facts)` |
| `git status` clean | **PASS** — empty |
| Nothing under `.factory/specs/` modified (D-058) | **PASS** — `.factory` worktree shows only `logs/*.jsonl`, `sidecar-learning.md`, and this review's untracked `code-delivery/` dir |
| Nothing under `.factory/holdout-scenarios/` modified | **PASS** |
| `check-index-integrity.py` byte-identical to develop | **PASS** — `0035ab6922ea9c` both sides; absent from the whole PR diff |
| Pre-flight guards still fire and report counts (D-057) | **PASS** — `11 checkers/generators` on both guards |

---

## Findings

No BLOCKING findings.

### MAJOR-4 — The meta-guard is defeated by commenting out the array entry, the most likely regression path
**File:** `scripts/spec-lint/selftest/run-selftests.sh:1580–1590` (selftest 29)
**Category:** enforcement / vacuous-by-construction

The guard asserts presence with `grep -qF "\"${name}\"" "$REPO/.github/workflows/ci.yml"` — a
whole-file literal search. It therefore proves the quoted string exists *somewhere in the file*,
not that the checker is an active element of the `CHECKS` array.

**Failure scenario:** six months from now `check-canonical-facts` starts failing on a spec edit
under deadline pressure. An engineer does the ordinary thing and comments the line out:

```yaml
            "check-index-integrity"
            # "check-canonical-facts"
          )
```

I verified bash then expands `CHECKS` to exclude it (only `check-index-integrity` runs), while the
meta-guard reports `missing_ci=[] missing_just=[]` and selftest 29 passes clean. The `Spec lint`
check-run goes green, the checker never executes, and BLOCKING-1 has silently recurred with a
guard in place that was specifically built to prevent it. Two variants reach the same state: the
quoted name surviving in any nearby comment (A1), or in any unrelated `run:`/`echo` string (A3).

**Fix:** extract the array and match members, rather than grepping the file. Something like

```bash
mapfile -t CI_CHECKS < <(sed -n '/CHECKS=(/,/^ *)/p' "$REPO/.github/workflows/ci.yml" \
  | grep -vE '^\s*#' | grep -oE '"check-[a-z-]+"' | tr -d '"')
```

then test membership in `CI_CHECKS`. Stripping comment lines before extraction is the load-bearing
step. Consider the same for the `justfile` arm, and add a mutation case that comments an entry out
so this vector is itself covered.

### MAJOR-5 — Selftest 25 no longer models a secondary worktree; the BI-021 property it asserts is false in production
**File:** `scripts/spec-lint/selftest/run-selftests.sh` (selftest 25 fixture), `check-canonical-facts.py:55–58`
**Category:** coverage / vacuous-by-proxy

Selftest 25 builds `$T/.worktrees/BI021-SIM/scripts/spec-lint/` and asserts the checker resolves
up to `$T`. Its fixture creates **no `.git` entry anywhere**. A real linked git worktree always
has a `.git` **file** at its root — verified on this machine:
`.worktrees/ws-b-generators/.git` is a 76-byte pointer file.

**Failure scenario:** I reproduced test 25's fixture exactly and then made it faithful:

```
fixture as shipped (no .git)          -> rc=0   "OK — all 1 bindings match"   test 25 passes
+ .git FILE at worktree root (real)   -> rc=1   fail-closed                    test 25 would FAIL
+ .git DIRECTORY at worktree root     -> rc=1   fail-closed
```

So the test passes only because its fixture is not a worktree. Anyone running `just spec-lint`
from `.worktrees/STORY-NNN/` gets rc=1 while selftest 25 reports the BI-021 fix working. This is
the same defect class as MAJOR-1 in the `a642d24` review: a test asserting a branch that
production cannot reach.

Not blocking — the production failure is fail-closed with a message naming
`SPEC_LINT_REPO_OVERRIDE`, and the other 8 checkers already behave this way (MAJOR-3, out of
scope). But the test should stop claiming otherwise.

**Fix:** add `printf 'gitdir: ...' > "$T/.worktrees/BI021-SIM/.git"` to the fixture and invert the
assertion to expect rc=1 plus the boundary message; rename the test to describe what it now
proves. Then record the real BI-021 resolution path — `SPEC_LINT_REPO_OVERRIDE` — as the supported
mechanism for worktree invocation, and set it in whatever wrapper runs spec-lint from worktrees.

### MINOR-A — Two mutation-verify claims are now false: neither `main()` gate flips its test
**File:** `scripts/spec-lint/gen-bc-traceability.py:322–323`, and PR #6 body line 21
**Category:** description accuracy / test sensitivity

The in-code comment above Gate 2 states: *"Mutation-verify: removing this block causes `--write`
to succeed (exit 0), flipping selftest 26's defect-fail assertion to FAIL."* The PR body repeats
it. Both were true at `a642d24`. This delta invalidated them and neither was updated.

**Failure scenario:** verified by mutation. Neuter `if write_mode:` → `if False:` and `--write`
still exits **1** (the function-level `RuntimeError`), the tree stays CLEAN, and the suite reports
**49/49 GREEN** — test 26 does not flip. Symmetrically for Gate 1: neuter its condition and bare
invocation still refuses via the function-level gate, suite still 49/49, test 27 does not flip. A
future maintainer trusting these comments would believe deleting either gate is caught by the
suite. It is not. Safety is preserved by the function-level gate in every case; only the D-040
evidence is stale.

**Fix:** update both comments and the PR body to state that the write capability is now removed at
the function level, so the two `main()` gates are defense-in-depth and are **not** individually
flippable. If independent verification is wanted, add a test that asserts each gate's specific
stderr message rather than only refusal-plus-byte-identity.

### MINOR-B — PR body's rewritten Gate 1 claim is self-contradictory and names the wrong mechanism
**File:** PR #6 body line 32
**Category:** description accuracy

The body now says *"Gate 1 IS independently mutation-verifiable: removing only Gate 1 causes bare
invocation to reach Gate 2, which still refuses…"* — then explains why the assertion does **not**
flip. A guard whose test does not flip is by definition not mutation-verified, so the sentence
contradicts itself. The mechanism is also wrong: Gate 2 is `if write_mode:`, which is `False` for
a bare invocation. Bare invocation with Gate 1 removed is caught by the **function-level gate** in
`update_bc_file`, which I confirmed from the traceback. Understates rigor in one clause and
misdescribes the control flow in the next.

### MINOR-C — BI-042 / D-073 is not recorded in the PR body, which still frames BI-035 as fully discharged
**File:** PR #6 body lines 5–6
**Category:** description accuracy

The body heads the section *"BI-035 — mutation-verified FACT-7/8/9/10 negative selftests"* and
states *"All four are mutation-verified."* There is no mention anywhere in the body of BI-042,
FACT-9/FACT-10 tautological capture groups, or ruling D-073. Per the prior review — confirmed
sound and not re-litigated here — the FACT-9 and FACT-10 *production* bindings are literal-baked
prefix presence checks, so tests 21 and 22 are mutation-verified only against their own synthetic
patterns.

**Failure scenario:** the squash-merge commit message becomes the durable record that BI-035 was
discharged for all four facts, when D-073 explicitly permits this merge with BI-035 **half**
discharged in exchange for BI-042 being first in the queue. A future audit reading only the merge
record concludes FACT-9/FACT-10 are enforced. Not blocking — D-073 already rules the substance —
but the bookkeeping should match the ruling.

**Fix:** add one line: *"BI-035 is half-discharged. FACT-7/8 are enforced at the value level;
FACT-9/FACT-10 bindings are tautological (BI-042) and enforce presence only. Merging under D-073;
BI-042 is the first work item once `.factory/specs` is released."*

### MINOR-D — An in-repo `.factory/` between the script and the repo root silently shadows the real root
**File:** `scripts/spec-lint/check-canonical-facts.py:43–52`
**Category:** correctness / fail-safety

Resolution is nearest-ancestor-wins with no preference for the repo root. With a decoy at
`scripts/.factory/specs/canonical-facts.toml`, the checker bound `REPO=<tmp>/scripts` and printed
`OK — all 1 bindings match`, never consulting the real root. Requires an in-repo write of that
specific path, and it cannot escape the repository, so severity is low. Worth a note in the
docstring that the *nearest* match wins, or an assertion that the resolved root also contains a
`.git` entry.

### MINOR-E — The boundary predicate is `.git` existence, so `.git`-less working trees can still escape
**File:** `scripts/spec-lint/check-canonical-facts.py:48–50`
**Category:** correctness / fail-safety

The stop fires only when a `.git` entry exists. A working tree without one still walks out of the
repository. Reproduced with a `git archive | tar -x` extraction nested under a decoy ancestor:
binds `FACT-ALIEN` from the ancestor and exits **0** with `OK`. The same applies to vendored
copies, release tarballs, and `--work-tree` with an external `GIT_DIR`. This is a narrower
instance of the MAJOR-2 class rather than a new one, and `git archive` extraction is a realistic
enough configuration to note. **Fix:** treat "no repo marker found anywhere up the walk" as
fail-closed too — e.g. require that the directory returned contain a `.git` entry, or resolve the
root via `git rev-parse --show-toplevel` with the walk as fallback.

### MINOR-F — The `justfile` arm of the meta-guard is not mutation-verified
**File:** `scripts/spec-lint/selftest/run-selftests.sh:1586–1589`
**Category:** coverage

Selftest 29's defect step builds a mutated **`ci.yml`** only. Deleting the entire `justfile`
detection block from the clean-pass loop leaves the suite at **49/49 GREEN**. The arm works today
(attack B detected a justfile-only omission), but no test would notice if it broke or was removed.
**Fix:** add a second defect step against a mutated temp `justfile`, symmetric to the `ci.yml` one.

---

## What remains open after this PR

1. **BI-040** — tracked, unchanged by this delta.
2. **BI-041** — `gen-bc-traceability` write mode is lossy (~20+ annotated Architecture Module rows,
   including INC-MAP-002/003/004). Deferred by ruling. Now mitigated by three layers, one of which
   removes the write call outright. Prior MINOR-4 (blast-radius count in the justifying comment)
   is still unrecorded.
3. **BI-042** — 17 of 31 bindings have tautological capture groups, including all 6 FACT-9 and all
   7 FACT-10 bindings. Merging under **D-073** with BI-035 half-discharged; BI-042 is first once
   the concurrent `.factory/specs` editor releases the tree. Not recorded in the PR body (MINOR-C).
4. **MAJOR-3 (prior)** — `parent.parent.parent` survives in 8 other checkers and in both
   generators. Fails closed, so annoying rather than unsafe. This delta makes
   `check-canonical-facts` behave consistently with those 8 from a linked worktree.
5. **BI-021 from a real linked worktree** — now fail-closed rather than auto-resolved;
   `SPEC_LINT_REPO_OVERRIDE` is the supported path. Selftest 25 does not yet reflect this
   (MAJOR-5).
6. **Live `--check` divergence** — 786 lines for `gen-bc-traceability`, 2 cosmetic lines for
   `gen-slug-corpus`. Now disclosed in both docstrings. Recorded finding, not a defect in this PR.
7. **Meta-guard comment bypass** (MAJOR-4) and the unverified `justfile` arm (MINOR-F).

## What I verified and found sound

- BLOCKING-1 closed end-to-end: both runners execute the checker, non-zero propagates to a job
  failure, and no rc value passes silently. Confirmed by real invocation and by replaying the
  `ci.yml` loop against a forced-failing checker.
- MAJOR-2's fail-open eliminated. `.git` as file and as directory both terminate the walk; the
  `.factory`-before-`.git` check order preserves live resolution; symlinks normalize correctly; the
  8-level limit fails closed with actionable guidance. Mutation M11 confirms the stop is
  load-bearing.
- Write gates hold and were strengthened: no `write_text`, `open(...,'w')`, or `.write(` remains in
  `gen-bc-traceability.py`. The import path is blocked with the file byte-identical — MINOR-3 is
  closed more thoroughly than the fix required.
- Delta confined to the six intended files. `check-index-integrity.py` byte-identical to develop
  (`0035ab6922ea9c`) and absent from the entire PR diff.
- 49/49 confirmed by my own count (49 `TESTS_RUN` increments, `EXPECTED_TEST_COUNT=49`, 49 PASS,
  0 FAIL, rc=0), not by accepting the reported figure.
- 8/9 checkers clean on the live tree; `check-placeholders` rc=1 with exactly 25 advisory
  placeholders. `git status` clean. Nothing under `.factory/specs/` or `.factory/holdout-scenarios/`
  modified (D-058). Pre-flight guards fire and report 11 files scanned (D-057).
- Four of the six named MINORs fully closed, one partially, one carried forward in altered form.

---

## Freshness statement

This review covers **`0ad5c5e81be0ee3a9614b46f163cdad09ed63104`** and no other commit. Head SHA
was verified against `gh pr view 6 --json headRefOid` before any analysis began; no drift. The
delta examined is `a642d24..0ad5c5e`. All execution evidence — selftest runs, mutations M9/M10/M11,
the Gate 1 and Gate 2 neutering runs, the nine-case `_find_repo_root()` matrix, the meta-guard
attacks, and the write-gate spot-check — was produced against this SHA, using sandbox copies
(`git archive 0ad5c5e`) and `SPEC_LINT_REPO_OVERRIDE` temp trees. No file in the working tree was
modified; `git status` was clean before and after. Findings may not hold for any later commit.

*Note: `gh pr review` is unsatisfiable on this PR (BI-039 — GraphQL "Can not request changes on
your own pull request", root cause D-021). Posted via `gh pr comment` as pre-authorized. Merge
authority remains the orchestrator's; this review does not merge or approve via the GitHub merge
API.*
