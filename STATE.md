---
document_type: pipeline-state
level: ops
version: "2.1"
status: draft
producer: state-manager
timestamp: 2026-08-05T23:30:00Z
phase: phase-1d
inputs: []
input-hash: "[live-state]"
traces_to: ""
project: mdlinkcheck-cloud
mode: greenfield
current_step: "phase-1d; pass-2 remediation COMPLETE; D-421 latest; trajectory-tail →0→0→32→34; next=pass3+consistency-pass3"
current_cycle: ""
dtu_required: false
---

<!--
  STATE.md SIZE BUDGET (per D-421(c)):
  Soft target: ≤200 lines; margin from soft-target = 500 - 200 = 300; margin from actual = 500 - 160 = 340. 160 lines (wc-l).
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
| **Last Updated** | 2026-08-05 — pass-2 remediation COMPLETE; D-025 pipeline-latest; trajectory-tail →0→0→32→34 |
| **Current Phase** | phase-1d |
| **Current Step** | pass-2 remediation COMPLETE; D-021..D-025 (exhaustive) recorded; BI-001/003 resolved; next=adversary pass 3 + consistency pass 3 |

## Phase Progress

| Phase | Status | Started | Completed | Gate | Finding Progression |
|-------|--------|---------|-----------|------|---------------------|
| pre-1: Planning | completed | 2026-08-05 | 2026-08-05 | HUMAN: market-intel-review + intake-approval | |
| 0: Codebase Ingestion | not-started | | | | |
| 1: Spec Crystallization | artifacts-complete | 2026-08-05 | 2026-08-05 | awaiting phase-1d convergence | |
| phase-1d: Adversarial Spec Review | in-progress | 2026-08-05 | — | adversary: 3 clean passes required | →0→0→32→34 |
| 2: Story Decomposition | not-started | | | | |
| 3: TDD Implementation | not-started | | | | |
| 4: Holdout Evaluation | not-started | | | | |
| 5: Adversarial Refinement | not-started | | | | |
| 6: Formal Hardening | not-started | | | | |
| 7: Convergence | not-started | | | | |
| pass-2 adversary | COMPLETE | 2026-08-05 | 2026-08-05 | — | →0→0→32→34 |
| pass-2 fix burst | COMPLETE | 2026-08-05 | 2026-08-05 | — | →0→0→32→34 |

## Current Phase Steps

<!-- Keep last 5 rows only. Archive older rows to cycles/phase-1d/burst-log.md. -->

| Step | Agent | Status | Output |
|------|-------|--------|--------|
| phase-1d adversary pass 1 | adversary | COMPLETE | adversary-pass-1.md; 32 novel findings; consistency-audit FAIL |
| phase-1d adversary pass 2 | adversary | COMPLETE | adversary-pass-2.md; 34 novel findings (REGRESSION); consistency-audit FAIL |
| phase-1d checkpoint | state-manager | COMPLETE | STATE.md updated; burst-log + convergence-trajectory written |
| phase-1d pass-2 remediation | product-owner/architect/BA/spec-steward/devops | COMPLETE | D-021..D-025 (exhaustive); BI-001/003 resolved; PRD v1.7; delivery model restored; 4 new holdouts |
| next: adversary pass 3 + consistency pass 3 | adversary + consistency-validator | pending | start at unreached perimeter in adversary-pass-2.md |

## Convergence Status

Trajectory →0→0→32→34

pass count: 0 of 3 required clean passes

REGRESSION RISK: novelty increased pass 1 → pass 2 (32 → 34 novel findings). Pass-2 remediation COMPLETE — awaiting pass 3.

| Pass | Findings | Delta | Status |
|------|----------|-------|--------|
| 1 | 32 (6C/21M/5m) | — | FINDINGS_REMAIN |
| 2 | 34 (7C/19M/8m) | +2 | FINDINGS_REMAIN (REGRESSION) — REMEDIATED |

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
| D-021 | Full PR-based delivery restored; merge gate = required CI status checks + factory AI review (pr-reviewer / code-reviewer); agents NEVER merge PRs — orchestrator merges only after human approval at a designed gate | devops-engineer agent attempted to self-merge PR #1 and was blocked by the security guard; `required_approving_review_count` is 0 on both branches because every agent-authored PR is authored by the human's own GitHub account (`drbothen`) and GitHub forbids self-approval — review rigor enforced by CI checks + factory AI review agents | phase-1d | 2026-08-05 | human |
| D-022 | Branch topology: story PRs target `develop`; releases go `develop` → `main` via PR. Branch protection live on both with 8 strict required status checks, linear history, no force-push/deletion; `enforce_admins` true on `main` | Establishes the two-branch delivery model replacing the D-002 local-only workaround | phase-1d | 2026-08-05 | devops-engineer/human |
| D-023 | CI jobs use `Cargo.toml`-presence guards so they pass green before the Rust workspace exists; required status check context strings are the unprefixed job names (`Format check`, `Clippy (deny warnings)`, `Test (ubuntu-latest)`, etc.) — verified empirically from live run 31065845669, NOT the guessed `CI / `-prefixed form | Avoids branch-protection deadlock on bootstrap PR; context string form verified from live CI run | phase-1d | 2026-08-05 | devops-engineer |
| D-024 | Nonexistent/unreadable PATH argument is a runtime I/O error (recorded, scan continues, exit 2 at end) — NOT a startup config error with immediate abort. Required by DD-007 no-fail-fast | architect ruling; PO reconciled | phase-1d | 2026-08-05 | architect |
| D-025 | `verdict::exit_code(findings, io_errors, config_error) -> u8` — three inputs. Precedence: io_errors non-empty OR config_error → 2; elif any broken → 1; else 0; indeterminate never raises the exit code | P2-M19 found the config_error half of exit 2 unmodeled; three-input function closes that gap | phase-1d | 2026-08-05 | architect |

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
| BI-002 | phase-1d not converged: adversary novelty not yet decaying (pass 1: 32 → pass 2: 34 novel); 0 of 3 required clean passes | HIGH | phase-1 gate | orchestrator | continue adversary passes; pass-2 remediation COMPLETE |
| BI-004 | Adversary pass 2 did not reach 56 of 66 BC files, nfr-catalog.md, test-vectors.md, BC-INDEX.md, ADRs 001–005/007, policies.yaml — coverage gap | MEDIUM | phase-1 gate | orchestrator | pass 3 must start at unreached perimeter listed in adversary-pass-2.md |

## Session Resume Checkpoint

| Field | Value |
|-------|-------|
| **Date** | 2026-08-05 |
| **Position** | phase-1d; pass-2 remediation COMPLETE across all owners; remote enabled; full PR delivery active |
| **Next Step** | Adversary pass 3 + consistency pass 3 — start at unreached perimeter listed in adversary-pass-2.md |
| **Convergence counter** | 0 of 3 |

PRD v1.7 | 66 BCs | 24 VPs | 7 ADRs | 9 arch shards | 12 domain-spec shards | 26+ DD decisions | 19 policies | holdout pool 12 (5 active: HS-001/004..007; 2 retired: HS-002/003). Remote live at https://github.com/BOHICA-LABS/mdlinkcheck-cloud. Branch protection active (8 status checks). D-021..D-025 (exhaustive) recorded. BI-001/003 resolved (archived in cycles/phase-1d/blocking-issues-resolved.md).

## Concurrent Cycles

| Cycle | Status | Notes |
|-------|--------|-------|
| phase-1d | in-progress | adversarial spec convergence; trajectory-tail →0→0→32→34; pass-2 remediation COMPLETE |

## Historical Content

| Content | Location |
|---------|----------|
| Burst history | `cycles/phase-1d/burst-log.md` |
| Convergence trajectory | `cycles/phase-1d/convergence-trajectory.md` |
| Session checkpoints | `cycles/phase-1d/session-checkpoints.md` |
| Lessons learned | `cycles/phase-1d/lessons.md` |
| Resolved blockers | `cycles/phase-1d/blocking-issues-resolved.md` |

Last Updated: 2026-08-05
