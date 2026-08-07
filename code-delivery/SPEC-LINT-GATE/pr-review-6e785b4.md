# D-028 Fresh-Eyes Review — PR #3 @ `6e785b4`

**Head SHA verified:** `gh pr view 3 --json headRefOid` → `6e785b461028b3b994be13bc4a76f3d89d1bd4fa`. Matches the SHA under review. No drift.

## Verdict

`APPROVE`

Scoped to D-070. Both BLOCKING items from the `f44147e` review are genuinely closed by one shared helper, across every spelling I could construct. Zero regressions: I A/B-ran the full prior corpus against both heads and 8 fixtures went exit 0 → exit 1 while **nothing** went exit 1 → exit 0. The four docstring blocks the ruling named are now honest on all four required points. The knowingly-deferred class is not re-raised as blocking.

**What remains open, stated plainly so the merge is eyes-open:**

1. The `prose` / `fenced_code` misclassification class is open by ruling, and I have **8 concrete working bypass spellings** in a whitespace-divergence family the review record did not previously contain (form feed, vertical tab, NBSP, U+3000 — through *both* the heading and the fence predicate). All 8 are **pre-existing** — byte-identical behaviour at `f44147e` — and all 8 are fixed by construction by the Option-3 "eliminate the parser" story. They are listed below and must be added to that story's landing gate.
2. One of the five overclaiming docstring sites from the prior review was **missed** (`main()` invariant comment, `:742-743`). It is a documentation defect, not a safety defect, because the guard it misdescribes is now pinned by a can-fail mutation-verified selftest. That is the difference between this round and rounds 1–3, and it is why this is MAJOR and not BLOCKING.

**`Spec lint` CI:** FAILURE, advisory per D-029/D-032. `check-placeholders` exits 1 with exactly `25 placeholder occurrences found (133 files checked)` — the known `[filled by story-writer]` set outstanding until Phase 2. Not reported as blocking. The other 7 checkers exit 0 on the live tree.

---

## BLOCKING-fix verification

**Both closed. One helper, not two parallel spelling checks.** Confirmed by reading, and confirmed by mutation.

`_leading_columns(raw)` is defined once at `check-index-integrity.py:38-67` and called at exactly two sites:

| Site | Line | Code |
|---|---|---|
| Fence check (BLOCKING-2) | `:420` | `if _leading_columns(raw) < 4 and _FENCE_RE.match(line):` |
| Heading check (BLOCKING-1) | `:442` | `if _leading_columns(raw) < 4 and _CM_HEADING_RE.match(line):` |

`grep -c _leading_columns` → 2 call sites, 1 definition. There is no second indent computation anywhere in the file; the prior `raw.startswith("    ")` spelling is gone entirely.

Tab expansion is CommonMark §2.1-correct: `col = (col // 4 + 1) * 4` advances to the next multiple of 4 from the *current* column, not a fixed +4. Verified against the docstring's own table and independently:

```
''  ->0   '   '->3   '    '->4   '\t'->4   ' \t'->4   '  \t'->4   '   \t'->4
'\t '->5  '\t\t'->8  '\t   '->7  '    \t'->8
```

Mutation verification (D-040 / D-050), run in an isolated copy — each mutation flips **exactly its own test**, proving both selftests are can-fail and neither is over-determined:

| Mutation | Result |
|---|---|
| `_leading_columns(raw) < 4` → `not raw.startswith("    ")` at the heading site | `Selftest FAILED: 1/36` — only `D-070-A` flips |
| Remove `_leading_columns(raw) < 4` from the fence site | `Selftest FAILED: 1/36` — only `D-070-B` flips |

---

## Indent-helper attack results

Method: `.factory` + `scripts/spec-lint` copied to `mktemp -d`, run with `SPEC_LINT_REPO_OVERRIDE=<tmpdir>`. Fixture template = real table → killer line → phantom table carrying `EC-999` (no wave-scenarios file) plus near-miss `hs_098`. Every exit-0 fixture was then submitted to **GitHub's own renderer** (`gh api -X POST /markdown`, `mode=gfm`) to establish whether the phantom actually renders as an in-section `<td>`.

### Heading family — indent boundary attack

| Killer line | exit | Verdict |
|---|---|---|
| `    ## Wave 2` (4 spaces) | **1** | closed |
| `\t## Wave 2` (TAB) | **1** | **closed — was BLOCKING-1** |
| ` \t## Wave 2` (space+TAB) | **1** | **closed** |
| `  \t## Wave 2` (2sp+TAB) | **1** | **closed** |
| `   \t## Wave 2` (3sp+TAB → col 4) | **1** | **closed — 3/4-column edge** |
| `    \t## Wave 2` (4sp+TAB → col 8) | **1** | **closed** |
| `\t\t## Wave 2` (2 TABs) | **1** | **closed** |
| `\t   ## Wave 2` (TAB+3sp → col 7) | **1** | **closed** |
| `   ## Wave 2` (3 spaces) | 0 | **correct** — GFM emits 2 `<h2>`; scope genuinely ended |
| `## Wave 2` (bare) | 0 | **correct** — GFM emits 2 `<h2>` |
| `#2 below` | 1 | closed (D-069) |
| `### Wave 2` (h3) | 1 | closed |
| fenced `## Wave 2` | 1 | closed (D-069) |

The 3-column vs 4-column edge is exact in both directions: 3 spaces → treated as a heading (GFM agrees), 3 spaces + tab → 4 columns → prose (GFM agrees it is a code block). No off-by-one.

### Fence family

| Killer line | exit | Verdict |
|---|---|---|
| `      ``` ` (6 spaces) | **1** | **closed — was BLOCKING-2** |
| `\t``` ` (TAB) | **1** | **closed** |
| `    ~~~` (4 spaces) | **1** | **closed** |
| `     ~~~` (5 spaces) | **1** | **closed** |
| `   \t``` ` (3sp+TAB → col 4) | **1** | **closed** |
| `   ``` ` (3 spaces) | 0 | **correct** — GFM: 1 `<h2>`, 1 `<pre>`, phantom is **not** a `<td>` |

### Exotic-byte attack — CRLF / BOM / form feed / vertical tab / NBSP

| Fixture | exit | GFM `<h2>` | GFM `<pre>` | phantom is in-section `<td>`? | Verdict |
|---|---|---|---|---|---|
| CRLF throughout | 1 | — | — | — | safe |
| UTF-8 BOM on line 1 | 1 | — | — | — | safe |
| BOM + CRLF | 1 | — | — | — | safe |
| BOM-prefixed `## ` killer | 1 | — | — | — | safe (BOM breaks `_CM_HEADING_RE` → fails toward counting) |
| BOM + TAB killer | 1 | — | — | — | safe |
| CRLF + TAB killer | 1 | — | — | — | safe |
| bare `\r` + `## Wave 2` | 0 | **2** | 0 | yes | **correct** — GFM also treats bare CR as a line ending, so scope genuinely ended |
| `\f## Wave 2` (form feed) | **0** | **1** | **0** | **YES** | **BYPASS — W1** |
| `\v## Wave 2` (vertical tab) | **0** | **1** | **0** | **YES** | **BYPASS — W2** |
| `\xa0## Wave 2` (NBSP) | **0** | **1** | **0** | **YES** | **BYPASS — W3** |
| `\xa0\xa0\xa0\xa0## Wave 2` (NBSP ×4) | **0** | **1** | **0** | **YES** | **BYPASS — W4** |
| `　## Wave 2` (ideographic space) | **0** | **1** | **0** | **YES** | **BYPASS — W5** |
| `\f``` ` (form feed + fence) | **0** | **1** | **0** | **YES** | **BYPASS — W6** |
| `\v``` ` (vertical tab + fence) | **0** | **1** | **0** | **YES** | **BYPASS — W7** |
| `\xa0``` ` (NBSP + fence) | **0** | **1** | **0** | **YES** | **BYPASS — W8** |

W1–W8 are the residual, adjudicated in MAJOR-2 below. **All 8 behave identically at `f44147e`** — see the new-regression check. They are not introduced by this commit, they are not in the indent-column family `_leading_columns` was built to close, and the sink they exploit is the one the ruling knowingly deferred.

### What did not produce a bypass

Adjacent-pipe `HS-099||EC-999` (exit 1), two HS-ID pre-separator rows / fixture C (exit 1), `_classify()` fall-through, fence-closer char mismatch (` ``` ` opened, `~~~` closer → exit 1, safe direction), 7+ hashes, setext headings, blockquoted and list-item headings.

---

## Docstring honesty assessment

The four claims the ruling required are **all present and all correct**. I verified each against the code rather than against the prose.

| Required claim | Where | Verified |
|---|---|---|
| Conservation law guarantees no line VANISHES but does NOT guarantee correct classification | `:253-260` — "This guarantees NO LINE VANISHES from the count, but does NOT guarantee correct classification. A phantom HS row routed to 'prose' or 'fenced_code' is accounted for but invisible to HS validation — the conservation law does not prevent this." | **YES — exact, no conflation** |
| `prose` and `fenced_code` are unbounded sinks through which a row can be counted yet still hide | `:238-241` (`fenced_code`: "UNBOUNDED SINK: any row that falls inside a fenced block is classified here and is invisible to HS validation, even if it looks like an HS row"), `:248-251` (`prose`: "UNBOUNDED SINK … accounted for but invisible to HS validation") | **YES — both labelled, both explained** |
| Class is NARROWED, not closed | `:29`, `:259-260`, `:287`, `:308-309` — four sites | **YES** |
| Seed-42 limitation disclosed, not silently implied | `:261-263` — "seed=42 fixed; the generator covers structural variety but NOT exhaustive input space — the seed is a reproducibility aid, not a completeness proof" | **YES — disclosed explicitly** |

**No docstring anywhere in the file now conflates "no line vanishes" with "no row can hide."** I read every block that mentions the conservation law and checked each for that conflation specifically. The `get_hs_data` docstring — the block a maintainer actually reads — is honest, and its honesty is load-bearing: it is what tells a reader that W1–W8 are possible in principle.

### Prior-round overclaim sites — disposition

| Prior finding | Site | Now |
|---|---|---|
| MAJOR-2 (a) module comment "closes the … bypass class" | `:26-29` | **FIXED** — "NARROWS … The class is NARROWED, not closed; see D-070." |
| MAJOR-3 `_FENCE_RE` "0-3 spaces … normalised away by `raw.strip()`" | `:31-35` | **FIXED** — the false claim is deleted; now correctly states "4+ columns → indented code block (not a fence). The indent guard is applied … via `_leading_columns(raw) < 4`." Also: I re-examined the "3+ **identical** backticks or tildes" half of MAJOR-3 and **withdraw it** — read as a description of `^(`{3,}\|~{3,})` it is accurate (a run is identical by construction). Fence char/length still is not tracked across open/close, but the comment does not claim it is. |
| MAJOR-4 `in_authored_scenarios` Claim 2 "no longer enables any bypass class" | `:308-309` | **FIXED** — "the heading-detection bypass class that enabled section-scope attacks is NARROWED (not closed); see D-070 ruling." |
| MAJOR-2 (b) BLOCKING-1 fix block "CommonMark-correct" | `:273` | **PARTIAL** — see MINOR-3 |
| MAJOR-2 (e) `main()` invariant comment "closes A/A2/A3 bypass class" | `:742-743` | **NOT FIXED — see MAJOR-1** |

Four of five corrected; one missed. That one is the top finding below.

---

## New-regression check (`f44147e..6e785b4`)

**Diff is 2 files, +259/−27.** `check-index-integrity.py` (+112/−…) and `run-selftests.sh` (+174). No other file touched. Every line of the code change is inside the `_leading_columns` definition, the two call sites, and comments.

I ran the full prior-review corpus against **both** heads side by side, same fixtures, same harness:

| Fixture | `f44147e` | `6e785b4` | Δ |
|---|---|---|---|
| `\t##`, ` \t##`, `\t\t##`, `   \t##`, `\t   ##` | 0 0 0 0 0 | **1 1 1 1 1** | **FIXED ×5** |
| `      ``` `, `\t``` `, `    ~~~` | 0 0 0 | **1 1 1** | **FIXED ×3** |
| `    ##`, `#2`, fenced `##`, `### `, adjacent-pipe, fixture C | 1 1 1 1 1 1 | 1 1 1 1 1 1 | SAME |
| `   ##`, `## `, `   ``` ` (all GFM-correct passes) | 0 0 0 | 0 0 0 | SAME |
| `\f##`, `\v##`, NBSP, NBSP×4, U+3000, `\f``` `, `\v``` `, NBSP-fence, bare-CR | 0 ×9 | 0 ×9 | SAME (pre-existing) |

**8 fixed, 0 regressed.** No previously-passing case changed direction to a worse one.

**One behaviour change, adjudicated as correct.** Adding the indent guard to the fence check necessarily makes an indented *closer* no longer close a fence — the one direction where the `fenced_code` sink becomes reachable for *more* lines than before. I hunted for it specifically:

| Fixture | `f44147e` | `6e785b4` | GFM: phantom is in-section `<td>`? |
|---|---|---|---|
| fence opened at col 0, closer indented **4 spaces**, phantom after | 1 | **0** | **False** |

The new behaviour is the **correct** one. CommonMark §4.5 allows a closing fence at most 3 spaces of indent, so a 4-space `` ``` `` is content, the fence stays open through the phantom table, and GitHub renders the phantom inside `<pre>` — no `<td>`, nothing a reader can see as a claim. The old exit 1 was a false positive. Closer at 3 spaces and at col 0 both still close correctly in both heads (exit 1, GFM agrees). This is a false-positive removal, not a bypass. Recorded as INFO below because it does move lines into the deferred sink and the Option-3 story should know.

**Full suite:** `Selftest passed: 36/36 negative tests verified (each proved clean-pass + defect-fail)`, `TESTS_RUN == EXPECTED_TEST_COUNT == 36`. Live repo `check-index-integrity` exit 0.

---

## Property test

**Still passes, still can-fail, still non-discriminating for the classification class.**

- `python3 scripts/spec-lint/check-index-integrity.py --property-test 300` → `Property test passed: 300/300 cases verified (total_candidates == sum(buckets) for all inputs, seed=42)`, exit 0. Also runs inside the 36-test suite.
- **Can-fail confirmed at this head.** Deleting the `buckets["prose"] += 1` increment on the out-of-scope path → `Property test FAILED: 178/300 cases violated the conservation law`. Not vacuous.

**Seed handling — which route was taken: DOCUMENTED, not parameterised.** `rng = random.Random(42)` is still hardcoded at `:1001`; there is no `--seed` argument and no CI rotation. The ruling permitted either route, and the disclosure route is taken properly: `:261-263` states the seed is "a reproducibility aid, not a completeness proof," and `run_property_test`'s own docstring (`:991`) scopes its claim to "no non-blank line vanishes from the accounting," which is exactly what it tests. Honest. Recorded as MINOR-5 for hygiene only.

**Can the generator produce the two new tab-family shapes? NO.** I inspected the generator's literal alphabet (`_gen_hs_index`, 148 lines) rather than trusting the docstring:

| Shape | In generator? |
|---|---|
| Any literal tab | **NO** |
| Indented fence opener | **NO** — `fence = rng.choice(["```", "~~~"])`, always emitted at column 0 |
| CRLF, BOM, form feed, vertical tab, NBSP, setext, 7+ hashes | **NO** |
| The six historical D-069 shapes | YES (unchanged from prior round) |

So the two D-070 shapes are pinned **only** by selftests `D-070-A` and `D-070-B`, not by the property test — the generator cannot reach them, and the conservation oracle would not discriminate even if it could. Recorded as MINOR-4, consistent with the prior round's MINOR-2, which the ruling did not require fixing in this PR.

---

## PR body

**Accurate, and it does not overstate in either direction on the load-bearing points.** Title updated (`… + D-068/D-069/D-070 accounting hardening`); no longer stale.

Verified claim-by-claim against what I ran:

| PR body claim | Verified |
|---|---|
| `Selftest passed: 36/36` | **exact** |
| `Property test passed: 300/300 … seed=42` | **exact** |
| `EXPECTED_TEST_COUNT` 34 → 36 | **exact** |
| Both bypasses fixed with **one** helper, called at fence **and** heading check | **exact** — 1 definition, 2 call sites |
| D-070-A mutation (revert to `startswith`) → D-070-A flips | **exact** — 1/36 |
| D-070-B mutation (remove fence guard) → D-070-B flips | **exact** — 1/36 |
| B-9 neutered → "7 tests flip → `Selftest FAILED: 7/36`" | **exact** — 7/36, and I can name them |
| Conservation-law neuter → property test catches | **confirmed** — 178/300 |
| `KNOWN_EC_COLLISIONS_PHASE2_DEFERRAL` frozenset deleted | **confirmed** — zero occurrences |
| "Honest residual" — class NARROWED not closed, `prose`/`fenced_code` unbounded sinks, residual tracked to a separate story | **present and correctly stated** |
| Per-checker negative-test table (all 8) | **accurate** |

One stale line, in the *conservative* direction (understates health):

- `- [x] check-ec-injectivity fails on real tree with exactly 2 collisions (EC-087e, EC-087f) — expected`. It does **not** fail any more: `Check passed: 205 EC IDs validated — all injective`, exit 0. The concurrent `.factory/specs/` editor appears to have resolved them. MINOR-6.

I also note for the record: the residual paragraph's framing — "a row that *legitimately* lands there (valid fence with content, or truly out-of-scope prose)" — describes only the benign half of the residual. W1–W8 are the malign half: rows GitHub renders as in-section `<td>` that the checker files into `prose`. The paragraph's next sentence, "An attacker would need a different structural trick to introduce a phantom HS row invisibly," is literally true and I found five such tricks. Not an overstatement, but the Option-3 story needs the malign half written down, which is what MAJOR-2 does.

---

## Verification notes

Fixtures built by copying `.factory` and `scripts/spec-lint` to `mktemp -d` and running with `SPEC_LINT_REPO_OVERRIDE=<tmpdir>`. GFM adjudication via `gh api -X POST /markdown` with `mode=gfm` — GitHub's own renderer, not a local approximation. All mutations applied to an isolated sandbox copy; the working tree was never modified.

**Orchestrator's independent verifications — all confirmed at this head:**

| Claim | Result |
|---|---|
| `\t## X` tab-indented heading | exit 1 ✅ |
| `      ``` ` indented fence | exit 1 ✅ |
| `#2 below` pseudo-heading | exit 1 ✅ |
| `### Wave 2` h3 subheading | exit 1 ✅ |
| `HS-099\|\|EC-999` adjacent pipe | exit 1 ✅ |
| `\t\t## X` double-tab | exit 1 ✅ |
| ` \t## X` space-then-tab | exit 1 ✅ |
| Selftests 36/36 | ✅ |
| Live repo exit 0 (`check-index-integrity`) | ✅ |
| Docstrings state "NARROWED, not closed" at `:29`, `:259-260`, `:287`, `:308-309` with unbounded-sink caveat + tracking story | ✅ all four sites, verbatim |

**Regression and hygiene:**

- **All 8 checkers, live tree.** 7 exit 0; `check-placeholders` exit 1 with exactly 25 occurrences (advisory, D-029/D-032). No collateral breakage. Only `check-ec-injectivity.py` and `check-index-integrity.py` are touched by this PR at all.
- **B-9 still load-bearing.** Neutering `if hs_rows_seen != hs_canonical + hs_nonconforming` (`:761`) → `Selftest FAILED: 7/36`, flipping: unaccounted-data-row, empty-first-cell separator, dash-only-first-cell separator, bold `HS-042` above separator, pipeless row, `D-069-B` adjacent-pipe, `D-069-C` column-header. Matches the claimed 7 exactly.
- **BI-037 guard ordering intact.** `run_override_guard` at `run-selftests.sh:104`, `run_suppression_guard` at `:123` — override first. Rationale documented at `:115-122` (F-15: suppression guard fails open on read error, override guard fails closed and runs first). G1/G2/G3 present at `:831`, `:868`, `:1119`.
- **Mutation verification (D-040/D-050) for the two new selftests.** Both can-fail, each isolating exactly its own guard (1/36 apiece). No over-determination.
- **D-057 positive coverage.** Live tree: `HS (7 validated, 0 non-conforming, 7 rows seen)`. Both new selftests assert a structural clean pass before injecting the defect (`TESTS_WITH_CLEAN_PASS` incremented, `CLEAN_PASS` gate).
- **D-058 — no spec edits.** `git status --porcelain` empty. `git diff --name-only develop...6e785b4 -- .factory/` empty. Nothing under `.factory/specs/` or `.factory/holdout-scenarios/` touched. Full diff: `.github/workflows/{ci,hardening}.yml`, `.gitignore`, `scripts/spec-lint/{check-ec-injectivity.py,check-index-integrity.py,selftest/…}`.
- **Commit quality.** Conventional format throughout, each carrying its decision ID (`D-068`, `D-069`, `D-070`, `B-9`…`B-11`, `F-12`…`F-16`, `P4-021`). `6e785b4` message accurately describes its own change including "honest residual."
- **Diff size.** 2,974 additions / 256 deletions across 7 files vs `develop`; `run-selftests.sh` is 2,325 of it. Large, but it is test code and the negative-suite expansion is the point of the PR. Not flagged. The D-070 delta alone is +259/−27.
- **D-039 — clean.** No allowlist, skip-list, deferral set, or known-issues collection in any checker, disguised or otherwise. `KNOWN_EC_COLLISIONS_PHASE2_DEFERRAL` is fully deleted. `run_suppression_guard` passes over all 8 checkers. The only frozenset in the diff is `_HEADER_FIRST_CELLS` (`:79`), re-verified compliant: it enumerates one structural token of the table grammar, and a recognition miss routes to **counting** — I re-ran the empirical check (`| Scenario ID | …` → `Check FAILED`, row counted), and a hit is bounded to `pending_pre_sep[-1]`, ≤1 row per table. Every recognition miss in the file routes toward counting: `_is_column_header` miss → counted; `_classify` fall-through → `unclassified_lines` → B-9 fires; separator miss → counted as data row; pipeless miss → counted. The two predicates whose *false positive* routes to silence (heading, fence) are the deferred class, now narrowed by `_leading_columns`. `EXCLUDE_PATHS` in `check-placeholders.py:83` is untouched by this PR and is a path exclusion for files that document the placeholder pattern, not a findings suppression — out of scope here, noting only that it is not a new construct.

---

## Findings

### MAJOR-1 — `main()` invariant comment was missed by the D-070 docstring pass: stale guard description + surviving "closes … bypass class"
`scripts/spec-lint/check-index-integrity.py:742-743`

```python
#   - Heading lines (CommonMark §4.2: #{1,6} + space/EOL, not 4-space-indented,
#     not inside a fenced code block — D-069 fix closes A/A2/A3 bypass class)
```

Two defects in two lines. **(i)** "not 4-space-indented" describes the *pre-D-070* implementation. The guard is now `_leading_columns(raw) < 4`, a column-expanded test; the 4-space spelling is exactly what BLOCKING-1 exploited and is gone from the code. **(ii)** "closes A/A2/A3 bypass class" is the fixture-vs-class conflation the prior review raised as MAJOR-2 at this precise site, and the ruling required it be made honest. Four of the five overclaiming blocks were corrected; this one was not. It is also the *only* remaining place in the file that says a bypass class is "closed" — every other site now says "NARROWED, not closed."

**Failure scenario.** A maintainer adds a predicate downstream of `line = raw.strip()` and consults this comment — the file's single consolidated statement of what is excluded from the `data_row` bucket — to learn the indent semantics. It tells them the rule is "not 4-space-indented," so they re-derive `raw.startswith("    ")` for their new predicate and reintroduce the tab bypass in a new spelling. It also tells them A/A2/A3 is a closed class, so they do not think to test `\t`. This is verbatim the failure mode MAJOR-2 described one round ago.

**Why MAJOR and not BLOCKING.** In rounds 1–3 the docstring was the only place the invariant was written down, so a docstring defect *was* a safety defect. That is no longer true: `D-070-A` and `D-070-B` are can-fail and mutation-verified, and I confirmed the exact regression this comment invites (`_leading_columns(raw) < 4` → `not raw.startswith("    ")`) flips `D-070-A` to FAIL. The gate now catches it. The comment is wrong; the code is protected.

**Fix.** Two-line edit: `not 4-space-indented` → `< 4 columns of indent (tabs expanded, D-070)`, and `D-069 fix closes A/A2/A3 bypass class` → `D-069 + D-070 NARROW the A/A2/A3 bypass class; not closed — see get_hs_data() docstring`.

### MAJOR-2 — 8 working bypasses in the whitespace-divergence family: `str.splitlines()` and `str.strip()` are wider than CommonMark
`scripts/spec-lint/check-index-integrity.py:409` (`line = raw.strip()`), `:405` (`.splitlines()`), routing into `:442` (heading) and `:420` (fence)

The checker derives lines with Python's `str.splitlines()` and normalises with `str.strip()`. Both are wider than CommonMark:

- `str.splitlines()` treats `\v` (U+000B) and `\f` (U+000C) as **line boundaries**. CommonMark line endings are `\n`, `\r`, `\r\n` only. So `\f## Wave 2` becomes two lines to the checker — `''` and `'## Wave 2'` — and the second is a clean h2 that kills section scope. To GitHub it is a single paragraph line.
- `str.strip()` strips every character for which `str.isspace()` is true, which includes NBSP (U+00A0) and U+3000. CommonMark indentation is spaces and tabs only. So `\xa0## Wave 2` strips to `## Wave 2` with `_leading_columns == 0`, matches `_CM_HEADING_RE`, and kills scope. To GitHub it is a paragraph.

`_leading_columns` cannot see any of this: it `break`s on the first non-space/non-tab character, returning 0, so the D-070 guard passes and the predicate fires. Eight confirmed spellings, each verified against GitHub's renderer (1 `<h2>`, 0 `<pre>`, phantom `EC-999` **is** a `<td>` inside `## Authored Scenarios`):

| ID | Killer line | Predicate abused | Sink |
|---|---|---|---|
| W1 | `\f## Wave 2` | heading | `prose` |
| W2 | `\v## Wave 2` | heading | `prose` |
| W3 | `\xa0## Wave 2` | heading | `prose` |
| W4 | `\xa0\xa0\xa0\xa0## Wave 2` | heading | `prose` |
| W5 | `　## Wave 2` | heading | `prose` |
| W6 | `\f``` ` | fence | `fenced_code` |
| W7 | `\v``` ` | fence | `fenced_code` |
| W8 | `\xa0``` ` | fence | `fenced_code` |

**Failure scenario (W3, the most realistic).** An author pastes a heading from a rendered web page or a Word/Confluence document into `HS-INDEX.md` between two tables inside `## Authored Scenarios`; the paste carries a leading NBSP, which is invisible in every editor. GitHub renders one `<h2>Authored Scenarios</h2>` and renders `<td>HS-099</td><td>EC-999</td>` and `<td>hs_098</td>` as real data cells inside it. `EC-999` has no `wave-scenarios/` file and `hs_098` is a near-miss ID. The checker prints `HS (1 validated, 0 non-conforming, 1 rows seen) all consistent` and exits 0. Both violations invisible. The identical file with the NBSP deleted exits 1 with 3 violations.

**Why this does not block.** Four reasons, in order of weight.

1. **Not new.** I A/B-ran all 8 against `f44147e` and the results are byte-identical (0 → 0). Nothing in `6e785b4` created, widened, or re-enabled them.
2. **Same class, same sink, same tracking story.** These are heading/fence predicate false positives routing GFM-rendered `<td>` rows into the unbounded `prose` / `fenced_code` sinks — precisely the mechanism the `get_hs_data` docstring names at `:238-251` and `:253-260` as the open residual, and precisely what D-070 deliberately carried to the Option-3 "eliminate the parser" story. A real CommonMark block parse fixes all 8 by construction, because all 8 are hand-rolled-parser-vs-real-parser divergences.
3. **Not the indent-column family.** `_leading_columns` was scoped to close indent-column bypasses and it closes them completely — I could not find a single surviving one. W1–W8 have a different root cause (line-splitting and whitespace-class divergence) that no indent helper could address.
4. **`spec-lint` is ADVISORY until the Phase 1 gate** (D-029/D-032), so this checker gates nothing today.

**What I require instead of a block.** W1–W8 must be written into the Option-3 story's landing gate as named negative fixtures, so the story cannot land without them exiting 1. They are currently in no test, no docstring, and no story. Recommend the differential oracle the prior review proposed — assert that no line GFM renders as an in-section `<td>` is filed outside `data_row`/`column_header` — which fails on all 8 and on all five D-069 reopening mutations.

### MINOR-1 — four stale `count_and_classify()` references
`scripts/spec-lint/check-index-integrity.py:71`, `:89`, `:101`, `:300`

The function was renamed `_classify()` two commits ago and no longer exists under this name. Carried unfixed from the prior round's MINOR-3.

**Failure scenario.** A maintainer greps `count_and_classify` to find the classifier, gets four comment hits and no definition, and concludes the comments describe a removed code path.

### MINOR-2 — bucket misstated for fenced headings
`scripts/spec-lint/check-index-integrity.py:277`

"Result: `'#2 below'`, `'    ## indented'`, fenced `'# heading'` are now prose." A fenced heading lands in `fenced_code`, not `prose` — the fence branch at `:420-424` `continue`s before the prose paths. Carried unfixed from the prior round's MINOR-4. Small, but this docstring is the reference for the bucket model, and the two buckets have materially different semantics (one is bounded by fence state, the other by section scope).

### MINOR-3 — "CommonMark-correct heading detection" survives
`scripts/spec-lint/check-index-integrity.py:273`

Heading detection is still not CommonMark-correct: W1–W5 prove `\f`, `\v`, NBSP and U+3000 are mishandled relative to the spec. Materially mitigated — the sentence sits in the *historical* "Fixes applied in D-069" block and the D-070 block ten lines below (`:280-287`) explicitly says D-069's indent handling was wrong and that the class is "NARROWED … not closed." A reader who reads the whole block is not misled. Downgraded from the prior round's MAJOR-2(b) on that basis, but the phrase should still go.

### MINOR-4 — property-test generator still cannot reach the two new D-070 shapes
`scripts/spec-lint/check-index-integrity.py` `_gen_hs_index` (148 lines preceding `:981`)

The generator's literal alphabet contains no tab, no indented fence opener (`fence = rng.choice(["```", "~~~"])`, always column 0), no CRLF, BOM, form feed, vertical tab, NBSP, setext heading, or 7+ hashes. The two shapes D-070 closed are therefore pinned only by selftests `D-070-A`/`D-070-B`, and the eight in MAJOR-2 by nothing. Consistent with the prior round's MINOR-2; the ruling did not require it in this PR. Worth widening in the same change that adds a discriminating oracle — under a conservation-only oracle the alphabet is irrelevant, but under a differential oracle it becomes the limiting factor.

### MINOR-5 — property-test seed remains hardcoded; disclosure route taken
`scripts/spec-lint/check-index-integrity.py:1001`

`rng = random.Random(42)`. No `--seed` argument, no CI rotation. Of the two routes the ruling allowed, this is the "plainly documented" one, and it is documented correctly at `:261-263` and `:991`. Reporting which route was taken as required; no action needed unless the oracle changes, at which point seed rotation starts to buy signal it currently cannot.

### MINOR-6 — PR body test-plan line for `check-ec-injectivity` is stale
PR #3 description, "Test plan"

`- [x] check-ec-injectivity fails on real tree with exactly 2 collisions (EC-087e, EC-087f) — expected`. It now exits **0**: `Check passed: 205 EC IDs validated — all injective (127 appear in multiple files but are consistent)`. The collisions appear to have been resolved by the concurrent `.factory/specs/` editor. Stale in the conservative direction — the body claims a failure that no longer occurs — so it understates rather than overstates. Worth a one-line correction so a future reader does not go hunting for a live collision.

### INFO — the fence indent guard makes an indented closer no longer close a fence
`scripts/spec-lint/check-index-integrity.py:420`

The only behaviour change I found in the `f44147e..6e785b4` diff beyond the eight fixes: a fence opened at column 0 and "closed" by a 4-space-indented `` ``` `` now stays open, moving subsequent lines into `fenced_code`. Previously exit 1, now exit 0. **Correct per CommonMark §4.5** (a closer may carry at most 3 spaces) and **confirmed against GitHub**, which also keeps the block open and renders the phantom inside `<pre>` with no `<td>` — so the old exit 1 was a false positive and no reader-visible claim is hidden. Recorded because it is the one direction in which D-070 makes the deferred `fenced_code` sink reachable for more lines, and the Option-3 story should account for it. Closers at 0–3 spaces still close correctly in both heads.

---

## Summary

| Severity | Count | Items |
|---|---|---|
| BLOCKING | **0** | — |
| MAJOR | 2 | MAJOR-1 (missed `main()` docstring site), MAJOR-2 (W1–W8, pre-existing, deferred class) |
| MINOR | 6 | stale `count_and_classify` ×4, fenced-heading bucket, "CommonMark-correct", generator alphabet, hardcoded seed, stale PR-body line |
| INFO | 1 | indented fence closer |

The two BLOCKING items are closed by one shared, correctly-implemented helper; every spelling I could build against it exits 1, including both 3/4-column edges and every mixed tab/space arrangement. No regression appeared — 8 fixtures improved, 0 degraded, and the single behaviour change is GFM-adjudicated as a false-positive removal. The four docstring claims the ruling required are present, exact, and free of the "no line vanishes ⇒ no row can hide" conflation. The PR body accurately describes the work.

Merging with eyes open on: MAJOR-1 (a two-line comment fix that should land promptly, but which the new can-fail selftests now protect against), and MAJOR-2 — **eight named, reproducible, GFM-confirmed bypasses** that are pre-existing, in the knowingly-deferred class, and must be written into the Option-3 story's landing gate rather than discovered a twelfth time.
