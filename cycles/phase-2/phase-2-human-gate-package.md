---
document_type: gate-package
level: ops
version: "1.0"
status: awaiting-operator-ruling
phase: phase-2
producer: vsdd-factory:state-manager
date: 2026-08-10
timestamp: "2026-08-10T00:00:00Z"
inputs:
  - .factory/stories/STORY-INDEX.md
  - .factory/stories/epics.md
  - .factory/stories/dependency-graph.md
  - .factory/stories/sprint-state.yaml
  - .factory/specs/behavioral-contracts/BC-INDEX.md
  - .factory/holdout-scenarios/HS-INDEX.md
  - .factory/cycles/phase-2/wave-schedule.md
---

# Phase-2 Human Gate Package

**Purpose of this document:** The human is being asked to rule on Phase 2 story
decomposition, which completed with a 5-PASS / 1-FAIL gate scorecard and two active
blockers. This is an honest disclosure document, not a persuasion document. Every figure
was verified by the orchestrator via direct execution and is stated verbatim. Where a
decision is required from the operator only, this document says so.

---

## §1 Phase 2 Outcome — Decomposition Summary

| Metric | Value |
|--------|-------|
| Epics | 7 |
| Stories | 24 |
| BC coverage | 66/66 |
| Story points | 152 |
| Acceptance criteria | 323 |
| Waves | 7 |
| Canonical story ID convention | `S-N.MM` |
| Legacy convention (unused) | `STORY-NNN` |
| Adversarial story convergence | CUT per gate #53 |

### Commits (all pushed; `factory-artifacts` == `origin/factory-artifacts`)

| SHA | Description |
|-----|-------------|
| `fdf036f` | Step A — epic decomposition |
| `816d8b8` | Step B — 24 story files, 66/66 BC coverage |
| `c461b72` | Steps C+D — dependency graph, wave schedule, index, sprint state |
| `5413f7e` | Step E — holdout wave wiring + disclosed coverage gap |

---

## §2 Wave Plan

| Wave | Stories | Points | Notes |
|------|---------|--------|-------|
| 1 | S-1.01 | 8 | DEV-11 Run A endpoint; operator stop-vs-continue re-ask |
| 2 | S-1.02 S-1.03 S-3.01 S-3.03 S-5.02 S-6.01 S-7.02 | 42 | |
| 3 | S-1.04 S-2.01 S-6.02 S-7.01 S-7.03 | 26 | |
| 4 | S-2.02 S-2.03 S-3.02 S-4.02 S-5.01 | 31 | |
| 5 | S-3.04 S-4.01 S-5.03 | 21 | |
| 6 | S-4.03 S-5.04 | 21 | |
| 7 | S-7.04 | 3 | |

**Critical path (47 pts):** S-1.01 → S-1.03 → S-2.01 → S-3.02 → S-4.01 → S-4.03 → S-7.04.

---

## §3 Decomposition Gate Scorecard — 5 PASS, 1 FAIL

**Gate verdict: BLOCKED.**

All criteria verified by orchestrator direct execution, independent of agent self-reports.

| # | Criterion | Result | Evidence |
|---|-----------|--------|----------|
| 1 | Every BC traces to ≥1 story | **PASS** | 66/66 in frontmatter and 66/66 with ≥1 AC trace; set equality with BC-INDEX in both directions |
| 2 | No TBD/TODO/placeholder ACs | **PASS** | 323 ACs all with real assertions and named tests; zero unfilled template tokens (`todo!()` is required Red-Gate boilerplate, not a placeholder) |
| 3 | No circular dependencies | **PASS** | Kahn sort places all 24 nodes; 34 edges |
| 4 | Waves respect dependency ordering | **PASS** | 0 stories depend on a story in wave ≥ their own |
| 5 | STORY-INDEX matches story files | **PASS** | 24 rows, 0 mismatches on id/epic/wave/points; sprint-state `blocked_by` == `depends_on` for all 24 |
| 6 | At least one holdout scenario per wave | **FAIL** | See §4 Blocker 1 |

---

## §4 Active Blockers

### §4.1 Blocker 1 — Holdout Wave Coverage (gate criterion 6)

Only waves 2 (HS-007) and 5 (HS-001, HS-004, HS-005, HS-006, HS-008) have an evaluable
holdout. **Waves 1, 3, 4, 6, 7 have none.** A holdout is evaluable only once every BC it
probes is implemented; all six active holdouts are anchor-checking-centric and anchor
resolution completes in waves 4–5. No active holdout probes E-2 (link extraction), E-4
(relative path resolution), E-5 (external URL checking), or E-7 (output/reporting/exit
codes). **Wave 1 — the Run A endpoint — is among the uncovered waves.** Computed
independently by product-owner and orchestrator with identical results; disclosed in
HS-INDEX v1.4. Closing it by authoring new scenarios is NEW WORK, excluded by D-244
closed-world.

**Options:**

- **(a)** Accept and run uncovered wave gates with holdout evaluation skipped, disclosed.
- **(b)** Re-scope criterion 6 to "≥1 holdout per wave where evaluable."
- **(c)** Authorise new holdout scenarios for E-2/E-4/E-5/E-7 as an exception to closed-world.
- **(d)** Leave unfixed and record.

Orchestrator recommends **(b)** plus recording **(c)** in the post-run backlog: it makes the
criterion say what it can actually mean given a pre-existing holdout pool, without weakening
intent or doing excluded work.

---

### §4.2 Blocker 2 — File-Lifecycle Ordering Across Waves (NEW defect class, found by mandatory fresh-context gate audit)

Story File Structure Requirements tables were authored per-story in parallel with no global
file-lifecycle reconciliation, so several stories declare `modify` on files no story has
created yet at that wave. Nothing checks this; gate criterion 4 checks dependency-edge
ordering only. Confirmed by orchestrator across all 24 stories:

**A. Modify BEFORE create (3):**
- `anchor_resolver.rs` — S-4.02 (w4) modifies; created w5 by S-3.04.
- `path_resolver.rs` — S-4.02 (w4) modifies; created w6 by S-4.03.
- `app.rs` — S-6.02 (w3) modifies; created w4 by S-3.02.

**B. Modify in SAME wave as create (1):**
- `cli.rs` — S-7.02 (w2) modifies; created same wave by S-1.02; parallel dispatch race.

**C. Modify with no creator anywhere (1):**
- `crates/mdlinkcheck/tests/integration_tests.rs` — modified by S-2.02; never created.

**D. Dual-create, unadjudicated (3):**
- `anchor_table.rs` created by BOTH S-2.03 and S-3.02 in wave 4 (same-wave collision).
- `url_classifier.rs` created by S-2.01 (w3) and S-5.01 (w4).
- `verdict_tests.rs` created by S-1.02 (w2) and S-7.01 (w3).
  (`fragment.rs` and `verdict.rs` dual-create were previously adjudicated as AMB-001/AMB-004.)

**Severity:** This WILL fail Phase 3 dispatches for the affected stories — a story told to
`modify` a nonexistent file either errors or creates a divergent partial file.

**The S-4.02 case is not mechanically fixable** and needs a decomposition ruling: S-4.03
depends on S-4.02, yet S-4.02 declares modifications to `path_resolver.rs`, which S-4.03
creates. The VP-004 P5/P6 decode-ordering integration tests must be re-homed to the stories
that own those files (P6 → S-3.04, which already implements decode-before-lookup at
creation; P5 → S-4.03), while preserving the D-165 obligation that decode-ordering stays
expressed as an integration test rather than a proof.

**CRITICAL SCOPE FACT: wave 1 is entirely `create` actions, self-contained, with zero
conflicts against any other wave-1 story. Blocker 2 affects waves 2–7 ONLY. The Run A
endpoint is reachable without fixing it.**

**Options:**

- **(a)** Fix all of Blocker 2 now before any Phase 3 dispatch.
- **(b)** Proceed to Phase 3 wave 1 now (unaffected) and fix Blocker 2 during the wave-1
  gate window, before wave 2 dispatches.
- **(c)** Fix only the mechanical subset now (relabel create→modify where an earlier creator
  exists; add the missing edges and wave bumps for `app.rs` and `cli.rs`; assign a creator
  for `integration_tests.rs`) and rule separately on the S-4.02 re-homing.

Orchestrator recommends **(b)**: it preserves the Run A decision point unchanged and does
the repair while wave 1 is in flight, rather than idling.

---

## §5 Findings Register — Recorded, No Work Performed (D-244 Closed-World)

- `BC-2.11.001` postcondition 4 asserts `--ignore` does not affect explicit PATH arguments,
  contradicted by the `[AMB-108]` note on that same line and by `BC-2.11.003` invariant 1
  ("`--ignore` wins over explicit PATH. Always."). Stale text left after the ambiguity was
  resolved. Stories correctly built on `BC-2.11.003`.

- `BC-2.03.002` v1.6 records VP-NONE ×2 with "integration test required in story", while
  VP-INDEX v1.7 line 163 still maps it to VP-019; `BC-2.03.002` appears in VP-INDEX exactly
  once and never in its v1.7 changelog. S-2.02 discloses both readings and carries the
  integration-test obligations; no side was adjudicated.

- **VP-attribution drift, quantified: 9 of 66 BCs disagree across VP-INDEX / BC-file VP
  section / `bc-module-map.md`.** VP-INDEX vs BC-file: BC-2.01.004, BC-2.05.001,
  BC-2.06.001, BC-2.10.005, BC-2.10.006. VP-INDEX vs bc-module-map: BC-2.07.001,
  BC-2.08.001, BC-2.10.005, BC-2.10.006, BC-2.12.001, BC-2.13.001. Six of these are exactly
  the BCs VP-INDEX v1.7's changelog says BI-052 remediated — the remediation updated
  VP-INDEX and never propagated to `bc-module-map.md`.

- **No spec-lint checker reads `bc-module-map.md` at all** (only the `gen-bc-traceability.py`
  generator); four checkers read VP-INDEX but none cross-validates per-BC VP attribution
  between the three artifacts. Routes to the existing BI-058 nine-checker sweep scope.

- The 9-of-66 figure is itself a LOWER BOUND: `BC-2.03.002` is absent from it because its
  VP section says `VP-NONE` while naming "VP-019" in prose, which defeats lexical extraction
  — an instance of L-79.

- `S-4.03` sits at exactly the 13-point ceiling covering 6 BCs; split candidate.

- `BC-2.07.001`, `BC-2.07.002`, `BC-2.07.003` are each co-implemented by multiple E-4
  stories and are only fully satisfied once every contributing story lands.

- `epics.md` labels epics `EPIC-01..EPIC-07` while stories carry template-mandated
  `epic_id: E-1..E-7`; mapping is 1:1 and documented, but the two conventions coexist.

- 6 reserved holdout EC ids (EC-079/093/094/141/147/148) remain unauthored.

---

## §6 Verification Status

spec-lint unchanged at **8 of 9**: `check-ec-injectivity` RED at **exactly 39** by design
per D-246 (a lower bound per D-126); the other eight PASS, including `check-holdout-boundary`
and `check-index-integrity` after the HS-INDEX v1.4 edit. Phase 2 perturbed the frozen spec
corpus not at all — `.factory/specs/` shows zero modifications across all four commits.

---

## §7 Questions for Operator

**Q1 — Blocker 1 ruling:** Which option for holdout wave coverage, and is criterion 6
re-scoped or waived-and-disclosed?

**Q2 — Blocker 2 ruling:** Fix before Phase 3, or proceed to wave 1 (unaffected) and repair
during the wave-1 window? And specifically: approve re-homing the VP-004 P5/P6 integration
tests out of S-4.02 into S-4.03 and S-3.04?

**Q3 — Scope check:** Is repairing Blocker 2 agreed to be in-scope Phase 2 completion (it
is defective Phase 2 output, not frozen-spec defect hunting) rather than a closed-world
violation?

**Q4 — Wave granularity:** 7 waves each carrying a full wave gate (test suite, adversarial
review, holdout eval, demo validation) is expensive for 24 stories. Accept, or consolidate?

**Q5 — Anchor-checking concentration:** KD-001 anchor behaviour lands across waves 2–5 with
its holdouts only evaluable at wave 5. Acceptable, or should anchor work be pulled earlier?

**Q6 — Story ID convention:** Confirm canonical `S-N.MM` and the `EPIC-0N` ↔ `E-N`
coexistence are acceptable.

---

## §8 Operator Ruling

**Decision required from operator.**

### Q1 — Blocker 1: Holdout Wave Coverage

```
Option selected: [ ] (a) accept-uncovered-skip  [ ] (b) re-scope-criterion  [ ] (c) authorise-new-scenarios  [ ] (d) leave-unfixed

Notes: ________________________________________________
```

### Q2 — Blocker 2: File-Lifecycle Ordering

```
Phase 3 gate approach: [ ] (a) fix-all-now  [ ] (b) wave-1-first-repair-in-window  [ ] (c) fix-mechanical-rule-separately

VP-004 P5/P6 re-homing (S-4.02 → S-4.03 / S-3.04): [ ] Approved  [ ] Rejected  [ ] Investigate

Notes: ________________________________________________
```

### Q3 — Blocker 2 Scope

```
Repairing Blocker 2 is: [ ] In-scope Phase 2 completion  [ ] Closed-world violation  [ ] Other: ___________
```

### Q4 — Wave Granularity

```
7-wave plan: [ ] Accept as-is  [ ] Consolidate to _____ waves  [ ] Investigate

Notes: ________________________________________________
```

### Q5 — Anchor-Checking Concentration

```
Anchor work spread waves 2–5, holdouts evaluable wave 5: [ ] Acceptable  [ ] Pull anchor work earlier

Notes: ________________________________________________
```

### Q6 — Story ID Convention

```
Canonical S-N.MM + EPIC-0N/E-N coexistence: [ ] Acceptable  [ ] Requires reconciliation

Notes: ________________________________________________
```

---

```
Verdict: ________________________________________________

Signature: ________________________________________________
Date:      ________________________________________________
```
