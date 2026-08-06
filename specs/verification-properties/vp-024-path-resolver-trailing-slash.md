---
document_type: verification-property
level: L4
version: "1.1"
status: draft
producer: architect
timestamp: 2026-08-05T21:00:00Z
phase: 1b
inputs:
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/architecture/module-decomposition.md
input-hash: "012887b"
traces_to: .factory/specs/architecture/ARCH-INDEX.md
source_bc: BC-2.07.008
module: path_resolver
proof_method: proptest
feasibility: feasible
verification_lock: false
proof_completed_date: null
proof_file_hash: null
lifecycle_status: active
introduced: v1.4.0
modified:
  - version: "1.1"
    date: 2026-08-05
    change: "P2-M06 remediation: replaced hardcoded absolute path '/tmp/test' in arb_dir_index_with_file strategy with relative form — src_dir derived from the generated file name, dest constructed as a relative path using format!('{name}/'). The harness now passes a relative dest to resolve_path and an empty src_dir (current directory), which matches the pure-function contract."
deprecated: null
deprecated_by: null
replacement: null
retired: null
withdrawn: null
withdrawal_reason: null
removed: null
removal_reason: null
---

# VP-024: path_resolver Trailing-Slash-on-File → file-not-found (Never target-is-directory)

## Property Statement

For any `DirIndex` that contains an entry for path `P` with `EntryKind::File`, the call
`resolve_path(dest, src_dir, &index)` where `dest` has a trailing slash that resolves to
`P` returns `PathVerdict::Broken(FailureReason::FileNotFound)` — never
`PathVerdict::Broken(FailureReason::TargetIsDirectory)` and never `PathVerdict::Clean`.

The distinction matters because:
- A trailing slash on a **directory** path should yield `clean` (BC-2.07.005).
- A trailing slash on a **file** path yields `broken(file-not-found)` — the path
  `a.md/` does not exist as a directory even though `a.md` exists as a file (BC-2.07.008).

The `target-is-directory` reason code is reserved for a different case: a destination
that resolves to a directory with a `#fragment`, not a trailing-slash-on-file. These two
reason codes must never be confused.

## Source Contract

- **BC:** BC-2.07.008 — Trailing Slash on Regular File → `file-not-found`
- **Postcondition 1:** verdict is `broken`, reason is `file-not-found`
- **Postcondition 4:** distinct from `target-is-directory` (which applies when a directory
  exists at the path; here, no directory exists at `a.md/`)

## Proof Method

| Method | Tool | Bounded? | Coverage |
|--------|------|----------|----------|
| proptest | proptest 1.6.0 | no — property-based, 10 000 samples | Synthetic DirIndex entries covering File/Dir/Symlink{dangling} kinds with and without trailing-slash destinations |

## Proof Harness Skeleton

```rust
use proptest::prelude::*;

// Generate a synthetic DirIndex with one File entry.
// The DirIndex key is the CURRENT directory (PathBuf::new(), representing "."),
// and the file name is a relative name like "foo.md".
// dest strings are relative (e.g., "foo.md/" and "foo.md") — matching how
// resolve_path receives them from the link extractor.
fn arb_dir_index_with_file() -> impl Strategy<Value = (String, DirIndex)> {
    "[a-z]{1,8}\\.[a-z]{1,4}".prop_map(|name| {
        // src_dir is the root of the synthetic DirIndex
        let src_dir = PathBuf::new();  // represents "." — current directory
        let entry = DirEntryInfo { name: OsString::from(&name), kind: EntryKind::File };
        let mut index = HashMap::new();
        index.insert(src_dir, vec![entry]);
        (name, index)
    })
}

proptest! {
    #[test]
    fn vp024_trailing_slash_on_file_is_file_not_found(
        (name, index) in arb_dir_index_with_file()
    ) {
        // dest = relative file name + "/" — trailing slash on a file
        let dest = format!("{}/", name);
        let src_dir = PathBuf::new();  // same directory as the DirIndex key
        let verdict = resolve_path(&dest, &src_dir, &index);
        match verdict {
            PathVerdict::Broken(FailureReason::FileNotFound) => {}  // correct
            PathVerdict::Broken(FailureReason::TargetIsDirectory) =>
                panic!("Trailing slash on file must not produce target-is-directory; \
                        got target-is-directory for {:?}/", name),
            PathVerdict::Clean =>
                panic!("Trailing slash on file must not produce clean; \
                        got clean for {:?}/", name),
            other =>
                panic!("Unexpected verdict {:?} for {:?}/", other, name),
        }
    }

    #[test]
    fn vp024_no_trailing_slash_on_file_is_clean(
        (name, index) in arb_dir_index_with_file()
    ) {
        // Control: same relative file name WITHOUT trailing slash → clean
        let src_dir = PathBuf::new();
        let verdict = resolve_path(&name, &src_dir, &index);
        prop_assert_eq!(verdict, PathVerdict::Clean,
            "File path without trailing slash must resolve clean; got {:?} for {:?}",
            verdict, name);
    }
}
```

## Feasibility Assessment

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Input space size | Bounded (synthetic DirIndex) | DirIndex contains controlled entries; proptest generates names within printable ASCII |
| Proof complexity | Low | Pure function; DirIndex is a data structure with no side effects; strategy construction is straightforward |
| Tool support | Full | `proptest 1.6.0`; no special Unicode strategies needed |
| Estimated proof time | < 5s per run (Phase 3 CI) | 10 000 samples; `cargo nextest` |
| Regression risk | Real | The `file-not-found` vs `target-is-directory` distinction is a single conditional on `EntryKind`; easy to swap under refactor |

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-05 | architect |
| Proof harness committed | — | formal-verifier |
| Proof first passed | — | formal-verifier |
| Locked (VERIFIED) | — | formal-verifier |
