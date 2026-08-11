---
document_type: adversary-convergence-audit
level: ops
version: "1.0"
status: complete-material-findings
producer: vsdd-factory:state-manager
story_id: S-1.01
cycle: v1.0.0-greenfield
head_sha: 2616257
perimeter_decision: D-254
passes_covered: [22, 23, 24]
pass_24_status: complete-material-findings
remediation_head_sha: 98a4f15
timestamp: "2026-08-11T00:00:00Z"
---

# Confirming Round Passes 22–24 — Adversary Convergence Audit (Third Confirming Round)

## Verdict

**THIRD CONFIRMING ROUND NOT CLEAN.**

All three passes (22, 23, and 24) returned `MATERIAL_FINDINGS` on the frozen six-lens perimeter (L1–L6). `passes_clean` remains 0 of 3 required.

**CRITICAL QUALITATIVE SHIFT — now six consecutive passes with no new L1–L5 defect.** All three passes again independently reported **ZERO new defects in L1 (spec-compliance), L2 (code-correctness), L3 (test-integrity), L4 (hostile filesystem / platform semantics), and L5 (public API contract / downstream consumability)**. Every round-3 finding is L6 / documentation-class, and every material one is a residual of the immediately preceding fix wave (`2616257`) — the same pattern round 2 recorded.

That is now the fourth, fifth, and sixth consecutive passes with no new L1–L5 defect.

All five material findings (BI-091 through BI-094, plus the structural BI-090 remediation) were **FIXED at `98a4f15`**. The D-261 LOW/NITPICK set (BI-084..BI-089) from prior rounds carries forward unmodified. BI-095 (orchestrator mutation testing, not adversary-found) is newly registered as LOW and routes to operator adjudication alongside D-252a.

Commits fixed this session on branch `feature/S-1.01-workspace-scaffold-and-core-discovery`:
- `2616257` — "fix(gates): three round-2 material residuals BI-081/BI-082/BI-083" (the fix wave these passes audited)
- `98a4f15` — "fix(purity): extract detector to one script; close multi-line + nested blindness" (round-3 remediation HEAD)

---

## Cross-Pass Corroboration

Two findings were found **independently by all three passes** — treated as highest confidence:

| P22 ID | P23 ID | P24 ID | Subject |
|--------|--------|--------|---------|
| P22-01 | P23-01 | P24-01 | Purity regex: multi-line grouped-import blindness + INVERTED fs/net asymmetry (BI-091) |
| —      | P23-02 | P24-03 | Gate text misquotes frozen ADR-001 ("enumerates path-fragments, not macros") (BI-093) |

---

## Material Findings — All Fixed at `98a4f15`

All findings below were verified by the orchestrator through direct execution or direct file read per D-193 / L-81. The `vsdd-factory:adversary` agent type has Read/Grep/Glob only and cannot run commands; all empirical confirmation is orchestrator work.

---

### BI-090 — Structural Remediation: Purity Detector Extracted to Single File

**Not adversary-found; orchestrator-initiated as part of this fix wave.**

**Register row: BI-090.**

**Context:** The purity detector logic had lived as two hand-maintained copies: inline in `ci.yml`'s `purity` job and in the `justfile`'s `purity` recipe. Keeping them byte-identical was a standing obligation that produced defects in THREE consecutive review rounds (BI-081 in round 2; then BI-091 and BI-092 in round 3). Both call sites now invoke a single new file, `scripts/purity-check.sh`, so the duplication class is closed by construction rather than by discipline.

**Verified:** the extracted script ran in real CI at `98a4f15` and printed "purity self-check: PASS (21 evasion shapes each detected; 6 clean samples each not matched)".

**Status: CLOSED at `98a4f15`.**

---

### P22-01 / P23-01 / P24-01 — MEDIUM — L6 — Purity Regex: Multi-Line Grouped-Import Blindness + INVERTED Asymmetry

**Register row: BI-091.**

**Location:** `scripts/purity-check.sh` (extracted from `ci.yml:329–349` and `justfile:242–262`); `FORBIDDEN_RE` pattern set.

**Claim:** The BI-081 fix (committed at `2616257`) INVERTED the asymmetry rather than removing it. Two distinct blind classes, both orchestrator-confirmed by execution at `2616257`:

**(a) Multi-line grouped-import blindness.** `grep -E` is line-oriented, so every `std::\{[^}]*\bNAME\b` arm required the brace and the name to appear on one PHYSICAL line. Any `use` statement that `rustfmt` reformats across multiple lines made all four forbidden paths invisible.

**(b) Inverted fs/net asymmetry.** BI-081 gave `stdout`/`Instant` prefix-free arms (`\bio::stdout\b`, `\btime::Instant\b`) but gave `fs`/`net` none, so `fs`/`net` became the new blind pair. Brace-scoped `[^}]*` also cannot reach `fs` in `use std::{collections::{A, B}, fs};` without crossing the inner `}`.

**Accident-reachable, not evasion-only:** `rustfmt --emit stdout` was run and emits `fs,` alone on its own line once the statement exceeds max_width; there is no `rustfmt.toml` in the repo, and `cargo fmt --all --check` is branch-protection-required — so the required formatter PRODUCES the blind shape.

**ORCHESTRATOR-CONFIRMED EMPIRICALLY:** EIGHT shapes confirmed bypassing at `2616257` and confirmed caught at `98a4f15` by planting each into real `mdlinkcheck-core` source (gate exit 1 for each): sibling-nested+fs, sibling-nested+net, multi-line fs, multi-line `io::{stdout}`, multi-line net, multi-line Instant, `use std::io as _i; _i::stdout()`, `use std::time as _t; _t::Instant::now()`. Five previously-caught controls stayed caught; three clean additions stayed green.

**Found independently by all three passes** — highest confidence.

**Status: FIXED at `98a4f15`.**

---

### P24-02 — MEDIUM — L6 — Purity Self-Check Coverage: Blind Arm Masking

**Register row: BI-092.**

**Location:** `scripts/purity-check.sh` (then `ci.yml`/`justfile`); the self-check plant set.

**Claim:** The `2616257` self-check could go green while a load-bearing arm was blind. Five arms had no plant depending on them alone — notably `std::\{[^}]*\bfs\b`, the very arm that closed the founding P16-05/P17-04 bypass, because plant `_p1` was also satisfied by the plain `std::fs` arm via its fully-qualified call on the same line. That is literally "one blind arm hiding behind a sibling arm that fires" — the failure mode the comment four lines above claimed to prevent.

**ORCHESTRATOR-CONFIRMED:** plant `_p1` satisfied by the `std::fs` plain arm, leaving the grouped-import arm untested.

**Fix:** Isolated plants: 9 → 21 plants (including 5 multi-line/nested) and 4 → 6 negative controls. The header now asserts only the property that is TRUE (every enumerated shape is caught by the detector as a whole) and explicitly disclaims per-arm isolation, since arms deliberately overlap for defence in depth.

**Status: FIXED at `98a4f15`.**

---

### P23-02 / P24-03 — MEDIUM — L6/L1 — Gate Text Misquotes Frozen ADR-001

**Register row: BI-093.**

**Location:** `scripts/purity-check.sh`; the printed success message.

**Claim:** The gate printed "ADR-001 enumerates path-fragments, not macros" on every green run. That is FALSE about a frozen spec: `ADR-001-pure-core-effectful-shell.md` reads "... random-number generators, **or any other I/O primitive**" — it enumerates four paths then generalises, and already includes a non-path item (RNG). So `println!` IS forbidden by ADR-001; the gate merely cannot enforce it.

**Documented real harm:** pass 21 found the macro gap and DECLINED to file it as a finding, citing exactly this claim, which `2616257` had promoted from an analyst's aside into durable gate-printed text. Corrected to quote the catch-all, name the other uncovered primitives (`io::stdin`, `io::stderr`, `std::process`, `std::env`, `SystemTime::now`), and state that the gap is a limit of the CHECK, not a permission granted by ADR-001.

**Found independently by passes 23 and 24** — high confidence.

**Status: FIXED at `98a4f15`.**

---

### P22-02 — MEDIUM — L6 — `mktemp` Template Not Portable

**Register row: BI-094.**

**Location:** `scripts/purity-check.sh` (was `ci.yml`/`justfile` purity self-check block); `mktemp` invocation.

**Claim:** `mktemp /tmp/purity-selftest-XXXXX.rs` was not portable. Pass 22 flagged the location and guessed "Invalid argument"; the real darwin behaviour is differently shaped and was confirmed by execution: BSD `mktemp` substitutes only TRAILING X's, so the non-trailing template is returned LITERALLY — call 1 returned `/tmp/purity-selftest-XXXXX.rs`, call 2 returned `mktemp: mkstemp failed ...: File exists`. Two concurrent runs therefore collide, and any ungraceful exit before the trap leaves `just purity` unrunnable until the file is deleted by hand — which actually happened during this session.

**ORCHESTRATOR-CONFIRMED EMPIRICALLY:** BSD mktemp behaviour verified; file collision confirmed during session.

**Fixed** to trailing X's, verified unique per call.

**Note:** The line pre-existed `2616257`; the adversary named the right location with the wrong mechanism. Both the location and the fix are correct.

**Status: FIXED at `98a4f15`.**

---

## LOW / NITPICK Round-3 Findings — Fixed at `98a4f15`

These sat in files already being edited; several were residuals of `2616257` itself. All fixed because co-located with material edits:

| Finding | Subject | Scope |
|---------|---------|-------|
| P23-03 | Justfile header falsely claimed "(separate recipes exist)" for `vef-selftest`/`verify-evidence-figures` — neither is a just recipe | LOW |
| P22-05 | Header said "the 5 blocking ones"; only FOUR are branch-protection-required (`purity` is blocking only inside `just ci`) | LOW |
| P24-05 | `test` recipe cited D-006's retired three-platform matrix, superseded by D-043 | LOW |
| P23-04 | `POL11_TEST_FLOOR=44` is platform-dependent — 3 tests are `#[cfg(unix)]` at `scanner_discovery_tests.rs:472/:526/:1411`, so non-unix compiles 41 and the floor emits a misleading "silently dropped out" diagnostic; **fails CLOSED** | LOW |
| P22-04 / P24-04 | `just` missing from lefthook prerequisites though pre-push runs `just purity` | LOW |
| P22-06 / P23-N1 | Lefthook accounting applied its "substantive step" standard asymmetrically and called the purity mirror "byte-identical"; standard now stated once and applied uniformly, purity row now says identical-by-shared-file | LOW |
| P22-03 | `fuzz-smoke` had the command substitution in the for-loop word list, which `set -e` does not cover — now captured first, matching the hardening.yml sibling that documents the correct form | LOW |

---

## LOW / NITPICK Carried Forward — D-261 Scoping, Not Fixed

These were DISCLOSED at the wave-1 gate and remain in the register. No change in this round:

| Register Row | Subject | Round First Found |
|--------------|---------|-------------------|
| BI-084 | Stale `scanner.rs` line citations at `scanner_discovery_tests.rs:1087` and `:1385` | Round 2 (passes 19–21) |
| BI-085 | Dot-path scan root exempt from the dot-component filter; route to S-1.02 | Round 2 |
| BI-086 | VP-017 divergence undisclosed in source | Round 2 |
| BI-087 | `just spec-lint` LOUD-SKIP exits 0 instead of 5 | Round 2 |
| BI-088 | "All 44 tests" in a 27-test file | Round 2 |
| BI-089 | `mdlc_probe.md`/`mdlc_keep.md` fixture prefix; intent pending | Round 2 |

---

## BI-095 — LOW — Orchestrator Mutation Testing: Backstop Survivor

**Not adversary-found; orchestrator mutation testing per L-90.**

**Register row: BI-095.**

Six targeted mutations were run against a hermetic out-of-tree copy with assert-mutant-landed per L-90. Kill counts:

| Mutation | Tests Killed |
|----------|-------------|
| Case-insensitive extension match | 6 |
| `filter_entry` guard removed | 2 |
| Gitignore disabled | 10 |
| `follow_links(true)` | 2 |
| `files.sort()` + `files.dedup()` removed | 0 |
| `collect_md_files` post-filter dot-component backstop removed | **0** |

The dedup survivor is already registered (F-B1/F-B3/C-B1, deferred to S-1.02).

**The backstop survivor is new:** `filter_entry` and the post-filter backstop are MUTUALLY MASKING — removing either alone leaves all 44 tests green, because `filter_entry` handles dot-DIRECTORIES for `collect_md_files` consumers while the backstop's unique contribution is dot-FILES. The existing `test_build_walk_filter_entry_replaceable_but_collect_md_files_backstop_holds` does NOT lock the backstop; it asserts a property `filter_entry` alone satisfies.

**Orchestrator confirmed the backstop IS discriminable** via a dot-FILE with an ignore negation: with `.gitignore` = `.*` + `!.template.md`, `collect_md_files` returned `["visible.md"]` with the backstop and `[".template.md", "visible.md"]` without it.

**A lock is NOT being added** because dot-FILE exclusion is unadjudicated under D-252a — locking it would pin unadjudicated behaviour. Route to operator adjudication alongside D-252a.

**Status: OPEN — routes to operator adjudication alongside D-252a.**

---

## OFF-PERIMETER Routes to S-1.02 — Pass 24

Not blockers per D-254 `new_lens_routing`. Record for S-1.02 scoping:

1. **`ignore_case_insensitive` corollary gap.** `ignore_case_insensitive` is the one remaining implicit `WalkBuilder` option that RESTRICTS when set true, so the corollary "a regression in a remaining implicit option could only silently INCLUDE" does not hold universally — same for `same_file_system(true)` and any finite `max_depth`/`max_filesize`; candidate for explicit writing under the same L-88 rationale as `parents`.

2. **Scan-root symlink traversal.** `ignore` 0.4.33 `walk.rs:606` is `wd.follow_links(follow_links || p.is_file())` and `Path::is_file()` follows symlinks, so a scan root that is a symlink TO a `.md` file is force-followed, yielded, and exempt from the relative-path dot-component filter — belongs with the BI-085 explicit-PATH-root question under BC-2.01.002.

---

## Lessons Added This Session

Five lessons added (see `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/cycles/v1.0.0-greenfield/lessons.md` for full text):

| Number | Summary |
|--------|---------|
| L-92 | Sweep EVERY site when correcting a claim; prefer step-NAME references over line-number citations |
| L-93 `[process-gap]` | A fix that adds coverage asymmetrically can INVERT a defect rather than close it; enumerate the full set |
| L-94 `[process-gap]` | Verify a text-matching gate against the output of the project's own REQUIRED formatter, not hand-written samples |
| L-95 `[process-gap]` | Never attribute a gate's scope limits to a frozen spec without quoting the spec |
| L-96 `[process-gap]` | Duplicated gate logic is a defect generator; extract to one file so parity holds by construction |

L-93, L-94, L-95, and L-96 are process gaps. Per the Cycle-Closing Checklist, each requires either a follow-up story targeting a self-improvement epic or a justified deferral entry. **That disposition has NOT yet been made.** Do not invent story IDs; route to the operator at the wave-1 gate.

---

## Gate State at `98a4f15` (Orchestrator-Verified)

CI run `31482829662` at `98a4f15`:
- `Format check` — **success**
- `Clippy (deny warnings)` — **success**
- `Test (macos-latest)` — **success**
- `Build release (macos-latest)` — **success**

All four branch-protection-required checks GREEN.

- `MSRV check (1.88)` — **success**
- `Purity check (ADR-001)` — **success** (printed "purity self-check: PASS (21 evasion shapes each detected; 6 clean samples each not matched)")
- `VEF selftest suite` — **success**
- `Spec lint` — **failure** — exactly 39 SCENARIO-MISMATCH, sole failing checker is `check-ec-injectivity`; known D-246 advisory, NOT required
- `Verify evidence figures (advisory)` — **skipped** (`pull_request`-only, has never run on this branch)

The 39 SCENARIO-MISMATCH are distributed across BC-2.05 through BC-2.14 and **ZERO are in BC-2.01.*** — S-1.01's own subsystem. The advisory spec-lint failure is entirely outside this story's contract scope.

44 tests pass. HEAD `98a4f15`, tree CLEAN, PUSHED, tracking origin.

27 commits total on `feature/S-1.01-workspace-scaffold-and-core-discovery`.
