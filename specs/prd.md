---
document_type: prd
level: L3
version: "1.15"
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
supplements:
  - prd-supplements/interface-definitions.md
  - prd-supplements/error-taxonomy.md
  - prd-supplements/test-vectors.md
  - prd-supplements/nfr-catalog.md
modified:
  - "1.14 (2026-08-09): BI-053 follow-up — undecodable-fragment boundary case specified in BC-2.07.004 (v1.5) and BC-2.08.001 (v1.5). All five authoritative sources silent; symmetric pass-through rule adopted (invalid percent sequences used raw for anchor lookup → anchor-not-found; no new reason code required)."
  - "1.13 (2026-08-09): BI-053 fix — fragment percent-decode inversion resolved in BC-2.07.004 (v1.4) and BC-2.08.001 (v1.4). Both BCs had inverted DI-003/CAP-008 by forbidding fragment decode; corrected to require percent-decode before anchor lookup. Resolves adversary pass-7 findings P7-S3-001 and P7-S4-002."
  - "1.12 (2026-08-07): EC-count reconciliation for EC-205..EC-213 — declared 203→212, range EC-001..EC-204→EC-001..EC-213; ID 102 retired per D-010 documented in §5b"
---

# Product Requirements Document: mdlinkcheck

> **BC Index Model:** This PRD is an index document. Each Behavioral Contract (BC)
> lives in its own file under `behavioral-contracts/ss-NN/`. Do NOT inline full
> contract details here.

## 1. Product Overview

### 1.1 Problem Statement

Documentation repositories accumulate link rot: files move, headings get renamed,
external sites die. CI build systems need a deterministic, fast tool that fails the
build when links break. The dominant failure mode of existing tools is **false positives
that train engineers to ignore CI failures** — particularly from: (a) links inside code
fences being extracted as real links, (b) HEAD-based external checks that 403/429 on
every CI run, and (c) case-insensitive filesystem delegation on macOS APFS producing silent false negatives
that the host filesystem would not catch without explicit directory-entry comparison.

### 1.2 Solution Vision

`mdlinkcheck` is a CLI tool written in Rust (MSRV 1.85) that scans Markdown files using
an AST-based parser (pulldown-cmark 0.13.4), checks every extracted link against a
closed failure-reason taxonomy, and exits nonzero **only on definitive breakage**. The
default mode is offline; external URL checking is opt-in via `--online`. Anchor checking
uses the verbatim github-slugger v2 algorithm and is on by default. Output is
deterministically sorted; both text and JSON formats are supported.

**Pilot scope note (ASM-003):** mdlinkcheck is a VSDD factory pilot on a deliberately
well-understood problem shape. Differentiation vs. lychee 0.24.2 (which covers a superset
of R1–R8) is not a product goal. The honest differentiators are: (1) anchor checking
correct and on by default — lychee has open bugs #1457/#1613/#1709; (2) a smaller,
formally-hardenable surface; (3) a complete Phase 6 (Kani/fuzz/mutation) proof record.

### 1.3 Key Differentiators

| ID | Differentiator | Description |
|----|---------------|-------------|
| KD-001 | Correct anchor checking, on by default | Every competitor either lacks it, gates it behind a flag, or has open false-positive/negative bugs. Covered by BC-2.05.*, BC-2.06.*, BC-2.08.* |
| KD-002 | Offline-by-default | No network traffic in default mode; external checks are opt-in. Eliminates 429/bot-block false positives entirely in the common case. Covered by BC-2.09.001, BC-2.10.* |
| KD-003 | Source-level file:line reporting | Reports the `.md` source line, not generated HTML. Post-render tools (htmltest, Sphinx) cannot do this. Covered by BC-2.12.001, BC-2.13.001 |
| KD-004 | Case-correct path resolution | Performs exact-case directory-entry comparison — never delegates to macOS APFS case-folding. Determinism-grounded (D-043/D-006): verdicts depend on repository content, not filesystem behaviour. No surveyed tool does this. Covered by BC-2.07.003 |
| KD-005 | Deterministic exit codes | 0/1/2 semantics documented and tested. No flakiness from indeterminate conditions. Covered by BC-2.14.* |

### 1.4 Target Users

| Persona | Description | Volume | Pain Level |
|---------|-------------|--------|------------|
| CI Engineer | Runs `mdlinkcheck` in GitHub Actions / CI pipeline; needs machine-readable output, stable exit codes, no flaky failures | Primary | High — current tools cause CI noise |
| Documentation Author | Runs `mdlinkcheck` locally before committing; needs fast feedback, human-readable output, color highlighting | Secondary | Medium — discovers rot late |

### 1.5 Out of Scope

- Link rewriting or fixing
- HTML parsing (beyond narrow `id=`/`name=` attribute extraction from inline HTML)
- JavaScript rendering
- Config file (flags only)
- Watch mode
- Inline suppression directives (`<!-- mdlinkcheck-disable -->`)
- GFM bare-URL autolinks (`https://x.com` in plain prose — pulldown-cmark does not support them; document as limitation)
- `<a href>` and `<img src>` raw HTML link destinations
- Cross-run result caching
- `--format xml` or other output formats beyond `text` and `json`
- Anchor verification on external URLs (no HTML fetching/parsing)
- **Explicit non-goals (D-011):** `--quiet` (summary suppression), `--offline` (explicit offline pin), `--insecure` (TLS bypass), `--hidden` (dot-directory inclusion) — these flags are not supported in v1.0
- **Explicit non-goal (D-012):** `.markdown`, `.MD`, `.mdx` and other non-`.md` extensions — only `.md` (exact, case-sensitive) is discovered during traversal
- Third-party corpus content creation (the `tests/corpus/` manifest schema is defined in
  `prd-supplements/interface-definitions.md` §10; corpus authorship IS in scope per D-009)

---

## 2. Behavioral Contracts Index

> BCs grouped by L2 domain subsystem (CAP-NNN). Subsystem IDs (SS-NN) are provisional
> — architect will confirm in Phase 1b. Files in `behavioral-contracts/ss-NN/`.

### 2.1 File Discovery (CAP-001) — SS-01

<!-- BEGIN GENERATED: prd-s2-ss-01 -->
| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.01.001 | Recursive `.md` Discovery with Default Scan Root | P0 |
| BC-2.01.002 | Explicit PATH Arguments Override Default Root | P0 |
| BC-2.01.003 | `.gitignore` and `.ignore` Exclusion During Traversal | P0 |
| BC-2.01.004 | Dot-Directory Skip (Unconditional) and Directory-Symlink Non-Following | P0 |
| BC-2.01.005 | Extension Matching — `.md` Only, Case-Sensitive | P0 |
| BC-2.01.006 | File Symlink Following with Dangling-Symlink Detection | P1 |
| BC-2.01.007 | Path Deduplication for Overlapping PATH Arguments | P1 |
| BC-2.01.008 | Zero Markdown Files Found Yields Exit 0 with Stderr Message | P0 |
| BC-2.01.009 | Non-Existent or Unreadable PATH Argument Yields Exit 2 | P0 |
<!-- END GENERATED: prd-s2-ss-01 -->

> Full contracts: `behavioral-contracts/ss-01/BC-2.01.001.md` through `BC-2.01.009.md`

### 2.2 Markdown Parsing (CAP-002) — SS-02

<!-- BEGIN GENERATED: prd-s2-ss-02 -->
| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.02.001 | CommonMark + GFM AST Parsing with Byte-Offset Line Numbers | P0 |
| BC-2.02.002 | UTF-8 BOM Stripping and CRLF Normalization (Shell-Side) | P0 |
| BC-2.02.003 | Non-UTF-8 File Reported as Per-File I/O Error; Scan Continues | P0 |
| BC-2.02.004 | Explicit Non-`.md` File Argument Is Parsed (Not Skipped) | P1 |
<!-- END GENERATED: prd-s2-ss-02 -->

> Full contracts: `behavioral-contracts/ss-02/BC-2.02.001.md` through `BC-2.02.004.md`

### 2.3 Link Extraction (CAP-003) — SS-03

<!-- BEGIN GENERATED: prd-s2-ss-03 -->
| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.03.001 | Inline Link and Image Extraction with Kind Classification | P0 |
| BC-2.03.002 | Full Reference-Style, Collapsed, and Shortcut Link/Image Forms | P0 |
| BC-2.03.003 | Undefined Reference Label Yields `broken` Verdict | P0 |
| BC-2.03.004 | CommonMark Autolinks In Scope; GFM Bare-URLs Out of Scope | P0 |
| BC-2.03.005 | Non-http(s) Schemes Silently Skipped with `clean` Verdict | P0 |
| BC-2.03.006 | Footnote References Excluded; Escaped Brackets Are Not Links | P1 |
<!-- END GENERATED: prd-s2-ss-03 -->

> Full contracts: `behavioral-contracts/ss-03/BC-2.03.001.md` through `BC-2.03.006.md`

### 2.4 Code Context Exclusion (CAP-004) — SS-04

<!-- BEGIN GENERATED: prd-s2-ss-04 -->
| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.04.001 | Fenced Code Blocks and Inline Code Spans Yield No Links | P0 |
| BC-2.04.002 | Indented Code Blocks and HTML Comments Yield No Links | P0 |
| BC-2.04.003 | ATX Headings Inside Fenced Blocks Do Not Create Anchor Entries | P0 |
<!-- END GENERATED: prd-s2-ss-04 -->

> Full contracts: `behavioral-contracts/ss-04/BC-2.04.001.md` through `BC-2.04.003.md`

### 2.5 Anchor Table Construction (CAP-005) — SS-05

<!-- BEGIN GENERATED: prd-s2-ss-05 -->
| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.05.001 | Three-Phase Design — Full Anchor Table Before Any Resolution | P0 |
| BC-2.05.002 | ATX and Setext Heading Extraction into Anchor Table | P0 |
| BC-2.05.003 | HTML `id=` and `name=` Attribute Extraction into Anchor Table | P1 |
<!-- END GENERATED: prd-s2-ss-05 -->

> Full contracts: `behavioral-contracts/ss-05/BC-2.05.001.md` through `BC-2.05.003.md`

### 2.6 Heading Slug Computation (CAP-006) — SS-06

<!-- BEGIN GENERATED: prd-s2-ss-06 -->
| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.06.001 | github-slugger v2 Core Algorithm | P0 |
| BC-2.06.002 | github-slugger v2 Duplicate-Heading Counter with Collision Bump | P0 |
<!-- END GENERATED: prd-s2-ss-06 -->

> Full contracts: `behavioral-contracts/ss-06/BC-2.06.001.md`, `BC-2.06.002.md`

### 2.7 Relative Path Resolution (CAP-007) — SS-07

<!-- BEGIN GENERATED: prd-s2-ss-07 -->
| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.07.001 | Relative Path Resolution Against Source File's Directory | P0 |
| BC-2.07.002 | Root-Relative Link Resolution Using Git Repo Root | P1 |
| BC-2.07.003 | NFC Normalization and Case-Sensitive Exact Directory-Entry Comparison | P0 |
| BC-2.07.004 | Percent-Encoding in File Path Destinations | P1 |
| BC-2.07.005 | Destination-Is-Directory Verdict | P0 |
| BC-2.07.006 | Non-Markdown Target — File Existence Check Only, Anchor Resolution Skipped | P0 |
| BC-2.07.007 | Empty Link Destination → Malformed URL | P0 |
| BC-2.07.008 | Trailing Slash on Regular File → file-not-found | P0 |
<!-- END GENERATED: prd-s2-ss-07 -->

> Full contracts: `behavioral-contracts/ss-07/BC-2.07.001.md` through `BC-2.07.008.md`

### 2.8 Anchor Resolution (CAP-008) — SS-08

<!-- BEGIN GENERATED: prd-s2-ss-08 -->
| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.08.001 | Anchor-Only Link Resolution (`#fragment`) | P0 |
| BC-2.08.002 | Cross-File Anchor Resolution (`path.md#fragment`) | P0 |
| BC-2.08.003 | Fragment Split at First Unescaped `#` Before Percent-Decode | P0 |
| BC-2.08.004 | Cross-File Anchor Into Ignored-Source File | P1 |
<!-- END GENERATED: prd-s2-ss-08 -->

> Full contracts: `behavioral-contracts/ss-08/BC-2.08.001.md` through `BC-2.08.004.md`

### 2.9 External URL Syntax Validation (CAP-009) — SS-09

<!-- BEGIN GENERATED: prd-s2-ss-09 -->
| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.09.001 | External URL Syntax Validation (Offline) | P0 |
| BC-2.09.002 | `--allow` URL Exemption — Specification in BC-2.11.002 | P0 |
<!-- END GENERATED: prd-s2-ss-09 -->

> Full contracts: `behavioral-contracts/ss-09/BC-2.09.001.md`, `BC-2.09.002.md`

### 2.10 External URL Liveness Checking (CAP-010) — SS-10

<!-- BEGIN GENERATED: prd-s2-ss-10 -->
| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.10.001 | HEAD-then-GET Fallback Protocol (`--online` mode) | P0 |
| BC-2.10.002 | Three-Verdict Model (alive/broken/indeterminate) — Total Partition | P0 |
| BC-2.10.003 | Per-URL 10-Second Timeout | P0 |
| BC-2.10.004 | 429 Rate-Limit Handling — Pause Host, Resume After Retry-After | P0 |
| BC-2.10.005 | DNS Resolution Failure Yields `broken` Verdict | P0 |
| BC-2.10.006 | TLS Handshake Failure Behavior | P0 |
| BC-2.10.007 | Redirect Chain Handling (Max 10 Hops) | P0 |
| BC-2.10.008 | Concurrency — Dedicated Pool, 32 Global / 4 Per-Host Request Limits | P1 |
| BC-2.10.009 | URL Deduplication — Each Unique External URL Fetched Once, Verdict Reported at Every Occurrence | P0 |
| BC-2.10.010 | Private-IP and Link-Local URL Classification (Indeterminate, No Outbound Request) | P0 |
<!-- END GENERATED: prd-s2-ss-10 -->

> Full contracts: `behavioral-contracts/ss-10/BC-2.10.001.md` through `BC-2.10.010.md`

### 2.11 Filter Application (CAP-011) — SS-11

<!-- BEGIN GENERATED: prd-s2-ss-11 -->
| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.11.001 | `--ignore` Glob Exclusion (Source Files Only) | P0 |
| BC-2.11.002 | `--allow` URL Prefix Exemption with Component-Boundary Safety | P0 |
| BC-2.11.003 | `--ignore` on Explicit PATH Argument | P1 |
| BC-2.11.004 | Invalid `--ignore` Glob → Exit 2 Before Scanning Begins | P0 |
<!-- END GENERATED: prd-s2-ss-11 -->

> Full contracts: `behavioral-contracts/ss-11/BC-2.11.001.md` through `BC-2.11.004.md`

### 2.12 Text Report Generation (CAP-012) — SS-12

<!-- BEGIN GENERATED: prd-s2-ss-12 -->
| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.12.001 | Text Report Format — One Finding per Line, Deterministic Order | P0 |
| BC-2.12.002 | Terminal Color Output with NO_COLOR / CLICOLOR / CLICOLOR_FORCE | P1 |
| BC-2.12.003 | Stderr Summary Line (Always Emitted) | P0 |
| BC-2.12.004 | `--format text` Explicit Alias Is Accepted | P1 |
| BC-2.12.005 | Stdout/Stderr Separation for Text Format | P0 |
<!-- END GENERATED: prd-s2-ss-12 -->

> Full contracts: `behavioral-contracts/ss-12/BC-2.12.001.md` through `BC-2.12.005.md`

### 2.13 JSON Report Generation (CAP-013) — SS-13

<!-- BEGIN GENERATED: prd-s2-ss-13 -->
| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.13.001 | JSON Report Format — `{"schema_version":1,"results":[...],"errors":[...]}` to Stdout | P0 |
| BC-2.13.002 | JSON Schema Stability Contract | P1 |
<!-- END GENERATED: prd-s2-ss-13 -->

> Full contracts: `behavioral-contracts/ss-13/BC-2.13.001.md`, `BC-2.13.002.md`

### 2.14 Exit Code Determination (CAP-014) — SS-14

<!-- BEGIN GENERATED: prd-s2-ss-14 -->
| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.14.001 | Exit Code 0 — No Broken Links | P0 |
| BC-2.14.002 | Exit Code 2 Takes Precedence Over Exit Code 1 | P0 |
| BC-2.14.003 | Exit Code 1 — At Least One Broken Link Found | P0 |
| BC-2.14.004 | `--help` and `--version` Exit 0 Without Scanning | P0 |
<!-- END GENERATED: prd-s2-ss-14 -->

> Full contracts: `behavioral-contracts/ss-14/BC-2.14.001.md` through `BC-2.14.004.md`

---

## 3. Interface Definition

> **Supplement:** Full definitions in `prd-supplements/interface-definitions.md`.

Summary: CLI invocation is `mdlinkcheck [OPTIONS] [PATH]...`. Key flags: `--format {text|json}`, `--ignore <glob>` (repeatable), `--allow <url-prefix>` (repeatable), `--online`. **Explicit non-goals (D-011):** `--offline`, `--insecure`, `--hidden`, `--quiet` are not supported in v1.0. Findings go to stdout; diagnostics and summary (always emitted) go to stderr. Exit codes: 0/1/2. JSON schema: `{schema_version: 1, results: [{file, line, column, link_target, verdict, reason}]}`.

**PRD Decisions Resolving Deferred L2 Questions:**

| AMB | Decision | Rationale |
|-----|----------|-----------|
| AMB-018 | Root-relative links resolved against git repo root (`git rev-parse --show-toplevel`); if not a git repo, against the first PATH argument (or CWD if default) | Matches GitHub rendering behavior; deterministic fallback |
| AMB-037 | Redirects: follow up to 10 hops; detect loops by URL deduplication; https→http downgrade allowed with an `indeterminate` warning appended to finding; redirect to 200-but-wrong-content is undetectable (documented limitation) | 10 hops is the de facto web standard; downgrade warning prevents silent security downgrades from being treated as clean |
| AMB-040 | Per-host concurrency cap: 4 connections; global cap: 32; no explicit politeness delay | Politeness is covered by per-host cap; avoids per-host rate-limiting under normal conditions |
| AMB-041 | User-Agent: `mdlinkcheck/<version> (+https://github.com/jmagady/mdlinkcheck)` | Identifies tool to server admins; link enables contact for blocking issues |
| AMB-042 | `--insecure` flag: **not supported (D-011 explicit non-goal)**. TLS certificate verification is always enforced; TLS failures produce `broken` verdict (`tls-error`). No flag overrides this in v1.0. Corporate CA environments must use system CA store. | --insecure creates security ambiguity and audit complexity; it is better to document as a known limitation for users with non-standard CAs |
| AMB-043 | Proxy: honor `HTTP_PROXY`, `HTTPS_PROXY`, `NO_PROXY` standard env vars (passed through to ureq) | Standard convention; required for corporate CI |
| `--format text` | Accepted explicitly as an alias for the default format; `--format xml` etc. → exit 2 | Explicit `--format text` in shell scripts prevents surprise when defaults change |
| Summary line | `N broken link(s) in M file(s).` on stderr; on zero findings: `No broken links found.`; **always emitted** (D-011: `--quiet` is a non-goal) | Goes to stderr for stdout purity; consistent human-readable conclusion |

**Binding Interpretation Note — R6 / D-017 (JSON Output Shape):**
The frozen brief (R6) states output "may be formatted as an array". This is superseded by D-017: the JSON output is an **object envelope** `{"schema_version": 1, "results": [...], "errors": [...]}`. The `results` array contains finding objects; the `errors` array contains I/O error objects. Consumers MUST read `.results`, not treat the top-level value as an array. The `schema_version` field enables consumers to detect schema changes. See BC-2.13.001 for the full contract; see `prd-supplements/interface-definitions.md` §6 for the full schema.

---

## 4. Non-Functional Requirements

> **Supplement:** Full NFR catalog in `prd-supplements/nfr-catalog.md`.

| NFR ID | Category | Target | Validation |
|--------|----------|--------|------------|
| NFR-001 | Performance (Tier A) — **active** | p95 ≤ 5s for 500 .md files, offline, aarch64-apple-darwin dev laptop, release+LTO, warm cache, 10 runs (D-013) | `hyperfine` benchmark in `benches/` |
| NFR-002 | Performance (Tier B) — **active** | p95 ≤ 10s same corpus on macOS CI runner (`macos-latest`, Apple Silicon M1 shared; D-013, retargeted per D-043) | CI benchmark job |
| NFR-003 | Determinism | Two runs over identical inputs produce byte-identical stdout | Property test |
| NFR-004 | Portability — **retired (D-043)** | ~~Test suite passes on macOS, Linux, Windows CI matrix~~ — retired; macOS-only platform matrix. `unicode-normalization` crate pin remains per DI-001/DI-002 (see nfr-catalog.md). | ~~CI matrix~~ |
| NFR-005 | Memory | Peak RSS ≤ 512 MB for 500-file corpus | `\time -l` (macOS) |
| NFR-006 | Anchor algorithm fidelity | All DD-015 worked examples pass as unit tests | Unit test suite |
| NFR-007 | Correctness — No Undefined Reason Codes | 100% — zero unrecognized reason strings in text or JSON output | Unit/integration tests |
| NFR-008 | CI Regression Gate — **active** | p95 ≤ ~500ms for 100-file corpus on `macos-latest` CI runner; merge-blocking per-commit benchmark (D-013, VP-022, updated D-043) | `hyperfine` in `perf-gate` CI job |

> See `prd-supplements/nfr-catalog.md` for full specification.

---

## 5. Error Taxonomy

> **Supplement:** Full taxonomy in `prd-supplements/error-taxonomy.md`.

The closed set of failure reason codes (from `failure-modes.md`):

| Code | Verdict | Exit Code |
|------|---------|-----------|
| `file-not-found` | broken | 1 |
| `target-is-directory` | broken | 1 |
| `broken-symlink` | broken | 1 |
| `anchor-not-found` | broken | 1 |
| `undefined-reference-definition` | broken | 1 |
| `malformed-url` | broken | 1 |
| `http-error` | broken | 1 |
| `dns-failure` | broken | 1 |
| `tls-error` | broken | 1 |
| `too-many-redirects` | broken | 1 |
| `target-unreadable` | — (I/O error) | 2 |
| `http-timeout` | indeterminate | 0 |
| `http-indeterminate` | indeterminate | 0 |

Nothing may fail with a reason outside this closed set.

## 5b. Test Vectors

> **Supplement:** Canonical test vectors in `prd-supplements/test-vectors.md`.

213 edge cases registered (EC-001..EC-214) (214 IDs allocated; ID 102 is retired — became TV-BV013 per D-010; EC-151 was D-010 replacement holdout burned per D-122, EC-214 as new replacement holdout) and 16 correctness traps (T1–T16) converted to executable test vectors. Includes the self-referential BV-013 vector: `mdlinkcheck BRIEF.md` MUST exit 0 (TV-BV013 is now a visible required test vector per D-010). Holdout vectors **(EC-079, EC-093, EC-094, EC-141, EC-147, EC-148, EC-214, EC-156, EC-165, EC-166, EC-167, EC-168)** reserved for holdout evaluation and NOT in the visible test suite — 12 holdouts total. EC-036, EC-049, EC-074, EC-151, EC-157, EC-158 burned to visible tests (D-020 / D-122): their holdout designation is retired; they are now normal visible tests in the suite — vectors TV-036, TV-049, TV-074, TV-151, TV-157, TV-157b, TV-158, TV-158b are present in test-vectors.md (P3-005 hotfix / v1.11 D-122 burn). DI-002/D-006/T12 flagship differentiator (KD-004 — case-sensitive filename comparison) now has falsifiable visible coverage via TV-036. EC-165..EC-168 are fresh replacement hidden scenarios (D-020) covering the same risk clusters; EC-214 is fresh replacement hidden scenario (D-122) covering heading-inside-HTML-block × cross-file anchor resolution; concrete inputs and expected outputs are stored ONLY in `.factory/holdout-scenarios/wave-scenarios/` per POL-18.

---

## 6. Competitive Differentiator Traceability

### 6.1 KD-001 — Correct Anchor Checking, On By Default

| BC ID | Contribution |
|-------|-------------|
| BC-2.05.001 | Three-phase pipeline design (Pass 1 → Pass 1.5 → Pass 2) extracts ALL headings including forward references before any link check; --ignore files' anchor tables still built, preventing false `anchor-not-found` |
| BC-2.05.003 | Narrow HTML `id=`/`name=` carve-out prevents false negatives on `<a name>` anchors |
| BC-2.06.001 | github-slugger v2 verbatim algorithm eliminates hyphen-collapsing false negatives |
| BC-2.06.002 | 0-based collision-bumping correctly handles multi-level duplicate heading sequences |
| BC-2.08.003 | Fragment split before decode prevents Sphinx-#13620-class false negatives (DI-003) |
| BC-2.08.002 | Percent-decode before slug comparison catches `#caf%C3%A9` correctly |
| BC-2.08.001 | Empty anchor (`#`) passes — top-of-page convention; no false `anchor-not-found` |
| BC-2.07.006 | Non-.md file targets: existence check only; anchor lookup skipped — prevents false `anchor-not-found` on code file links |

### 6.2 KD-002 — Offline-By-Default

| BC ID | Contribution |
|-------|-------------|
| BC-2.09.001 | Syntax validation in offline mode catches malformed URLs without network |
| BC-2.10.001 | `--online` required for liveness; default mode never makes HTTP requests |
| BC-2.10.002 | 5xx/429/timeout = indeterminate — never exit 1 on transient server conditions |

### 6.3 KD-003 — Source-Level `file:line` Reporting

| BC ID | Contribution |
|-------|-------------|
| BC-2.02.001 | Byte-offset AST provides line numbers from `.md` source, not rendered HTML |
| BC-2.12.001 | Text output uses `file:line:` format referencing the `.md` source |
| BC-2.13.001 | JSON output includes `file`, `line`, `column` from source |

### 6.4 KD-004 — Case-Correct Path Resolution

| BC ID | Contribution |
|-------|-------------|
| BC-2.07.003 | Exact-case directory-entry comparison on macOS (not OS-delegated; D-043/D-006 determinism grounds) |

### 6.5 KD-005 — Deterministic Exit Codes

| BC ID | Contribution |
|-------|-------------|
| BC-2.14.001 | Exit 0 when verdict multiset contains no `broken` entries and no I/O errors |
| BC-2.14.003 | Exit 1 when at least one `broken` verdict exists (and no I/O errors) |
| BC-2.14.002 | Exit 2 beats exit 1 when any I/O error exists; no fail-fast; complete scan always performed. Together with BC-2.14.001 and BC-2.14.003, exit code is a pure function of the verdict multiset — no hidden state |
| BC-2.10.002 | Indeterminate never sets exit 1 — guarantees no false-positive exits |

---

## 7. Requirements Traceability Matrix

| BC ID | Source (L2 CAP) | L2 Invariants | Brief Req | Priority | Test Type |
|-------|----------------|---------------|-----------|----------|-----------|
| BC-2.01.001 | CAP-001 | DI-009 | R1 | P0 | integration |
| BC-2.01.002 | CAP-001 | DI-009 | R1 | P0 | integration |
| BC-2.01.003 | CAP-001 | DI-009 | R1 | P0 | integration |
| BC-2.01.004 | CAP-001 | DI-009 | R1 | P0 | integration |
| BC-2.01.005 | CAP-001 | — | R1 | P0 | unit |
| BC-2.01.006 | CAP-001 | DI-009 | R1 | P1 | integration |
| BC-2.01.007 | CAP-001 | DI-009 | R1 | P1 | unit |
| BC-2.01.008 | CAP-001 | DI-009 | R1 | P0 | integration |
| BC-2.01.009 | CAP-001 | — | R1,R7 | P0 | integration |
| BC-2.02.001 | CAP-002 | — | R2,R3,R4 | P0 | unit/integration |
| BC-2.02.002 | CAP-002 | — | R2 | P0 | unit |
| BC-2.02.003 | CAP-002 | — | R7 | P0 | integration |
| BC-2.02.004 | CAP-002 | — | R1 | P1 | integration |
| BC-2.03.001 | CAP-003 | DI-004,DI-005 | R2,R3 | P0 | unit |
| BC-2.03.002 | CAP-003 | DI-004,DI-005 | R3 | P0 | unit |
| BC-2.03.003 | CAP-003 | DI-005 | R3 | P0 | unit |
| BC-2.03.004 | CAP-003 | DI-005 | R2c | P0 | unit |
| BC-2.03.005 | CAP-003 | — | R2c | P0 | unit |
| BC-2.03.006 | CAP-003 | DI-004 | R4 | P1 | unit |
| BC-2.04.001 | CAP-004 | DI-004 | R4 | P0 | unit/property |
| BC-2.04.002 | CAP-004 | DI-004 | R4 | P0 | unit |
| BC-2.04.003 | CAP-004 | DI-004 | R4 | P0 | unit |
| BC-2.05.001 | CAP-005 | DI-006,DI-008 | R5 | P0 | integration |
| BC-2.05.002 | CAP-005 | DI-008 | R5 | P0 | unit |
| BC-2.05.003 | CAP-005 | DI-008 | R5 | P1 | unit |
| BC-2.06.001 | CAP-006 | DI-012 | R2b | P0 | unit/property |
| BC-2.06.002 | CAP-006 | DI-013 | R2b | P0 | unit |
| BC-2.07.001 | CAP-007 | DI-002,DI-003 | R2a | P0 | unit |
| BC-2.07.002 | CAP-007 | DI-002 | R2a | P1 | integration |
| BC-2.07.003 | CAP-007 | DI-002 | R2a | P0 | unit/property |
| BC-2.07.004 | CAP-007 | DI-003 | R2a | P0 | unit |
| BC-2.07.005 | CAP-007 | — | R2a | P0 | unit |
| BC-2.07.006 | CAP-007 | — | R2a | P0 | unit |
| BC-2.07.007 | CAP-007 | DI-005 | R2a | P0 | unit |
| BC-2.07.008 | CAP-007 | DI-005 | R2a | P0 | unit |
| BC-2.08.001 | CAP-008 | DI-003,DI-008 | R5 | P0 | unit |
| BC-2.08.002 | CAP-008 | DI-003,DI-006,DI-008 | R5 | P0 | unit/integration |
| BC-2.08.003 | CAP-008 | DI-003 | R5 | P0 | unit/property |
| BC-2.08.004 | CAP-008 | DI-006,DI-008 | R5 | P1 | integration |
| BC-2.09.001 | CAP-009 | DI-005 | R2c | P0 | unit |
| BC-2.09.002 | CAP-009 | — | R2c,R5 | P0 | unit |
| BC-2.10.001 | CAP-010 | DI-005 | R2c | P0 | integration |
| BC-2.10.002 | CAP-010 | DI-005,DI-010 | R2c,R7 | P0 | integration |
| BC-2.10.003 | CAP-010 | DI-005 | R2c | P0 | integration |
| BC-2.10.004 | CAP-010 | DI-010 | R2c | P0 | integration |
| BC-2.10.005 | CAP-010 | — | R2c | P0 | integration |
| BC-2.10.006 | CAP-010 | — | R2c | P0 | integration |
| BC-2.10.007 | CAP-010 | — | R2c | P0 | integration |
| BC-2.10.008 | CAP-010 | DI-010 | R2c | P1 | integration |
| BC-2.10.009 | CAP-010 | DI-005 | R2c | P0 | integration |
| BC-2.10.010 | CAP-010 | DI-010 | R5,D-008 | P0 | unit |
| BC-2.11.001 | CAP-011 | DI-006 | R5 | P0 | integration |
| BC-2.11.002 | CAP-011 | — | R5 | P0 | unit |
| BC-2.11.003 | CAP-011 | — | R5 | P1 | unit |
| BC-2.11.004 | CAP-011 | — | R5 | P0 | unit |
| BC-2.12.001 | CAP-012 | DI-001 | R6 | P0 | unit/integration |
| BC-2.12.002 | CAP-012 | — | R6 | P1 | integration |
| BC-2.12.003 | CAP-012 | — | R6 | P0 | unit |
| BC-2.12.004 | CAP-012 | — | R6 | P1 | integration |
| BC-2.12.005 | CAP-012 | — | R6,R7 | P0 | integration |
| BC-2.13.001 | CAP-013 | DI-001 | R6 | P0 | unit/integration |
| BC-2.13.002 | CAP-013 | DI-010 | R6,R7 | P1 | unit |
| BC-2.14.001 | CAP-014 | DI-010,DI-011 | R7 | P0 | unit/property |
| BC-2.14.002 | CAP-014 | DI-011 | R7 | P0 | integration |
| BC-2.14.003 | CAP-014 | — | R7 | P0 | unit |
| BC-2.14.004 | CAP-014 | — | R7 | P0 | unit |

---

## 8. Changelog

| Version | Date | Findings Addressed | Changes |
|---------|------|-------------------|---------|
| v1.15 | 2026-08-10 | D-122 (EC-151 holdout burn) | EC-151 holdout designation retired per D-122; prd.md:618 D-010 note leaked concrete input/expected output verbatim. §5b updated: EC-151 removed from holdout list, EC-214 added; burned-list updated; count 212→213 edge cases, range EC-001..EC-213→EC-001..EC-214, 213→214 IDs allocated. D-010 note at §618 annotated with D-122 burn and EC-214 replacement. |
| v1.0 | 2026-08-05 | (initial) | PRD created in Phase 1a |
| v1.1 | 2026-08-05 | SF-001, SF-002, SF-003, NOTE-4 (architecture feasibility-review.md) | See below |
| v1.2 | 2026-08-05 | INC-001, INC-002, INC-003, INC-004, INC-005, INC-006 (via BC-INDEX), INC-007, INC-009 (via BC-INDEX), DFT-001 (error-taxonomy.md), F-001/SR-032 (error-taxonomy.md), SR-027, SR-035 | See below |
| v1.3 | 2026-08-05 | F-002, F-003, F-004, F-006, F-016, F-017, F-021, D-010, D-011, D-012, D-013 (adversary-pass-1.md + human decisions) | See below |
| v1.4 | 2026-08-05 | F-007, F-008, F-009, F-011, F-012, F-013, F-014, F-020, F-023, F-024, F-025, F-028, F-029, F-030, F-031, F-032 (adversary-pass-1.md sub-burst B) | See below |
| v1.5 | 2026-08-05 | POL-18 holdout boundary (EC-074 leak), VP elevations VP-023/VP-024 | See below |
| v1.6 | 2026-08-05 | P2-C01..P2-m06, REGRESSION-001..005, INCONSISTENCY-001/002, DRIFT-001/002 (adversary-pass-2 + consistency-pass-2); D-014..D-020 human decisions | See below |
| v1.7 | 2026-08-05 | P3-005, P3-006, P3-032 partial (test-vectors.md hotfix) | See below |
| v1.8 | 2026-08-05 | POL-16 (EC injectivity), unregistered EC-159..EC-183, vCurrent title sync, BC-INDEX statistics | Spec-lint remediation pass; see below |
| v1.9 | 2026-08-06 | INC-MAP-002, INC-MAP-003, P3-027 resolution | Architecture Module fields resolved across 26 BC files per bc-module-map.md Phase 1b; joint-ownership BCs annotated; PRD version aligned |
| v1.10 | 2026-08-06 | D-043 (macOS-only platform directive) | Platform matrix narrowed to macOS-only. NFR-002 retargeted (macOS CI runner, 10s p95). NFR-004 retired (vacuous on single-platform matrix). NFR-008 hardware tier updated to macos-latest. Problem statement §1.2 updated (removed Linux CI divergence framing). KD-004 §1.3 updated (determinism-grounded per D-043). NFR-005 measurement updated (`\time -l` macOS only). |
| v1.11 | 2026-08-06 | CV5-001 (D-043 survivor sites) | §6.4 KD-004 table "ALL platforms" → "macOS". Canonical-facts.toml FACT-7 added (platform-matrix binding for product-brief.md L1 root). D-034 amendment note for v1.7 TV-036 Linux-CI falsification claim. |

### v1.9 — Architecture Module Resolution (bc-module-map.md Phase 1b)

**INC-MAP resolution:** Closed all 22 `[filled by architect]` placeholders across 26 BC files
using bc-module-map.md as authoritative source (architect, Phase 1b). Placeholders were in
the `Architecture Module` field of the Traceability table.

**INC-MAP-002 (BC-2.03.005 joint SS-03/SS-09 ownership):** Architecture Module field now names
`url_classifier.rs` (SS-09) as primary and `link_extractor.rs` (SS-03) as secondary with
explicit note that story decomposition must assert both link extraction and url_classifier
classification behavior.

**INC-MAP-003 (BC-2.11.004 cli → verdict boundary):** Architecture Module field now names
`cli.rs` (SS-11) as primary and `verdict.rs` (SS-14) as secondary with explicit note that
acceptance tests must assert both cli validation error AND exit 2 via `verdict::exit_code`.

**P3-027 resolution (BC-2.10.009 dedup ownership):** BC-2.10.009 `## Architecture Anchors`
section filled with http_client.rs as primary owner, citing ADR-001 purity boundary rationale,
ADR-004/005 coupling requirement, and bc-module-map.md §P3-027.

**Four joint-ownership BCs annotated (Architecture Module row added):**
- BC-2.07.003: `path_resolver.rs` primary + `fragment.rs` secondary (percent-encode ordering per DI-002)
- BC-2.07.004: `fragment.rs` primary + `path_resolver.rs` secondary (already-split dest string)
- BC-2.08.003: `fragment.rs` primary + `anchor_resolver.rs` secondary (fragment-for-anchor-lookup)
- BC-2.11.004: `cli.rs` primary + `verdict.rs` secondary (INC-MAP-003 config_error coupling)

**INC-MAP-004 noted (BC-2.01.003):** VP-016 formal assignment is to `anchor_table` module;
Architecture Module note added to BC-2.01.003 to guide story decomposition.

**Version drift repaired:** BC-2.01.003 had frontmatter `version: "1.0"` while its modification
log had reached `v1.5`. Frontmatter corrected to `"1.6"` to match the new top-of-log entry.

### v1.10 — D-043 macOS-Only Platform Directive

**Platform matrix narrowed (D-043):** The product now targets macOS (`macos-latest`) only. Linux and Windows removed from all NFRs, test vectors, and platform-scoped prose.

**NFR-002 retargeted:** Changed from "Linux CI Runner" (15s p95, ubuntu-latest) to "macOS CI Runner" (10s p95, macos-latest, Apple Silicon M1 shared). Rationale: a single 5s ceiling covering both a local M2/M3 developer machine (NFR-001) and a shared M1 CI runner (NFR-002) is likely wrong for one of them; the 10s CI ceiling acknowledges shared-infrastructure variability honestly.

**NFR-004 retired:** The portability NFR asserting cross-platform test passage is vacuous on a single-platform matrix. Retired with status note. The `unicode-normalization` crate pin remains in force on DI-001/DI-002 determinism grounds — see nfr-catalog.md NFR-004 note and HANDOFF to architect.

**NFR-008 hardware tier updated:** CI regression gate now runs on `macos-latest` instead of `ubuntu-latest`. 500ms p95 threshold preserved.

**§1.2 Problem statement updated:** Removed cross-platform framing ("passes on macOS that fail in Linux CI"); replaced with macOS APFS case-insensitive filesystem framing.

**§1.3 KD-004 updated:** "macOS/Linux divergence eliminated" replaced with determinism-grounded framing (D-043/D-006 canonical rationale).

**NFR-005 measurement:** Removed `/usr/bin/time -v` (Linux) reference; macOS `\time -l` only.

### v1.11 — CV5-001 D-043 Platform-Matrix Survivor Remediation

**§6.4 KD-004 table (CV5-001 / D-043):** BC-2.07.003 description updated from "on ALL platforms (not OS-delegated)" to "on macOS (not OS-delegated; D-043/D-006 determinism grounds)". Under the macOS-only matrix, "ALL platforms" was vacuous and misleading; macOS is the sole target and the determinism rationale stands on its own.

**D-034 amendment note — v1.7 TV-036 falsification claim:** The v1.7 changelog entry (D-034-immutable) stated that TV-036 falsifies KD-004/DI-002 via "fails in Linux CI." Under D-043 (macOS-only), the Linux-CI mechanism is moot. The test vector retains full falsification force on macOS: `std::fs::exists()` on macOS APFS is case-insensitive and silently resolves `README.MD` when only `README.md` exists (false `clean` verdict). The correct implementation uses `read_dir()` with exact-byte entry comparison, which catches the mismatch on APFS. The macOS-APFS falsification is the operative mechanism under the macOS-only matrix and is at least as strong as the original Linux CI falsification.

**canonical-facts.toml FACT-7 added:** Platform-matrix canonical fact (canonical_value = "macOS") with bindings for `product-brief.md` (L1 root, the CV5-001 site) and `domain-spec/assumptions.md` (ASM-004). `check-canonical-facts.py` was previously structurally incapable of detecting platform-matrix divergence; FACT-7 closes that gap.

### v1.8 — Spec-Lint Violation Remediation Pass

**EC injectivity (POL-16):** TV-NNNb variant rows (TV-015b, TV-124b, TV-134b, TV-138b, TV-157b, TV-158b) reassigned to distinct EC-NNNs (EC-178..EC-183) to eliminate same-EC collision flags. §10 added to test-vectors.md registering EC-159..EC-183.

**Unregistered EC IDs:** EC-159..EC-164, EC-169..EC-183 registered in test-vectors.md §10. Retired holdout citation removed from prd.md prose and BC-2.04.001 edge cases (the retired ID was replaced by EC-151 per D-010; TV-BV013 is the visible replacement).

**EC count:** Updated to 182 edge cases registered (EC-001..EC-183).

**Title sync:** GENERATED markers added to prd.md §2 tables; gen-prd-sections.py regenerated all 14 subsystem tables from authoritative BC H1 headings.

**NFR-006 count:** Updated from 10 to 16 worked examples (matches §7 actual TV-S count).

**test-vectors.md §4 header:** Range updated to EC-077 through EC-150 (includes EC-149, EC-150).

**BC-INDEX titles:** BC-2.09.002, BC-2.10.002, BC-2.10.008 corrected to match BC H1 headings.


### v1.2 — Phase 1 Gate Review Remediation

**INC-001 + INC-002 (BC title scramble SS-10, SS-12):**
PRD sections 2.10 and 2.12 had BC titles completely wrong (a prior reorganization renumbered the BC files without updating the PRD summary tables). Corrected all 7 scrambled entries using BC file H1s as the source of truth (bc_h1_is_title_source_of_truth policy). Also corrected SS-14 (BC-2.14.001 and BC-2.14.003) which had the same scramble pattern but was not flagged as a standalone INC finding.

**INC-003 (URL deduplication behavior uncontracted):**
Created BC-2.10.009 "URL Deduplication — Each Unique External URL Fetched Once, Verdict Reported at Every Occurrence". Covers: one HTTP request per normalized URL, memoized verdict reported at each occurrence with correct per-occurrence file:line:column, interaction with per-host concurrency caps, interaction with 429 host-pausing. Priority P0. Added to SS-10 subsystem table (section 2.10) and RTM (section 7).

**INC-004 (wording mismatches SS-09, SS-11, SS-13, SS-06, SS-12.001, SS-10.001-004):**
Updated all PRD section 2.x title cells to exactly match BC file H1s via BC-INDEX (which is confirmed identical to BC H1s by the consistency audit's PASS on that check). Fixed: SS-06 (2.06.001, 2.06.002), SS-09 (2.09.001, 2.09.002), SS-10 (2.10.001-004), SS-11 (2.11.001-003), SS-12 (2.12.001-004), SS-13 (2.13.001-002), SS-14 (2.14.001-003).

**INC-005 (priority misalignment — 17 contracts affected, SS-10 decision):**
BC-INDEX is the authoritative priority source (more recently maintained). Updated PRD section 2.x tables and section 7 RTM to match BC-INDEX for all 17 affected contracts. SS-10 priority decision: BC-2.10.001-007 and BC-2.10.009 are **P0** because the three-verdict model is a core differentiator (KD-002) and the correct behavior of `--online` mode defines the product's anti-false-positive claim. BC-2.10.008 (concurrency limits 32/4) is **P1** because those specific caps are a scalability tuning decision, not a correctness requirement. BC-2.11.001-002 P0 (filter logic is always active); BC-2.12.002/2.12.004 P1; BC-2.13.001 P0.

**INC-007 (NFR-007 absent from PRD section 4):**
Added NFR-007 "Correctness — No Undefined Reason Codes" row to section 4 NFR table. NFR-007 is now meaningful: the canonical taxonomy has exactly 13 codes and the taxonomy conflict (two contradictory closed sets) is resolved by this revision — making NFR-007 testable and non-vacuous.

**SR-027 (BC-2.03.003 false premise about pulldown-cmark):**
Revised BC-2.03.003 preconditions to state that `scanner.rs` MUST construct the parser via `Parser::new_with_broken_links()` (or equivalent) with a `broken_link_callback` that returns `None`. Without this callback, undefined reference links are emitted as plain text (no link event), making the `undefined-reference-definition` verdict unreachable.

**SR-035 / D-009 (corpus scope contradiction):**
Removed the Non-Goals line "Tests/corpus authorship beyond the defined `tests/corpus/` manifest structure" which contradicted binding human decision D-009. Corpus authorship is IN scope. Added note pointing to interface-definitions.md §10 as the schema source. Manifest schema in interface-definitions.md §10.2 updated to align with `--format json` output (same field names, `column` included, flat array under `expected` key).

**DFT-001 + F-001/SR-032 (error taxonomy canonical ruling):**
error-taxonomy.md updated: (a) fixed `target-is-directory` qualifier (bare directory links are `clean` per BC-2.07.005 v1.1; fragment-present directory links are `broken`); (b) updated verdict classes to distinguish `alive` (external URL positive verdict) from `clean` (internal link positive verdict) per canonical ruling; (c) bumped to v1.1. The 13-code closed set in error-taxonomy.md is authoritative. DNS failure (`dns-failure`) and TLS error (`tls-error`) are `broken` (exit 1), not `indeterminate`. The positive external URL verdict is `alive`; the positive internal link verdict is `clean`; `valid` is never used.

**INC-009 (BC-INDEX DI-007 "reserved" label misleading):**
Updated DI-007 entry in BC-INDEX from "[reserved — no enforcement BC needed]" to an accurate coverage note referencing VP-020 and BC-2.05.001.

**INC-006 (BC-INDEX P0/P1 count off by ±1):**
Summary statistics corrected in BC-INDEX. After adding BC-2.10.009: P0=47, P1=13, Total=60.

**NOTE on gene-transfusion-assessment.md (INC-010):**
gene-transfusion-assessment.md uses "valid" for the positive external URL verdict at lines 211 and 286. This file is not in product-owner scope but is flagged here for the spec-steward: "valid" must be replaced with "alive" in that document.

### v1.3 — Adversary Pass-1 Remediation (Sub-Burst A: Behavioral Semantics)

**D-010 (holdout scenario replacement):** TV-BV013 (`mdlinkcheck BRIEF.md` → exit 0) is now a visible required test vector. Former holdout removed from holdout list; replaced by EC-151 (hidden `## Hidden Section` inside `<details>` HTML block with `[x](#hidden-section)` → broken). Updated §5b and test-vectors.md §0 holdout WARNING accordingly. *[D-122 update (2026-08-08): the concrete EC-151 content stated in this D-010 note constituted a POL-18 breach — holdout input and expected output were verbatim in a visible spec. EC-151 burned to visible test TV-151 per D-122; replaced by EC-214 (HS-008). §5b and test-vectors.md updated in prd.md v1.15.]*

**D-011 (dropped flags: --quiet, --offline, --insecure, --hidden):** All four flags removed from interface-definitions.md §2 and §8. §1.5 Out of Scope updated with explicit non-goals. BC-2.01.004 rewritten (dot-dir skip unconditional; no --hidden override). BC-2.12.003 retitled "Stderr Summary Line (Always Emitted)" — --quiet qualifier removed from title, preconditions, invariants, edge cases, test vectors. AMB-042 updated: --insecure is a non-goal; TLS failures are always `broken`. §3 interface summary updated.

**D-012 (.md only, case-sensitive):** BC-2.01.005 retitled/rewritten — extension matching is `.md` only, exact case-sensitive byte match; `.MD`, `.markdown`, `.mdx` are explicit non-goals. BC-2.07.006 Precondition 3 updated. TV-005 (README.MD → not scanned), TV-006 (notes.markdown → not scanned) updated in test-vectors.md.

**D-013 (two-tier perf model confirmed):** NFR-001 and NFR-002 changed from "provisional" to "active". NFR-008 added: ~500ms p95 CI regression gate for 100-file corpus, blocking merge, VP-022. §4 NFR table updated. nfr-catalog.md v1.3.

**F-002 (BC-2.07.003 NFD→NFC verdict wrong):** Postcondition 4 corrected — both link destination and directory entry are NFC-normalized before comparison; NFD link → NFC disk = `clean` (not `broken`). Test vector row 4 corrected; mirror vector added.

**F-003 (BC-2.08.002 missing carve-outs):** BC-2.08.002 rewritten — added explicit PC3 (directory target → BC-2.07.005) and PC4 (non-.md target → BC-2.07.006) carve-outs. DI-006 widening: out-of-scan-set .md targets valid via Pass 1.5. Invariant 4 added: anchor_resolver.rs never called for non-.md targets.

**F-004 (PRD §2.9–§2.14 drifted; uncontracted behaviors):** Four new BCs created: BC-2.10.010 (private-IP classification), BC-2.11.004 (invalid --ignore glob → exit 2), BC-2.12.005 (stdout/stderr separation), BC-2.14.004 (--help/--version exit 0). §2.9–§2.14 BC indexes updated; RTM updated.

**F-006 (BC-2.10.002 total partition):** BC-2.10.002 rewritten as total partition of HTTP 0..=599 + transport outcomes. Added 400-after-GET, 401, 403, other-4xx, https→http downgrade, TLS failure (broken, not indeterminate), DNS failure (broken), too-many-redirects (broken), private-IP (indeterminate). Removed --insecure clause (D-011). Removed holdout EC-093. error-taxonomy.md §2.3 updated: tls-error trigger removes "unless --insecure"; http-indeterminate trigger adds private-ip and https-downgrade sub-reasons. §3 disambiguation updated.

**F-016 (interface-definitions.md nonexistent PATH fail-fast):** §8 "Nonexistent PATH" rule updated: error recorded, scanning continues for remaining valid PATHs, exit 2 after scan completes (DD-007 no-fail-fast). SIGINT/panic sentences deleted from §3.

**F-017 (--allow contracted twice):** BC-2.11.002 is now the CANONICAL --allow contract (normalize-then-prefix-match ordering, component-boundary safety). BC-2.09.002 converted to pointer with required sections retained. Duplicate postconditions removed from BC-2.09.002.

**F-021 (target-is-directory trigger):** Already fixed in v1.1 error-taxonomy.md. No additional change needed in v1.3.

**Architect required BC changes:** BC-2.05.001 three-phase rewrite (Pass 1 → Pass 1.5 → Pass 2; PC1/PC4 circularity resolved; all four DI-006 cases covered). BC-2.10.008 dedicated rayon pool in Invariant 3; test vectors assert observable concurrent connections. Holdout citations EC-049, EC-074 removed from BC bodies where present.

**BA DI-006 propagation:** BC-2.01.003 Invariant 2 expanded (four-mechanism cross-reference). BC-2.11.001 Invariant 4 added. BC-2.11.003 Invariant 3 added. Four new DI-006 visible test vectors added (EC-152..EC-155, TV-152..TV-155) in test-vectors.md §3.

### v1.4 — Adversary Pass-1 Remediation (Sub-Burst B: Traceability, Index, Remaining Findings)

**F-007 (VP-TBD backfill):** All `VP-TBD` placeholders replaced across 37 BC files (ss-01, ss-06..ss-14). Every BC now cites its authoritative VP(s) from VP-INDEX v1.1, or `test-sufficient` where no formal VP is warranted. BC-2.02.002 (ss-02) handled in this burst. Zero VP-TBD remaining.

**F-008 / F-025 (holdout boundary sweep):** Residual holdout EC IDs removed from BC body edge-case tables where they had leaked in. Visible test-vectors.md updated to reflect split TV-134 → TV-134a (offline) / TV-134b (online).

**F-009 (BC-2.06.002 — containment loop semantics):** PC1/PC2 restated to use DD-015 key-containment semantics (not value comparison). PC3 restricted to the specific document order where both `## Setup` headings precede `## Setup 1`. PC4 added: Setup-1-first order produces ["setup-1", "setup", "setup-2"], not ["setup", "setup-1", "setup-1-1"]. New test vector added.

**F-011 (SS-TBD fixes):** 15 BC files with `subsystem: "SS-TBD"` corrected to SS-11, SS-12, SS-13, or SS-14. Five files with input-hash drift (ss-12 × 3, ss-13 × 2) had hash recomputed. Zero SS-TBD remaining.

**F-012 (non-deterministic test vectors):** TV-021 → deterministic: `2 / target-unreadable`. TV-024 → deterministic: `0 / clean` (relative links have no scan-root boundary). TV-031 → `broken (malformed-url)` (BC-2.07.007). TV-034 → `broken (file-not-found)` (BC-2.07.008). TV-134 split into TV-134a (offline, 6 codes) and TV-134b (online, http codes). New BCs: BC-2.07.007 (empty destination → malformed-url), BC-2.07.008 (trailing slash on file → file-not-found). §2.7 updated; RTM rows added.

**F-013 (JSON schema errors array):** BC-2.13.001 updated — PC1 now specifies `{"schema_version":1,"results":[...],"errors":[...]}`. PC7 added: `target-unreadable` entries go in `errors[]`, not `results[]`. Invariant 6+7 added. BC H1 updated to reflect errors field. §2.13 PRD table updated. interface-definitions.md §6 updated with errors array schema.

**F-014 (corpus manifest comparison):** interface-definitions.md §10.2 pass criterion updated to explicit 6-field tuple set equality `(file, line, column, link_target, verdict, reason)` with jq command.

**F-020 (Brief Requirement mislabeling):** 11 BC files' `Brief Requirement` fields corrected to use R2a/R2b/R2c/R5/R6 granularity per frozen BRIEF.md (background agent TASK C + BC-2.02.002 in this burst).

**F-023 (NFC sort key):** BC-2.13.001 PC4 sort key changed from `(file, line, column)` to `(NFC-normalized file path, line, column)` per DI-001. interface-definitions.md §6.2 Ordering updated.

**F-024 (T-number / DI-number mis-citations):** Systematic Brief Requirement corrections applied across BC files (background agent TASK C). §6.5 KD-005: BC-2.14.001 description corrected — exit 0 only, not "pure function of verdict multiset"; BC-2.14.003 added to KD-005 table; BC-2.14.002 description updated to reference the complete 3-BC exit code model.

**F-028 (column relative to BOM-stripped buffer):** BC-2.02.002 v1.2 — PC5 and Invariant 5 added: both line AND column are relative to the BOM-stripped, LF-normalized buffer. Column 1 is the first character after BOM removal. TV-015b added to test-vectors.md. Brief Requirement corrected from `R2, AMB-012, AMB-013` → `R2a`.

**F-029 (BC-2.06.001 PC2 self-contradiction):** PC2 rewritten as two separate rules: non-empty (for headings with at least one surviving character) and empty-string slug (for pure-punctuation headings). PC3 added: duplicate counter keyed on computed slug string, not heading text. Emoji-collision edge cases EC-059/EC-060 and test vectors added. BC-2.06.001 bumped to v1.2.

**F-030 (hyperfine --profile-mem flag invalid):** NFR-005 validation method corrected from `` `hyperfine --profile-mem` `` to `` `/usr/bin/time -v` (Linux) or `\time -l` (macOS) ``. nfr-catalog.md updated.

**F-031 (error-taxonomy.md §6 FM-004 row and missing rows):** FM-004 row corrected (was pointing to wrong reason code). Five missing rows added: `target-is-directory`, `dns-failure`, `tls-error`, `too-many-redirects`, `http-indeterminate` (expanded). error-taxonomy.md bumped to v1.4.

**F-032 (target-unreadable conflation):** §6.1 added to error-taxonomy.md explicitly documenting that `target-unreadable` covers both permission-denied and invalid-UTF-8 deliberately, with rationale and v2.0 deferral note.

---

### v1.6 — Adversary Pass-2 + Consistency-Pass-2 Remediation

**D-014 / DD-022 (Two-layer verdict model — P2-C01, INCONSISTENCY-001, INCONSISTENCY-002):**
Separated the URL liveness outcome (`alive|broken|indeterminate`) from the link verdict (`clean|broken|indeterminate`). `alive` is NOT a fourth link verdict — it is an intermediate HTTP-layer result that maps to link verdict `clean`. Fixed BC-2.10.001, BC-2.10.003, BC-2.10.007: replaced `clean` with `alive (link verdict: clean)` in test vectors and postconditions. Fixed BC-2.10.002: removed `alive (clean)` / `alive → clean` conflation; rewrote description and postconditions to use the two-layer model explicitly. Rewrote error-taxonomy.md §1 with two-table model. Retracted false assertion that `` `clean` is NOT used for external URL verdicts ``.

**D-015 / DD-022 (BC-2.05.001 title and DI-008 label — REGRESSION-001):**
BC-2.05.001 H1 title corrected from "Two-Pass Design" to "Three-Phase Design — Full Anchor Table Before Any Resolution" (BC-INDEX and prd.md §6.1 table updated to match). DI-008 label in BC-INDEX updated from "Two-pass:" to "Three-phase (Pass 1 → Pass 1.5 → Pass 2):".

**D-016 (sub_reason optional field — P2-M17):**
Added optional `sub_reason` field to JSON finding object for `http-indeterminate` diagnostics. Values: `https-downgrade` (BC-2.10.007) and `private-ip` (BC-2.10.010). Not part of the closed 13-code reason taxonomy; VP-021 does not check it. Updated BC-2.10.002 postconditions and test vectors, error-taxonomy.md §3b (new section), interface-definitions.md §6.2 (new table row).

**D-017 (JSON shape — P2-M11):**
Binding interpretation note added to §3: JSON output is an object envelope `{schema_version, results[], errors[]}` per D-017, superseding the R6 "array" wording. Consumers read `.results`.

**D-018 (HTTP 400 after GET fallback — P2-C03):**
400-after-GET confirmed `indeterminate` (not `broken`). Fixed BC-2.10.002 PC3 and PC3b. Fixed error-taxonomy.md `http-error` trigger note.

**D-019 (--allow on malformed URLs — P2-M08):**
`--allow` matching algorithm updated: attempt WHATWG normalization first; if normalization fails, fall back to raw-string prefix match at a component boundary. Rewrote BC-2.11.002 description and postconditions. Updated interface-definitions.md §2.2 `--allow` flag description. EC-090/091/092 in BC-2.11.002 renamed to EC-161/162/163 (deduplicated from BC-2.10.002's legitimate use of those IDs — P2-M09).

**D-020 (holdout pool refresh — P2-M12):**
Burned EC-036, EC-049, EC-074, EC-157, EC-158 (retired holdout designation; now visible tests). Authored four fresh replacement hidden scenarios EC-165..EC-168 in `.factory/holdout-scenarios/wave-scenarios/`. Risk clusters covered: anchor resolution (EC-165), source-exclusion × cross-file anchors (EC-166), percent-encoding × fragment split (EC-167), duplicate-slug collisions (EC-168). Removed concrete input/output details from prd.md §5b holdout list, §6.1 KD-001 table (EC-049 `Foo/Foo/Foo-1` reference), and v1.5 changelog EC-157/158 description lines. HS-INDEX.md updated with retired and new entries (HS-004..HS-007).

**P2-C05 (BC-2.05.001 PC2 unsatisfiable for nonexistent targets):**
Added PC2b failure branch: if a Pass 1.5 target path does not exist or cannot be read, no AnchorIndex entry is created, no IoError is recorded, no diagnostic emitted; Pass 2 produces the ordinary broken verdict.

**P2-C06 (nonexistent PATH argument — interface-definitions.md §8):**
Confirmed §8 Flag Interaction Rules entry for "Nonexistent PATH argument": error recorded, scanning continues for remaining valid PATH arguments, exit 2 at end (DD-007 no-fail-fast). BC-2.01.009 PC1 rewritten to match.

**P2-M01 (BC-2.10.002 partition not total):**
Added 0..=99, 1xx, HEAD-400/GET-also-400, and GET-also-405 cases to make the HTTP status code partition genuinely exhaustive. Aligned range claim to "all HTTP status code values".

**P2-M10 / REGRESSION-002 / REGRESSION-003 (.hidden and .markdown regressions):**
BC-2.01.001, BC-2.01.002: removed `.markdown` extension references per D-012 (`.md` only). BC-2.01.001, BC-2.01.004: removed `--hidden` flag and `.git/` carve-out per D-011 (dot-directories unconditionally skipped). BC-2.01.008: removed `--quiet` reference per D-011 (no `--quiet` flag). BC-2.02.001: precondition updated (`.markdown` excluded per D-012).

**P2-M15 (BC-2.10.002 VP-007 proof method):**
VP-007 proof method corrected from "unit test" to "kani (P0)". Removed two unverifiable attribution rows; added integration test rows.

**P2-m05 (invented capability titles sweep):**
Fixed L2 Capability Anchor Justification titles in BC-2.05.001, BC-2.07.008, BC-2.10.002, BC-2.11.002 to use verbatim titles from capabilities.md. BC-2.11.002 Brief Requirement corrected from R6 to R5.

**P2-m06 (BC-2.10.002 Related BCs swap):**
Fixed BC-2.10.006 description (was "redirect handling" → now "TLS failure handling") and BC-2.10.007 description (was "TLS failure" → now "redirect chain and HTTPS→HTTP downgrade handling").

**REGRESSION-005 (interface-definitions.md §2.3 TLS verdict):**
Fixed §2.3: TLS failures produce `broken` verdict with reason `tls-error` (BC-2.10.006, ADR-007), not `indeterminate`. There is no `--insecure` flag.

**EC-164 assigned:** EC-NEW-3 in BC-2.07.005 renamed to EC-164 (P2-M09 deduplication sweep). EC-161/162/163 assigned to BC-2.11.002 (renamed from EC-090/091/092).

---

### v1.5 — Pre-Adversary-Pass-2 Cleanup (Holdout Boundary + VP Elevations)

**Fix 1 (POL-18 holdout boundary — EC-074 leak, Option A):** EC-074 (`--ignore` × cross-file anchor corpus fixture) was still cited by name with exact expected-output wording in three BC edge-case tables, giving implementers a near-zero holdout signal. Option A applied: EC-074 citations removed from BC-2.01.003, BC-2.08.004, and BC-2.11.001 edge-case tables. Generic DI-006 coverage is preserved by: (a) BC-2.08.004's full contract body and test vectors (using b.md/intro variable names), (b) BC-2.11.001 PC3 and Invariant 4, (c) BC-2.01.003 Invariant 2, and (d) TV-152/EC-152 in the visible test-vectors.md. Two replacement generic edge cases EC-159/EC-160 added to BC-2.08.004 to satisfy the "at least one EC" requirement. EC-074 remains on the holdout reserved list — its corpus-fixture details remain hidden.

Note: The BC-2.01.003 EC-074 row was also incorrectly scoped — that BC covers `.gitignore` traversal (DI-006 case 2), but the row cited an `--ignore` flag scenario (DI-006 case 1). Removal was doubly correct.

**Fix 2 (Replacement holdouts — restore DEC-003 risk coverage):** Three new holdout scenarios designated to replace the signal lost from the EC-074 leak and close adjacent gaps:

- **EC-156** (HS-001): `.gitignore` × cross-file anchor, corpus fixture — tests DI-006 case 2 (traversal exclusion), the code path distinct from case 1 (`--ignore`). Stored in `.factory/holdout-scenarios/wave-scenarios/EC-156-gitignore-cross-file-anchor.md`.
- **EC-157** (HS-002): Percent-encoded fragment in cross-file link scenario — holdout risk cluster: percent-encoding × anchor resolution. [Concrete inputs/expected outputs stored only in holdout wave file per POL-18.]
- **EC-158** (HS-003): Emoji heading × collision counting scenario — holdout risk cluster: emoji × slug collision. [Concrete inputs/expected outputs stored only in holdout wave file per POL-18.]

§5b holdout list updated: EC-156/157/158 added (13 total holdout IDs). test-vectors.md HOLDOUT WARNING updated to reflect new IDs.

**Fix 3 (VP elevations per VP-INDEX v1.2):** Two architect-designated VP elevations applied:

- **BC-2.07.007**: `test-sufficient` replaced with **VP-023** (`url_classifier::classify_url` totality — empty destination string returns `Malformed(_)`, never `NonHttp`; method: proptest). Rationale: empty string through WHATWG URL parse is a real panic class; misclassification risk is `NonHttp` → no exit-1 contribution.
- **BC-2.07.008**: `test-sufficient` replaced with **VP-024** (`path_resolver` trailing-slash-on-file invariant — `File` entry + trailing slash → `broken(file-not-found)`, never `target-is-directory`; method: proptest). Rationale: `file-not-found` vs `target-is-directory` distinction is one conditional on `EntryKind`; exactly the swap a refactor introduces.

The four other new BCs (BC-2.10.010, BC-2.11.004, BC-2.12.005, BC-2.14.004) correctly remain `test-sufficient`. BC-2.11.004 fail-fast question resolved by architect: invalid `--ignore` glob is startup configuration error (before traversal), outside DD-007 no-fail-fast scope.

**BC→VP count (post-v1.5):** 66 BCs total; 33 with a real VP (VP-001..VP-024); 33 test-sufficient.

---

### v1.7 — Test-Vectors Hotfix (P3-005, P3-006, P3-032 partial)

**P3-005 (flagship differentiator KD-004 had zero test coverage):**
D-020 retired the holdout designation on EC-036, EC-049, EC-074, EC-157, EC-158 and declared them visible tests. That ruling was applied to `domain-spec/edge-cases.md` (which restored concrete detail) but was never executed in `test-vectors.md` — leaving zero visible vectors for those five ECs. This hotfix adds the missing vectors:

- **TV-036** (EC-036/DEC-009/T12): Case-mismatched filename — `[x](README.MD)` where only `README.md` exists on disk. Expected: exit 1, broken (`file-not-found`) on ALL platforms including macOS. This vector falsifies KD-004/DI-002 — an `std::fs::exists()`-based implementation passes on APFS, fails in Linux CI. DI-002 / D-006 / Trap T12 now has falsifiable visible coverage.
- **TV-049** (EC-049/DEC-001): Duplicate heading collision `Foo/Foo/Foo-1` — all three links clean (disambiguation while-loop must handle secondary collision). Exit 0.
- **TV-074** (EC-074/DEC-003): Cross-file anchor into `--ignore`'d `vendor.md` — link `[x](vendor.md#section)` resolves clean because `--ignore` suppresses link-source only, not anchor-table construction. Exit 0.
- **TV-157 / TV-157b** (EC-157): Percent-encoded fragment in cross-file link — `[Guide](other.md#caf%C3%A9)` where `other.md` has `## Café`. Positive: exit 0 clean. Negative control (wrong heading): exit 1 broken. Covers the cross-file path of BC-2.08.003; TV-053 only covers the same-file path (Sphinx bug #13620 root cause).
- **TV-158 / TV-158b** (EC-158): Emoji heading × collision counter — `## 🚀 Foo` then `## Foo` produce slug `foo` and `foo-1`; links to both clean. Failure probe `#foo-2` broken. Exit 0 and exit 1 respectively.

**P3-006 (HOLDOUT WARNING stale in both directions):**
The HOLDOUT WARNING in `test-vectors.md` listed EC-036/049/074/157/158 as hidden (their designation was retired by D-020) and omitted the four live replacements EC-165..EC-168. A reader could have treated four active holdouts as fair game for visible vectors. Rewritten to show the true active pool of 12. Frontmatter `version` field corrected from "1.4" (stale) to "1.6" (current body state + this hotfix). Intro range updated from EC-001..EC-150 to EC-001..EC-168.

**P3-032 partial (Trap T12 and T16 trap-map honesty):**
T12 updated from `[HOLDOUT] EC-036 reserved | holdout` to `TV-036 | covered` with explicit DI-002/KD-004 rationale. T16 ("Path above scan root") changed from `covered` to `not-covered` with tracked reason: TV-076 is broken because the target file does not exist (relative path), not because of scan-root boundary enforcement; TV-024 confirms relative paths have no scan-root boundary; a root-relative path with `..` traversal above git root on an existing file (per BC-2.07.002) has no dedicated vector.

---

### v1.1 — Architecture Feasibility Revision

**SF-001 (BC-2.02.002 — BOM/CRLF shell-side obligation):**
Revised BC-2.02.002 to explicitly assign BOM detection and CRLF normalization to `scanner.rs`
(effectful shell). The preconditions now state that `scanner.rs` performs both operations before
handing a clean UTF-8 string to the pure core. Added invariants: no pure core module performs
BOM detection or CRLF replacement. Architecture Module field updated to `scanner.rs`. BC title
updated to include "(Shell-Side)".

**SF-002 (BC-2.08.003 — non-Markdown target and directory target routing):**
The original PRD Section 2.8 had stale BC titles that did not match the actual BC files
(BC-H1 is authoritative per bc_h1_is_title_source_of_truth policy). The behavior "non-Markdown
targets pass without anchor check" was uncontracted. Actions taken:
1. **Fixed Section 2.8 titles** to match actual BC file H1s (BC-2.08.001..004).
2. **Corrected BC-2.07.005**: plain directory link (no fragment) verdict changed from `broken`
   to `clean`, aligning with test-vectors TV-029/TV-030 and the feasibility review.
3. **Created BC-2.07.006** (Non-Markdown Target — File Existence Check Only, Anchor Resolution
   Skipped): contracts that when a path resolves to a non-.md file, `path_resolver.rs` skips
   anchor resolution regardless of any fragment. Backs EC-072 and EC-073.
4. **Updated Section 6.1 (KD-001)** to reference the corrected BC IDs.
5. **Fixed Section 2.5 titles** to match actual BC file H1s (BC-2.05.001..003).

**SF-003 (BC-2.04.003 — cross-module acceptance criteria):**
Revised BC-2.04.003 to add explicit acceptance criteria for BOTH `link_extractor.rs` (no link
extraction from code blocks — already VP-014) AND `anchor_table.rs` (no heading extraction from
code blocks — requires a new dedicated unit test). Added joint ownership notation in the
Architecture Module field. Added story-writer note about VP gap for anchor_table.rs side.

**NOTE-4 (BC-2.06.001 — slug input disambiguation):**
Clarified Invariant 2 in BC-2.06.001 to precisely define "rendered text content":
- Inline code spans: the TEXT NODE inside the span IS included (backtick markup stripped only)
- HTML elements: NEITHER tag markup NOR text content inside HTML tags contributes to rendered text
This disambiguates "heading title" (the raw source text) from "rendered text content" (the AST
text-node concatenation). Matches github-slugger v2 / GitHub rendering behavior.

**NOTE items from feasibility-review.md:**
- N-001 (SS-10 pure/effectful split): No spec change needed. Story-writer guidance in feasibility-review.md is authoritative; storywriter must assign BC-2.10.002 to `http_verdict.rs` (pure) and remaining SS-10 BCs to `http_client.rs` (effectful).
- N-002 (SS-09 url crate not pinned): No spec change. Story-writer must select and pin `url = "2.5"` when implementing SS-09.
- N-003 (NFR-001/002 provisional): No change. Both NFRs already marked `provisional` in nfr-catalog.md.
- N-004 (BC-2.05.003 title conflation): The feasibility review found the OLD PRD BC-2.05.003 title ("Ignored-file anchor tables built; two-pass design enforced") conflated two invariants. The actual BC files already resolve this correctly: BC-2.05.001 handles both two-pass design and ignored-file anchor tables. PRD Section 2.5 titles corrected to match actual BC H1s. Slug input disambiguation (task NOTE-4 description) applied to BC-2.06.001 as described above.

**Traceability corrections (Section 7 RTM):**
Section 7 RTM corrected to align with actual BC file traceability fields:
- BC-2.05 series: DI assignments updated from stale values to match BC file content
- BC-2.08 series: DI assignments updated; "R2b" → "R5" throughout (brief requirement alignment)
- BC-2.07.005: brief requirement corrected R2a → R5
- BC-2.07.006: added (new BC)

**NFR-001 and NFR-002:** Still marked `provisional`. No change.
