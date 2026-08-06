---
document_type: domain-spec-section
level: L2
section: entities
version: "1.2"
status: draft
producer: business-analyst
timestamp: 2026-08-05T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/planning/brief-validation.md
  - .factory/planning/market-intelligence.md
input-hash: "20e96e1"
traces_to: L2-INDEX.md
changelog:
  - version: "1.2"
    date: 2026-08-05
    change: "Orchestrator ruling DD-022: added explicit `clean` entry to Ubiquitous Language as a standalone term with layer distinction (link verdict, not HTTP); expanded `alive` entry with full three-value liveness-to-verdict mapping and fresh-context guard against four-verdict misreading. This is the durable fix for the verdict-layer confusion identified by adversary P2-C01 and INCONSISTENCY-001/002."
  - version: "1.1"
    date: 2026-08-05
    change: "Phase 1d gate remediation: MarkdownFile entity corrected to .md only per DD-019/D-012. Added four missing canonical terms to Ubiquitous Language: alive (HTTP outcome term that maps to clean verdict), scan set, anchor-target universe, Pass 1.5. These terms appear throughout architecture/system-overview.md v1.2 and behavioral contracts but were absent from the domain glossary."
  - version: "1.0"
    date: 2026-08-05
    change: "Initial draft"
---

# Section 2: Ubiquitous Language and Domain Entities

> **Sharded L2 section (DF-021).** Navigate via `L2-INDEX.md`.

## Ubiquitous Language

| Term | Definition |
|------|-----------|
| **Link** | A syntactic reference in a Markdown document to another resource: text/alt part + destination. Includes inline, reference-style, and image links. Does NOT include raw HTML `<a href>` or `<img src>`. |
| **Link Kind** | Classification by destination form: `relative-file`, `anchor-only`, `cross-file-anchor`, `external-http`, `non-http` (skipped), `undefined-reference`. |
| **Link Target** | The resolved resource a link points to — a filesystem path, an anchor within a file, or an external URL. Computed from the destination after percent-decoding and path normalization. |
| **Anchor** | A named location within a Markdown document, identified by a slug derived from a heading or by an explicit HTML `id` or `name` attribute. |
| **Anchor Table** | The complete set of valid anchor identifiers for one Markdown file. Built from all headings (via slug algorithm) plus HTML `id`/`name` attributes. Always fully built before any link into the file is validated. |
| **Slug** | The normalized identifier produced from a heading's rendered text content by the GitHub slug algorithm (DD-015): lowercase, spaces → hyphens 1:1, non-word chars removed, duplicates disambiguated with 0-based per-file counter. |
| **Heading** | An ATX (`# Title`) or setext (`Title\n=====`) structural element that creates a named anchor. Headings inside code contexts do not create anchors. |
| **Reference Definition** | A `[label]: destination` mapping resolving reference-style links. Case-insensitive label matching with whitespace collapsing (CommonMark). First definition wins on duplicates. |
| **Code Context** | A region from which links are never extracted: fenced code blocks (backtick/tilde), inline code spans, indented code blocks (4-space), HTML `<pre>`/`<code>`, HTML comments. |
| **Scan Root** | The topmost directory of a scan invocation; used as the base for root-relative (`/path`) link resolution when no git repo root is detected. |
| **Corpus** | The acceptance corpus at `tests/corpus/` — a first-class committed deliverable with planted broken links (one per failure class), valid-link traps (one per false-positive class), and an expected-classification manifest. |
| **Verdict** | The outcome of checking one link: `clean` (link is valid), `broken` (definitively invalid), `indeterminate` (external check inconclusive). Each link has exactly one verdict (DI-005). The verdict set is closed at three values. |
| **clean** | The link-level verdict meaning the link is valid and fully resolved: the target exists and, if a fragment is present, the anchor exists in the target file. One of the three domain verdicts (`clean` \| `broken` \| `indeterminate`). **Layer note:** `clean` is a *link verdict* — it is never produced directly by the HTTP layer. In `--online` mode, the HTTP liveness outcome `alive` maps to link verdict `clean`; the report always emits `clean`, never `alive`. See `alive` below and DD-022. (DI-005) |
| **Failure Reason** | A closed, enumerated code classifying why a link is `broken`. See `failure-modes.md` for the full taxonomy. |
| **Indeterminate** | A verdict applied when the tool cannot confirm alive or broken — server responds 429, bot-403 (after GET fallback), all 5xx, or timeout. Appears in output but does NOT cause exit 1 (DI-010). |
| **alive** | The HTTP-layer liveness outcome produced when an external URL returns a 2xx status code in `--online` mode. **Layer:** HTTP liveness outcome, not link verdict. Full mapping: liveness `alive` → link verdict `clean`; liveness `broken` → link verdict `broken`; liveness `indeterminate` → link verdict `indeterminate`. `alive` does NOT appear in report output (the report emits `clean`); it is an internal classification in the liveness pipeline (DD-004, CAP-010). A fresh-context agent encountering `alive` in the codebase should NOT infer a fourth verdict — the verdict taxonomy is closed at three values (DI-005, DD-022). |
| **scan set** | The set of `.md` files for which the tool produces link-check findings (Pass 2 input scope). A file is in the scan set if and only if it was discovered by traversal AND is not excluded as a link *source* by any source-exclusion mechanism (`--ignore`, `.gitignore`, dot-directory skip, scan-root boundary). |
| **anchor-target universe** | The superset of all `.md` files whose anchor tables are built and made available for cross-file anchor resolution. Includes every file in the scan set plus any `.md` files outside the scan set that are referenced as link destinations by in-scan-set links (DI-006). Populated by Pass 1 (scan set) and Pass 1.5 (out-of-scan targets). |
| **Pass 1.5** | The intermediate pipeline phase (between Pass 1 and Pass 2) that identifies `.md` link destinations not reachable by the main Pass 1 traversal and builds their anchor tables and directory entry indices. Ensures DI-006 holds for links into `.gitignore`-excluded files, dot-directory files, and out-of-root targets. See architecture/system-overview.md §Three-Phase Pipeline. |

## Domain Entities

### MarkdownFile

A `.md` file discovered during traversal (`.md` only, case-sensitive — DD-019; `.markdown` and `.mdx` are explicit non-goals).

| Attribute | Type | Notes |
|-----------|------|-------|
| path | absolute path | canonicalized, NFC-normalized |
| content | UTF-8 string | BOM stripped, CRLF normalized |
| line-start-offsets | Vec\<usize\> | byte→line number lookup table |
| links | Vec\<Link\> | extracted after parsing |
| anchor-table | AnchorTable | built three-phase (Pass 1 → Pass 1.5; DI-008) |
| io-error | Option\<FailureReason\> | non-None triggers exit 2 |

### Link

One link occurrence within a MarkdownFile.

| Attribute | Type | Notes |
|-----------|------|-------|
| source-file | path | file containing the link |
| byte-range | Range\<usize\> | byte offset from `OffsetIter` |
| line | u32 | 1-based, derived from byte-range |
| column | u32 | 1-based, derived from byte-range |
| raw-destination | String | before any decode or split |
| path-component | String | before `#`, after percent-decode |
| fragment-component | Option\<String\> | after first `#`, percent-decoded |
| kind | LinkKind | `relative-file`, `anchor-only`, etc. |
| verdict | Verdict | assigned exactly once (DI-005) |

### AnchorTable

The set of valid anchor slugs for one file.

`AnchorTable` is a newtype: `AnchorTable(HashSet<String>)`. The `file` a table belongs
to is the `HashMap<PathBuf, AnchorTable>` key in the calling module — NOT a field of
`AnchorTable` itself. There is no `file` attribute on `AnchorTable`.

| Attribute | Type | Notes |
|-----------|------|-------|
| slugs | HashSet\<String\> | all valid fragment values (the wrapped set) |

Built by: (1) slug-compute all headings; (2) extract HTML `id` + `name` attrs.
Always complete before any link into the file is validated (DI-008).

### ExternalUrl

A deduplicated http(s) URL. Many Link instances share one ExternalUrl.

| Attribute | Type | Notes |
|-----------|------|-------|
| url | String | normalized, scheme + authority + path |
| verdict | Verdict | computed once per URL per run |
| http-status | Option\<u16\> | for `--online` mode |
| failure-reason | Option\<FailureReason\> | set when verdict is `broken` |

### IgnoreRule

A compiled globset pattern applied against the CWD-relative path of each file.
Matching files are excluded as link *sources* but their anchor tables are still built.

### AllowRule

A normalized URL prefix (scheme + authority + path) against which external URL
destinations are tested. A matching URL is exempted from both syntax validation and
liveness checking. Prefix matching uses normalized URL components, NOT naive byte
comparison (prevents `example.com.evil.tld` bypass — DD-013).

### Report

The complete output of a scan run: ordered list of findings (sorted by DI-001),
run metadata, and exit code. Emitted as human-readable text (default) or JSON
(`--format json`, DD-011).
