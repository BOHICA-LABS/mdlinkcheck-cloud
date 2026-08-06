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
source_bc: BC-2.11.002
module: filter
proof_method: proptest
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

# VP-010: filter::should_allow Enforces Component Boundary

## Property Statement

Given an `--allow` prefix of `https://a.com`, `should_allow("https://a.com/path")` returns `true` and `should_allow("https://a.com.evil.tld/path")` returns `false`. The allow-match logic compares full URL components (scheme + host), never raw byte prefixes. A URL whose host merely starts with the allowed host string is NOT allowed unless it is the same host. This is DD-013.

## Source Contract

- **BC:** BC-2.11.002 — Allow-List Component Boundary
- **Postcondition/Invariant:** DD-013 — `--allow` prefix matching is URL-component-aware; no false allowances via string prefix overlap.

## Proof Method

| Method | Tool | Bounded? | Coverage |
|--------|------|----------|----------|
| proptest | proptest 1.6.0 | no — property-based | Generated host strings with and without suffix extensions; allow prefix constructed to test boundary |

## Proof Harness Skeleton

```rust
proptest! {
    #[test]
    fn vp010_allow_no_suffix_bypass(
        host in "[a-z]{3,8}\\.[a-z]{2,4}",
        suffix in "\\.[a-z]{3,8}\\.[a-z]{2,4}",
        path in "/[a-z/]{0,20}"
    ) {
        let allowed_prefix = format!("https://{}", host);
        let allowed_url = format!("https://{}{}", host, path);
        let bypass_url = format!("https://{}{}{}", host, suffix, path);

        let prefixes = vec![AllowPrefix::parse(&allowed_prefix).unwrap()];

        // Legitimate URL under the prefix must match
        prop_assert!(should_allow(&allowed_url, &prefixes),
            "URL under allow prefix must be allowed");

        // URL with host suffix must NOT match
        prop_assert!(!should_allow(&bypass_url, &prefixes),
            "URL with extended host suffix must NOT be allowed: {}",
            bypass_url);
    }
}
```

## Feasibility Assessment

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Input space size | Property-based | Generated host + suffix combos; URL parsing ensures component-level comparison |
| Proof complexity | Low | URL parsing + host equality check; straightforward logic |
| Tool support | Full | proptest 1.6.0 string strategies sufficient |
| Estimated proof time | < 5s per run | |

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-05 | architect |
| Proof harness committed | — | formal-verifier |
| Proof first passed | — | formal-verifier |
| Locked (VERIFIED) | — | formal-verifier |
