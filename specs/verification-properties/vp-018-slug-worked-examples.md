---
document_type: verification-property
level: L4
version: "1.1"
status: draft
producer: architect
timestamp: 2026-08-05T20:00:00Z
phase: 1b
inputs:
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/planning/market-intelligence.md
input-hash: "da42fbb"
traces_to: .factory/specs/architecture/ARCH-INDEX.md
source_bc: BC-2.06.001
module: slug
proof_method: unit
feasibility: feasible
verification_lock: false
proof_completed_date: null
proof_file_hash: null
lifecycle_status: active
introduced: v0.1.0
modified:
  - version: "1.1"
    date: 2026-08-05
    change: "SR-020 remediation: (1) fixed Hello,World! expected from hello-world-1 to hello-world (fresh counter; comma/bang stripped; no prior registration); (2) fixed leading-spaces expected from leading-spaces to --leading-spaces-- (market-intelligence §4.1 rule 4: 1:1 space→hyphen, no trimming); (3) removed duplicate Hello World row; (4) added DEC-001 triple collision-bump test function; (5) noted SR-021 generated oracle recommendation"
deprecated: null
deprecated_by: null
replacement: null
retired: null
withdrawn: null
withdrawal_reason: null
removed: null
removal_reason: null
---

# VP-018: All Slug Worked Examples Produce Exact Match (NFR-006)

## Property Statement

The corpus fixtures from market-intelligence §4.1 (the github-slugger v2 ground truth test
cases) all produce byte-identical output from `compute_slug`. No fuzzy matching — exact byte
equality. This verifies the clean-room reimplementation against the behavioral specification.
NFR-006 requires 100% parity on the reference corpus.

Each corpus row is tested with a **fresh `DuplicateCounter`** (isolated call), so no
duplicate-counter state bleeds between rows. The DEC-001 collision-bump triple is tested
separately with a **shared counter** (see below).

## Source Contract

- **BC:** BC-2.06.001 — Slug Computation Algorithm (corpus parity requirement)
- **Postcondition/Invariant:** NFR-006 — clean-room reimplementation matches github-slugger v2
  on all reference corpus inputs.

## Proof Method

| Method | Tool | Bounded? | Coverage |
|--------|------|----------|----------|
| unit | nextest 0.9.129 | yes — exact corpus | Reference inputs with expected outputs from market-intelligence §4.1; byte-exact comparison |

## Proof Harness Skeleton

```rust
// tests/unit/slug_corpus.rs
// Reference corpus from market-intelligence §4.1 / gene-transfusion-assessment §1
// Each row tested with an independent fresh DuplicateCounter.

const SLUG_CORPUS: &[(&str, &str)] = &[
    // Basic ASCII
    ("Hello World",         "hello-world"),
    // Punctuation stripped — comma and ! produce no output characters
    // (fresh counter: no prior "hello-world" registered, so no -1 suffix)
    ("Hello, World!",       "hello-world"),
    // Non-ASCII preserved after Unicode lowercase
    ("Привет мир",          "привет-мир"),
    ("日本語",               "日本語"),
    // Symbols stripped
    ("C++ Pointers",        "c-pointers"),
    // Leading digit preserved
    ("1. Introduction",     "1-introduction"),
    // Underscore preserved (github-slugger v2 rule)
    ("under_score",         "under_score"),
    // Hyphen preserved
    ("hyphen-test",         "hyphen-test"),
    // Spaces become hyphens 1:1 — NO trimming of leading/trailing hyphens
    // market-intelligence §4.1 rule 4: "Replace each space with a hyphen —
    //   1:1 per-character, no run collapsing, leading/trailing hyphens never trimmed"
    ("  Leading spaces  ",  "--leading-spaces--"),
    // ALL CAPS → lowercased
    ("ALL CAPS",            "all-caps"),
    // Accented preserved (NFC normalization)
    ("résumé",              "résumé"),
    // Markdown link syntax: brackets and parentheses stripped
    ("[link text](url)",    "link-texturl"),
];

#[test]
fn vp018_slug_corpus_exact_match() {
    for (input, expected) in SLUG_CORPUS {
        let mut counter = DuplicateCounter::new();  // fresh per row
        let actual = compute_slug(input, &mut counter);
        assert_eq!(actual, *expected,
            "Corpus mismatch for input {:?}: got {:?}, expected {:?}",
            input, actual, expected);
    }
}
```

**DEC-001 collision-bump triple (shared counter — tests the `while` loop branch):**

```rust
#[test]
fn vp018_dec001_collision_bump() {
    // Reproduces the lychee #1613 collision edge case from market-intelligence §4.1.
    // Three headings processed with ONE shared counter.
    // "Setup 1" base-slug "setup-1" collides with the second result before
    // the counter for "setup-1" increments — this exercises the while-loop
    // in the collision-bump algorithm that the single-string harness cannot reach.
    let mut counter = DuplicateCounter::new();
    assert_eq!(compute_slug("Setup",   &mut counter), "setup");
    assert_eq!(compute_slug("Setup",   &mut counter), "setup-1");
    assert_eq!(compute_slug("Setup 1", &mut counter), "setup-1-1");
}
```

## Feasibility Assessment

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Input space size | Exact fixtures | Corpus items + DEC-001 triple; deterministic |
| Proof complexity | Low | Exact match test; no fuzzy logic |
| Tool support | Full | Standard nextest unit test |
| Estimated proof time | < 100ms | |

## SR-021 Generated Oracle Note

SR-021 recommends a generated differential oracle: a committed Node.js script that runs
`require('github-slugger')` over a sweep of inputs and emits `slug-vectors.json`, with a CI
check that regeneration is a no-op. This VP-018 corpus is a static hand-curated subset; the
generated oracle would cover a much larger sweep and would catch github-slugger v2 version
changes automatically. **This is deferred to Phase 3** as a story task — it requires Node.js
tooling at vector-generation time and a `just regen-slug-vectors` target. The VP-018 static
corpus remains the Phase 1 baseline requirement and is unaffected by the Phase 3 oracle.

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-05 | architect |
| v1.1 — SR-020 corpus corrections | 2026-08-05 | architect |
| Proof harness committed | — | formal-verifier |
| Proof first passed | — | formal-verifier |
| Locked (VERIFIED) | — | formal-verifier |
