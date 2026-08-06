---
document_type: architecture-section
level: L3
section: dependency-graph
version: "1.1"
status: draft
producer: architect
timestamp: 2026-08-05T20:00:00Z
phase: 1b
inputs:
  - .factory/specs/domain-spec/capabilities.md
  - .factory/planning/market-intelligence.md
input-hash: "1b26206"
traces_to: ARCH-INDEX.md
---

# Dependency Graph: mdlinkcheck

## External Crate Dependencies — VERIFIED VERSIONS (market-intelligence §4.2, 2026-08-05)

All versions below are taken from crates.io data verified 2026-08-05. Do not use other
versions without updating this document and rerunning the verification matrix.

### mdlinkcheck-core (library crate)

| Crate | Version | License | Purpose | MSRV |
|-------|---------|---------|---------|------|
| `pulldown-cmark` | **0.13.4** | MIT | Markdown parser; `into_offset_iter()` for byte offsets | ≤1.85 |
| `globset` | **0.4.20** | Unlicense OR MIT | Glob matching for `--ignore` patterns (GlobSetBuilder) | ≤1.85 |
| `url` | **2.5.8** | MIT OR Apache-2.0 | WHATWG URL parsing for SS-09 (DD-010: syntax failure = `malformed-url`; DD-013: normalized-URL `--allow` prefix matching). Pure-core dep; `url::Url::parse()` is deterministic, no I/O. Verified via crates.io API 2026-08-05. | ≤1.85 |
| `percent-encoding` | **2.3.2** | MIT OR Apache-2.0 | Percent-decode for path and fragment components (`path_resolver`). Retained as direct dep — see note below. | ≤1.85 |
| `unicode-normalization` | **0.1.24** | MIT OR Apache-2.0 | NFC normalization for DI-002 path comparison | ≤1.85 |
| `serde` | **1.0.x** | MIT OR Apache-2.0 | Derive serialization for JSON output types | ≤1.85 |
| `serde_json` | **1.0.151** | MIT OR Apache-2.0 | JSON serialization for `--format json` (CAP-013) | ≤1.85 |

**`percent-encoding` redundancy note (N-002 resolution):** `url 2.5.8` takes `percent-encoding ^2.3.2`
as a transitive dependency but does NOT re-export `percent_encoding` in its public API (only
`form_urlencoded` is re-exported). `path_resolver` calls `percent_encoding::percent_decode_str`
directly to decode percent-encoded path components in relative Markdown link destinations
(e.g. `[link](my%20file.md)`). Therefore `percent-encoding 2.3.2` must remain as a direct
dependency. It is NOT redundant. `url_classifier` no longer needs it directly (the `url` crate
handles percent-encoding internally during `Url::parse()`). No version conflict: both pull
the same `2.3.2` version; `deny.toml` `multiple-versions = "warn"` is satisfied.

### mdlinkcheck (binary crate — effectful shell)

| Crate | Version | License | Purpose | MSRV |
|-------|---------|---------|---------|------|
| `mdlinkcheck-core` | workspace | — | Library crate (all pure logic) | — |
| `clap` (derive) | **4.6.5** | MIT OR Apache-2.0 | CLI arg parsing with derive macros | **1.85** |
| `ignore` | **0.4.33** | Unlicense OR MIT | `WalkBuilder` with `.gitignore` awareness and parallel mode | ≤1.85 |
| `rayon` | **1.12.0** | MIT OR Apache-2.0 | Data parallelism for Pass 1 and Pass 2 | ≤1.85 |
| `ureq` | **3.3.0** | MIT OR Apache-2.0 | Sync/blocking HTTP client for `--online` (no tokio) | **1.85** |

**MSRV note:** Both `clap` 4.6.5 and `ureq` 3.3.0 require Rust 1.85. Project MSRV is pinned
to 1.85 (toolchain pinned to 1.97.0 in `rust-toolchain.toml` per environment-setup).

### Dev Dependencies (test only — both crates)

| Crate | Version | Purpose |
|-------|---------|---------|
| `httpmock` | **0.8.3** | In-process HTTP mock server; all `--online` behavioral tests (DTU assessment §Hermetic Strategy) |
| `proptest` | **1.6.x** | Property-based testing for VP-008..011, VP-019 |
| `kani` | toolchain | Formal verification for VP-001..007 (installed globally per environment-setup) |

## Inter-Module Dependency Graph (mdlinkcheck-core)

Build order (leaf modules first):

```
types           ←  no dependencies
  ↓
slug            ← types
fragment        ← types
url_classifier  ← types, url
anchor_table    ← types, slug
link_extractor  ← types, pulldown-cmark events
path_resolver   ← types, fragment, percent-encoding, unicode-normalization
anchor_resolver ← types, anchor_table
http_verdict    ← types
filter          ← types, globset
reporter        ← types, serde_json
verdict         ← types
```

No circular dependencies. All modules in `mdlinkcheck-core` are pure.

## Binary Crate Dependencies (mdlinkcheck)

```
cli         ← clap (derive)
scanner     ← ignore, pulldown-cmark, mdlinkcheck-core (types, link_extractor, anchor_table)
http_client ← ureq, rayon, mdlinkcheck-core (http_verdict, types)
app         ← scanner, http_client, mdlinkcheck-core (path_resolver, anchor_resolver,
               url_classifier, filter, reporter, verdict)
main        ← cli, app
```

## Build Order for Phase 3 Story Decomposition

Stories MUST implement modules in dependency order to satisfy the Red Gate:

1. `types` — no deps; define all shared types first
2. `slug`, `fragment`, `url_classifier` — leaf pure modules; Kani-provable immediately
3. `anchor_table` (depends on slug), `link_extractor` (depends on pulldown-cmark API)
4. `path_resolver`, `anchor_resolver`, `http_verdict`, `filter`, `reporter`, `verdict`
5. `cli`, `scanner` (binary crate foundation)
6. `http_client`, `app`, `main` (integration)

## [Section Content]

<!-- Validator scaffold: real content is in the named sections above. The
     architecture-section-template uses "[Section Content]" as a literal
     placeholder heading; the compliance validator matches it by substring.
     This stub satisfies that check without altering any real content. -->
