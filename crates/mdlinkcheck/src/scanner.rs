//! Effectful filesystem traversal module.
//!
//! Owns all filesystem I/O for the scanning pipeline.
//! Uses `ignore::WalkBuilder` for `.gitignore`-aware, dot-directory-skipping,
//! dir-symlink-non-following traversal (ADR-005).
//!
//! # ADR-001 Effectful Boundary
//! This module is the ONLY module that calls `fs::read_dir` (indirectly via the
//! `ignore` crate). `mdlinkcheck-core` MUST remain free of all I/O.
//!
//! # D-011 Non-Goal
//! The `--hidden` flag for overriding dot-directory skipping is an explicit non-goal.
//! Dot-directory skipping is unconditional and cannot be overridden by any flag.

use std::ffi::OsStr;
use std::path::{Path, PathBuf};

/// Build a configured [`ignore::WalkBuilder`] rooted at `root`.
///
/// The builder is configured to:
/// - Respect `.gitignore` and `.ignore` exclusion rules (BC-2.01.003)
/// - Unconditionally skip dot-**directories** (BC-2.01.004; enforced by `filter_entry`
///   independently of the ignore-rule system — see D-011 and the `filter_entry`
///   section below); dot-**file** skipping is best-effort via `hidden(true)` only,
///   is NOT unconditional, is NOT specified by any BC, and is under operator
///   adjudication — see the "Guarantee that does NOT survive caller mutation" section
/// - Never follow directory symlinks (BC-2.01.004 postcondition 2, DI-009)
///
/// # D-011 Non-Goal
/// `--hidden` is an explicit non-goal. Dot-directory skipping is enforced via a
/// `filter_entry` predicate (registered inside this function) that is evaluated
/// independently of the `ignore` crate's ignore-rule system.
///
/// **Guarantee that survives caller mutation:** the `filter_entry` dot-directory
/// rejection cannot be removed by calling `.hidden(false)` on the returned
/// builder, because `filter_entry` is not part of the hidden-file machinery.
/// A `.gitignore` negation pattern (e.g. `!.github`) that would otherwise
/// re-enable traversal into a dot-directory via `hidden(true)` alone is
/// overridden by this predicate (BC-2.01.004 invariant 1 / EC-003 / F-A1).
///
/// **Guarantee that does NOT survive caller mutation:** `hidden(true)` controls
/// dot-*file* skipping. A caller who calls `.hidden(false)` on the returned
/// `WalkBuilder` will re-enable traversal into dot-files. The dot-directory
/// guarantee is unaffected, but dot-file handling is under separate operator
/// adjudication (D-011) and is not enforced by `filter_entry`.
///
/// **`filter_entry` is REPLACEABLE (`ignore` 0.4.33 `walk.rs:1043`):** only one
/// filter predicate can be active on a `WalkBuilder` at a time — a subsequent
/// `filter_entry(...)` call on the returned builder REPLACES this predicate,
/// silently removing the dot-dir guard. Callers who need extra path filtering
/// (e.g. `--ignore <glob>` in S-1.02) MUST compose with [`is_dot_dir_name`]
/// rather than replace the predicate. For [`collect_md_files`], which builds
/// its own walker and additionally post-filters every path through
/// [`is_dot_dir_name`], the unconditional dot-dir invariant is structural and
/// cannot be removed by any builder mutation.
///
/// # Gitignore vs .ignore
/// `.gitignore` files are honoured in ALL directories regardless of whether a
/// real git repository is present (`require_git(false)`). `.ignore` files are
/// likewise always honoured. This satisfies BC-2.01.003 postcondition 1
/// ("every file matching a pattern in **any applicable** `.gitignore` or
/// `.ignore` file is excluded") and EC-002 ("`node_modules/` in `.gitignore`
/// → excluded, no performance blowout") which impose no git-repo requirement.
pub fn build_walk(root: &Path) -> ignore::WalkBuilder {
    let mut builder = ignore::WalkBuilder::new(root);
    builder
        .follow_links(false) // never follow dir symlinks (BC-2.01.004, DI-009)
        // hidden(true): best-effort dot-FILE skip — NOT unconditional. Subordinate to
        // ignore-rule matches: a .gitignore negation pattern can defeat this for
        // dot-files (see "Guarantee that does NOT survive caller mutation" in this
        // function's doc). NOT specified by any BC; under operator adjudication.
        // Dot-DIRECTORY skipping is enforced unconditionally by filter_entry below
        // (BC-2.01.004, D-011), independently of this flag.
        .hidden(true)
        .git_ignore(true) // respect .gitignore (BC-2.01.003)
        .ignore(true) // respect .ignore files (BC-2.01.003)
        .git_global(true) // respect global gitignore
        .git_exclude(true) // respect .git/info/exclude
        .require_git(false); // honour .gitignore outside git repos (BC-2.01.003 post1, EC-002)

    // Unconditional dot-directory guard (BC-2.01.004 invariant 1 / D-011 / EC-003).
    //
    // `hidden(true)` is SUBORDINATE to ignore-rule matches in `ignore` 0.4.33:
    // a negation pattern such as `!.github` in `.gitignore` re-enables traversal
    // into a dot-directory, defeating `hidden(true)` alone.  `filter_entry`
    // predicates are evaluated independently of the ignore system and therefore
    // cannot be overridden by ignore-file whitelist patterns.
    //
    // Depth-0 exemption: `filter_entry` is called for the root entry (depth 0).
    // `TempDir`'s default prefix is `.tmp`, so the scan root itself can be a
    // dot-prefixed directory.  Rejecting depth-0 would return an empty scan set.
    // We reject only entries at depth > 0, using `file_name()` (not the full
    // path) so that a dot-prefixed ancestor in the absolute path does not cause
    // false positives on non-root entries.
    builder.filter_entry(|e| {
        if e.depth() == 0 {
            return true; // never reject the scan root itself
        }
        // Reject any directory whose own name begins with `.`
        let is_dot_dir =
            e.file_type().is_some_and(|ft| ft.is_dir()) && is_dot_dir_name(e.file_name());
        !is_dot_dir
    });
    builder
}

/// Return `true` if `name` is a dot-directory name, i.e. its first byte is `b'.'`.
///
/// Uses a byte-wise comparison (`OsStr::as_encoded_bytes().starts_with(b".")`) so
/// that directory names that are not valid UTF-8 are correctly identified as
/// dot-directories and rejected.  A UTF-8-only check
/// (`to_str().is_some_and(|n| n.starts_with('.'))`) fails open for non-UTF-8 names
/// because `to_str()` returns `None`, causing the dot-directory to be admitted —
/// a violation of BC-2.01.004 invariant 1 (defect F-P2-01).
///
/// The `ignore` crate uses the equivalent byte-wise check in `pathutil.rs`:
/// `name.as_encoded_bytes().starts_with(b".")`.
///
/// # BC traceability
/// - BC-2.01.004 invariant 1: "ALL dot-directories are unconditionally excluded.
///   No flag overrides this (D-011)."
/// - BC-2.01.001 invariant 1: scope restricted to files not inside dot-directories.
pub fn is_dot_dir_name(name: &OsStr) -> bool {
    name.as_encoded_bytes().starts_with(b".")
}

/// Collect all `.md` files reachable from `root` into a deduplicated `Vec<PathBuf>`.
///
/// Applies the full traversal policy from [`build_walk`]:
/// - `.gitignore`/`.ignore` exclusion (BC-2.01.003)
/// - Dot-**directory** skip: unconditional, BC-anchored (BC-2.01.004, enforced by
///   both `filter_entry` in [`build_walk`] and the post-filter backstop below)
/// - Dot-**file** skip: best-effort via `hidden(true)`, NOT unconditional, NOT
///   specified by any BC; subject to override by ignore-rule negation patterns;
///   under operator adjudication (defer-and-disclose)
/// - Dir-symlink non-following (BC-2.01.004, DI-009)
/// - Case-sensitive `.md`-only extension filter via [`is_md_extension`] (BC-2.01.005)
/// - Post-filter backstop: any path whose components (relative to `root`) contain a
///   dot-prefixed segment is rejected, reusing [`is_dot_dir_name`] (BC-2.01.004
///   invariant 1). This is defence in depth against callers who replace the
///   `filter_entry` predicate on the builder returned by [`build_walk`] — see
///   `ignore` 0.4.33 `walk.rs:1043`.
///
/// The returned `Vec` contains no duplicate paths (BC-2.01.001 postcondition 2).
pub fn collect_md_files(root: &Path) -> Vec<PathBuf> {
    let builder = build_walk(root);
    let mut files: Vec<PathBuf> = builder
        .build()
        .filter_map(|result| {
            let entry = result.ok()?;
            let file_type = entry.file_type()?;
            if !file_type.is_file() {
                return None;
            }
            let path = entry.path().to_path_buf();
            // Post-filter backstop: reject any path containing a dot-prefixed
            // component (relative to root).  Defence in depth for the case where
            // a caller replaces the filter_entry predicate on the WalkBuilder
            // returned by build_walk — ignore 0.4.33 (walk.rs:1043) stores only
            // ONE filter predicate; a second call replaces the first, silently
            // removing the dot-dir guard registered inside build_walk.  This
            // post-filter restores the correctness guarantee structurally for all
            // collect_md_files consumers, regardless of builder mutation.
            // Reuses is_dot_dir_name for byte-wise, UTF-8-agnostic comparison
            // (BC-2.01.004 invariant 1 / F-P2-01 backstop).
            let rel = path.strip_prefix(root).unwrap_or(path.as_path());
            if rel.components().any(|c| is_dot_dir_name(c.as_os_str())) {
                return None;
            }
            if is_md_extension(&path) {
                Some(path)
            } else {
                None
            }
        })
        .collect();

    // Guarantee no duplicates (BC-2.01.001 postcondition 2).
    files.sort();
    files.dedup();
    files
}

/// Return `true` iff `path` has the exact lowercase `.md` extension.
///
/// Extension matching is a case-sensitive byte comparison of the exact string
/// `.md` (BC-2.01.005 invariant 1). `.MD`, `.Md`, `.markdown`, `.mdx`, `.mdown`,
/// `.mkd`, `.txt`, `.html`, and all other non-exact-`.md` extensions are excluded
/// (D-012).
///
/// # Extension invariant
/// `Path::extension()` strips the leading dot: `"file.md"` yields `Some("md")`.
/// A bare dotfile named exactly `.md` yields `None` (no extension per `Path`
/// semantics) and is therefore excluded — which is the correct behaviour because
/// `.md` as a filename (not extension) is not a Markdown file by convention.
pub fn is_md_extension(path: &Path) -> bool {
    // Case-sensitive byte comparison: "md" != "MD" != "Md" (BC-2.01.005 invariant 1).
    path.extension().is_some_and(|ext| ext == "md")
}
