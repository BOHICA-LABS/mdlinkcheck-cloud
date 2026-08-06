---
document_type: pipeline-state
level: ops
version: "2.4"
status: draft
producer: state-manager
timestamp: 2026-08-06T22:30:00Z
phase: phase-1d
inputs: []
input-hash: "[live-state]"
traces_to: ""
project: mdlinkcheck-cloud
mode: greenfield
current_step: "phase-1d; working tree: feature/spec-lint-hardening; PR #4: APPROVE awaiting CI re-trigger (GitHub Actions outage 2026-08-06T15:22Z); PR #3: mutation audit COMPLETE (6d954ab, 17/17, BI-019 RESOLVED); covered_sha stale (update to 6d954ab before merge); D-046..D-050 (exhaustive); trajectory-tail →32→34→39→37; D-chain cite D-050 D-421"
current_cycle: ""
dtu_required: false
---

<!--
  STATE.md SIZE BUDGET (per D-421(c)):
  Soft target: ≤200 lines; margin from soft-target = 500 - 200 = 300; margin from actual = 500 - 199 = 301. 199 lines (wc-l).
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
| **Last Updated** | 2026-08-06 — PR #3 mutation audit COMPLETE (6d954ab, 15→17 tests, 4/15 over-determined, BI-019 RESOLVED); PR #4 APPROVE on 6503d3b; both merge-ready pending CI (GitHub Actions outage 2026-08-06T15:22Z); D-046..D-050 (exhaustive); trajectory-tail →32→34→39→37; bc-module-map.md v1.4; branch = feature/spec-lint-hardening |
| **Current Phase** | phase-1d |
| **Current Step** | PR #4: APPROVE on 6503d3b, awaiting CI re-trigger (outage — `gh pr close 4 && gh pr reopen 4`; fallback `gh workflow run ci.yml --ref chore/macos-only-ci`; `on.push.branches` omits `chore/**`); PR #3: mutation audit COMPLETE (6d954ab, 17/17); pr-reviewer APPROVE STALE (covered a9b9be0; update covered_sha to 6d954ab); next = CI re-trigger both PRs → merge (WS-A), then WS-B generators, WS-C pass 5 per D-036/D-040 |

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
| pass-3 adversary | COMPLETE | 2026-08-06 | 2026-08-06 | — | →0→32→34→39→37 |
| pass-3 fix burst | COMPLETE | 2026-08-06 | 2026-08-06 | — | →0→32→34→39→37 |
| pass-4 adversary | COMPLETE | 2026-08-06 | 2026-08-06 | — | →0→32→34→39→37 |
| pass-4 fix burst | COMPLETE | 2026-08-06 | 2026-08-06 | — | →0→32→34→39→37 |

## Current Phase Steps

<!-- Keep last 5 rows only. Archive older rows to cycles/phase-1d/burst-log.md. -->

| Step | Agent | Status | Output |
|------|-------|--------|--------|
| phase-1d adversary pass 4 | adversary | COMPLETE | cycles/phase-1d/adversary-pass-4.md; 37 findings (3C/19M/15m); FINDINGS_REMAIN; zero in 7 enforced classes; topology root cause named |
| phase-1d pass-4 remediation | architect + product-owner | COMPLETE | ADR-008 authored; VP-025 rewritten; 10 VP paths flattened; DI-001 4-field key; 13 EC collisions → EC-184..EC-204; spec-lint 7/8 (only 25 known placeholders fail) |
| PR #2 merged | pr-manager | COMPLETE | 7 review cycles; squash-merged to develop 2290cb0; branch deleted; 9/9 required CI green |
| D-043 macOS-only platform narrowing | architect + product-owner + devops | COMPLETE | branch protection 8→4 contexts both branches; ci.yml matrices → macos-latest (PR #4); NFR-002 re-targeted 10s, NFR-004 retired, T13 retired; unicode-normalization pinned 0.1.24; C4-008 fixed; spec-lint 7/8 |
| PR #4 APPROVE + PR #3 mutation audit COMPLETE + D-050 | pr-manager + state-manager | COMPLETE | PR #4: APPROVE on 6503d3b (CI blocked: GitHub Actions outage 2026-08-06T15:22Z); PR #3: audit COMPLETE (6d954ab, 15→17 tests, 4/15 over-determined); BI-019 RESOLVED; BI-014 closed; D-046..D-050 (exhaustive); trajectory-tail →32→34→39→37; bc-module-map.md v1.4 |

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
| D-041 | Orchestrator sequencing error recorded: a devops burst was dispatched onto `feature/spec-lint-tooling` while pr-manager held merge-and-delete authority over that same branch. The merge landed mid-burst and deleted the branch. No work was lost (recovered from working tree + `stash@{0}`); the burst was redirected to `feature/spec-lint-hardening` (PR #3). Recorded as a factory process-gap. | LESSON: never dispatch a burst onto a branch another burst is authorized to merge or delete. Check branch ownership against in-flight merge authority before dispatch. | phase-1d | 2026-08-06 | orchestrator |
| D-042 | Adversary pass 4 and consistency pass 4 INDEPENDENTLY converged on the same defect (`BC-2.06.001`/`BC-2.06.002` citing DI-008 where DI-012/DI-013 belong; P4-007 == C4-001/C4-002). Independent convergence from different methods is adopted as the strongest available evidence a finding is real, and warrants immediate remediation without further verification. | Two fresh contexts, different mandates, same conclusion. | phase-1d | 2026-08-06 | orchestrator |
| D-043 | Platform matrix narrowed to **macOS latest ONLY**. Linux and Windows dropped from CI test/build jobs and from branch-protection required checks (8 → 4 contexts on both branches). NFR-002 RE-TARGETED to 10s p95 on `macos-latest` shared CI (kept distinct from NFR-001's 5s on an Apple Silicon dev machine). NFR-004 (cross-platform portability) RETIRED as vacuous. Trap T13 (Windows path separators) retired as platform-obsolete. **D-006 / ADR-006 / DI-002 (strict case-sensitive + NFC path comparison) REMAIN IN FORCE**, with rationale restated on determinism grounds rather than platform-divergence grounds. `unicode-normalization` pinned to exactly `0.1.24`, load-bearing for DI-001/DI-002/VP-008/VP-009 on determinism grounds and explicitly surviving NFR-004's retirement. | Operator directive; simplifies CI (9 → 5 jobs per run, −44%). Rationale restatement was required because D-006's recorded justification argued from macOS-vs-Linux divergence, which partly evaporates under a single-platform matrix — leaving it would have left a live decision resting on obsolete reasoning for a future pass to re-litigate. | phase-1d | 2026-08-06 | human/operator |
| D-044 | Platform-independent CI jobs (`Format check`, `Clippy`, `Spec lint`, and all 6 `hardening.yml` jobs) deliberately REMAIN on `ubuntu-latest` under D-043. Only genuinely macOS-dependent jobs (`Test`, `Build release`) moved to `macos-latest`. | macOS runners cost ~10x Linux. `cargo fmt`/`clippy` are syntactic/semantic with no OS-specific behaviour; `spec-lint` is pure Python over YAML/Markdown; GitGuardian is a hosted service. Literal platform uniformity would have increased CI cost while the directive's stated goal was simplification. Reversible if strict uniformity is later preferred. | phase-1d | 2026-08-06 | orchestrator |
| D-045 | Dropping Linux/Windows CI removes an INCIDENTAL safety net for case-sensitivity and Unicode-normalization divergence. No VP coverage is lost (all 26 VPs are platform-independent by construction), but `path_resolver`'s explicit `read_dir` case-sensitive enumeration and the NFC layer become SOLELY load-bearing, with VP-008/VP-009 as the only gatekeepers. Consequence: Phase 6 formal hardening of BC-2.07.003 is RAISED in priority. | Independently concluded by both the product-owner and architect bursts working in parallel (D-042 independent-convergence principle). ADR-006 is now MORE load-bearing, not less: macOS APFS is case-insensitive and NFD-storing, and on a macOS-only matrix it is the only filesystem, so nothing incidentally catches a missing normalization call. | phase-1d | 2026-08-06 | orchestrator |
| D-046 | Restricted-path merge gate WAIVED by operator for PR #3 and PR #4 ONLY. Both PRs consist entirely of restricted-path files (`.github/**` and `scripts/spec-lint/**`) which `merge-config.yaml` marks "always flag for human attention regardless of autonomy level." Operator granted explicit waiver for these two PRs. `merge-config.yaml` NOT amended — rule remains in force for all future PRs, which must seek fresh authorization. | Both PRs were complete before the waiver need was identified; their restricted-path content was already authored and reviewed. Future restricted-path PRs must seek fresh authorization per the rule's original intent. | phase-1d | 2026-08-06 | human/operator |
| D-047 | Merge wrapper scripts (`check-stale-verdict.sh`, `enforce-merge-strategy.sh`) built at `.factory/bin/` rather than `plugins/vsdd-factory/bin/`. Ship with D-040 negative tests (4/4 each) and D-039 clean (no bypass flags). Fail-closed. | `plugins/` belongs to the dark-factory engine and MUST NOT be created in a product repo. Placing scripts in the product tree would require their own PR + review cycle on the restricted path `scripts/spec-lint/**` — an unwanted recursion. `.factory/bin/` is the correct location for factory-scoped tooling that must not ship in the product. | phase-1d | 2026-08-06 | operator/orchestrator |
| D-048 | INC-MAP-001 recorded as `SPEC-RESOLVED / IMPL-PENDING`, NOT `RESOLVED`. `bc-module-map.md` bumped v1.3 → v1.4. VP-025 v1.1 discharges the spec-level API misalignment (AnchorTable(HashSet<String>), three-variant Verdict, corrected import path, property 4 replaced); Phase 3 implementation obligation remains open under BI-010. | Per D-033, closing a spec gap and discharging an implementation obligation are separate events (precedent: BI-005 → BI-007 split). Orchestrator rejected architect recommendation of bare closure. Collapsing the two events is precisely how FM-002 became invisible (VP-003 passed while fidelity was unverified). | phase-1d | 2026-08-06 | orchestrator |
| D-049 | Review cycle 5 EXCEPTION granted for PR #3 by operator, exceeding `max_review_cycles: 3` (precedent D-038, the PR #2 exception). Operator additionally ordered a mutation audit of ALL 15 selftests, not only the B-6 fix, reasoning that over-determination may be systemic and WS-C requires a provably sound skip list per D-040. | B-4 and B-6 (both over-determination defects) were found independently in the same session without searching. An unproven `check-index-integrity` cannot go on the WS-C pass-5 skip list — that is precisely the failure class that put false-passing `check-ec-injectivity` on pass 4's skip list and hid 13 real EC collisions. Mutation audit scopes the risk before committing to the skip list. | phase-1d | 2026-08-06 | human/operator |
| D-050 | Full mutation audit (operator-ordered per D-049) found 4 of 15 selftests over-determined (27%), not the 1 originally suspected. A green negative-test suite is NOT evidence of validator trustworthiness without mutation verification of each test. Standing rule: mutation verification is required for all future skip-list entries. WS-C consequence: `check-index-integrity`, `check-counts`, `check-adr-consistency`, and `check-title-sync` are proven-can-fail — eligible for the pass-5 skip list per D-040. PR #3 head `6d954ab` (15→17 tests; G1+G2 guard tests for M-1; `__pycache__`/`*.pyc` to `.gitignore`). Orchestrator independently verified at `6d954ab`. | Three of four over-determined tests would have shipped invisibly if only B-6 was patched. D-040's "proven-can-fail" standard is only meaningful under mutation verification. Over-determined: selftest 2 (check-counts co-fired on subsystems); selftest 5 (check-adr-consistency co-fired on dns-failure); selftest 9 (check-title-sync co-fired on PRD §2); selftest 10d (forward-check masked malformed-EC detection). | phase-1d | 2026-08-06 | human/operator |

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
| BI-012 | Spec-topology defect: ~15 documents hand-maintain restatements of the same canonical facts (DI-001 sort key, AnchorTable/Finding field names, pipeline pass count, module->subsystem, module->ADR, slug golden vectors) with no generated source of truth. Five such facts are currently INCONSISTENT across their restatement sites (FACT-4 module→subsystem confirmed AGREES at all checked BC sites; true count: 5, not 6). | HIGH | phase-1 gate | devops-engineer + architect | Land 3 generators (`gen-bc-traceability.py`, `gen-slug-corpus.py`) plus a canonical-facts block + divergence checker. Adversary estimates this structurally eliminates 11 of 22 MAJOR+ findings and makes the class unrepeatable. |
| BI-015 | P4-017: NFR-006 names `test-vectors.md` §7 as its inputs but VP-018 implements a near-disjoint corpus (overlap 2 of 16). TV-S007 (`😄 emoji` → `-emoji`, leading hyphen) and TV-S010 (`` `--online` flag `` → `--online-flag`) are the hardest registry vectors and have no test anywhere. PO merged VP-018's unique rows into §7; the one-to-one transcription of §7 into VP-018's SLUG_CORPUS remains outstanding. | MEDIUM | phase-1 gate | architect + devops | Land `gen-slug-corpus.py` (part of BI-012) and generate VP-018's corpus from §7 rather than hand-maintaining it. |
| BI-016 | PR #3 (`feature/spec-lint-hardening` → `develop`) OPEN: eliminates the vacuous-negative-test class and fixes P4-021. Head `6d954ab` (15→17 tests, 17/17 passing, BI-019 RESOLVED). Awaiting CI (GitHub Actions outage). | MEDIUM | phase-2 | pr-manager | Cycle-5 mutation audit COMPLETE. pr-reviewer APPROVE STALE (covered `a9b9be0`; `covered_sha` must be updated to `6d954ab` before merge; `check-stale-verdict.sh` will exit 1). PR #3 merge-ready pending CI + covered_sha update. Merge at level-4 autonomy per D-031. |
| BI-017 | Phase 3 CI obligation: NO perf-gate/benchmark job exists in any workflow (orchestrator verified zero matches for `perf-gate`, `NFR-008`, `hyperfine`, `bench` under `.github/workflows/`). When the NFR-008 regression gate (~500ms p95 Tier A) and the NFR-002 benchmark (10s p95) jobs are created in Phase 3, both MUST run on `macos-latest` — their thresholds are Apple-Silicon-calibrated and a Linux runner would silently invalidate them. | MEDIUM | phase-3 | devops-engineer | Recorded in `verification-properties/vp-022-regression-gate.md` Phase 3 obligations and `architecture/tooling-selection.md` §Phase 3 CI Obligations. |
| BI-018 | PR #4 (`chore/macos-only-ci` → develop): reduces `ci.yml` test/build matrices to `macos-latest`. Branch protection was already narrowed to 4 contexts BEFORE the workflow change (deadlock-free ordering per D-023). All 4 required contexts verified reporting on PR #4; `mergeable: MERGEABLE`. | MEDIUM | phase-2 | pr-manager | Review COMPLETE — APPROVE issued on head `6503d3b`. ZERO workflow runs (pushed mid-outage; GitHub never created runs). Recovery: `gh pr close 4 && gh pr reopen 4` (re-fires `pull_request` event; preserves SHA and APPROVE verdict). DO NOT push an empty commit — invalidates APPROVE. Fallback: `gh workflow run ci.yml --ref chore/macos-only-ci` (workflow_dispatch enabled; `on.push.branches` does NOT cover `chore/**`). |
| ~~BI-019~~ | ~~B-6 over-determination (selftest 10d in check-index-integrity.py)~~ | ~~CRITICAL~~ **CLOSED** | resolved | test-writer | CLOSED 2026-08-06: Mutation audit COMPLETE at `6d954ab`; suite 15→17 (G1+G2 guard tests for M-1); 17/17 passing. 4/15 over-determined (D-050). `check-index-integrity`, `check-counts`, `check-adr-consistency`, `check-title-sync` proven-can-fail → eligible for WS-C pass-5 skip list per D-040. Orchestrator independently verified. |

## Session Resume Checkpoint

Full resume snapshot: `SESSION-HANDOFF.md §RESUME SNAPSHOT D-050`

| Field | Value |
|-------|-------|
| **Date** | 2026-08-06 |
| **Position** | phase-1d; working tree: feature/spec-lint-hardening; PR #4: APPROVE on 6503d3b, awaiting CI re-trigger (GitHub Actions outage 2026-08-06T15:22Z); PR #3: mutation audit COMPLETE (6d954ab, 17/17, BI-019 RESOLVED); covered_sha stale (update to 6d954ab); 0 of 3 clean passes; trajectory-tail →32→34→39→37 |
| **Convergence counter** | 0 of 3 clean passes |
| **Next burst** | (1) CI re-trigger both PRs → merge (WS-A); (2) WS-B BI-012 generators; (3) WS-C pass 5 per D-036/D-040 (eligible skip list: check-index-integrity, check-counts, check-adr-consistency, check-title-sync per D-050) |

Spec snapshot: PRD v1.9 | 66 BCs | 26 VPs | 13 DIs | 8 ADRs | 19 policies | EC registry EC-001..EC-204 (205 ids) | holdout pool 12 (5 active: HS-001/004..007; 2 retired: HS-002/003). D-001..D-050 recorded (exhaustive). Closed: BI-005/006/008/009/011/013/014/019. Open: BI-007/010/012/015/016/017/018.

## Concurrent Cycles

| Cycle | Status | Notes |
|-------|--------|-------|
| phase-1d | in-progress | adversarial spec convergence; trajectory-tail →32→34→39→37; PR #4 APPROVE awaiting CI re-trigger (GitHub Actions outage 2026-08-06T15:22Z); PR #3 mutation audit COMPLETE (6d954ab, BI-019 RESOLVED; covered_sha stale); next = WS-A both PRs merge + WS-B generators + WS-C pass 5 |

## Historical Content

| Content | Location |
|---------|----------|
| Burst history | `cycles/phase-1d/burst-log.md` |
| Convergence trajectory | `cycles/phase-1d/convergence-trajectory.md` |
| Session checkpoints | `cycles/phase-1d/session-checkpoints.md` |
| Lessons learned | `cycles/phase-1d/lessons.md` |
| Resolved blockers | `cycles/phase-1d/blocking-issues-resolved.md` |

Last Updated: 2026-08-06 — PR #3 mutation audit COMPLETE (6d954ab, 4/15 over-determined, BI-019 RESOLVED); PR #4 APPROVE on 6503d3b; both merge-ready pending CI; D-046..D-050 (exhaustive); trajectory-tail →32→34→39→37
