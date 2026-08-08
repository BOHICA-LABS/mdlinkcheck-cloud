---
document_type: behavioral-contract
level: L3
version: "1.4"
status: draft
producer: vsdd-factory:product-owner
timestamp: 2026-08-05T00:00:00Z
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
subsystem: "SS-01"
capability: "CAP-001"
lifecycle_status: active
introduced: v1.0.0
modified:
  - "v1.1: REGRESSION-002 — removed .markdown extension reference from PC1 (D-012: .md only, case-sensitive)"
  - "v1.2: (INC-MAP) Architecture Module field filled per bc-module-map.md (architect, Phase 1b)"
  - "v1.3: (WS-4/POLICY-5) L2 Capability citation-fidelity repair — fabricated quoted excerpt replaced with verbatim CAP-001 heading 'File Discovery' per capabilities.md §CAP-001."
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.01.002: Explicit PATH Arguments Override Default Root

## Description
When one or more PATH arguments are supplied, mdlinkcheck uses those paths as the scan roots 
instead of CWD. Files are accepted directly; directories are traversed recursively. A mix of 
files and directories is allowed. Overlapping paths are deduplicated.

## Preconditions
1. Tool is invoked with one or more PATH arguments.
2. Each PATH is a path string (may be file or directory, may or may not exist).

## Postconditions
1. For each PATH that is an existing directory: all `.md` files under it are included, subject to traversal rules (`.markdown`, `.MD`, `.mdx` excluded per D-012).
2. For each PATH that is an existing file: that file is included regardless of extension (explicit intent overrides extension filter, per AMB-006).
3. For each PATH that does not exist: exit code 2 is triggered; see BC-2.01.009.
4. A file that would be discovered by multiple overlapping PATHs is included exactly once.

## Invariants
1. Deduplication is by canonicalized real path (resolves `.`, `..`, symlinks to files).
2. Per-file deduplication is applied before scanning, not after.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-007 | `mdlinkcheck notes.txt` — non-md explicit arg |
| EC-010 | `mdlinkcheck . docs docs/a.md` (overlapping) |
| EC-012 | `mdlinkcheck /does/not/exist` |

## Canonical Test Vectors
| Input | Expected Output | Category |
|-------|----------------|----------|
| `mdlinkcheck docs/` where docs/ has 3 .md files, 1 with a broken link | Exit 1; 1 finding | happy-path |
| `mdlinkcheck README.md docs/` where README.md is also inside docs/ | Deduplicated: each file found once | edge-case |
| `mdlinkcheck notes.txt` where notes.txt has `[x](missing.md)` | Exit 1; 1 finding (explicit file parsed) | edge-case |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | Each canonical path appears in scan set at most once | unit test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-001 ("File Discovery") per capabilities.md §CAP-001 |
| Capability Anchor Justification | CAP-001 ("File Discovery") per capabilities.md §CAP-001 — this BC specifies the explicit-PATH variant of discovery |
| L2 Domain Invariants | DI-009 |
| Brief Requirement | R1 |
| Architecture Module | `scanner.rs` (SS-01, effectful shell, HIGH tier) — ADR-005 (rayon traversal) |
| Stories | [filled by story-writer] |

## Related BCs
- BC-2.01.001 — superseded by (explicit PATH overrides default root)
- BC-2.01.007 — composes with (path deduplication)
- BC-2.01.009 — composes with (nonexistent PATH → exit 2)
