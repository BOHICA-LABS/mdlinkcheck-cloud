# Review Findings — CHECKER-COMPLETENESS-GATE35

**PR:** #12 — fix/checker-completeness-gate35
**Target:** develop
**Max cycles:** 10

## Convergence Tracking

| Cycle | SHA reviewed | Findings | Blocking | Fixed | Remaining |
|-------|-------------|----------|----------|-------|-----------|
| 1 | 879efff417106c05597e4edf8d005c9136c56a67 | 15 (2 blocking, 8 warning, 5 nit) | 2 | 0 | 2 blocking → AWAITING OPERATOR |

## Cycle 1 — SHA 879efff

**Review file:** `pr-review-cycle1.md`
**Verdict:** REQUEST_CHANGES
**Reviewer method:** Independent reproduction — ran suite, ran checkers against live corpus, ran 3 targeted mutations

### Blocking Findings

| ID | File | Description | Disposition |
|----|------|-------------|-------------|
| BLOCKING-1 | `check-ec-injectivity.py` + `run-selftests.sh` | EI-4 skip assertion vacuous — `"0 TV rows skipped"` matches the relaxed `grep -q "TV rows skipped"` so EI-4 cannot distinguish 0-skip from N-skip. Mutation (`"expected exit"` → comparable) survives 93/93. | AWAITING OPERATOR — fix requires changing `check-ec-injectivity.py` output string. Routing per constraint 6. |
| BLOCKING-2 | `check-ec-injectivity.py` | Moving `"link"` to `_COMPARABLE_KEYWORDS` buys zero additional coverage (174 rows either way) while reducing finding surface by 13 lines across 11 EC IDs. No selftest pins it. Per D-122, a finding-surface reduction requires explicit calibration proof. | AWAITING OPERATOR — substantive detection change. Routing per constraint 6. |

### Warning Findings (all deferred)

| ID | File | Description | Disposition |
|----|------|-------------|-------------|
| WARNING-1 | `check-adr-consistency.py` | E-code whitelist unreachable for P2/P3 shapes (Pattern 3 claims token first) | DEFERRED — whitelist empty today; no practical impact |
| WARNING-2 | `check-adr-consistency.py` | `extract_valid_e_class_codes()` keys on `^## 1\.` which matches verdict-classes section, not E-class registry | DEFERRED — returns empty set; functional today |
| WARNING-3 | `check-ec-injectivity.py` | `total_tv_skipped_no_tv_id` never printed; no TV-extraction completeness assertion | DEFERRED — D-132 partial; tracked as next-step |
| WARNING-4 | `check-ec-injectivity.py` | D-132 pairing line double-counts (58 single-occurrence ECs appear twice) | DEFERRED — output cosmetic |
| WARNING-5 | `check-ec-injectivity.py` | Change (d) hard short-circuit would block all output if `ec-registry.md` generated | DEFERRED — absent today |
| WARNING-6 | `run-selftests.sh` | Changes (c) and (d) have no selftest | DEFERRED |
| WARNING-7 | `run-selftests.sh` | 5k's E-CLI-001 assertion doesn't independently pin Pattern 3 (5d covers Pattern 3) | DEFERRED — covered elsewhere |
| WARNING-8 | `check-ec-injectivity.py` | BC-row parsing duplicated inline, cuts against BI-040 shared-primitive direction | DEFERRED — refactor item |

### NIT Findings

| ID | Description | Disposition |
|----|-------------|-------------|
| NIT-1 | `E_CLASS_CODE_RE` grammar undocumented (no primitive) | ACKNOWLEDGED |
| NIT-2 | EI-7 mutation-kill rationale inaccurate (link column catches it before filesystem) | ACKNOWLEDGED |
| NIT-3 | PR description head SHA = d3085d9, rollback snippet missing 879efff, traceability inaccurate | FIXED — PR description updated |
| NIT-4 | Diff size > 500 lines (majority demo-evidence text) | ACKNOWLEDGED |
| NIT-5 | 5j relaxed grep is sound | CONFIRMED — no action |

## CI Status (as of cycle 1 review)

| Check | Status | Notes |
|-------|--------|-------|
| Format check | **PASS** | |
| Clippy (deny warnings) | **PASS** | |
| Test (macos-latest) | **PASS** | |
| Build release (macos-latest) | **PASS** | |
| Spec lint | FAIL | Expected per D-128 (advisory-only); failure consists only of newly-visible content defects |
| GitGuardian Security Checks | PASS | |

**All 4 required checks PASS.** Spec lint failure is the intended baseline deliverable.

## Dependency Status

| Dependency | Status |
|------------|--------|
| ORACLE-REPAIRS-GATE34 | MERGED — `da86271` on `develop` |

No upstream PRs are blocking.

## Operator Decision Required

Per constraint 6 (D-105 discipline boundary), I cannot modify checker logic without operator confirmation. The PR is paused at review cycle 1 pending operator decisions:

1. **BLOCKING-1:** Authorize fix — change `"0 TV rows skipped"` → `"no TV rows skipped"` in the zero-skip branch of `check-ec-injectivity.py` and tighten EI-4 assertion to `grep -qE "[1-9][0-9]* TV rows skipped"`.

2. **BLOCKING-2:** Choose one:
   - Drop `"link"` from `_COMPARABLE_KEYWORDS` (restores 13 finding lines, 11 EC IDs regain findings; coverage unchanged at 174/190), OR
   - Keep `"link"` comparable and add a mutation-killing selftest + written calibration explaining why the 11 suppressed EC IDs are false positives rather than real divergences (per D-122 widening requirement).
