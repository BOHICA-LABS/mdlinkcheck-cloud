---
document_type: verification-property
level: L4
version: "1.3"
status: draft
producer: architect
timestamp: 2026-08-05T20:00:00Z
phase: 1b
inputs:
  - .factory/specs/prd-supplements/nfr-catalog.md
  - .factory/specs/architecture/system-overview.md
input-hash: "9a07a20"
traces_to: .factory/specs/architecture/ARCH-INDEX.md
source_bc: "NFR-008"
module: app
proof_method: integration
feasibility: feasible
verification_lock: false
proof_completed_date: null
proof_file_hash: null
lifecycle_status: active
introduced: v0.1.0
modified:
  - version: "1.3"
    date: 2026-08-06
    change: "D-043 decisions applied: removed HANDOFF placeholder; VP-022 MUST run on macos-latest (NFR-008 ~500ms threshold is Apple-Silicon-calibrated, not portable to Linux). Added Phase 3 obligation: NFR-008 perf-gate and NFR-002 benchmark CI jobs (currently absent from .github/workflows/) MUST be created on macos-latest."
  - version: "1.2"
    date: 2026-08-06
    change: "C4-008 fix: corrected source_bc from NFR-001 (5s Apple Silicon acceptance ceiling) to NFR-008 (the ~500ms per-commit CI regression gate — the NFR this VP actually validates). D-043 HANDOFF: product-owner must decide whether NFR-002 (15s p95 Linux CI runner) is retired or re-targeted to macOS CI; VP-022 Source Contract and CI harness will be aligned to the outcome. NFR-002 reference removed from Source Contract pending that decision."
  - version: "1.1"
    date: 2026-08-05
    change: "P2-m02 remediation: populated source_bc from empty string to NFR-001; clarified that ~500ms is a placeholder target (not a committed value) requiring calibration once the Tier A corpus and CI runner are established; clarified metric is process wall-clock p95 (not mean, not library call latency); added recalibration procedure."
deprecated: null
deprecated_by: null
replacement: null
retired: null
withdrawn: null
withdrawal_reason: null
removed: null
removal_reason: null
---

# VP-022: Regression Gate — p95 Wall-Clock <= ~500ms on Tier A Benchmark Corpus (Offline)

## Property Statement

The end-to-end offline scan of the Tier A benchmark corpus completes within ~500ms
p95 wall-clock on Apple Silicon. This is the CI regression gate (D-013, Tier 2
performance model) — tighter than NFR-001 (5s p95 acceptance ceiling) and designed
to catch algorithmic regressions before they accumulate.

The Tier A corpus is a small, stable benchmark corpus (separate from the 500-file
acceptance corpus) sized to complete in well under 1 second on Apple Silicon, giving
a meaningful signal without dominating CI time. Its exact composition is defined when
the benchmark is first authored (Phase 3); it must include at least: files with
duplicate headings, cross-file anchor links, `.gitignore`d targets, and path
normalization cases.

**Scope:** offline mode only (no `--online`). The gate measures the pure CPU/I/O path:
Pass 1 (parse + anchor tables) + Pass 1.5 (out-of-scan targets) + Pass 2 (resolve) +
Sort + Emit.

**This VP does NOT replace NFR-001** (acceptance ceiling, 5s p95 Apple Silicon) or
**NFR-002** (acceptance ceiling, 10s p95 on `macos-latest` — re-targeted per D-043).
Those are validated separately against the 500-file corpus via `hyperfine` in `benches/`.

**D-043 decision applied — runner platform:** VP-022 MUST run on `macos-latest`. The
~500ms regression gate is calibrated for Apple Silicon; running this job on a Linux runner
would produce a different baseline and silently invalidate the threshold. NFR-008's ~500ms
is an Apple-Silicon-specific measurement, not a portable latency ceiling.

**Phase 3 obligation — CI jobs must use `macos-latest`:** There is currently no
perf-gate or benchmark CI job in `.github/workflows/` (confirmed: no matches for
`perf-gate`, `NFR-008`, `hyperfine`, or `bench` as of 2026-08-06). When created in
Phase 3, BOTH the NFR-008 regression gate and the NFR-002 benchmark job (p95 ≤ 10s,
500-file corpus) MUST be configured on `macos-latest`. Running them on `ubuntu-latest`
or any Linux runner would silently invalidate both Apple-Silicon-calibrated thresholds.

## Source Contract

- **NFR:** NFR-008 — p95 wall-clock ≤ ~500ms per-commit CI regression gate, 100-file
  corpus, blocking merge (the NFR this VP validates). NFR-001 (5s/500-file acceptance
  ceiling) is a separate, manually-validated gate at Phase 4.
  system-overview.md D-013 — regression gate: Tier A corpus, ~500ms
  p95 process wall-clock (placeholder; see Threshold Calibration below).
- **Metric:** **process wall-clock p95 over 10 warm runs** measured by `criterion` or
  `hyperfine`. This is NOT library call latency, NOT CPU time, NOT mean. The CI script
  derives p95 from criterion's benchmark data.
- **Scope:** Process wall-clock from `main()` entry to exit, offline mode only. Includes
  startup, Pass 1, Pass 1.5, Pass 2, sort, and emit phases.
- **Postcondition:** The regression gate script exits 0 (p95 ≤ committed threshold) and
  the binary exits 0 (scan succeeded).

## Proof Method

| Method | Tool | Bounded? | Coverage |
|--------|------|----------|----------|
| integration | cargo bench / hyperfine (Phase 3) | yes — Tier A corpus | p95 wall-clock over 10 warm runs on Apple Silicon; CI fails if p95 > threshold |

## Proof Harness Skeleton

```rust
// benches/regression_gate.rs
use criterion::{criterion_group, criterion_main, Criterion};

fn tier_a_benchmark(c: &mut Criterion) {
    let corpus_path = std::env::var("TIER_A_CORPUS")
        .unwrap_or_else(|_| "tests/bench-corpus/tier-a".to_string());

    c.bench_function("tier_a_offline_scan", |b| {
        b.iter(|| {
            // Run full offline scan pipeline against Tier A corpus
            // Must complete without error
            let result = mdlinkcheck_core::run_offline(&corpus_path);
            assert!(result.is_ok(), "Regression gate scan failed: {:?}", result);
        })
    });
}

criterion_group!(benches, tier_a_benchmark);
criterion_main!(benches);
```

CI assertion (in `.github/workflows/ci.yml`):
```yaml
- name: Regression gate
  run: |
    cargo bench --bench regression_gate 2>&1 | tee bench-output.txt
    # Fail if p95 > 500ms (criterion reports mean; CI uses 2x mean as p95 proxy)
    python3 scripts/check_bench_threshold.py bench-output.txt --threshold-ms 500
```

## Feasibility Assessment

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Test complexity | Low | criterion benchmark + threshold script |
| Coverage | End-to-end | Full offline pipeline on a stable small corpus |
| Tool support | Full | criterion 0.5.x; hyperfine for manual spot-checks |
| Phase | test-sufficient (Phase 3) | Written alongside first performance-sensitive story |
| Threshold calibration | **Required before Phase 3 CI wiring** | ~500ms is a placeholder. Committed value is set via recalibration procedure below. |

### Threshold Calibration Procedure

The `~500ms` value in the property statement is a placeholder. The committed threshold
is established once per environment by the performance-engineer:

1. Define and commit the Tier A corpus (stable, small representative sample).
2. Run 20 warm `hyperfine` passes on the target CI Apple Silicon runner:
   `hyperfine --warmup 3 --runs 20 'mdlinkcheck <tier-a-path>'`
3. Record the p95 value (sort 20 samples, take the 19th).
4. Set committed threshold = p95_baseline × 1.50 (50% headroom for CI variance).
5. Write the committed value into `scripts/check_bench_threshold.py` and the CI YAML.
6. Update this VP's Property Statement line from `~500ms` to the committed value
   (e.g., `750ms`).

**Recalibration trigger:** If the CI runner hardware changes (e.g., new macOS runner
image, different CPU), repeat steps 2–6. Recalibration is NOT triggered by normal
code changes (those either pass or fail the existing gate).

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-05 | architect |
| Tier A corpus defined | — | test-writer |
| Baseline measured | — | performance-engineer |
| Threshold set in CI | — | devops-engineer |
| Locked (VERIFIED) | — | formal-verifier |
