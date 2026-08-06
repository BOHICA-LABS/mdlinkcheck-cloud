---
document_type: session-handoff
project: mdlinkcheck-cloud
---

# Session Handoff: mdlinkcheck-cloud

<!--
  This file accumulates RESUME SNAPSHOTS across sessions.
  Each session wrap adds a new §RESUME SNAPSHOT.
  Prior snapshots are marked SUPERSEDED but retained for audit.
  Latest: §RESUME SNAPSHOT D-045
-->

---

## §RESUME SNAPSHOT D-030 [SUPERSEDED by D-045 — retained for audit]

*Written: 2026-08-06 — session wrap via state-manager. Single-commit burst TD-VSDD-053.*

### RESUME IN ONE BREATH

mdlinkcheck-cloud is in phase-1d (adversarial spec convergence): 0 of 3 clean passes, trajectory →0→32→34→39, novelty increasing across all 3 passes; mechanical enforcement tooling is built and on open, unreviewed PR #2 (feature/spec-lint-tooling → develop, ADVISORY CI job).
Next burst is WS-1: run the full vsdd-factory pr-manager review lifecycle on PR #2 — review dispatch, finding triage, fix delegation, convergence — then merge; do NOT merge without completing that lifecycle (D-028 forbids direct unreviewed merge).
After PR #2 merges: WS-2 adversary pass 4 + consistency pass 4 (skip 7 mechanically-enforced classes; target unread semantic perimeter); WS-3 close BI-005 slug-fidelity FM-002 gap (differential proptest); WS-4 Phase 1 human gate (gated on 3 clean passes + BI-005 closed).

### HEADS

All heads verified at wrap time. Everything is pushed; nothing is local-only.

| Ref | SHA | Note |
|---|---|---|
| `origin/main` | `78a9f77` | CI workflows live (PR #1 merged by operator, 17/17 green) |
| `origin/develop` | `798dee5` | integration branch; story PRs target this |
| `feature/spec-lint-tooling` local == remote | `997ef95` | PR #2 head (f-string syntax fix pushed during this wrap) |
| `.factory` / `factory-artifacts` local == remote | this burst's SHA | single-commit wrap; see `git -C .factory log -1` |

- Main repo working tree: clean. Branch checked out: `feature/spec-lint-tooling`.
- `.factory` worktree: `sidecar-learning.md` and `logs/*.jsonl` committed in this burst.
- `git worktree list`: exactly two — repo root at `997ef95`, `.factory` at this burst's SHA.
- `.worktrees/`: empty — Phase 3 not started, no story worktrees exist.
- Multi-repo: no `.factory-project/` — single-repo project, no second artifacts branch.
- `.factory/hooks/verify-sha-currency.sh`: NOT present in this project — not run; hook verification gap (record only, not an implied pass).
- Open PRs: exactly one — PR #2 "feat: spec-integrity validator and generator tooling (Phase 1 gate)", `feature/spec-lint-tooling` → `develop`, OPEN, unreviewed, unmerged.
- `just check` / Cargo gate count: N/A — no Rust workspace exists yet (Phase 3). CI passes via `Cargo.toml`-presence no-op guards.
- Local-only commit found and pushed during wrap: `997ef95` "fix(spec-lint): fix Python 3.11 f-string syntax in gen-prd-sections.py". PR #2's remote head previously contained a broken generator; it no longer does.

### WORKSTREAMS

**WS-1 — PR #2 review + merge**

PR #2 (`feature/spec-lint-tooling` → `develop`, SHA `997ef95`) is OPEN and unreviewed. Contents: 8 validators, 4 generators, a negative-test selftest suite, `just spec-lint` / `just spec-gen` / `just spec-lint-selftest` recipes, and an ADVISORY `spec-lint` CI job. Per D-028, run the FULL `pr-manager` review lifecycle (review dispatch → finding triage → fix delegation → convergence) and only then merge. Direct unreviewed merge is FORBIDDEN.

RESUME NEXT-ACTION: Dispatch `vsdd-factory:pr-manager` on PR #2 to execute the full review lifecycle per D-028; merge only after that lifecycle completes and converges.

---

**WS-2 — Adversary pass 4 + consistency pass 4**

First test of whether mechanical enforcement bends the novelty curve. Pass 4 MUST SKIP the seven now-mechanically-enforced classes: title-sync, EC-injectivity, id-resolution, counts, holdout-boundary, ADR-consistency, index-integrity. Target the unread semantic perimeter:
- 54 BC bodies never fully read
- 24 individual VP files
- ADR-001/002/003/004/006 bodies
- 8 unread architecture shards
- `dtu-assessment.md`, `gene-transfusion-assessment.md`, `prd.md` §1, `interface-definitions.md`
- Interaction clusters: 32-thread HTTP pool × rayon scan pool × DI-001; URL dedup BC-2.10.009 × per-occurrence file:line × 429 host pausing; unbounded `Retry-After` pause per finding P3-017

Per the frozen-HEAD rule, the 0/3 clean streak must be re-counted against whatever HEAD exists when pass 4 runs. Do NOT carry any streak count across new commits.

RESUME NEXT-ACTION: After PR #2 merges to develop, dispatch `vsdd-factory:adversary` for pass 4 with the frozen HEAD of the merged develop branch, applying the skip list and semantic-perimeter focus above; simultaneously dispatch `vsdd-factory:consistency-validator` for consistency pass 4.

---

**WS-3 — Close BI-005: slug-fidelity verification gap (HIGHEST technical risk)**

A 1-based duplicate-counter bug (`setup`, `setup-2`, `setup-3` instead of `setup`, `setup-1`, `setup-2`) PASSES VP-003's Kani injectivity proof because all outputs remain distinct. That is failure mode FM-002, in the product's headline differentiator, and it would ship wrong with a green verification suite.

Required to close BI-005:
1. Differential proptest against a canonical reference oracle covering all 7 DI-012 rules
2. At least one duplicate-heading golden vector in VP-018
3. A case exercising DI-012's input definition (heading with inline code + HTML tags through to final anchor key)

RESUME NEXT-ACTION: Dispatch `vsdd-factory:architect` to design the differential proptest oracle for DI-012 slug-fidelity and update VP-018 with the required golden vectors; close BI-005 when the proptest and VP-018 update are committed and green.

---

**WS-4 — Phase 1 human approval gate**

Never yet presented. Gated on: 3 clean adversarial passes AND BI-005 closed. At approval, flip `spec-lint` CI job to a required status check per D-029 (currently ADVISORY to avoid deadlocking on the 25 expected `[filled by story-writer]` violations that are legitimately outstanding until Phase 2).

RESUME NEXT-ACTION: Present Phase 1 approval gate to human only after WS-2 achieves 3 clean passes AND WS-3 closes BI-005; on approval, execute D-029 flip via devops-engineer.

### PENDING USER-APPROVED WORK

| Decision | Approval | Status |
|----------|----------|--------|
| D-028: Agents MAY merge PRs after full pr-manager review lifecycle | Granted by operator | Not started — applies to PR #2 (WS-1) |
| D-029: Flip `spec-lint` to required status check at Phase 1 approval | Granted by operator | Not started — gated on WS-4 |

### WORKTREE INVENTORY

| Path | Branch | SHA | Status |
|------|--------|-----|--------|
| `/Users/jmagady/Dev/mdlinkcheck-cloud` (root) | `feature/spec-lint-tooling` | `997ef95` | active |
| `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory` | `factory-artifacts` | this burst | active |
| `/Users/jmagady/Dev/mdlinkcheck-cloud/.worktrees/` | — | — | empty; Phase 3 not started |

Nothing stale. Nothing removable post-merge. No Phase 3 story worktrees exist.

### DECISION DELTA

Decisions D-001 through D-029 were committed in prior bursts. This wrap adds D-030 only.

| ID | Decision | Rationale | Phase | Date |
|----|----------|-----------|-------|------|
| D-030 | Session wrap — durable RESUME SNAPSHOT D-030 committed to factory-artifacts | Zero-context resume capability; single-commit burst TD-VSDD-053; wrap triggered at end of session before context clear | phase-1d | 2026-08-06 |

### CAVEATS

a. `cycles/phase-1d/adversary-pass-3.md` stores **29 of 39 findings as stubs**; the record is incomplete. Pass 4 supersedes it entirely — do not rely on pass-3.md for finding counts or details.

b. `required_approving_review_count` is 0 on both `main` and `develop` because all agent PRs are authored by the human's own GitHub account (`drbothen`) and GitHub forbids self-approval. Review rigor lives in the pr-manager process (D-028), not in GitHub's review requirement.

c. Branch protection: 8 required status checks, strict, linear history, no force-push, `enforce_admins` true on `main`.

d. `verify-sha-currency.sh` is absent from this project — the post-push hook verification step could not be run. This is a known gap; do not assert the hook passed.

e. `L2-INDEX.md` lacks DD-027 → DI-012/DI-013 cross-reference rows. Known gap, no blocking issue assigned.

f. INC-MAP-004 (no VP directly verifies `scanner`'s `.gitignore` exclusion in isolation) is an accepted gap with recorded rationale.

---

## §RESUME SNAPSHOT D-045

*Written: 2026-08-06 — session wrap via state-manager. Single-commit burst TD-VSDD-053. Supersedes D-030.*

### RESUME IN ONE BREATH

mdlinkcheck-cloud is in phase-1d (adversarial spec convergence): 0 of 3 clean passes, trajectory →0→32→34→39→37. Adversary pass 4 found 37 findings (3C/19M/15m) and named the root cause as SPEC TOPOLOGY, not spec quality: ~15 documents hand-maintain restatements of the same facts, so every fix must be applied N times and no fixer knows N (8 of 12 audited prior fixes reached only the primary artifact). Pass 4 remediation is COMPLETE — spec-lint 7/8, only the 25 known Phase-2 placeholders fail. PR #2 merged (2290cb0). Two PRs open and unreviewed: PR #3 (spec-lint hardening) and PR #4 (macOS-only CI). D-043 macOS-only platform narrowing is applied: branch protection 8→4 contexts, NFR-002 re-targeted 10s p95, NFR-004/T13 retired, `unicode-normalization` pinned 0.1.24. **Pass 5 is deliberately DEFERRED per D-036/D-040 — do NOT run it next.** Next actions: WS-A (review/merge PR #3 + PR #4), then WS-B (BI-012 generators), THEN WS-C (pass 5).

### HEADS

All heads verified at wrap time. Everything is pushed; nothing is local-only.

| Ref | SHA | Note |
|---|---|---|
| `origin/main` | `78a9f77` | CI workflows live (PR #1 merged by operator, 17/17 green) |
| `origin/develop` | `2290cb0` | PR #2 squash-merged; integration branch; story PRs target this |
| `origin/feature/spec-lint-hardening` | `edc903f` | PR #3 head (spec-lint hardening + P4-021 fix); OPEN, unreviewed |
| `origin/chore/macos-only-ci` | `af54a65` | PR #4 head (ci.yml matrices → macos-latest); OPEN, unreviewed |
| `.factory` / `factory-artifacts` local == remote | see `git -C .factory log -1` | single-commit wrap; all pushed; nothing local-only |

- Main repo working tree: branch checked out: **`chore/macos-only-ci`** (`af54a65`, PR #4). All remote heads are pushed; nothing is local-only.
- `stash@{0}` ("pre-merge stash for PR #2") exists and is redundant with committed work. Needs an explicit user-space `git stash drop`; NOT dropped automatically.
- `.factory` worktree: all spec files, STATE.md, SESSION-HANDOFF.md, cycle files committed in this burst.
- `git worktree list`: exactly two — repo root, `.factory`.
- Multi-repo: no `.factory-project/` — single-repo project.
- `.factory/hooks/verify-sha-currency.sh`: NOT present in this project — post-push hook verification gap (record only, not an implied pass).

### WORKSTREAMS

**WS-A (do first) — PR #3 + PR #4 review lifecycles**

Both PRs open and unreviewed. Full pr-manager lifecycle per D-028, then merge at level-4 autonomy per D-031.

- PR #3 = `feature/spec-lint-hardening` → develop. Contents: vacuous-negative-test class elimination (isolated temp trees, clean-pass assertions on all 11 tests, pre-flight + post-test structural guards, POL-11 coverage line) + P4-021 fix (real bidirectional HS-INDEX↔wave-scenarios check, fence-based frontmatter scan, 64→66 BC row detection). NOTE: PR #3 still carries the 3-platform `ci.yml` because it branched before PR #4; its `Test (ubuntu-latest)` / `Test (windows-latest)` failures are NOT blocking (not required checks). A GitHub Actions infrastructure outage caused spurious failures; re-runs were triggered. A rebase onto post-PR-#4 develop is advisable but not blocking.
- PR #4 = `chore/macos-only-ci` → develop. Contents: `ci.yml` test/build matrices → `macos-latest`. Branch protection was already narrowed to 4 contexts before the workflow change (deadlock-free per D-023). All 4 required contexts verified on PR #4; `mergeable: MERGEABLE`.

RESUME NEXT-ACTION: Dispatch `vsdd-factory:pr-manager` on PR #4 first (simpler, no spec content), then PR #3 (rebase first if PR #4 has merged). Merge both per D-028/D-031.

---

**WS-B (highest leverage) — BI-012 spec-topology generators**

Blocked on PR #3 merging first (both touch `scripts/spec-lint/`). Then build:
1. `gen-bc-traceability.py`: emit each BC's Architecture Module / Key ADRs / L2 Invariants / VP rows from ARCH-INDEX + bc-module-map + invariants + VP-INDEX
2. `gen-slug-corpus.py`: emit VP-018's SLUG_CORPUS from test-vectors.md §7 (also closes BI-015)
3. A canonical-facts block (sort key, Finding/AnchorTable field names, pass count, Verdict variants) declared once with a divergence checker

Pass 4 estimates this structurally eliminates 11 of 22 MAJOR+ findings and makes the class unrepeatable.

RESUME NEXT-ACTION: After WS-A, dispatch `vsdd-factory:devops-engineer` and `vsdd-factory:architect` to build the generators; close BI-012/BI-015 when generators are green and committed.

---

**WS-C — adversary pass 5 (ONLY after WS-A and WS-B)**

Per D-040, the skip list MUST be re-derived from proven-can-fail evidence, NOT reused from pass 4. Pass 4's skip list wrongly included `check-ec-injectivity` (false-passing, hiding 13 real EC collisions). Re-freeze HEAD at post-WS-B develop. Remaining unread perimeter: 54 BC bodies, ADR bodies, interaction clusters (32-thread HTTP pool × rayon pool × DI-001; URL dedup × per-occurrence file:line × 429 pausing).

**Adversarial streak warning (BC-5.39.001 / DRIFT-ORCH-PRLEVEL-PUSH-001):** The 0/3 clean-pass streak was accumulated against HEADs that have since moved (working tree is now on `chore/macos-only-ci`, `af54a65`). Per the frozen-HEAD rule, the streak MUST be re-counted against whatever HEAD is frozen when pass 5 runs. No pre-wrap streak count may be carried forward. Do NOT treat the 0/3 counter as portable across this session boundary.

RESUME NEXT-ACTION: After WS-B complete and generators green, dispatch `vsdd-factory:adversary` for pass 5 with frozen HEAD, re-derived skip list, and semantic-perimeter focus; simultaneously dispatch `vsdd-factory:consistency-validator`.

---

**WS-D — remaining open findings**

- BI-010 (VP-025 API mismatch): architect rewrote VP-025; INC-MAP-001 RE-OPENED — closes only when Phase 3 implements it. NOT blocking Phase 1.
- BI-014 (C4-008: VP-022 `source_bc: "NFR-001"` should be NFR-008): medium priority, fix before pass 5.
- BI-015 (VP-018 SLUG_CORPUS not transcribed from §7): folded into WS-B.
- BI-017 (Phase 3 CI perf-gate must run on macos-latest): Phase 3 obligation, not Phase 1.

---

**WS-E — Phase 1 human approval gate**

Never yet presented. Gated on: 3 clean adversarial passes. On approval, flip `spec-lint` CI job to a required status check per D-029/D-032 (currently ADVISORY). Do not present until WS-C achieves 3 clean passes.

### PENDING USER-APPROVED WORK

| Decision | Approval | Status |
|----------|----------|--------|
| D-028: Agents MAY merge PRs after full pr-manager review lifecycle | Granted by operator | In force — applies to PR #3 (WS-A) and PR #4 (WS-A) |
| D-029/D-032: Flip `spec-lint` to required status check at Phase 1 approval | Granted by operator | Not started — gated on WS-E (3 clean passes) |
| D-031: Autonomy level 4 | Granted by operator | In force |
| D-038: PR #2 cycle-limit exception | Granted by operator | CLOSED (PR #2 merged) |
| D-043: macOS-only platform narrowing | Granted by operator | APPLIED — PR #4 pending review |

### WORKTREE INVENTORY

| Path | Branch | SHA | Status |
|------|--------|-----|--------|
| `/Users/jmagady/Dev/mdlinkcheck-cloud` (root) | `chore/macos-only-ci` | `af54a65` | active; PR #4 open (main working tree) |
| `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory` | `factory-artifacts` | see `git -C .factory log -1` | active |
| `/Users/jmagady/Dev/mdlinkcheck-cloud/.worktrees/` | — | — | empty; Phase 3 not started |

Nothing stale. No Phase 3 story worktrees exist. `.worktrees/` is empty because Phase 3 has not started; no story worktrees exist.

### DECISION DELTA

Decisions D-001 through D-042 were committed in prior bursts. This wrap adds D-043..D-045 (exhaustive) and D-030 (session wrap, superseded by this snapshot).

| ID | Decision | Rationale | Phase | Date |
|----|----------|-----------|-------|------|
| D-043 | Platform matrix narrowed to macOS latest ONLY. Branch-protection 8→4 contexts. NFR-002 re-targeted 10s p95 macos-latest. NFR-004 RETIRED. T13 RETIRED. D-006/ADR-006/DI-002 REMAIN IN FORCE (rationale restated on determinism grounds). `unicode-normalization` pinned 0.1.24 load-bearing. | Operator directive; CI simplified (9→5 jobs, −44%). Rationale restatement required because D-006 argued from macOS-vs-Linux divergence which partly evaporates under macOS-only matrix. | phase-1d | 2026-08-06 |
| D-044 | Platform-independent CI jobs remain on ubuntu-latest. Only Test + Build release moved to macos-latest. | macOS runners cost ~10x Linux; cargo fmt/clippy/spec-lint/GitGuardian have no OS-specific behaviour. | phase-1d | 2026-08-06 |
| D-045 | Dropping Linux/Windows removes incidental case-sensitivity/NFC safety net. VP-008/VP-009 solely load-bearing. BC-2.07.003 formal hardening priority RAISED. | Independent convergence from architect and product-owner bursts (D-042 principle). ADR-006 now MORE load-bearing on macOS-only matrix. | phase-1d | 2026-08-06 |

### CAVEATS

a. **Three of eight validators have been caught FALSE-PASSING** (`check-id-resolution`, `check-placeholders` under D-027; `check-ec-injectivity` under BI-013), and a fourth attempted to pass by suppression (D-039). Per **D-040**, treat no validator as trustworthy without a negative test proving it can fail. PR #3's structural guard makes this verifiable — orchestrator independently confirmed it.

b. **Allowlists / skip-lists / deferral sets in checkers are FORBIDDEN (D-039).** A burst previously made `check-ec-injectivity` green by whitelisting 14 real collisions while printing "all injective". Rejected. Fix the spec, never the checker.

c. `required_approving_review_count` is 0 on both branches because all PRs are authored by the operator's own account (`drbothen`) and GitHub forbids self-review. Review rigor lives in the pr-manager process (D-028), not GitHub's review state. `gh pr review --request-changes` FAILS; use `--comment`. This triggers an auto-mode laundering classifier — requires DIRECT human authorization.

d. **Never dispatch a burst onto a branch another burst may merge or delete (D-041).** This happened once: a devops burst was working on `feature/spec-lint-tooling` when pr-manager merged and deleted it. Work was recovered from the working tree + stash.

e. `.factory/hooks/verify-sha-currency.sh` does not exist in this project — the post-push SHA-currency hook verification could NOT be run during this wrap. Known gap; do not treat it as a pass.

f. `stash@{0}` ("pre-merge stash for PR #2") is redundant with committed work. Needs an explicit user-space `git stash drop`; NOT dropped automatically.

g. `prd.md` versioned changelog entries are IMMUTABLE (D-034). Do not update them to reference newer VP/EC ids.

h. **BI-007 remains open:** VP-026 is SPECIFIED but UNIMPLEMENTED (Phase 3 hasn't started). Blocks Phase 6, not Phase 1. Phase 2 MUST generate a story traced to VP-026.

i. Main repo working tree is on **`chore/macos-only-ci`** (`af54a65`, PR #4), NOT `develop`. Check out deliberately before new work. `feature/spec-lint-hardening` (`edc903f`) is PR #3's branch and also still exists.

j. **D-045 consequence:** macOS APFS is case-insensitive and NFD-storing; on a macOS-only matrix it is the only filesystem. Nothing incidentally catches a missing NFC normalization call. VP-008/VP-009 are the sole gatekeepers. Phase 6 formal hardening of BC-2.07.003 is RAISED in priority.
