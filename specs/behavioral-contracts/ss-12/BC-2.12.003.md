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
introduced: v1.0.0
modified:
  - v1.6: "WS-4 Shard E: POLICY-5 repair — L2 Capability fabricated quote replaced with verbatim CAP-012 title ('Text Report Generation')."
  - v1.3: "D-011 — --quiet is an explicit non-goal (dropped flag). Removed title qualifier 'Unless --quiet', PC2/PC4, EC-133, and --quiet test vector. Summary is ALWAYS emitted. Retitled from 'Stderr Summary Line (Unless --quiet)'."
  - "v1.4: (INC-MAP) Architecture Module field added per bc-module-map.md (architect, Phase 1b)"
  - "v1.5: (P4-023) Architecture Module secondary note corrected: format_text → format_summary for the stderr summary line function."
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.12.003: Stderr Summary Line (Always Emitted)

## Description
After all findings are emitted to stdout, a summary line is unconditionally written to stderr.
The summary reads: `N broken link(s) in M file(s).` when broken links exist, or `No broken
links found.` when zero broken links. There is no flag to suppress this output — `--quiet` is
an explicit non-goal (D-011). Indeterminate findings do NOT count toward N.

## Preconditions
1. All scanning and reporting is complete.

## Postconditions
1. If N (broken count) > 0: stderr: `N broken link(s) in M file(s).`
   - N = count of broken-verdict findings.
   - M = count of distinct files containing at least one broken finding.
2. If N == 0: stderr: `No broken links found.`
3. Indeterminate findings are NOT counted in N.

## Invariants
1. The summary line is ALWAYS written to stderr, never stdout.
2. `No broken links found.` is printed even if there are indeterminate findings.
3. The summary is the LAST thing written to stderr.
4. No flag suppresses the summary line (D-011: `--quiet` is a non-goal).

## Edge Cases
| EC | Description |
|----|-------------|
| EC-130 | 3 broken links in 2 files |
| EC-131 | 0 broken, 2 indeterminate |
| EC-132 | 0 broken, 0 indeterminate |

## Canonical Test Vectors
| Scenario | Expected stderr |
|----------|----------------|
| 3 broken links in 2 files | "3 broken link(s) in 2 file(s)." |
| 0 broken, 0 indeterminate | "No broken links found." |
| 0 broken, 2 indeterminate | "No broken links found." |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | Summary on stderr, findings on stdout | integration test (separate streams) |
| test-sufficient | Summary always emitted (no suppression flag) | integration test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-012 ("Text Report Generation") per capabilities.md §CAP-012 |
| Capability Anchor Justification | CAP-012 ("Text Report Generation") per capabilities.md §CAP-012 |
| Brief Requirement | R6, R7, AMB-091 |
| Architecture Module | `reporter.rs` (SS-12, pure core, HIGH tier) primary; `main.rs` (LOW tier) secondary — routes summary string to stderr; `reporter::format_summary` produces it — ADR-005 |

## Related BCs
- BC-2.12.001 — sibling (text format: per-finding line on stdout)
- BC-2.12.005 — sibling (stdout vs stderr separation — NEW)
