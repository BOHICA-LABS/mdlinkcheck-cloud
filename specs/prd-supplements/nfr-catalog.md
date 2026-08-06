---
document_type: prd-supplement
supplement_type: nfr-catalog
level: L3
version: "1.5"
status: draft
producer: vsdd-factory:product-owner
timestamp: 2026-08-06T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/specs/domain-spec/L2-INDEX.md
  - .factory/planning/brief-validation.md
  - .factory/planning/market-intelligence.md
input-hash: "7213efe"
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

**Confirmed active (D-013, updated D-043):** Human confirmed these constraints at the Phase 1 gate. The 5s p95 target for Apple Silicon (NFR-001) and 10s for macOS CI runner (NFR-002, retargeted per D-043) are the acceptance ceilings for v1.0.

---

## NFR-002: Performance — Tier B (macOS CI Runner)

| Field | Value |
|-------|-------|
| **ID** | NFR-002 |
| **Category** | Performance |
| **Status** | active — retargeted to macOS CI runner per D-043 (was: Linux CI runner); confirmed by human at Phase 1 gate (D-013) |
| **Requirement** | p95 wall-clock time ≤ 10 seconds for the same 500-file corpus, offline checks only |
| **Hardware tier** | macOS CI runner (GitHub Actions `macos-latest`, Apple Silicon M1, shared CI infrastructure) |
| **Build profile** | `--release` with `lto = "thin"` |
| **Cache state** | Warm filesystem cache |
| **Statistic** | p95 over 10 runs |
| **Harness** | `hyperfine` in CI benchmark job |
| **Validation method** | Dedicated CI benchmark workflow; not a blocking gate (advisory only until v1.0) |
| **Risk Source** | R-001, ASM-005 |

**Rationale for 10s ceiling (D-043):** D-043 narrows the platform matrix to macOS-only; the previous Linux 2-core target is obsolete. GitHub `macos-latest` uses Apple Silicon M1 hardware but is shared CI infrastructure, which runs materially slower than a dedicated developer M-series laptop (NFR-001 target: 5s p95 on developer hardware). A single 5s ceiling covering both a local M2/M3 machine and a shared M1 CI runner is likely to be wrong for one of them — the 10s CI ceiling provides honest headroom for shared-infrastructure variability while remaining achievable for an offline 500-file corpus. Confirmed active per D-013.

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

## NFR-004: Platform Portability — RETIRED (D-043)

| Field | Value |
|-------|-------|
| **ID** | NFR-004 |
| **Category** | Portability |
| **Status** | **retired — D-043 (macOS-only platform matrix)** |
| **Requirement** | ~~Full test suite passes on macOS (aarch64 and x86_64), Linux (x86_64), and Windows (x86_64)~~ |
| **Target** | ~~100% test pass on all three platforms in CI matrix~~ |
| **Validation method** | ~~GitHub Actions matrix job: `[macos-latest, ubuntu-latest, windows-latest]`~~ |
| **Source** | ASM-004, DD-002, DI-002 |
| **Retirement reason** | D-043 narrows the platform matrix to macOS (`macos-latest`) only. A portability NFR asserting cross-platform test passage is vacuous on a single-platform matrix. The CI matrix is now `[macos-latest]` only. |
| **IMPORTANT — `unicode-normalization` crate pin** | The architect's pin on the `unicode-normalization` crate version (flagged under NFR-004 context in phase-4 finding P4-018) **remains in force** on DI-001/DI-002 grounds, not on portability grounds. NFC normalization correctness is a determinism and correctness concern independent of the platform matrix — adopting native filesystem Unicode normalization would make verdicts a function of the filesystem rather than of the repository content, which would break DI-001 determinism and NFR-003 reproducibility. See also canonical D-006 rationale under D-043. The architect must keep the exact `unicode-normalization` crate pin. |

---

## NFR-005: Memory Limit

| Field | Value |
|-------|-------|
| **ID** | NFR-005 |
| **Category** | Resource |
| **Status** | active |
| **Requirement** | Peak RSS ≤ 512 MB when scanning the 500-file performance corpus |
| **Target** | ≤ 512 MB peak RSS |
| **Validation method** | `\time -l` (macOS) in the benchmark job — `hyperfine --profile-mem` is not a valid flag (F-030) |
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
| **Hardware tier** | macOS CI runner (GitHub Actions `macos-latest`, Apple Silicon M1, shared CI infrastructure) — updated per D-043 |
| **Build profile** | `--release` with `lto = "thin"` |
| **Cache state** | Warm filesystem cache |
| **Statistic** | p95 over 5 runs (`hyperfine --warmup 1 --runs 5`) |
| **Harness** | `hyperfine` in CI benchmark job; blocks PR merge if threshold exceeded |
| **Blocking gate** | Yes — merge-blocking per-commit regression check |
| **Validation method** | VP-022 (verification property); CI job `perf-gate` runs on every PR |
| **Risk Source** | D-013 (human decision at Phase 1 gate) |

**Relationship to NFR-001/002:** NFR-001/002 are acceptance ceilings (5s/10s, updated per D-043) validated manually at Phase 4. NFR-008 is the automated CI regression guard that catches performance regressions early on a smaller corpus. A regression gate that fires does NOT mean the product fails NFR-001/002 — it means a commit degraded performance by enough to warrant investigation.

---

## NFR Risk Sources

| Risk | NFR(s) Derived |
|------|----------------|
| R-001 (slug drift) | NFR-006 |
| R-002 (anchor false positives) | NFR-006, NFR-007 |
| R-003 (GET fallback) | NFR-007 |
| ASM-005 (R8 achievability) | NFR-001, NFR-002 |
| D-013 (two-tier perf model) | NFR-001, NFR-002, NFR-008 |

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.5 | 2026-08-06 | D-043 (macOS-only platform directive): NFR-002 retargeted from "Linux CI Runner" (15s p95, ubuntu-latest) to "macOS CI Runner" (10s p95, macos-latest, Apple Silicon M1 shared); NFR-004 retired as vacuous on single-platform matrix (unicode-normalization crate pin remains per DI-001/DI-002); NFR-008 hardware tier updated from ubuntu-latest to macos-latest; NFR-001 confirmed-active note updated to reflect new NFR-002 ceiling; NFR-008 relationship note updated from 5s/15s to 5s/10s |
| 1.4 | 2026-08-05 | Initial NFR catalog produced in Phase 1a |
