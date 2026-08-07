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
subsystem: "SS-08"
capability: "CAP-008"
lifecycle_status: active
introduced: v1.0.0
modified:
  - "v1.3: (WS-4/Shard-C) POLICY-5 citation repair: L2 Capability quoted string was fabricated DI-003 description; corrected to verbatim section title 'Anchor Resolution' per capabilities.md §CAP-008; gloss moved outside quotes. VP-004 proof method corrected from 'unit test' to 'kani'; VP-013 proof method corrected from 'unit test' to 'fuzz'; both per VP-INDEX authority."
  - "v1.1: (INC-MAP) Architecture Module field filled per bc-module-map.md (architect, Phase 1b)"
  - "v1.2: (EC-collision) EC-076→EC-197 (double-hash malformed fragment case; EC-076 canonical owner is BC-2.05.001 per test-vectors.md)."
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.08.003: Fragment Split at First Unescaped `#` Before Percent-Decode

## Description
The fragment is split from the path component at the FIRST unescaped `#` character in the
destination string, BEFORE any percent-decoding. This is DI-003. A `%23` in the path is NOT
treated as a fragment separator; it is decoded to `#` and is part of the path.

## Preconditions
1. A link destination string is being processed.
2. The destination may contain `#`, `%23`, or other sequences.

## Postconditions
1. Scan left-to-right for the first literal `#` (U+0023) that is not encoded as `%23`.
2. Everything before that `#` is the path component; everything after is the fragment.
3. If no literal `#` is found: no fragment; entire string is path.
4. `%23` in the path component is left as-is until percent-decoding (where it becomes `#`).

## Invariants
1. Fragment split precedes percent-decode. Always. (DI-003)
2. The split point is the first `#`, not the last.
3. Subsequent `#` after the fragment start are part of the fragment (not another split point).

## Edge Cases
| EC | Description |
|----|-------------|
| EC-032 | `a%23b.md` |
| EC-035 | `a%20b.md#section` |
| EC-197 | `a.md##double-hash` |

## Canonical Test Vectors
| Destination | Path Component | Fragment |
|-------------|---------------|----------|
| `docs/a.md#intro` | `docs/a.md` | `intro` |
| `a%23b.md` | `a#b.md` (after decode) | none |
| `a.md##double` | `a.md` | `#double` |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-004 | %23 not treated as fragment separator (trap T9) | kani |
| VP-013 | First # is split point | fuzz |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-008 ("Anchor Resolution") per capabilities.md §CAP-008 — fragment split at first unescaped #, BEFORE percent-decode; %23 in path is NOT a separator (DI-003) |
| Capability Anchor Justification | CAP-008 ("Anchor Resolution") per capabilities.md §CAP-008 |
| L2 Domain Invariants | DI-003 |
| Brief Requirement | R5, T9 |
| Architecture Module | `fragment.rs` (SS-08, pure core, CRITICAL tier) primary; `anchor_resolver.rs` (SS-08) secondary — receives the split fragment for anchor lookup — ADR-007 |
