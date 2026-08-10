---
document_type: verification-property
level: L4
version: "1.3"
status: draft
producer: architect
timestamp: 2026-08-10T00:00:00Z
phase: 1b
inputs:
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/prd-supplements/error-taxonomy.md
input-hash: "9f3526f"
traces_to: .factory/specs/architecture/ARCH-INDEX.md
source_bc: BC-2.10.002
module: http_verdict
proof_method: kani
feasibility: feasible
verification_lock: false
proof_completed_date: null
proof_file_hash: null
lifecycle_status: active
introduced: v0.1.0
modified:
  - version: "1.3"
    date: 2026-08-10
    change: "BI-052 remediation (P7-S7-003): corrected harness to use declared API types from api-surface.md. Fixed: (1) verdict.kind -> direct match on verdict enum (no .kind field; Verdict is the enum); (2) VerdictKind::Alive/Broken/Indeterminate -> Verdict::Clean/Broken/Indeterminate per api-surface.md; (3) HttpAttempt::Get -> HttpAttempt::GetFallback per api-surface.md line 103. Remaining issue: verify_vp007_correctness_dns_tls_broken harness still references classify_response_with_error(HttpError::DnsFailure/TlsError/Timeout) and HttpError enum — neither exists in the declared API (api-surface.md exposes only classify_response(status: u16, attempt: HttpAttempt)). These harnesses remain pending HttpAttempt transport-error encoding extension. BCs 2.10.005 and 2.10.006 updated to reflect this pending status."
  - version: "1.2"
    date: 2026-08-05
    change: "P2-M01 remediation: added D-018 assertion — HTTP 400 received after GET fallback produces indeterminate (not broken). 400 can indicate server-side validation rejecting a method; it is not a reliable signal that the link target does not exist."
  - version: "1.1"
    date: 2026-08-05
    change: "SR-022 remediation: added correctness assertions to harness — 429/5xx/timeout never produce broken; 404/410 produce broken; dns-failure and tls-error produce broken (per ADR-007 v1.1 and error-taxonomy.md); updated property statement title and description; corrected '9-reason-code' to '13-reason-code' per error-taxonomy.md"
deprecated: null
deprecated_by: null
replacement: null
retired: null
withdrawn: null
withdrawal_reason: null
removed: null
removal_reason: null
---

# VP-007: http_verdict::classify_response is Total and Correct

## Property Statement

For all valid HTTP status codes `status` in the range 0..=999 and all variants of
`HttpAttempt` (HEAD and GET), `classify_response(status, attempt)` terminates and
returns a `Verdict` without panicking — **totality**.

Additionally — **correctness** (SR-022):
- HTTP 429 (Too Many Requests) and all 5xx responses NEVER produce `broken`
  (they produce `indeterminate`; retrying is appropriate)
- HTTP 404 (Not Found) and 410 (Gone) ALWAYS produce `broken`
- `dns-failure` and `tls-error` ALWAYS produce `broken`
  (per ADR-007 v1.1 rationale: DNS/TLS failures are deterministic; the link is broken)
- HTTP timeout (no response received) produces `indeterminate`, not `broken`
- HTTP 400 (Bad Request) received after a GET fallback produces `indeterminate`, not
  `broken` (D-018: 400 can reflect server-side method validation, not link non-existence)

These correctness constraints directly encode ADR-007 v1.1, D-018, and DI-010
(indeterminate does not cause exit 1).

## Source Contract

- **BC:** BC-2.10.002 — HTTP Response Classification
- **Postcondition/Invariant:** `classify_response` is a total and correct function for
  all `(u16, HttpAttempt)` inputs; the closed 13-reason-code taxonomy has no gaps.

## Proof Method

| Method | Tool | Bounded? | Coverage |
|--------|------|----------|----------|
| kani | Kani 0.67.0 | no — exhaustive over u16 × {HEAD, GET} | All 65536 × 2 input combinations, plus correctness assertions |

## Proof Harness Skeleton

```rust
#[kani::proof]
fn verify_vp007_http_verdict_total() {
    let status: u16 = kani::any();
    let attempt: HttpAttempt = kani::any();
    // No range assumption — must be total for ALL u16 values

    // Totality: must not panic
    let verdict = classify_response(status, attempt);

    // Verdict must be one of the three valid variants (api-surface.md: Verdict enum)
    match &verdict {
        Verdict::Clean | Verdict::Broken(_) | Verdict::Indeterminate(_) => {}
    }
}

#[kani::proof]
fn verify_vp007_correctness_indeterminate_not_broken() {
    let attempt: HttpAttempt = kani::any();

    // 429 → indeterminate, never broken (ADR-007 v1.1)
    let v429 = classify_response(429, attempt);
    assert!(!matches!(v429, Verdict::Broken(_)),
        "429 must not be broken");

    // 500..=599 → indeterminate, never broken
    let status_5xx: u16 = kani::any();
    kani::assume(status_5xx >= 500 && status_5xx <= 599);
    let v5xx = classify_response(status_5xx, attempt);
    assert!(!matches!(v5xx, Verdict::Broken(_)),
        "5xx must not be broken: status {}", status_5xx);
}

#[kani::proof]
fn verify_vp007_correctness_404_410_broken() {
    let attempt: HttpAttempt = kani::any();

    // 404 → broken
    let v404 = classify_response(404, attempt);
    assert!(matches!(v404, Verdict::Broken(_)),
        "404 must be broken");

    // 410 → broken
    let v410 = classify_response(410, attempt);
    assert!(matches!(v410, Verdict::Broken(_)),
        "410 must be broken");
}

// PENDING API EXTENSION — this harness cannot be compiled against the declared API.
// api-surface.md exposes only classify_response(status: u16, attempt: HttpAttempt) -> Verdict
// with HttpAttempt { Head, GetFallback }.
// There is no classify_response_with_error function and no HttpError enum in the declared API.
// The transport-layer error encoding (dns-failure, tls-error, timeout) requires either:
//   (a) extending HttpAttempt with variants DnsFailure/TlsFailure/Timeout, OR
//   (b) adding a classify_error(error_kind: TransportError) -> Verdict function.
// Until that API extension is declared, the dns/tls/timeout harnesses below are
// design sketches only and cannot be run by the formal-verifier.
// BCs 2.10.005 and 2.10.006 are updated to reflect this pending status.
//
// #[kani::proof]
// fn verify_vp007_correctness_dns_tls_broken() {
//     // dns-failure case (DI-010 exception per ADR-007 v1.1)
//     let v_dns = classify_response_with_error(HttpError::DnsFailure);  // API NOT DECLARED
//     assert!(matches!(v_dns, Verdict::Broken(_)), "dns-failure must be broken");
//
//     // tls-error case
//     let v_tls = classify_response_with_error(HttpError::TlsError);    // API NOT DECLARED
//     assert!(matches!(v_tls, Verdict::Broken(_)), "tls-error must be broken");
//
//     // timeout case → indeterminate (not broken)
//     let v_timeout = classify_response_with_error(HttpError::Timeout); // API NOT DECLARED
//     assert!(!matches!(v_timeout, Verdict::Broken(_)), "timeout must not be broken");
// }

#[kani::proof]
fn verify_vp007_correctness_400_after_get_indeterminate() {
    // D-018: HTTP 400 received after a GET fallback (HEAD returned 4xx, then GET
    // returned 400) produces indeterminate, not broken.
    // Rationale: 400 can indicate the server rejected the method or request format,
    // not that the link target does not exist. Returning broken here would cause
    // false positives for links that work fine in a browser.
    //
    // This harness uses HttpAttempt::GetFallback (api-surface.md: HttpAttempt { Head, GetFallback }).
    let v400_get = classify_response(400, HttpAttempt::GetFallback);
    assert!(!matches!(v400_get, Verdict::Broken(_)),
        "400 after GET fallback must not produce broken (D-018)");
    assert!(matches!(v400_get, Verdict::Indeterminate(_)),
        "400 after GET fallback must produce indeterminate (D-018)");
}
```

**Note on `classify_response_with_error`:** The exact API signature for network-error
verdicts (dns-failure, tls-error, timeout) depends on whether the implementation uses a
combined `(u16, HttpAttempt)` type with error-encoding status codes, or a separate
`classify_error(HttpError) -> Verdict` function. The harness above assumes the latter.
If the implementer uses the former, the harness must be adapted to pass the appropriate
`(status, attempt)` encoding for each error case. The semantic assertions (broken/not
broken) remain unchanged regardless of signature.

## Feasibility Assessment

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Input space size | Exhaustive | 65536 × 2 = 131072 combinations; CBMC handles this as a bounded integer |
| Proof complexity | Very low | Match statement over u16 ranges; no loops |
| Tool support | Full | Kani handles `kani::any::<u16>()` exhaustively |
| Estimated proof time | < 30s | Integer range matching is fast; correctness harnesses add minimal overhead |

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-05 | architect |
| v1.1 — SR-022 correctness harnesses | 2026-08-05 | architect |
| Proof harness committed | — | formal-verifier |
| Proof first passed | — | formal-verifier |
| Locked (VERIFIED) | — | formal-verifier |
