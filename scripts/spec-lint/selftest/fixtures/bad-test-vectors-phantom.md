# Selftest Test Vectors — Phantom Reason Code (BI-050)

This file simulates the `malformed-fragment` breach at test-vectors.md:432
(adversary finding P7-S8-007). It is a selftest fixture for the POLICY 19
broad-corpus check in check-adr-consistency.

## §1. Vectors

| TV-ID | EC-ID | Description | BC | Input | Exit | Expected Behavior | Notes |
|-------|-------|-------------|-----|-------|------|-------------------|-------|
| TV-ST1 | EC-ST1 | `[x](a.md##double-hash)` — malformed fragment | BC-2.08.003 | (none) | 1 | broken (phantom-reason-code) | Selftest defect fixture |
