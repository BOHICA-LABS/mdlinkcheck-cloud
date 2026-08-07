# PR Review — PR #3 @ `51e6be8` (D-028 final fresh-eyes review)

- **PR:** #3 `fix(spec-lint): eliminate vacuous-test defect class + P4-021 fixes`
- **Branch:** `feature/spec-lint-hardening` → `develop`
- **Head SHA reviewed:** `51e6be8df98653779148d624b89749c74c3e1a46` (confirmed via `gh pr view 3 --json headRefOid` — no drift)
- **Diff:** 7 files, +1568 / −255. Primary: `scripts/spec-lint/check-index-integrity.py` (+234/−30), `scripts/spec-lint/selftest/run-selftests.sh` (+1255/−170)
- **Advisory CI:** `Spec lint` FAILURE is advisory per D-029/D-032 (25 known `[filled by story-writer]` violations) — **not** reported as a finding.

---

## Verdict

**REQUEST_CHANGES**

---

## Stopgap assessment (direct answer to the central question)

The central question was: *is "narrowed pre-filters plus an honestly documented residual" an acceptable stopgap to merge now?*

**The premise does not hold at this SHA, so the question is moot.** "Narrowed pre-filters + documented residual" would be a defensible stopgap if the residual were (a) genuinely only theoretical, and (b) accurately documented. Neither is true here:

1. **The fourth bypass is not hypothetical — I built five of them, and all five produce a false PASS.** The sharpest is a single `### Wave 2` line: inserting one h3 subheading into `## Authored Scenarios` silently drops every subsequent row, uncounted and unparsed. I ran the identical defect rows with and without that one line: **exit 1 (2 violations reported) without it, exit 0 with it.** This is not a new defect class; it is BI-033 / B-8 / B-11 recurring for the fifth time through a fifth pre-filter shape, and it is *worse* than A1/A2a/A2b because it drops an unbounded number of rows rather than one.

2. **The documented residual is documented inaccurately, in the direction that understates risk.** Three separate comments (`:146`, `:233`, `:478`) enumerate the pre-filters and assert that "empty-cell rows" are excluded from `hs_rows_seen`. That is false at this SHA — I verified empirically that both all-empty and empty-first-cell rows *are* counted (that was the entire point of the A2a fix, and it is asserted correctly four lines later at `:151-154`, contradicting `:146`). More importantly, all three enumerations **omit the section-scope pre-filter entirely** — the one pre-filter that actually carries the live residual. A maintainer reading these docstrings would conclude the residual is confined to pre-separator header rows. It is not.

So the honest characterisation of this SHA is not "structural independence deferred with a documented residual." It is "three known instances patched; a fourth, larger instance live and undocumented." Merging on the strength of a residual disclosure that does not describe the actual residual is exactly the failure mode D-039/D-050 exist to prevent.

**What I am *not* saying.** The rest of this PR is strong, and I want to be explicit that the blocker is narrow:
- The 24/24 suite is real. I ran it at this SHA: `Selftest passed: 24/24 negative tests verified (each proved clean-pass + defect-fail)`.
- A1, A2a, A2b are genuinely closed and genuinely mutation-verified — I built the three mutants independently and each flips exactly its own test and no other (matrix below).
- The B-9 accounting invariant is load-bearing, not decorative — removing it regresses A2a *and* A2b to exit 0.
- There is no suppression construct in this diff. The diff *removes* one and adds a structural guard against the class.
- The remediation for the blocking findings is small (see "Recommended minimal remediation"). This does not need another architectural round; it needs roughly 5 lines and 2 fixtures in the existing pattern.

I would also note, since it bears on the merge decision: the argument "no production Rust code depends on this yet" cuts the wrong way. This checker *is* the gate that Phase 3 will rely on. Merging it with a live false-PASS path means the gate ships already-bypassable, and the two follow-on structural stories will be written against a baseline that is believed cleaner than it is.

---

## Path enumeration — `get_hs_data()`, `check-index-integrity.py:186-262`

Every path through the row loop, in source order. "Counted" = reaches `hs_rows_seen += 1` at `:235`.

| # | Line | Condition / pre-filter | Row counted? | Assessment |
|---|------|------------------------|--------------|------------|
| P1 | `:194-197` | `line.startswith("##")` → set `in_authored_scenarios`, reset `found_separator`, `continue` | **NO** | Correct for headings themselves. But matches `##`, `###`, `####` … and sets scope `False` for any heading not containing the literal `"Authored Scenarios"` — **including a subheading inside the section**. Root cause of BLOCKING-1. |
| P2 | `:199-200` | `not in_authored_scenarios` → `continue` | **NO** | Unbounded silent drop, no accounting bucket. Rows here are invisible to the parser, the counter, and the invariant. BLOCKING-1. |
| P3 | `:201-202` | `not line.startswith("\|")` → `continue` | **NO** | Pipeless rows are valid GFM table rows (leading/trailing pipes are optional). Silent drop, uncounted. MAJOR-1. |
| P4 | `:206-207` | `not cells` → `continue` | **NO** | **Dead code.** `"".split("\|")` returns `['']`, so `cells` is never falsy. MINOR-4. |
| P5 | `:216-218` | `first_cell and all(set(c) <= set("-: ") for c in cells if c)` → separator, `continue` | **NO** | Correctly narrowed by B-11. Verified: A2a (`\|  \| EC-999 \|`) and A2b (`\| - \| EC-999 \|`) no longer match; both fall through and are counted. Correct non-data exclusion. |
| P6 | `:220-228` | `not found_separator` **and** first cell fails `^\|\s*(?:~~)?(?:HS-\d+\|[Hh][Ss][-_])` → `continue` | **NO** | Narrowed by B-11 to admit HS-shaped rows (closes A1). **But the regex is now a shape allowlist**: any pre-separator row whose ID cell is HS-ish in a shape the regex does not enumerate is still dropped uncounted. BLOCKING-2. |
| P7 | `:235` | all pre-filters passed | **YES** | Counted. Denominator of the accounting invariant. |
| P7a | `:238-241` | canonical active `\| HS-NNN \| EC-NNN \|` | YES | Classified → `hs_canonical`. Forward/reverse checks apply. |
| P7b | `:243-246` | retired `\| ~~HS-NNN~~ \| ~~EC-NNN~~ \|` | YES | Classified → `hs_canonical`. |
| P7c | `:249-252` | HS-NNN present, EC cell unrecognised | YES | Classified → `MALFORMED` → `hs_nonconforming`; reported at `:466-470`. |
| P7d | `:257-260` | near-miss HS-like ID | YES | Classified → `near_misses` → `hs_nonconforming`; reported at `:459-464`. |
| P7e | fallthrough | counted, matched none of P7a-d | YES | **Not classified** → accounting invariant at `:485` fires. Fail-closed. This is the safety net, and it works — but only for rows that reach `:235`. |

**Summary of the counting position.** The counter sits at `:235`, i.e. *below* six pre-filters (P1-P6). Four of them (P1, P2, P3, P6) can drop a real data row with no accounting trace whatsoever. P5 and P4 are correct/dead. The accounting invariant at `:485` is a sound net for everything at or below `:235` and worthless for everything above it. This is the structural non-independence the PR acknowledges — and it is load-bearing, not academic.

---

## Fourth-bypass attempt

I extracted the checker at `51e6be8` to `/tmp/cii_51e6be8.py` and built an isolated fixture harness mirroring the selftest pattern (`/tmp/b11probe/probe.py`). Baseline clean tree verified: `exit=0`, `HS (1 validated, 0 non-conforming, 1 rows seen)`.

Every probe below adds a row mapping to `EC-999`, for which **no `wave-scenarios/EC-999-*.md` file exists**. A correct checker must exit 1 on all of them.

| Probe | Shape | Result |
|-------|-------|--------|
| **C1** | h3 subheading inside `## Authored Scenarios` | **exit 0 — FALSE PASS** |
| **C2** | pipeless GFM row after the separator | **exit 0 — FALSE PASS** |
| **C3** | single-tilde `\| ~HS-042~ \|` pre-separator | **exit 0 — FALSE PASS** |
| **C4** | bold `\| **HS-042** \|` pre-separator | **exit 0 — FALSE PASS** |
| **C5** | markdown-link `\| [HS-042](…) \|` pre-separator | **exit 0 — FALSE PASS** |
| C6 | bold `\| **HS-042** \|` **after** separator (control) | exit 1 — caught by invariant |
| C7 | row under a later `##` section (`Reserved IDs`) | exit 0 — by design (see MINOR-5) |
| C8 | *all* rows pipeless (total drop) | exit 1 — caught by the reverse check |
| D1 | all-cells-empty row | exit 1 — **counted**, contradicting `:146`/`:233`/`:478` |
| D2 | empty-first-cell row | exit 1 — **counted**, contradicting `:146`/`:233`/`:478` |
| E1 | H1 (`#`) heading does not reset scope | exit 1 — over-inclusive, fail-closed |

**The decisive pair — C1 vs C1-control.** Identical defect rows; the only difference is one inserted `### Wave 2` line.

Without the subheading (`exit=1`, 2 violations):
```
| HS ID | EC ID | Title | Notes | BCs | Status |
|-------|-------|-------|-------|-----|--------|
| HS-001 | EC-156 | Selftest scenario | Notes | BC-2.01.001 | active |
| HS-042 | EC-999 | Orphan: no wave-scenarios file exists | Notes | BC | active |
| hs_043 | ~~EC-998~~ | Near-miss ID + retired EC | Notes | BC | active |
```
```
HS-INDEX.md: HS row with non-canonical ID 'hs_043' — expected 'HS-<digits>' or '~~HS-<digits>~~'
HS-INDEX.md: HS entry 'HS-042' maps to 'EC-999' — no wave-scenarios file found for this EC ID
Check FAILED: 2 index integrity violations found (14 structural checks)
```

With one subheading inserted (`exit=0`, silence):
```
## Authored Scenarios

| HS ID | EC ID | Title | Notes | BCs | Status |
|-------|-------|-------|-------|-----|--------|
| HS-001 | EC-156 | Selftest scenario | Notes | BC-2.01.001 | active |

### Wave 2

| HS ID | EC ID | Title | Notes | BCs | Status |
|-------|-------|-------|-------|-----|--------|
| HS-042 | EC-999 | Orphan: no wave-scenarios file exists | Notes | BC | active |
| hs_043 | ~~EC-998~~ | Near-miss ID + retired EC, also invisible | Notes | BC | active |
```
```
Check passed: 14 structural checks — … HS (1 validated, 0 non-conforming, 1 rows seen) all consistent
```

Two violations disappear and the success line reports `1 rows seen` — the invariant holds vacuously at `1 == 1 + 0`. This is the BI-033 / B-8 "zero-items → false PASS" shape reproduced exactly, one pre-filter to the left.

**Why C1 is realistic, not contrived.** The real `HS-INDEX.md` currently has six `##` sections and grows per wave. `### Wave 2` / `### Wave 3` subheadings under `## Authored Scenarios` is the single most obvious way a story-writer or state-manager would organise a growing scenario table. It requires no adversarial intent — it is ordinary editing that silently disables the gate.

**What I could not break.** For completeness, these attempts failed to produce a false PASS, i.e. the checker held: rows after the separator with any unrecognised ID shape (bold, empty, all-empty, dash-only, single-tilde) are all counted and caught by the accounting invariant; total-drop scenarios are caught by the reverse check because `wave-scenarios/` files still exist without a matching entry; leading/trailing whitespace and indentation are correctly normalised by `raw.strip()` at `:190`; and duplicate detection at `:520-532` reads the raw file independently of `get_hs_data()`, so it is unaffected by all of the above.

---

## Findings

### BLOCKING-1 — Any subheading inside `## Authored Scenarios` silently disables all downstream row detection
`scripts/spec-lint/check-index-integrity.py:194-200`

`if line.startswith("##")` matches every ATX heading of level 2 *or deeper*, and then sets `in_authored_scenarios = "Authored Scenarios" in line`. An h3 or h4 nested *inside* the Authored Scenarios section therefore sets scope to `False`, and `:199-200` drops every subsequent row before the counter at `:235`. The drop is unbounded, leaves no accounting trace, and the invariant at `:485` holds vacuously.

**Failure scenario:** verified above (C1). Add `### Wave 2` under `## Authored Scenarios` with a table containing `| HS-042 | EC-999 | … |` and `| hs_043 | ~~EC-998~~ | … |`, where no `wave-scenarios/EC-999-*.md` or `EC-998-*.md` exists. Checker exits **0** and prints `HS (1 validated, 0 non-conforming, 1 rows seen) all consistent`. Removing only the `### Wave 2` line makes it exit 1 with 2 violations. Same defect class as BI-033 / B-8 / B-11.

**Suggested fix (one line):** only level-2 headings should change section scope, so nested subheadings stay in scope.
```python
if line.startswith("#"):
    level = len(line) - len(line.lstrip("#"))
    if level <= 2:                       # only h1/h2 delimit sections
        in_authored_scenarios = "Authored Scenarios" in line
        found_separator = False
    continue
```
This also resolves the MINOR-3 H1 asymmetry. Mutation-verifiable with the existing fixture pattern: revert to `startswith("##")` and the new test flips alone.

---

### BLOCKING-2 — The narrowed pre-separator gate is a shape allowlist; HS-ish rows in unenumerated shapes are still dropped uncounted
`scripts/spec-lint/check-index-integrity.py:220-228`

The B-11 narrowing admits a pre-separator row only if its first cell matches `^\|\s*(?:~~)?(?:HS-\d+|[Hh][Ss][-_])`. That closes exactly the A1 shape and leaves every other HS-ish shape dropped without being counted. Functionally this is an allowlist of recognised ID spellings — the "narrowed regex that functions as an allowlist" form that D-039 forbids. The proof that it is a recognition artefact and not a real structural distinction: the **same row** is caught after the separator (C6, exit 1 via the invariant) and silently dropped before it (C4, exit 0).

**Failure scenario:** verified above (C3/C4/C5). Place any of `| ~HS-042~ | ~EC-999~ | … |`, `| **HS-042** | EC-999 | … |`, or `| [HS-042](wave-scenarios/EC-999.md) | EC-999 | … |` above the `|---|` separator with no `EC-999` file. Checker exits **0** in all three cases.

**Suggested fix:** identify the column-header row *positionally* rather than by ID shape, so no regex is load-bearing for the drop decision. The header row is, by GFM definition, the row immediately preceding the separator — buffer pre-separator rows and, once the separator is seen, discard exactly one (the last) as the header and push the rest through the counter:
```python
if not found_separator:
    pending.append(line)      # do not decide anything from the cell's shape
    continue
# on separator detection: pending[:-1] are misplaced data rows → count + classify
```
Mutation-verifiable: revert to the regex gate and only the new test flips.

---

### MAJOR-1 — Pipeless GFM table rows are dropped uncounted
`scripts/spec-lint/check-index-integrity.py:201-202`

GFM does not require leading or trailing pipes on table rows; `HS-042 | EC-999 | …` renders as a table row. `not line.startswith("|")` drops it before the counter.

**Failure scenario:** verified above (C2). Append `HS-042 | EC-999 | Bogus pipeless row | Notes | BC | active` to a valid Authored Scenarios table with no `EC-999` file. Checker exits **0**, reporting `1 rows seen`. (Note C8: if *all* rows are pipeless the reverse check catches it, so only the mixed case is exploitable — which is also the more likely accident.)

**Suggested fix (fail-closed, cheap):** treat an in-scope non-pipe line containing a cell delimiter as a nonconforming row rather than skipping it.
```python
if not line.startswith("|"):
    if "|" in line and re.search(r"[^|]\|[^|]", line):
        hs_rows_seen += 1     # counted → unclassified → invariant fires
    continue
```

---

### MAJOR-2 — Residual documentation is inaccurate in the risk-understating direction (three places)
`scripts/spec-lint/check-index-integrity.py:146`, `:233`, `:478`

Two distinct problems:

**(a) A claim that is factually false at this SHA.** All three comments assert that "empty-cell rows" are excluded from `hs_rows_seen`:
- `:146` — "*NOT independent of the structural pre-filters (non-pipe lines, empty-cell rows, and confirmed-non-HS pre-separator rows are excluded)*"
- `:233` — "*Rows excluded earlier (non-pipe lines, empty-cell rows, confirmed header rows, separator rows) are correct non-data exclusions.*"
- `:478` — "*Rows excluded by the structural pre-filters (non-pipe lines, empty-cell rows, column-header rows, separator rows) are not covered by this invariant*"

Empty-cell rows are **counted**, not excluded — I verified this directly (probes D1, D2 both exit 1 via the invariant with `2 data row(s) seen`). Including them was the entire point of the A2a fix, and `:151-154` in the same docstring correctly says so, directly contradicting `:146` nine lines above. `:233` and `:478` additionally label the exclusion "correct", which would tell a maintainer that re-introducing the A2a bypass is the intended design.

**(b) The load-bearing omission.** All three enumerations list the pre-filters as *non-pipe lines / empty-cell rows / header rows / separator rows*. None mentions the **section-scope pre-filter** (`:199-200`) — the widest silent-drop path in the function and the one carrying BLOCKING-1. A reader concludes the residual is limited to malformed pre-separator header rows. It is not.

**Failure scenario:** a maintainer implementing the deferred structural story reads `:146` and `:478`, believes the residual is confined to pre-separator/header shapes, moves the counter above P4/P5/P6 only, leaves P1/P2 untouched, and closes the story as "structural independence achieved" while BLOCKING-1 remains live. The docstring actively misdirects the follow-on fix.

**Suggested fix:** replace all three enumerations with the actual list — *(section-scope drops, non-pipe lines, separator rows, and pre-separator rows whose first cell does not match the HS-shape regex)* — delete "empty-cell rows" from all three, delete the word "correct" from `:233`/`:478`, and state plainly that section-scope drops and pre-separator shape drops are **not** covered by the invariant.

---

### MINOR-1 — PR body does not disclose the residual
The body says "*B-11 stopgap: three pre-filter bypasses closed … Docstring and invariant comment corrected to remove false independence claims*" and lists `F-16: accounting invariant claim softened to match code reality`. The word "stopgap" hints at incompleteness, but the body never states that the counter still sits below the pre-filters, that structural independence is not achieved, or that further bypass shapes are considered possible. A reviewer reading only the description would reasonably conclude B-11 is closed. Add one explicit "Known residual" section naming the un-counted pre-filter paths and the tracked follow-on stories.

### MINOR-2 — `run_suppression_guard` fail-open persists (BI-037), ordering intact
`scripts/spec-lint/selftest/run-selftests.sh:452-476`. `run_override_guard` uses `if ! grep …` (read error → non-zero → guard fires, fail-closed); `run_suppression_guard` uses `if grep …` (read error → treated as no match, fail-open). Guard 1 runs first at `:104-106` and exits 2, so guard 2's fail-open is unreachable — confirmed, and the F-15 comment at `:496-504` documents the dependency accurately and warns against reordering. **This diff does not perturb the ordering.** Not a blocker; worth converting guard 2 to the fail-closed form so the invariant does not depend on execution order. Also note both guards iterate `check-*.py` only, so a checker added under any other filename escapes both.

### MINOR-3 — H1 headings do not reset section scope (asymmetric with `##`)
`scripts/spec-lint/check-index-integrity.py:194`. `startswith("##")` misses `#`, so an H1 section following Authored Scenarios keeps scope `True` and its rows are parsed (verified: E1 exits 1). Over-inclusive and therefore fail-closed, so harmless today — but it means "section scoping" behaves differently for h1 vs h2 vs h3+. The BLOCKING-1 fix resolves this.

### MINOR-4 — Dead branch
`scripts/spec-lint/check-index-integrity.py:206-207`. `if not cells: continue` is unreachable: `"".split("|")` returns `['']`, so `cells` is always a non-empty list. Remove it, or the reader will over-estimate the pre-filter coverage.

### MINOR-5 — Rows misfiled into a non-Authored section are invisible by design
Verified (C7): a fully-formed authored row placed under `## Reserved IDs — Not Yet Authored` is never forward-checked. Excluding the Reserved IDs table is correct and intentional (F-12), so this is not a defect. But it is the same accounting hole in benign clothing: there is no bucket that would notice an authored row in the wrong section. Once the counter moves above the pre-filters, out-of-section pipe rows should land in an explicit "out-of-scope, reason=section" bucket rather than vanishing.

---

## Residual accuracy (review item 3)

Assessed at `:142-147`, `:169-175`, `:472-482`.

| Docstring block | Claim | Accurate? |
|---|---|---|
| `:141-150` | `hs_rows_seen` is "independent of the four regex patterns" | **Yes.** Verified: probes C6/D1/D2 all reach `:235` and trip the invariant precisely because the counter does not depend on the parser patterns. |
| `:146` | Pre-filter exclusions are "non-pipe lines, empty-cell rows, and confirmed-non-HS pre-separator rows" | **No.** Empty-cell rows are counted (D1, D2). Section-scope drops are omitted. MAJOR-2. |
| `:151-154` | A2a/A2b/A1 rows "are now counted and reported" | **Yes.** Mutation matrix confirms all three. Directly contradicts `:146`. |
| `:169-175` (F-12) | "Non-HS-pattern rows before the separator … are silently skipped and never counted"; "HS-pattern rows before the separator … fall through to be counted" | **Yes, and admirably candid** — this is the most honest sentence in the file. It states the residual outright. It just does not draw the conclusion that "non-HS-pattern" is regex-shape-defined, which is BLOCKING-2. |
| `:472-482` | Invariant does not cover "non-pipe lines, empty-cell rows, column-header rows, separator rows"; B-11 closes "the third instance of the BI-023 shared-filter bypass" | **Partly.** The non-coverage framing is right in spirit but the enumeration is wrong (empty-cell rows) and incomplete (no section scope). "Third instance" is accurate as of the fix but there is now a fourth. |

**Verdict on item 3:** the docstrings do **not** overstate the *strength of the invariant* — that part is scrupulous, and I want to credit it. What they get wrong is the *inventory of what escapes it*: one item on the list is false, and the largest item is missing. Since the stated purpose of these docstrings is to hand an accurate residual to the follow-on structural story, an inventory that misdirects that story is a substantive defect, not a wording nit. Hence MAJOR, not MINOR.

---

## Verification notes (review items 4-7)

### Item 4 — A1 / A2a / A2b mutation verification: **CONFIRMED**
I built four mutants from the head source independently of the PR's own claims and ran the three defect fixtures against each. `exit 1 = defect detected (test passes)`, `exit 0 = defect missed (test fails)`:

| Checker | A1 (row above separator) | A2a (empty first cell) | A2b (dash-only first cell) |
|---|---|---|---|
| **HEAD `51e6be8`** | exit 1 DETECT | exit 1 DETECT | exit 1 DETECT |
| M-A1 — revert `:220-228` to unconditional `continue` | **exit 0 MISSED** | exit 1 DETECT | exit 1 DETECT |
| M-A2a — re-admit empty first cell as separator | exit 1 DETECT | **exit 0 MISSED** | exit 1 DETECT |
| M-A2b — revert `:216` to first-cell-only test | exit 1 DETECT | exit 1 DETECT | **exit 0 MISSED** |
| M-INV — remove the `:485` accounting invariant | exit 1 DETECT | **exit 0 MISSED** | **exit 0 MISSED** |

Each of the three fixes is independently load-bearing, and each mutant flips exactly its own test — no over-determination. This matches the PR body's MUT-A1/A2a/A2b claims exactly. The three closed bypasses are genuinely closed.

On the D-040/D-050/D-057 point that mutation verification is necessary but not sufficient: the durable positive-coverage criterion is also satisfied. `run-selftests.sh` pins `EXPECTED_TEST_COUNT=24` (`:30`) and enforces two post-test structural guards — `TESTS_RUN == EXPECTED_TEST_COUNT` and `TESTS_WITH_CLEAN_PASS == TESTS_RUN` — each exiting 2. Every test increments `TESTS_WITH_CLEAN_PASS` only on a real clean-tree exit-0, so a test cannot be counted without a genuine positive assertion. I executed the suite at this SHA from an isolated export of the tree: `Selftest passed: 24/24 negative tests verified (each proved clean-pass + defect-fail)`.

### Item 5 — Suppression check (D-039): **CLEAN, with one caveat**
No allowlist, skip-list, deferral set, or known-issues collection is introduced. The diff moves in the opposite direction:
- `check-ec-injectivity.py` −13: the `KNOWN_EC_COLLISIONS_PHASE2_DEFERRAL` commentary block and its deferral branches are deleted; the checker now reports all real collisions (2, on the real tree).
- `run-selftests.sh` adds `run_suppression_guard` with a single canonical `SUPPRESSION_PATTERN` (`:426`) covering `ALLOWLIST|_DEFERRAL|SKIP_LIST|SKIP_SET|KNOWN_COLLISIONS|KNOWN_VIOLATIONS|KNOWN_ISSUES|WHITELIST|SUPPRESS_SET`, wired into both the pre-flight check and guard test G2 from that one definition — so a mutation to the pattern flips both.
- I grepped the full diff for allowlist-shaped constructs and hardcoded exemptions: none.

**Caveat, already filed as BLOCKING-2:** the narrowed pre-separator regex at `:226` is a disguised instance of the pattern D-039 targets — a shape allowlist that decides which rows are eligible to be seen at all. It is not a *named* allowlist and the guard cannot detect it, which is precisely why it needs to be caught in review.

### Item 6 — Accounting invariant (B-9): **HOLDS, still load-bearing, not weakened**
Present at `:483-491`. `hs_rows_seen != hs_canonical + hs_nonconforming` → violation. `hs_nonconforming` correctly uses `len(near_misses)` (F-13's list, preserving duplicate rows) plus the `MALFORMED` count, so duplicate near-miss rows can no longer collide away. The narrowing *strengthened* it: A2a/A2b rows now land in the denominator, and M-INV above proves both regress to exit 0 without it. Test 10f covers it directly. The invariant is genuine — its only limitation is jurisdictional: it cannot see anything dropped above `:235`, which is BLOCKING-1/2.

### Item 7 — Guard ordering (BI-037): **NOT PERTURBED**
`run_override_guard` at `:104-106`, `run_suppression_guard` at `:507-509`, both `exit 2` on fire. Guard 1 precedes guard 2, so an unreadable checker trips the fail-closed guard first and guard 2's fail-open remains unreachable. The F-15 comment at `:496-504` documents this dependency accurately, including the warning not to reorder without fixing guard 2's error handling. G3 confirms both guards fail closed on an empty checker directory. See MINOR-2.

### Secondary — PR body accuracy (BI-038): **CORRECT at this head**
The body reads `Selftest passed: 24/24 negative tests verified` (matches my run exactly) and references `get_hs_data()`, not the stale `get_hs_ec_mapping()`: "*replaced dead `get_actual_hs_files()` stub with `get_hs_data()` + `get_actual_wave_scenario_ec_ids()`*". The per-checker coverage table lists A1/A2a/A2b under `check-index-integrity`. BI-038 is legitimately closed. The only description gap is MINOR-1 (residual not disclosed).

### Other diff hunks reviewed
- `.gitignore` +5: adds `__pycache__/`, `*.pyc`, `*.pyo`. In scope (the suite now runs Python checkers repeatedly). No concern.
- `selftest/fixtures/bad-adr-exit-code.md` +1/−2: removes two sentences containing `dns-failure` / `http-indeterminate` reason codes from a fixture. Correct — the fixture exists to test exit-2-on-broken-link, and the stray reason codes were incidental content that other checkers could trip over. No concern.
- Diff size: 1568 additions is over the 500-line flag threshold, but ~1255 of it is the negative-test suite, which is the deliverable. Not a finding.
- Commit quality: conventional format throughout, each commit scoped to its finding IDs. Good.
- Demo evidence: N/A — this is CI tooling with executable test evidence in place of recordings, and that evidence is reproducible (I reproduced it).

---

## Recommended minimal remediation

Ordered by cost. The first two clear the blockers; none requires the deferred structural rewrite.

1. **BLOCKING-1** — gate section scope on heading *level* (h1/h2 only). ~4 lines at `:194`. Also fixes MINOR-3. New fixture: h3 subheading + orphan row. Mutation: revert to `startswith("##")`.
2. **BLOCKING-2** — replace the shape-regex header gate with positional header identification (buffer pre-separator rows; discard exactly the last one as the header, count the rest). ~6 lines at `:220-228`. New fixture: `| **HS-042** | EC-999 |` above the separator. Mutation: restore the regex gate.
3. **MAJOR-1** — count in-scope pipeless delimiter lines instead of skipping them. ~3 lines at `:201`. New fixture: pipeless orphan row. Fail-closed via the existing invariant.
4. **MAJOR-2** — correct all three pre-filter enumerations (`:146`, `:233`, `:478`): drop "empty-cell rows", add section-scope and pre-separator-shape drops, drop the word "correct".
5. **MINOR-1** — add a "Known residual" section to the PR body naming the un-counted paths and the two tracked follow-on stories.

MINOR-2/3/4/5 can ride with the follow-on structural stories.

Once 1-3 land with their mutation-verified fixtures (suite at 27/27), I would expect to approve. I would also suggest the follow-on structural story adopt **total row accounting** rather than only relocating the counter: count every table-shaped line in the file *before* any pre-filter, and require `total == in_scope_classified + Σ(explicitly-bucketed out-of-scope drops, each with a reason)`. That makes "dropped without a trace" unrepresentable, which is the property four consecutive cycles have been reaching for. Relocating the counter above today's six pre-filters fixes today's six; it does not prevent pre-filter number seven.

---

## Reproduction artefacts

All probes are outside the repo and modified nothing in it:
- `/tmp/cii_51e6be8.py` — checker extracted via `git show 51e6be8:scripts/spec-lint/check-index-integrity.py`
- `/tmp/b11probe/probe.py` — isolated fixture harness + clean baseline
- `/tmp/b11probe/attack.py`, `/tmp/b11probe/attack2.py` — probes C1-C8, D1-D2, E1
- `/tmp/b11probe/mutate.py` — mutation matrix (M-A1, M-A2a, M-A2b, M-INV)
- `/tmp/slt51/scripts/spec-lint/` — full tree at `51e6be8` via `git archive`, used to run the 24/24 suite
