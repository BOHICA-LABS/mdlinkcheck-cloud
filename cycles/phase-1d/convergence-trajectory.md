---
document_type: convergence-trajectory
level: ops
version: "1.0"
status: in-progress
producer: state-manager
timestamp: 2026-08-05T20:00:00Z
cycle: phase-1d
inputs:
  - .factory/cycles/phase-1d/adversary-pass-1.md
  - .factory/cycles/phase-1d/adversary-pass-2.md
input-hash: "5f91f02"
traces_to: STATE.md
---

# Convergence Trajectory — phase-1d

## Finding Progression

| Pass | Date | Total | CRIT | HIGH | MED | LOW | Novelty | Score | Counter | Verdict |
|------|------|-------|------|------|-----|-----|---------|-------|---------|---------|
| 1 | 2026-08-05 | 32 | 6 | 21 | 5 | 0 | HIGH | — | 0/3 | FINDINGS_REMAIN — REMEDIATED |
| 2 | 2026-08-05 | 34 | 7 | 19 | 8 | 0 | HIGH | — | 0/3 | FINDINGS_REMAIN (REGRESSION: novelty increased) — REMEDIATED |
| 3 | 2026-08-06 | 39 | 5 | 26 | 8 | 0 | HIGH | — | 0/3 | FINDINGS_REMAIN (REGRESSION: novelty increased) — REMEDIATED (mechanical enforcement) |

## Trajectory Shorthand

`→32→34→39`

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

## Frontmatter Fields (extracted from STATE.md)

<!-- When compacting STATE.md, adversary_pass_* frontmatter fields are
     converted to rows in the Finding Progression table above.
     Original field format: adversary_pass_N_findings: "description"
     Original field format: adversary_pass_N_date: "YYYY-MM-DD" -->

No STATE.md frontmatter fields were compacted into this file. The trajectory data above was
written directly from the phase-1d adversarial review artifacts.
