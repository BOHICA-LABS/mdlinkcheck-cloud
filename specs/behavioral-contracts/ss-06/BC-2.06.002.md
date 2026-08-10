---
document_type: behavioral-contract
level: L3
version: "1.5"
status: draft
producer: vsdd-factory:product-owner
timestamp: 2026-08-10T00:00:00Z
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
subsystem: "SS-06"
capability: "CAP-006"
lifecycle_status: active
introduced: v1.0.0
modified:
  - "v1.5: (BI-052 remediation P7-S7-001) VP-003 row 1 corrected. VP-003 proves injectivity (no two distinct inputs produce the same emitted slug in one file), not triple-collision case correctness. The triple-collision case expected outputs ('setup', 'setup-1', 'setup-1-1') are a correctness property verified by VP-026. VP-003 row 1 updated to state the injectivity property. VP-026 row added for triple-collision correctness."
  - "v1.4: (WS-4-B) Citation-authority repair: L2 Capability row — fabricated excerpt 'duplicate-heading suffix counters (the Setup x 2 + Setup 1 collision-bump case is explicitly in scope)' (invented paraphrase, not in capabilities.md) replaced with verbatim title 'Heading Slug Computation'; gloss moved outside quotes. Proof-method join: both VP-003 rows 'unit test' → 'kani'; VP-026 'differential oracle' → 'proptest' (all per VP-INDEX authority)."
  - "v1.3: (P4-007/C4-002) Corrected L2 Domain Invariants: DI-008 → DI-013. Added VP-026 to Verification Properties (C4-006)."
  - "v1.2: (INC-MAP) Architecture Module field added per bc-module-map.md (architect, Phase 1b)"
  - "v1.1: (F-009) restated PC1/PC2 as DD-015 key-containment semantics (not value semantics); corrected PC3 to restrict the canonical case to the specific document order where both ## Setup headings precede ## Setup 1; added Setup-1-first test vector and PC4"
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.06.002: github-slugger v2 Duplicate-Heading Counter with Collision Bump

## Description
When a heading produces a slug that has already been used in the same file, the 0-based duplicate
counter appends `-N` (N=1,2,3...) using a while-loop until the result is unique. The collision
bump rule: when `## Setup` appears twice AND `## Setup 1` also appears, the second `## Setup`
produces "setup-1" which collides with the slug for `## Setup 1`; thus `## Setup 1` gets
bumped to "setup-1-1".

## Preconditions
1. Slug computation (BC-2.06.001) has produced a raw slug.
2. A per-file `HashMap<String, u32>` (`occurrences`) tracks slugs already emitted in this file.
   The map is keyed on the computed slug string (not the heading text).

## Postconditions
1. **Key-absent case:** If `occurrences` does NOT contain `slug` as a key: emit `slug`
   unchanged; insert `occurrences[slug] = 1`.
2. **Key-present case (DD-015 containment loop):** If `occurrences` CONTAINS `slug` as a key:
   - `count := occurrences[slug]`
   - `result := "{slug}-{count}"`
   - while `occurrences` contains `result` as a key: `count += 1; result := "{slug}-{count}"`
   - emit `result`; set `occurrences[result] = 1`; set `occurrences[slug] = count + 1`
3. The canonical triple-heading collision case (**document order: both `## Setup` precede
   `## Setup 1`**) resolves as:
   - First `## Setup` → "setup" (key-absent)
   - Second `## Setup` → count=1, result="setup-1", "setup-1" not in occurrences → "setup-1"
   - `## Setup 1` → raw slug "setup-1", "setup-1" IS in occurrences (count=1), result="setup-1-1", not in occurrences → "setup-1-1"
4. When `## Setup 1` appears BEFORE both `## Setup` headings (**Setup-1-first order**):
   - `## Setup 1` → "setup-1" (key-absent)
   - First `## Setup` → "setup" (key-absent)
   - Second `## Setup` → count=1, result="setup-1", "setup-1" IS in occurrences → count=2, result="setup-2", not in occurrences → "setup-2"
   - Final slugs: ["setup-1", "setup", "setup-2"]

## Invariants
1. The counter is per-file; it resets for each new file.
2. The while-loop always terminates (unbounded counter, finite heading count).
3. Processing order is document order (top to bottom).

## Edge Cases
| EC | Description |
|----|-------------|
| EC-055 | `## Setup` × 2 |
| EC-056 | `## Setup` × 2 + `## Setup 1` |
| EC-057 | `## Setup` × 3 |
| EC-058 | `## A` × 4 |

## Canonical Test Vectors
| Headings (document order) | Slugs Produced | Category |
|--------------------------|----------------|----------|
| `## Setup`, `## Setup`, `## Setup 1` | "setup", "setup-1", "setup-1-1" | happy-path (canonical collision — Setup × 2 first) |
| `## Setup` × 3 | "setup", "setup-1", "setup-2" | edge-case |
| `## Setup 1`, `## Setup`, `## Setup` | "setup-1", "setup", "setup-2" | Setup-1-first (F-009) — order matters |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-003 | deduplicate is injective — for any sequence of headings in one file no two emitted slugs are identical | kani |
| VP-003 | Counter reset between files — per-file counter does not carry state across file boundaries | kani |
| VP-026 | Canonical triple-collision case (Setup x2 + Setup 1) produces correct slugs; duplicate-counter output matches github-slugger@2.0.0 oracle | proptest |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-006 ("Heading Slug Computation") per capabilities.md §CAP-006 — 0-based per-file duplicate disambiguation via while-loop counter (Setup × 2 + Setup 1 collision case) |
| Capability Anchor Justification | CAP-006 ("Heading Slug Computation") per capabilities.md §CAP-006 |
| L2 Domain Invariants | DI-013 (anchor-key uniqueness; 0-based duplicate counter) |
| Brief Requirement | R2b, DD-015 |
| Architecture Module | `slug.rs` (SS-06, pure core, CRITICAL tier) — ADR-008 (clean-room github-slugger v2 reimplementation — slug algorithm is the primary differentiator) |

## Related BCs
- BC-2.06.001 — composes with (base slug before counter)
