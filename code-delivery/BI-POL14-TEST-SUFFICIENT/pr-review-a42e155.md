# PR #9 Review — head `a42e155` (review cycle 3)

**Reviewer:** pr-reviewer (fresh context, independent re-derivation per operator ruling D-096)
**PR:** #9 `feature/pol14-test-sufficient` → `develop`
**Head reviewed:** `a42e15534dc5b2cccb4dfe1276bdad1d2c4ab493`
**Prior verdicts:** `87cefbf` CHANGES-NEEDED, `55113c4` CHANGES-NEEDED — both **void for this head**, read for context only, not carried over.
**Merge authority:** none. Verdict and evidence only.

---

## VERDICT: APPROVE

The cycle-3 remit was to kill the four survivors (`MS1`, `MX1`, `MX3`, `MB`) and to prove
the S1 heading-reset fix has discriminating coverage. **That remit is met.** I re-derived
every claim by executed predicate against `a42e155`; all six mutations die, and the kills
are proven independent of the suite-wide structural guard.

Severity profile (ranges per PG-012):

| Band | Count | Note |
|------|-------|------|
| BLOCKING | **0** | no live correctness defect found |
| WARNING | **2–4** | stale PR body; S3 sentinel/Proof-Method asymmetry; S2 exemption scope |
| NIT | **4–6** | S4, S5, N1, N2, plus two newly-derived heading-reset gaps (G1/G2) |

Nothing in the residual set is a live policy bypass. Every fail-open item I found requires
markdown that does not exist anywhere in the current corpus (measured, not assumed), and
the sentinel has **zero** live usages today. The PR is strictly net-additive against
`develop`: 68 tests vs 55, primitives byte-identical, no test removed or loosened.

---

## Ruling on the Central Question

**Q1 — Was the implementing agent's reasoning correct that cycle-2's prescription was "wrong in kind"?**
**Yes, on both counts. Verified by execution.**

*On `MX3`:* the agent claimed `P14-10` cannot discriminate `MX3` because under
`line.startswith("#")`, the line `### Details` computes `line[3:].strip() == "Details"`,
not `"Story Anchor"`, so the bullet is still flagged and `P14-10` passes. **Confirmed.**
Under `MX3` the suite failed **1/68 — `P14-13` only**. `P14-10` passed. Cycle-2's
prescription ("that single test kills `MS1` and `MX3`") was factually wrong. `MX3` is
distinguishable only when an H3+ heading whose text-after-3-chars equals `"Story Anchor"`
appears in a non-Story-Anchor context — exactly the fixture `P14-13` constructs.

*On `MX1`:* the agent claimed `MX1` produces **false positives**, not false negatives, so
no defect-fail test can kill it; it is killed via `P14-12`'s **clean-pass** failure.
**Confirmed.** Under `MX1`, `P14-12`'s clean tree exits 1 and the test emits
`STRUCTURAL FAIL: checker falsely rejected ... (MX1 regression)`.

**Q2 — Do any of the four new tests depend on the suite-wide structural clean-pass guard
in a way that would let its mutant survive if that guard were weakened?**
**No. Proven by executed composite experiment.**

This mattered because `MX1` and `M4` both surface as **exit 2** — the
`TESTS_WITH_CLEAN_PASS -ne TESTS_RUN` guard is ordered *before* the `FAILURES` check, so it
reports first and masks which mechanism actually fired. I disambiguated by neutralising the
suite-wide guard (`if [ "$TESTS_WITH_CLEAN_PASS" -ne "$TESTS_RUN" ]` → `if false`) and
re-running:

| Configuration | Exit | Result |
|---|---|---|
| guard neutralised, **no** code mutation | **0** | 68/68 — the guard edit alone is inert |
| `MX1` + guard neutralised | **1** | `Selftest FAILED: 1/68` — `P14-12` |
| `M4` + guard neutralised | **1** | `Selftest FAILED: 5/68` |

Because the no-mutation control still exits 0, the exit 1 in both mutant rows is
attributable **solely to the mutation**. Each test's clean-pass check is a *test-local*
assertion that increments `FAILURES` itself, not merely a contribution to the suite tally.
The suite-wide guard is a redundant second backstop, **not** the load-bearing mechanism.
These are runtime positive-coverage assertions — the durable criterion named by
D-040 / D-050 / D-057, not a mutation-detection artefact.

**Q3 — Are `P14-10`..`P14-13` genuinely discriminating, or do they merely happen to pass?**
**Genuinely discriminating.** Each is uniquely load-bearing for at least one mutant:

| Test | Uniquely kills | Discriminating assertion |
|------|----------------|--------------------------|
| `P14-10` | `MS1` | defect-fail (bullet after `### Details` must be flagged) |
| `P14-11` | `MB` | defect-fail (prose line under `## Story Anchor` must be flagged) |
| `P14-12` | `MX1` | **clean-pass** (`#nospace` must not reset context) |
| `P14-13` | `MX3` | defect-fail (`### Story Anchor` must not open a zone) |

Remove any one and its mutant survives. All four carry both a clean-pass and a defect-fail
assertion; the suite's own `TESTS_WITH_CLEAN_PASS == TESTS_RUN == 68` invariant holds.

One observation, non-blocking: `P14-12`'s *defect* fixture is shape-identical to `P14-10`'s
(`## Story Anchor` / `### Details` / bullet), so its defect assertion is redundant rather
than uniquely discriminating. That is not vacuity — `P14-12`'s discriminating power lives in
its clean-pass, and the redundant defect assertion still fired under `MS1`. Bracketing
behaviour from both sides in every test is sound design, not padding.

---

## Six-Mutant Table — my own (a)/(b)/(c) evidence

Harness discipline: every mutation applied **inside the worktree** via a Python helper that
**aborts (exit 9) unless the occurrence count matches exactly**, so a zero-match silent
no-op is structurally impossible. I proved this first with a negative control
(`THIS_STRING_DOES_NOT_EXIST_ANYWHERE` → `HARNESS-ABORT: expected 1 occurrence(s), found 0`,
tree untouched). Every run printed the `git diff` before executing, and the tree was
restored with `git checkout --` and re-verified clean after each.

**Control:** exit **0**, `Selftest passed: 68/68`, `grep -c 'selftest P14-'` = **13**.

| Mutation | (a) diff proves mutation present | (b) exit / failures | (c) P14 reached | Result |
|---|---|---|---|---|
| `MS1` — delete `else: current_h2_heading = None` | `-else:` / `-current_h2_heading = None` | **1** — 2/68 (`P14-10`, `P14-12`) | 13 | **DIES** |
| `MX1` — `if _atx_rest.startswith(" ") or not _atx_rest:` → `if True:` | `-if _atx_rest...` `+if True:` | **2** via guard; **1** — 1/68 (`P14-12`) guard-neutralised | 13 | **DIES** |
| `MX3` — `line.startswith("## ")` → `line.startswith("#")` | `-...("## "):` `+...("#"):` | **1** — 1/68 (`P14-13`) | 13 | **DIES** |
| `MB` — drop `and line.lstrip().startswith("- ")` | `-and line.lstrip().startswith("- ")` | **1** — 1/68 (`P14-11`) | 13 | **DIES** |
| `M4` — delete Shape 2 branch entirely | 6 lines removed | **2** via guard; **1** — 5/68 guard-neutralised | 13 | **DIES** |
| `M8` — drop `current_h2_heading == "Story Anchor"` | `-current_h2_heading ==...` `+line.lstrip()...` | **1** — 5/68 | 13 | **DIES** |

All six agree with the orchestrator's independent verification, including the exact
failure counts for `MS1` (2/68) and `MX3` (1/68). **Tree restored clean and confirmed:**
`git status --porcelain` empty, `git rev-parse HEAD` = `a42e155`, `git diff a42e155 --stat`
empty, and a post-restore control re-run returned `68/68`.

---

## Independent Confirmations

**JOIN fails closed — genuine, not an allowlist in disguise.** Built three isolated trees:

| VP-INDEX state | Result |
|---|---|
| VP-INDEX **absent** | **REJECTED** — `'BC-2.10.004' has no row in VP-INDEX; assign a real VP or add a 'test-sufficient' row` |
| VP-INDEX says `test-sufficient` | **ACCEPTED** |
| VP-INDEX says `VP-007` (reclassified) | **REJECTED** — `VP-INDEX classifies 'BC-2.10.004' as 'VP-007'; remove the sentinel and cite the real VP` |

Reclassification flips acceptance immediately with no allowlist entry to update. Confirmed
genuine runtime JOIN.

**D-039 — no allowlist introduced.** Grep for
`ALLOWLIST|WHITELIST|_DEFERRAL|SKIP_LIST|SKIP_SET|KNOWN_COLLISIONS|KNOWN_VIOLATIONS|KNOWN_ISSUES|SUPPRESS_SET`
over added lines: **no match**. The suite's own pre-flight guard reports
`Pre-flight guard passed: 15 checkers/generators scanned, 0 suppression constructs found`.

**No pre-existing test removed or loosened.** The complete deletion set in
`git diff origin/develop -- run-selftests.sh` is **one line**: `-EXPECTED_TEST_COUNT=55`.
No assertion weakened.

**`spec_lint_primitives.py` byte-identical to develop** — SHA-256 match on both sides
(`1a4489032c7ba3…`).

**Real corpus:** exit 1, **53** findings, all `non-conforming VP-NNN column value '—'`,
**0** `[filled by]` findings, 133 files. Matches CI's `Spec lint` log byte-for-byte.

**CI:** all 4 required contexts (`Format check`, `Clippy (deny warnings)`,
`Test (macos-latest)`, `Build release (macos-latest)`) **PASS**. `Spec lint` FAILS but is
**not** a required context, and its failure is exactly the 53 known em-dash rows —
advisory per D-029/D-032, no new cause.

---

## Findings

### W1 — WARNING (description accuracy): PR body is stale across all three heads

The PR body still describes head `87cefbf`. It is materially wrong as a merge-time audit
record:

| Body claims | Actual at `a42e155` |
|---|---|
| 55 findings, baseline "80 → 55" | **53** findings |
| "Selftest suite = 62/62 (EXPECTED_TEST_COUNT 55 → 62)" | **68/68**, count 55 → **68** |
| Mutation table lists `M1`/`M2`/`M3` only | `MS1`,`MX1`,`MX3`,`MB`,`M4`,`M8` all verified — none mentioned |
| "7 new tests P14-1..P14-7" | **13** P14 tests |

The body also omits the S1 heading-reset fix entirely — the substantive code change of the
last two heads. Recommend the body be corrected before merge; it is the artefact a future
auditor reads. Not code, so not blocking.

### W2 — WARNING (S3): `test-sufficient` accepts an empty Proof Method; `VP-NONE` does not

Confirmed by execution, side by side in identical trees:

- `| test-sufficient | thing works |  |` + VP-INDEX agreeing → **Check passed**
- `| VP-NONE | thing works |  |` → **REJECTED** `non-conforming VP-NNN column value 'VP-NONE'`

D-078 established that a sentinel is admissible only with a non-empty Proof Method. The new
sentinel does not inherit that constraint, so a row may assert *"tests are sufficient"*
while naming no test at all — a content-free assertion, which is what POL-14 exists to
prevent. Fails **open**.

Not blocking: there are **0** `test-sufficient` sentinels in the corpus today, so no live
false negative exists, and the authorizing rulings are silent on Proof Method. But this
becomes live the moment the 33 BCs migrate off `—`. **Highest-priority follow-up** — the fix
is one line (mirror the `VP-NONE` guard) plus one selftest, and it should land before the
spec migration, not after.

### W3 — WARNING (S2): Shape 1 is exempt anywhere in a file, including inside fenced code blocks

D-093 authorises the exemption "inside a Traceability row". Verified actual scope is wider:

- `| Stories | [filled by story-writer] |` inside a ```` ```markdown ```` fence → **Check passed**
- the same row under `## Random Section` in a non-Traceability `| Field | Value |` table → **Check passed**
- control: `| Architecture Module | [filled by architect] |` → correctly **flagged**

So the anchor is the field-name cell alone, with no section or fence scoping. Fails **open**,
but narrowly: it requires a table row whose first cell is exactly `Stories`. Broader than
D-093's literal wording. **DEFER with tracked issue.**

### N1 — NIT (S4): VP(s) column read positionally as `cells[2]`

Only the header's first cell is validated (`== "BC"`). With columns reordered to
`| BC | VP(s) | Title |`, the checker read `cells[2]` = `"thing"` and **rejected** the
sentinel: `VP-INDEX classifies 'BC-2.10.004' as 'thing'`. Fragile, but fails **CLOSED**
(over-strict, not permissive) — the safe direction. **ACCEPT.**

### N2 — NIT (N1 in dispatch): duplicate VP-INDEX BC rows silently last-win

Verified: VP-INDEX with `| BC-2.10.004 | thing | VP-007 |` followed by
`| BC-2.10.004 | thing | test-sufficient |` → **Check passed**. The lax row wins because
`classifications[bc] = cells[2]` overwrites unconditionally. Fails **open**, but requires a
malformed VP-INDEX. **DEFER with tracked issue** (prefer: detect duplicates and fail, or
take the strictest row).

### N3 — NIT (N2 in dispatch): message misleads when VP-INDEX is absent entirely

With no VP-INDEX file at all, the message is `'BC-2.10.004' has no row in VP-INDEX`, which
implies the file exists but lacks a row. Behaviour is correct and fail-closed; only the
wording is off. **ACCEPT** (cosmetic).

### N4 — NIT (S5): no demo evidence for this story

`git diff origin/develop...HEAD -- docs/` is empty. PR #8 established the convention at
`docs/demo-evidence/BI-040/` (an `evidence-report.md` plus per-AC `.txt` captures — the
appropriate form for a CLI/lint tool with no UI; the gif/webm expectation does not apply
here). PR #9 adds nothing. All the evidence exists in runnable form (68/68 suite, the
53-finding corpus run) and simply was not captured. **DEFER with tracked issue** — cheap to
add, and it is the artefact that makes this review reproducible.

### N5 — NIT (newly derived): heading-reset misses indented ATX and setext H2 headings

The code comment asserts the context is *"cleared by ANY other ATX heading (H1, H3, …)"*.
That overclaims. `line.startswith("#")` anchors at column 0, and setext headings are not
tracked at all. Both verified:

| Fixture inside `## Story Anchor` | Correct | Actual |
|---|---|---|
| `   ### Details` (1–3 space indent — a valid CommonMark ATX heading) | flagged | **Check passed** — reset missed |
| `Details` + `-------` (setext H2) | flagged | **Check passed** — reset missed |
| `### Details` (control, unindented) | flagged | **flagged** ✓ |

Same *class* as `MS1` — an unauthorised exemption zone persisting past a heading — at a much
narrower aperture, and untested.

I measured live exposure before sizing this, rather than assuming: **0** indented ATX
headings across the entire spec tree; the 67 `^-{3,}$` lines that pattern-match setext
underlines are all YAML frontmatter closers at line ~30 (preceded by `removal_reason: null`),
far above any `## Story Anchor`; and the corpus contains exactly **1** `## Story Anchor`
(`BC-2.10.009:110`) with exactly **1** `- [filled by` bullet (`:111`) immediately beneath it.
**Zero live exposure.** **DEFER with tracked issue**, and correct the comment's
"ANY other ATX heading" claim, which is currently false.

### Also noted

**Diff size** 908 insertions exceeds the 500-line flag threshold, but 664 of those lines are
`run-selftests.sh` tests and 2 files are fixtures — 231 lines of checker change. Proportionate
for a change whose whole burden is test sufficiency. **ACCEPT.**

**Sentinel has no live usage.** The 53 em-dash rows this feature exists to serve still say
`—`; the spec migration is a separate change under separate ownership (D-041). So the
sentinel's entire positive coverage today is from selftests `P14-1`/`P14-2`/`P14-3`. That is
expected, and it is why W2 (S3) should be fixed before the migration rather than after.

---

## Disposition Summary

| Item | Verified behaviour | Direction | Disposition |
|---|---|---|---|
| **S2** Shape 1 unscoped (fences, any section) | confirmed | fails open (narrow) | **DEFER-with-tracked-issue** |
| **S3** `test-sufficient` accepts empty Proof Method | confirmed | fails open | **DEFER-with-tracked-issue** — highest priority; fix before spec migration |
| **S4** positional `cells[2]` | confirmed | fails **closed** | **ACCEPT** |
| **S5** no demo evidence | confirmed | process | **DEFER-with-tracked-issue** |
| **N1** duplicate rows last-win | confirmed | fails open | **DEFER-with-tracked-issue** |
| **N2** misleading absent-VP-INDEX message | confirmed | fails closed | **ACCEPT** |
| **G1/G2** indented-ATX & setext reset gaps (new) | confirmed, 0 live exposure | fails open | **DEFER-with-tracked-issue** |
| **PR body stale** | confirmed | audit record | **fix before merge** (non-code) |

---

## S1 Correctness and Bounding vs D-093

Correct for every shape that exists in the corpus, and **bounded**: the exemption zone runs
from a column-0 `## Story Anchor` to the next column-0 ATX heading of any level, and applies
only to lines whose lstripped form starts with `- `. Directionally the implementation is
mostly *narrower* than D-093 (indented headings never open a zone; headings inside fences are
ignored; `####### x` resets even though it is not a valid heading — all fail-closed). The two
residual over-breadths are N5's untracked heading forms and S2's unscoped Shape 1. Net: no
longer broader in any way that is reachable by the current corpus.

---

## Contradictions with the Dispatch

None material. Every quantitative claim in the dispatch that I re-tested reproduced exactly
(68/68 control, P14 header count 13, `MS1` exit 1 at 2/68, `MX3` exit 1 at 1/68, 53 corpus
findings, primitives byte-identical, 4 required checks green, `Spec lint` advisory).

Two clarifications rather than contradictions:

1. `MX1` and `M4` surface as **exit 2**, not exit 1, when the suite-wide guard is intact —
   the guard is ordered ahead of the `FAILURES` check and reports first. The dispatch's
   framing of these as clean-pass kills is right; the raw exit code alone would have
   mis-attributed the mechanism. This is exactly the "a bare exit code is NOT evidence"
   trap the dispatch warned about, and it is why I ran the guard-neutralised composite.
2. The dispatch listed S3's consequence as a row that "can name no test at all." Confirmed
   literally — not merely theoretically.

**The `validate-pr-review-posted` hook did not fire during this review.** Had it fired, I
would have noted it and proceeded without fabricating a verdict.

---

## Basis for APPROVE

1. Cycle-3 remit met: all four prior survivors die, verified independently with
   presence-proof, control, and P14-reached evidence for each.
2. Kills are guard-independent — proven by executed composite experiment, not asserted.
3. All four new tests are non-vacuous and each is uniquely load-bearing for one mutant.
4. No test removed or loosened; no allowlist introduced; suppression pre-flight passes;
   primitives byte-identical; JOIN genuinely fails closed under both absence and
   reclassification.
5. All required CI contexts green; the one red check is a known advisory with an unchanged cause.
6. Zero live exposure for every residual fail-open item, each measured rather than assumed.

`gh pr review --request-changes` / `--approve` is not available on this self-authored PR
(GitHub forbids self-approval), so this review is posted as a comment. No verdict GitHub
refused to record has been fabricated, and no `covered_sha` field was touched.
The merge decision is reserved to the human operator.
