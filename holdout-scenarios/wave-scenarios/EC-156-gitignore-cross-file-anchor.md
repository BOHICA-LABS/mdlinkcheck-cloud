---
document_type: holdout-scenario
level: ops
version: "1.0"
status: draft
producer: "vsdd-factory:product-owner"
timestamp: 2026-08-05T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/prd.md
  - .factory/specs/behavioral-contracts/ss-01/BC-2.01.003.md
  - .factory/specs/behavioral-contracts/ss-08/BC-2.08.004.md
  - .factory/specs/behavioral-contracts/ss-05/BC-2.05.001.md
input-hash: "858b417"
traces_to: .factory/specs/prd.md
id: "HS-001"
category: "real-world-corpus"
must_pass: "true"
priority: "must-pass"
epic_id: "TBD"
behavioral_contracts:
  - BC-2.01.003
  - BC-2.05.001
  - BC-2.08.004
lifecycle_status: active
introduced: v1.5
last_evaluated: null
staleness_check: null
stale_reason: null
retired: null
assumption_source: null
risk_source: null
---

# Holdout Scenario: .gitignore Traversal Exclusion × Cross-File Anchor (EC-156)

> **WARNING:** This file is stored in `.factory/holdout-scenarios/` and must
> NEVER be shown to the implementer or test-writer agents. The information
> asymmetry between builder and evaluator is the core quality mechanism.

## Scenario

1. A repository has a root `.gitignore` containing `vendor/` (directory exclusion).
2. `docs/README.md` contains the link `[x](../vendor/lib.md#installation)`.
3. `vendor/lib.md` exists on disk and contains the heading `## Installation`.
4. The user runs `mdlinkcheck docs/`.
5. Expected: exit 0, no findings — the link resolves `clean` because Pass 1.5 builds
   the anchor table for `vendor/lib.md` even though it is excluded from traversal.

**Negative case (also tested):**

1. Same setup, but `## Installation` in `vendor/lib.md` has been renamed to `## Setup`.
2. The user runs `mdlinkcheck docs/`.
3. Expected: exit 1, one finding — `broken (anchor-not-found)` for `../vendor/lib.md#installation`.

## Behavioral Contract Linkage

| BC ID | Clause Tested | Scenario Aspect |
|-------|--------------|-----------------|
| BC-2.01.003 | Invariant 2 — .gitignore-excluded file remains a valid anchor target | Corpus `.gitignore` excludes `vendor/`; `vendor/lib.md` must still serve as anchor target |
| BC-2.05.001 | Pass 1.5 — anchor table built on demand for files absent from AnchorIndex | `vendor/lib.md` is not in the Pass 1 scan set; Pass 1.5 must build its table |
| BC-2.08.004 | Postcondition 1 — excluded-source file's anchor table is built | Cross-file anchor `[x](../vendor/lib.md#installation)` must resolve correctly |

## Verification Approach

```bash
# Fixture setup (corpus fixture — use real git repo with .gitignore)
mkdir -p /tmp/hs001/docs /tmp/hs001/vendor
cd /tmp/hs001
git init
echo "vendor/" > .gitignore
echo "[Installation Guide](../vendor/lib.md#installation)" > docs/README.md
printf "# Vendor Lib\n\n## Installation\n\nSetup steps here.\n" > vendor/lib.md

# Test 1: heading present → clean
mdlinkcheck docs/
# Expected: exit 0, empty stdout

# Test 2: heading absent → broken
sed -i 's/## Installation/## Setup/' vendor/lib.md
mdlinkcheck docs/
# Expected: exit 1
# stdout: docs/README.md:1: broken (anchor-not-found) ../vendor/lib.md#installation
```

## Evaluation Rubric

- **Functional correctness** (weight: 0.5): Test 1 exits 0 with no findings; Test 2 exits 1 with exactly one finding citing `anchor-not-found` for `../vendor/lib.md#installation`.
- **Edge case handling** (weight: 0.3): The `.gitignore` exclusion does NOT prevent anchor table construction — if it does, Test 1 fails with `file-not-found` instead of `clean`.
- **Error quality** (weight: 0.1): The finding in Test 2 cites the correct source file, line, and reason code.
- **Performance** (weight: 0.05): Runs within the NFR-001 500-file budget; no timeout.
- **Data integrity** (weight: 0.05): No duplicate findings; deterministic output order.

## Edge Conditions

- The `.gitignore` excludes a directory (`vendor/`), not a specific file. The link targets a file within that directory.
- The link crosses directories (`../vendor/lib.md` relative to `docs/README.md`).
- Pass 1.5 must handle nested directory exclusions, not just single-file exclusions.
- Negative case verifies the anchor table was actually read (not just file existence).

## Failure Guidance

`HOLDOUT LOW: HS-001 (satisfaction: 0.XX) -- .gitignore-excluded files are not being built as anchor targets; cross-file anchors into .gitignore'd directories produce wrong verdicts`

## Category: real-world-corpus

Real-world corpus scenarios test the product against actual, publicly available data from production systems.

| Field | Description |
|-------|-------------|
| corpus_source | Synthetic corpus modeled on Rust monorepo patterns (vendored deps in `vendor/`, gitignored) |
| corpus_size | 2 files, ~10 lines; representative of any repo with gitignored vendor docs |
| known_edge_cases | `.gitignore` directory pattern, cross-directory relative link, heading present/absent variants |
| false_positive_threshold | 0.0 — a `clean` verdict on Test 1 must be exact |
| false_negative_threshold | 0.0 — a `broken` finding on Test 2 must be exact |
