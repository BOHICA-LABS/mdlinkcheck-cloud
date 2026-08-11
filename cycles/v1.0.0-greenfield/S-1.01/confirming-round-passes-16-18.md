---
document_type: adversary-convergence-audit
level: ops
version: "1.0"
status: in-progress
producer: vsdd-factory:state-manager
story_id: S-1.01
cycle: v1.0.0-greenfield
head_sha: f24ad3e
perimeter_decision: D-254
passes_covered: [16, 17, 18]
pass_18_status: complete-material-findings
timestamp: "2026-08-11T00:00:00Z"
---

# Confirming Round Passes 16–18 — Adversary Convergence Audit

## Verdict

**CONFIRMING ROUND DEFINITIVELY NOT CLEAN.**

All three passes (16, 17, and 18) returned `MATERIAL_FINDINGS` on the frozen perimeter (L1–L6). Per D-254, findings MATERIAL on the frozen perimeter are blockers — fix and re-run is not perimeter expansion, it is the process working correctly. `passes_clean` remains 0 of 3 required. Fix-and-re-run is required before the confirming round can conclude.

Pass 18 was re-dispatched after an upstream API error terminated its first attempt mid-generation. The re-dispatched pass completed and returned `MATERIAL_FINDINGS`: 5 on-perimeter material findings (including a FIFTH PRODUCTION DEFECT, P18-03) and 4 LOW/NITPICK. Zero new-lens findings.

## Cross-Pass Corroboration

Three findings were found **independently** by both passes — treated as high-confidence per the established two-independent-lens rule:

| P16 ID | P17 ID | Lenses | Subject |
|--------|--------|--------|---------|
| P16-01 | P17-03 | L2/L5/L6 | `collect_md_files` doc block contradicts itself on dot-FILE exclusion; "subject to override by negation patterns" is empirically false |
| P16-05 | P17-04 | L6/L5 | Purity-gate grep patterns blind to grouped imports; guarded crate already uses grouped form at `types.rs:36` |
| P16-06 | P17-05 | L6 | `just ci` structurally unreachable via `purity`; `spec-lint` (D-246 known-red) blocks as hard prerequisite |

## Confirmed On-Perimeter Findings

All findings below were verified by the orchestrator through direct execution or direct file read per D-193 / L-81. The `vsdd-factory:adversary` agent type has Read/Grep/Glob only and cannot run commands; all empirical confirmation is orchestrator work.

---

### P16-01 / P17-03 — HIGH — L2/L5/L6

**Location:** `crates/mdlinkcheck/src/scanner.rs:133–135` vs `:137–142`; mechanism at `:166–169`

**Claim:** The `collect_md_files` doc block contradicts itself on dot-FILES. The P14-02 post-filter is NAME-based: `rel.components().any(|c| is_dot_dir_name(c.as_os_str()))` runs after `file_type.is_file()`, so the final component IS the file name and dot-FILES are rejected structurally. Yet the bullet five lines above says dot-file skip is "best-effort via `hidden(true)`, NOT unconditional … subject to override by ignore-rule negation patterns". Additionally, a POLICY 4 semantic mis-anchor: the post-filter cites BC-2.01.004 invariant 1 at `:139` and `:165`, but that invariant governs dot-DIRECTORIES only; no BC authorizes excluding dot-FILES. Consequence: the operator's OPEN D-252a adjudication was made on false information (the described best-effort behavior is in fact structural), and S-1.02 is told a negation-pattern override path exists that does not.

**Orchestrator verification: CONFIRMED EMPIRICAL.** Probe built tempdir with `.gitignore` containing `.*` then `!.*`, plus `docs/.template.md`, `.toplevel.md`, and `mdlc_fixture_README.md`, then called `collect_md_files`. Result: `["mdlc_fixture_README.md"]` — both dot-files excluded despite the negation pattern, proving the doc's "subject to override" claim FALSE. Probe removed; tree left clean.

**Corroboration:** P17-03 found the same contradiction independently on a separate confirming-round pass.

---

### P17-01 — HIGH — L3/L6

**Location:** `crates/mdlinkcheck/src/scanner.rs:95–103`

**Claim:** The `filter_entry` dot-directory guard has ZERO discriminating test coverage. The P14-02 post-filter masks it from every test: all dot-dir tests route through `collect_md_files`, and the only test calling `build_walk` directly (`test_build_walk_filter_entry_replaceable_but_collect_md_files_backstop_holds`) replaces the predicate with `|_| true` on the next line. This is a fix-integrity regression — the P14-02 fix destroyed the kill-coverage that closed F-01 in pass 1. `filter_entry` is the ONLY BC-2.01.004-invariant-1 defence for direct `build_walk` consumers, and `scanner.rs:47–55` names that consumer explicitly: S-1.02's `--ignore <glob>` per BC-2.11.001. A refactor removing the guard ships green and re-arms the F-A1 defect with no regression lock.

**Orchestrator verification: CONFIRMED EMPIRICAL.** The entire `builder.filter_entry(...)` statement was removed and the gate-exact suite re-run: `42 tests run: 42 passed, 0 skipped`. Zero tests detected removal of the guard. `scanner.rs` restored from backup; tree left clean.

---

### P16-05 / P17-04 — MEDIUM — L6/L5

**Location:** `.github/workflows/ci.yml:329–349` and `justfile:242–262`

**Claim:** The new `Purity check (ADR-001)` detector greps six literal patterns that all require a non-grouped `use std::…` form, so it is blind to grouped imports (`use std::{fs, path::PathBuf};`) and to fully-qualified calls with no `use` at all (`std::fs::read_to_string`). The guarded crate already writes grouped imports — `crates/mdlinkcheck-core/src/types.rs:36` is `use std::collections::{HashMap, HashSet};`. The job nevertheless prints the unqualified absolute claim `PASS: mdlinkcheck-core is free of forbidden I/O and RNG imports (ADR-001)`. It also has no known-positive self-test, so a quoting regression in the pattern list would be undetectable, and `file_count` is never asserted non-zero (POLICY 11). Material because `ci.yml:305–308` designates this the sole source-level ADR-001 erosion gate for 7 downstream stories.

**Orchestrator verification: CONFIRMED EMPIRICAL.** Planting `use std::{fs, path::PathBuf};` plus a real `fs::metadata` call into `crates/mdlinkcheck-core/src/` produced `purity: 3 file(s) … 0 forbidden-pattern(s) found`, the absolute PASS line, and exit 0. The control (non-grouped `use std::fs;`) correctly produced exit 1 with `FAIL: ADR-001 purity boundary violated`. So the gate discriminates on ONE form only.

**Note for the record:** The prior session's verification of this job ("orchestrator-verified to DISCRIMINATE: planting `use std::fs;` → exit 1") tested only the non-grouped form and generalized from it — an L-83/L-84-class verification gap now closed.

**Corroboration:** P17-04 found the same blindness independently.

---

### P16-06 / P17-05 — MEDIUM — L6

**Location:** `justfile:76` (`ci: fmt-check lint test build-release spec-lint purity`), `spec-lint` recipe at `:273–302`

**Claim:** `just` runs prerequisites left-to-right and aborts on the first failure. `spec-lint` exits 1 whenever any checker fails, and `check-ec-injectivity.py` is RED BY DESIGN at exactly 39 SCENARIO-MISMATCH per D-246 — while `ci.yml` deliberately treats `Spec lint` as an independent ADVISORY, non-required job. So the justfile wires a known-red advisory checker as a HARD BLOCKING prerequisite positioned immediately before `purity`, making fix #5's local wiring dead. The justfile header calls `just ci` "the canonical CI gate".

**Orchestrator verification: CONFIRMED EMPIRICAL.** `just spec-lint` → exit 1. `just ci` → exit 1, with `purity:` appearing 0 times and `CI pipeline passed.` appearing 0 times in the output: the purity gate never executes locally.

**Corroboration:** P17-05 found the same block independently.

---

### P17-02 — MEDIUM — L6

**Location:** `justfile:157–162`

**Claim:** `just hardening` reports `kani` as EXECUTED when zero Kani harnesses exist. Line 157 is `harness_files=$(grep -rl '#\[kani::proof\]' . --include='*.rs' 2>/dev/null | wc -l | tr -d ' ' || echo "0")`. Under `set -euo pipefail` with zero matches, `grep` exits 1, `pipefail` propagates, so `|| echo "0"` fires IN ADDITION to `wc`'s already-emitted `0`, capturing `"0\n0"`. `[ "0\n0" -eq 0 ]` is not an integer comparison, `[` errors and returns 2, `set -e` does not apply to `if` conditions, so the ELSE branch runs and `kani` lands in `executed`. This is the exact false-green class fix #3 was created to remove; the sibling `kani` recipe at `:131` gets it right with `|| true` on the grep itself, so this is a within-file divergence.

**Orchestrator verification: CONFIRMED EMPIRICAL.** Running the verbatim line under `bash -euo pipefail` produced `RAW=[0` / `0]` (two lines), `bash: [: 0\n0: integer expected` on stderr, and `BRANCH=executed`. Fix: mirror line 131's `|| true` placement.

---

### P16-02 — MEDIUM — L6/L3

**Location:** `crates/mdlinkcheck/tests/scanner_discovery_tests.rs:1438` and the assertion message at `:1443–1446`

**Claim:** P14-01 is recorded as fixed, but two stale defect-tense sites survive inside the F-P2-01 regression lock: `// BC-2.01.004 postcondition 1 / invariant 1 — FAILS on current impl.` and an assertion message prescribing in the imperative a fix that already landed at `7bea0b2`. The same file says at `:1374` "This test is the GREEN regression lock that must stay green" — flatly contradictory 64 lines apart.

**Orchestrator verification: CONFIRMED by grep** — exactly one hit for `FAILS on current impl` at line 1438.

---

### P16-03 — MEDIUM — L3/L6

**Location:** `crates/mdlinkcheck/tests/scanner_discovery_tests.rs:13–15` plus ~18 inline sites

**Claim:** The module doc still asserts RED GATE state: "all 13 AC tests and both VP tests MUST fail at this step … Each failure is a panic at `todo!()` … No test may pass before the implementer runs." Eighteen further comments state present-tense that the called function "panics at `todo!()`". The file's leading operative statement is inverted relative to reality. The sibling `types_tests.rs:17–19` handles this correctly, proving the convention exists and was applied to one file and not the other.

**Orchestrator verification: CONFIRMED by grep** — the only `todo!` in `crates/*/src/` is `mdlinkcheck/src/main.rs:11`; `scanner.rs` contains none.

---

### P16-04 — MEDIUM — L3/L6

**Location:** `crates/mdlinkcheck/tests/scanner_discovery_tests.rs:19–20, 226, 246, 1236, 1253–1254`

**Claim:** Five sites assert the pre-F-B2 world in which the `ignore` crate's `require_git=true` default applies. Most serious is `:1236`, a FALSE COVERAGE CLAIM: it states the companion test exercises "the `require_git=true` path", but that path is unreachable through `build_walk`, so the stated justification for that test's existence is void. `:246` and `:1253` tell a maintainer `git_init` is "required" when it is not (register entry C-C3). The file contradicts itself: its own `git_init` doc at `:70–75` states in bold that `git init` is NOT required because `build_walk` calls `require_git(false)`.

**Orchestrator verification: CONFIRMED by grep** — `scanner.rs:79` is `.require_git(false)`. Note lines `:1096` and `:1116` are correctly-phrased defect-history references inside the F-B2 lock and are NOT part of this finding.

---

### P16-07 — MEDIUM — L6

**Location:** `justfile:344–354` vs `.github/workflows/hardening.yml:229` and `:275`

**Claim:** Supply-chain pin not propagated to the sibling. `hardening.yml` pins `cargo-fuzz --version 0.13.2` with the explicit rationale "SEC-2 fix: pinned to exact version to prevent supply-chain substitution", and `kani-verifier --version 0.67.0` for SEC-1. `justfile:349` installs `cargo +nightly install cargo-fuzz --locked` with NO `--version`, and `kani-verifier` is absent from the justfile entirely — while `just hardening` depends on the `kani` recipe. The recipe prints `All Cargo tools installed.`, which is false. All four other tools are pinned identically in both places.

**Orchestrator verification: CONFIRMED by direct comparison** — justfile cargo-fuzz line has `--locked` but no `--version`; `kani-verifier` appears 0 times in `justfile` and is pinned in `hardening.yml`.

---

### P16-08 / P17-08 — LOW (intentional) — L6

**Location:** `.github/workflows/ci.yml:191–212`; `hardening.yml:54–69, 87–102, 152–187`

**Claim:** Fix #4 inverted four guards fail-open→fail-closed but four sibling jobs retain the `skip=true` shape in which a missing `Cargo.toml` yields SUCCESS having run nothing.

**Orchestrator verification: RESOLVED AS INTENTIONAL-LOW.** `gh api repos/{owner}/{repo}/branches/develop/protection` returns required contexts exactly `["Format check","Clippy (deny warnings)","Test (macos-latest)","Build release (macos-latest)"]` — `MSRV check (1.88)` is NOT branch-protection-required, satisfying the adversaries' own stated criterion for the intentional-LOW reading. Fix #4's scoping to the four required jobs was deliberate. Recorded, not escalated.

---

### P16-09 — LOW — L6

**Location:** `justfile:3` and `:9`

**Claim:** Line 9 documents `just ci` as `(fmt-check + lint + test + build-release)` — 4 entries — while line 76 has 6 (`spec-lint`, `purity` undocumented). Line 3 claims "Mirrors CI exactly", but `just ci` omits `msrv-check`, `vef-selftest`, and `verify-evidence-figures`, all of which are `ci.yml` jobs. Third instance this round of an aggregate's summary text drifting from its dependency list.

**Orchestrator verification: CONFIRMED by read.**

---

### P17-06 — LOW — L3

**Location:** `scanner_discovery_tests.rs:441–447`

**Claim:** AC-008's dot-component invariant sweep uses `c.as_os_str().to_str().map(|s| s.starts_with('.')).unwrap_or(false)` — exactly the UTF-8-only form F-P2-01 identified as fail-open — while its siblings at `:1541` and `:1567` are byte-wise `as_encoded_bytes().starts_with(b".")`. No discrimination lost today (ASCII fixture); latent for any future non-UTF-8 fixture. Intent adjudication needed.

---

### P17-07 — LOW — L3

**Location:** `scanner_discovery_tests.rs:869–965`

**Claim:** VP-017 is the only test in the suite with no positive-discovery gate: all four `prop_assert!`s are negative or universally quantified over `result`, so an implementation returning `Vec::new()` satisfies VP-017 for all 256 cases. Every other test in the file carries an explicit F-04 vacuous-pass-prevention positive assertion. `prop_assert_eq!(result.len(), file_count)` would close it.

---

### P17-09 — LOW — L2

**Location:** `scanner.rs:166`

**Claim:** `strip_prefix(root).unwrap_or(path.as_path())` converts a prefix mismatch into a silent, total, undiagnosed empty scan set: the absolute fallback path on macOS tempdirs (`/var/folders/…/.tmpXXXX/…`) contains a dot-prefixed component, so line 167 would reject every file and `collect_md_files` would return `vec![]` with no error and no log. Believed unreachable in practice (children are `parent.join(name)` from the supplied root) but unproven. Recommend `debug_assert`/fail-loud rather than silent fallback.

---

## New-Lens Finding (routes to S-1.02 input, not S-1.01 blocker per D-254)

### P17-N1 — L3 (new-lens)

No `docs/demo-evidence/S-1.01/` directory exists. POLICY 10 is not violated (no flat files), and this is simply Step 5 not yet reached. Recorded, not escalated. Per D-254 `new_lens_routing`, findings from any lens NOT in L1–L6 route to S-1.02 input or register entries and are NOT S-1.01 blockers.

---

## Refuted / Exonerating Results

- **`just spec-lint` reporting `9/9 checks failed` IS AN ENVIRONMENT ARTIFACT** — from a story worktree, `.factory/` is gitignored and empty, so `spec_lint_primitives.find_repo_root` raises `RuntimeError: repository boundary (.git) encountered before .factory/specs/ was found` and every checker crashes. With `SPEC_LINT_REPO_OVERRIDE=/Users/jmagady/Dev/mdlinkcheck-cloud`, 8 of 9 checkers exit 0 and only `check-ec-injectivity` exits 1, at exactly 39 SCENARIO-MISMATCH — confirming D-246 and EXONERATING the D-256 spec-lint claim. Live instance of L-84 (verification can fail in the exonerating direction). This has been recorded as BI-070.

- **Pass 17 independently refuted** one of its own candidate findings: verified that `ignore` 0.4.33 does honour `GIT_CONFIG_GLOBAL` and that `parse_excludes_file`'s regex accepts the tab-indented `[core]` form the test writes, so the global-gitignore test is sound rather than vacuous. Candidate dropped.

- **Pass 17 audited** `lefthook.yml`'s "mirror the CI jobs exactly" claim command-by-command and found it ACCURATE; deliberately not reported.

- **Pass 16 verified** all six remaining "Defined verbatim from `api-surface.md`" claims in `types.rs` (`:45, 77, 114, 152, 159, 173`) against `api-surface.md:80–92, 121–126` and found all six truthful — fix #8's siblings are clean.

- **Both passes (16 and 17) independently confirmed** P15-02 stayed fixed: all job names across both workflows are unique with no cross-workflow collisions.

- **Pass 18** swept an extensive L4 edge-case list and found all cases either correctly handled or genuinely unconstrained (non-UTF-8 directory component; non-UTF-8 filename with `.md`; trailing-dot directories; `.`/`..` components; scan root inside a dot-directory; zero-byte `.md` files; non-regular files; `foo.md.` and `foo.md ` correctly excluded; multi-suffix `foo.tar.md` correctly included; root-nonexistent/root-is-a-file/root-is-a-dir-symlink/permission-denied-mid-walk/`ENAMETOOLONG`). It also confirmed the AC-009 EC-008-vs-EC-009 discrimination argument is CORRECT, independently re-confirmed all `api-surface.md` fidelity claims in `types.rs` are accurate, and independently confirmed P15-02 stays fixed.

---

## Pass 18 — On-Perimeter Findings

Pass 18 was re-dispatched after an upstream API error terminated the initial response mid-generation. The re-dispatched pass returned `MATERIAL_FINDINGS` (lens `L1-L6-frozen-perimeter-confirming`): 5 on-perimeter material findings (2 HIGH routine + 1 HIGH production defect + 2 MEDIUM), 4 LOW/NITPICK, 0 new-lens findings.

All findings below were verified by the orchestrator through direct execution or direct file read per D-193 / L-81.

---

### P18-01 — HIGH — L6/L1

**Location:** `.github/workflows/ci.yml:135–136`, `justfile:55–56`, `lefthook.yml:44–46`

**Claim:** The frozen architecture spec `tooling-selection.md:155–160` MANDATES a CI positive-coverage assertion after `cargo nextest run`, with the stated rationale "This prevents a situation where a test target at the wrong path silently compiles to nothing and reports `0 passed` as green." All three nextest invocation sites run bare `cargo nextest run --locked --all-targets` with ZERO count assertion. This is both a frozen-spec mandate and registered project POLICY 11 (`ci_positive_coverage_assertion`). Material because this is the only gate-level defence against the exact false-green class that already bit this story twice — C-E2 (a `harness = false` binary nextest marked `ignored: true` and excluded) and P14-03 (a fail-open argv parser that exited 0 without running the test body). Both fixes hardened the binary; neither added the gate assertion.

**Orchestrator verification: CONFIRMED.** `grep -rnE 'nextest list|expected_harness' .github/workflows justfile lefthook.yml` returns NOTHING. Additionally, the spec's literal prescribed command `cargo nextest list --locked --all-targets | grep -c '^tests::'` returns **0** on this project — actual nextest list format is `crate::binary test_name` with no `tests::` prefix, so a naive verbatim implementation would always assert `0 -ge <expected>` and fail. Fix must implement the spec's INTENT with a pattern matching real nextest output, and DISCLOSE that the spec's literal snippet does not match this project's layout (closed-world corpus defect per D-244 — do not edit the spec).

---

### P18-02 — HIGH — L6

**Location:** `ci.yml:130`; `hardening.yml:121, 167, 171, 229`; `justfile:13–19, 345–349`

**Claim:** Version-pin contradictions vs frozen `tooling-selection.md:36–45` for 5 of 6 tools; divergence runs in BOTH directions ruling out a single "we upgraded" narrative. Spec vs implemented: Kani 0.67.0 vs 0.67.0 (MATCH); cargo-fuzz **0.13.1** spec vs **0.13.2** ci (ci newer); cargo-mutants **27.0.0** spec vs **24.11.2** impl (spec NEWER than impl); cargo-nextest **0.9.129** spec vs **0.9.98** impl (spec NEWER); semgrep **1.56.0** spec vs **1.75.0** impl (impl newer); hyperfine **2.0.0** spec vs unpinned `brew install` (impl unpinned). NONE of the five has a deviation record (unlike MSRV D-205/D-253 and proptest D-257). `hardening.yml:227–228` records only "Version verified against crates.io on 2026-08-06 (latest stable = 0.13.2)" — latest-stable silently preferred over frozen spec value. Two concrete consequences: (1) nextest is the runner for this story's entire suite and the `harness = false` binary's `--list`/argv contract was hand-written against observed behaviour of one version; (2) cargo-mutants kill-rate targets in `module-criticality.md` are calibrated against 27.0.0, so this story's survivor register (F-08, F-B1, F-B3) was produced by an older engine with different mutant-generation coverage, making those verdicts non-comparable to the calibrated baseline.

**Orchestrator verification: CONFIRMED by direct read of the frozen spec table.** PARTIAL EXONERATION: the suite was run under BOTH nextest **0.9.129** and nextest **0.9.98**, and both give `42 tests run: 42 passed, 0 skipped`, exit 0 — the feared silent-test-loss is NOT realized at this HEAD. The version divergence and the missing deviation record remain real.

**ROUTED TO OPERATOR DECISION** — same shape as MSRV (D-253) and proptest (D-257): frozen-spec value vs implemented value, requiring adjudication and a deviation record rather than a silent code change.

---

### P18-03 — HIGH — L2 — FIFTH PRODUCTION DEFECT

**Location:** `crates/mdlinkcheck/src/scanner.rs:64–79`

**Claim:** `build_walk` explicitly sets and documents seven `WalkBuilder` setters but leaves `parents` at the `ignore` 0.4.33 default of `true`. With `parents(true)` the walker ascends from the scan root collecting `.gitignore` / `.ignore` / `.git/info/exclude` matchers from ancestor directories, and because `require_git(false)` is also in force (`scanner.rs:79`) there is NO repository-root boundary at which that ascent stops. So an ignore file in ANY ancestor of the scan root governs the scan tree — which is not git's semantics (git stops at the repo root). Production consequence: a user whose `$HOME` contains a `.gitignore` (common — often the same file used as `core.excludesFile`) with a pattern like `notes/` or `*.md` silently loses those files from every scan under `$HOME`, and `collect_md_files` has no error or diagnostic channel to report it (F-A3).

**Orchestrator verification: CONFIRMED EMPIRICALLY.** A probe created `outer/.gitignore` containing `mdlc_probe.md`, plus `outer/inner/mdlc_probe.md` and `outer/inner/mdlc_keep.md`, with NO git repository anywhere, then called `collect_md_files(outer/inner)`. Result: `["mdlc_keep.md"]` — `mdlc_probe.md` was excluded by an ignore file ABOVE the scan root and outside any git repo. Probe removed; tree left clean. Also verified: `grep -n parents` returns NOTHING in `scanner.rs` or any test file — the setter is absent from source, undocumented in the otherwise exhaustively-documented `build_walk` doc block (which even has a dedicated "# Gitignore vs .ignore" section asserting which ignore files are honoured), and **structurally invisible to mutation testing**: because the setter is never written, `cargo mutants` cannot generate a mutant for it, unlike `git_global(true)` which got a purpose-built discriminating test precisely because its mutant would otherwise survive.

**ROUTED TO OPERATOR DECISION:** BC-2.01.003 postcondition 1 constrains exclusion to "any **applicable**" ignore file and no BC defines "applicable", so whether an ancestor-outside-repo ignore file qualifies is unadjudicated under closed-world (D-244). The orchestrator did NOT unilaterally change traversal semantics on a frozen spec. Recommendation offered to the operator: `parents(false)` matches git's repo-root-bounded semantics while `git_global(true)` continues to honour the user's global excludesFile — but this is the operator's call, and either way the behaviour must be documented and given a discriminating test. Tracking: **BI-071**.

---

### P18-04 — MEDIUM — L6

**Location:** `lefthook.yml:7`

**Claim:** Line 7 states the hooks "mirror the CI jobs exactly — the same commands, the same flags." They cover 3 of the 9 `ci.yml` jobs: `fmt`, `clippy` (pre-commit) and `nextest` (pre-push). Absent: `build-release`, `msrv` (1.88), `spec-lint`, `purity` (ADR-001), `vef-selftest`, `verify-evidence-figures`. The `purity` job is the only enforcement of the ADR-001 boundary the story declares MANDATORY, and it is in neither hook. This is a partial-fix regression: the nine-fix set at `f24ad3e` corrected the `justfile` header's identical false "Mirrors CI exactly" claim but left the sibling local-gate config file un-corrected — and fix #5 made the claim MORE false by adding `purity` to CI without touching the `lefthook.yml` assertion.

**Orchestrator verification: CONFIRMED by read.** Note: pass 17 separately audited `lefthook.yml` and found the three commands it does run match their CI counterparts flag-for-flag (accurate). The two readings are compatible: commands match flag-for-flag, but "mirror the CI **jobs** exactly" is false because 6 of 9 jobs are absent.

---

### P18-05 — MEDIUM — L3

**Location:** `crates/mdlinkcheck/tests/scanner_discovery_tests.rs:106–117`

**Claim:** AC-001's comment and assertion message claim a duplicate-yield detector that is structurally impossible. The comment says to "assert Vec length BEFORE set conversion so that a walker yielding a path multiple times is caught here", and the assertion message says "a len > 3 means the walker yielded a path more than once". But `scanner.rs:179–180` executes `files.sort(); files.dedup();` before returning, so `result.len()` can never exceed 3 as a consequence of a duplicate walker yield; the "before set conversion" positioning buys nothing and the assertion's real content ("exactly 3 distinct `.md` files") is already covered by the subsequent `result_set.len() == 3`. Material because this comment is the sole in-repo statement of HOW BC-2.01.001 postcondition 1's "exactly once" and postcondition 2's "not scanned more than once" clauses are discharged, and it names a mechanism that does not exist — so a reader concludes duplicate-yield detection is covered and stops looking, which is exactly the false belief that would let a real aliasing regression (the still-UNADJUDICATED P10-01 hardlink class) land unnoticed. It also misdirects the fix: acting on the message would mean reordering assertions rather than adding the aliasing fixture actually needed. Same class as C-E5 and C-E3, both fixed at `7a681ea`; this instance survived that sweep. Also note `:104` carries another stale `Red Gate: collect_md_files panics at todo!()` comment (P16-03 set).

**Orchestrator verification: CONFIRMED by direct read.**

---

### P18-06 through P18-09 — LOW / NITPICK

- **P18-06 (LOW — L6):** `justfile:187` — `just bench` runs `cargo build --release 2>/dev/null`, swallowing all compiler stderr so a failed build aborts with no diagnostic under `set -euo pipefail`; also missing `--locked` unlike `build-release`.

- **P18-07 (LOW — L2):** `scanner.rs:116–117` calls `ignore`'s hidden check "equivalent" to `is_dot_dir_name`, but `scanner_discovery_tests.rs:344–349` documents that `ignore` 0.4.33's `pathutil` returns "not hidden" for names ending in `.` or `..`, so the two DISAGREE on `.trailing.` — which is precisely why that input class is defended by `filter_entry`/`is_dot_dir_name` ALONE; a reader of the production doc could conclude the guard is redundant and remove the sole defence.

- **P18-08 (LOW — L6):** `ci.yml:220–221` says spec-lint "Failures are violations that MUST be fixed before the Phase 1 gate passes", contradicting D-246's red-by-design ADVISORY ruling AND contradicting `ci.yml:424–425` in the same file.

- **P18-09 (NITPICK — L5):** `pub fn is_dot_dir_name`'s name and doc promise a dot-DIRECTORY predicate but it performs no directory test and is invoked at `scanner.rs:167` on every component including the file name; it is `pub` and `scanner.rs:51` instructs S-1.02 to build `--ignore` on it, so the misleading contract is inherited downstream.

---

### Pass-18 Observations Recorded as Disclosure Only (corpus defects per D-244 or out of scope)

VP-016 has three mutually inconsistent property statements across the frozen corpus — the authoritative VP file `verification-properties/vp-016-ignored-files-anchor-targets.md` declares `source_bc: BC-2.08.004`, title "Ignored Files Have Anchor Tables" with five `vp016_*` fixtures requiring `run_scan`/`Finding`/Pass 1.5 (none of which exist in S-1.01), while `BC-2.01.003.md:73` states it as "Files matching .gitignore patterns are never in the scan set" and `BC-2.01.004.md:80` states it as "Dot-dir .md files remain valid anchor targets"; extends carried nitpick N-D3. VP-017's spec names a 5-second elapsed-time bound as the falsifier for "cycle detection disabled" but the implemented test has no timing assertion. Config files named by `tooling-selection.md:38–43` are ALL absent: `.config/nextest.toml`, `kani.toml`, `.cargo-mutants.toml`, `.semgrep/`. `justfile:180` names a recipe parameter `PATH` (latent footgun if `set export` ever enabled). `ci.yml:9–11`'s platform enumeration is stale.

---

## Gate State at `f24ad3e` (orchestrator-verified this session)

`cargo nextest run --locked --all-targets` under nextest **0.9.98** (the version CI pins, deliberately installed to match the gate rather than locally-present 0.9.129 per L-83): `42 tests run: 42 passed, 0 skipped`, exit 0. All 13 AC-named tests pass individually. `cargo clippy --locked --all-targets --all-features -- -D warnings` exit 0. `cargo fmt --all --check` exit 0. `just purity` exit 0.

Live check-runs at `f24ad3e`: `Format check`, `Clippy (deny warnings)`, `Test (macos-latest)`, `Build release (macos-latest)`, `MSRV check (1.88)`, `Purity check (ADR-001)`, `VEF selftest suite` all SUCCESS; `Spec lint` failure (known D-246 advisory, not required); `Verify evidence figures (advisory)` SKIPPED (`pull_request`-only).

21 commits ahead of `develop`; 17 files changed, +3966/−82.
