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
subsystem: "SS-03"
capability: "CAP-003"
lifecycle_status: active
introduced: v1.0.0
modified:
  - "v1.1: (F-007) VP-TBD backfill from VP-INDEX v1.1"
  - "v1.2: (INC-MAP) Architecture Module field filled per bc-module-map.md (architect, Phase 1b)"
  - "v1.3: (WS-4-B) Proof-method join repair: VP-019 'property test' → 'proptest' (VP-INDEX authority); VP-014 'property test' → 'integration' (VP-INDEX authority)."
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.03.001: Inline Link and Image Extraction with Kind Classification

## Description
From the pulldown-cmark AST, all `Tag::Link` and `Tag::Image` events that occur outside code 
contexts are extracted. Each is classified into a kind: relative-file, anchor-only, cross-file-anchor, 
external-http, or non-http (silently skipped). This is the primary extraction path for R2 and R3.

## Preconditions
1. A Markdown file has been parsed into an AST event stream (BC-2.02.001).
2. The current parser position is NOT inside a code context (enforced by structural event matching).

## Postconditions
1. Every `Tag::Link` and `Tag::Image` event outside code contexts produces exactly one extracted link.
2. Each extracted link has: source file, line, column, destination string (raw), link kind.
3. Link kind is determined by the destination string: starts with `http://` or `https://` → external; starts with `#` → anchor-only; contains `#` after a path component → cross-file-anchor; otherwise → relative-file.
4. Images (`Tag::Image`) are extracted and classified identically to links (R3).

## Invariants
1. Code context links are NEVER extracted (DI-004). Since pulldown-cmark's event model nests links inside `Tag::CodeBlock` and `Event::Code` never produces a nested `Tag::Link`, matching only `Tag::Link`/`Tag::Image` satisfies this by construction.
2. Each extracted link receives exactly one verdict (DI-005).

## Edge Cases
| EC | Description |
|----|-------------|
| EC-039 | `[x](logo.png)` |
| EC-040 | `![alt](missing.png)` |
| EC-113 | Link inside GFM table cell |
| EC-115 | Link inside blockquote or nested list |

## Canonical Test Vectors
| Input | Expected Output | Category |
|-------|----------------|----------|
| `[x](docs/a.md)` where `docs/a.md` exists | Clean | happy-path |
| `![img](logo.png)` where `logo.png` does not exist | broken (file-not-found) | edge-case |
| `[x](https://example.com)` offline | clean (syntax valid) | edge-case |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-019 | Every Tag::Link/Tag::Image outside code context is extracted | proptest |
| VP-014 | No Tag::Link/Tag::Image inside code context is extracted | integration |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-003 ("extract all links (inline, reference-style, collapsed, shortcut, image) that fall outside code contexts") per capabilities.md §CAP-003 |
| Capability Anchor Justification | CAP-003 ("Link Extraction") per capabilities.md §CAP-003 — this BC is the core inline-extraction contract |
| L2 Domain Invariants | DI-004, DI-005 |
| Brief Requirement | R2, R3 |
| Architecture Module | `link_extractor.rs` (SS-03, pure core, CRITICAL tier) — ADR-003 (pulldown-cmark event stream) |
| Stories | [filled by story-writer] |

## Related BCs
- BC-2.03.002 — related to (reference-style forms use same extraction)
- BC-2.04.001 — depends on (code context established before this runs)
