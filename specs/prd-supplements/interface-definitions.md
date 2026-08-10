---
document_type: prd-supplement
supplement_type: interface-definitions
level: L3
version: "1.6"
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
traces_to: .factory/specs/prd.md
primary_consumers: [implementer, test-writer]
---

# Interface Definitions: mdlinkcheck

> Primary consumers: implementer, test-writer.
> Full CLI surface, JSON schema, exit codes, stdout/stderr contract, and flag interactions.

---

## 1. CLI Invocation

```
mdlinkcheck [OPTIONS] [PATH]...
```

- `PATH`: Zero or more file or directory arguments. Default: `.` (current working directory).
- Options and positional arguments may be interleaved in any order.
- `--` ends option parsing; subsequent tokens are treated as PATH arguments even if they start with `-`.

---

## 2. Flags

### 2.1 Output Flags

| Flag | Arity | Type | Default | Description |
|------|-------|------|---------|-------------|
| `--format <FORMAT>` | once | `text\|json` | `text` | Output format. `text` and `--format text` are equivalent. `json` emits a JSON object to stdout. Any other value → exit 2 with usage error. |

**`--format` repeated:** last value wins. `--format json --format text` → `text`.

**Explicit non-goals (D-011):** `--quiet` (summary suppression) is not a supported flag in v1.0. The stderr summary is always emitted.

### 2.2 Filter Flags

| Flag | Arity | Type | Default | Description |
|------|-------|------|---------|-------------|
| `--ignore <GLOB>` | repeatable | glob string | none | Exclude files matching GLOB from link checking (as sources). Matched using globset dialect (BurntSushi); pattern anchored at CWD. `**` crosses directory boundaries. Does NOT exclude files as anchor targets. |
| `--allow <URL_PREFIX>` | repeatable | normalized URL prefix string | none | Exempt external URLs whose normalized form starts with URL_PREFIX from syntax and liveness checks. Prefix matched at scheme+authority+path component boundaries — `--allow https://example.com` does NOT match `https://example.com.evil.tld`. |

### 2.3 Checking Mode Flags

| Flag | Arity | Type | Default | Description |
|------|-------|------|---------|-------------|
| `--online` | once | bool | false | Enable external URL liveness checking (HEAD/GET). Default mode is offline. |

**Explicit non-goals (D-011):** `--offline` (explicit offline pin) and `--insecure` (TLS bypass) are not supported in v1.0. TLS certificate verification is always enforced; TLS failures produce `broken` verdict with reason code `tls-error` (BC-2.10.006, ADR-007). There is no flag to bypass TLS verification.

### 2.4 Traversal Flags

No traversal flags in v1.0.

**Explicit non-goals (D-011):** `--hidden` (include dot-directories) is not supported. Dot-directories are unconditionally excluded from traversal (BC-2.01.004). `.md` files inside dot-directories remain valid anchor targets (DI-006 case 3).

### 2.5 Standard Flags

| Flag | Description | Exit Code |
|------|-------------|-----------|
| `--help` / `-h` | Print help text to stdout and exit | 0 |
| `--version` / `-V` | Print version string to stdout and exit | 0 |

---

## 3. Exit Codes

| Code | Meaning | Trigger |
|------|---------|---------|
| `0` | Success — no broken links | All extracted links have `clean` or `indeterminate` verdict; no I/O or usage errors; OR `--help`/`--version` invocation. |
| `1` | Broken links found | At least one link has `broken` verdict. |
| `2` | Usage or I/O error | Unrecognized flag, invalid flag value, nonexistent PATH argument, unreadable `.md` file, or internal unexpected error. Takes precedence over exit code 1. |

**Precedence rule:** if a run produces both a broken link (→1) and an I/O error (→2), exit code is **2**.

**No other exit codes are produced.**

---

## 4. Stdout / Stderr Contract

| Stream | Content |
|--------|---------|
| **stdout** | Findings only: the text report (one line per finding) or the JSON object. Nothing else. |
| **stderr** | Diagnostics: progress messages (if any), warnings, informational messages (e.g., "No markdown files found"), error messages for I/O errors, and the trailing summary line. |

**Invariant:** stdout is pure findings. `mdlinkcheck --format json > report.json` must produce valid JSON in `report.json` with no intermixed diagnostic text.

---

## 5. Text Output Format

Each finding line on stdout:

```
<file>:<line>: <link_target> — <reason>
```

- `<file>`: path relative to CWD, NFC-normalized.
- `<line>`: 1-based line number of the opening `[` of the link in the source file.
- `<link_target>`: the raw link destination as written in the Markdown source.
- `<reason>`: a human-readable message from the closed reason taxonomy.

**Indeterminate findings** are also printed, prefixed with `[indeterminate]`:

```
<file>:<line>: <link_target> — [indeterminate] <reason>
```

**Ordering:** sorted by `(NFC-normalized file path, line number, column number, link_target)` — ascending, deterministic across all parallel scans.

**Color:** applied only when stdout is a TTY AND `NO_COLOR` is not set AND `CLICOLOR` is not `0`. `CLICOLOR_FORCE=1` forces color even on non-TTY.

- Broken findings: red
- Indeterminate findings: yellow
- File path: bold

**Trailing summary line on stderr** (always emitted; `--quiet` is a non-goal per D-011):

```
N broken link(s) in M file(s).
```

On zero broken links:

```
No broken links found.
```

---

## 6. JSON Output Schema

JSON output is a single object emitted to stdout, compact (no pretty-printing):

```json
{
  "schema_version": 1,
  "results": [
    {
      "file": "docs/guide.md",
      "line": 42,
      "column": 5,
      "link_target": "../api/reference.md#section",
      "verdict": "broken",
      "reason": "anchor-not-found"
    }
  ],
  "errors": [
    {
      "file": "docs/secret.md",
      "reason": "target-unreadable",
      "message": "cannot read file: docs/secret.md: permission denied"
    }
  ]
}
```

`errors` is omitted (or an empty array `[]`) when no I/O errors occurred. `results` is never empty solely because a file was unreadable — those go in `errors`, not `results`. This distinction allows the CI engineer persona to distinguish broken links from scan failures in machine-readable output. (Added v1.4, F-013.)

### 6.1 Top-Level Fields

| Field | Type | Description |
|-------|------|-------------|
| `schema_version` | integer | Always `1` for this version. Increment on incompatible schema changes. |
| `results` | array | Array of finding objects. Empty array `[]` when no findings. |
| `errors` | array | Array of I/O error objects (one per unreadable source file). Empty array `[]` or omitted when no I/O errors. Added v1.4 (F-013). |

### 6.2 Finding Object Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `file` | string | yes | CWD-relative path to the source file, NFC-normalized, forward slashes on all platforms. |
| `line` | integer | yes | 1-based line number of the opening `[` of the link in the source. Relative to BOM-stripped, LF-normalized buffer. |
| `column` | integer | yes | 1-based byte offset of the opening `[` within the source line. Relative to the BOM-stripped, LF-normalized buffer (not raw on-disk bytes). See §9. |
| `link_target` | string | yes | Raw link destination as written in source (before any percent-decoding). |
| `verdict` | string | yes | One of: `"broken"`, `"indeterminate"`. Never `"alive"` or `"clean"` — positive-verdict links are not emitted. |
| `reason` | string | yes | Reason code from the closed taxonomy (see error-taxonomy.md). |
| `sub_reason` | string | no (optional) | Additional diagnostic context for certain `http-indeterminate` findings. Present only when applicable. Current values: `"https-downgrade"` (HTTPS→HTTP redirect downgrade, BC-2.10.007) and `"private-ip"` (target resolves to private/link-local IP, BC-2.10.010). NOT part of the closed 13-code reason taxonomy. Consumers MUST ignore unknown values. (D-016) |

**Ordering:** `results` is sorted by (NFC-normalized file path, line, column, link_target) ascending — identical to text output sort order (DI-001, F-023).

**Stable key order in each object:** `file`, `line`, `column`, `link_target`, `verdict`, `reason`, `sub_reason` (omit if not applicable).

### 6.2b Error Object Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `file` | string | yes | CWD-relative path to the unreadable source file. |
| `reason` | string | yes | Always `"target-unreadable"` (from the closed taxonomy). |
| `message` | string | yes | Human-readable OS error string. Not stable across versions; test automation must use `reason`, not `message`. |

### 6.3 Schema Stability

`schema_version: 1` is pre-1.0 unstable. No backwards-compatibility guarantee until v1.0 release. Consumers should check `schema_version` before parsing. The addition of the `errors` array in v1.4 is additive (existing consumers ignoring unknown keys are unaffected); it is not a `schema_version` increment per the pre-1.0 policy.

---

## 7. Environment Variables

| Variable | Effect |
|----------|--------|
| `NO_COLOR` | If set (any value), suppress ANSI color output |
| `CLICOLOR` | If set to `0`, suppress ANSI color output |
| `CLICOLOR_FORCE` | If set to `1`, force ANSI color even on non-TTY |
| `HTTP_PROXY` | HTTP proxy URL (passed to ureq; `--online` mode only) |
| `HTTPS_PROXY` | HTTPS proxy URL (passed to ureq; `--online` mode only) |
| `NO_PROXY` | Comma-separated list of hosts to bypass proxy |

No other environment variables are recognized. Config via env vars beyond these is not supported (brief non-goal: "no config file").

---

## 8. Flag Interaction Rules

| Interaction | Rule |
|-------------|------|
| `--format` repeated | Last value wins |
| `--ignore GLOB` on an explicitly-passed PATH | `--ignore` wins — the file is excluded as a link source even if passed explicitly (BC-2.11.003) |
| `--allow PREFIX` in offline mode | Suppresses syntax validation for matching URLs (BC-2.11.002) |
| `--` | Ends option parsing; all subsequent tokens treated as PATH arguments |
| Nonexistent PATH argument | Error recorded (`target-unreadable`); scanning continues for remaining valid PATH arguments; exit 2 after all scanning completes (DD-007 no-fail-fast) |
| Unknown flag | Exit 2 immediately with usage message |

---

## 9. Column Reporting

Column is the 1-based byte offset of the opening `[` within the source line. Multi-byte UTF-8 characters count as their byte length (not their character count). This matches the convention used by Rust diagnostic tools (`rustc`, `cargo`).

**Buffer reference (F-028):** Line and column offsets are computed on the **BOM-stripped, LF-normalized** buffer produced by `scanner.rs` (BC-2.02.002), NOT on the raw on-disk bytes. Consequences:
- On a UTF-8 BOM'd file (3-byte `\xEF\xBB\xBF` prefix): the BOM is stripped before any offset is computed. The first character after the BOM is at line 1, column 1 — not column 4.
- On a CRLF file: CRLF→LF normalization happens before offset computation. Byte offsets are relative to the LF-normalized content.
- Text output, JSON `line`/`column` fields, and the manifest's finding objects all use this same buffer reference.

For a link whose destination spans multiple source lines, the line and column of the **opening `[`** is reported.

---

## 10. Acceptance Corpus (tests/corpus/)

Per DD-005 (D-009), `tests/corpus/` and a `README.md` are in-scope deliverables.

### 10.1 tests/corpus/ Structure

```
tests/corpus/
  manifest.json          -- machine-readable expected-classification manifest
  README.md              -- describes the corpus and its design rationale
  fixtures/              -- individual .md fixture files
    broken-links/        -- files with planted broken links
    valid-traps/         -- files designed to catch false positives
    anchor/              -- anchor-specific fixtures
    code-context/        -- R4 code-exclusion fixtures
    ...
```

### 10.2 manifest.json Schema

The manifest schema mirrors the `--format json` output schema so that a corpus run is a
**direct comparison**: run `mdlinkcheck --format json <corpus-root>`, extract `results`, and
diff against `expected`. No transform needed; the same `column` field is present; the same
field ordering applies.

```json
{
  "schema_version": 1,
  "expected": [
    {
      "file": "fixtures/broken-links/file-not-found.md",
      "line": 5,
      "column": 3,
      "link_target": "missing.md",
      "verdict": "broken",
      "reason": "file-not-found"
    }
  ]
}
```

**Top-level fields:**

| Field | Type | Description |
|-------|------|-------------|
| `schema_version` | integer | Always `1`. |
| `expected` | array | Flat array of expected finding objects, one per expected finding across ALL fixture files. |

**Finding object fields:** identical to the `--format json` finding object (§6.2): `file`, `line`, `column`, `link_target`, `verdict`, `reason` — all required.

**Pass criterion:** Set equality over the six-field tuple `(file, line, column, link_target, verdict, reason)`. Concretely: `mdlinkcheck --format json <corpus-root> | jq '[.results[] | {file,line,column,link_target,verdict,reason}] | sort_by(.file,.line,.column)'` must equal `jq '[.expected[] | {file,line,column,link_target,verdict,reason}] | sort_by(.file,.line,.column)' manifest.json`. Any extra result is a false positive; any missing result is a false negative. The `errors` array (I/O errors) is checked separately: corpus fixtures MUST be readable, so `errors` MUST be empty in a passing corpus run. (F-014)

**Holdout fixtures:** DEC cases marked `[HOLDOUT]` in edge-cases.md MUST NOT appear in `manifest.json`. They belong in the separate holdout evaluation scenario set (which is not shipped in `tests/corpus/`).
