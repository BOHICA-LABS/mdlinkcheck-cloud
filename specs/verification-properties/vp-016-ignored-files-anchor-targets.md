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
  - version: "1.3"
    date: 2026-08-07
    change: "BI-025 vacuity repair: prior v1.2 was outright vacuous — run_scan(_) -> vec![] trivially satisfies all four broken.is_empty() assertions. Added a 'control broken link' to each fixture's source file (link to definitely-not-here-xyzzy.md); each fixture now asserts the control IS broken (proving the scanner ran). Added 'source-not-scanned' assertions to cases 2-4: a broken link INSIDE the excluded file proves the excluded file was NOT scanned as a source. Added Fixture 5: vp016_pass15_missing_target_yields_broken_not_io_error, covering DI-006's Pass 1.5 missing-target rule (a non-existent Pass 1.5 target yields a broken verdict, not an IoError). Added Non-Vacuousness Analysis section."
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

Additionally, DI-006's **Pass 1.5 missing-target rule** (P2-C05): if a Pass 1.5 target path does not exist, Pass 2 produces an ordinary `broken` verdict (`file-not-found`), NOT an `IoError`. The non-existent target exits 1, never 2.

**Falsified by:** An implementation `run_scan(_) -> vec![]` (no-op scanner) passes the prior `broken.is_empty()` assertions trivially but fails the control assertion in each fixture (expected 1 broken for the control link `definitely-not-here-xyzzy.md`, got 0).

This is DI-006.

## Source Contract

- **BC:** BC-2.08.004 — Cross-file anchor into ignored file
- **Postcondition/Invariant:** DI-006 — all four source-exclusion mechanisms exclude files as sources only; they remain valid anchor targets; links TO them must not produce false positives.

## Proof Method

| Method | Tool | Bounded? | Coverage |
|--------|------|----------|----------|
| integration | nextest 0.9.129 | yes — fixture-based | Five fixtures: (1) `--ignore` target, (2) `.gitignore`'d target, (3) dot-directory target, (4) outside-scan-root target, (5) Pass 1.5 missing-target rule |

## Proof Harness Skeleton

```rust
// tests/integration_ignored_file_anchor.rs  (flat layout per tooling-selection.md §Test Target Layout)

// Case 1: --ignore pattern (Pass 1 anchor table inclusion)
//
// Control: source.md also links to definitely-not-here-xyzzy.md — this file does not
// exist, so the scanner MUST report it as broken. A no-op scanner fails this assertion.
// Source-not-scanned: ignored.md contains a broken link; no finding should originate
// from ignored.md (proving it was excluded as a source).
#[test]
fn vp016_ignored_file_is_valid_anchor_target() {
    let dir = tempdir();
    write_file(&dir, "source.md",
        "[good](./ignored.md#important-section)\n\
         [control](./definitely-not-here-xyzzy.md)");
    write_file(&dir, "ignored.md",
        "# Important Section\nContent.\n\
         [internal-broken](./also-not-here-xyzzy.md)");

    let opts = ScanOpts {
        ignore_patterns: vec!["ignored.md"],
        ..Default::default()
    };
    let findings = run_scan(&dir, opts);

    // Control: scanner must detect the broken link to definitely-not-here-xyzzy.md.
    let control: Vec<_> = findings.iter()
        .filter(|f| f.link_target.contains("definitely-not-here-xyzzy") && f.is_broken())
        .collect();
    assert_eq!(control.len(), 1,
        "Control: scanner must detect broken link to definitely-not-here-xyzzy.md \
         (no-op scanner yields 0 broken, expected 1)");

    // Primary: no broken verdict for the link to ignored.md#important-section.
    let false_positive: Vec<_> = findings.iter()
        .filter(|f| f.source_file.ends_with("source.md")
            && f.link_target.contains("important-section")
            && f.is_broken())
        .collect();
    assert!(false_positive.is_empty(),
        "Links to --ignore'd files must not produce false positives: {:?}", false_positive);

    // Source-not-scanned: ignored.md must not appear as a source of any finding.
    let from_ignored: Vec<_> = findings.iter()
        .filter(|f| f.source_file.ends_with("ignored.md"))
        .collect();
    assert!(from_ignored.is_empty(),
        "Ignored file must not appear as a source of findings: {:?}", from_ignored);
}

// Case 2: .gitignore'd target (Pass 1.5 on-demand anchor lookup)
//
// The ignore crate's WalkBuilder respects .gitignore files found in the directory tree
// regardless of whether a .git directory is present (local .gitignore files are always
// processed). gitignored-target.md is excluded from the scan set; Pass 1.5 opens it
// directly to build its anchor table.
//
// Control: source.md also links to definitely-not-here-xyzzy.md — must be broken.
// Source-not-scanned: gitignored-target.md contains a link to also-not-here-xyzzy.md;
// no finding should originate from gitignored-target.md (proving Pass 1 excluded it).
#[test]
fn vp016_gitignored_target_is_valid_anchor_target() {
    let dir = tempdir();
    write_file(&dir, ".gitignore", "gitignored-target.md\n");
    write_file(&dir, "source.md",
        "[good](./gitignored-target.md#the-heading)\n\
         [control](./definitely-not-here-xyzzy.md)");
    write_file(&dir, "gitignored-target.md",
        "# The Heading\nContent.\n\
         [internal-broken](./also-not-here-xyzzy.md)");

    let findings = run_scan(&dir, ScanOpts::default());

    // Control: scanner must detect the broken link to definitely-not-here-xyzzy.md.
    let control: Vec<_> = findings.iter()
        .filter(|f| f.link_target.contains("definitely-not-here-xyzzy") && f.is_broken())
        .collect();
    assert_eq!(control.len(), 1,
        "Control: scanner must detect broken link to definitely-not-here-xyzzy.md \
         (no-op scanner yields 0 broken, expected 1)");

    // Primary: no false positive for the link to gitignored-target.md#the-heading.
    let false_positive: Vec<_> = findings.iter()
        .filter(|f| f.source_file.ends_with("source.md")
            && f.link_target.contains("the-heading")
            && f.is_broken())
        .collect();
    assert!(false_positive.is_empty(),
        "Links to .gitignore'd files must not produce false positives: {:?}", false_positive);

    // Source-not-scanned: gitignored-target.md must not appear as a source of findings.
    // If it were scanned as a source, its link to also-not-here-xyzzy.md would appear.
    let from_gitignored: Vec<_> = findings.iter()
        .filter(|f| f.source_file.ends_with("gitignored-target.md"))
        .collect();
    assert!(from_gitignored.is_empty(),
        "Gitignored file must not appear as a source of findings: {:?}", from_gitignored);
}

// Case 3: dot-directory target (Pass 1.5 on-demand anchor lookup)
//
// .hidden/ is a dot-directory — skipped unconditionally by Pass 1 (D-011).
// Pass 1.5 opens .hidden/target.md directly when a link from source.md targets it.
//
// Control: source.md also links to definitely-not-here-xyzzy.md — must be broken.
// Source-not-scanned: .hidden/target.md contains a broken link; no finding should
// originate from it (proving it was excluded as a source).
#[test]
fn vp016_dot_dir_target_is_valid_anchor_target() {
    let dir = tempdir();
    write_file(&dir, "source.md",
        "[good](./.hidden/target.md#dot-heading)\n\
         [control](./definitely-not-here-xyzzy.md)");
    let hidden = dir.path().join(".hidden");
    fs::create_dir_all(&hidden).unwrap();
    write_file_at(&hidden, "target.md",
        "# Dot Heading\nContent.\n\
         [internal-broken](./also-not-here-xyzzy.md)");

    let findings = run_scan(&dir, ScanOpts::default());

    // Control: scanner must detect the broken link to definitely-not-here-xyzzy.md.
    let control: Vec<_> = findings.iter()
        .filter(|f| f.link_target.contains("definitely-not-here-xyzzy") && f.is_broken())
        .collect();
    assert_eq!(control.len(), 1,
        "Control: scanner must detect broken link to definitely-not-here-xyzzy.md \
         (no-op scanner yields 0 broken, expected 1)");

    // Primary: no false positive for the link to .hidden/target.md#dot-heading.
    let false_positive: Vec<_> = findings.iter()
        .filter(|f| f.source_file.ends_with("source.md")
            && f.link_target.contains("dot-heading")
            && f.is_broken())
        .collect();
    assert!(false_positive.is_empty(),
        "Links into dot-directories must not produce false positives: {:?}", false_positive);

    // Source-not-scanned: .hidden/target.md must not appear as a source of findings.
    let from_dot_dir: Vec<_> = findings.iter()
        .filter(|f| f.source_file.contains(".hidden"))
        .collect();
    assert!(from_dot_dir.is_empty(),
        "Dot-directory file must not appear as a source of findings: {:?}", from_dot_dir);
}

// Case 4: outside-scan-root target (Pass 1.5 on-demand anchor lookup)
//
// target.md is above the scan root; Pass 1 does not traverse it.
// Pass 1.5 opens it directly using the resolved absolute path.
//
// Control: project/source.md also links to definitely-not-here-xyzzy.md — must be broken.
// Source-not-scanned: ../target.md contains a broken link; no finding should originate
// from target.md (proving it was excluded as a source, as it is outside the scan root).
#[test]
fn vp016_outside_scan_root_target_is_valid_anchor_target() {
    // parent/
    //   target.md   ← outside scan root; has a broken link inside it
    //   project/
    //     source.md ← scan root is project/
    let parent = tempdir();
    write_file_at(parent.path(), "target.md",
        "# Parent Heading\nContent.\n\
         [internal-broken](./also-not-here-xyzzy.md)");
    let project = parent.path().join("project");
    fs::create_dir_all(&project).unwrap();
    write_file_at(&project, "source.md",
        "[good](../target.md#parent-heading)\n\
         [control](./definitely-not-here-xyzzy.md)");

    let findings = run_scan(&project, ScanOpts::default());

    // Control: scanner must detect the broken link to definitely-not-here-xyzzy.md.
    let control: Vec<_> = findings.iter()
        .filter(|f| f.link_target.contains("definitely-not-here-xyzzy") && f.is_broken())
        .collect();
    assert_eq!(control.len(), 1,
        "Control: scanner must detect broken link to definitely-not-here-xyzzy.md \
         (no-op scanner yields 0 broken, expected 1)");

    // Primary: no false positive for the link to ../target.md#parent-heading.
    let false_positive: Vec<_> = findings.iter()
        .filter(|f| f.source_file.ends_with("source.md")
            && f.link_target.contains("parent-heading")
            && f.is_broken())
        .collect();
    assert!(false_positive.is_empty(),
        "Links outside scan root must not produce false positives: {:?}", false_positive);

    // Source-not-scanned: ../target.md must not appear as a source of findings.
    // If it were scanned, its broken link to also-not-here-xyzzy.md would appear.
    let from_outside: Vec<_> = findings.iter()
        .filter(|f| f.source_file.ends_with("target.md"))
        .collect();
    assert!(from_outside.is_empty(),
        "Outside-scan-root file must not appear as a source of findings: {:?}", from_outside);
}

// Case 5: Pass 1.5 missing-target rule — non-existent Pass 1.5 target yields broken, not IoError.
//
// DI-006 Pass 1.5 missing-target rule (P2-C05): if Pass 1.5 cannot find a linked .md file,
// it produces no AnchorIndex entry. Pass 2 then produces a broken verdict (file-not-found).
// Only read failures on scan-set files (reached by Pass 1) contribute to io_errors and exit 2.
// A link to a non-existent out-of-scan-set target must exit 1 (broken link), never exit 2.
//
// Falsified by: an implementation that records an IoError for missing Pass 1.5 targets,
// causing exit 2 when the user expected exit 1 (broken link to a typo'd filename).
#[test]
fn vp016_pass15_missing_target_yields_broken_not_io_error() {
    let dir = tempdir();
    // source.md links to missing.md which does not exist — a Pass 1.5 lookup that finds nothing
    write_file(&dir, "source.md", "[link](./missing-target.md#some-heading)");

    let (findings, io_errors) = run_scan_with_io_errors(&dir, ScanOpts::default());

    // The missing-target link must produce a broken verdict (file-not-found), not an IoError.
    let broken: Vec<_> = findings.iter().filter(|f| f.is_broken()).collect();
    assert_eq!(broken.len(), 1,
        "Link to non-existent Pass 1.5 target must produce exactly one broken finding \
         (not zero: proves Pass 2 ran; not IoError: DI-006 missing-target rule)");

    // Must NOT produce an IoError — missing Pass 1.5 targets are a normal broken verdict.
    assert!(io_errors.is_empty(),
        "Pass 1.5 missing-target must NOT emit IoError (DI-006 P2-C05 rule: \
         only scan-set read failures produce IoErrors; non-existent targets exit 1, not 2). \
         Got io_errors: {:?}", io_errors);
}
```

## Non-Vacuousness Analysis

Five wrong implementations are falsified by this VP:

| Wrong Implementation | Falsifying Harness | Failure Mode |
|---|---|---|
| `run_scan(_) -> vec![]` (no-op scanner) | Control assertion in all 4 positive fixtures | expected 1 broken (`definitely-not-here-xyzzy.md`), got 0 |
| Pass 1 skips excluded files entirely (no Pass 1.5) | Cases 2, 3, 4 primary assertions | `gitignored-target.md#the-heading` etc. appear as broken (anchor table not built) |
| Excluded files scanned as sources | Cases 2, 3, 4 source-not-scanned assertions | findings originate from excluded file (its `also-not-here-xyzzy.md` link is reported) |
| Missing Pass 1.5 target produces IoError | Case 5 io_errors assertion | io_errors is non-empty, expected empty |
| Missing Pass 1.5 target produces no finding | Case 5 broken assertion | broken.len() == 0, expected 1 |

## Feasibility Assessment

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Input space size | Fixture-based | Five fixtures; each tests one DI-006 mechanism |
| Proof complexity | Low–Medium | Cases 1 is Pass 1 anchor-table inclusion. Cases 2–4 require Pass 1.5 to open non-scanned files. Case 5 requires run_scan_with_io_errors harness helper returning (Vec<Finding>, Vec<IoError>) |
| Tool support | Full | nextest + tempdir; `.gitignore` fixture requires writing a real `.gitignore` file in the temp directory |
| Estimated proof time | < 2s | Small fixtures; the gitignore parsing is the slowest step |
| API note | Case 5 requires `run_scan_with_io_errors` helper | This helper returns both `Vec<Finding>` and `Vec<IoError>` separately, needed to distinguish exit-1 from exit-2 conditions at the library level |

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-05 | architect |
| v1.3 — BI-025 vacuity repair: control + source-not-scanned assertions, Pass 1.5 missing-target fixture | 2026-08-07 | architect |
| Proof harness committed | — | formal-verifier |
| Proof first passed | — | formal-verifier |
| Locked (VERIFIED) | — | formal-verifier |
