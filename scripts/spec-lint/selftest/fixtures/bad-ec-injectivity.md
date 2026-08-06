---
bc_id: BC-2.01.SELFTEST
title: "Selftest fixture: EC verdict collision"
lifecycle_status: active
introduced: v0.0.0
modified: []
deprecated: null
---

# BC-2.01.SELFTEST: Selftest — EC Verdict Collision

This file is a selftest fixture for check-ec-injectivity.
EC-001 appears in test-vectors.md with verdict "clean". This fixture
asserts it has verdict "broken", creating a collision.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | CWD = directory with nested .md files at depth 3 | broken — INTENTIONALLY WRONG for selftest |
