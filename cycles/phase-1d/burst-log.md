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
