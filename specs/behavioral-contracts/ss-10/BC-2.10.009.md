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
introduced: v1.2.0
modified:
  - "v1.1: (F-007) VP-TBD backfill from VP-INDEX v1.1"
  - "v1.2: (INC-MAP) Architecture Module field filled per bc-module-map.md (architect, Phase 1b)"
  - "v1.5: (GATE-58/D-244) EC-149 description completed — same underlying scenario (same URL referenced at multiple lines + DNS NXDOMAIN), description was partial; added DNS NXDOMAIN vocabulary so checker agrees with registry (direction b, same scenario, wording drift)."
  - "v1.3: (P4-024) PC2 rewritten to distinguish HTTP-layer liveness outcome (alive/broken/indeterminate) from link-level verdict (clean/broken/indeterminate per DD-022); Invariant 4 added; canonical test vector corrected."
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.10.009: URL Deduplication — Each Unique External URL Fetched Once, Verdict Reported at Every Occurrence

## Description
In `--online` mode, each unique normalized external URL is fetched at most once per invocation.
If the same URL appears at multiple source locations in the corpus, the verdict from that single
fetch is memoized and reported at every occurrence, each with its own correct `file:line:column`
position. This behavior is externally observable via HTTP request counts and is a prerequisite
for correct 429 handling (BC-2.10.004): duplicate occurrences share the host-pause state rather
than each triggering an independent pause cycle.

## Preconditions
1. `--online` mode is active.
2. At least two links in the corpus resolve to the same normalized external URL after WHATWG
   parsing (same scheme, authority, path, and query string; fragment stripped per WHATWG spec).
3. The URL is not suppressed by `--allow` (i.e., it would otherwise be checked).

## Postconditions
1. Exactly one HTTP request (HEAD, or HEAD + GET fallback per BC-2.10.001) is issued for the
   normalized URL, regardless of the number of source occurrences.
2. The single HTTP-layer liveness outcome (`alive`, `broken`, or `indeterminate` per BC-2.10.002)
   is memoized; the resulting link-level verdict (`clean` when the outcome is `alive`, otherwise
   `broken`/`indeterminate` per DI-005/DD-022) is reported for every occurrence.
3. Each occurrence is reported with its own correct source `file:line:column` in text and JSON
   output.
4. The deduplication key is the normalized URL string as produced by the WHATWG URL parser
   (scheme + authority + path + query; fragment stripped). Only occurrences whose link-level
   verdict is not `clean` produce an output line.
5. Deduplicated URLs share per-host concurrency bookkeeping: the single in-flight request counts
   against the 4-per-host and 32-global caps (BC-2.10.008); duplicate occurrences awaiting the
   shared result do not hold additional concurrency slots.
6. If the host is paused due to a 429 response (BC-2.10.004), all deduplicated occurrences of
   URLs on that host share the same pause state and wait for the same resume signal — they do not
   each trigger an independent 429 pause cycle.

## Invariants
1. Two URLs with different normalized forms (e.g., `http://` vs `https://`) are NOT deduplicated
   even if they resolve to the same host.
2. URL deduplication applies only to external URLs. Internal file-path deduplication (exact
   canonical-path equality) is a separate mechanism governed by BC-2.01.007.
3. The deduplication cache is per-invocation only; no cross-run caching.
4. Deduplication does not alter the number of output lines — every occurrence whose link-level
   verdict is not `clean` produces an output line. Only the HTTP request count is reduced.
   (`alive` → `clean` per DD-022; clean findings are not emitted.)

## Edge Cases
| EC | Description |
|----|-------------|
| EC-090 | `https://example.com/x` (×50 occurrences in corpus) with successful HEAD; `--online` |
| EC-149 | Same URL referenced at two source locations (lines 3 and 7); DNS NXDOMAIN for broken.example.com; exactly one HTTP request (dedup) |
| EC-150 | `http://example.com` (HTTP) and `https://example.com` (HTTPS) both referenced; server returns 200 on both |

## Canonical Test Vectors
| Scenario | Expected |
|----------|---------|
| Same URL broken at 5 locations in `--online` mode (httpmock request counter) | Exactly 1 HTTP request issued; 5 output findings with correct file:line each |
| Same URL alive at 3 locations (link verdict `clean`) | 1 HTTP request; 0 output findings |
| `https://x.com` and `http://x.com` both broken (different normalized forms) | 2 HTTP requests (not deduplicated — different schemes) |
| Host paused on 429; same URL referenced at 4 locations | 1 request that receives 429; 1 pause cycle; all 4 occurrences report indeterminate after pause |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | Request count equals number of unique normalized URLs, not occurrences | integration test with httpmock request counter |

## Related BCs
- BC-2.10.001: defines the fetch protocol used for the single request
- BC-2.10.002: defines the verdict class that gets memoized
- BC-2.10.004: 429 host-pausing shares state across deduplicated occurrences
- BC-2.10.008: concurrency caps — deduplicated occurrences do not consume extra slots

## Architecture Anchors
- `http_client.rs` (SS-10) — primary owner per ADR-001 purity boundary (dedup memo table is mutable shared state; cannot live in pure `http_verdict`)
- ADR-004 (ureq sync HTTP choice)
- ADR-005 (rayon pool + per-host semaphores; dedup must be co-located with concurrency gating)
- bc-module-map.md §P3-027 (P3-027 resolution: dedup → http_client)

## Story Anchor
- [filled by story-writer]

## VP Anchors
- [filled after VP creation]

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-010 ("External URL Liveness Checking") per capabilities.md §CAP-010 |
| Capability Anchor Justification | CAP-010 ("External URL Liveness Checking") per capabilities.md §CAP-010 — URL deduplication is a core efficiency and correctness property of the liveness-checking subsystem, preventing redundant fetches and rate-limit abuse |
| L2 Domain Invariants | DI-005 |
| Brief Requirement | R2c, AMB-037 (loop detection described as "detect loops by URL deduplication") |
| Architecture Module | `http_client.rs` (SS-10, effectful shell, MEDIUM tier) — ADR-004 (ureq sync HTTP), ADR-005 (rayon pool + per-host semaphores); dedup memo table is mutable shared state that cannot live in pure `http_verdict` per ADR-001; see bc-module-map.md §P3-027 |
| Stories | [filled by story-writer] |
