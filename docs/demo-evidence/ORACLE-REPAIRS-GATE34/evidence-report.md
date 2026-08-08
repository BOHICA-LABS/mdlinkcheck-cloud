# Demo Evidence Report — ORACLE-REPAIRS-GATE34: Spec-lint oracle repairs

**Branch:** fix/oracle-repairs-gate34
**Worktree:** `.worktrees/fix-oracle-repairs-gate34/`
**Recorded:** 2026-08-08 (refreshed at head SHA 4722ca16fa512b5e060ca5034adba0014d99a63b)
**Closes:** BI-047 (placeholders oracle), BI-049 (holdout-boundary oracle), BI-050 (adr-consistency oracle), BI-051 (ec-injectivity oracle)

---

## Coverage Summary

| AC | Description | Evidence File | Status |
|----|-------------|---------------|--------|
| AC-1 | Pre-flight guard: 0 unproven scope reductions / 15 checkers; 10/10 primitives | `AC-001-preflight-guard.txt` | PASS |
| AC-2 | Full selftest suite: **91/91** pass (each proves clean-pass AND defect-fail) | `AC-002-selftest-91of91.txt` | PASS |
| AC-3 | 21 new oracle-repair selftests all pass (G5, P14-15/16/17, EI-1/2/3/4/5/6, 7b/7c/7d, 5b/5c/5d/5e/5f/5g/5h/5i/5j) | `AC-003-oracle-repair-selftests.txt` | PASS |

---

## AC-1: Pre-flight Guard (0 unproven scope reductions, 10/10 primitives)

**Script:** `scripts/spec-lint/selftest/run-selftests.sh`
**Evidence:** `AC-001-preflight-guard.txt`

```
Pre-flight structural guard: checking SPEC_LINT_REPO_OVERRIDE in all checkers...
Pre-flight guard passed: 15 checkers/generators support SPEC_LINT_REPO_OVERRIDE

Pre-flight structural guard: checking for unproven scope-reducing constructs in all checkers...
Pre-flight guard passed: 15 checkers/generators scanned, 0 proven scope reductions, 0 unproven

Pre-flight structural guard: running spec_lint_primitives unit tests (G3)...
  PASS: test_cm_splitlines_closed_under_discovery
  [... 9 more PASS lines ...]
10/10 primitive tests passed

Pre-flight structural guard: checking for raw .splitlines() in migrated checkers (G4)...
Pre-flight guard passed: 15 files checked, 0 raw .splitlines() uses
```

**Result: PASS**

---

## AC-2: Full Selftest Suite (91/91)

**Script:** `scripts/spec-lint/selftest/run-selftests.sh`
**Evidence:** `AC-002-selftest-91of91.txt`

```
Selftest passed: 91/91 negative tests verified (each proved clean-pass + defect-fail)
```

**Exit code: 0**
**Result: PASS**

---

## AC-3: Oracle-Repair Selftests (21 new, all PASS)

**Evidence:** `AC-003-oracle-repair-selftests.txt`

New selftests added by this PR (21 total, delivered across 4 review cycles):

| Test | Checker | What it proves |
|------|---------|----------------|
| G5 | guard | EXCLUDE_PATHS proven vs unproven (PATH_SHAPE_PATTERN) |
| P14-15 | check-placeholders | Live `[filled by architect]` in prd.md prose flags |
| P14-16 | check-placeholders | Changelog-narrative VP-TBD NOT flagged (D-081 P1) |
| P14-17 | check-placeholders | Backtick citation NOT flagged (D-081 P2) |
| EI-1 | check-ec-injectivity | BC-vs-registry divergent scenario detected |
| EI-2 | check-ec-injectivity | Genuine agreement not flagged |
| EI-3 | check-ec-injectivity | Borderline adjudication bucket |
| EI-4 | check-ec-injectivity | Multi-schema TV: Input column rows ARE compared |
| EI-5 | check-ec-injectivity | Input column scenario rows correctly compared |
| EI-6 | check-ec-injectivity | Source MD File column correctly skipped |
| 7b | check-holdout-boundary | Prose-form holdout EC-079 scenario leak detected |
| 7c | check-holdout-boundary | Table-form EC-093 regression: no regression |
| 7d | check-holdout-boundary | prd.md:630 shape must-NOT-flag (suffix predicate) |
| 5b | check-adr-consistency | BC body phantom reason code detected |
| 5c | check-adr-consistency | test-vectors phantom via verdict-paren detected |
| 5d | check-adr-consistency | Frontmatter changelog phantom NOT flagged; body phantom IS |
| 5e | check-adr-consistency | D-018 spec-ref in broken(...) NOT flagged |
| 5f | check-adr-consistency | macos-latest near "broken" NOT flagged |
| 5g | check-adr-consistency | Genuine phantom in Reason column detected |
| 5h | check-adr-consistency | Uppercase `E-IO-002` in Reason column detected |
| 5i | check-adr-consistency | Annotated cell `` `phantom-gamma` (per D-018) `` detected |
| 5j | check-adr-consistency | Phantom on same row as bare "reason" data cell detected |

**Result: PASS — all 21 new tests pass with non-vacuous clean and defect arms**
