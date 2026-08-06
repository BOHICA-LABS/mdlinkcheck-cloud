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
source_bc: BC-2.08.004
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
    change: "(P4-014) test file path corrected: tests/integration/ignored_file_anchor.rs → tests/integration_ignored_file_anchor.rs (flat Cargo-discoverable layout per tooling-selection.md §Test Target Layout)."
  - version: "1.1"
    date: 2026-08-05
    change: "P2-M05 + P2-M14 remediation: corrected Source Contract title from invented 'BC-2.08.004 — Ignored File Anchor Resolution' to actual BC-2.08.004 H1 'Cross-file anchor into ignored file'. Widened Property Statement from --ignore case only (1 of 4 DI-006 mechanisms) to all 4 mechanisms. Added three new fixture harnesses for .gitignore'd targets, dot-directory targets, and outside-scan-root targets — the three cases that use Pass 1.5 (structurally different from the --ignore case 1 which is handled entirely by Pass 1 anchor-table inclusion)."
deprecated: null
deprecated_by: null
replacement: null
retired: null
withdrawn: null
withdrawal_reason: null
removed: null
removal_reason: null
---

# VP-016: Ignored Files Have Anchor Tables — Cross-File Anchors into Ignored Files Resolve

## Property Statement

All four source-exclusion mechanisms in DI-006 exclude files as SOURCES only. The excluded file remains a valid anchor target, and links pointing TO it from non-excluded files must not produce false positives (broken verdicts).

The four mechanisms and their handling:

1. **`--ignore` patterns** (Pass 1 — anchor table built, file not scanned): `ignored.md` is included in the AnchorIndex built during Pass 1; it is not walked as a source.
2. **`.gitignore` patterns** (Pass 1.5 — out-of-scan anchor lookup): `gitignored-target.md` is not in the scan set; Pass 1.5 opens it directly to build its anchor table on demand.
3. **Dot-directory contents** (Pass 1.5 — out-of-scan anchor lookup): `.hidden/target.md` is in a dot-directory skipped by Pass 1; Pass 1.5 opens it directly when a link targets it.
4. **Outside-scan-root paths** (Pass 1.5 — out-of-scan anchor lookup): `../parent/target.md` is above the scan root; Pass 1.5 opens it directly using the resolved absolute path.

This is DI-006.

## Source Contract

- **BC:** BC-2.08.004 — Cross-file anchor into ignored file
- **Postcondition/Invariant:** DI-006 — all four source-exclusion mechanisms exclude files as sources only; they remain valid anchor targets; links TO them must not produce false positives.

## Proof Method

| Method | Tool | Bounded? | Coverage |
|--------|------|----------|----------|
| integration | nextest 0.9.129 | yes — fixture-based | Four fixtures: (1) `--ignore` target, (2) `.gitignore`'d target, (3) dot-directory target, (4) outside-scan-root target |

## Proof Harness Skeleton

```rust
// tests/integration_ignored_file_anchor.rs  (flat layout per tooling-selection.md §Test Target Layout)

// Case 1: --ignore pattern (Pass 1 anchor table inclusion)
#[test]
fn vp016_ignored_file_is_valid_anchor_target() {
    let dir = tempdir();
    write_file(&dir, "source.md", "[link](./ignored.md#important-section)");
    write_file(&dir, "ignored.md", "# Important Section\nContent.");

    let opts = ScanOpts {
        ignore_patterns: vec!["ignored.md"],
        ..Default::default()
    };
    let findings = run_scan(&dir, opts);

    let broken: Vec<_> = findings.iter()
        .filter(|f| f.source_file.ends_with("source.md") && f.is_broken())
        .collect();
    assert!(broken.is_empty(),
        "Links to --ignore'd files must not produce false positives: {:?}", broken);

    let from_ignored: Vec<_> = findings.iter()
        .filter(|f| f.source_file.ends_with("ignored.md"))
        .collect();
    assert!(from_ignored.is_empty(),
        "Ignored file must not appear as a source of findings");
}

// Case 2: .gitignore'd target (Pass 1.5 on-demand anchor lookup)
#[test]
fn vp016_gitignored_target_is_valid_anchor_target() {
    let dir = tempdir();
    write_file(&dir, ".gitignore", "gitignored-target.md\n");
    write_file(&dir, "source.md", "[link](./gitignored-target.md#the-heading)");
    write_file(&dir, "gitignored-target.md", "# The Heading\nContent.");

    // No --ignore flags; gitignore'd files are excluded by the ignore crate
    let findings = run_scan(&dir, ScanOpts::default());

    let broken: Vec<_> = findings.iter()
        .filter(|f| f.source_file.ends_with("source.md") && f.is_broken())
        .collect();
    assert!(broken.is_empty(),
        "Links to .gitignore'd files must not produce false positives: {:?}", broken);
}

// Case 3: dot-directory target (Pass 1.5 on-demand anchor lookup)
#[test]
fn vp016_dot_dir_target_is_valid_anchor_target() {
    let dir = tempdir();
    write_file(&dir, "source.md", "[link](./.hidden/target.md#dot-heading)");
    // .hidden/ is a dot-directory — skipped unconditionally by Pass 1 (D-011)
    let hidden = dir.path().join(".hidden");
    fs::create_dir_all(&hidden).unwrap();
    write_file_at(&hidden, "target.md", "# Dot Heading\nContent.");

    let findings = run_scan(&dir, ScanOpts::default());

    let broken: Vec<_> = findings.iter()
        .filter(|f| f.source_file.ends_with("source.md") && f.is_broken())
        .collect();
    assert!(broken.is_empty(),
        "Links into dot-directories must not produce false positives: {:?}", broken);
}

// Case 4: outside-scan-root target (Pass 1.5 on-demand anchor lookup)
#[test]
fn vp016_outside_scan_root_target_is_valid_anchor_target() {
    // parent/
    //   target.md   ← outside scan root
    //   project/
    //     source.md ← scan root is project/
    let parent = tempdir();
    write_file_at(parent.path(), "target.md", "# Parent Heading\nContent.");
    let project = parent.path().join("project");
    fs::create_dir_all(&project).unwrap();
    write_file_at(&project, "source.md", "[link](../target.md#parent-heading)");

    // Scan root is project/; ../target.md is outside the scan root
    let findings = run_scan(&project, ScanOpts::default());

    let broken: Vec<_> = findings.iter()
        .filter(|f| f.source_file.ends_with("source.md") && f.is_broken())
        .collect();
    assert!(broken.is_empty(),
        "Links outside scan root must not produce false positives: {:?}", broken);
}
```

## Feasibility Assessment

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Input space size | Fixture-based | Four fixtures; each tests one DI-006 mechanism |
| Proof complexity | Low–Medium | Cases 1 is Pass 1 anchor-table inclusion. Cases 2–4 require Pass 1.5 to open non-scanned files; tests verify the on-demand lookup path |
| Tool support | Full | nextest + tempdir; `.gitignore` fixture requires writing a real `.gitignore` file in the temp directory |
| Estimated proof time | < 2s | Small fixtures; the gitignore parsing is the slowest step |

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-05 | architect |
| Proof harness committed | — | formal-verifier |
| Proof first passed | — | formal-verifier |
| Locked (VERIFIED) | — | formal-verifier |
