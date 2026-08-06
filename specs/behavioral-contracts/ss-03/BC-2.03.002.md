---
document_type: behavioral-contract
level: L3
version: "1.2"
status: draft
producer: vsdd-factory:product-owner
timestamp: 2026-08-05T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/specs/domain-spec/L2-INDEX.md
  - .factory/planning/brief-validation.md
  - .factory/planning/market-intelligence.md
input-hash: "e860246"
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

# BC-2.03.002: Full Reference-Style, Collapsed, and Shortcut Link/Image Forms

## Description
Reference-style links (`[text][label]`), collapsed references (`[text][]`), and shortcut 
references (`[text]`) are all in scope. Reference definitions (`[label]: url`) are resolved 
whole-document (definitions may appear before or after use). Label matching is case-insensitive 
with internal whitespace collapsed. First definition wins on duplicates.

## Preconditions
1. A file's AST has been fully parsed (entire file, not streaming line-by-line).
2. The file contains reference definitions and/or reference uses.

## Postconditions
1. For `[text][label]` (full): label is looked up in the definition table.
2. For `[text][]` (collapsed): label is derived from `text`.
3. For `[text]` (shortcut): label is derived from `text`.
4. Label matching: case-insensitive, internal whitespace normalized to single space, leading/trailing stripped.
5. The first matching definition wins if multiple exist for the same label.
6. All reference forms (including `![alt][ref]` images) are extracted and classified the same as inline links.

## Invariants
1. Reference definitions that appear AFTER their use are still resolved (pulldown-cmark does this by default).
2. Label matching is not locale-dependent; it follows CommonMark ASCII case folding.
3. Unused reference definitions are NOT reported as errors.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-095 | `[text][ref]` with `[ref]: docs/a.md` at EOF |
| EC-098 | `[REF]` referencing `[ref]: a.md` |
| EC-099 | `[ref]` (shortcut) and `[ref][]` (collapsed) |
| EC-100 | Duplicate `[ref]:` definitions |
| EC-101 | `![alt][imgref]` |

## Canonical Test Vectors
| Input | Expected Output | Category |
|-------|----------------|----------|
| `[x][ref]\n\n[ref]: docs/a.md` (docs/a.md exists) | clean | happy-path |
| `[x][REF]\n\n[ref]: a.md` (a.md exists) | clean (case-insensitive) | edge-case |
| `[x]` (shortcut; no definition) | broken (undefined-reference-definition) | error |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-019 | Reference definitions at EOF are resolved for uses at line 1 | unit test |
| VP-019 | Label matching is case-insensitive | unit test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-003 ("extract all links (inline, reference-style, collapsed, shortcut, image)") per capabilities.md §CAP-003 |
| Capability Anchor Justification | CAP-003 ("Link Extraction") per capabilities.md §CAP-003 |
| L2 Domain Invariants | DI-004, DI-005 |
| Brief Requirement | R3, T4 |
| Architecture Module | `link_extractor.rs` (SS-03, pure core, CRITICAL tier) — ADR-003 (pulldown-cmark event stream) |
| Stories | [filled by story-writer] |
