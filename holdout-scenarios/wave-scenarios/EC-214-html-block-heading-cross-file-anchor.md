---
document_type: holdout-scenario
level: ops
version: "1.0"
status: draft
producer: "vsdd-factory:product-owner"
timestamp: 2026-08-10T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/prd.md
  - .factory/specs/behavioral-contracts/ss-05/BC-2.05.001.md
  - .factory/specs/behavioral-contracts/ss-08/BC-2.08.004.md
input-hash: "a713eb5"
traces_to: .factory/specs/prd.md
id: "HS-008"
category: "behavioral-contract"
must_pass: "true"
priority: "must-pass"
epic_id: "TBD"
behavioral_contracts:
  - BC-2.05.001
  - BC-2.08.004
lifecycle_status: active
introduced: v1.11
last_evaluated: null
staleness_check: null
stale_reason: null
retired: null
assumption_source: null
risk_source: null
---

# Holdout Scenario: HTML-Block Heading × Cross-File Anchor (EC-214)

> **WARNING:** This file is stored in `.factory/holdout-scenarios/` and must
> NEVER be shown to the implementer or test-writer agents. The information
> asymmetry between builder and evaluator is the core quality mechanism.

## Scenario

Two files coexist in the scan root:

**`docs.md`** — contains two structures in this order:

```markdown
<div class="note">

## Quick Start

This section is inside a raw HTML block.

</div>

## Overview

This is a real Markdown heading outside any HTML block.
```

**`index.md`** — contains two links:

```markdown
[Setup](docs.md#quick-start)
[Overview](docs.md#overview)
```

The heading `## Quick Start` appears textually inside the body of a raw HTML
block (`<div>...</div>`). The Markdown parser emits the entire div as a single
`Event::Html` event; the heading text is raw HTML content, not a Markdown
`Event::Heading` event. Therefore `quick-start` is **not** added to the anchor
table for `docs.md`.

The heading `## Overview` appears outside any HTML block and IS a Markdown
`Event::Heading` event. Therefore `overview` IS in the anchor table.

**Expected verdicts:**

| Link | Fragment | Expected verdict | Reason |
|------|----------|-----------------|--------|
| `[Setup](docs.md#quick-start)` | `quick-start` | `broken` (`anchor-not-found`) | Heading inside `<div>` HTML block yields no anchor-table entry |
| `[Overview](docs.md#overview)` | `overview` | `clean` | Real Markdown heading outside HTML block; slug `overview` is in anchor table |

**Expected exit code:** 1 (one broken link).

**Expected stdout (one finding):**

```
index.md:1: docs.md#quick-start — anchor not found: #quick-start in docs.md
```

## Test Vectors

```bash
mkdir -p /tmp/hs008
cat > /tmp/hs008/docs.md << 'EOF'
<div class="note">

## Quick Start

This section is inside a raw HTML block.

</div>

## Overview

This is a real Markdown heading outside any HTML block.
EOF

cat > /tmp/hs008/index.md << 'EOF'
[Setup](docs.md#quick-start)
[Overview](docs.md#overview)
EOF

mdlinkcheck /tmp/hs008/
# Expected: exit 1
# stdout (1 finding):
#   index.md:1: docs.md#quick-start — anchor not found: #quick-start in docs.md
# Confirm: index.md:2 (Overview link) produces NO finding
```

## Behavioral Contract Linkage

| BC ID | Clause Tested | Scenario Aspect |
|-------|--------------|-----------------|
| BC-2.05.001 | Pass 1.5 anchor-table construction: headings inside `Event::Html` raw-HTML blocks must NOT be added to the anchor table | `## Quick Start` inside `<div>` must not create slug `quick-start` in docs.md anchor table |
| BC-2.08.004 | Cross-file anchor resolution: fragment is looked up in the target file's anchor table | `docs.md#quick-start` resolved cross-file against docs.md anchor table — not found → `broken(anchor-not-found)` |

## Verification Approach

Run the fixture above. Three assertions:

1. Exit code is 1.
2. Stdout contains exactly one finding: source `index.md`, line 1, target `docs.md#quick-start`, reason `anchor-not-found`.
3. Stdout does NOT contain a finding for `docs.md#overview` — the `overview` anchor (from the real Markdown heading) resolves clean.

The critical trap: an implementation that scans raw HTML event text for ATX heading patterns (e.g., regex `^##\s+(.+)`) would incorrectly add `quick-start` to the anchor table, producing a false CLEAN result for `docs.md#quick-start`.

## Evaluation Rubric

- **Functional correctness** (weight: 0.5): `docs.md#quick-start` is `broken(anchor-not-found)`; `docs.md#overview` is `clean`.
- **Edge case handling** (weight: 0.3): The broken finding must cite `anchor-not-found` (not `file-not-found`) — proving that `docs.md` was found and its anchor table was built, but `quick-start` is absent from that table.
- **Error quality** (weight: 0.1): The `broken` finding references the correct source file (`index.md`) and fragment (`#quick-start`).
- **Performance** (weight: 0.05): Runs within NFR-001 budget.
- **Data integrity** (weight: 0.05): Exactly one finding; `overview` link produces no finding.

## Edge Conditions

- The `## Quick Start` heading MUST be preceded and followed by blank lines within the `<div>` block; without blank lines the Markdown parser may not emit the surrounding HTML as a single block event (CommonMark paragraph-continuation rules). The fixture above includes blank lines.
- A correct implementation uses the parser event stream (pulldown-cmark `Event::Heading`) exclusively for heading collection — it never pattern-matches heading syntax inside `Event::Html` events.
- The positive control (`## Overview`) proves that Pass 1.5 DID run anchor-table construction for `docs.md`; a `file-not-found` result for `docs.md#quick-start` would indicate a different failure (anchor table not built at all), not the target failure mode.

## Failure Guidance

`HOLDOUT LOW: HS-008 (satisfaction: 0.XX) -- heading inside raw HTML block incorrectly added to anchor table; or cross-file anchor table construction skipped for docs.md`

## Category: behavioral-contract

Documentation repositories commonly embed headings inside HTML admonition blocks such as `<div class="note">`, `<div class="warning">`, or `<details>` elements for styled callouts. GitHub renders the HTML but the Markdown parser treats the block content as opaque HTML. An anchor link pointing to such a heading should be `broken` because the heading never entered the anchor table.

| Field | Description |
|-------|-------------|
| corpus_source | Synthetic corpus modeled on documentation with HTML admonition blocks |
| corpus_size | 2 files, ~15 lines total |
| known_edge_cases | Heading inside raw HTML block (not a Markdown Event::Heading); cross-file anchor lookup; positive control via real heading |
| false_positive_threshold | 0.0 — `docs.md#overview` must be clean |
| false_negative_threshold | 0.0 — `docs.md#quick-start` must be broken(anchor-not-found) |
