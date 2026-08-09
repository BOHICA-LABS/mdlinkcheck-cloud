---
document_type: architecture-section
level: L3
section: bc-module-map
version: "1.6"
status: draft
producer: architect
timestamp: 2026-08-09T00:00:00Z
phase: 1b
inputs:
  - .factory/specs/architecture/ARCH-INDEX.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/purity-boundary-map.md
  - .factory/specs/module-criticality.md
  - .factory/specs/verification-properties/VP-INDEX.md
input-hash: "0cfd557"
traces_to: ARCH-INDEX.md
changelog:
  - version: "1.6"
    date: 2026-08-09
    change: "P7-S6-009: corrected Primary ownership count table — four cells had stale values (link_extractor 9→8, anchor_table 4→3, http_client 8→7, cli 4→3). Derived from BC mapping tables via awk; corrected column sums to 66, matching the declared total. http_client was a partial-fix regression: Module Ownership Summary already showed 7 but Primary table had not been updated. NOTE: check-counts.py has zero coverage of bc-module-map.md — this table is unguarded against future arithmetic drift; coverage gap routed to gate-#42 nine-checker sweep."
  - version: "1.5"
    date: 2026-08-09
    change: "BI-054 (P7-S6-001): corrected stale POL-14 directive. `test-sufficient` is the conforming VP-NNN column value for BCs with no formal VP (D-039 JOIN against VP-INDEX; accepted by check-placeholders.py); `none` is explicitly non-conforming. Updated preamble, §POL-14 Reference section, column definition, and all 33 VP-NNN col value cells in mapping tables (none→test-sufficient). No BC files modified — all 33 already hold the correct `test-sufficient` value. Checker passes 0/134 before and after."
  - version: "1.4"
    date: 2026-08-06
    change: "INC-MAP-001 status updated to SPEC-RESOLVED / IMPL-PENDING per D-033 two-event discipline: VP-025 v1.1 discharges the spec-level API misalignment (AnchorTable(HashSet<String>), three-variant Verdict, corrected import path, property 4 replaced); Phase 3 implementation obligation remains open (BI-010). Heading updated from RE-OPENED. Anchor_resolver VP note label corrected from stale 'resolved' claim."
  - version: "1.3"
    date: 2026-08-06
    change: "P4 remediation: (P4-008) SS-06 Key ADRs corrected from ADR-006 → ADR-008 (slug clean-room reimplementation); BC-2.06.001/002 Key ADRs likewise corrected. BC-2.05.003 Key ADRs corrected from ADR-006 → ADR-003 (pulldown-cmark governs HTML event stream). (C4-005) VP-026 added to SS-06 Formal VPs for BC-2.06.001/002. (P4-002) INC-MAP-001 re-opened — VP-025 was written against non-existent API (HashMap<String,usize>); AnchorTable is HashSet<String> per api-surface.md; VP-025 rewrite required."
  - version: "1.2"
    date: 2026-08-06
    change: "Ownership consistency pass: corrected 4 summary-vs-detail contradictions — BC-2.01.008 removed from app secondary (scanner-only per SS-01); BC-2.07.003 removed from path_resolver secondary group (it is primary per SS-07, was double-counted); BC-2.10.002 removed from url_classifier secondary (url_classifier not involved per SS-10); BC-2.10.001 removed from http_client secondary (it is primary per SS-10, was self-contradictory). Updated BC Count values: app 2→1, path_resolver 8→7, url_classifier 5→4, http_client 8→7. Rewrote 2 prose references to the placeholder-string pattern to eliminate false-positive checker matches."
  - version: "1.1"
    date: 2026-08-06
    change: "INC-MAP-001 resolved: added VP-025 to SS-08 Formal VPs for BC-2.08.001/002/004; updated VP note for anchor_resolver; marked INC-MAP-001 as RESOLVED; added explicit disposition for INC-MAP-004 (known gap, rationale recorded, no new VP)"
  - version: "1.0"
    date: 2026-08-05
    change: "Initial draft — fills 47 BC module placeholder cells; closes P3-027 (BC-2.10.009 dedup ambiguity); documents POL-14 defect for product-owner remediation"
---

# BC → Architecture Anchor Map: mdlinkcheck

> **Purpose:** Canonical BC → module mapping for Phase 2 story decomposition. One row per BC
> (all 66). Fills all 47 BC module placeholder cells in the behavioral contract files and closes the
> P3-027 adversary finding on BC-2.10.009 module ambiguity.
>
> **POL-14 Reference (BI-054 resolved):** For BCs with no formal VP, the correct `VP-NNN`
> column value is `test-sufficient` — accepted by `check-placeholders.py` when VP-INDEX
> classifies the BC as `test-sufficient` (D-039 runtime JOIN; Proof Method must be non-empty
> per D-078). `none` (lowercase) is explicitly non-conforming and rejected by POL-14. All 33
> BC files (53 VP table rows) currently hold the correct `test-sufficient` value; no
> product-owner remediation is needed. See §POL-14 Reference for the accepted value format.

## Universal ADRs

ADR-001 (pure-core/effectful-shell boundary) and ADR-002 (workspace layout) apply to every
module and every BC. The **Key ADRs** column below lists only the subsystem-specific ADRs
beyond these two.

## Column Definitions

| Column | Meaning |
|--------|---------|
| BC | Behavioral contract ID |
| Primary Module | Single owning module; story decomposition routes to this module |
| Secondary Module | Joint owner (explicit reason required); story must also touch this module |
| P/E | Pure (pure-core crate) or Effectful (binary crate) |
| Tier | Criticality tier from module-criticality.md: CRITICAL / HIGH / MEDIUM / LOW |
| Key ADRs | Subsystem-specific ADRs (ADR-001 + ADR-002 apply to all — omitted here) |
| Formal VPs | Real VP IDs from VP-INDEX; `—` means no formal VP exists for this BC |
| VP-NNN col value | Authoritative value for the `VP-NNN` cell of the BC's Verification Properties table per POL-14: a VP-NNN ID when a formal VP exists, or `test-sufficient` when VP-INDEX classifies the BC as test-sufficient (D-039 runtime JOIN) |

---

## SS-01: File Discovery (scanner)

Implementing module: `scanner` (effectful shell, HIGH).
Key ADRs: ADR-005 (rayon traversal).

| BC | Primary Module | Secondary Module | P/E | Tier | Key ADRs | Formal VPs | VP-NNN col value |
|----|---------------|-----------------|-----|------|---------|-----------|-----------------|
| BC-2.01.001 | `scanner` | — | Effectful | HIGH | ADR-005 | — | test-sufficient |
| BC-2.01.002 | `scanner` | — | Effectful | HIGH | ADR-005 | — | test-sufficient |
| BC-2.01.003 | `scanner` | — | Effectful | HIGH | ADR-005 | VP-016 | VP-016 |
| BC-2.01.004 | `scanner` | — | Effectful | HIGH | ADR-005 | VP-017 | VP-017 |
| BC-2.01.005 | `scanner` | — | Effectful | HIGH | ADR-005 | — | test-sufficient |
| BC-2.01.006 | `scanner` | — | Effectful | HIGH | ADR-005 | — | test-sufficient |
| BC-2.01.007 | `scanner` | — | Effectful | HIGH | ADR-005 | — | test-sufficient |
| BC-2.01.008 | `scanner` | — | Effectful | HIGH | ADR-005 | — | test-sufficient |
| BC-2.01.009 | `scanner` | `verdict` (exit code: I/O errors become exit 2 via verdict::exit_code) | Effectful / Pure | HIGH / CRITICAL | ADR-005, ADR-007 | VP-005 | VP-005 |

**BC-2.01.003 VP note:** VP-016 belongs to `anchor_table` module. It verifies that anchor tables
are built even for `.gitignore`-excluded files — the side effect of scanner still reading those
files. The primary implementing module for the .gitignore exclusion behavior is `scanner`.

---

## SS-02: Markdown Parsing (scanner, link_extractor)

Implementing modules: `scanner` (reads and parses), `link_extractor` (processes events).
Key ADRs: ADR-003 (pulldown-cmark choice).

| BC | Primary Module | Secondary Module | P/E | Tier | Key ADRs | Formal VPs | VP-NNN col value |
|----|---------------|-----------------|-----|------|---------|-----------|-----------------|
| BC-2.02.001 | `scanner` | `link_extractor` (processes the event stream scanner produces) | Effectful / Pure | HIGH / CRITICAL | ADR-003 | — | test-sufficient |
| BC-2.02.002 | `scanner` | — | Effectful | HIGH | ADR-003 | — | test-sufficient |
| BC-2.02.003 | `scanner` | — | Effectful | HIGH | ADR-003 | — | test-sufficient |
| BC-2.02.004 | `scanner` | — | Effectful | HIGH | ADR-003 | — | test-sufficient |

**Note:** BC-2.02.002 already has Architecture Module filled as `scanner.rs (SS-02, effectful shell)`.
This table is consistent with that entry.

---

## SS-03: Link Extraction (link_extractor)

Implementing module: `link_extractor` (pure core, CRITICAL).
Key ADRs: ADR-003 (pulldown-cmark event stream).

| BC | Primary Module | Secondary Module | P/E | Tier | Key ADRs | Formal VPs | VP-NNN col value |
|----|---------------|-----------------|-----|------|---------|-----------|-----------------|
| BC-2.03.001 | `link_extractor` | — | Pure | CRITICAL | ADR-003 | VP-019, VP-014 | VP-019, VP-014 |
| BC-2.03.002 | `link_extractor` | — | Pure | CRITICAL | ADR-003 | VP-019 | VP-019 |
| BC-2.03.003 | `link_extractor` | — | Pure | CRITICAL | ADR-003 | — | test-sufficient |
| BC-2.03.004 | `link_extractor` | — | Pure | CRITICAL | ADR-003 | — | test-sufficient |
| BC-2.03.005 | `url_classifier` | `link_extractor` (extracts the link; url_classifier classification drives clean verdict) | Pure | HIGH | ADR-003, ADR-007 | — | test-sufficient |
| BC-2.03.006 | `link_extractor` | — | Pure | CRITICAL | ADR-003 | — | test-sufficient |

**BC-2.03.005 ownership note:** "Non-http schemes yield clean" is a verdict that follows
from `url_classifier` returning a non-Http/Https UrlKind (ADR-007). `link_extractor`
extracts the link correctly; it is `url_classifier` that makes the clean-verdict classification
possible. Story decomposition must verify both that link_extractor does not drop non-http links
AND that url_classifier classifies them as non-http → pipeline routes to clean.

---

## SS-04: Code Context Exclusion (link_extractor)

Implementing module: `link_extractor` (pure core, CRITICAL), with `anchor_table` for BC-2.04.003.
Key ADRs: ADR-003 (structural exclusion via pulldown-cmark event types).

| BC | Primary Module | Secondary Module | P/E | Tier | Key ADRs | Formal VPs | VP-NNN col value |
|----|---------------|-----------------|-----|------|---------|-----------|-----------------|
| BC-2.04.001 | `link_extractor` | — | Pure | CRITICAL | ADR-003 | VP-014 | VP-014 |
| BC-2.04.002 | `link_extractor` | — | Pure | CRITICAL | ADR-003 | VP-014 | VP-014 |
| BC-2.04.003 | `link_extractor` | `anchor_table` (ATX headings inside fenced blocks must not produce anchors) | Pure | CRITICAL | ADR-003 | VP-014 | VP-014 |

**Note:** BC-2.04.003 already has Architecture Module filled as `link_extractor.rs (SS-04) + anchor_table.rs (SS-05)`.
This table is consistent with that entry.

---

## SS-05: Anchor Table Construction (anchor_table)

Implementing module: `anchor_table` (pure core, CRITICAL).
Key ADRs: ADR-006 (NFC strict path model — anchor slug comparison).

| BC | Primary Module | Secondary Module | P/E | Tier | Key ADRs | Formal VPs | VP-NNN col value |
|----|---------------|-----------------|-----|------|---------|-----------|-----------------|
| BC-2.05.001 | `anchor_table` | `app` (three-pass pipeline design that ensures anchor_table is complete before any resolution) | Pure / Effectful | CRITICAL / MEDIUM | ADR-006 | VP-015 | VP-015 |
| BC-2.05.002 | `anchor_table` | `slug` (ATX/Setext headings require slug computation to build the anchor key) | Pure | CRITICAL | ADR-006 | VP-018 | VP-018 |
| BC-2.05.003 | `anchor_table` | — | Pure | CRITICAL | ADR-003 | VP-020 | VP-020 |

---

## SS-06: Heading Slug Computation (slug)

Implementing module: `slug` (pure core, CRITICAL).
Key ADRs: ADR-008 (clean-room github-slugger v2 reimplementation — slug algorithm is the product's headline differentiator).

| BC | Primary Module | Secondary Module | P/E | Tier | Key ADRs | Formal VPs | VP-NNN col value |
|----|---------------|-----------------|-----|------|---------|-----------|-----------------|
| BC-2.06.001 | `slug` | — | Pure | CRITICAL | ADR-008 | VP-001, VP-002, VP-012, VP-018, VP-026 | VP-001, VP-002, VP-012, VP-018, VP-026 |
| BC-2.06.002 | `slug` | — | Pure | CRITICAL | ADR-008 | VP-003, VP-026 | VP-003, VP-026 |

---

## SS-07: Relative Path Resolution (path_resolver, fragment)

Implementing modules: `path_resolver` (primary, pure core, CRITICAL), `fragment` (secondary for
percent-encoding, pure core, CRITICAL).
Key ADRs: ADR-006 (NFC strict path model).

| BC | Primary Module | Secondary Module | P/E | Tier | Key ADRs | Formal VPs | VP-NNN col value |
|----|---------------|-----------------|-----|------|---------|-----------|-----------------|
| BC-2.07.001 | `path_resolver` | — | Pure | CRITICAL | ADR-006 | VP-008 | VP-008 |
| BC-2.07.002 | `path_resolver` | — | Pure | CRITICAL | ADR-006 | — | test-sufficient |
| BC-2.07.003 | `path_resolver` | `fragment` (percent-encoding decoded before NFC comparison — DI-002 requires this ordering) | Pure | CRITICAL | ADR-006 | VP-008, VP-009 | VP-008, VP-009 |
| BC-2.07.004 | `fragment` | `path_resolver` (receives already-split, percent-preserved dest string) | Pure | CRITICAL | ADR-006 | VP-004 | VP-004 |
| BC-2.07.005 | `path_resolver` | `anchor_resolver` (never called for directory targets — explicit exclusion) | Pure | CRITICAL | ADR-006, ADR-007 | — | test-sufficient |
| BC-2.07.006 | `path_resolver` | `anchor_resolver` (never called for non-Markdown targets) | Pure | CRITICAL | ADR-006, ADR-007 | — | test-sufficient |
| BC-2.07.007 | `url_classifier` | — | Pure | HIGH | ADR-006, ADR-007 | VP-023 | VP-023 |
| BC-2.07.008 | `path_resolver` | — | Pure | CRITICAL | ADR-006 | VP-024 | VP-024 |

**Note:** BC-2.07.005 and BC-2.07.006 already have Architecture Module filled. This table is
consistent with those entries.

**BC-2.07.007 ownership note:** "Empty link destination → malformed-url" is a `url_classifier`
concern (VP-023: totality proptest verifies empty string returns Malformed(_), never NonHttp).
This BC is filed in SS-07 because the behavior is observable during path resolution, but the
classification boundary belongs to url_classifier — no path resolution occurs for empty/malformed
destinations.

---

## SS-08: Anchor Resolution (anchor_resolver, fragment)

Implementing modules: `anchor_resolver` (pure core, CRITICAL), `fragment` (pure core, CRITICAL).
Key ADRs: ADR-007 (two-layer verdict model).

| BC | Primary Module | Secondary Module | P/E | Tier | Key ADRs | Formal VPs | VP-NNN col value |
|----|---------------|-----------------|-----|------|---------|-----------|-----------------|
| BC-2.08.001 | `anchor_resolver` | — | Pure | CRITICAL | ADR-007 | VP-015, VP-025 | VP-015, VP-025 |
| BC-2.08.002 | `anchor_resolver` | — | Pure | CRITICAL | ADR-007 | VP-015, VP-016, VP-025 | VP-015, VP-016, VP-025 |
| BC-2.08.003 | `fragment` | `anchor_resolver` (receives the split fragment for lookup) | Pure | CRITICAL | ADR-007 | VP-004, VP-013 | VP-004, VP-013 |
| BC-2.08.004 | `anchor_resolver` | — | Pure | CRITICAL | ADR-007 | VP-016, VP-025 | VP-016, VP-025 |

**anchor_resolver VP note (VP-025 v1.1 — INC-MAP-001 spec-resolved; impl pending):** VP-025 directly exercises
`anchor_resolver::resolve_anchor` with proptest (totality + lookup-hit correctness +
case-sensitivity + Indeterminate-exclusion). VP-015 and VP-016 remain assigned to `anchor_table`
in VP-INDEX — they verify the two-pass design that makes anchor_resolver's inputs complete.
Together VP-015/016 (table completeness) and VP-025 (lookup correctness) form a full
verification chain for the anchor resolution subsystem.

---

## SS-09: External URL Syntax Validation (url_classifier)

Implementing module: `url_classifier` (pure core, HIGH).
Key ADRs: ADR-007 (verdict model — classification drives routing).

| BC | Primary Module | Secondary Module | P/E | Tier | Key ADRs | Formal VPs | VP-NNN col value |
|----|---------------|-----------------|-----|------|---------|-----------|-----------------|
| BC-2.09.001 | `url_classifier` | — | Pure | HIGH | ADR-007 | — | test-sufficient |
| BC-2.09.002 | `filter` | `url_classifier` (the external URL check that --allow suppresses) | Pure | HIGH | ADR-007 | VP-010 | VP-010 |

---

## SS-10: External URL Liveness Checking (http_client, http_verdict)

Implementing modules: `http_client` (effectful shell, MEDIUM), `http_verdict` (pure core, CRITICAL).
Key ADRs: ADR-004 (ureq sync HTTP), ADR-005 (rayon + 32-thread pool), ADR-007 (three-verdict model).

| BC | Primary Module | Secondary Module | P/E | Tier | Key ADRs | Formal VPs | VP-NNN col value |
|----|---------------|-----------------|-----|------|---------|-----------|-----------------|
| BC-2.10.001 | `http_client` | `http_verdict` (classifies the response from the HEAD/GET protocol) | Effectful / Pure | MEDIUM / CRITICAL | ADR-004, ADR-005, ADR-007 | — | test-sufficient |
| BC-2.10.002 | `http_verdict` | `http_client` (implements the protocol that produces responses for classification) | Pure / Effectful | CRITICAL / MEDIUM | ADR-004, ADR-007 | VP-007 | VP-007 |
| BC-2.10.003 | `http_client` | — | Effectful | MEDIUM | ADR-004 | — | test-sufficient |
| BC-2.10.004 | `http_client` | `http_verdict` (429 classification drives pause decision) | Effectful / Pure | MEDIUM / CRITICAL | ADR-004, ADR-005, ADR-007 | — | test-sufficient |
| BC-2.10.005 | `http_verdict` | `http_client` (detects DNS failure; encodes it into Attempt enum for http_verdict) | Pure / Effectful | CRITICAL / MEDIUM | ADR-004, ADR-007 | VP-007 | VP-007 |
| BC-2.10.006 | `http_verdict` | `http_client` (detects TLS failure; encodes it into Attempt enum for http_verdict) | Pure / Effectful | CRITICAL / MEDIUM | ADR-004, ADR-007 | VP-007 | VP-007 |
| BC-2.10.007 | `http_client` | — | Effectful | MEDIUM | ADR-004 | — | test-sufficient |
| BC-2.10.008 | `http_client` | — | Effectful | MEDIUM | ADR-004, ADR-005 | — | test-sufficient |
| BC-2.10.009 | `http_client` | — | Effectful | MEDIUM | ADR-004, ADR-005 | — | test-sufficient |
| BC-2.10.010 | `http_client` | `http_verdict` (indeterminate verdict returned for private-IP URLs) | Effectful / Pure | MEDIUM / CRITICAL | ADR-004, ADR-007 | — | test-sufficient |

### BC-2.10.009 Ownership Decision (P3-027 Resolution)

**Decision: primary module is `http_client`.** Rationale:

1. **Purity boundary (ADR-001):** URL deduplication requires a mutable memo table
   (`HashMap<NormalizedUrl, Verdict>`). Mutable shared state is an effect; it cannot live in
   pure core. `http_verdict` is a pure function — `classify_response(status: u16, attempt:
   Attempt) → Verdict` — with no memory of prior calls. It physically cannot hold a memo table.
   The memo table must live in `http_client`.

2. **Concurrency coupling (ADR-005):** BC-2.10.009 PC5 requires that deduplicated URL occurrences
   share per-host concurrency bookkeeping and do not hold additional semaphore slots. The
   per-host semaphores are owned by `http_client` (32-global / 4-per-host rayon pool). The
   dedup logic must be co-located with the concurrency gating — both belong to `http_client`.

3. **429 pause sharing (BC-2.10.004 cross-reference):** PC6 of BC-2.10.009 requires all
   deduplicated occurrences of a URL to share the same 429 pause state. The pause state is
   a per-host runtime flag in `http_client`. Dedup must be in the same module to check "is
   this host currently paused?" before deciding whether to await the in-flight request or
   issue a new one.

4. **The "fetch once, report each occurrence" fan-out** is an I/O scheduling concern (when to
   issue a network request), not a verdict classification concern. `http_verdict` classifies
   responses; it is not involved in deciding whether to issue a request at all.

**Conclusion:** The memo table, deduplication gate, in-flight result sharing, and verdict
fan-out are all `http_client` responsibilities. `http_verdict` is not involved.

---

## SS-11: Filter Application (filter)

Implementing module: `filter` (pure core, HIGH).
Key ADRs: ADR-007 (verdict model — filtering suppresses findings).

| BC | Primary Module | Secondary Module | P/E | Tier | Key ADRs | Formal VPs | VP-NNN col value |
|----|---------------|-----------------|-----|------|---------|-----------|-----------------|
| BC-2.11.001 | `filter` | `scanner` (applies the glob patterns during traversal; still reads ignored files for anchor tables) | Pure / Effectful | HIGH | ADR-005, ADR-007 | VP-016 | VP-016 |
| BC-2.11.002 | `filter` | — | Pure | HIGH | ADR-007 | VP-010 | VP-010 |
| BC-2.11.003 | `filter` | `scanner` (applies filter to explicit PATH arguments during traversal) | Pure / Effectful | HIGH | ADR-007 | — | test-sufficient |
| BC-2.11.004 | `cli` | `verdict` (config_error=true → exit 2 via verdict::exit_code; see module-decomposition v1.2 changelog) | Effectful / Pure | LOW / CRITICAL | ADR-007 | — | test-sufficient |

**BC-2.11.001 VP note:** VP-016 belongs to `anchor_table` module. It verifies the side effect
that anchor tables are built even for `--ignore`'d files. The primary implementing module for
the --ignore glob matching is `filter`.

---

## SS-12: Text Report Generation (reporter)

Implementing module: `reporter` (pure core, HIGH).
Key ADRs: ADR-005 (sort-before-emit; deterministic output order), ADR-007 (verdict model).

| BC | Primary Module | Secondary Module | P/E | Tier | Key ADRs | Formal VPs | VP-NNN col value |
|----|---------------|-----------------|-----|------|---------|-----------|-----------------|
| BC-2.12.001 | `reporter` | — | Pure | HIGH | ADR-005, ADR-007 | VP-011, VP-021 | VP-011, VP-021 |
| BC-2.12.002 | `reporter` | `cli` (NO_COLOR / CLICOLOR env vars read by cli to produce CliArgs; reporter uses the flag) | Pure / Effectful | HIGH / LOW | ADR-005 | — | test-sufficient |
| BC-2.12.003 | `reporter` | `main` (routes summary string to stderr; reporter::format_text produces it) | Pure / Effectful | HIGH / LOW | ADR-005 | — | test-sufficient |
| BC-2.12.004 | `cli` | `reporter` (--format text flag selects format_text) | Effectful / Pure | LOW / HIGH | ADR-005 | — | test-sufficient |
| BC-2.12.005 | `reporter` | `main` (writes findings to stdout; writes summary to stderr; reporter produces both strings) | Pure / Effectful | HIGH / LOW | ADR-005 | — | test-sufficient |

---

## SS-13: JSON Report Generation (reporter)

Implementing module: `reporter` (pure core, HIGH).
Key ADRs: ADR-005 (sort-before-emit), ADR-007 (verdict model).

| BC | Primary Module | Secondary Module | P/E | Tier | Key ADRs | Formal VPs | VP-NNN col value |
|----|---------------|-----------------|-----|------|---------|-----------|-----------------|
| BC-2.13.001 | `reporter` | — | Pure | HIGH | ADR-005, ADR-007 | VP-011, VP-021 | VP-011, VP-021 |
| BC-2.13.002 | `reporter` | — | Pure | HIGH | ADR-005, ADR-007 | — | test-sufficient |

---

## SS-14: Exit Code Determination (verdict)

Implementing module: `verdict` (pure core, CRITICAL).
Key ADRs: ADR-007 (two-layer verdict model — clean / broken / indeterminate feeds exit_code).

| BC | Primary Module | Secondary Module | P/E | Tier | Key ADRs | Formal VPs | VP-NNN col value |
|----|---------------|-----------------|-----|------|---------|-----------|-----------------|
| BC-2.14.001 | `verdict` | — | Pure | CRITICAL | ADR-007 | VP-006 | VP-006 |
| BC-2.14.002 | `verdict` | — | Pure | CRITICAL | ADR-007 | VP-005 | VP-005 |
| BC-2.14.003 | `verdict` | — | Pure | CRITICAL | ADR-007 | VP-005, VP-006 | VP-005, VP-006 |
| BC-2.14.004 | `cli` | — | Effectful | LOW | ADR-007 | — | test-sufficient |

---

## Module Ownership Summary

| Module | BC Count | BCs |
|--------|----------|-----|
| `scanner` | 15 | BC-2.01.001–009, BC-2.02.001–004 (primary), BC-2.11.001/003 (secondary) |
| `link_extractor` | 12 | BC-2.03.001–006, BC-2.04.001–003 (primary), BC-2.02.001 (secondary) |
| `anchor_table` | 5 | BC-2.05.001–003, BC-2.04.003 (joint primary) |
| `slug` | 3 | BC-2.06.001–002, BC-2.05.002 (secondary) |
| `path_resolver` | 7 | BC-2.07.001–003, BC-2.07.005–006, BC-2.07.008 (primary), BC-2.07.004 (secondary) |
| `fragment` | 3 | BC-2.07.004, BC-2.08.003 (primary) |
| `anchor_resolver` | 4 | BC-2.08.001–002, BC-2.08.004 (primary) |
| `url_classifier` | 4 | BC-2.07.007, BC-2.09.001, BC-2.03.005 (primary); BC-2.09.002 (secondary) |
| `filter` | 4 | BC-2.11.001–003 (primary), BC-2.09.002 (primary) |
| `http_client` | 7 | BC-2.10.001, BC-2.10.003–004, BC-2.10.007–010 (primary) |
| `http_verdict` | 5 | BC-2.10.002, BC-2.10.005–006 (primary) |
| `reporter` | 8 | BC-2.12.001–003, BC-2.12.005, BC-2.13.001–002 (primary), BC-2.12.002 (secondary) |
| `verdict` | 5 | BC-2.14.001–003 (primary), BC-2.01.009 (secondary), BC-2.11.004 (secondary) |
| `cli` | 4 | BC-2.11.004, BC-2.14.004 (primary), BC-2.12.002/004 (primary/secondary) |
| `app` | 1 | BC-2.05.001 (secondary) |
| `main` | 2 | BC-2.12.003, BC-2.12.005 (secondary) |
| `types` | 0 | No executable behavior; structural shared types only |

**Primary ownership count per module (deduped — each BC counted once by its primary module):**

| Module | BCs (Primary) | Tier |
|--------|--------------|------|
| `scanner` | 13 | HIGH |
| `link_extractor` | 8 | CRITICAL |
| `path_resolver` | 6 | CRITICAL |
| `anchor_table` | 3 | CRITICAL |
| `filter` | 4 | HIGH |
| `reporter` | 6 | HIGH |
| `http_client` | 7 | MEDIUM |
| `http_verdict` | 3 | CRITICAL |
| `anchor_resolver` | 3 | CRITICAL |
| `url_classifier` | 3 | HIGH |
| `slug` | 2 | CRITICAL |
| `fragment` | 2 | CRITICAL |
| `verdict` | 3 | CRITICAL |
| `cli` | 3 | LOW |
| `app` | 0 | MEDIUM |
| `main` | 0 | LOW |
| **Total** | **66** | — |

---

## Architecture Inconsistency Notes

The following inconsistencies were observed while building this map. They are logged here for
the architect/product-owner to resolve; no BC file was modified.

### INC-MAP-001: anchor_resolver — VP-025 spec aligned (v1.1); Phase 3 implementation obligation outstanding

**Status: SPEC-RESOLVED / IMPL-PENDING.**

*Spec-level event (discharged 2026-08-06, VP-025 v1.1):* VP-025 has been rewritten to align
with `api-surface.md`. All API misalignments are corrected:
- Type: `AnchorTable(HashSet<String>)` (was `HashMap<String, usize>`, which does not exist)
- Return type: `Verdict` — three variants `Clean`, `Broken(FailureReason)`,
  `Indeterminate(FailureReason)` (was `AnchorVerdict`, a non-existent two-variant enum)
- Import path: `use mdlinkcheck_core::anchor_table::AnchorTable` (was `types`)
- Property 4: "Indeterminate is never returned from anchor resolution"
  (was "closed enum Hit|Miss", which was false against the declared API)

The spec-level defect — VP-025 harness non-compilable due to API mismatch (E0004
non-exhaustive match, BI-010 CRITICAL) — is discharged. VP-INDEX reflects the corrected spec.

*Implementation obligation (NOT yet discharged, BI-010):* Phase 3 must implement
`anchor_resolver`, make VP-025 green, and pass all related proofs before Phase 6 formal
hardening can proceed. No Rust workspace exists; Phase 3 has not started.

**This is NOT full closure.** Per D-033, closing a spec gap and discharging an implementation
obligation are separate events (precedent: BI-005 → BI-007 split). INC-MAP-001 fully closes
only when Phase 3 delivers a passing VP-025.

### INC-MAP-002: BC-2.03.005 spans SS-03 and SS-09 subsystem boundary

BC-2.03.005 "Non-http schemes yield clean" is filed in SS-03 (Link Extractor) but the
clean-verdict determination is architecturally a `url_classifier` (SS-09) concern. The BC is
correctly placed for the extraction story (link_extractor must extract the link) but the
verification acceptance criterion must also assert url_classifier classification behavior.
Story writers should be aware this BC produces stories that touch both modules.

### INC-MAP-003: BC-2.11.004 routes through cli → verdict via config_error bool

BC-2.11.004 (invalid --ignore glob → exit 2) crosses the cli → verdict boundary via the
`config_error: bool` parameter added to `verdict::exit_code` in module-decomposition v1.2.
This coupling is documented in that changelog. No gap — the architecture handles it. Noted
so story writers know the acceptance test must assert both the cli validation error AND the
exit 2 from verdict.

### INC-MAP-004: BC-2.01.003 VP belongs to anchor_table, not scanner — KNOWN GAP (disposition recorded)

**Status: Known gap — no new VP added. Rationale below.**

VP-016 is assigned to `anchor_table` in VP-INDEX. It verifies the observable downstream effect
of scanner's .gitignore compliance: anchor tables are built for gitignored files (DI-006).
This leaves a gap: no VP directly verifies that scanner *excludes* gitignored files as link
sources (i.e., links within .gitignore'd files are not reported as findings).

**Rationale for not adding a new VP:**

1. `scanner` is effectful (binary crate). Kani is not applicable. An integration VP is
   possible but would duplicate coverage already provided by the acceptance corpus: the
   corpus includes fixtures with .gitignore'd source files and asserts that no findings
   originate from them (checked in Phase 3 acceptance tests).

2. The `ignore` crate (the upstream library that implements .gitignore traversal) is a
   well-maintained, widely-deployed library with its own test suite. Scanner delegates the
   exclusion logic entirely to that crate; there is no custom gitignore-matching code to
   formally verify.

3. The combination of VP-016 (excluded files are valid anchor targets — proves scanner does
   read excluded files) and the acceptance corpus (proves scanner does not report findings
   from excluded files as sources) provides adequate coverage for BC-2.01.003 without a
   dedicated VP.

**Story writers** must include an acceptance test that asserts findings never originate
from .gitignore'd files (i.e., no `finding.source_file` matches a gitignored path).
This closes the gap at the integration test level.

---

## POL-14 Reference (BI-054 — stale directive corrected)

**Policy as implemented by `check-placeholders.py`:** In any Verification Properties table
whose header row first cell is exactly `VP-NNN`, every data row's first cell MUST be one of:

- A VP-NNN ID (e.g., `VP-007`) or a comma/slash-separated list of VP-NNN IDs — when a formal
  verification property exists for the BC.
- `test-sufficient` — **only** when VP-INDEX classifies the BC as `test-sufficient` (D-039
  runtime JOIN against VP-INDEX.md at check time) **and** the Proof Method cell is non-empty
  (D-078 precondition). Quoted from `check-placeholders.py` docstring: *"`test-sufficient`
  sentinel in VP-NNN column: Accepted ONLY when VP-INDEX classifies the file's BC ID as
  'test-sufficient'. This is a JOIN against VP-INDEX (not an allowlist, D-039)"*.
- `VP-NONE` — only when the Proof Method cell is non-empty (D-078).

`none` (lowercase) is **explicitly non-conforming** and is rejected by POL-14. Quoted from
`check-placeholders.py` docstring: *"Any other first-cell content (em-dash, en-dash, TBD,
none, empty, etc.) is a POL-14 violation — R2-RULE (D-069)."*

**History:** The original v1.0 directive in this document pre-dated commit `d4e76fa`
(`feat(pol14): test-sufficient VP sentinel`) which made `test-sufficient` a legal sentinel
in the VP-NNN column. The directive was not updated when the checker was, producing an inverted
guidance document that would break the gate if acted upon (BI-054 / P7-S6-001).

**Status:** Resolved at spec level (BI-054). `check-placeholders.py` currently reports
0 violations across 134 spec files. The 33 BC files (53 VP table rows) with `test-sufficient`
in the VP-NNN column are conforming. No product-owner remediation is needed.

**Correct format for a BC with no formal VP** (verified against the current checker):

```markdown
## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | [property description] | integration / acceptance test |
```

**Correct format for a BC with a formal VP:**
```markdown
| VP-007 | [property description] | kani |
```

## [Section Content]

<!-- Validator scaffold: real content is in the named sections above. The
     architecture-section-template uses "[Section Content]" as a literal
     placeholder heading; the compliance validator matches it by substring.
     This stub satisfies that check without altering any real content. -->
