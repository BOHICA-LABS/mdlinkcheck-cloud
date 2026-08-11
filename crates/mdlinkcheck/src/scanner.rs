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
/// `--hidden` is an explicit non-goal. Dot-directory skipping is unconditional
/// via `hidden(true)` and cannot be overridden by any caller-visible flag.
///
/// # Gitignore vs .ignore
/// `.gitignore` files are honoured only inside a real git repository
/// (`require_git` defaults to `true`). `.ignore` files are always honoured
/// regardless of git status. Tests that exercise `.gitignore` exclusion
/// (AC-004, VP-016 Form A) call `git init` in the fixture tempdir.
pub fn build_walk(root: &Path) -> ignore::WalkBuilder {
    let mut builder = ignore::WalkBuilder::new(root);
    builder
        .follow_links(false) // never follow dir symlinks (BC-2.01.004, DI-009)
        .hidden(true) // unconditionally skip dot-dirs/files (BC-2.01.004, D-011)
        .git_ignore(true) // respect .gitignore (BC-2.01.003)
        .ignore(true) // respect .ignore files (BC-2.01.003)
        .git_global(true) // respect global gitignore
        .git_exclude(true); // respect .git/info/exclude
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
