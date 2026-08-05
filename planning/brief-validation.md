---
document_type: brief-validation
level: ops
version: "1.0"
status: draft
producer: spec-reviewer
timestamp: 2026-08-05T18:15:00Z
phase: 1a
inputs: [BRIEF.md]
input-hash: "53940c2"
traces_to: BRIEF.md
---

# Brief Validation Report: mdlinkcheck

**Brief under validation:** `/Users/jmagady/Dev/mdlinkcheck-cloud/BRIEF.md` (frozen pilot brief — NOT modified by this pass)
**Pipeline step:** `planning.lobster` / `validate-existing-brief`
**Skill:** `vsdd-factory:validate-brief`
**Companion artifact:** `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/planning/artifact-detection.md` (shallow brief check; this report is the deep pass)
**Word count:** 301 words | **Estimated tokens:** ~440

---

## Executive summary

The brief is **structurally sound, well-scoped, and free of bloat** — it is the right
*size* for an L1 artifact. Its problem is the opposite of bloat: it is **materially
under-determined at the decision level**. R1-R8 read as complete prose but almost every
requirement contains at least one branch point with two or more defensible answers, and
several (R2c fallback semantics, R6 JSON schema, R7 exit-code precedence, R8 measurement
method) are **not testable as written** — meaning no behavioral contract or verification
property can be derived from them without a Product Owner decision first.

The single highest-value output of this pass is the enumerated
**ambiguity list (AMB-001..AMB-071)** and **edge-case list (EC-001..EC-094)** below. Those
lists are the actual work queue for L3 behavioral-contract authoring.

**Most consequential findings:**

1. **No markdown-flavor spec is pinned** (BV-001). R2/R3/R4 are all defined against an
   unnamed parser. This is the root ambiguity from which ~30 downstream edge cases hang.
2. **The GitHub slug algorithm is not version-pinned** (BV-002), and the reference the
   factory *does* carry is silent on duplicate-heading suffixes — the exact case flagged.
3. **R8 is unmeasurable as written** (BV-003) — no hardware baseline, no corpus definition,
   no statistic, no build profile. Cannot become a VP.
4. **R6's JSON output has no schema** (BV-004) and R6's "failure reason" has no closed
   taxonomy — yet the Success Criteria imply golden-file testing that requires both.
5. **R7's exit codes have no precedence rule and no fail-fast/resilient decision** (BV-005).
6. **Case sensitivity is unaddressed** (BV-006) — the same repo will classify differently on
   macOS (case-insensitive APFS, NFD filenames) than on Linux, directly contradicting the
   brief's own "deterministic" and "no false positives" promises.
7. **The brief is its own R4 test fixture** (BV-013) — a genuinely useful observation, see below.

---

## Section Assessment

The brief does not use the canonical VSDD brief section names. Assessment maps its actual
headings onto the required sections.

| Required Section | Brief's Heading | Status | Finding |
|---|---|---|---|
| What Is This? | (untitled line 3) + `## Problem` | **PASS** | One-line product statement plus a 3-sentence problem statement. Clear, specific, non-generic. Names the real failure mode ("false positives that train people to ignore it"). |
| Who Is It For? | `## Users` | **WEAK** | Single sentence, 13 words. One undifferentiated persona ("Engineers running it locally and in CI"). No pain point specific to a persona, **no current workaround named**, no distinction between the local-dev persona (wants speed + low noise) and the CI persona (wants determinism + machine-readable output). These two personas have *conflicting* requirements (interactive color/progress vs. stable parseable output) and that conflict is invisible at L1. |
| Scope — In Scope | `## Functional requirements` (R1-R8) | **PASS** | 8 capabilities, within the 3-7 guideline band (8 is acceptable). Reads as capabilities, not user stories. Note: R8 is an NFR living in the FR list — cosmetic. |
| Scope — Out of Scope | `## Non-goals` | **PASS** | 6 explicit exclusions (link rewriting, HTML parsing, JS rendering, config file, watch mode). Exceeds the 1-item minimum. One exclusion ("no HTML parsing") has an unflagged conflict with R2b — see BV-008. |
| Success Criteria | `## Success criteria` | **WEAK** | 3 criteria, **zero numerical targets**. "Passes its own test suite" is circular (tautological — any suite it passes satisfies it). "correctly classifies the acceptance corpus" references an artifact that **does not exist and is not defined** (BV-007). "runs clean on this repo's own README" references a file that **does not exist in the repo** (BV-012). The only number in the whole brief (5s / 500 files) lives in R8, not here. |
| Constraints & Integration Points | **ABSENT** | **FAIL** | No constraints section. Missing, and needed by downstream: target platform matrix (macOS/Linux/Windows?), Rust MSRV, distribution channel (cargo / prebuilt binaries / GitHub Action?), TTY/`NO_COLOR` behavior, proxy/TLS behavior in corporate CI, JSON schema stability commitment, license. The Rust constraint is stated in the *overview* line instead (leakage — see below). |

---

## Quality Check

| Criterion | Result | Finding |
|---|---|---|
| Specificity | **PASS** | No vague filler. No "various users", no "should be performant". R8 even attempts a number. |
| Measurability | **FAIL** | Success Criteria contain zero numbers. R8's number ("under 5 seconds on a developer laptop") is stated but **not operationalized** — "a developer laptop" is not a measurement baseline (BV-003). |
| Scope bounds (no contradiction) | **WARN** | One real contradiction: Non-goals say "no HTML parsing", but R2b's anchor matching against real-world GitHub markdown requires honoring `<a name="x">` / `<a id="x">` / `<h2 id="x">` anchors, which *are* HTML. Either accept a documented false-positive class or relax the non-goal (BV-008). Second, softer tension: "no config file (flags only)" + no inline-suppression mechanism means the only escape hatch is `--ignore`/`--allow` flag sprawl (BV-009). |
| Audience clarity | **WEAK** | "Engineers ... on repos containing Markdown" is close to the skill's own anti-example ("developers"). Two distinct personas are conflated (BV-010). |
| Constraint actionability | **N/A** | No constraints section exists to assess. |

---

## Bloat Check (Context Engineering)

| Check | Measurement | Result |
|---|---|---|
| Core-section word count | 301 words | **PASS** (limit 500; flag threshold 800) |
| Token estimate | ~440 tokens | **PASS** — 440 / 1,500 recommended max |
| Narrative padding | none detected | **PASS** — no business justification, no competitive analysis, no market research prose |
| Requirements leakage | R1-R8 numbered requirements present | **WARN (accepted)** — the skill's bloat check flags numbered requirements as PRD-level content. Here the R1-R8 numbering is *net-positive*: it gives L3 authors stable citation anchors for BC traceability, and the entire brief still fits in 440 tokens. **Recommendation: do not "fix" this.** The brief is frozen; keep R1-R8 as the L1 traceability root. |
| Acceptance criteria leakage | none | **PASS** |
| Architecture decision leakage | partial — see Implementation Leakage | **WARN** |

## Bloat Score

**Estimated tokens:** ~440 / 1,500 recommended max — **OK**

**Verdict: the brief is not bloated. It is under-determined.** The remediation direction is
*downward* into the PRD (resolve ambiguities as BCs), not *upward* into the brief. Do not
add the AMB/EC content below to BRIEF.md — that would convert a 440-token L1 artifact into
a 6,000-token pseudo-PRD and destroy its context-efficiency. **Resolve in L3.**

---

## Implementation Leakage Check

| Line | Text | Section | Severity | Assessment |
|---|---|---|---|---|
| 3 | "written in Rust" | Overview (not Scope/Success) | **Warning** | Prescriptive language choice. Legitimate as a hard pilot constraint, but it belongs in a Constraints section with a stated rationale (single static binary, startup time, no runtime dependency in CI), not asserted in the product one-liner. **Do not remove — relocate conceptually at L2/L3 and record the rationale as an ASM.** |
| 20 | "HEAD request (GET fallback on 405), 10s timeout" | R2c (in-scope FR) | **Warning** | HTTP-method-level mechanics are HOW, not WHAT. Defensible as *observable* protocol behavior, and it is load-bearing (politeness to external sites). Keep, but note it is under-specified rather than over-specified (see AMB-030..AMB-041). |
| 27 | "`--format json`" | R6 | **Info** | Interface surface, appropriate at L1. |

No framework, database, or infrastructure leakage. No library pinning. **Overall leakage: LOW
and defensible.** Two Warnings, both relocations rather than removals.

---

## Information Density Check

Scanned for conversational filler, wordy phrases, redundant phrases, and hedge words.

| Category | Instances | Detail |
|---|---|---|
| Conversational filler | 0 | — |
| Wordy phrases | 0 | — |
| Redundant phrases | 0 | — |
| Hedge words | 0 | — |

**Total: 0 instances. Result: PASS (<5 threshold).** Density is excellent — this brief is
tightly written. Every sentence carries payload.

---

## Completeness Check

| Check | Result |
|---|---|
| Not just a title or one-liner | **PASS** — 42 lines, 301 words |
| At least 150 words | **PASS** — 301 words |
| No TBD / TODO placeholders | **PASS** |
| Canonical VSDD frontmatter | **FAIL (minor)** — no YAML frontmatter; resolved by the copy-to-`.factory/specs/product-brief.md` step already recommended in `artifact-detection.md` |

---

## Market Intelligence Cross-Check

**Result: NOT_RUN — no market intelligence artifact exists.**

`.factory/specs/` contains only `.gitkeep` files; there is no
`market-intelligence-assessment.md` to cross-check against. Two observations that a market
intel pass would likely surface, recorded here so they are not lost:

- **BV-011 (Prior art / differentiation not addressed).** The brief claims a pain but names
  no existing tool and no differentiation. Mature tools already occupy nearly this exact
  requirement set — `lychee` (Rust, fast, offline mode, glob excludes, JSON output),
  `markdown-link-check`, `mlc`, `liche`, `hyperlink`. R1-R8 is close to a subset of `lychee`.
  For a **deliberately known-shape pilot** this is correct and desirable (a well-understood
  problem is the right factory test load), but the brief should say so explicitly, otherwise
  a downstream agent may invent a differentiation story that was never intended.
  → **Human decision, not a PO decision.** Recommend one sentence in an ASM: "This is a
  pilot; differentiation vs. prior art is explicitly out of scope."
- **Pain claim is plausible but unvalidated.** "false positives that train people to ignore
  it" (line 8) is a strong, testable design driver and it *should* be promoted to a
  first-class NFR/invariant, not left as problem-statement prose. It directly governs
  AMB-036 (5xx handling), AMB-052 (case sensitivity), and AMB-063 (retry policy) — in each
  case the "no false positives" principle picks the answer.

---

# GAPS — missing substance the downstream pipeline needs

Severity: **CRITICAL** = blocks BC authoring | **HIGH** = will cause spec churn or a wrong
implementation | **MEDIUM** = resolvable at L3 with a recorded decision | **LOW** = polish.

| ID | Severity | Gap | Why it blocks | Resolution owner |
|---|---|---|---|---|
| BV-001 | **CRITICAL** | **No markdown flavor/spec version pinned.** R2, R3, R4 all describe parsing behavior against an unnamed grammar. | ~30 of the edge cases below have *different correct answers* under CommonMark 0.31.2 vs. GFM vs. `pulldown-cmark` vs. `comrak` vs. a regex scanner. Without a pinned grammar, "correct" is undefined and no BC is falsifiable. | PO (recommend: **CommonMark 0.31.2 + GFM extensions**, named explicitly, with the AST-based-not-regex approach as an architecture invariant) |
| BV-002 | **CRITICAL** | **GitHub slug algorithm not version-pinned, and duplicate-heading behavior absent.** R2b says "GitHub's slug algorithm" with no version or source. | `github-slugger` v2.0.0 does **not** collapse consecutive hyphens; older implementations do → `AI & Automation` yields `ai--automation` vs `ai-automation`. Different answers for the same input. Separately, **duplicate headings** get an occurrence counter (`foo`, `foo-1`, `foo-2`) which the factory's own `dclaude:github-slug-reference` skill **does not document** — that reference is incomplete for this product's needs. | PO (recommend: pin **`github-slugger` v2.0.0** by name+version, adopt `dclaude:github-slug-reference` as the base table, and **extend it** with duplicate-counter, underscore-retention, and Unicode rules) |
| BV-003 | **CRITICAL** | **R8 is unmeasurable.** "under 5 seconds on a developer laptop" specifies neither hardware, corpus shape, build profile, cache state, thread count, sample count, nor statistic. | No verification property can be written. A VP needs a deterministic pass/fail predicate; "a developer laptop" has none. | Human (hardware baseline is a human call) + PO (corpus + statistic) |
| BV-004 | **CRITICAL** | **No JSON schema and no failure-reason taxonomy.** R6 requires a "failure reason" and "a machine-readable array of the same" — with no field names, types, nesting, or enumerated reason set. | The Success Criteria imply golden-file / corpus-classification testing, which requires byte-stable output. Also: the error taxonomy is a mandatory PRD supplement (`prd-supplements/error-taxonomy.md`) and the brief provides **zero seed values** for it. | PO |
| BV-005 | **CRITICAL** | **R7 exit codes: no precedence rule, no fail-fast decision.** What happens when a run has *both* a broken link (1) and an I/O error (2)? Is one unreadable `.md` among 500 an abort (2) or a reported per-file failure that continues? | Determines the entire error-handling architecture (fail-fast vs. accumulate). Getting this wrong is a rewrite, not a patch. Also R7 enumerates only {0,1,2} with no slot for an internal panic (Rust default 101) or SIGINT. | PO (precedence) + Human (fail-fast vs. resilient is a product-behavior call) |
| BV-006 | **HIGH** | **Path case sensitivity and Unicode normalization unaddressed.** No statement on whether `[x](README.MD)` matching `README.md` is a pass. | macOS APFS is case-insensitive *and* stores filenames NFD-normalized; Linux ext4 is case-sensitive and byte-literal. The same repo therefore classifies **differently locally vs. in CI** — a direct violation of the brief's own "deterministic" (line 7) and CI-trust premise. Must be decided as a hard invariant (recommend: always compare case-sensitively against actual directory entries, and NFC-normalize before comparison, regardless of host FS). | PO + Human (platform matrix) |
| BV-007 | **HIGH** | **"acceptance corpus" is a dangling reference.** Named as the primary acceptance gate; never defined, located, sized, or assigned an author. | This is the *main* success criterion. Needs: repo location, file count, number of planted breaks per failure class, number of valid-link traps per false-positive class, and an expected-classification manifest (the golden file). Should become a first-class deliverable story, not an assumed fixture. | PO |
| BV-008 | **HIGH** | **"no HTML parsing" (Non-goals) conflicts with R2b anchor resolution.** Real GitHub markdown defines anchors via `<a name="x">`, `<a id="x">`, and `<h2 id="x">`. | Under a literal no-HTML reading, every link to a hand-authored HTML anchor is a **false positive** — the exact failure mode the Problem statement says the tool must avoid. Needs an explicit, narrow carve-out ("extract `id`/`name` attributes as anchor sources; do not otherwise parse HTML") or an explicitly accepted false-positive class. | PO + Human |
| BV-009 | **MEDIUM** | **No inline suppression mechanism, and no config file (non-goal).** | Every real-world exception must become a CLI flag. Large repos will hit `--ignore`/`--allow` sprawl in CI invocations. Either accept explicitly, or add a narrow `<!-- mdlinkcheck-disable-next-line -->` comment directive (which is *not* a config file and does not violate the non-goal). | PO + Human |
| BV-010 | **MEDIUM** | **Two conflicting personas conflated in `## Users`.** Local-interactive vs. CI-automated have opposing needs (color/progress/partial output vs. determinism/stable ordering/machine parsing). | Drives TTY detection, `NO_COLOR`, progress reporting, and output-ordering decisions — none of which currently have a requirement to hang from. | PO |
| BV-011 | **MEDIUM** | **No prior-art / differentiation statement.** See Market Intelligence Cross-Check. | Prevents a downstream agent inventing scope to "differentiate". | Human |
| BV-012 | **MEDIUM** | **Success criterion references a nonexistent file.** "runs clean on this repo's own README" — the repo contains no `README.md` (only `BRIEF.md`, `.envrc`, `.gitignore`, `.mcp.json`). | An unsatisfiable acceptance criterion. Either create the README as a tracked deliverable or restate the criterion against `BRIEF.md`. | PO |
| BV-013 | **MEDIUM** | **The brief is its own R4 test fixture — and this is load-bearing.** `BRIEF.md` lines 18-19 contain `[x](docs/a.md)`, `[x](../b.md)`, `[x](#setup)`, `[x](a.md#usage)`. All four are inside inline code spans, so **R4 (ignore inline code) is the only reason the tool does not report its own brief as having 4 broken links.** | Excellent free test vector: `mdlinkcheck BRIEF.md` **must** exit 0. If R4's inline-code handling is wrong, the tool fails on the very document that specifies it. Promote to a canonical test vector *and* a holdout scenario. Also note `docs/` does not exist, so a regression here produces confident, wrong failures. | PO (make it a named test vector) |
| BV-014 | **MEDIUM** | **No `.gitignore` / hidden-directory traversal policy.** R1 says "scans the given files/directories (default `.`)" with no exclusion defaults. | Directly determines whether R8's 5-second target is achievable — a repo with `node_modules/` or `target/` containing thousands of `.md` files will blow the budget. Also determines whether `.git/` is walked. Recommend: respect `.gitignore` by default and skip dot-directories, both overridable. | PO |
| BV-015 | **MEDIUM** | **Output ordering is unspecified — and conflicts with R8.** R6 defines *content* per finding but no *order*, while R8's 5s target effectively requires parallel file scanning. | Parallelism without an explicit sort produces nondeterministic output ordering, which breaks golden-file tests *and* the brief's "deterministic" premise (line 7). Needs an explicit invariant: results sorted by (path, line, column) before emission, regardless of scan order. | PO |
| BV-016 | **LOW** | **No platform / distribution / MSRV constraints.** | Needed by the architect and devops-engineer (CI matrix, release artifacts, `cargo install` vs. prebuilt binaries, Windows CRLF and path-separator handling). | Human |
| BV-017 | **LOW** | **Success criterion "Passes its own test suite" is circular.** | Provides no external signal. Replace or supplement with coverage / mutation-score thresholds (or explicitly defer to Phase 6 formal hardening). | PO |
| BV-018 | **LOW** | **No stdout/stderr contract.** Which stream carries findings vs. diagnostics? | Required for CI piping (`mdlinkcheck --format json > report.json`) — diagnostics must not pollute stdout. | PO |
| BV-019 | **LOW** | **No JSON schema stability commitment.** | Consumers will parse it. Needs a versioning statement (e.g. a `schema_version` field) or an explicit "unstable pre-1.0" declaration. | PO |

---

# AMBIGUITIES AND UNSTATED ASSUMPTIONS

Every item below is a point where the brief admits **two or more defensible readings**. The
Product Owner must pick one per item when authoring behavioral contracts. Grouped by
requirement ID; a recommended default is given where one is clearly implied by the brief's
own stated intent ("deterministic", "no false positives").

## R1 — Discovery and traversal

| ID | Ambiguity | Recommended default |
|---|---|---|
| AMB-001 | Is directory traversal **recursive**? "scans the given files/directories" does not say. Unbounded depth or a limit? | Recursive, unbounded |
| AMB-002 | Are **dot-directories** (`.git/`, `.github/`, `.factory/`) traversed? `.github/` legitimately contains `.md` files; `.git/` must never be walked. | Skip dot-dirs by default; `--hidden` to include |
| AMB-003 | Is **`.gitignore` respected**? (See BV-014.) What about `.ignore`, nested `.gitignore`, global gitignore? | Respect `.gitignore` + nested; `--no-ignore-vcs` to disable |
| AMB-004 | Which **extensions** count as markdown? `*.md` only, or also `.markdown`, `.mdown`, `.mkd`, `.mdx`? | `.md` and `.markdown` |
| AMB-005 | Is extension matching **case-sensitive**? `README.MD`, `notes.Md`. | Case-insensitive extension match |
| AMB-006 | If an **explicit file argument is not markdown** (`mdlinkcheck notes.txt`), is it parsed anyway, silently skipped, or a usage error? | Parse it (explicit intent overrides extension filter) |
| AMB-007 | Are **symlinks followed** — for directories, for files, or neither? Are symlink **cycles** detected? Does a symlink pointing outside the scan root get followed? | Do not follow directory symlinks (cycle safety); do follow file symlinks |
| AMB-008 | **Overlapping/duplicate path arguments** (`mdlinkcheck . docs docs/a.md`) — is each file scanned once or N times? Are findings deduplicated? | Deduplicate by canonicalized path |
| AMB-009 | **Zero markdown files found** — exit 0 (nothing broken) or exit 2 (probable user error)? Silent or a message? | Exit 0 with an informational message on stderr |
| AMB-010 | Is a **nonexistent** PATH argument the same as R7's "unreadable path"? Not-found vs. permission-denied may warrant distinct reasons. | Both exit 2, distinct reason codes |
| AMB-011 | **Non-UTF-8 file content** — exit 2, or skip the file with a reported failure and continue? Lossy decode? | Report as a per-file failure, continue (ties to BV-005) |
| AMB-012 | **BOM** at file start — stripped before parsing? (Affects line 1 offsets and the first heading's slug.) | Strip UTF-8 BOM |
| AMB-013 | **CRLF line endings** — are line numbers identical to LF? Is `\r` stripped from link destinations? | Normalize; identical line numbers |
| AMB-014 | Are **Windows paths** supported (backslash separators in link destinations, drive letters)? Is Windows a target platform at all? | Ties to BV-016 (human decision) |
| AMB-015 | **Output path form** — absolute, relative to CWD, or relative to the scanned root? | Relative to CWD (CI-friendly, stable) |
| AMB-016 | **Non-regular files** encountered during the walk (FIFOs, sockets, device files named `*.md`). | Skip silently |

## R2a — Relative file links

| ID | Ambiguity | Recommended default |
|---|---|---|
| AMB-017 | **Resolution base** — relative to the containing file's directory, or the repo root? | Containing file's directory (GitHub behavior) |
| AMB-018 | **Root-relative links** (`[x](/docs/a.md)`) — resolved against repo root (GitHub), filesystem root (POSIX), or the scan root? All three are defensible; they give different answers. | Repo root (git top-level); fall back to scan root if not a git repo |
| AMB-019 | Links **escaping the scan root** (`[x](../../elsewhere/a.md)`) — checked against the real filesystem, skipped, or reported as out-of-scope? | Check against the filesystem |
| AMB-020 | **Percent-encoded destinations** (`[x](docs/my%20file.md)`, `%2F`) — decoded before filesystem resolution? | Percent-decode |
| AMB-021 | **Angle-bracket destinations** (`[x](<my file.md>)`) — supported? | Supported per CommonMark |
| AMB-022 | **Unencoded spaces** in a bare destination — where does the destination end? | Per CommonMark (destination ends at whitespace) |
| AMB-023 | **Link titles** (`[x](a.md "Title")`) — stripped before resolution? Single-quote and paren title forms too? | Strip all three title forms |
| AMB-024 | **Links to directories** (`[x](docs/)`, `[x](docs)`) — pass (GitHub renders a directory listing) or fail (not a file)? *Explicitly flagged; brief is silent.* | Pass if the directory exists; distinct reason if it does not |
| AMB-025 | **Empty destination** (`[x]()`) — broken link, ignored, or malformed-syntax error? | Report as malformed |
| AMB-026 | **Query strings on local paths** (`[x](a.md?raw=1)`) — stripped before resolution or treated as part of the filename? | Strip query |
| AMB-027 | **Trailing slash on a file link** (`[x](a.md/)`) — pass or fail? | Fail (not a directory) |
| AMB-028 | **Broken symlink target** — `Path::exists()` follows symlinks, so a dangling symlink reports as missing. Is that the intended classification, and is the reason distinct from "file not found"? *Explicitly flagged.* | Fail with a distinct `broken-symlink` reason |
| AMB-029 | **Non-markdown link targets** (`[x](logo.png)`, `[x](build.sh)`) — existence-checked? (Presumably yes.) | Existence-checked; anchors N/A |

## R2c — External URLs (HEAD/GET fallback — explicitly flagged as under-specified)

| ID | Ambiguity | Recommended default |
|---|---|---|
| AMB-030 | **GET fallback trigger set.** Brief says "on 405" only. Real-world servers reject HEAD with **403, 400, 404, 429, 501, 503**, and some CDNs/WAFs (Cloudflare) block HEAD outright. A 405-only fallback guarantees false positives. *Explicitly flagged.* | Fall back to GET on 400, 403, 404, 405, 429, 501, and on any 5xx |
| AMB-031 | Is the GET fallback a **full GET** or a ranged GET (`Range: bytes=0-0`)? Full GET on large assets wastes bandwidth. | Ranged GET, fall back to full GET if range unsupported |
| AMB-032 | **Which statuses count as OK?** 2xx only? Is 3xx-terminal OK? | 2xx = OK |
| AMB-033 | **401 / 403 after fallback** — the resource exists but is auth-gated. Broken link or not? | Not broken (distinct `auth-required` info, non-failing) |
| AMB-034 | **429 rate-limited** — broken? | Not broken; retry with backoff, then non-failing warning |
| AMB-035 | **404 vs. 410** — distinguished in the reason taxonomy? | Distinguish |
| AMB-036 | **5xx** — the remote server is broken, not the link. Flagging it produces exactly the CI false-positive noise the Problem statement targets. Broken or warning? | **Warning, not failure** (per "no false positives") |
| AMB-037 | **Redirects** — followed? Max hop count? Redirect loop detection? Is an `https`→`http` downgrade allowed? Is a redirect to a login/consent page (200 OK, wrong content) detectable? (It is not, without content inspection — state that limitation.) | Follow, max 10 hops, loop-detect, allow downgrade with a warning |
| AMB-038 | **"10s timeout"** — connect, read, or total? **Per attempt** or **per URL** (including HEAD + GET fallback + N redirects)? A per-attempt reading makes worst-case latency 10s x (1 + 1 + 10 redirects). *Explicitly needs pinning.* | Total per URL, 10s wall clock, covering all attempts and redirects |
| AMB-039 | **Retry policy** — none stated. A single transient DNS blip becomes a red CI build. Zero retries, or N with backoff? | 2 retries, exponential backoff, only for network/timeout/5xx/429 |
| AMB-040 | **Concurrency** for online checks — degree of parallelism, per-host connection limits, politeness delay? Unstated, yet required for tolerable runtime. | Global cap (e.g. 32), per-host cap (e.g. 4) |
| AMB-041 | **User-Agent** — many sites 403 unknown or empty UAs. What UA is sent? | `mdlinkcheck/<version>` with a project URL |
| AMB-042 | **TLS behavior** — are expired / self-signed / hostname-mismatched certificates broken links? Is there a `--insecure`? A custom CA bundle for corporate CI? | Fail with a distinct `tls-error` reason; provide `--insecure` |
| AMB-043 | **Proxy support** — are `HTTP_PROXY` / `HTTPS_PROXY` / `NO_PROXY` honored? (Corporate CI depends on this.) | Honor standard env vars |
| AMB-044 | **URL deduplication** — the same URL appearing in 50 files: fetched once or 50 times? Reported once or 50 times? | Fetch once, report at every occurrence |
| AMB-045 | **Cross-run caching** — out of scope? (Not listed in non-goals.) | Out of scope; state explicitly |
| AMB-046 | **Localhost / private-IP / link-local URLs** (`http://localhost:3000`, `http://192.168.1.1`) — always fail in CI. Skipped by default, or must be `--allow`ed? Any SSRF consideration? | Skip loopback/private ranges by default with a warning |
| AMB-047 | **Fragment on an external URL** (`https://x.com/page#section`) — anchor verified? (Cannot be, given "no HTML parsing".) State that the fragment is ignored. | Ignore fragment; document the limitation |
| AMB-048 | **"syntax-validated but not fetched"** — *the single vaguest phrase in the brief.* Which grammar (RFC 3986? WHATWG URL?)? What constitutes a syntax failure — `htp://x`, `https://`, `https://exam ple.com`, `https://foo` (no TLD), a non-ASCII/IDN host? Does a syntax failure exit **1** or **2**? Does it appear in JSON output? *Explicitly flagged.* | WHATWG URL parse; failure = broken link (exit 1) with `malformed-url` reason |
| AMB-049 | Does **`--online` also change offline behavior** (i.e. is syntax validation still performed when fetching)? | Yes, syntax-validate first, then fetch |
| AMB-050 | Is there an explicit **`--offline`** flag (to pin behavior if the default ever flips)? | Add it as a no-op-today explicit opt-in |

## R2b — Heading anchors

| ID | Ambiguity | Recommended default |
|---|---|---|
| AMB-051 | **Slug algorithm version** — see BV-002. `github-slugger` v2 (no hyphen collapsing) vs. older (collapsing). | Pin `github-slugger` v2.0.0 |
| AMB-052 | **Duplicate headings** — two `## Setup` headings produce `setup` and `setup-1`. Is the counter **0-based** (2nd occurrence → `-1`) as `github-slugger` does, or 1-based? Is it **per-file** (yes) or global? What happens when a literal heading `## Setup 1` **collides** with the generated `setup-1` — who wins, and does the loser get bumped to `setup-1-1`? *Explicitly flagged; the factory's own slug reference is silent on all of this.* | Mirror `github-slugger` exactly: per-file, 0-based counter, collision-bumping while-loop |
| AMB-053 | **Anchor comparison case sensitivity** — does `[x](#Setup)` match heading `## setup`? GitHub slugs are lowercase and browser fragment matching is case-sensitive, so on GitHub it does **not** match. Match or fail? | Case-sensitive comparison against the lowercased slug (so `#Setup` fails) — but flag as a likely-typo reason |
| AMB-054 | **Underscores** — `github-slugger` **retains** `_` (0x5F is outside its removal set). So `## my_heading` → `my_heading`, not `my-heading`. Is this replicated? *Not documented in the factory's slug reference.* | Retain underscores |
| AMB-055 | **Unicode headings** — `## Café`, `## 日本語`. Slug retains Unicode letters lowercased. Link may be **percent-encoded** (`#caf%C3%A9`) or literal (`#café`); both must resolve. Additionally macOS supplies **NFD** while most editors write **NFC** — normalization form must be pinned. | NFC-normalize both sides; percent-decode the fragment first |
| AMB-056 | **Trailing-hyphen / emoji ambiguity** — the factory's own reference says `Coherence Validation ✅` → `coherence-validation-` "(trailing hyphen, **may be trimmed**)". "May be" is not implementable. Must be pinned deterministically. | Pin to `github-slugger` v2 actual output; add as a canonical test vector |
| AMB-057 | **Inline markup inside headings** — `## **Bold** and \`code\` and [a link](x)`. Is the slug computed from the raw source text or the rendered plain text? (GitHub uses rendered text.) | Rendered plain text |
| AMB-058 | **Setext headings** (`Title` + `=====`) — recognized as anchor sources? | Yes |
| AMB-059 | **HTML anchors** — `<a name="x">`, `<a id="x">`, `<h2 id="x">`. See BV-008. | Extract `id`/`name` as anchor sources (narrow carve-out) |
| AMB-060 | **Explicit heading-ID syntax** — `## Title {#custom-id}` (kramdown / pandoc, **not** GitHub). Supported, ignored, or does the literal `{#custom-id}` text feed into the slug (yielding `title-custom-id`)? | Not supported; the braces feed the slug per GitHub behavior |
| AMB-061 | **ATX-looking lines inside fenced code blocks** — `# not a heading` inside a fence must **not** create an anchor. R4 covers *links* in code, and is silent about *headings* in code. | Do not treat as headings |
| AMB-062 | **YAML front matter** — skipped before parsing? Does a front-matter `title:` create an anchor (Jekyll/Hugo do render one)? Does `---` get misread as a setext underline? | Skip front matter; no anchor from it |
| AMB-063 | **Anchors in a file excluded by `--ignore`** — is the ignored file's heading table still built so that *incoming* cross-file anchors resolve? If not, `--ignore` silently manufactures false positives. **R5 × R2b interaction, entirely unstated.** | Build heading tables for ignored files as link *targets*; only exclude them as link *sources* |
| AMB-064 | **Anchor into a non-markdown target** (`[x](notes.txt#foo)`, `[x](img.png#frag)`) — no headings parseable. Skip the anchor check, or fail? | Skip anchor check (pass if the file exists) |
| AMB-065 | **Line-range anchors** (`#L12`, `#L12-L20`) — GitHub's code-line anchors. Under heading matching these always fail. Special-cased? | Special-case: recognize and skip |
| AMB-066 | **Empty anchor** (`[x](#)`) — GitHub treats bare `#` as "top of page" (valid). Pass, fail, or ignore? *Explicitly flagged.* | Pass (top of document) |
| AMB-067 | **Multiple `#` in a destination** (`[x](a.md#a#b)`) — where does the fragment start? | First `#` splits; remainder is the literal fragment |
| AMB-068 | **Whitespace in/around a fragment** (`[x](#setup )`, `[x](# setup)`) — trimmed? | Trim outer whitespace only |
| AMB-069 | **Self-file equivalence** — inside `README.md`, must `[x](#setup)` and `[x](README.md#setup)` and `[x](./README.md#setup)` behave identically? | Yes, identically |

## R3 / R4 — Parsing scope

| ID | Ambiguity | Recommended default |
|---|---|---|
| AMB-070 | **Undefined reference label** (`[text][nolabel]`) — R3 says reference links are "checked the same as inline ones", but an unresolvable *label* is a **new failure class** that has no inline analogue. Is it a broken link (exit 1), a warning, or ignored? Also: **unused** definitions — reported? **Duplicate** definitions — first or last wins (CommonMark: first)? Are labels matched case-insensitively with collapsed whitespace (CommonMark: yes)? Are **shortcut** (`[foo]`) and **collapsed** (`[foo][]`) forms in scope? | Undefined label = broken link; unused = not reported; first definition wins; case-insensitive + whitespace-collapsed matching; all three reference forms in scope |
| AMB-071 | **R4's exclusion boundary.** Fenced (```` ``` ````, `~~~`) and inline spans are named. Silent on: **4-space indented code blocks**, HTML `<pre>`/`<code>`, math blocks (`$$`), **HTML comments** (`<!-- -->`), unclosed fences at EOF, longer/nested fences, fences indented inside list items or blockquotes, and double-backtick inline spans containing a backtick. Indented code blocks and HTML comments are the two most likely false-positive sources in real repos. | Exclude indented code blocks, `<pre>`/`<code>`, and HTML comments; unclosed fence swallows to EOF (CommonMark) |

Additional unstated assumptions spanning R3/R4/R6 that also require a decision:

- **Images vs. links.** R3 says images are checked "the same". Confirm: does an image with a
  missing target exit 1 (same severity as a broken link) or produce a lower severity? Are
  **reference-style images** (`![alt][ref]`) in scope? Are `<img src>` HTML images in scope
  (probably not, per no-HTML)?
- **Autolinks.** `<https://x.com>` (CommonMark autolink) and GFM **literal autolinks** (a bare
  `https://x.com` in prose) are a **fourth** link form not enumerated in R2/R3. In scope? A
  literal-autolink scanner will find URLs in prose that authors never intended as links.
- **Footnotes.** `[^1]` references and `[^1]: text` definitions are syntactically close to
  reference links. Must be excluded, and the brief does not say so.
- **Escaped brackets.** `\[not a link\](x)` must not be treated as a link.
- **Table cells.** Links inside GFM tables, including escaped pipes (`\|`) inside destinations.
- **Line number semantics (R6).** Is "line" the line of the link's opening `[`, or of the
  destination? For a link whose destination wraps to the next line, which line is reported?
  1-based (assumed). Is a **column** reported? R6 says "file:line" only — confirm no column,
  which weakens editor jump-to-location.

## R5 — Flags

- **`--ignore <glob>` dialect.** Which glob syntax (gitignore-style, `globset`, POSIX
  fnmatch)? Does `**` cross directory boundaries? Is the pattern anchored at the scan root,
  the CWD, or unanchored? Matched against relative or absolute paths? Case-sensitive? Are
  negations (`!pattern`) supported? Does `docs` match the directory *and* everything under it,
  or must it be `docs/**`?
- **`--ignore` vs. explicit path argument precedence.** `mdlinkcheck README.md --ignore README.md`
  — which wins? (Classic bug.)
- **`--ignore` scope.** Excludes files as *sources* only, or also as *targets*? See AMB-063.
- **`--allow <url-prefix>` matching semantics.** Literal byte-prefix, or normalized-URL
  prefix? Is the scheme required? Is the host compared case-insensitively
  (`HTTPS://Example.COM`)? Critically, a naive literal prefix means
  `--allow https://example.com` also allows **`https://example.com.evil.tld`** — is that
  acceptable? Trailing-slash handling? Does `--allow` also suppress *offline* syntax
  validation, or only fetching?
- **`--format` invalid value** → exit 2 (assumed). Are there future formats? Is
  `--format text` explicitly accepted as the default's name?
- **`--help` / `--version` exit code.** R7 defines 0 as "no broken links" — a help invocation
  checked nothing. Definitional gap; needs an explicit "0 for successful non-check
  invocations".
- **Flag position.** Are flags accepted after positional arguments? Is `--` supported as an
  end-of-flags separator (needed for filenames starting with `-`)?
- **Repeated scalar flags.** `--format json --format text` — last-wins or error?
- **Environment variables.** "No config file" is a non-goal, but env-var configuration is
  unaddressed. Any env vars other than proxy/`NO_COLOR`?
- **Color / TTY.** Default output is human-readable text. Is it colorized? Is `NO_COLOR`
  honored? Is TTY detected? CI logs filling with ANSI escapes is a real defect class.
- **Progress reporting.** For a 500-file scan, any progress indicator? (Interacts with BV-010's
  persona split and with stdout purity.)

## R6 / R7 — Output and exit codes

- **JSON schema** — field names, types, nesting, array-of-what. Does it include *passing*
  links or only failures? Any summary object (counts by reason)? A `schema_version`? Pretty
  or compact? NDJSON variant? **Stable key order** (required for golden files)?
- **JSON on success** — `[]` or no output at all?
- **Failure-reason taxonomy** — closed enumerated set required. Minimum seeds implied by
  R1-R8: `file-not-found`, `target-is-directory`, `broken-symlink`, `target-unreadable`,
  `anchor-not-found`, `undefined-reference-label`, `malformed-url`, `http-status`,
  `http-timeout`, `dns-failure`, `tls-error`, `too-many-redirects`.
- **Reason text stability** — are human-readable reason strings part of the contract (golden
  files) or free text? Are machine reason *codes* separate from human messages?
- **Exit-code precedence** — broken link (1) + I/O error (2) in one run. See BV-005.
- **Fail-fast vs. resilient** — does one unreadable file abort the run? See BV-005.
- **Warnings vs. failures** — do non-failing conditions (5xx, 429, auth-required, skipped
  private IPs) affect the exit code? A severity model is needed and absent.
- **Panic / internal error exit code** — R7 enumerates only {0,1,2}. Rust panics exit 101.
  Needs an explicit invariant ("no exit code other than 0/1/2 is ever produced") or a
  documented fourth code.
- **SIGINT / SIGTERM** exit code and partial-output behavior.
- **Summary line** — is a trailing summary ("N broken links across M files") emitted? Its
  exact text becomes part of the golden files.
- **stdout vs. stderr split** — see BV-018.

## R8 — Performance

- **Hardware baseline** — "a developer laptop" is not a specification. Which CPU/core count,
  or is the target expressed relative to a named reference machine or a CI runner spec?
- **Corpus definition** — 500 files of what shape? Average file size, links per file,
  headings per file, ratio of local to anchor to external links?
- **Cache state** — cold or warm filesystem cache?
- **Build profile** — release with which opt-level/LTO settings? (Debug builds are 10-50x
  slower; a target with no profile stated is meaningless.)
- **Thread count** — fixed, or `num_cpus`? Is the 5s target single-threaded or parallel?
- **Measured span** — process start to exit (including binary load), or in-process scan time?
- **Statistic and sample count** — p50, p95, or max? Over how many runs? What variance is
  tolerated before a regression is declared?
- **Harness** — `hyperfine`, `criterion`, or a bespoke test? Where does the benchmark live,
  and does it gate CI?
- **Online-mode target** — none stated; presumably excluded as network-bound. State it.
- **Memory / resource budget** — none stated.
- **Parallelism vs. determinism invariant** — see BV-015.

---

# TESTABLE EDGE CASES IMPLIED BUT NOT STATED

Each row is a concrete test input whose expected output the brief does not pin. These are
directly promotable into `prd-supplements/test-vectors.md` and into holdout scenarios.

## Discovery (R1)

| ID | Input | Unstated expected behavior |
|---|---|---|
| EC-001 | `mdlinkcheck` with no arguments, CWD contains nested `.md` files | Recursion depth; exit code |
| EC-002 | Repo containing `node_modules/**/*.md` (5,000 files) | Traversed or skipped; R8 impact |
| EC-003 | `.github/PULL_REQUEST_TEMPLATE.md` | Dot-dir traversal |
| EC-004 | `.git/` containing files ending `.md` | Must not be walked |
| EC-005 | `README.MD` (uppercase extension) | Matched or not |
| EC-006 | `notes.markdown`, `notes.mdown`, `notes.mdx` | In or out of scope |
| EC-007 | `mdlinkcheck notes.txt` (explicit non-md arg) | Parsed, skipped, or exit 2 |
| EC-008 | Directory symlink creating a cycle (`a/b -> a`) | Must terminate |
| EC-009 | Symlink `docs -> ../shared-docs` (outside root) | Followed or not |
| EC-010 | `mdlinkcheck . docs docs/a.md` (overlapping args) | Single vs. triple reporting |
| EC-011 | Empty directory / no `.md` files anywhere | Exit 0 or 2 |
| EC-012 | `mdlinkcheck /does/not/exist` | Exit 2, reason text |
| EC-013 | `.md` file with mode `000` (no read permission) | Exit 2 abort vs. per-file failure + continue |
| EC-014 | `.md` file containing invalid UTF-8 bytes | Exit code and reason |
| EC-015 | `.md` file with a UTF-8 BOM, first line a heading | BOM stripped; heading slug correct |
| EC-016 | CRLF-only file with links on lines 5 and 10 | Reported line numbers identical to LF equivalent |
| EC-017 | Zero-byte `.md` file | No findings, exit 0 |
| EC-018 | 50 MB single `.md` file | No timeout/OOM; R8 impact |
| EC-019 | Filename containing spaces, `#`, `%`, or a newline | Correct reporting and quoting in text and JSON |
| EC-020 | FIFO named `pipe.md` in the tree | Must not block |
| EC-021 | A file modified while the scan is in flight | No panic |

## Relative file links (R2a)

| ID | Input | Unstated expected behavior |
|---|---|---|
| EC-022 | `docs/a.md` containing `[x](../README.md)` where README exists at root | Resolution base = containing file's dir |
| EC-023 | `docs/a.md` containing `[x](/docs/b.md)` | Root-relative resolution base (repo root vs. FS root) |
| EC-024 | `[x](../../../../etc/passwd)` | Escapes root — checked or refused |
| EC-025 | `[x](docs/my%20file.md)` where `docs/my file.md` exists | Percent-decode → pass |
| EC-026 | `[x](docs/my file.md)` (unencoded space, no angle brackets) | Destination boundary |
| EC-027 | `[x](<docs/my file.md>)` | Angle-bracket form → pass |
| EC-028 | `[x](a.md "Some title")` and `[x](a.md 'title')` and `[x](a.md (title))` | Title stripped → pass |
| EC-029 | `[x](docs/)` where `docs/` exists | Pass or fail |
| EC-030 | `[x](docs)` where `docs/` is a directory | Pass or fail |
| EC-031 | `[x]()` | Malformed vs. ignored |
| EC-032 | `[x](   )` (whitespace-only destination) | Same |
| EC-033 | `[x](a.md?raw=1)` where `a.md` exists | Query stripped → pass |
| EC-034 | `[x](a.md/)` where `a.md` is a file | Fail |
| EC-035 | `[x](./a.md)` and `[x](././a.md)` and `[x](dir/../a.md)` | All pass |
| EC-036 | `[x](README.MD)` where the file is `README.md` | **Passes on macOS, fails on Linux unless pinned** (BV-006) |
| EC-037 | macOS-created file `Café.md` (NFD) linked as `[x](Café.md)` (NFC) | Normalization required |
| EC-038 | `[x](link.md)` where `link.md` is a dangling symlink | Fail with distinct reason |
| EC-039 | `[x](logo.png)` where the image exists | Pass |
| EC-040 | `![alt](missing.png)` | Broken (R3) — severity and reason |
| EC-041 | `[x](/dev/null)` | Pass (exists) or refused |
| EC-042 | `[x](C:\docs\a.md)` on Linux | Reason |

## Anchors (R2b)

| ID | Input | Unstated expected behavior |
|---|---|---|
| EC-043 | `## AI & Automation` + `[x](#ai--automation)` | Double hyphen preserved (v2 semantics) — **must pass** |
| EC-044 | Same heading + `[x](#ai-automation)` | **Must fail** (proves v2 pinning) |
| EC-045 | `## Integrations - Growth` + `[x](#integrations---growth)` | Triple hyphen — pass |
| EC-046 | `## Phase 1: MVP (128 Features)` + `[x](#phase-1-mvp-128-features)` | Pass |
| EC-047 | Two `## Setup` headings + `[x](#setup)` and `[x](#setup-1)` | Both pass; counter is 0-based |
| EC-048 | Three `## Setup` + `[x](#setup-2)` | Pass |
| EC-049 | `## Setup`, `## Setup`, `## Setup 1` (literal) → all of `#setup`, `#setup-1`, `#setup-1-1` | Collision-bumping order — the single nastiest slug case |
| EC-050 | `## my_heading` + `[x](#my_heading)` | Underscore retained — pass |
| EC-051 | `## my_heading` + `[x](#my-heading)` | Must fail |
| EC-052 | `## Café` + `[x](#café)` | Pass |
| EC-053 | `## Café` + `[x](#caf%C3%A9)` | Percent-decoded — pass |
| EC-054 | `## 日本語` + `[x](#日本語)` | Pass |
| EC-055 | `## Done ✅` + `[x](#done-)` vs `[x](#done)` | Trailing-hyphen determinism (AMB-056) |
| EC-056 | `## **Bold** Heading` + `[x](#bold-heading)` | Rendered-text slug — pass |
| EC-057 | `## \`code\` heading` + `[x](#code-heading)` | Pass |
| EC-058 | `## [Link](x.md) heading` + `[x](#link-heading)` | Pass |
| EC-059 | `Setext Title` + `=====` + `[x](#setext-title)` | Pass |
| EC-060 | `####### seven hashes` | Not a heading → anchor absent |
| EC-061 | `#NoSpace` (ATX without a space) | Not a heading per CommonMark |
| EC-062 | `<a name="legacy"></a>` + `[x](#legacy)` | BV-008 decision point |
| EC-063 | `<h2 id="custom">T</h2>` + `[x](#custom)` | BV-008 decision point |
| EC-064 | `## Title {#custom}` + `[x](#custom)` vs `[x](#title-custom)` | AMB-060 |
| EC-065 | Fenced block containing `# Fake Heading` + `[x](#fake-heading)` | Must **fail** (no anchor from code) |
| EC-066 | YAML front matter `title: Foo` + `[x](#foo)` | Must fail; and `---` must not be read as a setext rule |
| EC-067 | `[x](#Setup)` vs heading `## setup` | Case-sensitivity decision (AMB-053) |
| EC-068 | `[x](#)` | Empty anchor — pass or fail |
| EC-069 | `[x](a.md#)` | Empty anchor on a cross-file link |
| EC-070 | `[x](a.md#a#b)` | Fragment splitting |
| EC-071 | `[x](#setup )` (trailing space in fragment) | Trimmed |
| EC-072 | `[x](notes.txt#section)` where the txt exists | Anchor check skipped |
| EC-073 | `[x](src/main.rs#L42-L50)` | Line-range anchor special-cased |
| EC-074 | `[x](ignored.md#setup)` where `ignored.md` is `--ignore`d and *does* contain `## Setup` | **Must pass** (AMB-063) — highest-risk false positive |
| EC-075 | `README.md` containing `[x](#setup)`, `[x](README.md#setup)`, `[x](./README.md#setup)` | All three identical |
| EC-076 | `[x](../outside-scan-root/a.md#heading)` | Is the out-of-scope file parsed for headings? |

## External URLs (R2c)

| ID | Input | Unstated expected behavior |
|---|---|---|
| EC-077 | `https://example.com/ok` returning 200 to HEAD, `--online` | Pass |
| EC-078 | Server returning **405** to HEAD, 200 to GET | Fallback → pass (stated) |
| EC-079 | Server returning **403** to HEAD, 200 to GET | Fallback set (AMB-030) — most common real case |
| EC-080 | Server returning **501** or **400** to HEAD | Fallback or fail |
| EC-081 | URL returning **500** | Failure or warning (AMB-036) |
| EC-082 | URL returning **429** | Retry/backoff vs. immediate failure |
| EC-083 | URL returning **401** / **403** on both HEAD and GET | Broken or auth-required |
| EC-084 | URL that hangs 30s | 10s timeout enforced; per-attempt vs. per-URL |
| EC-085 | Redirect chain of 12 hops | Max-hop enforcement |
| EC-086 | `https://a → http://a` downgrade redirect | Allowed, warned, or failed |
| EC-087 | Self-signed / expired certificate | `tls-error` classification |
| EC-088 | Unresolvable host (`https://nx-domain-xyz.invalid`) | `dns-failure` reason |
| EC-089 | `http://localhost:3000/docs` | Skipped or failed in CI |
| EC-090 | `https://example.com/x` appearing in 50 files | One fetch, 50 reports |
| EC-091 | Same URL, `--allow https://example.com` | Skipped |
| EC-092 | `--allow https://example.com` and the link is `https://example.com.evil.tld/x` | Naive-prefix hazard |
| EC-093 | **Without** `--online`: `htp://typo.com`, `https://`, `https://exam ple.com`, `https://xn--caf-dma.com` | Which are syntax failures; exit 1 or 2 (AMB-048) |
| EC-094 | `mailto:a@b.com`, `ftp://x/y`, `tel:+15551234`, `data:text/plain;base64,AA==`, `javascript:void(0)`, `vscode://x`, `//example.com/x` (protocol-relative) | **R2 enumerates only 3 link kinds; a 4th kind has no defined behavior.** Silently skipped is the presumed intent but is unstated for every one of these |

## Parsing scope (R3, R4)

| ID | Input | Unstated expected behavior |
|---|---|---|
| EC-095 | `[text][ref]` with `[ref]: docs/a.md` defined at EOF | Pass |
| EC-096 | `[text][nope]` — label never defined | New failure class (AMB-070) |
| EC-097 | `[ref]: missing.md` defined but never referenced | Reported or not |
| EC-098 | `[REF]` referencing `[ref]: a.md` | Case-insensitive label match |
| EC-099 | `[ref]` shortcut form and `[ref][]` collapsed form | In scope |
| EC-100 | Duplicate `[ref]:` definitions with different targets | First wins (CommonMark) |
| EC-101 | `![alt][imgref]` reference-style image | In scope |
| EC-102 | Inline code span `` `[x](missing.md)` `` | Ignored — **this is exactly BRIEF.md lines 18-19** (BV-013) |
| EC-103 | Double-backtick span containing a backtick: ``` ``[x](`a.md)`` ``` | Ignored |
| EC-104 | Fenced ```` ``` ```` block containing links | Ignored |
| EC-105 | `~~~`-fenced block containing links | Ignored |
| EC-106 | **4-space indented** code block containing links | Unstated (AMB-071) — likely false-positive source |
| EC-107 | Fence with a longer closing marker, or a nested fence inside a fence | Correct fence pairing |
| EC-108 | Fence opened and never closed at EOF | Remainder treated as code |
| EC-109 | Fence indented inside a list item or blockquote | Still a fence |
| EC-110 | `<!-- [x](missing.md) -->` HTML comment | Unstated (AMB-071) |
| EC-111 | `<pre>[x](missing.md)</pre>` | Unstated |
| EC-112 | `\[escaped\](missing.md)` | Not a link |
| EC-113 | Link inside a GFM table cell | Checked |
| EC-114 | Table cell with an escaped pipe in the destination: `[x](a\|b.md)` | Correct destination extraction |
| EC-115 | Link inside a blockquote, and inside a nested list | Checked |
| EC-116 | `<https://example.com>` autolink | In scope as an external URL? |
| EC-117 | Bare `https://example.com` in prose (GFM literal autolink) | In scope? |
| EC-118 | `<a href="missing.md">x</a>` raw HTML link | Out of scope per non-goals — confirm and document as a known false-negative |
| EC-119 | `<img src="missing.png">` | Same |
| EC-120 | Footnote `[^1]` + definition `[^1]: text` | Must not be treated as a reference link |
| EC-121 | Link whose destination wraps to the next source line | Which line number is reported |
| EC-122 | Nested brackets in link text: `[a [b] c](a.md)` | Correct parse |
| EC-123 | Two broken links on the same source line | Two findings; column disambiguation (or lack of it) |

## Flags, output, exit codes (R5, R6, R7)

| ID | Input | Unstated expected behavior |
|---|---|---|
| EC-124 | `--ignore 'docs/**'` vs `--ignore docs` vs `--ignore 'docs/'` | Glob dialect and directory semantics |
| EC-125 | `--ignore '*.md'` (would exclude everything) | Exit 0 or a warning |
| EC-126 | `--ignore README.md README.md` (ignored file passed explicitly) | Precedence |
| EC-127 | `--ignore a.md --ignore b.md` (repeated) | Both applied |
| EC-128 | `--ignore '!keep.md'` (negation) | Supported or literal |
| EC-129 | `--allow HTTPS://EXAMPLE.COM` vs link `https://example.com/x` | Case normalization |
| EC-130 | `--allow example.com` (no scheme) | Matches or not |
| EC-131 | `--allow` in default offline mode | Does it also suppress syntax validation |
| EC-132 | `--format xml` | Exit 2 |
| EC-133 | `--format json` with zero broken links | `[]` vs. no output |
| EC-134 | `--format json` with one broken link of each reason type | Full schema coverage — the golden-file anchor |
| EC-135 | `--format json` piped to a file while diagnostics occur | stdout purity |
| EC-136 | `--format json --format text` | Last-wins or error |
| EC-137 | `--unknown-flag` | Exit 2 |
| EC-138 | `--help`, `--version` | Exit code (R7 has no slot) |
| EC-139 | `mdlinkcheck -- -weird-name.md` | End-of-flags separator |
| EC-140 | `mdlinkcheck docs --format json` (flag after positional) | Accepted or not |
| EC-141 | Run with **one broken link and one unreadable file** | **Exit 1 or 2** (BV-005) — highest-value single test |
| EC-142 | Run where the only problem is an unreadable file | Exit 2 |
| EC-143 | Run with only warnings (5xx, 429, skipped private IP) | Exit 0 or 1 |
| EC-144 | Output piped to a non-TTY | Color suppressed |
| EC-145 | `NO_COLOR=1` set | Color suppressed |
| EC-146 | SIGINT mid-scan | Exit code; partial output |
| EC-147 | Two runs over the same 500-file corpus, parallel scanning enabled | **Byte-identical output** (BV-015) |
| EC-148 | `mdlinkcheck BRIEF.md` on this repo, today | **Must exit 0** (BV-013) |

---

## Recommended resolution path (brief is frozen — do not edit BRIEF.md)

1. **Do not add any of the above to BRIEF.md.** It is 440 tokens and correctly sized.
   Adding the AMB/EC content would create a 6,000-token pseudo-PRD and defeat the
   context-engineering purpose of an L1 artifact.
2. **Copy the brief to `.factory/specs/product-brief.md`** with canonical frontmatter (per
   `artifact-detection.md` Step 1b). Add **only** an `## Assumptions` appendix in the copy
   recording the human decisions from the open-questions list below — each as `ASM-NNN`,
   one line each. Budget: ≤150 additional tokens.
3. **Route AMB-001..AMB-071 to the business-analyst** as the L2 domain-spec decision queue
   (they are domain invariants and assumptions, not yet contracts).
4. **Route EC-001..EC-148 to the product-owner** as the seed for
   `prd-supplements/test-vectors.md` and `prd-supplements/error-taxonomy.md`.
5. **Reserve EC-036, EC-049, EC-074, EC-079, EC-093, EC-094, EC-102, EC-141, EC-147, EC-148
   for holdout scenarios** — do not let them appear in the visible test vectors. These are
   the cases most likely to be silently wrong, so they carry the most holdout signal.
6. **Escalate the 12 numbered questions below** marked `[HUMAN]` before Phase 1 begins;
   the `[PO]` items can be resolved during L3 authoring without blocking.

---

## Overall: VALID | NEEDS_WORK | INCOMPLETE | OVER_SPECIFIED

**Verdict: NEEDS_WORK**

Not `INCOMPLETE` (the brief is substantive, 301 words, no placeholders) and not
`OVER_SPECIFIED` (440 tokens, zero density violations, zero bloat). `NEEDS_WORK` reflects
one **FAIL** (missing Constraints & Integration Points), two **WEAK** sections (Users,
Success Criteria), and five **CRITICAL** gaps that block behavioral-contract authoring
(BV-001..BV-005).

**Recommended pipeline action:** proceed to Phase 1 spec crystallization, but resolve the
`[HUMAN]` open questions first — items 1, 2, 4, 5, 8, and 12 below each change the shape of
the domain model, and discovering them mid-Phase-1 costs an adversarial pass.

---

## BRIEF_VALIDATION: PASS_WITH_GAPS

The brief is authoritative, well-formed, correctly sized, and sufficient to **enter** Phase 1.
It is **not** sufficient to author falsifiable behavioral contracts without the decisions
below. 19 gaps (5 CRITICAL, 4 HIGH, 7 MEDIUM, 4 LOW), 71 enumerated ambiguities, 148
enumerated edge cases. Zero bloat findings. Zero density findings.

### Open questions requiring a decision

Marked `[HUMAN]` (product/scope/environment call the factory must not make autonomously) or
`[PO]` (resolvable deterministically during L3 authoring, but must be recorded as a decision).

1. **[HUMAN] Target platform matrix.** macOS, Linux, Windows? This decides EC-016, EC-036,
   EC-037, EC-042 and the entire path-handling model. *(BV-006, BV-016)*
2. **[HUMAN] Path case sensitivity and Unicode normalization.** Should `[x](README.MD)`
   resolving `README.md` pass on macOS? Recommendation: **no** — always compare
   case-sensitively against real directory entries and NFC-normalize, so results are
   identical on every OS. This is the brief's "deterministic" promise made concrete.
   *(BV-006, EC-036, EC-037)*
3. **[PO] Markdown grammar to pin.** Recommendation: CommonMark 0.31.2 + GFM, AST-based
   parsing (not regex), named explicitly in the PRD. *(BV-001)*
4. **[HUMAN] Slug algorithm authority.** Pin `github-slugger` v2.0.0 and **extend** the
   factory's `dclaude:github-slug-reference` skill, which is currently silent on
   duplicate-heading counters, underscore retention, and Unicode/normalization — all three
   of which this product needs. Should that skill be updated as part of this pilot?
   *(BV-002, AMB-052, AMB-054, AMB-055)*
5. **[HUMAN] Is a 5xx / 429 / timeout a broken link or a warning?** The brief's own
   anti-false-positive premise argues for **warning** (exit 0), but that means a genuinely
   dead site behind a broken server is not caught. This is a product-philosophy call, not a
   technical one. *(BV-005, AMB-036, EC-081, EC-082, EC-143)*
6. **[PO] Exit-code precedence and fail-fast policy.** Broken link (1) + I/O error (2) in the
   same run — which wins? Does one unreadable file among 500 abort the run? Recommendation:
   2 wins; do **not** abort — report per-file and continue. *(BV-005, EC-141, EC-142)*
7. **[PO] Does `--ignore` exclude files as anchor *targets* as well as scan *sources*?**
   Recommendation: sources only. Excluding targets manufactures false positives.
   *(AMB-063, EC-074)*
8. **[HUMAN] HTML anchor carve-out.** "No HTML parsing" (non-goal) vs. real-world
   `<a name="x">` / `<h2 id="x">` anchors. Accept the false-positive class, or grant a narrow
   `id`/`name`-attribute-extraction exception? *(BV-008, EC-062, EC-063)*
9. **[PO] Behavior for non-http(s) schemes** (`mailto:`, `ftp:`, `tel:`, `data:`,
   protocol-relative `//host/path`) and for the **fourth and fifth link forms** not
   enumerated in R2/R3 (CommonMark autolinks, GFM literal autolinks). Recommendation: skip
   non-http(s) schemes silently; include both autolink forms as external URLs.
   *(AMB-094 group, EC-094, EC-116, EC-117)*
10. **[PO] What exactly does "syntax-validated but not fetched" mean, and does a syntax
    failure exit 1 or 2?** Recommendation: WHATWG URL parse; failure is a broken link (exit
    1) with a `malformed-url` reason. *(AMB-048, EC-093)*
11. **[PO] Canonical JSON schema and closed failure-reason taxonomy.** Required before any
    golden-file test can exist. Include a `schema_version` field. *(BV-004, EC-134)*
12. **[HUMAN] R8 measurement contract.** Name the reference hardware (or a CI runner spec),
    define the 500-file corpus shape, fix the build profile, the thread count, the cache
    state, the statistic (recommend p95 over 10 runs), and the harness (recommend
    `hyperfine`). Without this R8 cannot become a verification property. *(BV-003)*
13. **[HUMAN] Acceptance corpus ownership.** Where does it live, who authors it, how many
    planted breaks per failure class, how many valid-link traps per false-positive class?
    Recommendation: make it a first-class story with an expected-classification manifest.
    *(BV-007)*
14. **[PO] Output ordering invariant.** Parallel scanning is required by R8; deterministic
    output is required by the Problem statement. Recommendation: sort by (path, line, column)
    before emission. *(BV-015, EC-147)*
15. **[HUMAN] Does the repo get a `README.md`?** A stated success criterion references one
    and it does not exist. Create it, or restate the criterion against `BRIEF.md`.
    *(BV-012, EC-148)*
16. **[HUMAN] Inline suppression directive** (`<!-- mdlinkcheck-disable-next-line -->`) — in
    or out? It does not violate the "no config file" non-goal, and without it every exception
    becomes CLI flag sprawl. *(BV-009)*
17. **[PO] `--ignore` glob dialect and `--allow` prefix-matching semantics**, including the
    `--allow https://example.com` / `https://example.com.evil.tld` prefix hazard.
    *(EC-124..EC-131)*
18. **[PO] Color / TTY / `NO_COLOR` behavior and the stdout-vs-stderr contract.**
    *(BV-010, BV-018, EC-135, EC-144, EC-145)*
19. **[HUMAN] Prior-art / differentiation statement.** Record explicitly that this is a
    factory pilot on a deliberately well-understood problem shape and that differentiation
    vs. `lychee` et al. is out of scope — otherwise a downstream agent will invent scope.
    *(BV-011)*
