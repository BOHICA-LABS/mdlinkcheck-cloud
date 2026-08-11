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
//! RED GATE STATE: all 13 AC tests and both VP tests MUST fail at this step.
//! Each failure is a panic at `todo!()` inside the called scanner function body
//! (commit ba83b1b). No test may pass before the implementer runs.
//!
//! Gitignore fixture forms (Scope Ruling 4 — both forms covered):
//!   AC-004 / VP-016 Form A : git repo + `.gitignore` (git init required; ignore
//!                            crate default `require_git=true` only honours
//!                            .gitignore inside a real git repo)
//!   AC-005 / AC-006 / VP-016 Form B : plain (non-git) dir + `.ignore`
//!                            (`.ignore` is honoured unconditionally by WalkBuilder
//!                            regardless of `require_git`)

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

/// Run `git init -q` in `dir`.
///
/// Required for `.gitignore` exclusion tests because the `ignore` crate's
/// `WalkBuilder` default (`require_git = true`) only honours `.gitignore` files
/// inside a git repository. Without this, `.gitignore` patterns are silently
/// skipped. See Scope Ruling 4.
fn git_init(dir: &Path) {
    let status = std::process::Command::new("git")
        .args(["-C", dir.to_str().expect("UTF-8 path"), "init", "-q"])
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

    create_file(root, "README.md");
    create_file(root, "docs/guide.md");
    create_file(root, "docs/api/reference.md");
    create_file(root, "not_a_md.txt");
    create_file(root, "image.png");

    // ── Red Gate: collect_md_files panics at todo!() ──────────────────────────
    let result = scanner::collect_md_files(root);

    // After implementation: every .md file under root must appear in the result.
    let result_set: HashSet<PathBuf> = result.into_iter().collect();
    assert!(
        result_set.contains(&root.join("README.md")),
        "README.md must be in the scan set"
    );
    assert!(
        result_set.contains(&root.join("docs/guide.md")),
        "docs/guide.md must be in the scan set"
    );
    assert!(
        result_set.contains(&root.join("docs/api/reference.md")),
        "docs/api/reference.md must be in the scan set"
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

    create_file(root, "a.md");
    create_file(root, "sub/b.md");
    create_file(root, "sub/nested/c.md");

    // ── Red Gate: panics at todo!() ───────────────────────────────────────────
    let result = scanner::collect_md_files(root);

    let unique: HashSet<PathBuf> = result.iter().cloned().collect();
    assert_eq!(
        result.len(),
        unique.len(),
        "scan set must not contain duplicate paths (BC-2.01.001 postcondition 2)"
    );
}

// ─── AC-003 (traces to BC-2.01.001 postcondition 3) ──────────────────────────
// Fixture form: plain tempdir with finite depth.
// After implementation: the call must return within bounded time for any finite tree.

#[test]
fn test_BC_2_01_001_scan_terminates_for_finite_tree() {
    let dir = TempDir::new().expect("tempdir");
    let root = dir.path();

    create_file(root, "a.md");
    create_file(root, "b/c.md");
    create_file(root, "b/d/e.md");

    // ── Red Gate: panics at todo!() ───────────────────────────────────────────
    // After implementation: must return without looping.
    let result = scanner::collect_md_files(root);

    assert_eq!(result.len(), 3, "all three .md files must be discovered");
}

// ─── AC-004 (traces to BC-2.01.003 postcondition 1) ──────────────────────────
// Fixture form: GIT REPO + `.gitignore`
// (git init so the ignore crate's require_git=true default honours .gitignore)

#[test]
fn test_BC_2_01_003_gitignore_excludes_from_scan_set() {
    let dir = TempDir::new().expect("tempdir");
    let root = dir.path();

    git_init(root); // required: ignore crate only reads .gitignore inside a git repo
    fs::write(root.join(".gitignore"), "node_modules/\n").expect("write .gitignore");
    create_file(root, "node_modules/foo.md"); // must be excluded
    create_file(root, "README.md"); // must be included

    // ── Red Gate: panics at todo!() ───────────────────────────────────────────
    let result = scanner::collect_md_files(root);

    assert!(
        !result.contains(&root.join("node_modules/foo.md")),
        "node_modules/foo.md must not appear in the scan set (gitignored by node_modules/)"
    );
    assert!(
        result.contains(&root.join("README.md")),
        "README.md must appear in the scan set"
    );
    assert_eq!(result.len(), 1, "only README.md should be in the scan set");
}

// ─── AC-005 (traces to BC-2.01.003 invariant 1) ──────────────────────────────
// Fixture form: PLAIN (non-git) dir + `.ignore`
// (.ignore is honoured unconditionally by WalkBuilder regardless of require_git)

#[test]
fn test_BC_2_01_003_gitignored_file_not_scanned_as_source() {
    let dir = TempDir::new().expect("tempdir");
    let root = dir.path();

    // No git init: .ignore is always honoured, making this fixture git-independent
    fs::write(root.join(".ignore"), "secret.md\n").expect("write .ignore");
    create_file(root, "secret.md"); // excluded by .ignore
    create_file(root, "visible.md"); // included

    // ── Red Gate: panics at todo!() ───────────────────────────────────────────
    // After implementation: secret.md must NOT appear in the scan set;
    // it must never be scanned as a link source.
    let result = scanner::collect_md_files(root);

    assert!(
        !result.contains(&root.join("secret.md")),
        "secret.md must not be scanned as a link source (excluded by .ignore)"
    );
    assert!(
        result.contains(&root.join("visible.md")),
        "visible.md must be in the scan set"
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

    // .ignore excludes "ignored_target.md" from the scan set (clause i only)
    fs::write(root.join(".ignore"), "ignored_target.md\n").expect("write .ignore");
    create_file(root, "ignored_target.md"); // excluded by .ignore
    create_file(root, "source.md"); // in scan set

    // ── Red Gate: panics at todo!() ───────────────────────────────────────────
    // Clause (i): the .ignore-excluded file must NOT appear in the scan set.
    let result = scanner::collect_md_files(root);

    assert!(
        !result.contains(&root.join("ignored_target.md")),
        "ignored_target.md must not appear in the scan set (excluded by .ignore) \
         — clause (i) of BC-2.01.003 invariant 2"
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
    create_file(root, "README.md"); // not in dot-dir — must appear

    // ── Red Gate: panics at todo!() ───────────────────────────────────────────
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
        result_set.contains(&root.join("README.md")),
        "README.md (not in any dot-dir) must be in the scan set"
    );
    assert_eq!(result_set.len(), 1, "only README.md should be discovered");
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
    create_file(root, "visible.md");

    // The call below compiles with EXACTLY ONE argument, asserting the API surface:
    // no `hidden: bool`, no override config, no builder knob for dot-dir traversal.
    // This is both a compile-time and a runtime assertion of D-011.
    //
    // ── Red Gate: panics at todo!() ───────────────────────────────────────────
    let result = scanner::collect_md_files(root);

    // Positive assertion: visible.md MUST appear in the scan set.
    // Without this, the invariant below would pass vacuously on an empty Vec —
    // an empty result is not a correct implementation.
    assert!(
        result.contains(&root.join("visible.md")),
        "visible.md must appear in the scan set"
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

#[test]
fn test_BC_2_01_004_directory_symlinks_not_followed() {
    let dir = TempDir::new().expect("tempdir");
    let root = dir.path();

    // Create a directory with real .md content
    let dir_a = root.join("dir_a");
    fs::create_dir_all(&dir_a).expect("create dir_a");
    create_file(root, "dir_a/real.md");

    // Create a directory-symlink cycle: dir_a/cycle_link -> dir_a
    // This replicates EC-008: `a/b -> a`.
    #[cfg(unix)]
    std::os::unix::fs::symlink(&dir_a, dir_a.join("cycle_link"))
        .expect("create directory symlink cycle");

    create_file(root, "README.md");

    // ── Red Gate: panics at todo!() ───────────────────────────────────────────
    // After implementation: must terminate normally (follow_links(false) prevents
    // infinite recursion) and must NOT yield any path containing "cycle_link".
    let result = scanner::collect_md_files(root);

    assert!(
        !result
            .iter()
            .any(|p| p.to_string_lossy().contains("cycle_link")),
        "directory symlinks must not be traversed; cycle_link must not appear in scan set"
    );
    // dir_a/real.md is a real file (not behind a symlink) and must appear
    assert!(
        result.contains(&root.join("dir_a/real.md")),
        "dir_a/real.md must be discovered (it is a real file, not behind a dir symlink)"
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
    create_file(root, "source.md");

    // ── Red Gate: panics at todo!() ───────────────────────────────────────────
    // Clause (i): dot-dir .md must NOT appear in the scan set as a link source.
    let result = scanner::collect_md_files(root);

    assert!(
        !result.contains(&root.join(".vitepress/api.md")),
        ".vitepress/api.md is in a dot-directory and must not appear in the scan set \
         — clause (i) of BC-2.01.004 invariant 3"
    );
}

// ─── AC-011 (traces to BC-2.01.005 postcondition 1) ──────────────────────────

#[test]
fn test_BC_2_01_005_exact_md_extension_included() {
    // ── Red Gate: is_md_extension panics at todo!() ───────────────────────────
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
    let excluded = [
        "README.MD",
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

    // ── Red Gate: is_md_extension panics at todo!() on first call ─────────────
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
    // ── Red Gate: is_md_extension panics at todo!() on first call ─────────────
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

// ─── VP-016: gitignored files never appear in the scan set ───────────────────
//
// Covers BOTH fixture forms (Scope Ruling 4):
//   Form A — git repo + `.gitignore`
//   Form B — plain (non-git) dir + `.ignore`
//
// This is a dedicated integration test for VP-016, separate from the 13 ACs.
// At Red Gate it fails on Form A's collect_md_files call (todo!() panic).

#[test]
fn test_vp016_gitignored_files_never_in_scan_set() {
    // ── Form A: git repo + .gitignore ────────────────────────────────────────
    {
        let dir = TempDir::new().expect("tempdir form A");
        let root = dir.path();

        git_init(root);
        fs::write(root.join(".gitignore"), "excluded/\n").expect("write .gitignore");
        create_file(root, "excluded/hidden.md");
        create_file(root, "visible.md");

        // ── Red Gate: panics at todo!() ───────────────────────────────────────
        let result = scanner::collect_md_files(root);

        assert!(
            !result.iter().any(|p| p.starts_with(root.join("excluded"))),
            "VP-016 form A: gitignored files must never appear in scan set"
        );
        assert_eq!(result.len(), 1);
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
        create_file(root, "visible.md");

        let result = scanner::collect_md_files(root);

        assert!(
            !result.iter().any(|p| p.starts_with(root.join("excluded"))),
            "VP-016 form B: .ignore-excluded files must never appear in scan set"
        );
        assert_eq!(result.len(), 1);
    }
}

// ─── VP-017: property-based test — scan terminates for arbitrary tree ─────────
//
// Uses proptest to generate varied (depth, file_count, include_symlink_cycle)
// combinations. `collect_md_files` must terminate and return only paths under
// root for every generated input.
//
// At Red Gate: proptest panics on the first generated case because
// `collect_md_files` calls `todo!()`. The test is reported as FAILED.

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

        // Build a layered tree of .md files at the generated depth
        for i in 0..file_count {
            let mut rel = format!("file_{}.md", i);
            for d in 0..depth {
                rel = format!("dir_{}_{}/{}", d, i, rel);
            }
            create_file(root, &rel);
        }

        // Optionally add a directory-symlink cycle (EC-008): cycle_root/self_link -> cycle_root
        if include_symlink_cycle {
            let cycle_dir = root.join("cycle_root");
            let _ = fs::create_dir_all(&cycle_dir);
            #[cfg(unix)]
            let _ = std::os::unix::fs::symlink(&cycle_dir, cycle_dir.join("self_link"));
        }

        // ── Red Gate: panics at todo!() on first generated case ───────────────
        // After implementation: must terminate for ALL generated inputs including
        // cycles (follow_links(false) in WalkBuilder breaks cycles per VP-017).
        let result = scanner::collect_md_files(root);

        // All discovered paths must be under root
        for path in &result {
            prop_assert!(
                path.starts_with(root),
                "every discovered path must be under root; got {:?} with root {:?}",
                path, root
            );
        }

        // Symlink components must never appear in scan results
        prop_assert!(
            !result.iter().any(|p| p.to_string_lossy().contains("self_link")),
            "directory symlink components must not appear in scan results"
        );
    }
}
