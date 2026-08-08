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
subsystem: "SS-11"
capability: "CAP-011"
lifecycle_status: active
introduced: v1.0.0
modified:
  - v1.3: "DI-006 four-mechanism note added to Invariants."
  - "v1.1: (INC-MAP) Architecture Module field added per bc-module-map.md (architect, Phase 1b)"
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.11.003: `--ignore` on Explicit PATH Argument

## Description
Per the interface-definitions.md §8 flag interaction rule, if a file is passed as an explicit
PATH argument AND also matches an `--ignore` glob, the `--ignore` wins — the file is excluded
as a link source. This ensures `--ignore` patterns behave predictably regardless of how files
entered the scan set.

## Preconditions
1. A file was passed as an explicit PATH argument.
2. The file's path also matches a `--ignore` glob.

## Postconditions
1. The file is excluded as a link source.
2. The file is NOT scanned for links.
3. The file's anchor table IS built (DI-006).
4. No links from this file are reported.

## Invariants
1. `--ignore` wins over explicit PATH. Always.
2. This is a deliberate design decision for script-friendly behavior.
3. **DI-006 context:** Same as BC-2.11.001 Invariant 4 — `--ignore` exclusion (even over
   explicit PATH) is DI-006 case 1. The excluded file's anchor table IS still built (Pass 1
   traversal). It remains a valid anchor target.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-073b | `mdlinkcheck vendor/lib.md --ignore vendor/**` |

## Canonical Test Vectors
| Command | Expected |
|---------|---------|
| `mdlinkcheck vendor/lib.md --ignore 'vendor/**'` (lib.md has broken link) | Exit 0; no findings |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | --ignore wins over explicit PATH | unit test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-011 ("Filter Application") per capabilities.md §CAP-011 |
| Capability Anchor Justification | CAP-011 ("Filter Application") per capabilities.md §CAP-011 |
| Brief Requirement | R5 |
| Architecture Module | `filter.rs` (SS-11, pure core, HIGH tier) primary; `scanner.rs` (SS-01, effectful, HIGH tier) secondary — applies filter to explicit PATH arguments during traversal — ADR-007 |
