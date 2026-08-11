<!-- PR-PACKAGE.md — S-1.01 -->
<!-- Written by pr-manager. Read-only package — no commands in this file execute anything. -->
<!-- The operator executes all mutating commands manually. -->

---

# PRE-EXECUTION BLOCKER

**This package is NOT cleared for execution.**

Adversarial convergence for S-1.01 requires **3 clean consecutive confirming passes** under
BC-5.39.001. Four confirming rounds have run (passes 16–18, 19–21, 22–24, 25–27) and every
one returned `MATERIAL_FINDINGS`. `passes_clean` = **0 of 3** required. Round 4 (passes 25–27)
found a leading-`::`-plus-rename escape from the ADR-001 purity gate (BI-096), fixed at
`9a9b46c` and confirmed closed. A **scoped confirming review of the changed surface** is still
required before this package is conventionally cleared.

**The operator may nonetheless choose to open the PR now** — with the non-convergence
disclosure intact and visible in the body — before convergence completes. That decision
belongs to the operator, not to this package. This package does not recommend it, nor does
it oppose it. If the operator opens the PR early, the body below accurately reflects the
current state and makes no false convergence claim.

The command sequence is in ready-to-execute form. Every mutating command is marked
**HUMAN-EXECUTED ONLY** and must not be run by an automated agent.

---

# PR Title

```
feat(S-1.01): workspace scaffold, shared types, and default-CWD file discovery
```

---

# PR Body

> **OPERATOR INSTRUCTION:** Extract the content between the `=== BEGIN PR BODY ===` and
> `=== END PR BODY ===` markers below (exclusive of the markers themselves) and save it to a
> local file — e.g., `~/pr-body-s1.01.md`. Pass that path via `--body-file` in the create
> command. Do not retype the body; paste artifacts from manual re-typing are the most common
> source of disclosure omissions.

=== BEGIN PR BODY ===

## Story

**S-1.01 — Workspace scaffold, shared types, and default-CWD file discovery**

**Branch:** `feature/S-1.01-workspace-scaffold-and-core-discovery`
**Evidence execution SHA:** `9a9b46c` (all 13 AC transcripts and mutation matrix executed here;
all four branch-protection CI checks green, orchestrator-verified via `gh api`)
**Base:** `develop`
**Merge-base equals `origin/develop` HEAD (`f81f412`):** the branch is fully current;
`git merge-tree` reports zero conflict markers.
**Carry-forward attestation:** `git diff --name-only 9a9b46c HEAD -- ':(exclude)docs'`
returns nothing — the delta from the evidence SHA to the current branch HEAD is
documentation-only. Verify this yourself before creating the PR; if it ever returns
non-empty output, the CI and test attestations must be re-verified.

---

## What Was Built

This PR delivers the foundational Rust workspace for mdlinkcheck-cloud:

- **`crates/mdlinkcheck-core`** — shared types and domain primitives (`version = "0.1.0"`,
  `rust-version = "1.88"`, edition 2021). Provides exactly nine public types in
  `src/types.rs`: `Verdict`, `FailureReason`, `Finding`, `LinkKind`, `ExtractedLink`,
  `AnchorTable`, `DirIndex` (a `pub type` alias), `DirEntryInfo`, and `EntryKind` (BI-104).
  Note: `crates/mdlinkcheck/src/lib.rs` currently exports only `pub mod scanner;` and
  imports zero symbols from `mdlinkcheck_core` — the declared dependency is currently unused.
- **`crates/mdlinkcheck`** — binary crate housing `scanner.rs` (the default-CWD file
  discovery engine) and a `main.rs` stub (`todo!()` — the CLI surface ships in S-1.02).
- Workspace-level configuration: toolchain pin `1.97.0`, `justfile`, `lefthook.yml`,
  `deny.toml`, CI workflow (`.github/workflows/ci.yml`), purity detection script.

The scanner implements gitignore-aware, dot-directory-exclusive, symlink-safe,
case-sensitive-extension `.md` file discovery governed by four behavioral contracts:
BC-2.01.001, BC-2.01.003, BC-2.01.004, BC-2.01.005.

---

## Behavioral Contract Traceability

| BC | Postcondition / Invariant | AC | Named test | Result |
|----|---------------------------|----|------------|--------|
| BC-2.01.001 | post 1 — all `.md` files included | AC-001 | `test_BC_2_01_001_default_cwd_scan_includes_all_md_files` | PASS |
| BC-2.01.001 | post 2 — no duplicates | AC-002 | `test_BC_2_01_001_no_duplicate_in_scan_set` | PASS |
| BC-2.01.001 | post 3 — terminates for finite tree | AC-003 | `test_BC_2_01_001_scan_terminates_for_finite_tree` | PASS |
| BC-2.01.003 | post 1 — gitignored file excluded from scan set | AC-004 | `test_BC_2_01_003_gitignore_excludes_from_scan_set` | PASS |
| BC-2.01.003 | inv 1 — gitignored file not scanned as source | AC-005 | `test_BC_2_01_003_gitignored_file_not_scanned_as_source` | PASS |
| BC-2.01.003 | inv 2 — gitignored file anchor table built as target | AC-006 | `test_BC_2_01_003_gitignored_file_anchor_table_built_as_target` | PASS † |
| BC-2.01.004 | post 1 — dot directories unconditionally skipped | AC-007 | `test_BC_2_01_004_dot_directories_unconditionally_skipped` | PASS |
| BC-2.01.004 | inv 1 — no override flag for dot-dir skip | AC-008 | `test_BC_2_01_004_no_override_flag_for_dot_dir_skip` | PASS |
| BC-2.01.004 | post 2 — directory symlinks not followed | AC-009 | `test_BC_2_01_004_directory_symlinks_not_followed` | PASS |
| BC-2.01.004 | inv 3 — dot-dir `.md` file anchor table built as target | AC-010 | `test_BC_2_01_004_dot_dir_md_file_anchor_table_built_as_target` | PASS † |
| BC-2.01.005 | post 1 — exact `.md` extension included | AC-011 | `test_BC_2_01_005_exact_md_extension_included` | PASS |
| BC-2.01.005 | post 2 — non-`.md` extensions excluded | AC-012 | `test_BC_2_01_005_non_md_extensions_excluded` | PASS |
| BC-2.01.005 | inv 1 — case-sensitive byte match | AC-013 | `test_BC_2_01_005_case_sensitive_byte_match` | PASS |

**† AC-006 and AC-010 — honest disclosure (BI-106):** Both ACs state that a gitignored or
dot-dir file "has its anchor table built as a target." The anchor-table build infrastructure
does not exist in S-1.01. Each test has exactly two assertions: a negative
`!result.contains(...)` and a positive vacuity gate. These assert **clause (i)** only —
that the excluded file does NOT appear in the scan set. **Clause (ii)** — that the anchor
table is built as a target — is **untested and deferred**: the `build_anchor_table` /
link-resolution infrastructure does not exist in S-1.01 and will not exist until S-1.02
or later. There is no assertion in either test that verifies a gitignored or dot-directory
file appears in an anchor table. Deferral target: S-1.02 (anchor-table stories). This is
scoped correctly to S-1.01 — it is a disclosure, not a defect claim.

---

## Test Evidence

All runs at evidence execution SHA `9a9b46c`. All four branch-protection-required CI checks
are green at `9a9b46c`. `git diff --name-only 9a9b46c HEAD -- ':(exclude)docs'` returns
nothing — the delta to the current branch HEAD is documentation-only and the attestation
carries.

**Full suite:** 44 tests run: **44 passed, 0 skipped**
`POL-11 PASS: 44 tests across 6 binaries`

| Gate | Command | Exit code |
|------|---------|-----------|
| Format | `cargo fmt --all --check` | 0 |
| Lint | `cargo clippy --locked --all-targets --all-features -- -D warnings` | 0 |
| Purity | `just purity` | 0 |
| Full CI (local) | `just ci` | 0 |

---

## Demo Evidence

Demo evidence for this story is located at `docs/demo-evidence/S-1.01/` and is
**test-execution based, not a CLI or terminal recording.**

This is not an evasion. `crates/mdlinkcheck/src/main.rs` is a documented `todo!()` stub.
The binary compiles but panics on invocation. There is no CLI surface until S-1.02. A VHS
terminal recording or `--help` transcript would either crash or be staged. A staged
recording is a fabricated artifact. The honest available form at this story is per-AC
test-execution evidence.

Each per-AC file records: the exact command, toolchain versions, commit SHA, verbatim
execution transcript, exit code, assertion inventory, and the test's full source — so a
reader can judge what was verified, not merely that something went green.

Evidence inventory (POLICY 10 story-scoped, all files under `docs/demo-evidence/S-1.01/`):

| File | Content |
|------|---------|
| `AC-001-test_BC_2_01_001_default_cwd_scan_includes_all_md_files.txt` | Per-AC transcript |
| `AC-002-test_BC_2_01_001_no_duplicate_in_scan_set.txt` | Per-AC transcript |
| `AC-003-test_BC_2_01_001_scan_terminates_for_finite_tree.txt` | Per-AC transcript |
| `AC-004-test_BC_2_01_003_gitignore_excludes_from_scan_set.txt` | Per-AC transcript |
| `AC-005-test_BC_2_01_003_gitignored_file_not_scanned_as_source.txt` | Per-AC transcript |
| `AC-006-test_BC_2_01_003_gitignored_file_anchor_table_built_as_target.txt` | Per-AC transcript |
| `AC-007-test_BC_2_01_004_dot_directories_unconditionally_skipped.txt` | Per-AC transcript |
| `AC-008-test_BC_2_01_004_no_override_flag_for_dot_dir_skip.txt` | Per-AC transcript |
| `AC-009-test_BC_2_01_004_directory_symlinks_not_followed.txt` | Per-AC transcript |
| `AC-010-test_BC_2_01_004_dot_dir_md_file_anchor_table_built_as_target.txt` | Per-AC transcript |
| `AC-011-test_BC_2_01_005_exact_md_extension_included.txt` | Per-AC transcript |
| `AC-012-test_BC_2_01_005_non_md_extensions_excluded.txt` | Per-AC transcript |
| `AC-013-test_BC_2_01_005_case_sensitive_byte_match.txt` | Per-AC transcript |
| `discrimination-matrix.txt` | Mutation trial transcripts (6 mutations, hermetic out-of-tree) |
| `evidence-report.md` | Full evidence summary |

---

## Discrimination Evidence

Six mutations applied to `scanner.rs` in a hermetic out-of-tree copy; each mutation was
verified as landed before running the suite (assert-mutant-landed check via `cmp`). All
runs used `--no-fail-fast` so that all 44 tests ran to completion regardless of earlier
failures (BI-103). The previously published counts (6/2/10/2) were incorrect: the original
runs used fail-fast (stopping at the first failure, yielding partial counts: `25/44`,
`25/44`, `21/44`, `18/44`) and counted FAIL lines rather than distinct test names (nextest
prints each failure twice — once streamed, once in the end-of-run recap). Re-run to
completion by both the orchestrator and demo-recorder independently, with matching results:

| Mutation | Tests killed | Killing tests |
|----------|:------------:|---------------|
| Extension match made case-**in**sensitive | **3** | `test_BC_2_01_005_case_sensitive_byte_match`, `test_BC_2_01_005_ec005_ec006a_ec006b_traversal_excludes_non_md_extensions`, `test_BC_2_01_005_non_md_extensions_excluded` |
| Dot-directory `filter_entry` guard removed | **1** | `test_BC_2_01_004_inv1_build_walk_filter_entry_guard_is_active` |
| `.gitignore` honouring disabled | **7** | `test_BC_2_01_003_post3_global_gitignore_respected_when_available`, `test_BC_2_01_003_gitignore_excludes_from_scan_set`, `test_BC_2_01_003_inv1_gitignored_source_not_scanned_real_gitignore`, `test_BC_2_01_003_post1_ancestor_gitignore_honoured_parents_true`, `test_BC_2_01_003_post1_gitignore_honored_outside_git_repo`, `test_build_walk_filter_entry_replaceable_but_collect_md_files_backstop_holds`, `test_vp016_gitignored_files_never_in_scan_set` |
| Directory symlinks followed (`follow_links(true)`) | **2** | `test_BC_2_01_004_ec009_directory_symlink_to_outside_not_followed`, `test_vp017_scan_terminates_arbitrary_tree` |
| `files.sort()` + `files.dedup()` removed | **0** | — survivor |
| `collect_md_files` post-filter backstop removed | **0** | — survivor |

**Two survivors — disclosed and registered:**

**Survivor 1: `files.sort()` / `files.dedup()` removal** (F-B1/F-B3/C-B1, deferred to
S-1.02). Duplicate yields cannot be provoked against genuine path aliasing without CLI path
arguments; that capability anchors to BC-2.01.007/BC-2.01.008, which are S-1.02 scope.
AC-002's distinct-count assertion is real, but nothing in S-1.01 can produce a duplicate
from the walker alone, so the `dedup` call is defensive and currently unobservable.

**Survivor 2: `collect_md_files` post-filter backstop removal** (BI-095, newly recorded;
BI-105). The masking is **one-directional, not mutual**: removing the `filter_entry` guard
alone kills `test_BC_2_01_004_inv1_build_walk_filter_entry_guard_is_active` (1 kill) — that
test declares itself the sole regression lock for the builder-level guard, so `filter_entry`
is **independently locked**. Removing the backstop alone leaves all 44 tests green (0 kills).
The backstop's unique contribution is dot-file
exclusion (not dot-directory, which `filter_entry` already covers). The backstop is
discriminable only via a dot-file that an ignore negation re-enables (verified by
execution: with `.gitignore` containing `.*` and `!.template.md`, the backstop present
→ `["visible.md"]`; backstop removed → `[".template.md", "visible.md"]`). A regression
lock is deliberately not added: dot-file exclusion is unadjudicated under **D-252a** —
adding a lock would pin behaviour the operator has not yet ruled on. Routed for adjudication
alongside D-252a.

---

## CI Status

All four branch-protection-required CI checks are green at evidence SHA `9a9b46c`
(orchestrator-verified via `gh api`). `git diff --name-only 9a9b46c HEAD -- ':(exclude)docs'`
returns nothing — all commits since `9a9b46c` are documentation-only, so the CI attestation
carries to the current branch HEAD.

### Four required branch-protection checks — all SUCCESS

| Check | Status |
|-------|--------|
| `Format check` | success |
| `Clippy (deny warnings)` | success |
| `Test (macos-latest)` | success |
| `Build release (macos-latest)` | success |

Branch protection on `develop`: `strict: true`; required contexts exactly the four above;
`required_approving_review_count: 0`; `enforce_admins: false`.

### Expected non-blocking red: `Spec lint`

Operator ruling **D-246**: advisory, NOT a required check.

The sole failing checker is `check-ec-injectivity` with **39 SCENARIO-MISMATCH** findings
spread across BC-2.05…BC-2.14. **Zero** are in `BC-2.01.*`. This failure is entirely
outside S-1.01's contract scope and does not reflect on the correctness of this story.

### Expected non-blocking red: `Verify evidence figures (advisory)`

**This check will be red on the PR and cannot be truthfully cleared (BI-069, accepted per
D-227 log-as-signal precedent).**

Material facts:
- The job triggers on `pull_request` events only (`github.event_name == 'pull_request'`).
  It has never run on this branch during its push-event CI runs.
- It has no `continue-on-error` at the job or step level, by deliberate L-66 design.
- On a `pull_request` event, exit codes 2 (REFUSED), 3, 4, and 5 all propagate as
  `exit 1`, making the check red regardless of the advisory intent.
- Its `REQUIRED_CHECKS` set is spec-lint-delivery-shaped (`check1-selftest-count`,
  `check2-adr-figures`, `check4-ei-figures`, `check3-ledger-triple`, `check8-live-pr-body`,
  …). A Rust story PR structurally cannot register comparisons for spec-lint delivery
  figures that belong to a different artifact class.
- This check is **NOT** a required branch-protection check. It does not block merge.

**DO NOT satisfy this check by fabricating spec-lint figures.** That action is the BI-063
false-claim class and constitutes a fabricated artifact regardless of review outcome. The
correct response to this check being red is to note D-227 and proceed.

### Additional non-required checks (SUCCESS at `9a9b46c`)

`MSRV check (1.88)` — success
`Purity check (ADR-001)` — success
`VEF selftest suite` — success

### Purity Gate (ADR-001): Boundary History and Known Residual Gaps

**A1 closure history (BI-096):** During round 4 (passes 25–27), the adversary found that
`use ::std::fs as f;` followed by `f::metadata()` performed real filesystem I/O inside the
pure core while passing **every** gate: `cargo fmt --all --check` (exit 0), `cargo clippy
-D warnings` (exit 0), all 44/44 tests, and the purity gate itself — whose own SCOPE output
affirmatively claimed that shape was covered. This was an undisclosed, exploitable escape from
the ADR-001 boundary — not a documentation finding. Fixed at `9a9b46c` and confirmed closed
for all five forbidden ADR-001 categories (`fs`, `net`, `rand`, `stdout`, `Instant`). The
ADR-001 boundary was unenforced for this shape from the story's inception until `9a9b46c`.

**Known residual gaps (declared NOT-COVERED by the gate itself — deliberate design decisions,
not permissions granted by ADR-001):** `Path::exists()`, `Path::is_dir()`, `Path::is_file()`
are not detected — the names would collide with plausible future `EntryKind::is_dir` /
`AnchorTable::exists` domain methods. `Path::metadata(&p)` UFCS form is not detected.
Aliased RNG call sites, RNG crates beyond the five named, and macro-generated I/O are not
detected. `io::stdin`, `io::stderr`, `std::process`, `std::env`, and `SystemTime::now` are
not detected. Every limit is a limit of the CHECK, not a permission granted by ADR-001.
Extending coverage is an operator decision at the wave-1 gate.

---

## Convergence Status — NOT CONVERGED

**This PR does not claim convergence and must not be treated as converged.**

Four confirming adversarial rounds have run:
- Passes 16–18: MATERIAL_FINDINGS
- Passes 19–21: MATERIAL_FINDINGS
- Passes 22–24: MATERIAL_FINDINGS
- Passes 25–27: MATERIAL_FINDINGS

`passes_clean` = **0 of 3** required under BC-5.39.001. Round 4 (passes 25–27) found a
leading-`::`-plus-rename escape from the ADR-001 purity gate (BI-096), fixed at `9a9b46c`
and confirmed closed. A **scoped confirming review of the changed surface** is still required
before the story is conventionally certified.

**Balanced disclosure:** The story is functionally green and has been extensively reviewed.

- **L1–L5** (spec-compliance, code-correctness, test-integrity, hostile-filesystem,
  public-API): independently reported **clean by nine consecutive passes (19–27)**; round 4
  included — `crates/` is byte-unchanged across round 4
- Every round-2 and round-3 material finding was **L6 class** (gate-configuration or
  documentation); round 4's only non-documentation finding (BI-096) is fixed and confirmed
  closed at `9a9b46c`
- Every material finding in rounds 2 and 3 was a residual of the immediately preceding
  fix wave — not a defect in the story's source code or tests
- Five production defects were found and fixed during the story's lifetime

The branch is disclosed, not hidden. This PR body carries the non-convergence disclosure
intact. Whether to open the PR before the scoped confirming review completes is the
operator's decision.

---

## Sequencing Deviation — Disclosed

The per-story-delivery workflow requires Step 4.5 (adversarial convergence) to complete
**before** Step 5 (demo recording). Step 5 demo evidence was produced at operator direction
while adversarial convergence was still open. This deviation is recorded without editorial.

---

## Accepted and Ruled Items

| Item | Ruling | Disposition |
|------|--------|-------------|
| `parents(true)` kept with `$HOME/.gitignore` ancestor-ignore residual risk | D-259/F-A3 | KEEP as-is |
| `proptest` locked at 1.11.0 (Cargo.toml requests `^1.6`) | D-257 | ACCEPTED |
| `Link` corpus contradiction | D-258 | Not S-1.01 work; deferred |
| Tool-pin deviations + four absent spec-named config files | D-260 | ACCEPTED (CI-verified pins override spec values) |
| LOW/NITPICK deferral scoping | D-261 | ACCEPTED |
| MSRV 1.88 divergence (toolchain pins 1.97.0, CI pins 1.88) | D-253 | ACCEPTED |
| Dot-FILE exclusion unadjudicated (D-252a) | D-252a | Pending operator adjudication; BI-095 backstop survivor routed here |
| CI tests on `macos-latest` only (no Linux or Windows runner) | D-043 | ACCEPTED |
| Frozen-perimeter convergence definition | D-254 | ACCEPTED |
| Holdout coverage vacuously satisfied | — | Disclosed; not classified as a failure |
| AC-006/AC-010 anchor-table claims without S-1.01 anchor infrastructure | — | Disclosed above in traceability table (BI-106) |

---

## C-Class Accepted Residuals (operator ruling D-263)

The following C-class findings are accepted as disclosed-documentation residuals under the
standing residual-risk posture (D-263). No fix is required before merge; each is disclosed
for reviewer awareness:

| Item | Finding | Status |
|------|---------|--------|
| BI-107 | `ci.yml:226` and `justfile:317` cite MSRV deviation to D-205; the authorising ruling is D-253 (which this PR body cites correctly) | ACCEPTED — no code impact |
| BI-108 | `ci.yml:461` claims spec-lint has "three known advisory failures"; there is exactly one (`check-ec-injectivity`) | ACCEPTED |
| BI-109 | `justfile:5` "With no remote…" is false and self-contradicted six lines later | ACCEPTED |
| BI-099 | Purity gate Phase-A line numbers index the comment-stripped stream; reported locations are offset by up to 117 lines in `types.rs` while the header claims precision | ACCEPTED |
| BI-100 | The `io::stdout` arm's rationale comment in the purity gate is false on two counts | ACCEPTED |
| BI-101 | A `.rs` filename containing a newline is a genuine fail-open in the purity gate | ACCEPTED |
| BI-102 | Nonexistent source directory exits 1 with no diagnostic | ACCEPTED |

---

## Carried-Forward LOW/NITPICK Register (Unfixed, Deferred per D-261)

BI-084, BI-085, BI-086, BI-087, BI-088, BI-089

All six are in the unfixed LOW/NITPICK register. None affects correctness of the scanner
or the acceptance criteria. All deferred per D-261 deferral scoping ruling.

---

## Pre-Merge Checklist

- [x] Branch is current with `develop` (merge-base = `origin/develop` HEAD, zero conflicts)
- [x] 44/44 tests passing, 0 skipped
- [x] `cargo fmt --all --check` exit 0
- [x] `cargo clippy --locked --all-targets --all-features -- -D warnings` exit 0
- [x] `just purity` exit 0
- [x] `just ci` exit 0
- [x] Four required CI checks green at `9a9b46c` (orchestrator-verified via `gh api`; attestation carries to HEAD — delta is documentation-only)
- [x] Demo evidence: 13 per-AC transcripts + discrimination matrix + evidence report
- [x] All CI check expectations honestly documented (including expected reds)
- [x] Non-convergence disclosed; `passes_clean` = 0/3
- [x] Sequencing deviation disclosed
- [x] Two mutation survivors registered and routed
- [ ] Scoped confirming review (BI-096 purity gate fix, `9a9b46c`) — **OUTSTANDING**; required for conventional certification under BC-5.39.001

=== END PR BODY ===

---

# Command Sequence

**Legend:**
- `[READ-ONLY]` — safe to run at any time; gathers facts only
- `[MUTATING — HUMAN-EXECUTED ONLY]` — modifies remote state; must not be run by an automated agent

Run all commands from within the repository root at
`/Users/jmagady/Dev/mdlinkcheck-cloud` (or any worktree within it; `gh` resolves the
repo from the git remote automatically).

---

## Step 1: Verify branch is current with develop and conflict-free

**[READ-ONLY]**

```sh
# Confirm the branch HEAD and that the working tree is clean
git -C /Users/jmagady/Dev/mdlinkcheck-cloud/.worktrees/S-1.01 log --oneline -1
```

Expected result: one line. The SHA shown is the current branch HEAD — note it for your
records. Do not compare it against any hardcoded value; the HEAD advances as this package
file is updated.

```sh
# Confirm the branch is ahead of develop, 0 behind
git -C /Users/jmagady/Dev/mdlinkcheck-cloud/.worktrees/S-1.01 \
  log --oneline origin/develop..HEAD | wc -l
```

Expected result: a positive integer. Verify it is non-zero (branch has commits ahead of
develop). Do not compare against a hardcoded count; the count increases as this package
file is updated.

```sh
# Confirm the evidence SHA is an ancestor of the current HEAD
git -C /Users/jmagady/Dev/mdlinkcheck-cloud/.worktrees/S-1.01 \
  merge-base --is-ancestor 9a9b46c HEAD \
  && echo "9a9b46c is an ancestor — attestation carries" \
  || echo "UNEXPECTED: evidence SHA is not an ancestor of HEAD"
```

Expected result: `9a9b46c is an ancestor — attestation carries`

```sh
# Confirm the delta from the evidence SHA to HEAD is documentation-only
git -C /Users/jmagady/Dev/mdlinkcheck-cloud/.worktrees/S-1.01 \
  diff --name-only 9a9b46c HEAD -- ':(exclude)docs'
```

Expected result: empty output (zero lines). If any lines appear, the CI and test
attestations do not carry to the current HEAD and must be re-verified before creating
the PR.

```sh
# Confirm no conflict markers between branch and develop
git -C /Users/jmagady/Dev/mdlinkcheck-cloud/.worktrees/S-1.01 \
  merge-tree HEAD origin/develop HEAD | grep -c "<<<<<<" || true
```

Expected result: `0` (zero conflict markers)

---

## Step 2: Check for an existing open PR on this branch

**[READ-ONLY]**

```sh
gh pr list \
  --repo BOHICA-LABS/mdlinkcheck-cloud \
  --head feature/S-1.01-workspace-scaffold-and-core-discovery \
  --state open
```

Expected result: no rows (the PR does not yet exist). If a PR is listed, the create
command in Step 4 should not be run again — update the existing PR body instead.

---

## Step 3: Confirm CI status on the last completed run

**[READ-ONLY]**

```sh
# List recent CI runs on the feature branch
gh run list \
  --repo BOHICA-LABS/mdlinkcheck-cloud \
  --branch feature/S-1.01-workspace-scaffold-and-core-discovery \
  --limit 5
```

Expected result: run `31482829662` near the top with status `completed`. Rows for commits
after `9a9b46c` may show as `skipped` (documentation-only commits do not trigger CI).

```sh
# View the four required checks specifically on run 31482829662
gh run view 31482829662 \
  --repo BOHICA-LABS/mdlinkcheck-cloud \
  --json jobs \
  --jq '.jobs[] | select(.name | test("Format check|Clippy|Test \\(macos|Build release")) | {name, conclusion}'
```

Expected result: four objects, each `"conclusion": "success"`.

---

## Step 4: Confirm branch protection on develop

**[READ-ONLY]**

```sh
gh api \
  repos/BOHICA-LABS/mdlinkcheck-cloud/branches/develop/protection \
  --jq '{
    strict: .required_status_checks.strict,
    contexts: .required_status_checks.contexts,
    required_approving_review_count: .required_pull_request_reviews.required_approving_review_count,
    enforce_admins: .enforce_admins.enabled
  }'
```

Expected result:
```json
{
  "strict": true,
  "contexts": ["Format check", "Clippy (deny warnings)", "Test (macos-latest)", "Build release (macos-latest)"],
  "required_approving_review_count": 0,
  "enforce_admins": false
}
```

---

## Step 5: Save the PR body to a local file

**[MUTATING — HUMAN-EXECUTED ONLY]**

Extract the content between `=== BEGIN PR BODY ===` and `=== END PR BODY ===` in this
file (exclusive of the markers) and save it to a local path you control. Example:

```sh
# One way: use sed to extract the body section from this package file
sed -n '/^=== BEGIN PR BODY ===/,/^=== END PR BODY ===/{ /^=== BEGIN PR BODY ===/d; /^=== END PR BODY ===/d; p }' \
  /Users/jmagady/Dev/mdlinkcheck-cloud/.worktrees/S-1.01/docs/demo-evidence/S-1.01/PR-PACKAGE.md \
  > ~/pr-body-s1.01.md

# Verify the file is non-empty and ends with the checklist
wc -l ~/pr-body-s1.01.md
tail -5 ~/pr-body-s1.01.md
```

Expected result: the file ends with the pre-merge checklist lines. At least 150 lines.

---

## Step 6: Create the PR

**[MUTATING — HUMAN-EXECUTED ONLY]** (D-120 / BI-062 — PR creation is human-executed;
automated agents are prohibited from executing this step)

```sh
gh pr create \
  --repo BOHICA-LABS/mdlinkcheck-cloud \
  --title "feat(S-1.01): workspace scaffold, shared types, and default-CWD file discovery" \
  --body-file ~/pr-body-s1.01.md \
  --base develop \
  --head feature/S-1.01-workspace-scaffold-and-core-discovery
```

Expected result: a URL of the form `https://github.com/BOHICA-LABS/mdlinkcheck-cloud/pull/<N>`.
Note the PR number — it is referenced in all subsequent commands as `<PR_NUMBER>`.

---

## Step 7: Poll CI checks on the newly created PR

**[READ-ONLY]** (run after the PR is created and CI has had time to start)

```sh
# Poll all check runs on the PR
gh pr checks <PR_NUMBER> \
  --repo BOHICA-LABS/mdlinkcheck-cloud
```

Expected result when ready:
- `Format check` — pass
- `Clippy (deny warnings)` — pass
- `Test (macos-latest)` — pass
- `Build release (macos-latest)` — pass
- `Spec lint` — **fail** (expected; operator ruling D-246; advisory; not a required check)
- `Verify evidence figures (advisory)` — **fail** (expected; BI-069/D-227; not a required check)
- `MSRV check (1.88)` — pass
- `Purity check (ADR-001)` — pass
- `VEF selftest suite` — pass

If any of the four **required** checks fail, do not proceed to Step 8 — investigate
the failure before taking any further action.

---

## Step 8: Read the four required contexts individually

**[READ-ONLY]** (confirms the required contexts are specifically green, not just "some checks pass")

```sh
# Check the status of each required context individually
gh pr checks <PR_NUMBER> \
  --repo BOHICA-LABS/mdlinkcheck-cloud \
  --json name,state \
  --jq '.[] | select(.name | test("Format check|Clippy \\(deny warnings\\)|Test \\(macos-latest\\)|Build release \\(macos-latest\\)"))'
```

Expected result: four objects with `"state": "SUCCESS"` (or `"PASS"` depending on API
version). Zero of the four may show `"FAILURE"` or `"PENDING"` at merge time.

---

## Step 9: Post a human verdict as a PR comment (NOT `gh pr review`)

**[MUTATING — HUMAN-EXECUTED ONLY]**

`gh pr review` is structurally impossible in this environment (BI-039/D-021/D-105). Any
verdict must be posted as a `gh pr comment`. Posting verdicts is human-executed (D-120/BI-062).
Example:

```sh
gh pr comment <PR_NUMBER> \
  --repo BOHICA-LABS/mdlinkcheck-cloud \
  --body "Operator verdict: [APPROVE / REQUEST_CHANGES / NOTE] <rationale here>. Convergence status: passes_clean=0/3 (BC-5.39.001). Fourth round outstanding."
```

Expected result: the comment appears on the PR. No `gh pr review` call is needed or valid.

---

## Step 10: Merge (after all gates pass)

**[MUTATING — HUMAN-EXECUTED ONLY]** (D-120 / BI-062 — merge is human-executed;
automated agents are prohibited from executing this step)

Do not execute until:
1. Scoped confirming review of the ADR-001 purity gate changes (BI-096, fixed at `9a9b46c`)
   has returned a clean pass, OR the operator has explicitly overridden the convergence gate
   with a documented ruling
2. All four required CI checks are green on the PR
3. Any upstream dependency PRs are merged (check `develop` for story dependency ordering)

```sh
# Merge via squash onto develop (non-release branch)
gh pr merge <PR_NUMBER> \
  --repo BOHICA-LABS/mdlinkcheck-cloud \
  --squash \
  --delete-branch
```

Expected result: `Merged pull request #<N>` and the branch `feature/S-1.01-workspace-scaffold-and-core-discovery` is deleted from origin.

**Note:** The `plugins/vsdd-factory/bin/enforce-merge-strategy.sh` wrapper applies on
automated pipelines but this package is operator-executed. If the project uses the
enforce-merge-strategy.sh wrapper in its workflow, substitute:
`plugins/vsdd-factory/bin/enforce-merge-strategy.sh <PR_NUMBER> --squash --delete-branch`

---

# Summary of Disclosures

This package contains the following explicit disclosures. A reviewer confirming the PR
body should verify all are present in the submitted body:

1. NOT CONVERGED — passes_clean 0/3; four rounds returned MATERIAL_FINDINGS; scoped confirming review of BI-096 fix outstanding
2. L1–L5 clean for nine consecutive passes (19–27); all material findings were L6 class; round 4's BI-096 finding is fixed and confirmed closed
3. `Spec lint` expected red — D-246 advisory ruling; 39 SCENARIO-MISMATCH in BC-2.05–2.14; zero in BC-2.01.*
4. `Verify evidence figures` expected red — BI-069/D-227; pull_request-only job; not a required check; must not be satisfied by fabricating spec-lint figures (BI-063)
5. Demo evidence is test-execution based — `main.rs` is a `todo!()` stub; no CLI until S-1.02
6. Two mutation survivors: `sort`/`dedup` (F-B1/F-B3/C-B1, deferred to S-1.02) and post-filter backstop (BI-095/BI-105, one-directional masking, routed to D-252a adjudication)
7. Sequencing deviation: Step 5 demo recording performed while Step 4.5 convergence was open
8. AC-006/AC-010: clause (i) only — clause (ii) anchor-table coverage deferred to S-1.02 (BI-106)
9. Carried-forward LOW/NITPICK register: BI-084 through BI-089 (deferred per D-261)
10. Accepted/ruled items: D-259/F-A3, D-257, D-258, D-260, D-261, D-253, D-252a, D-043, D-254
11. ADR-001 purity gate: A1 escape (BI-096) found in round 4, fixed at `9a9b46c`, confirmed closed; known residual gaps documented in "Purity Gate" section above
12. C-class accepted residuals: BI-107, BI-108, BI-109, BI-099, BI-100, BI-101, BI-102 (D-263, accepted as disclosed)
13. PR creation, verdict posts, and merge are human-executed (D-120/BI-062)

13 named disclosures. 10 named commands in the sequence (Steps 1–10 with sub-commands).
