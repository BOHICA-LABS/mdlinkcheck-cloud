# Demo Evidence Report — VERIFIER-HARDENING-SWEEP-STEP0

**Branch:** fix/verifier-hardening-sweep-step0
**Captured at SHA:** 01fc328
**Captured:** 2026-08-09
**Type:** CLI tool evidence (terminal output)

## Summary

| AC | Description | Status |
|----|-------------|--------|
| AC-1 | Pre-flight guard: 0 unproven scope reductions; 10/10 primitives | PASS |
| AC-2 | Nine-checker selftest suite: 99/99 pass | PASS |
| AC-5 | check-adr-consistency live corpus: 9 violations (79 reason-code + 6 E-class code occ) | PASS |
| AC-6 | check-ec-injectivity live corpus: 174 citations compared; 42 divergent; 22 adjudication | PASS |
| AC-7 | VEF selftest suite: 52/52 pass (each proved clean-pass + defect-fail) | PASS |

## Evidence Files

- `AC-001-preflight.txt` — pre-flight guard output (15 checkers, 0 unproven, 10/10 primitives)
- `AC-002-selftest-99of99.txt` — nine-checker selftest run confirming 99/99
- `AC-005-adr-consistency-live.txt` — live corpus run; 9 violations from 134 files
- `AC-006-ec-injectivity-live.txt` — live corpus run; 42 divergent, 22 adjudication
- `AC-007-vef-selftest.txt` — VEF selftest suite confirming 52/52 pass

## Key Baselines

### check-adr-consistency

- Previous (post-gate34): 4 violations, 0 E-class detections
- After this PR: **9 violations** (79 reason-code occurrences + 6 E-class code occurrences)
- 79 reason-code occurrences + 6 E-class code occ confirmed (figures unchanged; verifier updated)
- E-class population: population=8, examined=6, skipped=2 (frontmatter, D-081)
- See AC-005. population=8, examined=6, skipped=2

### check-ec-injectivity

- Previous (post-gate34): 110 citations compared (80 skipped), 9 divergent, 5 adjudication
- After this PR: **174 citations compared** (17 legitimately-EC-less skipped), **42 divergent**, **22 adjudication**
- 174 citations compared (17 skipped), 42 divergent, 22 adjudication
- 174 citations compared; 42 divergent
- 42 divergent, 22 adjudication

## Selftest Run (99/99 confirmed)

See `AC-002-selftest-99of99.txt`.

## VEF Selftest Evidence

VEF selftest suite (`scripts/tests/test-vef.py`): 52/52 pass.
Each test proved DEFECT PRESENT (verifier exits non-zero) and DEFECT ABSENT (verifier exits 0).
Covers T01-T50 including B-1 residual (T22-T24), B-3 structural (T25-T26), B2-4 (T30),
S2-1 check7-provenance with throwaway git repo (T31), B2-3 novel-spelling suppression
shapes (T33-T48: P-A/A2/B/C/C2/D probes plus L-65 relocated variants — T38 split into
T38a/T38b, T44 split into T44a/T44b for single-metric isolation), B2-3 option-1
column-filter structural assertions (T45-T46), B2-3 declaration-channel-deleted
probes confirming unconditional failure on ADR and EI sides (T47-T48), M-2 Case-G
ev-side positive-pinning probe (T49), and M-2 Case-G PR-side positive-pinning probe
confirming wrong-figure-hidden-in-stripped-PR-cell is detected (T50).

See `AC-007-vef-selftest.txt`.
