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
subsystem: "SS-07"
capability: "CAP-007"
lifecycle_status: active
introduced: v1.0.0
modified:
  - "v1.3: (DirIndex-scope ruling) Precondition 2 clarified: 'exists on the filesystem and is a directory' is determined via EntryKind::Dir in DirIndex; Pass 1.5a ensures DirIndex is populated for all link destination types including directory links, so this routing decision is always available to path_resolver without I/O."
  - "v1.2: P2-M09 — replaced non-conforming EC-NEW-3 with registry-compliant EC-164"
  - "v1.1: corrected verdict for plain directory links (no fragment) from broken to clean, aligning with test-vectors TV-029/TV-030 and feasibility-review SF-002; added fragment-present case (broken/target-is-directory); added routing note that path_resolver.rs makes both decisions"
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.07.005: Destination-Is-Directory Verdict

## Description
When a relative link destination resolves to a path that exists on the filesystem but is a
directory, `path_resolver.rs` (SS-07) makes the verdict decision — NOT `anchor_resolver.rs`
(SS-08). The outcome depends on whether a fragment is present:

- **No fragment:** `clean`. Directories are valid navigation targets in documentation.
  (This is the expected behavior for `[x](docs/)` or `[x](docs)` style links — they refer to
  a directory and the directory exists.)
- **Fragment present:** `broken` with reason `target-is-directory`. Anchor lookup on a
  directory is impossible; `path_resolver.rs` short-circuits to broken so `anchor_resolver.rs`
  is never called.

`anchor_resolver.rs` (SS-08) is a sibling module of `path_resolver.rs` and MUST NOT be called
for directory targets. `path_resolver.rs` owns this routing decision.

## Preconditions
1. A link destination has been resolved to an absolute path.
2. The resolved path exists on the filesystem and is a directory (not a regular file). `path_resolver` determines this via `EntryKind::Dir` in `DirIndex`. Pass 1.5a populates `DirIndex` for every extracted link destination — including directory links — so this information is always present without additional I/O.

## Postconditions
1. If the link has **no fragment**: verdict is `clean`. The directory exists; this is a
   navigable link target.
2. If the link has **a fragment**: verdict is `broken`, reason `target-is-directory`. Anchor
   lookup is impossible on a directory. `anchor_resolver.rs` is not called.
3. In both cases, `anchor_resolver.rs` is NEVER called for a directory target.

## Invariants
1. `path_resolver.rs` is the sole decision point for directory targets (no-fragment and
   fragment cases alike). `anchor_resolver.rs` must not receive a directory target.
2. `target-is-directory` (broken) applies only to directory+fragment — not to plain directory
   links.
3. A plain directory link `[x](docs/)` where `docs/` exists is `clean` (EC-029, EC-030,
   TV-029, TV-030).

## Edge Cases
| EC | Description |
|----|-------------|
| EC-029 | `[x](docs/)` where `docs/` is a directory, no fragment |
| EC-030 | `[x](docs)` where `docs` is a directory (no trailing slash), no fragment |
| EC-164 | `[x](docs#section)` where `docs` is a directory, fragment present |

## Canonical Test Vectors
| Link Target | Filesystem State | Fragment | Expected Verdict |
|-------------|-----------------|---------|-----------------|
| `docs/` | `docs/` is a directory | none | clean |
| `docs` | `docs` is a directory | none | clean |
| `docs#section` | `docs` is a directory | `section` | broken (target-is-directory) |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | Plain directory link (no fragment) → clean | unit test |
| test-sufficient | Directory link with fragment → broken (target-is-directory) | unit test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-007 ("Relative Path Resolution") per capabilities.md §CAP-007 |
| Capability Anchor Justification | CAP-007 ("Relative Path Resolution") per capabilities.md §CAP-007 — routing the directory-target decision to path_resolver.rs is a path resolution responsibility |
| Brief Requirement | R5, AMB-024 |
| Architecture Module | `path_resolver.rs` (SS-07) — routing decision; `anchor_resolver.rs` (SS-08) never called for directory targets |

## Related BCs
- BC-2.07.001 — composes with (resolution produces the path that is then checked)
- BC-2.07.006 — sibling (non-Markdown file targets: same routing layer, analogous contract)
- BC-2.08.002 — depends on this (cross-file anchor resolution receives only validated .md file paths; directory+fragment case is handled here before BC-2.08.002 is called)
