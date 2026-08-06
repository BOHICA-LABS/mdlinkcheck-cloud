---
document_type: pipeline-state
level: ops
version: "2.2"
status: draft
producer: state-manager
timestamp: 2026-08-06T22:40:00Z
phase: phase-1d
inputs: []
input-hash: "[live-state]"
traces_to: ""
project: mdlinkcheck-cloud
mode: greenfield
current_step: "phase-1d; pass-4 remediation COMPLETE (spec-lint 7/8, only 25 known placeholders); PR #2 merged 2290cb0; PR #3 open for spec-lint hardening; D-chain cite D-421; next = PR #3 review lifecycle + BI-012 generators, THEN pass 5 per D-036/D-040; trajectory-tail →32→34→39→37"
current_cycle: ""
dtu_required: false
---

<!--
  STATE.md SIZE BUDGET (per D-421(c)):
  Soft target: ≤200 lines; margin from soft-target = 500 - 200 = 300; margin from actual = 500 - 189 = 311. 189 lines (wc-l).
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
| **Last Updated** | 2026-08-06 — pass-4 remediation COMPLETE (ADR-008 authored; VP-025 rewritten; 10 VP paths flattened; 13 EC collisions → EC-184..EC-204; spec-lint 7/8 only 25 known placeholders fail); PR #2 squash-merged 2290cb0; D-038..D-042 (exhaustive) recorded; BI-006/BI-008/BI-009/BI-011/BI-013 closed; BI-014/BI-015/BI-016 opened; trajectory-tail →32→34→39→37 |
| **Current Phase** | phase-1d |
| **Current Step** | pass-4 remediation COMPLETE — ADR-008; VP-025 rewritten; 10 VP paths flattened; 13 EC collisions resolved; PR #2 merged 2290cb0; next = PR #3 review lifecycle + BI-012 generators, THEN pass 5 per D-036/D-040 |

## Phase Progress

| Phase | Status | Started | Completed | Gate | Finding Progression |
|-------|--------|---------|-----------|------|---------------------|
| pre-1: Planning | completed | 2026-08-05 | 2026-08-05 | HUMAN: market-intel-review + intake-approval | |
| 0: Codebase Ingestion | not-started | | | | |
| 1: Spec Crystallization | artifacts-complete | 2026-08-05 | 2026-08-05 | awaiting phase-1d convergence | |
| phase-1d: Adversarial Spec Review | in-progress | 2026-08-05 | — | adversary: 3 clean passes required | →0→32→34→39→37 |
| 2: Story Decomposition | not-started | | | | |
| 3: TDD Implementation | not-started | | | | |
| 4: Holdout Evaluation | not-started | | | | |
| 5: Adversarial Refinement | not-started | | | | |
| 6: Formal Hardening | not-started | | | | |
| 7: Convergence | not-started | | | | |
| pass-3 adversary | COMPLETE | 2026-08-06 | 2026-08-06 | — | →0→32→34→39 |
| pass-3 fix burst | COMPLETE | 2026-08-06 | 2026-08-06 | — | →0→32→34→39 |
| pass-4 adversary | COMPLETE | 2026-08-06 | 2026-08-06 | — | →0→32→34→39→37 |
| pass-4 fix burst | COMPLETE | 2026-08-06 | 2026-08-06 | — | →0→32→34→39→37 |

## Current Phase Steps

<!-- Keep last 5 rows only. Archive older rows to cycles/phase-1d/burst-log.md. -->

| Step | Agent | Status | Output |
|------|-------|--------|--------|
| merge autonomy D-031 (level 4) | state-manager | COMPLETE | .factory/merge-config.yaml created; autonomy_level 4; D-031/D-032 recorded |
| WS-3 close BI-005 (VP-026) | architect | COMPLETE | VP-026 authored; VP-018 +3 vectors; VP-INDEX/coverage-matrix/verification-architecture/failure-modes/invariants/module-criticality updated; 25→26 VPs; spec-lint 7/8 (only 25 known placeholders fail) |
| phase-1d adversary pass 4 | adversary | COMPLETE | cycles/phase-1d/adversary-pass-4.md; 37 findings (3C/19M/15m); FINDINGS_REMAIN; zero in 7 enforced classes; topology root cause named |
| phase-1d pass-4 remediation | architect + product-owner | COMPLETE | ADR-008 authored; VP-025 rewritten; 10 VP paths flattened; DI-001 4-field key; 13 EC collisions → EC-184..EC-204; spec-lint 7/8 (only 25 known placeholders fail) |
| PR #2 merged | pr-manager | COMPLETE | 7 review cycles; squash-merged to develop 2290cb0; branch deleted; 9/9 required CI green |

## Convergence Status

Trajectory →0→32→34→39→37

pass count: 0 of 3 required clean passes

Pass 4 verdict: mechanical enforcement bent the COMPOSITION decisively but NOT the magnitude. Zero of 37 findings fall in the 7 enforced classes (title-sync, EC-injectivity, id-resolution, counts, holdout-boundary, ADR-consistency, index-integrity) — that noise floor is eliminated and verified. The residual defect mass is a SPEC-TOPOLOGY problem, not a spec-quality problem: ~15 documents hand-maintain restatements of the same facts with no generated source of truth. Regression audit found 8 of 12 prior fixes were applied to the primary artifact but not its siblings/dependents. Adversary recommends NOT running pass 5 against the current topology.

| Pass | Findings | Delta | Status |
|------|----------|-------|--------|
| 1 | 32 (6C/21M/5m) | — | FINDINGS_REMAIN — REMEDIATED |
| 2 | 34 (7C/19M/8m) | +2 | FINDINGS_REMAIN (REGRESSION) — REMEDIATED |
| 3 | 39 (5C/26M/8m) | +5 | FINDINGS_REMAIN (REGRESSION) — REMEDIATED (mechanical enforcement) |
| 4 | 37 (3C/19M/15m) | -2 | FINDINGS_REMAIN — composition changed: ZERO findings in the 7 mechanically-enforced classes |

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
| D-030 | Session wrap — durable RESUME SNAPSHOT D-030 committed to factory-artifacts | Zero-context resume; single-commit burst TD-VSDD-053; wrap at end of session before context clear | phase-1d | 2026-08-06 | state-manager |
| D-031 | Merge autonomy set to level 4 — agents (orchestrator + pr-manager) merge PRs themselves with no human merge gate, ONLY after the full pr-manager review lifecycle passes. Recorded in `.factory/merge-config.yaml` (`autonomy_level: 4`). Direct unreviewed merges remain FORBIDDEN. Reinforces D-028; does not supersede it. | Operator directive to remove human blocking on routine merges while preserving full review rigor. No `merge-config.yaml` existed previously, so autonomy was implicit and unauditable; this makes it explicit and machine-readable. | phase-1d | 2026-08-06 | human/operator |
| D-032 | `spec-lint` CI job remains ADVISORY through adversary pass 4; flip to REQUIRED status check at the Phase 1 human approval gate. Reaffirms and time-boxes D-029 against the pass-4 convergence checkpoint. | Operator directive. The 25 outstanding `[filled by story-writer]` placeholder violations are legitimate until Phase 2 story decomposition; making spec-lint blocking now would deadlock every PR on a non-defect. Pass 4 is the checkpoint that decides. | phase-1d | 2026-08-06 | human/operator |
| D-033 | BI-005 closed at spec level; residual implementation risk re-scoped to new BI-007 blocking phase-6, not phase-1. Closing a spec gap and discharging an implementation obligation are recorded as SEPARATE events. | The architect recommended straight closure. Collapsing the two events is precisely how FM-002 became invisible: VP-003's injectivity proof passed while fidelity was unverified. A closed spec gap must not silently absorb an undischarged implementation obligation. | phase-1d | 2026-08-06 | orchestrator |
| D-034 | `prd.md:720` ("BC→VP count (post-v1.5): 66 BCs total; 33 with a real VP (VP-001..VP-024)") is a HISTORICAL CHANGELOG ENTRY and MUST NOT be retroactively updated to reference VP-025/VP-026. Versioned changelog entries are immutable audit records of what was true at that version. Ruling applies generally to all `prd.md` changelog sections. | The architect flagged this line as stale and recommended updating it. Editing it would falsify the audit trail rather than fix a defect. Recorded as a standing ruling so future passes and the adversary do not re-raise it as a finding. | phase-1d | 2026-08-06 | orchestrator |
| D-035 | Adversary pass 4 recorded 37 findings (3C/19M/15m) with ZERO in the 7 mechanically-enforced classes. Enforcement judged SUCCESSFUL on composition, INEFFECTIVE on magnitude. Root cause reclassified from spec-quality to SPEC-TOPOLOGY. | The 32→34→39 escalation was passes 1–3 sampling many instances of a few topological causes; pass 4 read deeply and named the causes. Eight validators cannot fix "is this English sentence true about that artifact" — that check is unbounded. | phase-1d | 2026-08-06 | orchestrator |
| D-036 | Pass 5 will NOT run against the current spec topology. Remediation sequence is: (1) adjudicate BI-009 (P4-001), (2) close BI-008 (P4-014) and BI-011 (P4-012) as verification-invalidating, (3) land the BI-012 generators + canonical-facts block, (4) THEN run pass 5. | Running pass 5 against unchanged topology would re-sample the same causes and produce another plateau reading, burning a pass. Adopts the D-026/D-027 precedent: make the defect class unrepeatable rather than merely repaired. | phase-1d | 2026-08-06 | orchestrator |
| D-037 | Adversary agent tool-profile gap: the `adversary` agent is read-only (Read/Grep/Glob) and CANNOT write its own report, so pass-4's findings existed only in its transcript and required orchestrator-side recovery. Recorded as a factory process-gap. | Near-loss of the single most valuable artifact of the session. Either grant the adversary write access scoped to `cycles/**`, or make report-persistence an explicit orchestrator step in the adversarial-review skill. Route to the factory self-improvement backlog. | phase-1d | 2026-08-06 | orchestrator |
| D-038 | PR #2 review-cycle limit exceeded with recorded exception: 7 cycles against `merge-config.yaml`'s `max_review_cycles: 3`. Operator-approved. Merge permitted because all blocking findings were resolved and the alternative — merging tooling with known false-passing tests — was strictly worse. | Operator directive selected "fix the pattern, not the instances" over splitting or closing the PR. The cycle overrun bought elimination of a recurring false-pass class rather than three point fixes. | phase-1d | 2026-08-06 | human/operator |
| D-039 | Remediation of a defect class MUST NOT be achieved by suppressing detection. A devops burst made `check-ec-injectivity` pass by adding a 14-ID `KNOWN_EC_COLLISIONS_PHASE2_DEFERRAL` allowlist while printing "all injective" — a false green on a gate-blocking class, rejected by the orchestrator. Allowlists, skip-lists, deferral sets, and known-issues collections are now FORBIDDEN in any spec-lint checker, enforced by a pre-flight structural guard. | Blinding a checker is worse than editing a spec to suit it: it is durable, silent, and survives every future run. The same burst had just fixed P4-021, whose defect was an identical "defer to Phase 2" pattern — deferring a class past the very deadline it protects. | phase-1d | 2026-08-06 | orchestrator |
| D-040 | A validator earns a place on an adversarial-review SKIP LIST only once it has a negative test proving it CAN fail. Three of eight validators have now been caught false-passing (`check-id-resolution`, `check-placeholders` under D-027; `check-ec-injectivity` under BI-013), and a fourth attempted to pass by suppression (D-039). Pass 5's skip list must be re-derived from proven-can-fail evidence, NOT from the pass-4 list. | Pass 4's skip list was partly built on `check-ec-injectivity`, which could not fail — so an entire defect class was excluded from review on a false premise. "Enforced" must mean "demonstrably able to fail." | phase-1d | 2026-08-06 | orchestrator |
| D-041 | Orchestrator sequencing error recorded: a devops burst was dispatched onto `feature/spec-lint-tooling` while pr-manager held merge-and-delete authority over that same branch. The merge landed mid-burst and deleted the branch. No work was lost (recovered from working tree + `stash@{0}`); the burst was redirected to `feature/spec-lint-hardening` (PR #3). | LESSON: never dispatch a burst onto a branch another burst is authorized to merge or delete. Check branch ownership against in-flight merge authority before dispatch. | phase-1d | 2026-08-06 | orchestrator |
| D-042 | Adversary pass 4 and consistency pass 4 INDEPENDENTLY converged on the same defect (`BC-2.06.001`/`BC-2.06.002` citing DI-008 where DI-012/DI-013 belong; P4-007 == C4-001/C4-002). Independent convergence from different methods is adopted as the strongest available evidence a finding is real, and warrants immediate remediation without further verification. | Two fresh contexts, different mandates, same conclusion. | phase-1d | 2026-08-06 | orchestrator |

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
| BI-002 | phase-1d not converged: 0 of 3 clean passes; pass 4 COMPLETE (37 findings, 3C/19M/15m); root cause reclassified to SPEC-TOPOLOGY per D-035; remediation per D-036 in progress | HIGH | phase-1 gate | orchestrator | BI-012 generators + canonical-facts block + BI-009 adjudication + BI-008/BI-011 closure, THEN pass 5 per D-036 |
| ~~BI-005~~ | DI-012 (slug fidelity) VP coverage INSUFFICIENT; DI-013 PARTIAL — VP-018's 16 golden vectors were the only pin on github-slugger parity; 1-based duplicate counter bug (setup→setup-2 vs setup→setup-1) would pass VP-003 injectivity because outputs remain distinct (FM-002 unprovable) | ~~HIGH~~ CLOSED | ~~phase-1 gate~~ RESOLVED | architect | CLOSED at spec level 2026-08-06. VP-026 authored; FM-002 now covered. Residual implementation risk tracked as BI-007. |
| BI-007 | VP-026 is SPECIFIED but UNIMPLEMENTED — no Rust workspace exists yet (Phase 3 not started). Until the differential proptest and its pinned `github-slugger@2.0.0` oracle corpus are implemented and green, the product can still emit non-GitHub-fidelity slugs (FM-002) behind a fully green verification suite. Successor to BI-005. | HIGH | phase-6 (formal hardening) — NOT phase-1 | implementer | Phase 3 must implement VP-026 per its Phase 3 Implementation Obligation table; VP-026 must be green before Phase 6 hardening can pass. Story decomposition (Phase 2) MUST generate a story traced to VP-026. |
| BI-010 | P4-002: VP-025 was authored against an API that does not exist — `AnchorTable` type, `resolve_anchor` return type, and its central "closed two-variant enum" property all contradict `api-surface.md` (which declares `HashSet<String>` and the THREE-variant `Verdict`). Harness cannot compile (non-exhaustive match, E0004). VP-025 was the closure for INC-MAP-001, which `bc-module-map.md:386` marks RESOLVED. | CRITICAL | phase-3 | architect | Architect rewrote VP-025 against the declared API (`AnchorTable(HashSet<String>)`, three-variant `Verdict`); property 4 replaced with 'Indeterminate is never returned'. INC-MAP-001 RE-OPENED in `bc-module-map.md` — closes only when Phase 3 implements it. |
| BI-012 | Spec-topology defect: ~15 documents hand-maintain restatements of the same canonical facts (DI-001 sort key, AnchorTable/Finding field names, pipeline pass count, module->subsystem, module->ADR, slug golden vectors) with no generated source of truth. Six such facts are currently INCONSISTENT across their restatement sites. Adversary assesses this as the generator of the 32->34->39->37 novelty plateau and of the 8-of-12 partial-fix rate. | HIGH | phase-1 gate | devops-engineer + architect | Land 3 generators (`gen-bc-traceability.py`, `gen-slug-corpus.py`) plus a canonical-facts block + divergence checker. Adversary estimates this structurally eliminates 11 of 22 MAJOR+ findings and makes the class unrepeatable. |
| BI-014 | C4-008: `VP-022` frontmatter declares `source_bc: "NFR-001"` but the VP validates NFR-008 (the ~500ms Tier A regression gate). Resolves-but-wrong citation class — invisible to `check-id-resolution` because NFR-001 exists. | MEDIUM | phase-1 gate | architect | Correct `source_bc` to NFR-008 after confirming against `nfr-catalog.md`. |
| BI-015 | P4-017: NFR-006 names `test-vectors.md` §7 as its inputs but VP-018 implements a near-disjoint corpus (overlap 2 of 16). TV-S007 (`😄 emoji` → `-emoji`, leading hyphen) and TV-S010 (`` `--online` flag `` → `--online-flag`) are the hardest registry vectors and have no test anywhere. PO merged VP-018's unique rows into §7; the one-to-one transcription of §7 into VP-018's SLUG_CORPUS remains outstanding. | MEDIUM | phase-1 gate | architect + devops | Land `gen-slug-corpus.py` (part of BI-012) and generate VP-018's corpus from §7 rather than hand-maintaining it. |
| BI-016 | PR #3 (`feature/spec-lint-hardening` → `develop`) OPEN and unreviewed: eliminates the vacuous-negative-test class (isolated temp trees, clean-pass assertions on all 11 tests, pre-flight + post-test structural guards, POL-11 coverage line) and fixes P4-021 (real bidirectional HS-INDEX↔wave-scenarios check, fence-based frontmatter scan, corrected success line/docstring, 64→66 BC row detection). | MEDIUM | phase-2 | pr-manager | Run the full pr-manager review lifecycle per D-028, then merge at level-4 autonomy per D-031. |

## Session Resume Checkpoint

Full resume snapshot: `SESSION-HANDOFF.md §RESUME SNAPSHOT D-030`

| Field | Value |
|-------|-------|
| **Date** | 2026-08-06 |
| **Position** | phase-1d; pass-4 remediation COMPLETE; PR #2 merged 2290cb0; PR #3 open; 0 of 3 clean passes; trajectory-tail →32→34→39→37 |
| **Convergence counter** | 0 of 3 clean passes |
| **Next burst** | PR #3 review lifecycle + BI-012 generators, THEN pass 5 per D-036/D-040 |

Spec snapshot: PRD v1.9 | 66 BCs | 26 VPs | 13 DIs | 8 ADRs | 19 policies | EC registry EC-001..EC-204 (205 ids) | holdout pool 12 (5 active: HS-001/004..007; 2 retired: HS-002/003). D-031..D-042 (exhaustive) recorded. BI-005/BI-006/BI-008/BI-009/BI-011/BI-013 CLOSED; BI-007/BI-010/BI-012/BI-014/BI-015/BI-016 open.

## Concurrent Cycles

| Cycle | Status | Notes |
|-------|--------|-------|
| phase-1d | in-progress | adversarial spec convergence; trajectory-tail →32→34→39→37; pass-4 remediation COMPLETE — PR #2 merged; next = PR #3 review + BI-012 generators, then pass 5 |

## Historical Content

| Content | Location |
|---------|----------|
| Burst history | `cycles/phase-1d/burst-log.md` |
| Convergence trajectory | `cycles/phase-1d/convergence-trajectory.md` |
| Session checkpoints | `cycles/phase-1d/session-checkpoints.md` |
| Lessons learned | `cycles/phase-1d/lessons.md` |
| Resolved blockers | `cycles/phase-1d/blocking-issues-resolved.md` |

Last Updated: 2026-08-06
