---
document_type: holdout-index
level: ops
version: "1.3"
status: active
producer: vsdd-factory:product-owner
timestamp: "2026-08-10T01:00:00Z"
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

| HS ID | EC ID | Title | Risk Cluster | BCs / CAPs Probed | Status |
|-------|-------|-------|--------------|-------------------|--------|
| HS-001 | EC-156 | .gitignore Traversal Exclusion × Cross-File Anchor | Exclusion boundary × Pass 1.5: an implementation may correctly skip ignored files as *sources* but incorrectly skip them as *anchor targets*, breaking cross-directory links into gitignored subtrees | BC-2.01.003 (gitignore exclusion rule), BC-2.05.001 (Pass 1.5 anchor-table construction), BC-2.08.004 (cross-file anchor into excluded file) | active |
| ~~HS-002~~ | ~~EC-157~~ | ~~Percent-Encoded Fragment in Cross-File Link~~ | ~~Percent-encoding × anchor resolution~~ | ~~BC-2.08.002, BC-2.08.003~~ | **retired** — burned to visible test per D-020; holdout signal compromised (P2-C07); replaced by EC-167 (HS-006) |
| ~~HS-003~~ | ~~EC-158~~ | ~~Emoji Heading × Collision Counter~~ | ~~Emoji × slug collision~~ | ~~BC-2.06.001, BC-2.06.002~~ | **retired** — burned to visible test per D-020; holdout signal compromised (P2-C07); replaced by EC-168 (HS-007) |
| HS-004 | EC-165 | Anchor Resolution Case Variant | Anchor resolution edge: a variant of anchor resolution ordering not covered by existing visible tests | BC-2.05.001, BC-2.08.002 | active |
| HS-005 | EC-166 | Source-Exclusion × Cross-File Anchor | Exclusion boundary × anchor target: source-exclusion flag interaction with cross-file anchor lookup | BC-2.01.003, BC-2.05.001, BC-2.08.004, BC-2.11.001 | active |
| HS-006 | EC-167 | Percent-Encoding × Fragment Split | Percent-encoding combined with fragment splitting: tests the interaction of DI-003 (fragment-at-first-unescaped-#) with percent-encoded anchor values | BC-2.08.003, BC-2.08.002 | active |
| HS-007 | EC-168 | Duplicate-Slug Collision Variant | Duplicate slug collision edge: a collision pattern not covered by EC-047/EC-048 visible tests | BC-2.06.001, BC-2.06.002 | active |
| HS-008 | EC-214 | HTML-Block Heading × Cross-File Anchor | Heading nested inside a raw HTML block × cross-file anchor-table construction and anchor resolution; replaces EC-151 (D-122) | BC-2.05.001, BC-2.08.004 | active |

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
