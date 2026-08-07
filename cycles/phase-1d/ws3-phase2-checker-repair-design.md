---
document_type: checker-repair-design
audit_id: WS-3-PHASE2
phase: 1d
branch: develop
date: 2026-08-07
mode: READ-ONLY characterization + repair specification (NO code applied)
scope: BI-023 / WS-3 Phase 2 items 2 and 3
governing_decisions: D-039, D-069, BI-021, BI-041, BI-043
repo_root_verified: /Users/jmagady/Dev/mdlinkcheck-cloud
sources_reviewed:
  - scripts/spec-lint/check-placeholders.py
  - scripts/spec-lint/check-id-resolution.py
  - scripts/spec-lint/selftest/run-selftests.sh
  - scripts/spec-lint/selftest/fixtures/
  - .factory/specs/ (enumeration corpus, 133 md files)
  - .factory/cycles/phase-1d/ws3-skip-list-audit.md (prior audit, magnitudes re-verified)
---

# WS-3 Phase 2 — Checker Repair Design (Items 2 and 3)

**Nothing in this document has been applied.** No file under `/Users/jmagady/Dev/mdlinkcheck-cloud/scripts/`
or `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/` was created, edited, or deleted.
This document is the only artifact produced.

---

## 0. Evidence base and root-resolution verification

Per the BI-021/BI-043 caveat, repo-root resolution was verified before any green
result was trusted:

```
override env:   /Users/jmagady/Dev/mdlinkcheck-cloud
heuristic root: /Users/jmagady/Dev/mdlinkcheck-cloud     (parent.parent.parent — agrees)
```

Both roots agree (this is the primary checkout, not a linked worktree), so
`SPEC_LINT_REPO_OVERRIDE` and the fallback heuristic resolve identically. Current
baseline against the real spec tree:

| Checker | Exit | Findings |
|---|---|---|
| `/Users/jmagady/Dev/mdlinkcheck-cloud/scripts/spec-lint/check-placeholders.py` | **1** | 25 × `[filled by story-writer]` across 133 files checked. **Zero** em-dash VP findings. |
| `/Users/jmagady/Dev/mdlinkcheck-cloud/scripts/spec-lint/check-id-resolution.py` | **0** | `Check passed: 134 files checked — all ID references resolve` |

`check-id-resolution.py` exiting **0** with a correctly-resolved root, while 9 live
`EC-NEW-*` table rows exist in the tree, is the direct proof of Item 3. It is a genuine
pass verdict on defective content, not a misresolved-root artifact.

Corpus shape (for false-positive budgeting):

| Measure | Count |
|---|---|
| BC files (excluding `BC-INDEX.md`) | 66 |
| `.md` files under `.factory/specs/` | 133 |
| `## Verification Properties` tables with header `\| VP-NNN \| Property \| Proof Method \|` | 67 (66 BC files + 1 template block in `bc-module-map.md`) |
| Em-dash (U+2014) occurrences anywhere in `.factory/specs/**.md` | **1,787** across 133 files |
| BC files containing an em-dash *anywhere* | **all 66** (+ `BC-INDEX.md` = 67) |

The last row is the decisive constraint on Item 2: **the em-dash is not a rare token.
It is a house style mark appearing 1,787 times.** Any repair predicate that is not
strictly positional is a false-positive generator with a ~1,700-item blast radius.
The operator's "67 BC files contain an em-dash" measurement is confirmed and explained:
it is simply *every* BC file plus the index, because em-dash is used in prose everywhere.

---

# ITEM 2 — `check-placeholders.py` em-dash bypass

## 2.1 The exact code path

`check-placeholders.py` has exactly two detection mechanisms. Both are quoted in full.

**Mechanism A — the general placeholder catalog (lines 43–47):**

```python
PLACEHOLDER_PATTERNS = [
    (re.compile(r"\bVP-TBD\b"), "VP-TBD (POL-14)"),
    (re.compile(r"\bSS-TBD\b"), "SS-TBD (POL-15)"),
    (re.compile(r"\[filled by [^\]]+\]", re.IGNORECASE), "[filled by ...] (POL-14/15 generalized)"),
]
```

**Mechanism B — the one and only column-aware rule (lines 49–51):**

```python
# Regex to detect test-sufficient in the VP-NNN column of a VP table row.
# Pattern: | test-sufficient | <anything> |
TEST_SUFFICIENT_IN_VP_COL = re.compile(r"^\|\s*test-sufficient\s*\|")
```

**The scan loop (lines 114–129):**

```python
for lineno, line in enumerate(lines, 1):
    # Check for test-sufficient in VP-NNN column (POL-14 violation)
    if TEST_SUFFICIENT_IN_VP_COL.match(line):
        violations.append(...)
        continue  # no point checking other patterns on the same row

    for pattern, name in PLACEHOLDER_PATTERNS:
        for m in pattern.finditer(line):
            ...
```

## 2.2 Mechanism of the bypass

This is **"the predicate sees the row and returns clean"** — not "never sees the row".
The row is read, `.match()` and `.finditer()` are both evaluated against it, and every
predicate returns no match. Empirically verified against the literal offending row:

```
row: | — | Plain directory link (no fragment) → clean | unit test |
  TEST_SUFFICIENT_IN_VP_COL.match  -> None
  r'\bVP-TBD\b'                    -> []
  r'\bSS-TBD\b'                    -> []
  r'\[filled by [^\]]+\]'          -> []
```

The root cause is **the design of Mechanism B, not its regex**. `TEST_SUFFICIENT_IN_VP_COL`
is a *value-enumerating* rule: it anchors on one literal forbidden spelling
(`test-sufficient`) in the first cell. It therefore only ever catches placeholders whose
spelling was known at authoring time. Any other spelling of "no VP yet" — em-dash,
en-dash, `none`, `n/a`, `TBD`, empty cell — sails through, because the checker never asks
the question *"is the first cell a well-formed VP-NNN reference?"*. It only asks
*"is the first cell this one specific bad string?"*

Corroborating evidence that the value-enumerating design has already failed in practice:
the literal string `test-sufficient` now appears **0 times** in any VP column in the live
tree. Mechanism B is currently a dead rule guarding against a spelling nobody uses, while
the actually-used placeholder spelling (em-dash, 55 rows) is unguarded. This is the exact
failure mode operator ruling **D-069** bans — spelling-specific patching instead of
property-based structural checking.

## 2.3 True count — enumerated, not inherited

Enumeration predicate used: a markdown table data row (not the `|---|` separator row)
whose enclosing table's header row begins with the cell `VP-NNN`, and whose **first cell**
is a lone dash-family / null-family token.

**Result: 55 rows across 34 BC files. The audit figure of 34/55 is CONFIRMED exactly.**
Character histogram of the offending cells: `Counter({('—', 'EM DASH'): 55})` — every one
of the 55 is U+2014 EM DASH; there are no en-dash, hyphen, `TBD`, `n/a`, or empty-cell
variants currently present.

| # | File (absolute) | Line(s) |
|---:|---|---|
| 1 | `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-01/BC-2.01.001.md` | 73 |
| 2 | `.../ss-01/BC-2.01.002.md` | 71 |
| 3 | `.../ss-01/BC-2.01.005.md` | 81 |
| 4 | `.../ss-01/BC-2.01.006.md` | 66 |
| 5 | `.../ss-01/BC-2.01.007.md` | 65 |
| 6 | `.../ss-01/BC-2.01.008.md` | 68 |
| 7 | `.../ss-02/BC-2.02.001.md` | 73 |
| 8 | `.../ss-02/BC-2.02.002.md` | 95, 96 |
| 9 | `.../ss-02/BC-2.02.003.md` | 67 |
| 10 | `.../ss-02/BC-2.02.004.md` | 66 |
| 11 | `.../ss-03/BC-2.03.003.md` | 78 |
| 12 | `.../ss-03/BC-2.03.004.md` | 69, 70 |
| 13 | `.../ss-03/BC-2.03.005.md` | 70 |
| 14 | `.../ss-03/BC-2.03.006.md` | 68, 69 |
| 15 | `.../ss-07/BC-2.07.002.md` | 72, 73 |
| 16 | `.../ss-07/BC-2.07.005.md` | 87, 88 |
| 17 | `.../ss-07/BC-2.07.006.md` | 84, 85 |
| 18 | `.../ss-09/BC-2.09.001.md` | 73, 74 |
| 19 | `.../ss-10/BC-2.10.001.md` | 82, 83 |
| 20 | `.../ss-10/BC-2.10.002.md` | 160, 161 |
| 21 | `.../ss-10/BC-2.10.003.md` | 69, 70 |
| 22 | `.../ss-10/BC-2.10.004.md` | 89, 90 |
| 23 | `.../ss-10/BC-2.10.007.md` | 74, 75 |
| 24 | `.../ss-10/BC-2.10.008.md` | 80, 81 |
| 25 | `.../ss-10/BC-2.10.009.md` | 96 |
| 26 | `.../ss-10/BC-2.10.010.md` | 85, 86 |
| 27 | `.../ss-11/BC-2.11.003.md` | 71 |
| 28 | `.../ss-11/BC-2.11.004.md` | 76, 77 |
| 29 | `.../ss-12/BC-2.12.002.md` | 73, 74 |
| 30 | `.../ss-12/BC-2.12.003.md` | 75, 76 |
| 31 | `.../ss-12/BC-2.12.004.md` | 72, 73 |
| 32 | `.../ss-12/BC-2.12.005.md` | 77, 78 |
| 33 | `.../ss-13/BC-2.13.002.md` | 68, 69 |
| 34 | `.../ss-14/BC-2.14.004.md` | 75, 76 |

(All paths are under `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/`.)

Representative offending cell content, `.../ss-07/BC-2.07.005.md:87–88`:

```
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| — | Plain directory link (no fragment) → clean | unit test |
| — | Directory link with fragment → broken (target-is-directory) | unit test |
```

Semantically: these two properties have a stated proof method but **no verification
property ID**, i.e. they are outside VP-INDEX and outside the formal-verification
accounting. That is exactly the state POL-14 exists to forbid.

## 2.4 Two additional non-conforming VP-column values found (not em-dash)

Enumerating *all* first-cell values inside `VP-NNN`-headed tables surfaced two values that
are neither em-dash nor a valid VP reference. These are decisive for the repair boundary:

| Location | First cell | Classification |
|---|---|---|
| `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/bc-module-map.md:479` | `none` | **MUST NOT be flagged** — it is inside a ` ```markdown ` fenced code block that *documents the remediation template*. Flagging it would punish the document that prescribes the fix. |
| `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-06/BC-2.06.001.md:109` | `VP-001, VP-018` | **MUST NOT be flagged** — a legitimate multi-VP citation: `\| VP-001, VP-018 \| All DD-015 worked examples produce correct slugs \| unit test (NFR-006) \|` |

Also measured: **4** legitimate em-dashes inside the *non-first* columns of VP tables, e.g.
`.../ss-04/BC-2.04.003.md:95` col 3 → `unit test (anchor_table.rs) — **new test required in this story**`.
These must not be flagged either.

## 2.5 Repair specification — Item 2

### R2-RULE (replaces, and subsumes, `TEST_SUFFICIENT_IN_VP_COL`)

Invert the predicate from **value-blacklist** to **shape-whitelist**, scoped positionally.

> **VP-ID-COLUMN CONFORMANCE.** Inside any markdown table whose header row's first cell is
> exactly `VP-NNN`, every data row's first cell MUST parse as a non-empty,
> comma-or-slash-separated list of tokens, each token matching `^VP-\d{3}$`
> (canonical three-digit form). Any first cell that does not parse this way is a
> POL-14 violation reported as `non-conforming VP-NNN column value '<cell>'`.

This is a *property* (well-formedness of an ID column), not a spelling list. It closes the
class: em-dash, en-dash, hyphen, empty cell, `none`, `n/a`, `TBD`, `test-sufficient`,
`?`, `pending`, `see below`, and every future spelling of "no VP yet" all fail the same
single predicate, with no enumeration and no allowlist. It is **not** a skip-list and does
not violate D-039: nothing is suppressed, the surface is *widened*.

### Structural preconditions the repair requires (currently absent from the checker)

1. **Table-context tracking.** `check-placeholders.py` today is purely line-local
   (`for lineno, line in enumerate(lines, 1)`), which is why Mechanism B had to hardcode
   a first-cell literal. The repair requires a small state machine: on a line starting with
   `|`, split into cells; if no header is currently held, this line is the header; skip the
   `:?-{2,}:?` separator row; reset the held header on the first non-`|` line.
2. **Fenced-code-block suppression.** The scanner must ignore lines inside triple-backtick
   fences. Without this, `bc-module-map.md:479` becomes an immediate false positive. This
   is a *grammar* rule (code fences are not spec content), not an exemption for a file.
3. **Cell-count tolerance.** `.../ss-07/BC-2.07.006.md`'s changelog records a prior
   "Edge Cases table cell-count error (`EC-NEW-1/2` had extra column)". The cell splitter
   must not crash or silently skip on ragged rows; a ragged row should still yield a
   first cell.

### MUST NOT be flagged (the false-positive boundary)

| Case | Why | Live count |
|---|---|---|
| Em-dash anywhere in prose, headings, YAML frontmatter, changelog strings | House style | ~1,783 |
| Em-dash in the `Property` or `Proof Method` columns of a VP table | Legitimate parenthetical | 4 |
| Em-dash as the first cell of a **non-VP** table | Different table, different semantics — e.g. all 5 rows in `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/dtu-assessment.md:58,83,93,103,114`, header `\| # \| Service \| Protocol \| Fidelity \| DTU? \| Justification \|`, rows read `\| — \| None \| — \| — \| No \| Pure local input (filesystem) \|` | 5 |
| Multi-VP cells (`VP-001, VP-018`) | Valid citation of two VPs | 1 |
| Anything inside a fenced code block, including the `\| none \| [property description] \| ... \|` remediation template at `bc-module-map.md:479` | Documentation of the fix, not an instance of the defect | 1 |
| The literal header row `\| VP-NNN \| Property \| Proof Method \|` and the `\|---\|` separator | Structural rows, not data rows | 67 + 67 |

### Expected post-repair finding count on the live tree

**55 new findings across 34 files**, plus the 25 pre-existing `[filled by story-writer]`
findings = **80 total**, exit 1. Zero false positives against the current corpus (verified
by enumeration of the entire `VP-NNN`-table population: 55 em-dash + 1 legit multi-VP
+ 1 fenced-template `none` + 111 conforming single VP IDs).

### Residual after this repair (stated explicitly per D-069)

R2-RULE closes the *VP-ID-column* class completely. It does **not** close:

- **Missing VP tables.** A BC with no `## Verification Properties` table at all is
  invisible to a rule that keys on the table header. (Currently benign: 66 BC files,
  67 `VP-NNN` tables → every BC has one. But nothing enforces that; that belongs to
  `check-index-integrity.py`, not here.)
- **Semantically wrong but well-formed VP references.** `| VP-003 |` on a property that
  VP-003 does not actually cover passes R2-RULE and passes `check-id-resolution.py`.
  Not mechanically decidable; requires formal-verifier review.

---

# ITEM 3 — `check-id-resolution.py` non-conforming EC-shape gap

## 3.1 The exact code path

**The reference scanner (lines 321–329):**

```python
        # EC-NNN and EC-NNNx: must be registered in test-vectors.md table rows
        # or holdout pool. Prose mentions and changelog entries are NOT registrations.
        for m in re.finditer(r"\bEC-(\d+)([a-z]?)\b", line):
            ref = f"EC-{m.group(1)}{m.group(2)}"
            if ref not in VALID_EC:
                violations.append(
                    f"{path}:{lineno}: unresolvable EC reference '{ref}' "
                    f"(not in test-vectors.md table rows or holdout pool)"
                )
```

**The registry builder (lines 131–146), same shape assumption:**

```python
            for m in re.finditer(r"\bEC-(\d+)\b", line):
                base_nums.add(int(m.group(1)))
```

## 3.2 Mechanism of the bypass

This is the **opposite** failure mode from Item 2: **the predicate never sees the token.**

`r"\bEC-(\d+)([a-z]?)\b"` requires at least one ASCII digit *immediately* after `EC-`.
In `EC-NEW-1`, the character after `EC-` is `N`. The match attempt fails at offset 0 and,
because `EC-` occurs only once in the token, `finditer` yields nothing at all. Verified:

```
'| EC-NEW-1 | ...'   -> []          (no match — invisible)
'| EC-NEW-10 | ...'  -> []
'| EC-NEW-16 | ...'  -> []
'| EC-029 | ok |'    -> [('029','')]   (matches)
'| EC-015b | ok |'   -> [('015','b')]  (matches)
```

Cross-checked against **every other** ID-family regex in `check_file()`
(`CAP`, `DI`, `DD`, `VP`, `NFR`, `BC`, `ADR`, `HS`, `POL`, `R`, `T`): **none** of them fires
on an `EC-NEW-1` row either. The token is lexically invisible to the entire checker. There
is no "returns clean" step — there is no candidate to evaluate.

Consequence: the loop that produces violations is **iterating over an empty match set**.
The checker is not lenient; it is *blind*. A checker that only validates references it can
already parse can never report an unparseable reference. That is the structural defect.

**Latent dead branch, noted for the repairer:** line 285 reads
`if ref != "VP-TBD":` inside the `VP` family loop. Since the enclosing pattern is
`r"\bVP-(\d+)\b"`, `ref` can never be `"VP-TBD"`. This guard is unreachable — the same
digits-only blindness, in a place where someone *thought* they had handled it. It is
direct evidence that the shape assumption has already caused a reasoning error in this
file, and should be removed or repointed as part of the repair.

## 3.3 Systemic scope — this is a toolchain-wide shape assumption, not one bug

The digits-only EC pattern is replicated across **7** checkers/generators:

| File (all under `/Users/jmagady/Dev/mdlinkcheck-cloud/scripts/spec-lint/`) | Line | Pattern |
|---|---|---|
| `check-id-resolution.py` | 135 | `r"\bEC-(\d+)\b"` (registry build) |
| `check-id-resolution.py` | 145 | `r"\bEC-(\d+)\b"` (holdout pool) |
| `check-id-resolution.py` | 323 | `r"\bEC-(\d+)([a-z]?)\b"` (reference scan) |
| `check-ec-injectivity.py` | 114 | `r"^\|\s*(EC-(\d+[a-z]?))\s*\|(.+)"` |
| `check-counts.py` | 386, 391, 457 | `r"\bEC-(\d+)\b"` |
| `check-holdout-boundary.py` | 56, 64, 114 | `r"EC-(\d+)"` |
| `check-index-integrity.py` | 350, 355, 534 | `r"(EC-\d+)"` |
| `gen-ec-registry.py` | 70 | TV-row EC column |

So the 9 live `EC-NEW-*` rows are simultaneously: unresolvable (invisible to
`check-id-resolution`), excluded from the injectivity **denominator** (invisible to
`check-ec-injectivity`), and absent from EC totals (invisible to `check-counts`).
**Repairing `check-id-resolution.py` alone closes the detection gap but leaves the
counting/coverage gap open.** Recommendation: extract one shared shape predicate
(a module-level `EC_TOKEN` / `is_conforming_ec()` pair) and reuse it, so the shape
definition has exactly one home. See §3.7 residual.

## 3.4 True count — enumerated

Total `EC-NEW` occurrences under `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/`:
**12, across 6 files.** These decompose into two materially different classes:

### Class L — LIVE placeholder IDs (real defects): 9 occurrences, 4 files

Every one is the **first cell of an `## Edge Cases` table data row** — i.e. it is being
*used as* the identifier for a concrete edge case.

| ID | File (absolute) | Line | Offending cell + row |
|---|---|---:|---|
| `EC-NEW-1` | `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-07/BC-2.07.006.md` | 70 | `\| EC-NEW-1 \| ` ``[x](assets/logo.png#anchor)`` ` where ` ``assets/logo.png`` ` exists — clean (image file; fragment ignored) \|` |
| `EC-NEW-2` | `.../ss-07/BC-2.07.006.md` | 71 | `\| EC-NEW-2 \| ` ``[x](scripts/build.sh)`` ` where file does not exist — broken (file-not-found) \|` |
| `EC-NEW-10` | `.../ss-11/BC-2.11.004.md` | 64 | `\| EC-NEW-10 \| ` ``--ignore '[abc'`` ` (unclosed bracket) \| Exit 2; error on stderr; no scanning \|` |
| `EC-NEW-11` | `.../ss-11/BC-2.11.004.md` | 65 | `\| EC-NEW-11 \| ` ``--ignore 'valid/**' --ignore '[bad'`` ` \| Exit 2 on first invalid; no scanning \|` |
| `EC-NEW-12` | `.../ss-12/BC-2.12.005.md` | 64 | `\| EC-NEW-12 \| 0 broken, 0 indeterminate \| stdout empty; stderr: "No broken links found." \|` |
| `EC-NEW-13` | `.../ss-12/BC-2.12.005.md` | 65 | `\| EC-NEW-13 \| 2 broken findings \| stdout: 2 finding lines; stderr: "2 broken link(s) in 1 file(s)." \|` |
| `EC-NEW-14` | `.../ss-14/BC-2.14.004.md` | 62 | `\| EC-NEW-14 \| ` ``mdlinkcheck --help`` ` with no PATH → Exit 0; help text on stdout \|` |
| `EC-NEW-15` | `.../ss-14/BC-2.14.004.md` | 63 | `\| EC-NEW-15 \| ` ``mdlinkcheck --version`` ` → Exit 0; ` ``mdlinkcheck X.Y.Z`` ` on stdout \|` |
| `EC-NEW-16` | `.../ss-14/BC-2.14.004.md` | 64 | `\| EC-NEW-16 \| ` ``mdlinkcheck . --version`` ` (PATH + --version) → Exit 0; --version takes priority per clap \|` |

Note the ID sequence has a gap: `1, 2, 10, 11, 12, 13, 14, 15, 16` — `EC-NEW-3` through
`EC-NEW-9` were previously remediated (see Class H). This is not a numbering artifact of
my enumeration; it is the actual state of the tree.

### Class H — HISTORICAL / prose records of already-remediated defects: 3 occurrences, 3 files

| ID | File (absolute) | Line | Context |
|---|---|---:|---|
| `EC-NEW-3` | `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-07/BC-2.07.005.md` | 24 | YAML frontmatter `modified:` list, quoted: `- "v1.2: P2-M09 — replaced non-conforming EC-NEW-3 with registry-compliant EC-164"` |
| `EC-NEW-1/2` | `.../ss-07/BC-2.07.006.md` | 23 | YAML frontmatter `modified:` list, quoted: `... Fixed pre-existing Edge Cases table cell-count error (EC-NEW-1/2 had extra column)."` |
| `EC-NEW-3` | `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/prd.md` | 721 | Prose: `**EC-164 assigned:** EC-NEW-3 in BC-2.07.005 renamed to EC-164 (P2-M09 deduplication sweep).` |

### Reconciliation with the briefed figure

> **The briefed "11 occurrences across 5 files" is arithmetically explainable and I can
> reproduce it, but it conflates two classes.** 11 = 12 total − 1 (`prd.md`, excluded
> because it is not a BC file); 5 files = the 5 *BC* files. The briefed file list
> included `ss-07/BC-2.07.005.md`, which contains **no live defect at all** — its only
> `EC-NEW` occurrence is the changelog line recording that the defect was already fixed
> in v1.2 (`EC-NEW-3` → `EC-164`).
>
> **Corrected magnitudes:**
> - **Live defects requiring spec remediation: 9 occurrences across 4 files**
>   (`ss-07/BC-2.07.006.md`, `ss-11/BC-2.11.004.md`, `ss-12/BC-2.12.005.md`, `ss-14/BC-2.14.004.md`).
> - **Historical records that MUST NOT be flagged: 3 occurrences across 3 files**
>   (`ss-07/BC-2.07.005.md:24`, `ss-07/BC-2.07.006.md:23`, `prd.md:721`).
> - `ss-07/BC-2.07.006.md` is the only file appearing in **both** classes.
>
> This distinction is not cosmetic. `check-placeholders.py` already has an explicit
> doctrine for exactly this (`is_historical_changelog_line()`, lines 59–79, plus the
> module docstring's "Scoping rule"). `check-id-resolution.py` has **no such doctrine**.
> If the repair flags Class H, the only ways to go green are to rewrite the changelog
> (destroying the audit trail of the P2-M09 remediation) or to add a suppression
> (forbidden by D-039). Neither is acceptable. **The historical-changelog scoping rule
> must be ported to `check-id-resolution.py` as part of this repair.**

## 3.5 Class-level repair — and the false-positive landscape that constrains it

D-069 requires closing the class, not the literal string `EC-NEW-`. I empirically tested
three candidate class predicates against the entire `.factory/specs/` corpus. This is the
part of the design that matters most, because the naive generalization is badly wrong.

**First, the hazard.** Enumerating every token of shape
`(CAP|DI|DD|VP|NFR|BC|ADR|HS|POL|EC|SS|TV)-<non-digit-start>` yields **211+ occurrences**
of legitimate non-ID usage:

| Token | Count | Why it is NOT a defect |
|---|---:|---|
| `VP-NNN` | 94 | Metasyntax — the literal table-column header and format documentation |
| `VP-INDEX` | 43 | Document name (`VP-INDEX.md`) |
| `VP-TBD` | 26 | A *known, already-policed* placeholder (POL-14 / `check-placeholders.py`) — not this checker's job |
| `BC-INDEX` | 16 | Document name |
| **`EC-collision`** | **14** | **A changelog tag, not an ID.** e.g. `.../ss-14/BC-2.14.001.md:24`: `- "v1.3: (EC-collision) EC-009 renamed to EC-184 ..."`. It means "EC collision remediation". |
| `TV-S001`..`TV-S016`, `TV-BV013` | ~40 | A legitimate TV sub-family naming scheme (S = structural, BV = boundary-value) |
| `DD-NNN`, `DI-NNN`, `CAP-NNN`, `EC-NNN`, `EC-NNNs`, `SS-NN`, `TV-NNNb`, `EC-ID` | ~22 | Metasyntax in format documentation |
| `BC-to`, `VP-to`, `BC-level`, `NFR-level`, `DI-number` | 13 | Hyphenated English compounds ("BC-to-module map", "VP-to-BC mapping") |
| `BC-H1` | 1 | Prose at `prd.md:780`: "BC-H1 is authoritative per bc_h1_is_title_source_of_truth policy" |
| `HS-INDEX` | 1 | Document name |

> **Correction to the prior audit.** `ws3-skip-list-audit.md` lines 252 and 325 propose
> that the repair should flag `EC-collision` alongside `EC-NEW-N`. **That recommendation
> must be rejected.** `EC-collision` is a changelog label appearing 14 times in quoted
> YAML frontmatter; flagging it would produce 14 false positives and would pressure the
> operator into rewriting remediation history. Its lowercase suffix is precisely what
> distinguishes prose-compound from would-be-ID, and the repair rule below exploits that.

**Candidate predicates, measured:**

| Predicate | Total hits | True positives | False positives |
|---|---:|---:|---|
| **P1** `\b(CAP\|DI\|DD\|VP\|NFR\|BC\|ADR\|HS\|POL\|EC)-[A-Za-z][A-Za-z0-9]*-\d+\b` (triple-segment) | 12 | 12 | **0** |
| **P2** `\b(…)-[A-Z][A-Za-z0-9]*\b` (any uppercase suffix) | 211 | 12 | **199** (`VP-NNN`, `VP-INDEX`, `BC-INDEX`, `DD-NNN`, …) |
| **P3** P2 minus metasyntax `N{2,}[a-z]?s?`, minus `INDEX`, minus `ID` | 39 | 12 | **27** (26 × `VP-TBD` — already policed elsewhere; 1 × `BC-H1` prose) |

### R3-RULE (the recommended repair)

Two layers. Layer A is the enforcement backbone; Layer B is the class-level net.

> **R3-A — ID-COLUMN CONFORMANCE (positional, zero-FP, catches all 9 live defects).**
> Inside any markdown table whose header row's first cell is `EC` or `ID`, every data
> row's first cell MUST match `^~?~?EC-\d{1,4}[a-z]?~?~?$` (strikethrough-tolerant for
> retired rows). Any other first-cell content in an EC-ID column is reported as
> `non-conforming EC ID in ID column '<cell>'` — *independently* of whether it resolves,
> because an unparseable ID cannot be resolved at all.
>
> **R3-B — WOULD-BE-ID SHAPE (lexical, class-level, applies everywhere).**
> Any token matching `\b(CAP|DI|DD|VP|NFR|BC|ADR|HS|POL|EC)-[A-Za-z][A-Za-z0-9]*-\d+\b`
> — a registered ID prefix, followed by an **alphabetic segment**, followed by a hyphen
> and a **numeric segment** — is a *non-conforming ID shape*: it is structurally
> announcing itself as an identifier while carrying an interpolated word where the
> registry expects only digits. Report as
> `non-conforming <FAMILY> ID shape '<token>' (expected <FAMILY>-NNN)`.
>
> **R3-C — HISTORICAL SCOPING (ported from `check-placeholders.py`).**
> R3-B findings are suppressed when the match sits inside a quoted YAML-changelog string
> on a line bearing a version marker — the same predicate as
> `check-placeholders.is_historical_changelog_line()` (quote-bracketed match **AND** the
> line matches `v\d+\.\d+`). This is a *scoping grammar* — "a quoted historical record is
> not a live reference" — identical in kind to the rule the sibling checker already
> enforces, and applied by shape, not by file or line number. It is not a skip-list.

**Why the triple-segment shape is the right class boundary.** The distinguishing property
of a placeholder ID is not the word `NEW`. It is that the author wrote *`<FAMILY>-<word>-<number>`*
— they knew a number was needed, and knew they did not have a registered one, so they
interpolated a qualifier segment. That shape is:
- **Sufficient** for the whole observed class (`EC-NEW-1`…`EC-NEW-16`).
- **Extensible without enumeration** to `EC-TMP-4`, `EC-TODO-7`, `EC-DRAFT-2`,
  `VP-NEW-3`, `BC-TBD-9`, `DI-PENDING-1` — none of which exist today and all of which
  would be caught, with zero code change.
- **Precise**: 0/12 false positives on a 133-file, 1.4 MB corpus.
- **Grammar, not blacklist**: it does not mention `NEW`.

### MUST NOT be flagged (the false-positive boundary)

| Case | Rule that protects it |
|---|---|
| Valid `EC-NNN`, `EC-NNNx` (`EC-029`, `EC-015b`, `EC-164`) | Requires an alphabetic segment; digits-only never matches R3-B; matches R3-A's whitelist |
| `EC-collision` (14×, changelog tag) | No trailing `-\d+` segment ⇒ fails R3-B. Additionally protected by R3-C. |
| `BC-to`, `VP-to`, `BC-level`, `NFR-level`, `DI-number` (13×) | No trailing `-\d+` segment |
| `VP-NNN`, `DD-NNN`, `DI-NNN`, `CAP-NNN`, `EC-NNN`, `EC-NNNs`, `SS-NN`, `EC-ID`, `TV-NNNb` (~116×) | No trailing `-\d+` segment (metasyntax) |
| `VP-INDEX`, `BC-INDEX`, `HS-INDEX` (60×) | No trailing `-\d+` segment |
| `BC-H1` (`prd.md:780`) | No trailing `-\d+` segment — this is what kills P3's only FP |
| `TV-S012`, `TV-BV013` (~40×) | `TV` is deliberately **not** in the family list — this checker does not resolve TV IDs |
| `VP-TBD` (26×) | `VP-TBD` is POL-14's jurisdiction (`check-placeholders.py`), and has no trailing `-\d+`. Do not double-report. |
| `ADR-008-slug-clean-room-reimplementation` and other ADR filenames | `ADR-008` is digits-first ⇒ conforming; the trailing slug is not a `-\d+` segment after an alphabetic segment |
| Historical changelog records: `ss-07/BC-2.07.005.md:24`, `ss-07/BC-2.07.006.md:23`, `prd.md:721` | R3-C |
| Anything inside a fenced code block | Same fence-suppression grammar as R2 |

### Expected post-repair finding count on the live tree

**9 findings across 4 files** (Class L only), exit 1. Class H's 3 occurrences are scoped
out by R3-C. Zero false positives.

## 3.6 Interaction with the existing EC-resolution rule

R3-A/B run **in addition to**, not instead of, the existing
`\bEC-(\d+)([a-z]?)\b` → `VALID_EC` resolution check. A well-formed-but-unregistered
`EC-999` must still be caught (it is today — that is selftest 1). The two rules answer
different questions: *"is this token a parseable EC ID?"* (new) and *"does this parseable
EC ID resolve?"* (existing). Emit distinct message prefixes so the selftests can
distinguish them:

- existing: `unresolvable EC reference 'EC-999' (not in test-vectors.md table rows or holdout pool)`
- new: `non-conforming EC ID shape 'EC-NEW-1' (expected EC-NNN)`

## 3.7 Residual after this repair (stated explicitly per D-069)

R3-A + R3-B close the class of **would-be-ID tokens with an interpolated alphabetic
segment**, and R3-A additionally closes **any** malformed first cell in an EC-ID column.
They do **not** close:

1. **Non-conforming shapes without a trailing numeric segment.** A hypothetical
   `| EC-TODO | ... |` in an Edge Cases table is caught by **R3-A** (column-scoped) but a
   bare `EC-TODO` in *Postconditions prose* is caught by neither rule. This is the
   unbounded residual, and it is unbounded on purpose: the only predicate that would
   catch it (`EC-` + uppercase word) is P2/P3, which costs 199 / 27 false positives.
   **I am consciously trading unbounded recall on prose-only non-conforming shapes for
   zero false positives.** If the operator prefers the opposite trade, P3 plus an
   explicit metasyntax grammar is the alternative — but it will double-report all 26
   `VP-TBD` and needs a story for `BC-H1`.
2. **The counting/coverage gap (§3.3).** Even after R3 lands, `check-ec-injectivity.py`,
   `check-counts.py`, and `check-holdout-boundary.py` still cannot *see* a non-conforming
   EC row, so it stays out of their denominators. Closing that requires the shared
   shape-predicate extraction. **This is a separate work item and should be tracked as
   such — do not let R3's green status imply the toolchain is shape-safe.**
3. **The dead `if ref != "VP-TBD":` guard at line 285.** Should be removed as part of the
   repair; it is unreachable and actively misleading.

---

# 4. Negative test vectors

## 4.1 Existing convention (observed, must be followed)

- Fixtures live at `/Users/jmagady/Dev/mdlinkcheck-cloud/scripts/spec-lint/selftest/fixtures/`,
  named `bad-<defect>.md`, ~300–600 bytes, YAML frontmatter with
  `bc_id: BC-2.01.SELFTEST`, then the minimal table that carries the defect.
- Harness `/Users/jmagady/Dev/mdlinkcheck-cloud/scripts/spec-lint/selftest/run-selftests.sh`
  uses a mandatory **two-step clean-pass / defect-fail** pattern per test (header lines
  1–20): (a) checker exits 0 on the isolated temp tree *before* injection; (b) checker
  exits non-zero *after* `cp`-ing the fixture in. This makes a vacuous test structurally
  impossible. `EXPECTED_TEST_COUNT=49` at line 27 **must be incremented** by the number of
  new cases added.
- Every test runs under `SPEC_LINT_REPO_OVERRIDE="$T"` against `mktemp -d`, never the real
  spec tree.
- Two pre-flight structural guards (lines 41–43) will reject the repair if it introduces
  any variable matching
  `(ALLOWLIST|_DEFERRAL|SKIP_LIST|SKIP_SET|KNOWN_COLLISIONS|KNOWN_VIOLATIONS|KNOWN_ISSUES|WHITELIST|SUPPRESS_SET)\s*[=:]`.
  **The R3-C historical-scoping predicate must therefore be implemented as a *function*
  (mirroring `is_historical_changelog_line`), not as a named set.** Naming it
  `HISTORICAL_SKIP_SET` would trip guard 2 and exit 2.

## 4.2 Empirical confirmation that the proposed vectors currently PASS

Built an isolated tree (`SPEC_LINT_REPO_OVERRIDE` → `mktemp -d`) containing a
`test-vectors.md` stub, then injected both proposed defect fixtures:

```
--- baseline clean tree ---
Check passed: 1 spec files checked — no VP-TBD, SS-TBD, [filled by], or test-sufficient placeholders
PH_EXIT=0
Check passed: 1 files checked — all ID references resolve
IR_EXIT=0
--- after injecting BOTH proposed defect vectors ---
Check passed: 3 spec files checked — no VP-TBD, SS-TBD, [filled by], or test-sufficient placeholders
PH_EXIT=0          <-- BUG: em-dash VP row not detected
Check passed: 3 files checked — all ID references resolve
IR_EXIT=0          <-- BUG: EC-NEW-1 not detected
```

Both vectors are confirmed **currently passing (exit 0) = the bug**. They are therefore
valid negative tests: each will flip to exit 1 only if the repair actually works.

## 4.3 Vector specifications

### NV-1 — `bad-placeholder-vp-emdash.md` → `check-placeholders.py`

Positive-detection vector for R2-RULE.

```markdown
---
bc_id: BC-2.01.SELFTEST
title: "Selftest fixture: em-dash in VP-NNN column"
lifecycle_status: active
introduced: v0.0.0
modified: []
deprecated: null
---

# BC-2.01.SELFTEST: Selftest — em-dash in VP-NNN column

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| — | Directory link with fragment → broken (target-is-directory) | unit test |
```

| Field | Value |
|---|---|
| Checker | `check-placeholders.py` |
| Exit BEFORE repair | **0** (verified empirically — this is the bug) |
| Exit AFTER repair | **1**, message `non-conforming VP-NNN column value '—'` |
| Harness placement | copy to `$T/.factory/specs/behavioral-contracts/ss-01/SELFTEST-vp-emdash.md`, mirroring selftest 3 |
| Note | The H1 deliberately contains an em-dash in prose, and the `Property` cell an arrow. Both must remain unflagged — the fixture doubles as a same-file FP guard. |

### NV-2 — `good-placeholder-vp-column.md` → `check-placeholders.py` (**anti-vector**)

Negative-detection (false-positive) vector. Without this, R2-RULE has no guard against
over-firing, and the 1,787-em-dash blast radius is untested.

```markdown
---
bc_id: BC-2.01.SELFTEST
title: "Selftest fixture: legitimate em-dash and multi-VP usage"
lifecycle_status: active
introduced: v0.0.0
modified: []
deprecated: null
---

# BC-2.01.SELFTEST: Selftest — em-dash is legal in prose

Prose with an em-dash — like this one — must never be flagged.

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-001 | Something — with an em-dash in the Property column | unit test — new test required |
| VP-001, VP-018 | Multi-VP citation is legitimate | unit test |

## Unrelated Table

| # | Service | Protocol | Fidelity | DTU? | Justification |
|---|---------|----------|----------|------|---------------|
| — | None | — | — | No | Pure local input (filesystem) |

## Remediation Template (documentation, not an instance)

```markdown
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| none | [property description] | integration / acceptance test |
```
```

| Field | Value |
|---|---|
| Checker | `check-placeholders.py` |
| Exit BEFORE repair | **0** |
| Exit AFTER repair | **0** — must STAY 0 |
| Harness pattern | Deviates from the standard two-step: this fixture is injected and the assertion is that the checker *still* exits 0. Recommend running it as the *clean-tree* step of NV-1's test case, so NV-1's mandatory clean-pass assertion doubles as the FP guard and the harness's two-step invariant is preserved rather than bypassed. |
| Guards against | The `dtu-assessment.md` 5-row pattern, the `BC-2.06.001.md:109` multi-VP cell, the `bc-module-map.md:479` fenced template, and prose/other-column em-dash |
| Requires `VP-001`, `VP-018` registered in the temp tree's `VP-INDEX.md` if `check-id-resolution` is also run against this fixture |

### NV-3 — `bad-ec-nonconforming-shape.md` → `check-id-resolution.py`

Positive-detection vector for R3-A + R3-B.

```markdown
---
bc_id: BC-2.01.SELFTEST
title: "Selftest fixture: non-conforming EC ID shape"
lifecycle_status: active
introduced: v0.0.0
modified: []
deprecated: null
---

# BC-2.01.SELFTEST: Selftest — non-conforming EC ID shape

## Edge Cases
| EC | Description |
|----|-------------|
| EC-001 | A conforming, registered edge case |
| EC-NEW-1 | A placeholder edge case that was never registered |
```

| Field | Value |
|---|---|
| Checker | `check-id-resolution.py` |
| Exit BEFORE repair | **0** (verified empirically — this is the bug) |
| Exit AFTER repair | **1**, message `non-conforming EC ID shape 'EC-NEW-1' (expected EC-NNN)` |
| Harness placement | temp tree with `$T/.factory/specs/prd-supplements/test-vectors.md` containing `\| TV-001 \| EC-001 \| ...` (registers EC-001, exactly as selftest 1 does), fixture copied to `$T/.factory/specs/behavioral-contracts/ss-01/SELFTEST-ec-shape.md` |
| Note | The conforming `EC-001` row on line above ensures the fixture fails **only** for the shape violation, not for unregistered-EC — mirroring selftest 1b's technique of pre-registering EC-001 to isolate the assertion |

### NV-4 — `bad-ec-nonconforming-shape-generic.md` → `check-id-resolution.py`

**The D-069 class-closure vector.** NV-3 alone could be satisfied by a checker that
hardcodes `EC-NEW-`. This vector proves the rule is a grammar. It uses a family and a
qualifier word that appear **nowhere** in the repository.

```markdown
---
bc_id: BC-2.01.SELFTEST
title: "Selftest fixture: class-level non-conforming ID shapes"
lifecycle_status: active
introduced: v0.0.0
modified: []
deprecated: null
---

# BC-2.01.SELFTEST: Selftest — class-level non-conforming ID shapes

## Edge Cases
| EC | Description |
|----|-------------|
| EC-001 | A conforming, registered edge case |
| EC-DRAFT-7 | Non-conforming shape, qualifier word never used in this repo |

## Postconditions
1. Also cites DI-PENDING-2 in prose, which is a non-conforming DI shape.
```

| Field | Value |
|---|---|
| Checker | `check-id-resolution.py` |
| Exit BEFORE repair | **0** |
| Exit AFTER repair | **1**, with **two** findings: `non-conforming EC ID shape 'EC-DRAFT-7'` and `non-conforming DI ID shape 'DI-PENDING-2'` |
| Guards against | A repair that hardcodes the literal `EC-NEW-` (would exit 0 → test fails, correctly) and against a repair scoped only to the EC family (would emit 1 finding, not 2) |
| Recommended assertion | Not merely exit ≠ 0, but a stdout match on **both** messages — otherwise the test is satisfiable by a family-scoped hardcode |

### NV-5 — `good-ec-historical-changelog.md` → `check-id-resolution.py` (**anti-vector**)

False-positive guard for R3-C, and the guard for the three Class-H occurrences.

```markdown
---
bc_id: BC-2.01.SELFTEST
title: "Selftest fixture: historical EC records must not be flagged"
lifecycle_status: active
introduced: v0.0.0
modified:
  - "v1.2: P2-M09 — replaced non-conforming EC-NEW-3 with registry-compliant EC-001"
  - "v1.3: (EC-collision) EC-001 canonical owner confirmed per test-vectors.md registry."
deprecated: null
---

# BC-2.01.SELFTEST: Selftest — historical records and prose compounds

The BC-to-module map and the VP-to-BC mapping are BC-level concerns; BC-H1 is
authoritative. Format metasyntax such as EC-NNN, VP-NNN, DD-NNN, and EC-NNNs
documents the ID grammar and is not a reference.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-001 | A conforming, registered edge case |
```

| Field | Value |
|---|---|
| Checker | `check-id-resolution.py` |
| Exit BEFORE repair | **0** |
| Exit AFTER repair | **0** — must STAY 0 |
| Guards against | R3-C regression (flagging the changelog `EC-NEW-3`), and against P2/P3-style over-firing on `EC-collision`, `BC-to`, `VP-to`, `BC-level`, `BC-H1`, `EC-NNN`, `VP-NNN`, `DD-NNN`, `EC-NNNs` |
| Harness pattern | Same recommendation as NV-2: serve as the clean-tree step of NV-3's or NV-4's test case so the two-step invariant is preserved |

### Summary

| Vector | Checker | Before | After | Kind |
|---|---|---:|---:|---|
| NV-1 `bad-placeholder-vp-emdash.md` | check-placeholders | 0 | 1 | detection |
| NV-2 `good-placeholder-vp-column.md` | check-placeholders | 0 | 0 | FP guard |
| NV-3 `bad-ec-nonconforming-shape.md` | check-id-resolution | 0 | 1 | detection |
| NV-4 `bad-ec-nonconforming-shape-generic.md` | check-id-resolution | 0 | 1 (×2 msgs) | class closure (D-069) |
| NV-5 `good-ec-historical-changelog.md` | check-id-resolution | 0 | 0 | FP guard |

`EXPECTED_TEST_COUNT` must go from **49** to **52** if NV-2 and NV-5 are folded into the
clean-tree steps of NV-1/NV-3 (3 new cases: NV-1, NV-3, NV-4), or to **54** if all five
are standalone cases. The folded arrangement is preferred because it keeps every case
inside the two-step clean-pass/defect-fail invariant.

---

# 5. Design question requiring operator resolution — sequencing

## 5.1 The tradeoff

R2-RULE will introduce **55 new failures across 34 BC files** on real spec content the
moment it lands. R3-RULE will introduce **9 new failures across 4 BC files**. Total: **64
new findings across 37 distinct files** (`ss-07/BC-2.07.006.md`, `ss-11/BC-2.11.004.md`,
`ss-12/BC-2.12.005.md`, and `ss-14/BC-2.14.004.md` carry both defect types).

Material context bearing on the decision:

1. **`spec-lint` is ADVISORY**, not a required status check, until the Phase-1 convergence gate.
2. **`check-placeholders.py` is ALREADY RED** — it exits 1 today on 25 `[filled by story-writer]`
   occurrences. Option (a)/(c) does not turn a green job red; it deepens an existing red.
   Marginal signal cost is near zero. (`check-id-resolution.py`, by contrast, is currently
   green and *would* go red.)
3. **The two remediations have very different costs and blockers.**
   - *Item 3 (9 EC rows)* is mechanical but **blocked on registry authority**: each
     `EC-NEW-N` needs a real `EC-NNN` allocated and a row added to `test-vectors.md`.
     That is an EC-registry allocation decision, not a text edit, and it must not collide
     with existing EC numbering (`check-ec-injectivity.py` will police that).
   - *Item 2 (55 VP rows)* is **blocked on adjudication**: as `ws3-skip-list-audit.md:367`
     already flags, it is unknown whether each em-dash row is "intentionally VP-free" or
     genuine Phase-1b residue. Resolving 55 rows requires either allocating ~55 VPs in
     `VP-INDEX.md` or a formal-verifier ruling that some properties need no VP — and if
     the latter, there is currently **no conforming vocabulary** for "deliberately no VP",
     which is itself an open spec-format question (see §5.3).
4. **The bypasses are load-bearing on the convergence gate.** As long as they exist, the
   Phase-1 gate can be passed by content the gate was designed to reject. Every day the
   bypass stays open, more spec content can be authored in the undetected shape — the
   defect population is *growing*, which argues against "fix content first".

## 5.2 Recommendation: **(c) — repair the checkers now, accept a red advisory job, fix the rows on a tracked burn-down**

with one qualification: **(c) then converge to (a)**. Justification:

1. **Detection must precede remediation, or remediation is unverifiable.** If the rows are
   fixed first (option b), nothing proves the fix is complete — the very checker that
   would confirm "0 remaining" does not exist. You would be asserting completeness from a
   manual enumeration (this document), which is exactly the fragile position that produced
   the 34/55 and 11/5 figures needing re-verification. Land the checker first and the count
   becomes machine-attested and monotonic.
2. **It stops the bleeding immediately.** The moment R2/R3 land, no *new* em-dash VP row
   or `EC-NEW-*` row can be authored without the advisory job going redder. Option (b)
   leaves the intake open for the entire duration of a 55-row adjudication.
3. **The advisory window is exactly the right instrument, and it is already in use.**
   `check-placeholders.py` is already red on 25 known-advisory items. Adding 55 to a red
   job costs one line in a burn-down table. It costs nothing in gating signal, because
   there is no gating signal to lose yet.
4. **Option (a) is not actually available as stated.** "Repair then fix all spec rows"
   presumes the rows *can* be fixed promptly. They cannot: 55 rows need VP allocation or a
   formal-verifier ruling, and 9 need EC-registry allocation. Option (a) is option (c)
   with an optimistic schedule attached. Better to name the burn-down honestly.
5. **Option (b) additionally risks the wrong fix.** Without the checker defining the
   conforming shape, an author "fixing" a row might write `| none |` or `| n/a |` — which
   under R2-RULE is *equally* non-conforming. Landing the rule first makes the target
   unambiguous.

**The one hard constraint on option (c):** the Phase-1 convergence gate must not be
crossed with a red `spec-lint`. So the burn-down is not open-ended — it is a blocker on
the gate. Concretely:

| Step | Action | Blocks |
|---|---|---|
| 1 | Land R2 + R3 + NV-1..NV-5; `spec-lint` goes red with 64 findings (89 total incl. the 25 `[filled by]`) | — |
| 2 | Record 64 as a tracked, machine-attested burn-down baseline; assert monotonic non-increase in CI | — |
| 3 | Formal-verifier adjudicates the 55 em-dash rows: allocate VP or rule "no VP required" (and if the latter, define the conforming vocabulary first — §5.3) | Phase-1 gate |
| 4 | Allocate 9 real `EC-NNN` for `EC-NEW-1/2/10–16`, add `test-vectors.md` rows, update the 4 BC files | Phase-1 gate |
| 5 | Extract the shared EC shape predicate so `check-ec-injectivity`/`check-counts`/`check-holdout-boundary` also see non-conforming shapes (§3.3) | Phase-1 gate |
| 6 | `spec-lint` green (modulo the 25 `[filled by]`, separately tracked) → promote to **required** status check | — |

**I am not deciding this.** Steps 3–4 commit named roles to work of currently unknown
size, and step 3 may surface a spec-format change. That is an operator call.

## 5.3 Second decision this forces (please rule on it together with §5.2)

If the formal-verifier rules that some of the 55 properties legitimately need no VP, then
R2-RULE as written will flag them forever, because it whitelists **only** `VP-\d{3}`.
There must be a **conforming way to say "no VP required"**, or the repair converts a
detection gap into an unsatisfiable rule. Options:

- **(i)** Every property gets a real VP. 55 VP allocations. R2-RULE unchanged. Cleanest,
  most expensive, and inflates `VP-INDEX.md`.
- **(ii)** Define a reserved sentinel — e.g. `VP-NONE` — admitted by R2-RULE **only** when
  the `Proof Method` column is non-empty and a sibling justification column/row is present.
  This is a *grammar extension*, not a suppression: the sentinel is a positive, greppable,
  reviewable assertion ("we considered this and no VP is required"), unlike an em-dash
  which is indistinguishable from an omission. **This is what I would recommend**, because
  the entire defect here is that `—` is ambiguous between "no VP needed" and "nobody filled
  this in", and a sentinel removes the ambiguity that made the bypass possible.
- **(iii)** Delete the VP-less rows from the VP tables entirely. Cheapest, but silently
  drops stated properties from the record. Not recommended.

Note that (ii) must be implemented as an admitted *shape in the grammar*, not as a
`SKIP_SET`/`ALLOWLIST` variable — the latter trips `run_suppression_guard` (exit 2) and
violates D-039.

---

# 6. Compliance ledger

| Constraint | Status |
|---|---|
| READ-ONLY; no edits under `scripts/` or `.factory/specs/**` | Honored. Only file written: `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/cycles/phase-1d/ws3-phase2-checker-repair-design.md` |
| No fixtures created or modified; `run-selftests.sh` untouched | Honored. NV-1..NV-5 are *specifications* in this document. Empirical confirmation used `mktemp -d` trees only. |
| No `git commit` / `push` / `gh pr create` / branch ops | Honored. No git write command issued. |
| `gen-bc-traceability.py` write mode (BI-041) | Never invoked, in any mode. |
| Repo-root verification (BI-021/BI-043) | Verified: override and `parent.parent.parent` heuristic both resolve to `/Users/jmagady/Dev/mdlinkcheck-cloud`. Green results interrogated, not assumed. |
| No allowlists / skip-lists proposed (D-039) | Honored. R3-C is a shape predicate implemented as a function (mirroring the existing `is_historical_changelog_line`), deliberately **not** a named set — a named set would trip `run_suppression_guard`. Both repairs *widen* the detection surface; nothing is suppressed. |
| Class closure, not instance patching (D-069) | R2-RULE inverts value-blacklist → shape-whitelist (closes all null spellings). R3-B is a grammar with no mention of `NEW` (closes `EC-TMP-*`, `VP-DRAFT-*`, etc.). NV-4 is the enforcing test. **Residuals stated explicitly** in §2.5 and §3.7, including the unbounded one (prose-only non-conforming shapes with no trailing numeric segment). |
| Absolute paths throughout | Honored. |
| Prior-audit figures independently re-verified | 34/55 **confirmed exactly**. 11/5 **reproduced but decomposed**: 9 live defects / 4 files, 3 historical records / 3 files. Prior audit's proposal to flag `EC-collision` **rejected with evidence** (14 FPs). |
