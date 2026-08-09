# PR Review — Cycle 5

**VERDICT: REQUEST_CHANGES** (2 blocking findings, both documentation-only)

**Reviewed head:** `39efec2607dd954cf2ef7cfe4ec390b33973d912` (`39efec2`)
**Base:** `develop` @ `da86271`
**Branch:** `fix/checker-completeness-gate35`
**Scope of this cycle:** re-verification of BLOCKING-A; confirmation the four prior RESOLVED
adjudications survive; regression check on the fix pass itself.
**Reviewed:** 2026-08-09

> Posted via `gh pr comment`, not `gh pr review`. `--approve` / `--request-changes` are structurally
> impossible on a self-authored PR here (BI-039 / D-021 / D-105). The `VERDICT:` line above is the
> review verdict for gating purposes.

## Headline

**BLOCKING-A is RESOLVED.** All eight defects I enumerated are fixed, and I verified each one
individually rather than accepting the summary. The evidence-provenance argument is sound and I
confirmed it independently.

**But the fix pass introduced a new accuracy defect of the same class, and I found one I missed in
cycle 4.** Both are documentation-only. No source change is required, and nothing about the code
verdict changed.

This is now the third consecutive iteration in which correcting a record defect produced another
one. That pattern is itself worth naming — see the closing note.

---

## 1. Source identity — verified, not assumed

The claim "zero files changed under `scripts/`" understates what I could confirm. I verified
identity three ways:

- `scripts/` **tree hash identical** at both commits: `161b0c623ba255ca2acc85111cab6ab68aba511c`.
- sha256 of each of the three files under test identical across `72db558` → `39efec2`
  (`check-adr-consistency.py` `c6039bacb0183f0e`, `check-ec-injectivity.py` `1918af2dd2bf3bfa`,
  `run-selftests.sh` `762332ab26dbcf5c`).
- Whole-tree `--name-status` shows exactly two paths, both under
  `docs/demo-evidence/CHECKER-COMPLETENESS-GATE35/`: `R098` rename of AC-002 and `M` on
  `evidence-report.md`.

So the evidence-provenance argument in the PR body — that a run captured at `72db558` remains valid
at `39efec2` because the source is byte-identical — is **correct, and now independently
established.** It does not paper over a mismatch.

## 2. The four prior RESOLVED adjudications — all still hold

Mechanically implied by source identity, but re-executed anyway at `39efec2`:

| Check | Result at `39efec2` |
|---|---|
| Full selftest suite | **99/99** |
| Unmutated population gate | `population=8, examined=6, skipped=2 (frontmatter, D-081)` |
| Tautology mutant (re-injected out-of-tree) | `ERROR: E-class accounting gap — population=8 != examined=3 + skipped=2`, **exit 2** |
| `check-ec-injectivity` live | 174 compared, **42** divergent, **22** adjudication |

C1-BLOCKING-1, C1-BLOCKING-2, C2-BLOCKING-1, C2-BLOCKING-2 and both NITs remain **RESOLVED**. Not
re-litigated.

## 3. BLOCKING-A re-verification — RESOLVED, defect by defect

| Original defect | State at `39efec2` | Verified how |
|---|---|---|
| `Head SHA: d3085d9` | `39efec2607dd...` | body line 6 |
| badge + AC-2 said `93/93` | `99/99` | body lines 176, 220, 357, 360, 376; `93/93`/`98/98`/`98of98` all zero occurrences |
| cited nonexistent `AC-002-selftest-93of93.txt` | cites `AC-002-selftest-99of99.txt`, **which exists** | filesystem check of every `AC-00*.txt` the body cites — all 4 resolve |
| `79 reason-code + 5 E-class` | `78 reason-code + 6 E-class` | matches fresh head run exactly |
| `40 DIVERGENT + 11 ADJUDICATION` | `42 DIVERGENT + 22 ADJUDICATION` | matches fresh head run exactly |
| `2` new selftests | `8` (5k, 5l, 5m, 5n, 5o, 5o-b, 5p, EI-7) | enumerated against the suite |
| `5` new E-class detections | `6` | matches fresh head run |
| rollback omitted 4 **source** commits | all 8 source+evidence commits listed newest-first | see NIT-C for the one residual |

Also confirmed: AC-002 is a **genuine recapture**, not a relabel — the diff adds the
`selftest 5o-b (NIT-1)` PASS line and changes the trailer to `99/99`. `- [ ] Operator merge
authorization — pending` is still **unticked and unmodified** (body line 384). The PR branch touches
**zero paths under `.factory/`**, so it structurally cannot have moved the frozen perimeter.

CI at exactly `39efec2`, via the check-runs API — all four required checks **SUCCESS**:
`Build release (macos-latest)`, `Clippy (deny warnings)`, `Format check`, `Test (macos-latest)`;
plus `GitGuardian` SUCCESS. `Spec lint` FAILURE, correct and intended per D-128 / D-122.

---

## BLOCKING-B (new — introduced by this fix pass) — the body misdescribes the detection set and the population arithmetic

**Severity:** blocking · **Category:** description accuracy · **Location:** PR body lines 74-77

The body reads:

> (78 reason-code + 6 E-class occurrences validated). Detection confirmed at:
> `BC-2.01.009.md:44,52,71,73` and `interface-definitions.md:237`. The sixth occurrence
> (`BC-2.01.009.md:23`) is inside YAML frontmatter and correctly excluded by the position-based
> D-081 predicate.

Three things are wrong, and they compound:

1. **The list has five entries for a claimed six.** `BC-2.11.004.md:61` (`E-CLI-001`) — a real,
   currently-reported detection — is missing entirely.
2. **`BC-2.01.009.md:23` is not the sixth occurrence.** It is one of the **two** frontmatter-skipped
   occurrences (that single line carries two E-codes, which is the whole `skipped=2`).
3. **It is self-contradictory.** An occurrence cannot be among the "6 validated" *and* "correctly
   excluded". Validated and excluded are the two disjoint buckets the gate reconciles.

Ground truth from a fresh run at `39efec2`:

```
BC-2.01.009.md:44   E-IO-002     ┐
BC-2.01.009.md:52   E-IO-002     │
BC-2.01.009.md:71   E-IO-002     ├─ examined = 6
BC-2.01.009.md:73   E-IO-002     │
BC-2.11.004.md:61   E-CLI-001    │   ← omitted from the body's list
interface-definitions.md:237  E-IO-002 ┘
BC-2.01.009.md:23   (two codes, frontmatter) ─ skipped = 2
population = 8 = examined 6 + skipped 2
```

This matters more than a stale SHA. The population reconciliation is the headline deliverable of the
cycle-2 fix, and this paragraph teaches a reader the wrong arithmetic for it — it conflates
`population` (8) with `examined` (6) and mislabels a skipped occurrence as a validated one. It looks
like the count was updated 5→6 without correspondingly updating the site list, and a wrong
explanation of "the sixth" was bolted on to reconcile the mismatch.

**Fix:** add `BC-2.11.004.md:61` to the list, and rewrite the last sentence to say that
`BC-2.01.009.md:23` carries **two** further occurrences inside YAML frontmatter which are excluded by
D-081 and disclosed as `skipped=2`, bringing the corpus population to 8.

## BLOCKING-C (pre-existing — I missed this in cycle 4) — three evidence artifacts carry a provably false capture-provenance stamp

**Severity:** blocking · **Category:** evidence integrity · **Location:**
`AC-001-preflight.txt`, `AC-005-adr-consistency-live.txt`, `AC-006-ec-injectivity-live.txt`

All three end with `Captured at: fd74bd73aa640f17102139345bb8b2aed29d3f58`. That stamp is false, and
falsifiable by execution. I ran the `fd74bd7` checker against the live corpus:

| | reason-code occurrences reported |
|---|---|
| `fd74bd7` checker (actual run) | **79** |
| `AC-005` artifact content | **78** |

`78` is only reachable **after** `b4bbbc3`, because it is `79` minus the ADR reason-code
double-count that `b4bbbc3`'s `e_class_only` change removed. So these artifacts were captured at
`b4bbbc3` or later and are stamped with a commit at which their own contents were unobtainable.

`evidence-report.md:65` says "all AC files recaptured at b4bbbc3", which contradicts the stamps.
Line 65 is the accurate one; the stamps are the defect.

Why this is blocking rather than cosmetic: the stamp is the only machine-readable provenance on the
artifact, and it points to the wrong side of the exact fix that changed the numbers. Anyone auditing
"was this evidence captured before or after the double-count was fixed?" gets the wrong answer from
the artifact itself. I own that I should have caught this in cycle 4 — I verified artifact *contents*
against head and did not check the *stamps*.

**Fix:** restamp all three to the commit they were actually captured at, or drop the stamps and rely
on `evidence-report.md`. Related: AC-002 lost its stamp entirely in this recapture and AC-007 never
had one, so the bundle is now inconsistent about whether artifacts carry provenance at all — pick
one convention.

---

## Suggestions and nits

- **SUGGESTION-2** (body line 332) — traceability row attributes `E-CLI-001 ×1` to `test-vectors`. It
  is in `BC-2.11.004.md:61`. `evidence-report.md` gets this right, so the two records disagree.
- **SUGGESTION-3** (`evidence-report.md:42`) — the section heading still reads
  `## Selftest Run (98/98 confirmed)`. The fix pass updated the four `98/98` occurrences at lines 12,
  13, 23 and 44 but missed the heading, so the file now contradicts itself on its own headline figure.
- **SUGGESTION-4** (`evidence-report.md:65`) — "AC-002 renamed to 98of98" is now false; the file is
  `AC-002-selftest-99of99.txt`.
- **NIT-C** (body line 319) — the rollback lists 8 commits but the branch now has **9**; head
  `39efec2` is omitted. Materially this is fine — all *source* commits are covered, and the omitted
  one is an evidence rename — so reverting the 8 does undo every code change. But the accompanying
  claim of "all branch commits" is off by one, and the revert would leave orphaned evidence
  artifacts. Add `39efec2` to the front.
- **NIT-D** — `evidence-report.md:4` is labelled `**Head SHA:** 72db558` while head is `39efec2`.
  Defensible as capture provenance, but the field name says otherwise; consider
  `**Captured at SHA:**`.

Cycle-4 **NIT-A** (count assertions matching any count ending in 1) and **NIT-B** (EI-5's
mutation-verify comment naming a kill mechanism that does not exist) are unaddressed and unchanged —
both still open, both still non-blocking.

---

## On the recursion

The coordinator is right that recapturing evidence advances the head and re-stales the body, and
right to have broken that loop with body-only edits. But the loop recurred here for a different
reason: each pass has corrected the figures it was told about and introduced or left one it was not.
Cycle 4 flagged eight body figures; this pass fixed all eight and produced BLOCKING-B while leaving
two stale strings in `evidence-report.md`.

The structural fix is to stop hand-editing these figures. Every number I checked in this review is
mechanically derivable: run the three commands, diff their output against the body and
`evidence-report.md`, fail on mismatch. A ~20-line CI job asserting that the PR body's quoted
figures match live checker output would have caught BLOCKING-B, SUGGESTION-2, SUGGESTION-3,
SUGGESTION-4 and NIT-C in one pass, and would have caught the false stamps in BLOCKING-C too. Worth
considering before the nine-checker ledger sweep, which will generate far more of these figures than
this PR did.

## Bottom line

The code remains sound and unchanged — `99/99`, the mutation proof reproduces, all four required CI
checks green, the frozen perimeter untouched, the authorization field unticked. **BLOCKING-A is
resolved and I could not fault the provenance argument.**

What blocks is narrower than last cycle but the same class: the body now misstates which files carry
the six E-class detections and mislabels a frontmatter-skipped occurrence as a validated one
(BLOCKING-B), and three evidence artifacts assert a capture provenance that is verifiably false
(BLOCKING-C). Both are documentation-only and quick. No source change required.
