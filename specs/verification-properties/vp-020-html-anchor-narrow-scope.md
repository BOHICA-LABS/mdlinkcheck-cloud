---
document_type: verification-property
level: L4
version: "1.2"
status: draft
producer: architect
timestamp: 2026-08-05T20:00:00Z
phase: 1b
inputs:
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/architecture/module-decomposition.md
input-hash: "9c1a1a8"
traces_to: .factory/specs/architecture/ARCH-INDEX.md
source_bc: BC-2.05.003
module: anchor_table
proof_method: integration
feasibility: feasible
verification_lock: false
proof_completed_date: null
proof_file_hash: null
lifecycle_status: active
introduced: v0.1.0
modified:
  - version: "1.2"
    date: 2026-08-06
    change: "(P4-014) test file path corrected: tests/integration/html_anchor_scope.rs → tests/integration_html_anchor_scope.rs (flat Cargo-discoverable layout per tooling-selection.md §Test Target Layout)."
  - version: "1.1"
    date: 2026-08-05
    change: "P2-m01 remediation: fixed frontmatter field 'removal_range' → 'removal_reason'; corrected pulldown-cmark event name in property description ('Event::Code' → 'Start(Tag::CodeBlock)'); added Event::InlineHtml to property statement; added inline <a name=\"x\"></a> fixture."
deprecated: null
deprecated_by: null
replacement: null
retired: null
withdrawn: null
withdrawal_reason: null
removed: null
removal_reason: null
---

# VP-020: HTML Anchor Extraction — Only id= / name= from Raw HTML Inline Blocks

## Property Statement

When building the anchor table for a Markdown file containing raw HTML blocks, `anchor_table::build` extracts anchors ONLY from `id=` and `name=` attributes of HTML elements within `Event::Html` events (block HTML) and `Event::InlineHtml` events (inline HTML). It does NOT extract anchors from:
- Arbitrary HTML attributes other than `id=` and `name=`
- HTML inside fenced code blocks (which produce `Event::Start(Tag::CodeBlock(...))` + `Event::Text` + `Event::End(Tag::CodeBlock(...))`, never `Event::Html`)
- Manufactured anchor IDs from non-heading Markdown structure

This is DI-007: HTML anchor extraction has narrow, well-defined scope.

## Source Contract

- **BC:** BC-2.05.003 — HTML Anchor Extraction Scope
- **Postcondition/Invariant:** DI-007 — anchor extraction from HTML is limited to `id=` and `name=` attributes in raw HTML events only.

## Proof Method

| Method | Tool | Bounded? | Coverage |
|--------|------|----------|----------|
| integration | nextest 0.9.129 | yes — fixture-based | Four fixtures: (1) block HTML with id= anchor, (2) inline HTML `<a name=>` anchor, (3) HTML with non-id/name attributes, (4) HTML inside fenced code block |

## Proof Harness Skeleton

```rust
// tests/integration_html_anchor_scope.rs  (flat layout per tooling-selection.md §Test Target Layout)

#[test]
fn vp020_id_attribute_extracted() {
    let md = r#"
# Heading

<div id="section-marker">Content</div>

[link to div](#section-marker)
"#;
    let table = build_anchor_table_from_md(md);
    assert!(table.contains("section-marker"),
        "id= attribute must be extracted as anchor");
}

#[test]
fn vp020_name_attribute_extracted_inline() {
    // Inline HTML (Event::InlineHtml) — <a name="x"> inline within paragraph text
    let md = "Some text <a name=\"inline-anchor\"></a> more text.";
    let table = build_anchor_table_from_md(md);
    assert!(table.contains("inline-anchor"),
        "name= attribute in inline HTML must be extracted as anchor");
}

#[test]
fn vp020_non_id_attribute_not_extracted() {
    let md = r#"<span class="highlight" data-ref="ignored">text</span>"#;
    let table = build_anchor_table_from_md(md);
    assert!(!table.contains("highlight"),
        "class= attribute must not be extracted as anchor");
    assert!(!table.contains("ignored"),
        "data-ref= attribute must not be extracted as anchor");
}

#[test]
fn vp020_html_in_code_block_not_extracted() {
    // Fenced code blocks produce Start(Tag::CodeBlock) + Text + End events, not Html events.
    // The id= attribute here must NOT be extracted.
    let md = r#"
```html
<div id="fake-anchor">Should not be extracted</div>
```
"#;
    let table = build_anchor_table_from_md(md);
    assert!(!table.contains("fake-anchor"),
        "HTML id= inside fenced code block (Event::Start(Tag::CodeBlock)) must not be extracted");
}
```

## Feasibility Assessment

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Input space size | Fixture-based | Four fixtures cover boundary conditions of DI-007; includes inline HTML (`Event::InlineHtml`) and code-block exclusion |
| Proof complexity | Low | The scope boundary is enforced by the pulldown-cmark event model |
| Tool support | Full | nextest unit/integration tests |
| Estimated proof time | < 500ms | |

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-05 | architect |
| Proof harness committed | — | formal-verifier |
| Proof first passed | — | formal-verifier |
| Locked (VERIFIED) | — | formal-verifier |
