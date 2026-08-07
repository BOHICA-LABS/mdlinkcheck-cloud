# PR #3 — Scoped confirmatory review at `7c1eccf`

**Scope:** narrow delta review of `6e785b4..7c1eccf` only. This is not a re-review of PR #3.
The prior full review APPROVED at `6e785b4`
(`.factory/code-delivery/SPEC-LINT-GATE/pr-review-6e785b4.md`). This review re-establishes
verdict freshness at the current head and confirms the MAJOR-1 remediation.

**Head verified:** `gh pr view 3 --json headRefOid` → `7c1eccf5fb04a58acb52ca082563f4cb06364082`. No drift.

---

## Verdict

APPROVE

---

## Delta scope confirmation

**Comment-only: YES — proven, not inspected.**

`git diff --stat 6e785b4..7c1eccf` → `scripts/spec-lint/check-index-integrity.py | 27 +++---`,
1 file changed, 20 insertions, 7 deletions. No other file touched.

I did not rely on reading the diff. I proved semantic identity three independent ways:

| Check | Method | Result |
|---|---|---|
| Non-comment changed lines | strip `+`/`-` and leading whitespace from every diff hunk line, drop lines matching `^#` and blanks, count remainder | **0** |
| Abstract syntax tree | `ast.dump(ast.parse(...))` on `6e785b4:` vs `7c1eccf:` versions of the file | **IDENTICAL** |
| Token stream | `tokenize` both files, discard `COMMENT`/`NL`/`NEWLINE`/`INDENT`/`DEDENT`/`ENCODING`, compare | **IDENTICAL — 3719 vs 3719 tokens** |

AST and token-stream identity is a stronger guarantee than line inspection: it rules out logic,
regex-literal, control-flow, and test changes by construction, including any change that a
line-oriented grep for `#` could have missed. The orchestrator's zero-non-comment-lines finding is
**confirmed independently**.

Consequence: **`7c1eccf` cannot behave differently from `6e785b4` in any input.** Every behavioural
conclusion in the `6e785b4` review carries forward unchanged, by construction rather than by retest.

`git status` on the PR worktree: **clean** (empty `--porcelain`).

---

## MAJOR-1 fix confirmation

**FIXED.**

MAJOR-1 cited two defects in `check-index-integrity.py:742-743` — the `main()` B-9 invariant comment,
the file's single consolidated statement of what is excluded from the `data_row` bucket:

**(i) Stale guard description — fixed.** The comment said "not 4-space-indented," describing the
pre-D-070 `raw.startswith("    ")` implementation. It now reads (`:742-746`):

> `- Heading lines (CommonMark §4.2: #{1,6} + space/EOL, with < 4 COLUMNS of leading indent — checked via _leading_columns(raw), which expands tabs at 4-column stops per CommonMark §2.1 so '\t## X' is correctly treated as 4 columns, NOT a heading; the prior raw.startswith("    ") missed this — D-070 fix).`

Cross-checked against the implementation, not just against the finding text:
- `_leading_columns` is defined at `:38` and expands tabs via `col = (col // 4 + 1) * 4` — 4-column
  stops, matching the comment and CommonMark §2.1.
- Both call sites use exactly the guard the comment names: `:426` `if _leading_columns(raw) < 4 and _FENCE_RE.match(line):`
  and `:443` `if _leading_columns(raw) < 4 and _CM_HEADING_RE.match(line):`.
- `raw.startswith("    ")` appears nowhere in the file as a live predicate.

The comment now describes the code that exists. It also names the superseded spelling explicitly and
says why it was wrong, which directly defeats the MAJOR-1 failure scenario (a maintainer re-deriving
`raw.startswith("    ")` for a new downstream predicate).

**(ii) Surviving "closes … bypass class" — fixed.** `:747` now reads
`D-069 + D-070 NARROW the A/A2/A3/tab bypass class; the class is NARROWED, not closed.`
The fence bullet at `:754-758` received the same treatment and goes further, re-labelling the sink:
`NARROWS the A2 bypass; class is NARROWED, not closed — 'fenced_code' remains an unbounded sink for
any line inside a fence, including phantom HS rows.` Two further downgrades landed in the same block:
`:761` `only pending[-1] is eligible — narrows C bypass` (was "closes"), and `:766`
`prior re.search gate removed — narrows B bypass` (was "closes"). `:762` now labels `prose` an
`unbounded sink`.

**Whole-file sweep for residual "closed" claims.** `grep -inE 'clos(e|es|ed|ing)'` returns 11 hits.
Nine are either correct NARROWED-not-closed statements (`:29`, `:260`, `:287`, `:309`, `:747`, `:757`)
or unrelated (`:543`, `:551`, `:552` — YAML frontmatter closing `---` fence). The two remaining
affirmative "closes" claims are **scoped to a specific input shape, not to a bypass class**, and both
are literally true:

- `:57` (`_leading_columns` docstring) — "`raw.startswith("    ")` misses `\t## X` … This helper
  closes that gap." True: the gap named is the tab-vs-four-spaces spelling gap, and the helper does
  close it.
- `:424` — "D-070: unguarded-indented-fence bypass closed here." True: with the `< 4` guard a 4+-column
  fence no longer toggles fence state. Scoped to the indented-fence *shape*; the enclosing bullet at
  `:754-758` states the fence *class* is NARROWED-not-closed, so a reader is not misled.

**No site in the file now claims a bypass class is closed.** MAJOR-1's specific complaint — that
`:742-743` was the last such site — is resolved, and the fixture-vs-class distinction the D-070
ruling required is now consistent across all five previously-overclaiming blocks (the `6e785b4`
review scored 4 of 5; this commit lands the fifth).

---

## `\f` / `\v` documentation accuracy

**Documented, not fixed — correct per instruction. Accurate in mechanism; understated in extent.**

**Not fixed in code — confirmed.** AST and token-stream identity with `6e785b4` proves no code
change of any kind, so no out-of-scope fix was smuggled in. No scope violation.

**Mechanism claims — all verified true.** The block at `:748-753`:

> `Known residual: Python's str.splitlines() treats \f (form feed) and \v (vertical tab) as line boundaries; CommonMark does not. '\f## X' and '\v## X' therefore reach this branch and can kill section scope — verified at this head.`

| Claim | Verified |
|---|---|
| `str.splitlines()` treats `\f`/`\v` as line boundaries | YES — `'\f## X'.splitlines()` → `['', '## X']` |
| CommonMark does not | YES — CommonMark line endings are `\n`, `\r`, `\r\n` only |
| `'\f## X'` / `'\v## X'` reach the heading branch | YES — the derived second line is a clean h2 |
| Can kill section scope | YES — both exit **0** with a phantom `HS-099 / EC-999` row in `## Authored Scenarios`; output reads `HS (7 validated, 0 non-conforming, 7 rows seen)`, i.e. the phantom row is invisible |
| "verified at this head" | YES — reproduced at `7c1eccf` |

Not an overstatement. `str.splitlines()` is the honest root cause named, `_leading_columns` genuinely
cannot see it (it `break`s on the first non-space/non-tab character, returning 0), and the "do not fix
here" rationale is sound and consistent with the review history.

**One understatement — see MINOR-1 below.** The comment presents `\f` and `\v` as *the* `splitlines()`
residual. `str.splitlines()` splits on eight characters beyond `\n`/`\r`; I confirmed the other six
produce the identical bypass. The mechanism sentence is right; the enumeration is 2 of 8.

---

## Regression spot-check results

All executed at `7c1eccf`. Fixtures built by copying `.factory/` and `scripts/spec-lint/` to a fresh
temp dir per case and running with `SPEC_LINT_REPO_OVERRIDE=<tmpdir>`. No repo file was modified.

| Check | Expected | Result |
|---|---|---|
| Selftest suite (`scripts/spec-lint/selftest/run-selftests.sh`) | 36/36 | **PASS — `Selftest passed: 36/36 negative tests verified (each proved clean-pass + defect-fail)`** |
| Live repo (`python3 scripts/spec-lint/check-index-integrity.py`) | exit 0 | **PASS — exit 0, `80 structural checks — BC (66), VP (26), ADR, ARCH, L2, HS (7 validated, 0 non-conforming, 7 rows seen) all consistent`** |
| Property test (`--property-test`) | pass | **PASS — `300/300 cases verified (total_candidates == sum(buckets)), seed=42`** |
| `D-070-A`/`D-070-B` selftests present and passing | pass | **PASS — both named in suite output** |

Bypass spot-checks — phantom `HS-099 / EC-999` row injected inside `## Authored Scenarios`, preceded
by the killer line. Exit 1 = bypass closed (phantom detected); exit 0 = bypass open.

| Fixture | Expected | Actual |
|---|---|---|
| baseline, no killer line | 1 | **1** |
| `\t## Wave 2` (D-070-A, tab-as-indent) | 1 | **1** |
| `      ``` ` (6-column indented fence, D-070-B) | 1 | **1** |
| `#2 below` (D-069-A, `#` + digit is not a heading) | 1 | **1** |
| `### Wave 2` (h3 must stay in scope) | 1 | **1** |
| `\f## Wave 2` (documented residual W1) | 0 | **0** |
| `\v## Wave 2` (documented residual W2) | 0 | **0** |

All seven match expectation. The four previously-closed bypasses still exit 1; the two documented
residuals behave exactly as the new comment says they do. **No regression.** Given AST identity with
`6e785b4` this was the expected outcome — the value here is that it is now observed, not assumed.

`git status` clean on the PR worktree. Nothing modified under `.factory/specs/` or
`.factory/holdout-scenarios/` — `git -C .factory status --porcelain -- specs holdout-scenarios`
returns empty. **D-058 satisfied.**

CI: `Test`, `Build release`, `Clippy (deny warnings)`, `Format check`, `GitGuardian` all **pass**.
`Spec lint` fails and is **ADVISORY per D-029/D-032** — not treated as blocking, consistent with the
prior review.

---

## Findings

**BLOCKING: none.**

**MAJOR: none.**

### MINOR-1 — the `splitlines()` residual is 8 characters; the comment names 2
`scripts/spec-lint/check-index-integrity.py:748-753`

The block correctly identifies `str.splitlines()` as the root cause, then enumerates only `\f` and
`\v`. `str.splitlines()` splits on eight characters beyond `\n`/`\r`. I built the same phantom-row
fixture for the other six and every one reproduces the identical bypass at this head:

| Killer line | Result |
|---|---|
| `\x1c## Wave 2` (FILE SEPARATOR) | exit 0 — phantom hidden |
| `\x1d## Wave 2` (GROUP SEPARATOR) | exit 0 — phantom hidden |
| `\x1e## Wave 2` (RECORD SEPARATOR) | exit 0 — phantom hidden |
| `\x85## Wave 2` (NEL, U+0085) | exit 0 — phantom hidden |
| `\u2028## Wave 2` (LINE SEPARATOR) | exit 0 — phantom hidden |
| `\u2029## Wave 2` (PARAGRAPH SEPARATOR) | exit 0 — phantom hidden |

**Failure scenario.** The Option-3 story's landing gate is to be built from named negative fixtures,
and this comment is the in-code specification of what that gate must cover for the `splitlines()`
mechanism. A maintainer reads `:748-753`, writes two fixtures (`\f`, `\v`), and lands Option-3 with a
gate that passes while six equivalent spellings still hide a phantom HS row. `\u2028` is the realistic
one: it survives copy-paste from PDFs and some CMS exports and is invisible in every editor — exactly
the W3-NBSP paste scenario the prior review called most realistic, in a spelling nobody has written
down.

**Why MINOR and not blocking.**
1. **Not new and not a regression.** AST-identical to `6e785b4`; these six behaved identically there
   and at `f44147e`. `7c1eccf` did not create, widen, or re-enable them.
2. **Inside the knowingly-open class.** Same mechanism (`splitlines()` wider than CommonMark), same
   unbounded `prose` sink, same root cause the D-070 ruling deliberately carried to the Option-3
   "eliminate the parser" story. A real CommonMark block parse fixes all eight by construction.
   This is not a re-litigation of that ruling — the ruling stands.
3. **Directionally honest.** The comment says the class is NARROWED-not-closed and points at a
   tracking story. It undercounts the residual; it does not misrepresent its existence or its cause.
4. `spec-lint` is ADVISORY until the Phase 1 gate (D-029/D-032), so nothing is gated today.

**Suggestion.** One-line generalisation, no code change:

```
#     Known residual: Python's str.splitlines() splits on eight characters
#     CommonMark does not treat as line endings — \v \f \x1c \x1d \x1e \x85
#     \u2028 \u2029. All eight reach this branch as a clean heading and can
#     kill section scope (all eight verified exit 0 with a phantom HS row).
```

Recommend the Option-3 landing gate name the set as a **family** — assert no member of
`set(chr(c) for c in range(0x110000) if ('X'+chr(c)).splitlines() != ['X'+chr(c)])` can reach the
heading or fence predicate — rather than as eight literals, so the gate is closed under discovery.
This also covers the `str.strip()` half (NBSP, U+3000) recorded as MAJOR-2(W3–W5) at `6e785b4`.

### MINOR-2 — fence bullet omits the same `splitlines()` caveat
`scripts/spec-lint/check-index-integrity.py:754-758`

The heading bullet carries the `\f`/`\v` residual note; the fence bullet does not, though the same
mechanism reaches the fence predicate (recorded as W6/W7 at `6e785b4`: `` \f``` `` toggles fence
state). Mitigated — the bullet does say `fenced_code` is an unbounded sink, which is the load-bearing
warning. A one-clause cross-reference ("same `splitlines()` residual applies to this predicate") would
close it. Fold into the MINOR-1 edit.

---

## Carried forward from `6e785b4` (not re-raised, listed for the record)

Unchanged by this commit and out of scope per the review instruction. Recorded so the freshness
statement is not read as a clean bill of health on the file as a whole:

- **D-070** — the defect *class* (`prose` / `fenced_code` unbounded sinks) remains knowingly open by
  operator decision. A ruling, not a defect.
- **MAJOR-2 / W1–W8** — knowingly accepted for this PR, already recorded as mandatory named landing
  gates on the Option-3 story. MINOR-1 above extends that inventory by six spellings rather than
  reopening the question.
- **MINOR-1..4 of `6e785b4`** — four stale `count_and_classify()` references (`:71`, `:89`, `:101`,
  `:300`); bucket misstated for fenced headings (`:277`); "CommonMark-correct heading detection"
  (`:273`); property-test generator alphabet cannot reach the D-070 shapes. All still present; none
  were in this commit's stated scope.

---

## Freshness statement

This review covers **`7c1eccf5fb04a58acb52ca082563f4cb06364082`** (`7c1eccf`), the current head of
`feature/spec-lint-hardening`, verified via `gh pr view 3 --json headRefOid` at review time.

The `6e785b4` APPROVE is re-established at `7c1eccf` on the following basis:

1. The delta `6e785b4..7c1eccf` is **provably semantically empty** — identical AST, identical
   non-comment token stream (3719 tokens), zero non-comment changed lines. `7c1eccf` cannot behave
   differently from the approved head on any input.
2. The **only** finding that stood between `6e785b4` and a clean approve — MAJOR-1, the stale
   `main()` invariant comment — is **fixed**, and the fix was verified against the implementation
   (`_leading_columns` at `:38`, call sites at `:426`/`:443`) rather than against the finding text.
3. Nothing regressed: 36/36 selftests, live repo exit 0, property test 300/300, and all four
   previously-closed bypasses (`\t## X`, 6-column indented fence, `#2 below`, `### Wave 2`) still
   exit 1.
4. `git status` clean; no modification under `.factory/specs/` or `.factory/holdout-scenarios/`
   (D-058); all non-advisory CI green.

The two MINOR findings are documentation-completeness items inside the knowingly-deferred D-070
class. Neither is a regression, neither gates anything today, and neither justifies withholding
approval of a semantically empty comment correction. MINOR-1's six additional spellings should be
folded into the Option-3 landing gate as a closed-under-discovery family assertion.

**Verdict at `7c1eccf`: APPROVE.** Merge authority remains with the orchestrator.

*Note: posted via `gh pr comment` rather than `gh pr review` — per BI-039, `gh pr review` fails with
GraphQL `Can not request changes on your own pull request` for agent PRs authored under the operator's
own account (root cause D-021). The formal-review path is unsatisfiable in this repo configuration.*
