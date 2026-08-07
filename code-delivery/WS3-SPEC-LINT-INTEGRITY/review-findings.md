# Review Findings — WS3-SPEC-LINT-INTEGRITY

**PR:** #7 `fix/ws3-spec-lint-integrity` → `develop`
**Merged:** 2026-08-07T13:27:06Z as `e1299b07` on develop
**Total review cycles:** 3
**Total blocking findings:** 5 (3 in cycle 1, 1 in cycle 2, 1 in cycle 2; all resolved)

## Convergence Table

| Cycle | Head SHA (short) | Findings | Blocking | Fixed | Remaining |
|-------|-----------------|----------|----------|-------|-----------|
| 1 | `70794e3` | 12 (3B + 5W + 4N) | 3 | 3 | 0 |
| 2 | `7e80443` | 11 (2B + 3S + 4N/NIT) | 1 (BLOCK-5); 1 invalid (BLOCK-4 stale state) | 1 | 0 |
| 3 | `791fc11` | 7 (0B + 3S + 4N) | 0 | — | 0 → APPROVE |

## Finding Inventory

### Cycle 1 (head `70794e3`)
| ID | Description | Severity | Resolution |
|----|-------------|----------|-----------|
| BLOCK-1 | `_is_valid_vp_cell` punctuation-only-cell hole (`,`/`/`-only passes as conforming — `all([])=True`) | Blocking | Fixed in `7e80443` |
| BLOCK-2 | Fenced-code `continue` placed before ALL checks, silently narrows pre-existing ID-resolution coverage (89 real refs) | Blocking | Fixed in `7e80443` |
| BLOCK-3 | BI-042 selftests 22/22b hardcode binding-25 snapshot; reverting production TOML leaves CI green | Blocking | Fixed in `7e80443` (dynamic derivation via tomllib) |
| WARN-1 | Selftest suite not in any CI job | Warning | Pre-existing, noted as follow-up |
| WARN-2 | R2-RULE covers only `VP-NNN`-headed tables; six `VP`-headed tables out of scope | Warning | Noted in PR body, follow-up |
| WARN-3 | R3-A/R3-B dedup breaks on strikethrough cells (latent) | Warning | Latent, no live occurrence |
| WARN-4 | `_SEP_CELL_RE` requires 2+ hyphens; no tilde-fence support (latent) | Warning | Latent, no live occurrence |
| WARN-5 | PR description inaccuracies (10th R3 finding mislabelled, EXPECTED_TEST_COUNT wrong, em-dash count, security checkbox) | Warning | Fixed in PR description update |

### Cycle 2 (head `7e80443`)
| ID | Description | Severity | Resolution |
|----|-------------|----------|-----------|
| BLOCK-4 | Suite 53/54 on clean clone — reviewer based on `factory-artifacts @ 17ed288` (stale) | Invalid — stale state | `origin/factory-artifacts` was already at `7e0f02a` (D-076 fix). Suite is 55/55. |
| BLOCK-5 | `` `\| , \|` `` regression guard in `bad-placeholder-vp-emdash.md` vacuous — masked by em-dash row | Blocking | Fixed in `791fc11` (separate fixture `bad-placeholder-vp-punctuation-only.md` + NV-1b test) |

### Cycle 3 (head `791fc11`)
| ID | Description | Severity | Resolution |
|----|-------------|----------|-----------|
| SUGGESTION-1 | Docstring says R3-A fires on "EC or ID" but impl is "EC" only (deliberate) | Suggestion | Follow-up |
| SUGGESTION-2 | VP-NONE sentinel branch has no selftest | Suggestion | Follow-up |
| SUGGESTION-3 | Proof Method resolved by hardcoded index [2] (latent if column is inserted) | Suggestion | Follow-up |
| SUGGESTION-4 | Selftest suite should be wired into CI | Suggestion | Follow-up |
| NIT-1 | R3-A/R3-B dedup on strikethrough (same as WARN-3) | Nit | Latent |
| NIT-2 | Fence delimiter line skipped in both checkers | Nit | Latent |
| NIT-3 | PR description says "9 EC rows" but actual is 10 (TV-BV013) | Nit | Noted |

## Security Review
One LOW finding (SEC-001: `is_historical_changelog_line` first-occurrence `find()` — lint accuracy trade-off). No CRITICAL/HIGH. Accepted per D-081 residual doctrine.
