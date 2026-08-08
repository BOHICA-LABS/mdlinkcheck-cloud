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
subsystem: "SS-12"
capability: "CAP-012"
lifecycle_status: active
introduced: v1.0.0
modified:
  - v1.3: "WS-4 Shard E: POLICY-5 repair — L2 Capability fabricated quote replaced with verbatim CAP-012 title ('Text Report Generation')."
  - "v1.1: (INC-MAP) Architecture Module field added per bc-module-map.md (architect, Phase 1b)"
  - "v1.2: (Task-8) Removed incorrect SS-11 subsystem label from cli.rs secondary module reference; corrected 'effectful' to 'effectful shell'."
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.12.002: Terminal Color Output with NO_COLOR / CLICOLOR / CLICOLOR_FORCE

## Description
Color is applied to text output only when: stdout is a TTY AND NO_COLOR is not set AND CLICOLOR
is not "0". CLICOLOR_FORCE=1 forces color even on non-TTY stdout. Color codes: broken findings
in red, indeterminate findings in yellow, file path in bold.

## Preconditions
1. Output format is `text`.
2. At least one finding exists.

## Postconditions
1. If stdout is TTY AND NO_COLOR not set AND CLICOLOR != "0": ANSI color codes applied.
2. If stdout is non-TTY (piped/redirected): no color codes (unless CLICOLOR_FORCE=1).
3. If NO_COLOR is set to any value: no color codes.
4. If CLICOLOR=0: no color codes.
5. If CLICOLOR_FORCE=1: color codes applied regardless of TTY status.

## Invariants
1. Color is purely cosmetic — the same findings are reported with or without color; only ANSI escape codes differ.
2. `--format json` never includes color codes in output.
3. stderr diagnostic messages may also use color under the same rules.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-126 | Piped stdout without CLICOLOR_FORCE |
| EC-127 | NO_COLOR=1 set |
| EC-128 | CLICOLOR_FORCE=1 |

## Canonical Test Vectors
| Env | stdout | Expected |
|-----|--------|---------|
| NO_COLOR=1 | TTY | No ANSI codes |
| (no env vars) | piped | No ANSI codes |
| CLICOLOR_FORCE=1 | piped | ANSI codes present |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | NO_COLOR suppresses ANSI codes | integration test |
| test-sufficient | Piped output has no ANSI codes by default | integration test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-012 ("Text Report Generation") per capabilities.md §CAP-012 |
| Capability Anchor Justification | CAP-012 ("Text Report Generation") per capabilities.md §CAP-012 |
| Brief Requirement | R6, AMB-130 |
| Architecture Module | `reporter.rs` (SS-12, pure core, HIGH tier) primary; `cli.rs` (effectful shell, LOW tier) secondary — NO_COLOR / CLICOLOR env vars read by cli to produce CliArgs; reporter uses the flag — ADR-005 |
