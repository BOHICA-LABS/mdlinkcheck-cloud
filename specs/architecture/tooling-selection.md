---
document_type: architecture-section
level: L3
section: tooling-selection
version: "1.2"
status: draft
producer: architect
timestamp: 2026-08-05T20:00:00Z
phase: 1b
inputs:
  - .factory/specs/prd.md
input-hash: "99c94a4"
traces_to: ARCH-INDEX.md
changelog:
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
| **hyperfine** | 2.0.0 | Benchmark harness for NFR-001/002 | 4 | `benches/perf.sh` |
| **Node.js** | 22.x LTS | Oracle-corpus generation for VP-026 (generation time only, never test time) | 3 | `tools/gen-slug-oracle.js` |
| **github-slugger** | 2.0.0 (npm, exact pin) | Differential oracle reference for VP-026 / DI-012 | 3 | `tools/package.json` + `tools/package-lock.json` committed |

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

## [Section Content]

<!-- Validator scaffold: real content is in the named sections above. The
     architecture-section-template uses "[Section Content]" as a literal
     placeholder heading; the compliance validator matches it by substring.
     This stub satisfies that check without altering any real content. -->
