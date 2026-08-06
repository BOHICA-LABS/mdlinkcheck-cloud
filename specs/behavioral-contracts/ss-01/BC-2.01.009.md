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
  - .factory/planning/brief-validation.md
  - .factory/planning/market-intelligence.md
input-hash: "a53c532"
traces_to: .factory/specs/domain-spec/L2-INDEX.md
origin: greenfield
extracted_from: null
subsystem: "SS-01"
capability: "CAP-001"
lifecycle_status: active
introduced: v1.0.0
modified:
  - "v1.1: P2-C06 — aligned nonexistent PATH behavior with DD-007 no-fail-fast: record error and continue scanning for remaining valid paths; exit 2 after all scanning completes. Error class changed from E-CLI-001 to E-IO-002."
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.01.009: Non-Existent or Unreadable PATH Argument Yields Exit 2

## Description
If a PATH argument does not exist on the filesystem, or if a `.md` file exists but cannot be read 
(permission denied, non-UTF-8, etc.), the tool emits an error on stderr and produces exit code 2. 
For I/O errors on individual files, the scan continues for other files — no fail-fast (DD-007, DI-011).

## Preconditions
1. A PATH argument is provided OR a file is encountered during traversal.
2. The path does not exist, OR exists but cannot be read.

## Postconditions
1. For a nonexistent PATH argument: an `E-IO-002` error is recorded; an error message is emitted on stderr; scanning continues for all remaining valid PATH arguments (DD-007 no-fail-fast); exit code is 2 after all scanning completes.
2. For an unreadable file encountered during scan: a `target-unreadable` I/O error is recorded; scan continues for all other files; final exit code is 2 (regardless of whether broken links were also found — exit 2 takes precedence per DI-011).
3. Findings from successfully scanned files are still emitted in output.

## Invariants
1. Exit 2 takes precedence over exit 1 (DI-011). If both broken links and I/O errors occur, exit is 2.
2. I/O error on one file does NOT abort the scan. Remaining files are processed. (DD-007)
3. `target-unreadable` is emitted in output to identify which file caused the I/O error.

## Edge Cases
| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-012 | `mdlinkcheck /does/not/exist` | Exit 2; error on stderr before scan begins |
| EC-013 | File with mode 000 encountered in traversal | Exit 2; `target-unreadable` finding; other files scanned |

## Canonical Test Vectors
| Input | Expected Output | Category |
|-------|----------------|----------|
| `mdlinkcheck /nonexistent` | Exit 2; stderr error | happy-path |
| Scan with 3 .md files; 1 unreadable (mode 000); 1 has broken link | Exit 2; broken finding + unreadable finding | edge-case |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-005 | Exit 2 when any I/O error occurs; exit 2 beats exit 1 | unit/integration test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-001 ("File Discovery") per capabilities.md §CAP-001 |
| Capability Anchor Justification | CAP-001 ("File Discovery") per capabilities.md §CAP-001 — nonexistent PATH handling is part of the discovery contract |
| L2 Domain Invariants | DI-011 |
| Brief Requirement | R1, R7, BV-005, AMB-010, AMB-011 |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |

## Related BCs
- BC-2.14.002 — depends on (exit code 2 precedence rule)
