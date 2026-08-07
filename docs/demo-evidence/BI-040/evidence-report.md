# Demo Evidence Report — BI-040: Shared Spec-Lint Primitive Layer

**Branch:** fix/bi-040-primitive-layer
**Worktree:** `.worktrees/bi-040-primitive-layer/`
**Recorded:** 2026-08-07
**Closes:** BI-040 (CommonMark-faithful line splitting/stripping), BI-043 (repo-root fail-closed), BI-044 (EC/VP ID grammar single source of truth)

---

## Coverage Summary

| AC | Description | Evidence File | Status |
|----|-------------|---------------|--------|
| AC-1 | Primitive unit tests: 9/9 pass | `AC-001-primitive-unit-tests.txt` | PASS |
| AC-2 | Full selftest suite: 55/55 pass | `AC-002-full-selftest-suite.txt` | PASS |
| AC-3 | Baseline finding counts: 80 + 10 | `AC-003-baseline-finding-counts.txt` | PASS |
| AC-4 | Splitlines guard: 0 raw uses in 15 files | `AC-004-splitlines-guard.txt` | PASS |

---

## AC-1: Primitive Unit Tests (9/9)

**Script:** `scripts/spec-lint/selftest/test_primitives.sh`
**Evidence:** `AC-001-primitive-unit-tests.txt`

```
  PASS: test_cm_splitlines_closed_under_discovery
  PASS: test_cm_strip_cell_closed_under_discovery
  PASS: test_is_conforming_vp_cell
  PASS: test_is_conforming_ec_cell
  PASS: test_is_conforming_ec_token
  PASS: test_split_table_cells
  PASS: test_find_repo_root_fail_closed
  PASS: test_find_repo_root_override_honored
  PASS: test_find_repo_root_hermetic

9/9 primitive tests passed
```

**Result: PASS**

---

## AC-2: Full Selftest Suite (55/55)

**Script:** `scripts/spec-lint/selftest/run-selftests.sh`
**Evidence:** `AC-002-full-selftest-suite.txt`

Key summary line from output:
```
Selftest passed: 55/55 negative tests verified (each proved clean-pass + defect-fail)
```

Pre-flight guards included in run:
- G1: SPEC_LINT_REPO_OVERRIDE presence in all 15 checkers/generators — PASS
- G2: No hardcoded suppression allowlists in all 15 files — PASS
- G3: Primitive unit tests (9/9) — PASS (embedded in run)
- G4: Raw `.splitlines()` guard — PASS (see AC-4)

**Result: PASS**

---

## AC-3: Baseline Finding Counts Preserved (D-077 baseline)

**Scripts:** `check-placeholders.py`, `check-id-resolution.py`
**Environment:** `SPEC_LINT_REPO_OVERRIDE=/Users/jmagady/Dev/mdlinkcheck-cloud`
**Evidence:** `AC-003-baseline-finding-counts.txt`

```
check-placeholders.py:
   25  [filled by ...] (POL-14/15 generalized)
   55  non-conforming VP-NNN column value '—' (POL-14)
Check FAILED: 80 placeholder occurrences found (133 files checked)

check-id-resolution.py:
Check FAILED: 10 unresolvable ID references found (134 files checked)
```

Note: These "FAILED" exits are the expected D-077 baseline. The counts 80 and 10 are
the known pre-existing findings from unfilled story-writer VP/EC slots. The primitive
layer refactor must preserve these counts exactly — any change would indicate a
behavioral regression. Both counts match the D-077 baseline.

**Result: PASS** (counts match baseline: 80 + 10)

---

## AC-4: Splitlines Guard (0 raw uses in 15 files)

**Guard:** G4 pre-flight check in `run-selftests.sh`
**Evidence:** `AC-004-splitlines-guard.txt`

```
Pre-flight structural guard: checking for raw .splitlines() in migrated checkers (G4)...
Pre-flight guard passed: 15 files checked, 0 raw .splitlines() uses
```

This guard validates BI-040's central invariant: all 15 migrated checkers/generators use
`cm_splitlines()` from `spec_lint_primitives.py` instead of raw `.splitlines()`, ensuring
CommonMark-faithful line splitting is the single implementation.

**Result: PASS**

---

## Files in This Directory

```
docs/demo-evidence/BI-040/
  AC-001-primitive-unit-tests.txt      # 9/9 primitive test output
  AC-002-full-selftest-suite.txt       # 55/55 selftest output
  AC-003-baseline-finding-counts.txt   # 80+10 baseline finding counts
  AC-004-splitlines-guard.txt          # G4 guard: 0 raw .splitlines()
  evidence-report.md                   # this file
```
