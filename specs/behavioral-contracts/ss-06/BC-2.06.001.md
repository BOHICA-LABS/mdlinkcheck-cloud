---
document_type: behavioral-contract
level: L3
version: "1.6"
status: draft
producer: vsdd-factory:product-owner
timestamp: 2026-08-10T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/specs/domain-spec/L2-INDEX.md
  - .factory/planning/brief-validation.md
  - .factory/planning/market-intelligence.md
input-hash: "07d983a"
traces_to: .factory/specs/domain-spec/L2-INDEX.md
origin: greenfield
extracted_from: null
subsystem: "SS-06"
capability: "CAP-006"
lifecycle_status: active
introduced: v1.0.0
modified:
  - "v1.6: (BI-052 remediation P7-S7-001/P7-S7-002) VP-002 rows corrected. VP-002 proves determinism (same input same output), not algorithm-correctness properties. The two prior VP-002 rows ('Space-to-hyphen is 1:1 trap T1' and 'Unicode word chars preserved trap T2') attributed algorithm-correctness claims to VP-002 which VP-002 cannot verify. Those claims are now attributed to VP-026 (differential oracle). An explicit VP-002 row added for the determinism property that VP-002 actually proves."
  - "v1.5: (WS-4-B) Citation-authority repair: L2 Capability row — fabricated excerpt 'Compute heading anchor slugs using the pinned github-slugger v2 algorithm' (invented paraphrase, not in capabilities.md) replaced with verbatim title 'Heading Slug Computation'; gloss moved outside quotes. Proof-method join: split combined VP-001/VP-018 row into two rows (VP-001 'unit test' → 'kani'; VP-018 'unit test' → 'unit'); VP-002 rows 'unit test' → 'kani'; VP-026 'differential oracle' → 'proptest' (all per VP-INDEX authority)."
  - "v1.4: (P4-001) Corrected Invariant 2: HTML element visible text IS retained (ADR-008 §HTML-Text Rendering Adjudication, DI-012 rule 1). Supersedes v1.1 Invariant-2 entry which stated the opposite. (EC-collision) EC-060→EC-190 (EC-060 canonical owner is BC-2.08.001 per test-vectors.md registry). (C4-003/C4-006) L2 Domain Invariants DI-008→DI-012; VP-026 added to Verification Properties."
  - "v1.3: (INC-MAP) Architecture Module field added per bc-module-map.md (architect, Phase 1b)"
  - "v1.2: (F-029) fixed PC2 self-contradiction (split into non-empty and empty-heading cases); added PC3 stating counter is keyed on computed slug; added emoji-collision edge cases EC-059/EC-060"
  - "v1.1: clarified Invariant 2 — code-span TEXT is included in rendered text; HTML element text is NOT included; disambiguates heading title vs rendered text content per NOTE-4 in feasibility-review.md"
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.06.001: github-slugger v2 Core Algorithm

## Description
Heading slugs are computed using the github-slugger v2 algorithm exactly as documented in
market-intelligence §4.1. The five-step process produces a lowercase, hyphenated slug from the
rendered text of a heading. The implementation MUST be byte-for-byte identical to github-slugger
v2 output for all inputs in the test vector corpus.

## Preconditions
1. A heading's rendered text content is available (inline markup stripped, just text nodes).
2. The slug function is called with the rendered text as input.

## Postconditions
1. The output slug satisfies all five steps:
   a. Input is the rendered text content (inline code spans, bold, etc. stripped to text nodes).
   b. `str::to_lowercase()` applied (full Unicode, not ASCII-only).
   c. Characters that are not `\p{Word}`, not `-`, not ` ` (U+0020) are removed.
   d. Each U+0020 space is replaced with `-` (1:1 mapping; no run collapsing; no trimming).
   e. Per-file duplicate counter applied (see BC-2.06.002). **The counter is keyed on the
      result of steps (b)–(d) — the computed slug string, NOT the original heading text.**
2. For any heading with at least one character surviving steps (b)–(d), the slug is a
   non-empty string.
3. For headings whose text yields an empty string after steps (b)–(d) (e.g., headings
   containing ONLY punctuation such as `## !!!`): the slug is `""` (empty string); an
   empty-string anchor entry is added to the anchor table for compatibility with
   github-slugger v2 behavior.
4. The slug for `## Hello, World!` is `"hello-world"` (comma removed, space→hyphen).
5. The slug for `## C++ Guide` is `"c-guide"` (both `+` chars removed).
6. The slug for `## 日本語` is `"日本語"` (\p{Word} includes Unicode letters).

## Invariants
1. No regex is used that differs from the algorithm; the algorithm is transcribed exactly.
2. The slug input is the heading's **rendered text content** — the concatenation of text nodes
   from the AST event stream, with inline markup stripped as follows:
   - **Bold / italic / links / images:** their TEXT NODE content IS included; only the markup
     syntax (asterisks, underscores, brackets) is discarded.
   - **Code spans (inline code):** the text node inside the backtick span IS included in the
     rendered text; only the backtick markup is discarded. A heading `` ## `foo` bar `` yields
     rendered text `"foo bar"` → slug `"foo-bar"`.
   - **HTML elements:** Tag markup tokens (e.g., `<kbd>`, `</kbd>`) are stripped; the
     visible TEXT CONTENT between the tags IS retained. A heading `## <kbd>Ctrl+C</kbd>`
     yields rendered text `"ctrlc"` → slug `"ctrlc"`. This matches pulldown-cmark's
     InlineHtml event model (ADR-003): `InlineHtml("<kbd>")` carries only the tag bytes;
     the text "Ctrl+C" arrives as a separate `Text` event and is retained.
     DI-012 rule 1: "HTML tags contribute nothing (tag tokens are stripped; their visible
     text content, if any, is retained)."
3. The space→hyphen step is 1:1 (a heading `## A  B` with two spaces produces `"a--b"`, NOT `"a-b"`).

## Edge Cases
| EC | Description |
|----|-------------|
| EC-043 | `## Hello World` |
| EC-044 | `## C++ Guide` |
| EC-045 | `## 日本語` |
| EC-046 | `## **Bold** Heading` |
| EC-047 | `## A  B` (two spaces) |
| EC-048 | `##` (empty heading) |
| EC-059 | `## 🦀Rust` (emoji directly adjacent to word) |
| EC-190 | `## 🦀Rust` followed by `## 🎯Rust` |

## Canonical Test Vectors
| Input (heading text) | Expected Slug | Source |
|---------------------|---------------|--------|
| "Hello World" | "hello-world" | DD-015 #1 |
| "C++ Guide" | "c-guide" | DD-015 #2 |
| "日本語 heading" | "日本語-heading" | DD-015 #3 |
| "A  B" (2 spaces) | "a--b" | DD-015 #4 |
| "" (empty) | "" | DD-015 #5 |
| "🦀Rust" | "rust" | EC-059 — emoji stripped, remaining word chars slugged |
| "🦀Rust" then "🎯Rust" | "rust", "rust-1" | EC-190 — emoji-collision; counter keyed on "rust" |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-001 | Slug function is total — terminates without panic for any input | kani |
| VP-002 | compute_slug is deterministic — same input with same counter initial state produces identical output | kani |
| VP-018 | All DD-015 worked examples produce correct slugs | unit |
| VP-026 | Space-to-hyphen is 1:1 (trap T1); Unicode word chars preserved (trap T2); differential oracle against github-slugger@2.0.0 | proptest |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-006 ("Heading Slug Computation") per capabilities.md §CAP-006 — verbatim github-slugger v2 algorithm with 0-based duplicate counter |
| Capability Anchor Justification | CAP-006 ("Heading Slug Computation") per capabilities.md §CAP-006 — this BC is the core slug algorithm contract |
| L2 Domain Invariants | DI-012 (slug computation fidelity — all 7 rules) |
| Brief Requirement | R2b, DD-015 |
| Architecture Module | `slug.rs` (SS-06, pure core, CRITICAL tier) — ADR-008 (clean-room github-slugger v2 reimplementation — slug algorithm is the primary differentiator) |

## Related BCs
- BC-2.06.002 — composes with (duplicate-heading counter)
- BC-2.05.002 — depends on this (anchor table uses these slugs)
