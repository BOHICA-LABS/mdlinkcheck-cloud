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
use std::sync::Mutex;

use tempfile::TempDir;

use mdlinkcheck::scanner;

// ─── Test fixture helpers ─────────────────────────────────────────────────────

// ─── Hermetic git-fixture support (F-09) ─────────────────────────────────────
//
// `build_walk` sets `git_global(true)`, which is correct per BC-2.01.003
// postcondition 3.  The `ignore` crate resolves the global gitignore path by
// reading the gitconfig whose location comes from the `GIT_CONFIG_GLOBAL`
// process environment variable (fallback: `$HOME/.gitconfig`).  If a
// developer's or CI runner's global gitignore contains patterns like `*.md`,
// git-init'd fixture tests (AC-004, VP-016 Form A) would fail for reasons
// unrelated to the code under test.
//
// Fix: git-fixture tests serialize via `GIT_FIXTURE_LOCK` and temporarily
// override `GIT_CONFIG_GLOBAL` (+ `GIT_CONFIG_NOSYSTEM`) to point at an empty
// file inside the fixture's own `TempDir`.  `EnvRestoreGuard` restores the
// prior env value on drop, ensuring cleanup even when a test panics.
//
// Race-free guarantee: `GIT_FIXTURE_LOCK` is the single shared resource.  Each
// git-fixture test acquires the lock before mutating env, holds it through the
// entire `collect_md_files` call, and releases it only after `EnvRestoreGuard`s
// have restored the original values.  No two git-fixture tests can mutate env
// concurrently.

/// Serialises all git-fixture tests so that per-test env overrides are
/// race-free within a single test binary process.
static GIT_FIXTURE_LOCK: Mutex<()> = Mutex::new(());

/// RAII guard: saves an env variable's current value on construction and
/// restores it (or removes it if it was absent) when dropped.
///
/// Used to bracket `GIT_CONFIG_GLOBAL` / `GIT_CONFIG_NOSYSTEM` overrides so
/// that the prior state is always restored — even when a test panics.
struct EnvRestoreGuard {
    key: &'static str,
    original: Option<std::ffi::OsString>,
}

impl EnvRestoreGuard {
    fn set(key: &'static str, new_val: impl AsRef<std::ffi::OsStr>) -> Self {
        let original = std::env::var_os(key);
        // SAFETY: this binary's tests are serialised via GIT_FIXTURE_LOCK so no
        // concurrent mutation can race with this assignment.
        unsafe { std::env::set_var(key, new_val) };
        EnvRestoreGuard { key, original }
    }
}

impl Drop for EnvRestoreGuard {
    fn drop(&mut self) {
        // SAFETY: same serialisation guarantee as in `set`.
        unsafe {
            match &self.original {
                Some(v) => std::env::set_var(self.key, v),
                None => std::env::remove_var(self.key),
            }
        }
    }
}

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
/// `hermetic_config` is the path to an empty gitconfig file that lives inside
/// the fixture's `TempDir`.  Passing it as per-command env (`GIT_CONFIG_GLOBAL`,
/// `GIT_CONFIG_NOSYSTEM=1`) ensures the `git init` subprocess is not influenced
/// by the developer's real global gitignore or git configuration.
///
/// The caller must also set `GIT_CONFIG_GLOBAL` in the *process* environment
/// (via `EnvRestoreGuard`) before calling `collect_md_files`, so that the
/// `ignore` crate — which runs in-process and reads `GIT_CONFIG_GLOBAL` to
/// locate the global gitignore — also uses the empty hermetic config.
///
/// Required for `.gitignore` exclusion tests because the `ignore` crate's
/// `WalkBuilder` default (`require_git = true`) only honours `.gitignore` files
/// inside a git repository.  Without this, `.gitignore` patterns are silently
/// skipped.  See Scope Ruling 4.
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
    // Positive gate: all three fixture files must be present (F-04 vacuous-pass
    // prevention — an empty Vec passes the dedup assertion above vacuously).
    assert!(
        unique.contains(&root.join("a.md")),
        "a.md must appear in the scan set"
    );
    assert!(
        unique.contains(&root.join("sub/b.md")),
        "sub/b.md must appear in the scan set"
    );
    assert!(
        unique.contains(&root.join("sub/nested/c.md")),
        "sub/nested/c.md must appear in the scan set"
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

    // Hermetic git config: prevents developer's/CI's global gitignore (e.g. `*.md`)
    // from interfering with the fixture via the ignore crate's git_global(true) path.
    // The lock serialises this test with other git-fixture tests; EnvRestoreGuard
    // restores env on exit (including panics).  See GIT_FIXTURE_LOCK docs above.
    let hermetic_cfg = root.join(".hermetic_gitconfig");
    fs::write(&hermetic_cfg, "").expect("write hermetic gitconfig");
    let _git_lock = GIT_FIXTURE_LOCK.lock().unwrap_or_else(|e| e.into_inner());
    let _guard_global = EnvRestoreGuard::set("GIT_CONFIG_GLOBAL", &hermetic_cfg);
    let _guard_nosys = EnvRestoreGuard::set("GIT_CONFIG_NOSYSTEM", "1");

    git_init(root, &hermetic_cfg); // required: ignore crate only reads .gitignore inside a git repo
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
    // Positive gate: source.md must be present (F-04 vacuous-pass prevention —
    // an empty Vec passes the negative assertion above vacuously).
    assert!(
        result.contains(&root.join("source.md")),
        "source.md must appear in the scan set (F-04 vacuous-pass prevention)"
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
    //   <root>/docs  ->  <external>   (analogous to EC-009: docs -> ../shared-docs)
    std::os::unix::fs::symlink(external, root.join("docs"))
        .expect("create non-cyclic out-of-root directory symlink (EC-009)");

    // A real in-root .md file: prevents vacuous pass on an empty result.
    create_file(root, "README.md");

    let result = scanner::collect_md_files(root);

    // Positive gate: README.md MUST appear.
    // If the implementation returns an empty Vec, the negative assertions below
    // would pass vacuously, so this guard is mandatory.
    assert!(
        result.contains(&root.join("README.md")),
        "README.md must be discovered; empty scan set is not a correct implementation \
         (EC-009 vacuous-pass prevention)"
    );

    // Negative assertion 1: no discovered path traverses the docs symlink.
    // Under follow_links(false) the docs entry is seen as a symlink and skipped.
    // Under follow_links(true) the walk descends into docs/ and yields paths
    // containing a "docs" path component — this is the mutation-kill signal.
    assert!(
        !result
            .iter()
            .any(|p| p.components().any(|c| c.as_os_str() == "docs")),
        "no path with a 'docs' component must appear — the docs directory symlink \
         must not be traversed \
         (AC-009 / BC-2.01.004 postcondition 2 / DI-009 / EC-009, \
         mutation-discriminating case for follow_links(false))"
    );

    // Negative assertion 2: external.md must not be reachable by any path.
    assert!(
        !result
            .iter()
            .any(|p| p.file_name().map_or(false, |n| n == "external.md")),
        "external.md lives outside the scan root and is reachable only via the docs \
         directory symlink; it must not be discovered when follow_links(false) is set \
         (EC-009 / BC-2.01.004 postcondition 2)"
    );

    // Exactly one file should be in the scan set.
    assert_eq!(
        result.len(),
        1,
        "only README.md should be in the scan set; \
         external.md behind the docs symlink must be excluded (EC-009)"
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
    // Positive gate: source.md must be present (F-04 vacuous-pass prevention —
    // an empty Vec passes the negative assertion above vacuously).
    assert!(
        result.contains(&root.join("source.md")),
        "source.md must appear in the scan set (F-04 vacuous-pass prevention)"
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
    create_file(root, "README.MD"); // EC-005: uppercase .MD
    create_file(root, "notes.markdown"); // EC-006a
    create_file(root, "notes.mdx"); // EC-006b
    create_file(root, "notes.mdown"); // D-012 non-goal
    create_file(root, "notes.mkd"); // D-012 non-goal
    create_file(root, "notes.txt"); // D-012 non-goal
    create_file(root, "page.html"); // D-012 non-goal

    // The only file that MUST appear — mandatory positive gate (vacuous-pass
    // prevention: without it, an empty Vec passes every negative assertion).
    create_file(root, "good.md");

    let result = scanner::collect_md_files(root);

    // Positive gate: good.md must be discovered via traversal.
    assert!(
        result.contains(&root.join("good.md")),
        "good.md must be in the scan set \
         (EC-005/EC-006a/EC-006b traversal test, vacuous-pass prevention)"
    );

    // Negative assertions: every non-.md file must be absent from the scan set.
    assert!(
        !result.contains(&root.join("README.MD")),
        "README.MD (uppercase) must not appear in scan set via traversal (EC-005)"
    );
    assert!(
        !result.contains(&root.join("notes.markdown")),
        "notes.markdown must not appear in scan set via traversal (EC-006a)"
    );
    assert!(
        !result.contains(&root.join("notes.mdx")),
        "notes.mdx must not appear in scan set via traversal (EC-006b)"
    );
    assert!(
        !result.contains(&root.join("notes.mdown")),
        "notes.mdown must not appear in scan set via traversal (D-012)"
    );
    assert!(
        !result.contains(&root.join("notes.mkd")),
        "notes.mkd must not appear in scan set via traversal (D-012)"
    );
    assert!(
        !result.contains(&root.join("notes.txt")),
        "notes.txt must not appear in scan set via traversal (D-012)"
    );
    assert!(
        !result.contains(&root.join("page.html")),
        "page.html must not appear in scan set via traversal (D-012)"
    );

    // Exactly one file: only good.md.
    assert_eq!(
        result.len(),
        1,
        "exactly one file (good.md) must be in the scan set; \
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
// At Red Gate it fails on Form A's collect_md_files call (todo!() panic).

#[test]
fn test_vp016_gitignored_files_never_in_scan_set() {
    // ── Form A: git repo + .gitignore ────────────────────────────────────────
    {
        let dir = TempDir::new().expect("tempdir form A");
        let root = dir.path();

        // Hermetic git config for Form A (same rationale as AC-004).
        let hermetic_cfg = root.join(".hermetic_gitconfig");
        fs::write(&hermetic_cfg, "").expect("write hermetic gitconfig form A");
        let _git_lock = GIT_FIXTURE_LOCK.lock().unwrap_or_else(|e| e.into_inner());
        let _guard_global = EnvRestoreGuard::set("GIT_CONFIG_GLOBAL", &hermetic_cfg);
        let _guard_nosys = EnvRestoreGuard::set("GIT_CONFIG_NOSYSTEM", "1");

        git_init(root, &hermetic_cfg);
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
            // EC-008: self-referential cycle
            let cycle_dir = root.join("cycle_root");
            let _ = fs::create_dir_all(&cycle_dir);
            #[cfg(unix)]
            let _ = std::os::unix::fs::symlink(&cycle_dir, cycle_dir.join("self_link"));

            // EC-009: non-cyclic out-of-root directory symlink
            #[cfg(unix)]
            {
                let outside = TempDir::new().expect("tempdir VP-017 outside");
                create_file(outside.path(), "outside.md");
                let _ = std::os::unix::fs::symlink(outside.path(), root.join("outlink"));
                _keep_alive.push(outside); // keep alive until after the scan
            }
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

        // EC-008: symlink-cycle components must never appear in scan results
        prop_assert!(
            !result.iter().any(|p| p.to_string_lossy().contains("self_link")),
            "directory symlink components must not appear in scan results"
        );

        // EC-009: files behind a non-cyclic out-of-root directory symlink must
        // not appear (mutation-discriminating for follow_links(false)).
        prop_assert!(
            !result.iter().any(|p| p.file_name().map_or(false, |n| n == "outside.md")),
            "files in out-of-root directories reachable only via a non-cyclic \
             directory symlink must not appear in scan results \
             (EC-009, mutation-discriminating for follow_links(false))"
        );

        // EC-009: the outlink symlink component itself must not appear in any path
        prop_assert!(
            !result.iter().any(|p| p.to_string_lossy().contains("outlink")),
            "outlink directory symlink must not be traversed; \
             no path with 'outlink' component may appear in scan results (EC-009)"
        );
    }
}
