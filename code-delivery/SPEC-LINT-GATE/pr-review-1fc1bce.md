# PR #3 Review — `fix(spec-lint): fix B-7 vacuous guard tests + B-8 false-pass on zero HS items`

**Reviewed SHA:** `1fc1bceb4dcf6e416c31f3f19a963fdbf94144b0`
**Verdict:** REQUEST_CHANGES

**Primary scope:** `6d954ab..1fc1bce` — 2 files, +144 / −69
**Secondary scope:** `origin/develop..1fc1bce` — 6 files, +956 / −239
**Prior disposition:** `pr-review-6d954ab.md` returned REQUEST_CHANGES with 2 blocking
findings (B-7, B-8). This review covers only the never-reviewed delta commit
`1fc1bce`. Findings already dispositioned at `a9b9be0` / `6d954ab` are not
re-litigated. The `checks`-counts-blocks-not-items papercut is accepted as D-057
low-priority per orchestrator and is not reported.

---

## Summary

The commit makes two claims. **One is genuine. One is only half-delivered, and the
half that was delivered has no test coverage at all.**

| Claim | Verdict |
|---|---|
| B-7 fixed — G1/G2 call the real guard functions, one pattern definition each | ✅ VERIFIED (MUT-5) |
| B-8 fixed — `hs_validated` runtime count + fail-closed zero-parsed guard | ❌ **PARTIAL — false pass still reachable** |
| Suite still 17/17, no regressions | ✅ VERIFIED |
| PR description corrected (prior F-10) | ✅ VERIFIED |

The B-7 half is real. `OVERRIDE_PATTERN` (`:45`) and `SUPPRESSION_PATTERN` (`:46`)
have one definition each, the guards are extracted into `run_override_guard()` /
`run_suppression_guard()`, and G1/G2 invoke them. Making both functions
`return 0` unconditionally flips exactly G1 and G2 (MUT-5). The empty-checker-dir
fail-closed branch is reachable in the real invocation path (MUT-7 → exit 2).

The B-8 half did not close the defect. **I reproduced the original B-8 false pass
at `1fc1bce` in two forms**, one of them with a *non-zero* `hs_validated`, which
means the new fail-closed guard is not even engaged:

```
| HS-001 | EC-156 | parsed fine |                          <- parsed
 | HS-004 | EC-165 | ONE LEADING SPACE |                   <- SILENTLY DROPPED
 | HS-005 | EC-166 | ONE LEADING SPACE |                   <- SILENTLY DROPPED

Check passed: 14 structural checks — ... HS (1 entries) all consistent
EXIT=0
```

Two real HS entries pointing at nonexistent `wave-scenarios/` files vanished from
the gate and the checker reported success. Root cause: **all four parser patterns
AND the new fail-closed guard's own data-row detector are anchored at `^\|`.** The
backstop shares the exact failure mode of the thing it is backstopping — BI-023,
verbatim.

Separately and independently: **every line of the B-8 remediation can be deleted
and the suite still reports 17/17.** Deleting the near-miss capture, the near-miss
violation emission, or the fail-closed guard each leaves the suite fully green
(MUT-1, MUT-2, MUT-3). MUT-1 restores literally the pre-`1fc1bce` silent-skip
behavior with zero test flips — the suite cannot distinguish the defect from the
fix. That is a direct D-040 violation on brand-new validator code, and it is the
structural sin of B-7 reproduced in the other half of the same commit.

Working tree left exactly as found (`git status` clean, HEAD `1fc1bce`, no
commits/branches/pushes). All mutation work done in `mktemp -d` sandboxes, since
removed.

---

## Verification performed

Sandbox pattern: `SB=$(mktemp -d /tmp/prrev.XXXXXX)`. Checker probes use a minimal
isolated tree (BC/VP/ARCH/L2 index stubs + `holdout-scenarios/`) driven via
`SPEC_LINT_REPO_OVERRIDE`, mirroring selftest 10's fixture. Selftest-suite
mutations use `cp -R scripts $SB/<name>/scripts` — `run-selftests.sh` derives
`REPO` from its own location, so a `scripts/`-only copy is a complete sandbox.

### V-1 — Baseline, real tree

```
$ git rev-parse HEAD && git status --porcelain
1fc1bceb4dcf6e416c31f3f19a963fdbf94144b0
(clean)

$ python3 scripts/spec-lint/check-index-integrity.py
Check passed: 80 structural checks — BC (66 entries), VP (26 entries), ADR, ARCH, L2, HS (7 entries) all consistent
EXIT=0

$ bash scripts/spec-lint/selftest/run-selftests.sh
... 17 test lines, all PASS ...
Selftest passed: 17/17 negative tests verified (each proved clean-pass + defect-fail)
```

`HS (7 entries)` is honest: HS-INDEX has exactly 7 canonical rows
(HS-001, ~~HS-002~~, ~~HS-003~~, HS-004…HS-007) and 7 `wave-scenarios/` files.

### V-2 — **MUT-1: near-miss capture deleted → suite still 17/17**

Replaced `check-index-integrity.py:173-176` (the `[Hh][Ss][-_]` capture block) with
`pass`, i.e. restored the pre-fix silent skip:

```
MUT-1 applied
Selftest passed: 17/17 negative tests verified (each proved clean-pass + defect-fail)
```

**The suite cannot tell `6d954ab`'s defective parser from `1fc1bce`'s fixed one.**

### V-3 — **MUT-2: fail-closed zero-parsed guard deleted → suite still 17/17**

Deleted `check-index-integrity.py:388-395` in full:

```
MUT-2 applied
Selftest passed: 17/17 negative tests verified (each proved clean-pass + defect-fail)
```

### V-4 — **MUT-3: near-miss violation emission neutered → suite still 17/17**

`:374` `if hs_id.startswith("NEAR_MISS:")` → `if False and ...`:

```
MUT-3 applied
Selftest passed: 17/17 negative tests verified (each proved clean-pass + defect-fail)
```

`EXPECTED_TEST_COUNT` is still 17; the commit added three violation paths and one
fail-closed guard to the checker and **zero** tests.

### V-5 — MUT-4: both guards' `count -eq 0` fail-closed branches deleted → 17/17

Removed both `if [[ "$count" -eq 0 ]]` blocks (`run-selftests.sh:64-67`, `:90-93`):

```
count==0 branches found: 2   remaining: 0
Selftest passed: 17/17 negative tests verified (each proved clean-pass + defect-fail)
```

New D-057 defensive code, untested.

### V-6 — MUT-5: B-7 confirmed genuinely fixed

Inserted `return 0` at the top of both guard functions (total defeat):

```
── guard selftest G2: suppression-allowlist pre-flight guard fires ──
  FAIL (guard did NOT detect KNOWN_COLLISIONS suppression allowlist)
Selftest FAILED: 2/17 negative tests failed
```

Exactly G1 + G2 flip; the other 15 pass. G1/G2 now exercise the shipped code path.

### V-7 — MUT-7: empty-checker-dir fail-closed is reachable in the REAL path

Renamed all 8 `check-*.py` → `verify-*.py` so `LINT_DIR` has no checkers:

```
Pre-flight structural guard: checking SPEC_LINT_REPO_OVERRIDE in all checkers...
STRUCTURAL GUARD FAILED: no check-*.py files found in .../scripts/spec-lint — nothing scanned
MUT-7 exit=2
```

Confirmed reachable and fail-closed, not merely correct in isolation.

### V-8 — MUT-6: glob did not weaken checker-inventory detection

Deleted `check-ec-injectivity.py`. The guards now just report `7 checkers`, but the
suite still fails closed via the post-test invariant:

```
Pre-flight guard passed: 7 checkers support SPEC_LINT_REPO_OVERRIDE
Pre-flight guard passed: 7 checkers scanned, 0 suppression constructs found
STRUCTURAL GUARD FAILED: only 16/17 tests had a clean-pass assertion
MUT-6 exit=2
```

No finding — replacing the hand-maintained 8-checker list with a glob is a net
improvement and the inventory property is preserved by `EXPECTED_TEST_COUNT`.

### V-9 — **P6: `hs_validated` NON-ZERO while real HS entries silently skipped** ← decisive

HS-INDEX with one flush row and two rows indented by a single space (renders
identically in every markdown renderer); only `EC-156-x.md` present in
`wave-scenarios/`:

```
| HS-001 | EC-156 | parsed fine | n | BC | active |
 | HS-004 | EC-165 | ONE LEADING SPACE - silently dropped | n | BC | active |
 | HS-005 | EC-166 | ONE LEADING SPACE - silently dropped | n | BC | active |

Check passed: 14 structural checks — BC (0 entries), VP (0 entries), ADR, ARCH, L2, HS (1 entries) all consistent
EXIT=0
```

`hs_validated == 1`, so `len(hs_mapping) == 0` is False and the fail-closed guard
never runs. Two HS entries whose EC files do not exist were dropped by the parser,
by the near-miss net, and by the guard simultaneously.

### V-10 — P7 / P4a: zero-item false pass still reachable

All rows indented, `wave-scenarios/` empty:

```
 | hs-009 | EC-163 | lowercase AND indented | ... |
 | HS_008 | EC-162 | underscore AND indented | ... |

Check passed: ... HS (0 entries) all consistent      EXIT=0
```

Same with three flush-left-broken canonical rows (P4a) and with the table replaced
by a bullet list (P4c). The guard's `hs_data_rows` detector
(`re.match(r"^\|\s*[^-|]", l)`, `:390`) is `^\|`-anchored, so the input class that
defeats the parser also defeats the guard. Where `wave-scenarios/` is non-empty the
reverse check rescues it (P4b → exit 1) — that rescue is coincidental coupling, not
the guard doing its job, and V-9 shows it does not rescue the mixed case.

### V-11 — P1 / P5: near-miss pattern over-matches legitimate content

```
$ # header row column named "HS-ID" instead of "HS ID"
| HS-ID | EC-ID | Title | Notes | BCs | Status |
HS-INDEX.md: HS row with non-canonical ID 'HS-ID' — expected 'HS-<digits>' or '~~HS-<digits>~~'
EXIT=1

$ # a documentation table row about the index file itself
| HS-INDEX.md | root of holdout-scenarios/ | governance scope |
HS-INDEX.md: HS row with non-canonical ID 'HS-INDEX.md' — expected 'HS-<digits>' or '~~HS-<digits>~~'
EXIT=1
```

The real tree escapes only because its header happens to read `HS ID` with a space
rather than a hyphen. Note the message tells the author to rename a *column header*
to `HS-<digits>`.

### V-12 — P2: `HS-6` single digit handled correctly

```
| HS-6 | EC-160 | single digit | ... |   +  wave-scenarios/EC-160-x.md
Check passed: ... HS (1 entries) all consistent      EXIT=0
```

`HS-\d+` matches one-or-more digits. No zero-padding assumption. Correct.

### V-13 — P3: `NEAR_MISS:` keys can collide and silently overwrite

Two **distinct** rows with different EC cells:

```
| HS-005x | EC-159 | first row | ... |
| ~~HS-005x~~ | EC-777 | second, DISTINCT row | ... |

Check FAILED: 1 index integrity violations found
```

`.strip().rstrip("~").strip()` (`:175`) normalizes both to `HS-005x`, so the second
row overwrites the first: two malformed rows → one violation. Exit code is still 1,
so no false pass.

### V-14 — Guard exit-code plumbing / `set -e` interaction

`run-selftests.sh:19` is `set -uo pipefail` — **no `-e`**, so there is no errexit
path to swallow a guard failure. Callers are `if ! run_override_guard "$LINT_DIR"; then
exit 2; fi` (`:103`, `:114`); the functions only ever return 0 or 2, so collapsing
non-zero to `exit 2` is lossless today. G1/G2 (`:820`, `:833`, `:858`, `:871`)
likewise test only zero/non-zero.

One asymmetry: `run_override_guard` uses `if ! grep -qE ... 2>/dev/null` so a `grep`
error (exit 2, e.g. unreadable file) fails **closed**; `run_suppression_guard` uses
`if grep -qE ...` so the same error is read as "no match" and fails **open**. I
planted `KNOWN_COLLISIONS` in a `chmod 000` checker:

```
STRUCTURAL GUARD FAILED: check-planted.py lacks SPEC_LINT_REPO_OVERRIDE support
```

Guard 1 fires first and stops the run, so the fail-open is unreachable today. That
makes guard ordering load-bearing and undocumented.

### V-15 — PR description corrected (prior F-10 closed)

Body now states 17/17 throughout, documents G1/G2 calling the real functions and
the single-definition property, documents the BI-023 near-miss fix and the D-057
`HS (N entries)` count. The false "vacuous tests are structurally impossible"
claim is gone from the body. Its test-plan item is accurate — I ran it:

```
| HS-001x | ... |  | hs-002 | ... |  | HS-003 (deferred) | ... |
3 violations, Check FAILED: 3 index integrity violations found   EXIT=1
```

### V-16 — No regression in the other 15 selftests

V-1 is 17/17. MUT-5 flips exactly G1 + G2. MUT-1/2/3/4 flip nothing. No selftest
regressed.

### V-17 — CI

Per orchestrator: all 4 branch-protection-required contexts green on `1fc1bce`.
Advisory `Spec lint` failure on 25 known `[filled by story-writer]` placeholders —
per D-029/D-032, **not** a finding.

---

## Findings

### B-9 [BLOCKING] B-8 is not closed: `hs_validated` can be non-zero while real HS entries are silently dropped, and the fail-closed guard shares the parser's failure mode

`scripts/spec-lint/check-index-integrity.py:153-177` (parser), `:388-395` (guard),
`:405` (`hs_validated += 1`), `:448` (success line)

Every one of the five patterns that decide whether an HS row is seen is anchored at
`^\|`:

- `:155` active — `^\|\s*(HS-\d+)\s*\|\s*(EC-\d+)\s*\|`
- `:160` retired — `^\|\s*~~(HS-\d+)~~...`
- `:166` malformed-EC — `^\|\s*(?:~~)?(HS-\d+)...`
- `:173` near-miss — `^\|\s*(?:~~)?([Hh][Ss][-_]\S[^\|]*?)...`
- `:390` **the fail-closed guard's own data-row detector** — `^\|\s*[^-|]`

Because the guard reuses the same anchor as the parser it is supposed to backstop,
any input class that defeats the parser defeats the guard too. One leading space —
which changes nothing about how the table renders — is sufficient. Proven twice by
execution:

1. **V-9, the serious form.** One flush row + two indented rows, only the flush
   row's EC file present. `hs_validated == 1`, so `len(hs_mapping) == 0` is False
   and the guard is never consulted. `HS-004 → EC-165` and `HS-005 → EC-166` both
   point at nonexistent `wave-scenarios/` files and are dropped by the parser, the
   near-miss net, and the guard simultaneously. Output:
   `Check passed: ... HS (1 entries) all consistent`, exit 0.
2. **V-10, the zero form.** All rows unparseable and `wave-scenarios/` empty →
   `HS (0 entries) all consistent`, exit 0. The count is now *disclosed* (a real
   improvement over `6d954ab`) but nothing **gates** on it. D-057's criterion is
   "N validated, 0 non-conforming"; printing `N = 0` and returning 0 is not
   fail-closed.

Where `wave-scenarios/` is non-empty the reverse check happens to catch the
all-rows-broken case (V-10, P4b). That is coincidental coupling to an unrelated
check, and V-9 shows it does not save the mixed case at all.

This is BI-023 in its canonical form — anchored literal matching plus silent skip
of unparseable input — and it is the finding the fix set out to close, reproduced
inside the fix.

**Suggestion:** make row recognition and the backstop structurally independent, and
gate on coverage rather than printing it.

```python
# 1. Normalize before matching so layout cannot hide a row.
for raw in hs_index.read_text(encoding="utf-8").splitlines():
    line = raw.strip()
    if not line.startswith("|"):
        continue
    ...  # existing patterns, now on `line`

# 2. Count every table row seen, and reconcile against rows classified.
#    Derive the denominator from a DIFFERENT mechanism than the parser
#    (cell split, not a row-shaped regex).
cells = [c.strip() for c in line.strip("|").split("|")]
if cells and not set(cells[0]) <= set("-: "):     # not a separator row
    hs_rows_seen += 1

# 3. Fail closed on the reconciliation, unconditionally — not only when
#    the mapping is empty.
if hs_rows_seen != hs_validated + hs_nonconforming:
    violations.append(
        f"{hs_index_path}: {hs_rows_seen} table row(s) seen but only "
        f"{hs_validated + hs_nonconforming} classified — "
        f"{hs_rows_seen - hs_validated - hs_nonconforming} row(s) unaccounted for"
    )
```

and make the success line assert rather than narrate:
`HS ({hs_validated} validated, 0 non-conforming, {hs_rows_seen} rows seen)`.

### B-10 [BLOCKING] The entire B-8 remediation has zero negative test coverage — all three new code paths can be deleted with the suite still reporting 17/17 (D-040)

`scripts/spec-lint/check-index-integrity.py:173-176`, `:374-379`, `:388-395`;
`scripts/spec-lint/selftest/run-selftests.sh:25` (`EXPECTED_TEST_COUNT=17`, unchanged)

The commit added three new violation paths and one fail-closed guard to a checker
and added no tests. Each is independently deletable with no effect on the suite:

| Mutation | Target | Suite result |
|---|---|---|
| MUT-1 | near-miss capture `:173-176` → `pass` (restores pre-fix silent skip) | **17/17 PASS** |
| MUT-2 | fail-closed zero-parsed guard `:388-395` deleted | **17/17 PASS** |
| MUT-3 | near-miss violation emission `:374` → `if False and ...` | **17/17 PASS** |
| MUT-4 | both guards' `count -eq 0` branches (`:64-67`, `:90-93`) deleted | **17/17 PASS** |

MUT-1 is the sharpest: it returns the parser to exactly the behavior the prior
review flagged at V-11 of `pr-review-6d954ab.md`, and the suite does not notice.
The fix therefore carries no regression protection — a future refactor can silently
undo it.

D-040 says no validator is trusted without a negative test proving it CAN fail.
This is the same recursion failure as B-7, applied to the other half of the same
commit: B-7 was fixed by making the guard tests exercise the real guard, while the
B-8 code was shipped with no test at all. D-057 also applies — mutation
verification is necessary but not sufficient, and here even the necessary condition
is unmet.

Note the PR body's own test plan already contains the missing case as an unchecked
box ("HS-INDEX with 3 near-miss rows … exits 1 with 3 violation messages"). I ran
it manually and it passes (V-15) — it simply is not in `run-selftests.sh`, so
nothing in CI holds the behavior.

**Suggestion:** add three selftests (bumping `EXPECTED_TEST_COUNT` to 20), each in
the established clean-pass-then-inject shape:

- **10e** near-miss ID → clean tree with `| HS-001 | EC-156 |`, then inject
  `| hs-002 | EC-157 |`; assert exit non-zero. Flips MUT-1 and MUT-3.
- **10f** zero-parsed fail-closed → clean tree, then rewrite HS-INDEX so every row
  is unparseable while data rows remain; assert exit non-zero. Flips MUT-2, and
  once B-9 is fixed it also guards the reconciliation counter.
- **G3** empty checker directory → `run_override_guard "$empty_dir"` and
  `run_suppression_guard "$empty_dir"` must both return non-zero. Flips MUT-4.

### F-12 [MAJOR] The near-miss pattern over-matches: any `HS-`-prefixed cell in any table in HS-INDEX.md is reported as a malformed HS row

`scripts/spec-lint/check-index-integrity.py:173`

`^\|\s*(?:~~)?([Hh][Ss][-_]\S[^\|]*?)(?:~~)?\s*\|` is applied to every line of the
file with no scoping to the Authored Scenarios table. It fires on:

- a column header named `HS-ID` instead of `HS ID` (V-11) — the real tree passes
  only because its header uses a space. A cosmetic header rename with zero semantic
  content turns the gate red with
  `HS row with non-canonical ID 'HS-ID' — expected 'HS-<digits>'`, which instructs
  the author to rename a column header to a scenario ID.
- a documentation row such as `| HS-INDEX.md | root of holdout-scenarios/ | … |`
  (V-11). HS-INDEX.md already has a prose "Placement rationale" section about
  exactly this; tabulating it would break the gate.

This is a false-FAIL class on legitimate content, and false fails erode the gate's
credibility as surely as false passes erode its value. It is also the mirror image
of B-9: the same pattern is simultaneously too loose about *where* it looks and too
strict about *how* the line must be laid out.

**Suggestion:** scope near-miss detection to the rows of the Authored Scenarios
table (track the active `##` heading, or require the second cell to look like an EC
cell — `EC-…`, `~~EC-…~~`, `TBD`, `—`), and exclude separator and header rows
explicitly (`set(cell) <= set("-: ")`, or a first-cell case-insensitive match
against the known header labels).

### F-13 [MINOR] `NEAR_MISS:` keys can collide, silently dropping the second row — and the docstring claims otherwise

`scripts/spec-lint/check-index-integrity.py:146`, `:175-176`

`:146` states the prefix exists "to avoid collisions". That is true only across the
canonical/near-miss namespaces; within near-misses the normalization
`.strip().rstrip("~").strip()` collapses distinct rows onto one key. V-13:
`| HS-005x | EC-159 | first row |` and `| ~~HS-005x~~ | EC-777 | second, DISTINCT
row |` produce **one** violation, not two — the second row's dict entry overwrites
the first.

No false pass results (both shapes emit violations, so exit is 1), which is why
this is MINOR rather than blocking. But it is a silent-drop introduced by the fix
for a silent drop, and the docstring asserts the opposite.

**Suggestion:** make near-miss rows a list rather than dict entries — e.g. return
`(mapping, near_misses: list[tuple[int, str]])` keyed by line number — so every
non-conforming row is reported exactly once with its line number, and reword `:146`
to say the prefix separates namespaces rather than "avoids collisions".

### F-14 [MINOR] `run_suppression_guard`'s remediation text hand-restates `SUPPRESSION_PATTERN` and will drift (D-039 / BI-012 thesis)

`scripts/spec-lint/selftest/run-selftests.sh:85-86` vs `:46`

The commit's headline structural improvement is collapsing two copies of each
pattern into one canonical definition, and the header comment at `:42-44` states
"there is no second copy of either pattern anywhere in this file." Nine of the ten
keywords are then restated by hand as prose two lines below the live variable:

```bash
echo "  Remove any variable matching: ALLOWLIST | _DEFERRAL | SKIP_LIST | SKIP_SET |"
echo "    KNOWN_COLLISIONS | KNOWN_VIOLATIONS | KNOWN_ISSUES | WHITELIST | SUPPRESS_SET"
```

Judging this against the D-039/BI-012 thesis as asked: it is a real instance of the
defect class but the mildest possible consequence. It cannot cause a missed
violation or a false pass — the matching is done entirely by `$SUPPRESSION_PATTERN`.
Drift produces a *misleading remediation hint*: a keyword added to `:46` would fire
the guard while the message printed to the developer omits the term that fired it,
sending them looking for the wrong variable. That is a diagnostic-quality defect,
not a gate-integrity defect, hence MINOR — but the fix is mechanical and free:

```bash
echo "  Remove any variable matching: $SUPPRESSION_PATTERN"
```

The same reasoning applies to the PR body's copy of the keyword list; that one is
release notes and needs no fix.

### F-15 [NIT] `run_suppression_guard` fails open on `grep` error where `run_override_guard` fails closed; guard ordering is load-bearing and undocumented

`scripts/spec-lint/selftest/run-selftests.sh:57` vs `:81`

`if ! grep -qE ... 2>/dev/null` treats `grep` exit 2 (read error) as "pattern
absent" → guard 1 fires. `if grep -qE ... 2>/dev/null` treats exit 2 as "pattern
absent" → guard 2 does **not** fire. So an unreadable checker containing a real
D-039 construct would sail past guard 2. V-14 shows this is unreachable today only
because guard 1 runs first and exits 2 on the same file. Worth a comment at `:114`
noting the dependency, or `grep -qE ... ; rc=$?; [[ $rc -eq 0 ]] && fire; [[ $rc -gt 1 ]] && fire`.

### F-16 [NIT] `run-selftests.sh:9-11` still claims vacuous tests are "STRUCTURALLY IMPOSSIBLE"

That claim was falsified for guard tests at `6d954ab` (prior F-10) and is now
fixed for G1/G2 — but MUT-1/2/3 show four checker code paths with no test at all,
which is vacuity by omission rather than by construction. The clean-pass +
defect-fail pattern makes an *existing* test hard to make vacuous; it says nothing
about untested code. Consider softening to "makes a vacuous test case structurally
impossible; it does not by itself guarantee coverage of every checker branch."

---

## Checklist

| # | Item | Result |
|---|---|---|
| 1 | Diff coherence | PASS — 2 files, both serve B-7/B-8 |
| 2 | Description accuracy | PASS — prior F-10 closed; 17/17, G1/G2 and BI-023 all documented; test-plan near-miss item verified by execution (V-15) |
| 3 | Test coverage | **FAIL** — B-10: four new code paths, zero tests, all deletable at 17/17 |
| 4 | Demo evidence | N/A — no `docs/demo-evidence/` convention in this repo; judgment call carried over from `a9b9be0`/`6d954ab`. Substituted by the execution evidence above. |
| 5 | Commit quality | PASS — conventional format, `B-7`/`B-8` in the subject |
| 6 | Diff size | PASS — 213 lines in primary scope |
| 7 | Missing changes | **FAIL** — B-9: the B-8 false pass is still reachable, once with a non-zero coverage count |
| 8 | Dependency status | PASS — no upstream PR deps; base `develop` |

---

## What was verified good

This is not a blanket rejection, and the B-7 half deserves explicit credit.

- **B-7 is genuinely and completely fixed.** `OVERRIDE_PATTERN` and
  `SUPPRESSION_PATTERN` have one definition each; the guards are real functions;
  G1/G2 call them. Neutering both functions flips exactly G1 and G2 and nothing
  else (V-6). The prior review's Mutation A and Mutation B would now both be
  caught. The extraction is also strictly less code than the duplicated version.
- **The empty-checker-dir fail-closed branch is reachable in the real invocation
  path**, not merely correct in isolation (V-7, exit 2).
- **Replacing the hardcoded 8-checker list with a `check-*.py` glob removed a
  hand-maintained restatement without weakening inventory detection** — deleting a
  checker still fails the suite closed via the post-test clean-pass invariant
  (V-8). Good change.
- **`hs_validated` is a real runtime count, not a constant**, and `HS (7 entries)`
  on the real tree is arithmetically correct against 7 rows and 7 scenario files.
  Disclosing the count is real D-057 progress even though nothing gates on it.
- **`HS-6` (single digit) is handled correctly** — no zero-padding assumption (V-12).
- **No `set -e`**, so no errexit interaction can swallow a guard failure (V-14).
- **No regression**: 17/17 clean, and every mutation flipped only its intended
  tests (V-16).

The blocking findings are confined to the B-8 half: the false pass is narrowed but
not closed (B-9), and none of the B-8 code is tested (B-10).

---

**2 blocking findings.** B-9: `check-index-integrity.py:388-395` / `:405` — the
fail-closed guard reuses the parser's `^\|` anchor, so a single leading space makes
real HS entries invisible to both; reproduced `Check passed … HS (1 entries) all
consistent`, exit 0, with two HS entries pointing at nonexistent scenario files.
B-10: `check-index-integrity.py:173-176`, `:374-379`, `:388-395` — every new B-8
code path is independently deletable with the suite still reporting 17/17, and
MUT-1 restores the pre-fix silent skip undetected.
