---
document_type: audit-report
audit_id: WS-3
commit: 7b9aa6d
branch: develop
date: 2026-08-07
auditor: devops-engineer
scope: BI-034 skip-list re-audit + BI-023 reproductions + Part 3 sweep
governing_decisions: D-050, D-057, D-060, D-039, D-040
---

# WS-3: Pass-6 Skip-List Positive-Coverage Re-Audit

## Verdict Table

| Checker | Positive-coverage count output | Item can silently escape | Neg-test drives production pattern | Skip-list verdict |
|---------|-------------------------------|--------------------------|-------------------------------------|-------------------|
| `check-counts.py` | YES — "37 count checks passed" | PARTIAL — optional checks gated on pattern match; HS-INDEX claimed but unimplemented (dead code) | Only `total_bcs` mismatch is tested; 13 other check paths untested | **KEEP** (with caveats — see §1.1) |
| `check-adr-consistency.py` | YES — "8 ADRs checked" | MINOR — reason-code keyword gate (precision miss, not coverage miss) | YES for tested path; dns/tls and reason-code paths have no selftest | **KEEP** |
| `check-title-sync.py` | YES — "66 BC titles validated" | NO — setext headings produce false-positive violation, not silent pass | YES — test drives production `startswith("# ")` pattern | **KEEP** |

---

## Part 1 — Per-Checker Analysis

### 1.1 check-counts.py

**Runs:** `SPEC_LINT_REPO_OVERRIDE=/path python3 check-counts.py` → `Check passed: 37 count checks passed`

**Q1 — Positive-coverage count?**
YES. The success message reports how many checks actually ran. At runtime on `develop@7b9aa6d`: 37 checks.

**Q2 — Can an item silently escape?**

Path enumeration table:

| Recognition gate | Line | Failure direction | Item counted? |
|-----------------|------|-------------------|---------------|
| `declared_total is not None` (BC total_bcs check) | 215 | Skips check if frontmatter absent | No, but no check is claimed either |
| `re.search(r"P0\s*=\s*(\d+)", ...)` (P0 summary block) | 229 | Skips P0 check if no summary block | No; acceptable — gated on claim |
| `if m:` for DD count in L2-INDEX | 331 | Skips DD count check if pattern absent | No; acceptable — gated on declared value |
| `if vcm_totals_m:` (VCM Totals row) | 356 | Skips VCM check if pattern absent | No; acceptable — gated on presence |
| `if ec_count_m:` (EC count claim in prd.md) | 379 | Skips EC check if prd.md has no EC count claim | No; acceptable |
| **HS-INDEX check** | **docstring line 15** | **CHECK IS NEVER CALLED** — `count_active_holdouts()` is dead code | **YES — claimed but absent** |

**Dead code finding (the main lead):**

Three functions are defined but never called in `main()`:
- `count_domain_decisions()` (line 179)
- `count_active_holdouts()` (line 168)
- `count_policies()` (line 190)

Verified by AST inspection:
```
Dead functions (defined but never called): count_active_holdouts, count_domain_decisions, count_policies
```

**Lead refutation — `count_domain_decisions()` at line 185:**

The lead states: "A decision recorded in any third form would be silently excluded from the count." This is TRUE of the dead function, but IRRELEVANT to production.

The PRODUCTION DD count is inline in `main()` at lines 337–341:
```python
dd_m = re.match(r"^\|\s*(DD-\d+)\s*\|", line)
```
This correctly matches actual table rows.

Concrete verification: the dead function finds **6 IDs** (heading-formatted only); the production inline count finds **27 IDs** (table rows). If the dead function were called with L2-INDEX declaring 27, it would produce a FALSE POSITIVE violation (6 ≠ 27), not a silent agreement. The lead is **REFUTED for production impact** — the dead function is never called.

**HS-INDEX gap:** The module docstring line 15 says the checker validates "HS-INDEX.md: active holdout count vs declared." `count_active_holdouts()` exists but is NEVER called in `main()`. The 37 checks-passed message does NOT include an HS-INDEX check, despite the docstring claim. This is a documentation-vs-implementation gap.

**Q3 — Does its negative test drive the production pattern?**

Selftest 2 tests ONLY `total_bcs` frontmatter mismatch. Production has 14+ distinct check paths. The following have no selftest: DD count, VP frontmatter fields, VP method-sum invariant, VP phase-sum invariant, module VP counts, PRD RTM row count, VCM column totals, EC count claim, worked-examples count, §4 range check.

The tested path (total_bcs check) correctly uses the production pattern. Not a BI-042 concern for the one tested path. The untested paths are a coverage gap, not a BI-042 synthetic stand-in.

**Skip-list verdict: KEEP** — the core counting logic is sound and correct production paths have proper recognition gates. Issues are latent defects (dead code) and coverage gaps (no selftests for 13+ check paths), not active bypasses. The HS-INDEX gap is a separate remediation item.

---

### 1.2 check-adr-consistency.py

**Runs:** `SPEC_LINT_REPO_OVERRIDE=/path python3 check-adr-consistency.py` → `Check passed: 8 ADRs checked — all exit codes and reason codes consistent with error-taxonomy.md`

**Q1 — Positive-coverage count?**
YES. "8 ADRs checked" is in the output. Current ADR count on disk matches: 8 ADR files.

**Q2 — Can an item silently escape?**

Path enumeration table:

| Recognition gate | Line | Failure direction |
|-----------------|------|-------------------|
| `ADR_DIR.glob("ADR-*.md")` | 156 | Any ADR file NOT named `ADR-*.md` is invisible; currently all 8 are correctly named |
| `if any(kw in context for kw in ("reason", "verdict", "broken", "exit")):` | 132 | Reason-code misuse on a line without these keywords is silently skipped |
| `-` in code and code not in exclusion set | 122 | Multi-segment codes are filtered; this is intentional |

The keyword gate at line 132 is a PRECISION miss, not a COVERAGE miss. The ADR is always fully counted in `adrs_checked`; only a specific reason-code misuse pattern could be missed within an ADR. An ADR that misuses a reason code in a line that does not contain the words "reason", "verdict", "broken", or "exit" would pass clean for that specific misuse.

Concrete example of the miss: if an ADR says `The result code is 'http-timeout'` (misusing reason code as a verdict label), and the line contains neither "reason" nor "verdict" nor "broken" nor "exit", the misuse is not flagged.

This is a TOLERABLE gap: the checker still counts all 8 ADRs and reports on them; the keyword gate only affects detection depth within each ADR.

**Q3 — Does its negative test drive the production pattern?**

Selftest 5 fixture (`bad-adr-exit-code.md`) contains: "the checker should return exit 2 for broken link outcomes to signal severity."

Production pattern 2: `re.compile(r"exit\s+(?:code\s+)?2[^.]*broken link", re.IGNORECASE)` — matches "exit 2 for broken link."

The test drives the production regex. Not a BI-042 concern.

Missing selftests: the dns/tls misclassification check (`_dns_tls_indeterminate()`) and the reason-code check (lines 121–136) have no dedicated selftests. These two check categories are exercised on the real spec tree when the checker runs, but there is no isolated negative-test proof they can fail.

**Skip-list verdict: KEEP**

---

### 1.3 check-title-sync.py

**Runs:** `SPEC_LINT_REPO_OVERRIDE=/path python3 check-title-sync.py` → `Check passed: 66 BC titles validated (BC-INDEX + prd.md §2 all match H1)`

**Q1 — Positive-coverage count?**
YES. "66 BC titles validated" is the success message. Note: `checked` increments only after confirming a BC file exists AND has an H1. Items with missing files or missing H1 are reported as violations (not counted as validated). The denominator (items seen) is `len(all_bc_ids)` = 66 total; `checked` = 66 only when all pass. This is acceptable — violations are never silently absorbed.

**Q2 — Can an item silently escape?**

Path enumeration table:

| Recognition gate | Line | Failure direction |
|-----------------|------|-------------------|
| `bc_index_rows.keys()` drives iteration | 108 | BCs on disk but not in BC-INDEX are invisible to this checker; caught by check-index-integrity |
| `line.startswith("# ")` in `get_bc_h1()` | 38 | **Setext headings not recognized → "no H1" violation, NOT silent pass** |
| `find_bc_file()` file existence | 82 | Missing file → violation reported at line 113 |

**Lead confirmation — `startswith("# ")` is safe:**

The `startswith("# ")` (with trailing space) is CORRECT. It matches only H1 ATX headings, preventing false matches on `##`, `###`, etc. The 10 bypasses found in `check-index-integrity.py` this session came from `startswith("#")` (without space). The trailing space makes this safe.

**Setext heading test (reproduced):** A BC file with a setext-form H1 (`Title\n=====`) triggers:
```
BC-2.01.001 has no H1 heading after frontmatter
Check FAILED: 1 title-sync violations found (0 BCs checked)
```
Direction of failure: toward visibility (false-positive violation), NOT toward silent pass. A setext heading causes the checker to FAIL loudly, not silently accept. This is the correct fail-toward-counting direction.

In practice: all 66 current BC files use ATX H1 format (`# BC-...:`), so setext headings are not present in the live tree.

**Q3 — Does its negative test drive the production pattern?**

Selftest 9 uses `# BC-2.01.001: Wrong Title That Differs From Index` — standard ATX format. The production `get_bc_h1()` uses `line.startswith("# ")`. These are aligned. Not a BI-042 concern.

**Skip-list verdict: KEEP**

---

## Part 2 — BI-023 Reproductions

### 2.1 BI-023(a): check-placeholders defeated by em-dash `—`

**Status: REPRODUCED on develop@7b9aa6d**

**Quantification (current, as of audit):**

```
BCs with em-dash (—) in VP-NNN column: 34
Total VP table rows with em-dash in VP column: 55
```

Complete list of affected BC files (34):
BC-2.01.001, BC-2.01.002, BC-2.01.005, BC-2.01.006, BC-2.01.007, BC-2.01.008, BC-2.02.001, BC-2.02.002, BC-2.02.003, BC-2.02.004, BC-2.03.003, BC-2.03.004, BC-2.03.005, BC-2.03.006, BC-2.07.002, BC-2.07.005, BC-2.07.006, BC-2.09.001, BC-2.10.001, BC-2.10.002, BC-2.10.003, BC-2.10.004, BC-2.10.007, BC-2.10.008, BC-2.10.009, BC-2.10.010, BC-2.11.003, BC-2.11.004, BC-2.12.002, BC-2.12.003, BC-2.12.004, BC-2.12.005, BC-2.13.002, BC-2.14.004

**Bypass mechanism:** `check-placeholders.py` detects VP-TBD, SS-TBD, and `[filled by ...]` placeholder strings. An em-dash `—` (U+2014) in the VP-NNN column is semantically equivalent to "no VP assigned" (a Phase 1b placeholder state) but does not match any of the three detection patterns. A BC with `| — | Property | test method |` in its Verification Properties table passes check-placeholders cleanly.

**Concrete reproduction:**
```bash
# minimal BC with em-dash in VP column → exits 0
T=$(mktemp -d); mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"
cat > "$T/.factory/specs/behavioral-contracts/ss-01/BC-TEST.md" <<'EOF'
---
bc_id: BC-TEST
---
## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| — | Some property | unit test |
EOF
SPEC_LINT_REPO_OVERRIDE="$T" python3 scripts/spec-lint/check-placeholders.py
# Output: Check passed: 1 spec files checked — no VP-TBD, SS-TBD, [filled by], or test-sufficient placeholders
```

**Distinction from known-advisory placeholders:** check-placeholders currently exits 1 on 25 occurrences of `[filled by story-writer]` across 133 files. Those 25 are known-advisory (story-writer has pending work). The em-dash bypass is a different defect class — BCs that USE `—` as a permanent "no VP" marker rather than an explicit placeholder string. The 25 advisory and 34 em-dash-affected BCs are distinct sets.

---

### 2.2 BI-023(b): check-id-resolution skips non-conforming EC shapes

**Status: REPRODUCED on develop@7b9aa6d**

**Bypass mechanism:** Production regex at `check_file()` line 323:
```python
for m in re.finditer(r"\bEC-(\d+)([a-z]?)\b", line):
```
This pattern requires digits immediately after `EC-`. Any EC-prefixed string with non-digit characters is completely invisible to the checker.

**Confirmed by running check-id-resolution on tree with non-conforming shapes:** `Check passed: 134 files checked — all ID references resolve` — despite 9 live table rows with EC-NEW shapes and 14 changelog entries with EC-collision.

**Non-conforming shapes in live spec tree (complete enumeration):**

*Live table rows (high severity — unregistered edge cases with concrete inputs/outputs):*

| Shape | File | Line | Content summary |
|-------|------|------|----------------|
| EC-NEW-1 | BC-2.07.006.md | 70 | `[x](assets/logo.png#anchor)` exists → clean (image file) |
| EC-NEW-2 | BC-2.07.006.md | 71 | `[x](scripts/build.sh)` not exist → broken |
| EC-NEW-10 | BC-2.11.004.md | 64 | `--ignore '[abc'` unclosed bracket → Exit 2 |
| EC-NEW-11 | BC-2.11.004.md | 65 | `--ignore 'valid/**' --ignore '[bad'` → Exit 2 |
| EC-NEW-12 | BC-2.12.005.md | 64 | 0 broken → stdout empty; stderr: "No broken links found." |
| EC-NEW-13 | BC-2.12.005.md | 65 | 2 broken → stdout: 2 finding lines; stderr: summary |
| EC-NEW-14 | BC-2.14.004.md | 62 | `mdlinkcheck --help` → Exit 0; help text |
| EC-NEW-15 | BC-2.14.004.md | 63 | `mdlinkcheck --version` → Exit 0 |
| EC-NEW-16 | BC-2.14.004.md | 64 | `mdlinkcheck . --version` → Exit 0; --version priority |

9 live table rows in 4 BC files. All are unregistered edge cases (not in test-vectors.md, not in the EC registry).

*Prose/changelog only (lower severity):*

| Shape | Occurrences | Context |
|-------|-------------|---------|
| EC-collision | 14 in 14 BC files | Changelog entries recording historical EC ID renaming events |
| EC-NEW-1/2 | 1 in BC-2.07.006.md:23 | Changelog entry (v1.1 typo fix note) |
| EC-NEW-3 | 2 (BC-2.07.005.md:24, prd.md:721) | Both in prose: one changelog, one "EC-164 assigned" note |
| EC-NNN | 2 in decisions.md + test-vectors.md | Template notation in table headers |
| EC-NNNs | 2 in test-vectors.md + prd.md | Template plural notation |
| EC-ID | 2 in edge-cases.md + test-vectors.md | Column header markers |

**`build_heading_ids()` at line 60 assessment:**

The function uses `line.startswith("#")` (no trailing space). This is used to BUILD the VALID_CAP and VALID_DI registries, not to check references against them. Since CAP and DI entries are defined as H2 headings (`## CAP-NNN:`, `## DI-NNN:`), `startswith("#")` correctly captures them (H2 lines start with `#`). The failure direction is INCLUSIVE (captures H2, H3, etc.), not exclusive. This is NOT a bypass — it over-includes rather than under-includes, and would only cause false-positive violations if an invalid ID were extracted. **The `build_heading_ids()` concern from the audit prompt is NOT confirmed as a bypass.**

**BI-023 Three-Part Remedy Specification:**

*Part 1 — Narrow the skip to conforming shapes (require EC-NNN numeric format):*
What changes: add a scan in `check_file()` that flags any EC-prefixed reference that DOES NOT match `\bEC-(\d+)([a-z]?)\b`. The new scan would use a broader pattern `\bEC-[^\s,|)\]"']+` and check whether each match conforms. Non-conforming shapes would be reported as violations.
Negative test to prove: inject a BC file with `EC-NEW-1` in an edge-case table; confirm check-id-resolution exits 1 with "non-conforming EC reference shape 'EC-NEW-1'".

*Part 2 — Require a positive-coverage count for EC references:*
What changes: add an `ec_refs_checked` counter in `check_file()` that increments for each EC reference found. Success message changes from "N files checked" to "N files checked (M EC references resolved, P non-conforming shapes)" — a runtime figure proving the checker examined the population it claims to cover.
Negative test to prove: run on a file with 3 registered EC references; verify the success message shows exactly 3 EC references resolved.

*Part 3 — Add meta-check for non-conforming shapes (dedicated checker or sub-check):*
What changes: either extend check-id-resolution or add `check-nonconforming-ids.py` that specifically finds all `EC-NEW-N`, `EC-collision`, and other non-standard patterns. Reports each with file:line and instructs assignee to register the ID in test-vectors.md or convert to a placeholder.
Negative test to prove: run on a tree with only `EC-NEW-1` in a live table row; verify exit 1 with identification of the non-conforming shape.

---

## Part 3 — Sweep: Remaining Checkers

### 3.1 check-ec-injectivity.py

**NEW FINDING — same root cause as BI-023(b):**

`extract_ec_rows()` at line 114:
```python
m = re.match(r"^\|\s*(EC-(\d+[a-z]?))\s*\|(.+)", line)
```
Only conforming EC shapes (digits + optional letter) are extracted. `EC-NEW-1` and `EC-NEW-2` in BC-2.07.006.md edge-case tables are **invisible to check-ec-injectivity**.

Concrete reproduction:
```bash
# BC with EC-NEW-1 edge case row → checker exits 0 (does not flag)
SPEC_LINT_REPO_OVERRIDE="$T" python3 scripts/spec-lint/check-ec-injectivity.py
# Output: Check passed: 1 EC IDs validated — all injective (1 appear in multiple files but are consistent)
# EC-NEW-1 is NOT counted in the population
```

The positive-coverage count (`total_ec_ids`) counts only conforming shapes seen. EC-NEW-N shapes are not in the denominator at all.

Not in the BI-040 family (splitlines/strip normalization). This is the same EC-recognition-gate defect as BI-023(b), manifesting in a second checker.

### 3.2 check-holdout-boundary.py

**No new bypasses found outside documented BI-040 family.**

The `bare_holdout_pattern` and `sub_letter_pattern` are built from numeric holdout IDs. Non-conforming shapes (EC-NEW-N) are not in the holdout pool, so this is not a bypass concern. The `should_check_file()` exclusion of holdout-scenarios and cycles is correct and intentional. Positive-coverage count present: "N visible artifact files checked".

### 3.3 check-canonical-facts.py

**No bypasses found.**

Every binding in canonical-facts.toml is always checked; no recognition predicate can make a binding invisible. The FAIL-CLOSED design (`_find_repo_root()` returning None → exit 1) prevents silent false-passes. Positive-coverage count present: "all N bindings match canonical values (M facts)".

### 3.4 check-index-integrity.py

**No new bypasses found outside the documented BI-040 family.**

The checker was hardened this session. The `_is_column_header()` function is explicitly documented as fail-toward-counting. The conservation law (every non-blank line is accounted for in exactly one bucket) is asserted internally. The BI-040 known-open family (splitlines treating `\f`/`\v` as line boundaries; strip removing NBSP/U+3000) is the only documented residual.

---

## Prioritized Remediation List

### Priority 1 (highest leverage): Register EC-NEW-N live table rows in test-vectors.md

**What:** 9 live table rows across 4 BC files (BC-2.07.006, BC-2.11.004, BC-2.12.005, BC-2.14.004) contain concrete edge-case scenarios with EC-NEW-N IDs that are not in the EC registry. They are undetected by check-id-resolution, check-ec-injectivity, AND check-holdout-boundary.

**Scope:** 4 BC files. Each `EC-NEW-N` must be assigned a real registered EC-NNN and entered in test-vectors.md.

**Why first:** Directly opens execution blind spots — 9 edge cases have no test vector registration and thus no VP linkage. Also unblocks Part 2 of the BI-023(b) remedy.

---

### Priority 2: Repair check-placeholders to detect em-dash VP gaps (BI-023a)

**What:** Add detection for `| — |` in the VP-NNN column position of a Verification Properties table (first cell of a data row is a bare em-dash). These 34 BCs have zero VP coverage and pass check-placeholders cleanly.

**Scope:** 1 checker file (`check-placeholders.py`). Add a pattern like `re.compile(r"^\|\s*—\s*\|")` alongside `TEST_SUFFICIENT_IN_VP_COL`. Requires a new negative selftest.

**Why second:** 34 BCs with zero VP coverage is a significant specification completeness gap. This is a simple, surgical change to one checker.

---

### Priority 3: Add non-conforming EC shape detection to check-id-resolution (BI-023b Part 1+3)

**What:** Add a second scan pass in `check_file()` that flags EC-prefixed strings not matching `\bEC-(\d+)([a-z]?)\b`. This catches EC-NEW-N, EC-collision, and any other non-standard shapes in spec files.

**Scope:** 1 checker file (`check-id-resolution.py`). Once implemented, the 9 live table rows from Priority 1 (EC-NEW-1/2/10–16) will immediately fail the check, driving registration.

**Why third:** Mechanically closes the BI-023(b) bypass. Combined with Priority 1 (register the IDs), this completes the BI-023(b) remedy.

---

### Priority 4: Implement HS-INDEX check in check-counts.py

**What:** The module docstring claims check-counts validates "HS-INDEX.md: active holdout count vs declared." `count_active_holdouts()` is dead code; no HS-INDEX check exists in `main()`. Either implement the check or remove the claim from the docstring and remove the dead function.

**Scope:** `check-counts.py`. If implementing: wire `count_active_holdouts()` into main() with a declared-count comparison; add a selftest. If removing: delete `count_active_holdouts()`, `count_domain_decisions()` (also dead), and update the docstring.

**Why fourth:** HS-INDEX drift is partially covered by check-index-integrity, but the count-vs-declared validation is unimplemented. Lower urgency than the EC bypass issues.

---

### Priority 5: Add selftests for check-counts non-total_bcs paths

**What:** 13+ distinct check paths in check-counts.py have no selftest: DD count, VP frontmatter fields (9), VP arithmetic invariants (2), VCM column totals, EC count claim, worked-examples count, §4 range check. Each needs a clean-pass + defect-fail pair.

**Scope:** `run-selftests.sh`. Estimate 5–8 new tests covering the highest-risk paths (VP arithmetic invariants, DD count, VCM totals).

**Why fifth:** Without selftests, mutations to these paths produce no regression signal. However, since the production code is correct and actively running on the spec tree, this is a test-coverage gap rather than a live bypass.

---

### Priority 6: Add selftests for check-adr-consistency dns/tls and reason-code paths

**What:** Two of three defect categories in check-adr-consistency.py (`_dns_tls_indeterminate()` and the reason-code check at lines 121–136) have no dedicated selftest. Add a selftest for each.

**Scope:** `run-selftests.sh` + two new fixture files.

---

## What Could Not Be Determined

1. **Whether EC-NEW-1/2/10–16 have assigned EC-NNN IDs that just need to be back-filled in the files.** The BC files show `EC-NEW-N` in live tables, but there is no cross-reference in test-vectors.md or prd.md to assigned numbers. Auditing the assignment history (via prd.md changelog or git log) was out of scope for this read-only pass.

2. **Whether the keyword gate in check-adr-consistency reason-code check (lines 131–136) has ever suppressed a real finding on a current ADR.** All 8 ADRs were spot-checked by running the checker; it passed clean. A systematic test of every possible reason-code misuse outside the keyword contexts was not performed.

3. **Whether the em-dash VP entries in the 34 BCs represent final design decisions ("no VP needed for this property") or are genuine Phase 1b residue.** The formal-verifier or story-writer should adjudicate which of the 55 em-dash rows are intentionally VP-free and which require a real VP assignment.
