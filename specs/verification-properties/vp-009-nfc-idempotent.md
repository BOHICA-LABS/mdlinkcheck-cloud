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
input-hash: "9c1a1a8"
traces_to: .factory/specs/architecture/ARCH-INDEX.md
source_bc: BC-2.07.003
module: path_resolver
proof_method: proptest
feasibility: feasible
verification_lock: false
proof_completed_date: null
proof_file_hash: null
lifecycle_status: active
introduced: v0.1.0
modified:
  - version: "1.1"
    date: 2026-08-06
    change: "D-043 macOS-only platform directive: re-scoped Property Statement and Feasibility Assessment to macOS APFS context. Noted that VP-009 (NFC idempotency) is load-bearing under macOS-only because the `unicode-normalization 0.1.24` wrapper is the only thing preventing a double-normalization from producing different results — there is no cross-platform CI to incidentally catch a broken wrapper. No changes to harness."
deprecated: null
deprecated_by: null
replacement: null
retired: null
withdrawn: null
withdrawal_reason: null
removed: null
removal_reason: null
---

# VP-009: NFC Normalization Is Idempotent — nfc(nfc(s)) == nfc(s)

## Property Statement

For all path strings `s`, applying NFC normalization twice produces the same result as applying it once: `nfc_normalize(nfc_normalize(s)) == nfc_normalize(s)`. This is a mathematical property of NFC normalization required for correctness of the path comparison model (DI-002).

**macOS-only scope (D-043):** On the macOS-only platform matrix, the `unicode-normalization 0.1.24` wrapper is the only normalization layer in the path comparison pipeline. VP-009 confirms the wrapper is idempotent — a double-normalization (e.g., normalizing an already-NFC path from a Markdown source file) produces no spurious byte changes. Under macOS-only, there is no cross-platform CI run to incidentally catch a broken wrapper, making this property more load-bearing, not less.

## Source Contract

- **BC:** BC-2.07.003 — NFC Case-Sensitive Path Comparison
- **Postcondition/Invariant:** DI-002 — NFC normalization must be idempotent for the comparison model to be consistent.

## Proof Method

| Method | Tool | Bounded? | Coverage |
|--------|------|----------|----------|
| proptest | proptest 1.6.0 | no — property-based | Arbitrary Unicode strings including combining characters, NFD sequences, and composed forms |

## Proof Harness Skeleton

```rust
proptest! {
    #[test]
    fn vp009_nfc_idempotent(s in "\\PC*") {
        let once = nfc_normalize(&s);
        let twice = nfc_normalize(&once);
        prop_assert_eq!(once, twice,
            "NFC normalization must be idempotent: nfc(nfc(s)) == nfc(s)");
    }
}
```

## Feasibility Assessment

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Input space size | Unbounded (property-based) | The `unicode-normalization 0.1.24` crate guarantees idempotency; this test verifies our wrapper preserves it |
| Proof complexity | Trivial | Single-line property; proptest handles Unicode generation |
| Tool support | Full | `proptest 1.6.0` with `"\\PC*"` strategy covers all Unicode printable chars |
| Estimated proof time | < 2s per run (Phase 3 macOS CI) | Simple string comparison on Apple Silicon |
| Platform | macOS only (D-043) | Harness is platform-independent; APFS NFD inputs are the primary concern |

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-05 | architect |
| Proof harness committed | — | formal-verifier |
| Proof first passed | — | formal-verifier |
| Locked (VERIFIED) | — | formal-verifier |
