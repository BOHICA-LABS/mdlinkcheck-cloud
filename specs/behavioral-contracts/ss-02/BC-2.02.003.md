---
document_type: behavioral-contract
level: L3
version: "1.3"
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
subsystem: "SS-02"
capability: "CAP-002"
lifecycle_status: active
introduced: v1.0.0
modified:
  - "v1.1: (F-007) VP-TBD backfill from VP-INDEX v1.1"
  - "v1.2: (INC-MAP) Architecture Module field filled per bc-module-map.md (architect, Phase 1b)"
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.02.003: Non-UTF-8 File Reported as Per-File I/O Error; Scan Continues

## Description
If a file cannot be decoded as valid UTF-8, it is treated as an I/O error (`target-unreadable`) 
and the scan continues for all other files. The run will ultimately exit 2 due to the I/O error.

## Preconditions
1. A file in the scan set contains bytes that are not valid UTF-8.
2. Alternatively, any OS-level read error occurs when reading the file.

## Postconditions
1. The file is not parsed; no links or headings are extracted from it.
2. A `target-unreadable` finding is emitted for the file.
3. The scan continues normally for all other files.
4. Final exit code is 2 (I/O error beats broken link exit 1 per DI-011).

## Invariants
1. Non-UTF-8 is NOT a broken link — it is an I/O error. `target-unreadable` is emitted, not `file-not-found`.
2. The tool does NOT attempt lossy UTF-8 decoding.
3. No fail-fast: remaining files are processed even after this error.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-014 | File containing ISO-8859-1 bytes |

## Canonical Test Vectors
| Input | Expected Output | Category |
|-------|----------------|----------|
| Scan with 2 .md files; 1 valid, 1 non-UTF-8 | Exit 2; `target-unreadable` for bad file; findings from valid file | happy-path |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | Non-UTF-8 file produces target-unreadable; scan continues | unit test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-002 ("Markdown Parsing") per capabilities.md §CAP-002 |
| Capability Anchor Justification | CAP-002 ("Markdown Parsing") per capabilities.md §CAP-002 — parse failure is part of the parsing contract |
| L2 Domain Invariants | DI-011 |
| Brief Requirement | R7, AMB-011 |
| Architecture Module | `scanner.rs` (SS-02, effectful shell, HIGH tier) — ADR-003 (pulldown-cmark event stream) |
| Stories | [filled by story-writer] |

## Related BCs
- BC-2.14.002 — depends on (exit 2 precedence)
- BC-2.01.009 — related to (I/O error handling)
