---
document_type: epic-decomposition
level: L2-stories
version: "1.0"
status: draft
producer: vsdd-factory:story-writer
timestamp: 2026-08-10T00:00:00Z
phase: 2a
inputs:
  - .factory/specs/prd.md
  - .factory/specs/behavioral-contracts/BC-INDEX.md
  - .factory/specs/architecture/ARCH-INDEX.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/bc-module-map.md
  - .factory/specs/architecture/purity-boundary-map.md
total_bcs: 66
total_p0: 53
total_p1: 13
epics: 7
estimated_stories: 24
---

# Epics: mdlinkcheck

> **BC coverage guarantee:** All 66 BCs from BC-INDEX.md v1.7 are assigned to exactly one
> epic below. See the Reconciliation Table at the end of this file.

---

## Epic Overview

| Epic ID  | Name | BCs | P0 | P1 | Est. Stories |
|----------|------|-----|----|----|--------------|
| EPIC-01  | File Discovery and Scanning Pipeline | 13 | 10 | 3 | 4 |
| EPIC-02  | Link Extraction and Code Context Exclusion | 9 | 8 | 1 | 3 |
| EPIC-03  | Anchor Checking | 9 | 7 | 2 | 4 |
| EPIC-04  | Relative File Link Resolution | 8 | 6 | 2 | 3 |
| EPIC-05  | External URL Checking | 12 | 11 | 1 | 4 |
| EPIC-06  | Filter Application | 4 | 3 | 1 | 2 |
| EPIC-07  | Output, Reporting, and Exit Codes | 11 | 8 | 3 | 4 |
| **Total** | — | **66** | **53** | **13** | **24** |

---

## Epic: File Discovery and Scanning Pipeline

- **Goal:** A user can point `mdlinkcheck` at a directory (or an explicit list of paths) and
  the tool discovers every `.md` file that should be scanned, parses each into a pulldown-cmark
  event stream with byte-offset line numbers, and handles traversal edge cases (`.gitignore`
  exclusion, dot-directory skipping, symlinks, overlapping PATH arguments) without crashing or
  scanning the wrong set of files. This is the prerequisite for all downstream processing.
- **BCs:**
  - BC-2.01.001 (P0), BC-2.01.002 (P0), BC-2.01.003 (P0), BC-2.01.004 (P0),
    BC-2.01.005 (P0), BC-2.01.006 (P1), BC-2.01.007 (P1), BC-2.01.008 (P0),
    BC-2.01.009 (P0),
  - BC-2.02.001 (P0), BC-2.02.002 (P0), BC-2.02.003 (P0), BC-2.02.004 (P1)
- **P0/P1 split:** 10 P0 / 3 P1
- **Subsystems touched:** SS-01 File Discovery, SS-02 Markdown Parsing
- **Implementing modules:**
  - `scanner` (effectful shell — `mdlinkcheck` crate) — primary for all 13 BCs
  - `link_extractor` (pure core — `mdlinkcheck-core` crate) — secondary for BC-2.02.001
    (processes the pulldown-cmark event stream that scanner produces)
- **Pure/Effectful note:** This epic is predominantly effectful (`scanner` does all filesystem I/O
  and stream parsing). The downstream handoff to pure core begins when scanner emits `ParsedFile`.
- **Estimated stories:** 4

---

## Epic: Link Extraction and Code Context Exclusion

- **Goal:** Given a pulldown-cmark event stream, all link and image destinations are extracted
  with their source locations and kind (inline, reference, image), while links inside fenced code
  blocks, indented code blocks, inline code spans, and HTML comments are correctly excluded.
  Undefined reference labels produce a `broken` verdict. Non-http(s) schemes yield `clean`
  without further processing.
- **BCs:**
  - BC-2.03.001 (P0), BC-2.03.002 (P0), BC-2.03.003 (P0), BC-2.03.004 (P0),
    BC-2.03.005 (P0), BC-2.03.006 (P1),
  - BC-2.04.001 (P0), BC-2.04.002 (P0), BC-2.04.003 (P0)
- **P0/P1 split:** 8 P0 / 1 P1
- **Subsystems touched:** SS-03 Link Extraction, SS-04 Code Context Exclusion
- **Implementing modules:**
  - `link_extractor` (pure core — `mdlinkcheck-core` crate) — primary for all 9 BCs
  - `anchor_table` (pure core) — secondary for BC-2.04.003 (ATX headings inside fenced
    blocks must not be added to the anchor table)
  - `url_classifier` (pure core) — secondary for BC-2.03.005 (non-http scheme → clean verdict)
- **Pure/Effectful note:** This epic is entirely pure core. No I/O touches these modules.
- **Estimated stories:** 3

---

## Epic: Anchor Checking

- **Goal:** Users get correct heading-anchor verification on by default — mdlinkcheck's headline
  differentiator (KD-001). This epic delivers: the three-phase design that ensures the full
  anchor table is built before any link resolution; the github-slugger v2 clean-room slug
  algorithm with duplicate-counter; HTML `id=`/`name=` extraction; and fragment lookup for both
  same-file (`#heading`) and cross-file (`path.md#heading`) anchor links. Links to ignored source
  files with anchors resolve correctly.
- **BCs:**
  - BC-2.05.001 (P0), BC-2.05.002 (P0), BC-2.05.003 (P1),
  - BC-2.06.001 (P0), BC-2.06.002 (P0),
  - BC-2.08.001 (P0), BC-2.08.002 (P0), BC-2.08.003 (P0), BC-2.08.004 (P1)
- **P0/P1 split:** 7 P0 / 2 P1
- **Subsystems touched:** SS-05 Anchor Table Construction, SS-06 Heading Slug Computation,
  SS-08 Anchor Resolution
- **Implementing modules:**
  - `anchor_table` (pure core — `mdlinkcheck-core` crate) — primary for BC-2.05.001–003
  - `slug` (pure core — `mdlinkcheck-core` crate) — primary for BC-2.06.001–002; secondary
    for BC-2.05.002 (heading extraction requires slug computation to build anchor keys)
  - `anchor_resolver` (pure core — `mdlinkcheck-core` crate) — primary for
    BC-2.08.001–002, BC-2.08.004
  - `fragment` (pure core — `mdlinkcheck-core` crate) — primary for BC-2.08.003 (fragment
    split at first unescaped `#`)
  - `app` (effectful shell — `mdlinkcheck` crate) — secondary for BC-2.05.001 (three-phase
    pipeline orchestration that ensures Pass 1 anchor tables are complete before Pass 2)
- **Pure/Effectful note:** This epic mixes pure-core computation (slug, anchor_table,
  anchor_resolver, fragment) with the effectful-shell pipeline design (app orchestrating
  Pass 1 → Pass 1.5 → Pass 2). Stories must call this out explicitly.
- **Gene transfusion note:** `slug::compute` is a clean-room reimplementation of the
  github-slugger v2 algorithm per gene-transfusion-assessment.md §1 (ADR-008). The story
  covering BC-2.06.001–002 must use `implementation_strategy: gene-transfusion`.
- **Estimated stories:** 4

---

## Epic: Relative File Link Resolution

- **Goal:** File-path link destinations are resolved against the source file's directory with
  exact-case NFC comparison (no filesystem delegation on macOS APFS), percent-encoding handled
  before comparison, git-repo-root anchoring for root-relative links, and correct verdicts for
  edge cases (destination-is-directory, non-Markdown target, empty destination, trailing slash on
  a regular file). This delivers KD-004 (case-correct path resolution).
- **BCs:**
  - BC-2.07.001 (P0), BC-2.07.002 (P1), BC-2.07.003 (P0), BC-2.07.004 (P1),
    BC-2.07.005 (P0), BC-2.07.006 (P0), BC-2.07.007 (P0), BC-2.07.008 (P0)
- **P0/P1 split:** 6 P0 / 2 P1
- **Subsystems touched:** SS-07 Relative Path Resolution
- **Implementing modules:**
  - `path_resolver` (pure core — `mdlinkcheck-core` crate) — primary for BC-2.07.001,
    BC-2.07.003, BC-2.07.005–006, BC-2.07.008; secondary for BC-2.07.004
  - `fragment` (pure core — `mdlinkcheck-core` crate) — primary for BC-2.07.004
    (percent-encoding in file path destinations); secondary for BC-2.07.003
  - `url_classifier` (pure core — `mdlinkcheck-core` crate) — primary for BC-2.07.007
    (empty link destination → Malformed URL classification)
  - `anchor_resolver` (pure core — `mdlinkcheck-core` crate) — secondary for BC-2.07.005
    and BC-2.07.006 (must NOT be called for directory targets or non-Markdown targets)
  - `app` (effectful shell — `mdlinkcheck` crate) — Pass 1.5 builds the `DirIndex`
    (HashMap<PathBuf, Vec<DirEntryInfo>>) that `path_resolver` consumes; stories must
    include the Pass 1.5 data-product story
- **Pure/Effectful note:** This epic is entirely pure-core computation, but depends on the
  `DirIndex` data product built by the effectful Pass 1.5 phase (story in EPIC-01 or a shared
  infrastructure story).
- **Estimated stories:** 3

---

## Epic: External URL Checking

- **Goal:** External HTTP/HTTPS URLs are validated offline (syntax check only, by default) and
  optionally verified live via `--online` mode with HEAD-then-GET fallback, three-verdict model
  (alive/broken/indeterminate), 10-second per-URL timeout, 429 rate-limit backoff,
  32-global/4-per-host concurrency, URL deduplication, and correct handling of DNS failure,
  TLS failure, redirect chains (max 10), and private/link-local IP classification. This delivers
  KD-002 (offline-by-default) and KD-005 (deterministic exit codes for indeterminate conditions).
- **BCs:**
  - BC-2.09.001 (P0), BC-2.09.002 (P0),
  - BC-2.10.001 (P0), BC-2.10.002 (P0), BC-2.10.003 (P0), BC-2.10.004 (P0),
    BC-2.10.005 (P0), BC-2.10.006 (P0), BC-2.10.007 (P0), BC-2.10.008 (P1),
    BC-2.10.009 (P0), BC-2.10.010 (P0)
- **P0/P1 split:** 11 P0 / 1 P1
- **Subsystems touched:** SS-09 External URL Syntax Validation, SS-10 External URL Liveness
  Checking
- **Implementing modules:**
  - `url_classifier` (pure core — `mdlinkcheck-core` crate) — primary for BC-2.09.001
  - `filter` (pure core — `mdlinkcheck-core` crate) — primary for BC-2.09.002 (`--allow`
    exemption; url_classifier is secondary)
  - `http_client` (effectful shell — `mdlinkcheck` crate) — primary for BC-2.10.001,
    BC-2.10.003–004, BC-2.10.007–010
  - `http_verdict` (pure core — `mdlinkcheck-core` crate) — primary for BC-2.10.002,
    BC-2.10.005–006; secondary for BC-2.10.001, BC-2.10.004, BC-2.10.010
- **Pure/Effectful note:** This epic spans the pure/effectful seam: `http_verdict` is pure core
  (classifies response codes and failure modes), while `http_client` is effectful shell (issues
  network requests, manages the memo table for URL deduplication, owns per-host semaphores and
  429-pause state). Stories must explicitly call out which module owns each BC.
- **Estimated stories:** 4

---

## Epic: Filter Application

- **Goal:** Users can exclude source files from link reporting with `--ignore` globs (while still
  building anchor tables for ignored files), exempt URL prefixes from external checks with
  `--allow`, and receive an early exit-2 when an `--ignore` glob is syntactically invalid. The
  `--ignore` filter applies to explicit PATH arguments as well as discovered files.
- **BCs:**
  - BC-2.11.001 (P0), BC-2.11.002 (P0), BC-2.11.003 (P1), BC-2.11.004 (P0)
- **P0/P1 split:** 3 P0 / 1 P1
- **Subsystems touched:** SS-11 Filter Application
- **Implementing modules:**
  - `filter` (pure core — `mdlinkcheck-core` crate) — primary for BC-2.11.001–003
  - `scanner` (effectful shell — `mdlinkcheck` crate) — secondary for BC-2.11.001 and
    BC-2.11.003 (applies glob patterns during traversal; still reads ignored files for anchor
    tables per DI-006)
  - `cli` (effectful shell — `mdlinkcheck` crate) — primary for BC-2.11.004 (validates
    `--ignore` glob syntax at startup)
  - `verdict` (pure core — `mdlinkcheck-core` crate) — secondary for BC-2.11.004
    (config_error=true → exit 2 via verdict::exit_code)
- **Pure/Effectful note:** This epic mixes pure-core filter logic with effectful CLI validation
  and scanner integration. BC-2.11.004 specifically routes through the
  cli → verdict::exit_code(config_error: bool) path established in module-decomposition v1.2.
- **Estimated stories:** 2

---

## Epic: Output, Reporting, and Exit Codes

- **Goal:** Results are emitted deterministically: text format to stdout with one finding per
  line in NFC path / line / col / link_target sort order; a stderr summary line always emitted;
  JSON format to stdout with `{"schema_version":1,"results":[...],"errors":[]}`; terminal color
  controlled by NO_COLOR/CLICOLOR/CLICOLOR_FORCE; exit code 0 (no broken links), 1 (broken
  links found), or 2 (usage error, takes precedence over 1). `--help` and `--version` exit 0
  without scanning. This delivers KD-003 (source-level file:line reporting) and KD-005
  (deterministic exit codes).
- **BCs:**
  - BC-2.12.001 (P0), BC-2.12.002 (P1), BC-2.12.003 (P0), BC-2.12.004 (P1),
    BC-2.12.005 (P0),
  - BC-2.13.001 (P0), BC-2.13.002 (P1),
  - BC-2.14.001 (P0), BC-2.14.002 (P0), BC-2.14.003 (P0), BC-2.14.004 (P0)
- **P0/P1 split:** 8 P0 / 3 P1
- **Subsystems touched:** SS-12 Text Report Generation, SS-13 JSON Report Generation,
  SS-14 Exit Code Determination
- **Implementing modules:**
  - `reporter` (pure core — `mdlinkcheck-core` crate) — primary for BC-2.12.001–003,
    BC-2.12.005, BC-2.13.001–002; secondary for BC-2.12.004
  - `cli` (effectful shell — `mdlinkcheck` crate) — primary for BC-2.12.004 and
    BC-2.14.004; secondary for BC-2.12.002 (reads NO_COLOR / CLICOLOR env vars,
    produces CliArgs flag for reporter)
  - `verdict` (pure core — `mdlinkcheck-core` crate) — primary for BC-2.14.001–003
  - `main` (effectful shell — `mdlinkcheck` crate) — secondary for BC-2.12.003 and
    BC-2.12.005 (routes reporter output: findings → stdout, summary → stderr)
- **Pure/Effectful note:** This epic mixes pure-core formatting (reporter, verdict) with
  effectful shell I/O routing (main writes to stdout/stderr) and CLI argument parsing (cli).
  The stdout/stderr separation invariant (BC-2.12.005) must be enforced at the main level.
- **Estimated stories:** 4

---

## BC Reconciliation Table

> Every BC appears in exactly one epic. Verify: count per column = total in epic header;
> grand total = 66.

| BC ID | Priority | Epic |
|-------|----------|------|
| BC-2.01.001 | P0 | EPIC-01 |
| BC-2.01.002 | P0 | EPIC-01 |
| BC-2.01.003 | P0 | EPIC-01 |
| BC-2.01.004 | P0 | EPIC-01 |
| BC-2.01.005 | P0 | EPIC-01 |
| BC-2.01.006 | P1 | EPIC-01 |
| BC-2.01.007 | P1 | EPIC-01 |
| BC-2.01.008 | P0 | EPIC-01 |
| BC-2.01.009 | P0 | EPIC-01 |
| BC-2.02.001 | P0 | EPIC-01 |
| BC-2.02.002 | P0 | EPIC-01 |
| BC-2.02.003 | P0 | EPIC-01 |
| BC-2.02.004 | P1 | EPIC-01 |
| BC-2.03.001 | P0 | EPIC-02 |
| BC-2.03.002 | P0 | EPIC-02 |
| BC-2.03.003 | P0 | EPIC-02 |
| BC-2.03.004 | P0 | EPIC-02 |
| BC-2.03.005 | P0 | EPIC-02 |
| BC-2.03.006 | P1 | EPIC-02 |
| BC-2.04.001 | P0 | EPIC-02 |
| BC-2.04.002 | P0 | EPIC-02 |
| BC-2.04.003 | P0 | EPIC-02 |
| BC-2.05.001 | P0 | EPIC-03 |
| BC-2.05.002 | P0 | EPIC-03 |
| BC-2.05.003 | P1 | EPIC-03 |
| BC-2.06.001 | P0 | EPIC-03 |
| BC-2.06.002 | P0 | EPIC-03 |
| BC-2.07.001 | P0 | EPIC-04 |
| BC-2.07.002 | P1 | EPIC-04 |
| BC-2.07.003 | P0 | EPIC-04 |
| BC-2.07.004 | P1 | EPIC-04 |
| BC-2.07.005 | P0 | EPIC-04 |
| BC-2.07.006 | P0 | EPIC-04 |
| BC-2.07.007 | P0 | EPIC-04 |
| BC-2.07.008 | P0 | EPIC-04 |
| BC-2.08.001 | P0 | EPIC-03 |
| BC-2.08.002 | P0 | EPIC-03 |
| BC-2.08.003 | P0 | EPIC-03 |
| BC-2.08.004 | P1 | EPIC-03 |
| BC-2.09.001 | P0 | EPIC-05 |
| BC-2.09.002 | P0 | EPIC-05 |
| BC-2.10.001 | P0 | EPIC-05 |
| BC-2.10.002 | P0 | EPIC-05 |
| BC-2.10.003 | P0 | EPIC-05 |
| BC-2.10.004 | P0 | EPIC-05 |
| BC-2.10.005 | P0 | EPIC-05 |
| BC-2.10.006 | P0 | EPIC-05 |
| BC-2.10.007 | P0 | EPIC-05 |
| BC-2.10.008 | P1 | EPIC-05 |
| BC-2.10.009 | P0 | EPIC-05 |
| BC-2.10.010 | P0 | EPIC-05 |
| BC-2.11.001 | P0 | EPIC-06 |
| BC-2.11.002 | P0 | EPIC-06 |
| BC-2.11.003 | P1 | EPIC-06 |
| BC-2.11.004 | P0 | EPIC-06 |
| BC-2.12.001 | P0 | EPIC-07 |
| BC-2.12.002 | P1 | EPIC-07 |
| BC-2.12.003 | P0 | EPIC-07 |
| BC-2.12.004 | P1 | EPIC-07 |
| BC-2.12.005 | P0 | EPIC-07 |
| BC-2.13.001 | P0 | EPIC-07 |
| BC-2.13.002 | P1 | EPIC-07 |
| BC-2.14.001 | P0 | EPIC-07 |
| BC-2.14.002 | P0 | EPIC-07 |
| BC-2.14.003 | P0 | EPIC-07 |
| BC-2.14.004 | P0 | EPIC-07 |

**Row count: 66. P0 rows: 53. P1 rows: 13.**

---

_Produced by vsdd-factory:story-writer (Phase 2 Step A). Next: Step B — decompose each epic
into individual STORY-NNN files under `.factory/stories/stories/`._
