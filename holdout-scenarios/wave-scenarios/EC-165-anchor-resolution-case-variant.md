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
  - .factory/specs/behavioral-contracts/ss-05/BC-2.05.001.md
  - .factory/specs/behavioral-contracts/ss-05/BC-2.05.003.md
  - .factory/specs/behavioral-contracts/ss-08/BC-2.08.002.md
input-hash: "c8c643a"
traces_to: .factory/specs/prd.md
id: "HS-004"
category: "behavioral-contract"
must_pass: "true"
priority: "must-pass"
epic_id: "TBD"
behavioral_contracts:
  - BC-2.05.003
  - BC-2.08.002
lifecycle_status: active
introduced: v1.6
last_evaluated: null
staleness_check: null
stale_reason: null
retired: null
assumption_source: null
risk_source: null
---

# Holdout Scenario: Anchor Resolution — HTML `name` Case Sensitivity (EC-165)

> **WARNING:** This file is stored in `.factory/holdout-scenarios/` and must
> NEVER be shown to the implementer or test-writer agents. The information
> asymmetry between builder and evaluator is the core quality mechanism.

## Scenario

1. `guide.md` contains BOTH a heading and an HTML name anchor at the top:

   ```markdown
   # Guide

   <a name="API-v2">API Version 2</a>

   ## api v2
   ```

2. `## api v2` produces slug `api-v2` (all lowercase, hyphenated per github-slugger v2).
3. The HTML `<a name="API-v2">` sets a literal name anchor `API-v2` (mixed case).
4. Both entries are in the anchor table: `api-v2` (from heading slug) and `API-v2` (from HTML name, stored literally).

**Test vectors:**

```bash
# Fixture
mkdir -p /tmp/hs004
cat > /tmp/hs004/guide.md << 'EOF'
# Guide

<a name="API-v2">API Version 2</a>

## api v2
EOF

cat > /tmp/hs004/index.md << 'EOF'
[Lowercase slug](guide.md#api-v2)
[Exact HTML name](guide.md#API-v2)
[Wrong case — neither matches](guide.md#api-V2)
[Lowercase HTML name — wrong](guide.md#api-v2-lower)
EOF
```

Running `mdlinkcheck /tmp/hs004/`:

| Link | Fragment | Expected verdict | Reason |
|------|----------|-----------------|--------|
| `[Lowercase slug](guide.md#api-v2)` | `api-v2` | `clean` | Matches heading slug exactly |
| `[Exact HTML name](guide.md#API-v2)` | `API-v2` | `clean` | Matches HTML name literal exactly (case-sensitive) |
| `[Wrong case](guide.md#api-V2)` | `api-V2` | `broken` | `anchor-not-found`: heading slug is `api-v2`, HTML name is `API-v2`, neither matches `api-V2` |
| `[Lowercase HTML name](guide.md#api-v2-lower)` | `api-v2-lower` | `broken` | `anchor-not-found`: no anchor matches |

Expected: exit 1 (two broken links), two findings in stdout.

## Behavioral Contract Linkage

| BC ID | Clause Tested | Scenario Aspect |
|-------|--------------|-----------------|
| BC-2.05.003 | HTML `name` anchors extracted and stored literally (not lowercased) | `<a name="API-v2">` stored as `API-v2`, not `api-v2` |
| BC-2.08.002 | Anchor lookup is case-sensitive; fragment compared to slug/name as-is after percent-decode | `api-V2` matches neither `api-v2` (slug) nor `API-v2` (HTML name) → broken |

## Verification Approach

```bash
mkdir -p /tmp/hs004
cat > /tmp/hs004/guide.md << 'EOF'
# Guide

<a name="API-v2">API Version 2</a>

## api v2
EOF

cat > /tmp/hs004/index.md << 'EOF'
[ok-slug](guide.md#api-v2)
[ok-html](guide.md#API-v2)
[wrong-case](guide.md#api-V2)
EOF

mdlinkcheck /tmp/hs004/
# Expected: exit 1
# stdout (2 findings):
#   index.md:3: guide.md#api-V2 — anchor not found: #api-V2 in guide.md
```

## Evaluation Rubric

- **Functional correctness** (weight: 0.5): `#api-v2` is `clean`; `#API-v2` is `clean`; `#api-V2` is `broken(anchor-not-found)`.
- **Edge case handling** (weight: 0.3): The HTML name anchor `API-v2` is NOT lowercased when stored — a tool that normalizes all anchors to lowercase would incorrectly report `#API-v2` as broken.
- **Error quality** (weight: 0.1): The `broken` finding cites the correct fragment value and `anchor-not-found` reason code.
- **Performance** (weight: 0.05): Runs within NFR-001 budget.
- **Data integrity** (weight: 0.05): No duplicate findings; correct count.

## Edge Conditions

- The heading slug `api-v2` and the HTML name `API-v2` differ only in case. Both must be in the anchor table separately.
- A buggy implementation that lowercases HTML name anchors would store `api-v2` twice, incorrectly treating `#API-v2` as clean via the (now-lowercase) name anchor.
- A buggy implementation that uppercases fragment inputs would incorrectly match `api-v2` against an uppercase slug.

## Failure Guidance

`HOLDOUT LOW: HS-004 (satisfaction: 0.XX) -- HTML name anchors not stored with their original case; case-sensitive anchor lookup not enforced for name anchors`

## Category: real-world-corpus

Real-world documentation frequently uses HTML `<a name="...">` anchors for deep-linking (common in auto-generated API docs, Javadoc, and Sphinx HTML output). Mixed-case name anchors such as `API-v2`, `HTTPSConfig`, and `AuthN-Flow` are standard in practice. This scenario uses a minimal synthetic corpus representative of that pattern.

| Field | Description |
|-------|-------------|
| corpus_source | Synthetic corpus modeled on API documentation with mixed-case HTML name anchors |
| corpus_size | 2 files, ~10 lines |
| known_edge_cases | HTML name anchor vs heading slug coexistence, case-sensitive lookup, case mismatch detection |
| false_positive_threshold | 0.0 — `#api-v2` and `#API-v2` must both be clean |
| false_negative_threshold | 0.0 — `#api-V2` must be broken (anchor-not-found) |
