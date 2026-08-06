---
document_type: behavioral-contract
level: L3
version: "1.1"
status: draft
producer: vsdd-factory:product-owner
timestamp: 2026-08-05T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/specs/domain-spec/L2-INDEX.md
  - .factory/planning/brief-validation.md
  - .factory/planning/market-intelligence.md
input-hash: "19b62d8"
traces_to: .factory/specs/domain-spec/L2-INDEX.md
origin: greenfield
extracted_from: null
subsystem: "SS-04"
capability: "CAP-004"
lifecycle_status: active
introduced: v1.0.0
modified:
  - "v1.1: (F-007) VP-TBD backfill from VP-INDEX v1.1"
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
| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-102 | Inline code span containing `[x](missing.md)` | Zero findings |
| EC-103 | Double-backtick span containing link syntax | Zero findings |
| EC-104 | Fenced block with `[x](missing.md)` inside | Zero findings |
| EC-105 | `~~~`-fenced block | Zero findings |
| EC-108 | Unclosed fence at EOF with links inside | Zero findings |
| EC-109 | Fence inside list item | Zero findings |
| TV-BV013 | BRIEF.md lines 18-19: inline code spans | Exit 0 (canonical self-test) |

## Canonical Test Vectors
| Input | Expected Output | Category |
|-------|----------------|----------|
| Inline code span containing `[x](missing.md)` only | Exit 0; no findings | happy-path (DI-004 proof) |
| Fenced block containing `[x](missing.md)` | Exit 0; no findings | edge-case |
| `mdlinkcheck BRIEF.md` on this repo | Exit 0; no findings | canonical (BV-013) |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-014 | No link in any code context is ever extracted | property test (fuzz with random links in code blocks) |
| VP-014 | BRIEF.md self-test exits 0 | integration test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-004 ("Identify regions...constituting code context...Exclusion is structural (AST event matching), not heuristic") per capabilities.md §CAP-004 |
| Capability Anchor Justification | CAP-004 ("Code Context Exclusion") per capabilities.md §CAP-004 — fenced blocks and inline spans are the primary code contexts |
| L2 Domain Invariants | DI-004 |
| Brief Requirement | R4, BV-013 |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |

## Related BCs
- BC-2.04.002 — composes with (indented blocks and HTML comments)
- BC-2.04.003 — composes with (headings inside fenced blocks)
