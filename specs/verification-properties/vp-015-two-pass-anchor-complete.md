---
document_type: verification-property
level: L4
version: "1.3"
status: draft
producer: architect
timestamp: 2026-08-05T20:00:00Z
phase: 1b
inputs:
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/architecture/module-decomposition.md
input-hash: "3efc65a"
traces_to: .factory/specs/architecture/ARCH-INDEX.md
source_bc: BC-2.05.001
module: anchor_table
proof_method: integration
feasibility: feasible
verification_lock: false
proof_completed_date: null
proof_file_hash: null
lifecycle_status: active
introduced: v0.1.0
modified:
  - version: "1.3"
    date: 2026-08-07
    change: "BI-025 vacuity repair: prior v1.2 was outright vacuous — run_scan(_) -> vec![] trivially satisfies all three broken.is_empty() assertions because an empty result has no broken links. Added a 'control broken link' to each fixture's source file: a link to a non-existent anchor in the target file. Each fixture now asserts (a) the control broken link IS detected (proving the scanner ran and checked anchors) and (b) the primary well-formed link is NOT broken (proving two-pass resolves it correctly). A no-op scanner fails assertion (a) immediately. Added Non-Vacuousness Analysis section."
  - version: "1.2"
    date: 2026-08-06
    change: "(P4-014) test file path corrected: tests/integration/two_pass_anchor.rs → tests/integration_two_pass_anchor.rs (flat Cargo-discoverable layout per tooling-selection.md §Test Target Layout)."
  - version: "1.1"
    date: 2026-08-05
    change: "P2-M14 remediation: added out-of-scan-target fixture (target outside scan root, handled by Pass 1.5); replaced vacuous reverse-reference fixture (where target lexicographically precedes source — not a meaningful ordering test) with a fixture that explicitly places the target file at a path that sorts AFTER the source file (z_target.md > a_source.md), making the two-pass ordering dependency visible."
deprecated: null
deprecated_by: null
replacement: null
retired: null
withdrawn: null
withdrawal_reason: null
removed: null
removal_reason: null
---

# VP-015: Two-Pass Design — Anchor Table Complete Before Any Link Resolution

## Property Statement

The pipeline builds the complete anchor table for ALL scanned files during Pass 1, before any link resolution occurs in Pass 2. A cross-file link from `a.md` to `b.md#heading` is correctly resolved even when `b.md` appears after `a.md` in the scan order. This is DI-008: no link resolution occurs until all anchor tables are built.

**Falsified by:** An implementation that resolves cross-file anchor links during a single pass, before building the anchor table for the target file, produces a false broken verdict (`anchor-not-found`) for a forward reference (`a_source.md` links to `z_target.md#target-heading`; `z_target.md` appears later in scan order). A no-op scanner returning `vec![]` fails the control assertion in each fixture (expected 1 broken for the control link, got 0).

## Source Contract

- **BC:** BC-2.05.001 — Two-Pass Anchor Table Construction
- **Postcondition/Invariant:** DI-008 — anchor table is fully populated before resolution begins; forward references resolve correctly.

## Proof Method

| Method | Tool | Bounded? | Coverage |
|--------|------|----------|----------|
| integration | nextest 0.9.129 | yes — fixture-based | Three fixtures: (1) forward reference, (2) backward reference, (3) out-of-scan target. Each fixture contains both a well-formed link (must not be broken) and a control broken link (must be broken), ensuring the scanner actually ran. |

## Proof Harness Skeleton

```rust
// tests/integration_two_pass_anchor.rs  (flat layout per tooling-selection.md §Test Target Layout)

// Fixture 1: forward reference — source sorts BEFORE target lexicographically.
// In a single-pass implementation, a_source.md would be resolved before z_target.md's
// anchor table is built, producing a false broken result for the good link.
// In the two-pass design, all anchor tables are complete before any resolution.
//
// Control broken link: a_source.md also links to z_target.md#no-such-heading.
// This anchor does NOT exist in z_target.md. The scanner MUST report it as broken.
// A no-op scanner returning vec![] fails the control assertion (expected 1, got 0).
#[test]
fn vp015_forward_reference_resolves() {
    let dir = tempdir();
    write_file(&dir, "a_source.md",
        // good link: z_target.md has "# Target Heading"
        "[good](./z_target.md#target-heading)\n\
         // control: this anchor does NOT exist in z_target.md — must be broken
         [bad](./z_target.md#no-such-heading-xyzzy)");
    write_file(&dir, "z_target.md", "# Target Heading\nContent.");

    let findings = run_scan(&dir, ScanOpts::default());

    // Control assertion: scanner must detect the broken link to #no-such-heading-xyzzy.
    // Falsified by: no-op scanner (returns vec![], so no broken findings at all).
    let control_broken: Vec<_> = findings.iter()
        .filter(|f| f.link_target.contains("no-such-heading-xyzzy") && f.is_broken())
        .collect();
    assert_eq!(control_broken.len(), 1,
        "Control: scanner must detect broken anchor 'no-such-heading-xyzzy' in z_target.md \
         (proves scanner ran; no-op scanner yields 0 broken, expected 1)");

    // Primary assertion: the well-formed forward reference must resolve correctly.
    // Falsified by: single-pass scanner (resolves before building z_target.md's table).
    let good_link_broken: Vec<_> = findings.iter()
        .filter(|f| f.link_target.contains("target-heading")
            && !f.link_target.contains("no-such")
            && f.is_broken())
        .collect();
    assert!(good_link_broken.is_empty(),
        "Forward cross-file anchor reference (a_source → z_target#target-heading) must \
         resolve correctly under two-pass design: {:?}", good_link_broken);
}

// Fixture 2: backward reference — source sorts AFTER target lexicographically.
// This verifies that anchor table completeness is not accidentally limited to
// files that appear before the source in the scan walk.
//
// Control broken link: z_source.md also links to a_target.md#nonexistent-anchor-xyzzy.
// This anchor does NOT exist in a_target.md. The scanner MUST report it as broken.
#[test]
fn vp015_backward_reference_resolves() {
    let dir = tempdir();
    write_file(&dir, "a_target.md", "# My Heading\nContent.");
    write_file(&dir, "z_source.md",
        "[good](./a_target.md#my-heading)\n\
         [bad](./a_target.md#nonexistent-anchor-xyzzy)");

    let findings = run_scan(&dir, ScanOpts::default());

    // Control assertion: scanner must detect the broken link to #nonexistent-anchor-xyzzy.
    let control_broken: Vec<_> = findings.iter()
        .filter(|f| f.link_target.contains("nonexistent-anchor-xyzzy") && f.is_broken())
        .collect();
    assert_eq!(control_broken.len(), 1,
        "Control: scanner must detect broken anchor 'nonexistent-anchor-xyzzy' in a_target.md \
         (proves scanner ran; no-op scanner yields 0 broken, expected 1)");

    // Primary assertion: the well-formed backward reference must resolve correctly.
    let good_link_broken: Vec<_> = findings.iter()
        .filter(|f| f.link_target.contains("my-heading")
            && !f.link_target.contains("nonexistent")
            && f.is_broken())
        .collect();
    assert!(good_link_broken.is_empty(),
        "Backward cross-file anchor reference (z_source → a_target#my-heading) must \
         resolve correctly: {:?}", good_link_broken);
}

// Fixture 3: out-of-scan target — Pass 1.5 opens the file on demand.
// The target is outside the scan root; Pass 1 does not traverse it.
// Pass 1.5 must open it and build its anchor table before Pass 2 runs.
//
// Control broken link: source.md also links to ../outside.md#nonexistent-xyzzy.
// This anchor does NOT exist in outside.md. Must be reported as broken.
#[test]
fn vp015_out_of_scan_target_anchor_resolves() {
    let parent = tempdir();
    write_file_at(parent.path(), "outside.md", "# External Heading\nContent.");
    let project = parent.path().join("project");
    fs::create_dir_all(&project).unwrap();
    write_file_at(&project, "source.md",
        "[good](../outside.md#external-heading)\n\
         [bad](../outside.md#nonexistent-xyzzy)");

    let findings = run_scan(&project, ScanOpts::default());

    // Control assertion: scanner must detect the broken link to #nonexistent-xyzzy.
    let control_broken: Vec<_> = findings.iter()
        .filter(|f| f.link_target.contains("nonexistent-xyzzy") && f.is_broken())
        .collect();
    assert_eq!(control_broken.len(), 1,
        "Control: scanner must detect broken anchor 'nonexistent-xyzzy' in ../outside.md \
         via Pass 1.5 (proves Pass 1.5 ran; no-op scanner yields 0 broken, expected 1)");

    // Primary assertion: the well-formed out-of-scan anchor link must resolve correctly.
    let good_link_broken: Vec<_> = findings.iter()
        .filter(|f| f.link_target.contains("external-heading")
            && !f.link_target.contains("nonexistent")
            && f.is_broken())
        .collect();
    assert!(good_link_broken.is_empty(),
        "Anchor in out-of-scan-root target must resolve via Pass 1.5: {:?}", good_link_broken);
}
```

## Non-Vacuousness Analysis

Three wrong implementations are falsified by this VP:

| Wrong Implementation | Falsifying Harness | Failure Mode |
|---|---|---|
| `run_scan(_) -> vec![]` (no-op scanner) | Control assertion in all 3 fixtures | expected 1 broken (control link to `#no-such-heading-xyzzy`), got 0 |
| Single-pass scanner (resolves before full table) | vp015_forward_reference_resolves (primary assertion) | good link `#target-heading` appears as broken because z_target.md not yet parsed |
| Pass 1.5 not implemented | vp015_out_of_scan_target_anchor_resolves | control `#nonexistent-xyzzy` not found (Pass 1.5 never ran), OR good link `#external-heading` broken |

Each fixture requires BOTH a control assertion (scanner ran) and a primary assertion
(two-pass resolved correctly). A no-op scanner fails the control. A single-pass
scanner may pass the control but fail the primary.

## Feasibility Assessment

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Input space size | Fixture-based | Three fixtures; each includes a control broken link and a primary clean link |
| Proof complexity | Medium | Requires integration harness with real file I/O; tests the pipeline architecture |
| Tool support | Full | nextest with tempdir fixture helpers |
| Estimated proof time | < 2s | Small fixtures; fast I/O |

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-05 | architect |
| v1.3 — BI-025 vacuity repair: control broken links added to all 3 fixtures | 2026-08-07 | architect |
| Proof harness committed | — | formal-verifier |
| Proof first passed | — | formal-verifier |
| Locked (VERIFIED) | — | formal-verifier |
