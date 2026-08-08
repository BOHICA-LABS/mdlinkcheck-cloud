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
input-hash: "07d983a"
traces_to: .factory/specs/domain-spec/L2-INDEX.md
origin: greenfield
extracted_from: null
subsystem: "SS-09"
capability: "CAP-009"
lifecycle_status: active
introduced: v1.0.0
modified:
  - "v1.2: (WS-4/Shard-C) POLICY-5 citation repair: L2 Capability quoted string was fabricated WHATWG description; corrected to verbatim section title 'External URL Syntax Validation' per capabilities.md §CAP-009; gloss moved outside quotes."
  - "v1.1: (INC-MAP) Architecture Module field added per bc-module-map.md (architect, Phase 1b)"
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.09.001: External URL Syntax Validation (Offline)

## Description
In offline mode (default), external URLs (`http://` and `https://` scheme) are validated for
syntactic correctness using the WHATWG URL parser. A URL that fails WHATWG parse is broken
(`malformed-url`) even in offline mode. A URL that passes WHATWG parse is clean in offline mode.

## Preconditions
1. A link has been classified as `external-http`.
2. The tool is in offline mode (no `--online` flag).

## Postconditions
1. The URL string is run through the WHATWG URL parser.
2. If WHATWG parse fails: verdict `broken`, reason `malformed-url`.
3. If WHATWG parse succeeds: verdict `clean`.
4. No HTTP request is made in offline mode.

## Invariants
1. The WHATWG URL standard is the authority for URL syntax validation.
2. A URL that WHATWG accepts is syntactically valid, regardless of whether the domain exists.
3. Syntax validation is the ONLY check performed in offline mode for external URLs.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-077 | `https://example.com/path?q=1&r=2#frag` |
| EC-078 | `http://` (no host) |
| EC-082 | `https://user:pass@host.com/path` |
| EC-083 | `https://[::1]:8080/path` (IPv6) |
| EC-084 | `https://xn--nxasmq6b.com` (Punycode) |

## Canonical Test Vectors
| URL | Expected Verdict (offline) | Category |
|-----|---------------------------|----------|
| `https://example.com` | clean | happy-path |
| `http://` | broken (malformed-url) | edge-case |
| `https://a b.com` (space) | broken (malformed-url) | edge-case |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | WHATWG-invalid URLs → malformed-url in offline mode | unit test |
| test-sufficient | No HTTP requests in offline mode | unit test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-009 ("External URL Syntax Validation") per capabilities.md §CAP-009 — malformed URLs are broken even in offline mode; WHATWG URL grammar is the authority |
| Capability Anchor Justification | CAP-009 ("External URL Syntax Validation") per capabilities.md §CAP-009 |
| Brief Requirement | R5, R6, T11 |
| Architecture Module | `url_classifier.rs` (SS-09, pure core, HIGH tier) — ADR-007 (verdict model — classification drives routing) |
