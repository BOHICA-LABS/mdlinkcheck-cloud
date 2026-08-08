---
document_type: behavioral-contract
level: L3
version: "1.3"
status: draft
producer: vsdd-factory:product-owner
timestamp: 2026-08-05T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/specs/domain-spec/L2-INDEX.md
  - .factory/planning/brief-validation.md
  - .factory/planning/market-intelligence.md
input-hash: "19b62d8"
traces_to: .factory/specs/domain-spec/L2-INDEX.md
origin: greenfield
extracted_from: null
subsystem: "SS-02"
capability: "CAP-002"
lifecycle_status: active
introduced: v1.0.0
modified:
  - "v1.1: revised to explicitly assign BOM detection and CRLF normalization to scanner.rs (effectful shell) per SF-001 in architecture feasibility-review.md"
  - "v1.2: (F-028) added PC5 and Invariant 5 — both line AND column numbers are relative to the BOM-stripped, LF-normalized buffer; updated test vector with explicit column assertion"
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.02.002: UTF-8 BOM Stripping and CRLF Normalization (Shell-Side)

## Description
Before any file content reaches the pure core, `scanner.rs` (effectful shell) performs two
byte-level normalizations during the file read: (1) detect and strip a UTF-8 BOM
(0xEF 0xBB 0xBF at byte offset 0), and (2) normalize CRLF line endings to LF. The resulting
clean UTF-8 string is what all pure core modules receive. No pure core module (link_extractor,
anchor_table, slug, etc.) ever performs BOM detection or CRLF replacement.

**Shell-side obligation (story-writer note):** The story implementing this BC must assign both
steps to `scanner.rs`. The string passed to `pulldown_cmark::Parser::new()` must already be
BOM-free and LF-only. BOM detection requires inspecting raw bytes (a byte-level I/O concern);
CRLF normalization on the already-read string is pure but is co-located in `scanner.rs` for
cohesion.

## Preconditions
1. `scanner.rs` has read the file's raw bytes from disk.
2. `scanner.rs` has detected and stripped any UTF-8 BOM (0xEF 0xBB 0xBF) at byte offset 0.
3. `scanner.rs` has normalized all CRLF (0x0D 0x0A) sequences to LF (0x0A) in the byte buffer.
4. The resulting byte sequence has been confirmed as valid UTF-8 (BC-2.02.003 handles the
   non-UTF-8 error path).

## Postconditions
1. The string delivered to all pure core modules is BOM-free (no U+FEFF at position 0).
2. The string delivered to all pure core modules contains only LF line endings (no CR, no CRLF).
3. The string is passed as-is to `pulldown_cmark::Parser::new()`.
4. Line numbers reported in findings correspond to the normalized (LF-only) string; CRLF files
   report the same line numbers as equivalent LF files.
5. Column numbers reported in findings are measured from position 0 of the BOM-stripped,
   LF-normalized string buffer — NOT from raw byte offset 0. A BOM file whose first real
   character (after the 3-byte BOM) is a `[` reports that `[` at column 1, not column 4.

## Invariants
1. BOM detection and stripping are exclusively the responsibility of `scanner.rs` (effectful
   shell). No pure core module inspects raw bytes for BOM presence.
2. CRLF normalization is exclusively the responsibility of `scanner.rs`. No pure core module
   performs `str::replace("\r\n", "\n")`.
3. The raw source file is NEVER modified on disk. Normalization is in-memory only.
4. BOM stripping changes byte positions but the tool reports line numbers, not byte offsets,
   so user-visible output is unaffected.
5. Both line and column numbers are computed relative to the BOM-stripped, LF-normalized
   buffer. Column counting starts at 1 from the first character in the buffer (after BOM
   removal). A BOM file and its non-BOM equivalent always produce identical (line, column)
   pairs for every finding.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-015 | UTF-8 BOM followed by `## Setup` on line 1 |
| EC-016 | CRLF file; link on line 10 |
| EC-015b | BOM file: `[x](missing.md)` is the first link on line 1 |

## Canonical Test Vectors
| Input | Expected Output | Category |
|-------|----------------|----------|
| BOM + `## Setup\n[x](#setup)` | Exit 0; clean; line 2, column 1 (BOM stripped; buffer starts at `#`) | happy-path |
| BOM + `[x](missing.md)\n` | Exit 1; line 1, **column 1** (not column 4 — BOM stripped before column counting) | edge-case (TV-015b) |
| CRLF `## Foo\r\n[x](missing.md)` | Exit 1; line 2 reported | edge-case |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | BOM-stripped and non-BOM files produce identical (line, column) findings | unit test |
| test-sufficient | scanner.rs produces clean string (no BOM/CRLF) before parser invocation | unit test (inspect string at scanner.rs boundary) |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-002 ("Markdown Parsing") per capabilities.md §CAP-002 |
| Capability Anchor Justification | CAP-002 ("Markdown Parsing") per capabilities.md §CAP-002 — BOM/CRLF normalization is part of the file-read pipeline that precedes parsing |
| Brief Requirement | R2a |
| Architecture Module | `scanner.rs` (SS-02, effectful shell) — BOM detection and CRLF normalization ONLY; pure core receives already-normalized string |
| Stories | [filled by story-writer] |
