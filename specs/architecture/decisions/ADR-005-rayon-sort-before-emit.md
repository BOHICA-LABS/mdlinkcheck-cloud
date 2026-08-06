---
document_type: adr
adr_id: ADR-005
status: accepted
date: 2026-08-05
version: "1.3"
subsystems_affected: [SS-01, SS-10, SS-12, SS-13]
supersedes: null
superseded_by: null
open_dependencies:
  - id: DEP-001
    artifact: BC-2.03.002
    requirement: "Add postcondition PC7: for all reference forms, the reported Finding position is the use site (byte offset of [text] span), never the [label]: url definition site. Required for sort key totality argument (see Consequences / Negative)."
    status: open
    tracking: "product-owner handoff item P4-005"
changelog:
  - version: "1.3"
    date: 2026-08-06
    change: "P4 remediation: renamed 4th sort-key field from `dest` to `link_target` to match the actual Finding struct field name in api-surface.md. `dest` is a field on ExtractedLink, not Finding. Updated Decision, Rationale, Consequences, and Source/Origin. Moved the open BC-2.03.002 postcondition directive from the body to open_dependencies frontmatter (P4-037 process-gap)."
  - version: "1.2"
    date: 2026-08-05
    change: "P3-019/P3-025 hotfix: added SS-10 to subsystems_affected (SS-10 implementer must not share the global rayon pool with HTTP dispatch — starvation hazard documented here); made DI-001 sort key total by adding `dest` as 4th tie-break field — removes dependency on the unproven full-pipeline DI-005 guarantee (VP-019 covers extraction deduplication only); updated Decision sort key, Rationale determinism-test paragraph, Consequences negative bullet, and Source/Origin"
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
the `Vec<Finding>` by `(nfc_normalize(path), line, column, link_target)` before
passing to the reporter. The `link_target` field (the raw link destination string
on `Finding`) is a final tie-break that makes the sort key total; `sort_unstable_by`
is safe because no two distinct findings can share all four fields when findings
are reported at use-site positions (see BC-2.03.002 postcondition — tracked as
open dependency DEP-001 in frontmatter). This sort is a mandatory pipeline stage —
no finding may bypass it.

For `--online` mode, HTTP results are collected into the `Vec<Finding>` after all
requests complete, then sorted in the same stage.

## Rationale

`rayon` 1.12.0 is the standard Rust parallel iterator library (MIT OR Apache-2.0,
actively maintained). It integrates directly with `ureq` (ADR-004) without tokio.
The `par_iter()` API over the file list in Pass 1, and over the extracted-link list
in Pass 2, provides direct parallelism with minimal boilerplate.

**Sort-before-emit as the ordering guarantee:** DI-001 specifies the primary sort
key `(NFC-normalized file path, line number, column number)`; a `link_target` field
(the `link_target: String` field on `Finding`) is added as a final fourth tie-break
to make the key total. Implementing this as a final sort stage (rather than
maintaining a sorted data structure during parallel processing) is simpler and
correct. The total key removes any dependency on DI-005 (one-verdict-per-link):
even if two findings share `(path, line, column)` — possible for reference-style
links reported at the definition site rather than the use site — `link_target`
disambiguates them deterministically. The sort is O(N log N) over the finding
count, which is dominated by the O(N * K) parsing work (N files, K links each).

**Determinism test:** VP-011 property-tests this guarantee directly: given the same
`Vec<Finding>` in any order, `sort_unstable_by` with the four-field key
`(nfc_normalize(path), line, column, link_target)` must always produce the same
ordering. The total key eliminates equal-element swaps.

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
- Sort key `(nfc_normalize(path), line, column, link_target)` is total for
  implementations that report findings at use-site positions (BC-2.03.002
  postcondition — see DEP-001 in open_dependencies). VP-019 remains a useful
  extraction-layer precondition but is no longer the sole guarantee of sort
  determinism; the `link_target` tie-break removes the DI-005 dependency from
  the ordering proof.
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
- BC-2.10.008: Per-host concurrency caps (governs SS-10 dedicated-pool requirement)
- BC-2.03.002: Reference-style link extraction — use-site finding position is required for sort key totality (open dependency DEP-001 tracked in frontmatter)
- VP-011: Sort determinism property test
