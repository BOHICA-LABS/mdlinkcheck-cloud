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
source_bc: BC-2.14.001
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
    change: "P2-M19 + P2-m03 + DD-022 remediation: renamed title and property from 'Alive or Indeterminate' to 'Clean or Indeterminate' — 'alive' is a URL liveness outcome that maps to link verdict clean; it is not a separate link verdict class (DD-022). Added config_error symbolic boolean and exit-2-for-usage-error assertion."
deprecated: null
deprecated_by: null
replacement: null
retired: null
withdrawn: null
withdrawal_reason: null
removed: null
removal_reason: null
---

# VP-006: verdict::exit_code Returns 0 When All Findings Are Clean or Indeterminate

## Property Statement

When `io_errors` is empty, `config_error` is false, and all findings in `findings` have
verdict `clean` or `indeterminate` (no `broken` finding exists), `exit_code(findings,
io_errors, config_error)` returns `0`. An `indeterminate` verdict never contributes to a
non-zero exit code (DI-010 anti-false-positive).

**DD-022 note:** The link verdict domain is `{clean, broken, indeterminate}`. `alive` is a
URL liveness outcome (from the HTTP checker) that maps to link verdict `clean`. It is not a
separate verdict class. This VP uses `clean`, not `alive`.

## Source Contract

- **BC:** BC-2.14.001 — Exit Code 0 for Clean / Indeterminate Run
- **Postcondition/Invariant:** DI-010 — `indeterminate` verdict does not trigger exit 1; only `broken` triggers exit 1.

## Proof Method

| Method | Tool | Bounded? | Coverage |
|--------|------|----------|----------|
| kani | Kani 0.67.0 | yes — symbolic Boolean inputs | All (has_broken=false, has_io_error=false, config_error=false) combinations with variable has_indeterminate |

## Proof Harness Skeleton

```rust
#[kani::proof]
fn verify_vp006_clean_or_indeterminate_exit0() {
    let has_indeterminate: bool = kani::any();
    // Constraint: no broken findings, no io_errors, no config error
    let has_broken = false;
    let has_io_error = false;
    let config_error = false;

    let findings = build_symbolic_findings(has_broken, has_indeterminate);
    let io_errors: Vec<IoError> = Vec::new();

    let code = exit_code(&findings, &io_errors, config_error);

    // Postcondition: always exit 0 regardless of indeterminate presence
    assert_eq!(code, 0u8,
        "Expected exit 0 when no broken findings, no io_errors, no config_error");
}

#[kani::proof]
fn verify_vp006_config_error_exits_2() {
    let has_indeterminate: bool = kani::any();
    let has_broken: bool = kani::any();
    let has_io_error: bool = kani::any();
    let config_error = true;  // usage error (bad flag, missing argument)

    let findings = build_symbolic_findings(has_broken, has_indeterminate);
    let io_errors = build_symbolic_io_errors(has_io_error);

    let code = exit_code(&findings, &io_errors, config_error);

    // A configuration/usage error always yields exit 2 (dominates exit 1)
    assert_eq!(code, 2u8,
        "Expected exit 2 when config_error is true");
}
```

## Feasibility Assessment

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Input space size | Minimal | Single symbolic Boolean; state space = 2 |
| Proof complexity | Very low | VP-006 is a companion to VP-005; same model, different constraint |
| Tool support | Full | Trivial for Kani |
| Estimated proof time | < 10s | |

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-05 | architect |
| Proof harness committed | — | formal-verifier |
| Proof first passed | — | formal-verifier |
| Locked (VERIFIED) | — | formal-verifier |
