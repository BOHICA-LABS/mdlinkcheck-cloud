---
document_type: adversarial-findings
level: ops
version: "1.0"
status: final
producer: adversary
phase: phase-1d
pass: 5
shard: 1
cycle: phase-1d
frozen_head: 1d3ed17
scope: "SS-01 (9 BCs) + SS-02 (4 BCs) = 13 BC bodies read in full"
counts: 2 CRITICAL / 13 MAJOR / 12 MINOR = 27
findings_total: 27
findings_critical: 2
findings_major: 13
findings_minor: 12
verdict: FINDINGS_REMAIN
project: mdlinkcheck-cloud
---

# Adversarial Findings — Phase 1d — Pass 5 — Shard 1 / 8

> **ERRATUM (operator ruling, gate #27 / PG-011):** This document's title says "Pass 5". Per the operator's ID-space-is-truth ruling, this perimeter sweep IS **pass 6** — matching the `P6-S*` finding IDs used throughout. The title is preserved unedited per D-034 spirit; this note is the correction. The separate `P5-*` finding population (36/37 findings, record only partially recoverable — see `adversary-pass-5.md`) is pass 5. The next adversary pass after remediation is **pass 7**.

**Frozen HEAD reviewed:** `1d3ed17` (`factory-artifacts`)
**Perimeter:** SS-01 (9 BCs) + SS-02 (4 BCs) = 13 BC bodies read in full
**Shard:** 1 of 8 (perimeter-closing sweep)
**Counts:** 2 CRITICAL / 13 MAJOR / 12 MINOR = 27 findings

---

## CRITICAL

### P6-S1-001 (POLICY 19, POLICY 12) — Phantom reason code `E-IO-002`; unrepresentable behaviour

**Files:** `BC-2.01.009.md:43,:51,:70,:72`; `error-taxonomy.md:91`; `BC-2.13.001.md:55-58,:66`; `vp-021`; `interface-definitions.md:174,:237`; `BC-2.11.004.md:59`; `test-vectors.md:82`

`E-IO-002` is a phantom reason code at BC-2.01.009.md:43,:51,:70,:72. Not in error-taxonomy.md's closed 13-code set (:99-102), which states nothing may fail with a reason outside the set. Worse, the **BEHAVIOUR IS UNREPRESENTABLE**: error-taxonomy.md:91 scopes `target-unreadable` to "source .md file EXISTS but cannot be read", so a nonexistent PATH does not qualify; BC-2.13.001.md:55-58,:66 constrain the JSON `errors[]` array to reason `target-unreadable` exclusively; vp-021 asserts both results[].reason and errors[].reason against the 13-code set, so an `E-IO-002` in errors[] FAILS VP-021 while omitting it makes the error invisible in --format json, defeating the CI-engineer rationale at interface-definitions.md:174. test-vectors.md:82 (TV-012) confirms the hole — expected reason is prose, not a code. Phase 3 must either invent a 14th code (breaking NFR-007) or silently drop the error. Propagates to interface-definitions.md:237 and BC-2.11.004.md:59 (which cites a second phantom family `E-CLI-001` that BC-2.01.009's own v1.1 changelog claims to have retired).

**NOTE:** independently corroborates pass-5 finding P5-015.

---

### P6-S1-002 (POLICY 4) — Deduplication key is `fs::canonicalize`; architecture explicitly forbids it

**Files:** `BC-2.01.002.md:51`; `BC-2.01.007.md:46`; `system-overview.md:141-144`; `invariants.md:234-236` (DI-009); `invariants.md:86` (DI-002); `ss-07/BC-2.07.001.md:44`

BC-2.01.002.md:51 and BC-2.01.007.md:46 both mandate deduplication "by canonicalized REAL path (resolves ., .., SYMLINKS)" = `fs::canonicalize` semantics, which the architecture **EXPLICITLY FORBIDS**. system-overview.md:141-144: dedup key is "NFC-normalized, lexically-normalized, NON-canonicalized (no fs::canonicalize — canonicalize case-folds on macOS APFS, violating D-006 case-sensitivity and DI-001 determinism)" and states this key form is used THROUGHOUT the pipeline. invariants.md:234-236 (DI-009) and :86 (DI-002, "no case-folding at any stage") agree. ss-07/BC-2.07.001.md:44 already uses the correct primitive `canonicalize_logical()`, making SS-01 the outlier. Impact: .md path identity is the join key between scan set, DirIndex, AnchorIndex and the DI-001 sort key; keying the same file two ways in one run is a false-positive `anchor-not-found` generator on APFS — the exact class D-043/DI-002 exist to eliminate. Both BCs also have NO `L2 Domain Invariants` row, so nothing mechanically ties them to DI-002.

---

## MAJOR

### P6-S1-003 — `Path::exists()` on verdict path; purity boundary violation

**Files:** `BC-2.01.006.md:48,:74`; `purity-boundary-map.md:63-70,:45`; `BC-2.13.001.md` (VP-008)

BC-2.01.006.md:48 puts `Path::exists()` on the verdict path; purity-boundary-map.md:63-70 states `broken-symlink` is produced by the PURE path_resolver which never calls fs::read_dir/fs::metadata/Path::exists — dangling-ness travels as `EntryKind::Symlink{dangling:bool}` in DirIndex. Also anchors the contract to `scanner.rs` alone (:74) though the postcondition cannot be implemented there. purity-boundary-map.md:45: "violating it invalidates Kani proof harnesses" — an implementer following :48 breaks VP-008.

---

### P6-S1-004 — BOM invariant 4 contradicts PC5 and TV; stale F-028 survivor

**Files:** `BC-2.02.002.md:71-72,:61-63,:89`; `interface-definitions.md:244`; `test-vectors.md:86`

BC-2.02.002.md:71-72 Invariant 4 claims BOM stripping is "user-visible output unaffected because the tool reports line numbers, not byte offsets", contradicting its own PC5 (:61-63, columns measured from the BOM-stripped buffer, `[` at column 1 not 4) and TV (:89), and interface-definitions.md:244 ("column is the 1-based BYTE OFFSET"). Stale survivor of the same file's v1.2 F-028 fix. It licenses skipping TV-015b, the one vector F-028 was raised to protect.

---

### P6-S1-005 — "stdout is empty" PC contradicts JSON empty-scan contract

**Files:** `BC-2.01.008.md:47`; `BC-2.13.001.md:63`; `BC-2.01.009.md:70`; `interface-definitions.md:102`

BC-2.01.008.md:47 PC2 "stdout is empty" contradicts BC-2.13.001.md:63 Invariant 3 (empty scan under --format json must emit `{"schema_version":1,"results":[],"errors":[]}`). PC2 carries no --format text qualifier; same defect at BC-2.01.009.md:70. interface-definitions.md:102 promises --format json produces VALID JSON; empty output is not.

---

### P6-S1-006 (POLICY 12) — `target-unreadable` described as a finding on stdout

**Files:** `BC-2.02.003.md:45`; `BC-2.01.009.md:58,:71`; `interface-definitions.md:99-100,:174`; `BC-2.13.001.md:66`; `error-taxonomy.md:88-91`

`target-unreadable` described as a "finding" emitted "in output"/"on stdout" at BC-2.02.003.md:45, BC-2.01.009.md:58,:71. Contradicts interface-definitions.md:99-100 (stdout = findings only; I/O errors to stderr), :174 (they go in `errors`, not `results`), BC-2.13.001.md:66 ("a results entry with reason target-unreadable is a BUG"), error-taxonomy.md:88-91 (verdict column is "— (I/O error)", not a link verdict). BC-2.01.009.md:71's "stdout/stderr" is an unresolved either/or inside a CANONICAL TEST VECTOR and cannot be asserted.

---

### P6-S1-007 (POLICY 4) — VP-016 claim is the OPPOSITE of VP-016's actual property

**Files:** `BC-2.01.003.md:72`; `vp-016...md:40,:44`; `VP-INDEX.md:138`

BC-2.01.003.md:72 claims VP-016 proves "files matching .gitignore patterns are NEVER in the scan set". VP-016's actual property (vp-016...md:40,:44) is the OPPOSITE concern: ignored files DO get anchor tables and cross-file anchors INTO them resolve; its source_bc is BC-2.08.004. VP-INDEX.md:138 describes it correctly, so the BC body is the outlier. This is an **AFFIRMATIVE FALSE COVERAGE CLAIM** (not the accepted INC-MAP-004 absence-of-coverage gap): a test-writer reading :72 believes gitignore scan-set exclusion is proven and writes no test.

---

### P6-S1-008 — `.markdown` extension residue: BC-2.02.004 never swept

**Files:** `BC-2.02.004.md:41`; `BC-2.01.002` PC2

BC-2.02.004.md:41's precondition excludes `.markdown`, so `mdlinkcheck notes.markdown` satisfies BC-2.01.002 PC2 (parse it, "regardless of extension") yet falls entirely outside BC-2.02.004. Two P0/P1 BCs disagree on a directly reachable CLI invocation. Same `.markdown` residue that v1.1/v1.2 removed from BC-2.01.001/.002/.008 and BC-2.02.001; BC-2.02.004 was never swept.

---

### P6-S1-009 — `~/.gitignore_global`/`core.excludesFile` in PC3; contradicts NFR-003 and DI-002

**Files:** `BC-2.01.003.md:48`; `invariants.md:88-90` (DI-002 rationale); `interface-definitions.md:305`; `NFR-003 (prd.md:324)`

BC-2.01.003.md:48 PC3 makes scan-set membership depend on `~/.gitignore_global` / `core.excludesFile`. String appears NOWHERE ELSE in the spec set. Contradicts NFR-003 (prd.md:324) and DI-002's rationale (invariants.md:88-90: "verdicts must be a function of repository content, not of the host filesystem's behaviour"). interface-definitions.md:305's acceptance criterion is SET EQUALITY, so a contributor with `docs/` in core.excludesFile gets a PASSING corpus run with fewer findings — silent false-green. DI-001's falsifying method varies only RAYON_NUM_THREADS on one machine, so no specified vehicle can detect it. Either delete PC3 (WalkBuilder git_global(false)) or scope NFR-003 to a fixed HOME.

---

### P6-S1-010 — SETEXT heading byte-offset undefined

**Files:** `BC-2.02.001.md:49`

BC-2.02.001.md:49 PC3 defines byte offset as "the position of the opening `[` for links, or the `#` for ATX headings". SETEXT headings have no `#` and are in scope and P0 (entities.md:42; BC-2.05.002 "ATX and Setext", P0 per BC-INDEX.md:83; TV-059). No default rule given; an implementer will guess.

---

### P6-S1-011 — Two canonical test vectors are non-determinate / unfalsifiable

**Files:** `BC-2.01.005.md:76`; `BC-2.02.004.md:61`; `test-vectors.md:77` (TV-007, correct form)

Two canonical test vectors are non-determinate/unexecutable: BC-2.01.005.md:76 expected output is "(depends on links inside)"; BC-2.02.004.md:61 is "Exit 1 IF pulldown-cmark finds link" — defers the expected result to the implementation, making the vector unfalsifiable by construction. test-vectors.md:77 (TV-007) shows the correct determinate form.

---

### P6-S1-012 (POLICY 4/16) [process-gap] — EC-028b unregistered; base EC-028 is a different scenario class

**Files:** `BC-2.01.006.md:55`; `test-vectors.md:106`

EC-028b at BC-2.01.006.md:55 is described as "Symlink to valid file" but base EC-028 (test-vectors.md:106) is LINK-TITLE STRIPPING. EC-028b has no registration of its own anywhere.

---

### P6-S1-013 (POLICY 16) — EC-015b cites a retired ID; resolves to opposite verdict

**Files:** `BC-2.02.002.md:83,:89`; `test-vectors.md:86,:404`; `prd.md:553`

EC-015b at BC-2.02.002.md:83 is a RETIRED id: the POL-16 remediation reassigned that scenario to EC-178 (test-vectors.md:86,:404; prd.md:553). EC-015 is the CLEAN scenario, so EC-015b resolves to a base whose expected verdict is the OPPOSITE of the row's own scenario. The file is internally split — :89 cites the correct TV-015b while :83 cites the retired EC id.

---

### P6-S1-014 (POLICY 11 class) — Stderr postcondition asserted against verification vehicles that cannot observe stderr

**Files:** `BC-2.01.008.md:48`; `VP-INDEX.md:143`; `interface-definitions.md:305`; `BC-2.01.009.md:70,:72`; `VP-INDEX.md:144`

BC-2.01.008.md:48's only substantive postcondition is a STDERR string ("No markdown files found."), and VP-INDEX.md:143 claims it is "covered by acceptance corpus". The corpus STRUCTURALLY CANNOT observe stderr: interface-definitions.md:305's pass criterion is set equality over the six-field tuple, and manifest.json has no stderr channel. TV-184 asserts only exit 0. Same false-green at BC-2.01.009.md:70,:72, where VP-INDEX.md:144 credits VP-005 — a Kani EXIT-CODE proof that proves nothing about stderr text.

---

### P6-S1-015 (POLICY 17, POLICY 2) — BC-INDEX DI-006 row retains pre-F-005 single-mechanism wording

**Files:** `BC-INDEX.md:211`; `invariants.md:143,:152-159`; `capabilities.md`; `ARCH-INDEX.md:93`; `vp-016`

BC-INDEX.md:211 carries PRE-F-005 DI-006 wording ("--ignore is source-only") though authoritative DI-006 (invariants.md:143,:152-159) covers FOUR mechanisms. The F-005 widening reached capabilities.md, ARCH-INDEX.md:93 and vp-016 but not BC-INDEX. A story-writer sizing DI-006 work from BC-INDEX scopes 1 of 4 mechanisms.

---

## MINOR

### P6-S1-016 — Trailing `(DI-009)` mis-anchor on a DI-006 statement

**File:** `BC-2.01.001.md:52`

`BC-2.01.001.md:52` trailing "(DI-009)" mis-anchor on a DI-006 statement (DI-009 is termination).

---

### P6-S1-017 (POLICY 2/17) — Six of 13 in-scope BCs have no `L2 Domain Invariants` row; BC-INDEX DI enforcer list for DI-002 is incomplete

**Files:** `BC-2.01.005.md,:006.md,:007.md`; `BC-2.02.001.md,:002.md,:004.md`; `BC-INDEX.md:207`; `BC-2.07.003/.004`; `BC-2.01.006`; `BC-2.07.001/.002/.004`

Six of 13 in-scope BCs have NO `L2 Domain Invariants` row (BC-2.01.005/.006/.007, BC-2.02.001/.002/.004); most consequential is BC-2.01.005, the case-sensitivity contract (:57 "case-sensitive byte comparison"), citing no DI at all. BC-INDEX.md:207 lists DI-002 enforcers as only BC-2.07.003/.004, omitting BC-2.01.006 and BC-2.07.001/.002/.004 which do carry DI-002.

---

### P6-S1-018 (POLICY 2/17) — BC-INDEX DI enforcer lists incomplete for DI-003 and DI-004

**File:** `BC-INDEX.md:211,:214`

BC-INDEX DI enforcer lists incomplete: :211 omits BC-2.01.004; :214 omits BC-2.01.002/.003/.008.

---

### P6-S1-019 — "informational, not a warning" contradicts EC-125 vector

**Files:** `BC-2.01.008.md:52`; `test-vectors.md:238`

BC-2.01.008.md:52 "informational, not a warning" vs its own EC-125 vector (test-vectors.md:238) "warning on stderr".

---

### P6-S1-020 — Unresolved `--no-ignore-vcs` hypothetical inside an active P0 invariant

**Files:** `BC-2.01.003.md:56`; `interface-definitions.md:68`

BC-2.01.003.md:56 contains an unresolved "defer to architecture" hypothetical about `--no-ignore-vcs`, a nonexistent flag, inside an active P0 invariant; contradicts interface-definitions.md:68 "no traversal flags in v1.0".

---

### P6-S1-021 (POLICY 4) — DI-009 cited to establish exit 0 on empty scan set; wrong invariants

**File:** `BC-2.01.008.md:75`

BC-2.01.008.md:75 cites DI-009 (termination) to establish "exit 0 on empty scan set"; the invariants that do are DI-010/DI-011.

---

### P6-S1-022 — Test vector asserts line/column for a CLEAN link; clean links are never emitted

**Files:** `BC-2.02.002.md:88`; `error-taxonomy.md:34`; `interface-definitions.md:192`

BC-2.02.002.md:88 test vector asserts line/column for a CLEAN link, but clean links are never emitted (error-taxonomy.md:34; interface-definitions.md:192). Unassertable.

---

### P6-S1-023 — Extension filter: symlink name vs target name ambiguous

**Files:** `BC-2.01.004.md:52`; `BC-2.01.005.md:38`

BC-2.01.004.md:52 ambiguous whether the extension filter applies to the symlink name or the target name; BC-2.01.005.md:38 also unqualified. Two defensible readings, different scan sets.

---

### P6-S1-024 — EC-006b bundles two scenarios; `.mdown` has no registered base

**File:** `BC-2.01.005.md:66`

BC-2.01.005.md:66 EC-006b bundles two scenarios ("notes.mdown OR notes.mdx") and `.mdown` has no registered base (EC-006/TV-006 list only notes.markdown and notes.mdx).

---

### P6-S1-025 (POLICY 1) — Reserved lifecycle vocabulary used for runtime flag precedence

**Files:** `BC-2.01.002.md:84`; `BC-2.01.001.md`

BC-2.01.002.md:84 uses reserved lifecycle vocabulary "superseded by" for a runtime flag-precedence relation; BC-2.01.001 is lifecycle_status active with replacement null, and its reciprocal row says "depends on".

---

### P6-S1-026 — Pre-P2-C06 immediacy flavour in exit-code BC

**Files:** `BC-2.01.002.md:47`; `BC-2.01.009` v1.2 (DD-007)

BC-2.01.002.md:47 PC3 "exit code 2 IS TRIGGERED" retains pre-P2-C06 immediacy flavour; BC-2.01.009 v1.2 established scanning continues (DD-007 no-fail-fast).

---

### P6-S1-027 — No precedence rule between `broken-symlink` and `file-not-found`; TV-134a fails either way

**Files:** `BC-2.01.006.md:49`; `error-taxonomy.md:64`; `DI-005`; `TV-134a`

No precedence rule between `broken-symlink` and `file-not-found`: BC-2.01.006.md:49 asserts only DISTINCTNESS, while error-taxonomy.md:64 gives file-not-found a trigger a dangling symlink also satisfies. DI-005 is preserved but the REASON is underdetermined, and TV-134a requires exactly one entry per offline reason code, so an implementation choosing file-not-found fails TV-134a with no spec basis.

---

## New Process Gap — Spec-lint structural blind spots

### Validator synthesis path shelters stale sub-lettered EC IDs

`scripts/spec-lint/check-id-resolution.py:120-122` and :155-158 SYNTHESISE `EC-NNNa..EC-NNNz` as registered whenever base `EC-NNN` appears in any table row, performing NO description-vs-base comparison. That is why P6-S1-012 (EC-028b), P6-S1-013 (EC-015b, retired) and P6-S1-024 (EC-006b) all pass a mutation-verified checker. Since the POL-16 remediation already migrated every legitimate variant to distinct EC-178..EC-183, the auto-synthesis fallback now shelters ONLY stale ids.

**RECOMMENDED FIX:** require sub-lettered ECs to be registered as their own rows in test-vectors.md §10 and remove the synthesis path.

### Two further skip-list blind spots

**(a)** POLICY 19's reason-code check is scoped to ADRs and to `Reason:` FIELDS, so phantom codes in BC prose/postcondition bodies (`E-IO-002`, `E-CLI-001`) are structurally out of reach — recommend grepping BC and PRD-supplement bodies for `\bE-[A-Z]+-\d+\b`.

**(b)** NO checker compares a BC's VP-table PROPERTY TEXT against the referenced VP's Property Statement, which is how P6-S1-007's inverted claim stays green.

**Also:** the `fs::canonicalize` prohibition is PROSE in system-overview.md:141-144, not a canonical fact with a binding — elevating the dedup key-form rule into canonical-facts.toml would close P6-S1-002 mechanically.

---

## Summary

| Severity | Count | Finding IDs |
|----------|-------|-------------|
| CRITICAL | 2 | P6-S1-001, P6-S1-002 |
| MAJOR | 13 | P6-S1-003 .. P6-S1-015 |
| MINOR | 12 | P6-S1-016 .. P6-S1-027 |
| **Total** | **27** | |

**Scope:** SS-01 (9 BCs: BC-2.01.001..BC-2.01.009) + SS-02 (4 BCs: BC-2.02.001..BC-2.02.004) = 13 BC bodies read in full.

**Shard:** 1 of 8. Shards 2–8 covering the remaining subsystems are in progress. This record is final and frozen.
