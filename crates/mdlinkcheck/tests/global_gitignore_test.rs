//! Integration test for BC-2.01.003 postcondition 3: global gitignore respected.
//!
//! This test uses `harness = false` (see `[[test]]` stanza in Cargo.toml) so that
//! it compiles to a binary with an explicit `fn main()` entry point.  That makes
//! the `unsafe std::env::set_var` call below genuinely sound: `fn main()` runs on
//! the main thread before any other thread is spawned, so no concurrent environment
//! reads are possible.
//!
//! # Why `harness = false`
//!
//! The prior approach used a `static INVOCATION_COUNT` guard and relied on libtest's
//! observed `join()` behaviour to argue that the main thread was blocked.  That
//! argument was fragile under `cargo nextest`, which executes each test in its own
//! process — so a future second `#[test]` in the file would always see a zero counter
//! and the assertion would never fire.  `harness = false` makes the single-entry
//! guarantee structural: there is only one `fn main()`, so adding a second test
//! function is structurally impossible without refactoring the entry point.
//!
//! # SAFETY basis for `set_var`
//!
//! With `harness = false` and an explicit `fn main()`, `set_var` is called on the
//! main thread before any other thread is created.  There are no concurrent reads of
//! the process environment.
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
/// concurrently.  Because this binary uses `harness = false` with an explicit
/// `fn main()`, `set_var` is called before any other thread is spawned,
/// so no concurrent environment reads are possible.
struct EnvRestoreGuard {
    key: &'static str,
    original: Option<std::ffi::OsString>,
}

impl EnvRestoreGuard {
    fn set(key: &'static str, new_val: impl AsRef<std::ffi::OsStr>) -> Self {
        let original = std::env::var_os(key);
        // SAFETY: This binary uses `harness = false` (see Cargo.toml [[test]] stanza).
        // `fn main()` is the sole entry point and runs on the main thread before any
        // other thread is created.  Therefore no concurrent environment reads are
        // possible when `set_var` is called.  The `harness = false` convention makes
        // adding a second test structurally impossible without refactoring `fn main()`,
        // ensuring this invariant cannot be accidentally violated.
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
//   A `.gitignore` inside `mdlc_fixture_subdir/` excludes
//   `mdlc_fixture_subdir/nested-excluded.md` but not files outside that
//   subdirectory.  This is cheap to add in the same git-init'd fixture and
//   closes the postcondition 2 coverage gap.
//
// Process-environment policy: `GIT_CONFIG_GLOBAL` and `GIT_CONFIG_NOSYSTEM` are
//   set in the process environment so that `collect_md_files` (which runs in-process
//   and reads the env to locate the global gitignore) uses our hermetic config.
//   This is sound here because this binary runs under `harness = false` with
//   `fn main()` as the sole entry point — see SAFETY comment on `EnvRestoreGuard`.
//   `EnvRestoreGuard` restores the original values on drop (including panics).
//
// Traceability: BC-2.01.003 postcondition 3 (global gitignore respected)
//              BC-2.01.003 postcondition 2 (nested .gitignore respected)

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

    // git_init is retained here for belt-and-suspenders assurance.
    // Under `require_git(false)` — set in `build_walk` — `.gitignore` and global
    // gitignore (core.excludesFile) are honoured even outside a git repository
    // (`ignore-0.4.33/src/dir.rs:560`: `let any_git = !require_git || ...`).
    // A real git repository is therefore NOT required for these to work with our
    // scanner; git_init is kept here for belt-and-suspenders correctness.
    git_init(root, &hermetic_cfg);

    // File that must be excluded via the global gitignore (core.excludesFile):
    create_file(root, "globally-ignored.md");

    // Normal file that must be included (positive gate — F-04 vacuous-pass
    // prevention: an empty result passes every negative assertion vacuously).
    create_file(root, "normal.md");

    // ── Nested-.gitignore sub-case (BC-2.01.003 postcondition 2) ─────────────
    // A .gitignore inside mdlc_fixture_subdir/ excludes
    // mdlc_fixture_subdir/nested-excluded.md but must NOT affect files outside
    // that subdirectory.  Directory name is mdlc_fixture_-prefixed for
    // hermeticity (N-2 fix: ancestor ignore files cannot match the dir).
    fs::create_dir_all(root.join("mdlc_fixture_subdir")).expect("create mdlc_fixture_subdir");
    fs::write(
        root.join("mdlc_fixture_subdir").join(".gitignore"),
        "nested-excluded.md\n",
    )
    .expect("write mdlc_fixture_subdir/.gitignore");
    create_file(root, "mdlc_fixture_subdir/nested-excluded.md"); // must be excluded
    create_file(root, "mdlc_fixture_subdir/nested-included.md"); // must be included

    let result: Vec<PathBuf> = scanner::collect_md_files(root);

    // ── Positive gates (F-04 vacuous-pass prevention) ─────────────────────────
    assert!(
        result.contains(&root.join("normal.md")),
        "normal.md must be in the scan set \
         (positive gate, BC-2.01.003 postcondition 3)"
    );
    assert!(
        result.contains(&root.join("mdlc_fixture_subdir/nested-included.md")),
        "mdlc_fixture_subdir/nested-included.md must be in the scan set \
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
        !result.contains(&root.join("mdlc_fixture_subdir/nested-excluded.md")),
        "mdlc_fixture_subdir/nested-excluded.md must be excluded by \
         mdlc_fixture_subdir/.gitignore \
         (BC-2.01.003 postcondition 2 — nested .gitignore files are respected)"
    );
}

fn main() {
    let args: Vec<String> = std::env::args().collect();

    const TEST_NAME: &str = "test_BC_2_01_003_post3_global_gitignore_respected_when_available";

    // --list / --list --ignored: enumerate tests for nextest/cargo test discovery.
    // Respond with the canonical libtest terse line for the non-ignored pass;
    // emit nothing for the --ignored-only pass (this test has no #[ignore]).
    //
    // nextest calls us TWICE during listing:
    //   1. `--list [--format terse]`          → list non-ignored tests
    //   2. `--list --ignored [--format terse]` → list only `#[ignore]`-marked tests
    // Our test has no `#[ignore]` attribute, so it must appear in call (1) only.
    // If we also output it for call (2), nextest marks the test as `ignored: true`
    // and excludes it from the default run — a false green.
    if args.iter().any(|a| a == "--list") {
        let listing_ignored_only = args.iter().any(|a| a == "--ignored");
        if !listing_ignored_only {
            println!("{}: test", TEST_NAME);
        }
        std::process::exit(0);
    }

    // Parse remaining arguments fail-closed.
    //
    // PROBLEM WITH THE PREVIOUS PARSER (latent false-green shape):
    //   The old parser collected every token that did NOT start with '-' as a name
    //   filter.  Value-taking flags like `--test-threads 4`, `--format terse`,
    //   `--color never`, and `--skip some_other_test` caused their VALUE tokens
    //   ("4", "terse", "never", "some_other_test") to be treated as name filters.
    //   A non-matching filter triggered exit(0) without running the test body —
    //   a false green identical in shape to the P10-01/P12-01 incident.
    //   `--skip some_other_test` was semantically inverted: skipping a DIFFERENT
    //   test should make this one run, but the old parser silently skipped it.
    //
    // NEW PARSER (fail-closed):
    //   Known boolean flags (consume the token, no value):
    //     --exact, --nocapture, --show-output, --include-ignored, --ignored,
    //     --quiet, -q
    //   Known value-taking flags (consume flag + next token, or --flag=value):
    //     --skip, --test-threads, --format, --color, --logfile, --shuffle-seed
    //   Genuine positionals (no '-' prefix): name-filter arguments.
    //   Unrecognized '-'-prefixed flags: print to stderr and exit non-zero.
    //
    //   --skip semantics: exit 0 (skip this test) only when the --skip value
    //     MATCHES our test name.  A non-matching --skip lets the test run.
    //   Inclusion filters: run only when a positional filter MATCHES our test name.

    const VALUE_FLAGS: &[&str] = &[
        "--skip",
        "--test-threads",
        "--format",
        "--color",
        "--logfile",
        "--shuffle-seed",
    ];
    const BOOL_FLAGS: &[&str] = &[
        "--nocapture",
        "--show-output",
        "--include-ignored",
        "--ignored",
        "--quiet",
        "-q",
    ];

    let mut exact = false;
    let mut filters: Vec<String> = Vec::new();
    let mut skip_patterns: Vec<String> = Vec::new();

    let mut i = 1usize;
    while i < args.len() {
        let arg = args[i].as_str();

        if arg == "--exact" {
            exact = true;
            i += 1;
        } else if BOOL_FLAGS.contains(&arg) {
            // Recognized boolean flag; consume without value.
            i += 1;
        } else if VALUE_FLAGS.contains(&arg) {
            // Recognized value-taking flag (--flag value form): consume value.
            let flag = arg.to_owned();
            i += 1;
            if i >= args.len() {
                eprintln!("error: flag '{}' requires an argument", flag);
                std::process::exit(1);
            }
            let value = args[i].clone();
            if flag == "--skip" {
                skip_patterns.push(value);
            }
            // Other value-taking flags: discard (not relevant to us).
            i += 1;
        } else if arg.contains('=') && arg.starts_with("--") {
            // Handle --flag=value form.
            let eq = arg.find('=').unwrap();
            let flag_part = &arg[..eq];
            let value_part = args[i][eq + 1..].to_owned();
            if VALUE_FLAGS.contains(&flag_part) {
                if flag_part == "--skip" {
                    skip_patterns.push(value_part);
                }
                i += 1;
            } else if BOOL_FLAGS.contains(&flag_part) || flag_part == "--exact" {
                // Boolean flags don't take values; --bool=value is unrecognized.
                eprintln!("error: unrecognized flag: {}", arg);
                std::process::exit(1);
            } else {
                eprintln!("error: unrecognized flag: {}", arg);
                std::process::exit(1);
            }
        } else if arg.starts_with('-') {
            // Unrecognized '-'-prefixed flag.
            eprintln!("error: unrecognized flag: {}", arg);
            std::process::exit(1);
        } else {
            // Genuine positional: inclusion name-filter argument.
            filters.push(arg.to_owned());
            i += 1;
        }
    }

    // Apply --skip semantics: skip this test if any skip pattern matches its name.
    // Real semantics: --skip X means "skip tests whose name matches X".
    // A non-matching pattern does NOT suppress the test.
    for skip in &skip_patterns {
        let skipped = if exact {
            TEST_NAME == skip.as_str()
        } else {
            TEST_NAME.contains(skip.as_str())
        };
        if skipped {
            std::process::exit(0);
        }
    }

    // Apply inclusion filters: if any positional filters given, run only when
    // at least one filter matches our test name.
    if !filters.is_empty() {
        let matches = filters.iter().any(|f| {
            if exact {
                TEST_NAME == f.as_str()
            } else {
                TEST_NAME.contains(f.as_str())
            }
        });
        if !matches {
            // Filtered out — no tests to run in this binary; exit 0.
            std::process::exit(0);
        }
    }

    // Run the single test body.  Any panic propagates and causes a non-zero exit
    // (the default panic handler terminates the process), which nextest and
    // `cargo test` both treat as a test failure.
    //
    // C-E2 soundness: this is the ONLY call site for the test function in this
    // binary.  `harness = false` makes adding a second call impossible without
    // refactoring `fn main()`, preserving the single-entry guarantee that makes
    // `unsafe set_var` safe (no concurrent environment reads possible).
    test_BC_2_01_003_post3_global_gitignore_respected_when_available();
    println!("test {TEST_NAME} ... ok");
}
