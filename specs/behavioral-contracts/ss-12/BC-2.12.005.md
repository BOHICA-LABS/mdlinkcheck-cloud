---
document_type: behavioral-contract
level: L3
version: "1.7"
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
introduced: v1.3.0
modified:
  - "v1.6: EC-NEW-12 and EC-NEW-13 allocated as EC-209 and EC-210; placeholders replaced with real IDs in Edge Cases table. input-hash corrected to 07d983a (was c3e82ce, hash drift)."
  - "v1.4: (INC-MAP) Architecture Module field added per bc-module-map.md (architect, Phase 1b)"
  - "v1.5: (P4-023) Architecture Module note updated to name format_summary() separately; fixed pre-existing Edge Cases table header cell count."
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.12.005: Stdout/Stderr Separation for Text Format

## Description
In text output format, findings (broken and indeterminate link lines) are written exclusively
to stdout. The summary line (`N broken link(s)...`) is written exclusively to stderr. Progress
indicators (if any) are written to stderr. No finding content appears on stderr; no summary or
progress content appears on stdout. This clean separation makes mdlinkcheck composable with
standard Unix pipeline tools: `grep`, `wc -l`, and `| tee` work on stdout without stderr
contamination.

## Preconditions
1. Text output format is active (default; not `--json`).
2. Scanning has completed and results are ready for output.

## Postconditions
1. Every broken-link finding line is written to stdout only.
2. Every indeterminate finding line is written to stdout only.
3. The summary line (`N broken link(s) in M file(s).` or `No broken links found.`) is written
   to stderr only (see BC-2.12.003).
4. stdout is empty when there are no broken or indeterminate findings.
5. stderr contains only the summary line (and any error messages from configuration failures).

## Invariants
1. `findings → stdout`, `summary → stderr`. These streams never cross.
2. Exit code is determined by broken-link count, not by stream content.
3. A caller can redirect `2>/dev/null` to get findings-only stdout, or `>/dev/null` to get
   only the summary on stderr.

## Edge Cases
| EC | Description | Expected |
|----|-------------|---------|
| EC-209 | 0 broken, 0 indeterminate | stdout empty; stderr: "No broken links found." |
| EC-210 | 2 broken findings | stdout: 2 finding lines; stderr: "2 broken link(s) in 1 file(s)." |

## Canonical Test Vectors
| Scenario | stdout | stderr |
|----------|--------|--------|
| 2 broken links in 1 file | 2 finding lines | "2 broken link(s) in 1 file(s)." |
| 0 findings | (empty) | "No broken links found." |
| 1 indeterminate, 0 broken | 1 indeterminate line | "No broken links found." |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | No finding lines on stderr | integration test (capture stderr; assert no finding-line pattern) |
| test-sufficient | Summary never appears on stdout | integration test (capture stdout; assert no summary pattern) |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-012 ("Text Report Generation") per capabilities.md §CAP-012 |
| Capability Anchor Justification | CAP-012 ("Text Report Generation") per capabilities.md §CAP-012 — stdout/stderr separation is a core output contract of the text reporter |
| L2 Domain Invariants | — |
| Brief Requirement | R6, R7 |
| Architecture Module | `reporter.rs` (SS-12, pure core, HIGH tier) primary; `main.rs` (LOW tier) secondary — `reporter::format_text` produces finding lines (stdout); `reporter::format_summary` produces summary line (stderr) — ADR-005 |

## Related BCs
- BC-2.12.001 — composes with (per-finding line format on stdout)
- BC-2.12.003 — composes with (summary on stderr)
