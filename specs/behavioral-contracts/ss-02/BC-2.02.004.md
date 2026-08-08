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
subsystem: "SS-02"
capability: "CAP-002"
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

# BC-2.02.004: Explicit Non-`.md` File Argument Is Parsed (Not Skipped)

## Description
When a file is passed explicitly as a PATH argument (not discovered via traversal), it is parsed 
regardless of its extension. Explicit intent overrides the extension filter applied during traversal.

## Preconditions
1. A PATH argument resolves to an existing regular file.
2. The file does not have a `.md` or `.markdown` extension.

## Postconditions
1. The file is read and parsed as Markdown.
2. All links found in it are checked.
3. Findings are reported normally.

## Invariants
1. This rule applies to explicit PATH arguments ONLY. Files discovered via directory traversal still use the extension filter.
2. The file must be readable; if not, BC-2.02.003 applies.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-007 | `mdlinkcheck notes.txt` |

## Canonical Test Vectors
| Input | Expected Output | Category |
|-------|----------------|----------|
| `mdlinkcheck notes.txt` where notes.txt has `[x](missing.md)` | Exit 1; 1 finding | happy-path |
| `mdlinkcheck notes.html` where notes.html has Markdown-style inline link | Exit 1 if pulldown-cmark finds link | edge-case |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | Explicit non-.md args are parsed | unit test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-002 ("Markdown Parsing") per capabilities.md §CAP-002 |
| Capability Anchor Justification | CAP-002 ("Markdown Parsing") per capabilities.md §CAP-002 |
| Brief Requirement | R1, AMB-006 |
| Architecture Module | `scanner.rs` (SS-02, effectful shell, HIGH tier) — ADR-003 (pulldown-cmark event stream) |
| Stories | [filled by story-writer] |
