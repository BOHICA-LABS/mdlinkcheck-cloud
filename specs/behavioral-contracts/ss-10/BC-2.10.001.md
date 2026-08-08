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
  - "v1.1: (F-007) VP-TBD backfill from VP-INDEX v1.1"
  - "v1.2: INCONSISTENCY-001/D-014 — replaced 'clean' with 'alive' in test vectors and postconditions (liveness outcome is alive; link verdict is clean per DD-022)"
  - "v1.3: (INC-MAP) Architecture Module field added per bc-module-map.md (architect, Phase 1b)"
  - "v1.4: (WS-4/POLICY-5) L2 Capability fabricated quotation repaired: replaced invented excerpt with verbatim CAP-010 heading per capabilities.md §CAP-010; gloss moved outside quotes"
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.10.001: HEAD-then-GET Fallback Protocol (`--online` mode)

## Description
In `--online` mode, external URL liveness is checked via HTTP HEAD first. If HEAD returns a
status in `{400, 403, 404, 405, 501, 999}` OR results in a transport failure (connection reset,
DNS-level error), a GET request is attempted. The final verdict is based on the GET response.

## Preconditions
1. `--online` flag is set.
2. A link has been classified as `external-http`.
3. The URL is syntactically valid (BC-2.09.001).
4. The URL has not been exempted by `--allow` (BC-2.09.002).
5. The URL's host is not currently rate-limited (paused).

## Postconditions
1. HEAD request is sent with 10-second timeout.
2. If HEAD returns 2xx: liveness outcome `alive` (link verdict `clean` per DD-022; not emitted). If HEAD returns 3xx (redirect): follow the chain; verdict based on the final HTTP status.
3. If HEAD returns status in `{400,403,404,405,501,999}` or transport failure: GET request sent.
4. If GET returns 200-299: liveness outcome `alive` (link verdict `clean` per DD-022; not emitted in output).
5. If GET returns 404 or 410: broken (`http-error`).
6. If GET returns 4xx (not 404/410) or 5xx: indeterminate (`http-indeterminate`).
7. If GET times out: indeterminate (`http-timeout`).
8. 301/302 redirects are followed up to 10 hops.

## Invariants
1. GET fallback is triggered on the SPECIFIED set `{400,403,404,405,501,999}` plus transport failures. Not for all non-2xx. (DD-016)
2. 10-second timeout applies per-URL total (not per-request).
3. Redirects count toward the 10-hop limit regardless of whether they occur during HEAD or GET.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-080 | HEAD returns 403 (Forbidden) |
| EC-085 | HEAD succeeds (200) |
| EC-086 | Both HEAD and GET return 404 |

## Canonical Test Vectors
| Scenario | Expected |
|----------|---------|
| HEAD 200 | alive (link verdict: clean) |
| HEAD 405 → GET 200 | alive (link verdict: clean) |
| HEAD 405 → GET 404 | broken (http-error) |
| HEAD 404 → GET 404 | broken (http-error) |
| HEAD 405 → GET 503 | indeterminate (http-indeterminate) |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | GET fallback on exactly {400,403,404,405,501,999} + transport | unit test with mock HTTP |
| test-sufficient | No GET fallback on 200 | unit test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-010 ("External URL Liveness Checking") per capabilities.md §CAP-010 — HEAD-then-GET fallback protocol with GET triggered on {400,403,404,405,501,999} and transport failures |
| Capability Anchor Justification | CAP-010 ("External URL Liveness Checking") per capabilities.md §CAP-010 |
| Brief Requirement | R5, DD-016, T12 |
| Architecture Module | `http_client.rs` (SS-10, effectful shell, MEDIUM tier) primary; `http_verdict.rs` (SS-10, pure core, CRITICAL tier) secondary — classifies the response from the HEAD/GET protocol — ADR-004, ADR-005, ADR-007 |
