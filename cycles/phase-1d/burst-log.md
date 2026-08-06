---
document_type: burst-log
level: ops
version: "1.0"
status: in-progress
producer: state-manager
timestamp: 2026-08-05T20:00:00Z
cycle: phase-1d
inputs: [STATE.md]
input-hash: "[live-state]"
traces_to: STATE.md
---

# Burst Log — phase-1d

## Burst: burst 1 — Phase 1 Spec Crystallization (2026-08-05)

**Parent-commit:** (pre-crystallization; initial planning burst bef00f2)

**Adversary verdict:** Phase 1 spec crystallization burst — no adversary pass yet at time of crystallization.

**Files touched (Dim-1): 7 unique files (index of directories)**

- .factory/specs/product-brief.md
- .factory/specs/prd.md (v1.5, 66 BCs across ss-01..ss-14)
- .factory/specs/domain-spec/ (12 shards + L2-INDEX.md)
- .factory/specs/behavioral-contracts/ (BC-INDEX.md + 14 subsystem dirs)
- .factory/specs/verification-properties/ (24 VPs + VP-INDEX.md)
- .factory/specs/architecture/ (9 shards + ARCH-INDEX.md + 7 ADRs)
- .factory/specs/prd-supplements/ (error-taxonomy.md, interface-definitions.md, nfr-catalog.md, test-vectors.md)

**Codifications:** D-006..D-009 recorded (platform path semantics, HTML anchor carve-out, three-verdict model, scope decisions).

---

## Burst: burst 2 — Phase 1d Adversarial Pass 1 + Consistency Audit 1 (2026-08-05)

**Parent-commit:** (factory-artifacts HEAD after Phase 1 crystallization commit)

**Adversary verdict:** Pass 1: 32 novel findings (6 CRIT, 21 MAJOR, 5 MINOR). Trajectory →32.

**Files touched (Dim-1): 3 unique files**

- .factory/cycles/phase-1d/adversary-pass-1.md
- .factory/cycles/phase-1d/consistency-audit-phase-1.md
- .factory/cycles/phase-1d/spec-review-second-opinion.md

**Codifications:** D-010..D-013 recorded (holdout visibility, dropped flags, .md-only discovery, NFR ceilings confirmed).

---

## Burst: burst 3 — Phase 1d Checkpoint pass-2 complete (2026-08-05)

**Parent-commit:** `bef00f277afbb8a95d7f9c16534a8c4a0146bcff` (factory(pre-1): planning phase burst)

**Adversary verdict:** Pass 2: 34 novel findings (7 CRIT, 19 MAJOR, 8 MINOR). Convergence NOT achieved. Trajectory →32→34 (novelty increasing). Convergence counter: 0 of 3.

**Files touched (Dim-1): 3 unique files**

- .factory/STATE.md
- .factory/cycles/phase-1d/burst-log.md
- .factory/cycles/phase-1d/convergence-trajectory.md

**Codifications:** D-014..D-016 recorded (two-layer verdict vocabulary, error-taxonomy canonical ruling, sub_reason field). D-006..D-013 (recorded in prior bursts) reflected in STATE.md decisions log. BI-002/003/004 opened. Phase-1d convergence loop IN_PROGRESS.

**Dim-2 Attestation:** Literal shell gate executed. Confirmed adversary-pass-2.md finding declaration matches stated count.

```
$ grep -c "NOVEL_FINDINGS:\|^NOVEL_FINDINGS\|FINDINGS:" .factory/cycles/phase-1d/adversary-pass-2.md
2
exit code: 0
```

Both `FINDINGS:` (severity summary line) and `NOVEL_FINDINGS:` declaration lines present. adversary-pass-2.md §Summary table confirms 34 total (7 CRIT + 19 MAJOR + 8 MINOR).

**Dim-5 Attestation:** adversary-pass-2.md — 34 novel findings. Producer: adversary agent, pass 2, input-hash bef00f2. Document 579 lines, status: final.

**Dim-6 Attestation:** IN_PROGRESS. Convergence counter 0 of 3 required clean passes. Novelty trend →32→34 (increasing). Not converging.

**Dim-7 Attestation:** Agents dispatched in this checkpoint burst: adversary (pass 2), consistency-validator (pass 2), state-manager (checkpoint commit). Total: 3 agents. This is the first burst-log entry — no prior Dim-7 cells to sweep for anachronism.

**Closes:** D-006..D-016 (all decisions recorded in STATE.md). BI-002, BI-003, BI-004 opened in STATE.md. Phase-1d pass-2 checkpoint committed to factory-artifacts.

---

## Burst: burst 4 — Pass-2 Remediation Complete + Delivery-Model Change (2026-08-05)

**Parent-commit:** `abaa2ab` (factory(phase-1d): checkpoint pass-2 complete; prior burst)

**Adversary verdict:** No new adversary pass this burst. This burst is post-pass-2 remediation only.

**Files touched (Dim-1): 15 unique files**

- .factory/STATE.md (decisions D-021..D-025 added; D-002 superseded; skip log corrected; BI-001/003 resolved; session checkpoint refreshed; artifact counts updated)
- .factory/specs/prd.md (v1.7: JSON object envelope, indeterminate for HTTP 400-after-GET, --allow normalize-then-match; holdout pool reconciled)
- .factory/specs/behavioral-contracts/ss-01/BC-2.01.009.md (--allow flag BC updated per D-024)
- .factory/specs/behavioral-contracts/ss-14/BC-2.14.001.md, BC-2.14.002.md, BC-2.14.003.md (ss-14 BCs: exit-code three-input model per D-025)
- .factory/specs/architecture/ARCH-INDEX.md, api-surface.md, module-decomposition.md, purity-boundary-map.md, system-overview.md, verification-architecture.md, verification-coverage-matrix.md, decisions/ADR-006-strict-path-model.md
- .factory/cicd-setup.md (updated: branch protection + required status checks live; D-021/D-022/D-023 delivery model recorded)
- .factory/holdout-scenarios/HS-INDEX.md (HS-002/003 retired; HS-004..007 active; EC-165..168 added; EC-036/049/074/157/158 burned to visible tests)
- .factory/holdout-scenarios/wave-scenarios/EC-165-anchor-resolution-case-variant.md (NEW)
- .factory/holdout-scenarios/wave-scenarios/EC-166-source-exclusion-cross-file-anchor.md (NEW)
- .factory/holdout-scenarios/wave-scenarios/EC-167-percent-encoding-fragment-split.md (NEW)
- .factory/holdout-scenarios/wave-scenarios/EC-168-duplicate-slug-collision.md (NEW)
- .factory/cycles/phase-1d/burst-log.md (this file)
- .factory/cycles/phase-1d/convergence-trajectory.md (pass-2 remediation section updated)
- .factory/cycles/phase-1d/blocking-issues-resolved.md (NEW: BI-001 and BI-003 archived)
- .factory/cycles/phase-1d/session-checkpoints.md (NEW: prior checkpoint archived)

**Codifications:**
- D-002 SUPERSEDED by D-021 (local-only delivery was a workaround; full PR delivery now active)
- D-021: Full PR-based delivery restored; merge gate = required CI status checks + factory AI review; agents NEVER merge PRs
- D-022: Branch topology: story PRs target `develop`; releases go `develop` → `main` via PR; branch protection live with 8 strict required status checks
- D-023: CI jobs use `Cargo.toml`-presence guards so they pass green before Rust workspace exists; required status check context strings are unprefixed job names
- D-024: Nonexistent/unreadable PATH argument is runtime I/O error (recorded, scan continues, exit 2 at end) — NOT startup config error
- D-025: `verdict::exit_code(findings, io_errors, config_error) -> u8` — three inputs; io_errors/config_error → 2; broken → 1; else 0

**Delivery-model change summary:** BI-001 (no origin remote) resolved by operator creating `https://github.com/BOHICA-LABS/mdlinkcheck-cloud`. D-002 (local-only) is superseded. Branch protection is live with 8 required status checks, linear history, enforce_admins=true on main. PR #1 merged CI workflows (17/17 checks green, commit 78a9f77). Full pr-manager 9-step + pr-reviewer diff review restored for every story.

**BI-001 resolved:** Remote created by operator; full PR lifecycle active; branch protection configured.
**BI-003 resolved:** All 4 human spec decisions ruled: JSON object envelope accepted; HTTP 400-after-GET-fallback = indeterminate; --allow uses normalize-then-match with raw-string fallback; 5 leaked holdouts burned and replaced.

**Artifact state at burst close:**
PRD v1.7 | 66 BCs | 24 VPs (kani 7 / proptest 7 / fuzz 2 / integration 7 / unit 1) | 7 ADRs | 9 arch shards | 12 domain-spec shards | 26+ DD decisions | 19 policies | holdout pool 12 (HS-001 + HS-004..007 active; HS-002/003 retired)

**Dim-2 Attestation:** Holdout pool count verified: HS-001 active + HS-004..HS-007 newly authored = 5 active holdouts (HS-002/003 retired). EC-036/049/074/157/158 confirmed burned to visible tests.

**Dim-5 Attestation:** Artifact corpus at burst close — prd.md v1.7 (66 BCs, 24 VPs, 7 ADRs, 9 arch shards, 12 domain-spec shards, 19 policies, 26+ DD decisions). Holdout pool: 12 scenarios total (5 active: HS-001/004..007; 2 retired: HS-002/003; 5 reserved: not-yet-authored). cicd-setup.md records branch protection live on main+develop with 8 required status checks, PR #1 merged at 78a9f77 (17/17 checks green). Producer: state-manager burst 4. Input-hash: abaa2ab. Status: final.

**Dim-6 Attestation:** IN_PROGRESS. Convergence counter 0 of 3 required clean passes. Pass-2 remediation COMPLETE. Awaiting pass 3.

**Dim-7 Attestation:** Agents dispatched in this burst: product-owner (BI-003 spec decisions), architect (D-024/D-025 rulings), business-analyst (domain-spec alignment), spec-steward (HS-INDEX, holdout pool), devops-engineer (D-021/D-022/D-023 delivery model), state-manager (this checkpoint). Total: 6 agents.

**Closes:** BI-001 (remote exists), BI-003 (human spec decisions). D-017..D-025 recorded in STATE.md. Skip log corrections applied. Session checkpoint updated. Phase-1d pass-2 remediation burst committed to factory-artifacts.

---

## Burst: burst 5 — Pass-3 Review + Strategy Pivot to Mechanical Enforcement + Violation Remediation (2026-08-06)

**Parent-commit:** `db029e3` (fix(phase-1d): pass-2 remediation COMPLETE — D-021..D-025; delivery model restored; BI-001/003 resolved)

**Adversary verdict:** Pass 3: 39 novel findings (5 CRIT, 26 MAJOR, 8 MINOR). Novelty still INCREASING under manual remediation (32→34→39). Consistency audit pass 3: FAIL. Convergence counter: 0 of 3.

**Strategy change:** Manual fix-by-fix remediation was driving novelty higher with each pass. Strategy pivoted to mechanical enforcement + generation: build a spec-lint tooling suite that catches violations at write-time and generates canonical forms rather than manually editing each file.

**Files touched (Dim-1): 19 unique files (index of directories)**

- `.factory/cycles/phase-1d/adversary-pass-3.md` (NEW — 39 novel findings; NOTE: 29 of 39 stored as stubs — full finding text was not supplied to the persisting agent; pass 4 supersedes this record)
- `.factory/cycles/phase-1d/consistency-audit-phase-1-pass-3.md` (NEW — FAIL)
- `.factory/cycles/phase-1d/process-gap-register.md` (UPDATED — mechanical enforcement gaps added)
- `scripts/spec-lint/` (NEW in source repo — 8 validators + 4 generators + negative-test selftest suite, on branch `feature/spec-lint-tooling` via open PR #2; NOT merged — D-021 forbids agent merges)
- `.factory/specs/architecture/bc-module-map.md` (NEW — maps all 66 BCs to owning module, criticality tier, VP anchor)
- `.factory/specs/verification-properties/vp-025-anchor-resolver-totality.md` (NEW — VP-025: anchor_resolver totality and correctness)
- `.factory/specs/prd.md` (v1.9 — final update in this burst)
- `.factory/specs/behavioral-contracts/` (ALL 66 BCs updated with owning module, criticality tier, VP anchor from bc-module-map.md)
- `.factory/specs/domain-spec/invariants.md` (DI-012 Slug Computation Fidelity + DI-013 Anchor-Key Uniqueness Within a File added)
- `.factory/specs/domain-spec/decisions.md` (DD-027 added)
- `.factory/specs/architecture/decisions/ADR-007-three-verdict-model.md` (rewritten to v1.3 — two-layer verdict model codified)
- `.factory/specs/architecture/ARCH-INDEX.md`, `verification-architecture.md`, `verification-coverage-matrix.md` (updated)
- `.factory/specs/behavioral-contracts/BC-INDEX.md`, `.factory/specs/verification-properties/VP-INDEX.md` (counts updated)
- `.factory/specs/domain-spec/L2-INDEX.md`, `capabilities.md`, `edge-cases.md`, `failure-modes.md` (updated)
- `.factory/specs/prd-supplements/nfr-catalog.md`, `test-vectors.md` (updated)
- `.factory/specs/module-criticality.md` (updated)
- `.factory/policies.yaml` (real `lint_hook` values populated on all automated policies)
- `.factory/specs/architecture/decisions/ADR-005-rayon-sort-before-emit.md` (updated)
- `.factory/specs/behavioral-contracts/ss-01/` through `ss-14/` (all BCs updated)

**Mechanical violation remediation results (`just spec-lint` run):**

| Checker | Before | After | Status |
|---------|--------|-------|--------|
| check-title-sync | 22 | 0 | PASS |
| check-ec-injectivity | 98 | 0 | PASS |
| check-id-resolution | 21 | 0 | PASS |
| check-counts | 3 | 0 | PASS |
| check-holdout-boundary | 8 | 0 | PASS |
| check-adr-consistency | 47 | 0 | PASS |
| check-index-integrity | 55 | 0 | PASS |
| check-placeholders | 0 | 25 | EXPECTED-PENDING (25 `[filled by story-writer]` markers; legitimately unresolvable until Phase 2) |
| **TOTAL** | **254** | **25** | **7 of 8 PASS** |

**Codifications:**
- D-026: BC `## Edge Cases` tables cite EC registry IDs + one-line label ONLY; canonical inputs/verdicts live solely in `prd-supplements/test-vectors.md` (POL-16). Structural root cause of 98 EC-ID collisions (six with opposite expected verdicts) eliminated — makes the collision class unrepeatable.
- D-027: Validator hardening mandatory before trusting any validator result. `check-id-resolution` initially returned PASS while never checking EC IDs (`VALID_EC` built and unused); `check-counts` missing 3 checks; `check-placeholders` had 23 false positives from changelog lines and missed 55 real `test-sufficient`-in-VP-column defects. All 8 checkers now have negative tests.

**Follow-up items (NOT blocking, documented for resuming session):**
- L2-INDEX.md lacks DD-027 → DI-012/DI-013 cross-reference rows (owner: business-analyst)
- INC-MAP-004: no VP directly verifies `scanner`'s `.gitignore` exclusion in isolation — recorded as accepted gap with rationale
- `adversary-pass-3.md` has 29 of 39 findings stored as stubs; full text was not supplied to the persisting agent; pass 4 supersedes this record

**Artifact state at burst close:**
PRD v1.9 | 66 BCs (all carry owning module, criticality tier, VP anchor) | 25 VPs (kani 7 / proptest 8 / fuzz 2 / integration 7 / unit 1; tiers P0 7 / P1 10 / test-sufficient 8) | 13 DIs | 27 DD decisions | 7 ADRs (ADR-007 v1.3) | 19 policies (real lint_hook values) | BC module map at `architecture/bc-module-map.md` | spec-lint CI job on PR #2 (unmerged)

**Dim-2 Attestation:** `just spec-lint` confirmed 254 → 25 violations. 7 of 8 checkers PASS. Remaining 25 are check-placeholders `[filled by story-writer]` — expected-pending until Phase 2.

**Dim-5 Attestation:** Artifact corpus at burst close — PRD v1.9, 66 BCs, 25 VPs (VP-025 added for anchor_resolver totality), 13 DIs (DI-012/DI-013 added), 27 DD decisions, 7 ADRs, 19 policies. BC module map NEW. spec-lint tooling on `feature/spec-lint-tooling` (open PR #2, NOT merged). Producer: state-manager burst 5. Status: final.

**Dim-6 Attestation:** IN_PROGRESS. Convergence counter 0 of 3 required clean passes. Novelty trend →32→34→39 (still increasing under manual remediation). Strategy changed to mechanical enforcement + generation. Adversary pass 4 is the next action — first real test of whether mechanical enforcement bends the novelty curve.

**Dim-7 Attestation:** Agents dispatched in this burst: adversary (pass 3), consistency-validator (pass 3), devops-engineer (spec-lint tooling + CI job), architect (bc-module-map, VP-025, DI-012/DI-013), product-owner (PRD v1.9), spec-steward (all BC updates), state-manager (this checkpoint). Total: 7 agents.

**Closes:** BI-004 (pass 3 covered unreached perimeter from pass 2). Opens: BI-005 (slug-fidelity VP gap insufficient), BI-006 (PR #2 unmerged, spec-lint not in required status checks). D-026/D-027 recorded.

## Archived STATE.md Steps (overflow — evicted from Current Phase Steps table 2026-08-06)

| Step | Agent | Status | Output |
|------|-------|--------|--------|
| phase-1d consistency audit pass 3 | consistency-validator | COMPLETE | consistency-audit-phase-1-pass-3.md; FAIL |
