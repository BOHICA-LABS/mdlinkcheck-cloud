# PR Review — Cycle 3 (fresh eyes)

**PR:** #7 `fix/ws3-spec-lint-integrity` → `develop`
**Story:** WS3-SPEC-LINT-INTEGRITY
**Head reviewed:** `791fc11e8b57e01326251daf0eb36dfffb59822a`
**Cycle 2 head:** `7e804432bd2d5593043323f0ca0bc91a86c26f2f`
**Verdict:** ✅ **APPROVE**

`covered_sha: 791fc11e8b57e01326251daf0eb36dfffb59822a`

---

## 1. Prior blockers — all resolved

### BLOCK-5 (cycle 2) — NV-1b teeth — ✅ CONFIRMED FIXED

This is the finding I spent the most effort on, because "add a test for the fix" is the
easiest place in a PR like this to ship something that looks like a guard and isn't one.
It is a real guard. I proved it by mutation rather than by reading it.

I reverted `_is_valid_vp_cell` in `scripts/spec-lint/check-placeholders.py` to the exact
pre-BLOCK-1 form:

```python
tokens = re.split(r"[,/]", first_cell)
return bool(tokens) and all(_VP_TOKEN_RE.match(t.strip()) for t in tokens if t.strip())
```

and re-ran the suite. Result:

```
── selftest NV-1:  em-dash in VP-NNN column (R2-RULE) ──
  PASS (clean-pass confirmed with FP-guard; em-dash ... correctly detected)
── selftest NV-1b: comma-only cell in VP-NNN column (BLOCK-1 guard) ──
  FAIL (checker returned 0 — did NOT catch comma-only cell in VP-NNN column)

Selftest FAILED: 1/55 negative tests failed
```

That is exactly the discrimination the fix claimed. NV-1 passes under the revert —
proving it structurally *cannot* guard the punctuation-only class, which is why splitting
the fixture was the right call and not just bookkeeping. NV-1b fails under the revert and
passes without it. The fixture separation (`bad-placeholder-vp-punctuation-only.md`
holding only `| , |`, with the em-dash row removed from `bad-placeholder-vp-emdash.md`)
is what makes the isolation real. Working tree restored to `791fc11` afterward, no diff.

### BLOCK-4 (cycle 2) — canonical-facts.toml state — ✅ CONFIRMED NOT-BLOCKING

The cycle-2 reviewer analyzed a stale branch. Verified independently:

```
$ git log --oneline -2 origin/factory-artifacts
7e0f02a factory(phase-1d): D-076..D-085 (exhaustive) — BI-042 .toml APPLIED; ...
17ed288 factory(phase-1d): D-075 session wrap — ...   <- what cycle 2 read
```

`7e0f02a` carries the D-076-corrected binding-25:

```toml
note    = "CAP-014 exit-2 condition — sole trigger parenthetical"
pattern = '\(sole trigger: ([^\n,]+?) pattern,'
```

I did not take the "corrected" label on faith — I ran both patterns against the three
vectors selftest 22/22b exercise:

| text | TAUTOLOGICAL (old) | PRODUCTION (D-076) |
|---|---|---|
| canonical | extracts `invalid \`--ignore\` glob` → match | extracts `invalid \`--ignore\` glob` → match |
| **prefix-extension** (`...glob or unrecognized flag...`) | extracts `invalid \`--ignore\` glob` → **match (FALSE NEGATIVE)** | extracts `invalid \`--ignore\` glob or unrecognized flag` → **DIVERGE** |
| complete replacement | no match → DIVERGE | extracts `unrecognized flag` → DIVERGE |

The bounded wildcard `([^\n,]+?)` is what closes the prefix-extension hole. The old
anchored literal was tautological in precisely the way BI-042 described. Selftest 22b is
therefore a genuine regression gate: reverting binding-25 makes it fail.

### BLOCK-1 / BLOCK-2 / BLOCK-3 (cycle 1) — re-verified at this head

- **BLOCK-1** — fix present at `check-placeholders.py:137`; empty tokens filtered *before*
  `all()`, so `all([])`-over-empty can no longer return vacuous `True`. Now guarded by NV-1b.
- **BLOCK-2** — fence scope correctly narrowed in both files. Only the structural R2/R3
  rules sit behind `if not in_fenced_code:`; `PLACEHOLDER_PATTERNS` (VP-TBD, SS-TBD,
  `[filled by]`) and all ID-resolution loops run regardless. Confirmed by reading control flow.
- **BLOCK-3** — selftests 22/22b derive the pattern from the *production* toml, resolving
  the `.factory` worktree via `git rev-parse --git-common-dir` so it works from any
  worktree. Correctly **fail-closed**: with `.factory` absent the suite aborts
  `FATAL: could not derive FACT-10 binding-25 pattern` and exits 1 rather than silently
  skipping. I hit this path accidentally during setup, which is good evidence it works.

---

## 2. Independent verification performed

| Check | Result |
|---|---|
| Full suite from worktree | **55/55 pass** |
| Structural guard: `TESTS_RUN == EXPECTED_TEST_COUNT` | present (`:3602`), exits 2 |
| Structural guard: `TESTS_WITH_CLEAN_PASS == TESTS_RUN` | present (`:3608`), exits 2 — no vacuous tests possible |
| BI-045 hermeticity, hostile ambient `SPEC_LINT_REPO_OVERRIDE=/tmp/bogus-nonexistent` | **55/55 pass** |
| BLOCK-1 mutation → NV-1b | **FAIL** (teeth confirmed) |
| BLOCK-1 mutation → NV-1 | PASS (confirms NV-1 cannot cover this class) |
| binding-25 pattern differential (3 vectors × 2 patterns) | corrected pattern strictly stronger |
| Required status checks on `791fc11` | Format ✅ Clippy ✅ Test (macOS) ✅ Build release (macOS) ✅ |
| `develop` branch protection required contexts (API) | `Spec lint` is **not** required — ADVISORY claim in PR body is accurate |
| `TV-BV013` finding triaged by hand | **true positive**, not an R3-A false positive |

The `TESTS_WITH_CLEAN_PASS == TESTS_RUN` guard deserves calling out. Every negative test
must first prove the checker exits 0 on a clean tree before injecting its defect. That
makes the whole suite resistant to the fixture-pollution failure mode where a test
"passes" because the tree was already dirty. This is the right structural invariant and
it is enforced, not merely documented.

### On the advisory spec-lint failure

Per the PR body I did not treat "spec-lint is failing" as a finding, but I did verify the
claim rather than accept it. Confirmed:

- `develop` required contexts are `Format check`, `Clippy (deny warnings)`,
  `Test (macos-latest)`, `Build release (macos-latest)` — all four green on this head.
- `Spec lint` was **already red on `develop`** (1/9 failing, 25 `[filled by]` occurrences)
  and has been since PR #2. This PR takes it to 2/9 — `check-id-resolution` newly fails
  with 10 findings, and `check-placeholders` grows 25 → 80.
- Every newly surfaced finding I sampled is a **true positive in `.factory/specs/**`**,
  a tree this PR cannot modify. Deferral to WS-4 under D-077 (detection precedes
  remediation) is coherent, and the PR body states it plainly rather than hiding it
  behind a green badge.

---

## 3. Findings — 0 blocking

### [SUGGESTION] `scripts/spec-lint/check-id-resolution.py:30` — docstring contradicts the code

The module docstring states R3-A fires on any table whose header first cell is
`"EC" or "ID"`. The implementation accepts only `"EC"`:

```python
# :396
if table_header_first_cell == "EC":
```

The `"ID"` exclusion is *deliberate and correct* — the inline comment explains that
`prd.md` uses `| ID | Differentiator |` with `KD-NNN` values, so admitting `ID` would
generate false positives. The problem is only that the docstring was never updated to
match. Anyone reading the module header will believe `ID`-headed tables are covered when
they are not, which is the kind of drift that later gets mistaken for a regression.

Suggest narrowing line 30 to `"EC"` and moving the `ID`-exclusion rationale up into the
docstring, where a reader looking for scope will actually find it.

### [SUGGESTION] `scripts/spec-lint/check-placeholders.py:131` — the D-078 `VP-NONE` branch has no test

`_is_valid_vp_cell` has three arms. Two are covered (conforming VP-NNN lists via the
`good-placeholder-vp-column.md` FP-guard; non-conforming via NV-1/NV-1b). The third is
untested:

```python
if first_cell == "VP-NONE":
    return bool(proof_method.strip())
```

`grep -rn "VP-NONE" scripts/spec-lint/selftest/` returns only a comment — no fixture
contains the sentinel. Neither arm is exercised: `VP-NONE` + non-empty Proof Method must
be *admitted*, and `VP-NONE` + empty Proof Method must be *rejected*.

This matters more than a generic coverage nit because BLOCK-1 was a hole in *this exact
function*, and the sentinel arm is the same risk class: a conditional whose false branch
silently admits. Two fixtures and one test would close it, and the suite's own
clean-pass discipline makes them cheap to add. Given this PR's thesis is selftest
integrity, an untested branch in the function that produced the last blocker is worth one
more test.

### [SUGGESTION] `scripts/spec-lint/check-placeholders.py:204` — Proof Method resolved by hardcoded index

```python
proof_method = cells[2] if len(cells) > 2 else ""
```

R2-RULE triggers on the header's *first* cell being `VP-NNN`; nothing constrains the rest
of the header. A VP table with an inserted column —
`| VP-NNN | Property | Notes | Proof Method |` — gates the `VP-NONE` sentinel on `Notes`
instead of `Proof Method`, so a `VP-NONE` row with an empty Proof Method but a non-empty
Notes cell would be wrongly admitted. No such table exists today, so this is latent, not
live. Resolving the column by matching the header cell to `Proof Method` would make the
rule shape-driven rather than position-driven, consistent with the D-039 structural-predicate
principle this PR argues for elsewhere.

Related, and already self-reported as WARN-2 in the PR body: R2-RULE covers only
`| VP-NNN |`-headed tables, leaving six `| VP |`-headed VP tables out of scope. Tracking
that as follow-up is the right call; I flag it only so it doesn't get lost.

### [NIT] `scripts/spec-lint/check-id-resolution.py:517` — R3-A/R3-B dedup breaks on strikethrough

The double-report suppression compares raw strings:

```python
if r3a_first_cell is not None and token == r3a_first_cell:
    continue
```

`_EC_ID_CELL_RE` is explicitly strikethrough-tolerant (`^~{0,2}EC-\d{1,4}[a-z]?~{0,2}$`),
so a first cell of `~~EC-NEW-1~~` is an anticipated input shape. For that shape
`r3a_first_cell` is `~~EC-NEW-1~~` while R3-B's token is `EC-NEW-1` — equality fails and
the same defect is reported twice, once per rule. Cosmetic only (exit code unchanged), but
duplicate findings inflate the WS-4 burn-down count. Comparing after `strip("~")` on both
sides fixes it.

### [NIT] Fence-delimiter line is skipped entirely in both checkers

Both files `continue` on the fence delimiter itself, so that one line is exempt from
`PLACEHOLDER_PATTERNS` and ID resolution as well as from R2/R3. A delimiter carrying an
info string (```` ```VP-TBD ````) would go unseen. Vanishingly unlikely in practice — I
note it only because it's a residual of the BLOCK-2 narrowing and the inline comment
("existing checks run regardless of `in_fenced_code`") is not quite true *on this line*.

### [NIT] PR description — EC burn-down count is 9, actual is 10

The body says "The 55 VP rows + 9 EC rows constitute a ..." but `check-id-resolution`
reports **10** findings: nine `EC-NEW-*` plus `TV-BV013` at
`.factory/specs/behavioral-contracts/ss-04/BC-2.04.001.md:63`.

I triaged `TV-BV013` by hand to rule out an R3-A false positive. It is a genuine defect —
a test-vector ID sitting in an Edge Cases table, in a row that is also ragged (three cells
in a two-column table):

```markdown
| EC | Description |
|----|-------------|
| EC-103 | Double-backtick span containing link syntax |
...
| TV-BV013 | BRIEF.md lines 18-19: inline code spans | Exit 0 (canonical self-test) |
```

Good catch by the new rule, and a nice demonstration that R3-A finds defects the
class-level R3-B grammar would miss (`TV` is not a registered family prefix). Worth
correcting the WS-4 scope to 10 rows so the burn-down doesn't come up one short.

### [SUGGESTION] `.github/workflows/ci.yml` — the 55-test suite is not wired into CI

`run-selftests.sh` — the central deliverable of this PR and the artifact that all five
prior blockers were adjudicated against — is not invoked by any workflow. The `spec-lint`
job runs the nine checkers directly and never calls the suite. Nothing in CI would catch
a broken selftest, a silently lowered `EXPECTED_TEST_COUNT`, or a fixture regression;
today that safety net exists only on the author's machine.

This is a pre-existing gap, not introduced here — but this PR adds 451 lines to the suite
and stakes its correctness argument on it, which changes the cost of leaving it unguarded.
The `spec-lint` job already checks out `factory-artifacts` into `.factory`, so the
`canonical-facts.toml` dependency is satisfied and this should be close to a one-line
addition:

```yaml
      - name: Run spec-lint selftests
        shell: bash
        run: bash scripts/spec-lint/selftest/run-selftests.sh
```

Given `spec-lint` is advisory, this could even be added as a *required* job — the suite is
hermetic (verified above against a hostile ambient `SPEC_LINT_REPO_OVERRIDE`) and
independent of the spec tree's outstanding violations, so it should be green today and
would stay green. That would give the checkers a real regression gate while the WS-4
burn-down proceeds.

---

## 4. Checklist

| # | Item | Result |
|---|------|--------|
| 1 | Diff coherence | ✅ All 9 files are spec-lint checkers, fixtures, or selftests. No unrelated changes. |
| 2 | Description accuracy | ✅ Accurate, including the advisory-CI framing, which I verified against branch protection. One off-by-one (nit above). |
| 3 | Test coverage | ✅ Every new rule has a negative test with a clean-pass assertion; two structural guards enforce count and clean-pass universality. One untested branch (suggestion above). |
| 4 | Demo evidence | N/A — spec-lint tooling, no user-facing surface. The 55/55 transcript plus the mutation-flip evidence is the appropriate artifact. |
| 5 | Commit quality | ✅ Conventional format, scoped to BI-/D-/BLOCK- IDs, one concern per commit. |
| 6 | Diff size | ⚠️ 871+/66− across 9 files (~937 lines), over the 500-line flag — but 451 lines are selftests and the checker changes are two focused files. Acceptable. |
| 7 | Missing changes | ✅ Spec-tree remediation (80 + 10 findings) deliberately deferred to WS-4 per D-077. Stated in the body, not concealed. |
| 8 | Dependency status | ✅ No upstream PR deps; #1–#6 merged to `develop`. |

---

## 5. Rationale

Approving. Both cycle-2 blockers are closed, and I confirmed each by independent
execution rather than by reading the fix:

- **BLOCK-5** — mutation-flipped `_is_valid_vp_cell` and observed NV-1b fail while NV-1
  passed. The claimed isolation is real, and the fixture split is what creates it.
- **BLOCK-4** — read `origin/factory-artifacts@7e0f02a` directly and ran a differential
  of the old and corrected binding-25 patterns across all three vectors. The cycle-2
  finding was against a stale tip; the corrected pattern is genuinely stronger.

The seven findings above are all non-blocking. Two are worth doing soon and are cheap: the
untested `VP-NONE` sentinel branch (same function that produced BLOCK-1), and wiring the
selftest suite into CI so the checkers gain a regression gate before the WS-4 burn-down
starts moving the spec tree underneath them. Neither is a merge blocker.

What raises my confidence beyond the diff itself: the suite's structural guards make
vacuous tests impossible by construction, and the binding-25 derivation fails closed
rather than skipping. Those are the properties that make the next reviewer's job easier,
and they are the reason the 55/55 result is worth something.

All four required status checks are green on `791fc11`. Advisory `spec-lint` remains red
by design, on a check that was already red on `develop`, with every new finding a true
positive in a tree outside this PR's reach.
