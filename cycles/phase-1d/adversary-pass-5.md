---
document_type: adversary-pass-record
status: archive-partial
cycle: phase-1d
producer: state-manager
timestamp: 2026-08-07T00:00:00Z
inputs:
  - cycles/phase-1d/perimeter-sweep-synthesis.md
  - cycles/phase-1d/perimeter-sweep-shard-1.md
  - cycles/phase-1d/perimeter-sweep-shard-3.md
  - cycles/phase-1d/perimeter-sweep-shard-4.md
  - cycles/phase-1d/perimeter-sweep-shard-6.md
  - cycles/phase-1d/perimeter-sweep-shard-8.md
input-hash: "[live-state]"
traces_to: cycles/phase-1d/convergence-trajectory.md
---

# Adversarial Findings — Phase 1d — Pass 5 (Gate #12)

## PARTIAL RECONSTRUCTION — RECORD GAP NOTICE

**This file was created by a CI-062 record-integrity maintenance burst on 2026-08-07.**

The original adversary-pass-5.md record was **never persisted** to factory-artifacts. The
adversary ran (it is referenced repeatedly in cross-shard corroboration notes and in
SESSION-HANDOFF.md), but no report file was committed. This document was rebuilt by
scanning all surviving artifacts for P5-* ID citations.

**Recovery result:** 10 of 36 (or 37 — see COUNT DISPUTE below) findings are recoverable
from cross-references. **26 findings are permanently lost** — no text, severity, or
artifact target for them exists anywhere in the corpus. Finding bodies for the 10
recovered entries are NOT reconstructed here; only the verbatim cross-reference text that
confirms existence of each ID is recorded.

**No finding text, severity, or file target has been invented for any ID.**

---

## COUNT DISPUTE — DO NOT RESOLVE WITHOUT OPERATOR RULING

The recorded pass-5 total is cited inconsistently in the register:

- **SESSION-HANDOFF.md §D-057** (line 562): "Pass 5 (36 findings)"
- **SESSION-HANDOFF.md §D-057** (line 576): "Frozen pass-5 HEAD | `1d3ed17` | reference HEAD for the 36-finding pass-5 report"
- **burst-log.md D-086 re-derivation** (line 866): `"36 pass-5 actionable"→37` — D-086 executed-predicate re-derivation corrected the count from 36 to 37.

**Both figures are recorded here. Neither is adopted as authoritative.** The operator must
adjudicate. See also PG-011 for the related pass-numbering collision.

Highest surviving ID: P5-036. This is consistent with a 36-finding total, and would
require one ID gap if the total is 37.

---

## PASS-NUMBERING COLLISION WARNING (FLAG FOR OPERATOR — NOT RESOLVED HERE)

The perimeter-sweep shard files title themselves "Pass 5" (example:
`perimeter-sweep-shard-1.md` line 22: `# Adversarial Findings — Phase 1d — Pass 5 — Shard
1 / 8`) but their finding IDs are prefixed **`P6-S<n>-<nnn>`** (pass SIX). The gate #12
pass documented here uses `P5-*` IDs and is a genuinely distinct finding population that
predates the perimeter sweep. "Pass 5" currently denotes two different finding populations
in the register. STATE.md's claim that pass 6 has not yet run sits uneasily with a
P6-prefixed corpus of 249 findings already on disk. Recorded as PG-011 in
`cycles/phase-1d/process-gap-register.md`. **No renumbering performed.**

---

## RECOVERED FINDINGS — 10 of 36 (or 37)

Findings are listed by ID. For each, the verbatim cross-reference text from the
surviving source file is quoted exactly. No paraphrase or inference of finding body
content is added.

---

### P5-001

| Field | Value |
|-------|-------|
| ID | P5-001 |
| Severity | unrecorded |
| Recovery source | `cycles/phase-1d/perimeter-sweep-shard-4.md` line 62 |

**Verbatim cross-reference text (from P6-S4-006 body):**

> BC-2.10.010.md:43-44,:56-61 blocks 127.0.0.0/8 and ::1/128 BEFORE any request with no
> test carve-out, while dtu-assessment.md:230,:260-262 builds every fixture on 127.0.0.1.
> Kills all five BC-2.10.001 vectors, all three BC-2.10.006 TLS vectors,
> BC-2.10.005's sole vector, the 11-row Phase-3 coverage table, and the DTU_REQUIRED:false
> conclusion resting on it. Worst-case outcome: an implementer "fixes" it by weakening the
> private-IP guard, silently removing the SSRF protection. CORROBORATES pass-5 P5-001.

---

### P5-002

| Field | Value |
|-------|-------|
| ID | P5-002 |
| Severity | unrecorded |
| Recovery source | `cycles/phase-1d/perimeter-sweep-shard-8.md` line 52 |

**Verbatim cross-reference text (from P6-S8-005 body):**

> DD-015 step 3 ("remove non-`\p{Word}`") and DI-012's claim that `\p{Mn}` is "not a
> `\p{Word}` character" are mutually contradictory under UTS#18 — `\p{Mn}` ⊂
> `\p{gc=Mark}` ⊂ `\p{word}`, and Rust's regex implements UTS#18 — so the literal
> DD-015 step RETAINS NFD combining marks, the opposite of DI-012's stated consequence,
> failing VP-026 OR-010. vp-026:130's "the oracle wins" clause papers over it by deferring
> to a fixture that does not exist yet. Also: github-slugger's actual mechanism is a
> punctuation/symbol BLOCKLIST, not a `\p{Word}` complement, so DD-015 mis-describes the
> algorithm it claims to quote verbatim. CORROBORATES pass-5 P5-002.

---

### P5-003

| Field | Value |
|-------|-------|
| ID | P5-003 |
| Severity | unrecorded |
| Recovery source | `cycles/phase-1d/perimeter-sweep-shard-3.md` line 38 (primary); `cycles/phase-1d/perimeter-sweep-synthesis.md` line 70 (secondary) |

**Verbatim cross-reference text (shard-3, primary):**

> CORROBORATES pass-5 P5-003. REQUIRES ARCHITECT/HUMAN ADJUDICATION BEFORE ANY OTHER
> SS-07 FIX — BC-2.07.002 postconditions, BC-2.07.003 preconditions, BC-2.07.005/006
> routing and DI-009's bound all depend on the answer.

**Verbatim cross-reference text (synthesis, secondary):**

> DirIndex population scope contradictory: pass 5 (P5-003) and shard 3 (P6-S3-001), which
> adds that NO SS-07 BC constrains the one input the subsystem entirely depends on.

---

### P5-004

| Field | Value |
|-------|-------|
| ID | P5-004 |
| Severity | unrecorded |
| Recovery source | `cycles/phase-1d/perimeter-sweep-shard-8.md` line 88 |

**Verbatim cross-reference text (from P6-S8-013 body):**

> The claimed enforcer BC-2.05.003 cites DI-008 instead. DI-007 governs the only
> carve-out from the frozen "no HTML parsing" non-goal. CORROBORATES pass-5 P5-004.

---

### P5-008

| Field | Value |
|-------|-------|
| ID | P5-008 |
| Severity | unrecorded |
| Recovery source | `cycles/phase-1d/perimeter-sweep-shard-6.md` line 80 (primary); `cycles/phase-1d/perimeter-sweep-synthesis.md` line 74 (secondary) |

**Verbatim cross-reference text (shard-6, primary, from P6-S6-020 body):**

> ADR-005's frontmatter `open_dependencies: DEP-001 status: open` was DISCHARGED by
> BC-2.03.002 v1.3, which delivered MORE than asked (PC7, Invariant 4, EC-202, a canonical
> vector). Three body cross-references still read as open, so DI-001's sort-key totality
> argument — the basis for sort_unstable_by safety — reads as conditional on an unmet
> precondition. CORROBORATES pass-5 P5-008.

**Verbatim cross-reference text (synthesis, secondary):**

> ADR-005 DEP-001 stale open: pass 5 (P5-008) and shard 6 (P6-S6-020).

---

### P5-011

| Field | Value |
|-------|-------|
| ID | P5-011 |
| Severity | unrecorded |
| Recovery source | `cycles/phase-1d/perimeter-sweep-synthesis.md` line 68 |

**Verbatim cross-reference text:**

> `format_json` cannot emit the mandatory `errors[]`: pass 5 (P5-011) and shard 5
> (P6-S5-003).

---

### P5-012

| Field | Value |
|-------|-------|
| ID | P5-012 |
| Severity | unrecorded |
| Recovery source | `cycles/phase-1d/perimeter-sweep-synthesis.md` line 67 (primary); `cycles/phase-1d/perimeter-sweep-shard-6.md` line 56 (secondary) |

**Verbatim cross-reference text (synthesis, primary):**

> `sub_reason` mandated but absent from the Finding struct: pass 5 (P5-012) and shard 5
> (P6-S5-002) and shard 6 (P6-S6-008).

**Verbatim cross-reference text (shard-6, secondary, from P6-S6-008 body):**

> `sub_reason` is part of the public --format json contract per BC-2.10.002.md:52-55
> (D-016) but appears ZERO times in ADR-007 — the document that declares itself
> authoritative for the verdict/reason model — and is absent from api-surface.md:121-123's
> Finding struct and from the JSON schema at :131-139. BC-2.10.002:55 has to pre-emptively
> state "VP-021 does NOT check sub_reason values" precisely because the schema does not
> know about it. CORROBORATES shard 5 P6-S5-002 and pass-5 P5-012.

---

### P5-015

| Field | Value |
|-------|-------|
| ID | P5-015 |
| Severity | unrecorded |
| Recovery source | `cycles/phase-1d/perimeter-sweep-shard-1.md` line 39 (primary); `cycles/phase-1d/perimeter-sweep-synthesis.md` line 66 (secondary) |

**Verbatim cross-reference text (shard-1, primary):**

> independently corroborates pass-5 finding P5-015.

**Verbatim cross-reference text (synthesis, secondary):**

> E-IO-002 / E-CLI-001 phantom reason codes + NO code for a nonexistent PATH: found
> independently by pass 5 (P5-015), shard 1 (P6-S1-001) and shard 5 (P6-S5-005,
> P6-S5-021). Three independent discoveries.

---

### P5-030

| Field | Value |
|-------|-------|
| ID | P5-030 |
| Severity | unrecorded |
| Recovery source | `cycles/phase-1d/perimeter-sweep-synthesis.md` line 50 |

**Verbatim cross-reference text:**

> Add a meta-check that every occurrence of a canonical fact has a binding, since P5-030
> showed the one wrong sort-key site had no binding at all.

---

### P5-036

| Field | Value |
|-------|-------|
| ID | P5-036 |
| Severity | unrecorded |
| Recovery source | `cycles/phase-1d/perimeter-sweep-shard-6.md` line 108 (in P6-S6-032 body) |

**Verbatim cross-reference text:**

> nfr-catalog.md:122 names module `slug_compute`, which does not exist (module is `slug`;
> the function is `compute_slug`). CORROBORATES pass-5 P5-036.

---

## UNRECOVERABLE FINDINGS — 26 of 36 (or 27 of 37)

The following P5-* IDs appear nowhere in the surviving corpus. No text, severity,
artifact target, or any other attribute is recoverable for them.

P5-005, P5-006, P5-007, P5-009, P5-010, P5-013, P5-014,
P5-016, P5-017, P5-018, P5-019, P5-020, P5-021, P5-022,
P5-023, P5-024, P5-025, P5-026, P5-027, P5-028, P5-029,
P5-031, P5-032, P5-033, P5-034, P5-035

If the true total is 37 rather than 36, then exactly one additional ID exists that is
also unrecoverable (it would be in the complement of P5-001..P5-036 within the range
P5-001..P5-037, i.e., P5-037 — but this cannot be confirmed since no P5-037 reference
appears in the corpus).

---

## Summary

| Metric | Value |
|--------|-------|
| Highest surviving P5-* ID | P5-036 |
| Reported total (SESSION-HANDOFF) | 36 |
| Reported total (burst-log D-086 re-derivation) | 37 |
| Recoverable findings | 10 |
| Unrecoverable findings | 26 (or 27 if total is 37) |
| Finding bodies reconstructed | 0 — none invented |
| Severity values recorded | 0 — all unrecorded |
| Original report persisted | NO — record gap; this is reconstruction only |
