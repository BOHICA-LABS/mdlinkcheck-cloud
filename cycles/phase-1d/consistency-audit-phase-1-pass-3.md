---
document_type: consistency-report
level: ops
version: "1.0"
status: "fail"
producer: consistency-validator
timestamp: 2026-08-05T00:00:00Z
phase: phase-1d
inputs:
  - .factory/specs/behavioral-contracts/BC-INDEX.md
  - .factory/specs/verification-properties/VP-INDEX.md
  - .factory/specs/architecture/ARCH-INDEX.md
  - .factory/specs/domain-spec/L2-INDEX.md
  - .factory/holdout-scenarios/HS-INDEX.md
  - .factory/specs/prd.md
  - .factory/specs/behavioral-contracts/ss-01/BC-2.01.009.md
  - .factory/specs/behavioral-contracts/ss-07/BC-2.07.006.md
  - .factory/specs/behavioral-contracts/ss-10/BC-2.10.002.md
  - .factory/specs/behavioral-contracts/ss-10/BC-2.10.009.md
  - .factory/specs/behavioral-contracts/ss-14/BC-2.14.001.md
  - .factory/specs/behavioral-contracts/ss-14/BC-2.14.002.md
  - .factory/specs/behavioral-contracts/ss-14/BC-2.14.003.md
  - .factory/specs/architecture/system-overview.md
  - .factory/specs/architecture/purity-boundary-map.md
  - .factory/specs/architecture/verification-architecture.md
  - .factory/specs/architecture/verification-coverage-matrix.md
  - .factory/specs/architecture/api-surface.md
  - .factory/specs/module-criticality.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/prd-supplements/error-taxonomy.md
  - .factory/specs/prd-supplements/nfr-catalog.md
  - .factory/specs/prd-supplements/test-vectors.md
  - .factory/policies.yaml
  - .factory/STATE.md
input-hash: "b96ddf9"
traces_to: .factory/specs/prd.md
---

# Consistency Validation Report: mdlinkcheck-cloud

## Report Metadata

| Field | Value |
|-------|-------|
| **Product** | mdlinkcheck-cloud |
| **Generated** | 2026-08-05T00:00:00Z |
| **Generator** | consistency-validator |
| **Pass** | 3 (prior: consistency-audit-phase-1-pass-2.md) |
| **Artifacts Scanned** | 24 primary; 66 BC files spot-checked |
| **Phase scope** | Phase 1 spec package (L1..L4 specs; no stories yet) |

## Summary

| # | Check | Result |
|---|-------|--------|
| 1 | L2 to L3 Requirement Coverage | pass |
| 2 | L3 to L4 Verification Property Coverage | pass |
| 3 | Dependency Acyclicity | n/a (no stories in Phase 1) |
| 4 | Architecture Alignment | pass |
| 5 | Acceptance Criteria Quality | n/a (no stories in Phase 1) |
| 6 | Story Sizing (all <= 13 points) | n/a (no stories in Phase 1) |
| 7 | Priority Consistency | pass |
| 8 | L1 to L2 to L3 to L4 Chain Completeness | pass |
| 9 | AC Completeness Coverage | n/a (no stories in Phase 1) |
| 10 | ASM/R Traceability | pass |

## 1. L2 to L3 Requirement Coverage

### 1.1 Domain Capabilities to Behavioral Contracts

All 14 capabilities (CAP-001..CAP-014) are covered by at least one BC. BC-INDEX v1.6 catalogs
66 BCs across 14 subsystems (SS-01..SS-14). CAP-to-SS mapping is 1:1 per domain-spec
capabilities.md. No orphaned capabilities.

| CAP-NNN | Subsystem | BC count | Coverage |
|---------|-----------|----------|----------|
| CAP-001 | SS-01 File Discovery | 9 | full |
| CAP-002 | SS-02 Markdown Parsing | 4 | full |
| CAP-003 | SS-03 Link Extraction | 6 | full |
| CAP-004 | SS-04 Code Context Exclusion | 3 | full |
| CAP-005 | SS-05 Anchor Table Construction | 3 | full |
| CAP-006 | SS-06 Heading Slug Computation | 2 | full |
| CAP-007 | SS-07 Relative Path Resolution | 8 | full |
| CAP-008 | SS-08 Anchor Resolution | 4 | full |
| CAP-009 | SS-09 External URL Syntax Validation | 2 | full |
| CAP-010 | SS-10 External URL Liveness Checking | 10 | full |
| CAP-011 | SS-11 Filter Application | 4 | full |
| CAP-012 | SS-12 Text Report Generation | 5 | full |
| CAP-013 | SS-13 JSON Report Generation | 2 | full |
| CAP-014 | SS-14 Exit Code Determination | 4 | full |

**Result: PASS** — all 14 capabilities covered; 0 orphans.

## 2. L3 to L4 Verification Property Coverage

### 2.1 Behavioral Contracts to Verification Properties

VP-INDEX v1.2 catalogs 24 VPs (VP-001..VP-024) across 17 modules. All VPs reference valid
source BCs. VP-INDEX arithmetic: kani(7) + proptest(7) + fuzz(2) + integration(7) + unit(1) = 24.
Priority split: p0(7) + p1(9) + test_sufficient(8) = 24. Both arithmetic checks pass.

Verification-coverage-matrix.md v1.4 per-module VP counts match VP-INDEX per-module data.
Verification-architecture.md v1.4 Provable Properties Catalog includes all 24 VPs with
correct tool and phase assignments. Module-criticality.md v1.3 VP counts corrected and
consistent with VP-INDEX.

| BC range | VPs assigned | Proof method | Status |
|----------|-------------|-------------|--------|
| BC-2.06.001/002 (slug) | VP-001, VP-002, VP-003 | kani | ✓ |
| BC-2.07.003 (NFC path) | VP-004, VP-008 | kani, proptest | ✓ |
| BC-2.14.001/002/003 (exit codes) | VP-005, VP-006 | unit | ✓ |
| BC-2.10.002 (liveness partition) | VP-007 | kani | ✓ |
| BC-2.08.003 (fragment split) | VP-009, VP-010 | kani, proptest | ✓ |
| BC-2.03.001/003 (link extract) | VP-011, VP-012 | proptest, fuzz | ✓ |
| BC-2.05.001/002 (anchor table) | VP-013, VP-014 | proptest, kani | ✓ |
| BC-2.11.001/002 (filter) | VP-015, VP-016 | kani, proptest | ✓ |
| BC-2.10.008/009 (HTTP) | VP-017..VP-021 | integration | ✓ |
| VP-022 (perf regression gate) | BC-2.10.* | integration benchmark | ✓ |
| VP-023, VP-024 | determinism, memory | integration | ✓ |

**Result: PASS** — all 24 VPs reference valid BCs; arithmetic consistent; 0 orphaned VPs.

## 3. Dependency Acyclicity

**N/A — Phase 1 only.** Story decomposition has not begun. No story dependency graphs exist.
This check will be evaluated at the Phase 2 consistency gate.

## 4. Architecture Alignment

### 4.1 Module Coverage

Architecture defines 17 pure-core modules (slug, fragment, anchor_table, link_extractor,
path_resolver, anchor_resolver, url_classifier, http_verdict, filter, reporter, verdict) plus
effectful-shell modules (cli, scanner, http_client, app). Module-criticality.md v1.3 lists all
17 modules with correct VP counts. Verification-coverage-matrix.md rows match architecture
module decomposition.

| Architecture document | Version | Status |
|----------------------|---------|--------|
| ARCH-INDEX.md | v1.1 | ✓ includes feasibility-review.md |
| system-overview.md | v1.5 | ✓ three-input exit_code; D-012; D-011 |
| purity-boundary-map.md | v1.3 | ✓ three-input exit_code corrected |
| verification-architecture.md | v1.4 | ✓ VP-021..024 present |
| verification-coverage-matrix.md | v1.4 | ✓ totals match VP-INDEX |
| api-surface.md | v1.3 | ✓ authoritative three-input signature |
| module-criticality.md | v1.3 | ✓ per-module VP counts corrected |

### 4.2 Component Consistency

exit_code signature: all architecture documents use `verdict::exit_code(findings, io_errors,
config_error) → u8`. No `compute_exit_code` found in specs/. No two-input form found.

**Result: PASS**

## 5. Acceptance Criteria Quality

**N/A — Phase 1 only.** Stories have not been written. AC quality will be evaluated at the
Phase 2 consistency gate.

## 6. Story Sizing

**N/A — Phase 1 only.** No stories exist yet. Story sizing will be evaluated at the Phase 2
consistency gate.

## 7. Priority Consistency

BC-INDEX v1.6 priority split: P0 = 53, P1 = 13, Total = 66. Priority assignments are consistent
with product brief requirements (R1..R8) and key differentiators (KD-001..KD-005). SS-10
(External URL Liveness) P0/P1 split verified: BC-2.10.001..007 and BC-2.10.009 are P0 (core
correctness of the three-outcome liveness model); BC-2.10.008 is P1 (scalability tuning).
No P0 BC has a missing or undefined capability anchor.

**Result: PASS**

## 8. L1 to L2 to L3 to L4 Chain Completeness

### L1 to L2 to L3 to L4 Chain Overview

| Level | Artifact | Count | Traced Forward | Traced Backward | Coverage |
|-------|----------|-------|---------------|----------------|----------|
| L1 | Product Brief requirements (R1..R8) | 8 | 8 to L2 | N/A | 100% |
| L2 | Domain Capabilities (CAP-001..CAP-014) | 14 | 14 to L3 | 14 to L1 | 100% |
| L3 | Behavioral Contracts (BC-S.SS.NNN) | 66 | 66 to L4 | 66 to L2 | 100% |
| L4 | Verification Properties (VP-NNN) | 24 | N/A | 24 to L3 | 100% |

### Broken Chains

No broken chains detected. All 66 BCs reference valid CAP-NNN capability anchors.
All 24 VPs reference valid BC-S.SS.NNN source BCs. L2-INDEX DD count 26 (DD-001..DD-026),
R count 9 (R-001..R-009) both verified correct. HS-INDEX 5 active holdouts
(HS-001, HS-004..HS-007) all reference valid wave-scenarios files.

### Orphaned Artifacts

No orphaned artifacts detected. Feasibility-review.md is listed in ARCH-INDEX Document Map
(MISSING-INDEX-001 FIXED). All domain-spec shards (11 files) listed in L2-INDEX.

**Result: PASS**

## 9. AC Completeness Coverage

**N/A — Phase 1 only.** Story acceptance criteria have not been written. AC completeness will
be evaluated at the Phase 2 consistency gate once stories exist.

## 10. ASM/R Traceability

### 10.1 Assumption Coverage

ASM-001..ASM-006 (from domain-spec/assumptions.md) are referenced in STATE.md and L2-INDEX.
All assumptions have Status documented. Holdout scenarios that exist (HS-001, HS-004..HS-007)
align with their BC clause targets. The ASM lifecycle fields are consistent across L2-INDEX,
STATE.md, and domain-spec.

### 10.2 Risk Register Coverage

R-001..R-009 all present in domain-spec/risks.md. R-001..R-009 are referenced in L2-INDEX
with non-empty Traced To columns. NFR-catalog.md v1.3 documents NFR-008 CI regression gate
(~500ms p95, VP-022, blocking merge) per D-013 two-tier performance model.

### 10.3 ASM/R Gate Summary

| Metric | Value | Status |
|--------|-------|--------|
| HIGH-impact ASMs with holdout scenario | not yet auditable (Phase 1) | n/a |
| HIGH-impact R-NNNs with architecture mitigation | R-001..R-009 all in risks.md | pass |
| R-NNN NFR candidates with corresponding NFR | NFR-001..NFR-008 present | pass |
| DD count (decisions.md) | 26 (DD-001..DD-026) | pass |

**Result: PASS**

---

## Cross-Reference Validation

### ID Consistency

| Check | Status | Issues |
|-------|--------|--------|
| BC IDs unique | pass | 66 unique IDs; no duplicates found in BC-INDEX |
| VP IDs unique | pass | 24 unique IDs; no duplicates found in VP-INDEX |
| CAP IDs unique | pass | 14 unique IDs (CAP-001..CAP-014) |
| BC traces to valid CAP | pass | All 66 BC capability fields reference valid CAP-NNN |
| VP traces to valid BC | pass | All 24 VP source_bc fields reference valid BC-S.SS.NNN |
| Story ACs trace to valid BC | n/a | No stories in Phase 1 |
| DD IDs sequential and complete | pass | DD-001..DD-026 (26 total); no gaps |
| R IDs sequential and complete | pass | R-001..R-009 (9 total); no gaps |
| Policies | pass | POL-1..POL-19 (19 total) in policies.yaml and STATE.md |

### Naming Convention Compliance

| Convention | Expected Pattern | Violations |
|-----------|-----------------|------------|
| BC naming | BC-S.SS.NNN | 0 violations |
| VP naming | VP-NNN | 0 violations |
| CAP naming | CAP-NNN | 0 violations |
| Domain decisions | DD-NNN | 0 violations |
| Error taxonomy | E-xxx-NNN | 0 violations (13-code closed set) |
| Holdout scenarios | HS-NNN | 0 violations |

### Canonical Frontmatter Validation

Spot-check of key artifacts:

| Artifact | document_type | level | version | producer | traces_to | Status |
|----------|--------------|-------|---------|----------|-----------|--------|
| BC-INDEX.md | present | present | v1.6 | present | present | pass |
| VP-INDEX.md | present | present | v1.2 | present | present | pass |
| ARCH-INDEX.md | present | present | v1.1 | present | present | pass |
| L2-INDEX.md | present | present | v1.6 | present | present | pass |
| BC-2.14.001.md | present | present | v1.1 | present | present | pass |
| BC-2.10.002.md | present | present | v1.5 | present | present | pass |
| system-overview.md | present | present | v1.5 | present | present | pass |
| purity-boundary-map.md | present | present | v1.3 | present | present | pass |

---

## Spec vs Implementation Drift

Phase 1 only — no implementation exists. Intra-spec drift findings are reported in Findings below.

| Artifact | Spec Version | Drift Detected | Notes |
|----------|-------------|---------------|-------|
| BC-INDEX.md | v1.6 | yes | DRIFT-P3-001: BC-2.10.002 title missing "— Total Partition" suffix |
| prd.md | v1.7 | yes | DRIFT-P3-004: 19 BC table entries in SS-01..04 use sentence case vs Title Case H1; DRIFT-P3-003: stale gene-transfusion obligation note |
| system-overview.md | v1.5 | yes | DRIFT-P3-005: stale BC-2.01.009 reconciliation note at line 239 |
| BC-2.07.006.md | v1.0 | yes | INCONSISTENCY-P3-001: Description/Precondition 3 contradiction about .markdown |
| BC-2.10.009.md | v1.1 | yes | INCONSISTENCY-P3-002: Postcondition 2 uses "alive" as link verdict |
| VP-INDEX.md | v1.2 | yes | INCONSISTENCY-P3-004: BC-to-VP table uses "alive" as verdict |
| error-taxonomy.md | v1.5 | no | D-018 propagated correctly |
| failure-modes.md | v1.2 | no | D-018 propagated correctly |
| module-criticality.md | v1.3 | no | VP counts corrected (REGRESSION-004 FIXED) |
| verification-coverage-matrix.md | v1.4 | no | Totals consistent |
| api-surface.md | v1.3 | no | Three-input exit_code authoritative |

---

## Findings

### Critical

None.

### Major

**DRIFT-P3-001 — BC-INDEX BC-2.10.002 Title Missing "— Total Partition" Suffix**

Severity: Major | Type: DRIFT | Policy: POL-7 (bc_h1_is_title_source_of_truth)

Files:
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/BC-INDEX.md` line 137
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-10/BC-2.10.002.md` line 34 (H1, authoritative)

Conflicting values:
- BC-INDEX line 137: `"Three-Verdict Model (alive/broken/indeterminate)"`
- BC H1 authoritative: `"Three-Verdict Model (alive/broken/indeterminate) — Total Partition"`

The "— Total Partition" suffix asserts that the three liveness outcomes form an exhaustive,
mutually exclusive partition. Its absence from BC-INDEX makes the title appear to be a vocabulary
list rather than a completeness guarantee, misleading downstream readers.

Fix: Update BC-INDEX.md line 137 to `Three-Verdict Model (alive/broken/indeterminate) — Total Partition`.
Owner: product-owner

---

**DRIFT-P3-004 — Systemic PRD Section 2 BC Title Casing Drift (SS-01..SS-04, 19 BCs)**

Severity: Major | Type: DRIFT | Policy: POL-13 (prd_section_title_bc_h1_sync)

19 BC entries in the PRD section 2 tables (prd.md) for SS-01..SS-04 use sentence case while the
authoritative BC H1 headings and BC-INDEX entries use Title Case. SS-05..SS-14 were corrected
in REGRESSION-002 remediation; SS-01..SS-04 were not fully updated.

Files:
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/prd.md` lines 102–144
- Authoritative H1: respective BC files in ss-01/, ss-02/, ss-03/, ss-04/

Affected BCs and conflicting values (PRD table entry → authoritative H1):

SS-01 (7):
- BC-2.01.001: `"Recursive \`.md\` discovery with default scan root"` → `"Recursive \`.md\` Discovery with Default Scan Root"`
- BC-2.01.002: `"Explicit PATH arguments override default root"` → `"Explicit PATH Arguments Override Default Root"`
- BC-2.01.003: `"\`.gitignore\` and \`.ignore\` exclusion during traversal"` → `"\`.gitignore\` and \`.ignore\` Exclusion During Traversal"`
- BC-2.01.006: `"File symlink following with dangling-symlink detection"` → `"File Symlink Following with Dangling-Symlink Detection"`
- BC-2.01.007: `"Path deduplication for overlapping PATH arguments"` → `"Path Deduplication for Overlapping PATH Arguments"`
- BC-2.01.008: `"Zero markdown files found yields exit 0 with stderr message"` → `"Zero Markdown Files Found Yields Exit 0 with Stderr Message"`
- BC-2.01.009: `"Non-existent or unreadable PATH argument yields exit 2"` → `"Non-Existent or Unreadable PATH Argument Yields Exit 2"`

SS-02 (3):
- BC-2.02.001: `"CommonMark + GFM AST parsing with byte-offset line numbers"` → `"CommonMark + GFM AST Parsing with Byte-Offset Line Numbers"`
- BC-2.02.003: `"Non-UTF-8 file reported as per-file I/O error; scan continues"` → `"Non-UTF-8 File Reported as Per-File I/O Error; Scan Continues"`
- BC-2.02.004: `"Explicit non-\`.md\` file argument is parsed (not skipped)"` → `"Explicit Non-\`.md\` File Argument Is Parsed (Not Skipped)"`

SS-03 (6, including 1 content-level difference):
- BC-2.03.001: `"Inline link and image extraction with kind classification"` → `"Inline Link and Image Extraction with Kind Classification"`
- BC-2.03.002: `"Full reference-style, collapsed, and shortcut link/image forms"` → `"Full Reference-Style, Collapsed, and Shortcut Link/Image Forms"`
- BC-2.03.003: `"Undefined reference label yields \`broken\` verdict"` → `"Undefined Reference Label Yields \`broken\` Verdict"`
- BC-2.03.004 (content diff): `"CommonMark \`<https://...>\` autolinks in scope; GFM bare-URLs out of scope"` → `"CommonMark Autolinks In Scope; GFM Bare-URLs Out of Scope"`
- BC-2.03.005: `"Non-http(s) schemes silently skipped with \`clean\` verdict"` → `"Non-http(s) Schemes Silently Skipped with \`clean\` Verdict"`
- BC-2.03.006: `"Footnote references excluded; escaped brackets are not links"` → `"Footnote References Excluded; Escaped Brackets Are Not Links"`

SS-04 (3, including 1 content-level difference):
- BC-2.04.001: `"Fenced code blocks and inline code spans yield no links"` → `"Fenced Code Blocks and Inline Code Spans Yield No Links"`
- BC-2.04.002 (content diff): `"Indented (4-space) code blocks and HTML comments yield no links"` → `"Indented Code Blocks and HTML Comments Yield No Links"`
- BC-2.04.003: `"ATX headings inside fenced blocks do not create anchor entries"` → `"ATX Headings Inside Fenced Blocks Do Not Create Anchor Entries"`

Fix: Update all 19 PRD section 2 table entries to exactly match the corresponding BC H1 heading.
BC H1 is the authoritative source per POL-7. Pay particular attention to BC-2.03.004 and
BC-2.04.002 which have content differences (not just casing).
Owner: product-owner

---

**INCONSISTENCY-P3-001 — BC-2.07.006 Description/Precondition 3 Contradiction About .markdown Files**

Severity: Major | Type: INCONSISTENCY | Decision: D-012 (.md only, case-sensitive)

File: `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-07/BC-2.07.006.md`

Conflicting values within a single artifact:
- Description: `"extension is NOT \`.md\` or \`.markdown\` (case-insensitive)"` — implies .markdown
  files are excluded from this contract, meaning they receive anchor resolution.
- Precondition 3: `"Files with extension \`.MD\`, \`.Md\`, \`.markdown\`, \`.mdx\`, or any other
  non-\`.md\` extension fall into this contract [existence-check only]"` — implies .markdown
  files ARE covered by this contract and receive existence-check only.

D-012 establishes `.md` is the only Markdown extension; `.markdown` is an explicit non-goal.
Precondition 3 is correct per D-012. The Description is wrong: it implies `.markdown` gets
anchor resolution (by excluding it from the "non-Markdown target" condition), which contradicts
D-012. The word "case-insensitive" in the Description is also wrong — D-012 is case-sensitive.

Fix: Correct the Description to remove "or \`.markdown\`" and "case-insensitive". Revised
Description: `"The link destination has an extension other than \`.md\` (case-sensitive, per D-012).
Files with non-\`.md\` extensions — including \`.MD\`, \`.markdown\`, \`.mdx\`, and others — receive
an existence check only; anchor resolution is skipped."`. This aligns Description with
Precondition 3 and with D-012.
Owner: product-owner

### Minor

**DRIFT-P3-002 — PRD BC-2.01.009 Table Entry Casing (Subsumed by DRIFT-P3-004)**

Severity: Minor | Type: DRIFT | Policy: POL-13

The single-BC exemplar identified in the prior pass; covered in full by DRIFT-P3-004 above.
No separate fix required beyond the DRIFT-P3-004 remediation.
Owner: product-owner

---

**DRIFT-P3-003 — PRD Stale Open Action Item for gene-transfusion-assessment.md**

Severity: Minor | Type: DRIFT

File: `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/prd.md` lines 504–505

Stale text (under v1.2 changelog, section INC-010):
`gene-transfusion-assessment.md uses "valid" for the positive external URL verdict at lines 211
and 286. [...] "valid" must be replaced with "alive" in that document.`

The note uses present tense ("uses") and prescribes an unresolved obligation ("must be replaced").
The fix was applied: gene-transfusion-assessment.md no longer contains "valid" as a verdict term
at those lines. The note is a false open action item; it will mislead anyone scanning for open
remediation obligations.

Fix: Append `[RESOLVED]` to the note, or delete it.
Owner: product-owner

---

**DRIFT-P3-005 — system-overview.md Stale BC-2.01.009 Reconciliation Note**

Severity: Minor | Type: DRIFT

File: `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/system-overview.md` line 239

Stale text:
`(Note: BC-2.01.009 requires reconciliation — if it prescribes immediate exit for a bad PATH,
that BC conflicts with DD-007 and must be updated by the product owner.)`

BC-2.01.009 was updated to v1.2 and is now correctly aligned with DD-007: nonexistent PATH
arguments are recorded into `Vec<IoError>`; scanning continues with valid paths. The
reconciliation is complete. The note is a false open obligation.

Fix: Remove the parenthetical note or append `[RESOLVED: BC-2.01.009 v1.2 aligned with DD-007]`.
Owner: architect

---

**INCONSISTENCY-P3-002 — BC-2.10.009 Postcondition 2 Uses "alive" as a Link Verdict**

Severity: Minor | Type: INCONSISTENCY | Decision: D-014 / DD-022

File: `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-10/BC-2.10.009.md` line 51

Conflicting values:
- Postcondition 2: `"The single verdict (\`alive\`, \`broken\`, or \`indeterminate\` per BC-2.10.002)
  is reported for every occurrence"`
- D-014 / DD-022: Link verdicts are `clean` / `broken` / `indeterminate`. `alive` is a URL
  liveness outcome (HTTP layer), not a link verdict. `alive` maps to link verdict `clean` in
  the two-layer model.

Fix: Replace `\`alive\`, \`broken\`, or \`indeterminate\`` with `\`clean\`, \`broken\`, or
\`indeterminate\`` in Postcondition 2, noting that "clean" is derived from liveness outcome
"alive" per the DD-022 two-layer model.
Owner: product-owner

---

**INCONSISTENCY-P3-003 — BC-INDEX DI-010 Description Uses "verdict" for Liveness Outcomes**

Severity: Minor | Type: INCONSISTENCY | Decision: D-014 / DD-022

File: `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/BC-INDEX.md` DI-010 row

Conflicting values:
- BC-INDEX DI-010 description: `"Three-verdict model: alive/broken/indeterminate"`
- D-014 / DD-022: `alive/broken/indeterminate` are URL liveness outcomes (SS-10 layer), not
  link verdicts. Calling them "verdicts" collapses the DD-022 two-layer distinction.

Fix: Change DI-010 description to `"Three-outcome HTTP liveness model: alive/broken/indeterminate
(DD-022 two-layer model)"` or similar phrasing that does not use "verdict" for this layer.
Owner: product-owner

---

**INCONSISTENCY-P3-004 — VP-INDEX BC-to-VP Table Uses "alive" as a Verdict**

Severity: Minor | Type: INCONSISTENCY | Decision: D-014 / DD-022

File: `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/VP-INDEX.md` BC-to-VP Coverage table, BC-2.10.002 row (line 206)

Conflicting values:
- VP-INDEX: `"Three-verdict model (broken/indeterminate/alive)"`
- D-014 / DD-022: "alive" is a URL liveness outcome, not a link verdict.

Fix: Update the BC-2.10.002 row description to `"URL liveness outcome partition
(alive/broken/indeterminate per DD-022; maps to link verdicts clean/broken/indeterminate)"`.
Owner: architect

---

**POTENTIAL-P3-001 — EC Sub-Variant IDs Visible in BCs for Holdout-Reserved Base IDs (Observation)**

Severity: Observation | Type: POTENTIAL (POL-18 signal concern)

Sub-variant IDs EC-079b, EC-079c (in BC-2.10.003, BC-2.10.006), EC-094a through EC-094e
(in BC-2.03.005), and EC-141b (in BC-2.13.002, BC-2.14.002) appear in behavioral contracts
with concrete inputs and expected outputs. Their base IDs (EC-079, EC-094, EC-141) are reserved
as not-yet-authored holdout scenarios in HS-INDEX.

This is NOT a confirmed POL-18 violation because the not-yet-authored holdouts may test
sufficiently different aspects from the visible sub-variants.

Action: When authoring holdout scenarios for EC-079, EC-094, and EC-141, verify that the
holdout tests a distinct edge-case aspect not covered by the existing BC sub-variant entries.
If no distinguishable aspect exists, either rename the sub-variants or burn those EC base IDs.
Owner: spec-steward

---

## Prior-Findings Resolution Table

| Prior ID | Description | Pass 3 Status | Evidence |
|----------|-------------|---------------|---------|
| HOLDOUT-001 | EC-157 holdout boundary violation | **FIXED** | HS-002 retired, EC-157 burned per HS-INDEX |
| HOLDOUT-002 | EC-158 holdout boundary violation | **FIXED** | HS-003 retired, EC-158 burned per HS-INDEX |
| MISSING-INDEX-001 | feasibility-review.md absent from ARCH-INDEX | **FIXED** | ARCH-INDEX.md v1.1 Document Map includes feasibility-review.md |
| REGRESSION-001 | BC-2.05.001 title drift in BC-INDEX | **FIXED** | BC-INDEX entry matches H1 "Three-Phase Design — Full Anchor Table Before Any Resolution" |
| REGRESSION-002 | PRD section 2 BC titles corrected | **PARTIALLY FIXED** | SS-05..14 corrected; SS-01..04 (19 BCs) still sentence-case → DRIFT-P3-004 |
| REGRESSION-003 | BC-2.07.006 .markdown extension | **PARTIALLY FIXED** | D-012 enforced elsewhere; BC-2.07.006 internal Description/Precondition contradiction persists → INCONSISTENCY-P3-001 |
| REGRESSION-004 | module-criticality.md VP count errors | **FIXED** | v1.3 corrected url_classifier, path_resolver, reporter, app counts |
| REGRESSION-005 | exit_code three-input form | **FIXED** | All specs use three-input form; no compute_exit_code remains in specs/ |
| REGRESSION-006 | Delivery model regression (D-002 local-only) | **FIXED** | D-002 superseded by D-021; no active local-only claims |
| INCONSISTENCY-001 | D-014 two-layer verdict vocabulary | **PARTIALLY FIXED** | DD-022 applied broadly; residual violations in BC-2.10.009, BC-INDEX DI-010, VP-INDEX → INCONSISTENCY-P3-002/003/004 |
| INCONSISTENCY-002 | D-014 two-layer verdict vocabulary (same root) | **PARTIALLY FIXED** | Same as INCONSISTENCY-001 |
| INCONSISTENCY-003 | error-taxonomy.md two-layer model | **FIXED** | error-taxonomy.md v1.5 documents DD-022; 400-after-GET = indeterminate |
| DRIFT-001 | gene-transfusion-assessment.md "valid" verdict | **FIXED** | File no longer uses "valid" as a verdict; stale PRD obligation note → DRIFT-P3-003 (Minor) |

---

## Validation Gate Result

**FAIL** — 3 Major findings block convergence.

Blocking findings:
1. DRIFT-P3-001: BC-INDEX BC-2.10.002 missing "— Total Partition" suffix (POL-7 violation)
2. DRIFT-P3-004: 19 BC table entries in prd.md SS-01..04 in sentence case vs authoritative Title Case H1 (POL-13 violation), including 2 content-level differences
3. INCONSISTENCY-P3-001: BC-2.07.006 internal Description/Precondition 3 contradiction about .markdown extension handling (D-012 alignment failure)

Non-blocking (Minor):
- DRIFT-P3-002 (subsumed by DRIFT-P3-004)
- DRIFT-P3-003: PRD stale gene-transfusion action item
- DRIFT-P3-005: system-overview.md stale reconciliation note
- INCONSISTENCY-P3-002: BC-2.10.009 Postcondition 2 "alive" vocabulary
- INCONSISTENCY-P3-003: BC-INDEX DI-010 "verdict" vocabulary
- INCONSISTENCY-P3-004: VP-INDEX BC-to-VP table "alive" vocabulary

Observation (not blocking):
- POTENTIAL-P3-001: EC sub-variant IDs for holdout-reserved base IDs

## Overall Metrics

| Metric | Value |
|--------|-------|
| **Total Checks (cross-document)** | ~120 |
| **Critical findings** | 0 |
| **Major findings** | 3 |
| **Minor findings** | 6 |
| **Observations** | 1 |
| **Prior findings FIXED** | 9 of 13 |
| **Prior findings PARTIALLY FIXED** | 3 of 13 |
| **Prior findings STILL OPEN** | 0 of 13 |
| **New regressions** | 0 |
| **Overall Status** | inconsistencies-found |

Estimated consistency score: 84% (19 sentence-case PRD title entries + 1 BC-INDEX title suffix
drop + 1 BC internal contradiction + 3 D-014 residuals + 2 stale obligation notes, out of
approximately 120 cross-document consistency checks).

All three blocking findings are owned by product-owner (DRIFT-P3-001, DRIFT-P3-004,
INCONSISTENCY-P3-001) or architect (DRIFT-P3-005 minor). No new exit_code regressions.
No holdout boundary violations. Delivery model coherent. Counts all reconcile.
Phase 1 gate requires a Pass 4 after the 3 Major findings are resolved.

## Appendix: Validation Methodology

This report covers Pass 3 of the Phase 1 consistency audit for the mdlinkcheck-cloud spec
package. The audit:

1. Verified all prior Pass 2 findings (HOLDOUT-001/002, MISSING-INDEX-001,
   REGRESSION-001..006, INCONSISTENCY-001..003, DRIFT-001) as FIXED / PARTIALLY FIXED.
2. Ran 13 check categories: counts reconciliation, index integrity, title source-of-truth
   (POL-7/POL-13), ID reference resolution, exit_code signature sweep, verdict vocabulary
   (D-014/DD-022), D-018 propagation, dropped-flag orphans (D-011), D-012 boundary, holdout
   boundary (POL-18), frontmatter currency, bidirectional traceability, delivery model
   coherence (D-021 supersedes D-002).
3. Applied an exhaustive BC title sweep comparing all 66 PRD section 2 table entries against
   their authoritative BC H1 headings. Entries for SS-05..14 (47 BCs) all match; entries for
   SS-01..04 (19 BCs) are in sentence case and do not match.
4. Performed intra-artifact semantic checks on BC-2.07.006 (D-012 boundary), BC-2.10.009
   (D-014 two-layer model), BC-INDEX DI-010, and VP-INDEX BC-to-VP coverage table.
5. No source code (src/) was read. Scope is limited to .factory/ spec artifacts.

Validation criteria applied per consistency-validator AGENTS.md criteria 1–20 (L1..L4 chain,
cross-artifact consistency, quality/compliance, sharding integrity) and criteria 70..77
(semantic anchoring, source-of-truth title sync, append-only ID integrity). Story-level
criteria (21+, AC completeness, story sizing) are N/A for Phase 1.
