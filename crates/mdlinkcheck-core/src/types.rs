//! Shared types for mdlinkcheck.
//!
//! All type definitions shared between the pure-core library crate and the
//! effectful shell binary crate live here.
//!
//! # ADR-001 Purity Boundary
//! This module MUST NOT import `std::fs`, `std::net`, `std::io::stdout`,
//! `std::time::Instant`, or any RNG. All filesystem I/O belongs in
//! `mdlinkcheck/src/scanner.rs`.
//!
//! # Type Count: Story S-1.01 vs. `api-surface.md`
//!
//! Story S-1.01 (Task 6 and File Structure Requirements) names **eight** shared
//! types that must be defined here:
//! `Link`, `ExtractedLink`, `Finding`, `Verdict`, `AnchorTable`, `DirIndex`,
//! `DirEntryInfo`, and `EntryKind`.
//!
//! This file defines **seven** of those eight. The eighth type — `Link` — is
//! deliberately absent. The frozen `api-surface.md` §Key Shared Types defines no
//! `Link` type; it defines `ExtractedLink` as the canonical link-representation type,
//! and all downstream consumers (story specs, behavioral contracts) use `ExtractedLink`
//! throughout. Adding a `Link` type here would follow the story's eight-type list but
//! contradict `api-surface.md`, which takes precedence as the frozen architecture
//! authority. The story-vs-`api-surface.md` contradiction has not been adjudicated by
//! the operator and is left unresolved. A future operator decision should either add
//! `Link` here and update `api-surface.md`, or formally remove `Link` from the story's
//! type list to align the two documents.
//!
//! In addition to the seven story-named types, this file defines two further types
//! required for compilation: `FailureReason` (referenced by `Verdict` and `Finding`)
//! and `LinkKind` (referenced by `ExtractedLink`). Those two are not among the eight
//! types the story names.

use std::collections::{HashMap, HashSet};
use std::ffi::OsString;
use std::path::PathBuf;

// ─── Verdict ─────────────────────────────────────────────────────────────────

/// Outcome of a single link-check operation.
///
/// Carries a [`FailureReason`] payload when the link is broken or indeterminate.
/// Defined verbatim from `api-surface.md` §Key Shared Types.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Verdict {
    /// Link resolves successfully; no issues found.
    Clean,
    /// Link is definitively broken.
    Broken(FailureReason),
    /// Link status could not be determined (e.g., offline mode for HTTP links).
    Indeterminate(FailureReason),
}

// ─── FailureReason ───────────────────────────────────────────────────────────

/// Reason code explaining why a link check failed or is indeterminate.
///
/// This type is required for compilation of [`Verdict`] and [`Finding`].
/// Concrete variants (e.g., `AnchorNotFound`, `FileNotFound`, `MalformedUrl`) are
/// added by the implementer in the story that implements `verdict.rs` / `reporter.rs`.
///
/// Added beyond the 8 story-named types (see module-level doc for the full accounting)
/// because both `Verdict` and `Finding` reference it directly and the file would not
/// compile without it.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum FailureReason {
    // TODO(implementer): add concrete variants per behavioral contracts
    // (AnchorNotFound, FileNotFound, DirSymlink, BrokenSymlink, MalformedUrl, ...)
}

// ─── Finding ─────────────────────────────────────────────────────────────────

/// A single link-check finding emitted to the user.
///
/// Defined verbatim from `api-surface.md` §Key Shared Types.
#[derive(Debug, Clone)]
pub struct Finding {
    /// Path to the source Markdown file.
    pub path: PathBuf,
    /// 1-based line number of the link in the source file.
    pub line: u32,
    /// 1-based column number of the link in the source file.
    pub col: u32,
    /// The raw link destination as it appears in the source.
    pub link_target: String,
    /// Check outcome for this link.
    pub verdict: Verdict,
    /// Detailed failure reason code.
    pub reason: FailureReason,
}

// ─── LinkKind ────────────────────────────────────────────────────────────────

/// Classification of a link's destination kind.
///
/// This type is required for compilation of [`ExtractedLink`].
/// Concrete variants (e.g., `RelativePath`, `AbsolutePath`, `Http`, `MailTo`) are
/// added by the implementer in the story that implements `link_extractor.rs`.
///
/// Added beyond the 8 story-named types (see module-level doc for the full accounting)
/// because `ExtractedLink.kind` references it directly and the file would not compile
/// without it.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum LinkKind {
    // TODO(implementer): add concrete variants per behavioral contracts
}

// ─── ExtractedLink ───────────────────────────────────────────────────────────

/// A link extracted from a Markdown document during Pass 1.
///
/// Defined verbatim from `api-surface.md` §Key Shared Types.
#[derive(Debug, Clone)]
pub struct ExtractedLink {
    /// Raw destination string from the Markdown source.
    pub dest: String,
    /// Classification of the destination kind.
    pub kind: LinkKind,
    /// 1-based source line number.
    pub line: u32,
    /// 1-based source column number.
    pub col: u32,
}

// ─── AnchorTable ─────────────────────────────────────────────────────────────

/// Set of normalized anchor identifiers built from a Markdown document's headings.
///
/// Populated by `anchor_table::build_anchor_table` (pure-core).
/// Defined verbatim from `api-surface.md` §Library API.
#[derive(Debug, Clone)]
pub struct AnchorTable(pub HashSet<String>);

// ─── DirIndex ────────────────────────────────────────────────────────────────

/// Directory-keyed index mapping each directory path to its [`DirEntryInfo`] list.
///
/// Built by the effectful shell (`app`) during Pass 1.5.
/// Passed as immutable data into `path_resolver::resolve_path` (pure-core).
/// Never populated inside `mdlinkcheck-core` (ADR-001 purity boundary: scanner only
/// traverses the scan root; app opens out-of-scan target directories directly in
/// Pass 1.5).
///
/// Defined verbatim from `api-surface.md` §Library API.
pub type DirIndex = HashMap<PathBuf, Vec<DirEntryInfo>>;

// ─── DirEntryInfo ────────────────────────────────────────────────────────────

/// Metadata about a single filesystem directory entry.
///
/// Defined verbatim from `api-surface.md` §Library API.
#[derive(Debug, Clone)]
pub struct DirEntryInfo {
    /// Entry file name (without parent directory path component).
    pub name: OsString,
    /// Kind of this filesystem entry.
    pub kind: EntryKind,
}

// ─── EntryKind ───────────────────────────────────────────────────────────────

/// Kind of a filesystem directory entry.
///
/// Defined verbatim from `api-surface.md` §Library API.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum EntryKind {
    /// Regular file.
    File,
    /// Directory.
    Dir,
    /// Symbolic link; carries whether the link target is missing (dangling).
    Symlink { dangling: bool },
}
