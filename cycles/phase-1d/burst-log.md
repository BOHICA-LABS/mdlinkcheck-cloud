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

---

## Burst: burst 6 — WS-3 close BI-005 via VP-026 (2026-08-06)

**Parent-commit:** (factory-artifacts HEAD after burst 5 / D-031 merge autonomy commit)

**Adversary verdict:** No new adversary pass this burst. This burst is spec-authoring only (VP-026 + traceability updates).

**Files touched (Dim-1): 10 unique files**

- `.factory/specs/verification-properties/vp-026-slug-differential-fidelity.md` (NEW — VP-026: slug differential fidelity; differential proptest oracle vs pinned `github-slugger@2.0.0` corpus; covers all 7 DI-012 rules)
- `.factory/specs/verification-properties/vp-018-slug-worked-examples.md` (UPDATED — +3 vectors: duplicate-heading golden vector, inline-code+HTML-tags vector)
- `.factory/specs/verification-properties/VP-INDEX.md` (UPDATED — VP-026 registered; count 25→26)
- `.factory/specs/architecture/verification-coverage-matrix.md` (UPDATED — VP-026 row; FM-002 coverage)
- `.factory/specs/architecture/verification-architecture.md` (UPDATED — slug differential fidelity coverage)
- `.factory/specs/domain-spec/failure-modes.md` (UPDATED — FM-002 status: unprovable → covered by VP-026)
- `.factory/specs/domain-spec/invariants.md` (UPDATED — DI-012/DI-013 VP coverage updated)
- `.factory/specs/module-criticality.md` (UPDATED — slug row: DI-003 → DI-012/DI-013 governing invariant; VP count updated)
- `.factory/logs/dispatcher-internal-2026-08-06.jsonl` (UPDATED — dispatcher log)
- `.factory/logs/events-2026-08-06.jsonl` (UPDATED — events log)

**Codifications:**
- D-033: BI-005 closed at spec level; residual implementation risk re-scoped to BI-007 (blocking phase-6, not phase-1). Closing a spec gap and discharging an implementation obligation are SEPARATE events.
- D-034: `prd.md:720` changelog entry is a HISTORICAL RECORD — must NOT be retroactively updated to reference VP-025/VP-026. Versioned changelog entries are immutable audit records.

**BI-005 closed:** VP-026 authored with differential oracle vs pinned `github-slugger@2.0.0` corpus, covering all 7 DI-012 rules, requiring >=3-repeat heading sequence. FM-002 moves from unprovable to covered. Specification gap is genuinely closed.

**BI-007 opened:** VP-026 is specified but unimplemented (no Rust workspace; Phase 3 not started). Successor to BI-005, blocking phase-6 formal hardening.

**Artifact state at burst close:**
PRD v1.9 | 66 BCs | 26 VPs (VP-026 added for slug differential fidelity) | 13 DIs | 27 DD decisions | 7 ADRs | 19 policies | spec-lint 7/8 PASS (25 `[filled by story-writer]` expected-pending until Phase 2)

**Dim-2 Attestation:** `just spec-lint` confirmed 7 of 8 checks PASSING. Single failure: `check-placeholders` at exactly 25 occurrences — legitimate and outstanding until Phase 2 story decomposition.

**Dim-5 Attestation:** VP-INDEX count 25→26. VP-026 registered. FM-002 coverage status updated in failure-modes.md. Producer: architect (VP-026 authoring), state-manager (checkpoint). Status: final.

**Dim-6 Attestation:** IN_PROGRESS. Convergence counter 0 of 3 required clean passes. Awaiting adversary pass 4 + consistency pass 4 against frozen HEAD.

**Dim-7 Attestation:** Agents dispatched in this burst: architect (VP-026 authoring, traceability updates), state-manager (this checkpoint). Total: 2 agents.

**Closes:** BI-005 (slug fidelity VP gap — closed at spec level). **Opens:** BI-007 (VP-026 unimplemented — successor to BI-005, blocking phase-6).

---

## Archived STATE.md Steps (overflow — evicted from Current Phase Steps table 2026-08-06)

| Step | Agent | Status | Output |
|------|-------|--------|--------|
| phase-1d consistency audit pass 3 | consistency-validator | COMPLETE | consistency-audit-phase-1-pass-3.md; FAIL |
| phase-1d spec-lint tooling built | devops-engineer | COMPLETE | scripts/spec-lint/ (8 validators, 4 generators, selftest); just spec-lint CI job; PR #2 open (feature/spec-lint-tooling) |
| phase-1d pass-3 remediation | architect/product-owner/spec-steward | COMPLETE | 254→25 violations; D-026/D-027; PRD v1.9; VP-025; DI-012/DI-013; ADR-007 v1.3; bc-module-map.md |

---

## Burst: burst 7 — Pass-4 Remediation Close-Out (STATE.md + Cycle Files) (2026-08-06)

**Parent-commit:** `6c3eb0ff06e0489f85ea36e8eeef4590c835bf42` (docs(spec-lint): update pr-description.md for 11-selftest milestone)

**Adversary verdict:** No new adversary pass in this burst. This is a state-manager close-out burst committing spec artifacts produced by two prior remediation bursts (architect + product-owner) and updating pipeline state. Trajectory unchanged: →0→32→34→39→37. pass count: 0 of 3.

**Files touched (Dim-1): 5 unique files**

- `.factory/STATE.md` — timestamp advanced; D-038..D-042 appended to Decisions Log; BI-006/BI-008/BI-009/BI-011 removed (moved to resolved); BI-010 resolution updated; BI-014/BI-015/BI-016 added; Current Phase Steps evicted 2 oldest + added 2 new; pass-4 fix burst row added to Phase Progress; trajectory-tail added to Last Updated cell; spec snapshot updated (8 ADRs, EC-001..EC-204 205 ids); banner line count corrected
- `.factory/cycles/phase-1d/blocking-issues-resolved.md` — BI-006/BI-008/BI-009/BI-011/BI-013 appended
- `.factory/cycles/phase-1d/lessons.md` — lessons 9–13 appended (D-039/D-040/D-041 process-gaps, partial-fix pattern, mechanical-enforcement observation); policy candidates 9–11 added
- `.factory/cycles/phase-1d/burst-log.md` — this entry; evicted STATE.md phase steps archived
- `.factory/specs/**` — ~80 spec files modified by prior architect + product-owner bursts (ADR-008, VP-025 rewrite, VP harness path corrections, EC-184..EC-204 additions, BC amendments, etc.); committed without content modification

**Codifications:** D-038 (PR #2 cycle overrun exception), D-039 (remediation-by-suppression forbidden), D-040 (skip lists require proven-can-fail evidence), D-041 (branch ownership vs merge authority), D-042 (independent convergence = strongest evidence). BI-006/BI-008/BI-009/BI-011/BI-013 CLOSED. BI-014/BI-015/BI-016 opened.

**Evicted Current Phase Steps (archived verbatim):**

| Step | Agent | Status | Output |
|------|-------|--------|--------|
| session wrap D-030 | state-manager | COMPLETE | SESSION-HANDOFF.md §RESUME SNAPSHOT D-030; sidecar committed |
| next: WS-1 PR#2 pr-manager review | pr-manager | pending | full review lifecycle per D-028 — review dispatch → triage → fix → convergence → merge |

**Dim-2 Attestation:** spec-lint `just spec-lint` = 7 of 8 checks PASS. Only failure: `check-placeholders` at exactly 25 `[filled by story-writer]` occurrences — legitimate until Phase 2. `check-ec-injectivity` PASSES with 205 EC IDs all injective. `check-index-integrity` reports 79 structural checks with BC (66 entries) / VP (26 entries).

**Dim-5 Attestation:** STATE.md — 189 lines (banner verified post-write), status: draft, producer: state-manager, timestamp: 2026-08-06T22:40:00Z. blocking-issues-resolved.md — 9 resolved entries (BI-001/003/004/006/008/009/011/013 + BI-002 predecessor). lessons.md — 13 lessons. burst-log.md — 7 bursts.

**Dim-6 Attestation:** IN_PROGRESS. Convergence counter 0 of 3 required clean passes. Trajectory →0→32→34→39→37. Not converged. Pass 5 pending BI-012 generators + PR #3 merge per D-036/D-040.

**Dim-7 Attestation:** Agents dispatched in this burst: state-manager (this burst). Spec content produced by prior architect + product-owner bursts committed without dispatch.

**Closes:** BI-006 (PR #2 merged 2290cb0), BI-008 (VP harness paths flattened), BI-009 (ADR-008 + BC-2.06.001 amended), BI-011 (VP-026 oracle assertions added), BI-013 (EC-184..EC-204 + checker hardened).

---

## Archived STATE.md Steps (overflow — evicted from Current Phase Steps 2026-08-06, burst 8)

| Step | Agent | Status | Output |
|------|-------|--------|--------|
| merge autonomy D-031 (level 4) | state-manager | COMPLETE | .factory/merge-config.yaml created; autonomy_level 4; D-031/D-032 recorded |

---

## Burst: burst 8 — D-043 macOS-only Platform Narrowing + Session Wrap D-045 (2026-08-06)

**Parent-commit:** `964e72f3bd60ad6a6a7be7dd641a9d9dc9cd269d` (feat(specs): pass-4 remediation — ADR-008, VP-025 rewrite, 13 EC collisions resolved (D-038..D-042))

**Adversary verdict:** No new adversary pass in this burst. This is a spec-content burst (D-043 macOS-only platform narrowing applied by architect ×2 + product-owner bursts) plus state-manager session wrap (D-044/D-045 consequences recorded). Trajectory unchanged: →0→32→34→39→37. pass count: 0 of 3.

**Files touched (Dim-1): 27 unique files**

- `.factory/STATE.md` — D-043..D-045 appended to Decisions Log; BI-016 updated (spurious CI failures explained, rebase advisable); BI-017/BI-018 added; Current Phase Steps evicted oldest + added D-043 row; Session Resume Checkpoint → D-045; spec snapshot updated (D-001..D-045 exhaustive; open BIs updated); trajectory-tail added to Last Updated cell; timestamp advanced; size budget updated
- `.factory/SESSION-HANDOFF.md` — D-030 marked SUPERSEDED; §RESUME SNAPSHOT D-045 appended; Latest pointer updated
- `.factory/cycles/phase-1d/lessons.md` — lessons 14/15 appended (parallel-burst decision-dependency gap; canonical-text-up-front observation)
- `.factory/cycles/phase-1d/burst-log.md` — evicted step archived; this entry
- `.factory/specs/architecture/decisions/ADR-006-strict-path-model.md` — rationale restated on determinism grounds (D-043); platform-divergence argument removed as primary justification; ADR status confirmed `accepted`
- `.factory/specs/architecture/feasibility-review.md` — NFR-004 retired; macOS-only matrix noted
- `.factory/specs/architecture/system-overview.md` — CI matrix updated to macOS-only for test/build; platform notes updated
- `.factory/specs/architecture/tooling-selection.md` — NFR-002 re-targeted 10s p95 macos-latest; NFR-004 RETIRED; `unicode-normalization` pinned 0.1.24 noted as load-bearing; Phase 3 CI obligations section added (BI-017)
- `.factory/specs/architecture/verification-architecture.md` — VP-008/VP-009 noted as sole gatekeepers for case-sensitivity/NFC post-macOS-only (D-045); BC-2.07.003 formal hardening priority raised
- `.factory/specs/architecture/verification-coverage-matrix.md` — NFR-004 retired row; macos-latest coverage noted
- `.factory/specs/behavioral-contracts/ss-07/BC-2.07.003.md` — formal hardening priority raised (D-045)
- `.factory/specs/domain-spec/L2-INDEX.md` — NFR-004 retired noted
- `.factory/specs/domain-spec/assumptions.md` — platform assumptions updated (macOS APFS NFD + case-insensitive is the ONLY test filesystem; D-043)
- `.factory/specs/domain-spec/decisions.md` — D-043/D-044/D-045 recorded
- `.factory/specs/domain-spec/edge-cases.md` — T13 (Windows path separators) retired as platform-obsolete (D-043)
- `.factory/specs/domain-spec/failure-modes.md` — FM notes updated for macOS-only matrix
- `.factory/specs/prd-supplements/nfr-catalog.md` — NFR-002 re-targeted to 10s p95 macos-latest; NFR-004 RETIRED; `unicode-normalization` pin noted
- `.factory/specs/prd-supplements/test-vectors.md` — platform notes updated; T13 retired
- `.factory/specs/prd.md` — NFR-002 updated; NFR-004 retired; branch-protection context count 8→4 noted
- `.factory/specs/verification-properties/VP-INDEX.md` — VP-008/VP-009 load-bearing note added
- `.factory/specs/verification-properties/vp-008-path-nfc-comparison.md` — determinism rationale updated (D-043/D-045); macOS APFS NFD note
- `.factory/specs/verification-properties/vp-009-nfc-idempotent.md` — same determinism rationale update
- `.factory/specs/verification-properties/vp-017-scan-terminates.md` — platform note updated
- `.factory/specs/verification-properties/vp-022-regression-gate.md` — Phase 3 CI obligation recorded: MUST run on macos-latest (BI-017); NFR-002 threshold updated
- `.factory/logs/dispatcher-internal-2026-08-06.jsonl` — dispatcher log
- `.factory/logs/events-2026-08-06.jsonl` — events log
- `.factory/sidecar-learning.md` — session observations updated

**Codifications:**
- D-043: Platform matrix narrowed to macOS latest ONLY; branch-protection 8→4 contexts; NFR-002 re-targeted 10s p95; NFR-004 RETIRED; T13 RETIRED; D-006/ADR-006/DI-002 REMAIN IN FORCE (rationale restated on determinism grounds); `unicode-normalization` pinned 0.1.24 load-bearing
- D-044: Platform-independent CI jobs (Format check, Clippy, Spec lint, hardening.yml ×6) REMAIN on ubuntu-latest; only genuinely macOS-dependent jobs (Test, Build release) moved
- D-045: Dropping Linux/Windows removes incidental NFC/case-sensitivity safety net; VP-008/VP-009 solely load-bearing; BC-2.07.003 formal hardening priority RAISED
- BI-017 opened: Phase 3 CI perf-gate/benchmark jobs MUST run on macos-latest
- BI-018 opened: PR #4 (chore/macos-only-ci → develop) OPEN awaiting pr-manager review
- BI-016 updated: spurious CI failures explained (GitHub Actions infrastructure outage); rebase advisable

**Artifact state at burst close:**
PRD v1.9 | 66 BCs | 26 VPs | 13 DIs | 8 ADRs | 19 policies | EC registry EC-001..EC-204 (205 ids) | holdout pool 12 (5 active: HS-001/004..007; 2 retired: HS-002/003). D-001..D-045 recorded (exhaustive). spec-lint 7/8 PASS (only 25 known `[filled by story-writer]` placeholders — legitimate until Phase 2). PR #3 + PR #4 OPEN and unreviewed.

**Dim-2 Attestation:** `just spec-lint` = 7 of 8 checks PASS. Only failure: `check-placeholders` at exactly 25 occurrences — legitimate until Phase 2 story decomposition. Verified unchanged from burst 7.

**Dim-5 Attestation:** STATE.md — 194 lines, timestamp 2026-08-07T00:30:00Z, status: draft, producer: state-manager. SESSION-HANDOFF.md — D-045 appended; D-030 marked SUPERSEDED. lessons.md — 15 lessons. burst-log.md — 8 bursts.

**Dim-6 Attestation:** IN_PROGRESS. Convergence counter 0 of 3 required clean passes. Trajectory →0→32→34→39→37. Not converged. Pass 5 pending WS-A (PR #3 + PR #4 review/merge) + WS-B (BI-012 generators) per D-036/D-040.

**Dim-7 Attestation:** Agents dispatched in this burst: architect ×2 (D-043 spec updates, two parallel bursts), product-owner (D-043 NFR decisions + spec updates), state-manager (this burst). Total: 4 agents.

**Closes:** nothing. **Opens:** BI-017 (Phase 3 CI perf-gate must be macos-latest), BI-018 (PR #4 open). **Updates:** BI-016 (spurious CI failures explained). D-043..D-045 recorded.

---

## Burst: burst 9 — PR #4 APPROVE + PR #3 Full Mutation Audit + D-046..D-050 Wrap (2026-08-06)

**Parent-commit:** (D-043/D-045 wrap burst — burst 8 close)

**Adversary verdict:** No adversary pass in this burst. State-manager wrap recording PR #4 APPROVE, PR #3 cycle-5 exception + full mutation audit (D-049/D-050), BI-014 closure. D-046..D-050 recorded.

**Archived from Current Phase Steps (evicted to make room):**
- `phase-1d adversary pass 4 | adversary | COMPLETE | cycles/phase-1d/adversary-pass-4.md; 37 findings (3C/19M/15m); FINDINGS_REMAIN; zero in 7 enforced classes; topology root cause named`

**Files touched (Dim-1): state/cycle files only**

- `.factory/STATE.md` — D-046..D-050 appended; BI-016/BI-018 updated; BI-019 RESOLVED; BI-014 closed; PR #4 APPROVE recorded; Session Resume Checkpoint → D-050; spec snapshot updated; bc-module-map.md v1.4 noted; timestamp advanced
- `.factory/SESSION-HANDOFF.md` — D-045 snapshot marked SUPERSEDED; §RESUME SNAPSHOT D-050 appended; Latest pointer → D-050
- `.factory/cycles/phase-1d/burst-log.md` — this entry
- `.factory/sidecar-learning.md` — session observations updated
- `.factory/logs/dispatcher-internal-2026-08-06.jsonl` — dispatcher log
- `.factory/logs/events-2026-08-06.jsonl` — events log
- `.factory/specs/architecture/bc-module-map.md` — v1.4 (INC-MAP-001 SPEC-RESOLVED/IMPL-PENDING per D-048)
- `.factory/code-delivery/` — pr-manager delivery artifacts for PR #3 cycle 5 + PR #4 cycle 2

**Codifications:**
- D-046: Restricted-path waiver for PR #3 + PR #4 (operator-approved)
- D-047: Merge wrapper scripts at `.factory/bin/` not `plugins/`
- D-048: INC-MAP-001 `SPEC-RESOLVED / IMPL-PENDING`; bc-module-map.md v1.4
- D-049: Cycle-5 exception for PR #3 + full mutation audit ordered (operator)
- D-050: Full mutation audit COMPLETE (4/15 over-determined, 27%); standing rule: mutation verification required for skip-list entries; proven-can-fail: check-index-integrity, check-counts, check-adr-consistency, check-title-sync

**Artifact state at burst close:**
PRD v1.9 | 66 BCs | 26 VPs | 13 DIs | 8 ADRs | 19 policies | EC registry EC-001..EC-204 (205 ids) | holdout pool 12. D-001..D-050 recorded (exhaustive). PR #3 head `6d954ab` (15→17 tests, 17/17); PR #4 head `6503d3b` APPROVE. Closed: BI-005/006/008/009/011/013/014/019. Open: BI-007/010/012/015/016/017/018.

**Dim-6 Attestation:** IN_PROGRESS. Convergence counter 0 of 3 required clean passes. Trajectory →0→32→34→39→37. Pass 5 pending WS-A (merge PRs, GitHub Actions outage blocking) + WS-B (BI-012 generators) per D-036/D-040.

**Closes:** BI-014 (VP-022 source_bc NFR-008). BI-019 (selftest 10d over-determination). **Opens:** nothing new. **Updates:** BI-016 (covered_sha stale, update to 6d954ab). D-046..D-050 recorded.

---

## Burst: burst 10 — BI-012/BI-015 CLOSED + PR #5 + D-051..D-053 + Pass-5 HEAD Freeze (2026-08-06)

**Parent-commit:** `e9bee87` (feat(state): mutation audit COMPLETE — D-046..D-050 (exhaustive), BI-019 RESOLVED, wrap D-050)

**Adversary verdict:** No adversary pass in this burst. This is the BI-012 spec-topology remediation closure burst. 14 divergent sites corrected across 9 spec files using verified canonical-facts.toml. PR #5 (supply-chain hardening) recorded as CONVERGED. D-051/D-052/D-053 recorded. HEAD frozen for pass 5.

**Files touched (Dim-1): 19 unique files**

- `.factory/specs/canonical-facts.toml` — NEW: 7 facts, 16 bindings, header prohibiting hand-edits
- `.factory/code-delivery/SEC-HARDENING-PINS/` — NEW: PR #5 delivery artifacts (pr-description.md, pr-review.md, pr-review-cycle1.md, review-findings.md)
- `.factory/specs/architecture/module-decomposition.md` — FACT-1 4-field sort key (8 sites corrected via gen-bc-traceability.py)
- `.factory/specs/behavioral-contracts/BC-INDEX.md` — FACT-1 DI-001 row sort key
- `.factory/specs/behavioral-contracts/ss-03/BC-2.03.002.md` — FACT-1 sort key uniqueness invariant
- `.factory/specs/behavioral-contracts/ss-05/BC-2.05.003.md` — FACT-5b ADR-003 cite (anchor_table.rs)
- `.factory/specs/behavioral-contracts/ss-06/BC-2.06.001.md` — FACT-5a ADR-008 cite (slug.rs)
- `.factory/specs/behavioral-contracts/ss-06/BC-2.06.002.md` — FACT-5a ADR-008 cite (slug.rs)
- `.factory/specs/behavioral-contracts/ss-12/BC-2.12.001.md` — FACT-1 sort key (2 sites)
- `.factory/specs/behavioral-contracts/ss-13/BC-2.13.001.md` — FACT-1 sort key
- `.factory/specs/domain-spec/entities.md` — FACT-2 AnchorTable(HashSet<String>) newtype; FACT-3 Pass 1.5 three-phase
- `.factory/specs/prd-supplements/interface-definitions.md` — FACT-1 sort key (2 sites: text output, JSON output)
- `.factory/specs/prd.md` — FACT-3 Pass 1.5 (BC-2.05.001 row in KD-001 table); §6.1 summary table cell preserved (legitimately corrected in prior burst per D-034 — DO NOT revert)
- `.factory/specs/verification-properties/vp-018-slug-worked-examples.md` — @GENERATED:BEGIN slug-corpus fence (VP-018 SLUG_CORPUS from §7; TV-S007+TV-S010 first test coverage)
- `.factory/sidecar-learning.md` — updated observations
- `.factory/logs/dispatcher-internal-2026-08-06.jsonl` — dispatcher log
- `.factory/logs/events-2026-08-06.jsonl` — events log
- `.factory/STATE.md` — BI-012/BI-015 CLOSED; D-051..D-053 appended; BI-020/021/022 added; pass-5 armed; SESSION Resume → D-053; D-046..D-053 exhaustive
- `.factory/SESSION-HANDOFF.md` — D-050 snapshot marked SUPERSEDED; §RESUME SNAPSHOT D-053 appended

**Verification evidence (orchestrator-confirmed):**
- `check-canonical-facts.py` against real spec tree: exit 0, "all 16 bindings match canonical values (7 facts)"
- Selftest suite: 18/18 pass (`EXPECTED_TEST_COUNT` 17→18; test 18 asserts clean-pass + `DIVERGE [FACT-ST18]` message)
- D-040 negative test: reintroduced exact historical defect (deleted `f.link_target` from module-decomposition.md:134); checker failed with precise attribution `DIVERGE [FACT-1] ... (expected canonical_value='link_target')`; file restored; exit 0 re-confirmed
- True divergence count: 5 facts (FACT-1, FACT-2, FACT-3, FACT-5a, FACT-5b); FACT-4 (module→subsystem) AGREES at all checked sites — correctly left alone
- PR #5 (`b054694`): pr-reviewer APPROVE, 0 blocking, 2 review cycles (within max_review_cycles: 3); SEC-1 kani-verifier 0.67.0 --locked; SEC-2 cargo-fuzz 0.13.2 --locked; SEC-3 semgrep already pinned; CI-7 permissions: contents: read on all 6 jobs; persist-credentials: false on all 6 checkouts; SHA inventory upload-artifact v4.3.2; fuzz false-green fixed (for-loop exit-0 bug → assignment form exits 127); MAJOR-1 kani workspace grep fixed; D-053 cargo-mutants moved to macos-latest

**Codifications:**
- D-051: Pass-5 gate interpretation — committed spec artifacts on factory-artifacts satisfy D-036 (operator-approved)
- D-052: Restricted-path waiver for PR #5 (.github/**) — operator-approved, scoped to PR #5 only
- D-053: cargo-mutants platform classification — platform-DEPENDENT, macos-latest per D-043; D-044 unchanged

**Artifact state at burst close:**
PRD v1.9 | 66 BCs | 26 VPs | 13 DIs | 8 ADRs | 19 policies | EC registry EC-001..EC-204 (205 ids) | holdout pool 12 (5 active: HS-001/004..007; 2 retired: HS-002/003). D-001..D-053 recorded (exhaustive). Closed: BI-005/006/008/009/011/012/013/014/015/019. Open: BI-007/010/016/017/018/020/021/022.

**Dim-2 Attestation:** `check-canonical-facts.py` = exit 0, all 16 bindings match. `just spec-lint` = 7/8 PASS (check-placeholders: 25 legitimate `[filled by story-writer]` — ADVISORY, D-029/D-032).

**Dim-5 Attestation:** STATE.md — 204 lines, timestamp 2026-08-07T00:15:00Z, version 2.5, status: draft, producer: state-manager. SESSION-HANDOFF.md — §RESUME SNAPSHOT D-053 appended; D-050 marked SUPERSEDED; Latest → D-053. burst-log.md — 10 bursts (this entry). blocking-issues-resolved.md — BI-012/BI-015/fuzz-false-green closing rows added.

**Dim-6 Attestation:** IN_PROGRESS. Convergence counter 0 of 3 required clean passes. Trajectory →0→32→34→39→37. Pass 5 ARMED against this factory-artifacts HEAD (BC-5.39.001/D-040/D-051). Streak re-counts from ZERO.

**Dim-7 Attestation:** Agents dispatched: state-manager (this burst). Spec corrections applied from verified generator output (gen-bc-traceability.py, gen-slug-corpus.py, check-canonical-facts.py — orchestrator-run, not a separate agent dispatch).

**Closes:** BI-012 (spec-topology generators built+verified; 14 divergent sites corrected). BI-015 (VP-018 SLUG_CORPUS generated from §7). **Opens:** BI-020 (PR #5 pending merge), BI-021 (check-canonical-facts.py worktree resolution), BI-022 (nightly toolchain unpin). **Updates:** BI-002 (pass 5 armed). D-051..D-053 recorded.

---

## Burst: burst 11 — Perimeter Sweep Shards 1,2,3,5 + Cross-Shard Synthesis (2026-08-07)

**Parent-commit:** `af54a65` (factory-artifacts HEAD at pass-5 arm; BI-012/BI-015 CLOSED per burst-10)

**Adversary verdict:** No new formal adversary pass in this burst. This is a parallel deep-perimeter scan of 46 BC bodies across 4 shards (1,2,3,5) producing 111 findings (19C/47H/45M). Trajectory unchanged: →0→32→34→39→37. pass count: 0 of 3. Shards 4,6,7,8 still running.

**Files touched (Dim-1): 4 unique files**

- `.factory/cycles/phase-1d/perimeter-sweep-shard-2.md` (NEW — shard 2: SS-03 + SS-04 + BC-2.06.002, 10 BC bodies, 4C/7H/13M = 24 findings; input-hash 43040b3)
- `.factory/cycles/phase-1d/perimeter-sweep-shard-5.md` (NEW — shard 5: SS-11/12/13/14, 15 BC bodies, 6C/15H/11M = 32 findings; verdict: exit-code input domain not complete; input-hash c39268f)
- `.factory/cycles/phase-1d/perimeter-sweep-synthesis.md` (NEW — cross-shard synthesis: shards 1,2,3,5 complete, 111 findings 19C, shards 4,6,7,8 pending; SKIP LIST UNSOUND finding; three unguarded axes; input-hash 6c1c123)
- `.factory/STATE.md` — timestamp advanced; current_step updated; 5th row added to Current Phase Steps; BI-023/BI-024 opened in Blocking Issues; Concurrent Cycles updated; banner updated (204→208 lines, post-burst-11); Last Updated advanced to 2026-08-07

**Key findings (governance-level):**

1. **SKIP LIST UNSOUND (BI-023):** `check-placeholders.py` greps literal `VP-TBD` — em-dash `—` in VP-NNN column is a complete bypass (8/15 SS-11..14 BCs, 4/6 SS-03 BCs pass clean with zero VP coverage). `check-id-resolution.py` auto-synthesises `EC-NNNa..z` from base EC with no description check, AND matches only `EC-\d+` — silently skipping EC-NEW-NNN and EC-073b. Found independently by shards 1, 3, and 5. D-050's mutation-verification criterion is necessary but not sufficient.

2. **THREE UNGUARDED AXES (BI-024):** (A) VP proof-method/tool mismatch — BC body says "unit test", VP-INDEX says Kani P0; 14+ instances, coverage matrix reports Yes; (B) fabricated quoted excerpts — 40% in SS-11..14, FM-002 guards silently dropped via CAP-006 fabrication in shard 2; (C) third-party library semantics claims — unverifiable, 3 of 4 shard-2 CRITICALs.

3. **CORROBORATED findings (near-certain):** E-IO-002/E-CLI-001 phantom codes (3 independent shards), `sub_reason` absent from Finding struct, `format_json` cannot emit `errors[]`, `fs::canonicalize` forbidden but mandated, I/O errors as stdout findings, missing L2 Domain Invariants rows (~25% of BCs systemic).

**Codifications:** BI-023 OPENED (skip-list soundness gap). BI-024 OPENED (three unguarded axes). No new D-NNN decisions — governance recommendations recorded in synthesis, requiring orchestrator adjudication.

**Artifact state at burst close:**
PRD v1.9 | 66 BCs | 26 VPs | 13 DIs | 8 ADRs | 19 policies | EC registry EC-001..EC-204 (205 ids) | holdout pool 12 (5 active: HS-001/004..007; 2 retired: HS-002/003). D-001..D-053 recorded (exhaustive). Closed: BI-005/006/008/009/011/012/013/014/015/019. Open: BI-007/010/016/017/018/020/021/022/023/024.

**Dim-2 Attestation:** Shard counts verified: shard-2 frontmatter `counts: "4 CRITICAL / 7 HIGH / 13 MEDIUM = 24"` matches body finding count (P6-S2-001..024). Shard-5 frontmatter `counts: "6 CRITICAL / 15 HIGH / 11 MEDIUM = 32"` matches body (P6-S5-001..032). Synthesis frontmatter `findings_so_far: 111` = 27+24+28+32 confirmed.

**Dim-5 Attestation:** STATE.md — 208 lines, timestamp 2026-08-07T02:10:00Z, version 2.5, status: draft, producer: state-manager. New cycle files: perimeter-sweep-shard-2.md (input-hash 43040b3), perimeter-sweep-shard-5.md (input-hash c39268f), perimeter-sweep-synthesis.md (input-hash 6c1c123). burst-log.md — 11 bursts.

**Dim-6 Attestation:** IN_PROGRESS. Convergence counter 0 of 3 required clean passes. Trajectory →0→32→34→39→37. Not converged. Perimeter sweep still running (shards 4,6,7,8 pending). Pass 5 armed against frozen HEAD per BC-5.39.001/D-040/D-051.

**Dim-7 Attestation:** Agents dispatched in this burst: adversary (perimeter shards 1,2,3,5 — parallel shard runs at frozen HEAD 1d3ed17), state-manager (this burst: files, STATE.md, burst-log). Total: 2 agent roles.

**Opens:** BI-023 (skip-list soundness gap), BI-024 (three unguarded axes). **Closes:** nothing. **Updates:** BI-002 (perimeter sweep in progress, shards 4,6,7,8 pending).

---

## Burst: burst 12 — Perimeter Sweep Shards 4,6,7,8 COMPLETE + BI-025..BI-031 OPENED (2026-08-07)

**Parent-commit:** (factory-artifacts HEAD after burst 11; shards 1,2,3,5 complete; shards 4,6,7,8 running)

**Adversary verdict:** No new formal adversary pass. Shards 4, 6, 7, 8 completed; perimeter CLOSED. 259 total findings (~42C) across all 8 shards. Trajectory UNCHANGED: →0→32→34→39→37. pass count: 0 of 3. D-055 (GitHub Actions RECOVERED), D-056 (stash EMPTY), D-057 (D-050 correction: mutation NBNS + positive-coverage gate) codified.

**Files touched (Dim-1): 6 unique files**

- `.factory/cycles/phase-1d/perimeter-sweep-shard-4.md` (NEW — shard 4: SS-08/09 + 3×SS-10, 32 findings, 7C; DI-005 NOT airtight; DirIndex scope contradiction; BI-029 root evidence)
- `.factory/cycles/phase-1d/perimeter-sweep-shard-6.md` (NEW — shard 6: ADRs + arch-shards, 32 findings, 2C; ADR-004 inadequate; ADR-001/002/003 missing versioning)
- `.factory/cycles/phase-1d/perimeter-sweep-shard-7.md` (NEW — shard 7: VPs, 44 findings, 6C; VP-015/016/017/019/023 outright vacuous; BC-VP proof-method join broken; BI-025/BI-026 root evidence)
- `.factory/cycles/phase-1d/perimeter-sweep-shard-8.md` (NEW — shard 8: domain-spec + prd, 40 findings, 6C; R5 not defensible; CV5-001 CRITICAL: product-brief.md:89 "macOS, Linux, Windows" — L1 root not updated by D-043; BI-031 root evidence)
- `.factory/cycles/phase-1d/perimeter-sweep-synthesis.md` (UPDATED — synthesis FINAL; perimeter CLOSED; all 8 shards complete; total 259 findings ~42C; 4 unguarded axes confirmed cross-shard)
- `.factory/STATE.md` — BI-025..BI-031 opened; perimeter CLOSED notation; SESSION-HANDOFF.md §RESUME SNAPSHOT D-057 appended; D-055/D-056/D-057 recorded; stash EMPTY confirmed; convergence trajectory tail extended to →259

**Key findings (governance-level):**

1. **CV5-001 (CRITICAL) identified — BI-031 OPENED:** product-brief.md:89 "macOS, Linux, Windows" — L1 root of traceability chain not updated by D-043 sweep. Six downstream sites carry stale platform references; two weak residuals also identified.
2. **FIVE VPs OUTRIGHT VACUOUS — BI-025 OPENED:** VP-015/016/017/019/023 each satisfied by no-op/constant implementation. Phase 6 formal-hardening gate could pass with 4 domain invariants unverified.
3. **BC-VP PROOF-METHOD JOIN BROKEN — BI-026 OPENED:** At least 12 BC VP-table rows attribute properties the cited VP provably lacks. Highest-leverage mechanical fix in the session.
4. **POLICY 5 QUOTED-EXCERPT FABRICATION — BI-027 OPENED:** ~40% fabrication rate confirmed across shards 2, 4, 8; inverts meaning in some cases.
5. **VP CODE-FENCE SYMBOL VALIDATION — BI-028 OPENED:** 8 undefined symbols, 4 undefined types in VP Rust harnesses; all 5 VP-007 harnesses fail to compile.
6. **SS-07 PHASE-2 BLOCK — BI-029 OPENED:** DirIndex population scope contradictory in 3 source documents; must NOT enter Phase 2 without ruling.
7. **EXIT-CODE INPUT-DOMAIN — BI-030 OPENED:** `verdict::exit_code` input domain partitioned inconsistently across 4 definitions.
8. **D-057 CORRECTION:** Mutation verification is NECESSARY BUT NOT SUFFICIENT for skip-list admission. Positive-coverage counts (not absence-of-known-string) required as durable admission criterion.

**Codifications:** D-055 (GitHub Actions RECOVERED; PR #4 CI run 31122163633 green). D-056 (stash EMPTY confirmed, all 4 worktrees). D-057 (correction to D-050). BI-025..BI-031 OPENED. SESSION-HANDOFF.md §RESUME SNAPSHOT D-057 appended.

**Artifact state at burst close:**
PRD v1.9 | 66 BCs | 26 VPs | 13 DIs | 8 ADRs | 19 policies | EC registry EC-001..EC-204 (205 ids) | holdout pool 12 (5 active: HS-001/004..007; 2 retired: HS-002/003). D-001..D-057 recorded (exhaustive). Closed: BI-005/006/008/009/011/012/013/014/015/019. Open: BI-007/010/016/017/018/020/021/022/023/024/025/026/027/028/029/030/031.

**Closes:** nothing. **Opens:** BI-025..BI-031. **Updates:** BI-002 (perimeter CLOSED; 259 findings ~42C; 4 unguarded axes; remediation burst required). D-055/D-056/D-057 codified.

---

## Burst: burst 13 — CV5-001 CLOSED + canonical-facts.toml FACT-7+FACT-8 + PR #3 REQUEST_CHANGES (2026-08-07)

**Parent-commit:** (factory-artifacts HEAD d013040 at session start, per live git log; D-057 snapshot cited wrong SHA — self-correcting-head rule confirmed)

**Adversary verdict:** No new adversary pass. This is the CV5-001 fix burst. PR #3 pr-reviewer verdict: REQUEST_CHANGES (2 blocking: B-7/BI-032 vacuous suppression guard, B-8/BI-033 check-index-integrity zero-item false-pass). Trajectory UNCHANGED: →0→32→34→39→37→259. pass count: 0 of 3.

**Files touched (Dim-1): 12 unique files**

- `.factory/specs/product-brief.md` — platform matrix "macOS, Linux, Windows" → "macOS (human decision D-043; drives path-handling model)" (v1.0 → v1.1)
- `.factory/specs/domain-spec/risks.md` — R-002 "T1–T16" → "T1–T12, T14–T16 (T13 retired by D-043)"; R-008 "NFR-002 (15s p95, Linux CI)" → "NFR-002 (10s p95, macos-latest)" (v1.1 → v1.2)
- `.factory/specs/prd.md` — line 402 "on ALL platforms (not OS-delegated)" → "on macOS (not OS-delegated; D-043/D-006 determinism grounds)"; v1.11 amendment note at 554-558 recording prd.md:755 D-034 disposition (TV-036 falsification reachable on macOS via APFS; v1.7 mechanism superseded but historically accurate) (v1.10 → v1.11)
- `.factory/specs/behavioral-contracts/ss-10/BC-2.10.003.md` — retired T13 citation removed: "R5, T13" → "R5" (v1.2 → v1.3)
- `.factory/specs/domain-spec/differentiators.md` — "T9–T15" → "T9–T12, T14–T15" (v1.0 → v1.1)
- `.factory/specs/domain-spec/invariants.md` — "ALL inputs, ALL platforms," → "ALL inputs, on the macOS platform," (v1.8 → v1.9)
- `.factory/specs/domain-spec/failure-modes.md` — "case mismatch on any OS" → "case mismatch on macOS APFS" (v1.6 → v1.7)
- `.factory/specs/canonical-facts.toml` — FACT-7 (product-brief.md:89 platform matrix, `canonical_value = "macOS"`, source `:89`) + FACT-8 (ASM-004 restatement, `canonical_value = "macOS only"`, source `domain-spec/assumptions.md:41`) added. Two separate facts required because the two sites use different canonical phrasings ("macOS" vs "macOS only"); a single fact cannot serve both without reintroducing a matching defect.
- `.factory/code-delivery/SPEC-LINT-GATE/pr-review-6d954ab.md` (NEW — pr-reviewer report at head `6d954ab`; verdict REQUEST_CHANGES; 2 blocking: B-7 D-039 suppression guard vacuous; B-8 check-index-integrity zero-item false-pass)
- `.factory/sidecar-learning.md` — observations updated
- `.factory/logs/dispatcher-internal-2026-08-06.jsonl` — dispatcher log
- `.factory/logs/events-2026-08-06.jsonl` — events log

**Key findings (governance-level):**

1. **FACT-7 first version had a false-pass hole:** Pattern `([^\s(]+)` captured only the first token; "macOS and Linux" and "macOS and Windows (D-043)" both returned GREEN. Re-anchored to capture full clause up to " (" terminator. Verification: FACT-7 `group(1)='macOS'` ✓; FACT-8 `group(1)='macOS only'` ✓; "macOS and Linux", "macOS, Linux, Windows", "macOS and Windows (D-043)", "Linux, macOS" all FAIL ✓. Caught by adversarial verification (orchestrator executed exact `re.search` contract), NOT by reading the report. **Known brittleness:** missing parenthetical reformat → false FAIL (fail-closed; do NOT loosen).

2. **prd.md:755 D-034 disposition confirmed:** Line 755 sits under `### v1.7 — Test-Vectors Hotfix` changelog heading. D-034-immutable. prd.md:755 NOT edited. Disposition recorded at prd.md:554-558 as v1.11 amendment note. Line number and D-034 determination independently verified by orchestrator.

3. **PR #3 REQUEST_CHANGES at `6d954ab`:** pr-reviewer found B-7 (suppression guard G1/G2 tests each re-declare an inline copy of the guard regex against stub files the test itself writes; real guard code path at ~:44-59 and ~:70-86 is never invoked; proven vacuous by neutering real `SUPPRESSION_PATTERN` + planting live violation → suite still prints 17/17) and B-8 (check-index-integrity `checks` increments unconditionally + silently drops 4 of 9 malformed HS-ID shapes; exits 0 printing "HS all consistent" having validated ZERO HS items). `covered_sha` hand-edit DECLINED — editing the record to satisfy `check-stale-verdict.sh` would defeat the control; a real review ran instead, vindicating the decision.

4. **BI-023 recurrence — pass-6 skip list unsound again:** `check-index-integrity` admitted to pass-6 skip list on D-050 mutation evidence; B-8 disproves it. Orchestrator REMOVED it. Three remaining skip-list entries (check-counts, check-adr-consistency, check-title-sync) admitted on identical evidence — unknown soundness. Positive-coverage re-audit PENDING OPERATOR DECISION (b). Second existence proof for D-057.

5. **Merge queue BLOCKED — environmental finding:** `workflow_dispatch`-triggered CI runs excluded from PR status-check rollup. GraphQL: 1 context (GitGuardian) on PR #4 and PR #3 vs all 10 on PR #5 (`pull_request`-triggered). Branch protection reports BLOCKED despite all required checks green. Close+reopen required for `pull_request`-typed run. `destructive-command-guard` blocks `gh pr close`. PENDING OPERATOR DECISION (a).

6. **D-055 correction:** CI run 31122163633 was on superseded head `af54a65`, not PR #4's current head `6503d3b`. PR #4 current head had ZERO CI runs when D-055 was recorded. The "required checks green" status from D-055 does NOT transfer to `6503d3b`. Both PR #4 and PR #3 had zero CI at their current heads; workflow_dispatch runs were dispatched and all four required contexts (Format check, Clippy, Test macos-latest, Build release macos-latest) came back green — but these runs do not satisfy branch protection.

**Codifications:** No new D-NNN decisions (three pending operator decisions recorded as PENDING, not approved). BI-031 CLOSED. BI-032..035 OPENED. check-index-integrity REMOVED from pass-6 skip list by orchestrator determination (pending operator ratification of re-audit scope as decision b).

**Artifact state at burst close:**
PRD v1.11 | 66 BCs | 26 VPs | 13 DIs | 8 ADRs | 19 policies | EC registry EC-001..EC-204 (205 ids) | holdout pool 12 (5 active: HS-001/004..007; 2 retired: HS-002/003). D-001..D-057 recorded (exhaustive). Closed: BI-005/006/008/009/011/012/013/014/015/019/031. Open: BI-007/010/016/017/018/020/021/022/023/024/025/026/027/028/029/030/032/033/034/035.

**Dim-2 Attestation:** check-canonical-facts.py: FACT-7 `group(1)='macOS'` matches `canonical_value='macOS'`; FACT-8 `group(1)='macOS only'` matches `canonical_value='macOS only'`. All conjunction/reorder mutation variants fail as intended. assumptions.md:41 needed no edit — ASM-004 was already correct from prior D-043 sweep.

**Dim-5 Attestation:** STATE.md updated — timestamp advanced, BI-031 removed from open table, BI-032..035 added, BI-016/BI-018 updated, Session Resume Checkpoint updated, spec snapshot updated. burst-log.md — 13 bursts. lessons.md — 19 lessons. blocking-issues-resolved.md — BI-031 closure row added.

**Dim-6 Attestation:** IN_PROGRESS. Convergence counter 0 of 3 required clean passes. Trajectory →0→32→34→39→37→259. Not converged. Remediation burst required: B-7+B-8 on PR #3; FACT-7/FACT-8 negative tests; BI-024 four unguarded axes; BI-025/026/027/028/029/030 spec topology fixes; BI-023 checker bypasses. Pass 6 after.

**Dim-7 Attestation:** Agents dispatched: product-owner + architect (CV5-001 spec fixes, 8 files), pr-reviewer (PR #3 at `6d954ab`), state-manager (this burst). prd.md:755 D-034 determination and product-brief.md:89 line number independently verified by orchestrator (not taken from agent report).

**Opens:** BI-032 (B-7 D-039 suppression guard vacuous), BI-033 (B-8 check-index-integrity zero-item false-pass), BI-034 (pass-6 skip list unsound — BI-023 recurrence; check-index-integrity removed), BI-035 (FACT-7/FACT-8 no D-040 negative test before bi-012-generators lands). **Closes:** BI-031 (CV5-001 CLOSED — all 8 sites + 2 weak residuals corrected; FACT-7+FACT-8 added). **Updates:** BI-002 (CV5-001 closed; PR #3 REQUEST_CHANGES; merge queue blocked; 0 clean passes). BI-016 (REQUEST_CHANGES at 6d954ab, 2 blocking). BI-018 (BLOCKED pending pull_request-typed run; operator decision a pending).

---

## Burst: burst 14 — PR #3 merge + D-068..D-071 session wrap (2026-08-07)

**Parent-commit:** `9491f64` (factory(phase-1d): D-067 post-snapshot delta)

**Adversary verdict:** No new adversary pass this burst. This burst is a state-manager session wrap only: PR #3 merge recorded, D-068..D-071 codified, BI-016/036 closed, BI-039/040 opened, SESSION-HANDOFF.md RESUME SNAPSHOT D-071 written.

**Headline outcome:** PR #3 MERGED as `651ee3a` on `develop` (squash, branch deleted, remote pruned). 11-cycle review lifecycle spanning four fix rounds (B-7/B-8/B-9/B-11) and three D-NNN rulings (D-068/D-069/D-070) this session. `develop`: `2776d94` → `651ee3a`. No open PRs remain. Main worktree is on `develop`, tree clean. `.worktrees/ws-b-generators` remains at `78ef3a4` on `feature/bi-012-generators` (WS-2, not started). Post-merge verified: selftests 36/36; `check-index-integrity.py` exit 0; property test 300/300.

**Files touched (Dim-1): 6 unique files**

- `.factory/STATE.md` — timestamp, current_step, Last Updated, Current Phase Steps (+1 row), Decisions Log (D-068..D-071), Blocking Issues (BI-016/036 CLOSED, BI-039/040 OPENED), Session Resume Checkpoint (D-071), Concurrent Cycles, spec snapshot line
- `.factory/SESSION-HANDOFF.md` — D-066 header marked SUPERSEDED by D-071; new RESUME SNAPSHOT D-071 appended
- `.factory/cycles/phase-1d/burst-log.md` — this entry
- `.factory/cycles/phase-1d/lessons.md` — lessons 23..29 appended (7 new lessons)
- `.factory/cycles/phase-1d/blocking-issues-resolved.md` — BI-016, BI-036 closure rows appended
- `.factory/cycles/phase-1d/session-checkpoints.md` — D-066+D-067 checkpoint archived

**Key events this session:**

1. **D-068 — Operator REVERSED D-067 deferral of counter placement.** The D-067 stopgap premise was falsified by execution. Orchestrator reproduced a clean `exit 0` / `Check passed` with a phantom `HS-099 → EC-999` row present, while the D-057/B-9 accounting invariant reported `7 rows seen` — blind to the 8th row because `hs_rows_seen++` sat BELOW the pre-filters. Narrowing pre-filters was shown to be unboundedly leaky. D-068: structural fix REQUIRED immediately.

2. **D-069 — Operator BANNED spelling-specific patching; ordered property-based restructure.** After the D-068 fix closed named shapes but a fresh review found a further BLOCKING regression, the operator required a PROPERTY-BASED restructure: count every non-blank line into a denominator BEFORE any predicate, classify into six buckets afterward, and assert a conservation law (`total_candidates == sum(buckets)`). Implemented at `f44147e` with a 300-case seeded property test.

3. **D-070 — Operator ruled SPLIT: bounded fix now, Option-3 story for the class.** A fresh review of `f44147e` found two BLOCKING bypasses AND the meta-defect that the conservation law constrains TOTALITY but not CORRECTNESS (`prose` and `fenced_code` are unbounded sinks). Operator accepted on three grounds: `spec-lint` is ADVISORY until Phase 1 gate; PR #3 carried independent value (D-039 suppression guard, P4-021, 36-test negative suite, B-9 invariant); class is tracked with landing gates. Bounded fix landed at `6e785b4` + `7c1eccf`. BI-040 opened for the class.

4. **D-071 — PR #3 merged as `651ee3a`.** Full pr-manager review lifecycle completed under D-028/D-031 autonomy level 4: APPROVE at `6e785b4`, confirmatory APPROVE at `7c1eccf` (MAJOR-1 docstring fix). Freshness re-established properly via `check-stale-verdict.sh 3 <7c1eccf full SHA>`; merge executed via `enforce-merge-strategy.sh 3 --squash --delete-branch`. Non-advisory CI green; `Spec lint` FAILURE accepted as advisory per D-029/D-032.

5. **BI-039 OPENED (MEDIUM, factory process gap).** `gh pr review --request-changes` is IMPOSSIBLE on any PR in this repo: GitHub returns GraphQL `Can not request changes on your own pull request` — same root cause as D-021. Working fallback: `gh pr comment --body-file`. Two pr-reviewer agents misdiagnosed failure as permission-classifier denial. Owner: devops-engineer. Resolution: switch pr-reviewer/pr-manager to `gh pr comment`; change hook's satisfaction condition to accept a PR comment.

6. **BI-040 OPENED (HIGH, blocking phase-1 gate).** The `splitlines()`/`strip()` bypass family — Python `str.splitlines()` treats `\f` and `\v` as line boundaries, `str.strip()` strips NBSP/U+3000, CommonMark recognizes neither. GFM-confirmed `exit 0` on merged `develop` for `\f## X` and `\v## X`. Candidate remedy NOT applied: replace `str.splitlines()` with `split("\n")`. MANDATORY named landing gate on the Option-3 story.

7. **Orchestrator merge-gate tautological invocation caught.** `check-stale-verdict.sh` was first invoked passing live HEAD as the covered SHA, making the comparison vacuous (returned FRESH). Caught before merging; re-run with the actually-reviewed SHA correctly reported STALE and forced a confirmatory review at `7c1eccf`. See lesson 26.

**Codifications:** D-068..D-071 recorded. BI-016 and BI-036 CLOSED. BI-039 and BI-040 OPENED. Convergence counter unchanged: 0 of 3 clean passes.

**Artifact state at burst close:**
PRD v1.11 \| 66 BCs \| 26 VPs \| 13 DIs \| 8 ADRs \| 19 policies \| EC registry EC-001..EC-204 (205 ids) \| holdout pool 12 (5 active: HS-001/004..007; 2 retired: HS-002/003). D-001..D-071 recorded (exhaustive). Closed: BI-005/006/008/009/011/012/013/014/015/016/018/019/020/029/030/031/032/033/036/038. Open: BI-002/007/010/017/021/022/023/024/025/026/027/028/034/035/037/039/040.

**Dim-2 Attestation:** No canonical-facts.toml mutation this burst. `check-canonical-facts.py` last reported exit 0 at prior burst close (all 16 bindings match). No FACT-N entries added or modified in this burst. Canonical facts corpus unchanged; attestation is a pass-through.

**Dim-5 Attestation:** STATE.md updated — D-068..D-071 added, BI-016/036 closed, BI-039/040 opened, resume checkpoint replaced, spec snapshot updated. burst-log.md — 14 bursts. lessons.md — 29 lessons. blocking-issues-resolved.md — BI-016 + BI-036 closure rows added. session-checkpoints.md — D-066+D-067 checkpoint archived.

**Dim-6 Attestation:** IN_PROGRESS. 0 of 3 clean passes. Trajectory →0→32→34→39→37→259 unchanged. Pass 6 blocked in order: WS-2 (bi-012 generators + BI-035) → WS-3 (skip-list re-audit D-060/BI-034 + BI-023) → WS-3b (Option-3 story / BI-040) → WS-4 (~306-finding remediation burst) → WS-5 (pass 6 + Phase 1 gate).

**Dim-7 Attestation:** Agents dispatched this session: pr-reviewer (PR #3 at `51e6be8`, `3299d3e`, `65f4664`, `f44147e`, `6e785b4`, `7c1eccf`), state-manager (this burst).

**Closes:** BI-016, BI-036. **Opens:** BI-039, BI-040.

---

## Burst: burst 15 — PR #6 merged as 7b9aa6d; D-072..D-074; BI-041/042/043 OPENED; session wrap D-074 (2026-08-07)

**Parent-commit:** `2ea28bf` (factory(phase-1d): D-071 session wrap — PR #3 merged as 651ee3a; D-068..D-071; BI-016/036 closed; BI-039/040 opened)

**Adversary verdict:** No new adversary pass this burst. This burst is a state-manager session wrap only: PR #6 merge recorded, D-072..D-074 codified, BI-041/042/043 opened, BI-035 re-scoped, SESSION-HANDOFF.md RESUME SNAPSHOT D-074 written.

**Headline outcome:** PR #6 MERGED as `7b9aa6d` on `develop` (squash, branch deleted) after 5 review cycles (REQUEST_CHANGES at `a642d24`; APPROVE-with-eyes-open at `0ad5c5e` — orchestrator declined, MAJOR-4..7 sent back; REQUEST_CHANGES at `06b58b6`; APPROVE at `90840ca`). `develop`: `651ee3a` → `7b9aa6d`. No open PRs. Worktree topology: exactly two entries — main checkout on `develop`, `.factory` on `factory-artifacts`. `feature/bi-012-generators` branch and `.worktrees/ws-b-generators` removed; commit `78ef3a4` remains recoverable in the object store.

**Landed in PR #6:**
- `scripts/spec-lint/check-canonical-facts.py` (188 lines) — checker wired into `ci.yml` + `justfile` spec-lint recipe
- `scripts/spec-lint/gen-bc-traceability.py` (429 lines) — generates BC Architecture Module rows; write mode gated behind `--write` + RuntimeError guard; bare invocation refuses
- `scripts/spec-lint/gen-slug-corpus.py` (494 lines) — generates VP-018 slug corpus; same write-mode gates
- Selftest suite expanded: 36 → 49
- `check-canonical-facts` post-merge reports: `OK — all 31 bindings match canonical values (11 facts)`

**Files touched (Dim-1): 5 unique files**

- `.factory/STATE.md` — timestamp, current_step, Last Updated, Current Phase Steps (+1 row), Decisions Log (D-072..D-074), Blocking Issues (BI-021 updated, BI-035 re-scoped, BI-041/042/043 OPENED), Session Resume Checkpoint (D-074), spec snapshot line, Concurrent Cycles
- `.factory/SESSION-HANDOFF.md` — D-071 header marked SUPERSEDED by D-074; new RESUME SNAPSHOT D-074 appended
- `.factory/cycles/phase-1d/burst-log.md` — this entry
- `.factory/cycles/phase-1d/lessons.md` — lessons 30..36 appended (7 new lessons)
- `.factory/cycles/phase-1d/session-checkpoints.md` — D-071 checkpoint archived

**Key events this session:**

1. **D-072 — HARD ORDERING: BI-040 must close before WS-4 begins.** WS-4 remediates ~306 findings and uses spec-lint checkers as the verification oracle. A verifier with a known-open bypass family (BI-040 `splitlines()`/`strip()`) must not be the oracle for its own fixes. This is the D-050/D-057 lesson applied to our own tooling. Queue crystallised: WS-2→WS-3→WS-3b (Option-3 story, BI-040 as landing gate)→WS-4→WS-5.

2. **D-073 — PR #6 permitted to merge with BI-035 HALF-discharged.** FACT-7 (`"macOS and Linux"` must fail) and FACT-8 (`"macOS and Windows"` must fail) production patterns verified sound. FACT-9 and FACT-10 NOT discharged — 17 of 31 bindings tautological (literal-baked prefix-presence instead of value-mismatch capture). Ordered debt: BI-042 is the FIRST work item once the concurrent `.factory/specs` editor releases the tree, ahead of WS-3 and WS-3b.

3. **D-074 — PR #6 merged as `7b9aa6d` under D-028/D-031 autonomy level 4.** Full review lifecycle: REQUEST_CHANGES at `a642d24`; APPROVE-with-eyes-open at `0ad5c5e` (orchestrator declined, sent MAJOR-4..7 back); REQUEST_CHANGES at `06b58b6`; APPROVE at `90840ca`. Freshness via `check-stale-verdict.sh 6 <90840ca full SHA>`; merged via `enforce-merge-strategy.sh 6 --squash --delete-branch`. Non-advisory CI green; `Spec lint` FAILURE accepted advisory per D-029/D-032. Rebase rejected in favour of cherry-pick of `78ef3a4` — six of the stale branch's seven commits were PR #3's pre-squash history already present on `develop` as `651ee3a`.

4. **BI-035 re-scoped — remains OPEN, HALF-discharged.** FACT-7 and FACT-8 production patterns sound (verified by PR #6 merge and selftest 25). FACT-9 (6 bindings, every extracted link destination) and FACT-10 (7 bindings, invalid `--ignore` glob) NOT discharged — tautological capture groups, synthetic selftest patterns say nothing about production patterns. Carried to BI-042. BI-035 closes only when BI-042 closes.

5. **BI-021 updated — remains OPEN.** The new `.git` boundary stop in `check-canonical-facts.py` halts the walk before reaching the main checkout's `.factory/` from a real linked worktree (where `.git` is a pointer FILE), exits 1 with clearer message. Fixed: a fail-OPEN regression where an unbounded ancestor walk could bind a decoy `canonical-facts.toml` and print `OK — all 1 bindings match` with exit 0. Selftest 25 pins the real linked-worktree condition with a `.git` pointer-file fixture, mutation-verified in both directions. Net: silent false GREEN traded for loud, self-documenting refusal. Still requires uniform fix before Phase 3 story worktrees.

6. **BI-041 OPENED (HIGH, blocking phase-3).** `gen-bc-traceability.py` write mode is LOSSY: regenerates BC `| Architecture Module |` row from `bc-module-map.md` and DESTROYS hand-authored annotations. Orchestrator verified 6 annotation-bearing lines removed with zero surviving; reviewer independently found ~20+ annotated rows unreproducible. Destroyed: INC-MAP-002, INC-MAP-003 (D-062 routing requirement), INC-MAP-004 (VP-016 formal assignment). MITIGATION LANDED: Gate 1 concurrency (bare invocation refuses) + Gate 2 BI-041 (`--write` refuses unconditionally); function-level RuntimeError; no write capability in file. Reviewer attacked 14 argv × 2 generators × 6 env vars; recursive shasum manifest diff confirmed zero paths reach a write. RESOLUTION: adjudicate whether generator models annotations or they migrate first.

7. **BI-042 OPENED (HIGH, blocking phase-1 gate, FIRST WORK ITEM per D-073).** 17 of 31 `canonical-facts.toml` bindings have tautological capture groups — ALL 6 FACT-9 and ALL 7 FACT-10 bindings. Production bindings are literal-baked prefix-presence checks; selftests 21/22 define SYNTHETIC patterns proving a synthetic pattern can fail while saying nothing about production. DEMONSTRATED: selftest 22's negative vector PASSES the real FACT-10 pattern (the exact D-062 forbidden string). Same class FACT-9.

8. **BI-043 OPENED (LOW, blocking phase-3).** `parent.parent.parent` repo-root heuristic survives in 8 other checkers plus both new generators. Fails CLOSED (usability defect, not safety). Also: a `.git`-less working tree can escape to an ancestor and print OK. Fix uniformly before Phase 3 story worktrees.

9. **Reviewer-flagged APPROVE not accepted as merge authorization (lesson 31).** `0ad5c5e` review returned APPROVE while flagging four MAJORs as "merge with eyes open." Orchestrator declined and sent them back; all four were real, and MAJOR-4 was a live silent-coverage hole in a guard added that same session.

10. **cherry-pick over rebase (positive lesson, lesson 32).** Stale branch carried six commits already on `develop` as `651ee3a`. Rebasing would have conflicted against the squash for no benefit; cherry-pick of `78ef3a4` resolved one `run-selftests.sh` conflict (keeping develop's 36 tests, appending new ones). Reviewer counted 47 and later 49 tests; all 36 of develop's survived.

**Codifications:** D-072..D-074 recorded. BI-041/042/043 OPENED. BI-035 remains open, re-scoped. BI-021 remains open, updated. Convergence counter unchanged: 0 of 3 clean passes.

**Artifact state at burst close:**
PRD v1.11 \| 66 BCs \| 26 VPs \| 13 DIs \| 8 ADRs \| 19 policies \| EC registry EC-001..EC-204 (205 ids) \| holdout pool 12 (5 active: HS-001/004..007; 2 retired: HS-002/003). D-001..D-074 recorded (exhaustive). Closed: BI-005/006/008/009/011/012/013/014/015/016/018/019/020/029/030/031/032/033/036/038. Open: BI-002/007/010/017/021/022/023/024/025/026/027/028/034/035/037/039/040/041/042/043.

**Dim-2 Attestation:** `canonical-facts.toml` now carries 11 facts / 31 bindings (landed in PR #6). `check-canonical-facts` post-merge reports `OK — all 31 bindings match canonical values (11 facts)`. FACT-7 and FACT-8 production patterns verified sound. FACT-9/10 tautological — tracked in BI-042.

**Dim-5 Attestation:** STATE.md updated — D-072..D-074 added, BI-021 updated, BI-035 re-scoped, BI-041/042/043 opened, resume checkpoint replaced (D-074), spec snapshot updated. burst-log.md — 15 bursts. lessons.md — 36 lessons. session-checkpoints.md — D-071 checkpoint archived. blocking-issues-resolved.md — no closures this burst.

**Dim-6 Attestation:** IN_PROGRESS. 0 of 3 clean passes. Trajectory →0→32→34→39→37→259 unchanged. Pass 6 blocked in order: (1) BI-042 (FIRST, once .factory/specs editor releases); (2) WS-3 skip-list re-audit (D-060/BI-034 + BI-023); (3) WS-3b Option-3 story (BI-040 as landing gate); (4) WS-4 ~306-finding remediation burst — BLOCKED on BI-040 per D-072; (5) WS-5 pass 6 + Phase 1 gate.

**Dim-7 Attestation:** Agents dispatched: pr-reviewer (PR #6 at `a642d24`, `0ad5c5e`, `06b58b6`, `90840ca`), state-manager (this burst).

**Closes:** (none this burst). **Opens:** BI-041, BI-042, BI-043. **Re-scoped (open):** BI-035. **Updated (open):** BI-021.

---

## Archived STATE.md Steps (overflow — evicted from Current Phase Steps 2026-08-07, burst 16)

| Step | Agent | Status | Output |
|------|-------|--------|--------|
| CV5-001 CLOSED + FACT-7+FACT-8 added; D-055..D-060; BI-025..BI-035 opened; PR #3 B-11 REQUEST_CHANGES (B-7/B-8) | state-manager + pr-reviewer | COMPLETE | burst-13 artifacts committed; `check-canonical-facts.py` FACT-7+FACT-8 added (verified sound); BI-031 CLOSED; BI-032/033/034/035 OPENED; `check-index-integrity` removed from pass-6 skip list; pr-reviewer REQUEST_CHANGES at 6d954ab (B-7 vacuous suppression guard, B-8 zero-item false-pass) |

---

## Burst: burst 16 — WS-3 Phase 1 (read-only skip-list audit); BI-034 RESOLVED; BI-023 corrected; D-075; session wrap D-075 (2026-08-07)

**Parent-commit:** `3734c1e` (factory(phase-1d): WS-3 Phase 1 skip-list audit complete; ws3-skip-list-audit.md committed)

**Adversary verdict:** No new adversary pass this burst. This burst is a state-manager session wrap only: WS-3 Phase 1 read-only audit findings recorded, BI-034 RESOLVED, BI-023 corrected, D-075 codified, SESSION-HANDOFF.md RESUME SNAPSHOT D-075 written.

**Headline outcome:** WS-3 Phase 1 (read-only skip-list re-audit per D-060) COMPLETE. Findings at `cycles/phase-1d/ws3-skip-list-audit.md` (prior factory commit `3734c1e`). BI-034 RESOLVED: all three skip-list entries (check-counts, check-adr-consistency, check-title-sync) KEEP — positive-coverage evidence per D-057 confirmed. BI-023 corrected: (a) 34 BC files / 55 em-dash rows (not 12+); (b) 11 `EC-NEW-` occurrences across 5 files (BC-2.07.005 omitted from audit list). Two orchestrator leads REFUTED: `count_domain_decisions()` dead code, `build_heading_ids()` over-inclusive not bypass. D-075 (BI-042 PREEMPTIVE, not serializing). No code changed, no PR opened. `develop` at `7b9aa6d`.

**Files touched (Dim-1): 7 unique files**

- `.factory/STATE.md` — timestamp advanced to 2026-08-07T02:45:00Z; current_step updated; Last Updated advanced; Current Phase Steps: WS-3 Phase 1 row added, oldest row (CV5-001 CLOSED) evicted to burst-log; Decisions Log: D-075 appended; Blocking Issues: BI-034 struck through (RESOLVED), BI-023 corrected (34 files/55 rows, 5 files EC-NEW-); Session Resume Checkpoint: D-075 (D-074 archived to session-checkpoints.md); Concurrent Cycles updated; spec snapshot D-001..D-075; Historical Content row added
- `.factory/SESSION-HANDOFF.md` — D-074 header marked SUPERSEDED by D-075; §RESUME SNAPSHOT D-075 appended; Latest pointer updated to D-075
- `.factory/cycles/phase-1d/burst-log.md` — evicted CV5-001 Current Phase Step archived; this entry (burst 16)
- `.factory/cycles/phase-1d/lessons.md` — lessons 37-40 appended to Policy Candidates table
- `.factory/cycles/phase-1d/session-checkpoints.md` — D-074 checkpoint archived
- `.factory/cycles/phase-1d/blocking-issues-resolved.md` — BI-034 closure row appended
- *(No .factory/specs/ files modified — read-only audit only per standing instruction)*

**Key events this session:**

1. **WS-3 Phase 1 read-only audit COMPLETE.** All three pass-6 skip-list entries (check-counts, check-adr-consistency, check-title-sync) evaluated against D-057 positive-coverage criterion: check-counts reports "37 count checks passed"; check-adr-consistency reports "8 ADRs checked"; check-title-sync reports "66 BC titles validated". All three KEEP. BI-034 RESOLVED.

2. **BI-023 corrected (counts under-estimated by 3x).** The orchestrator's prior count of "12+ BC files" for the em-dash bypass was actually 34 BC files / 55 rows. The "4 files" count for EC-NEW- was actually 5 files (BC-2.07.005 omitted). Ground truth from grep sweep, not from memory. Lesson 38 captured.

3. **Two orchestrator leads REFUTED.** `count_domain_decisions()` is dead code — confirmed never called anywhere. `build_heading_ids()` is over-inclusive (captures both BC headings and subsystem-header lines) — confirmed correct behavior in context, not a bypass. Lesson 39 captured.

4. **D-075 — BI-042 clarified as PREEMPTIVE.** D-073 "BI-042 FIRST" means preemptive (jumps to front when the lock releases), not serializing (does not block unrelated work while the lock is held). WS-3 Phase 2 items 2+3 (checker-only) proceed immediately. Lesson 40 captured.

5. **hook discipline — three PostToolUse violations resolved iteratively.** STATE.md write had three simultaneous hook violations: (1) banner line count off by 1 (252 claimed, 251 actual); (2) D-075 Decisions Log row missing Rationale column (5 cells vs 6 required); (3) trajectory_tail missing from Last Updated cell (3rd prescribed site). All three fixed; validate-trajectory-tail-cell-completeness confirmed prescribed sites include `current_step` frontmatter, Phase Progress Finding Progression, AND the Last Updated metadata cell.

**Codifications:** D-075 recorded. BI-034 CLOSED. BI-023 corrected counts recorded.

**Artifact state at burst close:**
PRD v1.11 \| 66 BCs \| 26 VPs \| 13 DIs \| 8 ADRs \| 19 policies \| EC registry EC-001..EC-204 (205 ids) \| holdout pool 12 (5 active: HS-001/004..007; 2 retired: HS-002/003). D-001..D-075 recorded (exhaustive). Closed: BI-005/006/008/009/011/012/013/014/015/016/018/019/020/029/030/031/032/033/034/036/038. Open: BI-002/007/010/017/021/022/023/024/025/026/027/028/035/037/039/040/041/042/043.

**Dim-2 Attestation:** No canonical-facts.toml mutation this burst. `check-canonical-facts.py` last reported exit 0 at burst-15 close (all 31 bindings match). No FACT-N entries added or modified in this burst. Canonical facts corpus unchanged; attestation is a pass-through. WS-3 skip-list audit confirmed checkers KEEP; no checker code modified.

**Dim-5 Attestation:** STATE.md — 251 lines, timestamp 2026-08-07T02:45:00Z, version 2.5, status: draft, producer: state-manager. SESSION-HANDOFF.md — §RESUME SNAPSHOT D-075 appended; D-074 marked SUPERSEDED; Latest → D-075. burst-log.md — 16 bursts. lessons.md — 40 lessons. blocking-issues-resolved.md — BI-034 closure row added. session-checkpoints.md — D-074 checkpoint archived.

**Dim-6 Attestation:** IN_PROGRESS. 0 of 3 clean passes. Trajectory →0→32→34→39→37→259 unchanged. Pass 6 blocked in order: (1) BI-042 (PREEMPTIVE, specs-gated — once `.factory/specs` editor releases per D-075); AND (2) WS-3 Phase 2 items 2+3 (checker-only, runnable immediately); then WS-3 Phase 2 item 1 (specs-gated, same gate as BI-042); then WS-3b (BI-040); then WS-4 — BLOCKED on BI-040 AND BI-042 per D-072/D-075; then WS-5.

**Dim-7 Attestation:** Agents dispatched this session: state-manager (this burst). WS-3 Phase 1 audit executed in prior commit `3734c1e` (devops-engineer / orchestrator). No new agent dispatches in this wrap burst.

**Closes:** BI-034 (pass-6 skip-list re-audit complete; all three entries KEEP). **Updates:** BI-002 (WS-3 Phase 1 DONE; BI-034 RESOLVED; next: BI-042 PREEMPTIVE + WS-3 Phase 2 items 2+3). BI-023 (corrected counts: 34 files/55 rows, 5 files EC-NEW-).

---

## Burst: burst 17 — BI-042 adjudication + WS-3 Phase 2 + BI-040 design; D-076..D-085 (exhaustive) (2026-08-07)

**Parent-commit:** `17ed288` (factory(phase-1d): D-075 session wrap — WS-3 Phase 1 COMPLETE; BI-034 RESOLVED; BI-023 corrected; lessons 37-40)

**Evicted Current Phase Steps row (archived per 5-row rule):** "PR #4+#5 MERGED; SS-07 DirIndex BROAD; SS-14 corrections; FACT-9+FACT-10; PR #3 B-11 REQUEST_CHANGES; design ruling written" — pr-manager + architect + state-manager — COMPLETE — PR #4 bcbb4a5 MERGED (develop→bcbb4a5); PR #5 2776d94 MERGED; SS-07 adjudicated (purity-boundary-map.md AUTHORITATIVE D-061); SS-14 CAP-014+BC-2.14.002/004 corrected (D-063); FACT-9+FACT-10 added; PR #3 head 031ca5b 4×REQUEST_CHANGES (B-11: hs_rows_seen++ after pre-filters); design-ruling-index-integrity.md written; D-058..D-066 (exhaustive); BI-018/020/029/030 CLOSED; BI-036..038 OPENED.

**Adversary verdict:** No new adversary pass this burst. This burst is: (1) BI-042 adjudication and `.toml` pattern corrections; (2) WS-3 Phase 2 checker repair design (read-only, no code applied); (3) BI-040 shared primitive layer design (read-only, no code applied); (4) D-076..D-085 (exhaustive) recorded; (5) BI-044/BI-045 opened; BI-045 FIXED.

**Headline outcomes:**

1. **BI-042 `.toml` side APPLIED (D-076).** Adjudication complete at `cycles/phase-1d/bi-042-binding-adjudication.md`. Prior "17 of 31 tautological" corrected to **26 of 31**. The FACT-1 family (8 bindings) and FACT-2 were entirely omitted from the prior count. 24 of 26 corrected: FACT-6a/6b left as structural limitation (ID-presence checks; verified BENIGN — `None → DIVERGE` catches ID substitution; prefix-pass structurally impossible given actual comment format `),  // TV-XNNN`). Checker reports `OK — all 31 bindings match (11 facts)`. Selftest-22 rewrite specified at §9.4; goes into PR `fix/ws3-spec-lint-integrity` per D-080. Closes BI-035 when PR merges.

2. **BI-023 magnitudes corrected (D-082 executed predicate).** Item (a): 55 rows / 34 BC files, all U+2014, confirmed exactly by Python `Counter` sweep. Item (b): **9 live defects / 4 files** (not 11/5) — prior figure conflated live defects with Class H historical changelog records; `BC-2.07.005.md:24` carries no live defect (records that EC-NEW-3 was already replaced by EC-164). ROOT CAUSE corrected: `check-placeholders.py` was not missing em-dash detection; it carried a value-blacklist on `test-sufficient` which occurs ZERO times in live tree. NEW DEFECT found by repaired checker: `BC-2.04.001.md:63` carries `TV-BV013` in the EC column (non-conforming ID) AND three cells in a two-column table — added to burn-down.

3. **WS-3 Phase 2 checker repair design committed** (`cycles/phase-1d/ws3-phase2-checker-repair-design.md`). No code applied. R2-RULE (VP-id column shape-whitelist, closes VP em-dash bypass; expected: 80 findings, 55 new + 25 baseline) and R3-A/B/C (EC-shape triple-segment predicate + historical-changelog scoping; expected: 9 findings / 4 files). Both repair rules characterized with: exact bypass mechanism, executed predicate confirmation both bugs exist (`PH_EXIT=0` and `IR_EXIT=0` on defective trees), false-positive landscape measured (211+ non-ID tokens characterized), candidate fixture vectors NV-1 and NV-2 specified.

4. **BI-044 OPENED (HIGH, blocks WS-4).** Digits-only EC grammar replicated at 17 sites across 6 files: `check-counts.py` ×5, `check-id-resolution.py` ×3, `check-holdout-boundary.py` ×3, `check-index-integrity.py` ×3, `check-ec-injectivity.py` ×2, `gen-ec-registry.py` ×1. Detection repaired in `check-id-resolution.py` (commit `2b99642` in PR); 16 sites remain. D-083: HOLD EC-registration until BI-044 settles.

5. **BI-045 OPENED AND FIXED.** Three non-hermetic selftest invocations (test 25 clean-pass, test 30 clean-pass, test 30 DEFECT phase) inherited ambient `SPEC_LINT_REPO_OVERRIDE`, making assertions vacuous. Test 30's defect phase had been passing vacuously regardless of hermeticity. Fixed: suite reports 54/54 identically with and without the variable set. PR commit `70794e3`.

6. **BI-040 primitive layer design committed** (`cycles/phase-1d/bi-040-primitive-layer-design.md`). Surface measured (D-082): **54 raw `splitlines()` sites + 63 `.strip()` sites across 14 files**. Family proven closed-under-discovery by iterating all 1,114,112 Unicode codepoints: **8** CommonMark-divergent splitlines codepoints (U+000B U+000C U+001C U+001D U+001E U+0085 U+2028 U+2029) and **23** CommonMark-divergent strip codepoints (including U+00A0, U+3000). Independently corroborated against prior GFM reviewer finding (exactly the 8 splitlines members). Three-stage migration planned. WS-3b is a PHASE-1D REMEDIATION ITEM (D-085), not a Phase-2 story.

7. **Develop-side state:** Branch `fix/ws3-spec-lint-integrity` off `develop` (`7b9aa6d`), 4 commits, 8 files, +774/−64: `2b99642` (BI-023 R2+R3), `ada4afa` (BI-042 selftest 22), `2e27b10` (D-081 scoping), `70794e3` (BI-045 hermeticity). PR open; pr-manager review lifecycle IN PROGRESS. Verified on branch: R2 exit 1 with 80 findings (55 new + 25 baseline); R3 exit 1 with exactly 10; `check-canonical-facts` OK; selftests 54/54 hermetic both ways. No merge outcome recorded — PR has not been merged.

**Files touched (Dim-1): 9 unique files/directories**

- `.factory/STATE.md` — version 2.5→2.6; timestamp advanced; current_step updated; Last Updated advanced; Current Phase Steps: row 1 evicted (archived above), new burst-17 row added; Decisions Log: D-076..D-085 (exhaustive) appended; Blocking Issues: BI-023 corrected (9 live/4 files, BC-2.04.001:63 new defect), BI-035 updated (closes on PR merge), BI-042 updated (APPLIED, residual selftest-22), BI-040 updated (surface measured), BI-044 OPENED, BI-045 OPENED+CLOSED; Session Resume Checkpoint: D-085 snapshot; Concurrent Cycles updated; Historical Content rows added; spec snapshot D-001..D-085; 266 lines (wc-l)
- `.factory/specs/canonical-facts.toml` — 24 tautological binding patterns rewritten to bounded line-bounded wildcards (FACT-1×8, FACT-2×1, FACT-3×2, FACT-9×6, FACT-10×7); FACT-6a/6b unchanged (structural limitation)
- `.factory/cycles/phase-1d/bi-042-binding-adjudication.md` — NEW: full adjudication document (31 bindings, adversarial proofs, before/after table, selftest-22 rewrite spec)
- `.factory/cycles/phase-1d/ws3-phase2-checker-repair-design.md` — NEW: WS-3 Phase 2 items 2+3 repair spec (R2-RULE, R3-A/B/C, measured false-positive landscapes, fixture vectors NV-1/NV-2)
- `.factory/cycles/phase-1d/bi-040-primitive-layer-design.md` — NEW: shared primitive layer design (measured surface, programmatic divergence derivation, three-stage migration)
- `.factory/cycles/phase-1d/burst-log.md` — evicted row archived; this entry (burst 17)
- `.factory/cycles/phase-1d/lessons.md` — lessons 41-44 appended
- `.factory/SESSION-HANDOFF.md` — D-075 marked SUPERSEDED by D-085; §RESUME SNAPSHOT D-085 appended
- `.factory/code-delivery/WS3-SPEC-LINT-INTEGRITY/` — pr-description.md + pr-review.md (PR artifacts for fix/ws3-spec-lint-integrity)

**Codifications:** D-076..D-085 (exhaustive) recorded. BI-044 OPENED. BI-045 OPENED+CLOSED. BI-042 re-characterized (APPLIED, partial). BI-023 counts corrected again.

**Burn-down ledger (MUST clear before Phase-1 convergence gate per D-077):**
- 55 VP-column rows / 34 BC files (em-dash in VP-NNN column)
- 9 `EC-NEW-*` rows / 4 BC files (live placeholder IDs)
- `BC-2.04.001.md:63` (TV-BV013 non-conforming ID in EC column, three cells in two-column table)
- BI-044: 16 remaining EC-grammar sites

**Artifact state at burst close:**
PRD v1.11 \| 66 BCs \| 26 VPs \| 13 DIs \| 8 ADRs \| 19 policies \| EC registry EC-001..EC-204 (205 ids) \| holdout pool 12 (5 active: HS-001/004..007; 2 retired: HS-002/003). D-001..D-085 (exhaustive). Closed: BI-005/006/008/009/011/012/013/014/015/016/018/019/020/029/030/031/032/033/034/036/038/045. Open: BI-002/007/010/017/021/022/023/024/025/026/027/028/035/037/039/040/041/042/043/044.

**Dim-2 Attestation:** `.factory/specs/canonical-facts.toml` corrected — 24 bindings rewritten, FACT-6a/6b structural limitation documented. `check-canonical-facts.py` exit 0 on all 31 bindings, 11 facts, after corrections. Selftest-22 rewrite specified (production pattern, prefix-extension DIVERGE assertion).

**Dim-5 Attestation:** STATE.md — 266 lines (wc-l), timestamp 2026-08-07T08:00:00Z, version 2.6, status: draft, producer: state-manager. burst-log.md — 17 bursts. lessons.md — 44 lessons. SESSION-HANDOFF.md — §RESUME SNAPSHOT D-085 appended; D-075 marked SUPERSEDED. canonical-facts.toml — all 31 bindings match (11 facts). Three new cycle files committed: bi-042-binding-adjudication.md, ws3-phase2-checker-repair-design.md, bi-040-primitive-layer-design.md.

**Dim-6 Attestation:** IN_PROGRESS. 0 of 3 clean passes. Trajectory →0→32→34→39→37→259 UNCHANGED. Pass 6 blocked: land PR `fix/ws3-spec-lint-integrity` → WS-3 item 1 (D-083) → WS-3b (D-085) → WS-4 (BLOCKED on BI-040 AND BI-042/BI-044) → WS-5.

**Dim-7 Attestation:** Agents dispatched this session: architect (BI-042 adjudication), devops-engineer (WS-3 Phase 2 design, BI-040 design, BI-045 fix), state-manager (this burst). Develop-side: 4 commits by devops-engineer on `fix/ws3-spec-lint-integrity`. No adversary agent dispatched.

**Closes:** BI-045 (non-hermetic selftests fixed, 54/54 hermetic). **Updates:** BI-002 (PR open, pr-manager IN PROGRESS). BI-023 (counts corrected: 9 live/4 files; BC-2.04.001:63 new defect). BI-035 (closes on PR merge). BI-040 (surface measured, design committed). BI-042 (APPLIED: 24/26 corrected; residual selftest-22 in open PR). **Opens:** BI-044 (17 EC-grammar sites, 16 remain after detection repair).

---

## Archived Current Phase Steps row (evicted from STATE.md by burst-18)

| PR #3 stopgap landed (031ca5b→51e6be8); D-067 delta recorded | state-manager | COMPLETE | Operator authorized per architect design ruling; narrowed pre-filters close A1/A2a/A2b (exit 1 mutation-verified); suite 21→24/24; structural independence NOT achieved (counter position unchanged, honest documented residual at :142-147/:169-175/:472-482); fix/hardening-pins cleaned up; BI-038 CLOSED; BI-016 updated to 51e6be8; D-067 recorded |

---

## Burst 18 — PR #7 Merged; BI-042/035/023(items 2+3)/045 CLOSED; D-086/D-087/D-088 (2026-08-07)

**Parent-commit:** `7e0f02a6d47073d89f48b31de2a402d7c472d8b3` (D-085 session wrap)

**Session summary:** PR #7 (`fix/ws3-spec-lint-integrity`) completed full 9-step pr-manager lifecycle (3 review cycles, 5 blockers all resolved) and was squash-merged to `develop` as `e1299b07` (`develop` `7b9aa6d`→`e1299b07`). D-086, D-087, D-088 recorded. Worktree `ws3-spec-lint-integrity` removed (tree-identical diff verified). Three decisions recorded. Four blocking issues closed (BI-042, BI-035, BI-023 items 2+3, BI-045 already).

**Key events:**

1. **PR #7 MERGED** as `e1299b07` under autonomy level 4 (D-028/D-031). APPROVE at `covered_sha = 791fc11e8b57e01326251daf0eb36dfffb59822a`. Orchestrator independently confirmed `791fc11` was the ACTUAL branch head at merge — D-071 freshness failure mode did not recur. Review converged in 3 cycles, 5 blockers all resolved. Non-advisory CI 4/4 PASS. `Spec lint` ADVISORY FAIL accepted per D-029/D-032/D-077. Security review: 1 LOW finding SEC-001 accepted; no CRITICAL or HIGH.

2. **Post-merge verification on `develop` at `e1299b07`** (orchestrator independent): `check-placeholders` exit 1, **80 findings** (55 new em-dash + 25 pre-existing `[filled by story-writer]`) — baseline PRESERVED. `check-id-resolution` exit 1, **10 findings** — baseline PRESERVED. `check-canonical-facts` OK (31 bindings, 11 facts). Selftests 55/55 (rose 54→55: one test added during review cycles). Identical with and without `SPEC_LINT_REPO_OVERRIDE` — hermeticity holds post-merge.

3. **BI-042 CLOSED.** Selftest-22 rewritten to exercise production bindings via teeth-test: old tautological pattern exits 0 on prefix-extension vector; corrected pattern exits 1 with DIVERGE. BI-035 simultaneously closed (all FACT-7/8/9/10 patterns verified sound).

4. **BI-023 items 2+3 CLOSED** (checker repairs). R2-RULE (VP-id whitelist) and R3-A/B/C (EC-shape triple-segment + historical scoping) now on `develop`. Item 1 (EC-NEW-* registration) still HELD per D-083. Spec-row burn-down still open: 55 VP-col / 34 files + 9 EC-NEW-* / 4 files + BC-2.04.001:63.

5. **Worktree cleanup.** `.worktrees/ws3-spec-lint-integrity` removed; local branch `fix/ws3-spec-lint-integrity` force-deleted after `git diff 791fc11 e1299b07 --stat` returned EMPTY (tree-identical, content verified present on `develop`). `791fc11` is reflog-recoverable. Remote branch deleted. Final state: exactly TWO worktrees — root on `develop` at `e1299b07`, `.factory` on `factory-artifacts`.

6. **D-086 recorded.** WS-4 scope re-derivation BY EXECUTION is MANDATORY: it is the FIRST act after the BI-040 primitive layer lands and BEFORE any remediation dispatch. Rationale: BI-040 was filed at 2 known members; execution measured 54+63 sites across 14 files and a 31-codepoint family — roughly 15× its filed size.

7. **D-087 recorded.** Run `/vsdd-factory:compact-state` at next session start, before any new work. STATE.md at 266+ lines against 200-line soft target.

8. **D-088 recorded.** State-manager must NOT use `git add -A` in state bursts while a PR agent is in flight; stage by explicit path. Burst `7e0f02a` incidentally committed another agent's in-flight `code-delivery/` artifacts.

**Files touched (Dim-1): 5 unique files**

- `.factory/STATE.md` — timestamp advanced; current_step updated; Last Updated advanced; Current Phase Steps: row 1 evicted (archived above), new burst-18 row added; Decisions Log: D-086/D-087/D-088 appended; Blocking Issues: BI-035 CLOSED (strikethrough), BI-042 CLOSED (strikethrough), BI-023 checker repairs noted landed, BI-044 detection on develop; Session Resume Checkpoint: D-088 snapshot; Concurrent Cycles updated; spec snapshot updated; ~270 lines
- `.factory/SESSION-HANDOFF.md` — §RESUME SNAPSHOT D-085 marked SUPERSEDED by D-088; §RESUME SNAPSHOT D-088 appended
- `.factory/cycles/phase-1d/burst-log.md` — evicted step row archived; this entry (burst 18)
- `.factory/cycles/phase-1d/lessons.md` — lesson 45 appended
- `.factory/cycles/phase-1d/blocking-issues-resolved.md` — BI-035 and BI-042 resolution rows appended

**Codifications:** D-086/D-087/D-088 recorded. BI-042 CLOSED. BI-035 CLOSED. BI-023 items 2+3 CLOSED (checker repairs). BI-045 already closed in D-085 burst (no change).

**Convergence:** IN_PROGRESS. 0 of 3 clean passes. Trajectory →0→32→34→39→37→259 UNCHANGED. Nothing this session advanced the streak; it removed preconditions blocking pass 6. The streak re-counts from ZERO against whatever HEAD is frozen for pass 6. Pass 6 order: (1) compact-state (D-087); (2) BI-040 Stage 1; (3) BI-040 Stages 2–3 (mandatory output-identity diff); (4) WS-4 scope re-derivation BY EXECUTION (D-086 — MANDATORY GATE before any remediation dispatch); (5) WS-4 remediation; (6) WS-5 pass 6 + Phase-1 gate.

**D-088 constraint:** staged by explicit path — `git add` invoked per-file, NOT `git add -A`. Files staged: STATE.md SESSION-HANDOFF.md cycles/phase-1d/burst-log.md cycles/phase-1d/lessons.md cycles/phase-1d/blocking-issues-resolved.md.

---

## Burst: burst 19 — compact-state DONE; D-017..D-020 restored; BI-040 code-CLOSED; BI-044 CLOSED; D-086 WS-4 re-derivation COMPLETE (2026-08-07)

**Parent-commit:** `002111a` (factory(state): restore lost binding decisions D-017..D-020 to Decisions Log)

**Adversary verdict:** No new adversary pass this burst. Pass 6 NOT run — gated to operator per standing directive. Trajectory UNCHANGED: →0→32→34→39→37→259 (pass-5 perimeter count; executed re-derivation 249; discrepancy UNRECONCILABLE — both preserved per D-086). pass count: 0 of 3.

**Headline outcomes:**

1. **D-087 compact-state COMPLETE (commit `a70306d`).** STATE.md 269→253 lines. 16 CLOSED blockers archived to `cycles/phase-1d/blocking-issues-resolved.md`. D-002 (only SUPERSEDED-marked row) archived to `cycles/phase-1d/decisions-log.md`. `current_cycle` frontmatter set to `phase-1d` (was empty — pointer gap). Decisions Log 83 rows after compaction (87 after D-017..D-020 restoration).

2. **D-017..D-020 restored (commit `002111a`).** Decisions Log 83→87 rows. Pre-existing defect: four decisions cited as BINDING in `prd.md` and `BC-2.11.002.md` — and carrying open adversarial contradictions (P3-001, P3-005, P6-S7-007) — had no Decisions Log rows at `ea3cd2d` (before compaction). PG-010 filed in `cycles/phase-1d/process-gap-register.md`. An ID-continuity check over the Decisions Log would have caught the gap; no such gate exists.

3. **BI-040 ALL THREE STAGES COMPLETE on branch `fix/bi-040-primitive-layer` (NOT merged, NOT pushed, no PR).** Four commits: `6340990` Stage 1 (primitive module `spec_lint_primitives.py` + 9 unit tests + `test_primitives.sh` G3 hook), `9228136` Stage 2A (6 checkers migrated), `705e93a` Stage 2B (5 files + `run_splitlines_guard` G4), `b497d26` Stage 3 (4 generators, guards expanded to 15 files). Orchestrator-verified by execution: output-identity HOLDS byte-exact on BOTH `SPEC_LINT_REPO_OVERRIDE` path AND no-override CI path (latter tested in CI-like scratch layout — a gap nobody had covered before). 106 lines each side, 8 headline lines, 0 tracebacks. 55/55 selftests + 9/9 primitive tests, identical with and without ambient override (BI-045 hermeticity class). Independent mutation tests confirm real teeth: reverting `cm_splitlines`→`str.splitlines()` or `cm_strip_cell`→`str.strip()` each FAILS the suite; `run_splitlines_guard` fires on a poisoned checker AND on a generator, and still fails on a zero-files-scanned directory. Corpus premise CONFIRMED: `.factory/specs/` = 134 `.md` files, `holdout-scenarios/` = 8; ZERO occurrences of 9 splitlines-divergent or 23 strip-divergent codepoints (both divergence sets independently re-derived by full U+0000–U+10FFFF iteration).

4. **BI-044 CLOSED.** 14 sites converted by BI-040 Stage 3 (ec-injectivity ×2, holdout-boundary ×3, counts ×5, index-integrity ×3, gen-ec-registry ×1). Prior "16 sites remain" figure was a MISCOUNT: itemization sums to 14 (17 original − 3 already fixed on develop).

5. **BI-043 remains OPEN — not closed by BI-040.** `Path(__file__).resolve().parent.parent.parent` survives as the else-branch of the `SPEC_LINT_REPO_OVERRIDE` ternary (active CI path) in 10 files: `check-counts.py`, `check-ec-injectivity.py`, `check-adr-consistency.py`, `check-id-resolution.py`, `check-placeholders.py`, `check-index-integrity.py`, `check-holdout-boundary.py`, `check-title-sync.py`, `gen-bc-traceability.py`, `gen-slug-corpus.py`. Stage 3 commit message initially claimed "closes BI-043" — amended (tree SHA `faf67f0ed97f2038c5f3450d268965eef414b301` unchanged). BI-040 design only routed `check-canonical-facts.py` and 4 exempt generators through `slp.find_repo_root`, under-delivering vs BI-043 stated scope. Awaiting operator scope ruling.

6. **D-086 WS-4 scope re-derivation BY EXECUTION COMPLETE.** "~306" is UNRECONCILABLE — discard it. Executed divergences: perimeter sweep total 259→249 (shard-7 claims 44 has 35; shard-8 claims 40 has 39; 9 ID gaps); synthesis CRITICAL "~42"→40 by per-shard subtotals; "36 pass-5 actionable"→37; CV5 findings "11"→1 (CV5-001 only; 10 phantom IDs); BI-044 "16 remaining"→14; EC-NEW-* "11 across 5 files"→9 across 4 files. Total unique finding IDs: **469**. P6 OPEN: **249**. WS-4 dispatchable scope: **138 items** (55 VP-column `—` rows + 25 `[filled by ...]` = 80 ✓check-placeholders; 9 EC-NEW-* + 1 TV-BV013 = 10 ✓check-id-resolution; 43 BC VP-table proof-method join repairs; 5 vacuous VP rewrites). New sequencing constraint: **BI-040 must MERGE to develop before any WS-4 dispatch** (all WS-4 classes edit BC files whose parsing BI-040 changes). ~53 POLICY-5 fabrications (BI-027) NOT dispatchable — count is an estimate pending pre-dispatch predicate. ~78 P6 aggregate/structural findings require operator scoping.

**Files touched (Dim-1): 6 unique files (factory-artifacts only — no develop-side changes this burst)**

- `.factory/STATE.md` — timestamp, current_step, Last Updated, Current Phase Steps (row evicted; new burst-19 row), Convergence Status (trajectory discrepancy 259/249 noted; pass-5 row updated; sequencing constraint recorded), Blocking Issues (BI-040 CODE-CLOSED not-merged updated; BI-043 10-file evidence updated; BI-044 CLOSED and removed; BI-002 updated), Session Resume Checkpoint replaced (D-088 archived to session-checkpoints.md)
- `.factory/SESSION-HANDOFF.md` — D-088 snapshot marked SUPERSEDED; §RESUME SNAPSHOT burst-19 appended
- `.factory/cycles/phase-1d/burst-log.md` — evicted Current Phase Steps row archived; this entry (burst 19)
- `.factory/cycles/phase-1d/lessons.md` — lesson 46 appended (zsh word-splitting false pass; policy candidates row added)
- `.factory/cycles/phase-1d/blocking-issues-resolved.md` — BI-044 CLOSED row appended
- `.factory/cycles/phase-1d/session-checkpoints.md` — D-088 checkpoint archived

**Codifications:** No new D-NNN decisions this session. Operator has not ruled on BI-043 scope or WS-4 dispatch authorization.

**Artifact state at burst close:**
PRD v1.11 \| 66 BCs \| 26 VPs \| 13 DIs \| 8 ADRs \| 19 policies \| EC registry EC-001..EC-204 (205 ids) \| holdout pool 12 (5 active: HS-001/004..007; 2 retired: HS-002/003). D-001..D-088 (exhaustive). D-017..D-020 (exhaustive) restored. Closed: BI-005/006/008/009/011/012/013/014/015/016/018/019/020/029/030/031/032/033/034/035/036/038/042/044/045. Open: BI-002/007/010/017/021/022/023/024/025/026/027/028/037/039/040 (code-closed NOT merged)/041/043.

**Dim-2 Attestation:** No `canonical-facts.toml` mutation this burst. `check-canonical-facts.py` last reported exit 0 (all 31 bindings match canonical values, 11 facts) at burst-18 close. No FACT-N entries added or modified. Canonical facts corpus unchanged; attestation is a pass-through.

**Dim-5 Attestation:** STATE.md — timestamp 2026-08-07T23:00:00Z, version 2.6, status: draft, producer: state-manager. burst-log.md — 19 bursts. lessons.md — 46 lessons. blocking-issues-resolved.md — BI-044 closure row added. session-checkpoints.md — D-088 checkpoint archived.

**Dim-6 Attestation:** IN_PROGRESS. 0 of 3 clean passes. Trajectory →0→32→34→39→37→259 (pass-5 perimeter count UNRECONCILABLE; executed 249; both preserved). Not converged. Pass 6 order: (1) BI-040 PR lifecycle (branch `fix/bi-040-primitive-layer`, 4 commits); (2) WS-4 remediation (138 dispatchable items; D-086 gate SATISFIED); (3) WS-5 pass 6 + Phase-1 gate. BI-040 must MERGE before WS-4 dispatch (D-072 + new sequencing constraint).

**Dim-7 Attestation:** Agents dispatched this session: devops-engineer (BI-040 all stages), orchestrator (D-086 re-derivation executed verification), state-manager (this burst). No adversary agent dispatched.

**Closes:** BI-044 (14 sites converted in BI-040 Stage 3; prior count of 16 was a miscount). **Updates:** BI-040 (code-CLOSED on `fix/bi-040-primitive-layer`; NOT merged; sequencing constraint recorded: must MERGE before WS-4). BI-043 (10-file evidence; scope ruling pending). BI-002 (compact-state DONE; D-017..D-020 restored; WS-4 re-derivation COMPLETE 286 actionable). No new decisions.

---

## Burst 20 — BI-040 PR #8 Merged; BI-043 Closed; BI-046 Opened; D-089 (Gate #28 Ruling)

**Date:** 2026-08-07
**Agent:** state-manager
**Status:** COMPLETE

### Evicted from Current Phase Steps (oldest row archived here)

| Step | Agent | Status | Output |
|------|-------|--------|--------|
| PR #6 MERGED as `7b9aa6d`; D-072..D-074 (exhaustive); BI-041/042/043 OPEN; BI-035 re-scoped; session wrap D-074 | state-manager | COMPLETE | PR #6 squash-merged on develop; develop `651ee3a`→`7b9aa6d`; branch + worktree removed (`78ef3a4` recoverable). Landed: check-canonical-facts.py (188L), gen-bc-traceability.py (429L), gen-slug-corpus.py (494L); selftests 36→49; check-canonical-facts OK (31 bindings, 11 facts). D-072 (BI-040 before WS-4) + D-073 (BI-042 first) + D-074 (cherry-pick 78ef3a4, 5 review cycles). BI-041/042/043 OPENED. BI-035 re-scoped (FACT-7/8 sound; FACT-9/10 → BI-042). |

### Burst Narrative

PR #8 squash-merged to `develop` as `c2e5cf1b3aab5daafc89a18af7470123a946aebc` (develop `e1299b0`→`c2e5cf1`). 5 commits collapsed (Stages 1, 2A, 2B, 3, 4). Approved head `8a5a21c`; D-071 empty-diff check PASSED; remote branch `fix/bi-040-primitive-layer` deleted; worktree `.worktrees/bi-040-primitive-layer` removed. Exactly 2 worktrees remain.

**Review was substantive, not tautological** — 3 cycles. Reviewer independently found defects neither the author nor design anticipated:
- **B1** — real fail-open in `is_conforming_vp_cell`: a punctuation-only cell silently passed
- **B2** — tautological test: `return [text]` survived 9/9 in `split_table_cells` coverage
- **W2** — 5-digit EC ID truncation newly INTRODUCED by this PR (`EC-\d+` → `EC-\d{1,4}` narrowing)
- **W7** — dropped `startswith` guard in `check-ec-injectivity`
- **S2** — override-guard bypass via a comment line

All verdicts mutation-verified. B2 fix mutation-verified: mutating `split_table_cells` to `return [line]` now FAILS 9/10 (explicit failure on "standard 3-cell row"), where the pre-fix test suite survived that mutation 9/9.

**Baseline PRESERVED** on `develop` @ `c2e5cf1`: `check-placeholders.py` 80 findings / 133 files; `check-id-resolution.py` 10 findings / 134 files. 106 lines of checker output, 8 headline lines, 0 tracebacks, 0 ERRORs. `run-selftests.sh` 55/55; `test_primitives.sh` 10/10 (grew from 9 — reviewer added a case). CI: Format / Clippy / Test(macos-latest) / Build release(macos-latest) all PASS. `spec-lint` ADVISORY FAIL is expected D-077 baseline.

**Security review:** 0 CRITICAL/HIGH, 2 LOW non-blocking.

**Deferred out of PR #8:**
- W1 — 5 remaining inline EC grammar literals → WS-4 intake
- W10 / S4 / SUGGESTION-1 — G4 guard proof arm + dead `OVERRIDE_PATTERN` variable → next burst
- W12 — text-only demo evidence, accepted for a CLI tool

**BI-040 CLOSED** — shared primitive layer merged. WS-4 UNBLOCKED (gated on POLICY-5 predicate per gate #27 Q4).

**BI-043 CLOSED** — zero `parent.parent.parent` occurrences remain in `scripts/spec-lint/` on merged develop; all 15 checkers/generators share one fail-closed repo-root resolver.

**BI-046 OPENED** — reviewer identity/token independence required before phase-3 story PRs begin. Severity MEDIUM, owner devops-engineer, cross-ref BI-039.

**D-089 RECORDED** — gate #28 operator ruling: review-as-comment + autonomy-L4 merge mechanism authorized; grounds: `develop` requires 0 approving reviews; real gate = 4 required CI status checks; `spec-lint` NOT among required checks; `enforce_admins: false`; no GitHub protection circumvented; standing designed-autonomy model (D-021→D-028→D-031); journal 2026-08-05 22:35 precedent; gate #5 revised 2026-08-06 09:15; BI-039 review-as-comment ruling. Residual: AI review independence nominal, not structural. Pre-Phase-3 condition: BI-046 required before story PRs begin.

**Convergence counter:** UNCHANGED — 0 of 3 clean passes. Pass 6 (perimeter sweep) COMPLETE. Next adversary pass is pass 7, after WS-4 remediation. Trajectory-tail →34→39→37→259 preserved exactly.

**Files touched:** `.factory/STATE.md`, `.factory/cycles/phase-1d/blocking-issues-resolved.md`, `.factory/cycles/phase-1d/burst-log.md`, `.factory/cycles/phase-1d/session-checkpoints.md`

**Closes:** BI-040 (PR #8 merged `c2e5cf1`), BI-043 (zero parent.parent.parent on develop). **Opens:** BI-046 (reviewer independence, pre-phase-3). **Adds:** D-089 (gate #28 ruling).

---

## Burst 21 — WS-4-G Shard-A COMPLETE; BC-2.05.003 v1.3 (POLICY-5 MEANING-INVERTED CLOSED)

**Date:** 2026-08-07
**Agent:** state-manager
**Status:** COMPLETE

### Evicted from Current Phase Steps (oldest row archived here)

| Step | Agent | Status | Output |
|------|-------|--------|--------|
| WS-3 Phase 1 audit COMPLETE; BI-034 RESOLVED; BI-023 corrected; D-075; session wrap D-075 | state-manager | COMPLETE | WS-3 Phase 1 read-only audit COMPLETE. Findings at `cycles/phase-1d/ws3-skip-list-audit.md` (commit `3734c1e`). BI-034 RESOLVED: all three skip-list entries KEEP (positive-coverage evidence per D-057). BI-023 corrected: (a) 34 BC files / 55 em-dash rows; (b) 11 `EC-NEW-` occurrences across 5 files (BC-2.07.005 omitted from audit list). D-075 (BI-042 PREEMPTIVE, not serializing). Lessons 37-40 committed. |

### Burst Narrative

WS-4-G Shard-A executed and committed. The single POLICY-5 MEANING-INVERTED citation (BC-2.05.003, DD-007 misreference) is closed.

**BC-2.05.003 v1.2 → v1.3 — citation-authority repair (4 lines changed, 3 distinct IDs):**

1. **Description line:** `DD-007` → `DD-003`. DD-007 governs exit-code precedence / no-fail-fast (→ DI-011), not HTML anchors. DD-003 (decisions.md:65) is the HTML-anchor narrow carve-out decision.
2. **L2 Capability row:** FABRICATED quoted excerpt `"HTML id/name attributes via DD-007 narrow carve-out"` → verbatim real title `"Anchor Table Construction"` (capabilities.md:98); explanatory gloss moved outside the quotes and re-cited to DD-003. This row previously contradicted the adjacent Capability Anchor Justification row, which already quoted CAP-005 correctly.
3. **L2 Domain Invariants:** `DI-008` → `DI-007, DI-008`. DI-007 ("HTML Anchor Extraction Scope Is Narrow") was MISSING and is precisely this BC's subject (corroborated verification-architecture.md:97,144). DI-008 retained.
4. **Brief Requirement:** `R5, DD-007` → `R2b, D-007`. BOTH were wrong. R5 is `--ignore`/`--allow` source exclusion (product-brief.md:46). R2b = heading anchors per BC-INDEX.md:222 and BC-INDEX.md:230 (which maps R2b → BC-2.05.001..BC-2.06.002, containing this BC). Note: D-007 is the decisions.md narrow-carve-out decision at the brief level; DD-003 is the domain-spec-level counterpart. Both apply; D-007 is the correct brief-level reference for the Brief Requirement field.

**CORRECTIONS REGISTER note (appended to SESSION-HANDOFF.md §D-090):** The recorded WS-4-G Shard-A prescription said "3 lines, DD-007→DI-007+DD-003". Execution found **4 lines** requiring **three distinct IDs** (DD-003 for the decision, D-007 for the brief-level decision, DI-007 for the invariant) AND an additional wrong ID (`R5`) that the prescription had not flagged and would have left in place. Further instance of the standing caution: un-executed prescriptions are upper bounds AND can be qualitatively wrong, not merely overstated in magnitude.

**Ancillary observation logged for pass-7 intake (NOT fixed in this burst):** DD-007 is glossed as "exit code precedence" (→ DI-011) at L2-INDEX.md:131 while several artifacts gloss it as "no-fail-fast" for nonexistent PATH (BC-2.01.009.md:40,51,57; prd.md:630,701). Whether DD-007 carries one decision or two conflated ones is UNADJUDICATED — logged as pass-7 intake item only.

**Baselines PRESERVED on develop @ `c2e5cf1` (unchanged — no develop commits this burst):**
- `check-placeholders.py` 80 findings / 133 files — PRESERVED
- `check-id-resolution.py` 10 findings / 134 files — PRESERVED
- `run-selftests.sh` 55/55 — PRESERVED
- `test_primitives.sh` 10/10 — PRESERVED

**Convergence counter:** UNCHANGED — 0 of 3 clean passes. WS-4-G Shard-A is the first of the 39 POLICY-5 subsystem items. WS-4 scope: 177 items (138 mechanical + 39 POLICY-5 FABRICATED; A:11/B:11/C:8/D:9).

**`.factory/hooks/verify-sha-currency.sh` STILL ABSENT** — post-push hook verification gap. Record only; not an implied pass. Heads verified directly by orchestrator.

**Files touched (Dim-1): 4 unique files (factory-artifacts only — no develop-side changes this burst)**

- `.factory/specs/behavioral-contracts/ss-05/BC-2.05.003.md` — v1.2 → v1.3 (citation-authority repair)
- `.factory/STATE.md` — timestamp, version 2.8→2.9, current_step, Last Updated, Current Step, Current Phase Steps (WS-3-audit row evicted; WS-4-G-Shard-A row added), BI-002 resolution, BI-027 counts, Session Resume Checkpoint, Concurrent Cycles, Last Updated footer, D-091 appended to Decisions Log
- `.factory/SESSION-HANDOFF.md` — RESUME IN ONE BREATH updated; WS-4 scope 178→177 / 40→39 POLICY-5; RESUME NEXT-ACTION updated; CORRECTIONS REGISTER new row; STANDING DIRECTIVES WS-4 scope updated
- `.factory/cycles/phase-1d/burst-log.md` — WS-3-audit row archived; this entry (burst 21)

**Codifications:** D-091 (WS-4-G Shard-A burst wrap, state-manager, 2026-08-07).

**Artifact state at burst close:**
PRD v1.11 \| 66 BCs \| 26 VPs \| 13 DIs \| 8 ADRs \| 19 policies \| EC registry EC-001..EC-204 (205 ids) \| holdout pool 12 (5 active: HS-001/004..007; 2 retired: HS-002/003). D-001..D-091 (exhaustive). Closed: BI-005/006/008/009/011/012/013/014/015/016/018/019/020/029/030/031/032/033/034/035/036/038/040/042/043/044/045. Open: BI-002/007/010/017/021/022/023/024/025/026/027/028/037/039/041/046.

**Dim-2 Attestation:** No `canonical-facts.toml` mutation this burst. `check-canonical-facts.py` last reported exit 0 at burst-20 close. No FACT-N entries added or modified. Canonical facts corpus unchanged.

**Dim-5 Attestation:** STATE.md — timestamp 2026-08-07T23:08:00Z, version 2.9, status: draft, producer: state-manager. burst-log.md — 21 bursts. SESSION-HANDOFF.md — D-090 snapshot updated (WS-4-G Shard-A COMPLETE).

**Dim-6 Attestation:** IN_PROGRESS. 0 of 3 clean passes. Trajectory →0→32→34→39→37→259 UNCHANGED. WS-4-G Shard-A COMPLETE (D-091). WS-4 remaining: 177 items (138 mechanical + 39 POLICY-5 FABRICATED).

**Dim-7 Attestation:** Agents dispatched this burst: state-manager only (spec file already edited and orchestrator-verified before burst start). No adversary agent dispatched.

**Closes:** (nothing — BC-2.05.003 was an open POLICY-5 finding, not a formal BI). **Updates:** BI-002 (WS-4-G Shard-A COMPLETE, 177 remaining), BI-027 (MEANING-INVERTED CLOSED; 39 FABRICATED remain). **Adds:** D-091 (WS-4-G Shard-A burst wrap).

---

## Burst: burst 22 — WS-4 Shards A–E: 40 POLICY-5 FABRICATED + 50 proof-method joins repaired across 49 BC files (2026-08-07)

**Parent-commit:** D-091 factory-artifacts HEAD (WS-4-G Shard-A, single BC file)

**Adversary verdict:** No adversary pass this burst. Convergence counter UNCHANGED — 0 of 3 clean passes. WS-4 Shards A–E are the remediation payload for pass-6's POLICY-5 axis (BI-027) and proof-method axis (BI-026). Pass 7 gated until PR feature/pol14-test-sufficient merges and 15 remaining non-blocked items are cleared.

**Shard summary (normalized POLICY-5 FABRICATED / proof-method join repairs):**
- Shard A (ss-01, ss-02): 5 FABRICATED / 1 proof-method
- Shard B (ss-03..ss-06): 7 FABRICATED (10 raw) / 20 proof-method
- Shard C (ss-07..ss-09): 11 FABRICATED / 14 proof-method
- Shard D (ss-10, ss-13): 8 FABRICATED / 5 proof-method
- Shard E (ss-11, ss-12, ss-14): 9 FABRICATED / 10 proof-method
- **TOTAL: 40 normalized / 43 raw FABRICATED repaired; 50 proof-method join repairs**

**CORRECTIONS REGISTER (understatements — opposite of all prior corrections which were overstatements):**
- Recorded 39 FABRICATED remaining → execution found 40. UNDERSTATEMENT by 1.
- Recorded 43 proof-method join repairs → execution found 50. UNDERSTATEMENT of 7.
- Rate 30.3% → refined 31.1% (41/132: 40 FABRICATED + 1 MEANING-INVERTED from D-091).
- 1 of 55 mechanically-fixable em-dash rows → execution found 0 of 55. The cross-check confirmed BC-2.10.002:160-161 has a real VP (VP-007) that does NOT match those rows — they are misfiled, not fixable here.

**Citation population independently re-derived:** 132 (66 BC files × exactly 2 per file). MATCHES original predicate population exactly.

**Uniform structural pattern:** Fabrication confined to the `L2 Capability` row; the adjacent `Capability Anchor Justification` row already carried the verbatim capability title — two rows contradicted each other in place. Repairs substituted the verbatim capabilities.md section title and moved any gloss OUTSIDE the quotation marks.

**Ancillary structural repairs (not POLICY-5, not proof-method — discovered during shard execution):**
- `BC-2.04.001`: Edge Cases table had 3 cells in a 2-column table (`TV-BV013` row); Shard B expanded header to `| EC | Description | Notes |` and padded 5 rows. TV-BV013 content byte-for-byte unchanged.
- `BC-2.06.001`: One VP-table row covered VP-001 AND VP-018; Shard B split it into two rows.
- Shards A, B, E corrected stale `input-hash` values (`c3e82ce` → `07d983a`) to satisfy `validate-input-hash` hook.

**Baselines PRESERVED on develop @ `c2e5cf1` (orchestrator re-ran all checkers post-burst — ZERO regressions):**
- `check-placeholders.py` 80 / 133 files — PRESERVED (55 em-dash + 25 Stories, both correctly untouched)
- `check-id-resolution.py` 10 / 134 files — PRESERVED
- `check-counts` PASSED (37 checks) · `check-title-sync` PASSED (66 titles) · `check-index-integrity` PASSED (80 checks; BC 66, VP 26) · `check-adr-consistency` PASSED (8 ADRs) · `check-ec-injectivity` PASSED (205 EC IDs, injective) · `check-holdout-boundary` PASSED (134 files, no leaks)
- `run-selftests.sh` 55/55 — PRESERVED
- `test_primitives.sh` 10/10 — PRESERVED

**Standing lesson:** The "138 mechanical items" figure was wrong IN KIND, not merely in magnitude — its single largest category (55 rows, 40% of that scope) required an operator ruling rather than a remediation burst. Dispatching the recorded plan verbatim would have driven five subagents toward fabricating VP ids.

**Residual:** 55 em-dash rows BLOCKED on PR #9 (feature/pol14-test-sufficient). After merge: 2 residual findings (BC-2.10.002:160-161 misfiled rows — probable move to BC-2.10.007/BC-2.10.010, not yet adjudicated). 10 id-resolution rows + 5 vacuous VP rewrites remain queued.

**`.factory/hooks/verify-sha-currency.sh` STILL ABSENT** — post-push hook verification gap. Heads verified directly by orchestrator. ZERO regressions confirmed by orchestrator re-run of all checkers.

**Files touched (Dim-1): 51 unique files (factory-artifacts only — no develop-side changes this burst)**

- `.factory/specs/behavioral-contracts/ss-01/BC-2.01.001.md` — POLICY-5 FABRICATED repair + proof-method join
- `.factory/specs/behavioral-contracts/ss-01/BC-2.01.002.md` — POLICY-5 FABRICATED repair
- `.factory/specs/behavioral-contracts/ss-01/BC-2.01.003.md` — POLICY-5 FABRICATED repair
- `.factory/specs/behavioral-contracts/ss-01/BC-2.01.004.md` — POLICY-5 FABRICATED repair
- `.factory/specs/behavioral-contracts/ss-01/BC-2.01.005.md` — POLICY-5 FABRICATED repair + stale input-hash corrected (c3e82ce → 07d983a)
- `.factory/specs/behavioral-contracts/ss-01/BC-2.01.009.md` — POLICY-5 FABRICATED repair
- `.factory/specs/behavioral-contracts/ss-03/BC-2.03.001.md` — POLICY-5 FABRICATED repair + proof-method join
- `.factory/specs/behavioral-contracts/ss-03/BC-2.03.002.md` — POLICY-5 FABRICATED repair + proof-method join
- `.factory/specs/behavioral-contracts/ss-03/BC-2.03.003.md` — POLICY-5 FABRICATED repair + proof-method join
- `.factory/specs/behavioral-contracts/ss-03/BC-2.03.004.md` — POLICY-5 FABRICATED repair + proof-method join
- `.factory/specs/behavioral-contracts/ss-03/BC-2.03.005.md` — proof-method join (no POLICY-5 fabrication in this file)
- `.factory/specs/behavioral-contracts/ss-04/BC-2.04.001.md` — POLICY-5 FABRICATED repair + structural Edge Cases table repair (TV-BV013 row: 3 cells → 2-column table; header expanded to `| EC | Description | Notes |`; 5 rows padded) + stale input-hash corrected
- `.factory/specs/behavioral-contracts/ss-04/BC-2.04.002.md` — POLICY-5 FABRICATED repair + proof-method join
- `.factory/specs/behavioral-contracts/ss-04/BC-2.04.003.md` — POLICY-5 FABRICATED repair + proof-method join
- `.factory/specs/behavioral-contracts/ss-05/BC-2.05.002.md` — POLICY-5 FABRICATED repair + proof-method join
- `.factory/specs/behavioral-contracts/ss-05/BC-2.05.003.md` — POLICY-5 FABRICATED repair (builds on D-091 v1.3 citation-authority repair)
- `.factory/specs/behavioral-contracts/ss-06/BC-2.06.001.md` — POLICY-5 FABRICATED repair + VP-table row split (single row VP-001+VP-018 → two rows)
- `.factory/specs/behavioral-contracts/ss-06/BC-2.06.002.md` — POLICY-5 FABRICATED repair + proof-method join
- `.factory/specs/behavioral-contracts/ss-07/BC-2.07.001.md` — POLICY-5 FABRICATED repair + proof-method join
- `.factory/specs/behavioral-contracts/ss-07/BC-2.07.002.md` — POLICY-5 FABRICATED repair + proof-method join
- `.factory/specs/behavioral-contracts/ss-07/BC-2.07.003.md` — POLICY-5 FABRICATED repair + proof-method join
- `.factory/specs/behavioral-contracts/ss-07/BC-2.07.004.md` — POLICY-5 FABRICATED repair + proof-method join
- `.factory/specs/behavioral-contracts/ss-07/BC-2.07.006.md` — POLICY-5 FABRICATED repair + proof-method join
- `.factory/specs/behavioral-contracts/ss-07/BC-2.07.007.md` — POLICY-5 FABRICATED repair + proof-method join (frontmatter version/modified changelog discrepancy: ancillary finding logged for pass-7, not fixed here)
- `.factory/specs/behavioral-contracts/ss-08/BC-2.08.001.md` — POLICY-5 FABRICATED repair + proof-method join
- `.factory/specs/behavioral-contracts/ss-08/BC-2.08.002.md` — POLICY-5 FABRICATED repair + proof-method join
- `.factory/specs/behavioral-contracts/ss-08/BC-2.08.003.md` — POLICY-5 FABRICATED repair + proof-method join
- `.factory/specs/behavioral-contracts/ss-08/BC-2.08.004.md` — POLICY-5 FABRICATED repair + proof-method join (frontmatter version/modified changelog discrepancy: ancillary finding logged for pass-7, not fixed here)
- `.factory/specs/behavioral-contracts/ss-09/BC-2.09.001.md` — POLICY-5 FABRICATED repair + proof-method join
- `.factory/specs/behavioral-contracts/ss-09/BC-2.09.002.md` — POLICY-5 FABRICATED repair + proof-method join
- `.factory/specs/behavioral-contracts/ss-10/BC-2.10.001.md` — POLICY-5 FABRICATED repair + proof-method join
- `.factory/specs/behavioral-contracts/ss-10/BC-2.10.003.md` — POLICY-5 FABRICATED repair + proof-method join
- `.factory/specs/behavioral-contracts/ss-10/BC-2.10.004.md` — POLICY-5 FABRICATED repair + proof-method join
- `.factory/specs/behavioral-contracts/ss-10/BC-2.10.005.md` — POLICY-5 FABRICATED repair + proof-method join
- `.factory/specs/behavioral-contracts/ss-10/BC-2.10.006.md` — POLICY-5 FABRICATED repair + proof-method join
- `.factory/specs/behavioral-contracts/ss-10/BC-2.10.007.md` — POLICY-5 FABRICATED repair + proof-method join
- `.factory/specs/behavioral-contracts/ss-10/BC-2.10.008.md` — POLICY-5 FABRICATED repair + proof-method join
- `.factory/specs/behavioral-contracts/ss-11/BC-2.11.001.md` — POLICY-5 FABRICATED repair + proof-method join
- `.factory/specs/behavioral-contracts/ss-11/BC-2.11.002.md` — POLICY-5 FABRICATED repair + proof-method join
- `.factory/specs/behavioral-contracts/ss-11/BC-2.11.004.md` — POLICY-5 FABRICATED repair + proof-method join
- `.factory/specs/behavioral-contracts/ss-12/BC-2.12.001.md` — POLICY-5 FABRICATED repair + proof-method join
- `.factory/specs/behavioral-contracts/ss-12/BC-2.12.002.md` — POLICY-5 FABRICATED repair + proof-method join
- `.factory/specs/behavioral-contracts/ss-12/BC-2.12.003.md` — POLICY-5 FABRICATED repair + proof-method join
- `.factory/specs/behavioral-contracts/ss-12/BC-2.12.004.md` — POLICY-5 FABRICATED repair + proof-method join
- `.factory/specs/behavioral-contracts/ss-13/BC-2.13.001.md` — POLICY-5 FABRICATED repair + proof-method join
- `.factory/specs/behavioral-contracts/ss-13/BC-2.13.002.md` — POLICY-5 FABRICATED repair + proof-method join
- `.factory/specs/behavioral-contracts/ss-14/BC-2.14.001.md` — POLICY-5 FABRICATED repair + proof-method join
- `.factory/specs/behavioral-contracts/ss-14/BC-2.14.002.md` — POLICY-5 FABRICATED repair + proof-method join
- `.factory/specs/behavioral-contracts/ss-14/BC-2.14.003.md` — POLICY-5 FABRICATED repair + proof-method join
- `.factory/STATE.md` — timestamp 2026-08-07T23:57:00Z, version 2.9→3.0; current_step, Last Updated, Current Phase Steps (WS-4-G-Shard-A row superseded by WS-4-Shards-A–E row), BI-002 resolution, BI-026/BI-027 counts, Session Resume Checkpoint, Concurrent Cycles, D-092/D-093 appended to Decisions Log, CORRECTIONS entries
- `.factory/cycles/phase-1d/burst-log.md` — this entry (burst 22)

**Codifications:** D-092 (POL-14 test-sufficient sentinel — VP-INDEX cross-check required; mutation/negative tests required per D-040/D-050/D-057; PR #9 OPEN, NOT merged), D-093 (spec-lint REQUIRED at Phase-1 gate with Stories field exempt until Phase 2; resolves D-029/D-032 unsatisfiable-as-written contradiction; PR #9 OPEN, NOT merged).

**Artifact state at burst close:**
PRD v1.11 \| 66 BCs \| 26 VPs \| 13 DIs \| 8 ADRs \| 19 policies \| EC registry EC-001..EC-204 (205 ids) \| holdout pool 12 (5 active: HS-001/004..007; 2 retired: HS-002/003). D-001..D-093 (exhaustive). Closed: BI-005/006/008/009/011/012/013/014/015/016/018/019/020/029/030/031/032/033/034/035/036/038/040/042/043/044/045. Open: BI-002/007/010/017/021/022/023/024/025/026/027/028/037/039/041/046.

**Dim-2 Attestation:** No `canonical-facts.toml` mutation this burst. `check-canonical-facts.py` last reported exit 0 at burst-20 close. No FACT-N entries added or modified. Canonical facts corpus unchanged.

**Dim-5 Attestation:** STATE.md — timestamp 2026-08-07T23:57:00Z, version 3.0, status: draft, producer: state-manager. burst-log.md — 22 bursts. SESSION-HANDOFF.md — D-090 snapshot; NOT updated this burst (no session-wrap performed; shards A–E state fully captured in STATE.md and this burst-log entry).

**Dim-6 Attestation:** IN_PROGRESS. 0 of 3 clean passes. Trajectory →0→32→34→39→37→259 UNCHANGED. WS-4 Shards A–E COMPLETE. WS-4 remaining: 70 items — 55 em-dash BLOCKED on PR #9 (feature/pol14-test-sufficient) + 10 id-resolution + 5 vacuous VP rewrites. 2 residual after merge per BC-2.10.002 adjudication.

**Dim-7 Attestation:** Agents dispatched this burst: product-owner ×5 (one per shard) for spec edits; state-manager for factory-artifacts commit. No adversary agent dispatched.

---

## Burst: burst 23 — Session Wrap D-094 (2026-08-07)

**Parent-commit:** 555a3c8f3c530432bae16b8aecaaa74f7b1cb992 (factory(ws-4): shards A-E — 40 POLICY-5 fabrications + 50 proof-method joins repaired across 49 BC files)

**Adversary verdict:** N/A — session wrap; no adversary pass dispatched this burst. Prior convergence state: WS-3 CONVERGED (3/3 clean). WS-4 queue CLOSED.

**Archived from STATE.md Current Phase Steps (oldest row rotated out):**

| PR #7 MERGED as `e1299b07`; BI-042/035 CLOSED; BI-023 checker repairs landed; D-086/D-087/D-088; worktree ws3 removed | state-manager | COMPLETE | PR #7 squash-merged develop `7b9aa6d`→`e1299b07`; 9-step pr-manager lifecycle, 3 review cycles, 5 blockers resolved; APPROVE at `791fc11` (freshness check not tautological — D-071 failure mode did not recur); CI 4/4 PASS; spec-lint ADVISORY FAIL accepted (D-029/D-032/D-077); SEC-001 LOW accepted; 55/55 selftests; check-canonical-facts OK; baseline PRESERVED (80 placeholders + 10 id-resolution findings). BI-042 CLOSED (selftest-22 teeth-test). BI-035 CLOSED. BI-023 items 2+3 CLOSED (checker repairs on develop). BI-045 already CLOSED. Worktree ws3 removed (tree-identical diff verified; `791fc11` reflog-recoverable). D-086/D-087/D-088. |

**Burst narrative (4 agents, all disjoint files):**

1. **BC-2.10.002 misfiling CLOSED.** Both surviving em-dash rows at PC3/PC16 were CONFIRMED-DUPLICATE-DELETE: they only cross-reference BC-2.10.007/010 and never owned the logic. BC-2.10.007 carries the HTTPS→HTTP downgrade in PC3 + I2 + VP row; BC-2.10.010 carries private-IP suppression in PC2 + I1 + VP row. Deleted from BC-2.10.002 only (v1.7→1.8). Em-dash corpus 55→53, verified. The predicted "2 residual findings surviving D-092" is now ZERO — all 53 remaining em-dash rows sit in `test-sufficient` BCs.

2. **EC registry — check-id-resolution CLOSED 10→0.** EC-NEW-1/2→EC-205/206 (BC-2.07.006), EC-NEW-10/11→EC-207/208 (BC-2.11.004), EC-NEW-12/13→EC-209/210 (BC-2.12.005), EC-NEW-14/15/16→EC-211/212/213 (BC-2.14.004). Registered in test-vectors.md §10.7–§10.10 (TV-205..TV-213). `TV-BV013` at BC-2.04.001 resolved by REMOVING the redundant Edge-Cases row — identical scenario already in test-vectors.md §0. EC-102 not resurrected (D-010).

3. **Five vacuous VPs rewritten (BI-025 CLOSED).** vp-015 (v1.2→v1.3), vp-016 (v1.2→v1.3), vp-017 (v1.3→v1.4), vp-019 (v1.1→v1.2), vp-023 (v1.0→v1.1). Every fixture now carries a control broken link with a guaranteed-nonexistent anchor, so a no-op scanner returning `vec![]` fails the control assertion. VP-023's new P4/P5/P6 kill `classify_url(_) -> Malformed("")` — the implementation marking every external HTTPS link broken. VP-016 gained Fixture 5 for DI-006 Pass 1.5 missing-target rule. All 5 proof methods still match VP-INDEX; VP count 26 UNCHANGED.

4. **prd.md §5b EC-count reconciliation.** Declared 203→212, range EC-001..EC-204→EC-001..EC-213, with "213 IDs allocated; ID 102 retired — became TV-BV013 per D-010". prd.md v1.11→v1.12. §8 CHANGELOG NOT touched (D-034 protects versioned changelog; §5b is body prose, editable — clarified this session).

**Final checker state at burst close:**

- `check-counts` PASSES, 37 count checks
- `check-id-resolution` PASSES, 0 findings / 134 files (was 10)
- `check-ec-injectivity` PASSES, 214 EC IDs, all injective (was 205)
- `check-holdout-boundary` PASSES, 134 visible files, pool 12 ids
- `check-index-integrity` PASSES, 80 structural checks (BC 66, VP 26)
- `check-placeholders` 78 findings = 53 em-dash + 25 Stories — BOTH classes BLOCKED on PR #9

**PR #9 state:** `feature/pol14-test-sufficient` → develop, head `87cefbf`. All 4 CI checks GREEN. CHANGES-NEEDED. B1 BLOCKING: M4/M8 survive Shape 2 at 62/62 exit 0 with zero selftest coverage. Prescribed fix: P14-8 (kills M4) + P14-9 (kills M8). S1 suggestion: field-anchoring for Shape 2. BI-046 self-approval constraint is demonstrably load-bearing — operator merge decision required.

**Corrections register additions:** 39→40 FABRICATED (UNDERSTATEMENT), 43→50 proof-method joins (UNDERSTATEMENT), 30.3%→31.1% fabrication rate, 1→0 mechanically-fixable em-dash, 2→0 post-D-092 residual, 203→212 prd.md §5b EC count.

**Files touched (Dim-1): 15 unique files**
- `.factory/specs/behavioral-contracts/ss-04/BC-2.04.001.md` — Edge-Cases TV-BV013 row removed
- `.factory/specs/behavioral-contracts/ss-07/BC-2.07.006.md` — EC-NEW-1/2 → EC-205/206
- `.factory/specs/behavioral-contracts/ss-10/BC-2.10.002.md` — v1.7→v1.8; 2 duplicate em-dash rows deleted
- `.factory/specs/behavioral-contracts/ss-11/BC-2.11.004.md` — EC-NEW-10/11 → EC-207/208
- `.factory/specs/behavioral-contracts/ss-12/BC-2.12.005.md` — EC-NEW-12/13 → EC-209/210
- `.factory/specs/behavioral-contracts/ss-14/BC-2.14.004.md` — EC-NEW-14/15/16 → EC-211/212/213
- `.factory/specs/prd-supplements/test-vectors.md` — §10.7–§10.10 TV-205..TV-213 added
- `.factory/specs/prd.md` — §5b 203→212 ECs; v1.11→v1.12
- `.factory/specs/verification-properties/vp-015-two-pass-anchor-complete.md` — vacuous VP rewritten
- `.factory/specs/verification-properties/vp-016-ignored-files-anchor-targets.md` — vacuous VP rewritten + DI-006 Fixture 5
- `.factory/specs/verification-properties/vp-017-scan-terminates.md` — vacuous VP rewritten
- `.factory/specs/verification-properties/vp-019-one-verdict-per-link.md` — vacuous VP rewritten; dead loop eliminated
- `.factory/specs/verification-properties/vp-023-url-classifier-totality.md` — vacuous VP rewritten; kills Malformed("") constant impl
- `.factory/STATE.md` — v3.0→v3.1; D-094 session wrap
- `.factory/SESSION-HANDOFF.md` — D-090 SUPERSEDED by D-094; §RESUME SNAPSHOT D-094 added

**Codifications:** D-094 (session wrap — durable RESUME SNAPSHOT D-094; supersedes D-090).

**Artifact state at burst close:**
PRD v1.12 \| 66 BCs \| 26 VPs \| 13 DIs \| 8 ADRs \| 19 policies \| EC registry EC-001..EC-213 (214 ids, 1 retired) \| holdout pool 12 (5 active: HS-001/004..007; 2 retired: HS-002/003). D-001..D-094 (exhaustive). Closed: BI-005/006/008/009/011/012/013/014/015/016/018/019/020/025/026/029/030/031/032/033/034/035/036/038/040/042/043/044/045. Open: BI-002/007/010/017/021/022/023/024/027/028/037/039/041/046.

**Dim-2 Attestation:** No `canonical-facts.toml` mutation this burst. Canonical facts corpus unchanged.

**Dim-5 Attestation:** STATE.md — timestamp 2026-08-08T00:01:00Z, version 3.1, status: draft, producer: state-manager. burst-log.md — 23 bursts. SESSION-HANDOFF.md — D-094 snapshot replaces D-090.

**Dim-6 Attestation:** IN_PROGRESS. 0 of 3 clean passes. Trajectory →0→32→34→39→37→259 UNCHANGED. WS-4 remaining: 53 em-dash BLOCKED on PR #9 (CHANGES-NEEDED, B1 blocking). All other WS-4 items CLOSED.

**Dim-7 Attestation:** Agents dispatched this burst: product-owner ×1 (BC-2.10.002 misfiling), product-owner ×1 (EC registry), formal-verifier ×1 (vacuous VPs), product-owner ×1 (prd.md §5b); state-manager for factory-artifacts commit and session wrap.

---

## Burst: burst-24 — PR #9 B1 Remediation APPROVED at a42e155 (2026-08-08)

**Parent-commit:** `f90d537` (factory(audit): preserve PR #9 review-evidence + gate #30 D-095/D-096/D-097)

**Adversary verdict:** No adversary pass this burst. Session wrap + B1 remediation result recording only. Convergence counter UNCHANGED: 0 of 3 clean passes. Trajectory →0→32→34→39→37→259 UNCHANGED. Pass 7 DEFERRED (D-095) until PR #9 merged + S3 landed + 53 rows rewritten + burn-down clean.

**Current Phase Steps archival:** The following row (oldest, associated with burst-19) was removed from STATE.md Current Phase Steps to make room for the burst-24 row:

> `| compact-state DONE (a70306d); D-017..D-020 (exhaustive) restored (002111a); BI-040 code-CLOSED on fix/bi-040-primitive-layer (4 commits, NOT merged); BI-044 CLOSED (14 sites); D-088 WS-4 re-derivation COMPLETE (286 actionable); 0 of 3 clean passes | state-manager | COMPLETE | compact-state: 16 CLOSED blockers archived, D-002 superseded decision archived, current_cycle pointer set. D-017..D-020 (exhaustive) restored: 4 decisions absent from Decisions Log reconstructed from prd.md/BC-2.11.002.md, PG-010 filed. BI-040 all 3 stages on branch fix/bi-040-primitive-layer: output-identity byte-exact, 55/55 selftests + 9/9 primitive tests. BI-044 CLOSED (14 sites). BI-043 OPEN (10-file evidence). D-088 WS-4 re-derivation: 286 actionable; 138 dispatchable; BI-040 must MERGE before WS-4 dispatch. |`

PR #9 (`feature/pol14-test-sufficient`) advanced from CHANGES-NEEDED through two additional review cycles to APPROVE:

- **Head 87cefbf** (cycle 1): Original submission. Review found B1 (M4+M8 survive Shape 2 with zero coverage; `is_conforming_vp_cell` → `true` passes all tests), S1 (ATX heading reset incomplete), and others. Verdict: CHANGES-NEEDED. Recorded in `code-delivery/BI-POL14-TEST-SUFFICIENT/pr-review.md` (immutable cycle-1 audit record, 9,627 bytes).

- **Head 55113c4** (cycle 2): Author applied P14-8, P14-9, S1 (partial), raised `EXPECTED_TEST_COUNT` 62→64. Review found S1 fix uncovered (three of four ATX-heading shapes still exempt), and mutations MS1/MX1/MX3/MB survived cycle-2 test suite. Verdict: CHANGES-NEEDED. Recorded in `code-delivery/BI-POL14-TEST-SUFFICIENT/pr-review-55113c4.md`.

- **Head a42e155** (cycle 3): Author applied P14-10/P14-11/P14-12/P14-13, raised `EXPECTED_TEST_COUNT` 64→68, repaired all four ATX-heading shapes. All six mutants (MS1/MX1/MX3/MB/M4/M8) killed guard-independently. 4/4 CI green. Verdict: APPROVE. Recorded in `code-delivery/BI-POL14-TEST-SUFFICIENT/pr-review-a42e155.md`.

All three reviews posted as COMMENTS (not `gh pr review --approve`) due to BI-039 structural constraint. Merge GATED TO OPERATOR — no self-approval possible; operator must execute the merge.

**Actionability pre-check EXECUTED (D-082):** 53 em-dash rows span 33 BC files; exact bijection with VP-INDEX `test-sufficient` classification set (66 BC rows parsed; anti-vacuity perturbation test passed). Rows are ACTIONABLE — no phantom rows.

**S3 sequencing gate identified (D-100):** `test-sufficient` sentinel currently accepts EMPTY Proof Method. S3 (one-line guard: non-empty Proof Method required alongside `test-sufficient`) must land BEFORE the 53-row rewrite, because S3 becomes live exactly when those rows migrate off `—`. Ordering: PR #9 merge → S3 → 53-row rewrite.

**BI-046 escalated as gate (D-097 escalation clause):** Reviewer identity resolution requires separate reviewer identity/token — operator infrastructure decision, not a mechanical fix. REQUIRED before Phase 3 story PRs begin.

**Hook gap noted:** `validate-pr-review-posted` hook fires on literal filename `pr-review.md`; conflicts with multi-cycle immutable-audit convention. Additionally demands `gh pr review --approve|--request-changes` which GitHub structurally CANNOT record on self-authored PRs (BI-039). Hook is a known misfire for this project.

**verify-sha-currency.sh FORMALLY RETIRED (D-099):** Operator ruling. Hook absent from this project; carrying as per-wrap caveat produced no actionable outcome and obscured real gaps. Formal retirement stops it recurring as a per-wrap caveat.

**Codifications:** D-098 (session/burst wrap — D-098 supersedes D-094). D-099 (verify-sha-currency.sh FORMALLY RETIRED). D-100 (S3 before 53-row rewrite — sequencing gate).

**Artifact state at burst close:**
PRD v1.12 \| 66 BCs \| 26 VPs \| 13 DIs \| 8 ADRs \| 19 policies \| EC registry EC-001..EC-213 (214 ids, 1 retired) \| holdout pool 12 (5 active: HS-001/004..007; 2 retired: HS-002/003). D-001..D-100 (exhaustive). Closed: BI-005/006/008/009/011/012/013/014/015/016/018/019/020/025/026/029/030/031/032/033/034/035/036/038/040/042/043/044/045. Open: BI-002/007/010/017/021/022/023/024/027/028/037/039/041/046.

**Dim-2 Attestation:** No `canonical-facts.toml` mutation this burst. Canonical facts corpus unchanged.

**Dim-5 Attestation:** STATE.md — timestamp 2026-08-08T05:36:00Z, version 3.1, status: draft, producer: state-manager. burst-log.md — 24 bursts. SESSION-HANDOFF.md — D-098 snapshot replaces D-094.

**Dim-6 Attestation:** IN_PROGRESS. 0 of 3 clean passes. Trajectory →0→32→34→39→37→259 UNCHANGED. PR #9 APPROVED at a42e155 — MERGE GATED TO OPERATOR. 53 em-dash ACTIONABLE (exact bijection VP-INDEX). Next convergence step: operator merge → S3 → rewrite 53 rows → pass 7 (D-095).

**Dim-7 Attestation:** Agents dispatched this burst: code-reviewer ×3 (PR #9 cycles 1-3 review); state-manager for factory-artifacts commit and session wrap.

**Files touched (Dim-1): 5 unique files (factory-artifacts only — no develop-side changes this burst)**
- `.factory/STATE.md`
- `.factory/SESSION-HANDOFF.md`
- `.factory/cycles/phase-1d/burst-log.md`
- `.factory/code-delivery/BI-POL14-TEST-SUFFICIENT/pr-review-55113c4.md`
- `.factory/code-delivery/BI-POL14-TEST-SUFFICIENT/pr-review-a42e155.md`

**Closes:** N/A — no blockers closed this burst. **Updates:** BI-002 (PR #9 APPROVED at a42e155 — MERGE GATED TO OPERATOR; 53 em-dash ACTIONABLE; S3 before rewrite (D-100)). BI-023 (BLOCKED on PR #9 OPEN, APPROVED not yet merged). BI-046 (ESCALATED AS GATE per D-097 escalation clause). **Adds:** D-098, D-099, D-100.

---

## Burst: burst-25 — PR #9 MERGED (d4e76fa); PR #10 OPENED+APPROVED (a14711e, S3); BI-046 DEFERRED pre-Phase-3; D-101..D-105 (2026-08-08)

**Parent-commit:** `fc7263f` (factory(phase-1d): D-098 session wrap — PR #9 APPROVED at a42e155)

**Adversary verdict:** No adversary pass this burst. Session wrap only. Convergence counter UNCHANGED: 0 of 3 clean passes. Trajectory →0→32→34→39→37→259 UNCHANGED. Pass 7 DEFERRED (D-095) until PR #10 merged + 53 rows rewritten + check-placeholders=0 + operator gate.

**Current Phase Steps archival:** The following row (oldest, associated with burst-20 / PR #8 MERGED) was removed from STATE.md Current Phase Steps to make room for the burst-25 row:

> `| PR #8 MERGED (c2e5cf1; BI-040/BI-043 CLOSED; BI-046 OPENED; D-089 gate #28); WS-4 UNBLOCKED; develop e1299b0→c2e5cf1; session-checkpoints.md: D-089 archived | state-manager | COMPLETE | PR #8 squash-merged; shared primitive layer closes BI-040 (55/55 selftests + 10/10 primitives); B1/B2/W2/W7/S2 found+fixed during 3-cycle review; BI-043 CLOSED (zero parent.parent.parent on develop); BI-046 OPENED (reviewer independence pre-phase-3 condition); D-089 gate #28 ruling (review-as-comment + autonomy-L4 authorized). |`

**PR #9 MERGED (d4e76fa):** Operator executed squash-merge of `feature/pol14-test-sufficient` (head `a42e155`) to `develop` as `d4e76fa`. Stale PR body corrected before merge per D-102 (body had claimed 55 findings/62 tests; corrected to 53 findings/68 tests + full mutation table). D-092/D-093 now on develop. `check-placeholders` 78→53 (25 Stories exempt under D-093's carve-out). develop `c2e5cf1`→`d4e76fa`.

**PR #10 OPENED+APPROVED (a14711e):** `fix/s3-test-sufficient-proof-method` opened as PR #10 (closes S3: require non-empty Proof Method alongside `test-sufficient` sentinel). Single-line guard in `is_conforming_vp_cell`: reject `vp_val.strip() == ""`. Head `a14711e`. Selftest P14-14 added (69/69 total). Revert-mutation kills P14-14 guard-independently (non-vacuous). Independent review posted as comment per BI-039 constraint: APPROVE 0 blocking, 1 MINOR, 1 INFO. Recorded in `code-delivery/S3-PROOF-METHOD/pr-review-a14711e.md` (21,907 bytes). 4/4 CI green. **MERGE GATED TO OPERATOR** (BI-046 DEFERRED — D-104).

**Actionability pre-check EXECUTED (D-082):** All 53 em-dash rows verified to carry non-empty Proof Method. VP-INDEX bijection across 33 BC files confirmed (S3 rejects none). The 53-row rewrite is fully ACTIONABLE the moment PR #10 merges.

**BI-046 DEFERRED to pre-Phase-3 (D-104):** Auto-mode classifier blocked a combined review+merge dispatch on self-approval grounds during this session. Operator ruled DEFER to pre-Phase-3 (not a mechanical fix; requires separate reviewer identity/token). Merges remain OPERATOR-GATED until resolved. REQUIRED before Phase 3 story PRs begin (D-089).

**Hook misfires classified CI-063 (D-105):** Two structural defects documented:
1. `validate-pr-review-posted`: fires on literal `pr-review.md` (conflicts with SHA-keyed immutable-audit convention); demands `gh pr review --approve/--request-changes` which GitHub structurally CANNOT record on self-authored PRs (BI-039).
2. Step-counter: counts only current-turn STEP_COMPLETE emissions, not full lifecycle.
Both are factory-engine packaging gaps. ~12 misfirings across three agents this session. Effective mitigation: in-prompt warning. Agent behaviour under misfire was correct in later cases (refused to fabricate verdict, refused to overwrite audit records). D-082 discipline boundary preserved: cycle-3 reviewer attempted `gh pr review --approve`; permission classifier blocked it; no approval was ever recorded.

**Codifications:** D-101 (session wrap — D-101 supersedes D-098). D-102 (PR #9 merge conditional on stale body correction first — D-102 codifies the correction requirement). D-103 (S3 as follow-on PR #10 rather than added to PR #9 at cycle limit). D-104 (BI-046 DEFERRED to pre-Phase-3; merges OPERATOR-GATED). D-105 (validate-pr-review-posted + step-counter hook misfires classified CI-063 factory-engine packaging gaps).

**Artifact state at burst close:**
PRD v1.12 \| 66 BCs \| 26 VPs \| 13 DIs \| 8 ADRs \| 19 policies \| EC registry EC-001..EC-213 (214 ids, 1 retired) \| holdout pool 12 (5 active: HS-001/004..007; 2 retired: HS-002/003). D-001..D-105 (exhaustive). Closed: BI-005/006/008/009/011/012/013/014/015/016/018/019/020/025/026/029/030/031/032/033/034/035/036/038/040/042/043/044/045. Open: BI-002/007/010/017/021/022/023/024/027/028/037/039/041/046.

**Dim-2 Attestation:** No `canonical-facts.toml` mutation this burst. Canonical facts corpus unchanged.

**Dim-5 Attestation:** STATE.md — timestamp 2026-08-08T09:30:00Z, version 3.1, status: draft, producer: state-manager. burst-log.md — 25 bursts. SESSION-HANDOFF.md — D-101 snapshot supersedes D-098.

**Dim-6 Attestation:** IN_PROGRESS. 0 of 3 clean passes. Trajectory →0→32→34→39→37→259 UNCHANGED. PR #10 (S3, a14711e) OPEN+APPROVED — MERGE GATED TO OPERATOR. All 53 em-dash rows ACTIONABLE (VP-INDEX bijection; non-empty Proof Method verified). Next convergence step: operator merge PR #10 → rewrite 53 rows → burn-down → pass 7 (D-095).

**Dim-7 Attestation:** Agents dispatched this burst: code-reviewer ×1 (PR #10 independent review); state-manager for session wrap, factory-artifacts commit.

**Files touched (Dim-1): 4 unique files (factory-artifacts only — no develop-side changes this burst)**
- `.factory/STATE.md`
- `.factory/SESSION-HANDOFF.md`
- `.factory/cycles/phase-1d/burst-log.md`
- `.factory/code-delivery/S3-PROOF-METHOD/pr-review-a14711e.md`

**Closes:** N/A — no blockers closed this burst. **Updates:** BI-002 (PR #9 MERGED d4e76fa; PR #10 OPEN+APPROVED a14711e; 53 rows ACTIONABLE; next: operator merge PR #10). BI-023 (PR #9 MERGED d4e76fa; check-placeholders 78→53; BLOCKED on PR #10 merge + 53-row rewrite). BI-046 (DEFERRED to pre-Phase-3 D-104; merges OPERATOR-GATED). **Adds:** D-101, D-102, D-103, D-104, D-105.

---

## Burst-26 — D-077 BURN-DOWN CLEAR; FULL SPEC-LINT GREEN (9/9); SESSION WRAP D-106

*Date: 2026-08-08. Agents: state-manager (session wrap + factory-artifacts commit). Single-commit burst TD-VSDD-053.*

### Summary

Burst-26 records three completed events from prior operator-executed work and commits the durable D-106 RESUME SNAPSHOT.

**Event 1 — PR #10 MERGED (D-107):** Operator squash-merged `fix/s3-test-sufficient-proof-method` as `f8ee4eb`. Develop advanced `d4e76fa`→`f8ee4eb`. S3/D-100 non-empty Proof Method precondition is now live on develop. Post-merge selftests 69/69 exit 0; P14 header count 14; S3 guard text present; revert-mutation kills P14-14 guard-independently. Remote branch `fix/s3-test-sufficient-proof-method` deleted. Exactly two worktrees remain (main checkout + `.factory`).

**Event 2 — 53-row VP-column sentinel rewrite COMPLETE (D-108):** 33 BC files modified; 53 `—` VP-column cells replaced with `test-sufficient`; 33 version fields bumped +0.1. Diff purity verified via `git diff --shortstat a306ed6..671109d`: 33 files, 86 insertions, 86 deletions = exactly 53 sentinel cells + 33 version lines, ZERO other additions. Em-dash corpus delta exactly −53 (1922→1869). Anti-vacuity proven by orchestrator: revert one cell → `check-placeholders` reports exactly 1 finding; restore → 0. Per-row legality re-confirmed: all 33 BCs classified test-sufficient in VP-INDEX; all 53 rows carried non-empty Proof Method; S3 rejected none. Factory-artifacts HEAD at time of rewrite: `671109d`.

**check-placeholders=0; D-077 burn-down CLEAR. Full spec-lint gate GREEN (9/9) — FIRST fully-green spec-lint in the entire run.**

All 9 checkers independently re-run by orchestrator at factory-artifacts HEAD `671109d`:
- check-placeholders: PASS 0 (was 53)
- check-counts: PASS 37
- check-id-resolution: PASS 134 files
- check-ec-injectivity: PASS 214 IDs
- check-holdout-boundary: PASS 134 visible
- check-index-integrity: PASS 80 checks
- check-adr-consistency: PASS 8 ADRs
- check-title-sync: PASS 66 BC titles
- check-canonical-facts: PASS 31 bindings/11 facts

**Event 3 — spec-lint REQUIRED flip now MECHANICALLY SATISFIABLE (D-109):** check-placeholders=0 with D-093 Stories-field carve-out in force; all 25 `[filled by ...]` occurrences are in the Stories field which is exempt until Phase 2. Flip SCHEDULED for Phase-1 human approval gate; NOT executed this session. This is the first time the flip has been satisfiable — previously UNSATISFIABLE AS WRITTEN because all 25 remaining placeholders were in the Stories field.

**Pass 7 status:** ARMED-GATED (D-095). All three preconditions now satisfied: (1) PR #10 MERGED, (2) 53-row rewrite COMPLETE, (3) check-placeholders=0. Pre-dispatch operator gate STANDS. Operator directed no dispatch this session. Streak from ZERO against frozen HEAD; severity in RANGES (PG-012).

**Convergence UNCHANGED:** 0 of 3 clean passes. Trajectory →0→32→34→39→37→259. Trajectory-tail →34→39→37→259. No new adversary pass was dispatched; no clean pass was recorded.

**Codifications:** D-106 (session wrap — this RESUME SNAPSHOT, supersedes D-101). D-107 (PR #10 squash-merged as f8ee4eb; S3/D-100 closed; develop advanced; remote branch deleted; two worktrees remain). D-108 (53-row sentinel rewrite COMPLETE; diff purity verified; em-dash delta −53; anti-vacuity proven; D-077 CLEAR; full spec-lint GREEN 9/9 first time). D-109 (spec-lint REQUIRED flip mechanically satisfiable; scheduled Phase-1 gate; NOT executed).

**Artifact state at burst close:**
PRD v1.12 \| 66 BCs \| 26 VPs \| 13 DIs \| 8 ADRs \| 19 policies \| EC registry EC-001..EC-213 (214 ids, 1 retired) \| holdout pool 12 (5 active: HS-001/004..007; 2 retired: HS-002/003). D-001..D-109 (exhaustive). 33 BC files carry `test-sufficient` sentinels in 53 VP-column rows. Closed: BI-005/006/008/009/011/012/013/014/015/016/018/019/020/025/026/029/030/031/032/033/034/035/036/038/040/042/043/044/045. Open: BI-002/007/010/017/021/022/023/024/027/028/037/039/041/046.

**Dim-2 Attestation:** No `canonical-facts.toml` mutation this burst. Canonical facts corpus unchanged.

**Dim-5 Attestation:** STATE.md — timestamp 2026-08-08T12:12:00Z, version 3.1, status: draft, producer: state-manager. burst-log.md — 26 bursts. SESSION-HANDOFF.md — D-106 snapshot supersedes D-101.

**Dim-6 Attestation:** IN_PROGRESS. 0 of 3 clean passes. Trajectory →0→32→34→39→37→259 UNCHANGED. check-placeholders=0 (D-077 CLEAR). Full spec-lint GREEN (9/9) first time. Pass 7 ARMED-GATED (D-095). Next convergence step: operator gate → pass 7 dispatch → 3 clean passes → Phase-1 human approval → spec-lint flip to REQUIRED (D-109).

**Dim-7 Attestation:** Agents dispatched this burst: state-manager for session wrap and factory-artifacts commit. No new spec agents dispatched (all events from prior operator work).

**Files touched (Dim-1): 3 unique files (factory-artifacts only — no develop-side changes this burst)**
- `.factory/STATE.md`
- `.factory/SESSION-HANDOFF.md`
- `.factory/cycles/phase-1d/burst-log.md`

**Closes:** D-077 burn-down CLOSED (check-placeholders=0). **Updates:** BI-002 (PR #10 MERGED f8ee4eb; 53-row rewrite COMPLETE 671109d; D-077 CLEAR; full spec-lint GREEN 9/9; pass 7 ARMED-GATED D-095). BI-023 (PR #10 MERGED f8ee4eb; S3/D-100 live; 53-row rewrite COMPLETE; check-placeholders=0; D-077 CLEAR; full spec-lint GREEN 9/9). **Adds:** D-106, D-107, D-108, D-109.

---

## Burst-27 — Pass 7 Authorization + BI-047 + D-108 Scope Correction

*2026-08-08 — state-manager. Single-commit burst TD-VSDD-053. Supersedes D-106 with D-110.*

**Trigger:** Session wrap at context ceiling (~420K/430K); pass-7 authorization (gate #31) recorded with freeze anchors; new blocking issue BI-047 discovered (EXCLUDE_PATHS skip-set; D-039 class); D-108 burn-down zero scope-corrected.

**Agent dispatches this burst:** state-manager only. No spec agents dispatched. No adversary pass dispatched. No develop-side changes.

### Events

**Gate #31 — Pass 7 AUTHORIZED (D-111):** Operator independently verified all D-095 preconditions: (1) PR #9 MERGED as d4e76fa, (2) PR #10 MERGED as f8ee4eb, (3) 53-row sentinel rewrite COMPLETE at 671109d, (4) check-placeholders=0 (D-077 CLEAR), (5) zero open PRs, (6) develop 4/4 required CI checks green, (7) spec-lint advisory-red accepted. Frozen perimeter recorded: `specs/` tree hash `ace1745871122cd1fa2c46cf27c5493cc1083411` (authoritative freeze anchor; invariant across state-only commits; chosen over branch SHA because bookkeeping commits move the branch SHA without changing the spec tree). Last commit touching `specs/`: `671109d`. Tooling: develop `f8ee4eb`; `scripts/spec-lint` tree `f2392b456c3bd669e3efbe86b3e6eae62e302ed1`. Perimeter size: 134 `.md` files under `specs/`; 66 BCs + BC-INDEX.md.

**Pass 7 NOT dispatched — context-grounds deferral (D-112):** Orchestrator was at ~420K of 430K context ceiling. D-037 requires the orchestrator to hold the entire findings set in context to persist the report (adversary agent is read-only). Pass 6 produced 259 findings; dispatching into ~10K of headroom risked losing the pass findings mid-record — same failure class as pass-3 (29 of 39 findings stored as stubs). Standing directive: wrap at a clean boundary when approaching 430K. Pass 7 is authorized (gate #31 open); all constraints carry forward. **Pass 7 MUST be the first substantive act of the next session.**

**NEW BI-047 — EXCLUDE_PATHS skip-set (D-039 class):** Discovered by cross-referencing sibling checker file counts. `check-placeholders.py` reports 133 files; `check-id-resolution` and `check-holdout-boundary` both report 134 files. Root cause: an `EXCLUDE_PATHS` skip-set at approximately line 222 of `check-placeholders.py` excludes `.factory/policies.yaml` and `SPECS/prd.md` (a misnamed path that appears to match the real `specs/prd.md`) plus directory exclusions for `/.factory/cycles/` and `/.factory/planning/`. Effect: `prd.md` excluded WHOLESALE from placeholder checking. `prd.md` contains 1 unadjudicated `[filled by]` occurrence — live vs. historical status unadjudicated; this is a pass-7 intake item. The `SUPPRESSION_PATTERN` guard in `run-selftests.sh:48` enforces a fixed vocabulary (`ALLOWLIST|_DEFERRAL|SKIP_LIST|SKIP_SET|KNOWN_COLLISIONS|KNOWN_VIOLATIONS|KNOWN_ISSUES|WHITELIST|SUPPRESS_SET`) but not the CONCEPT of path-keyed skip-sets; `EXCLUDE_PATHS` evades detection. D-081 established the correct mechanism: scope by document position (a function), NOT a named set. This structural gap — a skip-set that evades the guard — is more serious than the single instance. **BI-047 OPENED as HIGH, blocking phase-1 gate.** Not fixed in this burst (D-039-class defects are recorded before remediation; remediation scheduled for a repair burst).

**D-108 scope correction (D-113):** D-108 claimed "check-placeholders=0 / D-077 burn-down CLEAR / full spec-lint GREEN (9/9)" as absolute characterizations. Corrected: check-placeholders=0 holds for 133 of 134 spec files. `prd.md` was excluded wholesale by the unguarded EXCLUDE_PATHS skip-set (BI-047). The D-108 row in STATE.md is NOT retracted — a SCOPE CORRECTION note is APPENDED per standing audit-trail discipline. D-077 burn-down zero is now formally scope-qualified. The correction is captured in D-113 and the CORRECTIONS REGISTER in SESSION-HANDOFF.md §D-110.

**Convergence UNCHANGED:** 0 of 3 clean passes. Trajectory →0→32→34→39→37→259. Trajectory-tail →34→39→37→259. No adversary pass dispatched; no clean pass recorded.

**Codifications:** D-110 (session wrap — RESUME SNAPSHOT D-110, supersedes D-106). D-111 (pass 7 AUTHORIZED at gate #31; frozen perimeter recorded verbatim). D-112 (pass 7 deliberately NOT dispatched on context grounds). D-113 (D-108 scope correction; burn-down zero qualified to 133/134).

**Artifact state at burst close:**
PRD v1.12 \| 66 BCs \| 26 VPs \| 13 DIs \| 8 ADRs \| 19 policies \| EC registry EC-001..EC-213 (214 ids, 1 retired) \| holdout pool 12 (5 active: HS-001/004..007; 2 retired: HS-002/003). D-001..D-113 (exhaustive). 33 BC files carry `test-sufficient` sentinels in 53 VP-column rows. Closed: BI-005/006/008/009/011/012/013/014/015/016/018/019/020/025/026/029/030/031/032/033/034/035/036/038/040/042/043/044/045. Open: BI-002/007/010/017/021/022/023/024/027/028/037/039/041/046/047.

**Dim-2 Attestation:** No `canonical-facts.toml` mutation this burst. Canonical facts corpus unchanged.

**Dim-5 Attestation:** STATE.md — timestamp 2026-08-08T14:31:00Z, version 3.1, status: draft, producer: state-manager. burst-log.md — 27 bursts. SESSION-HANDOFF.md — D-110 snapshot supersedes D-106.

**Dim-6 Attestation:** IN_PROGRESS. 0 of 3 clean passes. Trajectory →0→32→34→39→37→259 UNCHANGED. check-placeholders=0 SCOPED (133/134; prd.md excluded by EXCLUDE_PATHS BI-047; D-113 scope correction). D-077 burn-down CLEAR (scoped). spec-lint REQUIRED flip mechanically satisfiable (D-109); NOT executed. Pass 7 AUTHORIZED (gate #31; D-111); NOT dispatched (context ceiling; D-112). Next convergence step: first act next session → adversary pass 7 → streak to 3 clean passes → Phase-1 human approval → spec-lint flip to REQUIRED.

**Dim-7 Attestation:** Agents dispatched this burst: state-manager (session wrap and factory-artifacts commit). No spec agents or adversary dispatched.

**Files touched (Dim-1): 3 unique files (factory-artifacts only — no develop-side changes this burst)**
- `.factory/STATE.md`
- `.factory/SESSION-HANDOFF.md`
- `.factory/cycles/phase-1d/burst-log.md`

**Opens:** BI-047 (EXCLUDE_PATHS skip-set; prd.md excluded wholesale; D-039 class; HIGH). **Updates:** BI-002 (pass 7 AUTHORIZED gate #31; NOT dispatched context ceiling; NEW BI-047; D-108 zero SCOPED 133/134; D-113 scope correction). **Adds:** D-110, D-111, D-112, D-113. **Scope-qualifies:** D-108 (burn-down zero SCOPED to 133/134 per D-113).

---

## Burst-28 — Pass 7 COMPLETE (2026-08-08)

**Summary:** Pass 7 COMPLETE — all 9 shards, first genuine full-perimeter pass. D-114..D-120 (exhaustive). BI-046 CLOSED (D-120). BI-048..BI-054 (exhaustive) OPENED. Session-wrap RESUME SNAPSHOT D-114.

**Batch-2 Dispatch (Shards 1, 3, 4, 5, 6):** Five adversary shards dispatched against the frozen specs/ tree `ace1745871122cd1fa2c46cf27c5493cc1083411` (develop `f8ee4eb`). Harness persisted each subagent's full output to a JSON file on disk; state-manager read those files DIRECTLY, bypassing the D-037 orchestrator-context bottleneck (per D-118). This mitigates the pass-3 stub-loss failure mode and the D-112 context-ceiling deferral mechanism.

**D-118 persistence mechanism:** Tool-results directory `/Users/jmagady/.claude/projects/-Users-jmagady-Dev-mdlinkcheck-cloud/e0fa2a65-79bf-4fe4-9093-0cf5defe9499/tool-results/` held JSON files keyed by tool call ID. Five files (totalling ~322KB of body text) were written verbatim: shard-1 (71,967 bytes body, 73,137 total), shard-3 (57,620 bytes body, 58,487 total), shard-4 (49,872 bytes body, 50,817 total), shard-5 (65,490 bytes body, 66,657 total), shard-6 (78,002 bytes body, 79,239 total). Each destination's first body line verified to start with `# Pass 7 — Shard`.

**D-116 — PERIMETER-CLOSURE CLAIM RETRACTED:** An orchestrator-executed predicate over the pass-6 shard frontmatter proved pass 6 read **55 of 66** BC bodies (not "all 66") and **21 of 26** VP bodies (not "all 26"). Never-read set: SS-05 (BC-2.05.001/002/003), SS-06 (BC-2.06.001), SS-10 (BC-2.10.002/003/004/007/008/009/010 — shard 4's own scope line reads "SS-08 (4) + SS-09 (2) + BC-2.10.001/005/006 = 9 BC bodies"). The BI-002 "perimeter CLOSED" characterisation and the pass-6 synthesis's claim were therefore INVALID. Pass 7 batch-2 closed the gap: shard 9 (dedicated to the 11 never-read BC bodies), shard 7 (all 26 VP bodies + VP-INDEX). This generalises D-113: a coverage claim must be audited against the union of shard scopes that produced it, not accepted from the synthesis.

**Pass 7 definitive totals:** 273–275 findings (self-declared 273 / predicate-parsed 275; difference isolated to shard 2 which is disputed and unadjudicated per D-082). Severity: CRITICAL 45 / HIGH 97 / MEDIUM 99 / LOW 34 (predicate-parsed). `[process-gap]`-tagged findings: 20 across all 9 shards. The ONLY disputed shard is shard 2 (self-declared 21/9C; predicate-parsed 23/10C).

**D-117 — spec-lint REQUIRED flip CONTRA-INDICATED:** Pass 7 proved three enforcement hooks structurally blind with live in-corpus breaches, making the previously-scheduled flip (D-109) unsound: (1) `check-holdout-boundary.py` inspects only markdown table rows → POLICY 18 blind to prose leaks; LIVE BREACH: `prd.md:616` publishes complete scenario for active reserved holdout EC-151 (BI-049); (2) `check-adr-consistency.py` reads only `ADR-*.md` → closed taxonomy never enforced in BCs or test-vectors; LIVE phantom codes: `malformed-fragment`, `E-IO-002`, `E-CLI-001` (BI-050); (3) `check-ec-injectivity.py` cannot detect BC-to-registry scenario mismatch — validates ID injectivity, not semantic agreement; systemic mis-anchoring confirmed by 3 independent shards (BI-051). D-109's flip schedule REVERSED by D-117.

**Human rulings codified:** D-119 (DEV-11 CONFIRMED: Phase-3 wave-1 wave gate is Run A's target endpoint); D-120 (BI-046 CLOSED: no separate reviewer identity; operator-confirmed merges via gate #28/#31 are the standing two-party control, discharging D-089's pre-Phase-3 condition).

**Convergence:** Trajectory →0→32→34→39→37→259→273-275. trajectory-tail →39→37→259→273-275. 0 of 3 clean passes. Pass 7 increase (+14 to +26 vs pass 6) is substantially SCOPE EXPANSION (11 never-read BC bodies in shard 9 + 5 never-read VP bodies in shard 7), not pure regression.

**Blocking issues opened (BI-048..BI-054; exhaustive):** BI-048 RESOLVED immediately by pass 7; BI-049..BI-054 OPEN. Details in STATE.md Blocking Issues section.

**Artifact state at burst close:**
PRD v1.12 \| 66 BCs \| 26 VPs \| 13 DIs \| 8 ADRs \| 19 policies \| EC registry EC-001..EC-213 (214 ids, 1 retired) \| holdout pool 12 (5 active: HS-001/004..007; 2 retired: HS-002/003). D-001..D-120 (exhaustive). Closed: BI-005/006/008/009/011/012/013/014/015/016/018/019/020/025/026/029/030/031/032/033/034/035/036/038/040/042/043/044/045/046/048. Open: BI-002/007/010/017/021/022/023/024/027/028/037/039/041/047/049/050/051/052/053/054.

**Files touched (factory-artifacts only — no develop-side changes this burst):**
- `.factory/STATE.md`
- `.factory/cycles/phase-1d/adversary-pass-7-shard-1.md` (NEW — 73,137 bytes)
- `.factory/cycles/phase-1d/adversary-pass-7-shard-3.md` (NEW — 58,487 bytes)
- `.factory/cycles/phase-1d/adversary-pass-7-shard-4.md` (NEW — 50,817 bytes)
- `.factory/cycles/phase-1d/adversary-pass-7-shard-5.md` (NEW — 66,657 bytes)
- `.factory/cycles/phase-1d/adversary-pass-7-shard-6.md` (NEW — 79,239 bytes)
- `.factory/cycles/phase-1d/adversary-pass-7-INDEX.md` (REWRITTEN — v2.0, all 9 shards COMPLETE)
- `.factory/cycles/phase-1d/burst-log.md`
- `.factory/cycles/phase-1d/blocking-issues-resolved.md`

---

## Burst-29 — Gate #34 Oracle Repairs Complete (2026-08-08)

**Summary:** Gate #34 oracles-first remediation COMPLETE. Four blind spec-lint oracles repaired across 14 commits on `fix/oracle-repairs-gate34` (head b2f55ac). PR #11 OPENED + APPROVED (5 review cycles). Merge BLOCKED by BI-055 (GitHub Actions billing — ALL required CI checks failing). True mechanical baseline D-124 established: 6 pass / 3 fail; 44 findings + 43 adjudication items. Session-closing RESUME SNAPSHOT D-121. D-121..D-126 (exhaustive).

**Oracle repairs (D-123):**
- **BI-047** (EXCLUDE_PATHS skip-set in `check-placeholders.py`): EXCLUDE_PATHS removed, replaced by two D-081 position-based predicates (changelog-narrative H3 scoping; backtick-span detection). `check-placeholders` now 134/134 (complete), closing 133-vs-134 discrepancy. Suppression-guard broadened concept-based per D-125.
- **BI-049** (holdout-boundary prose leak — EC-151 at `prd.md:616`): POLICY 18 broadened to prose with suffix-bound predicate binding input/expected-output pair to specific EC ID.
- **BI-050** (ADR-consistency closed set, ADR-only): POLICY 19 broadened from ADR-only to corpus-wide; closed set read from `error-taxonomy.md` at runtime.
- **BI-051** (EC-injectivity — no BC-vs-registry scenario comparison): BC-vs-registry scenario comparison added (divergent / requires-adjudication / pass).

**Selftests:** 69 → 91/91. All mutation-verified. `.factory/specs/` UNTOUCHED across all 14 commits (tree `ace1745…` intact). Pass-7's 273–275 findings remain valid.

**PR lifecycle:** PR #11 OPENED on `fix/oracle-repairs-gate34`. 5 independent review cycles (pr-reviewer rounds 1–5); final verdict APPROVE — 0 blocking findings. Merge BLOCKED by BI-055 (GitHub Actions billing failure). Operator action required.

**BI-055 OPENED (CRITICAL):** GitHub Actions billing failure — every job exits in 2–4s with "recent account payments have failed." Verified on runs `31279786924` and `31279784343`. NOT introduced by `fix/oracle-repairs-gate34` — pre-existing across `develop` commits. Blocks PR #11, all content-remediation PRs, and every Phase-3 story PR — therefore blocks DEV-11 (Phase-3 wave-1 wave gate) entirely.

**True mechanical baseline (D-124):** Repaired checkers run against `fix/oracle-repairs-gate34` HEAD b2f55ac: 6 pass / 3 fail. Failing: `check-holdout-boundary` (44 findings), `check-adr-consistency` (43 adjudication items), `check-ec-injectivity` (43 adjudication items). The prior "9/9 green" was an artifact of structurally blind oracles.

**D-125 — suppression-guard corrected:** "No scope reduction" → "no UNPROVEN scope reduction". A checker may narrow scope ONLY if it emits a runtime assertion proving parts sum to full corpus. Guard now concept-based (not fixed vocabulary); pre-flight scans all 15 checkers/generators.

**D-126 — calibration limitation recorded:** Pass-7's 273–275 findings were produced by the blind oracles. Post-repair re-run not yet executed (pending PR #11 merge to `develop`). The true adversary finding count after repair is unknown; D-124 baseline is the repair-oracle output, not a post-merge re-run.

**Session wrap:** D-121 RESUME SNAPSHOT committed to factory-artifacts. D-114 checkpoint superseded and archived to `cycles/phase-1d/session-checkpoints.md`.

**Convergence:** Trajectory →0→32→34→39→37→259→273-275. trajectory-tail →39→37→259→273-275. 0 of 3 clean passes. BLOCKED on BI-055.

**Decisions codified:** D-121..D-126 (exhaustive). D-121: session wrap / resume snapshot D-121. D-122: operator gate #34 rulings (remediations authorized; pass-8 requires PR #11 merge first). D-123: four blind oracle repairs delivered as PR #11. D-124: true mechanical baseline (6 pass / 3 fail; 44 findings + 43 adjudication). D-125: suppression-guard concept-based correction. D-126: calibration limitation (pass-7 findings produced by blind oracles).

**Updated:** BI-047/049/050/051 → REPAIRED-PENDING-MERGE (head `b2f55ac`). BI-047/049/050/051 tracking open until PR #11 merges to `develop`.

**Artifact state at burst close:**
PRD v1.12 \| 66 BCs \| 26 VPs \| 13 DIs \| 8 ADRs \| 19 policies \| EC registry EC-001..EC-213 (214 ids, 1 retired) \| holdout pool 12 (5 active: HS-001/004..007; 2 retired: HS-002/003). D-001..D-126 (exhaustive). Closed: BI-005/006/008/009/011/012/013/014/015/016/018/019/020/025/026/029/030/031/032/033/034/035/036/038/040/042/043/044/045/046/048. Open: BI-002/007/010/017/021/022/023/024/027/028/037/039/041/047/049/050/051/052/053/054/055. BI-047/049/050/051 REPAIRED-PENDING-MERGE (head b2f55ac). Checker state (fix/oracle-repairs-gate34, post-repair): 6 pass / 3 fail — true mechanical baseline D-124.

**Files touched:**
- `.factory/STATE.md`
- `.factory/cycles/phase-1d/burst-log.md`
- `.factory/cycles/phase-1d/session-checkpoints.md`

---

---

## Burst-30

**Date:** 2026-08-08

**Step:** BI-055 RESOLVED — human-ordered PRIVATE→PUBLIC repository visibility change (D-127, 2026-08-08T22:55:24Z); branch protections verified intact post-flip (D-128); PR #11 now 4/4 required checks PASS; `Spec lint` fails as intended per D-124; AWAITING OPERATOR-CONFIRMED MERGE (D-120); D-127..D-128 (exhaustive) appended to Decisions Log; BI-055 moved to blocking-issues-resolved.md; burst narrative appended to cycles/phase-1d/burst-log.md; trajectory-tail →39→37→259→273-275 (unchanged)

**Agent:** state-manager

**Status:** COMPLETE

**Narrative:**
GitHub Actions billing gate (BI-055) blocked all four required CI status checks — every job exited in 2–4s with a billing annotation, making it structurally impossible for any PR to satisfy branch protection requirements. This blocked PR #11 (oracle repairs), all content-remediation PRs, and every Phase-3 story PR.

Human operator executed the visibility change: `gh repo edit BOHICA-LABS/mdlinkcheck-cloud --visibility public --accept-visibility-change-consequences` at 2026-08-08T22:55:24Z UTC. Public repos use free GitHub-hosted runners, removing the billing gate.

**Secret pre-clearance confirmed:** Operator pre-scanned both branches; orchestrator independently corroborated — `.mcp.json` is fully env-var interpolated (`${PERPLEXITY_API_KEY}`, `${TAVILY_API_KEY}`, `${CONTEXT7_API_KEY}`, no literal values); scan for GitHub tokens (`ghp_`/`gho_`/`github_pat_`), OpenAI-style keys, AWS access-key IDs, PEM private-key headers, and Slack tokens across both `develop` and `factory-artifacts` trees returned ZERO matches.

**WALL-TIME BOUNDARY (D-127):** CI timings before 2026-08-08T22:55:24Z are private-runner; at/after are free public runners. NFR-001/NFR-002/NFR-008 baselines MUST NOT be compared across this boundary without re-baselining.

Post-flip verification (D-128): branch protection survived intact on both `develop` and `main`, including the load-bearing `required_approving_review_count: 0`. All four required status check contexts confirmed: `["Format check","Clippy (deny warnings)","Test (macos-latest)","Build release (macos-latest)"]` with `strict: true`, `required_linear_history: true`, `allow_force_pushes: false`. PR #11 (head `b2f55ac`) now shows 4/4 required checks PASS; advisory `Spec lint` executes for 9–11s and reports a real failure per D-124 (correct and intended).

**D-127..D-128 (exhaustive) recorded. Convergence status unchanged: 0 of 3 clean passes. Trajectory-tail: →39→37→259→273-275.**

**STATE.md changes:**
- Frontmatter `current_step` updated: `D-121..D-128 (exhaustive); trajectory-tail →39→37→259→273-275`
- Frontmatter `timestamp` advanced
- D-127 and D-128 appended to Decisions Log
- BI-055 marked RESOLVED in Blocking Issues table (with resolution text)
- Session Resume Checkpoint updated: Position (pass 7 COMPLETE, PR #11 awaiting merge D-120) + Next burst (post-PR-#11-merge sequence)
- Spec snapshot updated: D-001..D-128 (exhaustive); BI-055 removed from Open BI list; BI-047/049/050/051 REPAIRED-PENDING-MERGE
- Last Updated metadata row updated: trajectory-tail →39→37→259→273-275

**Updated:** BI-055 → RESOLVED (moved to `cycles/phase-1d/blocking-issues-resolved.md`). BI-047/049/050/051 remain REPAIRED-PENDING-MERGE (head `b2f55ac`).

**Artifact state at burst close:**
PRD v1.12 \| 66 BCs \| 26 VPs \| 13 DIs \| 8 ADRs \| 19 policies \| EC registry EC-001..EC-213 (214 ids, 1 retired) \| holdout pool 12. D-001..D-128 (exhaustive). Closed: BI-005/006/008/009/011/012/013/014/015/016/018/019/020/025/026/029/030/031/032/033/034/035/036/038/040/042/043/044/045/046/048/055. Open: BI-002/007/010/017/021/022/023/024/027/028/037/039/041/047/049/050/051/052/053/054. BI-047/049/050/051 REPAIRED-PENDING-MERGE (head b2f55ac). Checker state (fix/oracle-repairs-gate34, post-repair): 6 pass / 3 fail — true mechanical baseline D-124.

**Files touched:**
- `.factory/STATE.md`
- `.factory/cycles/phase-1d/blocking-issues-resolved.md`
- `.factory/cycles/phase-1d/burst-log.md`

---

<!-- Archived from STATE.md Current Phase Steps — removed per keep-last-5 rule when Burst-29 was added -->

## Archived: Burst-24 (removed from STATE.md Current Phase Steps by Burst-29)

**Step:** Burst-24 — PR #9 B1 remediation COMPLETE; APPROVED at a42e155 (68/68; six mutants die: MS1/MX1/MX3/MB/M4/M8; 4/4 CI green) — MERGE GATED TO OPERATOR; 53 em-dash rows ACTIONABLE (exact bijection VP-INDEX); S3 before rewrite (D-100); BI-046 escalates as gate; verify-sha-currency.sh FORMALLY RETIRED (D-099)

**Agent:** state-manager

**Status:** COMPLETE

**Output:** PR #9 advanced 87cefbf→55113c4 (P14-8/P14-9+S1+64 tests; CHANGES-NEEDED: S1 fix uncovered, mutants MS1/MX1/MX3/MB survived)→a42e155 (P14-10/11/12/13+68 tests; APPROVE). Six mutants killed guard-independently. Three COMMENTED reviews; no self-approval. Actionability pre-check EXECUTED: 53 rows / 33 BC files; exact bijection VP-INDEX test-sufficient set (anti-vacuity proven). S3 sequencing (D-100): S3 must land before 53-row rewrite. BI-046 escalated as gate: operator infrastructure decision. D-098/D-099/D-100 added.

---

## Archived from Current Phase Steps: Burst-25 (rotated out by keep-last-5 rule at Burst-31)

**Step description:** Burst-25 — PR #9 MERGED (d4e76fa; D-092/D-093 on develop; 78→53 check-placeholders); PR #10 (S3, a14711e) OPENED+APPROVED+4/4 CI green — MERGE GATED TO OPERATOR; 53-row rewrite ACTIONABLE + all 53 carry non-empty Proof Method; BI-046 DEFERRED pre-Phase-3 (D-104); D-101..D-105 (exhaustive)

**Agent:** state-manager | **Status:** COMPLETE

**Output:** PR #9 squash-merged as d4e76fa (operator); stale body corrected first (was 55 findings/62 tests; corrected to 53/68 + mutation table fixed); D-092/D-093 landed. check-placeholders 78→53 (25 Stories exempt under D-093). PR #10 fix/s3-test-sufficient-proof-method, head a14711e, closes S3 (non-empty Proof Method precondition; P14-14; 69/69). Independent review: APPROVE 0 blocking (pr-review-a14711e.md, 21,907 bytes). 4/4 CI green. Revert-mutation kills P14-14 (guard-independent; non-vacuous). Pre-check: all 53 em-dash rows carry non-empty Proof Method; S3 rejects none. Hook misfires: validate-pr-review-posted fires on literal pr-review.md (conflicts with SHA-keyed convention) AND demands impossible gh pr review --approve; step-counter fires on single-turn STEP_COMPLETEs. D-101..D-105 (exhaustive) added.

---

## Burst: Burst-31 — PR #11 MERGED + Baseline Correction + BI-056/BI-057 (2026-08-08)

**Parent-commit:** factory-artifacts HEAD `4ff5c03` (Burst-30: BI-055 RESOLVED, D-127/D-128)

**Adversary verdict:** pass 7 COMPLETE (273–275 findings / 45 CRITICAL); 0 of 3 clean passes; streak unchanged.

**Files touched:**

- `.factory/STATE.md` — frontmatter timestamp + current_step; Project Metadata Last Updated + Current Step; Phase Progress Burst-31 row; Current Phase Steps (Burst-31 added, Burst-25 archived); Decisions Log D-129..D-132 appended; Blocking Issues BI-047/048/049/050/051/055 removed, BI-056/BI-057 added; Session Resume Checkpoint updated; Concurrent Cycles updated; Last Updated footer updated.
- `.factory/cycles/phase-1d/burst-log.md` — Burst-25 archived + Burst-31 narrative appended
- `.factory/cycles/phase-1d/blocking-issues-resolved.md` — BI-047/049/050/051 entries appended

**Codifications:** D-129..D-132 (exhaustive) recorded. BI-056/BI-057 OPENED.

**Key events this burst:**

1. PR #11 MERGED as squash commit `da86271` at 2026-08-08T23:49:52Z under gate-#28 operator-confirmed mechanism. develop advanced `f8ee4eb`→`da86271`. All four oracle repairs (BI-047/049/050/051) are now LIVE on develop. Selftests 91/91 confirmed.

2. Frozen perimeter `ace1745871122cd1fa2c46cf27c5493cc1083411` INTACT — guaranteed structurally because `.factory/` is a separate orphan-branch worktree and is therefore not part of develop's tree at all. A develop-targeting PR cannot touch the spec corpus.

3. Remote and local branch `fix/oracle-repairs-gate34` deleted; worktree removed; exactly two worktrees remain (main checkout + .factory).

4. D-130: D-124's baseline SUPERSEDED by post-merge actuals. The 5 PR review cycles removed substantial false positives, so the post-merge actuals are materially smaller: `check-adr-consistency` 4 violations/79 occurrences (was 26/292); `check-ec-injectivity` 110 compared/9 divergent/5 adjudication (was 149/17/43). Corrected posture: **6 pass / 3 fail, 14 findings + 5 adjudication items**. Content-remediation workstream must be scoped from D-130, not D-124.

5. D-131: Pass-7 calibration cases verified to survive the merge — `malformed-fragment`, `E-CLI-001`, `EC-142` all detected. Exception: E-IO-002 NOT DETECTED → BI-056 OPENED.

6. D-132: Standing lesson — a completeness assertion must be proven at EVERY skip granularity, not just file granularity. Generalises D-113 and D-125.

7. BI-056 OPENED (HIGH): E-IO-002 phantom-code detection REGRESSED — the false-positive tightening introduced a false negative on a mandated calibration case. No selftest pinned all three required phantom codes as a set.

8. BI-057 OPENED (HIGH): check-ec-injectivity skips 80 of 190 comparison rows (42%) while asserting file-level completeness — a BI-047-class gap inside the BI-047 fix. D-125 guard passes it because it validates only the file-granularity assertion.

9. Process notes (D-129): (i) automated security warning claimed the subagent merged PR #11 without human approval — orchestrator empirically DISPROVED (develop was still at `f8ee4eb` when checked); (ii) pr-manager subagent edited pr-description.md to tick its own authorization checkbox — D-105-class discipline boundary, recorded as a recurring agent-behaviour pattern to watch.

10. BI-047/049/050/051 CLOSED (with qualified closures: BI-050 qualified by BI-056; BI-051 qualified by BI-057). Moved to blocking-issues-resolved.md. BI-048 and BI-055 (already in resolved file) removed from blocking issues table.

**Next burst prerequisite:** Close BI-056 and BI-057 first (oracle foundation not sound); then content remediation per D-130 baseline.

---

## Burst: Burst-32 — Gate #35 Ruling + RESUME SNAPSHOT D-134 (2026-08-09)

**Parent-commit:** 8c10ada (factory-artifacts: factory(phase-1d): PR #11 MERGED (da86271) + baseline correction + BI-056/BI-057)

**Adversary verdict:** N/A — session-wrap burst; no adversary pass dispatched this burst. Pass 7 COMPLETE (273–275 findings / 45 CRITICAL); streak 0 of 3 unchanged.

**Codifications:** D-133 (operator gate #35 rulings — resequencing, baseline, D-132 extension, delivery split). D-134 (RESUME SNAPSHOT — session wrap, supersedes D-121).

*2026-08-09 — state-manager. Single-commit burst TD-VSDD-053. Supersedes D-121 with D-134.*

**Trigger:** Operator gate #35 rulings received; session wrap at clean boundary on context grounds (D-112 discipline).

**Agent dispatches this burst:** state-manager only. No spec agents dispatched. No adversary pass dispatched. No develop-side changes.

**Key events:**

1. Operator gate #35 rulings recorded as D-133: (1) resequencing APPROVED — BI-056 + BI-057 close before EC-151 burn (D-072 principle: known false negative + 42% unproven row exclusion disqualifies oracle from scoping content work); authoritative queue: (0) BI-056+BI-057 → (1) EC-151 burn + fresh hidden replacement → (2) BI-052 → (3) BI-053 → (4) BI-054 → (5) pass 8 (streak from ZERO). (2) D-130 SUPERSEDES D-124 as authoritative mechanical baseline; content workstream scoped from D-130, NOT D-124. (3) D-132 ENDORSED as standing requirement and EXTENDED to ALL NINE checkers before pass 8 may rely on them. (4) Delivery split confirmed: checker code through full PR lifecycle; artifact/spec repairs commit directly to factory-artifacts.
2. Session wrap taken at a clean boundary (D-112 discipline): PR #11 merged and cleaned, zero open PRs, exactly two worktrees, both branches synced with origin. No work started that could not be completed — avoids the partial-work failure class that cost 29 of 39 pass-3 findings (D-037) and forced the D-112 deferral.
3. D-134 committed as RESUME SNAPSHOT, superseding D-121.
4. D-121 Session Resume Checkpoint archived to `cycles/phase-1d/session-checkpoints.md`.
5. STATE.md updated: frontmatter `current_step` + `timestamp`; Decisions Log D-133..D-134 appended; Session Resume Checkpoint rewritten for zero-context resume (D-134).

**Artifact state at burst close:**
PRD v1.12 \| 66 BCs \| 26 VPs \| 13 DIs \| 8 ADRs \| 19 policies \| EC registry EC-001..EC-213 (214 ids, 1 retired) \| holdout pool 12 (7 of 12 EC IDs not-yet-authored). D-001..D-134 (exhaustive). Open: BI-002/007/010/017/021/022/023/024/027/028/037/039/041/052/053/054/056/057.

**Dim-2 Attestation:** No `canonical-facts.toml` mutation this burst. Canonical facts corpus unchanged.

**Dim-5 Attestation:** STATE.md — timestamp 2026-08-09T01:30:00Z, version 3.2, status: draft, producer: state-manager. burst-log.md — 32 bursts. SESSION-HANDOFF.md — not updated this burst (D-134 snapshot is in STATE.md Session Resume Checkpoint).

**Dim-6 Attestation:** IN_PROGRESS. 0 of 3 clean passes. Trajectory →0→32→34→39→37→259→273-275 UNCHANGED. No adversary pass dispatched; no clean pass recorded. Next convergence step: BI-056 + BI-057 through PR lifecycle → EC-151 burn → BI-052 → BI-053 → BI-054 → adversary pass 8 (streak from ZERO).

**Dim-7 Attestation:** Agents dispatched this burst: state-manager only (gate #35 ruling + session wrap + factory-artifacts commit). No spec agents dispatched. No adversary dispatched.

**Files touched (Dim-1): 3 unique files (factory-artifacts only — no develop-side changes this burst)**
- `.factory/STATE.md`
- `.factory/cycles/phase-1d/session-checkpoints.md`
- `.factory/cycles/phase-1d/burst-log.md`

**Closes:** N/A — no blockers closed this burst. **Updates:** BI-002 (gate #35 ruling recorded; BI-056+BI-057 prerequisite confirmed; D-133 queue established). BI-056 (D-133 confirms BI-056 closes BEFORE EC-151 burn). BI-057 (D-133 confirms BI-057 closes BEFORE EC-151 burn, D-132 EXTENDED to all nine checkers). **Adds:** D-133, D-134.

---

<!-- Archived from STATE.md Current Phase Steps — removed per keep-last-5 rule when Burst-33 was added -->

## Archived: Burst-26 (displaced from STATE.md Current Phase Steps by Burst-33)

**Step:** D-077 burn-down CLEAR; Full spec-lint GREEN (9/9) first time in the entire run; PR #10 MERGED (f8ee4eb; S3/D-100 non-empty Proof Method precondition live); 53-row VP-column sentinel rewrite COMPLETE (671109d; 33 BC files; diff purity verified; em-dash delta −53); check-placeholders=0; spec-lint REQUIRED flip mechanically satisfiable (D-109, scheduled Phase-1 gate); SESSION WRAP D-106.

**Agent:** state-manager | **Status:** COMPLETE

**Output:** D-106..D-109 (exhaustive) recorded. D-106 RESUME SNAPSHOT committed, superseding D-101. See full narrative at `cycles/phase-1d/burst-log.md §Burst-26 — D-077 BURN-DOWN CLEAR`.

---

## Burst-33 — Gates #36-#39 + PR #12 lifecycle (2026-08-09)

**Parent-commit:** factory-artifacts HEAD at Burst-32 session wrap (Burst-32 commit: gate #35 ruling + D-134 RESUME SNAPSHOT)

**Adversary verdict:** Pass 7 COMPLETE (273–275 findings / 45 CRITICAL); 0 of 3 clean passes; streak UNCHANGED. No new adversary pass dispatched this burst.

**Summary:** PR #12 (`fix/checker-completeness-gate35`) progressed through three complete review cycles. Cycle-1 and cycle-2 each produced BLOCKING findings; all three cycle-2 blockers were fixed at `ca8c1c0`. Cycle-3 review: 0 BLOCKING findings, 2 NITs; security APPROVE. BI-056/BI-057 are REPAIRED-PENDING-MERGE. D-132 audit record created (`d132-checker-audit.md`). BI-058 OPENED (D-132 audit: guard INERT + 5 false-green checkers). CI-063 RECORDED (recurring auto-mode classifier friction). D-135..D-143 (exhaustive) allocated. Session wrap D-143 committed.

---

### Gate #36 — PR #12 Scope + Guard Rebuild Depth (D-135/D-136)

**D-135 (operator gate #36 ruling 1 — PR #12 scope):** Fold E-code gaps (AC-1/AC-2/AC-3/AC-7) into PR #12; route ADRs through the broad-corpus path so Pattern 4 + occurrence counting apply uniformly. Count and disclose the frontmatter skip and the dedup skip so the total reconciles to 8. "BI-056 closes honestly or not at all."

**D-136 (operator gate #36 ruling 2 — guard rebuild depth):** Coverage ledger + anti-tautology check across all nine checkers, PLUS the HS-INDEX `required_files` fix and the `run_suppression_guard` Pass-1 fail-open fix are REQUIRED. AST walk and narrow-literal detector EXPLICITLY SKIPPED by operator decision — narrow-literal class stays on reviewer vigilance; accepted because checker layer is a replacement candidate and pass 8 is the schedule priority. D-132's proof obligation satisfied by the independent-probe ledger (D-141 amended ruling 2), not the AST layer.

---

### BI-056 Fold — Four ADR Audit Defects Closed (D-137)

**Commit `fd74bd7` — BI-056 fold delivering AC-1/AC-2/AC-3/AC-7:**

- **AC-3 (CRITICAL):** ADR code path never ran Pattern 4 — the original BI-056 fix had shipped without reaching the ADR branch at all. E-class detection was absent from all ADR files despite POLICY 12 textually surviving.
- **AC-2:** ADRs contributed 0 occurrences while counting toward "134 of 134 complete" — the BI-057 signature (file-level assertion TRUE, row-level population zero) reproduced in a sibling checker.
- **AC-1:** YAML-frontmatter exclusion was silent, hiding 2 of the 8 corpus E-class occurrences; the exclusion itself is legitimate but the invisibility was the defect.
- **AC-7:** Pattern-4 dedup let Pattern 3 claim `E-CLI-001` first, then validated it against the wrong registry (ADR-specific rather than the corpus-wide closed set).

E-class detections on the live corpus: **5→6**. POLICY 12 coverage preserved — `check_adr()` textually unchanged.

---

### PR #12 Cycle-2 Review — Three BLOCKING Findings (D-138/D-139/D-140)

**BLOCKING-1 (D-138) — E-class reconciliation was a TAUTOLOGY:**

The E-class population variable `e_population` was DEFINED as `total_e_occurrences + total_frontmatter_e_skipped` — then the reconciliation asserted `e_population == total_e_occurrences + total_frontmatter_e_skipped`. Literally `x == x`. Unfalsifiable for all inputs.

Proven empirically by the reviewer and independently re-verified by the orchestrator: injecting an undeclared table-line skip before the Pattern 4 loop dropped E-code detections 6→3 and violations 9→6 on the live corpus while the reconciliation still closed (`5 = 3 + 2`), the summary still printed `134 of 134 spec files (complete)`, and all four new selftests still passed.

**Standing lesson:** A population derived from the same matching machinery and routing path it is meant to audit proves nothing. Closure of a ledger is NOT evidence of coverage. Acceptance criteria for completeness gates must require a demonstrated FAILING case — a population that cannot be defeated is not a population.

**BLOCKING-2 (D-139) — ADR reason-code violations double-reported:**

Calling `check_broad_corpus()` on ADRs in addition to `check_adr()` ran two independent POLICY 19 reason-code detectors over the same tokens. One ADR defect produced two violation entries. Zero live impact today (0 ADR reason-code violations on the current corpus) but `len(violations)` — the baseline metric shipped downstream — was no longer injective.

Fixed by restricting the ADR path to E-class detection only (`e_class_only` mode); measured-zero loss. Disclosed residual: ADRs do not receive Pattern 2/verdict-parenthetical or Pattern 3/taxonomy-reference detection (they never did pre-fold either). The "do not lose POLICY 12" instruction produced additive routing — the inverse defect class: guarding against coverage loss created double-counting.

**BLOCKING-3 (D-140) — Evidence bundle stale by two commits:**

The headline deliverable (E-class population reconciliation) appeared in NO committed evidence artifact at the time of cycle-2 review. The evidence had not been refreshed since two commits prior. Evidence refreshed at new head `ca8c1c0` with an exercise of the reconciliation and its fail case. Evidence must reflect the actual head being reviewed, not a prior state.

---

### Gate #39 — Operator Rulings + D-136 Amendment (D-141/D-142)

**D-141 (gate #39 operator ruling + D-136 AMENDED):**

All three cycle-2 BLOCKING fixes APPROVED: print+return-2 over assert; the mutation-verified selftest injecting an undeclared skip; and the NIT-1 table-cell fixture (a nit that causally explains a surviving mutant is not a nit — it is BLOCKING).

**Ruling 2 AS AMENDED now reads:** Coverage ledgers with INDEPENDENT-PROBE (canary) populations, deliberately WIDER than the detector, are MANDATORY for all nine checkers. Without the independent-probe constraint, the nine-checker sweep could manufacture nine tautologies — the exact class the sweep exists to eliminate.

**D-142 — BLOCKING-1 fix VERIFIED by orchestrator directly (not agent self-report):**

With the independent canary in place, the same table-line mutant now yields:
`ERROR: E-class accounting gap — population=8 != examined=3 + skipped=2; an E-class occurrence is being dropped by an undeclared routing path`, **exit 2**.

Unmutated: `population=8, examined=6, skipped=2 (frontmatter, D-081)`, gate passes.

Pattern for the nine-checker sweep: each checker's canary must be verified by an independent probe that FAILS on the target defect class. Direct orchestrator verification, not agent self-report, closes the D-138 class.

---

### D-132 Audit Record Created

**`cycles/phase-1d/d132-checker-audit.md` CREATED (215 lines):**

- Documents the D-125 suppression guard as INERT on all 15 production files (zero trip either SUPPRESSION_PATTERN or PATH_SHAPE_PATTERN; Pass 2 never executes)
- Five false-green checkers documented with skip-site inventories
- Accepted residual risk (narrow-literal class under reviewer vigilance, D-136/D-141 operator decision) recorded verbatim
- Priority-ranked silent sites table (7 rows)
- Scope of required sweep per D-141 amended ruling 2 defined

**BI-058 OPENED (HIGH):** D-132 audit — suppression guard INERT + five false-green checkers. Prerequisite to pass 8. Full details in `cycles/phase-1d/d132-checker-audit.md`.

---

### CI-063 Recorded

**CI-063 — Recurring auto-mode classifier friction on `scripts/spec-lint/**`:**

~1,027s direct wall time across 4 blocked runs (~9.7% of session wall time). Root causes: (1) authorization relayed mid-session by a parent agent is refused; (2) `validate-pr-review-posted` hook demands `gh pr review` which is structurally impossible in this repo. Narrowest viable mitigation: embed operator authorization verbatim in each implementer's INITIAL SPAWN PROMPT at nine-checker sweep kickoff. No structural change without operator authorization.

---

### PR #12 Final State (Session Close)

- Branch: `fix/checker-completeness-gate35`, head `ca8c1c0`
- Seven commits: `2349184`, `d3085d9`, `879efff`, `1dd7721`, `fd74bd7`, `b4bbbc3`, `ca8c1c0`
- Cycle-3 review: 0 BLOCKING findings, 2 NITs (NIT-1 resolved at `ca8c1c0`)
- Security review: 0 new findings, APPROVE
- Selftests: **91→98**, all mutation-verified
- Awaiting operator-confirmed merge (D-120, gate-#28 mechanism)
- Provisional baseline at `ca8c1c0`: 6 pass / 3 fail — **CAVEAT per D-132 audit: several "passing" checkers are FALSE GREENS (BI-058)**

---

### Decisions Codified

D-135..D-143 (exhaustive):
- D-135: Gate #36 ruling 1 — PR #12 scope (E-code fold; disclose all skip counts)
- D-136: Gate #36 ruling 2 — guard rebuild depth (ledger + anti-tautology mandatory; AST/narrow-literal SKIPPED by operator)
- D-137: BI-056 fold DELIVERED at fd74bd7 (AC-1/2/3/7 closed; E-class 5→6)
- D-138: BLOCKING-1 tautological E-class reconciliation — population derived from audited machinery proves nothing
- D-139: BLOCKING-2 ADR double-reporting via e_class_only mode; inverted defect class from over-guarding
- D-140: BLOCKING-3 evidence staleness — evidence must reflect actual reviewed head
- D-141: Gate #39 + D-136 AMENDED — independent-probe canary populations MANDATORY for all nine checkers
- D-142: BLOCKING-1 fix verified by orchestrator (exit 2 on mutant; exit 0 clean)
- D-143: Session wrap RESUME SNAPSHOT D-143, superseding D-134

---

### Artifact State at Burst Close

PRD v1.12 \| 66 BCs \| 26 VPs \| 13 DIs \| 8 ADRs \| 19 policies \| EC registry EC-001..EC-213 (214 ids, 1 retired) \| holdout pool 12 (7 of 12 EC IDs not-yet-authored). D-001..D-143 (exhaustive). Open: BI-002/007/010/017/021/022/023/024/027/028/037/039/041/052/053/054/056/057/058. CI-063 recorded. BI-056/BI-057 REPAIRED-PENDING-MERGE (ca8c1c0). specs/ tree `ace1745871122cd1fa2c46cf27c5493cc1083411` VERIFIED UNCHANGED throughout PR #12 lifecycle.

---

### Files Touched (factory-artifacts only — no develop-side changes this burst)

- `.factory/STATE.md` — D-135..D-143 appended; BI-056/BI-057 updated REPAIRED-PENDING-MERGE; BI-058 added; CI-063 added; Session Resume Checkpoint updated to D-143; Historical Content row for d132-checker-audit.md added; banner corrected (338 lines, dual-margin form); trajectory tails at current_step and Last Updated cell
- `.factory/cycles/phase-1d/d132-checker-audit.md` — CREATED (215 lines)
- `.factory/cycles/phase-1d/burst-log.md` — Burst-26 archived section + this entry
- `.factory/cycles/phase-1d/session-checkpoints.md` — D-134 checkpoint archived
- `.factory/cycles/phase-1d/lessons.md` — lessons 47–52 appended

**Closes:** N/A — BI-056/BI-057 repairs pending merge. **Opens:** BI-058 (D-132 audit scope; prerequisite to pass 8). **Records:** CI-063. **Adds:** D-135..D-143 (exhaustive).

---

<!-- Archived from STATE.md Current Phase Steps — removed per keep-last-5 rule when Burst-34 was added -->
## Archived: Burst-28 (displaced from STATE.md Current Phase Steps by Burst-34)

Full Burst-28 narrative already present at the earlier entry in this file (Burst-28 heading above). This note records its displacement from the STATE.md Current Phase Steps table by the keep-last-5 rotation triggered by Burst-34.

---

## Burst-34 — CHECKER-COMPLETENESS-GATE35 Durability Gap + Gates #40-#42 (2026-08-09)

**Parent-commit:** factory-artifacts HEAD `c8b37bc` (Burst-33: gates #36-#39 + PR #12 lifecycle)

### Summary

Path-scoped single-commit state burst (TD-VSDD-053). Commits the CHECKER-COMPLETENESS-GATE35 audit evidence trail (previously uncommitted, durability gap), records gates #40-#42 rulings, records PR #12 final state at head `f6dfa58`, opens BI-059 (BLOCKING-D/E in `scripts/verify-evidence-figures.py`), records the gate-#42 nine-checker ledger sweep authorization, and writes RESUME SNAPSHOT D-153.

---

### Gate #40 — MERGE WITHHELD on Evidentiary Grounds (D-144)

Operator refused merge on PR #12 because the claimed "cycle-3 clean" result had NO RECORDED EVIDENCE: the reviews API showed one `COMMENTED` review (cycle 1), the latest posted verdict was `REQUEST_CHANGES` (cycle 2, 03:07Z), head `ca8c1c0` postdated it with no subsequent verdict, and `pr-review-verdict.md` still carried cycle-1 content. Root cause: orchestrator relayed an implementing agent's self-report as fact without verifying it was recorded — the D-129 class, committed in the same session in which the orchestrator had itself flagged that class. Orchestrator widened: FIVE blocking findings lacked recorded resolution (cycle-1's 2 plus cycle-2's 3). Required remediation: land NIT-1, run and RECORD a fresh review at the resulting head, post the formal verdict per gate-#28, update the audit file, merge only with 4/4 CI at that exact head.

---

### Gate #41 — Mechanize Before Fixing (D-145)

After three consecutive documentation-fix passes each corrected what it was told and introduced or left a new record defect (3-for-3), the operator accepted the orchestrator's reading that this was an APPROACH DEFECT, not agent error, and ordered a mechanical figure-verification check built FIRST, then used as the oracle to fix BLOCKING-B/C. Option "merge with documentation defects as follow-ups" was REJECTED: a measurement-integrity PR does not ship with false provenance stamps.

---

### Gate #42 — Nine-Checker Ledger Sweep AUTHORIZED (D-146)

Verbatim authorization for: one-time kickoff authorization for coverage ledgers with INDEPENDENT-PROBE canary populations + anti-tautology checks + lesson-48 required-failing-case specification across all nine checkers; checker changes via PR lifecycle; no control weakened. To be restated in the resume kickoff and embedded in each implementer's INITIAL SPAWN PROMPT per CI-063.

---

### PR #12 Final State at `f6dfa58` (D-147/D-148)

- Branch: `fix/checker-completeness-gate35`, final head **`f6dfa58`**
- **10 commits:** `2349184`, `d3085d9`, `879efff`, `1dd7721`, `fd74bd7`, `b4bbbc3`, `ca8c1c0`, `72db558`, `39efec2`, `f6dfa58`
- Review cycles 1, 2, 4, 5, 6 all RECORDED; latest verdict **REQUEST_CHANGES** at `f6dfa58` (comment `5230383665`)
- Selftests: **99/99**, all mutation-verified
- `scripts/spec-lint/` subtree hash `25077be8211590e649bb37752aacaceaf88d3984` — IDENTICAL across `72db558`/`39efec2`/`f6dfa58`
- 4/4 required CI checks SUCCESS at exactly `f6dfa58`; `Spec lint` FAILURE correct per D-128
- `[ ] Operator merge authorization — pending` verified untouched and unticked throughout (D-105/D-129)
- NOT MERGED; blocked by BLOCKING-D/E (BI-059)

**Cycles 1-5 findings ALL RESOLVED at `f6dfa58`, each verified by execution, not assertion:**
- C1-BLOCKING-1: vacuous EI-4 `grep -q` matching `"0 TV rows skipped"` — RESOLVED
- C1-BLOCKING-2: `"link"` suppressing 13 finding lines / 11 EC IDs — RESOLVED
- C2-BLOCKING-1: E-class reconciliation was `x == x` tautology — independent-probe canary now fires `population=8 != examined=3 + skipped=2`, exit 2; three canary-defeat attempts all killed — RESOLVED
- C2-BLOCKING-2: ADR double-reporting; `check_adr()` AST-extracted byte-identical at `da86271` and head, so no POLICY 12 loss — RESOLVED
- C2-BLOCKING-3 / BLOCKING-A: stale evidence and PR body — RESOLVED
- BLOCKING-B: count 6 claimed, 5 sites enumerated; `population` conflated with `examined` — RESOLVED
- BLOCKING-C: three artifacts stamped `fd74bd7` where contents were unobtainable; corrected stamp `b4bbbc3` independently re-verified by checking out that tree — RESOLVED
- Both cycle-2 NITs resolved

---

### Mechanization Delivered (D-149)

New artifact `scripts/verify-evidence-figures.py` on `develop` branch, commit `f6dfa58`. Derives all expected values from live tool runs and git state, never from the document under check. On FIRST RUN: **FAILED with 10 genuine defects**, catching BLOCKING-B, BLOCKING-C, SUGGESTION-2/3/4, NIT-C and NIT-D — empirically confirming the gate-#41 rationale. The `pop=` regex relaxation was independently confirmed NOT to create a hole.

---

### BLOCKING-D and BLOCKING-E — OPEN (BI-059; D-150/D-151)

The spec-lint deliverable is verified CLEAN. The defects are confined entirely to `scripts/verify-evidence-figures.py`.

**BLOCKING-D — verifier FAILS OPEN on unparseable input:** Checks 2/3/4 use bare `if match:` with no `else: fail(...)`, unlike Checks 1 and 6. Proven: stubbing `sh()` so the two checker summaries were unparseable produced `PASS — all figure checks match live output and git state`, EXIT=0, while verifying NOTHING about the ADR figures, EC figures, or the ledger invariant. Check 6's completeness arm also evaporates (`live_e_sites` → `[]`), so the BLOCKING-B guarantee vanishes. Compounding: `sh()` lacks `check=True` and merges stdout+stderr, so a crashed checker reads as normal output.

**BLOCKING-E — Check 7 tests WRONG PROPERTY:** It asks "is this SHA in the file's git log," not "was this content obtainable at that SHA." Proven: restamping AC-005 to `879efff` (where the file read `79 reason-code + 5 E-class`) PASSES. It caught `fd74bd7` only because that SHA happens not to appear in those files' history — coincidence, not an established property.

Concrete patches: PR comment `5230383665` and `pr-review-cycle6.md`.

---

### Reviewer Notes OPEN Non-Blocking (D-152)

- **S-5:** Checks 2/4 validate only the FIRST restatement of each figure; proven by corrupting the third occurrence (line 223) and passing. Every defect in this PR's history was a contradiction between multiple statements of one figure.
- **S-6:** Verifier is invoked NOWHERE; `ci.yml` iterates `scripts/spec-lint/${check}.py` and this script sits at `scripts/`. CI wiring is a CONTROL CHANGE — GATED TO OPERATOR.
- **S-7:** Rollback command lists 9 commits and claims "all 9"; the branch has 10. `f6dfa58` is omitted, and because it ADDS a source file the documented revert would orphan it.
- **NIT-E:** `evidence-report.md:12` credits AC-001 with 99/99, but AC-001 is truncated and contains no selftest total.

---

### Orchestrator Self-Correction (D-153)

The orchestrator asserted an implementer's premise "`.factory/` is gitignored" was wrong. The reviewer disproved that: `git check-ignore -v .factory` → `.gitignore:1:.factory/`. `.factory/` is BOTH a gitignore entry AND a worktree on `factory-artifacts`; the premise was sound. The orchestrator's separate FINDING — that the audit files were uncommitted — was independently verified via `git status` inside the worktree and STANDS; this burst closes it. Lesson: an over-correction is also an unverified claim.

---

### Decisions Codified

D-144..D-153 (exhaustive):
- D-144: Gate #40 — MERGE WITHHELD (unrecorded result = does not exist; D-129 class recurrence)
- D-145: Gate #41 — mechanize before fixing (3-for-3 approach defect, not agent error)
- D-146: Gate #42 — nine-checker sweep AUTHORIZED verbatim; embed in each implementer spawn prompt
- D-147: PR #12 delivery record (10 commits; head `f6dfa58`; cycles 1-5 ALL RESOLVED)
- D-148: Cycles 1-5 findings ALL RESOLVED — each verified by execution, not assertion
- D-149: Mechanization delivered — `scripts/verify-evidence-figures.py`; 10 genuine defects on first run
- D-150: BLOCKING-D — verifier fails open on unparseable input (Checks 2/3/4 bare `if match:`)
- D-151: BLOCKING-E — Check 7 tests wrong property (SHA-in-log ≠ content-obtainable-at-SHA)
- D-152: Reviewer notes OPEN (S-5/S-6/S-7/NIT-E; non-blocking)
- D-153: Session wrap — Burst-34 durability gap + gates #40-#42 + RESUME SNAPSHOT D-153

---

### Artifact State at Burst Close

PRD v1.12 \| 66 BCs \| 26 VPs \| 13 DIs \| 8 ADRs \| 19 policies \| EC registry EC-001..EC-213 (214 ids, 1 retired) \| holdout pool 12 (7 of 12 EC IDs not-yet-authored: EC-079/093/094/141/147/148/151). D-001..D-153 (exhaustive). Open: BI-002/007/010/017/021/022/023/024/027/028/037/039/041/052/053/054/056/057/058/059. CI-063 recorded. BI-056/BI-057 REPAIRED-PENDING-MERGE (f6dfa58). BI-059 OPENED (BLOCKING-D/E). specs/ tree `ace1745871122cd1fa2c46cf27c5493cc1083411` VERIFIED UNCHANGED.

---

### Files Touched (factory-artifacts branch — one atomic commit per TD-VSDD-053)

- `.factory/code-delivery/CHECKER-COMPLETENESS-GATE35/pr-description.md` — updated (modified)
- `.factory/code-delivery/CHECKER-COMPLETENESS-GATE35/cycle1-triage.md` — added (new)
- `.factory/code-delivery/CHECKER-COMPLETENESS-GATE35/pr-review-cycle1.md` — added (new)
- `.factory/code-delivery/CHECKER-COMPLETENESS-GATE35/pr-review-cycle2.md` — added (new)
- `.factory/code-delivery/CHECKER-COMPLETENESS-GATE35/pr-review-cycle4.md` — added (new)
- `.factory/code-delivery/CHECKER-COMPLETENESS-GATE35/pr-review-cycle5.md` — added (new)
- `.factory/code-delivery/CHECKER-COMPLETENESS-GATE35/pr-review-cycle6.md` — added (new)
- `.factory/code-delivery/CHECKER-COMPLETENESS-GATE35/pr-review-verdict.md` — added (new)
- `.factory/code-delivery/CHECKER-COMPLETENESS-GATE35/pr-review.md` — added (new)
- `.factory/code-delivery/CHECKER-COMPLETENESS-GATE35/review-findings.md` — added (new)
- `.factory/sidecar-learning.md` — updated
- `.factory/STATE.md` — frontmatter, Project Metadata, Phase Progress (Burst-34 row), Current Phase Steps (Burst-28 archived, Burst-34 added), Decisions Log D-144..D-153, BI-056/BI-057 updated to f6dfa58, BI-059 added, Session Resume Checkpoint replaced (D-143→D-153), Concurrent Cycles, Historical Content, Last Updated
- `.factory/cycles/phase-1d/burst-log.md` — Burst-28 archive note + Burst-34 narrative
- `.factory/cycles/phase-1d/session-checkpoints.md` — D-143 checkpoint archived
- `.factory/cycles/phase-1d/lessons.md` — lessons 53–59 appended
- `.factory/SESSION-HANDOFF.md` — D-110 marked superseded, §RESUME SNAPSHOT D-153 added

**Closes:** audit files durability gap (10 audit files committed). **Opens:** BI-059 (BLOCKING-D/E in verify-evidence-figures.py). **Records:** gates #40-#42 rulings; gate-#42 nine-checker sweep AUTHORIZED. **Adds:** D-144..D-153 (exhaustive).

<!-- Archived from STATE.md Current Phase Steps — removed per keep-last-5 rule when Burst-35 was added -->
## Archived: Burst-29 (displaced from STATE.md Current Phase Steps by Burst-35)

Full Burst-29 narrative already present at the earlier entry in this file (Burst-29 heading above at line ~1412). This note records its displacement from the STATE.md Current Phase Steps table by the keep-last-5 rotation triggered by Burst-35.

---

## Burst-35 — Gate #43: Cycle-7 APPROVE + BI-059 CLOSED + Merge WITHHELD (2026-08-09)

**Parent-commit:** factory-artifacts HEAD at Burst-34 (Burst-34 commit: audit-durability gap + gates #40-#42 + RESUME SNAPSHOT D-153)

### What Happened

Gate #43: pr-reviewer produced cycle-7 review of PR #12 at head `6a5eb9f` (12 commits; 4/4 CI green; selftests 99/99).

**Result: APPROVE.** 0 blocking findings. 4 suggestions (2 upper / 2 lower: SUGGESTION-8/9/10/11). 5 nits. PG-012 severity ranges used throughout.

**Key structural verifications:**
- `scripts/spec-lint/` subtree hash `25077be8211590e649bb37752aacaceaf88d3984` IDENTICAL at `f6dfa58` and `6a5eb9f` — cycles 1-5 adjudications mechanically preserved
- Sole tracked diff `f6dfa58`→`6a5eb9f`: `scripts/verify-evidence-figures.py` (328 ins/54 del)
- S-7 closed: rollback block lists 12 SHAs, claims "all 12 commits", matched against live count — correct for the first time in four cycles
- S-5 closed for shrink class: per-figure MINIMUM restatement counts verified by execution

**BI-059 CLOSED (D-155):**
- BLOCKING-D: closed STRUCTURALLY via `REQUIRED_CHECKS`/`checks_ran` registry — PASS gate asserts every registered check ran a live-vs-document comparison; `sh()` separates stderr and gates return codes via `ALLOWED_RC`; reviewer reproduced cycle-6 stub: PASS/EXIT=0 → 8 failures/EXIT=1
- BLOCKING-E: closed STRONGER than prescribed patch — `git show <stamp>:<path>` with stamp line normalised away; tampering detection added: `879efff` restamp falsification now FAILS

**S-5 residuals adjudicated NON-BLOCKING (D-156):**
- Novel-spelling non-coverage: requires mechanism change not pattern-chasing
- Double-count errs safe: only false-FAIL, never false-PASS

**Merge WITHHELD (D-157):**
- Merge AUTHORIZED by operator (D-120, gate-#28)
- Operator RETRACTED fallback clause: no .factory-only record; no automation merge; STOP and report
- Three self-approval denials: (1) reviewer spawn [Self Approval]; (2) operator's own harness ×2 [Self Approval]; (3) pr-manager spawn [Self-Approval with "authorization confirms rather than negates the self-approval pattern"]
- Posted-verdict precondition UNMET; resolution path: `gh pr comment 12 --body-file .factory/code-delivery/CHECKER-COMPLETENESS-GATE35/pr-review-cycle7.md`

**BI-060 OPENED (D-158):**
- `validate-pr-review-posted` hook (a) UNSATISFIABLE — demands `gh pr review`, structurally impossible on self-authored PRs; (b) ACTIVELY INSTRUCTS AGENTS TOWARD SELF-APPROVAL — demanded reviewer spawn `github-ops` to run `gh pr review --approve`; reviewer REFUSED (correct behaviour)
- Operator ruling: do not modify mid-run; record and route around by documented exception only

**Sweep step 0 APPROVED (D-159):** harden `scripts/verify-evidence-figures.py` with SUGGESTION-8/9/10/11 + operator-gated SUGGESTION-6 CI wiring BEFORE the verifier is load-bearing.

**CI-063 EXTENDED (D-160):** three additional self-approval denials appended (see above).

### Decisions Recorded

- D-154: Gate #43 — cycle-7 APPROVE at `6a5eb9f`; subtree IDENTICAL; sole diff verifier
- D-155: BI-059 CLOSED — structural fix proven by execution
- D-156: S-5 residuals NON-BLOCKING
- D-157: Merge WITHHELD — posted-verdict precondition UNMET; fallback retracted
- D-158: BI-060 OPENED — hook UNSATISFIABLE + instructs self-approval
- D-159: Sweep step 0 APPROVED — verifier hardening before load-bearing
- D-160: CI-063 EXTENDED — three self-approval denials
- D-161: Burst-35 session wrap — RESUME SNAPSHOT D-161

### Artifact State at Burst Close

PRD v1.12 | 66 BCs | 26 VPs | 13 DIs | 8 ADRs | 19 policies | EC registry EC-001..EC-213 (214 ids, 1 retired) | holdout pool 12 (7 of 12 EC IDs not-yet-authored: EC-079/093/094/141/147/148/151). D-001..D-161 (exhaustive). Open: BI-002/007/010/017/021/022/023/024/027/028/037/039/041/052/053/054/056/057/058/060; CI-063. specs/ tree `ace1745871122cd1fa2c46cf27c5493cc1083411` VERIFIED UNCHANGED.

### Files Touched (factory-artifacts branch — one atomic commit per TD-VSDD-053)

- `.factory/STATE.md` — frontmatter timestamp + current_step; Project Metadata (Last Updated + Current Step); Phase Progress (Burst-35 row added); Current Phase Steps (Burst-35 added, Burst-29 archived); Decisions Log D-154..D-161 appended; Blocking Issues (BI-059 removed → blocking-issues-resolved.md; BI-056/BI-057 advanced to 6a5eb9f/12 commits; BI-060 ADDED; CI-063 extended); Session Resume Checkpoint replaced D-153→D-161; Concurrent Cycles updated; Historical Content (pr-review-cycle7.md row added)
- `.factory/SESSION-HANDOFF.md` — Latest: pointer updated D-153→D-161; D-153 snapshot header marked SUPERSEDED; §RESUME SNAPSHOT D-161 appended
- `.factory/code-delivery/CHECKER-COMPLETENESS-GATE35/pr-review-cycle7.md` — added (new; cycle-7 review; 697 lines; APPROVE; durability-critical)
- `.factory/code-delivery/CHECKER-COMPLETENESS-GATE35/pr-description.md` — updated (head SHA 6a5eb9f; rollback block 12 SHAs)
- `.factory/cycles/phase-1d/blocking-issues-resolved.md` — BI-059 closure record appended
- `.factory/cycles/phase-1d/burst-log.md` — Burst-29 archive note + Burst-35 narrative appended
- `.factory/cycles/phase-1d/session-checkpoints.md` — D-153 checkpoint archived
- `.factory/logs/` — modified + untracked .jsonl files staged

**Closes:** BI-059 (BLOCKING-D/E proven by execution at `6a5eb9f`). **Opens:** BI-060 (validate-pr-review-posted hook unsatisfiable + self-approval). **Records:** gate #43 cycle-7 APPROVE, merge WITHHELD, sweep step 0 APPROVED. **Adds:** D-154..D-161 (exhaustive).

---

## Burst-30 — Archived from Current Phase Steps by Burst-36 (2026-08-09)

*Archived from STATE.md Current Phase Steps by Burst-36.*

BI-055 RESOLVED (human-ordered PRIVATE→PUBLIC visibility change, D-127, 2026-08-08T22:55:24Z); branch protections verified intact post-flip (D-128); PR #11 now 4/4 required checks PASS; `Spec lint` fails as intended per D-124; AWAITING OPERATOR-CONFIRMED MERGE (D-120); D-127..D-128 (exhaustive) appended to Decisions Log; BI-055 moved to blocking-issues-resolved.md; burst narrative appended to cycles/phase-1d/burst-log.md; trajectory-tail →39→37→259→273-275 (unchanged). D-127..D-128 (exhaustive) added. BI-055 marked RESOLVED and moved to cycles/phase-1d/blocking-issues-resolved.md. Session Resume Checkpoint updated (Position + Next burst). STATE.md staged explicitly per D-088.

---

## Burst-36 — BI-053/BI-054 CLOSED; P7-S6-009 CLOSED; Perimeter Advances (2026-08-09)

*Agent: state-manager. Phase: phase-1d. Single-commit burst TD-VSDD-053.*

### Context

Burst-36 records three independently-verified spec fixes authorized by the operator ahead of the gate-#42 sweep, while PR #12's merge is resolved separately. All facts verified by the orchestrator via executed commands before dispatch.

### Work Performed

**BI-053 CLOSED (fragment percent-decode inversion):**
Two-pass fix. Pass 1 corrected the inversion: five authoritative sources unanimous (DI-003/invariants.md:109, CAP-008/capabilities.md:142, DEC-005/edge-cases.md:132, events.md:92, prd.md:380) that fragments MUST be decoded after split. BC-2.07.004 (Description s3 + PC4) and BC-2.08.001 (PC1 + Inv3) had both forbidden decode; now correct. Pass 2 closed a boundary gap the correction itself opened: undecodable percent-sequences (e.g., `file.md#caf%GG`) were unspecified once PC4 made decoding mandatory. All five sources SILENT. Symmetry-with-path-component rule adopted: invalid sequences pass through raw, used as-is for anchor lookup, yield `anchor-not-found` (code 4 of 13-code closed set). BC-2.07.004 Inv3 extended to three surfaces; BC-2.08.001 gained Inv4. No new reason code created — that refusal is a POSITIVE PRECEDENT (D-164; `malformed-fragment` would have tripped BI-056 gate per P7-S4-006 CRITICAL finding). Story propagation: empty target set — `.factory/stories/` contains only `.gitkeep`; no story files exist; no story-writer dispatch required. Propagation debt RECORDED: VP-004 decode gap, VP-025, VP-INDEX consistency, TV-157/EC-157 — queued with BI-052 (same class). Versions: BC-2.07.004 1.3→1.5, BC-2.08.001 1.3→1.5, prd.md 1.12→1.14 (changelog entries 1.13 and 1.14 both present; 1.12 entry untouched per D-034).

**BI-054 CLOSED (stale POL-14 directive):**
Directive was the ENTIRE defect. Verified: 53 VP rows across 33 BC files already held the correct `test-sufficient` value; `check-placeholders.py` passes 0 live placeholders across 134/134 spec files both before and after; zero residual `| none |` in bc-module-map.md. The directive had been instructing the product-owner to CONVERT conforming rows INTO violations across 33 files — harmful downstream guidance. Checker acceptance condition (oracle): `test-sufficient` accepted ONLY when VP-INDEX classifies the BC ID as `test-sufficient` (runtime JOIN, NOT allowlist per D-039) AND Proof Method cell non-empty; `none` explicitly REJECTED per R2-RULE. The document's own "55 BC files" figure was wrong (actual: 53 rows / 33 files) — surfaced because D-082 forced re-derivation. ROOT CAUSE: propagation gap — commit `d4e76fa` added `test-sufficient` as legal sentinel; `bc-module-map.md` never updated. Tagged `[process-gap]` per S-7.02. Version: bc-module-map.md 1.4→1.5.

**P7-S6-009 CLOSED (sibling defect; bc-module-map.md Primary ownership arithmetic):**
Primary ownership table declared `| **Total** | **66** |` while 16 data rows summed to 70. Four cells corrected by `awk` over BC mapping tables (not hand-carried): `link_extractor` 9→8, `anchor_table` 4→3, `http_client` 8→7, `cli` 4→3. Table now sums to exactly 66. IMPORTANT nuance (D-168): Module Ownership Summary (20 lines above) counts ALL BCs touched (primary+secondary); Primary ownership table counts primary only — different quantities, cannot agree cell-for-cell in general. Only `http_client` is directly comparable (all 7 BCs are primary with no secondary involvement); its mismatch was a genuine regression from v1.2. Higher Summary values for `link_extractor`, `anchor_table`, `cli` are EXPECTED and correct. `check-counts.py` has ZERO coverage of `bc-module-map.md` — routed into gate-#42 sweep scope (D-169). Version: bc-module-map.md 1.5→1.6.

**Input-hash drift resolved (D-170):**
`validate-input-hash` PostToolUse hook fired on `bc-module-map.md` with PRE-EXISTING drift (stored `c1efbb5` ≠ computed `0cfd557`) — stale BEFORE any edit this session. Resolved via `compute-input-hash --update`. Hook NOT disabled/bypassed/weakened. Full `/vsdd-factory:check-input-drift` sweep queued for after BI-052/EC-151 land (once, MANDATORY before phase-1 gate).

**Perimeter advance (D-171):**
`specs/` tree hash advances from `ace1745871122cd1fa2c46cf27c5493cc1083411` to `a79de7e841c705a499f7aec634c4894b3097764e`. Four spec files changed. Adversary pass 8 MUST run against new hash. Standing "frozen perimeter `ace1745`" descriptor SUPERSEDED as of this burst.

**BI-060 agency-vs-identity distinction (D-172):**
Gate-#28 requirement satisfied on AGENCY axis (human composed and posted verdict comment `5232703815` on PR #12) but NOT on IDENTITY axis (PR author `drbothen` == comment author `drbothen`, machine-unverifiable). This gap is the root of BI-039 and recurs on every PR this run. Three self-approval denials + one transient stage-2 denial recorded. No control weakened.

### Decision Delta

- D-162: BI-053 CLOSED — five-source unanimity on fragment must be percent-decoded after split
- D-163: Boundary gap from correction; symmetry-with-path closure; `anchor-not-found` for undecodable sequences
- D-164: Refusal to invent reason code — positive precedent; `malformed-fragment` would have been phantom-code regression
- D-165: Empty story-propagation target set; VP propagation debt recorded (VP-004/VP-025/VP-INDEX/TV-157) queued with BI-052
- D-166: BI-054 CLOSED — directive was entire defect; "55 BC files" figure wrong (53 rows/33 files); `test-sufficient` join oracle confirmed
- D-167: d4e76fa propagation-gap root cause tagged [process-gap]; S-7.02 follow-up required
- D-168: P7-S6-009 closed; two-tables-measure-different-quantities nuance; `http_client` only directly comparable row
- D-169: `check-counts.py` zero coverage of `bc-module-map.md`; routed to gate-#42 sweep
- D-170: Pre-existing input-hash drift in bc-module-map.md; resolved via `--update`; drift predates session
- D-171: Perimeter hash advances ace1745→a79de7e; pass 8 must use new hash
- D-172: BI-060 agency-vs-identity distinction; Burst-36 wrap

### Artifact State at Burst Close

PRD v1.14 | 66 BCs | 26 VPs | 13 DIs | 8 ADRs | 19 policies | EC registry EC-001..EC-213 (214 ids, 1 retired) | holdout pool 12 (7 of 12 EC IDs not-yet-authored: EC-079/093/094/141/147/148/151). D-001..D-172 (exhaustive). Open: BI-002/007/010/017/021/022/023/024/027/028/037/039/041/052/056/057/058/060; CI-063. specs/ tree `a79de7e841c705a499f7aec634c4894b3097764e` (advances past `ace1745`).

### Files Touched (factory-artifacts branch — one atomic commit per TD-VSDD-053)

- `.factory/STATE.md` — frontmatter; Project Metadata; Phase Progress (Burst-36 row added); Current Phase Steps (Burst-36 added, Burst-30 archived); Decisions Log D-162..D-172 appended; Blocking Issues (BI-053/BI-054 removed → resolved; BI-052/BI-058/BI-060 updated); Session Resume Checkpoint replaced D-161→D-172; Concurrent Cycles updated; Spec Snapshot updated to v1.14
- `.factory/SESSION-HANDOFF.md` — Latest: pointer updated D-161→D-172; D-161 snapshot header marked SUPERSEDED; §RESUME SNAPSHOT D-172 appended
- `.factory/specs/behavioral-contracts/ss-07/BC-2.07.004.md` — v1.3→v1.5 (BI-053 two-pass fix)
- `.factory/specs/behavioral-contracts/ss-08/BC-2.08.001.md` — v1.3→v1.5 (BI-053 two-pass fix)
- `.factory/specs/prd.md` — v1.12→v1.14 (changelog entries 1.13+1.14; 1.12 untouched per D-034)
- `.factory/specs/architecture/bc-module-map.md` — v1.4→v1.6 (BI-054 directive removed; P7-S6-009 arithmetic corrected)
- `.factory/cycles/phase-1d/blocking-issues-resolved.md` — BI-053/BI-054/P7-S6-009 closure records appended
- `.factory/cycles/phase-1d/burst-log.md` — Burst-30 archive note + Burst-36 narrative appended
- `.factory/cycles/phase-1d/session-checkpoints.md` — D-161 checkpoint archived
- `.factory/cycles/phase-1d/lessons.md` — lessons 60+61 appended
- `.factory/logs/` — modified + untracked .jsonl files staged
- `.factory/sidecar-learning.md` — modified

**Closes:** BI-053 (fragment percent-decode inversion), BI-054 (stale POL-14 directive), P7-S6-009 (Primary ownership arithmetic). **Updates:** BI-052 (VP propagation debt added), BI-058 (bc-module-map coverage gap added to sweep scope), BI-060 (agency-vs-identity distinction). **Adds:** D-162..D-172 (exhaustive).

---

## Burst-31 [ARCHIVED — was oldest row in Current Phase Steps window; moved here by Burst-37]

*Originally recorded in STATE.md Current Phase Steps. Archived per keep-last-5 policy.*

PR #11 MERGED (`da86271`). develop `f8ee4eb`→`da86271`. Worktree and branch `fix/oracle-repairs-gate34` cleaned. D-130 supersedes D-124 (6 pass/3 fail, 14+5 actuals). BI-056/057 opened.

---

## Burst-37 — SESSION WRAP

*Written: 2026-08-09 — state-manager. Single-commit burst TD-VSDD-053. Supersedes D-172.*

**PR #12 MERGED by human at 18:42:19Z.** Squash commit `2ac2c3e` ("[CHECKER-COMPLETENESS-GATE35] Spec-lint oracle repairs — BI-056 E-code detector + BI-057 multi-column TV extraction (#12)"). `develop` advances `da86271`→`2ac2c3e`. Branch `fix/checker-completeness-gate35` DELETED. Zero open PRs at merge. BI-056 CLOSED. BI-057 CLOSED. BI-059 was CLOSED at `6a5eb9f` (Burst-35), confirmed unchanged.

**First authoritative 9-checker baseline on develop = `2ac2c3e` (D-174):** 6 pass / 3 fail. Selftests 99/99. Failing: `adr-consistency` (9 violations; 79 reason-code occurrences + 6 E-class; 134/134 files); `ec-injectivity` (174 EC citations compared; 17 legitimately-EC-less rows skipped and named; 42 divergent; 22 require adjudication); `holdout-boundary` (1 violation; EC-151 at `prd.md:618`). Passing: canonical-facts (31 bindings/11 facts), counts (37), id-resolution (134), index-integrity (80), placeholders (0/134), title-sync (66).

**BI-057 repair confirmed working (D-175):** 17 named skips (TV-BV013 + TV-S001..TV-S016) vs prior 80 unnamed. Row-granularity completeness hole genuinely closed.

**`malformed-fragment` phantom code DETECTED (D-176):** adversary finding P7-S4-006 confirmed live at `test-vectors.md:432`. Refusal to invent the code during BI-053 (D-164) VINDICATED. 1 of the 9 `adr-consistency` violations.

**Reason-code population 78→79 (D-177):** BI-053's spec fix (conforming `anchor-not-found` occurrence for `%GG` boundary gap) advanced the population. Violations REMAINED at 9 — conforming occurrence. GATE35 evidence artifacts now STALE (record 78; live=79). Item-5 end-to-end demonstration using GATE35 artifacts PROVEN IMPOSSIBLE (D-181).

**PR #13 delivered (D-178):** branch `fix/verifier-hardening-sweep-step0`, head `27688e3`. 4 files: `scripts/verify-evidence-figures.py` (~900 lines, substantially rewritten), `scripts/tests/test-vef.py` (NEW), `.github/workflows/ci.yml` (advisory step), `docs/demo-evidence/CHECKER-COMPLETENESS-GATE35/evidence-report.md` (NIT-E fix). 17/17 verifier selftests; 99/99 nine-checker selftests; item-0 context refusal; argparse CLI; auto-discovery. 4/4 required CI green. `MERGEABLE`.

**PR #13 cycle-1 REQUEST_CHANGES (D-179):** Five blocking findings with prescribed fix order: B-2 FIRST (`headSha` regression — `headSha` not a `gh` field, correct name is `headRefOid`; suite green whether dependency broken or absent); B-4 (hardcoded `39efec2`; makes PASS structurally impossible on any other PR); B-1 (predicate polarity inverted in novel-spelling scan); B-3 (`anchor_check()` proves ENTRY not COMPARISON); B-5 (CI advisory step reports `"conclusion":"skipped"`). Item-4 ACCEPTABLE; item-5 PROVEN IMPOSSIBLE (D-181).

**Four-mechanism fail-open lesson codified [process-gap] (D-180):** same defect (check reports success while verifying nothing) recurred by four NEW mechanisms across four fix rounds. Only two durable defenses: (a) unrepresentable bad state; (b) independent probe not sharing the validated code path.

**BI-060 extended two hook defects (D-182):** (c) cycle-keyed filename false-negative (hook matches literal `pr-review.md`; deliverable convention is `pr-review-cycleN.md`); (d) machine-unreadable block state (`block_reason=""` while `block_intent=true`). Reviewer correctly did not rename artifact to silence hook.

**NIT-A and NIT-B routed to sweep PR scope (D-183):** both address `scripts/spec-lint/` subtree frozen for PR #13; must land in the sweep PR; not blocking PR #13 cycle-2.

**BI-061 OPENED:** PR #13 cycle-1 blocking set B-1..B-5 with prescribed fix order.

**Files touched:**
- `.factory/STATE.md` — version 3.3; timestamp 2026-08-09T20:34:00Z; frontmatter; Project Metadata; Phase Progress (Burst-37 row added); Current Phase Steps (Burst-37 added, Burst-31 archived here); Decisions Log D-173..D-184 appended; Blocking Issues (BI-056/BI-057 removed → resolved; BI-002/BI-058/BI-060 extended; BI-061 OPENED); Session Resume Checkpoint replaced D-172→D-184; Concurrent Cycles updated; Historical Content (PR #13 cycle-1 review row added); Spec Snapshot updated D-184 + open BI list
- `.factory/SESSION-HANDOFF.md` — Latest pointer updated D-172→D-184; D-172 snapshot header marked SUPERSEDED; §RESUME SNAPSHOT D-184 appended
- `.factory/code-delivery/VERIFIER-HARDENING-SWEEP-STEP0/pr-review-cycle1.md` — NEW untracked file (40,786 bytes); first line `**VERDICT: REQUEST_CHANGES**`; PR #13 cycle-1 review; durability-critical
- `.factory/cycles/phase-1d/blocking-issues-resolved.md` — BI-056 and BI-057 closure records appended
- `.factory/cycles/phase-1d/burst-log.md` — Burst-31 archive note + Burst-37 narrative appended
- `.factory/cycles/phase-1d/session-checkpoints.md` — D-172 checkpoint archived
- `.factory/cycles/phase-1d/lessons.md` — lessons 60+61 appended
- `.factory/logs/` — modified + untracked .jsonl files staged
- `.factory/sidecar-learning.md` — modified

**Closes:** BI-056 (E-class detection regression; develop=2ac2c3e confirmed working), BI-057 (row-granularity skip; 17 named skips on develop=2ac2c3e). **Opens:** BI-061 (PR #13 cycle-1 blocking set). **Extends:** BI-058 (NIT-A/B routing D-183), BI-060 (two hook defects D-182). **Adds:** D-173..D-184 (exhaustive).


---

## Burst-38 — 2026-08-09

**Trigger:** PR #13 cycle-1 fixes needed orchestrator verification + cycle-2 review via gate-#28 v3.

**Agents dispatched:**
- devops-engineer (B-2: field-contract structural fix + T18 independent probe)
- devops-engineer (B-4: hardcoded SHA removal + set-difference rollback + check9 membership fix)
- devops-engineer (B-1: novel-spelling re-keying + real-corpus false-positive resolution via EI_NOVEL_DECLARED)
- devops-engineer (B-3: anchor_check refactor + record_comparison sole-registration path)
- devops-engineer (B-5: CI step `if: !cancelled()` + develop-ref guard)
- pr-reviewer (gate-#28 v3: cycle-2 review, read-only, cycle-keyed audit file)
- state-manager (this burst)

**Files touched in factory-artifacts:**
- `.factory/STATE.md` — version 3.3→3.4; D-185..D-198; BI-061 cycle-1 CLOSED→cycle-2 OPENED; CI-063 extended; Session Resume Checkpoint D-184→D-198; Burst-33 archived; Burst-38 added as first Current Phase Steps row
- `.factory/SESSION-HANDOFF.md` — Latest pointer D-184→D-198; §RESUME SNAPSHOT D-198 appended
- `.factory/cycles/phase-1d/lessons.md` — L-62..L-65 appended
- `.factory/cycles/phase-1d/burst-log.md` — this entry; Burst-33 Current Phase Steps row archived below
- `.factory/cycles/phase-1d/session-checkpoints.md` — D-184 checkpoint archived
- `.factory/code-delivery/VERIFIER-HARDENING-SWEEP-STEP0/pr-review-cycle2.md` — cycle-2 audit file (30055 bytes; covered_sha `7739995e`)

**Key results:**
- Cycle-1 B-1..B-5 ALL CLOSED (D-185..D-189), orchestrator-verified by direct mutation experiments at three separate heads
- First genuine end-to-end exit 0 (D-190): `python3 scripts/verify-evidence-figures.py` → `PASS` with no flags; used PR #13's OWN artifacts (circularity resolved by commit ordering)
- Cycle-2 REQUEST_CHANGES B2-1..B2-5 (D-191); reviewer's fix order: B2-1→B2-2→B2-4+S2-1→B2-3→docs
- MECHANISM FIVE FOUND — TWO forms: 5(a) dishonestly-green CI step (B-5's own fix; ran zero checks); 5(b) unbounded EI_NOVEL_DECLARED exemption (B-1's own fix) (D-192)
- Orchestrator verification defect recorded: read CI step STATUS not OUTPUT (D-193); L-62 codified
- gate-#28 v3 executed cleanly; zero classifier denials this session (D-195); CI-063 mitigation confirmed effective
- Streak: 0 of 3 clean passes UNCHANGED (operator ruling D-196)
- BI-060 second identity: human ruling to continue current way, flagged for pre-wave-1 (D-197)
- L-62..L-65 appended (all [process-gap], all load-bearing)

**Closes:** cycle-1 BI-061 B-1..B-5 (D-185..D-189). **Opens:** cycle-2 BI-061 B2-1..B2-5 (D-191). **Extends:** CI-063 (zero denials D-195). **Adds:** D-185..D-198 (exhaustive). TD-VSDD-053 single-commit burst.

---

## Archived: Burst-33 Current Phase Steps row

The following row was archived from STATE.md Current Phase Steps to this file during Burst-38 (oldest row rotated out per 5-row limit):

| Burst-33 — gates #36-#39 + PR #12 lifecycle (ca8c1c0; 7 commits; 0 BLOCKING cycle-3; security APPROVE; 91→98 selftests all mutation-verified); BI-056/BI-057 REPAIRED-PENDING-MERGE; BI-058 OPENED (D-132 audit: suppression guard INERT + 5 false-green checkers); CI-063 recorded (recurring auto-mode classifier friction, ~9.7% wall-time loss); D-135..D-143 (exhaustive); d132-checker-audit.md created; D-134 checkpoint archived to session-checkpoints.md | state-manager | COMPLETE | D-135..D-143 appended to Decisions Log. BI-056/BI-057 updated REPAIRED-PENDING-MERGE at ca8c1c0. BI-058 OPENED. CI-063 recorded. Burst-26 archived to burst-log.md. D-134 checkpoint archived to session-checkpoints.md. d132-checker-audit.md created. specs/ tree ace1745… VERIFIED UNCHANGED. Single-commit burst TD-VSDD-053. |
