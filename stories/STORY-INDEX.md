---
document_type: story-index
level: ops
version: "1.0"
status: draft
producer: story-writer
timestamp: 2026-08-10T00:00:00Z
phase: 2
traces_to: .factory/stories/dependency-graph.md
---

# Story Index — mdlinkcheck

| ID | Title | Epic | Wave | Points | Priority | Status | Dependencies |
|----|-------|------|------|--------|----------|--------|--------------|
| S-1.01 | S-1.01: Workspace Scaffold, Shared Types, and Default-CWD File Discovery | E-1 | 1 | 8 | P0 | draft | none |
| S-1.02 | S-1.02: Explicit PATH Arguments, Symlinks, Deduplication, and Traversal Error Cases | E-1 | 2 | 8 | P0 | draft | S-1.01 |
| S-1.03 | S-1.03: Markdown File Reading, BOM/CRLF Normalization, and pulldown-cmark Event Stream | E-1 | 2 | 5 | P0 | draft | S-1.01 |
| S-1.04 | S-1.04: Non-UTF-8 File Error Handling and Explicit Non-.md Argument Parsing | E-1 | 3 | 3 | P0 | draft | S-1.02, S-1.03 |
| S-2.01 | S-2.01: Inline Link/Image Extraction with Kind Classification and Non-http Scheme Skipping | E-2 | 3 | 5 | P0 | draft | S-1.03 |
| S-2.02 | S-2.02: Reference-Style Links, Undefined Reference Verdict, and Parser Non-Link Exclusions | E-2 | 4 | 5 | P0 | draft | S-2.01 |
| S-2.03 | S-2.03: Code Context Exclusion and Anchor Table Integrity for Fenced Code Blocks | E-2 | 5 | 5 | P0 | draft | S-2.01, S-3.02 |
| S-3.01 | S-3.01: github-slugger v2 Slug Algorithm — Clean-Room Rust Reimplementation | E-3 | 2 | 5 | P0 | draft | S-1.01 |
| S-3.02 | S-3.02: Anchor Table Construction — Three-Phase Pipeline and Heading/HTML Extraction | E-3 | 4 | 8 | P0 | draft | S-3.01, S-2.01 |
| S-3.03 | S-3.03: Fragment Split at First Unescaped `#` Before Percent-Decode | E-3 | 2 | 3 | P0 | draft | S-1.01 |
| S-3.04 | S-3.04: Anchor Resolution — Same-File, Cross-File, and Ignored-Source Lookups | E-3 | 5 | 8 | P0 | draft | S-3.02, S-3.03 |
| S-4.01 | S-4.01: Pass 1.5 DirIndex Data Product | E-4 | 5 | 5 | P0 | draft | S-3.02 |
| S-4.02 | S-4.02: Fragment Split, Percent-Decode Ordering, and Empty-Destination Classification | E-4 | 4 | 8 | P0 | draft | S-3.03, S-2.01 |
| S-4.03 | S-4.03: Pure Path Resolver — NFC Case-Sensitive Resolution, Directory and Non-Markdown Routing, Trailing Slash, and Root-Relative Links | E-4 | 6 | 13 | P0 | draft | S-4.01, S-4.02 |
| S-5.01 | S-5.01: Offline URL Syntax Validation and `--allow` Exemption | E-5 | 4 | 5 | P0 | draft | S-2.01, S-6.01 |
| S-5.02 | S-5.02: `http_verdict` — Pure HTTP Response Classification | E-5 | 2 | 5 | P0 | draft | S-1.01 |
| S-5.03 | S-5.03: `http_client` — HEAD/GET Protocol, Timeout, Rate-Limiting, Redirects, and Concurrency | E-5 | 5 | 8 | P0 | draft | S-5.01, S-5.02 |
| S-5.04 | S-5.04: `http_client` — Transport Errors, URL Deduplication, and Private-IP Guard | E-5 | 6 | 8 | P0 | draft | S-5.03 |
| S-6.01 | S-6.01: `--ignore` Glob Source Filtering and Anchor-Table Carve-Out | E-6 | 2 | 8 | P0 | draft | S-1.01 |
| S-6.02 | S-6.02: `--allow` URL Prefix Exemption and Invalid-Glob Startup Gate | E-6 | 5 | 8 | P0 | draft | S-6.01, S-3.02 |
| S-7.01 | S-7.01: Exit Code Determination — `verdict::exit_code` | E-7 | 3 | 5 | P0 | draft | S-1.02 |
| S-7.02 | S-7.02: Text Report Generation — `reporter::format_text` + `format_summary` + stdout/stderr separation | E-7 | 3 | 8 | P0 | draft | S-1.01, S-1.02 |
| S-7.03 | S-7.03: JSON Report Generation — `reporter::format_json` + schema stability contract | E-7 | 4 | 5 | P0 | draft | S-7.02 |
| S-7.04 | S-7.04: CLI Output Format Selection, `--help`, `--version`, and `main.rs` Full Routing | E-7 | 7 | 3 | P0 | draft | S-7.01, S-7.02, S-7.03, S-3.04, S-4.03 |
