---
document_type: holdout-index
level: ops
version: "1.4"
status: active
producer: vsdd-factory:product-owner
timestamp: "2026-08-10T02:00:00Z"
phase: phase-1d
inputs:
  - .factory/holdout-scenarios/wave-scenarios/
  - .factory/specs/prd.md
input-hash: "2860da8"
traces_to: .factory/specs/prd.md
---

# Holdout Scenario Index (HS-INDEX)

> **POL-18 NOTICE:** This index contains ONLY identifiers, titles, risk clusters, and
> traceability pointers. It does NOT contain concrete inputs, expected outputs, fixture
> content, or any information that could reveal scenario details to an implementer or
> test-writer. Entries marked `status: not-yet-authored` are reserved IDs with no
> scenario file; their absence from this index would be a silent gap — listing them here
> makes the gap visible and auditable.

## Placement rationale

This file lives at `.factory/holdout-scenarios/HS-INDEX.md` (not inside
`wave-scenarios/`). Convention follows the existing index placement in this project:
`BC-INDEX.md` lives at the root of `behavioral-contracts/` (not inside a subsystem
subdirectory), and the VP-INDEX lives at the root of `verification-properties/`. The
HS-INDEX governs all holdout scenario files regardless of which wave subdirectory they
reside in; placing it at the root of `holdout-scenarios/` preserves that governance
scope as future waves add subdirectories.

---

## Authored Scenarios

| HS ID | EC ID | Title | Risk Cluster | BCs / CAPs Probed | Status | Earliest Evaluable Wave |
|-------|-------|-------|--------------|-------------------|--------|------------------------|
| HS-001 | EC-156 | .gitignore Traversal Exclusion × Cross-File Anchor | Exclusion boundary × Pass 1.5: an implementation may correctly skip ignored files as *sources* but incorrectly skip them as *anchor targets*, breaking cross-directory links into gitignored subtrees | BC-2.01.003 (gitignore exclusion rule), BC-2.05.001 (Pass 1.5 anchor-table construction), BC-2.08.004 (cross-file anchor into excluded file) | active | **5** |
| ~~HS-002~~ | ~~EC-157~~ | ~~Percent-Encoded Fragment in Cross-File Link~~ | ~~Percent-encoding × anchor resolution~~ | ~~BC-2.08.002, BC-2.08.003~~ | **retired** — burned to visible test per D-020; holdout signal compromised (P2-C07); replaced by EC-167 (HS-006) | N/A (retired) |
| ~~HS-003~~ | ~~EC-158~~ | ~~Emoji Heading × Collision Counter~~ | ~~Emoji × slug collision~~ | ~~BC-2.06.001, BC-2.06.002~~ | **retired** — burned to visible test per D-020; holdout signal compromised (P2-C07); replaced by EC-168 (HS-007) | N/A (retired) |
| HS-004 | EC-165 | Anchor Resolution Case Variant | Anchor resolution edge: a variant of anchor resolution ordering not covered by existing visible tests | BC-2.05.001, BC-2.08.002 | active | **5** |
| HS-005 | EC-166 | Source-Exclusion × Cross-File Anchor | Exclusion boundary × anchor target: source-exclusion flag interaction with cross-file anchor lookup | BC-2.01.003, BC-2.05.001, BC-2.08.004, BC-2.11.001 | active | **5** |
| HS-006 | EC-167 | Percent-Encoding × Fragment Split | Percent-encoding combined with fragment splitting: tests the interaction of DI-003 (fragment-at-first-unescaped-#) with percent-encoded anchor values | BC-2.08.003, BC-2.08.002 | active | **5** |
| HS-007 | EC-168 | Duplicate-Slug Collision Variant | Duplicate slug collision edge: a collision pattern not covered by EC-047/EC-048 visible tests | BC-2.06.001, BC-2.06.002 | active | **2** |
| HS-008 | EC-214 | HTML-Block Heading × Cross-File Anchor | Heading nested inside a raw HTML block × cross-file anchor-table construction and anchor resolution; replaces EC-151 (D-122) | BC-2.05.001, BC-2.08.004 | active | **5** |

---

## Reserved IDs — Not Yet Authored

The following EC IDs are reserved as holdouts in prd.md:332 but have no scenario file
in `.factory/holdout-scenarios/`. Listing them here prevents silent gaps.

| EC ID | Reserved Since | Notes | Status |
|-------|---------------|-------|--------|
| ~~EC-036~~ | ~~prd.md:332~~ | ~~Case-sensitivity: mixed-case path component vs on-disk filename.~~ P2-C07: holdout signal compromised (leaked in edge-cases.md, invariants.md). D-020: **burned to visible test**; holdout designation retired. | **retired** |
| ~~EC-049~~ | ~~prd.md:332~~ | ~~Triple-collision slug disambiguation.~~ P2-C07: holdout signal compromised (leaked in edge-cases.md, prd.md, VP-003). D-020: **burned to visible test**; holdout designation retired. | **retired** |
| ~~EC-074~~ | ~~prd.md:332~~ | ~~`--ignore`d file as anchor target.~~ P2-C07: holdout signal compromised (leaked in edge-cases.md). D-020: **burned to visible test**; holdout designation retired. | **retired** |
| EC-079 | prd.md:332 | (scenario not yet specified) | not-yet-authored |
| EC-093 | prd.md:332 | (scenario not yet specified; BC-2.10.002 changelog records it was removed from the HTTP block) | not-yet-authored |
| EC-094 | prd.md:332 | (scenario not yet specified) | not-yet-authored |
| EC-141 | prd.md:332 | (scenario not yet specified) | not-yet-authored |
| EC-147 | prd.md:332 | (scenario not yet specified) | not-yet-authored |
| EC-148 | prd.md:332 | (scenario not yet specified) | not-yet-authored |
| ~~EC-151~~ | ~~prd.md:618~~ | ~~heading nested inside a raw HTML `<details>` block × anchor resolution.~~ D-122 (2026-08-08): holdout signal compromised — prd.md:618 D-010 audit note exposed concrete input and expected output verbatim. **burned to visible test TV-151**; holdout designation retired. Replaced by EC-214 (HS-008). | **retired** |

---

## P2-C07 Resolution (D-020)

Adversary pass-2 finding P2-C07 (CRITICAL) determined that the POL-18 holdout boundary
was breached. **D-020 (human ruling, 2026-08-05) resolves P2-C07** by burning the
compromised holdouts to visible tests and replacing them with fresh hidden scenarios:

- **EC-036, EC-049, EC-074** (Reserved, never authored): holdout designation **retired**; burned to visible tests. Their concrete details were already visible in domain-spec artifacts (edge-cases.md, invariants.md) and would have provided zero holdout signal. Risk coverage is maintained by EC-165..EC-168.
- **EC-157 (HS-002)**: holdout designation **retired**; burned to visible test. Concrete inputs/expected outputs from the scenario file are now part of the visible test suite. Replaced by EC-167 (HS-006) covering the same risk cluster with a fresh non-leaked variant.
- **EC-158 (HS-003)**: holdout designation **retired**; burned to visible test. Replaced by EC-168 (HS-007).
- **EC-156 (HS-001)**: P2-C07 note resolved. EC-156 retains `status: active` — the adversary's concern about TV-153/EC-153 overlap was noted but EC-156 tests a corpus-fixture code path (DI-006 case 2) distinct from the visible vector's inline assertion. The holdout signal remains intact.

**Replacement holdouts EC-165..EC-168** (HS-004..HS-007) are fresh non-leaked variants in the same risk clusters. Their concrete inputs and expected outputs reside ONLY in their wave scenario files per POL-18 — never in prd.md, any BC file, or test-vectors.md.

---

## D-122 Resolution (2026-08-08)

Operator gate #34 ruling D-122 determined that EC-151's POL-18 holdout boundary was breached by the D-010 audit note at prd.md:618, which stated EC-151's concrete input and expected output verbatim in a visible spec. EC-151 was a RESERVED, never-authored holdout; its concrete details were thus already public.

- **EC-151** (Reserved, never authored): holdout designation **retired**; burned to visible test TV-151 per D-122. The leaked content (heading inside `<details>` HTML block × same-file anchor resolution) is now a normal visible test vector. Replaced by EC-214 (HS-008) covering the same risk cluster with a cross-file variant using a different raw HTML block element — a genuinely non-leaked scenario verified against all spec files before authoring.

---

## Wave Coverage Gap — DISCLOSED, NOT RESOLVED

**Added in v1.4 (Phase 2 Step E). Escalated to operator. No new scenarios authored.**

### Per-Wave Holdout Coverage

The "earliest evaluable wave" values above produce the following coverage map across the 7-wave delivery schedule:

| Wave | Stories | Evaluable Holdouts | Coverage |
|------|---------|-------------------|----------|
| 1 | S-1.01 | (none) | **UNCOVERED** |
| 2 | S-1.02, S-1.03, S-3.01, S-3.03, S-5.02, S-6.01, S-7.02 | HS-007 | COVERED |
| 3 | S-1.04, S-2.01, S-6.02, S-7.01, S-7.03 | (none) | **UNCOVERED** |
| 4 | S-2.02, S-2.03, S-3.02, S-4.02, S-5.01 | (none) | **UNCOVERED** |
| 5 | S-3.04, S-4.01, S-5.03 | HS-001, HS-004, HS-005, HS-006, HS-008 | COVERED |
| 6 | S-4.03, S-5.04 | (none) | **UNCOVERED** |
| 7 | S-7.04 | (none) | **UNCOVERED** |

5 of 7 waves have no evaluable holdout at their gate. Only waves 2 and 5 are covered.

### Conflict with Phase 2 Gate Criterion

This distribution **conflicts with the Phase 2 decomposition gate criterion** which requires "at least one holdout scenario per wave." That criterion is not satisfied: waves 1, 3, 4, 6, and 7 all lack an evaluable holdout at their gate.

### Wave 1 — DEV-11 Run A Endpoint Is Uncovered

Wave 1 is the **DEV-11 "Run A" endpoint** — the operator's stop-vs-continue gate after the first story lands. It has **zero holdout coverage**. Every active holdout depends on anchor-resolution BCs (BC-2.05.001, BC-2.08.002, BC-2.08.004) that are implemented no earlier than wave 4–5. The wave 1 story (S-1.01) implements only BC-2.01.001, BC-2.01.003, BC-2.01.004, BC-2.01.005, none of which are probed by any active holdout in isolation.

### Uncovered Epics

The four epics with no active holdout at any wave:

| Epic | Domain | No holdout probing... |
|------|--------|-----------------------|
| E-2 | Link Extraction | BC-2.02.*, BC-2.03.*, BC-2.04.* — inline link extraction, reference-style links, code context exclusion |
| E-4 | Relative Path Resolution | BC-2.07.* — pure path resolver, DirIndex, fragment split / percent-decode ordering |
| E-5 | External URL Checking | BC-2.09.*, BC-2.10.* — offline URL syntax, HTTP verdict, HTTP client protocol / transport errors |
| E-7 | Output / Reporting / Exit Codes | BC-2.13.*, BC-2.14.* — exit code determination, text/JSON report generation |

### Disposition — Escalated, Not Fixed

**Resolving this gap by authoring new holdout scenarios is new work and is excluded by the D-244 closed-world ruling.** No new scenarios have been authored in this step. This section is a factual disclosure for operator adjudication.

The operator must decide one of:
1. Author new holdout scenarios for the uncovered epics and waves (new work, outside current phase scope).
2. Accept the gap and weaken the gate criterion for waves 1, 3, 4, 6, 7 (gate policy change).
3. Proceed with the current gate criterion knowing 5 waves will fail it (deferred risk).

**This item is escalated and awaits operator ruling before Phase 2 gate can be satisfied against the original criterion.**

### Reserved-but-Unauthored EC IDs

The 6 reserved-but-not-yet-authored EC IDs (EC-079, EC-093, EC-094, EC-141, EC-147, EC-148) remain in the "Reserved IDs — Not Yet Authored" table above with `status: not-yet-authored`. No new authoring has been done. They are noted here because some could potentially address the uncovered epics, but determining that requires operator decision, not product-owner action under the closed-world ruling.

---

## Scenario File Locations

All authored scenario files reside in `.factory/holdout-scenarios/wave-scenarios/`:

- `wave-scenarios/EC-156-gitignore-cross-file-anchor.md` → HS-001 (active)
- `wave-scenarios/EC-157-percent-encoded-fragment-cross-file.md` → HS-002 (retired/burned per D-020)
- `wave-scenarios/EC-158-emoji-heading-collision.md` → HS-003 (retired/burned per D-020)
- `wave-scenarios/EC-165-anchor-resolution-case-variant.md` → HS-004 (active)
- `wave-scenarios/EC-166-source-exclusion-cross-file-anchor.md` → HS-005 (active)
- `wave-scenarios/EC-167-percent-encoding-fragment-split.md` → HS-006 (active)
- `wave-scenarios/EC-168-duplicate-slug-collision.md` → HS-007 (active)
- `wave-scenarios/EC-214-html-block-heading-cross-file-anchor.md` → HS-008 (active)

---

## Changelog

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.4 | 2026-08-10 | product-owner (Phase 2 Step E) | Added "Earliest Evaluable Wave" column to Authored Scenarios table (computed from story `wave:` frontmatter); added "Wave Coverage Gap — DISCLOSED, NOT RESOLVED" section disclosing that 5 of 7 waves have no evaluable holdout, conflicting with the Phase 2 gate criterion, and escalating to operator for adjudication. No scenarios authored, retired, rewritten, or re-scoped. |
| 1.3 | 2026-08-10 | product-owner (phase-1d) | Added HS-008 (EC-214) replacing EC-151 per D-122; updated D-122 Resolution section. |
| 1.0–1.2 | 2026-08-05–08 | product-owner | Initial index with HS-001..HS-008; P2-C07 resolution (D-020); EC-151 burn and replacement. |
