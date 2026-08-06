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

# BC-2.07.004: Percent-Encoding in File Path Destinations

## Description
File path destinations may contain percent-encoded characters (e.g., `My%20File.md` meaning
`My File.md`). The tool percent-decodes the path component (after fragment split per DI-003)
before performing directory-entry comparison. The fragment component is NOT percent-decoded before
slug comparison (DI-003).

## Preconditions
1. A relative-file link destination has been classified.
2. The destination contains `%XX` percent-encoding sequences in the path component.

## Postconditions
1. Fragment is split at first unescaped `#` BEFORE any decoding (DI-003).
2. The path component is percent-decoded before directory-entry comparison.
3. The decoded path is NFC-normalized (BC-2.07.003).
4. The fragment component is used verbatim (not decoded) as the anchor lookup key.

## Invariants
1. Fragment split ALWAYS precedes percent-decode. This is DI-003.
2. A `%23` in the path component is decoded to `#` before use; it does NOT become a fragment separator.
3. Invalid percent sequences (e.g., `%GG`) cause the link to be treated as malformed-url only for external URLs; for file paths they are passed through (not decoded) and likely produce file-not-found.

## Edge Cases
| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-033 | `[x](My%20File.md)` where file is `My File.md` | clean (decoded to `My File.md`) |
| EC-034 | `[x](path%23with-hash.md)` | path decoded to `path#with-hash.md` (not a fragment) |
| EC-035 | `[x](a%20b.md#section)` | path = `a b.md`; fragment = `section` (split before decode) |

## Canonical Test Vectors
| Destination | Split + Decode Result | Verdict |
|-------------|----------------------|---------|
| `My%20File.md` | path=`My File.md`, frag=none | existence check `My File.md` |
| `a%20b.md#section` | path=`a b.md`, frag=`section` | existence + anchor check |
| `path%23not-frag.md` | path=`path#not-frag.md`, frag=none | existence check literal `#` in filename |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-004 | Fragment split precedes percent-decode (trap T9) | unit test |
| VP-004 | %20 in path decoded to space | unit test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-007 ("Percent-encode awareness: decode path before comparison, fragment before anchor lookup, fragment split BEFORE decode") per capabilities.md §CAP-007 |
| Capability Anchor Justification | CAP-007 ("Relative Path Resolution") per capabilities.md §CAP-007 |
| L2 Domain Invariants | DI-002, DI-003 |
| Brief Requirement | R5, R6, T9 |
