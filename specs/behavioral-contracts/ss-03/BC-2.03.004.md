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
  - "v1.3: (WS-4-B) Citation-authority repair: L2 Capability row — fabricated excerpt 'Distinguish link kinds: ... external-http, non-http' (uses ... elision, not verbatim) replaced with verbatim title 'Link Extraction'; gloss moved outside quotes."
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.03.004: CommonMark Autolinks In Scope; GFM Bare-URLs Out of Scope

## Description
CommonMark autolinks (`<https://example.com>`, `<mailto:user@example.com>`) produce 
`LinkType::Autolink` or `LinkType::Email` events in pulldown-cmark and are in scope as 
external URLs. GFM bare-URL autolinks (`https://example.com` in plain prose, without angle 
brackets) are NOT in scope — pulldown-cmark does not support them (issue #494). This is an 
explicit scope decision (DD-009), documented as a known limitation.

## Preconditions
1. A file contains `<https://...>` or `<mailto:...>` autolinks, or plain-prose URLs.

## Postconditions
1. `<https://x.com>` — extracted as `external-http`; syntax-validated offline; fetched if `--online`.
2. `<mailto:user@example.com>` — extracted; classified as `non-http`; silently skipped (clean).
3. `https://x.com` in plain prose (no angle brackets) — NOT extracted; not reported.

## Invariants
1. GFM bare-URL autolinks are never extracted. This is a permanent scope boundary for v1.0.
2. The limitation is documented in the README and `--help` output.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-116 | `<https://example.com>` |
| EC-117 | Bare `https://example.com` in prose |

## Canonical Test Vectors
| Input | Expected Output | Category |
|-------|----------------|----------|
| `See <https://example.com> for details.` (offline) | clean (syntax valid) | happy-path |
| `Visit https://example.com for details.` (bare URL, offline) | no findings | edge-case |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | Bare URLs in prose produce zero findings | unit test |
| test-sufficient | Angle-bracket autolinks produce external-URL findings | unit test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-003 ("Link Extraction") per capabilities.md §CAP-003 — classifies external-http and non-http link kinds |
| Capability Anchor Justification | CAP-003 ("Link Extraction") per capabilities.md §CAP-003 |
| L2 Domain Invariants | DI-005 |
| Brief Requirement | R2c, DD-009, AMB-047 |
| Architecture Module | `link_extractor.rs` (SS-03, pure core, CRITICAL tier) — ADR-003 (pulldown-cmark event stream) |
| Stories | [filled by story-writer] |
