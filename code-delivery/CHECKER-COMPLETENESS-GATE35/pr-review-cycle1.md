# PR Review — CHECKER-COMPLETENESS-GATE35 (cycle 1)

**PR:** #12 — Spec-lint oracle repairs (BI-056 E-code detector + BI-057 multi-column TV extraction)
**covered_sha:** 879efff417106c05597e4edf8d005c9136c56a67
**Reviewer method:** independent reproduction. I ran the full selftest suite, ran the `develop`
and PR versions of both checkers against the live corpus, and ran three targeted mutations to
test the mutation-kill claims written into the new/updated selftests. All mutations were applied
to throwaway copies or applied-and-immediately-reverted in the working tree; the tree is clean
and `.factory/specs/` was never touched.

---

## What I verified as correct

Everything below reproduced exactly as claimed. No content defect is reported here, and no
suggestion in this review asks for a `.factory/specs/` edit.

| Claim | Verified |
|-------|----------|
| Selftests 93/93, `EXPECTED_TEST_COUNT=93`, `TESTS_RUN=93` | Reproduced (`Selftest passed: 93/93`) |
| `check-adr-consistency`: 4 → 9 violations, "79 reason-code + 5 E-class" | Reproduced exactly |
| New E-class detections at `BC-2.01.009.md:44,52,71,73` + `interface-definitions.md:237` | Reproduced exactly |
| D-081 frontmatter exclusion still holds for Pattern 4 | Confirmed — `BC-2.01.009.md:23` (which contains *both* `E-CLI-001` and `E-IO-002`) is not flagged. Pattern 4 sits inside the per-line loop after the `in_frontmatter: continue` guard. |
| Return-arity change `(violations, occurrences, e_code_occurrences)` propagates | Correct; both the pass and fail summary lines render the new counter. |
| No detection regression in `check-adr-consistency` | New violation set is a strict superset of the old 4. |
| No detection regression in `check-ec-injectivity` | Old 9 `SCENARIO-MISMATCH` and old 5 `REQUIRES-ADJUDICATION` EC IDs are all still present. Nothing was masked relative to `develop`. |
| `check-ec-injectivity`: 110 → 174 citations, 40 divergent, 11 adjudication | Reproduced exactly |
| `parse_frontmatter_end()` is called before the inline BC-row scan | Yes (`start = parse_frontmatter_end(raw_rows)`), and the inline loop is otherwise semantically identical to `extract_ec_rows()` |
| D-132 BC-row math | Sound and *asserted*: `193 parsed + 1038 skipped-no-ec + 0 skipped-empty = 1231 scanned` |
| D-132 collision math | Sound and asserted: `161 tested + 58 single = 219 = total_ec_ids` |
| Corpus-wide E-code population "8 occurrences (6× E-IO-002, 2× E-CLI-001, 3 files)" | Confirmed by independent grep |
| Pattern 4 cannot reintroduce the PR #11 false positives | Structurally sound — the pattern requires `E-` + 2–4 uppercase + `-NNN`; every removed FP was a lowercase reason-code token |
| Selftest 5k clean fixture is genuinely clean | Confirmed: no E-class token and no phantom reason code in the clean tree; clean-pass asserted before the defect injection |
| Selftest EI-7 proves the §2-shape `Filesystem` column is parsed | Yes — removing `"filesystem"` from `_COMPARABLE_KEYWORDS` kills EI-7 (via clean-fixture exit 1) |
| Upstream dependency ORACLE-REPAIRS-GATE34 merged | Yes, `da86271` on `develop` |
| Diff coherence | All 8 files are in scope (3 checker/test files + 5 evidence artifacts). No unrelated changes. `.factory/specs/` untouched. |

---

## BLOCKING

### BLOCKING-1 — Selftest EI-4's skip assertion is now vacuous; the mutation it documents survives

**Files:** `scripts/spec-lint/selftest/run-selftests.sh` (EI-4 clean assertion),
`scripts/spec-lint/check-ec-injectivity.py` (zero-skip branch wording)

EI-4's structural assertion was relaxed from `grep -q "non-comparable TV rows skipped"` to
`grep -q "TV rows skipped"`. But the new zero-skip branch in `check-ec-injectivity.py` reads:

```python
skip_msg = (
    f"{total_tv_skipped} TV rows skipped ({'; '.join(skip_detail_parts)})"
    if skip_detail_parts else "0 TV rows skipped"
)
```

`"0 TV rows skipped"` contains the substring `"TV rows skipped"`. Both branches now match the
grep, so EI-4 can no longer distinguish "a section was skipped" from "nothing was skipped" —
which is the only thing EI-4 exists to prove.

EI-4's own comment states the kill condition:

> Mutation-verify: expanding `_COMPARABLE_KEYWORDS` to include `"source md file"` or
> `"expected exit"` would make section B rows comparable ... the skip count in the coverage
> line would drop to 0 → STRUCTURAL FAIL fires → MUTATION DIES.

**I ran exactly that mutation** (added `"expected exit"` to `_COMPARABLE_KEYWORDS`) against the
full suite:

```
mutation applied: expected exit -> COMPARABLE
SUITE RC=0
── selftest EI-4: ... ──
  PASS (clean-pass with skipped rows confirmed; EC-004 divergence correctly detected)
Selftest passed: 93/93 negative tests verified
```

The mutation **survives**, and EI-4 prints "clean-pass with skipped rows confirmed" while zero
rows were skipped. The regression guard protecting the comparable-column set is gone, on the
exact PR that widens that set.

**Suggestion:** make the branches lexically distinguishable and restore a discriminating
assertion, e.g. emit `"no TV rows skipped"` in the zero branch and assert
`grep -qE "[1-9][0-9]* TV rows skipped"` in EI-4. (Do not change checker logic to fix the test —
this is a wording + assertion fix, not a semantic one.)

### BLOCKING-2 — Moving `"link"` to `_COMPARABLE_KEYWORDS` suppresses 11 EC IDs' findings, buys zero coverage, and is pinned by no test

**File:** `scripts/spec-lint/check-ec-injectivity.py` (`_NON_COMPARABLE` / `_COMPARABLE_KEYWORDS`)

I built a variant that reverts only this one change (`"link"` back into `_NON_COMPARABLE`,
removed from `_COMPARABLE_KEYWORDS`) and ran both against the live corpus:

| | citations compared | TV rows skipped | divergent | adjudication |
|---|---|---|---|---|
| `develop` | 110 | 80 | 9 | 5 |
| **PR as written** | **174** | **17** (all legitimately EC-less) | **40** | **11** |
| PR with `"link"` reverted to non-comparable | **174** | **17** | **42** | **22** |

Two things follow:

1. **The coverage win does not depend on `"link"`.** All 174 rows parse either way, and
   `skipped_by_col` is empty either way — the 110 → 174 widening comes entirely from
   `"filesystem"`, `"heading"`, `"mock server"` and change (c).
2. **Making `"link"` comparable is a net finding-surface reduction.** Concatenating the
   `Link` cell (link targets / filenames) into the TV scenario text raises Jaccard and promotes
   findings to PASS. Eleven EC IDs lose *all* findings:
   - out of divergent entirely: `EC-077, EC-081, EC-082, EC-083, EC-084, EC-149`
   - out of adjudication entirely: `EC-069, EC-072, EC-073, EC-089, EC-091`
   - (3 more — `EC-051, EC-053, EC-092` — escalate adjudication → divergent, the only movement
     in the widening direction)

   Total finding lines: 64 → 51.

This also reverses a documented calibration decision without replacing the rationale. The
comment deleted in this PR said BC-vs-TV description comparison was scoped the way it was because
"TV captures the canonical input-file name, not a scenario description" — precisely why `Link`
was non-comparable. The replacement rationale is one unevidenced sentence: "in multi-column mode
a Link cell alongside Filesystem or Heading provides useful Jaccard tokens."

3. **Nothing tests it.** I reverted `"link"` to non-comparable and ran the full suite:
   `93/93 green`. Neither EI-4 (now uses `Source MD File`) nor EI-7 (whose header also carries a
   comparable `Filesystem` column) dies. So the single most consequential semantic change in
   BI-057 has no mutation-killing selftest.

**Suggestion:** drop `"link"` from `_COMPARABLE_KEYWORDS` (coverage is unchanged at 174/190,
and the 13 finding lines return), or — if `"link"` is genuinely wanted — add a selftest that dies
when it is reverted, plus a written calibration explaining why the 11 suppressed EC IDs are false
positives rather than real divergences. Under D-122 ("oracles expected to WIDEN the count before
it shrinks"), a 20% narrowing of the finding surface inside a completeness-gate PR needs an
explicit proof, not a side effect.

---

## WARNING

### WARNING-1 — The E-code registry whitelist is unreachable for any code that appears in a Pattern 2/3 shape

**File:** `scripts/spec-lint/check-adr-consistency.py`

`extract_valid_e_class_codes()` is documented as "the live source-of-truth so future codes can be
whitelisted without changing the checker." That is only true for Pattern 4. Patterns 2 and 3 run
*first*, claim the token via the shared `seen_codes_this_line`, and validate against
`valid_reason_codes` — a set that structurally can never contain an E-code.

Reproduced hermetically. With `E-IO-002` and `E-CLI-001` both registered in a §1 registry:

- Pattern-4 shape (`emits an E-IO-002 error`) → `Check passed: ... 3 E-class code occurrences validated ... 0 non-conforming`
- Pattern-3 shape (`(consistent with E-CLI-001 taxonomy)`) → `taxonomy reference 'E-CLI-001' not in closed taxonomy (POLICY 19)`, exit 1

So a registered E-code cannot be silenced in the taxonomy-reference shape without also adding it
to the reason-code closed set. This is latent today (`valid_e_codes` is empty), but it becomes a
false positive the moment the content-remediation workstream registers any E-code — promote to
blocking if that is imminent.

A secondary consequence: because Pattern 3 claims `BC-2.11.004.md:61` first, that occurrence is
counted in the *reason-code* bucket. The reported "5 E-class code occurrences" therefore
under-reports the actual non-frontmatter E-class population (6).

**Suggestion:** route the E-code namespace through a single owner. Either check E-class tokens
against `valid_e_codes` inside Patterns 2/3 as well (branch on `E_CLASS_CODE_RE.fullmatch(code)`),
or run Pattern 4 first and let it claim E-class tokens before P2/P3 see them.

### WARNING-2 — `extract_valid_e_class_codes()` reads the wrong section and fails silently

**File:** `scripts/spec-lint/check-adr-consistency.py`

The function keys the registry on `^## 1\.`, described in the code as "§1 (error-class registry)".
§1 of the real `error-taxonomy.md` is `## 1. Verdict Classes (Two-Layer Model — DD-022)` — the
verdict-class section, not an error-class registry; no E-code registry section exists anywhere in
the file. The function therefore returns an empty set for a reason unrelated to the one documented,
and if a future registry is added as (say) `## 7. Error Class Registry`, the whitelist stays
silently empty.

Every other extraction in this suite fails closed — `main()` returns 2 when
`extract_closed_reason_codes()` comes back empty. This one degrades silently.

**Suggestion:** match a *named* anchor (e.g. a heading containing "error class registry") and, if
no such section exists, either return empty with an explicit printed disclosure or fail loudly the
way the reason-code extraction does. No spec edit required to do this.

### WARNING-3 — A D-132 skip counter is accumulated and then dropped; TV extraction has no completeness assertion

**File:** `scripts/spec-lint/check-ec-injectivity.py`

- `total_tv_skipped_no_tv_id` is declared, incremented from `extract_tv_rows()`, and then **never
  printed and never asserted**. The comment says it is "reported for transparency" — it is not.
  It is exactly the silent skip site D-132 exists to eliminate.
- `total_tv_parsed` is computed and never used (dead assignment).
- There is no TV-side sum assertion analogous to the BC-row one. BC rows get a real assertion
  (`parsed + skipped_no_ec + skipped_empty == scanned`, exit 1 on mismatch); TV rows get only a
  printed message.

The PR body claims "all TV-extraction and per-EC-pairing granularities asserted". Only BC-row,
per-EC pairing, and collision granularities are actually asserted; TV extraction is
reported-only, and one of its counters is not even reported.

**Suggestion:** print `total_tv_skipped_no_tv_id` in the D-132 block and add
`tv_parsed + tv_skipped_col + tv_skipped_no_ec + tv_skipped_no_tv_id == tv_table_rows_scanned`
as a hard assertion (that will require `extract_tv_rows()` to also return a scanned-row count).

### WARNING-4 — The D-132 pairing line double-counts and contradicts the assertion two lines above it

**File:** `scripts/spec-lint/check-ec-injectivity.py` (`pairing_msg`)

Live output:

```
D-132: 161 EC IDs compared (19 BC-only, 39 TV-only, 58 single-occurrence skipped)
```

The assertion immediately above enforces `bc_only + tv_only + compared == total_ec_ids`
(19 + 39 + 161 = 219). The 58 single-occurrence ECs are not a fourth bucket — they are already
inside the first two (and in fact 19 + 39 = 58 exactly, so the parenthetical lists the same 58
ECs twice). An auditor reading this line will compute 277 and conclude the partition is broken.
`collision_msg` is the line where the single-occurrence count is the correct partition, and it
already says so.

**Suggestion:** drop `single-occurrence skipped` from `pairing_msg`.

### WARNING-5 — Change (d)'s hard short-circuit is keyed on an assumption a sibling generator in the same directory violates

**File:** `scripts/spec-lint/check-ec-injectivity.py`

`other_spec_ec_violations` triggers `return 1` *before* any injectivity or scenario output is
printed. `scripts/spec-lint/gen-ec-registry.py` writes
`.factory/specs/prd-supplements/ec-registry.md` with rows shaped
`| EC-NNN | TV-NNN | desc | verdict |` (line 100) — exactly the shape `extract_ec_rows()` parses,
in a file that is neither in `BC_DIR` nor `TV_FILE`.

That file is absent from the corpus today, so the invariant passes (verified). The first time
anyone runs the generator, `check-ec-injectivity` exits 1 on `UNEXPECTED-EC-CITATION` and **all**
40 divergences, 11 adjudications, and the entire D-132 block disappear from the output. Generators
are not wired into `.github/workflows/ci.yml`, so this is latent rather than live.

**Suggestion:** either allowlist generated registry artifacts, or append these to `violations`
(which are printed alongside everything else) instead of short-circuiting with an early `return 1`.

### WARNING-6 — BI-057 changes (c) and (d) have no selftest at all

**File:** `scripts/spec-lint/selftest/run-selftests.sh`

The suite gains exactly two tests. Nothing exercises:

- **change (c)** — the non-table-line state reset. This is presented as fixing a latent mis-parse
  ("stale desc_col from §6 bleeding into §7"), i.e. a real prior defect, and it has no
  clean-pass/defect-fail pair. A revert would be invisible to the suite.
- **change (d)** — the new checked invariant. `grep -n "UNEXPECTED-EC-CITATION"
  scripts/spec-lint/selftest/run-selftests.sh` returns nothing, so neither the firing path nor the
  non-firing path is pinned.

**Suggestion:** add a fixture with an unrecognised `TV | Heading Text` header following a
comparable section (kills the (c) revert), and a fixture with an EC row in a non-BC/non-TV spec
file (kills the (d) revert).

### WARNING-7 — Selftest 5k's `E-CLI-001` assertion does not pin Pattern 3, contrary to its own comment

**File:** `scripts/spec-lint/selftest/run-selftests.sh` (5k)

5k asserts:

> All three grep assertions are necessary; dropping any one would re-open the original blind spot.
> Removing `TAXONOMY_CODE_RE` (reverting Pattern 3) loses E-CLI-001 → `grep -q "E-CLI-001"` fails.

`E-CLI-001` matches `E_CLASS_CODE_RE`, so Pattern 4 catches it whenever Pattern 3 does not.
I disabled `TAXONOMY_CODE_RE` and ran the suite:

```
── selftest 5k (BI-056): ... ──
  PASS (clean-pass confirmed; all three phantom codes detected: E-IO-002, E-CLI-001, malformed-fragment)
Selftest FAILED: 1/93 negative tests failed   ← the kill came from selftest 5d, not 5k
```

So 5k passes with Pattern 3 removed. Pattern 3 is still covered (5d dies), which is why this is a
warning rather than blocking — but 5k does not prove what it documents, and the "three codes as a
set" framing overstates what it pins: it pins Pattern 2 and Pattern 4 only.

**Suggestion:** use a non-E-class token for the Pattern-3 leg (e.g.
`(consistent with phantom-p3 taxonomy)`), which Pattern 4 structurally cannot see.

### WARNING-8 — BC-row parsing is now duplicated inline instead of extended in the shared helper

**File:** `scripts/spec-lint/check-ec-injectivity.py`

The BC branch of `main()` reimplements `extract_ec_rows()` line-for-line (frontmatter skip, cell
split, `EC_TOKEN_RE.fullmatch`, `rest_cells` separator filter, desc/verdict election) purely to
add counters. `extract_ec_rows()` now survives only to serve the change-(d) invariant, so the two
must stay byte-identical forever or BC parsing and other-file parsing will silently diverge — and
a divergence there is a false-negative in the invariant, not a loud failure. This cuts against
BI-040's shared-primitive-layer direction (PR #8).

**Suggestion:** have `extract_ec_rows()` return `(rows, scanned, skipped_no_ec, skipped_empty)`
and call it from both branches.

---

## NIT

### NIT-1 — `E_CLASS_CODE_RE` enshrines an undocumented grammar

`E-[A-Z]{2,4}-\d{3}` cannot see `E-X-001` (1-letter namespace), `E-HTTPS-001` (5-letter),
`E-IO-02`, or `E-IO-0002`. Since no spec section defines an E-code grammar at all, the checker's
implicit grammar is unproven — a phantom written as `E-HTTP2-001` stays invisible, which is the
same shape of blind spot BI-056 was raised about (there: prose-shape dependence; here:
namespace-length dependence). Also `(?<![A-Za-z0-9])` still admits a hyphen prefix, so
`FOO-E-IO-002` matches. Consider promoting the token to a named primitive next to `EC_TOKEN_RE`
so the grammar has one owner.

### NIT-2 — EI-7's mutation-kill rationale is inaccurate

EI-7 claims that removing `"filesystem"` yields "0 citations compared → grep fails". It does not:
the same fixture header carries a comparable `Link` column, so the row is still parsed and the
mutation dies via exit 1 on the clean fixture instead. The mutation does die — the stated
mechanism is just wrong. (And per BLOCKING-2, EI-7 does not die if `"link"` is reverted.)

### NIT-3 — Description / evidence metadata drift

- PR body and `evidence-report.md` both say `Head SHA: d3085d9`; head is `879efff`.
- Rollback snippet `git revert d3085d9 2349184` omits the evidence commit `879efff`.
- Traceability table says "`E-CLI-001` ×1 in test-vectors via Pattern 3". It is in
  `.factory/specs/behavioral-contracts/ss-11/BC-2.11.004.md:61`, not `test-vectors.md`, and it is
  not a new detection — it is one of the four pre-existing violations on `develop`. The 5 new
  detections are `E-IO-002` ×4 in `BC-2.01.009.md` + ×1 in `interface-definitions.md`.

### NIT-4 — Diff size

1079 additions / 102 deletions over 8 files exceeds the 500-line review flag. Roughly 490 lines
are demo-evidence text and ~200 are selftest fixtures, so the reviewable logic delta is modest.
Noting for checklist completeness only; no action requested.

### NIT-5 — Selftest 5j's relaxed grep is still sound

`"[1-9][0-9]* reason-code occurrences validated"` → `"[1-9][0-9]* reason-code occurrences"` was
necessary (the word `validated` moved past the new E-class clause) and remains discriminating —
it still requires a non-zero occurrence count. No action.

---

## Checklist disposition

| # | Item | Result |
|---|------|--------|
| 1 | Diff coherence | PASS — 3 checker/test files + 5 evidence artifacts, all in scope; `.factory/specs/` untouched |
| 2 | Description accuracy | PASS with NIT-3 and WARNING-3 (the "all TV granularities asserted" claim overstates) |
| 3 | Test coverage | **FAIL** — BLOCKING-1 (EI-4 vacuous), BLOCKING-2 (`"link"` unpinned), WARNING-6 (changes c/d untested), WARNING-7 (5k's P3 leg not independent) |
| 4 | Demo evidence | PASS for a CLI tooling PR — `evidence-report.md` + 4 AC transcripts present; every headline number reproduced independently. No `.gif`/`.webm`, which is appropriate here (no UI, no interactive surface). |
| 5 | Commit quality | PASS — 3 conventional commits, gate ID present, one logical change each (BI-056, BI-057, evidence) |
| 6 | Diff size | NIT-4 |
| 7 | Missing changes | WARNING-3 — TV-extraction completeness assertion claimed but not implemented |
| 8 | Dependency status | PASS — ORACLE-REPAIRS-GATE34 (`da86271`) merged to `develop` |

## Note on CI

I did not treat the red `Spec lint` check as a finding. Its failure is the declared deliverable
(D-128 advisory-only, D-122 widen-first), and I independently confirmed the failure consists only
of newly-visible content defects plus the pre-existing four — no checker crash, no assertion
break, and no loss of any finding that `develop` produced.

**VERDICT: REQUEST_CHANGES**
