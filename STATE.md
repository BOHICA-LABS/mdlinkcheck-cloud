---
document_type: pipeline-state
level: ops
version: "2.1"
status: draft
producer: state-manager
timestamp: 2026-08-06T12:08:00Z
phase: phase-1d
inputs: []
input-hash: "[live-state]"
traces_to: ""
project: mdlinkcheck-cloud
mode: greenfield
current_step: "phase-1d; pre-restart checkpoint; D-028/D-029 recorded; D-421 latest; trajectory-tail →0→32→34→39; next=PR#2 pr-manager review + pass4"
current_cycle: ""
dtu_required: false
---

<!--
  STATE.md SIZE BUDGET (per D-421(c)):
  Soft target: ≤200 lines; margin from soft-target = 500 - 200 = 300; margin from actual = 500 - 180 = 320. 180 lines (wc-l).
  Hard cap: 500 lines.
  Historical content belongs in cycle files, NOT here.
  Run /vsdd-factory:compact-state if this file grows past 200 lines.
-->

# Pipeline State: mdlinkcheck-cloud

## Project Metadata

| Field | Value |
|-------|-------|
| **Product** | mdlinkcheck-cloud |
| **Repository** | /Users/jmagady/Dev/mdlinkcheck-cloud |
| **Mode** | greenfield |
| **Language** | Rust (MSRV 1.85, toolchain pinned 1.97.0) |
| **Product Type** | CLI (no UI) |
| **Target Workspace** | /Users/jmagady/Dev/mdlinkcheck-cloud |
| **Started** | 2026-08-05 |
| **Last Updated** | 2026-08-06 — pre-restart checkpoint; D-028/D-029 recorded; 0 of 3 clean passes; trajectory-tail →0→32→34→39 |
| **Current Phase** | phase-1d |
| **Current Step** | pre-restart checkpoint at 410K context; D-028/D-029 recorded; next=PR #2 pr-manager review + pass 4 |

## Phase Progress

| Phase | Status | Started | Completed | Gate | Finding Progression |
|-------|--------|---------|-----------|------|---------------------|
| pre-1: Planning | completed | 2026-08-05 | 2026-08-05 | HUMAN: market-intel-review + intake-approval | |
| 0: Codebase Ingestion | not-started | | | | |
| 1: Spec Crystallization | artifacts-complete | 2026-08-05 | 2026-08-05 | awaiting phase-1d convergence | |
| phase-1d: Adversarial Spec Review | in-progress | 2026-08-05 | — | adversary: 3 clean passes required | →0→32→34→39 |
| 2: Story Decomposition | not-started | | | | |
| 3: TDD Implementation | not-started | | | | |
| 4: Holdout Evaluation | not-started | | | | |
| 5: Adversarial Refinement | not-started | | | | |
| 6: Formal Hardening | not-started | | | | |
| 7: Convergence | not-started | | | | |
| pass-3 adversary | COMPLETE | 2026-08-06 | 2026-08-06 | — | →0→32→34→39 |
| pass-3 fix burst | COMPLETE | 2026-08-06 | 2026-08-06 | — | →0→32→34→39 |

## Current Phase Steps

<!-- Keep last 5 rows only. Archive older rows to cycles/phase-1d/burst-log.md. -->

| Step | Agent | Status | Output |
|------|-------|--------|--------|
| phase-1d adversary pass 3 | adversary | COMPLETE | adversary-pass-3.md; 39 novel (5 CRIT); consistency FAIL; record 29/39 stored as stubs — pass 4 supersedes |
| phase-1d consistency audit pass 3 | consistency-validator | COMPLETE | consistency-audit-phase-1-pass-3.md; FAIL |
| phase-1d spec-lint tooling built | devops-engineer | COMPLETE | scripts/spec-lint/ (8 validators, 4 generators, selftest); just spec-lint CI job; PR #2 open (feature/spec-lint-tooling) |
| phase-1d pass-3 remediation | architect/product-owner/spec-steward | COMPLETE | 254→25 violations; D-026/D-027; PRD v1.9; VP-025; DI-012/DI-013; ADR-007 v1.3; bc-module-map.md |
| next: adversary pass 4 + consistency pass 4 | adversary + consistency-validator | pending | first test of mechanical enforcement — target: novelty decays |

## Convergence Status

Trajectory →0→32→34→39

pass count: 0 of 3 required clean passes

REGRESSION: novelty increased across all 3 passes (32→34→39). Strategy changed to mechanical enforcement. Pass-3 remediation COMPLETE — awaiting pass 4. First test of whether enforcement bends the curve.

| Pass | Findings | Delta | Status |
|------|----------|-------|--------|
| 1 | 32 (6C/21M/5m) | — | FINDINGS_REMAIN — REMEDIATED |
| 2 | 34 (7C/19M/8m) | +2 | FINDINGS_REMAIN (REGRESSION) — REMEDIATED |
| 3 | 39 (5C/26M/8m) | +5 | FINDINGS_REMAIN (REGRESSION) — REMEDIATED (mechanical enforcement) |

## Decisions Log

| ID | Decision | Rationale | Phase | Date | Made By |
|----|----------|-----------|-------|------|---------|
| D-001 | Initialize .factory worktree via /vsdd-factory:factory-health | factory-artifacts branch and worktree were missing; pre-existing logs/ and sidecar-learning.md preserved | pre-1 | 2026-08-05 | human/orchestrator |
| ~~D-002~~ | ~~Run pipeline LOCAL-ONLY, no GitHub remote / no PRs~~ | ~~Repo has no `origin` remote; human elected local-only delivery~~ | pre-1 | 2026-08-05 | **SUPERSEDED by D-021** |
| D-003 | Phase 3 autonomy = run to convergence, stop only at designed human gates | Human decision; no per-story or per-wave pauses | pre-1 | 2026-08-05 | human |
| D-004 | Target language Rust, MSRV 1.85, toolchain pinned to 1.97.0 | BRIEF.md specifies Rust; MSRV 1.85 forced by clap 4.6 + ureq 3.3 per market-intelligence.md | pre-1 | 2026-08-05 | dx-engineer/orchestrator |
| D-005 | Copy BRIEF.md to .factory/specs/product-brief.md with canonical VSDD L1 frontmatter; keep root BRIEF.md as frozen original | artifact-detection.md flagged path discrepancy; BRIEF.md is frozen and must not be edited | pre-1 | 2026-08-05 | orchestrator |
| D-006 | Strict case-sensitive + NFC path comparison on all platforms (macOS, Linux, Windows) | Brief's determinism premise; macOS APFS is case-insensitive and NFD — native semantics would classify the same repo differently locally vs in CI | phase-1 | 2026-08-05 | human |
| D-007 | Narrow HTML `id=`/`name=` anchor carve-out; no DOM, no HTML link following | Literal "no HTML parsing" non-goal would make every `<a name>`-defined anchor a false positive | phase-1 | 2026-08-05 | human |
| D-008 | Three link verdicts: clean / broken / indeterminate; indeterminate never causes nonzero exit | Real servers return 429/403/5xx to CI runners; strict classification would produce the CI false positives the brief targets | phase-1 | 2026-08-05 | human |
| D-009 | IN scope: factory-authored README.md, acceptance corpus. OUT: inline suppression directives, GFM bare-URL autolinks | Brief references an acceptance corpus and README that did not exist; suppression and bare autolinks were scope creep | phase-1 | 2026-08-05 | human |
| D-010 | The `mdlinkcheck BRIEF.md` → exit 0 vector is VISIBLE, not a holdout; replacement holdouts designated | It is the canonical R4 proof stated in the brief itself, so it cannot meaningfully be hidden | phase-1d | 2026-08-05 | human |
| D-011 | `--quiet`, `--offline`, `--insecure`, `--hidden` DROPPED as explicit non-goals | No BC coverage and not in R1–R8; `--offline` is redundant since offline is the default | phase-1d | 2026-08-05 | human |
| D-012 | Discovery matches `.md` only, case-sensitive; `.MD`, `.markdown`, `.mdx` are non-goals | Literal reading of R1 and consistent with D-006 strictness | phase-1d | 2026-08-05 | human |
| D-013 | NFR-001 (5s p95 Apple Silicon) / NFR-002 (15s p95 Linux CI) confirmed as acceptance ceilings from frozen R8, PLUS NFR-008 ~500ms p95 Tier A regression gate | The R8 ceiling is ~25–100x looser than realistic runtime; it cannot detect regression without the tighter NFR-008 gate | phase-1d | 2026-08-05 | human |
| D-014 | Verdict vocabulary is TWO LAYERS: link verdict = clean/broken/indeterminate (closed, drives exit codes); URL liveness outcome = alive/broken/indeterminate (intermediate, --online only). `alive` is NOT a fourth verdict | error-taxonomy.md had flattened the layers and wrongly asserted "clean is NOT used for external URL verdicts", contradicting DI-005 | phase-1d | 2026-08-05 | orchestrator ruling (DD-022) |
| D-015 | Error taxonomy canonical ruling: 13-code closed set is authoritative; exit 1 for broken links per frozen R7; DNS failure and TLS error are `broken` not `indeterminate` | ADR-007 had inverted the exit codes, invented 5 phantom reason codes, and misclassified dns/tls | phase-1d | 2026-08-05 | orchestrator ruling |
| D-016 | Add optional `sub_reason` field to the JSON finding object rather than stripping sub-reason diagnostics | `private-ip` and `https-downgrade` sub-reasons exist in BC test vectors with no schema field to carry them; additive and pre-1.0 | phase-1d | 2026-08-05 | orchestrator ruling |
| D-021 *(clause "agents NEVER merge" partially superseded by D-028)* | Full PR-based delivery restored; merge gate = required CI status checks + factory AI review (pr-reviewer / code-reviewer); ~~agents NEVER merge PRs — orchestrator merges only after human approval at a designed gate~~ *(superseded: agents MAY merge after full pr-manager review lifecycle per D-028)* | devops-engineer agent attempted to self-merge PR #1 and was blocked by the security guard (origin of this decision); `required_approving_review_count` is 0 on both branches because every agent-authored PR is authored by the human's own GitHub account (`drbothen`) and GitHub forbids self-approval — review rigor enforced by CI checks + factory AI review agents; remainder of D-021 strengthened by D-028 | phase-1d | 2026-08-05 | human |
| D-022 | Branch topology: story PRs target `develop`; releases go `develop` → `main` via PR. Branch protection live on both with 8 strict required status checks, linear history, no force-push/deletion; `enforce_admins` true on `main` | Establishes the two-branch delivery model replacing the D-002 local-only workaround | phase-1d | 2026-08-05 | devops-engineer/human |
| D-023 | CI jobs use `Cargo.toml`-presence guards so they pass green before the Rust workspace exists; required status check context strings are the unprefixed job names (`Format check`, `Clippy (deny warnings)`, `Test (ubuntu-latest)`, etc.) — verified empirically from live run 31065845669, NOT the guessed `CI / `-prefixed form | Avoids branch-protection deadlock on bootstrap PR; context string form verified from live CI run | phase-1d | 2026-08-05 | devops-engineer |
| D-024 | Nonexistent/unreadable PATH argument is a runtime I/O error (recorded, scan continues, exit 2 at end) — NOT a startup config error with immediate abort. Required by DD-007 no-fail-fast | architect ruling; PO reconciled | phase-1d | 2026-08-05 | architect |
| D-025 | `verdict::exit_code(findings, io_errors, config_error) -> u8` — three inputs. Precedence: io_errors non-empty OR config_error → 2; elif any broken → 1; else 0; indeterminate never raises the exit code | P2-M19 found the config_error half of exit 2 unmodeled; three-input function closes that gap | phase-1d | 2026-08-05 | architect |
| D-026 | BC `## Edge Cases` tables now cite EC registry IDs plus a one-line label ONLY; all concrete inputs and expected verdicts live solely in `prd-supplements/test-vectors.md` as the single canonical EC registry (POL-16) | Duplicating expectations in both BCs and the registry was the structural cause of 98 EC-ID collisions, six with opposite expected verdicts. Makes the collision class unrepeatable rather than merely repaired | phase-1d | 2026-08-06 | product-owner/orchestrator |
| D-027 | Validator hardening is mandatory before trusting any validator result | `check-id-resolution` initially returned PASS while never checking EC IDs (`VALID_EC` built but unused); `check-counts` missing 3 checks; `check-placeholders` had 23 false positives + missed 55 real defects. All 8 checkers now have negative tests proving they can fail | phase-1d | 2026-08-06 | devops-engineer/orchestrator |
| D-028 | Merge policy REVISED — agents MAY merge PRs, but ONLY after the full vsdd-factory PR review process (pr-manager lifecycle: review dispatch, finding triage, fix delegation, convergence tracking). Direct unreviewed merges remain FORBIDDEN. SUPERSEDES the "agents NEVER merge" clause of D-021; remainder of D-021 stands. CI checks + factory AI review are a precondition, not the ceiling — passing the full pr-manager process is the explicit merge precondition. | Operator directive. D-021 origin: devops-engineer self-merge blocked by security guard. D-028 unlocks agent-merge post-review to remove human-blocking of routine story PRs. | phase-1d | 2026-08-06 | human/operator |
| D-029 | `spec-lint` CI job remains ADVISORY (NOT in required status checks) until adversary pass 4 demonstrates convergence; flip to REQUIRED at Phase 1 approval | Operator directive. 25 known `[filled by story-writer]` violations legitimately outstanding until Phase 2; making spec-lint blocking now would deadlock PRs for a non-defect | phase-1d | 2026-08-06 | human/operator |

## Skip Log

| Step | Skipped? | Justification |
|------|----------|---------------|
| phase-1-design-system-bootstrap | YES | CLI product, no UI surface. No design tokens or component registry applicable. |
| phase-1-design-system-approval | YES | Dependent on skipped design-system-bootstrap. |
| phase-1-multi-variant-design | YES | CLI product, no screens to generate variants for. |
| phase-1-multi-variant-approval | YES | Dependent on skipped multi-variant-design. |
| phase-1-heuristic-evaluation | YES | Nielsen heuristics target GUI usability; CLI UX covered by output-format and exit-code BCs (R6/R7). |
| phase-6-ui-completeness-final / phase-6-responsive-final / phase-6-ui-quality-gate / phase-6-ui-fix-delivery | YES | No UI. Visual convergence satisfied by VHS terminal demo recordings. |
| multi-repo-topology-check / multi-repo-human-confirmation / multi-repo-transition / multi-repo-state-migration | YES | Single-repo project, no project.yaml. |
| phase-1-cicd-setup | COMPLETE | Branch protection live on main+develop (8 required status checks, linear history, enforce_admins=true on main). ci.yml + hardening.yml merged to main at PR #1, commit 78a9f77, 17/17 checks green. Full PR delivery active per D-021/D-022/D-023. D-002 (local-only) superseded by D-021. |
| phase-0-codebase-ingestion | YES | Greenfield project; no existing codebase to ingest. |

## Blocking Issues

| ID | Issue | Severity | Blocking Phase | Owner | Resolution |
|----|-------|----------|----------------|-------|------------|
| BI-002 | phase-1d not converged: novelty increasing across 3 passes (32→34→39); 0 of 3 clean passes; pass 4 not yet run | HIGH | phase-1 gate | orchestrator | mechanical enforcement built; pass 4 is next action and first test of curve-bending |
| BI-005 | DI-012 (slug fidelity) VP coverage INSUFFICIENT; DI-013 PARTIAL — VP-018's 16 golden vectors are the only pin on github-slugger parity; 1-based duplicate counter bug (setup→setup-2 vs setup→setup-1) would pass VP-003 injectivity because outputs remain distinct (FM-002 unprovable) | HIGH | phase-1 gate | architect | needs differential proptest against canonical reference oracle covering all 7 DI-012 rules + duplicate-heading golden vector |
| BI-006 | PR #2 (`feature/spec-lint-tooling`) open and unmerged; `spec-lint` CI job advisory only (D-029, NOT in 8 required status checks) — flip to required at Phase 1 approval per D-029, not now | MEDIUM | phase-2 | pr-manager | run full pr-manager review lifecycle on PR #2 per D-028, then merge when it passes; flip spec-lint to required status check at Phase 1 approval per D-029 |

## Session Resume Checkpoint

| Field | Value |
|-------|-------|
| **Date** | 2026-08-06 |
| **Position** | phase-1d; mechanical enforcement built; violations 254→25; 7/8 checkers green; 0 of 3 clean adversarial passes; pre-restart checkpoint at orchestrator 410K |
| **Convergence counter** | 0 of 3 clean passes |
| **Trajectory** | →0→32→34→39 (REGRESSION all 3 passes; strategy: mechanical enforcement) |

**Next actions (in order):**

1. PR #2 (`feature/spec-lint-tooling` → `develop`, OPEN) — run full pr-manager review lifecycle per D-028, then merge when it passes
2. Adversary pass 4 + consistency pass 4 — skip mechanically-enforced classes; concentrate on 54 unread BC bodies, 24 VP files, ADR bodies, 8 unread arch shards, `dtu-assessment.md`, `gene-transfusion-assessment.md`, `prd.md §1`, `interface-definitions.md`, and interaction clusters: DI-001 (32-thread HTTP pool × rayon scan), URL dedup BC-2.10.009 × per-occurrence × 429 pausing, unbounded `Retry-After` pause (P3-017)
3. Close BI-005 — slug-fidelity VP gap: differential proptest against canonical reference oracle (all 7 DI-012 rules) + duplicate-heading golden vector in VP-018 + DI-012 input exercising inline code and HTML tags through to final anchor key
4. At Phase 1 approval: flip `spec-lint` CI job to required status check per D-029
5. Phase 1 human approval gate — present only when 3 clean passes achieved and BI-005 closed

**Caveats:**
- `cycles/phase-1d/adversary-pass-3.md`: 29 of 39 findings stored as stubs — pass 4 supersedes this record
- Branch protection: 8 required checks, strict, linear history; `enforce_admins=true` on `main`; `required_approving_review_count=0` (GitHub forbids self-approval — review rigor lives in D-028 process)
- `L2-INDEX.md` lacks DD-027 → DI-012/DI-013 cross-refs; INC-MAP-004 (no VP for scanner `.gitignore` isolation) accepted gap with recorded rationale
- `spec-lint` advisory until Phase 1 approval (D-029); 25 `[filled by story-writer]` violations are expected-pending until Phase 2

PRD v1.9 | 66 BCs (all carry owning module, criticality tier, VP anchor) | 25 VPs | 13 DIs | 7 ADRs | 29 DD decisions | 19 policies | holdout pool 12 (5 active: HS-001/004..007; 2 retired: HS-002/003). spec-lint tooling on PR #2 (feature/spec-lint-tooling, unmerged). D-028/D-029 recorded (D-021 partially superseded). BI-004 resolved. BI-005/006 open.

## Concurrent Cycles

| Cycle | Status | Notes |
|-------|--------|-------|
| phase-1d | in-progress | adversarial spec convergence; trajectory →0→32→34→39; pass-3 remediation COMPLETE |

## Historical Content

| Content | Location |
|---------|----------|
| Burst history | `cycles/phase-1d/burst-log.md` |
| Convergence trajectory | `cycles/phase-1d/convergence-trajectory.md` |
| Session checkpoints | `cycles/phase-1d/session-checkpoints.md` |
| Lessons learned | `cycles/phase-1d/lessons.md` |
| Resolved blockers | `cycles/phase-1d/blocking-issues-resolved.md` |

Last Updated: 2026-08-06
