---
document_type: behavioral-contract
level: L3
version: "1.2"
status: draft
producer: vsdd-factory:product-owner
timestamp: 2026-08-05T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/specs/domain-spec/L2-INDEX.md
  - .factory/planning/brief-validation.md
  - .factory/planning/market-intelligence.md
input-hash: "e860246"
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
4. `results` is sorted by (NFC-normalized file path, line, column) ascending — same order
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
| VP-011 | JSON output is valid and parseable | integration test (jq) |
| VP-021 | No ANSI codes in JSON output | unit test |
| VP-021 | Field order consistent | unit test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-013 ("Generate JSON-format report: {schema_version:1, results:[...]} to stdout; same sort order as text") per capabilities.md §CAP-013 |
| Capability Anchor Justification | CAP-013 ("JSON Report Generation") per capabilities.md §CAP-013 |
| L2 Domain Invariants | DI-001 (NFC-normalized sort order enforced in PC4) |
| Brief Requirement | R6 |
| Architecture Module | `reporter.rs` (SS-13, pure core, HIGH tier) — ADR-005 (sort-before-emit), ADR-007 (verdict model) |
