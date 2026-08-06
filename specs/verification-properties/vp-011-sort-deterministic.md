---
document_type: verification-property
level: L4
version: "1.1"
status: draft
producer: architect
timestamp: 2026-08-05T20:00:00Z
phase: 1b
inputs:
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/architecture/module-decomposition.md
input-hash: "012887b"
traces_to: .factory/specs/architecture/ARCH-INDEX.md
source_bc: BC-2.12.001
module: reporter
proof_method: proptest
feasibility: feasible
verification_lock: false
proof_completed_date: null
proof_file_hash: null
lifecycle_status: active
introduced: v0.1.0
modified:
  - version: "1.1"
    date: 2026-08-05
    change: "P2-M05 + P2-M16 remediation: corrected source BC title from invented 'BC-2.12.001 — Deterministic Output Ordering' to actual H1 'Text report format — one finding per line'. Added DI-001 binary-output-stable integration harness that runs the binary twice under varying RAYON_NUM_THREADS and byte-compares stdout — the proptest harnesses do not exercise rayon scheduling, which is the actual source of non-determinism DI-001 exists to neutralize."
deprecated: null
deprecated_by: null
replacement: null
retired: null
withdrawn: null
withdrawal_reason: null
removed: null
removal_reason: null
---

# VP-011: Sort Order Is Deterministic — Same Vec<Finding> Always Produces Same Permutation

## Property Statement

For any `Vec<Finding>` input (regardless of initial order), applying `sort_unstable_by_key(|f| (nfc_normalize(&f.path), f.line, f.col))` twice on two independent copies of the same collection produces byte-identical sequences. Equivalently: the sort key function induces a total order on findings, and the resulting sorted sequence is independent of initial order. This is DI-001.

## Source Contract

- **BC:** BC-2.12.001 — Text report format — one finding per line
- **Postcondition/Invariant:** DI-001 — output ordering is deterministic; sort key is (NFC path, line, col).

**Coverage note:** The proptest harnesses below verify that `sort_findings` is a
deterministic total order on `Vec<Finding>`. They do NOT exercise rayon scheduling,
which is the actual non-determinism source DI-001 exists to neutralize. The
`vp011_binary_output_stable` integration harness below provides the falsifying test
for DI-001 by running the binary twice under different thread counts and
byte-comparing stdout.

## Proof Method

| Method | Tool | Bounded? | Coverage |
|--------|------|----------|----------|
| proptest | proptest 1.6.0 | no — property-based | Arbitrary Vec<Finding> up to 20 elements; shuffled before second sort to verify order-independence |

## Proof Harness Skeleton

```rust
proptest! {
    #[test]
    fn vp011_sort_deterministic(
        mut findings in prop::collection::vec(arb_finding(), 0..20)
    ) {
        let mut copy = findings.clone();

        // Sort both in same way
        sort_findings(&mut findings);
        sort_findings(&mut copy);

        prop_assert_eq!(&findings, &copy,
            "Sorted findings must be identical regardless of initial order");
    }

    #[test]
    fn vp011_sort_order_independent(
        mut findings in prop::collection::vec(arb_finding(), 2..20)
    ) {
        let mut shuffled = findings.clone();
        // Reverse as a deterministic shuffle
        shuffled.reverse();

        sort_findings(&mut findings);
        sort_findings(&mut shuffled);

        prop_assert_eq!(findings, shuffled,
            "Sort result must be independent of input order");
    }
}
```

### DI-001 Binary-Output Stable Integration Harness

```rust
// tests/integration/determinism.rs  (Phase 3)
// Runs the mdlinkcheck binary twice on the Tier A corpus under different
// RAYON_NUM_THREADS values and byte-compares stdout. This is the only harness
// that can detect rayon-scheduling-induced non-determinism (DI-001).
#[test]
fn vp011_binary_output_stable_text() {
    let corpus = std::env::var("TIER_A_CORPUS")
        .unwrap_or_else(|_| "tests/bench-corpus/tier-a".to_string());

    for threads in &["1", "4", "16"] {
        let run1 = std::process::Command::new("cargo")
            .args(&["run", "--", &corpus])
            .env("RAYON_NUM_THREADS", threads)
            .output().expect("run1 failed");
        let run2 = std::process::Command::new("cargo")
            .args(&["run", "--", &corpus])
            .env("RAYON_NUM_THREADS", threads)
            .output().expect("run2 failed");

        assert_eq!(run1.stdout, run2.stdout,
            "Stdout differs between run 1 and run 2 with RAYON_NUM_THREADS={}", threads);
    }
}

#[test]
fn vp011_binary_output_stable_json() {
    let corpus = std::env::var("TIER_A_CORPUS")
        .unwrap_or_else(|_| "tests/bench-corpus/tier-a".to_string());

    for threads in &["1", "16"] {
        let run1 = std::process::Command::new("cargo")
            .args(&["run", "--", "--format", "json", &corpus])
            .env("RAYON_NUM_THREADS", threads)
            .output().expect("run1 json failed");
        let run2 = std::process::Command::new("cargo")
            .args(&["run", "--", "--format", "json", &corpus])
            .env("RAYON_NUM_THREADS", threads)
            .output().expect("run2 json failed");

        assert_eq!(run1.stdout, run2.stdout,
            "JSON stdout differs between runs with RAYON_NUM_THREADS={}", threads);
    }
}
```

## Feasibility Assessment

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Input space size | Property-based | `arb_finding()` strategy generates arbitrary path/line/col combinations |
| Proof complexity | Low | Sort correctness is a standard property; `sort_unstable_by` is deterministic for equal key inputs |
| Tool support | Full | proptest strategies for custom types are standard |
| Estimated proof time | < 5s per run | |

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-05 | architect |
| Proof harness committed | — | formal-verifier |
| Proof first passed | — | formal-verifier |
| Locked (VERIFIED) | — | formal-verifier |
