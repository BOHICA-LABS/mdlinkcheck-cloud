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
input-hash: "a53c532"
traces_to: .factory/specs/domain-spec/L2-INDEX.md
origin: greenfield
extracted_from: null
subsystem: "SS-10"
capability: "CAP-010"
lifecycle_status: active
introduced: v1.0.0
modified:
  - "v1.1: (F-007) VP-TBD backfill from VP-INDEX v1.1"
  - "v1.2: INCONSISTENCY-001/D-014 — replaced 'clean' with 'alive' in test vector (liveness outcome is alive; link verdict is clean per DD-022)"
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.10.007: Redirect Chain Handling (Max 10 Hops)

## Description
HTTP redirects (301, 302, 307, 308) are followed up to a maximum of 10 hops. If the redirect
chain exceeds 10 hops, the verdict is `broken` with reason `too-many-redirects`. HTTP→HTTPS
upgrades are followed. HTTPS→HTTP downgrades produce `indeterminate` with a warning.

## Preconditions
1. `--online` mode is active.
2. An HTTP response with 3xx redirect status is received.

## Postconditions
1. Follow up to 10 redirects; take the final response for verdict determination.
2. If redirect count exceeds 10: broken (`too-many-redirects`).
3. If the chain includes an HTTPS→HTTP downgrade: indeterminate (security warning).
4. Redirect hops count across HEAD and GET fallback.

## Invariants
1. Max 10 hops is absolute; cannot be configured.
2. HTTPS→HTTP downgrade is always indeterminate (never clean).
3. Loop detection: if a redirect target is the same as a URL already in the chain, break immediately → too-many-redirects.

## Edge Cases
| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-087e | Redirect chain of 11 hops | broken (too-many-redirects) |
| EC-087f | HTTP → HTTPS upgrade | follow and resolve normally |
| EC-087g | HTTPS → HTTP downgrade | indeterminate |

## Canonical Test Vectors
| Scenario | Expected |
|----------|---------|
| 5-hop redirect chain → 200 | alive (link verdict: clean) |
| 11-hop redirect chain | broken (too-many-redirects) |
| HTTPS → HTTP downgrade | indeterminate |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | >10 redirects → too-many-redirects | unit test |
| test-sufficient | HTTPS→HTTP downgrade → indeterminate | unit test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-010 ("Redirects followed up to 10 hops; too-many-redirects beyond that; HTTPS→HTTP downgrade → indeterminate") per capabilities.md §CAP-010 |
| Capability Anchor Justification | CAP-010 ("External URL Liveness Checking") per capabilities.md §CAP-010 |
| Brief Requirement | R5, AMB-086 |
