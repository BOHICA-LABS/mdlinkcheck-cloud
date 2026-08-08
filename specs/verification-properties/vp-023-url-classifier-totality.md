---
document_type: verification-property
level: L4
version: "1.1"
status: draft
producer: architect
timestamp: 2026-08-05T21:00:00Z
phase: 1b
inputs:
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/architecture/module-decomposition.md
input-hash: "3efc65a"
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
modified:
  - version: "1.1"
    date: 2026-08-07
    change: "BI-025 vacuity repair: prior v1.0 was outright vacuous — all three harnesses were satisfied by classify_url(_) -> Malformed(String::new()), which marks every external URL as broken. Added vp023_https_url_is_https and vp023_http_url_is_https to assert that valid http/https URLs return UrlKind::HttpS — these fail the all-Malformed implementation immediately. Added vp023_non_http_scheme_is_non_http to assert that mailto:, ftp:// etc. return UrlKind::NonHttp. Tightened totality harness to also assert the result is not Malformed for syntactically valid https URLs (previously the totality harness only prevented panics, not misclassifications). Added Non-Vacuousness Analysis section following VP-025 template."
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

`url_classifier::classify_url` is total and correct for all `&str` inputs:

1. **Totality:** For any `s: &str`, `classify_url(s)` completes without panic.

2. **Empty-dest contract (BC-2.07.007):** `classify_url("")` returns
   `UrlKind::Malformed(_)`. An empty destination is neither a non-http scheme nor a
   valid URL.

3. **Whitespace-only contract:** `classify_url("   ")` (or any string that trims to
   empty) returns `UrlKind::Malformed(_)` — whitespace-only destinations are not
   treated as relative paths or non-http schemes.

4. **https/http classification:** Any string beginning with `https://` or `http://`
   followed by a syntactically valid domain must return `UrlKind::HttpS(_)`, not
   `UrlKind::Malformed(_)` and not `UrlKind::NonHttp`. An implementation that returns
   `Malformed` for all inputs silently marks every external link as broken — the
   exact false-positive class the product exists to prevent.

5. **Non-http scheme classification:** Any string beginning with `mailto:`, `ftp://`,
   `ssh://`, or other non-http/https schemes must return `UrlKind::NonHttp` — these
   are out-of-scope links that must not trigger HTTP liveness checks and must not
   be classified as malformed.

**Falsified by:** An implementation `classify_url(_) -> Malformed(String::new())`
passes properties 1, 2, and 3 (the prior v1.0 harness) but fails properties 4 and 5:
`classify_url("https://example.com")` returns `Malformed` instead of `HttpS`,
silently marking every external link as broken and rendering `--online` mode useless.

## Source Contract

- **BC:** BC-2.07.007 — Empty Link Destination → `malformed-url`
- **Postcondition:** `verdict = broken`, `reason = malformed-url`; `path_resolver` and
  `anchor_resolver` are never called for an empty destination string.

## Proof Method

| Method | Tool | Bounded? | Coverage |
|--------|------|----------|----------|
| proptest | proptest 1.6.0 | no — property-based, 10 000 samples per property | Arbitrary `&str` (panic check), empty string, whitespace-only, valid https:// and http:// URLs, non-http schemes (mailto:, ftp://, ssh://) |

## Proof Harness Skeleton

```rust
use proptest::prelude::*;
use mdlinkcheck_core::url_classifier::{classify_url, UrlKind};

proptest! {
    // ── P1: totality (no panic) ──────────────────────────────────────────────
    //
    // Any implementation that panics on an arbitrary string fails here.
    // This includes: unwrap() on failed URL parse of arbitrary input,
    // index operations on empty strings, byte-range panics.
    // Does NOT verify correctness — correctness is P2..P5.
    #[test]
    fn vp023_classify_url_total(s in ".*") {
        let _ = classify_url(&s);
    }

    // ── P2: empty-dest contract (BC-2.07.007) ────────────────────────────────
    //
    // An empty string is never a valid URL or non-http scheme.
    // Returns Malformed, not NonHttp and not HttpS.
    // Falsified by: classify_url("") returning NonHttp or HttpS.
    #[test]
    fn vp023_empty_dest_is_malformed() {
        match classify_url("") {
            UrlKind::Malformed(_) => {}
            other => panic!("Empty destination must return Malformed, got {:?}", other),
        }
    }

    // ── P3: whitespace-only contract ─────────────────────────────────────────
    //
    // Whitespace-only destinations are not relative paths or non-http schemes.
    // Returns Malformed, not NonHttp and not HttpS.
    // Falsified by: classify_url("  ") returning NonHttp (treating whitespace as a
    // non-http scheme) or HttpS.
    #[test]
    fn vp023_whitespace_only_is_malformed(spaces in " +") {
        match classify_url(&spaces) {
            UrlKind::Malformed(_) => {}
            other => panic!("Whitespace-only {:?} must return Malformed, got {:?}", spaces, other),
        }
    }

    // ── P4: valid https:// URLs return HttpS ─────────────────────────────────
    //
    // This is the PRIMARY anti-vacuousness property.
    // An implementation returning Malformed for all inputs would silently mark
    // every external URL as broken — the false-positive class the product exists
    // to prevent. P4 directly falsifies that implementation.
    //
    // Strategy: generate <domain>.<tld> patterns that form valid https:// URLs.
    // The URL parser recognises these as syntactically valid https URLs.
    //
    // Falsified by: classify_url("https://example.com") returning Malformed(_)
    // or NonHttp instead of HttpS(_).
    #[test]
    fn vp023_https_url_is_https(
        domain in "[a-z]{3,12}",
        tld    in "[a-z]{2,4}",
    ) {
        let url = format!("https://{}.{}", domain, tld);
        match classify_url(&url) {
            UrlKind::HttpS(_) => {}
            UrlKind::Malformed(_) => panic!(
                "Valid https URL {:?} must return HttpS, got Malformed — \
                 this misclassification marks every external link as broken",
                url
            ),
            UrlKind::NonHttp => panic!(
                "Valid https URL {:?} must return HttpS, got NonHttp",
                url
            ),
        }
    }

    // ── P5: valid http:// URLs return HttpS ──────────────────────────────────
    //
    // Same correctness requirement as P4, for plain http:// URLs.
    // Both http and https map to UrlKind::HttpS because both require HTTP liveness
    // checking. An implementation that handles https but not http (or vice versa)
    // is still broken.
    //
    // Falsified by: classify_url("http://example.com") returning Malformed(_) or
    // NonHttp instead of HttpS(_).
    #[test]
    fn vp023_http_url_is_https(
        domain in "[a-z]{3,12}",
        tld    in "[a-z]{2,4}",
    ) {
        let url = format!("http://{}.{}", domain, tld);
        match classify_url(&url) {
            UrlKind::HttpS(_) => {}
            UrlKind::Malformed(_) => panic!(
                "Valid http URL {:?} must return HttpS, got Malformed",
                url
            ),
            UrlKind::NonHttp => panic!(
                "Valid http URL {:?} must return HttpS, got NonHttp",
                url
            ),
        }
    }

    // ── P6: non-http schemes return NonHttp ──────────────────────────────────
    //
    // mailto:, ftp://, ssh:// and other non-http/https schemes are out-of-scope
    // links. They must not be classified as Malformed (which would produce broken
    // verdicts) or as HttpS (which would trigger HTTP liveness checks).
    //
    // Falsified by: classify_url("mailto:foo@bar.com") returning Malformed or HttpS.
    #[test]
    fn vp023_non_http_scheme_is_non_http(
        scheme in "(mailto|ftp|ssh|git|file)",
        local  in "[a-z]{3,12}",
    ) {
        let dest = format!("{}:{}", scheme, local);
        match classify_url(&dest) {
            UrlKind::NonHttp => {}
            UrlKind::Malformed(_) => panic!(
                "Non-http scheme {:?} must return NonHttp, got Malformed — \
                 this misclassification produces a false-positive broken verdict \
                 for every mailto:, ftp://, and similar link",
                dest
            ),
            UrlKind::HttpS(_) => panic!(
                "Non-http scheme {:?} must return NonHttp, got HttpS — \
                 would trigger HTTP liveness checks for non-http links",
                dest
            ),
        }
    }
}
```

## Non-Vacuousness Analysis

Five wrong implementations are falsified by different harnesses in this VP:

| Wrong Implementation | Falsifying Harness | Failure Mode |
|---|---|---|
| `classify_url(_) -> Malformed("")` (all-broken impl) | vp023_https_url_is_https (P4) | `https://example.com` returns Malformed, expected HttpS |
| `classify_url(_) -> Malformed("")` (all-broken impl) | vp023_http_url_is_https (P5) | `http://example.com` returns Malformed, expected HttpS |
| `classify_url(_) -> NonHttp` (all-ignored impl) | vp023_empty_dest_is_malformed (P2) | `""` returns NonHttp, expected Malformed |
| `classify_url(_) -> NonHttp` (all-ignored impl) | vp023_https_url_is_https (P4) | `https://...` returns NonHttp, expected HttpS |
| `classify_url(_) -> HttpS(...)` (always-check impl, panics on empty) | vp023_classify_url_total (P1) | `classify_url("")` panics on URL parse attempt |
| Mailto classified as Malformed | vp023_non_http_scheme_is_non_http (P6) | `mailto:foo` returns Malformed, expected NonHttp |

The hit/miss boundary requires a correct three-way discriminant: `HttpS` for
http/https, `NonHttp` for other schemes, and `Malformed` for syntactically invalid
destinations including the empty string. No single constant return value can satisfy
all four correctness properties simultaneously.

## Feasibility Assessment

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Input space size | Unbounded (property-based) | proptest generates arbitrary Unicode strings (P1) and domain-like patterns (P4, P5) |
| Proof complexity | Low | `classify_url` is a pure function with no I/O; proptest strategies are standard |
| Tool support | Full | `proptest 1.6.0`; no Kani required (WHATWG URL parser internal states are too large for model-checking) |
| Estimated proof time | < 5s per run (Phase 3 CI) | 10 000 samples × 6 properties; `cargo nextest` |
| Panic risk class | Real | An `unwrap()` or index operation on empty-string WHATWG URL parse result panics at runtime; P1 catches this exhaustively |

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-05 | architect |
| v1.1 — BI-025 vacuity repair: added P4/P5/P6 + Non-Vacuousness Analysis | 2026-08-07 | architect |
| Proof harness committed | — | formal-verifier |
| Proof first passed | — | formal-verifier |
| Locked (VERIFIED) | — | formal-verifier |
