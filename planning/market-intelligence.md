# Market Intelligence Assessment — `mdlinkcheck`

**Pipeline step:** `market-intelligence` (planning.lobster)
**Date:** 2026-08-05
**Product:** `mdlinkcheck` — fast, offline-first Markdown link checker CLI in Rust
**Scope note:** Deliberately proportionate. This is a pilot/internal developer tool in a mature
category. **No TAM modelling was performed** — it would not change a single engineering decision.
Effort was concentrated on Section 4 (technical findings that must flow into the spec), which is
where research materially de-risks implementation.

---

## 1. Competitive Landscape

### 1.1 Gap matrix

Verified as of 2026-08-05. "Offline" = can validate local paths **and** heading fragments with zero
network traffic. "—" = not verified from primary sources; treat as unknown, not absent.

| Tool | Lang | Offline (paths + anchors) | Anchor check | Ref-style links + images | Ignores code fences/spans | JSON out | Exit codes | Speed / concurrency |
|---|---|---|---|---|---|---|---|---|
| **lychee** 0.24.2 | Rust | **Yes** (`--offline` + `--include-fragments`) | Yes, **opt-in** | Yes (parser-based) | Yes by default (`--include-verbatim` opts in) | Yes (`compact`/`detailed`/`json`/`markdown`/`raw`) | 0 ok, 1 missing input/runtime, **2 link failures**, 3 config error | async, default **128** concurrent requests, cache, retries |
| **markdown-link-check** (~3.14.x) | Node | Not reliably — no documented network-block switch | Yes since 3.10.0 (regressive) | Partial / unverified | Probably (parser-based) | **No** — text or JUnit XML only | Non-zero on break; semantics undocumented; "always exits 1" complaints | Node `async`, no worker control; 429 retry honours `Retry-After` |
| **lint-roller** (`@electron/lint-roller`) | TS/Node | Yes for relative mode (`--fetch-external-links` opts in) | Yes, incl. fragments | Likely (mdast + VS Code MD language service) | Expected yes | **No** | lint-style: 0 / non-zero | No documented concurrency |
| **remark-validate-links** v13 | Node (ESM) | **Yes** — offline by design, explicitly to avoid false positives | Yes, incl. cross-file `a.md#h` via CLI | **Yes** — links, images, and definitions explicitly | Yes (mdast node types make it structural) | No native JSON (vfile reporters compose one) | Warnings only; needs `remark --frail` for exit 1 | FS/AST only |
| **liche** | Go | Partial — paths only, no anchor validation | No | Via rendered `a`/`img` | Expected yes | **No** | Non-zero on failure | goroutines, default **512** concurrent |
| **muffet** | Go | **No** — HTTP crawler, needs a served site | HTML `id` only (post-render) | Post-render only | Yes (rendered) | Yes (text/JSON/JUnit) | 0 / 1 | "massive speed", `--max-connections` |
| **htmltest** | Go | Yes, **after build** (`--skip-external`) | Yes, default on (`CheckInternalHash`) | Post-render only | Yes (rendered) | No (only `refcache.json` + `htmltest.log`) | Non-zero on error-level | 2000 files in **8.6 s**; doc limit 128, HTTP limit 16, 2-week cache |
| **awesome_bot** | Ruby | **No** — URL-probing oriented | No | Partial | **Unsafe** — undocumented parser, may extract example URLs | Yes (`ab-results-*.json`) | 0 / non-zero | No worker model; delay/timeout only |
| **Sphinx `linkcheck`** | Python | **No** — it is `CheckExternalLinksBuilder` by design | Yes for **remote** HTML anchors (`linkcheck_anchors`, default on) | N/A (docutils nodes) | Yes (structural) | Yes (`output.txt` + `output.json`) | 0 / non-zero (warnings ⇒ 1) | 5 worker threads, 1 retry, 30 s timeout |
| **mkdocs-htmlproofer-plugin** | Python | Yes post-render (`validate_external_urls: false`) | Yes (rendered HTML ids + `attr_list`) | Post-render | Yes (rendered) | No | `raise_error` / `raise_error_after_finish` config | No concurrency control; explicitly slow |
| **mkdocs-linkcheck** | Python | Local file existence only (`-local`) | **No** | Unverified | Unverified | No | 0 clean, **22** on missing target | asyncio/aiohttp; README admits **HEAD yields false positives** |

### 1.2 What incumbents get right

- **lychee** is the strongest reference implementation: real `--offline`, structured output, an
  explicit and *distinguished* exit-code taxonomy (2 = link failures, 1 = tool failure, 3 = config),
  caching, and tunable concurrency. Its exit-code split is better design than the brief's R7 and is
  worth studying (see Risk R4).
- **remark-validate-links** has the right *philosophy* — it deliberately refuses to do network
  checks, and its README explicitly justifies this as "faster and less prone to false positives."
  This is independent validation of `mdlinkcheck`'s central design bet.
- **htmltest** proves the performance target is easy: 2000 generated HTML files in 8.6 s in Go.
  R8 (500 Markdown files in < 5 s, offline) is not an ambitious bar for Rust + rayon.
- **htmltest** avoids the whole HEAD/GET class of bugs by sending `GET` with `Range: bytes=0-0`.

### 1.3 What incumbents get wrong

- **Anchor checking is where everyone breaks.** This is the single most consistent defect class
  across the whole category:
  - lychee: open [#1457](https://github.com/lycheeverse/lychee/issues/1457) (missing remote anchors
    accepted as valid — false *negative*), [#1613](https://github.com/lycheeverse/lychee/issues/1613)
    (self-fragments broken), [#1709](https://github.com/lycheeverse/lychee/issues/1709) (local
    fragment checks cause read errors and eventually "too many open files").
  - markdown-link-check: anchors ending in `?`, trailing whitespace, Chinese headings, headings
    containing links, and headings appearing *before* the source link
    ([issues](https://github.com/tcort/markdown-link-check/issues),
    [#304](https://github.com/tcort/markdown-link-check/issues/304)); a 3.12 regression had the
    anchor tests **skipped in CI**.
  - Sphinx: [#13620](https://github.com/sphinx-doc/sphinx/issues/13620) false "Anchor not found" for
    percent-encoded fragment characters; [#11542](https://github.com/sphinx-doc/sphinx/issues/11542)
    valid GitLab/Framagit anchors rejected after 7.1.
  - mkdocs-htmlproofer: [#64](https://github.com/manuzhang/mkdocs-htmlproofer-plugin/issues/64)
    emoji-containing headings reported as false 404s.
  - MkDocs' own 1.6 native anchor validator: [#3690](https://github.com/mkdocs/mkdocs/issues/3690),
    [#3923](https://github.com/mkdocs/mkdocs/issues/3923) — false positives from special characters
    and GitHub-slug divergence.
  - markdownlint MD051: [#945](https://github.com/DavidAnson/markdownlint/issues/945) false positive
    when the heading itself contains link syntax.
- **Anchor checking is opt-in almost everywhere** (lychee `--include-fragments`), so most users never
  turn it on and heading rot goes undetected.
- **Post-render tools (htmltest, muffet, mkdocs plugins, Sphinx) cannot diagnose Markdown-source
  errors** — an undefined reference definition `[foo]` that renders as literal text is invisible to
  them, and their file:line reporting points at generated HTML, not the `.md` the author edits.
- **No JSON output** in markdown-link-check, lint-roller, htmltest, mkdocs plugins, liche, or
  mkdocs-linkcheck. JUnit XML where present.
- **Exit-code semantics are undocumented** in most tools; `markdown-link-check` has open complaints
  about always exiting 1, and mkdocs-linkcheck uses an idiosyncratic `22`.
- **Maintenance decay:** `liche` is **deprecated by its own author** (recommends lychee/muffet);
  `remark-validate-links` was **reported archived on 2026-06-04**.

---

## 2. Validated Pain — the false-positive problem is real and citable

The brief's core claim — "without false positives that train people to ignore it" — is well
supported by primary evidence:

1. **Tools admit it in their own docs.** `mkdocs-linkcheck`'s README states HEAD checks "produce
   false positives" and recommends the slower GET. Optimizely's support article documents that its
   HEAD-based validator reports links broken that open fine in a browser.
2. **Rate limiting is endemic enough to need dedicated docs.** lychee ships an entire
   [rate-limits troubleshooting page](https://lychee.cli.rs/troubleshooting/rate-limits/) whose
   remedies include, as a last resort, *accepting 429 as valid* — i.e. suppressing the signal.
3. **CI failures on plain github.com HTML pages.** Sphinx
   [#7388](https://github.com/sphinx-doc/sphinx/issues/7388) shows a CI linkcheck failing with 429
   on an ordinary `https://github.com/.../pull/80` page (not the REST API); pypa/twine
   [#582](https://github.com/pypa/twine/issues/582) shows the same. Re-running locally succeeds
   because the source IP differs. This is unfixable flakiness from the repo owner's side.
4. **Bot-protection false positives.** LinkedIn returns nonstandard `999 Request denied` to
   automation; htmltest [#150](https://github.com/wjdp/htmltest/issues/150) documents Microsoft
   returning 403 to htmltest's user agent while curl got 200.
5. **The standard mitigation is to disable the check.** `awesome_bot --allow 429` and lychee's
   "accept 429" advice are both "make CI green without validating anything." This is precisely the
   "train people to ignore it" failure mode.
6. **Code-fence false positives.** Cursor
   [forum report](https://forum.cursor.com/t/plan-preview-parses-markdown-links-text-url-inside-fenced-code-blocks-corrupting-scala-generic-signatures/165052)
   and kiwifs [#301](https://github.com/kiwifs/kiwifs/issues/301) both show regex-based extraction
   inventing links inside fenced blocks.

**Conclusion:** offline-by-default is not a cop-out; it is the only configuration in which a link
checker can be a *hard* CI gate. Externals belong on a scheduled, non-blocking job. R2(c)'s
`--online` opt-in is the correct architecture and is defensible with the above citations.

---

## 3. Differentiation — honest assessment

| Claimed differentiator | Verdict | Reasoning |
|---|---|---|
| Offline-by-default | **Table stakes as a capability, differentiated as a *default*** | lychee, remark-validate-links, lint-roller and htmltest can all run offline; none except remark-validate-links makes it the default. Making offline the default and `--online` the opt-in is a genuine (if modest) positioning difference. |
| Strict anchor checking, **on by default** | **Genuinely differentiated** | Every competitor either lacks anchor checking (liche, mkdocs-linkcheck, awesome_bot), makes it opt-in (lychee), or has active open false-positive/false-negative bugs (all the rest). "Anchor checking that is on by default and *correct*" is the strongest available wedge. |
| Deterministic exit codes | **Table stakes in principle, differentiated in practice** | lychee already does this well (and better than the brief). Most others don't document theirs at all. Low differentiation ceiling but cheap to get right. |
| Source-level `file:line` reporting on the `.md` | **Differentiated vs. the post-render half of the field** | htmltest/muffet/mkdocs/Sphinx can only point at generated HTML. |
| Single static Rust binary, no runtime | Shared with lychee/liche/muffet/htmltest | Differentiates only against the Node/Python/Ruby tools. |
| Speed | **Not a differentiator** | htmltest already does 2000 files in 8.6 s. R8 is a floor, not a moat. |

**Sharpest defensible claim:** *"correct GitHub-compatible anchor checking, on by default, offline,
reported at `file:line` in the Markdown source, with a non-flaky exit code."* Note that speed is
explicitly **not** the pitch.

---

## 4. Technical Findings That Must Flow Into the Spec

> This is the highest-value section. Everything below is sourced from primary implementation code or
> registry data, not model memory.

### 4.1 The GitHub heading-anchor slug algorithm (AUTHORITATIVE)

**Canonical source:** GitHub's HTML pipeline, `html-pipeline` v2
`lib/html/pipeline/toc_filter.rb`. The de facto reference port is
[`github-slugger`](https://github.com/Flet/github-slugger) (used by markdownlint MD051, remark,
mdast-util-toc). markdownlint MD051's documentation explicitly cites the html-pipeline Ruby
implementation as the normative algorithm.

**html-pipeline v2, verbatim:**

```ruby
PUNCTUATION_REGEXP = RUBY_VERSION > '1.9' ? /[^\p{Word}\- ]/u : /[^\w\- ]/
```

**github-slugger v2 `index.js`, verbatim:**

```js
export function slug(value, maintainCase) {
  if (typeof value !== 'string') return ''
  if (!maintainCase) value = value.toLowerCase()
  return value.replace(regex, '').replace(/ /g, '-')
}
```

**Duplicate handling, verbatim:**

```js
slug(value, maintainCase) {
  const self = this
  let result = slug(value, maintainCase === true)
  const originalSlug = result
  while (own.call(self.occurrences, result)) {
    self.occurrences[originalSlug]++
    result = originalSlug + '-' + self.occurrences[originalSlug]
  }
  self.occurrences[result] = 0
  return result
}
```

**Normative algorithm for the spec (implement exactly this order):**

1. **Input is the heading's rendered *text content*** — not the raw Markdown source. Concatenate all
   text of the heading, including the text inside inline code spans; drop all markup. So
   `## Use \`--online\` **now**` has text content `Use --online now`.
   - HTML tags inside a heading contribute **no** text (`## Foo <a name="bar"></a>` → text `Foo `).
     Note the trailing space survives into the slug as a hyphen: `foo-`.
   - HTML comments contribute nothing.
2. **Lowercase.** Full Unicode lowercasing (JS `toLowerCase`). Note a real divergence: Ruby's
   `String#downcase` was ASCII-only in older Rubies, which is the origin of github-slugger
   [#54](https://github.com/Flet/github-slugger/issues/54). Rust's `str::to_lowercase` is full
   Unicode and matches github-slugger. **Use `to_lowercase()`, not `to_ascii_lowercase()`.**
3. **Remove every character that is not a word character, a hyphen `-`, or a space.**
   Equivalent to Ruby `/[^\p{Word}\- ]/u`. In Rust terms: **keep** `char::is_alphanumeric()` plus
   `_` plus combining marks (Unicode `M*`), plus `-` and ` `; **remove** everything else.
   - **Kept:** ASCII letters/digits, `_`, `-`, space, accented Latin (`é`), Cyrillic, Greek, CJK
     (`你好`), Arabic, combining marks.
   - **Removed:** `. , : ; ! ? ' " ( ) [ ] { } < > / \ | @ # $ % ^ & * + = ~ \`` and all ASCII
     control chars — **and all emoji**.
4. **Replace each space with a hyphen.** Note: this is a **1:1 per-character** replacement
   (`/ /g`), **not** run collapsing. Two consecutive spaces → two hyphens. Runs of hyphens are
   **never** collapsed and leading/trailing hyphens are **never** trimmed.
5. **Disambiguate duplicates by document order.** First occurrence gets **no** suffix. Second gets
   `-1`, third `-2`, and so on. The counter is keyed on the *original* slug.

**Worked examples (verified against github-slugger's documented behaviour):**

| Heading | Slug |
|---|---|
| `Foo` | `foo` |
| `Foo` (2nd occurrence) | `foo-1` |
| `Foo` (3rd occurrence) | `foo-2` |
| `Hello, World!` | `hello-world` |
| `Hello,  World!` (two spaces) | `hello--world` |
| `Привет non-latin 你好` | `привет-non-latin-你好` |
| `😄 emoji` | `-emoji` |
| `snake_case_name` | `snake_case_name` |
| `C++ / C#` | `c--c` |
| `## \`--online\` flag` | `--online-flag` |

**Known divergences to document as accepted limitations:**
- **U+200C (ZWNJ) / U+200D (ZWJ):** GitHub *keeps* them, github-slugger *strips* them. Per
  github-slugger [#56](https://github.com/Flet/github-slugger/issues/56), across all Unicode
  codepoints these are the **only** two divergences found. Acceptable to ignore.
- **No percent-encoding in the slug itself.** github-slugger emits raw Unicode. GitHub's rendered
  `href` *is* percent-encoded, so a link written as `[x](#%E4%BD%A0%E5%A5%BD)` must be
  percent-**decoded** before comparison against the raw slug. See 4.3.
- **`{#custom-id}` is NOT GitHub Markdown.** It is kramdown/pandoc/MkDocs syntax. markdownlint MD051
  tolerates it. Since BRIEF non-goals exclude HTML parsing, the spec should treat `{#custom-id}` and
  `<a name="x">` / `id="x"` anchors as **unsupported**, and document `--allow`-style escape hatch or
  a known-limitation note. **Flag this as an explicit product decision, not an oversight.**
- **Collision edge case:** headings `Foo`, `Foo`, `Foo-1` (in that order) produce `foo`, `foo-1`,
  `foo-1-1`. Include this in the acceptance corpus.

### 4.2 Rust crate recommendations — VERSIONS VERIFIED AGAINST crates.io (2026-08-05)

All versions below were read from the crates.io API on 2026-08-05. None are from model memory.

| Concern | Recommendation | Verified latest | Released | License |
|---|---|---|---|---|
| Markdown/CommonMark parser | **`pulldown-cmark`** | **0.13.4** | 2026-05-20 | MIT |
| (alternative considered) | `comrak` | 0.54.0 | 2026-07-12 | BSD-2-Clause |
| CLI arg parsing | **`clap`** (derive) | **4.6.5** | 2026-07-31 | MIT OR Apache-2.0 |
| Glob matching for `--ignore` | **`globset`** | **0.4.20** | 2026-08-04 | Unlicense OR MIT |
| (alternative considered) | `glob` | 0.3.4 | 2026-07-21 | MIT OR Apache-2.0 |
| Directory traversal | **`ignore`** (or `walkdir`) | **0.4.33** / `walkdir` 2.5.0 | 2026-08-04 / 2024-03-01 | Unlicense OR MIT |
| Parallelism | **`rayon`** | **1.12.0** | 2026-04-14 | MIT OR Apache-2.0 |
| HTTP client for `--online` | **`ureq`** | **3.3.0** | 2026-03-21 | MIT OR Apache-2.0 |
| (alternative considered) | `reqwest` | 0.13.4 | 2026-05-25 | MIT OR Apache-2.0 |
| JSON output | **`serde_json`** | **1.0.151** | 2026-07-20 | MIT OR Apache-2.0 |
| Fragment decoding | **`percent-encoding`** | **2.3.2** | 2025-08-21 | MIT OR Apache-2.0 |

**MSRV note:** `clap` 4.6.x requires **Rust 1.85**; `ureq` 3.3.0 requires **Rust 1.85** (edition
2024). Set the project MSRV to **1.85** and pin it in CI.

#### Parser decision: `pulldown-cmark` over `comrak` — with a caveat

Verified from primary source (`pulldown-cmark/src/parse.rs`, `src/lib.rs` via Context7, plus
docs.rs):

- **Source offsets:** `Parser::into_offset_iter()` yields `(Event<'a>, Range<usize>)` where the range
  is **byte offsets into the source string**. This gives exactly what R6 needs. Convert byte offset
  → line number with a one-pass prefix scan of `\n` positions (build a `Vec<usize>` of line-start
  offsets once per file, then binary-search). **Note:** offsets are *byte* offsets, so line numbers
  must be derived from byte positions, not char positions.
- **Reference-style links are fully distinguishable.** `LinkType` has, verbatim:
  `Inline`, `Reference`, `ReferenceUnknown`, `Collapsed`, `CollapsedUnknown`, `Shortcut`,
  `ShortcutUnknown`, `Autolink`, `Email`, `WikiLink { has_pothole: bool }`.
  This directly satisfies R3 and lets the tool report *undefined reference* as a distinct failure
  reason (the `*Unknown` variants) — a class that remark-validate-links
  [#74](https://github.com/remarkjs/remark-validate-links/issues/74) got wrong.
- **Images are a separate tag with the same shape:** `Tag::Image { link_type, dest_url, title, id }`
  mirrors `Tag::Link { link_type, dest_url, title, id }`. R3's "images checked the same as links" is
  a two-line match arm.
- **Reference definitions are enumerable:** `OffsetIter::reference_definitions() -> &RefDefs<'a>`.
  Useful for reporting unused/duplicate definitions if ever desired.
- **Code fences and code spans are free.** R4 requires **zero** special-case work: inline parsing
  never runs inside code spans (`Event::Code`), and fenced-block content arrives as `Event::Text`
  nested inside `Tag::CodeBlock` — never as a `Tag::Link`. If you only match `Tag::Link` /
  `Tag::Image`, R4 is satisfied by construction. This is the single strongest argument for
  AST parsing over regex.
- **Heading IDs:** `Tag::Heading { level, id: Option<CowStr>, classes, attrs }` — the `id` field
  surfaces `{#custom-id}` when `Options::ENABLE_HEADING_ATTRIBUTES` is on. Per 4.1, the spec should
  **leave this option off** to stay GitHub-faithful, or treat a present `id` as an additional
  accepted anchor. Decide explicitly.

**The one caveat — GFM extended autolinks.** Verified: `pulldown-cmark` does **not** support GFM
bare-URL autolinks (`www.example.com` or `https://example.com` in plain prose without angle
brackets) — see [pulldown-cmark #494](https://github.com/pulldown-cmark/pulldown-cmark/issues/494).
Only CommonMark `<http://...>` autolinks produce `LinkType::Autolink`. `comrak` (a
100%-GFM-compatible parser) does support them and exposes `Ast.sourcepos: Sourcepos` with
line/column directly.

**Recommendation:** use `pulldown-cmark` 0.13.4 anyway, and **explicitly scope bare-URL autolinks out
of R2** with a documented rationale. Justification: (a) bare URLs are always *external* URLs, which
are not fetched in the default offline mode anyway, so the gap only affects `--online`; (b) byte-range
offsets from `into_offset_iter` are simpler and cheaper than comrak's arena AST; (c) MIT vs
BSD-2-Clause is a wash but MIT is the more common expectation. **If GFM bare-URL parity later becomes
a requirement, `comrak` is the migration target** — record this in the ADR.

#### HTTP client decision: `ureq` over `reqwest`

For a CLI whose network work is a bounded, embarrassingly-parallel batch:
- `ureq` 3.3.0 is **synchronous/blocking** — it composes directly with `rayon`, requires **no tokio
  runtime**, and produces a materially smaller binary and simpler stack traces. It supports rustls,
  timeouts, and redirect control.
- `reqwest` 0.13.4 pulls in tokio + hyper. Justified only if you need per-host token-bucket
  scheduling with thousands of in-flight requests — which `mdlinkcheck` explicitly does not (R2c is
  a HEAD/GET with a 10 s timeout).
- **Decision:** `ureq` 3.3.0 with `rustls`. Bound concurrency with a `rayon` thread pool sized
  separately for network work (see 4.4).

#### Glob decision: `globset` over `glob`

`globset` 0.4.20 (BurntSushi, actively maintained, powers ripgrep) compiles **multiple** patterns
into one matcher — exactly right for a repeatable `--ignore <glob>` flag (R5). `glob` 0.3.4 matches
one pattern at a time and would require N passes. Use `GlobSetBuilder`.

For traversal, prefer **`ignore` 0.4.33** over `walkdir` 2.5.0: it gives `.gitignore` awareness for
free and its `WalkBuilder` has a parallel mode. Note `walkdir` has had **no release since
2024-03-01** (stable, not abandoned — same author).

### 4.3 Correctness traps — mandatory acceptance-corpus cases

Every item below is a documented real-world failure in an existing tool. Each should become a
fixture in the acceptance corpus.

| # | Trap | Correct behaviour |
|---|---|---|
| T1 | Links inside fenced code blocks and inline code spans | Never extracted. Free with `pulldown-cmark` if you only match `Tag::Link`/`Tag::Image`. Also cover indented (4-space) code blocks and language-tagged fences. |
| T2 | CommonMark autolinks `<http://x>` / `<mailto:>` | `LinkType::Autolink` / `Email`. Treat as external URLs → syntax-only unless `--online`. Bare `www.x.com` is **out of scope** (4.2 caveat). |
| T3 | Raw HTML `<a href>` / `<img src>` | **Out of scope** per BRIEF non-goals. Arrives as `Event::Html` / `Event::InlineHtml`; ignore. Document as a limitation — markdownlint [#2178](https://github.com/DavidAnson/markdownlint/issues/2178) shows naive HTML scanning causes false positives. |
| T4 | Reference definitions: full `[a][b]`, collapsed `[a][]`, shortcut `[a]` | Resolution requires **whole-document** parse — definitions may appear *after* use. `pulldown-cmark` handles this. Label matching is **case-insensitive after Unicode case folding**, with outer whitespace trimmed and internal whitespace runs collapsed (CommonMark). **First** matching definition wins. |
| T5 | Undefined references | `LinkType::ReferenceUnknown` / `CollapsedUnknown` / `ShortcutUnknown`. Report as a **distinct** reason ("undefined reference definition"), not as a broken file path. Do not attempt filesystem resolution. |
| T6 | Escaped brackets `\[not a link\]` | Not a link. Parser handles it. Regex approaches fail. |
| T7 | Nested brackets `[a [b] c](url)` | **Is** a valid link (GFM permits matched bracket pairs in link text). Parser handles it. |
| T8 | Angle-bracket destination with spaces `[x](<a b.md>)` | Valid; destination is `a b.md`. The angle brackets are **stripped by the parser** — `dest_url` is already `a b.md`. Do not reject destinations containing spaces. |
| T9 | Percent-encoding | **Order matters:** (1) split the fragment at the **first unescaped `#`** — do this on the *raw* destination, before any decoding, so `%23` is never mistaken for `#` (see markdown-link-check [#351](https://github.com/tcort/markdown-link-check/issues)); (2) percent-**decode** the path component, then resolve against the filesystem, so `a%20b.md` finds `a b.md`; (3) percent-**decode** the fragment before comparing to the raw Unicode slug (4.1) — this is exactly the bug in Sphinx [#13620](https://github.com/sphinx-doc/sphinx/issues/13620). |
| T10 | `#frag` on a directory, or on a non-Markdown file (`.pdf`, `.png`) | Resolve the path first. Then: for a **directory**, a fragment is unverifiable → do not fail (report as skipped/unchecked). For a **non-`.md`** file, the tool cannot extract headings → do not fail. Failing here is a guaranteed false positive. |
| T11 | Bare `#` and empty fragment (`a.md#`) | No ecosystem consensus found. **Decide explicitly in the spec** and test it. Recommended: treat empty fragment as "no fragment" (check the file only). |
| T12 | Case-insensitive macOS APFS vs case-sensitive Linux | `[x](docs/Setup.md)` pointing at `docs/setup.md` **passes on a dev Mac and 404s on GitHub**. Mitigation: after `Path::exists()` succeeds, read the parent directory and confirm an **exact byte-for-byte** filename match. This is a *silent* class of failure and a real differentiator, since the research found no tool doing it. Note: primary-issue evidence for this specific trap was thin — flagged as **inferred from filesystem semantics, medium confidence** on prevalence, high confidence on mechanism. |
| T13 | Windows path separators / `\` in destinations | A `\` in a Markdown destination is not a path separator. Do not normalise it into one. Resolve destinations as URL paths with `/`, then map to `PathBuf`. Evidence gap — no primary issue found; treat as defensive. |
| T14 | Heading containing link syntax, e.g. `## See [the docs](x)` | Text content is `See the docs`; slug is `see-the-docs`. markdownlint [#945](https://github.com/DavidAnson/markdownlint/issues/945) got this wrong. Concatenate the heading's inline **text**, do not use raw source. |
| T15 | Heading appearing *after* the link that references it | Requires a two-pass design: extract all headings per file first, then validate links. markdown-link-check has an open bug here. Build the anchor index for a file before validating any link into it. |
| T16 | Path traversal above the scan root (`../../outside/x.md`) | Resolve and check; do not silently pass. Decide whether to report as broken or as out-of-scope. |

### 4.4 HEAD-then-GET fallback and rate limiting (`--online` only)

Verified: **there is no consensus around "only retry on 405."** Three of five tools surveyed sidestep
the problem entirely by using `GET`. Current Sphinx `linkcheck` yields HEAD first then a **streamed
GET**, so effectively *any* HEAD error falls through to GET; older Sphinx limited fallback to
403/404/405. `htmltest` uses `GET` with `Range: bytes=0-0` and `Accept: */*`.

**Recommended policy — retry with GET on: 400, 403, 404, 405, 501, and LinkedIn's nonstandard 999.**
R2(c)'s "GET fallback on 405" is **too narrow** and will produce false positives.

| HEAD status | GET retry? | Rationale |
|---|---|---|
| 400 | Yes | Some front ends reject unusual HEAD requests/headers. |
| 403 | Yes | Method-, UA-, or WAF-dependent. A repeated 403 is **access-denied, not missing**. |
| 404 | Yes | Real servers route HEAD differently from GET (documented in Optimizely + curl reports). |
| 405 | Yes | Canonical case. |
| 501 | Yes | RFC 9110 distinguishes 405 (known but disallowed) from 501 (unimplemented); both mean "try GET". |
| 429 | **No immediate GET** | Retrying immediately just adds a request. Pause the **host**, obey `Retry-After`. |
| 999 | Yes, once | LinkedIn bot rejection; if GET also 999 → indeterminate. |

Also fall through to GET on **transport-level failures** (connection reset/closed on HEAD) — Sphinx
[#9306](https://github.com/sphinx-doc/sphinx/issues/9306) shows a server closing the connection on
HEAD while GET returned valid content, and the exception bypassed the status-code-only fallback.

**Bandwidth-conscious GET:** send `Range: bytes=0-0` and stop after headers (htmltest's approach).

**`Retry-After` per RFC 9110** has exactly two forms:
```
Retry-After: 120                              # delay-seconds, from time of receipt
Retry-After: Wed, 05 Aug 2026 18:00:00 GMT    # HTTP-date
```
For the date form compute `max(0, date − now_utc)`. **Do not** reinterpret the numeric form as
milliseconds.

**429 handling:**
- Key retry state **per host/origin**, not per URL.
- When any request to a host gets 429, **stop releasing other queued requests for that host** —
  otherwise concurrent workers defeat the backoff.
- Without `Retry-After`, back off exponentially with jitter. Sphinx's concrete model: key by
  `netloc`, start at **60 s**, double, cap at **300 s**.
- Cap both attempt count and total elapsed delay.

**Classification — this is a spec decision, not an implementation detail.** A robust checker needs
**three** outcomes, not two: `valid`, `broken`, `indeterminate`. 429 and confirmed bot-blocking
(403/999 after GET) are **indeterminate** — the tool never established that the target is missing.
`linkinator` is the model here: it explicitly *skips* detected bot protection (Cloudflare mitigation
header, LinkedIn 999), counting it as neither valid nor broken.

> **Spec impact on R6/R7:** the brief's binary text/JSON output has no place to express
> "indeterminate." Recommend adding a `status` field to the JSON schema
> (`broken` | `indeterminate`) and deciding whether indeterminate affects the exit code. Simplest
> defensible answer: indeterminate results are printed as warnings and do **not** set exit 1, since
> the default offline mode never produces them.

**GitHub.com in CI — the characteristic failure pattern** (do not assume the 60 req/hr REST quota
applies to HTML pages; the mechanism is IP-attributed anti-abuse):
1. Docs contain many github.com issue/PR/commit/blob links.
2. Checker fires a burst of unauthenticated requests.
3. CI runners may share an outbound IP with unrelated jobs.
4. GitHub's anti-abuse layer returns 429 (or 403) — sometimes before the job itself made many requests.
5. Re-running locally succeeds because the source IP and history differ.

Mitigations if `--online` ever hardens: cap `github.com` concurrency separately, cache successes,
support a `GITHUB_TOKEN` (lychee's approach — an unprivileged token suffices for public repos), and
honour `Retry-After` / `x-ratelimit-reset` / `x-ratelimit-remaining`.

---

## 5. Risk Signals

| ID | Risk | Severity | Assessment / mitigation |
|---|---|---|---|
| **R1** | **"Why not just use lychee?"** | **High** | lychee 0.24.2 (Apache-2.0 OR MIT) already does offline mode, fragments, JSON, caching, and a *better* exit-code taxonomy. It has ~169k crates.io downloads and an active maintainer. On raw features `mdlinkcheck` is a subset. **Honest answer:** the justification is (a) it is a **pilot/internal exercise** — the VSDD factory's purpose is the pipeline, not market conquest; (b) lychee's fragment support has three open correctness bugs (#1457, #1613, #1709), so "anchors correct and on by default" is a real gap; (c) a narrower tool with a smaller surface is easier to make provably correct. **This must be stated explicitly in the PRD or the product looks naive.** |
| **R2** | **Anchor slug fidelity drift** | **High** | GitHub's algorithm is only *documented* via a third-party Ruby gem and a JS port. GitHub can change it. Mitigation: pin the algorithm in a single well-tested module with the 4.1 examples as unit tests; document the ZWJ/ZWNJ divergence as accepted. |
| **R3** | **Licensing** | **Low** | Whole recommended stack is MIT / Apache-2.0 / Unlicense-OR-MIT. `comrak` (BSD-2-Clause) is permissive too. No copyleft, no CLA traps, no attribution burden beyond standard notices. |
| **R4** | **R7 exit codes are less expressive than lychee's** | **Medium** | Brief: 0/1/2 with 2 = usage/IO error. lychee: 2 = *link failures*, 1 = runtime failure, 3 = config error. These are **inverted**, which will confuse anyone switching. Also, R7 has no code for "checked but indeterminate" (4.4). Recommend keeping the brief's simpler scheme (it is defensible and self-consistent) but **documenting the divergence from lychee prominently**, and deciding the indeterminate case. |
| **R5** | **Maintenance burden / bus factor** | **Medium** | The category is littered with abandoned tools: `liche` deprecated by its own author, `remark-validate-links` reported archived 2026-06-04, `walkdir` no release since 2024. A pilot tool with no maintainer plan joins them. Not a blocker for a pilot; note it. |
| **R6** | **False-positive risk concentrates in exactly the differentiating feature** | **Medium-High** | Anchor checking on-by-default is the wedge *and* the highest-risk surface — every competitor has bugs there. Traps T9–T15 are the specific ones. Mitigation: make the acceptance corpus (Success Criteria) carry a fixture for every one of T1–T16. |
| **R7** | **`--online` scope creep** | **Medium** | Getting `--online` "right" means per-host concurrency, `Retry-After` parsing, exponential backoff, indeterminate status, caching, and token support. R2(c) as written ("HEAD, GET on 405, 10 s timeout") is a *deliberately* thin slice. Keep it thin, and document that `--online` is best-effort and not a hard CI gate. |
| **R8** | **Case-sensitivity check (T12) has no precedent** | **Low** | No surveyed tool does exact-case verification, so there is no reference behaviour and it could surprise users on Windows/macOS. Mitigation: implement it, but consider gating behind a flag or emitting a distinct reason string so it is obviously separable. |

---

## 6. Decisions the Spec Must Now Make Explicitly

Research surfaced seven points where the BRIEF is silent or under-specified. Each needs an answer
before implementation:

1. **R2(c) GET-fallback status codes** — widen from `405` to `{400, 403, 404, 405, 501, 999}` plus
   transport failures. (4.4)
2. **Indeterminate status** — does `--online` need a third outcome, and does it affect exit code?
   Affects R6 JSON schema and R7. (4.4)
3. **`{#custom-id}` and HTML anchors** — supported, ignored, or a documented limitation?
   Recommend: unsupported, documented. (4.1)
4. **GFM bare-URL autolinks** — out of scope given `pulldown-cmark`. Confirm and record. (4.2)
5. **Empty fragment `a.md#`** — recommend treating as "no fragment." (T11)
6. **Fragments on directories and non-`.md` targets** — recommend skip-not-fail. (T10)
7. **Exact-case filename verification (T12)** — in or out, and behind a flag or not? (R8)

---

## 7. Sources

**Competitors / primary repos & docs**
- lychee: https://github.com/lycheeverse/lychee · https://lychee.cli.rs/guides/cli/ ·
  https://lychee.cli.rs/recipes/anchors/ · https://lychee.cli.rs/troubleshooting/rate-limits/ ·
  https://lychee.cli.rs/troubleshooting/network-errors/
- lychee open issues: https://github.com/lycheeverse/lychee/issues/1457 ·
  https://github.com/lycheeverse/lychee/issues/1613 ·
  https://github.com/lycheeverse/lychee/issues/1709 ·
  https://github.com/lycheeverse/lychee/issues/1605 ·
  https://github.com/lycheeverse/lychee/discussions/978
- markdown-link-check: https://github.com/tcort/markdown-link-check ·
  https://github.com/tcort/markdown-link-check/issues ·
  https://github.com/tcort/markdown-link-check/issues/304 ·
  https://github.com/tcort/markdown-link-check/issues/91 ·
  https://github.com/tcort/markdown-link-check/blob/master/CHANGELOG.md ·
  https://github.com/tcort/markdown-link-extractor
- lint-roller: https://github.com/electron/lint-roller
- remark-validate-links: https://github.com/remarkjs/remark-validate-links ·
  https://github.com/remarkjs/remark-validate-links/issues/74 ·
  https://github.com/remarkjs/remark-validate-links/issues/77 ·
  https://github.com/remarkjs/remark-validate-links/issues/57
- liche: https://github.com/raviqqe/liche (deprecation notice)
- muffet: https://github.com/raviqqe/muffet/blob/main/README.md ·
  https://raviqqe.com/muffet/usage/ · https://github.com/raviqqe/muffet/issues/41
- htmltest: https://github.com/wjdp/htmltest · https://wjdp.uk/work/htmltest/ ·
  https://pkg.go.dev/github.com/wjdp/htmltest/htmltest ·
  https://github.com/wjdp/htmltest/issues/150 · https://github.com/wjdp/htmltest/issues/126
- awesome_bot: https://github.com/dkhamsing/awesome_bot
- Sphinx linkcheck: https://www.sphinx-doc.org/en/master/usage/configuration.html ·
  https://github.com/sphinx-doc/sphinx/blob/master/sphinx/builders/linkcheck.py ·
  https://github.com/sphinx-doc/sphinx/issues/13620 ·
  https://github.com/sphinx-doc/sphinx/issues/7388 ·
  https://github.com/sphinx-doc/sphinx/issues/9306 ·
  https://github.com/sphinx-doc/sphinx/issues/2988 ·
  https://github.com/sphinx-doc/sphinx/issues/11542
- MkDocs plugins: https://github.com/manuzhang/mkdocs-htmlproofer-plugin ·
  https://github.com/manuzhang/mkdocs-htmlproofer-plugin/issues/64 ·
  https://github.com/mkdocs/mkdocs/issues/3690 · https://github.com/mkdocs/mkdocs/issues/3923 ·
  https://github.com/byrnereese/linkchecker-mkdocs · https://pypi.org/project/mkdocs-linkcheck/
- linkinator: https://github.com/JustinBeckwith/linkinator · https://jbeckwith.com/projects/linkinator

**Anchor slug algorithm (authoritative)**
- github-slugger source: https://github.com/Flet/github-slugger/blob/master/index.js
- github-slugger README/behaviour: https://github.com/Flet/github-slugger
- GitHub's actual regex analysis: https://github.com/Flet/github-slugger/issues/56
- Unicode case divergence: https://github.com/Flet/github-slugger/issues/54
- html-pipeline v2 `toc_filter.rb` (`PUNCTUATION_REGEXP`):
  https://github.com/gjtorikian/html-pipeline/blob/v2.14.3/lib/html/pipeline/toc_filter.rb
- html-pipeline v3 (no longer contains the slug logic):
  https://github.com/gjtorikian/html-pipeline/blob/main/lib/html_pipeline/node_filter/table_of_contents_filter.rb
- markdownlint MD051 (cites html-pipeline as normative):
  https://github.com/DavidAnson/markdownlint/blob/main/doc/md051.md
- markdownlint anchor bugs: https://github.com/DavidAnson/markdownlint/issues/945 ·
  https://github.com/DavidAnson/markdownlint/issues/2178

**Rust crates (all versions read from the crates.io API, 2026-08-05)**
- https://crates.io/api/v1/crates/pulldown-cmark · comrak · clap · globset · glob · rayon · ureq ·
  reqwest · serde_json · walkdir · ignore · percent-encoding · lychee
- pulldown-cmark `OffsetIter` / `LinkType` / `Tag` source:
  https://github.com/pulldown-cmark/pulldown-cmark/blob/main/src/parse.rs ·
  https://github.com/pulldown-cmark/pulldown-cmark/blob/main/src/lib.rs
- pulldown-cmark `LinkType` docs: https://docs.rs/pulldown-cmark/latest/pulldown_cmark/enum.LinkType.html
- pulldown-cmark broken-link callbacks:
  https://github.com/pulldown-cmark/pulldown-cmark/blob/main/guide/src/examples/broken-link-callbacks.md
- pulldown-cmark GFM bare-autolink gap: https://github.com/pulldown-cmark/pulldown-cmark/issues/494
- comrak sourcepos: https://docs.rs/comrak/latest/comrak/nodes/index.html

**Specs & HTTP**
- CommonMark spec: https://spec.commonmark.org/0.29 · https://spec.commonmark.org/0.24
- GFM spec: https://github.github.com/gfm
- RFC 9110 (`Retry-After`, 405 vs 501): https://datatracker.ietf.org/doc/html/rfc9110
- MDN `Retry-After`: https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Retry-After
- MDN 429: https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/429
- MDN Range requests: https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/Range_requests
- GitHub rate limits: https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api ·
  https://github.blog/changelog/2025-05-08-updated-rate-limits-for-unauthenticated-requests/

**False-positive evidence**
- HEAD false positives: https://support.optimizely.com/hc/en-us/articles/4418093269005-Broken-Links-in-LinkValidation-Job-that-are-not-actually-broken ·
  https://stackoverflow.com/questions/36092648/broken-link-checker-fails-head-requests
- LinkedIn 999: https://stackoverflow.com/questions/27231113/999-error-code-on-head-request-to-linkedin
- CI 429 on github.com HTML pages: https://github.com/pypa/twine/issues/582 ·
  https://github.com/sphinx-doc/sphinx/issues/7388 ·
  https://github.com/peter-evans/link-checker/issues/29
- Code-fence extraction false positives:
  https://forum.cursor.com/t/plan-preview-parses-markdown-links-text-url-inside-fenced-code-blocks-corrupting-scala-generic-signatures/165052 ·
  https://github.com/kiwifs/kiwifs/issues/301

---

## Research Methods

| Tool | Queries | Purpose |
|------|---------|---------|
| **Perplexity perplexity_research (PRIMARY)** | 4 attempted, **2 succeeded** | (1) Full 11-tool competitive gap matrix incl. offline/anchor/JSON/exit-code/concurrency and open issues — succeeded, ~370 citations. (2) HEAD→GET fallback status codes, 429/`Retry-After` semantics, per-tool behaviour, GitHub CI rate limiting — succeeded, ~280 citations. (3) GitHub anchor-slug algorithm — **timed out at 300 s**, replaced by direct primary-source fetches of github-slugger and html-pipeline. (4) Combined Markdown-traps + HTTP query — **timed out at 300 s**, split and re-routed to Tavily + a focused Perplexity call. |
| Perplexity perplexity_ask | 1 | Confirmed pulldown-cmark lacks GFM bare-URL autolinks and comrak exposes `sourcepos`. |
| Perplexity perplexity_search | 0 | — |
| Perplexity perplexity_reason | 0 | — |
| Context7 | 2 (1 resolve + 1 query-docs) | `/pulldown-cmark/pulldown-cmark` — verified `OffsetIter` byte ranges, all 10 `LinkType` variants, `Tag::Link`/`Tag::Image`/`Tag::Heading` shapes, `reference_definitions()`, broken-link callbacks. Source-level verbatim, not docs prose. |
| Tavily tavily_research | 1 (`pro`) | Markdown link-extraction correctness traps T1–T16 with issue citations; also self-reported its own evidence gaps (T12/T13), which are flagged in the report rather than asserted. |
| Tavily tavily_extract | 1 (`advanced`) | Extracted github-slugger `index.js` verbatim after `raw.githubusercontent.com` and npmx both failed (404 / 403). Yielded the exact `slug()` body and duplicate-counter loop. |
| Tavily tavily_search / crawl / map | 0 | — |
| WebFetch | 17 | **13 crates.io API endpoints** for version/license/date verification (pulldown-cmark, comrak, clap, globset, glob, rayon, ureq, reqwest, serde_json, walkdir, ignore, percent-encoding, lychee) + html-pipeline v2 & v3 `toc_filter.rb` + markdownlint MD051 doc + github-slugger `regex.js` + issue #56 + docs.rs `LinkType`. 3 further attempts returned 404/403 and were re-routed. |
| WebSearch | 1 | Located the github-slugger repo/branch after raw-URL 404s. |
| Read / Glob | 2 | `BRIEF.md`; confirmed no prior research exists under `.factory/`. |
| Training data | **2 areas, both flagged inline** | (a) Byte-offset→line-number conversion strategy in 4.2 is standard practice, not sourced. (b) T13 (Windows separators) is defensive reasoning — Tavily explicitly reported no primary evidence, and the report says so. T12's *prevalence* is also marked medium-confidence for the same reason. |

**Total MCP tool calls:** 9 (5 Perplexity attempts of which 3 returned, 2 Context7, 2 Tavily) plus
18 WebFetch/WebSearch calls. **Every crate version in 4.2 was read from the crates.io API on
2026-08-05; none is from model memory.** The anchor algorithm in 4.1 is quoted verbatim from
github-slugger and html-pipeline source, not paraphrased.

**Training data reliance:** **low** — confined to two explicitly flagged items, both of which are
labelled as inferred in the report body. Two `perplexity_research` calls timed out and were
compensated with direct primary-source retrieval (which produced *stronger* evidence for §4.1 than
a synthesized answer would have).

---

RECOMMENDATION: **GO (with conditions)**

The offline-by-default premise is validated by hard evidence, not intuition: lychee ships a
troubleshooting page whose last-resort advice is to accept HTTP 429 as success, Sphinx and twine CI
jobs fail on ordinary github.com HTML pages, and `mkdocs-linkcheck` documents its own HEAD-based
false positives — so an offline-only hard gate is the only configuration that can be trusted in CI.
Anchor checking is simultaneously the strongest wedge (every one of the eleven surveyed tools either
lacks it, gates it behind a flag, or carries open false-positive/false-negative bugs) and the
highest-risk surface, and the `pulldown-cmark` 0.13.4 + `ureq` 3.3.0 + `globset` 0.4.20 stack is
version-verified, permissively licensed, and exposes precisely the byte-range offsets and
`LinkType` discrimination that R3/R4/R6 require — making R4 (ignore code fences) satisfied by
construction rather than by special-casing.

**Conditions:** (1) widen R2(c)'s GET fallback from `405` to `{400, 403, 404, 405, 501, 999}` plus
transport failures, or `--online` will produce exactly the false positives the brief exists to
prevent; (2) resolve all seven under-specified decisions in §6 — especially the indeterminate-status
question, which changes the R6 JSON schema and the R7 exit-code contract; (3) carry a fixture for
every trap T1–T16 into the acceptance corpus, since traps T9/T10/T14/T15 are where the incumbents
demonstrably fail; (4) state the "why not lychee" answer explicitly in the PRD — lychee 0.24.2 is a
feature superset, and the honest differentiators are correctness-by-default plus pilot scope, not
capability or speed.
