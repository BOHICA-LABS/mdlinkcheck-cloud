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
input-hash: "19b62d8"
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

# BC-2.14.001: Exit Code 0 — No Broken Links

## Description
The process exits 0 when all links are either clean or indeterminate, and no I/O or usage errors
occurred. This is the success exit code.

## Preconditions
1. All scanning and reporting is complete.
2. No `broken` verdict links were found.
3. No I/O errors occurred (no `target-unreadable`).
4. No usage errors occurred (no invalid flags, no nonexistent PATH).

## Postconditions
1. Process exit code: 0.
2. Indeterminate findings may have been emitted to stdout but do NOT cause exit 1 or 2.
3. `No broken links found.` on stderr (always emitted; --quiet is a non-goal per D-011).

## Invariants
1. Exit 0 means: the tool found no definitively broken links.
2. Exit 0 is consistent with having indeterminate findings.
3. Zero files found → exit 0 (EC-009).

## Edge Cases
| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-142 | Scan with 0 findings | Exit 0 |
| EC-143 | Scan with indeterminate findings only | Exit 0 |
| EC-009 | Empty directory (no .md files) | Exit 0 |

## Canonical Test Vectors
| Scenario | Expected Exit |
|----------|--------------|
| All links clean | 0 |
| All links indeterminate | 0 |
| No markdown files found | 0 |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-006 | Exit 0 with only indeterminate findings | unit test |
| VP-006 | Exit 0 with no files | unit test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-014 ("Determine final exit code from scan results: 0 no broken links, 1 broken links, 2 usage/IO error") per capabilities.md §CAP-014 |
| Capability Anchor Justification | CAP-014 ("Exit Code Determination") per capabilities.md §CAP-014 |
| L2 Domain Invariants | DI-010, DI-011 |
| Brief Requirement | R7 |
