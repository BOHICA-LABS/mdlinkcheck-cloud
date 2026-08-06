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
input-hash: "19b62d8"
traces_to: .factory/specs/domain-spec/L2-INDEX.md
origin: greenfield
extracted_from: null
subsystem: "SS-10"
capability: "CAP-010"
lifecycle_status: active
introduced: v1.0.0
modified:
  - v1.3: "Architect required change: Invariant 3 now specifies dedicated rayon thread pool of size 32 (not general rayon worker pool). Test vectors rewritten to assert observed concurrent connections at mock server, not internal thread counts."
  - "v1.4: (F-007) VP-TBD backfill from VP-INDEX v1.1"
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.10.008: Concurrency — Dedicated Pool, 32 Global / 4 Per-Host Request Limits

## Description
In `--online` mode, external URL checks are dispatched through a **dedicated rayon thread pool
of size 32** (separate from rayon's default global pool used by file traversal and anchor
parsing). The global concurrency limit is 32 simultaneous in-flight requests; the per-host
limit is 4 simultaneous requests to the same hostname. This prevents overwhelming any single
server while maintaining throughput and avoids contention with Pass 1 parallelism.

## Preconditions
1. `--online` mode is active.
2. Multiple external URLs are queued for checking.

## Postconditions
1. At most 32 HTTP requests are in-flight simultaneously across all hosts.
2. At most 4 HTTP requests are in-flight simultaneously to any single hostname.
3. When a slot frees up, the next queued request begins immediately.
4. Concurrency limits apply to all URLs not currently paused by a 429 (BC-2.10.004).

## Invariants
1. The limits are 32 global / 4 per-host; these are hardcoded in v1.0 (not user-configurable).
2. A 429-paused host has 0 in-flight requests during the pause period.
3. URL checking uses a **dedicated rayon thread pool of fixed size 32**, not the rayon global
   pool. This isolates network I/O parallelism from file-system traversal and anchor-parsing
   parallelism (which use the default global pool in Pass 1).

## Edge Cases
| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-088b | 100 URLs to same host | At most 4 observed concurrent connections at mock server; no thundering-herd |
| EC-088c | 100 URLs to 100 different hosts | At most 32 observed concurrent connections total |

## Canonical Test Vectors

Test vectors assert behavior observable from OUTSIDE the process (concurrent connections at
mock server), not internal thread counts or pool sizes.

| Scenario | Observable Assertion |
|----------|---------------------|
| 40 URLs to single mock server | Mock server observes ≤ 4 simultaneous open connections |
| 40 URLs to 40 different mock servers | Each mock server observes ≤ 1 open connection; global total ≤ 32 |
| 429 from host A; 40 URLs to host B | Host A has 0 connections during pause; host B proceeds normally (≤ 4) |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | Per-host limit enforced: mock server observes ≤ 4 concurrent connections | integration (mock HTTP server counting concurrent connections) |
| test-sufficient | Global limit enforced: total concurrent connections ≤ 32 | integration (multi-host mock) |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-010 ("Parallelism: 32 global / 4 per-host concurrent requests via rayon") per capabilities.md §CAP-010 |
| Capability Anchor Justification | CAP-010 ("External URL Liveness Checking") per capabilities.md §CAP-010 |
| Brief Requirement | R2c, R8 |

## Related BCs
- BC-2.10.004 — dependency (429 pausing reduces per-host in-flight count to 0)
- BC-2.10.002 — sibling (verdict model; concurrency model dispatches the requests it verdicts)
