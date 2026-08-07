# D-028 Fresh-Eyes Review — PR #3 @ `65f4664`

**Head SHA verified:** `gh pr view 3 --json headRefOid` → `65f4664bc3f24c1269bafdbe2d3f8960e45d8a3c`. Matches the SHA under review. No drift.

**Verdict:** `REQUEST_CHANGES`

---

## Answer to the central question

**The "count first, classify second" restructure is genuinely sound *within its scope*, but it does not close the class — it relocates the hiding surface one level up.**

`3299d3e` did exactly what it claimed inside `count_and_classify()`: `hs_rows_seen += 1` is now the first statement of the function (line 256), above every classifier pattern. I mutation-verified this. Any row that *reaches* `count_and_classify()` is in the denominator unconditionally. That is real, structural, and it is why fixtures E1/E2/E3/B4 now fail loudly where they previously passed.

But the denominator's blind spot was never solely below the counter. It was in the **row-recognition pre-filters that decide whether `count_and_classify()` is called at all**, and those pre-filters are still shape heuristics that fail toward *skipping*:

1. **`line.startswith("#")` is used as a proxy for "is a heading"** (line 295). It is not one. CommonMark requires whitespace or EOL after the `#` run. `3299d3e` *widened* this test from `startswith("##")` to `startswith("#")` in order to fix BLOCKING-1 — and in doing so it turned every single-`#` non-heading line into a section terminator that silently drops every subsequent row. **This is a new regression: fixtures A and A2 exit 1 at `51e6be8` and exit 0 at `3299d3e`/`65f4664`.**
2. **`re.search(r"[^|]\|[^|]", line)` is used as a proxy for "is a GFM pipeless row"** (line 327). It misses any row whose pipes are all adjacent or line-terminal. `HS-099||EC-999` renders as a real `<td>HS-099</td>` table row on GitHub and is counted zero times.

So: sixth hole found, on the sixth round, and one of the two is a regression introduced by the very commit that claimed to close the class. The distinction the task asks me to draw — *narrowed vs. closed* — resolves to **narrowed**.

What *would* close it: stop asking "does this line look like a row?" and instead count every in-scope non-blank line that is not provably a heading or a delimiter, with heading detection matching CommonMark (`^#{1,6}(\s|$)`). Every recognition predicate that gates entry to the denominator must fail toward counting, not just the one inside `_is_column_header()`.

---

## Item 1 — Path enumeration through the HS row loop (`get_hs_data`, lines 284–371)

Every path a line can take. "GFM data row?" = does GitHub's renderer (`POST /markdown`, `mode=gfm`) emit the content as a `<td>` inside the `## Authored Scenarios` section? All render results below were generated against GitHub's own renderer, not a local approximation.

| # | Lines | Condition | `hs_rows_seen` incremented? | Can this path carry a GFM-rendered data row? | Verdict |
|---|-------|-----------|------------------------------|----------------------------------------------|---------|
| **P1** | 295–306 | `startswith("#")` ∧ hash-run ≤ 2 → treated as h1/h2 section boundary. Flushes `pending_pre_sep`, resets scope + `found_separator`, `continue` | **NO** for this line; and via `in_authored_scenarios=False` it removes **all subsequent lines** from the denominator (→ P3) | **YES** — `#foo`, `    ## foo`, and `#` lines inside fenced code blocks are not headings | **HOLE — BLOCKING-1 finding. Fixtures A, A2, A3** |
| **P2** | 307–317 | `startswith("#")` ∧ hash-run ≥ 3 → h3+ sub-heading. Flushes pending, resets `found_separator`, stays in scope | NO for this line; subsequent rows still counted | No (h3–h6 render as headings) | OK — this is the BLOCKING-1 fix, verified by E1/E3 + MUT-B1 |
| **P3** | 319–320 | `not in_authored_scenarios` → `continue` | **NO** | Only reachable in error via P1 | Sound given a correct section model; poisoned by P1 |
| **P4** | 326–329 | pipeless ∧ `"\|" in line` ∧ `re.search(r"[^\|]\|[^\|]")` | **YES** (raw `+= 1`, line 328 — note: *not* via `count_and_classify()`) | Yes | OK — invariant fires. Fixture B2-control, MUT-B3 |
| **P5** | 326–329 | pipeless ∧ ¬(above) → `continue` | **NO** | **YES** — `HS-099\|\|EC-999` renders as `<td>HS-099</td><td></td><td>EC-999</td>` | **HOLE — MAJOR-1 finding. Fixture B** |
| **P6** | 339–353 | pipe row ∧ `first_cell` non-empty ∧ every non-empty cell ⊆ `{-, :, space}` → delimiter row. Flushes pending, `continue` | NO for this line | No — a row of only dashes/colons carries no ID | OK (A2a/A2b fixes hold) |
| **P7** | 359–361 | pipe row ∧ `not found_separator` → buffer into `pending_pre_sep` | Deferred to P9/P10 | — | OK — deferral, not a drop; every exit path flushes |
| **P8** | 364 | pipe row ∧ `found_separator` → `count_and_classify(line)` | **YES** | Yes | OK — the normal path |
| **P9** | 301–303, 312–314, 369–371 | flush site ∧ `_is_column_header(p)` **True** → row discarded | **NO** | No — GFM only ever renders a pre-delimiter row as `<thead>` or `<p>`, never `<td>` (verified) | **NARROW HOLE — regression vs `3299d3e`, low impact. Fixture C** |
| **P10** | 301–303, 312–314, 369–371 | flush site ∧ `_is_column_header(p)` **False** → `count_and_classify(p)` | **YES** | Yes | OK — this is the `65f4664` D-068-residual fix. Fixtures E2, E3, B4 + MUT-B4 |

**Direct answer to the required question:** *Yes.* Three paths drop a candidate row without incrementing `hs_rows_seen`: **P1** (cascading through P3, unbounded number of rows), **P5**, and **P9**. P1 and P5 can each hide a row that GitHub renders as a data row inside `## Authored Scenarios`. P9 cannot.

---

## Item 2 — Bypass attempts

Method: `SPEC_LINT_REPO_OVERRIDE=<tmpdir>` against a minimal tree (BC/VP/ARCH/L2 index stubs + one real `EC-156` wave-scenarios file). Every fixture that produced `exit 0` was then submitted to GitHub's own GFM renderer to prove the hidden content actually renders as a table row in the `## Authored Scenarios` section. Cross-SHA results:

| Fixture | Attack | `51e6be8` | `3299d3e` | `65f4664` | GFM-renders as in-section data row? |
|---------|--------|-----------|-----------|-----------|--------------------------------------|
| **A** | `#2 below: wave-2 candidates` paragraph before a phantom table | exit 1 | **exit 0** | **exit 0** | **YES** — verified `<p>#2 below…</p>` then `<td>HS-099</td><td>EC-999</td>` under one `<h2>Authored Scenarios</h2>` |
| **A2** | Fenced code block containing `# Example heading` | exit 1 | **exit 0** | **exit 0** | **YES** — verified |
| **A3** | 4-space-indented `## indented` (a code block, not a heading) | exit 0 | exit 0 | **exit 0** | **YES** — verified |
| **B** | Pipeless GFM row `HS-099\|\|EC-999` | exit 0 | exit 0 | **exit 0** | **YES** — verified `<td>HS-099</td><td></td><td>EC-999</td>` |
| **C** | Pre-separator row with first cell literally `HS ID` carrying `EC-999` | exit 0 | exit 1 | **exit 0** | No — GFM renders it as `<thead>`; the earlier real header becomes `<p>` |
| **F** | Two tables in one section, no intervening heading | — | — | exit 1 (false positive, safe direction) | n/a |

### Working fixture — BLOCKING (Attack A)

```markdown
## Authored Scenarios

| HS ID | EC ID | Title | Notes | BCs | Status |
|-------|-------|-------|-------|-----|--------|
| HS-001 | EC-156 | Selftest scenario | Notes | BC-2.01.001 | active |

#2 below: wave-2 candidates

| HS ID | EC ID | Title | Notes | BCs | Status |
|-------|-------|-------|-------|-----|--------|
| HS-099 | EC-999 | PHANTOM — still visually inside ## Authored Scenarios | Notes | BC | active |
| hs_098 | ~~EC-998~~ | PHANTOM near-miss | Notes | BC | active |
```

```
Check passed: 14 structural checks — … HS (1 validated, 0 non-conforming, 1 rows seen) all consistent
exit=0
```

`EC-999` has no wave-scenarios file. `hs_098` is a near-miss ID. Both should be reported; both are invisible. GitHub's renderer output for this exact file:

```html
<h2>Authored Scenarios</h2>
… <td>HS-001</td><td>EC-156</td> …
<p>#2 below: wave-2 candidates</p>          <!-- a PARAGRAPH, not a heading -->
… <td>HS-099</td><td>EC-999</td> …
… <td>hs_098</td><td><del>EC-998</del></td> …
```

One `<h2>`. Two phantom rows inside it. Checker: `1 rows seen`, exit 0.

Root cause at line 295–296:
```python
if line.startswith("#"):
    level = len(line) - len(line.lstrip("#"))
```
`"#2 below…"` → `level == 1` → treated as an h1 section boundary → `in_authored_scenarios = False` → every subsequent line takes P3 and is never counted. CommonMark §4.2 requires at least one space/tab after the `#` run (or an empty heading). The predicate needed is `re.match(r"#{1,6}(\s|$)", line)`.

This is **not a pre-existing hole**: at `51e6be8` the test was `startswith("##")`, which `#2 below` does not satisfy, so the phantom stayed in scope and the checker exited 1. The BLOCKING-1 fix widened the pattern and opened this.

### Working fixture — MAJOR (Attack B)

```markdown
## Authored Scenarios

| HS ID | EC ID | Title | Notes | BCs | Status |
|-------|-------|-------|-------|-----|--------|
| HS-001 | EC-156 | Selftest scenario | Notes | BC-2.01.001 | active |
HS-099||EC-999
```

```
Check passed: 14 structural checks — … HS (1 validated, 0 non-conforming, 1 rows seen) all consistent
exit=0
```

GitHub renders the last line as a real table row: `<tr><td>HS-099</td><td></td><td>EC-999</td>…</tr>`. Line 327's gate `re.search(r"[^|]\|[^|]", line)` requires a non-pipe on *both* sides of some pipe; with `||` neither pipe qualifies, so `hs_rows_seen` is never incremented.

Controls that isolate the hole precisely:
- `HS-099 | EC-999 | pipeless spaced` → exit 1 (the B3 selftest case; the gate matches).
- `|HS-099||EC-999` (same row, leading pipe added) → exit 1, reported by name as a malformed EC cell.

So only the pipeless + adjacent-pipe combination escapes. The docstring at 183–186 asserts this class is closed.

### What I tried that did **not** produce a bypass

- **`_is_column_header()` recognition MISS → silence?** No. Every miss I could construct routes to `count_and_classify()` and then either (a) classifies as a canonical `HS-NNN → EC-NNN` and gets forward-checked, or (b) falls through all four patterns and fires the accounting invariant. Renaming the header cell `HS ID` → `Scenario ID` yields `2 data row(s) seen … but only 1 classified` and `Check FAILED`. Confirmed loud.
- **`_is_column_header()` recognition HIT hiding a real HS→EC mapping.** Not possible in a way a human would see as a data row: a hit only exempts *pre-delimiter* rows, and GFM never renders a non-terminal pre-delimiter row as `<td>` — the block degrades to `<p>` plus a table whose `<thead>` is the terminal row. Fixture C confirms the exemption is real but the payload can only occupy a header/paragraph slot, so no phantom `HS-NNN` mapping can hide there. Reported as MINOR, not BLOCKING.
- **`~~`/decoration attacks on `_is_column_header`.** `strip("~")` handles strikethrough; `**HS ID**`, `` `HS ID` ``, `HS&nbsp;ID` all miss → counted → reported. Safe direction.
- **h3+/h4 flush handler.** `#### Wave 3` correctly stays in scope and resets `found_separator`, so a phantom in the header position of a sub-table is caught (fixture E3 → exit 1).
- **EOF flush** (369–371). Exercised by fixtures E2/E3/D057; buffered rows are always flushed and counted.
- **Separator handler.** I could not construct a row that GFM renders as data but the checker classifies as a delimiter: `first_cell` must be non-empty and every non-empty cell ⊆ `{-, :, space}`, which cannot carry an ID. `| ~~-~~ | … |` and `| --- | | --- |` both behave correctly. A2a/A2b remain closed.
- **Setext headings** (`Retired` + `---`). The checker doesn't recognise them, so scope is *retained* — rows are counted. Fail-toward-counting; safe.
- **Blockquoted `> #note`, HTML comments, 7+ hashes (`####### foo`).** All leave scope intact → rows counted. Safe.
- **Injecting an early fake delimiter to skip rows.** Setting `found_separator=True` early only moves rows from P7 to P8, both of which count.
- **Frontmatter / pre-first-heading content.** `in_authored_scenarios` defaults True, so this region fails toward counting.

---

## Item 3 — D-039 assessment of `_HEADER_FIRST_CELLS`

`_HEADER_FIRST_CELLS = frozenset({"hs id", "hs-id", "hs_id"})` (line 28), consumed only by `_is_column_header()` (31–52), which is called only at the three flush sites.

**Is it a D-039-forbidden allowlist? No — but the defense as written is stated too strongly, and it is not free.**

Assessment against the D-039 semantics (allowlists / skip-lists / deferral sets / known-issues collections, including disguised forms):

- **It does not enumerate findings, IDs, or violations to suppress.** It enumerates *one structural token of the table grammar* — the literal spelling of the ID column's header cell. That is a parser vocabulary entry, not a suppression list. It does not trip `SUPPRESSION_PATTERN`, and correctly so: renaming it `_HS_ID_HEADER_SPELLINGS` would not change its semantics, which is the test for a disguised form.
- **The miss branch genuinely fails loud — I verified the claim, it holds.** Every recognition failure I could construct results in the row being counted and either forward-checked or reported by the accounting invariant. Fixture E4 (`Scenario ID` header) → `Check FAILED`. Fixture D057 (a valid `| HS-001 | EC-156 |` row sitting in the column-header position) → counted, forward-checked, `1 validated, 1 rows seen`, exit 0 — correct on both the numerator and the denominator. **There is no input I found for which a `_is_column_header()` miss leads to silence.** Answering the required question directly: no.
- **But the hit branch skips, and it is unbounded.** The docstring (lines 25–27, 38–46) says "Its failure mode is COUNTING, not skipping." That describes the *miss* branch only and omits that a *hit* is exactly a skip. Worse, unlike `3299d3e`'s `pending[:-1]` — which could discard at most one row — `_is_column_header()` has no positional constraint and will exempt *every* matching pre-separator row. Fixture C proves this is a measurable behavioral regression: `3299d3e` exits 1 on it, `65f4664` exits 0.
- **Mitigating: the exemption's blast radius is structurally bounded.** GFM cannot render a non-terminal pre-delimiter row as a data cell, so the hit branch can only hide header rows and paragraph text — never a phantom `HS-NNN → EC-NNN` mapping. This is why I am not calling it BLOCKING.

**Conclusion:** not a D-039 violation. The docstring's absolute framing is inaccurate and should be corrected to state both branches, and the exemption should be positionally bounded to `pending_pre_sep[-1]` so that recognition can retire at most the one row GFM actually treats as the header.

---

## Item 4 — Docstring accuracy

Two of the three named blocks overclaim. Per the review criteria, an overclaiming docstring is a MAJOR finding.

### (a) `get_hs_data()` `hs_rows_seen` paragraph (lines 172–236) — **OVERCLAIMS**

- **Lines 183–186:** *"In-scope pipeless line containing cell delimiters (MAJOR-1 fix: … such lines are now counted and will fire the accounting invariant)."* **False.** `HS-099||EC-999` is an in-scope pipeless line containing cell delimiters, is not counted, and does not fire the invariant (fixture B). Two errors in one bullet: the same bullet also attributes the increment to `count_and_classify()`, but line 328 increments `hs_rows_seen` directly and bypasses the function entirely — so a pipeless row is never classified and never reported *by name*, only in aggregate.
- **Lines 188–191:** *"NOT counted: heading lines; out-of-scope rows (outside the current h1/h2 section boundary)…"* **Misleading in the load-bearing direction.** The code's notion of "heading line" is `startswith("#")`, which includes non-headings; the code's notion of "h1/h2 section boundary" fires on paragraphs, indented code, and fenced-block contents. Fixtures A/A2/A3 are in-section, GFM-rendered data rows classified by this sentence as "out of scope."
- **Lines 213–218 (BLOCKING-1 fix):** *"only h1/h2 headings delimit sections."* Accurate as *intent*; the implementation delimits on any `#`-prefixed line with a hash-run ≤ 2, which is a strictly larger set than "h1/h2 headings."
- **Lines 228–232 (D-068 residual closed):** **ACCURATE.** Verified by fixtures E2/E3, selftest B4, and MUT-B4.

### (b) BLOCKING-2 section (lines 220–236) — **ACCURATE but INCOMPLETE**

"each buffered row is exempted … ONLY on positive recognition by `_is_column_header()`" and "rows not recognised … are counted" are both true and verified. What is omitted: recognition hits are unbounded in number, which is the delta that regressed fixture C relative to `3299d3e`.

### (c) `main()` accounting-invariant comment (lines 583–601) — **OVERCLAIMS by omission**

It enumerates "Rows NOT covered by this invariant" as exactly four items: headings, out-of-scope rows, separator rows, recognised column-header rows. **The pipeless-regex-miss path (P5) is a fifth and is absent from the list.** For a comment whose entire purpose is to be an exhaustive statement of the invariant's blind spots, an omitted blind spot is the failure mode that matters. It also inherits the "heading lines" imprecision from (a).

### (d) Module header comment (lines 24–27) — **INCOMPLETE**

"`_is_column_header()` is the ONLY gate that exempts a pre-separator row from `count_and_classify()`" is true (for pre-separator rows). "Its failure mode is COUNTING, not skipping" states the miss branch and omits the hit branch. See Item 3.

---

## Item 5 — Mutation verification (D-040/D-050) + positive coverage (D-057)

Baseline: `Selftest passed: 28/28 negative tests verified (each proved clean-pass + defect-fail)`. Every mutation applied to an isolated copy of the tree, suite re-run, checker restored between runs.

| Mutation | Reverts | Tests that flipped | Result |
|----------|---------|--------------------|--------|
| MUT-B1 | heading detection → `startswith("##")`, no level gate | **B1 only** | `Selftest FAILED: 1/28` ✅ |
| MUT-B2 | restore pre-separator shape-regex eligibility gate | **B2 only** | `Selftest FAILED: 1/28` ✅ |
| MUT-B3 | remove the pipeless `hs_rows_seen += 1` | **B3 only** | `Selftest FAILED: 1/28` ✅ |
| MUT-B4 | restore unconditional `pending[:-1]` positional discard (all 4 sites) | **B4 only** | `Selftest FAILED: 1/28` ✅ |

All four new tests are genuinely can-fail and each isolates its own fix. No vacuous tests. D-040/D-050 satisfied for B1–B4.

**D-057 positive coverage — criterion HOLDS.** The requirement is that the runtime `N validated, 0 non-conforming, N rows seen` figure provably includes rows the pre-filters reject. Demonstrated positively (not merely via a violation):

```markdown
## Authored Scenarios

| HS-001 | EC-156 | Data row in the column-header position, valid EC | Notes | BC | active |
|-------|-------|-------|-------|-----|--------|
```
```
Check passed: … HS (1 validated, 0 non-conforming, 1 rows seen) all consistent
```

This row was rejected by *both* prior pre-filters (the `51e6be8` shape-regex gate and the `3299d3e` positional discard) and now flows into the denominator **and** the `hs_validated` numerator and is forward-checked against `wave-scenarios/`. The reported figures are not vacuous.

Caveat on the live figure: the real `HS-INDEX.md` reports `7 validated, 0 non-conforming, 7 rows seen`, and all 7 arrive via P8 (the normal post-separator path). So the *live* number does not itself exercise a pre-filter-rejected row — the proof is the fixture above, not the production output.

---

## Item 6 — B-9 accounting invariant still load-bearing

MUT-B9: neutered the violation condition at line 604 (`if hs_rows_seen != …` → `if False:`).

```
Selftest FAILED: 5/28 negative tests failed
  10f  FAIL — did NOT catch unaccounted data row
  A2a  FAIL — empty first cell bypassed separator check
  A2b  FAIL — dash-only first cell bypassed separator check
  B2   FAIL — bold HS ID above separator not detected
  B3   FAIL — pipeless row dropped uncounted
```

A2a and A2b regress as required, plus 10f, B2 and B3. The invariant is load-bearing and has grown *more* load-bearing since the last review (3 dependents → 5). Confirmed.

---

## Item 7 — Guard ordering (BI-037)

Unchanged by `3299d3e`/`65f4664`; re-verified at this SHA.

- `run_override_guard` invoked at `run-selftests.sh:104`; `run_suppression_guard` at `:123`. Ordering preserved.
- `OVERRIDE_PATTERN` (:47) and `SUPPRESSION_PATTERN` (:48) each have exactly one definition, shared by the pre-flight guards and by G1/G2.
- Guard 1 uses `if ! grep …` (fails **closed** on read error); guard 2 uses `if grep …` (would fail **open**). Because guard 1 runs first and `exit 2`s on any unreadable checker, guard 2's fail-open remains unreachable. The reasoning is documented in-line at :115–121 with an explicit warning not to reorder.
- G3 proves both guards fail closed on an empty checker directory.

Compliant.

---

## Item 8 — New defects, and live-tree status

**New defects introduced by these two commits:**
- `3299d3e` introduced the P1 pseudo-heading regression (fixtures A, A2: exit 1 → exit 0). **BLOCKING.**
- `65f4664` introduced the P9 unbounded header-exemption widening (fixture C: exit 1 → exit 0). **MINOR** (blast radius structurally bounded by GFM).
- P5 (fixture B) is *not* new — it predates `51e6be8` — but `3299d3e` added a docstring asserting the class was closed. **MAJOR** as an unclosed class + overclaim.

**Live tree, no spec edits (D-058 check).** All 8 checkers run against the unmodified working tree:

| Checker | Exit | Output |
|---------|------|--------|
| check-adr-consistency | 0 | 8 ADRs checked |
| check-counts | 0 | 37 count checks passed |
| check-ec-injectivity | 0 | 205 EC IDs validated — all injective |
| check-holdout-boundary | 0 | 134 files checked — no leaks |
| check-id-resolution | 0 | 134 files — all IDs resolve |
| check-index-integrity | 0 | 80 checks — HS (7 validated, 0 non-conforming, 7 rows seen) |
| check-placeholders | 1 | 25 placeholder occurrences — **known/advisory per D-029/D-032, not blocking** |
| check-title-sync | 0 | 66 BC titles validated |

`git status --porcelain` is empty — no spec was edited to satisfy any checker. No D-058 anti-pattern. `Spec lint` CI FAILURE is the 25 known `[filled by story-writer]` placeholders only; correctly treated as advisory.

---

## Findings

### BLOCKING-1 — `startswith("#")` misclassifies non-heading lines as section boundaries, silently dropping every subsequent HS row

**File:** `scripts/spec-lint/check-index-integrity.py:295-306` (root cause at `:296`)
**Category:** correctness / silent-false-pass / regression introduced by `3299d3e`

`level = len(line) - len(line.lstrip("#"))` is computed for any line starting with `#`. CommonMark §4.2 requires whitespace or EOL after the `#` run for an ATX heading, so `#2 below`, `#TODO`, `#1 priority`, a 4-space-indented `## …` (a code block), and any `#`-prefixed line inside a fenced code block are **not headings**. All of them yield `level ≤ 2`, set `in_authored_scenarios = False`, and remove every subsequent line in the file from the denominator via path P3 — uncounted, unclassified, unreported.

**Failure scenario (verified, fixture A):** an `HS-INDEX.md` containing the line `#2 below: wave-2 candidates` between two tables under `## Authored Scenarios`. GitHub's renderer emits `<p>#2 below: wave-2 candidates</p>` — one `<h2>Authored Scenarios</h2>`, with `HS-099 → EC-999` and near-miss `hs_098 → EC-998` rendered as data rows inside it. `EC-999` has no `wave-scenarios/` file. Checker output: `Check passed: … HS (1 validated, 0 non-conforming, 1 rows seen) all consistent`, exit 0. Fixtures A2 (fenced code block) and A3 (indented pseudo-heading) reproduce the same silence.

**Regression evidence:** fixture A → `51e6be8` exit 1, `3299d3e` exit 0, `65f4664` exit 0. Fixture A2 → identical. The BLOCKING-1 fix widened `startswith("##")` to `startswith("#")` and opened this.

**Suggestion:** gate on a CommonMark-conformant heading predicate, e.g.
```python
m = re.match(r"(#{1,6})(?:\s|$)", line)
if m:
    level = len(m.group(1))
    ...
```
and take the not-a-heading branch (i.e. fall through to row handling, which counts) otherwise. Also track fenced-code-block state (```` ``` ````/`~~~`) and treat everything inside a fence as non-structural. A selftest is required for each of: `#2 below`, an indented `## …`, and a `#` line inside a fence. Given five prior rounds on this component, the fix should also assert the general property — *no in-scope non-blank line may leave the loop without either being counted or matching a provably-structural predicate* — rather than patching the three known spellings.

---

### MAJOR-1 — pipeless-row gate `re.search(r"[^|]\|[^|]")` drops GFM-rendered data rows uncounted; docstring claims the class is closed

**File:** `scripts/spec-lint/check-index-integrity.py:326-329` (gate at `:327`)
**Category:** correctness / silent-false-pass / overclaimed fix

The MAJOR-1 counting branch requires a non-pipe character on *both* sides of some pipe. Any pipeless GFM row whose pipes are all adjacent or line-terminal fails the gate and is dropped at `continue` (path P5) without incrementing `hs_rows_seen`.

**Failure scenario (verified, fixture B):** appending `HS-099||EC-999` to the Authored Scenarios table. GitHub renders it as a genuine row — `<tr><td>HS-099</td><td></td><td>EC-999</td>…</tr>` — i.e. a visible `HS-099` entry with a blank EC cell, which is precisely the malformed-EC case the checker exists to report. Checker: `1 rows seen`, exit 0. The leading-pipe variant `|HS-099||EC-999` is correctly caught and reported by name, and the spaced variant `HS-099 | EC-999 | …` is caught, which isolates the hole to exactly this shape.

Two secondary defects in the same branch: the increment at `:328` bypasses `count_and_classify()`, so a pipeless row can only ever surface in the aggregate invariant message and never by name; and the docstring at `:183-186` asserts that all in-scope pipeless lines with cell delimiters are counted, which is false.

**Suggestion:** replace the shape gate with an unconditional count for in-scope non-blank pipeless lines that contain any `|`, and route them through `count_and_classify()` so they can be named. If a narrower predicate is retained, it must fail toward counting. Add a selftest for `HS-099||EC-999` and one for a trailing-pipe-only row (`HS-099|`).

---

### MAJOR-2 — three of the four documentation blocks overclaim what the code does

**File:** `scripts/spec-lint/check-index-integrity.py:183-191`, `:583-601`, `:24-27`
**Category:** documentation-accuracy / overclaim

Detail and evidence in Item 4. Summary:
1. `:183-186` — asserts pipeless lines with cell delimiters "are now counted." Fixture B falsifies this. Also misattributes the increment to `count_and_classify()`.
2. `:188-191` — describes the skip set as "heading lines" and "outside the current h1/h2 section boundary." Fixtures A/A2/A3 are in-section, GFM-rendered data rows that this sentence classifies as out of scope.
3. `:583-601` — the `main()` comment purports to enumerate every row class not covered by the accounting invariant, listing four. The pipeless-regex-miss class (P5) is a fifth and is missing. For an exhaustiveness claim, an omitted blind spot is the whole defect.
4. `:24-27` — "Its failure mode is COUNTING, not skipping" states the miss branch and omits that a hit is a skip.

**Failure scenario:** a maintainer reads `:583-601`, concludes the invariant's blind spots are fully enumerated and bounded to four structurally-safe classes, and does not audit the pipeless branch. MAJOR-1 survives another review round on the strength of the comment.

**Suggestion:** after fixing BLOCKING-1 and MAJOR-1, rewrite all four blocks against the actual post-fix code and add the P5 class to the `main()` enumeration if any variant survives. State the `_is_column_header()` hit branch explicitly.

---

### MINOR-1 — `_is_column_header()` exemption is positionally unbounded; regresses a case `3299d3e` caught

**File:** `scripts/spec-lint/check-index-integrity.py:31-52`, flush sites `:301-303`, `:312-314`, `:369-371`
**Category:** correctness / regression introduced by `65f4664`

`3299d3e` discarded at most one pre-separator row (`pending[:-1]` kept all but the last). `_is_column_header()` has no positional constraint, so it exempts *every* pre-separator row whose first cell matches `_HEADER_FIRST_CELLS`.

**Failure scenario (verified, fixture C):** two pre-separator rows, the first the real header `| HS ID | EC ID | … |` and the second `| HS ID | EC-999 | PHANTOM … |`. Both are exempted and uncounted → exit 0. `3299d3e` exits 1 on this input. Impact is bounded: GFM renders the second row as `<thead>` and the first as `<p>`, so no phantom `HS-NNN → EC-NNN` mapping can hide here — which is why this is MINOR and not BLOCKING.

**Suggestion:** apply the exemption only to `pending_pre_sep[-1]`, i.e. `for p in pending_pre_sep[:-1]: count_and_classify(p)` followed by a single `if not _is_column_header(pending_pre_sep[-1]): count_and_classify(...)`. That composes `3299d3e`'s positional bound with `65f4664`'s positive recognition and restores both fixture C and fixture B4/E2.

---

### MINOR-2 — B2 selftest comment still describes the `3299d3e` positional-discard mechanism

**File:** `scripts/spec-lint/selftest/run-selftests.sh:1436-1437`
**Category:** documentation-accuracy

> `# last is discarded positionally as the column header; earlier rows are counted.`
> `# The accounting invariant detects the displaced column header as unclassified.`

`65f4664` removed the positional discard. The actual detection mechanism for B2 is that `| **HS-042** | EC-999 | … |` is not recognised as a column header, is therefore counted, and falls through all four classifier patterns — the message is `2 data row(s) seen … but only 1 classified`, produced by the bold row itself, not by a "displaced column header."

**Failure scenario:** a maintainer debugging a B2 failure looks for a positional-discard bug that no longer exists.

**Suggestion:** rewrite lines 1436–1437 to describe `_is_column_header()` recognition. The mutation note at `:1586` is correct and needs no change.

---

### MINOR-3 — PR body no longer describes the PR's contents

**File:** PR #3 description
**Category:** description-accuracy

Four concrete inaccuracies after these two commits:
1. Header reads `## Evidence — current HEAD (51e6be8)` and quotes `Selftest passed: 24/24`. Current HEAD is `65f4664` and the suite is 28/28.
2. The per-checker test table lists `8, 10, 10b–10g, A1, A2a, A2b` for check-index-integrity; **B1, B2, B3, B4 are missing**.
3. The section "check-ec-injectivity behavior after frozenset removal" states the checker "is expected to fail on the real tree" and quotes `Check FAILED: 2 EC ID collisions found`. It now exits 0 with `205 EC IDs validated — all injective`. A reviewer reading the body would expect a failing checker.
4. The body does not mention the `3299d3e`/`65f4664` work at all — no `count_and_classify()` restructure, no `_is_column_header()`, no BLOCKING-1/BLOCKING-2/MAJOR-1/MAJOR-2, no D-068. Roughly a third of the diff by line count is undescribed.

Title `fix(spec-lint): eliminate vacuous-test defect class + P4-021 fixes` remains broadly accurate.

**Suggestion:** refresh the Evidence section to `65f4664` / 28/28, add B1–B4 to the table, correct or delete the ec-injectivity section, and add a paragraph on the D-068 restructure.

---

### NIT-1 — dead branch in `_is_column_header()`

**File:** `scripts/spec-lint/check-index-integrity.py:49-50`

```python
cells = [c.strip() for c in l.strip("|").split("|")]
if not cells:
    return False
```

`str.split("|")` always returns at least one element, so `cells` is never empty and the branch is unreachable. Harmless; consider removing or replacing with a guard on `cells[0]`.

---

### NIT-2 — two tables in one section without an intervening heading produce a false positive

**File:** `scripts/spec-lint/check-index-integrity.py:359-364`

`found_separator` is reset only by a heading, so a second table in the same section has its header and delimiter rows consumed as post-separator data rows. Verified (fixture F): `3 data row(s) seen … but only 1 classified`, exit 1. This is the *safe* direction (fail-toward-counting) and the live `HS-INDEX.md` has one table per section, so nothing is broken today. Worth noting only because if such a structure were ever authored, the pressure would be to restructure the spec to satisfy the checker — which is the D-058 anti-pattern. Consider resetting `found_separator` on a blank line as well.

---

## Summary

| Severity | Count | Findings |
|----------|-------|----------|
| BLOCKING | 1 | BLOCKING-1 (pseudo-heading section-scope kill — regression from `3299d3e`) |
| MAJOR | 2 | MAJOR-1 (pipeless `\|\|` bypass), MAJOR-2 (overclaiming docstrings) |
| MINOR | 3 | MINOR-1 (`_is_column_header` unbounded — regression from `65f4664`), MINOR-2 (stale B2 comment), MINOR-3 (PR body) |
| NIT | 2 | NIT-1 (dead branch), NIT-2 (two-table false positive) |

**What genuinely improved, and should be preserved:** the `count_and_classify()` restructure is the right shape and is mutation-verified — the increment is unconditionally above every classifier pattern, and the D-068 residual (phantom row in the column-header position) is truly closed, not narrowed. The B-9 accounting invariant is more load-bearing than at the last review (5 dependents, up from 3). B1–B4 are all genuinely can-fail and independently isolating. D-057 positive coverage holds with a demonstrated non-vacuous numerator. Guard ordering and the guard fail-open analysis are intact. The live tree passes with zero spec edits.

**Why this is `REQUEST_CHANGES` rather than `APPROVE`:** the class is narrowed, not closed, and the narrowing was not monotone. `3299d3e` closed the h3-subheading hole and opened the single-`#` pseudo-heading hole in the same edit; `65f4664` closed the header-position hole and widened the header-exemption surface in the same edit. Two of the three surviving drop-paths hide content that GitHub itself renders as a data row inside `## Authored Scenarios`, and one of them (BLOCKING-1) is a strict regression against `51e6be8`, reachable by an ordinary authoring accident like a line beginning `#2`, and unbounded in the number of rows it silences. The remedy is not a fourth spelling-specific patch — it is to make *every* predicate that gates entry to the denominator fail toward counting, and to assert that as a property rather than enumerating the known spellings.

---

*Reviewed at `65f4664bc3f24c1269bafdbe2d3f8960e45d8a3c`. All results reproduced independently via `SPEC_LINT_REPO_OVERRIDE` on isolated temp trees; every exit-0 fixture was rendered through GitHub's own `POST /markdown` (`mode=gfm`) to confirm the hidden content renders as a table row inside the `## Authored Scenarios` section. Cross-SHA comparisons run against `51e6be8`, `3299d3e`, and `65f4664`. `Spec lint` CI FAILURE (25 known placeholder violations) treated as advisory per D-029/D-032 and is not part of this verdict.*
