---
document_type: behavioral-contract
level: L3
version: "1.6"
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
subsystem: "SS-07"
capability: "CAP-007"
lifecycle_status: active
introduced: v1.0.0
modified:
  - "v1.6: (BI-052 remediation BI-053-B) VP table row 2 corrected: '%20 in path decoded to space' was attributed to VP-004 kani but the VP-004 Kani harness only proves split correctness (P1-P4). The decode-ordering property is verified by VP-004 P5 integration test (vp004_path_percent_decode_after_split). Row 2 proof method corrected from 'kani' to 'integration'."
  - "v1.5: (BI-053 follow-up) Undecodable-fragment boundary case specified: Invariant 3 extended to cover the fragment component — invalid percent sequences in the fragment (e.g., `%GG`) are passed through undecoded; raw fragment used for anchor lookup → anchor-not-found (symmetric with path-component pass-through rule; no new reason code: anchor-not-found is in the 13-code closed set). Test vector added. All five authoritative sources (DI-003, CAP-008, DEC-005, events.md, prd.md) are silent on this case; symmetry with existing path rule is the defensible default."
  - "v1.4: (BI-053/P7-S3-001) Fragment percent-decode inversion corrected: Description sentence 3 stated 'NOT percent-decoded before slug comparison (DI-003)' and Postcondition 4 stated 'verbatim (not decoded)'. Both inverted DI-003/CAP-008/events.md/DEC-005 — all five authoritative sources require the fragment to be percent-decoded after the split. Corrected Description and PC4 to require 'percent-decoded before anchor lookup (DI-003, CAP-008)'. Added test vector for percent-encoded fragment (DEC-005 scenario). Resolves P7-S3-001."
  - "v1.3: (WS-4/Shard-C) POLICY-5 citation repair: L2 Capability quoted string was fabricated percent-encode description; corrected to verbatim section title 'Relative Path Resolution' per capabilities.md §CAP-007; gloss moved outside quotes. VP-004 proof method corrected from 'unit test' to 'kani' per VP-INDEX authority."
  - "v1.1: (INC-MAP) Architecture Module field filled per bc-module-map.md (architect, Phase 1b)"
  - "v1.2: (EC-collision) EC-034→EC-189 (EC-034 canonical owner is BC-2.07.008 per test-vectors.md registry)."
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
before performing directory-entry comparison. The fragment component is also percent-decoded
before anchor lookup (DI-003, CAP-008).

## Preconditions
1. A relative-file link destination has been classified.
2. The destination contains `%XX` percent-encoding sequences in the path component.

## Postconditions
1. Fragment is split at first unescaped `#` BEFORE any decoding (DI-003).
2. The path component is percent-decoded before directory-entry comparison.
3. The decoded path is NFC-normalized (BC-2.07.003).
4. The fragment component is percent-decoded before anchor lookup (DI-003, CAP-008).

## Invariants
1. Fragment split ALWAYS precedes percent-decode. This is DI-003.
2. A `%23` in the path component is decoded to `#` before use; it does NOT become a fragment separator.
3. Invalid percent sequences (e.g., `%GG`) are handled as follows:
   - **External URLs:** the link is treated as `malformed-url` (broken, exit 1) — WHATWG parse fails.
   - **Path component:** passed through undecoded; used as-is in directory-entry lookup → likely produces `file-not-found`.
   - **Fragment component:** passed through undecoded; raw (undecoded) fragment used as-is for anchor-table lookup → produces `anchor-not-found` when no anchor key matches the raw string. Symmetric with path-component rule. No new reason code: `anchor-not-found` is in the 13-code closed set.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-033 | `[x](My%20File.md)` where file is `My File.md` |
| EC-189 | `[x](path%23with-hash.md)` |
| EC-035 | `[x](a%20b.md#section)` |

## Canonical Test Vectors
| Destination | Split + Decode Result | Verdict |
|-------------|----------------------|---------|
| `My%20File.md` | path=`My File.md`, frag=none | existence check `My File.md` |
| `a%20b.md#section` | path=`a b.md`, frag=`section` | existence + anchor check |
| `path%23not-frag.md` | path=`path#not-frag.md`, frag=none | existence check literal `#` in filename |
| `docs/guide.md#caf%C3%A9` | path=`docs/guide.md`, frag=`café` (decoded) | existence + anchor check; decoded fragment matches slug `café` (DEC-005) |
| `file.md#caf%GG` | path=`file.md`, frag=`caf%GG` (raw — invalid sequence passed through) | anchor-not-found; raw fragment does not match any slug (Invariant 3 fragment rule) |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-004 | Fragment split precedes percent-decode (trap T9) | kani |
| VP-004 | %20 in path decoded to space — see VP-004 P5 decode-ordering integration test (vp004_path_percent_decode_after_split) | integration |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-007 ("Relative Path Resolution") per capabilities.md §CAP-007 — percent-encode awareness: decode path before comparison, fragment split BEFORE decode (DI-003) |
| Capability Anchor Justification | CAP-007 ("Relative Path Resolution") per capabilities.md §CAP-007 |
| L2 Domain Invariants | DI-002, DI-003 |
| Brief Requirement | R5, R6, T9 |
| Architecture Module | `fragment.rs` (SS-07, pure core, CRITICAL tier) primary; `path_resolver.rs` (SS-07) secondary — receives already-split, percent-preserved dest string — ADR-006 |
