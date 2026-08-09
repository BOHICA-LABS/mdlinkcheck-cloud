---
document_type: audit-record
level: ops
version: "1.0"
status: final
producer: state-manager
timestamp: 2026-08-09T05:00:00Z
cycle: phase-1d
decision: D-132
inputs: []
input-hash: "[live-state]"
traces_to: D-132, D-133, D-135, D-136, D-141
---

# D-132 Eight-Checker Skip-Site Audit — phase-1d

Produced per gate #35 operator ruling (D-133) and gate #36 operator ruling (D-135/D-136).
Documents every skip site, silent suppression, and false-green PASS across the nine spec-lint
checkers. Drives the nine-checker ledger sweep (BI-058), which is a prerequisite for pass 8.

---

## HEADLINE FINDING: D-125 Suppression Guard Is INERT on Production Code

The `run_suppression_guard` pre-flight (Pass 1) reports:
`15 checkers/generators scanned, 0 proven scope reductions, 0 unproven`.

Zero of 15 production files trip either `SUPPRESSION_PATTERN` or `PATH_SHAPE_PATTERN`.
Therefore Pass 2 (`COMPLETENESS_PATTERN`) **never executes** against any real checker —
the guard has only ever been exercised against synthetic fixtures.

**It would NOT have caught BI-057.** The row-granularity skip in `check-ec-injectivity`
(80 of 190 rows, 42% of comparison population) is a `COMPLETENESS_PATTERN` case, but the
guard's Pass-2 is unreachable because Pass-1 finds zero scope reductions in any checker.

Root cause: `SUPPRESSION_PATTERN` enforces a fixed vocabulary (`ALLOWLIST`, `SKIP_LIST`,
`DEFER`, etc.) and `PATH_SHAPE_PATTERN` matches a specific identifier format. Neither pattern
covers the `REGISTRY_FILES`, `EXCLUDE_PATHS`, or column-header skip patterns that are the
dominant skip mechanisms in the live checkers.

---

## ACCEPTED RESIDUAL RISK (Operator Decision — Record Verbatim in Substance)

**AST walk and narrow-literal detector are EXPLICITLY SKIPPED by operator decision (D-136,
D-141).**

The narrow-literal class (BI-056 class) stays on **reviewer vigilance** rather than structural
enforcement. Operator's rationale: the checker layer is a candidate for structural replacement
post-run; pass 8 is the schedule priority; D-132's proof obligation is satisfied by the
independent-probe ledger (D-141 amended ruling 2), not by the AST layer.

**Known live instances this leaves unguarded** (not detected by any automated checker):

| Site | File | Shape |
|------|------|-------|
| `_VP_TABLE_HEADER_CELL = "VP-NNN"` | `check-placeholders.py` | narrow literal guards 6 tables / 78 VP-ID-column rows |
| `table_header_first_cell == "EC"` | `check-ec-injectivity.py` | narrow literal governs column recognition |
| `("reason","reason code")` header set | `check-adr-consistency.py` | narrow literal for reason-cell column recognition |
| `verdict_pattern` closed vocabulary | `check-adr-consistency.py` | closed regex set |

These four sites are the narrow-literal residual explicitly accepted by operator ruling D-136/D-141.

---

## False-Green PASS Checkers (Five)

### 1. `check-placeholders` — "0 live placeholders … (complete)"

**Suppression scope:** 55 raw matches found across the spec corpus. **100% suppressed.** None
disclosed to the caller. Suppression operates across five predicates:

- `_VP_TABLE_HEADER_CELL = "VP-NNN"` exempts 6 tables / 78 VP-ID-column rows (narrow literal,
  BI-056 class — see Accepted Residual Risk above).
- `EXCLUDE_PATHS`-equivalent logic wholesale-excluded `prd.md` (the BI-047 class: D-039 pattern
  under a different variable name; the D-125 guard's `SUPPRESSION_PATTERN` vocabulary missed it
  because the name is `EXCLUDE_PATHS`, not `SKIP_LIST` or `ALLOWLIST`).
- Three additional in-row predicates suppress further matches without disclosure.

**Tautology:** Both the "live count" and the "complete" assertion iterate the same unfiltered
generator. The `INCOMPLETE` branch is structurally unreachable for all inputs — every call path
that reaches the assertion has already walked the same set. `complete` never means "examined
the full corpus"; it means "the unfiltered count happened to be zero after applying the
suppressions the assertion's own generator also applies."

**The D-125 guard passes this checker.** The guard validates the file-level assertion ("134 of
134 spec files") but not the within-file suppression of the 55 matches.

---

### 2. `check-id-resolution` — "134 files checked"

**7 files receive ZERO validation** — 1,785 lines of spec content — via the `REGISTRY_FILES`
set. This is **BI-047 reproduced under a different variable name.** The D-125 repair targeted
`EXCLUDE_PATHS` and similar vocabulary; `REGISTRY_FILES` uses a different shape
(`{ str(CAPABILITIES), ...}` vs `{ str(SPECS / "...")}`) that the guard's `PATH_SHAPE_PATTERN`
does not match.

**12 of 12 R3-B detections suppressed** — the live yield of the R3-B path (non-conforming
sub-reason ID shapes in Reason Cell column) is exactly zero, undisclosed. The checker reports
zero violations when 12 instances exist.

**2 YAML files iterated** but counted in no totals — invisible to the "134 of 134" assertion.

---

### 3. `check-holdout-boundary` — "(complete)"

**`should_check_file` is a no-op filter.** It excludes three directory prefixes — none of which
are under `SPECS/`. The filter therefore excludes ZERO files from the spec corpus. The
completeness assertion that follows ("all spec files checked") is satisfied vacuously.

**Tautological:** The assertion is `should_check_file(f) for f in corpus` but `should_check_file`
returns `True` for every file in `SPECS/`. The INCOMPLETE branch is unreachable by construction.

---

### 4. `check-counts` — "37 count checks passed"

**37 is defined as whatever ran.** There is no expected total — `checks_passed` is a counter
incremented once per check run, and the assertion is `checks_passed > 0`. Any input set
produces a tautologically-passing assertion.

**2 documented checks are measured no-ops (P0/P1):** The P0 and P1 check functions execute
their code paths but their success conditions are always satisfied by the corpus structure —
there is no input that makes them report a failure, making them effectively zero-information
probes.

**3 functions are DEAD CODE** — including the `HS-INDEX.md active holdout count` check that the
module docstring advertises as one of the checker's primary purposes. None of these dead
functions are called from the dispatcher. The HS-INDEX count check is **the check the module
docstring leads with**, yet it has never executed on any real corpus.

---

### 5. `check-index-integrity` — "80 structural checks"

**66 of 80 checks are one per-BC loop** — the number 80 changes when BCs are added or removed.
It cannot detect a deleted check (the metric scales with corpus, not with check coverage).

**61 of 76 HS lines (80%) land in an unbounded `prose` sink** whose bucket dict is computed,
asserted under the conservation law, then **discarded before printing**. The result: the check
confirms "all 76 HS lines are accounted for" (totality, per the D-070 lesson) but cannot tell
the caller which bucket anything went into. This is the D-070 "conservation law proves totality
not correctness" finding recurring in a sibling checker.

**`HS-INDEX.md` is absent from `required_files`.** If `HS-INDEX.md` were moved, renamed, or
deleted, `check-index-integrity` prints `all consistent` and **exits 0**. The entire HS
subsystem check is a latent false-GREEN on file movement. This is the highest-severity single
false-green in the suite: it is silent, would survive every existing test run, and is the
motivation for the `HS-INDEX.md required_files` item in BI-058's scope.

---

## Well-Behaved Checkers (for completeness)

### `check-adr-consistency`

Had 3 of the corpus's 8 E-class occurrences unaccounted pre-fix:
- 2 frontmatter-excluded (silent, exclusion legitimate but invisibility was the defect — AC-1)
- 1 dedup misroute (Pattern 3 claimed `E-CLI-001` before Pattern 4 validated it against the
  correct registry — AC-7)

**Status: CLOSED** by `fd74bd7` + `b4bbbc3` (D-137). E-class detections 5→6. POLICY 12
coverage preserved. `check_adr()` textually unchanged.

### `check-canonical-facts`

**Best fail-loud discipline in the suite:** every `continue` appends a finding first (no silent
skips). However, its binding population is **self-declared, not derived** — e.g.:
- Pass 1.5: 172 corpus occurrences / 2 bindings
- `macOS`: 204 corpus occurrences / 1 binding

A self-declared binding count cannot detect a missing binding. This is a softer form of the
tautology class (D-138): the population is asserted, not measured.

### `check-ec-injectivity`

Had **10 skip granularities** with only **2 asserted completeness**. The largest unasserted
skip: per-EC pairing silently dropped **79 BC-cited ECs + 19 TV-only ECs** (larger than the
80 rows BI-057 was opened against).

**Status of BI-057:** REPAIRED-PENDING-MERGE at `ca8c1c0`. TV-row exclusion closed:
110→174 citations compared, 0 column-skipped. Guard extended per D-132/D-133.

---

## Priority-Ranked Silent Sites (units-dropped, current session)

| Rank | Site | Checker | Units Dropped | Status |
|------|------|---------|---------------|--------|
| 1 | ADR frontmatter (3,956 lines) | `check-adr-consistency` | 3 of 8 E-class occurrences | **CLOSED** — `fd74bd7`+`b4bbbc3` |
| 2 | `REGISTRY_FILES` exclusion (7 files, 1,785 lines) | `check-id-resolution` | 1,785 lines zero-validated | **OPEN** — BI-058 scope |
| 3 | 55-match suppression (100%) | `check-placeholders` | 55 of 55 matches | **OPEN** — BI-058 scope |
| 4 | ADR Reason-cell `fullmatch` 50 of 66 cells (AC-5) | `check-adr-consistency` | 50 cells | **DEFERRED** — AC-5, not in PR #12 scope |
| 5 | `VP-NNN` literal 6 tables / 78 rows | `check-placeholders` | 78 rows | **OPEN (residual)** — narrow-literal, reviewer vigilance |
| 6 | Index-integrity `prose` sink 61 of 76 lines | `check-index-integrity` | 61 lines | **OPEN** — BI-058 scope |
| 7 | id-resolution R3-B 12 of 12 detections | `check-id-resolution` | 12 detections | **OPEN** — BI-058 scope |

---

## Scope of Required Sweep (BI-058)

Per D-141 amended ruling 2, the nine-checker ledger sweep must produce, for each of the nine
checkers, a **coverage ledger with INDEPENDENT-PROBE canary populations** that are deliberately
**WIDER than the detector**. The canary population must be derived independently from the
matching machinery it audits. A ledger that closes by deriving its population from the same
machinery proves nothing (the BLOCKING-1 tautology lesson, D-138).

Additionally:
- `HS-INDEX.md` must be added to `check-index-integrity`'s `required_files` list
- `run_suppression_guard` Pass-1 fail-open must be investigated and fixed

The AST walk and narrow-literal detector are explicitly OUT of scope (operator decision D-136/D-141).
