# Review Cycle 3 — BI-040 Shared spec-lint Primitive Layer

**Verdict: APPROVE**

`covered_sha: 8a5a21cb048688cb77154cff4c7242279db83f4a`

Cycle 2 fixes reviewed at commit `8a5a21c` (diff `21ec865..8a5a21c`, 3 files, +41/-7).
Every fix was verified **by execution**, not by reading. All six carried findings
(BLOCKING-1, S2, S3, S4, N1, N2) are resolved. No new blocking issues.

---

## BLOCKING-1 — `split_table_cells` test coverage: RESOLVED

The claim was that two new assertions kill two specific mutants. I applied each
mutant to a scratch copy and confirmed the *named* assertion is the one that
fails — so neither assertion is tautological.

| Mutant applied | Result | Failing assertion |
|---|---|---|
| Drop guard: `if len(parts) < 2 or cm_strip_cell(parts[0]) != "":` → `if len(parts) < 2:` | **KILLED** (9/10) | `non-whitespace before first '\|' must not be parsed as a table row` |
| Strip-downgrade: `cm_strip_cell(parts[0]) != ""` → `parts[0] != ""` | **KILLED** (9/10) | `leading CM whitespace before first '\|' is still a table row` |

Both mutants are killed, each by exactly the assertion it was paired with, and no
other test flips. This is the correct shape: the two assertions pin opposite edges
of the same predicate — one proves the guard *rejects* prose, the other proves the
guard does not *over*-reject legitimately indented rows. That second one is what
makes `cm_strip_cell` load-bearing rather than incidental, which is the whole point
of the primitive. Good pairing.

## S3 — `is_historical_changelog_line` assertions: RESOLVED

Same treatment, same result.

| Mutant applied | Result | Failing assertion |
|---|---|---|
| `return in_quotes and has_version` → `return has_version` | **KILLED** (9/10) | `version marker without quotes must not suppress` |
| Remove disjunct 1 (`'"' in before and '"' in after`) | **KILLED** (9/10) | `quote-bracketed match with version marker outside quotes should suppress` |

The disjunct-1 assertion is the more interesting of the two. `_CHANGELOG_VERSION_RE`
is `"[^"]*v\d+\.\d+[^"]*"`, so on `v1.2 - "EC-001 renamed"` the version marker sits
*outside* the quoted span and disjunct 2 cannot fire. That makes disjunct 1 the only
thing producing `True`, which is precisely why removing it flips the test. Correctly
targeted.

## S2 — two-part override guard: RESOLVED

This is the strongest fix in the commit, and it closes a real hole rather than just
adding a comment. Verified in four parts:

1. **All 15 files still pass.** `Pre-flight guard passed: 15 checkers/generators
   support SPEC_LINT_REPO_OVERRIDE`.
2. **The old regex was genuinely fooled.** Against
   `REPO = Path("/hardcoded")  # honors SPEC_LINT_REPO_OVERRIDE via slp.find_repo_root`,
   the previous single `OVERRIDE_PATTERN` **matched** — the guard would have passed a
   checker with a hardcoded path. That was a live bypass, not a hypothetical.
3. **The new check rejects it.** Same input → `STRUCTURAL GUARD FAILED`.
4. **`check-index-integrity.py` passes on real code, not on its comment.** This was
   the specific thing worth confirming, because that file's `REPO = (` line carries a
   trailing comment mentioning `slp.find_repo_root`. Stripping comments, the only line
   satisfying Part 2 is line 21: `else slp.find_repo_root(start=Path(__file__).resolve().parent)`.
   I then replaced *only* that live call with a hardcoded path, leaving the comment
   intact — the guard **fired**. The verdict is earned by executable code.

## S4 / N1 / N2 — comment and docstring accuracy: RESOLVED

- **N2:** docstring now says "at all 4 call sites." Counted: `check-holdout-boundary.py`,
  `check-id-resolution.py`, `check-placeholders.py`, `check-ec-injectivity.py` — exactly 4
  real call sites. The old "5" was wrong; the new count is right.
- **N1:** the dead-exemption comment is accurate. `LINT_DIR="$REPO/scripts/spec-lint"`,
  the loop globs `"$dir"/*.py` (non-recursive), and `test_spec_lint_primitives.py` lives in
  `selftest/`. The exemption is unreachable today, and the comment says so plainly instead
  of quietly leaving a line that looks live.
- **S4:** G4 exists as a pre-flight guard (lines 191/199) and the new comment at line 2304
  correctly records that its proof arm is deferred to the W10 burst. Consistent with the
  agreed deferral.

## Regression status

Both suites green at `8a5a21c`:

- `run-selftests.sh` → `55/55 negative tests verified`, exit 0
- `test_spec_lint_primitives.py` → `10/10 primitive tests passed`, exit 0
- Property test → `300/300 cases verified (seed=42)`

---

## New findings (non-blocking, introduced by the S2 fix)

Neither blocks merge. Both are in the same comment-accuracy class as N1/N2/S4, which
is why I'm raising them rather than letting them ride.

### SUGGESTION-1 — `OVERRIDE_PATTERN` is now dead, and two comments still claim it is coupled

`run_override_guard` no longer uses `OVERRIDE_PATTERN`; it uses inline greps. The
variable at line 47 is now referenced only from comments, and two comment blocks
assert a coupling that no longer exists:

- Lines 43–46: *"Both the pre-flight checks and the guard selftests (G1, G2) use these
  variables … any mutation to `OVERRIDE_PATTERN` or `SUPPRESSION_PATTERN` will make both
  the pre-flight guard AND G1/G2 flip."*
- Lines 1992–1995: *"`OVERRIDE_PATTERN` has one canonical definition; any mutation to it
  will flip this test."*

I tested the claim directly: I replaced `OVERRIDE_PATTERN` with
`'ZZZ_TOTALLY_BOGUS_PATTERN_NEVER_MATCHES'` and ran the full suite. Result: the
pre-flight guard still reported all 15 files passing, G1 still passed, and the suite
still returned **55/55, exit 0**. Mutating it flips nothing.

To be clear about why this is not blocking: G1 calls the real `run_override_guard`
function, so the test still genuinely exercises the shipped logic — the anti-drift
property those comments were protecting (no duplicate pattern copy, the original B-7
defect class) is still intact in substance. The defect is that the comments now
misdescribe the mechanism, and a dead variable that *looks* authoritative is a trap
for the next person who "fixes" the guard by editing line 47 and sees every test
still pass.

Suggested fix: delete `OVERRIDE_PATTERN` and update both comment blocks to say the
coupling is now "G1 invokes the real `run_override_guard`," which is the actual
(and stronger) guarantee.

### NIT-1 — the S2 comment slightly overstates what Part 2 rejects

The new comment says: *"This rejects files where `slp.find_repo_root` appears only in
a comment on the `REPO=` line."* That holds only when the comment omits the open paren.
Part 2 strips full-line comments (`grep -v '^[[:space:]]*#'`) but not trailing ones, so:

```
REPO = Path("/hardcoded")  # uses slp.find_repo_root() somewhere else   → still PASSES
REPO = Path("/hardcoded")  # honors ... via slp.find_repo_root; note     → correctly FIRES
```

The real file falls on the safe side of this by accident of punctuation (its comment
writes `slp.find_repo_root;`, no paren). The residual requires someone to write a
trailing comment containing `slp.find_repo_root(`. Narrow, and the guard is strictly
stronger than before — but the comment should say "in a full-line comment" rather than
"only in a comment," or Part 2 should strip trailing comments too (`sed 's/#.*//'`).

---

## Checklist

| # | Item | Status |
|---|---|---|
| 1 | Diff coherence | PASS — all 3 files trace to a named cycle-2 finding |
| 2 | Description accuracy | PASS — all six claimed fixes verified present and correct |
| 3 | Test coverage | PASS — 4/4 claimed mutants killed by their named assertions |
| 4 | Demo evidence | Carried from `ae03356`; unchanged by this commit |
| 5 | Commit quality | PASS — `fix(bi-040): review cycle 2 — BLOCKING-1/S2/S3/S4/N1/N2` |
| 6 | Diff size | PASS — 41 insertions, 7 deletions |
| 7 | Missing changes | PASS — no cycle-2 finding left unaddressed |
| 8 | Dependency status | N/A |

Out of scope per agreement and not assessed: WS-4 spec-content findings, BI-027,
BI-041 write-mode, W1 inline grammars, W10 checker-level negative selftest, W12
text-only evidence, S4 G4 proof arm.

---

**APPROVE.** The two blocking-class fixes were verified by mutation rather than
inspection, and both hold. S2 in particular closes a demonstrated bypass — I confirmed
the old pattern really did accept a hardcoded-path checker, and that the replacement
rejects it while still passing the 15 real files for the right reason. The two new
findings are comment-accuracy debt introduced by S2; they can be swept into the W10
burst alongside the deferred G4 proof arm.
