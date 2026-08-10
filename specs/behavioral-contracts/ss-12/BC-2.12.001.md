---
document_type: behavioral-contract
level: L3
version: "1.4"
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
subsystem: "SS-12"
capability: "CAP-012"
lifecycle_status: active
introduced: v1.0.0
modified:
  - v1.4: "(GATE-58/POL-14) VP-NNN column bare em-dash is non-conforming per POL-14; replaced with VP-NONE (D-078) — proof method is integration, so VP-NONE is accepted."
  - v1.3: "(BI-052 remediation P7-S12-001) VP-021 row corrected: 'Clean links produce no output' was attributed to VP-021 but VP-021 proves the text-format sort ordering property (trap T15); it does not specifically assert that clean links are absent from output. That property is verified by the acceptance corpus integration tests. Row changed to bare dash."
  - v1.2: "WS-4 Shard E: POLICY-5 repair — L2 Capability fabricated quote replaced with verbatim CAP-012 title ('Text Report Generation'); VP-021 proof method corrected to 'integration' (was 'unit test') per VP-INDEX authority."
  - "v1.1: (INC-MAP) Architecture Module field added per bc-module-map.md (architect, Phase 1b)"
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.12.001: Text Report Format — One Finding per Line, Deterministic Order

## Description
The text report (default format) emits one line per finding to stdout, in the format
`<file>:<line>: <link_target> — <reason>`. Findings are sorted deterministically by
(NFC-normalized file path, line number, column number, link_target) ascending. Clean links are never emitted.

## Preconditions
1. All link validation is complete.
2. Output format is `text` (the default).

## Postconditions
1. Each broken or indeterminate finding produces exactly one line on stdout.
2. Format: `<file>:<line>: <link_target> — <reason>`
3. Indeterminate findings are prefixed: `<file>:<line>: <link_target> — [indeterminate] <reason>`
4. Clean links produce no output lines.
5. Findings are sorted by (NFC file path asc, line asc, column asc, link_target asc).

## Invariants
1. Sort order is deterministic across parallel scans (DI-001).
2. The sort is by NFC-normalized path (same NFC normalization as DI-002).
3. `<file>` is CWD-relative, NFC-normalized, forward-slash separated on all platforms.
4. Two runs with identical inputs produce byte-identical stdout (NFR-003).

## Edge Cases
| EC | Description |
|----|-------------|
| EC-124 | Multiple findings in same file |

## Canonical Test Vectors
| Findings | Expected Output Lines |
|---------|-----------------------|
| `a.md:5: missing.md — file-not-found` and `a.md:3: x.md — file-not-found` | Line 3 first, then line 5 |
| 0 broken links | No output (empty stdout) |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-011 | Deterministic sort (trap T15) | proptest |
| VP-NONE | Clean links produce no output — no current VP; verified by acceptance corpus integration tests | integration |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-012 ("Text Report Generation") per capabilities.md §CAP-012 |
| Capability Anchor Justification | CAP-012 ("Text Report Generation") per capabilities.md §CAP-012 |
| L2 Domain Invariants | DI-001 |
| Brief Requirement | R6 |
| Architecture Module | `reporter.rs` (SS-12, pure core, HIGH tier) — ADR-005 (sort-before-emit; deterministic output order), ADR-007 (verdict model) |
