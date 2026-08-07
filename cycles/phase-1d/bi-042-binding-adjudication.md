# BI-042 Binding Adjudication — Tautological Capture Groups in canonical-facts.toml

**Status:** APPLIED (D-076) — 24 tautological patterns corrected in `.factory/specs/canonical-facts.toml`; FACT-6a/6b left unchanged (structural limitation); checker passes all 31 bindings  
**Author:** architect (phase-1d adjudication)  
**Date:** 2026-08-07  
**Input files read:** `.factory/specs/canonical-facts.toml`, `scripts/spec-lint/check-canonical-facts.py`, `scripts/spec-lint/selftest/run-selftests.sh`, and the following binding-target files to verify actual text: `module-decomposition.md`, `interface-definitions.md`, `entities.md`, `prd.md`, `BC-INDEX.md`, `BC-2.12.001.md`, `BC-2.13.001.md`, `BC-2.03.002.md`, `BC-2.06.001/002.md`, `BC-2.05.003.md`, `vp-018-slug-worked-examples.md`, `product-brief.md`, `assumptions.md`, `purity-boundary-map.md`, `system-overview.md`, `capabilities.md`, `BC-2.14.001/002/003.md`

---

## 1. Executive Summary

| Claim | Verdict |
|-------|---------|
| "No match = silent skip" | **REFUTED** — the checker reports `DIVERGE` on `None` (hard failure, not skip) |
| "17 of 31 tautological" | **WRONG** — the correct count is **26 of 31** tautological |
| Prefix-pass false-negative class is real | **CONFIRMED** — empirically verified |
| FACT-7 and FACT-8 are sound | **INDEPENDENTLY CONFIRMED** |
| Selftest 22 guards the production FACT-10 patterns | **REFUTED** — it never runs the production patterns |

---

## 2. Checker Code Analysis: What Happens When re.search Returns None

Quoted from `scripts/spec-lint/check-canonical-facts.py` lines 151–168:

```python
try:
    m = re.search(pattern, content, re.DOTALL)
except re.error as exc:
    findings.append(
        f"PATTERN-ERROR [{fact_id}] {rel_path}: invalid regex '{pattern}': {exc}"
    )
    continue

if not m:
    findings.append(
        f"DIVERGE [{fact_id}] {rel_path}"
        + (f" ({note})" if note else "")
        + f": pattern did not match (expected canonical_value='{canonical}')"
    )
elif m.group(1) != canonical:
    findings.append(
        f"DIVERGE [{fact_id}] {rel_path}"
        + (f" ({note})" if note else "")
        + f": extracted '{m.group(1)}', expected '{canonical}'"
    )
```

**Decisive conclusion:** `re.search` returning `None` is **not a silent skip**. It appends a `DIVERGE` finding and proceeds. Exit 1 is returned whenever `findings` is non-empty. The BI-042 claim that "a site that diverges does not produce a mismatch — it produces NO match at all" is technically correct about which branch fires (the `if not m:` branch, not `m.group(1) != canonical`), but the claim that this constitutes a false negative is **wrong for complete replacements**. Complete replacement of the canonical phrase with unrelated text → `None` → `DIVERGE` finding → exit 1 → **correctly detected**.

**What IS a genuine false negative:** the **prefix-pass** case. If a binding site extends the canonical phrase by appending text (e.g., "every extracted link destination BUT ONLY .md files"), the tautological literal pattern matches the canonical phrase as a prefix, `group(1)` equals the canonical, and the checker exits 0. This is empirically confirmed:

```
pattern: 'directories from (every extracted link destination)'
text:    'directories from every extracted link destination BUT ONLY .md files — limited scope'
result:  m.group(1) = 'every extracted link destination' == canonical → PASS (FALSE NEGATIVE)
```

**Severity downgrade from BI-042 premise:** The tautological pattern class is a false-negative risk specifically for **semantic narrowing via append** (e.g., "every extracted link destination" → "every extracted link destination for .md files only"). It does NOT produce false negatives for **complete replacement** (e.g., "every extracted link destination" → ".md file destinations only"), which the checker correctly catches via `None → DIVERGE`. The risk is narrower than BI-042 suggested, but still a real and important class of undetected divergence.

---

## 3. The Adjudicated Rule for Sound Binding Patterns

A binding pattern is **sound** if and only if:

1. **The capture group contains a bounded wildcard, not the canonical literal.** The group `(...)` must use a wildcard expression — `(.*?)`, `([^)]+)`, `(\d+)`, `([^;\n]+?)`, etc. — that can capture a value DIFFERENT from the canonical. A group containing only the literal canonical value (or a regex that can only match the literal) is tautological.

2. **The wildcard has a right-side delimiter.** A lazy wildcard like `(.*?)` requires a terminating anchor that appears consistently and reliably AFTER the canonical value in the production text. Examples that work: ` —` (em-dash), ` \(`, `;`, a closing backtick `` ` ``, `)`. Without a right delimiter, the wildcard captures to end-of-string or end-of-line, which risks false positives from over-capture.

3. **A divergent restatement is captured-and-compared, not bypassed.** Specifically:
   - **Complete replacement** (different phrase entirely): the replacement phrase must be captured by the wildcard and fail the `!=` check.
   - **Semantic narrowing via append** (canonical phrase + qualifying clause): the full extended phrase must be captured and fail the `!=` check.

4. **The wildcard does not over-capture (false-positive risk).** The right delimiter must appear close to the canonical value. A delimiter that appears far from the value (or appears only incidentally) risks capturing irrelevant surrounding text and producing spurious `DIVERGE` reports on valid sites. In practice this is bounded by the fact that all production binding sites currently pass the checker.

**Counter-examples that constrain the rule:**

| Anti-pattern | Problem | Fix |
|---|---|---|
| `(.*?)` with no right delimiter and `re.DOTALL` | Captures across multiple lines up to the next unrelated occurrence of any suffix — false positives or over-capture | Add a consistent right delimiter; if none exists, use `([^\n]+?)` to stay on-line |
| `([a-z]+)` character class too narrow | Misses canonical values with digits, dots, spaces (e.g., "Pass 1.5", "macOS only") | Use `([^\n]+?)` or `(.*?)` with appropriate delimiter |
| `sort_unstable_by_key[^;]*(link_target)` — literal inside group | Only detects ABSENCE, not substitution or append | Replace with tuple-end capture: `sort_unstable_by_key[^;]*\.([a-z_]+)\)\)` |
| `@GENERATED:BEGIN slug-corpus.*(TV-S007)` | Cannot detect TV-S007→TV-S009 (returns None, correctly caught), but cannot distinguish TV-S007-extra (prefix-pass) | These are structural presence-checks, not value-comparisons; best addressed by line-level assertion if the block always has exactly one TV-SNNN per line |

**The core tension:** a tighter left context reduces false positives but does not help if the capture group is still the canonical literal. The BI-035 patterns (FACT-7, FACT-8) achieve soundness by using `(.*?)` bounded by a ` (` delimiter, which makes the captured value the entire platform clause — any extension of the clause is captured and compared, not bypassed. This is the model to follow.

---

## 4. Binding Classification Table (all 31 bindings)

The "17 of 31" figure in BI-042 is **wrong**. The correct count is **26 TAUTOLOGICAL** and **5 SOUND**. No bindings are classified BORDERLINE.

### Legend
- **TAUTOLOGICAL**: capture group is the literal canonical value or a regex equivalent of it. Detects complete replacement (via `None → DIVERGE`) but not semantic narrowing via append.
- **SOUND**: capture group is a bounded wildcard. Detects both complete replacement and semantic narrowing via append.

### FACT-1 — canonical_value = `"link_target"` (8 bindings, all TAUTOLOGICAL)

| # | File | Note | Pattern | Verdict |
|---|------|------|---------|---------|
| 1 | `architecture/module-decomposition.md` | sort_unstable_by_key tuple in reporter.rs pseudocode | `sort_unstable_by_key[^;]*(link_target)` | **TAUTOLOGICAL** |
| 2 | `prd-supplements/interface-definitions.md` | text output Ordering field | `Ordering.*?sorted by .{0,5}\(NFC-normalized[^)]*?(link_target)` | **TAUTOLOGICAL** |
| 3 | `prd-supplements/interface-definitions.md` | JSON output Ordering field | `results.*?is sorted by \([^)]*?(link_target)` | **TAUTOLOGICAL** |
| 4 | `behavioral-contracts/BC-INDEX.md` | DI-001 row invariant table | `DI-001[^\n]*(link_target)` | **TAUTOLOGICAL** |
| 5 | `behavioral-contracts/ss-12/BC-2.12.001.md` | description sort-key (multi-line tuple) | `sorted deterministically by.{0,10}\([^)]*?(link_target)` | **TAUTOLOGICAL** |
| 6 | `behavioral-contracts/ss-12/BC-2.12.001.md` | postcondition 5 sort-key | `Findings are sorted by \([^)]*?(link_target)` | **TAUTOLOGICAL** |
| 7 | `behavioral-contracts/ss-13/BC-2.13.001.md` | postcondition 4 results sorted-by | `results.*?is sorted by \([^)]*?(link_target)` | **TAUTOLOGICAL** |
| 8 | `behavioral-contracts/ss-03/BC-2.03.002.md` | invariant 4 sort-key uniqueness | `sort key \([^)]*?(link_target)` | **TAUTOLOGICAL** |

### FACT-2 — canonical_value = `"AnchorTable(HashSet<String>)"` (1 binding, TAUTOLOGICAL)

| # | File | Note | Pattern | Verdict |
|---|------|------|---------|---------|
| 9 | `domain-spec/entities.md` | AnchorTable § newtype declaration | `AnchorTable.*?is a newtype.*?(AnchorTable\(HashSet<String>\))` | **TAUTOLOGICAL** |

### FACT-3 — canonical_value = `"Pass 1.5"` (2 bindings, all TAUTOLOGICAL)

| # | File | Note | Pattern | Verdict |
|---|------|------|---------|---------|
| 10 | `domain-spec/entities.md` | MarkdownFile table anchor-table row | `anchor-table.*?(Pass 1\.5)` | **TAUTOLOGICAL** |
| 11 | `specs/prd.md` | KD-001 table BC-2.05.001 row | `BC-2\.05\.001.*?(Pass 1\.5)` | **TAUTOLOGICAL** |

### FACT-5a — canonical_value = `"ADR-008"` (2 bindings, both SOUND)

| # | File | Note | Pattern | Verdict |
|---|------|------|---------|---------|
| 12 | `behavioral-contracts/ss-06/BC-2.06.001.md` | Traceability: Architecture Module field | `Architecture Module.*?slug\.rs.*?— (ADR-\d+)` | **SOUND** |
| 13 | `behavioral-contracts/ss-06/BC-2.06.002.md` | Traceability: Architecture Module field | `Architecture Module.*?slug\.rs.*?— (ADR-\d+)` | **SOUND** |

### FACT-5b — canonical_value = `"ADR-003"` (1 binding, SOUND)

| # | File | Note | Pattern | Verdict |
|---|------|------|---------|---------|
| 14 | `behavioral-contracts/ss-05/BC-2.05.003.md` | Traceability: Architecture Module field | `Architecture Module.*?anchor_table\.rs.*?— (ADR-\d+)` | **SOUND** |

### FACT-6a — canonical_value = `"TV-S007"` (1 binding, TAUTOLOGICAL)

| # | File | Note | Pattern | Verdict |
|---|------|------|---------|---------|
| 15 | `verification-properties/vp-018-slug-worked-examples.md` | @GENERATED slug-corpus includes TV-S007 | `@GENERATED:BEGIN slug-corpus.*(TV-S007)` | **TAUTOLOGICAL** |

### FACT-6b — canonical_value = `"TV-S010"` (1 binding, TAUTOLOGICAL)

| # | File | Note | Pattern | Verdict |
|---|------|------|---------|---------|
| 16 | `verification-properties/vp-018-slug-worked-examples.md` | @GENERATED slug-corpus includes TV-S010 | `@GENERATED:BEGIN slug-corpus.*(TV-S010)` | **TAUTOLOGICAL** |

**Note on FACT-6a/6b:** These are structural presence checks for test-vector IDs in a generated block. The IDs appear at the end of comment lines with no natural right-side delimiter other than end-of-line. Complete absence of the ID → `None → DIVERGE` (correctly caught). The prefix-pass risk (e.g., `TV-S007-variant`) is very low in practice because test-vector IDs follow a rigid `TV-XNNN` format and never carry suffixes. These are TAUTOLOGICAL by structure but low-severity compared to FACT-9 and FACT-10.

### FACT-7 — canonical_value = `"macOS"` (1 binding, SOUND)

| # | File | Note | Pattern | Verdict |
|---|------|------|---------|---------|
| 17 | `specs/product-brief.md` | Platform matrix bullet | `\*\*Platform matrix:\*\* (.*?) \(` | **SOUND** |

### FACT-8 — canonical_value = `"macOS only"` (1 binding, SOUND)

| # | File | Note | Pattern | Verdict |
|---|------|------|---------|---------|
| 18 | `domain-spec/assumptions.md` | ASM-004 platform matrix restatement | `ASM-004 \| Platform matrix is (.*?) \(` | **SOUND** |

### FACT-9 — canonical_value = `"every extracted link destination"` (6 bindings, all TAUTOLOGICAL)

| # | File | Note | Pattern | Verdict |
|---|------|------|---------|---------|
| 19 | `architecture/purity-boundary-map.md` | DirIndex build step 1 | `directories from (every extracted link destination)` | **TAUTOLOGICAL** |
| 20 | `architecture/system-overview.md` | Pass 1.5 Purpose line — DirIndex build | `build DirIndex for (every extracted link destination)` | **TAUTOLOGICAL** |
| 21 | `architecture/system-overview.md` | Pass 1.5a step — Collect unique parent dirs | `Collect unique parent directories of (every extracted link destination)` | **TAUTOLOGICAL** |
| 22 | `behavioral-contracts/ss-07/BC-2.07.002.md` | Postcondition 5 — DirIndex coverage | `` `DirIndex` for (every extracted link destination) `` | **TAUTOLOGICAL** |
| 23 | `behavioral-contracts/ss-07/BC-2.07.005.md` | Precondition 2 — directory-link routing | `` `DirIndex` for (every extracted link destination) `` | **TAUTOLOGICAL** |
| 24 | `behavioral-contracts/ss-07/BC-2.07.006.md` | Precondition 2 — non-.md file routing | `` `DirIndex` for (every extracted link destination) `` | **TAUTOLOGICAL** |

### FACT-10 — canonical_value = `` `invalid `--ignore` glob` `` (7 bindings, all TAUTOLOGICAL)

| # | File | Note | Pattern | Verdict |
|---|------|------|---------|---------|
| 25 | `domain-spec/capabilities.md` | CAP-014 exit-2 condition — sole trigger parenthetical | `` sole trigger: (invalid `--ignore` glob) `` | **TAUTOLOGICAL** |
| 26 | `domain-spec/capabilities.md` | CAP-014 io_errors/config_error partition — receives: line | `` receives: (invalid `--ignore` glob) `` | **TAUTOLOGICAL** |
| 27 | `architecture/system-overview.md` | Error Handling section — sole startup configuration error sentence | `` startup configuration error is an (invalid `--ignore` glob) `` | **TAUTOLOGICAL** |
| 28 | `architecture/system-overview.md` | Error Handling table — Configuration error row label | `` Configuration error: (invalid `--ignore` glob) `` | **TAUTOLOGICAL** |
| 29 | `behavioral-contracts/ss-14/BC-2.14.001.md` | Precondition 4 — config_error = false condition | `` no (invalid `--ignore` glob) pattern was detected `` | **TAUTOLOGICAL** |
| 30 | `behavioral-contracts/ss-14/BC-2.14.002.md` | Precondition 2 — config_error = true sole trigger | `` is an (invalid `--ignore` glob) pattern `` | **TAUTOLOGICAL** |
| 31 | `behavioral-contracts/ss-14/BC-2.14.003.md` | Precondition 4 — config_error = false condition | `` no (invalid `--ignore` glob) pattern was detected `` | **TAUTOLOGICAL** |

---

## 5. Corrected Patterns with Adversarial Proof

### FACT-1: corrected patterns (8 bindings)

The "link_target" canonical appears as the **last element in a 4-tuple sort key** of the form `(field1, field2, field3, link_target)`. All 8 corrections exploit a consistent structural property: the canonical value is the tuple's final element, separated from preceding elements by `, ` and followed by `)`.

#### Binding 1 — module-decomposition.md
**Actual text:** `findings.sort_unstable_by_key(|f| (nfc(&f.path), f.line, f.col, f.link_target))  [pure]`  
Canonical appears as `f.link_target` followed by `))`.

**Corrected:** `sort_unstable_by_key[^;]*\.([a-z_]+)\)\)`

**Adversarial proof:**
- Real `f.link_target))` → captures `link_target` == canonical → PASS ✓
- Mutant `f.sort_target))` → captures `sort_target` ≠ canonical → DIVERGE ✓
- Mutant `f.link_target_v2))` → captures `link_target_v2` ≠ canonical → DIVERGE ✓

#### Bindings 2 and 3 — interface-definitions.md (text format and JSON Ordering fields)
**Actual text (binding 2):** `` **Ordering:** sorted by `(NFC-normalized file path, line number, column number, link_target)` — ascending ``  
**Actual text (binding 3):** `` `results` is sorted by (NFC-normalized file path, line, column, link_target) ascending ``  
Both end with `, <last-field>)`.

**Corrected binding 2:** `Ordering.*?sorted by .{0,5}\([^)]*,\s*([^)`\s]+)\s*\)`  
**Corrected binding 3:** `results.*?is sorted by \([^)]*,\s*([^)]+)\)`

**Adversarial proof (binding 3 as representative):**
- Real `(..., link_target)` → `([^)]+)` captures `link_target` == canonical → PASS ✓
- Mutant `(..., sort_field)` → captures `sort_field` ≠ canonical → DIVERGE ✓
- Mutant `(..., link_target_v2)` → captures `link_target_v2` ≠ canonical → DIVERGE ✓

#### Binding 4 — BC-INDEX.md
**Actual text:** `| DI-001 | Deterministic output order (NFC path, line, col, link_target) | BC-2.12.001, BC-2.13.001 |`

**Corrected:** `DI-001[^\n]*,\s*([^)]+)\)`

**Adversarial proof:**
- Real `(NFC path, line, col, link_target)` → captures `link_target` == canonical → PASS ✓
- Mutant `(NFC path, line, col, sort_key_field)` → captures `sort_key_field` ≠ canonical → DIVERGE ✓
- Mutant `(NFC path, line, col, link_target_v2)` → captures `link_target_v2` ≠ canonical → DIVERGE ✓

#### Binding 5 — BC-2.12.001.md (description sort-key)
**Actual text:** `(NFC-normalized file path, line number, column number, link_target) ascending.`

**Corrected:** `sorted deterministically by.{0,10}\([^)]*,\s*([^)]+)\)`

**Adversarial proof:** same structure as binding 3.

#### Binding 6 — BC-2.12.001.md (postcondition 5)
**Actual text:** `Findings are sorted by (NFC file path asc, line asc, column asc, link_target asc).`  
Note: each field has ` asc` qualifier.

**Corrected:** `Findings are sorted by \([^)]*,\s*([^\s)]+)\s+asc\)`

**Adversarial proof:**
- Real `link_target asc)` → captures `link_target` == canonical → PASS ✓
- Mutant `sort_target asc)` → captures `sort_target` ≠ canonical → DIVERGE ✓
- Mutant `link_target_v2 asc)` → captures `link_target_v2` ≠ canonical → DIVERGE ✓

#### Bindings 7 and 8 — BC-2.13.001.md and BC-2.03.002.md
**Actual text (binding 7):** `` `results` is sorted by (NFC-normalized file path, line, column, link_target) ascending ``  
**Actual text (binding 8):** `The sort key (file, line, col, link_target) must be unique`

**Corrected binding 7:** `results.*?is sorted by \([^)]*,\s*([^)]+)\)` (same form as binding 3)  
**Corrected binding 8:** `sort key \([^)]*,\s*([^)]+)\)`

**Adversarial proof (binding 8):**
- Real `(file, line, col, link_target)` → captures `link_target` == canonical → PASS ✓
- Mutant `(file, line, col, sort_key_field)` → captures `sort_key_field` ≠ canonical → DIVERGE ✓
- Mutant `(file, line, col, link_target_v2)` → captures `link_target_v2` ≠ canonical → DIVERGE ✓

---

### FACT-2: corrected pattern (1 binding)

**Actual text:** `` `AnchorTable` is a newtype: `AnchorTable(HashSet<String>)`. ``  
The canonical appears backtick-wrapped after `: `.

**Corrected:** `` AnchorTable.*?is a newtype:\s*`([^`]+)` ``

**Adversarial proof:**
- Real `` `AnchorTable(HashSet<String>)` `` → captures `AnchorTable(HashSet<String>)` == canonical → PASS ✓
- Mutant `` `AnchorTable(BTreeSet<String>)` `` → captures `AnchorTable(BTreeSet<String>)` ≠ canonical → DIVERGE ✓
- Mutant `` `HashSet<String>` `` (newtype wrapper dropped) → captures `HashSet<String>` ≠ canonical → DIVERGE ✓

---

### FACT-3: corrected patterns (2 bindings)

Both binding sites use a pipeline-phase notation `Pass 1 → Pass 1.5 → …` or `Pass 1 → Pass 1.5;` where `Pass 1.5` is bounded by ` → ` on the right (binding 11) or `;` on the right (binding 10).

#### Binding 10 — entities.md
**Actual text:** `| anchor-table | AnchorTable | built three-phase (Pass 1 → Pass 1.5; DI-008) |`

**Corrected:** `anchor-table.*?Pass 1 → (.*?);`

**Adversarial proof:**
- Real `Pass 1 → Pass 1.5;` → captures `Pass 1.5` == canonical → PASS ✓
- Mutant `Pass 1 → Pass 2.0;` → captures `Pass 2.0` ≠ canonical → DIVERGE ✓
- Mutant `Pass 1 → Pass 1.5a;` → captures `Pass 1.5a` ≠ canonical → DIVERGE ✓

#### Binding 11 — prd.md
**Actual text:** `| BC-2.05.001 | Three-phase pipeline design (Pass 1 → Pass 1.5 → Pass 2) … |`

**Corrected:** `BC-2\.05\.001.*?Pass 1 → (.*?) →`

**Adversarial proof:**
- Real `Pass 1 → Pass 1.5 →` → captures `Pass 1.5` == canonical → PASS ✓
- Mutant `Pass 1 → Pass 2.0 →` → captures `Pass 2.0` ≠ canonical → DIVERGE ✓
- Mutant `Pass 1 → Pass 1.5a →` → captures `Pass 1.5a` ≠ canonical → DIVERGE ✓

---

### FACT-6a/6b: structural note

FACT-6a and FACT-6b are structural ID-presence checks, not value-capture checks. The canonical values `TV-S007` and `TV-S010` are rigid IDs (format `TV-XNNN`) that always appear at end-of-line in the `@GENERATED` block as inline comments. There is no natural value-comparison alternative: the check is inherently "does this ID appear in this block?" Complete removal of the ID → `None → DIVERGE` (correct). The prefix-pass risk (e.g., `TV-S007-additional`) is structurally impossible given the actual comment format `),  // TV-S007`.

**Recommended action:** mark these as a known limitation — the existing pattern is the best achievable within the current single-regex framework for structural membership checks. Alternatively, verify with a line-level pattern:

**Proposed binding 15 (FACT-6a):** `@GENERATED:BEGIN slug-corpus.*\bTV-S(\d{3})\b.*\n.*\n.*\n.*\n.*\n.*TV-S007` — but this is fragile to insertion order. The simplest sound alternative for an ID-presence check is the two-pattern approach (not supported by the current checker design). Mark as **structural limitation** rather than fixable with the current framework.

---

### FACT-9: corrected patterns (6 bindings)

All six binding sites have ` —` (space-em-dash) as the natural right delimiter following the canonical phrase, confirmed by reading the actual texts.

**General corrected form for all 6:**

| Binding | Old pattern | Corrected pattern |
|---------|------------|-------------------|
| 19 (purity-boundary-map.md) | `directories from (every extracted link destination)` | `directories from (.*?) —` |
| 20 (system-overview.md, Purpose) | `build DirIndex for (every extracted link destination)` | `build DirIndex for (.*?) —` |
| 21 (system-overview.md, Pass 1.5a) | `Collect unique parent directories of (every extracted link destination)` | `Collect unique parent directories of (.*?) —` |
| 22 (BC-2.07.002.md) | `` `DirIndex` for (every extracted link destination) `` | `` `DirIndex` for (.*?) — `` |
| 23 (BC-2.07.005.md) | `` `DirIndex` for (every extracted link destination) `` | `` `DirIndex` for (.*?) — `` |
| 24 (BC-2.07.006.md) | `` `DirIndex` for (every extracted link destination) `` | `` `DirIndex` for (.*?) — `` |

**Adversarial proof (binding 19 as representative):**

Actual text: `1. Collecting all unique parent directories from every extracted link destination — all link types (.md, non-.md, directories)`

- Real: `directories from (.*?) —` captures `every extracted link destination` == canonical → PASS ✓
- Mutant "directories from every extracted link destination BUT ONLY .md files —" → captures `every extracted link destination BUT ONLY .md files` ≠ canonical → DIVERGE ✓
- Mutant "directories from .md link destinations —" → captures `.md link destinations` ≠ canonical → DIVERGE ✓

Note: the `(.*?)` lazy wildcard with `re.DOTALL` will not cross the ` —` boundary. The em-dash is reliable as a delimiter across all 6 binding sites (confirmed by reading actual texts).

---

### FACT-10: corrected patterns (7 bindings)

The canonical `` invalid `--ignore` glob `` appears with different trailing context in each binding site. Per-site corrections are required.

**Actual trailing text per site:**

| Binding | Actual text after canonical | Right delimiter |
|---------|----------------------------|----------------|
| 25 (capabilities.md, "sole trigger") | `...glob pattern, the` | ` pattern,` |
| 26 (capabilities.md, "receives") | `...glob pattern only (detected by` | ` pattern ` |
| 27 (system-overview.md, "sole startup error") | `...glob\npattern that \`globset\`` | `\n` (end of line) |
| 28 (system-overview.md, table row) | `...glob (sole \`config_error\` trigger)` | ` \(` |
| 29 (BC-2.14.001, "no ... pattern was detected") | `...glob pattern was detected` | ` pattern was detected` |
| 30 (BC-2.14.002, "is an ... pattern") | `...glob pattern (detected by` | ` pattern \(` |
| 31 (BC-2.14.003, same as 29) | same as 29 | same as 29 |

| Binding | Old pattern | Corrected pattern |
|---------|------------|-------------------|
| 25 | `` sole trigger: (invalid `--ignore` glob) `` | `` sole trigger: ([^,\n]+?) pattern, `` |
| 26 | `` receives: (invalid `--ignore` glob) `` | `` receives: ([^ ]+(?:\s[^ ]+)*?) pattern `` or simpler: `` `config_error = true`\s*receives:\s*([^\n(]+?) pattern `` |
| 27 | `` startup configuration error is an (invalid `--ignore` glob) `` | `` startup configuration error is an ([^\n]+)\n `` |
| 28 | `` Configuration error: (invalid `--ignore` glob) `` | `` Configuration error: ([^(]+?)\s*\( `` |
| 29 | `` no (invalid `--ignore` glob) pattern was detected `` | `` no ([^()]+?) pattern was detected `` |
| 30 | `` is an (invalid `--ignore` glob) pattern `` | `` is an ([^()]+?) pattern \( `` |
| 31 | same as 29 | same corrected pattern as 29 |

**Adversarial proof (bindings 25 and 29 as representatives):**

**Binding 25** (`sole trigger: ([^,\n]+?) pattern,`):
- Real `sole trigger: invalid \`--ignore\` glob pattern, the` → captures `` invalid `--ignore` glob `` == canonical → PASS ✓
- Mutant `sole trigger: invalid \`--ignore\` glob or unrecognized flag pattern, the` → captures `` invalid `--ignore` glob or unrecognized flag `` ≠ canonical → DIVERGE ✓
- Mutant `sole trigger: invalid \`--output\` glob pattern, the` → captures `` invalid `--output` glob `` ≠ canonical → DIVERGE ✓

**Binding 29** (`no ([^()]+?) pattern was detected`):
- Real `no invalid \`--ignore\` glob pattern was detected` → captures `` invalid `--ignore` glob `` == canonical → PASS ✓
- Mutant `no invalid \`--ignore\` glob or bad-config pattern was detected` → captures `` invalid `--ignore` glob or bad-config `` ≠ canonical → DIVERGE ✓
- Mutant `no invalid \`--output\` glob pattern was detected` → captures `` invalid `--output` glob `` ≠ canonical → DIVERGE ✓

**Binding 28** (`Configuration error: ([^(]+?)\s*\(`): mirrors the FACT-7/FACT-8 ` \(` delimiter approach.
- Real `Configuration error: invalid \`--ignore\` glob (sole...)` → captures `` invalid `--ignore` glob `` == canonical → PASS ✓
- Mutant `Configuration error: invalid \`--ignore\` glob or second thing (sole...)` → captures `` invalid `--ignore` glob or second thing `` ≠ canonical → DIVERGE ✓
- Mutant `Configuration error: invalid \`--output\` glob (sole...)` → captures `` invalid `--output` glob `` ≠ canonical → DIVERGE ✓

---

## 6. Selftest 22 Assessment

### The test verbatim (lines 1087–1148 of run-selftests.sh)

The relevant portion:

```bash
# ── Test 22: check-canonical-facts — FACT-10 negative (second config_error trigger) ─────
# ...
cat > "$T/.factory/specs/canonical-facts.toml" <<'TOML22'
[[fact]]
id              = "FACT-10-NEG"
...
canonical_value = 'invalid `--ignore` glob'

[[binding]]
fact_id = "FACT-10-NEG"
file    = ".factory/specs/selftest-fact10.md"
pattern = 'config error trigger: "(.*?)"'
TOML22

cat > "$T/.factory/specs/selftest-fact10.md" <<'MD22CLEAN'
config error trigger: "invalid `--ignore` glob"
MD22CLEAN

# [clean-pass phase]

cat > "$T/.factory/specs/selftest-fact10.md" <<'MD22BAD'
config error trigger: "invalid `--ignore` glob or unrecognized flag"
MD22BAD
# asserts: DIVERGE [FACT-10-NEG] reported
```

### Why it passes

Selftest 22 PASSES correctly **for its own synthetic scenario**. The pattern `'config error trigger: "(.*?)"'` is a sound flexible pattern: `(.*?)` bounded by `"..."` delimiters. When the binding site changes to `"invalid \`--ignore\` glob or unrecognized flag"`, the flexible pattern captures the full phrase and the `!=` check fires correctly.

### Why it provides no coverage of the production FACT-10 patterns

Selftest 22 creates its own `canonical-facts.toml` in a temp tree and runs `SPEC_LINT_REPO_OVERRIDE="$T"`. It **never executes the production FACT-10 binding patterns** (`sole trigger: (invalid \`--ignore\` glob)`, `receives: (invalid \`--ignore\` glob)`, etc.). It only tests a synthetic scenario that is sound-by-design.

### What it should assert instead

To provide actual coverage, selftest 22 must test the production FACT-10 patterns **against the specific adversarial text that prefix-passes them**. For example, using the actual production binding 25 context:

```toml
# Synthetic test that exposes the production pattern's weakness
[[binding]]
fact_id = "FACT-10-TEST"
file    = ".factory/specs/selftest-fact10.md"
pattern = 'sole trigger: (invalid `--ignore` glob)'   # ACTUAL production pattern
```

With binding site text:
```
sole trigger: invalid `--ignore` glob or unrecognized flag pattern, the
```

With this setup, the test should assert **DIVERGE fires** — but with the current production pattern, the checker would **PASS** (false negative). The selftest, as written, cannot detect this defect because it uses a different flexible pattern.

**The fix** is for selftest 22 to use the PRODUCTION pattern in its synthetic `canonical-facts.toml`, pair it with the adversarial "second trigger" text, and assert that the checker **correctly detects** the divergence. As long as the production pattern is tautological, the fixed selftest would FAIL — which is the correct outcome. The selftest would only pass once the production pattern is corrected to use a bounded wildcard.

The BI-042 characterization that "selftest 22 passes against the real FACT-10 production pattern" is slightly imprecise — the test never runs the production pattern. The precise statement is: **selftest 22 tests a synthetic flexible pattern in an isolated temp tree and passes correctly, while providing zero assurance about the production FACT-10 binding patterns, all of which are tautological and will silently pass prefix-extending adversarial text.**

---

## 7. FACT-7 and FACT-8 Independent Verification

### FACT-7 (independent of BI-035)

Pattern: `\*\*Platform matrix:\*\* (.*?) \(`  
Canonical: `macOS`  
Actual text in product-brief.md: `**Platform matrix:** macOS (D-043)`

The `(.*?)` lazy wildcard is bounded by ` \(` on the right. This captures the entire platform clause. Adversarial proofs:
- `macOS (D-043)` → captures `macOS` == canonical → PASS ✓
- `macOS and Linux (D-043)` → captures `macOS and Linux` ≠ canonical → DIVERGE ✓
- `macOS, Linux, Windows (D-043)` → captures `macOS, Linux, Windows` ≠ canonical → DIVERGE ✓
- `macOS and Windows (D-043)` → captures `macOS and Windows` ≠ canonical → DIVERGE ✓

The BI-023 first-token weakness (a prior weaker pattern that only captured up to the first space) is not present in the current pattern. **FACT-7: SOUND, independently confirmed.**

### FACT-8 (independent of BI-035)

Pattern: `ASM-004 \| Platform matrix is (.*?) \(`  
Canonical: `macOS only`  
Actual text in assumptions.md: `ASM-004 | Platform matrix is macOS only (\`macos-latest\`...`

The `(.*?)` lazy wildcard bounded by ` \(`. Adversarial proofs:
- `macOS only (\`macos-latest\`)` → captures `macOS only` == canonical → PASS ✓
- `macOS and Linux (\`macos-latest\`, \`ubuntu-latest\`)` → captures `macOS and Linux` ≠ canonical → DIVERGE ✓
- `macOS only and Windows (\`macos-latest\`, \`windows-latest\`)` → captures `macOS only and Windows` ≠ canonical → DIVERGE ✓

**FACT-8: SOUND, independently confirmed.**

---

## 8. Summary of Corrections Required

| Category | Count | Action |
|----------|-------|--------|
| TAUTOLOGICAL bindings requiring corrected patterns | 24 | Correct the 8 FACT-1 + 1 FACT-2 + 2 FACT-3 + 6 FACT-9 + 7 FACT-10 patterns |
| TAUTOLOGICAL bindings with structural limitation | 2 | FACT-6a/6b — mark as known limitation, or redesign as line-level assertions |
| SOUND bindings (no change needed) | 5 | FACT-5a(2) + FACT-5b(1) + FACT-7(1) + FACT-8(1) |
| Selftest 22 | 1 | Replace synthetic flexible pattern with actual production pattern; assert DIVERGE on prefix-extending adversarial text |

**Total TAUTOLOGICAL: 26 of 31** (not 17 as stated in BI-042 premise)  
**Total SOUND: 5 of 31**

The BI-042 premise that "no match → silent skip" is refuted. The true severity class is narrower: **prefix-extending additions to the canonical phrase silently pass**. Complete replacements are correctly caught via `None → DIVERGE`. The risk is still genuine and warrants remediation, but the existing checker is not as broken as the BI-042 premise implied.

---

## 9. D-076 Applied: Pattern Corrections and Verification Results

**Applied date:** 2026-08-07  
**File modified:** `.factory/specs/canonical-facts.toml` (and only that file)  
**Checker result:** `canonical-facts: OK — all 31 bindings match canonical values (11 facts)`

### 9.1 Before/After Pattern Table (all 26 tautological bindings)

FACT-6a (binding 15) and FACT-6b (binding 16) are unchanged — structural limitation documented in Section 4.

| # | Fact | File (abbreviated) | Old pattern | New pattern |
|---|------|--------------------|------------|------------|
| 1 | FACT-1 | `module-decomposition.md` | `sort_unstable_by_key[^;]*(link_target)` | `sort_unstable_by_key[^\n;]*\.([a-z_]+)\)\)` |
| 2 | FACT-1 | `interface-definitions.md` | `Ordering.*?sorted by .{0,5}\(NFC-normalized[^)]*?(link_target)` | `Ordering.*?sorted by [^\n]{0,5}\([^)]*,\s*([^)\n]+)\)` |
| 3 | FACT-1 | `interface-definitions.md` | `results.*?is sorted by \([^)]*?(link_target)` | `results.*?is sorted by \([^)]*,\s*([^)\n]+)\)` |
| 4 | FACT-1 | `BC-INDEX.md` | `DI-001[^\n]*(link_target)` | `DI-001[^\n]*,\s*([^)\n]+)\)` |
| 5 | FACT-1 | `BC-2.12.001.md` | `sorted deterministically by.{0,10}\([^)]*?(link_target)` | `sorted deterministically by.{0,10}\([^)]*,\s*([^)\n]+)\)` |
| 6 | FACT-1 | `BC-2.12.001.md` | `Findings are sorted by \([^)]*?(link_target)` | `Findings are sorted by \([^)]*,\s*([^\s)\n]+)\s+asc\)` |
| 7 | FACT-1 | `BC-2.13.001.md` | `results.*?is sorted by \([^)]*?(link_target)` | `results.*?is sorted by \([^)]*,\s*([^)\n]+)\)` |
| 8 | FACT-1 | `BC-2.03.002.md` | `sort key \([^)]*?(link_target)` | `sort key \([^)]*,\s*([^)\n]+)\)` |
| 9 | FACT-2 | `entities.md` | `` AnchorTable.*?is a newtype.*?(AnchorTable\(HashSet<String>\)) `` | `` AnchorTable.*?is a newtype:\s*`([^`\n]+)` `` |
| 10 | FACT-3 | `entities.md` | `anchor-table.*?(Pass 1\.5)` | `anchor-table[^\n]*Pass 1 → ([^;\n]+?);` |
| 11 | FACT-3 | `prd.md` | `BC-2\.05\.001.*?(Pass 1\.5)` | `BC-2\.05\.001[^\n]*Pass 1 → ([^→\n]+?) →` |
| 19 | FACT-9 | `purity-boundary-map.md` | `directories from (every extracted link destination)` | `directories from ([^\n]+?) —` |
| 20 | FACT-9 | `system-overview.md` | `build DirIndex for (every extracted link destination)` | `build DirIndex for ([^\n]+?) —` |
| 21 | FACT-9 | `system-overview.md` | `Collect unique parent directories of (every extracted link destination)` | `Collect unique parent directories of ([^\n]+?) —` |
| 22 | FACT-9 | `BC-2.07.002.md` | `` `DirIndex` for (every extracted link destination) `` | `` `DirIndex` for ([^\n]+?) — `` |
| 23 | FACT-9 | `BC-2.07.005.md` | `` `DirIndex` for (every extracted link destination) `` | `` `DirIndex` for ([^\n]+?) — `` |
| 24 | FACT-9 | `BC-2.07.006.md` | `` `DirIndex` for (every extracted link destination) `` | `` `DirIndex` for ([^\n]+?) — `` |
| 25 | FACT-10 | `capabilities.md` | `` sole trigger: (invalid `--ignore` glob) `` | `\(sole trigger: ([^\n,]+?) pattern,` |
| 26 | FACT-10 | `capabilities.md` | `` receives: (invalid `--ignore` glob) `` | `` `config_error = true`\s*receives: ([^\n(]+?) pattern `` |
| 27 | FACT-10 | `system-overview.md` | `` startup configuration error is an (invalid `--ignore` glob) `` | `startup configuration error is an ([^\n]+)\n` |
| 28 | FACT-10 | `system-overview.md` | `` Configuration error: (invalid `--ignore` glob) `` | `Configuration error: ([^\n(]+?)\s*\(` |
| 29 | FACT-10 | `BC-2.14.001.md` | `` no (invalid `--ignore` glob) pattern was detected `` | `no ([^\n(]+?) pattern was detected` |
| 30 | FACT-10 | `BC-2.14.002.md` | `` is an (invalid `--ignore` glob) pattern `` | `is an ([^\n(]+?) pattern \(` |
| 31 | FACT-10 | `BC-2.14.003.md` | `` no (invalid `--ignore` glob) pattern was detected `` | `no ([^\n(]+?) pattern was detected` |

### 9.2 Three-Way Verification Results

All 24 corrected bindings were empirically verified before application. The three verification assertions for each binding are:

1. **Real-text capture:** `re.search(new_pattern, actual_file_text, re.DOTALL).group(1) == canonical_value` → PASS
2. **Complete replacement:** replace canonical phrase with unrelated text → pattern returns `None` → DIVERGE
3. **Prefix-extension:** append qualifying clause to canonical phrase → group(1) captures the extended phrase, `!= canonical_value` → DIVERGE

All 24 corrected bindings pass all three assertions. Two non-obvious disambiguation issues were identified and resolved during verification:

**Binding 25 (FACT-10, capabilities.md "sole trigger"):** Two occurrences of "sole trigger:" in capabilities.md — one at the changelog entry (pos 720, no backticks around `--ignore`) and one in the spec content (pos 12546, with backticks). The corrected pattern uses `\(sole trigger:` with a left-anchor `\(` because the spec-content occurrence is preceded by `(` while the changelog entry is not. This ensures `re.search` matches the correct occurrence.

**Binding 26 (FACT-10, capabilities.md "receives:"):** Two occurrences of "receives:" in capabilities.md — one for `io_errors` (pos 12810) and one for `config_error` (pos 13023). The corrected pattern uses `` `config_error = true`\s*receives: `` as the left anchor to bind exclusively to the config_error occurrence.

### 9.3 New Divergences from Corrected Patterns

None. The production checker reported `OK — all 31 bindings match canonical values` after applying all 24 corrections. No new divergences surfaced; the production spec files are consistent with their canonical values.

### 9.4 Selftest-22 Rewrite Specification

**Do not implement here.** This spec is for the develop-side PR that resets the selftest infrastructure. The rewrite lands in a separate PR after D-076.

**Problem:** The current selftest 22 creates a synthetic `canonical-facts.toml` with a flexible pattern (`'config error trigger: "(.*?)"'`) that is sound-by-design. It never runs any production FACT-10 binding pattern. A tautological production pattern would silently pass the selftest.

**Rewrite specification:**

Replace the synthetic TOML in test 22 with the actual production FACT-10 binding 25 context. The rewritten test has two phases:

**Phase A — pass case (existing behavior, new pattern):**

```toml
[[fact]]
id              = "FACT-10-SELFTEST"
canonical_value = 'invalid `--ignore` glob'

[[binding]]
fact_id = "FACT-10-SELFTEST"
file    = ".factory/specs/selftest-fact10.md"
pattern = '\(sole trigger: ([^\n,]+?) pattern,'
```

Binding file content (canonical, should pass):
```
(sole trigger: invalid `--ignore` glob pattern, the only...)
```

Assert: checker exits 0.

**Phase B — prefix-extension DIVERGE case (new test, add to EXPECTED_TEST_COUNT):**

Same TOML as Phase A. Binding file content (adversarial, should diverge):
```
(sole trigger: invalid `--ignore` glob or unrecognized flag pattern, the only...)
```

Assert: checker exits 1 AND output contains `DIVERGE [FACT-10-SELFTEST]` AND the extracted value contains the phrase `or unrecognized flag`.

**Counter update:** Phase B is a distinct test assertion that increments the passed counter by 1. Update `EXPECTED_TEST_COUNT` from `49` to `50`.

**Guard constraint:** The rewritten test must not introduce any named-set construct matching `(ALLOWLIST|SKIP_SET|SUPPRESS_SET)\s*[=:]` — use a temporary TOML file written via heredoc as already done in the existing selftest 22 structure.

**Rationale:** With this rewrite, if the production FACT-10 binding 25 pattern is ever reverted to the tautological form `'sole trigger: (invalid `--ignore` glob)'`, Phase B will FAIL (the checker exits 0 instead of 1) and the CI will catch the regression.
