---
document_type: adversarial-synthesis
level: ops
version: "1.1"
status: final
producer: state-manager
timestamp: 2026-08-07T02:30:00Z
cycle: phase-1d
pass: 5
frozen_head: 1d3ed17
shards_complete: "1,2,3,4,5,6,7,8"
findings_total: 259
findings_critical: 40
inputs:
  - cycles/phase-1d/perimeter-sweep-shard-1.md
  - cycles/phase-1d/perimeter-sweep-shard-2.md
  - cycles/phase-1d/perimeter-sweep-shard-3.md
  - cycles/phase-1d/perimeter-sweep-shard-4.md
  - cycles/phase-1d/perimeter-sweep-shard-5.md
  - cycles/phase-1d/perimeter-sweep-shard-6.md
  - cycles/phase-1d/perimeter-sweep-shard-7.md
  - cycles/phase-1d/perimeter-sweep-shard-8.md
input-hash: "f1f33cd"
traces_to: STATE.md
---

# Perimeter Sweep Cross-Shard Synthesis — phase-1d

**Shards complete:** 1, 2, 3, 4, 5, 6, 7, 8 — SWEEP COMPLETE
**Findings total:** 259 (40 CRITICAL) [^crit-correction]
**Frozen HEAD:** `1d3ed17`

[^crit-correction]: CI-062 correction 2026-08-07: prior figure "~42" was unreconcilable with
this document's own per-shard C-column subtotals (2+4+7+7+6+2+6+6 = 40). Corrected to 40.
An independent per-finding severity recount across all 8 shards is NOT obtainable by any
single predicate: severity vocabularies are inconsistent across shards (shard-1 uses
CRITICAL/MAJOR/MINOR; others use CRITICAL/HIGH/MEDIUM; shards 4 and 8 also carry LOW), and
naive section-based attribution double-counts cross-referenced IDs. Only shard-1 has a
self-declared severity roster table that is internally consistent (2+13+12 = 27 = shard-1's
27 unique IDs). The per-shard C-column subtotals in the table below are the best available
oracle. The inconsistent severity vocabulary is recorded as PG-012 in
`cycles/phase-1d/process-gap-register.md`.

---

## THE SKIP LIST IS DEMONSTRABLY UNSOUND — highest-priority governance conclusion

Pass 5 ran with 8 classes on the skip list on the belief they were mutation-verified. Four independent shards have now found STRUCTURAL HOLES in two of them:

**1. `check-placeholders.py` greps the LITERAL string `VP-TBD`.** An em-dash `—` in the VP-NNN column defeats it entirely. Shard 5 found 8 of 15 BCs with zero VP coverage passing as clean; shard 2 found 4 of 6 SS-03 BCs. Uncovered contracts include stdout/stderr separation (the PRIMARY CI-engineer persona's core contract), JSON schema stability (the NFR-007 anchor), and BC-2.03.003 which is the SOLE owner of a closed-taxonomy reason code AND carries a CRITICAL defect.

**2. `check-id-resolution.py` has two independent bypass paths:**
- (a) SYNTHESISES `EC-NNNa..EC-NNNz` as registered whenever base `EC-NNN` appears anywhere, with NO description comparison — so EC-028b ("symlink") passes against base EC-028 (link-title stripping), and EC-015b passes though POL-16 retired it in favour of EC-178.
- (b) Matches only `EC-\d+`, so `EC-NEW-10..16` and `EC-073b` are SILENTLY SKIPPED rather than reported unresolvable. Shards 1, 3 and 5 each found instances independently.

**CONSEQUENCE:** Pass 5's skip list excluded defect classes that were never actually enforced. D-050's mutation-verification admission criterion is necessary but NOT sufficient — a mutation test proves the checker can fail on the input shape it recognises; it cannot reveal input shapes the regex never matches.

**RECOMMENDATION:**
- (a) Remove "ID resolution" and "placeholders" from the skip list, or narrow them to "ID EXISTENCE for conforming shapes".
- (b) Require every checker to emit a POSITIVE COVERAGE count (POLICY 11 style: "N citations validated, 0 non-conforming") rather than absence-of-known-string.
- (c) Add a meta-check that every occurrence of a canonical fact has a binding, since P5-030 showed the one wrong sort-key site had no binding at all.

---

## THREE UNGUARDED AXES WITH NO CHECKER AT ALL (each produced multiple CRITICALs)

**A. VP `Proof Method` / `Property` vs VP-INDEX's `tool` / subject.** Nothing joins them. Instances: 6 of 6 SS-14 rows turning Kani P0 into "unit test" (P6-S5-006); 5 rows in shard 2 (P6-S2-005, P6-S2-008); 3 in shard 3 (P6-S3-007, P6-S3-017). Effect: P0 formal proofs silently become example-based tests while the coverage matrix reports Yes. This is a one-line mechanical join and is the single highest-leverage gap found.

**B. Quoted excerpts inside resolvable citations (POLICY 5, lint_hook: null).** Shard 5 found a 40% fabrication rate (6 of 15 BCs quoting capabilities.md text that does not exist); shard 2 found BC-2.06.002 fabricating a CAP-006 quote that DROPS the words "0-based" and the while-loop form — the only capability-level guards against FM-002. Mechanically checkable: extract every `("...")` in a `per <file> §<ID>` row and assert substring presence in the named section.

**C. Factual claims about third-party library semantics.** Three of shard 2's four CRITICALs are here: pulldown-cmark's broken_link_callback return contract, `Options::ENABLE_FOOTNOTES` defaulting off (and the parser Options bitmask being unspecified ANYWHERE in the corpus), and CommonMark HTML-block start conditions for `<code>`/`<pre>`. No checker can validate these and they sit directly under the CRITICAL-tier extraction module.

---

## CORROBORATION ACROSS INDEPENDENT SHARDS (raises confidence to near-certain)

- **E-IO-002 / E-CLI-001 phantom reason codes + NO code for a nonexistent PATH:** found independently by pass 5 (P5-015), shard 1 (P6-S1-001) and shard 5 (P6-S5-005, P6-S5-021). Three independent discoveries.
- **`sub_reason` mandated but absent from the Finding struct:** pass 5 (P5-012) and shard 5 (P6-S5-002) and shard 6 (P6-S6-008).
- **`format_json` cannot emit the mandatory `errors[]`:** pass 5 (P5-011) and shard 5 (P6-S5-003).
- **`fs::canonicalize` forbidden by DI-002/DI-009/system-overview yet mandated by BCs:** shard 1 (P6-S1-002, SS-01) and shard 3 (P6-S3-019, SS-07 phantom canonicalize_logical()).
- **DirIndex population scope contradictory:** pass 5 (P5-003) and shard 3 (P6-S3-001), which adds that NO SS-07 BC constrains the one input the subsystem entirely depends on.
- **I/O errors described as "findings" on stdout:** shard 1 (P6-S1-006), shard 5 (P6-S5-004).
- **Missing `L2 Domain Invariants` rows:** shard 1 (6 of 13), shard 2 (BC-2.03.005), shard 3 (BC-2.07.005/006), shard 5 (5 of 15). Systemic, ~25% of BCs.
- **comrak parser constructor disagreement (P6-S2-001 / P6-S6-009):** feasibility-review says `Parser::new()`, purity-boundary-map says `Parser::new_with_broken_links()`. ADR-003's decisive comrak-rejection rationale depends on the correct answer.
- **ADR-005 DEP-001 stale open:** pass 5 (P5-008) and shard 6 (P6-S6-020).

---

## THE S-7.01 PARTIAL-FIX CLASS IS THE DOMINANT GENERATOR

Pass 5 already tagged this a [process-gap] with 6 instances. Shards add many more, including cases where the REMEDIATION ITSELF introduced the error: ADR-006 v1.1's changelog claims it "corrected T12 cross-reference to T8" — T8 is the wrong trap, on the very trap that motivates the macOS-only gatekeeper (P6-S3-022); and BC-2.07.003 v1.3's D-043 edit REGRESSED VP-008's proof method from proptest to "integration test", undoing ADR-006 v1.1's explicit fix (P6-S3-017). prd.md:674 enumerates D-016's propagation set verbatim and it is demonstrably incomplete (P6-S5-002). prd.md:804-805's deliberate "R2b -> R5 throughout" created the 18-BC R5 scramble (shard 8). prd.md:545's D-043 replacement text introduced the false-negative-in-a-false-positive-list defect (shard 8). prd.md:647 and :651 both CLAIM classes were fixed that demonstrably were not (shard 8).

**RECOMMENDATION (adversary's, endorsed):** A Phase-1 gate check that every P4-NNN/INC-NNN handoff item names BOTH the target artifact AND the flagging artifact, and that both are touched in the same commit.

---

## PER-SHARD YIELD

| Shard | Scope | Bodies | C | H | M | Total | Verdict |
|-------|-------|--------|---|---|---|-------|---------|
| 1 | SS-01/02 | 13 | 2 | 13 | 12 | 27 | — |
| 2 | SS-03/04 + BC-2.06.002 | 10 | 4 | 7 | 13 | 24 | — |
| 3 | SS-07 | 8 | 7 | 12 | 9 | 28 | must NOT enter Phase 2 |
| 4 | SS-08/09 + 3×SS-10 | 9 | 7 | 16 | 9 | 32 | DI-005 NOT airtight, breached 4 ways |
| 5 | SS-11/12/13/14 | 15 | 6 | 15 | 11 | 32 | exit-code input domain not complete |
| 6 | 5 ADRs + 4 arch shards | 9 | 2 | 19 | 11 | 32 | ADR-004 inadequate on starvation |
| 7 | 21 VP bodies | 21 | 6 | 25 | 13 | 44 | 5 VPs outright vacuous |
| 8 | domain-spec + brief + prd + test-vectors | 15 | 6 | 20 | 14 | 40 | R5 anchoring not defensible |
| **TOTAL** | | **100** | **40** [^crit-correction] | **~127** | **~92** | **259** | **FINDINGS_REMAIN** |

---

## SWEEP CLOSED — 259 findings, 40 CRITICAL [^crit-correction], across all 8 shards

Coverage achieved: all 66 of 66 BC bodies, 21 of 26 VP bodies, all 8 ADRs, all 11 architecture shards, all 11 domain-spec shards, product-brief, prd in full, test-vectors in full. The "~49 unread BC bodies + 5 unread ADRs" perimeter that survived five prior passes is now CLOSED.

## FOUR TOP-LEVEL CONCLUSIONS

### 1. THE VERIFICATION LAYER IS SUBSTANTIALLY NOTIONAL

Five VPs (VP-015/016/017/019/023) are satisfied by a no-op implementation and are the SOLE coverage for DI-008/DI-006/DI-009/DI-005, three of which VP-INDEX reports "All Covered? Yes". Only 9 of 21 audited VPs are non-vacuous. The Phase 6 gate could pass with four domain invariants unverified.

### 2. THE SKIP LIST WAS UNSOUND

check-placeholders greps the literal VP-TBD and is defeated by an em-dash (12+ BCs with zero VP coverage passing clean); check-id-resolution auto-synthesises EC-NNNa..z without description comparison and skips non-conforming shapes (EC-NEW-NN, EC-073b) entirely. D-050's mutation-verification criterion is NECESSARY BUT NOT SUFFICIENT — a mutation test proves a checker can fail on the shape it recognises; it cannot reveal shapes the regex never matches.

### 3. FOUR UNGUARDED AXES, each producing multiple CRITICALs

(a) BC VP-table Proof Method + Property text vs VP-INDEX — >=12 mis-described rows and 30+ wrong methods, closable by a one-line mechanical join, the HIGHEST-LEVERAGE FIX AVAILABLE.

(b) Quoted excerpts inside resolvable citations (POLICY 5 lint_hook null, 40% fabrication rate in one shard).

(c) Symbols inside ```rust code fences plus four types declared only in signatures with no definition anywhere.

(d) Discharged directives that are never closed — ~10 stale "must be updated / status: open / action required" flags across ADRs, feasibility-review and bc-module-map, several of which would cause a story-writer to do actively harmful work.

### 4. THE DOMINANT GENERATOR IS PARTIAL-FIX PROPAGATION

Remediations have themselves introduced defects: ADR-006 v1.1's changelog claims it "corrected T12 -> T8" (T8 is the wrong trap, on the very trap motivating the macOS-only gatekeeper); BC-2.07.003 v1.3's D-043 edit REGRESSED VP-008 from proptest to "integration test"; prd.md:563's range "fix" created the §4/§5/§6 EC overlap; prd.md:804-805's deliberate "R2b -> R5 throughout" created the 18-BC R5 scramble; prd.md:545's D-043 replacement text introduced the false-negative-in-a-false-positive-list defect. prd.md:647 and :651 both CLAIM classes were fixed that demonstrably were not.

## Open Blocking Issues (sweep-identified)

- Five vacuous VPs (VP-015/016/017/019/023) — verification layer notional
- BC-VP proof-method join — highest-leverage mechanical fix available
- POLICY 5 substantiation — lint_hook null, 40% fabrication rate in one shard
- Code-fence symbol validation + four undefined types
- Stale-directive class (~10 undischarged "must be updated" flags)
- SS-07 Phase-2 block — must NOT enter Phase 2 per shard 3
- Exit-code input-domain adjudication
- D-043 survivor list
- ADR-001 revision (retired seam design still live)
- ADR-004 revision (starvation mitigation inadequate)
