# PR Review — Cycle 2 (final convergence pass)

**PR:** #4 — `ci: narrow platform matrix to macOS-only (D-043)`
**Branch:** `chore/macos-only-ci` → `develop`
**Reviewed SHA:** `6503d3baacaa7aef2b9e6fe44f27aadb13d239ae`
**Verdict:** APPROVE (no blocking findings)

Fresh-eyes review of the diff, PR description, and repository check evidence. This is
cycle 2; cycle 1's two findings (`persist-credentials`, single-entry matrix templating)
are confirmed fixed below by direct inspection rather than by trusting the claim.

---

## What I verified (not rubber-stamped)

### 1. Required-context names are literal strings in the YAML

Parsed the workflow at the reviewed SHA and dumped each job's resolved `name:` and
`runs-on:`, then compared against live branch protection on **both** `develop` and `main`:

| Job | `name:` in YAML | `runs-on:` | `strategy` block |
|---|---|---|---|
| `fmt` | `Format check` | `ubuntu-latest` | none |
| `lint` | `Clippy (deny warnings)` | `ubuntu-latest` | none |
| `test` | `Test (macos-latest)` | `macos-latest` | none |
| `build-release` | `Build release (macos-latest)` | `macos-latest` | none |
| `spec-lint` | `Spec lint` | `ubuntu-latest` | none |

Live required contexts on `develop` **and** `main` are identical:
`["Format check","Clippy (deny warnings)","Test (macos-latest)","Build release (macos-latest)"]`

All four resolve to literal YAML strings with no template expansion. Deadlock risk from
a renamed-but-still-required context is **zero** — this was the highest-consequence failure
mode for this PR and it is clean. `spec-lint` correctly remains non-required (D-029/D-032).

### 2. `persist-credentials: false` on every checkout

`actions/checkout@` appears 6 times; `persist-credentials: false` appears 6 times, and
the structural parse confirms the attribute is attached to all 6 checkout steps
individually (not merely co-located in the file):

- `fmt`, `lint`, `test`, `build-release`, `spec-lint` primary — 5 newly added
- `spec-lint` secondary (`ref: factory-artifacts`) — already had it, unchanged

Cycle 1 MAJOR finding is fully resolved. No checkout leaves a usable `GITHUB_TOKEN` in
`.git/config` for later steps to reach.

### 3. No residual matrix / template machinery

`strategy`, `matrix`, `fail-fast`, and `${{ matrix.* }}` are absent from the entire file.
Remaining `ubuntu-latest` hits are exactly the three intentional D-044 jobs
(`fmt`, `lint`, `spec-lint`); remaining `windows`/`D-006` hits in the file are comment
prose documenting the retirement, not live configuration.

### 4. Cache-key continuity (checked because renames silently orphan caches)

`test-${{ matrix.os }}` with `os: macos-latest` expanded to `test-macos-latest`, and the
literal is now exactly `test-macos-latest`. Same for `release-macos-latest`. The keys are
byte-identical to what the previous config produced, so existing warm caches remain
addressable — no silent cold-cache regression. The now-redundant per-OS-collision comment
was correctly dropped along with the matrix.

### 5. Diff coherence, description accuracy, size, commits

- Exactly one file changed (`.github/workflows/ci.yml`, +26/−29). No unrelated changes,
  no drive-by edits, no `hardening.yml` scope creep.
- PR description's per-job platform table matches the YAML row for row, including the
  D-044 cost-efficiency rationale for keeping `fmt`/`lint`/`spec-lint` on Ubuntu.
- Both commits use conventional format with substantive bodies explaining *why*.
  Commit `6503d3b` accurately attributes itself to review cycle 1.
- 55 lines changed — far under any size concern.
- Branch is exactly up to date with `develop` (merge-base == `origin/develop` tip
  `2290cb0`), so `strict: true` branch protection will not demand a rebase.

### 6. No D-039 violations

No allowlists, skip-lists, `continue-on-error`, or suppression mechanisms are introduced.
The `Cargo.toml` guards are pre-existing and step-level, so the five job names still
register as check runs while the workspace is unscaffolded — which is precisely what
keeps required contexts satisfiable. Least-privilege `permissions: contents: read` is
preserved at workflow level.

### 7. Nothing new broken by `6503d3b`

Full YAML parse succeeds. Removing `fail-fast: false` is a no-op on a single job (it only
governs sibling-cancellation within a matrix). `needs: [fmt, lint]` on `build-release` is
unchanged. No step, `if:`, `env:`, timeout, or SHA pin was altered by the hardening commit.

---

## Findings

### [SUGGESTION] `justfile` still cites D-006 cross-platform verification as live policy

`justfile` (lines ~51–53, not in this diff) documents the `test` recipe as follows:

```
# test — run full test suite with nextest (matches CI test job)
#
# Cross-platform correctness (D-006): path case-sensitivity and NFC
# normalization must be verified on macOS (case-insensitive) and
# Linux (case-sensitive).  Run on Windows via WSL or native.
```

This PR is what makes that comment wrong. The header explicitly claims the recipe
"matches CI test job", and this PR retires the three-platform matrix that the D-006
rationale existed to justify — so a developer reading the `justfile` is now told to verify
on Linux and Windows for a product that D-043 scopes to macOS exclusively, and is pointed
at a CI job that no longer does what the comment says it mirrors.

Why it is not blocking: the impact is confined to comment prose. The recipe body is
`cargo nextest run --all-targets` with no platform logic, so neither `just test` nor CI
changes behavior, and `set windows-shell` is inert shell selection rather than a platform
commitment. Blocking a correct CI-config change on a stale comment in an untouched file
would be disproportionate.

Suggested follow-up (cheap enough to fold into this PR if you prefer a clean sweep):

```
# test — run full test suite with nextest (matches CI test job)
#
# Platform scope per D-043 (supersedes D-006): product targets macOS
# exclusively.  Path case-sensitivity and NFC normalization are verified
# on macOS only; CI runs this job on macos-latest.
```

Same pattern is worth a grep for wherever else D-006 is asserted as current, so the
supersession lands everywhere rather than only in `ci.yml`.

---

## Not assessed / out of scope

- **CI green evidence.** Only `GitGuardian Security Checks` (GitHub App, `pass`) has
  reported; the four required Actions contexts have not posted, and `mergeStateStatus`
  is `BLOCKED` as a consequence. This is consistent with the ongoing GitHub Actions
  incident and is an infrastructure condition, not a defect in this diff — nothing in
  the changed YAML could suppress those check runs (verified: job names register
  independently of the `Cargo.toml` guards). I am approving the change on its merits;
  **the merge gate on the four required contexts still applies and is the pr-manager's
  call per D-028.** Do not interpret this approval as a waiver of those checks.
- **`hardening.yml`** is unchanged by this PR and was not re-reviewed. The cycle-1
  observation about unpinned `kani-verifier` / `cargo-fuzz` installs lives there and
  remains open on its own track.

---

## Verdict

**APPROVE.** No blocking findings. The stated objective (D-043 narrowing) is implemented
correctly and completely, the cycle-1 MAJOR and NIT are genuinely fixed rather than
papered over, required-context alignment is verified against live protection on both
protected branches, and cache addressing survives the rename. One non-blocking
documentation-drift suggestion (`justfile` D-006 comment) is recorded above.

Reviewed at `6503d3baacaa7aef2b9e6fe44f27aadb13d239ae`.

---

## Posting record

| Field | Value |
|---|---|
| Reviewed SHA | `6503d3baacaa7aef2b9e6fe44f27aadb13d239ae` |
| Verdict | APPROVE (no blocking findings) |
| GitHub review ID | `4877556940` |
| GitHub review state | `COMMENTED` (see constraint below) |
| Posted via | `gh pr review 4 --comment --body-file` (github-ops) |
| Reviewer account | `drbothen` |

**Why the GitHub review state is `COMMENTED` and not `APPROVED`:**
`gh pr review 4 --approve --body-file ...` was attempted first and was rejected by the
GitHub API:

```
failed to create review: GraphQL: Review Can not approve your own pull request
(addPullRequestReview)
```

The authenticated account (`drbothen`) is the PR author, and GitHub structurally forbids
self-approval. This is a platform constraint with no workaround from this account.

Fallback used was `gh pr review --comment` — still a **formal review object** bound to the
reviewed commit SHA (hence the review ID and `commit_id` above). This is NOT
`gh pr comment`, which would have produced a mere issue comment with no review record and
no SHA binding.

**Merge-gate implications for pr-manager:**
- `reviewDecision` will remain empty for this PR and can never show `APPROVED`. Do not
  block waiting on an approval badge that cannot appear.
- `required_approving_review_count` on `develop` is `0`, so no approving review is needed
  to merge. Verified via branch-protection API.
- `mergeStateStatus` was `BLOCKED` at review time: only `GitGuardian Security Checks`
  had reported (`pass`); the four required Actions contexts had not posted, consistent
  with the ongoing GitHub Actions incident. The four required contexts remain a hard
  merge gate and are the pr-manager's call per D-028. This APPROVE verdict covers the
  correctness of the diff only and is **not** a waiver of those checks.
