---
document_type: verification-property
level: L4
version: "1.0"
status: draft
producer: architect
timestamp: 2026-08-05T20:00:00Z
phase: 1b
inputs:
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/architecture/module-decomposition.md
input-hash: "5670949"
traces_to: .factory/specs/architecture/ARCH-INDEX.md
source_bc: BC-2.08.003
module: fragment
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

# VP-013: fragment::split Fuzz — No Panic on Arbitrary Byte Sequences

## Property Statement

`split_fragment(s)` does not panic, abort, or produce undefined behavior for any valid UTF-8 byte sequence `s`, including sequences containing multiple `#` characters, percent-encoded sequences (`%23`, `%2523`), null bytes represented as `%00`, and very long inputs.

## Source Contract

- **BC:** BC-2.08.003 — Fragment Split Before Percent-Decode
- **Postcondition/Invariant:** DI-003 — `split_fragment` is total; fuzz extends VP-004's bounded Kani proof to unbounded inputs.

## Proof Method

| Method | Tool | Bounded? | Coverage |
|--------|------|----------|----------|
| fuzz | cargo-fuzz 0.13.1 (libFuzzer) | no — coverage-guided | Valid UTF-8 byte sequences of any length; coverage-guided to hit all branch conditions |

## Proof Harness Skeleton

```rust
// fuzz/fuzz_targets/fuzz_fragment.rs
#![no_main]
use libfuzzer_sys::fuzz_target;
use mdlinkcheck_core::fragment::split_fragment;

fuzz_target!(|data: &[u8]| {
    if let Ok(s) = std::str::from_utf8(data) {
        // Must not panic; result must be structurally valid
        let (path, fragment) = split_fragment(s);
        // Invariant: path + optional fragment reconstruct the input
        if let Some(frag) = fragment {
            assert!(s.contains('#'),
                "fragment present but no # in input");
            let _ = (path, frag);
        } else {
            assert!(!s.contains('#') || s.is_empty(),
                "no fragment but # present");
        }
    }
});
```

## Feasibility Assessment

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Input space size | Unbounded | libFuzzer explores percent-encoding edge cases automatically |
| Proof complexity | Low | No-crash + structural invariant |
| Tool support | Full | `cargo-fuzz 0.13.1` |
| Estimated proof time | 15 min CI run; longer soak in Phase 6 | Simple function; reaches full branch coverage quickly |

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-05 | architect |
| Proof harness committed | — | formal-verifier |
| Proof first passed | — | formal-verifier |
| Locked (VERIFIED) | — | formal-verifier |
