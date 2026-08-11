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
/// - Unconditionally skip dot-directories (BC-2.01.004; see D-011)
/// - Never follow directory symlinks (BC-2.01.004 postcondition 2, DI-009)
///
/// # D-011 Non-Goal Reminder
/// `--hidden` is an explicit non-goal. There is no mechanism to override
/// dot-directory skipping. Do NOT add `hidden(true)` to the builder.
///
/// # BC-5.38.005 Self-Check
/// "If I include this real implementation, will the test for this function pass
/// trivially without any implementer work?"
/// Answer: YES — AC-007, AC-009 tests exercise dot-dir and symlink behaviour
/// configured here. Body MUST be `todo!()` per BC-5.38.001.
pub fn build_walk(root: &Path) -> ignore::WalkBuilder {
    todo!()
}

/// Collect all `.md` files reachable from `root` into a `Vec<PathBuf>`.
///
/// Applies the full traversal policy from [`build_walk`]:
/// - `.gitignore`/`.ignore` exclusion (BC-2.01.003)
/// - Dot-directory skip (BC-2.01.004)
/// - Dir-symlink non-following (BC-2.01.004, DI-009)
/// - Case-sensitive `.md`-only extension filter via [`is_md_extension`] (BC-2.01.005)
///
/// The returned `Vec` contains no duplicate paths
/// (BC-2.01.001 postcondition 2).
///
/// # BC-5.38.005 Self-Check
/// "If I include this real implementation, will the test for this function pass
/// trivially without any implementer work?"
/// Answer: YES — AC-001 through AC-013 tests exercise this function directly.
/// Body MUST be `todo!()` per BC-5.38.001.
pub fn collect_md_files(root: &Path) -> Vec<PathBuf> {
    todo!()
}

/// Return `true` iff `path` has the exact lowercase `.md` extension.
///
/// Extension matching is a case-sensitive byte comparison of the exact string
/// `.md` (BC-2.01.005 invariant 1). `.MD`, `.Md`, `.markdown`, `.mdx`, `.mdown`,
/// `.mkd`, `.txt`, `.html`, and all other non-exact-`.md` extensions are excluded
/// (D-012).
///
/// # BC-5.38.005 Self-Check (BC-5.38.005 invariant 1)
/// "If I include this real implementation, will the test for this function pass
/// trivially without any implementer work?"
/// Answer: YES — AC-011 (`test_BC_2_01_005_exact_md_extension_included`), AC-012
/// (`test_BC_2_01_005_non_md_extensions_excluded`), and AC-013
/// (`test_BC_2_01_005_case_sensitive_byte_match`) directly exercise this function.
/// Body MUST be `todo!()` per BC-5.38.001.
pub fn is_md_extension(path: &Path) -> bool {
    todo!()
}
