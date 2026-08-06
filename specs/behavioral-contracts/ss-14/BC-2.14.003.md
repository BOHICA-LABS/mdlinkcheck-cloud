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
input-hash: "e860246"
traces_to: .factory/specs/domain-spec/L2-INDEX.md
origin: greenfield
extracted_from: null
subsystem: "SS-14"
capability: "CAP-014"
lifecycle_status: active
introduced: v1.0.0
modified:
  - "v1.1: Three-input model alignment — Preconditions 3 and 4 now cite verdict::exit_code parameter names (io_errors and config_error). Precondition 3 clarifies that nonexistent PATH arguments count as I/O errors. Architect v1.4 reconciliation."
  - "v1.2: (INC-MAP) Architecture Module field added per bc-module-map.md (architect, Phase 1b)"
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
3. No I/O errors occurred — no unreadable files and no nonexistent PATH arguments. (Corresponds to `io_errors = []` in `verdict::exit_code`. A nonexistent PATH argument is an I/O error, not a startup config error.)
4. No startup configuration errors occurred — no unrecognized flags and no invalid `--ignore` glob pattern. (Corresponds to `config_error = false` in `verdict::exit_code`.)

## Postconditions
1. Process exit code: 1.
2. Broken findings are reported in stdout output.
3. Summary line on stderr: `N broken link(s) in M file(s).`

## Invariants
1. Only `broken` verdict links trigger exit 1. `indeterminate` does not.
2. Exit 1 is preempted by exit 2 (BC-2.14.002).
3. CI pipelines that check exit code can rely on: 0=success, 1=broken, 2=error.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-144 | 1 broken link, 0 I/O errors |
| EC-145 | 100 broken links, 0 I/O errors |
| EC-146 | 0 broken links, 1 indeterminate |

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
| Architecture Module | `verdict.rs` (SS-14, pure core, CRITICAL tier) — ADR-007 (two-layer verdict model) |
