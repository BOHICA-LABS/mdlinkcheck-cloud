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
