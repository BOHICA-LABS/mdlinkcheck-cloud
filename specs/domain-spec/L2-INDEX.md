---
document_type: domain-spec-index
level: L2
version: "1.9"
status: draft
producer: business-analyst
timestamp: 2026-08-05T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/planning/brief-validation.md
  - .factory/planning/market-intelligence.md
input-hash: "20e96e1"
traces_to: .factory/specs/product-brief.md
changelog:
  - version: "1.9"
    date: 2026-08-06
    change: "D-043 (macOS-only platform directive): ASM-004 updated (macOS-only, Linux/Windows removed); shard versions bumped: assumptions.md 1.1→1.2, decisions.md 1.7→1.8, failure-modes.md 1.5→1.6, edge-cases.md 1.4→1.5. DD-002 canonical D-006 rationale updated to determinism grounds. DD-020 NFR-002 reference updated to macOS CI runner. FM-006/FM-007 platform framing updated. DEC-004/DEC-009 platform prose narrowed to macOS."
  - version: "1.8"
    date: 2026-08-06
    change: "P3-010 governance gap closure (DD-027): ID Registry DI-NNN count 11→13 (added DI-012, DI-013), DD-NNN count 26→27 (added DD-027). Document Map invariants.md row updated to DI-001–DI-013. Domain Decisions row updated to DD-001–DD-027. Brief→Domain Coverage R2b row updated to include DI-012, DI-013. Human Decisions table extended with DD-027. Shard versions bumped: invariants.md 1.4→1.5, failure-modes.md 1.3→1.4, capabilities.md 1.4→1.5, decisions.md 1.6→1.7."
  - version: "1.7"
    date: 2026-08-06
    change: "Mechanical spec remediation: shard versions bumped — edge-cases.md 1.3→1.4, failure-modes.md 1.2→1.3, decisions.md 1.5→1.6. Fixes: (1) DEC-006 retired-holdout and mis-cited active-holdout source references removed — BV-013 only; (2) FM-001/002/003 Invariant Violated corrected from DI-001 (ordering — wrong) to no-governing-DI annotation with DD-015 normative reference; (3) FM-004 retired-holdout corpus fixture citation removed; (4) DD-017 erroneous still-active holdout citation removed from Decision text and Resolves; (5) DD-007/009/010 active holdout IDs in Resolves column replaced with risk-class descriptions per DD-026. check-id-resolution and check-holdout-boundary both at 0."
  - version: "1.6"
    date: 2026-08-05
    change: "Pass-2 adversarial remediation: ID Registry DD-NNN count updated 22→26; Domain Decisions row updated to DD-001–DD-026; Human Decisions table extended with DD-023–DD-026. Shard versions bumped: capabilities.md 1.3→1.4, invariants.md 1.3→1.4, edge-cases.md 1.2→1.3, failure-modes.md 1.1→1.2, decisions.md 1.4→1.5. Changes: CAP-008 directory+fragment discriminator, CAP-011 --allow fallback, CAP-013 JSON object envelope, CAP-014 three-input exit code, DI-001 falsifiable, DI-002 concrete example removed, DI-006 Pass 1.5 missing-target rule, DI-009 non-canonicalize dedup key, http-error/http-indeterminate 400-after-GET reclassification, DEC-001/003/009 holdout burn + concrete detail restored."
  - version: "1.5"
    date: 2026-08-05
    change: "Orchestrator ruling DD-022: ID Registry DD-NNN count updated 21→22; Domain Decisions row updated to DD-001–DD-022; Human Decisions table extended with DD-022; shard versions bumped: edge-cases.md 1.1→1.2, invariants.md 1.2→1.3, entities.md 1.1→1.2, capabilities.md 1.2→1.3, decisions.md 1.3→1.4, events.md 1.0→1.1. POL-18 holdout leak remediation for DEC-001/EC-049, DEC-003/EC-074, DEC-009/EC-036 recorded."
  - version: "1.4"
    date: 2026-08-05
    change: "Orchestrator ruling DD-021: ID Registry DD-NNN count updated 20→21; Domain Decisions row updated to DD-001–DD-021; assumptions.md and decisions.md section shards bumped (1.0→1.1 and 1.2→1.3 respectively)."
  - version: "1.3"
    date: 2026-08-05
    change: "Phase 1d gate remediation: ID Registry counts updated (R-NNN: 7→9, DD-NNN: 16→20); Human Decisions table extended with DD-017 through DD-020 (D-010 holdout, D-011 dropped flags, D-012 extension scope, D-013 performance model). All section shards bumped to match."
  - version: "1.2"
    date: 2026-08-05
    change: "Phase 1d F-005 remediation: DD-008 cross-reference in Human Decisions table updated to reflect widening to all source-exclusion mechanisms"
  - version: "1.1"
    date: 2026-08-05
    change: "Added decisions.md to section list"
  - version: "1.0"
    date: 2026-08-05
    change: "Initial draft"
sections:
  - capabilities.md
  - entities.md
  - invariants.md
  - events.md
  - edge-cases.md
  - assumptions.md
  - risks.md
  - failure-modes.md
  - differentiators.md
  - event-flow.md
  - decisions.md
---

# L2 Domain Specification: mdlinkcheck

> **Sharded artifact (DF-021).** This index provides navigation and summary.
> Detail lives in per-section files listed below. Each section targets
> 800-1,200 tokens for optimal LLM consumption.

## Domain Summary

`mdlinkcheck` is a CLI tool that checks every link in a set of Markdown files, classifying
each as clean, broken, or indeterminate, and exiting nonzero only on definitive breakage.
The domain is link *verification* — not repair, rendering, or publication — with a hard
constraint against false positives that undermine CI trust.

## Pilot Note

`mdlinkcheck` is a **factory pilot** on a deliberately well-understood problem shape.
Differentiation against lychee and other incumbents is explicitly out of scope (ASM-003).
The product's purpose is to exercise the VSDD factory pipeline on a bounded,
correctness-intensive domain.

## Document Map

| Section | File | Primary Consumer | Purpose |
|---------|------|-----------------|---------|
| Domain Capabilities | `capabilities.md` | product-owner, architect, story-writer | CAP-001–CAP-014 capability catalog |
| Domain Entities | `entities.md` | architect, product-owner | Ubiquitous language + entity model |
| Domain Invariants | `invariants.md` | product-owner, architect | DI-001–DI-013 business rules |
| Processing Stages | `events.md` | architect | Scan pipeline stage definitions |
| Edge Cases | `edge-cases.md` | story-writer, test-writer | DEC-001–DEC-009 domain-level edge cases |
| Assumptions | `assumptions.md` | product-owner, test-writer | ASM-001–ASM-010 with validation methods |
| Risks | `risks.md` | product-owner, architect | R-001–R-007 risk register |
| Failure Modes | `failure-modes.md` | architect, test-writer | FM-001–FM-010 runtime failure catalog |
| Differentiators | `differentiators.md` | product-owner | Competitive differentiator → CAP mapping |
| Event Flow | `event-flow.md` | (human reference) | End-to-end scan lifecycle state transitions |
| Domain Decisions | `decisions.md` | product-owner, all | DD-001–DD-027 resolved AMB-* and governance register |

## Cross-References

| If you need... | Read these together |
|----------------|-------------------|
| BC creation input | `capabilities.md` + `invariants.md` + `edge-cases.md` + `assumptions.md` + `risks.md` + `decisions.md` |
| Architecture design input | `capabilities.md` + `entities.md` + `invariants.md` + `events.md` + `risks.md` + `failure-modes.md` |
| Story decomposition input | `capabilities.md` + `edge-cases.md` + `decisions.md` |
| Holdout scenario generation | `assumptions.md` + `risks.md` + `failure-modes.md` + `edge-cases.md` |
| NFR derivation | `risks.md` + `failure-modes.md` + `invariants.md` |
| Full domain review | ALL sections |

### Brief → Domain Coverage

| Brief Requirement | Capabilities | Invariants |
|---|---|---|
| R1 (discovery) | CAP-001 | DI-009 |
| R2a (relative file links) | CAP-007 | DI-002, DI-003 |
| R2b (heading anchors) | CAP-005, CAP-006, CAP-008 | DI-003, DI-007, DI-008, DI-012, DI-013 |
| R2c (external URLs) | CAP-009, CAP-010 | DI-005, DI-010 |
| R3 (reference links/images) | CAP-003 | DI-004 |
| R4 (code context exclusion) | CAP-004 | DI-004 |
| R5 (filtering) | CAP-011 | DI-006 |
| R6 (output) | CAP-012, CAP-013 | DI-001, DI-009 |
| R7 (exit codes) | CAP-014 | DI-005, DI-010, DI-011 |
| R8 (performance) | — | DI-009 (determinism) |

### Human Decisions → Domain Invariants

| Decision | Invariant(s) |
|---|---|
| D-006 (case-sensitive NFC) | DI-002 |
| D-007 (HTML anchor narrow carve-out) | DI-007 |
| D-008 (three-outcome verdicts) | DI-005, DI-010 |
| D-009 (corpus + no inline suppression) | ASM-006, ASM-007 |
| DD-012 (output ordering) | DI-001 |
| DD-007 (exit code precedence) | DI-011 |
| DD-008 (all source-exclusion mechanisms are source-only; widened Phase 1d) | DI-006 |
| DD-018 (D-011: dropped flags; unconditional dot-directory skip) | DI-006 (item 3 corrected) |
| DD-019 (D-012: `.md` only, case-sensitive extension) | — (capability-level; no DI) |
| DD-017 (D-010: BRIEF.md holdout vector de-designated) | — (holdout policy; no DI) |
| DD-020 (D-013: two-tier performance model) | — (NFR-level; no DI) |
| DD-021 (orchestrator: holdout de-designation ASM-005/ASM-008; governing holdout policy) | — (holdout governance; no DI) |
| DD-022 (orchestrator: two-layer verdict model — link verdict vs. URL liveness outcome; `alive` is NOT a fourth verdict) | DI-005 |
| DD-023 (D-017: JSON object envelope `{schema_version, results[], errors[]}` is the authoritative R6 interpretation) | — (CAP-013 only) |
| DD-024 (D-018: HTTP 400 after GET fallback is `indeterminate`, not `broken`) | — (CAP-010, failure-modes.md) |
| DD-025 (D-019: `--allow` WHATWG-normalize-then-prefix-match with raw-string fallback at component boundary) | — (CAP-011 only) |
| DD-026 (D-020: EC-036/049/074/157/158 holdout burn; standing no-concrete-detail rule for newly designated holdouts) | — (edge-cases.md governance) |
| DD-027 (business-analyst governance: two-invariant model for CAP-006 — DI-012 slug computation fidelity + DI-013 anchor-key uniqueness; closes P3-010 governance gap) | DI-012, DI-013 |

## ID Registry Summary

| ID Format | Count | Section |
|-----------|-------|---------|
| CAP-NNN | 14 (CAP-001–CAP-014) | `capabilities.md` |
| DI-NNN | 13 (DI-001–DI-013) | `invariants.md` |
| DEC-NNN | 9 (DEC-001–DEC-009) | `edge-cases.md` |
| ASM-NNN | 10 (ASM-001–ASM-010) | `assumptions.md` |
| R-NNN | 9 (R-001–R-009) | `risks.md` |
| FM-NNN | 10 (FM-001–FM-010) | `failure-modes.md` |
| DD-NNN | 27 (DD-001–DD-027) | `decisions.md` |

## Priority Distribution

| Priority | Count | Capabilities |
|----------|-------|-------------|
| P0 (must-have) | 10 | CAP-001, CAP-002, CAP-003, CAP-004, CAP-005, CAP-006, CAP-007, CAP-008, CAP-012, CAP-014 |
| P1 (should-have) | 4 | CAP-009, CAP-010, CAP-011, CAP-013 |
| P2 (nice-to-have) | 0 | — |
