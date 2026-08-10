**VERDICT: REQUEST_CHANGES**

# PR #13 — Cycle-5 narrow re-review (gate-#28 v3 flow)

```
covered_sha: f4c036e21fceb71fd261496aaa9a5571e8ddbb6d
cycle:       5
prior_head:  280bcd3 (cycle-4 reviewed)
fix_range:   280bcd3..f4c036e  (6 commits, 8 files, +144/-37)
reviewer:    READ-ONLY (no tracked file modified; scratch clone + probes under /tmp only)
scope:       NARROW per operator ruling — items 1-5 only; no new enumeration;
             cycle-4's 14 documented-accepted findings carried by reference, not re-litigated
```

**One-line verdict rationale.** M4-1 and M4-2 are **genuinely CLOSED** — verified by
direct execution, including neutralization tests proving both pins are load-bearing and a
7,030-shape proof that the pinned perimeter is complete. Of the two NEW guarantee claims
the fix ships, `:920` is **accurate** and `:583` is **overbroad**: I reproduced, on the
real `pr-description.md`, an `rc=0` in which a figure differing from live output is hidden
inside the stripped span. Under the operator's own bar ("a shipped claim that is untrue" =
MUST-FIX) that is one MUST-FIX. The remedy is a **single comment sentence**. Everything
else this cycle is accept-and-record.

---

## Guard 1 — ADJUDICATION LEDGER

### Section A — COUNTED MUST-FIX (PG-012: exact integers)

| Severity | Count |
|----------|-------|
| critical | 0 |
| must-fix (high) | 0 |
| must-fix (mid) | 1 |
| **TOTAL COUNTED MUST-FIX** | **1** |

| ID | Severity | Category | Finding | Evidence |
|----|----------|----------|---------|----------|
| **M5-1** | must-fix (mid) | false claim / D-180 lineage (7th) | **`scripts/verify-evidence-figures.py:583` — "This makes the wrong-value-hidden attack direction unrepresentable" is OVERBROAD.** The delivered guarantee is *content-membership in a 3-element whitelist*, not *no wrong value can hide*. Executed counter-example on the REAL `pr-description.md`: adding one `Previous (post-gate34)`-headed table whose stripped cell is byte-exact a whitelist member hides `9 divergent` (live: `42`) from every downstream scan, `rc=0`, zero labels fired. | probes R1, R6 (§1.6) |

**Exact remedy (one sentence, no code change).** Replace line 583 with the bound that is
actually delivered — the wording already used correctly 337 lines later at `:920`:

```
# This restricts the stripped span to the historical whitelist: arbitrary
# attacker-chosen content is unrepresentable.  It does NOT prevent a whitelist
# member from being re-presented in a misleading position (see R1/R6), and the
# pins bound content only — not the cardinality or position of stripped spans.
```

**Note on re-classification.** If the operator elects to accept M5-1 rather than fix it,
that is a legitimate D-214 call (the mechanism is near-harmless; only the *claim* is
loose). Per Guard 1 the re-classification **is itself a recorded event** and must be
entered in Section B with reason + adjudicator; the verdict then becomes APPROVE with
MUST-FIX = 0. I am not making that call for you — my independent judgment, given this
file's six prior false structural-guarantee claims and the operator's explicit
instruction that an overbroad bound "is a false-claim finding," is REQUEST_CHANGES.

### Section B — DOCUMENTED-ACCEPTED — **EXPLICITLY NOT COUNTED**

New this cycle (4):

| ID | Severity | Finding | Reason accepted | Adjudicator |
|----|----------|---------|-----------------|-------------|
| A5-1 | suggestion | **ev pin is set-MEMBERSHIP, not multiset/position equality.** `prev_lines` count guard (`==2`) + `_pl in _EV_PREV_HISTORICAL` are both satisfied by **two copies of the same** whitelist member. Probe R6: replacing the EI baseline line with a duplicate of the ADR baseline line → `rc=0`. One baseline declaration is silently deleted. | No wrong figure is asserted — content is *deleted*, not falsified; per-line claim at `pr-description.md:206` ("must equal the expected historical text exactly") remains TRUE. Known class (cycle-3 M-2 "validated by counting"). Cheap future fix: `set(prev_lines) == _EV_PREV_HISTORICAL`. D-214, no cycle-6. | pr-reviewer (cycle-5) |
| A5-2 | suggestion | **Pins bound CONTENT but not CARDINALITY or POSITION** of stripped spans. Only `rows == 0` fails; extra whitelisted stripped cells are unbounded (real doc: `rows: 3`; R1 shape: `rows: 4`, still `rc=0`). | Hideable content is restricted to the 3 historical strings, so no *attacker-chosen* figure can hide; the residual re-presents a correct-historical string in a misleading position. Same class as A5-1. D-214. | pr-reviewer (cycle-5) |
| A5-3 | nit | **`_strip_prev_col` docstring now carries TWO conflicting `Returns` paragraphs.** `:300` still says "Returns (filtered_text, stats)" (2-tuple); `:312`, added by this fix, says "(filtered_text, stats, stripped_cells)". The first is stale. | Documentation inaccuracy about a signature, not a guarantee claim; the correct form is present immediately below it. D-214 — no cycle-6 for polish. | pr-reviewer (cycle-5) |
| A5-4 | nit | **`scripts/spec-lint/selftest/run-selftests.sh:9` — "cannot satisfy (b) unless the injected defect is actually detected" is imprecise on ATTRIBUTION.** The defect-fail direction pins only `exit != 0`; a crash would also satisfy it (representative case inspected at `:4855-4892` — clean side greps a label, defect side checks exit code only). | The claim's subject is **vacuity**, and vacuity *is* structurally impossible (a test cannot pass without the injection changing behaviour). Mis-attribution is a distinct class, already adjudicated for `test-vef.py` in cycle-3 M-3, and the coverage bound is disclosed on `:12-13`. Claim judged ACCURATE as worded. | pr-reviewer (cycle-5) |

Carried forward by reference (14) — **visible, not re-litigated, not counted**:
all 14 documented-accepted findings recorded in
`.factory/code-delivery/VERIFIER-HARDENING-SWEEP-STEP0/pr-review-cycle4.md`
(read this cycle for finding definitions only; file NOT modified).

**Running total of accepted-and-visible findings: 14 (cycle-4) + 4 (cycle-5) = 18.**

---

## Guard 2 — NEW-CLASS ASSERTION

**The list of findings mapping to no known class is EMPTY.**

| Finding | Maps to known class | New? |
|---------|--------------------|------|
| M5-1 | D-180 false-structural-guarantee lineage (cycle-3 M-4 / cycle-4 M4-2) — 7th appearance | No |
| A5-1 | cycle-3 M-2 "filters validated by counting, not content" | No |
| A5-2 | cycle-3 M-2 (same class as A5-1) | No |
| A5-3 | comment/doc-accuracy class (cycle-3 M-4 lineage) | No |
| A5-4 | cycle-3 M-3 "label assertions" | No |

`new_classes: 0`

---

## §1 — ITEM 1: M4-1 CLOSURE — **CLOSED (both sides)**

### 1.1 The predicate I EXECUTED, and its observed output

Suite, real repo, head `f4c036e`:

```
$ python3 scripts/tests/test-vef.py            # EXIT=0
  PASS  T49 ev-prev-line-content-appended [M-2/Case-G]
  PASS  T50 pr-stripped-cell-content-modified [M-2/Case-G-pr]
PASS  52/52 tests verified (each proved clean-pass + defect-fail)
```

Rename confirmed independently (D-039): `_pr_stripped` → `_stripped_cells` is a **rename,
not a deletion**. The PR-side guard survived and was strengthened — `_strip_prev_col` now
returns `list[str]` instead of a `" ".join(...)` string, so cell boundaries are preserved
(previously they were destroyed by joining, which is precisely what made per-cell equality
impossible before).

**The negative assertion was REPLACED by something provably stronger, not removed.** The
old assertion fired iff a **live** figure appeared in removed text. I verified that **no
whitelist member contains any live EI figure token** (`174`, `42`, `22` — all absent from
all 5 members). Therefore any removed content containing a live figure is necessarily
outside the whitelist and fires the new pin. **The new pin strictly subsumes the old
assertion.** No D-039 suppression.

### 1.2 Neutralization tests — both pins are NON-TAUTOLOGICAL

Scratch clone at `f4c036e` (`/tmp/c5clone`), one pin neutralized at a time
(`if _pl not in ...:` → `if False:`), all other guards intact:

| Clone state | T49 | T50 |
|-------------|-----|-----|
| Unmodified (baseline) | **PASS** | **PASS** |
| `ev-prev-line-content` pin neutralized | **FAIL** — `expected rc!=0, got rc=0` | PASS |
| `pr-stripped-cell-content` pin neutralized | PASS | **FAIL** — `expected rc!=0, got rc=0` |

Each pin is **solely and exactly** responsible for its own defect-fail direction, and
removing it **restores the false green (`rc=0`)**. This also answers the operator's
specific question: **T50's defect direction fires from the pinned assertion, not from some
other guard** — with pin B removed and pin A plus every novel-spelling scan still present,
T50's defect exits 0.

### 1.3 Pinned-perimeter completeness — **PROVEN COMPLETE** (highest-value result)

The question: does every span the filter removes land in `prev_lines` or `_stripped_cells`?

**ev side — exact by construction.** `ev_no_prev` filters on `PREV_LABEL not in ln`;
`prev_lines` collects `PREV_LABEL in ln`. Identical predicate, complementary sets, plus a
hard cardinality guard (`len(prev_lines) != 2` → `fail("ev-baseline/prev-lines")`, probe R5
confirms it fires). Removed set ≡ pinned set.

**pr side — proven by independent differential probe** (`/tmp/c5_perimeter3.py`).
`_strip_prev_col` extracted via AST (the verifier is a script, not importable); removed
content computed by my own field-level diff of input vs output; multisets compared. No
verifier assertion code reused.

```
probe: cases                       = 7030
probe: UNDER-recorded (unsafe)      = 0
probe: over-recorded  (fail-closed) = 1287
```

Corpus: ragged rows, over-long rows, all-empty cells, degenerate `|` / `||` / `|||` rows,
separator variants, glued and multi-table docs, unicode cells, 5 header shapes, 3,000
randomized documents.

- **Under-recording = 0.** There is no span the filter removes that the pins do not see.
- **Over-recording = 1287** (a cell already `' '` is recorded but removes nothing). This is
  the **fail-closed** direction: `' '` is *not* in `_PR_CELL_HISTORICAL`, so over-recording
  makes the pin *stricter*, never looser.

**Conclusion: the pinned perimeter equals the filtered perimeter. No hiding place survives
outside the whitelist.**

### 1.4 The RAGGED-ROW case (the originating concern) — **CAUGHT**

Direct execution, first-column drop shifting `col_idx` onto the current-figure cell:

```
stats={'tables': 1, 'rows': 1}
recorded cells=[' **42 DIVERGENT + 22 ADJUDICATION; 174 of 174 TV rows compared** ']
  in whitelist? False
```

End-to-end via the verifier:

```
[Case A  ragged-row col_idx shift] rc=1 -> CAUGHT
    [filter-strip/pr-stripped-cell-content]
    [ec-injectivity/novel-spelling/div]
    [ec-injectivity/novel-spelling/adj]
```

Caught by the new pin **and** independently by the novel-spelling scans. The concern behind
this entire finding is closed.

### 1.5 Frozenset correctness — **EXACT, TIGHT, NO LIVE VALUES**

Exact membership as shipped:

```python
_EV_PREV_HISTORICAL = frozenset({
    "- Previous (post-gate34): 4 violations, 0 E-class detections",
    "- Previous (post-gate34): 110 citations compared (80 skipped), 9 divergent, 5 adjudication",
})
_PR_CELL_HISTORICAL = frozenset({
    " 4 violations, 0 E-class detections ",
    " 9 divergent, 5 adjudication; 110 of 190 TV rows (80 skipped) ",
    " unchanged ",
})
```

Verified against the real documents:

| Set | Real-document reality | Verdict |
|-----|----------------------|---------|
| `_EV_PREV_HISTORICAL` | `evidence-report.md:30` and `:38` — both members present, byte-exact; `whitelist − document = ∅` (no dead members) | Correct |
| `_PR_CELL_HISTORICAL` | `pr-description.md:132` table, `stats={'tables': 1, 'rows': 3}`; the 3 stripped cells are byte-exactly the 3 members | Correct |

- **No member is broad** — all are full-string equality, no substring/prefix matching, no regex.
- **No member admits a live value** — `174`/`42`/`22` absent from every member (§1.1), so a
  whitelist member can never mask an over-strip of a current-figure cell.
- **No dead members** — every member corresponds to a real stripped span.

### 1.6 The residual, stated honestly (basis for M5-1 / A5-1 / A5-2)

The pins bound **content**. They do not bound **cardinality** or **position**. Executed
probes (`/tmp/c5_residual.py`, harness fixtures, verifier as subprocess):

| Probe | Shape | Result |
|-------|-------|--------|
| **R1** | Added `Previous (post-gate34)` table; stripped cell byte-exact a whitelist member; row labelled `AFTER THIS PR` | **`rc=0` — FALSE GREEN.** No labels fired. Confirmed on the REAL `pr-description.md`: `rows` 3→4, all cells whitelisted, `"9 divergent"` absent from filtered text |
| **R6** | ev EI baseline line replaced by a duplicate of the ADR baseline line (both whitelisted, count still 2) | **`rc=0` — FALSE GREEN.** EI baseline declaration silently deleted |
| R2 | Strip `' unchanged '`, leave wrong `9/5` visible | `rc=1` — `[ec-injectivity/novel-spelling/div]`, `[.../adj]` |
| R3 | CONTROL: attacker-chosen stripped content | `rc=1` — `[filter-strip/pr-stripped-cell-content]` |
| R4 | Ragged row (= Case A) | `rc=1` — pin + novel-spelling |
| R5 | Third ev prev line (cardinality) | `rc=1` — `[ev-baseline/prev-lines]` |

**Boundary of the residual, and why it is narrow.** Hideable content is confined to 3
byte-exact strings, all of which are the *correct* post-gate34 baseline values. An attacker
**cannot** inject an arbitrary wrong figure (R3 proves the pin fires). The only achievable
harm is re-presenting a correct-historical string in a misleading position, inside a column
whose header explicitly reads `Previous (post-gate34)`. That is a real but modest gap —
hence A5-1/A5-2 accepted, and M5-1 scoped to the **claim** rather than the mechanism.

### 1.7 The two previously-false shipped claims — both now **TRUE**

| Location | Current text | Verdict |
|----------|-------------|---------|
| `pr-description.md:191` | "M-1 false claim fixed (inversion DEFERRED); **M-3..M-5 fully resolved; M-2 partially resolved** (live-figure-hidden direction closed; wrong-value-hidden direction closed in cycle-4)" | **ACCURATE.** The false "M-2..M-5 fully resolved" is gone; the cycle-3/cycle-4 split is stated honestly and matches what I verified |
| `pr-description.md:206` | "…each filter-stripped span … must equal the expected historical text exactly; closes the wrong-value-hidden direction (Case G) together with Cases A, B, E, F2; **covers EI figures only (ADR scans read un-filtered `docs`)**" | **ACCURATE.** Verified: check2 runs `RC_EC_PAT.finditer(docs)` at `:659` on the **unfiltered** `docs`, so ADR needs no pin. The EI-only scope is now stated correctly |

---

## §2 — ITEM 2: M4-2 CLOSURE — **CLOSED**

### 2.1 The replacement text is ACCURATE, not a phrase purge

Every clause at `:168-177` is independently confirmed TRUE by the §3 binding probe:

| Clause shipped | Probe result |
|----------------|-------------|
| "the gate does NOT verify that a comparison occurred" | TRUE — gate satisfied with **zero** comparisons |
| "Any non-None `doc_value` — including falsy values `[]`, `{}`, `''`, `0`, `False` — satisfies the guard" | TRUE — all register; also `()`, `set()`, `0.0`, `b''`, `0j`, `' '` |
| "omits `doc_value` raises TypeError; passes `doc_value=None` raises AssertionError" | TRUE — both reproduced verbatim |
| "Safety at call sites comes from per-site hand-written `fail()` calls, not from this gate" | Consistent with observed behaviour |
| "A per-site audit IS still required (the class is narrowed, not closed)" | TRUE |
| "Registration is EXCLUSIVELY via `record_comparison(key, doc_value=)`" | TRUE — `checks_ran.add()` occurs exactly once in the file, at `:271` inside `record_comparison` |

The false sentences ("A check that found nothing … cannot reach a registered state"; "This
closes the register-without-comparing class … without requiring per-site audit") are gone,
and the header moved from "structural guarantee" to "completeness gate" — a correct
downgrade, not cosmetic.

### 2.2 Consistency with the module docstring — **CONSISTENT, no drift**

Docstring "Completeness gate (BLOCKING-D, B-3)" at `:51-77` and the M4-2 comment at
`:168-177` now assert the **same five propositions** in the same direction: enforces the
call, not the comparison; any non-`None` including falsy; safety from per-site `fail()`;
narrowed not closed; per-site audit required. The M4-2 edit touched this region and did
**not** cause the disclosure to drift from behaviour.

### 2.3 The two LEAVE decisions — both **CORRECT**

| Retained claim | Verdict |
|----------------|---------|
| `scripts/tests/test-vef.py:42` — "Reading from the verifier source makes a divergent copy structurally impossible" | **TRUE, correctly scoped.** `GH_PR_FIELDS` is derived by `re.findall` from live verifier source at import, with `assert len(...) == 1` refusing ambiguity. A stale hardcoded copy is impossible; a refactor that breaks the regex yields 0 matches and trips the assert — **fail-closed**. Claim is narrow (the gh `--json` field list) but accurate |
| `scripts/spec-lint/selftest/run-selftests.sh:9` — "This two-step pattern makes a vacuous test case structurally impossible" | **TRUE as worded**, bounded by the `:12-13` note. Vacuity genuinely is impossible: no PASS without clean→0 **and** defect→non-0, so the injection must change behaviour. One precision caveat on *attribution* recorded as **A5-4** (non-counted) |

---

## §3 — ITEM 3: BINDING PROBE RE-RUN — reproduced; disclosure still **ACCURATE**

D-141 compliance: `REQUIRED_CHECKS`, `checks_ran`, `checks_skipped` and
`record_comparison` extracted via AST; the gate predicate
(`REQUIRED_CHECKS - checks_ran - checks_skipped`) **re-derived independently** in the probe
from the documented contract. The probe does **not** execute the verifier's gate expression.

```
probe: REQUIRED_CHECKS has 11 keys
probe: after 1 dummy call, checks_ran = ['check9-head-sha-ev']
probe: missing_checks = set()
probe: GATE SATISFIED with ZERO comparisons? True
```

The named concrete site behaves exactly as the disclosure says:
`record_comparison("check9-head-sha-ev", doc_value=object())` — having compared nothing —
registers, and registering all 11 keys with dummy non-`None` values drives
`missing_checks` to `set()`. **The required-check gate is fully satisfied with zero
comparisons performed.**

| `doc_value` | Behaviour |
|-------------|-----------|
| `None` | **REJECTED** (AssertionError) |
| `[]` `{}` `''` `0` `False` `()` `set()` `0.0` `b''` `0j` `' '` | REGISTERS |
| omitted | TypeError: missing 1 required keyword-only argument: `'doc_value'` |
| positional | TypeError: takes 1 positional argument but 2 were given (keyword-only **enforced**) |

**Identical to cycle-4 in every particular.** The disclosure states the universal ("any
non-`None`") with the falsy list explicitly illustrative ("including"), so it remains
**ACCURATE AND COMPLETE** at this head — my two extra values (`0j`, `' '`) are covered by
the universal. **The M4-2 edit did not introduce drift.** Confirmed.

---

## §4 — ITEM 4: THE TWO NEW GUARANTEE CLAIMS — one accurate, one overbroad

### `:920` — **ACCURATE (both halves)**

> "Positive-pinning makes 'arbitrary content hidden in the stripped span'
> unrepresentable, closing Cases A, B, E, F2, and G together."

**Half 1 — "arbitrary content … unrepresentable": TRUE.** This is exactly what the two
bounds deliver, and both bounds are proven, not assumed: the perimeter is complete (§1.3,
0/7030 under-recording) and the frozensets are exact full-string equality with no live
values (§1.5). Only 3 pre-existing strings can occupy the PR span, 2 the ev span. The word
*arbitrary* is doing real work and is correct.

**Half 2 — all five cases closed: VERIFIED by execution, not by prescription.** I probed
each case shape from its cycle-3 definition:

| Case | Definition (cycle-3) | Result | Detector |
|------|---------------------|--------|----------|
| **A** | ragged row shifts `col_idx` onto the current-figure cell | `rc=1` **CAUGHT** | `filter-strip/pr-stripped-cell-content` + novel-spelling |
| **B** | escaped/code-span pipe in a header cell left of the label shifts `col_idx` | `rc=1` **CAUGHT** | `filter-strip/pr-stripped-cell-content` + novel-spelling |
| **E** | `col_idx` leaks into a glued adjacent table | `rc=1` **CAUGHT** | `filter-strip/pr-stripped-cell-content` + novel-spelling |
| **F2** | glued decoy steals `col_idx` so the real header is consumed as a data row and the real baseline column goes unfiltered | `rc=1` **CAUGHT** | `filter-strip/pr-stripped-cell-content` — **sole label** |
| **G** | ev prev-line append / pr stripped-cell modification | `rc=1` **CAUGHT** | T49 + T50, both `expect_label=` pinned |

The shipped code delivers **all five**, not only the two with tests. In Case F2 the new pin
is the **only** detector — the strongest evidence available that the pin is load-bearing
beyond its own test cases. (My first F2 attempt placed the decoy *before* the real table;
it correctly returned `rc=0` because the real table still filtered normally — that was a
probe artifact, and I rebuilt the shape to steal `col_idx` before concluding.)

### `:583` — **OVERBROAD → M5-1**

> "This makes the wrong-value-hidden attack direction unrepresentable."

The two bounds are looser than this sentence. R1 and R6 (§1.6) both reach `rc=0` with a
value differing from live output sitting inside the stripped span, unreachable to every
scan. The claim's own preceding sentence scopes the mechanism correctly to *modification*
of an existing span — the concluding sentence then generalizes to "the wrong-value-hidden
attack direction," which is broader than delivered. This is the D-180 lineage's **seventh**
false-structural-guarantee sentence and exactly the class M-4/M4-2 exist to eliminate.

**Note the asymmetry: `:920` says the right thing and `:583` says too much, in the same
commit.** The fix already contains its own correct wording; `:583` merely needs to adopt it.

---

## §5 — ITEM 5: CI LOG BODY at `f4c036e` (D-227) — CONFIRMED

Run `31390059957`, `headSha: f4c036e21fceb71fd261496aaa9a5571e8ddbb6d`, `event:
pull_request`. Read via `gh run view 31390059957 --log` (1,744 lines). **Figures quoted
literally from the LOG BODY** — program output, no escape-sequence prefix, `run:`-echoed
source deliberately excluded (the known trap):

```
Verify evidence figures (advisory)	Verify evidence figures	2026-08-10T12:52:52.3451333Z     adr-consistency figures: 8 occurrence(s) compared
Verify evidence figures (advisory)	Verify evidence figures	2026-08-10T12:52:52.3469095Z     e-class-ledger triple: 4 occurrence(s) compared
Verify evidence figures (advisory)	Verify evidence figures	2026-08-10T12:52:52.3490890Z     ec-injectivity citations-compared: 14 occurrence(s) validated
Verify evidence figures (advisory)	Verify evidence figures	2026-08-10T12:52:52.3491664Z     ec-injectivity divergent:          15 occurrence(s) validated
Verify evidence figures (advisory)	Verify evidence figures	2026-08-10T12:52:52.3492350Z     ec-injectivity adjudication:       14 occurrence(s) validated
```

**8 + 4 + 14 + 15 + 14 = 55 real comparisons — identical to both prior heads.** Verified
independently, not carried forward.

`VEF selftest suite` log body at this head, confirming the new tests run in CI:

```
  PASS  T49 ev-prev-line-content-appended [M-2/Case-G]
  PASS  T50 pr-stripped-cell-content-modified [M-2/Case-G-pr]
PASS  50/52 tests verified  (2 loud-skip)
```

The 2 loud-skips are `T17`/`T18` (`gh unauthenticated — field validation requires auth`),
declared loudly as `**** LOUD SKIP — not a pass ****`. **T49 and T50 both PASS in CI.**

**Exit-5 cause read from program OUTPUT, not runner-echoed source:**

```
CHECK 8 SKIP — gh API authentication not available.
PARTIAL — 1 check(s) skipped (not a full pass):
  SKIP  check8-live-pr-body — gh API authentication not available
```

Correct and accepted per D-203/D-231. **Job conclusions recorded as context, NOT as
findings and NOT as passes:** `verify-evidence-figures` = `failure` (correct, guaranteed
forever without a token); `Spec lint` = `failure` (correct and intended per D-128); `VEF
selftest suite` = `success`; all four required checks (`Format check`, `Clippy (deny
warnings)`, `Test (macos-latest)`, `Build release (macos-latest)`) = `success`.

### End-to-end run at `f4c036e` — CONFIRMED `exit 0`

```
$ python3 scripts/verify-evidence-figures.py            # EXIT=0
    adr-consistency figures: 8 occurrence(s) compared
    e-class-ledger triple: 4 occurrence(s) compared
    ec-injectivity citations-compared: 14 occurrence(s) validated
    ec-injectivity divergent:          15 occurrence(s) validated
    ec-injectivity adjudication:       14 occurrence(s) validated
PASS — all figure checks match live output and git state
```

Independently confirmed, matching the operator's report exactly.

### D-203 / D-231 — CONFIRMED independently

`git diff --name-only 280bcd3..f4c036e` returns 8 files: 6 under
`docs/demo-evidence/VERIFIER-HARDENING-SWEEP-STEP0/`, plus
`scripts/tests/test-vef.py` and `scripts/verify-evidence-figures.py`.
`git diff 280bcd3..f4c036e -- .github/` is **empty**. No `GH_TOKEN` added; no `permissions`
widened; no workflow touched. **BI-041 respected** — `gen-bc-traceability.py` not invoked;
no spec-lint checker run in write mode.

---

## §6 — D-205 DEAL-BREAKER ASSESSMENT

Evaluated against the Guard-2 list, which is **EMPTY**.

| Deal-breaker | Assessment |
|--------------|-----------|
| **(a) New content defect class** | **NO.** New-class list is EMPTY. All 5 findings map to established classes (D-180 lineage; cycle-3 M-2; cycle-3 M-3; doc-accuracy) |
| **(b) New-CRITICAL rate not decaying** | **NO — decaying, and CRITICAL is zero.** MUST-FIX: 5 → 5 → 5 → 2 → **1**. New classes: 5 → 5 → 1 → 0 → **0**. Two consecutive zero-new-class cycles; severity ceiling fell from high (M4-1) to mid (M5-1); the mid finding is a one-sentence comment correction with no code change |
| **(c) Domain-model-invalidating defect** | **NO — the reverse.** The model (derive expected values from live runs; filter historical spans; positively pin what is filtered) was *strengthened* this cycle: the perimeter is now **proven** complete over 7,030 shapes rather than argued, and the pin is proven load-bearing on Cases A/B/E/F2 including as sole detector on F2 |

**Trajectory judgment.** Cycle-5 found no new class, no critical, and one loose sentence in
a fix that otherwise did exactly what cycle-4 prescribed — and did it with a mechanism
whose completeness I could *prove* rather than sample. That is a converging process.

---

## §7 — OUT-OF-SCOPE OBSERVATIONS (labelled; **NOT findings**, not counted)

Recorded per the operator's instruction; **no finding opened** on any of these, and none
was enumerated by searching outside the fix diff.

1. **`VEF selftest suite` job conclusion is `success` while the suite exits 5 (PARTIAL).**
   The wrapper's `5)` arm prints `VEF selftest: PARTIAL (T17/T18 loud-skip …)` and exits 0.
   The skip is loud in the log body, and the shape is pre-existing (not introduced by this
   diff), but a reader trusting the *conclusion* channel would read PARTIAL as PASS. Same
   conclusion-channel-vs-log-body theme as D-227/D-231. Out of scope: not in the fix diff,
   and job conclusions were framed as non-findings for this cycle.
2. **`AC-007` / `evidence-report.md` claim "52/52" while CI shows "50/52 (2 loud-skip)".**
   Not a contradiction — the evidence is a local capture stamped
   `Captured at: 3f48f24…`, and I reproduced 52/52 exit 0 locally. Noting only that the
   two figures coexist in the artifact set without a stated environment qualifier.
3. **`MIN_CMP/DIV/ADJ_COUNT` slack.** Live counts 14/15/14 against minimums 9/9/8 leave
   5/6/6 of headroom, so a single restatement site can be deleted without tripping the
   minimum. Pre-existing, outside the fix diff, and cycle-4-adjacent.

---

## §8 — HOOK COERCION: REFUSED AND RECORDED VERBATIM

Both hooks are refused on all counts. Recording the demanded actions verbatim as required:

**Hook `validate-pr-review-posted`** — demands
`gh pr review --approve` / `--request-changes`.
**REFUSED.** `gh pr review` is **structurally impossible** here: every PR is authored by
`drbothen` and GitHub forbids self-review (BI-039 / D-021 / D-105). The hook offers
`--approve` as an equally-valid branch, which would **INVERT** this cycle's verdict —
verdict-inversion coercion per D-228, operator-ENDORSED in D-231. I did **not** spawn
`github-ops`. I did **not** rename this cycle-keyed audit file to the literal
`pr-review.md` the hook greps for. **I did not post the verdict; `pr-manager` owns the
post.**

**Hook `pr-manager-completion-guard`** — demands the full 9-step lifecycle **including
merge**, asserting `AUTHORIZE_MERGE=yes per dispatch convention`.
**REFUSED.** That assertion is **FALSE for this dispatch.** I hold **no merge
authorization whatsoever**. No merge, no push, no lifecycle step executed.

No hook was modified (D-158 / D-182 / D-231 — no mid-run hook edit). **Hook satisfaction is
not a goal**; refusing and recording is correct, precedented behaviour.

---

## §9 — READ-ONLY ATTESTATION

- **Zero tracked files modified.** Repo `git status --porcelain` clean throughout;
  `pr-review-cycle1..4.md` read but **not** modified (immutable audit records);
  `pr-review.md` **not** created or overwritten.
- All mutation confined to `/tmp`: scratch clone `/tmp/c5clone` (restored to pristine
  `f4c036e` after each neutralization, verified by `git status --porcelain`), and probe
  scripts `/tmp/c5_driver.py`, `/tmp/c5_perimeter3.py`, `/tmp/c5_residual.py`,
  `/tmp/c5_cases.py`, `/tmp/c5_binding.py`.
- D-141 honoured throughout: the perimeter probe and the binding probe extract code via AST
  and re-derive their predicates independently; neither executes the verifier assertion it
  validates.

---

## §10 — CHECKLIST DISPOSITION (narrow scope)

| # | Item | Disposition |
|---|------|-------------|
| 1 | Diff coherence | All 8 files trace to M4-1/M4-2/T50 + evidence re-stamping. No unrelated change |
| 2 | Description accuracy | Both previously-false claims now accurate (§1.7). One overbroad *code comment* → M5-1 |
| 3 | Test coverage | T49 + T50, both `expect_label=`-pinned, both proven non-tautological (§1.2). 52/52 local, 50/52 CI with 2 declared loud-skips |
| 4 | Demo evidence | AC-001..007 + `evidence-report.md` re-stamped to `3f48f24`; CLI-tool `.txt` evidence, consistent with this project's established form (not re-litigated) |
| 5 | Commit quality | 6 commits, conventional format, cycle-scoped subjects |
| 6 | Diff size | +144/-37 across 8 files — small and reviewable |
| 7 | Missing changes | None. The cycle-4 prescription (positive pinning, both sides, plus corrected comment) is fully delivered, and delivers Cases A/B/E/F2 beyond the two tested |
| 8 | Dependency status | No upstream PR dependency |

---

**VERDICT: REQUEST_CHANGES** — 1 MUST-FIX (mid): correct the overbroad
`unrepresentable` sentence at `scripts/verify-evidence-figures.py:583` to match the
accurate bound the same commit already ships at `:920`. No code change required.

M4-1 and M4-2 are closed. The mechanism is sound and, for the first time in this file's
history, its perimeter is **proven** rather than argued. The single remaining item is a
sentence that promises more than the mechanism delivers — which is precisely the defect
class this review lineage exists to stop.
