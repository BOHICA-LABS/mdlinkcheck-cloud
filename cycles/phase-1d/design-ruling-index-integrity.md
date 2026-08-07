# Design Ruling: spec-lint Parser Architecture
**Date:** 2026-08-06
**Status:** RULING — operator decision, halts further patch-fix cycle on PR #3 pending ruling acceptance
**Scope:** `scripts/spec-lint/check-index-integrity.py` and the seven other checkers
**Triggered by:** Four consecutive review cycles failing on structurally identical defect (B-8, B-9, B-11 + BI-023 variants in check-placeholders / check-id-resolution)

---

## 1. Diagnosis: The Structural Invariant Being Violated

**Statement (precise):** The verification mechanism is placed downstream of the same pre-filter chain it is supposed to verify, so any input that defeats the pre-filter chain also defeats both the classifier and the accounting check simultaneously. The accounting invariant `hs_rows_seen == hs_canonical + hs_nonconforming` holds vacuously rather than as a genuine constraint.

This is not a bug in any individual regex. It is a structural coupling between three roles that must be structurally independent:

- **T (tokenizer):** selects which raw lines enter the processing loop
- **S (semantic classifier):** decides what category each selected line belongs to
- **A (accounting check):** verifies that every line T ought to have seen was accounted for by S

When A is computed using the same filter as T, or is computed after T's filtering runs, A cannot detect T's blind spots.

### File:line evidence — three different manifestations of the same invariant:

**B-8 (`6d954ab`, `check-index-integrity.py:350-370`):** `checks += 1` executes unconditionally outside the loop, before any row is examined. When `get_hs_ec_mapping()` returns an empty mapping (all rows dropped by the parser), both `checks` increments fire, the forward and reverse check loops execute on empty sets, and the checker exits 0 with `HS all consistent` having validated zero items. Reviewed SHA evidence: V-10 in `pr-review-6d954ab.md` — an HS-INDEX with three non-conforming rows all pointing at nonexistent files produces `Check passed: 14 structural checks — HS all consistent, EXIT=0`.

**B-9 (`1fc1bce`, `check-index-integrity.py:390`):** The fail-closed backstop's data-row detector (`re.match(r"^\|\s*[^-|]", l)`) uses the same `^\|` anchor as all four parser patterns at lines 155, 160, 166, 173. One leading space (semantically neutral in Markdown) defeats all five simultaneously. Reviewed SHA evidence: V-9 in `pr-review-1fc1bce.md` — one flush row + two indented rows, only the flush row's EC file present; `hs_validated == 1` so the fail-closed guard is never consulted; `Check passed: ... HS (1 entries) all consistent, EXIT=0` with two HS entries pointing at nonexistent scenario files.

**B-11 (`031ca5b`, `check-index-integrity.py:211`):** `hs_rows_seen += 1` is at line 211, after five `continue` pre-filters at lines 188, 190, 195, 198, and 202. Any row skipped by any pre-filter is invisible to both the parser and the denominator; the invariant `hs_rows_seen == hs_canonical + hs_nonconforming` is satisfied regardless of how many rows were silently dropped. Reviewed SHA evidence: V-1/A1 in `pr-review-031ca5b.md` — a data row positioned above the separator exits 0 printing `HS (1 validated, 0 non-conforming, 1 rows seen) all consistent`, while that same row correctly exited 1 at `1fc1bce` before the F-12 scoping fix was applied (regression confirmed by V-10 comparison).

**B-8 is the progenitor. B-9 is the same invariant in the backstop. B-11 is the same invariant in the accounting denominator.** Each fix closed one instance and opened a structurally identical one because the structural coupling was never broken.

---

## 2. Checker Audit: Which of the Eight Share the Shape

All eight checkers were audited. Results in descending severity:

### CONFIRMED — same structural failure mode as B-8/B-9/B-11

**check-index-integrity.py**
Three documented variants (B-8/B-9/B-11). Additionally: the duplicate-HS-ID check at line 494-504 re-parses the same file with `re.match(r"^\|\s*(?:~~)?(HS-\d+)(?:~~)?\s*\|", raw.strip())` — a third independent parse with no row-accounting, structurally diverged from the main parser. For BC/VP/ARCH/L2/ADR sections, functions `get_bc_index_entries()`, `get_vp_index_entries()`, `get_adr_index_entries()`, `get_arch_index_documents()`, `get_l2_index_sections()` all silently drop non-conforming rows with no accounting invariant protecting the caller.

**check-placeholders.py**
The checker searches for literal strings `VP-TBD`, `SS-TBD`, and `[filled by ...]`. Any non-standard placeholder notation (em-dash `—`, blank cell, `TBD`, `pending`, `N/A`) defeats detection entirely because detection and classification are the same mechanism. No positive-coverage count tracks "N BCs with VP assignments examined." Operator-observed consequence: 12+ BCs with zero VP coverage passed cleanly through the gate — the checker cannot distinguish "VP-TBD (flagged placeholder)" from "— (equally unassigned, unflagged)". The missing count is the D-057 dimension: `files_checked` counts files scanned, not BCs with confirmed VP assignments.

**check-id-resolution.py**
Two distinct BI-023 variants:
1. `build_table_ids()` (used by `VALID_DD`, `VALID_VP`, `VALID_NFR`, `VALID_HS`) uses `if not line.startswith("|"):` to select table rows. The same anchor applies to both building the valid-set and checking references in `check_file()`. A non-conforming valid-set row (wrong table format) silently drops the ID from the valid-set, causing false violations downstream.
2. `build_valid_ec_ids()` auto-synthesizes all EC-NNNa..z variants for any registered base. This means `EC-073b` is automatically accepted even if it never appears in test-vectors.md — the "valid" set is broader than the actual registered set. Simultaneously, non-conforming ID shapes `EC-NEW-NN` and `EC-073-b` (separator variant) are silently skipped because they don't match `r"\bEC-(\d+)([a-z]?)\b"`. Both the detection regex and the valid-set construction regex require the same digit-only ID format; any shape that deviates from that format is invisible to both.

**check-ec-injectivity.py**
`extract_ec_rows()` uses `re.match(r"^\|\s*(EC-(\d+[a-z]?))\s*\|(.+)", line)`. Non-conforming EC rows (wrong format, missing columns, em-dash cell separator) are silently dropped. `total_ec_ids` at exit reflects only what the parser captured, not the actual count of EC rows in the files. The `multi_occurrence` metric is similarly derived from the captured set. A table with 50 malformed EC rows produces the same coverage output as a table with zero rows.

### MODERATE — same structural shape, lower exploitation risk

**check-counts.py**
`count_active_holdouts()` uses `re.match(r"^\|\s*(HS-\d+)\s*\|", line)` and `"~~" not in line`. A non-standard active holdout row (e.g., partially annotated ID `HS-007 (active)`, or extra column prefix) is silently dropped from the active count, causing the declared count to appear correct when it is not. The overall check compares declared-vs-computed counts, but if the parser systematically undercounts, both sides of the comparison see the same under-count. `count_bc_index_rows()` has the same exposure for BC-INDEX rows with malformed priority fields.

**check-title-sync.py**
`parse_bc_index_rows()` uses `re.match(r"^\|\s*(BC-\d+\.\d+\.\d+)\s*\|\s*(.+?)\s*\|\s*P[012]\s*\|", line)`. A BC row with priority `P3` (out-of-range), or `P0/P1` with trailing whitespace outside the cell boundary, is silently dropped. Dropped rows are not counted or reported; the title-sync check for that BC is silently omitted. Combined with the `check-counts.py` check for P0/P1 counts, this is a lower-exploitation risk — but the structural coupling is identical.

### LOWER — structural coupling exists; mitigated by other controls

**check-holdout-boundary.py**
`parse_active_holdout_ec_ids()` reads HS-INDEX with `"~~" not in line` (coarse filter) then `re.search(r"\|\s*(EC-(\d+))\s*\|", line)`. If a holdout HS row uses a non-standard format, it won't register as a holdout, and then won't be checked in visible artifacts — a false-negative on the boundary check. Mitigated by the guard at line 103-104: `if not holdout_ids: return 2`. This guard fails closed if the pool parse returns nothing, but it cannot distinguish "legitimately empty pool" from "pool parse silently failed."

**check-adr-consistency.py**
Uses grep-style detection of *prohibited* patterns (exit code misuse, bad verdict labels, wrong reason codes). This inverted structure is less susceptible to BI-023: the checker fires when it FINDS a bad pattern, not when it FAILS to classify a pattern. A non-conforming bad pattern would cause a false negative (missed violation), not a false pass of a present violation. The `extract_closed_reason_codes()` function has the same silent-skip exposure, but reason code false negatives mean the "valid set" is smaller than it should be, which causes more violations to be reported (fail-closed direction). Lowest risk of the eight.

---

## 3. Options Table

| # | Option | Cost | What it eliminates | What it does NOT eliminate | Incremental? | Phase-1 gate impact |
|---|--------|------|--------------------|---------------------------|--------------|---------------------|
| **1** | **Separate lexing from semantics.** Tokenize every physical table row unconditionally, THEN classify. Counter increments at the tokenizer layer, before any classifier pre-filter. | 0.5–1 day per affected checker × ~6 checkers = 3–6 days. Requires adding lexer layer and bucket accounting to each checker. | BI-023 within each checker's current scope. Delivers D-057 positive-coverage counts as a structural property, not a bolt-on. | Risk of future regression: a subsequent fix can move the counter back inside the classifier loop; the defect class re-emerges at the next fix. Convention-dependent unless a meta-test (test-count invariant) enforces it. | Yes, per checker. | Strengthens to reliable for all eight checkers. Removes the specific false-pass class documented in B-8/B-9/B-11. |
| **2** | **Keep regex, add architectural rule.** "Count physical rows before any continue", enforced by a meta-test in `run-selftests.sh`. | 1 day: write the meta-test and propagate the counter convention to all affected checkers. | Nothing structural. Raises the cost of violating the convention. | The defect class itself. Convention has already been violated across four consecutive fix cycles. A future fix under context pressure will violate it again; the meta-test catches the regression only after it ships. | Yes. | No improvement in reliability over current state; meta-test catches regression post-hoc but does not prevent the class. |
| **3** | **Generate the indices from source-of-truth.** For checkers that validate machine-maintained indices, run generators from BI-012 (`gen-bc-index.py`, `gen-rtm.py`, `gen-prd-sections.py`) in CI before checkers. HS-INDEX: add a generator that materialises it from `wave-scenarios/` metadata. | 2–4 days: land generators from BI-012 branch (already written), wire into CI, write one new generator for HS-INDEX, add the GENERATED:BEGIN/END markers to relevant files. | The entire parse-fidelity defect class for generated indices: there is no parser for the checker to mis-trust. Eliminates check-index-integrity (BC/VP/ADR/ARCH/L2 sections), check-title-sync, check-counts (BC/VP/RTM rows), most of check-index-integrity HS section. | Human-authored content checkers: check-placeholders, check-holdout-boundary, check-adr-consistency, check-id-resolution still need lexer-first restructuring (Option 1) for the content they validate. The BI-012 generators do not cover semantic validation of authored prose. | Yes, per generator. Each generator replaces one checker's parse-verify loop without touching others. | Strongest for Phase-1 gate: generated content cannot drift from source-of-truth. Makes the gate genuinely REQUIRED-safe. |
| **4** | **Structured intermediate format.** Index data in YAML/TOML as primary source; Markdown tables rendered from it. Machine-readable form is primary, table is a view. | 2+ weeks. Requires rewriting authoring workflow, all existing BC/VP/ADR files, and all editing tooling. Disrupts every contributor workflow. canonical-facts.toml is this approach applied to selected facts (already exists). | Same as Option 3 for all structured data. Canonical-facts.toml already delivers this for VSDD-maintained facts. | Author UX disruption for free-form documents (BCs, ADRs). Phase-3 has not started; doing this now means Phase-3 implementation team inherits a different authoring workflow. | No — requires system-level change before any checker can be updated. | Strongest long-term; impractical for this phase. |

---

## 4. Ruling

**Rule: Option 3 (generation) for index-derived checkers, combined with Option 1 (lexer-first restructuring) for the checkers that must validate human-authored content. These are complementary, not competing. Option 2 is rejected. Option 4 is deferred.**

### Reasoning

**Reject Option 2 unconditionally.** The convention has been violated across four consecutive fix cycles by competent contributors working under review. A meta-test enforcing the convention is better than nothing, but the defect class re-emerges at every future fix under context pressure. Four data points are sufficient evidence that a convention does not survive the environment. The operator has already noted this correctly.

**Option 1 alone is necessary but not sufficient.** Lexer-first restructuring correctly isolates the tokenizer from the classifier. It eliminates the immediate BI-023 class. But it remains a structural pattern, not a structural constraint: a future contributor who adds a pre-filter above the counter will silently re-introduce the defect. D-040 requires negative tests proving each violation path can fire; those tests mitigate but do not fully prevent regression to the same pattern. This is the correct fix for checkers that have no generator alternative.

**Option 3 eliminates the defect class by construction for generated content.** The BI-012 generators (`gen-bc-index.py`, `gen-rtm.py`, `gen-prd-sections.py`, `gen-bc-traceability.py`) already exist on branch `feature/bi-012-generators`. They implement the correct structural fix: BC-INDEX, VP-INDEX frontmatter counts, PRD §2 title table, RTM section, and Architecture Module rows are regenerated from ground truth before CI runs. A checker validating a just-generated index cannot fail due to parser blind spots because the index IS the parser's input and was just materialized by a deterministic generator. The BI-023 class evaporates for any data path that goes through a generator.

The HS-INDEX case requires one new generator (not yet on BI-012), but it follows the same pattern: HS-INDEX should be materialized from the `wave-scenarios/` directory listing, making the bidirectional check structural rather than parse-dependent.

**The Phase-1 gate consideration is decisive.** The spec-lint CI job is currently ADVISORY (D-029/D-032) and is meant to become a REQUIRED status check at Phase 1 approval. Four consecutive blocking findings mean the gate cannot be made REQUIRED while parse-fidelity bugs remain. Option 3 makes the gate REQUIRED-safe for generated content: the gate checks that the generator was run (via GENERATED:BEGIN/END marker freshness) and that generated content matches source. That is a structurally sound REQUIRED check.

**Phase-3 timing amplifies the urgency.** Phase 3 (Rust workspace) has not started. A structural fix now costs 2–4 days against a clean slate. Post-Phase-3, the same fix requires updating CI pipelines that also build Rust crates, regression-testing against a complete implementation, and synchronizing across any multi-repo topology. Option 3 is far cheaper today.

**What would change this ruling:**
- If the BI-012 generators are discovered to have correctness bugs of their own (they introduce false confidence in a broken index). This must be verified before landing — run the generators on the current tree and confirm `git diff --stat` shows only generated-region changes.
- If the generator CI integration requires touching `.factory/specs/` files that another concurrent agent is actively editing (constraint noted: another agent is editing `.factory/specs/` and `canonical-facts.toml`). In that case, the landing of Option 3 must be sequenced after that agent completes.

---

## 5. PR #3 Recommendation

**Land PR #3 with the B-11 stopgap as described in `pr-review-031ca5b.md`. Do not expand its scope.**

The B-11 fix (move `hs_rows_seen += 1` above the five `continue` pre-filters; add explicit `if not first_cell:` branch rather than relying on `set(first_cell) <= set("-: ")` being True for the empty string; add three new selftests covering the A1 regression and the A2a/A2b blank/dash-ID cases) is the correct local fix for the specific invariant violation in the current HS-INDEX parser. It closes the regression (A1) and two pre-existing gaps (A2a/A2b) with the minimum surface area. It does not require understanding or touching the generator infrastructure.

**Do not add the generator integration to PR #3.** Adding Option 3 to PR #3 would expand its scope to include BI-012 generator landing, CI rewiring, and HS-INDEX generator authoring — a scope change that could introduce new regressions and would require another full review cycle. PR #3's scope is already `fix(spec-lint)`; keeping it narrowly focused allows it to merge cleanly.

**Track Option 3 as a dedicated follow-on story.** Recommended story title: `feat(spec-lint): replace parse-verify loops with generation for machine-maintained indices (BI-012)`. It should reference this ruling, the BI-012 generators branch, and the requirement to write one new generator for HS-INDEX. It should also track the Option 1 lexer-first restructuring for the remaining human-authored-content checkers (check-placeholders, check-id-resolution, check-ec-injectivity) as a second story: `fix(spec-lint): lexer-first restructuring for human-authored-content checkers (BI-023 hardening)`.

**Additional PR #3 items from the review (do not skip):**
- Fix the PR description (F-17): update test count to 21/21, replace `get_hs_ec_mapping()` with `get_hs_data()`, tick test-plan checkboxes.
- Add the F-18 clean-pass test pinning the F-12 section-scoping fix (minor but prevents MUT-E from being undetected).
- Correct the docstring at `:142-147` and comment at `:450-452` to match what the code actually guarantees after the B-11 fix.

---

## Appendix A: Affected Checker Disposition Summary

| Checker | BI-023 severity | Option 3 applies? | Option 1 needed? | Notes |
|---------|----------------|-------------------|--------------------|-------|
| check-index-integrity.py | CONFIRMED (3 variants) | YES — BC/VP/ADR/ARCH/L2 sections replaced by generators; HS section replaced by HS-INDEX generator | YES — until Option 3 lands; also for duplicate-ID re-parse at :494-504 | Highest priority |
| check-placeholders.py | CONFIRMED | NO — content is human-authored | YES — add positive-coverage count: N BCs checked, N with valid VP assignments | Em-dash bypass affects 12+ BCs |
| check-id-resolution.py | CONFIRMED (2 variants) | PARTIAL — VALID_EC generation can be replaced by strict table-row scan | YES — fix non-conforming ID silent-skip; replace auto-synthesis with strict lookup | Also fix EC-NNNa..z over-generation |
| check-ec-injectivity.py | CONFIRMED | NO — semantic validation of human-authored EC rows | YES — add row accounting to extract_ec_rows(); count dropped rows | |
| check-counts.py | MODERATE | YES — most counts become structural via generators | YES for count_active_holdouts() | Lower urgency |
| check-title-sync.py | MODERATE | YES — title sync is structural if BC-INDEX generated from BC files | Not needed if generator applied | |
| check-holdout-boundary.py | LOWER | PARTIAL — holdout pool read from prd.md §5b; pool-empty guard mitigates | LOW | Existing fail-closed guard reduces risk |
| check-adr-consistency.py | LOWEST | NO | LOW | Inverted structure (grep for bad) is inherently less susceptible |

---

## Appendix B: BI-021 / SPEC_LINT_REPO_OVERRIDE

The constraint noted in the task (BI-021: `check-canonical-facts.py` resolves `.factory/` from its own script location and exits 1 from a `.worktrees/` path; `SPEC_LINT_REPO_OVERRIDE` is the intended fix) applies to the generator/checker integration: when landing Option 3, every generator and `check-canonical-facts.py` must consistently use `SPEC_LINT_REPO_OVERRIDE` for path resolution. The BI-012 generators already use this pattern (`REPO = Path(os.environ.get("SPEC_LINT_REPO_OVERRIDE", "")).resolve() if ...`) — verify before landing.

---

## Appendix C: Placeholder Tolerance (25 Outstanding [filled by story-writer])

The 25 `[filled by story-writer]` placeholders legitimately outstanding until Phase 2 are currently tolerated by the gate being ADVISORY. Under Option 3, when the gate becomes REQUIRED, these must be handled without suppression (D-039). The correct mechanism is a YAML-configured "expected placeholder count" field in a manifest (not a skip-list), compared against the actual count: if the runtime count matches the expected count exactly, the check passes with a warning; if it exceeds the expected count, it fails. This gives D-057 positive-coverage semantics without a D-039 allowlist.
