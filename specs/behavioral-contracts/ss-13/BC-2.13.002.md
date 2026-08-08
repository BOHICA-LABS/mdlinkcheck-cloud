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
input-hash: "07d983a"
traces_to: .factory/specs/domain-spec/L2-INDEX.md
origin: greenfield
extracted_from: null
subsystem: "SS-13"
capability: "CAP-013"
lifecycle_status: active
introduced: v1.0.0
modified:
  - "v1.1: (INC-MAP) Architecture Module field added per bc-module-map.md (architect, Phase 1b)"
  - "v1.2: (WS-4/POLICY-5) L2 Capability fabricated quotation repaired: replaced invented excerpt with verbatim CAP-013 heading per capabilities.md §CAP-013; gloss moved outside quotes"
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.13.002: JSON Schema Stability Contract

## Description
The JSON output schema (`schema_version: 1`) is pre-1.0 unstable. No backwards-compatibility
guarantee exists until v1.0 release. After v1.0, adding/removing/renaming any field in the
`results` objects requires incrementing `schema_version`. Consumers must check `schema_version`
before parsing.

## Preconditions
1. JSON output has been produced.
2. A consumer is parsing the output.

## Postconditions
1. `schema_version` is always present as the first field in the JSON object.
2. All field names in `results` objects are stable across patch versions once v1.0 ships.
3. Reason codes in the `reason` field are from the closed taxonomy (error-taxonomy.md); they are stable once v1.0 ships.
4. Human-readable message strings (text output) are NOT stable; automation must use `reason` codes.

## Invariants
1. `schema_version` is an integer, always 1 for the current implementation.
2. A consumer that checks `if schema_version != 1 { error }` is robust.
3. The `verdict` field only ever contains `"broken"` or `"indeterminate"`.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-170 | Future version changes schema |

## Canonical Test Vectors
| Scenario | Expected |
|----------|---------|
| Parse JSON output | `schema_version` is integer 1; `results` is array |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | schema_version always present and integer | unit test |
| test-sufficient | verdict only "broken" or "indeterminate" | unit test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-013 ("JSON Report Generation") per capabilities.md §CAP-013 — schema stability contract: schema_version field; reason codes stable after v1.0 |
| Capability Anchor Justification | CAP-013 ("JSON Report Generation") per capabilities.md §CAP-013 |
| Brief Requirement | R6, NFR-007 |
| Architecture Module | `reporter.rs` (SS-13, pure core, HIGH tier) — ADR-005 (sort-before-emit), ADR-007 (verdict model) |
