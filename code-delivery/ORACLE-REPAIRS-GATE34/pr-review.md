# PR Review — ORACLE-REPAIRS-GATE34 (cycle 4)

**PR:** #11 — `fix/oracle-repairs-gate34` → `develop`
**Reviewed SHA:** `7e4a8f014a2e09e59757d1e26dbc4ce6073e1770`
**Incremental base (cycle 3):** `9bc2d052b16574190d8d2130b78de3850e128b88`
**Incremental diff:** 6 files, +135 / −129 (2 commits)

## Scope note

This is an incremental review of the two commits added since cycle 3. Cycle-1/2/3 findings
that were already dispositioned are not re-litigated. `WARNING-7` (stale `82/82` evidence)
and `WARNING-8` (Branch A prose false positive) were the two open non-blocking items from
cycle 3; both are addressed here. `ADVISORY-9` (TV skip audit completeness) remains
deferred by agreement and is untouched by this diff.

Red spec-lint CI is the intended deliverable of this PR and is not treated as a defect.
No suggestion in this review asks for any change under `.factory/specs/` or
`.factory/holdout-scenarios/`.

---

## Verification performed

Every claim below was executed, not read.

| # | Check | Result |
|---|-------|--------|
| 1 | `is_header_row` guard removed from Pattern 1 table branch | CONFIRMED — variable and its `not is_header_row` conjunct are gone; the remaining guard is `not is_table_separator_row(cells) and current_reason_col_p1 is not None and current_reason_col_p1 < len(cells)` |
| 2 | Corpus baseline byte-identical to cycle 3 | CONFIRMED — `4 violations found (79 reason-code occurrences validated across 126 files scanned + 8 ADRs routed to POLICY 12 = 134 of 134 spec files (complete), 4 non-conforming)` |
| 3 | Full selftest suite | CONFIRMED — `Selftest passed: 91/91 negative tests verified (each proved clean-pass + defect-fail)`, exit 0 |
| 4 | Selftest 5j mutation-verified | CONFIRMED — restoring the `is_header_row` guard makes 5j fail: `STRUCTURAL FAIL: checker exited 0 but reported 0 occurrences — row was silently skipped`, followed by `STRUCTURAL GUARD FAILED: only 90/91 tests had a clean-pass assertion`. Working tree restored afterward; `git status --porcelain` clean. |
| 5 | Selftest 5j is non-vacuous | CONFIRMED — the phantom now sits on the **same** row as the bare `reason` cell (`\| reason \| \`phantom-5j\` \| x \|`), and the clean leg asserts `grep -q "[1-9][0-9]* reason-code occurrences validated"`, which is what actually catches the mutation. This is the correct fix for the vacuity that made the old 5j pass under the bug. |
| 6 | WARNING-8 prose cell no longer flagged | CONFIRMED — `` `pulldown-cmark` handles this correctly per CommonMark `` no longer matches Branch A (backtrack-exhaustive, verified against the compiled pattern) |
| 7 | Selftest 5i still green (annotated `` `phantom-gamma` (per D-018) ``) | CONFIRMED — passes; `[...]`-form annotation also verified matching |
| 8 | Change isolation — 4-variant sweep | CONFIRMED — new/old regex × new/old guard, all four combinations produce identical corpus output (4 / 79 / 134). Neither change has any live corpus effect; both close latent holes. Notably this proves BLOCKING-6 itself had zero live corpus effect, so "no corpus delta" is the expected outcome, not a sign the fix is inert — selftest 5j is the proof of effect. |
| 9 | Demo evidence refreshed | CONFIRMED — `AC-002-selftest-91of91.txt` exists, final line is `Selftest passed: 91/91 …`; `AC-002-selftest-82of82.txt` deleted; `grep -rn "82of82\|82/82" docs/` returns nothing. WARNING-7 is closed. |
| 10 | `AC-003-oracle-repair-selftests.txt` refreshed | CONFIRMED — now lists all 22 branch-new selftests including 5e–5j and EI-4/5/6 |
| 11 | `evidence-report.md` provenance honesty | CONFIRMED — "refreshed at head SHA 4722ca1" is accurate: `7e4a8f0` touches only `docs/`, so the `scripts/` tree the evidence was recorded against is identical at both SHAs. Good practice. |
| 12 | Diff coherence | CONFIRMED — every hunk belongs to BLOCKING-6, WARNING-8, or evidence refresh. No drive-by changes. |
| 13 | Commit quality | CONFIRMED — conventional format, correct type (`fix` / `chore`), finding ID in subject |
| 14 | Diff size | CONFIRMED — 264 lines changed, well inside budget |
| 15 | Non-spec-lint CI failures (Clippy / Format / Test) | PRE-EXISTING, not attributable to this PR — every recent `develop` CI run (`f8ee4eb`, `d4e76fa`, `c2e5cf1`, `e1299b0`, `7b9aa6d`, …) fails identically. Not raised as a finding. |

I also re-derived the header-row safety argument the new comment asserts, rather than
taking it on faith. `current_reason_col_p1` is set only on the separator row from
`prev_row_cells`, and is reset to `None` on any non-table line — so a table's own header
row is always processed with `current_reason_col_p1 is None` and skipped, and no prior
table's index can survive into a later table (an intervening non-table line is required to
end a markdown table). The one case the removed guard used to absorb is a **repeated
mid-table header row**, which is now processed; I verified it is harmless: `Reason` fails
Branch B's `[a-z]` leading-class test, `Reason code` fails `fullmatch` on the space, and a
lowercase `reason` has no hyphen so `_is_reason_code_candidate` rejects it. **No false
positive is introduced by removing the guard.** The comment's claim is correct.

---

## Findings

### WARNING-9 — the WARNING-8 anchor closes a false positive by opening a narrower silent-skip class in Branch A

| Field | Value |
|-------|-------|
| Severity | suggestion (warning) |
| Category | coverage / oracle scope |
| File | `scripts/spec-lint/check-adr-consistency.py:359` |

First, credit where due: the implemented fix is **exactly** the remedy cycle 3 recommended,
including the `(?:\s*[([].*)?$` anchor. This finding is me auditing my own suggestion, and
the trade-off it carries was under-specified in cycle 3. That is on the review, not the
implementation.

The `$` anchor means Branch A now matches only when the cell is *nothing but* a backticked
token, optionally followed by an annotation opening with `(` or `[`. Any other trailing
content causes the whole cell to be skipped silently. Differential test of old vs. new
Branch A pattern over candidate cell shapes:

```
SAME  old='phantom-gamma'   new='phantom-gamma'   :: `phantom-gamma` (per D-018)
SAME  old='phantom-gamma'   new='phantom-gamma'   :: `phantom-gamma` [see D-018]
DIFF  old='pulldown-cmark'  new=None              :: `pulldown-cmark` handles this correctly   ← intended fix
DIFF  old='file-not-found'  new=None              :: `file-not-found`, `phantom-x`
DIFF  old='file-not-found'  new=None              :: `file-not-found` / `phantom-x`
DIFF  old='file-not-found'  new=None              :: `file-not-found` or `phantom-x`
DIFF  old='file-not-found'  new=None              :: `file-not-found`.
DIFF  old='file-not-found'  new=None              :: `file-not-found`;
DIFF  old='file-not-found'  new=None              :: `file-not-found` —
DIFF  old='file-not-found'  new=None              :: `file-not-found` - see note
DIFF  old='phantom-x'       new=None              :: `phantom-x`<br>note
DIFF  old='file-not-found'  new=None              :: `file-not-found`**
```

Failure scenario: the content-remediation workstream (the workstream this baseline exists
to serve) edits a Reason cell to `` | broken | `phantom-code`, `other-code` | `` or adds a
trailing period. Pattern 1 then reports zero occurrences for that row and no violation, and
nothing in the output indicates a row was dropped.

Why this is **not** blocking:

- Zero live corpus effect, proven by the 4-variant sweep (check #8): no Reason-column cell
  in the frozen corpus has any of these shapes, so the merged baseline of 4 / 79 / 134 is
  exactly as trustworthy as it was at cycle 3.
- It is a *narrowing of an already-narrow branch*, not a regression against `develop`. On
  the multi-code shapes Branch A was never correct: the old regex validated only the first
  of two codes, so this moves "1 of 2 checked" to "0 of 2 checked" — a degradation of a
  path that was already blind, not the creation of a blind spot where a sound one existed.
- The repo's own proof obligation is satisfied. The pre-flight guard's criterion for a
  scope reduction is a runtime corpus-**completeness** assertion (`N of M spec files`), and
  `check-adr-consistency.py` emits `134 of 134 spec files (complete)`. Cell-level coverage
  is explicitly outside what that guard proves, for every checker in the tree. Holding this
  one line to a standard the guard does not encode would be inventing a gate at merge time.
- The remaining ambiguous case is genuinely hard: `` `pulldown-cmark` handles this `` and
  `` `phantom-x` or `other` `` are not separable by delimiter alone, which is why the anchor
  approach was chosen.

Recommended follow-up for the content workstream (not this PR):

```python
# Allow any non-letter-leading trailing annotation, not just '(' / '['.
# Recovers `code`, `code`. `code`; `code` — `code`<br>… while still rejecting
# `pulldown-cmark` handles this correctly (trailing text starts with a letter).
m_simple = re.match(r"`([A-Za-z][a-zA-Z0-9-]{2,})`(?:\s*[^\sA-Za-z0-9].*)?$", reason_stripped)
```

The more thorough option is to switch Branch A to `re.finditer` over *every* backticked
token in the cell and gate the cell as prose by a separate discriminator (e.g. count of
unbackticked words), which would also fix the pre-existing multi-code blindness. Either way
it wants a selftest pair — a `` `phantom-x`, `phantom-y` `` defect arm and a
`` `pulldown-cmark` handles this correctly `` must-not-flag arm — so the boundary is pinned
by the suite rather than by a comment.

---

### WARNING-10 — new evidence report and PR body both undercount the branch's new selftests

| Field | Value |
|-------|-------|
| Severity | suggestion (warning) |
| Category | description accuracy |
| File | `docs/demo-evidence/ORACLE-REPAIRS-GATE34/evidence-report.md:59` |

The refreshed AC-3 section introduces the count `21` in three places ("21 new
oracle-repair selftests all pass", "New selftests added by this PR (21 total…)",
"Result: PASS — all 21 new tests pass"), but the table immediately below it has **22**
rows, and the enumeration `G5, P14-15/16/17, EI-1/2/3/4/5/6, 7b/7c/7d, 5b/5c/5d/5e/5f/5g/5h/5i/5j`
is also 22 items (1 + 3 + 6 + 3 + 9). Ground truth confirms 22:

```
develop:  Selftest passed: 69/69 negative tests verified
branch:   Selftest passed: 91/91 negative tests verified     → 91 − 69 = 22 new
```

`AC-003-oracle-repair-selftests.txt` correctly contains 22 entries, so only the summary
integer is wrong. Related, in the PR body: line 144 states selftests are "up from 75
pre-gate34" — the actual pre-branch baseline on `develop` is **69**, and 75 is consistent
with neither 69 nor `91 − 21`. Suggest `22` and `69` respectively. The headline `91/91`,
`134/134`, `10/10` and `0/15` claims all verify correct.

---

### WARNING-11 — PR body rollback instruction no longer covers the whole branch

| Field | Value |
|-------|-------|
| Severity | suggestion (warning) |
| Category | description accuracy |
| File | PR #11 body, line 325 |

The documented rollback is `git revert 9bc2d05 bc4b9c2 4c82538 57ad637 0002a20 c4ea0f2
a4bb910 c27d7fe 69c1a99 c59ec02 3d31dcf`, which was complete at cycle 3 but now omits
`4722ca1` and `7e4a8f0`. Running it as written would leave the BLOCKING-6 fix and the
refreshed evidence in the tree. Since this is the stated break-glass procedure for a PR
that deliberately turns CI red, it should be accurate at merge. Suggest prepending
`7e4a8f0 4722ca1`.

---

### NIT-12 — the two `` `? `` in the new Branch A pattern deviate from the reviewed remedy and widen it undocumentedly

| Field | Value |
|-------|-------|
| Severity | nit |
| Category | coherence |
| File | `scripts/spec-lint/check-adr-consistency.py:359` |

The implemented pattern is `` r"`?([A-Za-z][a-zA-Z0-9-]{2,})`?(?:\s*[([].*)?$" ``, whereas
the reviewed remedy had both backticks mandatory. Two consequences, neither harmful but
neither documented:

- The **leading** `` `? `` is dead code. Branch A is only entered under
  `reason_stripped.startswith("`")`, so the backtick is always present and never optional.
- The **trailing** `` `? `` is a scope *increase*: an unclosed cell such as
  `` `file-not-found `` (missing closing backtick) now matches, where the old pattern
  rejected it. Verified: `old=False new=True`.

Fail-loud and arguably an improvement, but the adjacent comment describes only the
annotation anchor and says nothing about accepting unclosed backticks — so the code is
doing something the comment does not claim. Either make both backticks mandatory (matching
the reviewed remedy) or document the unclosed-token tolerance as deliberate.

---

### NIT-13 — pre-existing Branch B comment contradicts the code it annotates

| Field | Value |
|-------|-------|
| Severity | nit |
| Category | coherence / stale comment |
| File | `scripts/spec-lint/check-adr-consistency.py:355` |

Carried in as unchanged context, so out of scope for this cycle, but noted while reading the
block the diff touches. The Branch A/B header comment states: *"Bare lowercase annotated
cells like `file-not-found (default)` are also handled here via re.match + [a-z]"* — Branch
B uses `re.fullmatch(r"([a-z][a-z0-9-]{2,})", …)`, which does **not** match
`file-not-found (default)`. Fold into whichever change next touches this comment block.

---

## Checklist

| # | Item | Status |
|---|------|--------|
| 1 | Diff coherence — all changes relate to the story | PASS |
| 2 | Description accuracy — PR body matches changes | PASS with WARNING-10 / WARNING-11 |
| 3 | Test coverage — changed lines covered | PASS for BLOCKING-6 (5j, mutation-verified). WARNING-8's boundary is uncovered — see WARNING-9 |
| 4 | Demo evidence present and current | PASS — 91/91 evidence replaces 82/82; no stale refs remain (closes WARNING-7) |
| 5 | Commit quality — conventional, finding-IDed | PASS |
| 6 | Diff size reasonable | PASS (264 lines) |
| 7 | Missing changes vs. stated scope | PASS — both cycle-3 open items addressed |
| 8 | Dependency status | PASS — no upstream PR dependency |

---

## Assessment

Both cycle-3 items are genuinely closed, and the BLOCKING-6 fix is the strongest work in
this branch so far. The important part is not the deletion of `is_header_row` — that alone
changes nothing observable, as my 4-variant sweep proves — it is that **selftest 5j was
rebuilt to be non-vacuous**. The old 5j placed the phantom on a *subsequent* row and
asserted only on exit codes, which is precisely why it passed while the bug was live. The
new version puts the phantom on the same row as the bare `reason` cell and adds a
`≥1 occurrence` assertion on the clean leg, and I confirmed by mutation that this
assertion — not the exit code — is what fires when the guard is restored. That is the
difference between a test that documents a fix and a test that holds it.

The header-row safety argument in the new comment is not hand-waving; I re-derived it
independently and also checked the one case the removed guard used to absorb (a repeated
mid-table header row), which is harmless because `Reason` fails Branch B's lowercase
leading-class test and a bare lowercase `reason` has no hyphen.

WARNING-9 is the one thing I would want the next workstream to carry. The anchor I
recommended in cycle 3 trades a loud latent false positive for a quiet latent false
negative, and I did not enumerate that when I recommended it. It does not block merge: the
frozen corpus contains none of the affected shapes, the baseline is provably unchanged, the
narrowed path was already blind to multi-code cells, and the repo's own scope-reduction
guard is satisfied by the file-completeness assertion the checker already emits. Inventing
a cell-level coverage gate at merge time — one no checker in the tree currently meets —
would be moving the goalposts on the last cycle. It belongs in the content workstream's
oracle backlog with the concrete regex and the two selftest arms above.

The remaining findings are documentation arithmetic (22 not 21, 69 not 75), a rollback
command that has fallen two commits behind, and two comment/code mismatches. None affect
the checker's behavior or the merged baseline.

The deliverable holds: `4 violations / 79 reason-code occurrences / 134 of 134 spec files`,
reproduced byte-identically to cycle 3, with 91/91 selftests each proving clean-pass and
defect-fail. Red spec-lint CI is the intended output. Clippy, Format, and Test failures are
pre-existing on `develop` and not attributable to this branch.

Zero blocking findings. Ready for operator merge.

VERDICT: APPROVE
