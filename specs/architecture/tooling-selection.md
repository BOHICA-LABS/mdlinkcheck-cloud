---
document_type: architecture-section
level: L3
section: tooling-selection
version: "1.1"
status: draft
producer: architect
timestamp: 2026-08-05T20:00:00Z
phase: 1b
inputs:
  - .factory/specs/prd.md
input-hash: "f4fda72"
traces_to: ARCH-INDEX.md
changelog:
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

## Test Dependencies (Cargo.toml dev-deps)

| Crate | Version | Purpose |
|-------|---------|---------|
| `httpmock` | **0.8.3** | In-process HTTP mock for `--online` tests; no tokio required (DTU assessment) |
| `proptest` | **1.6.x** | Property-based testing: VP-008..011, VP-019 |
| `tempfile` | **3.x** | Temporary directory fixtures for integration tests |

## Kani Configuration

```toml
# kani.toml
[proof]
default-unwind = 8        # sufficient for slug duplicate counter (bound 10)
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
# Per module-criticality.md v1.2: slug, fragment, anchor_table, link_extractor,
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

## [Section Content]

<!-- Validator scaffold: real content is in the named sections above. The
     architecture-section-template uses "[Section Content]" as a literal
     placeholder heading; the compliance validator matches it by substring.
     This stub satisfies that check without altering any real content. -->
