---
document_type: adversary-convergence-audit
level: ops
version: "1.0"
status: complete-material-findings
producer: vsdd-factory:state-manager
story_id: S-1.01
cycle: v1.0.0-greenfield
head_sha: 9badc02
perimeter_decision: D-254
passes_covered: [19, 20, 21]
pass_21_status: complete-material-findings
timestamp: "2026-08-11T00:00:00Z"
---

# Confirming Round Passes 19–21 — Adversary Convergence Audit (Second Confirming Round)

## Verdict

**SECOND CONFIRMING ROUND NOT CLEAN.**

All three passes (19, 20, and 21) returned `MATERIAL_FINDINGS` on the frozen six-lens perimeter (L1–L6). `passes_clean` remains 0 of 3 required.

**CRITICAL QUALITATIVE SHIFT — record prominently.** All three passes independently reported **ZERO new defects in L1 (spec-compliance), L2 (code-correctness), L3 (test-integrity), L4 (hostile filesystem / platform semantics), and L5 (public API contract / downstream consumability)**. Every round-2 finding is **L6 / documentation-class, and every material one is a residual of the fix wave itself** — not a defect in production code or the test corpus.

- Pass 19 states production code and the 44-test corpus are correct, mutation-covered, and honestly documented.
- Pass 20 states the same and that no finding requires a change to `scanner.rs`, `types.rs`, or any test body.
- Pass 21 states it is CLEAN on its assigned L2/L4/L5 emphasis.

The three material findings (items 1–3 below) are documentation-class fix-residuals traceable to this session's own remediation wave, not to S-1.01 source or test logic. Per D-261 scoping, they are HIGH+MEDIUM and must be fixed before the confirming round can conclude. Items 4–9 are LOW/NITPICK and route to the register as disclosed-at-wave-1-gate per the established D-261 pattern.

---

## Pass 21 — Definitive L2 WalkBuilder Option Enumeration

**Record in full — this is the most valuable artifact of the round.**

Pass 21 enumerated every `WalkBuilder` option against the locked `ignore 0.4.33` source and established that **`parents` was the UNIQUE implicit default whose value was RESTRICTIVE** (able to remove files from the scan set). All seven restrictive options are now explicitly written in the builder chain: `hidden`, `git_ignore`, `ignore`, `git_global`, `git_exclude`, `require_git`, `parents`.

Every remaining implicit option (`max_depth`, `min_depth`, `max_filesize`, `same_file_system`, `ignore_case_insensitive`, `overrides`, `types`, `sort_by_*`, `threads`, `skip_stdout`, `add_ignore`, `add_custom_ignore_filename`, `current_dir`) defaults permissive or no-op, so none can cause a silent exclusion — the worst a regression could do is silently INCLUDE, which the existing exact-count assertions would catch.

**Conclusion:** There is no second `parents`-class (L-88) defect in `build_walk`, and the audit that would have caught P18-03 eighteen passes earlier is now on record.

Pass 21 also verified from crate source:

- `filter_entry` runs LAST in `Walk::skip_entry` (`walk.rs:1043`), so no ignore-file whitelist, `overrides()`, or `types()` can defeat the dot-dir guard — making the S-1.02 `--ignore` composition instruction sound.
- `add_parents` ascends to the filesystem root with `has_git` forced false under `require_git(false)`, confirming the D-259 documentation claim of "no repository-root boundary" is accurate.

---

## Cross-Pass Corroboration

Two findings were found **independently by all three passes** — treated as highest confidence:

| P19 ID | P20 ID | P21 ID | Subject |
|--------|--------|--------|---------|
| P19-02 | P20-01 | P21-01 | `cargo-fuzz` `--locked` omission with misapplied justification in `justfile:505` |
| P19-04 | P20-02 | P21-02 | POL-11 `lefthook.yml` third `cargo nextest` site not hardened; mirror count false |

---

## Material Findings (OPEN — TO BE FIXED IN FRESH SESSION'S FIRST BURST)

All findings below were verified by the orchestrator through direct execution or direct file read per D-193 / L-81. The `vsdd-factory:adversary` agent type has Read/Grep/Glob only and cannot run commands; all empirical confirmation is orchestrator work.

---

### P19-01 — MEDIUM — L6 — Purity Regex Grouped-Arm Asymmetry

**Register row: BI-081.**

**Location:** `.github/workflows/ci.yml:329–349`; `justfile:242–262`; `FORBIDDEN_RE` pattern set.

**Claim:** `FORBIDDEN_RE` implements the grouped-import form as `std::\{[^}]*\b<name>\b` for **only `fs` and `net`**; for `stdout` and `Instant` the arms are the narrower `std::io::\{[^}]*\bstdout\b` / `std::time::\{[^}]*\bInstant\b`, which require the brace to open AFTER `io::`/`time::`. So `use std::{io::stdout, fmt::Debug}; stdout()` passes the detector with exit 0 — a live instance of the L-87 generalization failure.

**ORCHESTRATOR-CONFIRMED EMPIRICALLY:** Planting `use std::{io::stdout, fmt::Debug}; stdout()`, `use std::io::{self, Write}; io::stdout()`, and `use std::{time::Instant}; Instant::now()` into `mdlinkcheck-core` each yielded `just purity` exit 0 with the log line:
```
PASS: 3 .rs file(s) checked; no forbidden I/O or RNG path-fragments found (ADR-001).
Note: both non-grouped and grouped import forms were checked.
```
The log line overclaims — grouped coverage exists for only two of four forbidden `std` paths. Non-grouped `use std::fs;` correctly produces exit 1. The grouped-only gap for `stdout`/`Instant` is real and now confirmed.

**This is a live instance of L-87 recurring against the orchestrator's own verification.** The prior session's discrimination probe tested the `fs` grouped form and the fully-qualified form but not the `stdout`/`Instant` grouped forms, and generalized.

Material because this is the sole source-level ADR-001 erosion gate for 7 downstream stories and `std::io::stdout` in pure-core is a MANDATORY story rule.

**Note from pass 21:** Pass 21 separately verified that ALIASED grouped imports (`use std::{fs as _f, …}`) ARE caught, and that `println!`/`print!`/`write!` and macro-generated I/O are NOT. Pass 21 declined to file the macro gap as a separate finding — it is the registered sibling-gate class and ADR-001's text enumerates path-fragments, not macros.

---

### P19-02 / P20-01 / P21-01 — MEDIUM — L6 — cargo-fuzz `--locked` Omission with Misapplied Justification

**Register row: BI-082.**

**Location:** `justfile:505`; `hardening.yml:229`.

**Claim:** `justfile:505` is `cargo +nightly install cargo-fuzz --version 0.13.2` with NO `--locked`, while `hardening.yml:229` is the same line WITH `--locked`. The justfile comment claims "(matches hardening.yml:229)" — a false parity claim. The adjacent justification — "Verified: `cargo fuzz run` does not accept `--locked`" — is a CATEGORY ERROR: it annotates a `cargo install` invocation, and `cargo install --help` reports `--locked` twice.

**ORCHESTRATOR-CONFIRMED:** `cargo install --help` confirms `--locked` is a valid flag for `cargo install`. All five sibling tool installs in the same recipe use `--locked`.

**Two harms:**
1. `--version` pins `cargo-fuzz` itself while `--locked` pins its transitive dependency graph, so the local tool and the CI tool are not the same artifact, defeating the stated SEC-2 supply-chain intent locally.
2. The comment's "Verified" actively entrenches the divergence — a maintainer reconciling the false parity claim may delete `--locked` from `hardening.yml:229`, destroying the SEC-2 pin.

**ROOT CAUSE IS PARTLY ORCHESTRATOR-INDUCED.** The fix dispatch instructed the agent to document the orchestrator-probed fact that `cargo fuzz run` rejects `--locked` (true, probed) without scoping the instruction to the fuzz RUN recipes only. The agent attached that true fact to the `cargo install` line, manufacturing a false justification. See L-91 dispatch-discipline note attached to BI-082.

**Found independently by all three passes** — treat as highest confidence.

---

### P19-04 / P20-02 / P21-02 — MEDIUM — L6 — POL-11 Third `cargo nextest` Site Unhardened

**Register row: BI-083.**

**Location:** `lefthook.yml` pre-push command; `ci.yml`; `justfile`.

**Claim:** There are exactly three `cargo nextest run --locked --all-targets` sites: `ci.yml`, `justfile`, `lefthook.yml`. The POL-11 floors were added to the first two only. `lefthook.yml` still annotates its pre-push command `[mirrors CI job "Test (macos-latest)"]` and its header claims "4 of the 9 ci.yml jobs", but since `46cab5a` that CI job has TWO substantive steps and the hook runs ONE — so the truthful count is 3 fully-mirrored plus 1 partial.

**Material because:** The false-green POL-11 gap remains invisible locally. This repo HAS a `harness = false` binary (`global_gitignore_test.rs`) carrying BC-2.01.003 postconditions 2 and 3 alone; POL-11 exists to catch a C-E2/P14-03-class silent drop of exactly that binary. The one-line parity form is already used two lines below (`run: just purity`), so `run: just test` closes it.

**Alternative disposition (pass 21):** Frozen `tooling-selection.md:155–160` scopes POL-11 to "CI", so a git hook is arguably outside its literal remit — in which case correct the count and drop the mirror annotation instead. **Operator adjudication invited; either resolution closes it.**

**Found independently by all three passes** — treat as highest confidence.

---

## Low / Nitpick Findings (OPEN — DISCLOSED AT WAVE-1 GATE, NOT FIXED per D-261 scoping)

---

### P19-05 / P20-03 / P21-03 — LOW — Stale `scanner.rs` Line Citations

**Register row: BI-084.**

**Location:** `crates/mdlinkcheck/tests/scanner_discovery_tests.rs:1087` and `:1385`.

**Claim:** `:1087` cites `scanner.rs:59` for `require_git(false)` — line 59 is doc prose; the setter is at **89**. `:1385` cites `scanner.rs:103-104` for `is_dot_dir_name` — those are comment lines; the function body is at **145–147**.

**ORCHESTRATOR-CONFIRMED.** `47e11b0`'s ~35-line doc expansion shifted them; a self-inflicted propagation gap from this session's own fix wave.

Pass 21 verified all EXTERNAL citations remain accurate (`walk.rs:1043`, `dir.rs:560`, `pathutil.rs:156/158`, `api-surface.md:80`); only the two intra-repo ones drifted.

**Found independently by all three passes** — high confidence.

---

### P19-08 / P21-05 — LOW — Dot-Path Scan Root Exempt from Dot-Component Filter

**Register row: BI-085.**

**Location:** `crates/mdlinkcheck/src/scanner.rs:166`; `collect_md_files` post-filter.

**Claim:** `collect_md_files(<tmp>/.template.md)` returns 1 element. When `path == root`, `strip_prefix` yields the empty path, `components()` is empty, `.any()` is false, and `is_md_extension(".template.md")` is true. So the `47e11b0` doc's "structural and unconditional … always rejected" has a genuine hole at the root case.

**ORCHESTRATOR-CONFIRMED EMPIRICALLY:** `collect_md_files(<tmp>/.template.md)` returns 1. Not a blocker: BC-2.01.001 precondition 1 fixes the root as CWD; explicit-PATH roots are BC-2.01.002 which is NOT in S-1.01's contracts; and there is no CLI in S-1.01, so no user-reachable path exists under D-244.

**Route to S-1.02 as decidable input:** BC-2.01.002 must state whether an explicitly-named dot-directory or dot-file PATH is scanned, and the behaviour is inconsistent by construction (`mdlinkcheck docs/.template.md` yields the file, `mdlinkcheck docs/` does not).

Pass 21 adds: the depth-0 exemption's recorded rationale is a TEST artifact (`TempDir`'s `.tmp` prefix) rather than the semantic argument (the user chose that root); the semantic rationale is the one worth writing down if S-1.02 keeps the behaviour.

---

### P20-04 / P21-06 — LOW — VP-017 Divergence Undisclosed

**Register row: BI-086.**

**Location:** `.factory/specs/verification-properties/vp-017-scan-terminates.md`; `crates/mdlinkcheck/tests/scanner_discovery_tests.rs:869–965`.

**Claim:** The authoritative VP file declares `proof_method: integration`, test file `tests/integration_scan_termination.rs`, three named fixtures (`vp017_symlink_cycle_terminates`, `vp017_empty_dir_terminates`, `vp017_non_empty_dir_finds_broken_links`), and the symbol `scanner::scan(root, opts)`. None of these exist — S-1.01 delivers a single proptest `test_vp017_scan_terminates_arbitrary_tree` against `collect_md_files`, which story Task 10 legitimately authorizes. The VP's own fixtures require link extraction and broken-link verdicts that do not exist until E-2, and `scanner::scan`'s `opts` parameter is in direct tension with AC-008's compile-time single-argument proof of D-011.

**The defect is the MISSING DISCLOSURE:** this codebase discloses every comparable divergence in-comment (MSRV, `Link` absence, `AnchorTable` visibility, dot-file exclusion, the POL-11 `^tests::` corpus defect), and this is the one of comparable weight with no disclosure anywhere. A Phase-6 formal-verifier will hunt a non-existent harness and cannot tell whether it is missing or consciously re-scoped. Corpus defect under D-244 — disclose in source, do not fix the spec.

Found as L1 by pass 20 and as NEW_LENS spec-vs-spec by pass 21.

---

### P19-06 — LOW — `just spec-lint` LOUD-SKIP Exits 0

**Register row: BI-087.**

**Location:** `justfile` `spec-lint` recipe; `ci.yml` `Spec lint` job header.

**Claim:** The BI-070 remediation prints "SKIPPED (corpus unavailable) — not a failure, not a pass." then `exit 0`, while `ci.yml` states the project's own rule for this exact situation verbatim: "Exit 5 (PARTIAL/loud-skip) … Exit 0 here would be indistinguishable from a successful run to any consumer reading the exit code." The message was adopted; the exit code was not. Pass 21 did not report this independently; it falls within the known BI-070 remediation scope.

---

### P19-07 — NITPICK — Module Doc Count

**Register row: BI-088.**

**Location:** `crates/mdlinkcheck/tests/scanner_discovery_tests.rs:13–14`.

**Claim:** The module doc says "All 44 tests must pass" in a file containing **27** tests. 44 is the workspace total (27 + 16 `types_tests.rs` + 1 `global_gitignore_test.rs`) and matches `POL11_TEST_FLOOR=44`, but reads as a per-file count. Both numbers must move together when a test is added to any module.

Pass 20 concurs.

---

### P21-04 — LOW — New-Test Fixture Prefix (Pending Intent)

**Register row: BI-089.**

**Location:** `crates/mdlinkcheck/tests/scanner_discovery_tests.rs` — the `parents(true)` lock test.

**Claim:** The `parents(true)` lock creates `mdlc_probe.md` / `mdlc_keep.md`, which carry the `mdlc_` prefix but not the module's stated `mdlc_fixture_` hermeticity prefix. The sibling test added in the SAME commit uses `mdlc_fixture_visible.md` and cites the C-E4 convention. Failure mode: a host global pattern matching `mdlc_keep.md` specifically causes a false green; a pattern matching `mdlc_probe.md` causes a flake (loud, not silent). Intent unadjudicated — possibly intentional shorthand for a two-file probe fixture.

---

## Pass 20 Perimeter-Integrity Disclosure

Pass 20 detected the working tree mutating mid-pass (the `9badc02` `--color never` fix landing while it was reading `ci.yml`/`justfile`) and said so plainly rather than silently reporting stale content. That honesty is exemplary. The cause was an orchestrator sequencing error — see L-91 (do not write to perimeter files while adversary passes are running). Pass 20's findings are accordingly anchored to the SHA it was briefed on; findings touching the `--color never` fix were reconciled against the final HEAD.

---

## POL-11 ANSI Regression — Session's Most Instructive Incident

### The Incident

`46cab5a` added the POL-11 positive-coverage assertion to the branch-protection-REQUIRED `Test (macos-latest)` job. **That job then FAILED** — real CI run 31476944208 at `46cab5a`: `POL-11 FAIL: test count 0 is below floor 44`. It had been `success` at `f24ad3e`. The orchestrator introduced a regression into a required merge gate.

### Root Cause

`ci.yml` sets `CARGO_TERM_COLOR: always`. Under this environment, `cargo nextest list` emits ANSI escape sequences between the indentation and the test name:

```
    ^[[34;1mtest_BC_2_01_003_post3_global_gitignore_respected_when_available^[[0m
```

(`cat -v` output). So `grep -cE '[[:space:]]+test_'` matches nothing. Measured by the orchestrator:

| Condition | Count |
|-----------|-------|
| No `CARGO_TERM_COLOR` | 44 |
| `CARGO_TERM_COLOR=always` | 0 |
| `cargo nextest list --color never` | 44 |

`bin_count` was unaffected because `wc -l` counts lines regardless of escape codes.

### Fix and Verification

Fixed at `9badc02` by adding `--color never` to both `cargo nextest list` invocations in `ci.yml` and `justfile`, with comments naming the exact environment variable and warning a future editor not to remove the flag while `CARGO_TERM_COLOR: always` remains. Coupling comments also added at both sites because `POL11_TEST_FLOOR`/`POL11_BIN_FLOOR` are necessarily duplicated between the YAML workflow and the justfile and can drift.

**Verified by orchestrator:**
- Count = 44 under both colour conditions.
- Discrimination re-proved: floor 100 → `POL-11 FAIL: test count 44 is below floor 100`.
- `Test (macos-latest)` observed `success` in real CI at `9badc02`.

### The Irony (record explicitly)

An assertion whose entire purpose is to stop a text-parsing count from silently reporting a wrong number shipped with a text-parsing count that silently reported zero.

Pass 19 independently found this same bug (P19-03), correctly reasoned it fails CLOSED rather than open, and flagged the misleading diagnostic ("A test binary may have silently dropped out of the run") that would send a maintainer hunting a non-existent test-loss regression. Pass 19's finding is HIGH-CONFIDENCE independent corroboration of the root-cause analysis.

### Lesson

This is L-89: verify in the gate's ENVIRONMENT, not just with the gate's TOOL. See the lessons section.

---

## Gate State at `9badc02` (orchestrator-verified this session)

`cargo nextest run --locked --all-targets` under nextest **0.9.98** (CI-pinned per L-83) and nextest **0.9.129** (spec-mandated): `44 tests run: 44 passed, 0 skipped`, exit 0, under both. All 13 AC-named tests pass individually. `cargo clippy --locked --all-targets --all-features -- -D warnings` exit 0. `cargo fmt --all --check` exit 0. `just purity` exit 0. `just ci` exit 0 (reaches `purity` and the CI-pipeline-passed line).

Live check-runs at `9badc02`: `Format check`, `Clippy (deny warnings)`, `Test (macos-latest)`, `Build release (macos-latest)`, `MSRV check (1.88)`, `Purity check (ADR-001)`, `VEF selftest suite` all **success**. `Spec lint` failure — known D-246 advisory, NOT required, exactly 39 SCENARIO-MISMATCH. `Verify evidence figures (advisory)` **skipped** — `pull_request`-only. All four branch-protection-required checks GREEN.

25 commits total on `feature/S-1.01-workspace-scaffold-and-core-discovery` (21 as of D-256 plus 4 this session: `47e11b0`, `366104c`, `46cab5a`, `9badc02`).
