---
document_type: dependency-graph
product: mdlinkcheck
version: "1.0"
producer: story-writer
phase: 2
step: C
generated: 2026-08-10
total_stories: 24
total_edges: 37
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
| 35 | S-7.02 | S-1.02 | ✦ E-7→E-1 | S-7.02 MODIFIES cli.rs (adds ColorMode resolution logic); cli.rs is CREATED in S-1.02 — same-wave collision fix (gate #59 item 4): S-7.02 must run after S-1.02 |
| 36 | S-6.02 | S-3.02 | ✦ E-6→E-3 | S-6.02 MODIFIES app.rs (passes config_error to verdict::exit_code); app.rs is CREATED in S-3.02 — modify-before-create fix (gate #59 item 3): S-6.02 must run after S-3.02 |
| 37 | S-2.03 | S-3.02 | ✦ E-2→E-3 | S-2.03 MODIFIES anchor_table.rs (adds structural test for code-context exclusion); anchor_table.rs is CREATED in S-3.02 — dual-create fix (gate #59 item 6): S-2.03 must run after S-3.02 so it modifies, not re-creates |

Cross-epic edges: 20  Within-epic edges: 17  Total: 37

---

## Acyclicity Proof

Original 34-edge graph verified by Kahn's algorithm (`/tmp/topo_verify.py`, run 2026-08-10).
Re-verified after gate #59 repair (`/tmp/topo_verify_37.py`, run 2026-08-10) with 3 new edges.
Script output (verbatim):

```
============================================================
TOPOLOGICAL SORT VERIFICATION
============================================================
Nodes: 24
Edges: 37

ACYCLICITY: CONFIRMED — no cycles detected

Topological order:
    1. S-1.01
    2. S-1.02
    3. S-1.03
    4. S-3.01
    5. S-3.03
    6. S-5.02
    7. S-6.01
    8. S-7.01
    9. S-7.02
   10. S-1.04
   11. S-2.01
   12. S-7.03
   13. S-2.02
   14. S-3.02
   15. S-4.02
   16. S-5.01
   17. S-2.03
   18. S-3.04
   19. S-4.01
   20. S-6.02
   21. S-5.03
   22. S-4.03
   23. S-5.04
   24. S-7.04

============================================================
BIDIRECTIONAL CONSISTENCY CHECK
============================================================
BIDIRECTIONAL CONSISTENCY: CONFIRMED — 37 edges, 0 violations

============================================================
WAVE ORDERING CHECK
============================================================
WAVE ORDERING: CONFIRMED — all 37 edges satisfy wave[src] > wave[dst]
```

---

## Wave Layers (for downstream wave-scheduler reference)

Wave layers are the topological depth (longest path from the root S-1.01).  These
are DERIVED, not assigned — the Step-D wave scheduler owns wave assignment.

| Layer | Stories |
|-------|---------|
| 0 | S-1.01 |
| 1 | S-1.02, S-1.03, S-3.01, S-3.03, S-5.02, S-6.01 |
| 2 | S-1.04, S-2.01, S-7.01, S-7.02 |
| 3 | S-2.02, S-3.02, S-4.02, S-5.01, S-7.03 |
| 4 | S-2.03, S-3.04, S-4.01, S-5.03, S-6.02 |
| 5 | S-4.03, S-5.04 |
| 6 | S-7.04 |

---

## Root and Leaf Sets

**Root (no prerequisites):** S-1.01  
This is the only story with an empty `depends_on`. It establishes the Cargo workspace,
`Cargo.toml`, `rust-toolchain.toml`, `lib.rs`, and the initial `types.rs` scaffold that
every other story in the product depends on, directly or transitively.

**Leaves (nothing blocks on them):** S-1.04, S-2.02, S-2.03, S-5.04, S-6.02, S-7.04  
_(These remain unchanged after gate #59 repairs. S-2.03 and S-6.02 gained new prerequisites but still block nothing.)_

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

## S-2.03 Stub-Dependency Decision (gate #59 updated)

**Decision revised (gate #59 item 6): blocking edge S-2.03 → S-3.02 ADDED.**

Original reasoning (now superseded): S-2.03 was to create the anchor_table.rs stub
itself, and S-3.02 would create the full implementation — both in layer 3. If run
concurrently, S-3.02 would overwrite the stub. This was classified as an acceptable
race (no edge needed) under the original "stub-only" reasoning.

**Gate #59 correction:** The "create stub" and "create full" in the same wave
constitutes a dual-create same-wave collision (item 6 defect class). The correct
fix is to designate S-3.02 as the sole creator of `anchor_table.rs`, and make
S-2.03 a modifier that runs after S-3.02. Edge 37 (S-2.03 → S-3.02) is added.

S-2.03 now runs in layer 4 (wave 5), after S-3.02 (layer 3, wave 4) creates the
full anchor_table.rs implementation. S-2.03 modifies it by adding code-context
exclusion unit tests. This also eliminates the concurrent-write race risk.

---

## Ambiguous Edges (documented, not added)

### AMB-001: fragment.rs dual creation (S-3.03 and S-4.02)

Both S-3.03 and S-4.02 originally listed `fragment.rs | create` in their File
Structure tables. A file can only be created once.

Resolution chosen: S-3.03 is the primary creator (E-3, anchor checking context).
S-4.02 EXTENDS S-3.03's fragment.rs by adding the VP-004 Kani harness.
This is captured as edge 15 (S-4.02 → S-3.03).

**Gate #59 correction applied:** S-4.02's File Structure table has been updated to
`fragment.rs | modify` (was `create`). The spec inconsistency is now resolved in
the story file itself. Edge 15 rationale stands unchanged.

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

**Gate #59 correction applied:** S-7.01's File Structure table has been updated to
`verdict.rs | modify` and `verdict_tests.rs | modify` (both were `create`). The
spec inconsistencies are now resolved in the story file itself. Edge 27 rationale
stands unchanged. `verdict_tests.rs` dual-create (item 8) also corrected here.

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
| GAP-DEP-001 | spec inconsistency | S-4.02 File Structure | fragment.rs annotated "create" but S-3.03 creates it first; S-4.02 should say "modify" | Gate #59 authorized story-file repair (AMB-001 adjudication) | CLOSED by gate #59: S-4.02 File Structure updated to `fragment.rs \| modify` |
| GAP-DEP-002 | spec inconsistency | S-7.01 File Structure | verdict.rs and verdict_tests.rs annotated "create" but S-1.02 creates both; S-7.01 should say "modify" | Gate #59 authorized story-file repair (AMB-004 adjudication, item 8) | CLOSED by gate #59: S-7.01 File Structure updated to `verdict.rs \| modify` and `verdict_tests.rs \| modify` |
| GAP-DEP-003 | missing within-epic edge | S-6.02 Step-B decomp | S-6.02 had depends_on:[] but both S-6.01 and S-6.02 write filter.rs; parallel dispatch would cause overwrite conflict | Added edge 26 (S-6.02 → S-6.01) in Step C as a correctness fix | Edge added; gap closed |
| GAP-DEP-004 | scope ambiguity | S-5.01 allow_match | S-5.01 adds allow_match to filter.rs; S-6.02 also owns allow_match (BC-2.11.002); implementations may overlap | Wave layer guarantees S-6.02 completes before S-5.03 consumes allow_match; implementer for S-5.01 should write a minimal pass-through that S-6.02 then replaces | Document in implementer dispatch; no graph change needed |
| GAP-DEP-005 | modify-before-create | S-4.02 vs S-3.04 (item 1) | anchor_resolver.rs: S-4.02 (wave 4) declared modify; S-3.04 (wave 5) is the actual creator — ordering violation | Gate #59 operator ruling: move VP-004 P6 fragment-decode integration test to S-3.04; S-4.02 drops anchor_resolver.rs modify entirely | CLOSED by gate #59: S-4.02 File Structure row for anchor_resolver.rs removed; S-3.04 owns the test via existing AC-006 |
| GAP-DEP-006 | modify-before-create | S-4.02 vs S-4.03 (item 2) | path_resolver.rs: S-4.02 (wave 4) declared modify; S-4.03 (wave 6) is the actual creator — ordering violation | Gate #59 operator ruling: move VP-004 P5 path-decode integration test to S-4.03 as AC-024 | CLOSED by gate #59: S-4.02 File Structure row for path_resolver.rs removed; S-4.03 gains AC-024 and BC-2.07.004 |
| GAP-DEP-007 | modify-before-create | S-6.02 vs S-3.02 (item 3) | app.rs: S-6.02 (wave 3) declared modify; S-3.02 (wave 4) is the actual creator — ordering violation | Add dependency edge S-6.02 → S-3.02; recompute wave | CLOSED by gate #59: edge 36 added; S-6.02 moved wave 3→5; S-1.02 blocks updated |
| GAP-DEP-008 | same-wave modify+create | S-7.02 vs S-1.02 (item 4) | cli.rs: S-7.02 (wave 2) declared modify; S-1.02 (wave 2) creates it — same-wave collision | Add dependency edge S-7.02 → S-1.02; recompute wave | CLOSED by gate #59: edge 35 added; S-7.02 moved wave 2→3; S-1.02 blocks updated; S-7.03 cascades wave 3→4 |
| GAP-DEP-009 | modify-without-creator | S-2.02 (item 5) | integration_tests.rs: S-2.02 declared modify but no story creates it — orphaned modify | S-2.02 is earliest story needing the file; it becomes the creator | CLOSED by gate #59: S-2.02 File Structure updated from `modify (or create)` to `create` |
| GAP-DEP-010 | dual-create | S-2.03 + S-3.02 (item 6) | anchor_table.rs: both S-2.03 (wave 4) and S-3.02 (wave 4) declared create in same wave — conflict | S-3.02 is the real creator (builds the three-phase pipeline); add edge S-2.03 → S-3.02 | CLOSED by gate #59: edge 37 added; S-2.03 moved wave 4→5; S-2.03 now declares modify |
| GAP-DEP-011 | dual-create | S-2.01 + S-5.01 (item 7) | url_classifier.rs: S-2.01 (wave 3) and S-5.01 (wave 4) both declared create — but waves already ordered | S-2.01 is the definitive creator; S-5.01 extends it in a later wave | CLOSED by gate #59: S-2.01 File Structure clarified to `create`; S-5.01 updated to `modify` with note |
| GAP-DEP-012 | dual-create | S-1.02 + S-7.01 (item 8) | verdict_tests.rs: S-1.02 (wave 2) and S-7.01 (wave 3) both declared create — but waves already ordered | S-1.02 is the creator; S-7.01 adds Kani proofs; handled together with GAP-DEP-002 (AMB-004) | CLOSED by gate #59: S-7.01 File Structure updated to `verdict_tests.rs \| modify` (combined with GAP-DEP-002 fix) |
