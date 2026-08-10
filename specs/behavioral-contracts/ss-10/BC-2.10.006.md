---
document_type: behavioral-contract
level: L3
version: "1.8"
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
  - v1.3: "D-011 — --insecure is an explicit non-goal. Removed all --insecure-conditional postconditions. TLS handshake failure is always broken (tls-error). EC-079d removed."
  - "v1.4: (F-007) VP-TBD backfill from VP-INDEX v1.1"
  - "v1.5: (INC-MAP) Architecture Module field added per bc-module-map.md (architect, Phase 1b)"
  - "v1.8: (GATE-58/POL-14) VP-NNN column bare em-dash is non-conforming per POL-14; replaced with VP-NONE (D-078) — proof method is pending, so VP-NONE is accepted."
  - "v1.7: (BI-052 remediation P7-S7-003) VP-007 row corrected: tls-error harness (verify_vp007_correctness_dns_tls_broken) references classify_response_with_error(HttpError::TlsError) which does not exist in the declared API (api-surface.md exposes only classify_response(status: u16, attempt: HttpAttempt)). Row changed to pending with explanation."
  - "v1.6: (WS-4) VP-007 proof method corrected from 'unit test with mock TLS server' to 'kani (P0)' per VP-INDEX authority"
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.10.006: TLS Handshake Failure Behavior

## Description
If TLS handshake fails (expired certificate, self-signed cert, hostname mismatch, etc.) for an
HTTPS URL, the verdict is `broken` with reason `tls-error`. TLS certificate verification is
always enforced — there is no `--insecure` flag to bypass it (`--insecure` is an explicit
non-goal per D-011). Users with non-standard CAs must configure the system CA store.

## Preconditions
1. `--online` mode is active.
2. An HTTPS URL is being checked.
3. TLS handshake fails.

## Postconditions
1. Verdict: `broken` (`tls-error`) → exit 1.
2. No bypass mechanism exists (`--insecure` is a non-goal per D-011).

## Invariants
1. `tls-error` is always `broken` and contributes to exit 1.
2. No flag bypasses TLS certificate verification in v1.0 (D-011).

## Edge Cases
| EC | Description |
|----|-------------|
| EC-172 | Self-signed cert |

## Canonical Test Vectors
| Scenario | Expected |
|----------|---------|
| Expired cert | broken (tls-error) |
| Self-signed cert | broken (tls-error) |
| Hostname mismatch | broken (tls-error) |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-NONE | TLS failure → tls-error (broken) always — pending HttpAttempt transport-error API extension; no classify_response_with_error or HttpError enum in declared API; see VP-007 pending harness note | pending |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-010 ("External URL Liveness Checking") per capabilities.md §CAP-010 |
| Capability Anchor Justification | CAP-010 ("External URL Liveness Checking") per capabilities.md §CAP-010 — TLS behavior is part of the liveness checking pipeline |
| Brief Requirement | R5, AMB-090 |
| Architecture Module | `http_verdict.rs` (SS-10, pure core, CRITICAL tier) primary; `http_client.rs` (SS-10, effectful, MEDIUM tier) secondary — detects TLS failure; encodes into Attempt enum for http_verdict — ADR-004, ADR-007 |

## Related BCs
- BC-2.10.002 — parent (total partition; TLS failure maps to PC14 broken)
- BC-2.10.005 — sibling (DNS failure)
- BC-2.10.010 — sibling (private-IP classification)
