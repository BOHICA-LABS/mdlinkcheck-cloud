# PR Review — #5 `fix/hardening-pins`

**Reviewer:** pr-reviewer (fresh context, diff-only)
**Scope reviewed:** `.github/workflows/hardening.yml` (+40 / -5), PR description, branch protection config
**Verdict: REQUEST_CHANGES** — 1 BLOCKING, 1 MAJOR, 3 MINOR, 3 NIT

The four items this PR set out to do are done correctly, and I verified them
mechanically rather than taking the description's word for it. What I am blocking
on is not in the added lines — it is a pre-existing false-green path in the *same
job whose install line this PR just changed*, which this PR's pin makes strictly
more likely to trigger, and which the PR body affirmatively (and incorrectly)
certifies as clean under D-039.

---

## What I verified as correct

Parsed the workflow and enumerated every job rather than eyeballing the diff:

| Job | runs-on | job `permissions` | `timeout-minutes` | `continue-on-error` | checkout `persist-credentials` |
|-----|---------|-------------------|-------------------|---------------------|-------------------------------|
| audit | ubuntu-latest | `contents: read` | 15 | 0 | `false` |
| deny | ubuntu-latest | `contents: read` | 15 | 0 | `false` |
| semgrep | ubuntu-latest | `contents: read` | 20 | 0 | `false` |
| mutants | **macos-latest** | `contents: read` | 60 | 0 | `false` |
| fuzz-smoke | ubuntu-latest | `contents: read` | 30 | 0 | `false` |
| kani | ubuntu-latest | `contents: read` | 60 | 0 | `false` |

- **(c) Diff completeness — PASS.** 6/6 jobs carry `permissions: contents: read`;
  6/6 checkout steps carry `persist-credentials: false`. Nothing missed. YAML parses.
- **(d) D-039 — no new suppression introduced — PASS.** Zero `continue-on-error`,
  zero `|| true`, zero `exit 0` added anywhere in the diff. I also confirmed the
  claim about the mutants runner empirically: with `set -euo pipefail`, a failing
  `cargo mutants | tee` pipeline aborts *at the pipeline* and the step exits 1.
  The `exit ${PIPESTATUS[0]}` line is never reached, but the exit code is correctly
  preserved either way. That part of the PR body is accurate.
- **(e) SHA inventory — PASS, accurate and complete.** All three resolved against
  the GitHub API:
  - `actions/checkout` `11bd719…` → `refs/tags/v4.2.2` (lightweight tag) ✅
  - `Swatinem/rust-cache` `82a92a6…` → `v2.7.5` (annotated tag, dereferenced to
    commit `82a92a6…`, commit message "2.7.5") ✅
  - `actions/upload-artifact` `1746f4a…` → `refs/tags/v4.3.2` ✅
  The inventory is also *complete* — these are the only three actions referenced
  in the file. Adding the previously-undocumented `upload-artifact` entry was the
  right call.
- **SEC-1 / SEC-2 — correctly fixed.** Both now carry `--version` *and* `--locked`.
  Worth stating explicitly since the PR body does not: `--locked` means the crate's
  bundled `Cargo.lock` is honoured, so the pin covers the **entire transitive graph**,
  not just the top-level crate. That is a genuinely complete fix for CWE-829 on the
  cargo side. (See MINOR-1 for why the pip side is not equivalent.)
- **CI status.** Only GitGuardian has reported (SUCCESS). All four required contexts
  (`Format check`, `Clippy (deny warnings)`, `Test (macos-latest)`, `Build release
  (macos-latest)`) are absent — consistent with the stated Actions outage, not with a
  code defect. Note `strict: true` on develop, so the branch will need to be current
  with develop at merge time.

---

## Findings

### BLOCKING-1 — `fuzz-smoke` reports GREEN while fuzzing zero targets, and this PR's pin makes that more likely

**Category:** correctness / D-039 suppression
**File:** `.github/workflows/hardening.yml:237`

```bash
for target in $(cargo +nightly fuzz list 2>/dev/null); do
```

Two defects compound here:

1. `2>/dev/null` discards the error output of the command that enumerates what to fuzz.
2. Under `set -euo pipefail`, a **failing command substitution in a `for` word list does
   not abort the script.** The expansion yields the empty list, the loop body never
   executes, and the step exits 0.

I confirmed this empirically rather than reasoning about it:

```
$ bash -c 'set -euo pipefail; for t in $(cargo-fuzz-does-not-exist list 2>/dev/null); do echo "FUZZING $t"; done; echo done'
done
  -> exit code: 0
```

So any failure of `cargo fuzz list` — tool missing, tool broken, incompatible nightly,
non-zero exit for any reason — is converted into a passing fuzz gate that fuzzed nothing.
The step's own comment claims "exits 1 if any target crashes," which is only true for
targets it managed to enumerate.

**Why this PR makes it worse, and why I'm blocking rather than filing it:** SEC-2 pins
`cargo-fuzz` to `0.13.2` (good), but the toolchain two steps above is still
`rustup toolchain install nightly` — **unpinned, resolving to a fresh nightly on every
weekly run**. A frozen fuzz driver against a moving nightly is a well-known drift pair;
when that pair eventually breaks, the outcome is no longer a loud red build, it is a
silent green one. This PR introduces that coupling. Pinning the version was correct — the
problem is that the pin lands on top of a path that fails silently.

Suggested fix, in the file this PR already has a waiver to touch:

```bash
run: |
  set -euo pipefail
  if [ ! -d fuzz ]; then
    echo "No fuzz/ directory found — skipping smoke run."
    exit 0
  fi
  # Enumerate explicitly so a broken cargo-fuzz fails the job instead of
  # silently yielding an empty target list (D-039: no suppression).
  targets="$(cargo +nightly fuzz list)"
  if [ -z "${targets}" ]; then
    echo "::error::fuzz/ exists but cargo fuzz list returned no targets"
    exit 1
  fi
  for target in ${targets}; do
    echo "Fuzzing target: ${target} (30s)"
    cargo +nightly fuzz run "${target}" -- -max_total_time=30 -max_len=65536
  done
```

Note `targets="$(...)"` *is* covered by `set -e` (it is a simple command), unlike the
`for`-list form — that is the whole point of the restructure.

If the operator prefers to keep this PR strictly mechanical, I'll accept a documented
waiver plus a tracked follow-up. What I can't accept is the PR body's current claim of
"**0 D-039 violations**" while an explicit `2>/dev/null` sits on a security gate's
enumeration path.

---

### MAJOR-1 — `kani` gate silently self-disables the moment the workspace is scaffolded

**Category:** correctness / false-green
**File:** `.github/workflows/hardening.yml:278`

```bash
if ! grep -rq '#\[kani::proof\]' src/ 2>/dev/null; then
  echo "No Kani proof harnesses found — skipping."
  exit 0
fi
```

The proof-detection guard hardcodes a single root-level `src/` directory, and suppresses
`grep`'s stderr. If `src/` does not exist, `grep` fails, the negation succeeds, and the
job exits 0 announcing "no proof harnesses found" — which is indistinguishable from the
legitimate case:

```
$ bash -c 'set -euo pipefail; if ! grep -rq "#\[kani::proof\]" src/ 2>/dev/null; then echo "No Kani proof harnesses found — skipping."; exit 0; fi'
No Kani proof harnesses found — skipping.
  -> exit code: 0
```

The sibling guards in `audit`, `deny`, and `mutants` all probe for a **workspace root
`Cargo.toml`**, and the mutants run passes `-- --all-targets`. That is the shape of a
multi-crate Cargo workspace, where proof harnesses live under member crates and there is
frequently no root `src/` at all. In that layout this job passes green forever, having
verified nothing, and the `2>/dev/null` hides the "No such file or directory" that would
otherwise expose the misconfiguration.

Suggested fix:

```bash
if ! grep -rq --include='*.rs' '#\[kani::proof\]' .; then
```

…or gate on the same root-`Cargo.toml` guard the other three jobs use, so "workspace not
scaffolded" and "scaffolded but no proofs" are distinguishable states.

This is pre-existing and harmless *today* (the whole workflow is a vacuous no-op with no
`Cargo.toml` present), which is why it is MAJOR and not BLOCKING. But it directly
contradicts the D-040 row in the traceability table: "existing Cargo guards can still
fail (no Cargo.toml → skip) — this is the correct behaviour, not suppression." Applying
D-040's own test — *what happens if this control were removed?* — the answer is
**nothing changes**, because the control has already removed itself.

---

### MINOR-1 — (a) SEC-3's residual gap is honestly *labelled* but inaccurately *characterised*

**Category:** description accuracy
**File:** PR description, "Supply-Chain (pip / Python)" section

Credit where due: SEC-3 is unambiguously marked as **not fixed**, is correctly identified
as pre-existing, and is not smuggled into the "FIXED" column. There is no dishonesty about
status. But the risk characterisation is wrong in both directions:

**Overstated.** The PR says: *"a published 1.75.0 package could be replaced on PyPI via
maintainer account compromise without changing the version string."* PyPI permanently
forbids reusing a filename, even after a release is deleted — same-version file
replacement is not a supported attack path. The real value of `--require-hashes` here is
against index/mirror substitution and TLS-terminating MITM, not against in-place
replacement of an already-published artifact.

**Understated, and this is the part that matters.** The description frames the entire
residual gap as "pip cannot hash-verify inline." It omits the larger exposure:
`pip install semgrep==1.75.0` pins **only the top-level distribution**. Semgrep's whole
transitive dependency tree resolves to latest-compatible *at job execution time*, every
weekly run. That is precisely the CWE-829 condition SEC-1 and SEC-2 were raised for, still
fully open on this line.

The asymmetry the PR does not acknowledge, and should:

| | Version pinned | Transitive graph pinned | Hash-verified |
|---|---|---|---|
| `cargo install kani-verifier --version 0.67.0 --locked` | yes | **yes** (bundled `Cargo.lock`) | via registry checksums |
| `cargo install cargo-fuzz --version 0.13.2 --locked` | yes | **yes** | via registry checksums |
| `pip install semgrep==1.75.0` | yes | **no** | no |

So SEC-1/SEC-2 are complete fixes while SEC-3 is a partial mitigation with a materially
larger hole than described. Please reword the residual-gap paragraph to lead with unpinned
transitive dependencies, drop or correct the "replaced without changing the version string"
claim, and note that the deferred `requirements-semgrep.txt` fix closes both gaps at once
(a hash-pinned requirements file necessarily pins the full tree). No code change needed in
this PR.

---

### MINOR-2 — (b) The CI-4 decision is right; the rationale written into the file is not

**Category:** documentation accuracy
**File:** `.github/workflows/hardening.yml:138-143` (and the mirrored text in the PR body)

**To be unambiguous: keep `runs-on: macos-latest`.** The conclusion is correct and I am not
asking for it to be reverted. The stated mechanism, however, does not hold up:

> "A mutation that breaks macOS path-handling would pass on ubuntu (case-sensitive ext4)
> and give a false-green survivor signal."

A *survivor* is how `cargo-mutants` reports a **failure** — surviving mutants produce a
non-zero exit. A survivor is never a green signal, so "false-green survivor" describes
something that cannot happen. Working through what would actually occur on ubuntu:

- If the VP-008/VP-009 tests are **not** platform-gated, they fail on ext4 *unmutated*, so
  `cargo-mutants` fails its baseline run and aborts before generating a single mutant.
- If they **are** `cfg`-gated to macOS, they are skipped, macOS path mutations survive, and
  the job reports them as missed — a false *red*/noise problem, not a false green.

The genuinely sound justification is simpler and stronger: **mutation testing is only
meaningful when the detection oracle — the test suite — runs on its supported platform, and
`cargo-mutants` requires a passing unmutated baseline.** Per D-043 this project is macOS-only;
branch protection on develop requires exactly `Test (macos-latest)` and
`Build release (macos-latest)`, and the CI matrix was narrowed to macOS-only. A ubuntu
mutants run is therefore not "less sensitive," it is **invalid** — it cannot establish a
baseline.

That distinction has real consequences. As currently worded, a future maintainer doing a
CI cost review reads "10x cost for extra sensitivity" and reverts it. Reworded as "ubuntu
cannot produce a valid baseline," they don't. Please rewrite lines 138-143 accordingly and
cite D-043 as the platform-scope decision rather than as a cost-acceptance decision.

**On D-044's split:** exempting `audit`, `deny`, and `semgrep` is clearly right — none
execute the test suite. `kani` on ubuntu is also fine (bounded model checking is
platform-agnostic and Kani's Linux support is the better-trodden path). `fuzz-smoke` is the
one arguable case, since it does compile and execute crate code — but fuzz harnesses are
in-memory and the oracle is "did it crash," not "does the filesystem fold case," so ubuntu
is defensible. Worth one line in the file recording *why* fuzz-smoke is exempt while
mutants is not, so the next person doesn't have to re-derive it. (NIT-adjacent, folded here.)

---

### MINOR-3 — `timeout-minutes: 60` was not re-evaluated after the platform move

**Category:** reliability
**File:** `.github/workflows/hardening.yml:145`

The 60-minute budget was calibrated for ubuntu and is unchanged, but three things got more
expensive simultaneously:

1. macOS runners are materially slower than ubuntu for Rust compilation.
2. The job builds **two** tools from source every run — `cargo-nextest 0.9.98` and
   `cargo-mutants 24.11.2`. `Swatinem/rust-cache` caches the registry, the git DB, and
   `./target`; it does **not** cache `~/.cargo/bin`, so `cargo install` recompiles each time.
3. rust-cache keys are OS/arch-scoped, so the accumulated ubuntu cache is discarded and the
   first several macOS runs start cold. This job's `rust-cache` step also has no explicit
   `key:` (unlike `fuzz-smoke`'s `fuzz-nightly` and `kani`'s `kani`), so it is the most
   collision-prone of the three.

The failure mode is a timeout kill, which is a **loud** failure and not a false pass — hence
MINOR, not blocking. But it will most likely manifest on the first real run after Phase 3
lands code, when the signal is most wanted. Suggest raising `timeout-minutes`, adding an
explicit cache `key: mutants`, and/or installing both tools via SHA-pinned
`taiki-e/install-action` to get prebuilt binaries — that also *reduces* supply-chain surface
versus building from source, so it is congruent with this PR's goal. Also note the cost table
says "~10x": a longer wall-clock on top of a 10x per-minute rate compounds rather than adds.

---

### NIT-1 — The commented-out `issues: write` grant is now dead code

**File:** `.github/workflows/hardening.yml:31-33`

```yaml
permissions:
  contents: read
  # issues: write is needed for the schedule path to open a tracking issue
  # when a job fails.  Uncomment when the repo has a remote and issues enabled.
  # issues: write
```

Job-level `permissions` **replaces** workflow-level permissions — GitHub does not merge the
two. Now that all six jobs declare `contents: read`, uncommenting this line will silently
have no effect, and the "open a tracking issue on failure" work it describes will fail with
403 in a way that points at the wrong place. This is a direct, if minor, consequence of CI-7.
Please update the comment to say the grant must be added **at the job level** on whichever
job opens the issue, so the next maintainer isn't sent down a dead end.

### NIT-2 — CI-7 / D-029 traceability rows read repo-wide but are file-scoped

**File:** PR description, Traceability table

In `ci.yml`, only the `spec-lint` job has job-level `permissions`, and only its second
checkout has `persist-credentials: false`. `fmt`, `lint`, `test`, and `build-release` have
neither — and those are the four jobs that run on **every PR** and are the four required
contexts on develop, so they carry more credential-exposure surface than a weekly scheduled
workflow does. Limiting this PR to `hardening.yml` is a legitimate scope choice given the
`.github/**` waiver is PR-scoped, so this is not a defect in the diff. But "CI-7 IMPLEMENTED
— 6/6 jobs" and "D-029 COMPLIANT" read as repo-wide guarantees. Please add a scope qualifier
("hardening.yml only") and open a follow-up for `ci.yml`.

### NIT-3 — Pins are correct but nothing will ever move them

**File:** `.github/workflows/hardening.yml:12-14`

`actions/upload-artifact` is pinned at v4.3.2 (current: v7.0.1) and `Swatinem/rust-cache` at
v2.7.5 (current: v2.9.2, the pinned commit dates from 2024-10-12). SHA pinning is the
security property and it is done correctly, so this is not a vulnerability. But there is no
`.github/dependabot.yml` in the repo at all, so these pins will drift indefinitely and any
future advisory against them will go unnoticed — which is the failure mode a supply-chain
hardening PR exists to prevent. Suggest adding a `dependabot.yml` with the `github-actions`
ecosystem so pins receive reviewed bumps. Cheap, and it converts a static inventory comment
into a maintained one.

---

## Checklist disposition

| # | Item | Result |
|---|------|--------|
| 1 | Diff coherence | PASS — every hunk maps to SEC-1/SEC-2/CI-4/CI-7/D-029 or the SHA inventory. No unrelated changes. |
| 2 | Description accuracy | PARTIAL — see MINOR-1 (SEC-3 mischaracterised), MINOR-2 (CI-4 mechanism wrong), NIT-2 (scope overclaim), and the "0 D-039 violations" claim in BLOCKING-1. |
| 3 | Test coverage | N/A — CI config; no Cargo workspace exists yet. |
| 4 | Demo evidence | N/A accepted — CI workflow change, correctly declared as such. |
| 5 | Commit quality | PASS — single commit, conventional prefix, finding IDs, clear body. |
| 6 | Diff size | PASS — 40/5 in one file. |
| 7 | Missing changes | PASS for stated scope (6/6 and 6/6 verified). See NIT-2 for the unstated `ci.yml` remainder. |
| 8 | Dependency status | NOTE — PR #4 and #3 unmerged; body correctly states the ordering is operational, not technical, and the files do not overlap. `strict: true` on develop means the branch must be current at merge. |

**One process note:** `hardening.yml` triggers only on `schedule` and `workflow_dispatch`,
so it will not run on this PR *even after the outage clears*. The "YAML syntax validity —
valid — PASS" row cites no method, and there is no actionlint/yamllint anywhere in the repo.
I independently confirmed the file parses and that all six jobs are well-formed, so I am not
raising a finding — but since `hardening.yml` is present on `main`, a `workflow_dispatch`
against `fix/hardening-pins` is possible and would be the only real execution evidence
available for this change. Worth doing before merge if the outage clears.

---

## Summary

SEC-1, SEC-2, CI-7, and the `persist-credentials` convention are correctly and completely
implemented, and I verified all three action SHAs against the GitHub API rather than trusting
the comment. The macOS move for `mutants` is the right call. Nothing in the added lines
weakens a control.

The blocker is that this PR certifies D-039 compliance on a file that contains a fuzz gate
which exits 0 having fuzzed nothing whenever `cargo fuzz list` fails, with the failure
explicitly routed to `/dev/null` — and SEC-2's pin against a still-floating `nightly`
toolchain is exactly the drift pair that eventually triggers it. Fixing it is a few lines in
a file you already hold a waiver for. MAJOR-1 is the same class of defect in the `kani` gate
and should be tracked even if not fixed here.

Happy to re-review immediately on push.
