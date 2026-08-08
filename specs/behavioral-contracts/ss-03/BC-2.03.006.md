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
input-hash: "c3e82ce"
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
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.03.006: Footnote References Excluded; Escaped Brackets Are Not Links

## Description
Footnote references (`[^1]`, `[^note]`) and their definitions (`[^1]: text`) must not be treated 
as reference links. Escaped brackets (`\[not a link\](url)`) must not produce a link. Both cases 
are handled correctly by pulldown-cmark's parser without special-casing.

## Preconditions
1. A file contains footnote-style constructs `[^label]` or `[^label]: definition`.
2. A file contains escaped bracket sequences `\[...\](...)`.

## Postconditions
1. `[^1]` is not extracted as a link. No finding is emitted for the footnote reference.
2. `[^1]: Some text` is not treated as a reference definition for link resolution.
3. `\[not a link\](url)` is not extracted as a link. The parser handles escape sequences.

## Invariants
1. pulldown-cmark handles both cases by construction; this BC documents the expected behavior.
2. No special-case footnote filtering code is needed.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-120 | `[^1]` + `[^1]: text` |
| EC-112 | `\[escaped\](missing.md)` |

## Canonical Test Vectors
| Input | Expected Output | Category |
|-------|----------------|----------|
| `See [^1] for details.\n\n[^1]: Source text.` | Exit 0; no findings | happy-path |
| `\[not a link\](missing.md)` | Exit 0; no findings | edge-case |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | Footnote constructs produce no link findings | unit test |
| test-sufficient | Escaped brackets produce no link findings | unit test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-003 ("Link Extraction") per capabilities.md §CAP-003 |
| Capability Anchor Justification | CAP-003 ("Link Extraction") per capabilities.md §CAP-003 — exclusions (footnotes, escaped brackets) are part of the extraction contract |
| L2 Domain Invariants | DI-004 |
| Brief Requirement | R3, R4, T6 |
| Architecture Module | `link_extractor.rs` (SS-03, pure core, CRITICAL tier) — ADR-003 (pulldown-cmark event stream) |
| Stories | [filled by story-writer] |
