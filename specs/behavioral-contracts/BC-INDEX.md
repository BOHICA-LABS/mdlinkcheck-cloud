---
document_type: bc-index
level: L3
version: "1.7"
status: draft
producer: vsdd-factory:product-owner
timestamp: 2026-08-05T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities.md
input-hash: "c3e82ce"
traces_to: .factory/specs/prd.md
total_bcs: 66
subsystems: 14
---

# BC-INDEX — Behavioral Contract Registry

Master index of all behavioral contracts for mdlinkcheck. Each entry links to a
self-contained contract file. The H1 title in each file is the authoritative title
(see `bc_h1_is_title_source_of_truth` policy).

**Legend:** P0 = must-have for v1.0 release; P1 = important; P2 = enhancement.

---

## SS-01 — File Discovery (CAP-001)

| BC ID | Title | Priority | File |
|-------|-------|----------|------|
| BC-2.01.001 | Recursive `.md` Discovery with Default Scan Root | P0 | [ss-01/BC-2.01.001.md](ss-01/BC-2.01.001.md) |
| BC-2.01.002 | Explicit PATH Arguments Override Default Root | P0 | [ss-01/BC-2.01.002.md](ss-01/BC-2.01.002.md) |
| BC-2.01.003 | `.gitignore` and `.ignore` Exclusion During Traversal | P0 | [ss-01/BC-2.01.003.md](ss-01/BC-2.01.003.md) |
| BC-2.01.004 | Dot-Directory Skip (Unconditional) and Directory-Symlink Non-Following | P0 | [ss-01/BC-2.01.004.md](ss-01/BC-2.01.004.md) |
| BC-2.01.005 | Extension Matching — `.md` Only, Case-Sensitive | P0 | [ss-01/BC-2.01.005.md](ss-01/BC-2.01.005.md) |
| BC-2.01.006 | File Symlink Following with Dangling-Symlink Detection | P1 | [ss-01/BC-2.01.006.md](ss-01/BC-2.01.006.md) |
| BC-2.01.007 | Path Deduplication for Overlapping PATH Arguments | P1 | [ss-01/BC-2.01.007.md](ss-01/BC-2.01.007.md) |
| BC-2.01.008 | Zero Markdown Files Found Yields Exit 0 with Stderr Message | P0 | [ss-01/BC-2.01.008.md](ss-01/BC-2.01.008.md) |
| BC-2.01.009 | Non-Existent or Unreadable PATH Argument Yields Exit 2 | P0 | [ss-01/BC-2.01.009.md](ss-01/BC-2.01.009.md) |

---

## SS-02 — Markdown Parsing (CAP-002)

| BC ID | Title | Priority | File |
|-------|-------|----------|------|
| BC-2.02.001 | CommonMark + GFM AST Parsing with Byte-Offset Line Numbers | P0 | [ss-02/BC-2.02.001.md](ss-02/BC-2.02.001.md) |
| BC-2.02.002 | UTF-8 BOM Stripping and CRLF Normalization (Shell-Side) | P0 | [ss-02/BC-2.02.002.md](ss-02/BC-2.02.002.md) |
| BC-2.02.003 | Non-UTF-8 File Reported as Per-File I/O Error; Scan Continues | P0 | [ss-02/BC-2.02.003.md](ss-02/BC-2.02.003.md) |
| BC-2.02.004 | Explicit Non-`.md` File Argument Is Parsed (Not Skipped) | P1 | [ss-02/BC-2.02.004.md](ss-02/BC-2.02.004.md) |

---

## SS-03 — Link Extraction (CAP-003)

| BC ID | Title | Priority | File |
|-------|-------|----------|------|
| BC-2.03.001 | Inline Link and Image Extraction with Kind Classification | P0 | [ss-03/BC-2.03.001.md](ss-03/BC-2.03.001.md) |
| BC-2.03.002 | Full Reference-Style, Collapsed, and Shortcut Link/Image Forms | P0 | [ss-03/BC-2.03.002.md](ss-03/BC-2.03.002.md) |
| BC-2.03.003 | Undefined Reference Label Yields `broken` Verdict | P0 | [ss-03/BC-2.03.003.md](ss-03/BC-2.03.003.md) |
| BC-2.03.004 | CommonMark Autolinks In Scope; GFM Bare-URLs Out of Scope | P0 | [ss-03/BC-2.03.004.md](ss-03/BC-2.03.004.md) |
| BC-2.03.005 | Non-http(s) Schemes Silently Skipped with `clean` Verdict | P0 | [ss-03/BC-2.03.005.md](ss-03/BC-2.03.005.md) |
| BC-2.03.006 | Footnote References Excluded; Escaped Brackets Are Not Links | P1 | [ss-03/BC-2.03.006.md](ss-03/BC-2.03.006.md) |

---

## SS-04 — Code Context Exclusion (CAP-004)

| BC ID | Title | Priority | File |
|-------|-------|----------|------|
| BC-2.04.001 | Fenced Code Blocks and Inline Code Spans Yield No Links | P0 | [ss-04/BC-2.04.001.md](ss-04/BC-2.04.001.md) |
| BC-2.04.002 | Indented Code Blocks and HTML Comments Yield No Links | P0 | [ss-04/BC-2.04.002.md](ss-04/BC-2.04.002.md) |
| BC-2.04.003 | ATX Headings Inside Fenced Blocks Do Not Create Anchor Entries | P0 | [ss-04/BC-2.04.003.md](ss-04/BC-2.04.003.md) |

---

## SS-05 — Anchor Table Construction (CAP-005)

| BC ID | Title | Priority | File |
|-------|-------|----------|------|
| BC-2.05.001 | Three-Phase Design — Full Anchor Table Before Any Resolution | P0 | [ss-05/BC-2.05.001.md](ss-05/BC-2.05.001.md) |
| BC-2.05.002 | ATX and Setext Heading Extraction into Anchor Table | P0 | [ss-05/BC-2.05.002.md](ss-05/BC-2.05.002.md) |
| BC-2.05.003 | HTML `id=` and `name=` Attribute Extraction into Anchor Table | P1 | [ss-05/BC-2.05.003.md](ss-05/BC-2.05.003.md) |

---

## SS-06 — Heading Slug Computation (CAP-006)

| BC ID | Title | Priority | File |
|-------|-------|----------|------|
| BC-2.06.001 | github-slugger v2 Core Algorithm | P0 | [ss-06/BC-2.06.001.md](ss-06/BC-2.06.001.md) |
| BC-2.06.002 | github-slugger v2 Duplicate-Heading Counter with Collision Bump | P0 | [ss-06/BC-2.06.002.md](ss-06/BC-2.06.002.md) |

---

## SS-07 — Relative Path Resolution (CAP-007)

| BC ID | Title | Priority | File |
|-------|-------|----------|------|
| BC-2.07.001 | Relative Path Resolution Against Source File's Directory | P0 | [ss-07/BC-2.07.001.md](ss-07/BC-2.07.001.md) |
| BC-2.07.002 | Root-Relative Link Resolution Using Git Repo Root | P1 | [ss-07/BC-2.07.002.md](ss-07/BC-2.07.002.md) |
| BC-2.07.003 | NFC Normalization and Case-Sensitive Exact Directory-Entry Comparison | P0 | [ss-07/BC-2.07.003.md](ss-07/BC-2.07.003.md) |
| BC-2.07.004 | Percent-Encoding in File Path Destinations | P1 | [ss-07/BC-2.07.004.md](ss-07/BC-2.07.004.md) |
| BC-2.07.005 | Destination-Is-Directory Verdict | P0 | [ss-07/BC-2.07.005.md](ss-07/BC-2.07.005.md) |
| BC-2.07.006 | Non-Markdown Target — File Existence Check Only, Anchor Resolution Skipped | P0 | [ss-07/BC-2.07.006.md](ss-07/BC-2.07.006.md) |
| BC-2.07.007 | Empty Link Destination → Malformed URL | P0 | [ss-07/BC-2.07.007.md](ss-07/BC-2.07.007.md) |
| BC-2.07.008 | Trailing Slash on Regular File → file-not-found | P0 | [ss-07/BC-2.07.008.md](ss-07/BC-2.07.008.md) |

---

## SS-08 — Anchor Resolution (CAP-008)

| BC ID | Title | Priority | File |
|-------|-------|----------|------|
| BC-2.08.001 | Anchor-Only Link Resolution (`#fragment`) | P0 | [ss-08/BC-2.08.001.md](ss-08/BC-2.08.001.md) |
| BC-2.08.002 | Cross-File Anchor Resolution (`path.md#fragment`) | P0 | [ss-08/BC-2.08.002.md](ss-08/BC-2.08.002.md) |
| BC-2.08.003 | Fragment Split at First Unescaped `#` Before Percent-Decode | P0 | [ss-08/BC-2.08.003.md](ss-08/BC-2.08.003.md) |
| BC-2.08.004 | Cross-File Anchor Into Ignored-Source File | P1 | [ss-08/BC-2.08.004.md](ss-08/BC-2.08.004.md) |

---

## SS-09 — External URL Syntax Validation (CAP-009)

| BC ID | Title | Priority | File |
|-------|-------|----------|------|
| BC-2.09.001 | External URL Syntax Validation (Offline) | P0 | [ss-09/BC-2.09.001.md](ss-09/BC-2.09.001.md) |
| BC-2.09.002 | `--allow` URL Exemption — Specification in BC-2.11.002 | P0 | [ss-09/BC-2.09.002.md](ss-09/BC-2.09.002.md) |

---

## SS-10 — External URL Liveness Checking (CAP-010)

| BC ID | Title | Priority | File |
|-------|-------|----------|------|
| BC-2.10.001 | HEAD-then-GET Fallback Protocol (`--online` mode) | P0 | [ss-10/BC-2.10.001.md](ss-10/BC-2.10.001.md) |
| BC-2.10.002 | Three-Verdict Model (alive/broken/indeterminate) — Total Partition | P0 | [ss-10/BC-2.10.002.md](ss-10/BC-2.10.002.md) |
| BC-2.10.003 | Per-URL 10-Second Timeout | P0 | [ss-10/BC-2.10.003.md](ss-10/BC-2.10.003.md) |
| BC-2.10.004 | 429 Rate-Limit Handling — Pause Host, Resume After Retry-After | P0 | [ss-10/BC-2.10.004.md](ss-10/BC-2.10.004.md) |
| BC-2.10.005 | DNS Resolution Failure Yields `broken` Verdict | P0 | [ss-10/BC-2.10.005.md](ss-10/BC-2.10.005.md) |
| BC-2.10.006 | TLS Handshake Failure Behavior | P0 | [ss-10/BC-2.10.006.md](ss-10/BC-2.10.006.md) |
| BC-2.10.007 | Redirect Chain Handling (Max 10 Hops) | P0 | [ss-10/BC-2.10.007.md](ss-10/BC-2.10.007.md) |
| BC-2.10.008 | Concurrency — Dedicated Pool, 32 Global / 4 Per-Host Request Limits | P1 | [ss-10/BC-2.10.008.md](ss-10/BC-2.10.008.md) |
| BC-2.10.009 | URL Deduplication — Each Unique External URL Fetched Once, Verdict Reported at Every Occurrence | P0 | [ss-10/BC-2.10.009.md](ss-10/BC-2.10.009.md) |
| BC-2.10.010 | Private-IP and Link-Local URL Classification (Indeterminate, No Outbound Request) | P0 | [ss-10/BC-2.10.010.md](ss-10/BC-2.10.010.md) |

---

## SS-11 — Filter Application (CAP-011)

| BC ID | Title | Priority | File |
|-------|-------|----------|------|
| BC-2.11.001 | `--ignore` Glob Exclusion (Source Files Only) | P0 | [ss-11/BC-2.11.001.md](ss-11/BC-2.11.001.md) |
| BC-2.11.002 | `--allow` URL Prefix Exemption with Component-Boundary Safety | P0 | [ss-11/BC-2.11.002.md](ss-11/BC-2.11.002.md) |
| BC-2.11.003 | `--ignore` on Explicit PATH Argument | P1 | [ss-11/BC-2.11.003.md](ss-11/BC-2.11.003.md) |
| BC-2.11.004 | Invalid `--ignore` Glob → Exit 2 Before Scanning Begins | P0 | [ss-11/BC-2.11.004.md](ss-11/BC-2.11.004.md) |

---

## SS-12 — Text Report Generation (CAP-012)

| BC ID | Title | Priority | File |
|-------|-------|----------|------|
| BC-2.12.001 | Text Report Format — One Finding per Line, Deterministic Order | P0 | [ss-12/BC-2.12.001.md](ss-12/BC-2.12.001.md) |
| BC-2.12.002 | Terminal Color Output with NO_COLOR / CLICOLOR / CLICOLOR_FORCE | P1 | [ss-12/BC-2.12.002.md](ss-12/BC-2.12.002.md) |
| BC-2.12.003 | Stderr Summary Line (Always Emitted) | P0 | [ss-12/BC-2.12.003.md](ss-12/BC-2.12.003.md) |
| BC-2.12.004 | `--format text` Explicit Alias Is Accepted | P1 | [ss-12/BC-2.12.004.md](ss-12/BC-2.12.004.md) |
| BC-2.12.005 | Stdout/Stderr Separation for Text Format | P0 | [ss-12/BC-2.12.005.md](ss-12/BC-2.12.005.md) |

---

## SS-13 — JSON Report Generation (CAP-013)

| BC ID | Title | Priority | File |
|-------|-------|----------|------|
| BC-2.13.001 | JSON Report Format — `{"schema_version":1,"results":[...],"errors":[...]}` to Stdout | P0 | [ss-13/BC-2.13.001.md](ss-13/BC-2.13.001.md) |
| BC-2.13.002 | JSON Schema Stability Contract | P1 | [ss-13/BC-2.13.002.md](ss-13/BC-2.13.002.md) |

---

## SS-14 — Exit Code Determination (CAP-014)

| BC ID | Title | Priority | File |
|-------|-------|----------|------|
| BC-2.14.001 | Exit Code 0 — No Broken Links | P0 | [ss-14/BC-2.14.001.md](ss-14/BC-2.14.001.md) |
| BC-2.14.002 | Exit Code 2 Takes Precedence Over Exit Code 1 | P0 | [ss-14/BC-2.14.002.md](ss-14/BC-2.14.002.md) |
| BC-2.14.003 | Exit Code 1 — At Least One Broken Link Found | P0 | [ss-14/BC-2.14.003.md](ss-14/BC-2.14.003.md) |
| BC-2.14.004 | `--help` and `--version` Exit 0 Without Scanning | P0 | [ss-14/BC-2.14.004.md](ss-14/BC-2.14.004.md) |

---

## Summary Statistics

| Metric | Count |
|--------|-------|
| Total BCs | 66 |
| P0 (must-have) | 53 |
| P1 (important) | 13 |
| Subsystems | 14 (SS-01..SS-14) |
| CAPs covered | CAP-001..CAP-014 (all) |

## Domain Invariant Coverage

| DI-NNN | Description | Enforcing BCs |
|--------|-------------|---------------|
| DI-001 | Deterministic output order (NFC path, line, col, link_target) | BC-2.12.001, BC-2.13.001 |
| DI-002 | Case-sensitive NFC path comparison; never delegate to OS | BC-2.07.003, BC-2.07.004 |
| DI-003 | Fragment split at first unescaped `#` before percent-decode | BC-2.08.003, BC-2.07.004, BC-2.07.001 |
| DI-004 | Code context exclusion is structural (AST), not heuristic | BC-2.04.001, BC-2.04.002, BC-2.04.003 |
| DI-005 | Each link receives exactly one verdict | BC-2.03.001, BC-2.03.003, BC-2.07.006 |
| DI-006 | `--ignore` is source-only; anchor tables built for ignored files | BC-2.01.003, BC-2.05.001, BC-2.08.004, BC-2.11.001 |
| DI-007 | HTML Anchor Extraction Scope Is Narrow | BC-2.05.001 (anchor_table module enforces scope per Invariant 3), VP-020 (integration test-sufficient; ensures no over-extraction) |
| DI-008 | Three-phase (Pass 1 → Pass 1.5 → Pass 2): anchor table complete before any link resolution | BC-2.05.001, BC-2.08.001, BC-2.08.002 |
| DI-009 | Scan Terminates for Any Input (directory-symlink cycles, overlapping PATHs, zero-file trees, out-of-scan-set reads all terminate) | BC-2.01.004, BC-2.01.001, BC-2.05.001 (Pass 1.5 termination) |
| DI-010 | Three-verdict model: alive/broken/indeterminate (429/5xx/timeout → indeterminate) | BC-2.10.002, BC-2.14.003 |
| DI-011 | Exit 2 beats exit 1; no fail-fast | BC-2.01.009, BC-2.02.003, BC-2.14.002 |
| DI-012 | Slug Computation Fidelity — per-heading character-level transformation must exactly match DD-015 github-slugger v2 algorithm (HTML text retained, emoji stripped, case-fold, non-word stripped) | BC-2.06.001 |
| DI-013 | Anchor-Key Uniqueness within a File — duplicate-counter produces injective mapping; 0-based suffix (`-1` for 2nd occurrence, `-(N-1)` for N-th) | BC-2.06.002 |

## Requirements Traceability (R1–R8)

Per frozen BRIEF.md: R1=file discovery, R2a=relative file links, R2b=heading anchors,
R2c=external URLs (--online), R3=reference links/images, R4=code context exclusion,
R5=--ignore/--allow filters, R6=output formats, R7=exit codes, R8=performance.

| Requirement | Enforcing BCs |
|-------------|---------------|
| R1 — File discovery | BC-2.01.001..BC-2.01.009 |
| R2a — Relative file link resolution | BC-2.07.001..BC-2.07.008 |
| R2b — Heading anchor resolution | BC-2.05.001..BC-2.06.002, BC-2.08.001..BC-2.08.004 |
| R2c — External URL checking (--online) | BC-2.09.001, BC-2.10.001..BC-2.10.010 |
| R3 — Reference links and images | BC-2.03.001..BC-2.03.004 |
| R4 — Code context exclusion | BC-2.04.001..BC-2.04.003 |
| R5 — --ignore/--allow filters | BC-2.11.001..BC-2.11.004 |
| R6 — Output formats (text/JSON) | BC-2.12.001..BC-2.13.002 |
| R7 — Exit codes | BC-2.14.001..BC-2.14.004 |
| R8 — Performance (NFR-001, NFR-002) | [NFR-001..NFR-002 in nfr-catalog.md] |

## Competitive Differentiator Coverage (KD-001..005)

Per PRD §1.3.

| Differentiator | Primary BCs |
|---------------|-------------|
| KD-001 — Correct anchor checking, on by default | BC-2.05.001, BC-2.05.003, BC-2.06.001, BC-2.06.002, BC-2.08.001..BC-2.08.003, BC-2.07.006 |
| KD-002 — Offline-by-default (no 429/bot-block false positives) | BC-2.09.001, BC-2.10.001, BC-2.10.002 |
| KD-003 — Source-level file:line reporting | BC-2.02.001, BC-2.12.001, BC-2.13.001 |
| KD-004 — Case-correct path resolution (NFC + exact-case dir-entry on all platforms) | BC-2.07.003 |
| KD-005 — Deterministic exit codes (0/1/2 pure function of verdict multiset) | BC-2.14.001, BC-2.14.002, BC-2.14.003, BC-2.10.002 |

---

_Last updated: 2026-08-05 by vsdd-factory:product-owner (PRD v1.6 — REGRESSION-001: BC-2.05.001 title corrected from "Two-Pass Design" to "Three-Phase Design" per H1 source-of-truth policy. DI-008 label updated from "Two-pass:" to "Three-phase (Pass 1 → Pass 1.5 → Pass 2):". BC count unchanged: 66 total.)_
