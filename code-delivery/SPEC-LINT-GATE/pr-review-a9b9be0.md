# PR #3 Review — `fix(spec-lint): eliminate vacuous-test defect class + P4-021 fixes`

**Recommendation: no blocking findings — ready to merge from this reviewer's perspective**
**Reviewed SHA:** `a9b9be04655fe71ad72b429b89903bf2676095fb`
**Diff:** 3 files, +755 / −213

> Submitted in COMMENT state. GitHub rejected an APPROVE-state review with
> `Review Can not approve your own pull request`, because the only credential
> available to me belongs to the PR author's account. This review therefore
> carries **no formal approval**. A GitHub approval, if the branch protection
> rules require one, must come from a different account.

All five previously-blocking findings (B-1 … B-5) are verified fixed by direct
execution, not by reading the diff alone. No new blocking issues. Nine
non-blocking findings follow.

---

## What I verified (not rubber-stamped)

| # | Verification | Result |
|---|---|---|
| 1 | `bash scripts/spec-lint/selftest/run-selftests.sh` | `Selftest passed: 15/15` (exit 0) |
| 2 | All 8 checkers on the live spec tree | 7 pass; `check-placeholders` fails (pre-existing — see F-9) |
| 3 | HS checks non-vacuous on live tree | 7 HS entries parsed, 7 wave-scenario files, 0 MALFORMED sentinels |
| 4 | Mutation test: forced `check-index-integrity` to always exit 0 | tests 8, 10, 10b, 10c, 10d **all failed** → none of them are vacuous |
| 5 | **B-4** — test 10c defect injection | Emits exactly **1** violation: `duplicate HS-INDEX entry 'HS-001'`. No EC-157 file in the fixture. Over-determination gone. |
| 6 | **B-5** — test 10d defect injection | Emits exactly **1** violation: `HS entry 'HS-002' has a malformed or unrecognized EC cell`. Well-determined. |
| 7 | Guard 2 fires | Injecting `KNOWN_COLLISIONS = frozenset()` → `STRUCTURAL GUARD FAILED`, exit 2 |
| 8 | D-039 sweep beyond guard keywords | One pre-existing skip-list found (`EXCLUDE_PATHS`) — adjudicated in F-3; **no allowlist introduced by this diff** |
| 9 | B-1 `get_l2_index_sections()` | Old and new agree on the live tree; closing frontmatter fence is at line 58 of 163 — the old `lineno < 60` heuristic was **3 lines** from silently breaking. Real fix. |

Commit quality: all 5 commits use conventional format with the fix ID
(`B-1 B-2`, `B-3`, `B-4 B-5`). Clear and traceable. No unrelated changes in the
diff — all three files serve this story.

---

## Findings

### F-1 [SUGGESTION] Reverse HS check silently ignores non-conforming scenario filenames

`check-index-integrity.py:163-172` — `get_actual_wave_scenario_ec_ids()` drops any
file that fails `^(EC-\d+)`. A scenario file dropped into `wave-scenarios/` with a
name like `holdout-for-connection-reset.md` is invisible to the reverse check.

Verified:

```
unindexed file, non-EC name (holdout-for-connection-reset.md)  -> rc=0  NOT DETECTED
unindexed file, EC- name    (EC-998-orphan.md)                  -> rc=1  DETECTED
```

This is the same silent-skip shape as the P4-021 dead stub this PR removes.
**Suggestion:** emit a violation for any `*.md` in `wave-scenarios/` that does not
match the `EC-NNN-*` convention, rather than skipping it. Needs a negative test
per D-040.

### F-2 [SUGGESTION] HS→EC mapping is not checked for injectivity

The duplicate check covers HS IDs only. Two distinct HS entries pointing at the
same EC, or two scenario files for the same EC, both pass:

```
| HS-001 | EC-156 |  +  | HS-009 | EC-156 |           -> rc=0  NOT DETECTED
EC-156-selftest-scenario.md + EC-156-duplicate.md     -> rc=0  NOT DETECTED
```

The docstring and PR body describe the relation as "bidirectional", but it is not
verified to be a bijection. **Suggestion:** add a duplicate-EC check plus a
matching negative test (10e).

### F-3 [SUGGESTION] Guard 2 is a name denylist, evadable by renaming — and one live skip-list already evades it

Verified both directions:

```
KNOWN_COLLISIONS = frozenset()   -> guard 2 FIRES
IGNORED_EC_IDS   = frozenset()   -> guard 2 does NOT fire (identical construct)
```

`check-placeholders.py:83` already contains a hardcoded per-file skip-list that
passes both guards:

```python
EXCLUDE_PATHS = {
    str(REPO / ".factory" / "policies.yaml"),
    str(SPECS / "prd.md"),  # prd.md may mention the policy but not have BC-level placeholders
}
```

I checked what it actually suppresses before judging severity: 7 placeholder hits
in `.factory/specs/prd.md` (lines 506, 633 ×3, 639 ×3) — **all 7 are
changelog-narrative false positives** sitting under `### v1.9 —` and `### v1.4 —`
headings, describing placeholders that were *removed*. So no real defect is hidden
today and D-039 holds in substance. This file is also untouched by this diff.

Two consequences worth acting on:

1. The PR body's claim that guard 2 "verifies no checker contains a hardcoded
   suppression allowlist, skip-list, or deferral set" is stronger than what the
   guard delivers. Either broaden the pattern (`EXCLUDE`, `IGNORE`, `EXEMPT`,
   `WAIV`, `GRANDFATHER`, `EXPECTED_FAIL`) or soften the claim.
2. `prd.md`'s blanket exclusion is broader than needed. The precise mechanism
   already exists — `is_historical_changelog_line()` — but it misses these lines
   because it requires a double-quote pair **and** `v\d+\.\d+` on the *same* line,
   while these use backticks with the version in a preceding heading. Making that
   function section-aware would let the whole-file exclusion be deleted.

### F-4 [SUGGESTION] The selftest suite is not wired into CI

`.github/workflows/ci.yml:211-266` runs all 8 checkers but never invokes
`scripts/spec-lint/selftest/run-selftests.sh`. Only `justfile:229` does. The entire
structural guarantee this PR delivers — vacuous-test impossibility, plus the two
D-039/D-040 pre-flight guards — is human-invoked only. A future PR could
reintroduce a vacuous test or an allowlist and CI would stay green.

**Suggestion:** add a step to the existing `spec-lint` job (it already checks out
`factory-artifacts`, and the selftest needs no spec tree since every test builds its
own temp tree).

### F-5 [SUGGESTION] The B-1 fix has no negative test

No selftest exercises the L2-INDEX phantom-shard or unlisted-shard paths at all —
test 8's fixture has an empty `L2-INDEX.md` and zero `domain-spec/` files. And the
live tree cannot distinguish correct from broken behavior here, because the old
`lineno < 60` heuristic and the new frontmatter-fence slicing agree on the current
file (fence at line 58 of 163). So the bug B-1 fixed is real but now unguarded: a
regression in `get_l2_index_sections()` would be caught by nothing.

**Suggestion:** add a test with a populated L2-INDEX whose frontmatter exceeds 60
lines (locking in the specific regression) plus a phantom shard entry.

### F-6 [NIT] MALFORMED sentinel can overwrite a valid mapping

`check-index-integrity.py:157-159` — a later malformed row for an HS ID that already
has a valid mapping does `mapping[hs_id] = "MALFORMED"`, dropping the good EC ID.
That can cascade into a spurious `wave-scenarios file for 'EC-NNN' has no
corresponding HS-INDEX entry`. Nothing is missed (the duplicate-ID check also
fires), but the extra violation misleads. Consider `setdefault`, or tracking
malformed rows in a separate list instead of in-band.

### F-7 [NIT] PR description is stale

- Body says "All 11 selftest cases" and the test plan expects `11/11`; the suite is
  now 15 (`EXPECTED_TEST_COUNT=15`, actual output `15/15`).
- The checker-coverage table omits tests 10, 10b, 10c, 10d.
- Body states `check-ec-injectivity` "is expected to fail on the real tree" with 2
  collisions (EC-087e, EC-087f). On the current tree it **passes**:
  `205 EC IDs validated — all injective`. The spec was evidently fixed after the
  body was written.

### F-8 [NIT] Diff size above threshold — justified

968 changed lines vs. the 500-line flag. ~840 are the mechanical
clean-pass/defect-inject scaffold repeated per test. No action needed; noting for
the record.

### F-9 [NOT ATTRIBUTABLE] `check-placeholders` fails on the live tree

`check-placeholders` exits 1 (25 occurrences, 133 files). `check-placeholders.py` is
byte-identical on `develop`, so this is pre-existing and outside this PR's scope.
Flagging it because it means the CI `spec-lint` job will fail on this branch for
reasons unrelated to the diff — do not read a red `spec-lint` as a signal about
this PR.

---

## Note on demo evidence

There is no `docs/demo-evidence/` directory anywhere in this repo, so there is no
established convention this PR is departing from. This change delivers Python/shell
lint tooling whose only observable surface is exit codes and stdout; a screen
recording would carry strictly less information than a transcript. Rather than
treat the absence as blocking, I executed the suites myself and reproduced every
claim independently — that evidence is in the table above. Recording this as a
deliberate judgment call, not an oversight.

## Note on CI evidence

PR #3 has no workflow check results (only GitGuardian, which passed). All test
evidence in this review comes from local execution at
`a9b9be04655fe71ad72b429b89903bf2676095fb`.

---

**No blocking findings.** B-1 through B-5 are genuinely fixed — B-4 and B-5
confirmed by observing that each defect injection now yields exactly one,
correctly-targeted violation. The nine findings above are all follow-up work, not
merge blockers.
