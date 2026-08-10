---
document_type: behavioral-contract
level: L3
version: "1.5"
status: draft
producer: vsdd-factory:product-owner
timestamp: 2026-08-10T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/specs/domain-spec/L2-INDEX.md
  - .factory/planning/brief-validation.md
  - .factory/planning/market-intelligence.md
input-hash: "07d983a"
traces_to: .factory/specs/domain-spec/L2-INDEX.md
origin: greenfield
extracted_from: null
subsystem: "SS-07"
capability: "CAP-007"
lifecycle_status: active
introduced: v1.0.0
modified:
  - "v1.5: (EC-injectivity redo) EC-022 row description updated under disposition (b): BC scenario and registry EC-022 describe the same file-relative ../ resolution scenario; placeholder filenames aligned to registry (README.md/docs/a.md) to resolve SCENARIO-MISMATCH."
  - "v1.4: (GATE-58/POL-14) VP-NNN column bare em-dash is non-conforming per POL-14; replaced with VP-NONE (D-078) — proof method is integration, so VP-NONE is accepted."
  - "v1.3: (BI-052 remediation P7-S2-001/P7-S2-002) VP table corrected. Row 1 'Fragment stripped before path resolution' re-attributed from VP-008 (path resolution) to VP-004 (split_fragment kani proof that fragment is separated before any path operations). Row 2 '.. resolution is logical' has no current VP; VP-008 proptest verifies path resolution outcomes but does not specifically assert the filesystem-vs-logical distinction; row changed to bare dash with integration test note."
  - "v1.2: (WS-4/Shard-C) POLICY-5 citation repair: L2 Capability quoted string was fabricated paraphrase; corrected to verbatim section title 'Relative Path Resolution' per capabilities.md §CAP-007. VP-008 proof method corrected from 'unit test' to 'proptest' per VP-INDEX authority."
  - "v1.1: (INC-MAP) Architecture Module field added per bc-module-map.md (architect, Phase 1b)"
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.07.001: Relative Path Resolution Against Source File's Directory

## Description
Relative file link destinations are resolved by joining the source file's directory with the
destination path. The result is then canonicalized (resolves `.` and `..` segments). This is
standard URL/file reference semantics: `docs/a.md` + `../api/ref.md` = `api/ref.md` from repo root.

## Preconditions
1. A link destination has been classified as `relative-file` or `cross-file-anchor` (not `anchor-only`, `external-http`, or `non-http`).
2. The source file's absolute path is known.

## Postconditions
1. The resolved path = source_dir.join(destination_path).canonicalize_logical().
2. `..` segments are resolved logically (not filesystem — no readlink needed for `.`/`..`).
3. The fragment portion (`#anchor`) is stripped BEFORE path resolution (DI-003).
4. After path resolution, DI-002 case-sensitive NFC comparison is applied (BC-2.07.003).

## Invariants
1. Fragment is split at the first unescaped `#` BEFORE any path operations. (DI-003)
2. Path resolution is purely logical; no filesystem call is needed for `.`/`..` resolution.
3. The resolved path is then existence-checked using filesystem APIs.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-022 | `[x](../README.md)` in `docs/a.md`; README.md exists at root |
| EC-023 | `[x](./same-dir.md)` |
| EC-024 | `[x](sub/nested.md)` |
| EC-025 | `[x](../../above-root.md)` |

## Canonical Test Vectors
| Source | Destination | Expected Resolved | Verdict |
|--------|-------------|------------------|---------|
| `docs/guide.md` | `../api/ref.md` | `api/ref.md` | file existence check |
| `docs/guide.md` | `./same.md` | `docs/same.md` | file existence check |
| `docs/guide.md` | `../../escape.md` | path escapes root | broken (file-not-found) |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-004 | Fragment stripped at first unescaped # before path resolution (split_fragment totality and correctness — DI-003) | kani |
| VP-NONE | .. resolution is logical, not filesystem readlink — no current VP; integration test required in story | integration |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-007 ("Relative Path Resolution") per capabilities.md §CAP-007 |
| Capability Anchor Justification | CAP-007 ("Relative Path Resolution") per capabilities.md §CAP-007 |
| L2 Domain Invariants | DI-002, DI-003 |
| Brief Requirement | R5, R6, T7 |
| Architecture Module | `path_resolver.rs` (SS-07, pure core, CRITICAL tier) — ADR-006 (NFC strict path model) |

## Related BCs
- BC-2.07.002 — composes with (root-relative links use git root)
- BC-2.07.003 — composes with (NFC + case-sensitive comparison)
- BC-2.07.004 — composes with (percent-encoding in paths)
