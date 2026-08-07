# D-028 Scoped Confirmatory Review — PR #6 @ `06b58b6`

**Head SHA verified:** `06b58b6f935193e75d8239aacdd49b65cda0ea8a` via `gh pr view 6 --json headRefOid` — matches
mandate, no drift.
**Delta reviewed:** `0ad5c5e..06b58b6` — 1 commit, 3 files, +145/−66. Base `develop` @ `651ee3a`.
**`Spec lint` CI FAILURE treated as ADVISORY** per D-029/D-032. Independently confirmed from the CI log
(run 31160052315): `spec-lint FAILED: 1/9 checks failed`, sole failure `check-placeholders` with
`25 placeholder occurrences found (133 files checked)`. All 9 checkers ran, including
`check-canonical-facts`.
**Out of scope per mandate, not re-raised:** BI-041, BI-042/D-073, BI-021 remaining open, prior MAJOR-3,
the `.git`-less working-tree residual, the live `--check` divergence.

## Verdict

REQUEST_CHANGES

Three of the four MAJORs are genuinely and strongly closed, and I closed them by execution, not by reading
the diff. MAJOR-4 is closed better than the fix asked for: the awk-derived active list is byte-for-byte
identical to what bash actually expands on both real runner files, the comment-out bypass is now detected on
both arms, and — new since the last review — each arm is *independently* mutation-verified, which also
closes prior MINOR-F. MAJOR-5 is closed and mutation-verified in **both** directions: removing the `.git`
boundary stop flips test 25, and making `SPEC_LINT_REPO_OVERRIDE` ineffective flips its second step, so
neither half of that test is vacuous. MAJOR-7 is closed — I read the PR body against every specific claim in
the mandate and it holds without softening. Nothing regressed: 49/49 counted by hand, all checkers as
expected, tree clean, `check-index-integrity.py` still byte-identical to develop.

MAJOR-6 is **not** closed, and that is the whole of my objection. The implementer's explanation is *true* —
I mutation-tested all four combinations and every claim in it checks out. The two comments in
`gen-bc-traceability.py` were corrected. But the exact false sentence MAJOR-6 was raised about survives
verbatim, unedited, in `run-selftests.sh:1379–1380` — inside the very file this delta rewrote 172 lines of —
still telling a maintainer that removing Gate 2 "causes `--write` to exit 0, flipping this test's
defect-fail assertion to FAIL." I proved by mutation that it does not: the suite stays 49/49 GREEN and test
26 reports PASS. A second claim at `1442–1443` names the wrong mechanism. MAJOR-6 is a record-accuracy
finding; a record-accuracy finding is not closed while the record is still false at a site a maintainer
would plausibly read *first* — a test's own header is the most authoritative statement of what that test
detects.

I want to be explicit about proportionality, because this is cycle four and the fix is two comment lines.
The harm ceiling here is bounded: I verified (MUT-H) that removing Gate 2 **and** the function-level guard
together *does* flip test 26, so no unguarded-write end state is reachable without the suite going red.
Safety is intact in every mutation I ran. This is a wrong belief about test sensitivity, not an exploitable
hole. If the operator rules that an acknowledged-stale test comment is an acceptable carry, the substance of
this PR is otherwise merge-ready and I have mutation-verified every load-bearing property in it — a
follow-up head can be confirmed in minutes because nothing else needs re-checking. But I will not report
MAJOR-6 as closed when the assigned closure criterion ("confirm the comments ... now state it accurately
rather than claiming verification that does not exist") demonstrably fails.

---

## Delta confinement — `0ad5c5e..06b58b6`

```
scripts/spec-lint/check-canonical-facts.py  |  14 ++-
scripts/spec-lint/gen-bc-traceability.py    |  25 +++-
scripts/spec-lint/selftest/run-selftests.sh | 172 +++++++++++++----------
3 files changed, 145 insertions(+), 66 deletions(-)
```

**Confined to the four MAJORs.** No unrelated change, no drive-by refactor, no new dependency, nothing
outside `scripts/spec-lint/`.

| Check | Result |
|---|---|
| `check-canonical-facts.py` +14 lines | **Docstring only.** Zero executable change — the diff adds the corrected BI-021 sentence (MAJOR-5) and the KNOWN RESIDUAL paragraph. Live resolution unaffected: verified below. |
| `gen-bc-traceability.py` +25 lines | **Comments only.** Three comment blocks rewritten (MAJOR-6). Zero executable change. |
| `run-selftests.sh` +172/−66 | Test 25 rewritten in place (MAJOR-5), test 29 rewritten in place (MAJOR-4). `git diff -U0` hunk ranges are confined to 1287–1362 and 1576–1679. |
| Selftest count did not rise | Legitimate — both tests replaced in place, no new `TESTS_RUN` increment. |
| `check-index-integrity.py` untouched | **PASS** — absent from the delta *and* from the whole PR diff. `git show 06b58b6:…` → `0035ab6922ea9c`; `git show 651ee3a:…` → `0035ab6922ea9c`. Matches the recorded hash. |
| No `.factory/specs/` change (D-058) | **PASS** — `git diff --name-only 651ee3a..06b58b6` piped through `grep '^\.factory/'` → 0 matches. Whole PR touches only 6 files, none under `.factory/`. |
| No `.factory/holdout-scenarios/` change | **PASS** — same evidence. |
| `ci.yml` / `justfile` unchanged in this delta | **PASS** — not in the delta; their `+1` line each is from the earlier `0ad5c5e` work. |

**Live resolution unchanged by the +14 docstring lines** (mandate item 3):
```
$ python3 scripts/spec-lint/check-canonical-facts.py
canonical-facts: OK — all 31 bindings match canonical values (11 facts)
rc=0
```

---

## MAJOR-4 attack matrix

The awk extraction is the safety mechanism now, so I attacked it directly. Method: for each case I built a
runner-shaped file and ran the shipped `_get_active_checks()` against it, then separately executed the *same*
array in bash and captured `printf '%s\n' "${CHECKS[@]}"`. Verdicts compare the derived set to what bash
**actually** expands.

**Baseline first — the shipped files.** Derived list is byte-for-byte identical to bash-actual on both arms:

```
ci.yml   : DERIVED == BASH-ACTUAL (9 entries)
justfile : DERIVED == BASH-ACTUAL (9 entries)
```

**The headline claim — comment-out bypass, both arms.** With `# "check-canonical-facts"` substituted into
each real file, the awk-derived active list and the bash-actual expansion *both* drop to the same 8 entries.
The guard fires. Prior attack A2 is closed.

| # | Attack | AWK-derived vs BASH-actual | Verdict |
|---|---|---|---|
| A2 | Array entry **commented out in place** (`# "check-canonical-facts"`), real `ci.yml` | 8 == 8, entry absent from both | **CLOSED** — guard fires ✓ |
| A2j | Same, real `justfile` | 8 == 8, entry absent from both | **CLOSED** — guard fires ✓ |
| C1 | Trailing inline comment `"check-foo"  # temporarily off` | awk → `check-foo  # temporarily off`; bash → `check-foo` | **safe-direction FP** — guard reports missing, bash runs it (MINOR-1) |
| C2 | Entry commented with a **tab** before the `#` | awk drops it; bash drops it | **MATCH** ✓ (`[[:space:]]` covers tab) |
| C3 | Single-line array `CHECKS=( "a" "b" )` | awk → ∅ (the `CHECKS=(` rule `next`s the whole line); bash → both | **safe direction** — guard reports *all* missing, maximally loud |
| C4 | `)` inside a comment **within** the array (`# note (disabled soon)`) | awk closes early, drops rest; bash keeps all | **safe direction** |
| C9 | `)` inside a **quoted entry** (`"check-canonical-facts)x"`) | awk closes early, drops rest; bash keeps all | **safe direction** |
| C5 | Array assembled via `CHECKS+=(...)` | awk sees nothing (regex is literal `CHECKS=(`, `+` breaks the match); bash keeps all | **safe direction** |
| C6 | Line continuation `"check-a" \` | awk → `check-a \`; bash → `check-a` | **safe direction** |
| C7 | **CRLF** line endings | awk → `check-a<CR>`; bash itself fails to parse the array at all | **safe direction** (both broken) |
| C8 | Whitespace **inside** the quotes (`" check-foo "`) | awk → ` check-foo `; bash → ` check-foo ` | **MATCH** (identically broken; neither would run) |
| C10 | Single-quoted entry `'check-foo'` | awk → `'check-foo'`; bash → `check-foo` | **safe-direction FP** (unchanged from prior review) |
| C11 | **Bare unquoted** entry `check-foo` | awk → `check-foo`; bash → `check-foo` | **MATCH** ✓ — an *improvement* over the grep guard, which false-positived here |
| C12 | **`CHECKS=(` appearing more than once in the file** | awk returns the **union** of all blocks; bash executes only the block it reaches | **UNSAFE direction** — see MINOR-2 |
| C13 | Stray `# CHECKS=(` in a comment above the real array | awk correctly skips the `#`-prefixed body and re-arms on the real block | **MATCH** ✓ |

**Both arms independently mutation-verified** — this is new, and it closes prior MINOR-F:

| Mutation | Suite | Test 29 |
|---|---|---|
| **MUT-C** — make the awk comment-blind globally (`sub(/^# */,"")` instead of skipping) | **rc=1, 2/49 failed** | **FLIPS with one failure per arm**: `FAIL (ci.yml arm: commented-out entry NOT detected…)` **and** `FAIL (justfile arm: commented-out entry NOT detected…)` |
| **MUT-D** — comment-blind for `*.yml` **only** | **rc=1, 1/49 failed** | only the **ci.yml** arm fails |
| **MUT-E** — comment-blind for `*justfile*` **only** | **rc=1, 1/49 failed** | only the **justfile** arm fails |

MUT-D and MUT-E are the decisive pair: each arm fails in isolation, so each arm has its own live defect step.
Prior M10 (deleting the justfile arm left the suite green) no longer reproduces.

**MAJOR-4: CLOSED.** One latent robustness gap (C12 / MINOR-2), not present in the file as shipped.

---

## MAJOR-5 closure

Selftest 25 now creates `$T/.worktrees/BI021-SIM/.git` as a **FILE** containing
`gitdir: ../../.git/worktrees/BI021-SIM` — a genuine linked-worktree simulation, matching the 76-byte
pointer file a real `git worktree add` produces. Confirmed present in the diff and in the shipped file.

The test's polarity is inverted relative to its predecessor and is asserted in both directions:

- **Clean pass:** no `SPEC_LINT_REPO_OVERRIDE` → asserts exit **non-zero** *and* that the output names
  `SPEC_LINT_REPO_OVERRIDE`. It also carries an explicit false-pass branch:
  `STRUCTURAL FAIL: script exited 0 without SPEC_LINT_REPO_OVERRIDE (false pass — boundary stop missing)`.
- **Defect step:** `SPEC_LINT_REPO_OVERRIDE=$T` → asserts exit **0**.

**Mutation-verified in both directions:**

| Mutation | Suite | Test 25 |
|---|---|---|
| **MUT-A** — delete the `.git` boundary stop (`if (candidate/".git").exists(): return None`) | **rc=2**, structural guard `only 47/49 tests had a clean-pass assertion` | **FLIPS**: `STRUCTURAL FAIL: script exited 0 without SPEC_LINT_REPO_OVERRIDE (false pass — boundary stop missing)` / `Output: canonical-facts: OK — all 1 bindings match`. Test 30 flips too. |
| **MUT-B** — remove `SPEC_LINT_REPO_OVERRIDE` support outright | **rc=2** — caught even earlier by the D-057 pre-flight guard | test 25 never reached |
| **MUT-B2** — keep the textual pattern (so the pre-flight guard still matches) but make the override silently ineffective | **rc=1, 6/49 failed** | **FLIPS**: `FAIL (SPEC_LINT_REPO_OVERRIDE set but checker still exited non-zero — override not effective)` |

MUT-B2 is the one that matters for the mandate's question "does the defect step genuinely exercise the
override": it does. Neither half of test 25 is vacuous. The record is corrected in the docstring
(`check-canonical-facts.py:51–53`) and in the PR body.

**MAJOR-5: CLOSED.**

---

## MAJOR-6 explanation verification

The mandate asked me to verify the explanation rather than accept it, since it is a claim about why a test
cannot fail. I ran all four mutation combinations. **The explanation is true in every particular.**

| Mutation | Direct behavior | Suite | Named test |
|---|---|---|---|
| **MUT-F** — Gate 1 neutered only | bare invocation `rc=1`; traceback terminates in `update_bc_file` line 271 `raise RuntimeError`; BC file **byte-identical** | **rc=0, 49/49 GREEN** | test 27 **PASS** (does not flip) |
| **MUT-G** — Gate 2 neutered only | `--write` `rc=1` via the same `RuntimeError`; message contains **`BI-041`** (test 26's grep target, 1 match); BC file byte-identical | **rc=0, 49/49 GREEN** | test 26 **PASS** (does not flip) |
| **MUT-H** — Gate 2 **and** the function-level guard removed, write restored | `--write` **rc=0**, `Updated: BC-2.99.001.md`, file **modified** | **rc=1** | test 26 **FLIPS**: `FAIL (--write returned 0 — BI-041 guard (Gate 2) not active…)` |
| **MUT-I** — Gate 1 **and** the function-level guard removed | bare invocation writes, `rc=0` | **rc=1** | test 27 **FLIPS**: `FAIL (bare invocation returned 0 — concurrency gate not active)` |

So: every clause of the implementer's explanation checks out. Removing Gate 1 does fall through to a
function-level `RuntimeError` (exit non-zero, file unchanged, test 27 green). Removing Gate 2 does reach the
same `RuntimeError`, whose message does contain "BI-041", so test 26's grep does still match. And the
positive half of the claim — "both must be removed simultaneously for `--write` to actually write files and
exit 0" — is **also** true (MUT-H). The joint protection is genuinely mutation-verified even though neither
gate is individually isolable. That is a materially better state than the prior review's MINOR-A described,
and I want it on the record.

`gen-bc-traceability.py:290–297` (Gate 1) and `:331–336` (Gate 2) now state this accurately, naming the
function-level `RuntimeError` as the mechanism — which also repairs prior MINOR-B's misattribution to Gate 2.

**But the fix landed at 2 of 4 sites.** See MAJOR-A. `run-selftests.sh:1379–1380` still carries the false
claim *verbatim*, and `:1442–1443` still names the wrong mechanism. Neither line is in the delta's hunk
ranges. **MAJOR-6: PARTIALLY CLOSED.**

---

## MAJOR-7 record accuracy

I read the PR body against each specific claim the mandate named. It holds, without softening.

| Required statement | Body text | Verdict |
|---|---|---|
| BI-035 is **PARTIALLY** discharged | Heading reads verbatim `### BI-035 — PARTIALLY discharged (tests 19–22)` | ✓ |
| FACT-9/FACT-10 explicitly **NOT** verified | "**FACT-9 and FACT-10 are NOT:** 17 of 31 bindings … have tautological capture groups, including all 6 FACT-9 bindings and all 7 FACT-10 bindings." Adds the sharper admission that "Selftest 22's own negative vector actually PASSES the real FACT-10 pattern (the string D-062 forbids)." | ✓ — stronger than required |
| **BI-042** named | Named, with the binding count and location | ✓ |
| **D-073** named | "Operator ruling **D-073** permits this merge in exchange for BI-042 being the first work item once the concurrent `.factory/specs/` editor releases the tree." | ✓ |
| BI-021 stated as **not fixed** | `### BI-021 — OPEN, fail-open regression CLOSED`; "BI-021 is **NOT fixed** by this PR." | ✓ |
| `SPEC_LINT_REPO_OVERRIDE` named as the supported path | "**`SPEC_LINT_REPO_OVERRIDE` is the supported path from secondary worktrees.**" | ✓ |
| "Open items after merge" section | Present, listing BI-021 and BI-042 (D-073) | ✓ |
| No claim that FACT-9/FACT-10 are verified | None anywhere in the body | ✓ |
| No claim that BI-021 is fixed | None; the body distinguishes the fail-open regression (closed) from BI-021 itself (open) | ✓ |

Prior MINOR-A, MINOR-B and MINOR-C are all discharged in the body: the Gate 1 claim now reads "NOT
independently verifiable" instead of the self-contradictory earlier version, and the Gate 2 mutation status
is stated accurately. The body also volunteers the git-archive residual (prior MINOR-E) and the `01736e7`
history artifact. The one nit is that the meta-guard paragraph says a grep-based check "could still be
defeated by comments; this implementation cannot" — true for the single-array case I verified, slightly
absolute given C12, but not a misstatement of anything shipped.

**MAJOR-7: CLOSED.**

---

## Write-gate spot-check

All runs in a `SPEC_LINT_REPO_OVERRIDE` temp tree at `/tmp/pr6mut2` seeded with a 140-file copy of
`.factory/specs`. Verification after every invocation was a full recursive `shasum` manifest diff over all
140 files. **The real `.factory/specs/` was never a write target.**

| Generator | argv | rc | tree | gate that fired |
|---|---|---|---|---|
| `gen-bc-traceability` | *(bare)* | 1 | **CLEAN** | Gate 1 — "bare invocation does not write." |
| `gen-bc-traceability` | `--write` | 1 | **CLEAN** | Gate 2 — "BLOCKED — write mode disabled pending BI-041 adjudication." |
| `gen-bc-traceability` | `--dry-run` | 0 | **CLEAN** | preview only |
| `gen-bc-traceability` | `--check` | 1 | **CLEAN** | ran, non-destructive (786 diff lines / 66 files — known, out of scope) |
| `gen-bc-traceability` | *import* → `update_bc_file(f, v, False)` on a real BC file | `RuntimeError` | **CLEAN**, file byte-identical | function-level gate |
| `gen-slug-corpus` | *(bare)* | 1 | **CLEAN** | "bare invocation does not write." |
| `gen-slug-corpus` | `--dry-run` | 0 | **CLEAN** | preview only |
| `gen-slug-corpus` | `--check` | 1 | **CLEAN** | ran, non-destructive (2 cosmetic lines — known) |

**Not weakened.** The +25 lines are comments; there is no executable change. Independently reconfirmed that
no write statement remains in `gen-bc-traceability.py`:
`grep -nE 'write_text|open\(.*[\x27"]w|\.write\(' scripts/spec-lint/gen-bc-traceability.py` → **NONE**.

---

## No regression

| Check | Result |
|---|---|
| Selftest count — **counted myself** | `TESTS_RUN` increments: **49**. `EXPECTED_TEST_COUNT=49`. Live run: `Selftest passed: 49/49`, rc=0. Consistent. |
| Sandbox reproduces baseline | `git archive 06b58b6` + copied `.factory/specs` → **49/49, rc=0**, so every mutation result above is measured against a valid baseline |
| All checkers clean on live tree | **PASS** — 8/9 rc=0; only `check-placeholders` rc=1 |
| `check-placeholders` = 25 advisory placeholders | **PASS** — `25 placeholder occurrences found (133 files checked)`; identical count in CI |
| `check-canonical-facts` on live tree | **PASS** — `OK — all 31 bindings match canonical values (11 facts)` |
| CI ran all 9 checkers | **PASS** — CI log shows all 9 `── check-… ──` banners incl. `check-canonical-facts`; `spec-lint FAILED: 1/9` |
| `git status` clean | **PASS** — empty, before and after all work |
| Nothing under `.factory/specs/` modified (D-058) | **PASS** — `.factory` worktree shows only `logs/*.jsonl`, `sidecar-learning.md`, and this review's `code-delivery/` dir |
| Nothing under `.factory/holdout-scenarios/` modified | **PASS** |
| `check-index-integrity.py` byte-identical to develop | **PASS** — `0035ab6922ea9c` both sides |
| Non-`Spec lint` CI | **PASS** — Format, Clippy, Test, Build release, GitGuardian all green |

---

## Findings

No BLOCKING findings.

### MAJOR-A — MAJOR-6's false mutation-verify claim survives verbatim in the selftest headers
**File:** `scripts/spec-lint/selftest/run-selftests.sh:1379–1380` (test 26 header) and `:1442–1443` (test 27 header)
**Category:** description accuracy / test sensitivity — incomplete fix of an in-scope MAJOR

MAJOR-6 was raised because in-code comments asserted a mutation-verification for the two `main()` gates that
no longer holds. The delta corrected `gen-bc-traceability.py` in both places. It did **not** correct the two
selftest headers, which carry the same claims — and `run-selftests.sh` is the file this delta rewrote 172
lines of. `git diff -U0 0ad5c5e..06b58b6` hunk ranges are 1287–1362 and 1576–1679; neither cited line is in
them. `git log -L` dates both to `a642d24`.

Line 1379–1380, verbatim and unedited:

```bash
# Mutation-verify: removing the BI-041 guard block (Gate 2) in gen-bc-traceability.py
# causes --write to exit 0, flipping this test's defect-fail assertion to FAIL.
```

**Failure scenario — measured, not argued.** I neutered Gate 2 alone (MUT-G) in a sandbox at this exact SHA:

```
--write, Gate 2 gone: rc=1
RuntimeError: update_bc_file(BC-2.99.001.md): write mode blocked pending BI-041 adjudication. …
file byte-identical: YES        output mentions BI-041: 1
suite rc=0  →  Selftest passed: 49/49
selftest 26: PASS (clean-pass confirmed; --write correctly blocked by BI-041 guard (Gate 2))
```

`--write` exits **1**, not 0. Test 26 **passes**. The suite stays **49/49 GREEN**. The comment asserts the
precise opposite, and it does so in the place a maintainer working BI-041 would look first — a test's own
header is the authoritative statement of what that test detects. The gate it describes even points the
reader at itself ("See Gate 2 guard in `main()`"), so the two records now contradict each other:
`gen-bc-traceability.py:331` says "NOT independently verifiable for this gate alone" while
`run-selftests.sh:1379` says removal flips the test.

Line 1442–1443 is the second instance — right conclusion, wrong mechanism:

```bash
# Mutation note: removing ONLY Gate 1 leaves Gate 2 (BI-041) still active.
# Gate 2 also refuses write mode, so the byte-identical assertion continues to pass.
```

Gate 2 is `if write_mode:`, which is `False` for a bare invocation, so Gate 2 does **not** fire on this path.
MUT-F's traceback shows the refusal comes from `update_bc_file` line 271. This is prior MINOR-B's exact
misattribution, repaired in the `.py` and left standing here.

**Severity reasoning.** Not BLOCKING: I verified (MUT-H, MUT-I) that removing either `main()` gate *together
with* the function-level guard **does** flip its test, so no unguarded-write state is reachable without the
suite going red. Safety was intact in all four mutations, and the tree stayed byte-identical in every
refusal path. The harm ceiling is a maintainer's mistaken belief about test sensitivity. But MAJOR-6 is a
record-accuracy finding whose assigned closure criterion is "state what is actually true," and at these two
lines the record is still false — so MAJOR-6 cannot be reported closed.

**Fix (two comments, no code):**
```bash
# Mutation-verify status: this test does NOT isolate Gate 2. Removing Gate 2 alone leaves
# --write exiting non-zero via the function-level RuntimeError in update_bc_file, whose
# message also contains "BI-041" — so the grep below still matches and this test stays green.
# Gate 2 AND the function-level guard must both be removed for this assertion to flip
# (verified: it does flip in that case).
```
and at 1442–1443, replace "Gate 2 also refuses write mode" with "the function-level write gate in
`update_bc_file` raises before any write". Consider adding a `grep -q "Gate 2"`-style assertion on each
gate's *specific* stderr text so each gate becomes individually isolable, which would let all three comments
say something stronger.

### MINOR-1 — A trailing inline comment on an active entry produces a fail-closed false positive
**File:** `scripts/spec-lint/selftest/run-selftests.sh:1598–1611` (`_get_active_checks`)
**Category:** robustness / false positive (safe direction)

`"check-foo"  # temporarily off` survives the `#`-prefix test (the line's first non-space character is `"`),
so awk emits `check-foo  # temporarily off` and `grep -qx` fails. Bash, by contrast, *does* honour an inline
`#` at a word boundary inside an array assignment, so the checker runs. Verified: awk → one mangled entry,
bash → `check-foo`. The guard therefore fires spuriously. This is the **safe** direction — a loud, wrong
"missing from active array" beats a silent hole — so it is a nuisance, not a defect. Same class as C10
(single-quoted entries) and C6 (line continuations). **Fix if convenient:** strip a trailing `#…` before the
quote-stripping `gsub`, i.e. `sub(/[[:space:]]*#.*$/, "")` after the leading-whitespace `sub`.

### MINOR-2 — The extraction unions every `CHECKS=(` block in the file, so a second array can mask a demotion
**File:** `scripts/spec-lint/selftest/run-selftests.sh:1599–1611` (`_get_active_checks`)
**Category:** robustness / latent unsafe-direction divergence

`_get_active_checks` re-arms on every `CHECKS=(` match and closes on the next `)`, so its output is the
**union** of all arrays in the file. Bash executes only the array in the code path it reaches. Verified — the
one unsafe-direction divergence I found:

```yaml
      - name: spec-lint (blocking)
        run: |
          CHECKS=( "check-title-sync"
            # "check-canonical-facts" )
      - name: spec-lint advisory (never gates)
        continue-on-error: true
        run: |
          CHECKS=( "check-canonical-facts" )
```
→ `AWK-DERIVED: check-title-sync, check-canonical-facts`. The guard reports nothing missing while the
gating step does not run the checker.

**Why I graded this MINOR rather than BLOCKING**, given the mandate's rule that unsafe-direction divergence
is blocking: the divergence is **not present in the artifact under review**. `CHECKS=(` occurs exactly once
in each real file (`ci.yml:232`, `justfile:196`), and I verified derived == bash-actual byte-for-byte on
both. Reaching the divergence needs a deliberate structural edit adding a second array — not the one-line
expedient comment-out that MAJOR-4 was about, and precisely the kind of change that gets reviewed. Every
*accidental* route to a second array (copy-pasting the spec-lint step into another job) duplicates the same
membership, so the union equals each block and nothing is masked. The realistic trigger is a future
blocking/advisory split of `CHECKS` — plausible given `check-placeholders` is already advisory by ruling
(D-029/D-032) — which is why it is worth recording now. Flagging for operator ruling rather than deciding it
unilaterally. **Fix:** bind extraction to the first block only (`in_array && seen { next }`), or assert
exactly one `CHECKS=(` per runner file and fail the guard if that count changes.

### MINOR-3 — Test 25 inverts the suite's stated clean-pass contract while still counting toward its structural guard
**File:** `scripts/spec-lint/selftest/run-selftests.sh:1288–1302` (test 25 header), `:1339–1352`
**Category:** invariant clarity

The suite header (lines 3–13) states every test asserts "(a) clean-pass: checker exits 0 on the clean fixture
tree; (b) defect-fail: checker exits non-zero after injecting the defect," and the post-test structural guard
enforces that each test increments `TESTS_WITH_CLEAN_PASS`. Test 25 now inverts both poles: its clean pass
requires exit **non-zero** and its "defect" step requires exit **0**. The inversion is correct for what the
test proves, is documented in the test's own header, and both directions are mutation-verified (MUT-A,
MUT-B2), so the test is not vacuous — but the `47/49` structural-guard message under MUT-A is now measuring
something different for test 25 than for the other 48. Worth one line in the suite header noting that tests
25 and 30 assert fail-closed refusal as their clean state, so a reader does not over-read the guard's
"clean-pass" wording.

---

## What remains open after this PR

1. **MAJOR-A** — two stale mutation-verify comments at `run-selftests.sh:1379–1380` and `:1442–1443`. The
   only reason this review is not an APPROVE.
2. **BI-021 from a real linked worktree** — fail-closed refusal naming `SPEC_LINT_REPO_OVERRIDE`. Accepted;
   now correctly recorded in both the docstring and the PR body, and pinned by mutation-verified test 25.
3. **BI-041** — `gen-bc-traceability` write mode lossy (~20+ annotated rows incl. INC-MAP-002/003/004).
   Deferred. Mitigated by Gate 1 + Gate 2 + a function-level guard, with the *joint* protection
   mutation-verified (MUT-H/MUT-I) even though no single gate is isolable.
4. **BI-042 / D-073** — 17 of 31 bindings tautological, incl. all FACT-9 and all FACT-10. Merging under
   D-073; first work item once `.factory/specs` is released. Now recorded in the PR body.
5. **Prior MAJOR-3** — `parent.parent.parent` in 8 other checkers and both generators. Fails closed.
6. **`.git`-less working-tree residual** — now documented in the `_find_repo_root()` docstring and the PR body.
7. **Live `--check` divergence** — 786 lines / 2 cosmetic lines. Disclosed in both docstrings.
8. **MINOR-1, MINOR-2, MINOR-3** above.

## What I verified and found sound

- **MAJOR-4 closed.** awk-derived active list == bash-actual expansion byte-for-byte on both real runners.
  The comment-out bypass (prior A2) is detected on both arms. Fourteen attack cases run; the only
  unsafe-direction divergence needs a second `CHECKS=(` block that does not exist in either file.
- **Both meta-guard arms independently mutation-verified** (MUT-D, MUT-E) — prior MINOR-F closed. Prior M10
  no longer reproduces.
- **MAJOR-5 closed.** Test 25 pins the real linked-worktree refusal with a genuine `gitdir:` pointer file and
  is mutation-verified in both directions (MUT-A flips the clean pass; MUT-B2 flips the override step).
- **MAJOR-6 explanation is true in every particular** — MUT-F, MUT-G, MUT-H and MUT-I all behave exactly as
  the implementer described, including the positive claim that the joint removal *does* flip its test.
- **MAJOR-7 closed.** Nine specific body claims checked; all accurate, none softened. Prior MINOR-A/B/C
  discharged.
- **Write gates not weakened.** Eight invocation paths plus the import path, every one leaving all 140 files
  byte-identical. No write statement remains in `gen-bc-traceability.py`.
- **Delta genuinely confined.** The two `.py` files changed comments and docstrings only — zero executable
  change, and live resolution reconfirmed at 31 bindings / 11 facts.
- **49/49 by my own count** (49 `TESTS_RUN` increments, `EXPECTED_TEST_COUNT=49`, rc=0), reproduced
  independently in a `git archive` sandbox so every mutation is measured against a valid baseline.
- **No regression.** 8/9 checkers clean, 25 advisory placeholders matching CI exactly, `git status` clean,
  D-058 respected, `check-index-integrity.py` at `0035ab6922ea9c` on both sides.

---

## Freshness statement

This review covers **`06b58b6f935193e75d8239aacdd49b65cda0ea8a`** and no other commit. The head SHA was
verified against `gh pr view 6 --json headRefOid` before any analysis began; no drift. The delta examined is
`0ad5c5e..06b58b6`. All execution evidence — the 49/49 suite run, mutations MUT-A/B/B2 (boundary stop and
override), MUT-C/D/E (meta-guard arms), MUT-F/G/H/I (the two `main()` gates and the function-level guard),
the fourteen-case awk attack matrix, the derived-vs-bash-actual equivalence checks on both real runner files,
and the write-gate spot-check — was produced against this SHA, using a `git archive 06b58b6` sandbox and
`SPEC_LINT_REPO_OVERRIDE` temp trees. Every mutated file was restored and confirmed byte-identical to the
head version afterwards. No file in the working tree was modified; `git status` was clean before and after.
Findings may not hold for any later commit.

*Note: `gh pr review` is unsatisfiable on this PR (BI-039 — GraphQL "Can not request changes on your own pull
request", root cause D-021). Not attempted. Posted via `gh pr comment` as pre-authorized. Merge authority
remains the orchestrator's; this review does not merge or approve via the GitHub merge API.*
