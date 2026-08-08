# Independent Review — PR #10 @ `a14711e1a3dd8e0181234df472392c5ba89c21f7`

**PR:** `fix/s3-test-sufficient-proof-method` → `develop` (`d4e76fa`)
**Scope:** closes review finding **S3** from the PR #9 cycle-3 review (D-100 follow-on)
**Reviewer authority:** verdict + evidence only. No merge authority. `gh pr review --approve` /
`--request-changes` were **not** attempted (self-authored PR; GitHub refuses self-approval) and
no `covered_sha` field was touched.

---

## VERDICT: APPROVE (no blocking defects)

**Basis:** the fix is correct, genuinely symmetric with `VP-NONE`, correctly ordered after the
VP-INDEX cross-check, bounded to 7 lines in one function, and locked by a non-vacuous selftest
whose kill I proved **guard-independent** by executed composite experiment. Real-corpus output is
**byte-identical** to pre-fix. Every finding below is a suggestion, a nit, or a pre-existing
condition inherited from `develop` — none is attributable to this diff.

### Severity ranges (PG-012)

| Severity | Count range |
|---|---|
| BLOCKING | **0** |
| SUGGESTION | **2–3** |
| NIT | **2–4** |
| Informational / out-of-scope observation | 2–3 |

---

## Harness non-vacuity discipline

Every mutation below records all three mandated artefacts. The mutation driver
(`/tmp/s3probe/mutate.py`) **asserts the search text occurs exactly once and refuses to write
otherwise** — this structurally closes the silent-zero-match `str.replace` failure mode that
produced a near-miss vacuous result earlier in this repo. All mutations were applied **inside the
worktree**, reverted with `git checkout -- <file>`, and each restore was verified by comparing
`git hash-object <file>` against `git rev-parse HEAD:<file>` (not merely by `git status`).

**Control (no mutation):**

```
bash scripts/spec-lint/selftest/run-selftests.sh
  → EXIT=0
  → Selftest passed: 69/69 negative tests verified (each proved clean-pass + defect-fail)
  → grep -c 'selftest P14-'  ==  14
```

Pre-flight guards, from the control log (executed, not read):

```
Pre-flight guard passed: 15 checkers/generators support SPEC_LINT_REPO_OVERRIDE
Pre-flight structural guard: checking for hardcoded suppression allowlists in all checkers...
Pre-flight guard passed: 15 checkers/generators scanned, 0 suppression constructs found
Pre-flight guard passed: 15 files checked, 0 raw .splitlines() uses
── guard selftest G2: suppression-allowlist pre-flight guard fires ──
  PASS (clean-pass confirmed; guard correctly detects KNOWN_COLLISIONS suppression allowlist)
```

The suppression guard is itself proven live by G2 — it is not a decorative check.

---

## 1. Is the fix correct and genuinely symmetric with `VP-NONE`?

**Yes.** Both paths now gate on the identical predicate, `proof_method.strip()`:

```python
# test-sufficient (new, after the JOIN)
if not bool(proof_method.strip()):
    return False, (... "Proof Method cell must be non-empty (D-078 precondition)")
return True, ""

# VP-NONE (pre-existing, D-078)
if bool(proof_method.strip()):
    return True, ""
return False, "non-conforming VP-NNN column value 'VP-NONE' (POL-14)"
```

**Placement is correct and load-bearing.** The guard sits *after* all three VP-INDEX
cross-checks (`bc_id is None`, `bc_id not in vp_classifications`, `classification !=
"test-sufficient"`). Probes P4 / P4b / P4c below confirm empirically that a non-test-sufficient
BC still receives its specific VP-INDEX message and **never** the new Proof-Method message — even
when the Proof Method is *also* empty (P4). Had the guard been placed before the JOIN, P4 would
have emitted the misleading D-078 message; it does not.

**Message quality:** accurate and actionable — names the sentinel, the policy (POL-14), the
required condition, and the governing decision (D-078). It is greppable positive grammar, not a
skip-set (D-078 / D-039 compliant).

**Scope:** bounded. `git diff d4e76fa..a14711e --numstat` = `7/0` in `check-placeholders.py`,
`67/1` in `run-selftests.sh`, nothing else. `spec_lint_primitives.py` diff is **0 lines** and its
blob hash matches HEAD. No redesign of sentinel logic, the VP-INDEX JOIN, or the Stories-field
exemption. **No scope creep.**

---

## 2. Is P14-14 non-vacuous, discriminating, and guard-independent?

**Yes to all three.**

- **Both halves present.** Clean-pass assertion (`test-sufficient` + non-empty Proof Method +
  VP-INDEX agreement → exit 0, increments `TESTS_WITH_CLEAN_PASS`) *and* defect-fail assertion
  (empty Proof Method → non-zero exit **and** the D-078 message must appear in output). The
  defect assertion is message-matched via `grep -qF`, not merely exit-code-matched, so it cannot
  be satisfied by an unrelated failure.

- **Both halves discriminate (executed):**

  | Mutant | Definition | Suite exit | P14 count | Failing test(s) | Verdict |
  |---|---|---|---|---|---|
  | `S3G` | `if not bool(proof_method.strip()):` → `if False:` | **1** | 14 | **P14-14** (sole) | KILLED |
  | `S3G2` | same line → `if True:` (guard always fires) | **2** | 14 | **P14-14**, P14-3 (clean-pass) | KILLED |

  `S3G` kills the **defect-fail** half; `S3G2` kills the **clean-pass** half. Both halves are
  therefore live. `git diff` proof was captured for each before the run.

- **Guard-independence — proven by executed composite, not asserted.** I neutralised the
  suite-wide structural guard (`if [ "$TESTS_WITH_CLEAN_PASS" -ne "$TESTS_RUN" ]` → `if false;`)
  and ran both arms:

  | Arm | Guard | Code | Exit | P14 count | Result |
  |---|---|---|---|---|---|
  | A (control) | weakened | unmutated | **0** | 14 | 69/69 — control is *not* itself failing |
  | B | weakened | `S3G` | **1** | 14 | **P14-14 sole failure** |

  Arm A is the essential control: it proves arm B's exit 1 is attributable to the mutation and
  not to guard tampering. **P14-14's kill does not depend on the suite-wide clean-pass guard.**
  Mechanistically consistent: `S3G` exits **1** via `FAILURES`, whereas the structural guard
  exits **2** — different code paths.

---

## 3. Direct behavioural probes (all four required, plus ten more)

Independently constructed fixture trees via `SPEC_LINT_REPO_OVERRIDE`; not the PR's own fixtures.

| # | Row | VP-INDEX says | Result | Message |
|---|---|---|---|---|
| **P1** | `\| test-sufficient \| p \|  \|` | `test-sufficient` | **REJECTED** (exit 1) | `… 'test-sufficient' (POL-14) — Proof Method cell must be non-empty (D-078 precondition)` |
| **P2** | `\| test-sufficient \| p \| unit test \|` | `test-sufficient` | **ACCEPTED** (exit 0) | — |
| **P3** | `\| VP-NONE \| p \|  \|` | `test-sufficient` | **REJECTED** (exit 1) | `… 'VP-NONE' (POL-14)` |
| **P4** | `\| test-sufficient \| p \|  \|` | `VP-001` | **REJECTED** (exit 1) | `… VP-INDEX classifies 'BC-0.00.004' as 'VP-001'; remove the sentinel and cite the real VP` |

All four required probes behave exactly as specified. **P4 is the decisive ordering probe:** an
empty Proof Method *and* a VP-INDEX disagreement together still yield the **VP-INDEX** message.

Supplementary probes:

| # | Case | Result |
|---|---|---|
| P3b | `\| VP-NONE \| p \| manual review \|` | ACCEPTED (VP-NONE path unregressed) |
| P4b | `test-sufficient`, index `VP-001`, full Proof Method | REJECTED — VP-INDEX message |
| P4c | `test-sufficient`, BC **absent** from VP-INDEX, empty PM | REJECTED — `has no row in VP-INDEX` message (not the new one) |
| P5 | `\| test-sufficient \| p \|     \|` (5 spaces) | **REJECTED** — D-078 message |
| E6 | Proof Method = single NBSP (`U+00A0`) | **REJECTED** — D-078 message |
| P8 | truncated 2-cell row `\| test-sufficient \| p \|` | REJECTED — D-078 message (`cells[2]` defaults to `""`) |
| P10 | `\| VP-001 \| p \|  \|` (real token, empty PM) | ACCEPTED — real-VP rows correctly unaffected |

---

## 4. Regression

**Real corpus: exactly 53. Verified by execution, and verified *identical* to pre-fix.**

```
SPEC_LINT_REPO_OVERRIDE=<repo> python3 scripts/spec-lint/check-placeholders.py
  → exit 1
  → 53  non-conforming VP-NNN column value '—' (POL-14)
  → Check FAILED: 53 placeholder occurrences found (133 files checked)
```

I did not stop at the count. I extracted `develop`'s pre-fix checker
(`git show d4e76fa:scripts/spec-lint/check-placeholders.py`, run as an untracked sibling so the
`spec_lint_primitives` import resolved, then removed) and diffed the two full outputs:

```
diff <pre-fix output> <post-fix output>   →   IDENTICAL
```

Not just an equal count — the same 53 findings at the same file:line coordinates. This is the
strongest available evidence for the D-100 timing claim: **the new guard rejects no legitimate
row today.** The hole is closed prospectively, before the 53 em-dash rows are rewritten to the
sentinel across 33 BC files.

**PR #9 mutant coverage — all six re-verified dead.** My first formulations of `M8` and `MX3`
diverged from PR #9's canonical definitions, so I retrieved the canonical wording from PR #9's
body and re-ran both (`M8c`, `MX3c`). The initial mis-formulations are disclosed in the
observations section rather than quietly dropped.

| Mutant | Canonical definition | Exit | P14 count | Failing test(s) | Verdict |
|---|---|---|---|---|---|
| `M4` | delete the Shape 2 branch entirely | **2** | 14 | P14-8/9/10/11/12/13 (guard: 64/69 clean-pass) | KILLED |
| `M8c` | drop the `current_h2_heading == "Story Anchor"` condition | **1** | 14 | P14-8, P14-9, P14-10, P14-12, P14-13 (5/69) | KILLED |
| `MS1` | delete `else: current_h2_heading = None` | **1** | 14 | P14-10, P14-12 (2/69) | KILLED |
| `MX1` | `if _atx_rest.startswith(" ") or not _atx_rest:` → `if True:` | **2** | 14 | P14-12 (guard: 68/69 clean-pass) | KILLED |
| `MX3c` | `line.startswith("## ")` → `line.startswith("#")` | **1** | 14 | P14-13 (1/69) | KILLED |
| `MB` | drop the bullet-prefix condition | **1** | 14 | P14-11 (1/69) | KILLED |

All six match PR #9's recorded kill signatures. **No PR #9 coverage regressed.** `git diff` proof
and a clean-restore blob check were captured for every row.

**Item 6 — no pre-existing selftest removed or loosened.** The entire `run-selftests.sh` diff
contains exactly **one** deleted line:

```
-EXPECTED_TEST_COUNT=68
```

Everything else is a pure append. No assertion anywhere was weakened.

**Item 7 — D-039 clean.** A case-insensitive scan of the full diff for
`allowlist|allow_list|whitelist|skip.?list|deferral|known.?issue|exempt.?list|ignore.?list|expected.?fail|xfail|@skip|waiver|suppress`
returned **NONE FOUND**. All three pre-flight guards pass (see control log above), and the
suppression guard is proven live by selftest G2.

---

## 5. Whitespace and punctuation-placeholder findings

**Whitespace-only: rejected — confirmed by execution (P5, E6).** But the mechanism is worth
recording precisely, because it is not what it appears to be. `slp.split_table_cells` already
strips each cell:

```
'| test-sufficient | p |  |'     -> ['test-sufficient', 'p', '']
'| test-sufficient | p |     |'  -> ['test-sufficient', 'p', '']
```

`proof_method` is therefore **always pre-stripped** at the only call site. I tested whether the
`.strip()` in the new guard is load-bearing by mutating it away (`S3G3`:
`proof_method.strip()` → `proof_method`) and re-running the probes: P1, P5 and P8 were **still
rejected**, and the suite still passed 69/69. `S3G3` is an **equivalent mutant** — its survival
is *not* a coverage gap, and I am explicitly withdrawing that as a finding rather than reporting
a scary-sounding survivor I could not stand behind. The `.strip()` is redundant defence-in-depth
that exactly mirrors the pre-existing `VP-NONE` line; keeping it is the right call for symmetry.

**Punctuation placeholders: ACCEPTED.** Executed:

| Proof Method | `test-sufficient` | `VP-NONE` |
|---|---|---|
| `—` (em-dash) | ACCEPTED | ACCEPTED |
| `–` (en-dash) | ACCEPTED | — |
| `n/a` | ACCEPTED | ACCEPTED |
| `TBD` | ACCEPTED | ACCEPTED |
| `.` | ACCEPTED | — |

**My scope position: OUT OF SCOPE for S3, and it must be a separate follow-up covering both
sentinels together.** Three reasons:

1. **S3 as filed is an *asymmetry* defect,** not a content-quality defect. Its precise claim is
   that `test-sufficient` lacked the non-empty precondition that `VP-NONE` had. That asymmetry is
   now fully closed. Widening S3 to cover placeholder *content* would change the finding's
   identity mid-flight.
2. **The gap is symmetric and pre-existing.** Every accepted-placeholder case above reproduces
   identically on the `VP-NONE` path on `develop`. Fixing it on only the new path would
   *reintroduce* an asymmetry — the exact class of defect S3 exists to eliminate.
3. **It is a different kind of check.** Non-emptiness is a structural predicate. "Is this string
   a real proof method?" is a content predicate requiring a positive grammar (or at minimum a
   negative-token set), and a naive `—`/`TBD` blocklist would drift toward the skip-set shape
   D-078 forbids. It deserves its own decision record, not a bolt-on.

Recommended follow-up (not a condition of this merge): a single bounded change applying one
shared non-placeholder predicate to **both** sentinel branches, with paired selftests per branch.

---

## Findings

### SUGGESTION-1 — the `VP-NONE` precondition this PR mirrors has **zero** test coverage

`scripts/spec-lint/check-placeholders.py` ~L208–211 (pre-existing; **not** introduced here)

Mutant `VPN2` deletes the entire `VP-NONE` D-078 precondition:

```python
-        if bool(proof_method.strip()):
-            return True, ""
-        return False, "non-conforming VP-NNN column value 'VP-NONE' (POL-14)"
+        return True, ""
```

Result: **suite exits 0, 69/69, P14 count 14 — the mutant SURVIVES.** I confirmed it is *not*
equivalent: under `VPN2`, probe P3 (`| VP-NONE | p |  |`) flips from REJECTED to **ACCEPTED**.
`grep -c 'VP-NONE' run-selftests.sh` returns **2**, and both hits are comments — no fixture
exercises the sentinel.

This is the ironic shape of the finding: this PR adds the *derived* precondition **with** a
discriminating test (P14-14) while the *reference* precondition it cites as precedent has none.
Under D-040 / D-050 / D-057 — runtime positive-coverage assertions are the durable criterion,
mutation verification necessary but not sufficient — someone could silently delete D-078's
enforcement tomorrow and the suite would stay green. **Pre-existing on `develop`; not a blocker
for this PR. Recommend a `P14-15` covering `VP-NONE` empty-Proof-Method as a follow-on.**

### SUGGESTION-2 — the 69-test selftest suite is never executed in CI

`.github/workflows/ci.yml` L206–266

The `spec-lint` job runs exactly nine `check-*.py` validators. `grep -rn 'selftest\|run-selftests'
.github/workflows/` finds **no invocation of `scripts/spec-lint/selftest/run-selftests.sh`**.
Consequence: P14-14 — and all 69 tests, and all three pre-flight structural guards — have **no
automated enforcement path**. Their only execution is a manual operator run. The mutation
evidence in this PR is real, but nothing in CI will reproduce it or catch its regression.
**Pre-existing; a separate CI-wiring change. Flagging because it bounds how much durable
protection P14-14 actually buys.**

### SUGGESTION-3 (borderline / nit) — docstrings not updated for the new precondition

`scripts/spec-lint/check-placeholders.py` L16–19, L30–37, L163–167

Three places still describe `test-sufficient` acceptance as gated *only* on the VP-INDEX
cross-check:

- module docstring L16–19: `'test-sufficient' (ONLY when VP-INDEX classifies that BC as test-sufficient — cross-checked at runtime)`
- module docstring L30–37 (Operator-ruled exemptions): `Accepted ONLY when VP-INDEX classifies the file's BC ID as 'test-sufficient'.`
- function docstring L163–167: `- 'test-sufficient' sentinel, ONLY when VP-INDEX classifies the BC as test-sufficient`

Compare L163 immediately above, which *does* spell out the `VP-NONE` condition
(`ONLY when proof_method is non-empty (D-078)`). The asymmetry S3 removed from the code now
persists in the prose. The inline comment at the guard itself is good; the three summary sites
are stale. One-line each.

### NIT-1 — redundant `.strip()` (documented, keep as-is)

`scripts/spec-lint/check-placeholders.py` L200. `proof_method` is pre-stripped by
`slp.split_table_cells`, so `.strip()` cannot change any outcome at the only call site (proven by
equivalent mutant `S3G3`). **Recommend keeping it** — it mirrors `VP-NONE` exactly and protects
against a future caller that bypasses the splitter. Recorded only so no future reader mistakes it
for whitespace-handling coverage.

### NIT-2 — `Spec lint` CI check is red, and is expected to be

Both PR #10 runs show `Spec lint fail`. The failure is the 53 em-dash findings — **pre-existing on
`develop`** (`gh run list --branch develop` shows CI failing at `d4e76fa`, `c2e5cf1`, `e1299b0`
and every prior commit) and the exact condition D-100 exists to clear. CI's count is **53**,
matching my local count. All other checks pass (Build, Clippy, Format, Test, GitGuardian).
**Not caused by this PR.** Noted so the red badge is not mistaken for a regression at merge time.

---

## Informational observations (no action requested)

**O-1 — a surviving mutant outside this PR's blast radius.** While formulating `M8` I first tried
`if not in_fenced_code and line.startswith("#"):` → `if not in_fenced_code:`. It **survives** the
suite at 69/69. Analysis: it clears `current_h2_heading` on blank/indented lines, so the Shape 2
exemption zone terminates early. Direction of error matters — a non-heading line can never
satisfy `line.startswith("## ")`, so the mutant can only *withhold* an exemption, never grant a
false one. It yields **false positives only, never false negatives**, so it cannot hide a real
violation. Informational, PR #9 territory, no action.

**O-2 — disclosure of my own harness corrections.** My initial `M8` and `MX3` formulations did not
match PR #9's canonical definitions; I retrieved the canonical wording from PR #9's body and
re-ran as `M8c` / `MX3c` (both KILLED). Separately I withdrew `S3G3` and `VPN1` as coverage
findings after proving them equivalent mutants. Recording both so the audit trail shows what I
got wrong, not only what survived.

**O-3 — PR description accuracy.** The body's claims reproduce under independent execution: 7
lines in `check-placeholders.py`; `spec_lint_primitives.py` unchanged; 69/69 control; `S3G` revert
kills P14-14; 53 corpus findings; all six PR #9 mutants dead with the stated exit codes (`M4`→2,
`MX1`→2, others→1). The one imprecision is the `M8 → P14-9` attribution: canonical `M8` fails
**five** tests (P14-8, P14-9, P14-10, P14-12, P14-13), not P14-9 alone. Harmless — the body's
table lists a killing test, not the exhaustive set.

---

## Checklist

| # | Item | Result |
|---|---|---|
| 1 | Diff coherence | PASS — 2 files, both in `scripts/spec-lint/`, all S3-related |
| 2 | Description accuracy | PASS — every claim reproduced; one imprecision (O-3) |
| 3 | Test coverage of changed lines | PASS — P14-14, both halves discriminating, guard-independent |
| 4 | Demo evidence | N/A — internal lint tooling, no user-facing AC |
| 5 | Commit quality | PASS — conventional format, `Closes S3`, cites D-078/D-100 and evidence |
| 6 | Diff size | PASS — 74 insertions / 1 deletion, far under 500 |
| 7 | Missing changes | PASS — nothing S3 requires is absent |
| 8 | Dependency status | PASS — PR #9 (`d4e76fa`) merged to `develop`; `MERGEABLE` |
| — | D-041 (no spec content touched) | PASS — zero files under `.factory/specs/**` in the diff; no em-dash row rewritten |
| — | D-039 (no allowlist/skip-list) | PASS — scan NONE FOUND; guards pass; G2 proves guard live |
| — | D-088 (no `git add -A`) | PASS — no staging performed by this review |

---

## Tree restoration

Verified clean after **twelve** mutation cycles (`S3G`, `S3G2`, `S3G3`, `MS1`, `M8`, `M8c`, `MX1`,
`MX3`, `MX3c`, `MB`, `M4`, `VPN1`, `VPN2`, plus the two-file composite arms A and B):

```
git status --porcelain          → (empty)
git rev-parse HEAD              → a14711e1a3dd8e0181234df472392c5ba89c21f7
git hash-object <file> == git rev-parse HEAD:<file>:
  OK  scripts/spec-lint/check-placeholders.py
  OK  scripts/spec-lint/selftest/run-selftests.sh
  OK  scripts/spec-lint/spec_lint_primitives.py
```

Blob-hash equality (not just `git status`) confirms byte-level restoration. The temporary
`_ZZ_prefix_check.py` used for the pre-fix corpus comparison was removed; `git status` is empty.
No `covered_sha` field was read or written. No `.factory/code-delivery/BI-POL14-TEST-SUFFICIENT/`
file was touched.

---

## Anything that contradicted the dispatch

Two items, both minor and neither altering the verdict:

1. **The dispatch stated the diff is "7 lines in `check-placeholders.py` + 68 in
   `run-selftests.sh`".** Measured: `7/0` and **`67/1`** (`git diff --numstat`). "68" counts the
   `EXPECTED_TEST_COUNT` line as an addition; it is 67 additions plus 1 deletion. Immaterial, but
   D-082 says quantitative claims come from an executed predicate, so I am reporting the measured
   value.
2. **`gh pr checks 10` is red.** The dispatch did not flag this. It is pre-existing on `develop`
   and expected pending D-100 (NIT-2), not a contradiction of substance — but a reviewer arriving
   cold would reasonably read the red badge as a blocker, so it belongs in the record.

Nothing else in the dispatch failed to reproduce. In particular, the four required probes, the
53-count, the `S3G` kill, and the six PR #9 mutant kills all confirmed independently.

---

**Reviewer:** independent PR review, fresh harness, no merge authority.
**Merge decision:** reserved to the human operator.
