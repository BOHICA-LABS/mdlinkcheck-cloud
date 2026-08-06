---
document_type: behavioral-contract
level: L3
version: "1.3"
status: draft
producer: vsdd-factory:product-owner
timestamp: 2026-08-05T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/specs/domain-spec/L2-INDEX.md
  - .factory/planning/brief-validation.md
  - .factory/planning/market-intelligence.md
input-hash: "19b62d8"
traces_to: .factory/specs/domain-spec/L2-INDEX.md
origin: greenfield
extracted_from: null
subsystem: "SS-01"
capability: "CAP-001"
lifecycle_status: active
introduced: v1.0.0
modified:
  - v1.3: "D-011 — dot-directory skip is now UNCONDITIONAL; --hidden is a dropped non-goal. DI-006 carve-out added: dot-dir .md files remain valid anchor targets."
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.01.004: Dot-Directory Skip (Unconditional) and Directory-Symlink Non-Following

## Description
Directories whose names begin with `.` (dot-directories such as `.github/`, `.vitepress/`, `.git/`)
are **always** skipped during traversal. This is unconditional — there is no `--hidden` flag to
override it (`--hidden` is an explicit non-goal, D-011). Directory symlinks are never followed,
preventing infinite traversal loops. File symlinks (pointing to files) ARE followed.

**DI-006 carve-out (case 3):** `.md` files inside skipped dot-directories are excluded from the
scan set but remain valid anchor targets. If any in-scan-set link points to a `.md` file inside
a dot-directory, Pass 1.5 builds its anchor table before Pass 2 resolves the link (identified
by AnchorIndex membership absence, per system-overview.md v1.2).

## Preconditions
1. Traversal encounters a directory entry.

## Postconditions
1. If the entry is a directory starting with `.`: skip entirely (unconditional).
2. If the entry is a symlink pointing to a directory: skip (do not follow).
3. If the entry is a symlink pointing to a file: follow and include the target file if it matches extension rules.

## Invariants
1. ALL dot-directories are unconditionally excluded. No flag overrides this (D-011: `--hidden` is a non-goal).
2. Directory symlinks are never followed (DI-009 — prevents infinite cycles).
3. A `.md` file inside a dot-directory that is referenced as a cross-file anchor target still has
   its anchor table built (DI-006 case 3 — Pass 1.5 builds it via AnchorIndex membership check).

## Edge Cases
| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-003 | `.github/PULL_REQUEST_TEMPLATE.md` | Not scanned (dot-dir unconditionally skipped) |
| EC-004 | `.git/` directory | Not scanned (dot-dir) |
| EC-008 | Dir symlink creating cycle `a/b -> a` | Terminates (dir symlinks not followed) |
| EC-009 | Symlink `docs -> ../shared-docs` | Dir symlink not followed; no crash |

## Canonical Test Vectors
| Input | Expected Output | Category |
|-------|----------------|----------|
| `.github/PULL_REQUEST_TEMPLATE.md` has broken link | Exit 0; no findings (dot-dir unconditionally skipped) | happy-path |
| Dir symlink cycle in tree | Terminates normally | edge-case |
| `README.md` has `[x](.vitepress/api.md#section)`; `.vitepress/api.md` has `## Section` | Exit 0; clean (Pass 1.5 builds anchor table for dot-dir target per DI-006 case 3) | DI-006 case 3 |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-017 | Scan terminates for any directory tree with symlink cycles | integration |
| VP-016 | Dot-dir .md files remain valid anchor targets (DI-006 case 3) | integration |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-001 ("applying traversal constraints (dot-directory policy, .gitignore exclusion)") per capabilities.md §CAP-001 |
| Capability Anchor Justification | CAP-001 ("File Discovery") per capabilities.md §CAP-001 — dot-dir policy and symlink safety are traversal constraints |
| L2 Domain Invariants | DI-006, DI-009 |
| Brief Requirement | R1, AMB-002, AMB-007 |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |

## Related BCs
- BC-2.01.003 — composes with (.gitignore exclusion)
- BC-2.01.006 — related to (file symlink behavior)
