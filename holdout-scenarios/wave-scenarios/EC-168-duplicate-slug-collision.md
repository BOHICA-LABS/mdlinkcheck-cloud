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
  - .factory/specs/behavioral-contracts/ss-06/BC-2.06.001.md
  - .factory/specs/behavioral-contracts/ss-06/BC-2.06.002.md
input-hash: "334c0cf"
traces_to: .factory/specs/prd.md
id: "HS-007"
category: "real-world-corpus"
must_pass: "true"
priority: "must-pass"
epic_id: "TBD"
behavioral_contracts:
  - BC-2.06.001
  - BC-2.06.002
lifecycle_status: active
introduced: v1.6
last_evaluated: null
staleness_check: null
stale_reason: null
retired: null
assumption_source: null
risk_source: null
---

# Holdout Scenario: Duplicate-Slug Collision — Setext + ATX Mixed Heading Types (EC-168)

> **WARNING:** This file is stored in `.factory/holdout-scenarios/` and must
> NEVER be shown to the implementer or test-writer agents. The information
> asymmetry between builder and evaluator is the core quality mechanism.

## Scenario

The duplicate-slug collision counter is keyed on the COMPUTED SLUG, not on the heading text or heading type (ATX vs setext). This scenario tests that the counter correctly deduplicates slugs across mixed heading types — specifically an ATX H1 and a setext H2 that produce the same slug.

**Fixture (`spec.md`):**

```markdown
# Setup

First setup section content.

Setup
-----

Second setup section content.

## Setup

Third setup section content.
```

Slug computation:
- `# Setup` (ATX H1) → slug `setup` (first occurrence → counter: `setup` = 1) → stored as `setup`
- `Setup\n-----` (setext H2) → slug `setup` (already in counter → `setup` = 2) → stored as `setup-1`
- `## Setup` (ATX H2) → slug `setup` (already in counter → `setup` = 3) → stored as `setup-2`

**Fixture (`index.md`):**

```markdown
[First section](#setup)
[Second section](#setup-1)
[Third section](#setup-2)
[Nonexistent](#setup-3)
```

**Expected results (offline scan of both files):**

```bash
mkdir -p /tmp/hs007
cat > /tmp/hs007/spec.md << 'EOF'
# Setup

First setup section content.

Setup
-----

Second setup section content.

## Setup

Third setup section content.
EOF

cat > /tmp/hs007/index.md << 'EOF'
[First section](#setup)
[Second section](#setup-1)
[Third section](#setup-2)
[Nonexistent](#setup-3)
EOF

mdlinkcheck /tmp/hs007/
# Expected: exit 1
# Link 1 (#setup): clean — matches ATX H1 slug
# Link 2 (#setup-1): clean — matches setext H2 bumped slug
# Link 3 (#setup-2): clean — matches ATX H2 double-bumped slug
# Link 4 (#setup-3): broken (anchor-not-found) — no fourth "Setup" heading
#
# stdout (1 finding):
#   index.md:4: #setup-3 — anchor not found: #setup-3 in index.md
```

Note: Links 1–3 are within `index.md` itself. They reference `spec.md` anchors only if written as `[x](spec.md#setup)`. In this fixture, all four links are self-referential (same-file, no `spec.md` prefix), so `index.md` must also define the headings — or we use a separate file. Let me restructure:

**Revised fixture — all links in `index.md` reference `spec.md`:**

```markdown
# index.md
[First section](spec.md#setup)
[Second section](spec.md#setup-1)
[Third section](spec.md#setup-2)
[Nonexistent](spec.md#setup-3)
```

```bash
mkdir -p /tmp/hs007
cat > /tmp/hs007/spec.md << 'EOF'
# Setup

First content.

Setup
-----

Second content.

## Setup

Third content.
EOF

cat > /tmp/hs007/index.md << 'EOF'
[First](spec.md#setup)
[Second](spec.md#setup-1)
[Third](spec.md#setup-2)
[Nonexistent](spec.md#setup-3)
EOF

mdlinkcheck /tmp/hs007/
# Expected: exit 1
# spec.md#setup → clean
# spec.md#setup-1 → clean
# spec.md#setup-2 → clean
# spec.md#setup-3 → broken (anchor-not-found)
#
# stdout (1 finding):
#   index.md:4: spec.md#setup-3 — anchor not found: #setup-3 in spec.md
```

## Behavioral Contract Linkage

| BC ID | Clause Tested | Scenario Aspect |
|-------|--------------|-----------------|
| BC-2.06.001 | Slug computation for setext headings uses same algorithm as ATX headings | `Setup\n-----` (setext H2) produces slug `setup`, same as `# Setup` (ATX H1) |
| BC-2.06.002 | Duplicate counter is keyed on COMPUTED SLUG, not heading type | Counter increments for both ATX and setext headings sharing the same slug; setext H2 gets `setup-1`, subsequent ATX H2 gets `setup-2` |

## Verification Approach

```bash
mkdir -p /tmp/hs007
cat > /tmp/hs007/spec.md << 'EOF'
# Setup

First content.

Setup
-----

Second content.

## Setup

Third content.
EOF

cat > /tmp/hs007/index.md << 'EOF'
[First](spec.md#setup)
[Second](spec.md#setup-1)
[Third](spec.md#setup-2)
[Nonexistent](spec.md#setup-3)
EOF

mdlinkcheck /tmp/hs007/
# Assert exit code 1
# Assert: lines 1-3 of index.md produce no findings
# Assert: line 4 produces broken(anchor-not-found) for spec.md#setup-3
# Assert: exactly 1 finding in stdout
```

## Evaluation Rubric

- **Functional correctness** (weight: 0.5): `#setup`, `#setup-1`, `#setup-2` all resolve clean; `#setup-3` is anchor-not-found.
- **Edge case handling** (weight: 0.35): The setext heading must participate in the duplicate counter on equal footing with ATX headings. A buggy implementation that maintains separate counters per heading type (one for ATX, one for setext) would store the setext H2 as `setup` (first setext heading), incorrectly making `#setup-1` broken.
- **Error quality** (weight: 0.1): Exactly 1 finding, with correct reason `anchor-not-found` (not `file-not-found`), proving the anchor table was built and consulted.
- **Performance** (weight: 0.025): Runs within NFR-001 budget.
- **Data integrity** (weight: 0.025): No duplicate findings.

## Edge Conditions

- Three distinct heading types produce the same slug: ATX H1, setext H2 (underline `---`), ATX H2. All three must share the same collision counter namespace.
- This is distinct from EC-047/EC-048 (two ATX headings of the same level) and from EC-049 (three ATX headings, now burned to visible), and from the emoji collision pattern.
- A buggy implementation that resets the counter per heading level (e.g., separate counters for H1, H2) would produce `setup` for the ATX H1, `setup` again for the setext H2 (first H2 of that slug), and `setup-1` for the ATX H2 — incorrectly reporting `#setup-1` as pointing to the third heading instead of the second.

## Failure Guidance

`HOLDOUT LOW: HS-007 (satisfaction: 0.XX) -- duplicate-slug counter not shared across heading types (ATX vs setext); setext headings not included in collision namespace`

## Category: real-world-corpus

Setext-style headings (`Title\n=====` and `Section\n------`) are common in older Markdown documents and are part of the CommonMark spec. Documentation that mixes ATX and setext headings — common in projects migrating from older editors — can produce slug collisions across heading types. This scenario models a document with a repeated section name (`Setup`) using mixed heading styles, representative of auto-generated or partially-converted documentation.

| Field | Description |
|-------|-------------|
| corpus_source | Synthetic corpus modeled on mixed ATX/setext documentation with repeated section names |
| corpus_size | 2 files; spec.md ~12 lines, index.md ~4 lines |
| known_edge_cases | ATX H1 + setext H2 + ATX H2 all sharing slug `setup`; counter must be type-agnostic |
| false_positive_threshold | 0.0 — links 1-3 must all be clean |
| false_negative_threshold | 0.0 — link 4 must be broken(anchor-not-found) |
