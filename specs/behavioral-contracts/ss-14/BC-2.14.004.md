---
document_type: behavioral-contract
level: L3
version: "1.3"
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
subsystem: "SS-14"
capability: "CAP-014"
lifecycle_status: active
introduced: v1.3.0
modified: []
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

## Edge Cases
| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-NEW-14 | `mdlinkcheck --help` with no PATH | Exit 0; help text on stdout |
| EC-NEW-15 | `mdlinkcheck --version` | Exit 0; `mdlinkcheck X.Y.Z` on stdout |
| EC-NEW-16 | `mdlinkcheck . --version` (PATH + --version) | Exit 0; --version takes priority per clap |

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

## Related BCs
- BC-2.14.001 — sibling (exit 0 when no broken links found)
- BC-2.14.002 — sibling (exit 2 for configuration/usage errors)
