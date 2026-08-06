---
document_type: holdout-scenario
level: ops
version: "1.0"
status: draft
producer: "vsdd-factory:product-owner"
timestamp: 2026-08-05T15:00:00Z
phase: 1a
inputs:
  - .factory/specs/prd.md
  - .factory/specs/behavioral-contracts/ss-01/BC-2.01.003.md
  - .factory/specs/behavioral-contracts/ss-05/BC-2.05.001.md
  - .factory/specs/behavioral-contracts/ss-08/BC-2.08.004.md
  - .factory/specs/behavioral-contracts/ss-11/BC-2.11.001.md
input-hash: "8d555bb"
traces_to: .factory/specs/prd.md
id: "HS-005"
category: "real-world-corpus"
must_pass: "true"
priority: "must-pass"
epic_id: "TBD"
behavioral_contracts:
  - BC-2.11.001
  - BC-2.05.001
  - BC-2.08.004
lifecycle_status: active
introduced: v1.6
last_evaluated: null
staleness_check: null
stale_reason: null
retired: null
assumption_source: null
risk_source: null
---

# Holdout Scenario: Source-Exclusion × Cross-File Anchor — Dual-Role File (EC-166)

> **WARNING:** This file is stored in `.factory/holdout-scenarios/` and must
> NEVER be shown to the implementer or test-writer agents. The information
> asymmetry between builder and evaluator is the core quality mechanism.

## Scenario

A file `api.md` plays two roles simultaneously:
- **Excluded as a link source** (via `--ignore api.md`) — its outbound links are not checked.
- **Valid as a link target** (per DI-006 case 1) — other files can link into it and find anchors.

The key question: does the implementation correctly handle a file that is BOTH ignored-as-source AND referenced-as-anchor-target?

**Fixture:**

```markdown
# index.md
[API Docs](api.md#getting-started)
[API Reference](api.md#reference)
## Overview
```

```markdown
# api.md
## Getting Started
Some content.

[Back to Index](index.md#overview)

## Reference
More content.
```

**Test 1 — anchor present:**
```bash
mkdir -p /tmp/hs005
printf "# Index\n[API Docs](api.md#getting-started)\n[Reference](api.md#reference)\n## Overview\n" > /tmp/hs005/index.md
printf "# API\n## Getting Started\nContent.\n[Back](index.md#overview)\n## Reference\nMore.\n" > /tmp/hs005/api.md
mdlinkcheck --ignore api.md /tmp/hs005/
# Expected: exit 0
# api.md's links NOT checked (ignored as source)
# index.md's links to api.md ARE checked (api.md is anchor target, not ignored as target)
# Both api.md#getting-started and api.md#reference resolve clean
```

**Test 2 — anchor absent (heading renamed):**
```bash
printf "# API\n## Setup\nContent.\n[Back](index.md#overview)\n## Reference\nMore.\n" > /tmp/hs005/api.md
mdlinkcheck --ignore api.md /tmp/hs005/
# Expected: exit 1
# stdout: index.md:2: api.md#getting-started — anchor not found: #getting-started in api.md
# api.md's link to index.md#overview is NOT reported (api.md excluded as source)
```

**Test 3 — verify api.md's own links are not reported:**
Run Test 2 output and confirm no finding with source file `api.md`. The exclusion must apply to `api.md` as a link source even when its anchor table IS being built.

## Behavioral Contract Linkage

| BC ID | Clause Tested | Scenario Aspect |
|-------|--------------|-----------------|
| BC-2.11.001 | PC3 — `--ignore` excludes file as link source only; does NOT exclude it as anchor target | `api.md`'s outbound link to `index.md#overview` not reported |
| BC-2.05.001 | Pass 1.5 — anchor table built for files not in Pass 1 scan set | `api.md` excluded from traversal but its anchor table built for cross-file resolution |
| BC-2.08.004 | Cross-file anchor resolves into excluded-source file | `index.md` → `api.md#getting-started` resolves against api.md's anchor table |

## Verification Approach

See test scripts above. Three assertions:
1. Test 1 exits 0 with no findings.
2. Test 2 exits 1 with exactly one finding: `index.md` source, `api.md#getting-started` target, reason `anchor-not-found`.
3. Test 2 stdout does NOT contain any line starting with `api.md:`.

## Evaluation Rubric

- **Functional correctness** (weight: 0.5): Test 1 exits 0; Test 2 exits 1 with exactly one finding from `index.md`.
- **Edge case handling** (weight: 0.3): Test 3 — no findings with source `api.md`; the exclusion of `api.md` as a source must not suppress findings from other files pointing INTO it.
- **Error quality** (weight: 0.1): The finding in Test 2 correctly cites `anchor-not-found` (not `file-not-found`), proving the anchor table was built.
- **Performance** (weight: 0.05): Runs within NFR-001 budget.
- **Data integrity** (weight: 0.05): No duplicate findings.

## Edge Conditions

- The `--ignore` pattern is a specific filename, not a glob pattern.
- The ignored file has outbound links that must NOT appear in output.
- The ignored file has headings that MUST be reachable as anchor targets from non-ignored files.
- If the implementation skips anchor-table building for `--ignore`d files entirely, Test 2 would produce `broken(file-not-found)` instead of `broken(anchor-not-found)` — the wrong reason code, indicating the anchor table was not built.

## Failure Guidance

`HOLDOUT LOW: HS-005 (satisfaction: 0.XX) -- --ignore'd file not serving as anchor target; anchor table not built for excluded source files`

## Category: real-world-corpus

Real-world repositories commonly exclude generated or vendored documentation via `--ignore` while still linking INTO those files from the main docs. For example, a monorepo might ignore `packages/*/CHANGELOG.md` as scan sources but still expect links like `[v2.0 changes](packages/core/CHANGELOG.md#v200)` to resolve. This scenario models that dual-role pattern with a minimal two-file corpus.

| Field | Description |
|-------|-------------|
| corpus_source | Synthetic corpus modeled on monorepo documentation patterns |
| corpus_size | 2 files, ~10 lines each |
| known_edge_cases | Dual-role file (ignored source + valid anchor target), anchor-present vs anchor-absent variants |
| false_positive_threshold | 0.0 — Test 1 must exit 0 exactly |
| false_negative_threshold | 0.0 — Test 2 must report exactly one finding with correct reason code |
