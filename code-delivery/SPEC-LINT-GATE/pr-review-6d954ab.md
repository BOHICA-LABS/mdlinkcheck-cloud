# PR #3 Review — `fix(spec-lint): eliminate vacuous-test defect class + P4-021 fixes`

**Reviewed SHA:** `6d954ab88f52795bd1cd1c3bf22b5cba31dec495`
**Verdict:** REQUEST_CHANGES

**Primary scope:** `a9b9be0..6d954ab` — 4 files, +105 / −8
**Secondary scope:** `origin/develop..6d954ab` — 5 files, +853 / −214
**Prior disposition:** `pr-review-a9b9be0.md` APPROVED at `a9b9be0`. This review
covers only the never-reviewed delta commit `6d954ab` plus a sanity sweep of the
full PR. Findings already dispositioned at `a9b9be0` (F-1 … F-9) are not re-litigated.

---

## Summary

The commit makes four claims. **Three are genuine and verified by execution.
One is false.**

| Claim | Verdict |
|---|---|
| Suite is 17/17 | ✅ VERIFIED |
| Fixes B-6 (test 10 / 10d mutation independence) | ✅ VERIFIED |
| Fixes 3 over-determined tests (2, 5, 9) | ✅ VERIFIED — each now flips in isolation |
| Adds guard tests G1/G2 proving the pre-flight guards fire | ❌ **FALSE — both are tautological** |

The two guard tests added by this commit do not test the guards. They re-declare
a **duplicated inline copy** of each guard's regex and match it against stub files
the test itself writes. The real guard code path is never invoked. I defeated both
real guards outright and planted a live D-039 violation in a real checker; the
suite still reported `17/17` and still printed `Pre-flight guard passed`.

This is BLOCKING because the tests' own stated purpose is "D-040 applies
recursively: the guard ... must itself be proven to fire," and they do not
establish that. It is also a D-057 violation: the guard tests carry zero
positive-coverage count over the real artifact.

A second, independent D-057 defect was found in the exact code blocks this commit
restructured: `check-index-integrity.py` prints `Check passed: 14 structural
checks — ... HS all consistent` **while validating zero HS items**, on a tree
whose HS-INDEX rows all point at nonexistent files.

Working tree left exactly as found (`git status` clean, HEAD `6d954ab`).
All mutation work was done in throwaway `mktemp -d` sandboxes, since removed.

---

## Verification performed

All commands run at `6d954ab` in `/Users/jmagady/Dev/mdlinkcheck-cloud`.

### V-1 — Baseline suite (claim: 17/17)

```
$ bash scripts/spec-lint/selftest/run-selftests.sh
Pre-flight guard passed: all 8 checkers support SPEC_LINT_REPO_OVERRIDE
Pre-flight guard passed: no suppression allowlists found in any checker
... (17 test lines, all PASS) ...
Selftest passed: 17/17 negative tests verified (each proved clean-pass + defect-fail)
```

Confirmed. Also re-confirmed on the pristine tree after all mutation work.

### V-2 — Checker inventory (no silently-omitted checker)

`scripts/spec-lint/*.py` = 12 files: 8 `check-*.py` + 4 `gen-*.py`. The
pre-flight guards' hardcoded list enumerates exactly those 8. No omission.

### V-3 — MUTATION A: real G1 guard defeated → G1 does not notice

Sandbox copy. Replaced the real guard's pattern at
`selftest/run-selftests.sh:51` with `.` (matches any non-empty file, so a checker
with a hardcoded path would sail through):

```
MUTATION A applied: real guard pattern replaced with '.' (guard defeated)
Pre-flight guard passed: all 8 checkers support SPEC_LINT_REPO_OVERRIDE
── guard selftest G1: SPEC_LINT_REPO_OVERRIDE pre-flight guard fires ──
Selftest passed: 17/17 negative tests verified (each proved clean-pass + defect-fail)
```

**G1 still PASSED. Suite still 17/17.** G1 is over-determined.

### V-4 — MUTATION B: real G2 guard defeated + live D-039 violation planted

Neutered the real `SUPPRESSION_PATTERN` (`run-selftests.sh:70`) to
`ZZZ_THIS_NEVER_MATCHES_ANYTHING`, **and** appended a genuine D-039 violation to a
real checker: `KNOWN_COLLISIONS = {"EC-001", "EC-002"}` in `check-ec-injectivity.py`.

```
MUTATION B applied: real SUPPRESSION_PATTERN neutered
planted KNOWN_COLLISIONS into check-ec-injectivity.py
Pre-flight guard passed: no suppression allowlists found in any checker
── guard selftest G2: suppression-allowlist pre-flight guard fires ──
Selftest passed: 17/17 negative tests verified (each proved clean-pass + defect-fail)
```

**A real D-039 violation sat in a real checker and the suite reported all-green,
while explicitly asserting "no suppression allowlists found in any checker."**
G2 is over-determined and actively misleading.

### V-5 — MUTATION C: test 2 over-determination fixed (claim verified)

Disabled only the `total_bcs` mismatch branch in `check-counts.py:214`:

```
[C] ── selftest 2: check-counts: BC frontmatter count mismatch ──
[C]   FAIL (checker returned 0 — did NOT catch BC count mismatch)
[C] Selftest FAILED: 1/17 negative tests failed
```

Exactly one test flipped, for the intended reason. Previously the
`subsystems: 1` fixture value masked this. Genuine fix.

### V-6 — MUTATION D: test 9 over-determination fixed (claim verified)

Disabled only the BC-INDEX-vs-H1 comparison in `check-title-sync.py:130`:

```
[D]   FAIL (checker returned 0 — did NOT catch H1 vs BC-INDEX title mismatch)
[D] Selftest FAILED: 1/17 negative tests failed
```

Exactly one test flipped. The added `prd.md` rewrite correctly removes the PRD §2
check as a confound. Genuine fix.

### V-7 — MUTATION E: test 5 over-determination fixed (claim verified)

Neutered only the two `WRONG_EXIT_PATTERNS` exit-2 regexes in
`check-adr-consistency.py:86-89`:

```
[E]   FAIL (checker returned 0 — did NOT catch exit 2 for broken-link outcome)
[E] Selftest FAILED: 1/17 negative tests failed
```

Exactly one test flipped. The fixture edit (removing the `dns-failure →
indeterminate` sentence from `bad-adr-exit-code.md`) correctly removes the
second, unrelated defect that was masking the exit-2 check. Genuine fix.

### V-8 — MUTATIONS F & G: B-6 fixed, tests 10 / 10d now independent

```
MUT F: malformed-cell block ONLY disabled
[F]   FAIL (checker returned 0 — did NOT catch malformed EC cell in HS-002)
[F] Selftest FAILED: 1/17 negative tests failed

MUT G: forward-check block ONLY disabled
[G]   FAIL (checker returned 0 — did NOT catch HS entry with no wave-scenarios file)
[G] Selftest FAILED: 1/17 negative tests failed
```

Each block is now independently mutation-detectable by exactly its own test.
B-6 is genuinely fixed.

### V-9 — No regression in the other 13 selftests

Every mutation V-5 … V-8 flipped **exactly one** test and left the other 16
passing. Combined with V-1, no selftest regressed.

### V-10 — D-057 positive-coverage probe on the HS blocks this commit split

Built an isolated tree whose `HS-INDEX.md` has 3 rows, **all** pointing at
nonexistent `wave-scenarios/` files, all with non-conforming HS-ID cells:

```
| HS-001x | EC-999 | ... |
| hs-002  | EC-998 | ... |
| HS-003 (deferred) | EC-997 | ... |

$ SPEC_LINT_REPO_OVERRIDE=$T python3 scripts/spec-lint/check-index-integrity.py
Check passed: 14 structural checks — BC (0 entries), VP (0 entries), ADR, ARCH, L2, HS all consistent
EXIT=0
```

**False pass.** `checks` counted both new blocks (14 total) while validating zero
HS items, and the success line asserts "HS all consistent."

### V-11 — HS row-parser silent-skip enumeration

```
  ACTIVE                   | HS-001 | EC-156 | ok |
  RETIRED                  | ~~HS-002~~ | ~~EC-157~~ | retired |
  MALFORMED (flagged)      | HS-003 | TBD | malformed EC cell |
  MALFORMED (flagged)      | ~~HS-004~~ | EC-158 | partial strike |
  ** SILENTLY SKIPPED **   | HS-005x | EC-159 | trailing junk in HS cell |
  ACTIVE                   | HS-6 | EC-160 | single digit |
  ** SILENTLY SKIPPED **   |  HS-007 (deferred) | EC-161 | annotation in HS cell |
  ** SILENTLY SKIPPED **   | HS_008 | EC-162 | underscore typo |
  ** SILENTLY SKIPPED **   | hs-009 | EC-163 | lowercase |
```

4 of 9 realistic malformed shapes are dropped before either check sees them.

### V-12 — `__pycache__` hygiene

`git ls-files | grep pycache` → 0 tracked files. The `.gitignore` addition is
pure hygiene, introduces no untracking of previously-tracked content.

### V-13 — CI / advisory spec-lint

Per orchestrator: 4 required contexts green on `6d954ab`. Advisory `Spec lint`
failure on 25 known `[filled by story-writer]` placeholders — per D-029/D-032,
**not** treated as a finding.

---

## Findings

### B-7 [BLOCKING] Guard tests G1 and G2 are tautological — they test a copy of the regex, not the guard

`scripts/spec-lint/selftest/run-selftests.sh:773-845`

Both new tests write their own stub files and then run `grep` with a **second,
independent copy** of the guard's pattern. The real guard code (lines 44-59 and
70-86) is never executed by either test.

G1 hardcodes `"^REPO[[:space:]]*=.*SPEC_LINT_REPO_OVERRIDE"` inline, duplicating
line 51. G2 is worse: it declares

```bash
G2_PATTERN='(ALLOWLIST|_DEFERRAL|SKIP_LIST|SKIP_SET|KNOWN_COLLISIONS|KNOWN_VIOLATIONS|KNOWN_ISSUES|WHITELIST|SUPPRESS_SET)[[:space:]]*[=:]'
```

even though the real `SUPPRESSION_PATTERN` (line 70) is a live, in-scope shell
variable at that point. Using `$SUPPRESSION_PATTERN` would have been strictly
less code and at least pattern-drift-safe. The copy was chosen deliberately.

Consequences, both proven by execution (V-3, V-4):

1. Defeating the real G1 guard leaves G1 passing and the suite at 17/17.
2. Defeating the real G2 guard **and planting a live `KNOWN_COLLISIONS` D-039
   violation into `check-ec-injectivity.py`** leaves G2 passing, the suite at
   17/17, and the run printing `Pre-flight guard passed: no suppression
   allowlists found in any checker`.

This is the precise defect class the commit claims to close, reproduced inside
the fix itself. It violates D-040 as the tests' own comments frame it ("the guard
... must itself be proven to fire"), and D-057 — the tests establish only
known-bad-input coverage against self-authored stubs, with zero positive-coverage
count over the real checker set. It is also the BI-023 literal-match-brittleness
shape: two copies of a literal pattern that can silently diverge.

These tests also inflate `TESTS_WITH_CLEAN_PASS`, so the post-test invariant at
line 855 ("every test must assert the checker exits 0 on the clean tree") is
satisfied vacuously for G1/G2 — the "checker" is a stub the test just wrote.

**Suggestion:** extract each guard into a function taking the checker directory
as an argument, e.g.

```bash
assert_override_guard() {  # $1 = dir to scan; returns 0 = pass, 2 = guard fired
    local dir="$1" ...
}
```

then have the pre-flight call `assert_override_guard "$LINT_DIR"` and have G1
call `assert_override_guard "$T"` against the good/bad stubs, asserting exit 0
then exit 2. Same for guard 2. That makes the test exercise the shipped code
path, so Mutation A and Mutation B would both flip it. Additionally, have each
guard print a runtime-computed positive-coverage count (`8 checkers scanned, 0
suppression constructs found`) and fail if the scanned count is 0, per D-057.

### B-8 [BLOCKING] `check-index-integrity` reports "HS all consistent" while validating zero HS items (D-057)

`scripts/spec-lint/check-index-integrity.py:350-370`, success line at `:405-407`

The commit split the HS forward check into two blocks specifically so each is
independently mutation-detectable — that part works (V-8). But both blocks do
`checks += 1` **unconditionally**, outside the loop, before iterating. When
`get_hs_ec_mapping()` returns an empty or degraded mapping, both blocks still
increment `checks` and validate nothing, and the checker exits 0 with:

```
Check passed: 14 structural checks — BC (0 entries), VP (0 entries), ADR, ARCH, L2, HS all consistent
```

Proven at V-10 against an HS-INDEX whose three rows all point at nonexistent
`wave-scenarios/` files. Note the success line reports item counts for BC and VP
but **not** for HS, so nothing in the output reveals that the HS checks were
vacuous — while the message affirmatively claims HS consistency.

`checks` is a count of *check blocks executed*, not a positive-coverage count of
*items validated*. D-057 requires the latter. This commit added two increments to
that misleading counter in the very blocks it restructured.

Contributing cause (V-11): the row parser at `check-index-integrity.py:~140-160`
silently drops any row whose HS-ID cell is not exactly `HS-<digits>` optionally
wrapped in `~~`. `HS-005x`, `HS-007 (deferred)`, `HS_008`, and `hs-009` all
vanish before either check runs — the BI-023 silent-skip shape.

**Suggestion:** replace `checks += 1` in these two blocks with item counters and
gate success on them:

```python
hs_validated = 0
for hs_id, ec_id in sorted(hs_mapping.items()):
    hs_validated += 1
    ...
if hs_validated == 0:
    violations.append(f"{hs_index_path}: zero parseable HS entries — checker validated nothing")
```

and include `HS ({hs_validated} entries)` in the success line alongside BC and VP.
Separately, emit a violation for any `^\|\s*~?~?[Hh][Ss][-_]` row that fails to
parse, rather than skipping it.

### F-10 [MINOR] PR description is now further out of date and does not mention G1/G2

The body still says "All **11** selftest cases" (line 6) and the test plan expects
`Selftest passed: 11/11` (lines 64, 72). The suite is now 17. `F-7` at `a9b9be0`
already flagged this at 15; this commit added two more tests without touching the
body, so the gap widened and the two new guard tests are entirely undocumented.

More importantly, the body's claim "A test that passes with or without the planted
defect is now structurally impossible" is **demonstrably false** as of this commit
— G1 and G2 are exactly such tests (V-3, V-4). Update the body when B-7 is fixed.

### F-11 [NIT] `.gitignore` `__pycache__` entry is unrelated to the story

`.gitignore:21-25`. Correct and harmless (V-12 confirms nothing was previously
tracked), and plausibly motivated by running the selftests locally, but it is not
part of the mutation-audit change set. No action needed; noting for diff coherence.

---

## Checklist

| # | Item | Result |
|---|---|---|
| 1 | Diff coherence | PASS — 4 files, all serve the mutation audit (see F-11) |
| 2 | Description accuracy | **FAIL** — see F-10; one claim is now false |
| 3 | Test coverage | **FAIL** — the two added tests do not cover their target (B-7) |
| 4 | Demo evidence | N/A — no `docs/demo-evidence/` convention in this repo; deliberate judgment call carried over from `a9b9be0`. Substituted by the execution evidence above. |
| 5 | Commit quality | PASS — conventional format, fix ID `B-6` in the subject |
| 6 | Diff size | PASS — 105 lines in primary scope |
| 7 | Missing changes | **FAIL** — B-6 and the 3 over-determined tests are done; the guard-test claim is not delivered |
| 8 | Dependency status | PASS — no upstream PR deps; base `develop` |

---

## What was verified good

To be explicit that this is not a blanket rejection: **three of the four claims
in this commit are real, and I proved each one by mutation rather than by
reading.** The B-6 split genuinely decouples tests 10 and 10d (V-8). The three
over-determination fixes are all correct and minimal — the `subsystems: 0` fixture
change, the `prd.md` confound removal, and the `bad-adr-exit-code.md` second-defect
removal each isolate exactly one checker branch, confirmed by V-5, V-6 and V-7.
No selftest regressed (V-9). The checker inventory has no silent omission (V-2).

The blocking findings are confined to the guard tests G1/G2 and to the
positive-coverage semantics of the `checks` counter.

---

## Note on BI-021

`check-canonical-facts.py` is not under `scripts/spec-lint/` and is not in either
pre-flight guard's checker list. Per instructions, BI-021 is not reported here.

---

**2 blocking findings.** B-7: the two guard tests added by this commit do not
exercise the guards they claim to prove, verified by defeating both real guards
and planting a live D-039 violation with the suite still reporting 17/17. B-8: the
HS checks this commit restructured report success while validating zero items.
