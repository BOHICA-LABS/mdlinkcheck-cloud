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
subsystem: "SS-14"
capability: "CAP-014"
lifecycle_status: active
introduced: v1.0.0
modified:
  - v1.5: "(GATE-58/D-244) EC citation corrected: EC-146 → EC-143 — 'Only --online indeterminate results' matches '0 broken links, 1 indeterminate' (both test indeterminate-only scan → exit 0 boundary); EC-146 registry describes SIGINT/exit-2, a different scenario (direction a, same underlying scenario)."
  - v1.4: "WS-4 Shard E: POLICY-5 repair — L2 Capability fabricated quote replaced with verbatim CAP-014 title ('Exit Code Determination'); VP-005 and VP-006 proof methods corrected to 'kani' (was 'unit test') per VP-INDEX authority."
  - "v1.3: (exit-code ruling) PC4 updated: removed 'unrecognized flags' from config_error description — unrecognized flags are handled by clap before app::run() and do not set config_error; config_error = true has exactly one trigger (invalid --ignore glob); scope-exclusion note added for --help/--version."
  - "v1.2: (INC-MAP) Architecture Module field added per bc-module-map.md (architect, Phase 1b)"
  - "v1.1: Three-input model alignment — Preconditions 3 and 4 now cite verdict::exit_code parameter names (io_errors and config_error). Precondition 3 clarifies that nonexistent PATH arguments count as I/O errors. Architect v1.4 reconciliation."
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.14.003: Exit Code 1 — At Least One Broken Link Found

## Description
The process exits 1 when at least one link received a `broken` verdict AND no I/O or usage
errors occurred (which would trigger exit 2). Exit 1 means: the tool definitively found broken
links; the calling script should treat this as a CI failure.

## Preconditions
1. All scanning and reporting is complete.
2. At least one link received verdict `broken`.
3. No I/O errors occurred — no unreadable files and no nonexistent PATH arguments. (Corresponds to `io_errors = []` in `verdict::exit_code`. A nonexistent PATH argument is an I/O error, not a startup config error.)
4. No configuration error occurred — specifically, no invalid `--ignore` glob pattern was detected (the sole trigger for `config_error = true`). This corresponds to `config_error = false` in `verdict::exit_code`. Scope exclusion: unrecognized flags are handled by clap before `app::run()` and do NOT set `config_error`; `--help`/`--version` are also handled by clap before `app::run()` and are outside this BC's scope (see BC-2.14.004).

## Postconditions
1. Process exit code: 1.
2. Broken findings are reported in stdout output.
3. Summary line on stderr: `N broken link(s) in M file(s).`

## Invariants
1. Only `broken` verdict links trigger exit 1. `indeterminate` does not.
2. Exit 1 is preempted by exit 2 (BC-2.14.002).
3. CI pipelines that check exit code can rely on: 0=success, 1=broken, 2=error.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-144 | 1 broken link, 0 I/O errors |
| EC-145 | 100 broken links, 0 I/O errors |
| EC-143 | 0 broken links, 1 indeterminate |

## Canonical Test Vectors
| Scenario | Expected Exit |
|----------|--------------|
| 1 file-not-found broken link | 1 |
| 1 anchor-not-found broken link | 1 |
| 1 indeterminate only | 0 |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-005 | Exit 1 when broken links found, no I/O errors | kani |
| VP-006 | Indeterminate does not trigger exit 1 | kani |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-014 ("Exit Code Determination") per capabilities.md §CAP-014 |
| Capability Anchor Justification | CAP-014 ("Exit Code Determination") per capabilities.md §CAP-014 |
| L2 Domain Invariants | DI-010, DI-011 |
| Brief Requirement | R7 |
| Architecture Module | `verdict.rs` (SS-14, pure core, CRITICAL tier) — ADR-007 (two-layer verdict model) |
