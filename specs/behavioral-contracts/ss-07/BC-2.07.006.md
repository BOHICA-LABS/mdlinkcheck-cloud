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
introduced: v1.1.0
modified:
  - "v1.3: EC-NEW-1 and EC-NEW-2 allocated as EC-205 and EC-206; placeholders replaced with real IDs in Edge Cases table."
  - "v1.2: (WS-4/Shard-C) POLICY-5 citation repair: L2 Capability quoted string was fabricated paraphrase; corrected to verbatim section title 'Relative Path Resolution' per capabilities.md §CAP-007."
  - "v1.1: (DirIndex-scope ruling) Precondition 2 clarified: 'exists as a regular file' is determined via EntryKind::File in DirIndex; Pass 1.5a ensures DirIndex is populated for non-.md link destination parent dirs so this routing decision is always available to path_resolver without I/O. Fixed pre-existing Edge Cases table cell-count error (EC-NEW-1/2 had extra column)."
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.07.006: Non-Markdown Target — File Existence Check Only, Anchor Resolution Skipped

## Description
When a link destination (after fragment split per DI-003 and percent-decode) resolves to a file
whose extension is NOT `.md` or `.markdown` (case-insensitive), the link is checked for file
existence only. No anchor table lookup is attempted, regardless of whether a fragment component
is present. This routing decision is made by `path_resolver.rs` before any call to
`anchor_resolver.rs`, keeping the two modules decoupled per ADR-001.

This contract backs EC-072 and EC-073 and prevents false `anchor-not-found` verdicts on links
to code files, images, PDFs, or any other non-Markdown file.

## Preconditions
1. A link destination's path component has been resolved to an absolute filesystem path.
2. The resolved path exists as a regular file (or a file symlink that resolves to a regular file). `path_resolver` determines this via `EntryKind::File` (or `EntryKind::Symlink { dangling: false }`) in `DirIndex`. Pass 1.5a populates `DirIndex` for every extracted link destination — including non-.md files — so this routing decision is always available without additional I/O.
3. The file's extension is NOT exactly `.md` (case-sensitive). Files with extension `.MD`, `.Md`,
   `.markdown`, `.mdx`, or any other non-`.md` extension fall into this contract (D-012: only `.md`
   files receive anchor resolution; all others get existence-check only).

## Postconditions
1. Verdict: `clean`.
2. The fragment (if any) is silently ignored — no anchor table lookup is performed.
3. `anchor_resolver.rs` (SS-08) is never called for this link.
4. If the resolved path does NOT exist, verdict is `broken` with reason `file-not-found`
   (normal path-resolution behavior; this BC applies only when the file exists).

## Invariants
1. Anchor resolution (SS-08) is never invoked for non-Markdown file targets.
2. `path_resolver.rs` makes this routing decision. `anchor_resolver.rs` is a sibling module and
   must not be called for non-Markdown targets — calling it would create illegal sibling coupling
   (per ADR-001 purity boundary and module dependency order).
3. "Non-Markdown" is determined by file extension, not MIME type or file content.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-072 | `[x](notes.txt#section)` where `notes.txt` exists |
| EC-073 | `[x](src/main.rs#L42-L50)` where `src/main.rs` exists |
| EC-205 | `[x](assets/logo.png#anchor)` where `assets/logo.png` exists — clean (image file; fragment ignored) |
| EC-206 | `[x](scripts/build.sh)` where file does not exist — broken (file-not-found) |

## Canonical Test Vectors
| Link | Filesystem State | Expected Verdict | Notes |
|------|-----------------|-----------------|-------|
| `[x](notes.txt#section)` | `notes.txt` exists | clean | Fragment on .txt file silently ignored |
| `[x](src/main.rs#L42-L50)` | `src/main.rs` exists | clean | GitHub-style line-range anchor; no lookup |
| `[x](missing.py#L10)` | file does not exist | broken (file-not-found) | Normal file-not-found path |
| `[x](README.md#section)` | `README.md` exists with `## Section` | clean | .md extension: anchor resolution IS performed |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | Non-.md file targets never trigger anchor_resolver | unit test (routing verification) |
| test-sufficient | Fragment on non-.md file never produces anchor-not-found | unit test (EC-072, EC-073) |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-007 ("Relative Path Resolution") per capabilities.md §CAP-007 |
| Capability Anchor Justification | CAP-007 ("Relative Path Resolution") per capabilities.md §CAP-007 — routing the non-Markdown target decision to path_resolver.rs is a path resolution responsibility, not an anchor resolution responsibility |
| L2 Domain Invariants | — |
| Brief Requirement | R5, EC-072, EC-073 |
| Architecture Module | `path_resolver.rs` (SS-07) — routing decision only; `anchor_resolver.rs` (SS-08) never called |
| Stories | [filled by story-writer] |

## Related BCs
- BC-2.07.005 — sibling (handles directory targets; same routing layer)
- BC-2.08.001 — depends on this (anchor-only links bypass this BC; they always reference .md source file)
- BC-2.08.002 — depends on this (cross-file anchor links to non-.md targets are handled HERE, not in BC-2.08.002)
