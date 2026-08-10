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
subsystem: "SS-08"
capability: "CAP-008"
lifecycle_status: active
introduced: v1.0.0
modified:
  - "v1.6: (BI-052 remediation P7-S4-001/BI-053-D) VP table corrected. Rows 1-2 cited VP-015 for same-file-table and case-mismatch. VP-025 vp025_case_sensitive_lookup explicitly tests case sensitivity; VP-025 totality covers the same-file table property. Both rows re-attributed to VP-025. VP-004 P6 row added for fragment percent-decode before anchor lookup (decode-ordering integration test)."
  - "v1.5: (BI-053 follow-up) Undecodable-fragment boundary case specified: Invariant 4 added — invalid percent sequences in the anchor-only fragment (e.g., `#caf%GG`) are passed through undecoded; raw fragment used for anchor-table lookup → anchor-not-found (symmetric with BC-2.07.004 Invariant 3 path-and-fragment pass-through rule; no new reason code: anchor-not-found is in the 13-code closed set). All five authoritative sources silent on this case. Test vector added."
  - "v1.4: (BI-053/P7-S4-002) Fragment percent-decode inversion corrected: PC1 stated 'verbatim (no additional decoding)' and Invariant 3 stated 'verbatim from source (not decoded)'. Both inverted DI-003/CAP-008/events.md/DEC-005/prd.md — all five authoritative sources require the fragment to be percent-decoded after the split. PC1 corrected to 'percent-decoded; no case-folding'. Invariant 3 rewritten to require decode before lookup. Added test vector for percent-encoded fragment (DEC-005 anchor-only scenario). Resolves P7-S4-002."
  - "v1.3: (WS-4/Shard-C) POLICY-5 citation repair: L2 Capability quoted string was fabricated description; corrected to verbatim section title 'Anchor Resolution' per capabilities.md §CAP-008; gloss moved outside quotes. VP-015 proof method corrected from 'unit test' to 'integration' per VP-INDEX authority. VP-025 proof method corrected from 'Kani/proptest' to 'proptest' per VP-INDEX authority."
  - "v1.1: (INC-MAP) Architecture Module field added per bc-module-map.md (architect, Phase 1b)"
  - "v1.2: (EC-collision) EC-060→EC-191 (EC-060 canonical owner is BC-2.08.001 corrected: was coliding with BC-2.06.001); EC-075→EC-194 (empty-anchor case; three-equivalent-forms case stays in test-vectors.md). (C4-006) VP-025 added to Verification Properties."
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.08.001: Anchor-Only Link Resolution (`#fragment`)

## Description
Links whose destination starts with `#` (anchor-only, referencing a heading in the same file)
are resolved against the source file's own anchor table. The fragment is extracted after the `#`
and looked up in the anchor table. If found, verdict is clean; if not, verdict is broken
(anchor-not-found).

## Preconditions
1. A link's destination starts with `#`.
2. The source file's anchor table has been fully built (Pass 1 complete).

## Postconditions
1. The fragment = destination.strip_prefix('#'), then percent-decoded. No case-folding applied (DI-003, CAP-008).
2. The fragment is looked up in the source file's own anchor table.
3. If found: clean.
4. If not found: broken (anchor-not-found).
5. Empty anchor `#` (bare hash): clean (conventionally means "top of page"; in scope per EC-194).

## Invariants
1. Anchor lookup is in the SOURCE file's table (not another file's table).
2. The lookup is verbatim slug comparison — the fragment must exactly match an anchor table entry.
3. Fragment percent-decode: the fragment (everything after `#`) is percent-decoded before anchor-table lookup (DI-003, CAP-008). No case-folding applied. For anchor-only links, the entire destination after `#` is the fragment.
4. Invalid percent sequences (e.g., `#caf%GG`): the fragment is passed through undecoded; the raw (undecoded) fragment is used for anchor-table lookup → produces `anchor-not-found` when no key matches. Symmetric with BC-2.07.004 Invariant 3 (path and fragment components both pass through on invalid sequences). `malformed-url` is NOT emitted — that code is scoped to external URLs only (error-taxonomy.md §2.3).

## Edge Cases
| EC | Description |
|----|-------------|
| EC-191 | `[x](#setup)` where `## Setup` exists |
| EC-061 | `[x](#Setup)` where `## Setup` exists |
| EC-062 | `[x](#no-such-anchor)` |
| EC-194 | `[x](#)` empty anchor |

## Canonical Test Vectors
| Input | Expected Verdict | Category |
|-------|----------------|----------|
| `## Setup\n[x](#setup)` | clean | happy-path |
| `## Setup\n[x](#Setup)` | broken (anchor-not-found) | edge-case |
| `[x](#)` empty anchor | clean | edge-case |
| `## Café\n[x](#caf%C3%A9)` | clean (decoded `café` matches slug `café`) | DEC-005 anchor-only: percent-encoded fragment decoded before lookup |
| `## Section\n[x](#caf%GG)` | broken (anchor-not-found) — invalid percent sequence `%GG` passed through; raw `caf%GG` does not match slug `section` (Invariant 4) | invalid-percent-sequence in fragment |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-025 | Anchor-only links resolved in same-file anchor table (totality: every input resolves without panic) | proptest |
| VP-025 | Case mismatch → anchor-not-found (vp025_case_sensitive_lookup) | proptest |
| VP-004 | Fragment percent-decoded before anchor lookup — see VP-004 P6 decode-ordering integration test (vp004_fragment_percent_decode_before_anchor_lookup) | integration |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-008 ("Anchor Resolution") per capabilities.md §CAP-008 — resolve anchor fragments by looking up the fragment in the pre-built anchor table |
| Capability Anchor Justification | CAP-008 ("Anchor Resolution") per capabilities.md §CAP-008 |
| L2 Domain Invariants | DI-003, DI-008 |
| Brief Requirement | R5, AMB-053 |
| Architecture Module | `anchor_resolver.rs` (SS-08, pure core, CRITICAL tier) — ADR-007 (two-layer verdict model) |
