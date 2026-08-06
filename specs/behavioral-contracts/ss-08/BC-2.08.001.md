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
input-hash: "e860246"
traces_to: .factory/specs/domain-spec/L2-INDEX.md
origin: greenfield
extracted_from: null
subsystem: "SS-08"
capability: "CAP-008"
lifecycle_status: active
introduced: v1.0.0
modified:
  - "v1.1: (INC-MAP) Architecture Module field added per bc-module-map.md (architect, Phase 1b)"
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
5. Empty anchor `#` (bare hash): clean (conventionally means "top of page"; in scope per EC-075).

## Invariants
1. Anchor lookup is in the SOURCE file's table (not another file's table).
2. The lookup is verbatim slug comparison — the fragment must exactly match an anchor table entry.
3. Percent-decoded vs non-decoded: fragment is used verbatim from source (not decoded) unless DI-003 requires split. For anchor-only links, the entire destination after `#` is the fragment.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-060 | `[x](#setup)` where `## Setup` exists |
| EC-061 | `[x](#Setup)` where `## Setup` exists |
| EC-062 | `[x](#no-such-anchor)` |
| EC-075 | `[x](#)` empty anchor |

## Canonical Test Vectors
| Input | Expected Verdict | Category |
|-------|----------------|----------|
| `## Setup\n[x](#setup)` | clean | happy-path |
| `## Setup\n[x](#Setup)` | broken (anchor-not-found) | edge-case |
| `[x](#)` empty anchor | clean | edge-case |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-015 | Anchor-only links resolved in same-file table | unit test |
| VP-015 | Case mismatch → anchor-not-found | unit test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-008 ("Resolve anchor fragments by looking up the fragment in the pre-built anchor table") per capabilities.md §CAP-008 |
| Capability Anchor Justification | CAP-008 ("Anchor Resolution") per capabilities.md §CAP-008 |
| L2 Domain Invariants | DI-003, DI-008 |
| Brief Requirement | R5, AMB-053 |
| Architecture Module | `anchor_resolver.rs` (SS-08, pure core, CRITICAL tier) — ADR-007 (two-layer verdict model) |
