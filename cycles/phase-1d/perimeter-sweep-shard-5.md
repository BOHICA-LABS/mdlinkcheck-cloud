---
document_type: adversarial-findings
level: ops
version: "1.0"
status: final
producer: adversary
timestamp: 2026-08-07T01:00:00Z
cycle: phase-1d
shard: 5
frozen_head: 1d3ed17
scope: "SS-11 (4) + SS-12 (5) + SS-13 (2) + SS-14 (4) = 15 BC bodies read in full"
counts: "6 CRITICAL / 15 HIGH / 11 MEDIUM = 32"
verdict: "exit-code precedence rules are NOT complete or unambiguous"
inputs:
  - .factory/specs/behavioral-contracts/ss-11/
  - .factory/specs/behavioral-contracts/ss-12/
  - .factory/specs/behavioral-contracts/ss-13/
  - .factory/specs/behavioral-contracts/ss-14/
input-hash: "c39268f"
traces_to: cycles/phase-1d/perimeter-sweep-synthesis.md
---

# Adversarial Findings — Perimeter Sweep Shard 5

**Scope:** SS-11 (4 BC bodies) + SS-12 (5 BC bodies) + SS-13 (2 BC bodies) + SS-14 (4 BC bodies) = 15 BC bodies read in full.
**Frozen HEAD:** `1d3ed17`
**Counts:** 6 CRITICAL / 15 HIGH / 11 MEDIUM = **32 findings**
**Verdict:** exit-code precedence rules are NOT complete or unambiguous

---

## CRITICAL Findings

### P6-S5-001 (POLICY 16/4)

**Location:** BC-2.11.001.md:50
**Title:** PC4 says --ignore does NOT affect explicit PATH; justification and sibling BC-2.11.003 both say --ignore WINS — same vendor/lib.md yields exit 0 or exit 1 depending on which BC is read

BC-2.11.001.md:50 PC4 states "--ignore does NOT affect files passed as explicit PATH arguments" while its own bracketed justification says "AMB-108: --ignore WINS over explicit PATH". The cited authority (interface-definitions.md:234) and sibling BC-2.11.003.md:52 ("--ignore wins. ALWAYS.") both contradict the postcondition. vendor/lib.md with a broken link = exit 0 under BC-2.11.003, exit 1 under BC-2.11.001 PC4.

---

### P6-S5-002 (POLICY 4/16)

**Location:** BC-2.13.001.md:48-49, interface-definitions.md:198, BC-2.10.002.md:73,:109, error-taxonomy.md:121-124
**Title:** `sub_reason` is mandated by the schema, REQUIRED by its producer, and UNEMITTABLE — three layers deep with no correction in capabilities.md:218 or the Finding struct

`sub_reason` is mandated by the schema, REQUIRED by its producer, and UNEMITTABLE. BC-2.13.001.md:48-49 PC2 fixes a CLOSED six-field key order; interface-definitions.md:198 mandates seven including `sub_reason`. BC-2.10.002.md:73,:109 plus error-taxonomy.md:121-124 REQUIRE emitting it. Gap is three layers deep: capabilities.md:218 (CAP-013) omits it; BC-2.13.002 (the schema-stability contract) never mentions it; api-surface.md:121-123 `Finding` has no such field and format_json consumes only Finding. Root cause documented: prd.md:674 enumerates D-016's propagation set verbatim and SS-13, CAP-013 and Finding were never in it. `sub_reason` is the ONLY mechanism distinguishing `private-ip` (security outcome, no request sent) from `https-downgrade` and from a generic 5xx — all three collapse to reason `http-indeterminate`. No reading satisfies both BCs.

---

### P6-S5-003 (POLICY 4)

**Location:** api-surface.md:110-112,:132-138, decisions.md:89
**Title:** The `errors[]` array required by BC-2.13.001 PC1/PC7 cannot be produced by the only declared JSON function — format_json has no io_errors parameter

The `errors[]` array required by BC-2.13.001 PC1/PC7 cannot be produced by the only declared JSON function: api-surface.md:110-112 gives `format_summary(findings, io_errors)` but `format_json(findings)` — no io_errors parameter, so it has no access to the data PC1/PC7 require it to serialize. api-surface.md:132-138's schema block still shows only `{schema_version, results}`, and cites DD-011 which at decisions.md:89 still describes the output as a bare ARRAY of findings. The F-013 fix landed on the BC but not the architecture surface; `format_summary` got its `io_errors` parameter in P4-022 and its sibling on the same line-block did not. `errors[]` exists specifically for the PRIMARY CI-engineer persona and is unimplementable through the declared API.

---

### P6-S5-004 (POLICY 12/19)

**Location:** BC-2.14.002.md:49, error-taxonomy.md:50,:54, interface-definitions.md:99, BC-2.13.001.md:66
**Title:** PC2 calls an I/O error a "finding" reported "in output" — contradicts three authoritative sources; every wc -l CI consumer miscounts it as a broken link

BC-2.14.002.md:49 PC2 calls an I/O error a "finding" reported "in output". error-taxonomy.md:50,:54 are explicit that I/O errors are NOT link verdicts; interface-definitions.md:99 fixes stdout as findings only; BC-2.13.001.md:66 declares a results entry with reason `target-unreadable` "IS A BUG". In text mode an implementer emits an I/O line to stdout with finding-line shape but no line number, so every `wc -l` CI consumer BC-2.12.005 promises to support miscounts it as a broken link. Corroborating sibling BC-2.01.009.md:58,:71.

---

### P6-S5-005 (POLICY 19/16/4)

**Location:** capabilities.md:233, BC-2.14.001.md:45, BC-2.14.002.md:44, BC-2.14.003.md:43, interface-definitions.md:205
**Title:** Nonexistent PATH argument has NO reason code in the closed 13-code set and is classified two mutually exclusive ways; phantom E-IO-002 papers over the gap

A nonexistent PATH argument has NO reason code in the closed 13-code set and is classified two mutually exclusive ways: CAP-014 (capabilities.md:233) says USAGE error; BC-2.14.001.md:45, BC-2.14.002.md:44, BC-2.14.003.md:43 all say I/O error, emphatically ("NOT a startup configuration error"). Exit code is 2 either way so POLICY 12 passes, but the classification determines JSON `errors[]` population, and interface-definitions.md:205 fixes that array's reason as "Always `target-unreadable`" whose trigger requires the file to EXIST. The specs paper over it with the phantom E-IO-002. `mdlinkcheck docs/ typo-dir/` in CI therefore yields either an empty `errors[]` with exit 2 and no machine-readable cause, or a reason the taxonomy forbids.

---

### P6-S5-006 (POLICY 4/9)

**Location:** BC-2.14.001.md:76-77, BC-2.14.002.md:74-75, BC-2.14.003.md:73-74
**Title:** ALL SIX VP rows across the three SS-14 BCs declare Proof Method "unit test" where VP-INDEX says Kani P0; story-writer sees six "unit test" rows and writes no Kani task — DI-010/DI-011 ship with example-based tests

ALL SIX VP rows across the three SS-14 BCs declare Proof Method "unit test" (BC-2.14.001.md:76-77, BC-2.14.002.md:74-75, BC-2.14.003.md:73-74) where VP-INDEX.md:61-62 declares VP-005 and VP-006 KANI P0. VP-INDEX.md:97-98 records DI-010/DI-011 as fully covered SOLELY on those two proofs, and api-surface.md:114-115 marks verdict.rs a Kani target. A story-writer decomposing SS-14 reads the BC body, sees six "unit test" rows, writes no Kani task, and DI-010/DI-011 ship with example-based tests while the coverage matrix still reports Yes.

---

## HIGH Findings

**P6-S5-007** BC-2.14.004.md:43,:53 (unconditional exit 0 for `--help/--version`) vs BC-2.11.004.md:50 (exit 2 for invalid glob) and BC-2.12.004.md:51 (exit 2 for invalid `--format`) are co-satisfiable with contradictory exit codes and no adjudicating rule — this is the CI availability-probe path BC-2.14.004 exists to protect.

**P6-S5-008** BC-2.14.004.md:50 PC5 "stderr is empty" contradicts BC-2.12.003.md:53,:56 ("ALWAYS written to stderr", "no flag suppresses"), BC-2.14.001.md:51 and interface-definitions.md:133.

**P6-S5-009** Three of BC-2.14.002's five canonical vectors (:66,:67,:68) violate its own preconditions, and row :67 (I/O error with no broken link) is the PRIMARY exit-2 case with NO satisfiable-precondition BC anywhere in SS-14; unknown flag -> 2 and invalid `--format` -> 2 are owned by no exit-code BC.

**P6-S5-010** (POLICY 4) Two independent Related-BCs pointers (BC-2.11.004.md:90, BC-2.14.004.md:87) describe the wrong BC as "the exit-2 contract" and land on DIFFERENT wrong targets — direct corroboration of the P6-S5-009 structural hole.

**P6-S5-011** `--format json` + startup config error yields EMPTY stdout (BC-2.11.004.md:54, BC-2.12.004.md:46 neither conditions on `--format`), falsifying interface-definitions.md:102 ("must produce valid JSON"), BC-2.13.001.md:65 (jq must work) and BC-2.13.002.md:52; no BC specifies an exit-2 JSON envelope.

**P6-S5-012** BC-2.12.002.md:45-49 PC3/PC4 vs PC5 are mutually contradictory for `NO_COLOR=1 CLICOLOR_FORCE=1` and `CLICOLOR=0 CLICOLOR_FORCE=1` with no precedence rule anywhere; both are common CI combinations and the outcome decides whether ANSI bytes land in stdout.

**P6-S5-013** (POLICY 5) SYSTEMATIC FABRICATED QUOTATIONS — 6 of 15 BCs (40%) attribute quoted text to capabilities.md that does not appear there: BC-2.12.002.md:79 (CLICOLOR appears NOWHERE in capabilities.md), BC-2.12.003.md:81 ("summary line" 0 hits), BC-2.12.004.md:78 ("--format text" 0 hits), BC-2.13.002.md:74 ("schema stability" 0 hits), BC-2.14.002.md:80 ("fail-fast" 0 hits in capabilities.md), BC-2.11.001.md:85/BC-2.11.004.md:82 (quotes DD-008 where capabilities.md:183 says DD-013). In two cases the fabrication CONCEALS a real L2 gap: CAP-012 does not authorize the CLICOLOR_FORCE behaviour BC-2.12.002 PC5 specifies.

**P6-S5-014** (POLICY 16) Both trap citations in scope are wrong: BC-2.12.001.md:70 cites T15 for deterministic sort (T15 is forward heading reference) and BC-2.11.002.md:98,:106 cites T16 for --allow component boundary (T16 is path above scan root, and test-vectors.md:310 marks it NOT-COVERED — so a VP is cited as satisfying a trap that is formally open).

**P6-S5-015** (POLICY 16) The R6->R5 correction landed on BC-2.11.002/003 and not on BC-2.11.001.md:88 or BC-2.11.004.md:85, so two of four filter BCs are anchored to the OUTPUT requirement.

**P6-S5-016** (POLICY 4) The 3->4-field sort-key fix propagated to DI-001, ADR-005, api-surface and both output BCs but NOT to capabilities.md:203-204 (CAP-012), :217 (CAP-013) or decisions.md:90 (DD-012) — under the still-published 3-field key the key is NOT TOTAL and `sort_unstable_by` becomes nondeterministic, and CAP-012 is the capability BC-2.12.001 anchors to.

**P6-S5-017** BC-2.12.004 asserts repeated `--format` last-wins in an EC and a VP row but in no postcondition; interface-definitions.md:45 gives `--format` arity `once` then :47 defines repeat semantics — incoherent.

**P6-S5-018** (POLICY 14) EIGHT of 15 BCs use `—` in the VP-NNN column = zero VP coverage, cross-confirmed by VP-INDEX having no row for any of them; uncovered are stdout/stderr separation (the PRIMARY persona's core contract), colour/NO_COLOR/TTY, the always-emitted summary, invalid `--format`, invalid glob, `--help/--version`, JSON schema stability (the NFR-007 anchor), and `--ignore`-over-explicit-PATH. check-placeholders.py greps the literal `VP-TBD` so it reports clean.

**P6-S5-019** (POLICY 4) VP property descriptions contradict what the cited VPs prove in BC-2.12.001.md:71, BC-2.13.001.md:88-90 (three distinct properties laundered through VP-021), BC-2.11.001.md:80, BC-2.11.002.md:98-99 — VP-021 is the SOLE vehicle for NFR-007 closed-taxonomy conformance and is cited four times, never once for that.

**P6-S5-020** (POLICY 16 reverse) Three documented interface behaviours have NO owning BC anywhere: `--` end-of-options (zero hits in behavioral-contracts/; security-relevant for argument injection and for scanning a file literally named `--online.md`), unknown flag -> exit 2 (only as a negated precondition), repeated `--format` last-wins.

**P6-S5-021** (POLICY 19) Phantom E-CLI-001 at BC-2.11.004.md:59 and E-IO-002 at BC-2.01.009.md:43,:51,:70,:72 + interface-definitions.md:237; BC-2.01.009.md:23 even records a MIGRATION BETWEEN TWO PHANTOM IDS.

---

## MEDIUM Findings

**P6-S5-022** BC-2.12.002.md:54 keys STDERR colouring off STDOUT's TTY status, so `mdlinkcheck 2> err.log` writes ANSI bytes into err.log — the exact contamination class DD-014 names; also uses permissive "may" in a normative invariant.

**P6-S5-023** `errors[]` "always present" (BC-2.13.001.md:45-46,:63) vs "omitted or empty" (interface-definitions.md:174,:182); Inv7 also claims it "was present from schema_version 1" while the v1.1 changelog says it was ADDED under F-013.

**P6-S5-024** BC-2.13.002 (JSON Schema Stability) covers only `results` objects — the error-object shape and `sub_reason` have no stability guarantee and the sole vector never asserts errors is an array.

**P6-S5-025** (POLICY 1/16) Unregistered pseudo-EC ids EC-NEW-10..EC-NEW-16 and EC-073b appear ONLY in the four BCs that declare them; EC-073b is the unfixed sibling of a documented EC-073->EC-193 rename; check-id-resolution.py matches `EC-\d+` so these are silently SKIPPED, not reported unresolvable.

**P6-S5-026** BC-2.11.004.md:43-44 defers empty-glob behaviour to the implementer inside a P0 exit-code contract (`--ignore ''` is one typo from ordinary usage; globset actually accepts "" as valid-matching-nothing so the "invalid glob" framing is likely wrong on the facts).

**P6-S5-027** BC-2.13.001.md:53 makes the trailing newline implementation-defined, so two conforming implementations emit different bytes and every golden-file JSON test is unspecified; contrast BC-2.12.001.md:54 which commits to byte-identity for text.

**P6-S5-028** The acceptance-corpus criterion (interface-definitions.md:305) sorts on THREE fields and normalizes before comparing, dropping the `link_target` tie-break BC-2.13.001 PC4 requires — and invariants.md:67-71 warns that sorting/normalizing before comparison DESTROYS the property under test; net effect JSON ordering has no non-order-destroying vehicle.

**P6-S5-029** BC-2.13.001's Description is stale post-F-013 (still describes only `schema_version + results`, so a story-writer summarizing it never learns `errors[]` exists) and lacks BC-2.12.001's byte-identity invariant.

**P6-S5-030** (POLICY 4/16) DD-007/DD-013/DD-014 Resolves columns cite ECs owned by unrelated BCs — DD-013 and DD-014's citations appear swapped or offset wholesale — and DD-013 still cites EC-092 which was renamed to EC-163.

**P6-S5-031** DI-001's byte-identity claim has no carve-out for the colour axis BC-2.12.002 introduces (TTY-ness and NO_COLOR/CLICOLOR/CLICOLOR_FORCE are neither inputs nor flags yet determine stdout bytes); VP-011's method runs piped so colour is off and the axis is never exercised.

**P6-S5-032** (POLICY 2) Five BCs omit the L2 Domain Invariants ROW entirely (BC-2.11.002, BC-2.12.002/003/004, BC-2.13.002) — a missing row and an explicit `—` are different failure modes and both defeat POLICY 2's bidirectional check.

---

## Exit-Code Precedence Verdict

**The NUMERIC precedence relation is sound and total** and consistently maps indeterminate to "never raises the exit code" in all seven places checked — that part is CONVERGED. What is not complete is the DOMAIN of the three inputs to `verdict::exit_code(findings, io_errors, config_error)`:

1. The `io_errors`/`config_error` partition for a nonexistent PATH is contested between CAP-014 and all three SS-14 BCs.
2. `config_error` membership is enumerated THREE different ways (BC-2.14.001/003 list two members and omit invalid `--format` which BC-2.12.004 independently routes to exit 2; CAP-014 lists four).
3. `--help/--version` sits outside the lattice entirely and collides with it, and `verdict::exit_code` has no fourth input so the short-circuit must live in cli.rs which no BC states.
4. Standalone exit 2 has no owning contract in SS-14.

**Minimum to close:** one adjudicating decision fixing the partition and propagating to CAP-014 + all three SS-14 BCs; publishing one canonical `config_error` list; stating `--help/--version` precedence and its enforcement point; either widening BC-2.14.002 or adding a new SS-14 BC for standalone exit 2; adding a reason code (or an explicit "no code, `errors[]` stays empty" ruling) for usage errors; retiring E-CLI-001 and E-IO-002.
