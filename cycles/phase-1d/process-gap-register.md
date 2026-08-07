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

---

## Convergence Strategy Change — 2026-08-05

### Decision

The human has ruled that **manual remediation is not converging** and the fix is to
**automate enforcement and generate derived artifacts** rather than hand-patch
individual files.

### Root Cause

Approximately 600 hand-maintained cross-referenced identifiers exist across
approximately 130 files, with **all 19 policies at `lint_hook: null`** — meaning
no policy has any automated enforcement. Evidence of systemic failure:

- BC counts wrong at least 5 times across the adversarial passes
- PRD §2 titles drifted at least 3 times; a manual pass caught 2 of 14 (86% miss rate)
- Approximately 60 EC-ID collisions discovered in pass 3 (P3-003 CRITICAL)

### Direction

A devops-engineer is building validators and generators under
`/Users/jmagady/Dev/mdlinkcheck-cloud/scripts/spec-lint/`. These tools will:

1. Validate EC-ID injectivity across all BC files
2. Regenerate derived index tables from source documents
3. Enforce PRD§2 title ↔ BC-H1 synchronization
4. Wire `lint_hook` fields in `policies.yaml` to the generated scripts

Future adversarial passes must verify `lint_hook` fields are populated, not just
that policies are codified.

---

### PG-008 — `[filled by ...]` placeholder values in BC files, uncovered by POL-14 and POL-15

| Field | Value |
|-------|-------|
| Origin finding | P3 pass — 73 occurrences of `[filled by ...]` placeholder text across 35 BC files |
| Process gap | POL-14 (`no_vp_tbd_after_phase_1b`) and POL-15 (`no_ss_tbd_after_phase_1b`) catch `VP-TBD` and `SS-TBD` sentinels respectively, but neither policy covers the `[filled by ...]` placeholder pattern. These 73 instances in 35 BC files passed all current gates undetected |
| Policy coverage | None — uncovered gap. Requires a new sentinel lint rule |
| Disposition | **Deferred — automation track** |
| Deferral reason | The `[filled by ...]` pattern is a different sentinel family from VP-TBD/SS-TBD. The fix is to extend the spec-lint validator being built under `scripts/spec-lint/` to grep for this pattern and fail the gate. This is part of the automation-first strategy recorded above. A new POL entry should be added once the lint hook is wired — adding a policy with `lint_hook: null` would repeat the pattern this convergence strategy change is designed to break. |
| Upstream location | `scripts/spec-lint/` (in-progress); vsdd-factory Phase 1b gate (longer term) |

---

### PG-009 — POL-12's verification step encodes `alive` as an external-URL verdict, inverting binding decision D-014

| Field | Value |
|-------|-------|
| Origin finding | P3-028 (adversary-pass-3.md) — `[process-gap]` tagged |
| Process gap | `policies.yaml` POL-12 (`bc_adr_verdict_exit_code_consistency`) was written to enforce ADR/taxonomy consistency. Its own `verification_steps` field encodes `alive` as a valid external-URL verdict. Binding decision D-014 resolves the alive/clean naming question. POL-12's verification procedure therefore contradicts the binding decision it is supposed to protect — a governance rule that inverts a binding decision is actively harmful: it misdirects the adversary and produces false clean-pass results on any D-014-class finding |
| Policy coverage | POL-12 is itself the defective artifact |
| Disposition | **Deferred — automation track** |
| Deferral reason | Correcting POL-12 requires resolving D-014's alive/clean decision unambiguously first (that is a product-owner + architect task on P3-001/P3-002). Once D-014 is resolved and ADR-007 is updated, POL-12's verification steps must be regenerated from the authoritative source. The automation track's validator generation approach (scripts/spec-lint/) should derive policy verification procedures from spec decisions rather than encoding them by hand — this is the root cause that allowed a policy to drift from the decision it encodes. |
| Upstream location | `.factory/policies.yaml` (POL-12 `verification_steps`); `scripts/spec-lint/` for regeneration |

---

## Updated Summary (after pass 3)

| Gap ID | Origin | Gap Description (one sentence) | Policy | Disposition |
|--------|--------|-------------------------------|--------|-------------|
| PG-001 | F-001 | No gate verifies ADR exit codes and reason codes against error-taxonomy.md before ADR acceptance | POL-12 | Deferred — vsdd-factory consistency-validator + ADR gate |
| PG-002 | F-004 | PRD§2↔BC-H1 title drift check exists in the consistency-validator but is not configured as blocking | POL-13 | Deferred — vsdd-factory gate severity config |
| PG-003 | F-007 | No Phase 1b gate check rejects BCs with VP-TBD in Verification Properties | POL-14 | Deferred — vsdd-factory Phase 1b gate script |
| PG-004 | F-008 | No EC-NNN anchor validation; no holdout boundary enforcement gate | POL-16, POL-18 | Deferred — vsdd-factory consistency-validator + holdout gate |
| PG-005 | F-011 | No Phase 1b gate check rejects BCs with SS-TBD frontmatter | POL-15 | Deferred — vsdd-factory Phase 1b gate script |
| PG-006 | F-020 | BC-INDEX derived tables (P0/P1 counts, KD/R labels) are hand-maintained and drift from their sources | POL-17 | Deferred — vsdd-factory consistency-validator + BC-INDEX template |
| PG-007 | F-024 | T-NNN, EC-NNN, R-NNN reference families in BC Traceability sections are not resolved by any validator | POL-16 | Deferred — vsdd-factory consistency-validator ID resolution |
| PG-008 | P3 pass | `[filled by ...]` placeholder text (73 occurrences, 35 BC files) passes all current gates; not covered by POL-14/POL-15 | None yet | Deferred — automation track (scripts/spec-lint/) |
| PG-009 | P3-028 | POL-12's own verification step encodes `alive` as external-URL verdict, inverting binding decision D-014 | POL-12 (defective) | Deferred — automation track; resolve D-014 first |
| PG-010 | data-repair burst 2026-08-07 | A binding decision ID can be cited in spec files while absent from the STATE.md Decisions Log, with no ID-continuity gate detecting the gap | None yet | Deferred — vsdd-factory consistency-validator + STATE.md burst gate |
| PG-011 | CI-062 maintenance burst 2026-08-07 | "Pass 5" named two distinct populations; resolved by ID-space-is-truth ruling at gate #27 | None yet | **RESOLVED** — perimeter sweep = pass 6 (P6-S* IDs); next pass = 7; erratum notes added to shard-1 + shard-6 + synthesis per D-034 spirit (2026-08-07) |
| PG-012 | CI-062 maintenance burst 2026-08-07 | Perimeter sweep shards use inconsistent severity vocabularies; totals are taxonomy-incomparable; hand recount PROHIBITED (D-082); §6 reporting uses severity ranges | None yet | Deferred — confirmed by operator at gate #27 (2026-08-07); pass-5 total disputed (36 vs 37), unadjudicated; §6 will use ranges |

---

### PG-010 — Binding Decision IDs Referenced in Specs While Absent from STATE.md Decisions Log

| Field | Value |
|-------|-------|
| Origin finding | Data-repair burst (2026-08-07) — D-017..D-020 (exhaustive) cited as binding in prd.md changelog, BC-2.11.002.md, and adversary-pass-3.md but absent from the STATE.md Decisions Log at commit `ea3cd2d` and still absent after D-087 compaction at `a70306d` |
| Process gap | A decision can be recorded as binding in spec files (PRD changelog, BC changelogs, adversary findings) while its corresponding STATE.md Decisions Log row is never written or is silently dropped. No gate performs an ID-continuity check over the Decisions Log (e.g., verify D-001..D-NNN has no gaps). The burst-log asserted "D-017..D-025 recorded in STATE.md" — D-021..D-025 were present; D-017..D-020 were not. An adversary finding (P3-001) cited D-018 as a "binding decision" and filed a CRITICAL finding against ADR-007 for contradicting it — yet D-018 had no row in the Decisions Log. |
| Policy coverage | None — no policy currently requires or verifies Decisions Log ID continuity |
| Disposition | **Deferred — factory engine** |
| Deferral reason | The fix requires adding an ID-continuity check to the consistency-validator or STATE.md gate: after each burst, verify that the Decisions Log contains a row for every D-NNN from D-001 to the current maximum, with no gaps. This is a vsdd-factory gate-script change. The immediate repair (D-017..D-020 rows reconstructed from prd.md and cycle artifacts) is recorded in STATE.md with RECONSTRUCTED provenance markers. |
| Detection note | An ID-continuity check over the Decisions Log would have caught this gap immediately: `grep -oP 'D-\d+' STATE.md \| sort -un` showing a jump from D-016 to D-021 is unambiguous evidence of missing rows. |
| Upstream location | vsdd-factory: consistency-validator (Decisions Log ID-continuity check); STATE.md burst gate |

---

**PG-001 through PG-007:** Justified Deferral — vsdd-factory engine changes.
**PG-008 through PG-009:** Deferred — automation track (scripts/spec-lint/ in progress).
**PG-010:** Deferred — vsdd-factory consistency-validator + STATE.md burst gate.
**PG-011:** RESOLVED — operator ruling at gate #27 (2026-08-07). ID-space is truth: perimeter sweep = pass 6; next adversary pass = 7; erratum notes added to affected shard docs per D-034 spirit.
**PG-012:** Deferred — confirmed by operator at gate #27 (2026-08-07). Severity totals taxonomy-incomparable; hand recount PROHIBITED (D-082); §6 reporting uses severity ranges. Pass-5 total disputed (36 vs 37), unadjudicated.
No Phase 2 product stories are created for any gap. All 12 gaps have explicit dispositions.

---

### PG-011 — Pass-Numbering Collision: "Pass 5" Names Two Distinct Finding Populations

| Field | Value |
|-------|-------|
| Origin finding | CI-062 record-integrity maintenance burst (2026-08-07) |
| Process gap | The register contains two distinct finding populations both labelled "Pass 5": (1) A gate #12 adversarial pass with `P5-*` ID prefixes (36 or 37 findings — see COUNT DISPUTE in adversary-pass-5.md); record was never persisted. (2) The perimeter-sweep shard files (perimeter-sweep-shard-1.md through shard-8.md), which TITLE themselves "Pass 5" (example: shard-1.md line 22 `# Adversarial Findings — Phase 1d — Pass 5 — Shard 1 / 8`) but whose finding IDs are prefixed `P6-S<n>-<nnn>` (pass SIX). STATE.md's Phase Progress table records the perimeter sweep as "pass-5 adversary (perimeter sweep — 8 shards) COMPLETE". The claim that "pass 6 has not yet run" sits uneasily with a P6-prefixed corpus of 249 findings already on disk. |
| Consequence | The convergence register is ambiguous about which gate count to use for convergence evaluation. WS-5 pass 6 sequencing may be miscounted. |
| Policy coverage | None |
| Disposition | **RESOLVED — operator ruling at gate #27 (2026-08-07).** Ruling verbatim: "PG-011 pass numbering: adopt ID-space as truth — the perimeter sweep IS pass 6 (matches the P6-S* IDs already on disk); add an erratum note to the shard docs' 'Pass 5' titles rather than rewriting them (D-034 spirit); the lost 36/37-finding record remains pass 5 (P5-*); the NEXT adversary pass after remediation is pass 7. The 0/3 clean-pass counter is unaffected either way — no pass to date was clean, and the streak was always defined to start after perimeter close + remediation per gate #12." Erratum notes added to: `perimeter-sweep-shard-1.md`, `perimeter-sweep-shard-6.md`, `perimeter-sweep-synthesis.md` (D-034 spirit — titles preserved unedited). `convergence-trajectory.md` and `STATE.md` updated to pass-6 semantics. The 0/3 counter is unchanged. |
| Upstream location | STATE.md Phase Progress table; convergence-trajectory.md; adversary-pass-5.md; all 8 perimeter-sweep-shard-*.md files |

---

### PG-012 — Inconsistent Severity Vocabulary Across Perimeter Sweep Shards

| Field | Value |
|-------|-------|
| Origin finding | CI-062 record-integrity maintenance burst (2026-08-07); triggered by Item 3 CRITICAL headline correction |
| Process gap | Severity vocabularies are inconsistent across the 8 perimeter-sweep shards: shard-1 uses CRITICAL/MAJOR/MINOR; shards 2-6 use CRITICAL/HIGH/MEDIUM; shards 4 and 8 also carry LOW. This inconsistency means no single predicate can compute an aggregate CRITICAL count across all shards — naive section-based attribution double-counts cross-referenced IDs (attempted count yielded 63/86/106 = 255 ≠ 249). Only shard-1 provides an internally consistent self-declared severity roster table. The per-shard C-column totals in perimeter-sweep-synthesis.md are the best available oracle and sum to 40 CRITICAL. |
| Consequence | Any aggregate severity statistic in the register (e.g. "40 CRITICAL") is derived from per-shard self-reported C columns, not from an independently verifiable per-finding recount. The true aggregate count is therefore an ESTIMATE that is cross-verified only for the subset of findings with shard-level C-column declarations. |
| Policy coverage | None |
| Disposition | **Deferred — future adversarial pass discipline; confirmed by operator ruling at gate #27 (2026-08-07).** Operator ruling verbatim: "PG-012: correct as logged — carry 36-vs-37 as disputed and severity totals as taxonomy-incomparable; do NOT hand-recount (that would violate D-082); the §6 report will use ranges." Additional ruling clarifications: (1) Severity totals across the 8 perimeter-sweep shards are **taxonomy-incomparable** — shard-1 uses CRITICAL/MAJOR/MINOR; shards 2–8 use CRITICAL/HIGH/MEDIUM; shards 4 and 8 also carry LOW; no predicate can aggregate point totals across these vocabularies. (2) A hand-recount of per-finding severity across all 249 findings is **PROHIBITED** as a D-082 violation (D-082: quantitative claims must come from an executed predicate, not reading-and-counting). (3) Downstream §6 convergence reporting MUST express severity as **ranges** rather than point totals. (4) The pass-5 total (P5-* population) remains **disputed (36 vs 37)** — unadjudicated by this ruling. Future adversarial passes MUST specify a SINGLE severity vocabulary in the dispatch instruction. |
| Upstream location | cycles/phase-1d/perimeter-sweep-shard-*.md (8 files); perimeter-sweep-synthesis.md |
