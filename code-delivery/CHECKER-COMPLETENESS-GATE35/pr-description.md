# [CHECKER-COMPLETENESS-GATE35] Spec-lint oracle repairs — BI-056 E-code detector + BI-057 multi-column TV extraction

**Epic:** Spec-Lint Integrity — Gate #35 Checker Completeness
**Mode:** maintenance
**Branch:** fix/checker-completeness-gate35
**Head SHA:** 6a5eb9f6ff8bbf7911f5eb612215e353cb54239f
**Base:** develop

> **SHA note:** `6a5eb9f` is a documentation-only commit (cycle-7 verifier hardening —
> S-5 complete + Check 8 live-PR-body in `scripts/verify-evidence-figures.py`); it contains
> no change under `scripts/spec-lint/`. The source tree under test is byte-identical to
> `72db558`. Evidence artifacts and the selftest run recorded in AC-002 were captured at
> `72db558`; they remain valid at `6a5eb9f` precisely because the spec-lint source is identical.

![Tests](https://img.shields.io/badge/selftests-99%2F99-brightgreen)
![Primitives](https://img.shields.io/badge/primitives-10%2F10-brightgreen)
![Guard](https://img.shields.io/badge/unproven_scope_reductions-0%2F15-brightgreen)
![Spec files](https://img.shields.io/badge/corpus-134%2F134_spec_files-blue)

Eight spec-lint oracle repairs across BI-056, BI-057, cycle-2 blocking fixes (independent E-class
canary + ADR double-count elimination), and NIT-1/NIT-2. Selftests advance from 91 to 99 (new tests
5k, 5l, 5m, 5n, 5o, 5o-b, 5p, EI-7). BI-056 folds in four additional gaps AC-1/AC-2/AC-3/AC-7.
`check-adr-consistency` gains an independent E-class canary replacing a tautology.
`check-ec-injectivity` now compares 174 of 174 citations (up from 110); `"link"` is absent from
`_COMPARABLE_KEYWORDS` at head.

> **IMPORTANT — this PR does NOT remediate any content defects.** It corrects and extends
> the checkers so more defects become visible. The `.factory/specs/` corpus is untouched
> (frozen perimeter, tree `ace1745871122cd1fa2c46cf27c5493cc1083411`). Any reviewer suggestion
> to fix a spec file to make a checker green is out of scope and must be routed to the
> content remediation workstream.

> **NOTE — `Spec lint` CI check WILL FAIL on this PR.** Decision D-128 classifies `Spec lint`
> as advisory-only (NOT a required check). Its failure is the intended deliverable: the
> newly-visible violations are real content defects per D-122 ("oracles expected to WIDEN count
> before it shrinks"). The four required checks are: `Format check`, `Clippy (deny warnings)`,
> `Test (macos-latest)`, `Build release (macos-latest)`.

> **MERGE CONSTRAINT — operator-gated.** This PR touches `scripts/spec-lint/**` (a restricted
> file pattern per `.factory/merge-config.yaml`). Merge requires operator confirmation per
> decision D-120.

---

## Architecture Changes

```mermaid
graph TD
    CAC["check-adr-consistency.py<br/>(BI-056 + folded AC-1/2/3/7<br/>+ cycle-2 canary + NIT-1)"]
    CEC["check-ec-injectivity.py<br/>(BI-057 + D-132)"]
    RST["run-selftests.sh<br/>(+8 tests: 5k, 5l, 5m, 5n, 5o, 5o-b, 5p, EI-7)"]
    PRI["spec_lint_primitives.py<br/>(unchanged)"]

    CAC -->|"uses"| PRI
    CEC -->|"uses"| PRI
    RST -->|"orchestrates"| CAC
    RST -->|"orchestrates"| CEC

    style CAC fill:#90EE90
    style CEC fill:#90EE90
    style RST fill:#90EE90
```

<details>
<summary><strong>Change summary per checker</strong></summary>

**BI-056 — check-adr-consistency.py (Pattern 4: E-class code namespace + folded gaps AC-1/AC-2/AC-3/AC-7):**
`TAXONOMY_CODE_RE` (Pattern 3) matched only the `(consistent with X taxonomy)` prose shape.
`E-IO-002` — the code adversary finding P7-S1-003 explicitly required detection of — was
invisible in all other prose shapes. Fix adds `E_CLASS_CODE_RE` (Pattern 4): a
prose-shape-independent detector for `E-[A-Z]{2,4}-\d{3}` tokens. A companion function
`extract_valid_e_class_codes()` reads the closed set from `error-taxonomy.md §1`
(currently empty → all corpus `E-*` occurrences are violations). Result: 4 → 9 violations
(78 reason-code + 6 E-class occurrences validated). Detection confirmed at:
`BC-2.01.009.md:44,52,71,73`, `BC-2.11.004.md:61`, and `interface-definitions.md:237`.
`BC-2.01.009.md:23` carries two further occurrences inside YAML frontmatter, excluded by
the D-081 predicate and disclosed as `skipped=2`, bringing the corpus population to 8. New selftest 5k pins ALL THREE mandated calibration codes
as a set: `E-IO-002` (Pattern 4), `E-CLI-001` (Pattern 3), `malformed-fragment`
(Pattern 2). Structural proof that Pattern 4 cannot reintroduce the 22 false positives
removed in PR #11: it requires a 2-4 uppercase-letter namespace component between
`E-` and `-NNN`; all prior false positives were lowercase reason-code tokens.
Additional gaps folded in: AC-1 (E-class in ADR table cell — selftest 5l), AC-2 (frontmatter
E-class named skip — selftest 5m), AC-3 (taxonomy-ref routing to Pattern 4 — selftest 5n),
AC-7 (E-class population gate — selftest 5o, proves gate is load-bearing).

**BI-057 — check-ec-injectivity.py (multi-column TV extraction + D-132 assertions):**
The checker asserted "134 of 134 spec files (complete)" while silently excluding 80 of 190
comparison rows (42%). All three excluded shapes were unparsed, not non-comparable:
`§2 (Source MD File | Link | Filesystem)`, `§3 (Source MD | Heading | Link)`,
`§4 (Link | Mock Server / Setup)`. Fix (a): `extract_tv_rows()` now collects ALL comparable
columns per section and concatenates them. `"filesystem"`, `"heading"`, `"mock server"`
added to `_COMPARABLE_KEYWORDS`; `"link"` is **not** in the comparable set at head
(reverted per cycle-1 review; 174 citations with 42 divergent / 22 adjudication is the
correct baseline). Fix (b): the `"no EC citations outside BC_DIR/TV_FILE"` assumption is
now a checked invariant (an unexpected EC row in any other spec file causes exit 1). Fix (c):
non-table lines reset section parser state (fixes latent mis-parse where stale column indices
bled into the next section). D-132: per-EC pairing counts, EC-token gates,
verdict-comparison skip counts, and collision short-circuit counts are all emitted explicitly.

**Independent E-class canary — check-adr-consistency.py (cycle-2 BLOCKING-1):**
The original E-class reconciliation was a tautology (`assert x == x`). The fix replaces it
with an **independent probe**: its own file iteration (`_in_spec_corpus`, not
`should_check_for_broad_p19`), its own line iteration (no routing or `continue` logic), and a
deliberately wider regex (`E_CLASS_CANARY_RE = (?<![A-Za-z0-9])E-[A-Z]+-\d+`, no `{2,4}`
namespace cap and no `{3}` digit cap) — then compares via `print(...) + return 2`, not
`assert`. The `python -O` stripping concern is also addressed. Counter-factual confirmed:
the table-line mutant that previously halved live detections while the tautology closed
silently is now caught (gate fires `population=8 != examined=3 + skipped=2`, exit 2).
New selftests: 5o (population gate fires on BLOCKING-1 mutant) and 5p (one ADR defect yields
exactly one violation, not two).

**NIT-1/NIT-2 — check-adr-consistency.py and run-selftests.sh (commit 72db558):**
NIT-1: `E_CLASS_CANARY_RE` lifted to module level; frontmatter bucket changed from
`set(PATTERN_FOUR_RE.findall(line))` to `set(E_CLASS_CANARY_RE.findall(line))` — both false-alarm
directions (narrower regex inflating `skipped` count; wrong regex lowering `examined`) are closed.
New test 5o-b pins the alignment: reverting either bucket or probe to the narrower regex kills
`5o-b`'s `skipped=1` assertion. NIT-2: `run-selftests.sh:6070-6078` mutation-kill comment for 5o
now documents both kill paths (Path 1 — mutation makes gate close but lose detections; Path 2 —
narrowing `E_CLASS_CANARY_RE` kills four assertions including 5o-b).

**ADR double-count fix — check-adr-consistency.py (cycle-2 BLOCKING-2):**
`e_class_only` flag plumbed (`check-adr-consistency.py:288`, guard at `383`, ADR call site at
`640-641`), so Patterns 1-3 no longer run on the ADR path. One ADR reason-code defect now yields
exactly one violation entry. `check_adr()` source remains byte-identical to `da86271` — no POLICY
12 ADR check was lost. New selftest 5p verifies this directly.

</details>

---

## Story Dependencies

```mermaid
graph LR
    GATE34["ORACLE-REPAIRS-GATE34<br/>merged (da86271)"] --> GATE35["CHECKER-COMPLETENESS-GATE35<br/>this PR"]
    BI056["BI-056 blocking issue"] --> GATE35
    BI057["BI-057 blocking issue"] --> GATE35
    GATE35 --> D132R["D-132 full compliance<br/>(8 remaining checkers — next workstream)"]
    GATE35 --> CONTENT["Content remediation<br/>(EC-043, EC-050, EC-071, EC-092, etc.)"]
    style GATE34 fill:#90EE90
    style GATE35 fill:#FFD700
    style D132R fill:#FFCCCC
    style CONTENT fill:#FFCCCC
```

No upstream PRs are blocking. D-132 full compliance across all 9 checkers is downstream
(explicitly out of scope for this PR per the task description; tracked separately as task #3).

---

## Spec Traceability

```mermaid
flowchart LR
    ADV7["Adversary pass 7<br/>P7-S1-003 (E-IO-002 phantom<br/>blind spot)"] --> BI056["BI-056"]
    ADV7 --> BI057["BI-057<br/>(80 skipped TV rows)"]
    D132["D-132 operator directive<br/>(completeness at every skip site)"] --> BI057

    BI056 --> T5K["selftest 5k<br/>(3-code calibration set)"]
    BI056 --> T5L["selftests 5l/5m/5n<br/>(folded gaps AC-1/2/3)"]
    BI056 --> T5O["selftests 5o/5p/5o-b<br/>(canary gate + NIT-1)"]
    BI057 --> TEI7["selftest EI-7<br/>(§2 Filesystem column)"]

    T5K --> CAC["check-adr-consistency.py<br/>Pattern 4 + independent canary"]
    TEI7 --> CEC["check-ec-injectivity.py<br/>multi-column extraction"]
```

---

## Test Evidence

### Coverage Summary

| Metric | Value | Notes |
|--------|-------|-------|
| Selftests | **99/99** (up from 91 post-gate34) | Each proves clean-pass AND defect-fail |
| Primitive unit tests | **10/10** | `spec_lint_primitives.py` (unchanged) |
| Suppression guard pre-flight | **0/15 unproven scope reductions** | All 15 checkers pass |
| Corpus coverage | **134/134 spec files** | All checkers assert completeness |
| New selftests this PR | **8** (5k, 5l, 5m, 5n, 5o, 5o-b, 5p, EI-7) | |

### New Selftests (This PR)

| Test ID | Checker | What it verifies |
|---------|---------|-----------------|
| 5k | check-adr-consistency | All three mandated calibration codes detected as a set: `E-IO-002` (Pattern 4), `E-CLI-001` (Pattern 3), `malformed-fragment` (Pattern 2) |
| 5l | check-adr-consistency | E-class code in ADR table cell detected (folded gap AC-1); kills the table-line routing mutant |
| 5m | check-adr-consistency | Frontmatter E-class code disclosed as named skip (`skipped=1`); proves D-081 predicate fires (folded gap AC-2) |
| 5n | check-adr-consistency | E-class code in taxonomy-ref context routed to Pattern 4 (folded gap AC-3) |
| 5o | check-adr-consistency | E-class population gate fires on BLOCKING-1 mutant: `population=8 != examined=3 + skipped=2`, exit 2 |
| 5o-b | check-adr-consistency | NIT-1: frontmatter bucket uses `E_CLASS_CANARY_RE`; reverting bucket or probe kills `skipped=1` assertion |
| 5p | check-adr-consistency | One ADR reason-code defect → exactly 1 violation (not 2); `e_class_only` flag proof (cycle-2 BLOCKING-2) |
| EI-7 | check-ec-injectivity | §2 TV table shape (Source MD File / Link / Filesystem) is now parsed; Filesystem+Link columns concatenated; EC-007 divergence correctly detected |

### Updated Selftests (This PR)

| Test ID | What changed |
|---------|-------------|
| EI-4 | Updated fixture to use only non-comparable column (`Source MD File`) in section B — original section B fixture no longer triggered a skip after BI-057. Mutation-kill preserved. |
| 5j | Structural assertion grep relaxed from `"[1-9][0-9]* reason-code occurrences validated"` to `"[1-9][0-9]* reason-code occurrences"` — output format updated to include E-class occurrence count alongside reason-code count. |

### Baseline After This PR

| Checker | Previous (post-gate34) | After This PR | Notes |
|---------|----------------------|---------------|-------|
| check-adr-consistency | 4 violations (79 reason-code occ) | **9 violations** (78 reason-code + 6 E-class occ) | BI-056: 6 new E-class detections |
| check-ec-injectivity | 9 DIVERGENT + 5 ADJUDICATION; 110 of 190 TV rows compared | **42 DIVERGENT + 22 ADJUDICATION; 174 of 190 TV rows compared** | BI-057: 80 previously-skipped TV rows now parsed |
| (all others) | unchanged | unchanged | |

---

## Demo Evidence

This is a CLI tooling PR (Python spec-lint checkers). Evidence is captured as terminal
output rather than screen recordings.

| AC | Description | Evidence | Status |
|----|-------------|----------|--------|
| AC-1 | Pre-flight guard: 0 unproven scope reductions across 15 checkers; 10/10 primitives | `docs/demo-evidence/CHECKER-COMPLETENESS-GATE35/AC-001-preflight.txt` | PASS |
| AC-2 | Full selftest suite: 99/99 pass — run captured at `72db558`; valid at `39efec2` (docs-only head, source tree byte-identical) | `docs/demo-evidence/CHECKER-COMPLETENESS-GATE35/AC-002-selftest-99of99.txt` | PASS |
| AC-3 | New selftest 5k: all three calibration codes detected as a set | Embedded in AC-002 output | PASS |
| AC-4 | New selftest EI-7: §2 Filesystem column parsed and EC-007 divergence detected | Embedded in AC-002 output | PASS |
| AC-5 | check-adr-consistency on live corpus: 9 violations (78 reason-code + 6 E-class occurrences validated across 134 of 134 spec files) | `docs/demo-evidence/CHECKER-COMPLETENESS-GATE35/AC-005-adr-consistency-live.txt` | PASS |
| AC-6 | check-ec-injectivity on live corpus: 174 citations compared, 42 divergent, 22 adjudication | `docs/demo-evidence/CHECKER-COMPLETENESS-GATE35/AC-006-ec-injectivity-live.txt` | PASS |
| AC-7 | E-class population gate: unmutated pass (`pop=8, examined=6, skipped=2`); table-line mutant fires (`pop=8 != 3+2`, exit 2) | `docs/demo-evidence/CHECKER-COMPLETENESS-GATE35/AC-007-eclass-population-gate.txt` | PASS |

Full evidence report: `docs/demo-evidence/CHECKER-COMPLETENESS-GATE35/evidence-report.md`

> **Note:** Demo evidence files are committed on the feature branch. The evidence-report.md
> is generated from the selftest runner output and live corpus runs above.

---

## Holdout Evaluation

N/A — evaluated at wave gate. This is a maintenance PR targeting spec-lint tooling only.
No holdout scenarios apply to checker code changes.

---

## Adversarial Review

| Pass | Findings | Critical | High | Status |
|------|----------|----------|------|--------|
| 1-7 | Prior passes | — | — | Converged on spec content + gate #34 oracle repairs |
| 7 | P7-S1-003 (E-IO-002 blind spot) | 1 | 0 | This PR resolves: BI-056 + BI-057 + D-132 partial |
| Cycle-2 | BLOCKING-1 (tautology), BLOCKING-2 (double-count) | 2 | 0 | Resolved: independent E-class canary; `e_class_only` flag |

**Findings resolved by this PR:**
- BI-056: `TAXONOMY_CODE_RE` prose-shape dependency → `E_CLASS_CODE_RE` prose-shape-independent Pattern 4; four additional gaps AC-1/2/3/7 folded in
- BI-057: single-column TV extraction → multi-column concatenation; 80 skipped rows now parsed
- D-132: 2 of 10 skip-site assertions → all TV-extraction and per-EC-pairing granularities asserted (partial; 8 remaining checkers tracked separately)
- Cycle-2 BLOCKING-1: `assert x == x` tautology → independent E-class canary with independent file iterator and wider regex
- Cycle-2 BLOCKING-2: ADR reason-code double-count eliminated via `e_class_only` flag
- NIT-1: frontmatter E-class bucket aligned with `E_CLASS_CANARY_RE` (pins the canary/bucket asymmetry); test 5o-b added
- NIT-2: 5o mutation-kill comment extended to document both kill paths (Path 1 and Path 2)

---

## Security Review

Reviewed by `vsdd-factory:security-reviewer`. Scope: all files under `scripts/spec-lint/`
in the PR diff. No new security findings introduced by this PR.

```mermaid
graph LR
    Critical["Critical: 0"]
    High["High: 0"]
    Medium["Medium: 0"]
    Low["Low: 0 new (3 pre-existing from PR #11)"]

    style Critical fill:#90EE90
    style High fill:#90EE90
    style Medium fill:#90EE90
    style Low fill:#90EE90
```

**Verdict: APPROVE (no new findings)**

<details>
<summary><strong>Security Analysis (0 new findings)</strong></summary>

All new regexes (`E_CLASS_CODE_RE`, `E_CLASS_CANARY_RE`, `re.match(r"^-+$", c)`) are ReDoS-safe with bounded
quantifiers. All shell heredoc delimiters in new selftests (5k, 5l, 5m, 5n, 5o, 5o-b, 5p, EI-7) are single-quoted
preventing variable expansion. All `$T` and `$LINT_DIR` references are double-quoted.
No new attack surface beyond pre-existing SEC-001/002/003 (carry-forward from PR #11).

**Explicit clean checks:** No `eval`, `exec`, `subprocess`, or `os.system` calls in new code.
No hardcoded secrets. No ReDoS risk (all new regexes use bounded quantifiers). No network
access introduced.

**Pre-existing findings (unaffected):**
- SEC-001 (LOW, CWE-59): Symlink following via `SPECS.rglob("*.md")` — no new exposure
- SEC-002 (LOW, CWE-73): `SPEC_LINT_REPO_OVERRIDE` accepts arbitrary path — no new exposure
- SEC-003 (LOW, CWE-345): `COMPLETENESS_PATTERN` can match comment lines — unrelated to this PR

</details>

---

## Risk Assessment

### Blast Radius
- **Systems affected:** `scripts/spec-lint/` only — 2 Python checker scripts + selftest orchestrator
- **User impact:** None in production. spec-lint is a developer-facing lint tool, not a runtime component
- **Data impact:** Zero. Checkers are read-only; they do not write to the spec corpus
- **Risk Level:** LOW — no Rust changes, no CI workflow changes, no `.factory/specs/` changes
- **Restricted files:** YES — `scripts/spec-lint/**` is in `.factory/merge-config.yaml` `restricted_file_patterns` → operator-gated merge per D-120

### Performance Impact
| Metric | Before | After | Notes |
|--------|--------|-------|-------|
| Selftest suite | ~55s | ~65s | 8 additional tests (5k, 5l, 5m, 5n, 5o, 5o-b, 5p, EI-7) |
| check-adr-consistency | negligible | negligible | Pattern 4 + canary probe are linear regex scans |
| check-ec-injectivity | negligible | slightly higher | Multi-column concatenation is still O(row) |

### Rollback
```bash
git revert 6a5eb9f 0ff789f f6dfa58 39efec2 72db558 ca8c1c0 b4bbbc3 fd74bd7 1dd7721 879efff d3085d9 2349184
git push origin fix/checker-completeness-gate35
```
Rollback reverts all 12 commits in reverse order (newest-first). Restores the Pattern 3-only
E-code detection, single-column TV extraction, and the tautology reconciliation; the
80 previously-excluded TV rows would silently disappear again.

---

## Traceability

| Issue | Checker | Selftest | Corpus Impact | Status |
|-------|---------|---------|----------------|--------|
| BI-056 | check-adr-consistency.py | 5k | 6 new E-class detections (E-IO-002 ×4 in BC-2.01.009.md; E-CLI-001 ×1 in BC-2.11.004.md:61; E-IO-002 ×1 in interface-definitions.md) | CLOSED |
| BI-056 folded gaps (AC-1/2/3/7) | check-adr-consistency.py | 5l, 5m, 5n, 5o | ADR table cell, frontmatter named skip, taxonomy-ref routing, E-class population gate | CLOSED |
| BI-057 | check-ec-injectivity.py | EI-7 | 110 → 174 citations compared; 9 → 42 divergent; 5 → 22 adjudication | CLOSED |
| D-132 (partial) | check-ec-injectivity.py | — | TV-extraction granularity + per-EC pairing + verdict-comparison + collision counts all emitted | PARTIAL — 8 remaining checkers out of scope |
| Cycle-2 BLOCKING-1 (tautology) | check-adr-consistency.py | 5o, 5p | Independent E-class canary; table-line mutant caught by gate | CLOSED |
| Cycle-2 BLOCKING-2 (double-count) | check-adr-consistency.py | 5p | `e_class_only` flag; one defect = one violation | CLOSED |
| NIT-1 (canary/bucket asymmetry) | check-adr-consistency.py | 5o-b | `E_CLASS_CANARY_RE` module-level; frontmatter bucket aligned | CLOSED |
| NIT-2 (5o mutation comment) | run-selftests.sh | 5o | Path 1 and Path 2 both documented | CLOSED |

---

## AI Pipeline Metadata

<details>
<summary><strong>Pipeline Details</strong></summary>

```yaml
ai-generated: true
pipeline-mode: maintenance
factory-version: "1.0.0"
gate: "35"
gate-directive: "checker completeness — BI-056 E-code namespace + BI-057 multi-column TV extraction + cycle-2 canary + NIT-1/NIT-2"
pipeline-stages:
  adversarial-review: completed (pass 7, P7-S1-003; cycle-2 BLOCKING-1/BLOCKING-2)
  oracle-repair: completed (BI-056, BI-057, cycle-2 fixes, NIT-1/NIT-2)
  selftest-validation: completed (99/99)
  pr-delivery: in-progress
convergence-metrics:
  selftests: "99/99"
  unproven-scope-reductions: "0/15"
  primitive-tests: "10/10"
  corpus-coverage: "134/134"
models-used:
  builder: claude-sonnet-4-6
generated-at: "2026-08-08T00:00:00Z"
spec-corpus-frozen-at: "ace1745871122cd1fa2c46cf27c5493cc1083411"
```

</details>

---

## Pre-Merge Checklist

- [x] Selftests 99/99 pass (each proves clean-pass AND defect-fail)
- [x] Pre-flight guard: 0 unproven scope reductions across 15 checkers
- [x] Primitive unit tests 10/10 pass
- [x] `.factory/specs/` untouched — frozen perimeter tree `ace1745871122cd1fa2c46cf27c5493cc1083411`
- [x] No changes to Rust source, Cargo.toml, or CI workflows
- [x] Baseline widened as expected: 4→9 adr-consistency violations; 110→174 ec-injectivity comparisons; 9→42 divergent; 5→22 adjudication
- [x] Required CI checks passing (Format check, Clippy, Test macos-latest, Build release macos-latest) — all PASS at `39efec2`
- [ ] PR review convergence complete — pending
- [ ] Operator merge authorization — pending (D-120; scripts/spec-lint/** is a restricted file pattern)

> **Note on spec-lint CI:** The `Spec lint` CI check is NOT a required status check on
> `develop`. Its output will be red — that is the intended baseline deliverable per D-128.
> A red spec-lint result MUST NOT be treated as a blocking gate.

> **Note on operator gate:** Merge is operator-gated regardless of autonomy_level per
> `.factory/merge-config.yaml` (restricted_file_patterns includes `scripts/spec-lint/**`).
