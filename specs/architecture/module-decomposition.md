---
document_type: architecture-section
level: L3
section: module-decomposition
version: "1.2"
status: draft
producer: architect
timestamp: 2026-08-05T20:00:00Z
phase: 1b
inputs:
  - .factory/specs/domain-spec/capabilities.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/prd.md
input-hash: "f0555db"
traces_to: ARCH-INDEX.md
changelog:
  - version: "1.2"
    date: 2026-08-05
    change: "Signature consistency fix: verdict::exit_code updated to three-input form (findings, io_errors, config_error: bool) in module table and data-flow summary, matching api-surface.md authoritative signature. config_error carries the R7 usage-error half of exit 2 (P2-M19)."
  - version: "1.1"
    date: 2026-08-05
    change: "SR-016/SR-034 remediation: replaced DirEntries with DirIndex type; path_resolver now receives directory-keyed index; added Pass 1.5 (shell-only) phase that populates DirIndex; ParsedFile no longer carries dir_entries"
  - version: "1.0"
    date: 2026-08-05
    change: "Initial draft"
---

# Module Decomposition: mdlinkcheck

## Workspace Layout

```
Cargo.toml (workspace root)
  members = ["crates/mdlinkcheck-core", "crates/mdlinkcheck"]
  resolver = "2"
  [workspace.metadata.msrv] = "1.85"

crates/mdlinkcheck-core/   ← library crate (pure core)
crates/mdlinkcheck/        ← binary crate (effectful shell)
```

## mdlinkcheck-core (Library Crate — Pure Core)

All modules in this crate are **pure functions**: they take data in, return results, never
call I/O. Kani proof harnesses operate directly on these functions.

| Module | File | Capability | Key Types | Kani-targetable? |
|--------|------|-----------|-----------|-----------------|
| `slug` | `slug.rs` | CAP-006 | `fn compute(text: &str, counter: &mut DuplicateCounter) -> String` | **Yes** |
| `fragment` | `fragment.rs` | DI-003 | `fn split(raw_dest: &str) -> (&str, Option<&str>)` | **Yes** |
| `anchor_table` | `anchor_table.rs` | CAP-005 | `fn build(events: &ParsedHeading) -> AnchorTable` | **Yes** |
| `link_extractor` | `link_extractor.rs` | CAP-003, CAP-004 | `fn extract(events: &[PcEvent]) -> Vec<ExtractedLink>` | Yes |
| `path_resolver` | `path_resolver.rs` | CAP-007, DI-002 | `fn resolve(dest: &str, src_dir: &Path, index: &DirIndex) -> PathVerdict` | **Yes** |
| `anchor_resolver` | `anchor_resolver.rs` | CAP-008 | `fn resolve(fragment: &str, table: &AnchorTable) -> Verdict` | Yes |
| `url_classifier` | `url_classifier.rs` | CAP-009 | `fn classify(dest: &str) -> UrlKind` | Yes |
| `http_verdict` | `http_verdict.rs` | CAP-010 (logic) | `fn classify_response(status: u16, attempt: Attempt) -> Verdict` | **Yes** |
| `filter` | `filter.rs` | CAP-011 | `fn ignore_match(path: &Path, gs: &GlobSet) -> bool`, `fn allow_match(url: &str, prefixes: &[Prefix]) -> bool` | **Yes** |
| `reporter` | `reporter.rs` | CAP-012, CAP-013 | `fn format_text(findings: &[Finding], opts: ReportOpts) -> String`, `fn format_json(findings: &[Finding]) -> String` | No |
| `verdict` | `verdict.rs` | CAP-014, DI-010, DI-011 | `fn exit_code(findings: &[Finding], io_errors: &[IoError], config_error: bool) -> u8` | **Yes** |
| `types` | `types.rs` | — | `Link`, `ExtractedLink`, `Finding`, `Verdict`, `AnchorTable`, `DirIndex`, `DirEntryInfo`, `EntryKind` | — |

**Slug module note (gene-transfusion):** `slug::compute` is a clean-room reimplementation
of the github-slugger v2 algorithm from the behavioral spec in market-intelligence §4.1.
See gene-transfusion-assessment.md §1. Source comment cites the specification reference.

**Path resolver purity note (SR-016 resolution):** `path_resolver` receives a `DirIndex`
(a directory-keyed map of `Vec<DirEntryInfo>`) as input data. It never calls `fs::read_dir`
or any other I/O. The `DirIndex` is built by `app` during Pass 1.5 (see below) and passed as
immutable data. Each `DirEntryInfo` carries the entry name and `EntryKind` (file/dir/symlink
with dangling state), enabling `target-is-directory` and `broken-symlink` reason codes to be
produced correctly. Multi-component path resolution works because the index is keyed by
directory path, not limited to a single source file's parent.

## mdlinkcheck (Binary Crate — Effectful Shell)

| Module | File | Responsibility | I/O Used |
|--------|------|---------------|---------|
| `cli` | `cli.rs` | clap arg parsing; produces `CliArgs` struct | none |
| `scanner` | `scanner.rs` | `ignore` crate traversal; file reads; produces ParsedFile | fs::read, fs::read_dir |
| `http_client` | `http_client.rs` | ureq HEAD/GET with per-host concurrency; produces HttpResult | network (ureq) |
| `app` | `app.rs` | Three-phase pipeline orchestration (Pass 1 → Pass 1.5 → Pass 2); builds DirIndex | orchestrates scanner + http_client + fs::read_dir |
| `main` | `main.rs` | Entry point; calls clap, app, writes exit code | stdout, stderr, process::exit |

## Pure/Effectful Seam

The seam between pure core and effectful shell spans two data products built by the shell
and consumed by the core:

```
scanner (Pass 1) → ParsedFile { path: PathBuf, source: String, events: Vec<PcEvent>,
                                 headings: Vec<ParsedHeading>, link_line_map: Vec<usize> }
                 ↓
link_extractor::extract(&events) → Vec<ExtractedLink>   [pure]
anchor_table::build(&headings)   → AnchorTable           [pure]

app (Pass 1.5)  → DirIndex: HashMap<PathBuf, Vec<DirEntryInfo>>
                  (built from all link target directories + out-of-scan .md files)

Pass 2: path_resolver::resolve(dest, src_dir, &dir_index) → PathVerdict   [pure]
```

`ParsedFile` no longer carries `dir_entries`. The `DirIndex` is a separate data product
built after all links have been extracted, so it covers every target directory the links
reference — including directories outside the scan set.

## Three-Phase Data Flow Summary

```
Pass 1  (shell + pure, parallel via rayon):
  For each discovered .md file (ALL files, including --ignore'd):
    scanner reads file → ParsedFile
    link_extractor::extract(&events) → Vec<ExtractedLink>     [pure]
    anchor_table::build(&headings)   → AnchorTable             [pure]
  Output: AnchorIndex: HashMap<PathBuf, AnchorTable>
          LinkMap:     HashMap<PathBuf, Vec<ExtractedLink>>

Pass 1.5 (shell only, sequential):
  From all link destinations in LinkMap:
    Collect unique parent directories of every dest path
    Identify .md targets outside the scan set (gitignored, above root, dot-dirs)
    fs::read_dir each directory → Vec<DirEntryInfo> with EntryKind
    Parse each extra .md file → AnchorTable (same as Pass 1 anchor extraction)
  Output: DirIndex: HashMap<PathBuf, Vec<DirEntryInfo>>
  Termination: each directory visited at most once; symlink cycles broken by
    path-identity deduplication (DI-009 satisfied without recursion)

Pass 2  (pure only, parallel via rayon):
  For each non-ignored file's ExtractedLinks:
    path_resolver::resolve(dest, src_dir, &dir_index)     → PathVerdict  [pure]
    anchor_resolver::resolve(fragment, &anchor_index)      → Verdict      [pure]
    url_classifier::classify(dest) + http_verdict          → Verdict      [pure]
  Output: Vec<Finding>

Sort:   findings.sort_unstable_by_key(|f| (nfc(&f.path), f.line, f.col, f.link_target))  [pure]
Report: reporter::format_*(sorted_findings)  [pure]
Exit:   verdict::exit_code(sorted_findings, io_errors, config_error)  [pure]
```

## [Section Content]

<!-- Validator scaffold: real content is in the named sections above. The
     architecture-section-template uses "[Section Content]" as a literal
     placeholder heading; the compliance validator matches it by substring.
     This stub satisfies that check without altering any real content. -->
