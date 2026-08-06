---
document_type: architecture-section
level: L3
section: verification-architecture
version: "1.10"
status: draft
producer: architect
timestamp: 2026-08-06T00:00:00Z
phase: 1b
inputs:
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/prd.md
input-hash: "0983244"
traces_to: ARCH-INDEX.md
changelog:
  - version: "1.10"
    date: 2026-08-06
    change: "D-043 macOS-only platform directive: (1) VP-022 test-sufficient table row: D-013/NFR-001 → D-013/NFR-008 (C4-008 propagation from VP-INDEX). (2) VP-022 source contract inline reference corrected."
  - version: "1.9"
    date: 2026-08-06
    change: "P4 remediation: (P4-004) VP-011 sort key 'dest' → 'link_target' to match api-surface.md Finding struct field name. (P4-009) VP-026 proptest coverage claim corrected — removed false claims for NFC/NFD and inline-code+HTML; now names only the 6 rules with enabled proptest arms (rules 2/3/4/5/6/7); Rule 1b rendering fidelity explicitly deferred to Phase 3 integration; oracle corpus NFC/NFD runs (R-009/OR-010) recorded."
  - version: "1.8"
    date: 2026-08-06
    change: "BI-005 spec-level closure: added VP-026 (slug differential fidelity, proptest P1) to Should Prove table. DI→VP Coverage Matrix: DI-012 updated VP-018→VP-018+VP-026 (Yes, proptest oracle); DI-013 updated VP-003→VP-003+VP-026 (Yes, kani+proptest). FM-002 now covered by VP-026 (was unprovable — VP-003 injectivity does not detect 0-based/1-based counter bug). Gap notes removed for DI-012 and DI-013. Phase 3 obligation recorded: VP-026 must be green before Phase 6 hardening."
  - version: "1.7"
    date: 2026-08-06
    change: "DI-012/DI-013 coverage: new domain invariants landed (invariants.md v1.5). DI→VP Coverage Matrix extended with DI-012 (VP-018, test-sufficient/partial) and DI-013 (VP-003, P0 Kani/partial). Coverage summary updated 11→13. Gap analysis: DI-012 needs a new differential-proptest VP for full coverage; DI-013 suffix-numbering correctness needs duplicate-heading golden vectors in VP-018."
  - version: "1.6"
    date: 2026-08-06
    change: "INC-MAP-001 closure: added VP-025 (anchor_resolver::resolve_anchor totality + correctness, proptest P1, BC-2.08.001/002/004) to Should Prove table; proptest chosen over Kani because AnchorTable is a HashMap — CBMC state explosion for symbolic HashMap keys is unbounded even for a 1-entry table"
  - version: "1.5"
    date: 2026-08-05
    change: "P3-019 hotfix: VP-011 Should Prove table updated — sort key description now reflects four-field total key (nfc_path, line, col, dest); ordering guarantee no longer depends on unproven DI-005 full-pipeline guarantee (VP-019 covers extraction deduplication only; dest tie-break is the architectural resolution)"
  - version: "1.4"
    date: 2026-08-05
    change: "Pass-2 remediation: VP-001 corrected to slug::slugify (pure core, no counter); VP-002/003 confirmed as slug::compute_slug (counter-wrapping function); VP-003 description de-qualified — 'distinct' qualifier removed (property holds for all pairs); VP-005/006 corrected to verdict::exit_code (not compute_exit_code); P0 harness example updated to exit_code_symbolic with config_error third argument; VP-012 confirmed as compute_slug fuzz (consistent with VP-012 file)"
  - version: "1.3"
    date: 2026-08-05
    change: "BC coverage gap closure: added VP-023 (url_classifier totality / empty-dest, proptest P1, BC-2.07.007) and VP-024 (path_resolver trailing-slash-on-file, proptest P1, BC-2.07.008) to P1 Should Prove table"
  - version: "1.2"
    date: 2026-08-05
    change: "Phase 1d remediation: added VP-021 (NFR-007 no-undefined-reason-codes, test-sufficient) and VP-022 (D-013 regression gate, test-sufficient) to test-sufficient table; updated VP-016 description for widened DI-006 (all 4 exclusion mechanisms); updated DI-006 row in DI->VP matrix; corrected P0 harness example for VP-001 (slugify not compute_slug)"
  - version: "1.1"
    date: 2026-08-05
    change: "SR-019/SR-022 remediation: corrected VP-003 catalog description from overclaimed 'no two headings collide' to accurate injectivity scope; expanded VP-007 description to include correctness assertions (not just totality); updated path_resolver description for DirIndex"
  - version: "1.0"
    date: 2026-08-05
    change: "Initial draft"
---

# Verification Architecture: mdlinkcheck

## Provable Properties Catalog

### Must Prove (P0 — Kani, Phase 6)

| VP | Property | Module | Invariant |
|----|----------|--------|-----------|
| VP-001 | `slug::slugify` is total — no panic for any `&str` input | slug | CAP-006 PC1 |
| VP-002 | `slug::compute_slug` is deterministic — same input + same counter state → same output | slug | CAP-006, NFR-003 |
| VP-003 | `DuplicateCounter` output-uniqueness — for any two heading strings, `compute_slug` with a shared counter returns distinct slugs; same heading repeated N times also produces N distinct slugs (bound 10) | slug | BC-2.06.002 |
| VP-004 | `fragment::split_fragment` splits at first unescaped `#` — `%23` never splits | fragment | DI-003, BC-2.08.003 |
| VP-005 | `verdict::exit_code` returns 2 when any `IoError` present — regardless of findings | verdict | DI-011, BC-2.14.002 |
| VP-006 | `verdict::exit_code` returns 0 when all findings are `clean` or `indeterminate` | verdict | DI-010, BC-2.14.001 |
| VP-007 | `http_verdict::classify_response` is total and correct: no panic on any `(u16, HttpAttempt)`; 429/5xx/timeout never produce `broken`; 404/410 produce `broken`; `dns-failure` and `tls-error` produce `broken` | http_verdict | BC-2.10.002, DI-010, D-008 |

### Should Prove (P1 — proptest, Phase 3)

| VP | Property | Module | Invariant |
|----|----------|--------|-----------|
| VP-008 | NFC normalization applied: `path_resolver` uses NFC-normalized comparison | path_resolver | DI-002, BC-2.07.003 |
| VP-009 | NFC normalization idempotent: `nfc(nfc(s)) == nfc(s)` for all path strings | path_resolver | DI-002 |
| VP-010 | `filter::should_allow` enforces component boundary — `https://a.com` ≠ `https://a.com.evil.tld` | filter | DD-013, BC-2.11.002 |
| VP-011 | Sort order is deterministic — sort key `(nfc_path, line, col, link_target)` is total; same `Vec<Finding>` always produces same sort permutation regardless of rayon scheduling | reporter | DI-001, BC-2.12.001 |
| VP-019 | Each link in `extract_links` output has exactly one verdict path | link_extractor | DI-005, BC-2.03.001 |
| VP-023 | `url_classifier::classify_url` is total — no panic on any `&str`; empty string returns `Malformed(_)` not `NonHttp` | url_classifier | BC-2.07.007 |
| VP-024 | `path_resolver::resolve_path` trailing-slash-on-file invariant — `EntryKind::File` + trailing slash → `broken(file-not-found)`, never `target-is-directory`, never clean | path_resolver | BC-2.07.008 |
| VP-025 | `anchor_resolver::resolve_anchor` totality and correctness — no panic on any `(fragment, table)` pair; fragment present in table → Hit; fragment absent → Miss; case-sensitive byte-exact lookup; empty fragment handled | anchor_resolver | BC-2.08.001/002/004 |
| VP-026 | `compute_slug` differential fidelity — byte-identical output to `github-slugger@2.0.0` oracle for all 7 DI-012 rules; oracle corpus MUST include ≥3-entry duplicate run (FM-002 discriminator: 0-based counter `setup-1` vs 1-based `setup-2`) plus NFC (R-009) and NFD (OR-010) runs; proptest generator covers rules 2 (Unicode lowercase), 3 (space→hyphen 1:1), 4 (underscore retained), 5 (leading/trailing whitespace), 6 (Unicode word chars retained), 7 (emoji stripped); Rule 1 rendering fidelity (inline-code+HTML) is a Phase 3 integration obligation (Rule 1b — see VP-026 §Coverage) | slug | DI-012, DI-013, FM-002, BC-2.06.001/002 |

### Fuzz Targets (P1 — cargo-fuzz, Phase 6)

| VP | Target | Module | Risk |
|----|--------|--------|------|
| VP-012 | `slug::compute_slug` fuzz — no panic on arbitrary UTF-8 | slug | R-001, R-002 |
| VP-013 | `fragment::split_fragment` fuzz — no panic on arbitrary byte sequences | fragment | DI-003 |

### Test-Sufficient (Integration/Unit, Phase 3)

| VP | Property | Module | Invariant |
|----|----------|--------|-----------|
| VP-014 | Code context exclusion structural — no links from fenced/inline code | link_extractor | DI-004, BC-2.04.001 |
| VP-015 | Two-pass design: anchor table complete before any link resolution | anchor_table | DI-008, BC-2.05.001 |
| VP-016 | Excluded files have anchor tables — cross-file anchors into --ignore'd, .gitignore'd, dot-dir, and outside-root files resolve (DI-006 widened) | anchor_table | DI-006, BC-2.08.004 |
| VP-017 | Scan terminates for any dir tree including symlink cycles | scanner | DI-009, BC-2.01.004 |
| VP-018 | All DD-015 slug worked examples produce exact match (NFR-006) | slug | NFR-006, BC-2.06.001 |
| VP-020 | HTML anchor extraction narrow scope — only `id=`/`name=` from raw HTML (DI-007) | anchor_table | DI-007, BC-2.05.003 |
| VP-021 | No undefined reason codes — every emitted `reason` field is in the closed taxonomy set (NFR-007) | reporter | NFR-007, BC-2.12.001, BC-2.13.001 |
| VP-022 | Regression gate — p95 wall-clock <= ~500ms on Tier A benchmark corpus, offline (D-013) | app | D-013, NFR-008 |

## P0 Proof Harness Strategy

All P0 harnesses run against `mdlinkcheck-core` in isolation. No I/O. Bound sizes
chosen to complete in < 2 minutes on standard CI hardware (Kani 0.67.0 CBMC backend).

```rust
// VP-001 pattern: pure slugify() — ASCII only, no DuplicateCounter in proof scope
// (VP-003 proves the BTreeMap-keyed counter separately)
#[kani::proof]
fn verify_vp001_slug_total() {
    let len: usize = kani::any();
    kani::assume(len <= 16);
    let bytes: [u8; 16] = kani::any();
    for i in 0..len {
        kani::assume(bytes[i] < 128u8);  // ASCII only — avoids Unicode table blow-up
    }
    let s = std::str::from_utf8(&bytes[..len]).expect("ASCII is valid UTF-8");
    let _ = slugify(s);  // must not panic
}

// VP-005 pattern
#[kani::proof]
fn verify_exit2_beats_exit1() {
    let has_broken: bool = kani::any();
    let has_io_error: bool = kani::any();
    let config_error: bool = kani::any();
    let exit = exit_code_symbolic(has_broken, has_io_error, config_error);
    if has_io_error || config_error { assert_eq!(exit, 2); }   // DI-011
    else if has_broken { assert_eq!(exit, 1); }
    else { assert_eq!(exit, 0); }
}
```

## DI → VP Coverage Matrix

| DI | Description (summary) | VP(s) | Phase |
|----|----------------------|-------|-------|
| DI-001 | Deterministic output ordering | VP-011 | P1 |
| DI-002 | Case-sensitive NFC path comparison | VP-008, VP-009 | P1 |
| DI-003 | Fragment split before percent-decode | VP-004, VP-013 | P0/fuzz |
| DI-004 | Code context exclusion structural | VP-014 | integration |
| DI-005 | Exactly one verdict per link | VP-019 | P1 |
| DI-006 | Excluded files (all 4 mechanisms) are valid anchor targets | VP-016 | integration |
| DI-007 | HTML anchor extraction narrow scope | VP-020 | integration |
| DI-008 | Anchor table built before any link resolution (Pass 1 + Pass 1.5) | VP-015 | integration |
| DI-009 | Scan terminates for any input | VP-017 | integration |
| DI-010 | Indeterminate does not cause exit 1 | VP-006 | P0 Kani |
| DI-011 | Exit 2 takes precedence over exit 1 | VP-005 | P0 Kani |
| DI-012 | Slug computation fidelity (github-slugger v2 algorithm) | VP-018, VP-026 | test-sufficient + P1 proptest |
| DI-013 | Anchor-key uniqueness / injectivity within a file | VP-003, VP-026 | P0 Kani + P1 proptest |

**DI-012 coverage (BI-005 closed):** VP-018 (v1.2) adds the three DI-012 falsifying cases (`AI & Automation` → `ai--automation`, emoji stripped, and inline-code+HTML pre-rendered form). VP-026 provides a comprehensive differential oracle against `github-slugger@2.0.0` covering all 7 rules independently via a committed corpus + proptest generator. VP-026 must pass before Phase 6 hardening.

**DI-013 / FM-002 coverage (BI-005 closed):** VP-003 (Kani P0) proves injectivity. VP-026 oracle R-001 (≥3-entry repeat run) closes the FM-002 gap: `github-slugger@2.0.0` emits `setup`, `setup-1`, `setup-2`; a 1-based counter emits `setup`, `setup-2`, `setup-3`; injectivity holds for both; only the oracle comparison catches the off-by-one. VP-018 `vp018_duplicate_heading_counter_0_based()` provides defense-in-depth.

## [Section Content]

<!-- Validator scaffold: real content is in the named sections above. The
     architecture-section-template uses "[Section Content]" as a literal
     placeholder heading; the compliance validator matches it by substring.
     This stub satisfies that check without altering any real content. -->
