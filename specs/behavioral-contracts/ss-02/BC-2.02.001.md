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
subsystem: "SS-02"
capability: "CAP-002"
lifecycle_status: active
introduced: v1.0.0
modified:
  - "v1.1: (F-007) VP-TBD backfill from VP-INDEX v1.1"
  - "v1.2: REGRESSION-002 — removed .markdown extension reference from Preconditions (D-012: .md only, case-sensitive)"
  - "v1.3: (INC-MAP) Architecture Module field filled per bc-module-map.md (architect, Phase 1b)"
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.02.001: CommonMark + GFM AST Parsing with Byte-Offset Line Numbers

## Description
Each discovered Markdown file is parsed into an AST event stream using pulldown-cmark 0.13.4 
with CommonMark 0.31.2 + GFM options enabled. The parser is used via `Parser::into_offset_iter()` 
which yields `(Event, Range<usize>)` byte-offset pairs. Line numbers are derived from byte offsets 
by binary-searching a precomputed array of line-start byte positions.

## Preconditions
1. A `.md` file has been read into a UTF-8 string (`.markdown`, `.MD`, `.mdx` excluded per D-012).
2. The string has been BOM-stripped and CRLF-normalized (BC-2.02.002).

## Postconditions
1. The file is parsed into a sequence of pulldown-cmark events with byte-range annotations.
2. Each link and heading event carries a byte offset that is convertible to a 1-based (line, column) pair.
3. The byte offset is the position of the opening `[` for links, or the `#` for ATX headings.
4. GFM extensions (tables, strikethrough, task lists) are enabled; footnotes are recognized but treated as non-links.

## Invariants
1. Parsing is purely structural; no regex applied to source text after this point.
2. Code contexts (inline spans, fenced blocks, indented blocks) are distinguishable by event type — no heuristic needed to satisfy DI-004.
3. Line numbers are 1-based; columns are 1-based byte-offset within the line.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-016 | CRLF file |
| EC-015 | UTF-8 BOM at start |
| EC-121 | Multi-line link destination |

## Canonical Test Vectors
| Input | Expected Output | Category |
|-------|----------------|----------|
| `# Heading\n[x](missing.md)` | Link at line 2, column 1 | happy-path |
| CRLF file with link on line 5 | Reported at line 5, same as LF | edge-case |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | Line numbers are identical for LF and CRLF equivalents | property test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-002 ("Parse each discovered Markdown file into a structured AST event stream using the CommonMark 0.31.2 + GFM grammar") per capabilities.md §CAP-002 |
| Capability Anchor Justification | CAP-002 ("Markdown Parsing") per capabilities.md §CAP-002 — this BC is the central parsing contract |
| Brief Requirement | R2, R3, R4, R6 |
| Architecture Module | `scanner.rs` (SS-02, effectful shell, HIGH tier) primary; `link_extractor.rs` (SS-03, pure core, CRITICAL tier) secondary — processes the event stream scanner produces — ADR-003 |
| Stories | [filled by story-writer] |

## Related BCs
- BC-2.03.001 — depends on (extraction uses this AST)
- BC-2.05.001 — depends on (anchor extraction uses this AST)
- BC-2.04.001 — depends on (code exclusion is structural via this AST)
