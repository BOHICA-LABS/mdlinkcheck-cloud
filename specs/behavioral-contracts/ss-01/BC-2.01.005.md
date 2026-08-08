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
subsystem: "SS-01"
capability: "CAP-001"
lifecycle_status: active
introduced: v1.0.0
modified:
  - v1.3: "D-012 — extension matching is now .md only, case-sensitive. .MD, .markdown, .mdx are explicit non-goals. Retitled from 'Extension Matching (Case-Insensitive .md and .markdown)'."
  - "v1.4: (INC-MAP) Architecture Module field filled per bc-module-map.md (architect, Phase 1b)"
  - "v1.5: (WS-4/POLICY-5) L2 Capability citation-fidelity repair — fabricated quoted excerpt replaced with verbatim CAP-001 heading 'File Discovery' per capabilities.md §CAP-001."
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.01.005: Extension Matching — `.md` Only, Case-Sensitive

## Description
During traversal, only files with the exact extension `.md` (lowercase, case-sensitive) are
included in the scan set. `.MD`, `.Md`, `.markdown`, `.mdx`, and all other extensions are
explicit non-goals (D-012). Extension matching uses a case-sensitive byte comparison of the
final suffix after the last `.` in the filename. Explicit file arguments bypass extension
filtering entirely (see BC-2.01.002).

This decision is recorded as D-012 in the product brief. `.markdown` and `.MD` support would
require scope expansion beyond R1 and introduce ambiguity in anchor-target resolution.
The `ignore` crate's WalkBuilder is configured with a case-sensitive filter for the exact string `.md`.

## Preconditions
1. A file path is being evaluated for inclusion in the scan set.
2. The file was discovered via traversal (not passed as an explicit argument).

## Postconditions
1. Files with extension `.md` (exact lowercase match) are included.
2. Files with extension `.MD`, `.Md`, `.markdown`, `.mdx`, `.mdown`, `.mkd`, `.txt`, `.html`,
   and all other extensions are excluded.
3. Explicit file arguments are included regardless of extension (see BC-2.01.002).

## Invariants
1. Extension matching is case-sensitive byte comparison of the exact string `.md`.
2. `.markdown`, `.MD`, and `.mdx` are not Markdown files for this tool's purposes (D-012, explicit non-goals).
3. Files matched by extension but excluded by `.gitignore` are still excluded (BC-2.01.003 takes precedence).

## Edge Cases
| EC | Description |
|----|-------------|
| EC-005 | `README.MD` (uppercase extension) |
| EC-006a | `notes.markdown` |
| EC-006b | `notes.mdown` or `notes.mdx` |
| EC-007 | `notes.txt` passed explicitly |

## Canonical Test Vectors
| Input | Expected Output | Category |
|-------|----------------|----------|
| `README.MD` with broken link; traversal | Exit 0; not scanned (case-sensitive extension rejects .MD) | D-012 |
| `notes.mdx` with broken link; traversal | Exit 0; not scanned | D-012 |
| `notes.markdown` with broken link; traversal | Exit 0; not scanned (D-012 non-goal) | D-012 |
| `README.md` (lowercase) with broken link; traversal | Exit 1; finding | happy-path |
| `notes.txt` passed explicitly | (depends on links inside) | explicit-arg |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | Only exact .md files included; case-sensitive byte match | unit test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-001 ("File Discovery") per capabilities.md §CAP-001 — extension match is case-sensitive; .md only (D-012) |
| Capability Anchor Justification | CAP-001 ("File Discovery") per capabilities.md §CAP-001 |
| Brief Requirement | R1, D-012 |
| Architecture Module | `scanner.rs` (SS-01, effectful shell, HIGH tier) — ADR-005 (rayon traversal) |
| Stories | [filled by story-writer] |

## Related BCs
- BC-2.01.002 — related to (explicit file args bypass this filter)
