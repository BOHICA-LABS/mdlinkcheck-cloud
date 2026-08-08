---
document_type: verification-property
level: L4
version: "1.4"
status: draft
producer: architect
timestamp: 2026-08-05T20:00:00Z
phase: 1b
inputs:
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/architecture/module-decomposition.md
input-hash: "3efc65a"
traces_to: .factory/specs/architecture/ARCH-INDEX.md
source_bc: BC-2.01.004
module: scanner
proof_method: integration
feasibility: feasible
verification_lock: false
proof_completed_date: null
proof_file_hash: null
lifecycle_status: active
introduced: v0.1.0
modified:
  - version: "1.4"
    date: 2026-08-07
    change: "BI-025 vacuity repair: prior v1.3 was outright vacuous — scan(_,_) -> Ok(vec![]) trivially satisfies both fixtures. (1) vp017_symlink_cycle_terminates used 'let _ = scan(...)' discarding the result entirely — a no-op returns Ok(vec![]) in 0ms, well under the 5s bound, so only timing was checked. Fixed: capture result; assert scanner found README.md's broken link to ./sub/other.md (proving traversal happened before cycle was encountered). (2) vp017_empty_dir_terminates asserted only result.is_ok() — trivially satisfied by Ok(vec![]). Added vp017_non_empty_dir_finds_broken_links: a dir with a known broken link must produce a finding, proving the scanner traverses and extracts links. Added Non-Vacuousness Analysis section."
  - version: "1.3"
    date: 2026-08-06
    change: "D-043 macOS-only platform directive: updated #[cfg(unix)] comment — removed Windows reference (macOS is the only target; macOS is Unix). #[cfg(unix)] attribute is still correct and remains unchanged."
  - version: "1.2"
    date: 2026-08-06
    change: "(P4-014) test file path corrected: tests/integration/scan_termination.rs → tests/integration_scan_termination.rs (flat Cargo-discoverable layout per tooling-selection.md §Test Target Layout)."
  - version: "1.1"
    date: 2026-08-05
    change: "P2-M05 remediation: corrected Source Contract title from invented 'BC-2.01.004 — Scan Termination with Symlink Cycle Handling' to actual BC-2.01.004 H1 'Dot-directory skip (unconditional, D-011)'."
deprecated: null
deprecated_by: null
replacement: null
retired: null
withdrawn: null
withdrawal_reason: null
removed: null
removal_reason: null
---

# VP-017: Scan Terminates for Any Directory Tree Including Symlink Cycles

## Property Statement

`scanner::scan(root, opts)` terminates and returns for any directory tree, including trees containing symlink cycles (e.g., a directory symlink that points to a parent directory). The `ignore` crate's built-in symlink cycle detection is relied upon; this property verifies it is correctly configured and not accidentally disabled.

Termination alone is insufficient — a no-op scanner trivially terminates in 0 ms without traversing anything. This VP additionally verifies that the scanner correctly traverses non-cycle content even when a cycle is present: files reachable without following the cycle symlink must still be processed and their links checked.

**Falsified by:**
- A no-op `scan(_) -> Ok(vec![])` terminates instantly and satisfies the timing assertion but fails `vp017_non_empty_dir_finds_broken_links` (expected 1 broken finding, got 0) and fails the post-cycle content assertion in `vp017_symlink_cycle_terminates` (README.md's broken link to `./sub/other.md` not detected).
- A scanner with cycle detection accidentally disabled would loop indefinitely on the symlink cycle, exceeding the 5 s bound.

This is DI-009.

## Source Contract

- **BC:** BC-2.01.004 — Dot-directory skip (unconditional, D-011)
- **Postcondition/Invariant:** DI-009 — `scanner::scan` terminates for any directory tree; symlink cycles do not cause infinite traversal.

## Proof Method

| Method | Tool | Bounded? | Coverage |
|--------|------|----------|----------|
| integration | nextest 0.9.129 | yes — fixture-based | Three fixtures: (1) symlink cycle — scanner terminates AND processes non-cycle content, (2) empty dir — scanner returns Ok(()), (3) non-empty dir without cycles — scanner finds expected broken link |

## Proof Harness Skeleton

```rust
// tests/integration_scan_termination.rs  (flat layout per tooling-selection.md §Test Target Layout)

// Fixture 1: symlink cycle — terminates AND processes content correctly.
//
// Tree structure:
//   root/
//     README.md         ← contains a broken link to ./sub/other.md
//     sub/
//       cycle -> root   ← directory symlink pointing back to root (cycle)
//
// sub/other.md does not exist. After a correct scan, findings must include
// 1 broken finding for the link in README.md to ./sub/other.md.
//
// A no-op scanner: returns Ok(vec![]) in 0ms — PASSES the timing check but
//   FAILS the content assertion (expected 1 broken, got 0).
// A scanner with cycle detection disabled: loops forever through cycle/ ->
//   root/ -> sub/ -> cycle/ -> ... — FAILS the timing assertion (>> 5s).
// A correct scanner: traverses root/, finds README.md, enters sub/, encounters
//   cycle (symlink to parent — skipped by ignore crate cycle detection), returns
//   with 1 broken finding for ./sub/other.md.
#[cfg(unix)] // macOS is Unix; symlink creation works without elevated privileges on macOS
#[test]
fn vp017_symlink_cycle_terminates() {
    use std::os::unix::fs::symlink;
    use std::time::{Duration, Instant};

    let dir = tempdir();
    let root = dir.path();

    // Create: root/sub/cycle -> root (symlink cycle)
    let sub = root.join("sub");
    fs::create_dir(&sub).unwrap();
    let cycle_link = sub.join("cycle");
    symlink(root, &cycle_link).unwrap();

    // README.md contains a broken link — sub/other.md does not exist.
    write_file(root, "README.md", "# Hello\n[link](./sub/other.md)");

    let start = Instant::now();
    let findings = scan(root, ScanOpts::default())
        .expect("scan must succeed even with a symlink cycle");
    let elapsed = start.elapsed();

    // Termination assertion: cycle detection must prevent infinite traversal.
    assert!(elapsed < Duration::from_secs(5),
        "Scan with symlink cycle must terminate within 5s, took {:?}", elapsed);

    // Content assertion: README.md must be processed and its broken link detected.
    // This fails a no-op scanner (returns empty; no broken findings).
    let broken: Vec<_> = findings.iter()
        .filter(|f| f.link_target.contains("sub/other.md") && f.is_broken())
        .collect();
    assert_eq!(broken.len(), 1,
        "Scanner must process README.md and detect the broken link to ./sub/other.md \
         (no-op scanner returns 0 findings; proves traversal was not accidentally prevented \
         by cycle detection)");
}

// Fixture 2: empty directory — scanner returns Ok with no findings.
//
// This is a minimal sanity check. An empty directory has no markdown files,
// so there are no links to check and no findings to report.
// result.is_ok() is not falsifiable by a no-op scanner alone; see Fixture 3
// for the falsifying content assertion.
#[test]
fn vp017_empty_dir_terminates() {
    let dir = tempdir();
    let result = scan(dir.path(), ScanOpts::default());
    assert!(result.is_ok(),
        "Scanning an empty directory must succeed (not panic or error)");
    let findings = result.unwrap();
    assert!(findings.is_empty(),
        "Empty directory must produce no findings");
}

// Fixture 3: non-empty directory without cycles — scanner finds expected broken link.
//
// This is the PRIMARY non-vacuousness fixture for VP-017.
// A tree with one .md file containing one broken link must produce exactly one
// broken finding. A no-op scanner returning Ok(vec![]) fails this assertion.
//
// Falsified by: scan(_) -> Ok(vec![]) returns 0 findings, expected 1.
#[test]
fn vp017_non_empty_dir_finds_broken_links() {
    let dir = tempdir();
    write_file(dir.path(), "index.md",
        "# Index\n[broken](./does-not-exist-xyzzy.md)");

    let findings = scan(dir.path(), ScanOpts::default())
        .expect("scan must succeed");

    // Scanner must detect the broken link — does-not-exist-xyzzy.md does not exist.
    let broken: Vec<_> = findings.iter()
        .filter(|f| f.link_target.contains("does-not-exist-xyzzy") && f.is_broken())
        .collect();
    assert_eq!(broken.len(), 1,
        "Scanner must traverse index.md and report its broken link \
         (no-op scanner yields 0 findings; expected 1). \
         This proves the scanner traverses non-empty directories and checks links.");
}
```

## Non-Vacuousness Analysis

Three wrong implementations are falsified by this VP:

| Wrong Implementation | Falsifying Harness | Failure Mode |
|---|---|---|
| `scan(_) -> Ok(vec![])` (no-op scanner) | vp017_non_empty_dir_finds_broken_links (Fixture 3) | expected 1 broken finding, got 0 |
| `scan(_) -> Ok(vec![])` (no-op scanner) | vp017_symlink_cycle_terminates content assertion | expected 1 broken for `sub/other.md`, got 0 |
| Cycle detection disabled | vp017_symlink_cycle_terminates timing assertion | scan runs indefinitely through cycle — exceeds 5 s bound |

Fixtures 1 and 3 together ensure the scanner both terminates under adversarial input
(cycle) and produces correct output under normal input (non-empty dir). A no-op
scanner passes the termination timing check but fails both content assertions.

## Feasibility Assessment

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Input space size | Fixture-based | Symlink cycle fixture + empty dir + non-empty dir; sufficient to verify `ignore` crate configuration and traversal |
| Proof complexity | Low | `ignore` crate handles cycle detection; test verifies it is not accidentally disabled |
| Tool support | Full | nextest; Unix-only symlink test gated on `#[cfg(unix)]` |
| Estimated proof time | < 2s | Symlink detection is fast |

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-05 | architect |
| v1.4 — BI-025 vacuity repair: content assertions added; Fixture 3 added | 2026-08-07 | architect |
| Proof harness committed | — | formal-verifier |
| Proof first passed | — | formal-verifier |
| Locked (VERIFIED) | — | formal-verifier |
