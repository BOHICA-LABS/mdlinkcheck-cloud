# Demo Evidence Report — CHECKER-COMPLETENESS-GATE35

**Branch:** fix/checker-completeness-gate35
**Head SHA:** b4bbbc3
**Captured:** 2026-08-08
**Type:** CLI tool evidence (terminal output)

## Summary

| AC | Description | Status |
|----|-------------|--------|
| AC-1 | Pre-flight guard: 0 unproven scope reductions; 10/10 primitives; 98/98 selftests | PASS |
| AC-2 | Full selftest suite: 98/98 pass | PASS |
| AC-3 | New selftest 5k: E-IO-002 + E-CLI-001 + malformed-fragment detected as a set | PASS |
| AC-4 | New selftest EI-7: §2 Filesystem column parsed; EC-007 divergence detected | PASS |
| AC-5 | check-adr-consistency live corpus: 9 violations (78 reason-code + 6 E-class occ; ADR gap disclosed) | PASS (widened as expected) |
| AC-6 | check-ec-injectivity live corpus: 174 citations compared; 42 divergent; D-132 counts emitted | PASS (widened as expected) |
| AC-7 | E-class population gate: unmutated passes (pop=8, examined=6, skipped=2); table-line mutant fires (pop=8 != 3+2, exit 2) | PASS |

## Evidence Files

- `AC-001-preflight.txt` — pre-flight guard output (15 checkers, 0 unproven, 10/10 primitives)
- `AC-002-selftest-98of98.txt` — full selftest run confirming 98/98
- `AC-005-adr-consistency-live.txt` — live corpus run; 9 violations from 134 files
- `AC-006-ec-injectivity-live.txt` — live corpus run; 42 divergent, 22 adjudication, D-132 counts
- `AC-007-eclass-population-gate.txt` — population gate PASS (unmutated) and FAIL (table-line mutant)

## Key Baselines

### check-adr-consistency (BI-056 repair + cycle-2 fixes)
- Previous (post-gate34): 4 violations, 0 E-class detections
- After this PR: **9 violations** (78 reason-code occurrences + 6 E-class code occurrences)
- New E-class detections: E-IO-002 at BC-2.01.009.md:44,52,71,73 and interface-definitions.md:237; E-CLI-001 at BC-2.11.004.md:61
- ADR reason-code gap disclosed: 0 occurrences counted from ADR path (8 ADR files; Patterns 1-3 not applied; check_adr() handles violations)
- E-class population: population=8, examined=6, skipped=2 (frontmatter, D-081)

### check-ec-injectivity (BI-057 repair)
- Previous (post-gate34): 110 citations compared (80 skipped), 9 divergent, 5 adjudication
- After this PR: **174 citations compared** (17 legitimately-EC-less skipped), **42 divergent**, **22 adjudication**
- D-132 skip counts emitted at every granularity

## Selftest Run (98/98 confirmed)

See `AC-002-selftest-98of98.txt`. New and modified tests in this PR:
- `selftest 5k (BI-056)`: PASS — all three phantom codes detected: E-IO-002, E-CLI-001, malformed-fragment
- `selftest 5l (AC-3+AC-2)`: PASS — E-class code in ADR TABLE CELL detected (updated fixture kills table-line mutant)
- `selftest 5m (AC-1)`: PASS — frontmatter E-class code disclosed as named skip (skipped=1)
- `selftest 5n (AC-7)`: PASS — E-class code in taxonomy-ref context routed to Pattern 4
- `selftest 5o (BLOCKING-1)`: PASS — E-VERBOSE-001 triggers population gate → exit 2 (gate mutation-verified)
- `selftest 5p (BLOCKING-2)`: PASS — one ADR reason-code defect yields exactly 1 violation (no double-count)
- `selftest EI-7`: PASS — §2-shape comparison confirmed; EC-007 divergence correctly detected

## Cycle-2 Blocking Fix Proofs

### BLOCKING-1: Table-line mutant fires the population gate
Gate: `population=8 != examined=3 + skipped=2` → exit 2 (see AC-007).
Previously the tautology `assert x == x` closed at `5 = 3 + 2`, exit 0, all 4 new tests PASS.

### BLOCKING-2: One ADR reason-code defect → exactly one violation
Test 5p: phantom-zeta in ADR Reason column → `grep -c "not in closed taxonomy"` = 1.
Previously: check_adr() + check_broad_corpus() both fired → count = 2.

### BLOCKING-3: Evidence refresh
Stale: evidence-report.md referenced d3085d9, AC-002 said 93/93, AC-005 had no population line.
Fixed: all AC files recaptured at b4bbbc3; AC-002 renamed to 98of98; AC-007 added with gate proof.
