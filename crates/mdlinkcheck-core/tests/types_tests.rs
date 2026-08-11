//! Unit tests for shared type construction in `mdlinkcheck-core/src/types.rs`.
//!
//! # Scope Note — S-1.01 constructible types only
//!
//! `Finding` and `ExtractedLink` construction tests are DEFERRED until
//! `FailureReason` and `LinkKind` gain concrete variants in their respective
//! implementation stories. Both enums are currently empty (no variants), making
//! `Finding` and `ExtractedLink` unconstructible without `unsafe` code.
//!
//! Types tested here (all fully defined in the S-1.01 stub, no `todo!()` bodies):
//!   - `EntryKind`    — all three variants including `Symlink { dangling }`
//!   - `DirEntryInfo` — construction and field access
//!   - `DirIndex`     — insert, lookup, and absence
//!   - `AnchorTable`  — construction and membership
//!   - `Verdict::Clean` — the only constructible `Verdict` variant in S-1.01
//!
//! These tests are NOT Red Gate tests. They exercise pure-core type definitions
//! that carry no `todo!()` bodies. All tests in this file should PASS at the
//! Red Gate step.

use std::collections::{HashMap, HashSet};
use std::ffi::OsString;
use std::path::PathBuf;

use mdlinkcheck_core::types::{AnchorTable, DirEntryInfo, DirIndex, EntryKind, Verdict};

// ─── EntryKind::File ─────────────────────────────────────────────────────────

#[test]
fn test_entry_kind_file_variant() {
    let kind = EntryKind::File;
    assert_eq!(kind, EntryKind::File);
    // Negative: not the other variants
    assert_ne!(kind, EntryKind::Dir);
    assert_ne!(kind, EntryKind::Symlink { dangling: false });
}

// ─── EntryKind::Dir ──────────────────────────────────────────────────────────

#[test]
fn test_entry_kind_dir_variant() {
    let kind = EntryKind::Dir;
    assert_eq!(kind, EntryKind::Dir);
    assert_ne!(kind, EntryKind::File);
}

// ─── EntryKind::Symlink { dangling: false } ───────────────────────────────────

#[test]
fn test_entry_kind_symlink_live_variant() {
    let kind = EntryKind::Symlink { dangling: false };
    assert_eq!(kind, EntryKind::Symlink { dangling: false });
    assert_ne!(kind, EntryKind::Symlink { dangling: true });

    if let EntryKind::Symlink { dangling } = kind {
        assert!(!dangling, "live symlink must have dangling: false");
    } else {
        panic!("expected EntryKind::Symlink, got {:?}", kind);
    }
}

// ─── EntryKind::Symlink { dangling: true } ────────────────────────────────────

#[test]
fn test_entry_kind_symlink_dangling_variant() {
    let kind = EntryKind::Symlink { dangling: true };
    assert_eq!(kind, EntryKind::Symlink { dangling: true });
    assert_ne!(kind, EntryKind::Symlink { dangling: false });

    if let EntryKind::Symlink { dangling } = kind {
        assert!(dangling, "dangling symlink must have dangling: true");
    } else {
        panic!("expected EntryKind::Symlink, got {:?}", kind);
    }
}

// ─── DirEntryInfo construction ────────────────────────────────────────────────

#[test]
fn test_dir_entry_info_construction_file() {
    let entry = DirEntryInfo {
        name: OsString::from("README.md"),
        kind: EntryKind::File,
    };
    assert_eq!(entry.name, OsString::from("README.md"));
    assert_eq!(entry.kind, EntryKind::File);
}

#[test]
fn test_dir_entry_info_construction_dir() {
    let entry = DirEntryInfo {
        name: OsString::from("docs"),
        kind: EntryKind::Dir,
    };
    assert_eq!(entry.name, OsString::from("docs"));
    assert_eq!(entry.kind, EntryKind::Dir);
}

#[test]
fn test_dir_entry_info_construction_symlink_dangling() {
    let entry = DirEntryInfo {
        name: OsString::from("broken_link"),
        kind: EntryKind::Symlink { dangling: true },
    };
    assert_eq!(entry.name, OsString::from("broken_link"));
    assert_eq!(entry.kind, EntryKind::Symlink { dangling: true });
}

#[test]
fn test_dir_entry_info_construction_symlink_live() {
    let entry = DirEntryInfo {
        name: OsString::from("live_link"),
        kind: EntryKind::Symlink { dangling: false },
    };
    assert_eq!(entry.kind, EntryKind::Symlink { dangling: false });
}

// ─── DirIndex insert and lookup ───────────────────────────────────────────────

#[test]
fn test_dir_index_insert_and_lookup() {
    let mut index: DirIndex = HashMap::new();
    let dir_path = PathBuf::from("/docs");

    let entries = vec![
        DirEntryInfo {
            name: OsString::from("guide.md"),
            kind: EntryKind::File,
        },
        DirEntryInfo {
            name: OsString::from("images"),
            kind: EntryKind::Dir,
        },
    ];

    index.insert(dir_path.clone(), entries);

    let retrieved = index.get(&dir_path).expect("dir_path must be in index after insert");
    assert_eq!(retrieved.len(), 2, "both entries must be retrieved");
    assert_eq!(retrieved[0].name, OsString::from("guide.md"));
    assert_eq!(retrieved[0].kind, EntryKind::File);
    assert_eq!(retrieved[1].name, OsString::from("images"));
    assert_eq!(retrieved[1].kind, EntryKind::Dir);
}

#[test]
fn test_dir_index_absent_key_returns_none() {
    let index: DirIndex = HashMap::new();
    assert!(
        index.get(&PathBuf::from("/nonexistent")).is_none(),
        "lookup of absent key must return None"
    );
}

#[test]
fn test_dir_index_multiple_directories() {
    let mut index: DirIndex = HashMap::new();

    index.insert(
        PathBuf::from("/a"),
        vec![DirEntryInfo { name: OsString::from("x.md"), kind: EntryKind::File }],
    );
    index.insert(
        PathBuf::from("/b"),
        vec![
            DirEntryInfo { name: OsString::from("y.md"),  kind: EntryKind::File },
            DirEntryInfo { name: OsString::from("link"), kind: EntryKind::Symlink { dangling: false } },
        ],
    );

    assert_eq!(index.get(&PathBuf::from("/a")).unwrap().len(), 1);
    assert_eq!(index.get(&PathBuf::from("/b")).unwrap().len(), 2);
    assert!(index.get(&PathBuf::from("/c")).is_none());
}

// ─── AnchorTable construction and membership ──────────────────────────────────

#[test]
fn test_anchor_table_construction_with_entries() {
    let mut set = HashSet::new();
    set.insert("section-one".to_string());
    set.insert("section-two".to_string());
    set.insert("api-reference".to_string());

    let table = AnchorTable(set);
    assert!(table.0.contains("section-one"), "section-one must be present");
    assert!(table.0.contains("section-two"), "section-two must be present");
    assert!(table.0.contains("api-reference"), "api-reference must be present");
    assert!(!table.0.contains("nonexistent"), "absent anchor must not match");
    assert_eq!(table.0.len(), 3);
}

#[test]
fn test_anchor_table_empty() {
    let table = AnchorTable(HashSet::new());
    assert!(table.0.is_empty(), "empty AnchorTable must have no entries");
    assert!(!table.0.contains("anything"), "empty table must not match any anchor");
}

#[test]
fn test_anchor_table_deduplication() {
    // HashSet semantics: inserting the same anchor twice results in one entry.
    let mut set = HashSet::new();
    set.insert("heading".to_string());
    set.insert("heading".to_string());

    let table = AnchorTable(set);
    assert_eq!(table.0.len(), 1, "duplicate anchor insertions must be deduplicated");
}

// ─── Verdict::Clean ───────────────────────────────────────────────────────────

#[test]
fn test_verdict_clean_construction() {
    let v = Verdict::Clean;
    assert_eq!(v, Verdict::Clean);
    // Verdict::Clean carries no payload and is the only unconditionally
    // constructible Verdict variant in S-1.01. Verdict::Broken and
    // Verdict::Indeterminate require a FailureReason value, which cannot
    // be constructed while FailureReason has no variants.
    match &v {
        Verdict::Clean => { /* expected */ }
        other => panic!("expected Verdict::Clean, got {:?}", other),
    }
}

#[test]
fn test_verdict_clean_equality() {
    let a = Verdict::Clean;
    let b = Verdict::Clean;
    assert_eq!(a, b, "two Verdict::Clean values must be equal");
}
