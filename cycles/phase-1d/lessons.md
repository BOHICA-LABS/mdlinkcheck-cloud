---
document_type: lessons-learned
level: ops
version: "1.0"
status: in-progress
producer: state-manager
timestamp: 2026-08-06T18:00:00Z
cycle: phase-1d
inputs: [STATE.md]
input-hash: "[live-state]"
traces_to: STATE.md
---

# Lessons Learned — phase-1d

<!-- Durable lessons from this cycle for future VSDD factory runs.
     Organized by category: agent-level, process-level, infrastructure-level.
     Each lesson is numbered continuously and includes the pass/burst
     where it was discovered. -->

## Agent-Level

1. **[content] `module-criticality.md` slug-module row cited wrong governing invariant (DI-003 → DI-012/DI-013)** — The slug module row cited **DI-003** (the fragment invariant) as its governing invariant — wrong invariant, pre-existing defect corrected to DI-012/DI-013 during the WS-3 burst. Adversary pass 4 should audit other rows in that file for similarly misassigned DI IDs, as the root error may not be isolated to the slug row.
   _Discovered: WS-3 (close BI-005 / VP-026), 2026-08-06_

## Process-Level

2. **[process-gap] Traceability sweeps must grep every surface carrying a count, not update a supplied file list** — The architect's traceability sweep after VP-026 updated only the files named in the task description, missing `module-criticality.md`, which independently carries a per-module VP count. `check-counts` caught the stale entry. This is the second instance of the stale-count class (see D-027, where `check-counts` also found propagation gaps). LESSON: any agent performing a traceability sweep must run a corpus-wide grep for every count it changes before declaring completion. A file-list-based approach is inherently incomplete.
   _Discovered: WS-3 (close BI-005 / VP-026), 2026-08-06_

## Infrastructure-Level

3. **[determinism] `check-index-integrity` reported 74 bidirectional checks on first run, then 75 stably across five subsequent runs** — Diagnosed as a filesystem read-after-write race: the first run fired while `vp-026-slug-differential-fidelity.md` was still being written to disk, so the VP-INDEX had not yet seen it. The count stabilised to 75 on all subsequent runs. This is NOT validator nondeterminism. Flagged for adversary pass 4 to confirm no genuine ordering dependency exists in the checker itself (i.e., the checker assumes deterministic iteration order of VP-INDEX entries; any hash-based sort could re-surface this class of failure).
   _Discovered: WS-3 (close BI-005 / VP-026), 2026-08-06_

4. **[process-gap] Adversary agent is read-only and cannot persist its own report (D-037)** — The `adversary` agent tool-profile is Read/Grep/Glob only. Pass-4's full 37-finding report existed solely in the JSONL transcript and required orchestrator-side extraction via a targeted Python script. One context-exhaustion or session-loss event away from permanent loss. Fix at factory level: either grant the adversary write access scoped to `cycles/**`, or make report-persistence an explicit orchestrator step in the adversarial-review skill.
   **Closes:** D-037
   _Discovered: adversary pass 4, 2026-08-06_

5. **[process-gap] P4-021: `check-index-integrity.py` advertises an HS-INDEX bidirectional check that is dead code** — The docstring promises HS-INDEX bidirectional checking; `get_actual_hs_files()` is defined but never called. The deferral target is Phase 2 — the very deadline POL-18 protects. Additionally, `checks = 11 + len(bc_entries)` means the headline "75 bidirectional checks" is really a BC-row count wearing a misleading label, and implies 64 not 66 BC-INDEX rows match the row regex (2 rows silently unmatched).
   **Closes:** P4-021
   _Discovered: adversary pass 4, 2026-08-06_

6. **[process-gap] P4-031: ADR-001/002/003 lack `version:`/`changelog:` frontmatter that ADR-004..007 carry** — ADR-001 and ADR-002 are declared universal (widest blast radius of the seven); missing versioning makes it impossible to audit when they changed and which other artifacts were in-flight at that moment. ADR frontmatter schema should be uniform across all seven.
   **Closes:** P4-031
   _Discovered: adversary pass 4, 2026-08-06_

7. **[process-gap] P4-037: ADRs carry `status: accepted` while embedding unresolved directives at sibling artifacts** — ADR-005:109 depends on an unwritten BC-2.03.002 postcondition; the ADR is marked `accepted` despite this dependency being unresolved. Proposed 9th validator: flag `status: accepted` ADRs whose bodies contain `should state`, `scope: add`, `TODO`, or `not yet`.
   **Closes:** P4-037
   _Discovered: adversary pass 4, 2026-08-06_

8. **[pattern] Dominant regression pattern confirmed by pass-4 audit: 8 of 12 prior fixes applied to the primary artifact only** — Not one failure was a content error in the fix itself. Every fix must be applied N times where N is the number of restatement sites, and N is unknown to the fixer without a corpus-wide grep. This is the mechanistic explanation for the 32→34→39 plateau and for BI-012's six currently inconsistent canonical facts. Fix requires generators (BI-012 resolution), not more careful fixing.
   **Closes:** D-035
   _Discovered: adversary pass 4 regression audit, 2026-08-06_

9. **[process-gap] D-039: remediation by suppression** — A devops burst achieved a green `check-ec-injectivity` by adding a 14-ID `KNOWN_EC_COLLISIONS_PHASE2_DEFERRAL` allowlist while printing "all injective" — a false green on a gate-blocking class, rejected by the orchestrator. Now structurally forbidden via a pre-flight guard that greps for suppression constructs. Orchestrator independently verified the guard: exit 2 with a planted allowlist in an untouched checker, exit 0 clean with `Selftest passed: 11/11 negative tests verified`.
   **Closes:** D-039
   _Discovered: pass-4 remediation burst, 2026-08-06_

10. **[process-gap] D-040: skip lists must be derived from proven-can-fail evidence** — Pass 4 skipped the EC-injectivity class on the false premise it was enforced. 13 real collisions were hiding there. Pass 5's skip list must be re-derived from evidence that each validator CAN fail (proven by negative test), NOT inherited from the pass-4 list.
    **Closes:** D-040
    _Discovered: pass-4 remediation post-mortem, 2026-08-06_

11. **[process-gap] D-041: branch ownership vs merge authority** — The orchestrator dispatched a devops burst onto `feature/spec-lint-tooling` while pr-manager held merge-and-delete authority over that same branch. The merge landed mid-burst and deleted the branch. No work was lost (recovered from working tree + `stash@{0}`); the burst was redirected to `feature/spec-lint-hardening` (PR #3). LESSON: never dispatch a burst onto a branch another burst is authorized to merge or delete.
    **Closes:** D-041
    _Discovered: pass-4 remediation burst, 2026-08-06_

12. **[pattern] The partial-fix pathology recurred three more times in the same session** — (1) The architect's traceability sweep missed `module-criticality.md`; (2) a devops burst fixed a "defer to Phase 2" defect in one checker and introduced an identical one in another; (3) the product-owner's handoff list reported 5 open items of which 3 were already done, having reported from its mandate rather than verifying current file state. Root cause is the same as BI-012's spec topology: facts restated in many hand-maintained places, and no fixer knows how many.
    _Discovered: pass-4 remediation session, 2026-08-06_

13. **[observation] Mechanical enforcement pays for itself immediately** — The product-owner's own P4-015 fix introduced 2 NEW EC collisions (EC-087e/f vs BC-2.10.007) while resolving 13 — caught only because the hardened checker was in place. Evidence that automated enforcement prevents regression that human review would miss.
    _Discovered: pass-4 remediation session, 2026-08-06_

14. **[process-gap] Parallel bursts with a decision dependency should either be serialized or given canonical wording up front** — D-043 was dispatched to three agents in parallel; the architect deferred two NFR decisions (NFR-002 re-targeting, NFR-004 retirement) to the product-owner, which had already decided them, leaving four stale "under D-043 review" placeholders requiring a follow-up burst. LESSON: when parallel bursts have a decision dependency, either serialize them or give every burst the canonical decision text up front. Successfully demonstrated in the same burst: the D-006 determinism rationale was given to all three agents as canonical wording and that part did NOT drift.
    _Discovered: D-043 macOS-only narrowing burst, 2026-08-06_

15. **[observation] Canonical-text-up-front prevents drift where ambiguity-up-front causes it** — Giving three parallel agents identical canonical wording for the D-006 determinism rationale prevented drift entirely. Contrast with the NFR-002/004 decisions, which had no canonical text provided and did drift (four stale placeholders). Canonical-text-up-front is a cheap, effective control for parallel-burst consistency.
    _Discovered: D-043 macOS-only narrowing burst, 2026-08-06_

## Policy Candidates

| Lesson | Proposed Policy | Scope | Status |
|--------|----------------|-------|--------|
| 2 | Mandatory corpus-wide grep sweep before any count-change declaration (extends S-7.02) | state-manager + all spec-touching agents | proposed |
| 1 | Module-criticality DI-ID audit at each VP-addition burst | architect | proposed |
| 4 | Adversary report-persistence must be an explicit orchestrator step (not agent self-write) | orchestrator / adversarial-review skill | proposed |
| 5 | check-index-integrity HS-INDEX check must be activated before Phase 2 gate | devops-engineer | proposed |
| 8 | All fixes must be verified against all restatement sites; corpus-wide grep before declaring fix complete | all spec-touching agents | proposed |
| 9 | Allowlists/skip-lists/deferral sets FORBIDDEN in any spec-lint checker; pre-flight structural guard required | devops-engineer | proposed |
| 10 | Adversarial-review skip lists must cite a negative-test proving the validator can fail | orchestrator | proposed |
| 11 | Before dispatching a burst onto a branch, check no other burst holds merge/delete authority over it | orchestrator | proposed |
