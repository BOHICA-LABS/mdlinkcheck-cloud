---
document_type: adversary-convergence-audit
level: ops
version: "1.0"
status: complete-material-findings
producer: vsdd-factory:state-manager
story_id: S-1.01
cycle: v1.0.0-greenfield
head_sha: b42285a
perimeter_decision: D-254
passes_covered: [25, 26, 27]
pass_27_status: complete-material-findings
remediation_head_sha: b42285a
timestamp: "2026-08-11T00:00:00Z"
---

# Confirming Round Passes 25–27 — Adversary Convergence Audit (Fourth Confirming Round)

## Verdict

**FOURTH CONFIRMING ROUND NOT CLEAN.**

All three passes (25, 26, and 27) returned `MATERIAL_FINDINGS` on the frozen six-lens perimeter (L1–L6). `passes_clean` remains 0 of 3 required.

**BC-5.39.001 NOT SATISFIED — four rounds, twelve passes, zero clean.**

---

## Why This Round Differs in Kind from Rounds 2 and 3

Rounds 2 and 3 justified the D-254 early-ratification posture on the grounds that the residual class was documentation-accuracy — disclosed, not hidden. **Round 4 falsified that premise.**

The L1–L5 production-code streak DID hold: all three passes again independently reported **ZERO new defects in L1 (spec-compliance), L2 (code-correctness), L3 (test-integrity), L4 (hostile filesystem / platform semantics), and L5 (public API contract / downstream consumability)**. That is now nine consecutive passes (passes 19–27) with no new L1–L5 defect.

However, the defect class moved into the enforcement gate itself: `scripts/purity-check.sh`, new at `98a4f15` and never previously adversarially reviewed, contains a fully-exploitable escape from the ADR-001 boundary that seven downstream stories depend on. Finding A1/BI-096 is MUST-FIX-class under D-205. The "residual is documentation-class only" premise that D-254's early-ratification posture rested on is no longer valid.

---

## Target and Scope

- **Target HEAD:** `b42285a`. Note: `adversary-convergence-state.json` previously carried `head_sha: 98a4f15`, the code-remediation SHA; round 4 correctly audited `b42285a`, which is `98a4f15` + two docs-only commits (all 16 paths under `docs/demo-evidence/S-1.01/`).
- **Lens:** `L1-L6-frozen-perimeter-confirming` (as established by D-254).
- **Adversary dispatch constraint:** the `vsdd-factory:adversary` agent type has Read/Grep/Glob only and CANNOT execute. All three passes disclosed this honestly. **Every empirical confirmation below is orchestrator work, performed out-of-tree so the perimeter was never written to (L-91).** The worktree was verified CLEAN at `b42285a` and `== origin` both before and after all probing.

Each pass was given a distinct angle within the frozen perimeter:
- **Pass 25:** purity-script-first line-by-line review, then evidence artifacts.
- **Pass 26:** evidence-vs-reality falsification plus detector-escape construction.
- **Pass 27:** fix-integrity regression and cross-artifact numeral coherence.

---

## Cross-Pass Corroboration

Findings reached by multiple independent passes — treated as highest confidence:

| Pass(es) | Finding IDs | Subject |
|----------|-------------|---------|
| P25-07, P26-01 | BI-096 | `use ::std::fs as f; f::metadata()` defeats purity gate via leading `::` + rename |
| P25-03, P27-05, orchestrator | BI-099 | strip_comments shifts Phase A line numbers — three-way convergence |
| P25-12, P26-05 | BI-109 | `justfile:5` "with no remote" claim while origin exists |
| P25-05, P26-06, P27-04 | BI-110 | PR-PACKAGE pins stale HEAD SHA at five-plus sites — three-pass highest-confidence |
| P25-08, P26-09 | BI-102 | Nonexistent `CORE_SRC` exits 1 with zero diagnostic output |

---

## Class A — Defects in the Shipping Purity Gate (All Orchestrator-Confirmed by Execution)

All findings in this class were verified by the orchestrator through direct execution in an out-of-tree `git archive` clone of `b42285a` with an assert-mutant-landed `cmp` guard (L-90). The `vsdd-factory:adversary` agent type has Read/Grep/Glob only and cannot run commands; all empirical confirmation is orchestrator work, performed out-of-tree. The worktree perimeter was never written to.

---

### A1 / BI-096 — HIGH — Fully Exploitable Past Every Required Gate

**Register row: BI-096. Disposition per D-263: FIX. Add discriminating test asserting mutant lands per L-90.**

**Location:** `scripts/purity-check.sh`; `STMT_RE` and `LINE_RE` pattern set.

**Claim:** `use ::std::fs as f;` followed by `f::metadata()` performs real filesystem I/O inside `mdlinkcheck-core` and passes ALL gates.

**Mechanism:** A leading `::` defeats `STMT_RE`'s `use[[:space:]]+std::` anchor. The ` as f` rename defeats `LINE_RE`'s `\bfs::` arm. Affects `fs`, `net`, and `rand`; `stdout`/`Instant` remain caught by their call-site arms. rustfmt does NOT normalise the leading `::` — verified — so no required gate closes it.

**Orchestrator-confirmed** in an out-of-tree `git archive` clone of `b42285a`:
- Compiles.
- `cargo fmt --all --check` — exit 0.
- `cargo clippy --locked --all-targets --all-features -- -D warnings` — exit 0.
- `cargo nextest run --locked --all-targets` — 44/44 pass.
- `./scripts/purity-check.sh` — exit 0, printing the PASS line.

**Negative control confirmed:** the identical shape WITHOUT the leading `::` is correctly caught (exit 1).

**Aggravating:** the gate's own SCOPE block at `:205-208` affirmatively claims this shape COVERED ("leaf-aliased (as _x)", "intermediate-module-aliased", "in any import shape"). This is a false statement in the durable gate artifact.

**Downstream consequence:** seven stories (S-1.02 through S-7.02) explicitly depend on ADR-001 enforcement by this gate. A silent hole in the gate corrupts the security posture those seven stories are built on.

**Found independently:** P26-01 (primary, pass 26 evidence-vs-reality angle), corroborated by P25-07 (pass 25 line-by-line angle). Two-pass high-confidence.

**Status: OPEN — FIX per D-263 (MUST-FIX per D-205).**

---

### A2 / BI-097 — MEDIUM — Path Method Syscalls Pass Undetected

**Register row: BI-097. Disposition per D-263: FIX.**

**Location:** `scripts/purity-check.sh`; inherent method detection coverage.

**Claim:** The fs-performing inherent methods on `Path`/`PathBuf` — `exists()`, `try_exists()`, `metadata()`, `symlink_metadata()`, `is_dir()`, `is_file()`, `read_dir()`, `canonicalize()` — perform real syscalls and carry zero forbidden tokens.

**Orchestrator-confirmed:** a file containing `use std::path::Path;` + `p.exists()` + `p.metadata()` passes with exit 0. Not listed in the NOT-COVERED block. Aggravating: the script's own negative control `_n4` at `:135` blesses `use std::path::Path` as clean, actively signalling to maintainers that this form is safe.

**Found:** P26 (P26-07).

**Status: OPEN — FIX per D-263.**

---

### A3 / BI-098 — MEDIUM — RNG Detection Is `rand`-Crate-Only

**Register row: BI-098. Disposition per D-263: FIX.**

**Location:** `scripts/purity-check.sh`; RNG detection arms.

**Claim:** RNG detection is `rand`-crate-only (`\buse rand\b`, `rand::`, `extern crate rand`). `getrandom::getrandom(b)` passes with exit 0.

**Orchestrator-confirmed:** `getrandom`/`fastrand`/`oorandom`/`rand_chacha` appear in neither the COVERED nor the NOT-COVERED enumeration, though ADR-001 forbids random-number generators generally, not specifically `rand`.

**Found:** P27 (P27-07).

**Status: OPEN — FIX per D-263.**

---

### A4 / BI-099 — MEDIUM — Line Numbers Index Comment-Stripped Stream, Not Source File

**Register row: BI-099. Disposition per D-263: ACCEPTED-DISCLOSED (no fix).**

**Location:** `scripts/purity-check.sh:36-37`; the Phase A output claim.

**Claim:** `scripts/purity-check.sh:36-37` claims Phase A "yields precise file:line locations." FALSE: `detect_in_file` pipes through `strip_comments` before `grep -n`, so line numbers index the comment-stripped stream, not the source file.

**Orchestrator-confirmed:** a violation on true line 7 of a file with five comment-only lines above it is reported as line 2. Magnitude in this tree: `crates/mdlinkcheck-core/src/types.rs` is 181 lines of which 117 match `^[[:space:]]*//`, so no reported number from `detect_in_file` on that file can exceed 64.

**Three-way convergence:** Found INDEPENDENTLY by the orchestrator before any pass returned, then by P25-03 and P27-05. Three independent observations — highest confidence for the reported-vs-true shift.

**Status: ACCEPTED-DISCLOSED per D-263 — registered, disclosed in PR body, no fix work.**

---

### A5 / BI-100 — MEDIUM — `io::stdout` Arm Rationale Is False on Two Counts

**Register row: BI-100. Disposition per D-263: ACCEPTED-DISCLOSED (no fix).**

**Location:** `scripts/purity-check.sh:63-65`; the `io::stdout` arm rationale comment.

**Orchestrator-confirmed:**
1. The cited example `use std::io as _i; _i::stdout()` matches the `io::stdout` arm 0 times — it is the `\bstdout[[:space:]]*\(` arm that fires.
2. "Same reasoning omits a leading `\b` nowhere else" is contradicted by three further arms (`time::Instant`, `rand::`, `extern crate rand`) that all carry `\b`.

**Risk:** Invites deleting the arm that actually functions by making the comment describe a different arm.

**Found:** P25 (P25-04).

**Status: ACCEPTED-DISCLOSED per D-263 — registered, disclosed in PR body, no fix work.**

---

### A6 / BI-101 — LOW — Newline in Filename Triggers Fail-OPEN

**Register row: BI-101. Disposition per D-263: ACCEPTED-DISCLOSED (no fix).**

**Location:** `scripts/purity-check.sh`; the file-iteration and count reconciliation logic.

**Claim:** A `.rs` filename containing a newline makes `wc -l` count 2 while `read -r` yields two nonexistent paths. `file_count` derives from a second, separate `find` invocation and is never reconciled against the number of files actually passed through `detect_in_file`.

**Orchestrator-confirmed:** a file containing `use std::fs;` in a newline-named path was reported as `2 file(s) ... checked` and PASSED.

**Found:** P26 (P26-08).

**Status: ACCEPTED-DISCLOSED per D-263 — registered, disclosed in PR body, no fix work.**

---

### A7 / BI-102 — LOW — Nonexistent `CORE_SRC` Fails Silently

**Register row: BI-102. Disposition per D-263: ACCEPTED-DISCLOSED (no fix).**

**Location:** `scripts/purity-check.sh`; the `CORE_SRC` path resolution and fail-closed diagnostic path.

**Claim:** A nonexistent `CORE_SRC` exits 1 with ZERO output. Under `set -euo pipefail` the failing `find` aborts the assignment before the fail-closed `FAIL:` message can print, and `2>/dev/null` discards find's own diagnostic. The `FAIL:` message is reachable only for the narrower "directory exists but is empty" case.

**Orchestrator-confirmed:** exit 1, zero `FAIL:` lines. Fails closed (correct direction) but undiagnosable.

**Found:** P25 (P25-08), corroborated by P26 (P26-09).

**Status: ACCEPTED-DISCLOSED per D-263 — registered, disclosed in PR body, no fix work.**

---

## Class B — False Claims in the Human-Facing Evidence Package (All Orchestrator-Confirmed)

---

### B1 / BI-103 — HIGH — Mutation Kill-Count Table Wrong in Both Evidence Files

**Register row: BI-103. Disposition per D-263: FIX.**

**Location:** `docs/demo-evidence/S-1.01/evidence-report.md:61-68` AND `docs/demo-evidence/S-1.01/PR-PACKAGE.md:160-167` (the block destined for the public PR body).

**Two compounding errors:**

(a) Every `FAIL` line in `discrimination-matrix.txt` appears exactly twice — once as a streamed line and once in the nextest end-of-run recap. The table counted lines, not distinct tests, so all counts were doubled.

(b) All four killing runs were CANCELLED by nextest's default fail-fast: `25/44`, `25/44`, `21/44`, `18/44` with `0 skipped`. A `Summary: N/M tests run` with `0 skipped` means fail-fast cancellation. The published figures were never kill counts — they were partial run summaries from cancelled executions.

**See the VERIFIED TRUE MUTATION TABLE section for the authoritative corrected figures.** Note that all three passes (P25, P26, P27) independently "corrected" the evidence-report figures to `3/1/5/1` by reading the cancelled Summary lines as ground truth — that adversary-derived correction is itself WRONG for M3 and M4 (see Refuted section and mutation table).

**Status: OPEN — FIX per D-263. B1/B2 non-negotiable regardless of ratification posture because false claims must never go public.**

---

### B2 / BI-104 — HIGH — Fabricated Type Names in PR Body "What Was Built"

**Register row: BI-104. Disposition per D-263: FIX.**

**Location:** `docs/demo-evidence/S-1.01/PR-PACKAGE.md:63`.

**Claim:** Names `ScanSet` and `ScanPath` as the core crate's headline public types "consumed by all downstream crates."

**Orchestrator-confirmed:** a tree-wide grep across `*.rs` and `*.toml` returns ZERO hits for either identifier; the sole occurrence anywhere is that line. The types that actually exist are `Verdict`, `FailureReason`, `Finding`, `LinkKind`, `ExtractedLink`, `AnchorTable`, `DirIndex`, `DirEntryInfo`, `EntryKind`.

**Found:** P26 (P26-03).

**Status: OPEN — FIX per D-263.**

---

### B3 / BI-105 — MEDIUM — Masking Claim Is One-Directional, Not Mutual (DISPOSITION PENDING OPERATOR)

**Register row: BI-105. Disposition: PENDING OPERATOR — not assigned by D-263.**

**Location:** `evidence-report.md:80-82` and `PR-PACKAGE.md:178-179`.

**Claim:** `filter_entry` and the post-filter backstop are "mutually masking: removing either one alone leaves all 44 tests green."

**Orchestrator-confirmed FALSE for the `filter_entry` half** by re-running the M2 mutant to completion with `--no-fail-fast`: it kills `test_BC_2_01_004_inv1_build_walk_filter_entry_guard_is_active`, which declares itself the SOLE REGRESSION LOCK for that guard. The masking is ONE-DIRECTIONAL: removing the backstop leaves all tests green (BI-095), but removing `filter_entry` does not.

**Material because:** this is the disclosure the operator is being asked to adjudicate D-252a on. The claim as written understates what the tests actually prove about `filter_entry`.

**Found:** P27 (P27-03).

**Status: OPEN — PENDING OPERATOR ADJUDICATION. B3 was assigned NEITHER to the fix list (A1–A3, B1–B2) NOR to the accepted list (C1–C4, A4–A7) by D-263. Do not infer a disposition. Orchestrator has escalated; awaiting adjudication.**

---

### B4 / BI-106 — MEDIUM — AC-006/AC-010 Footnote Substitutes Invented Proof for Tests' Own Honest Disclosure (DISPOSITION PENDING OPERATOR)

**Register row: BI-106. Disposition: PENDING OPERATOR — not assigned by D-263.**

**Location:** `PR-PACKAGE.md:94-98` and `evidence-report.md:29-45, :105`.

**Claim:** The AC-006/AC-010 "honest disclosure" footnote at `PR-PACKAGE.md:94-98` asserts both tests "pass by satisfying a structural reachability invariant (the file path can be resolved from the scan root)."

**Orchestrator-confirmed:** no such assertion exists in either test. Both tests have exactly two assertions — a negative `!result.contains(...)` and a positive vacuity gate. The tests' own in-source comments are accurate and scope themselves to clause (i); the PR body replaced that honesty with an invented proof.

**Compounding:** `evidence-report.md:29-45` carries the same 13-row table with NO footnote or caveat and states at `:105` that all 13 ACs have passing assertion-bearing evidence — which is asserted more broadly than the tests actually prove.

**Found:** P26 (P26-04).

**Status: OPEN — PENDING OPERATOR ADJUDICATION. B4 was assigned NEITHER to the fix list (A1–A3, B1–B2) NOR to the accepted list (C1–C4, A4–A7) by D-263. Do not infer a disposition. Orchestrator has escalated; awaiting adjudication.**

---

## Class C — Stale / Mis-Anchored Config Claims (All Orchestrator-Confirmed; ACCEPTED-DISCLOSED, No Fix)

---

### C1 / BI-107 — MEDIUM — MSRV Deviation Cited to Wrong Decision

**Register row: BI-107. Disposition per D-263: ACCEPTED-DISCLOSED (no fix).**

**Location:** `.github/workflows/ci.yml:226` and `justfile:317`.

**Claim:** The MSRV-1.88 deviation is cited to **D-205**. D-205 is the build-sufficiency / MUST-FIX-vs-ADJUDICATE materiality ruling and contains no MSRV content. The authorising ruling is **D-253**, which the same delivery cites CORRECTLY at `PR-PACKAGE.md:289`. The delivery names two different authorities for one deviation.

**Found:** P27 (P27-01).

**Status: ACCEPTED-DISCLOSED per D-263 — registered, disclosed in PR body, no fix work.**

---

### C2 / BI-108 — MEDIUM — Spec-Lint Failure Count Claims "Three Known Advisory Failures"

**Register row: BI-108. Disposition per D-263: ACCEPTED-DISCLOSED (no fix).**

**Location:** `.github/workflows/ci.yml:461`.

**Claim:** Says spec-lint has "its three known advisory failures on develop." The established fact under D-246 is ONE failing checker (`check-ec-injectivity`, carrying 39 SCENARIO-MISMATCH findings). A triager reading this would silently absorb two genuine checker regressions without investigation.

**Found:** P25 (P25-06).

**Status: ACCEPTED-DISCLOSED per D-263 — registered, disclosed in PR body, no fix work.**

---

### C3 / BI-109 — LOW/MEDIUM — `justfile:5` States Remote Doesn't Exist When It Does

**Register row: BI-109. Disposition per D-263: ACCEPTED-DISCLOSED (no fix).**

**Location:** `justfile:5`.

**Claim:** States "With no remote, `just ci` IS the canonical gate for blocking checks." `origin` exists (`https://github.com/BOHICA-LABS/mdlinkcheck-cloud.git`), branch protection on `develop` is live with four required contexts. The claim is also contradicted six lines later in the same rewritten header block.

**Orchestrator-confirmed:** `origin` exists; branch protection confirmed via `gh api`.

**Found:** P25 (P25-12), corroborated by P26 (P26-05).

**Status: ACCEPTED-DISCLOSED per D-263 — registered, disclosed in PR body, no fix work.**

---

### C4 / BI-110 — LOW — PR-PACKAGE Pins Stale HEAD SHA and Wrong Commit Count

**Register row: BI-110. Disposition per D-263: ACCEPTED-DISCLOSED (no fix).**

**Location:** `PR-PACKAGE.md:14, :51, :104, :255, :348, :356`.

**Claim:** `PR-PACKAGE.md` pins HEAD `f7c5b11` at five-plus sites while the true HEAD is `b42285a`, and `:356` expects a commit count of `28` where the true count against `origin/develop` is **29**. The operator's Step 1 and Step 5 verifications therefore fail on execution — fails LOUD, not silent.

**Found:** P25 (P25-05), P26 (P26-06), P27 (P27-04) — three-pass highest-confidence.

**Status: ACCEPTED-DISCLOSED per D-263 — registered, disclosed in PR body, no fix work.**

---

## Verified True Mutation Table — Orchestrator, `--no-fail-fast`, Complete Runs

This table is the **authoritative record** replacing the figures in `evidence-report.md:61-68` and `PR-PACKAGE.md:160-167` (wrong per B1/BI-103).

Each mutant was applied in an out-of-tree `git archive` clone of `b42285a` with an assert-mutant-landed `cmp` guard (L-90) so a no-op edit could not be counted. The guard fired twice on bad `sed`/`perl` attempts; those runs were correctly discarded rather than reported.

> **CRITICAL NOTE:** All three passes (P25, P26, P27) independently "corrected" the evidence-report figures to `3/1/5/1` by reading the cancelled `Summary` lines as ground truth. **That adversary-derived correction is itself WRONG for M3 (true 7) and M4 (true 2).** Only execution settled it. Any downstream fix must use the TRUE column, not the adversary-derived column. Also note M4's originally-reported `2` is coincidentally CORRECT despite being produced by the doubling error.

| Mutant | Reported in evidence | Cancelled-run summary | **TRUE (complete run)** | Killing tests (true) |
|--------|---------------------|-----------------------|-------------------------|----------------------|
| M1 extension match case-INsensitive | 6 | 3 | **3** | `test_BC_2_01_005_case_sensitive_byte_match`, `test_BC_2_01_005_ec005_ec006a_ec006b_traversal_excludes_non_md_extensions`, `test_BC_2_01_005_non_md_extensions_excluded` |
| M2 dot-dir `filter_entry` guard removed | 2 | 1 | **1** | `test_BC_2_01_004_inv1_build_walk_filter_entry_guard_is_active` |
| M3 `.gitignore` honouring disabled | 10 | 5 | **7** | the five recorded in evidence plus `test_build_walk_filter_entry_replaceable_but_collect_md_files_backstop_holds` and `test_vp016_gitignored_files_never_in_scan_set` |
| M4 `follow_links(true)` | 2 | 1 | **2** | `test_BC_2_01_004_ec009_directory_symlink_to_outside_not_followed` and `test_vp017_scan_terminates_arbitrary_tree` |
| M5 `files.sort()` + `dedup()` removed | 0 | 0 | **0** | survivor — already registered (F-B1/F-B3/C-B1, deferred S-1.02) |
| M6 post-filter backstop removed | 0 | — | 0 (complete run) | survivor — BI-095 |

---

## Refuted: Three-Pass Consensus That Was Wrong

> Record prominently. This is the strongest available evidence for L-81/D-193 and the primary justification for L-97.

All three passes (P25, P26, P27) converged on the following inference — unanimously and independently:
> "The `98a4f15..HEAD` delta is not docs-only; therefore the 'four required checks green' attestation does not carry to HEAD; and `scripts/purity-check.sh` has never been executed by any CI run."

**Orchestrator refutation, by execution — five commands:**

1. `git log --oneline --diff-filter=A -- scripts/purity-check.sh` → **`98a4f15`**. The script was INTRODUCED AT `98a4f15`, not after it.
2. `git diff --name-only 98a4f15 b42285a` → 16 paths, **all** under `docs/demo-evidence/S-1.01/`. The delta IS docs-only.
3. `git log --oneline 98a4f15..HEAD -- .github/workflows/ci.yml justfile lefthook.yml scripts/` → **empty**. No CI-config commit after `98a4f15`.
4. `gh api repos/{owner}/{repo}/commits/98a4f15/check-runs` → `Purity check (ADR-001): success`. The shipping gate HAS run green in CI.
5. `gh api .../commits/b42285a/check-runs` + `gh api .../branches/develop/protection/required_status_checks` → all four branch-protection-required contexts **success** at `b42285a`; required set is exactly `Format check`, `Clippy (deny warnings)`, `Test (macos-latest)`, `Build release (macos-latest)`.

**Consequence for process:** The attestation is TRUE; only its SHA anchor is stale (that residue is C4/BI-110). Three-pass agreement was NOT truth here. Had the orchestrator accepted the consensus, the fix wave would have chased a non-existent CI-coverage gap.

**This is the strongest available evidence for the standing L-81/D-193 rule that every agent report is verified by direct execution.** Unanimous agreement raised confidence about salience; execution determined truth. Cited as the primary evidence basis for L-97.

---

## Orchestrator-Verified GREEN at `b42285a` (Established Fresh, Not Carried Forward)

- **Tests:** 44/44 pass. 44 tests across 6 binaries. `POL11_TEST_FLOOR=44` and `POL11_BIN_FLOOR=6` both exact. All 44 test names begin with `test_` so the POL-11 `[[:space:]]+test_` pattern cannot undercount.
- **Required CI contexts at `b42285a`:** all four green.
  - `Format check` — **success**
  - `Clippy (deny warnings)` — **success**
  - `Test (macos-latest)` — **success**
  - `Build release (macos-latest)` — **success**
- **Additional CI contexts:**
  - `Purity check (ADR-001)` — **success** (run at `98a4f15`; docs-only delta; no CI-config commit after `98a4f15`)
  - `Spec lint` — **failure** — D-246 advisory, expected, NOT required
  - `Verify evidence figures` — **skipped** (`pull_request`-only, BI-069)
- **`#[cfg(unix)]` citations:** `scanner_discovery_tests.rs:472`, `:526`, `:1411` — accurate, exactly three item-level test gates.
- **BI-090 single-implementation claim:** TRUE — both call sites invoke the same file; no inline detector remains in either `ci.yml` or `justfile`.
- **`just purity`:** succeeds from the repo root and from a subdirectory.
- **`shellcheck` 0.11.0:** clean at default severity. `bash -n` clean on `scripts/purity-check.sh`.
- **Detector escape probe (nine shapes):** five caught (re-export chain, leaf alias, intermediate alias, leading-`::` WITHOUT rename, rustfmt multi-line nested); three that escaped and ARE honestly declared NOT-COVERED (`println!`, `SystemTime::now`, `io::stdin`); two undeclared escapes are A1/BI-096 and A2/BI-097.
- **Worktree:** CLEAN at `b42285a`, `== origin` verified before and after all probing.
- **Commit count:** 29 total on `feature/S-1.01-workspace-scaffold-and-core-discovery` against `origin/develop`.

---

## Operator Ruling D-263

Option (a), durability first. Actions:

1. **Write this audit record now, commit and push.** (This document.)
2. **Fix A1–A3 and B1–B2.** B1/B2 are non-negotiable regardless of ratification posture — false claims must never go public. A1/BI-096 is MUST-FIX-class under D-205: a silent hole in the gate ADR-001 depends on corrupts everything the seven downstream stories build on. Fix A1 AND add the discriminating test that proves the hole closed, asserting the mutant lands per L-90.
3. **C1–C4 and A4–A7 ACCEPTED as disclosed-documentation class** under the standing residual-risk posture — register entries, disclosed in PR body, no fix work.
4. **ONE confirming review SCOPED to the changed surface only**, not a full perimeter round — review the fix, not the story.
5. If that scoped review is clean, record convergence as ACHIEVED-WITH-DISCLOSED-RESIDUALS, update the PR body, present the PR package plus the wave-1 DEV-11 package, and STOP. If it is material, stop and escalate again — no fix wave 6 on orchestrator authority.

**No PR creation, no verdict, no merge — HUMAN executes.**

> **OPEN against D-263:** B3 (BI-105) and B4 (BI-106) were NOT assigned a disposition by the ruling — they are neither in the fix list (A1–A3, B1–B2) nor in the accepted list (C1–C4, A4–A7). Orchestrator has escalated this gap and is awaiting adjudication. Do not infer a disposition.

---

## Lessons Added This Session

Four lessons added (see `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/cycles/v1.0.0-greenfield/lessons.md` for full text):

| Number | Tag | Summary |
|--------|-----|---------|
| L-97 | `[process-gap]` | Unanimous multi-agent agreement is not evidence; verify by execution regardless of consensus count |
| L-98 | `[process-gap]` | Never derive a metric from a cancelled run; mutation evidence requires `--no-fail-fast` or it is not a kill count |
| L-99 | `[process-gap]` | A collapsed single implementation inherits none of the review history of what it replaced; treat the new single file as unreviewed surface |
| L-100 | — | A gate's self-check can only prove the shapes it enumerates; scope statements must be derived from the plant list, not written independently of it |

L-97, L-98, and L-99 are process gaps. Per the Cycle-Closing Checklist, each requires either a follow-up story targeting a self-improvement epic or a justified deferral entry. **That disposition has NOT been made — do not invent story IDs.** Route to the operator at the wave-1 gate.
