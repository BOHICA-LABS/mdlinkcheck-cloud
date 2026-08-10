---
document_type: behavioral-contract
level: L3
version: "1.5"
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
subsystem: "SS-13"
capability: "CAP-013"
lifecycle_status: active
introduced: v1.0.0
modified:
  - "v1.1: (F-013) added PC7 — top-level errors array for file-level I/O failures; target-unreadable entries go in errors[], not results[]; updated invariants and test vectors. (F-023) fixed PC4 sort key to specify NFC-normalized file path per DI-001"
  - "v1.2: (INC-MAP) Architecture Module field added per bc-module-map.md (architect, Phase 1b)"
  - "v1.5: (GATE-58/POL-14) VP-NNN column bare em-dashes (3 rows) are non-conforming per POL-14; replaced with VP-NONE (D-078) — all three have proof method 'integration', so VP-NONE is accepted."
  - "v1.4: (BI-052 remediation P7-S13-001) VP table corrected. VP-011 row re-scoped: VP-011 proves deterministic sort order; it does not verify JSON parseability or structural validity. Parseability is verified by acceptance corpus tests. VP-021 rows corrected: VP-021 tests the text-report sort ordering (reporter.rs); it does not detect ANSI escape sequences in JSON output or verify field order. VP-021 uses serde_json::Value which ignores field order. Both VP-021 rows changed to bare dash."
  - "v1.3: (WS-4/POLICY-5) L2 Capability fabricated quotation repaired: replaced invented excerpt with verbatim CAP-013 heading per capabilities.md §CAP-013; gloss moved outside quotes. VP-011 proof method corrected from 'integration test (jq)' to 'proptest (P1)'; VP-021 proof method corrected from 'unit test' to 'integration (test-sufficient)' — per VP-INDEX authority"
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.13.001: JSON Report Format — `{"schema_version":1,"results":[...],"errors":[...]}` to Stdout

## Description
When `--format json` is passed, the tool emits a single JSON object to stdout. The object has
`schema_version: 1` and a `results` array containing one object per finding (broken or
indeterminate). Clean links are never included. The object is compact (not pretty-printed).

## Preconditions
1. `--format json` has been passed.
2. All link validation is complete.

## Postconditions
1. stdout contains exactly one JSON object:
   `{"schema_version":1,"results":[...],"errors":[...]}`.
   Both `results` and `errors` are always present; each may be an empty array.
2. Each finding object in `results` has fields in this order:
   `file`, `line`, `column`, `link_target`, `verdict`, `reason`.
3. `verdict` in `results` is one of `"broken"` or `"indeterminate"`. Never `"clean"`.
4. `results` is sorted by (NFC-normalized file path, line, column, link_target) ascending — same order
   as text output (DI-001).
5. The JSON is compact; no trailing newline required but acceptable.
6. No ANSI color codes in JSON output.
7. File-level I/O errors (reason `target-unreadable`) are emitted in the `errors` array,
   NOT in `results`. Each error object has fields: `file`, `reason`, `message`.
   These entries do NOT have `line`, `column`, `link_target`, or `verdict` fields.
   Example: `{"file":"bad.md","reason":"target-unreadable","message":"cannot read file: bad.md: permission denied"}`

## Invariants
1. `schema_version` is always 1 for this version.
2. Clean links are never in `results`.
3. An empty scan (no findings, no errors) produces `{"schema_version":1,"results":[],"errors":[]}`.
4. stdout is pure JSON — no diagnostic messages, no summary line (those go to stderr).
5. JSON is machine-parseable: `mdlinkcheck --format json | jq` must work.
6. `target-unreadable` entries are NEVER placed in `results`. They go exclusively in `errors`.
   A `results` entry with `"reason":"target-unreadable"` is a bug.
7. The `errors` array is additive and does not affect `schema_version`; the `errors` field
   was present from schema_version 1 (non-breaking addition in pre-1.0).

## Edge Cases
| EC | Description |
|----|-------------|
| EC-138 | No findings, no errors |
| EC-139 | JSON piped to file |
| EC-140 | Mixed broken + indeterminate findings |

## Canonical Test Vectors
| Scenario | Expected JSON |
|----------|--------------|
| `README.md:5: missing.md (file-not-found)` | `{"schema_version":1,"results":[{"file":"README.md","line":5,"column":1,"link_target":"missing.md","verdict":"broken","reason":"file-not-found"}],"errors":[]}` |
| 0 findings, 0 errors | `{"schema_version":1,"results":[],"errors":[]}` |
| `bad.md` unreadable (permission denied) | `{"schema_version":1,"results":[],"errors":[{"file":"bad.md","reason":"target-unreadable","message":"cannot read file: bad.md: permission denied"}]}` |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-011 | JSON findings sorted deterministically (NFC path asc, line asc, column asc, link_target asc) — same sort property as text output | proptest |
| VP-NONE | JSON output is valid and parseable — no current VP; verified by acceptance corpus (jq parse in CI) | integration |
| VP-NONE | No ANSI codes in JSON output — no current VP; verified by acceptance corpus integration tests | integration |
| VP-NONE | Field order consistent (file, line, column, link_target, verdict, reason) — no current VP; VP-011 uses serde_json::Value which ignores field order | integration |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-013 ("JSON Report Generation") per capabilities.md §CAP-013 — emits {schema_version:1, results:[...], errors:[...]} to stdout; same sort order as text output |
| Capability Anchor Justification | CAP-013 ("JSON Report Generation") per capabilities.md §CAP-013 |
| L2 Domain Invariants | DI-001 (NFC-normalized sort order enforced in PC4) |
| Brief Requirement | R6 |
| Architecture Module | `reporter.rs` (SS-13, pure core, HIGH tier) — ADR-005 (sort-before-emit), ADR-007 (verdict model) |
