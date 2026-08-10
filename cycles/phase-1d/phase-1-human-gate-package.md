---
document_type: gate-package
level: ops
version: "1.1"
status: awaiting-human-ratification
phase: phase-1d
producer: vsdd-factory:technical-writer
date: 2026-08-10
timestamp: "2026-08-10T18:00:00Z"
gate: 57
title: "Phase-1 Human Gate Package — Spec ratification WITH disclosed defects"
---

# Phase-1 Human Gate Package

**Purpose of this document:** The human is being asked to ratify the Phase-1 spec package
WITH disclosed defects, under operator ruling (gate #53, reaffirmed gate #57). This is an
honest disclosure document, not a persuasion document. Every figure was verified by the
orchestrator via direct execution this session and is stated verbatim. Where evidence is
absent, this document says so.

---

## §1 What is Being Ratified — Spec Package Manifest

| Artifact | State |
|----------|-------|
| PRD | v1.15 |
| Behavioral Contracts | 66 BCs |
| Verification Properties | 26 VPs |
| Domain Invariants | 13 DIs |
| Architecture Decision Records | 8 ADRs |
| Policies | 19 policies |
| EC registry | EC-001..EC-214 |
| Holdout pool | 12 scenarios (HS-001..HS-008; HS-002 and HS-003 retired) |
| Total spec files | 134 |
| Product brief | v1.1 (approved) |
| Domain spec | L2-INDEX v1.9 |
| `develop` HEAD | `f81f412` |
| Frozen perimeter | `a79de7e841c705a499f7aec634c4894b3097764e` |

Six holdout EC IDs remain reserved-but-not-yet-authored: EC-079, EC-093, EC-094, EC-141,
EC-147, EC-148.

---

## §2 Convergence Status

**0 of 3 required clean adversarial passes.**

The convergence trajectory is: 0 → 32 → 34 → 39 → 37 → 259 → 273–275. This trajectory
is UNCHANGED this session. No adversary pass ran this session.

The convergence phase was **TRUNCATED BY OPERATOR RULING** (gate #53, reaffirmed gate #57),
not completed. The following items were CUT to a post-run backlog:

- The BI-058 nine-checker sweep
- The BI-063 semantic claim-audit
- Adversary pass 8
- Adversary passes 9 and 10
- The required 3-clean-pass streak

**The human is being asked to ratify a spec that did NOT reach its own convergence bar, by
deliberate ruling.**

Pass 7 was the last pass executed and the first genuine full-perimeter pass (prior passes
read only 55/66 BCs and 21/26 VPs; pass 7 read the full perimeter). Pass-7 totals are
reported as a **range 273–275** (CRITICAL: 44 self-declared vs 45 predicate-parsed) per
PG-012 taxonomy-incomparability. A hand recount is PROHIBITED (D-082).

---

## §3 Known-Defect Register

### §3.1 Open Blocking Issues (20)

**Flag: BI-023 and BI-027 are carried OPEN, but their own resolution text reads as
CLOSED** — this is a status ambiguity requiring human adjudication (see §7 Q6).

**Flag: BI-014 has no register row anywhere** — a hole in the BI ID space. Its existence
is inferred from the surrounding numbering; no defect description is available.

Rows marked (SESSION-HANDOFF ONLY) do not appear in STATE.md and exist only as pending
verbatim text in SESSION-HANDOFF §RESUME SNAPSHOT D-243. STATE.md has not been updated
due to D-243 classifier block; see §3.8.

| ID | Defect | Severity | Why It Is Open / Reason | Owner |
|----|--------|----------|------------------------|-------|
| BI-002 | phase-1d not converged: 0 of 3 clean passes; pass 7 complete (273–275 findings; first genuine full-perimeter pass); perimeter CLOSED; root causes SPEC-TOPOLOGY (D-035) + 4 unguarded axes (BI-024) + structural checker bypasses (BI-023) | HIGH | Convergence truncated by gate #53; passes 8/9/10 and 3-clean-streak cut to post-run backlog | orchestrator |
| BI-007 | VP-026 is SPECIFIED but UNIMPLEMENTED — no Rust workspace exists yet (Phase 3 not started). FM-002 risk until Phase 3 implements the differential proptest. | HIGH | Phase 3 has not started; VP-026 requires implementation work not spec work | implementer |
| BI-010 | VP-025 authored against non-existent API types. Harness cannot compile. Architect rewrote VP-025; INC-MAP-001 SPEC-RESOLVED/IMPL-PENDING (D-048). | CRITICAL | INC-MAP-001 closes only when Phase 3 implements the required types | architect |
| BI-017 | Phase 3 CI obligation: NO perf-gate/benchmark job exists. Both NFR-008 and NFR-002 benchmark jobs MUST run on `macos-latest` when created in Phase 3. Baselines must be established AFTER the wall-time boundary at 2026-08-08T22:55:24Z (D-127). | MEDIUM | Phase 3 not started; job cannot be created until then | devops-engineer |
| BI-021 | `check-canonical-facts.py` — from a real linked worktree (`.git` is a pointer file) the new `.git` boundary stop halts the walk before reaching main checkout's `.factory/`, exits 1 with clearer message. `SPEC_LINT_REPO_OVERRIDE` is the supported path. | LOW | Residual behavior documented; BI-043 closed (BI-040 merged); all 15 checkers/generators now share one resolver; the specific worktree refusal behavior is the remaining edge | devops-engineer |
| BI-022 | MINOR: `rustup toolchain install nightly` in `fuzz-smoke` job still UNPINNED. Recommend pinning nightly date before Phase 6. | LOW | Pin not yet applied; deferred to pre-Phase 6 | devops-engineer |
| BI-023 | SKIP LIST UNSOUND — **STATUS AMBIGUOUS (see flag above).** Resolution text claims "check-placeholders=0; D-077 CLEAR. Full spec-lint GREEN (9/9)." Direct execution this session contradicts the 9/9 claim (3 FAILs found). Direct execution is treated as authoritative. Root defects: (a) check-placeholders structural bypasses via em-dash; (b) check-id-resolution skip of non-conforming shapes — both addressed by prior PRs. The 9/9 GREEN claim is FALSE per direct execution. | HIGH | Open because its own resolution text's 9/9 claim is contradicted by direct execution; requires human adjudication of status | devops-engineer |
| BI-024 | FOUR UNGUARDED AXES: (A) VP proof-method/tool mismatch BC body vs VP-INDEX (14+ instances, highest-leverage); (B) quoted-excerpt fabrication (~40% rate, POLICY 5 lint_hook null); (C) symbols in rust code fences + 4 undefined types; (D) ~10 stale discharged directives causing harmful story-writer guidance. | HIGH | Mechanical BC-VP-INDEX join, substring-presence check, code-fence symbol resolver, and machine-checkable directive references all unimplemented; no PR has been merged to address these axes | devops-engineer |
| BI-027 | POLICY 5 QUOTED-EXCERPT FABRICATION — **STATUS AMBIGUOUS (see flag above).** Resolution text claims WS-4 Shards A–E COMPLETE, 0 FABRICATED remain, 41/132 corrected (31.1% rate). Resolution text reads as CLOSED. Carried OPEN in the STATE.md table; reason for keeping it open is not explicitly stated. | HIGH | Open because the STATE.md table has not been updated to show closure; requires human adjudication of status | product-owner |
| BI-028 | VP CODE-FENCE SYMBOL VALIDATION + FOUR UNDEFINED TYPES — symbols in VP Rust harnesses that resolve to nothing. Four types with NO definition anywhere: `PathVerdict`, `FailureReason`, `IoError`, `AllowPrefix`. All five VP-007 harnesses fail to compile. | HIGH | No architectural fix applied; VP-007 must be rewritten before Phase-3; symbol-extraction linter unimplemented | architect |
| BI-037 | F-15 MINOR / PR #3 — fail-open in `run_suppression_guard`. Reproduced in isolation but UNREACHABLE via the real entry point (guard 1 exits 2 first). Load-bearing guard ordering MUST be preserved in any refactor. | LOW | Guard ordering dependency must be explicitly documented; no code change implemented | devops-engineer |
| BI-039 | `gh pr review --request-changes` IMPOSSIBLE on any PR in this repo: GitHub returns GraphQL "Can not request changes on your own pull request" (same root cause as D-021, all PRs authored by `drbothen`). Two pr-reviewer agents misdiagnosed as permission-classifier denial. Hook `validate-pr-review-posted` UNSATISFIABLE via `gh pr review` for every PR in this repo. | MEDIUM | Structural impossibility in GitHub; workaround (`gh pr comment`) not yet codified in hook logic | devops-engineer |
| BI-041 | `gen-bc-traceability.py` write mode LOSSY: regenerates BC Architecture Module row and DESTROYS hand-authored annotations (INC-MAP-002, INC-MAP-003, INC-MAP-004 destroyed on prior run). MITIGATION LANDED: Gate 1 concurrency guard + Gate 2 (`--write` refuses unconditionally). RESOLUTION requires adjudication of annotation handling. | HIGH | DO NOT enable write mode until annotation handling is adjudicated | architect |
| BI-052 | FALSE-GREEN VP ATTRIBUTION CLASS — BCs naming Kani/proptest proofs for properties the cited VP body does not assert. 23 items adjudicated; 19 ATTRIBUTION-FALSE, 2 UNFALSIFIABLE, 1 HARNESS-BROKEN. 21 ADJUDICATED-ACCEPTED-NOT-FIXED. See §3.2 for full residual risk. | CRITICAL | Accepted under gate #57 D-205/D-214 build-sufficiency ruling; 21 items not fixed, only adjudicated | architect + product-owner |
| BI-058 | D-132 AUDIT — SUPPRESSION GUARD INERT + FIVE FALSE-GREEN CHECKERS. `run_suppression_guard` Pass-1 scans 15 checkers/generators but zero trip either pattern; Pass-2 (`COMPLETENESS_PATTERN`) never executes on real checkers. False-green checkers: (1) check-placeholders — 55 raw matches 100% suppressed, tautological assertion; (2) check-id-resolution — 7 files/1,785 lines zero-validated; (3) check-holdout-boundary — pre-filter is no-op; (4) check-counts — 2 documented checks are no-ops, 3 functions dead code; (5) check-index-integrity — 61 of 76 HS lines land in unbounded prose sink discarded before asserting. Scope extended per D-169/D-183. | HIGH | Nine-checker sweep CUT to post-run backlog by gate #53; prerequisite to pass 8 | devops-engineer |
| BI-060 | `validate-pr-review-posted` HOOK — FOUR STRUCTURAL DEFECTS: (a) UNSATISFIABLE — demands `gh pr review`, structurally impossible on self-authored PRs; (b) ACTIVELY INSTRUCTS AGENTS TOWARD SELF-APPROVAL; (c) FALSE NEGATIVE ON CYCLE-KEYED FILENAMES (matches literal `pr-review.md` not `pr-review-cycleN.md`); (d) MACHINE-UNREADABLE BLOCK STATE (`block_reason=""` while `block_intent=true`). Plus AGENCY-vs-IDENTITY gap (D-172). | HIGH | Operator ruling: do not modify mid-run; route around by documented exception only (D-158/D-182) | devops-engineer |
| CI-063 | PROCESS-GAP: Recurring auto-mode classifier friction on `scripts/spec-lint/**`. Operations blocked: `git add` on checker files ×3, `git pull` ×1, running selftests/checkers on the branch. Root cause 1 — authorization relayed mid-session refused; authorization in initial spawn prompt accepted. ~1,027s direct wall time (~9.7% of session). Root cause 2 — `validate-pr-review-posted` demands `gh pr review` which is structurally impossible (BI-039). Burst-38: zero denials — initial-spawn-prompt mitigation confirmed effective. | MEDIUM | No structural control change; mitigation documented; CI-063 wording revision CUT to post-run backlog by gate #53 | orchestrator |
| BI-062 | **`pr-manager-completion-guard` HOOK — MERGE COERCION.** Demanded the full 9-step PR lifecycle INCLUDING MERGE, asserting `AUTHORIZE_MERGE=yes per dispatch convention`, on dispatches whose prompts withheld merge authorization in verbatim terms — the hook MANUFACTURES an authorization it was never granted. Fired **eight times** this session, including while PR #13 carried an OPEN REQUEST_CHANGES verdict and a live false green. Every agent REFUSED and recorded, on two independent grounds: operator task-scope, and the review-convergence gate. **Categorically more severe than BI-060's verdict-inversion coercion: inverting a verdict falsifies a RECORD, whereas this would have landed unreviewed false-green code on `develop`.** SECOND-ORDER HARM: three of four pr-manager returns omitted the task outcome, twice implying failure where the operation had succeeded. | HIGH | SESSION-HANDOFF ONLY — NOT YET IN STATE.md. Operator ruling by precedent (D-158/D-182/D-231): record and route around by documented exception; NO mid-run hook edit. Carried to pre-wave-1 checkpoint. Phase-2 will run many PRs while this hook remains live and unrepaired. | devops-engineer |
| BI-063 | **SEMANTIC CLAIM-AUDIT GAP.** `scripts/verify-evidence-figures.py:1164` asserts "`doc_value` must be non-None, so a check that found nothing in the document cannot reach a registered state" — the SAME false claim M-4/M4-2 exist to eliminate, disproven three times by the binding probe. Survived cycles 3, 4, and 5 plus orchestrator verification because every audit was LEXICAL while the claim is SEMANTIC. Impact bounded: comment only, no behavioural effect. Implication: all nine checkers carry invariant-asserting comments written across many sessions; none has been semantically audited; D-141's instruments are all behavioural and do not cover the claim surface. | MEDIUM | SESSION-HANDOFF ONLY — NOT YET IN STATE.md. ROUTED into BI-058 nine-checker sweep scope. Operator decision PENDING: whether semantic claim-audit belongs inside the sweep or as separate work. | devops-engineer |
| BI-064 | **`verify-state-timestamp-refresh` HOOK — UNSATISFIABLE FOR MULTI-EDIT STATE BURSTS.** Requires every `Edit` to leave `timestamp:` (line 7) newer than pre-edit. Because `Edit` needs one contiguous `old_string`, any Decisions-Log (~line 185) or Blocking-Issues (~line 222) change demands a ~180–215-line SPANNING edit; sequential small edits are impossible because edit #2 cannot re-advance the timestamp. The hook FORCES the exact large-rewrite shape L-77 forbids — the shape traced to all three state-manager stalls (Bursts 39/42/44, ~94 min each, with false-COMPLETE writes). Hook NOT modified, disabled, or weakened; operator authorized exception was then blocked by the classifier (D-243). | MEDIUM | SESSION-HANDOFF ONLY — NOT YET IN STATE.md. Repair is post-run engine work: make the timestamp requirement burst-scoped rather than per-Edit, or have the hook advance the timestamp itself. Do NOT edit mid-run (D-158/D-182/D-231). | devops-engineer |

---

### §3.2 BI-052 False-Green VP Attribution — 23 Items Adjudicated

Source ledger: `.factory/cycles/phase-1d/bi-052-adjudication.md`

**Verdict tally:**

| Verdict | Count |
|---------|-------|
| ATTRIBUTION-FALSE | 19 |
| UNFALSIFIABLE | 2 |
| HARNESS-BROKEN | 1 |
| ATTRIBUTION-OK | 0 |
| **Total** | **23** |

**Disposition tally:**

| Disposition | Count |
|-------------|-------|
| FIXED (already corrected on disk in prior BC versions) | 2 |
| ADJUDICATED-ACCEPTED-NOT-FIXED | 21 |

The two FIXED items are: ADJ-SS07-D-1 (BC-2.07.003 proof-method label corrected in v1.4)
and ADJ-SS07-D-2 (BC-2.14.002 Precondition 3 removed in v1.3). Both corrections are live
on disk; no residual risk from either.

Scope note: Items 1–17 are the 17 BI-052 adversary-pass-7 instances. Items 18–21 are the
4 BI-053 VP propagation debt items (D-165), same class. Items 22–23 are additive scope
from adjudication-ss07-ss14.md. Items P7-S9-001, P7-S2-013, and P7-S7-001 all describe
the same physical rows (BC-2.06.001:111-112); recorded separately because they carry
distinct adversary finding IDs. Items P7-S3-003 and BI-053-A share the same root defect
(BC-2.07.004 VP-004 row 2).

**Also record:** VP-010 is v1.0 with `modified: []` — the D-019 fallback conflict has
never been reviewed by any prior adversary pass. `verification-coverage-matrix.md` asserts
**13/13 DIs covered, which is materially false** given finding P7-S7-004 (VP-INDEX and
coverage matrix both report DI-004 fully covered while the indented-code context and the
entire anchor_table side have zero harness coverage).

---

#### What a reader of the BCs would wrongly believe is proven

_The following five claims are the Residual Risk Summary reproduced in full from_
_`.factory/cycles/phase-1d/bi-052-adjudication.md`. This is the single most important_
_content in this document._

**1. Slug correctness (BC-2.06.001, BC-2.06.002 — items P7-S9-001, P7-S2-013, P7-S7-001, P7-S2-018, P7-S7-002).** The spec records Kani P0 proofs for space-to-hyphen transformation, Unicode word character preservation, and correct slug output for collision triples. In reality: VP-002 is a tautology — f(x)==f(x) for any pure function, so no compiling implementation can fail it — and VP-003 proves only that two slugs are not equal, explicitly incapable of detecting the 1-based vs 0-based counter off-by-one. Blast radius: the product's stated primary differentiator (the AI-and-Automation double-hyphen case) and slug de-dup counter correctness both ship with no formal verification, behind a BC reporting P0 green. FM-001 and FM-002, the two highest-risk slug defects in the corpus, are invisible to the proof layer.

**2. VP-007 harness is inoperable (BC-2.10.002, BC-2.10.005, BC-2.10.006 — item P7-S7-003).** Three BCs record Kani P0 proofs for dns-failure and tls-error verdict routing. The VP-007 harness references five types and functions absent from the declared API, with the network-error encoding explicitly marked TBD by implementer. Blast radius: if the network-error harnesses are silently dropped in Phase-6 (the most likely outcome when the API is locked), the DI-010 carve-outs for dns-failure and tls-error go unverified. A CI environment without DNS egress produces broken(dns-failure) for every external URL, generating the false-positive class the product brief names as its primary problem. This remains invisible to formal verification.

**3. Percent-decode step is unproven (BC-2.07.004, BC-2.08.001, BC-2.08.003 — items P7-S3-003, BI-053-A, BI-053-B, BI-053-D).** VP-004 (Kani P0) proves only that the fragment-split function splits on literal # and not on %23. The subsequent decode step — which turns My%20File.md into My File.md and #caf%C3%A9 into the accented form before anchor lookup — has no Kani proof in any VP. Blast radius: an implementation that correctly splits but omits decode passes all named P0 Kani proofs; TV-157 (now live and visible) and TV-025 would catch it at integration, but the formal layer is silent. The Sphinx bug root cause is precisely this omission.

**4. Allow-list bypass path and double-star glob are unverified (BC-2.09.002, BC-2.11.001, BC-2.11.002 — items P7-S4-005, P7-S5-006, P7-S5-007).** VP-010's property statement negates CAP-011's required raw-string fallback for malformed URLs. VP-016 uses a literal-filename fixture, never a `**` pattern. Blast radius: the --allow security boundary is unverified for the malformed-URL case; the bypass risk is not detectable by the named VP. The `**` glob dialect — the most common --ignore operational pattern — is untested by any named VP.

**5. Multiple attribution errors in less critical properties (items P7-S2-005, P7-S3-002, P7-S4-004, P7-S5-004, P7-S5-005, P7-S7-004, BI-053-C).** Reference-definition resolution, dot-dot path normalization, same-file anchor-only lookup, JSON validity, output suppression, field order, and the `**` glob dialect are all described as verified by named VPs whose bodies prove something else. None represents a safety or security boundary, but together they mean that the acceptance test suite written from BC bodies alone will systematically miss the behaviors each VP claims to cover.

**Why this is tolerable at Phase-1:** No implementation exists. The defects are in spec artifacts that function as design blueprints. The blast radius described above is the consequence of shipping the current spec to Phase-3 implementation without correction; it is not a consequence of the Phase-1 gate passing. The risks are most acute for items 2 and 3 (VP-007 API mismatch and slug tautology), which require active VP redesign before Phase-6, not before Phase-1.

---

### §3.3 Adjudicated-Accepted, Not Fixed — Verifier Tooling (18)

**Scope boundary: every finding in PR #13 was verifier TOOLING, never spec CONTENT.**
None of the 18 findings below concerns a BC, VP, or spec artifact. They describe defects
in `scripts/verify-evidence-figures.py`, the CI harness, and the selftest suite.

Note: A-12 and A-2 were recorded as SECTION MOVES (MUST-FIX → accepted). A-2's cycle-3
rationale was **falsified and corrected** at cycle-4 — an accepted finding whose stated
reason later proved wrong; the finding remained accepted on independent grounds.

Source: `.factory/code-delivery/VERIFIER-HARDENING-SWEEP-STEP0/pr-review-cycle4.md` §4
(A-1..A-14) and `pr-review-cycle5.md` §Guard 1 Section B (A5-1..A5-4).

**Cycle-4 findings (14):**

| ID | Finding | Acceptance Reason | Adjudicator |
|----|---------|------------------|-------------|
| A-1 | The `verify-evidence-figures` job conclusion is permanently `failure`. Without a token, `check8` can never authenticate; exit 5 is guaranteed on every PR. Channel can signal failure but can never signal success; cannot distinguish PARTIAL-all-passed from FAIL-figures-mismatched. | No green is produced, so no green can be mistrusted. Operator ruling D-203/D-231: accept as-is; advisory job permanently red. | Operator, D-203/D-231 |
| A-2 | `_strip_prev_col` latent shapes B (escaped/code-span pipe shifts `col_idx`), E (`col_idx` leaks into glued adjacent table), F2 (decoy label row satisfies both guards while real table goes unfiltered). | Still absent from real documents at `280bcd3`. M4-1 content-pinning fix closes all three for free — this time genuinely (cycle-3's stated rationale that "the M-2 content assertion closes all three" was **falsified and corrected** at cycle-4). SECTION MOVE: MUST-FIX → accepted. | Reviewer, D-214 |
| A-3 | `MIN_RC_EC_COUNT=5`, `MIN_LEDGER_COUNT=3`, `MIN_CMP_COUNT=9`, `MIN_DIV_COUNT=9`, `MIN_ADJ_COUNT=8` are literals with 1–6 sites of slack against observed counts, and do not tighten as documents grow. | Deleting a restatement site removes a cross-check but introduces no wrong figure; every surviving site is still compared. Fail-safe direction. | Reviewer, D-214 |
| A-4 | `50/50` (AC-007) is not derived by the verifier from a live run; `check1` validates only the nine-checker `99/99`. | Not verifier-derived, but provenance-verified against real git objects by `check7` in CI, and independently reproduced by reviewer. `test-vef.py` byte-identical between `7944201` and `280bcd3`. | Reviewer, D-214 |
| A-5 | R1 residual — `if not _TEST_MODE and _expected_stamp_sha7 is None: fail(...)` has a fail path unreachable under the harness, since `_TEST_MODE` is always true in tests. | R1 is the sole backstop for `STAMPED` being emptied; correctness rests on cycle-3's inspection. A test would need a `_VEF_TEST_STAMPED_EMPTY` hook — polish. | Reviewer, D-214 (carried) |
| A-6 | `anchor_check(key: str, …)` still accepts a `key` parameter its body never uses (`:204`). | Cosmetic. The live trap it represented is now disclosed by the corrected `record_comparison` docstring. | Reviewer, D-205 |
| A-7 | The ADR novel-spelling scans read raw `docs` while the EI scans read `docs_no_prev`, so the filters affect only the EI side. | Asymmetric but fail-closed in the ADR direction: historical rc/ec text left in `docs` fails loudly. Now bounded per commit `280bcd3`. | Reviewer, D-214 |
| A-8 | Test-quality gloss: T39 only guards trailing-word re-narrowing; T41's mutant kill-set duplicates T35's; T48 structurally equivalent to T07 with stated target no longer existing; T47's docstring names the `else:` branch while injected values take the `if _wrong:` branch. | Redundancy and stale docstrings, not coverage loss. All four now carry `expect_label` pins, which strictly improves them. | Reviewer, D-205 gloss |
| A-9 | The same head yields two runs — a `push` run and a `pull_request` run — and `gh pr checks 13` shows both under one name. | Correct behaviour of the `event_name == 'pull_request'` guard on the verifier job. Worth flagging for the deferred required-checks flip, where a `skipping` entry could be misread as non-failing. | Reviewer; flip deferred, out of scope |
| A-10 | Diff size far over the 500-line threshold; grown again at `eae146a..280bcd3` (244 insertions / 97 deletions across 9 files, on top of ~3,400 insertions). | Justified and verified: fix round is 179 lines of test suite, 78 lines of verifier (mostly comments), 55 lines of CI, and re-stamped evidence. | Reviewer, D-214 |
| A-11 | L-71 ordering race — `pr-description.md` lives on `factory-artifacts` and must be pushed before the CI run starts. | Process hazard, not a code defect. `REFUSED-on-pull_request → exit 1` mapping makes it loud rather than silently green. | Reviewer, D-214 |
| A-12 | T32 still runs no clean case, so the shipped banner `50/50 tests verified (each proved clean-pass + defect-fail)` is literally false for 1 of 50. T32 is hand-rolled, calls `env_t.run()` exactly once with the defect applied. SECTION MOVE: cycle-3 M-3 sub-item, cycle-4 MUST-FIX → accepted. | Defect direction is proven for T32; clean direction for the shared fixture proven 49 times over by other tests. A 1-in-50 overstatement with no false-green consequence. | Reviewer, D-214/D-205 |
| A-13 | M-2 content assertion has ZERO test coverage. Mutant N1 (entire `filter-strip/live-figure-in-removed` block deleted) returned `PASS 50/50`, exit 0. The cycle's headline fix can be deleted without a single test noticing. | Assertion is live and does work — probe A fired it three times on real documents. Latent regression risk, not a live false green. Becomes largely moot once M4-1 is fixed, as the correct content-pinning fix needs its own paired test. | Reviewer, D-214 |
| A-14 | The `vef-selftest` job conclusion is `success` on exit 5 (PARTIAL). In CI the suite prints `PASS 48/50 tests verified (2 loud-skip)` and `Exit 5 (PARTIAL)`, but the wrapper maps `5)` to echo with no non-zero exit — so a check-status reader sees a green tick for a PARTIAL run. | Tightly bounded and honestly labelled: only T17/T18 can loud-skip, gated purely on `gh` availability. Step name and log body both say PARTIAL. T17/T18 single-source-of-truth extraction asserts at import time, so a drifted field site crashes the whole suite rather than skipping quietly. Verifies 48 real tests. | Reviewer, D-214 |

**Cycle-5 findings (4):**

| ID | Severity | Finding | Acceptance Reason | Adjudicator |
|----|----------|---------|-----------------|-------------|
| A5-1 | suggestion | ev pin is set-MEMBERSHIP, not multiset/position equality. `prev_lines` count guard (`==2`) + `_pl in _EV_PREV_HISTORICAL` are both satisfied by two copies of the same whitelist member. Probe R6: replacing the EI baseline line with a duplicate of the ADR baseline line → `rc=0`. One baseline declaration is silently deleted. | No wrong figure is asserted — content is deleted, not falsified; per-line claim at `pr-description.md:206` remains TRUE. Known class (cycle-3 M-2 "validated by counting"). Cheap future fix: `set(prev_lines) == _EV_PREV_HISTORICAL`. | pr-reviewer (cycle-5), D-214 |
| A5-2 | suggestion | Pins bound CONTENT but not CARDINALITY or POSITION of stripped spans. Only `rows == 0` fails; extra whitelisted stripped cells are unbounded (real doc: `rows: 3`; R1 shape: `rows: 4`, still `rc=0`). | Hideable content is restricted to the 3 historical strings, so no attacker-chosen figure can hide; the residual re-presents a correct-historical string in a misleading position. Same class as A5-1. | pr-reviewer (cycle-5), D-214 |
| A5-3 | nit | `_strip_prev_col` docstring now carries TWO conflicting `Returns` paragraphs. `:300` still says "Returns (filtered_text, stats)" (2-tuple); `:312`, added by this fix, says "(filtered_text, stats, stripped_cells)". The first is stale. | Documentation inaccuracy about a signature, not a guarantee claim; the correct form is present immediately below it. | pr-reviewer (cycle-5), D-214 |
| A5-4 | nit | `scripts/spec-lint/selftest/run-selftests.sh:9` — "cannot satisfy (b) unless the injected defect is actually detected" is imprecise on ATTRIBUTION. Defect-fail direction pins only `exit != 0`; a crash would also satisfy it. | The claim's subject is vacuity, and vacuity is structurally impossible. Mis-attribution is a distinct class, already adjudicated in cycle-3 M-3; the coverage bound is disclosed on `:12-13`. Claim judged ACCURATE as worded. | pr-reviewer (cycle-5), D-214 |

---

### §3.4 Three Disclosed Verifier Holes Live on `develop`

These are accepted and disclosed per D-214, NOT closed. Quoted verbatim from
SESSION-HANDOFF §THREE DISCLOSED VERIFIER HOLES ON `develop`:

> **(a)** the 11-key required-check gate is satisfiable with ZERO comparisons — any non-`None` `doc_value`, including `[] {} "" 0 False () set() 0.0 b'' 0j " "`; only literal `None` is rejected; safety rests on per-site hand-written `fail()` calls and a per-site audit IS required. **(b)** An ADDED span whose stripped content byte-matches a whitelist member evades the positive pin, as does a DUPLICATED ev line; the pin covers mutation of existing spans, not addition. **(c)** M-1's prose-figure inversion is DEFERRED — closing it means flagging any integer inside an EI/ADR context window that is not a live value, not inside a covered pattern span, and not whitelisted.

---

### §3.5 Spec-Lint: 51 Live Violations

Verified by direct execution of all 9 checkers this session:

| Checker | Result | Details |
|---------|--------|---------|
| check-canonical-facts.py | PASS | |
| check-counts.py | PASS | 37/37 |
| check-id-resolution.py | PASS | |
| check-index-integrity.py | PASS | 80 checks |
| check-placeholders.py | PASS | |
| check-title-sync.py | PASS | |
| check-adr-consistency.py | **FAIL** | **9 violations** |
| check-ec-injectivity.py | **FAIL** | **42 divergences (LOWER BOUND per D-126)** |
| check-holdout-boundary.py | **PASS** | 0 (cleared by EC-151 burn this session; was 1) |

**6 PASS, 3 FAIL. 51 total live violations.**

The 9 adr-consistency violations reduce to **5 root causes:**
- Undefined E-class codes `E-IO-002` (BC-2.01.009:73 and prd-supplements/interface-definitions.md:237) and `E-CLI-001` (BC-2.11.004:61)
- Three verdict reason codes outside the 13-code closed taxonomy: `case-insensitive` (BC-2.03.002:82), `syntax-valid` (test-vectors.md:225), `malformed-fragment` (test-vectors.md:436)

**Contradiction disclosed:** STATE.md BI-023 resolution text claims "Full spec-lint GREEN
(9/9)". Direct execution this session contradicts it. Direct execution is treated as
authoritative. This is one of the reasons BI-023 is carried OPEN with ambiguous status.

---

### §3.6 Input-Hash Drift (D-170) — Not Clean

130 in-scope hash-declaring artifacts: **68 CURRENT, 62 DRIFT**; 75 repo-wide.

**Attribution of this session's contribution:**
- This session leaves ZERO newly-stale artifacts — the EC-214 stale-on-arrival stamp was
  detected by the pre-gate sweep and remediated before the gate, and all 62 remaining
  in-scope drifts pre-date this session.
- 48 in-scope drifts were present at committed HEAD.
- Nothing else became current.

**Cluster shape of the 48 pre-existing drifts:**
All 6 domain-spec shards, all 3 PRD supplements, an entire VP family (17 VPs), and 7
architecture docs. The drift skill flags cluster-shaped drift as a **content-review signal
requiring producing-agent review, not bulk re-stamping**.

**Two structural gaps:**

(a) `.factory/cycles/phase-1d/adversary-pass-2.md` is **UNVERIFIABLE** — its `inputs:`
field contains prose descriptions rather than file paths. It drops out of drift detection
entirely: neither CURRENT nor DRIFT. Drift detection cannot assess its currency.

(b) **Three of the five files changed this session are outside hash coverage altogether.**
No artifact declares `prd-supplements/test-vectors.md`, `holdout-scenarios/HS-INDEX.md`,
or the new scenario/ledger files as an `input:`. A clean drift scan over those changes is
a **FALSE NEGATIVE**, not evidence of currency.

---

### §3.7 Deferred Items

| Item | Deferred To | Authority |
|------|------------|-----------|
| Spec-lint REQUIRED flip | When corpus is clean or violations adjudicated (see §5 for recommendation to change this precondition) | D-117/D-122/D-133 |
| M-1 prose-figure inversion (verifier hole (c)) | Pre-wave-1 checkpoint | D-232 |
| BI-041 `--write` prohibition | Until annotation adjudication | Pending adjudication |
| BI-060 second-identity question (AGENCY-vs-IDENTITY gap) | Pre-wave-1 checkpoint | D-197 |
| BI-062 hook repair (`pr-manager-completion-guard`) | Post-run; no mid-run hook edits | D-158/D-182/D-231 |
| BI-064 hook repair (`verify-state-timestamp-refresh`) | Post-run engine work; no mid-run hook edits | D-158/D-182/D-231 |
| CI token grant | RESOLVED as NOT-DO | D-203/D-231 |
| D-165 story-propagation debt (VP-004/VP-025/VP-INDEX/TV-157) | Phase 2 story decomposition; handle in same burst as BI-052 | D-165 |
| PG-001..PG-012 policy lint hooks | Phase 2 / Phase 3 | Process gap register |
| STATE.md repair (6 stale-state assertions + BI-061 closure + BI-062/063/064 insertion + D-242/D-243 rows) | Next session (fresh STATE.md burst) | D-243 classifier block + operator ruling |
| Gate #53 post-run backlog: BI-058 nine-checker sweep, BI-063 semantic claim-audit, adversary passes 8/9/10, 3-clean-pass streak, CI-063 wording revision, L-77 read-what-you-commit carve-out | Post-ratification, pre-Phase 2 | Gate #53 / D-231 |

---

### §3.8 Register Completeness — The Limits of This Register

**The register is complete at CLASS granularity, not per-finding.** The ~273–275 pass-7
findings were rolled into class-level BIs. Roughly **250 individual findings carry no
per-finding adjudication reason**. The 9 shard files
(`.factory/cycles/phase-1d/adversary-pass-7-shard-1.md` through `..shard-9.md`) are the
only per-finding record. Closing this gap requires real work — it was disclosed here rather
than done, per gate #57.

**The register spans TWO files, not one.** STATE.md is knowingly incomplete:

- D-242, D-243, the BI-061 closure, BI-062, BI-063, BI-064, and lessons L-78..L-81 exist
  only as pending verbatim text in SESSION-HANDOFF §RESUME SNAPSHOT D-243.
- STATE.md additionally still asserts pre-merge state in six places and a stale
  `D-001..D-222` range.
- Repair was attempted this session, was blocked by the permission classifier (D-243), and
  was then DEFERRED by operator ruling. The classifier's objection was that the authorized
  dispatch described itself as routing around a control; the operator chose to carry the
  records verbatim in the snapshot and defer STATE.md insertions to the fresh session.

**`.factory/cycles/phase-1d/adjudication-ss07-ss14.md` frontmatter is stale:**
`status: awaiting-operator-ruling` though BI-029/BI-030 closed via D-061/D-062/D-063.
Not corrected per gate #57 ruling.

**The process-gap register stops at PG-012.** Approximately 20 later `[process-gap]`
lessons (L-60..L-81) were never promoted to PG-NNN entries with dispositions. The S-7.02
codification rule is unsatisfied for everything after PG-012.

**PG-012's disputed pass-5 total (36 vs 37) is unadjudicated.** The pass-5 finding
population was never persisted — permanently lost. Both numbers appear in the record;
neither can be confirmed.

---

## §4 D-205 NEW-CLASS Assertion — For Operator Evaluation

Per D-211, the following findings may map to no known class. **The operator, not the
orchestrator, evaluates the three D-205 deal-breakers:** (a) new content-defect class,
(b) non-decaying CRITICAL rate, (c) domain-model-invalidating defect. Both candidates are
presented neutrally with the argument on each side.

### Candidate 1: VP-010's Property Statement Negates CAP-011

VP-010 (v1.0, `modified: []`, never reviewed by any prior adversary pass) has a Property
Statement that reads "The allow-match logic compares full URL components (scheme + host),
never raw byte prefixes." BC-2.11.002 PC3 mandates raw-string prefix match at a component
boundary when WHATWG normalization fails (D-019 requirement). VP-010's own property
statement is the negation of the behavior it is supposed to verify.

**Argument for NEW class:** This is not a mis-attribution (a BC citing a VP that proves
something else) — it is a VP asserting the opposite of the capability it verifies. A
contradiction at the VP level sits outside BI-052's stated class, which concerns BCs
citing VPs whose bodies prove different properties. VP-010 is not a mis-labelled proof; it
is an actively wrong specification.

**Argument for KNOWN class:** It is the BI-053 inversion lineage (BCs forbidding what
five authoritative sources required), reappearing on the VP surface rather than the BC
surface. If BI-052 covers "spec artifacts that assert the opposite of what is required,"
this is the same class at a different layer.

### Candidate 2: `verification-coverage-matrix.md` Asserting 13/13 DI Coverage That Is Materially False

`verification-coverage-matrix.md:111` states "All 13 DIs have VP coverage (13/13)." This
is contradicted by finding P7-S7-004: VP-INDEX and the matrix both report DI-004 fully
covered while the indented-code context and the entire anchor_table side have zero harness
coverage.

**Argument for KNOWN class:** The false-claim lineage is already tracked through
D-241/BI-063. A coverage-matrix reporting false coverage is the same class as a BC
claiming proof coverage that does not exist.

**Argument for NEW class:** This is a coverage-accounting artifact, not a code comment or
a BC. A reader who trusts a coverage matrix has stronger warrant to trust it than they do
to trust a prose comment in a BC — the matrix's sole purpose is to state coverage status,
so the false claim occupies a position of higher authority.

### Decay Evidence Relevant to Deal-Breaker (b)

PR #13's five review cycles decayed as follows:

| Metric | C1 | C2 | C3 | C4 | C5 |
|--------|----|----|----|----|-----|
| MUST-FIX open | 5 | 5 | 5 | 2 | 1 → **0** |
| New classes | 5 | 5 | 1 | 0 | **0** |
| Severity ceiling | high | mid | mid | mid | **none** |

This decay shows convergence to zero MUST-FIX and zero new classes across five cycles.
However: this decay is evidence about **verifier TOOLING only**. It is NOT evidence that
spec-content CRITICALs are decaying. The pass-7 shard findings, which are spec-content
findings, have not been subjected to any comparable decay measurement — they were
adjudicated in bulk under gate #57, not reviewed across multiple passes to convergence.

---

## §5 Recommendation — Spec-Lint REQUIRED Flip

**Recommendation: DO NOT FLIP NOW.**

**Recommendation: CHANGE THE PRECONDITION** from "flip when the checkers are repaired" to
"flip when the corpus is clean or its violations are adjudicated."

**Reasoning:**

Branch protection requires 4 checks; `Spec lint` is currently advisory and fails by design
(D-128/D-231). Flipping it REQUIRED with 51 open violations converts those violations into
an immediate, total merge deadlock — including the Phase-2 and wave-1 PRs in the ratified
queue.

The recorded reason for deferring the flip (D-117) is now largely stale. D-117 deferred
the flip because three checkers were structurally blind. Two of the three demonstrably work
now:

- `check-holdout-boundary.py`, characterized in D-117 as "prose-blind," CAUGHT the
  EC-151 prose leak at `prd.md:618` (tagged BI-049, 134/134 files checked).
- `check-adr-consistency.py`, characterized as "never reads BCs/test-vectors," now reads
  126 non-ADR files plus 8 ADRs and finds exactly the phantom codes D-117 named.

The third checker, `check-ec-injectivity.py`, is recorded as SOUND with a calibration
limitation (D-126), not blind.

The precondition "flip when the checkers are repaired" is largely satisfied. Keeping it as
written holds the flip hostage to the post-run BI-058 sweep that gate #53 just cut. The
replacement precondition "flip when the corpus is clean or its violations are adjudicated"
is measurable: 5 root causes (for the 9 adr-consistency violations) plus 42 adjudications
(for the ec-injectivity divergences).

**Counter-argument:** `check-ec-injectivity`'s 42 divergences is a LOWER BOUND (D-126),
so "corpus clean" cannot be fully established by that checker alone. The flip should not be
treated as achievable on the basis of that checker's current output.

**The human decides** whether to adopt this recommendation or override it.

---

## §6 What This Session Changed

**EC-151 burn per D-122/D-020 precedent:**
- EC-151 holdout designation RETIRED and burned to visible test vector TV-151 (now live and visible in `prd-supplements/test-vectors.md`).
- Fresh hidden replacement authored: HS-008 / EC-214. Identifiers only are recorded in the HS-INDEX per POL-18; no concrete content of HS-008 is disclosed in this document or any index artifact.
- Holdout pool held at 12 (HS-002 and HS-003 retired; HS-008 added; net unchanged).

**Version bumps:**
- HS-INDEX: 1.1 → 1.3
- prd.md: 1.14 → 1.15
- test-vectors.md: 1.10 → 1.11

**Verified by direct execution:**
- `check-holdout-boundary`: 1 violation → 0
- `check-counts`: 37/37
- `check-index-integrity`: HS 8/8

**POL-18 breach corrected before gate:** A POL-18 leak in the newly written HS-008 index
row (it named the hidden fixture's HTML element) was caught by orchestrator verification
and corrected before this gate was assembled. This was the **THIRD POL-18 breach in this
project's history** (D-020, D-122, and this session). The pattern — three breaches across
three separate holdout-touching sessions — is a process control gap worth the human's
attention.

**Branch state:**
- Local `develop` fast-forwarded to `f81f412` (PR #13 squash merge).
- Merged branch `fix/verifier-hardening-sweep-step0` deleted.

---

## §7 Questions for Human Review

The following questions point at assumptions requiring human verification or decisions only
the human can make.

**Q1 — Convergence bar:** You are being asked to ratify a spec at **0 of 3 clean adversarial passes** by deliberate truncation. The convergence phase was cut by operator ruling, not reached naturally. Do you accept this truncation and ratify the spec as workable under D-205/D-214 build-sufficiency, or do you require resuming convergence (passes 8/9/10 plus 3-clean-streak) before ratification?

**Q2 — BI-052 residual risk:** 21 accepted false-green VP attributions mean BCs advertise Kani P0 proofs that do not exist. The Phase-2 story-writers and Phase-3 implementers will read these BCs and write acceptance suites from them. The acceptance suite written from BC bodies alone will systematically miss what each VP claims to cover (Residual Risk item 5 in §3.2). Is that acceptable to carry into Phase 2/3 without correction, given that corrections would require rewriting VP bodies before Phase 3 begins?

**Q3 — D-205 NEW-CLASS candidates:** The two candidates in §4 — VP-010's property statement negating CAP-011, and the coverage-matrix asserting false 13/13 DI coverage — each have arguments for being a new content-defect class and arguments for being a known class. This is the operator's call per D-211. What is your verdict on each?

**Q4 — 63 drift artifacts and cluster-shaped drift:** 63 in-scope artifacts have input-hash drift, including all 6 domain-spec shards, all 3 PRD supplements, an entire VP family (17 VPs), and 7 architecture docs. The drift skill flags this cluster shape as a content-review signal requiring producing-agent review, not bulk re-stamping. Do you accept the drift as disclosed and proceed to Phase 2, or do you require producing-agent review of the drifted artifact clusters before ratification?

**Q5 — Spec-lint precondition swap:** The recommendation in §5 is to change the precondition from "flip when the checkers are repaired" (largely satisfied) to "flip when the corpus is clean or its violations are adjudicated" (measurable at 5 root causes + 42 adjudications). Do you adopt this recommendation, or override it?

**Q6 — BI-023 / BI-027 ambiguous status:** Both BIs have resolution text that reads as closed (BI-023: "Full spec-lint GREEN (9/9)"; BI-027: "0 FABRICATED remain") but both remain in the OPEN table. The 9/9 claim in BI-023's resolution text is directly contradicted by this session's execution. Do you adjudicate BI-023 as OPEN (the 9/9 claim was stale when written) or as evidence the issue was closed and has since regressed? Do you adjudicate BI-027 as CLOSED given its resolution text, or keep it OPEN until a subsequent audit confirms?

**Q7 — BI-062 merge-coercion hook before Phase 2:** The `pr-manager-completion-guard` hook fired 8 times this session, manufacturing merge authorizations it was never granted, including while PR #13 carried an OPEN REQUEST_CHANGES verdict. Phase 3 will run many PRs. The current mitigation is "refuse and record." This hook remains live and unrepaired. Do you accept the refuse-and-record mitigation as sufficient for Phase 2/3, or do you require repair of this hook before wave 1 begins — even though repair requires a mid-run hook edit which is prohibited by D-158/D-182/D-231?

**Q8 — Register completeness at class-not-finding granularity:** ~250 of the ~273–275 pass-7 findings carry no per-finding adjudication reason. They were rolled into class-level BIs; the 9 shard files are the only per-finding record. Do you accept this class-level granularity as the permanent record for Phase 1, or do you require per-finding adjudication of pass-7 findings before ratification? (Note: per-finding adjudication was explicitly cut by gate #57 as a post-run task.)

---

## §8 Ratification Block

**Decision required from human:**

```
RATIFICATION DECISION:
[ ] Approve (with disclosed defects as registered in §3)
[ ] Reject — resume convergence before ratification
[ ] Investigate — specific questions or items requiring resolution before decision

If Approve:
  Signature: ___________________________
  Date: ___________________________

  D-205 NEW-CLASS CANDIDATE 1 (VP-010 contradiction):
  [ ] Known class (BI-052/BI-053 inversion lineage, VP layer)
  [ ] New class — requires additional disposition
  [ ] Investigate further before deciding

  D-205 NEW-CLASS CANDIDATE 2 (coverage-matrix false 13/13):
  [ ] Known class (false-claim lineage, D-241/BI-063)
  [ ] New class — requires additional disposition
  [ ] Investigate further before deciding

  §5 Spec-Lint Precondition Swap Recommendation:
  [ ] Adopt — change precondition to "flip when corpus clean or violations adjudicated"
  [ ] Override — retain original precondition
  [ ] Override with alternate precondition: _____________________________

  BI-023 Status Adjudication:
  [ ] OPEN — 9/9 claim was stale; issue persists (direct execution authoritative)
  [ ] CLOSED — was correctly resolved; current 3-FAIL state is a regression, separate issue
  [ ] Other: ___________________________

  BI-027 Status Adjudication:
  [ ] CLOSED — WS-4 Shards A–E complete, 0 FABRICATED remain per resolution text
  [ ] OPEN — retain until confirmed by subsequent audit
  [ ] Other: ___________________________
```
