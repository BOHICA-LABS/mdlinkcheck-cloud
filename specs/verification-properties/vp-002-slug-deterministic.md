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
  - .factory/specs/behavioral-contracts/ss-06/BC-2.06.001.md
  - .factory/specs/architecture/module-decomposition.md
input-hash: "2d52acc"
traces_to: .factory/specs/architecture/ARCH-INDEX.md
source_bc: BC-2.06.001
module: slug
proof_method: kani
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

# VP-002: slug::compute_slug is Deterministic — Same Input Produces Same Output

## Property Statement

For all valid UTF-8 strings `s` and `DuplicateCounter` states with the same counter value, two calls to `compute_slug(s, &mut counter)` with equivalent initial states return byte-identical `String` values. There is no hidden global state, thread-local state, or random element in the computation.

## Source Contract

- **BC:** BC-2.06.001 — Slug Computation Algorithm
- **Postcondition/Invariant:** PC2 — `compute_slug` is deterministic; CAP-006 requires slug stability across runs.

## Proof Method

| Method | Tool | Bounded? | Coverage |
|--------|------|----------|----------|
| kani | Kani 0.67.0 | yes — input length bounded to 32 bytes | All valid UTF-8 byte sequences up to 32 bytes with same counter initial value |

## Proof Harness Skeleton

```rust
#[kani::proof]
fn verify_vp002_slug_deterministic() {
    let bytes: [u8; 32] = kani::any();
    let len: usize = kani::any();
    kani::assume(len <= 32);
    let s = match std::str::from_utf8(&bytes[..len]) {
        Ok(s) => s,
        Err(_) => return,
    };
    let count: u32 = kani::any();
    kani::assume(count <= 10);

    // Two identical counter states
    let mut counter1 = DuplicateCounter::with_count(count);
    let mut counter2 = DuplicateCounter::with_count(count);

    let slug1 = compute_slug(s, &mut counter1);
    let slug2 = compute_slug(s, &mut counter2);

    // Postcondition: outputs must be identical
    assert_eq!(slug1, slug2);
}
```

## Feasibility Assessment

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Input space size | Bounded | 32-byte bound; counter 0..10 |
| Proof complexity | Low-medium | Requires DuplicateCounter to expose `with_count` constructor for harness |
| Tool support | Full | Kani handles struct initialization with concrete field values |
| Estimated proof time | < 60s | Two call unrollings; CBMC may need `--unwind 32` for the loop |

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-05 | architect |
| Proof harness committed | — | formal-verifier |
| Proof first passed | — | formal-verifier |
| Locked (VERIFIED) | — | formal-verifier |
