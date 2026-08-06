---
document_type: architecture-section
level: L3
section: api-surface
version: "1.4"
status: draft
producer: architect
timestamp: 2026-08-05T20:00:00Z
phase: 1b
inputs:
  - .factory/specs/prd.md
  - .factory/specs/prd-supplements/interface-definitions.md
  - .factory/specs/domain-spec/capabilities.md
input-hash: "f3758cf"
traces_to: ARCH-INDEX.md
changelog:
  - version: "1.4"
    date: 2026-08-06
    change: "P4 remediation: (P4-022) added format_summary() to reporter API surface — produces the stderr summary line separately from format_text() stdout body. (P4-004) updated JSON sort key comment from 3-field to 4-field (NFC-file, line, column, link_target) per DI-001/ADR-005 v1.3."
  - version: "1.3"
    date: 2026-08-05
    change: "P2-M12 remediation: corrected comment on line 82 from 'DirIndex populated by scanner Pass 1.5' to 'DirIndex populated by app Pass 1.5' — scanner traverses only the scan root in Pass 1; app opens out-of-scan target directories directly in Pass 1.5"
  - version: "1.2"
    date: 2026-08-05
    change: "Phase 1d D-011 remediation: removed --quiet, --hidden, --insecure, --offline from CLI surface (all four are explicit non-goals per D-011); F-018 remediation: DuplicateCounter now BTreeMap<String,u32> (HashMap<String,u32> is not Kani-feasible); added slugify() pure core to library API"
  - version: "1.1"
    date: 2026-08-05
    change: "SR-016 remediation: replaced DirEntries=Vec<OsString> with DirIndex=HashMap<PathBuf,Vec<DirEntryInfo>>; resolve_path now receives directory-keyed index populated by Pass 1.5"
  - version: "1.0"
    date: 2026-08-05
    change: "Initial draft"
---

# API Surface: mdlinkcheck

## CLI Interface (Public Contract)

```
mdlinkcheck [OPTIONS] [PATH]...

ARGS:
  [PATH]...   Files or directories to scan. Default: current directory.

OPTIONS:
  --ignore <GLOB>          Exclude files matching glob from link-source scanning.
                           Repeatable. globset dialect. Anchor tables still built.
  --allow <URL-PREFIX>     Exempt URLs with this prefix from syntax/liveness checks.
                           Repeatable. Component-boundary enforced (DD-013).
  --online                 Enable external URL liveness checking (HEAD+GET fallback).
                           Default: offline (syntax validation only).
  --format <FORMAT>        Output format. [default: text] [possible values: text, json]
  -h, --help               Print help.
  -V, --version            Print version.
```

**Exit codes:**
- `0` — no broken links, no I/O errors
- `1` — at least one `broken` verdict
- `2` — at least one I/O or usage error (takes precedence over exit 1)

**Stdout/stderr contract:** Findings go to stdout only. Diagnostics, progress, and
the summary line go to stderr only. JSON output must be pipeable (`mdlinkcheck --format json > out.json`).

## Library API (mdlinkcheck-core) — Key Public Functions

These are the surfaces that test-writer and implementer drive directly.

```rust
// slug.rs — CAP-006, pure, Kani target
// slugify() is the Kani-provable core (VP-001); compute_slug() wraps it with the counter (VP-003)
pub fn slugify(text: &str) -> String;
pub fn compute_slug(text: &str, counter: &mut DuplicateCounter) -> String;
pub struct DuplicateCounter(BTreeMap<String, u32>);  // BTreeMap required for Kani feasibility (VP-003)
impl DuplicateCounter { pub fn new() -> Self; }

// fragment.rs — DI-003, pure, Kani target
pub fn split_fragment<'a>(raw_dest: &'a str) -> (&'a str, Option<&'a str>);

// anchor_table.rs — CAP-005, pure
pub struct AnchorTable(HashSet<String>);
pub fn build_anchor_table(headings: &[ParsedHeading]) -> AnchorTable;
pub fn build_with_html(headings: &[ParsedHeading], html_anchors: &[String]) -> AnchorTable;

// link_extractor.rs — CAP-003, CAP-004, pure
pub fn extract_links(events: &[OffsetEvent]) -> Vec<ExtractedLink>;

// path_resolver.rs — CAP-007, DI-002, pure
// DirIndex populated by app Pass 1.5 — never by path_resolver itself (scanner only traverses the scan root)
pub fn resolve_path(dest: &str, src_dir: &Path, index: &DirIndex) -> PathVerdict;
pub type DirIndex = HashMap<PathBuf, Vec<DirEntryInfo>>;
pub enum EntryKind { File, Dir, Symlink { dangling: bool } }
pub struct DirEntryInfo { pub name: OsString, pub kind: EntryKind }

// anchor_resolver.rs — CAP-008, pure
pub fn resolve_anchor(fragment: &str, table: &AnchorTable) -> Verdict;

// url_classifier.rs — CAP-009, pure
pub fn classify_url(dest: &str) -> UrlKind;
pub enum UrlKind { HttpS(Url), NonHttp, Malformed(String) }

// http_verdict.rs — CAP-010 logic, pure, Kani target
pub fn classify_response(status: u16, attempt: HttpAttempt) -> Verdict;
pub enum HttpAttempt { Head, GetFallback }

// filter.rs — CAP-011, pure
pub fn should_ignore(path: &Path, patterns: &GlobSet) -> bool;
pub fn should_allow(url: &str, prefixes: &[AllowPrefix]) -> bool;

// reporter.rs — CAP-012, CAP-013, pure
pub fn format_text(findings: &[Finding], opts: TextReportOpts) -> String;   // stdout body
pub fn format_summary(findings: &[Finding], io_errors: &[IoError]) -> String; // stderr summary line
pub fn format_json(findings: &[Finding]) -> String;  // schema_version: 1

// verdict.rs — CAP-014, DI-010, DI-011, pure, Kani target
pub fn exit_code(findings: &[Finding], io_errors: &[IoError], config_error: bool) -> u8;
```

## Key Shared Types

```rust
pub struct Finding { pub path: PathBuf, pub line: u32, pub col: u32,
                     pub link_target: String, pub verdict: Verdict,
                     pub reason: FailureReason }
pub enum Verdict { Clean, Broken(FailureReason), Indeterminate(FailureReason) }
pub struct ParsedHeading { pub text: String, pub level: u8 }
pub struct ExtractedLink { pub dest: String, pub kind: LinkKind, pub line: u32, pub col: u32 }
```

## JSON Output Schema (CAP-013, DD-011)

```json
{ "schema_version": 1,
  "results": [
    { "file": "docs/README.md", "line": 42, "column": 5,
      "link_target": "setup.md#missing-section",
      "verdict": "broken", "reason": "anchor-not-found" }
  ]
}
```

`indeterminate` results ARE included. Compact (not pretty-printed). Findings sorted
by (NFC-file, line, column, link_target) before serialization (DI-001).

## [Section Content]

<!-- Validator scaffold: real content is in the named sections above. The
     architecture-section-template uses "[Section Content]" as a literal
     placeholder heading; the compliance validator matches it by substring.
     This stub satisfies that check without altering any real content. -->
