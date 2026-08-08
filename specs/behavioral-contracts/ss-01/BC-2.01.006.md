---
document_type: behavioral-contract
level: L3
version: "1.2"
status: draft
producer: vsdd-factory:product-owner
timestamp: 2026-08-05T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/specs/domain-spec/L2-INDEX.md
  - .factory/planning/brief-validation.md
  - .factory/planning/market-intelligence.md
input-hash: "c3e82ce"
traces_to: .factory/specs/domain-spec/L2-INDEX.md
origin: greenfield
extracted_from: null
subsystem: "SS-01"
capability: "CAP-001"
lifecycle_status: active
introduced: v1.0.0
modified:
  - "v1.1: (INC-MAP) Architecture Module field filled per bc-module-map.md (architect, Phase 1b)"
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.01.006: File Symlink Following with Dangling-Symlink Detection

## Description
Symlinks pointing to files (not directories) are followed during traversal. If the symlink target 
does not exist (dangling symlink), any link to that symlink target is reported as `broken-symlink`.
Directory symlinks are never followed (BC-2.01.004).

## Preconditions
1. A filesystem entry is a symlink pointing to a file.
2. The file may or may not exist at the symlink target path.

## Postconditions
1. If the symlink target exists: the file is included in the scan set and processed normally.
2. If the symlink target does not exist (dangling): any Markdown link to this path receives verdict `broken` with reason `broken-symlink`.

## Invariants
1. `Path::exists()` follows symlinks; after confirming existence, exact-case directory-entry comparison is still applied (DI-002).
2. `broken-symlink` is distinct from `file-not-found` in the reason taxonomy.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-038 | `[x](link.md)` where `link.md` is a dangling symlink |
| EC-028b | Symlink to valid file |

## Canonical Test Vectors
| Input | Expected Output | Category |
|-------|----------------|----------|
| `a.md` with `[x](link.md)`; `link.md` is dangling symlink | Exit 1; reason `broken-symlink` | happy-path |
| `a.md` with `[x](link.md)`; `link.md` is symlink to valid `target.md` | Exit 0; clean | happy-path |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | Dangling symlink always produces broken-symlink reason | unit test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-001 ("File Discovery") per capabilities.md §CAP-001 |
| Capability Anchor Justification | CAP-001 ("File Discovery") per capabilities.md §CAP-001 — symlink handling is part of discovery traversal |
| Brief Requirement | R1, AMB-007, AMB-028 |
| Architecture Module | `scanner.rs` (SS-01, effectful shell, HIGH tier) — ADR-005 (rayon traversal) |
| Stories | [filled by story-writer] |

## Related BCs
- BC-2.01.004 — related to (dir symlinks not followed; this BC covers file symlinks)
- BC-2.07.001 — related to (path resolution checks existence)
