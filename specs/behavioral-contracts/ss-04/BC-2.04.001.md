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
subsystem: "SS-04"
capability: "CAP-004"
lifecycle_status: active
introduced: v1.0.0
modified:
  - "v1.4: TV-BV013 row removed from Edge Cases table (TV is not an EC ID; the same scenario is already captured in the Canonical Test Vectors section row 3 and in test-vectors.md §0; removing it resolves check-id-resolution non-conforming EC ID finding)."
  - "v1.1: (F-007) VP-TBD backfill from VP-INDEX v1.1"
  - "v1.2: (INC-MAP) Architecture Module field filled per bc-module-map.md (architect, Phase 1b)"
  - "v1.3: (WS-4-B) Citation-authority repair: L2 Capability row — fabricated excerpt with ... elisions replaced with verbatim title 'Code Context Exclusion'; gloss moved outside quotes. Proof-method join: VP-014 row-1 'property test (fuzz...)' → 'integration'; row-2 'integration test' → 'integration' (VP-INDEX authority). Edge Cases table: added Notes column header to accommodate pre-existing TV-BV013 3-cell row (TV-BV013 content unchanged)."
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.04.001: Fenced Code Blocks and Inline Code Spans Yield No Links

## Description
Links inside fenced code blocks (` ``` ` or `~~~`) and inline code spans (`` `...` `` or ` `` ... `` `) 
are NEVER extracted. This is satisfied by construction using pulldown-cmark: code block content arrives 
as `Event::Text` inside `Tag::CodeBlock`, and inline code arrives as `Event::Code` — neither ever 
produces a `Tag::Link` event. This is DI-004 applied to the most common code contexts.

## Preconditions
1. A file has been parsed by pulldown-cmark.
2. The file contains links inside fenced code blocks or inline code spans.

## Postconditions
1. Zero links are extracted from fenced code block content.
2. Zero links are extracted from inline code span content.
3. This holds for backtick fences, tilde fences, language-tagged fences, unclosed fences (EOF), and fences inside list items or blockquotes.

## Invariants
1. The exclusion is structural (AST event matching), not heuristic. (DI-004)
2. Double-backtick spans are also excluded.
3. An unclosed fence swallows all content to EOF (CommonMark behavior).

## Edge Cases
| EC | Description | Notes |
|----|-------------|-------|
| EC-103 | Double-backtick span containing link syntax | |
| EC-104 | Fenced block with `[x](missing.md)` inside | |
| EC-105 | `~~~`-fenced block | |
| EC-108 | Unclosed fence at EOF with links inside | |
| EC-109 | Fence inside list item | |

## Canonical Test Vectors
| Input | Expected Output | Category |
|-------|----------------|----------|
| Inline code span containing `[x](missing.md)` only | Exit 0; no findings | happy-path (DI-004 proof) |
| Fenced block containing `[x](missing.md)` | Exit 0; no findings | edge-case |
| `mdlinkcheck BRIEF.md` on this repo | Exit 0; no findings | canonical (BV-013) |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-014 | No link in any code context is ever extracted | integration |
| VP-014 | BRIEF.md self-test exits 0 | integration |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-004 ("Code Context Exclusion") per capabilities.md §CAP-004 — exclusion is structural (AST event matching), not heuristic; primary code contexts: fenced blocks and inline spans |
| Capability Anchor Justification | CAP-004 ("Code Context Exclusion") per capabilities.md §CAP-004 — fenced blocks and inline spans are the primary code contexts |
| L2 Domain Invariants | DI-004 |
| Brief Requirement | R4, BV-013 |
| Architecture Module | `link_extractor.rs` (SS-04, pure core, CRITICAL tier) — ADR-003 (pulldown-cmark structural event types for code context exclusion) |
| Stories | [filled by story-writer] |

## Related BCs
- BC-2.04.002 — composes with (indented blocks and HTML comments)
- BC-2.04.003 — composes with (headings inside fenced blocks)
