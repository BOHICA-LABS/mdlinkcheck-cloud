---
document_type: domain-spec-section
level: L2
section: capabilities
version: "1.6"
status: draft
producer: business-analyst
timestamp: 2026-08-05T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/planning/brief-validation.md
  - .factory/planning/market-intelligence.md
input-hash: "62dc24f"
traces_to: L2-INDEX.md
changelog:
  - version: "1.6"
    date: 2026-08-06
    change: "Exit-code ruling: CAP-014 updated with two fixes: (1) 'nonexistent PATH argument' moved from 'usage error' category to 'I/O error' category — it is recorded into io_errors and scanning continues per DD-007, consistent with all three SS-14 BCs and BC-2.01.009; (2) config_error canonical membership collapsed to sole trigger: invalid --ignore glob pattern, routed through verdict::exit_code with config_error=true. Unrecognized flags are handled by clap before app::run() and do not set config_error."
  - version: "1.5"
    date: 2026-08-06
    change: "P3-010 governance gap closure (DD-027): CAP-005 updated to reference DI-012 and DI-013 (anchor table correctness depends on slug computation fidelity and anchor-key uniqueness); CAP-006 updated to name DI-012 and DI-013 as its governing invariants."
  - version: "1.4"
    date: 2026-08-05
    change: "Pass-2 adversarial remediation: CAP-008 — added fragment-presence discriminator for directory targets (directory + no fragment = clean; directory + fragment = broken(target-is-directory)); P2-M07. CAP-011 — added WHATWG-normalize-then-prefix-match with raw-string fallback at component boundary when normalization fails (D-019/DD-025); P2-M08. CAP-013 — corrected from impossible 'JSON array with schema_version field' to correct JSON object envelope {schema_version, results[], errors[]}; R6 interpretation recorded as D-017/DD-023; P2-M11. CAP-014 — added usage errors as third explicit input; P2-M19."
  - version: "1.3"
    date: 2026-08-05
    change: "Orchestrator ruling DD-022: CAP-010 updated to distinguish URL liveness outcome (`alive` → HTTP layer) from link verdict (`clean` → domain layer); explicit mapping stated in CAP-010 body. CAP-009 confirmed correct — it produces link verdict `broken` directly via syntax check, no liveness layer involved."
  - version: "1.2"
    date: 2026-08-05
    change: "Phase 1d gate remediation: CAP-001 Grounding fixed — extension match is case-sensitive .md only (.MD/.markdown/.mdx are non-goals per DD-019/D-012); dot-directory skip noted as unconditional (DD-018/D-011). CAP-008 — removed incorrect DEC-009 reference for directory targets (DEC-009 is case-mismatch, not directory/non-Markdown). CAP-010 — added explicit classification of dns-failure and tls-error as broken (confirmed from failure-modes.md taxonomy). CAP-011 — clarified that --allow performs normalize-then-prefix-match (DD-013). Self-review pass per adversary context-budget gap noted in F-001 Observations."
  - version: "1.1"
    date: 2026-08-05
    change: "Phase 1d F-005 remediation: CAP-005 and CAP-011 descriptions updated to reflect widened DI-006 (all source-exclusion mechanisms, not --ignore only)"
  - version: "1.0"
    date: 2026-08-05
    change: "Initial draft"
---

# Section 1: Domain Capabilities

> **Sharded L2 section (DF-021).** Navigate via `L2-INDEX.md`.

Capabilities describe **what** the system does, not how. Each is grounded in the
product brief requirement indicated. Priority: P0 = must-have, P1 = should-have.

---

## CAP-001: File Discovery

Recursively discover `.md` files (case-sensitive, exact extension — DD-019) under the
given path arguments, applying unconditional dot-directory skip (DD-018), `.gitignore`
exclusion, and path deduplication. Default scan root is `.`.

**Grounding:** R1 — "`mdlinkcheck [PATH]...` scans the given files/directories
(default `.`) for `*.md` files." Extension match is **case-sensitive**; `.md` only.
`.MD`, `.markdown`, and `.mdx` are explicit non-goals (DD-019). Dot-directory skip is
unconditional — `--hidden` is a dropped non-goal (DD-018). **Priority: P0**

---

## CAP-002: Markdown Parsing

Parse each discovered Markdown file into a structured AST event stream using the
CommonMark 0.31.2 + GFM grammar (AST-based, not regex; pulldown-cmark 0.13.4).
Capture byte offsets for every link and heading for line/column reporting.

**Grounding:** R2, R3, R4 foundation — all extraction and resolution depend on a
correctly parsed document. Grammar pinned by DD-006. **Priority: P0**

---

## CAP-003: Link Extraction

From the parsed event stream, extract all links (inline, reference-style, collapsed,
shortcut, image) that fall outside code contexts. Distinguish link kinds:
`relative-file`, `anchor-only`, `cross-file-anchor`, `external-http`, `non-http`
(silently skipped per DD-009), `undefined-reference`.

**Grounding:** R2 ("every link"), R3 ("reference-style links and images checked the
same as inline ones"). **Priority: P0**

---

## CAP-004: Code Context Exclusion

Identify regions of a document constituting code context: fenced blocks (backtick and
tilde), inline code spans (single and double backtick), indented code blocks
(4-space), HTML `<pre>`/`<code>`, HTML comments. Links within these regions are
never extracted. Exclusion is structural (AST event matching), not heuristic.

**Grounding:** R4 — "Links inside fenced code blocks and inline code spans are
IGNORED." With pulldown-cmark, this is satisfied by only matching `Tag::Link` /
`Tag::Image` events — see market-intelligence §4.2. **Priority: P0**

---

## CAP-005: Anchor Table Construction

For every file in the anchor-target universe (per DI-006), build the complete anchor
table: (1) enumerate all headings from the AST; (2) extract `id` and `name` attributes
from inline/raw HTML elements (narrow carve-out, DI-007). The anchor-target universe
includes files in the scan set, `--ignore`d files, `.gitignore`-excluded files,
dot-directory files, and files outside the scan root — whenever an in-scan-set link
points directly at them. The table for each file must be fully built before any link
into that file is validated (DI-008). Anchor table correctness depends on slug
computation fidelity (DI-012) and anchor-key uniqueness within each file (DI-013),
both satisfied by CAP-006.

**Grounding:** R2b — "anchor must match a heading in the target file." **Priority: P0**

---

## CAP-006: Heading Slug Computation

Transform a heading's rendered text content into a GitHub-compatible anchor slug
using the verbatim github-slugger v2 algorithm (DD-015), including 0-based per-file
duplicate disambiguation via the `while(occurrences contains result)` loop. The
per-heading character-level transformation is governed by DI-012 (slug computation
fidelity); the file-global injectivity of the resulting anchor-key mapping is
governed by DI-013 (anchor-key uniqueness within a file).

**Grounding:** R2b — "using GitHub's slug algorithm." Algorithm pinned in DD-015 and
`decisions.md`. Governed by DI-012, DI-013. **Priority: P0**

---

## CAP-007: Relative Path Resolution

Resolve a relative or root-relative link destination against the containing file's
directory (root-relative: against git repo root or scan root). Percent-decode the
path component before resolution. Apply case-sensitive NFC-normalized directory-entry
comparison (DI-002). Fragment split before decode (DI-003).

**Grounding:** R2a — "Relative file links ... target must exist." **Priority: P0**

---

## CAP-008: Anchor Resolution

Given a fragment split from a link destination, validate it against the target file's
anchor table. Percent-decode the fragment before comparison. Skip the anchor check for
non-Markdown targets (DEC-008). For directory targets, `path_resolver` decides without
invoking `anchor_resolver`: no fragment → verdict `clean`; fragment present → verdict
`broken(target-is-directory)` (BC-2.07.005). Pass empty fragments without check (DEC-007).

**CAP-008 anchor justification:** Covers anchor resolution and the directory-target
discriminator because directory targets cannot have anchor tables; the fragment-presence
rule is the BC-2.07.005 v1.1 addition. Grounded in R2b.

**Grounding:** R2b — "anchor must match a heading in the target file." **Priority: P0**

---

## CAP-009: External URL Syntax Validation

When a link destination is an http(s) URL (including CommonMark `<https://x>`
autolinks), validate it against the WHATWG URL grammar without network access. Syntax
failure produces a `broken` verdict with reason `malformed-url` and counts toward exit
1. Applied in both offline (default) and online mode.

**Grounding:** R2c — "external URLs are syntax-validated but not fetched."
Decision DD-010. **Priority: P1**

---

## CAP-010: External URL Liveness Checking

When `--online` is passed, check each unique external http(s) URL via HEAD request
(GET fallback on DD-016 status codes), 10-second per-URL total timeout, 2 retries
with backoff for transient failures. Produce URL liveness outcome `alive` (2xx),
`broken`, or `indeterminate` per URL. Liveness outcome `alive` maps to link verdict
`clean`; `broken` and `indeterminate` map directly to the same-named link verdicts.
DNS resolution failure (`dns-failure`) and TLS handshake failure (`tls-error`) are
liveness `broken` → link verdict `broken` → exit 1. Transient conditions (429,
bot-403, 5xx, timeout) are liveness `indeterminate` → link verdict `indeterminate` →
do NOT cause exit 1 (DI-010). See DD-022 for the two-layer model.

**Grounding:** R2c — "HEAD request (GET fallback on 405), 10s timeout, checked ONLY
when `--online` is passed." Fallback set widened by DD-016. **Priority: P1**

---

## CAP-011: Filter Application

Evaluate `--ignore <glob>` (globset dialect, DD-013) against discovered file paths,
excluding matched files as link *sources* only. `--ignore` is one of four
source-exclusion mechanisms (`--ignore`, `.gitignore` patterns, dot-directory skip,
scan-root boundary); none suppress anchor-table construction for files in the
anchor-target universe (DI-006). Evaluate `--allow <url-prefix>` against external URLs using a two-step algorithm
(D-019/DD-025): (1) attempt WHATWG normalization of the candidate URL; (2) if
normalization succeeds, perform component-boundary prefix match against the normalized
form; (3) if WHATWG normalization fails (URL is syntactically malformed), fall back to
raw-string prefix match at a component boundary. A match by either path exempts the URL
from syntax and liveness checks. The component-boundary requirement — `example.com` must
NOT match `example.com.evil.tld` — is mandatory in both the normalized and raw-string
paths.

**Grounding:** R5 — "`--ignore <glob>` ... excludes files; `--allow <url-prefix>`
... exempts external URLs." D-019/DD-025. **Priority: P1**

---

## CAP-012: Text Report Generation

Emit findings on stdout in human-readable text, sorted by (NFC-normalized file path,
line number, column number) per DI-001. Each finding: `file:line: link-target —
reason`. Suppress ANSI color when output is not a TTY or `NO_COLOR` is set. Emit
diagnostics and progress on stderr (DD-014).

**Grounding:** R6 — "human-readable text (default) listing file:line, link target,
and failure reason." **Priority: P0**

---

## CAP-013: JSON Report Generation

When `--format json` is passed, emit findings on stdout as a JSON object envelope with
three top-level fields: `schema_version` (integer 1), `results` (array of finding
objects sorted identically to the text report per DI-001), and `errors` (array of I/O
diagnostic objects). Each `results` element: `{file, line, column, link_target, verdict,
reason}`. Diagnostics remain on stderr. R6's "machine-readable array" is satisfied by
the `results` array inside the versioned envelope; the object envelope is the
authoritative shape (D-017/DD-023).

**Grounding:** R6 — "`--format json` emits a machine-readable array of the same."
DD-011, DD-023. **Priority: P1**

---

## CAP-014: Exit Code Determination

Compute the process exit code as a pure function of three inputs: the verdict multiset
(`findings`), the I/O error list (`io_errors`), and the configuration error flag
(`config_error`). All three are passed to `verdict::exit_code(findings, io_errors, config_error)`.

Exit rules:
- **0** — all verdicts `clean` or `indeterminate`; `io_errors` is empty; `config_error` is false.
- **1** — at least one `broken` verdict; `io_errors` is empty; `config_error` is false.
- **2** — `io_errors` is non-empty (any I/O error: unreadable `.md` file, nonexistent PATH
  argument) OR `config_error = true` (sole trigger: invalid `--ignore` glob pattern, the
  sole `config_error` trigger — routed through `verdict::exit_code` with `config_error=true`; scan
  does not start). Precedence: exit 2 > exit 1 (DI-011).

**io_errors vs. config_error partition:**
- `io_errors` receives: unreadable `.md` file encountered during scan; nonexistent PATH
  argument (recorded into `Vec<IoError>`; scanning continues for remaining valid paths per
  DD-007 no-fail-fast).
- `config_error = true` receives: invalid `--ignore` glob pattern only (detected by
  `globset` after clap parsing; `app` sets `config_error=true` before any traversal).
- Unrecognized flags and `--help`/`--version` are handled by clap before `app::run()` is
  called and do NOT set `config_error`. They never reach `verdict::exit_code`.

`indeterminate` verdicts never raise the exit code. An `indeterminate`-only run always exits 0.

**Grounding:** R7 — "Exit codes: 0 = no broken links; 1 = at least one broken link;
2 = usage or I/O error." **Priority: P0**
