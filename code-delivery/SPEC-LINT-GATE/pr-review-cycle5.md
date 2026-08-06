# PR Review — Cycle 5 (HEAD `2463b53`)

**Verdict: REQUEST_CHANGES** — 1 BLOCKING finding.

Cycle 4's blocking finding (110 false positives in `check-ec-injectivity`, real tree
exiting 1) is genuinely fixed: the tree now exits 0 and all 11 selftests pass. I verified
both claims by execution. But the fix over-corrected. It did not narrow the collision
predicate — it removed it. As of this HEAD, `check-ec-injectivity.py` cannot report a
violation against this project's actual spec-file convention, and there are real POL-16
injectivity violations sitting in the tree right now that it reports as "all injective".

This is the same defect class as D-027 (false-passing checker), in the one validator this
PR exists to harden.

---

## What I verified by execution

| Check | Result |
|---|---|
| `check-ec-injectivity.py` on unmodified tree | exit 0 — `183 EC IDs validated, 110 multi-file` |
| `run-selftests.sh` full suite | exit 0 — 11/11 negative tests PASS |
| Selftest 6 fixture injected | exit 1, exactly one collision (`EC-001` verdict `broken` vs TV `clean`) |
| Cycle-3 commits pushed to origin | confirmed — 15 commits reachable from `2463b53` |
| Required CI checks | all pass (GitGuardian pending); `Spec lint` advisory fail per D-029/D-032 |

So: no false positives, and selftest 6's exit codes are correct in both directions. The
answer to "has selftest 6 regained its soundness" is **no** — for a reason the exit codes
cannot show. See below.

---

## BLOCKING

### B-1 — `check-ec-injectivity` is unconditionally exit-0 on the real corpus; both collision branches are unreachable

| Field | Value |
|---|---|
| Severity | **blocking** |
| Category | correctness / false-negative |
| File | `scripts/spec-lint/check-ec-injectivity.py:133-165` |

Both new collision branches gate on a BC row having a **non-empty verdict column**:

```python
explicit_bc_occs = [(f, d, v, l) for f, d, v, l in bc_occs if v.strip()]
if len(explicit_bc_occs) > 1:          # desc collision
...
    if not bc_verdict_raw.strip():
        continue                        # verdict collision — skip
```

Every Edge Cases table in the spec tree is **2-column** (`| EC | Description |`), so
`extract_ec_rows` always yields `verdict_raw == ""`. Measured over the whole BC tree:

```
total BC EC rows: 179   with explicit verdict col: 0
distinct EC-row column counts: {2: 179}
EC ids with >1 explicit-verdict BC occurrence (desc-collision eligible): 0
```

Both branches are therefore dead code against real data. Demonstration — I injected a
2-column row using the project's own table convention, asserting a scenario that has
nothing to do with the canonical `EC-001`:

```
| EC-001 | TOTALLY UNRELATED SCENARIO: user pipes binary garbage into stdin over TLS |
```

Result: `Check passed: 183 EC IDs validated — all injective`, **exit 0**. A maximally
blatant injectivity violation, in the exact file shape the corpus uses, is not detected.

**This is not hypothetical — the tree already violates POL-16.** 23 EC IDs appear in more
than one BC file with differing descriptions; all 23 are now unchecked. Cross-referencing
against the canonical `test-vectors.md` rows confirms these are distinct scenarios sharing
one ID, not paraphrases:

| EC | Canonical (test-vectors.md) | Conflicting BC citation |
|---|---|---|
| EC-009 | `Symlink docs -> ../shared-docs pointing outside root` (TV-009) | `BC-2.01.008:56` "Directory exists but has zero .md files"; `BC-2.14.001:63` "Empty directory (no .md files)" |
| EC-029 | `[x](docs/)`, `docs/` directory exists (TV-029) | `BC-2.07.003:59` "`[x](readme.md)` but file is `README.md`" |
| EC-072 | `[x](notes.txt#section)` (TV-072) | `BC-2.11.001:66` "`--ignore '*.md'` excludes all .md files" |
| EC-073 | `[x](src/main.rs#L42-L50)` (TV-073) | `BC-2.11.001:67` "`--ignore 'docs/a.md'` exact match" |
| EC-014 | `bad.md` containing ISO-8859-1 bytes | `BC-2.01.009:64` "`mdlinkcheck good_dir/ nonexistent_dir/`" |
| EC-090 | URL dedup, `https://example.com/x` ×50 | `BC-2.10.002:130` "HTTP 401 on GitHub raw content" |

(Plus likely violations in EC-030, 031, 034, 035, 060, 075, 076 — same pattern, but their
TV description column holds only the input filename so I could not adjudicate them from
the diff alone.)

`EC-009` is the cleanest proof: TV-009 canonically defines a dir-symlink-outside-root
scenario, `BC-2.01.004:66` cites it correctly, and two other BCs cite the *same ID* for
an empty-directory scenario. That is a non-injective EC map — precisely what POL-16
forbids and what this checker is named for.

**Why the cycle-4 diagnosis led here.** The commit message is right that comparing
`normalize_verdict("")` against a TV verdict caused the 110 false positives. But the
remedy conflated two separate axes:

1. *BC-vs-TV description* comparison is genuinely unreliable — `extract_tv_rows` captures
   TV's **input-file** column (often just `` `a.md` ``), not a scenario description.
   Dropping this was correct.
2. *BC-vs-BC description* comparison is where the real signal lives, and it was
   collateral damage. It was disabled not because BC descriptions are unreliable, but
   because it was gated behind a verdict column that BC files never have.

**Suggested fix.** Decouple the description check from the verdict column entirely — it
has no logical dependency on it:

```python
# Description collision: across BC files, independent of verdict column presence
if len(bc_occs) > 1:
    by_norm = {}
    for f, d, v, l in bc_occs:
        by_norm.setdefault(normalize_desc(d), []).append((f, d, v, l))
    if len(by_norm) > 1:
        has_desc_collision = True
        ...
```

with `normalize_desc` stripping backticks/emphasis/punctuation and case-folding, so
`` `.git/` directory `` vs `` `.git/` contains files ending in `.md` `` and
`` `mdlinkcheck /does/not/exist` `` vs `` `mdlinkcheck /does/not/exist` (single
nonexistent PATH…) `` collapse as intended paraphrases. I checked: naive normalization
alone collapses 0 of the 23, so a token-overlap or substring-containment threshold will
be needed rather than exact-match-after-normalize. Whatever threshold you choose, it must
separate the paraphrase cases (EC-004, EC-008, EC-010, EC-012, EC-092) from the genuine
collisions (EC-009, EC-029, EC-072, EC-073) listed above — those nine rows make a good
built-in calibration set.

Then fix the ~6 mis-citations so the tree passes, or list them as an explicit,
enumerated, time-boxed allowlist in the script. An allowlist is acceptable; silently
unreachable code is not.

---

## Related, non-blocking

### S-1 — Selftest 6's fixture uses a table shape that does not exist anywhere in the corpus

| Field | Value |
|---|---|
| Severity | **suggestion** (blocking-adjacent; resolved by fixing B-1) |
| Category | test-soundness |
| File | `scripts/spec-lint/selftest/fixtures/bad-ec-injectivity.md:19-21` |

The fixture declares a **3-column** table (`| ID | Description | Expected Behavior |`).
All 179 real BC EC rows are 2-column. So selftest 6 certifies a code path that real data
can never reach — it proves the checker *can* fail, but not that it can fail *on this
corpus*. That is why 11/11 green did not surface B-1, and why the "baseline 0 / fixture 1"
evidence is necessary but not sufficient here.

Once B-1 is fixed, please add a **second** ec-injectivity fixture in the corpus-native
2-column shape (a description collision), so the suite covers the shape that actually
occurs. Consider making this a general harness rule: fixtures should mirror the real
tree's table conventions, and a reviewer should be able to tell at a glance that they do.

### S-2 — `check-ec-injectivity.py` does not honor `SPEC_LINT_REPO_OVERRIDE`

| Field | Value |
|---|---|
| Severity | **suggestion** |
| Category | test-isolation |
| File | `scripts/spec-lint/check-ec-injectivity.py:26-30` |

`REPO` is hardcoded from `Path(__file__).resolve()`. Five other checkers support
`SPEC_LINT_REPO_OVERRIDE` and their selftests run against isolated temp trees. This
checker cannot, which forces selftest 6 to mutate the live spec tree and to depend on
`EC-001` existing in `test-vectors.md` — the fixture-coupling already noted as accepted.
Adding the override closes both, and would let the B-1 regression test run hermetically.

### N-1 — `collision_detail` header suppression can drop TV context

| Field | Value |
|---|---|
| Severity | **nit** |
| Category | diagnostics |
| File | `scripts/spec-lint/check-ec-injectivity.py:155` |

`if not collision_detail:` means that when a description collision has already populated
the list, a subsequent verdict collision on the same EC never prints its TV-side rows —
the operator sees the BC row with no canonical value to compare against. Unreachable
today (desc path is dead), but it becomes live the moment B-1 is fixed. Track the TV
header with its own boolean.

---

## Checklist

| # | Item | Status |
|---|---|---|
| 1 | Diff coherence | PASS — all 24 files are spec-lint tooling, CI, justfile |
| 2 | Description accuracy | **PARTIAL** — the traceability table claims POL-16 EC injectivity is enforced with selftest coverage; per B-1 the enforcement is unreachable on real data |
| 3 | Test coverage | **PARTIAL** — 11/11 pass, but see B-1/S-1: the ec-injectivity test exercises a non-existent shape |
| 4 | Demo evidence | ACCEPTED — selftest output is the right evidence for validator tooling; no UI surface |
| 5 | Commit quality | PASS — conventional format, accurate and specific messages, good root-cause narration |
| 6 | Diff size | NOTED — 3390 insertions, >500 threshold; justified for a 12-script tooling drop |
| 7 | Missing changes | PASS for stated scope |
| 8 | Dependency status | PASS — no upstream PR deps; all commits pushed |

## Explicitly not re-raised (accepted / deferred)

`check-placeholders` real-tree failure (25 `[filled by story-writer]`); non-exhaustive
`check-adr-consistency` exit-code validation; non-atomic generator writes;
`gen-prd-sections.py` exit 0 when markers absent; unescaped `re.sub` in generators;
`bad-holdout-leak.md` / `bad-ec-injectivity.md` fixture coupling to live tree state;
unpinned CI Python; `persist-credentials`; missing `check-title-sync` injection selftest
(note: this one now *does* exist as selftest 9 — the PR description's "Gap noted" section
is stale and can be updated); no positive-control baseline in the harness.

The last item is worth reconsidering after B-1: an all-clear baseline assertion would not
have caught B-1 either, but a *coverage* assertion would — something that fails if a
checker's violation-emitting branches are never exercised by any fixture. Worth a Phase 2
backlog item.

---

## What good looks like for cycle 6

1. Description-collision detection reachable on 2-column BC rows, with a normalization
   threshold calibrated against the paraphrase/collision pairs above.
2. The ~6 confirmed mis-citations fixed, or explicitly allowlisted with rationale.
3. A 2-column ec-injectivity fixture added to the selftest suite.
4. Evidence: real tree exit code, `EC-009`-class violations demonstrably caught, and the
   2-column probe from B-1 shown failing.

Nothing here questions the overall shape of this PR — 12 scripts, a negative-test harness,
and advisory-then-required CI staging is the right design, and the cycle-to-cycle root
cause analysis has been consistently honest. B-1 is one predicate away from correct.

covered_sha: 2463b536fd1b97fafffa8a18a9158ce2fe5844dc
