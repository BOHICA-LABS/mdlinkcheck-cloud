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

## Policy Candidates

| Lesson | Proposed Policy | Scope | Status |
|--------|----------------|-------|--------|
| 2 | Mandatory corpus-wide grep sweep before any count-change declaration (extends S-7.02) | state-manager + all spec-touching agents | proposed |
| 1 | Module-criticality DI-ID audit at each VP-addition burst | architect | proposed |
