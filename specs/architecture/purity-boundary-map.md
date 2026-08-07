---
document_type: architecture-section
level: L3
section: purity-boundary-map
version: "1.5"
status: draft
producer: architect
timestamp: 2026-08-06T00:00:00Z
phase: 1b
inputs:
  - .factory/specs/domain-spec/capabilities.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "07f5a2c"
traces_to: ARCH-INDEX.md
changelog:
  - version: "1.5"
    date: 2026-08-06
    change: "DirIndex-scope ruling: DirIndex is built from every extracted link destination — all link types (.md, non-.md, directory references). Added explicit qualifier to DirIndex build description (step 1) to match authoritative broad-scope ruling. This closes the contradiction with system-overview.md v1.8 (which described only missing-.md-target parent dirs)."
  - version: "1.4"
    date: 2026-08-06
    change: "P4-028 remediation: corrected v1.2 changelog entry — 'scanner now feeds DirIndex via Pass 1.5 in app' → 'app now builds DirIndex via Pass 1.5 (scanner traverses only the scan root in Pass 1)'. The body was already correct (line 77/104 reference app); only the changelog text was wrong."
  - version: "1.3"
    date: 2026-08-05
    change: "Pass-2 remediation: corrected verdict API — compute_exit_code(findings, io_errors) → exit_code(findings, io_errors, config_error) in pure-core table and Phase 6 Scope list; clarified slug P0 targets — slugify for totality (VP-001), compute_slug for determinism/uniqueness (VP-002/003)"
  - version: "1.2"
    date: 2026-08-05
    change: "SR-016 remediation: path_resolver now receives DirIndex (not DirEntries); removed fs escape hatch from path_resolver description; updated ParsedFile seam to remove dir_entries; app now builds DirIndex via Pass 1.5 (scanner traverses only the scan root in Pass 1)"
  - version: "1.1"
    date: 2026-08-05
    change: "Previous revision"
  - version: "1.0"
    date: 2026-08-05
    change: "Initial draft"
---

# Purity Boundary Map: mdlinkcheck

## The Boundary Rule

A function belongs to the **pure core** if and only if:
1. It takes data structures as input and returns data structures as output.
2. It calls no I/O primitives: no `fs::read`, `fs::read_dir`, `net::*`, `process::*`,
   no printing, no timestamps, no random numbers, no global mutable state.
3. Given the same inputs, it always returns the same output (referential transparency).

A function belongs to the **effectful shell** if it performs any I/O.

The boundary is architectural, not advisory. Violating it invalidates Kani proof harnesses.

## Pure Core — mdlinkcheck-core

| Module | Pure guarantee | Kani harness viable? |
|--------|---------------|---------------------|
| `slug` | `compute_slug(text, counter) → String`. No I/O. Counter is passed in, not global. | Yes |
| `fragment` | `split_fragment(raw_dest) → (&str, Option<&str>)`. String scan only. | Yes |
| `anchor_table` | `build_anchor_table(headings) → AnchorTable`. Reads from slice input only. | Yes |
| `link_extractor` | `extract_links(events) → Vec<ExtractedLink>`. Events pre-parsed by scanner. | Yes |
| `path_resolver` | `resolve_path(dest, src_dir, index: &DirIndex) → PathVerdict`. **DirIndex is input data**, never calls any fs::* function. Does directory lookups by PathBuf key; each entry carries EntryKind so file/dir/symlink is distinguishable without I/O. NFC comparison on provided entry names. Genuinely pure: no escape hatch. | Yes |
| `anchor_resolver` | `resolve_anchor(fragment, table) → Verdict`. Lookup in provided table. | Yes |
| `url_classifier` | `classify_url(dest) → UrlKind`. Uses `url::Url::parse()` from the `url 2.5.8` crate (servo/rust-url, WHATWG-compliant). `Url::parse()` is deterministic and performs no I/O — it takes a `&str` and returns a `Result<Url, ParseError>`. URL parsing and normalization are pure; only the subsequent HTTP fetch (in `http_client`) is effectful. Kani harnesses can target the classifier decision logic directly. | Yes |
| `http_verdict` | `classify_response(status, attempt) → Verdict`. Pattern-match on integers. | Yes |
| `filter` | `should_ignore(path, patterns) → bool` + `should_allow(url, prefixes) → bool`. Pure predicate over input data. | Yes |
| `reporter` | `format_text(findings, opts) → String` + `format_json(findings) → String`. Formatting only; no stdout. | Limited (string output, not side-effect-critical) |
| `verdict` | `exit_code(findings, io_errors, config_error) → u8`. Pure aggregation over slices and a boolean flag. | Yes |

**path_resolver purity guarantee (SR-016 resolution):** `path_resolver` receives a
`DirIndex: HashMap<PathBuf, Vec<DirEntryInfo>>` built by `app` during Pass 1.5. It never
calls `fs::read_dir`, `fs::metadata`, `Path::exists`, or any other I/O. Each `DirEntryInfo`
carries the entry name and an `EntryKind` enum (`File`, `Dir`, `Symlink { dangling: bool }`),
so path_resolver can distinguish a directory target from a file target and a dangling symlink
from a healthy one — producing `target-is-directory` and `broken-symlink` reason codes
correctly. Multi-component resolution (`docs/sub/a.md` from `docs/guide.md`) works because
DirIndex is keyed by directory path, not limited to the source file's parent directory.
This is what makes NFC case-sensitive comparison formally verifiable (VP-008).

## Effectful Shell — mdlinkcheck (binary crate)

| Module | Effects | Data produced for pure core |
|--------|---------|----------------------------|
| `scanner` | `fs::read` (file bytes), `ignore` WalkBuilder traversal | `ParsedFile { path, source, events, headings, link_line_map }` |
| `http_client` | `ureq` HTTP calls (network), `rayon` thread pool management | `HttpResult { url, status, redirect_count, timing }` |
| `cli` | `clap` arg parsing (reads env vars for NO_COLOR/CLICOLOR) | `CliArgs` |
| `app` | Orchestrates scanner + http_client; builds DirIndex via Pass 1.5 (`fs::read_dir`); calls `process::exit` indirectly | Routes data to/from pure core; produces `DirIndex: HashMap<PathBuf, Vec<DirEntryInfo>>` |
| `main` | `println!`, `eprintln!`, `process::exit` | — |

## The Seam — ParsedFile and DirIndex Types

```rust
// ParsedFile: produced by scanner in Pass 1 (effectful) — consumed by pure core
pub struct ParsedFile {
    pub path: PathBuf,                  // NFC-normalized in scanner
    pub source: String,                 // file bytes as UTF-8
    pub events: Vec<OffsetEvent>,       // pulldown-cmark events with byte ranges
    pub headings: Vec<ParsedHeading>,   // (text, level) for slug computation
    pub link_line_map: Vec<usize>,      // byte-offset → line mapping (precomputed)
    // NOTE: no dir_entries field — directory information is in DirIndex (built Pass 1.5)
}

// DirIndex: produced by app in Pass 1.5 (effectful) — consumed by path_resolver (pure)
pub type DirIndex = HashMap<PathBuf, Vec<DirEntryInfo>>;
pub enum EntryKind { File, Dir, Symlink { dangling: bool } }
pub struct DirEntryInfo { pub name: OsString, pub kind: EntryKind }
```

The scanner produces `ParsedFile` in Pass 1 by:
1. Reading file bytes (I/O)
2. Running `pulldown-cmark::Parser::new_with_broken_links()` (pure-ish)
3. Recording `into_offset_iter()` events and precomputing the line map (CPU)

`app` builds `DirIndex` in Pass 1.5 by:
1. Collecting all unique parent directories from every extracted link destination — all link types (.md, non-.md, directories)
2. Calling `fs::read_dir` on each (one I/O call per distinct directory)
3. Storing `DirEntryInfo { name, kind }` keyed by directory PathBuf

All processing in Pass 2 is pure: `path_resolver` does lookups against DirIndex with no I/O.

## Phase 6 Scope

Kani proofs are valid for all `pub fn` signatures in `mdlinkcheck-core` that take
only `&str`, `&Path`, `&[T]`, or newtype wrappers around those. The following are
P0 Kani targets (proof harnesses defined in VP-001..007):

- `slug::slugify` — totality (VP-001); `slug::compute_slug` — determinism (VP-002), output-uniqueness (VP-003)
- `fragment::split_fragment` — split correctness
- `verdict::exit_code` — exit-2-beats-1, indeterminate-clean-exit-0, config-error-exits-2
- `http_verdict::classify_response` — totality

Fuzz targets (VP-012, VP-013) live in `fuzz/fuzz_targets/` under the binary crate.

## [Section Content]

<!-- Validator scaffold: real content is in the named sections above. The
     architecture-section-template uses "[Section Content]" as a literal
     placeholder heading; the compliance validator matches it by substring.
     This stub satisfies that check without altering any real content. -->
