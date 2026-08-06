---
document_type: verification-property
level: L4
version: "1.0"
status: draft
producer: architect
timestamp: 2026-08-05T20:00:00Z
phase: 1b
inputs:
  - .factory/specs/domain-spec/risks.md
  - .factory/specs/architecture/module-decomposition.md
input-hash: "3ba0c51"
traces_to: .factory/specs/architecture/ARCH-INDEX.md
source_bc: BC-2.06.001
module: slug
proof_method: fuzz
feasibility: feasible
verification_lock: false
proof_completed_date: null
proof_file_hash: null
lifecycle_status: active
introduced: v0.1.0
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
withdrawn: null
withdrawal_reason: null
removed: null
removal_reason: null
---

# VP-012: slug::compute_slug Fuzz — No Panic on Arbitrary UTF-8

## Property Statement

`compute_slug(s, &mut DuplicateCounter::new())` does not panic, abort, or produce undefined behavior for any valid UTF-8 byte sequence `s` of any length. This extends VP-001's Kani-bounded proof to unbounded input lengths and adversarial UTF-8 constructions (long combining character sequences, surrogate-adjacent sequences, embedded null bytes, maximum codepoint values).

## Source Contract

- **BC:** BC-2.06.001 — Slug Computation Algorithm
- **Postcondition/Invariant:** R-001/R-002 — slug algorithm correctness; no panics on any input.

## Proof Method

| Method | Tool | Bounded? | Coverage |
|--------|------|----------|----------|
| fuzz | cargo-fuzz 0.13.1 (libFuzzer) | no — coverage-guided | Arbitrary valid UTF-8; coverage-guided to explore all character classification branches |

## Proof Harness Skeleton

```rust
// fuzz/fuzz_targets/fuzz_slug.rs
#![no_main]
use libfuzzer_sys::fuzz_target;
use mdlinkcheck_core::slug::{compute_slug, DuplicateCounter};

fuzz_target!(|data: &[u8]| {
    if let Ok(s) = std::str::from_utf8(data) {
        let mut counter = DuplicateCounter::new();
        // Must not panic
        let _ = compute_slug(s, &mut counter);
    }
    // Invalid UTF-8 is silently ignored (filter at fuzz harness level)
});
```

## Feasibility Assessment

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Input space size | Unbounded | libFuzzer coverage-guided; finds crashes in character classification branches |
| Proof complexity | Low | No assertions needed — no-crash is the property |
| Tool support | Full | `cargo-fuzz 0.13.1` with `fuzz/` workspace member (ADR-002) |
| Estimated proof time | 30 min CI run minimum; longer soak in Phase 6 | Target 1M executions for initial confidence |

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-05 | architect |
| Proof harness committed | — | formal-verifier |
| Proof first passed | — | formal-verifier |
| Locked (VERIFIED) | — | formal-verifier |
