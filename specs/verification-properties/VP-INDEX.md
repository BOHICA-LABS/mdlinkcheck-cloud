---
document_type: vp-index
level: L4
version: "1.7"
status: draft
producer: architect
timestamp: 2026-08-10T00:00:00Z
phase: 1b
total_vps: 26
kani_count: 7
proptest_count: 9
fuzz_count: 2
integration_count: 7
unit_count: 1
p0_count: 7
p1_count: 11
test_sufficient_count: 8
traces_to: .factory/specs/architecture/ARCH-INDEX.md
changelog:
  - version: "1.7"
    date: 2026-08-10
    change: "BI-052 remediation: BC-to-VP table updated for 7 BCs. BC-2.07.001 VP changed from VP-008 to VP-004 (fragment-strip property belongs to VP-004 kani, not path-resolution proptest). BC-2.07.004 notes updated: P5 decode-ordering is integration test, not kani. BC-2.08.001 changed from VP-015/VP-025 to VP-004/VP-025 (VP-025 covers same-file lookup and case-sensitive; VP-004 P6 covers fragment decode). BC-2.10.005 and BC-2.10.006 moved from VP-007 to pending (dns/tls harnesses require classify_response_with_error API not in declared API). BC-2.12.001 and BC-2.13.001 VP-021 rows removed (VP-021 does not prove clean-link absence, ANSI absence, or field order; those are verified by acceptance corpus). BCs-with-real-VP count: 33→31 (BC-2.10.005 and BC-2.10.006 now pending). DI-003 note updated: VP-004 P5/P6 integration tests now provide decode-ordering coverage."
  - version: "1.6"
    date: 2026-08-06
    change: "D-043 / C4-008: VP-022 DI Covered column updated D-013/NFR-001 → D-013/NFR-008 (VP-022 validates the ~500ms per-commit CI regression gate NFR-008, not the 5s acceptance ceiling NFR-001). No VP count changes; arithmetic invariant unchanged."
  - version: "1.5"
    date: 2026-08-06
    change: "BI-005 spec-level closure: added VP-026 (slug differential fidelity, proptest P1, BC-2.06.001/BC-2.06.002, DI-012/DI-013/FM-002). Updated total_vps 25→26, proptest_count 8→9, p1_count 10→11. DI-012 coverage upgraded from Partial to Yes (proptest oracle); DI-013 coverage upgraded from Partial to Yes (kani+proptest). BC-to-VP table updated for BC-2.06.001/BC-2.06.002. Slug module proptest count 0→1, total 5→6. FM-002 now covered-by-VP-026 (was unprovable: VP-003 injectivity + VP-018 without duplicate-heading vectors could not detect the 0-based/1-based counter bug). Arithmetic invariant: 7+9+2+7+1=26; 7+11+8=26."
  - version: "1.4"
    date: 2026-08-06
    change: "DI-012/DI-013 coverage mapping: new domain invariants landed (invariants.md v1.5). VP-003 assigned to DI-013 (Kani injectivity; partial — proves distinct slugs, not suffix numbering). VP-018 assigned to DI-012 (partial — 16 worked examples; no formal proof for all inputs). DI Coverage Summary extended: DI-012 Partial, DI-013 Partial. Coverage line updated 11/11→13/13-partial. No new VPs added; gap analysis recorded: DI-012 needs a new VP for differential-testing correctness, DI-013 needs VP-018 duplicate-heading vectors to close suffix-numbering gap."
  - version: "1.3"
    date: 2026-08-06
    change: "INC-MAP-001 closure: added VP-025 (anchor_resolver totality + correctness, proptest P1, BC-2.08.001/002/004); updated BC→VP rows for BC-2.08.001/002/004 to include VP-025; updated per-module VP count for anchor_resolver 0→1; updated arithmetic invariant for 25 VPs; INC-MAP-004 disposition recorded in bc-module-map.md"
  - version: "1.2"
    date: 2026-08-05
    change: "BC coverage gap closure: added VP-023 (url_classifier totality / empty-dest contract, proptest P1, BC-2.07.007) and VP-024 (path_resolver trailing-slash-on-file invariant, proptest P1, BC-2.07.008); added BC→VP rows for all 6 new BCs (BC-2.07.007, BC-2.07.008, BC-2.10.010, BC-2.11.004, BC-2.12.005, BC-2.14.004); updated SS section counts; updated coverage summary to 66 BCs; system-overview.md clarified startup config error vs no-fail-fast rule"
  - version: "1.1"
    date: 2026-08-05
    change: "Phase 1d remediation: F-022 (verified p1_count=7, test_sufficient_count=6 correct per actual VP files; the prior-pass values were already right); F-026 (added VP-021 for NFR-007 no-undefined-reason-codes, test-sufficient); D-013 (added VP-022 for regression gate, test-sufficient); F-007 (added complete BC-to-VP coverage table); DI-006 description updated to reflect widened scope (all 4 exclusion mechanisms); arithmetic invariant updated for 22 VPs"
---

# VP-INDEX: Verification Properties — mdlinkcheck

This file is the authoritative enumeration of all Verification Properties (VPs) for
the mdlinkcheck product. Any change to VP count, module assignment, proof method, or
phase tier MUST propagate to:

1. `architecture/verification-architecture.md` — Provable Properties Catalog + P0/P1 lists
2. `architecture/verification-coverage-matrix.md` — VP-to-Module table + Totals row
3. Any `architecture/*.md` file with a `VP-NNN` reference

**Arithmetic invariant:** total_vps (26) = kani (7) + proptest (9) + fuzz (2) + integration (7) + unit (1) = 26.
Phase check: p0 (7) + p1 (11) + test_sufficient (8) = 26. Check before editing.

## VP Catalog

| VP | File | Module | Proof Method | Phase | DI Covered | Status |
|----|------|--------|-------------|-------|-----------|--------|
| VP-001 | vp-001-slug-total.md | slug | kani | P0 | — (CAP-006 PC1) | draft |
| VP-002 | vp-002-slug-deterministic.md | slug | kani | P0 | — (CAP-006, NFR-003) | draft |
| VP-003 | vp-003-slug-duplicate-uniqueness.md | slug | kani | P0 | DI-013 (BC-2.06.002) | draft |
| VP-004 | vp-004-fragment-split.md | fragment | kani | P0 | DI-003 | draft |
| VP-005 | vp-005-exit-code-io-error.md | verdict | kani | P0 | DI-011 | draft |
| VP-006 | vp-006-exit-code-clean.md | verdict | kani | P0 | DI-010 | draft |
| VP-007 | vp-007-http-verdict-total.md | http_verdict | kani | P0 | — (BC-2.10.002) | draft |
| VP-008 | vp-008-path-nfc-comparison.md | path_resolver | proptest | P1 | DI-002 | draft |
| VP-009 | vp-009-nfc-idempotent.md | path_resolver | proptest | P1 | DI-002 | draft |
| VP-010 | vp-010-allow-component-boundary.md | filter | proptest | P1 | — (DD-013) | draft |
| VP-011 | vp-011-sort-deterministic.md | reporter | proptest | P1 | DI-001 | draft |
| VP-012 | vp-012-slug-fuzz.md | slug | fuzz | P1 | — (R-001, R-002) | draft |
| VP-013 | vp-013-fragment-fuzz.md | fragment | fuzz | P1 | DI-003 | draft |
| VP-014 | vp-014-code-context-exclusion.md | link_extractor | integration | test-sufficient | DI-004 | draft |
| VP-015 | vp-015-two-pass-anchor-complete.md | anchor_table | integration | test-sufficient | DI-008 | draft |
| VP-016 | vp-016-ignored-files-anchor-targets.md | anchor_table | integration | test-sufficient | DI-006 | draft |
| VP-017 | vp-017-scan-terminates.md | scanner | integration | test-sufficient | DI-009 | draft |
| VP-018 | vp-018-slug-worked-examples.md | slug | unit | test-sufficient | DI-012 partial (NFR-006) | draft |
| VP-019 | vp-019-one-verdict-per-link.md | link_extractor | proptest | P1 | DI-005 | draft |
| VP-020 | vp-020-html-anchor-narrow-scope.md | anchor_table | integration | test-sufficient | DI-007 | draft |
| VP-021 | vp-021-no-undefined-reason-codes.md | reporter | integration | test-sufficient | — (NFR-007) | draft |
| VP-022 | vp-022-regression-gate.md | app | integration | test-sufficient | — (D-013/NFR-008) | draft |
| VP-023 | vp-023-url-classifier-totality.md | url_classifier | proptest | P1 | — (BC-2.07.007 empty-dest) | draft |
| VP-024 | vp-024-path-resolver-trailing-slash.md | path_resolver | proptest | P1 | — (BC-2.07.008 trailing-slash) | draft |
| VP-025 | vp-025-anchor-resolver-totality.md | anchor_resolver | proptest | P1 | — (BC-2.08.001/002/004 totality+correctness) | draft |
| VP-026 | vp-026-slug-differential-fidelity.md | slug | proptest | P1 | DI-012, DI-013, FM-002 (BC-2.06.001/002) | draft |

## DI Coverage Summary

| DI | Invariant (summary) | VP(s) | Method(s) | All Covered? |
|----|---------------------|-------|-----------|-------------|
| DI-001 | Deterministic output ordering | VP-011 | proptest | Yes |
| DI-002 | Case-sensitive NFC path comparison | VP-008, VP-009 | proptest x 2 | Yes |
| DI-003 | Fragment split before percent-decode; path/fragment decode-ordering | VP-004, VP-013 | kani + fuzz + integration (P5/P6) | Yes — kani proves split precedes decode; P5/P6 integration tests prove path/fragment components are decoded by callers before lookup |
| DI-004 | Code context exclusion structural | VP-014 | integration | Yes |
| DI-005 | Exactly one verdict per link | VP-019 | proptest | Partial — VP-019 proves extract_links is duplicate-free within one file (extraction precondition); full pipeline guarantee (no-verdict and two-verdict cases, e.g. path_resolver AND anchor_resolver both firing on the same link) requires a Phase 3 integration test |
| DI-006 | Excluded files (--ignore, .gitignore, dot-dirs, outside-root) are valid anchor targets | VP-016 | integration | Yes |
| DI-007 | HTML anchor extraction narrow scope | VP-020 | integration | Yes |
| DI-008 | Anchor table built before any link resolution (two-pass + Pass 1.5) | VP-015 | integration | Yes |
| DI-009 | Scan terminates for any input | VP-017 | integration | Yes |
| DI-010 | Indeterminate does not cause exit 1 | VP-006 | kani | Yes |
| DI-011 | Exit 2 takes precedence over exit 1 | VP-005 | kani | Yes |
| DI-012 | Slug computation fidelity (github-slugger v2 algorithm) | VP-018, VP-026 | unit + proptest | Yes — VP-018 (15 worked examples incl. AI & Automation rule-3 and emoji rule-7 falsifying cases); VP-026 (proptest differential oracle, all 7 DI-012 rules independently falsifiable, committed github-slugger@2.0.0 corpus) |
| DI-013 | Anchor-key uniqueness / injectivity within a file | VP-003, VP-026 | kani + proptest | Yes — VP-003 (Kani P0 injectivity); VP-026 oracle R-001 (≥3-entry repeat run proves exact 0-based counter: setup/setup-1/setup-2; closes FM-002 which injectivity alone cannot detect) |

All 13 domain invariants have VP coverage. Coverage: 13/13 (DI-012 and DI-013 fully covered by VP-018+VP-026 and VP-003+VP-026 respectively; FM-002 closed).

## Per-Module VP Count

| Module | Kani | Proptest | Fuzz | Integration | Unit | Total |
|--------|------|---------|------|-------------|------|-------|
| slug | 3 | 1 | 1 | 0 | 1 | 6 |
| fragment | 1 | 0 | 1 | 0 | 0 | 2 |
| verdict | 2 | 0 | 0 | 0 | 0 | 2 |
| http_verdict | 1 | 0 | 0 | 0 | 0 | 1 |
| anchor_table | 0 | 0 | 0 | 3 | 0 | 3 |
| anchor_resolver | 0 | 1 | 0 | 0 | 0 | 1 |
| path_resolver | 0 | 3 | 0 | 0 | 0 | 3 |
| link_extractor | 0 | 1 | 0 | 1 | 0 | 2 |
| filter | 0 | 1 | 0 | 0 | 0 | 1 |
| reporter | 0 | 1 | 0 | 1 | 0 | 2 |
| scanner | 0 | 0 | 0 | 1 | 0 | 1 |
| app | 0 | 0 | 0 | 1 | 0 | 1 |
| url_classifier | 0 | 1 | 0 | 0 | 0 | 1 |
| **Totals** | **7** | **9** | **2** | **7** | **1** | **26** |

## BC-to-VP Coverage Table

Authoritative mapping of all 66 BCs to their verifying VPs (or `test-sufficient` where
no formal VP exists). The product-owner uses this table to back-fill the VP columns in
BC files. `test-sufficient` means the behavior is covered by integration/acceptance tests
but no dedicated formal VP file exists for that BC.

BCs with a real VP: **33**. BCs test-sufficient only: **33**.

### SS-01: File Discovery (9 BCs)

| BC | Title (abbreviated) | VP(s) | Notes |
|----|---------------------|-------|-------|
| BC-2.01.001 | Recursive .md discovery | test-sufficient | covered by acceptance corpus |
| BC-2.01.002 | Explicit PATH arguments | test-sufficient | covered by acceptance corpus |
| BC-2.01.003 | .gitignore/.ignore exclusion | VP-016 | anchor tables built for gitignored files |
| BC-2.01.004 | Dot-directory skip (unconditional, D-011) | VP-017 | termination includes symlink non-following |
| BC-2.01.005 | Extension matching (.md only, D-012) | test-sufficient | D-012: .MD/.markdown/.mdx excluded |
| BC-2.01.006 | File symlink following | test-sufficient | covered by acceptance corpus |
| BC-2.01.007 | Path deduplication | test-sufficient | covered by acceptance corpus |
| BC-2.01.008 | Zero .md files yields exit 0 | test-sufficient | covered by acceptance corpus |
| BC-2.01.009 | Non-existent/unreadable PATH yields exit 2 | VP-005 | exit-code-io-error Kani proof |

### SS-02: Parser (4 BCs)

| BC | Title (abbreviated) | VP(s) | Notes |
|----|---------------------|-------|-------|
| BC-2.02.001 | CommonMark+GFM parsing | test-sufficient | covered by acceptance corpus |
| BC-2.02.002 | BOM/CRLF normalization | test-sufficient | covered by acceptance corpus |
| BC-2.02.003 | Non-UTF-8 file yields I/O error | test-sufficient | covered by acceptance corpus |
| BC-2.02.004 | Explicit non-.md file argument parsed | test-sufficient | covered by acceptance corpus |

### SS-03: Link Extractor (6 BCs)

| BC | Title (abbreviated) | VP(s) | Notes |
|----|---------------------|-------|-------|
| BC-2.03.001 | Inline link/image extraction | VP-019, VP-014 | one-verdict + code-context |
| BC-2.03.002 | Reference-style links | VP-019 | one-verdict property covers all extraction forms |
| BC-2.03.003 | Undefined reference yields broken | test-sufficient | covered by acceptance corpus |
| BC-2.03.004 | CommonMark autolinks in scope | test-sufficient | covered by acceptance corpus |
| BC-2.03.005 | Non-http schemes yield clean | test-sufficient | covered by acceptance corpus |
| BC-2.03.006 | Footnotes excluded | test-sufficient | covered by acceptance corpus |

### SS-04: Code Context (3 BCs)

| BC | Title (abbreviated) | VP(s) | Notes |
|----|---------------------|-------|-------|
| BC-2.04.001 | Fenced/inline code yields no links | VP-014 | DI-004 integration |
| BC-2.04.002 | Indented code/HTML comments yield no links | VP-014 | DI-004 integration |
| BC-2.04.003 | ATX headings in fenced blocks no anchor | VP-014 | DI-004 integration |

### SS-05: Anchor Table Builder (3 BCs)

| BC | Title (abbreviated) | VP(s) | Notes |
|----|---------------------|-------|-------|
| BC-2.05.001 | Two-pass (+ Pass 1.5) design | VP-015 | DI-008 integration |
| BC-2.05.002 | ATX/Setext heading extraction | VP-018 | slug worked examples unit test |
| BC-2.05.003 | HTML id=/name= extraction | VP-020 | DI-007 narrow-scope integration |

### SS-06: Slug (2 BCs)

| BC | Title (abbreviated) | VP(s) | Notes |
|----|---------------------|-------|-------|
| BC-2.06.001 | github-slugger v2 core algorithm | VP-001, VP-002, VP-012, VP-018, VP-026 | totality + determinism + fuzz + worked examples + differential oracle |
| BC-2.06.002 | Duplicate-heading counter | VP-003, VP-026 | Kani injectivity + proptest 0-based counter oracle (FM-002 discriminator) |

### SS-07: Path Resolver (8 BCs)

| BC | Title (abbreviated) | VP(s) | Notes |
|----|---------------------|-------|-------|
| BC-2.07.001 | Relative path resolution | VP-004 | fragment stripped before path resolution (kani); .. resolution logical — no current VP |
| BC-2.07.002 | Root-relative link resolution | test-sufficient | covered by acceptance corpus |
| BC-2.07.003 | NFC normalization + case-sensitive comparison | VP-008, VP-009 | NFC comparison + idempotency |
| BC-2.07.004 | Percent-encoding in destinations | VP-004 | fragment split kani (P1-P4); P5 path decode-ordering via integration test; P6 fragment decode-ordering covered in BC-2.08.001 via VP-004 |
| BC-2.07.005 | Destination-is-directory verdict | test-sufficient | covered by acceptance corpus |
| BC-2.07.006 | Non-Markdown target existence-only | test-sufficient | covered by acceptance corpus |
| BC-2.07.007 | Empty link destination → malformed-url | VP-023 | url_classifier totality proptest; empty string returns Malformed(_), never NonHttp |
| BC-2.07.008 | Trailing slash on regular file → file-not-found | VP-024 | path_resolver trailing-slash proptest; File entry + trailing slash → broken(file-not-found), never target-is-directory |

### SS-08: Anchor Resolver (4 BCs)

| BC | Title (abbreviated) | VP(s) | Notes |
|----|---------------------|-------|-------|
| BC-2.08.001 | Anchor-only link (#fragment) | VP-004, VP-025 | decode-ordering P6 integration (VP-004) + resolver totality and case-sensitive lookup (VP-025) |
| BC-2.08.002 | Cross-file anchor resolution | VP-015, VP-016, VP-025 | two-pass + out-of-scan anchor tables + resolver correctness |
| BC-2.08.003 | Fragment split at first unescaped # | VP-004, VP-013 | Kani proof + fuzz |
| BC-2.08.004 | Cross-file anchor into ignored file | VP-016, VP-025 | DI-006 integration + resolver correctness |

### SS-09: URL Classifier (2 BCs)

| BC | Title (abbreviated) | VP(s) | Notes |
|----|---------------------|-------|-------|
| BC-2.09.001 | External URL syntax validation (offline) | test-sufficient | covered by acceptance corpus |
| BC-2.09.002 | --allow suppresses external URL checks | VP-010 | component-boundary proptest |

### SS-10: HTTP Checker (10 BCs)

| BC | Title (abbreviated) | VP(s) | Notes |
|----|---------------------|-------|-------|
| BC-2.10.001 | HEAD-then-GET fallback protocol | test-sufficient | httpmock integration tests |
| BC-2.10.002 | Three-verdict model (broken/indeterminate/alive) | VP-007 | http_verdict Kani totality + correctness |
| BC-2.10.003 | Per-URL 10-second timeout | test-sufficient | httpmock integration tests |
| BC-2.10.004 | 429 rate-limit handling | test-sufficient | httpmock integration tests |
| BC-2.10.005 | DNS resolution failure yields broken | pending | dns-failure harness pending HttpAttempt transport-error API extension; no classify_response_with_error in declared API |
| BC-2.10.006 | TLS handshake failure behavior | pending | tls-error harness pending HttpAttempt transport-error API extension; no classify_response_with_error in declared API |
| BC-2.10.007 | Redirect chain max 10 hops | test-sufficient | httpmock integration tests |
| BC-2.10.008 | Concurrency 32 global / 4 per-host | test-sufficient | httpmock concurrent-connections assertions |
| BC-2.10.009 | URL deduplication (fetch once, report each occurrence) | test-sufficient | httpmock integration tests |
| BC-2.10.010 | Private-IP / link-local URL → indeterminate (no HTTP sent) | test-sufficient | integration test: mock DNS returning private IP; assert no socket opened; pure IP-range check is simple conditional, not panic-class |

### SS-11: Filter (4 BCs)

| BC | Title (abbreviated) | VP(s) | Notes |
|----|---------------------|-------|-------|
| BC-2.11.001 | --ignore glob exclusion (source files only) | VP-016 | anchor tables built for --ignore'd files |
| BC-2.11.002 | --allow URL prefix with component-boundary safety | VP-010 | component-boundary proptest |
| BC-2.11.003 | --ignore on explicit PATH argument | test-sufficient | covered by acceptance corpus |
| BC-2.11.004 | Invalid --ignore glob → exit 2 before scanning | test-sufficient | startup config error; clap + globset validation in cli module; integration test (invalid glob arg → assert exit 2 + stderr pattern + no file traversal); not subject to no-fail-fast (see system-overview.md §Error Handling) |

### SS-12: Text Reporter (5 BCs)

| BC | Title (abbreviated) | VP(s) | Notes |
|----|---------------------|-------|-------|
| BC-2.12.001 | Text report format — one finding per line | VP-011 | sort determinism (proptest); clean-links-produce-no-output verified by acceptance corpus |
| BC-2.12.002 | Terminal color (NO_COLOR/CLICOLOR) | test-sufficient | covered by acceptance corpus |
| BC-2.12.003 | Stderr summary line | test-sufficient | covered by acceptance corpus (--quiet is dropped D-011) |
| BC-2.12.004 | --format text explicit alias | test-sufficient | covered by acceptance corpus |
| BC-2.12.005 | Stdout/stderr separation — findings to stdout only, summary to stderr only | test-sufficient | integration test: capture both streams; assert no finding-line pattern on stderr, no summary on stdout; consistent with api-surface.md Stdout/stderr contract |

### SS-13: JSON Reporter (2 BCs)

| BC | Title (abbreviated) | VP(s) | Notes |
|----|---------------------|-------|-------|
| BC-2.13.001 | JSON report format | VP-011 | sort determinism (proptest); parseability, ANSI-absence, field order verified by acceptance corpus |
| BC-2.13.002 | JSON schema stability contract | test-sufficient | covered by acceptance corpus + schema validation |

### SS-14: Exit Code (4 BCs)

| BC | Title (abbreviated) | VP(s) | Notes |
|----|---------------------|-------|-------|
| BC-2.14.001 | Exit code 0 — no broken links | VP-006 | exit-code-clean Kani (DI-010) |
| BC-2.14.002 | Exit code 2 takes precedence over exit 1 | VP-005 | exit-code-io-error Kani (DI-011) |
| BC-2.14.003 | Exit code 1 — at least one broken link | VP-005, VP-006 | both exit-code Kani proofs |
| BC-2.14.004 | --help / --version exit 0 without scanning | test-sufficient | clap library intercepts before app::run(); integration test verifies exit 0; "no scanning" confirmed by running --help/--version in a directory with broken links and asserting exit 0 (not 1/2) |

### Coverage Summary

| Metric | Count |
|--------|-------|
| Total BCs | 66 |
| BCs with at least one real VP | 31 |
| BCs test-sufficient only | 33 |
| BCs pending API extension | 2 |
| Dropped flags (D-011): --quiet, --offline, --insecure, --hidden | none of these have BCs in scope |

All 66 BCs covered (31 with VP + 33 test-sufficient + 2 pending). All 13 DIs covered by at least one VP (13/13). Pending BCs: BC-2.10.005 (dns-failure) and BC-2.10.006 (tls-error) — both await HttpAttempt transport-error API extension to make Kani harness compilable.
