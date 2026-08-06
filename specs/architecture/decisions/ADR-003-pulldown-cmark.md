---
document_type: adr
adr_id: ADR-003
status: accepted
date: 2026-08-05
subsystems_affected: [SS-02, SS-03, SS-04]
supersedes: null
superseded_by: null
version: "1.0"
changelog:
  - version: "1.0"
    date: 2026-08-05
    change: "Initial draft — selected pulldown-cmark 0.13.4 over comrak for byte-offset extraction, code-exclusion by construction, and undefined-reference detection."
---

# ADR-003: pulldown-cmark 0.13.4 as the Markdown Parser

## Context

The product requires AST-based Markdown parsing (CAP-002) to satisfy three constraints
simultaneously: (1) byte-offset line numbers for `file:line` reporting (R6); (2) structural
code exclusion — links inside code contexts must never be extracted (DI-004, CAP-004);
(3) undefined reference detection as a distinct failure reason (CAP-003, BC-2.03.003).

Two viable parser candidates exist in the Rust ecosystem with verified crates.io versions
as of 2026-08-05: `pulldown-cmark` 0.13.4 and `comrak` 0.54.0.

## Decision

Use `pulldown-cmark` 0.13.4 (MIT license). Pin this version in `Cargo.toml`.

## Rationale

**Byte offsets:** `pulldown-cmark::Parser::into_offset_iter()` yields
`(Event<'a>, Range<usize>)` where the range is byte offsets into the source string.
This is exactly what R6 needs. Line numbers are derived by a one-pass `\n`-position
scan (build a `Vec<usize>` of line-start byte offsets once per file, then binary-search).
`comrak` provides `Ast.sourcepos` as `(line, col)` directly, but its arena-based AST
is heavier for our use case.

**Code exclusion is free:** DI-004 requires that no link be extracted from code context.
With `pulldown-cmark`, this is satisfied by construction: only matching `Tag::Link` and
`Tag::Image` events satisfies R4. Links inside code spans and fenced blocks arrive as
`Event::Code` and `Event::Text` inside `Tag::CodeBlock` — they never generate
`Tag::Link` events. Zero special-case logic required (market-intelligence §4.2).

**Undefined reference detection:** `LinkType::ReferenceUnknown`, `CollapsedUnknown`, and
`ShortcutUnknown` variants surface undefined references directly in the event stream.
This enables BC-2.03.003's `undefined-reference-definition` reason code without
post-processing. `comrak` would require a separate pass over the AST.

**GFM bare-URL limitation:** `pulldown-cmark` does not support GFM bare-URL autolinks
(`https://x.com` in plain prose). This is documented and accepted per DD-009: bare URLs
are out of scope. If bare-URL parity ever becomes a requirement, `comrak` is the migration
target — record this in a future ADR superseding ADR-003.

## Consequences

### Positive
- Code exclusion invariant (DI-004) satisfied by construction — zero risk of code-fence
  false positives (the dominant incumbent defect class per market-intelligence §1.3)
- Undefined references detected as a distinct reason code without extra passes
- MIT license; permissive
- Smaller dependency surface than comrak (no arena allocator)

### Negative / Trade-offs
- GFM bare-URL autolinks are not supported; documented as a product limitation (DD-009)
- Byte-offset-to-line conversion requires a helper function (trivial, single pass)
- If comrak migration is ever needed, the event-stream API will change significantly

### Status as of 2026-08-05

Accepted. Parser not yet instantiated (Phase 3 scope).

## Alternatives Considered

- **comrak 0.54.0 (BSD-2-Clause):** Supports GFM bare-URL autolinks and provides
  source positions as (line, col) directly. Rejected because: arena-based AST is
  heavier; code exclusion requires explicit node-type filtering (vs. event-based free
  exclusion); `comrak` doesn't expose undefined-reference variants in its AST node types
  as cleanly as `pulldown-cmark`'s `LinkType::*Unknown` variants.
- **Regex-based extraction:** Explicitly rejected as anti-gene (gene-transfusion §4):
  known failure vectors include code-fence false positives (DI-004 violation), escaped
  bracket false positives, and nested bracket mishandling.

## Source / Origin

- market-intelligence.md §4.2: Parser decision section with primary-source verification
- DI-004, CAP-004: Code context exclusion invariant
- BC-2.03.003: Undefined reference detection behavioral contract
- gene-transfusion-assessment.md §4: Regex-based extraction anti-gene
