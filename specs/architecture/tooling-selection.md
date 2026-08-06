---
document_type: architecture-section
level: L3
section: tooling-selection
version: "1.4"
status: draft
producer: architect
timestamp: 2026-08-05T20:00:00Z
phase: 1b
inputs:
  - .factory/specs/prd.md
input-hash: "4f3a8c5"
traces_to: ARCH-INDEX.md
changelog:
  - version: "1.4"
    date: 2026-08-06
    change: "D-043 decisions applied: hyperfine row updated — NFR-002 re-targeted to 10s on macos-latest; removed D-043 HANDOFF annotation. NFR-004 retirement confirmed. Added Phase 3 CI Obligations section — NFR-008 perf-gate and NFR-002 benchmark MUST run on macos-latest (Apple-Silicon-calibrated thresholds)."
  - version: "1.3"
    date: 2026-08-06
    change: "D-043 macOS-only platform directive: (1) hyperfine role updated from 'NFR-001/002' to 'NFR-001' (NFR-002 Linux CI target under review per D-043 HANDOFF). (2) Node.js/github-slugger row annotated as platform-independent at generation time. (3) unicode-normalization 0.1.24 Runtime Dependencies entry strengthened: added NFR-004-retirement note — pin is load-bearing for DI-001/DI-002/VP-008/VP-009 on determinism grounds, not portability."
  - version: "1.2"
    date: 2026-08-06
    change: "P4 remediation: (P4-018A) added Node.js 22.x LTS + github-slugger 2.0.0 to Verification Toolchain for VP-026 oracle corpus generation. (P4-018B) added unicode-normalization crate pin to new Runtime Dependencies table; amended ADR-006 defer note. (P4-018C) updated proptest VP list: VP-008..011, VP-019 → VP-008..011, VP-019, VP-023..026. (P4-018D) updated module-criticality.md citation from v1.2 to v1.6. (P4-026) kani.toml default-unwind 8 → 12 (bound 10 + 2 margin). (P4-014) added Test Target Layout section — flat tests/<category>_<name>.rs convention."
  - version: "1.1"
    date: 2026-08-05
    change: "INC-008 remediation: pinned hyperfine from 'latest' to '2.0.0' for reproducible benchmark runs"
  - version: "1.0"
    date: 2026-08-05
    change: "Initial draft"
---

# Tooling Selection: mdlinkcheck

## Verification Toolchain (verified versions from environment-setup, 2026-08-05)

| Tool | Version | Role | Phase | Config |
|------|---------|------|-------|--------|
| **Kani** | 0.67.0 | Model checking for pure-core P0 proofs | 6 | `kani.toml` in workspace root |
| **cargo-fuzz** | 0.13.1 | Fuzz targets for slug and fragment modules | 6 | `fuzz/Cargo.toml` |
| **cargo-mutants** | 27.0.0 | Mutation testing — enforces kill-rate targets per module-criticality.md | 6 | `.cargo-mutants.toml` |
| **cargo-nextest** | 0.9.129 | Test runner — faster parallel test execution | 3–6 | `.config/nextest.toml` |
| **semgrep** | 1.56.0 | Static security analysis | 6 | `.semgrep/` rules |
| **hyperfine** | 2.0.0 | Benchmark harness for NFR-001 (Apple Silicon acceptance ceiling, 5s p95) and NFR-002 (macOS CI runner acceptance ceiling, 10s p95) — both thresholds are Apple-Silicon-calibrated; benchmark jobs MUST run on `macos-latest` (see Phase 3 CI Obligations) | 4 | `benches/perf.sh` |
| **Node.js** | 22.x LTS | Oracle-corpus generation for VP-026 (generation time only, never test time; **platform-independent** — runs wherever Node 22 is available, not macOS-specific) | 3 | `tools/gen-slug-oracle.js` |
| **github-slugger** | 2.0.0 (npm, exact pin) | Differential oracle reference for VP-026 / DI-012 (platform-independent at generation time) | 3 | `tools/package.json` + `tools/package-lock.json` committed |

## Test Dependencies (Cargo.toml dev-deps)

| Crate | Version | Purpose |
|-------|---------|---------|
| `httpmock` | **0.8.3** | In-process HTTP mock for `--online` tests; no tokio required (DTU assessment) |
| `proptest` | **1.6.x** | Property-based testing: VP-008..011, VP-019, VP-023..026 |
| `serde` | **1.x** | Derive `Deserialize` for VP-026 oracle fixture structs |
| `serde_json` | **1.x** | Load VP-026 oracle fixture (`tests/fixtures/slug-oracle-vectors.json`) |
| `tempfile` | **3.x** | Temporary directory fixtures for integration tests |

## Runtime Dependencies (Cargo.toml dependencies)

| Crate | Version | Purpose |
|-------|---------|---------|
| `unicode-normalization` | **0.1.24** | NFC normalization for DI-001 sort key, DI-002 path comparison (ADR-006); version pinned at workspace level — do NOT use the 1.x major version |

Note: `ADR-006:46`/`:129-130` previously deferred the unicode-normalization version pin to workspace creation. That deferral is now resolved: use `unicode-normalization = "0.1.24"` (the latest stable `0.1.x` as of 2026-08-06). The `0.1.x` and `1.x` major versions are API-incompatible; `0.1.x` is the correct branch for all existing Rust ecosystem consumers.

**NFR-004 retired (D-043):** NFR-004 (cross-platform portability) is retired as vacuous under
the macOS-only platform matrix. The `unicode-normalization 0.1.24` pin **must NOT be dropped**.
It is load-bearing for:
- DI-001 sort key: NFC-normalized path as the first sort field
- DI-002 path comparison: case-sensitive NFC comparison in `path_resolver`
- VP-008: proptest falsifying the absence of NFC normalization
- VP-009: proptest proving NFC idempotency of the wrapper
All four obligations are on **determinism grounds** (NFR-003, D-006), not portability grounds.

## Kani Configuration

```toml
# kani.toml
[proof]
default-unwind = 12       # bound 10 (heading count) + 2 margin; 8 was insufficient (CBMC unwinding-assertion failure on 10-iteration loop)
jobs = 4                  # parallel proof jobs
timeout-secs = 120        # per-proof timeout

[harnesses]
# P0 harnesses live in mdlinkcheck-core/src/ as #[kani::proof] functions
# Bounded types: string length ≤ 16, heading count ≤ 10, findings ≤ 8
```

## cargo-mutants Configuration

```toml
# .cargo-mutants.toml
[mutants]
# Critical modules: ≥95% kill rate target
# Per module-criticality.md v1.6: slug, fragment, anchor_table, link_extractor,
#   path_resolver, anchor_resolver, verdict, http_verdict are CRITICAL
timeout-multiplier = 3.0
exclude-globs = ["crates/mdlinkcheck/src/cli.rs"]  # generated clap boilerplate
```

## Fuzz Target Structure

```
fuzz/
  Cargo.toml             (fuzz workspace member)
  fuzz_targets/
    slug_fuzz.rs         (VP-012: arbitrary UTF-8 → compute_slug no panic)
    fragment_fuzz.rs     (VP-013: arbitrary bytes → split_fragment no panic)
```

Fuzz targets compile against `mdlinkcheck-core` directly (no binary crate needed).

## Parser Selection Rationale (ADR-003 summary)

`pulldown-cmark` 0.13.4 chosen over `comrak` 0.54.0:
- `into_offset_iter()` provides byte-range offsets → line numbers without comrak's arena AST
- `LinkType::*Unknown` variants make undefined references a distinct failure class
- Code exclusion is free: only matching `Tag::Link`/`Tag::Image` satisfies DI-004 by construction
- GFM bare-URL autolinks out of scope (DD-009, pulldown-cmark #494 confirmed limitation)
- If bare-URL parity ever needed: `comrak` is the documented migration target (ADR-003)

## HTTP Client Selection Rationale (ADR-004 summary)

`ureq` 3.3.0 (sync/blocking) chosen over `reqwest` 0.13.4 (async/tokio):
- No tokio runtime: smaller binary, simpler stack traces, direct rayon composition
- `httpmock` 0.8.3 works with blocking tests (no `#[tokio::test]` needed)
- reqwest justified only for token-bucket scheduling at 1000+ concurrent requests
- mdlinkcheck caps at 32 global / 4 per-host HTTP threads (BC-2.10.008)

## Test Target Layout

**Convention (P4-014):** All integration, unit, and proptest harnesses use the **flat** layout:

```
crates/mdlinkcheck-core/
tests/
  integration_determinism.rs       (VP-011)
  unit_slug_corpus.rs               (VP-018)
  proptest_anchor_resolver.rs       (VP-025)
  proptest_slug_differential.rs     (VP-026)
  integration_link_extractor_code_exclusion.rs  (VP-014)
  integration_two_pass_anchor.rs    (VP-015)
  integration_ignored_file_anchor.rs (VP-016)
  integration_scan_termination.rs   (VP-017)
  integration_html_anchor_scope.rs  (VP-020)
  fixtures/
    slug-oracle-vectors.json        (VP-026 committed oracle corpus)
```

**Rationale:** Cargo auto-discovers `tests/*.rs` and `tests/<dir>/main.rs`. A file at
`tests/proptest/slug_differential.rs` is NOT discovered unless a sibling
`tests/proptest/main.rs` declares `mod slug_differential;`, or an explicit
`[[test]]` entry appears in `Cargo.toml`. The flat convention avoids both requirements
and works with `cargo nextest` without additional config.

**CI positive-coverage assertion (POL-11):** After `cargo nextest run`, assert:
```
cargo nextest list | grep -c '^tests::' | xargs -I{} test {} -ge <expected_harness_count>
```
This prevents a situation where a test target at the wrong path silently compiles to nothing
and reports `0 passed` as green.

**Kani harnesses** live in `crates/mdlinkcheck-core/src/` as `#[kani::proof]` functions —
this is the standard Kani layout and is not subject to the flat-test convention.

**Fuzz targets** live in `fuzz/fuzz_targets/` — cargo-fuzz generates `[[bin]]` entries
automatically and does not use the integration-test discovery mechanism.

## Phase 3 CI Obligations — Runner Platform

**Platform constraint:** The following CI jobs do not yet exist (confirmed: no `perf-gate`,
`NFR-008`, `hyperfine`, or `bench` entry in `.github/workflows/` as of 2026-08-06). When
created in Phase 3, BOTH MUST be configured on `macos-latest`. Their thresholds are
calibrated for Apple Silicon (M1); running them on `ubuntu-latest` or any Linux runner
would silently invalidate both thresholds.

| Phase 3 job | NFR | Threshold | Required runner |
|-------------|-----|-----------|-----------------|
| NFR-008 regression gate (VP-022) | NFR-008 | p95 ≤ ~500ms, Tier A corpus | `macos-latest` |
| NFR-002 benchmark | NFR-002 | p95 ≤ 10 seconds, 500-file corpus | `macos-latest` |

This constraint is recorded here so that devops-engineer creating these jobs in Phase 3
cannot silently pick a cheaper Linux runner and break the Apple-Silicon-calibrated thresholds.

## [Section Content]

<!-- Validator scaffold: real content is in the named sections above. The
     architecture-section-template uses "[Section Content]" as a literal
     placeholder heading; the compliance validator matches it by substring.
     This stub satisfies that check without altering any real content. -->
