---
document_type: gene-transfusion-assessment
level: L3
version: "1.0"
status: draft
producer: architect
timestamp: 2026-08-05T00:00:00Z
phase: 1b
inputs:
  - .factory/specs/product-brief.md
  - .factory/specs/domain-spec/capabilities.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/domain-spec/risks.md
  - .factory/planning/market-intelligence.md
input-hash: "990f7ae"
traces_to: architecture/ARCH-INDEX.md
---

# Gene Transfusion Assessment: mdlinkcheck

## Summary

| Metric | Value |
|--------|-------|
| Modules assessed (CAP-001 through CAP-014 implied capabilities) | 8 logical modules |
| Algorithm transfusion candidates | 1 (GitHub slug algorithm → `slug` module) |
| Architectural pattern models | 3 (two-pass anchor index; URL deduplication; three-outcome classification) |
| Test corpus genes (incumbent bugs mapped to acceptance fixtures) | 11 |
| CommonMark spec suite: vendor? | No — derive test cases covering relevant constructs |
| Estimated story-point savings from slug spec (vs. rediscovering algorithm) | 3–5 |
| Estimated story-point savings from bug corpus (vs. discovering these cases from scratch) | 8–10 |
| Languages involved | JavaScript → Rust (slug algorithm) |
| Human decision items | 2 (see Section 6) |

---

## Candidate Analysis

Detailed candidate analysis is presented in the numbered sections below: §1 (Algorithm Transfusion), §2 (Test Corpus Genes), §3 (Architectural Pattern Models), and §4 (Anti-Genes). The §1 candidate factor table is the primary per-candidate evaluation.

## Section 1: Algorithm Transfusion — GitHub Slug Algorithm

### 1.1 Provenance and Licensing

The GitHub heading-anchor algorithm has two reference implementations:

**html-pipeline v2** (`lib/html/pipeline/toc_filter.rb`)
- License: MIT
- Copyright holder: GitHub / gjtorikian
- Key artifact: `PUNCTUATION_REGEXP = RUBY_VERSION > '1.9' ? /[^\p{Word}\- ]/u : /[^\w\- ]/`
- Source: https://github.com/gjtorikian/html-pipeline/blob/v2.14.3/lib/html/pipeline/toc_filter.rb

**github-slugger v2** (`index.js`)
- License: ISC
- Copyright holder: Flet (2015)
- ISC license text (verbatim obligation): "provided that the above copyright notice and this permission notice appear in **all copies**"
- Source: https://github.com/Flet/github-slugger

### 1.2 Licensing Position: Clean-Room Reimplementation

**The ISC and MIT "all copies" obligation applies to copies of the software, not to independent reimplementations of the algorithm.**

The legal basis:

1. **Algorithms are not copyrightable under US copyright law** (Baker v. Selden, 101 U.S. 99 (1879); affirmed in software context). The 5-step behavioral spec documented in market-intelligence §4.1 describes an algorithm (a mathematical function from heading text to slug string). That description is a specification of behavior, not copyrightable expression.

2. **Character class `[^\p{Word}\- ]` is a mathematical set**, not creative expression. It describes "all Unicode codepoints that are not word characters, hyphens, or spaces." Implementing this set membership test in Rust using `char::is_alphanumeric()`, `'_'`, `'-'`, `' '` is an independent implementation of a concept.

3. **The duplicate-counter pattern** (increment a per-slug counter, append `-N` for Nth duplicate) is an obvious, common algorithm for disambiguation. Implementing it from scratch in Rust requires no reference to the JS source.

4. **The ISC "copies" trigger is not met** by a Rust implementation that: (a) was written without looking at the JS function body during coding; (b) implements behavior from the published behavioral spec in market-intelligence §4.1; (c) shares no source code lines with `index.js`.

**Result: No mandatory copyright attribution in NOTICE or README for a clean-room Rust reimplementation.**

However, **source-level citation is strongly recommended** as engineering hygiene — it explains where the algorithm comes from, enables future maintainers to verify conformance, and acknowledges the ecosystem work. The recommended comment is:

```rust
/// Computes a GitHub-compatible heading anchor slug.
///
/// Algorithm specification: html-pipeline v2 (MIT, GitHub/gjtorikian) and
/// github-slugger v2 (ISC, Flet). This is a clean-room Rust implementation
/// from the published behavioral specification documented in
/// `.factory/planning/market-intelligence.md §4.1`. No source code was copied
/// from either reference implementation.
///
/// Known divergences from GitHub's live rendering (accepted limitations):
/// - U+200C (ZWNJ) and U+200D (ZWJ): github-slugger strips them; this
///   implementation strips them (matching slugger, diverging from GitHub).
/// - percent-encoding: slugs are raw Unicode; incoming fragment refs with
///   percent-encoding must be decoded before comparison.
```

### 1.3 Candidate Factor Table

| Factor | Assessment |
|--------|-----------|
| Reference | github-slugger v2 (`index.js`) + html-pipeline v2 (`toc_filter.rb`) |
| Source language | JavaScript / Ruby |
| Target language | Rust |
| License | ISC (github-slugger) / MIT (html-pipeline) — both permissive; "all copies" obligation not triggered by clean-room reimplementation |
| Test coverage (reference) | github-slugger ships a test suite; exact count not retrieved, but the worked examples in market-intel §4.1 cover the critical edge cases |
| Last maintained | github-slugger: actively maintained, used by remark/markdownlint. html-pipeline v2: superseded by v3 (which no longer contains the slug logic), but v2 algorithm is stable and is the normative reference |
| Known vulnerabilities | None in the slug algorithm itself |
| Translation complexity | LOW — the algorithm is 5 deterministic steps, pure function, no I/O, no state except per-document duplicate counter |
| Paradigm gap | Small — JS to Rust is straightforward for a pure string-transform function |
| Estimated from-scratch effort | 3–5 story points (would require rediscovering the exact algorithm from GitHub behaviour) |
| Estimated transfusion effort | 1–2 story points (algorithm fully specified in market-intel §4.1) |
| Recommendation | YES — reimplement from behavioral spec |
| Justification | Algorithm is the product's #1 differentiator (DI-002, CAP-006, R-001). Reinventing it without the spec would produce exactly the slug fidelity drift that causes every competitor's bugs (MkDocs #3923, Sphinx #11542, markdownlint MD051 #945). The behavioral spec is complete and verified with worked examples. |

### 1.4 Implementation Constraints

The Rust implementation MUST:

1. Accept the heading's **rendered text content** (not raw Markdown source). The caller (heading extractor) must strip all markup and concatenate only text nodes. Inline code content is kept as text; HTML tags are dropped.
2. Apply `str::to_lowercase()` — NOT `to_ascii_lowercase()`. Market-intel §4.1 explicitly verifies that full Unicode lowercasing is required and that Rust's `to_lowercase()` matches github-slugger's `toLowerCase()`.
3. Keep exactly the characters satisfying: `char::is_alphanumeric() || c == '_' || c == '-' || c == ' '`. This is the Rust equivalent of `\p{Word}` (which covers alphanumeric + `_` + combining marks in Unicode terms). Note: for full Unicode `\p{Word}` fidelity, Unicode combining marks (category `M*`) should also be kept — verify with the `unicode-properties` or equivalent approach, or check that `char::is_alphanumeric()` covers all `\p{Word}` codepoints used in practice. If gaps exist, use the `unicode-general-category` crate.
4. Replace each space with a hyphen, 1:1, with NO run collapsing and NO leading/trailing trim.
5. Maintain a per-file duplicate counter keyed on original slugs. First occurrence: no suffix. Second: `-1`. Third: `-2`.

The `slug` module (or function) MUST be isolated as a pure function with no I/O, no global state, taking `&str` → `String`. This makes it amenable to property-based testing and Kani proof harnesses (VP candidates: "slug is deterministic", "slug of empty string is empty string", "duplicate counter never produces collisions for valid document inputs").

### 1.5 Attribution Disposition

| Location | Action | Reason |
|----------|--------|--------|
| Source comment on the slug function | Cite github-slugger + html-pipeline as specification references | Engineering hygiene; enables future maintainers to verify algorithm fidelity |
| NOTICE file | No entry required | Clean-room reimplementation; ISC/MIT "copies" trigger not met |
| README | Recommended mention in "Algorithm" section | Transparency to users about GitHub compatibility and the upstream specification |
| Cargo.toml dependency | No entry | Not importing any code |

---

## Section 2: Test Corpus Genes

### 2.1 Incumbent Bug Reports as Acceptance Corpus Fixtures

**Transfusion mode: Adopt — these are free, adversary-authored test cases.**

Each open bug in an incumbent tool is a documented real-world input that caused incorrect behavior. Treating these as named acceptance fixtures is the cheapest quality investment in the project. The fixture names below are suggested canonical names for the acceptance corpus.

| Bug | Tool | Failure Class | Fixture Name | T-trap from §4.3 |
|-----|------|---------------|--------------|-------------------|
| lychee [#1457](https://github.com/lycheeverse/lychee/issues/1457) | lychee 0.24.x | False negative: local file anchor validated as "present" when the slug algorithm differs between local check and GitHub rendering | `corpus/lychee-1457-anchor-false-negative.md` | T14/R-001 |
| lychee [#1613](https://github.com/lycheeverse/lychee/issues/1613) | lychee 0.24.x | False negative: anchor-only self-fragment (`#section-in-same-file`) silently passes or is skipped | `corpus/lychee-1613-self-fragment.md` | T15 (two-pass, same-file) |
| lychee [#1709](https://github.com/lycheeverse/lychee/issues/1709) | lychee 0.24.x | Resource exhaustion: local fragment checks open file handles without closing, producing "too many open files" on large repos | `corpus/lychee-1709-open-files.md` (large fixture set) | DI-009 (termination invariant) |
| markdown-link-check [#304](https://github.com/tcort/markdown-link-check/issues/304) | mlc 3.x | Multiple anchor edge cases: heading containing link syntax (raw source used instead of text content), Chinese/CJK headings, trailing whitespace in heading text | `corpus/mlc-304-heading-link-syntax.md`, `corpus/mlc-304-cjk-heading.md`, `corpus/mlc-304-trailing-whitespace.md` | T14, Unicode slug fidelity |
| markdown-link-check [#91](https://github.com/tcort/markdown-link-check/issues/91) | mlc 3.x | Anchor validation regression — CI anchor test bypass in version 3.12; tool reported anchors as valid even when anchor checking was not running | `corpus/mlc-91-anchor-regression-bypass.md` | Test-infrastructure: verifying that anchor checking runs (meta-fixture) |
| Sphinx [#13620](https://github.com/sphinx-doc/sphinx/issues/13620) | Sphinx 7.x | False "Anchor not found": percent-encoded fragment (`%23`, `%2F`, non-ASCII percent sequences) not decoded before comparing against raw Unicode slug | `corpus/sphinx-13620-percent-encoded-fragment.md` | T9 (fragment decode before comparison), DI-003 |
| Sphinx [#11542](https://github.com/sphinx-doc/sphinx/issues/11542) | Sphinx 7.1 | Valid GitLab/Framagit anchors rejected after Sphinx 7.1 algorithm change — slug generation diverged from GitHub's algorithm for special characters | `corpus/sphinx-11542-slug-algorithm-drift.md` | R-001 (algorithm fidelity), MkDocs #3923 |
| mkdocs-htmlproofer [#64](https://github.com/manuzhang/mkdocs-htmlproofer-plugin/issues/64) | mkdocs-htmlproofer | False 404: emoji-containing headings. GitHub slug: `😄 emoji` → `-emoji` (emoji stripped, leading hyphen preserved, no trim). Tools that strip the leading hyphen or apply a different emoji policy will mismatch | `corpus/htmlproofer-64-emoji-heading.md` | T14, slug algorithm (emoji handling) |
| MkDocs [#3690](https://github.com/mkdocs/mkdocs/issues/3690) | MkDocs 1.6 native anchor | False positives from special characters in headings (e.g. `C++ / C#` → `c--c`, not `c-c`; pipes, backslashes mishandled) | `corpus/mkdocs-3690-special-chars.md` | T9/T14, worked example `C++ / C#` → `c--c` |
| MkDocs [#3923](https://github.com/mkdocs/mkdocs/issues/3923) | MkDocs 1.6 native anchor | GitHub-slug algorithm divergence: MkDocs native checker used a different slugging rule than GitHub, producing false positives for headings with punctuation | `corpus/mkdocs-3923-slug-divergence.md` | R-001, R-002 (slug fidelity is the differentiator) |
| markdownlint MD051 [#945](https://github.com/DavidAnson/markdownlint/issues/945) | markdownlint MD051 | False positive: heading itself contains link syntax (e.g., `## See [the docs](x)`). Correct slug uses text content `see-the-docs`; incorrect implementation uses raw source `see-[the-docs](x)` or drops the content | `corpus/markdownlint-945-heading-with-link.md` | T14 (heading text extraction, not raw source) |

**Count: 11 incumbent bugs mapped to 13 named acceptance-corpus fixtures** (markdown-link-check #304 decomposes into 3 fixtures covering distinct sub-cases).

**Licensing note:** Bug report content (issue text, linked reproducer snippets) is publicly available under GitHub's Terms of Service for the purpose of interoperability. The fixture Markdown files we write are original works authored by this project; they *implement* the scenario described in the bug but contain no copied code or prose from the issue threads. No attribution is required.

**Urgency:** Fixtures for T9 (Sphinx #13620, DI-003), T14 (markdownlint #945, mlc #304), and T15 (lychee #1613) map directly to risks R-001 and R-002 (HIGH impact). These fixtures must exist before the acceptance corpus gate is declared complete.

### 2.2 CommonMark Spec Test Suite

**Transfusion mode: Leave Behind (formal vendoring) — Derive instead.**

**Assessment:**

- The CommonMark spec (`spec.commonmark.org/0.31.2/spec.json`) contains ~652 test cases. The spec document itself is under CC BY SA 4.0.
- CC BY SA 4.0 is a copyleft license that requires derivative works to be distributed under the same license. **Vendoring the spec.json into our test suite and distributing it would create a share-alike obligation** — our test fixtures would need to be CC BY SA 4.0, which conflicts with the intended MIT/Apache-2.0 license for the project.
- More importantly: the question is not "does pulldown-cmark implement CommonMark?" (it does — it passes the CommonMark spec suite in its own CI). The question is "does our extraction layer correctly identify links, headings, and code contexts?" This is a narrower question about **our use of pulldown-cmark**, not about pulldown-cmark itself.

**What we need from the CommonMark spec:**
Not all 652 cases. We need cases covering exactly:
1. Inline links, reference-style links (full, collapsed, shortcut), images — confirming correct `Tag::Link` / `Tag::Image` event emission
2. Code fences (backtick, tilde), inline code spans (single, double backtick), indented code blocks — confirming links inside are NOT emitted (DI-004)
3. Heading levels 1–6 — confirming `Tag::Heading` events carry the correct text content
4. Reference definition resolution — confirming `LinkType::ReferenceUnknown` / `CollapsedUnknown` / `ShortcutUnknown` appear correctly for undefined refs (T5)

These are approximately 20–30 targeted test cases that we write from scratch, inspired by CommonMark spec scenarios but not copied verbatim. Writing them takes less effort than understanding which of the 652 spec cases are relevant and vendoring them under a compatible license.

**GFM extension cases:** pulldown-cmark supports a configurable set of GFM extensions. For `mdlinkcheck`, we need: (1) GFM tables (no links in table syntax itself — verify headers and cells are parsed correctly), (2) GFM autolinks (see §4.2 caveat: bare URLs not supported, already out-of-scope), (3) nested brackets in link text (T7). Write 5–10 targeted cases.

**Recommendation:** Do NOT vendor `spec.commonmark.org/spec.json`. Write 25–35 original test fixtures covering the extraction constructs relevant to `mdlinkcheck`. These are original works; no CC BY SA obligation arises.

**HUMAN DECISION FLAG (HD-001):** If the project later wants to formally claim CommonMark conformance (beyond pulldown-cmark's own claim), vendoring spec.json under CC BY SA 4.0 and complying with the share-alike obligation is the path. This is a project-scope and licensing decision that a human must make. The current recommendation defers that decision.

---

## Section 3: Architectural Pattern Models

These are design patterns studied from existing tools and consciously adopted. No code is copied; patterns are not copyrightable.

### 3.1 Two-Pass Anchor Index (from remark-validate-links, lychee)

**Source:** remark-validate-links (MIT, remarkjs; archived 2026-06-04), lychee (Apache-2.0 OR MIT)
**Mode:** Model
**What is taken:** The architectural pattern of fully building the anchor table for every target file before validating any link into that file. This eliminates false negatives for forward heading references (T15, DI-008).
**Attribution obligation:** None. Design patterns are not copyrightable.
**Already captured in domain spec:** DI-008 ("Anchor Table Built Before Any Incoming Link Is Validated") is already a domain invariant. This entry documents the provenance of that invariant.
**Risk if wrong:** markdown-link-check has an open bug for forward-reference false negatives because it uses a single-pass design. A single-pass design is architecturally incorrect for this problem.

### 3.2 URL Deduplication (from lychee)

**Source:** lychee (Apache-2.0 OR MIT)
**Mode:** Model
**What is taken:** The architectural pattern of deduplicating external URLs before dispatching HTTP checks — each unique URL is checked once regardless of how many links point to it. Results are memoized and reused.
**Attribution obligation:** None. The pattern is standard memoization applied to HTTP dispatch.
**Scope constraint:** `mdlinkcheck` does not cache across runs (BRIEF non-goal: no config file, no persistent cache). Deduplication applies only within a single invocation's `--online` batch.
**Implementation note:** A `HashMap<Url, Verdict>` keyed on the normalized URL is sufficient. Normalization: lowercase scheme and host, remove default ports, no query/fragment normalization needed (fragment is split before URL parsing per DI-003).

### 3.3 Three-Outcome Classification — Indeterminate (from linkinator)

**Source:** linkinator (Apache-2.0, JustinBeckwith)
**Mode:** Model (already captured independently)
**What is taken:** The classification of HTTP responses into `alive` / `broken` / `indeterminate` rather than a binary. `indeterminate` covers 429, confirmed bot-blocking (403/999 after GET retry), and transport-level failures — conditions where the tool cannot establish that the target is absent.
**Attribution obligation:** None. The three-outcome classification is a logical consequence of the problem domain (you cannot distinguish "link broken" from "server rejecting automation") and was arrived at independently by the domain spec analysis.
**Already captured in domain spec:** DI-010, DI-005, CAP-010. This entry documents the provenance for future maintainers.

---

## Section 4: Anti-Genes — Patterns to Explicitly Reject

These patterns appear in incumbent tools and must not be adopted. Each has a concrete rationale.

| Anti-Gene | Source | Rationale for Rejection |
|-----------|--------|------------------------|
| **Exit codes: 2=link failure, 1=runtime failure** | lychee 0.24.2 | Directly inverted from BRIEF R7 (1=broken, 2=I/O error). BRIEF R7 is frozen. Adopting lychee's scheme would require changing a frozen requirement. Risk R-006 documents the confusion hazard; mitigation is documentation, not scheme adoption. |
| **Post-render HTML checking** | htmltest, muffet, Sphinx linkcheck, mkdocs-htmlproofer | Structurally cannot produce `file:line` in the Markdown source — reports point at generated HTML files, not the `.md` the author edits. Requires a build step or a running HTTP server. Incompatible with offline-first and source-level reporting (R6, CAP-012). This structural failure is what differentiates `mdlinkcheck` from half the field. |
| **Regex-based link extraction** | mkdocs-linkcheck, awesome_bot, early versions of tools | Known failure vectors: (1) extracts URLs from fenced code blocks and inline code spans (false positives; DI-004 is an absolute invariant); (2) mishandles escaped brackets `\[not a link\]` (T6); (3) mishandles nested brackets (T7); (4) mishandles angle-bracket destinations with spaces (T8). AST-based extraction (pulldown-cmark) satisfies DI-004 by construction. |
| **Anchor checking opt-in** | lychee (`--include-fragments` flag) | `mdlinkcheck`'s primary differentiator is anchor checking **on by default**. Making it opt-in reproduces the exact gap that leaves heading rot undetected in every lychee installation that doesn't pass `--include-fragments`. |
| **Code-fence exclusion opt-in** | lychee (`--include-verbatim` opts IN to scanning verbatim blocks) | DI-004 is an absolute invariant, not a configuration option. The BRIEF's own inline code spans (e.g., `[x](docs/a.md)`) demonstrate why — `mdlinkcheck BRIEF.md` must not fail. |
| **GET fallback limited to 405 only** | BRIEF R2c (original wording) | Decision DD-016 widened the fallback set to `{400, 403, 404, 405, 501, 999}` plus transport failures, based on market-intelligence §4.4 evidence. The original "405 only" wording is itself an anti-gene: it produces exactly the CI false positives the brief exists to prevent (Optimizely support article, Sphinx #9306). |
| **HEAD-only checking without fallback** | mkdocs-linkcheck (documented HEAD false positives in its own README) | Tool's own README states HEAD checks "produce false positives." Market-intelligence §2 documents this systematically. Any implementation that sends HEAD and trusts the result without GET fallback for specific status codes will inherit this class of false positives. |
| **Accepting 429 as valid** | lychee troubleshooting page ("last resort: accept 429 as valid") | This converts the tool from a link checker into a CI-green machine. The correct classification of 429 is `indeterminate` (DI-010), which appears in the report but does not trigger exit 1. |
| **Config file** | lychee `.lychee.toml` | Explicit BRIEF non-goal: "no config file (flags only)." A config file also introduces a portability concern in CI (checked in vs default vs override). The flags-only design is the explicit product decision. |
| **Per-host token-bucket concurrency with 128 concurrent slots** | lychee (default `--max-concurrency 128`) | Overkill for `mdlinkcheck`'s `--online` mode, which is explicitly a best-effort batch over a bounded set of links. Simple rayon thread pool with a reasonably low ceiling (e.g., 8–16 for network work) is sufficient and avoids triggering rate limiting more aggressively. |
| **{#custom-id} / kramdown heading IDs as GitHub-valid anchors** | MkDocs, pandoc | `{#custom-id}` is not GitHub Markdown. The domain spec (market-intel §4.1) records this as an explicit limitation. Supporting it would require a different anchor table construction logic and a feature flag. Out of scope for the initial product. |

---

## Modules Without Candidates

_See Section 5 below for the full table of modules that have no transfusion candidate._

## Section 5: Modules Without Gene Transfusion Candidates

| Module | Reason no transfusion applies |
|--------|-------------------------------|
| File discovery (CAP-001) | Satisfied by `ignore` 0.4.33 as a direct dependency. No algorithm transfusion — we call the library's API. |
| Markdown parsing (CAP-002) | Satisfied by `pulldown-cmark` 0.13.4 as a direct dependency. pulldown-cmark already implements CommonMark. Our layer wraps it, not reimplements it. |
| Link extraction (CAP-003, CAP-004) | Simple event-stream matching over pulldown-cmark output. No reference algorithm exists; the logic is derived directly from the `LinkType` and `Tag` variants documented in market-intel §4.2. |
| Path resolution + anchor resolution (CAP-007, CAP-008) | URL/filesystem operations composed from standard Rust `std::path`, `percent-encoding` crate, and directory-entry comparison. No complex algorithm. |
| External URL liveness checking (CAP-010) | HTTP HEAD/GET using `ureq` 3.3.0. The `Retry-After` parsing and per-host rate-limiting patterns are documented specs (RFC 9110), not algorithms with reference implementations. Architecture drawn from market-intel §4.4. |
| Text and JSON reporting (CAP-012, CAP-013) | Trivial formatter over verdict multiset. `serde_json` 1.0.151 handles serialization. No transfusion candidate. |
| Exit code determination (CAP-014) | Three-line pure function over verdict types. No reference algorithm. |
| Percent-fragment splitting (DI-003) | Simple string scan for first unescaped `#`. No reference algorithm. The rule is from the URL specification, not a library. |

---

## Section 6: Human Decision Items

### HD-001 — CommonMark CC BY SA 4.0 and Formal Conformance Claim

**Decision needed:** If `mdlinkcheck` ever wants to formally claim CommonMark link-extraction conformance by running the official spec test suite, spec.json is CC BY SA 4.0. Running the spec tests requires vendoring the test data, which creates a share-alike obligation on the test artifacts.

**Options:**
1. (Current recommendation) Do not vendor spec.json; write 25–35 original test cases covering link/heading/code-context constructs. No CC BY SA obligation. `mdlinkcheck` can claim "tested against CommonMark link constructs" but not "passes the official CommonMark test suite."
2. Vendor spec.json; release the test suite (not the production code) under CC BY SA 4.0. This is compatible with the production code being MIT/Apache-2.0 — the license obligation applies only to the test data compilation.
3. Reference the CommonMark test suite in CI via a network fetch without vendoring. Avoids the distribution question but creates a CI dependency on external availability.

**This is a licensing judgment call for a human.** Option 1 is recommended for the pilot scope and requires no legal review. Options 2 or 3 should involve a human with legal context before adoption.

### HD-002 — GitHub Slug Algorithm: README/NOTICE Attribution Beyond Source Comments

**Decision needed:** The clean-room reimplementation analysis above concludes that no attribution is legally required in NOTICE or README. However, some projects and organizations choose to include acknowledgment lines ("Algorithm based on the github-slugger specification") as a matter of culture, honesty, and community goodwill.

**Options:**
1. (Current recommendation) Source comment only (see §1.4 template). No NOTICE entry. README mentions "GitHub-compatible slug algorithm" without citing github-slugger.
2. README "Algorithm" section explicitly cites github-slugger (ISC) and html-pipeline (MIT) as specification references. No NOTICE entry required since we're citing a spec, not distributing code.
3. NOTICE entry treating it as a "derived work of the specification." This is legally conservative but not required.

**This is a project culture and community decision for a human.** Option 2 (README citation, no NOTICE) is recommended — it is transparent, accurate, and requires no legal counsel.

---

## Transfusion Summary Table

| Source | License | Mode | What Is Taken | Attribution Obligation | Risk if Wrong |
|--------|---------|------|---------------|----------------------|---------------|
| github-slugger v2 (Flet) | ISC | Reimplement (clean-room from behavioral spec) | 5-step algorithm spec: lowercase → strip non-word → replace spaces → deduplicate | Source comment citation only; no NOTICE/README entry required | Slug fidelity drift causes every anchor check to be wrong — primary differentiator failure |
| html-pipeline v2 (GitHub/gjtorikian) | MIT | Reimplement (clean-room from behavioral spec) | `\p{Word}` character class semantics for the keep-set | Source comment citation only | Same as above |
| Incumbent bug reports (11 bugs, 5 tools) | Public bug tracker content | Adopt as fixture scenarios | 13 named acceptance-corpus scenarios | None — original fixture files are our own work | Each unfixture'd bug is a class of correctness failure that went undetected in every incumbent tool |
| Two-pass anchor index pattern (remark-validate-links, lychee) | MIT / Apache-2.0 OR MIT | Model | Architectural pattern: build all anchor tables before validating any link into them | None | Forward-reference false negatives (T15); documented mlc bug class |
| Three-outcome classification (linkinator) | Apache-2.0 | Model | `alive` / `broken` / `indeterminate` verdict taxonomy | None | Binary classification produces false positives from 429/bot-blocking |
| URL deduplication within a run (lychee) | Apache-2.0 OR MIT | Model | Memoize HTTP check results by normalized URL | None | Duplicate requests, wasted time, increased rate-limiting risk |
| CommonMark spec test suite | CC BY SA 4.0 | Leave Behind (derive instead) | — test case scenarios inspire our original fixtures | N/A — we do not vendor | Vendoring creates CC BY SA share-alike obligation; pulldown-cmark already passes the spec |
| lychee exit code taxonomy (2=link fail) | Apache-2.0 OR MIT | Anti-gene — reject | — | N/A | Adopting it would invert R7, breaking CI integrations built on brief's contract |
| Post-render HTML checking (htmltest, muffet) | MIT / MIT | Anti-gene — reject | — | N/A | Structural inability to report `file:line` in source `.md` |
| Regex-based extraction (mkdocs-linkcheck) | Apache-2.0 | Anti-gene — reject | — | N/A | Code-fence false positives (DI-004 violation), escaped bracket false positives |

---

## Cross-Reference with DTU Assessment

`mdlinkcheck` has no external service dependencies beyond standard HTTP for `--online` mode. The DTU assessment (`.factory/specs/dtu-assessment.md`) records DTU_REQUIRED: false. No gene transfusion candidate calls any external service that would require a DTU.
