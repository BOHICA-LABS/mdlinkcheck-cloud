---
document_type: behavioral-contract
level: L3
version: "1.3"
status: draft
producer: vsdd-factory:product-owner
timestamp: 2026-08-05T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/specs/domain-spec/L2-INDEX.md
  - .factory/planning/brief-validation.md
  - .factory/planning/market-intelligence.md
input-hash: "e860246"
traces_to: .factory/specs/domain-spec/L2-INDEX.md
origin: greenfield
extracted_from: null
subsystem: "SS-06"
capability: "CAP-006"
lifecycle_status: active
introduced: v1.0.0
modified:
  - "v1.1: clarified Invariant 2 — code-span TEXT is included in rendered text; HTML element text is NOT included; disambiguates heading title vs rendered text content per NOTE-4 in feasibility-review.md"
  - "v1.2: (F-029) fixed PC2 self-contradiction (split into non-empty and empty-heading cases); added PC3 stating counter is keyed on computed slug; added emoji-collision edge cases EC-059/EC-060"
  - "v1.3: (INC-MAP) Architecture Module field added per bc-module-map.md (architect, Phase 1b)"
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
   - **HTML elements:** NEITHER the tag markup NOR the text content inside HTML elements
     contributes to the rendered text. A heading `## <kbd>Ctrl+C</kbd>` yields rendered text
     `""` (empty). This distinction between "code span includes text" and "HTML element excludes
     text" matches github-slugger v2 / GitHub's rendering behavior.
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
| EC-060 | `## 🦀Rust` followed by `## 🎯Rust` |

## Canonical Test Vectors
| Input (heading text) | Expected Slug | Source |
|---------------------|---------------|--------|
| "Hello World" | "hello-world" | DD-015 #1 |
| "C++ Guide" | "c-guide" | DD-015 #2 |
| "日本語 heading" | "日本語-heading" | DD-015 #3 |
| "A  B" (2 spaces) | "a--b" | DD-015 #4 |
| "" (empty) | "" | DD-015 #5 |
| "🦀Rust" | "rust" | EC-059 — emoji stripped, remaining word chars slugged |
| "🦀Rust" then "🎯Rust" | "rust", "rust-1" | EC-060 — emoji-collision; counter keyed on "rust" |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-001, VP-018 | All DD-015 worked examples produce correct slugs | unit test (NFR-006) |
| VP-002 | Space→hyphen is 1:1 (trap T1) | unit test |
| VP-002 | Unicode word chars preserved (trap T2) | unit test |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-006 ("Compute heading anchor slugs using the pinned github-slugger v2 algorithm") per capabilities.md §CAP-006 |
| Capability Anchor Justification | CAP-006 ("Heading Slug Computation") per capabilities.md §CAP-006 — this BC is the core slug algorithm contract |
| L2 Domain Invariants | DI-008 |
| Brief Requirement | R2b, DD-015 |
| Architecture Module | `slug.rs` (SS-06, pure core, CRITICAL tier) — ADR-006 (NFC strict path model; slug algorithm is the primary differentiator) |

## Related BCs
- BC-2.06.002 — composes with (duplicate-heading counter)
- BC-2.05.002 — depends on this (anchor table uses these slugs)
