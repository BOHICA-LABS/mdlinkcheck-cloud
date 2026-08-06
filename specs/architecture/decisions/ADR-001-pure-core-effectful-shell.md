---
document_type: adr
adr_id: ADR-001
status: accepted
date: 2026-08-05
subsystems_affected: [SS-01, SS-02, SS-03, SS-04, SS-05, SS-06, SS-07, SS-08, SS-09, SS-10, SS-11, SS-12, SS-13, SS-14]
supersedes: null
superseded_by: null
version: "1.0"
changelog:
  - version: "1.0"
    date: 2026-08-05
    change: "Initial draft — established pure-core/effectful-shell boundary for all 14 subsystems."
---

# ADR-001: Pure-Core / Effectful-Shell Boundary

## Context

Phase 6 of the VSDD pipeline runs formal proofs using Kani (model checking). Kani can
only prove properties of pure, deterministic, side-effect-free functions. A function
that reads from disk, performs a calculation, and writes a result cannot be proven —
the I/O introduces nondeterminism and state that Kani cannot model.

`mdlinkcheck` contains multiple business-logic functions with provable invariants:
the slug algorithm (DI-003, R-001, R-002), the fragment split rule (DI-003),
the exit-code computation (DI-010, DI-011), and the path-comparison logic (DI-002).
Without an architectural separation, these functions will inevitably accumulate I/O
dependencies and become unprovable in Phase 6.

## Decision

All business logic lives in `mdlinkcheck-core` as a library crate composed entirely
of pure functions. The `mdlinkcheck` binary crate is a thin effectful shell: it reads
files, fetches URLs, and writes to stdout/stderr, then hands structured data to the
library for all computation.

No function in `mdlinkcheck-core` may call `std::fs`, `std::net`, `std::io::stdout`,
`std::time::Instant::now`, random-number generators, or any other I/O primitive.
Violations are detectable by code review and by `cargo deny` rules.

## Rationale

This decision directly enables Phase 6 Kani proofs (VP-001..007) on the pure core
modules. Without it, the slug algorithm — the product's primary differentiator (R-001,
R-002) — cannot be formally proven total and deterministic.

The boundary also benefits Phase 3: tests can drive `mdlinkcheck-core` functions
directly with in-memory data, without filesystem setup. Proptest strategies (VP-008..011,
VP-019) operate on pure functions, producing faster and more reliable tests.

The `DirEntries` design is the key constraint: `path_resolver` receives a
pre-populated `Vec<OsString>` from `scanner` instead of calling `fs::read_dir` itself.
This single choice makes the case-sensitive NFC comparison formally verifiable (VP-008).

## Consequences

### Positive
- All 7 P0 Kani proof targets are directly accessible without stubs or mocking
- Property tests drive core logic without filesystem fixtures
- Binary crate becomes a thin wrapper; integration concerns stay in one place
- Fuzz targets (VP-012, VP-013) compile against the library directly

### Negative / Trade-offs
- `ParsedFile` seam type must be maintained as the data handoff contract
- Scanner must eagerly read `DirEntries` for every file even when path resolution
  turns out not to need them (minor memory overhead)
- Adding I/O to a pure-core module requires an ADR update and re-evaluation

### Status as of 2026-08-05

Accepted. Not yet implemented (Phase 1b). Phase 3 implementer must enforce this
boundary; the stub-architect must not create I/O calls in core stubs.

## Alternatives Considered

- **Single crate with feature flags:** Would not isolate I/O at the type level. Kani
  harnesses would need stub injection for I/O calls, which reduces proof coverage.
  Rejected.
- **Trait-based injection (DI):** Pure interfaces with I/O implementations injected.
  Viable but adds trait objects and dynamic dispatch. The data-passing seam is simpler,
  provides stronger purity guarantees, and has no runtime cost. Rejected in favor of ADR-001.

## Source / Origin

- DI-001..011: invariants that must be formally verifiable
- VP-001..007: Kani proof targets that require pure functions
- gene-transfusion-assessment.md §1.4: slug module must be a pure function for Kani
- purity-boundary-map.md: canonical classification of all modules
