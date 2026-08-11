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

use std::path::{Path, PathBuf};

/// Build a configured [`ignore::WalkBuilder`] rooted at `root`.
///
/// The builder is configured to:
/// - Respect `.gitignore` and `.ignore` exclusion rules (BC-2.01.003)
/// - Unconditionally skip dot-directories and dot-files (BC-2.01.004; see D-011)
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
        .hidden(true) // unconditionally skip dot-dirs/files (BC-2.01.004, D-011)
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
        let is_dot_dir = e.file_type().is_some_and(|ft| ft.is_dir())
            && e.file_name().to_str().is_some_and(|n| n.starts_with('.'));
        !is_dot_dir
    });
    builder
}

/// Collect all `.md` files reachable from `root` into a deduplicated `Vec<PathBuf>`.
///
/// Applies the full traversal policy from [`build_walk`]:
/// - `.gitignore`/`.ignore` exclusion (BC-2.01.003)
/// - Dot-directory and dot-file skip (BC-2.01.004)
/// - Dir-symlink non-following (BC-2.01.004, DI-009)
/// - Case-sensitive `.md`-only extension filter via [`is_md_extension`] (BC-2.01.005)
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
