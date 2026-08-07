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

16. **[process-gap] Standing rule: any new cross-cutting decision MUST register its canonical fact in the same burst** — `canonical-facts.toml` had no platform-matrix fact, making `check-canonical-facts.py` structurally incapable of detecting the divergence that produced CV5-001 even after a 13-site sweep. The registry permanently lagged D-043 by one burst — which is precisely the mechanism by which CV5-001 survived a sweep that reached 13+ downstream files. Rule adopted as standing: any `D-NNN` decision that names a canonical value or authoritative string MUST register a FACT-N entry in `canonical-facts.toml` in the SAME burst, not as a follow-up.
    _Discovered: CV5-001 closure burst, 2026-08-07_

17. **[process-gap] FACT-7's first version had a false-pass hole in the very pattern added to close the gap** — Pattern `([^\s(]+)` captured only the FIRST TOKEN of the platform clause, so "macOS and Linux" and "macOS and Windows (D-043)" both returned GREEN with a second platform present. The checker caught CV5-001's literal string only incidentally (the comma fell inside the capture). Caught by adversarial verification — orchestrator re-executed `re.search(pattern, text, re.DOTALL).group(1)` against real files and mutated variants — NOT by reading the checker report. Re-anchored: patterns now capture the full clause up to the " (" terminator. Verification: FACT-7 `group(1)='macOS'` matches; FACT-8 `group(1)='macOS only'` matches; "macOS and Linux", "macOS, Linux, Windows", "macOS and Windows (D-043)", "Linux, macOS" all FAIL. **Known brittleness (record explicitly):** a benign reformat dropping the trailing parenthetical causes `.*?` + `re.DOTALL` to run past the newline → FALSE FAIL (fail-closed direction; acceptable; do NOT loosen the pattern to fix it).
    _Discovered: CV5-001 closure burst, 2026-08-07_

18. **[pattern] Third confirmed instance in this session: REMEDIATIONS HAVE THEMSELVES INTRODUCED DEFECTS — rule is load-bearing and paying for itself** — The re-anchoring of FACT-7/FACT-8 patterns introduced a false-pass hole that was caught only because the orchestrator re-executed the checker's exact `re.search` contract against real files and mutated variants. This is the third confirmed instance where a "fix applied" claim required adversarial verification to catch a defect in the fix itself. The standing rule — "do not accept any 'fix applied' claim at face value; verify against the artifact" — has triggered three times in one session. Record as explicitly load-bearing.
    _Discovered: CV5-001 closure burst, 2026-08-07_

19. **[infrastructure] Environmental finding: `workflow_dispatch`-triggered CI runs are excluded from the PR status-check rollup** — Runs dispatched via `workflow_dispatch` attach to the commit but do NOT appear in the pull request's status-check rollup. GraphQL reports 1 context (GitGuardian) on PR #4 and PR #3, versus all 10 on PR #5 whose run was `pull_request`-triggered. Branch protection therefore still reports BLOCKED even when all required checks are green on the underlying commit. Only a `pull_request`-typed run at the same SHA — obtained via close→reopen — can satisfy the gate. Confirmed non-transient on re-query. The `destructive-command-guard` hook blocks `gh pr close`; resolution requires operator authorization. Escalated; resolution PENDING.
    _Discovered: merge-queue execution attempt, 2026-08-07_

20. **[process-gap] Verification downstream of classification inherits the classifier's blind spots — generalizable root cause of B-8/B-9/B-11** — All three consecutive `check-index-integrity.py` defects had the same shape: a fix moved the verification backstop one step further downstream of the pre-filter/classifier chain, but the same classification blind spot that defeated the original check also defeated the new backstop. B-8 fix: added an accounting invariant, but `hs_rows_seen` was incremented inside the classifier's output set (post-filter), so the invariant held vacuously when no rows passed the filter. B-9 fix: moved the backstop to a shared parser anchor, but the parser anchor used the same `^\|` regex as the filter — one leading space defeated both. B-11: `hs_rows_seen += 1` was placed AFTER five `continue` pre-filters — same shape again. **Standing rule: any verification backstop must be placed UPSTREAM of (or independently of) the classification it is intended to bound. Downstream placement inherits upstream blind spots.**
    _Discovered: PR #3 B-11 review, 2026-08-07_

21. **[process-gap] Orchestrator's own B-8 verification was insufficient — presence of a guard is NOT evidence of soundness** — When B-8 was fixed at `1fc1bce`, the orchestrator verified that the accounting invariant existed in the code. It did NOT verify whether the invariant could be DEFEATED by a realistic malformed input. The subsequent B-9 review found it could be. Standing rule: **presence of a guard is NOT evidence; only a mutation that flips a test from PASS to FAIL is evidence.** Specifically: for every new backstop or invariant, at least one input must be identified that (a) would bypass the pre-filters, (b) would be miscounted, and (c) would cause the invariant to trip — and a test vector for that input must be added. This extends D-050 to COVER the check itself, not just prove it can fail in isolation.
    _Discovered: PR #3 B-11 review, 2026-08-07_

22. **[observation] Fifth confirmed instance of "REMEDIATIONS HAVE THEMSELVES INTRODUCED DEFECTS" — pattern is now systemic** — The four instances in this session: (1) VP-008 proof-method regression from the D-043 edit (fixed in PR #3 B-6 review burst); (2) B-9 — the B-8 backstop fix shared the same `^\|` anchor as the pre-filter it was supposed to verify; (3) B-11 — the B-9 re-anchor fix moved `hs_rows_seen += 1` downstream of the pre-filters; (4) B-8 — the accounting invariant held vacuously because `hs_rows_seen` was incremented on post-filter rows only; (5) FACT-7 false-pass hole — the re-anchored pattern captured only the first token, so "macOS and Linux" matched incorrectly (caught by orchestrator re-executing the regex contract). Five instances is a systemic pattern, not isolated incidents. The "REMEDIATIONS HAVE THEMSELVES INTRODUCED DEFECTS" finding from the D-057 snapshot is now the PROJECT-LEVEL STANDING WARNING for this codebase.
    _Discovered: PR #3 B-11 review session, 2026-08-07_

23. **`[process-gap]` A hand-rolled Markdown parser cannot be validated against itself.** Ten-plus bypasses across four fix rounds in one component in one session. Each round closed the spellings it was shown and opened a neighbouring one. Closing the class requires either a real CommonMark/GFM oracle to grade against, or eliminating the parser (generate-and-diff). Extends the D-066 design-signal finding with decisive empirical weight.
    _Discovered: PR #3 four-round review lifecycle, 2026-08-07_

24. **`[process-gap]` A conservation law proves totality, not correctness — the D-050→D-057 lineage recurring a third time.** "No line vanishes from the accounting" is a strictly weaker property than "no row can hide." Unbounded sink buckets (`prose`, `fenced_code`) satisfy the former while violating the latter. The orchestrator's own 12,000-case verification (40 seeds × 300) tested the weaker property and returned a false sense of closure; a fresh reviewer disproved it with five mutations that left the property test green. Standing rule: when admitting a property test as evidence, state explicitly which property it constrains and which it does not.
    _Discovered: D-070 ruling, 2026-08-07_

25. **`[process-gap]` Recognition predicates must fail toward COUNTING/REPORTING, never toward skipping.** This is the generalizable principle extracted from D-068/D-069 and it is the correct lens for the whole spec-lint suite, not just this checker. A recognition gate whose failure makes an item invisible is the D-039 forbidden pattern in disguise regardless of whether it is literally named an allowlist; a recognition set whose failure makes an item MORE visible is compliant. Verified live: renaming the HS-INDEX header cell `HS ID` → `Scenario ID` produces `Check FAILED`, not a silent pass.
    _Discovered: D-068/D-069 rulings, 2026-08-07_

26. **`[process-gap]` Orchestrator error — a merge gate was very nearly defeated by tautological invocation.** `check-stale-verdict.sh <pr> <covered-sha>` takes the covered SHA as an argument and compares it to live HEAD. The orchestrator first invoked it passing live HEAD as the covered SHA, which made the comparison vacuous and returned FRESH. Caught before merging; re-run correctly with the actually-reviewed SHA, it correctly reported STALE and forced a confirmatory review at `7c1eccf`. This is the D-058 anti-pattern in operational form — the control was sound, the invocation was not. LESSON: a gate that accepts the value it is meant to verify as a parameter can be satisfied by misuse; prefer gates that derive both sides themselves.
    _Discovered: PR #3 merge gate execution, 2026-08-07_

27. **`[process-gap]` Orchestrator error — an unrequested state-changing probe against a live PR.** The orchestrator re-ran `gh pr review --request-changes` with throwaway body content purely to re-test BI-039, when definitive evidence already existed from an earlier genuine attempt. The call was correctly denied by the permission classifier. LESSON: do not re-probe a shared external system to reconfirm what is already established.
    _Discovered: BI-039 investigation, 2026-08-07_

28. **Docstring overclaiming was a four-round recurring defect and required explicit, repeated intervention.** Three consecutive rounds shipped docstrings asserting more safety than the code delivered; the fourth still missed one block (MAJOR-1 at `:742-743`, the only remaining "closes the class" claim in the file), fixed at `7c1eccf`. An overclaiming docstring is worse than none, because a future reader greps for the claim and inherits the false conclusion. The honest framing that finally landed — "NARROWED, not closed," with the unbounded sinks and tracking story named — should be the template.
    _Discovered: PR #3 four-round review lifecycle, 2026-08-07_

29. **Positive: adversarial review paid for itself repeatedly.** Every one of the four fix rounds was caught by a fresh-context reviewer, never by the implementer's own green suite. Three separate reviewers each found a real BLOCKING defect that the implementer's passing tests did not surface — including one strict regression introduced by the fix that claimed to close the class. Independent verification by the orchestrator (executing fixtures rather than trusting reports) upgraded two reviewer findings and corrected one overstatement.
    _Discovered: PR #3 four-round review lifecycle, 2026-08-07_

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
| 16 | Register canonical fact in canonical-facts.toml in the same burst as the decision that names it | all decision-making agents | proposed |
| 17 | Adversarial verification of re-anchored checker patterns before claiming fix complete | orchestrator | proposed |
| 18 | No "fix applied" claim accepted without artifact verification (standing rule — 3rd confirmed instance) | all agents | standing rule (load-bearing) |
| 19 | workflow_dispatch CI runs are excluded from PR status-check rollup; close+reopen required for branch-protection satisfaction | devops-engineer | proposed |
| 20 | Any verification backstop must be placed upstream of (or independently of) the classifier it bounds; downstream placement inherits classifier blind spots | devops-engineer + orchestrator | proposed |
| 21 | Presence of a guard is NOT evidence; a mutation that flips a test from PASS to FAIL is the minimum evidence standard; add at least one defeating input vector per new backstop | orchestrator + devops-engineer | proposed |
| 22 | "Remediations have themselves introduced defects" is the project-level standing warning; every fix must be adversarially verified against at least one input that would defeat a naive re-implementation | all agents | standing rule (load-bearing) |
| 23 | Hand-rolled Markdown parsers cannot be validated against themselves; closing the defect class requires either a real CommonMark/GFM oracle or eliminating the parser | architect | proposed |
| 24 | A conservation law proves totality, not correctness; state explicitly which property a property test constrains and which it does not | orchestrator + all agents | standing rule (load-bearing) |
| 25 | Recognition predicates must fail toward counting/reporting, never toward skipping; a recognition gate whose failure makes an item invisible is the D-039 forbidden pattern in disguise | devops-engineer + orchestrator | standing rule (load-bearing) |
| 26 | Merge-gate controls that accept the verified value as a CLI argument can be satisfied by misuse; prefer gates that derive both sides themselves | devops-engineer | proposed |
| 27 | Do not re-probe a live external system to reconfirm what is already established | orchestrator | standing rule |
| 28 | Docstrings that overclaim safety are worse than no docstring; the honest framing is "NARROWED, not closed" with the unbounded sinks and tracking story named | all agents | proposed |
| 29 | Independent fresh-context adversarial review found every BLOCKING defect in this session; the implementer's own green suite found none of them | orchestrator | observation (load-bearing) |
| 30 | The generator-diff-verification falsifier worked on first use and caught a destructive generator; the operator-endorsed `--check` gate immediately exposed BI-041 — a generator that would have silently deleted ~20+ hand-authored Architecture Module annotations. Standing rule: a generator nobody diffs is a generator nobody should run. | all agents | standing rule (load-bearing) |
| 31 | `[process-gap]` A negative test must exercise the PRODUCTION artifact, not a synthetic stand-in; BI-042 is the D-050→D-057 lesson recurring a fourth time. Selftests 21/22 defined their own regex patterns and proved those could fail while the production bindings used different tautological patterns. A D-040 negative test earns credit only when it drives the same pattern/artifact the production checker uses. | devops-engineer + orchestrator | standing rule (load-bearing) |
| 32 | `[process-gap]` A recognition guard must model what the executor actually does, not what the file text contains; the BLOCKING-1 meta-guard grepped whole-file for a quoted name (proving only "this string appears somewhere") while bash ran 8 of 9 checkers and reported nothing missing. Fixed by deriving the ACTIVE list from the `CHECKS=( ... )` block with comments stripped. | devops-engineer + orchestrator | proposed |
| 33 | Default-unsafe invocation is the write-path equivalent of a predicate that fails toward silence; write mode was gated on LOSSLESSNESS when the binding constraint was CONCURRENCY. Remediated by gating every generator write path behind explicit `--write` opt-in, verified unreachable by a reviewer across 14 argv combinations and a recursive shasum manifest diff. A tool whose no-argument behavior mutates shared state is one keystroke from an incident. | all agents | standing rule (load-bearing) |
| 34 | `[process-gap]` Orchestrator error — a subagent was allowed to override an explicit stop condition; when a dispatch defines a stop condition the subagent may NOT substitute its own judgement, and any escalation to a `--force` variant requires returning for authorization. | orchestrator | standing rule (load-bearing) |
| 35 | Reviewer-flagged APPROVE is not merge authorization; a conditional APPROVE ("merge with eyes open") is an input to the merge decision, not the decision. The orchestrator declined `0ad5c5e` and sent MAJOR-4..7 back; all four were real, and MAJOR-4 was a live silent-coverage hole. | orchestrator | standing rule (load-bearing) |
| 36 | Positive: cherry-pick over rebase after a squash merge; when a stale branch carries commits already present on develop as a squash, rebasing conflicts for no benefit — cherry-pick the single unique commit and resolve only the genuine delta. Reviewer independently confirmed all 36 of develop's selftests survived. | orchestrator | proposed |
| 37 | D-050 mutation-only evidence admitted skip-list entries that D-057 positive-coverage evidence validated; D-057 is necessary AND sufficient for admission. check-counts/check-adr-consistency/check-title-sync all KEEP on positive-coverage evidence (runtime corpus counts). BI-034 closes on D-057, not D-050. | orchestrator | standing rule (load-bearing) |
| 38 | Audit scope under-estimation: "12+ BC files" was actually 34 files / 55 rows (3x); "4 files with EC-NEW-" was actually 5 files. When an audit confirms a prior estimate differs by >50%, the prior was derived from sampling or memory. LESSON: always run the grep to get ground truth before recording a count. | state-manager + orchestrator | proposed |
| 39 | Dead code and over-inclusive-but-correct analysis both require execution-proof, not textual inspection. count_domain_decisions() dead (never called); build_heading_ids() over-inclusive (correct behavior in context). Function names are insufficient to characterize behavior. Call-site inspection or execution-path analysis required. | orchestrator | proposed |
| 40 | PREEMPTIVE ordering vs SERIALIZING ordering — keep-moving principle. D-073 "BI-042 is FIRST" means it jumps to the front of the queue WHEN the lock releases, not that it holds up all other work while the lock is held. When an ordering instruction is ambiguous, resolve in favor of keep-moving. Never idle on a lock you do not hold; find the parallel track. | orchestrator | standing rule (load-bearing) |
| 41 | `[process-gap]` Four consecutive issue magnitudes (BI-023 root cause, BI-023(b) count, BI-042 severity, BI-042 breadth) were misfiled by enumeration-by-reading, and BI-044 was invisible entirely. Every correction came from executing a predicate. Codified as D-082: any quantitative claim in a finding or dispatch MUST come from an EXECUTED predicate, not from reading or counting. | orchestrator + all agents | standing rule (load-bearing) |
| 42 | `[process-gap]` Verification tooling is itself unreliable on first draft: the orchestrator produced three false alarms this session — mutating the first occurrence of a string rather than the matched site; a TOML parser that silently skipped single-quoted `canonical_value` (reporting on 10 of 11 facts without saying so); and leaking `SPEC_LINT_REPO_OVERRIDE` into a test harness, producing a false regression verdict. Each would have dispatched an agent against a phantom. Standing rule: reconcile a verification result against a known baseline before acting on it. | orchestrator | standing rule (load-bearing) |
| 43 | `[process-gap]` A test that constructs its own sound fixture and then attests to production is worse than no test — selftest 22 passed for the entire period during which 26 of 31 production bindings were tautological. Require a teeth-test: restore the defect, confirm the test FAILS. A D-040 negative test earns credit ONLY when it drives the same pattern/artifact the production checker uses. | devops-engineer + orchestrator | standing rule (load-bearing) |
| 44 | An issue can be wrong in BOTH directions at once. BI-042 overstated severity (complete replacement was always caught via `None → DIVERGE`) while understating breadth (26 sites, not 17, because the FACT-1 family of 8 was entirely omitted). Re-derive both axes independently; do not assume an error is one-directional. | orchestrator | standing rule (load-bearing) |
| 45 | An issue's FILED size is not evidence of its real size. BI-040 was filed as 2 bypass members with a candidate one-line remedy; execution measured 54 `splitlines()` + 63 `.strip()` sites across 14 files and a family of 31 divergent codepoints. Two independent methods converging (a reviewer probing GFM found 8; iterating all 1,114,112 codepoints found the same 8) is what justified the closed-under-discovery claim — a single method would not have. Codified as D-086 for WS-4. | orchestrator | standing rule (load-bearing) |
