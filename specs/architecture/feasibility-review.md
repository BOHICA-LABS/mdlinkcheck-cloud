---
document_type: architecture-feasibility-report
level: L4
version: "1.3"
status: accepted
producer: architect
timestamp: 2026-08-06T00:00:00Z
phase: 1b
outcome: APPROVE
inputs:
  - .factory/specs/prd.md
  - .factory/specs/prd-supplements/nfr-catalog.md
  - .factory/specs/behavioral-contracts/BC-INDEX.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/purity-boundary-map.md
input-hash: "05c4a7d"
prd_version: "1.0"
traces_to: .factory/specs/architecture/ARCH-INDEX.md
changelog:
  - version: "1.3"
    date: 2026-08-06
    change: "D-043 decisions applied: (1) NFR-004 retirement confirmed — NFR Coherence note updated from 'under review for retirement' to 'retired as vacuous per D-043' (unicode-normalization pin retained on determinism grounds). (2) N-003 updated — NFR-002 re-targeted to p95 ≤ 10 seconds on macos-latest; removed HANDOFF placeholder; title updated to reflect decisions are final."
  - version: "1.2"
    date: 2026-08-06
    change: "D-043 macOS-only platform directive: updated NFR Coherence section — NFR-004 (cross-platform portability) noted as under review for retirement (macOS-only makes it vacuous; unicode-normalization 0.1.24 pin is retained on DI-001/DI-002 determinism grounds, independent of NFR-004 status). Updated N-003 — NFR-002 (Linux CI) noted as D-043 HANDOFF for product-owner decision (retire vs. re-target)."
---

# Architecture Feasibility Review: mdlinkcheck PRD v1.0

## Summary

**Outcome: APPROVE**

The 14-subsystem grouping in the PRD is architecturally feasible. Subsystem
boundaries align with the pure-core / effectful-shell separation required by
ADR-001, and with the module decomposition designed in this phase. No
restructuring is required.

Three SHOULD-FIX items are recorded — they are story-writer guidance issues, not
PRD restructuring issues. Four NOTEs document architectural decisions that
story-writers must apply consistently. There are no BLOCKING issues.

---

## Executive Summary

See § Summary above. This section is a template-required alias; all executive
summary content is in § Summary.

---

## Review Criteria Assessment

### NFR Coherence

All 7 NFRs from nfr-catalog.md are either:
- **Cross-cutting** (NFR-001/002 performance, NFR-003 determinism, NFR-004
  portability, NFR-005 memory) — no single subsystem owns them; the pipeline
  architecture (app.rs + rayon parallelism) satisfies them collectively.
- **Module-scoped** (NFR-006 slug fidelity → SS-06/slug.rs, NFR-007 reason
  codes → SS-11..SS-14/reporter.rs+verdict.rs) — these map cleanly to a single
  module.

No subsystem has conflicting NFR profiles (e.g., "real-time latency AND batch
processing"). NFR coherence: PASS.

**D-043 decision — NFR-004 retired:** NFR-004 (cross-platform portability) is
retired as vacuous under the macOS-only platform directive (recorded per POL-1; not
deleted). There are no other platforms to be portable to. The `unicode-normalization
0.1.24` pin that NFR-004 previously anchored is retained on determinism grounds
(DI-001, DI-002): the NFC normalization layer must produce byte-identical results for
byte-identical repository content, independent of APFS NFD storage. The pin survives
NFR-004 retirement unchanged.

### Integration Feasibility

The two-pass pipeline design (DI-008) requires:
1. Pass 1: SS-01 (scanner) → SS-02 (parse) → SS-03/SS-04 (extract + exclude) →
   SS-05 (anchor table) → SS-06 (slugify)
2. Pass 2: SS-07/SS-08 (resolve) → SS-09/SS-10 (online check) → SS-11 (filter)
   → SS-12/SS-13 (report) → SS-14 (exit code)

The data hand-off between passes is the `HashMap<PathBuf, (AnchorTable, Vec<ExtractedLink>)>`
seam type, produced entirely in Pass 1. This seam supports clean subsystem
integration without circular dependencies. Integration feasibility: PASS.

### Purity Boundary Alignment

All SS-01..SS-14 subsystems' BCs can be implemented with the ADR-001 purity
boundary intact, subject to the SHOULD-FIX items below. The only subsystem
that straddles the pure/effectful boundary by design is SS-10 (HTTP checking):
the verdict logic (`http_verdict.rs`) is pure; the I/O (`http_client.rs`) is
effectful. This split is architecturally correct per ADR-004. Purity alignment:
PASS with SHOULD-FIX items (see SF-001, SF-002).

### Verifiability

All 11 domain invariants (DI-001..011) have at least one VP (VP-INDEX.md,
20 VPs total). The subsystem structure does not interfere with VP proof
strategies — all 7 Kani P0 proofs target pure core modules that map to
single well-defined subsystems (SS-06, SS-08, SS-14, SS-10). The proptest
and integration VPs likewise map to subsystem boundaries without cross-cutting.
Verifiability: PASS.

---

## Constraint Mapping

No architectural constraints requiring mapping to external systems were
identified. All subsystem constraints derive from the ADR set (ADR-001..007)
and the pure/effectful boundary is enforced structurally. See purity-boundary-map.md
for the full constraint map by module.

---

## Subsystem Grouping Assessment

The 14-subsystem grouping is assessed feasible. See § Review Criteria Assessment
above for the full analysis by criterion (NFR coherence, integration feasibility,
purity boundary alignment, verifiability).

Summary by subsystem:
- SS-01..SS-06 (Pass 1): pure-core + scanner effectful shell; clean boundary.
- SS-07..SS-10 (Pass 2 resolution + online): SS-10 has an intentional
  pure/effectful split (ADR-004); all others are pure.
- SS-11..SS-14 (filter + report + exit): fully pure-core.

No subsystem regrouping required.

---

## Subsystem-to-Module Mapping

See ARCH-INDEX.md § Subsystem Registry for the authoritative SS-NN → module
mapping, and module-decomposition.md for per-module specifications.

Preliminary mapping summary:

| SS-NN | Module(s) |
|-------|-----------|
| SS-01 | scanner |
| SS-02 | scanner, link_extractor |
| SS-03 | link_extractor |
| SS-04 | link_extractor (via pulldown-cmark events) |
| SS-05 | anchor_table |
| SS-06 | slug |
| SS-07 | path_resolver, fragment |
| SS-08 | anchor_resolver, fragment |
| SS-09 | url_classifier |
| SS-10 | http_client, http_verdict |
| SS-11 | filter |
| SS-12 | reporter |
| SS-13 | reporter |
| SS-14 | verdict |

---

## BLOCKING Findings

None.

---

## SHOULD-FIX Findings

### SF-001: SS-02 Purity Boundary Ambiguity — BOM/CRLF Preprocessing Location

**Subsystem:** SS-02 (Markdown Parsing)
**BCs affected:** BC-2.02.002 (UTF-8 BOM stripping and CRLF normalization)

**Issue:** BC-2.02.002 describes preprocessing that MUST be performed in
`scanner.rs` (effectful shell) before the file content reaches any pure-core
module. If a story-writer reads BC-2.02.002 and implements it inside
`link_extractor.rs` or as part of the pulldown-cmark invocation in pure core,
the `mdlinkcheck-core` library would call `str::replace` on mutable strings,
which is pure, but the BOM detection step requires inspecting the file's raw
bytes — a concern of the scanner, not the parser.

**Required action for story-writer:** The story for BC-2.02.002 must explicitly
assign BOM stripping and CRLF normalization to `scanner.rs`. The string passed
to `pulldown-cmark::Parser::new()` must already be BOM-free and LF-normalized.
No pure core module should perform BOM/CRLF handling.

**Architectural note:** If BOM stripping is a pure `str` transformation on an
already-read `&str`, it may be implemented as a pure helper in `types.rs` or
`link_extractor.rs`. But the BOM DETECTION (checking `[0xEF, 0xBB, 0xBF]` at
byte 0 of the file buffer) is a byte-level operation that belongs in `scanner.rs`.
The story must distinguish detection (effectful shell) from stripping (could be
pure helper). Recommend: scanner detects and strips in one step during file read.

---

### SF-002: BC-2.08.003 Scope Mixing — Non-Markdown and Directory Targets in Anchor Resolution

**Subsystem:** SS-08 (Anchor Resolution)
**BC affected:** BC-2.08.003 ("Empty fragment, non-Markdown targets, and directories pass")

**Issue:** BC-2.08.003 groups three distinct resolver behaviors under SS-08
(Anchor Resolution), but two of them are path resolution concerns (SS-07):
- "Non-Markdown file targets pass without anchor check" — this is a routing
  decision in `url_classifier.rs` or `path_resolver.rs`: if the target file
  is not `.md`, skip anchor resolution.
- "Directory targets pass if directory exists" — this is `path_resolver.rs`
  (BC-2.07.005 also covers directory links, creating potential duplication).

If a story-writer implements these in `anchor_resolver.rs`, they will add
path-inspection logic (calling into path_resolver) inside anchor resolution,
creating a module coupling that violates the dependency order
(`anchor_resolver.rs` must not call `path_resolver.rs` — they are siblings).

**Required action for story-writer:** The story for BC-2.08.003 must route
the "non-Markdown target" and "directory target" cases to `path_resolver.rs`
(or `url_classifier.rs` for the routing decision). Only the "empty fragment
passes" case belongs in `anchor_resolver.rs`. Consider splitting BC-2.08.003
into implementation story tasks for the three distinct cases.

---

### SF-003: BC-2.04.003 Cross-Module Concern — Headings Inside Code Blocks Must Not Enter Anchor Table

**Subsystem:** SS-04 (Code Context Exclusion)
**BC affected:** BC-2.04.003 ("ATX headings inside fenced blocks do not create anchor entries")

**Issue:** BC-2.04.003 is placed in SS-04 and will naturally be assigned to the
`link_extractor.rs` story. However, heading entries are built by `anchor_table.rs`
(SS-05), not `link_extractor.rs`. Preventing headings inside code blocks from
entering the anchor table requires that `anchor_table::build` also filters on
event context — or more precisely, that the event stream fed to `anchor_table`
correctly marks code-block events so headings inside them are not processed.

With pulldown-cmark's event model, this is free by construction: headings inside
fenced code blocks appear as `Event::Text` inside a `Tag::CodeBlock`, not as
`Tag::Heading`. So `anchor_table::build`, which matches `Tag::Heading` events,
naturally excludes them. But this must be explicitly verified.

**Required action for story-writer:** The story for BC-2.04.003 must include
an acceptance criterion in BOTH `link_extractor.rs` context (no link extraction)
AND `anchor_table.rs` context (no heading extraction). VP-014 covers link
extraction; no VP currently covers the anchor_table exclusion. This gap is
acceptable for Phase 3 (integration test suffices) but the story must include
a test asserting that `anchor_table::build` produces no entry for headings
inside fenced code.

---

## NOTE Findings

### N-001: SS-10 Spans Pure/Effectful Boundary — Story-Writer Must Split Stories Accordingly

**Subsystem:** SS-10 (External URL Liveness Checking)

SS-10 contains both pure-core logic (`http_verdict.rs`: classifies HTTP responses
into the three-verdict model, provable by Kani VP-007) and effectful-shell I/O
(`http_client.rs`: makes actual HTTP requests via ureq). This is the correct
architecture (ADR-004). Story-writer must assign BCs as follows:

- BC-2.10.002 (three-verdict model classification logic): story touches `http_verdict.rs` (pure)
- BC-2.10.001, BC-2.10.003..BC-2.10.008: stories touch `http_client.rs` (effectful)

Do not implement HTTP classification logic inside `http_client.rs` — it must be
split to preserve Kani provability of VP-007.

---

### N-002: SS-09 URL Parsing Crate — RESOLVED

**Subsystem:** SS-09 (External URL Syntax Validation)
**Resolution date:** 2026-08-05
**Resolved by:** Architect agent (NOTE-2 surgical patch)

**Original issue:** BC-2.09.001 requires WHATWG URL parsing. The `url` crate
(servo/rust-url) is the standard Rust implementation. This crate was not listed
in market-intelligence §4.2 and the story-writer was asked to select and pin
the version.

**Resolution:** The `url` crate has been pinned in dependency-graph.md.

- **Pinned version:** `url = "2.5.8"` (crates.io verified 2026-08-05 via API)
- **Published:** 2026-01-05
- **MSRV:** Rust 1.63 — compatible with project MSRV 1.85
- **License:** `MIT OR Apache-2.0` — both permitted by `deny.toml`
- **WHATWG compliance:** Yes (servo/rust-url is the reference implementation)
- **Purity:** `url::Url::parse()` is deterministic, performs no I/O; assigned to
  pure core (`url_classifier`). DD-010 (syntax failure = `malformed-url`) and
  DD-013 (normalized-URL `--allow` prefix matching) are both satisfied by the
  WHATWG-compliant `Url::parse()` + `Url::as_str()` normalization.
- **`percent-encoding` redundancy verdict:** NOT redundant. `url 2.5.8` takes
  `percent-encoding ^2.3.2` as an internal transitive dep but does not re-export
  it. `path_resolver` must call `percent_encoding::percent_decode_str` directly
  for path component decoding; that dependency is retained. No version conflict
  (both direct and transitive reference the same `2.3.2`).
- **`url_classifier` dep line updated:** `url_classifier ← types, url`
  (no longer lists `percent-encoding` as a direct dep of this module).
- **ADR:** Not added. The `url` crate is the only viable WHATWG parser in Rust;
  the choice is not a trade-off decision requiring a load-bearing ADR.

Story-writer must add `url = "2.5.8"` to `mdlinkcheck-core`'s `[dependencies]`
in `Cargo.toml` when implementing SS-09.

---

### N-003: NFR-001/002 Performance Targets — D-043 Decisions Final

**NFRs:** NFR-001 (5s p95, Apple Silicon M-series), NFR-002 (10s p95, `macos-latest`, shared Apple Silicon M1)

The architecture (rayon parallelism, two-crate workspace, `--release lto=thin`) is
designed to satisfy both. D-043 decisions confirmed by PO:

- **NFR-001:** p95 ≤ 5 seconds on Apple Silicon M-series — unchanged.
- **NFR-002:** p95 ≤ 10 seconds on `macos-latest` (shared Apple Silicon M1) — re-targeted
  per D-043. The original Linux CI baseline (15s on ubuntu-latest) is retired. NFR-002
  is kept distinct from NFR-001 because `macos-latest` is shared CI infrastructure and
  materially slower than a dedicated developer machine; one ceiling covering both would
  be wrong for one of them.

Both thresholds are Apple-Silicon-calibrated. VP-022 and all Phase 3 perf-gate CI jobs
MUST run on `macos-latest` (see tooling-selection.md § Phase 3 CI Obligations).

---

### N-004: BC-2.05.003 Title Conflates Two Independent Invariants

**Subsystem:** SS-05 (Anchor Table Construction)
**BC:** BC-2.05.003 ("Ignored-file anchor tables built; two-pass design enforced")

The BC title conflates two independent architectural invariants:
1. Ignored files have anchor tables built (DI-006) — an observable behavior.
2. Two-pass design is enforced (DI-008) — an architectural constraint.

These should logically be separate BCs. As written, the single BC creates a
story that must simultaneously demonstrate (a) ignored-file anchor target
correctness and (b) two-pass pipeline ordering. Both VP-015 and VP-016 cover
these separately.

This does not require PRD restructuring (the behavior is fully captured), but
the story-writer should split the implementation tasks to address each invariant
independently. No action required on the PRD.

---

## Risks and Mitigations

No blocking risks identified at this review stage. Active risks:

- **N-003 (provisional NFR targets):** Risk that performance targets are
  unachievable. Mitigation: architecture uses rayon + two-crate design;
  benchmarks are a Phase 4 deliverable.
- **N-004 (conflated BC):** Risk of incomplete implementation if story-writer
  doesn't split tasks. Mitigation: captured above with explicit story-writer
  guidance.

---

## Decision Log

| Date | Decision | Rationale |
|------|---------|-----------|
| 2026-08-05 | APPROVE — no restructuring required | All 14 subsystems map cleanly to the module decomposition. No NFR conflicts. Pure/effectful boundary is maintained across all subsystems with SHOULD-FIX guidance. |
| 2026-08-05 | SF-001..003 are story-writer guidance, not PRD changes | The issues are implementation-boundary clarifications. Editing the PRD or BCs would be premature; capturing them here gives the story-writer precise guidance without invalidating the 58 existing BCs. |
| 2026-08-05 | N-002 RESOLVED — `url 2.5.8` pinned | Verified via crates.io API: MSRV 1.63 ≤ 1.85, MIT OR Apache-2.0 license allowed by deny.toml, WHATWG-compliant, `percent-encoding` not redundant. dependency-graph.md and purity-boundary-map.md updated. |

---

## Approval

**Status: APPROVED** — 2026-08-05

All 14 subsystems are feasible. Three SHOULD-FIX items require story-writer
attention; zero items require PRD restructuring. NOTE findings are informational.
The architecture proceeds to Phase 2 story decomposition.
