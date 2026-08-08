---
document_type: adversarial-index
level: ops
version: "1.0"
status: partial
producer: state-manager
timestamp: 2026-08-08T00:00:00Z
cycle: phase-1d
pass: 7
batch: 1
shards_complete: [9, 7, 8, 2]
shards_pending: [1, 3, 4, 5, 6]
traces_to: STATE.md
---

# Adversary Pass 7 — Batch-1 Index

> **STATUS: PARTIAL — Pass 7 is IN PROGRESS.**
> Batch 1 = shards 9, 7, 8, 2 COMPLETE. Batch 2 = shards 1, 3, 4, 5, 6 NOT YET DISPATCHED.
> Pass 7 MUST NOT be characterised as a completed perimeter pass until batch 2 lands.

## Frozen Perimeter

| Field | Value |
|---|---|
| develop HEAD | `f8ee4eb024b8b4a300139ef803d248e8fe40f2fc` |
| `specs/` tree | `ace1745871122cd1fa2c46cf27c5493cc1083411` |
| spec-lint tree | `f2392b456c3bd669e3efbe86b3e6eae62e302ed1` |
| Corpus size | 134 `.md` files, 66 BCs |

## Batch-1 Running Totals

| Metric | Self-Declared | Predicate-Parsed | Note |
|---|---|---|---|
| Total findings | 135 | 137 | +2 discrepancy isolated to shard 2 |
| CRITICAL findings | 20 | 21 | +1 discrepancy isolated to shard 2 |

Both totals preserved; discrepancy is isolated to shard 2 and unadjudicated (PG-012 class, no hand-recount per D-082).

## Verdict So Far

**NOT CLEAN — clean-pass streak remains 0 of 3.**

## Shard Table

| Shard | Scope | Bodies | Self-Decl Total | Self-Decl C/H/M/L | Verdict |
|---|---|---|---|---|---|
| 9 | never-read BC bodies (SS-05 ×3, SS-06 BC-2.06.001, SS-10 ×7) | 11 | 27 | 2/11/10/4 | verdict: NOT CONVERGED — the never-read shard contains two false-green verification defects (a Kani proof claimed for properties it does not assert; a "total partition" with a 400-value hole covering a full valid range) |
| 7 | verification layer (all 26 VP bodies + VP-INDEX) | 27 | 38 | 4/12/14/8 | verdict: The verification layer is structurally real but semantically porous — four false-green paths let a Phase-6 gate pass with the property unverified; the 2026-08-07 BI-025 vacuity-repair burst narrowed but did not close the gap |
| 8 | prd + domain-spec + supplements + 3 intake items | — | 49 | 5/16/21/7 | verdict: NOT CLEAN — two verification gates (POL-18 holdout boundary, POL-19 closed taxonomy) are structurally false-green and the corpus contains live instances of both; the frozen-brief requirement and six other HIGH findings are unresolved |
| 2 | SS-03 + SS-04 + SS-06 (11 BC bodies) | 11 | 21 *(disputed 23)* | 9/5/5/2 *(CRITICAL disputed 10)* | verdict: NOT CLEAN — nine CRITICAL defects, including three false-green VP tables (BC-2.03.002, BC-2.06.001, BC-2.06.002) that name formal Kani/proptest proofs for properties those proofs explicitly do not assert |

**Shard 2 dispute:** predicate-parsed 23 finding sections and 10 CRITICAL against self-declared 21 / 9 CRITICAL. Unadjudicated, PG-012 class, no hand-recount per D-082. See `adversary-pass-7-shard-2.md` frontmatter `findings_total_disputed`.

## Four Highest-Order Structural Findings (Batch 1)

These are structural false-green gates — checker blindness that lets live defects pass undetected:

1. **P7-S8-005** — `check-holdout-boundary.py` inspects only markdown table rows, so POLICY 18 is structurally blind to prose leaks.

2. **P7-S8-004** — Live consequence of the above: `prd.md:616` publishes the complete input + expected-output scenario for **active reserved holdout EC-151**, breaching holdout-pool integrity for Phase 4.

3. **P7-S8-006** — `check-adr-consistency.py` (sole POLICY 19 hook) reads only `architecture/decisions/ADR-*.md`, so closed-taxonomy enforcement never inspects BCs or test-vectors.

4. **P7-S8-007** — Live consequence of the above: phantom reason code `malformed-fragment` at `test-vectors.md:432`.

## Batch-2 Pending Shards

Shards 1, 3, 4, 5, 6 not yet dispatched. This index will be updated when batch 2 completes and pass 7 can be declared a perimeter pass.

## Shard Report Files

| File | Shard | Status |
|---|---|---|
| `adversary-pass-7-shard-9.md` | 9 | COMPLETE |
| `adversary-pass-7-shard-7.md` | 7 | COMPLETE |
| `adversary-pass-7-shard-8.md` | 8 | COMPLETE |
| `adversary-pass-7-shard-2.md` | 2 | COMPLETE |
| `adversary-pass-7-shard-1.md` | 1 | NOT YET DISPATCHED |
| `adversary-pass-7-shard-3.md` | 3 | NOT YET DISPATCHED |
| `adversary-pass-7-shard-4.md` | 4 | NOT YET DISPATCHED |
| `adversary-pass-7-shard-5.md` | 5 | NOT YET DISPATCHED |
| `adversary-pass-7-shard-6.md` | 6 | NOT YET DISPATCHED |
