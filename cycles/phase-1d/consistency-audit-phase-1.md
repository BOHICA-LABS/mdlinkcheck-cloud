---
document_type: consistency-audit
level: ops
version: "1.0"
status: draft
producer: vsdd-factory:consistency-validator
timestamp: 2026-08-05T22:00:00Z
phase: phase-1d
traces_to: .factory/specs/behavioral-contracts/BC-INDEX.md
---

# Consistency Audit Report — Phase 1 Spec Package

**Project:** mdlinkcheck-cloud  
**Audit ID:** phase-1d/consistency-audit-phase-1  
**Auditor:** vsdd-factory:consistency-validator  
**Date:** 2026-08-05  
**Scope:** Full Phase 1 spec package (L1–L4 chain: product-brief → domain-spec → PRD+BCs → architecture → VPs), approximately 119 files.

---

## Summary

| Check | Result | Finding count |
|-------|--------|--------------|
| BC index integrity (file count vs. BC-INDEX total_bcs) | PASS | 0 |
| VP index integrity (file count vs. VP-INDEX total_vps) | PASS | 0 |
| Architecture index integrity (ADR count) | PASS | 0 |
| BC H1 title ↔ BC-INDEX title alignment (all 59) | PASS | 0 |
| BC H1 title ↔ PRD section 2.x alignment — topic scramble | FAIL | 7 BCs (INC-001, INC-002) |
| BC H1 title ↔ PRD section 2.x alignment — wording mismatch | FAIL | 9 BCs (INC-004) |
| URL deduplication behavior BC coverage | FAIL | 0 BCs cover it (INC-003) |
| BC priority alignment — BC-INDEX vs. PRD (section 2.x + RTM) | FAIL | 17 BCs (INC-005) |
| BC-INDEX internal P0/P1 arithmetic | FAIL | ±1 off (INC-006) |
| NFR completeness — PRD §4 vs. nfr-catalog.md | FAIL | NFR-007 absent (INC-007) |
| Module criticality tier alignment — module-criticality.md vs. vcm | FAIL | 5 modules (INC-008) |
| Input-hash currency — error-taxonomy.md after BC-2.07.005 v1.1 | FAIL | factual error (DFT-001) |
| Verdict taxonomy consistency across all artifacts | FAIL | gene-transfusion "valid" (INC-010) |
| Frontmatter schema completeness | FAIL | cicd-setup.md (INC-011) |
| Input-hash currency — architecture shards after prd v1.1 | WARN | 6 shards stale (DFT-002) |
| Input-hash currency — prd-supplements after prd v1.1 | WARN | 3 supplements (DFT-003) |
| ID reference integrity (all CAP/DI/BC/VP/ADR/NFR IDs) | PASS | 0 |
| Crate version consistency across all artifacts | PASS | 0 |
| Exit-code semantic consistency | PASS | 0 |
| No UX/design-system/multi-repo artifacts | PASS | 0 |
| Domain invariant VP coverage (DI-001..011) | PASS | 11/11 |
| All 4 PRD supplements exist | PASS | 0 |
| Sharding integrity (index files, traces_to) | PASS | 0 |
| Bidirectional VP → BC traceability | PASS | 0 |

**Checks run:** 23  
**PASS:** 13  
**FAIL:** 10  
**Advisories:** 1 (checks 8/9 skipped — no Rust sources)

**Findings totals:** CRITICAL: 3 | MAJOR: 6 | MINOR: 5 | Total: 14

---

## CRITICAL Findings

---

### INC-001 (CRITICAL — INCONSISTENCY)

**Check:** BC H1 title ↔ PRD section 2.x — topic scramble in SS-10  
**Files:**
- `.factory/specs/prd.md` lines 205–208 (section 2.10 subsystem table)  
- `.factory/specs/behavioral-contracts/ss-10/BC-2.10.005.md`, `BC-2.10.006.md`, `BC-2.10.007.md`, `BC-2.10.008.md`

The PRD section 2.10 summary table assigns completely different behaviors to BC IDs 005–008 than the actual BC files contain. A story-writer reading the PRD would implement the wrong feature for each of these IDs.

| BC ID | PRD section 2.10 title (prd.md) | Authoritative BC file H1 |
|-------|--------------------------------|--------------------------|
| BC-2.10.005 | "URL deduplication: fetch once, report at every occurrence" | "DNS Resolution Failure Yields `broken` Verdict" |
| BC-2.10.006 | "Redirect following: max 10 hops, loop detection, downgrade warning" | "TLS Handshake Failure Behavior" |
| BC-2.10.007 | "Concurrency: 32 global / 4 per-host; proxy env vars honored" | "Redirect Chain Handling (Max 10 Hops)" |
| BC-2.10.008 | "Private/loopback IP ranges and TLS errors classified appropriately" | "Concurrency — 32 Global / 4 Per-Host Request Limits" |

The same stale titles repeat verbatim in the PRD section 7 RTM at lines 418–421.

Root cause: The SS-10 BCs were renumbered or reorganized after the PRD section 2.10 summary was drafted; the PRD was not updated to reflect the new BC file contents.

**Recommended fix:** Update PRD section 2.10 table rows for BC-2.10.005–008 to use their authoritative H1 title strings. Apply the same correction to the section 7 RTM. Include in PRD v1.2.  
**Owner:** product-owner

---

### INC-002 (CRITICAL — INCONSISTENCY)

**Check:** BC H1 title ↔ PRD section 2.x — topic scramble in SS-12  
**Files:**
- `.factory/specs/prd.md` lines 227–229 (section 2.12 subsystem table)  
- `.factory/specs/behavioral-contracts/ss-12/BC-2.12.002.md`, `BC-2.12.003.md`, `BC-2.12.004.md`

The PRD section 2.12 summary table assigns completely different behaviors to BC IDs 002–004 than the actual BC files contain.

| BC ID | PRD section 2.12 title (prd.md) | Authoritative BC file H1 |
|-------|--------------------------------|--------------------------|
| BC-2.12.002 | "Stdout (findings) / stderr (diagnostics + summary) separation" | "Terminal Color Output with NO_COLOR / CLICOLOR / CLICOLOR_FORCE" |
| BC-2.12.003 | "ANSI color suppression: non-TTY, `NO_COLOR`, `CLICOLOR=0`" | "Stderr Summary Line (Unless `--quiet`)" |
| BC-2.12.004 | "Summary line on stderr: `N broken link(s) in M file(s).`" | "`--format text` Explicit Alias Is Accepted" |

The same stale titles repeat in the PRD section 7 RTM at lines 426–428.

**Recommended fix:** Update PRD section 2.12 table rows for BC-2.12.002–004 to use their authoritative H1 title strings. Apply the same correction to the section 7 RTM. Include in PRD v1.2.  
**Owner:** product-owner

---

### INC-003 (CRITICAL — INCONSISTENCY)

**Check:** Behavior coverage — URL deduplication has no Behavioral Contract  
**Files:**
- `.factory/specs/prd.md` line 205 (section 2.10)  
- `.factory/specs/gene-transfusion-assessment.md` (references deduplication as an architectural pattern)  
- `.factory/specs/dtu-assessment.md` (implicit reference)  
- `.factory/specs/behavioral-contracts/` (no BC file covers this behavior)

The behavior "fetch each unique external URL exactly once; report verdict at every occurrence in output" has no dedicated Behavioral Contract. The PRD section 2.10 original draft listed it as BC-2.10.005, but that slot is now occupied by "DNS Resolution Failure Yields `broken` Verdict" (see INC-001). After INC-001 is fixed, URL deduplication will have zero BC coverage anywhere in the spec package.

Gene-transfusion-assessment.md describes URL deduplication as an architectural pattern inherited from linkinator, noting it as a user-facing performance feature. DTU assessment assumes it as part of the online-check subsystem's design. Neither document is a Behavioral Contract, so no story acceptance criterion can trace to the behavior.

**Recommended fix:** Decide between two options before PRD v1.2 is published:

Option A — Create a new BC. Add BC-2.10.009 (or the next available SS-10 slot) with title "URL Deduplication: Each Unique External URL Fetched Once, Verdict Reported at Every Occurrence" and trace it to CAP-010.

Option B — Declare it implementation-detail. Add a NOTE to BC-2.12.001 (deterministic output) and to the PRD v1.2 changelog stating that URL deduplication is an implementation optimization not requiring a dedicated BC, with rationale.

Either way, the decision must be explicit and documented. The current state (behavior described in design docs but absent from the BC registry) is a coverage gap.  
**Owner:** product-owner

---

## MAJOR Findings

---

### INC-004 (MAJOR — INCONSISTENCY)

**Check:** BC H1 title ↔ PRD section 2.x — wording mismatch in SS-09, SS-11, SS-13  
**Files:**
- `.factory/specs/prd.md` lines 192–193 (section 2.9), 216–218 (section 2.11), 237–238 (section 2.13)  
- `.factory/specs/behavioral-contracts/ss-09/BC-2.09.001.md`, `BC-2.09.002.md`  
- `.factory/specs/behavioral-contracts/ss-11/BC-2.11.001.md`, `BC-2.11.002.md`, `BC-2.11.003.md`  
- `.factory/specs/behavioral-contracts/ss-13/BC-2.13.001.md`, `BC-2.13.002.md`

Nine BCs have PRD summary table titles that differ from their authoritative H1 headings. None represent the complete topic scramble of INC-001/002, but all violate the `bc_h1_is_title_source_of_truth` policy. BC-2.13.002 is the most materially wrong: the PRD title describes an edge-case test vector ("empty result") while the H1 names the actual contract ("JSON Schema Stability Contract").

| BC ID | PRD title (prd.md line) | Authoritative BC file H1 |
|-------|------------------------|--------------------------|
| BC-2.09.001 | "WHATWG URL parse; malformed URL = broken verdict (exit 1)" (line 192) | "External URL Syntax Validation (Offline)" |
| BC-2.09.002 | "Fragment on external URL ignored; `--allow` suppresses validation" (line 193) | "`--allow` Suppresses External URL Checks" |
| BC-2.11.001 | "`--ignore` globset filter applied to sources only; anchor tables still built" (line 216) | "`--ignore` Glob Exclusion (Source Files Only)" |
| BC-2.11.002 | "`--allow` URL prefix filter with suffix-boundary safety" (line 217) | "`--allow` URL Prefix Exemption with Component-Boundary Safety" |
| BC-2.11.003 | "Flag edge cases: explicit path vs `--ignore`, repeated `--ignore`, invalid glob" (line 218) | "`--ignore` on Explicit PATH Argument" |
| BC-2.13.001 | "JSON output schema: `{schema_version: 1, results: [...]}` with all fields" (line 237) | "JSON Report Format — `{\"schema_version\":1,\"results\":[...]}` to Stdout" |
| BC-2.13.002 | "Empty result: `{schema_version: 1, results: []}`. Indeterminate findings included." (line 238) | "JSON Schema Stability Contract" |

**Recommended fix:** Update all 9 PRD section 2.x table title cells to match the exact H1 string from each BC file. Include in PRD v1.2 (combine with INC-001/002 fix).  
**Owner:** product-owner

---

### INC-005 (MAJOR — INCONSISTENCY)

**Check:** BC priority alignment — BC-INDEX vs. PRD section 2.x and section 7 RTM  
**Files:**
- `.factory/specs/behavioral-contracts/BC-INDEX.md` (updated 2026-08-05 per footer note)  
- `.factory/specs/prd.md` section 2.x tables (lines 192–238) and section 7 RTM (lines 412–433)

17 BCs have conflicting priority assignments between BC-INDEX and the PRD. PRD section 2.x tables and PRD section 7 RTM are internally consistent with each other but both disagree with BC-INDEX. BC-INDEX was updated as part of the Phase 1a v1.1 revision; the PRD section 2.x priority columns were not updated in that revision.

| BC ID | BC-INDEX priority | PRD priority (section 2.x = RTM) |
|-------|------------------|----------------------------------|
| BC-2.01.006 | P1 | P0 |
| BC-2.01.008 | P0 | P1 |
| BC-2.03.006 | P1 | P0 |
| BC-2.09.001 | P0 | P1 |
| BC-2.09.002 | P0 | P1 |
| BC-2.10.001 | P0 | P1 |
| BC-2.10.002 | P0 | P1 |
| BC-2.10.003 | P0 | P1 |
| BC-2.10.004 | P0 | P1 |
| BC-2.10.005 | P0 | P1 |
| BC-2.10.006 | P0 | P1 |
| BC-2.10.007 | P0 | P1 |
| BC-2.11.001 | P0 | P1 |
| BC-2.11.002 | P0 | P1 |
| BC-2.12.002 | P1 | P0 |
| BC-2.12.004 | P1 | P0 |
| BC-2.13.001 | P0 | P1 |

Most significant impact: BC-2.10.001–007 (all online-check BCs except 2.10.008) and BC-2.09.001–002 are P0 in BC-INDEX but P1 in PRD. Story decomposition based on PRD priorities would deprioritize the entire HTTP checking subsystem.

**Recommended fix:** Designate BC-INDEX as the authoritative priority source (it is the more recent document). Update PRD section 2.x summary tables and section 7 RTM to match BC-INDEX for all 17 BCs. Include in PRD v1.2.  
**Owner:** product-owner

---

### INC-006 (MAJOR — INCONSISTENCY)

**Check:** BC-INDEX internal P0/P1 arithmetic  
**Files:** `.factory/specs/behavioral-contracts/BC-INDEX.md` (summary statistics block vs. actual row counts)

BC-INDEX summary statistics table declares P0=45, P1=14, Total=59. Actual P0/P1 row counts across all 14 subsystem tables: P0=46, P1=13, Total=59.

| Metric | Declared in summary | Actual row count |
|--------|--------------------|--------------------|
| P0 | 45 | 46 |
| P1 | 14 | 13 |
| Total | 59 | 59 |

Root cause: BC-2.07.006 (P0) was added to BC-INDEX rows during the v1.1 cycle; the summary statistics block was not updated to reflect the addition.

**Recommended fix:** Update BC-INDEX summary statistics: `| P0 | 46 |` and `| P1 | 13 |`.  
**Owner:** product-owner

---

### INC-007 (MAJOR — INCONSISTENCY)

**Check:** NFR completeness — PRD section 4 vs. nfr-catalog.md  
**Files:**
- `.factory/specs/prd.md` lines 281–286 (section 4, Non-Functional Requirements table)  
- `.factory/specs/prd-supplements/nfr-catalog.md`

nfr-catalog.md defines 7 NFRs (NFR-001 through NFR-007). PRD section 4 summary table lists only 6 (NFR-001 through NFR-006). NFR-007 "No Undefined Reason Codes" is absent from PRD section 4.

NFR-007 details from nfr-catalog.md:
> **Category:** Correctness | **Requirement:** Every verdict in text/JSON output uses a reason code from the closed taxonomy in error-taxonomy.md | **Target:** 100% — zero unrecognized reason strings in any output

Confirmation: `.factory/specs/architecture/feasibility-review.md` v1.1 references "All 7 NFRs from nfr-catalog.md," establishing that NFR-007 is an active requirement recognized by the architect.

**Recommended fix:** Add NFR-007 row to PRD section 4 table: `| NFR-007 | No Undefined Reason Codes (Correctness) | 100% — zero unrecognized reason strings in text or JSON output | Unit/integration tests validating against the closed taxonomy in error-taxonomy.md |`. Include in PRD v1.2.  
**Owner:** product-owner

---

### INC-008 (MAJOR — INCONSISTENCY)

**Check:** Module criticality tier alignment  
**Files:**
- `.factory/specs/module-criticality.md` (lines 53–68)  
- `.factory/specs/architecture/verification-coverage-matrix.md` (lines 82–84)

Five modules have conflicting criticality tiers between the two documents, producing inconsistent cargo-mutants kill rate targets. Additionally, `main` and `types` appear in module-criticality.md as LOW tier but are entirely absent from the vcm tier table.

| Module | module-criticality.md tier | vcm tier | Kill rate delta | Recommended resolution |
|--------|---------------------------|---------|----------------|----------------------|
| `http_verdict` | CRITICAL (≥95%) | HIGH (≥90%) | 5 pp | CRITICAL: misclassifying verdicts is silent failure; VP-007 confirms | 
| `link_extractor` | HIGH (≥90%) | CRITICAL (≥95%) | 5 pp | CRITICAL: missed links = false negative; vcm's rationale is more conservative |
| `reporter` | HIGH (≥90%) | MEDIUM (≥80%) | 10 pp | HIGH: sort determinism drives VP-011 |
| `http_client` | MEDIUM (≥80%) | HIGH (≥90%) | 10 pp | MEDIUM: effectful shell; governed by http_verdict (pure) |
| `cli` | LOW (≥70%) | MEDIUM (≥80%) | 10 pp | LOW: argument parsing only; no business logic |

The two documents embed different engineering judgments. Both cannot be correct for the same kill rate budget.

**Recommended fix:** Convene an explicit architect decision to resolve each conflict. The recommended tiers in the table above are based on the rationale columns in both source documents. After resolution, regenerate both module-criticality.md and vcm with reconciled tier values and add LOW-tier rows for `main` and `types` to the vcm.  
**Owner:** architect

---

### DFT-001 (MAJOR — DRIFT)

**Check:** Input-hash currency — error-taxonomy.md factual accuracy after BC-2.07.005 v1.1  
**Files:**
- `.factory/specs/prd-supplements/error-taxonomy.md` line 46  
- `.factory/specs/behavioral-contracts/ss-07/BC-2.07.005.md` (v1.1)

error-taxonomy.md v1.0 (input-hash "7a355e9") contains a factually incorrect qualifier for the `target-is-directory` reason code.

**error-taxonomy.md line 46 (current, wrong):**
> `| \`target-is-directory\` | path | broken | 1 | Destination resolves to a directory (only when directory links are disallowed — today always broken unless \`docs/\` trailing-slash form) |`

**BC-2.07.005 v1.1 (authoritative):** A directory link with NO fragment resolves to CLEAN verdict. Only a directory link WITH a fragment present yields BROKEN with reason `target-is-directory`.

The parenthetical "today always broken unless `docs/` trailing-slash form" is false per BC-2.07.005 v1.1: bare directory links (no fragment) are now explicitly CLEAN.

error-taxonomy.md was not regenerated after BC-2.07.005 was updated as SF-002 in the v1.1 revision cycle. This is the only prd-supplement with a confirmed factual error (versus the other three, which have stale input-hashes but no known content errors).

**Recommended fix:** Update error-taxonomy.md line 46 qualifier to: "(only when a fragment is appended to a directory destination — a bare directory link without a fragment yields `clean` verdict per BC-2.07.005 v1.1)". Bump error-taxonomy.md to version 1.1 and update input-hash.  
**Owner:** product-owner

---

## MINOR Findings

---

### INC-009 (MINOR — INCONSISTENCY)

**Check:** BC-INDEX DI-007 status label vs. domain-spec and VP-INDEX  
**Files:**
- `.factory/specs/behavioral-contracts/BC-INDEX.md` (DI Coverage section)  
- `.factory/specs/domain-spec/invariants.md` (DI-007 entry)  
- `.factory/specs/verification-properties/VP-INDEX.md` line 56

BC-INDEX DI Coverage section labels DI-007 as "[reserved — no enforcement BC needed]."

However:
- domain-spec/invariants.md defines DI-007 "HTML Anchor Extraction Scope Is Narrow" as a fully specified active invariant with scope, rationale, and enforcer fields.
- VP-INDEX line 56: VP-020 actively covers DI-007 via `integration` test-sufficient method.

The label "reserved" implies the invariant ID is unused or intentionally uncovered, which misleads readers checking coverage.

**Recommended fix:** Update the BC-INDEX DI-007 entry to accurately reflect the coverage status, for example: "[DI-007 covered by VP-020 (test-sufficient integration) — no dedicated enforcement BC; behavior captured via anchor_table module contract in BC-2.05.001 scope]".  
**Owner:** product-owner

---

### INC-010 (MINOR — INCONSISTENCY)

**Check:** Verdict taxonomy consistency  
**Files:**
- `.factory/specs/gene-transfusion-assessment.md` lines 211, 286  
- `.factory/specs/dtu-assessment.md` (uses "alive" correctly)  
- `.factory/specs/behavioral-contracts/ss-10/BC-2.10.002.md` (authoritative external URL verdict)

gene-transfusion-assessment.md uses the term "valid" for the positive external URL verdict at two locations:
- Line 211: `` `valid` / `broken` / `indeterminate` ``
- Line 286: `` `valid` / `broken` / `indeterminate` ``

Authoritative verdict names, as established in BC-2.10.002 and ADR-007:
- External URLs: `alive` / `broken` / `indeterminate`
- Internal links: `clean` / `broken` / `indeterminate`

"valid" is linkinator's (the reference codebase's) terminology, carried over from the gene transfusion analysis before canonical names were established in the BC registry.

**Recommended fix:** Replace "valid" with "alive" at gene-transfusion-assessment.md lines 211 and 286. If the context is generic across both link types, use "alive (external) / clean (internal)".  
**Owner:** product-owner (low urgency; gene-transfusion-assessment is a reference artifact, not a spec input to story decomposition)

---

### INC-011 (MINOR — INCONSISTENCY)

**Check:** Frontmatter schema completeness  
**Files:** `.factory/cicd-setup.md`

cicd-setup.md is missing 5 of the 9 required VSDD frontmatter fields.

| Field | Status |
|-------|--------|
| `document_type` | present |
| `producer` | present |
| `timestamp` | present |
| `status` | present |
| `level` | MISSING |
| `version` | MISSING |
| `inputs` | MISSING |
| `input-hash` | MISSING |
| `traces_to` | MISSING |

**Recommended fix:** Add the missing fields to cicd-setup.md frontmatter:
```yaml
level: ops
version: "1.0"
inputs:
  - .factory/STATE.md
input-hash: "<hash-of-STATE.md>"
traces_to: .factory/STATE.md
```
**Owner:** devops-engineer

---

### DFT-002 (MINOR — DRIFT)

**Check:** Input-hash currency — architecture shards after prd v1.1  
**Files:**
- `.factory/specs/architecture/ARCH-INDEX.md` (v1.0, input-hash "a84515b")  
- `.factory/specs/architecture/module-decomposition.md` (v1.0, input-hash "0a8b291")  
- `.factory/specs/architecture/system-overview.md` (v1.0, no input-hash tracked)  
- `.factory/specs/architecture/verification-architecture.md` (v1.0, input-hash "b418ba6")  
- `.factory/specs/architecture/verification-coverage-matrix.md` (v1.0, input-hash "5e1a5b6")  
- `.factory/specs/architecture/tooling-selection.md` (v1.0, input-hash "507e917")

All six architecture shards list prd.md among their inputs and are at version 1.0 with input-hashes computed before prd v1.1 was published. prd v1.1 added BC-2.07.006 and updated BC-2.07.005, BC-2.02.002, BC-2.04.003, and BC-2.06.001. The input-hashes no longer reflect the current prd.md content.

Impact assessment: The v1.1 BC changes are targeted corrections (title/verdict-rule updates). BC-2.07.006 ("non-Markdown target — file existence check only, anchor resolution skipped") does not require new modules — it is handled by routing in the existing `anchor_resolver` / `path_resolver` modules. No new VP was added for BC-2.07.006. The functional impact on architecture is low, but the hash tracking is technically stale.

**Recommended fix:** After PRD v1.2 stabilizes, review all six architecture shards for content impact from v1.1 BC changes. If no content changes are needed, update input-hashes and bump versions to 1.1. If module-decomposition needs adjustment for BC-2.07.006 routing (unlikely but check), produce that update as well.  
**Owner:** architect (after PRD v1.2 stabilizes)

---

### DFT-003 (MINOR — DRIFT)

**Check:** Input-hash currency — prd-supplements after prd v1.1  
**Files:**
- `.factory/specs/prd-supplements/interface-definitions.md` (v1.0, input-hash "7a355e9")  
- `.factory/specs/prd-supplements/nfr-catalog.md` (v1.0, input-hash "7a355e9")  
- `.factory/specs/prd-supplements/test-vectors.md` (v1.0, input-hash "7a355e9")

(error-taxonomy.md has a confirmed content error and is filed separately as DFT-001 at MAJOR severity.)

These three supplements list prd.md in their `traces_to` field but their input-hash "7a355e9" was computed before prd v1.1. No confirmed content errors in these three supplements arising from the v1.1 changes have been found during this audit. However, they have not been reviewed for implicit references to the changed BC-2.07.005 directory verdict semantics.

**Recommended fix:** Review interface-definitions.md, nfr-catalog.md, and test-vectors.md for any content that depends on BC-2.07.005 directory verdict behavior (CLEAN for no-fragment, BROKEN for fragment-present). If no content changes are needed, update input-hashes only.  
**Owner:** product-owner (low urgency, combine with DFT-001 pass)

---

## Advisory Checks

**Check 8 — Test Tautology Detector:** Skipped — no Rust source files detected. Project is in Phase 1 spec stage; Phase 3 (TDD implementation) has not started.

**Check 9 — BC Canonical TV vs. Emitter Field Consistency:** Skipped — no Rust source files detected.

---

## Confirmed PASS (all checks that passed)

1. **BC file count:** 59 files on disk = 59 in BC-INDEX `total_bcs`. Zero orphaned or missing BC files.
2. **VP file count:** 20 files on disk = 20 in VP-INDEX `total_vps`. Zero orphaned or missing VP files.
3. **ADR file count:** 7 files on disk = 7 in ARCH-INDEX ADR catalog.
4. **VP-INDEX arithmetic:** kani(7) + proptest(5) + fuzz(2) + integration(5) + unit(1) = 20. Consistent.
5. **VP-INDEX per-module totals row:** Column sums to 20; matches VP-INDEX `total_vps`.
6. **BC H1 ↔ BC-INDEX title alignment (all 59):** Bulk extraction of all BC H1 headings and all BC-INDEX title cells confirmed zero title drift. Every BC file's H1 matches its BC-INDEX row exactly.
7. **BC H1 titles for v1.1 BCs:** BC-2.02.002 v1.1 H1 = "UTF-8 BOM Stripping and CRLF Normalization (Shell-Side)" ✓; BC-2.04.003 v1.1 ✓; BC-2.06.001 v1.1 ✓; BC-2.07.005 v1.1 H1 = "Destination-Is-Directory Verdict" ✓; BC-2.07.006 v1.0 (new) H1 = "Non-Markdown Target — File Existence Check Only, Anchor Resolution Skipped" ✓.
8. **Crate version consistency:** pulldown-cmark 0.13.4, ureq 3.3.0, httpmock 0.8.3, rayon 1.12.0, ignore 0.4.33, clap 4.6.5, globset 0.4.20, url 2.5.8, percent-encoding 2.3.2 consistent across dependency-graph.md, tooling-selection.md, feasibility-review.md, and dtu-assessment.md.
9. **Exit-code semantics:** exit 0 = no broken links; exit 1 = at least one broken; exit 2 = I/O error (overrides exit 1). Consistent across PRD, error-taxonomy.md, BC-2.14.001–003, dtu-assessment.md.
10. **Verdict taxonomy (authoritative documents):** `alive`/`broken`/`indeterminate` for external URLs and `clean`/`broken`/`indeterminate` for internal links are consistent across BC-2.10.002, ADR-007, dtu-assessment.md, and error-taxonomy.md (exception: gene-transfusion-assessment uses "valid" — filed as INC-010).
11. **VP → BC traceability (all 20 VPs):** Every VP `source_bc` field references a BC ID that exists in the BC file registry. Zero broken VP→BC links.
12. **Domain invariant VP coverage:** All 11 domain invariants DI-001..011 have at least one VP. VP-INDEX DI Coverage table shows 11/11 (100%).
13. **All 4 PRD supplements exist:** interface-definitions.md, error-taxonomy.md, test-vectors.md, nfr-catalog.md all present at `.factory/specs/prd-supplements/`.
14. **Sharding integrity:** L2-INDEX.md lists all 11 domain-spec section files; section files have `traces_to: L2-INDEX.md`; BC-INDEX, VP-INDEX, ARCH-INDEX all exist and are internally consistent (file lists match disk). No orphaned detail files.
15. **No UX/design-system/multi-repo artifacts:** No references to ux-spec/, design-system/, or cross-repo paths found anywhere in the perimeter.
16. **BC-2.07.005 v1.1 directory verdict:** Confirmed correct. No-fragment directory link → CLEAN. Fragment-present directory link → BROKEN with reason `target-is-directory`. This is the authoritative behavior.
17. **BC-2.07.006 registration:** Correctly registered in BC-INDEX at P0, in PRD section 7 RTM (added in v1.1 revision), and in the v1.1 changelog.
18. **dependency-graph.md at v1.1:** Updated for url crate 2.5.8 pin (NOTE-2 resolution). Consistent with architecture.
19. **No duplicate BC IDs:** All 59 BC files have unique identifiers.
20. **ID reference integrity:** All CAP-NNN, DI-NNN, ADR-NNN, and NFR-NNN IDs referenced across the spec package resolve to real entries in their authoritative registries. DI-007 is a live invariant in domain-spec/invariants.md (its "reserved" label in BC-INDEX is misleading but not a broken reference — filed as INC-009).

---

## CONSISTENCY_AUDIT: FAIL

**Gate status:** FAIL — 3 CRITICAL blocking findings must be resolved before Phase 1 gate passes.

**Finding counts:**
- CRITICAL (INCONSISTENCY): 3 — INC-001, INC-002, INC-003
- MAJOR (INCONSISTENCY): 5 — INC-004, INC-005, INC-006, INC-007, INC-008
- MAJOR (DRIFT): 1 — DFT-001
- MINOR (INCONSISTENCY): 3 — INC-009, INC-010, INC-011
- MINOR (DRIFT): 2 — DFT-002, DFT-003
- **Total findings:** 14

---

## Artifacts Requiring Regeneration

Artifacts that contain stale or incorrect content derived from superseded inputs, listed in priority order:

| Priority | Artifact | Finding(s) | Required action |
|----------|----------|-----------|----------------|
| CRITICAL | `.factory/specs/prd.md` | INC-001, INC-002, INC-003, INC-004, INC-005, INC-007 | PRD v1.2: fix 14 BC title mismatches (§2.10, §2.12, §2.9, §2.11, §2.13), update 17 priorities to match BC-INDEX, add NFR-007 to §4, resolve URL deduplication coverage gap |
| MAJOR | `.factory/specs/prd-supplements/error-taxonomy.md` | DFT-001 | Patch `target-is-directory` qualifier; bump to v1.1 |
| MAJOR | `.factory/specs/behavioral-contracts/BC-INDEX.md` | INC-006 | Correct summary stats to P0=46/P1=13 |
| MAJOR | `.factory/specs/module-criticality.md` | INC-008 | Resolve 5-module tier conflict with vcm; add `main` and `types` |
| MAJOR | `.factory/specs/architecture/verification-coverage-matrix.md` | INC-008 | Reconcile tier table to match module-criticality.md decisions |
| MINOR | `.factory/specs/gene-transfusion-assessment.md` | INC-010 | Replace "valid" → "alive" at lines 211 and 286 |
| MINOR | `.factory/cicd-setup.md` | INC-011 | Add 5 missing VSDD frontmatter fields |
| MINOR | `.factory/specs/architecture/ARCH-INDEX.md` | DFT-002 | Update input-hash after PRD v1.2 stabilizes |
| MINOR | `.factory/specs/architecture/module-decomposition.md` | DFT-002 | Review + update input-hash |
| MINOR | `.factory/specs/architecture/system-overview.md` | DFT-002 | Review + begin tracking input-hash |
| MINOR | `.factory/specs/architecture/verification-architecture.md` | DFT-002 | Review + update input-hash |
| MINOR | `.factory/specs/architecture/tooling-selection.md` | DFT-002 | Update input-hash |
| MINOR | `.factory/specs/prd-supplements/interface-definitions.md` | DFT-003 | Review for BC-2.07.005/006 impact; update input-hash |
| MINOR | `.factory/specs/prd-supplements/nfr-catalog.md` | DFT-003 | Review for impact; update input-hash |
| MINOR | `.factory/specs/prd-supplements/test-vectors.md` | DFT-003 | Review for impact; update input-hash |

---

*Audit conducted 2026-08-05. Perimeter: 119 files across L1–L4 spec chain.*  
*Auditor: vsdd-factory:consistency-validator (claude-sonnet-4-6).*
