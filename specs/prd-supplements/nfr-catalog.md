---
document_type: prd-supplement
supplement_type: nfr-catalog
level: L3
version: "1.4"
status: draft
producer: vsdd-factory:product-owner
timestamp: 2026-08-05T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/specs/domain-spec/L2-INDEX.md
  - .factory/planning/brief-validation.md
  - .factory/planning/market-intelligence.md
input-hash: "c3e82ce"
traces_to: .factory/specs/prd.md
primary_consumers: [architect, performance-engineer]
---

# NFR Catalog: mdlinkcheck

> Primary consumers: architect, performance-engineer.
> NFRs are cross-cutting concerns with numerical targets. Not converted to BCs — tabular only.

---

## NFR-001: Performance — Tier A (Apple Silicon)

| Field | Value |
|-------|-------|
| **ID** | NFR-001 |
| **Category** | Performance |
| **Status** | active — confirmed by human at Phase 1 gate (D-013) |
| **Requirement** | p95 wall-clock time ≤ 5 seconds for 500 `.md` files with offline checks only |
| **Measurement corpus** | 500 `.md` files; realistic link-density distribution: avg 20 links/file, avg 15 headings/file, zero external URLs |
| **Hardware tier** | Apple Silicon M-series (`aarch64-apple-darwin`) developer laptop; `num_cpus` thread parallelism |
| **Build profile** | `--release` with `lto = "thin"` in `[profile.release]` |
| **Cache state** | Warm filesystem cache (corpus read once before measurement begins) |
| **Statistic** | p95 over 10 runs (`hyperfine --warmup 2 --runs 10`) |
| **Harness** | `hyperfine` (version-pinned in `benches/README.md`) |
| **Measurement scope** | Process start to exit (includes binary load, not one-time corpus creation) |
| **Validation method** | `cargo bench` or `hyperfine` command in `benches/perf.sh`; gates a manual Phase 4 checkpoint |
| **Risk Source** | R-001, ASM-005 (NFR candidate: yes) |

**Confirmed active (D-013):** Human confirmed these constraints at the Phase 1 gate. The 5s p95 target for Apple Silicon and 15s for Linux CI are the acceptance ceilings for v1.0.

---

## NFR-002: Performance — Tier B (Linux CI Runner)

| Field | Value |
|-------|-------|
| **ID** | NFR-002 |
| **Category** | Performance |
| **Status** | active — confirmed by human at Phase 1 gate (D-013) |
| **Requirement** | p95 wall-clock time ≤ 15 seconds for the same 500-file corpus, offline checks only |
| **Hardware tier** | Standard 2-core x86_64 Linux CI runner (e.g., GitHub Actions `ubuntu-latest` with 2 vCPUs) |
| **Build profile** | `--release` with `lto = "thin"` |
| **Cache state** | Warm filesystem cache |
| **Statistic** | p95 over 10 runs |
| **Harness** | `hyperfine` in CI benchmark job |
| **Validation method** | Dedicated CI benchmark workflow; not a blocking gate (advisory only until v1.0) |
| **Risk Source** | R-001, ASM-005 |

**Rationale for 15s (vs. 5s):** A 2-core shared CI runner is materially different from an M-series laptop. htmltest achieves 2000 HTML files in 8.6s in Go. 500 `.md` files in ≤ 15s on 2 cores in Rust is achievable and realistic. If the Tier A measurement shows headroom, the Tier B budget may be tightened. Confirmed active per D-013.

---

## NFR-003: Output Determinism

| Field | Value |
|-------|-------|
| **ID** | NFR-003 |
| **Category** | Correctness / Determinism |
| **Status** | active |
| **Requirement** | Two invocations of `mdlinkcheck` with identical inputs and flags, under any thread-scheduling environment, produce byte-identical stdout |
| **Target** | 100% — zero tolerance for nondeterminism |
| **Validation method** | Property test: (1) run twice with identical inputs on the same fixture, diff stdout; (2) diff stdout across `RAYON_NUM_THREADS=1` and `RAYON_NUM_THREADS=4` on the same fixture. Both must produce empty diffs. Integrated into standard test suite. |
| **Source** | DI-001, BV-015, EC-147, DD-012 |

---

## NFR-004: Platform Portability

| Field | Value |
|-------|-------|
| **ID** | NFR-004 |
| **Category** | Portability |
| **Status** | active |
| **Requirement** | Full test suite passes on macOS (aarch64 and x86_64), Linux (x86_64), and Windows (x86_64) |
| **Target** | 100% test pass on all three platforms in CI matrix |
| **Validation method** | GitHub Actions matrix job: `[macos-latest, ubuntu-latest, windows-latest]` |
| **Source** | ASM-004, DD-002, DI-002 |
| **Note** | Windows path separator handling: link destinations use `/` per URL semantics; `\` in destinations is NOT treated as a path separator |

---

## NFR-005: Memory Limit

| Field | Value |
|-------|-------|
| **ID** | NFR-005 |
| **Category** | Resource |
| **Status** | active |
| **Requirement** | Peak RSS ≤ 512 MB when scanning the 500-file performance corpus |
| **Target** | ≤ 512 MB peak RSS |
| **Validation method** | `/usr/bin/time -v` (Linux) or `\time -l` (macOS) in the benchmark job — `hyperfine --profile-mem` is not a valid flag (F-030) |
| **Source** | R-001 (resource budget) |

---

## NFR-006: Anchor Algorithm Fidelity

| Field | Value |
|-------|-------|
| **ID** | NFR-006 |
| **Category** | Correctness |
| **Status** | active |
| **Requirement** | All worked examples from DD-015 (market-intelligence §4.1) pass as unit tests in the slug module |
| **Target** | 100% — all 16 worked examples in SLUG_CORPUS pass (TV-S001..TV-S016; TV-S012 is the DEC-001 collision-bump triple, not a separate item) |
| **Validation method** | Unit test suite for `slug_compute` module; run on every commit |
| **Source** | R-001, R-002, DD-015, ASM-008 |
| **Test inputs** | See test-vectors.md §7 (slug algorithm vectors) |

---

## NFR-007: No Undefined Reason Codes

| Field | Value |
|-------|-------|
| **ID** | NFR-007 |
| **Category** | Correctness |
| **Status** | active |
| **Requirement** | Every verdict in text/JSON output uses a reason code from the closed taxonomy in error-taxonomy.md |
| **Target** | 100% — zero unrecognized reason strings in any output |
| **Validation method** | Parsing test: run against acceptance corpus, parse JSON output, assert every `reason` field matches the enumerated set |
| **Source** | DD-011, FM-NNN catalog |

---

## NFR-008: CI Performance Regression Gate

| Field | Value |
|-------|-------|
| **ID** | NFR-008 |
| **Category** | Performance / Regression Prevention |
| **Status** | active — introduced per D-013 |
| **Requirement** | Per-commit CI benchmark: p95 wall-clock time ≤ ~500 ms for the regression-gate corpus (100 `.md` files, offline, warm cache), blocking merge if exceeded |
| **Target** | ≤ 500 ms p95 (guidance: 500 ms; exact threshold pinned in `benches/perf.sh`) |
| **Measurement corpus** | 100 `.md` files; same link-density distribution as NFR-001/002 but smaller (1/5 the size) for fast CI feedback |
| **Hardware tier** | Standard 2-core x86_64 Linux CI runner (GitHub Actions `ubuntu-latest`) |
| **Build profile** | `--release` with `lto = "thin"` |
| **Cache state** | Warm filesystem cache |
| **Statistic** | p95 over 5 runs (`hyperfine --warmup 1 --runs 5`) |
| **Harness** | `hyperfine` in CI benchmark job; blocks PR merge if threshold exceeded |
| **Blocking gate** | Yes — merge-blocking per-commit regression check |
| **Validation method** | VP-022 (verification property); CI job `perf-gate` runs on every PR |
| **Risk Source** | D-013 (human decision at Phase 1 gate) |

**Relationship to NFR-001/002:** NFR-001/002 are acceptance ceilings (5s/15s) validated manually at Phase 4. NFR-008 is the automated CI regression guard that catches performance regressions early on a smaller corpus. A regression gate that fires does NOT mean the product fails NFR-001/002 — it means a commit degraded performance by enough to warrant investigation.

---

## NFR Risk Sources

| Risk | NFR(s) Derived |
|------|----------------|
| R-001 (slug drift) | NFR-006 |
| R-002 (anchor false positives) | NFR-006, NFR-007 |
| R-003 (GET fallback) | NFR-007 |
| ASM-005 (R8 achievability) | NFR-001, NFR-002 |
| D-013 (two-tier perf model) | NFR-001, NFR-002, NFR-008 |
