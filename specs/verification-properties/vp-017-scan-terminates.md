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

`scanner::scan(root, opts)` terminates and returns for any directory tree, including trees containing symlink cycles (e.g., a directory symlink that points to a parent directory). The `ignore` crate's built-in symlink cycle detection is relied upon; this property verifies it is correctly configured and not accidentally disabled. This is DI-009.

## Source Contract

- **BC:** BC-2.01.004 — Dot-directory skip (unconditional, D-011)
- **Postcondition/Invariant:** DI-009 — `scanner::scan` terminates for any directory tree; symlink cycles do not cause infinite traversal.

## Proof Method

| Method | Tool | Bounded? | Coverage |
|--------|------|----------|----------|
| integration | nextest 0.9.129 | yes — fixture-based | Fixture with a symlink cycle (dir → parent dir); verified that scan returns within 5 seconds |

## Proof Harness Skeleton

```rust
// tests/integration_scan_termination.rs  (flat layout per tooling-selection.md §Test Target Layout)
#[cfg(unix)] // symlinks on Unix; Windows requires elevated privileges
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

    write_file(root, "README.md", "# Hello\n[link](./sub/other.md)");

    let start = Instant::now();
    let _ = scan(root, ScanOpts::default()); // must return
    let elapsed = start.elapsed();

    assert!(elapsed < Duration::from_secs(5),
        "Scan with symlink cycle must terminate within 5s, took {:?}", elapsed);
}

#[test]
fn vp017_empty_dir_terminates() {
    let dir = tempdir();
    let result = scan(dir.path(), ScanOpts::default());
    assert!(result.is_ok());
}
```

## Feasibility Assessment

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Input space size | Fixture-based | Symlink cycle fixture + empty dir; sufficient to verify `ignore` crate configuration |
| Proof complexity | Low | `ignore` crate handles cycle detection; test verifies it is not accidentally disabled |
| Tool support | Full | nextest; Unix-only symlink test gated on `#[cfg(unix)]` |
| Estimated proof time | < 2s | Symlink detection is fast |

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-05 | architect |
| Proof harness committed | — | formal-verifier |
| Proof first passed | — | formal-verifier |
| Locked (VERIFIED) | — | formal-verifier |
