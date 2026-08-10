---
document_type: behavioral-contract
level: L3
version: "1.10"
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
  - v1.3: "F-006 — expanded postconditions to total partition of HTTP 0..=599 + transport outcomes (added 400-after-GET, 401, 403, other-4xx, https→http downgrade, TLS failure, too-many-redirects). Removed --insecure clause in old PC7 (D-011: --insecure is a non-goal). Removed holdout EC-093."
  - "v1.4: (F-007) VP-TBD backfill from VP-INDEX v1.1"
  - "v1.5: D-014/INCONSISTENCY-002 — separated 'alive' (liveness outcome) from 'clean' (link verdict per DD-022); removed 'alive (clean)' / 'alive → clean' conflation. D-018 — confirmed 400-after-GET is indeterminate (not broken). P2-M01 — made partition truly total: added 0..=99, 1xx, HEAD-400-when-GET-also-400, GET-also-405 cases; aligned range claim to 'all valid HTTP status code values'. P2-M15 — corrected VP-007 proof method to kani and removed two unverifiable attribution rows. P2-m05 — fixed L2 Capability title to verbatim capabilities.md title. P2-m06 — fixed Related BCs swap. D-016 — added sub_reason field documentation."
  - "v1.6: (INC-MAP) Architecture Module field added per bc-module-map.md (architect, Phase 1b)"
  - "v1.7: (EC-collision) EC-087→EC-198 (HTTP 429 case; EC-087 canonical owner is test-vectors.md TV-087 self-signed TLS); new EC-087 row added for self-signed TLS cert. EC-090→EC-201 (HTTP 401 case; EC-090 canonical owner is BC-2.10.009 per test-vectors.md registry). (Task-12) clarified 'configured window' to reference BC-2.10.003."
  - "v1.10: (GATE-58/POL-14) VP-NNN column bare em-dash is non-conforming per POL-14; replaced with VP-NONE (D-078) — proof method is pending, so VP-NONE is accepted."
  - "v1.9: (BI-052 remediation P7-S7-003) VP-007 row split. Prior row claimed VP-007 kani covers timeout verdict; timeout harness requires HttpError enum and classify_response_with_error API which do not exist in declared API (api-surface.md). VP-007 Kani covers the status-code partition only (429/5xx/404/410). Timeout property split to separate pending row."
  - "v1.8: (misfiling-repair) Removed two duplicate VP rows that were parked in this table but owned by sibling BCs: 'HTTPS→HTTP downgrade → indeterminate' belongs to and is already asserted by BC-2.10.007 (PC3, Invariant 2, VP table line 76); 'private-IP target never sends outbound request' belongs to and is already asserted by BC-2.10.010 (PC2, Invariant 1, VP table line 85). Both rows deleted as confirmed duplicates per reference-integrity repair. No VP minted, no sentinel written (D-092 unmerged)."
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.10.002: Three-Verdict Model (alive/broken/indeterminate) — Total Partition

## Description
External URL liveness checks produce a **URL liveness outcome** per DI-010/DD-022:
`alive` (liveness), `broken`, or `indeterminate`. This intermediate outcome maps to a
**link verdict**: liveness `alive` → link verdict `clean`; `broken` → `broken`; `indeterminate` →
`indeterminate`. Only link verdict `broken` contributes to exit 1. `indeterminate` is emitted in
output (as a warning) but does NOT trigger exit 1. This prevents rate-limiting, auth walls,
transient errors, and security-policy outcomes from creating false failures.

The postconditions below form a **total partition**: every possible HTTP status code value and
every transport-layer outcome maps to exactly one liveness outcome. No HTTP outcome is unspecified.

**Two-layer model (DD-022):** `alive` is a URL liveness outcome, NOT a fourth link verdict.
The link verdict set remains `{clean, broken, indeterminate}`. `alive` maps to `clean`.

**`sub_reason` field (D-016):** certain `http-indeterminate` outcomes carry an optional `sub_reason`
string in the JSON finding object. `sub_reason` is NOT a member of the 13-code closed `reason`
taxonomy; it provides diagnostic context only. Current values: `https-downgrade`, `private-ip`.
VP-021 does NOT check `sub_reason` values.

## Preconditions
1. An external URL has been submitted for liveness checking.
2. The URL's scheme is `http` or `https` (other schemes handled by separate classification BCs).

## Postconditions

### HTTP Status Code Partition

0. **0..=99 and 1xx (100–199):** `indeterminate` (`http-indeterminate`). Non-standard or
   informational codes; the server has not confirmed the resource state. This is the catch-all
   for any status code not explicitly enumerated below.
1. **2xx (200–299):** liveness outcome `alive` → link verdict `clean`. Not emitted in output.
2. **3xx (redirect):** follow redirects up to the configured limit.
   - Final response after redirect: apply this partition recursively to the final status.
   - Redirect limit exceeded: `broken` (`too-many-redirects`) → exit 1. See BC-2.10.007.
   - `https://` redirecting to `http://` (protocol downgrade): `indeterminate`
     (`http-indeterminate`; `sub_reason`: `https-downgrade`). The downgraded request is NOT
     followed. See BC-2.10.007.
3. **400 (after HEAD→GET fallback, where HEAD triggered GET on any fallback-trigger status):**
   `indeterminate` (`http-indeterminate`). The server rejects the method or request, not the
   resource. (D-018: 400-after-GET is indeterminate, not broken.)
3b. **400 on GET when HEAD also returned 400 (both HEAD and GET return 400):** `indeterminate`
   (`http-indeterminate`). Covered by "other 4xx" logic — 400 is included in the unmapped set
   when it arises as a GET result in this combination.
4. **401 Unauthorized:** `indeterminate` (`http-indeterminate`). Resource exists behind auth wall;
   liveness cannot be confirmed or denied.
5. **403 Forbidden (including bot-blocking):** `indeterminate` (`http-indeterminate`). Resource
   exists but access is denied; this is a server policy, not a broken link.
6. **404 Not Found (after HEAD + any GET fallback):** `broken` (`http-error`) → exit 1.
7. **405 Method Not Allowed (HEAD only):** triggers GET fallback (see BC-2.10.001). Not a final
   verdict; apply this partition to the GET response.
   - **If GET also returns 405:** `indeterminate` (`http-indeterminate`). No further fallback;
     the server rejects both methods.
8. **410 Gone (after HEAD + any GET fallback):** `broken` (`http-error`) → exit 1.
9. **429 Too Many Requests:** `indeterminate` (`http-indeterminate`). Also triggers host
   back-off per BC-2.10.004.
10. **Other 4xx (400, 402, 406–409, 411–428, 430–499):** `indeterminate` (`http-indeterminate`).
    The server has not confirmed the resource is absent. (400 is included here as the catch-all
    for any HEAD→400 that does not trigger a GET fallback path.)
11. **5xx (500–599):** `indeterminate` (`http-indeterminate`). Transient server error.

### Transport / Pre-HTTP Partition

12. **Timeout (no response within the fixed 10-second per-URL window per BC-2.10.003):** `indeterminate` (`http-timeout`).
13. **DNS resolution failure:** `broken` (`dns-failure`) → exit 1. DNS failure is definitively
    broken — the hostname does not exist. See BC-2.10.005.
14. **TLS handshake failure (certificate error; no `--insecure` bypass — non-goal per D-011):**
    `broken` (`tls-error`) → exit 1. TLS failures are definitively broken. The tool never
    bypasses TLS verification. See BC-2.10.006.
15. **Connection reset / refused:** `indeterminate` (`http-indeterminate`). Transient network
    error; the resource may be temporarily unreachable. See BC-2.10.006.
16. **Private-IP or link-local target (e.g., `http://192.168.1.1/`, `http://[::1]/`):**
    `indeterminate` (`http-indeterminate`; `sub_reason`: `private-ip`). See BC-2.10.010 for
    classification. The outbound request is NOT sent.

## Invariants
1. 429, 5xx, and timeouts are NEVER mapped to `broken`. (DI-010)
2. Among HTTP status codes: only 404 and 410 (after full HEAD + GET fallback) are definitively
   `broken`. Among transport outcomes: DNS failure (`dns-failure`), TLS failure (`tls-error`),
   and too-many-redirects (`too-many-redirects`) are also definitively `broken`. All other
   outcomes (including 400-after-GET) are `indeterminate`.
3. The liveness outcomes (`alive`/`broken`/`indeterminate`) are exhaustive and mutually exclusive —
   every HTTP status code value and every transport outcome maps to exactly one. The catch-all
   for all unspecified status codes (including 0..=99, 1xx, and unrecognized codes) is
   `indeterminate` (`http-indeterminate`).
4. TLS bypass (`--insecure`) is an explicit non-goal (D-011). TLS failures are always `broken`
   (`tls-error`) — there is no flag to change this.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-087 | Self-signed TLS cert (self-signed, not CA-signed) |
| EC-198 | HTTP 429 response |
| EC-088 | HTTP 503 |
| EC-089 | HTTP 410 Gone |
| EC-201 | HTTP 401 on GitHub raw content (private repo) |
| EC-091 | https://example.com redirects to http://example.com |
| EC-092 | Connection to private IP `http://10.0.0.1/` |

## Canonical Test Vectors
| Scenario | Expected Verdict | Exit Code Contribution |
|----------|-----------------|----------------------|
| 200 OK | alive (link verdict: clean; not emitted) | none |
| 301 → 200 | alive (link verdict: clean; not emitted) | none |
| 404 (HEAD + GET both 404) | broken (http-error) | exit 1 |
| 410 | broken (http-error) | exit 1 |
| 429 | indeterminate (http-indeterminate) | none |
| 403 (bot-blocking) | indeterminate (http-indeterminate) | none |
| 401 | indeterminate (http-indeterminate) | none |
| 500 | indeterminate (http-indeterminate) | none |
| DNS failure | broken (dns-failure) | exit 1 |
| TLS cert error | broken (tls-error) | exit 1 |
| Timeout | indeterminate (http-timeout) | none |
| https→http redirect | indeterminate (http-indeterminate; sub_reason: https-downgrade) | none |
| private-IP URL | indeterminate (http-indeterminate; sub_reason: private-ip) | none |
| Redirect storm (>10 hops) | broken (too-many-redirects) | exit 1 |
| 100 Continue (informational) | indeterminate (http-indeterminate) | none |
| HEAD 405 → GET also 405 | indeterminate (http-indeterminate) | none |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-007 | 429/5xx never produce broken verdict; 404/410 always produce broken (after full fallback) | kani (P0) |
| VP-NONE | timeout produces indeterminate not broken — pending HttpAttempt transport-error API extension; no classify_response_with_error in declared API; see VP-007 pending harness note | pending |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-010 ("External URL Liveness Checking") per capabilities.md §CAP-010 |
| Capability Anchor Justification | CAP-010 ("External URL Liveness Checking") per capabilities.md §CAP-010 — this BC is the definitive total-partition contract for the HTTP verdict model |
| L2 Domain Invariants | DI-010 |
| Brief Requirement | R2c, R7 |
| Architecture Module | `http_verdict.rs` (SS-10, pure core, CRITICAL tier) primary; `http_client.rs` (SS-10, effectful shell, MEDIUM tier) secondary — implements the HEAD/GET protocol that produces responses for classification — ADR-004, ADR-007 |

## Related BCs
- BC-2.10.003 — dependency (HEAD→GET fallback triggers from 405; GET verdict flows back here)
- BC-2.10.004 — dependency (429 back-off behavior)
- BC-2.10.005 — dependency (DNS failure handling)
- BC-2.10.006 — dependency (TLS failure handling; also covers connection reset per PC15)
- BC-2.10.007 — dependency (redirect chain and HTTPS→HTTP downgrade handling)
- BC-2.10.010 — dependency (private-IP/link-local URL classification)
