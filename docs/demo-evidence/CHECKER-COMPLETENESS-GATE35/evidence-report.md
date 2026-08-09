# Demo Evidence Report — CHECKER-COMPLETENESS-GATE35

**Branch:** fix/checker-completeness-gate35
**Head SHA:** d3085d9
**Captured:** 2026-08-08
**Type:** CLI tool evidence (terminal output)

## Summary

| AC | Description | Status |
|----|-------------|--------|
| AC-1 | Pre-flight guard: 0 unproven scope reductions; 10/10 primitives; 93/93 selftests | PASS |
| AC-2 | Full selftest suite: 93/93 pass | PASS |
| AC-3 | New selftest 5k: E-IO-002 + E-CLI-001 + malformed-fragment detected as a set | PASS |
| AC-4 | New selftest EI-7: §2 Filesystem column parsed; EC-007 divergence detected | PASS |
| AC-5 | check-adr-consistency live corpus: 9 violations (79 reason-code + 5 E-class occ validated) | PASS (widened as expected) |
| AC-6 | check-ec-injectivity live corpus: 174 citations compared; 40 divergent; D-132 counts emitted | PASS (widened as expected) |

## Evidence Files

- `AC-001-preflight.txt` — pre-flight guard output (15 checkers, 0 unproven, 10/10 primitives)
- `AC-002-selftest-93of93.txt` — full selftest run confirming 93/93
- `AC-005-adr-consistency-live.txt` — live corpus run; 9 violations from 134 files
- `AC-006-ec-injectivity-live.txt` — live corpus run; 40 divergent, 11 adjudication, D-132 counts

## Key Baselines

### check-adr-consistency (BI-056 repair)
- Previous (post-gate34): 4 violations, 0 E-class detections
- After this PR: **9 violations** (79 reason-code occurrences + 5 E-class code occurrences)
- New E-class detections: E-IO-002 at BC-2.01.009.md:44,52,71,73 and interface-definitions.md:237

### check-ec-injectivity (BI-057 repair)
- Previous (post-gate34): 110 citations compared (80 skipped), 9 divergent, 5 adjudication
- After this PR: **174 citations compared** (17 legitimately-EC-less skipped), **40 divergent**, **11 adjudication**
- D-132 skip counts emitted at every granularity

## Selftest Run (93/93 confirmed)

See `AC-002-selftest-93of93.txt`. New tests in this PR:
- `selftest 5k (BI-056)`: PASS — all three phantom codes detected: E-IO-002, E-CLI-001, malformed-fragment
- `selftest EI-7`: PASS — §2-shape comparison confirmed; EC-007 divergence correctly detected
