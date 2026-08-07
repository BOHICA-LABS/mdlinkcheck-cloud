# D-028 Scoped Confirmatory Review — PR #6 @ `90840ca`

**Head SHA verified:** `90840ca1c59c52859b4ca3f08ea44577ee6b4273` via `gh pr view 6 --json headRefOid` — matches
mandate, no drift. Base `develop` @ `651ee3a`.
**Delta reviewed:** `06b58b6..90840ca` — 1 commit, **1 file**, +43/−5.
**`Spec lint` CI FAILURE treated as ADVISORY** per D-029/D-032 — not reported as blocking.
**Out of scope per mandate, not re-raised:** BI-040; BI-041; BI-042 / BI-035 half-discharge (D-073); BI-021
remaining open; prior MAJOR-3; the `.git`-less `git archive` residual; the live `--check` divergence.

## Verdict

APPROVE

Both open items are closed, and MINOR-2 is closed better than the ruling asked for. The ruling asked for a
loud failure in place of cleverer parsing. What shipped is a loud failure *plus* a structural property that
eliminates the unsafe direction outright rather than merely detecting it: the block counter and the entry
extractor use the **identical** regex `/CHECKS=\(/`, and `in_array` can only be armed by a line that also
increments the count. Therefore `block_count == 1` implies exactly one arming line, which implies at most one
contiguous extracted region, which makes a cross-block union **impossible** — not unlikely, impossible. The
hazard MINOR-2 named (a demoted checker still reading as active because two blocks were silently unioned)
cannot occur in the passing path, and cannot occur in the failing path either because the failing path is
loud. I proved this by construction and then attacked it at both boundary shapes.

MAJOR-6 is closed. Both false strings are gone from the harness, the replacement text at `1379–1383` agrees
in substance with the authoritative statement at `gen-bc-traceability.py:331`, and a grep of the whole
harness finds no surviving claim that either `main()` gate is independently mutation-verifiable — both sites
now say the opposite, explicitly.

I confirmed rather than assumed everything the mandate listed as pre-verified, and I did the one thing the
mandate flagged as genuinely new code properly: 13 adversarial fixtures against the new guard, each compared
to what **bash actually expands**, plus an end-to-end propagation test using the verbatim shipped bytes.
Nothing regressed: 49/49, all 9 checkers run, three write gates refuse with the tree byte-identical, working
tree clean.

Two NITs, neither a merge consideration. Both recorded below and carried on the open-at-merge list.

---

## Delta confinement — `06b58b6..90840ca`

```
scripts/spec-lint/selftest/run-selftests.sh | 48 ++++++++++++++++++++++++++---
1 file changed, 43 insertions(+), 5 deletions(-)
```

| Check | Result |
|---|---|
| Delta touches ONLY `run-selftests.sh` | **PASS** — single file, single commit. |
| No `.py` file in the delta | **PASS** — `git diff --name-only 06b58b6..90840ca \| grep '\.py$'` → 0 matches. |
| `check-index-integrity.py` absent from the whole PR diff | **PASS** — not among the 6 changed files. |
| `check-index-integrity.py` byte-identical to develop | **PASS** — `git show 90840ca:…` → `0035ab6922ea9c`; `git show 651ee3a:…` → `0035ab6922ea9c`. Matches the recorded hash. |
| No `.factory/specs/` path in the PR (D-058) | **PASS** — `git diff --name-only 651ee3a..90840ca \| grep '^\.factory/'` → 0 matches. |
| No `.factory/holdout-scenarios/` path in the PR | **PASS** — same evidence. |
| Whole-PR file set unchanged from prior review | **PASS** — still exactly 6 files: `ci.yml`, `justfile`, `check-canonical-facts.py`, `gen-bc-traceability.py`, `gen-slug-corpus.py`, `run-selftests.sh`. |
| Change confined to the two assigned items | **PASS** — 2 comment-block rewrites (MAJOR-6), 1 guard + 1 defect arm + 1 PASS-message update (MINOR-2). No drive-by refactor, no new dependency, nothing outside `scripts/spec-lint/selftest/`. |
| Diff size | 43 insertions — far under the 500-line flag. |

---

## MAJOR-6 closure

**Authoritative statement** — `gen-bc-traceability.py:331–336`:

> `Mutation-verify status: NOT independently verifiable for this gate alone. Removing only Gate 2 does not
> flip selftest 26: --write then reaches the function-level RuntimeError in update_bc_file, which also prints
> "BI-041" in its message. … Both Gate 2 AND the function-level guard must be removed simultaneously for
> --write to actually write files and exit 0.`

**Site 1 — harness `1379–1383`** (was the verbatim-surviving false claim):

> `Mutation-verify status: NOT independently verifiable. Removing only Gate 2 does not flip this test to FAIL:
> --write then hits the function-level RuntimeError in update_bc_file, whose message also contains "BI-041" —
> the grep still matches and the suite stays green. Both Gate 2 AND the function-level guard must be removed
> simultaneously for --write to succeed and for exit code to become 0.`

Agrees with `:331` on all three load-bearing points: the verdict (not independently verifiable), the
mechanism (function-level `RuntimeError` in `update_bc_file`, not Gate 2), and the reason the suite stays
green (the `"BI-041"` substring still matches the grep).

**Site 2 — harness `1445–1448`**:

> `Mutation note: removing ONLY Gate 1 does not flip this test. --write is not passed in the defect step so
> Gate 2 is irrelevant; the byte-identical assertion passes because the function-level RuntimeError in
> update_bc_file prevents any write. Only removing Gate 1 AND that RuntimeError simultaneously allows writes.`

Correctly names the function-level `RuntimeError` as the refusal mechanism and correctly identifies Gate 2 as
irrelevant on this path (no `--write`).

**Whole-harness grep for surviving false or over-claiming statements:**

| Query | Result |
|---|---|
| `causes --write to exit 0` | **0 matches** — gone |
| `flipping this test's defect-fail` | **0 matches** — gone |
| `removing the BI-041 guard block` | **0 matches** — gone |
| Any claim a `main()` gate is independently mutation-verifiable | **0 matches** — every `Gate 1`/`Gate 2` mutation note (lines 1376, 1377, 1379–1383, 1417, 1418, 1422, 1427, 1438, 1442, 1445–1451) either states the opposite or makes no verifiability claim |

**MAJOR-6: CLOSED.** The assigned closure criterion — the comments now state what is true rather than
claiming verification that does not exist — is met at both sites, and neither contradicts `:331`.

### NIT-1 (record precision, not correctness)

`run-selftests.sh:1449` — `# Full isolation of Gate 1 requires removing BOTH gates — tested jointly.` — is a
leftover from the pre-fix text and now sits awkwardly beside the corrected `1445–1448`. Lines 1445–1448 have
just established that the co-requisite pair is **Gate 1 + the function-level `RuntimeError`**; line 1449's
"BOTH gates" then reads most naturally as Gate 1 + Gate 2, which is exactly the pair the preceding lines
disclaim. This is an ambiguous antecedent, not a false claim: line 1449 asserts *non*-isolability, so it does
not reintroduce the over-claim MAJOR-6 was raised about, and the very next line correctly points the reader
at selftest 28 for an independently verifiable analogue. Suggested wording if touched later:
`Full isolation of Gate 1 requires removing Gate 1 and the function-level RuntimeError — tested jointly.`
Not worth a cycle on its own.

---

## MINOR-2 guard attack matrix

The block counter is new code, so I attacked it directly rather than reading it. Method: for each fixture I
ran the **shipped** `_get_active_checks()` (extracted verbatim from the `90840ca` blob, not retyped), recorded
`block_count`, the return status, and the derived entry list; then separately `source`d the same fixture in a
bash subshell and captured `"${CHECKS[*]}"`. Verdicts compare the guard's view to what bash **actually**
expands. "Unsafe" means the guard would report a checker as active when bash does not run it.

**Real runner files first** — the only files the guard is applied to in the live path:

```
.github/workflows/ci.yml : CHECKS=( occurrences = 1  (line 232)  → guard passes
justfile                 : CHECKS=( occurrences = 1  (line 196)  → guard passes
```

Neither real runner exhibits any of the false-positive shapes below.

| # | Fixture | `block_count` | rc | Derived | bash-actual | Verdict |
|---|---|---|---|---|---|---|
| G1 | Two full blocks, second demotes (**the MINOR-2 scenario**) | 2 | **1** | ∅ | `b` | **CLOSED — guard fires** ✓ |
| G2 | `CHECKS+=(` append form | 1 | 0 | `a` | `a b` | **safe** — `b` reported missing, loud |
| G3 | One-line `CHECKS=("a" "b")` | 1 | 0 | ∅ | `a b` | **safe** — all reported missing, maximally loud |
| G4 | `# CHECKS=(` in a trailing comment | 2 | **1** | ∅ | `a` | **safe FP** — loud refusal (see MINOR-3) |
| G5 | `# CHECKS=(` in a comment **above** the real array | 2 | **1** | ∅ | `a b` | **safe FP** — loud refusal (see MINOR-3) |
| G6 | Literal inside a quoted string (`X="text CHECKS=( literal"`) | 2 | **1** | ∅ | `a` | **safe FP** — loud refusal |
| G7 | Literal inside a **heredoc** body | 2 | **1** | ∅ | `a` | **safe FP** — loud refusal |
| G8 | Literal inside an `echo` | 2 | **1** | ∅ | `a` | **safe FP** — loud refusal |
| G9 | **CRLF** line endings | 1 | 0 | `a\r` | bash fails to parse array | **safe** — `a\r` fails `grep -qx`, reported missing |
| G10 | `NOCHECKS=(` (unanchored prefix match) | 2 | **1** | ∅ | `b` | **safe FP** — loud refusal |
| G11 | Two assignments on **one line**: `CHECKS=( "a" ); CHECKS=( "b" )` | 1 | 0 | ∅ | `b` | **safe** — count understates (1 vs 2) but extractor `next`s the whole line → ∅ → maximally loud |
| G12 | Same-line re-arm into multiline: `CHECKS=( "a" ); CHECKS=(`⏎`"b"`⏎`)` | 1 | 0 | `b` | `b` | **MATCH** ✓ — derived == bash-actual |
| G13 | Re-arm on the closing line: `)`; `CHECKS=(` on same line | 2 | **1** | ∅ | `b` | **CLOSED — guard fires** ✓ |

**Zero unsafe-direction divergences.** Every divergence is either a loud refusal (rc=1) or an empty/partial
derived list that causes checkers to be reported *missing* — the maximally loud direction. Prior MINOR-2
(case C12, the only unsafe-direction finding in the `06b58b6` matrix) is the G1 row: **closed**.

### Why this is structural, not lucky

The counter (`awk '/CHECKS=\(/{c++}'`) and the extractor (`awk '/CHECKS=\(/ { in_array=1; next }'`) use the
**same regex**. `in_array` can be set only by a line matching it, and every line matching it increments the
count. Consequently:

- `block_count == 1` ⇒ exactly one matching line ⇒ `in_array` is armed at most once ⇒ the extractor reads at
  most **one** contiguous region. A union across two blocks is unreachable in the passing path.
- Two or more matching lines ⇒ `block_count >= 2` ⇒ rc=1, loud refusal. The union is unreachable in the
  failing path too.

G11/G12 are the only shapes where the *line*-based count understates the number of real assignments, and both
resolve safely because the `next` on the arming line discards that line's inline entries: G11 → ∅ (loud),
G12 → exactly bash-actual. So the unsafe direction is eliminated by construction, not merely detected.

### Does the loud failure actually propagate?

This was the sharpest question in the mandate — a guard that writes to stderr and returns 0 would be worse
than none. The harness runs under `set -uo pipefail`, **not** `set -e`, and the call sites are
`CI_ACTIVE=$(_get_active_checks "$REPO/.github/workflows/ci.yml")` (harness line 1631), which **discards the
return code**. So I tested it end-to-end rather than reasoning about it.

Method: extracted harness lines `1608–1658` verbatim from the `90840ca` blob (the function plus the entire
clean-pass block through `FAILURES=$((FAILURES + 1))`) and executed those exact bytes against a synthesized
`$REPO` whose `ci.yml` is the **real** `ci.yml` with a second, advisory-style `CHECKS=(` block appended —
precisely the future scenario MINOR-2 predicted. `justfile` is the real one, unmodified.

```
########## ARM 1: 2-block ci.yml (the future-demotion scenario) ##########
META-GUARD ERROR: …/ci.yml contains 2 CHECKS=( block(s) — expected exactly 1.
  The guard's assumption (one authoritative array per runner file) has been invalidated.
  Update the guard to name the authoritative array before proceeding.
  STRUCTURAL FAIL (clean-pass): checker(s) absent from active CHECKS array:
    MISSING from ci.yml active array: check-adr-consistency
    … (all 9 checkers listed) …
RESULT: FAILURES=1 CLEAN_PASS=0 RUNNER_MISSING=1

########## ARM 2: control — real repo, 1 block ##########
RESULT: FAILURES=0 CLEAN_PASS=1 RUNNER_MISSING=0
```

**Confirmed: test 29's clean-pass arm goes RED if the real runners ever gain a second block**, the three
stderr lines surface, and `FAILURES` increments (→ suite `exit 1`). The control arm confirms the test is not
trivially red. Note the *mechanism*: redness arrives via the empty stdout making all 9 checkers read as
missing, not via the discarded `return 1`. The outcome is correct and loud either way — see NIT-2.

### NIT-2 (defence-in-depth, safe today)

`run-selftests.sh:1631–1632` discard `_get_active_checks`'s exit status. Today the loud failure still lands,
because empty output forces a `STRUCTURAL FAIL`, and I verified that end-to-end above. But the loudness rides
on a side channel rather than on the signal the guard was written to emit. The degenerate case that would
defeat it — `$LINT_DIR/check-*.py` matching zero files, leaving the `for` loop unentered and `RUNNER_MISSING`
at 0 — is pre-existing and not introduced by this delta (9 checkers present, and the harness has a pre-flight
guard). Belt-and-braces if touched later:
`CI_ACTIVE=$(_get_active_checks "$REPO/.github/workflows/ci.yml") || exit 2`. Not worth a cycle.

### MINOR-3 (accepted, safe direction)

The count guard introduces a false-positive class that the previous extractor handled cleanly: G5 — a
`# CHECKS=(` comment *above* the real array — was verdict **MATCH ✓** (prior case C13) and now trips a loud
refusal. Same for the literal appearing in a string (G6), a heredoc (G7), an `echo` (G8), or as the tail of a
longer identifier such as `NOCHECKS=(` (G10). All are strictly safe-direction: the guard refuses loudly with
a message that names the remedy. Neither real runner file contains any of these shapes (both count = 1,
verified above), so the live path is unaffected. This is the correct trade under the ruling — fail loudly
rather than parse more cleverly — and I am recording it, not objecting to it.

---

## Defect C mutation result

Defect C is **genuinely asserted, not merely present**. Mutation performed on the verbatim shipped bytes
(harness `1608–1724`, the function plus all three defect arms) by deleting exactly the 8-line `block_count`
guard (`local block_count` through its closing `fi`) and nothing else:

| Run | Output | `FAILURES` | `ALL_ARM_DEFECTS_DETECTED` |
|---|---|---|---|
| **Baseline** (shipped) | `PASS (clean-pass confirmed; ci.yml and justfile arms detect commented-out entry; two-array fixture rejected)` | 0 | 1 |
| **Mutant** (guard deleted) | `FAIL (two-array fixture: guard did NOT reject file with two CHECKS=( blocks)` | **1** | **0** |

Removing the check flips the arm and increments `FAILURES`, which takes the suite to `exit 1`. Not vacuous.

Two further confirmations:

- The fixture is a genuine two-array file (`awk` count = 2) whose *second* block demotes — i.e. it encodes the
  exact blocking/advisory-split scenario MINOR-2 described, not a synthetic duplicate.
- Defect C's assertion inverts correctly: `if _get_active_checks … ; then FAIL` — success is the failure
  condition, so the arm cannot pass by the function erroring for an unrelated reason and returning 0.

**Selftest count did not rise, legitimately.** `TESTS_RUN=$((TESTS_RUN + 1))` appears exactly **49** times in
the head blob, `EXPECTED_TEST_COUNT=49`, and Defect C was added as a third defect arm *inside* test 29 rather
than as a new test — so no increment was due. The harness's own post-test structural guard (`1229–1233`)
would have exited 2 on any mismatch; it did not fire.

---

## Regression + write-gate spot-check

**Full suite at `90840ca`, counted independently:**

```
Selftest passed: 49/49 negative tests verified (each proved clean-pass + defect-fail)
SUITE RC=0
── selftest 29: meta-guard: every check-*.py is in the active CHECKS array (both runners) ──
  PASS (clean-pass confirmed; ci.yml and justfile arms detect commented-out entry; two-array fixture rejected)
```

`TESTS_RUN` increments counted from source = 49 = `EXPECTED_TEST_COUNT`. `RC=0` also proves the second
post-test invariant held — `TESTS_WITH_CLEAN_PASS == TESTS_RUN` — so no test is structurally vacuous.

**`just spec-lint` — all 9 checkers ran; exactly one advisory failure:**

```
Check FAILED: 25 placeholder occurrences found (133 files checked)   ← check-placeholders (advisory)
canonical-facts: OK — all 31 bindings match canonical values (11 facts)
spec-lint FAILED: 1/9 checks failed
```

Matches the expected state exactly: sole failure `check-placeholders`, 25 known advisory placeholders, 133
files. All 9 checkers including `check-canonical-facts` executed. Advisory per D-029/D-032 — **not blocking**.

**Write gates — `SPEC_LINT_REPO_OVERRIDE` temp tree only, real `.factory/specs/` never touched:**

| Path | Message | Exit |
|---|---|---|
| `gen-bc-traceability.py` bare (Gate 1) | `bare invocation does not write.` | **1** ✓ |
| `gen-bc-traceability.py --write` (Gate 2) | `BLOCKED — write mode disabled pending BI-041 adjudication.` | **1** ✓ |
| `gen-slug-corpus.py` bare | `bare invocation does not write.` | **1** ✓ |
| `gen-bc-traceability.py --dry-run` (control) | — | **0** ✓ |

**Temp tree BYTE-IDENTICAL** before and after all four invocations (recursive `shasum` over the tree,
path-normalised). The `--dry-run` control returning 0 proves the gates are selective rather than refusing
everything, so the refusals are meaningful.

**Working tree:** `git status --porcelain` → empty, before and after every step of this review. No file was
modified except the two review artefacts.

---

## Findings

| Severity | Category | Finding | Suggestion |
|---|---|---|---|
| nit | record-precision | **NIT-1** — `run-selftests.sh:1449` `"Full isolation of Gate 1 requires removing BOTH gates"` is leftover text; "BOTH gates" now reads as Gate 1 + Gate 2, but `1445–1448` just established the co-requisite pair is Gate 1 + the function-level `RuntimeError`. Ambiguous antecedent, not a false verifiability claim. | Reword to `…requires removing Gate 1 and the function-level RuntimeError — tested jointly.` Fold into any future touch of this file. |
| nit | defence-in-depth | **NIT-2** — `run-selftests.sh:1631–1632` discard `_get_active_checks`'s `return 1`; redness on a two-block runner arrives via empty stdout, not the guard's own signal. Verified loud end-to-end today. | `CI_ACTIVE=$(_get_active_checks …) \|\| exit 2` on both call sites. |
| nit | safe-direction FP | **MINOR-3** — count guard now refuses files containing `CHECKS=(` inside a comment, string, heredoc, `echo`, or as a longer identifier (`NOCHECKS=(`). G5 in particular was a clean MATCH before this delta. All refusals are loud; neither real runner file is affected. | Accept as the intended trade under the ruling. If it ever bites, anchor the regex (`/^[[:space:]]*CHECKS=\(/`) in **both** the counter and the extractor together — never one alone, or the union-impossibility property breaks. |

No blocking findings. No suggestions above nit level.

**Explicit non-rubber-stamp statement.** This APPROVE rests on execution, not on reading the diff or on
trusting the prior review. I independently: verified the head SHA; confirmed delta confinement and the
`check-index-integrity.py` hash against develop on both sides; grepped the whole harness for surviving false
claims and read the corrected text against `gen-bc-traceability.py:331`; built and ran 13 adversarial fixtures
against the new guard, comparing each to bash's actual array expansion; derived and checked the
union-impossibility property at its two boundary shapes; executed the verbatim shipped clean-pass block
against a synthesized two-block `ci.yml` to prove the failure propagates, with a control arm; mutation-tested
Defect C by deleting exactly the guard; counted the 49 `TESTS_RUN` increments from source; ran the full suite,
`just spec-lint`, and four generator invocations with a byte-identical-tree assertion.

---

## Freshness statement

This review covers PR #6 at head **`90840ca`** (`90840ca1c59c52859b4ca3f08ea44577ee6b4273`), verified live via
`gh pr view 6 --json headRefOid` at review time, against base `develop` @ `651ee3a`. All execution evidence
above was produced from a working tree at `90840ca` with `git status --porcelain` empty. Every claim in this
document is scoped to that SHA. Findings and verdict do not carry to any subsequent head; a new head requires
a fresh confirmation, though after this pass only the delta would need re-checking — every load-bearing
property of the guard is now mutation-verified or proved structurally.

---

## Open-at-merge list

Merge this with eyes open. The following are known-open and deliberately carried:

| Item | Status at merge | Why acceptable |
|---|---|---|
| **BI-041** — `gen-bc-traceability` write mode destroys hand-authored INC-MAP annotations | **Open.** Write mode disabled behind two independent gates plus a function-level `RuntimeError`. | Verified this pass: bare → exit 1, `--write` → exit 1, tree byte-identical. `--check`/`--dry-run` remain functional. No unguarded-write end state is reachable without the suite going red. |
| **BI-042 / BI-035 half-discharge** | **Open**, operator ruling **D-073** permits this merge. | Recorded in the PR body; all nine body claims were verified accurate at `06b58b6` and the body is unchanged in this delta. |
| **BI-021** | **Open.** | Accepted: a loud refusal naming `SPEC_LINT_REPO_OVERRIDE` beats a silent false GREEN. |
| **BI-040** | **Open.** | Out of scope per mandate. |
| **MAJOR-3** — `parent.parent.parent` in 8 peer checkers | **Open.** | Fails closed. |
| `check-placeholders` — 25 advisory placeholders | **Open**, `Spec lint` CI FAILURE. | **ADVISORY** per D-029/D-032. All 9 checkers run; this is the sole failure. |
| `.git`-less `git archive` residual | **Open**, documented. | Documented in `check-canonical-facts.py`'s KNOWN RESIDUAL paragraph. |
| Live `--check` divergence (786 / 2 lines) | **Open**, documented. | Non-destructive mode; out of scope per mandate. |
| **NIT-1** — line 1449 ambiguous antecedent | **Open**, this review. | Record precision only; asserts non-isolability, so no over-claim reintroduced. |
| **NIT-2** — discarded `return 1` at lines 1631–1632 | **Open**, this review. | Loud failure verified to propagate end-to-end via the empty-output path. |
| **MINOR-3** — safe-direction false positives in the count guard | **Open**, accepted. | All refusals loud; neither real runner file affected (both count = 1, verified). Intended trade under the ruling. |

Nothing on this list is a correctness or safety blocker at `90840ca`.
