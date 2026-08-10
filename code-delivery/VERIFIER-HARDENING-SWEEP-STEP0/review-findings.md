# Review Findings — VERIFIER-HARDENING-SWEEP-STEP0 (PR #13)

**PR:** #13 — `feat(GATE42-step0): harden verify-evidence-figures.py before nine-checker sweep`
**Branch:** `fix/verifier-hardening-sweep-step0`
**Final packaged HEAD:** `eae146a1536fd093aa74bfb28cc9b29903728d58`
**Status:** Packaging complete. Merge pending operator authorization (D-120).

---

## Convergence Tracking

| Cycle | Findings | Blocking | Fixed | Remaining |
|-------|----------|----------|-------|-----------|
| 1 | 12 (B-1..B-5, S-4, S-5, S-7, S-8, NIT-A, NIT-B, NIT-C) | 5 | 12 | 0 |
| 2 | 11 (B2-1..B2-5, S2-1..S2-5, N2-1, N2-2) | 5 | 11 | 0 |
| Packaging | B2-5, D-208 | 2 | 2 | 0 → PACKAGED |

All blocking findings from cycle-1 and cycle-2 resolved. A fresh cycle-3 review is required before merge (no READY verdict with `covered_sha` exists for head `eae146a`).

---

## Cycle-1 Findings Summary

| ID | Severity | Finding | Resolution |
|----|----------|---------|-----------|
| B-1 | blocking | Novel-spelling scan inverted (context-word key not live figure) | Fixed: `context-word key`; T22-T24 prove detection |
| B-2 | blocking | `headRefOid` guard missing | Fixed: REFUSED on stale head mismatch |
| B-3 | blocking | Structural separation: `anchor_check` was registering keys | Fixed: entry guard vs comparison registration; T25-T26 prove |
| B-4 | blocking | Hardcoded SHA `39efec2` in check7/check9 | Fixed: `git rev-list develop..HEAD` set comparison; T19-T21 prove |
| B-5 | blocking | Advisory CI step always skipped | Fixed (cycle-1 partial): step now runs; full fix in B2-1 |
| S-4..NIT-C | suggestion/nit | Various | Resolved in this PR |

## Cycle-2 Findings Summary

| ID | Severity | Finding | Resolution |
|----|----------|---------|-----------|
| B2-1 | blocking (high) | CI wiring: exit-code conflation; step ran but verified nothing | Fixed: exit-code split (2/3/4), GH_TOKEN, real-head checkout; T27-T28 |
| B2-2 | blocking (high-mid) | `check2a-e-cli-001` registered without comparing | Fixed: failure if E-CLI-001 absent from PR; T29 proves detection |
| B2-3 | blocking (mid-high) | Novel-spelling suppression: proximity-bound exemption, ADR scan line-granular | Fixed: PREV_LABEL column filter on PR; declaration channel deleted; T33-T48 |
| B2-4 | blocking (mid) | `evidence-report.md` `**Captured at SHA:**` pointed at wrong commit | Fixed: check9 requires SHA = stamp SHA from check7; T30 proves |
| B2-5 | blocking (low) | Risk Assessment claimed "no CI workflow changes" — false | Fixed: this packaging step |
| S2-1 | suggestion | `check7-provenance-stamps` unregistered, zero coverage | Fixed: AC-002/AC-007 added to STAMPED; T31 covers check7 |
| S2-2 | suggestion | 48/48 VEF count not derived from live run | Recorded, not fixed (GOOD ENOUGH — not a live figure check) |
| S2-3 | suggestion | `test-vef.py` not run by CI | Fixed: CI step added (B2-1) |
| S2-4 | suggestion | AC-002 was 3-line hand-trimmed excerpt | Resolved: full run in AC-002 |
| S2-5 | suggestion | `anchor_check` unused `key` parameter | Recorded, not fixed (GOOD ENOUGH) |
| N2-1 | nit | Diff size >500 lines | Noted; justified by 824-line test file |
| N2-2 | nit | Suite exits 0 printing PASS with 2 loud-skips | Fixed: exit-5 PARTIAL on auth-skip |

## Packaging Step Findings (D-208, B2-5)

| ID | Type | Finding | Resolution |
|----|------|---------|-----------|
| B2-5 | blocking (description) | Risk Assessment: "no CI workflow changes" — false; ci.yml omitted from Systems affected | Fixed in pr-description.md: ci.yml listed; accurate description of advisory job |
| D-208 | MUST-FIX | `check2a-e-cli-001` found E-CLI-001 in live ADR output but PR description had no mention | Fixed in pr-description.md: "Live-detected E-class code: E-CLI-001" added |
| stamp-fix | packaging | Provenance stamps pointed at 7e9cc16 where AC files had `Captured at: PENDING` (not stripped by normalizer) | Fixed: re-stamped all 5 AC files + evidence-report.md to ebb1a78 |
| stale-count | packaging | evidence-report.md AC-007 description said "32/32" (stale) | Fixed: 32/32 → 48/48 |

---

## Branch Deletion Status

Merge has not occurred (D-120 operator gate). Remote branch `fix/verifier-hardening-sweep-step0` remains. Branch deletion will execute at operator-authorized merge.

---

## Pre-Merge Gates Summary

| Gate | Status | Note |
|------|--------|------|
| Security review | PASS | No findings; read-only verifier |
| Review convergence | PACKAGED | All cycle-2 blocking findings resolved; cycle-3 review required before merge |
| CI checks | PENDING | Will run on pushed head `eae146a` |
| Dependency PRs | PASS | GATE35 merged |
| Stale-verdict check | BLOCKED | No cycle-3 READY verdict with `covered_sha` for current head |
| End-to-end verifier | PASS (exit 0) | `PASS — all figure checks match live output and git state` |
