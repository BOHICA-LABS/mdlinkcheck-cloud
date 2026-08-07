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
input-hash: "07d983a"
traces_to: .factory/specs/domain-spec/L2-INDEX.md
origin: greenfield
extracted_from: null
subsystem: "SS-05"
capability: "CAP-005"
lifecycle_status: active
introduced: v1.0.0
modified:
  - "v1.1: (F-007) VP-TBD backfill from VP-INDEX v1.1"
  - "v1.2: (INC-MAP) Architecture Module field added per bc-module-map.md (architect, Phase 1b)"
  - "v1.3: (WS-4-B) Citation-authority repair: L2 Capability row — fabricated excerpt 'Build and cache a per-file anchor table from headings (slugged per github-slugger v2 with duplicate-suffix counters) and HTML id/name attributes' (invented paraphrase, not in capabilities.md) replaced with verbatim title 'Anchor Table Construction'; gloss moved outside quotes. Proof-method join: VP-018 'unit test (NFR-006)' → 'unit' (VP-INDEX authority)."
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.05.002: ATX and Setext Heading Extraction into Anchor Table

## Description
During Pass 1, all ATX headings (# through ######) and setext headings (underlined with = or -)
are extracted from each file and their github-slugger v2 slugs are computed and inserted into the
anchor table. The slug computation handles duplicate headings with the 0-based counter per
github-slugger v2 semantics.

## Preconditions
1. Pass 1 is in progress for a file.
2. The file has been parsed into an AST event stream (BC-2.02.001).

## Postconditions
1. Every ATX heading (`Tag::Heading`) in the file produces exactly one anchor table entry with its slug.
2. Every setext heading in the file produces exactly one anchor table entry.
3. Duplicate headings get suffixed slugs per github-slugger v2 counter semantics (BC-2.06.001).
4. Headings inside code blocks are NOT included (BC-2.04.003).

## Invariants
1. The anchor table is a HashMap from slug string to list of line numbers (for error messaging).
2. Slug computation is deterministic and follows github-slugger v2 exactly.
3. The lookup in Pass 2 is by slug string (not heading text).

## Edge Cases
| EC | Description |
|----|-------------|
| EC-050 | File with three `## Setup` headings |
| EC-051 | `# Hello World` |
| EC-052 | `## C++ API` |
| EC-053 | `## 日本語 heading` |

## Canonical Test Vectors
| Input | Expected Output | Category |
|-------|----------------|----------|
| `## Setup\n## Setup\n## Setup 1` | anchor table has "setup","setup-1","setup-1-1" | happy-path |
| `## C++ API` | anchor table has "c-api" | edge-case |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-018 | github-slugger v2 worked examples all pass | unit |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-005 ("Anchor Table Construction") per capabilities.md §CAP-005 — enumerates headings from AST and extracts HTML id/name attributes |
| Capability Anchor Justification | CAP-005 ("Anchor Table Construction") per capabilities.md §CAP-005 |
| L2 Domain Invariants | DI-008 |
| Brief Requirement | R5 |
| Architecture Module | `anchor_table.rs` (SS-05, pure core, CRITICAL tier) primary; `slug.rs` (SS-06, CRITICAL tier) secondary — ATX/Setext headings require slug computation to build anchor key — ADR-006 |

## Related BCs
- BC-2.06.001 — composes with (slug algorithm)
- BC-2.06.002 — composes with (duplicate suffix counters)
