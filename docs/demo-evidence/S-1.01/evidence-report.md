# Demo Evidence Report — S-1.01: Workspace Scaffold, Shared Types, and Default-CWD File Discovery

**Branch:** `feature/S-1.01-workspace-scaffold-and-core-discovery`
**Worktree:** `.worktrees/S-1.01/`
**Commit:** `98a4f15`
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
| AC-006 | BC-2.01.003 inv 2 | `test_BC_2_01_003_gitignored_file_anchor_table_built_as_target` | `AC-006-…txt` | PASS |
| AC-007 | BC-2.01.004 post 1 | `test_BC_2_01_004_dot_directories_unconditionally_skipped` | `AC-007-…txt` | PASS |
| AC-008 | BC-2.01.004 inv 1 | `test_BC_2_01_004_no_override_flag_for_dot_dir_skip` | `AC-008-…txt` | PASS |
| AC-009 | BC-2.01.004 post 2 | `test_BC_2_01_004_directory_symlinks_not_followed` | `AC-009-…txt` | PASS |
| AC-010 | BC-2.01.004 inv 3 | `test_BC_2_01_004_dot_dir_md_file_anchor_table_built_as_target` | `AC-010-…txt` | PASS |
| AC-011 | BC-2.01.005 post 1 | `test_BC_2_01_005_exact_md_extension_included` | `AC-011-…txt` | PASS |
| AC-012 | BC-2.01.005 post 2 | `test_BC_2_01_005_non_md_extensions_excluded` | `AC-012-…txt` | PASS |
| AC-013 | BC-2.01.005 inv 1 | `test_BC_2_01_005_case_sensitive_byte_match` | `AC-013-…txt` | PASS |

Every one of the 13 tests named in the story spec exists verbatim and passes when
run individually via `-E 'test(=<name>)'`. Full suite at this commit:
**44 tests run: 44 passed, 0 skipped**, plus `POL-11 PASS: 44 tests across 6 binaries`.

---

## Discrimination evidence — the tests fail when the behaviour breaks

A green test suite is not evidence that the tests *discriminate*. Six targeted
mutations were applied to `scanner.rs` in a hermetic out-of-tree copy, each with
an assert-mutant-landed check (a `cmp` against the pristine file) so that a
no-op edit could not be mistaken for a kill. Full transcript in
`discrimination-matrix.txt`.

| Mutation | Tests killed |
|----------|--------------|
| Extension match made case-**in**sensitive | 6 |
| Dot-directory `filter_entry` guard removed | 2 |
| `.gitignore` honouring disabled | 10 |
| Directory symlinks followed (`follow_links(true)`) | 2 |
| `files.sort()` + `files.dedup()` removed | **0** |
| `collect_md_files` post-filter backstop removed | **0** |

### The two survivors are disclosed, not hidden

- **`files.sort()` / `files.dedup()` removal survives.** Already registered as
  F-B1 / F-B3 / C-B1 and deferred to S-1.02: duplicate yields cannot be
  provoked against genuine path aliasing without CLI path arguments, which
  BC-2.01.007 / BC-2.01.008 anchor to S-1.02. AC-002's assertion is a real
  distinct-count check, but nothing in S-1.01 can make the walker yield a
  duplicate, so the dedup call is defensive and currently unobservable.

- **Post-filter backstop removal survives — newly recorded (BI-095).** The
  `filter_entry` guard and the `collect_md_files` post-filter are **mutually
  masking**: removing either one alone leaves all 44 tests green. `filter_entry`
  covers dot-**directories** for every `collect_md_files` consumer, so the
  backstop's unique contribution is dot-**files**. The existing
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
- All four branch-protection-required CI checks are **green** at `98a4f15`.
- The story is **NOT CONVERGED**. Three confirming rounds have run (adversary
  passes 16–18, 19–21, 22–24) and every one returned `MATERIAL_FINDINGS`;
  `passes_clean` is **0 of 3** required under BC-5.39.001. A fourth confirming
  round is required. This evidence package does not assert convergence.
- L1–L5 (spec-compliance, code-correctness, test-integrity, hostile-filesystem,
  public-API) have been independently reported clean by six consecutive passes.
  Every round-2 and round-3 material finding was L6 gate-configuration or
  documentation class, and every material one was a residual of the immediately
  preceding fix wave rather than a defect in this story's source or tests.
