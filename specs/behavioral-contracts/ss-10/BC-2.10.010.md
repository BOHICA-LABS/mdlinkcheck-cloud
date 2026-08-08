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
  - .factory/planning/brief-validation.md
  - .factory/planning/market-intelligence.md
input-hash: "c3e82ce"
traces_to: .factory/specs/domain-spec/L2-INDEX.md
origin: greenfield
extracted_from: null
subsystem: "SS-10"
capability: "CAP-010"
lifecycle_status: active
introduced: v1.3.0
modified:
  - "v1.4: (F-007) VP-TBD backfill from VP-INDEX v1.1"
  - "v1.5: (INC-MAP) Architecture Module field added per bc-module-map.md (architect, Phase 1b)"
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.10.010: Private-IP and Link-Local URL Classification (Indeterminate, No Outbound Request)

## Description
Before sending any HTTP request, mdlinkcheck resolves the URL's hostname to an IP address and
checks whether that address falls within a private, loopback, or link-local range (RFC 1918,
RFC 4193, loopback, APIPA). If so, the URL is classified as `indeterminate` with reason
`private-ip` and **no outbound HTTP request is sent**. This prevents SSRF-style attacks and
avoids spurious timeouts on development-environment URLs that exist locally but not in CI.

Private/link-local ranges checked (non-exhaustive; implementation must cover at minimum):
- IPv4 loopback: 127.0.0.0/8
- IPv4 private: 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16
- IPv4 APIPA/link-local: 169.254.0.0/16
- IPv6 loopback: ::1/128
- IPv6 link-local: fe80::/10
- IPv6 unique-local: fc00::/7

## Preconditions
1. A link has been classified as `external-http`.
2. DNS resolution (or literal IP parsing) has produced an IP address for the URL's hostname.
3. The IP address falls within a private, loopback, or link-local range.

## Postconditions
1. Verdict: `indeterminate` (`http-indeterminate`, reason: `private-ip`).
2. No HTTP request is sent to the target.
3. The classification is logged at debug level with the resolved IP and range matched.

## Invariants
1. The private-IP check is performed BEFORE any HTTP request is dispatched.
2. Literal IP addresses in URLs (e.g., `http://192.168.1.1/`) are also subject to this check.
3. `indeterminate` is never escalated to `broken` for private-IP targets (DI-010).

## Edge Cases
| EC | Description |
|----|-------------|
| EC-092 | `http://192.168.1.1/` (RFC 1918 private) |
| EC-092b | `http://[::1]/` (IPv6 loopback) |
| EC-092c | `http://10.0.0.1/resource` |
| EC-092d | `http://localhost/` (resolves to 127.0.0.1) |

## Canonical Test Vectors
| URL | Expected Verdict | Notes |
|-----|-----------------|-------|
| `http://192.168.1.1/` | indeterminate (private-ip) | RFC 1918 private; no HTTP sent |
| `http://10.0.0.1/path` | indeterminate (private-ip) | RFC 1918 private |
| `http://[::1]/` | indeterminate (private-ip) | IPv6 loopback |
| `http://169.254.1.1/` | indeterminate (private-ip) | APIPA link-local |
| `https://example.com/` | (normal liveness check) | public IP — this BC does not apply |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | Private-IP URLs never produce outbound HTTP requests | unit test (mock DNS resolver returns private IP; assert no socket open) |
| test-sufficient | Private-IP verdict is indeterminate, not broken | unit test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-010 ("External URL Liveness Checking") per capabilities.md §CAP-010 |
| Capability Anchor Justification | CAP-010 ("External URL Liveness Checking") per capabilities.md §CAP-010 — private-IP guard is a pre-flight check in the external URL liveness pipeline |
| L2 Domain Invariants | DI-010 |
| Brief Requirement | R5, D-008 |
| Architecture Module | `http_client.rs` (SS-10, effectful shell, MEDIUM tier) primary; `http_verdict.rs` (SS-10, pure core, CRITICAL tier) secondary — indeterminate verdict returned for private-IP URLs — ADR-004, ADR-007 |

## Related BCs
- BC-2.10.002 — parent (total partition; private-IP maps to PC16 indeterminate)
- BC-2.10.005 — sibling (DNS failure)
- BC-2.10.007 — sibling (TLS failure)
