---
document_type: behavioral-contract
level: L3
version: "1.7"
status: draft
producer: vsdd-factory:product-owner
timestamp: 2026-08-10T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/specs/domain-spec/L2-INDEX.md
  - .factory/planning/brief-validation.md
  - .factory/planning/market-intelligence.md
input-hash: "07d983a"
traces_to: .factory/specs/domain-spec/L2-INDEX.md
origin: greenfield
extracted_from: null
subsystem: "SS-09"
capability: "CAP-009"
lifecycle_status: active
introduced: v1.0.0
modified:
  - "v1.7: (D-205/BI-052 remediation) VP-010 row annotation updated: VP-010 now describes a two-path algorithm (D-019 per BC-2.11.002). The proptest harness covers Path A (normalized URL component boundary). Path B (raw-string fallback for malformed URLs) is pending AllowPrefix API extension."
  - "v1.6: (WS-4/Shard-C) VP-010 proof method corrected from 'unit test (owned by SS-11 tests)' to 'proptest' per VP-INDEX authority."
  - v1.3: "F-017 — converted to pointer. --allow specification is now OWNED by BC-2.11.002 (SS-11/CAP-011). This BC exists only to note the SS-09 side-effect of --allow (URL is not validated). Duplicate postconditions removed; readers reference BC-2.11.002 for full matching algorithm."
  - "v1.4: (INC-MAP) Architecture Module field added per bc-module-map.md (architect, Phase 1b)"
  - "v1.5: (EC-collision) EC-090→EC-200 (EC-090 canonical owner is BC-2.10.009 per test-vectors.md registry)."
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
| EC | Description |
|----|-------------|
| EC-200 | `--allow https://example.com`; URL `https://example.com/page` |
| EC-091 | `--allow https://example.com`; URL `https://example.com.evil.tld/` |

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
| VP-010 | Component boundary prevents bypass Path A (normalized) — Path B raw-string fallback pending AllowPrefix API; see BC-2.11.002 and VP-010 v1.1 | proptest |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-009 ("External URL Syntax Validation") per capabilities.md §CAP-009 |
| Capability Anchor Justification | CAP-009 ("External URL Syntax Validation") per capabilities.md §CAP-009 — `--allow` causes SS-09 to skip validation; this is an SS-09 side-effect contract |
| L2 Domain Invariants | — (matching semantics fully specified in BC-2.11.002) |
| Brief Requirement | R5 |
| Architecture Module | `filter.rs` (SS-11, pure core, HIGH tier) primary; `url_classifier.rs` (SS-09) secondary — the external URL check that `--allow` suppresses — ADR-007 |

## Related BCs
- BC-2.11.002 — canonical specification for `--allow` matching algorithm (normalize-then-prefix-match with component-boundary safety)
