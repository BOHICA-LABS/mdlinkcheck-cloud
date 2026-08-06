---
document_type: verification-property
level: L4
version: "1.0"
status: draft
producer: architect
timestamp: 2026-08-05T21:00:00Z
phase: 1b
inputs:
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/architecture/module-decomposition.md
input-hash: "0433588"
traces_to: .factory/specs/architecture/ARCH-INDEX.md
source_bc: BC-2.07.007
module: url_classifier
proof_method: proptest
feasibility: feasible
verification_lock: false
proof_completed_date: null
proof_file_hash: null
lifecycle_status: active
introduced: v1.4.0
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

# VP-023: url_classifier::classify_url Totality — No Panic, Empty-String Contract

## Property Statement

`url_classifier::classify_url` is total for all `&str` inputs: it never panics, never
returns an incorrect variant, and treats the empty string as `UrlKind::Malformed(_)` —
not `UrlKind::NonHttp` and not `UrlKind::HttpS(_)`. Concretely:

1. **Totality:** for any `s: &str`, `classify_url(s)` completes without panic.
2. **Empty-dest contract (BC-2.07.007):** `classify_url("")` returns
   `UrlKind::Malformed(_)`. An empty destination is neither a non-http scheme nor a
   valid URL.
3. **Whitespace-only contract:** `classify_url("   ")` (or any string that trims to
   empty) returns `UrlKind::Malformed(_)` — whitespace-only destinations are not
   treated as relative paths or non-http schemes.

## Source Contract

- **BC:** BC-2.07.007 — Empty Link Destination → `malformed-url`
- **Postcondition:** `verdict = broken`, `reason = malformed-url`; `path_resolver` and
  `anchor_resolver` are never called for an empty destination string.

## Proof Method

| Method | Tool | Bounded? | Coverage |
|--------|------|----------|----------|
| proptest | proptest 1.6.0 | no — property-based, 10 000 samples | Arbitrary `&str` including empty string, whitespace-only, valid URLs, non-http schemes, partial URL fragments, percent-encoded junk |

## Proof Harness Skeleton

```rust
proptest! {
    #[test]
    fn vp023_classify_url_total(s in ".*") {
        // Property 1: never panics on any string
        let _ = classify_url(&s);
    }

    #[test]
    fn vp023_empty_dest_is_malformed() {
        // Property 2: empty string → Malformed, not NonHttp, not HttpS
        match classify_url("") {
            UrlKind::Malformed(_) => {}
            other => panic!("Expected Malformed, got {:?}", other),
        }
    }

    #[test]
    fn vp023_whitespace_only_is_malformed(spaces in " +") {
        // Property 3: whitespace-only → Malformed
        match classify_url(&spaces) {
            UrlKind::Malformed(_) => {}
            // NonHttp would be a silent misclassification bug
            other => panic!("Whitespace-only '{}' classified as {:?}", spaces, other),
        }
    }
}
```

## Feasibility Assessment

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Input space size | Unbounded (property-based) | proptest generates arbitrary Unicode strings; empty string and whitespace are included |
| Proof complexity | Low | `classify_url` is a pure function with no I/O; the proptest strategies are standard |
| Tool support | Full | `proptest 1.6.0`; no Kani required (WHATWG URL parser internal states are too large for model-checking) |
| Estimated proof time | < 5s per run (Phase 3 CI) | 10 000 samples; `cargo nextest` |
| Panic risk class | Real | An `unwrap()` or index operation on empty-string WHATWG URL parse result panics at runtime; proptest catches this exhaustively |

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-05 | architect |
| Proof harness committed | — | formal-verifier |
| Proof first passed | — | formal-verifier |
| Locked (VERIFIED) | — | formal-verifier |
