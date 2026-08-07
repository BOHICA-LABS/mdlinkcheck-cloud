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
  - "v1.3: (WS-4/Shard-C) POLICY-5 citation repair: L2 Capability quoted string was fabricated description; corrected to verbatim section title 'Anchor Resolution' per capabilities.md §CAP-008; gloss moved outside quotes. VP-015 proof method corrected from 'unit test' to 'integration' per VP-INDEX authority. VP-025 proof method corrected from 'Kani/proptest' to 'proptest' per VP-INDEX authority."
  - "v1.1: (INC-MAP) Architecture Module field added per bc-module-map.md (architect, Phase 1b)"
  - "v1.2: (EC-collision) EC-060→EC-191 (EC-060 canonical owner is BC-2.08.001 corrected: was coliding with BC-2.06.001); EC-075→EC-194 (empty-anchor case; three-equivalent-forms case stays in test-vectors.md). (C4-006) VP-025 added to Verification Properties."
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.08.001: Anchor-Only Link Resolution (`#fragment`)

## Description
Links whose destination starts with `#` (anchor-only, referencing a heading in the same file)
are resolved against the source file's own anchor table. The fragment is extracted after the `#`
and looked up in the anchor table. If found, verdict is clean; if not, verdict is broken
(anchor-not-found).

## Preconditions
1. A link's destination starts with `#`.
2. The source file's anchor table has been fully built (Pass 1 complete).

## Postconditions
1. The fragment = destination.strip_prefix('#'), verbatim (no additional decoding or lowercasing).
2. The fragment is looked up in the source file's own anchor table.
3. If found: clean.
4. If not found: broken (anchor-not-found).
5. Empty anchor `#` (bare hash): clean (conventionally means "top of page"; in scope per EC-194).

## Invariants
1. Anchor lookup is in the SOURCE file's table (not another file's table).
2. The lookup is verbatim slug comparison — the fragment must exactly match an anchor table entry.
3. Percent-decoded vs non-decoded: fragment is used verbatim from source (not decoded) unless DI-003 requires split. For anchor-only links, the entire destination after `#` is the fragment.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-191 | `[x](#setup)` where `## Setup` exists |
| EC-061 | `[x](#Setup)` where `## Setup` exists |
| EC-062 | `[x](#no-such-anchor)` |
| EC-194 | `[x](#)` empty anchor |

## Canonical Test Vectors
| Input | Expected Verdict | Category |
|-------|----------------|----------|
| `## Setup\n[x](#setup)` | clean | happy-path |
| `## Setup\n[x](#Setup)` | broken (anchor-not-found) | edge-case |
| `[x](#)` empty anchor | clean | edge-case |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-015 | Anchor-only links resolved in same-file table | integration |
| VP-015 | Case mismatch → anchor-not-found | integration |
| VP-025 | Anchor-resolver totality (every input resolves to Hit or non-panic outcome) | proptest |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-008 ("Anchor Resolution") per capabilities.md §CAP-008 — resolve anchor fragments by looking up the fragment in the pre-built anchor table |
| Capability Anchor Justification | CAP-008 ("Anchor Resolution") per capabilities.md §CAP-008 |
| L2 Domain Invariants | DI-003, DI-008 |
| Brief Requirement | R5, AMB-053 |
| Architecture Module | `anchor_resolver.rs` (SS-08, pure core, CRITICAL tier) — ADR-007 (two-layer verdict model) |
