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
input-hash: "19b62d8"
traces_to: .factory/specs/domain-spec/L2-INDEX.md
origin: greenfield
extracted_from: null
subsystem: "SS-10"
capability: "CAP-010"
lifecycle_status: active
introduced: v1.0.0
modified:
  - "v1.1: (F-007) VP-TBD backfill from VP-INDEX v1.1"
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
3. Pause duration = Retry-After header value in seconds, or 60 seconds if absent.
4. After the pause elapses, requests to that host resume.
5. Resumed requests produce their own verdicts (they are not all automatically indeterminate).

## Invariants
1. 429 is never `broken`. (DI-010)
2. The pause is per-host (hostname), not per-URL.
3. Requests to OTHER hosts are not paused by a 429 from one host.

## Edge Cases
| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-087 | 429 with `Retry-After: 30` | Pause host 30 seconds |
| EC-087b | 429 with no Retry-After header | Pause host 60 seconds |
| EC-087c | 429 when all URLs are to the same host | All paused; all indeterminate |

## Canonical Test Vectors
| Scenario | Expected |
|----------|---------|
| Host returns 429 with `Retry-After: 5` | indeterminate; host paused 5s |
| Host returns 429 (no Retry-After) | indeterminate; host paused 60s |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | 429 triggers host pause per Retry-After | unit test with mock HTTP |
| test-sufficient | Only the 429 host is paused | unit test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-010 ("429 pauses the host per Retry-After header (default 60s); queued requests resume after pause") per capabilities.md §CAP-010 |
| Capability Anchor Justification | CAP-010 ("External URL Liveness Checking") per capabilities.md §CAP-010 |
| L2 Domain Invariants | DI-010 |
| Brief Requirement | R5, AMB-088 |
