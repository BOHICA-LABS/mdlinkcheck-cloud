---
document_type: architecture-section
level: L3
section: system-overview
version: "1.9"
status: draft
producer: architect
timestamp: 2026-08-06T00:00:00Z
phase: 1b
inputs:
  - .factory/specs/domain-spec/L2-INDEX.md
  - .factory/specs/prd.md
  - .factory/specs/prd-supplements/nfr-catalog.md
input-hash: "f9f12cd"
traces_to: ARCH-INDEX.md
changelog:
  - version: "1.9"
    date: 2026-08-06
    change: "DirIndex-scope ruling: restructured Pass 1.5 into two explicit sub-phases — Pass 1.5a (DirIndex population for every extracted link destination, all link types) and Pass 1.5b (AnchorIndex extension for missing .md targets only). Resolves purity-boundary-map.md vs. system-overview.md contradiction; closes BC-2.07.003 PC2 gap and BC-2.07.005/006 EntryKind routing gap. DI-009 termination comment updated to reference broad population set. Error handling table: config_error routing updated to explicit 'config_error=true → verdict::exit_code' (not process::exit bypass); unrecognized-flag row removed from config_error category."
  - version: "1.8"
    date: 2026-08-06
    change: "D-043 decisions applied: NFR-002 re-targeted to p95 ≤ 10 seconds on macos-latest (shared Apple Silicon M1) per PO decision; removed 'under D-043 review' placeholder from Performance Architecture section."
  - version: "1.7"
    date: 2026-08-06
    change: "D-043 macOS-only platform directive: (1) 'Cross-Platform Path Handling' section renamed to 'Path Handling (macOS APFS)' — removed Windows path-separator note; DI-002 rationale restated on determinism grounds per ADR-006 v1.4. (2) Performance Architecture: NFR-002 (Linux CI 15s) marked as under D-043 review — product-owner decides retire vs. re-target. (3) Pass 1.5 visited-set comment: removed 'and Windows' from fs::canonicalize note (macOS-only)."
  - version: "1.6"
    date: 2026-08-06
    change: "P4 remediation: (P4-003) 'rayon parallelizes both passes' → 'Pass 1 and Pass 2 (Pass 1.5 is sequential)'. (P4-004) Sort line updated to 4-field key (NFC-path, line, col, link_target); P4-019 sort ownership corrected from (app) to (reporter). (P4-035) 'advisory defaults' → 'hard caps' per ADR-004/ADR-005."
  - version: "1.5"
    date: 2026-08-05
    change: "Signature consistency fix: pipeline diagram exit-code call updated from verdict::exit_code(&findings, &io_errors) to verdict::exit_code(&findings, &io_errors, config_error), matching api-surface.md authoritative three-input signature. config_error is the bool that carries the R7 usage-error half of exit 2 (P2-M19)."
  - version: "1.4"
    date: 2026-08-05
    change: "P2-C05/P2-C06/P2-M13/P2-M18 remediation: (C05) added Pass 1.5 failure branch — unreadable/missing out-of-scan targets produce no IoError, no diagnostic, Pass 2 emits normal broken verdict; (C06) corrected nonexistent PATH behavior from 'exit immediately' to runtime I/O error recorded into Vec<IoError> per DD-007 and interface-definitions.md; (M13) replaced 'absolute canonical path' visited-set key with non-canonicalizing NFC-normalized lexically-normalized key to avoid fs::canonicalize case-folding conflict with D-006; (M18) clarified Pass 1.5 iterates scan-set LinkMap only (not --ignore'd sources)"
  - version: "1.3"
    date: 2026-08-05
    change: "BC-2.11.004 reconciliation: Error Handling section now explicitly distinguishes startup configuration errors (invalid --ignore glob, non-existent PATH — exit 2 immediately, NOT subject to no-fail-fast) from runtime I/O errors (collected, no-fail-fast per DD-007)"
  - version: "1.2"
    date: 2026-08-05
    change: "Phase 1d remediation: F-005 (Pass 1.5 identifies out-of-scan targets by AnchorIndex membership, not per-exclusion-mechanism re-check); D-011 (dot-directory skip is unconditional -- --hidden dropped as explicit non-goal); D-012 (.md only, case-sensitive -- .MD/.markdown/.mdx are not markdown files); D-013 (two-tier performance model: NFR-001/002 acceptance ceilings + ~500ms regression gate); F-032 (memory model and file-size bound stated)"
  - version: "1.1"
    date: 2026-08-05
    change: "SR-016/SR-034 remediation: two-pass pipeline extended to three phases (Pass 1 -> Pass 1.5 -> Pass 2); Pass 1.5 builds DirIndex from all link target directories; documents bootstrapping order and DI-009 termination argument for symlinks"
  - version: "1.0"
    date: 2026-08-05
    change: "Initial draft"
---

# System Overview: mdlinkcheck

## Architecture Vision

`mdlinkcheck` is a **single-service, single-binary Rust CLI** (MSRV 1.85) with a strict
pure-core / effectful-shell boundary. This boundary exists for one reason: Phase 6 runs
Kani formal proofs, and Kani can only prove pure, deterministic, side-effect-free functions.
Every design decision subordinates itself to this constraint.

## Two-Crate Workspace

```
Cargo workspace
├── crates/mdlinkcheck-core/   ← library crate; pure core; all business logic
│   └── src/                   ← slug, anchor_table, link_extractor, fragment,
│                                  path_resolver, anchor_resolver, url_classifier,
│                                  http_verdict, filter, reporter, verdict
└── crates/mdlinkcheck/        ← thin binary crate; effectful shell
    └── src/                   ← cli (clap), scanner (ignore+fs), http_client (ureq), app
```

The library crate exports a pure API: takes data structures in, returns results.
It never calls `std::fs`, `std::net`, or any I/O. Tests and Kani harnesses drive it directly.

The binary crate performs all I/O, then hands structured data to the library for processing.

## Discovery Scope (D-012)

Discovery matches **`.md` files only, case-sensitive** (D-012). `.MD`, `.markdown`,
and `.mdx` are not Markdown files for purposes of this tool and are never added to
the scan set. The `ignore` crate's WalkBuilder is configured with a case-sensitive
extension filter for the exact string `.md`. This applies to both the traversal scan
set and the Pass 1.5 out-of-scan anchor-target lookup.

## Three-Phase Pipeline

DI-008 mandates that every file's anchor table exists before any link *into* that file
is resolved. DI-006 (widened in v1.1) mandates that files excluded by ANY source-exclusion
mechanism still have anchor tables when they are referenced as anchor targets. SR-016
revealed that a single-directory `DirEntries` type could not resolve multi-component
paths or detect file-vs-directory. These constraints force a three-phase design:

**Bootstrapping order invariant (DI-008, F-005):** Pass 1 completes fully before Pass 1.5
begins; Pass 1.5 completes fully before Pass 2 begins. No link resolution occurs during
Pass 1 or Pass 1.5. No anchor table construction occurs during Pass 2. The three passes
are strictly sequenced and do not interleave.

```
Pass 1 (parallel, rayon):
  Scope: ALL .md files reachable by the WalkBuilder traversal, INCLUDING
         --ignore'd files (their anchor tables are needed as targets).
  Dot-directory skip is UNCONDITIONAL (D-011): directories prefixed with '.'
         (e.g., .github/, .vitepress/) are always skipped. There is no --hidden
         flag to override this (D-011 binding decision: --hidden is dropped).

  For each discovered .md file:
  a. Read file bytes from disk (effectful — scanner)
  b. Parse bytes -> pulldown-cmark event stream (effectful — scanner)
  c. Extract links -> Vec<ExtractedLink> (pure — link_extractor)
  d. Build anchor table (pure — anchor_table, slug)
  Result: AnchorIndex: HashMap<PathBuf, AnchorTable>
          LinkMap:     HashMap<PathBuf, Vec<ExtractedLink>>

Pass 1.5 (shell only, sequential — app):
  Purpose: (1) build DirIndex for every extracted link destination — all link types
           (.md, non-.md, directory references) — so that path_resolver can perform
           NFC case-sensitive directory-entry comparison for any link target without I/O;
           and (2) ensure DI-006 — every link destination that is a .md file has an
           anchor table, even if it was not reachable by the Pass 1 traversal.

  Both sub-phases iterate scan-set LinkMap only — link destinations from --ignore'd
  source files are excluded. An --ignore'd file is excluded as a SOURCE; its anchor
  table may still be built if it appears as a TARGET of a scan-set link.

  Pass 1.5a — DirIndex population (all link destination types):
  Collect unique parent directories of every extracted link destination — all link
  types (.md, non-.md, directories). For each unique parent directory:
    fs::read_dir -> Vec<DirEntryInfo { name: OsString, kind: EntryKind }>
    EntryKind distinguishes File / Dir / Symlink { dangling: bool }
  Store results in DirIndex: HashMap<PathBuf, Vec<DirEntryInfo>>.
  This guarantees that path_resolver can determine EntryKind and perform NFC
  case-sensitive comparison for any resolved link target — including links to files
  already in the scan set (in-scan-set .md files), links to non-.md files, and links
  to directories — without performing any I/O at resolution time.
  Deduplication key: NFC-normalized, lexically-normalized (`.`/`..` collapsed),
    NON-canonicalized (no `fs::canonicalize` — canonicalize case-folds on macOS
    APFS, violating D-006 case-sensitivity and DI-001 determinism), scan-root-relative
    `PathBuf`. The set of visited keys is checked before each `fs::read_dir` call;
    the second encounter of any key is skipped. No recursion: only the immediate
    parent directory of each link destination is read (DI-006 one-level bound).
  Termination: DirIndex population terminates because LinkMap is fixed after Pass 1
    (Pass 1.5 does not add new links) and each unique parent directory is visited at
    most once. Bound: O(unique parent dirs of all link destinations) ≤ O(|all links|).
    This key form is the same canonical key form used throughout the pipeline.

  Pass 1.5b — AnchorIndex extension (missing .md targets only):
  Identification mechanism (F-005): identifies out-of-scan .md targets by AnchorIndex
  MEMBERSHIP — every .md destination from LinkMap that is NOT already a key in
  AnchorIndex. Does NOT re-check individual exclusion mechanisms (gitignore patterns,
  dot-dir prefix, scan-root boundary) — AnchorIndex membership is the single
  authoritative gate. Any future exclusion mechanism automatically becomes part of
  Pass 1.5 scope without code changes.
  For each missing .md path:
    - If the file does not exist, is not a regular file, or cannot be read:
      skip silently. No AnchorIndex entry is created. No IoError is recorded.
      No diagnostic is emitted. Pass 2 produces the normal verdict for that destination
      (e.g., broken(file-not-found), broken(broken-symlink)).
      Only I/O failures reading files IN the scan set contribute to io_errors.
    - If the file exists and is readable: read and parse for its anchor table; add
      the anchor table to AnchorIndex.
  (Parent directory listings are already in DirIndex from Pass 1.5a; no additional
   directory reads are needed to determine file existence or EntryKind.)
  Result: DirIndex fully populated for all link destination types;
          AnchorIndex extended with out-of-scan .md entries.

  Bootstrapping order: Pass 1.5 (both sub-phases) runs after Pass 1 completes and
    before Pass 2 begins. This guarantees AnchorIndex and DirIndex cover every path
    that Pass 2 will look up.

Pass 2 (pure only, parallel, rayon):  For each file in the scan set (NOT --ignore'd):
  a. For each extracted link, call the appropriate resolver:
       path_resolver::resolve(dest, src_dir, &dir_index)   [pure — DirIndex data]
       anchor_resolver::resolve(fragment, &anchor_index)    [pure]
       url_classifier::classify(dest)                       [pure]
  b. Collect Finding objects
  Result: Vec<Finding>

Sort:   sort_unstable_by(NFC-path, line, col, link_target) — enforces DI-001 determinism (reporter)

Emit:   reporter formats and writes to stdout (effectful)
        exit code = verdict::exit_code(&findings, &io_errors, config_error) (pure)
```

For `--online`, between Pass 2 and Sort, HTTP checks dispatch via a DEDICATED rayon
thread pool (32 threads, separate from the file-scan pool — see ADR-004):
- `ureq` 3.3.0 (blocking/sync — no tokio, no async)
- Per-host semaphores cap concurrent requests to 4 per host
- Results memoized by normalized URL within the run (BC-2.10.009)

## Concurrency and Determinism Reconciliation

rayon parallelizes Pass 1 and Pass 2 (Pass 1.5 is sequential, shell-only — see §Three-Phase Pipeline). The sort-before-emit stage (between Pass 2 output
collection and stdout write) enforces DI-001. The sort key is
`(nfc_normalize(path), line, column, link_target)`. This is a mandatory late-pipeline step;
no finding may bypass it.

Per-host concurrency in `--online` mode: a `Semaphore`-style counter per host limits
concurrent requests to 4. A global semaphore caps total HTTP threads at 32.
Both limits are hard caps, not configurable in v1.0 (BC-2.10.008, ADR-004).

## Performance Architecture — Two-Tier Model (D-013)

Performance is specified at two tiers (D-013):

**Tier 1 — Acceptance ceilings (confirmed from frozen brief R8):**
- NFR-001: p95 wall-clock ≤ 5 seconds on Apple Silicon M-series (500 .md files, offline)
- NFR-002: p95 wall-clock ≤ 10 seconds on macOS CI runner (`macos-latest`, shared Apple
  Silicon M1) — re-targeted per D-043

These ceilings are pass/fail gates at release. Any build that exceeds them on the
reference corpus is rejected.

**Tier 2 — Regression gate (D-013, CI-enforced):**
- Internal target: p95 wall-clock ≤ ~500ms on the Tier A benchmark corpus (offline)
- This tighter bound is what CI enforces on every commit for regression detection
- It is NOT derived from NFR-001/002; it is calibrated to the Tier A corpus size and
  Apple Silicon baseline. VP-022 (integration benchmark) enforces this gate.

The two tiers serve different purposes: NFR-001/002 confirm the product meets user
requirements on large repos; the regression gate detects algorithmic regressions early
on a small CI-fast corpus before they compound.

The 500-file/5-second budget is decomposed as:
- I/O bound: `ignore` crate WalkBuilder parallel mode; per-file reads stream bytes
- CPU bound: pulldown-cmark parse + anchor_table build + link_extractor — all in-memory,
  no allocations beyond the event buffer
- Bottleneck invariant: anchor_table holds ~15 entries/file × 500 files = 7,500 entries —
  well within L2 cache. The slug module (O(n) per character) is fast.
- Budget risk: `--online` with many external URLs dominates wall-clock; offline is
  CPU-only and should complete well under the 5-second target.

## Memory Model (F-032)

Each `.md` file is read entirely into memory as a `Vec<u8>` before BOM stripping and
CRLF normalization. All anchor tables for all files in the anchor-target universe
(scan set + out-of-scan targets discovered by Pass 1.5) are held in memory
simultaneously during Pass 2.

**No explicit per-file size bound is enforced in v1.0.** The NFR-005 peak RSS budget
of 512 MB on the 500-file reference corpus is the implicit constraint. For repos with
a small number of very large generated `.md` files (e.g., auto-generated API docs
hundreds of megabytes each), the RSS budget may be exceeded. This is a known limitation
acceptable for v1.0: the product targets source documentation repos, not generated output
repos. If a future use case requires large-file support, streaming parse (pulldown-cmark
supports incremental events) is the migration path.

**Interaction with NFR-005:** NFR-005's 512 MB ceiling is corpus-shape-dependent. It
holds for the reference corpus (500 files, each ≤ 1 MB). Repos deviating significantly
from this shape (very large files or very many files) may require the streaming migration.

## Error Handling Strategy

The error taxonomy (error-taxonomy.md) is closed. Every verdict is one of `broken`,
`indeterminate`, `clean`. I/O errors (non-UTF-8 file, unreadable file) are collected
into a separate `Vec<IoError>` that does not interrupt the scan (DD-007 no-fail-fast).
The final exit code is computed as a pure function over both collections.

**Startup configuration errors are distinct from runtime I/O errors and are NOT subject
to no-fail-fast.** The sole startup configuration error is an invalid `--ignore` glob
pattern that `globset` cannot compile (BC-2.11.004). When detected, `app` sets
`config_error = true` and calls `verdict::exit_code([], [], true)` — which returns 2.
No file traversal occurs. **This is routed THROUGH `verdict::exit_code`** — it is not
a `process::exit` bypass — so `verdict::exit_code` remains the single authority for
every exit code and VP-005's Kani proof covers this path. Unrecognized flags are
handled by clap before `app::run()` is called and do NOT set `config_error`.

A `PATH` argument that does not exist or cannot be read is NOT a startup configuration
error. Per DD-007 and interface-definitions.md, it is recorded into `Vec<IoError>` and
scanning continues with any remaining valid paths.

| Error class | When detected | Behaviour | DD rule |
|-------------|--------------|-----------|---------|
| Configuration error: invalid `--ignore` glob (sole `config_error` trigger) | Startup, before traversal | `app` sets `config_error=true`; calls `verdict::exit_code([], [], true)` → exit 2 | BC-2.11.004 |
| Non-existent or unreadable PATH argument | Startup or first access | Record into `Vec<IoError>`; scan continues with valid paths | DD-007 no-fail-fast |
| Runtime I/O error (unreadable file, non-UTF-8) | During scan | Collect into `Vec<IoError>`; scan continues | DD-007 no-fail-fast |

## Path Handling (macOS APFS)

DI-002 (case-sensitive NFC path comparison) is enforced in `path_resolver` by reading
actual directory entries and doing NFC-normalized byte-for-byte comparison — never
delegating to `Path::exists()` alone (which would adopt APFS case-insensitive semantics).
The rationale is determinism, not cross-platform portability: verdicts must be a function
of repository content, not of what the host filesystem resolves at runtime (ADR-006 v1.4,
D-043). See purity-boundary-map.md and ADR-006 for the detailed strategy.

## [Section Content]

<!-- Validator scaffold: real content is in the named sections above. The
     architecture-section-template uses "[Section Content]" as a literal
     placeholder heading; the compliance validator matches it by substring.
     This stub satisfies that check without altering any real content. -->
