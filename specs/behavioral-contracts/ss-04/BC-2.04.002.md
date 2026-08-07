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
subsystem: "SS-04"
capability: "CAP-004"
lifecycle_status: active
introduced: v1.0.0
modified:
  - "v1.1: (F-007) VP-TBD backfill from VP-INDEX v1.1"
  - "v1.2: (INC-MAP) Architecture Module field filled per bc-module-map.md (architect, Phase 1b)"
  - "v1.3: (WS-4-B) Proof-method join repair: both VP-014 rows 'unit test' → 'integration' (VP-INDEX authority)."
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.04.002: Indented Code Blocks and HTML Comments Yield No Links

## Description
Links inside 4-space indented code blocks and inside HTML comments (`<!-- ... -->`) are never 
extracted. These are the two most likely sources of false positives in real repositories that 
use regex-based link extraction.

## Preconditions
1. A file contains links inside 4-space indented blocks or HTML comments.

## Postconditions
1. Zero links are extracted from 4-space indented code block content.
2. Zero links are extracted from HTML comment content.
3. `<pre>` and `<code>` HTML elements also yield no link extraction.

## Invariants
1. 4-space indented blocks are only recognized outside of continuation contexts (CommonMark rules). pulldown-cmark handles this correctly.
2. HTML comments are represented as `Event::Html` / `Event::InlineHtml` events containing `<!--`; links within are not parsed as structured events.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-106 | 4-space indented `[x](missing.md)` |
| EC-110 | `<!-- [x](missing.md) -->` HTML comment |
| EC-111 | `<pre>[x](missing.md)</pre>` |

## Canonical Test Vectors
| Input | Expected Output | Category |
|-------|----------------|----------|
| `    [x](missing.md)` (4-space indent) | Exit 0; no findings | happy-path |
| `<!-- [x](missing.md) -->` | Exit 0; no findings | edge-case |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-014 | Indented code blocks yield no links | integration |
| VP-014 | HTML comments yield no links | integration |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-004 ("indented code blocks (4-space), HTML `<pre>`/`<code>`, HTML comments") per capabilities.md §CAP-004 |
| Capability Anchor Justification | CAP-004 ("Code Context Exclusion") per capabilities.md §CAP-004 |
| L2 Domain Invariants | DI-004 |
| Brief Requirement | R4, AMB-071 |
| Architecture Module | `link_extractor.rs` (SS-04, pure core, CRITICAL tier) — ADR-003 (pulldown-cmark structural event types for code context exclusion) |
| Stories | [filled by story-writer] |
