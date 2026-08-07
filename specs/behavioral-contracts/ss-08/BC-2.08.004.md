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
subsystem: "SS-08"
capability: "CAP-008"
lifecycle_status: active
introduced: v1.0.0
modified:
  - "v1.6: (WS-4/Shard-C) POLICY-5 citation repair: L2 Capability quoted string was fabricated description; corrected to verbatim section title 'Anchor Resolution' per capabilities.md §CAP-008; gloss moved outside quotes. VP-016 proof method corrected from 'integration test' to 'integration'; VP-025 corrected from 'Kani/proptest' to 'proptest'; both per VP-INDEX authority."
  - v1.5: "Fix 1 (POL-18 holdout boundary): EC-074 citation removed from edge-case table. Replaced with EC-159/EC-160 generic vectors using distinct variable names so the corpus-fixture holdout details remain hidden. DI-006 invariant coverage is preserved by Description, Postconditions, Invariants, and Canonical Test Vectors."
  - "v1.1: (INC-MAP) Architecture Module field added per bc-module-map.md (architect, Phase 1b)"
  - "v1.2: (C4-006) VP-025 added to Verification Properties."
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.08.004: Cross-File Anchor Into Ignored-Source File

## Description
When a file is excluded as a LINK SOURCE via `--ignore` (it is not scanned for its own links),
it can still be the TARGET of a cross-file anchor from a non-ignored file. The anchor table for
the ignored file IS built during Pass 1 (DI-006). This means cross-file anchors into ignored
files can resolve correctly.

## Preconditions
1. File `b.md` is excluded as a source by `--ignore b.md`.
2. File `a.md` (not ignored) contains `[x](b.md#section)`.
3. `b.md` exists and has heading `## Section`.

## Postconditions
1. `b.md`'s anchor table is built during Pass 1 (not skipped because b.md is ignored as a source).
2. The link `[x](b.md#section)` in `a.md` resolves to `b.md`'s anchor table.
3. If `## Section` exists in `b.md`: clean.
4. If `## Section` does not exist in `b.md`: broken (anchor-not-found).

## Invariants
1. `--ignore` applies to source traversal ONLY. It never affects anchor table construction.
2. DI-006: The anchor table for ignored-source files is always built.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-159 | `--ignore b.md`; `a.md` has `[x](b.md#setup)`; `b.md` exists and has `## Setup` |
| EC-160 | `--ignore b.md`; `a.md` has `[x](b.md#missing)`; `b.md` exists but has no `## Missing` |

## Canonical Test Vectors
| Scenario | Expected |
|----------|---------|
| `a.md` has `[x](b.md#intro)`; `b.md` ignored as source but has `## Intro` | clean |
| `a.md` has `[x](b.md#nope)`; `b.md` ignored as source but has no `## Nope` | broken (anchor-not-found) |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-016 | Anchor tables built for --ignore'd sources | integration |
| VP-025 | Anchor-resolver totality (every input resolves to Hit or non-panic outcome) | proptest |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-008 ("Anchor Resolution") per capabilities.md §CAP-008 — anchor tables built for --ignore-excluded files so cross-file anchors into those files can still resolve (DI-006) |
| Capability Anchor Justification | CAP-008 ("Anchor Resolution") per capabilities.md §CAP-008 |
| L2 Domain Invariants | DI-006, DI-008 |
| Brief Requirement | R5, DD-008 |
| Architecture Module | `anchor_resolver.rs` (SS-08, pure core, CRITICAL tier) — ADR-007 (two-layer verdict model) |
