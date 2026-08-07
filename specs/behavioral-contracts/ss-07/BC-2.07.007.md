---
document_type: behavioral-contract
level: L3
version: "1.6"
status: draft
producer: vsdd-factory:product-owner
timestamp: 2026-08-05T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/specs/domain-spec/L2-INDEX.md
input-hash: "2a2b80f"
traces_to: .factory/specs/domain-spec/L2-INDEX.md
origin: greenfield
extracted_from: null
subsystem: "SS-07"
capability: "CAP-007"
lifecycle_status: active
introduced: v1.4.0
modified:
  - "v1.6: (WS-4/Shard-C) POLICY-5 citation repair: L2 Capability quoted string 'Relative Path Resolution Against Source File's Directory' was fabricated extension of section title; corrected to verbatim 'Relative Path Resolution' per capabilities.md §CAP-007; existing gloss preserved outside quotes."
  - v1.5: "Fix 3 (VP elevation): replaced test-sufficient with VP-023 per VP-INDEX v1.2 architect decision. Empty destination → Malformed(_) totality requires proptest to eliminate the NonHttp misclassification risk."
  - "v1.1: (INC-MAP) Architecture Module field added per bc-module-map.md (architect, Phase 1b)"
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.07.007: Empty Link Destination → Malformed URL

## Description
A link with an empty destination string (`[x]()`) is classified as a syntactic failure before
path resolution or URL validation occurs. The empty string is neither a valid relative path nor
a valid URL; it is rejected with verdict `broken`, reason `malformed-url`. This is the
deterministic single-verdict for EC-031/TV-031 (F-012).

## Preconditions
1. A link has been extracted with an empty destination string (`href=""`).
2. The link has not been classified as a non-http(s) scheme link (BC-2.03.005).

## Postconditions
1. The verdict is `broken`.
2. The reason code is `malformed-url`.
3. Exit code contribution: 1.
4. `path_resolver.rs` and `anchor_resolver.rs` are NOT called — the failure is at the
   classification/validation stage.

## Invariants
1. An empty destination string is NEVER treated as a self-link (it is NOT equivalent to `[x](.)` or `[x](./#)`).
2. WHATWG URL parse fails on empty string → `malformed-url` is the syntactically correct rejection code.
3. This applies to `[x]()` and to equivalent forms where pulldown-cmark produces an empty href.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-031 | `[x]()` in any file |
| EC-031b | `[x]( )` whitespace-only (see TV-032, EC-032) |

## Canonical Test Vectors
| Link | Filesystem | Expected Exit | Expected Verdict | Reason |
|------|------------|---------------|-----------------|--------|
| `[x]()` | any | 1 | broken | malformed-url |
| `[x](   )` (spaces only) | any | 1 | broken | malformed-url (whitespace trimmed → empty) |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-023 | `url_classifier::classify_url` totality — empty string returns `Malformed(_)`, never `NonHttp` | proptest |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-007 ("Relative Path Resolution") per capabilities.md §CAP-007 — empty destination rejected at classification, before resolution |
| Capability Anchor Justification | CAP-007 ("Relative Path Resolution") per capabilities.md §CAP-007 — this BC constrains the path resolution entry point |
| L2 Domain Invariants | DI-005 |
| Brief Requirement | R2a |
| Architecture Module | `url_classifier.rs` (SS-09, pure core, HIGH tier) — ADR-006, ADR-007; VP-023 totality proptest verifies empty string → Malformed(_), never NonHttp (filed in SS-07 because observable during path resolution; classification boundary belongs to url_classifier) |

## Related BCs
- BC-2.07.001 — sibling (handles non-empty relative paths)
- BC-2.09.001 — sibling (WHATWG URL parse failure for external URLs)
- BC-2.08.002 — sibling (cross-file anchor resolution; this BC short-circuits before it is reached)
