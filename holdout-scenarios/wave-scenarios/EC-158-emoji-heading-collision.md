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
  - .factory/specs/behavioral-contracts/ss-06/BC-2.06.001.md
  - .factory/specs/behavioral-contracts/ss-06/BC-2.06.002.md
input-hash: "cb489bf"
traces_to: .factory/specs/prd.md
id: "HS-003"
category: "edge-case-combinations"
must_pass: "true"
priority: "must-pass"
epic_id: "TBD"
behavioral_contracts:
  - BC-2.06.001
  - BC-2.06.002
lifecycle_status: active
introduced: v1.5
last_evaluated: null
staleness_check: null
stale_reason: null
retired: null
assumption_source: null
risk_source: null
---

# Holdout Scenario: Emoji Heading × Collision Counter (EC-158)

> **WARNING:** This file is stored in `.factory/holdout-scenarios/` and must
> NEVER be shown to the implementer or test-writer agents. The information
> asymmetry between builder and evaluator is the core quality mechanism.

## Scenario

1. A file `doc.md` contains these headings in order: `## 🚀 Foo`, then `## Foo`.
2. Both headings slugify to `foo` after emoji-stripping and lowercasing.
3. The duplicate counter assigns `foo` to the first and `foo-1` to the second.
4. The file also contains links `[first](#foo)` and `[second](#foo-1)`.
5. The user runs `mdlinkcheck doc.md`.
6. Expected: exit 0 — both links resolve `clean`.

**Negative control:**

1. Same file, but the links are `[first](#foo)` and `[second](#foo)` (both targeting `foo`).
2. `#foo` resolves to the first heading. `#foo` again resolves to the same heading.
3. Expected: exit 0 — `#foo` appears twice and both resolve clean (same anchor, both valid).

**Failure probe:**

1. Same file, but `[third](#foo-2)` is added.
2. Only two headings exist (`## 🚀 Foo` → `foo`, `## Foo` → `foo-1`); there is no third occurrence.
3. Expected: exit 1 — `broken (anchor-not-found)` for `#foo-2`.

## Behavioral Contract Linkage

| BC ID | Clause Tested | Scenario Aspect |
|-------|--------------|-----------------|
| BC-2.06.001 | Postcondition 2 — emoji characters are stripped before slug computation | `## 🚀 Foo` → rendered text `Foo` → slug `foo` |
| BC-2.06.001 | Invariant 4 — emoji-strip runs BEFORE the collision counter | Both headings produce candidate slug `foo`; counter then bumps second to `foo-1` |
| BC-2.06.002 | Postcondition 1 — duplicate counter is keyed on computed slug, not heading text | The counter key is `foo` (after strip), not `🚀 Foo` vs `Foo` |
| BC-2.06.002 | Postcondition 2 — collision bump uses 0-based while loop | `foo` taken → `foo-1`; probe confirms `foo-2` does not exist with only 2 headings |

## Verification Approach

```bash
cat > /tmp/hs003.md <<'EOF'
# Document

## 🚀 Foo

First section.

## Foo

Second section.

[first](#foo)
[second](#foo-1)
[probe](#foo-2)
EOF

mdlinkcheck /tmp/hs003.md
# Expected: exit 1
# stdout: /tmp/hs003.md:13: broken (anchor-not-found) #foo-2
# (lines 11 and 12 — #foo and #foo-1 — are clean and not in stdout)

# Verify clean-only variant:
cat > /tmp/hs003b.md <<'EOF'
# Document

## 🚀 Foo

First section.

## Foo

Second section.

[first](#foo)
[second](#foo-1)
EOF

mdlinkcheck /tmp/hs003b.md
# Expected: exit 0, no stdout findings
```

## Evaluation Rubric

- **Functional correctness** (weight: 0.5): Clean variant exits 0; probe variant exits 1 with exactly one `anchor-not-found` for `#foo-2`.
- **Edge case handling** (weight: 0.3): `#foo` resolves to the emoji heading (first occurrence); `#foo-1` resolves to the plain heading (second occurrence). If emoji-strip runs after the collision counter, both headings get different keys and neither collision is detected, causing `#foo-1` to break.
- **Error quality** (weight: 0.1): The finding for `#foo-2` cites the correct line number and reason.
- **Performance** (weight: 0.05): Single-file scan; no measurable overhead.
- **Data integrity** (weight: 0.05): Exactly one finding in probe variant; zero in clean variant.

## Edge Conditions

- The visible tests (EC-047/TV-047, EC-048/TV-048) cover ASCII duplicate headings `## Setup` × 2/3. This scenario introduces an emoji before the text, which forces emoji-strip to run before the duplicate counter.
- The visible EC-049 holdout covers the `Foo/Foo/Foo-1` triple-collision (different ordering issue). This scenario tests whether emoji-strip and collision counting compose correctly, not the triple-collision disambiguation loop.
- If the implementation keys the collision counter on raw heading text (`🚀 Foo` ≠ `Foo`), no collision is detected and both get slug `foo`. Then `#foo-1` would be `broken (anchor-not-found)`.

## Failure Guidance

`HOLDOUT LOW: HS-003 (satisfaction: 0.XX) -- emoji heading slug does not collide with plain-text heading because emoji-strip does not run before the duplicate counter`

## Category: real-world-corpus

| Field | Description |
|-------|-------------|
| corpus_source | Synthetic fixture representative of changelogs and release notes using emoji section headers (`## 🚀 New Features`, `## 🐛 Bug Fixes`), common in GitHub-hosted projects |
| corpus_size | 1 file, ~15 lines |
| known_edge_cases | Emoji-strip × collision bump ordering; emoji U+1F680 (ROCKET) is multi-codepoint |
| false_positive_threshold | 0.0 — `#foo` and `#foo-1` must be exactly clean |
| false_negative_threshold | 0.0 — `#foo-2` must be exactly broken |
