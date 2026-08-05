---
document_type: planning-report
level: ops
version: "1.0"
producer: consistency-validator
timestamp: 2026-08-05T00:00:00Z
traces_to: STATE.md
---

# Artifact Detection Report: mdlinkcheck-cloud

**Run date:** 2026-08-05
**Mode:** greenfield
**Pipeline step:** planning.lobster / artifact-detection + routing-gate

---

## Step 1: Artifact Inventory

### Files Found

| Artifact | Path | Status |
|----------|------|--------|
| Product Brief (L1) | `/Users/jmagady/Dev/mdlinkcheck-cloud/BRIEF.md` | FOUND — at repo root (path discrepancy; see below) |
| Pipeline STATE.md | `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/STATE.md` | FOUND — factory initialized at pre-1 |
| Sidecar learning | `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/sidecar-learning.md` | FOUND — skeleton only |
| .factory/ structure | `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/` | FOUND — skeleton dirs, all .gitkeep |

### Files Absent

| Artifact | Expected Path | Status |
|----------|--------------|--------|
| Product Brief (canonical) | `.factory/specs/product-brief.md` | ABSENT — exists only at repo root |
| L2 Domain Spec | `.factory/specs/domain-spec/L2-INDEX.md` | ABSENT |
| PRD | `.factory/specs/prd.md` | ABSENT |
| BC-INDEX (L3 behavioral contracts) | `.factory/specs/behavioral-contracts/BC-INDEX.md` | ABSENT — directory is .gitkeep only |
| VP-INDEX (L4 verification properties) | `.factory/specs/verification-properties/VP-INDEX.md` | ABSENT — directory is .gitkeep only |
| ARCH-INDEX (architecture) | `.factory/specs/architecture/ARCH-INDEX.md` | ABSENT — directory is .gitkeep only |
| Architecture Feasibility Report | `.factory/specs/architecture-feasibility-report.md` | ABSENT |
| Verification Architecture | `.factory/specs/architecture/verification-architecture/ARCH-INDEX.md` | ABSENT |
| PRD Supplements | `.factory/specs/prd-supplements/` (4 files) | ABSENT — directory is .gitkeep only |
| UX Spec | `.factory/specs/ux-spec/UX-INDEX.md` | ABSENT — expected absent (CLI product) |
| Epics file | `.factory/stories/epics.md` | ABSENT — directory is .gitkeep only |
| Stories | `.factory/stories/stories/` | ABSENT |
| STORY-INDEX | `.factory/stories/STORY-INDEX.md` | ABSENT |
| Holdout Scenarios | `.factory/holdout-scenarios/` (real content) | ABSENT — directory is .gitkeep only |
| EVAL-INDEX | `.factory/holdout-scenarios/evaluations/EVAL-INDEX.md` | ABSENT — directory is .gitkeep only |
| policies.yaml | `.factory/policies.yaml` | ABSENT |
| project-context.md | (any location) | ABSENT — greenfield, expected absent |
| docs/ directory | `/Users/jmagady/Dev/mdlinkcheck-cloud/docs/` | ABSENT |

---

## Step 1b: Path Discrepancy — BRIEF.md at Repo Root

**Finding:** The product brief exists at `/Users/jmagady/Dev/mdlinkcheck-cloud/BRIEF.md`
(repo root), not at the canonical factory location `.factory/specs/product-brief.md`.

**Recommendation:** Copy to `.factory/specs/product-brief.md` and add canonical VSDD
frontmatter (`document_type: product-brief`, `level: L1`, `version: "1.0"`,
`producer: human`, `traces_to: ""`, `timestamp`). Do NOT delete the root copy — it
serves as a human-readable project readme and can remain as a stable reference.
The factory pipeline will operate from `.factory/specs/product-brief.md`.

**Action required before Phase 1:** The business-analyst agent needs the brief at the
canonical path. Recommend the orchestrator copy+annotate it as the first Phase 1
sub-step.

---

## Step 1c: Format Detection

- **Requirement numbering in brief:** Flat R1-R8 style — expected and correct for an
  L1 product brief. No BC-S.SS.NNN IDs present; those are produced in Phase 1 (L3).
- **FR-NNN legacy format:** Not detected. Brief uses descriptive prose requirements;
  no legacy numeric FR-NNN IDs to migrate.
- **Architecture sharding format:** Not applicable — no architecture artifact exists yet.

---

## Step 2: Readiness Classification

**Level: L1 — Brief Only**

A substantive product brief exists. All downstream artifacts (L2 domain spec, PRD,
architecture, BCs, VPs, stories) are absent. The `.factory/` skeleton is initialized
but contains no spec content.

---

## Step 3: Brief Validation

| Check | Result | Notes |
|-------|--------|-------|
| Contains a problem statement | PASS | "Documentation repos rot: files move, headings get renamed, external sites die." |
| Users identified | PASS | "Engineers running it locally and in CI on repos containing Markdown." |
| Functional requirements present | PASS | R1-R8 with concrete behavioral descriptions |
| Non-goals declared | PASS | "No link rewriting/fixing, no HTML parsing, no JavaScript rendering, no config file, no watch mode." |
| Success criteria present | PASS | Three measurable criteria stated |
| Scope is defined (not "build everything") | PASS | Clearly scoped to offline-first CLI Markdown link checker |
| Not just a title or one-liner | PASS | Full substantive content (~42 lines) |
| Canonical frontmatter | FAIL (Minor) | No YAML frontmatter block; brief is a raw Markdown file |
| Located at canonical factory path | FAIL (Minor) | At repo root, not `.factory/specs/product-brief.md` |
| NFR targets with numerical thresholds | PARTIAL | R8 states "under 5 seconds" for 500-file corpus — good. No explicit latency/memory NFRs for other modes. |
| Edge cases cataloged | PARTIAL | R4 (code-block exclusion), R5 (ignore globs) present; full edge-case catalog deferred to PRD phase |

**Brief verdict: VALID with minor gaps.** The brief is substantive and well-scoped.
The two FAIL items (no frontmatter, wrong path) are cosmetic and resolved by the
brief-copy step at Phase 1 start. The partial NFR gap is normal at L1 and will be
filled during L2/L3 spec crystallization.

---

## Step 4: Gap Analysis

| Artifact | Status | Gaps |
|----------|--------|------|
| Product Brief (L1) | VALID (minor path issue) | (1) Not at `.factory/specs/product-brief.md`; (2) No canonical frontmatter; (3) NFR catalog incomplete but sufficient for L1 |
| L2 Domain Spec | MISSING | Entire artifact absent |
| PRD (L3) | MISSING | Entire artifact absent |
| Behavioral Contracts (L3) | MISSING | No BC-INDEX, no individual BC files |
| Verification Properties (L4) | MISSING | No VP-INDEX, no individual VP files |
| Architecture | MISSING | No ARCH-INDEX, no section files |
| PRD Supplements | MISSING | All 4 required files absent (interface-definitions.md, error-taxonomy.md, test-vectors.md, nfr-catalog.md) |
| UX Spec | N/A | CLI product — UX spec correctly absent |
| Stories / Epics | MISSING | No epics.md, no story files, no STORY-INDEX |
| Holdout Scenarios | MISSING | No scenario files, no EVAL-INDEX |
| policies.yaml | MISSING | Governance registry not yet created |

---

## Step 5: Route Decision

**Classification:** L1 — Brief exists, all downstream artifacts absent.

**Entry point:** Phase 1: Spec Crystallization — validate-existing-brief path.

**Planning.lobster branch:** `validate-existing-brief` (not `guided-brief-creation`).
The brief is complete enough to drive spec crystallization directly.

**Pre-Phase-1 action:** Copy and annotate brief to canonical factory path before
dispatching the business-analyst agent.

**Pipeline entry sequence:**
1. Copy `/Users/jmagady/Dev/mdlinkcheck-cloud/BRIEF.md` to
   `.factory/specs/product-brief.md` with canonical frontmatter added.
2. Dispatch business-analyst agent to produce L2 Domain Spec
   (`.factory/specs/domain-spec/` sharded directory + `L2-INDEX.md`).
3. Dispatch product-owner agent to produce PRD + behavioral contracts from L2.
4. Dispatch architect agent to produce architecture from PRD + BCs.
5. Continue through Phase 1 gate (consistency validation + adversarial review).

---

## Artifact Inventory Summary

| Category | Found | Missing | Notes |
|----------|-------|---------|-------|
| L1 Product Brief | 1 (at wrong path) | — | Needs copy to factory path |
| L2 Domain Spec | 0 | 1 (full sharded dir) | |
| L3 PRD + BCs | 0 | PRD + BC-INDEX + BC files | |
| L4 VPs | 0 | VP-INDEX + VP files | |
| Architecture | 0 | ARCH-INDEX + 7 section files | |
| PRD Supplements | 0 | 4 required files | |
| UX Spec | N/A | — | CLI product |
| Stories | 0 | epics.md + STORY-INDEX + story files | |
| Holdout Scenarios | 0 | scenario files + EVAL-INDEX | |
| policies.yaml | 0 | 1 | |
| .factory/ skeleton | PRESENT | — | All directories created, .gitkeep only |
| STATE.md | PRESENT | — | Phase pre-1, all phases not-started |
