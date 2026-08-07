---
document_type: behavioral-contract
level: L3
version: "1.4"
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
  - v1.4: "WS-4 Shard E: POLICY-5 repair — L2 Capability fabricated quote replaced with verbatim CAP-014 title ('Exit Code Determination'); VP-005 proof method corrected to 'kani' (was 'unit test') per VP-INDEX authority."
  - "v1.3: (exit-code ruling) Removed Precondition 3 (broken-link co-requirement); Description updated to make standalone exit 2 (io_error/config_error without broken links) explicit; PC2 config_error description tightened to canonical sole trigger (invalid --ignore glob); scope-exclusion note added for --help/--version."
  - "v1.2: (INC-MAP) Architecture Module field added per bc-module-map.md (architect, Phase 1b)"
  - "v1.1: Three-input model alignment — Description, Precondition 2, and Invariant 3 updated to name verdict::exit_code(findings, io_errors, config_error). Nonexistent PATH explicitly classified as io_errors (not config_error). Mixed-case test vector added (good_dir + nonexistent_dir + broken link → exit 2). Architect v1.4 reconciliation."
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.14.002: Exit Code 2 Takes Precedence Over Exit Code 1

## Description
Exit code 2 takes strict precedence over exit code 1 (DI-011). If a run encounters an I/O error
OR a configuration error, the process exits 2 regardless of whether any broken links were found.
This includes the standalone case: no broken links, but an I/O error occurred (e.g., an unreadable
file or nonexistent PATH argument) — the exit is still 2. The exit code is computed by the
pure-core function `verdict::exit_code(findings, io_errors, config_error) → u8`: exit 2 if
`io_errors` is non-empty OR `config_error = true`; exit 1 if any finding has verdict `broken` and
no 2-triggering condition; exit 0 otherwise. `indeterminate` findings never raise the exit code.

Scope exclusion: `--help` and `--version` are intercepted by clap before `app::run()` is called;
they never reach `verdict::exit_code` and are outside this BC's scope (see BC-2.14.004).

## Preconditions
1. All scanning and reporting is complete.
2. At least one condition that triggers exit 2 has occurred: `io_errors` is non-empty (I/O error during scan OR a nonexistent PATH argument — both are recorded into `Vec<IoError>`) OR `config_error = true`. The sole trigger for `config_error = true` is an invalid `--ignore` glob pattern (detected by `globset` after clap parsing); unrecognized flags are handled by clap before `app::run()` and do NOT set `config_error`.

## Postconditions
1. Process exit code: 2.
2. Both the broken finding(s) AND the I/O error finding(s) are reported in output.
3. The summary line on stderr reflects the broken count (for text format).

## Invariants
1. Exit 2 ALWAYS beats exit 1. No exception. (DI-011)
2. No fail-fast: even with I/O errors, the scan continues for all remaining valid paths (DD-007). Broken links from successfully scanned paths are still reported.
3. The exit code is the deterministic output of `verdict::exit_code(findings, io_errors, config_error) → u8`. Precedence: if `io_errors` non-empty OR `config_error = true` → 2; elif any `broken` finding → 1; else → 0. `indeterminate` never raises the exit code.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-169 | 1 broken link + invalid `--format` flag |

## Canonical Test Vectors
| Scenario | Expected Exit |
|----------|--------------|
| 1 broken link + 1 unreadable file | 2 |
| 1 broken link, no I/O errors | 1 |
| 1 unreadable file, no broken links | 2 |
| All clean | 0 |
| `mdlinkcheck good_dir/ nonexistent_dir/` — good_dir has 1 broken link; nonexistent_dir does not exist (io_errors non-empty; findings has broken) | 2 (exit 2 beats exit 1; good_dir IS fully scanned and its broken finding IS reported) |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-005 | Exit 2 beats exit 1 | kani |
| VP-005 | No fail-fast: broken links still reported with I/O error | kani |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-014 ("Exit Code Determination") per capabilities.md §CAP-014 |
| Capability Anchor Justification | CAP-014 ("Exit Code Determination") per capabilities.md §CAP-014 |
| L2 Domain Invariants | DI-011 |
| Brief Requirement | R7, DD-007, BV-005 |
| Architecture Module | `verdict.rs` (SS-14, pure core, CRITICAL tier) — ADR-007 (two-layer verdict model) |
