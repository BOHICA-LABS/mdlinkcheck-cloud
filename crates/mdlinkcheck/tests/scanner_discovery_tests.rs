//! Integration tests for the scanner discovery pipeline.
//!
//! Covers AC-001..AC-013 from story S-1.01, tracing to behavioral contracts:
//!   BC-2.01.001 — Recursive .md Discovery with Default Scan Root
//!   BC-2.01.003 — .gitignore and .ignore Exclusion During Traversal
//!   BC-2.01.004 — Dot-Directory Skip (Unconditional) and Dir-Symlink Non-Following
//!   BC-2.01.005 — Extension Matching — .md Only, Case-Sensitive
//!
//! Verification properties:
//!   VP-016 — gitignored files never appear in the scan set (integration test)
//!   VP-017 — scan terminates for arbitrary directory trees including symlink cycles (proptest)
//!
//! This is the GREEN acceptance corpus for AC-001..AC-013 (story S-1.01) plus VP-016
//! and VP-017. All 44 tests must pass. At Red Gate (commit ba83b1b), every call to
//! `collect_md_files` and `is_md_extension` panicked at `todo!()` inside the scanner
//! function bodies — that phase is complete.
//!
//! Gitignore fixture forms (Scope Ruling 4 — both forms covered):
//!   AC-004 / VP-016 Form A : git repo + `.gitignore` (git init NOT required for
//!                            .gitignore to work — `build_walk` calls `require_git(false)`
//!                            which honours .gitignore unconditionally; git init is used
//!                            for belt-and-suspenders assurance and Scope Ruling 4 semantics)
//!   AC-005 / AC-006 / VP-016 Form B : plain (non-git) dir + `.ignore`
//!                            (`.ignore` is honoured unconditionally by WalkBuilder
//!                            regardless of `require_git`)
//!
//! Process-environment policy: NO test in this file mutates the process
//! environment.  The `git init` subprocess is kept hermetic through per-command
//! env on the `Command` object — that is safe because it is not process-env
//! mutation.  For `collect_md_files` (which runs in-process),
//! fixture file names AND fixture directory names use a distinctive `mdlc_fixture_`
//! prefix so that no plausible host-global gitignore pattern can accidentally exclude
//! them.  Count assertions are whole-set `result.len()` checks; hermeticity is
//! maintained through the `mdlc_fixture_` prefix on both files and directories.
//! Purely negative or structural assertions use `contains`/`!contains` style.  The one test that genuinely needs
//! a controlled global gitignore (`test_BC_2_01_003_post3_global_gitignore_respected_when_available`)
//! lives in its own integration-test file (`global_gitignore_test.rs`) which
//! compiles to a separate binary with no concurrent libtest threads.

#![allow(non_snake_case)]

use std::collections::HashSet;
use std::fs;
use std::path::{Path, PathBuf};

use tempfile::TempDir;

use mdlinkcheck::scanner;

// ─── Test fixture helpers ─────────────────────────────────────────────────────

/// Create a file (and all parent dirs) at `root/rel`, writing placeholder content.
fn create_file(root: &Path, rel: &str) {
    let full = root.join(rel);
    if let Some(parent) = full.parent() {
        fs::create_dir_all(parent)
            .unwrap_or_else(|e| panic!("create_dir_all for '{}': {}", rel, e));
    }
    fs::write(&full, "# Placeholder\n").unwrap_or_else(|e| panic!("write '{}': {}", rel, e));
}

/// Run `git init -q` in `dir` with hermetic git configuration.
///
/// `hermetic_config` is the path to a gitconfig file that lives inside
/// the fixture's `TempDir`.  Passing it as per-command env (`GIT_CONFIG_GLOBAL`,
/// `GIT_CONFIG_NOSYSTEM=1`) via `Command::env` ensures the `git init` subprocess
/// is not influenced by the developer's real global gitignore or git configuration.
///
/// This function only affects the child subprocess environment — it performs
/// no process-env mutation on the current process.
///
/// **`git init` is NOT required for `.gitignore` to work with our scanner.**
/// `build_walk` calls `require_git(false)`, which causes the `ignore` crate to
/// honour `.gitignore` files in ALL directories regardless of whether a real git
/// repository is present (`ignore-0.4.33/src/dir.rs:560`:
/// `let any_git = !require_git || ...`).  Tests that call `git_init` do so for
/// belt-and-suspenders assurance or to align with Scope Ruling 4 fixture semantics.
fn git_init(dir: &Path, hermetic_config: &Path) {
    let status = std::process::Command::new("git")
        .args(["-C", dir.to_str().expect("UTF-8 path"), "init", "-q"])
        .env("GIT_CONFIG_NOSYSTEM", "1")
        .env("GIT_CONFIG_GLOBAL", hermetic_config)
        .status()
        .expect("`git` must be available on PATH for gitignore fixture tests");
    assert!(status.success(), "git init failed in {:?}", dir);
}

// ─── AC-001 (traces to BC-2.01.001 postcondition 1) ──────────────────────────
// Fixture form: plain tempdir — no gitignore exclusion, tests pure recursive
// discovery of all .md files.

#[test]
fn test_BC_2_01_001_default_cwd_scan_includes_all_md_files() {
    let dir = TempDir::new().expect("tempdir");
    let root = dir.path();

    create_file(root, "mdlc_fixture_README.md");
    create_file(root, "mdlc_fixture_docs/mdlc_fixture_guide.md");
    create_file(
        root,
        "mdlc_fixture_docs/mdlc_fixture_api/mdlc_fixture_reference.md",
    );
    create_file(root, "not_a_md.txt");
    create_file(root, "image.png");

    // ── Red Gate history (commit ba83b1b): collect_md_files panicked at todo!(). ──────
    let result = scanner::collect_md_files(root);

    // Exact-count assertion: assert the returned Vec has exactly 3 paths.
    // NOTE: this assertion CANNOT detect duplicate yields from the walker.
    // `collect_md_files` calls `files.sort(); files.dedup()` before returning,
    // so `result.len()` can never exceed 3 as a consequence of a duplicate yield.
    // The "exactly once" property for BC-2.01.001 postconditions 1 and 2 is
    // enforced structurally by `collect_md_files`'s internal dedup — genuine
    // path-aliasing verification (e.g. hardlinks) requires explicit path arguments
    // and is deferred (C-B1, anchored to S-1.02); hardlink aliasing intent is
    // unadjudicated (P10-01/BI-068). The subsequent `result_set.len() == 3`
    // assertion covers the same "exactly 3 distinct .md files" constraint.
    assert_eq!(
        result.len(),
        3,
        "scan set must contain exactly 3 distinct .md paths (BC-2.01.001 \
         postconditions 1 and 2); NOTE: duplicate-yield detection is not possible \
         at this level because collect_md_files deduplicates internally before \
         returning — path-aliasing verification (C-B1) is deferred to S-1.02"
    );

    // After implementation: every .md file under root must appear in the result.
    let result_set: HashSet<PathBuf> = result.into_iter().collect();
    assert!(
        result_set.contains(&root.join("mdlc_fixture_README.md")),
        "mdlc_fixture_README.md must be in the scan set"
    );
    assert!(
        result_set.contains(&root.join("mdlc_fixture_docs/mdlc_fixture_guide.md")),
        "mdlc_fixture_docs/mdlc_fixture_guide.md must be in the scan set"
    );
    assert!(
        result_set
            .contains(&root.join("mdlc_fixture_docs/mdlc_fixture_api/mdlc_fixture_reference.md")),
        "mdlc_fixture_docs/mdlc_fixture_api/mdlc_fixture_reference.md must be in the scan set"
    );
    assert_eq!(
        result_set.len(),
        3,
        "only .md files must appear; .txt/.png must be excluded"
    );
}

// ─── AC-002 (traces to BC-2.01.001 postcondition 2) ──────────────────────────
// Fixture form: plain tempdir.

#[test]
fn test_BC_2_01_001_no_duplicate_in_scan_set() {
    let dir = TempDir::new().expect("tempdir");
    let root = dir.path();

    create_file(root, "mdlc_fixture_a.md");
    create_file(root, "mdlc_fixture_sub/mdlc_fixture_b.md");
    create_file(
        root,
        "mdlc_fixture_sub/mdlc_fixture_nested/mdlc_fixture_c.md",
    );

    // ── Red Gate history (commit ba83b1b): this call panicked at todo!(). ────────────
    let result = scanner::collect_md_files(root);

    let unique: HashSet<PathBuf> = result.iter().cloned().collect();
    assert_eq!(
        result.len(),
        unique.len(),
        "scan set must not contain duplicate paths (BC-2.01.001 postcondition 2)"
    );
    // Positive gate: all three fixture files must be present (F-04 vacuous-pass
    // prevention — an empty Vec passes the dedup assertion above vacuously).
    assert!(
        unique.contains(&root.join("mdlc_fixture_a.md")),
        "mdlc_fixture_a.md must appear in the scan set"
    );
    assert!(
        unique.contains(&root.join("mdlc_fixture_sub/mdlc_fixture_b.md")),
        "mdlc_fixture_sub/mdlc_fixture_b.md must appear in the scan set"
    );
    assert!(
        unique.contains(&root.join("mdlc_fixture_sub/mdlc_fixture_nested/mdlc_fixture_c.md")),
        "mdlc_fixture_sub/mdlc_fixture_nested/mdlc_fixture_c.md must appear in the scan set"
    );
}

// ─── AC-003 (traces to BC-2.01.001 postcondition 3) ──────────────────────────
// Fixture form: plain tempdir with finite depth.
// After implementation: the call must return within bounded time for any finite tree.
//
// TERMINATION DISCLOSURE: this test contains no timeout assertion or elapsed-time
// check.  Non-termination (an infinite loop) would manifest as the test hanging
// until the CI job's timeout fires and kills the process — it would NOT produce an
// assertion failure.  The valuable assertions here are the identity gates below
// (each expected path must be present) plus the exact Vec count (all three files,
// no extras).  The WalkBuilder's follow_links(false) prevents infinite recursion
// on symlink cycles; for finite trees without cycles, termination is guaranteed
// by the finite depth of the filesystem tree itself.

#[test]
fn test_BC_2_01_001_scan_terminates_for_finite_tree() {
    let dir = TempDir::new().expect("tempdir");
    let root = dir.path();

    create_file(root, "mdlc_fixture_a.md");
    create_file(root, "mdlc_fixture_b/mdlc_fixture_c.md");
    create_file(root, "mdlc_fixture_b/mdlc_fixture_d/mdlc_fixture_e.md");

    // ── Red Gate history (commit ba83b1b): this call panicked at todo!(). ────────────
    // This call must return without looping (BC-2.01.001 postcondition 3).
    let result = scanner::collect_md_files(root);

    // Identity assertions prevent three unrelated paths from satisfying len==3
    // (F-P3-04 identity gate — AC-003).
    assert!(
        result.contains(&root.join("mdlc_fixture_a.md")),
        "mdlc_fixture_a.md must be in the scan set (AC-003 identity gate)"
    );
    assert!(
        result.contains(&root.join("mdlc_fixture_b/mdlc_fixture_c.md")),
        "mdlc_fixture_b/mdlc_fixture_c.md must be in the scan set (AC-003 identity gate)"
    );
    assert!(
        result.contains(&root.join("mdlc_fixture_b/mdlc_fixture_d/mdlc_fixture_e.md")),
        "mdlc_fixture_b/mdlc_fixture_d/mdlc_fixture_e.md must be in the scan set (AC-003 identity gate)"
    );
    assert_eq!(result.len(), 3, "all three .md files must be discovered");
}

// ─── AC-004 (traces to BC-2.01.003 postcondition 1) ──────────────────────────
// Fixture form: GIT REPO + `.gitignore`
// (git init for Scope Ruling 4 belt-and-suspenders; require_git(false) in
// build_walk honours .gitignore even without a git repo — git init is NOT
// required for .gitignore to work; see git_init doc comment)
//
// Process-environment policy: no process-env mutation in this test.
// The `git init` subprocess is hermetic via per-command env on `Command`
// (see `git_init`).  `collect_md_files` runs with the host's process env;
// fixture file names use the `mdlc_fixture_` prefix so no plausible host-global
// gitignore pattern can accidentally exclude them.  No exact-count assertion is
// made because an unrelated ambient gitignore exclusion could add or remove
// other files without invalidating the BC-2.01.003 postcondition.

#[test]
fn test_BC_2_01_003_gitignore_excludes_from_scan_set() {
    let dir = TempDir::new().expect("tempdir");
    let root = dir.path();

    // Hermetic config for the git subprocess only (per-command env — not process-env
    // mutation).  The ignore crate running in collect_md_files uses the host env.
    let hermetic_cfg = root.join(".hermetic_gitconfig");
    fs::write(&hermetic_cfg, "").expect("write hermetic gitconfig");

    git_init(root, &hermetic_cfg); // Scope Ruling 4 belt-and-suspenders; require_git(false) in
                                   // build_walk honours .gitignore outside git repos — git init
                                   // is NOT required for .gitignore to work (see git_init doc)
    fs::write(root.join(".gitignore"), "node_modules/\n").expect("write .gitignore");
    create_file(root, "node_modules/mdlc_fixture_foo.md"); // must be excluded
    create_file(root, "mdlc_fixture_README.md"); // must be included

    // ── Red Gate history (commit ba83b1b): this call panicked at todo!(). ────────────
    let result = scanner::collect_md_files(root);

    assert!(
        !result.contains(&root.join("node_modules/mdlc_fixture_foo.md")),
        "node_modules/mdlc_fixture_foo.md must not appear in the scan set \
         (gitignored by node_modules/)"
    );
    assert!(
        result.contains(&root.join("mdlc_fixture_README.md")),
        "mdlc_fixture_README.md must appear in the scan set"
    );
    // No exact-count assertion: host global gitignore could exclude unrelated files.
}

// ─── AC-005 (traces to BC-2.01.003 invariant 1) ──────────────────────────────
// Fixture form: PLAIN (non-git) dir + `.ignore`
// (.ignore is honoured unconditionally by WalkBuilder regardless of require_git)

#[test]
fn test_BC_2_01_003_gitignored_file_not_scanned_as_source() {
    let dir = TempDir::new().expect("tempdir");
    let root = dir.path();

    // No git init: .ignore is always honoured, making this fixture git-independent
    fs::write(root.join(".ignore"), "mdlc_fixture_secret.md\n").expect("write .ignore");
    create_file(root, "mdlc_fixture_secret.md"); // excluded by .ignore
    create_file(root, "mdlc_fixture_visible.md"); // included

    // ── Red Gate history (commit ba83b1b): this call panicked at todo!(). ────────────
    let result = scanner::collect_md_files(root);

    assert!(
        !result.contains(&root.join("mdlc_fixture_secret.md")),
        "mdlc_fixture_secret.md must not be scanned as a link source (excluded by .ignore)"
    );
    assert!(
        result.contains(&root.join("mdlc_fixture_visible.md")),
        "mdlc_fixture_visible.md must be in the scan set"
    );
}

// ─── AC-006 (traces to BC-2.01.003 invariant 2) ──────────────────────────────
// Fixture form: PLAIN (non-git) dir + `.ignore`
//
// HALF-SCOPED (Scope Ruling 1): only clause (i) is asserted here.
//   Clause (i): the .ignore-excluded file does NOT appear in the scan set. ← tested
//   DEFERRED: Clause (ii) — "anchor table still built for the gitignored target"
//   (DI-006 case 2, Pass 1.5 / AnchorIndex). This belongs to link-extraction and
//   anchor-table stories in E-2. No anchor_table module, no AnchorIndex, and no
//   Pass 1.5 exist in S-1.01's file list. Asserting clause (ii) here would require
//   an unconstructible AnchorIndex or a vacuous assertion — both are forbidden.

#[test]
fn test_BC_2_01_003_gitignored_file_anchor_table_built_as_target() {
    let dir = TempDir::new().expect("tempdir");
    let root = dir.path();

    // .ignore excludes "mdlc_fixture_ignored_target.md" from the scan set (clause i only)
    fs::write(root.join(".ignore"), "mdlc_fixture_ignored_target.md\n").expect("write .ignore");
    create_file(root, "mdlc_fixture_ignored_target.md"); // excluded by .ignore
    create_file(root, "mdlc_fixture_source.md"); // in scan set

    // ── Red Gate history (commit ba83b1b): this call panicked at todo!(). ────────────
    // Clause (i): the .ignore-excluded file must NOT appear in the scan set.
    let result = scanner::collect_md_files(root);

    assert!(
        !result.contains(&root.join("mdlc_fixture_ignored_target.md")),
        "mdlc_fixture_ignored_target.md must not appear in the scan set (excluded by .ignore) \
         — clause (i) of BC-2.01.003 invariant 2"
    );
    // Positive gate: mdlc_fixture_source.md must be present (F-04 vacuous-pass
    // prevention — an empty Vec passes the negative assertion above vacuously).
    assert!(
        result.contains(&root.join("mdlc_fixture_source.md")),
        "mdlc_fixture_source.md must appear in the scan set (F-04 vacuous-pass prevention)"
    );
}

// ─── AC-007 (traces to BC-2.01.004 postcondition 1) ──────────────────────────
// Fixture form: plain tempdir with dot-directories at multiple names.

#[test]
fn test_BC_2_01_004_dot_directories_unconditionally_skipped() {
    let dir = TempDir::new().expect("tempdir");
    let root = dir.path();

    create_file(root, ".github/PULL_REQUEST_TEMPLATE.md"); // dot-dir — must be skipped
    create_file(root, ".git_backup/notes.md"); // dot-dir — must be skipped
    create_file(root, ".vitepress/config.md"); // dot-dir — must be skipped
                                               // P10-02: regression lock for dot-dirs whose name ENDS in `.`.
                                               // In `ignore 0.4.33`, `pathutil.rs:156/158` make `hidden(true)` return
                                               // "not hidden" for names ending in `.` or `..`, so this input class is
                                               // defended by `filter_entry`/`is_dot_dir_name` ALONE.  The `hidden(false)`
                                               // mutant is an accepted survivor; without this fixture that defence is
                                               // unverified.  Behavior verified correct by direct execution.
    create_file(root, ".trailing./mdlc_fixture_in_trailing_dot.md"); // dot-dir with trailing `.` — must be skipped
    create_file(root, "mdlc_fixture_README.md"); // not in dot-dir — must appear

    // ── Red Gate history (commit ba83b1b): this call panicked at todo!(). ────────────
    let result = scanner::collect_md_files(root);

    let result_set: HashSet<PathBuf> = result.into_iter().collect();
    assert!(
        !result_set.contains(&root.join(".github/PULL_REQUEST_TEMPLATE.md")),
        ".github/ is a dot-dir and must be unconditionally skipped (BC-2.01.004)"
    );
    assert!(
        !result_set.contains(&root.join(".git_backup/notes.md")),
        ".git_backup/ is a dot-dir and must be unconditionally skipped"
    );
    assert!(
        !result_set.contains(&root.join(".vitepress/config.md")),
        ".vitepress/ is a dot-dir and must be unconditionally skipped"
    );
    assert!(
        !result_set.contains(&root.join(".trailing./mdlc_fixture_in_trailing_dot.md")),
        ".trailing./ is a dot-dir (name starts with `.`) and must be unconditionally \
         skipped even though ignore 0.4.33 hidden() considers trailing-`.` names as \
         not hidden — defence is is_dot_dir_name alone (BC-2.01.004, P10-02)"
    );
    assert!(
        result_set.contains(&root.join("mdlc_fixture_README.md")),
        "mdlc_fixture_README.md (not in any dot-dir) must be in the scan set"
    );
    assert_eq!(
        result_set.len(),
        1,
        "only mdlc_fixture_README.md should be discovered; \
         .github/, .git_backup/, .vitepress/, and .trailing./ are all dot-dirs \
         and must be unconditionally skipped (BC-2.01.004)"
    );
}

// ─── AC-008 (traces to BC-2.01.004 invariant 1) ──────────────────────────────
// API-surface negative assertion (D-011 non-goal).
//
// Scope Ruling 2: no CLI arg parsing exists in S-1.01 (that belongs to S-1.02).
// What IS assertable at this story boundary: `collect_md_files` takes exactly one
// argument (`root: &Path`). The function signature has NO `hidden: bool`, no
// `allow_dot_dirs: bool`, no config struct, and no builder knob that could enable
// traversal into dot-directories. Dot-dir skipping is unconditional and not
// parameterized by any caller-visible parameter.
//
// Compile-time proof: this test compiles with a single argument. If the function
// signature gained a `hidden: bool` parameter, this line would cause a compile ERROR
// (wrong argument count), catching the violation before any test runs.
// Fixture form: plain tempdir.

#[test]
fn test_BC_2_01_004_no_override_flag_for_dot_dir_skip() {
    let dir = TempDir::new().expect("tempdir");
    let root = dir.path();

    create_file(root, ".hidden_dir/secret.md");
    create_file(root, "mdlc_fixture_visible.md");

    // The call below compiles with EXACTLY ONE argument, asserting the API surface:
    // no `hidden: bool`, no override config, no builder knob for dot-dir traversal.
    // This is both a compile-time and a runtime assertion of D-011.
    //
    // ── Red Gate history (commit ba83b1b): this call panicked at todo!(). ────────────
    let result = scanner::collect_md_files(root);

    // Positive assertion: mdlc_fixture_visible.md MUST appear in the scan set.
    // Without this, the invariant below would pass vacuously on an empty Vec —
    // an empty result is not a correct implementation.
    assert!(
        result.contains(&root.join("mdlc_fixture_visible.md")),
        "mdlc_fixture_visible.md must appear in the scan set"
    );

    // Negative assertion: the file inside the dot-directory must NOT appear.
    assert!(
        !result.contains(&root.join(".hidden_dir").join("secret.md")),
        ".hidden_dir/secret.md must not appear — dot-dir skip is unconditional (D-011)"
    );

    // Invariant: no path whose RELATIVE components (relative to root) contain a
    // dot-prefixed segment may appear.  We strip the absolute root prefix first so
    // that a dot-prefixed OS tempdir name (e.g. `/tmp/.tmpXXXXX` — tempfile's
    // default prefix on all platforms) in the absolute path does not trigger a
    // false failure.  Only the relative path components count for D-011.
    assert!(
        !result.iter().any(|p| {
            p.strip_prefix(root)
                .unwrap_or(p.as_path())
                .components()
                .any(|c| {
                    c.as_os_str()
                        .to_str()
                        .map(|s| s.starts_with('.'))
                        .unwrap_or(false)
                })
        }),
        "no file inside a dot-directory component must ever appear in the scan set \
         regardless of invocation — dot-dir skip is unconditional (D-011)"
    );
}

// ─── AC-009 (traces to BC-2.01.004 postcondition 2) ──────────────────────────
// Fixture form: plain tempdir with a directory-symlink cycle (EC-008).
//
// Gated on unix: symlink creation is a Unix-only API.  On non-unix targets this
// test would create no symlink, making both `cycle_link` negative assertions
// vacuously true — green while asserting nothing.  `#[cfg(unix)]` prevents that.

#[cfg(unix)]
#[test]
fn test_BC_2_01_004_directory_symlinks_not_followed() {
    let dir = TempDir::new().expect("tempdir");
    let root = dir.path();

    // Create a directory with real .md content.
    // Name is mdlc_fixture_-prefixed for hermeticity (N-2 fix).
    let dir_a = root.join("mdlc_fixture_dir_a");
    fs::create_dir_all(&dir_a).expect("create mdlc_fixture_dir_a");
    create_file(root, "mdlc_fixture_dir_a/real.md");

    // Create a directory-symlink cycle: mdlc_fixture_dir_a/cycle_link -> mdlc_fixture_dir_a
    // This replicates EC-008: `a/b -> a`.
    std::os::unix::fs::symlink(&dir_a, dir_a.join("cycle_link"))
        .expect("create directory symlink cycle");

    create_file(root, "README.md");

    // ── Red Gate history (commit ba83b1b): this call panicked at todo!(). ────────────
    // follow_links(false) prevents infinite recursion; no path containing "cycle_link"
    // must appear in the result.
    let result = scanner::collect_md_files(root);

    assert!(
        !result
            .iter()
            .any(|p| p.to_string_lossy().contains("cycle_link")),
        "directory symlinks must not be traversed; cycle_link must not appear in scan set"
    );
    // mdlc_fixture_dir_a/real.md is a real file (not behind a symlink) and must appear
    assert!(
        result.contains(&root.join("mdlc_fixture_dir_a/real.md")),
        "mdlc_fixture_dir_a/real.md must be discovered (it is a real file, not behind a dir symlink)"
    );
}

// ─── EC-009: non-cyclic out-of-root directory symlink (mutation-discriminating) ─
//
// WHY A SEPARATE TEST IS NEEDED:
//   The EC-008 (cyclic) fixtures used by AC-009 and VP-017 pass vacuously under
//   `follow_links(true)` because the `ignore` crate's loop detector returns an
//   error (not a path) for the looping entry, which `result.ok()?` swallows.
//   A NON-CYCLIC symlink pointing at an external directory DOES produce yielded
//   paths under `follow_links(true)`, making it the only fixture that truly
//   discriminates `follow_links(false)` from `follow_links(true)`.
//
// FIXTURE (EC-009 from the story edge-cases table):
//   docs -> ../shared-docs  (directory symlink, not a cycle)
//   Files under ../shared-docs are NOT discovered unless separately specified.
//
// Traceability: AC-009 / BC-2.01.004 postcondition 2 / DI-009 / EC-009
// Mutation target: `follow_links(false)` in `build_walk` / `collect_md_files`

#[cfg(unix)]
#[test]
fn test_BC_2_01_004_ec009_directory_symlink_to_outside_not_followed() {
    // Create an EXTERNAL directory (outside the scan root) containing a .md file.
    // Analogue: ../shared-docs/external.md from EC-009.
    let external_dir = TempDir::new().expect("external tempdir EC-009");
    let external = external_dir.path();
    create_file(external, "external.md");

    // Create the scan root (a separate TempDir so external is truly outside).
    let root_dir = TempDir::new().expect("scan root tempdir EC-009");
    let root = root_dir.path();

    // Create a non-dot, non-cyclic directory symlink inside the scan root:
    //   <root>/mdlc_fixture_docs  ->  <external>
    // Name is mdlc_fixture_-prefixed for hermeticity (N-2 fix); analogous to
    // EC-009: docs -> ../shared-docs.
    std::os::unix::fs::symlink(external, root.join("mdlc_fixture_docs"))
        .expect("create non-cyclic out-of-root directory symlink (EC-009)");

    // A real in-root .md file: prevents vacuous pass on an empty result.
    create_file(root, "mdlc_fixture_README.md");

    let result = scanner::collect_md_files(root);

    // Positive gate: mdlc_fixture_README.md MUST appear.
    // If the implementation returns an empty Vec, the negative assertions below
    // would pass vacuously, so this guard is mandatory.
    assert!(
        result.contains(&root.join("mdlc_fixture_README.md")),
        "mdlc_fixture_README.md must be discovered; empty scan set is not a correct \
         implementation (EC-009 vacuous-pass prevention)"
    );

    // Negative assertion 1: no discovered path traverses the mdlc_fixture_docs symlink.
    // Under follow_links(false) the symlink entry is seen and skipped.
    // Under follow_links(true) the walk descends and yields paths containing an
    // "mdlc_fixture_docs" path component — this is the mutation-kill signal.
    assert!(
        !result
            .iter()
            .any(|p| p.components().any(|c| c.as_os_str() == "mdlc_fixture_docs")),
        "no path with a 'mdlc_fixture_docs' component must appear — the directory symlink \
         must not be traversed \
         (AC-009 / BC-2.01.004 postcondition 2 / DI-009 / EC-009, \
         mutation-discriminating case for follow_links(false))"
    );

    // Negative assertion 2: external.md must not be reachable by any path.
    assert!(
        !result
            .iter()
            .any(|p| p.file_name().is_some_and(|n| n == "external.md")),
        "external.md lives outside the scan root and is reachable only via the docs \
         directory symlink; it must not be discovered when follow_links(false) is set \
         (EC-009 / BC-2.01.004 postcondition 2)"
    );

    // Exactly one file should be in the scan set.
    assert_eq!(
        result.len(),
        1,
        "only mdlc_fixture_README.md should be in the scan set; \
         external.md behind the mdlc_fixture_docs symlink must be excluded (EC-009)"
    );
}

// ─── AC-010 (traces to BC-2.01.004 invariant 3) ──────────────────────────────
// Fixture form: plain tempdir with a dot-directory.
//
// HALF-SCOPED (Scope Ruling 1): only clause (i) is asserted here.
//   Clause (i): the dot-dir .md file does NOT appear in the scan set. ← tested
//   DEFERRED: Clause (ii) — "anchor table still built for dot-dir .md target"
//   (DI-006 case 3, Pass 1.5 / AnchorIndex). Belongs to link-extraction and
//   anchor-table stories in E-2. No anchor_table module, no AnchorIndex, and
//   no Pass 1.5 exist in S-1.01's file list. Asserting clause (ii) here would
//   require an unconstructible AnchorIndex or a vacuous/tautological assertion.

#[test]
fn test_BC_2_01_004_dot_dir_md_file_anchor_table_built_as_target() {
    let dir = TempDir::new().expect("tempdir");
    let root = dir.path();

    // .vitepress/api.md is inside a dot-directory (should be excluded from scan set)
    create_file(root, ".vitepress/api.md");
    create_file(root, "mdlc_fixture_source.md");

    // ── Red Gate history (commit ba83b1b): this call panicked at todo!(). ────────────
    // Clause (i): dot-dir .md must NOT appear in the scan set as a link source.
    let result = scanner::collect_md_files(root);

    assert!(
        !result.contains(&root.join(".vitepress/api.md")),
        ".vitepress/api.md is in a dot-directory and must not appear in the scan set \
         — clause (i) of BC-2.01.004 invariant 3"
    );
    // Positive gate: mdlc_fixture_source.md must be present (F-04 vacuous-pass
    // prevention — an empty Vec passes the negative assertion above vacuously).
    assert!(
        result.contains(&root.join("mdlc_fixture_source.md")),
        "mdlc_fixture_source.md must appear in the scan set (F-04 vacuous-pass prevention)"
    );
}

// ─── AC-011 (traces to BC-2.01.005 postcondition 1) ──────────────────────────
//
// NOTE — predicate-level test only: this test calls `is_md_extension` on
// string literals and never creates a file on disk or calls `collect_md_files`.
// It therefore does NOT exercise BC-2.01.005's "discovered via traversal"
// precondition.  The traversal-level coverage that discharges that precondition
// is provided by `test_BC_2_01_005_ec005_ec006a_ec006b_traversal_excludes_non_md_extensions`.

#[test]
fn test_BC_2_01_005_exact_md_extension_included() {
    // ── Red Gate history (commit ba83b1b): is_md_extension panicked at todo!(). ──────
    assert!(
        scanner::is_md_extension(&PathBuf::from("README.md")),
        "README.md must pass the .md extension filter (BC-2.01.005)"
    );
    // Additional canonical vectors from BC-2.01.005 test-vector table:
    assert!(
        scanner::is_md_extension(&PathBuf::from("notes.md")),
        "notes.md must pass"
    );
    assert!(
        scanner::is_md_extension(&PathBuf::from("path/to/deep/file.md")),
        "nested path with .md extension must pass"
    );
}

// ─── AC-012 (traces to BC-2.01.005 postcondition 2) ──────────────────────────

#[test]
fn test_BC_2_01_005_non_md_extensions_excluded() {
    // Canonical non-goal extensions from BC-2.01.005 and D-012.
    // `.Md` is explicitly named in the AC text and must be present here.
    let excluded = [
        "README.MD",
        "notes.Md", // AC text names .Md explicitly (mixed-case, BC-2.01.005 invariant 1)
        "notes.markdown",
        "notes.mdx",
        "notes.mdown",
        "notes.mkd",
        "doc.txt",
        "page.html",
        "image.png",
        "archive.zip",
        "data.json",
    ];

    // ── Red Gate history (commit ba83b1b): is_md_extension panicked at todo!() on first call. ─
    for name in &excluded {
        assert!(
            !scanner::is_md_extension(&PathBuf::from(name)),
            "'{}' must NOT pass the .md extension filter (D-012 non-goal)",
            name
        );
    }
}

// ─── AC-013 (traces to BC-2.01.005 invariant 1) ──────────────────────────────

#[test]
fn test_BC_2_01_005_case_sensitive_byte_match() {
    // ── Red Gate history (commit ba83b1b): is_md_extension panicked at todo!() on first call. ─
    // Case-sensitivity: ONLY the exact lowercase byte sequence ".md" is matched.
    assert!(
        !scanner::is_md_extension(&PathBuf::from("README.MD")),
        ".MD must NOT match — case-sensitive byte comparison (BC-2.01.005 invariant 1, D-012)"
    );
    assert!(
        !scanner::is_md_extension(&PathBuf::from("notes.Md")),
        ".Md must NOT match"
    );
    assert!(
        !scanner::is_md_extension(&PathBuf::from("notes.mD")),
        ".mD must NOT match"
    );
    // Only exact lowercase ".md" is accepted:
    assert!(
        scanner::is_md_extension(&PathBuf::from("notes.md")),
        ".md (exact lowercase) MUST match"
    );
}

// ─── EC-005 / EC-006a / EC-006b: traversal-level non-.md extension filter ────
//
// AC-011/AC-012/AC-013 verify `is_md_extension` at the predicate level on string
// literals — no file is ever created on disk in those tests.  AC-012 specifies
// that non-.md variants are "excluded from the scan set **when discovered via
// directory traversal**".  This test provides the end-to-end traversal coverage
// that the predicate tests cannot: it puts actual files with non-.md extensions
// in a real TempDir, calls `collect_md_files`, and asserts the scan set contains
// only the one legitimate `good.md`.
//
// Mutation-discriminating: temporarily changing `ext == "md"` to
// `ext.eq_ignore_ascii_case("md")` in scanner.rs causes `README.MD` to be
// INCLUDED in the scan set, breaking the negative assertion below.  The three
// predicate-level AC tests would NOT catch this regression via traversal.
//
// Traceability: BC-2.01.005 postcondition 2 / EC-005 / EC-006a / EC-006b / D-012

#[test]
fn test_BC_2_01_005_ec005_ec006a_ec006b_traversal_excludes_non_md_extensions() {
    let dir = TempDir::new().expect("tempdir");
    let root = dir.path();

    // Non-.md files that must be absent from the scan set when traversed:
    create_file(root, "mdlc_fixture_README.MD"); // EC-005: uppercase .MD
    create_file(root, "mdlc_fixture_notes.markdown"); // EC-006a
    create_file(root, "mdlc_fixture_notes.mdx"); // EC-006b
    create_file(root, "mdlc_fixture_notes.mdown"); // D-012 non-goal
    create_file(root, "mdlc_fixture_notes.mkd"); // D-012 non-goal
    create_file(root, "mdlc_fixture_notes.txt"); // D-012 non-goal
    create_file(root, "mdlc_fixture_page.html"); // D-012 non-goal

    // The only file that MUST appear — mandatory positive gate (vacuous-pass
    // prevention: without it, an empty Vec passes every negative assertion).
    create_file(root, "mdlc_fixture_good.md");

    let result = scanner::collect_md_files(root);

    // Positive gate: mdlc_fixture_good.md must be discovered via traversal.
    assert!(
        result.contains(&root.join("mdlc_fixture_good.md")),
        "mdlc_fixture_good.md must be in the scan set \
         (EC-005/EC-006a/EC-006b traversal test, vacuous-pass prevention)"
    );

    // Negative assertions: every non-.md file must be absent from the scan set.
    assert!(
        !result.contains(&root.join("mdlc_fixture_README.MD")),
        "mdlc_fixture_README.MD (uppercase) must not appear in scan set via traversal (EC-005)"
    );
    assert!(
        !result.contains(&root.join("mdlc_fixture_notes.markdown")),
        "mdlc_fixture_notes.markdown must not appear in scan set via traversal (EC-006a)"
    );
    assert!(
        !result.contains(&root.join("mdlc_fixture_notes.mdx")),
        "mdlc_fixture_notes.mdx must not appear in scan set via traversal (EC-006b)"
    );
    assert!(
        !result.contains(&root.join("mdlc_fixture_notes.mdown")),
        "mdlc_fixture_notes.mdown must not appear in scan set via traversal (D-012)"
    );
    assert!(
        !result.contains(&root.join("mdlc_fixture_notes.mkd")),
        "mdlc_fixture_notes.mkd must not appear in scan set via traversal (D-012)"
    );
    assert!(
        !result.contains(&root.join("mdlc_fixture_notes.txt")),
        "mdlc_fixture_notes.txt must not appear in scan set via traversal (D-012)"
    );
    assert!(
        !result.contains(&root.join("mdlc_fixture_page.html")),
        "mdlc_fixture_page.html must not appear in scan set via traversal (D-012)"
    );

    // Exactly one file: only mdlc_fixture_good.md.
    assert_eq!(
        result.len(),
        1,
        "exactly one file (mdlc_fixture_good.md) must be in the scan set; \
         all non-.md files must be excluded via traversal \
         (EC-005 / EC-006a / EC-006b / D-012)"
    );
}

// ─── VP-016: gitignored files never appear in the scan set ───────────────────
//
// Covers BOTH fixture forms (Scope Ruling 4):
//   Form A — git repo + `.gitignore`
//   Form B — plain (non-git) dir + `.ignore`
//
// This is a dedicated integration test for VP-016, separate from the 13 ACs.
// At Red Gate (commit ba83b1b) it failed on Form A's collect_md_files call (todo!() panic).
//
// Process-environment policy: see module-level doc comment.  Form A uses
// the `mdlc_fixture_` prefix on fixture files and omits the len() assertion.

#[test]
fn test_vp016_gitignored_files_never_in_scan_set() {
    // ── Form A: git repo + .gitignore ────────────────────────────────────────
    {
        let dir = TempDir::new().expect("tempdir form A");
        let root = dir.path();

        // Hermetic config for the git subprocess only (per-command env — not
        // process-env mutation).
        let hermetic_cfg = root.join(".hermetic_gitconfig");
        fs::write(&hermetic_cfg, "").expect("write hermetic gitconfig form A");

        git_init(root, &hermetic_cfg);
        fs::write(root.join(".gitignore"), "excluded/\n").expect("write .gitignore");
        create_file(root, "excluded/mdlc_fixture_hidden.md");
        create_file(root, "mdlc_fixture_visible.md");

        // ── Red Gate history (commit ba83b1b): this call panicked at todo!(). ────────────
        let result = scanner::collect_md_files(root);

        assert!(
            !result.iter().any(|p| p.starts_with(root.join("excluded"))),
            "VP-016 form A: gitignored files must never appear in scan set"
        );
        assert!(
            result.contains(&root.join("mdlc_fixture_visible.md")),
            "VP-016 form A: mdlc_fixture_visible.md must appear in scan set (positive gate)"
        );
        // No exact-count assertion: host global gitignore may exclude other files.
    }

    // Form B is unreachable in Red Gate state because Form A panics first.
    // Both forms are present to pin the behaviour the implementer must deliver.
    //
    // ── Form B: plain (non-git) dir + .ignore ────────────────────────────────
    {
        let dir = TempDir::new().expect("tempdir form B");
        let root = dir.path();

        // No git init — .ignore is honoured unconditionally
        fs::write(root.join(".ignore"), "excluded/\n").expect("write .ignore");
        create_file(root, "excluded/hidden.md");
        create_file(root, "mdlc_fixture_visible.md");

        let result = scanner::collect_md_files(root);

        assert!(
            !result.iter().any(|p| p.starts_with(root.join("excluded"))),
            "VP-016 form B: .ignore-excluded files must never appear in scan set"
        );
        assert!(
            result.contains(&root.join("mdlc_fixture_visible.md")),
            "VP-016 form B: mdlc_fixture_visible.md must appear in scan set (positive gate)"
        );
        assert_eq!(
            result.len(),
            1,
            "VP-016 form B: exactly one file (mdlc_fixture_visible.md) must be in the scan set"
        );
    }
}

// ─── VP-017: property-based test — scan terminates for arbitrary tree ─────────
//
// Uses proptest to generate varied (depth, file_count, include_symlink_cycle)
// combinations. `collect_md_files` must terminate and return only paths under
// root for every generated input.
//
// At Red Gate (commit ba83b1b): proptest panicked on the first generated case because
// `collect_md_files` called `todo!()`. The test was reported as FAILED.

use proptest::prelude::*;

proptest! {
    #![proptest_config(ProptestConfig::with_cases(256))]

    #[test]
    fn test_vp017_scan_terminates_arbitrary_tree(
        depth in 1usize..4usize,
        file_count in 0usize..8usize,
        include_symlink_cycle in proptest::bool::ANY,
    ) {
        let dir = TempDir::new().expect("tempdir VP-017");
        let root = dir.path();

        // Build a layered tree of .md files at the generated depth.
        // Directory names are mdlc_fixture_-prefixed for hermeticity (N-2 fix).
        for i in 0..file_count {
            let mut rel = format!("mdlc_fixture_file_{}.md", i);
            for d in 0..depth {
                rel = format!("mdlc_fixture_dir_{}_{}/{}", d, i, rel);
            }
            create_file(root, &rel);
        }

        // Hold TempDirs that must outlive the scan call on Unix.
        // On non-Unix the vec stays empty; `mut` is needed only on Unix.
        #[allow(unused_mut)]
        let mut _keep_alive: Vec<TempDir> = Vec::new();

        // Optionally add symlink scenarios when include_symlink_cycle is true:
        //   EC-008 — self-referential cycle:  cycle_root/self_link -> cycle_root
        //   EC-009 — non-cyclic out-of-root:  outlink -> <external TempDir>
        // EC-009 is the mutation-discriminating case for follow_links(false):
        // a non-cyclic symlink yields paths under follow_links(true) but must
        // not yield any path under follow_links(false).
        if include_symlink_cycle {
            // EC-008: self-referential cycle.
            // Directory name is mdlc_fixture_-prefixed for hermeticity (N-2 fix).
            let cycle_dir = root.join("mdlc_fixture_cycle_root");
            fs::create_dir_all(&cycle_dir)
                .expect("create mdlc_fixture_cycle_root (VP-017 EC-008 fixture)");
            #[cfg(unix)]
            std::os::unix::fs::symlink(&cycle_dir, cycle_dir.join("self_link"))
                .expect("create self-referential symlink (VP-017 EC-008 fixture)");

            // EC-009: non-cyclic out-of-root directory symlink
            #[cfg(unix)]
            {
                let outside = TempDir::new().expect("tempdir VP-017 outside");
                create_file(outside.path(), "outside.md");
                std::os::unix::fs::symlink(outside.path(), root.join("outlink"))
                    .expect("create out-of-root directory symlink (VP-017 EC-009 fixture)");
                _keep_alive.push(outside); // keep alive until after the scan
            }
        }

        // ── Red Gate history (commit ba83b1b): panicked at todo!() on first generated case. ─
        // Must terminate for ALL generated inputs including cycles
        // (follow_links(false) in WalkBuilder breaks cycles per VP-017).
        let result = scanner::collect_md_files(root);

        // All discovered paths must be under root
        for path in &result {
            prop_assert!(
                path.starts_with(root),
                "every discovered path must be under root; got {:?} with root {:?}",
                path, root
            );
        }

        // EC-008: symlink-cycle components must never appear in scan results.
        // Gated on unix: symlinks are only created on unix (see #[cfg(unix)] in the
        // fixture setup above), so on non-unix these assertions would be vacuously
        // true — gate them to make the conditional explicit and prevent misleading
        // green results on non-unix platforms.
        #[cfg(unix)]
        prop_assert!(
            !result.iter().any(|p| p.to_string_lossy().contains("self_link")),
            "directory symlink components must not appear in scan results"
        );

        // EC-009: files behind a non-cyclic out-of-root directory symlink must
        // not appear (mutation-discriminating for follow_links(false)).
        #[cfg(unix)]
        prop_assert!(
            !result.iter().any(|p| p.file_name().is_some_and(|n| n == "outside.md")),
            "files in out-of-root directories reachable only via a non-cyclic \
             directory symlink must not appear in scan results \
             (EC-009, mutation-discriminating for follow_links(false))"
        );

        // EC-009: the outlink symlink component itself must not appear in any path.
        #[cfg(unix)]
        prop_assert!(
            !result.iter().any(|p| p.to_string_lossy().contains("outlink")),
            "outlink directory symlink must not be traversed; \
             no path with 'outlink' component may appear in scan results (EC-009)"
        );
    }
}

// ─── BC-2.01.005 postcondition 1: directories with .md names excluded ─────────
//
// Mutation target: `if !file_type.is_file() { return None; }` → `if false { ... }`
//   in `collect_md_files`.
//
// WHY THIS TEST IS NEEDED:
//   `ignore::WalkBuilder` yields both files and directories during traversal.
//   The `is_file()` guard ensures only regular files are considered.  If that
//   guard is neutered, a DIRECTORY whose name ends in `.md`
//   (e.g. `mdlc_fixture_notes.md/`) passes the `is_md_extension` check and is
//   incorrectly returned as a scannable Markdown file.  No existing test
//   creates such a directory, so the mutant survives.
//
// BC CONTRACT:
//   BC-2.01.005 postcondition 1: "Files with extension `.md` (exact lowercase
//   match) are included."  A directory is not a file; the directory
//   `mdlc_fixture_notes.md` therefore must NOT appear in the scan set.
//   BC-2.01.001 postcondition 1 likewise scopes the scan set to files.
//
// FIXTURE (P10-04: all fixture dir names carry the `mdlc_fixture_` prefix so
// that no host-global gitignore pattern can accidentally exclude them):
//   - `mdlc_fixture_notes.md/`                    — a DIRECTORY (must NOT appear)
//   - `mdlc_fixture_notes.md/mdlc_fixture_inner.md` — real file inside (MUST appear)
//   - `mdlc_fixture_good.md`                      — normal file (MUST appear; positive gate)
//
// Under the mutant (is_file() removed): `mdlc_fixture_notes.md` (directory)
//   passes the extension check and is added → result.len() == 3, both the
//   direct contains-check and the len-check fail, killing the mutant.
//
// Traceability: BC-2.01.005 postcondition 1 / BC-2.01.001 postcondition 1

#[test]
fn test_BC_2_01_005_post1_directory_with_md_name_not_in_scan_set() {
    let dir = TempDir::new().expect("tempdir");
    let root = dir.path();

    // Create a DIRECTORY named mdlc_fixture_notes.md (not a file).
    // The `mdlc_fixture_` prefix is required by the module's fixture hermeticity
    // policy (P10-04): no host-global gitignore can accidentally exclude it.
    // The `.md` suffix is load-bearing: it exercises the `is_file()` guard.
    fs::create_dir_all(root.join("mdlc_fixture_notes.md"))
        .expect("create directory named mdlc_fixture_notes.md");

    // Put a real .md file inside it so the tree is realistic and proves the
    // walker still descends into the directory (it must — it is not a symlink,
    // not a dot-dir, and not gitignored).
    create_file(root, "mdlc_fixture_notes.md/mdlc_fixture_inner.md");

    // A normal .md file — mandatory positive gate (F-04 vacuous-pass prevention:
    // without it, an empty Vec passes every negative assertion vacuously).
    create_file(root, "mdlc_fixture_good.md");

    let result = scanner::collect_md_files(root);

    // ── Positive gate 1: mdlc_fixture_good.md must be discovered. ─────────────
    assert!(
        result.contains(&root.join("mdlc_fixture_good.md")),
        "mdlc_fixture_good.md must be in the scan set \
         (positive gate, BC-2.01.005 postcondition 1)"
    );

    // ── Positive gate 2: mdlc_fixture_notes.md/mdlc_fixture_inner.md is a real
    // file and must be discovered.  It must not be lost because its parent dir
    // has a .md name.
    assert!(
        result.contains(
            &root
                .join("mdlc_fixture_notes.md")
                .join("mdlc_fixture_inner.md")
        ),
        "mdlc_fixture_notes.md/mdlc_fixture_inner.md is a real .md file and must be in \
         the scan set \
         (BC-2.01.005 postcondition 1 — files inside a .md-named directory are still files)"
    );

    // ── Negative assertion — MUTATION TARGET: is_file() guard removed. ────────
    // Under the mutant the directory `mdlc_fixture_notes.md` passes the
    // extension check and is included; this assertion FAILS — killing the mutant.
    assert!(
        !result.contains(&root.join("mdlc_fixture_notes.md")),
        "the directory named mdlc_fixture_notes.md must NOT appear in the scan set — \
         only regular files with .md extension are included, not directories \
         (BC-2.01.005 postcondition 1)"
    );

    // ── Count assertion — secondary discriminator. ────────────────────────────
    // Exactly two files: mdlc_fixture_good.md and
    // mdlc_fixture_notes.md/mdlc_fixture_inner.md.
    // Under the mutant, mdlc_fixture_notes.md (directory) would be a third entry.
    assert_eq!(
        result.len(),
        2,
        "exactly two files must be in the scan set \
         (mdlc_fixture_good.md and mdlc_fixture_notes.md/mdlc_fixture_inner.md); \
         the mdlc_fixture_notes.md directory must not be counted \
         (BC-2.01.005 postcondition 1)"
    );
}

// ─── Regression lock: BC-2.01.003 postcondition 1 / EC-002 (defect F-B2, fixed) ────
//
// HISTORICAL DEFECT F-B2 (fixed in scanner.rs): `.gitignore` was NOT honored
// outside a git repository because `build_walk` did not call `require_git(false)`.
// The `ignore` crate defaults `require_git` to `true`; without `require_git(false)`,
// `.gitignore` files were honoured ONLY inside a real git repository.  In a
// non-git directory containing a `.gitignore` with `node_modules/`, the file
// `node_modules/mdlc_fixture_foo.md` WAS returned by `collect_md_files`.
//
// FIX APPLIED (scanner.rs:59): `require_git(false)` is now set in `build_walk`,
// so `.gitignore` is honoured even in non-git directories.  This test is the
// GREEN regression lock that must stay green.
//
// BC-2.01.003 postcondition 1: "Every file that matches a pattern in any
//   applicable .gitignore or .ignore file is excluded from the scan set."
//
// EC-002: `node_modules/**/*.md` (5000 files); `node_modules/` in `.gitignore`
//         → All 5000 files excluded; no performance blowout.

#[test]
fn test_BC_2_01_003_post1_gitignore_honored_outside_git_repo() {
    // NO git init — this is a plain directory, not a git repository.
    let dir = TempDir::new().expect("tempdir");
    let root = dir.path();

    // .gitignore declares node_modules/ as excluded.
    fs::write(root.join(".gitignore"), "node_modules/\n").expect("write .gitignore");

    // This file is matched by node_modules/ and must NOT appear in the scan set.
    // With defect F-B2 present (require_git=true default), the .gitignore is
    // silently skipped in non-git directories and this file IS returned — the
    // negative assertion below FAILS, exposing the defect.
    create_file(root, "node_modules/mdlc_fixture_foo.md");

    // Positive gate: a normal .md file outside node_modules must appear.
    // Prevents vacuous pass on an empty scan set (F-04).
    create_file(root, "mdlc_fixture_README.md");

    let result = scanner::collect_md_files(root);

    // Positive gate (F-04 vacuous-pass prevention): mdlc_fixture_README.md must
    // be in the scan set.
    assert!(
        result.contains(&root.join("mdlc_fixture_README.md")),
        "mdlc_fixture_README.md must be in the scan set (positive gate, F-04)"
    );

    // BC-2.01.003 postcondition 1 / EC-002: the .gitignore-excluded file must
    // NOT appear — even in a non-git directory.
    // THIS ASSERTION FAILS with defect F-B2: require_git=true causes .gitignore
    // to be silently skipped outside a git repo, so node_modules/mdlc_fixture_foo.md
    // appears in the scan set.
    assert!(
        !result.contains(&root.join("node_modules/mdlc_fixture_foo.md")),
        "node_modules/mdlc_fixture_foo.md must not appear in the scan set \
         (excluded by .gitignore per BC-2.01.003 postcondition 1 / EC-002). \
         Regression lock for defect F-B2: `require_git(false)` MUST remain set \
         in build_walk (scanner.rs) — removing it drops .gitignore support in \
         non-git directories and this assertion fails."
    );
}

// ─── EC-001: empty scan set when no .md files exist ──────────────────────────
//
// EC-001 from the story edge-cases table:
//   "CWD has no .md files at any depth → Scan set is empty; no crash."
//
// No existing test covers EC-001.  This test creates a tempdir containing only
// non-.md files and asserts that collect_md_files returns an empty Vec without
// panicking.  The "No markdown files found." CLI exit message is deferred to
// S-1.02; we assert only the empty scan set here.
//
// Fixture form: plain tempdir — no gitignore exclusion needed, tests pure
// extension filtering.
//
// Traceability: BC-2.01.001 / EC-001

#[test]
fn test_BC_2_01_001_ec001_empty_scan_set_when_no_md_files() {
    let dir = TempDir::new().expect("tempdir");
    let root = dir.path();

    // Only non-.md files — none of these match the .md-only filter (BC-2.01.005).
    create_file(root, "notes.txt");
    create_file(root, "image.png");
    create_file(root, "sub/data.json");

    // collect_md_files must not panic (EC-001: "no crash") and must return empty.
    let result = scanner::collect_md_files(root);

    // EC-001 postcondition: the scan set is empty when no .md files exist.
    // The assertion itself IS the positive outcome — there is no vacuous-pass
    // risk here because we are asserting emptiness (not absence of a specific
    // file).  The "No markdown files found." CLI message is deferred to S-1.02.
    assert!(
        result.is_empty(),
        "scan set must be empty when no .md files exist at any depth \
         (EC-001 / BC-2.01.001): got {:?}",
        result
    );
}

// ─── EC-004: real .git/ directory — .md files inside must be skipped ─────────
//
// EC-004 from the story edge-cases table.  The existing dot-dir test
// (test_BC_2_01_004_dot_directories_unconditionally_skipped) uses `.git_backup/`
// and similar names — never an actual `.git/` directory.  The `ignore` crate
// special-cases `.git` for repository detection, making it a genuinely different
// code path from generic dot-directory skipping via `hidden(true)`.  This test
// exercises that specific path.
//
// The `.git/` directory is created with `fs::create_dir_all` — no `git init`.
// Creating it manually is sufficient to trigger the `.git`-specific handling in
// the `ignore` crate while keeping the fixture simple and hermetic.
//
// Fixture form: plain tempdir with a manually-created `.git/` directory.
//
// Traceability: BC-2.01.004 postcondition 1 / EC-004

#[test]
fn test_BC_2_01_004_ec004_real_git_directory_md_files_skipped() {
    let dir = TempDir::new().expect("tempdir");
    let root = dir.path();

    // Create a real .git/ directory (no git init — just mkdir).
    fs::create_dir_all(root.join(".git")).expect("create .git dir");

    // .md files inside .git/ must be unconditionally excluded because .git is
    // a dot-directory (BC-2.01.004 postcondition 1) AND is special-cased by
    // the ignore crate for repository detection.
    create_file(root, ".git/COMMIT_EDITMSG.md");
    create_file(root, ".git/notes.md");

    // Positive gate: a normal .md file outside .git/ must appear in the scan set.
    // Without this, an empty result passes every negative assertion vacuously (F-04).
    create_file(root, "mdlc_fixture_README.md");

    let result = scanner::collect_md_files(root);

    // Positive gate (F-04 vacuous-pass prevention).
    assert!(
        result.contains(&root.join("mdlc_fixture_README.md")),
        "mdlc_fixture_README.md must be in the scan set \
         (positive gate, EC-004 / BC-2.01.004 postcondition 1)"
    );

    // Negative assertions: .md files inside .git/ must never appear.
    assert!(
        !result.contains(&root.join(".git/COMMIT_EDITMSG.md")),
        ".git/COMMIT_EDITMSG.md must not appear — .git is a dot-dir and is \
         unconditionally skipped (EC-004 / BC-2.01.004 postcondition 1)"
    );
    assert!(
        !result.contains(&root.join(".git/notes.md")),
        ".git/notes.md must not appear — .git is a dot-dir and is \
         unconditionally skipped (EC-004 / BC-2.01.004 postcondition 1)"
    );
}

// ─── AC-005 companion: real .gitignore inside a git-init'd repo ──────────────
//
// AC-005 (`test_BC_2_01_003_gitignored_file_not_scanned_as_source`) uses a
// PLAIN (non-git) dir with a `.ignore` file — its name is mandated by the
// story's AC-005 `**Test:**` field and must NOT be modified.  That fixture
// exercises `.ignore` (honoured unconditionally); it does NOT exercise the
// `.gitignore`-in-git-repo code path.
//
// This companion test covers the SAME invariant (BC-2.01.003 invariant 1) but
// uses a REAL `.gitignore` inside a `git init`-ed tempdir as a realistic
// end-to-end fixture, complementing the synthetic plain-dir tests.  It does NOT
// exercise a `require_git=true` code path — `build_walk` calls `require_git(false)`,
// so the `require_git=true` path is unreachable through `collect_md_files`; the
// stated justification in any prior version of this comment was void.  The test's
// real value is as a belt-and-suspenders real-git-repo fixture.  Using hermetic git
// config on the subprocess (not process-env mutation) keeps it safe for concurrent runs.
//
// Fixture form: GIT REPO + real `.gitignore` (Scope Ruling 4, Form A).
//
// Traceability: BC-2.01.003 invariant 1 / AC-005 companion / S-1.01

#[test]
fn test_BC_2_01_003_inv1_gitignored_source_not_scanned_real_gitignore() {
    let dir = TempDir::new().expect("tempdir");
    let root = dir.path();

    // Hermetic config for the git subprocess only (per-command env — not
    // process-env mutation; see module-level doc comment and git_init helper).
    let hermetic_cfg = root.join(".hermetic_gitconfig");
    fs::write(&hermetic_cfg, "").expect("write hermetic gitconfig");

    // git init for Scope Ruling 4 belt-and-suspenders assurance; require_git(false)
    // in build_walk honours .gitignore unconditionally — git init is NOT required
    // for .gitignore to work (see git_init doc comment).
    git_init(root, &hermetic_cfg);

    // .gitignore excludes mdlc_fixture_gitignored_source.md.
    fs::write(
        root.join(".gitignore"),
        "mdlc_fixture_gitignored_source.md\n",
    )
    .expect("write .gitignore");

    // This file is matched by .gitignore and must NOT appear in the scan set.
    create_file(root, "mdlc_fixture_gitignored_source.md");

    // This file is NOT gitignored and must appear in the scan set.
    create_file(root, "mdlc_fixture_visible_source.md");

    let result = scanner::collect_md_files(root);

    // Positive gate (F-04 vacuous-pass prevention): mdlc_fixture_visible_source.md
    // must be in the scan set.
    assert!(
        result.contains(&root.join("mdlc_fixture_visible_source.md")),
        "mdlc_fixture_visible_source.md must be in the scan set \
         (positive gate, BC-2.01.003 invariant 1 / AC-005 companion)"
    );

    // BC-2.01.003 invariant 1: a gitignored file must not appear in the scan set
    // — it must never be scanned as a link source.
    assert!(
        !result.contains(&root.join("mdlc_fixture_gitignored_source.md")),
        "mdlc_fixture_gitignored_source.md must not appear in the scan set \
         (excluded by real .gitignore in git-init'd repo; \
         BC-2.01.003 invariant 1 / AC-005 companion)"
    );
    // No exact-count assertion: host global gitignore may exclude unrelated files.
}

// ─── Regression lock: BC-2.01.004 invariant 1 / EC-003 (defect F-A1, fixed) ──────
//
// BC-2.01.004 invariant 1: "ALL dot-directories are unconditionally excluded.
//   No flag overrides this (D-011)."
// EC-003: ".github/PULL_REQUEST_TEMPLATE.md … unconditionally skipped."
//
// HISTORICAL DEFECT F-A1 (fixed in scanner.rs): `ignore` 0.4.33's hidden filter
// (hidden(true)) is SUBORDINATE to ignore-rule matches.  A .gitignore containing:
//   .*
//   !.github
// re-enabled traversal into .github/ via the negation/whitelist pattern.
// With require_git(false) set (so .gitignore is honoured outside git repos),
// a plain-tempdir fixture with these two files:
//   .github/PULL_REQUEST_TEMPLATE.md  (inside a dot-directory)
//   mdlc_fixture_README.md             (normal .md outside dot-dir)
// produced scan set [".github/PULL_REQUEST_TEMPLATE.md", "mdlc_fixture_README.md"].
// The dot-directory file WAS incorrectly included.
//
// FIX APPLIED (scanner.rs): `collect_md_files` now post-filters every path,
// rejecting any path whose relative components contain a dot-prefixed segment
// (reuses is_dot_dir_name for byte-wise comparison).  This overrides the ignore
// crate's whitelist behaviour and is the structural backstop for BC-2.01.004
// invariant 1.  This test is the GREEN regression lock that must stay green.

#[test]
fn test_BC_2_01_004_inv1_dot_dir_skip_not_defeatable_by_ignore_whitelist() {
    let dir = TempDir::new().expect("tempdir");
    let root = dir.path();

    // .gitignore: ".*" excludes all dot-entries; "!.github" whitelists .github
    // via negation.  This is the exact two-line pattern confirmed by the probe
    // to defeat hidden(true) in ignore 0.4.33.  require_git(false) is active in
    // build_walk, so this .gitignore is honoured without a git init.
    fs::write(root.join(".gitignore"), ".*\n!.github\n").expect("write .gitignore");

    // File inside the whitelisted dot-directory — MUST be unconditionally skipped.
    create_file(root, ".github/PULL_REQUEST_TEMPLATE.md");

    // Normal .md file outside any dot-directory — MUST appear in the scan set.
    create_file(root, "mdlc_fixture_README.md");

    let result = scanner::collect_md_files(root);

    // Positive gate (F-04 vacuous-pass prevention): the non-dot-dir file MUST appear.
    assert!(
        result.contains(&root.join("mdlc_fixture_README.md")),
        "mdlc_fixture_README.md must appear in the scan set (F-04 positive gate)"
    );

    // BC-2.01.004 invariant 1 / EC-003: NOTHING under .github/ may appear, even
    // when a .gitignore whitelist pattern (!.github) re-enables traversal.
    //
    // Regression lock for defect F-A1 (fixed): this assertion was red when
    // collect_md_files had no post-filter.  The post-filter now makes the
    // dot-dir exclusion unconditional regardless of ignore-rule whitelists.
    assert!(
        !result.contains(&root.join(".github/PULL_REQUEST_TEMPLATE.md")),
        ".github/PULL_REQUEST_TEMPLATE.md must NOT appear — .github is a dot-directory \
         and must be unconditionally skipped regardless of any .gitignore whitelist \
         pattern (BC-2.01.004 invariant 1 / EC-003 / defect F-A1). \
         Got scan set: {:?}",
        result
    );
}

// ─── Regression lock: BC-2.01.004 postcondition 1 / invariant 1 (defect F-P2-01, fixed) ─
//
// BC-2.01.004 postcondition 1 / invariant 1 / BC-2.01.001 invariant 1:
//   "ALL dot-directories are unconditionally excluded. No flag overrides this."
//
// HISTORICAL DEFECT F-P2-01 (fixed in scanner.rs): the `filter_entry` dot-directory
// guard was UTF-8-only:
//   `e.file_name().to_str().is_some_and(|n| n.starts_with('.'))`
// For a directory whose name is not valid UTF-8, `to_str()` returned `None`,
// `is_some_and` evaluated to `false`, `is_dot_dir` was `false`, and the directory
// was ACCEPTED — failing OPEN on exactly the input class it was added to protect.
//
// FIX APPLIED (scanner.rs): the guard now uses byte-wise comparison via
// `is_dot_dir_name` (scanner.rs:103-104), which calls
// `name.as_encoded_bytes().starts_with(b".")` — matching the `ignore` crate's
// own byte-wise check in `pathutil.rs`.  Any dot-prefixed name, including
// non-UTF-8 names, is correctly identified and rejected.
// `collect_md_files` also applies the same guard as a post-filter backstop.
// This test is the GREEN regression lock that must stay green.
//
// FIXTURE DESIGN (two-path, platform-adaptive):
//
//   Linux path (ext4/xfs/btrfs accept arbitrary byte sequences in filenames):
//   - Creates a dot-prefixed directory with INVALID UTF-8 name b".caf\xe9".
//   - Places an .md file inside it (must NOT be discovered).
//   - A .gitignore with ".*\n!.*\n" defeats hidden(true), leaving filter_entry
//     and the collect_md_files post-filter as the defences.
//     require_git(false) honours .gitignore without git init.
//   - Asserts the file inside does NOT appear in the scan set.
//
//   macOS path (APFS/HFS+ enforces UTF-8; mkdir returns EILSEQ for non-UTF-8 bytes;
//   the end-to-end path is not reachable on this OS):
//   - Falls back to asserting the production guard helper directly:
//     `scanner::is_dot_dir_name(non_utf8_name)` must return true (byte-wise check).
//   - Reverting `is_dot_dir_name` to the UTF-8-only form would make this fail.
//
// Traceability: BC-2.01.004 postcondition 1, invariant 1 / BC-2.01.001 invariant 1
//               / F-P2-01

#[cfg(unix)]
#[test]
fn test_BC_2_01_004_inv1_dot_dir_skip_handles_non_utf8_dir_name() {
    use std::ffi::OsStr;
    use std::os::unix::ffi::OsStrExt;

    let dir = TempDir::new().expect("tempdir");
    let root = dir.path();

    // Dot-prefixed directory with a non-UTF-8 name.
    // 0xe9 alone is an invalid UTF-8 lead byte (starts a 3-byte sequence with no
    // continuation bytes), so to_str() returns None for this OsStr.
    let non_utf8_name: &OsStr = OsStr::from_bytes(b".caf\xe9");
    let dot_dir = root.join(non_utf8_name);

    // Defeat hidden(true) via gitignore whitelist, leaving filter_entry as sole
    // defense.  ".*" excludes all dot-prefixed entries; "!.*" negates and
    // re-enables them.  require_git(false) in build_walk honours .gitignore
    // without a git init.
    fs::write(root.join(".gitignore"), ".*\n!.*\n")
        .expect("write .gitignore that defeats hidden(true)");

    // Normal .md file — positive gate (F-04 vacuous-pass prevention).
    create_file(root, "mdlc_fixture_README.md");

    // Attempt to create the non-UTF-8 directory.
    // Linux: succeeds (ext4/xfs accept arbitrary byte sequences).
    // macOS (APFS/HFS+): fails with EILSEQ — the OS enforces valid UTF-8 for
    //   all VFS operations.  The end-to-end path is unavailable on macOS.
    match fs::create_dir_all(&dot_dir) {
        Ok(()) => {
            // ── Linux path: full end-to-end test ─────────────────────────────
            fs::write(dot_dir.join("secret.md"), "# secret\n")
                .expect("write secret.md inside non-UTF-8 dot-dir");

            let result = scanner::collect_md_files(root);

            // Positive gate (F-04).
            assert!(
                result.contains(&root.join("mdlc_fixture_README.md")),
                "mdlc_fixture_README.md must be in the scan set (F-04 positive gate)"
            );

            // BC-2.01.004 postcondition 1 / invariant 1 — GREEN regression lock.
            // Locks fix for defect F-P2-01 (commit 7bea0b2): `is_dot_dir_name` uses
            // `as_encoded_bytes().starts_with(b".")` — byte-wise, UTF-8-agnostic —
            // so a non-UTF-8 dot-prefixed directory name is correctly rejected.
            assert!(
                !result.iter().any(|p| p.starts_with(&dot_dir)),
                "no file under the non-UTF-8 dot-directory {:?} must appear in the \
                 scan set (BC-2.01.004 postcondition 1 / invariant 1 / F-P2-01 regression \
                 lock): is_dot_dir_name must use byte-wise as_encoded_bytes().starts_with(b\".\") \
                 so non-UTF-8 dot-dir names are correctly rejected — a failure here means the \
                 F-P2-01 fix was reverted. Got scan set: {:?}",
                dot_dir,
                result
            );
        }
        Err(_) => {
            // ── macOS path: direct guard assertion via production helper ──────
            // macOS APFS/HFS+ cannot create non-UTF-8 dirs (EILSEQ); the
            // end-to-end path is unavailable.  Assert the production guard logic
            // directly via the public helper so this branch exercises the real
            // implementation rather than an inline copy.
            // BC-2.01.004 invariant 1 requires ANY dot-prefixed name — including
            // non-UTF-8 names — to be recognised as a dot-directory.
            //
            // Calls the real production guard (not a replicated copy):
            let guard_result = scanner::is_dot_dir_name(non_utf8_name);

            // Discriminates F-P2-01: if is_dot_dir_name is reverted to
            // `to_str().is_some_and(|n| n.starts_with('.'))`, guard_result
            // returns false for non-UTF-8 names and this assertion FAILS.
            assert!(
                guard_result,
                "F-P2-01: scanner::is_dot_dir_name({non_utf8_name:?}) returned \
                 {guard_result}. Expected true — dot-dirs must be rejected regardless \
                 of name encoding (BC-2.01.004 invariant 1 / F-P2-01). \
                 macOS APFS cannot create non-UTF-8 dirs; guard logic asserted \
                 directly via the production helper."
            );
        }
    }
}

// ─── build_walk direct: filter_entry replaceability + collect_md_files backstop ─
//
// BACKGROUND (ignore 0.4.33 walk.rs:1043):
//   `WalkBuilder::filter_entry` stores ONE predicate.  A subsequent call on the
//   returned builder REPLACES the first, silently removing the dot-dir guard
//   registered inside `build_walk`.
//
// THIS TEST DOCUMENTS TWO THINGS:
//   (1) A raw `build_walk` consumer who calls `.filter_entry(|_| true)` LOSES the
//       subtree-pruning dot-dir defence — dot-dir content LEAKS when a .gitignore
//       negation pattern defeats hidden(true).
//   (2) `collect_md_files`, which builds its own walker and post-filters every path
//       via `is_dot_dir_name`, still excludes dot-dir content REGARDLESS of any
//       builder mutation — the backstop is structural.
//
// Practical risk: S-1.02 implements `--ignore <glob>` via `.filter_entry` on a
//   builder derived from `build_walk`.  The idiomatic approach replaces the
//   predicate, silently removing the dot-dir guard.  The post-filter backstop in
//   `collect_md_files` is what keeps the invariant structural for all callers of
//   that function.
//
// Traceability: BC-2.01.004 invariant 1 / ignore 0.4.33 walk.rs:1043
//               / collect_md_files post-filter backstop

#[test]
fn test_build_walk_filter_entry_replaceable_but_collect_md_files_backstop_holds() {
    let dir = TempDir::new().expect("tempdir");
    let root = dir.path();

    // .gitignore: ".*" excludes all dot-entries; "!.github" re-enables .github/
    // via negation.  With require_git(false) active in build_walk, this is
    // honoured without a git init, defeating hidden(true) for .github/.
    fs::write(root.join(".gitignore"), ".*\n!.github\n")
        .expect("write .gitignore with negation pattern that defeats hidden(true)");

    create_file(root, ".github/PULL_REQUEST_TEMPLATE.md"); // dot-dir — must be excluded
    create_file(root, "mdlc_fixture_visible.md"); // normal file — must be included

    // ── Part 1: raw build_walk consumer who replaces filter_entry ────────────
    // Calling filter_entry again REPLACES the predicate registered by build_walk
    // (ignore 0.4.33 walk.rs:1043).  Once replaced, the .gitignore negation
    // pattern defeats hidden(true) and .github/ is traversed — dot-dir leaks.
    let mut builder = scanner::build_walk(root);
    // This replaces the dot-dir guard predicate registered inside build_walk.
    builder.filter_entry(|_| true);
    let leaked: Vec<PathBuf> = builder
        .build()
        .filter_map(|r| r.ok())
        .filter(|e| e.file_type().is_some_and(|ft| ft.is_file()))
        .filter(|e| scanner::is_md_extension(e.path()))
        .map(|e| e.path().to_path_buf())
        .collect();

    // The replacing predicate removes the dot-dir guard: .github/ is traversed.
    // This assertion PROVES the vulnerability exists.  If it ever starts failing
    // (the leak stops), ignore's filter_entry semantics may have changed from
    // single-replace to chain — update the build_walk doc comment if so
    // (cite ignore 0.4.33 walk.rs:1043).
    let leaked_dot_dir_content = leaked.iter().any(|p| {
        p.strip_prefix(root)
            .unwrap_or(p.as_path())
            .components()
            .any(|c| c.as_os_str().as_encoded_bytes().starts_with(b"."))
    });
    assert!(
        leaked_dot_dir_content,
        "build_walk with a replacing filter_entry(|_| true) must LEAK dot-dir \
         content when a .gitignore negation defeats hidden(true); if this fails, \
         ignore's filter_entry semantics may have changed from replace to compose — \
         update the build_walk doc (cite ignore 0.4.33 walk.rs:1043). \
         leaked set: {leaked:?}"
    );

    // ── Part 2: collect_md_files backstop holds ───────────────────────────────
    // collect_md_files builds its OWN walker and post-filters every path through
    // is_dot_dir_name.  The dot-dir exclusion is structural here — it does not
    // depend on filter_entry surviving caller mutation.
    let result = scanner::collect_md_files(root);

    assert!(
        result.contains(&root.join("mdlc_fixture_visible.md")),
        "mdlc_fixture_visible.md must be in the scan set (positive gate)"
    );
    assert!(
        !result.iter().any(|p| {
            p.strip_prefix(root)
                .unwrap_or(p.as_path())
                .components()
                .any(|c| c.as_os_str().as_encoded_bytes().starts_with(b"."))
        }),
        "collect_md_files must exclude all dot-dir content regardless of any \
         builder mutation — the post-filter backstop is structural for all callers \
         (BC-2.01.004 invariant 1 / ignore 0.4.33 walk.rs:1043)"
    );
}

// ─── Regression lock: BC-2.01.004 invariant 1 — builder-level filter_entry guard ─
//
// SOLE REGRESSION LOCK for the `filter_entry` dot-directory guard registered
// inside `build_walk`.  The `collect_md_files` post-filter (structural backstop)
// masks the builder guard for all callers of that function — deleting the entire
// `builder.filter_entry(...)` statement from `build_walk` leaves every
// `collect_md_files`-based test green.  Only a test that calls `build_walk`
// directly WITHOUT replacing the predicate can kill the guard-deletion mutant.
//
// WHY collect_md_files CANNOT SUBSTITUTE:
//   Since commit 70f1f19, `collect_md_files` applies an independent structural
//   post-filter (`is_dot_dir_name` on every relative path component) that rejects
//   dot-dir content even when the builder guard is absent.  The S-1.02
//   `--ignore <glob>` consumer (BC-2.11.001) calls `build_walk` directly and
//   registers its own `filter_entry` predicate on the returned builder.  If the
//   builder-level guard is absent, a direct consumer who does NOT also apply the
//   `collect_md_files` post-filter re-arms the original F-A1 defect with no
//   regression signal.
//
// FIXTURE DESIGN (defeats hidden(true) so the test genuinely exercises filter_entry):
//   `.gitignore` with `.*` + `!.github` — the exact two-line pattern confirmed to
//   defeat `hidden(true)` in `ignore` 0.4.33 (the `.gitignore` negation re-enables
//   .github/ traversal; `require_git(false)` in `build_walk` honours this without
//   a git init).  With `hidden(true)` defeated, the only remaining defence against
//   traversal into `.github/` at the builder level is the `filter_entry` predicate.
//   `mdlc_fixture_` prefix on the visible file and the `.github/` sub-file follows
//   the C-E4 ancestor-ignore hermeticity convention.
//
// NON-VACUITY PROOF (mandatory for merging this test):
//   Temporarily delete `builder.filter_entry(...)` from scanner.rs and re-run —
//   this test MUST fail.  All `collect_md_files`-based tests will remain green
//   (the post-filter masks the deletion), confirming this test is the sole
//   kill-signal for the builder-level guard-deletion mutant.  Restore scanner.rs
//   with `git checkout -- crates/mdlinkcheck/src/scanner.rs` and verify the suite
//   is green again.
//
// Traceability: BC-2.01.004 invariant 1 / D-011 / EC-003 / F-A1 regression
//               / S-1.02 build_walk direct consumer (BC-2.11.001)

#[test]
fn test_BC_2_01_004_inv1_build_walk_filter_entry_guard_is_active() {
    let dir = TempDir::new().expect("tempdir");
    let root = dir.path();

    // Defeat hidden(true) via the exact two-line .gitignore negation pattern:
    // ".*" excludes all dot-entries; "!.github" re-enables .github/ traversal.
    // require_git(false) in build_walk honours this without a git init.
    // With hidden(true) defeated, filter_entry is the sole remaining defence
    // at the builder level against traversal into .github/.
    fs::write(root.join(".gitignore"), ".*\n!.github\n")
        .expect("write .gitignore that defeats hidden(true)");

    // Dot-directory content: must NOT appear in the walk output.
    // mdlc_fixture_ prefix follows the C-E4 ancestor-ignore hermeticity convention.
    create_file(root, ".github/PULL_REQUEST_TEMPLATE.md");

    // Visible file: MUST appear (F-04 positive gate — prevents vacuous pass on
    // an empty result set).
    create_file(root, "mdlc_fixture_visible.md");

    // Call build_walk directly — do NOT replace filter_entry on the returned builder.
    // The companion test (test_build_walk_filter_entry_replaceable_but_collect_md_files_backstop_holds)
    // documents what happens when filter_entry IS replaced; this test exercises the
    // as-shipped predicate.
    let builder = scanner::build_walk(root);

    let walked: Vec<PathBuf> = builder
        .build()
        .filter_map(|r| r.ok())
        .filter(|e| e.file_type().is_some_and(|ft| ft.is_file()))
        .filter(|e| scanner::is_md_extension(e.path()))
        .map(|e| e.path().to_path_buf())
        .collect();

    // F-04 positive gate: mdlc_fixture_visible.md MUST be in the walk output.
    // If the walk returns an empty Vec, the negative assertion below passes
    // vacuously and the test discharges nothing.
    assert!(
        walked.contains(&root.join("mdlc_fixture_visible.md")),
        "mdlc_fixture_visible.md must be discovered by build_walk \
         (F-04 vacuous-pass prevention)"
    );

    // BC-2.01.004 invariant 1 — builder-level guard assertion.
    // No yielded path may contain a dot-prefixed component relative to root.
    // Uses byte-wise comparison (as_encoded_bytes().starts_with(b".")) matching
    // the production is_dot_dir_name implementation — NOT to_str() which fails
    // open on non-UTF-8 names (defect F-P2-01, fixed at commit 7bea0b2).
    //
    // MUTATION TARGET: deleting `builder.filter_entry(...)` from build_walk causes
    // this assertion to FAIL because .github/ is traversed (hidden(true) is defeated
    // by the .gitignore negation above) and PULL_REQUEST_TEMPLATE.md appears in the
    // walked set.
    assert!(
        !walked.iter().any(|p| {
            p.strip_prefix(root)
                .unwrap_or(p.as_path())
                .components()
                .any(|c| c.as_os_str().as_encoded_bytes().starts_with(b"."))
        }),
        "build_walk's filter_entry guard must prevent dot-dir content from appearing \
         in the walk output (BC-2.01.004 invariant 1 / D-011 / EC-003): \
         .github/PULL_REQUEST_TEMPLATE.md must be blocked by the builder-level predicate. \
         FAILURE means filter_entry was removed from build_walk — this is the sole \
         regression lock for the builder-level guard (collect_md_files post-filter \
         masks the deletion for all collect_md_files-based tests). walked: {walked:?}"
    );
}

// ─── Regression lock: parents(true) ancestor-ascent semantics (D-259, operator intent) ──
//
// OPERATOR RULING D-259: ancestor-directory ignore files ARE honoured when the scan
// root is a subdirectory of a directory containing an ignore file, even with no git
// repository present anywhere.  This is intended behaviour matching git semantics
// for scanning a subdirectory of a project.
//
// WHY THIS LOCK IS NECESSARY:
//   `parents(true)` is the `ignore` 0.4.33 default.  Before it was set explicitly in
//   `build_walk` (commit 47e11b0), cargo-mutants could not generate a kill-able mutant
//   for it and no kill-rate metric could ever have covered it — an implicit default
//   produces no mutant (lesson L-88).  Setting it explicitly enables a `parents(false)`
//   mutant whose kill is this test.
//
// USER-VISIBLE CONSEQUENCE (accepted and disclosed per D-259):
//   A user with a `$HOME/.gitignore` will have those patterns apply to any scan
//   beneath it.  `collect_md_files` has no diagnostic channel to report such silent
//   exclusions (deferred finding F-A3).
//
// FIXTURE DESIGN:
//   - No `git init` anywhere — proves the behaviour is not git-repo-gated.
//   - `mdlc_fixture_outer/` and `mdlc_fixture_outer/mdlc_fixture_inner/` are
//     sub-directories inside the tempdir; the scan root is `mdlc_fixture_inner/`
//     and the ignore file lives in `mdlc_fixture_outer/` (its parent), ensuring
//     the ignore file is genuinely above and outside the scan root.  The tempdir
//     root itself is not the scan root, so an ancestor ignore file above the
//     tempdir cannot satisfy the assertion for an unrelated reason.
//   - `mdlc_probe.md` matches the ancestor pattern and MUST be excluded.
//   - `mdlc_keep.md` does NOT match and MUST be included (F-04 positive gate).
//
// Traceability: BC-2.01.003 postcondition 1 / parents(true) / D-259 / L-88

#[test]
fn test_BC_2_01_003_post1_ancestor_gitignore_honoured_parents_true() {
    // No git init — behaviour must not be git-repo-gated.
    let dir = TempDir::new().expect("tempdir");
    let root = dir.path();

    // Build mdlc_fixture_outer/ and mdlc_fixture_outer/mdlc_fixture_inner/ inside
    // the tempdir.  Scan root will be mdlc_fixture_inner/.
    let outer = root.join("mdlc_fixture_outer");
    let inner = outer.join("mdlc_fixture_inner");
    fs::create_dir_all(&inner).expect("create mdlc_fixture_outer/mdlc_fixture_inner");

    // Ignore file lives in mdlc_fixture_outer/ — ABOVE the scan root (mdlc_fixture_inner/).
    // Pattern: `mdlc_probe.md` inside the scan root must be excluded via ancestor ascent.
    fs::write(outer.join(".gitignore"), "mdlc_probe.md\n")
        .expect("write ancestor .gitignore in mdlc_fixture_outer/");

    // File matching the ancestor ignore pattern — MUST be excluded.
    create_file(root, "mdlc_fixture_outer/mdlc_fixture_inner/mdlc_probe.md");

    // Sibling file that does NOT match — MUST be included (F-04 positive gate).
    // Without this, an empty result passes the negative assertion vacuously.
    create_file(root, "mdlc_fixture_outer/mdlc_fixture_inner/mdlc_keep.md");

    // Scan mdlc_fixture_inner/ — the ignore file is in its parent (mdlc_fixture_outer/),
    // which is outside the scan root.
    let result = scanner::collect_md_files(&inner);

    // F-04 positive gate: mdlc_keep.md MUST be in the scan set.
    assert!(
        result.contains(&inner.join("mdlc_keep.md")),
        "mdlc_keep.md must be in the scan set (F-04 vacuous-pass prevention / D-259 \
         ancestor-ascent positive gate)"
    );

    // BC-2.01.003 postcondition 1 / D-259: the ancestor-ignored file must be excluded.
    // MUTATION TARGET: changing `parents(true)` to `parents(false)` in build_walk
    // causes this assertion to FAIL because the ancestor .gitignore in
    // mdlc_fixture_outer/ is no longer consulted and mdlc_probe.md appears in the result.
    assert!(
        !result.contains(&inner.join("mdlc_probe.md")),
        "mdlc_probe.md must NOT be in the scan set — it is excluded by the ancestor \
         .gitignore in mdlc_fixture_outer/ (BC-2.01.003 postcondition 1 / D-259 \
         operator-ruled intended behaviour). FAILURE here means parents(true) was \
         removed from build_walk — this test is the regression lock for ancestor-ascent \
         semantics (lesson L-88). result: {result:?}"
    );
}
