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

## Infrastructure-Level

5. **L-96 — Duplicated Gate Logic Across CI and a Local Task Runner Is a Defect Generator** `[process-gap]` — The purity detector lived as two hand-maintained copies in `ci.yml` and `justfile`. Three consecutive adversary rounds found defects in it: BI-081 (round 2), then BI-091 and BI-092 (round 3). All three would have been impossible if there had been only one copy to maintain. The pattern "two copies must stay byte-identical by discipline" is a standing defect generator; the correct shape is "one file invoked by both." Extract to one invoked file so parity holds by construction rather than by ongoing manual synchronization.
   _Discovered: S-1.01 third confirming round, 2026-08-11_
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
