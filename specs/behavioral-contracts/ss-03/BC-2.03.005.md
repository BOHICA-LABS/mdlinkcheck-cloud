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
input-hash: "07d983a"
traces_to: .factory/specs/domain-spec/L2-INDEX.md
origin: greenfield
extracted_from: null
subsystem: "SS-03"
capability: "CAP-003"
lifecycle_status: active
introduced: v1.0.0
modified:
  - "v1.1: (F-007) VP-TBD backfill from VP-INDEX v1.1"
  - "v1.2: (INC-MAP) Architecture Module field filled per bc-module-map.md (architect, Phase 1b)"
  - "v1.3: (WS-4-B) Citation-authority repair: L2 Capability row — fabricated excerpt 'non-http (silently skipped per DD-009)' (backtick markup stripped from source text \\`non-http\\`) replaced with verbatim title 'Link Extraction'; gloss moved outside quotes."
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.03.005: Non-http(s) Schemes Silently Skipped with `clean` Verdict

## Description
Link destinations with non-http(s) schemes (mailto:, ftp:, tel:, data:, vscode:, 
protocol-relative //host/path) are silently skipped. They receive a `clean` verdict 
and are not emitted in output. This is intentional scope-boundary behavior (DD-009).

## Preconditions
1. An extracted link has a destination that begins with a non-http(s) scheme.

## Postconditions
1. The link is NOT checked (no filesystem lookup, no URL fetch).
2. The link is NOT emitted in output (neither text nor JSON).
3. Effective verdict: `clean`.

## Invariants
1. Non-http(s) schemes are silently skipped, not warned about. No diagnostic is emitted.
2. `--allow` has no effect on non-http(s) links (they're already skipped).

## Edge Cases
| EC | Description |
|----|-------------|
| EC-173 | `mailto:a@b.com` |
| EC-174 | `ftp://x/y` |
| EC-175 | `tel:+15551234` |
| EC-176 | `javascript:void(0)` |
| EC-177 | `//example.com/x` (protocol-relative) |

## Canonical Test Vectors
| Input | Expected Output | Category |
|-------|----------------|----------|
| `[email](mailto:user@example.com)` | Exit 0; no findings | happy-path |
| `[ftp](ftp://files.example.com/file.zip)` | Exit 0; no findings | edge-case |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | All non-http(s) schemes produce no findings | unit test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-003 ("Link Extraction") per capabilities.md §CAP-003 — non-http scheme links silently skipped per DD-009 |
| Capability Anchor Justification | CAP-003 ("Link Extraction") per capabilities.md §CAP-003 |
| Brief Requirement | R2c, DD-009 |
| Architecture Module | `url_classifier.rs` (SS-09, pure core, HIGH tier) primary; `link_extractor.rs` (SS-03) secondary — INC-MAP-002: non-http clean verdict is `url_classifier` classification; story must assert both link extraction (link_extractor) and url_classifier classification behavior — ADR-003, ADR-007 |
| Stories | [filled by story-writer] |
