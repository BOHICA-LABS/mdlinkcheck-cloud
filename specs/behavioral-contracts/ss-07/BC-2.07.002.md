---
document_type: behavioral-contract
level: L3
version: "1.0"
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
subsystem: "SS-07"
capability: "CAP-007"
lifecycle_status: active
introduced: v1.0.0
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.07.002: Root-Relative Link Resolution Using Git Repo Root

## Description
Link destinations starting with `/` (root-relative) are resolved from the git repository root,
determined by `git rev-parse --show-toplevel`. If the scan is not inside a git repo, the scan
root (the deepest common ancestor of all PATH arguments, or CWD for default scan) is used as
fallback.

## Preconditions
1. A link destination starts with `/` (root-relative).
2. A scan root has been determined.

## Postconditions
1. The resolved path = git_repo_root.join(destination.strip_prefix('/').unwrap()).
2. If no git repo is found, resolved path = scan_root.join(destination.strip_prefix('/').unwrap()).
3. The git repo root is determined once per run and cached; not re-computed per file.
4. The fragment portion is stripped before path resolution (DI-003).

## Invariants
1. Root-relative links always use the same root for all files in the run.
2. The fallback (scan root) is deterministic: deepest common ancestor of PATH args, or CWD.
3. `git rev-parse --show-toplevel` is run once at startup; if git is not in PATH, falls back silently.

## Edge Cases
| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-026 | `/docs/api.md` in a git repo | Resolved from `git rev-parse --show-toplevel` |
| EC-027 | `/docs/api.md` in a non-git directory | Resolved from scan root (CWD or PATH ancestor) |

## Canonical Test Vectors
| Destination | Context | Expected Resolution |
|------------|---------|---------------------|
| `/docs/api.md` | Git repo root = `/Users/user/project` | `/Users/user/project/docs/api.md` |
| `/docs/api.md` | No git repo; CWD = `/tmp/scan` | `/tmp/scan/docs/api.md` |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | Root-relative resolved from git root | integration test |
| test-sufficient | Fallback works in non-git directory | integration test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-007 ("Relative Path Resolution — root-relative links resolved from git root") per capabilities.md §CAP-007 |
| Capability Anchor Justification | CAP-007 ("Relative Path Resolution") per capabilities.md §CAP-007 |
| L2 Domain Invariants | DI-002, DI-003 |
| Brief Requirement | R5, AMB-017 |
