# D-028 Fresh-Eyes Review — PR #3 @ `f44147e`

**Head SHA verified:** `gh pr view 3 --json headRefOid` → `f44147e28dc2262c1308e2c28c9d31acbf5f4bf3`. Matches the SHA under review. No drift.

**Verdict:** `REQUEST_CHANGES`

**`Spec lint` CI:** FAILURE, advisory per D-029/D-032. Not reported as blocking. (Note: at review time all 8 checkers exit 0 on the live tree, including `check-placeholders` — the 25 advisory placeholders appear to have been resolved by the concurrent `.factory/specs/` editor. Informational only.)

---

## Answer to the central question

**The conservation law is sound, and it is the wrong invariant. It does not close the defect class, and I can prove that with a mutation rather than an argument.**

The restructure delivers exactly what it says on the tin: counting genuinely precedes every predicate (audit table below — there is precisely one `continue` above the counter, and it is the blank-line skip). The law `total_candidates == sum(buckets.values())` is not vacuous; it holds as a real constraint, and I confirmed it is can-fail.

But the defect class in B-8/B-9/B-11 and in the six prior bypasses was **never "a line vanishes."** It was **"a line that GitHub renders as a data row is filed under a non-data bucket."** Two of the six buckets — `prose` (:400) and `fenced_code` (:373) — are *unbounded sinks*. A misfiled row lands in one of them, the sum still balances, and the law is silent by construction.

Decisive experiment. I reverted the D-069 heading fix to the pre-D-069 `startswith("#")` spelling — reinstating historical bypass #2 in full, verified by fixture A going from exit 1 to exit 0 with the phantom `EC-999` hidden:

```
MUT-X applied: heading detection reverted to startswith('#')
D-069 property test: generating 300 cases (seed=42)...
Property test passed: 300/300 cases verified   ← the property does not notice
```

Then, systematically: I applied five mutations, each of which individually reopens one of the historical bypasses. **The property test flipped under zero of the five.**

| Mutation | Reopens | Selftests flipped | Property test |
|---|---|---|---|
| MUT-1 heading → `startswith("#")` | `#2` pseudo-heading + 4-space `##` | `D-069-A`, `D-069-A3` | **PASS 300/300** |
| MUT-2 disable fence tracking | fenced-code heading | `D-069-A2` | **PASS 300/300** |
| MUT-3 drop `raw.startswith("    ")` | 4-space-indented `##` | `D-069-A3` | **PASS 300/300** |
| MUT-4 restore adjacent-pipe gate | `HS-099\|\|EC-999` | `D-069-B` | **PASS 300/300** |
| MUT-5 unbounded column-header exemption | fixture C | `D-069-C` | **PASS 300/300** |

The property test *is* can-fail — MUT-P (deleting one `buckets["prose"] += 1`, a genuine vanishing-line bug) yields `Property test FAILED: 205/300`. So it is not vacuous. It is simply orthogonal to the class it is presented as closing.

What is actually holding the six historical bypasses shut is **the five spelling-specific selftests plus the CommonMark regex** — the same mechanism as rounds one through three, with a conservation law bolted alongside it. And because the mechanism is still spelling-specific, I found the seventh hole, in the same place as the third: **`raw.startswith("    ")` is a literal four-space test, and CommonMark counts a tab as four columns of indent.**

```
A3  4-space-indented ##   exit=1   ← the spelling the implementer was shown
T1  TAB-indented ##       exit=0   ← BYPASS
```

Same file, one character different. Six new working bypass spellings in total, across both sinks, all confirmed against GitHub's own renderer. **Narrowed again, not closed.**

---

## Conservation-law soundness audit (item 1)

Every `continue` / early return in the row loop (`get_hs_data`, :352–449) and both flush handlers (:321–350, :452). "Counted first?" = did `total_candidates += 1` (:361) execute for this line before the predicate ran?

| # | Line | Condition | Counted first? | Bucket assigned | Sink class |
|---|------|-----------|----------------|-----------------|-----------|
| **C0** | 359–360 | `not line` → `continue` | **NO — the only path above the counter** | none | Sound: blank lines are definitionally not rows and are excluded from the law by design. Not a hole. |
| **C1** | 368–371 | `_FENCE_RE.match(line)` → toggle, `continue` | YES | `fenced_code` | Bounded (1 line), but **sets unbounded state** → see BLOCKING-2 |
| **C2** | 372–374 | `in_fenced_code` → `continue` | YES | `fenced_code` | **UNBOUNDED SINK** — conserves perfectly while hiding every row |
| **C3** | 383–396 | heading → flush, set scope, `continue` | YES | `heading` | Bounded (1 line), but **sets unbounded state** → see BLOCKING-1 |
| **C4** | 399–401 | `not in_authored_scenarios` → `continue` | YES | `prose` | **UNBOUNDED SINK** — conserves perfectly while hiding every row |
| **C5** | 404–417 | non-pipe ∧ `"\|" in line` | YES | `data_row` + `_classify()` | Correct (MAJOR-1 fix; `HS-099\|\|EC-999` now lands here) |
| **C6** | 404–419 | non-pipe ∧ no `\|` | YES | `prose` | Sound — a line with no pipe cannot be a GFM cell row |
| **C7** | 430–434 | separator row → flush, `continue` | YES | `separator` | Sound — all non-empty cells ⊆ `{-,:,space}` cannot carry an ID |
| **C8** | 441–444 | `not found_separator` → buffer, `continue` | YES | deferred → C9/F1–F3 | Deferral, not a drop; every exit path flushes |
| **C9** | 447–449 | post-separator row | YES | `data_row` + `_classify()` | Correct — the normal path |
| **F0** | 333 | `not pending_pre_sep` → `return` | n/a | none | Sound — nothing buffered |
| **F1** | 336–339 | all pending but `[-1]` | already counted at C8 | `data_row` + `_classify()` | Correct (MINOR-1 fix) |
| **F2** | 343–344 | `pending[-1]` ∧ `_is_column_header()` hit | already counted at C8 | `column_header` | Bounded to ≤1 row per table — verified |
| **F3** | 345–348 | `pending[-1]` ∧ miss | already counted at C8 | `data_row` + `_classify()` | Correct — fail-toward-counting |
| **EOF** | 452 | unconditional final flush | — | — | Always runs; no pending row can survive EOF |

Inside `_classify()` (:284–319) every branch either records into `mapping`/`near_misses` (both of which produce a violation or a forward check) or falls through to `unclassified_lines.append()`. **No silent drop exists in the classifier.**

**Direct answer to the required question: No.** There is no path where a line is dropped without being counted, other than the blank-line skip, which is correct. The law does **not** hold vacuously — it holds as a genuine constraint, and MUT-P proves it fires on a real vanishing-line bug.

**And that is the problem.** The law's soundness is orthogonal to the defect class. C2 and C4 are unbounded sinks: any number of GFM-rendered data rows can be filed into them, the sum balances exactly, and no assertion fires. The law can only ever detect a *bookkeeping* bug (someone adds a `continue` without a bucket increment) — never a *classification* bug, which is what all six historical bypasses were and what BLOCKING-1 and BLOCKING-2 below are.

Also note: under `python -O` the two asserts at :455 and :459 are stripped entirely, so the law has **no runtime enforcement at all** in optimised mode. This is not a finding on its own — the B-9 conditional at :701 is a real `if` and fixture A still exits 1 under `-O` (confirmed) — but it means the law contributes nothing to the shipped gate beyond the property-test harness.

---

## Bypass attempts (item 2)

Method: `SPEC_LINT_REPO_OVERRIDE=<tmpdir>` against a minimal tree (BC/VP/ARCH/L2 index stubs + one real `EC-156` wave-scenarios file). Every fixture that produced exit 0 was then submitted to **GitHub's own GFM renderer** (`POST /markdown`, `mode=gfm`) to prove the hidden content renders as a `<td>` inside a single `<h2>Authored Scenarios</h2>`.

All fixtures share one template — a real table, a *killer line*, then a phantom table carrying `EC-999` (no wave-scenarios file):

```markdown
## Authored Scenarios

| HS ID | EC ID | Title | Notes | BCs | Status |
|-------|-------|-------|-------|-----|--------|
| HS-001 | EC-156 | Real scenario | Notes | BC | active |

<<KILLER LINE>>

| HS ID | EC ID | Title | Notes | BCs | Status |
|-------|-------|-------|-------|-----|--------|
| HS-099 | EC-999 | PHANTOM | Notes | BC | active |
```

| Killer line | Checker | GitHub renders as | Phantom is a `<td>`? | Verdict |
|---|---|---|---|---|
| `    ## Wave 2` (4 spaces) | **exit 1** | `<pre>` | yes | closed by D-069 (fixture A3) |
| `#2 below` | **exit 1** | `<p>` | yes | closed by D-069 (fixture A) |
| `\t## Wave 2` (**TAB**) | **exit 0** | `<pre>` | **yes** | **BLOCKING-1 — T1** |
| ` \t## Wave 2` (space+TAB) | **exit 0** | `<pre>` | **yes** | **BLOCKING-1 — T1b** |
| `\t\t## Wave 2` (2 TABs) | **exit 0** | `<pre>` | **yes** | **BLOCKING-1 — T1c** |
| `      ``` ` (6 spaces) | **exit 0** | `<pre>` | **yes** | **BLOCKING-2 — T2b** |
| `\t``` ` (TAB) | **exit 0** | `<pre>` | **yes** | **BLOCKING-2 — T2c** |
| `    ~~~` (4 spaces) | **exit 0** | `<pre>` | **yes** | **BLOCKING-2 — T2d** |
| `## Wave 2` (bare) | exit 0 | `<h2>` | yes, but under a *second* h2 | correct — GFM agrees scope ended |
| `> ## Wave 2` | exit 1 | `<blockquote><h2>` | yes | safe direction |
| `- ## Wave 2` | exit 1 | `<li><h2>` | yes | safe direction |
| `####### Wave 2` (7 hashes) | exit 1 | `<p>` | yes | correct — CommonMark caps at 6 |
| `Wave 2` + `---` (setext h2) | exit 1 | `<h2>` | yes | safe direction (unrecognised → counted) |
| ` ``` ` … `~~~` (wrong closer) | exit 1 | code block | n/a | safe direction |
| ` ```` ` … ` ``` ` (short closer) | exit 1 | code block | n/a | safe direction |
| CRLF throughout | exit 1 | table | yes | safe — `splitlines()` + `strip()` handle it |
| UTF-8 BOM on line 1 | exit 1 | table | yes | safe — BOM breaks `_CM_HEADING_RE`, fails toward counting |
| BOM-prefixed scope-kill heading | exit 1 | `<p>` | yes | safe direction |

### Working fixture — BLOCKING-1 (T1)

```markdown
## Authored Scenarios

| HS ID | EC ID | Title | Notes | BCs | Status |
|-------|-------|-------|-------|-----|--------|
| HS-001 | EC-156 | Real scenario | Notes | BC | active |

<TAB>## Wave 2 candidates

| HS ID | EC ID | Title | Notes | BCs | Status |
|-------|-------|-------|-------|-----|--------|
| HS-099 | EC-999 | PHANTOM | Notes | BC | active |
| hs_098 | ~~EC-998~~ | PHANTOM near-miss | Notes | BC | active |
```

```
Check passed: 14 structural checks — … HS (1 validated, 0 non-conforming, 1 rows seen) all consistent
exit=0
```

GitHub's own renderer on that exact byte sequence:

```
GH headings: ['h2: Authored Scenarios']        ← exactly ONE h2
GH pre:      ['## Wave 2 candidates']           ← a CODE BLOCK, not a heading
GH <td>:     HS-001, EC-156, …, HS-099, EC-999, …, hs_098, EC-998, …
```

One `<h2>`. Two phantom rows inside it — a phantom EC with no wave-scenarios file **and** a near-miss ID `hs_098`. Checker reports `1 rows seen`, exit 0. Both violations invisible.

Root cause, `:383`:

```python
if not raw.startswith("    ") and _CM_HEADING_RE.match(line):
```

`raw.startswith("    ")` is a literal four-**space** test. CommonMark §2.2 expands a tab to the next four-column tab stop, so `\t## X`, ` \t## X`, and `\t\t## X` are all indented code blocks, exactly as `    ## X` is. The guard recognises one of the four spellings. The other three fall through to `_CM_HEADING_RE.match(line)` — which matches, because `line = raw.strip()` (:358) has already destroyed the indentation — are treated as h2 section boundaries, set `in_authored_scenarios = False` (:389), and every subsequent row takes C4 into the unbounded `prose` sink.

Fix: replace the literal test with a column-expanded indent computation, e.g.

```python
def _indent_cols(raw: str) -> int:
    col = 0
    for ch in raw:
        if ch == "\t":   col += 4 - (col % 4)
        elif ch == " ":  col += 1
        else:            break
    return col
```

and gate on `_indent_cols(raw) < 4`.

### Working fixture — BLOCKING-2 (T2b)

```markdown
## Authored Scenarios

| HS ID | EC ID | Title | Notes | BCs | Status |
|-------|-------|-------|-------|-----|--------|
| HS-001 | EC-156 | Real scenario | Notes | BC | active |

      ```

| HS ID | EC ID | Title | Notes | BCs | Status |
|-------|-------|-------|-------|-----|--------|
| HS-099 | EC-999 | PHANTOM | Notes | BC | active |
```

```
Check passed: 14 structural checks — … HS (1 validated, 0 non-conforming, 1 rows seen) all consistent
exit=0
```

GitHub: `headings=['h2: Authored Scenarios']`, `pre=['```']`, `phantom_is_td=True`. There is **no fenced code block in this document at all** — the six-space-indented backtick run is an *indented* code block whose *content* is three backticks. The phantom table is a real table inside the one and only h2.

Root cause, `:368`:

```python
if _FENCE_RE.match(line):
    in_fenced_code = not in_fenced_code
```

The fence branch has **no `raw`-indent guard whatsoever** — not even the four-space one the heading branch has. `line` is already stripped, so any indentation opens a fence. CommonMark permits at most 3 spaces of indent on a fence; at 4+ columns it is an indented code block and opens nothing. So the checker enters the unbounded `fenced_code` sink (C2) on a line that GitHub treats as ordinary code content, and swallows the rest of the file. `\t``` ` and `    ~~~` are the same hole in two more spellings.

Fix: apply the same `_indent_cols(raw) < 4` gate to `:368`, and additionally track the opening fence's character and length so a closer must match (CommonMark §4.5) — see MAJOR-3.

### What I tried that did **not** produce a bypass

- **`_classify()` fall-through.** Every unmatched row reaches `unclassified_lines` and fires B-9. Bold `| **HS-042** |`, backticked, `HS&nbsp;ID`, partial strikethrough — all counted and reported. Confirmed loud.
- **`mapping` dict collapse.** Two rows with the same HS-ID collapse to one dict entry, but `hs_rows_seen` still counts 2 → B-9 fires, and the independent duplicate check at :740 also fires. Loud twice.
- **`_is_column_header()` miss.** Header renamed `| Scenario ID | …` → `Check FAILED`, row counted. Fail-toward-counting confirmed.
- **`_is_column_header()` hit.** Bounded to `pending_pre_sep[-1]`; fixture C and a phantom in the non-last pre-separator slot both exit 1. MINOR-1 fix verified.
- **Separator misclassification.** `first_cell` non-empty ∧ all non-empty cells ⊆ `{-,:,space}` cannot carry an ID. A2a/A2b remain closed.
- **Fence closer mismatch** (char or length). The checker toggles off at-or-before GFM does, so it exits the fence *early* and sees more rows. Safe direction, both spellings exit 1.
- **CRLF, UTF-8 BOM, BOM-prefixed heading, blockquoted heading, list-item heading, 7+ hashes, setext headings, `#\t`.** All either correct or fail-toward-counting. All exit 1 (or exit 0 where GFM agrees the scope genuinely ended).
- **Injecting an early fake separator.** Only moves rows from C8 to C9; both count.
- **Pre-first-heading content.** `in_authored_scenarios` defaults True (:279) → fails toward counting.

---

## Property-test assessment (item 3)

**As an artifact: well-built, honest about what it asserts, can-fail, not seed-tuned — and load-bearing for nothing.**

*Generator coverage.* `_gen_hs_index()` (:773–918) does produce all six historical shapes. I verified this by inspecting the generator's literal alphabet rather than trusting the docstring:

| Historical shape | Generator can produce it? |
|---|---|
| `#2` pseudo-heading | **YES** (`pseudo_headings`, :802, p≈0.5) |
| Fenced code containing a heading | **YES** (`fenced_internals`, :808–815, p≈0.4) |
| 4-space-indented `##` | **YES** (:846, p≈0.3) |
| Adjacent-pipe pipeless row | **YES** (`pipeless_adjacent`, :799) |
| Pre-separator `HS ID` row | **YES** (:859) |
| h3+ subheading | **YES** (:884–887, p≈0.3) |

So the "a property test that never generates `#2`-style pseudo-headings would prove nothing" concern does **not** apply — it generates them. The problem is one level deeper: **generating the shape proves nothing when the asserted property cannot distinguish correct from incorrect handling of it.** MUT-1 through MUT-5 all leave the property passing 300/300 *while the generator is emitting the very shapes those mutations mishandle.* Shape coverage without a discriminating oracle is not evidence.

*Shapes the generator cannot produce* — and which happen to be exactly where the two BLOCKING findings live:

| Shape | In generator? |
|---|---|
| Any tab character | **NO** |
| Indented fence opener | **NO** (all fences emitted at column 0) |
| CRLF | **NO** |
| BOM | **NO** |
| Setext heading | **NO** |
| 7+ hashes | **NO** |

*Seed 42 (`:941`).* The shipped test hardcodes `random.Random(42)`, so CI exercises one seed. I parameterised it and ran **60 seeds × 300 cases = 18,000 generated inputs: zero conservation-law violations.** So the single seed is not hiding anything — but that is *because the property is trivially true of the current code by construction* (see the audit table: every `continue` has a bucket increment). Widening the seed count would add cost and no signal. I flag the hardcoded seed as MINOR for hygiene, while noting explicitly that fixing it would not have caught either BLOCKING finding, and neither would 12,000 or 1,200,000 cases. The gap is the oracle, not the sample size.

*Recommendation.* The property worth testing is a **differential** one: for each generated document, compare the checker's bucket assignment against a reference CommonMark/GFM block parse (`cmark-gfm`, or `POST /markdown` in a non-CI harness), and assert that **no line GFM renders as a `<td>` inside `## Authored Scenarios` is filed anywhere other than `data_row` or `column_header`.** That property fails on T1, T1b, T1c, T2b, T2c, T2d, and on all five of MUT-1…MUT-5. Then the generator's alphabet must be widened to include tabs, indented fences, CRLF, and setext, because under a discriminating oracle alphabet coverage starts to matter.

---

## Residual attack (item 4)

**The declared residual is a genuine false POSITIVE and I could not turn it into a false negative.** Confirmed and safe.

| Variant | Result |
|---|---|
| Two full tables in one section, no intervening heading (as declared) | **exit 1** — `2 data row(s) seen … only 1 classified`, second header row named as the unclassified line |
| Second separator only, no second header | **exit 1** |
| Phantom rows appended after a blank line with no second header/separator | **exit 1** |
| h3 subheading between the two tables | **exit 1** — `found_separator` correctly reset at :394, phantom caught by the forward check |
| Phantom in the pre-separator block after an h3 | **exit 1** — 3 violations |

Mechanism confirmed: `found_separator` is not reset on blank lines (correct — blank lines take C0 above the counter), so the second table's header row arrives at C9 as a data row, matches none of the four `_classify()` patterns, and fires B-9. Adding a separator, blank lines, or a subheading in any position I tried made it *more* loudly wrong, never silent. The safe-direction claim holds. Not present in the live file — confirmed, live tree exits 0 with `7 validated, 7 rows seen`.

---

## D-039 assessment (item 5)

**`_HEADER_FIRST_CELLS` (`:45`) is compliant. The six-bucket vocabulary is compliant as a vocabulary. The heading and fence *predicates* violate the governing asymmetry.**

*`_HEADER_FIRST_CELLS = frozenset({"hs id", "hs-id", "hs_id"})`* — consumed only by `_is_column_header()` (:48–76), called only on `pending_pre_sep[-1]` (:343).

- It enumerates one structural token of the table grammar — the ID column's header spelling — not findings, IDs, or violations to suppress. Renaming it would not change its semantics, which is the test for a disguised form. Correctly does not trip `SUPPRESSION_PATTERN`.
- **Recognition miss → COUNTING, verified empirically.** `| Scenario ID | …` → `Check FAILED: 1 index integrity violations`, row counted. There is no input I found for which a miss leads to silence.
- **Recognition hit → skipping, but now bounded.** The MINOR-1 fix restricts the exemption to `pending_pre_sep[-1]`, ≤1 row per table, matching GFM single-header semantics. Fixture C and the non-last-pre-separator phantom both exit 1. The previous round's unbounded-exemption finding is resolved.

*The six-bucket vocabulary* is not an allowlist either — it is a total partition, and totality is enforced. But applying the task's governing asymmetry to the *predicates that route into it* gives a clear negative result:

| Recognition predicate | Failure mode | Compliant? |
|---|---|---|
| `_is_column_header()` (:48) | miss → counted; hit bounded to 1 row | **YES** |
| `_classify()` four patterns (:294–315) | miss → `unclassified_lines` → B-9 fires | **YES** |
| Separator test (:430) | miss → counted as data row | **YES** |
| Pipeless test `"\|" in line` (:414) | miss → `prose`, but only for lines with no pipe | **YES** |
| **`_CM_HEADING_RE` + 4-space guard (:383)** | **false positive → unbounded `prose` sink, silent** | **NO** |
| **`_FENCE_RE` (:368)** | **false positive → unbounded `fenced_code` sink, silent** | **NO** |

The two non-compliant predicates are exactly BLOCKING-1 and BLOCKING-2. The asymmetry the docstring at :36–44 correctly identifies as load-bearing has been applied to the column-header recogniser and *not* to the two recognisers whose failure mode is unbounded. No allowlist, skip-list, deferral set, or known-issues collection is present anywhere in the diff, and the `run_suppression_guard` pre-flight passes over all 8 checkers (`0 suppression constructs found`). So this is not a literal D-039 violation — but it is the same silent-skip failure mode D-039 exists to prevent, reached through a predicate rather than a list.

---

## Section-scope predicate (item 6)

**The justification's first clause is accurate and I verified it. The second clause is false.**

The docstring at `:247–253` claims two things.

*Claim 1 — removing section scope would route `## Reserved IDs` pipe rows to `data_row` and fire B-9 incorrectly.* **ACCURATE.** I neutered the `not in_authored_scenarios` branch and ran against the live tree:

```
18 data row(s) seen in Authored Scenarios table but only 7 classified (11 row(s) unaccounted for)
 — unclassified: [line 56: '| EC ID | Reserved Since | Notes | Status |';
                  line 58: '| ~~EC-036~~ | …'; line 59: '| ~~EC-049~~ | …'; …]
Check FAILED
```

11 spurious violations, exactly as claimed. I also independently confirmed the premise that no HS-shaped row (first cell matching `HS-NNN` or a near-miss) appears outside `## Authored Scenarios` in the live file — clean scan.

*Claim 2 — "With CommonMark-correct heading detection, the section scope predicate no longer enables any bypass class."* **FALSE, and this is the sentence BLOCKING-1 falsifies.** Heading detection is not CommonMark-correct (it mishandles tab indentation), and the section-scope predicate is precisely the mechanism T1/T1b/T1c exploit: `in_authored_scenarios = False` at :389 followed by the unbounded `prose` sink at :400. Retaining the predicate is defensible on Claim 1's merits, but it is **not** "genuinely safe" — it is safe only to the exact extent that heading detection is correct, and heading detection is not correct.

---

## Docstring accuracy (item 7)

Round four ships overclaiming docstrings again. Four MAJOR-grade inaccuracies, all in the load-bearing direction.

**(a) `:26–28` module comment — OVERCLAIMS.**
> "Combined with a 4-space-indent exclusion on the raw line, this closes the pseudo-heading / fenced-code bypass class (fixtures A/A2/A3)."

It closes the three named *fixtures*. It does not close the *class*: T1, T1b, T1c are pseudo-heading bypasses and T2b, T2c, T2d are fenced-code bypasses, all still open. The parenthetical "(fixtures A/A2/A3)" is doing the work of narrowing the claim, and the word "class" contradicts it in the same sentence.

**(b) `:226–231` (BLOCKING-1 fix block) — OVERCLAIMS.**
> "CommonMark-correct heading detection replaces the prior `startswith("#")`. … 4-space-indented lines excluded via raw-line check (before strip)."

Not CommonMark-correct. CommonMark §2.2 defines indentation in *columns* with tabs advancing to four-column stops; the implementation tests for four literal space characters. `\t## X` is an indented code block per CommonMark and a heading per this code. Proven by T1.

Also, `:231`: "Result: `'#2 below'`, `'    ## indented'`, fenced `'# heading'` are now prose". The fenced heading is filed under `fenced_code`, not `prose`. Minor, but this docstring is the reference for the bucket model.

**(c) `:31–33` `_FENCE_RE` comment — FACTUALLY WRONG on two counts.**
> "A fence is 3+ identical backticks or tildes (optionally 0-3 spaces of indent, which are normalised away by `raw.strip()` before this is applied)."

1. `raw.strip()` normalises away *any* indentation, not 0–3. The comment states the CommonMark rule and then describes an implementation that does not enforce it. This is the BLOCKING-2 root cause stated as if it were the fix.
2. "identical" is not enforced anywhere. `_FENCE_RE` is `^(\`{3,}|~{3,})` and the code toggles a bare boolean — it tracks neither the fence character nor its length, so a ``` fence is "closed" by `~~~` or by a shorter run. (Both directions happen to fail safe, but the comment asserts a property the code does not have.)

**(d) `:247–253` `in_authored_scenarios RETAINED` — second clause FALSE.** See item 6.

**(e) `:681–690` `main()` invariant comment — OVERCLAIMS by the same mechanism as (a)/(b).**
> "Heading lines (CommonMark §4.2: `#{1,6}` + space/EOL, not 4-space-indented, not inside a fenced code block — D-069 fix closes A/A2/A3 bypass class)"

For a comment whose entire purpose is an exhaustive statement of the invariant's blind spots, "closes A/A2/A3 bypass class" is the same conflation of fixture with class, and the enumeration omits that tab-indented headings and indent-opened fences are misrouted.

**Accurate claims, verified:**
- `:196–197` "Every non-blank line increments `total_candidates` before any predicate examines it" — **TRUE**, verified by the full path audit.
- `:213–216` conservation law "A violation signals a parser bug (line vanished)" — **TRUE** and correctly scoped to *vanishing*. This docstring does not claim the law closes the misclassification class; the module comment (a) and the PR framing do.
- `:218–220` "B-9 accounting invariant … Neutering this check causes multiple selftests to fail" — **TRUE**, 7 tests flip.
- `:36–44`, `:48–76` `_is_column_header()` asymmetry and MINOR-1 bounding — **TRUE**, verified empirically.
- `:240–245` MINOR-1 / fixture C — **TRUE**, MUT-5 verified.
- `:922–931` `run_property_test` docstring — **TRUE**. It claims only that no line vanishes, which is exactly what it tests. Honest.

**Stale identifier (NIT):** `count_and_classify()` is referenced at `:37`, `:55`, `:67`, `:244`. The function was renamed `_classify()` in this commit and no longer exists under that name.

---

## Verification notes

Fixtures built by copying `.factory` and `scripts/spec-lint` to `mktemp -d` and running with `SPEC_LINT_REPO_OVERRIDE=<tmpdir>`. GFM rendering via `gh api -X POST /markdown` with `mode=gfm` (GitHub's own renderer, not a local approximation).

**Orchestrator's five prior findings — all independently confirmed:**

1. **Six known bypasses exit 1.** Confirmed: h3 subheading, `#2` pseudo-heading, fenced-code heading, 4-space-indented `##`, pipeless `HS-099||EC-999`, pre-separator `HS ID` row — all exit 1, and each is pinned by a can-fail selftest.
2. **Strikethrough-retired phantom exits 1.** Confirmed.
3. **`python -O` still exits 1 on the `#2` fixture.** Confirmed — the B-9 check at `:701` is a real conditional. Note the corollary: the `:455`/`:459` asserts *are* stripped under `-O`, so the conservation law has no runtime enforcement in optimised mode.
4. **Property test not seed-tuned.** Confirmed and extended: 60 seeds × 300 = **18,000** generated inputs, 0 violations. Also confirmed can-fail (MUT-P → 205/300 failures). And confirmed *non-discriminating*: 0 of 5 reopening mutations flip it.
5. **Selftests 34/34; live repo exit 0.** Confirmed. All 8 checkers now exit 0 on the live tree (`check-placeholders` included — the 25 advisory placeholders appear resolved by the concurrent `.factory/specs/` editor).

**Regressions and hygiene (item 8) — all pass:**

- **B-9 load-bearing.** Neutering `if hs_rows_seen != hs_canonical + hs_nonconforming` (`:701`) flips exactly 7 tests: `10f`, `A2a`, `A2b`, `B2`, `B3`, `D-069-B`, `D-069-C`. Matches the claim.
- **Guard ordering BI-037 intact.** `run_override_guard` invoked at `run-selftests.sh:104`, `run_suppression_guard` at `:123`. Rationale documented at `:115–122`. Both pre-flight guards pass: 8 checkers support the override, 0 suppression constructs found. G1/G2/G3 present.
- **Mutation verification D-040/D-050 for the new selftests** — all five are genuinely can-fail and each isolates its own fix (table in the central-question section). MUT-1 flips two because that edit necessarily removes the indent guard as well; expected.
- **D-057 positive coverage** present at `:766` — `HS (7 validated, 0 non-conforming, 7 rows seen)`.
- **D-058** — `git status` clean; `git diff develop...f44147e -- .factory/` is empty. No spec edits. Diff touches only `.github/workflows/*`, `.gitignore`, and `scripts/spec-lint/*`.
- **Diff size** — 2,669 additions / 216 deletions across 5 files, of which `run-selftests.sh` is 2,153. Large but it is test code, and the selftest expansion is the point of the PR. Not flagged.

---

## Findings

### BLOCKING-1 — tab-indented ATX heading kills section scope; unbounded silent `prose` sink
`scripts/spec-lint/check-index-integrity.py:383`

`raw.startswith("    ")` is a literal four-space test. CommonMark §2.2 expands tabs to four-column stops, so `\t##`, ` \t##`, and `\t\t##` are indented code blocks exactly as `    ##` is. `line = raw.strip()` (`:358`) has already erased the indentation, so `_CM_HEADING_RE` matches, the line is treated as an h2 boundary, `in_authored_scenarios` is set False (`:389`), and every subsequent row takes `:399–401` into the unbounded `prose` bucket. The conservation law balances exactly; nothing fires.

**Failure scenario.** An HS-INDEX authored in any editor configured with `insertSpaces: false` contains `\t## Wave 2 candidates` between two tables inside `## Authored Scenarios`. GitHub's renderer emits one `<h2>Authored Scenarios</h2>`, renders the tab line as `<pre>`, and renders `<td>HS-099</td><td>EC-999</td>` and `<td>hs_098</td>` as real data cells inside that section. `EC-999` has no wave-scenarios file and `hs_098` is a near-miss ID. The checker prints `HS (1 validated, 0 non-conforming, 1 rows seen) all consistent` and exits 0. The identical file with four spaces instead of the tab exits 1 with 3 violations. Fixture and GFM render output in item 2.

**Fix.** Replace the literal test with column-expanded indent (`_indent_cols(raw) < 4`, tabs advancing to the next multiple of 4).

### BLOCKING-2 — indented fence opener enters unbounded silent `fenced_code` sink
`scripts/spec-lint/check-index-integrity.py:368`

The fence branch applies `_FENCE_RE` to the already-stripped `line` with **no `raw`-indent guard at all** — not even the four-space one the heading branch has. CommonMark permits at most 3 spaces of indent on a fence; at 4+ columns the line is an indented code block and opens nothing. So `      ``` `, `\t``` `, and `    ~~~` each set `in_fenced_code = True` and route every subsequent line to `fenced_code` (`:372–374`) while GitHub sees no fenced block whatsoever. The conservation law balances exactly.

**Failure scenario.** An HS-INDEX contains a six-space-indented backtick run — e.g. left over from a nested list example or a reflowed code sample — inside `## Authored Scenarios`, followed by a table containing `| HS-099 | EC-999 | … |`. GitHub renders `<pre>```</pre>` and then the table with `<td>EC-999</td>` inside the single h2. `EC-999` has no wave-scenarios file. Checker: `1 rows seen`, exit 0. Fixture and GFM render output in item 2.

**Fix.** Apply the same `_indent_cols(raw) < 4` gate at `:368`, and track the opening fence's character and length so a closer must match per CommonMark §4.5.

### MAJOR-1 — the conservation law and property test cannot detect the defect class they are presented as closing
`scripts/spec-lint/check-index-integrity.py:459`, `:921–990`

The law constrains *totality* of classification, not *correctness* of classification. `prose` (`:400`) and `fenced_code` (`:373`) are unbounded sinks, so any misfiled row conserves. Demonstrated, not argued: five mutations each individually reopen one historical bypass and flip its selftest, and the property test passes 300/300 under all five. The law is sound and can-fail (MUT-P → 205/300), but it is orthogonal to B-8/B-9/B-11 and to all six prior bypasses. What actually holds those shut is the five spelling-specific selftests plus the CommonMark regex — i.e. the same mechanism as rounds 1–3. This is the finding that answers D-069's question: the restructure did not deliver closure by construction.

**Failure scenario.** A future contributor adds any predicate that misclassifies a GFM data row into `prose` or `fenced_code` — as `:383` and `:368` already do. Selftests pass, the property test passes 300/300, the assert at `:459` never fires, the gate exits 0, and the seventh round of this review finds it by hand. Recommended remedy: a differential property against a reference GFM block parse, asserting that no line GFM renders as an in-section `<td>` is filed outside `data_row`/`column_header`. That property fails on all six new fixtures and on all five mutations.

### MAJOR-2 — docstrings claim a closed *class* where only three *fixtures* are closed
`scripts/spec-lint/check-index-integrity.py:26–28`, `:226–231`, `:685`

"closes the pseudo-heading / fenced-code bypass class", "CommonMark-correct heading detection", "D-069 fix closes A/A2/A3 bypass class". Heading detection is not CommonMark-correct (tabs), and both named classes remain open in six spellings. Third consecutive round shipping a docstring that overstates coverage; this is the pattern D-069 was issued to stop.

**Failure scenario.** A future maintainer reads `:226–231`, believes indentation handling is CommonMark-correct, and adds a new predicate downstream of `strip()` without re-deriving the indent semantics — reintroducing exactly this hole in a new spelling. The docstring is the only place the invariant is written down.

### MAJOR-3 — `_FENCE_RE` comment describes a CommonMark rule the code does not enforce
`scripts/spec-lint/check-index-integrity.py:31–33`

"(optionally 0-3 spaces of indent, which are normalised away by `raw.strip()`)" — `strip()` normalises away *any* indent, which is the BLOCKING-2 root cause written down as though it were the fix. "3+ **identical** backticks or tildes" — identity is not enforced; the code toggles a bare boolean and tracks neither fence character nor length.

**Failure scenario.** A maintainer auditing fence handling reads this comment, concludes the 0–3-space rule is enforced, and does not test `      ``` `. BLOCKING-2 survives the audit.

### MAJOR-4 — `in_authored_scenarios` retention justification asserts a safety property that does not hold
`scripts/spec-lint/check-index-integrity.py:247–253`

Claim 1 (Reserved-IDs rows would fire B-9) is accurate — verified, 11 spurious violations when neutered. Claim 2 — "With CommonMark-correct heading detection, the section scope predicate no longer enables any bypass class" — is false; that predicate is exactly the BLOCKING-1 mechanism.

**Failure scenario.** A reviewer accepts the retention on the strength of Claim 2 and does not probe the scope-kill path, which is the single highest-value attack surface in the file and the origin of three of the seven bypasses.

### MINOR-1 — property test hardcodes seed 42; CI exercises one seed
`scripts/spec-lint/check-index-integrity.py:941`

`random.Random(42)`. I verified this is not hiding anything (18,000 inputs across 60 seeds, 0 violations) — because the property is trivially true of the current code. Worth parameterising for hygiene, but note explicitly that neither more seeds nor more cases would have caught BLOCKING-1 or BLOCKING-2; the oracle is the gap, not the sample size.

### MINOR-2 — generator alphabet excludes the shapes both BLOCKING findings live in
`scripts/spec-lint/check-index-integrity.py:773–918`

The generator produces all six historical shapes (verified) but cannot produce a tab character, an indented fence opener, CRLF, a BOM, a setext heading, or 7+ hashes. Under the current conservation-only oracle this is harmless; under a differential oracle it becomes the limiting factor, so widen it in the same change.

### MINOR-3 — docstrings reference a function that no longer exists
`scripts/spec-lint/check-index-integrity.py:37`, `:55`, `:67`, `:244`

`count_and_classify()` was renamed `_classify()` in this commit. Four stale references.

### MINOR-4 — bucket misstated for fenced headings
`scripts/spec-lint/check-index-integrity.py:231`

"fenced `'# heading'` [is] now prose" — it is `fenced_code`. Small, but this docstring is the reference for the bucket model.

### MINOR-5 — PR title and body are stale by three commits
PR #3 description

Body says `24/24 negative tests`, headlines "Evidence — current HEAD (`51e6be8`)", and contains **zero** mentions of D-068, D-069, the property test, the conservation law, or 34/34. It documents neither the restructure that is now the PR's centrepiece nor the three commits since `51e6be8`. The title `fix(spec-lint): eliminate vacuous-test defect class + P4-021 fixes` no longer describes the change.

**Failure scenario.** A reviewer or future archaeologist reads the PR description and reviews the wrong artifact — precisely the fresh-eyes failure mode D-028 exists to prevent.

---

## What would make this APPROVE

1. Fix `:383` and `:368` with a single shared column-expanded indent helper, so both the heading and fence predicates derive indentation the way CommonMark does. One helper closes all six new spellings; I verified they share one root cause.
2. Add can-fail selftests for the tab-indented heading and the indented fence, mutation-verified per D-040/D-050.
3. Correct the four overclaiming docstrings to state fixture-level coverage, and remove "CommonMark-correct", "closes the … class", and "0-3 spaces of indent" unless the code enforces them.
4. Replace or supplement the conservation property with a **differential** property against a reference GFM block parse — the only oracle I found that fails on all seven bypasses and all five reopening mutations. Without this, round five will find the eighth spelling.
5. Refresh the PR title and body.

Items 1–3 and 5 are mechanical. Item 4 is the one that would actually close the class, and it is the same conclusion the D-069 ruling reached one level up: stop asking "does this line look like a heading/fence?" and start comparing against something that already knows.
