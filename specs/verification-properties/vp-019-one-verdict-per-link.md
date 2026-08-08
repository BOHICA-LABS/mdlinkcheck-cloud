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
input-hash: "3efc65a"
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
  - version: "1.2"
    date: 2026-08-07
    change: "BI-025 vacuity repair: prior v1.1 was outright vacuous — extract_links(_) -> vec![] trivially satisfies the deduplication loop because the loop body never executes on empty output, so prop_assert! is never called. Added vp019_extracts_all_inline_links (completeness property): generates markdown with exactly N inline links and asserts extract_links returns exactly N entries. This fails a no-op extractor (expected N, got 0). Changed deduplication strategy from 0..20 (can be empty) to 1..20 (at least 1 link) and asserted !links.is_empty() to close the vacuity. Added Non-Vacuousness Analysis section following VP-025 template."
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

Furthermore, when a Markdown document contains N inline links at N distinct source positions, `extract_links` returns exactly N `ExtractedLink` entries — it neither under-counts (omission) nor over-counts (duplication).

**Scope note:** `extract_links` processes one file at a time; `source_file` is the implicit caller context, not a field on each event. The uniqueness key within a single-file call is `(dest, line, col)`.

**DI-005 gap:** DI-005 requires that each extracted link is assigned exactly ONE verdict downstream (no-verdict and two-verdict cases are the real risk — e.g., `[x](missing.md#anchor)` generating both `file-not-found` from `path_resolver` AND `anchor-not-found` from `anchor_resolver`). This VP establishes only the extraction deduplication precondition, not the full downstream verdict uniqueness. The complete DI-005 guarantee requires a Phase 3 pipeline integration test asserting `findings.len() == links.filter(broken_or_indeterminate).count()` and no two findings share `(file, line, column)`.

**Falsified by:** An implementation `extract_links(_) -> vec![]` satisfies the deduplication property vacuously (empty output has no duplicates) but fails `vp019_extracts_all_inline_links`: given markdown with N=3 inline links, it returns 0 entries instead of 3.

## Source Contract

- **BC:** BC-2.03.001 — Inline link/image extraction
- **Postcondition/Invariant:** Partial DI-005 precondition — each link position produces at most one `ExtractedLink`; no duplicate extraction within one file.

## Proof Method

| Method | Tool | Bounded? | Coverage |
|--------|------|----------|----------|
| proptest | proptest 1.6.0 | no — property-based | Arbitrary Markdown with 1..20 links (deduplication); markdown with exactly N links at distinct positions (completeness) |

## Proof Harness Skeleton

```rust
use proptest::prelude::*;
use mdlinkcheck_core::link_extractor::extract_links;

proptest! {
    // ── P1: deduplication ────────────────────────────────────────────────────
    //
    // For any input that produces at least one link, extract_links must not yield
    // the same (dest, line, col) position twice. Strategy guarantees at least 1
    // link element so the loop body always executes and prop_assert! is live.
    //
    // Falsified by: extract_links returning two ExtractedLink entries with the same
    // (dest, line, col) — e.g. if the pulldown-cmark event loop fires twice per link.
    #[test]
    fn vp019_no_duplicate_links(md in arb_markdown_with_links()) {
        let events = parse_to_events(&md);
        let links = extract_links(&events);

        // Non-vacuousness guard: the strategy guarantees at least one link element;
        // if extract_links returns empty, that is itself a correctness failure.
        prop_assert!(
            !links.is_empty(),
            "extract_links returned empty output for markdown that contains links: {:?}",
            md
        );

        // Deduplication: each (dest, line, col) tuple must appear at most once.
        let mut seen = std::collections::HashSet::new();
        for link in &links {
            let key = (link.dest.clone(), link.line, link.col);
            prop_assert!(
                seen.insert(key.clone()),
                "Duplicate link at ({}, {}): {} — extract_links must not yield \
                 the same position twice",
                link.line, link.col, link.dest
            );
        }
    }

    // ── P2: completeness ─────────────────────────────────────────────────────
    //
    // This is the PRIMARY anti-vacuousness property.
    // Given markdown containing exactly N inline links at N distinct positions,
    // extract_links must return exactly N ExtractedLink entries.
    //
    // Falsified by:
    //   - Under-count: extract_links(_) -> vec![] returns 0, expected N ≥ 1.
    //   - Over-count: extract_links fires twice per link event, returns 2N.
    //
    // Strategy: generate N simple inline links [textN](destN.md) on separate lines.
    // Each [textN](destN.md) is a distinct inline link. pulldown-cmark produces
    // exactly one Start(Tag::Link)/End event pair per inline link, so exactly N
    // ExtractedLink entries are expected.
    #[test]
    fn vp019_extracts_all_inline_links(
        dests in prop::collection::vec("[a-z]{3,12}\\.md", 1..=5usize),
    ) {
        // Build markdown with exactly dests.len() inline links, one per line.
        // Lines are separated to place each link at a distinct (line, col) position.
        let md: String = dests
            .iter()
            .enumerate()
            .map(|(i, d)| format!("[link{}]({})", i, d))
            .collect::<Vec<_>>()
            .join("\n");
        let n = dests.len();

        let events = parse_to_events(&md);
        let links = extract_links(&events);

        prop_assert_eq!(
            links.len(),
            n,
            "extract_links must return exactly {} links for markdown with {} inline links, \
             got {} — no-op extractor fails here (returns 0 instead of {})",
            n, n, links.len(), n
        );
    }
}

/// Strategy: generates Markdown with 1..20 inline-link elements (at least one),
/// ensuring the deduplication loop always has content to check.
fn arb_markdown_with_links() -> impl Strategy<Value = String> {
    prop::collection::vec(arb_inline_link(), 1..20)
        .prop_map(|links| links.join("\n"))
}

/// Strategy: generates a single inline link element [textN](dest.md).
fn arb_inline_link() -> impl Strategy<Value = String> {
    ("[a-z]{3,12}".prop_flat_map(|dest: String| {
        "[a-z]{3,8}".prop_map(move |text: String| {
            format!("[{}]({}.md)", text, dest)
        })
    }))
}
```

## Non-Vacuousness Analysis

Three wrong implementations are falsified by different harnesses in this VP:

| Wrong Implementation | Falsifying Harness | Failure Mode |
|---|---|---|
| `extract_links(_) -> vec![]` (no-op extractor) | vp019_extracts_all_inline_links (P2) | expected N links, got 0 |
| `extract_links(_) -> vec![]` (no-op extractor) | vp019_no_duplicate_links (P1, !is_empty guard) | prop_assert!(!links.is_empty()) fails |
| Extractor fires twice per link | vp019_extracts_all_inline_links (P2) | returns 2N instead of N |
| Extractor fires twice per link | vp019_no_duplicate_links (P1) | duplicate (dest, line, col) detected |

The completeness (P2) and deduplication (P1) properties together require a bijective
mapping from input link positions to output `ExtractedLink` entries: neither
over-counting (duplication) nor under-counting (omission) satisfies both simultaneously.

## Feasibility Assessment

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Input space size | Property-based | `arb_markdown_with_links` generates 1..20 inline links; `arb_inline_link` generates alphanumeric dest/text |
| Proof complexity | Low | HashSet uniqueness check is trivial; count comparison is trivial |
| Tool support | Full | proptest 1.6.0; custom strategy for inline links |
| Estimated proof time | < 5s per run | |

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-05 | architect |
| v1.1 — P2-M04/P2-M05 remediation | 2026-08-05 | architect |
| v1.2 — BI-025 vacuity repair: added P2 completeness + Non-Vacuousness Analysis | 2026-08-07 | architect |
| Proof harness committed | — | formal-verifier |
| Proof first passed | — | formal-verifier |
| Locked (VERIFIED) | — | formal-verifier |
