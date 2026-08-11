//! Integration test for BC-2.01.003 postcondition 3: global gitignore respected.
//!
//! This test lives in its own file so that it compiles to a SEPARATE test binary.
//! That isolation is the soundness basis for the one `std::env::set_var` call below:
//! there are no other libtest threads in this binary, so no concurrent thread can be
//! reading the process environment while we mutate it.
//!
//! Traceability:
//!   BC-2.01.003 postcondition 3 — global gitignore respected when available
//!   BC-2.01.003 postcondition 2 — nested .gitignore inside a subdirectory respected
//!
//! Mutation target: `git_global(true)` → `git_global(false)` in `build_walk`.

#![allow(non_snake_case)]

use std::fs;
use std::path::{Path, PathBuf};

use tempfile::TempDir;

use mdlinkcheck::scanner;

// ─── Helpers ─────────────────────────────────────────────────────────────────

fn create_file(root: &Path, rel: &str) {
    let full = root.join(rel);
    if let Some(parent) = full.parent() {
        fs::create_dir_all(parent)
            .unwrap_or_else(|e| panic!("create_dir_all for '{}': {}", rel, e));
    }
    fs::write(&full, "# Placeholder\n").unwrap_or_else(|e| panic!("write '{}': {}", rel, e));
}

fn git_init(dir: &Path, hermetic_config: &Path) {
    let status = std::process::Command::new("git")
        .args(["-C", dir.to_str().expect("UTF-8 path"), "init", "-q"])
        .env("GIT_CONFIG_NOSYSTEM", "1")
        .env("GIT_CONFIG_GLOBAL", hermetic_config)
        .status()
        .expect("`git` must be available on PATH for gitignore fixture tests");
    assert!(status.success(), "git init failed in {:?}", dir);
}

/// RAII guard: saves an env variable's current value on construction and
/// restores it (or removes it if it was absent) when dropped.
///
/// Used to restore `GIT_CONFIG_GLOBAL` / `GIT_CONFIG_NOSYSTEM` on drop so
/// that the prior state is always restored — even when the test panics.
///
/// SAFETY invariant: callers must ensure no other thread reads the environment
/// concurrently.  This file's single test is the only test in its binary, so
/// no concurrent libtest threads exist.
struct EnvRestoreGuard {
    key: &'static str,
    original: Option<std::ffi::OsString>,
}

impl EnvRestoreGuard {
    fn set(key: &'static str, new_val: impl AsRef<std::ffi::OsStr>) -> Self {
        let original = std::env::var_os(key);
        // SAFETY: This binary contains exactly one test (`test_BC_2_01_003_post3_global_gitignore_respected_when_available`).
        // Rust's libtest spawns a thread per test; with only one test there is only
        // one thread — the test thread itself.  No other thread can be concurrently
        // reading the process environment, so the data race that makes `set_var`
        // unsafe on multi-threaded programs cannot occur here.
        unsafe { std::env::set_var(key, new_val) };
        EnvRestoreGuard { key, original }
    }
}

impl Drop for EnvRestoreGuard {
    fn drop(&mut self) {
        // SAFETY: same single-thread guarantee as in `set`.
        unsafe {
            match &self.original {
                Some(v) => std::env::set_var(self.key, v),
                None => std::env::remove_var(self.key),
            }
        }
    }
}

// ─── BC-2.01.003 postcondition 3: global gitignore respected when available ───
//
// Mutation target: `git_global(true)` → `git_global(false)` in `build_walk`.
//
// WHY THIS TEST IS NEEDED:
//   All other git-fixture tests (AC-004, VP-016 Form A in scanner_discovery_tests.rs)
//   are written with the `mdlc_fixture_` prefix and no exact-count assertion so
//   that the host's process-level global gitignore cannot flip them.  That approach
//   is correct, but it creates a blind spot: if `git_global(true)` is mutated to
//   `git_global(false)` the behaviour is now identical (no global ignore in either
//   case) and the mutant survives.
//
// FIX: this test writes a hermetic gitconfig with a real `core.excludesFile`
//   entry pointing at a separate file inside the same TempDir.  That file lists
//   `globally-ignored.md` as a pattern.  If `git_global(true)` is in effect, the
//   `ignore` crate reads the config, resolves the `core.excludesFile` path, and
//   excludes the matching file.  If `git_global(false)` is in effect, the global
//   gitignore is never consulted and `globally-ignored.md` appears in the scan
//   set — killing the mutant via the negative assertion below.
//
// NESTED-.GITIGNORE SUB-CASE (BC-2.01.003 postcondition 2):
//   A `.gitignore` inside `subdir/` excludes `subdir/nested-excluded.md` but
//   not files outside that subdirectory.  This is cheap to add in the same
//   git-init'd fixture and closes the postcondition 2 coverage gap.
//
// Process-environment policy: `GIT_CONFIG_GLOBAL` and `GIT_CONFIG_NOSYSTEM` are
//   set in the process environment so that `collect_md_files` (which runs in-process
//   and reads the env to locate the global gitignore) uses our hermetic config.
//   This is sound here because this binary contains only this one test — see the
//   `EnvRestoreGuard::set` SAFETY comment above.  `EnvRestoreGuard` restores the
//   original values on drop (including panics).
//
// Traceability: BC-2.01.003 postcondition 3 (global gitignore respected)
//              BC-2.01.003 postcondition 2 (nested .gitignore respected)

#[test]
fn test_BC_2_01_003_post3_global_gitignore_respected_when_available() {
    let dir = TempDir::new().expect("tempdir");
    let root = dir.path();

    // Create the global gitignore file with a distinctive pattern.
    let global_gitignore = root.join("global.gitignore");
    fs::write(&global_gitignore, "globally-ignored.md\n").expect("write global.gitignore");

    // Write a hermetic gitconfig whose `core.excludesFile` points at the global
    // gitignore above.  Unlike the empty configs used in AC-004 / VP-016, this
    // config provides REAL global-gitignore coverage while remaining
    // machine-independent (the path is inside the same TempDir).
    let hermetic_cfg = root.join(".hermetic_gitconfig");
    fs::write(
        &hermetic_cfg,
        format!(
            "[core]\n\texcludesFile = {}\n",
            global_gitignore.to_str().expect("UTF-8 path")
        ),
    )
    .expect("write hermetic gitconfig with core.excludesFile");

    // Set GIT_CONFIG_GLOBAL in the process env so the `ignore` crate (which runs
    // in collect_md_files) reads our hermetic config.  EnvRestoreGuard restores
    // the original values on drop, even if the test panics.
    let _guard_global = EnvRestoreGuard::set("GIT_CONFIG_GLOBAL", &hermetic_cfg);
    let _guard_nosys = EnvRestoreGuard::set("GIT_CONFIG_NOSYSTEM", "1");

    // git init is required: `ignore` crate's `require_git=true` default only
    // honours `.gitignore` files (and git_global) inside a real git repository.
    git_init(root, &hermetic_cfg);

    // File that must be excluded via the global gitignore (core.excludesFile):
    create_file(root, "globally-ignored.md");

    // Normal file that must be included (positive gate — F-04 vacuous-pass
    // prevention: an empty result passes every negative assertion vacuously).
    create_file(root, "normal.md");

    // ── Nested-.gitignore sub-case (BC-2.01.003 postcondition 2) ─────────────
    // A .gitignore inside subdir/ excludes subdir/nested-excluded.md but must
    // NOT affect files outside that subdirectory.
    fs::create_dir_all(root.join("subdir")).expect("create subdir");
    fs::write(
        root.join("subdir").join(".gitignore"),
        "nested-excluded.md\n",
    )
    .expect("write subdir/.gitignore");
    create_file(root, "subdir/nested-excluded.md"); // must be excluded
    create_file(root, "subdir/nested-included.md"); // must be included

    let result: Vec<PathBuf> = scanner::collect_md_files(root);

    // ── Positive gates (F-04 vacuous-pass prevention) ─────────────────────────
    assert!(
        result.contains(&root.join("normal.md")),
        "normal.md must be in the scan set \
         (positive gate, BC-2.01.003 postcondition 3)"
    );
    assert!(
        result.contains(&root.join("subdir/nested-included.md")),
        "subdir/nested-included.md must be in the scan set \
         (nested-.gitignore positive gate, BC-2.01.003 postcondition 2)"
    );

    // ── Negative assertion — MUTATION TARGET: git_global(true) → git_global(false)
    // Under git_global(false) the `core.excludesFile` is NOT read; the pattern
    // `globally-ignored.md` is never loaded, so the file appears in the scan
    // set and this assertion FAILS — killing the mutant.
    assert!(
        !result.contains(&root.join("globally-ignored.md")),
        "globally-ignored.md must be excluded via the global gitignore \
         (core.excludesFile in hermetic gitconfig) — \
         BC-2.01.003 postcondition 3. \
         If git_global(false) is used, this file incorrectly appears in the scan set."
    );

    // ── Negative assertion — nested .gitignore (BC-2.01.003 postcondition 2) ──
    assert!(
        !result.contains(&root.join("subdir/nested-excluded.md")),
        "subdir/nested-excluded.md must be excluded by subdir/.gitignore \
         (BC-2.01.003 postcondition 2 — nested .gitignore files are respected)"
    );
}
