---
document_type: cicd-setup-report
level: ops
version: "1.1"
phase: 1-cicd
step: phase-1-cicd-setup
producer: devops-engineer
timestamp: 2026-08-06T02:35:00Z
project: mdlinkcheck
status: complete
deferred: false
inputs:
  - .factory/STATE.md
input-hash: "1636936"
traces_to: .factory/STATE.md
---

# CI/CD Setup Report: mdlinkcheck

## Summary

Phase-1 CI/CD setup complete. Remote activated (D-002 superseded). Full
PR-based delivery model live. Six infrastructure artifacts plus branch
protection on both `main` and `develop`. Required status checks confirmed from
a live CI run.

---

## Branch Topology

| Branch | Role | Story PRs target? |
|--------|------|--------------------|
| `develop` | Integration branch | YES — all story PRs target develop |
| `main` | Releases only | NO — only receives merges from develop |
| `feature/STORY-NNN` | Per-story work | Created per-story in Phase 3 |

Story PRs: `feature/STORY-NNN` → `develop`
Release merges: `develop` → `main` (via PR)

---

## Files Created / Configured

| File | Purpose |
|------|---------|
| `.github/workflows/ci.yml` | Per-push / per-PR pipeline (fmt, lint, test ×3 platforms, build-release ×3 platforms) |
| `.github/workflows/hardening.yml` | Weekly + manual Phase-6 gates (audit, deny, semgrep, mutants, fuzz-smoke, kani) |
| `justfile` | Local task runner — `just ci` reproduces the full pipeline locally |
| `lefthook.yml` | Git hooks — pre-commit: fmt+clippy; pre-push: nextest |
| `deny.toml` | cargo-deny policy (licenses, advisories, bans, sources) |
| `.gitignore` | Updated: Rust entries, `.factory/` worktree, `.worktrees/` for Phase-3 story worktrees |

---

## Branch Protection — Applied Settings

### `develop` branch

| Setting | Value |
|---------|-------|
| Required PR reviews | 0 (dismiss stale: yes) |
| enforce_admins | false |
| required_linear_history | true |
| allow_force_pushes | false |
| allow_deletions | false |
| required_status_checks strict | true |
| Required contexts | 8 (see table below) |

### `main` branch

| Setting | Value |
|---------|-------|
| Required PR reviews | 0 (dismiss stale: yes) |
| enforce_admins | **true** (admins subject to all rules) |
| required_linear_history | true |
| allow_force_pushes | false |
| allow_deletions | false |
| required_status_checks strict | true |
| Required contexts | 8 (see table below) |

### Verified Required Status Check Names

These were captured from a live CI run on `develop` push
(run ID 31065845669, completed 2026-08-06 with `success` on all jobs).
GitHub Actions app_id confirmed as 15368.

| Context string (exact) | Job in ci.yml | Platform |
|------------------------|---------------|----------|
| `Format check` | `fmt` | ubuntu |
| `Clippy (deny warnings)` | `lint` | ubuntu |
| `Test (ubuntu-latest)` | `test` | ubuntu |
| `Test (macos-latest)` | `test` | macos |
| `Test (windows-latest)` | `test` | windows |
| `Build release (ubuntu-latest)` | `build-release` | ubuntu |
| `Build release (macos-latest)` | `build-release` | macos |
| `Build release (windows-latest)` | `build-release` | windows |

Note: The original deferred section predicted context strings prefixed with
"CI / " (e.g. "CI / Format check"). The actual names from GitHub are
unprefixed. This was verified from the live run — do NOT use the prefixed form.

---

## CI Job Inventory

### ci.yml jobs

| Job | Runner | Timeout | Guard | Local equivalent |
|-----|--------|---------|-------|-----------------|
| `fmt` | ubuntu-latest | 10 min | yes | `just fmt-check` |
| `lint` | ubuntu-latest | 20 min | yes | `just lint` |
| `test` | ubuntu × macos × windows | 30 min each | yes | `just test` |
| `build-release` | ubuntu × macos × windows | 30 min each | yes | `just build-release` |

### hardening.yml jobs

| Job | Runner | Timeout | Guard | Local equivalent |
|-----|--------|---------|-------|-----------------|
| `audit` | ubuntu-latest | 15 min | yes | `just audit` |
| `deny` | ubuntu-latest | 15 min | yes | `just deny` |
| `semgrep` | ubuntu-latest | 20 min | no (semgrep scans any dir) | `just semgrep` |
| `mutants` | ubuntu-latest | 60 min | yes | `just mutants` |
| `fuzz-smoke` | ubuntu-latest | 30 min | yes (existing) | `just fuzz-smoke` |
| `kani` | ubuntu-latest | 60 min | yes (existing) | `just kani` |

**Guard pattern**: All Cargo-dependent jobs check for `Cargo.toml` existence and
exit 0 gracefully if not found. This prevents deadlock on pre-workspace PRs
(spec deliveries, CI setup itself). After Phase 3 scaffolds the workspace, the
guards are transparent no-ops.

---

## Anti-Deadlock Sequencing Decision

**Decision**: Graceful no-op guards + immediate required-check configuration.

No `Cargo.toml` exists before Phase 3. Without guards, CI would fail on any PR
opened before the workspace lands (spec-only PRs, CI setup PRs). The fuzz-smoke
and kani jobs already use this pattern; it was extended to all Cargo-dependent
steps in both workflows. This allows branch protection with required status
checks to be fully configured from day one — there is no "unprotected window"
and no staged-activation complexity.

Implementation: each Cargo-dependent job has a guard step that writes
`skip=true` to `$GITHUB_OUTPUT` when `Cargo.toml` is absent. All subsequent
steps in the job use `if: steps.guard.outputs.skip != 'true'`. The guard step
uses `shell: bash` for cross-platform compatibility (Git Bash on Windows).

---

## Action SHA Pins — Verified

| Action | Pinned SHA | Version | Verification method |
|--------|-----------|---------|---------------------|
| `actions/checkout` | `11bd71901bbe5b1630ceea73d27597364c9af683` | v4.2.2 | `gh api repos/actions/checkout/git/refs/tags/v4.2.2` → `type: commit` ✓ |
| `Swatinem/rust-cache` | `82a92a6e8fbeee089604da2575dc567ae9ddeaab` | v2.7.5 | Annotated tag `5cb072d...` dereferences to this commit ✓ |
| `actions/upload-artifact` | `1746f4ab65b179e0ea60a494b83293b640dd5bba` | v4.3.2 | `gh api repos/actions/upload-artifact/git/refs/tags/v4.3.2` → `type: commit` ✓ |

Note: `Swatinem/rust-cache` v2.7.5 is an annotated tag (tag object SHA
`5cb072d7354962be830356aa6b146f7612846014`). The dereferenced commit SHA
`82a92a6e8fbeee089604da2575dc567ae9ddeaab` is correct — verified 2026-08-06.

---

## Semgrep Authentication

`semgrep --config=auto --error --metrics=off` in `hardening.yml` does NOT
require `SEMGREP_APP_TOKEN`. The `--config=auto` flag pulls rules from the
public Semgrep registry; `--metrics=off` disables telemetry. No secret is
needed or missing. The `hardening.yml` `permissions` block is least-privilege
(`contents: read` only) and no SEMGREP_APP_TOKEN secret needs to be configured.

---

## `.factory/` Worktree State

- Worktree path: `.factory/` (on `factory-artifacts` branch)
- Remote: `origin/factory-artifacts`
- Upstream tracking: SET (confirmed 2026-08-06 — was missing, now configured)
- `.gitignore` entry on `main`: `.factory/` ✓
- State-manager owns all commits to `factory-artifacts`. Do NOT commit from here.

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

## Open PR

**PR #1**: `develop` → `main` (CI infrastructure activation)
URL: https://github.com/BOHICA-LABS/mdlinkcheck-cloud/pull/1

This PR adds all workflow and toolchain files to `main`. It must be merged
by a human (auto-mode cannot self-merge authored PRs). CI checks on the PR
should be green (guards fire, no Cargo.toml). Required checks on `main` are
now configured, so the PR must pass all 8 CI checks before merge.

After merging:
- `main` will have CI workflows
- Future `develop` → `main` release PRs will have full CI coverage

---

## Local Equivalents (exact commands)

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
normalization behavior to be identical on all three platforms.

---

## Pinned Toolchain

Pinned to `1.97.0` via `rust-toolchain.toml` with components:
`rustfmt`, `clippy`, `llvm-tools-preview`, `rust-src`.

---

## Tool Versions Pinned

| Tool | Pinned version |
|------|---------------|
| cargo-nextest | 0.9.98 |
| cargo-audit | 0.21.2 |
| cargo-deny | 0.17.0 |
| cargo-mutants | 24.11.2 |
| semgrep | 1.75.0 |

---

## Residual Deferred Items

These items genuinely must wait — they are not blocking and have clear
activation triggers.

### 1. Merge PR #1 (human action required)

```bash
# After PR CI checks pass (should be green now):
gh pr merge 1 --repo BOHICA-LABS/mdlinkcheck-cloud --rebase
```

Trigger: human reviews and merges PR #1.

### 2. `issues: write` permission in hardening.yml

```yaml
# Uncomment in hardening.yml permissions block:
issues: write
```

Also add the actual step that creates a GitHub Issue when a hardening job
fails (the permission without the step is inert). This is a Phase-6 concern.

Trigger: Phase-6 hardening is being actively used and issue creation for
failed hardening runs is desired.

### 3. `.worktrees/` — per-story worktrees

After Phase-2 story decomposition, create per-story worktrees:

```bash
git worktree add .worktrees/STORY-NNN -b feature/STORY-NNN develop
```

`.worktrees/` is in `.gitignore`. Never committed.

Trigger: Phase-3 story delivery begins.

### 4. Release workflow

A dedicated `release.yml` workflow (tagged releases, binary uploads, crates.io
publish) is deferred until Phase 7. The devops-engineer creates it during the
release phase.
