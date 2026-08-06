---
document_type: verification-property
level: L4
version: "1.1"
status: draft
producer: architect
timestamp: 2026-08-05T20:00:00Z
phase: 1b
inputs:
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/architecture/module-decomposition.md
input-hash: "012887b"
traces_to: .factory/specs/architecture/ARCH-INDEX.md
source_bc: BC-2.03.001
module: link_extractor
proof_method: proptest
feasibility: feasible
verification_lock: false
proof_completed_date: null
proof_file_hash: null
lifecycle_status: active
introduced: v0.1.0
modified:
  - version: "1.1"
    date: 2026-08-05
    change: "P2-M04/P2-M05 remediation: retitled from 'Single Verdict per Link' (invented BC title) to what the VP actually proves — extract_links is duplicate-free. Corrected source BC title to actual BC-2.03.001 H1 'Inline link/image extraction'. Fixed harness key to include source_file. Clarified that DI-005 (no-verdict / two-verdict cases) is not fully covered by this VP — the full pipeline guarantee requires a Phase 3 integration test."
deprecated: null
deprecated_by: null
replacement: null
retired: null
withdrawn: null
withdrawal_reason: null
removed: null
removal_reason: null
---

# VP-019: extract_links Output Is Duplicate-Free — No Position Extracted Twice

## Property Statement

For any input event stream produced by parsing a valid Markdown document, each unique `(dest, line, col)` tuple appears at most once in the output of `link_extractor::extract(events)`. No link is extracted twice from the same source position within a single file's event stream.

**Scope note:** `extract_links` processes one file at a time; `source_file` is the implicit caller context, not a field on each event. The uniqueness key within a single-file call is `(dest, line, col)`.

**DI-005 gap:** DI-005 requires that each extracted link is assigned exactly ONE verdict downstream (no-verdict and two-verdict cases are the real risk — e.g., `[x](missing.md#anchor)` generating both `file-not-found` from `path_resolver` AND `anchor-not-found` from `anchor_resolver`). This VP establishes only the extraction deduplication precondition, not the full downstream verdict uniqueness. The complete DI-005 guarantee requires a Phase 3 pipeline integration test asserting `findings.len() == links.filter(broken_or_indeterminate).count()` and no two findings share `(file, line, column)`.

## Source Contract

- **BC:** BC-2.03.001 — Inline link/image extraction
- **Postcondition/Invariant:** Partial DI-005 precondition — each link position produces at most one `ExtractedLink`; no duplicate extraction within one file.

## Proof Method

| Method | Tool | Bounded? | Coverage |
|--------|------|----------|----------|
| proptest | proptest 1.6.0 | no — property-based | Arbitrary Markdown source strings parsed to event stream; output checked for duplicate (dest, line, col) tuples |

## Proof Harness Skeleton

```rust
proptest! {
    #[test]
    fn vp019_no_duplicate_links(md in arb_markdown_with_links()) {
        let events = parse_to_events(&md);
        let links = extract_links(&events);

        // Build a set of (source_file, dest, line, col) tuples.
        // source_file is implicit (extract_links processes one file at a time)
        // so within a single call the effective key is (dest, line, col).
        let mut seen = std::collections::HashSet::new();
        for link in &links {
            let key = (link.dest.clone(), link.line, link.col);
            prop_assert!(
                seen.insert(key.clone()),
                "Duplicate link at ({}, {}): {} — extract_links must not yield the same position twice",
                link.line, link.col, link.dest
            );
        }
    }
}

// Strategy: generates Markdown with 0..10 links in various positions
fn arb_markdown_with_links() -> impl Strategy<Value = String> {
    prop::collection::vec(arb_link_or_text(), 0..20)
        .prop_map(|parts| parts.join("\n"))
}
```

## Feasibility Assessment

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Input space size | Property-based | `arb_markdown_with_links` strategy generates documents with various link patterns |
| Proof complexity | Low | HashSet uniqueness check is trivial; the property holds by construction if `into_offset_iter` yields each event once |
| Tool support | Full | proptest 1.6.0; custom Arbitrary strategy for Markdown |
| Estimated proof time | < 5s per run | |

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-05 | architect |
| Proof harness committed | — | formal-verifier |
| Proof first passed | — | formal-verifier |
| Locked (VERIFIED) | — | formal-verifier |
