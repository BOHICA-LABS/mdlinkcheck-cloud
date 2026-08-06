---
document_type: cicd-setup-report
level: ops
version: "1.0"
phase: 1-cicd
step: phase-1-cicd-setup
producer: devops-engineer
timestamp: 2026-08-05T00:00:00Z
project: mdlinkcheck
status: complete
deferred: true
deferred_reason: LOCAL-ONLY repo (D-002) — no remote at time of creation
inputs:
  - .factory/STATE.md
input-hash: "4b1d9c6"
traces_to: .factory/STATE.md
---

# CI/CD Setup Report: mdlinkcheck

## Summary

Greenfield Phase-1 CI/CD setup complete.  Six artifacts created for a
LOCAL-ONLY repository (decision D-002: no `origin` remote).  Workflows are
remote-ready; branch protection and required status checks are deferred until
a remote is configured.

---

## Files Created

| File | Purpose |
|------|---------|
| `.github/workflows/ci.yml` | Per-push / per-PR pipeline (fmt, lint, test ×3 platforms, build-release ×3 platforms) |
| `.github/workflows/hardening.yml` | Weekly + manual Phase-6 gates (audit, deny, semgrep, mutants, fuzz-smoke, kani) |
| `justfile` | Local task runner — `just ci` reproduces the full pipeline locally |
| `lefthook.yml` | Git hooks — pre-commit: fmt+clippy; pre-push: nextest |
| `deny.toml` | cargo-deny policy (licenses, advisories, bans, sources) |
| `.gitignore` | Updated with standard Rust entries; `.factory/` worktree line preserved |

---

## CI Job Inventory

### ci.yml jobs

| Job | Runner | Timeout | Local equivalent |
|-----|--------|---------|-----------------|
| `fmt` | ubuntu-latest | 10 min | `just fmt-check` |
| `lint` | ubuntu-latest | 20 min | `just lint` |
| `test` | ubuntu × macos × windows | 30 min each | `just test` |
| `build-release` | ubuntu × macos × windows | 30 min each | `just build-release` |

### hardening.yml jobs

| Job | Runner | Timeout | Local equivalent |
|-----|--------|---------|-----------------|
| `audit` | ubuntu-latest | 15 min | `just audit` |
| `deny` | ubuntu-latest | 15 min | `just deny` |
| `semgrep` | ubuntu-latest | 20 min | `just semgrep` |
| `mutants` | ubuntu-latest | 60 min | `just mutants` |
| `fuzz-smoke` | ubuntu-latest | 30 min | `just fuzz-smoke` |
| `kani` | ubuntu-latest | 60 min | `just kani` |

---

## Local Equivalents (exact commands)

Every CI job maps to a `just` recipe.  With no remote, `just ci` IS the
canonical CI gate.

```bash
# Run the full CI pipeline locally
just ci

# Individual jobs
just fmt-check        # cargo fmt --all --check
just lint             # cargo clippy --all-targets --all-features -- -D warnings
just test             # cargo nextest run --all-targets
just build-release    # cargo build --release

# Hardening (Phase 6)
just hardening        # runs all six hardening checks sequentially

# Performance budget (R8: 500 md files in <5s)
just bench PATH=/path/to/docs-repo

# Install all required tools
just install-tools
```

---

## Cross-Platform Matrix Rationale (D-006)

The test and build-release jobs run on ubuntu-latest, macos-latest, AND
windows-latest.  This is a **correctness requirement**, not portability
nicety.  The domain spec (DI-002) requires path case-sensitivity and NFC
normalization behavior to be identical on all three platforms.  macOS uses a
case-insensitive HFS+ filesystem by default; Windows uses NTFS (case-
insensitive); Linux uses ext4 (case-sensitive).  Tests that verify anchor
resolution and file-path checking must be exercised on all three or the
behavior is undefined on two of the three supported platforms.

---

## Pinned Toolchain

The repo pins `rust-toolchain.toml` to `1.97.0` with components:
`rustfmt`, `clippy`, `llvm-tools-preview`, `rust-src`.

All CI jobs rely on the toolchain file being picked up automatically by
`rustup` / `cargo` on first invocation.  No explicit toolchain-install action
is used — `rust-toolchain.toml` is the single source of truth.

The fuzzing job installs `nightly` alongside the pinned toolchain (only nightly
supports `cargo fuzz`).

---

## Action SHA Pinning

All `uses:` references are pinned to full 40-character commit SHAs per
supply-chain security requirements.  Mutable version tags (e.g. `@v4`) are
not used.

### Verified SHAs in use

| Action | Pinned SHA | Version tag |
|--------|-----------|-------------|
| `actions/checkout` | `11bd71901bbe5b1630ceea73d27597364c9af683` | v4.2.2 |
| `Swatinem/rust-cache` | `82a92a6e8fbeee089604da2575dc567ae9ddeaab` | v2.7.5 |
| `actions/upload-artifact` | `1746f4ab65b179e0ea60a494b83293b640dd5bba` | v4.3.2 |

### SHA verification command

Before enabling remote CI, verify all SHAs:

```bash
# Verify a tag SHA
gh api repos/actions/checkout/git/refs/tags/v4.2.2 \
  --jq '.object.sha'

# Or use the GitHub UI: Releases → tag → commit SHA
```

---

## Tool Versions Pinned in Workflows and justfile

| Tool | Pinned version | Install |
|------|---------------|---------|
| cargo-nextest | 0.9.98 | `cargo install cargo-nextest --locked --version 0.9.98` |
| cargo-audit | 0.21.2 | `cargo install cargo-audit --locked --version 0.21.2` |
| cargo-deny | 0.17.0 | `cargo install cargo-deny --locked --version 0.17.0` |
| cargo-mutants | 24.11.2 | `cargo install cargo-mutants --locked --version 24.11.2` |
| semgrep | 1.75.0 | `pip install semgrep==1.75.0` |
| cargo-fuzz | latest nightly | `cargo +nightly install cargo-fuzz --locked` |
| hyperfine | latest | `brew install hyperfine` (bench recipe only) |

Versions should be bumped when a vulnerability is disclosed or when the
toolchain is upgraded.

---

## Git Hooks Setup

```bash
# Install lefthook hooks into .git/hooks/
lefthook install

# Test the pre-commit hook manually
lefthook run pre-commit

# Test the pre-push hook manually
lefthook run pre-push

# Skip hooks for a single commit (emergency only)
LEFTHOOK=0 git commit -m "..."
```

---

## Deferred Until a Remote Exists

The following items CANNOT be completed until `git remote add origin <url>` is
configured (decision D-002).  They are documented here for a future devops-
engineer run.

### 1. Branch protection on `develop`

```bash
gh api repos/ORG/REPO/branches/develop/protection -X PUT \
  --input - <<'EOF'
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "CI / Format check",
      "CI / Clippy (deny warnings)",
      "CI / Test (ubuntu-latest)",
      "CI / Test (macos-latest)",
      "CI / Test (windows-latest)",
      "CI / Build release (ubuntu-latest)",
      "CI / Build release (macos-latest)",
      "CI / Build release (windows-latest)"
    ]
  },
  "required_pull_request_reviews": {
    "required_approving_review_count": 0,
    "dismiss_stale_reviews": true
  },
  "enforce_admins": false,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF
```

### 2. Required status checks

The eight context strings above must match the exact job names that appear in
GitHub's Checks UI after the first successful CI run.  Verify with:

```bash
gh api repos/ORG/REPO/commits/HEAD/check-runs --jq '.[].name'
```

If the names differ from the strings listed, update the protection rule.

### 3. `.factory/` worktree on orphan branch

When a remote exists, promote `.factory/` to a git worktree on the
`factory-artifacts` orphan branch:

```bash
git checkout --orphan factory-artifacts
git rm -rf .
git commit --allow-empty -m "chore: initialize factory artifacts branch"
git push origin factory-artifacts
git checkout develop
git worktree add .factory factory-artifacts
```

### 4. PR gates and merge queue

After branch protection is active, configure the merge queue:

```bash
gh api repos/ORG/REPO/branches/develop/protection \
  -X PATCH \
  -F required_linear_history=true
```

### 5. `.worktrees/` — story worktrees

After Phase 2 story decomposition, create per-story worktrees:

```bash
git worktree add .worktrees/STORY-NNN -b feature/STORY-NNN develop
```

`.worktrees/` is in `.gitignore` and is never committed.

---

## Notes

- `CARGO_INCREMENTAL=0` is set in all CI jobs to prevent non-reproducible
  builds from causing cache-poisoning false-negatives.
- `RUST_BACKTRACE=1` is set globally so test failures include stack traces.
- `CARGO_TERM_COLOR=always` ensures log output is readable in GitHub's CI UI.
- The `fuzz-smoke` and `kani` jobs exit 0 gracefully when no harnesses exist
  yet, so the hardening workflow passes during early development phases.
- `fail-fast: false` on all matrix jobs ensures all platforms are tested even
  if one fails — critical for D-006 cross-platform correctness diagnosis.
