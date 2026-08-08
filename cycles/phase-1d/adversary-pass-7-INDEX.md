---
document_type: adversarial-index
level: ops
version: "2.0"
status: final
producer: state-manager
timestamp: 2026-08-08T16:00:00Z
cycle: phase-1d
pass: 7
batch: all
shards_complete: [1, 2, 3, 4, 5, 6, 7, 8, 9]
shards_pending: []
traces_to: STATE.md
---

# Adversary Pass 7 — Complete Index (All 9 Shards)

> **STATUS: COMPLETE — all 9 shards.**
> Pass 7 is the FIRST genuine full-perimeter pass: all 66 of 66 BC bodies, all 26 of 26 VP bodies,
> all 8 ADRs, all 11 architecture docs, all 12 domain-spec shards, prd.md and all 4 supplements.
> Verdict: **NOT CLEAN. Clean-pass streak remains 0 of 3.**

## Frozen Perimeter

| Field | Value |
|---|---|
| develop HEAD | `f8ee4eb024b8b4a300139ef803d248e8fe40f2fc` |
| `specs/` tree | `ace1745871122cd1fa2c46cf27c5493cc1083411` |
| spec-lint tree | `f2392b456c3bd669e3efbe86b3e6eae62e302ed1` |
| Corpus size | 134 `.md` files, 66 BCs, 26 VPs, 8 ADRs, 11 architecture docs |

## Definitive Totals

| Metric | Self-Declared | Predicate-Parsed | Note |
|---|---|---|---|
| Total findings | 273 | 275 | **Report as range: 273–275** (PG-012) |
| CRITICAL | 44 | 45 | +1 isolated to shard 2 dispute |
| HIGH | 97 | 97 | reconciles exactly |
| MEDIUM | 98 | 99 | +1 isolated to shard 2 dispute |
| LOW | 34 | 34 | reconciles exactly |
| `[process-gap]`-tagged | 20 | 20 | across all 9 shards |

**Disputed shard:** Shard 2 only. Self-declared 21 findings / 9 CRITICAL; predicate-parsed 23 / 10 CRITICAL.
All eight other shards reconcile exactly. No hand-recount (D-082).

## Per-Shard Table

| Shard | Scope | Bodies/Docs | Self-Decl Total | Self-Decl C/H/M/L | Pred-Parsed Total | Pred C/H/M/L | Verdict (verbatim from shard file) |
|---|---|---|---|---|---|---|---|
| 1 | SS-01 (9) + SS-02 (4) = 13 BC bodies | 13 | 31 | 3/11/14/3 | 31 | 3/11/14/3 | verdict: NOT converged — three CRITICAL contradictions (fs::canonicalize mandate, Parser::new() mandate that makes a closed-taxonomy reason code unreachable, phantom E-IO-002 error code) plus eleven HIGH contradictions/coverage gaps in the discovery and parsing perimeter. |
| 2 | SS-03 (6) + SS-04 (3) + SS-06 (2) = 11 BC bodies | 11 | 21 *(disputed 23)* | 9/5/5/2 *(CRITICAL disputed 10)* | 23 | 10/5/6/2 | verdict: NOT CLEAN — nine CRITICAL defects, including three false-green VP tables (BC-2.03.002, BC-2.06.001, BC-2.06.002) that name formal Kani/proptest proofs for properties those proofs explicitly disclaim, an inverted pulldown-cmark broken-link-callback contract that makes `undefined-reference-definition` unreachable, a non-total link-kind classification rule, and 11 of 12 SS-06 edge-case IDs mis-anchored against the canonical test-vector registry. |
| 3 | SS-07 = 8 BC bodies | 8 | 25 | 5/10/7/3 | 25 | 5/10/7/3 | verdict: SS-07 is the highest-risk subsystem in the corpus and cannot be decomposed into implementation stories until the fragment-decode inversion, the two false-green VP rows, the EC-187 verdict inversion, the intermediate-path-component hole, and the three DI-005 totality holes are resolved. |
| 4 | SS-08 (4) + SS-09 (2) + BC-2.10.001/005/006 = 9 BC bodies | 9 | 25 | 6/10/8/1 | 25 | 6/10/8/1 | verdict: NOT CONVERGED — six false-green/no-verdict CRITICALs including a systemic edge-case-registry mis-anchoring block (16 of 24 EC citations in this shard denote a different scenario than the canonical registry) and a phantom reason code invisible to the only POLICY 19 hook. |
| 5 | SS-11 (4) + SS-12 (5) + SS-13 (2) + SS-14 (4) = 15 BC bodies | 15 | 30 | 7/10/11/2 | 30 | 7/10/11/2 | verdict: NOT CLEAN — the shard's edge-case ID layer is systematically de-anchored from the canonical EC registry (19 of 36 EC rows resolve to a different scenario, one of them an outright exit-0-vs-exit-2 contradiction), the JSON contract cannot carry a field the corpus requires, four VP-table rows claim coverage their VP bodies do not assert, and BC-2.11.001 PC4 states the exact opposite of the --ignore-wins rule the sibling BC exists to specify. |
| 6 | 8 ADRs + 11 architecture docs = 19 documents | 19 | 27 | 3/12/8/4 | 27 | 3/12/8/4 | verdict: NOT CONVERGED — three CRITICAL defects, including an architecture directive that would break the spec-lint gate on 33 BC files, an authoritative API surface that makes the sole DNS/TLS verification property unprovable, and an ADR whose decisive parser rationale is factually wrong about pulldown-cmark. |
| 7 | all 26 VP bodies + VP-INDEX (prior passes read only 21 of 26) | 27 | 38 | 4/12/14/8 | 38 | 4/12/14/8 | verdict: The verification layer is structurally real but semantically porous — four false-green paths let a Phase-6 gate pass with the property unverified; the 2026-08-07 BI-025 vacuity-repair burst never propagated to VP-INDEX or either architecture anchor doc; and 11 symbols/types named inside `rust` fences are declared nowhere in the workspace. |
| 8 | prd.md + product-brief + 12 domain-spec + 4 prd-supplements + 3 top-level assessments + 3 mandatory intake adjudications | — | 49 | 5/16/21/7 | 49 | 5/16/21/7 | verdict: NOT CLEAN — two verification gates (POL-18 holdout boundary, POL-19 closed taxonomy) are structurally false-green and the corpus contains live instances of both; the frozen-brief requirement anchors in prd.md §7 RTM disagree with the BC files at 19 of 66 rows; the JSON envelope contract is stated four incompatible ways. |
| 9 | SS-05 (3) + SS-06 BC-2.06.001 (1) + SS-10 ×7 = 11 never-before-read BC bodies | 11 | 27 | 2/11/10/4 | 27 | 2/11/10/4 | verdict: NOT CONVERGED — the never-read shard contains two false-green verification defects (a Kani proof claimed for properties it does not assert; a "total partition" with a 400-value hole covering the spec's own HTTP-999 case) plus a 20-row EC-registry mis-anchoring cluster that the EC-injectivity checker is structurally unable to detect. |

> **Shard 3 additional flag:** carries an explicit `phase_2_readiness: NOT SAFE` field in the shard body.
> SS-07 must not enter Phase-2 story decomposition until its five CRITICAL defects are resolved.

> **Shard 5 note:** `heading_level_variance` — shard 5 used `##` for finding headings where other shards
> used `###`; parse regex must tolerate both.

## Coverage Accounting

Pass 7 is the **first genuine full-perimeter pass** in the pipeline run.

**BC bodies:** 66 of 66 (100%)
- Batch 1: shards 9 (11 never-read), 2 (11 bodies), 7 (VPs only), 8 (docs only)
- Batch 2 additions: shard 1 (13), shard 3 (8), shard 4 (9), shard 5 (15), shard 6 (ADRs/arch docs)
- Gap filled by shard 9: SS-05 (3), SS-06 BC-2.06.001 (1), SS-10 full ×7 — 11 never-before-read BC bodies

**VP bodies:** 26 of 26 (100%)
- Prior passes (1–6) read only 21 of 26 VP bodies; shard 7 read all 26 + VP-INDEX.

**D-116 perimeter-closure retraction:** Pass 6's synthesis asserted "all 66 of 66 BC bodies" read;
an orchestrator-executed predicate over the pass-6 shard frontmatter proved it read **55 of 66**
BC bodies and **21 of 26** VP bodies. Pass 7 closes the gap.

## Deliberate Coverage Overlap

BC-2.06.001 was reviewed by BOTH shard 2 and shard 9. Both independently found the same VP-002
false-green defect (P7-S2-013 and P7-S9-001). This is **corroboration, not duplication** — two
shards with different scopes and fresh contexts reached the same finding independently, which
constitutes the strongest available evidence that the defect is real.

## Highest-Order Structural Findings (Predicate-Class CRITICALs)

These are structural false-green gates — checker blindness that lets live defects pass undetected:

1. **P7-S8-005** — `check-holdout-boundary.py` inspects only markdown table rows → POLICY 18
   structurally blind to prose leaks.
2. **P7-S8-004** — Live consequence: `prd.md:616` publishes the complete scenario for **active
   reserved holdout EC-151**, breaching Phase-4 holdout-pool integrity. (BI-049)
3. **P7-S8-006** — `check-adr-consistency.py` reads only `ADR-*.md` → closed taxonomy never
   enforced in BCs or test-vectors. (BI-050)
4. **P7-S5-017** — Process gap: EC mis-anchoring is a systemic pattern `check-ec-injectivity.py`
   structurally cannot detect (validates ID injectivity, not semantic agreement). (BI-051)
5. **P7-S6-001** — `bc-module-map.md` POL-14 Defect Report prescribes the value the POL-14
   checker REJECTS — acting on the directive would break spec-lint on 33 BC files. (BI-054)
6. **P7-S7-002** — VP-002 is an unfalsifiable P0 Kani proof that no compiling implementation can
   fail. (BI-052)
7. **P7-S3-001 / P7-S4-002** — Fragment percent-decode inversion: BC-2.07.004 and BC-2.08.001
   both FORBID percent-decoding the fragment, inverting DI-003, CAP-008, DEC-005, and prd.md. (BI-053)

## `[process-gap]` Tags

20 `[process-gap]`-tagged findings across 9 shards. The dominant process gap is the structural
inability of the existing checker suite to detect EC mis-anchoring (BI-051), confirmed
independently by shards 2, 4, 5, and 9.

## Verdict

**NOT CLEAN. Clean-pass streak remains 0 of 3 required.**

Remediation priorities (derived from CRITICAL counts):
1. EC mis-anchoring class (BI-051) — systemic, 3 shards independently measured
2. False-green VP attribution class (BI-052) — 6 shards, 16+ instances
3. `check-holdout-boundary` / EC-151 prose leak (BI-049)
4. `check-adr-consistency` closed-taxonomy gap (BI-050)
5. Fragment percent-decode inversion (BI-053)

Human scoping of pass-7 remediation is required before passes 8–9 can advance the streak.
The spec-lint REQUIRED flip is CONTRA-INDICATED until BI-049/050/051/052 are repaired (D-117).

## Shard Report Files

| File | Shard | Status | Bytes |
|---|---|---|---|
| `adversary-pass-7-shard-1.md` | 1 | COMPLETE | 73,137 |
| `adversary-pass-7-shard-2.md` | 2 | COMPLETE | — |
| `adversary-pass-7-shard-3.md` | 3 | COMPLETE | 58,487 |
| `adversary-pass-7-shard-4.md` | 4 | COMPLETE | 50,817 |
| `adversary-pass-7-shard-5.md` | 5 | COMPLETE | 66,657 |
| `adversary-pass-7-shard-6.md` | 6 | COMPLETE | 79,239 |
| `adversary-pass-7-shard-7.md` | 7 | COMPLETE | — |
| `adversary-pass-7-shard-8.md` | 8 | COMPLETE | — |
| `adversary-pass-7-shard-9.md` | 9 | COMPLETE | — |
