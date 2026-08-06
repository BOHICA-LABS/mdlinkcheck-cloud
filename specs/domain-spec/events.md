---
document_type: domain-spec-section
level: L2
section: events
version: "1.1"
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
  - version: "1.1"
    date: 2026-08-05
    change: "D-012 orphan fix: Stage 2 corrected from 'case-insensitive extension match (.md, .markdown)' to 'case-sensitive extension match (.md only)'. Both the case-sensitivity claim and the .markdown inclusion were wrong per DD-019/D-012."
  - version: "1.0"
    date: 2026-08-05
    change: "Initial draft"
---

# Section 4: Processing Stages

> **Sharded L2 section (DF-021).** Navigate via `L2-INDEX.md`.

`mdlinkcheck` is a pipeline-oriented CLI tool. Domain events map to named processing
stages. Each stage has defined inputs, outputs, and failure behavior. See
`event-flow.md` for the causality chain.

---

## Stage 1: Input Validation

**Trigger:** CLI invocation.
**Inputs:** Raw argv, environment variables (`NO_COLOR`, proxy env vars).
**Outputs:** Validated path list, parsed flags, IgnoreRule set, AllowRule set.
**Failure:** Invalid flag or unknown flag → exit 2 immediately (no further processing).
Nonexistent path argument → I/O error recorded; continue (DI-011).

---

## Stage 2: File Discovery

**Trigger:** Validated path list.
**Inputs:** Path arguments (files and directories), IgnoreRule set.
**Outputs:** Deduplicated list of MarkdownFile paths to scan.
**Rules:** Recursive traversal; skip dot-directories unconditionally (DD-018); respect
`.gitignore`; case-sensitive extension match (`.md` only — DD-019); deduplicate by
canonicalized path; terminate on symlink cycles (DI-009).
**Failure:** Unreadable directory → I/O error recorded, mark exit-2 pending, continue.

---

## Stage 3: Parallel File Parsing + Anchor Table Construction

**Trigger:** Discovered file list (parallel across files permitted).
**Inputs:** MarkdownFile paths.
**Outputs:** Per-file: parsed AST, link list (with byte offsets), anchor table.

**Two-pass constraint (DI-008):** ALL anchor tables must be fully constructed before
Stage 4 begins. No link validation starts while any anchor table is being built.

**Non-UTF-8 content:** Decoded lossily or reported as per-file I/O error → mark
exit-2 pending, exclude from further stages.

**Byte-offset to line number:** Build a `Vec<usize>` of line-start byte offsets once
per file, then binary-search for each link's byte range.

---

## Stage 4: Link Resolution

**Trigger:** Completion of Stage 3 (all anchor tables available).
**Inputs:** All extracted links, all anchor tables, IgnoreRule set, AllowRule set.
**Outputs:** Per-link verdict (initial assignment).

Sub-steps by link kind:

| Kind | Resolution |
|------|-----------|
| `relative-file` | Percent-decode path → NFC-normalize → case-sensitive directory-entry lookup (DI-002) |
| `anchor-only` | Look up slug in current file's anchor table |
| `cross-file-anchor` | Resolve file path (as above) → look up slug in target's anchor table |
| `external-http` | Apply AllowRule; if exempt → `clean`; else if offline → syntax check (CAP-009); if `--online` → Stage 5 |
| `non-http scheme` | Skip → `clean` (DD-009) |
| `undefined-reference` | `broken` with reason `undefined-reference-definition` (T5) |

Fragment processing (all kinds): split at first unescaped `#` in raw destination
(DI-003), then percent-decode the fragment, then compare against anchor table.

---

## Stage 5: External URL Liveness Checking (online mode only)

**Trigger:** External http(s) URLs not exempted by AllowRule, when `--online` active.
**Inputs:** Deduplicated ExternalUrl set.
**Outputs:** Per-URL verdict (`alive`/`broken`/`indeterminate`) and reason code.

**Protocol:**
1. HEAD request with `User-Agent: mdlinkcheck/<version>`.
2. On status in `{400, 403, 404, 405, 501, 999}` or transport failure → GET fallback
   with `Range: bytes=0-0` (DD-016).
3. 2xx → `alive`. Definitive 404/410/DNS failure → `broken`. 429/5xx/bot-403/timeout
   → `indeterminate` (DI-010).
4. Total per-URL timeout: 10 seconds wall clock across all attempts (DD-016).
5. 2 retries with exponential backoff for network/timeout/5xx/429.
6. Per-host rate limiting; honor `Retry-After` header (delay-seconds or HTTP-date).

---

## Stage 6: Report Assembly

**Trigger:** All verdicts collected.
**Inputs:** All Link + Verdict pairs, run metadata.
**Outputs:** Sorted finding list (DI-001: by NFC path / line / column), formatted report.
**Empty result:** Zero findings → empty JSON array `[]` or no output lines; exit 0.

---

## Stage 7: Output and Exit

**Trigger:** Report assembled.
**Inputs:** Report, I/O error flag, broken-link flag.
**Outputs:** stdout (findings in text or JSON), stderr (diagnostics), exit code.

**Exit code rule (DI-011):** `if any I/O/usage error → 2; else if any broken → 1; else 0`.
