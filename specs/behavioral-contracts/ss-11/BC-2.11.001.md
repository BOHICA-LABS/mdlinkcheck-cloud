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
input-hash: "79b9564"
traces_to: .factory/specs/domain-spec/L2-INDEX.md
origin: greenfield
extracted_from: null
subsystem: "SS-11"
capability: "CAP-011"
lifecycle_status: active
introduced: v1.0.0
modified:
  - v1.3: "DI-006 four-mechanism note added to Invariants: --ignore is one of four source-exclusion mechanisms that share the DI-006 anchor-target carve-out property."
  - v1.5: "Fix 1 (POL-18 holdout boundary): EC-074 citation removed from edge-case table. The anchor-target carve-out property is stated in PC3 and Invariant 4; corpus-fixture holdout details remain hidden. EC-071..EC-073 provide sufficient visible edge coverage."
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
| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-071 | `--ignore 'vendor/**'` excludes all files under `vendor/` | Not scanned as sources |
| EC-072 | `--ignore '*.md'` excludes all .md files | No files scanned; exit 0 |
| EC-073 | `--ignore 'docs/a.md'` exact match | Only `docs/a.md` excluded |

## Canonical Test Vectors
| --ignore pattern | Files present | Expected |
|-----------------|--------------|---------|
| `vendor/**` | `vendor/lib.md` (broken link), `docs/a.md` (clean) | Exit 0; vendor not scanned |
| `*.md` | `README.md` (broken link) | Exit 0; all md ignored |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-016 | --ignore excludes source, not anchor target | integration test |
| VP-016 | globset dialect: ** crosses directories | unit test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-011 ("Apply --ignore glob patterns (globset dialect, source-only per DD-008) and --allow URL prefix exemptions") per capabilities.md §CAP-011 |
| Capability Anchor Justification | CAP-011 ("Filter Application") per capabilities.md §CAP-011 — --ignore is the primary filter mechanism |
| L2 Domain Invariants | DI-006 |
| Brief Requirement | R6, DD-008 |
