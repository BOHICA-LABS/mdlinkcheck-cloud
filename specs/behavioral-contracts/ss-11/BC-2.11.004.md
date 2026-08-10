---
document_type: behavioral-contract
level: L3
version: "1.9"
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
subsystem: "SS-11"
capability: "CAP-011"
lifecycle_status: active
introduced: v1.3.0
modified:
  - "v1.7: EC-NEW-10 and EC-NEW-11 allocated as EC-207 and EC-208; placeholders replaced with real IDs in Edge Cases table."
  - "v1.9: (GATE-58/CLOSED-WORLD) E-CLI-001 phantom code reference removed from Invariant 3 (D-117); invariant now states the behavior without the undefined code cross-reference."
  - v1.6: "WS-4 Shard E: POLICY-5 repair — L2 Capability fabricated quote replaced with verbatim CAP-011 title ('Filter Application')."
  - "v1.4: (INC-MAP) Architecture Module field filled per bc-module-map.md (architect, Phase 1b)"
  - "v1.5: (Task-8) Removed incorrect SS-11 subsystem label from cli.rs (cli.rs is not an SS-11 module); fixed pre-existing Edge Cases table header cell count."
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.11.004: Invalid `--ignore` Glob → Exit 2 Before Scanning Begins

## Description
If a `--ignore` glob pattern fails to compile (rejected by the `globset` crate at startup), the
tool exits immediately with exit code 2 and an error message on stderr. No scanning occurs. This
provides fail-fast feedback for misconfigured CI invocations before spending time on file
traversal.

An invalid glob is one that fails `globset::GlobBuilder::new(pattern).build()`. Examples of
invalid globs: unclosed bracket `[abc`, unescaped special character sequences that globset
rejects, or empty patterns (implementation must define empty-glob behavior).

## Preconditions
1. One or more `--ignore GLOB` flags were provided on the command line.
2. At least one glob pattern fails to compile via `globset`.

## Postconditions
1. Exit code 2 (configuration error).
2. Stderr: `error: invalid --ignore glob '<pattern>': <reason>`.
3. No file traversal occurs.
4. No scanning occurs.
5. Stdout is empty.

## Invariants
1. Glob validation occurs at startup, before any traversal.
2. The error message includes the offending pattern and the reason from globset.
3. Exit code 2 is used for all configuration errors.

## Edge Cases
| EC | Description | Expected |
|----|-------------|---------|
| EC-207 | `--ignore '[abc'` (unclosed bracket) | Exit 2; error on stderr; no scanning |
| EC-208 | `--ignore 'valid/**' --ignore '[bad'` | Exit 2 on first invalid; no scanning |

## Canonical Test Vectors
| Command | Expected |
|---------|---------|
| `mdlinkcheck . --ignore '[unclosed'` | Exit 2; `error: invalid --ignore glob '[unclosed': ...` on stderr |
| `mdlinkcheck . --ignore 'valid/**'` | Normal scan proceeds |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | Invalid glob exits 2 before any traversal | unit test |
| test-sufficient | Error message includes offending pattern | unit test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-011 ("Filter Application") per capabilities.md §CAP-011 |
| Capability Anchor Justification | CAP-011 ("Filter Application") per capabilities.md §CAP-011 — startup validation of --ignore globs is part of filter application setup |
| L2 Domain Invariants | — |
| Brief Requirement | R6, DD-008 |
| Architecture Module | `cli.rs` (effectful shell, LOW tier) primary; `verdict.rs` (SS-14, pure core, CRITICAL tier) secondary — INC-MAP-003: invalid glob exits via `config_error: bool` through `verdict::exit_code`; acceptance test must assert both cli validation error AND exit 2 — ADR-007 |

## Related BCs
- BC-2.11.001 — sibling (valid --ignore glob exclusion)
- BC-2.14.003 — sibling (nonexistent PATH → exit 2 pattern)
