---
document_type: behavioral-contract
level: L3
version: "1.5"
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
introduced: v1.0.0
modified:
  - "v1.5: (WS-4/Shard-C) POLICY-5 citation repair: L2 Capability quoted string was fabricated description; corrected to verbatim section title 'Relative Path Resolution' per capabilities.md §CAP-007; gloss moved outside quotes. VP-009 proof method corrected from 'unit test' to 'proptest' per VP-INDEX authority."
  - "v1.4: (DirIndex-scope ruling) Precondition 2 clarified: 'parent directory is readable' operationalized as 'present in DirIndex' — Pass 1.5a guarantees this for all link destination types. VP-008 proof method corrected: 'integration test (macOS only per D-043)' was wrong (D-043 edit changed platform scope, not proof method); corrected to 'proptest (macOS only per D-043)' matching VP-INDEX (authoritative) and vp-008 file."
  - "v1.3: (D-043) macOS-only platform directive: Description restated with canonical D-006 determinism rationale; Invariant 3 replaced with D-043 canonical wording; Postcondition 4 scoped to macOS; VP-008 proof method updated to macOS-only."
  - "v1.2: (EC-collision) EC-029→EC-186 (EC-029 canonical owner is BC-2.07.005); EC-030→EC-187 (NFC/NFD normalization case); EC-031→EC-188 (Unicode mixed-case case)."
  - "v1.1: (INC-MAP) Architecture Module field filled per bc-module-map.md (architect, Phase 1b)"
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.07.003: NFC Normalization and Case-Sensitive Exact Directory-Entry Comparison

## Description
After resolving a path, the resolved destination is compared against actual filesystem directory
entries using case-sensitive, NFC-normalized exact matching. Strict case-sensitive + NFC path
comparison is retained on determinism grounds, independent of the platform matrix. The tool must
produce byte-identical output for byte-identical repository content, and must not let macOS APFS
case-folding or Unicode normalization behaviour influence link verdicts. macOS APFS is
case-insensitive and stores filenames in NFD; adopting native filesystem semantics would make
verdicts a function of the filesystem rather than of the repository content, which would break
DI-001 determinism and NFR-003 reproducibility. This is DI-002 / D-006, retained on determinism
grounds per D-043 and not contingent on cross-platform parity.

## Preconditions
1. A path has been resolved (BC-2.07.001 or BC-2.07.002).
2. The resolved path's parent directory is present in `DirIndex`. In the pure-core model, `path_resolver` performs no I/O; "readable" is operationalized as "present in `DirIndex`." Pass 1.5a guarantees this for every extracted link destination — all link types (.md files already in the scan set, missing .md files, non-.md files, and directory references) — before Pass 2 begins.

## Postconditions
1. Both the resolved destination and all actual directory entries are NFC-normalized before comparison.
2. Comparison is byte-for-byte exact after NFC normalization (case-sensitive).
3. `README.md` → `readme.md` fails (different case, broken: file-not-found) even on macOS.
4. `café.md` (NFC U+00E9) linking to `cafe\u{301}.md` (NFD U+0065+U+0301): both sides normalize to NFC → the
   comparison succeeds → verdict `clean`. NFC normalization eliminates this false positive on macOS (where APFS
   stores filenames in NFD), ensuring verdicts depend on repository content rather than filesystem normalization.

## Invariants
1. The tool NEVER uses `std::path::Path::exists()` alone for the final match decision. It reads the actual directory entries and compares.
2. NFC normalization is applied to both sides: the link destination AND the directory entry names.
3. Strict case-sensitive + NFC path comparison is retained on determinism grounds, independent of the platform matrix. The tool must produce byte-identical output for byte-identical repository content, and must not let the host filesystem's case-folding or Unicode normalization behaviour influence link verdicts. macOS APFS is case-insensitive and stores filenames in NFD; adopting native filesystem semantics would make verdicts a function of the filesystem rather than of the repository content, which would break DI-001 determinism and NFR-003 reproducibility. This holds on a macOS-only matrix and is not contingent on cross-platform parity. (D-043 canonical D-006 rationale)

## Edge Cases
| EC | Description |
|----|-------------|
| EC-186 | `[x](readme.md)` but file is `README.md` |
| EC-187 | NFC vs NFD normalization in filename |
| EC-188 | Unicode filename with uppercase/lowercase |

## Canonical Test Vectors
| Link Target | Actual Filename | Expected Verdict | Notes |
|-------------|-----------------|-----------------|-------|
| `readme.md` | `README.md` | broken (file-not-found) | Case mismatch — different case after NFC |
| `README.md` | `README.md` | clean | Exact match |
| `café.md` (NFC U+00E9) | `café.md` (NFC on disk) | clean | Already NFC; exact match |
| `cafe\u{301}.md` (NFD) | `café.md` (NFC U+00E9 on disk) | clean | NFD link normalizes to NFC → matches NFC disk entry |
| `café.md` (NFC U+00E9) | `cafe\u{301}.md` (NFD, macOS-created) | clean | NFC link; NFD disk entry normalizes to NFC → match (see TV-037) |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-008 | Case mismatch always detected on macOS (never delegated to APFS case-folding) | proptest (macOS only per D-043) |
| VP-009 | NFC-normalized comparison is applied | proptest |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-007 ("Relative Path Resolution") per capabilities.md §CAP-007 — NFC normalization and case-sensitive exact-match; never delegate to OS filesystem |
| Capability Anchor Justification | CAP-007 ("Relative Path Resolution") per capabilities.md §CAP-007 — NFC+case-sensitive comparison is the core correctness property of CAP-007 |
| L2 Domain Invariants | DI-002 |
| Brief Requirement | R2a |
| Architecture Module | `path_resolver.rs` (SS-07, pure core, CRITICAL tier) primary; `fragment.rs` (SS-07, pure core, CRITICAL tier) secondary — percent-encoding decoded before NFC comparison per DI-002 ordering requirement — ADR-006 |
