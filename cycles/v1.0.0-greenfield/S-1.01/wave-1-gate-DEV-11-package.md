---
document_type: gate-package
level: ops
version: "1.0"
status: ready-for-human-review
producer: vsdd-factory:state-manager
story_id: S-1.01
cycle: v1.0.0-greenfield
gate: DEV-11
wave: 1
head_sha: 0719c3c
convergence_status: ACHIEVED-WITH-DISCLOSED-RESIDUALS
convergence_decision_refs: ["D-254", "D-263"]
standard_criterion_met: false
passes_clean: 0
required_clean_passes: 3
timestamp: "2026-08-11T00:00:00Z"
---

# Wave 1 Gate DEV-11 Package — S-1.01

## HEADLINE: What the Convergence Bar Bought and What It Kept Costing

**This is the operator's explicit instruction: the human should see exactly what the convergence bar bought and what it kept costing.**

Delivered production code: **235 lines** (`crates/mdlinkcheck/src/scanner.rs`) + **181 lines** (`crates/mdlinkcheck-core/src/types.rs`). Against that: **28 adversary passes, 40 commits, 5 fix waves, 47 on-perimeter material findings** (rounds 1–4) plus 5 from pass 28.

| Surface | Commits | Lines changed |
|---|---|---|
| Production code (`crates/`) | 23 | 2,915 |
| Gate / CI / tooling | 12 | 1,993 |
| Evidence / docs | 7 | 1,890 |

The purity gate guarding 416 lines of production code is itself **280 lines**.

---

## Convergence Status

**S-1.01 convergence: ACHIEVED-WITH-DISCLOSED-RESIDUALS** (operator ruling D-263-continuation).

**MANDATORY QUALIFIER:** The standard BC-5.39.001 criterion of three consecutive clean passes was **NEVER met**. `passes_clean` was **0 of 3** across all four confirming rounds and every pass 16–27 returned `MATERIAL_FINDINGS`. Convergence is recorded on an operator-ruled non-standard path (D-254 + D-263), NOT by satisfying the three-clean-pass criterion.

---

## Substance vs Claim-Language Split

### Production Defects: All Found by Pass 15 or Earlier

**Five production defects across the story's entire life**, ALL found by pass 15 or earlier:

1. `require_git(false)` missing (F-B2)
2. Dot-dir whitelist-negation bypass (F-A1)
3. Non-UTF-8 guard fail-open (F-P2-01)
4. Dot-dir guard erasable via `filter_entry` (P14-02/P15-01)
5. `WalkBuilder parents(true)` ancestor-ignore escape (P18-03, KEPT per D-259 with the silence remediated)

Two were HIGH and would have shipped silently.

### Production-Code Review Saturated at Pass 15

Passes 22–28 found ZERO production-code defects. `zero_l1_l5_findings: true` unbroken across nine consecutive passes (19–27) and pass 28.

### Marginal Value Did Not Go to Zero — It MOVED

Those same late passes found **two independently exploitable holes in the ADR-001 enforcement gate** (BI-096 at round 4, P28-01 at pass 28), both confirmed compiling and passing fmt, clippy, all 44 tests and the gate itself. Neither was in production code. Both would have left the purity boundary unenforced for the seven downstream stories that depend on it.

**Per-pass material counts:** pass 16→7, 17→5, 18→5, 19→3, 20→2, 21→2, 22→2, 23→1, 24→2, 25→6, 26→7, 27→5, 28→1.

---

## Process Findings — Weight These Above Any Individual Defect

1. **Unanimous multi-agent consensus is not evidence.** Three independent round-4 passes converged on a FALSE inference (that the `98a4f15..HEAD` delta was not docs-only, that the CI attestation therefore failed, and that `scripts/purity-check.sh` had never run in CI). One `git log --diff-filter=A` refuted it. Acting on the consensus would have driven a fix wave chasing a non-existent gap.

2. **Agent completion reports did not surface real defects; execution did.** Four of seven round-4 fixes needed a correction round, and every one was caught by orchestrator verification rather than by the reporting agent.

3. **Never derive a metric from a cancelled run.** The published mutation kill counts were wrong twice over — FAIL-line double-counting AND fail-fast cancellation. All three adversary passes then "corrected" them to figures that were ALSO wrong (M3 true 7 vs their 5; M4 true 2 vs their 1). Only `--no-fail-fast` execution settled it.

4. **The self-invalidating-attestation class recurred five times** because instance fixes were specified for a structural problem. This is an orchestrator process failure and is recorded as such (see lessons L-102, L-103; scoped-review-pass-28-and-fix-wave-5.md §The Self-Invalidating-Attestation Defect Class).

5. **A collapsed duplicate gate inherits none of the review history of what it replaced.** Extracting the detector to one file closed BI-090 by construction and simultaneously shipped BI-096.

---

## Human Decision List

Carry forward every open item and add the new ones:

### Carry-Forward Items

- **D-252a:** Dot-FILE exclusion acknowledgement
- **BI-067:** LICENSE file creation and licence choice
- **BI-065:** `clap` 4.6.6 and `unicode-normalization` 0.1.25 parity still open
- **BI-066 / D-258:** `Link` corpus precedence
- **BI-068 / P10-01:** Hardlink/inode aliasing intent
- **Holdout coverage:** VACUOUSLY SATISFIED (disclosed, not a failure)
- **D-043:** CI tests `macos-latest` ONLY — no Linux coverage
- **BI-106 / AC-006 / AC-010:** Clause-(ii) untested and deferred
- **D-253:** MSRV-1.88 divergence and its mis-citation to D-205 in two config files (BI-107, accepted-disclosed)
- **D-254:** Frozen-perimeter convergence definition itself (non-standard path)
- **D-260:** Tool-pin deviation and the four absent spec-named config files
- **BI-069:** `verify-evidence-figures` will show RED on the PR — accepted and disclosed. Must NOT be satisfied by fabricating figures (BI-063 class)
- **BI-086:** VP-017 undisclosed divergence
- **D-259 / F-A3:** `parents(true)` accepted residual risk
- **BI-089:** Fixture prefix intent
- **BI-095:** Backstop mutation survivor

### New Items (This Gate)

- **P28-01 — Live gate hole, disclosed-not-fixed.** Crate-root aliasing of `std` plus a renamed leaf escapes the purity gate. Extending purity coverage is an **operator decision**.
- **P28-04:** Asymmetric Path-method rationale (`.metadata()` / `.canonicalize()` detected; `.exists()`/`.is_dir()`/`.is_file()` excluded for the same collision-hazard reason)
- **P28-05:** Third-party I/O crate class (e.g. `walkdir::WalkDir::new(".")`) undetected by the purity gate
- **`pr-manager-completion-guard` hook has no representable terminal state for package-only mode.** The hook requires 9 `STEP_COMPLETE` markers at `status=ok` but steps 3 and 8 require PR creation and merge, which D-120/BI-062 prohibit. `pr-manager` correctly refused to fabricate them across three separate runs and no hook was edited (D-158/D-182/D-231). This needs an operator decision, not a workaround.
- **Stop-vs-continue decision required.** See Cycle-Closing Checklist status below.

---

## Cycle-Closing Checklist Status

Process-gap lessons L-93, L-94, L-95, L-96 (from round 3) and L-97, L-98, L-99 (round 4) plus the new ones from pass 28 (L-101, L-102, L-103, L-104) each require either a follow-up story against a self-improvement epic or a justified deferral entry.

**That disposition has NOT been made. Do not invent story IDs.** Route to the operator at this gate.

---

## Artifact Checklist

| Artifact | Location | Status |
|---|---|---|
| Scoped review pass 28 + fix wave 5 record | `.factory/cycles/v1.0.0-greenfield/S-1.01/scoped-review-pass-28-and-fix-wave-5.md` | WRITTEN |
| Convergence state JSON (pass 28, fix wave 5, convergence basis) | `.factory/cycles/v1.0.0-greenfield/S-1.01/adversary-convergence-state.json` | WRITTEN |
| Lessons L-101..L-104 | `.factory/cycles/v1.0.0-greenfield/lessons.md` | WRITTEN |
| Wave-1 gate DEV-11 package | `.factory/cycles/v1.0.0-greenfield/S-1.01/wave-1-gate-DEV-11-package.md` | THIS FILE |
| STATE.md | `.factory/STATE.md` | **NOT BUMPED** (D-243, CI-063) |
