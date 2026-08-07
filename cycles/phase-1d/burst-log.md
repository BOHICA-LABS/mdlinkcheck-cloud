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
