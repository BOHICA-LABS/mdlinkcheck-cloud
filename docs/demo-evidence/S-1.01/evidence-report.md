# Demo Evidence Report — S-1.01: Workspace Scaffold, Shared Types, and Default-CWD File Discovery

**Branch:** `feature/S-1.01-workspace-scaffold-and-core-discovery`
**Worktree:** `.worktrees/S-1.01/`
**Commit:** `9a9b46c`
**Recorded:** 2026-08-11
**Toolchain:** rustc 1.97.0 · cargo-nextest 0.9.129 (CI pins nextest 0.9.98; suite verified green under both)

---

## Why this evidence is test-execution based, not a CLI or terminal recording

S-1.01 delivers a **library only**. `crates/mdlinkcheck/src/main.rs` is a documented
`todo!()` stub — the binary compiles but panics if executed, and there is no CLI
surface until S-1.02. A VHS terminal recording or a `--help` transcript would
therefore either fail or be staged, and a staged recording would be a fabricated
artifact. Per-AC evidence is captured by executing each acceptance criterion's
named test in isolation and recording the real output, which is the honest
available form at this story. POLICY 10 story-scoped output is satisfied: all
files live under `docs/demo-evidence/S-1.01/`.

Each per-AC file contains the exact command, the toolchain versions, the commit
SHA, the verbatim execution transcript with exit code, an inventory of every
assertion the test makes, and the test's full source — so a reader can judge
*what was verified*, not merely that something went green.

---

## Coverage Summary — 13 of 13 acceptance criteria

| AC | Traces to | Test | Evidence file | Result |
|----|-----------|------|---------------|--------|
| AC-001 | BC-2.01.001 post 1 | `test_BC_2_01_001_default_cwd_scan_includes_all_md_files` | `AC-001-…txt` | PASS |
| AC-002 | BC-2.01.001 post 2 | `test_BC_2_01_001_no_duplicate_in_scan_set` | `AC-002-…txt` | PASS |
| AC-003 | BC-2.01.001 post 3 | `test_BC_2_01_001_scan_terminates_for_finite_tree` | `AC-003-…txt` | PASS |
| AC-004 | BC-2.01.003 post 1 | `test_BC_2_01_003_gitignore_excludes_from_scan_set` | `AC-004-…txt` | PASS |
| AC-005 | BC-2.01.003 inv 1 | `test_BC_2_01_003_gitignored_file_not_scanned_as_source` | `AC-005-…txt` | PASS |
| AC-006 | BC-2.01.003 inv 2 | `test_BC_2_01_003_gitignored_file_anchor_table_built_as_target` | `AC-006-…txt` | PASS (clause i only — see note) |
| AC-007 | BC-2.01.004 post 1 | `test_BC_2_01_004_dot_directories_unconditionally_skipped` | `AC-007-…txt` | PASS |
| AC-008 | BC-2.01.004 inv 1 | `test_BC_2_01_004_no_override_flag_for_dot_dir_skip` | `AC-008-…txt` | PASS |
| AC-009 | BC-2.01.004 post 2 | `test_BC_2_01_004_directory_symlinks_not_followed` | `AC-009-…txt` | PASS |
| AC-010 | BC-2.01.004 inv 3 | `test_BC_2_01_004_dot_dir_md_file_anchor_table_built_as_target` | `AC-010-…txt` | PASS (clause i only — see note) |
| AC-011 | BC-2.01.005 post 1 | `test_BC_2_01_005_exact_md_extension_included` | `AC-011-…txt` | PASS |
| AC-012 | BC-2.01.005 post 2 | `test_BC_2_01_005_non_md_extensions_excluded` | `AC-012-…txt` | PASS |
| AC-013 | BC-2.01.005 inv 1 | `test_BC_2_01_005_case_sensitive_byte_match` | `AC-013-…txt` | PASS |

Every one of the 13 tests named in the story spec exists verbatim and passes when
run individually via `-E 'test(=<name>)'`. Full suite at this commit:
**44 tests run: 44 passed, 0 skipped**, plus `POL-11 PASS: 44 tests across 6 binaries`.

**Partial-coverage disclosure — AC-006 and AC-010 (BI-106)**

AC-006 (`test_BC_2_01_003_gitignored_file_anchor_table_built_as_target`) and
AC-010 (`test_BC_2_01_004_dot_dir_md_file_anchor_table_built_as_target`) each
have two clauses. The table above shows PASS for both, but the coverage is
partial:

- **Clause (i) — excluded file must NOT appear in scan set**: asserted and
  discharged. Both tests contain a `!result.contains(...)` negative assertion
  plus a `result.contains(...)` vacuous-pass guard. The tests' own in-source
  comments confirm this scope: "clause (i) of BC-2.01.003 invariant 2" and
  "clause (i) of BC-2.01.004 invariant 3".

- **Clause (ii) — anchor table built as target**: **untested and deferred**.
  The anchor-table infrastructure (`build_anchor_table` / link-resolution) does
  not exist in S-1.01 and will not exist until S-1.02 or later. There is no
  assertion in either test that verifies a gitignored or dot-directory file
  appears in an anchor table. The test names reference this intent in their
  names, but the implementations are clause-(i)-only stubs scoped to what the
  scanner currently provides.

Deferral target: S-1.02 (anchor-table stories). These ACs will require
additional test logic once the anchor-table infrastructure exists.

---

## Discrimination evidence — the tests fail when the behaviour breaks

A green test suite is not evidence that the tests *discriminate*. Six targeted
mutations were applied to `scanner.rs` in a hermetic out-of-tree copy, each with
an assert-mutant-landed check (a `cmp` against the pristine file) so that a
no-op edit could not be mistaken for a kill. Every run used `--no-fail-fast` so
that all 44 tests ran to completion regardless of earlier failures — a
`N/M tests run` summary with N < M means cancellation and any count taken from it
is a floor, not a measurement. Full corrected transcript in
`discrimination-matrix.txt`. The previously published counts (6/2/10/2) were
wrong: the original runs used fail-fast (stopping at the first failure) and
counted FAIL lines rather than distinct test names (each test appeared twice —
once streamed, once in the end-of-run recap). See BI-103 for the root-cause
record.

| Mutation | Tests killed | Killing tests |
|----------|:------------:|---------------|
| Extension match made case-**in**sensitive | **3** | `test_BC_2_01_005_case_sensitive_byte_match`, `test_BC_2_01_005_ec005_ec006a_ec006b_traversal_excludes_non_md_extensions`, `test_BC_2_01_005_non_md_extensions_excluded` |
| Dot-directory `filter_entry` guard removed | **1** | `test_BC_2_01_004_inv1_build_walk_filter_entry_guard_is_active` |
| `.gitignore` honouring disabled | **7** | `test_BC_2_01_003_post3_global_gitignore_respected_when_available`, `test_BC_2_01_003_gitignore_excludes_from_scan_set`, `test_BC_2_01_003_inv1_gitignored_source_not_scanned_real_gitignore`, `test_BC_2_01_003_post1_ancestor_gitignore_honoured_parents_true`, `test_BC_2_01_003_post1_gitignore_honored_outside_git_repo`, `test_build_walk_filter_entry_replaceable_but_collect_md_files_backstop_holds`, `test_vp016_gitignored_files_never_in_scan_set` |
| Directory symlinks followed (`follow_links(true)`) | **2** | `test_BC_2_01_004_ec009_directory_symlink_to_outside_not_followed`, `test_vp017_scan_terminates_arbitrary_tree` |
| `files.sort()` + `files.dedup()` removed | **0** | — survivor |
| `collect_md_files` post-filter backstop removed | **0** | — survivor |

### The two survivors are disclosed, not hidden

- **`files.sort()` / `files.dedup()` removal survives.** Already registered as
  F-B1 / F-B3 / C-B1 and deferred to S-1.02: duplicate yields cannot be
  provoked against genuine path aliasing without CLI path arguments, which
  BC-2.01.007 / BC-2.01.008 anchor to S-1.02. AC-002's assertion is a real
  distinct-count check, but nothing in S-1.01 can make the walker yield a
  duplicate, so the dedup call is defensive and currently unobservable.

- **Post-filter backstop removal survives — newly recorded (BI-095).** The
  masking is **one-directional, not mutual** (BI-105): removing the `filter_entry`
  guard alone kills `test_BC_2_01_004_inv1_build_walk_filter_entry_guard_is_active`
  (M2, 1 kill) — that test declares itself in its own assertion message "the sole
  regression lock for the builder-level guard". So `filter_entry` is **independently
  locked**. Only the post-filter backstop is the unlocked half: removing it alone
  leaves all 44 tests green (M6, 0 kills). The `filter_entry` guard covers
  dot-**directories** for every `collect_md_files` consumer; the backstop's unique
  contribution — the reason it survives deletion undetected — is dot-**files**. The
  existing
  `test_build_walk_filter_entry_replaceable_but_collect_md_files_backstop_holds`
  does not lock the backstop — it asserts a property `filter_entry` alone
  satisfies.

  The backstop *is* discriminable, via a dot-file that an ignore negation
  re-enables (verified by execution — with `.gitignore` containing `.*` and
  `!.template.md`):

  | Build | `collect_md_files` result |
  |-------|---------------------------|
  | backstop present | `["visible.md"]` |
  | backstop removed | `[".template.md", "visible.md"]` |

  A regression lock is **deliberately not added**, because dot-file exclusion is
  unadjudicated under **D-252a** — a test would pin behaviour the operator has
  not yet ruled on. Routed to operator adjudication alongside D-252a.

---

## Honest status of this story at this commit

- All 13 ACs have passing, individually-executed, assertion-bearing evidence.
  AC-006 and AC-010 are clause-(i)-only: clause (ii) is deferred to S-1.02
  because the anchor-table infrastructure does not yet exist (see partial-coverage
  disclosure above, BI-106).
- All four branch-protection-required CI checks are **green** at `b538112`:
  `Format check`, `Clippy (deny warnings)`, `Test (macos-latest)`,
  `Build release (macos-latest)`, all `conclusion: success`. The workflow-level run
  conclusion is `failure` because `Spec lint` is advisory-red by design (D-246).
  The 13 AC transcripts and mutation matrix were executed at `9a9b46c`; they carry
  to `b538112` because `crates/` is byte-unchanged between the two SHAs (verified:
  `git diff --name-only 9a9b46c b538112 -- crates/` returns zero paths). The one
  non-docs commit between `9a9b46c` and `b538112` altered only echo and comment
  lines in `scripts/purity-check.sh`; LINE_RE, STMT_RE, PLANTS, and CLEAN are
  byte-identical — detection behaviour is unchanged. To confirm the attestations
  still hold for the commit you are reading: run
  `git diff --name-only b538112 HEAD -- crates/ scripts/`; if it returns any
  paths, re-verify CI and the transcripts before relying on them.
- The story is **NOT CONVERGED**. Four confirming rounds have run (adversary
  passes 16–18, 19–21, 22–24, 25–27) and every one returned `MATERIAL_FINDINGS`;
  `passes_clean` is **0 of 3** required under BC-5.39.001. Round 4 (passes 25–27)
  audited HEAD `b42285a` and found a leading-`::`-plus-rename escape from the
  ADR-001 purity gate (BI-096), subsequently fixed at `9a9b46c` and confirmed
  closed for all five forbidden ADR-001 categories. Under operator ruling D-263,
  what remains is ONE confirming review scoped to the changed surface; once that
  passes, convergence may be recorded as ACHIEVED-WITH-DISCLOSED-RESIDUALS. This
  evidence package does not assert convergence.
- L1–L5 (spec-compliance, code-correctness, test-integrity, hostile-filesystem,
  public-API) in the production Rust code were independently reported clean by
  **nine consecutive passes (19–27)**, round 4 included; `crates/` is
  byte-unchanged across round 4. Every round-2 and round-3 material finding was
  L6 gate-configuration or documentation class. Round 4's findings were also all
  on the L6/gate/evidence surface, but one of them (BI-096) was **functional
  rather than documentation-class** — a leading-`::`-plus-rename escape from the
  ADR-001 purity gate, undisclosed and exploitable past every required gate
  (`cargo fmt`, `cargo clippy`, 44/44 tests, and the purity gate itself all passed
  with real `std::fs` I/O planted inside the pure core). Rounds 2 and 3 produced
  only documentation-accuracy residuals; round 4 did not. BI-096 is fixed and
  confirmed closed at `b538112`.
