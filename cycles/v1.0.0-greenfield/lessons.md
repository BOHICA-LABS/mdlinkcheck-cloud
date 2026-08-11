---
document_type: lessons-learned
level: ops
version: "1.0"
status: in-progress
producer: vsdd-factory:state-manager
timestamp: "2026-08-11T00:00:00Z"
cycle: "v1.0.0-greenfield"
inputs: []
input-hash: "d41d8cd"
traces_to: STATE.md
---

# Lessons Learned — v1.0.0-greenfield

<!-- Durable lessons from the v1.0.0-greenfield pipeline for future VSDD factory runs.
     Organized by category: agent-level, process-level, infrastructure-level.
     Each lesson is numbered continuously and includes the pass/burst
     where it was discovered. Lessons tagged [process-gap] require either
     a follow-up story targeting a self-improvement epic or a justified
     deferral entry; see the disposition note on each. -->

## Agent-Level

1. **L-93 — A Fix That Adds Coverage Asymmetrically Can Invert a Defect Rather Than Remove It** `[process-gap]` — BI-081 made `stdout`/`Instant` grouped forms robust while leaving `fs`/`net` with weaker arms. The BI-081 fix inverted the asymmetry rather than eliminating it, producing BI-091. When closing a gap for some members of a set, enumerate the whole set and verify each member independently. A partial fix that produces a mirror defect is a net-neutral outcome, not progress.
   _Discovered: S-1.01 third confirming round pass 22, 2026-08-11_
   **Process-gap disposition required — not yet made. Do not invent story IDs.**
   **Closes:** (pre-D-448(b) exemption)

2. **L-95 — Never Attribute a Gate's Own Scope Limits to a Frozen Spec Without Quoting the Spec** `[process-gap]` — The `2616257` fix promoted an analyst's aside ("ADR-001 enumerates path-fragments, not macros") into durable gate-printed text. That claim is FALSE about the frozen spec — ADR-001 reads "or any other I/O primitive." The false authority caused pass 21 to decline to file the macro gap as a finding. When a gate cannot enforce part of a spec, the correct documentation is "this CHECK does not cover X" — not "the SPEC does not cover X." Scope limits are properties of the check, not of the spec.
   _Discovered: S-1.01 third confirming round passes 23–24, 2026-08-11_
   **Process-gap disposition required — not yet made. Do not invent story IDs.**
   **Closes:** (pre-D-448(b) exemption)

## Process-Level

3. **L-92 — Sweep Every Site When Correcting a Claim About a Flag or Value** — When correcting a claim about a flag or value, sweep EVERY site that repeats it, including summary and prerequisite tables far from the change. The BI-082 fix corrected `justfile:505` but would have shipped a newly-false justfile prerequisites table had a parity grep not been run. Corollary: prefer step-NAME references over cross-file line-number citations (the BI-084 class). A step name remains stable when surrounding lines shift; a line citation drifts silently every time the file is edited.
   _Discovered: S-1.01 fix wave 4 (BI-082 remediation), 2026-08-11_
   **Closes:** (pre-D-448(b) exemption)

4. **L-94 — Verify a Text-Matching Gate Against the Output of the Project's Own Required Formatter** `[process-gap]` — `rustfmt` produces the exact multi-line grouped-import shape the purity detector was blind to, and `cargo fmt --all --check` is a branch-protection-required gate — the project was ENFORCING the formatting that defeated its own erosion gate. Verifying against hand-written samples missed this because hand-written samples were not formatted by `rustfmt`. Sibling of L-89 (verify in the gate's ENVIRONMENT): L-89 = execution environment; L-94 = input form produced by required toolchain. Before shipping a text-pattern gate, run the required formatter on each sample and verify the gate still fires.
   _Discovered: S-1.01 third confirming round pass 22, 2026-08-11_
   **Process-gap disposition required — not yet made. Do not invent story IDs.**
   **Closes:** (pre-D-448(b) exemption)

6. **L-97 — Unanimous Multi-Agent Agreement Is Not Evidence** `[process-gap]` — Three independent adversary passes (P25, P26, P27) converged unanimously on an inference — that `98a4f15..HEAD` was not docs-only and that the CI attestation did not carry to `b42285a` — that was FALSE. Five `git`/`gh` commands refuted it completely. Consensus raises confidence about *salience* (the topic is worth examining) but not about *truth* (the conclusion is correct). Every agent report is verified by direct execution regardless of how many passes agree. The refutation is the primary evidence basis for the standing L-81/D-193 rule: verify empirically, always.
   _Discovered: S-1.01 fourth confirming round passes 25–27, 2026-08-11_
   **Process-gap disposition required — not yet made. Do not invent story IDs.**
   **Closes:** (pre-D-448(b) exemption)

7. **L-98 — Never Derive a Metric from a Cancelled Run** `[process-gap]` — All four mutation killing runs were CANCELLED by nextest's default fail-fast (`25/44`, `25/44`, `21/44`, `18/44` with `0 skipped`). A `Summary: N/M tests run` line with `0 skipped` means fail-fast cancellation, not completion — the count is a floor, not a measurement. All three adversary passes then independently "corrected" the evidence figures by reading these cancelled summaries as ground truth, producing a correction (`3/1/5/1`) that was itself wrong for two of four mutants (M3 true 7, not 5; M4 already correct at 2, not 1). Mutation kill counts must be produced with `--no-fail-fast` or they are not kill counts — they are partial counts from cancelled runs, which are unreliable in both directions.
   _Discovered: S-1.01 fourth confirming round passes 25–27, 2026-08-11_
   **Process-gap disposition required — not yet made. Do not invent story IDs.**
   **Closes:** (pre-D-448(b) exemption)

8. **L-99 — A Collapsed Single Implementation Inherits None of the Review History of What It Replaced** `[process-gap]` — The BI-090 fix extracted the duplicated purity detector to a single `scripts/purity-check.sh`. That extraction was correct: it closed L-96's defect-generator class by construction. But `scripts/purity-check.sh` was entirely new code — it was NOT the old inline code copied verbatim, it was a rewrite — and it was never adversarially reviewed as a unit before round 4. The leading-`::` escape (BI-096, HIGH) lived in it from the moment it was created. When a duplicated gate is collapsed into one shared implementation, treat the new single file as unreviewed surface and audit it before trusting any "closed by construction" claim the collapse makes. The collapse closes the parity problem; it does not retroactively audit the new file.
   _Discovered: S-1.01 fourth confirming round, 2026-08-11_
   **Process-gap disposition required — not yet made. Do not invent story IDs.**
   **Closes:** (pre-D-448(b) exemption)

## Infrastructure-Level

5. **L-96 — Duplicated Gate Logic Across CI and a Local Task Runner Is a Defect Generator** `[process-gap]` — The purity detector lived as two hand-maintained copies in `ci.yml` and `justfile`. Three consecutive adversary rounds found defects in it: BI-081 (round 2), then BI-091 and BI-092 (round 3). All three would have been impossible if there had been only one copy to maintain. The pattern "two copies must stay byte-identical by discipline" is a standing defect generator; the correct shape is "one file invoked by both." Extract to one invoked file so parity holds by construction rather than by ongoing manual synchronization.
   _Discovered: S-1.01 third confirming round, 2026-08-11_
   **Process-gap disposition required — not yet made. Do not invent story IDs.**
   **Closes:** (pre-D-448(b) exemption)

9. **L-100 — A Gate's Self-Check Can Only Prove the Shapes It Enumerates** — `scripts/purity-check.sh` asserted 21 evasion shapes and printed a coverage claim broader than those 21 ("leaf-aliased (as _x)", "intermediate-module-aliased", "in any import shape"). The escape lived in the gap between the enumeration and the claim: the SCOPE block said a shape was covered but no plant actually tested it. A scope statement must be derived from the plant list, never written independently of it. The correct claim is "the detector catches each of the N shapes in this plant list" — provable by inspection. Any broader claim ("all forms", "in any import shape") is an assertion about the gap the plants do not cover and cannot be verified by the self-check. Discovered via BI-096: the claim of coverage was in the gate's own SCOPE block, which made it authoritative-looking and caused prior passes to trust the gate's self-assessed scope without probing it.
   _Discovered: S-1.01 fourth confirming round, 2026-08-11_
   **Closes:** (pre-D-448(b) exemption)

10. **L-101 — Attest to the Most Immutable Property That Supports the Conclusion** — "`crates/` is byte-unchanged between two named SHAs" survives; "the delta is documentation-only" does not survive committing further changes. Anchor CI to a fixed commit rather than carrying it forward. The permitted form for immutable attestation names both endpoint SHAs explicitly; the prohibited form names one SHA and claims it is current.
    _Discovered: S-1.01 fix wave 5 (self-invalidating-attestation class), 2026-08-11_
    **Closes:** (pre-D-448(b) exemption)

11. **L-102 `[process-gap]` — A Committed Artifact Can Never Assert That a Named SHA IS the Current HEAD** — Committing moves HEAD, so any statement "SHA X is the current HEAD" is self-refuting the instant the commit lands. Permitted forms: (a) immutable named-SHA facts with both endpoint SHAs named; (b) verification commands phrased as instructions to the reader, making no claim about what HEAD currently is. The `PR-PACKAGE.md` ancestor-check lines used form (b) correctly throughout and were never defective — the pattern was available and simply had not been applied to the attestation bullets. Five recurrences before the class was closed.
    _Discovered: S-1.01 fix wave 5 (fifth recurrence of self-invalidating-attestation class), 2026-08-11_
    **Process-gap disposition required — not yet made. Do not invent story IDs.**
    **Closes:** (pre-D-448(b) exemption)

12. **L-103 `[process-gap]` — When a Defect Recurs, Specify the CLASS Fix, Not the Instance Fix** — Five recurrences of the self-invalidating-attestation defect across two files occurred because instance corrections were issued for a structural problem. The class only closed once the rule was stated as permitted/forbidden forms. Each successive instance fix narrowed the scope of the next violation rather than eliminating the root cause. The correct response to a second recurrence of the same defect class is to halt instance repair and instead articulate the prohibition in structural terms that make the class impossible.
    _Discovered: S-1.01 fix wave 5 (fifth recurrence analysis), 2026-08-11_
    **Process-gap disposition required — not yet made. Do not invent story IDs.**
    **Closes:** (pre-D-448(b) exemption)

13. **L-104 `[process-gap]` — A Self-Check That Aborts on First Failure Proves Only That the FIRST New Assertion Discriminates** — Test each new plant/lock individually against the pre-fix implementation, or the added coverage is unquantified. In fix wave 5: `cd3507a` added 14 new plants; the self-check exited 1 on the FIRST failing plant (`_p22`), so that alone proved only `_p22` discriminates. Individual per-plant testing revealed 12 genuinely discriminate and 2 do not (`_p23` and `_p26` — old `net::` matched regardless of the leading `::`, and old `rand::` matches `fastrand::` as a bare substring). The plant count locked less than it implied. The correct protocol is individual per-plant testing against the pre-fix detector, or a documented disclaimer that per-arm isolation is not guaranteed.
    _Discovered: S-1.01 fix wave 5 orchestrator verification, 2026-08-11_
    **Process-gap disposition required — not yet made. Do not invent story IDs.**
    **Closes:** (pre-D-448(b) exemption)

## Policy Candidates

<!-- Lessons that should be formalized as governance policies.
     Reference the lesson number and proposed policy scope. -->

| Lesson | Proposed Policy | Scope | Status |
|--------|----------------|-------|--------|
| 3 (L-92) | Claim-correction sweep requirement: after any fix to a documented claim, grep the repo for every verbatim repetition before committing | Fix-wave process | proposed |
| 4 (L-94) | Formatter-output verification: text-pattern gates must be validated against `rustfmt`-formatted samples before merging | CI gate authoring | proposed |
| 5 (L-96) | Single-source gate logic: gate scripts invoked from multiple callers must live in exactly one file; inline duplication is a blocker | CI gate authoring | proposed |
| 6 (L-97) | Multi-agent consensus verification: unanimous agreement across N passes is not a substitute for execution; empirical verification is required regardless of agreement count | Adversarial review process | proposed |
| 7 (L-98) | Fail-fast prohibition for mutation runs: mutation kill counts must be produced with `--no-fail-fast`; results from cancelled runs must not be counted or quoted as kill counts | Mutation testing process | proposed |
| 8 (L-99) | Collapsed-implementation audit obligation: any gate logic extracted from duplication to a single file is treated as unreviewed surface and must pass fresh adversarial review before the "closed by construction" claim is accepted | CI gate authoring | proposed |
| 11 (L-102) | Self-invalidating-attestation prohibition: any committed artifact that uses the word "current" in conjunction with a named SHA is a defect; require permitted forms (a) or (b) | Fix-wave / evidence authoring | proposed |
| 12 (L-103) | Class-fix obligation: after a second recurrence of any defect, the response must be a structural prohibition, not an instance correction | Orchestrator process | proposed |
| 13 (L-104) | Per-plant discrimination requirement: each new plant/lock must be individually tested against the pre-fix implementation; a self-check abort on first failure is insufficient proof of per-arm coverage | CI gate authoring | proposed |
