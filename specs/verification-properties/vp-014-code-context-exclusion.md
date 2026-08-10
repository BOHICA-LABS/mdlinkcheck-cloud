---
document_type: verification-property
level: L4
version: "1.3"
status: draft
producer: architect
timestamp: 2026-08-10T00:00:00Z
phase: 1b
inputs:
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/architecture/module-decomposition.md
input-hash: "3efc65a"
traces_to: .factory/specs/architecture/ARCH-INDEX.md
source_bc: BC-2.04.001
module: link_extractor
proof_method: integration
feasibility: feasible
verification_lock: false
proof_completed_date: null
proof_file_hash: null
lifecycle_status: active
introduced: v0.1.0
modified:
  - version: "1.3"
    date: 2026-08-10
    change: "BI-052 remediation (P7-S3-002): added vp014_indented_code_no_links fixture. Property Statement listed indented code blocks as excluded context #3 and proof method table claimed 'indented code' coverage, but no harness fixture existed for this case. Fixture verifies that a 4-space-indented paragraph containing a Markdown link-like string produces zero ExtractedLink entries."
  - version: "1.2"
    date: 2026-08-06
    change: "(P4-014) test file path corrected: tests/integration/link_extractor_code_exclusion.rs → tests/integration_link_extractor_code_exclusion.rs (flat Cargo-discoverable layout per tooling-selection.md §Test Target Layout)."
  - version: "1.1"
    date: 2026-08-05
    change: "P2-M14 remediation: added HTML <pre> and HTML comment (<!-- -->) code-context fixtures; updated Property Statement to enumerate all 5 code-context exclusion cases."
deprecated: null
deprecated_by: null
replacement: null
retired: null
withdrawn: null
withdrawal_reason: null
removed: null
removal_reason: null
---

# VP-014: Code Context Exclusion — No Links Extracted from Code or Non-Link HTML Contexts

## Property Statement

Given Markdown source containing links inside code or non-link HTML contexts,
`link_extractor::extract(events)` returns no `ExtractedLink` for those link strings.
Links in normal (non-code) context in the same document are extracted normally.
This is DI-004: code context exclusion is structural (pulldown-cmark event model), not a regex filter.

The five excluded contexts are:
1. **Fenced code blocks** — ` ``` ` delimited blocks (`Event::Start(Tag::CodeBlock(...))`)
2. **Inline code spans** — `` `...` `` (``Event::Code``)
3. **Indented code blocks** — 4-space indented paragraphs (also `Event::Start(Tag::CodeBlock(...))`)
4. **HTML `<pre>` blocks** — preformatted text blocks (`Event::Html` containing `<pre>`)
5. **HTML comments** — `<!-- ... -->` (`Event::Html` containing comment syntax)

## Source Contract

- **BC:** BC-2.04.001 — Code Context Exclusion
- **Postcondition/Invariant:** DI-004 — no link from code context appears in extraction output; this is enforced by construction via the pulldown-cmark event model.

## Proof Method

| Method | Tool | Bounded? | Coverage |
|--------|------|----------|----------|
| integration | nextest 0.9.129 | yes — fixture-based | Corpus of 13+ Markdown fixtures covering fenced code, inline code, indented code, HTML `<pre>`, HTML comments; each fixture verified against expected extraction count |

## Proof Harness Skeleton

```rust
// tests/integration_link_extractor_code_exclusion.rs  (flat layout per tooling-selection.md §Test Target Layout)
#[test]
fn vp014_fenced_code_no_links() {
    let md = r#"
Normal [link](./foo.md) here.

```markdown
[not a link](./should-not-appear.md)
```

Another [link](./bar.md).
"#;
    let events = parse_to_events(md);
    let links = extract_links(&events);
    assert_eq!(links.len(), 2, "Should extract exactly 2 links");
    assert!(!links.iter().any(|l| l.dest.contains("should-not-appear")),
        "Code block link must not be extracted");
}

#[test]
fn vp014_inline_code_no_links() {
    let md = "Use `[link](./inline-code.md)` syntax.";
    let events = parse_to_events(md);
    let links = extract_links(&events);
    assert!(links.is_empty(), "Inline code link must not be extracted");
}

#[test]
fn vp014_indented_code_no_links() {
    // Indented code blocks: 4-space indentation signals a code block in CommonMark.
    // pulldown-cmark emits Event::Start(Tag::CodeBlock(CodeBlockKind::Indented)) —
    // the same variant as fenced blocks, so it is excluded by the same gate.
    // Falsified by: an implementation that only suppresses fenced blocks and forgets
    // that CodeBlockKind::Indented shares the same Tag::CodeBlock variant.
    let md = "Normal [link](./normal.md) here.\n\n    [not a link](./indented-code.md)\n";
    let events = parse_to_events(md);
    let links = extract_links(&events);
    assert_eq!(links.len(), 1, "Should extract exactly 1 link (the normal one)");
    assert!(!links.iter().any(|l| l.dest.contains("indented-code")),
        "Indented code block link must not be extracted");
}

#[test]
fn vp014_html_pre_block_no_links() {
    // <pre> blocks are rendered as Event::Html; the link inside must not be extracted.
    let md = "<pre>\n[not a link](./pre-block.md)\n</pre>";
    let events = parse_to_events(md);
    let links = extract_links(&events);
    assert!(links.is_empty(), "Link inside HTML <pre> block must not be extracted");
}

#[test]
fn vp014_html_comment_no_links() {
    // HTML comments are Event::Html; link-like text inside must not be extracted.
    let md = "<!-- [not a link](./comment.md) -->";
    let events = parse_to_events(md);
    let links = extract_links(&events);
    assert!(links.is_empty(), "Link inside HTML comment must not be extracted");
}
```

## Feasibility Assessment

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Input space size | Bounded fixtures | 13 corpus fixtures from gene-transfusion-assessment.md; sufficient for structural proof |
| Proof complexity | Low | Property holds by construction (pulldown-cmark event model); tests verify it is not accidentally broken |
| Tool support | Full | nextest + standard Rust test macros |
| Estimated proof time | < 1s | Pure in-memory test; no I/O |

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-05 | architect |
| Proof harness committed | — | formal-verifier |
| Proof first passed | — | formal-verifier |
| Locked (VERIFIED) | — | formal-verifier |
