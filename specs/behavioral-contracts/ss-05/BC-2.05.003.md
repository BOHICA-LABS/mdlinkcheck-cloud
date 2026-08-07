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
subsystem: "SS-05"
capability: "CAP-005"
lifecycle_status: active
introduced: v1.0.0
modified:
  - "v1.1: (F-007) VP-TBD backfill from VP-INDEX v1.1"
  - "v1.2: (INC-MAP) Architecture Module field added per bc-module-map.md (architect, Phase 1b)"
  - "v1.3: (WS-4-G) Citation-authority repair: replaced misreferenced DD-007 with DD-003 in Description; corrected fabricated CAP-005 excerpt to verbatim title 'Anchor Table Construction'; added missing DI-007 to L2 Domain Invariants; replaced wrong brief requirement R5/DD-007 with R2b/D-007."
  - "v1.4: (WS-4-B) Proof-method join repair: VP-020 'unit test' → 'integration' (VP-INDEX authority)."
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.05.003: HTML `id=` and `name=` Attribute Extraction into Anchor Table

## Description
In addition to headings, the anchor table includes anchors from HTML `id=` and `name=` attributes
in inline HTML spans (the "narrow carve-out" per DD-003). Only `<a name="...">` and any element
with `id="..."` are recognized. The value is used as-is (no slug computation). This supports
legacy `<a name="top">` patterns and explicit id anchors in documentation.

## Preconditions
1. Pass 1 is in progress for a file.
2. The file contains inline HTML with `id=` or `name=` attributes.

## Postconditions
1. `<a name="foo">` adds `"foo"` to the anchor table.
2. `<div id="bar">` and `<span id="baz">` add `"bar"` and `"baz"` respectively.
3. The value is used verbatim (not slugged, not lowercased).
4. Empty id/name values (`id=""`) are NOT added to the anchor table.

## Invariants
1. Only elements with `id=` or `<a name=` are recognized. Other attributes are ignored.
2. Values are used verbatim; no case-folding applied.
3. Malformed HTML that pulldown-cmark cannot parse as inline HTML yields no anchor entries from that element.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-066 | `<a name="custom-anchor">` |
| EC-067 | `<span id="api-reference">` |
| EC-068 | `id=""` empty value |
| EC-069 | `[x](#custom-anchor)` targeting `<a name="custom-anchor">` |

## Canonical Test Vectors
| Input | Expected Output | Category |
|-------|----------------|----------|
| `<a name="top"></a>\n[x](#top)` | Exit 0; clean | happy-path |
| `<a name="TOP"></a>\n[x](#top)` | Exit 1; anchor-not-found (verbatim, case-sensitive) | edge-case |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-020 | id/name values added verbatim to anchor table | integration |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-005 ("Anchor Table Construction") per capabilities.md §CAP-005 — HTML id/name attribute extraction narrow carve-out per DD-003 |
| Capability Anchor Justification | CAP-005 ("Anchor Table Construction") per capabilities.md §CAP-005 |
| L2 Domain Invariants | DI-007, DI-008 |
| Brief Requirement | R2b, D-007 |
| Architecture Module | `anchor_table.rs` (SS-05, pure core, CRITICAL tier) — ADR-003 (pulldown-cmark HTML event stream governs the extraction approach) |
