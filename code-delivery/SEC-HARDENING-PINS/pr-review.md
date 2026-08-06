## PR Review — Cycle 2 (fresh-eyes, diff + description + evidence only)

**Verdict: APPROVE** — 0 blocking findings. All four cycle-1 items verified fixed. Six non-blocking findings below; two of them (F1, F6) are one-line comment corrections on lines this PR already touches and are worth folding in before merge.

Reviewed at `b054694` (`fix/hardening-pins` → `develop`), 1 file, +47/-11.

---

### Cycle-1 fix verification

| Cycle-1 finding | Status | How I verified |
|---|---|---|
| BLOCKING-1 fuzz silent-green | **FIXED** | Empirical shell test. `targets="$(false)"` under `set -euo pipefail` → script aborts, exit 1. Old form `for t in $(false 2>/dev/null)` → script continues, exit 0. Assignment exit status is that of the last command substitution, so errexit fires. Removing `2>/dev/null` also restores cargo's diagnostics to the job log. |
| MAJOR-1 kani workspace grep | **FIXED** (for the stated defect) | Built a `crates/{core,cli}/src` workspace fixture. Old `grep -rq ... src/` → rc=2 (`src/` does not exist), masked by `2>/dev/null` → silent skip. New `grep -rq ... . --include='*.rs'` → rc=0, matched `crates/core/src/lib.rs`. Option-after-path ordering is fine for GNU grep on `ubuntu-latest`. Two residual gaps in the same guard: see F3/F4/F5. |
| MINOR-2 CI-4 rationale | **CHANGED, still inaccurate** | See F1 — the new rationale contradicts `ci.yml` on this PR's own base branch and contradicts this PR's description. |
| MINOR-3 mutants timeout | **FIXED** | `timeout-minutes: 90` confirmed via YAML parse. Adjacent comment left stale — see F6. |
| NIT-1 dead `issues: write` comment | **FIXED** | Confirmed removed; top-level `permissions: contents: read` intact. |
| MINOR-1 SEC-3 description | **FIXED** | PR body now leads with the floating-transitive-dependency gap (CWE-829) and correctly notes PyPI forbids same-version file reuse. Technically accurate, including the point that `pip` has no `--locked` equivalent. |

### What I verified independently (not taken from the description)

- **YAML parses**; exactly 6 jobs; **6/6** carry `permissions: contents: read`; **6/6** checkouts carry `persist-credentials: false`; runners and timeouts match the description's table.
- **All three pinned action SHAs resolve and match their claimed tags** (GitHub API): `actions/checkout` `11bd719…` = v4.2.2; `Swatinem/rust-cache` `82a92a6…` = v2.7.5; `actions/upload-artifact` `1746f4a…` = v4.3.2. The updated SHA-inventory comment is accurate.
- **Both new pins exist and are the current max published versions** (crates.io sparse index): `kani-verifier` 0.67.0, `cargo-fuzz` 0.13.2. The description's claim is correct. Pre-existing pins also verified present: `cargo-audit` 0.21.2, `cargo-deny` 0.17.0, `cargo-nextest` 0.9.98, `cargo-mutants` 24.11.2.
- **No unpinned installer remains** other than the three already documented as pre-existing residuals (`rustup toolchain install nightly`, `semgrep --config=auto`, `cargo kani setup`).
- **D-039:** zero `continue-on-error`, zero `|| true`, zero `exit 0` bypasses added. `if: always()` on the artifact upload is not a bypass — the run step still fails the job.
- **Blast radius:** trigger set unchanged (`schedule` + `workflow_dispatch`, no `pull_request`), no `write` permission anywhere, no secrets referenced. Diff is 58 lines, far under the 500-line threshold. Commit messages are conventional with substantive bodies.

---

### F1 — [SUGGESTION] CI-4 comment asserts something the repo's own CI contradicts

`.github/workflows/hardening.yml` (mutants job header)

The new rationale states:

> On ubuntu, the baseline would fail — ubuntu is not a valid platform for this suite, not merely "less sensitive".

Three problems with that as a permanent code comment:

1. **It contradicts `ci.yml` on this PR's base branch.** `develop@2290cb0` runs `Test` on `ubuntu-latest`, `macos-latest`, and `windows-latest`, with the comment: *"Path case-sensitivity and NFC normalization must behave identically on all three platforms, so this matrix is a correctness gate, not merely a portability nicety."* The repo's stated design intent today is that the suite **must pass** on ubuntu. Two workflow files now assert opposite things about the same test suite.
2. **It contradicts this PR's own description.** The body's *Architecture Decision Context* for CI-4 still says the ubuntu baseline **passes** and the problem is false-green *survivors*. The yml now says the baseline **fails**. If the baseline fails you never get survivors — the two rationales are mutually exclusive.
3. **The inference doesn't hold.** Branch protection required contexts (`Test (macos-latest)`, `Build release (macos-latest)`) describe what gates a merge, not whether the suite passes on a platform. And there is no Cargo workspace in the repo yet, so neither claim is currently demonstrable.

The `runs-on: macos-latest` change itself is right and I'm not questioning it. Only the stated reason.

Suggested replacement that is verifiable today:

```yaml
    # D-043/D-044: mutation testing runs on macos-latest to match the only
    # required test context (branch protection: "Test (macos-latest)").
    # cargo-mutants drives the real test suite, and the properties most worth
    # protecting are macOS filesystem semantics (VP-008 case-insensitivity,
    # VP-009 NFC normalization).  Mutants must therefore be scored on the same
    # platform whose behaviour is gated.  Cost premium (~10x) accepted; see D-043/D-045.
```

Please also align the PR body's CI-4 paragraph with whichever rationale you keep.

### F2 — [SUGGESTION] Fuzz smoke still reports green when the target list is empty

`.github/workflows/hardening.yml` (fuzz-smoke → "Smoke run all fuzz targets")

The `set -e` propagation fix is correct, but one silent-green path survives it: if `fuzz/` exists and `cargo fuzz list` succeeds with **empty** output, the loop body never runs and the job passes having fuzzed nothing. Verified: `targets="$(true)"; for t in $targets; do …; done` → exit 0, zero iterations.

Realistic trigger: `fuzz/fuzz_targets/` renamed, `[[bin]]` entries dropped from `fuzz/Cargo.toml`, or a future change to `cargo fuzz list` output. A `fuzz/` directory that exists with zero targets is a misconfiguration, not a legitimate skip — the `[ ! -d fuzz ]` guard above already covers the legitimate skip.

```bash
targets="$(cargo +nightly fuzz list)"
if [ -z "${targets//[[:space:]]/}" ]; then
  echo "fuzz/ exists but cargo fuzz list returned no targets — harness set is broken."
  exit 1
fi
```

### F3 — [SUGGESTION, MAJOR-class] Kani guard treats a grep *error* as "no harnesses"

`.github/workflows/hardening.yml` (kani → "Run Kani proofs")

```bash
if ! grep -rq '#\[kani::proof\]' . --include='*.rs' 2>/dev/null; then
```

`grep` returns 0 = match, 1 = no match, **2 = error**. The `!` disables errexit for this command and `2>/dev/null` hides the reason, so rc=2 produces the exact same green `exit 0` skip as a genuine no-match — the same silent-failure class that was blocking in cycle 1, in the sibling job. Verified: `grep -rq 'zzz' ./does-not-exist --include='*.rs' 2>/dev/null` → rc=2.

Widening the search from `src/` to `.` enlarges the surface for rc=2 rather than shrinking it. Suggested:

```bash
rc=0
grep -rqE 'kani::proof(_for_contract)?' . --include='*.rs' --exclude-dir=target || rc=$?
case "$rc" in
  0) ;;
  1) echo "No Kani proof harnesses found — skipping."; exit 0 ;;
  *) echo "grep failed with status $rc"; exit "$rc" ;;
esac
cargo kani
```

Not blocking because the guard is provably inert today (no `Cargo.toml`, zero `.rs` files, schedule-only workflow, every job no-ops). It does need tightening before the first Kani harness lands, or the Phase-6 proof gate can report green with zero proofs executed.

### F4 — [SUGGESTION, MAJOR-class] Guard pattern misses two real Kani harness forms

Same line. `'#\[kani::proof\]'` is a literal match and does not cover:

- `#[kani::proof_for_contract(f)]` — function-contract verification, a first-class Kani harness form
- `#[cfg_attr(kani, kani::proof)]` — used to keep harnesses out of non-kani builds

Verified: a tree containing **only** those two forms yields rc=1, so the job prints "No Kani proof harnesses found — skipping" and exits 0 while real harnesses sit unverified. `grep -rqE 'kani::proof(_for_contract)?'` returns rc=0 on the same tree. Folded into the F3 snippet above.

### F5 — [NIT] Kani guard now scans `target/`

Same line. The grep runs *after* `Swatinem/rust-cache` restores the cache, so a restored `target/` is in scope. Generated sources under `target/*/build/*/out/*.rs` can satisfy the guard, letting `cargo kani` proceed on the strength of non-source files. Verified: my fixture matched `target/debug/build/foo-1/out/gen.rs`. Add `--exclude-dir=target` (already in the F3 snippet).

### F6 — [NIT] Stale budget comment left behind by the timeout bump

`.github/workflows/hardening.yml` (mutants → "Run mutation smoke test")

```yaml
        # -j2: parallelize 2 mutant builds (keeps time budget under 60 min)
```

`timeout-minutes` is now 90. Introduced by the MINOR-3 fix. Suggest "(keeps the run inside the 90-minute job budget)".

### F7 — [NIT, pre-existing, optional] `cargo-nextest` install appears unused

`cargo install cargo-nextest … # (needed by mutants runner)` — but the run step is `cargo mutants --no-shuffle -j2 --timeout 30 -- --all-targets`, with no `--test-tool nextest`, and the repo has no `mutants.toml` or `.config/nextest.toml`. `cargo-mutants` defaults to `cargo test`, so the comment's claim doesn't hold and the from-source nextest build looks like dead work. Flagging only because this PR moves the job to a ~10x-cost runner, so the wasted compile is now paid at 10x. Either pass `--test-tool nextest` or drop the step.

### F8 — [NIT, pre-existing, optional] Pinned tool versions are drifting stale

Pinning is correct and this PR improves it. Noting for the follow-up hardening PR: `cargo-mutants` 24.11.2 vs 27.1.0 current, plus older `cargo-audit`/`cargo-deny` pins. A ~21-month-old mutation engine may not parse current Rust syntax once the workspace exists. Pins need a refresh cadence (dependabot for `github-actions` + a periodic bump task) so "pinned" doesn't become "abandoned". The two pins added here are current.

---

### Checklist

| # | Item | Result |
|---|---|---|
| 1 | Diff coherence | PASS — single file, every hunk maps to SEC-1/SEC-2/CI-4/CI-7 or a cycle-1 fix |
| 2 | Description accuracy | PARTIAL — SEC-3 corrected; CI-4 paragraph now contradicts the yml (F1) |
| 3 | Test coverage | N/A — no Cargo workspace; CI config verified by parse + API checks instead |
| 4 | Demo evidence | N/A accepted — schedule-only CI workflow, no user-facing surface |
| 5 | Commit quality | PASS — conventional, scoped, substantive bodies |
| 6 | Diff size | PASS — 58 lines |
| 7 | Missing changes | PASS — all 7 installers pinned; residual unpinned items documented as pre-existing |
| 8 | Dependency status | NOTE — PR #4 still open; no structural dependency (different workflow files), so merge order stays operational. F1 point 1 resolves itself once #4 narrows the matrix, but the "would fail" claim still won't be demonstrated by it. |

CI status checks are absent due to the GitHub Actions outage — treated as environmental, not a defect, and not a factor in this verdict.
