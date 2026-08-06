---
document_type: verification-property
level: L4
version: "1.2"
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
  - version: "1.2"
    date: 2026-08-06
    change: "D-043 macOS-only platform directive: re-scoped Property Statement and Feasibility Assessment to macOS APFS context. Noted that VP-008 becomes MORE important under macOS-only — on a macOS-only matrix, APFS NFD storage is the only filesystem in scope, making the NFC normalization layer the sole barrier between APFS NFD storage and correct verdicts. No changes to harness (proptest strategies are platform-independent)."
  - version: "1.1"
    date: 2026-08-05
    change: "P2-M02 remediation: replaced vacuous property 3 (ASCII-only %23 generator that never produced combining characters) with (a) a real NFD/NFC combining-character pair test (é, ñ, ガ) and (b) a case-sensitivity falsifying test asserting files_match(s, s.to_uppercase()) == false for any string with at least one ASCII letter. D-006 now has a genuine falsifying test."
deprecated: null
deprecated_by: null
replacement: null
retired: null
withdrawn: null
withdrawal_reason: null
removed: null
removal_reason: null
---

# VP-008: path_resolver Uses NFC-Normalized Case-Sensitive Comparison

## Property Statement

For all path strings `a` and `b` where `nfc_normalize(a) == nfc_normalize(b)` (same logical path in different Unicode normalization forms), `path_resolver::files_match(a, b)` returns `true`. For paths where `nfc_normalize(a) != nfc_normalize(b)` (different paths regardless of case), `files_match` returns `false`. No case-folding is applied. This is DI-002.

**macOS-only scope (D-043):** On the macOS-only platform matrix, macOS APFS stores filenames in NFD. The NFC normalization layer in `path_resolver` is the sole barrier between APFS NFD storage and correct link verdicts. This makes VP-008 **more important** under macOS-only, not less: without it, every NFC-authored link to an accented-character filename would produce a false positive on APFS. There is no cross-platform CI run (e.g., Linux ext4) that would incidentally catch a missing normalization call. The harness strategies are platform-independent (proptest generates Unicode strings regardless of host OS).

## Source Contract

- **BC:** BC-2.07.003 — NFC Case-Sensitive Path Comparison
- **Postcondition/Invariant:** DI-002 — path comparison is NFC-normalized and case-sensitive.

## Proof Method

| Method | Tool | Bounded? | Coverage |
|--------|------|----------|----------|
| proptest | proptest 1.6.0 | no — property-based, 10000 samples | Arbitrary Unicode strings including NFD/NFC variants; paired strings with controlled normalization form differences |

## Proof Harness Skeleton

```rust
// Curated combining-character pairs: (NFC form, NFD form)
// Each pair represents the same logical path in two Unicode normalization forms.
// Strategy: pick randomly from this set to ensure real combining characters appear.
fn arb_nfc_nfd_path_pair() -> impl Strategy<Value = (String, String)> {
    prop_oneof![
        // é: U+00E9 (NFC) vs e + U+0301 (NFD)
        Just(("docs/caf\u{00E9}.md".to_string(), "docs/cafe\u{0301}.md".to_string())),
        // ñ: U+00F1 (NFC) vs n + U+0303 (NFD)
        Just(("files/ma\u{00F1}ana.md".to_string(), "files/man\u{0303}ana.md".to_string())),
        // ガ: U+30AC (NFC) vs カ + U+3099 (NFD)
        Just(("docs/\u{30AC}イド.md".to_string(), "docs/\u{30AB}\u{3099}イド.md".to_string())),
    ]
}

proptest! {
    #[test]
    fn vp008_nfc_reflexive(s in "\\PC*") {
        // Property 1: NFC match is reflexive
        prop_assert!(files_match(s.as_ref(), s.as_ref()),
            "files_match(s, s) must be true for all s");
    }

    #[test]
    fn vp008_nfc_symmetric(a in "\\PC*", b in "\\PC*") {
        // Property 2: NFC match is symmetric
        prop_assert_eq!(
            files_match(a.as_ref(), b.as_ref()),
            files_match(b.as_ref(), a.as_ref()),
            "files_match must be symmetric"
        );
    }

    #[test]
    fn vp008_nfd_nfc_pair_matches((nfc_path, nfd_path) in arb_nfc_nfd_path_pair()) {
        // Property 3 (replaced): real NFD/NFC combining-character pairs must match.
        // Verifies that NFC normalization is actually applied to both sides — a
        // byte-equality implementation would fail this test.
        prop_assert!(
            files_match(&nfc_path, &nfd_path),
            "NFC path {:?} and NFD path {:?} are the same logical path and must match",
            nfc_path, nfd_path
        );
    }

    #[test]
    fn vp008_case_differs_no_match(s in "[a-zA-Z][a-zA-Z0-9/._-]{0,30}") {
        // Property 4 (new, D-006): for any string containing at least one ASCII letter,
        // the lowercase and uppercase variants are DIFFERENT paths.
        // An implementation that calls to_lowercase() would fail this test.
        // This is the falsifying test for D-006 (case-sensitive, no case-folding).
        let upper = s.to_uppercase();
        if s != upper {
            prop_assert!(
                !files_match(&s, &upper),
                "files_match({:?}, {:?}) must be false — case-sensitivity is required (D-006)",
                s, upper
            );
        }
    }
}
```

## Feasibility Assessment

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Input space size | Unbounded (property-based) | proptest generates Unicode strings including composed/decomposed variants |
| Proof complexity | Low | Pure function; proptest strategies for NFD/NFC pairs are standard |
| Tool support | Full | `proptest 1.6.0` with `unicode-normalization 0.1.24` test helpers |
| Estimated proof time | < 5s per run (Phase 3 macOS CI) | 10000 sample default; run in `cargo nextest` on Apple Silicon |
| Platform | macOS only (D-043) | Harness strategies are platform-independent; APFS NFD → NFC is the primary falsifying scenario |

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-05 | architect |
| Proof harness committed | — | formal-verifier |
| Proof first passed | — | formal-verifier |
| Locked (VERIFIED) | — | formal-verifier |
