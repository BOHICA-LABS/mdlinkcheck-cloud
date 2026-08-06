# Review Findings — D-043-MACOS-MATRIX (PR #4)

**PR:** #4 — "ci: narrow platform matrix to macOS-only (D-043)"
**Branch:** chore/macos-only-ci → develop
**Base SHA (cycle 1 start):** af54a6532811edf8d1d67a4674032fe8aa527d15
**HEAD SHA (post-fix):** 6503d3baacaa7aef2b9e6fe44f27aadb13d239ae
**Reviewers:** ci-workflow-analyzer, security-reviewer, pr-reviewer
**Max cycles:** 3 | **Cycles used:** 1
**Date:** 2026-08-06

---

## Convergence Table

| Cycle | Findings | Blocking | Fixed | Remaining | Verdict |
|-------|----------|----------|-------|-----------|---------|
| 0 (start) | 11 | 0 | — | 11 | — |
| 1 | 11 → 2 fixed | 0 | 2 | 9 deferred | APPROVE |

**Result: APPROVE after 1 cycle. Zero blocking findings across all cycles.**

---

## Cycle 1 Findings

### Fixed in commit 6503d3b

| # | Severity | Finding | File:Line | Fix |
|---|---|---|---|---|
| CI-1 | MAJOR | `persist-credentials: false` missing from 4 of 5 checkout steps | ci.yml:62,87,124,176,219 | Added to all 5 checkouts |
| CI-6 | NIT | `fail-fast: false` + `${{ matrix.os }}` on single-entry matrix (introduced by this diff) | ci.yml:117-121, 164-175 | Removed strategy block; literal `macos-latest` names |

### Deferred (pre-existing, not blocking CI-config PR)

| # | Severity | Finding | File | Status |
|---|---|---|---|---|
| CI-2 | MINOR | selftest (run-selftests.sh) not invoked in CI — D-040 gap | ci.yml spec-lint job | Follow-up PR |
| CI-3 | MINOR | Static CHECKS array — new check-*.py scripts silently skipped in CI | ci.yml:233-243 | Follow-up PR |
| CI-4 | MINOR | cargo-mutants job runs on ubuntu-latest (D-043 inconsistency) | hardening.yml | Separate PR |
| CI-5 | MINOR | chore/** absent from push.branches trigger | ci.yml:24-27 | Accepted: PR trigger sufficient |
| CI-7 | NIT | Job-level permissions inconsistency (only spec-lint has explicit block) | ci.yml+hardening.yml | Follow-up |
| SEC-1 | MAJOR | kani-verifier installed without --version pin (CWE-829) | hardening.yml:234 | Separate PR |
| SEC-2 | MAJOR | cargo-fuzz installed without --version pin (CWE-829) | hardening.yml:197 | Separate PR |
| SEC-3 | MINOR | pip install semgrep without hash verification (CWE-494) | hardening.yml:111 | Follow-up |
| SEC-4 | MINOR | Stale D-006 comment in justfile | justfile | Follow-up |

---

## Convergence Verification (Cycle 1)

### Final pr-reviewer verdict

```
READY: PR #4 has been reviewed and is approved for merge.
covered_sha: 6503d3baacaa7aef2b9e6fe44f27aadb13d239ae
```

### 7 verifications performed by pr-reviewer

1. All 4 required-context names are literal strings (no template expansion):
   - `name: Test (macos-latest)` — exact match to required context ✓
   - `name: Build release (macos-latest)` — exact match to required context ✓
   - `name: Format check` — exact match ✓
   - `name: Clippy (deny warnings)` — exact match ✓

2. persist-credentials: false present on all 5 checkout steps ✓

3. No strategy/matrix blocks in test or build-release ✓

4. D-043 matrix narrowing correct (ubuntu-latest and windows-latest removed) ✓

5. No new issues introduced by 6503d3b ✓

6. D-039: no allowlists/skip-lists anywhere in workflow ✓

7. No BLOCKING findings ✓

---

## Merge Gates Status

| Gate | Status | Notes |
|------|--------|-------|
| Security review | PASS | No CRITICAL/HIGH findings in diff |
| Review convergence | PASS | APPROVE in cycle 1 |
| CI required checks | BLOCKED | GitHub Actions outage 2026-08-06T15:22Z; GitGuardian pass via App |
| Dependency PRs | PASS | PR #2 merged 2026-08-06T15:48:59Z |
| Rebase needed | NO | Branch based on 2290cb0 (current develop HEAD) |

---

## Merge decision

**MERGE-READY: YES-pending-CI**

Merge is deferred until GitHub Actions outage clears. All non-CI gates pass.
No merge action taken per orchestrator instruction (STOP BEFORE MERGE).

When ready to merge:
1. Re-run `check-stale-verdict.sh 4 6503d3baacaa7aef2b9e6fe44f27aadb13d239ae` via github-ops
2. Confirm CI passes for 6503d3b
3. Execute via `enforce-merge-strategy.sh 4 --squash --delete-branch`
