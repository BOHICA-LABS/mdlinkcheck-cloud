---
document_type: dependency-graph
product: mdlinkcheck
version: "1.0"
producer: story-writer
phase: 2
step: C
generated: 2026-08-10
total_stories: 24
total_edges: 34
acyclicity: CONFIRMED
bidirectional_consistency: CONFIRMED
---

# Story Dependency Graph — mdlinkcheck

## Method

Cross-epic edges were derived by translating the module-level dependency graph in
`specs/architecture/dependency-graph.md` into story-level dependencies.  For each
module consumed by a story, the story that FIRST CREATES that module (or its
foundational types) is identified; that creator story becomes a prerequisite.

Edges satisfy the rule: **A depends_on B** iff A needs a type, module, or data product
that B creates, and that dependency crosses epic boundaries (or, in one case, was
missing from within-epic Step-B decomposition).

Constraints honoured:
- STATE.md not read or written
- `.factory/holdout-scenarios/` not read
- `.factory/specs/` not modified
- Only `depends_on:` and `blocks:` frontmatter fields patched in story files
- No wave-schedule file, STORY-INDEX, or epics.md created or modified
- No placeholders; all ambiguous edges documented with reasoning

---

## Complete Edge Set

Each row: **A depends_on B** (B must complete before A can start).  Cross-epic
edges are marked (✦); the one missing within-epic edge is marked (within).

| # | A (dependent) | B (prerequisite) | Type | Justification |
|---|---------------|------------------|------|---------------|
| 1 | S-1.02 | S-1.01 | within E-1 | cli.rs and verdict stub need workspace + types |
| 2 | S-1.03 | S-1.01 | within E-1 | scanner parsing needs workspace + initial types |
| 3 | S-1.04 | S-1.02 | within E-1 | non-UTF-8 scanner path builds on cli.rs error model |
| 4 | S-1.04 | S-1.03 | within E-1 | non-UTF-8 path extends the parse_file() from S-1.03 |
| 5 | S-2.01 | S-1.03 | ✦ E-2→E-1 | `link_extractor::extract(events: &[OffsetEvent])` — OffsetEvent is added to types.rs in S-1.03; without it the stub cannot compile |
| 6 | S-2.02 | S-2.01 | within E-2 | reference-link extraction extends S-2.01's inline extractor |
| 7 | S-2.03 | S-2.01 | within E-2 | code-context exclusion filters the extractor from S-2.01 |
| 8 | S-3.01 | S-1.01 | ✦ E-3→E-1 | slug.rs is a pure-core leaf module; needs workspace scaffold and types.rs established in S-1.01 |
| 9 | S-3.02 | S-3.01 | within E-3 | anchor_table::build() calls slug::slugify() |
| 10 | S-3.02 | S-2.01 | ✦ E-3→E-2 | app.rs (created here) calls link_extractor::extract() in Pass 1; link_extractor module must exist in mdlinkcheck-core; ParsedHeading type (from S-1.03) is transitive through S-2.01→S-1.03 |
| 11 | S-3.03 | S-1.01 | ✦ E-3→E-1 | fragment.rs is a pure-core leaf module; needs workspace scaffold and types.rs from S-1.01 |
| 12 | S-3.04 | S-3.02 | within E-3 | anchor_resolver uses AnchorTable produced by anchor_table::build() |
| 13 | S-3.04 | S-3.03 | within E-3 | anchor_resolver calls fragment::split() on each link destination |
| 14 | S-4.01 | S-3.02 | ✦ E-4→E-3 | app.rs is first CREATED in S-3.02; S-4.01 adds Pass 1.5 DirIndex construction by MODIFYING that file |
| 15 | S-4.02 | S-3.03 | ✦ E-4→E-3 | fragment.rs is first CREATED in S-3.03; S-4.02 adds the VP-004 Kani harness and P5/P6 integration tests by extending that same module |
| 16 | S-4.02 | S-2.01 | ✦ E-4→E-2 | S-4.02 extends url_classifier.rs (adds empty-destination → Malformed mapping); url_classifier.rs is first CREATED in S-2.01 |
| 17 | S-4.03 | S-4.01 | within E-4 | path_resolver reads DirIndex produced by Pass 1.5 (S-4.01) |
| 18 | S-4.03 | S-4.02 | within E-4 | path_resolver calls fragment::split() extended by S-4.02; also needs empty-dest classification |
| 19 | S-5.01 | S-2.01 | ✦ E-5→E-2 | S-5.01 MODIFIES url_classifier.rs (adds WHATWG http-URL parsing); url_classifier.rs is first CREATED in S-2.01 |
| 20 | S-5.01 | S-6.01 | ✦ E-5→E-6 | S-5.01 MODIFIES filter.rs (adds allow_match hook); filter.rs is first CREATED in S-6.01; the "modify" annotation in S-5.01's File Structure is definitive |
| 21 | S-5.02 | S-1.01 | ✦ E-5→E-1 | http_verdict.rs is a pure-core leaf module; needs workspace scaffold and types.rs (Verdict, BrokenReason, IndeterminateReason base) from S-1.01 |
| 22 | S-5.03 | S-5.01 | within E-5 | http_client uses url_classifier::classify() and filter::allow_match() |
| 23 | S-5.03 | S-5.02 | within E-5 | http_client uses http_verdict::classify_response() |
| 24 | S-5.04 | S-5.03 | within E-5 | transport-error handling extends the http_client from S-5.03 |
| 25 | S-6.01 | S-1.01 | ✦ E-6→E-1 | filter.rs needs workspace scaffold and types.rs (Path, GlobSet wrapper types) from S-1.01 |
| 26 | S-6.02 | S-6.01 | within E-6 | S-6.02 adds allow_match logic to the same filter.rs file CREATED in S-6.01; these MUST be sequential to avoid overwrite conflicts (edge missing from Step-B decomposition) |
| 27 | S-7.01 | S-1.02 | ✦ E-7→E-1 | verdict.rs stub is CREATED in S-1.02; S-7.01 implements the full logic + Kani proofs by MODIFYING that file |
| 28 | S-7.02 | S-1.01 | ✦ E-7→E-1 | reporter.rs is a new pure-core module; needs workspace scaffold and types.rs (Finding, Verdict) from S-1.01 |
| 29 | S-7.03 | S-7.02 | within E-7 | JSON formatter extends the reporter.rs created in S-7.02 |
| 30 | S-7.04 | S-7.01 | within E-7 | main.rs calls verdict::exit_code() |
| 31 | S-7.04 | S-7.02 | within E-7 | main.rs dispatches to reporter::format_text() |
| 32 | S-7.04 | S-7.03 | within E-7 | main.rs dispatches to reporter::format_json() |
| 33 | S-7.04 | S-3.04 | ✦ E-7→E-3 | anchor_resolver must be implemented for app::run() to perform anchor checking; S-7.04 integration tests execute the full pipeline |
| 34 | S-7.04 | S-4.03 | ✦ E-7→E-4 | path_resolver must be implemented for app::run() to perform file-link resolution; S-7.04 integration tests execute the full pipeline |

Cross-epic edges: 17  Within-epic edges: 17  Total: 34

---

## Acyclicity Proof

Verified by Kahn's algorithm (`/tmp/topo_verify.py`, run 2026-08-10).
Script output (verbatim):

```
============================================================
TOPOLOGICAL SORT VERIFICATION
============================================================
Nodes: 24
Edges: 34

ACYCLICITY: CONFIRMED — no cycles detected

Topological order:
   1. S-1.01
   2. S-1.02
   3. S-1.03
   4. S-3.01
   5. S-3.03
   6. S-5.02
   7. S-6.01
   8. S-7.02
   9. S-7.01
  10. S-1.04
  11. S-2.01
  12. S-6.02
  13. S-7.03
  14. S-2.02
  15. S-2.03
  16. S-3.02
  17. S-4.02
  18. S-5.01
  19. S-3.04
  20. S-4.01
  21. S-5.03
  22. S-4.03
  23. S-5.04
  24. S-7.04

============================================================
BIDIRECTIONAL CONSISTENCY CHECK
============================================================
BIDIRECTIONAL CONSISTENCY: CONFIRMED — 34 edges, 0 violations
```

---

## Wave Layers (for downstream wave-scheduler reference)

Wave layers are the topological depth (longest path from the root S-1.01).  These
are DERIVED, not assigned — the Step-D wave scheduler owns wave assignment.

| Layer | Stories |
|-------|---------|
| 0 | S-1.01 |
| 1 | S-1.02, S-1.03, S-3.01, S-3.03, S-5.02, S-6.01, S-7.02 |
| 2 | S-1.04, S-2.01, S-6.02, S-7.01, S-7.03 |
| 3 | S-2.02, S-2.03, S-3.02, S-4.02, S-5.01 |
| 4 | S-3.04, S-4.01, S-5.03 |
| 5 | S-4.03, S-5.04 |
| 6 | S-7.04 |

---

## Root and Leaf Sets

**Root (no prerequisites):** S-1.01  
This is the only story with an empty `depends_on`. It establishes the Cargo workspace,
`Cargo.toml`, `rust-toolchain.toml`, `lib.rs`, and the initial `types.rs` scaffold that
every other story in the product depends on, directly or transitively.

**Leaves (nothing blocks on them):** S-1.04, S-2.02, S-2.03, S-5.04, S-6.02, S-7.04

The product is complete when all six leaves are green:
- S-1.04: scanner complete (UTF-8 errors + explicit file args)
- S-2.02: reference-style link extraction complete
- S-2.03: code-context exclusion + anchor-table structural guarantee complete
- S-5.04: http_client complete (transport errors, dedup, private-IP block)
- S-6.02: filter complete (allow_match full algorithm)
- S-7.04: CLI full routing complete (format flags, exit codes, main.rs wiring)

---

## Co-Implemented Behavioral Contracts

Three BCs span multiple stories and are only fully satisfied once all contributing
stories are complete.

| BC | Contributing Stories | Nature of Split |
|----|---------------------|-----------------|
| BC-2.07.001 | S-4.01, S-4.02, S-4.03 | DirIndex (S-4.01) provides the data product; fragment::split + empty-dest (S-4.02) provides the precondition enforcement; path_resolver (S-4.03) provides the full resolution algorithm |
| BC-2.07.002 | S-4.01, S-4.03 | DirIndex construction (S-4.01) + resolution invariants for same-directory relative paths (S-4.03) |
| BC-2.07.003 | S-4.01, S-4.03 | DirIndex construction (S-4.01) + git-root boundary invariant (S-4.03) |

Dependency graph already guarantees ordering: S-4.03 depends on both S-4.01 and S-4.02
(within-epic), so all three BC-2.07.001 contributors are complete before S-4.03 finishes.

---

## S-2.03 Stub-Dependency Decision

**Decision: stub-only relationship — no blocking edge between S-2.03 and S-3.02.**

Reasoning:

S-2.03 (BC-2.04.003 AC-010) writes a unit test that calls `anchor_table::build`
directly to verify a structural guarantee: fenced code-block events produce zero
`Tag::Heading` events in the pulldown-cmark parse stream.  The test needs
`anchor_table::build` to exist as a compilable symbol — a `todo!()` stub body is
sufficient to reach Red Gate (the test compiles, then panics with todo!(), satisfying
the ≥0.5 density gate).

S-2.03 creates that stub itself (File Structure: "create stub (if not yet present)"),
so it does not need S-3.02 to have run first.  Conversely, S-3.02 creates
`anchor_table.rs` from scratch in its own Task 1 ("Create anchor_table.rs with todo!()
stubs"), so S-3.02 does not depend on S-2.03's stub either.

Once S-3.02 implements `anchor_table::build` correctly, S-2.03's AC-010 test passes
as a welcome side-effect.  No ordering edge is needed: S-2.03 and S-3.02 can be in
the same wave (layer 3 and layer 3 respectively, both after S-2.01 and S-3.01 /
S-1.01 respectively).  If they run concurrently, the implementer for S-3.02 will
overwrite the stub with the real implementation; S-2.03's test then passes.

---

## Ambiguous Edges (documented, not added)

### AMB-001: fragment.rs dual creation (S-3.03 and S-4.02)

Both S-3.03 and S-4.02 list `fragment.rs | create` in their File Structure tables.
A file can only be created once.

Resolution chosen: S-3.03 is the primary creator (E-3, anchor checking context).
S-4.02 EXTENDS S-3.03's fragment.rs by adding the VP-004 Kani harness and P5/P6
integration tests.  This is captured as edge 15 (S-4.02 → S-3.03).

The "create" annotation in S-4.02's File Structure is a spec inconsistency; it should
read "modify."  This is noted but not corrected (`.factory/specs/` is read-only).

### AMB-002: url_classifier.rs ordering (S-2.01, S-4.02, S-5.01)

Three stories modify url_classifier.rs:
- S-2.01 creates it (inline link extraction, stub classify())
- S-4.02 adds empty-destination → Malformed mapping
- S-5.01 adds full WHATWG http-URL parsing

S-4.02 and S-5.01 add independent, orthogonal features to url_classifier.rs (empty
dest vs. http parsing).  Neither needs the other's changes to compile.  The dependency
chain is therefore: S-4.02 → S-2.01 and S-5.01 → S-2.01, without an edge between
S-4.02 and S-5.01.  If dispatched in parallel, the two stories touch different
function slots in url_classifier.rs; merge conflict risk is low.

### AMB-003: filter.rs and allow_match ownership (S-5.01 vs S-6.02)

S-5.01 adds `filter::allow_match` as a hook.  S-6.02 implements the full
BC-2.11.002 allow_match algorithm.  Both reference the same function name.

Chosen model: S-5.01 adds the function signature and a minimal implementation
sufficient for E-5 unit tests; S-6.02 delivers the complete algorithm with VP-010
proptest coverage.  These are SEQUENTIAL (S-6.01 creates filter.rs, S-6.02 extends
it — edge 26), so S-6.02 will fill in allow_match completely.  S-5.01 runs AFTER
S-6.01 (edge 20) and may run concurrently with S-6.02 (both in layer 3), with
S-6.02 providing the authoritative allow_match before S-5.03 depends on the full
implementation.

The wave scheduler should verify that S-5.03 (which calls allow_match) is dispatched
only after both S-5.01 and S-6.02 are complete.  From the graph: S-5.03 depends on
S-5.01 (edge 22); S-5.01 depends on S-6.01 (edge 20); S-6.02 depends on S-6.01
(edge 26).  S-6.02 is at layer 2 and S-5.03 is at layer 4, so S-6.02 precedes
S-5.03 in any valid schedule.  No additional edge needed.

### AMB-004: verdict.rs dual creation (S-1.02 and S-7.01)

S-1.02 creates `verdict.rs` with a basic `exit_code()` implementation.
S-7.01 provides the full implementation with Kani proofs.

This is an intentional decomposition: S-1.02's verdict is "good enough" for early
integration; S-7.01 hardens it.  Edge 27 (S-7.01 → S-1.02) captures this.
The "create" annotation in S-7.01's story should read "modify"; not corrected
per read-only constraint on specs/.

---

## BC to Stories Traceability Matrix

| Epic | BC (sample — not exhaustive) | Primary Story | Contributing Stories |
|------|------------------------------|---------------|----------------------|
| E-1 | BC-2.01.001–009 | S-1.01, S-1.02, S-1.03, S-1.04 | — |
| E-2 | BC-2.04.001–004 | S-2.01, S-2.02 | S-2.03 (structural guarantee) |
| E-3 | BC-2.08.001–006 | S-3.01, S-3.02, S-3.03, S-3.04 | — |
| E-4 | BC-2.07.001–008 | S-4.03 | S-4.01, S-4.02 (co-impl) |
| E-5 | BC-2.09.001–006 | S-5.01, S-5.02, S-5.03, S-5.04 | — |
| E-6 | BC-2.11.001–004 | S-6.01, S-6.02 | S-5.01 (allow hook) |
| E-7 | BC-2.14.001–003 | S-7.01 | S-1.02 (stub) |
| E-7 | BC-2.15.001–003 | S-7.02, S-7.03, S-7.04 | — |

Full per-BC AC traceability is embedded in each individual story file.

---

## Gap Register

| Gap ID | Type | Source | Description | Justification | Resolution |
|--------|------|--------|-------------|---------------|------------|
| GAP-DEP-001 | spec inconsistency | S-4.02 File Structure | fragment.rs annotated "create" but S-3.03 creates it first; S-4.02 should say "modify" | Spec files are read-only and frozen; the correct dependency edge (S-4.02 → S-3.03) is added to the graph | Accept as-is; implementer must read S-3.03 before implementing S-4.02 |
| GAP-DEP-002 | spec inconsistency | S-7.01 File Structure | verdict.rs annotated "create" but S-1.02 creates the stub; S-7.01 should say "modify" | Same constraint | Accept as-is; implementer reads S-1.02 before S-7.01 |
| GAP-DEP-003 | missing within-epic edge | S-6.02 Step-B decomp | S-6.02 had depends_on:[] but both S-6.01 and S-6.02 write filter.rs; parallel dispatch would cause overwrite conflict | Added edge 26 (S-6.02 → S-6.01) in Step C as a correctness fix | Edge added; gap closed |
| GAP-DEP-004 | scope ambiguity | S-5.01 allow_match | S-5.01 adds allow_match to filter.rs; S-6.02 also owns allow_match (BC-2.11.002); implementations may overlap | Wave layer guarantees S-6.02 completes before S-5.03 consumes allow_match; implementer for S-5.01 should write a minimal pass-through that S-6.02 then replaces | Document in implementer dispatch; no graph change needed |
