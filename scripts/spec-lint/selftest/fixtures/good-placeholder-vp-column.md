---
bc_id: BC-2.01.SELFTEST
title: "Selftest fixture: legitimate em-dash and multi-VP usage"
lifecycle_status: active
introduced: v0.0.0
modified: []
deprecated: null
---

# BC-2.01.SELFTEST: Selftest — em-dash is legal in prose

Prose with an em-dash — like this one — must never be flagged.

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-001 | Something — with an em-dash in the Property column | unit test — new test required |
| VP-001, VP-018 | Multi-VP citation is legitimate | unit test |

## Unrelated Table

| # | Service | Protocol | Fidelity | DTU? | Justification |
|---|---------|----------|----------|------|---------------|
| — | None | — | — | No | Pure local input (filesystem) |

## Remediation Template (documentation, not an instance)

```markdown
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| none | [property description] | integration / acceptance test |
```
