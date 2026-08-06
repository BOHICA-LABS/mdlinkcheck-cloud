---
document_type: module-criticality
level: ops
version: "1.6"
status: draft
producer: architect
timestamp: 2026-08-06T00:00:00Z
phase: 1b
inputs:
  - .factory/specs/domain-spec/capabilities.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/verification-architecture.md
input-hash: "21a6ba4"
traces_to: .factory/specs/architecture/ARCH-INDEX.md
changelog:
  - version: "1.6"
    date: 2026-08-06
    change: "P4 remediation: (1) ARCH-INDEX:30 'two-pass' fixed to 'three-phase' (P4-003). (2) module-criticality.md four 'two-pass' occurrences updated to 'three-phase pipeline (Pass 1 → Pass 1.5 → Pass 2)' in Module Inventory and Module Classification tables (P4-003). (3) path_resolver description fixed: 'DirEntries' → 'DirIndex' (P4-027). (4) Section labels (v1.3) updated to (v1.5) (P4-033)."
  - version: "1.5"
    date: 2026-08-06
    change: "BI-005 spec-level closure: slug VP Count 5→6 (VP-026 proptest differential oracle added). Rationale updated to cite VP-026 and DI-012/DI-013 (replaces stale DI-003 reference — DI-003 is the fragment invariant; slug invariants are DI-012 and DI-013 per DD-027)."
  - version: "1.4"
    date: 2026-08-06
    change: "INC-MAP-001 closure: anchor_resolver VP Count 0→1 (VP-025 proptest totality+correctness)"
  - version: "1.3"
    date: 2026-08-05
    change: "REGRESSION-004 remediation: corrected VP counts to match VP-INDEX v1.2 actual catalog — url_classifier 0→1 (VP-023), path_resolver 2→3 (VP-024), reporter 1→2 (VP-021), app 0→1 (VP-022)"
  - version: "1.2"
    date: 2026-08-05
    change: "INC-008 remediation: upgraded link_extractor from HIGH to CRITICAL (missed-link = false negative; VCM CRITICAL view was correct); declared module-criticality.md as source of truth for tier conflicts; fixed types inventory to list DirIndex/DirEntryInfo/EntryKind instead of stale DirEntries; fixed http_verdict description to say 13 reason codes not 9"
  - version: "1.1"
    date: 2026-08-05
    change: "Previous revision"
  - version: "1.0"
    date: 2026-08-05
    change: "Initial draft"
---

# Module Criticality Classification: mdlinkcheck

## Tier Definitions

| Tier | Mutation Kill Rate Target | Description | Examples |
|------|--------------------------|-------------|----------|
| **CRITICAL** | >= 95% | Core business logic, security boundaries, data integrity | Slug algorithm, exit-code logic, verdict classification |
| **HIGH** | >= 90% | Important functionality with significant user impact | Link extraction, path resolution, filtering |
| **MEDIUM** | >= 80% | Supporting functionality, utilities | HTTP client, pipeline orchestration |
| **LOW** | >= 70% | Infrastructure, glue code, CLI surface | Arg parsing, entry point, shared types |

## Module Inventory

- **slug** — github-slugger v2 clean-room reimplementation; primary product differentiator (R-001, R-002)
- **fragment** — splits raw link destination at first unescaped `#`; handles percent-encoding correctly
- **anchor_table** — builds heading-slug anchor key set (HashSet<String>); three-phase timing ensures anchor keys exist before any link resolution (DI-008)
- **anchor_resolver** — looks up fragment in AnchorTable; produces anchor Verdict
- **link_extractor** — extracts links/images from pulldown-cmark event stream; structural code exclusion
- **path_resolver** — pure NFC case-sensitive file existence check against pre-read DirIndex
- **url_classifier** — classifies link destination as file-path / mailto / anchor / http / https
- **http_verdict** — classifies HTTP response code + attempt into three-verdict model
- **filter** — apply ignore glob patterns and --allow prefix matchers
- **reporter** — format Text and JSON output from sorted findings
- **verdict** — compute process exit code from findings and io_errors collections
- **scanner** — effectful: traverses directory via `ignore` crate, reads files, produces ParsedFile
- **http_client** — effectful: ureq HEAD/GET with per-host concurrency and timeout
- **app** — effectful: three-phase pipeline orchestration (Pass 1 → Pass 1.5 → Pass 2); also performs Pass 1.5 DirIndex construction for out-of-scan link targets; coordinates scanner and http_client
- **cli** — clap argument parsing; produces CliArgs struct (no business logic)
- **main** — entry point; minimal glue code
- **types** — shared data types: Link, Finding, Verdict, AnchorTable, DirIndex, DirEntryInfo, EntryKind

## Module Classification

| Module | Path | Tier | Rationale | Kill Rate Target | VP Count |
|--------|------|------|-----------|-----------------|----------|
| `slug` | `crates/mdlinkcheck-core/src/slug.rs` | CRITICAL | Primary differentiator (R-001, R-002); formal proofs VP-001..003; unit corpus VP-018; fuzz VP-012; differential oracle VP-026 (DI-012, DI-013) | >= 95% | 6 |
| `fragment` | `crates/mdlinkcheck-core/src/fragment.rs` | CRITICAL | Incorrect split produces wrong anchor lookups and silent mismatch bugs; VP-004, VP-013 | >= 95% | 2 |
| `verdict` | `crates/mdlinkcheck-core/src/verdict.rs` | CRITICAL | Incorrect exit code silently ignores broken links in CI (DI-010, DI-011); VP-005, VP-006 | >= 95% | 2 |
| `http_verdict` | `crates/mdlinkcheck-core/src/http_verdict.rs` | CRITICAL | Misclassifying alive as broken is a false positive; misclassifying broken as alive is silent failure; VP-007 | >= 95% | 1 |
| `anchor_table` | `crates/mdlinkcheck-core/src/anchor_table.rs` | CRITICAL | Incorrect anchor table causes false positives/negatives on all heading links; VP-015..016, VP-020 | >= 95% | 3 |
| `anchor_resolver` | `crates/mdlinkcheck-core/src/anchor_resolver.rs` | CRITICAL | Direct consumer of anchor_table; incorrect lookup produces wrong verdicts for all heading links; VP-025 (proptest totality+correctness) | >= 95% | 1 |
| `path_resolver` | `crates/mdlinkcheck-core/src/path_resolver.rs` | CRITICAL | Case-sensitive NFC comparison is the correctness anchor for all local file links (DI-002); VP-008, VP-009, VP-024 | >= 95% | 3 |
| `link_extractor` | `crates/mdlinkcheck-core/src/link_extractor.rs` | CRITICAL | Missed link extraction = false negative (silent failure); over-extraction from code = false positive; VP-014, VP-019 | >= 95% | 2 |
| `filter` | `crates/mdlinkcheck-core/src/filter.rs` | HIGH | Incorrect --ignore / --allow behavior silently suppresses findings; VP-010 | >= 90% | 1 |
| `reporter` | `crates/mdlinkcheck-core/src/reporter.rs` | HIGH | Output format correctness; sort determines VP-011 determinism guarantee; VP-011, VP-021 | >= 90% | 2 |
| `url_classifier` | `crates/mdlinkcheck-core/src/url_classifier.rs` | HIGH | Misclassifying URL kind routes links to wrong resolver path; VP-023 (proptest totality) | >= 90% | 1 |
| `scanner` | `crates/mdlinkcheck/src/scanner.rs` | HIGH | Scan termination and .gitignore compliance directly affect correctness (DI-009); VP-017 | >= 90% | 1 |
| `http_client` | `crates/mdlinkcheck/src/http_client.rs` | MEDIUM | Effectful; hermetically tested via httpmock; behavior governed by http_verdict (pure) | >= 80% | 0 |
| `app` | `crates/mdlinkcheck/src/app.rs` | MEDIUM | Three-phase pipeline orchestration (Pass 1 → Pass 1.5 → Pass 2); correctness verified by integration tests; VP-022 (regression gate) | >= 80% | 1 |
| `cli` | `crates/mdlinkcheck/src/cli.rs` | LOW | Argument parsing only; clap handles most validation; no business logic | >= 70% | 0 |
| `main` | `crates/mdlinkcheck/src/main.rs` | LOW | Thin glue; no business logic | >= 70% | 0 |
| `types` | `crates/mdlinkcheck-core/src/types.rs` | LOW | Shared data types; structural only; no executable logic to mutate | >= 70% | 0 |

## Per-Module Risk Assessment

| Module | Tier | Blast Radius | Security Sensitivity | Implementation Complexity | Test Priority |
|--------|------|-------------|---------------------|--------------------------|--------------|
| `slug` | CRITICAL | high | none | high (Unicode, special chars, dedup) | P0 |
| `fragment` | CRITICAL | high | none | medium (percent-encoding edge cases) | P0 |
| `verdict` | CRITICAL | high | none | low (enum + exit code) | P0 |
| `http_verdict` | CRITICAL | high | none | medium (13 reason codes, two-attempt model) | P0 |
| `anchor_table` | CRITICAL | high | none | high (HTML id/name, three-phase timing) | P0 |
| `anchor_resolver` | CRITICAL | high | none | low | P0 |
| `path_resolver` | CRITICAL | high | none | medium (NFC normalization, OsStr) | P0 |
| `link_extractor` | CRITICAL | high | none | medium (pulldown-cmark event stream) | P0 |
| `filter` | HIGH | medium | none | medium (glob patterns, URL prefix) | P1 |
| `reporter` | HIGH | medium | none | low | P1 |
| `url_classifier` | HIGH | medium | none | low | P1 |
| `scanner` | HIGH | medium | none | medium (ignore crate, symlink detection) | P1 |
| `http_client` | MEDIUM | medium | none | medium (ureq, per-host semaphore) | P2 |
| `app` | MEDIUM | medium | none | medium (three-phase pipeline orchestration (Pass 1 → Pass 1.5 → Pass 2)) | P2 |
| `cli` | LOW | low | none | low | P2 |
| `main` | LOW | low | none | low | P2 |
| `types` | LOW | low | none | low | P2 |

## Classification Summary

| Tier | Module Count | Percentage |
|------|-------------|------------|
| CRITICAL | 8 | 47% |
| HIGH | 4 | 24% |
| MEDIUM | 2 | 12% |
| LOW | 3 | 18% |
| **Total** | **17** | **100%** |

(Note: types.rs is counted in LOW; it contains no executable logic.)

**Source-of-truth declaration (INC-008):** This file is the authoritative source of truth for
module criticality tier assignments. In any conflict between this file and
`verification-coverage-matrix.md`, this file takes precedence. The VCM must be updated to
conform whenever this file changes.

## Dependency Graph — Build Order

```
types.rs  (no deps)
    ↓
slug.rs   fragment.rs   url_classifier.rs
    ↓           ↓
anchor_table.rs   anchor_resolver.rs   path_resolver.rs
    ↓
link_extractor.rs   filter.rs   http_verdict.rs   verdict.rs
    ↓
reporter.rs
    ↓
[effectful shell]
scanner.rs   http_client.rs
    ↓
app.rs
    ↓
cli.rs   main.rs
```

## Implementation Priority Order

1. **types** — shared data types; all modules depend on this
2. **slug** — primary differentiator; must be proven first (VP-001..003)
3. **fragment** — required by anchor_table and path_resolver
4. **url_classifier** — required by link_extractor
5. **anchor_table** — required by anchor_resolver
6. **anchor_resolver** — required by app (Pass 2)
7. **path_resolver** — required by app (Pass 2)
8. **link_extractor** — required by app (Pass 1)
9. **http_verdict** — required by http_client
10. **filter** — required by app
11. **verdict** — required by app and main
12. **reporter** — required by app
13. **scanner** — effectful; requires types and pure core
14. **http_client** — effectful; requires http_verdict
15. **app** — effectful; orchestrates everything
16. **cli** — requires app interface
17. **main** — depends on cli and app

## Cross-Cutting Concerns by Tier

| Concern | CRITICAL modules | HIGH modules | MEDIUM/LOW modules |
|---------|-----------------|-------------|-------------------|
| Error handling | All errors propagate as typed Result variants | Typed Result; no silent silencing | May use anyhow in effectful shell |
| Testing | Kani proofs + proptest + unit + fuzz | proptest + unit + integration | Integration + unit |
| Mutation testing | >= 95% kill rate; use cargo-mutants --strict | >= 90% kill rate | >= 80% / >= 70% |
| Code exclusions | No I/O; violations are CI failures | No I/O (pure modules) | I/O allowed (effectful only) |

**CRITICAL modules (v1.5):** slug, fragment, verdict, http_verdict, anchor_table, anchor_resolver, path_resolver, link_extractor
**HIGH modules (v1.5):** filter, reporter, url_classifier, scanner
