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

## Source Contract

- **BC:** BC-2.05.001 — Two-Pass Anchor Table Construction
- **Postcondition/Invariant:** DI-008 — anchor table is fully populated before resolution begins; forward references resolve correctly.

## Proof Method

| Method | Tool | Bounded? | Coverage |
|--------|------|----------|----------|
| integration | nextest 0.9.129 | yes — fixture-based | Three fixtures: (1) forward reference (`a.md` links to `z_target.md#heading`; target sorts AFTER source), (2) backward reference (`z_source.md` links to `a_target.md#heading`; target sorts BEFORE source), (3) out-of-scan target (Pass 1.5 lookup for a file outside the scan root) |

## Proof Harness Skeleton

```rust
// tests/integration_two_pass_anchor.rs  (flat layout per tooling-selection.md §Test Target Layout)

// Fixture 1: forward reference — source sorts BEFORE target lexicographically.
// In a single-pass implementation, a.md would be resolved before z_target.md's
// anchor table is built, producing a false broken result.
// In the two-pass design, all anchor tables are complete before any resolution.
#[test]
fn vp015_forward_reference_resolves() {
    let dir = tempdir();
    write_file(&dir, "a_source.md", "[link](./z_target.md#target-heading)");
    write_file(&dir, "z_target.md", "# Target Heading\nContent.");

    let findings = run_scan(&dir, ScanOpts::default());
    let broken: Vec<_> = findings.iter().filter(|f| f.is_broken()).collect();
    assert!(broken.is_empty(),
        "Forward cross-file anchor reference (a_source → z_target) must resolve");
}

// Fixture 2: backward reference — source sorts AFTER target lexicographically.
// This verifies that anchor table completeness is not accidentally limited to
// files that appear before the source in the scan walk.
#[test]
fn vp015_backward_reference_resolves() {
    let dir = tempdir();
    write_file(&dir, "a_target.md", "# My Heading\nContent.");
    write_file(&dir, "z_source.md", "[back link](./a_target.md#my-heading)");

    let findings = run_scan(&dir, ScanOpts::default());
    let broken: Vec<_> = findings.iter().filter(|f| f.is_broken()).collect();
    assert!(broken.is_empty(),
        "Backward cross-file anchor reference (z_source → a_target) must resolve");
}

// Fixture 3: out-of-scan target — Pass 1.5 opens the file on demand.
// The target is outside the scan root; Pass 1 does not traverse it.
// Pass 1.5 must open it and build its anchor table before Pass 2 runs.
#[test]
fn vp015_out_of_scan_target_anchor_resolves() {
    let parent = tempdir();
    write_file_at(parent.path(), "outside.md", "# External Heading\nContent.");
    let project = parent.path().join("project");
    fs::create_dir_all(&project).unwrap();
    write_file_at(&project, "source.md", "[link](../outside.md#external-heading)");

    let findings = run_scan(&project, ScanOpts::default());
    let broken: Vec<_> = findings.iter().filter(|f| f.is_broken()).collect();
    assert!(broken.is_empty(),
        "Anchor in out-of-scan-root target must resolve via Pass 1.5");
}
```

## Feasibility Assessment

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Input space size | Fixture-based | Two fixtures cover the essential forward/backward reference cases |
| Proof complexity | Medium | Requires integration harness with real file I/O; tests the pipeline architecture, not just a pure function |
| Tool support | Full | nextest with tempdir fixture helpers |
| Estimated proof time | < 2s | Small fixtures; fast I/O |

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-05 | architect |
| Proof harness committed | — | formal-verifier |
| Proof first passed | — | formal-verifier |
| Locked (VERIFIED) | — | formal-verifier |
