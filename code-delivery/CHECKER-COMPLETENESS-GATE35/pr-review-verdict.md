# Formal Review — CHECKER-COMPLETENESS-GATE35

**VERDICT: REQUEST_CHANGES** (2 blocking findings, both inside the newly-added
`scripts/verify-evidence-figures.py`; zero source change required in `scripts/spec-lint/`)
**covered_sha:** `f6dfa582b3911ddce155921043efec0c429578d3`
**base:** `develop` @ `da86271`
**cycle:** 6
**reviewed:** 2026-08-09

> Submitted as a `COMMENT` (via `gh pr comment`), not a `gh pr review` event: the authenticated
> identity (`drbothen`) is this PR's author and GitHub structurally rejects
> `APPROVE`/`REQUEST_CHANGES` on one's own PR (BI-039 / D-021 / D-105). Treat the verdict above as
> REQUEST_CHANGES for gating purposes.
>
> Full findings detail: `pr-review-cycle6.md` (identical content in `pr-review.md`).

## Finding adjudication

| Finding | Verdict | Primary evidence |
|---|---|---|
| C1-BLOCKING-1 — vacuous EI-4 skip assertion | **RESOLVED** | `scripts/spec-lint/` subtree hash identical across `72db558`/`39efec2`/`f6dfa58` (`25077be8…`); suite 99/99 at head |
| C1-BLOCKING-2 — `"link"` in `_COMPARABLE_KEYWORDS` | **RESOLVED** | live run at head: 174 compared / 42 divergent / 22 adjudication |
| C2-BLOCKING-1 — reconciliation was a tautology | **RESOLVED** | ledger `population=8, examined=6, skipped=2` at head; mutation proof reproduced in cycles 4-5 on identical source |
| C2-BLOCKING-2 — ADR reason codes double-reported | **RESOLVED** | unchanged source; `check_adr()` byte-identical to base |
| C2-BLOCKING-3 / BLOCKING-A — stale PR body + evidence | **RESOLVED** (cycle 5) | all eight enumerated defects fixed |
| C2-NIT-1, C2-NIT-2 | **RESOLVED** (cycle 4) | unchanged source |
| **BLOCKING-B** — body misdescribed the detection set | **RESOLVED** | enumeration now lists 6 sites incl. `BC-2.11.004.md:61`; `:23` correctly placed in the excluded bucket with `skipped=2` → population 8; matches live run |
| **BLOCKING-C** — false capture-provenance stamps | **RESOLVED** | stamps now `b4bbbc3`; falsification-tested by running the `b4bbbc3` spec-lint tree — AC-005 and AC-006 reproduce **exactly**, unlike `fd74bd7` which yields 79 vs the recorded 78 |
| SUGGESTION-2 / -3 / -4, NIT-D (cycle 5) | **RESOLVED** | `E-CLI-001` → `BC-2.11.004.md:61`; heading `99/99`; `99of99`; field relabelled `**Captured at SHA:**` |
| **BLOCKING-D** — verifier reports PASS when live output is unparseable | **NEW — blocking** | Checks 2/3/4 (lines 61, 72, 88) and Check 6's completeness arm (line 136) are guarded by bare `if match:` with no `else: fail(...)`. Proven: with adr+ec summaries unparseable the verifier printed `PASS — all figure checks match live output`, exit 0 |
| **BLOCKING-E** — provenance check weaker than the finding it closes | **NEW — blocking** | Check 7 accepts any SHA in the file's git log. AC-005's accepted set includes `879efff`, where the file read `79 reason-code + 5 E-class`. Proven: restamping AC-005 to `879efff` → `PASS` |

## Suggestions / nits

- **SUGGESTION-5** — Checks 2/4 use `re.search`, validating only the *first* restatement of each
  figure. Proven: corrupting the third occurrence (line 223, AC-5 row) to `79 … + 5 …` still passed.
  Use `re.finditer` and assert every occurrence.
- **SUGGESTION-6** — the verifier is invoked nowhere (`grep -rl` matches only itself; `ci.yml`'s
  `spec-lint` job iterates `scripts/spec-lint/${check}.py`). A manual-only script cannot prevent the
  drift it was built to prevent.
- **SUGGESTION-7** — rollback lists 9 commits and claims "all 9", but the branch has **10**;
  `f6dfa58` is omitted, and since it *adds* `scripts/verify-evidence-figures.py` the documented
  revert leaves an orphaned source file. Third consecutive cycle the rollback is wrong; the verifier
  deliberately exempts this (lines 193-195).
- **NIT-E** — `evidence-report.md:12` credits AC-001 with "99/99 selftests"; AC-001 is a truncated
  preflight capture containing no selftest total. Figure is true and evidenced in AC-002.
- Cycle-4 **NIT-A** and **NIT-B** remain open, both non-blocking.

## Verifier: what it does well

Expected values are genuinely derived from live runs and git state, never from the document under
check — the `x == x` trap is avoided. Positive control passed: reintroducing BLOCKING-B fired both
`enumerated-sites/count` and `enumerated-sites/completeness` with precise messages. The
bucket-overlap check (lines 144-151) structurally prevents the "validated *and* excluded"
contradiction. Checks 1 and 6 correctly fail on absent patterns. The `pop=` relaxation (line 77)
**did not** create a hole: only one ledger triple exists in the body, it matches live, and the
`population == examined + skipped` invariant is computed purely from live output.

## Corrections to the handoff report

- **`.factory/` *is* gitignored** — `git check-ignore -v .factory` → `.gitignore:1:.factory/`. It is
  both an ignore entry and a worktree on `factory-artifacts` (mounted at `c8b37bc`). The
  implementer's premise was not wrong; claims resting on it need no extra suspicion. Either
  mechanism suffices — `git diff --name-only da86271 f6dfa58 -- .factory/` is empty.
- **Frozen perimeter confirmed directly** (unresolvable last cycle): `factory-artifacts` `specs` tree
  = `ace1745871122cd1fa2c46cf27c5493cc1083411`, matching the claim exactly.

## Verified correct at `f6dfa58`

Selftests **99/99**. Ledger `population=8, examined=6, skipped=2`. `9 violations (78 reason-code + 6
E-class)`. ec-injectivity `174 / 42 / 22`. All four required CI checks SUCCESS via check-runs API at
this exact SHA; `Spec lint` FAILURE correct per D-128, widened counts intended per D-122.
`- [ ] Operator merge authorization — pending` unticked and unmodified (D-105/D-129).
`pr-description.md` matches the live PR body (one trailing newline). Working tree clean after all
probes; every mutation restored and verified.

## Bottom line

The spec-lint deliverable is clean and unchanged, and every finding from cycles 1-5 is RESOLVED —
including BLOCKING-C, whose replacement stamp survives the same falsification test that killed its
predecessor. REQUEST_CHANGES rests entirely on the new verifier: it reports PASS when it cannot parse
the live output it exists to compare against (BLOCKING-D), and its provenance test accepts stamps
naming a commit at which the content did not exist (BLOCKING-E). Both proven by execution, both a few
lines to fix, neither touching `scripts/spec-lint/`.
