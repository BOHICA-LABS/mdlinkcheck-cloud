# Red Gate Log — S-1.01

| Field | Value |
|-------|-------|
| Story | S-1.01 |
| Cycle | v1.0.0-greenfield |
| Wave | 1 |
| Log created | 2026-08-10 |

---

## Step 1 — Stub Commit

**Agent:** stub-architect
**Branch:** `feature/S-1.01-workspace-scaffold-and-core-discovery`
**Commit:** `ba83b1b`

stub-architect created the 9-file workspace scaffold on the story branch. The
orchestrator independently verified `cargo check --workspace --all-targets`
GREEN: 0 errors, 6 warnings (all from `todo!()` unreachable/unused stubs —
expected for Red Gate discipline, not blocking).

All three `scanner.rs` functions have `todo!()` bodies:
- `build_walk`
- `collect_md_files`
- `is_md_extension`

Red Gate precondition satisfied: stubs compile but all tests that exercise
these functions will fail (or will fail once written).

---

## Step 2 — Failing Tests / Red Gate

**Agent:** test-writer
**Branch:** `feature/S-1.01-workspace-scaffold-and-core-discovery`
**Test commit:** `d7aa245`
**Stub commit:** `ba83b1b`
**Verified by:** orchestrator (direct `cargo test` execution, D-193/L-81)

### Gate Metrics

| Field | Value |
|-------|-------|
| Blocking gate | BC-8.29.001 |
| Red ratio | 1.0 |
| Red tests | 15 |
| Total new tests | 31 |
| Exempt tests | 16 |
| Green-by-design count | 16 |
| Wiring-exempt count | 0 |
| Full exception path | false |
| Threshold | 0.5 |
| Integer form check | 15 × 2 = 30 ≥ (31 − 16) = 15 → TRUE |
| TDD mode | strict |
| **Verdict** | **PASS** |

### Red Tests (15)

All 15 fail with `panicked at crates/mdlinkcheck/src/scanner.rs: not yet
implemented` — specifically the `todo!()` bodies of `collect_md_files`
(line 54) and `is_md_extension` (line 72). Zero failures from compile
errors, missing fixtures, or `assert!(false)`.

The 15 RED tests are:
- **AC-001 through AC-013** (13 named acceptance-criterion tests)
- `test_vp016_gitignored_files_never_in_scan_set`
- `test_vp017_scan_terminates_arbitrary_tree`

### Exempt Tests (16)

All 16 tests in `crates/mdlinkcheck-core/tests/types_tests.rs` passed
(16 passed / 0 failed). Classified GREEN-BY-DESIGN per BC-5.38.002: they
exercise only type declarations — `EntryKind` variants, `DirEntryInfo`
construction, `DirIndex` insert/lookup, `AnchorTable` construction/dedup,
`Verdict::Clean` — and were verified by grep to reference NO
`todo!()`-bodied function (`scanner`, `collect_md_files`, `build_walk`,
`is_md_extension` all absent from that file). They cannot be made red
without making the stub non-compilable. WIRING-EXEMPT count: 0.

### Deviations and Disclosures

These are disclosed, not hidden. They carry into the PR body and the
wave-1 gate package.

**1. Undeclared file created: `crates/mdlinkcheck/src/lib.rs`**
11 lines, `pub mod scanner;`. NOT in the story's File Structure
Requirements table. Required because `scanner` was a private module of a
BINARY crate and integration tests in `tests/` cannot reach binary-crate
internals. Fix is the conventional Rust library-crate pattern; `main()`
body remains `todo!()`. Same file-lifecycle class as Blocker 2 — flagged
for the file-lifecycle checker obligation already RECORDED (not actioned)
under S-7.02.

**2. Declared-create file was pre-existing: `rust-toolchain.toml`**
Listed `create` in the story table but already existed at the worktree
root pinning 1.97.0. It was NOT overwritten or modified.

**3. AC-006 and AC-010 are HALF-SCOPED in this story.**
Clause (i) "excluded file is not in the scan set" IS asserted. Clause (ii)
"its anchor table is still built as a link target" (DI-006 cases 2 and 3,
Pass 1.5 / AnchorIndex) does NOT exist in S-1.01 — no `anchor_table`
module, no `AnchorIndex`, no Pass 1.5 in this story's file list. Clause
(ii) is DEFERRED to E-2 link-extraction/anchor-table stories and is marked
with `// DEFERRED:` comments in both test bodies. Orchestrator ruling; the
story's own AC text already scopes the scan-set half here.

**4. AC-008 is an API-surface negative assertion, not a CLI test.**
No clap arg parsing exists in S-1.01 (that is S-1.02), so the test
asserts the discovery API exposes no parameter/knob enabling dot-directory
traversal, rather than testing a fabricated `--hidden` flag surface.

**5. `Finding` and `ExtractedLink` are UNCONSTRUCTIBLE as of this story.**
Their payload enums `FailureReason` and `LinkKind` were added as EMPTY
enums (beyond the 7 types the story names) purely to make `types.rs`
compile, since `api-surface.md` line 121-123 defines `Finding` with both
`verdict: Verdict` and `reason: FailureReason`. Variants belong to later
stories. Construction tests for these two types are therefore deferred; no
AC among AC-001..013 requires them.

**6. `Link` type discrepancy (register entry).**
`module-decomposition.md` names a bare `Link` type for the `types` module;
`api-surface.md` — the authoritative signature source — defines no such
type. It was deliberately NOT invented and is absent from `types.rs`.
Unresolved artifact disagreement; recorded, not actioned (closed-world
D-244).

**7. `main()` body is `todo!()`, so the binary panics if run.**
Demo evidence for S-1.01 therefore cannot be CLI-invocation based; it must
be library/test-execution based. Flagged for the Step 5 demo-recorder
dispatch.

---

## Step 4 — Implementation and Post-Implementation Hardening

**Branch:** `feature/S-1.01-workspace-scaffold-and-core-discovery`
**Final HEAD:** `f773598` (PUSHED to origin)
**Test count at step close:** 40 tests pass, 0 fail
**Clippy:** `cargo clippy --all-targets --all-features -- -D warnings` exits 0
**Format:** `cargo fmt --check` clean
**Working tree:** CLEAN

### 12-Commit Ledger (stub → green → hardened)

| # | SHA | Description |
|---|-----|-------------|
| 1 | `ba83b1b` | feat(S-1.01): add module stubs (9 files, cargo check green) |
| 2 | `d7aa245` | test(S-1.01): write failing test suite — Red Gate step 2 |
| 3 | `cf3418c` | feat(S-1.01): implement build_walk, collect_md_files, is_md_extension |
| 4 | `4fb5049` | fix(test/S-1.01): repair AC-008 dot-dir skip test against relative components |
| 5 | `c7384ed` | test(S-1.01): close follow_links mutation gap with EC-009 fixture |
| 6 | `dbd1404` | fix(S-1.01): resolve five adversarial-review findings F-04 F-05 F-06 F-09 F-10 |
| 7 | `54b210b` | test(S-1.01): close two mutation-coverage gaps in scanner_discovery_tests |
| 8 | `6379384` | test(S-1.01): remove process-env mutation; gate AC-009 on unix |
| 9 | `affaaf1` | test(S-1.01): add 4 tests — EC-001, EC-004, AC-005 companion, F-B2 red |
| 10 | `91b57c4` | fix(S-1.01): require_git(false) so .gitignore is honoured outside git repos (F-B2) |
| 11 | `2f3ce12` | test(S-1.01): add F-A1 red test + hygiene fixes F-C1/F-C2/F-C3/F-C5 |
| 12 | `f773598` | fix(S-1.01): F-A1 dot-dir guard + B-03 doc fix + clippy clean |

### Two Real Production Defects Found and Fixed

**F-B2 (commit 10 — `91b57c4`):** `build_walk` lacked `require_git(false)`, so
`.gitignore` was honored ONLY inside a git repository. Probe against `ignore`
0.4.33: a non-git directory with `.gitignore` containing `node_modules/` returned
`["node_modules/foo.md","README.md"]`. Violated BC-2.01.003 postcondition 1. Fixed
TDD red-first.

**F-A1 HIGH (commit 12 — `f773598`):** dot-directory skip was NOT unconditional.
`hidden(true)` is subordinate to ignore-rule matches in `ignore` 0.4.33, so a
whitelist negation pattern (`.gitignore`: `.*` + `!.github`) re-enabled traversal of
`.github/`. Probe returned `[".github/PULL_REQUEST_TEMPLATE.md","README.md"]`.
Violated BC-2.01.004 postcondition 1 and invariant 1 (D-011), BC-2.01.001 invariant
1. Fixed with a `WalkBuilder::filter_entry` dot-dir guard that exempts depth 0
(critical: `TempDir` roots are `.tmp`-prefixed, so a naive predicate would reject
the scan root and empty every scan set).

### Final Mutation Sweep — 12 Mutants

| Mutant | Result | Notes |
|--------|--------|-------|
| `filter_entry` disabled | KILLED | F-A1 fix tested directly |
| `require_git(true)` | KILLED | F-B2 fix tested directly |
| `follow_links(true)` | KILLED | EC-009 fixture |
| case-insensitive `.md` | KILLED | F-04 |
| `git_ignore(false)` | KILLED | F-05 |
| `ignore(false)` | KILLED | F-06 |
| `git_global(false)` | KILLED | F-09 |
| `is_file()` neutered | KILLED | 54b210b |
| `hidden(false)` (early) | KILLED | Superseded — see below |
| `git_exclude(false)` | SURVIVED | Accepted: no BC mandates `.git/info/exclude` |
| `files.dedup()` removal | SURVIVED | Deferred to S-1.02 / reporter |
| `files.sort()` removal | SURVIVED | Deferred to S-1.02 / reporter (byte-order vs NFC per DI-001) |

**`hidden(false)` reclassification:** This mutant NOW SURVIVES because
`filter_entry` handles dot-DIRECTORIES independently of the `hidden` flag.
`hidden(true)`'s only remaining unique effect is dot-FILE exclusion. This
is a coherent consequence of the F-A1 fix, not a regression — and is
exactly the escalated open question (dot-FILE exclusion needs an operator
ruling). Summary: 9 killed / 3 survived (accepted or deferred) / 1
reclassified.

### Step 4.5 — Adversarial Convergence Status

**NOT CONVERGED. `passes_clean = 0` of 3 required (BC-5.39.001).**

Six passes run (1 general + 2 lens + 3 convergence attempts); every pass
returned MATERIAL_FINDINGS. All findings are fixed, adjudicated-deferred
to S-1.02, or escalated to operator. Per-pass disposition detail:
`.factory/cycles/v1.0.0-greenfield/S-1.01/adversary-convergence-state.json`.

**Step 5 (demo evidence) and Step 6 (PR) have NOT begun.** Step 4.5 must
reach 3 consecutive NITPICK_ONLY or CLEAN passes before proceeding.
