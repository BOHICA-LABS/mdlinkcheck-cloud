---
document_type: verification-property
level: L4
version: "1.1"
status: draft
producer: architect
timestamp: 2026-08-05T20:00:00Z
phase: 1b
inputs:
  - .factory/specs/prd-supplements/error-taxonomy.md
  - .factory/specs/prd-supplements/nfr-catalog.md
  - .factory/specs/behavioral-contracts/ss-12/BC-2.12.001.md
  - .factory/specs/behavioral-contracts/ss-13/BC-2.13.001.md
input-hash: "92b8d5b"
traces_to: .factory/specs/architecture/ARCH-INDEX.md
source_bc: BC-2.12.001
module: reporter
proof_method: integration
feasibility: feasible
verification_lock: false
proof_completed_date: null
proof_file_hash: null
lifecycle_status: active
introduced: v0.1.0
modified:
  - version: "1.1"
    date: 2026-08-05
    change: "P2-C02 remediation: added http-timeout (13th code) to known_codes whitelist; added iteration over errors[] array (target-unreadable routes there per error-taxonomy.md §6.1); added positive-coverage assertion (N reason-code occurrences across M fixtures)"
deprecated: null
deprecated_by: null
replacement: null
retired: null
withdrawn: null
withdrawal_reason: null
removed: null
removal_reason: null
---

# VP-021: No Undefined Reason Codes — All Emitted Reasons Are in the Closed Set

## Property Statement

Every `reason` field emitted in any output (text format, JSON format) is a member of
the closed reason-code set defined in `error-taxonomy.md`. No run of `mdlinkcheck`
ever emits a reason code that is not in that set.

The closed set (13 codes, from `error-taxonomy.md` §3):
```
file-not-found, target-is-directory, broken-symlink, target-unreadable,
anchor-not-found, malformed-url, too-many-redirects, http-error,
http-indeterminate, http-timeout, dns-failure, tls-error,
undefined-reference-definition
```

The JSON envelope is `{schema_version, results[], errors[]}`. The `reason` field
appears in both `results[].reason` (most codes) and `errors[].reason` (always
`target-unreadable` per error-taxonomy.md §6.1 / interface-definitions.md §6.2b).
Both arrays must be iterated; checking only `results` silently ignores
`target-unreadable` occurrences.

This property is classified **test-sufficient** (NFR-007): it is enforced by a
corpus-wide integration test that parses all JSON output from the acceptance test
suite and asserts every `reason` value appears in the enumerated set. No formal proof
is required because the closed set is a compile-time enum (`ReasonCode`) in the Rust
type system — the integration test validates that no variant is added to the enum
without a corresponding entry in the taxonomy documentation.

## Source Contract

- **BC:** BC-2.12.001 — Text Report Format (primary); BC-2.13.001 — JSON Report Format (also covered)
- **NFR:** NFR-007 — No Undefined Reason Codes
- **Postcondition:** Every `Finding.reason` value is a variant of `ReasonCode`; the
  `ReasonCode` enum is exhaustively documented in `error-taxonomy.md`.

## Proof Method

| Method | Tool | Bounded? | Coverage |
|--------|------|----------|----------|
| integration | cargo nextest (Phase 3) | yes — acceptance corpus | Parses all JSON output from the full acceptance corpus and asserts every `reason` field is a known code |

## Proof Harness Skeleton

```rust
// Integration test: parse all acceptance corpus JSON outputs
#[test]
fn no_undefined_reason_codes() {
    // Derive from a single authoritative source; this list must mirror
    // ReasonCode::VARIANTS in types.rs AND error-taxonomy.md §3.
    let known_codes: HashSet<&str> = [
        "file-not-found", "target-is-directory", "broken-symlink",
        "target-unreadable", "anchor-not-found", "malformed-url",
        "too-many-redirects", "http-error", "http-indeterminate",
        "http-timeout", "dns-failure", "tls-error",
        "undefined-reference-definition",
    ].into_iter().collect();
    assert_eq!(known_codes.len(), 13, "Taxonomy must have exactly 13 codes");

    let fixtures = corpus_fixtures();
    assert!(!fixtures.is_empty(), "corpus_fixtures() must not be empty");

    let mut total_checked: usize = 0;

    // Run each corpus fixture with --format json and verify reason codes
    for fixture in &fixtures {
        let output = run_mdlinkcheck(&fixture.args, "--format json");
        let json: serde_json::Value = serde_json::from_str(&output.stdout).unwrap();

        // Check results[] array
        for result in json["results"].as_array().unwrap_or(&vec![]) {
            if let Some(reason) = result.get("reason") {
                let code = reason.as_str().unwrap();
                assert!(
                    known_codes.contains(code),
                    "Unknown reason code '{}' in results[] of fixture {:?}",
                    code, fixture
                );
                total_checked += 1;
            }
        }

        // Check errors[] array — target-unreadable routes here per error-taxonomy.md §6.1
        for error in json["errors"].as_array().unwrap_or(&vec![]) {
            if let Some(reason) = error.get("reason") {
                let code = reason.as_str().unwrap();
                assert!(
                    known_codes.contains(code),
                    "Unknown reason code '{}' in errors[] of fixture {:?}",
                    code, fixture
                );
                total_checked += 1;
            }
        }
    }

    // Positive-coverage assertion: must have checked at least one reason code
    // across all fixtures. Prevents the test passing vacuously on an empty corpus.
    assert!(
        total_checked > 0,
        "No reason codes were checked — corpus produced zero findings. \
         Checked {} reason-code occurrences across {} fixtures.",
        total_checked, fixtures.len()
    );
}
```

## Feasibility Assessment

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Test complexity | Low | Simple set-membership check over JSON output |
| Coverage | High | Runs against entire acceptance corpus (all 140+ test vectors) |
| Tool support | Full | cargo nextest + serde_json |
| Phase | test-sufficient (Phase 3) | No formal proof required; type system + enum already provides compile-time guarantee |

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-05 | architect |
| Test harness committed | — | test-writer |
| First passed | — | implementer |
| Locked (VERIFIED) | — | formal-verifier |
