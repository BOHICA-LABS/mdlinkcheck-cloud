---
document_type: behavioral-contract
level: L3
version: "1.6"
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
subsystem: "SS-05"
capability: "CAP-005"
lifecycle_status: active
introduced: v1.0.0
modified:
  - v1.3: "Architect three-phase rewrite: Pass 1 → Pass 1.5 → Pass 2 (resolves PC1/PC4 circularity). Pass 1.5 identifies out-of-scan targets by AnchorIndex membership absence. Covers all four DI-006 exclusion cases. Removed holdout EC-049 and EC-074 citations."
  - v1.4: "P2-C05 — Added Pass 1.5 failure branch (PC2b): nonexistent or unreadable target path records no AnchorIndex entry, no IoError, no diagnostic; Pass 2 produces the ordinary broken verdict. Fixes unsatisfiable PC2 for missing-file targets. Fixed L2 Capability title (P2-m05)."
  - "v1.5: (INC-MAP) Architecture Module field added per bc-module-map.md (architect, Phase 1b)"
  - "v1.6: (EC-collision) EC-075→EC-195 (EC-075 canonical owner is BC-2.08.001 per test-vectors.md registry); EC-076→EC-196 (EC-076 canonical owner is BC-2.08.003 per test-vectors.md registry)."
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.05.001: Three-Phase Design — Full Anchor Table Before Any Resolution

## Description
mdlinkcheck uses a three-phase design to satisfy DI-008 (anchor table built before any
resolution) and DI-006 (excluded `.md` files remain valid anchor targets):

- **Pass 1** (parallel): builds anchor tables for ALL `.md` files reached by the WalkBuilder
  traversal (including `--ignore`'d files — DI-006 case 1). Also collects all extracted links
  into the LinkMap.
- **Pass 1.5** (sequential, bounded): identifies any `.md` link destination that is NOT a key
  in the AnchorIndex after Pass 1 (due to `.gitignore`, dot-directory, or outside-root exclusion —
  DI-006 cases 2, 3, 4), and builds anchor tables for those targets.
- **Pass 2** (parallel): resolves all links against the complete AnchorIndex and DirIndex.

**Bootstrapping-order invariant:** Pass 1 completes fully before Pass 1.5 begins; Pass 1.5
completes fully before Pass 2 begins. No link resolution occurs in Pass 1 or Pass 1.5. No anchor
table construction occurs in Pass 2.

## Preconditions
1. The scan set has been determined (all files to be scanned are known).
2. Pass 1 (anchor table construction) has not yet begun.

## Postconditions
1. **After Pass 1:** every `.md` file reachable by the WalkBuilder traversal (including
   `--ignore`'d files — DI-006 case 1) has a complete anchor table in AnchorIndex. The LinkMap
   contains all extracted links from scan-set files.
2. **After Pass 1.5 (success case):** every `.md` destination that appeared in the LinkMap but was ABSENT from
   AnchorIndex after Pass 1 (due to `.gitignore`, dot-directory, or outside-root exclusion —
   DI-006 cases 2, 3, 4) and that EXISTS as a readable regular file now has a complete anchor table in AnchorIndex.
   Pass 1.5 identifies these targets by AnchorIndex membership absence — it does NOT re-check individual exclusion
   mechanisms.

2b. **After Pass 1.5 (failure branch — missing/unreadable target):** If a Pass 1.5 target path does not
   exist, is not a regular file, or cannot be read: NO AnchorIndex entry is created, NO `IoError` is recorded,
   and NO diagnostic is emitted. Pass 2 then produces the ordinary `broken(file-not-found)`,
   `broken(broken-symlink)`, or `broken(target-is-directory)` verdict for any links pointing to it.
   **Only failures reading files that are IN the scan set contribute to `io_errors`** (and therefore exit 2).
   Out-of-scan-set target read failures are NOT I/O errors — they are simply missing/unresolvable link targets.
3. **After Pass 2:** every anchor link has been resolved against the pre-built AnchorIndex.
4. No link validation occurs during Pass 1 or Pass 1.5.
5. No anchor table construction occurs during Pass 2.

## Invariants
1. A file's anchor table is always fully populated before any cross-file anchor pointing to that
   file is resolved (DI-008). This holds for ALL files in the anchor-target universe, including
   out-of-scan-set files covered by DI-006.
2. The three phases are strictly sequenced; they do not interleave.
3. Pass 1.5 uses AnchorIndex membership as the single gate — not per-exclusion-mechanism
   re-checks. Any future exclusion mechanism automatically falls into Pass 1.5 scope without
   code changes.
4. **DI-006 coverage (all four exclusion mechanisms):**
   - Case 1 (`--ignore`): Pass 1 traverses and parses ALL files including `--ignore`'d ones;
     their anchor tables exist before Pass 2. Pass 2 skips them as link sources.
   - Case 2 (`.gitignore`/`.ignore`): Not discovered by Pass 1 traversal; absent from AnchorIndex.
     Pass 1.5 builds their tables.
   - Case 3 (dot-directory): Same as case 2 — absent from AnchorIndex; Pass 1.5 builds tables.
   - Case 4 (outside scan root): Same as case 2 — absent from AnchorIndex; Pass 1.5 builds tables.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-195 | `a.md` has `[x](b.md#intro)` and `b.md` has `## Intro` |
| EC-196 | `a.md` has `[x](b.md#intro)` but `b.md` has no such heading |

## Canonical Test Vectors
| Input | Expected Output | Category |
|-------|----------------|----------|
| `a.md` has `[x](b.md#intro)` and `b.md` has `## Intro` | Exit 0; clean | happy-path |
| `a.md` has `[x](b.md#intro)` but `b.md` has no such heading | Exit 1; anchor-not-found | anchor-miss |
| `a.md` has `[x](gitignored.md#section)`; `gitignored.md` is in `.gitignore`; has `## Section` | Exit 0; clean | DI-006 case 2 |
| `a.md` has `[x](.vitepress/api.md#section)`; `.vitepress/api.md` has `## Section` | Exit 0; clean | DI-006 case 3 |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-015 | Anchor table completeness before resolution (Pass 1 + Pass 1.5 before Pass 2) | integration |
| VP-016 | Out-of-scan-set .md files are valid anchor targets (all four DI-006 cases) | integration |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-005 ("Anchor Table Construction") per capabilities.md §CAP-005 |
| Capability Anchor Justification | CAP-005 ("Anchor Table Construction") per capabilities.md §CAP-005 — three-phase design IS the anchor table construction contract |
| L2 Domain Invariants | DI-006, DI-008 |
| Brief Requirement | R2b, BV-009 |
| Architecture Module | `anchor_table.rs` (SS-05, pure core, CRITICAL tier) primary; `app.rs` (MEDIUM tier) secondary — three-pass pipeline (app) ensures anchor_table is complete before any resolution — ADR-006 |

## Related BCs
- BC-2.05.002 — composes with (heading extraction into anchor table)
- BC-2.05.003 — composes with (HTML id/name extraction into anchor table)
- BC-2.08.001 — depends on (anchor resolution uses these pre-built tables)
