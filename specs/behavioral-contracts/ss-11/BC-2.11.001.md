---
document_type: behavioral-contract
level: L3
version: "1.8"
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
subsystem: "SS-11"
capability: "CAP-011"
lifecycle_status: active
introduced: v1.0.0
modified:
  - v1.8: "(GATE-58/POL-14) VP-NNN column bare em-dash is non-conforming per POL-14; replaced with VP-NONE (D-078) — proof method is integration, so VP-NONE is accepted."
  - v1.7: "(BI-052 remediation P7-S11-001) VP-016 row 2 corrected: 'globset dialect: ** crosses directories' was attributed to VP-016 but VP-016 uses literal patterns and does not test globset wildcard semantics. Property has no current VP; integration test required in story. Row 2 changed to bare dash."
  - v1.6: "WS-4 Shard E: POLICY-5 repair — L2 Capability fabricated quote replaced with verbatim CAP-011 title ('Filter Application'); VP-016 row 2 proof method corrected to 'integration' (was 'unit test') per VP-INDEX authority."
  - v1.3: "DI-006 four-mechanism note added to Invariants: --ignore is one of four source-exclusion mechanisms that share the DI-006 anchor-target carve-out property."
  - v1.5: "Fix 1 (POL-18 holdout boundary): EC-074 citation removed from edge-case table. The anchor-target carve-out property is stated in PC3 and Invariant 4; corpus-fixture holdout details remain hidden. EC-071..EC-073 provide sufficient visible edge coverage."
  - "v1.1: (INC-MAP) Architecture Module field added per bc-module-map.md (architect, Phase 1b)"
  - "v1.2: (EC-collision) EC-072→EC-192 (EC-072 canonical owner is BC-2.08.002 / test-vectors.md TV-072); EC-073→EC-193 (EC-073 canonical owner is test-vectors.md TV-073)."
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.11.001: `--ignore` Glob Exclusion (Source Files Only)

## Description
The `--ignore <GLOB>` flag excludes files matching the glob pattern from being scanned as link
sources. It is applied during traversal (source-only per DD-008). The glob uses the `globset`
crate dialect. `**` crosses directory boundaries. The pattern is anchored at CWD.

## Preconditions
1. One or more `--ignore GLOB` flags are provided.
2. A file has been discovered via traversal.

## Postconditions
1. If the file's CWD-relative path matches any `--ignore` glob: the file is excluded as a source.
2. The file is NOT scanned for links.
3. The file's anchor table IS still built (DI-006, BC-2.05.001).
4. `--ignore` does NOT affect files passed as explicit PATH arguments. [AMB-108: --ignore wins over explicit PATH per interface-definitions.md §8]

## Invariants
1. `--ignore` is source-only. It has no effect on whether a file can be an anchor target.
2. Glob matching uses `globset 0.4.20` dialect: `*` does not cross `/`, `**` does.
3. The pattern is CWD-relative; it does not anchor to git root.
4. **DI-006 context:** `--ignore` is DI-006 case 1 — one of four source-exclusion mechanisms
   that share the property "excluded from scan set as link sources but remain valid anchor
   targets." The other three: `.gitignore` exclusion (BC-2.01.003, DI-006 case 2), dot-directory
   exclusion (BC-2.01.004, DI-006 case 3), and outside-scan-root links (DI-006 case 4). Pass 1
   traversal covers `--ignore`'d files (case 1); Pass 1.5 covers cases 2, 3, and 4 via
   AnchorIndex membership absence (BC-2.05.001).

## Edge Cases
| EC | Description |
|----|-------------|
| EC-071 | `--ignore 'vendor/**'` excludes all files under `vendor/` |
| EC-192 | `--ignore '*.md'` excludes all .md files |
| EC-193 | `--ignore 'docs/a.md'` exact match |

## Canonical Test Vectors
| --ignore pattern | Files present | Expected |
|-----------------|--------------|---------|
| `vendor/**` | `vendor/lib.md` (broken link), `docs/a.md` (clean) | Exit 0; vendor not scanned |
| `*.md` | `README.md` (broken link) | Exit 0; all md ignored |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-016 | --ignore excludes source, not anchor target | integration |
| VP-NONE | globset dialect: ** crosses directories — no current VP (VP-016 uses literal pattern); integration test required in story | integration |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-011 ("Filter Application") per capabilities.md §CAP-011 |
| Capability Anchor Justification | CAP-011 ("Filter Application") per capabilities.md §CAP-011 — --ignore is the primary filter mechanism |
| L2 Domain Invariants | DI-006 |
| Brief Requirement | R6, DD-008 |
| Architecture Module | `filter.rs` (SS-11, pure core, HIGH tier) primary; `scanner.rs` (SS-01, effectful, HIGH tier) secondary — applies glob patterns during traversal; `--ignore`'d files still have anchor tables built — ADR-005, ADR-007 |
