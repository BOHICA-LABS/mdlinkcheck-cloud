---
document_type: process-gap-register
level: ops
version: "1.0"
status: active
producer: spec-steward
timestamp: "2026-08-05T00:00:00Z"
phase: phase-1d
inputs:
  - .factory/cycles/phase-1d/adversary-pass-1.md
  - .factory/cycles/phase-1d/consistency-audit-phase-1.md
input-hash: "38b7304"
traces_to: .factory/STATE.md
---

# Process Gap Register — Phase 1d

## Purpose

This register captures all 7 `[process-gap]` annotations found in the Phase 1d
adversarial review (`adversary-pass-1.md`, findings F-001, F-004, F-007, F-008,
F-011, F-020, F-024). Per the S-7.02 cycle-closing checklist, the phase-1d
convergence loop cannot be declared CONVERGED until every process-gap finding has
either:

- **(a) A follow-up story** to be created in Phase 2 against a self-improvement epic, or
- **(b) A justified deferral** with a documented reason.

## Critical Distinction: Factory Engine vs. Product

Every process gap in this register is a deficiency in the **factory engine** — the
agent prompts, templates, gate tooling, and consistency validators maintained in the
vsdd-factory repository (`/Users/jmagady/Dev/vsdd-factory/plugins/vsdd-factory/`).
None of these gaps are deficiencies in the `mdlinkcheck` product source code or
its spec content (those are tracked as INC-NNN and F-NNN findings, not process gaps).

Because these fixes belong to the upstream vsdd-factory repository, this product
cannot author engine stories unilaterally. Phase 2 story decomposition for
`mdlinkcheck` concerns the product's behavioral contracts, not factory tooling.
The appropriate action for each gap is therefore a **justified deferral** flagging the
gap for the factory's own backlog, with the policy codified in `.factory/policies.yaml`
to ensure the adversary enforces the intent manually until automation is added.

---

## Gap Register

### PG-001 — BC↔ADR Verdict and Exit-Code Consistency (F-001)

| Field | Value |
|-------|-------|
| Origin finding | F-001 (adversary-pass-1.md) |
| Process gap | No check verifies that an accepted ADR's exit codes and reason codes are consistent with error-taxonomy.md and frozen brief R7 before the ADR reaches `status: accepted` |
| Policy coverage | POL-12 (`bc_adr_verdict_exit_code_consistency`) in `.factory/policies.yaml` |
| Disposition | **Deferred — factory engine** |
| Deferral reason | The fix requires adding a cross-reference lint step to the consistency-validator (vsdd-factory) that extracts exit-code and reason-code claims from ADR text and verifies them against error-taxonomy.md. This is a vsdd-factory agent-prompt and gate-script change, not a product story. Manual enforcement is codified in POL-12 `verification_steps` so the adversary checks this in future passes. |
| Upstream location | vsdd-factory: consistency-validator agent prompt; Phase 1b ADR acceptance gate script |

---

### PG-002 — PRD §2 Title ↔ BC H1 Sync Not Automated (F-004)

| Field | Value |
|-------|-------|
| Origin finding | F-004 (adversary-pass-1.md) |
| Process gap | The consistency-validator detects PRD §2 title drift but the gate treated it as advisory rather than blocking. PRD v1.1 SF-002 fixed 2 of 14 drifted titles and the remaining 12 survived a full revision cycle — the single most dangerous class of defect found: a drifted title causes a story-writer to implement the wrong feature |
| Policy coverage | POL-13 (`prd_section_title_bc_h1_sync`) in `.factory/policies.yaml` |
| Disposition | **Deferred — factory engine** |
| Deferral reason | The consistency-validator already has the detection logic. The fix is to promote the PRD§2↔BC-H1 check from WARN to BLOCKING in the Phase 1b gate configuration in vsdd-factory. This is a gate severity configuration change in the factory, not a product story. POL-13 ensures the adversary treats this as a blocking finding in all future passes. |
| Upstream location | vsdd-factory: consistency-validator gate severity config; Phase 1b exit gate |

---

### PG-003 — No Gate Rejects VP-TBD After Phase 1b (F-007)

| Field | Value |
|-------|-------|
| Origin finding | F-007 (adversary-pass-1.md) |
| Process gap | The Phase 1b exit gate has no check that rejects a BC file containing `VP-TBD` in its Verification Properties section. All 59 BC files had 99 VP-TBD occurrences when Phase 1b was declared complete |
| Policy coverage | POL-14 (`no_vp_tbd_after_phase_1b`) in `.factory/policies.yaml` |
| Disposition | **Deferred — factory engine** |
| Deferral reason | The fix is a one-line grep added to the Phase 1b exit gate script in vsdd-factory: `grep -r 'VP-TBD' .factory/specs/behavioral-contracts/` must return zero results. This is a vsdd-factory gate-script change. POL-14 ensures the adversary enforces this manually until the gate script is updated. |
| Upstream location | vsdd-factory: Phase 1b exit gate script |

---

### PG-004 — No EC-NNN Anchor Validation; No Holdout Boundary Enforcement (F-008)

| Field | Value |
|-------|-------|
| Origin finding | F-008 (adversary-pass-1.md) |
| Process gap | Two sub-gaps: (a) nothing validates that a BC's cited EC-NNN IDs exist in the canonical test-vectors.md list and mean the same scenario as the BC claims; (b) nothing enforces the holdout boundary — no tool prevents holdout EC IDs from being fully specified in visible BC files |
| Policy coverage | POL-16 (`bc_traceability_id_resolution`) for sub-gap (a); POL-18 (`holdout_boundary_enforcement`) for sub-gap (b) |
| Disposition | **Deferred — factory engine** |
| Deferral reason | Sub-gap (a): EC-NNN resolution requires extending the consistency-validator to check the EC ID family against test-vectors.md, including semantic matching not just existence. This is a vsdd-factory consistency-validator change. Sub-gap (b): holdout boundary enforcement requires adding a holdout-boundary check to the Phase 1b gate script that greps visible artifacts for reserved EC IDs and verifies no full scenario specification exists. Both are vsdd-factory changes. POL-16 and POL-18 codify manual enforcement until automation is added. Note: the holdout contamination found (6 of 10 reserved ECs exposed in visible BCs) must be resolved by the product-owner before Phase 2 begins — that is an INC-finding remediation tracked separately, not a process-gap story. |
| Upstream location | vsdd-factory: consistency-validator (EC-NNN resolution); Phase 1b gate script (holdout boundary grep) |

---

### PG-005 — No Gate Rejects SS-TBD After Phase 1b (F-011)

| Field | Value |
|-------|-------|
| Origin finding | F-011 (adversary-pass-1.md) |
| Process gap | The Phase 1b exit gate has no check that rejects a BC file with `subsystem: "SS-TBD"` in its frontmatter. All 12 BCs in SS-11..SS-14 — the exit-code and output-format contracts, all P0 — still carried SS-TBD when Phase 1b was declared complete |
| Policy coverage | POL-15 (`no_ss_tbd_after_phase_1b`) in `.factory/policies.yaml` |
| Disposition | **Deferred — factory engine** |
| Deferral reason | The fix is a one-line grep added to the Phase 1b exit gate script in vsdd-factory: `grep -r 'subsystem: "SS-TBD"'` across BC frontmatter must return zero results. This is a vsdd-factory gate-script change. POL-15 ensures the adversary enforces this manually until the gate script is updated. |
| Upstream location | vsdd-factory: Phase 1b exit gate script |

---

### PG-006 — No Cross-Validation of BC-INDEX Derived Tables (F-020)

| Field | Value |
|-------|-------|
| Origin finding | F-020 (adversary-pass-1.md) |
| Process gap | Nothing cross-validates BC-INDEX's summary statistics, KD labels, R labels, and priority columns against their source documents (prd.md, BRIEF.md, domain-spec/invariants.md, VP-INDEX.md). These are derived tables that drifted because they are hand-maintained rather than regenerated |
| Policy coverage | POL-17 (`derived_tables_must_be_regenerated`) in `.factory/policies.yaml` |
| Disposition | **Deferred — factory engine** |
| Deferral reason | The long-term fix is to make BC-INDEX's derived sections templated outputs regenerated by the consistency-validator from source documents, not hand-authored text. Intermediate fix: add a derived-table validation step to the consistency-validator that counts BC rows and cross-checks KD/R/DI sections against their authoritative sources. Both are vsdd-factory changes. POL-17 ensures the adversary checks these counts manually in every future pass. |
| Upstream location | vsdd-factory: consistency-validator; BC-INDEX template |

---

### PG-007 — BC Traceability ID Families Not Validated (F-024)

| Field | Value |
|-------|-------|
| Origin finding | F-024 (adversary-pass-1.md) |
| Process gap | The consistency-validator resolves CAP/DI/ADR/NFR ID references but does not resolve the EC-NNN, T-NNN, R-NNN, DD-NNN, AMB-NNN, or FM-NNN reference families cited in BC Traceability sections. In the Phase 1 adversarial review, 100% of sampled T-number citations were wrong, 11 EC-NNN citations collided with unrelated canonical entries, and the R-number family was systematically relabelled — all three families wrong across the same set of files, which meets the 3+-recurrence bar for a process gap |
| Policy coverage | POL-16 (`bc_traceability_id_resolution`) in `.factory/policies.yaml` (shared with PG-004 sub-gap a) |
| Disposition | **Deferred — factory engine** |
| Deferral reason | The fix requires extending the consistency-validator to resolve the T/EC/R/DD/AMB/FM ID families in addition to the CAP/DI/ADR/NFR families it already checks. This includes semantic matching (does the BC's description of T-8 match what T-8 actually is in test-vectors.md?) not just existence checking. This is a non-trivial consistency-validator extension in vsdd-factory. POL-16 codifies the manual verification procedure for the adversary until the validator is extended. |
| Upstream location | vsdd-factory: consistency-validator ID resolution logic |

---

## Summary

| Gap ID | Origin | Gap Description (one sentence) | Policy | Disposition |
|--------|--------|-------------------------------|--------|-------------|
| PG-001 | F-001 | No gate verifies ADR exit codes and reason codes against error-taxonomy.md before ADR acceptance | POL-12 | Deferred — vsdd-factory consistency-validator + ADR gate |
| PG-002 | F-004 | PRD§2↔BC-H1 title drift check exists in the consistency-validator but is not configured as blocking | POL-13 | Deferred — vsdd-factory gate severity config |
| PG-003 | F-007 | No Phase 1b gate check rejects BCs with VP-TBD in Verification Properties | POL-14 | Deferred — vsdd-factory Phase 1b gate script |
| PG-004 | F-008 | No EC-NNN anchor validation; no holdout boundary enforcement gate | POL-16, POL-18 | Deferred — vsdd-factory consistency-validator + holdout gate |
| PG-005 | F-011 | No Phase 1b gate check rejects BCs with SS-TBD frontmatter | POL-15 | Deferred — vsdd-factory Phase 1b gate script |
| PG-006 | F-020 | BC-INDEX derived tables (P0/P1 counts, KD/R labels) are hand-maintained and drift from their sources | POL-17 | Deferred — vsdd-factory consistency-validator + BC-INDEX template |
| PG-007 | F-024 | T-NNN, EC-NNN, R-NNN reference families in BC Traceability sections are not resolved by any validator | POL-16 | Deferred — vsdd-factory consistency-validator ID resolution |

**All 7 dispositions: Justified Deferral.** No Phase 2 product stories are created for these gaps. All require changes to the vsdd-factory engine repository. Each gap is covered by a policy in `.factory/policies.yaml` that encodes the check procedure for the adversary, ensuring manual enforcement until automation is added upstream.

---

## Convergence Gate Status

Per S-7.02: all 7 process-gap findings have an explicit disposition. The phase-1d
convergence loop may proceed to gate evaluation on this dimension.

The deferred factory-engine improvements should be filed in the vsdd-factory backlog
with references to this register (finding IDs F-001, F-004, F-007, F-008, F-011,
F-020, F-024) and the corresponding policy IDs (POL-12 through POL-19).
