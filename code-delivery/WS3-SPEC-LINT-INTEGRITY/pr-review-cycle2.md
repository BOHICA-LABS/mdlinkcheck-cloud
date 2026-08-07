# PR Review — Cycle 2 — REQUEST_CHANGES

**PR:** #7 `fix/ws3-spec-lint-integrity` → `develop`
**Story:** WS3-SPEC-LINT-INTEGRITY
**Reviewed head SHA:** `7e804432bd2d5593043323f0ca0bc91a86c26f2f`
**Cycle-1 head SHA:** `70794e3bbdc4db968dd40674a94843476dc41559`
**Delta reviewed:** `git diff 70794e3..7e80443` (4 files, +144/-104) plus full re-verification of `git diff 7b9aa6d..7e80443` (8 files, +816/-66)

**Verdict: REQUEST_CHANGES** — 2 blocking findings. Both cycle-1 fixes BLOCK-1 (production predicate) and BLOCK-2 are **verified correct by mutation and differential testing**. BLOCK-3's derivation is also correct and demonstrably has teeth — but exercising those teeth exposes that the spec-side dependency it now reads has never been published, so the selftest suite is **53/54 on any clean checkout of this repository**.

---

## Cycle-1 finding disposition

| Cycle-1 finding | Status | How verified |
|---|---|---|
| BLOCK-1 — `_is_valid_vp_cell` all-over-empty hole | **Production fix CONFIRMED FIXED**; regression guard is inert (see BLOCK-5) | Direct unit probe of `_is_valid_vp_cell` over 18 inputs |
| BLOCK-2 — fence `continue` suppressed pre-existing checks | **CONFIRMED FIXED**, no regression | Differential run of base-`7b9aa6d` vs head checkers over the live spec tree |
| BLOCK-3 — selftests 22/22b used a hardcoded pattern snapshot | **Derivation CONFIRMED CORRECT and has teeth**; exposes an unlanded dependency (see BLOCK-4) | Isolated clone + worktree resolution test + teeth test |

---

## BLOCKING FINDINGS

### BLOCK-4 — Selftests 22/22b now depend on an unpublished `canonical-facts.toml` change; suite is 53/54 on a clean checkout

| Field | Value |
|---|---|
| Severity | **blocking** |
| Category | test-integrity / reproducibility |
| File | `scripts/spec-lint/selftest/run-selftests.sh:1105-1131` |

Commit `7e80443` replaces the hardcoded binding-25 pattern in the `TOML22` / `TOML22B` heredocs with a value derived at test time from `.factory/specs/canonical-facts.toml`. That derivation is implemented correctly. The problem is what it derives.

**Reproduction — from published repository state only:**

```
$ D=$(mktemp -d)/c
$ git clone <this repo> "$D"
$ cd "$D" && git checkout fix/ws3-spec-lint-integrity
$ git worktree add .factory factory-artifacts     # exactly what ci.yml:220-225 does
$ bash scripts/spec-lint/selftest/run-selftests.sh
...
── selftest 22b: check-canonical-facts: FACT-10 binding-25 — prefix-extension vector DIVERGE (BI-042) ──
  FAIL (checker returned 0 — prefix-extension adversarial text should DIVERGE)

Selftest FAILED: 1/54 negative tests failed
```

The derived pattern differs depending on where you run it:

| Location | Derived FACT-10 binding-25 pattern |
|---|---|
| Author's working tree | `\(sole trigger: ([^\n,]+?) pattern,` |
| `factory-artifacts` @ `17ed288` (published tip, `origin` == local) | `sole trigger: (invalid ` + "`" + `--ignore` + "`" + ` glob)` |

The second value is the **tautological form** that BI-042/D-076 exists to eliminate — and it is what every consumer of this repository will get. The D-076 remediation of `specs/canonical-facts.toml` is an **uncommitted working-tree modification** in the author's `.factory` worktree; it is not on `origin/factory-artifacts`.

**Why this is blocking, not merely cosmetic:**

1. **This PR causes a green→red transition on a clean checkout.** At `70794e3` the heredoc carried a literal snapshot, so `just spec-lint-selftest` passed 54/54 anywhere. At `7e80443` it fails 53/54 anywhere except the author's machine. That is a selftest-integrity regression introduced by this cycle, which is inside the blocking scope your own reviewer guidance defines.
2. **The pre-merge checklist claim `[x] Selftests 54/54 pass hermetically` is not reproducible.** `just spec-lint-selftest` is the documented local gate (`justfile:230`). It is red for every other developer and every fresh agent worktree.
3. **`[x] No spec content changed (.factory/ not in diff)` is now in tension with reality.** The diff genuinely contains no `.factory/` change, but the PR has acquired a hard runtime dependency on an unlanded one. Merging this before that lands leaves `develop` with a permanently failing local gate.
4. It is fail-*open* in the wrong direction for the property the test claims to guard: the suite is not asserting "binding-25 is correct," it is asserting "whatever binding-25 says, prefix-extension is caught" — and against published state it is not caught, silently, until someone runs the suite.

**Note this is *not* a CI break.** `run-selftests.sh` is not invoked by any workflow (`grep -rn selftest .github/` → no hits; only `justfile:230`). The required checks are unaffected.

**Suggested fix — pick one:**

- **(preferred)** Commit and push the D-076 `specs/canonical-facts.toml` correction to `factory-artifacts` *before* merging #7, then re-run and re-attest the suite from a clean clone. This makes the checklist claim true and keeps the teeth.
- Or gate the merge explicitly on that landing order and say so in the PR body, so the sequencing hazard is recorded rather than implicit.
- Either way, please re-state the test-evidence row as **"54/54 from a clean clone with `factory-artifacts` at `<sha>`"** rather than an unqualified 54/54, so the claim is falsifiable by a reviewer.

---

### BLOCK-5 — The `| , |` regression guard added for BLOCK-1 has no teeth (vacuous test)

| Field | Value |
|---|---|
| Severity | **blocking** |
| Category | test-integrity |
| File | `scripts/spec-lint/selftest/fixtures/bad-placeholder-vp-emdash.md:17`, `scripts/spec-lint/selftest/run-selftests.sh:3348-3381` |

The production fix is right — I probed `_is_valid_vp_cell` directly and it is sound:

```
','   -> False    ',,'  -> False    '/'   -> False    '//'  -> False
',/'  -> False    ' , ' -> False    '—'   -> False    ''    -> False
'VP-001' -> True  'VP-001, VP-018' -> True  'VP-NONE' -> True
'VP-0011' -> False  'vp-001' -> False  'VP-1' -> False  'TBD' -> False
```

But the fixture row added to lock it in is inert. The `| , |` row was appended to `bad-placeholder-vp-emdash.md`, which **already contains the `| — |` row**, and selftest NV-1 asserts only that the checker exits non-zero. The em-dash row fires under both the buggy and the fixed predicate, so the comma row contributes zero detection power.

**Mutation proof.** I reverted `_is_valid_vp_cell` to the exact pre-BLOCK-1 buggy form:

```python
tokens = re.split(r"[,/]", first_cell)
return bool(tokens) and all(_VP_TOKEN_RE.match(t.strip()) for t in tokens if t.strip())
```

and re-ran the suite:

```
Selftest passed: 54/54 negative tests verified (each proved clean-pass + defect-fail)
EXIT=0
```

The BLOCK-1 defect can be fully reintroduced with the suite still green. The row's own comment calls itself a "regression guard (all-over-empty hole in `_is_valid_vp_cell`)" — it is not one.

This matters more than usual in this PR specifically: the file header asserts *"This two-step pattern makes a vacuous test case structurally impossible"* (`run-selftests.sh:9-11`), and BI-042 in this very PR exists to kill a tautological test. Shipping a self-described regression guard that a mutation test walks straight through is the same anti-pattern under a new name.

**Suggested fix.** Move the comma row into its own fixture and give it its own clean-pass/defect-fail case, e.g.:

```
scripts/spec-lint/selftest/fixtures/bad-placeholder-vp-punctuation-only.md
  | VP-NNN | Property | Proof Method |
  |--------|----------|-------------|
  | , | comma-only (BLOCK-1 regression guard) | unit test |
```

then add a discrete `TESTS_RUN` case that copies only that fixture and asserts non-zero exit (bump `EXPECTED_TEST_COUNT` 54 → 55). Alternatively, keep one fixture but assert the **finding count** is 2, not just the exit code — the existing tests already grep output (see selftest 22b), so the pattern is available.

---

## VERIFIED CLEAN — what I confirmed, with evidence

### BLOCK-2 fix: confirmed, zero regressions

I reconstructed the base-`7b9aa6d` checkers, dropped them into `scripts/spec-lint/` so their `REPO` resolution was correct, and ran base vs. head over the same spec tree:

| Checker | base `7b9aa6d` | head `7e80443` | base findings lost in head |
|---|---|---|---|
| `check-placeholders.py` | 25 (`[filled by …]`) | 80 (25 `[filled by]` + 55 R2 em-dash) | **0** |
| `check-id-resolution.py` | 0 (`134 files checked — all ID references resolve`) | 10 | **0** |

All 25 pre-existing `[filled by story-writer]` findings survive verbatim, which is the direct evidence that `PLACEHOLDER_PATTERNS` again runs on fenced content. The head counts reproduce the PR's claimed 80 and 10 exactly.

I also confirmed the base checkers had **no** fence tracking at all (`git show 7b9aa6d:… | grep fenced` → no hits), so restoring base behaviour for pre-existing checks is the correct target, and that the gate is correctly narrow:

- `check-placeholders.py:189` — only the R2-RULE table state machine is inside `if not in_fenced_code:`; `PLACEHOLDER_PATTERNS` at line 225 is outside it.
- `check-id-resolution.py:388` and `:511` — only R3-A table tracking and the R3-B `_WOULD_BE_ID_RE` loop are gated; the CAP/DI/DD/VP/NFR/BC/ADR/HS/POL resolution loops from line 431 are outside.
- Fence open/close resets table state and `continue`s (`:375-379`, `:179-184`), so a table cannot span a fence boundary in either file.
- Moving the D-081 `### vN.N` heading state update inside the fence gate is an improvement, not a regression: a heading inside a code fence no longer flips section scope. NV-5 still passes and no base finding was lost.

### BLOCK-3 fix: derivation correct, worktree-portable, teeth proven

- **Reads production, not a snapshot** — confirmed. The derivation opens `<main-checkout>/.factory/specs/canonical-facts.toml` at test time.
- **`--git-common-dir` works in both contexts** — verified:
  - story worktree: `git rev-parse --git-common-dir` → `/Users/…/mdlinkcheck-cloud/.git` (absolute) → `_MAIN_REPO=/Users/…/mdlinkcheck-cloud` ✓
  - main checkout: returns relative `.git`, normalized by the `!= /*` branch ✓
  - CI layout (`ci.yml:220-225` checks `factory-artifacts` out to `./.factory`): `<workspace>/.git` → `<workspace>/.factory/specs/…` ✓
- **Teeth confirmed** — this is the strongest evidence in the review. Against the published binding, selftest 22b **FAILS**. The test genuinely discriminates the corrected pattern from the tautological one; that is exactly the property BLOCK-3 asked for. (It is also precisely what produces BLOCK-4.)
- **Note discriminator resolves uniquely** — of the 7 `FACT-10` bindings, exactly one note contains `sole trigger parenthetical`, so `assert len(pats) == 1` holds.
- **`tomllib` / `tomli` fallback is fail-closed** — an uncaught `ImportError` (or `FileNotFoundError`, or the `assert`) exits non-zero with empty stdout, so `BINDING25_PATTERN` is empty and the `[ -z … ]` guard at `:1129` hard-exits 1. No silent skip. Good.
- **Unquoted heredoc escaping is correct today** — the backticks in `canonical_value` are properly escaped to `\`` and the interpolated pattern contains no `$`, backtick, or `'`. Variable expansion is not recursive, so a `$` anchor inside a future pattern would also be safe. (See SUGGESTION-2 for the residual `'` case.)

### Advisory spec-lint failure — NOT blocking, confirmed as D-077 intent

I read the CI log rather than taking the PR's word for it. Job `92867576043`: **7 of 9 validators PASS**; only `check-id-resolution` and `check-placeholders` fail — i.e. exactly the two checkers this PR sharpens. `check-canonical-facts` **PASSES**. All required checks are green (Format, Clippy, Test macos, Build release macos, GitGuardian). This is the D-077 outcome as described.

---

## SUGGESTIONS

### SUGGESTION-1 — PR description is stale; commit `7e80443` is undocumented

| Field | Value |
|---|---|
| Severity | suggestion |
| Category | description |

The body says **"What Changed (4 commits, 8 files, +774/-64)"**. Actual: **5 commits, 8 files, +816/-66**. The entire cycle-2 remediation commit `7e80443` — the BLOCK-1/2/3 fixes, the single most review-relevant change on the branch — has no section in the PR body. A human maintainer reading only the description would not know these fixes exist, nor that selftests 22/22b now read `.factory` at test time.

Please add a `### 7e80443 —` section covering all three fixes and correct the header counts. The new `.factory` read dependency in particular belongs in the body, not only in a shell comment.

### SUGGESTION-2 — Generate the selftest TOML from Python instead of interpolating into a shell heredoc

| Field | Value |
|---|---|
| Severity | suggestion |
| Category | robustness |
| File | `scripts/spec-lint/selftest/run-selftests.sh:1140`, `:1198` |

`pattern = '$BINDING25_PATTERN'` interpolates an arbitrary regex into a **TOML single-quoted literal string**, which cannot contain `'`. Regexes containing a single quote are common. If binding-25 ever acquires one, the generated `canonical-facts.toml` is malformed, `check-canonical-facts` errors on the clean tree, and the operator sees `STRUCTURAL FAIL: checker failed on clean FACT-10 tree (Phase A)` — a message that points nowhere near the real cause. Multi-line patterns fail the same way.

Since a Python interpreter is already in this code path, have it emit the whole file with correct quoting:

```bash
python3 - "$_MAIN_REPO/.factory/specs/canonical-facts.toml" "$T/.factory/specs/canonical-facts.toml" <<'PY'
# ... derive pattern, then write the selftest TOML with proper escaping
PY
```

This also lets you drop the `\`` escaping in `canonical_value` and revert both heredocs to the safer quoted `<<'TOML22'` form.

### SUGGESTION-3 — Distinguish "not a git repo" from "relative git-common-dir"

| Field | Value |
|---|---|
| Severity | suggestion |
| Category | robustness |
| File | `scripts/spec-lint/selftest/run-selftests.sh:1109-1113` |

```bash
_GIT_COMMON=$(git -C "$REPO" rev-parse --git-common-dir 2>/dev/null)
if [[ "$_GIT_COMMON" != /* ]]; then
    _GIT_COMMON="$(cd "$REPO/$_GIT_COMMON" && pwd)"
fi
```

If `git rev-parse` fails (repo exported as a tarball, `git` absent, `$REPO` outside a work tree), `_GIT_COMMON` is empty, the `!= /*` test is true, `cd "$REPO/"` succeeds, and `_MAIN_REPO` silently becomes `dirname($REPO)` — a wrong path that surfaces as the generic `FATAL: could not derive …` message. Fail-closed, but the diagnostic misdirects. Add an explicit branch:

```bash
if [[ -z "$_GIT_COMMON" ]]; then
    echo "FATAL: $REPO is not inside a git work tree — cannot locate .factory worktree" >&2
    exit 1
fi
```

### SUGGESTION-4 — Free-text `note` is a fragile key into `canonical-facts.toml`

| Field | Value |
|---|---|
| Severity | suggestion |
| Category | maintainability |
| File | `scripts/spec-lint/selftest/run-selftests.sh:1121-1126` |

The derivation keys on `"sole trigger parenthetical" in b.get("note", "")`. `note` is human-facing prose with no stability contract. Rewording it — or adding any other FACT-10 binding whose note happens to contain that phrase — trips `assert len(pats) == 1` and hard-fails the **entire 54-case suite** at line 1131, before any test runs, with a message that names a pattern rather than a note. Fail-closed and honest, but a stable machine key (an explicit `id = "binding-25"` field on the binding, matched exactly) would make this robust and self-documenting. The inline comment already acknowledges the ambiguity it is working around.

---

## NITS

| # | File | Finding |
|---|---|---|
| NIT-1 | `check-placeholders.py:208-214` | Stream-of-consciousness comment block retained verbatim, including a self-correction mid-comment: *"…but we do that by not continuing here. **Actually:** run PLACEHOLDER_PATTERNS on the full line…"*. Six lines of contradictory reasoning where one declarative sentence would do. Collapse to: *"No `continue` here: PLACEHOLDER_PATTERNS must still run on this row so VP-TBD in the Property/Proof Method cells is caught."* |
| NIT-2 | `check-placeholders.py:137` | A trailing separator is accepted as conforming: `_is_valid_vp_cell("VP-001,", …)` → `True`. Harmless for POL-14 but arguably a formatting defect the shape-whitelist could catch for free. |
| NIT-3 | whole diff | +816/-66 = 882 lines, above the 500-line review threshold. Fine in substance — ~500 of those lines are selftest cases and fixtures, and the checker changes themselves are small and focused. Recorded for the diff-size checklist item only. |

---

## Checklist coverage

| # | Item | Result |
|---|---|---|
| 1 | Diff coherence | **PASS** — all 4 delta files are checker/selftest scoped; no unrelated changes, no Rust, no `.factory/` in the diff |
| 2 | Description accuracy | **SUGGESTION-1** — stale counts, cycle-2 commit undocumented, new `.factory` read dependency unstated |
| 3 | Test coverage of changed lines | **BLOCK-5** — BLOCK-1's guard is inert (mutation-proven); BLOCK-2 covered by differential run + NV-1/3/4/5; BLOCK-3 covered by 22/22b and teeth-proven |
| 4 | Demo evidence | **N/A accepted** — no `docs/demo-evidence/` in repo; CLI-only checker tooling, evidence is selftest output + exit codes. Reasonable. |
| 5 | Commit quality | **PASS** — all 5 conventional, scoped, with issue IDs; `7e80443` names its three findings |
| 6 | Diff size | **NIT-3** — 882 lines, justified |
| 7 | Missing changes | **BLOCK-4** — the `canonical-facts.toml` D-076 correction the suite now depends on is not published |
| 8 | Dependency status | **PASS** — #1–#6 merged; no upstream PR blockers. But see BLOCK-4: there is an unlanded *artifact* dependency. |

---

## Summary

Cycle 2 is genuinely good work on the code itself. BLOCK-1's predicate is sound under direct probing, BLOCK-2's fence gate is provably regression-free against the base checkers, and BLOCK-3's derivation is portable across worktrees and demonstrably has teeth. I could not find a logic bug in any of the three fixes, and I could not find a false positive or a lost pre-existing finding.

What blocks merge is one gap and one soft spot, both mechanical:

1. **BLOCK-4** — BLOCK-3's teeth work, and the first thing they bite is the repository's own published `canonical-facts.toml`, which still carries the tautological binding-25. The suite is red on every clean checkout and the `54/54 hermetic` checklist claim is not reproducible. Land the D-076 spec correction (or fix the merge order) and re-attest from a clean clone.
2. **BLOCK-5** — the comma-only row added to close BLOCK-1 is masked by the em-dash row in the same fixture. Reverting the production fix still yields 54/54. Split the fixture or assert the finding count.

Both are small. Neither undoes the cycle-2 work — they finish it. Re-review should be quick once the spec correction is published and the guard is given teeth.

*No `covered_sha` is issued — verdict is REQUEST_CHANGES.*
