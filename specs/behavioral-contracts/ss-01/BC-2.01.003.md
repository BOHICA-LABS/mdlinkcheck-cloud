---
document_type: behavioral-contract
level: L3
version: "1.7"
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
  - v1.5: "Fix 1 (POL-18 holdout boundary): EC-074 citation removed from edge-case table. EC-074 is a corpus-fixture holdout; its generic behavior is already covered by Invariant 2, BC-2.08.004, and TV-152/EC-152. This BC's scope is .gitignore traversal (DI-006 case 2); the removed row incorrectly cited an --ignore scenario (DI-006 case 1)."
  - "v1.6: (INC-MAP) Architecture Module field filled per bc-module-map.md (architect, Phase 1b)"
  - "v1.7: (WS-4/POLICY-5) L2 Capability citation-fidelity repair — fabricated quoted excerpt replaced with verbatim CAP-001 heading 'File Discovery' per capabilities.md §CAP-001."
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.01.003: `.gitignore` and `.ignore` Exclusion During Traversal

## Description
During directory traversal, mdlinkcheck respects `.gitignore` files (and `.ignore` files) 
using the `ignore` crate's WalkBuilder. Files and directories matching ignore patterns are 
excluded from the scan set. This prevents `node_modules/`, `target/`, and similar large 
directories from blowing the R8 performance budget.

## Preconditions
1. Traversal is underway across a directory tree.
2. `.gitignore` and/or `.ignore` files may be present at any level of the tree.

## Postconditions
1. Every file that matches a pattern in any applicable `.gitignore` or `.ignore` file is excluded from the scan set.
2. Nested `.gitignore` files are respected (ignore crate handles this).
3. The global git ignore file (`~/.gitignore_global`, `core.excludesFile`) is respected when available.

## Invariants
1. A file excluded by `.gitignore` is NOT scanned as a link source.
2. A file excluded by `.gitignore` but referenced as an anchor link target still has its anchor table
   built (DI-006 case 2). This is one of four source-exclusion mechanisms sharing the same property;
   see also BC-2.01.004 (dot-dir, DI-006 case 3), BC-2.11.001 (--ignore, DI-006 case 1), and the
   scan-root boundary (DI-006 case 4). Pass 1.5 handles cases 2, 3, and 4 via AnchorIndex membership.
3. `--no-ignore-vcs` (not a planned flag in v1.0 — defer to architecture) would override this behavior; today the behavior is always-on.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-002 | `node_modules/**/*.md` (5000 files) |

## Canonical Test Vectors
| Input | Expected Output | Category |
|-------|----------------|----------|
| Repo with `node_modules/foo.md` containing broken link; `node_modules/` in `.gitignore` | Exit 0; no findings for node_modules | happy-path |
| Repo with `.gitignore: docs/secret.md`; `docs/secret.md` has broken link | Exit 0; no findings | edge-case |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-016 | Files matching .gitignore patterns are never in the scan set | integration test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-001 ("File Discovery") per capabilities.md §CAP-001 |
| Capability Anchor Justification | CAP-001 ("File Discovery") per capabilities.md §CAP-001 — .gitignore exclusion is a traversal constraint within CAP-001 |
| L2 Domain Invariants | DI-006, DI-009 |
| Brief Requirement | R1 (implied), AMB-003 |
| Architecture Module | `scanner.rs` (SS-01, effectful shell, HIGH tier) — ADR-005 (rayon traversal); note: VP-016 formal assignment is to `anchor_table` module (INC-MAP-004) |
| Stories | [filled by story-writer] |

## Related BCs
- BC-2.01.004 — composes with (dot-dir and symlink policy)
- BC-2.05.003 — related to (ignored source files still get anchor tables)
- BC-2.11.001 — related to (--ignore flag is a separate, explicit exclusion)
