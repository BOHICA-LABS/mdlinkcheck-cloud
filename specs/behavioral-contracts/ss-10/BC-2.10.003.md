---
document_type: behavioral-contract
level: L3
version: "1.5"
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
subsystem: "SS-10"
capability: "CAP-010"
lifecycle_status: active
introduced: v1.0.0
modified:
  - "v1.1: INCONSISTENCY-001/D-014 — replaced 'clean' with 'alive' in test vector (liveness outcome is alive; link verdict is clean per DD-022)"
  - "v1.2: (INC-MAP) Architecture Module field added per bc-module-map.md (architect, Phase 1b)"
  - "v1.3: CV5-001/D-043 — T13 removed from Brief Requirement field; T13 is retired by D-043 macOS-only platform directive"
  - "v1.4: (WS-4/POLICY-5) L2 Capability fabricated quotation repaired: replaced invented excerpt with verbatim CAP-010 heading per capabilities.md §CAP-010; gloss moved outside quotes"
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.10.003: Per-URL 10-Second Timeout

## Description
Each external URL check has a total timeout of 10 seconds (wall clock from request start to
response completion). If the timeout elapses before a response is received, the verdict is
`indeterminate` with reason `http-timeout`. The timeout applies per-URL (HEAD + GET fallback
share one 10-second budget).

## Preconditions
1. An HTTP request is being made for an external URL.

## Postconditions
1. If the request completes within 10 seconds: verdict based on response.
2. If 10 seconds elapse before response: indeterminate (`http-timeout`).
3. The 10-second budget applies to HEAD + GET combined (not 10s each).

## Invariants
1. Timeout is 10 seconds total per-URL. This cannot be configured in v1.0.
2. `http-timeout` is indeterminate, not broken (DI-010).
3. DNS resolution time counts within the 10-second budget.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-171 | URL times out in 10s |

## Canonical Test Vectors
| Scenario | Expected |
|----------|---------|
| Server takes 15s to respond | indeterminate (http-timeout) |
| Server responds in 5s with 200 | alive (link verdict: clean) |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | Timeout after 10s produces http-timeout | unit test with mock slow server |
| test-sufficient | http-timeout is indeterminate not broken | unit test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-010 ("External URL Liveness Checking") per capabilities.md §CAP-010 — 10-second per-URL total timeout; timeout → indeterminate (http-timeout) |
| Capability Anchor Justification | CAP-010 ("External URL Liveness Checking") per capabilities.md §CAP-010 |
| L2 Domain Invariants | DI-010 |
| Brief Requirement | R5 |
| Architecture Module | `http_client.rs` (SS-10, effectful shell, MEDIUM tier) — ADR-004 (ureq sync HTTP) |
