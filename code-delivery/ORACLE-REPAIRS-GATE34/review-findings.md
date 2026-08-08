# Review Findings — ORACLE-REPAIRS-GATE34

**PR:** #11 — fix/oracle-repairs-gate34
**Target:** develop
**Max cycles:** 10

## Convergence Tracking

| Cycle | SHA reviewed | Findings | Blocking | Fixed | Remaining |
|-------|-------------|----------|----------|-------|-----------|
| 1 | c4ea0f2a4daf815de1711ff34097132e484ca206 | 12 (3 blocking, 9 advisory, 5 cosmetic) | 3 | 3 | 0 blocking → Cycle 2 |
| 2 | 4c825386a6a544d4703451ab255bfa2ddd6d8c56 | 6 (2 blocking, 4 warning, 1 nit) | 2 | 2 | 0 blocking → Cycle 3 |
| 3 | 9bc2d052b16574190d8d2130b78de3850e128b88 | 4 (1 blocking, 2 warning, 1 nit) | 1 | 1 | 0 blocking → Cycle 4 |
| 4 | 7e4a8f014a2e09e59757d1e26dbc4ce6073e1770 | 5 (0 blocking, 3 warning, 2 nit) | 0 | — | APPROVE — stale at merge time (b2f55ac pushed after) |
| 5 | b2f55ac63ee9de011339d7a37c9d6545c88fc455 | 4 (0 blocking, 4 cosmetic) | 0 | — | **APPROVE** — FRESH; covered_sha matches HEAD |

## Cycle 1 — SHA c4ea0f2

**Review file:** `pr-review-c4ea0f2a4daf815de1711ff34097132e484ca206.md`
**Verdict:** REQUEST_CHANGES

### Blocking Findings (all in scripts/spec-lint/, no spec-corpus edits)

| ID | File | Description | Disposition |
|----|------|-------------|-------------|
| BLOCKING-1 | check-ec-injectivity.py | extract_tv_rows() used hard-coded column 3 regardless of TV table schema — 13/17 SCENARIO-MISMATCH were column-alignment artifacts | FIXED — commit 0002a20: schema-aware header detection, Description column lookup, non-comparable rows skipped |
| BLOCKING-2 | check-adr-consistency.py | Patterns 2+3 missing _is_spec_ref_id() discriminator — DI-010, D-018, "clean" flagged as phantom reason codes | FIXED — commit 57ad637: _is_reason_code_candidate() helper applied to all three patterns |
| BLOCKING-3 | check-adr-consistency.py | Pattern 1 keyword-in-line context guard too broad — macos-latest, Retry-After, test-sufficient, anchor slugs flagged | FIXED — commit 4c82538: positional predicate (Reason column table mode + prose trigger-phrase mode) |

### Advisory/Cosmetic Findings (deferred to post-merge)

ADVISORY-1: Three completeness assertions are tautological (same predicate for total and scan count)
ADVISORY-2: Suppression guard Pass 2 can be satisfied by a comment line (SEC-003 overlap)
ADVISORY-3: check-holdout-boundary prose predicate false-positives on mermaid --> edges
ADVISORY-4: BI-049 residual bypass has no selftest
ADVISORY-5: check-adr-consistency completeness assertion aborts on non-ADR-*.md in decisions/
ADVISORY-6: _compare_bc_to_registry consults only first TV row per EC (fixed alongside BLOCKING-1)
ADVISORY-7: Hardcoded name-keyed allowlist inline in Pattern 1/2
ADVISORY-8: check-placeholders exemption region count not reported separately
ADVISORY-9: Scope-gap exit codes inconsistent (2 vs 1) and untested
COSMETIC-1 through COSMETIC-5: minor wording/logic nits

### Post-fix Baseline (verified live)

| Checker | Before fix | After fix |
|---------|-----------|-----------|
| check-ec-injectivity | 17 DIVERGENT + 43 ADJUDICATION (mostly artifacts) | 0 divergent, 0 adjudication; 68 comparable citations, 133 non-comparable skipped |
| check-adr-consistency | 26 violations (mostly artifacts) | 4 violations (all real content defects) |
| check-holdout-boundary | 1 violation (EC-151) | unchanged |
| check-placeholders | 0 violations | unchanged |

### New Selftests Added by Fix Commits

| Test ID | What it proves |
|---------|----------------|
| EI-4 | Multi-schema TV file: non-comparable section skipped, Description section compared |
| 5e | D-018 in broken(...) NOT flagged (BLOCKING-2 guard) |
| 5f | macos-latest near "broken" keyword NOT flagged (BLOCKING-3 guard) |
| 5g | Genuine phantom code in Reason table column IS detected |

Selftest suite: 82 → 86 (4 new tests)
