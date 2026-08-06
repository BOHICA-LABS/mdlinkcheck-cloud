---
bc_id: BC-2.01.SELFTEST
title: "Selftest fixture: holdout boundary violation"
lifecycle_status: active
introduced: v0.0.0
modified: []
deprecated: null
---

# BC-2.01.SELFTEST: Selftest — Holdout Boundary Leak

This file is a selftest fixture for check-holdout-boundary.
It contains a concrete scenario for EC-079, which is a reserved holdout ID.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-079 | Concrete scenario with specific URL and expected broken verdict | broken (dns-failure) |
