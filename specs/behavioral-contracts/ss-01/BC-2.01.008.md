---
document_type: behavioral-contract
level: L3
version: "1.4"
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
  - "v1.1: P2-m04/REGRESSION-003 — removed .markdown extension reference from Description; removed --quiet reference from Invariant 2 (D-011: --quiet is a non-goal; the message is always emitted)"
  - "v1.2: (INC-MAP) Architecture Module field filled per bc-module-map.md (architect, Phase 1b)"
  - "v1.3: (EC-collision) EC-009 renamed to EC-184 (EC-009 canonical owner is BC-2.01.004 per test-vectors.md registry)."
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.01.008: Zero Markdown Files Found Yields Exit 0 with Stderr Message

## Description
When traversal completes and no `.md` files were found (after all filters applied),
the tool exits 0 and emits an informational message on stderr. This is not an error — an empty
repo or a filtered-out-everything case is a valid state.

## Preconditions
1. Traversal has completed.
2. The scan set is empty (zero files).

## Postconditions
1. Exit code is 0.
2. Stdout is empty (no findings).
3. Stderr contains an informational message: `No markdown files found.`

## Invariants
1. Exit 0 does not change if no files are found — the tool has not observed any broken links.
2. The stderr message is always emitted; there is no `--quiet` flag (D-011). The message is informational, not a warning.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-184 | Directory exists but has zero .md files |
| EC-125 | `--ignore '*.md'` excludes all files |

## Canonical Test Vectors
| Input | Expected Output | Category |
|-------|----------------|----------|
| `mdlinkcheck` in empty directory | Exit 0; stderr: "No markdown files found." | happy-path |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | Exit 0 when scan set is empty | unit test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-001 ("File Discovery") per capabilities.md §CAP-001 |
| Capability Anchor Justification | CAP-001 ("File Discovery") per capabilities.md §CAP-001 |
| L2 Domain Invariants | DI-009 |
| Brief Requirement | R1, R7, AMB-009 |
| Architecture Module | `scanner.rs` (SS-01, effectful shell, HIGH tier) — ADR-005 (rayon traversal) |
| Stories | [filled by story-writer] |
