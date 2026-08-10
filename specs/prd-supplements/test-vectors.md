---
document_type: prd-supplement
supplement_type: test-vectors
level: L3
version: "1.12"
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
primary_consumers: [test-writer, holdout-evaluator]
---

# Test Vectors: mdlinkcheck

> Primary consumers: test-writer, holdout-evaluator.
> Concrete, executable test vectors derived from EC-001..EC-214 (active holdout pool excluded per HOLDOUT WARNING below) and T1..T16.
>
> **HOLDOUT WARNING:** The following ECs are NOT present in this file. They belong
> exclusively in the hidden holdout evaluation scenarios under
> `.factory/holdout-scenarios/wave-scenarios/`.
> Active holdout pool (12 total): EC-079, EC-093, EC-094, EC-141, EC-147, EC-148,
> EC-214, EC-156, EC-165, EC-166, EC-167, EC-168.
> EC-102 was formerly on this list; it has been replaced by EC-151 (D-010 decision).
> TV-BV013 (formerly EC-102) is now a visible required test vector in §0.
> EC-036, EC-049, EC-074, EC-157, EC-158: holdout designation retired per D-020
> (burned to visible tests); vectors TV-036, TV-049, TV-074, TV-157, TV-157b, TV-158,
> TV-158b added in v1.6 (P3-005 hotfix).
> EC-151: holdout designation retired per D-122 (2026-08-08) — prd.md:618 D-010 note
> leaked concrete input/expected output verbatim; burned to visible test TV-151 (§3);
> replaced by EC-214 (HS-008) in the same risk cluster.
> EC-165..EC-168 are fresh replacement hidden scenarios (D-020) covering anchor
> resolution, source-exclusion × cross-file anchors, percent-encoding × fragment
> split, and duplicate-slug collisions.
>
> Vector format: each table row is a self-contained test: filesystem fixture, flags,
> source markdown, expected verdict(s), expected exit code, expected JSON (abbreviated).

---

## §0. Canonical Self-Referential Vector (BV-013 — CRITICAL)

> This vector is the single most important correctness proof for R4 (code context exclusion).
> It must be in the standard test suite AND verified manually at acceptance.

| Vector ID | Source MD | Filesystem | Flags | Expected Exit | Expected Findings |
|-----------|-----------|------------|-------|---------------|------------------|
| TV-BV013 | `BRIEF.md` from this repository (lines 18-19 contain `` `[x](docs/a.md)` ``, `` `[x](../b.md)` ``, `` `[x](#setup)` ``, `` `[x](a.md#usage)` `` inside inline code spans) | Repo root | (none) | **0** | none — all four link-looking strings are inside inline code spans and must NOT be extracted |

**JSON expected:**
```json
{"schema_version": 1, "results": []}
```

**Why critical:** If R4 (code context exclusion) is broken, `mdlinkcheck BRIEF.md` exits 1 on its own specification document. This is the cheapest possible regression catch.

---

> **Column offset note (F-028):** All `column` values in this file refer to the 1-based byte
> offset within the **BOM-stripped, LF-normalized** buffer — not the raw on-disk bytes. On a
> BOM'd file the first character after the BOM is column 1 (not column 4). On a CRLF file,
> byte offsets are computed on the LF-normalized buffer. See BC-2.02.002 Invariant (added v1.4).

## §1. Discovery (R1) — EC-001 through EC-021

| TV | EC | Fixture Description | Flags | Expected Exit | Expected Verdict | Reason |
|----|-----|---------------------|-------|---------------|-----------------|--------|
| TV-001 | EC-001 | CWD = directory with nested `.md` files at depth 3 | (none) | 0 | (clean) | Recursive traversal |
| TV-002 | EC-002 | Directory with `node_modules/foo/bar.md` (1000 `.md` files inside node_modules) | (none) | 0 | (clean) | `node_modules` is excluded via `.gitignore` |
| TV-003 | EC-003 | `.github/PULL_REQUEST_TEMPLATE.md` with a broken link | (none) | 0 | (clean) | Dot-dir skipped by default |
| TV-004 | EC-004 | `.git/COMMIT_EDITMSG` named `.md` | (none) | 0 | none | `.git/` never walked |
| TV-005 | EC-005 | `README.MD` (uppercase) with a broken link | (none) | 0 | (none — not scanned) | D-012: extension matching is case-sensitive; `.MD` ≠ `.md`; file is excluded from scan set |
| TV-006 | EC-006 | `notes.markdown` with a broken link; `notes.mdx` with a broken link | (none) | 0 | neither file scanned | D-012: only `.md` (exact, case-sensitive) is discovered; `.markdown` and `.mdx` are explicit non-goals |
| TV-007 | EC-007 | `notes.txt` with a broken link; explicit arg | `notes.txt` | 1 | broken | Explicit arg parsed regardless of extension |
| TV-008 | EC-008 | Directory symlink creating cycle `a/b -> a` | (none) | 0 | (clean) | Dir symlinks not followed; terminates |
| TV-009 | EC-009 | Symlink `docs -> ../shared-docs` pointing outside root; shared-docs has clean links | (none) | 0 | (clean) | File symlinks in dirs: NOT followed (dir symlink); no crash |
| TV-010 | EC-010 | `mdlinkcheck . docs docs/a.md` (overlapping) with `docs/a.md` having one broken link | `. docs docs/a.md` | 1 | broken ×1 (not ×3) | Deduplicated — reported once |
| TV-011 | EC-011 | Empty directory; no `.md` files found | (none) | 0 | none | Exit 0 + stderr "No markdown files found." |
| TV-012 | EC-012 | PATH is `/does/not/exist` | `/does/not/exist` | 2 | n/a | Exit 2 with reason indicating path not found |
| TV-013 | EC-013 | `docs/secret.md` with mode `000` (no read) | (none) | 2 | exit 2; `errors:[{file:"docs/secret.md",reason:"target-unreadable"}]` in JSON `--format json` output; NOT a `verdict` field (I/O errors go in the `errors` array, not `results`) | I/O error; other files still scanned; see F-013/BC-2.13.001 |
| TV-014 | EC-014 | `bad.md` containing ISO-8859-1 bytes (not valid UTF-8) | (none) | 2 | exit 2; `errors:[{file:"bad.md",reason:"target-unreadable"}]` in JSON output | Non-UTF-8 reported as I/O error in `errors` array |
| TV-015 | EC-015 | `utf8bom.md` with UTF-8 BOM followed by `## Setup\n[x](#setup)` | (none) | 0 | (clean) | BOM stripped; heading slug `setup` matches |
| TV-015b | EC-178 | `utf8bom.md` with UTF-8 BOM, then `[x](missing.md)` on line 1 | (none) | 1 | broken; file=utf8bom.md, line=1, **column=1** | Column is relative to BOM-stripped buffer; the `[` is at byte offset 1 after BOM removal, NOT byte offset 4 counting the 3 BOM bytes. See F-028. |
| TV-016 | EC-016 | CRLF-only file with `## Heading` on line 5, `[x](#heading)` on line 10 | (none) | 0 | (clean) | Line numbers same as LF equivalent |
| TV-017 | EC-017 | Zero-byte `empty.md` | (none) | 0 | none | No findings |
| TV-018 | EC-018 | 50 MB single `huge.md` with one broken link | (none) | 1 | broken ×1 | No OOM; completes |
| TV-019 | EC-019 | File named `my file#1.md` with a broken link in it | (none) | 1 | broken | Correct quoting in text and JSON output |
| TV-020 | EC-020 | FIFO named `pipe.md` in the tree | (none) | 0 | none | Non-regular files skipped silently |
| TV-021 | EC-021 | File modified while scan is in flight (concurrent write) | (none) | 2 | `target-unreadable` | Any I/O failure during read yields exit 2 and target-unreadable; other files continue scanning. Race condition is handled identically to permission-denied: graceful, no panic, deterministic exit code. (Verdict chosen: target-unreadable/exit-2 is the only valid deterministic outcome — "clean" would require the race to be undetectable, which is implementation-defined.) |

---

## §2. Relative File Links (R2a) — EC-022 through EC-042

| TV | EC | Source MD File | Link | Filesystem | Expected Exit | Expected Verdict | Reason |
|----|-----|----------------|------|------------|---------------|-----------------|--------|
| TV-022 | EC-022 | `docs/a.md` | `[x](../README.md)` | `README.md` exists at root | 0 | clean | File-relative resolution |
| TV-023 | EC-023 | `docs/a.md` | `[x](/docs/b.md)` | `docs/b.md` exists (git repo) | 0 | clean | Root-relative → git root |
| TV-024 | EC-024 | `docs/a.md` | `[x](../../../../etc/passwd)` | `/etc/passwd` exists | 0 | clean | Relative path resolution has no scan-root boundary. The resolved absolute path `/etc/passwd` exists → clean. No path-above-scan-root enforcement for relative links (that applies only to root-relative links T16). (Verdict chosen: clean — no policy prevents relative traversal outside root.) |
| TV-025 | EC-025 | `a.md` | `[x](docs/my%20file.md)` | `docs/my file.md` exists | 0 | clean | Percent-decode → resolve |
| TV-026 | EC-026 | `a.md` | `[x](docs/my file.md)` | `docs/my file.md` exists | 0 | clean | CommonMark angle-bracket NOT needed for this — raw space ends destination; `pulldown-cmark` handles correctly |
| TV-027 | EC-027 | `a.md` | `[x](<docs/my file.md>)` | `docs/my file.md` exists | 0 | clean | Angle-bracket form; parser strips brackets; destination = `docs/my file.md` |
| TV-028 | EC-028 | `a.md` | `[x](a.md "Some title")`, `[x](a.md 'title')`, `[x](a.md (title))` | `a.md` exists | 0 | clean ×3 | Titles stripped; all three forms |
| TV-029 | EC-029 | `a.md` | `[x](docs/)` | `docs/` directory exists | 0 | clean | Directory link passes |
| TV-030 | EC-030 | `a.md` | `[x](docs)` | `docs/` directory exists (no file named `docs`) | 0 | clean | Directory link passes |
| TV-031 | EC-031 | `a.md` | `[x]()` | — | 1 | broken (`malformed-url`) | Empty link destination is syntactically invalid — fails WHATWG URL parse (not a valid URL) and is not a valid relative path. Classified before path resolution. Verdict: broken, reason: malformed-url. (Verdict chosen: malformed-url is the correct syntactic-failure code for an unparseable destination; an empty string is neither a valid path nor a valid URL. Backed by BC-2.07.007.) |
| TV-032 | EC-032 | `a.md` | `[x](   )` | — | 1 | broken | Whitespace-only destination malformed |
| TV-033 | EC-033 | `a.md` | `[x](a.md?raw=1)` | `a.md` exists | 0 | clean | Query stripped before resolution |
| TV-034 | EC-034 | `a.md` | `[x](a.md/)` | `a.md` is a file (not dir) | 1 | broken (`file-not-found`) | Trailing slash signals a directory path. `a.md/` resolves to a directory path that does not exist (POSIX: ENOTDIR when `a.md` exists as a file but not as a directory). Verdict: broken, reason: file-not-found (no such directory path exists). (Verdict chosen: file-not-found because `a.md/` as a path does not point to any existing file or directory — ENOTDIR means the path resolution fails. `target-is-directory` would require a directory to exist there; it does not. Backed by BC-2.07.008.) |
| TV-035 | EC-035 | `a.md` | `[x](./a.md)`, `[x](././a.md)`, `[x](dir/../a.md)` | `a.md` exists | 0 | clean ×3 | Path normalization |
| TV-036 | EC-036 | `a.md` | `[x](README.MD)` | `README.md` exists; no `README.MD` on disk (case mismatch) | 1 | broken (`file-not-found`) | DEC-009/DI-002/T12 **flagship differentiator KD-004**: explicit case-sensitive `read_dir` entry comparison. `std::fs::exists("README.MD")` returns `true` on macOS APFS but MUST NOT be used — tool must enumerate the parent directory and compare entries exactly, so that verdicts depend on repository content rather than macOS APFS case-folding behaviour (D-043/D-006 canonical determinism rationale). An `std::fs::exists()`-based implementation silently accepts the case mismatch on macOS APFS, producing a false negative invisible on a macOS-only matrix. (D-020) |
| TV-037 | EC-037 | `a.md` | `[x](Café.md)` (NFC) | `Café.md` on disk in NFD (macOS-created) | 0 | clean | NFC-normalize both sides |
| TV-038 | EC-038 | `a.md` | `[x](link.md)` | `link.md` is a dangling symlink | 1 | broken | `broken-symlink` |
| TV-039 | EC-039 | `a.md` | `[x](logo.png)` | `logo.png` exists | 0 | clean | Non-MD file existence-checked |
| TV-040 | EC-040 | `a.md` | `![alt](missing.png)` | `missing.png` does NOT exist | 1 | broken | Image treated same as link |
| TV-041 | EC-041 | `a.md` | `[x](/dev/null)` | `/dev/null` exists on macOS | 0 | clean | Exists → pass |
| TV-042 | EC-042 | `a.md` | `[x](C:\docs\a.md)` | macOS FS, no such path | 1 | broken | `\` not a path separator on macOS; path not found |

---

## §3. Anchors (R2b) — EC-043 through EC-076

| TV | EC | Source MD | Heading | Link | Expected Exit | Verdict | Notes |
|----|-----|-----------|---------|------|---------------|---------|-------|
| TV-043 | EC-043 | `a.md` | `## AI & Automation` | `[x](#ai--automation)` | 0 | clean | v2: double hyphen retained |
| TV-044 | EC-044 | `a.md` | `## AI & Automation` | `[x](#ai-automation)` | 1 | broken | v2 proof: single hyphen is WRONG slug |
| TV-045 | EC-045 | `a.md` | `## Integrations - Growth` | `[x](#integrations---growth)` | 0 | clean | Triple hyphen |
| TV-046 | EC-046 | `a.md` | `## Phase 1: MVP (128 Features)` | `[x](#phase-1-mvp-128-features)` | 0 | clean | Colon, parens removed |
| TV-047 | EC-047 | `a.md` | `## Setup` (×2) | `[x](#setup)` and `[x](#setup-1)` | 0 | clean ×2 | 0-based counter |
| TV-048 | EC-048 | `a.md` | `## Setup` (×3) | `[x](#setup-2)` | 0 | clean | Third occurrence → `-2` |
| TV-049 | EC-049 | `a.md` | `## Foo` (×2) then `## Foo-1` in order | `[a](#foo)`, `[b](#foo-1)`, `[c](#foo-1-1)` | 0 | clean ×3 | DEC-001: second `Foo` collides → `foo-1`; `Foo-1` normalizes to `foo-1` (already taken) → disambiguation while-loop bumps to `foo-1-1`. Implementations using a 1-based counter or not re-entering the loop on secondary collision produce broken for `#foo-1-1`. See also TV-S012. (D-020) |
| TV-050 | EC-050 | `a.md` | `## my_heading` | `[x](#my_heading)` | 0 | clean | Underscore retained |
| TV-051 | EC-051 | `a.md` | `## my_heading` | `[x](#my-heading)` | 1 | broken | Underscore NOT replaced with hyphen |
| TV-052 | EC-052 | `a.md` | `## Café` | `[x](#café)` | 0 | clean | Unicode retained |
| TV-053 | EC-053 | `a.md` | `## Café` | `[x](#caf%C3%A9)` | 0 | clean | Percent-decode fragment before comparison |
| TV-054 | EC-054 | `a.md` | `## 日本語` | `[x](#日本語)` | 0 | clean | CJK retained |
| TV-055 | EC-055 | `a.md` | `## Done ✅` | `[x](#done-)` | 0 | clean | Emoji stripped → `done-`; trailing hyphen NOT trimmed |
| TV-056 | EC-056 | `a.md` | `## **Bold** Heading` | `[x](#bold-heading)` | 0 | clean | Rendered text: `Bold Heading` → `bold-heading` |
| TV-057 | EC-057 | `a.md` | `` ## `code` heading `` | `[x](#code-heading)` | 0 | clean | Rendered text: `code heading` → `code-heading` |
| TV-058 | EC-058 | `a.md` | `## [Link](x.md) heading` | `[x](#link-heading)` | 0 | clean | Rendered text: `Link heading` |
| TV-059 | EC-059 | `a.md` | `Setext Title\n=====` | `[x](#setext-title)` | 0 | clean | Setext headings recognized |
| TV-060 | EC-060 | `a.md` | `####### seven hashes` | `[x](#seven-hashes)` | 1 | broken | 7 hashes is not a heading (CommonMark: ATX must be 1-6) |
| TV-061 | EC-061 | `a.md` | `#NoSpace` (no space after `#`) | `[x](#nospace)` | 1 | broken | Not a heading per CommonMark; no anchor |
| TV-062 | EC-062 | `a.md` | `<a name="legacy"></a>` | `[x](#legacy)` | 0 | clean | HTML name= carve-out |
| TV-063 | EC-063 | `a.md` | `<h2 id="custom">T</h2>` | `[x](#custom)` | 0 | clean | HTML id= carve-out |
| TV-064 | EC-064 | `a.md` | `## Title {#custom}` | `[x](#title-custom)` | 0 | clean | `{#custom}` fed into slug: `title-custom` |
| TV-065 | EC-065 | `a.md` | Fenced block containing `# Fake Heading` | `[x](#fake-heading)` | 1 | broken | Code block headings yield no anchors |
| TV-066 | EC-066 | `a.md` | YAML front matter `title: Foo` + `[x](#foo)` | — | 1 | broken | Front matter skipped; `#foo` anchor absent |
| TV-067 | EC-067 | `a.md` | `## setup` | `[x](#Setup)` (capital S) | 1 | broken | Case-sensitive: `#Setup` ≠ slug `setup` |
| TV-068 | EC-068 | `a.md` | — | `[x](#)` | 0 | clean | Empty anchor → top of document, pass |
| TV-069 | EC-069 | `a.md` | — | `[x](a.md#)` (cross-file empty anchor) | 0 | clean | Cross-file empty anchor → check file exists only |
| TV-070 | EC-070 | `a.md` | `## A` | `[x](a.md#a#b)` | 1 | broken | Fragment = `a#b` (includes second #); no such slug |
| TV-071 | EC-071 | `a.md` | `## setup` | `[x](#setup )` | 0 | clean | Trailing space in fragment trimmed |
| TV-072 | EC-072 | `a.md` | — | `[x](notes.txt#section)` | 0 | clean | Non-MD: anchor check skipped; file exists |
| TV-073 | EC-073 | `a.md` | — | `[x](src/main.rs#L42-L50)` | 0 | clean | Line-range anchor: recognized and skipped |
| TV-074 | EC-074 | `README.md` (flags: `--ignore vendor.md`) | — | `[x](vendor.md#section)` where `vendor.md` has `## Section` | 0 | clean | DEC-003/DI-006: `--ignore` suppresses link-source scanning only; Pass 1 still builds the anchor table for `vendor.md`; the cross-file anchor resolves clean. A false `anchor-not-found` here means the implementation incorrectly skips anchor-table construction for `--ignore`'d targets. (D-020; see also TV-152/EC-152 which tests the same invariant as a general DI-006 fixture) |
| TV-075 | EC-075 | `README.md` | `## setup` | `[x](#setup)`, `[x](README.md#setup)`, `[x](./README.md#setup)` | 0 | clean ×3 | All three equivalent |
| TV-076 | EC-076 | `README.md` | — | `[x](../outside-root/a.md#heading)` | 1 | broken | Outside root; file does not exist |
| TV-152 | EC-152 | `a.md` (flags: `--ignore vendor.md`) | — | `[x](vendor.md#section)` where `vendor.md` has `## Section` | 0 | clean | DI-006 case 1: `--ignore`'d file is still a valid anchor target; Pass 1 builds its anchor table |
| TV-153 | EC-153 | `a.md` (`.gitignore` lists `gitignored.md`) | — | `[x](gitignored.md#section)` where `gitignored.md` has `## Section` | 0 | clean | DI-006 case 2: .gitignore'd file is still a valid anchor target; Pass 1.5 builds its anchor table |
| TV-154 | EC-154 | `README.md` | — | `[x](.vitepress/api.md#setup)` where `.vitepress/api.md` has `## Setup` | 0 | clean | DI-006 case 3: dot-dir .md file is still a valid anchor target; Pass 1.5 builds its anchor table |
| TV-155 | EC-155 | `docs/a.md` | — | `[x](../../sibling-repo/README.md#overview)` where `sibling-repo/README.md` has `## Overview` | 0 | clean | DI-006 case 4: outside-root .md file is still a valid anchor target; Pass 1.5 builds its anchor table |
| TV-157 | EC-157 | `a.md` | — | `[Guide](other.md#caf%C3%A9)` where `other.md` has `## Café` | 0 | clean | Cross-file percent-decoded fragment: `caf%C3%A9` decoded to `café` before slug comparison in cross-file anchor resolver (BC-2.08.003). Distinct from same-file TV-053 — the cross-file path invokes `anchor_resolver.rs` which must also decode before lookup. Root cause of Sphinx bug #13620. (D-020) |
| TV-157b | EC-182 | `a.md` | — | `[Guide](other.md#caf%C3%A9)` where `other.md` has `## Coffee` (no Café heading) | 1 | broken (`anchor-not-found`) | Negative control for TV-157: decoded fragment `café` finds no matching slug in `other.md`. |
| TV-158 | EC-158 | `doc.md` | `## 🚀 Foo` then `## Foo` (in document order) | `[first](#foo)`, `[second](#foo-1)` | 0 | clean ×2 | Emoji-strip before collision counter: both headings produce candidate slug `foo` after emoji removal; counter assigns `foo` to first, `foo-1` to second. If emoji-strip runs AFTER the counter, keys are `🚀 Foo` ≠ `Foo` → no collision detected → `foo-1` remains unassigned → broken. (D-020) |
| TV-158b | EC-183 | `doc.md` | Same two headings plus link `[probe](#foo-2)` | `[first](#foo)`, `[second](#foo-1)`, `[probe](#foo-2)` | 1 | broken (`anchor-not-found`) | Failure probe: only 2 headings exist; `foo-2` has no third occurrence. Confirms the counter stops at the correct upper bound. |
| TV-151 | EC-151 | `a.md` | `<details>` block containing `## Hidden Section` | `[x](#hidden-section)` | 1 | broken (`anchor-not-found`) | Heading inside raw HTML `<details>` block yields no anchor-table entry; `Event::Html` content is not parsed for headings. D-122 burn of formerly-holdout EC-151 (prd.md:618 D-010 note leaked concrete content). |

---

## §4. External URLs (R2c) — EC-077 through EC-150 (excluding EC-079, EC-093, EC-094, EC-147, EC-148)

| TV | EC | Link | Mock Server / Setup | Flags | Expected Exit | Verdict |
|----|-----|------|---------------------|-------|---------------|---------|
| TV-077 | EC-077 | `https://example.com/ok` | Returns 200 to HEAD | `--online` | 0 | clean |
| TV-078 | EC-078 | `https://example.com/head-405` | Returns 405 to HEAD, 200 to GET | `--online` | 0 | clean |
| TV-080 | EC-080 | `https://example.com/head-501` | Returns 501 to HEAD, 200 to GET | `--online` | 0 | clean |
| TV-081 | EC-081 | `https://example.com/server-error` | Returns 500 | `--online` | 0 | indeterminate |
| TV-082 | EC-082 | `https://example.com/rate-limit` | Returns 429 with `Retry-After: 60` | `--online` | 0 | indeterminate |
| TV-083 | EC-083 | `https://example.com/auth` | Returns 401 to HEAD, 401 to GET | `--online` | 0 | indeterminate (auth-gated, not missing) |
| TV-084 | EC-084 | `https://example.com/slow` | Hangs 30s | `--online` | 0 | indeterminate (`http-timeout`) |
| TV-085 | EC-085 | `https://example.com/redirects` | Redirect chain of 12 hops | `--online` | 1 | broken (`too-many-redirects`) |
| TV-086 | EC-086 | `https://a.com/page` | 301 → `http://a.com/page` → 200 | `--online` | 0 | indeterminate (downgrade warning) |
| TV-087 | EC-087 | `https://self-signed.example.com/` | Self-signed TLS cert | `--online` | 1 | broken (`tls-error`) |
| TV-088 | EC-088 | `https://nx-domain-xyz.invalid/` | DNS NXDOMAIN | `--online` | 1 | broken (`dns-failure`) |
| TV-089 | EC-089 | `http://localhost:3000/docs` | — | `--online` | 0 | indeterminate (private IP) |
| TV-090 | EC-090 | `https://example.com/x` (×50 occurrences) | Returns 200 to HEAD | `--online` | 0 | alive ×50 (one fetch, not emitted) |
| TV-091 | EC-091 | `https://example.com/x` | — | `--allow https://example.com --online` | 0 | alive (allowed, not emitted) |
| TV-092 | EC-092 | `https://example.com.evil.tld/x` | — | `--allow https://example.com --online` | 1 | broken (prefix boundary enforced) |
| TV-149 | EC-149 | `https://broken.example.com/x` (referenced at lines 3 and 7 of same file) | DNS NXDOMAIN for `broken.example.com` | `--online` | 1 | broken (`dns-failure`) ×2 with distinct line/column; exactly 1 HTTP request (dedup per BC-2.10.009) |
| TV-150 | EC-150 | `http://example.com/page` and `https://example.com/page` both in corpus | Returns 200 to HEAD for both | `--online` | 0 | alive ×2 (not emitted); 2 HTTP requests (different normalized URLs, not deduplicated) |

---

## §5. Parsing Scope (R3, R4) — EC-095 through EC-123

| TV | EC | Source MD Content | Expected Exit | Expected Verdict | Notes |
|----|-----|-------------------|---------------|-----------------|-------|
| TV-095 | EC-095 | `[text][ref]` with `[ref]: docs/a.md` at EOF; `docs/a.md` exists | 0 | clean | Full reference form |
| TV-096 | EC-096 | `[text][nope]` — label never defined | 1 | broken (`undefined-reference-definition`) | |
| TV-097 | EC-097 | `[ref]: missing.md` defined but never referenced | 0 | none | Unused definitions not reported |
| TV-098 | EC-098 | `[REF]` referencing `[ref]: a.md`; `a.md` exists | 0 | clean | Case-insensitive label match |
| TV-099 | EC-099 | `[ref]` shortcut and `[ref][]` collapsed forms; `[ref]: a.md` defined; `a.md` exists | 0 | clean ×2 | Both forms in scope |
| TV-100 | EC-100 | Two `[ref]:` definitions with different targets; first is valid, second is broken | 0 | clean | First definition wins (CommonMark) |
| TV-101 | EC-101 | `![alt][imgref]` with `[imgref]: logo.png`; `logo.png` exists | 0 | clean | Ref-style image in scope |
| TV-103 | EC-103 | ` ``[x](`a.md)`` ` (double-backtick span containing backtick) | 0 | none | Code span; ignored |
| TV-104 | EC-104 | Fenced block with `[x](missing.md)` | 0 | none | Fenced block ignored |
| TV-105 | EC-105 | `~~~`-fenced block with `[x](missing.md)` | 0 | none | Tilde fence ignored |
| TV-106 | EC-106 | 4-space indented block with `[x](missing.md)` | 0 | none | Indented code block ignored |
| TV-107 | EC-107 | Fence with longer closing marker (7 backticks to close 3-backtick fence) | 0 | none | Correct fence pairing |
| TV-108 | EC-108 | Fence opened, never closed at EOF; `[x](missing.md)` inside | 0 | none | Unclosed fence swallows to EOF (CommonMark) |
| TV-109 | EC-109 | Fence indented inside a list item | 0 | none | Still a fence |
| TV-110 | EC-110 | `<!-- [x](missing.md) -->` HTML comment | 0 | none | Comments ignored |
| TV-111 | EC-111 | `<pre>[x](missing.md)</pre>` | 0 | none | HTML pre/code ignored |
| TV-112 | EC-112 | `\[escaped\](missing.md)` | 0 | none | Escaped brackets not a link |
| TV-113 | EC-113 | Link inside a GFM table cell | 1 | broken (if target missing) | Tables scanned |
| TV-114 | EC-114 | Table cell with escaped pipe in dest: `[x](a\|b.md)` | 1 | broken | Correct dest extraction |
| TV-115 | EC-115 | Link inside blockquote, and inside nested list | 1 | broken (if target missing) | Both scanned |
| TV-116 | EC-116 | `<https://example.com>` CommonMark autolink | 0 (offline) | clean | In scope; syntax-valid offline verdict |
| TV-117 | EC-117 | Bare `https://example.com` in prose (GFM literal autolink) | 0 | none | Out of scope; not extracted |
| TV-118 | EC-118 | `<a href="missing.md">x</a>` raw HTML | 0 | none | Out of scope (non-goal); documented false-negative |
| TV-119 | EC-119 | `<img src="missing.png">` raw HTML | 0 | none | Out of scope |
| TV-120 | EC-120 | `[^1]` footnote + `[^1]: text` definition | 0 | none | Not a reference link |
| TV-121 | EC-121 | Multi-line link destination; line of `[` | 1 | broken | Reports line of opening `[` |
| TV-122 | EC-122 | `[a [b] c](a.md)` nested brackets | 0 | clean | Valid link if `a.md` exists |
| TV-123 | EC-123 | Two broken links on same source line | 1 | broken ×2 | Two findings; different columns |

---

## §6. Flags, Output, Exit Codes (R5, R6, R7) — EC-124 through EC-148 (excluding EC-141, EC-147, EC-148)

| TV | EC | Input | Flags | Expected Exit | Expected Output |
|----|-----|-------|-------|---------------|----------------|
| TV-124 | EC-124 | `docs/a.md` exists; broken link inside | `--ignore 'docs/**'` | 0 | no findings (ignored) |
| TV-124b | EC-179 | `docs/a.md` exists; broken link inside | `--ignore docs` | 0 | no findings (`docs` matches dir and children) |
| TV-125 | EC-125 | All files matched by `*.md` | `--ignore '*.md'` | 0 | warning on stderr; no findings |
| TV-126 | EC-126 | `README.md` with broken link | `README.md --ignore README.md` | 0 | `--ignore` wins; no findings |
| TV-127 | EC-127 | `a.md` and `b.md` both broken | `--ignore a.md --ignore b.md` | 0 | both ignored |
| TV-128 | EC-128 | `docs/a.md` with broken link | `--ignore '!keep.md'` | 1 | negation treated as literal glob (not supported); `!keep.md` does not match `docs/a.md`; findings emitted |
| TV-129 | EC-129 | `[x](https://example.com/x)` | `--allow HTTPS://EXAMPLE.COM` | 0 | allowed (case-normalized) |
| TV-130 | EC-130 | `[x](https://example.com/x)` | `--allow example.com` (no scheme) | 1 | broken (scheme required in prefix) |
| TV-131 | EC-131 | `[x](https://example.com/x)` (offline) | `--allow https://example.com` | 0 | allowed (suppresses syntax validation too) |
| TV-132 | EC-132 | — | `--format xml` | 2 | exit 2, usage error on stderr |
| TV-133 | EC-133 | No broken links | `--format json` | 0 | `{"schema_version":1,"results":[]}` |
| TV-134a | EC-134 | One of each OFFLINE reason type: file-not-found, target-is-directory, broken-symlink, anchor-not-found, undefined-reference-definition, malformed-url | `--format json` | 1 | JSON `results` contains exactly 6 entries, one per offline broken reason code. No http-error/dns-failure/tls-error/too-many-redirects (those require --online). |
| TV-134b | EC-180 | One of each ONLINE reason type, covering all http-related broken codes: http-error, dns-failure, tls-error, too-many-redirects; plus indeterminate: http-timeout, http-indeterminate | `--online --format json` | 1 | JSON `results` contains entries for all online broken/indeterminate reason codes. Together TV-134a + TV-134b exercise all 13 reason codes in the closed taxonomy (NFR-007). |
| TV-135 | EC-135 | Broken link found; diagnostic also occurs | `--format json` | 1 | stdout = pure JSON; stderr = diagnostic only |
| TV-136 | EC-136 | — | `--format json --format text` | 0/1 | last wins: `text` format |
| TV-137 | EC-137 | — | `--unknown-flag` | 2 | exit 2, usage error |
| TV-138 | EC-138 | — | `--help` | 0 | help text on stdout |
| TV-138b | EC-181 | — | `--version` | 0 | version string on stdout |
| TV-139 | EC-139 | file `-weird-name.md` | `-- -weird-name.md` | (depends on links) | File processed correctly |
| TV-140 | EC-140 | Broken link in `docs/` | `docs --format json` | 1 | flag after positional accepted |
| TV-142 | EC-142 | Only an unreadable file | (none) | 2 | exit 2 only |
| TV-143 | EC-143 | Only `--online` indeterminate results (5xx) | `--online` | 0 | exit 0; indeterminate in output |
| TV-144 | EC-144 | Broken link; piped output | `\| cat` (non-TTY) | 1 | no ANSI color codes in output |
| TV-145 | EC-145 | Broken link; `NO_COLOR=1` set | (none) | 1 | no ANSI color codes |
| TV-146 | EC-146 | Long-running scan; SIGINT sent | (none) | 2 | partial output; exit 2 |

---

## §7. Slug Algorithm Vectors (DD-015 Worked Examples)

These are the canonical github-slugger v2 test vectors. ALL must pass as unit tests.

| TV | Heading Text | Expected Slug | Source |
|----|-------------|---------------|--------|
| TV-S001 | `Foo` (first occurrence) | `foo` | DD-015 |
| TV-S002 | `Foo` (second occurrence in same file) | `foo-1` | DD-015 |
| TV-S003 | `Foo` (third occurrence in same file) | `foo-2` | DD-015 |
| TV-S004 | `Hello, World!` | `hello-world` | DD-015 |
| TV-S005 | `Hello,  World!` (two spaces) | `hello--world` | DD-015 |
| TV-S006 | `Привет non-latin 你好` | `привет-non-latin-你好` | DD-015 |
| TV-S007 | `😄 emoji` | `-emoji` | DD-015 (emoji stripped, space→hyphen) |
| TV-S008 | `snake_case_name` | `snake_case_name` | DD-015 (underscore retained) |
| TV-S009 | `C++ / C#` | `c--c` | DD-015 |
| TV-S010 | `` `--online` flag `` | `--online-flag` | DD-015 (backticks stripped, content kept) |
| TV-S011 | `AI & Automation` | `ai--automation` | EC-043 (& removed, two spaces → two hyphens) |
| TV-S012 | `Foo`, `Foo`, `Foo-1` (collision) | `foo`, `foo-1`, `foo-1-1` | DEC-001 (collision-bumping) |
| TV-S013 | `## setup` (with inline code `## setup` inside fenced block) | Only `setup` from the real heading | EC-065 |
| TV-S014 | `## Use \`--online\` **now**` (rendered text: `Use --online now`) | `use---online-now` | market-intel §4.1 |
| TV-S015 | `## Foo <a name="bar"></a>` (rendered text: `Foo `) | `foo-` | market-intel §4.1 (trailing space → trailing hyphen) |
| TV-S016 | `## Done ✅` | `done-` | EC-055 (emoji stripped; trailing hyphen NOT trimmed) |

---

## §8. Correctness Traps (T1–T16)

Each trap from market-intelligence §4.3 has at least one test vector above.

| Trap | TV(s) | Verdict |
|------|-------|---------|
| T1: Code fences | TV-104, TV-105, TV-106, TV-108, TV-109 | covered |
| T2: CommonMark autolinks | TV-116 | covered |
| T3: Raw HTML links out of scope | TV-118, TV-119 | covered |
| T4: Reference definitions whole-document | TV-095, TV-098, TV-100 | covered |
| T5: Undefined references | TV-096 | covered |
| T6: Escaped brackets | TV-112 | covered |
| T7: Nested brackets | TV-122 | covered |
| T8: Angle-bracket destinations | TV-027 | covered |
| T9: Percent-encoding order | TV-053, TV-025 | covered |
| T10: Fragments on dirs/non-MD | TV-072 (non-MD), TV-029 (dir) | covered |
| T11: Empty fragment | TV-068, TV-069 | covered |
| T12: Case-sensitive filename | TV-036 | covered — DI-002/D-006/KD-004: explicit case-sensitive `read_dir` comparison; macOS APFS false-pass eliminated |
| T13: Windows path separators | TV-042 (partial) | **retired (D-043, platform-obsolete)** — Windows is out of scope per macOS-only platform directive. TV-042 is retained and active: on macOS, `\` is also not a path separator, so the broken verdict is correct. T13 as a cross-platform portability trap is obsolete; the macOS-scoped residual is covered by TV-042. |
| T14: Heading with link syntax | TV-058 | covered |
| T15: Forward heading reference | TV-047 (implicit) + DEC-002 corpus | covered |
| T16: Path above scan root | TV-076 (file absent) | not-covered — TV-076 is broken because the target file does not exist (relative path to a nonexistent file outside git root), not because of scan-root boundary enforcement. TV-024 establishes there is no scan-root boundary for relative links. A root-relative path (starting with `/`) with `..` traversal above git root on an existing file (per BC-2.07.002) has no dedicated vector; boundary enforcement for root-relative paths is untested. |

---

## §9. Real-World Corpus Scenarios

### 9.1 Known-Good Corpus

**Corpus:** Rust standard library documentation (`std` crate from `rust-lang/rust`), specifically the `library/std/src/` Markdown files.

**Why known-good:** Well-maintained by the Rust team; all internal links are systematically verified by the team's own tooling; very few or zero broken links expected.

**Expected result:** Zero `broken` findings, zero `broken-symlink` findings. A small number of `indeterminate` on external URLs in `--online` mode is acceptable.

**Setup:**

```sh
git clone --depth=1 https://github.com/rust-lang/rust.git /tmp/rust-corpus
mdlinkcheck /tmp/rust-corpus/library/std/src/
```

**Pass criterion:** Exit 0.

### 9.2 Known-Problematic Corpus

**Corpus:** The acceptance corpus in `tests/corpus/fixtures/broken-links/` — synthetic files with one planted broken link per failure class.

**Why known-problematic:** Each file is designed with a specific, known broken link. Expected result: every planted break found, every valid-link trap NOT found (zero false positives).

**Expected result:** Exactly the findings listed in `tests/corpus/manifest.json`.

**Setup:**

```sh
mdlinkcheck --format json tests/corpus/fixtures/ > /tmp/corpus-result.json
```

**Pass criterion:** JSON output matches `tests/corpus/manifest.json` exactly (modulo ordering, which must itself match the sorted order).

---

## §10. Supplementary Edge Case Registrations (EC-159..EC-213)

Rows in this section register ECs that were named in BC edge-case tables after
test-vectors.md v1.6 was produced. Each row is the minimal registration needed
by POL-16; full scenario detail lives in the BC file referenced in the Description.

### §10.1 Anchor Resolution (SS-08) — EC-159, EC-160

| TV | EC | Description | Flags | Exit | Verdict | Notes |
|----|----|-------------|-------|------|---------|-------|
| TV-159 | EC-159 | `a.md` has `[x](b.md#setup)`; `b.md` ignored as source but has `## Setup` | `--ignore b.md` | 0 | clean | Anchor table built for ignored-source `b.md` (DI-006); cross-file anchor found (BC-2.08.004) |
| TV-160 | EC-160 | `a.md` has `[x](b.md#missing)`; `b.md` ignored as source, no `## Missing` | `--ignore b.md` | 1 | broken (`anchor-not-found`) | Anchor table built for ignored-source `b.md`; fragment not found |

### §10.2 Filter Application (SS-11) — EC-161..EC-163

| TV | EC | Description | Flags | Exit | Verdict | Notes |
|----|----|-------------|-------|------|---------|-------|
| TV-161 | EC-161 | URL `https://example.com/path` against prefix `https://example.com` | `--allow https://example.com` | n/a | exempt | Component boundary `/` → prefix matches at boundary |
| TV-162 | EC-162 | URL `https://example.com.evil.tld/` against prefix `https://example.com` | `--allow https://example.com` | n/a | not exempt | Boundary safety: next char after prefix is `.`, not `/` or end |
| TV-163 | EC-163 | URL `https://example.comX/path` against prefix `https://example.com` | `--allow https://example.com` | n/a | not exempt | Boundary safety: next char is `X`, not `/` or end |

### §10.3 Relative Path Resolution (SS-07) — EC-164

| TV | EC | Description | Flags | Exit | Verdict | Notes |
|----|----|-------------|-------|------|---------|-------|
| TV-164 | EC-164 | `[x](docs#section)` where `docs` is a directory, fragment present | (none) | 1 | broken (`target-is-directory`) | Directory target with fragment always broken; no anchor lookup attempted |

### §10.4 Holdout-Alias Replacements — EC-169..EC-177

These ECs replace the sub-lettered holdout aliases EC-141b, EC-079b, EC-079c, EC-094a–e
that were renamed per POL-18 (holdout sub-letter prohibition).

| TV | EC | Description | Flags | Exit | Verdict | Notes |
|----|----|-------------|-------|------|---------|-------|
| TV-169 | EC-169 | 1 broken link + invalid `--format` flag | `--format bad` | 2 | exit 2 (config error beats broken) | Exit 2 beats exit 1 (DI-011); see BC-2.14.002 |
| TV-170 | EC-170 | Future JSON schema version does not break existing consumers | `--format json` | n/a | schema_version integer 1 | Formerly EC-141b in BC-2.13.002; JSON schema stability (BC-2.13.002) |
| TV-171 | EC-171 | URL connection times out (server takes 15s, timeout is 10s) | `--online` | 0 | indeterminate (`http-timeout`) | Timeout is indeterminate not broken (DI-010); see BC-2.10.003 |
| TV-172 | EC-172 | HTTPS target with self-signed certificate | `--online` | 1 | broken (`tls-error`) | TLS always enforced; no --insecure flag (D-011); see BC-2.10.006 |
| TV-173 | EC-173 | Link with `mailto:a@b.com` scheme | (none) | 0 | no findings (silently skipped) | Formerly EC-094a in BC-2.03.005; non-http(s) silently skipped |
| TV-174 | EC-174 | Link with `ftp://x/y` scheme | (none) | 0 | no findings (silently skipped) | Formerly EC-094b in BC-2.03.005 |
| TV-175 | EC-175 | Link with `tel:+15551234` scheme | (none) | 0 | no findings (silently skipped) | Formerly EC-094c in BC-2.03.005 |
| TV-176 | EC-176 | Link with `javascript:void(0)` scheme | (none) | 0 | no findings (silently skipped) | Formerly EC-094d in BC-2.03.005 |
| TV-177 | EC-177 | Link with `//example.com/x` (protocol-relative) | (none) | 0 | no findings (silently skipped) | Formerly EC-094e in BC-2.03.005 |

### §10.5 EC-178..EC-183 — Disambiguation IDs for Multi-Variant Test Vectors

These EC-NNNs resolve EC injectivity collisions (POL-16). Each EC-NNN below is already
registered by the corresponding TV-NNNb row in its original section. This sub-section
exists as an index only — do NOT add table rows here (that would create duplicate
registrations and re-introduce the injectivity violation).

| EC | TV-NNNb (registered in) | Original Collision |
|----|------------------------|--------------------|
| EC-178 | TV-015b (§1) | Disambiguates TV-015 (clean) vs TV-015b (broken) |
| EC-179 | TV-124b (§6) | Disambiguates `--ignore 'docs/**'` vs `--ignore docs` |
| EC-180 | TV-134b (§6) | Disambiguates offline (TV-134a) vs online (TV-134b) reason codes |
| EC-181 | TV-138b (§6) | Disambiguates `--help` vs `--version` |
| EC-182 | TV-157b (§3) | Negative control for percent-decoded cross-file anchor (D-020) |
| EC-183 | TV-158b (§3) | Failure probe for emoji-strip slug counter (D-020) |

### §10.6 EC-184..EC-204 — Adversary Pass 4 Collision-Remapping Registry

These ECs were introduced during adversary pass 4 + consistency pass 4 remediation (phase-1d)
to resolve EC-ID collisions. Each ID is the canonical identifier for its described edge case,
replacing a previously colliding ID in the referencing BC.

| TV | EC | Description | BC Owner | Flags | Exit | Verdict | Notes |
|----|----|-------------|----------|-------|------|---------|-------|
| TV-184 | EC-184 | Directory argument contains no .md files | BC-2.01.008, BC-2.14.001 | (none) | 0 | clean (no findings) | Formerly EC-009 in these BCs; EC-009 owned by TV-009 (symlink outside root) |
| TV-185 | EC-185 | `mdlinkcheck good_dir/ nonexistent_dir/` — good_dir has 1 broken link; nonexistent_dir absent | BC-2.01.009 | (none) | 2 | exit 2 (I/O error); broken finding from good_dir | Formerly EC-014; EC-014 owned by TV-014 (ISO-8859-1 file); distinguishing vector for DD-007 no-fail-fast |
| TV-186 | EC-186 | `[x](readme.md)` but file is `README.md` (case-sensitive filesystem) | BC-2.07.003 | (none) | 1 | broken (file-not-found) | Formerly EC-029; EC-029 owned by TV-029 (directory link `docs/`) |
| TV-187 | EC-187 | NFC vs NFD normalization in filename (macOS APFS stores filenames in NFD) | BC-2.07.003 | (none) | 1 | broken (file-not-found) on mismatched form | Formerly EC-030; EC-030 owned by TV-030 (dir link `docs` no slash); ADR-008: no normalization applied |
| TV-188 | EC-188 | Unicode filename with mixed case (e.g., `README.Md` target vs `readme.md` on disk) | BC-2.07.003 | (none) | 1 | broken (file-not-found) | Formerly EC-031; EC-031 owned by TV-031 (empty link `[x]()`) |
| TV-189 | EC-189 | `[x](path%23with-hash.md)` — percent-encoded `#` in path segment | BC-2.07.004 | (none) | 1 | broken (file-not-found) | Formerly EC-034; EC-034 owned by TV-034 (trailing slash `a.md/`); `%23` decoded → path contains literal `#` |
| TV-190 | EC-190 | `## 🦀Rust` then `## 🎯Rust` in same file | BC-2.06.001 | (none) | n/a | slugs: `rust`, `rust-1` | Formerly EC-060 in BC-2.06.001; EC-060 owned by TV-060 (7-hash non-heading); emoji-collision; 0-based counter keyed on "rust" per DI-012 |
| TV-191 | EC-191 | `[x](#setup)` where `## Setup` exists in same file | BC-2.08.001 | (none) | 0 | clean | Formerly EC-060 in BC-2.08.001; self-file anchor found |
| TV-192 | EC-192 | `--ignore '*.md'` — glob excludes all .md source files; 0 files scanned | BC-2.11.001 | `--ignore '*.md'` | 0 | no findings | Formerly EC-072; EC-072 owned by TV-072 (non-MD anchor check skipped) |
| TV-193 | EC-193 | `--ignore 'docs/a.md'` — exact-path glob excludes one source file | BC-2.11.001 | `--ignore 'docs/a.md'` | 0 or 1 | docs/a.md excluded as source | Formerly EC-073; EC-073 owned by TV-073 (line-range anchor skipped) |
| TV-194 | EC-194 | `[x](#)` empty anchor (bare hash) | BC-2.08.001 | (none) | 0 | clean (top-of-page convention) | Formerly EC-075 in BC-2.08.001; EC-075 owned by TV-075 (three equivalent anchor forms); bare `#` is clean per BC-2.08.001 PC5 |
| TV-195 | EC-195 | `a.md` links `[x](b.md#intro)` and `b.md` has `## Intro` | BC-2.05.001 | (none) | 0 | clean | Formerly EC-075 in BC-2.05.001; cross-file anchor found |
| TV-196 | EC-196 | `a.md` links `[x](b.md#intro)` but `b.md` has no `## Intro` heading | BC-2.05.001 | (none) | 1 | broken (anchor-not-found) | Formerly EC-076 in BC-2.05.001; EC-076 owned by TV-076 (outside scan root); cross-file anchor not found |
| TV-197 | EC-197 | `[x](a.md##double-hash)` — malformed fragment with double `#` | BC-2.08.003 | (none) | 1 | broken (anchor-not-found) | Formerly EC-076 in BC-2.08.003; double-`#` splits to fragment `#double-hash` per BC-2.08.003; anchor lookup fails → anchor-not-found (D-164) |
| TV-198 | EC-198 | HTTP 429 response (server rate-limits request) | BC-2.10.002 | `--online` | 0 | indeterminate (http-indeterminate) | Formerly EC-087 in BC-2.10.002; EC-087 owned by TV-087 (self-signed TLS); 429 → indeterminate per DI-010 |
| TV-199 | EC-199 | 429 response with `Retry-After: 30` (delta-seconds) | BC-2.10.004 | `--online` | 0 | indeterminate; host paused 30s | Formerly EC-087 in BC-2.10.004; delta-seconds form per RFC 9110 §10.2.3 |
| TV-200 | EC-200 | `--allow https://example.com`; URL `https://example.com/page` (prefix match) | BC-2.09.002 | `--allow https://example.com` | 0 | exempt (not checked online) | Formerly EC-090 in BC-2.09.002; EC-090 owned by TV-090 (50x same URL deduplication) |
| TV-201 | EC-201 | HTTP 401 response on GitHub raw content URL (private repo) | BC-2.10.002 | `--online` | 0 | indeterminate (http-indeterminate) | Formerly EC-090 in BC-2.10.002; 401 → indeterminate per DI-010 |
| TV-202 | EC-202 | `[x][ref]` on line 3 and line 7; `[ref]: missing.md` at EOF | BC-2.03.002 | (none) | 1 | broken ×2; findings at line 3 and line 7 | P4-005 use-site position; definition-site attribution forbidden per BC-2.03.002 Invariant 4 |
| TV-203 | EC-203 | Redirect chain of 11 hops | BC-2.10.007 | `--online` | 1 | broken (too-many-redirects) | Formerly EC-087e in BC-2.10.007; EC-087e now owned by BC-2.10.004 (P4-015 malformed Retry-After) |
| TV-204 | EC-204 | HTTP → HTTPS upgrade redirect (single hop) | BC-2.10.007 | `--online` | 0 | clean (redirect followed) | Formerly EC-087f in BC-2.10.007; EC-087f now owned by BC-2.10.004 (P4-015 clamped Retry-After) |

### §10.7 Non-Markdown Target Resolution (SS-07) — EC-205, EC-206

| TV | EC | Description | Flags | Exit | Verdict | Notes |
|----|----|-------------|-------|------|---------|-------|
| TV-205 | EC-205 | `[x](assets/logo.png#anchor)` where `assets/logo.png` exists | (none) | 0 | clean | Image file; fragment silently ignored per BC-2.07.006 |
| TV-206 | EC-206 | `[x](scripts/build.sh)` where `scripts/build.sh` does not exist | (none) | 1 | broken (`file-not-found`) | Non-.md file existence check; file-not-found path per BC-2.07.006 PC4 |

### §10.8 Filter Application — Invalid Glob (SS-11) — EC-207, EC-208

| TV | EC | Description | Flags | Exit | Verdict | Notes |
|----|----|-------------|-------|------|---------|-------|
| TV-207 | EC-207 | `mdlinkcheck . --ignore '[abc'` (unclosed bracket) | `--ignore '[abc'` | 2 | Exit 2; error on stderr; no scanning | globset rejects unclosed bracket at startup; fail-fast before traversal per BC-2.11.004 |
| TV-208 | EC-208 | `mdlinkcheck . --ignore 'valid/**' --ignore '[bad'` | `--ignore 'valid/**' --ignore '[bad'` | 2 | Exit 2 on first invalid; no scanning | One invalid glob triggers exit 2 even when a sibling glob is valid per BC-2.11.004 |

### §10.9 Text Output Stream Separation (SS-12) — EC-209, EC-210

| TV | EC | Description | Flags | Exit | Verdict | Notes |
|----|----|-------------|-------|------|---------|-------|
| TV-209 | EC-209 | No broken or indeterminate findings (clean corpus) | (none) | 0 | stdout empty; stderr: "No broken links found." | Zero-findings stream separation per BC-2.12.005 |
| TV-210 | EC-210 | `a.md` containing 2 broken links | (none) | 1 | stdout: 2 finding lines; stderr: "2 broken link(s) in 1 file(s)." | Multi-finding stream separation per BC-2.12.005 |

### §10.10 Help and Version Flags (SS-14) — EC-211, EC-212, EC-213

| TV | EC | Description | Flags | Exit | Verdict | Notes |
|----|----|-------------|-------|------|---------|-------|
| TV-211 | EC-211 | `mdlinkcheck --help` with no PATH argument | `--help` | 0 | full help text on stdout; no scanning | clap intercepts before app::run(); no DirIndex or AnchorIndex constructed per BC-2.14.004 Invariant 4 |
| TV-212 | EC-212 | `mdlinkcheck --version` | `--version` | 0 | `mdlinkcheck X.Y.Z` on stdout; no scanning | Version string matches Cargo.toml; no scanning per BC-2.14.004 |
| TV-213 | EC-213 | `mdlinkcheck . --version` (PATH + --version together) | `--version` (with PATH) | 0 | version string on stdout; --version takes priority | clap intercepts --version before PATH processing per BC-2.14.004 Invariant 4 |

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.12 | 2026-08-10 | GATE-58 CLOSED-WORLD remediation (D-117 phantom codes): TV-116 verdict column corrected — parenthetical descriptor stripped, bare `clean` retained; TV-197 verdict corrected from phantom code to `anchor-not-found` (##double-hash splits to fragment #double-hash per BC-2.08.003; anchor lookup fails per D-164 precedent). |
| 1.11 | 2026-08-10 | EC-151 burned per D-122: holdout designation retired; TV-151 added to §3 (heading inside `<details>` HTML block × same-file anchor). EC-214 (HS-008) allocated as replacement holdout in same risk cluster (cross-file variant, `<div>` element). Holdout WARNING updated: EC-151 removed, EC-214 added; burned-list sentence updated. Intro range updated: EC-001..EC-213 → EC-001..EC-214; 212 → 213 edge cases registered; 213 → 214 IDs allocated. |
| 1.10 | 2026-08-07 | EC-205..EC-213 allocated (§10.7..§10.10): SS-07 EC-205..EC-206 (non-MD target resolution, BC-2.07.006), SS-11 EC-207..EC-208 (invalid --ignore glob, BC-2.11.004), SS-12 EC-209..EC-210 (text stream separation, BC-2.12.005), SS-14 EC-211..EC-213 (--help/--version, BC-2.14.004). §10 range updated to EC-159..EC-213. Intro range updated to EC-001..EC-213. input-hash corrected to 07d983a. |
| 1.9 | 2026-08-06 | D-043 (macOS-only platform directive): T13 retired as platform-obsolete (kept with note; TV-042 macOS-scoped residual retained); TV-036 description updated (removed Linux CI cross-platform framing; restated per D-043 determinism rationale); TV-041 fixture description updated ("Linux/macOS" → "macOS"); TV-042 fixture description updated ("Linux FS" → "macOS FS"); TV-187 description updated (removed "Linux NFC" reference; macOS APFS NFD context only) |
| 1.8 | 2026-08-05 | POL-16 EC injectivity remediation; EC-159..EC-204 registered in §10; holdout WARNING updated; CRLF column offset note added; §10 collision-remapping registry |
