---
document_type: fix-batch-record
level: ops
version: "1.0"
status: in-progress
producer: vsdd-factory:state-manager
story_id: S-1.01
cycle: v1.0.0-greenfield
authorizing_decision: D-261
scope: HIGH+MEDIUM findings from passes 16-18
fix_groups_total: 3
fix_groups_committed: 2
fix_groups_in_flight: 1
timestamp: "2026-08-11T00:00:00Z"
---

# Fix Batch D-261 — HIGH + MEDIUM Remediation Record (S-1.01)

## Status

**IN PROGRESS.** Two of three fix groups are committed to
`feature/S-1.01-workspace-scaffold-and-core-discovery`. The third group
(CI/build configuration) is in flight at the time of this record and will
require a completion update.

## Authorizing Decision

**D-261** — Operator ruled the fix batch covers HIGH and MEDIUM findings
only (14 material on-perimeter findings from passes 16–18). The 9
LOW/NITPICK findings are recorded as register entries BI-072..BI-080 and
DISCLOSED at the wave-1 gate rather than fixed. This converts the
confirming-round criterion into a bounded loop: fix the HIGH+MEDIUM set,
run 3 clean passes, gate.

The confirming round (D-254) ran passes 16, 17, and 18 against the frozen
six-lens perimeter. All three returned MATERIAL_FINDINGS; `passes_clean`
remains 0 of 3. Fix-and-re-run is the process working correctly.

## Commit Ledger (committed)

| Commit | Group | Scope |
|--------|-------|-------|
| `47e11b0` | Production code / docs (`crates/mdlinkcheck/src/scanner.rs`) | 1 file, +41/−5 |
| `366104c` | Tests (`crates/mdlinkcheck/tests/scanner_discovery_tests.rs`) | 1 file, +259/−52 |

Branch: `feature/S-1.01-workspace-scaffold-and-core-discovery`

## Commit `47e11b0` — Production Code / Docs

### P16-01 / P17-03 (HIGH) — L2/L5/L6 — Fixed

`collect_md_files` doc block contradicted itself on dot-FILE exclusion.
The bullet claiming dot-file skipping was "best-effort via `hidden(true)`,
NOT unconditional, subject to override by ignore-rule negation patterns"
was FALSE: the P14-02 post-filter is name-based and runs after the
`is_file()` check, so the filename is itself a path component and
dot-files are rejected structurally. Corrected to state the truth for that
function while PRESERVING the live D-252a defer-and-disclose disclosure.

Also split the post-filter's BC citation: the dot-DIRECTORY arm is
anchored to BC-2.01.004 invariant 1, the dot-FILE arm has NO BC authority
and is now disclosed as such (POLICY 4 semantic-anchoring fix).

The corresponding `build_walk` statements were deliberately left unchanged
because they are literally true for that function, which has no
post-filter.

### P18-03 (HIGH, D-259) — L2 — Remediated (behaviour unchanged)

`.parents(true)` is now set EXPLICITLY in the builder chain (a deliberate
behavioural no-op) and documented in the `build_walk` doc block including
the "# Gitignore vs .ignore" section. The documentation now covers: the
ancestor-ascent semantics, the absence of a repo-root boundary under
`require_git(false)`, that this is operator-ruled intended behaviour
(D-259), and the honest consequence that a user's `$HOME/.gitignore`
applies to scans beneath it with no diagnostic channel (deferred F-A3).

The setter was made explicit specifically because an unwritten setter is
invisible to `cargo mutants` — no mutant can be generated for a
non-existent line, so the option can never be covered by a kill-rate
metric while implicit (L-88).

## Commit `366104c` — Tests

Suite: 42 → **44 tests**. Two new discriminating regression tests plus
four claim-truth defects.

### P17-01 (HIGH) — L3/L6 — Fixed

New test `test_BC_2_01_004_inv1_build_walk_filter_entry_guard_is_active`
calls `build_walk` WITHOUT replacing `filter_entry`, using a `.gitignore`
of `.*` then `!.github` (the ignore-rule negation that defeats
`hidden(true)` — the F-A1 mechanism), asserting no dot-prefixed component
appears, with an F-04 positive gate and byte-wise component comparison.

This closes the fix-integrity regression from P17-01: the P14-02
post-filter had masked `filter_entry` from every test, so removing the
guard left all 42 tests green. The guard that F-01's kill-coverage once
protected was protected by nothing. The new test is the discriminating
lock.

### D-259 lock — new test

New test `test_BC_2_01_003_post1_ancestor_gitignore_honoured_parents_true`
locks the operator-ruled-intended ancestor-ascent behaviour. No `git init`
anywhere in this test's fixture.

### P16-02 (MEDIUM) — L6/L3 — Fixed

Removed the stale `FAILS on current impl` comment and the obsolete
imperative fix prescription inside the F-P2-01 regression lock.
`grep -c "FAILS on current impl"` now returns 0 (was 1).

### P16-03 (MEDIUM) — L3/L6 — Fixed

The module doc no longer asserts RED GATE state ("all 13 AC tests … MUST
fail … No test may pass"); rewritten as the green acceptance corpus,
matching the `types_tests.rs` convention. All 18 inline `panics at
todo!()` claims converted to past tense.

### P16-04 (MEDIUM) — L3/L6 — Fixed

Five false `require_git=true` claims corrected, including the false
COVERAGE claim that a companion test "exercis[es] the `require_git=true`
path" (unreachable through `build_walk`, since `scanner.rs` sets
`require_git(false)`), replaced with the test's real justification.

The correctly-phrased F-B2 defect-history references were deliberately
left untouched.

### P18-05 (MEDIUM) — L3 — Fixed

AC-001's claim of a duplicate-yield detector was structurally impossible
because `collect_md_files` runs `files.sort(); files.dedup();` before
returning; comment and assertion message rewritten to state what IS
verified and to point at C-B1 / P10-01 / BI-068 for genuine
path-aliasing.

## Non-Vacuity Proofs (orchestrator-executed per L-81)

The adversary agent type has Read/Grep/Glob only and cannot run commands;
all empirical confirmation is orchestrator work per D-193/L-81. These
proofs are independent of the agents' own reports.

### `filter_entry` lock (P17-01)

With the entire `builder.filter_entry(...)` statement deleted from
`scanner.rs`, the suite reports **44 tests run: 43 passed, 1 failed** and
the sole failure is
`test_BC_2_01_004_inv1_build_walk_filter_entry_guard_is_active`, whose
failure message prints the actually-leaked path
`.github/PULL_REQUEST_TEMPLATE.md`.

Baseline before the fix: deleting the same statement left all 42 tests
green. `scanner.rs` restored; tree clean.

### `parents` lock (D-259 lock)

With `.parents(true)` changed to `.parents(false)`, the suite reports
**44 tests run: 43 passed, 1 failed** and the sole failure is
`test_BC_2_01_003_post1_ancestor_gitignore_honoured_parents_true`.
`scanner.rs` restored and re-verified as `.parents(true)`; tree clean.

Both mutants killed exactly one test each with no collateral failures.

### Methodology note (L-84)

The orchestrator's first attempt at the `parents` mutation used `sed -i
''`, which silently failed to apply; the run returned a clean 44/44 that
would have been misread as the lock being vacuous. It was caught only
because the orchestrator grepped to confirm the mutation had actually
landed before trusting the result. **Always assert the mutant applied
before interpreting a mutation-test outcome.**

## Intermittent `(1 leaky)` Annotation

An intermittent nextest `(1 leaky)` annotation appears on some runs. The
orchestrator ran the suite 3× at the post-fix HEAD and 2× at pre-fix
`f24ad3e`; it did NOT reproduce in any of those five runs, but later
appeared during a mutant run.

Characterization: nondeterministic, NOT a memory leak (nextest "leaky"
means a spawned child outlived the test), plausibly an unreaped `git`
subprocess from the four tests that require `git` on PATH (register entry
C-C3). One fix agent asserted it was "pre-existing … not a regression"
without having measured it; the measurement above supersedes that
characterization. Not escalated; recorded.

## `cargo fuzz run --locked` Note

`cargo fuzz run` does NOT accept `--locked` — probing it yields `error:
unexpected argument '--locked' found`. The absence of `--locked` on the
fuzz recipes is correct and deliberate, which is why the `f24ad3e`
`--locked` sweep covered `deny`, `mutants`, and `kani` but not `fuzz`.

The locally installed `cargo-fuzz` is 0.13.1 — the version the frozen
spec mandates — while CI pins 0.13.2, a live instance of the D-260
divergence.

## In-Flight Fix Group (CI/build configuration, D-261 scope)

The following findings remain unaddressed pending the third fix group:

| Finding | Subject |
|---------|---------|
| P18-01 | POL-11 harness-count assertion absent at all three nextest sites. Note: the spec's literal `grep -c '^tests::'` matches 0 lines because nextest's real format is `crate::binary test_name`; the fix implements the spec's INTENT and discloses the corpus defect. |
| P16-05 / P17-04 | Purity detector blind to grouped and fully-qualified `std::fs` forms while printing an absolute PASS claim; `file_count` never asserted non-zero. |
| P16-06 / P17-05 | `purity` unreachable under `just ci` because the red-by-design advisory `spec-lint` is wired as a blocking prerequisite. |
| P17-02 | `just hardening` false `kani` EXECUTED via `pipefail` + `\|\| echo "0"` double-output. |
| P16-07 | `cargo-fuzz --version` pin missing from `install-tools`; `kani-verifier` absent; false "All Cargo tools installed." claim. |
| P18-04 | `lefthook.yml` "mirror the CI jobs exactly" covering 3 of 9 jobs. |
| BI-070 | `just spec-lint` / `just ci` unrunnable from a story worktree. |

This record will be updated when the third fix group is committed.
