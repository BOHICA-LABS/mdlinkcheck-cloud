---
document_type: consistency-report
level: ops
version: "1.0"
status: fail
producer: vsdd-factory:consistency-validator
timestamp: 2026-08-06T00:00:00Z
phase: phase-1d
inputs:
  - .factory/specs/product-brief.md
  - .factory/specs/domain-spec/L2-INDEX.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/domain-spec/capabilities.md
  - .factory/specs/domain-spec/failure-modes.md
  - .factory/specs/behavioral-contracts/BC-INDEX.md
  - .factory/specs/behavioral-contracts/ss-06/BC-2.06.001.md
  - .factory/specs/behavioral-contracts/ss-06/BC-2.06.002.md
  - .factory/specs/behavioral-contracts/ss-08/BC-2.08.001.md
  - .factory/specs/behavioral-contracts/ss-08/BC-2.08.002.md
  - .factory/specs/behavioral-contracts/ss-08/BC-2.08.004.md
  - .factory/specs/verification-properties/VP-INDEX.md
  - .factory/specs/verification-properties/vp-022-regression-gate.md
  - .factory/specs/verification-properties/vp-026-slug-differential-fidelity.md
  - .factory/specs/architecture/ARCH-INDEX.md
  - .factory/specs/architecture/bc-module-map.md
  - .factory/specs/architecture/verification-architecture.md
  - .factory/specs/architecture/verification-coverage-matrix.md
  - .factory/specs/module-criticality.md
  - .factory/specs/prd.md
  - .factory/specs/prd-supplements/nfr-catalog.md
  - .factory/specs/prd-supplements/test-vectors.md
input-hash: "819c871"
traces_to: .factory/specs/prd.md
audit_pass: 4
frozen_head: d08021e4af055885fdd4b1898ce4dc9a426fa393
---

# Consistency Validation Report: mdlinkcheck-cloud Phase 1 — Pass 4

## Report Metadata

| Field | Value |
|-------|-------|
| **Product** | mdlinkcheck (Rust CLI, MSRV 1.85) |
| **Generated** | 2026-08-06T00:00:00Z |
| **Generator** | vsdd-factory:consistency-validator |
| **Artifacts Scanned** | 22 |
| **Audit Pass** | Pass 4 — perimeter + cross-document consistency |
| **Frozen HEAD** | `d08021e4af055885fdd4b1898ce4dc9a426fa393` on `factory-artifacts` |
| **Pass scope** | Orphan/chain checks; BI-005 propagation (VP-026 + DI-012/DI-013); resolves-but-wrong semantics; cross-document contradictions; convention consistency |
| **Not in scope** | Spec-lint mechanical checks (title/H1 sync, ID resolution, counts), UI/design-system artifacts, holdout evaluations, prd.md:720 immutable record |

## Summary

| # | Check | Result |
|---|-------|--------|
| 1 | L2 to L3 Requirement Coverage | pass |
| 2 | L3 to L4 Verification Property Coverage | fail |
| 3 | Dependency Acyclicity | n/a (Phase 1 — no stories) |
| 4 | Architecture Alignment | fail |
| 5 | Acceptance Criteria Quality | n/a (Phase 1 — no stories) |
| 6 | Story Sizing (all <= 13 points) | n/a (Phase 1 — no stories) |
| 7 | Priority Consistency | n/a (Phase 1 — no stories) |
| 8 | L1 to L2 to L3 to L4 Chain Completeness | fail |
| 9 | AC Completeness Coverage | n/a (Phase 1 — no stories) |
| 10 | ASM/R Traceability | pass |

---

## 1. L2 to L3 Requirement Coverage

### 1.1 Domain Capabilities to Behavioral Contracts

All 14 CAPs have BC subsystem coverage per BC-INDEX.md. No orphaned capabilities found.

| CAP-NNN | Description | Covered by BC-NNN? | Gap? |
|---------|-------------|-------------------|------|
| CAP-001 | File link extraction from Markdown | BC-2.01.xxx | no |
| CAP-002 | URL classification | BC-2.02.xxx | no |
| CAP-003 | Fragment splitting | BC-2.03.xxx | no |
| CAP-004 | Path resolution (case-sensitive, NFC) | BC-2.04.xxx | no |
| CAP-005 | Heading extraction and anchor table | BC-2.05.xxx | no |
| CAP-006 | github-slugger v2 slug algorithm | BC-2.06.001, BC-2.06.002 | no |
| CAP-007 | Anchor resolution | BC-2.07.xxx | no |
| CAP-008 | Anchor resolver lookup | BC-2.08.xxx | no |
| CAP-009 | HTTP verdict classification | BC-2.09.xxx | no |
| CAP-010 | Exit code / verdict computation | BC-2.10.xxx | no |
| CAP-011 | Output formatting (text + JSON) | BC-2.11.xxx | no |
| CAP-012 | Filter (--ignore / --allow) | BC-2.12.xxx | no |
| CAP-013 | Scanner (directory traversal) | BC-2.13.xxx | no |
| CAP-014 | Two-pass pipeline orchestration | BC-2.14.xxx | no |

**Result: PASS** — all 14 CAPs traced to at least one BC.

**Secondary issue (semantic drift, reported in Section 8):** CAP-006 in `capabilities.md` v1.5 cites DI-012 and DI-013 as governing invariants. BC-2.06.001 and BC-2.06.002 still cite DI-008 in their Traceability sections. This is a cross-document contradiction reported under Broken Chains and Findings C4-001/C4-002.

---

## 2. L3 to L4 Verification Property Coverage

### 2.1 Behavioral Contracts to Verification Properties

VP-INDEX BC-to-VP table is the authoritative source and is complete. The gap is at the BC **body** level: VP tables inside individual BC files do not reflect recently added VPs.

| BC-S.SS.NNN | Description | VP-NNN (VP-INDEX authoritative) | Body VP table current? |
|-------------|-------------|--------------------------------|----------------------|
| BC-2.06.001 | github-slugger v2 core algorithm | VP-001, VP-002, VP-012, VP-018, VP-026 | no — body missing VP-026 |
| BC-2.06.002 | Duplicate-heading counter | VP-003, VP-026 | no — body missing VP-026 |
| BC-2.08.001 | Anchor resolver (basic lookup) | VP-015, VP-025 | no — body missing VP-025 |
| BC-2.08.002 | Anchor resolver (edge cases) | VP-015, VP-016, VP-025 | no — body missing VP-025 |
| BC-2.08.004 | Anchor resolver (empty fragment) | VP-016, VP-025 | no — body missing VP-025 |
| All other BCs | (66 total) | per VP-INDEX | not individually re-checked — VP-INDEX and VCM confirmed consistent |

**Result: FAIL** (MINOR) — VP-INDEX is authoritative and accurate; body VP tables in 5 BC files are stale. Reported as C4-006 and C4-007.

---

## 3. Dependency Acyclicity

**Not applicable — Phase 1.** No story files exist yet. Dependency graph check will be performed in Phase 2 post-story decomposition.

---

## 4. Architecture Alignment

### 4.1 Module Coverage

All 17 modules declared in `module-decomposition.md` are covered by BCs per `bc-module-map.md`. No unregistered module references found.

### 4.2 Component Consistency

`bc-module-map.md` is the authoritative BC-to-module-to-VP mapping document. Inconsistency found in the Formal VPs columns for the SS-06 slug module:

| Row | Column | Current Value | Correct Value | Finding |
|-----|--------|--------------|---------------|---------|
| BC-2.06.001 | Formal VPs | VP-001, VP-002, VP-012, VP-018 | VP-001, VP-002, VP-012, VP-018, VP-026 | C4-005 |
| BC-2.06.002 | Formal VPs | VP-003 | VP-003, VP-026 | C4-005 |

The INC-MAP-001 closure (bc-module-map.md v1.1) correctly added VP-025 to BC-2.08.001/002/004. The BI-005 closure did not follow the same discipline for VP-026.

**Result: FAIL** — bc-module-map.md SS-06 VP columns are stale after VP-026 addition.

---

## 5. Acceptance Criteria Quality

**Not applicable — Phase 1.** No story files exist. AC quality checks are scheduled for Phase 2 consistency gate.

---

## 6. Story Sizing

**Not applicable — Phase 1.** No story files exist.

---

## 7. Priority Consistency

**Not applicable — Phase 1.** No story files exist.

---

## 8. L1 to L2 to L3 to L4 Chain Completeness

> Every L1 brief section must trace to L2 CAP, every CAP to BC, every BC to story (Phase 2+).
> L4 VPs must trace to BCs. Gaps must have explicit justification.

### L1 to L2 to L3 to L4 Chain Overview

| Level | Artifact | Count | Traced Forward | Traced Backward | Coverage |
|-------|----------|-------|---------------|----------------|----------|
| L1 | Product Brief requirements (R1-R8) | 8 | 8 to L2 CAPs | N/A | 100% |
| L2 | Domain Capabilities (CAP-NNN) | 14 | 14 to L3 BCs | 14 to L1 | 100% |
| L2 | Domain Invariants (DI-NNN) | 13 | 13 with VP coverage | — | 100% |
| L3 | Behavioral Contracts (BC-S.SS.NNN) | 66 | 26 VPs covering them | 66 to L2 CAPs | 100% |
| L4 | Verification Properties (VP-NNN) | 26 | N/A | 26 to L3 BCs | 100% |
| Stories | (Phase 2) | 0 | — | — | — |

Structural perimeter is complete. Defects are semantic references within documents (resolves-but-wrong DI citations) and stale secondary documents not updated after BI-005 closure.

### Broken Chains

| Gap ID | From | To | Missing Link | Impact | Priority |
|--------|------|----|-------------|--------|----------|
| CHAIN-001 | `capabilities.md` CAP-006 (cites DI-012) | `BC-2.06.001.md` Traceability DI field | BC-2.06.001 cites DI-008 (wrong ID, wrong semantics) | Story-writer reads wrong governing invariant for slug algorithm | P0 |
| CHAIN-002 | `capabilities.md` CAP-006 (cites DI-013) | `BC-2.06.002.md` Traceability DI field | BC-2.06.002 cites DI-008 (wrong ID, wrong semantics) | Story-writer reads wrong governing invariant for duplicate counter | P0 |
| CHAIN-003 | `invariants.md` DI-012 (added v1.5) | `BC-INDEX.md` DI Coverage table | No row for DI-012; enforcing BC not declared at index level | DI-012 traceability invisible at index level | P1 |
| CHAIN-004 | `invariants.md` DI-013 (added v1.5) | `BC-INDEX.md` DI Coverage table | No row for DI-013; enforcing BC not declared at index level | DI-013 traceability invisible at index level | P1 |
| CHAIN-005 | DI-012 / DI-013 (added 2026-08-06) | `prd.md` §7 RTM L2 Invariants column | RTM L2 Invariants shows `—` for both slug BCs | PRD RTM false claim: no DI governs slug correctness | P1 |
| CHAIN-006 | VP-026 (VP-INDEX BC-to-VP table) | `bc-module-map.md` SS-06 Formal VPs | VP-026 absent from both slug BC rows | Canonical VP list in architecture is incomplete | P1 |

### Orphaned Artifacts

No truly orphaned artifacts found. All CAPs, BCs, VPs, DIs, and ADRs participate in at least one forward and one backward trace. The chains above are broken internal references (wrong ID or missing entry), not orphans.

---

## 9. AC Completeness Coverage

**Not applicable — Phase 1.** No story files exist for BC clause-to-AC mapping. This check is scheduled for the Phase 2 consistency gate after story decomposition.

> Gate threshold (for future): >= 90% weighted overall across L1 BC Clause (50%), L2 Edge Case/Error (30%), and L3 Cross-Cutting (20%) checks.

### 9.1 BC Clause Coverage (Level 1)

Not applicable — Phase 1.

**L1 Score:** N/A

### 9.2 Edge Case & Error Coverage (Level 2)

Not applicable — Phase 1.

**L2 Score:** N/A

### 9.3 Cross-Cutting Coverage (Level 3)

Not applicable — Phase 1. NFR-001/002/008 are present in nfr-catalog.md; story-level coverage is deferred to Phase 2.

**L3 Score:** N/A

### 9.4 AC Completeness Summary

Not applicable — Phase 1.

**Gate Result:** DEFERRED (threshold: >= 90% weighted overall; evaluated at Phase 2 gate)

---

## 10. ASM/R Traceability

> Validates that assumptions and risks from the L2 Domain Spec are properly traced,
> covered by holdout scenarios and stories, and have consistent status across artifacts.

### 10.1 Assumption Coverage

Brief requirements (R1-R8) traced to BCs per BC-INDEX Requirements Traceability table. All 8 requirements covered.

| Metric | Value | Status |
|--------|-------|--------|
| Brief requirements (R1-R8) with BC coverage | 8/8 | pass |
| DIs (DI-001..013) with VP coverage | 13/13 | pass |
| ADRs (ADR-001..007) registered in ARCH-INDEX | 7/7 | pass |

### 10.2 Risk Register Coverage

NFR coverage against VPs and architecture:

| R-NNN | Description | Status | Category | Impact | Traced To | NFR? | Architecture? | Coverage |
|-------|-------------|--------|----------|--------|-----------|------|---------------|----------|
| NFR-001 | 5s p95 on 500-file corpus (Apple Silicon) | open | performance | H | benches/ (hyperfine manual) | NFR-001 | performance-architecture.md | full |
| NFR-002 | Deterministic output | open | correctness | M | VP-011 | NFR-002 | — | full |
| NFR-008 | CI regression gate p95 | open | performance | M | VP-022 (label drift C4-008) | NFR-008 | app module | full (label fix needed) |

### 10.3 ASM/R Gate Summary

| Metric | Value | Threshold | Status |
|--------|-------|-----------|--------|
| Brief requirements (R1-R8) with BC coverage | 8/8 | 100% | pass |
| NFRs with validation method | 3/3 | 100% | pass |
| DIs with VP coverage | 13/13 | 100% | pass |
| ADRs registered in ARCH-INDEX | 7/7 | 100% | pass |
| Unvalidated ASMs after Phase 3 | N/A | 0 | deferred |

---

## Cross-Reference Validation

### ID Consistency

| Check | Status | Issues |
|-------|--------|--------|
| BC IDs unique (BC-S.SS.NNN) | pass | None |
| VP IDs unique (VP-NNN) | pass | None |
| CAP IDs unique (CAP-NNN) | pass | None |
| DI IDs unique (DI-NNN) | pass | None |
| BC traces to valid CAP | pass | None |
| VP traces to valid BC (VP-INDEX) | pass | None |
| BC Traceability→DI semantic correctness | fail | BC-2.06.001 cites DI-008 (should be DI-012); BC-2.06.002 cites DI-008 (should be DI-013) |
| VP-022 source_bc semantic correctness | fail (minor) | source_bc="NFR-001" but VP validates NFR-008 |

### Naming Convention Compliance

| Convention | Expected Pattern | Violations |
|-----------|-----------------|------------|
| BC naming | BC-S.SS.NNN | None detected |
| VP naming | VP-NNN | None detected |
| CAP naming | CAP-NNN | None detected |
| DI naming | DI-NNN | None detected |
| Error taxonomy | E-xxx-NNN | Not re-checked (spec-lint scope) |

### Canonical Frontmatter Validation

All 22 scanned files have canonical frontmatter. Representative sample:

| Artifact | document_type | level | version | producer | traces_to | Status |
|----------|--------------|-------|---------|----------|-----------|--------|
| BC-2.06.001.md | present | present | present | present | present | pass |
| BC-2.06.002.md | present | present | present | present | present | pass |
| BC-INDEX.md | present | present | present | present | present | pass |
| VP-INDEX.md | present | present | present | present | present | pass |
| invariants.md | present | present | present | present | present | pass |
| capabilities.md | present | present | present | present | present | pass |
| bc-module-map.md | present | present | present | present | present | pass |
| prd.md | present | present | present | present | present | pass |
| nfr-catalog.md | present | present | present | present | present | pass |

---

## Spec vs Implementation Drift

Drift introduced by the BI-005 spec-level closure (VP-026 + DI-012/DI-013 additions, 2026-08-06) that was not fully propagated to secondary reference documents:

| Artifact | Spec Version | Implementation State | Drift Detected | Notes |
|----------|-------------|---------------------|---------------|-------|
| `behavioral-contracts/ss-06/BC-2.06.001.md` | v1.3 (2026-08-05) | outdated | yes | DI-008 in Traceability should be DI-012; VP-026 missing from body VP table |
| `behavioral-contracts/ss-06/BC-2.06.002.md` | v1.2 (2026-08-05) | outdated | yes | DI-008 in Traceability should be DI-013; VP-026 missing from body VP table |
| `behavioral-contracts/BC-INDEX.md` | v1.6 (2026-08-05) | outdated | yes | DI-012 and DI-013 rows absent from DI Coverage table |
| `prd.md` §7 RTM | v1.9 | outdated | yes | BC-2.06.001/002 L2 Invariants column shows `—`; should be DI-012/DI-013 |
| `architecture/bc-module-map.md` | v1.2 (2026-08-06) | outdated | yes | VP-026 absent from SS-06 Formal VPs columns |
| `behavioral-contracts/ss-08/BC-2.08.001.md` | — | outdated | yes (minor) | VP-025 missing from body VP table (INC-MAP-001 gap) |
| `behavioral-contracts/ss-08/BC-2.08.002.md` | — | outdated | yes (minor) | VP-025 missing from body VP table |
| `behavioral-contracts/ss-08/BC-2.08.004.md` | — | outdated | yes (minor) | VP-025 missing from body VP table |
| `verification-properties/vp-022-regression-gate.md` | v1.1 | outdated | yes (minor) | source_bc="NFR-001"; should be NFR-008 |
| `prd-supplements/nfr-catalog.md` | v1.3 | outdated | yes (minor) | NFR-006 target says "16 worked examples"; corpus is 15 |
| `verification-properties/VP-INDEX.md` | v1.5 (2026-08-06) | current | no | Correctly updated for VP-026 |
| `architecture/verification-architecture.md` | v1.8 (2026-08-06) | current | no | Correctly updated for VP-026 |
| `architecture/verification-coverage-matrix.md` | v1.7 (2026-08-06) | current | no | Correctly updated for VP-026 |
| `module-criticality.md` | v1.5 (2026-08-06) | current | no | DI-003 stale ref replaced with DI-012/DI-013 |
| `domain-spec/failure-modes.md` | v1.5 (2026-08-06) | current | no | FM-002 closure note correctly updated |
| `domain-spec/invariants.md` | v1.6 (2026-08-06) | current | no | DI-012/DI-013 correctly added |
| `domain-spec/capabilities.md` | v1.5 (2026-08-06) | current | no | CAP-006 correctly cites DI-012/DI-013 |

---

## Findings

### Critical

None.

### Major

**C4-001 — BC-2.06.001 Traceability cites DI-008 (resolves-but-wrong; should be DI-012)**

File: `.factory/specs/behavioral-contracts/ss-06/BC-2.06.001.md` — Traceability section, L2 Domain Invariants field.

BC-2.06.001 records `L2 Domain Invariants | DI-008`. DI-008 is "Anchor Table Built Before Any Incoming Link Is Validated" — a two-pass timing invariant with no semantic connection to github-slugger v2 character-level transformation rules. The correct governing invariant is DI-012 (Slug Computation Fidelity), added to `invariants.md` v1.5 on 2026-08-06 and explicitly cited by `capabilities.md` v1.5. The DI-008 ID resolves (no broken link) — this is the resolves-but-wrong class that spec-lint cannot catch. BC-2.06.001 was at v1.3 when DI-012 was added; the BI-005 closure propagated DI-012 to six primary surfaces but not to BC-2.06.001.

Impact: Story-writer reads wrong governing rule for slug algorithm; DI-012 acceptance criteria (7 rules, FM-001/FM-003 failure classes) not prompted for Phase 2 stories.

Fix: Update BC-2.06.001 Traceability → L2 Domain Invariants: `DI-008` → `DI-012, DI-013`.

Owner: spec-steward

---

**C4-002 — BC-2.06.002 Traceability cites DI-008 (resolves-but-wrong; should be DI-013)**

File: `.factory/specs/behavioral-contracts/ss-06/BC-2.06.002.md` — Traceability section, L2 Domain Invariants field.

BC-2.06.002 records `L2 Domain Invariants | DI-008`. The governing invariant for the duplicate-heading counter is DI-013 (Anchor-Key Uniqueness within a File), added to `invariants.md` v1.5 on 2026-08-06. FM-002 (1-based counter bug) is re-anchored to DI-013 per DD-027. Same root cause as C4-001.

Impact: FM-002 discriminator obligation (0-based vs. 1-based counter) — the subtlest correctness requirement in the slug subsystem — is not associated with any visible domain rule from the BC body. VP-026 oracle R-001 (FM-002 discriminator) is effectively invisible in the BC.

Fix: Update BC-2.06.002 Traceability → L2 Domain Invariants: `DI-008` → `DI-013`.

Owner: spec-steward

---

**C4-003 — BC-INDEX Domain Invariant Coverage table stops at DI-011; DI-012 and DI-013 absent**

File: `.factory/specs/behavioral-contracts/BC-INDEX.md` — Domain Invariant Coverage table.

DI-012 and DI-013 were added to `invariants.md` v1.5 on 2026-08-06. BC-INDEX was last updated 2026-08-05 (v1.6) and was not included in the BI-005 spec-level closure surface list. Missing rows should be:
- `| DI-012 | Slug computation fidelity (github-slugger v2 algorithm, all 7 rules) | BC-2.06.001 |`
- `| DI-013 | Anchor-key uniqueness / per-file duplicate-counter injectivity | BC-2.06.002 |`

Impact: Story-writers using BC-INDEX as Phase 2 entry point do not see the DI-012/DI-013 governing rule associations. Coverage claim that "all domain invariants are enforced by BCs" is visually unsupported.

Fix: Add two rows; bump version.

Owner: spec-steward

---

**C4-004 — PRD §7 RTM BC-2.06.001 and BC-2.06.002 L2 Invariants column shows `—` (stale)**

File: `.factory/specs/prd.md` — Section 7 Requirements Traceability Matrix, rows for BC-2.06.001 and BC-2.06.002.

Current: `| BC-2.06.001 | CAP-006 | — | R2b | P0 | unit/property |` and `| BC-2.06.002 | CAP-006 | — | R2b | P0 | unit |`. Adjacent rows (BC-2.05.002→DI-008, BC-2.07.001→DI-002/DI-003) correctly cite their DIs. The slug BCs remain `—` while their domain invariants now exist. (This is an RTM data row update, not a changelog entry; not subject to the immutability ruling.)

Impact: PRD RTM creates false impression that no domain invariant governs slug correctness.

Fix: BC-2.06.001 L2 Invariants `—` → `DI-012`; BC-2.06.002 L2 Invariants `—` → `DI-013`. Bump PRD version with changelog entry.

Owner: product-owner

---

**C4-005 — bc-module-map.md SS-06 Formal VPs columns missing VP-026**

File: `.factory/specs/architecture/bc-module-map.md` — SS-06 section, BC table rows for BC-2.06.001 and BC-2.06.002.

Current: BC-2.06.001 Formal VPs = `VP-001, VP-002, VP-012, VP-018`; BC-2.06.002 Formal VPs = `VP-003`. VP-INDEX (authoritative) shows VP-026 for both. The INC-MAP-001 closure correctly added VP-025 to bc-module-map.md for anchor-resolver BCs; the BI-005 closure did not follow the same discipline.

Impact: Story-writers decomposing SS-06 stories would see an incomplete VP list for BC-2.06.001/002, potentially omitting the VP-026 differential oracle from Phase 3 planning.

Fix: BC-2.06.001 Formal VPs → append VP-026; BC-2.06.002 Formal VPs → `VP-003, VP-026`. Bump version.

Owner: architect

### Minor

**C4-006 — BC-2.06.001 and BC-2.06.002 body Verification Properties tables missing VP-026**

Files: `.factory/specs/behavioral-contracts/ss-06/BC-2.06.001.md` and `BC-2.06.002.md` — body Verification Properties tables.

VP-INDEX is authoritative; body tables are convenience duplicates. BC-2.06.001 body lists VP-001, VP-002, VP-018 (missing VP-026). BC-2.06.002 body lists VP-003 (missing VP-026). Fix: add VP-026 rows to both BC body tables.

Owner: spec-steward

---

**C4-007 — BC-2.08.001, BC-2.08.002, BC-2.08.004 body Verification Properties tables missing VP-025**

Files: `.factory/specs/behavioral-contracts/ss-08/BC-2.08.001.md`, `BC-2.08.002.md`, `BC-2.08.004.md`.

When VP-025 was added (INC-MAP-001), bc-module-map.md was updated but the individual BC body VP tables were not. VP-INDEX correctly shows VP-025 for all three. Fix: add VP-025 rows to each BC body Verification Properties table.

Owner: spec-steward

---

**C4-008 — VP-022 labeled NFR-001 throughout; validates NFR-008 (CI regression gate)**

Files: `vp-022-regression-gate.md` (source_bc), `VP-INDEX.md` (DI column), `verification-architecture.md` (DI column), `verification-coverage-matrix.md` (DI column).

VP-022 measures p95 <= ~500ms on CI regression corpus — the metric defined by NFR-008 (CI Performance Regression Gate). NFR-001 is the 5s acceptance ceiling validated manually by hyperfine. `nfr-catalog.md` NFR-008 correctly names VP-022 as its Validation Method; VP-022 itself labels source_bc as NFR-001. One-directional: NFR-008→VP-022 exists; VP-022→NFR-008 does not.

Fix: VP-022 source_bc → "NFR-008"; DI column in VP-INDEX, verification-architecture.md, verification-coverage-matrix.md → "NFR-008".

Owner: spec-steward

---

**C4-009 — NFR-006 target says "16 worked examples"; actual corpus has 15**

File: `.factory/specs/prd-supplements/nfr-catalog.md` — NFR-006 Target field.

NFR-006: "100% — all 16 worked examples + DEC-001 collision case pass." VP-INDEX DI Coverage Summary and VP-018 SLUG_CORPUS both say 15 items. `test-vectors.md` §7 has 16 vectors (TV-S001..TV-S016) where TV-S012 IS the DEC-001 collision case. NFR-006 counts it separately (implying 17 total). Root cause: NFR-006 was written before VP-018 v1.1 removed a duplicate row; count never revised.

Fix: Update NFR-006 Target to "100% — all 15 worked examples in SLUG_CORPUS + DEC-001 collision-bump triple (separate test function) pass" and align counting methodology with VP-INDEX.

Owner: spec-steward

---

## Validation Gate Result

**FAIL** — 5 MAJOR findings, 4 MINOR findings.

Blocking findings:
- C4-001: BC-2.06.001 cites DI-008 (wrong) instead of DI-012
- C4-002: BC-2.06.002 cites DI-008 (wrong) instead of DI-013
- C4-003: BC-INDEX missing DI-012/DI-013 rows in DI Coverage table
- C4-004: PRD RTM BC-2.06.001/002 L2 Invariants column stale (`—`)
- C4-005: bc-module-map.md SS-06 VP columns missing VP-026

All 5 MAJOR findings share the same root cause: the BI-005 spec-level closure propagated DI-012/DI-013 and VP-026 to six primary surfaces but omitted five secondary-reference surfaces. A single targeted remediation pass touching the five files in C4-001 through C4-005 would clear all MAJOR findings.

**Recommendation:** Gate Phase 2 SS-06 story decomposition on resolving C4-001 through C4-005. Subsystems SS-01 through SS-05 and SS-07 through SS-14 are clear to proceed.

---

## Overall Metrics

| Metric | Value |
|--------|-------|
| **Total Checks** | 23 (10 template + 13 supplemental perimeter checks) |
| **Passed** | 18 |
| **Failed** | 5 (MAJOR) + 4 (MINOR) |
| **Warnings** | 0 |
| **Critical findings** | 0 |
| **Major findings** | 5 |
| **Minor findings** | 4 |
| **Overall Status** | inconsistencies-found |

**Perimeter judgment:** The spec package is structurally complete — all R1–R8 requirements, 14 CAPs, 66 BCs, 13 DIs, 26 VPs, and 7 ADRs participate in complete forward and backward traces. The defects are limited to secondary-reference quality for the SS-06 slug subsystem: five documents were not updated when DI-012/DI-013 and VP-026 were added on 2026-08-06 as part of the BI-005 spec-level closure. The BI-005 agent updated the explicitly-listed six primary surfaces but missed five secondary-reference surfaces that the INC-MAP-001 closure had established as the expected maintenance pattern.

**BI-005 Integration Surface Audit:**

| Surface | What Was Missed | Finding |
|---------|----------------|---------|
| `behavioral-contracts/ss-06/BC-2.06.001.md` | DI-008→DI-012 Traceability fix; VP-026 in VP table | C4-001, C4-006 |
| `behavioral-contracts/ss-06/BC-2.06.002.md` | DI-008→DI-013 Traceability fix; VP-026 in VP table | C4-002, C4-006 |
| `behavioral-contracts/BC-INDEX.md` | DI-012 and DI-013 rows in DI Coverage table | C4-003 |
| `prd.md` §7 RTM | BC-2.06.001 DI `—`→DI-012; BC-2.06.002 DI `—`→DI-013 | C4-004 |
| `architecture/bc-module-map.md` | VP-026 in SS-06 Formal VPs columns | C4-005 |

---

## Appendix: Validation Methodology

**Audit pass:** Pass 4 — Perimeter and Cross-Document Consistency. Fresh context, read-only. No modification to any spec file.

**What this pass covers:**
1. Orphan and dangling-end detection: BCs without VPs, VPs referenced by nothing, DIs without BC coverage, CAPs without BC coverage, unreferenced ADRs
2. End-to-end traceability chains in both directions: brief → capability → BC → VP
3. Coverage gaps against R1–R8 and NFR-001/002/008
4. Convention consistency: naming, ID formats, frontmatter fields, version/changelog discipline
5. Cross-document contradictions: same fact stated differently in two places
6. Resolves-but-wrong class: IDs that exist but are semantically incorrect for the claim
7. BI-005 integration surface audit: VP-026 and DI-012/DI-013 additions propagated to ALL surfaces

**What spec-lint already enforces (not re-checked):**
BC title/H1/PRD-section sync, EC-ID injectivity, ID reference resolution (existence), counts/tallies, holdout-boundary leakage, ADR exit-code/reason-code consistency, INDEX-to-file bidirectional integrity.

**Standing rulings honored (not reported):**
- `prd.md:720` ("33 with a real VP (VP-001..VP-024)") — immutable historical record, ruling D-034
- 25 `[filled by story-writer]` placeholders — legitimate until Phase 2
- `--quiet`, `--offline`, `--insecure`, `--hidden` — dropped non-goals (D-011)
- `.MD`/`.markdown`/`.mdx` discovery — non-goal (D-012)
- INC-MAP-004 — accepted gap
- BI-007 — VP-026 unimplemented; Phase 3 has not started
- Design-system / UI / Nielsen artifacts — CLI product, no UI surface
- Phase 0 codebase ingestion — greenfield

**Validation criteria applied:** Criteria 1–80 from consistency-validator AGENTS.md; notably criteria 3 (CAP→BC coverage), 7 (VP→BC links), 8 (L1–L4 chain completeness), 13 (data model consistency), 16 (VP story match), 18 (canonical frontmatter), 29 (module-criticality currency), 38 (NFR-to-story coverage), 70–73 (semantic anchoring integrity), 74 (DI→BC traceability), 78–80 (VP-INDEX architecture coherence).

_Audit completed by vsdd-factory:consistency-validator, fresh context, pass 4, 2026-08-06._
