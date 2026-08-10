---
document_type: verification-property
level: L4
version: "1.2"
status: draft
producer: architect
timestamp: 2026-08-10T00:00:00Z
phase: 1b
inputs:
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/architecture/module-decomposition.md
input-hash: "3efc65a"
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
  - version: "1.2"
    date: 2026-08-10
    change: "BI-052 remediation (P7-S3-003, BI-053-A, BI-053-B, BI-053-D): added Properties P5 and P6 — integration harnesses asserting that the path component is percent-decoded after split (P5) and that the fragment component is percent-decoded before anchor-table lookup (P6). These close the D-165 propagation debt: the D-162/D-163 BC corrections required decode-before-lookup but no VP verified the decode step. BC-2.07.004 row 2 and BC-2.08.001 decode postcondition now correctly cite VP-004 integration (P5/P6). See also TV-025, TV-157."
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

**Properties P5 and P6 — Decode Ordering (integration, BI-052/BI-053 remediation):**

4. (P5) The path component returned by `split_fragment` is percent-decoded before directory-entry comparison. A link destination `My%20File.md` resolves to the file `My File.md` — an implementation that omits the decode step produces `file-not-found` for a file that exists. Verified by integration test `vp004_path_percent_decode_after_split`.
5. (P6) The fragment component returned by `split_fragment` is percent-decoded before anchor-table lookup. A fragment `caf%C3%A9` is decoded to `café` before being looked up in the anchor table — an implementation that omits the decode step produces `anchor-not-found` for an anchor that exists. Verified by integration test `vp004_fragment_percent_decode_before_anchor_lookup`.

Note: `split_fragment` itself does not perform decoding (it returns borrowed slices). P5 and P6 verify that the *caller* performs the decode step. This closes the D-162/D-163 gap where the BC postconditions required decode-before-lookup but no VP verified the decode step.

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

## Decode-Ordering Integration Tests (P5, P6)

These integration tests verify the decode step that the Kani harness cannot test (split_fragment returns borrowed slices; it cannot perform allocation). They follow the same pattern as VP-015 and VP-016.

```rust
// tests/integration_fragment_decode_ordering.rs
// VP-004 P5: path component percent-decoded after split
// Falsified by: an implementation that skips percent-decode of the path component
// before directory-entry lookup (looks for "My%20File.md" instead of "My File.md").
#[test]
fn vp004_path_percent_decode_after_split() {
    let dir = tempdir();
    // File on disk has a space in the name
    write_file(&dir, "My File.md", "# Content\n");
    // Link destination uses percent-encoding for the space
    write_file(&dir, "source.md", "[x](./My%20File.md)");

    let findings = run_scan(&dir, ScanOpts::default());

    assert!(findings.iter().all(|f| !f.is_broken()),
        "VP-004 P5: Link to My%20File.md must resolve to 'My File.md' after percent-decode \
         — a decoder-omitting implementation produces file-not-found: {:?}", findings);
}

// VP-004 P6: fragment component percent-decoded before anchor-table lookup
// Falsified by: an implementation that skips percent-decode of the fragment before
// anchor-table lookup (looks for "caf%C3%A9" instead of the NFC-slugged "café").
#[test]
fn vp004_fragment_percent_decode_before_anchor_lookup() {
    let dir = tempdir();
    // Heading "Café" produces slug "café" in the anchor table
    write_file(&dir, "guide.md", "# Café\nContent.\n");
    // Link uses percent-encoded fragment
    write_file(&dir, "source.md", "[x](./guide.md#caf%C3%A9)");

    let findings = run_scan(&dir, ScanOpts::default());

    assert!(findings.iter().all(|f| !f.is_broken()),
        "VP-004 P6: Percent-encoded fragment caf%%C3%%A9 must be decoded to 'café' before \
         anchor lookup — a decoder-omitting implementation produces anchor-not-found: {:?}",
        findings);
}
```

## Feasibility Assessment

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Input space size | Bounded | 32-byte ASCII; manageable CBMC state space |
| Proof complexity | Low | Single pass over bytes looking for '#'; no recursion |
| Tool support | Full | String slicing is well-supported in Kani 0.67.0 |
| Estimated proof time | < 30s | Simple character scan |
| P5/P6 integration | < 1s each | Fixture-based; tests the decode step in path_resolver and anchor_resolver callers |

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-05 | architect |
| Proof harness committed | — | formal-verifier |
| Proof first passed | — | formal-verifier |
| Locked (VERIFIED) | — | formal-verifier |
