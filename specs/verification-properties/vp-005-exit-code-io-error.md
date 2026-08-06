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
source_bc: BC-2.14.002
module: verdict
proof_method: kani
feasibility: feasible
verification_lock: false
proof_completed_date: null
proof_file_hash: null
lifecycle_status: active
introduced: v0.1.0
modified:
  - version: "1.1"
    date: 2026-08-05
    change: "P2-M19 + P2-m03 remediation: added config_error bool as third symbolic input (models usage errors — bad flag, missing argument); added exit-2-for-usage-error assertion alongside existing io_error assertion. Function is exit_code (not compute_exit_code)."
deprecated: null
deprecated_by: null
replacement: null
retired: null
withdrawn: null
withdrawal_reason: null
removed: null
removal_reason: null
---

# VP-005: verdict::exit_code Returns 2 When Any IoError or ConfigError Present — Regardless of Findings

## Property Statement

For all possible combinations of `findings: &[Finding]`, `io_errors: &[IoError]`, and
`config_error: bool`, if `io_errors` is non-empty OR `config_error` is true, then
`exit_code(findings, io_errors, config_error)` returns `2`. The presence of I/O errors
or usage errors (bad flag, missing argument) dominates all other state — even an empty
findings slice yields exit 2. This is DI-011.

## Source Contract

- **BC:** BC-2.14.002 — I/O Error Exit Code Precedence
- **Postcondition/Invariant:** DI-011 — Exit code 2 takes precedence over exit code 1; io_errors non-empty OR config_error true → exit 2.

## Proof Method

| Method | Tool | Bounded? | Coverage |
|--------|------|----------|----------|
| kani | Kani 0.67.0 | yes — symbolic Boolean inputs (no array needed) | All combinations of (has_broken, has_io_error, config_error) as symbolic booleans — 8 combinations |

## Proof Harness Skeleton

```rust
#[kani::proof]
fn verify_vp005_exit2_dominates() {
    // Symbolic inputs: represent presence of findings, io_errors, and config errors
    // as booleans to keep the model small
    let has_broken: bool = kani::any();
    let has_indeterminate: bool = kani::any();
    let has_io_error: bool = kani::any();
    let config_error: bool = kani::any();  // usage error: bad flag, missing argument

    let findings = build_symbolic_findings(has_broken, has_indeterminate);
    let io_errors = build_symbolic_io_errors(has_io_error);

    let code = exit_code(&findings, &io_errors, config_error);

    // DI-011: io_error → exit 2 (dominates everything)
    if has_io_error {
        assert_eq!(code, 2u8, "Expected exit 2 when io_errors non-empty");
    }
    // config_error → exit 2 (usage error dominates findings)
    if config_error {
        assert_eq!(code, 2u8, "Expected exit 2 when config_error is true");
    }
    // DI-010: no broken, no io_error, no config_error → exit 0
    if !has_broken && !has_io_error && !config_error {
        assert_eq!(code, 0u8, "Expected exit 0 when no errors");
    }
    // exit 1: broken findings, no io_error, no config_error
    if has_broken && !has_io_error && !config_error {
        assert_eq!(code, 1u8, "Expected exit 1 when broken but no io_error/config_error");
    }
}
```

## Feasibility Assessment

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Input space size | Minimal | Three symbolic Booleans; state space = 8 |
| Proof complexity | Very low | Simple conditional logic over enum variants |
| Tool support | Full | Kani handles symbolic Booleans trivially |
| Estimated proof time | < 10s | Near-instantaneous for this model |

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-05 | architect |
| Proof harness committed | — | formal-verifier |
| Proof first passed | — | formal-verifier |
| Locked (VERIFIED) | — | formal-verifier |
