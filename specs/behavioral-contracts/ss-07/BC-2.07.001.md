---
document_type: behavioral-contract
level: L3
version: "1.1"
status: draft
producer: vsdd-factory:product-owner
timestamp: 2026-08-05T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/specs/domain-spec/L2-INDEX.md
  - .factory/planning/brief-validation.md
  - .factory/planning/market-intelligence.md
input-hash: "c3e82ce"
traces_to: .factory/specs/domain-spec/L2-INDEX.md
origin: greenfield
extracted_from: null
subsystem: "SS-07"
capability: "CAP-007"
lifecycle_status: active
introduced: v1.0.0
modified:
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
| EC-022 | `[x](../sibling.md)` in `docs/guide.md` |
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
| VP-008 | Fragment stripped before path resolution | unit test |
| VP-008 | .. resolution is logical, not filesystem readlink | unit test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-007 ("Resolve relative file destinations using source-file-directory-relative path joins, with NFC normalization and case-sensitive exact-match against directory entries") per capabilities.md §CAP-007 |
| Capability Anchor Justification | CAP-007 ("Relative Path Resolution") per capabilities.md §CAP-007 |
| L2 Domain Invariants | DI-002, DI-003 |
| Brief Requirement | R5, R6, T7 |
| Architecture Module | `path_resolver.rs` (SS-07, pure core, CRITICAL tier) — ADR-006 (NFC strict path model) |

## Related BCs
- BC-2.07.002 — composes with (root-relative links use git root)
- BC-2.07.003 — composes with (NFC + case-sensitive comparison)
- BC-2.07.004 — composes with (percent-encoding in paths)
