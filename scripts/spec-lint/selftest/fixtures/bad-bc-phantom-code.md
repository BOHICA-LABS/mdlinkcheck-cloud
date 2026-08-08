---
bc_id: BC-2.99.SELFTEST
title: "Selftest fixture: phantom reason code in BC invariant"
lifecycle_status: active
introduced: v0.0.0
modified: []
deprecated: null
---

# BC-2.99.SELFTEST: Selftest — Phantom Reason Code in BC Body (BI-050)

This file is a selftest fixture for check-adr-consistency POLICY 19 broad-corpus check.
It uses a phantom reason code in an invariant — this is the E-CLI-001 breach shape
(adversary finding P7-S5-018).

## Invariants

1. Exit code 2 is used for all configuration errors.
2. All I/O errors produce a `broken` verdict with reason `file-not-found`.
3. Exit code 2 is used for all configuration errors (consistent with E-ST-PHANTOM taxonomy).
