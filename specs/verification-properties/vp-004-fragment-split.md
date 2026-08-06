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
source_bc: BC-2.08.003
module: fragment
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
    change: "P2-M03 remediation: added forward-direction assertion (if s contains '#', fragment must be Some and path length must equal s.find('#')); tightened P3 reconstruction check from disjunctive 'starts_with OR equal' to strict 'reconstructed == s'."
deprecated: null
deprecated_by: null
replacement: null
retired: null
withdrawn: null
withdrawal_reason: null
removed: null
removal_reason: null
---

# VP-004: fragment::split Splits at First Unescaped # — %23 Never Splits

## Property Statement

For all raw link destination strings `s`:
1. If `s` contains a literal `#` character (ASCII 0x23), `split_fragment(s)` returns `(path, Some(fragment))` where `fragment` is the substring after the first `#`.
2. If `s` contains `%23` (percent-encoded `#`) but no literal `#`, `split_fragment(s)` returns `(s, None)` — the percent-encoded sequence is never treated as a split point.
3. `split_fragment(s)` is total — it never panics.

This is DI-003: fragment splitting occurs before percent-decoding.

## Source Contract

- **BC:** BC-2.08.003 — Fragment Split Before Percent-Decode
- **Postcondition/Invariant:** DI-003 — `%23` in destination is not a fragment separator.

## Proof Method

| Method | Tool | Bounded? | Coverage |
|--------|------|----------|----------|
| kani | Kani 0.67.0 | yes — input length bounded to 32 bytes | All ASCII inputs up to 32 bytes; targeted assume constraints for %23 presence |

## Proof Harness Skeleton

```rust
#[kani::proof]
fn verify_vp004_fragment_split_no_percent23() {
    let bytes: [u8; 32] = kani::any();
    let len: usize = kani::any();
    kani::assume(len <= 32);
    // Only ASCII to keep model small; %23 is ASCII
    for i in 0..len { kani::assume(bytes[i] < 128); }
    let s = std::str::from_utf8(&bytes[..len]).unwrap(); // safe: all ASCII

    let (path, fragment) = split_fragment(s);

    // P1 (forward): if s contains a literal '#', fragment MUST be Some
    // and path length must be exactly the index of the first '#'.
    if s.contains('#') {
        assert!(fragment.is_some(),
            "split_fragment returned None fragment when '#' is present in {:?}", s);
        assert_eq!(path.len(), s.find('#').unwrap(),
            "path must be the prefix before the first '#' in {:?}", s);
    }
    // P2 (backward): if no literal '#', fragment is None
    if !s.contains('#') {
        assert!(fragment.is_none(),
            "split_fragment returned Some fragment when no # present in {:?}", s);
    }
    // P3: %23 is never a split point (even when no literal '#' is present)
    if s.contains("%23") && !s.contains('#') {
        assert!(fragment.is_none(),
            "split_fragment split on %23 — must only split on literal # in {:?}", s);
    }
    // P4: path + fragment reconstruct the input exactly (strict equality)
    if let Some(frag) = fragment {
        let reconstructed = format!("{}#{}", path, frag);
        assert_eq!(reconstructed, s,
            "path + '#' + fragment must equal the original input for {:?}", s);
    }
}
```

## Feasibility Assessment

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Input space size | Bounded | 32-byte ASCII; manageable CBMC state space |
| Proof complexity | Low | Single pass over bytes looking for '#'; no recursion |
| Tool support | Full | String slicing is well-supported in Kani 0.67.0 |
| Estimated proof time | < 30s | Simple character scan |

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-05 | architect |
| Proof harness committed | — | formal-verifier |
| Proof first passed | — | formal-verifier |
| Locked (VERIFIED) | — | formal-verifier |
