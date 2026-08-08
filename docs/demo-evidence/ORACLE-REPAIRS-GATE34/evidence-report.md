# Demo Evidence Report — ORACLE-REPAIRS-GATE34: Spec-lint oracle repairs

**Branch:** fix/oracle-repairs-gate34
**Worktree:** `.worktrees/fix-oracle-repairs-gate34/`
**Recorded:** 2026-08-08
**Closes:** BI-047 (placeholders oracle), BI-049 (holdout-boundary oracle), BI-050 (adr-consistency oracle), BI-051 (ec-injectivity oracle)

---

## Coverage Summary

| AC | Description | Evidence File | Status |
|----|-------------|---------------|--------|
| AC-1 | Pre-flight guard: 0 unproven scope reductions / 15 checkers; 10/10 primitives | `AC-001-preflight-guard.txt` | PASS |
| AC-2 | Full selftest suite: 82/82 pass (each proves clean-pass AND defect-fail) | `AC-002-selftest-82of82.txt` | PASS |
| AC-3 | 13 new oracle-repair selftests all pass (G5, P14-15/16/17, EI-1/2/3, 7b/7c/7d, 5b/5c/5d) | `AC-003-oracle-repair-selftests.txt` | PASS |

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

## AC-2: Full Selftest Suite (82/82)

**Script:** `scripts/spec-lint/selftest/run-selftests.sh`
**Evidence:** `AC-002-selftest-82of82.txt`

```
Selftest passed: 82/82 negative tests verified (each proved clean-pass + defect-fail)
```

**Exit code: 0**
**Result: PASS**

---

## AC-3: Oracle-Repair Selftests (13 new, all PASS)

**Evidence:** `AC-003-oracle-repair-selftests.txt`

```
── guard selftest G5: broadened guard — EXCLUDE_PATHS proven vs unproven (BI-047) ──
  PASS (clean-pass confirmed; EXCLUDE_PATHS without completeness assertion correctly detected as unproven)
── selftest P14-15: live placeholder in prd.md prose must flag (D-113) ──
  PASS (clean-pass confirmed; live [filled by architect] in prd.md prose correctly flagged)
── selftest P14-16: changelog-narrative VP-TBD not flagged (D-081 P1) ──
  PASS (clean-pass confirmed; changelog-narrative VP-TBD exempt; prose VP-TBD flagged)
── selftest P14-17: backtick citation of placeholder not flagged (D-081 P2) ──
  PASS (clean-pass confirmed; backtick citation exempt; unquoted live placeholder flagged)
── selftest EI-1: BC-vs-registry divergent scenario (BI-051) ──
  PASS (clean-pass confirmed; divergent BC-vs-registry scenario correctly detected)
── selftest EI-2: genuine agreement not flagged (BI-051) ──
  PASS (clean-pass confirmed; genuine agreement not flagged; divergent correctly detected)
── selftest EI-3: borderline case in adjudication bucket (BI-051) ──
  PASS (clean-pass confirmed with adjudication; zero-overlap correctly detected as divergent)
── selftest 7b: prose-form holdout EC-079 scenario leak (BI-049) ──
  PASS (clean-pass confirmed; prose-form holdout scenario correctly detected)
── selftest 7c: table-form EC-093 regression after BI-049 repair ──
  PASS (clean-pass confirmed; table-form EC-093 correctly detected — no regression)
── selftest 7d: prd.md:630 shape must-NOT-flag (suffix predicate, CORRECTION 1) ──
  PASS (prd.md:630 shape not flagged; inverted shape correctly detected)
── selftest 5b: BC body phantom reason code (BI-050) ──
  PASS (clean-pass confirmed; BC body phantom reason code correctly detected)
── selftest 5c: test-vectors phantom reason code via verdict-paren (BI-050) ──
  PASS (clean-pass confirmed; test-vectors phantom reason code correctly detected)
── selftest 5d: frontmatter changelog phantom NOT flagged, body phantom IS (BI-050) ──
  PASS (clean-pass confirmed; frontmatter phantom not flagged; body phantom flagged)
```

**Result: PASS**
