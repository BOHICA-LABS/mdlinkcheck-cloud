# PR Review — Cycle 2

**VERDICT: REQUEST_CHANGES**

**Reviewed:** head `fd74bd7`, base `develop` @ `da86271`, 8 files / +1415 −114.
**Method:** every changed file read; all claims verified by execution, not inspection. Independent corpus greps, five out-of-tree mutants of `check-adr-consistency.py`, an AST comparison of `check_adr()` across base and head, a validated 4-test mutation harness, and a full 96-test suite run. No repo file was modified (all mutants under `/tmp`).

Three blocking findings. The first is a false-green in the very mechanism added to prevent false-greens, and I was able to demonstrate it losing half the live corpus detections with all four new selftests still passing.

---

## BLOCKING-1 — The E-class population reconciliation is a tautology and cannot detect coverage loss

`scripts/spec-lint/check-adr-consistency.py:648-652`

```python
e_population = total_e_occurrences + total_frontmatter_e_skipped
assert e_population == total_e_occurrences + total_frontmatter_e_skipped, (
    f"BUG: E-class accounting error: population={e_population} "
    f"!= examined={total_e_occurrences} + skipped={total_frontmatter_e_skipped}")
```

`e_population` is *defined* on line 648 as `total_e_occurrences + total_frontmatter_e_skipped`, and line 649 asserts it equals that same expression. This is `x == x`. It is unfalsifiable for every possible input, so the comment on lines 641-647 calling it a "HARD RUNTIME ASSERTION" that "every E-class occurrence in the corpus is accounted for" is not accurate. Secondary: `assert` is the wrong construct for a completeness gate — it is stripped entirely under `python -O`, and the three other completeness gates in this same function correctly use `print(...) + return 2` (lines 561, 599, 637).

The design concern behind this is confirmed: `population` is derived from the same matching machinery **and the same routing path** it is meant to audit, so it shrinks in lockstep with `examined`.

### Failure scenario (executed, not hypothesised)

I inserted `if is_table_line: continue` immediately before the Pattern 4 loop — a plausible future refactor, since it mirrors Pattern 1's own `if is_table_line: / else:` structure, and is exactly the "third routing category" that lines 645-647 claim the assertion would force a developer to declare. Against the **live corpus**:

```
E-class population: population=5, examined=3, skipped=2 (frontmatter, D-081)
Check FAILED: 6 violations found (79 reason-code occurrences + 3 E-class code occurrences
validated across 126 non-ADR + 8 ADRs = 134 of 134 spec files (complete), 6 non-conforming)
```

- E-code detections **6 → 3**; violations **9 → 6**. Half the real findings silently gone.
- The reconciliation still closes perfectly (`5 = 3 + 2`).
- Still prints `134 of 134 spec files (complete)`.
- **All four new selftests — 5k, 5l, 5m, 5n — PASS.**

Harness validity was established before trusting that result: unmutated → 4/4 PASS; control mutation (`E_CLASS_CODE_RE` → never-match) → 4 FAILURES across all four tests. So the harness kills mutants; this particular mutant survives it.

Three of the six live detections are in markdown table cells (`BC-2.01.009.md:71`, `:73`, `interface-definitions.md:237`) and none of the four new fixtures put an E-code in a table cell — which is why this mutant survives (see NIT-1).

For completeness, a *partial* regex narrowing (`{2,4}` → `{3}`, keeping `E-ZZZ-001`/`E-CLI-001`, dropping every `E-IO-002`) also closes the ledger cleanly — `population=2, examined=1, skipped=1`, violations 9 → 4 — though that one *is* caught, by 5k's `E-IO-002` grep. Credit where due: the selftests are the thing actually providing protection here, not the assertion.

### Recommended fix

Mirror the file-count gate 60 lines above (581-589), which already does this correctly — an independently computed ground truth compared against the parts, failing loud. Concretely:

```python
# Independent probe: does NOT reuse check_broad_corpus()'s routing / `continue` logic,
# and uses a deliberately WIDER canary than the detector so that narrowing
# E_CLASS_CODE_RE also surfaces as a gap rather than shrinking both sides together.
E_CLASS_CANARY_RE = re.compile(r"(?<![A-Za-z0-9])E-[A-Z]+-\d+")
e_population = 0
for f in sorted(SPECS.rglob("*.md")):
    if not _in_spec_corpus(f):
        continue
    for line in slp.cm_splitlines(f.read_text(encoding="utf-8")):
        e_population += len(set(E_CLASS_CANARY_RE.findall(line)))

if e_population != total_e_occurrences + total_frontmatter_e_skipped:
    print(f"ERROR: E-class accounting gap — population={e_population} != "
          f"examined={total_e_occurrences} + skipped={total_frontmatter_e_skipped}; "
          f"an E-class occurrence is being dropped by an undeclared routing path")
    return 2
```

Under that version, the table-line mutant above yields `population=8 != 3 + 2` and exits 2. Please also add a selftest that injects an undeclared skip and asserts the gate fires, so this gate is itself mutation-verified.

---

## BLOCKING-2 — ADR reason-code violations are now double-reported, inflating the deliverable count

`scripts/spec-lint/check-adr-consistency.py:601-613`

`fd74bd7` calls `check_broad_corpus()` on every ADR *in addition to* `check_adr()`. Both functions contain an independent POLICY 19 reason-code detector (`check_adr` at 206-218; `check_broad_corpus` Pattern 1 at 396-449). When both fire on the same token, `violations` gets two entries.

Failure scenario — an ADR containing:

```markdown
| TV-ID | Verdict | Reason |
|-------|---------|--------|
| TV-001 | broken | `phantom-alpha` |
```

Head reports the *same* defect twice and counts it twice:

```
ADR-900-dup.md:5: reason code 'phantom-alpha' not in closed taxonomy
ADR-900-dup.md:5: reason code 'phantom-alpha' not in closed taxonomy (POLICY 19)
Check FAILED: 2 violations found ...
```

Base (`da86271`) on the identical fixture: `Check FAILED: 1 violations found`.

The live corpus has zero ADR reason-code violations today, so the headline `9` is correct as published. But `len(violations)` is the metric this PR ships as the baseline for the downstream content-remediation workstream, and it is no longer injective with respect to defects in ADR files. The direction is fail-safe (inflation, not false green, and D-122 expects widening) — but double-counting one defect is a measurement error in the instrument, not widening.

**Recommended fix:** the fold only needed Pattern 4 on the ADR path. Measured ADR contribution on the live corpus is **0 E-code occurrences** and **1 reason-code occurrence** (`ADR-006-strict-path-model.md`, 0 violations), so restricting the ADR-path call to E-class detection loses nothing and removes the overlap entirely. Alternatively dedupe `violations` on `(path, lineno, code)` before reporting.

---

## BLOCKING-3 — Demo evidence and PR body are stale by two commits; the headline deliverable appears in no evidence artifact

`docs/demo-evidence/CHECKER-COMPLETENESS-GATE35/` (all 5 files)

The evidence was captured at `d3085d9` and never refreshed for `1dd7721` or `fd74bd7` — the two commits containing the cycle-1 fixes and the entire four-defect fold under review.

| Artifact | Committed evidence | Actual at `fd74bd7` |
|---|---|---|
| `evidence-report.md:4` | `Head SHA: d3085d9` | `fd74bd7` |
| `AC-002-selftest-93of93.txt` (filename + last line) | `Selftest passed: 93/93` | `96/96` |
| `AC-005-adr-consistency-live.txt` | `5 E-class code occurrences ... 126 files scanned + 8 ADRs routed to POLICY 12` | `6 E-class ... 126 non-ADR + 8 ADRs (POLICY 12 + POLICY 19)` |
| `AC-005-...` | **no `E-class population:` line at all** | `E-class population: population=8, examined=6, skipped=2 (frontmatter, D-081)` |
| `AC-006-ec-injectivity-live.txt` | `40 divergent, 11 require adjudication` | `42 divergent, 22 require adjudication` |

The PR body inherits every stale number (`Head SHA: d3085d9`, the `selftests-93/93` badge, `5 E-class occ`, `40 DIVERGENT + 11 ADJUDICATION`) and its traceability table asserts `BI-056 ... CLOSED` on that basis.

The third row matters most: the AC-1 population reconciliation is the headline deliverable of `fd74bd7`, and it is absent from every committed evidence file. There is no artifact in this PR demonstrating the mechanism BLOCKING-1 concerns. For a PR whose entire subject is the integrity of a measurement instrument, the evidence bundle is the audit record.

**Recommended fix:** recapture all four AC files at `fd74bd7`; rename `AC-002-selftest-93of93.txt` to its real count; update `evidence-report.md` and the PR body (head SHA, badge, all counts); add an AC that exercises the population reconciliation — ideally including the fail case from BLOCKING-1's fix.

---

## NIT-1 — No table-cell E-code fixture, though half the live detections are in table cells

`run-selftests.sh:5735-5769` (5k), `:5846-5852` (5l), `:5928-5938` (5m), `:6006-6010` (5n)

All four fixtures place E-codes in prose or YAML frontmatter. Three of the six live examined occurrences are inside markdown table cells (`BC-2.01.009.md:71`, `:73`, `interface-definitions.md:237`). This is the precise gap that let BLOCKING-1's mutant survive. Adding one table-cell E-code row to 5l or a new 5o would kill it independently of the reconciliation fix.

## NIT-2 — The two population buckets use different counting units

`check-adr-consistency.py:352-353` vs `:521-525`

The frontmatter bucket counts every regex match with no dedup (`for _m in E_CLASS_CODE_RE.finditer(line): frontmatter_e_skipped += 1`); the examined bucket dedupes per line via `seen_e_codes_this_line`. So a non-frontmatter line containing `E-IO-002` twice contributes 1, while a frontmatter line containing it twice contributes 2. `population` therefore isn't a consistent unit of measure. It reconciles with a raw corpus grep (8) today only because no non-frontmatter line repeats a code — `BC-2.01.009.md:23` carries two *distinct* codes. Pick one unit and apply it to both buckets (and to the independent probe in BLOCKING-1's fix).

## NIT-3 — The summary line omits the skip count

`check-adr-consistency.py:663-678`

Answering the review question directly: the frontmatter skip **is** genuinely disclosed — but only on a separate line printed earlier, and `Check passed: ... = 134 of 134 spec files (complete), 0 non-conforming` never mentions it. A corpus with E-codes only in frontmatter exits 0 with that line, which a human or CI annotation grepping the summary would read as "nothing excluded". Fold `skipped=N` into both summary strings so the disclosure travels with the completeness claim.

## NIT-4 — Test 5k's `E-CLI-001` grep no longer exercises Pattern 3, but still claims to

`run-selftests.sh:5712`, `:5714`, `:5782-5784`

The AC-7 change routes E-class codes away from Pattern 3 (`check-adr-consistency.py:499-500`) to Pattern 4 (`:529`). So 5k's `grep -q "E-IO-002"` (5778) and `grep -q "E-CLI-001"` (5782) now hit the identical branch and cannot fail independently. Verified: replacing `TAXONOMY_CODE_RE` with a never-match pattern leaves 5k **PASSING**, while line 5714 asserts "All three grep assertions are necessary; dropping any one would re-open the original blind spot" and line 5783's failure message says "Pattern 3 taxonomy-reference broken".

Not a coverage hole — Pattern 3 retains genuine defect-fail coverage via tests 5b (`:5188`) and 5d (`:5304`), which use a lowercase phantom in the same prose shape; I confirmed that killing Pattern 3 flips a phantom-bearing fixture from `Check FAILED: 1 violations` to `Check passed`. But 5k is now a two-pattern calibration set wearing a three-pattern label, and the misattribution will mislead the next person reading it. Swap 5k's Pattern-3 line to a lowercase non-E-class code, or correct the comment and the failure message.

## NIT-5 — The reason-code namespace has no population reconciliation at all

`check-adr-consistency.py:351-354`

The `continue` for frontmatter drops reason-code tokens with no count — the same defect class AC-1 just fixed for the 6-occurrence E-class namespace, left open for the 79-occurrence reason-code namespace. Measured: 2 tokens dropped uncounted (`http-error`, `http-indeterminate` at `.factory/specs/domain-spec/failure-modes.md:34`). Live impact is nil — both sit in a `change:` changelog field and would not be in a reason-code position outside frontmatter either. Flagging for the D-132 nine-checker sweep, not for this PR.

## NIT-6 — Three overlapping corpus predicates, written three different ways

`check-adr-consistency.py:553` vs `:601` vs `:581-587`

`should_check_for_broad_p19` excludes all of `/architecture/decisions/`; the ADR loop globs only `ADR-*.md`; `_in_spec_corpus` counts every `.md`. A non-`ADR-`-prefixed `.md` added under `decisions/` would be scanned by neither loop. This fails loud (`return 2` at 637) rather than silently, and no such file exists today — good — but the three predicates should share one definition rather than three hand-maintained ones.

## NIT-7 — Pre-existing selftest-suite items surfaced by the sweep (no change requested here)

Reported for the record per the vacuous-guard sweep; all pre-date this PR:
- `run-selftests.sh:48` — `OVERRIDE_PATTERN` is referenced only in comments; `run_override_guard` (92-94) uses a hardcoded inline check. So the claim at lines 44-47 that mutating `OVERRIDE_PATTERN` "will flip both the pre-flight guard AND the corresponding guard selftest" is false. G1 still has teeth via the inline check; the documented coupling is what's wrong.
- `:1436`, `:1507` (tests 23, 24) — assert on a bare `grep -q "FAIL"` against combined stdout+stderr. Sound today (only one FAIL emitter each) but pins no reason; `--check: FAIL` would be tighter.
- `:1665` (test 26) — `grep -q "BI-041"` is emitted by three distinct refusal paths (`gen-bc-traceability.py:272`, `:303`, `:339`), so it proves only that *some* BI-041 refusal fired.
- `:2958-2977` (D-069 property test) — both arms run the same code path with different case counts; no defect is injected, yet it consumes a `TESTS_RUN` slot and satisfies the `TESTS_WITH_CLEAN_PASS == TESTS_RUN` guard at `:6268`.

---

## FOCUS 3 — Vacuous-guard sweep result

**The EI-4 repair is sound.** `run-selftests.sh:4958` now uses `grep -qE "[1-9][0-9]* TV rows skipped"`, and the zero branch emits `no TV rows skipped` (`check-ec-injectivity.py:674`) rather than `0 TV rows skipped` — lexically distinguishable, so the guard cannot pass on a zero-skip run.

I swept all 6,283 lines: 96 tests / 192 assertion arms / 36 grep predicates against checker output, each cross-referenced to the `print()` that produces the matched text, and each checker run against a zero-result tree to confirm the actual zero-run string rather than reasoning from source. **No remaining strictly-vacuous instance of the EI-4 class.** EI-4 was the only one that ever existed.

Three prefix-looseness cases are sound but imprecise — none can match a zero run, and each fixture can only produce the value 1:
- `:4866` `"1 require adjudication"` also matches `11` / `21` / `101 require adjudication`
- `:6222` `"1 EC citation"` also matches `11` / `21 EC citations`
- `:5917` `"skipped=1"` also matches `skipped=10`…`19`, `skipped=100`

Anchoring (e.g. `-qE '(^|[^0-9])1 require adjudication'`) would make them exact. No change required.

Worth recording as a standing hazard: **every count phrase these checkers emit is a latent vacuity trap**, because all are printed unconditionally with a literal `0`. Confirmed by running a zero-result tree — bare greps for `TV rows skipped`, `reason-code occurrences`, `E-class code`, `EC citations compared`, `skipped=`, `require adjudication`, `divergent`, and `non-conforming` all match a zero run. The 36 existing assertions correctly avoid the trap in every case; the comment at `:4907-4912` is the right precedent and is worth generalising so the class doesn't reopen.

---

## Verified clean — what I checked and found correct

Stating these explicitly rather than implying them by omission.

**FOCUS 2, item 1 — ADR routing dropped nothing.** `check_adr()` is **byte-identical** between `da86271` and `fd74bd7` (extracted by AST boundary and compared, not eyeballed). The ADR loop calls `check_broad_corpus()` *in addition*, never instead. No ADR takes a path through `main()` that bypasses a check: both loops run, `total_corpus` is computed independently of routing, and a mismatch exits 2 loudly (637). The base→head violation diff is a **pure superset**: 4 → 9, with `BC-2.11.004.md:61` `E-CLI-001` correctly *reclassified* from `taxonomy reference` (validated against the reason-code registry — wrong registry) to `E-class code` (right registry). Nothing was lost.

**FOCUS 2, item 3 — the Pattern-3/Pattern-4 dedup fix is correct.** Separate `seen_e_codes_this_line` prevents shadowing, and there is no double-counting: `E-CLI-001` in `(consistent with … taxonomy)` shape is counted exactly once as an E-class occurrence and zero times as a reason-code occurrence. Verified on the live corpus and via fixture.

**Corpus population claim independently confirmed.** My own grep: exactly **8** raw occurrences — 6× `E-IO-002`, 2× `E-CLI-001`, across 3 files (`BC-2.01.009.md`, `BC-2.11.004.md`, `interface-definitions.md`). Reported `population=8, examined=6, skipped=2` reconciles exactly, with the 2 skips being the two distinct codes on `BC-2.01.009.md:23` (frontmatter `modified:` changelog). Every one of the 6 reported violation line numbers matches my grep.

**FOCUS 2, item 4 — 5l/5m/5n are genuinely mutation-killing** for the mutations they claim: the control mutation kills all four tests (5m via its `skipped=1` structural assertion, which is the assertion actually doing the load-bearing work for AC-1). Their gap is fixture coverage (NIT-1), not assertion strength.

**5j's grep relaxation is not a weakening.** `[1-9][0-9]* reason-code occurrences` still excludes the `0 reason-code occurrences` zero run; the `validated` token had to be dropped only because output format changed. Verified empirically, including that the bracket expression works as intended in BRE.

**96/96 selftests pass** in the real repo (`rc=0`, zero `FAIL` / `STRUCTURAL FAIL` lines), matching `EXPECTED_TEST_COUNT=96`.

**Frozen perimeter intact.** The PR touches only 5 evidence files and 3 files under `scripts/spec-lint/`. No `.factory/`, `src/`, `Cargo*`, or `.github/` changes. Confirmed by `git diff --name-only`.

**Diff size and commit quality** are fine: ~1.4k lines of which the majority is selftest fixtures and evidence; all five commits use conventional format with issue IDs.

**The `Spec lint` CI failure is correct and expected** per D-128 (advisory-only) and D-122 (oracles widen before they shrink). The four required checks — `Format check`, `Clippy (deny warnings)`, `Test (macos-latest)`, `Build release (macos-latest)` — are all green. The widened counts are the intended deliverable and I have not treated them as regressions. I confirmed the widening is real rather than an artifact: every one of the 5 new violations corresponds to an occurrence in my independent grep.

**Out-of-scope items were not raised:** the `re.fullmatch` Reason-column Branch B and its comment, the reason-column header literal check, and the other seven checkers.

---

## Summary

The two oracle repairs themselves are correct and well-evidenced: the E-code detector finds every occurrence my independent grep finds, the ADR fold is genuinely additive with `check_adr()` byte-identical, the Pattern-3/4 routing fix sends E-codes to the right registry without double-counting, and the EI-4 vacuous guard is properly closed with no remaining instances of that class anywhere in 96 tests.

What blocks merge is narrower and specific: the completeness *mechanism* added to guard the E-class namespace does not work. `assert x == x` cannot fail, and because `population` is derived from the same routing path it audits, a single plausible `continue` silently discards half the live detections while the ledger balances, the corpus still reports "complete", and all four new selftests pass. That is the BI-056 failure mode reproduced one level up, which is precisely the risk this PR set out to close. The correct pattern already exists 60 lines above in the same function — the file-count gate at 581-589 — and needs only to be mirrored for the E-class population using an independent, deliberately wider probe.

BLOCKING-2 and BLOCKING-3 are smaller: a double-count that corrupts the baseline metric this PR ships downstream, and an evidence bundle two commits stale in which the fold's headline deliverable does not appear at all.

None of the three requires touching `.factory/specs/`, and none is a content defect.
