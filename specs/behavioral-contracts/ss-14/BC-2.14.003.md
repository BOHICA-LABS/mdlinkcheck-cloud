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

# BC-2.14.003: Exit Code 1 — At Least One Broken Link Found

## Description
The process exits 1 when at least one link received a `broken` verdict AND no I/O or usage
errors occurred (which would trigger exit 2). Exit 1 means: the tool definitively found broken
links; the calling script should treat this as a CI failure.

## Preconditions
1. All scanning and reporting is complete.
2. At least one link received verdict `broken`.
3. No I/O errors occurred.
4. No usage errors occurred.

## Postconditions
1. Process exit code: 1.
2. Broken findings are reported in stdout output.
3. Summary line on stderr: `N broken link(s) in M file(s).`

## Invariants
1. Only `broken` verdict links trigger exit 1. `indeterminate` does not.
2. Exit 1 is preempted by exit 2 (BC-2.14.002).
3. CI pipelines that check exit code can rely on: 0=success, 1=broken, 2=error.

## Edge Cases
| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-144 | 1 broken link, 0 I/O errors | Exit 1 |
| EC-145 | 100 broken links, 0 I/O errors | Exit 1 |
| EC-146 | 0 broken links, 1 indeterminate | Exit 0 |

## Canonical Test Vectors
| Scenario | Expected Exit |
|----------|--------------|
| 1 file-not-found broken link | 1 |
| 1 anchor-not-found broken link | 1 |
| 1 indeterminate only | 0 |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-005 | Exit 1 when broken links found, no I/O errors | unit test |
| VP-006 | Indeterminate does not trigger exit 1 | unit test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-014 ("Exit 1: at least one broken link; exit 0: no broken links") per capabilities.md §CAP-014 |
| Capability Anchor Justification | CAP-014 ("Exit Code Determination") per capabilities.md §CAP-014 |
| L2 Domain Invariants | DI-010, DI-011 |
| Brief Requirement | R7 |
