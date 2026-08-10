---
document_type: behavioral-contract
level: L3
version: "1.6"
status: draft
producer: vsdd-factory:product-owner
timestamp: 2026-08-10T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/specs/domain-spec/L2-INDEX.md
  - .factory/planning/brief-validation.md
  - .factory/planning/market-intelligence.md
input-hash: "07d983a"
traces_to: .factory/specs/domain-spec/L2-INDEX.md
origin: greenfield
extracted_from: null
subsystem: "SS-01"
capability: "CAP-001"
lifecycle_status: active
introduced: v1.0.0
modified:
  - "v1.1: P2-C06 — aligned nonexistent PATH behavior with DD-007 no-fail-fast: record error and continue scanning for remaining valid paths; exit 2 after all scanning completes. Error class changed from E-CLI-001 to E-IO-002."
  - "v1.2: P2-C06 convergence with architect v1.4 — EC-012 corrected: removed 'before scan begins' wording that implied immediate abort. A nonexistent PATH argument is a runtime I/O error recorded into Vec<IoError>; it is NOT a startup configuration error and does NOT cause immediate exit. Added mixed-case test vector (EC-014) that distinguishes the two readings: good_dir IS scanned and its findings ARE reported; exit 2 is produced at the end because exit 2 beats exit 1. Description rewritten to make no-fail-fast explicit for all I/O error classes."
  - "v1.3: (INC-MAP) Architecture Module field filled per bc-module-map.md (architect, Phase 1b)"
  - "v1.4: (EC-collision) EC-014 renamed to EC-185 (EC-014 canonical owner is BC-2.02.003 per test-vectors.md registry)."
  - "v1.5: (WS-4/POLICY-5) Proof-method join repair — VP-005 Proof Method corrected from 'unit/integration test' to 'kani' per VP-INDEX authority."
  - "v1.6: (GATE-58/CLOSED-WORLD) E-IO-002 phantom code retired (D-117); all citations corrected to target-unreadable per error-taxonomy.md §6.1 three-condition conflation."
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.01.009: Non-Existent or Unreadable PATH Argument Yields Exit 2

## Description
A nonexistent PATH argument and an unreadable file encountered during scan are both classified as
runtime I/O errors. Both are recorded into `Vec<IoError>` and neither causes an immediate abort.
Scanning continues for all remaining valid paths (DD-007 no-fail-fast); exit code 2 is produced
after ALL scanning completes. A nonexistent PATH argument is NOT a startup configuration error —
it does not exit before traversal begins. The distinguishing behavior: `mdlinkcheck good_dir/
nonexistent_dir/` fully scans `good_dir/`, emits its broken-link findings, emits a `target-unreadable` error
for `nonexistent_dir/`, and exits 2 (exit 2 beats exit 1 per DI-011).

## Preconditions
1. A PATH argument is provided OR a file is encountered during traversal.
2. The path does not exist, OR exists but cannot be read.

## Postconditions
1. For a nonexistent PATH argument: a `target-unreadable` error is recorded; an error message is emitted on stderr; scanning continues for all remaining valid PATH arguments (DD-007 no-fail-fast); exit code is 2 after all scanning completes.
2. For an unreadable file encountered during scan: a `target-unreadable` I/O error is recorded; scan continues for all other files; final exit code is 2 (regardless of whether broken links were also found — exit 2 takes precedence per DI-011).
3. Findings from successfully scanned files are still emitted in output.

## Invariants
1. Exit 2 takes precedence over exit 1 (DI-011). If both broken links and I/O errors occur, exit is 2.
2. I/O error on one file does NOT abort the scan. Remaining files are processed. (DD-007)
3. `target-unreadable` is emitted in output to identify which file caused the I/O error.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-012 | `mdlinkcheck /does/not/exist` (single nonexistent PATH, no other paths) |
| EC-013 | File with mode 000 encountered in traversal |
| EC-185 | `mdlinkcheck good_dir/ nonexistent_dir/` — `good_dir/` has one broken link; `nonexistent_dir/` does not exist |

## Canonical Test Vectors
| Input | Expected Output | Category |
|-------|----------------|----------|
| `mdlinkcheck /nonexistent` | Exit 2; `target-unreadable` on stderr; no findings on stdout | happy-path |
| Scan with 3 .md files; 1 unreadable (mode 000); 1 has broken link | Exit 2; broken finding + unreadable finding on stdout/stderr | edge-case |
| `mdlinkcheck good_dir/ nonexistent_dir/` (good_dir has 1 broken link; nonexistent_dir absent) | Exit 2; broken finding from good_dir on stdout; `target-unreadable` for nonexistent_dir on stderr; good_dir fully scanned (EC-185 distinguishing vector) | distinguishing |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-005 | Exit 2 when any I/O error occurs; exit 2 beats exit 1 | kani |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-001 ("File Discovery") per capabilities.md §CAP-001 |
| Capability Anchor Justification | CAP-001 ("File Discovery") per capabilities.md §CAP-001 — nonexistent PATH handling is part of the discovery contract |
| L2 Domain Invariants | DI-011 |
| Brief Requirement | R1, R7, BV-005, AMB-010, AMB-011 |
| Architecture Module | `scanner.rs` (SS-01, effectful shell, HIGH tier) primary; `verdict.rs` (SS-14, pure core, CRITICAL tier) secondary — I/O errors become exit 2 via `verdict::exit_code` — ADR-005, ADR-007 |
| Stories | [filled by story-writer] |

## Related BCs
- BC-2.14.002 — depends on (exit code 2 precedence rule)
