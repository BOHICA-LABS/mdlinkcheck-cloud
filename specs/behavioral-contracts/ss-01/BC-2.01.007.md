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

# BC-2.01.007: Path Deduplication for Overlapping PATH Arguments

## Description
When multiple PATH arguments refer to the same file (directly or via directory nesting), the file 
is included in the scan set exactly once. Findings for that file are reported once, not once per 
occurrence in the PATH arguments.

## Preconditions
1. Two or more PATH arguments are provided.
2. At least two of them resolve (via traversal) to the same canonical file path.

## Postconditions
1. Each canonical file path appears in the scan set exactly once.
2. Findings for deduplicated files are reported once in output.
3. Deduplication is based on the canonicalized real path (resolves `.`, `..`, symlinks).

## Invariants
1. Deduplication is applied before scanning, not during result collection.
2. The scan set is a set (no duplicates), not a list (with duplicates).

## Edge Cases
| EC | Description |
|----|-------------|
| EC-010 | `mdlinkcheck . docs docs/a.md` |

## Canonical Test Vectors
| Input | Expected Output | Category |
|-------|----------------|----------|
| `mdlinkcheck . docs/` (overlapping) with 1 broken link in docs/a.md | Exit 1; 1 finding (not 2) | happy-path |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | Scan set is a proper set of canonical paths | unit test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-001 ("File Discovery") per capabilities.md §CAP-001 |
| Capability Anchor Justification | CAP-001 ("File Discovery") per capabilities.md §CAP-001 |
| Brief Requirement | R1, AMB-008 |
| Architecture Module | `scanner.rs` (SS-01, effectful shell, HIGH tier) — ADR-005 (rayon traversal) |
| Stories | [filled by story-writer] |

## Related BCs
- BC-2.01.002 — composes with (explicit PATH handling)
