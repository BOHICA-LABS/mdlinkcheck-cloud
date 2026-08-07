# PR Review — Cycle 1 (fresh-eyes, independent)

**PR:** #7 `fix/ws3-spec-lint-integrity` → `develop`
**Head SHA reviewed:** `70794e3bbdc4db968dd40674a94843476dc41559`
**Base:** `7b9aa6d` (== `develop` == `origin/develop`, confirmed; no upstream PR dependency outstanding)
**Scope reviewed:** all 8 changed files, +774/-64, 4 commits

**REQUEST_CHANGES**

Blocking findings: **BLOCK-1**, **BLOCK-2**, **BLOCK-3** (all genuine checker/selftest logic defects; all small fixes).

Per the reviewer note in the PR body I did **not** treat the advisory `Spec lint` CI failure as a finding — 80 findings (25 pre-existing `[filled by]` + 55 new em-dash) is the D-077 intended outcome and I independently reproduced exactly that number. All required checks are green (Build release, Clippy, Format, Test, GitGuardian).

---

## What I verified independently (not taken on trust)

I re-ran both checkers at base and at head against the live 133-file spec tree, re-ran the selftest suite in both hermeticity modes, and re-implemented the R3-B predicate standalone to replay it over the corpus.

| Claim | Method | Result |
|---|---|---|
| R2: 55 new + 25 pre-existing = 80 | ran head vs base `check-placeholders.py` | **confirmed** — base 25, head 80, all 55 new are `'—'` |
| R2 false positives: 0 | 4 operator-named must-not-flag vectors | **confirmed** (detail below) |
| R3: 10 findings | ran head vs base `check-id-resolution.py` | **confirmed** — base 0, head 10 (9 `EC-NEW-*` + `TV-BV013`) |
| R3-B grammar is the narrow triple-segment one | replayed regex standalone over corpus | **confirmed** — exactly **12** raw hits, matching the design figure |
| `EC-collision` (14 tags) not flagged | regex replay + live output | **confirmed** — no `-\d+` tail, cannot match |
| D-081 scoping is narrow, no sibling bleed | replayed heading state machine over corpus | **confirmed** — suppresses exactly **one** token corpus-wide: `prd.md:721 EC-NEW-3` |
| Two-step invariant not weakened | read post-test guards + diff of counter increments | **confirmed** — `TESTS_WITH_CLEAN_PASS -ne TESTS_RUN → exit 2` unchanged; all 5 new tests increment both |
| 54/54 hermetic both ways | ran with and without ambient `SPEC_LINT_REPO_OVERRIDE` | **confirmed** — 54/54 both |
| BI-042 teeth property | reverted pattern, re-ran | **partially false** → see BLOCK-3 |

### Axis 1 — R2 false-positive guard: all four named vectors verified clean

- **4 legitimate em-dashes in VP tables' non-first columns** — safe by construction: R2-RULE inspects only `cells[0]`, and `PLACEHOLDER_PATTERNS` contains no em-dash pattern, so nothing can fire on columns 2+.
- **5 `| — | None | — | — |` rows in `dtu-assessment.md`** (lines 58, 83, 93, 103, 114) — that table's header first cell is `#`, not `VP-NNN`, so `in_vp_table_data` never engages. Not flagged. Confirmed absent from live output.
- **Multi-VP cell `| VP-001, VP-018 |`** at `behavioral-contracts/ss-06/BC-2.06.001.md:109` — comma-split accepts it. Not flagged.
- **`| none | [property description] |`** at `architecture/bc-module-map.md:479` — inside a ` ```markdown ` fence; suppressed. Not flagged. (Confirmed this is the only `^| none |` first cell in the corpus.)

`good-placeholder-vp-column.md` genuinely covers all four vectors (prose em-dash, Property + Proof-Method column em-dash, multi-VP cell, non-VP `| — | None | — | — |` table, fenced template) and it is wired as the NV-1 **clean-tree** input, so the FP guard executes on every run rather than being a comment. Good design.

### Axis 3 — D-081 residual is correctly narrow

Replaying the state machine over all 133 files, `in_versioned_changelog_section` is `True` for exactly one R3-B token in the entire corpus (`prd.md:721`). Entry keys on `^### v\d+\.\d+`; exit fires on **any** level-1/2/3 heading that does not match. No bleed into sibling sections. NV-5 is correctly bidirectional — a one-directional test would be satisfied by disabling R3-B entirely, and the comment says so explicitly. This is the right shape for the test.

### Dead-code removals are safe

- `if ref != "VP-TBD":` was genuinely unreachable — `\bVP-(\d+)\b` requires digits after `VP-`, so `ref` can never be `VP-TBD`. Removal is behaviour-neutral. Confirmed.
- `base = f"EC-{n:03d}" ...` in `build_valid_ec_ids()` was an unused local; the following lines build the same strings inline. Confirmed no other reference.

---

## BLOCKING

### BLOCK-1 — `_is_valid_vp_cell` accepts punctuation-only cells as conforming (class-closure hole)

**File:** `scripts/spec-lint/check-placeholders.py`, `_is_valid_vp_cell()`

The final predicate is:

```python
tokens = re.split(r"[,/]", first_cell)
return bool(tokens) and all(_VP_TOKEN_RE.match(t.strip()) for t in tokens if t.strip())
```

The `if t.strip()` filter means that when *every* token is blank the generator is empty, and `all()` over an empty generator returns `True`. `bool(tokens)` cannot save it — `re.split` never returns an empty list, so that guard is dead code.

Measured against the shipped code:

```
first_cell=','        valid=True     <-- should be False
first_cell='/'        valid=True     <-- should be False
first_cell=',,'       valid=True     <-- should be False
first_cell='  ,  '    valid=True     <-- should be False
first_cell='—'        valid=False    (correct)
first_cell=''         valid=False    (correct)
```

**Failure scenario:** a product-owner remediating one of the 55 em-dash rows types `| , | Property text | unit test |` (or leaves a stray `/` after deleting a VP ID). `check-placeholders.py` exits 0 for that row. The burn-down baseline reports the row as cleared while the VP-ID column is still empty of any VP reference — a silent false negative in the exact column this PR exists to police.

Why this is blocking rather than a nit: the module docstring states the contract as *"Any other first-cell content (em-dash, en-dash, TBD, none, empty, etc.) is a POL-14 violation — R2-RULE (D-069)"*, and D-069's root constraint is closure of the **class** by structural predicate. A whitelist that admits `,` has not closed the class. It is also two lines to fix:

```python
tokens = [t.strip() for t in re.split(r"[,/]", first_cell) if t.strip()]
return bool(tokens) and all(_VP_TOKEN_RE.match(t) for t in tokens)
```

Please also add the punctuation-only cell (`| , |`) to `bad-placeholder-vp-emdash.md` or a sibling fixture so the hole stays closed.

---

### BLOCK-2 — fenced-code `continue` suppresses *all* checks, not just the new rules; contradicts both docstrings and silently narrows pre-existing detection

**Files:** `scripts/spec-lint/check-id-resolution.py` (`check_file`), `scripts/spec-lint/check-placeholders.py` (`check_file_lines`)

Both files declare the fence suppression as scoped to the *new* rules:

- `check-placeholders.py`: *"R2-RULE scoping: Fenced code blocks … are suppressed"*
- `check-id-resolution.py`: *"Fenced code blocks (triple-backtick, CommonMark §4.5) are suppressed from **both R3-A and R3-B**."*

The implementation does not match. In both files the fence branch is:

```python
if in_fenced_code:
    continue  # skip content inside fenced code blocks
```

placed at the very top of the per-line loop, **before** every pre-existing check. So it also disables:

- in `check-id-resolution.py`: the entire pre-existing CAP / DI / DD / VP / NFR / BC / ADR / HS / POL / EC / T-reference resolution set;
- in `check-placeholders.py`: `VP-TBD`, `SS-TBD`, and `[filled by …]` detection.

**Measured coverage loss:** at base, `check-id-resolution.py` validated ID references inside fenced blocks. At head it does not, for **89 occurrences of 44 distinct real ID tokens** — e.g. `.factory/specs/architecture/api-surface.md:48 DD-013`, `:69 CAP-006`, `:70 VP-001 / VP-003`, `:76 DI-003`, `:79 CAP-005`, `:84 CAP-003 / CAP-004`, `:87 CAP-007 / DI-002`, `:94 CAP-008`. These are live cross-references in doc-comment examples, not metasyntax. If any is renumbered or deleted from a registry, the dangling reference is now invisible.

**Failure scenario:** someone renames `CAP-006` → `CAP-020` in the registry. `api-surface.md:69` still cites `CAP-006` inside its fenced Rust example. Base `check-id-resolution.py` would have reported `unresolvable CAP reference 'CAP-006'`; head reports nothing and exits 0 on that file.

For `check-placeholders.py` the loss is currently latent, not actual — I confirmed there are **0** `VP-TBD` / `SS-TBD` / `[filled by …]` occurrences inside fenced blocks today, and the `[filled by]` count is unchanged at 25 base → 25 head. But a remediation template containing `VP-TBD` in a fenced block would now bypass POL-14.

This also makes the PR body's framing inaccurate — the PR presents R2/R3 as purely additive detection (`25 → 80 findings`, "these defects were previously invisible"). It does not disclose that pre-existing detection was simultaneously narrowed.

**Suggested fix** — hoist the fence flag but gate only the new rules on it, e.g. in `check-id-resolution.py` keep the flag update at the top but replace the blanket `continue` with a guard on the R3-A table block and the R3-B loop:

```python
if line.lstrip().startswith("```") and indent < 4:
    in_fenced_code = not in_fenced_code
    in_ec_id_column_table = False
    table_header_first_cell = None
    continue
# (no blanket `continue` here)
...
if not in_fenced_code:
    for m in _WOULD_BE_ID_RE.finditer(line):
        ...
```

If the wider suppression is in fact the intended decision, that is defensible — but then it needs to be stated in the docstrings as a deliberate scope change, and pinned by a selftest (clean tree with an unresolvable `VP-999` inside a fence → asserted exit code), because right now nothing in the 54-test suite would notice if this flipped either way.

---

### BLOCK-3 — the BI-042 "teeth test" does not gate the production FACT-10 binding; the stated regression property does not hold

**File:** `scripts/spec-lint/selftest/run-selftests.sh` (selftest 22 at ~line 1106, selftest 22b at ~line 1163)

Commit `ada4afa` and the PR body both assert:

> "If binding-25 is ever reverted to the tautological form, Phase B will fail CI."
> "restoring the old synthetic pattern must make 22b FAIL. If it doesn't, the selftest is still tautological."

**Verified: this property does not hold against the production binding.**

Selftest 22 and 22b each `cat >` their **own** `canonical-facts.toml` into `$T/.factory/specs/` and run the checker with `SPEC_LINT_REPO_OVERRIDE="$T"`. They never read `.factory/specs/canonical-facts.toml`. The production pattern is present only as a hardcoded string literal that *happens to be equal today* to `canonical-facts.toml:325`.

I proved this two ways:

1. Copied the spec tree, reverted `canonical-facts.toml:325` from `'\(sole trigger: ([^\n,]+?) pattern,'` back to the tautological `'sole trigger: (invalid \`--ignore\` glob)'`, and ran the checker on the real corpus:
   ```
   canonical-facts: OK — all 31 bindings match canonical values (11 facts)   exit=0
   ```
   Reverting the production pattern produces **no failure anywhere**. Selftest 22b is unaffected because it never consults that file.
2. Separately confirmed the *narrow* reading does hold — with the tautological pattern in the selftest's own TOML and the Phase-B adversarial text, the checker exits 0 (false negative reproduced). So 22b has teeth against its own literal, and only against its own literal.

This is the BI-042 defect class surviving in a new form. The original defect was "the selftest exercises a **synthetic** pattern, so it says nothing about the production pattern." The rewrite substitutes "the selftest exercises an **unpinned snapshot copy** of the production pattern, so it still says nothing enforceable about the production pattern, and will silently drift out of sync the moment binding-25 is edited." The improvement over the old test is real and worth keeping — but the claimed regression gate does not exist.

**Suggested fix:** derive the pattern from the real registry at test time so drift breaks the test. Roughly:

```bash
BINDING25_PATTERN=$(python3 - "$REPO" <<'PY'
import sys, tomllib, pathlib
d = tomllib.loads((pathlib.Path(sys.argv[1])/".factory/specs/canonical-facts.toml").read_text())
pats = [b["pattern"] for b in d["binding"]
        if b["fact_id"] == "FACT-10" and "sole trigger" in b["note"]]
assert len(pats) == 1, f"expected exactly 1 FACT-10 sole-trigger binding, got {len(pats)}"
print(pats[0])
PY
)
```

then interpolate `$BINDING25_PATTERN` into the temp TOML instead of the literal. The `assert len(pats) == 1` also guards against the binding being deleted outright, which the current test would not notice either.

Related, and worth fixing in the same pass (see WARN-1): even with the fix, "will fail CI" would still be untrue, because `run-selftests.sh` is not invoked by any workflow.

---

## WARNINGS (should fix; not merge blockers)

### WARN-1 — the 54-test selftest suite is not run by any CI job (pre-existing, but it invalidates this PR's assurance claims)

`grep -rn "run-selftests" .github/ lefthook.yml` returns nothing. The only caller is `Justfile:233` (`just spec-lint-selftest`), which no workflow invokes. The `spec-lint` CI job runs the nine `check-*.py` validators directly and never touches the selftest harness.

Consequences specific to this PR:
- the BI-042 regression gate cannot "fail CI" (BLOCK-3);
- the `EXPECTED_TEST_COUNT` structural guard and the `TESTS_WITH_CLEAN_PASS` vacuity guard — the two things that make this suite trustworthy — are enforced only when a human remembers to run them locally;
- BI-045's hermeticity fix hardens against an ambient `SPEC_LINT_REPO_OVERRIDE` that, by definition, only exists in the local/manual workflow. The fix is correct and worth having, but its blast radius is smaller than the commit message implies.

I am not blocking on this because the gap predates the PR. But this PR is the one that starts *depending* on the suite as evidence, so adding a `spec-lint-selftest` job (ubuntu-latest, `bash scripts/spec-lint/selftest/run-selftests.sh`, with the `factory-artifacts` checkout step the `spec-lint` job already uses) belongs with this work.

### WARN-2 — R2-RULE leaves part of the VP-ID-column class open: `| VP |`-headed tables are never checked

`in_vp_table_data` engages only when the header's first cell is exactly `VP-NNN`. All 67 BC Verification-Properties tables use that header, so live coverage is complete. But six other tables hold VP IDs in the first column under a `| VP |` header and are entirely unchecked:

- `architecture/verification-architecture.md:57, 69, 83, 90`
- `verification-properties/VP-INDEX.md:55`
- `architecture/verification-coverage-matrix.md:51`

No defects there today (I checked — the em-dashes in those tables are all in non-first columns). But the PR claims R2-RULE "closes the entire VP-ID-column class", and these tables are in that class. Either widen the header trigger to `{"VP-NNN", "VP"}` or narrow the claim to "BC Verification-Properties tables".

### WARN-3 — R3-A/R3-B de-duplication breaks on strikethrough cells

`r3a_first_cell` holds the whole cell text and R3-B skips only on `token == r3a_first_cell`. `_EC_ID_CELL_RE` is deliberately strikethrough-tolerant (`^~{0,2}EC-\d{1,4}[a-z]?~{0,2}$`), so a first cell of `~~EC-NEW-3~~` yields `r3a_first_cell == "~~EC-NEW-3~~"` while R3-B extracts `EC-NEW-3` — the two never compare equal and the same defect is reported twice. No live occurrence (`grep "^| *~~EC-"` → none), so this is latent. Fix: strip `~` before comparing, or compare by `(lineno, span)`.

### WARN-4 — table/fence recognition is narrower than GFM in two places

- `_SEP_CELL_RE = ^:?-{2,}:?$` requires two or more hyphens. GFM accepts `| - |`. A VP or EC table written with single-hyphen separators would never transition into data mode, so the **entire table** would go unchecked — a silent false negative for the whole table, not one row. No live occurrence today.
- Only backtick fences are recognized; CommonMark `~~~` fences are not. Note that `EC-105` in `BC-2.04.001.md` is literally *"`~~~`-fenced block"*, so `~~~` is a first-class concept in this domain and spec authors plausibly will use it. A `~~~`-fenced template would be scanned as live content (false positives) rather than suppressed.

Both are cheap to widen (`-{1,}`; add `~~~` to the fence test, ideally tracking the opening delimiter so a `~~~` inside a ``` block doesn't toggle).

### WARN-5 — PR description inaccuracies

Checklist item 2 (description accuracy):

1. Test Evidence table: *"R3 live tree findings | **10** (9 live EC-NEW rows + 1 from BI-042 synthetic)"*. The 10th finding is `TV-BV013` at `behavioral-contracts/ss-04/BC-2.04.001.md:63` — a test-vector ID sitting in an Edge-Cases `EC` column. It has nothing to do with BI-042 or with any synthetic fixture. Commit `2b99642` describes it correctly ("genuine defect in EC column"); the PR body does not. Since this row is the only genuinely *new class* of defect surfaced beyond the `EC-NEW-*` family, mislabelling it as test scaffolding risks it being dismissed during the WS-4 burn-down.
2. The `ada4afa` section says *"`EXPECTED_TEST_COUNT` incremented from 49 to 51 (net +2 …)"*. The commit itself says 52 → 53. Actual sequence across the four commits is 49 → 52 → 53 → 54.
3. Test Evidence says "1,783 prose em-dashes"; the figure elsewhere is 1,787. Cosmetic, but pick one.
4. Pre-Merge Checklist leaves `- [ ] Security review complete` unchecked while the Security Review section states "Security review complete."

---

## NITS

- **N1 — `check-placeholders.py`, R2 data-row branch.** The trailing comment block reads as an unedited thinking trace and contradicts itself: *"Still check non-first cells … by falling through to PLACEHOLDER_PATTERNS after skipping the first-cell check — but we do that by not continuing here. Actually: run PLACEHOLDER_PATTERNS on the full line…"*. The behaviour is correct; please collapse this to one sentence stating it. A future reader trying to decide whether the fall-through is intentional will not be able to tell from this.
- **N2 — violation grouping.** The `pattern_name` string interpolates the offending value (`f"non-conforming VP-NNN column value '{first_cell}' (POL-14)"`), so the summary counter buckets per distinct bad value. With only `—` present the summary reads cleanly (`55 non-conforming VP-NNN column value '—'`), but a mixed tree will produce one summary line per spelling. Consider a fixed group name with the value in the per-line detail only.
- **N3 — diff size.** 838 changed lines, above the 500-line review threshold. Acceptable here: 373 lines are selftest additions and 105 are fixtures/docstrings, leaving a genuinely small logic delta. Noting for the record, not asking for a split.
- **N4 — demo evidence.** No `docs/demo-evidence/` directory exists. The "N/A — CLI tooling" justification is reasonable for checker scripts with no interactive surface, and the reproducible selftest output plus exit-code evidence is the right substitute. Not a finding.

---

## Commit quality

Conventional format throughout, each with the bug ID in the subject (`fix(bi-023)`, `fix(bi-042)`, `fix(d-081)`, `fix(bi-045)`), and the bodies are unusually good — they state the failure mode, the fix, the measured deltas, and the accepted residual. `2b99642` even discloses that the measured R3 count (11) exceeded the design projection (9) and explains both deviations. That is the kind of self-reporting that makes review tractable; please keep it. The only issue is that two of those bodies assert an enforcement property that isn't implemented (BLOCK-3).

---

## Summary

The structural direction is right: both repairs are genuine shape-whitelist / grammar predicates rather than value blacklists, the FP anti-vectors are wired into clean-tree steps so they actually execute, NV-4 correctly forces class closure across two families, NV-5 is correctly bidirectional, and the D-081 residual is as narrow as claimed (one token corpus-wide). The two-step clean-pass invariant is intact and not weakened. I reproduced every headline number.

Three things need to change before merge: the `,`/`/` hole in the VP-cell whitelist (BLOCK-1), the fence `continue` that silently removes pre-existing ID-resolution coverage for 89 real references and contradicts both docstrings (BLOCK-2), and the BI-042 teeth test that gates a hardcoded copy of binding-25 rather than binding-25 itself (BLOCK-3).

**REQUEST_CHANGES: BLOCK-1 (`_is_valid_vp_cell` accepts punctuation-only cells as conforming — class-closure hole in R2-RULE); BLOCK-2 (fenced-code `continue` suppresses all pre-existing checks, not just R2-RULE/R3-A/R3-B — removes ID-resolution coverage for 89 live ID references and contradicts both module docstrings; no selftest pins it); BLOCK-3 (selftest 22/22b hardcode a snapshot copy of binding-25 and never read `.factory/specs/canonical-facts.toml` — reverting the production pattern to the tautological form leaves CI green, so the stated BI-042 regression property does not hold).**

Reviewed at head `70794e3bbdc4db968dd40674a94843476dc41559`. Happy to re-review on push; the three fixes look like well under an hour of work.
