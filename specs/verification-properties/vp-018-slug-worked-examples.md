---
document_type: verification-property
level: L4
version: "1.3"
status: draft
producer: architect
timestamp: 2026-08-05T20:00:00Z
phase: 1b
inputs:
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/planning/market-intelligence.md
input-hash: "acab0d6"
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
  - version: "1.3"
    date: 2026-08-06
    change: "P4 remediation: (P4-032) added 'use mdlinkcheck_core::slug::{compute_slug, DuplicateCounter};' import to harness. (P4-014) test file path corrected: tests/unit/slug_corpus.rs → tests/unit_slug_corpus.rs (flat layout). (P4-013) NFC comment on résumé row expanded to explain NFD asymmetry and reference ADR-008 §NFC/NFD ruling. (P4-010) Rule-1 corpus row re-labeled Rule-1a (pre-rendered only); added NOTE clarifying Rule 1b (rendering fidelity) is deferred to Phase 3 integration test."
  - version: "1.2"
    date: 2026-08-06
    change: "BI-005 spec-level closure: (1) added DI-012 Rule 3 falsifying case (AI & Automation → ai--automation); (2) added DI-012 Rule 7 falsifying case (Hello 🌍 → hello-); (3) added DI-012 Rule 1 pre-rendered golden vector (code text → code-text, sourced from ## `code` <em>text</em>); (4) added vp018_duplicate_heading_counter_0_based() — FM-002 discriminator, three ## Setup repeats → setup / setup-1 / setup-2; (5) added DI-012 Rule 1 end-to-end integration skeleton (Phase 3). VP-026 is the comprehensive differential oracle; these vectors are defense-in-depth."
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
// tests/unit_slug_corpus.rs  (Phase 3 — flat layout per tooling-selection.md §Test Target Layout)
// Reference corpus from market-intelligence §4.1 / gene-transfusion-assessment §1
// Each row tested with an independent fresh DuplicateCounter.
use mdlinkcheck_core::slug::{compute_slug, DuplicateCounter};

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
    // Accented preserved — NFC form: U+00E9 (é) is \p{L} (word char), retained as-is.
    // NFD form "re\u{0301}sume\u{0301}" would produce "resume" (combining diacritics
    // U+0301 are \p{Mn}, stripped as non-word chars). No normalization is applied before
    // slugging — see DI-012 Normalization rule and ADR-008 §NFC/NFD ruling.
    ("résumé",              "résumé"),
    // Markdown link syntax: brackets and parentheses stripped
    ("[link text](url)",    "link-texturl"),
    // DI-012 Rule 3 falsifying case (BI-005): & stripped; flanking spaces → "--"
    // "AI & Automation": lowercase → "ai & automation"; strip "&" → "ai  automation";
    // 1:1 space→hyphen on both spaces → "ai--automation" (NOT "ai-automation").
    // FM-001 shape: a v1 hyphen-collapser would produce "ai-automation" here.
    ("AI & Automation",        "ai--automation"),
    // DI-012 Rule 7 falsifying case (BI-005): emoji is not \p{Word}, not space, not hyphen.
    // 🌍 (U+1F30D, EARTH GLOBE EUROPE-AFRICA) is stripped; the space before it → "-".
    // Trailing "-" is retained per Rule 5 (no trim step).
    ("Hello 🌍",               "hello-"),
    // DI-012 Rule 1a pre-rendered golden vector (BI-005):
    // Source heading: ## `code` <em>text</em>
    //   inline code span "code" → contributes text "code"
    //   HTML <em> tag stripped; visible text "text" retained
    // Rendered text (after AST processing per DI-012 Rule 1): "code text"
    // Expected slug: "code-text"
    // NOTE: this row tests the slug function with PRE-RENDERED input — the rendering
    // step (Rule 1b: AST → text) is bypassed. Rule 1b is deferred to Phase 3 integration
    // in vp018_di012_rule1_end_to_end() below. This row covers Rule 1a only.
    ("code text",              "code-text"),
    // @GENERATED:BEGIN slug-corpus
    ("Foo"                , "foo"                ),  // TV-S001
    ("Hello, World!"      , "hello-world"        ),  // TV-S004
    ("Hello,  World!"     , "hello--world"       ),  // TV-S005
    ("Привет non-latin 你好", "привет-non-latin-你好"),  // TV-S006
    ("😄 emoji"            , "-emoji"             ),  // TV-S007
    ("snake_case_name"    , "snake_case_name"    ),  // TV-S008
    ("C++ / C#"           , "c--c"               ),  // TV-S009
    ("--online flag"      , "--online-flag"      ),  // TV-S010
    ("AI & Automation"    , "ai--automation"     ),  // TV-S011
    ("setup"              , "setup"              ),  // TV-S013
    ("Use --online now"   , "use---online-now"   ),  // TV-S014
    ("Foo "               , "foo-"               ),  // TV-S015
    ("Done ✅"             , "done-"              ),  // TV-S016
    // @GENERATED:END slug-corpus
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

**Duplicate-heading counter test — FM-002 discriminator (BI-005):**

```rust
#[test]
fn vp018_duplicate_heading_counter_0_based() {
    // DI-013 / FM-002 discriminator: three ## Setup headings MUST produce
    // "setup", "setup-1", "setup-2" — the 0-based counter scheme.
    // A 1-based counter produces "setup", "setup-2", "setup-3" — wrong.
    //
    // WHY THIS TEST CLOSES FM-002 WHEN VP-003 CANNOT:
    // VP-003 (Kani injectivity) proves the three outputs are distinct (≠).
    // Both ("setup","setup-1","setup-2") and ("setup","setup-2","setup-3")
    // satisfy injectivity. Only an exact-value comparison catches the off-by-one.
    // VP-026 is the comprehensive oracle; this test is defense-in-depth.
    let mut counter = DuplicateCounter::new();
    assert_eq!(compute_slug("Setup", &mut counter), "setup",
        "1st occurrence: bare slug, no suffix");
    assert_eq!(compute_slug("Setup", &mut counter), "setup-1",
        "2nd occurrence: suffix -1 (0-based counter slot 1, NOT -2)");
    assert_eq!(compute_slug("Setup", &mut counter), "setup-2",
        "3rd occurrence: suffix -2 (0-based counter slot 2, NOT -3)");
}
```

**TV-S001/S002/S003 and TV-S012 (shared-counter sequence and collision tests — generated from test-vectors.md §7):**

```rust
// @GENERATED:BEGIN slug-sequence-tests

/// TV-S001/TV-S002/TV-S003: three occurrences of "Foo" with shared counter (TV-S002 needs -1, TV-S003 needs -2)
#[test]
fn vp018_tv_s001_s002_s003_foo_sequence() {
    let mut counter = DuplicateCounter::new();
    assert_eq!(compute_slug("Foo", &mut counter), "foo",   "TV-S001: 1st Foo");
    assert_eq!(compute_slug("Foo", &mut counter), "foo-1", "TV-S002: 2nd Foo");
    assert_eq!(compute_slug("Foo", &mut counter), "foo-2", "TV-S003: 3rd Foo");
}

/// TV-S012: Foo / Foo / Foo-1 collision with shared counter (DEC-001 / dd-015)
/// The 3rd heading "Foo-1" has base slug "foo-1"; "foo-1" is already taken by the
/// 2nd "Foo" → while-loop bumps to "foo-1-1".
#[test]
fn vp018_tv_s012_foo_collision() {
    let mut counter = DuplicateCounter::new();
    assert_eq!(compute_slug("Foo",   &mut counter), "foo",     "TV-S012.1: first Foo");
    assert_eq!(compute_slug("Foo",   &mut counter), "foo-1",   "TV-S012.2: second Foo");
    assert_eq!(compute_slug("Foo-1", &mut counter), "foo-1-1", "TV-S012.3: Foo-1 collides");
}

// @GENERATED:END slug-sequence-tests
```

**DI-012 Rule 1 end-to-end integration skeleton (Phase 3 — CAP-005/CAP-006 required):**

```rust
// This test validates the full pipeline: raw markdown heading → anchor table builder
// (CAP-005) renders heading text → compute_slug (CAP-006) → final anchor key.
// It cannot run until anchor_table::build_for_test() exists (Phase 3).
//
// #[test]  // integration — enable in Phase 3
// fn vp018_di012_rule1_end_to_end() {
//     // Source: ## `code` <em>text</em>
//     // DI-012 Rule 1:
//     //   - Inline code span `code` → contributes text content "code"
//     //   - HTML <em> tag stripped; visible text "text" retained
//     // Rendered text: "code text"
//     // Expected anchor key: "code-text"
//     let md = "## `code` <em>text</em>\n";
//     let table = anchor_table::build_for_test(md);
//     assert!(
//         table.contains("code-text"),
//         "DI-012 Rule 1: expected anchor 'code-text' from '## `code` <em>text</em>'; \
//          got {:?}. Check that inline code contributes text and HTML tags are stripped.",
//         table
//     );
// }
```

## Feasibility Assessment

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Input space size | Exact fixtures | Corpus items (15) + DEC-001 triple + FM-002 discriminator; deterministic |
| Proof complexity | Low | Exact match test; no fuzzy logic |
| Tool support | Full | Standard nextest unit test |
| Estimated proof time | < 100ms | |

## SR-021 Generated Oracle Note

SR-021 recommends a generated differential oracle: a committed Node.js script that runs
`require('github-slugger')` over a sweep of inputs and emits `slug-vectors.json`, with a CI
check that regeneration is a no-op. This VP-018 corpus is a static hand-curated subset; the
generated oracle would cover a much larger sweep and would catch github-slugger v2 version
changes automatically. **This is now specified as VP-026** (slug differential fidelity,
Phase 3) — it formalises the SR-021 recommendation into a full verification property with
oracle corpus format, provenance requirements, and proptest generator strategy. The VP-018
static corpus remains the Phase 1 baseline requirement and is unaffected by VP-026.

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-05 | architect |
| v1.1 — SR-020 corpus corrections | 2026-08-05 | architect |
| v1.2 — BI-005 vectors + FM-002 discriminator | 2026-08-06 | architect |
| Proof harness committed | — | formal-verifier |
| Proof first passed | — | formal-verifier |
| Locked (VERIFIED) | — | formal-verifier |
