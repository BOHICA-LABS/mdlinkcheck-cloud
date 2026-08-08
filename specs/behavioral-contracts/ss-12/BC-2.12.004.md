---
document_type: behavioral-contract
level: L3
version: "1.5"
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
subsystem: "SS-12"
capability: "CAP-012"
lifecycle_status: active
introduced: v1.0.0
modified:
  - v1.4: "WS-4 Shard E: POLICY-5 repair — L2 Capability fabricated quote replaced with verbatim CAP-012 title (dropped appended '; --format text explicit alias accepted' clause)."
  - "v1.1: (INC-MAP) Architecture Module field added per bc-module-map.md (architect, Phase 1b)"
  - "v1.3: (P4-016) Removed incorrect SS-11 subsystem label from cli.rs secondary module reference."
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.12.004: `--format text` Explicit Alias Is Accepted

## Description
The default output format is text. `--format text` is an explicit alias that produces identical
output to the default. Any value other than `text` or `json` for `--format` causes exit 2 with
a usage error.

## Preconditions
1. `--format <value>` has been provided on the command line.

## Postconditions
1. `--format text` (or no `--format` flag): text output.
2. `--format json`: JSON output (see BC-2.13.001).
3. Any other value (e.g., `--format xml`, `--format TEXT`): exit 2; usage error on stderr.
4. `--format` is case-sensitive: `text` and `json` are lowercase only.

## Invariants
1. Exactly two valid values: `text` and `json`.
2. Invalid value triggers exit 2 immediately, before any scanning begins.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-134 | `--format text` |
| EC-135 | `--format xml` |
| EC-136 | `--format TEXT` (uppercase) |
| EC-137 | `--format json --format text` |

## Canonical Test Vectors
| Flag | Expected |
|------|---------|
| (no --format) | text output |
| `--format text` | text output |
| `--format json` | JSON output |
| `--format xml` | exit 2; usage error |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | Invalid --format value → exit 2 | unit test |
| test-sufficient | Last --format wins when repeated | unit test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-012 ("Text Report Generation") per capabilities.md §CAP-012 |
| Capability Anchor Justification | CAP-012 ("Text Report Generation") per capabilities.md §CAP-012 |
| Brief Requirement | R6, AMB-092 |
| Architecture Module | `cli.rs` (effectful shell, LOW tier) primary; `reporter.rs` (SS-12, pure core, HIGH tier) secondary — `--format text` flag selects format_text — ADR-005 |
