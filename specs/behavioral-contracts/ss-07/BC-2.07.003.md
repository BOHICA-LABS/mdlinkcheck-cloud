---
document_type: behavioral-contract
level: L3
version: "1.2"
status: draft
producer: vsdd-factory:product-owner
timestamp: 2026-08-05T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/specs/domain-spec/L2-INDEX.md
  - .factory/planning/brief-validation.md
  - .factory/planning/market-intelligence.md
input-hash: "c3e82ce"
traces_to: .factory/specs/domain-spec/L2-INDEX.md
origin: greenfield
extracted_from: null
subsystem: "SS-07"
capability: "CAP-007"
lifecycle_status: active
introduced: v1.0.0
modified:
  - "v1.1: (INC-MAP) Architecture Module field filled per bc-module-map.md (architect, Phase 1b)"
  - "v1.2: (EC-collision) EC-029→EC-186 (EC-029 canonical owner is BC-2.07.005); EC-030→EC-187 (NFC/NFD normalization case); EC-031→EC-188 (Unicode mixed-case case)."
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
entries using case-sensitive, NFC-normalized exact matching — on ALL platforms, including macOS
(which has a case-insensitive HFS+ default filesystem). This is DI-002: the tool never delegates
case-sensitivity to the OS filesystem layer.

## Preconditions
1. A path has been resolved (BC-2.07.001 or BC-2.07.002).
2. The resolved path's parent directory is readable.

## Postconditions
1. Both the resolved destination and all actual directory entries are NFC-normalized before comparison.
2. Comparison is byte-for-byte exact after NFC normalization (case-sensitive).
3. `README.md` → `readme.md` fails (different case, broken: file-not-found) even on macOS.
4. `café.md` (NFC U+00E9) linking to `cafe\u{301}.md` (NFD U+0065+U+0301): both sides normalize to NFC → the
   comparison succeeds → verdict `clean`. NFC normalization eliminates this false positive on all platforms.

## Invariants
1. The tool NEVER uses `std::path::Path::exists()` alone for the final match decision. It reads the actual directory entries and compares.
2. NFC normalization is applied to both sides: the link destination AND the directory entry names.
3. This behavior is identical on macOS, Linux, and Windows.

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
| VP-008 | Case mismatch always detected regardless of OS filesystem | integration test (macOS + Linux) |
| VP-009 | NFC-normalized comparison is applied | unit test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-007 ("NFC normalization and case-sensitive exact-match against directory entries — never delegate to OS filesystem") per capabilities.md §CAP-007 |
| Capability Anchor Justification | CAP-007 ("Relative Path Resolution") per capabilities.md §CAP-007 — NFC+case-sensitive comparison is the core correctness property of CAP-007 |
| L2 Domain Invariants | DI-002 |
| Brief Requirement | R2a |
| Architecture Module | `path_resolver.rs` (SS-07, pure core, CRITICAL tier) primary; `fragment.rs` (SS-07, pure core, CRITICAL tier) secondary — percent-encoding decoded before NFC comparison per DI-002 ordering requirement — ADR-006 |
