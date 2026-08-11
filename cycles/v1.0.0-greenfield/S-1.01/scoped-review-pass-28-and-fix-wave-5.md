---
document_type: adversary-convergence-audit
level: ops
version: "1.0"
status: complete-achieved-with-disclosed-residuals
producer: vsdd-factory:state-manager
story_id: S-1.01
cycle: v1.0.0-greenfield
head_sha: 0719c3c
perimeter_decision: D-254
passes_covered: [28]
pass_28_status: complete-material-findings-scoped-confirming-review
remediation_head_sha: 0719c3c
convergence_status: ACHIEVED-WITH-DISCLOSED-RESIDUALS
convergence_decision_refs: ["D-254", "D-263"]
standard_criterion_met: false
passes_clean: 0
required_clean_passes: 3
timestamp: "2026-08-11T00:00:00Z"
---

# Pass 28 — Scoped Confirming Review and Fix Wave 5

## Convergence Verdict

**S-1.01 convergence: ACHIEVED-WITH-DISCLOSED-RESIDUALS** (operator ruling D-263-continuation).

**MANDATORY QUALIFIER — do not soften:** The standard BC-5.39.001 criterion of three consecutive clean passes was **NEVER met**. `passes_clean` was **0 of 3** across all four confirming rounds (passes 16–27) and every pass returned `MATERIAL_FINDINGS`. Convergence is recorded on an operator-ruled non-standard path (D-254 + D-263), NOT by satisfying the three-clean-pass criterion.

Exact definition: frozen six-lens perimeter (L1–L6, frozen at pass 15 per D-254); adversarial rounds 1–4 (passes 16–27) plus one scoped confirming review (pass 28) of the fix surface only; C-class residuals plus P28-01, P28-04, and P28-05 disclosed rather than fixed; purity-gate claim language closed by explicit enumeration so the over-claim class cannot recur.

---

## Pass 28 — Scoped Confirming Review

### Scope and Angle

ONE pass, scoped to the fix surface only per D-263 step 4 ("review the fix, not the story"), against diff `b42285a..9796bf5` (17 files: `scripts/purity-check.sh` + the 16 demo-evidence files; `crates/`, `.github/`, `justfile`, `lefthook.yml` all byte-unchanged).

**Result: `MATERIAL_FINDINGS` — 1 MEDIUM, 4 LOW.**

---

### P28-01 (MEDIUM) — DISCLOSED (not fixed)

**Crate-root aliasing of `std` plus a renamed leaf escapes the purity gate.**

Shape: `mod m { pub use ::std as s; } use m::s::fs as f; f::metadata(p)`.

**Orchestrator-CONFIRMED exploitable.** Verified in an out-of-tree clone: compiles; `cargo fmt --all --check` exit 0; `cargo clippy --locked --all-targets --all-features -- -D warnings` exit 0; `cargo nextest run` 44/44; `./scripts/purity-check.sh` prints PASS exit 0.

Mechanism: `STMT_RE` requires `std` immediately followed by `::` (the alias breaks the adjacency anchor); `LINE_RE`'s `\bfs::` requires the trailing `::` (the rename removes it); the A2 `.method()` arm does not backstop it because `f::metadata(` is a path call, not a method call. Affects `std::fs` and `std::net`; `std::io::stdout` and `std::time::Instant` remain caught via call-site arms.

**Second exploitable escape found in this gate (BI-096 was the first) and the THIRD instance of the same over-claiming-scope-statement class (BI-081, BI-096, P28-01).**

**Disposition per D-263-continuation: DISCLOSED, not fixed.** No regex arms added ("optional means omitted under runway"). Extending purity coverage is an operator decision; record as a disclosed live gate hole for human review at the DEV-11 gate.

---

### P28-02 (LOW) — FIXED

The `Forbidden paths:` summary still named `RNG (rand)` after A3 broadened to five crates. Material-adjacent because it prints at line ~240 while `exit 1` is at ~245 and the SCOPE block at ~249 is unreachable after a FAIL — so on a FAIL it was the only forbidden-paths summary an operator saw. Now names all five crates.

---

### P28-03 (LOW) — FIXED

`PR-PACKAGE.md` operator-verdict comment template said `Fourth round outstanding` when four rounds had already run; inside a copy-paste template destined for a public PR comment. Now reflects actual state.

---

### P28-04 (LOW) — DISCLOSED

`.metadata()` and `.canonicalize()` are detected despite the same future-domain-name-collision hazard used to justify excluding `.exists()`/`.is_dir()`/`.is_file()`. Zero occurrences in `mdlinkcheck-core` today; a false positive fails CLOSED. Asymmetry now disclosed as deliberate and foreseen.

---

### P28-05 (LOW) — DISCLOSED

Third-party I/O crates undetected — `walkdir::WalkDir::new(".")` matches zero arms. All seven current core deps (`pulldown-cmark`, `globset`, `url`, `percent-encoding`, `unicode-normalization`, `serde`, `serde_json`) perform no I/O; latent, visible in dependency review.

---

### BI-100 — FIXED (not re-accepted)

Per pass 28's disposition and operator agreement: the `io::stdout` arm rationale comment was false on two counts and the round-4 wave had WIDENED its blast radius. Corrected to name the arm that actually fires (`\bstdout[[:space:]]*\(`, plant `_p09`) and to list all arms carrying no leading `\b`.

---

### Pass 28 Exoneration of Substance

Pass 28 exonerated the substance of all seven round-4 fixes. It independently re-derived the mutation kill sets as complete (not merely correct), verified all six mutation sites byte-exact against `scanner.rs`, verified the B3 quotation across a Rust line-continuation split that a naive grep misses, recomputed ~20 numerals, found no fabricated execution evidence and no convergence assertion, and checked the accepted C-class list for misclassification finding none.

---

## Fix Wave 5 — Commits and Orchestrator Verification

### Commit Chain

`cd3507a` (RED: 14 plants added, no regex change) → `9a9b46c` (A1/A2/A3 regex fix) → `2f93a31` → `8194232` → `8af58b1` (evidence B1/B3/B4 + residuals) → `beca9b6` → `9796bf5` (PR body B1–B4 + structural SHA fix) → `b538112` (claim-language closure, text-only) → `0a9c320` → `fc61828` (evidence attestation re-anchor) → `0719c3c` (PR body final).

### Orchestrator Verifications by Execution

**L-90 discipline held and was checked harder than reported.** `cd3507a` is genuinely RED (exit 1). But the self-check aborts on the FIRST failing plant, so that alone proved only `_p22` discriminates. Testing all 14 new plants individually against the pre-fix detector: **12 genuinely discriminate; `_p23` and `_p26` do NOT** — old `net::` matched regardless of the leading `::`, and old `rand::` matches `fastrand::` as a bare substring. Not a defect (the header disclaims per-arm isolation) but the plant set locks less than its count implies.

**A1 closed for all five categories** (`fs`, `net`, `rand`, `stdout`, `Instant`) — each exit 1.

**Claim-language closure at `b538112` is text-only and proven so:** `LINE_RE`, `STMT_RE`, `PLANTS`, `CLEAN` byte-identical to `9796bf5`; the diff contains nothing but comment and `echo` lines.

**The closed enumeration was probed, not read.** All 10 enumerated shapes resting on arm-verification alone (no dedicated plant) confirmed CAUGHT: `use std::io::stdout;`, `use std::time::Instant;`, sibling-nested stdout/Instant, absolute-prefix stdout/Instant, non-absolute leaf-aliased fs/net, `oorandom` import, `rand_chacha` import. All three disclosed gaps confirmed ESCAPING as disclosed. Clean control not flagged. The enumeration is exactly true.

Gates at each step: fmt 0, clippy 0, 44/44, shellcheck clean, `bash -n` clean, purity 0, `just purity` 0.

**CI green on all four branch-protection-required contexts at `b538112`** (`Format check`, `Clippy (deny warnings)`, `Test (macos-latest)`, `Build release (macos-latest)`), verified via `gh api`. Run-level conclusion `failure` because `Spec lint` is advisory-red by design (D-246).

`crates/` byte-unchanged from `9a9b46c` through `0719c3c` — zero paths.

---

## The Self-Invalidating-Attestation Defect Class — Process Evidence

**The same defect recurred FIVE times across two files:** the `f7c5b11`/`98a4f15` mis-anchoring (round 4); the `git diff ... ':(exclude)docs' returns nothing` claim (broken by the `b538112` purity commit); and three instances of asserting a named SHA IS current HEAD (`(current HEAD)`, `carry to this HEAD`, `confirmed closed at the current HEAD`) — each of which was false the instant it was committed.

Root cause, diagnosed only at the fifth recurrence: **a committed artifact can never truthfully assert that a named SHA is the current HEAD, because committing moves HEAD.** The orchestrator had been specifying instance fixes for a structural problem; the class only closed once the rule was stated as permitted/forbidden forms.

**Resulting rule:**

- **FORBIDDEN:** any claim that a named SHA is current.
- **PERMITTED (a):** immutable facts about fixed commits — "CI green at `b538112`"; "`crates/` byte-unchanged from `9a9b46c` to `b538112`" with both SHAs named.
- **PERMITTED (b):** verification commands phrased as instructions to the reader, making no claim about what HEAD currently is.

Note as corroborating evidence: `PR-PACKAGE.md`'s ancestor-check lines already used form (b) correctly throughout and were never defective — the pattern was available in the package and simply had not been applied to the attestation bullets.

See also L-102 (lessons.md) for the durable lesson derived from this class.
