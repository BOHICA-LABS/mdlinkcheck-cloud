---
bc_id: BC-2.01.SELFTEST-PROSE
title: "Selftest fixture: holdout boundary violation via prose"
lifecycle_status: active
introduced: v0.0.0
modified: []
deprecated: null
---

# BC-2.01.SELFTEST-PROSE: Selftest — Holdout Boundary Prose Leak (BI-049)

This file is a selftest fixture for check-holdout-boundary.
It contains a concrete scenario for EC-079 in PROSE form (not a table row).
This is the exact breach shape that previously evaded detection (P7-S8-004/P7-S8-005).

## Background

The former test was replaced by EC-079 (input: `test.md` with `[x](missing.md)` pointing to an absent target → broken) as the designated holdout scenario for this risk cluster.

This prose paragraph contains both the concrete input AND the expected output
for active reserved holdout EC-079 on a single line, and must be detected as a POL-18 violation.
