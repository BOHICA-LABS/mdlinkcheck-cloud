---
document_type: verification-property
level: L4
version: "1.1"
status: draft
producer: architect
timestamp: 2026-08-10T00:00:00Z
phase: 1b
inputs:
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/behavioral-contracts/ss-06/BC-2.06.001.md
  - .factory/specs/architecture/module-decomposition.md
input-hash: "5495752"
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
modified:
  - version: "1.1"
    date: 2026-08-10
    change: "BI-052 remediation (P7-S7-002): Property Statement rewritten to be precise and falsifiable. Prior version stated 'no hidden global state, thread-local state, or random element' which is unfalsifiable under Kani because f(x)==f(x) is trivially true for any pure function. New statement names the concrete falsifying conditions: rand::random(), SystemTime::now(), or any non-deterministic FFI cause the two symbolic calls to diverge. Scope limitation documented: static AtomicU32 counters not detectable by this harness; that guarantee is provided by DI-012 and the pure-core architecture constraint."
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

For all valid UTF-8 strings `s` and `DuplicateCounter` states initialized to the same counter value, two independent calls to `compute_slug(s, &mut counter)` with equivalent initial states return byte-identical `String` values.

**Falsifying conditions (what WOULD cause this harness to fail under Kani):** Any call to `rand::random()`, `SystemTime::now()`, or any other non-deterministic source inside `compute_slug` causes the two symbolic calls to diverge, failing `assert_eq!(slug1, slug2)`. Kani's symbolic execution model makes every such non-deterministic source observable.

**Scope limitation:** A hidden `static AtomicU32` counter (per-binary state) initialized once at startup would appear identical across both symbolic calls — Kani cannot distinguish it from the DuplicateCounter argument. The absence of such a static is guaranteed by DI-012 (algorithm fidelity to github-slugger v2, which is stateless) and the pure-core architecture constraint (no globals in slug.rs), not by this proof. The proof's value is specifically in ruling out randomness, OS-clock reads, and non-deterministic FFI calls.

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
