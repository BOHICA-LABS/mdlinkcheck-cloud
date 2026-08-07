---
document_type: convergence-trajectory
level: ops
version: "1.1"
status: in-progress
producer: state-manager
timestamp: 2026-08-07T00:00:00Z
cycle: phase-1d
inputs:
  - .factory/cycles/phase-1d/adversary-pass-1.md
  - .factory/cycles/phase-1d/adversary-pass-2.md
  - .factory/cycles/phase-1d/adversary-pass-3.md
  - .factory/cycles/phase-1d/adversary-pass-4.md
  - .factory/cycles/phase-1d/adversary-pass-5.md
  - .factory/cycles/phase-1d/perimeter-sweep-synthesis.md
  - .factory/cycles/phase-1d/perimeter-sweep-shard-1.md
  - .factory/cycles/phase-1d/perimeter-sweep-shard-2.md
  - .factory/cycles/phase-1d/perimeter-sweep-shard-3.md
  - .factory/cycles/phase-1d/perimeter-sweep-shard-4.md
  - .factory/cycles/phase-1d/perimeter-sweep-shard-5.md
  - .factory/cycles/phase-1d/perimeter-sweep-shard-6.md
  - .factory/cycles/phase-1d/perimeter-sweep-shard-7.md
  - .factory/cycles/phase-1d/perimeter-sweep-shard-8.md
input-hash: "[live-state]"
traces_to: STATE.md
---

# Convergence Trajectory — phase-1d

## Finding Progression

| Pass | Date | Total | CRIT | HIGH | MED | LOW | Novelty | Score | Counter | Verdict |
|------|------|-------|------|------|-----|-----|---------|-------|---------|---------|
| 1 | 2026-08-05 | 32 | 6 | 21 | 5 | 0 | HIGH | — | 0/3 | FINDINGS_REMAIN — REMEDIATED |
| 2 | 2026-08-05 | 34 | 7 | 19 | 8 | 0 | HIGH | — | 0/3 | FINDINGS_REMAIN (REGRESSION: novelty increased) — REMEDIATED |
| 3 | 2026-08-06 | 39 | 5 | 26 | 8 | 0 | HIGH | — | 0/3 | FINDINGS_REMAIN (REGRESSION: novelty increased) — REMEDIATED (mechanical enforcement) |
| 4 | 2026-08-06 | 37 | 3 | 19 | 15 | 0 | ZERO in enforced classes | — | 0/3 | FINDINGS_REMAIN — composition changed; root cause = SPEC-TOPOLOGY (BI-012) |
| 5 (gate #12; P5-* IDs) | 2026-08-07 | **36 or 37 — DISPUTED** [^pass5-count] | unrecorded | unrecorded | unrecorded | unrecorded | unknown | — | 0/3 | FINDINGS_REMAIN — original report NEVER PERSISTED; 10 of 36/37 findings recoverable (see adversary-pass-5.md); 26 UNRECOVERABLE. Also see PG-011 (pass-numbering collision). |
| 6 — perimeter sweep (8 shards; P6-S* IDs; **pass 6 per gate #27 / PG-011**) [^pg011-ruling] | 2026-08-07 | **249 (executed)** [^sweep-count] | 40 [^crit-40] | ~127 | ~92 | — | HIGH | — | 0/3 | FINDINGS_REMAIN — perimeter closed (all 66 BC bodies, all 8 ADRs, all spec shards read); 4 unguarded axes confirmed (BI-024); skip-list unsound (BI-023) |

[^pass5-count]: SESSION-HANDOFF.md §D-057 (lines 562, 576) cites 36. burst-log.md D-086 re-derivation (line 866) states `"36 pass-5 actionable"→37` (executed-predicate correction). Both figures preserved; neither adopted as authoritative. Operator adjudication required (see PG-011).

[^pg011-ruling]: **PG-011 RESOLVED by operator ruling at gate #27 (2026-08-07):** ID-space is truth — the perimeter sweep IS pass 6, matching the `P6-S*` IDs on disk. The shard files' "Pass 5" titles are preserved per D-034 spirit; errata notes have been added to the affected files (perimeter-sweep-shard-1.md, perimeter-sweep-shard-6.md, perimeter-sweep-synthesis.md). The separate P5-* finding population (36/37 DISPUTED, `adversary-pass-5.md`) remains pass 5. The next adversary pass after remediation is **pass 7**. The 0/3 clean-pass counter is unaffected.

[^sweep-count]: `perimeter-sweep-synthesis.md` claims **259**; executed unique-ID count (D-086 re-derivation) is **249**. Delta −10: shard-7 claims 44 but contains 35 (9 ID gaps: 004, 005, 025, 027, 032, 035, 041, 042, 043); shard-8 claims 40 but contains 39 (ID 030 missing). The historical STATE.md trajectory shorthand `→34→39→37→259` is PRESERVED AS-IS in STATE.md per operator instruction. Both figures are recorded here; the executed 249 is the correct per-D-086 figure. Do NOT rewrite the STATE.md shorthand to 249.

[^crit-40]: Synthesis document originally stated `~42 CRITICAL`. CI-062 correction: per-shard C-column subtotals sum to 40 (2+4+7+7+6+2+6+6). Corrected to 40 in `perimeter-sweep-synthesis.md` (CI-062). The `~42` figure is superseded.

## Trajectory Shorthand

Historical shorthand as recorded in STATE.md (do not change): `→0→32→34→39→37→259`

Executed correction (D-086): `→0→32→34→39→37→[36/37]→249`

Note: the `→259` in the STATE.md shorthand reflects the synthesis document's claimed total.
The executed re-derivation (D-086) found 249 unique IDs. Both are preserved per operator
instruction. The STATE.md shorthand is not rewritten to 249.

## Per-Pass Details

### Pass 1 (2026-08-05)

**Findings:** 32 (6 CRIT, 21 HIGH, 5 MED, 0 LOW)
**Novelty:** HIGH
**Convergence counter:** 0 of 3

Pass 1 reviewed: prd.md, prd-supplements/, behavioral-contracts/, architecture/, domain-spec/, verification-properties/, BRIEF.md. Full-corpus scan including targeted greps across all 130+ spec files at time of pass. Key finding clusters: verdict vocabulary two-layer confusion (alive/clean conflation), error taxonomy issues (ADR-007 exit-code inversion, phantom reason codes), holdout scenario compromise at source-of-truth layer, PRD requirement gaps for --online flag semantics, NFR regression gate missing.

Remediation after pass 1: D-010..D-013 decisions recorded; error-taxonomy.md revised; ADR-007 corrected (exit codes, reason code set); alive→clean vocabulary aligned across prd.md and interface-definitions.md; sub_reason field added (D-016); verdict two-layer model clarified in prd.md §5b (D-014, D-015).

---

### Pass 2 (2026-08-05)

**Findings:** 34 (7 CRIT, 19 HIGH, 8 MED, 0 LOW)
**Novelty:** HIGH (REGRESSION: increased from pass 1)
**Convergence counter:** 0 of 3

Pass 2 focused on: verification-properties layer (all 24 VP files, full read), architecture verification-architecture.md and verification-coverage-matrix.md, VP-INDEX.md, domain-spec capabilities/invariants/edge-cases, prd-supplements error-taxonomy and interface-definitions, partial ADR-006, prd.md §5/§5b/§6, targeted BCs (BC-2.05.001, BC-2.07.005, BC-2.07.008, BC-2.10.002, BC-2.11.002). Targeted greps across all 130 spec files. Novelty increased (32→34) — consistent with concurrent multi-agent editing introducing regressions. Key new finding clusters: VP specification gaps for edge cases, cross-subsystem interaction blind spots (duplicate-slug × emoji, HTTP pool × rayon, URL dedup × per-occurrence reporting), interface-definitions inconsistencies, continued holdout-pool compromises.

Coverage NOT reached in pass 2: 56 of 66 BC files unread; nfr-catalog.md, test-vectors.md, BC-INDEX.md, ADRs 001-005/007 unread; most domain-spec shards only grepped; most architecture shards only grepped; policies.yaml only partially read; prd.md §1-§4/§7+ unread.

Consistency audit pass 2 result: FAIL — 3 critical / 7 major / 3 minor. 11 of 13 pass-1 findings confirmed FIXED. Regressions introduced by concurrent multi-agent editing noted.

Remediation after pass 2: COMPLETE (burst 4, 2026-08-05). BI-003 resolved — all 4 human spec decisions ruled. D-021..D-025 recorded. PRD v1.7. Holdout pool reconciled to 12 (HS-004..HS-007 authored, EC-165..EC-168 authored, HS-002/003 retired, EC-036/049/074/157/158 burned to visible tests). Delivery model updated: full PR-based delivery restored (D-021/D-022/D-023). Exit-code model codified as three-input function (D-025). PATH arg error model codified as runtime I/O error (D-024). Skip log corrected: phase-1-cicd-setup → COMPLETE; pr steps un-skipped.

---

### Pass 3 (2026-08-06)

**Findings:** 39 (5 CRIT, 26 HIGH, 8 MED, 0 LOW)
**Novelty:** HIGH (REGRESSION: 34→39 novel findings)
**Convergence counter:** 0 of 3

Pass 3 covered the unreached perimeter from pass 2: ADR-007-three-verdict-model.md, BC-INDEX.md, BC-2.10.004.md, test-vectors.md, prd.md, HS-INDEX.md, policies.yaml, VP-INDEX.md, verification-coverage-matrix.md, ARCH-INDEX.md, error-taxonomy.md, failure-modes.md. Findings clustered around: missing module ownership tracking in BCs, BC edge-case-table structure (EC ID collisions), placeholder markers (`[filled by story-writer]` / `[filled by architect]`), index integrity issues, title sync failures, slug computation fidelity verification gap (FM-002 unprovable with current VP set).

NOTE: 29 of 39 findings stored as stubs in adversary-pass-3.md — full finding text was not supplied to the persisting agent. Pass 4 supersedes this record.

Consistency audit pass 3 result: FAIL.

Strategy response: Novelty increasing for 3 consecutive passes under manual remediation (32→34→39). Strategy pivoted to mechanical enforcement + generation. Built spec-lint validator/generator suite (8 validators, 4 generators, negative-test selftest) on branch `feature/spec-lint-tooling` (open PR #2). Running `just spec-lint` cleared 254 → 25 mechanical violations. 7 of 8 checkers now PASS. Remaining 25 are check-placeholders `[filled by story-writer]` — legitimately unresolvable until Phase 2 story-writer runs.

Remediation after pass 3: COMPLETE (burst 5, 2026-08-06). D-026/D-027 recorded. PRD v1.9. 25 VPs (VP-025 added for anchor_resolver totality). 13 DIs (DI-012/DI-013 added). All 66 BCs carry owning module/criticality/VP anchor from new `architecture/bc-module-map.md`. ADR-007 rewritten to v1.3 (two-layer verdict model). Mechanical violations 254 → 25 (25 expected-pending placeholders). BI-004 resolved. BI-005/006 opened.

---

### Pass 4 (2026-08-06)

**Findings:** 37 (3 CRIT, 19 HIGH, 15 MED, 0 LOW)
**Novelty:** ZERO in 7 mechanically-enforced classes (title-sync, EC-injectivity, id-resolution, counts, holdout-boundary, ADR-consistency, index-integrity)
**Convergence counter:** 0 of 3

Pass 4 performed deep reads of: VP-025, VP-026, VP-018, BC-2.06.001, api-surface.md, ADR-001..ADR-007, architecture/tooling-selection.md, bc-module-map.md, test-vectors.md, interface-definitions.md, domain-interfaces.md (DI-012 rules). Full regression audit of 12 prior fixes — found 8 of 12 applied to primary artifact only, not siblings/dependents. Key finding clusters: VP test-path Cargo non-discovery (P4-014, 10 VPs), BC/DI/VP contradiction on HTML element slug behavior (P4-001, BI-009), VP-025 authored against non-existent API types (P4-002, BI-010), VP-026 vacuous-pass risk on empty corpus (P4-012, BI-011), spec-topology defect (~15 documents hand-maintaining restatements with no generator, BI-012). ZERO findings in any of the 7 mechanically-enforced classes — enforcement judged SUCCESSFUL on composition. Root cause reclassified from spec-quality to SPEC-TOPOLOGY per D-035.

NOTE: adversary agent tool-profile is read-only; report was recovered by orchestrator from JSONL transcript (D-037). Full report: cycles/phase-1d/adversary-pass-4.md (784 lines, 104,916 bytes, P4-001..P4-038).

Strategy response per D-036: pass 5 will NOT run against current topology. Pre-pass-5 sequence: (1) adjudicate BI-009 (P4-001 HTML-strip contradiction), (2) close BI-008/BI-011 as verification-invalidating, (3) land BI-012 generators + canonical-facts block. Then pass 5.

---

## Frontmatter Fields (extracted from STATE.md)

<!-- When compacting STATE.md, adversary_pass_* frontmatter fields are
     converted to rows in the Finding Progression table above.
     Original field format: adversary_pass_N_findings: "description"
     Original field format: adversary_pass_N_date: "YYYY-MM-DD" -->

No STATE.md frontmatter fields were compacted into this file. The trajectory data above was
written directly from the phase-1d adversarial review artifacts.
