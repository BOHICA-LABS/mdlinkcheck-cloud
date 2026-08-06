---
document_type: adr
adr_id: ADR-004
status: accepted
date: 2026-08-05
version: "1.1"
subsystems_affected: [SS-10]
supersedes: null
superseded_by: null
changelog:
  - version: "1.1"
    date: 2026-08-05
    change: "Phase 1d F-010 remediation: made explicit that the --online HTTP dispatch uses a DEDICATED rayon pool separate from the file-scan pool; explained the starvation hazard of sharing pools; added architectural contract statement for BC-2.10.008"
---

# ADR-004: ureq 3.3.0 Sync/Blocking HTTP Client

## Context

`--online` mode (CAP-010) requires HTTP HEAD/GET requests to external URLs with
a 10-second timeout, per-host concurrency caps (32 global / 4 per-host), and GET
fallback on specific status codes (DD-016). Two viable HTTP client options exist:
`ureq` 3.3.0 (sync/blocking) and `reqwest` 0.13.4 (async, requires tokio).

The DTU assessment establishes that `httpmock` 0.8.3 is used for all `--online`
behavioral tests. `httpmock` 0.8.3 rejects `wiremock` (which requires tokio) as
the mock strategy precisely because of the tokio runtime conflict.

## Decision

Use `ureq` 3.3.0 with `rustls` (no native-tls). Pin this version in `Cargo.toml`.
Do not introduce `tokio` as a dependency.

## Rationale

**Sync + dedicated rayon pool composition:** The HTTP work in `--online` mode is a
bounded, embarrassingly-parallel batch — a fixed set of unique URLs, each checked once.
A **dedicated** rayon thread pool (`rayon::ThreadPoolBuilder::new().num_threads(32).build()`)
separate from the default global rayon pool handles all HTTP dispatch. `ureq` blocks on
each request in a thread from that dedicated pool; no async runtime is needed.

**CRITICAL: dedicated vs. shared pool.** The HTTP pool MUST be separate from the
file-scan pool. ureq is synchronous: each in-flight HTTP request occupies its rayon
thread for the full request duration (up to 10 seconds per BC-2.10.003). If HTTP
dispatch shared the global/file-scan pool, 32 blocked HTTP threads would starve the
CPU-bound Pass 1 and Pass 2 work — effectively serializing a parallel file scan behind
network I/O. The dedicated pool means HTTP threads only compete with each other, not
with CPU work. ADR-005 documents the file-scan pool separately.

**Binary size and complexity:** `reqwest` pulls in tokio + hyper, adding significant
binary size and making stack traces harder to read. For a CLI with at most 32
concurrent HTTP threads, this overhead is unjustified.

**Test compatibility:** `httpmock` 0.8.3 works with blocking tests. The DTU assessment
explicitly records that `wiremock` 0.6.5 was rejected because it requires
`#[tokio::test]`. Using `ureq` means ALL `--online` tests use standard `#[test]`
(or `#[nextest]`) without async test harnesses.

**`httpmock` hermetic strategy:** The DTU assessment specifies `httpmock` 0.8.3 in-process
mocking for all `--online` behavioral tests. This strategy is verified only with the
sync request model — `httpmock` binds to a random localhost port, and `ureq` makes
blocking calls to that port.

**Per-host concurrency:** A semaphore-style `Arc<Mutex<HashMap<String, u32>>>` tracking
active-request counts per host implements BC-2.10.008's 4-per-host cap. This is trivial
with sync code; with async it would require a tokio semaphore or similar.

## Consequences

### Positive
- No tokio runtime — smaller binary, simpler stack traces
- `#[test]` everywhere; no `#[tokio::test]` contamination
- Dedicated rayon pool provides natural HTTP concurrency control without starving CPU work
- `httpmock` hermetic strategy works without any async test infrastructure

### Negative / Trade-offs
- Each HTTP rayon thread holds a blocking OS thread during HTTP I/O (not cooperative)
- 32 dedicated HTTP threads is a hard OS-thread cap, not an async task cap; total OS thread
  count = (file-scan pool threads) + 32 + (system threads)
- If per-request streaming ever needed, ureq 3.x supports it but the API differs from async streams

### Architectural contract (for BC-2.10.008)

`BC-2.10.008` Invariant 3 must NOT reference "available rayon thread count" as a cap.
The dedicated HTTP pool is always sized at exactly 32, regardless of the host's CPU count
or the size of the file-scan pool. BC-2.10.008 should state: "A dedicated rayon thread
pool of size 32 (separate from the file-scan pool) is created at `--online` startup;
at most 32 HTTP requests are in-flight at any instant." This is the authoritative
architectural contract; BC-2.10.008 must be updated to match (product-owner scope).

### Status as of 2026-08-05

Accepted. HTTP client not yet implemented (Phase 3 scope).

## Alternatives Considered

- **reqwest 0.13.4 (MIT OR Apache-2.0):** Async, supports tokio. Rejected: introduces
  tokio runtime; `httpmock` 0.8.3 incompatible with tokio test harness (DTU assessment).
  Token-bucket scheduling at 1000+ requests would favor reqwest, but mdlinkcheck caps
  at 32 global / 4 per-host (BC-2.10.008).
- **curl (C FFI):** Unsafe FFI; linking complexity; no benefit over ureq for this use case. Rejected.
- **hyper directly:** Low-level; requires tokio. Same objections as reqwest. Rejected.

## Source / Origin

- dtu-assessment.md: httpmock 0.8.3 hermetic strategy; wiremock rejection rationale
- market-intelligence.md §4.2: HTTP client decision section
- BC-2.10.008: Per-host concurrency caps
- DD-016: GET fallback trigger set
