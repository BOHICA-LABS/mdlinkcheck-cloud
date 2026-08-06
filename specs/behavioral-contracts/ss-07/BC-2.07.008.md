---
document_type: behavioral-contract
level: L3
version: "1.1"
status: draft
producer: vsdd-factory:product-owner
timestamp: 2026-08-05T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/specs/domain-spec/L2-INDEX.md
input-hash: "c08cb30"
traces_to: .factory/specs/domain-spec/L2-INDEX.md
origin: greenfield
extracted_from: null
subsystem: "SS-07"
capability: "CAP-007"
lifecycle_status: active
introduced: v1.4.0
modified:
  - v1.5: "Fix 3 (VP elevation): replaced test-sufficient with VP-024 per VP-INDEX v1.2 architect decision. Trailing-slash-on-file invariant requires proptest to eliminate the file-not-found vs target-is-directory swap risk on EntryKind refactor."
  - "v1.1: (INC-MAP) Architecture Module field added per bc-module-map.md (architect, Phase 1b)"
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.07.008: Trailing Slash on Regular File → file-not-found

## Description
A link whose destination has a trailing slash (`[x](a.md/)`) where `a.md` exists as a regular
file (not a directory) produces verdict `broken`, reason `file-not-found`. The trailing slash
signals a directory path expectation; since `a.md` is a file, not a directory, the path `a.md/`
does not resolve to any existing file or directory (POSIX: ENOTDIR). This is the deterministic
single-verdict for EC-034/TV-034 (F-012).

## Preconditions
1. A link destination has a trailing `/` after path normalization.
2. The resolved base path (stripping the trailing `/`) exists as a **regular file**.

## Postconditions
1. The verdict is `broken`.
2. The reason code is `file-not-found`.
3. Exit code contribution: 1.
4. This is distinct from `target-is-directory` (which applies when a directory exists at the
   path). Here, no directory exists at `a.md/` — the path resolution fails with ENOTDIR/ENOENT.

## Invariants
1. A trailing slash never converts a file path into a clean result.
2. The tool checks whether `a.md/` resolves to a **directory** entry; finding only a file at
   `a.md`, it concludes the directory path `a.md/` does not exist → `file-not-found`.
3. If `a.md` does NOT exist either: verdict is still `file-not-found` (same code, different cause).

## Edge Cases
| EC | Description |
|----|-------------|
| EC-034 | `[x](a.md/)` where `a.md` is a regular file |
| EC-034b | `[x](a.md/)` where `a.md` does NOT exist |
| EC-034c | `[x](docs/)` where `docs` IS a directory |

## Canonical Test Vectors
| Link | Filesystem | Expected Exit | Expected Verdict | Reason |
|------|------------|---------------|-----------------|--------|
| `[x](a.md/)` | `a.md` exists as a regular file | 1 | broken | file-not-found (no directory at `a.md/`) |
| `[x](a.md/)` | `a.md` does not exist | 1 | broken | file-not-found |
| `[x](docs/)` | `docs/` is a directory | 0 | clean | BC-2.07.005 — directory link, no fragment |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-024 | `path_resolver` trailing-slash-on-file invariant — `File` entry + trailing slash → `broken(file-not-found)`, never `target-is-directory` | proptest |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-007 ("Relative Path Resolution") per capabilities.md §CAP-007 |
| Capability Anchor Justification | CAP-007 ("Relative Path Resolution") per capabilities.md §CAP-007 — this BC defines path resolution behavior for trailing-slash destinations |
| L2 Domain Invariants | DI-005 |
| Brief Requirement | R2a |
| Architecture Module | `path_resolver.rs` (SS-07, pure core, CRITICAL tier) — ADR-006 (NFC strict path model) |

## Related BCs
- BC-2.07.005 — sibling (directory link WITHOUT trailing-slash oddity; verdict is clean when no fragment)
- BC-2.07.001 — sibling (relative path resolution — happy path)
- BC-2.07.007 — sibling (empty destination → malformed-url)
