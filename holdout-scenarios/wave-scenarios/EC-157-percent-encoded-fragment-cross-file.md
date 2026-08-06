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
  - .factory/specs/behavioral-contracts/ss-08/BC-2.08.002.md
  - .factory/specs/behavioral-contracts/ss-08/BC-2.08.003.md
input-hash: "7fc4857"
traces_to: .factory/specs/prd.md
id: "HS-002"
category: "edge-case-combinations"
must_pass: "true"
priority: "must-pass"
epic_id: "TBD"
behavioral_contracts:
  - BC-2.08.002
  - BC-2.08.003
lifecycle_status: active
introduced: v1.5
last_evaluated: null
staleness_check: null
stale_reason: null
retired: null
assumption_source: null
risk_source: null
---

# Holdout Scenario: Percent-Encoded Fragment in Cross-File Link (EC-157)

> **WARNING:** This file is stored in `.factory/holdout-scenarios/` and must
> NEVER be shown to the implementer or test-writer agents. The information
> asymmetry between builder and evaluator is the core quality mechanism.

## Scenario

1. File `a.md` contains the cross-file anchor link `[Guide](other.md#caf%C3%A9)`.
2. File `other.md` exists and contains the heading `## Café`.
3. The user runs `mdlinkcheck .` (or `mdlinkcheck a.md`).
4. Expected: exit 0, verdict `clean` — the fragment `caf%C3%A9` must be percent-decoded
   to `café` before comparison with the slug of `## Café` (which is `café`).

**Negative control:**

1. Same setup, but `other.md` has heading `## Coffee` (no `## Café`).
2. Expected: exit 1, `broken (anchor-not-found)` — the decoded fragment `café` finds
   no matching slug.

## Behavioral Contract Linkage

| BC ID | Clause Tested | Scenario Aspect |
|-------|--------------|-----------------|
| BC-2.08.003 | Postcondition 1 — fragment split at first `#` before percent-decode | Fragment `#caf%C3%A9` is the raw fragment extracted from `other.md#caf%C3%A9` |
| BC-2.08.003 | Postcondition 2 — percent-decode applied after split | `caf%C3%A9` → `café` before slug comparison |
| BC-2.08.002 | Postcondition 3 — decoded fragment matched against anchor table of `other.md` | Cross-file path: `other.md` anchor table is built, then `café` slug looked up |

## Verification Approach

```bash
mkdir -p /tmp/hs002
cat > /tmp/hs002/a.md <<'EOF'
# Source

[Guide](other.md#caf%C3%A9)
EOF
cat > /tmp/hs002/other.md <<'EOF'
# Other

## Café

Content here.
EOF

# Test 1: fragment decodes to matching slug → clean
cd /tmp/hs002
mdlinkcheck .
# Expected: exit 0, no stdout findings

# Test 2: anchor absent → broken
cat > /tmp/hs002/other.md <<'EOF'
# Other

## Coffee

Content here.
EOF
mdlinkcheck .
# Expected: exit 1
# stdout: a.md:3: broken (anchor-not-found) other.md#caf%C3%A9
```

## Evaluation Rubric

- **Functional correctness** (weight: 0.6): Test 1 exits 0 (percent-decode in cross-file path works); Test 2 exits 1 with `anchor-not-found`.
- **Edge case handling** (weight: 0.2): The cross-file path must decode the fragment — implementations that decode in same-file but not cross-file will fail Test 1 while passing EC-053 (same-file visible test).
- **Error quality** (weight: 0.1): Test 2 finding cites `other.md#caf%C3%A9` (original encoded form, per BC-2.08.003 Postcondition 3 — report uses original fragment).
- **Performance** (weight: 0.05): No measurable latency difference from ASCII-only anchors.
- **Data integrity** (weight: 0.05): Exactly one finding in Test 2; no double-reporting.

## Edge Conditions

- This is a CROSS-FILE percent-encoded anchor. The visible EC-053 (TV-053) tests the same-file case `[x](#caf%C3%A9)`. The cross-file path invokes `anchor_resolver.rs` which must also percent-decode before slug comparison.
- The distinction is identical to Sphinx bug #13620: fragment decode must happen in the cross-file anchor resolver, not just in the same-file path.
- `other.md`'s heading `## Café` slugifies to `café` (Unicode retained per github-slugger v2). The decoded fragment is also `café`. Exact match → clean.

## Failure Guidance

`HOLDOUT LOW: HS-002 (satisfaction: 0.XX) -- percent-encoded fragments are not being decoded before slug comparison in the cross-file anchor resolution path`

## Category: real-world-corpus

| Field | Description |
|-------|-------------|
| corpus_source | Synthetic fixture representing documentation with international headings (café, résumé, etc.), common in European open-source projects |
| corpus_size | 2 files, ~10 lines |
| known_edge_cases | Percent-encoded non-ASCII fragment in cross-file context; UTF-8 multi-byte codepoint (`é` = U+00E9 = `%C3%A9`) |
| false_positive_threshold | 0.0 — must be exactly clean |
| false_negative_threshold | 0.0 — must detect missing heading exactly |
