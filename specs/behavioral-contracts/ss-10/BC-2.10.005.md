---
document_type: behavioral-contract
level: L3
version: "1.5"
status: draft
producer: vsdd-factory:product-owner
timestamp: 2026-08-10T00:00:00Z
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
  - "v1.2: (INC-MAP) Architecture Module field added per bc-module-map.md (architect, Phase 1b)"
  - "v1.5: (GATE-58/POL-14) VP-NNN column bare em-dash is non-conforming per POL-14; replaced with VP-NONE (D-078) — proof method is pending, so VP-NONE is accepted."
  - "v1.4: (BI-052 remediation P7-S7-003) VP-007 row corrected: dns-failure harness (verify_vp007_correctness_dns_tls_broken) references classify_response_with_error(HttpError::DnsFailure) which does not exist in the declared API (api-surface.md exposes only classify_response(status: u16, attempt: HttpAttempt)). Row changed to pending with explanation."
  - "v1.3: (WS-4/POLICY-5) L2 Capability fabricated quotation repaired: replaced invented excerpt with verbatim CAP-010 heading per capabilities.md §CAP-010; gloss moved outside quotes. VP-007 proof method corrected from 'unit test with mock DNS resolver' to 'kani (P0)' per VP-INDEX authority"
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.10.005: DNS Resolution Failure Yields `broken` Verdict

## Description
If the DNS lookup for an external URL's hostname fails (NXDOMAIN or resolver error), the verdict
is `broken` with reason `dns-failure`. DNS failure is definitively broken — unlike HTTP errors,
a non-existent hostname is unlikely to be transient.

## Preconditions
1. `--online` mode is active.
2. An HTTP request is being initiated for an external URL.
3. DNS resolution for the hostname fails.

## Postconditions
1. Verdict: `broken`.
2. Reason: `dns-failure`.
3. Contributes to exit 1.
4. The hostname that failed is reported in the message: `DNS resolution failed: <host>`.

## Invariants
1. DNS failure is `broken`, not `indeterminate` (unlike timeout or 5xx).
2. A resolver connectivity failure (can't reach resolver) MAY be indeterminate; implementer judgement — default to broken.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-081 | URL to non-existent hostname `https://this-domain-does-not-exist-xyz-123.com` |

## Canonical Test Vectors
| Scenario | Expected |
|----------|---------|
| Request to NXDOMAIN hostname | broken (dns-failure) |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-NONE | DNS failure → broken (dns-failure) — pending HttpAttempt transport-error API extension; no classify_response_with_error or HttpError enum in declared API; see VP-007 pending harness note | pending |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-010 ("External URL Liveness Checking") per capabilities.md §CAP-010 — DNS resolution failure (dns-failure) maps to liveness broken → link verdict broken |
| Capability Anchor Justification | CAP-010 ("External URL Liveness Checking") per capabilities.md §CAP-010 |
| Brief Requirement | R2c |
| Architecture Module | `http_verdict.rs` (SS-10, pure core, CRITICAL tier) primary; `http_client.rs` (SS-10, effectful, MEDIUM tier) secondary — detects DNS failure; encodes into Attempt enum for http_verdict — ADR-004, ADR-007 |
