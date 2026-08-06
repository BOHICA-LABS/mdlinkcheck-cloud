---
document_type: adr
adr_id: ADR-002
status: accepted
date: 2026-08-05
subsystems_affected: [SS-01, SS-02, SS-03, SS-04, SS-05, SS-06, SS-07, SS-08, SS-09, SS-10, SS-11, SS-12, SS-13, SS-14]
supersedes: null
superseded_by: null
version: "1.0"
changelog:
  - version: "1.0"
    date: 2026-08-05
    change: "Initial draft — established two-crate Cargo workspace layout (library crate + binary crate)."
---

# ADR-002: Cargo Workspace Layout — Library Crate + Binary Crate

## Context

ADR-001 establishes a pure-core / effectful-shell separation. This separation must
be enforced structurally, not just by convention. Rust's crate system provides the
mechanism: a library crate cannot accidentally call the binary crate's I/O code,
and the library's `pub` API is the explicit contract between shell and core.

Additionally, `cargo-fuzz` requires fuzz targets to live in a separate crate. Kani
proofs work best when operating against a library crate's public API rather than
binary internals. The test ecosystem (proptest, httpmock) also benefits from driving
the library directly without binary-crate overhead.

## Decision

The project uses a Cargo workspace with two crates:

```
Cargo.toml (workspace root, resolver = "2")
crates/mdlinkcheck-core/    — library crate; pure core; all business logic
crates/mdlinkcheck/         — binary crate; thin effectful shell
```

A third implicit member `fuzz/` is added as a workspace member for `cargo-fuzz`
targets targeting `mdlinkcheck-core`.

The workspace root `Cargo.toml` defines shared `[profile.release]` settings:
- `lto = "thin"` (NFR-001 build profile requirement)
- `opt-level = 3`
- `codegen-units = 1`

## Rationale

The two-crate layout enforces ADR-001 at the Rust type-system level: `mdlinkcheck-core`
cannot import from `mdlinkcheck`. The library's public API is the documented,
testable, provable surface. The binary crate is just a consumer.

`cargo-fuzz` fuzz targets must live in a `fuzz/` workspace member — this is the
standard cargo-fuzz layout. Without the workspace, fuzz targets cannot reference
`mdlinkcheck-core`'s internal types.

The `resolver = "2"` setting is required by `clap` 4.6.5 and `ureq` 3.3.0 (edition 2024
dependencies). Setting it at workspace level ensures consistent resolution.

## Consequences

### Positive
- ADR-001 purity constraint is structurally enforced, not convention-based
- cargo-fuzz targets (VP-012, VP-013) compile as a separate workspace member
- `mdlinkcheck-core` can be published to crates.io as a standalone library later
- cargo-mutants and Kani both work cleanly against library-only targets

### Negative / Trade-offs
- Two-crate setup requires story-writer to assign files to the correct crate
- Shared types in `mdlinkcheck-core/src/types.rs` must avoid binary-crate dependencies
- Build times marginally longer (two incremental compilation units)

### Status as of 2026-08-05

Accepted. Workspace root `Cargo.toml` not yet created (Phase 3 scope).
The stub-architect must reflect this layout when generating initial stubs.

## Alternatives Considered

- **Single crate with modules:** Simpler, but cannot structurally enforce ADR-001. Kani
  and fuzz targets would need feature-gated internal access. Rejected.
- **Three crates (core, shell, cli):** Overly granular for this product size. The binary
  crate is thin enough that splitting cli from shell adds no value. Rejected.

## Source / Origin

- ADR-001: establishes the pure-core constraint that this workspace layout enforces
- system-overview.md: Two-Crate Workspace section
- module-decomposition.md: Workspace Layout section
