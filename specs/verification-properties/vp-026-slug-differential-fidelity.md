---
document_type: verification-property
level: L4
version: "1.1"
status: draft
producer: architect
timestamp: 2026-08-06T00:00:00Z
phase: 1b
inputs:
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/domain-spec/failure-modes.md
  - .factory/specs/architecture/module-decomposition.md
input-hash: "85c2674"
traces_to: .factory/specs/architecture/ARCH-INDEX.md
source_bc: BC-2.06.001
module: slug
proof_method: proptest
feasibility: feasible
verification_lock: false
proof_completed_date: null
proof_file_hash: null
lifecycle_status: active
introduced: v0.1.0
modified:
  - version: "1.1"
    date: 2026-08-06
    change: "P4 remediation: (P4-023) Proof Method tool corrected: fast-check → proptest 1.6.x + serde_json 1.x. (P4-024) Oracle corpus format section: normalized to stateful GithubSlugger API (new GithubSlugger().slug()) — the stateless export cannot model multi-entry runs. (P4-025) R-003 rendered text corrected: 'config api new' → 'config API new' (lowercasing is slug step (b), not part of rendering). (P4-009) Added proptest arms prop_vp026_rule5_leading_trailing_retained and prop_vp026_rule6_unicode_word_retained; deleted dead heading_text_strategy; added oracle-wins precedence clause to §Oracle Definition. (P4-010) DI-012 Rule Coverage table: Rule 1 row split into Rule 1a (pre-rendered, oracle-covered) and Rule 1b (rendering fidelity, Phase 3 obligation). (P4-011) Oracle freshness CI check: replaced git diff with jq diff excluding generated_at and node_version timestamps; added note that github_slugger_version and generator_script_sha256 MUST be in diff scope. (P4-012) vp026_oracle_corpus_exact_match: added positive-coverage block asserting R-001..R-008 present, R-001 ≥3 entries, entries_checked ≥8; added eprintln summary per POL-11. (P4-013) oracle_runs_required and Phase 3 obligation table: added R-009 (NFC form) and OR-010 (NFD form). (P4-014) test file path corrected: tests/proptest/slug_differential.rs → tests/proptest_slug_differential.rs (flat Cargo-discoverable layout)."
deprecated: null
deprecated_by: null
replacement: null
retired: null
withdrawn: null
withdrawal_reason: null
removed: null
removal_reason: null
---

# VP-026: Slug Differential Fidelity — github-slugger v2 Oracle Parity

## Property Statement

For every heading input in the pinned oracle corpus and for proptest-generated
heading inputs, `compute_slug` produces byte-identical output to
`github-slugger@2.0.0` at the same counter state. This is a differential
correctness test: VP-003 proves injectivity (no two outputs collide); VP-026
proves the exact output values match the canonical reference.

All seven DI-012 rules are covered independently — each has a falsifying clause
that a compliant implementation passes and a non-compliant one fails. The
duplicate-counter discriminator (Rule 7c below) closes FM-002: a 1-based counter
produces observably different output from a 0-based counter when the corpus
contains a heading sequence of length ≥ 3.

**Why VP-003 cannot close FM-002:** VP-003's Kani proof establishes that no two
outputs from `compute_slug` with a shared counter are equal. Both `("setup",
"setup-1", "setup-2")` and `("setup", "setup-2", "setup-3")` satisfy injectivity.
Only an oracle comparison with the exact expected values catches the off-by-one.

## Source Contract

- **BC:** BC-2.06.001 — Slug Computation Algorithm (parity with github-slugger v2)
- **BC:** BC-2.06.002 — Duplicate Heading Disambiguation (0-based counter)
- **Postconditions/Invariants:**
  - DI-012 — slug computation fidelity (all 7 rules)
  - DI-013 — anchor-key uniqueness (0-based counter exact values)
  - FM-002 — duplicate-counter 1-based bug is now provable (covered by this VP)

## Oracle Definition

### Canonical Authority

The canonical reference is GitHub's heading-anchor behavior as implemented by
`github-slugger@2.0.0` (the exact version pinned in DD-015). No other version is
authoritative: github-slugger v1.x used different hyphen-collapse behavior (FM-001
shape).

### Oracle Corpus Format

The corpus is a committed JSON fixture at
`tests/fixtures/slug-oracle-vectors.json`. It is structured as a sequence of
*runs*, where each run is a sequence of headings processed through a single fresh
`Slugger` instance in order. This models the per-file duplicate-counter lifecycle.

```json
{
  "provenance": {
    "github_slugger_version": "2.0.0",
    "generator_script": "tools/gen-slug-oracle.js",
    "generator_script_sha256": "<sha256 of gen-slug-oracle.js at generation time>",
    "generated_at": "YYYY-MM-DDTHH:MM:SSZ",
    "node_version": "22.x"
  },
  "runs": [
    {
      "id": "R-001",
      "description": "FM-002 discriminator — three identical headings, 0-based counter",
      "entries": [
        { "heading": "Setup", "expected": "setup" },
        { "heading": "Setup", "expected": "setup-1" },
        { "heading": "Setup", "expected": "setup-2" }
      ]
    },
    {
      "id": "R-002",
      "description": "DI-012 Rule 3 — 1:1 space substitution, no run collapsing",
      "entries": [
        { "heading": "AI & Automation", "expected": "ai--automation" }
      ]
    }
  ]
}
```

### Stateful API Requirement

The generator script MUST use the stateful `GithubSlugger` class per run — NOT the
stateless `slug()` module export. The stateless export has no counter and cannot
model multi-entry runs (including R-001's FM-002 discriminator). Normative form:

```js
import GithubSlugger from 'github-slugger';
// Per run:
const slugger = new GithubSlugger();
for (const entry of run.entries) {
    entry.expected = slugger.slug(entry.heading);
}
```

**Oracle-wins precedence clause:** Where a proptest structural assertion (derived
from DI-012 prose) conflicts with the committed oracle corpus, **the oracle wins**.
The DI-012 prose describes the intended algorithm behavior; the oracle captures the
canonical reference implementation's actual output. If they diverge, the DI-012
prose is corrected to match the library and the proptest arm is amended in the same
commit. This precedence prevents VP-026 from becoming unsatisfiable if DI-012's
prose is imprecise for any of the ~1,800 codepoints in emoji range.

### Constraint: No Live JS Dependency at Test Time

Rust cannot call the Node.js `github-slugger` library at Cargo test time. The
oracle corpus MUST be a committed fixture, not a live dependency. The fixture is
regenerated by `just regen-slug-vectors` (runs `tools/gen-slug-oracle.js`). A CI
check verifies the corpus is current by running the generator and comparing only
the stable content fields:

```sh
just regen-slug-vectors
# Compare runs + version/script hash; exclude generated_at and node_version
# (wall-clock timestamp changes on every regeneration and must not trigger failure)
jq -S '{runs, provenance: {github_slugger_version, generator_script_sha256}}' \
    tests/fixtures/slug-oracle-vectors.json > /tmp/new.json
jq -S '{runs, provenance: {github_slugger_version, generator_script_sha256}}' \
    tests/fixtures/slug-oracle-vectors.json.committed > /tmp/committed.json
diff /tmp/new.json /tmp/committed.json
```

`github_slugger_version` and `generator_script_sha256` MUST remain inside the
diff scope so an unreviewed `github-slugger` upgrade or generator script change is
detected. Only `generated_at` and `node_version` are excluded from the diff.

**Provenance record:** The fixture embeds the generator script SHA-256 and the
`github-slugger` npm package version. If `github-slugger` is upgraded, the
generator is re-run and the new corpus committed; VP-026 then tests against the
new reference. The old corpus is preserved in git history for regression comparison.

## DI-012 Rule Coverage

Each rule has an independent falsifying clause. A correct implementation passes
all seven; a partially-correct implementation fails at least one.

| Rule | DI-012 Statement | Oracle Clause | Canonical Falsifying Input → Expected |
|------|-----------------|---------------|---------------------------------------|
| 1a | Input is rendered text content — inline code → text (slug-level: oracle tests pre-rendered form) | Oracle corpus R-003: pre-rendered text `"config API new"` (lowercasing happens in slug step (b), not rendering) | `"config API new"` from `## \`config\` API <em>new</em>` → `"config-api-new"` |
| 1b | HTML tags stripped, visible text retained — rendering fidelity | **NOT covered until Phase 3** — integration obligation; see §Phase 3 | `## \`config\` API <em>new</em>` → anchor `"config-api-new"` (requires CAP-005 integration) |
| 2 | Full Unicode `to_lowercase()` — not ASCII-only | Proptest Cyrillic/Greek/accented Latin strategy; oracle R-004 | `"Привет"` → `"привет"` |
| 3 | 1:1 space→hyphen — runs NOT collapsed | Oracle R-002; proptest multi-space strategy | `"AI & Automation"` → `"ai--automation"` |
| 4 | `_` retained | Oracle R-005; proptest `_`-containing strategy | `"my_heading"` → `"my_heading"` |
| 5 | Leading and trailing hyphens retained (no trim) | Oracle R-006; proptest leading/trailing-space strategy | `"  Leading  "` → `"--leading--"` |
| 6 | CJK, Cyrillic, accented Latin retained (`\p{Word}`) | Oracle R-007; proptest Unicode retained-class strategy | `"日本語"` → `"日本語"` |
| 7 | Emoji stripped (not `\p{Word}`, not `-`, not space) | Oracle R-008; proptest emoji-injection strategy | `"Hello 🌍"` → `"hello-"` |

**NOTE on Rule 1 coverage gap:** Six of seven rules have an enabled falsifying
clause. Rule 1's rendering half (Rule 1b) requires the `anchor_table` builder
(CAP-005) to be integrated — the slug function alone cannot be tested for rendering
behavior. Rule 1a (slug of pre-rendered text) IS covered by oracle R-003.

**Rule 1a DI-012 input definition — oracle entry R-003:**
The oracle corpus must include a run whose heading text is the pre-rendered form of
a heading containing both an inline code span and an HTML tag:
- Source heading (raw markdown): `## \`config\` API <em>new</em>`
- Rendered text content per DI-012 rule 1: `"config API new"` (inline code
  contributes its text "config"; `<em>` tag stripped, visible text "new" retained;
  lowercasing is slug step (b) — NOT part of rendering)
- `new GithubSlugger().slug("config API new")` → `"config-api-new"`

The generator script passes the **pre-rendered text** to `github-slugger`. The
integration of the full pipeline (raw heading → AST rendering → `compute_slug`) is
an obligation recorded in the Phase 3 section below.

## Duplicate-Counter Discriminator (FM-002 Closure)

Oracle run R-001 is the specific discriminating clause for FM-002. The corpus MUST
contain a run of at least three entries with the same base heading:

| Call # | Heading | 0-based (correct) | 1-based (FM-002 bug) |
|--------|---------|-------------------|----------------------|
| 1st | "Setup" | `"setup"` | `"setup"` |
| 2nd | "Setup" | `"setup-1"` ← | `"setup-2"` ← |
| 3rd | "Setup" | `"setup-2"` | `"setup-3"` |

The second entry is where the implementations diverge. A sequence of only 2
entries would detect the FM-002 bug only if the second entry is checked; a
sequence of ≥ 3 makes the divergence observable at both the second and third
positions, providing a stronger discriminator against accidental passes.

**Why VP-003 is insufficient for FM-002 (restated clearly):** VP-003's Kani proof
establishes `slug1 ≠ slug2` for any two calls. For the 1-based implementation,
`"setup" ≠ "setup-2" ≠ "setup-3"` — all distinct, Kani passes. VP-026 R-001
checks `slug2 == "setup-1"` and `slug3 == "setup-2"` — a 1-based implementation
fails both. This is the only clause in the current verification suite that catches
FM-002 before Phase 6.

## Proof Method

| Method | Tool | Bounded? | Coverage |
|--------|------|----------|----------|
| proptest | proptest 1.6.x + serde_json 1.x | oracle: exact corpus; proptest: bounded by strategy | Oracle corpus covers 7-rule DI-012 classification + duplicate-counter exact values; proptest generator explores Unicode, emoji, whitespace, and repeated-heading space |

**Two test components under one VP:**
1. **Oracle corpus fixture test** — loads `tests/fixtures/slug-oracle-vectors.json`,
   iterates over every run, reconstructs counter state per run, and asserts exact
   byte-equality for each entry. This is deterministic and fails if the corpus or
   the implementation diverges.
2. **Proptest differential generator** — generates heading inputs from the strategy
   below and verifies structural DI-012 properties (not full oracle comparison, since
   the oracle is finite). Catches regressions not in the committed corpus.

## Proof Harness Skeleton

```rust
// tests/proptest_slug_differential.rs  (Phase 3 — flat layout per tooling-selection.md §Test Target Layout)
// VP-026: Slug Differential Fidelity
// Module: mdlinkcheck-core, crate mdlinkcheck-core
// Phase 3 story: create this file and tests/fixtures/slug-oracle-vectors.json

use mdlinkcheck_core::slug::{compute_slug, DuplicateCounter};
use proptest::prelude::*;
use serde::Deserialize;

// --- Oracle corpus types ---

#[derive(Debug, Deserialize)]
struct OracleProvenance {
    github_slugger_version: String,
    generator_script: String,
}

#[derive(Debug, Deserialize)]
struct OracleEntry {
    heading: String,
    expected: String,
}

#[derive(Debug, Deserialize)]
struct OracleRun {
    id: String,
    description: String,
    entries: Vec<OracleEntry>,
}

#[derive(Debug, Deserialize)]
struct OracleCorpus {
    provenance: OracleProvenance,
    runs: Vec<OracleRun>,
}

// --- Oracle corpus test ---

#[test]
fn vp026_oracle_corpus_exact_match() {
    // Load committed oracle fixture — no live JS dependency.
    let corpus: OracleCorpus = serde_json::from_str(
        include_str!("../tests/fixtures/slug-oracle-vectors.json")
    ).expect("oracle corpus is valid JSON — regenerate with `just regen-slug-vectors`");

    // Verify provenance pin: if github-slugger was upgraded without regenerating
    // the corpus, this assertion catches the mismatch before any slug test runs.
    assert_eq!(
        corpus.provenance.github_slugger_version, "2.0.0",
        "Oracle corpus was generated against github-slugger v{}; expected v2.0.0. \
         Regenerate with `just regen-slug-vectors` after reviewing the version bump.",
        corpus.provenance.github_slugger_version
    );

    // Positive-coverage block (POL-11): assert all required runs are present and
    // contain sufficient entries before iterating. This prevents a truncated corpus
    // from passing vacuously (an empty runs vec makes the loop a no-op).
    let ids: std::collections::HashSet<&str> =
        corpus.runs.iter().map(|r| r.id.as_str()).collect();
    for required in ["R-001","R-002","R-003","R-004","R-005","R-006","R-007","R-008",
                     "R-009","OR-010"] {
        assert!(ids.contains(required),
            "Oracle corpus missing required run {} — regenerate with `just regen-slug-vectors`. \
             Required runs: R-001..R-008 (DI-012 rules), R-009 (NFC), OR-010 (NFD).", required);
    }
    let r001 = corpus.runs.iter().find(|r| r.id == "R-001").unwrap();
    assert!(r001.entries.len() >= 3,
        "FM-002 discriminator requires ≥3 entries in R-001; found {}. \
         Three consecutive identical headings are needed to distinguish 0-based from 1-based counter.",
        r001.entries.len());

    // Iterate runs; each run gets a fresh counter (models per-file counter lifecycle).
    let mut entries_checked = 0usize;
    for run in &corpus.runs {
        let mut counter = DuplicateCounter::new();
        for entry in &run.entries {
            let actual = compute_slug(&entry.heading, &mut counter);
            assert_eq!(
                actual, entry.expected,
                "Oracle mismatch in run {} ({:?}): heading {:?} — \
                 got {:?}, expected {:?}. DI-012/DI-013 violation.",
                run.id, run.description, entry.heading, actual, entry.expected
            );
            entries_checked += 1;
        }
    }

    // Final positive-coverage assertion: at least one entry per required run.
    assert!(entries_checked >= 10,
        "Oracle corpus validated only {} entries across {} runs; expected ≥10 \
         (one per required run R-001..OR-010).", entries_checked, corpus.runs.len());
    eprintln!("VP-026 oracle: {} runs, {} entries validated against github-slugger@{}",
        corpus.runs.len(), entries_checked, corpus.provenance.github_slugger_version);
}

// FM-002 discriminator: must be in the oracle corpus as run R-001, but also
// tested explicitly here so failures are reported with the FM-002 label.
#[test]
fn vp026_fm002_discriminator_0_based_counter() {
    // Three ## Setup headings: github-slugger v2 produces "setup", "setup-1", "setup-2".
    // A 1-based implementation produces "setup", "setup-2", "setup-3" — injectivity
    // holds in both cases (VP-003 passes); only this exact-value test catches FM-002.
    let mut counter = DuplicateCounter::new();
    assert_eq!(compute_slug("Setup", &mut counter), "setup",
        "FM-002: 1st occurrence must be base slug with no suffix");
    assert_eq!(compute_slug("Setup", &mut counter), "setup-1",
        "FM-002: 2nd occurrence must have suffix -1 (0-based counter, NOT -2)");
    assert_eq!(compute_slug("Setup", &mut counter), "setup-2",
        "FM-002: 3rd occurrence must have suffix -2 (0-based counter, NOT -3)");
}

// --- Proptest arms (one per DI-012 rule; no dead strategy function) ---

proptest! {
    // Rule 2: all output characters must be lowercase Unicode letters
    #[test]
    fn prop_vp026_rule2_unicode_lowercase(heading in "[\\p{Lu}]{1,20}") {
        let mut counter = DuplicateCounter::new();
        let slug = compute_slug(&heading, &mut counter);
        prop_assert!(
            slug.chars().all(|c| !c.is_uppercase()),
            "Rule 2 violation: uppercase char in slug {:?} from input {:?}",
            slug, heading
        );
    }

    // Rule 3: space count in input equals hyphen count at same positions in output
    // (tests 1:1 substitution, not run-collapsing)
    #[test]
    fn prop_vp026_rule3_space_to_hyphen_1to1(
        prefix in "[a-z]{1,6}",
        spaces in " {2,5}",  // 2+ spaces to make non-collapse observable
        suffix in "[a-z]{1,6}"
    ) {
        let input = format!("{}{}{}", prefix, spaces, suffix);
        let mut counter = DuplicateCounter::new();
        let slug = compute_slug(&input, &mut counter);
        // The hyphen run between prefix and suffix must equal the space count.
        let space_count = spaces.len();
        let slug_after_prefix = &slug[prefix.len()..];
        let hyphen_run = slug_after_prefix.chars().take_while(|&c| c == '-').count();
        prop_assert_eq!(
            hyphen_run, space_count,
            "Rule 3 violation: {} spaces became {} hyphens (expected 1:1) in {:?} → {:?}",
            space_count, hyphen_run, input, slug
        );
    }

    // Rule 4: underscore always passes through unchanged
    #[test]
    fn prop_vp026_rule4_underscore_retained(
        a in "[a-z]{1,8}",
        b in "[a-z]{1,8}"
    ) {
        let input = format!("{a}_{b}");
        let mut counter = DuplicateCounter::new();
        let slug = compute_slug(&input, &mut counter);
        prop_assert!(
            slug.contains('_'),
            "Rule 4 violation: underscore stripped in {:?} → {:?}", input, slug
        );
    }

    // Rule 5: leading and trailing spaces produce leading and trailing hyphens (no trim)
    #[test]
    fn prop_vp026_rule5_leading_trailing_retained(
        lead in " {1,3}",
        body in "[a-z]{1,10}",
        trail in " {0,3}"
    ) {
        let input = format!("{}{}{}", lead, body, trail);
        let mut counter = DuplicateCounter::new();
        let slug = compute_slug(&input, &mut counter);
        let lead_hyphens = slug.chars().take_while(|&c| c == '-').count();
        prop_assert_eq!(
            lead_hyphens, lead.len(),
            "Rule 5 violation: {} leading spaces produced {} leading hyphens (expected 1:1, no trim) \
             in {:?} → {:?}", lead.len(), lead_hyphens, input, slug
        );
        if !trail.is_empty() {
            let trail_hyphens = slug.chars().rev().take_while(|&c| c == '-').count();
            prop_assert_eq!(
                trail_hyphens, trail.len(),
                "Rule 5 violation: {} trailing spaces produced {} trailing hyphens (expected 1:1, no trim) \
                 in {:?} → {:?}", trail.len(), trail_hyphens, input, slug
            );
        }
    }

    // Rule 6: CJK, Cyrillic, and Han characters (all \p{L}) are retained in output
    #[test]
    fn prop_vp026_rule6_unicode_word_retained(
        s in "[\\p{Han}\\p{Cyrillic}]{1,10}"
    ) {
        let mut counter = DuplicateCounter::new();
        let slug = compute_slug(&s, &mut counter);
        // Every input char is \p{L} and must appear in the slug (lowercased).
        // The slug must be non-empty and contain only the lowercased forms.
        prop_assert!(
            !slug.is_empty(),
            "Rule 6 violation: slug is empty for all-word-char input {:?}", s
        );
        // The lowercased input must appear as a substring of the slug
        // (hyphens may be inserted around it, but no chars should be dropped).
        let lowercased: String = s.chars().flat_map(|c| c.to_lowercase()).collect();
        prop_assert!(
            slug.contains(&lowercased),
            "Rule 6 violation: lowercased {:?} not found in slug {:?} (input {:?})",
            lowercased, slug, s
        );
    }

    // Rule 7: emoji are stripped (not present in output)
    #[test]
    fn prop_vp026_rule7_emoji_stripped(
        prefix in "[a-z]{1,8}",
        emoji in "[\u{1F300}-\u{1F9FF}]{1,3}"
    ) {
        let input = format!("{prefix}{emoji}");
        let mut counter = DuplicateCounter::new();
        let slug = compute_slug(&input, &mut counter);
        let has_emoji = slug.chars().any(|c| ('\u{1F300}'..='\u{1F9FF}').contains(&c));
        prop_assert!(
            !has_emoji,
            "Rule 7 violation: emoji present in slug {:?} from {:?}", slug, input
        );
    }
}

// DI-012 Rule 1b integration skeleton (Phase 3 — CAP-005/CAP-006 required)
// Rule 1b tests that the anchor table builder correctly renders heading text
// (inline code → text, HTML tags stripped) before passing to compute_slug.
// Cannot run until anchor_table::build_for_test() exists.
//
// #[test]  // integration — enable in Phase 3
// fn vp026_di012_rule1b_inline_code_html_end_to_end() {
//     // Source heading: ## `config` API <em>new</em>
//     // DI-012 Rule 1:
//     //   - Inline code span `config` → contributes text "config"
//     //   - HTML tag <em> stripped; visible text "new" retained
//     // Rendered text: "config API new" (lowercasing is slug step (b), not rendering)
//     // new GithubSlugger().slug("config API new") → "config-api-new"
//     let md = "## `config` API <em>new</em>\n";
//     let table = anchor_table::build_for_test(md);
//     assert!(
//         table.contains("config-api-new"),
//         "DI-012 Rule 1b: expected anchor 'config-api-new' from \
//          '## `config` API <em>new</em>'; got {:?}", table
//     );
// }
```

## Phase 3 Implementation Obligation

This VP MUST be implemented before Phase 6 hardening begins. It records a
pre-Phase-3 implementation contract so the story cannot silently skip it.

| Obligation | Detail |
|------------|--------|
| **Crate** | `mdlinkcheck-core` |
| **Test file** | `tests/proptest_slug_differential.rs` (flat layout — Cargo auto-discovers `tests/*.rs`) |
| **Oracle fixture** | `tests/fixtures/slug-oracle-vectors.json` |
| **Generator script** | `tools/gen-slug-oracle.js` (Node.js 22.x LTS, pinned `github-slugger@2.0.0`; uses stateful `new GithubSlugger()` per run) |
| **CI check** | `just regen-slug-vectors` then `jq` diff excluding `generated_at` and `node_version`; `github_slugger_version` and `generator_script_sha256` MUST be inside the diff scope (see §Constraint: No Live JS Dependency at Test Time) |
| **Provenance record** | Fixture embeds: `github_slugger_version`, generator script SHA-256, generation timestamp, Node.js version |
| **Phase 6 gate** | VP-026 must pass (green) before Phase 6 formal hardening can proceed |
| **Oracle coverage** | Runs R-001 through OR-010 (one per DI-012 rule, plus FM-002 discriminator, plus NFC/NFD); each run contains ≥1 entry |
| **FM-002 closure** | Run R-001 MUST contain ≥3 entries with identical base heading; the oracle values for entries 2 and 3 must be `setup-1` and `setup-2` (not `setup-2` and `setup-3`) |
| **NFC/NFD coverage** | Run R-009: NFC form (e.g., `"résumé"` → `"résumé"`); Run OR-010: NFD form (e.g., `"re\u{0301}sume\u{0301}"` → `"resume"`); outputs derived from adjudication in ADR-008 §NFC/NFD ruling |
| **Positive-coverage assertion** | `vp026_oracle_corpus_exact_match` MUST assert R-001..OR-010 all present, R-001 ≥3 entries, entries_checked ≥10; include `eprintln!` summary per POL-11 |
| **Integration skeleton** | `vp026_di012_rule1b_inline_code_html_end_to_end` (commented out) is enabled in Phase 3 story for CAP-005/CAP-006 integration |

**oracle_runs_required:** R-001 (FM-002, ≥3 entries), R-002 (rule 3, `AI & Automation`), R-003 (rule 1a, pre-rendered `"config API new"`), R-004 (rule 2, Unicode lowercase), R-005 (rule 4, underscore), R-006 (rule 5, leading/trailing spaces), R-007 (rule 6, CJK), R-008 (rule 7, emoji), R-009 (NFC accented Latin, e.g. `"résumé"`), OR-010 (NFD combining diacritics, e.g. `"re\u{0301}sume\u{0301}"`).

## Feasibility Assessment

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Oracle corpus generation | Feasible | `github-slugger@2.0.0` is a stable npm package; generator script is ~50 lines; generation is deterministic |
| Committed fixture size | Small (~5-10 KB) | 8 runs × ~5 entries average; JSON format |
| Test runtime | < 1s oracle; < 30s proptest | Oracle is a simple iteration; proptest bounded by strategy depth |
| Tool support | Full | `serde_json` for fixture loading; `proptest 1.x` for generator strategies; standard `nextest` runner |
| NFC/NFD edge case | Known asymmetry | NFD combining diacritics (\p{Mn}) are stripped by github-slugger v2; NFC accented chars (\p{L}) are retained; the oracle corpus must include both forms with their respective expected outputs; see provenance note |
| No live JS at test time | Enforced | Oracle is a committed fixture; `just regen-slug-vectors` CI check ensures fixture freshness |

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created (BI-005 spec-level closure) | 2026-08-06 | architect |
| Oracle fixture generated | — | implementer (Phase 3) |
| Proof harness committed | — | implementer (Phase 3) |
| Proof first passed | — | formal-verifier |
| Locked (VERIFIED) | — | formal-verifier |
