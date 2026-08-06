---
document_type: adr
adr_id: ADR-005
status: accepted
date: 2026-08-05
version: "1.1"
subsystems_affected: [SS-01, SS-12, SS-13]
supersedes: null
superseded_by: null
changelog:
  - version: "1.1"
    date: 2026-08-05
    change: "Phase 1d F-010 remediation: reinforced the two-pool model — dedicated 32-thread HTTP pool vs. global file-scan pool; documented the starvation hazard of pool sharing; cross-referenced ADR-004 dedicated-pool requirement"
---

# ADR-005: rayon Parallelism + Sort-Before-Emit for Determinism

## Context

R8 requires scanning 500 `.md` files in under 5 seconds on an M-series laptop.
DI-001 requires that two runs with identical inputs produce byte-identical stdout.
These two requirements are in tension: parallelism processes files in nondeterministic
order; determinism requires a stable output order.

The reconciliation must not impose a global lock that serializes the scan. The
ordering guarantee must be enforceable and verifiable (VP-011).

## Decision

Use `rayon` 1.12.0 for parallel processing in both Pass 1 (parse + index) and
Pass 2 (resolve + classify). After Pass 2 collects all `Finding` objects, sort
the `Vec<Finding>` by `(nfc_normalize(path), line, column)` before passing to
the reporter. This sort is a mandatory pipeline stage — no finding may bypass it.

For `--online` mode, HTTP results are collected into the `Vec<Finding>` after all
requests complete, then sorted in the same stage.

## Rationale

`rayon` 1.12.0 is the standard Rust parallel iterator library (MIT OR Apache-2.0,
actively maintained). It integrates directly with `ureq` (ADR-004) without tokio.
The `par_iter()` API over the file list in Pass 1, and over the extracted-link list
in Pass 2, provides direct parallelism with minimal boilerplate.

**Sort-before-emit as the ordering guarantee:** DI-001 specifies the sort key
explicitly: `(NFC-normalized file path, line number, column number)`. Implementing
this as a final sort stage (rather than maintaining a sorted data structure during
parallel processing) is simpler and correct. The sort is O(N log N) over the finding
count, which is dominated by the O(N * K) parsing work (N files, K links each).

**Determinism test:** VP-011 property-tests this guarantee directly: given the same
`Vec<Finding>` in any order, `sort_unstable_by` with the DI-001 key must always
produce the same ordering.

**Two-pool model — file-scan pool and HTTP pool are separate instances:** For `--online`
mode, a dedicated rayon thread pool (separate from the global/file-scan pool) sized at
exactly 32 threads handles HTTP dispatch. Within that dedicated pool, per-host semaphores
enforce the 4-per-host cap (BC-2.10.008). The file-scan pool (Passes 1 and 2) and the
HTTP pool (--online URL checks) MUST be distinct `rayon::ThreadPool` instances — see
ADR-004 for the starvation hazard of sharing. The 32-thread HTTP pool size is fixed and
does not scale with CPU count; this is an architectural constant, not a heuristic.

## Consequences

### Positive
- `rayon::par_iter()` over file lists provides near-linear parallelism speedup
- DI-001 determinism is a simple sort; no complex synchronization needed
- VP-011 can verify the sort property in isolation
- `--online` HTTP concurrency is naturally controlled by pool size

### Negative / Trade-offs
- `sort_unstable_by` is not stable — two findings with identical (path, line, col) may
  swap order. This is acceptable only if each link produces at most one finding (DI-005).
  VP-019 verifies this invariant.
- rayon thread pool is a global resource; tests that run concurrently must not
  interfere (use separate test fixtures)

### Status as of 2026-08-05

Accepted. Parallelism not yet implemented (Phase 3 scope).

## Alternatives Considered

- **Single-threaded scan:** Deterministic by default but cannot meet NFR-001 on large repos. Rejected.
- **Sorted concurrent map (BTreeMap):** Inserting findings into a sorted structure during
  parallel processing requires a `Mutex<BTreeMap<...>>`, which creates contention.
  Sort-after-collection is faster and simpler. Rejected.
- **async/tokio for file scan:** Would require tokio runtime (conflicts with ADR-004). Rejected.

## Source / Origin

- DI-001: Deterministic output ordering invariant
- DD-012: Output ordering decision
- NFR-001/002: Performance targets
- BC-2.10.008: Per-host concurrency caps
- VP-011: Sort determinism property test
