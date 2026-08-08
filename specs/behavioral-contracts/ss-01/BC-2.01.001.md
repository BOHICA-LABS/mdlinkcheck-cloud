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
  - "v1.1: P2-M10/REGRESSION-002 — removed .markdown extension (D-012: .md only, case-sensitive); removed --hidden flag reference and .git/ carve-out (D-011: dot-dir skip is unconditional, no flag overrides)"
  - "v1.2: (INC-MAP) Architecture Module field filled per bc-module-map.md (architect, Phase 1b)"
  - "v1.3: (WS-4/POLICY-5) L2 Capability citation-fidelity repair — fabricated quoted excerpt replaced with verbatim CAP-001 heading 'File Discovery' per capabilities.md §CAP-001."
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.01.001: Recursive `.md` Discovery with Default Scan Root

## Description
When invoked with no PATH arguments, mdlinkcheck discovers all `.md` files
(case-sensitive, exact extension match — `.markdown`, `.MD`, `.mdx` are explicit non-goals per D-012)
under the current working directory, recursively, respecting `.gitignore` exclusions.
This is R1's "default `.`" behavior.

## Preconditions
1. Tool is invoked as `mdlinkcheck` with no PATH arguments.
2. CWD is a readable directory.
3. Zero or more `.md` files exist at any depth under CWD.

## Postconditions
1. Every `.md` file reachable from CWD (subject to traversal rules in BC-2.01.003 and BC-2.01.004) is included in the scan set exactly once.
2. Files are not scanned more than once even if multiple traversal paths could reach them.
3. The scan completes (terminates) for any finite directory tree.

## Invariants
1. ALL dot-directories (including `.git/`) are unconditionally skipped — there is no `--hidden` flag to override this (D-011). `.md` files inside dot-directories remain valid anchor targets (DI-006 case 3). (DI-009)
2. `.gitignore` patterns are applied during traversal. (BC-2.01.003)
3. Symlinked directories are NOT followed. (BC-2.01.004, DI-009)

## Edge Cases
| EC | Description |
|----|-------------|
| EC-001 | CWD has no `.md` files at any depth |
| EC-004 | `.git/` contains files ending in `.md` |
| EC-008 | Directory symlink creating a cycle `a/b -> a` |

## Canonical Test Vectors
| Input | Expected Output | Category |
|-------|----------------|----------|
| `mdlinkcheck` in directory with `README.md` containing broken link | Exit 1; finding for README.md | happy-path |
| `mdlinkcheck` in empty directory | Exit 0; stderr: "No markdown files found." | edge-case |
| `mdlinkcheck` in directory with only `.gitignore`-excluded `.md` files | Exit 0; no findings | edge-case |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | Scan always terminates for finite inputs | proptest (bounded depth + symlink cycle) |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-001 ("File Discovery") per capabilities.md §CAP-001 |
| Capability Anchor Justification | CAP-001 ("File Discovery") per capabilities.md §CAP-001 — this BC defines the default-root discovery behavior that is the core of CAP-001 |
| L2 Domain Invariants | DI-009 |
| Brief Requirement | R1 |
| Architecture Module | `scanner.rs` (SS-01, effectful shell, HIGH tier) — ADR-005 (rayon traversal) |
| Stories | [filled by story-writer] |

## Related BCs
- BC-2.01.002 — depends on (explicit PATH overrides this default)
- BC-2.01.003 — composes with (.gitignore filter during traversal)
- BC-2.01.004 — composes with (dot-dir and symlink policy)
