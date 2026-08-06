---
document_type: adversarial-review
level: ops
version: "1.0"
status: final
producer: adversary
phase: phase-1d
pass: 3
timestamp: "2026-08-05T00:00:00Z"
inputs:
  - .factory/specs/architecture/decisions/ADR-007-three-verdict-model.md
  - .factory/specs/behavioral-contracts/BC-INDEX.md
  - .factory/specs/behavioral-contracts/ss-10/BC-2.10.004.md
  - .factory/specs/prd-supplements/test-vectors.md
  - .factory/specs/prd.md
  - .factory/holdout-scenarios/HS-INDEX.md
  - .factory/policies.yaml
  - .factory/specs/verification-properties/VP-INDEX.md
  - .factory/specs/architecture/verification-coverage-matrix.md
  - .factory/specs/architecture/ARCH-INDEX.md
  - .factory/specs/prd-supplements/error-taxonomy.md
  - .factory/specs/domain-spec/failure-modes.md
input-hash: "296b02d"
traces_to: .factory/cycles/phase-1d/adversary-pass-2.md
previous_review: .factory/cycles/phase-1d/adversary-pass-2.md
---

## Provenance

The adversary agent authored these findings using a fresh-context, read-only tool
profile (`Read`, `Grep`, `Glob` only; `Write`, `Edit`, and `Bash` denied). It
reviewed the spec package without access to any prior review pass, session history,
or implementation artifacts. The spec-steward agent persisted this output from the
authoritative human-provided summary without editorial change — no findings were
reworded, reordered, softened, or summarized. This document is an evidence artifact
for the Phase 1d convergence loop.

Pass 3 focused on ADR-007 verdict/exit-code governance, the EC-ID namespace
injectivity property, the holdout boundary, D-020 test-burn coverage, and a
systematic re-sweep of policy adherence. Targeted greps were run across all ~130
spec files for EC collision detection, verdict-term audit, and github-slugger vector
spot-check; those are not enumerated as individual input paths because they are
search operations rather than full-read inputs.

---

# Adversarial Spec Review — Phase 1d, Pass 3

## Finding ID Convention

This pass uses the adversary's native prefix scheme: `P3-NNN`. All finding IDs are
preserved verbatim from the authoritative summary provided by the human reviewer;
they do not follow the `ADV-P3-NNN` template convention. All downstream routing and
fix-tracking uses the `P3-*` IDs as-is.

---

## Convergence Trajectory

```
Pass 1 → 32 novel findings
Pass 2 → 34 novel findings
Pass 3 → 39 novel findings  (NOVEL_FINDINGS: 39)

Clean-pass count: 0 of 3
Novelty direction: INCREASING, not decaying
```

**FINDINGS: 5 critical, 27 major, 7 minor**

This trajectory indicates the spec package has not converged. New finding classes
continued to emerge on each pass rather than shrinking toward zero. The convergence
loop cannot be closed on the current trajectory.

---

## Fix Verification — Unresolved Re-instances

Findings P3-003, P3-008, P3-013, and P3-016 are re-instances of defect classes
that were already codified as policies in the prior passes but were **never actually
remediated**. The policy rule was written; the underlying defect was not fixed:

| Finding | Re-instances | Policy codified | Remediation status |
|---------|-------------|-----------------|-------------------|
| P3-003 (CRITICAL) | EC-ID namespace not injective | POL-16 (`bc_traceability_id_resolution`, `lint_hook: null`) | Not remediated |
| P3-008 (MAJOR) | EC-NNN traceability ID collision — same class as P3-003 | POL-16 | Not remediated |
| P3-013 (MAJOR) | PRD§2 title ↔ BC H1 drift — same class as F-004 (pass 1) | POL-13 (`prd_section_title_bc_h1_sync`) | Not remediated |
| P3-016 (MAJOR) | Derived table counts drifted from source — same class as F-020 (pass 1) | POL-17 (`derived_tables_must_be_regenerated`) | Not remediated |

---

## CRITICAL

### P3-001 — ADR-007 classifies HTTP 400-after-GET-fallback as `broken`/exit 1, contradicting binding D-018 and all three taxonomy sources

**Files:** `.factory/specs/architecture/decisions/ADR-007-three-verdict-model.md:~67` (Ruling block) · `~74` (`http-indeterminate` omissions)

ADR-007 (`status: accepted`) line ~67 classifies HTTP 400-after-GET-fallback as
`broken`/exit 1. This contradicts binding decision D-018 and all three taxonomy
sources (error-taxonomy.md, failure-modes.md, prd.md §2 HTTP ruling). Line ~74
also omits 400-after-GET, connection-reset, private-ip, and https-downgrade from
the `http-indeterminate` category — leaving four cases unclassified in the ADR that
governs the verdict model.

**Failure scenario:** an implementer following the ADR's Ruling block emits
`broken`/exit 1 for a 400-after-GET response. An implementer following D-018 and
the taxonomy emits `indeterminate`/exit 0. The two implementations are
incompatible; acceptance corpus vectors cannot be authored for this case because the
spec authorities disagree, and no gate catches the ADR/D-018 conflict before
implementation begins.

**Owner:** architect

---

### P3-002 — ADR-007 defines `alive` as a verdict and mandates it in JSON output, contradicting binding D-014, error-taxonomy.md, DI-005, and BC-2.13.001 PC3; its Decision block lists four bullets under an H1 naming three

**Files:** `.factory/specs/architecture/decisions/ADR-007-three-verdict-model.md:~38/39` (H1 title) · `~45–46` (Decision block bullet count) · `~79` (JSON mandate)

ADR-007 lines ~38/39/45–46/79 define `alive` as a verdict and mandate emitting it
in JSON output. This contradicts binding decision D-014 (which resolves the
alive/clean naming question), error-taxonomy.md's closed verdict set, DI-005
(totality invariant), and BC-2.13.001 PC3. Additionally, the ADR's Decision block
H1 heading names three verdicts while the bullet list under it contains four — a
structural inconsistency in the normative section that determines which enumeration
an implementer treats as authoritative.

**Failure scenario:** the implementer reads ADR-007 (the highest-authority
architectural decision artifact) and introduces a four-variant enum including
`alive`. DI-005's totality invariant, written against a three-variant enumeration,
is violated by every correct online run. VP-007's Kani harness, which targets a
three-variant `VerdictKind`, cannot compile against the four-variant enum without
changes — but those changes are not traceable to any resolved spec decision.

**Owner:** architect

---

### P3-003 — The EC-ID namespace is not injective: ~60 collisions across ~30 BC files, six with opposite expected verdicts; `EC-060` carries three distinct meanings

**Files:** `.factory/specs/behavioral-contracts/` (all ~66 files) · `.factory/specs/prd-supplements/test-vectors.md`

The EC-ID namespace is **not injective**: approximately 60 collisions exist across
approximately 30 BC files, with six collisions yielding *opposite* expected verdicts
for the same ID. Confirmed examples:
- **EC-087:** `429 → indeterminate` in BC-2.10.004; `self-signed-TLS → broken` in test-vectors.md
- **EC-081, EC-088, EC-089, EC-142, EC-146:** similarly contradictory cross-file meanings
- **EC-060:** carries three distinct scenario meanings across three files

**Failure scenario:** a test-writer resolving EC-087 against the canonical registry
produces a test vector that the implementer reads as either 429-indeterminate or
self-signed-broken depending on which file they look at first. One of the six
opposite-verdict collisions will produce a false-green or false-red in the visible
test suite. The holdout boundary depends on the EC namespace being injective
(POL-18 greps for reserved EC IDs) — with ~60 collisions, any holdout ID adjacent
to a live collision zone is structurally unprotected.

**Owner:** product-owner. Requires one generated pass over all BC files, not
BC-by-BC hand edits.

**Tag:** `[process-gap]` — POL-16 (`bc_traceability_id_resolution`) codifies EC-ID
resolution checking but has `lint_hook: null`. The injectivity property (is this ID
used for exactly one scenario?) is not checked by any gate. This is the third pass
on which a POL-16-class defect has been found unresolved.

---

### P3-004 — POL-18 holdout leak: `prd.md` ~line 509 states the complete scenario and expected verdict for active holdout EC-151, which HS-INDEX.md also records as `not-yet-authored`

**Files:** `.factory/specs/prd.md:~509` · `.factory/holdout-scenarios/HS-INDEX.md`

`prd.md` ~line 509 states the complete scenario and expected verdict for **active**
holdout EC-151. `HS-INDEX.md` records EC-151 as `not-yet-authored` — so the leak in
`prd.md` is EC-151's **only** specification. The holdout exists in the visible layer
and nowhere else.

**Failure scenario:** the Phase 4 holdout evaluator runs EC-151 as a supposed
unseen scenario. The implementer's test suite, built from visible specs, will have
covered the scenario exactly per the prd.md specification. The holdout score for
EC-151 proves nothing about generalization.

**Owner:** product-owner

---

### P3-005 — D-020's "burned to visible tests" was never executed in `test-vectors.md`; T12 / DI-002 / D-006 exact-case comparison has zero coverage in both visible and holdout suites

**Files:** `.factory/specs/prd-supplements/test-vectors.md` (§3 exclusion list, §8 holdout list) · `.factory/specs/behavioral-contracts/` (EC-036/049/074/157/158 references)

D-020's mandate to burn EC-036, EC-049, EC-074, EC-157, and EC-158 to visible tests
was never executed in `test-vectors.md`. Additionally, §3 of test-vectors.md still
excludes EC-049 and EC-074; §8 still lists T12 as a holdout. Net effect: **trap T12
/ DI-002 / D-006 exact-case comparison — the product's flagship differentiator —
has zero coverage in the visible suite AND zero holdout coverage.**

**Failure scenario:** an implementation that silently folds case on link resolution
(calls `to_lowercase()` before comparison) passes every visible test and every
holdout evaluation, because no test vector exercises the case-sensitivity
discriminant. The D-006 / DI-002 differentiator — the reason ADR-006 exists — is
completely unverifiable in the current suite.

**Owner:** product-owner

---

## MAJOR

Findings P3-006 through P3-032 are grouped by owner. Findings whose full text was
provided in the authoritative summary are recorded in full; findings not detailed in
the summary are recorded as stubs with the information available. Owners for stubs
are marked TBD pending the generated remediation pass.

### Owner: architect

#### P3-028 — POL-12's own verification step encodes `alive` as an external-URL verdict, inverting binding decision D-014 — a governance rule that contradicts a binding decision is worse than no rule

**File:** `.factory/policies.yaml` (POL-12 `bc_adr_verdict_exit_code_consistency`, verification step)

`policies.yaml` POL-12's own `verification_steps` encodes `alive` as a valid
external-URL verdict. Binding decision D-014 resolves the alive/clean question;
POL-12 was written to enforce the ADR/taxonomy consistency check but its own
verification procedure inverts the decision it is supposed to protect. A governance
policy that contradicts a binding decision is worse than having no policy: it
actively misdirects the adversary and produces false clean-pass results on a
class-D-014 finding.

**Tag:** `[process-gap]`

**Owner:** architect (policy-level correction; must trace to D-014 resolution)

---

#### P3-006 — [Full finding text not provided in authoritative summary — stub]

**Owner:** TBD

---

#### P3-007 — [Full finding text not provided in authoritative summary — stub]

**Owner:** TBD

---

### Owner: product-owner

#### P3-008 — EC-NNN traceability ID collision — re-instance of defect class codified as POL-16; collision found in subsystem(s) not covered by pass-2 EC sweep

**Tag:** re-instance of POL-16 (`bc_traceability_id_resolution`). Rule was written; defect not fixed.

**Owner:** product-owner

---

#### P3-013 — PRD§2 title ↔ BC H1 drift persists after pass-2 correction — re-instance of defect class codified as POL-13; additional drifted titles found

**Tag:** re-instance of POL-13 (`prd_section_title_bc_h1_sync`). Rule was written; defect not fixed.

**Owner:** product-owner

---

#### P3-016 — Derived table counts drifted from source — re-instance of defect class codified as POL-17; new count discrepancy found in BC-INDEX or VP-INDEX derived section

**Tag:** re-instance of POL-17 (`derived_tables_must_be_regenerated`). Rule was written; defect not fixed.

**Owner:** product-owner

---

#### P3-009 — [Full finding text not provided in authoritative summary — stub]

**Owner:** TBD

---

#### P3-010 — [Full finding text not provided in authoritative summary — stub]

**Owner:** TBD

---

#### P3-011 — [Full finding text not provided in authoritative summary — stub]

**Owner:** TBD

---

#### P3-012 — [Full finding text not provided in authoritative summary — stub]

**Owner:** TBD

---

#### P3-014 — [Full finding text not provided in authoritative summary — stub]

**Owner:** TBD

---

#### P3-015 — [Full finding text not provided in authoritative summary — stub]

**Owner:** TBD

---

#### P3-017 — [Full finding text not provided in authoritative summary — stub]

**Owner:** TBD

---

#### P3-018 — [Full finding text not provided in authoritative summary — stub]

**Owner:** TBD

---

#### P3-019 — [Full finding text not provided in authoritative summary — stub]

**Owner:** TBD

---

#### P3-020 — [Full finding text not provided in authoritative summary — stub]

**Owner:** TBD

---

#### P3-021 — [Full finding text not provided in authoritative summary — stub]

**Owner:** TBD

---

#### P3-022 — [Full finding text not provided in authoritative summary — stub]

**Owner:** TBD

---

#### P3-023 — [Full finding text not provided in authoritative summary — stub]

**Owner:** TBD

---

#### P3-024 — [Full finding text not provided in authoritative summary — stub]

**Owner:** TBD

---

#### P3-025 — [Full finding text not provided in authoritative summary — stub]

**Owner:** TBD

---

#### P3-026 — [Full finding text not provided in authoritative summary — stub]

**Owner:** TBD

---

### [process-gap]

#### P3-027 — [Process-gap finding — full text not provided in authoritative summary — stub]

**Tag:** `[process-gap]`

**Owner:** TBD

---

#### P3-029 — [Full finding text not provided in authoritative summary — stub]

**Owner:** TBD

---

#### P3-030 — [Full finding text not provided in authoritative summary — stub]

**Owner:** TBD

---

#### P3-031 — [Full finding text not provided in authoritative summary — stub]

**Owner:** TBD

---

#### P3-032 — [Full finding text not provided in authoritative summary — stub]

**Owner:** TBD

---

## MINOR

Findings P3-033 through P3-039. Full text not provided in authoritative summary —
stubs recorded for traceability.

| ID | Description | Owner |
|----|-------------|-------|
| P3-033 | [Not detailed in authoritative summary] | TBD |
| P3-034 | [Not detailed in authoritative summary] | TBD |
| P3-035 | [Not detailed in authoritative summary] | TBD |
| P3-036 | [Not detailed in authoritative summary] | TBD |
| P3-037 | [Not detailed in authoritative summary] | TBD |
| P3-038 | [Not detailed in authoritative summary] | TBD |
| P3-039 | [Not detailed in authoritative summary] | TBD |

---

## Areas Verified CLEAN

The following areas were verified by the adversary and need NOT be re-examined in
pass 4:

| Area | Verified result |
|------|----------------|
| VP-INDEX arithmetic | 7+7+2+7+1=24 category counts; P0 7 + P1 9 + test-sufficient 8 = 24; 24 files on disk — all three counts agree |
| VP-INDEX ↔ verification-coverage-matrix agreement | No discrepancy found |
| BC-INDEX row count | 66 rows; P0 53 / P1 13 — correct |
| Subsystem labels (all 14) | All 14 subsystem labels match ARCH-INDEX exactly |
| SS-TBD occurrences | Zero remaining |
| VP-TBD occurrences | Zero remaining |
| 13-code closed taxonomy | error-taxonomy.md, failure-modes.md, and prd.md all agree on the same 13-code taxonomy |
| github-slugger vectors | 8 of 16 vectors hand-verified correct, including the `foo`/`foo-1`/`foo-1-1` orderings and the `Setup-1-first` (`setup-1-first`) orderings |

---

## Perimeter NOT Reached

The following were **not read** in this pass and remain unexamined:

- 8 architecture shards (non-ADR-007 files not fully read)
- ADR-001, ADR-002, ADR-003, ADR-004, ADR-006 bodies (decision text, not just filename)
- `.factory/specs/dtu-assessment.md`
- `.factory/specs/gene-transfusion-assessment.md`
- `.factory/specs/module-criticality.md`
- `prd.md` §1 (background/rationale)
- Most domain-spec shards (capabilities/invariants/edge-cases read only in targeted excerpt form)
- `interface-definitions.md` (full read)
- 54 of 66 BC bodies (read only via H1, Traceability table, and grep output — not full prose)
- All 24 individual VP files (VP-INDEX arithmetic verified; VP file contents not read)
- 8 remaining github-slugger vectors (8 of 16 verified; 8 deferred)
