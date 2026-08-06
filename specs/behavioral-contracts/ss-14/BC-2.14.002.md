---
document_type: behavioral-contract
level: L3
version: "1.0"
status: draft
producer: vsdd-factory:product-owner
timestamp: 2026-08-05T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/specs/domain-spec/L2-INDEX.md
  - .factory/planning/brief-validation.md
  - .factory/planning/market-intelligence.md
input-hash: "79b9564"
traces_to: .factory/specs/domain-spec/L2-INDEX.md
origin: greenfield
extracted_from: null
subsystem: "SS-14"
capability: "CAP-014"
lifecycle_status: active
introduced: v1.0.0
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.14.002: Exit Code 2 Takes Precedence Over Exit Code 1

## Description
Exit code 2 (usage error or I/O error) takes strict precedence over exit code 1 (broken links).
If a run produces both broken links AND an I/O error, the process exits 2. This is DI-011.

## Preconditions
1. All scanning and reporting is complete.
2. At least one I/O error or usage error occurred (would set exit 2).
3. At least one broken link was also found (would set exit 1).

## Postconditions
1. Process exit code: 2.
2. Both the broken finding(s) AND the I/O error finding(s) are reported in output.
3. The summary line on stderr reflects the broken count (for text format).

## Invariants
1. Exit 2 ALWAYS beats exit 1. No exception. (DI-011)
2. No fail-fast: even with I/O errors, the scan continues for all other files.
3. The final exit code is the maximum of (0, any 1-triggering events, any 2-triggering events).

## Edge Cases
| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-141b | 1 broken link + invalid `--format` flag | Exit 2; usage error |

## Canonical Test Vectors
| Scenario | Expected Exit |
|----------|--------------|
| 1 broken link + 1 unreadable file | 2 |
| 1 broken link, no I/O errors | 1 |
| 1 unreadable file, no broken links | 2 |
| All clean | 0 |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-005 | Exit 2 beats exit 1 | unit test |
| VP-005 | No fail-fast: broken links still reported with I/O error | unit test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-014 ("Exit 2 takes precedence over exit 1; no fail-fast") per capabilities.md §CAP-014 |
| Capability Anchor Justification | CAP-014 ("Exit Code Determination") per capabilities.md §CAP-014 |
| L2 Domain Invariants | DI-011 |
| Brief Requirement | R7, DD-007, BV-005 |
