---
document_type: architecture-index
level: L3
version: "1.1"
status: draft
producer: architect
timestamp: 2026-08-05T20:00:00Z
phase: 1b
inputs:
  - .factory/specs/domain-spec/L2-INDEX.md
  - .factory/specs/prd.md
  - .factory/specs/prd-supplements/nfr-catalog.md
  - .factory/specs/dtu-assessment.md
  - .factory/specs/gene-transfusion-assessment.md
  - .factory/planning/market-intelligence.md
input-hash: "4e83a61"
traces_to: .factory/specs/prd.md
deployment_topology: single-service
---

# Architecture Index: mdlinkcheck

> **Context Engineering:** Lightweight index (~300 tokens). Agents load ONLY
> the section files they need. See Document Map for per-section consumer guidance.

## Document Map

| Section | File | Primary Consumer | Purpose |
|---------|------|-----------------|---------|
| System Overview | system-overview.md | all agents | Architecture vision, two-pass pipeline, concurrency |
| Module Decomposition | module-decomposition.md | story-writer, implementer | Crate/module catalog with boundaries |
| Dependency Graph | dependency-graph.md | story-writer, implementer | Inter-module deps, verified crate versions |
| API Surface | api-surface.md | test-writer, implementer | CLI interface, library public API |
| Verification Architecture | verification-architecture.md | formal-verifier | Provable properties, proof strategies, VP catalog |
| Purity Boundary Map | purity-boundary-map.md | implementer, formal-verifier | Pure-core vs effectful-shell classification |
| Tooling Selection | tooling-selection.md | formal-verifier, dx-engineer | Kani, cargo-fuzz, cargo-mutants, proptest config |
| Verification Coverage Matrix | verification-coverage-matrix.md | consistency-validator | VP-to-module mapping, coverage totals |
| Architecture Feasibility Review | feasibility-review.md | product-owner, architect | PRD subsystem grouping feasibility verdict and rationale |

## Cross-References

| If you need... | Read these together |
|----------------|-------------------|
| Implementation plan for a module | module-decomposition.md + dependency-graph.md + purity-boundary-map.md |
| Verification plan for a module | verification-architecture.md + purity-boundary-map.md + tooling-selection.md |
| Story decomposition input | module-decomposition.md + dependency-graph.md + api-surface.md |
| Full verification picture | verification-architecture.md + verification-coverage-matrix.md + VP-INDEX.md |

## Subsystem Registry

> **Source of truth** for subsystem names. BC frontmatter `subsystem:`, BC-INDEX,
> and story `subsystems:` MUST use exact names from this table.

| SS ID | Name | Implementing Modules | Phase |
|-------|------|---------------------|-------|
| SS-01 | File Discovery | scanner | Phase 1 |
| SS-02 | Markdown Parsing | scanner, link_extractor | Phase 1 |
| SS-03 | Link Extraction | link_extractor | Phase 1 |
| SS-04 | Code Context Exclusion | link_extractor (structural via pulldown-cmark) | Phase 1 |
| SS-05 | Anchor Table Construction | anchor_table | Phase 1 |
| SS-06 | Heading Slug Computation | slug | Phase 1 |
| SS-07 | Relative Path Resolution | path_resolver, fragment | Phase 1 |
| SS-08 | Anchor Resolution | anchor_resolver, fragment | Phase 1 |
| SS-09 | External URL Syntax Validation | url_classifier | Phase 1 |
| SS-10 | External URL Liveness Checking | http_client, http_verdict | Phase 1 |
| SS-11 | Filter Application | filter | Phase 1 |
| SS-12 | Text Report Generation | reporter | Phase 1 |
| SS-13 | JSON Report Generation | reporter | Phase 1 |
| SS-14 | Exit Code Determination | verdict | Phase 1 |

## Architecture Decisions

| ADR | Title | Subsystems |
|-----|-------|------------|
| ADR-001 | Pure-Core / Effectful-Shell Boundary | all |
| ADR-002 | Workspace Layout: Library + Binary Crates | all |
| ADR-003 | pulldown-cmark 0.13.4 Parser Choice | SS-02, SS-03, SS-04 |
| ADR-004 | ureq 3.3.0 Sync HTTP Client | SS-10 |
| ADR-005 | rayon Parallelism + Sort-Before-Emit | SS-01, SS-12, SS-13 |
| ADR-006 | Case-Sensitive NFC Strict Path Model | SS-07 |
| ADR-007 | Three-Verdict Model | SS-10, SS-14 |
