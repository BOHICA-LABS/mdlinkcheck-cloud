---
document_type: behavioral-contract
level: L3
version: "1.8"
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
subsystem: "SS-14"
capability: "CAP-014"
lifecycle_status: active
introduced: v1.3.0
modified:
  - "v1.7: EC-NEW-14, EC-NEW-15, EC-NEW-16 allocated as EC-211, EC-212, EC-213; placeholders replaced with real IDs in Edge Cases table."
  - "v1.6: (exit-code ruling b.3) Added Invariant 4: clap intercepts --help/--version before app::run(); verdict::exit_code is never invoked; no DirIndex, AnchorIndex, Vec<Finding>, or Vec<IoError> is constructed."
  - "v1.5: (P4-016) Removed incorrect SS-11 subsystem label from cli.rs; removed fabricated ADR-007 parenthetical '(--help/--version are cli module concerns)' — ADR-007 does not contain that clause."
  - "v1.4: (INC-MAP) Architecture Module field added per bc-module-map.md (architect, Phase 1b)"
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.14.004: `--help` and `--version` Exit 0 Without Scanning

## Description
When the user passes `--help` or `--version` as the sole or primary flag, the tool prints the
requested information and exits 0 immediately, without performing any file traversal, link
extraction, or liveness checking. This is standard CLI behavior and is required for CI pipeline
compatibility — scripts that probe tool availability via `mdlinkcheck --version` must not
trigger false exits.

## Preconditions
1. `--help` or `--version` is present in the command-line arguments.

## Postconditions
1. **`--help`:** full usage text printed to stdout; exit 0.
2. **`--version`:** `mdlinkcheck <semver>` (one line) printed to stdout; exit 0.
3. No file traversal occurs.
4. No link scanning occurs.
5. Stderr is empty (no summary line is emitted — there are no results).

## Invariants
1. `--help` and `--version` always exit 0.
2. No scanning side-effects occur (no file I/O beyond the flag parse).
3. The version string matches the `version` field in `Cargo.toml`.
4. clap intercepts `--help`/`--version` before `app::run()` is called; `verdict::exit_code` is never invoked for these cases; no `DirIndex`, `AnchorIndex`, `Vec<Finding>`, or `Vec<IoError>` is ever constructed.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-211 | `mdlinkcheck --help` with no PATH → Exit 0; help text on stdout |
| EC-212 | `mdlinkcheck --version` → Exit 0; `mdlinkcheck X.Y.Z` on stdout |
| EC-213 | `mdlinkcheck . --version` (PATH + --version) → Exit 0; --version takes priority per clap |

## Canonical Test Vectors
| Command | Expected stdout | Expected exit |
|---------|----------------|---------------|
| `mdlinkcheck --help` | Full help text (contains "Usage:") | 0 |
| `mdlinkcheck --version` | `mdlinkcheck X.Y.Z` | 0 |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | --help exits 0 without scanning | integration test |
| test-sufficient | --version output matches Cargo.toml version | integration test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-014 ("Exit Code Determination") per capabilities.md §CAP-014 |
| Capability Anchor Justification | CAP-014 ("Exit Code Determination") per capabilities.md §CAP-014 — --help and --version are special exit-0 cases in the exit code determination subsystem |
| L2 Domain Invariants | — |
| Brief Requirement | R7, standard CLI conventions |
| Architecture Module | `cli.rs` (effectful shell, LOW tier) — ADR-007 |

## Related BCs
- BC-2.14.001 — sibling (exit 0 when no broken links found)
- BC-2.14.002 — sibling (exit 2 for configuration/usage errors)
