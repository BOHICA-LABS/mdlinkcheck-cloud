---
document_type: consistency-audit
level: ops
version: "1.0"
status: draft
producer: vsdd-factory:consistency-validator
timestamp: 2026-08-05T23:30:00Z
phase: phase-1d
traces_to: .factory/specs/behavioral-contracts/BC-INDEX.md
---

# Consistency Audit Report — Phase 1 Spec Package (Pass 2)

**Project:** mdlinkcheck-cloud  
**Audit ID:** phase-1d/consistency-audit-phase-1-pass-2  
**Auditor:** vsdd-factory:consistency-validator  
**Date:** 2026-08-05  
**Scope:** Full Phase 1 spec package after multi-agent Phase 1d remediation. Verifies all 14 prior
findings from `consistency-audit-phase-1.md`; hunts for regressions introduced by concurrent remediation.
Approximately 130 files examined (66 BC files, 24 VP files, 7 ADR files, 11 domain-spec shards, 4 PRD
supplements, 9 architecture shards, 3 holdout scenarios, plus supporting artifacts).

---

## Summary

| Check Area | Result | New finding count |
|------------|--------|------------------|
| 1. BC/VP/Architecture index integrity | PASS | 0 |
| 2. Title source-of-truth (BC H1 ↔ BC-INDEX ↔ PRD) | FAIL | 1 (REGRESSION-001) |
| 3. ID reference resolution (DD/ADR cross-refs) | FAIL | 1 (REGRESSION-006) |
| 4. Bidirectional VP → BC traceability | PASS | 0 |
| 5. Frontmatter + sharding integrity | FAIL | 1 (MISSING-INDEX-001) |
| 6. Version and artifact coherence (supplements) | FAIL | 1 (REGRESSION-005) |
| 7. Cross-artifact factual agreement (verdict taxonomy) | FAIL | 3 (INCONSISTENCY-001, -002, -003) |
| 8. Dropped-flag orphan scan (D-011/D-012) | FAIL | 2 (REGRESSION-002, REGRESSION-003) |
| 9. Holdout boundary enforcement (POL-18) | FAIL | 2 (HOLDOUT-001, HOLDOUT-002) |
| 10. Policy self-consistency (policies.yaml) | PASS | 0 |
| Module-criticality VP count currency | FAIL | 1 (REGRESSION-004) |

**New findings totals:**
- CRITICAL: 3 — HOLDOUT-001, HOLDOUT-002, MISSING-INDEX-001  
- MAJOR: 7 — REGRESSION-001, REGRESSION-002, REGRESSION-004, REGRESSION-005, INCONSISTENCY-001, INCONSISTENCY-002, INCONSISTENCY-003  
- MINOR: 3 — REGRESSION-003, REGRESSION-006, DRIFT-001  
- **Total new findings: 13**

**Remediation verdict on prior 14 findings:** 11 FIXED, 2 PARTIAL, 1 REGRESSED.  
(See Prior-Finding Verdict Table at end of document.)

---

## CRITICAL Findings

---

### HOLDOUT-001 (CRITICAL — HOLDOUT BOUNDARY VIOLATION)

**Policy:** POL-18 `holdout_boundary_enforcement`  
**Classification:** REGRESSION — the holdout scenario text in `edge-cases.md` predates Phase 1d but
was never cleaned up during two successive remediation passes.

**Files that disagree:**
- `.factory/specs/domain-spec/edge-cases.md` lines 38–45 (Section DEC-001)  
- `.factory/specs/prd.md` §5b (EC-049 is in the holdout-reserved list)

**Exact conflicting content:**

`edge-cases.md` DEC-001 (lines 38–45) fully specifies the concrete EC-049 holdout scenario:

```
Heading collision: headings `Foo`, `Foo`, `Foo-1` in the same file produce slugs
`foo`, `foo-1`, `foo-1-1`. Links `[a](#foo)`, `[b](#foo-1)`, `[c](#foo-1-1)` all
resolve `clean`.
```

`prd.md` §5b holdout list:

```
Holdout vectors (EC-036, EC-049, EC-074, EC-079, EC-093, EC-094, EC-141, EC-147,
EC-148, EC-151, EC-156, EC-157, EC-158) reserved for holdout evaluation and NOT in
the visible test suite.
```

EC-049 is explicitly reserved for holdout evaluation. DEC-001 provides the full
scenario specification — the exact input headings, the exact slugs produced, and the
expected `clean` verdict for all three links. Any implementer who reads
`edge-cases.md` will know the exact test case before it is administered.

**Recommended fix:** Remove DEC-001 from `edge-cases.md` entirely. If the
heading-collision duplicate-counter algorithm needs to be specified for implementers,
describe the algorithm in abstract terms (the counter increments for each duplicate
slug) without specifying the exact EC-049 input/output. The algorithm is already
fully specified in BC-2.06.001 and BC-2.06.002.  
**Owner:** spec-steward  
**Blocking:** Yes — POL-18 violation prevents Phase 1 gate approval.

---

### HOLDOUT-002 (CRITICAL — HOLDOUT BOUNDARY VIOLATION)

**Policy:** POL-18 `holdout_boundary_enforcement`  
**Classification:** REGRESSION — PRD v1.5 Fix 1 removed EC-074 references from BC files but did
not extend the cleanup to `domain-spec/edge-cases.md`.

**Files that disagree:**
- `.factory/specs/domain-spec/edge-cases.md` lines 62–70 (Section DEC-003)  
- `.factory/specs/prd.md` §5b (EC-074 is in the holdout-reserved list)

**Exact conflicting content:**

`edge-cases.md` DEC-003 (lines 62–70) fully specifies the concrete EC-074 holdout scenario:

```
`--ignore` does not prevent link resolution into ignored file: link
`[x](vendor.md#section)` in `README.md`, where `vendor.md` is matched by `--ignore`,
and `## Section` exists in `vendor.md` → must resolve `clean`.
```

`prd.md` §5b holdout list includes EC-074 as reserved.

EC-074 is explicitly reserved for holdout evaluation. DEC-003 provides the full
scenario — the source file name (`README.md`), the exact link target (`vendor.md#section`),
the `--ignore` match, the heading name (`## Section`), and the expected verdict
(`clean`). An implementer reading `edge-cases.md` will know the exact test case.

PRD v1.5 Fix 1 changelog states: "Removed EC-074 full scenario text from BC-2.08.004
and BC-2.11.001 (holdout boundary enforcement)." The same removal was not applied
to `domain-spec/edge-cases.md`.

**Recommended fix:** Remove DEC-003 from `edge-cases.md`. The general rule that
`--ignore` is source-only (ignored files remain valid anchor targets) is already
specified in DI-006 and BC-2.11.001 at the conceptual level without EC-074's concrete
scenario.  
**Owner:** spec-steward  
**Blocking:** Yes — POL-18 violation prevents Phase 1 gate approval.

---

### MISSING-INDEX-001 (CRITICAL — SHARDING INTEGRITY, Criterion 21)

**Classification:** REGRESSION (introduced during Phase 1d when holdout scenario files were added
without creating the required index).

**Files:**
- `.factory/holdout-scenarios/wave-scenarios/EC-156-gitignore-cross-file-anchor.md`
- `.factory/holdout-scenarios/wave-scenarios/EC-157-percent-encoded-fragment-cross-file.md`
- `.factory/holdout-scenarios/wave-scenarios/EC-158-emoji-heading-collision.md`
- `.factory/holdout-scenarios/wave-scenarios/HS-INDEX.md` — **MISSING**

Criterion 21 requires that every sharded directory with detail files must have an INDEX file. The
`wave-scenarios/` directory contains 3 holdout scenario detail files but no `HS-INDEX.md`. All
three scenario files set `traces_to: .factory/specs/prd.md`, bypassing the index layer entirely.

The HS-INDEX serves two purposes: (1) it is the authoritative catalog of active vs.
retired holdout scenarios for the holdout evaluator; (2) it allows the sharding integrity
criterion to verify no scenario file has been accidentally committed twice or with a
conflicting ID. Without it, management of the holdout set is opaque.

**Recommended fix:** Create `.factory/holdout-scenarios/wave-scenarios/HS-INDEX.md` with
canonical frontmatter and a catalog table listing HS-001 (EC-156), HS-002 (EC-157), HS-003
(EC-158) with `lifecycle_status: active` for each. Update each scenario file's `traces_to`
field to reference `HS-INDEX.md`.  
**Owner:** spec-steward  
**Blocking:** Yes — criterion 21 CRITICAL violation.

---

## MAJOR Findings

---

### REGRESSION-001 (MAJOR — INCONSISTENCY)

**Check:** BC H1 title ↔ BC-INDEX title alignment — BC-2.05.001  
**Classification:** REGRESSION — BC-2.05.001 was rewritten to v1.3 ("Three-Phase Design") during
Phase 1d but BC-INDEX was not updated.

**Files that disagree:**
- `.factory/specs/behavioral-contracts/BC-INDEX.md` line 82  
- `.factory/specs/behavioral-contracts/ss-05/BC-2.05.001.md` H1 (line 32)

**Exact conflicting values:**

BC-INDEX.md line 82:
```
| BC-2.05.001 | Two-Pass Design — Full Anchor Table Before Any Resolution | P0 | ...
```

BC-2.05.001.md H1 (authoritative per POL-7):
```
# BC-2.05.001: Three-Phase Design — Full Anchor Table Before Any Resolution
```

PRD.md §2.5 correctly says "Three-Phase Design" (it was updated during Phase 1d). BC-INDEX was not.

Secondary drift: BC-INDEX DI table line 213 (DI-008) still reads "Two-pass: anchor table complete
before any link resolution." DI-008's own label was never updated for the Pass 1.5 addition.
BC-INDEX line 214 (DI-009) correctly uses "Pass 1.5 termination," creating an internal
inconsistency within BC-INDEX itself.

A story-writer reading BC-INDEX to understand subsystem 5 will see the old "Two-Pass" framing
while the canonical BC defines three phases.

**Recommended fix:** Update BC-INDEX.md line 82 title cell from "Two-Pass Design" to "Three-Phase
Design — Full Anchor Table Before Any Resolution". Also update DI-008's description label in the
BC-INDEX DI Coverage table from "Two-pass:" to "Three-phase (Pass 1 → Pass 1.5 → Pass 2):". Bump
BC-INDEX to v1.6.  
**Owner:** product-owner

---

### REGRESSION-002 (MAJOR — INCONSISTENCY)

**Check:** Dropped-flag orphan scan — D-012 (`.markdown` extension non-goal) and D-011 (`--hidden` non-goal)  
**Classification:** REGRESSION — BC-2.01.001 was never updated for D-011/D-012 while BC-2.01.004 and
capabilities.md were updated.

**Files that disagree:**
- `.factory/specs/behavioral-contracts/ss-01/BC-2.01.001.md` (v1.0, `modified: []`)  
- `.factory/specs/domain-spec/decisions.md` D-011 and D-012  
- `.factory/specs/behavioral-contracts/ss-01/BC-2.01.004.md` (v1.3, correctly updated)

**Exact conflicting values:**

BC-2.01.001 line 34 (Description):
```
discovers all `.md` and `.markdown` files (case-insensitive extension match)
```

D-012 (binding decision):
```
`.md` files only, case-sensitive; `.MD`, `.markdown`, `.mdx` are explicit non-goals
```

BC-2.01.001 line 50 (Invariant 2):
```
Dot-directories other than `.git/` are skipped unless `--hidden` is passed. (BC-2.01.004)
```

D-011 (binding decision):
```
`--quiet`, `--offline`, `--insecure`, `--hidden` are explicit non-goals for v1.0
```

BC-2.01.004 v1.3 (correctly updated, for comparison):
```
There is no `--hidden` flag. Dot-directory skip is unconditional.
```

The same D-012 violation appears in additional BCs also not updated during Phase 1d:
- `BC-2.01.002.md` line 43: "all `.md`/`.markdown` files under it are included"
- `BC-2.02.001.md` line 41: "A `.md` or `.markdown` file has been read"
- `BC-2.01.008.md` line 34: "no `.md` or `.markdown` files were found"

An implementer following BC-2.01.001 verbatim would implement `.markdown` file discovery and
a `--hidden` flag — both explicitly ruled out by binding human decisions.

**Recommended fix:** Update BC-2.01.001 (bump to v1.1): (a) line 34 — replace "all `.md` and
`.markdown` files (case-insensitive extension match)" with "all `.md` files (case-sensitive,
`.markdown`/`.MD`/`.mdx` excluded per D-012)"; (b) line 41 — remove "`.markdown`" from
precondition 3; (c) line 44 — remove "`.markdown`" from postcondition 1; (d) line 50 —
replace "unless `--hidden` is passed. (BC-2.01.004)" with "(unconditional — there is no
`--hidden` flag, D-011)". Apply the same `.markdown` removal to BC-2.01.002 line 43, BC-2.01.008
line 34, and BC-2.02.001 line 41.  
**Owner:** product-owner

---

### REGRESSION-004 (MAJOR — DRIFT)

**Check:** module-criticality.md VP count currency after VP-023 and VP-024 additions  
**Classification:** REGRESSION — VP-023 and VP-024 were added to VP-INDEX, verification-architecture.md,
and verification-coverage-matrix.md during Phase 1d, but module-criticality.md VP counts were not updated.

**Files that disagree:**
- `.factory/specs/module-criticality.md` lines 69 and 73  
- `.factory/specs/verification-properties/VP-INDEX.md` (VP-023, VP-024 present)  
- `.factory/specs/architecture/verification-coverage-matrix.md` (VP-023, VP-024 present)

**Exact conflicting values:**

`module-criticality.md` line 73 (url_classifier row):
```
| `url_classifier` | HIGH | ... | no VP (integration-tested) | >= 90% | **0** |
```

VP-INDEX (authoritative): VP-023 is `url_classifier | proptest | P1 | BC-2.07.007`. VP count = **1**.

`module-criticality.md` line 69 (path_resolver row):
```
| `path_resolver` | CRITICAL | ... | VP-008, VP-009 | >= 95% | **2** |
```

VP-INDEX (authoritative): VP-024 is `path_resolver | proptest | P1 | BC-2.07.008`. VP count = **3**
(VP-008, VP-009, VP-024).

verification-coverage-matrix.md v1.3 correctly shows path_resolver total = 3 and url_classifier
total = 1.

A maintainer reading module-criticality.md to understand formal coverage would see stale zero-VP
count for url_classifier and a count of 2 for path_resolver, both inconsistent with the other
architecture documents.

**Recommended fix:** Update module-criticality.md (bump to v1.3): (a) url_classifier VP ref column:
"VP-023 (proptest P1)" and VP count = 1; (b) path_resolver VP ref column: "VP-008, VP-009, VP-024"
and VP count = 3.  
**Owner:** architect

---

### REGRESSION-005 (MAJOR — INCONSISTENCY)

**Check:** Version coherence — TLS error verdict in interface-definitions.md  
**Classification:** REGRESSION — interface-definitions.md was regenerated during Phase 1d but its
§2.3 note carried a stale `indeterminate` claim for TLS failures.

**Files that disagree:**
- `.factory/specs/prd-supplements/interface-definitions.md` line 64 (v1.4)  
- `.factory/specs/prd-supplements/error-taxonomy.md` §2.3 (v1.4)  
- `.factory/specs/architecture/decisions/ADR-007-three-verdict-model.md` (v1.1)

**Exact conflicting values:**

`interface-definitions.md` line 64:
```
TLS failures produce `indeterminate` verdict (BC-2.10.002)
```

`error-taxonomy.md` §2.3 (authoritative closed taxonomy):
```
| `tls-error` | external | broken | 1 | TLS handshake fails (expired cert, invalid cert, self-signed) |
```

`ADR-007` v1.1 changelog:
```
moved dns-failure and tls-error from indeterminate to broken; updated terminology
(alive not valid; 13 codes not 9)
```

`BC-2.10.006` (authoritative BC for TLS behavior):
```
Postcondition: verdict = `broken`, reason = `tls-error`, exit code = 1
```

The `indeterminate` claim in interface-definitions.md directly contradicts the canonical closed
taxonomy, ADR-007, and BC-2.10.006. An implementer reading the interface document would wire TLS
failures to `indeterminate` (no exit 1), breaking the closed error taxonomy invariant and causing
TLS failures to silently not trigger build failures.

**Recommended fix:** Update interface-definitions.md §2.3 line 64 from "TLS failures produce
`indeterminate` verdict (BC-2.10.002)" to "TLS failures produce `broken` verdict with reason code
`tls-error` (BC-2.10.006, ADR-007)". Also audit the surrounding §2.3 text for any reference to
DNS failures — `dns-failure` is likewise `broken` not `indeterminate`. Bump interface-definitions.md
to v1.5.  
**Owner:** product-owner

---

### INCONSISTENCY-001 (MAJOR — INCONSISTENCY)

**Check:** Verdict taxonomy — "clean" used for external URL positive results in SS-10 BC test vectors  
**Classification:** INCONSISTENCY (pre-existing + unresolved by Phase 1d remediation)

**Files that disagree:**
- `.factory/specs/behavioral-contracts/ss-10/BC-2.10.001.md` test vectors  
- `.factory/specs/behavioral-contracts/ss-10/BC-2.10.003.md` test vectors  
- `.factory/specs/behavioral-contracts/ss-10/BC-2.10.007.md` test vectors  
- `.factory/specs/prd-supplements/error-taxonomy.md` §1

**Exact conflicting values:**

`error-taxonomy.md` §1 (authoritative, unambiguous):
```
The positive external URL verdict is `alive` (never `valid`). The positive internal
link verdict is `clean`. `clean` is NOT used for external URL verdicts.
```

BC-2.10.001 test vectors (representative sample):
```
| HEAD 200 | clean |
```

BC-2.10.003 test vectors:
```
| Server responds in 5s with 200 | clean |
```

BC-2.10.007 test vectors:
```
| 5-hop redirect chain → 200 | clean |
```

All three BCs cover external URL checking behaviors (HTTP responses). The positive result for
an HTTP 200 response is `alive`, not `clean`. Using `clean` in external URL test vectors would
cause a test-writer following these BCs to assert the wrong verdict, producing tests that would
fail against a correct implementation.

**Recommended fix:** Search all SS-10 test vector tables for `| clean |` and `| clean\n`. Replace
every occurrence that corresponds to an external URL success verdict with `| alive |`. Affected files:
BC-2.10.001, BC-2.10.003, BC-2.10.007 (and any other SS-10 BCs using "clean" for HTTP 200
outcomes). BC-2.10.002 is filed separately as INCONSISTENCY-002.  
**Owner:** product-owner

---

### INCONSISTENCY-002 (MAJOR — INCONSISTENCY)

**Check:** Verdict taxonomy — "alive (clean)" conflation in BC-2.10.002  
**Classification:** INCONSISTENCY (pre-existing + unresolved by Phase 1d remediation)

**Files that disagree:**
- `.factory/specs/behavioral-contracts/ss-10/BC-2.10.002.md` lines 36, 53, 115–116  
- `.factory/specs/prd-supplements/error-taxonomy.md` §1

**Exact conflicting values:**

BC-2.10.002 line 36:
```
alive (clean)
```

BC-2.10.002 line 53:
```
verdict `alive` → clean
```

BC-2.10.002 lines 115–116 (test vectors):
```
alive/clean
```

`error-taxonomy.md` §1:
```
`clean` is NOT used for external URL verdicts.
```

BC-2.10.002 is the authoritative BC for HTTP 200 → `alive` behavior. Using "alive (clean)" or
"alive → clean" in this file directly contradicts the strict two-verdict model and suggests the
two positive verdicts are aliases. They are not: `alive` is the external URL positive verdict;
`clean` is the internal link positive verdict. No external URL check should ever produce `clean`.

**Recommended fix:** Update BC-2.10.002: (a) line 36 — replace "alive (clean)" with "alive"; (b)
line 53 — replace "verdict `alive` → clean" with "verdict `alive`"; (c) lines 115–116 — replace
"alive/clean" with "alive". Bump to v1.5.  
**Owner:** product-owner

---

### INCONSISTENCY-003 (MAJOR — INCONSISTENCY)

**Check:** ARCH-INDEX Document Map completeness — feasibility-review.md not listed  
**Classification:** REGRESSION (feasibility-review.md was present in the architecture/ directory before
Phase 1d but was not added to ARCH-INDEX when ARCH-INDEX was updated in Phase 1d).

**Files that disagree:**
- `.factory/specs/architecture/ARCH-INDEX.md` Document Map (v1.0, lists 8 section files)  
- `.factory/specs/architecture/feasibility-review.md` (`traces_to: .factory/specs/architecture/ARCH-INDEX.md`)

**Exact conflicting values:**

ARCH-INDEX.md Document Map:
```
8 section files listed:
  system-overview.md, module-decomposition.md, dependency-graph.md,
  tooling-selection.md, verification-architecture.md, verification-coverage-matrix.md,
  decisions/ADR-001…007
```

`feasibility-review.md` frontmatter:
```
traces_to: .factory/specs/architecture/ARCH-INDEX.md
```

`find .factory/specs/architecture -name "*.md" -not -path "*/decisions/*" -not -name "ARCH-INDEX.md"`
returns 7 section files; feasibility-review.md is the 8th and is not listed in the Document Map.

Criterion 23 (Index files reference all existing detail files): orphaned detail files must not
exist. feasibility-review.md claims to be a shard of ARCH-INDEX.md via `traces_to`, but ARCH-INDEX
does not list it. This means a reader following ARCH-INDEX cannot reach feasibility-review.md.

**Recommended fix:** Add `feasibility-review.md` to the ARCH-INDEX.md Document Map section files
list. Bump ARCH-INDEX to v1.1.  
**Owner:** architect

---

## MINOR Findings

---

### REGRESSION-003 (MINOR — INCONSISTENCY)

**Check:** Dropped-flag orphan scan — BC-2.01.008 Invariant 2 references `--quiet`  
**Classification:** REGRESSION — BC-2.01.008 references the dropped `--quiet` flag (D-011 non-goal).

**Files that disagree:**
- `.factory/specs/behavioral-contracts/ss-01/BC-2.01.008.md` Invariant 2  
- `.factory/specs/domain-spec/decisions.md` D-011

**Exact conflicting values:**

BC-2.01.008 Invariant 2:
```
The stderr message is emitted even if `--quiet` is not set (it is informational, not a warning).
```

D-011 (binding decision):
```
`--quiet`, `--offline`, `--insecure`, `--hidden` are explicit non-goals for v1.0
```

The conditional "even if `--quiet` is not set" implies a world where `--quiet` could be set.
Per D-011, `--quiet` does not exist. The invariant is misleading rather than incorrect (the
behavior described — always emit the message — is correct), but the conditional phrasing will
confuse any reader familiar with D-011.

**Recommended fix:** Update BC-2.01.008 Invariant 2 to: "The stderr message is always emitted;
there is no `--quiet` flag (D-011). The message is informational, not a warning." Bump to v1.1.  
**Owner:** product-owner

---

### REGRESSION-006 (MINOR — INCONSISTENCY)

**Check:** ID reference integrity — ADR-007 cites DD-015 for GET fallback behavior  
**Classification:** REGRESSION (introduced when ADR-007 was updated to v1.1 during Phase 1d).

**Files that disagree:**
- `.factory/specs/architecture/decisions/ADR-007-three-verdict-model.md` lines 102, 132, 153  
- `.factory/specs/domain-spec/decisions.md` (DD-015 vs. DD-016 definitions)

**Exact conflicting values:**

ADR-007 lines 102, 132, 153 (three occurrences):
```
(DD-015 — HEAD→GET fallback trigger set)
```

`decisions.md` DD-015:
```
DD-015: GitHub slug algorithm authority — the GitHub Markdown renderer's slug
algorithm is authoritative for anchor ID generation.
```

`decisions.md` DD-016:
```
DD-016: HEAD→GET fallback trigger set — 405 Method Not Allowed, connection timeout
on HEAD, and certain 4xx responses trigger a GET fallback.
```

DD-015 is about the GitHub slug algorithm; it has nothing to do with HTTP fallback behavior.
DD-016 is the correct reference for HEAD→GET fallback behavior. ADR-007 cites DD-015 three times
in contexts that describe the GET fallback trigger set.

**Recommended fix:** In ADR-007 lines 102, 132, and 153, replace every occurrence of "(DD-015 —
HEAD→GET fallback trigger set)" with "(DD-016 — HEAD→GET fallback trigger set)". Bump to v1.2.  
**Owner:** architect

---

### DRIFT-001 (MINOR — INFORMATIONAL)

**Check:** Input-hash currency — domain-spec section files after Phase 1d edits  
**Classification:** DRIFT (intentional — BA confirmed inputs are unchanged)

**Files:**
- All `domain-spec/*.md` section files still carry `input-hash: "20e96e1"` (computed at
  initial draft from product-brief.md, brief-validation.md, market-intelligence.md)

Phase 1d made corrections to capabilities.md (CAP-001 grounding, CAP-010 verdict classification,
CAP-011 --allow behavior), edge-cases.md (DEC-003 cleanup attempt, though incomplete), and
invariants.md (DI-006 widening). These were spec corrections, not new input changes. The business
analyst confirmed the upstream inputs (product-brief.md, brief-validation.md, market-intelligence.md)
are unchanged, so the hash remains valid.

This finding is informational only. The hash tracks the BA's upstream inputs, not the BA's own
edits. The current state is correct. No action required.

**Owner:** N/A (no action required)

---

## Confirmed Pass

The following checks passed in this audit with no new findings:

1. **BC file count:** 66 files on disk = 66 in BC-INDEX `total_bcs`. Count correct (find returns
   67, but one hit is BC-INDEX.md itself matching the `BC-*.md` glob).
2. **VP file count:** 24 files on disk = 24 in VP-INDEX `total_vps`. VP-023 and VP-024 correctly
   added.
3. **VP-INDEX arithmetic:** kani(7) + proptest(7) + fuzz(2) + integration(7) + unit(1) = 24.
   P0(7) + P1(9) + test-sufficient(8) = 24. Both checks pass.
4. **BC-INDEX P0/P1 arithmetic:** P0=53, P1=13, Total=66. Consistent with row counts. (Prior
   INC-006 is confirmed FIXED.)
5. **ADR file count:** 7 files on disk = 7 in ARCH-INDEX ADR catalog.
6. **VP → BC traceability:** All 24 VPs have `source_bc` pointing to valid BC IDs.
7. **Domain invariant VP coverage:** DI-001..011 all covered by at least one VP (11/11 = 100%).
8. **All 4 PRD supplements exist:** interface-definitions.md, error-taxonomy.md, test-vectors.md,
   nfr-catalog.md all present.
9. **BC-INDEX P0/P1/Total statistics:** Correctly reflect 66 BCs (P0=53, P1=13).
10. **policies.yaml:** 19 policies, IDs 1–19 sequential with no gaps. Schema validates.
11. **DI-007 label in BC-INDEX:** Correctly updated: "HTML Anchor Extraction Scope Is Narrow |
    BC-2.05.001 (anchor_table module enforces scope per Invariant 3), VP-020 (integration
    test-sufficient)". (Prior INC-009 FIXED.)
12. **cicd-setup.md frontmatter:** Has document_type, level, version, producer, traces_to,
    timestamp. (Prior INC-011 FIXED.)
13. **gene-transfusion-assessment.md verdict vocabulary:** Lines 211–215 now correctly use `alive`
    (not "valid"). (Prior INC-010 FIXED.)
14. **BC H1 ↔ BC-INDEX alignment (all 66, minus BC-2.05.001):** 65 of 66 BCs have BC-INDEX titles
    matching their H1. The one exception is BC-2.05.001 (REGRESSION-001 above).
15. **URL deduplication BC:** BC-2.10.009 "URL Deduplication — Each Unique External URL Fetched
    Once, Verdict Reported at Every Occurrence" correctly added. (Prior INC-003 FIXED.)
16. **PRD §2.10 and §2.12 topic scramble:** PRD section 2 tables now use authoritative BC H1
    titles. (Prior INC-001, INC-002 FIXED.)
17. **BC priority alignment:** PRD section 2.x and RTM priorities reconciled with BC-INDEX.
    (Prior INC-005 FIXED.)
18. **NFR-007 in PRD §4:** PRD §4 now includes NFR-007 "No Undefined Reason Codes" and NFR-008.
    (Prior INC-007 FIXED.)
19. **error-taxonomy.md target-is-directory qualifier:** Updated to reflect bare directory link →
    `clean`, fragment-present directory link → `broken`. (Prior DFT-001 FIXED.)
20. **No UX/design-system/multi-repo artifacts:** No references to ux-spec/, design-system/, or
    cross-repo paths found.

---

## Prior-Finding Verdict Table

| Finding | Severity | Description | Verdict |
|---------|----------|-------------|---------|
| INC-001 | CRITICAL | PRD §2.10 SS-10 BC topic scramble | **FIXED** |
| INC-002 | CRITICAL | PRD §2.12 SS-12 BC topic scramble | **FIXED** |
| INC-003 | CRITICAL | URL deduplication has no BC | **FIXED** (BC-2.10.009 added) |
| INC-004 | MAJOR | PRD section 2.x wording mismatches (9 BCs) | **FIXED** |
| INC-005 | MAJOR | BC priority alignment (17 BCs PRD vs. BC-INDEX) | **FIXED** |
| INC-006 | MAJOR | BC-INDEX P0/P1 arithmetic off by 1 | **FIXED** |
| INC-007 | MAJOR | NFR-007 absent from PRD §4 | **FIXED** |
| INC-008 | MAJOR | Module criticality tier conflicts (5 modules) | **PARTIAL** — tier reconciled; VP counts now stale (REGRESSION-004) |
| DFT-001 | MAJOR | error-taxonomy.md target-is-directory factual error | **FIXED** |
| INC-009 | MINOR | BC-INDEX DI-007 "reserved" label misleading | **FIXED** |
| INC-010 | MINOR | gene-transfusion-assessment.md uses "valid" for alive | **FIXED** |
| INC-011 | MINOR | cicd-setup.md missing 5 frontmatter fields | **FIXED** |
| DFT-002 | MINOR | Architecture shards stale input-hashes | **INFORMATIONAL** — architecture shards at v1.3 post-remediation; hash updates tracked |
| DFT-003 | MINOR | PRD supplements stale input-hashes | **REGRESSED** — interface-definitions.md now has a content error (REGRESSION-005) beyond the hash staleness |

---

## Artifacts That Must Be Regenerated

The following artifacts require updates before Phase 1 gate passes. Listed in dependency order
(items 1–3 are blocking; all others should be resolved in the same pass).

**Blocking (Phase 1 gate cannot pass until resolved):**

1. `.factory/specs/domain-spec/edge-cases.md` — Remove DEC-001 (EC-049 holdout specification)
   and DEC-003 (EC-074 holdout specification). Owner: spec-steward.

2. `.factory/holdout-scenarios/wave-scenarios/HS-INDEX.md` — Create with canonical frontmatter
   and catalog of HS-001/HS-002/HS-003. Update each scenario file's `traces_to`. Owner: spec-steward.

3. `.factory/specs/prd-supplements/interface-definitions.md` — Fix TLS verdict claim (line 64)
   from `indeterminate` to `broken (tls-error)`. Bump to v1.5. Owner: product-owner.

**Non-blocking MAJOR (resolve before Phase 2):**

4. `.factory/specs/behavioral-contracts/BC-INDEX.md` — Update BC-2.05.001 title row and DI-008
   label. Bump to v1.6. Owner: product-owner.

5. `.factory/specs/behavioral-contracts/ss-01/BC-2.01.001.md` — Remove `.markdown` and `--hidden`
   references. Bump to v1.1. Owner: product-owner.

6. `.factory/specs/behavioral-contracts/ss-01/BC-2.01.002.md` — Remove `.markdown` reference
   (line 43). Owner: product-owner.

7. `.factory/specs/behavioral-contracts/ss-02/BC-2.02.001.md` — Remove `.markdown` reference
   (line 41). Owner: product-owner.

8. `.factory/specs/module-criticality.md` — Update VP counts for url_classifier (0→1) and
   path_resolver (2→3). Bump to v1.3. Owner: architect.

9. `.factory/specs/behavioral-contracts/ss-10/BC-2.10.001.md` — Replace "clean" with "alive" in
   test vectors. Owner: product-owner.

10. `.factory/specs/behavioral-contracts/ss-10/BC-2.10.002.md` — Replace "alive (clean)" and
    "alive → clean" with "alive". Bump to v1.5. Owner: product-owner.

11. `.factory/specs/behavioral-contracts/ss-10/BC-2.10.003.md` — Replace "clean" with "alive" in
    test vectors. Owner: product-owner.

12. `.factory/specs/behavioral-contracts/ss-10/BC-2.10.007.md` — Replace "clean" with "alive" in
    test vectors. Owner: product-owner.

13. `.factory/specs/architecture/ARCH-INDEX.md` — Add feasibility-review.md to Document Map.
    Bump to v1.1. Owner: architect.

**Non-blocking MINOR (resolve before Phase 2):**

14. `.factory/specs/behavioral-contracts/ss-01/BC-2.01.008.md` — Reword Invariant 2 to remove
    `--quiet` conditional. Bump to v1.1. Owner: product-owner.

15. `.factory/specs/architecture/decisions/ADR-007-three-verdict-model.md` — Replace DD-015
    references (×3) with DD-016. Bump to v1.2. Owner: architect.

---

## CONSISTENCY_AUDIT: FAIL

**Gate status:** FAIL — 3 CRITICAL blocking findings must be resolved before Phase 1 gate passes.

**Finding counts (this pass):**
- CRITICAL: 3 — HOLDOUT-001, HOLDOUT-002, MISSING-INDEX-001
- MAJOR: 7 — REGRESSION-001, REGRESSION-002, REGRESSION-004, REGRESSION-005, INCONSISTENCY-001, INCONSISTENCY-002, INCONSISTENCY-003
- MINOR: 3 — REGRESSION-003, REGRESSION-006, DRIFT-001
- **Total findings: 13**

**Prior finding resolution:** 11/14 FIXED, 1/14 PARTIAL (INC-008), 1/14 REGRESSED (DFT-003
scope upgrade to REGRESSION-005), 1/14 INFORMATIONAL (DFT-002).

**Root cause summary:** The multi-agent Phase 1d remediation correctly fixed the 3 prior CRITICAL
findings and most MAJOR findings. However, four coordination failures occurred:
1. BC-2.05.001.md was rewritten to v1.3 without BC-INDEX.md being updated to match the new H1 title.
2. VP-023 and VP-024 were added to VP-INDEX and architecture documents without updating module-criticality.md.
3. interface-definitions.md §2.3 was regenerated but carried forward a stale `indeterminate` claim for TLS.
4. The holdout boundary cleanup removed EC-074 from BC files but did not remove DEC-003 from `domain-spec/edge-cases.md`; EC-049 in DEC-001 was not cleaned up at all.
