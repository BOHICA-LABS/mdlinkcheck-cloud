# PR #9 Independent Review — head `55113c4c56ae694b4cc6d01178e5924f554742ff`

**Reviewer:** pr-reviewer (fresh context, independent re-derivation per operator ruling D-096)
**PR:** #9 `feature/pol14-test-sufficient` → `develop`
**Prior review at head `87cefbf`:** read for context only; its CHANGES-NEEDED verdict treated as **void** for this head.
**Merge authority:** none in this dispatch. No `covered_sha` field touched. No merge attempted.

---

## VERDICT: CHANGES-NEEDED

**Basis (one sentence):** The two behaviours the PR *claims* — the VP-INDEX JOIN and the two-shape Stories exemption — are genuinely implemented, genuinely fail closed, and genuinely mutation-covered; but the **S1 "Option A" heading-reset fix that is the entire substance of this head is untested**, and three separate live mutations of that exact code block survive the 64-test suite with `exit 0`. Under D-040/D-050/D-057 (runtime positive-coverage assertions are the durable criterion), newly-added load-bearing logic shipping with zero discriminating assertion is a blocking gap.

Severity range (PG-012): **one blocking-class finding**, **low-to-mid single digits** of non-blocking findings.

---

## Ruling on the Central Question (M4 kill mechanism)

**The premise in the dispatch is false, and the finding is therefore stronger than "acceptable under D-065" — the kill is a proper test-local kill and needs no D-065 relief at all.**

The dispatch states the M4 kill "rests on the suite's structural clean-pass guard remaining intact." Reading `run-selftests.sh`, P14-8's clean-pass check is **not** merely a contribution to the suite-wide `TESTS_WITH_CLEAN_PASS` tally. It is a test-local assertion that increments `FAILURES` itself:

```
else
    echo "  STRUCTURAL FAIL: checker rejected [filled by story-writer] under ## Story Anchor — Shape 2 exemption not working"
    ...
    FAILURES=$((FAILURES + 1))
fi
```

Under M4 **both** signals fire. The observed exit code is 2 only because the `TESTS_WITH_CLEAN_PASS` guard is ordered *before* the `FAILURES` check in the post-test block (`run-selftests.sh:4124` precedes `:4132`).

I proved the independence by executed predicate — applying M4 **and** neutralising the suite-wide guard (`if [ "$TESTS_WITH_CLEAN_PASS" -ne "$TESTS_RUN" ]` → `if false`):

```
M4 + suite-guard-neutralised: EXIT=1  P14=9
  Selftest FAILED: 1/64 negative tests failed
  STRUCTURAL FAIL: checker rejected [filled by story-writer] under ## Story Anchor — Shape 2 exemption not working
```

**Ruling:** M4 is killed by P14-8's own clean-pass assertion, which is a *runtime positive-coverage assertion* — exactly the durable criterion D-040/D-050/D-057 name, not a mutation-detection artefact. The suite-wide guard is a redundant second backstop, not the load-bearing one. **No, P14-8 does not need an additional defect assertion to discriminate M4.**

Secondary observation, stated for the record: it is *correct* design that P14-8's defect assertion cannot discriminate M4. The clean-pass assertion discriminates **narrowing** mutations (exemption deleted / under-applied); the defect assertion discriminates **broadening** mutations (M8-class). The pair brackets the behaviour from both sides. Asking one assertion to do both jobs would be the design error.

---

## BLOCKING — B1: the S1 remediation is untested; 3 live mutations of it survive

**File:** `scripts/spec-lint/check-placeholders.py:280-286` (the ATX-heading-tracking block added at this head)

This head exists to apply S1 "Option A": `current_h2_heading` reset by an ATX heading of **any** level. That block has **no discriminating assertion anywhere in the 64-test suite.**

| Mutation | Change | Suite result |
|---|---|---|
| `MS1_revert_heading_reset` | delete the `else: current_h2_heading = None` branch — i.e. **revert S1 exactly** | **EXIT=0, 64/64, P14=9 — SURVIVES** |
| `MX1_atx_guard_removed` | `if _atx_rest.startswith(" ") or not _atx_rest:` → `if True:` | **EXIT=0, 64/64, P14=9 — SURVIVES** |
| `MX3_h2_prefix_loosened` | `line.startswith("## ")` → `line.startswith("#")` | **EXIT=0, 64/64, P14=9 — SURVIVES** |
| `MX2_h2_blanket_anchor` | `current_h2_heading = line[3:].strip()` → `= "Story Anchor"` | EXIT=1, P14-8 + P14-9 fail — killed |

Three of four mutations in the S1 block survive. `MS1` is the literal inverse of the change this head was cut to make.

**These are live mutants, not equivalent mutants** — proven by direct executed predicate on isolated trees (`1` = flagged, `0` = exempt):

| Fixture | HEAD | under `MS1` | under `MB` |
|---|---|---|---|
| A: `## Story Anchor` / `### Details` / `- [filled by story-writer]` | 1 | **0** | 1 |
| B: `## Story Anchor` / `Stories: [filled by story-writer]` (prose, not a bullet) | 1 | 1 | **0** |
| C: `## Story Anchor` / `# Other Doc` / `- [filled by story-writer]` | 1 | **0** | 1 |

Cases A and C flip from flagged to silently exempt under `MS1`; case B flips under `MB`. Real placeholder violations become invisible and no test notices.

**Failure scenario:** a future contributor "simplifies" the `else: current_h2_heading = None` branch away as dead code — the suite stays green at 64/64, and every `- [filled by ...]` bullet appearing after any subheading inside a `## Story Anchor` section is silently exempted for the rest of the file. POL-14 detection is lost with no signal.

**Required fix:** one selftest, `P14-10`, with clean-pass + defect-fail on fixture A (bullet under `### Details` nested inside `## Story Anchor` must be **flagged**). That single test kills `MS1` and `MX3`. A second covering `MB` (prose line under `## Story Anchor` must be flagged) closes the fourth survivor.

**I have not remediated this.** Per stop condition, reporting and stopping.

---

## Non-Blocking Findings — Per-Item Disposition

Every disposition below is backed by an executed probe against isolated trees.

| Item | Executed result | Disposition |
|---|---|---|
| **S2** Shape 1 exempt anywhere / inside fenced blocks | `Stories` row under `## Random Section` → **exit 0 (exempt)**; `Stories` row inside a ``` fence → **exit 0 (exempt)**. Broader than D-093's "inside a Traceability row". **But:** all 25 real-corpus exemptions are legitimate — 24 Shape 1 rows enclosed by `## Traceability`, 1 Shape 2 bullet under `## Story Anchor`; **zero** in fences, **zero** outside Traceability. No live exposure. | **DEFER-with-tracked-issue** |
| **S3** `test-sufficient` accepts EMPTY Proof Method | `test-sufficient` + empty Proof Method → **exit 0 (accepted)**. Contrast, same tree shape: `VP-NONE` + empty Proof Method → **exit 1 (rejected)**. Confirmed asymmetry — a row asserting "tests are sufficient" may name no test, while `VP-NONE` may not (D-078). Real inconsistency, cheap fix (reuse the `proof_method.strip()` gate). | **DEFER-with-tracked-issue** |
| **S4** positional `cells[2]` join | Column inserted before `VP(s)`: → **exit 1**, `VP-INDEX classifies 'BC-0.00.011' as 'alice'`. It **fails CLOSED**, not silently. Mutation `MS4_column_shift` (`cells[2]`→`cells[1]`) is **KILLED** (exit 2). Prior review's "would silently retarget" is not what the code does. Residual risk is a confusing message, not lost detection. | **ACCEPT** |
| **S5** no demo evidence under `docs/` | `git diff --name-only origin/develop...55113c4 -- docs/` → **empty**. PR #8 (`c2e5cf1`) did establish `docs/demo-evidence/BI-040/` (evidence-report.md + 4 per-AC `.txt`). Convention broken. Note the artefacts PR #8 set are `.txt`, not `.gif`/`.webm` — the convention itself is weaker than the standard checklist wants; that is a separate matter. For a pure-CLI lint change, `.txt` transcripts are adequate and cheap. | **DEFER-with-tracked-issue** |
| **N1** duplicate VP-INDEX BC rows last-win | Two rows for `BC-0.00.012` — first `VP-001`, second `test-sufficient` → **exit 0 (accepted)**. Worse than "silently last-win": a duplicate row **launders** a real-VP classification into `test-sufficient`. Mitigated by requiring a VP-INDEX edit, which is itself reviewed. | **DEFER-with-tracked-issue** (raise from nit to suggestion) |
| **N2** misleading message when VP-INDEX absent | VP-INDEX entirely absent → **exit 1** (fails closed ✓), message `'BC-0.00.013' has no row in VP-INDEX; assign a real VP or add a 'test-sufficient' row to VP-INDEX` — never says the file is missing, and advises editing a file that does not exist. Cosmetic. | **ACCEPT** |

### Additional finding not in the prior review — W1: PR description is stale at `87cefbf`

Executed vs. claimed:

| PR body claim | Executed measurement |
|---|---|
| "Selftest suite = 62/62 (EXPECTED_TEST_COUNT 55 → 62)" | **64/64**, `EXPECTED_TEST_COUNT` 55 → **64** |
| "7 new tests P14-1..P14-7, count 55→62" | **9** tests P14-1..**P14-9** |
| "Baseline Movement: 80 → 55" / "em-dash findings 55" | **78 → 53**; em-dash summary `53` |
| Shape 2: "`current_h2_heading` (updated on every `## ` heading outside fenced blocks)" | Omits the S1 reset-on-any-ATX-level behaviour that **is** this head |
| Mutation table lists M1/M2/M3 only | M4 and M8 — the mutations this head was cut to kill — are absent |

The 80→55 vs 78→53 gap is plausibly benign corpus drift (`.factory/specs` is owned by another agent, D-041). The 62-vs-64, 7-vs-9, and missing S1 description are unambiguous staleness. **Disposition: DEFER** (fix the body before merge; not a code defect).

---

## Control-Run and Mutation Evidence

Every run below executed **inside the worktree** `/Users/jmagady/Dev/mdlinkcheck-cloud/.worktrees/pol14-test-sufficient` with `git checkout -- <file>` restore. No temp-dir copy of `scripts/` was used, per the harness warning. `P14` column = `grep -c 'selftest P14-'`, which **must equal 9** for the run to count as evidence.

### Control (unmutated) — 10 consecutive runs

```
run1..run10  EXIT=0  P14=9  Selftest passed: 64/64
```

Post-mutation-campaign control, tree restored: `EXIT=0 P14=9 Selftest passed: 64/64`.

The harness is proven non-vacuous: the P14 block is reached (9/9 headers) and the suite reports the full 64.

### Mutation results — 14 mutations, 9 killed, 5 survived

All runs `P14=9`; all left `tree_dirty=0`.

**KILLED (9):**

| Mutation | Exit | Kill signal |
|---|---|---|
| `M4_delete_shape2` | 2 | `only 63/64 tests had a clean-pass assertion` + P14-8 `STRUCTURAL FAIL: ... Shape 2 exemption not working` |
| `M4` + suite-guard neutralised | 1 | `Selftest FAILED: 1/64` — **P14-8 local assertion alone suffices** |
| `MShape1_delete_shape1` | 2 | P14-6 `STRUCTURAL FAIL: ... Stories field — exemption not working` |
| `M8_blanket_bullet_exempt` | 1 | `2/64 failed` — P14-8 **and** P14-9 defect assertions |
| `MJ1_sentinel_uncond_accept` | 1 | `4/64 failed` — test 3, P14-1, P14-2, P14-3 |
| `MJ2_ignore_missing_row` | 1 | `1/64` — P14-2 |
| `MJ3_ignore_mismatch` | 1 | `1/64` — P14-1 |
| `MJ4_failopen_empty_index` | 1 | `1/64` — P14-2 (**fail-closed property is asserted**) |
| `MS4_column_shift` (`cells[2]`→`cells[1]`) | 2 | P14-1 + P14-3 |
| `MX2_h2_blanket_anchor` | 1 | `2/64` — P14-8 + P14-9 |

**SURVIVED (5):**

| Mutation | Exit | Assessment |
|---|---|---|
| `MS1_revert_heading_reset` | 0 (64/64) | **B1** — new code, live mutant proven |
| `MX1_atx_guard_removed` | 0 (64/64) | **B1** — new code |
| `MX3_h2_prefix_loosened` | 0 (64/64) | **B1** — new code |
| `MB_any_line_under_anchor` | 0 (64/64) | **B1-adjacent** — new code, live mutant proven (case B) |
| `MVPNONE_drop_proof_check` | 0 (64/64) | **PRE-EXISTING, not a regression** — verified below |

`MVPNONE` pre-existence, executed on a clean `origin/develop` worktree:

```
develop CONTROL          exit=0  Selftest passed: 55/55
develop VP-NONE-mutant   exit=0  Selftest passed: 55/55   ← survives on develop too
```

The D-078 `VP-NONE`-requires-Proof-Method gate is uncovered on `develop` as well. Not this PR's regression. **Disposition: DEFER-with-tracked-issue** (pairs naturally with S3).

---

## Confirmations Requested

**Fail-closed behaviour of the sentinel — CONFIRMED genuine, not an allowlist in disguise.** Four independent executed probes:

- VP-INDEX assigns a real VP → rejected, `VP-INDEX classifies 'BC-0.00.001' as 'VP-001'`
- VP-INDEX has no row for the BC → rejected, `'BC-0.00.002' has no row in VP-INDEX`
- VP-INDEX file entirely absent → rejected (exit 1)
- VP-INDEX header first cell ≠ `BC` → `classifications` empty → all sentinels rejected

And the fail-*open* mutation `MJ4` (`if vp_classifications and bc_id not in vp_classifications`) is **killed**, so the fail-closed property is itself asserted at runtime, not merely incidental.

**No pre-existing selftest removed or loosened — CONFIRMED.** The complete set of removed lines in `run-selftests.sh` across the whole diff vs `develop` is exactly one:

```
-EXPECTED_TEST_COUNT=55
```

Test-header set comparison: develop 51 headers, HEAD 60; `comm -23` (missing at HEAD) is **empty**; `comm -13` (added) is exactly `P14-1` … `P14-9`. The change is purely additive.

**`SUPPRESSION_PATTERN` pre-flight guard still passes — CONFIRMED.** `Pre-flight guard passed: 15 checkers/generators scanned, 0 suppression constructs found` in every green control run. Independently: `grep -nE '(ALLOWLIST|_DEFERRAL|SKIP_LIST|SKIP_SET|KNOWN_COLLISIONS|KNOWN_VIOLATIONS|KNOWN_ISSUES|WHITELIST|SUPPRESS_SET)[[:space:]]*[=:]' scripts/spec-lint/*.py` → **rc=1, no matches**. **No allowlist / skip-list / deferral set / known-issues collection introduced (D-039 satisfied).**

**`spec_lint_primitives.py` byte-identical to develop — CONFIRMED** (`git diff --quiet` → IDENTICAL).

**S1 introduced no regression on the real corpus — CONFIRMED.** `78 → 53` findings. Newly-exempt = 25; newly-flagged = **0** (`comm -13` empty). All 25 classified by executed script:

```
  24  shape=Shape1_table_Stories   enclosing_H2=Traceability    prose
   1  shape=Shape2_bullet          enclosing_H2=Story Anchor    prose
```

`BC-2.10.009.md` (the only corpus file with `## Story Anchor`; bullet at line 111) drops from 3 findings on develop to 1 on HEAD — the Story Anchor exemption still works after S1. All 53 remaining findings are `non-conforming VP-NNN column value '—' (POL-14)`; **zero** `[filled by]` remain. Em-dash detection intact.

**Shape 2 bounding.** Now bounded to the span between `## Story Anchor` and the next ATX heading of any level — tighter than `87cefbf` and consistent with D-093's intent. Two residual over-breadths, both untested (`MB`, and S2's fence/section-scope gap). Bounded in practice, still slightly broader than D-093's literal wording.

**Diff size.** 683 insertions / 22 deletions across 4 files — over the 500-line flag threshold, but 439 of the 683 are selftests and 35 are fixtures. Coherent and appropriately weighted. **No finding.**

**Diff coherence.** All four changed paths are within POL-14's blast radius. No unrelated changes. **No finding.**

---

## Contradictions With What This Dispatch Told Me

Recorded per instruction.

1. **"Control (unmutated): 64/64, exit 0" — my *first* control run FAILED.** `EXIT=2`, `P14=0`, `STRUCTURAL GUARD FAILED: check-index-integrity.py lacks SPEC_LINT_REPO_OVERRIDE support`. This is a **pre-existing flake**, not a real guard violation: `run_override_guard` runs `grep -v '^[[:space:]]*#' "$f" | grep -qE ...` under `set -uo pipefail` (`run-selftests.sh:21`). When `grep -q` matches early (line 21 of a 48 KB file — `check-index-integrity.py` is by far the largest checker) it exits and SIGPIPEs the upstream `grep -v`, whose 141 exit status `pipefail` propagates as a guard failure. Reproduction: 1 failure in 11 full-suite runs; the isolated predicate passed 40/40. **Confirmed not introduced by this PR** — `git diff origin/develop...55113c4` over `run-selftests.sh` matches nothing in `run_override_guard|pipefail|OVERRIDE_PATTERN|SUPPRESSION_PATTERN|grep -v`. **Disposition: DEFER-with-tracked-issue** against the shared harness. This flake is dangerous for exactly the reason the dispatch warns about — a spurious `exit 2` can masquerade as a mutation kill. It is distinguishable only by reading the guard message, which is why every row above records the message and the `P14` count rather than a bare exit code.

2. **The M4-kill premise was wrong.** The dispatch says the kill "rests on the suite's structural clean-pass guard remaining intact." It does not — proven by executed experiment (§ Central Question). The kill is test-local.

3. **S4's stated risk does not match behaviour.** The prior review's "inserting a column would silently retarget the join" is contradicted: it fails closed with a diagnostic, and the retarget mutation is killed by the suite.

4. **The dispatch did not flag that the S1 fix has no test.** This is the one blocking finding, and it sits in the change this head was cut to deliver.

---

## What Would Clear This Review

1. Add `P14-10`: clean-pass + defect-fail proving a `- [filled by ...]` bullet under a `###` subheading nested inside `## Story Anchor` is **flagged**. Kills `MS1` and `MX3`.
2. Add `P14-11` (or extend P14-10): prove a non-bullet prose line under `## Story Anchor` is flagged. Kills `MB`.
3. Bump `EXPECTED_TEST_COUNT` to match, and re-run the control to 66/66 with `P14` header count updated.
4. Refresh the PR body to head `55113c4` (test count, mutation table, S1 description, corpus numbers).

Items S2, S3, S5, N1, N2, `MVPNONE`, and the `pipefail` harness flake should be tracked as issues, not fixed in this PR.
