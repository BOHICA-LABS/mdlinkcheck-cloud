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
  - "v1.2: (INC-MAP) Architecture Module field added per bc-module-map.md (architect, Phase 1b)"
  - "v1.3: (EC-collision) EC-087→EC-199 (EC-087 canonical owner is test-vectors.md TV-087 self-signed TLS). (P4-015) PC3 rewritten for RFC 9110 §10.2.3 compliance (delta-seconds + HTTP-date + malformed fallback); new PC6 (120s clamp); new Invariant 4 (bounded total pause); EC-087d/e/f added."
  - "v1.4: (WS-4/POLICY-5) L2 Capability fabricated quotation repaired: replaced invented excerpt with verbatim CAP-010 heading per capabilities.md §CAP-010; gloss moved outside quotes"
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.10.004: 429 Rate-Limit Handling — Pause Host, Resume After Retry-After

## Description
When a 429 (Too Many Requests) response is received for a URL, the tool pauses all requests
to that host for the duration specified in the `Retry-After` response header (or a default 60
seconds if the header is absent). After the pause, queued requests for that host resume. The
URL that triggered the 429 receives verdict `indeterminate (http-indeterminate)`.

## Preconditions
1. `--online` mode is active.
2. A 429 response is received for a URL.
3. Other URLs with the same host may be queued.

## Postconditions
1. The 429-triggering URL receives verdict `indeterminate`.
2. All pending requests to the same host are paused.
3. Pause duration is derived from `Retry-After` per RFC 9110 §10.2.3: if the value is
   delta-seconds (a non-negative integer), that many seconds; if it is an HTTP-date,
   `max(0, date − now)` seconds; if the header is absent, unparseable, negative, or
   non-numeric-non-date, 60 seconds AND a `[warn]` diagnostic naming the raw header value
   is emitted to stderr.
4. After the pause elapses, requests to that host resume.
5. Resumed requests produce their own verdicts (they are not all automatically indeterminate).
6. The honored pause is clamped to `min(computed, 120s)`. A `Retry-After` exceeding the
   clamp is honored at the clamp and a `[warn]` diagnostic is emitted.

## Invariants
1. 429 is never `broken`. (DI-010)
2. The pause is per-host (hostname), not per-URL.
3. Requests to OTHER hosts are not paused by a 429 from one host.
4. Total pause time accumulated across all hosts in one invocation is bounded; no `--online`
   run can be delayed indefinitely by server-controlled headers (120s clamp per PC6).

## Edge Cases
| EC | Description |
|----|-------------|
| EC-199 | 429 with `Retry-After: 30` |
| EC-087b | 429 with no Retry-After header |
| EC-087c | 429 when all URLs are to the same host |
| EC-087d | 429 with HTTP-date form `Retry-After` (e.g., `Retry-After: Fri, 01 Jan 2027 00:00:00 GMT`) |
| EC-087e | 429 with malformed `Retry-After` value (e.g., `Retry-After: abc`) |
| EC-087f | 429 with `Retry-After: 86400` → pause clamped to 120s |

## Canonical Test Vectors
| Scenario | Expected |
|----------|---------|
| Host returns 429 with `Retry-After: 5` | indeterminate; host paused 5s |
| Host returns 429 (no Retry-After) | indeterminate; host paused 60s (default) |
| Host returns 429 with `Retry-After: abc` (malformed) | indeterminate; host paused 60s; `[warn]` diagnostic emitted |
| Host returns 429 with `Retry-After: 86400` | indeterminate; host paused 120s (clamped); `[warn]` diagnostic emitted |
| Host returns 429 with HTTP-date `Retry-After` (future) | indeterminate; host paused `max(0, date − now)` seconds, capped at 120s |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | 429 triggers host pause per Retry-After | unit test with mock HTTP |
| test-sufficient | Only the 429 host is paused | unit test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-010 ("External URL Liveness Checking") per capabilities.md §CAP-010 — 429 rate-limit handling: pause host per Retry-After header (default 60s); queued requests resume after pause |
| Capability Anchor Justification | CAP-010 ("External URL Liveness Checking") per capabilities.md §CAP-010 |
| L2 Domain Invariants | DI-010 |
| Brief Requirement | R5, AMB-088 |
| Architecture Module | `http_client.rs` (SS-10, effectful shell, MEDIUM tier) primary; `http_verdict.rs` (SS-10, pure core, CRITICAL tier) secondary — 429 classification drives pause decision — ADR-004, ADR-005, ADR-007 |
