---
document_type: behavioral-contract
level: L3
version: "1.3"
status: draft
producer: vsdd-factory:product-owner
timestamp: 2026-08-05T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/specs/domain-spec/L2-INDEX.md
  - .factory/planning/brief-validation.md
  - .factory/planning/market-intelligence.md
input-hash: "19b62d8"
traces_to: .factory/specs/domain-spec/L2-INDEX.md
origin: greenfield
extracted_from: null
subsystem: "SS-09"
capability: "CAP-009"
lifecycle_status: active
introduced: v1.0.0
modified:
  - v1.3: "F-017 — converted to pointer. --allow specification is now OWNED by BC-2.11.002 (SS-11/CAP-011). This BC exists only to note the SS-09 side-effect of --allow (URL is not validated). Duplicate postconditions removed; readers reference BC-2.11.002 for full matching algorithm."
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.09.002: `--allow` URL Exemption — Specification in BC-2.11.002

## Description
**This BC is a cross-reference pointer. The canonical `--allow` specification is BC-2.11.002
(SS-11/CAP-011).** Read that BC for the full normalize-then-prefix-match algorithm, component-
boundary safety rule, and multiple-flag semantics.

From the perspective of SS-09 (External URL Syntax Validation): when a URL matches an allow
prefix (per BC-2.11.002), SS-09 skips both syntax validation AND liveness checking for that
URL. The verdict is `clean` and the link is not emitted in output.

## Preconditions
1. A link has been classified as `external-http`.
2. One or more `--allow URL_PREFIX` flags have been provided.

## Postconditions
1. If the URL matches an allow prefix (per the full algorithm in BC-2.11.002): verdict `clean`;
   URL is not validated and not emitted in output.
2. If the URL does NOT match any allow prefix: normal SS-09 validation applies.

## Invariants
1. The matching algorithm (normalize-then-prefix-match with component-boundary check) is
   specified exclusively in BC-2.11.002. SS-09 delegates the match decision to SS-11 logic.

## Edge Cases
| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-090 | `--allow https://example.com`; URL `https://example.com/page` | clean (see BC-2.11.002 for matching algorithm) |
| EC-091 | `--allow https://example.com`; URL `https://example.com.evil.tld/` | NOT exempt — normal SS-09 validation applies (see BC-2.11.002 §boundary check) |

## Canonical Test Vectors
| `--allow` Prefix | URL | Expected (SS-09 view) |
|------------------|-----|----------------------|
| `https://example.com` | `https://example.com/path` | clean (no validation) |
| `https://example.com` | `https://example.com.evil.tld/` | normal SS-09 validation |
| `https://example.com` | `https://example.com` | clean (exact match) |

See BC-2.11.002 for the authoritative test vectors including ordering and boundary checks.

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-010 | Component boundary prevents bypass — see BC-2.11.002 | unit test (owned by SS-11 tests) |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-009 ("External URL Syntax Validation") per capabilities.md §CAP-009 |
| Capability Anchor Justification | CAP-009 ("External URL Syntax Validation") per capabilities.md §CAP-009 — `--allow` causes SS-09 to skip validation; this is an SS-09 side-effect contract |
| L2 Domain Invariants | — (matching semantics fully specified in BC-2.11.002) |
| Brief Requirement | R5 |

## Related BCs
- BC-2.11.002 — canonical specification for `--allow` matching algorithm (normalize-then-prefix-match with component-boundary safety)
