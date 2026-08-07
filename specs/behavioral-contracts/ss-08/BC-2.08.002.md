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
input-hash: "07d983a"
traces_to: .factory/specs/domain-spec/L2-INDEX.md
origin: greenfield
extracted_from: null
subsystem: "SS-08"
capability: "CAP-008"
lifecycle_status: active
introduced: v1.0.0
modified:
  - "v1.6: (WS-4/Shard-C) POLICY-5 citation repair: L2 Capability quoted string was fabricated description; corrected to verbatim section title 'Anchor Resolution' per capabilities.md §CAP-008; gloss moved outside quotes. VP-025 proof method corrected from 'Kani/proptest' to 'proptest' per VP-INDEX authority."
  - v1.3: "F-003 — added non-.md and directory carve-outs in PC3/PC4 pointing at BC-2.07.005 and BC-2.07.006. DI-006 widened: out-of-scan-set .md targets (gitignored, dot-dir, outside root, --ignored) are valid anchor targets. Removed holdout EC-074 citation."
  - "v1.4: (INC-MAP) Architecture Module field added per bc-module-map.md (architect, Phase 1b)"
  - "v1.5: (C4-006) VP-025 added to Verification Properties."
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.08.002: Cross-File Anchor Resolution (`path.md#fragment`)

## Description
Links of the form `path/to/file.md#fragment` require: (1) resolve the path component against the
source file's directory; (2) verify the target file exists (case-sensitive NFC); (3) look up the
fragment in the TARGET file's anchor table. Verdict priorities: `file-not-found` before
`anchor-not-found`.

**Scope of this BC:** This BC handles `.md` targets with a fragment. For non-`.md` targets
(regardless of fragment), see BC-2.07.006 (existence-check only; `anchor_resolver.rs` is never
called). For directory targets, see BC-2.07.005 (clean if no fragment; broken if fragment present).
For anchor-only links (`#fragment` with no path), see BC-2.08.001.

**DI-006 widening:** The target `.md` file may be outside the scan set (excluded by `--ignore`,
`.gitignore`, dot-directory policy, or scan-root boundary). In all four cases, Pass 1.5 ensures
its anchor table is built before Pass 2 resolves any link into it.

## Preconditions
1. A link has been classified as `cross-file-anchor` (path component + fragment, `.md` target).
2. The fragment has been split at the first unescaped `#` (DI-003).
3. The target file's anchor table has been built (Pass 1 or Pass 1.5 complete, DI-008).
   This holds even if the target file is outside the scan set — Pass 1.5 covers it.

## Postconditions
1. Path resolution follows BC-2.07.001 (relative) or BC-2.07.002 (root-relative).
2. If resolved path does not exist as a file or directory: broken (`file-not-found`).
3. If resolved path exists as a **directory**:
   - With fragment: broken (`target-is-directory`) — per BC-2.07.005.
   - Without fragment: clean — per BC-2.07.005. `anchor_resolver.rs` is NOT called.
4. If resolved path exists as a **non-`.md` file** (any fragment): clean, fragment silently ignored —
   per BC-2.07.006. `anchor_resolver.rs` is NOT called for non-`.md` targets.
5. If resolved path exists as a **`.md` file** and the fragment is NOT in its anchor table:
   broken (`anchor-not-found`).
6. If resolved path exists as a **`.md` file** and the fragment IS in its anchor table: clean.
7. Empty fragment `path.md#` → clean (same as BC-2.08.001 for bare `#`).

## Invariants
1. Fragment split is BEFORE percent-decode (DI-003).
2. Target file's anchor table is fully built before any resolution (DI-008). For out-of-scan-set
   `.md` targets, this is guaranteed by Pass 1.5 (system-overview.md v1.2).
3. Out-of-scan-set `.md` files — excluded via any of the four DI-006 mechanisms (--ignore,
   .gitignore, dot-directory, outside root) — are valid anchor targets. Their absence from the
   scan set as link sources does not prevent them from being anchor targets (DI-006).
4. `anchor_resolver.rs` (SS-08) is ONLY called for `.md` file targets. Directory targets and
   non-`.md` file targets are handled by `path_resolver.rs` (SS-07) and never reach SS-08.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-063 | `[x](docs/api.md#overview)` where `docs/api.md` has `## Overview` |
| EC-064 | `[x](docs/api.md#nope)` where `docs/api.md` has no such heading |
| EC-072 | `[x](notes.txt#section)` where `notes.txt` exists |

## Canonical Test Vectors
| Source | Destination | Target File | Expected | Notes |
|--------|-------------|-------------|----------|-------|
| `a.md` | `b.md#intro` | `b.md` has `## Intro` | clean | Happy path |
| `a.md` | `b.md#intro` | `b.md` has no `## Intro` | broken (anchor-not-found) | Anchor missing |
| `a.md` | `missing.md#intro` | file doesn't exist | broken (file-not-found) | File missing |
| `a.md` | `notes.txt#section` | `notes.txt` exists | clean | Non-.md: BC-2.07.006 (not this BC) |
| `a.md` | `docs/#setup` | `docs/` is a directory | broken (target-is-directory) | Dir + fragment: BC-2.07.005 |
| `a.md` | `gitignored.md#section` | `gitignored.md` is .gitignore'd; has `## Section` | clean | DI-006 case 2: Pass 1.5 builds anchor table |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-015 | Anchor table complete before any cross-file resolution (two-pass + Pass 1.5) | integration |
| VP-016 | Out-of-scan-set .md targets remain valid anchor targets (DI-006) | integration |
| VP-025 | Anchor-resolver totality (every input resolves to Hit or non-panic outcome) | proptest |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-008 ("Anchor Resolution") per capabilities.md §CAP-008 — cross-file resolution uses target file's anchor table (DI-008) |
| Capability Anchor Justification | CAP-008 ("Anchor Resolution") per capabilities.md §CAP-008 |
| L2 Domain Invariants | DI-003, DI-006, DI-008 |
| Brief Requirement | R2b |
| Architecture Module | `anchor_resolver.rs` (SS-08, pure core, CRITICAL tier) — ADR-007 (two-layer verdict model) |

## Related BCs
- BC-2.07.005 — dependency (directory targets handled there; BC-2.08.002 defers to it)
- BC-2.07.006 — dependency (non-.md targets handled there; BC-2.08.002 defers to it)
- BC-2.08.001 — sibling (anchor-only links)
- BC-2.08.004 — composes with (cross-file anchor into --ignore'd source)
