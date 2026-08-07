---
document_type: behavioral-contract
level: L3
version: "1.5"
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
subsystem: "SS-14"
capability: "CAP-014"
lifecycle_status: active
introduced: v1.0.0
modified:
  - v1.5: "WS-4 Shard E: POLICY-5 repair — L2 Capability fabricated quote replaced with verbatim CAP-014 title ('Exit Code Determination'); VP-006 proof method corrected to 'kani' (was 'unit test') per VP-INDEX authority."
  - "v1.4: (exit-code ruling) PC4 updated: removed 'no unrecognized flags' from config_error description — unrecognized flags are handled by clap before app::run() and do not set config_error. config_error = true has exactly one trigger: invalid --ignore glob pattern. Added note clarifying --help/--version are outside this BC's scope."
  - "v1.3: (EC-collision) EC-009 renamed to EC-184 (EC-009 canonical owner is BC-2.01.004 per test-vectors.md registry)."
  - "v1.2: (INC-MAP) Architecture Module field added per bc-module-map.md (architect, Phase 1b)"
  - "v1.1: Three-input model alignment — Precondition 4 corrected: nonexistent PATH is an I/O error (recorded in io_errors), not a startup config/usage error. Preconditions 3 and 4 now cite verdict::exit_code parameter names. Invariants updated to name all three inputs."
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.14.001: Exit Code 0 — No Broken Links

## Description
The process exits 0 when all links are either clean or indeterminate, and no I/O or startup
configuration errors occurred. This is the success exit code. In terms of the pure-core function,
`verdict::exit_code(findings, io_errors, config_error)` returns 0 when: no finding has verdict
`broken`, `io_errors` is empty, and `config_error` is false.

## Preconditions
1. All scanning and reporting is complete.
2. No `broken` verdict links were found.
3. No I/O errors occurred — no unreadable files and no nonexistent PATH arguments. (Corresponds to `io_errors = []` in `verdict::exit_code`.) Note: a nonexistent PATH argument is an I/O error, NOT a startup configuration error; it goes into `io_errors`, not `config_error`.
4. No configuration error occurred — specifically, no invalid `--ignore` glob pattern was detected (the sole trigger for `config_error = true`). This corresponds to `config_error = false` in `verdict::exit_code`. Note: unrecognized flags are handled by clap before `app::run()` is called and do NOT set `config_error`; `--help`/`--version` are similarly handled by clap before `app::run()` and are outside the scope of this BC.

## Postconditions
1. Process exit code: 0.
2. Indeterminate findings may have been emitted to stdout but do NOT cause exit 1 or 2.
3. `No broken links found.` on stderr (always emitted; --quiet is a non-goal per D-011).

## Invariants
1. Exit 0 means: the tool found no definitively broken links.
2. Exit 0 is consistent with having indeterminate findings.
3. Zero files found → exit 0 (EC-184).
4. All three inputs to `verdict::exit_code(findings, io_errors, config_error) → u8` must be "empty/false": no broken findings, `io_errors = []`, `config_error = false`. Any non-empty input in `io_errors` or `config_error = true` produces exit 2, not exit 0.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-142 | Scan with 0 findings |
| EC-143 | Scan with indeterminate findings only |
| EC-184 | Empty directory (no .md files) |

## Canonical Test Vectors
| Scenario | Expected Exit |
|----------|--------------|
| All links clean | 0 |
| All links indeterminate | 0 |
| No markdown files found | 0 |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-006 | Exit 0 with only indeterminate findings | kani |
| VP-006 | Exit 0 with no files | kani |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-014 ("Exit Code Determination") per capabilities.md §CAP-014 |
| Capability Anchor Justification | CAP-014 ("Exit Code Determination") per capabilities.md §CAP-014 |
| L2 Domain Invariants | DI-010, DI-011 |
| Brief Requirement | R7 |
| Architecture Module | `verdict.rs` (SS-14, pure core, CRITICAL tier) — ADR-007 (two-layer verdict model) |
