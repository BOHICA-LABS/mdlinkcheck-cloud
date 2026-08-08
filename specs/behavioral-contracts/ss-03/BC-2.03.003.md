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
  - "v1.3: (WS-4-B) Citation-authority repair: L2 Capability row — fabricated excerpt 'Distinguish link kinds: ... undefined-reference' (uses ... elision, not verbatim) replaced with verbatim title 'Link Extraction'; gloss moved outside quotes."
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.03.003: Undefined Reference Label Yields `broken` Verdict

## Description
When a reference link's label has no corresponding definition in the file, pulldown-cmark emits
a `LinkType::ReferenceUnknown`, `CollapsedUnknown`, or `ShortcutUnknown` event. This is classified
as `broken` with reason `undefined-reference-definition` — a distinct failure class from a broken
file path (the target is not even attempted to be resolved).

## Preconditions
1. A reference link of any form (`[text][label]`, `[text][]`, `[text]`) is present.
2. No `[label]: url` definition exists in the file for the label (case-insensitively).
3. **`scanner.rs` MUST construct the pulldown-cmark parser via `Parser::new_with_broken_links()`**
   (or the equivalent API that installs a `broken_link_callback`). The callback MUST return `None`
   so that the link destination is left empty and the event is retained as a `*Unknown` variant for
   classification. Without this callback, pulldown-cmark emits undefined reference links as plain
   text (no link event at all), making this verdict unreachable.

## Postconditions
1. Verdict: `broken`.
2. Reason: `undefined-reference-definition`.
3. The label text is reported as the `link_target` field.
4. No filesystem or URL lookup is attempted for this link.

## Invariants
1. This verdict is for undefined LABELS only. If the label is defined but the target path is missing, that is a separate `file-not-found` verdict.
2. `pulldown-cmark`'s `*Unknown` variants surface undefined reference links ONLY when a
   `broken_link_callback` is registered on the parser. A plain `Parser::new()` emits them as
   text nodes — no link event, no verdict. The callback installation in precondition 3 is
   therefore mandatory, not optional.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-096 | `[text][nope]` — label never defined |
| EC-097 | `[ref]: missing.md` — defined but never used |

## Canonical Test Vectors
| Input | Expected Output | Category |
|-------|----------------|----------|
| `[see also][missing-label]` | Exit 1; reason `undefined-reference-definition` | happy-path |
| `[x][ref]\n\n[ref]: existing.md` (existing.md exists) | Exit 0; clean | contrast case |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | *Unknown LinkType variants always produce undefined-reference-definition | unit test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-003 ("Link Extraction") per capabilities.md §CAP-003 — distinguishes undefined-reference as a distinct link kind |
| Capability Anchor Justification | CAP-003 ("Link Extraction") per capabilities.md §CAP-003 — undefined-reference is a distinct extraction outcome within CAP-003 |
| L2 Domain Invariants | DI-005 |
| Brief Requirement | R3, T5, AMB-070 |
| Architecture Module | `link_extractor.rs` (SS-03, pure core, CRITICAL tier) — ADR-003 (pulldown-cmark event stream) |
| Stories | [filled by story-writer] |
