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
  - .factory/specs/behavioral-contracts/ss-08/BC-2.08.002.md
  - .factory/specs/behavioral-contracts/ss-08/BC-2.08.003.md
input-hash: "9baf611"
traces_to: .factory/specs/prd.md
id: "HS-006"
category: "real-world-corpus"
must_pass: "true"
priority: "must-pass"
epic_id: "TBD"
behavioral_contracts:
  - BC-2.08.002
  - BC-2.08.003
lifecycle_status: active
introduced: v1.6
last_evaluated: null
staleness_check: null
stale_reason: null
retired: null
assumption_source: null
risk_source: null
---

# Holdout Scenario: Percent-Encoding × Fragment Split — `%23` in Destination (EC-167)

> **WARNING:** This file is stored in `.factory/holdout-scenarios/` and must
> NEVER be shown to the implementer or test-writer agents. The information
> asymmetry between builder and evaluator is the core quality mechanism.

## Scenario

DI-003 requires fragment splitting at the FIRST UNESCAPED `#`. A percent-encoded `#` (`%23`) in the destination must NOT trigger fragment splitting — the whole destination `path%23section` is treated as a path, not as `path` + fragment `section`.

This scenario tests three closely related links targeting a file named `archive.md` which contains `## C# Tutorial` (a heading containing a `#` character, which the slug algorithm strips: `c-tutorial`).

**Fixture:**

```markdown
# archive.md
## C# Tutorial
Content about C-sharp.

## C-Tutorial
Content about C tutorial.
```

Note: `## C# Tutorial` produces slug `c-tutorial` (hash stripped by github-slugger v2).
Note: `## C-Tutorial` also produces slug `c-tutorial` — collision! The first occurrence gets `c-tutorial`, the second gets `c-tutorial-1`.

```markdown
# index.md
[Link A](archive.md#c-tutorial)
[Link B](archive.md#c%23-tutorial)
[Link C](archive.md%23c-tutorial)
```

**Expected results:**

```bash
mkdir -p /tmp/hs006
printf "# Archive\n## C# Tutorial\nContent.\n\n## C-Tutorial\nMore.\n" > /tmp/hs006/archive.md
printf "[A](archive.md#c-tutorial)\n[B](archive.md#c%%23-tutorial)\n[C](archive.md%%23c-tutorial)\n" > /tmp/hs006/index.md
mdlinkcheck /tmp/hs006/
# Expected: exit 1
#
# Link A: archive.md#c-tutorial
#   Fragment = "c-tutorial" (no percent-encoding)
#   Matches slug of first "## C# Tutorial" → clean
#
# Link B: archive.md#c%23-tutorial
#   Split at unescaped # → fragment = "c%23-tutorial"
#   Percent-decode → "c#-tutorial"
#   Compare to slugs: "c-tutorial", "c-tutorial-1" → no match
#   Result: broken (anchor-not-found)
#
# Link C: archive.md%23c-tutorial
#   %23 is an ESCAPED #, so NO fragment split occurs
#   Entire string "archive.md%23c-tutorial" is treated as path
#   No file named "archive.md%23c-tutorial" exists → broken (file-not-found)
#
# stdout (2 findings):
#   index.md:2: archive.md#c%23-tutorial — anchor not found: #c%23-tutorial in archive.md
#   index.md:3: archive.md%23c-tutorial — file not found: archive.md%23c-tutorial
```

## Behavioral Contract Linkage

| BC ID | Clause Tested | Scenario Aspect |
|-------|--------------|-----------------|
| BC-2.08.003 | DI-003 — fragment split at first UNESCAPED `#`; `%23` does not trigger split | Link C: `%23` in path treated as literal, no fragment split → file-not-found |
| BC-2.08.002 | Percent-decode before slug comparison | Link B: `#c%23-tutorial` decoded to `#c#-tutorial`, compared to slugs → no match → anchor-not-found |

## Verification Approach

```bash
mkdir -p /tmp/hs006
printf "# Archive\n## C# Tutorial\nContent.\n\n## C-Tutorial\nMore.\n" > /tmp/hs006/archive.md
# Note: %% in shell printf produces literal %
printf "[A](archive.md#c-tutorial)\n[B](archive.md#c%%23-tutorial)\n[C](archive.md%%23c-tutorial)\n" > /tmp/hs006/index.md

mdlinkcheck /tmp/hs006/
# Assert: exit code is 1
# Assert: Link A (line 1) produces no finding
# Assert: Link B (line 2) produces broken(anchor-not-found)
# Assert: Link C (line 3) produces broken(file-not-found)
```

## Evaluation Rubric

- **Functional correctness** (weight: 0.5): Link A clean, Link B anchor-not-found, Link C file-not-found.
- **Edge case handling** (weight: 0.35): The critical distinction is between `#c%23-tutorial` (unescaped `#` triggers split, then `%23` in fragment decoded) vs `%23c-tutorial` (no split, whole string is path). Conflating these two is the primary failure mode.
- **Error quality** (weight: 0.1): Correct reason codes — `anchor-not-found` for B (proof that split happened and fragment was looked up), `file-not-found` for C (proof that no split happened and the path was checked).
- **Performance** (weight: 0.025): Runs within NFR-001 budget.
- **Data integrity** (weight: 0.025): No duplicate findings; exactly 2 findings.

## Edge Conditions

- The heading `## C# Tutorial` contains a literal `#` which is stripped by the slug algorithm, producing `c-tutorial` — the same slug as `## C-Tutorial`. The collision bump makes the second one `c-tutorial-1`. Neither `c#-tutorial` nor `c%23-tutorial` decode to a valid slug.
- A buggy implementation that does not percent-decode `%23` before slug comparison might treat `%23` as a literal character, incorrectly matching some invented anchor.
- A buggy implementation that applies fragment splitting to `%23` would incorrectly split `archive.md%23c-tutorial` into path=`archive.md` and fragment=`c-tutorial`, producing `clean` instead of `file-not-found`.

## Failure Guidance

`HOLDOUT LOW: HS-006 (satisfaction: 0.XX) -- fragment split is not DI-003 compliant: %23 triggers split incorrectly, or percent-decode not applied before anchor comparison`

## Category: real-world-corpus

Documentation generators and wikis occasionally produce links with percent-encoded characters in fragment identifiers or paths — for example, MediaWiki encodes `#` as `%23` in certain contexts, and documentation containing C# code references may produce headings like `## C# Tutorial`. This scenario uses a minimal synthetic corpus modeled on C# / programming language documentation.

| Field | Description |
|-------|-------------|
| corpus_source | Synthetic corpus modeled on C# programming documentation with special-character headings |
| corpus_size | 2 files, ~6 lines each |
| known_edge_cases | `%23` in path (no split) vs `%23` in fragment (decoded but no match), collision-generated slug `c-tutorial` vs `c-tutorial-1` |
| false_positive_threshold | 0.0 — Link A must be clean |
| false_negative_threshold | 0.0 — Links B and C must each be broken with the correct reason code |
