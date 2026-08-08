---
document_type: adversarial-review
level: ops
version: "1.0"
status: final
producer: adversary
timestamp: 2026-08-08T00:00:00Z
cycle: phase-1d
pass: 7
shard: 8
frozen_develop_head: f8ee4eb024b8b4a300139ef803d248e8fe40f2fc
frozen_specs_tree: ace1745871122cd1fa2c46cf27c5493cc1083411
frozen_spec_lint_tree: f2392b456c3bd669e3efbe86b3e6eae62e302ed1
severity_vocabulary: "CRITICAL/HIGH/MEDIUM/LOW (single vocabulary per PG-012 ruling)"
findings_total_self_declared: 49
inputs: []
input-hash: "ace1745"
traces_to: STATE.md
---
# Pass 7 — Shard 8: prd + domain-spec + supplements + 3 intake items

```
scope: ".factory/specs/prd.md, product-brief.md, domain-spec/{L2-INDEX,capabilities,entities,invariants,decisions,edge-cases,failure-modes,assumptions,events,event-flow,risks,differentiators}.md, prd-supplements/{error-taxonomy,interface-definitions,nfr-catalog,test-vectors}.md, dtu-assessment.md, module-criticality.md, gene-transfusion-assessment.md — all read in full"
files_read_in_full:
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/prd.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/product-brief.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/L2-INDEX.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/capabilities.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/entities.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/invariants.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/decisions.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/edge-cases.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/failure-modes.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/assumptions.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/events.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/event-flow.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/risks.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/differentiators.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/prd-supplements/error-taxonomy.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/prd-supplements/interface-definitions.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/prd-supplements/nfr-catalog.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/prd-supplements/test-vectors.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/dtu-assessment.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/module-criticality.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/gene-transfusion-assessment.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/scripts/spec-lint/check-placeholders.py
  - /Users/jmagady/Dev/mdlinkcheck-cloud/scripts/spec-lint/check-holdout-boundary.py
  - /Users/jmagady/Dev/mdlinkcheck-cloud/scripts/spec-lint/check-adr-consistency.py
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/holdout-scenarios/HS-INDEX.md
  (reference reads, partial: check-counts.py, gen-rtm.py, spec_lint_primitives.py, selftest/run-selftests.sh, BC Brief-Requirement/L2-Invariant rows across all 66 BCs, BC-2.13.001.md, canonical-facts.toml §FACT-3)
findings_total: 49
severity_counts: CRITICAL 5 / HIGH 16 / MEDIUM 21 / LOW 7
verdict: NOT CLEAN — two verification gates (POL-18 holdout boundary, POL-19 closed taxonomy) are structurally false-green and the corpus contains live instances of both; the frozen-brief requirement anchors in prd.md §7 RTM disagree with the BC files at 19 of 66 rows; the JSON envelope contract is stated four incompatible ways.
```

**Integrity disclosure:** one Grep for `malformed-fragment` was accidentally scoped to `.factory` rather than `.factory/specs` and returned two lines from `.factory/cycles/phase-1d/perimeter-sweep-shard-{4,8}.md`. I read no further into those files and did not use them. The `malformed-fragment` finding (P7-S8-007) was derived independently from reading `test-vectors.md` in full before that grep ran; the grep was for the corpus-wide predicate only.

---

## Intake Adjudications

### P7-S8-001 — `EXCLUDE_PATHS` is unguarded because the selftest guard matches identifier *names*, not suppression *semantics* [HIGH]

**Verdict:** (a) YES — the guard's vocabulary-based matching is a **structural defect**, not a missing entry. (b) The exclusion currently hides exactly **7** placeholder occurrences, **all 7 HISTORICAL**. (c) YES — a position-based predicate is the correct replacement; predicate stated below. (d) NO other checker carries a file-path-keyed skip-set, but two checkers carry *equivalent unguarded scope reductions of a different shape* (see P7-S8-005, P7-S8-006) that the guard also cannot see.

**(a) The guard is a name-matcher.** `scripts/spec-lint/selftest/run-selftests.sh:48`:
```
SUPPRESSION_PATTERN='(ALLOWLIST|_DEFERRAL|SKIP_LIST|SKIP_SET|KNOWN_COLLISIONS|KNOWN_VIOLATIONS|KNOWN_ISSUES|WHITELIST|SUPPRESS_SET)[[:space:]]*[=:]'
```
`run-selftests.sh:164` claims "guard closes the class structurally." It does not. It closes a *closed nine-word vocabulary*. `EXCLUDE_PATHS` (`check-placeholders.py:223`) is semantically identical to `SKIP_LIST` and is invisible to it. So is any future `OMIT_FILES`, `DEFERRED`, `NOT_YET`, `PENDING`, `GRANDFATHERED`. Adding `EXCLUDE_PATHS` to the vocabulary fixes one instance and leaves the class open. `spec_lint_primitives.py:16-17` repeats the same nine-word claim.

**(b) Full set hidden, by predicate.**
- **Predicate:** `Grep '\[filled by [^\]]+\]' -i /Users/.../.factory/specs` → **26 occurrences**, of which **exactly 1 in prd.md** (`prd.md:509`) and 25 in BC files (all `| Stories | [filled by story-writer] |` or the Story-Anchor bullet at `BC-2.10.009.md:111`, i.e. inside the operator-ruled carve-out).
- **Predicate:** `Grep 'VP-TBD|SS-TBD|\[filled by [^\]]+\]' -o -n /Users/.../.factory/specs/prd.md` → **7 matches**: `509:[filled by architect]`, `644:VP-TBD` ×3, `650:SS-TBD` ×3.
- **Predicate:** `Grep '^\| *VP-NNN *\|' /Users/.../.factory/specs/prd.md` → **0 matches**. prd.md has no `VP-NNN`-headed table, so the R2-RULE VP-ID-column check currently hides **0** findings there.

Total currently hidden: **7 occurrences, 0 R2-RULE findings**. All 7 are historical (adjudicated per-occurrence in P7-S8-002).

**Second-order finding within (b):** the `EXCLUDE_PATHS` entry `str(REPO / ".factory" / "policies.yaml")` (`check-placeholders.py:224`) is **dead code**. `main()` iterates `SPECS.rglob("*.md")` (`check-placeholders.py:382`); `.factory/policies.yaml` is (i) outside `SPECS` and (ii) not `*.md`, so `should_check()` can never be called with it. Predicate: `Grep 'VP-TBD|SS-TBD|\[filled by' -o -n /Users/.../.factory/policies.yaml` → **8 matches** (lines 244,252,255,256 VP-TBD; 260,268,270,271 SS-TBD) — none of which the checker would ever reach. The docstring at `check-placeholders.py:41` ("Excludes: policies.yaml verification_steps") therefore documents an exclusion that does nothing, and the entire practical effect of `EXCLUDE_PATHS` is the prd.md line.

**(c) The correct replacement is positional, and it must be two predicates, not one.** The existing `slp.is_historical_changelog_line()` (`spec_lint_primitives.py:156-188`) does **not** cover these sites — I traced both:
- `prd.md:644` — `has_version` = True (`"VP-INDEX v1.1"`), but `in_quotes` = False (the line contains no `"` at all, and `_CHANGELOG_VERSION_RE` requires `"…v\d+.\d+…"`). Returns **False**.
- `prd.md:650` — `has_version` = False (no `v\d+\.\d+` token on the line). Returns **False**.

So deleting `EXCLUDE_PATHS` today produces **7 false positives**. The replacement predicate must be:
1. **Changelog-region scoping (positional):** a placeholder token is HISTORICAL if it occurs (i) inside a YAML `changelog:` / `modified:` frontmatter block, **or** (ii) inside a markdown body region opened by a `## Changelog` H2 or a `### v<N>.<N>` remediation-narrative H3 and closed by the next H2/H3 of equal-or-higher level. This is document-position-based, requires no filename, and generalises to every spec artifact.
2. **Inline-code-span scoping (lexical):** a placeholder token wholly enclosed in a backtick code span is a *citation of the pattern*, not an instance. `prd.md:509`'s `` `[filled by architect]` `` is caught by this predicate alone, which is strictly narrower than the whole-file exclusion. Note `check-placeholders.py:271-280` already suppresses *fenced* blocks; the *inline span* case is the missing sibling.

Either predicate alone would close all 7; both together are the honest scoping. Neither disables the check for prd.md going forward — which is the failure mode `EXCLUDE_PATHS` currently has.

**(d) Enumeration across all checkers, by predicate.** `Grep 'def should_check|\.name ==|\.name !=|md_file ==|md_file !=|== PRD|!= PRD|\.stem ==|in str\(|not in s\b|in s:|startswith\(|endswith\(' --glob 'check-*.py' /Users/.../scripts/spec-lint` → 44 hits across 7 checkers. Classified:
- **File-path-keyed skip-set:** `check-placeholders.py:223-239` only. **1 of 7 checkers.**
- **Directory-scoped exclusions (structurally justified):** `check-placeholders.py:237` and `check-holdout-boundary.py:98,101` (`/.factory/cycles/`, `/.factory/planning/`, `holdout-scenarios`). `holdout-scenarios` must be excluded — it is the artifact class that is *supposed* to hold scenario detail.
- **Single-file positive scoping (justified):** `check-id-resolution.py:144`, `check-index-integrity.py:137,201,592` — these select the one index file a given sub-check applies to.
- **Unguarded scope reductions of a *different shape* that the vocabulary guard also cannot see:** `check-holdout-boundary.py:149` (`re.match(r"^\s*\|", line)` — restricts POL-18 to markdown table rows) and `check-adr-consistency.py:156` (`ADR_DIR.glob("ADR-*.md")` — restricts POL-19 to 8 ADR files). Both are far more consequential than `EXCLUDE_PATHS`, and both have live corpus instances. Filed separately as P7-S8-005 and P7-S8-006.

**Consequence:** the class is not closed. The guard gives false assurance; the one skip-set it misses is currently benign, and the two scope reductions it cannot see by construction are not.

**Tag:** [process-gap]

---

### P7-S8-002 — the prd.md `[filled by]` occurrence: 1 site, HISTORICAL, Stories carve-out inapplicable and unnecessary [LOW]

**Verdict:** There is exactly **one** occurrence. It is **HISTORICAL**, not LIVE. It does **not** fall inside the Stories carve-out — and does not need to.

**Predicate:** `Grep 'VP-TBD|SS-TBD|\[filled by [^\]]+\]' -o -n /Users/.../.factory/specs/prd.md` → 7 matches. Per-occurrence verdicts:

| Line | Match | Context | LIVE / HISTORICAL | In Stories carve-out? |
|---|---|---|---|---|
| `prd.md:509` | `[filled by architect]` | `### v1.9 — Architecture Module Resolution` narrative: "Closed all 22 `` `[filled by architect]` `` placeholders across 26 BC files" — inside a backtick span, reporting a **completed** remediation | **HISTORICAL** | **No.** Not a table row whose first cell is `Stories`; not a `- ` bullet under `## Story Anchor`. Carve-out is structurally inapplicable — and irrelevant, because the token is a citation, not a field. |
| `prd.md:644` ×3 | `VP-TBD` | `### v1.4 — Adversary Pass-1 Remediation` narrative, F-007 entry, ending "Zero VP-TBD remaining" | **HISTORICAL** ×3 | No — and inapplicable (VP-TBD has no Stories carve-out at all) |
| `prd.md:650` ×3 | `SS-TBD` | `### v1.4` narrative, F-011 entry, ending "Zero SS-TBD remaining" | **HISTORICAL** ×3 | No — inapplicable |

**Corroboration that "Zero VP-TBD/SS-TBD remaining" is true outside prd.md:** `Grep 'VP-TBD|SS-TBD' /Users/.../.factory/specs` → 24 occurrences total; every one outside prd.md is inside a YAML `changelog:`/`modified:` quoted version entry (e.g. `BC-2.02.004.md:23: - "v1.1: (F-007) VP-TBD backfill from VP-INDEX v1.1"`). Zero live BC-level placeholders. The v1.4 claim is accurate.

**Consequence:** No unadjudicated LIVE placeholder exists in prd.md. The Phase-1 gate is not blocked by a placeholder. However, the *reason* it is unblocked is the whole-file exclusion, not a positional predicate — so this specific verdict cannot be re-derived by the toolchain, only by hand. That is the residual defect, and it is P7-S8-001's, not a content defect in prd.md.

---

### P7-S8-003 — `DD-007` / `D-007` / `DI-007` is a systemic three-namespace collision, and L2-INDEX mis-files DD-007 as a human decision [HIGH]

**Verdict:** This is a **systemic collision class, not a single-site typo** — but every existing `DD-007` citation in the corpus resolves correctly. The defect is (i) that index 007 is the worst possible collision point because `D-007` and `DI-007` are the *same topic* while `DD-007` is unrelated, (ii) that no artifact carries a disambiguation legend, and (iii) that `L2-INDEX.md` places `DD-007` in a table titled "Human Decisions" when `decisions.md` classifies it as a PO decision.

**What each registry defines at index 007 — established by predicate:**

| ID | Defined at | Denotes |
|---|---|---|
| `DD-007` | `domain-spec/decisions.md:85`, under the H2 `## PO Decisions — Resolved [PO] Questions (DD-007–DD-016)` (`decisions.md:81`) | "Q6 — Exit-code precedence and fail-fast … **No fail-fast** … Domain Artifact: **DI-011**" |
| `D-007` | `domain-spec/decisions.md:65`, Source column of row **DD-003** | Human decision: "HTML anchors: extract `id=` and `name=` attributes only from inline/raw HTML … Domain Artifact: **DI-007**" |
| `DI-007` | `domain-spec/invariants.md:209` | "HTML Anchor Extraction Scope Is Narrow" |

**Predicates.**
- `Grep '\bDD-007\b' /Users/.../.factory/specs` → **22 occurrences across 11 files**. I checked every one: all denote exit-code precedence / no-fail-fast. `capabilities.md:248`, `invariants.md:285`, `L2-INDEX.md:131`, `prd.md:632,703,746`, `interface-definitions.md:237`, `test-vectors.md:420`, `BC-2.01.009.md:41,52,58`, `BC-2.14.002.md:60,89`, `system-overview.md:253,266,272,273` — **0 mis-glosses**.
- `Grep 'D-007' /Users/.../.factory/specs` → **31 total occurrences across 11 files** (this superset includes DD-007; the bare-`D-007` residue is `decisions.md:65`, `L2-INDEX.md:127`, `BC-2.05.003.md:25,83`).
- `Grep '\bDI-007\b' /Users/.../.factory/specs` → **21 occurrences across 12 files**. All denote HTML-anchor narrow scope.

**Live defects flowing from the collision:**

1. **`L2-INDEX.md:122-131` mis-files DD-007.** The table heading is `### Human Decisions → Domain Invariants` (`L2-INDEX.md:122`). Row `L2-INDEX.md:127` is `| D-007 (HTML anchor narrow carve-out) | DI-007 |` — correct, D-007 *is* human. Row `L2-INDEX.md:131` is `| DD-007 (exit code precedence) | DI-011 |` — **DD-007 is not a human decision**; `decisions.md:50-51` states explicitly "Decisions DD-001–DD-006 and DD-017–DD-027 are from human/orchestrator decisions (binding). **DD-007–DD-016** resolve the [PO]-tagged open questions." Same defect at `L2-INDEX.md:130` (`DD-012`) and `:132` (`DD-008`). Three PO decisions sit inside a table asserting human authority. POLICY 4 mis-anchor: a reader treats DD-007/008/012 as frozen human rulings when they are PO-level and therefore revisable.

2. **The `BC-2.05.003.md:25` changelog is the diagnostic artifact for the collision, and it names all three IDs in one sentence**: `"v1.3: (WS-4-G) Citation-authority repair: replaced misreferenced DD-007 with DD-003 in Description; … added missing DI-007 to L2 Domain Invariants; replaced wrong brief requirement R5/DD-007 with R2b/D-007."` The prescribed edit ("DD-007 → DI-007 + DD-003") and the executed edit (DD-003, D-007, DI-007) differ because the *prescription conflated the namespaces*: the correct decision-layer citation for BC-2.05.003's HTML carve-out is **DD-003** (the DD row) whose Source is **D-007** (the human decision), and the invariant is **DI-007**. All three are needed; the prescription named only two. The executed edit is **correct**; the prescription was wrong. The `R5 → R2b` change was also correct on the merits (see P7-S8-016), though it was indeed unprescribed.

3. **No disambiguation legend exists anywhere.** `decisions.md` opens with a preamble (`decisions.md:50-57`) that uses `DD-NNN`, `D-NNN`, and `DI-NNN` in adjacent sentences without ever stating that `D-NNN` lives outside `.factory/specs/` (it is a pipeline-decision namespace with no in-corpus registry). Predicate: `Grep 'D-0(0[4-9]|1[0-9]|2[0-9]|4[0-9])' ` resolves to no definition site inside `.factory/specs/` for any bare `D-NNN` — they are cited 100+ times and defined zero times in-corpus. A fresh implementer cannot resolve `D-043`, `D-020`, `D-007` from the spec tree at all.

**Consequence:** the corpus is *currently* self-consistent about DD-007 (22/22 correct), so this is not a live wrong-behaviour risk. It is a live **re-injection** risk: the collision has already produced one mis-citation (BC-2.05.003 v1.2), the remediation prescription for that mis-citation was itself namespace-confused, and there is no legend or checker to prevent the third occurrence. Plus the L2-INDEX authority mis-filing is a present-tense POLICY 4 defect.

---

## Critical Findings

### P7-S8-004 — prd.md:616 publishes the complete input+expected-output scenario for active reserved holdout EC-151 [CRITICAL]

`prd.md:616`:
> **D-010 (holdout scenario replacement):** … Former holdout removed from holdout list; **replaced by EC-151 (hidden `## Hidden Section` inside `<details>` HTML block with `[x](#hidden-section)` → broken)**.

That is a complete scenario specification: **input** = a `.md` file containing a `<details>` HTML block enclosing `## Hidden Section`, plus the link `[x](#hidden-section)`; **expected output** = `broken`. Nothing is withheld. An implementer reading prd.md can write the passing test.

EC-151 is an **active** reserved holdout: `prd.md:365` lists it in the bold canonical pool, `test-vectors.md:29` lists it in the active-12 pool, and `HS-INDEX.md:67` records it as `not-yet-authored` (so prd.md:616 is the *only* place the scenario exists anywhere).

**Predicate:** `Grep 'EC-147|EC-141|EC-148|EC-079|EC-093|EC-094|EC-151|EC-156|EC-16[5-8]' /Users/.../.factory/specs` → 25 occurrence lines; `prd.md:616` is the only one carrying a full input+verdict pair for an active holdout in prose. `Glob '*' /Users/.../.factory/holdout-scenarios/wave-scenarios` → 7 scenario files + `.gitkeep`; **no EC-151 file**.

**Consequence:** POL-18 is breached for EC-151. Its Phase-4 evaluation signal is zero. Worse: because no scenario file exists, prd.md:616 is simultaneously the leak *and* the only record — deleting the leak without authoring `wave-scenarios/EC-151-*.md` destroys the holdout entirely rather than restoring it.

---

### P7-S8-005 — `check-holdout-boundary.py` inspects only markdown table rows, so POL-18 is structurally blind to prose leaks; it reports PASS on a corpus containing P7-S8-004 [CRITICAL]

`check-holdout-boundary.py:149`:
```python
if re.match(r"^\s*\|", line):
```
Every violation check — `bare_holdout_pattern` (`:151`) and `sub_letter_pattern` (`:160`) — is nested inside this guard. A line that does not begin with `|` is never examined for holdout content at all.

`prd.md:616` is prose. It does not begin with `|`. It is therefore **structurally unreachable** by the only checker mapped to POLICY 18. The three preceding per-line skips are also over-broad but irrelevant here:
- `:139` `if is_prd and "Holdout vectors" in line: continue` — line 616 does not contain that phrase.
- `:145` `if "HOLDOUT WARNING" in line: continue` — case-sensitive; line 616 says "holdout WARNING" (lowercase h), so it would not have matched anyway.
- `:142` `if "~~EC-" in line: continue` — **independently over-broad**: any line containing a single struck-through EC anywhere is skipped in its entirety, so a line that retires one ID while leaking another is silently exempt.

The checker's success message (`:179-182`) is `"Check passed: {files_checked} visible artifact files checked — no concrete holdout scenarios leaked (pool: {len(holdout_ids)} IDs)"`. It reports a non-zero file count and a non-zero pool size — a POL-11-conforming *shape* — while the property it claims to have checked (no full scenario in any visible artifact) is unverified for every non-table line in the corpus. `L2-INDEX.md:24` records the resulting false assurance verbatim: "check-id-resolution and check-holdout-boundary **both at 0**."

Secondary blindness in the same function: `is_concrete_scenario_row()` (`:84-92`) requires a verdict word (`alive|broken|indeterminate|clean`), an exit code, or a reason code on the line. I traced the four table rows that cite active holdouts — `decisions.md:90` (DD-012/EC-147), `decisions.md:94` (DD-016/EC-079), `failure-modes.md:84` (FM-009/EC-147), `nfr-catalog.md:79` (NFR-003/EC-147) — and **none** contains a matching token, so all four pass even though EC-147's scenario is fully reconstructible from them (P7-S8-018).

**Consequence:** POL-18, a HIGH-severity policy protecting the Phase-4 evaluation signal, has been functionally inert for prose leaks across every converged pass. This is the D-057 pattern in its purest form: the checker exists, runs, exits 0, and prints a positive-coverage line, and the property is unverified.

**Tag:** [process-gap]

---

### P7-S8-006 — `check-adr-consistency.py` (the sole POLICY 19 hook) reads only `architecture/decisions/ADR-*.md`; the closed-taxonomy check never sees prd.md, prd-supplements, domain-spec, or behavioral-contracts [CRITICAL]

`check-adr-consistency.py:156`:
```python
for adr_file in sorted(ADR_DIR.glob("ADR-*.md")):
```
`ADR_DIR = SPECS / "architecture" / "decisions"` (`:28`). No other path is ever opened for checking; `error-taxonomy.md` is read only to *build* the valid-code set (`:142`), never to be checked, and `SPECS.rglob` is never called.

POLICY 19 is stated as *closed-taxonomy enforcement* — "Every reason code anywhere in the corpus must exist VERBATIM in error-taxonomy.md." The hook covers **8 ADR files** out of the 134-file spec corpus. Reason codes in prd.md §5, error-taxonomy.md itself, failure-modes.md, test-vectors.md, interface-definitions.md, and all 66 BC files are **never validated against the closed set**.

That is why P7-S8-007 (`malformed-fragment` at `test-vectors.md:432`) is live. And the miss is doubled: the code-extraction regex is `` re.finditer(r"`([a-z][a-z0-9-]{3,})`", line) `` (`:121`) — **backtick-delimited only**. `test-vectors.md:432` writes the phantom code as bare text `broken (malformed-fragment)`, with no backticks. Even if the checker's file scope were widened to the whole corpus, this specific violation would still be missed. Two independent structural gaps guarding the same defect.

The success message (`:170-173`) reads `"Check passed: {adrs_checked} ADRs checked — all exit codes and reason codes consistent with error-taxonomy.md"`. "all … reason codes" overclaims: only ADR reason codes were examined.

**Consequence:** POLICY 19 provides no corpus-wide coverage. A phantom reason code reaching implementation means `verdict::exit_code` and the JSON `reason` field receive a value outside the enum, which is the exact class NFR-007 exists to make impossible — and NFR-007's own validation method (`nfr-catalog.md:137`) is a runtime parsing test that does not exist yet, so nothing checks it at spec time either.

**Tag:** [process-gap]

---

### P7-S8-007 — `test-vectors.md:432` asserts the phantom reason code `malformed-fragment`, and contradicts its own sibling vector TV-070 and DI-003 [CRITICAL]

`test-vectors.md:432`:
```
| TV-197 | EC-197 | `[x](a.md##double-hash)` — malformed fragment with double `#` | BC-2.08.003 | (none) | 1 | broken (malformed-fragment) | Formerly EC-076 in BC-2.08.003; double-`#` is syntactically malformed |
```

**Predicate:** `Grep 'malformed-fragment' /Users/.../.factory` → **1 occurrence in `.factory/specs`**, this line. It appears nowhere in `error-taxonomy.md` §2 or §3, nowhere in `failure-modes.md`, and in no BC.

The closed set is 13 codes (`error-taxonomy.md:99-102`, `failure-modes.md:53-67`); `malformed-fragment` is not among them. `error-taxonomy.md:23` states "Nothing may fail with a reason outside this set." `prd.md:359` repeats it.

**Compounding: the vector also asserts the wrong behaviour.** `DI-003` (`invariants.md:105-109`) is unconditional: "The fragment component is split from a link destination at the **first unescaped `#`** … After splitting, each component is percent-decoded independently." Applied to `a.md##double-hash`: path = `a.md`, fragment = `#double-hash`. There is no "malformed" branch. Its sibling row `test-vectors.md:155` (TV-070) applies exactly that rule to exactly that shape and reaches the opposite conclusion:
```
| TV-070 | EC-070 | `a.md` | `## A` | `[x](a.md#a#b)` | 1 | broken | Fragment = `a#b` (includes second #); no such slug |
```
TV-070 says a multi-`#` destination yields a fragment containing the extra `#`, hence `anchor-not-found`. TV-197 says the same construction is "syntactically malformed" and invents a code for it. Both cite the same governing BC family (BC-2.08.003 / DI-003).

**Consequence:** a test-writer implementing TV-197 adds a 14th reason code and a `Malformed` branch to the fragment splitter that DI-003 forbids, which then makes TV-070 fail. Two vectors in the same file cannot both pass. Also invalidates the `NFR-007` "zero unrecognized reason strings" target and the `TV-134a`+`TV-134b` claim (`test-vectors.md:248`) that "Together TV-134a + TV-134b exercise **all 13** reason codes in the closed taxonomy."

---

### P7-S8-008 — a nonexistent PATH argument must be emitted in the JSON `errors[]` array, but the closed taxonomy has no reason code whose trigger it satisfies [CRITICAL]

The four artifacts are individually consistent and jointly unsatisfiable:

1. **Nonexistent PATH must be recorded as an I/O error and reach exit 2.** `interface-definitions.md:237`: "Nonexistent PATH argument | Error recorded (E-IO-002); scanning continues …; exit 2 after all scanning completes." `capabilities.md:246-247` (CAP-014): "`io_errors` receives: unreadable `.md` file …; **nonexistent PATH argument**." `capabilities.md:19` (v1.6 changelog) records this as a deliberate ruling: "'nonexistent PATH argument' moved from 'usage error' category to 'I/O error' category."
2. **I/O errors go in JSON `errors[]`, and the `reason` field is mandatory and single-valued.** `interface-definitions.md:200-206` §6.2b: `reason` | string | **yes** | "Always `"target-unreadable"` (from the closed taxonomy)". `BC-2.13.001.md:56-58` PC7: "File-level I/O errors (reason `target-unreadable`) are emitted in the `errors` array … Each error object has fields: `file`, `reason`, `message`."
3. **`target-unreadable`'s trigger requires the file to exist.** `error-taxonomy.md:91`: "Source `.md` file **exists** but cannot be read (permission denied, non-UTF-8 content, unexpected read error)." `failure-modes.md:65`: "**File exists** but cannot be processed." `error-taxonomy.md:166` §6.1 enumerates the two covered conditions — permission-denied and invalid-UTF-8 — and neither is "path absent."
4. **The taxonomy is closed at 13.** `error-taxonomy.md:99-102`, `:176` ("The closed taxonomy remains 13 codes").

A nonexistent PATH does not exist, so `target-unreadable` is false for it; and §6.2b permits no other value. `E-IO-002` is not a member of the taxonomy either — **predicate:** `Grep 'E-IO-002|E-IO-001|E-CLI-001' /Users/.../.factory/specs` → 8 occurrences across 3 files (`interface-definitions.md:237`; `BC-2.01.009.md:23,44,52,71,73`; `BC-2.11.004.md:61`) and **zero definition site** — `E-IO-002` and `E-CLI-001` are cited as an "error class taxonomy" that exists in no artifact.

`test-vectors.md` records the gap without resolving it: `:82` TV-012 → "Exit 2 **with reason indicating path not found**" (no code named, because none exists); `:420` TV-185 → "exit 2 (I/O error)" with no reason field.

**Consequence:** `--format json` on `mdlinkcheck /does/not/exist` has no conformant output. Any implementation either (a) invents a 14th code, breaking NFR-007 and the closed-set invariant, (b) emits `target-unreadable` for a nonexistent path, contradicting three trigger definitions, or (c) omits the error from `errors[]`, contradicting CAP-014 and making exit 2 unexplainable in machine-readable output — the exact "CI engineer can distinguish broken links from scan failures" capability `interface-definitions.md:174` claims the array delivers.

---

## Important Findings

### P7-S8-009 — the JSON `errors[]` array is mandatory in the BC and optional in the interface spec; the two most important test vectors emit the non-conformant shape [HIGH]

`BC-2.13.001.md:48` PC1: "**Both `results` and `errors` are always present**; each may be an empty array." Invariant 3 (`:64`): "An empty scan … produces `{"schema_version":1,"results":[],"errors":[]}`."

Against:
- `interface-definitions.md:174`: "`errors` is **omitted** (or an empty array `[]`) when no I/O errors occurred."
- `interface-definitions.md:182` §6.1: "`errors` | array | … Empty array `[]` **or omitted** when no I/O errors."
- `test-vectors.md:55` — the expected JSON for **TV-BV013**, described at `:44-47` as "the single most important correctness proof for R4" and "must be in the standard test suite AND verified manually at acceptance": `{"schema_version": 1, "results": []}` — **`errors` omitted**.
- `test-vectors.md:246` — TV-133, the canonical `--format json` clean-run vector: `{"schema_version":1,"results":[]}` — **`errors` omitted**.
- `prd.md:298` §3 interface summary: `{schema_version: 1, results: [{file, line, column, link_target, verdict, reason}]}` — **`errors` absent entirely**, contradicting `prd.md:314` sixteen lines later in the same section, which gives the three-field envelope.

**Consequence:** a consumer written against `BC-2.13.001` Inv 3 does `.errors | length` unconditionally and crashes on the shape TV-BV013 and TV-133 assert; a consumer written against `interface-definitions.md` §6.1 must null-guard. TV-BV013 and TV-133 will fail an implementation that satisfies BC-2.13.001 PC1, so the acceptance suite cannot be made green against the BC.

---

### P7-S8-010 — `events.md:119` prescribes an empty JSON **array** on a clean run, the exact shape DD-023 declares non-conforming [HIGH]

`events.md:119`, Stage 6 Report Assembly:
> **Empty result:** Zero findings → **empty JSON array `[]`** or no output lines; exit 0.

`decisions.md:75` (DD-023, human ruling D-017): "The authoritative shape is `{schema_version: 1, results: [...], errors: [...]}`. … **A JSON array literal is NOT a conforming implementation.**" `prd.md:313-314` gives the same binding interpretation. `capabilities.md:218-224` (CAP-013) is correct.

`event-flow.md:23` designates `events.md` as normative: "the **normative** processing stage definitions are in `events.md`."

**Consequence:** the normative stage document prescribes, for the single most common invocation outcome (clean repo, `--format json`), output that the authoritative decision explicitly rejects. An implementer building Stage 6 from `events.md` emits `[]`, and every downstream `jq '.results'` consumer breaks. The `capabilities.md:25` v1.4 changelog records the CAP-013 half of this fix ("corrected from impossible 'JSON array with schema_version field' to correct JSON object envelope"); `events.md` (still v1.1, `events.md:5`) was never swept.

---

### P7-S8-011 — DD-011 and DD-023 contradict each other inside the same decision register [HIGH]

`decisions.md:89` (DD-011): "JSON output includes a top-level `schema_version: 1` field. **Output is an array of finding objects** with fields: `{file, line, column, link_target, verdict, reason}`."

`decisions.md:75` (DD-023), five rows earlier in the same file: "**A bare JSON array cannot carry a `schema_version` field**; the envelope design … is therefore the correct binding interpretation of R6. … A JSON array literal is NOT a conforming implementation."

DD-011 is not marked superseded, struck through, or annotated. It is still cited as live authority by `capabilities.md:227` ("DD-011, DD-023"), `entities.md:129` ("JSON (`--format json`, DD-011)"), `failure-modes.md:51` ("All are emitted in both text and JSON output (**DD-011**)"), and `nfr-catalog.md:138` (NFR-007 Source: "DD-011, FM-NNN catalog"). DD-011's field list also predates D-016 and omits `sub_reason`.

**Consequence:** the decision register — the artifact whose entire purpose is to be the single resolution point for ambiguity — contains two live, mutually exclusive rulings on the product's machine-readable contract. Four downstream artifacts cite the losing one. DD-011 needs an explicit "superseded by DD-023 for shape; field list amended by D-016" annotation.

---

### P7-S8-012 — DI-001's four-field sort key did not propagate to four L2 artifacts, including the DD that DI-001 cites as its own authority [HIGH]

`invariants.md:61-71` (DI-001, v1.7): sort key is `(NFC-normalized file path, line number, column number, **link_target**)`, with an explicit totality argument — "The fourth field `link_target` … is the tie-break that makes the key total … `sort_unstable_by` is safe given totality." `invariants.md:28` (v1.7 changelog) states "DI-001 is the L2 authority and must lead."

**Predicate:** `Grep 'line number, column number\)|line, column\)|path, line, col\)|line, column, link_target\)' /Users/.../.factory/specs` → 4-field at `invariants.md:63`, `interface-definitions.md:125,196`, `BC-2.13.001.md:52`, `system-overview.md:192`, `api-surface.md:142`, `ADR-005:44,75,95`. **Three-field survivors, all in shard-8 scope:**

| Site | Text |
|---|---|
| `decisions.md:90` (DD-012) | "All findings sorted by `(NFC-normalized file path, line number, column number)` before emission" |
| `capabilities.md:206-207` (CAP-012) | "sorted by (NFC-normalized file path, line number, column number) per DI-001" |
| `events.md:118` (Stage 6) | "Sorted finding list (DI-001: by NFC path / line / column)" |
| `event-flow.md:77` | "Sort by (path, line, col) (DI-001)" |

Blast radius = 4 → HIGH per partial-fix regression discipline. The most consequential is `decisions.md:90`: `invariants.md:81` cites "Decision DD-012" as DI-001's authority, so the invariant's own cited decision states a *different, non-total* key.

**Consequence:** an implementer building the text reporter from CAP-012 (which is CAP-012's job — it owns text output) sorts on three fields. Per ADR-005's totality argument that key is **not total** for reference-style links reported at multiple use-sites (see TV-202, `test-vectors.md:437`: two findings at line 3 and line 7 from one definition — and the converse, two distinct findings sharing `(path, line, column)`). `sort_unstable_by` on a non-total key is order-unstable, which silently violates DI-001 and NFR-003 determinism under varying `RAYON_NUM_THREADS` — the precise failure FM-009 names.

---

### P7-S8-013 — `events.md:52` prescribes `fs::canonicalize`-based deduplication *while citing DI-009*, which forbids it by name [HIGH]

`invariants.md:249-252` (DI-009, v1.10): the dedup key must be "NFC-normalized, lexically-normalized (`.`/`..` collapsed), **NOT-`fs::canonicalize`** key. (`fs::canonicalize` **case-folds on macOS APFS, which would conflict with DI-002**; the non-canonicalizing key form is **mandatory**.)"

`events.md:52`, Stage 2 File Discovery:
> **Rules:** … deduplicate by **canonicalized** path; terminate on symlink cycles (**DI-009**).

The same sentence prescribes the forbidden operation and cites the invariant forbidding it. `entities.md:64` compounds it: MarkdownFile `| path | absolute path | **canonicalized**, NFC-normalized |`.

**Predicate:** `Grep -i 'canonicaliz' /Users/.../.factory/specs` → 13 occurrence lines. Correct: `invariants.md:250-251`, `system-overview.md:134` ("NON-canonicalized (no `fs::canonicalize` — canonicalize case-folds on macOS"). Incorrect in shard-8 scope: `events.md:52`, `entities.md:64`. (Corroborating, other shards' subject: `BC-2.01.002.md:52`, `BC-2.01.007.md:46` — "Deduplication is by canonicalized real path (resolves `.`, `..`, symlinks)"; `BC-2.07.001.md:37,45`.)

**Consequence:** this is the KD-004 flagship differentiator's failure mode. `fs::canonicalize` on APFS returns the on-disk case, which makes the resolved path a function of the filesystem rather than of repository content — exactly what `invariants.md:94-101` (DI-002 rationale) and `decisions.md:64` (DD-002, canonical D-043 rationale) forbid. An implementer building Stage 2 from `events.md` writes the case-folding bug that TV-036 exists to catch, and does so believing DI-009 sanctions it.

---

### P7-S8-014 — `events.md:66` offers two mutually exclusive behaviours for non-UTF-8 content in a normative stage definition [HIGH]

`events.md:66-67`, Stage 3:
> **Non-UTF-8 content:** **Decoded lossily** OR reported as per-file I/O error → mark exit-2 pending, exclude from further stages.

These are not compatible. Lossy decoding (`String::from_utf8_lossy`) yields a parseable buffer, produces findings, and implies **no** I/O error and **exit 0/1**. Reporting a per-file I/O error yields **no** findings for that file and **exit 2**.

The rest of the corpus has adjudicated this unambiguously in favour of the second: `prd.md:125` BC-2.02.003 title is "Non-UTF-8 File Reported as Per-File I/O Error; Scan Continues"; `error-taxonomy.md:91` includes "non-UTF-8 content" in `target-unreadable`; `error-taxonomy.md:166` §6.1 (b) "invalid UTF-8 content"; `failure-modes.md:65` and `failure-modes.md:108-113` ("F-032 Decision Record") settle it as one reason code at exit 2; `test-vectors.md:84` TV-014 asserts `exit 2; errors:[{file:"bad.md",reason:"target-unreadable"}]`.

`event-flow.md:23` designates `events.md` as normative, and `event-flow.md:53` carries only the correct branch ("Non-UTF-8 ──── I/O error (mark exit-2)") — so the normative doc is the *less* correct of the pair.

**Consequence:** the sole remaining "decode lossily" survivor sits in the document declared normative for stage behaviour. An implementer taking the first disjunct produces exit 1 (or 0) where TV-014 demands exit 2, and F-032's single-failure-mode decision record is silently voided.

---

### P7-S8-015 — prd.md §7 RTM `Brief Req` column disagrees with the BC files' own `Brief Requirement` field at 19 of 66 rows; the RTM has no GENERATED markers and its generator silently no-ops [HIGH]

**Predicate A:** `Grep '^\| Brief Requirement \|' /Users/.../.factory/specs/behavioral-contracts` → **66 rows**, one per BC. **Predicate B:** prd.md §7 RTM rows are `prd.md:421-486` (66 rows). Cross-comparing all 66 pairs yields **19 rows where the RTM names a different R-requirement than the BC file**:

| BC | prd.md §7 says | BC file's own field says |
|---|---|---|
| BC-2.02.002 | `R2` (`:431`) | `R2a` (`BC-2.02.002.md:103`) |
| BC-2.05.001 | `R5` (`:443`) | `R2b, BV-009` (`BC-2.05.001.md:119`) |
| BC-2.05.003 | `R5` (`:445`) | `R2b, D-007` (`BC-2.05.003.md:83`) |
| BC-2.07.001 | `R2a` (`:448`) | `R5, R6, T7` (`BC-2.07.001.md:82`) |
| BC-2.07.002 | `R2a` (`:449`) | `R5, AMB-017` (`BC-2.07.002.md:82`) |
| BC-2.07.004 | `R2a` (`:451`) | `R5, R6, T9` (`BC-2.07.004.md:83`) |
| BC-2.07.005 | `R2a` (`:452`) | `R5, AMB-024` (`BC-2.07.005.md:95`) |
| BC-2.07.006 | `R2a` (`:453`) | `R5, EC-072, EC-073` (`BC-2.07.006.md:95`) |
| BC-2.08.002 | `R5` (`:457`) | `R2b` (`BC-2.08.002.md:111`) |
| BC-2.09.001 | `R2c` (`:460`) | `R5, R6, T11` (`BC-2.09.001.md:82`) |
| BC-2.09.002 | `R2c, R5` (`:461`) | `R5` (`BC-2.09.002.md:85`) |
| BC-2.10.001 | `R2c` (`:462`) | `R5, DD-016, T12` (`BC-2.10.001.md:91`) |
| BC-2.10.003 | `R2c` (`:464`) | `R5` (`BC-2.10.003.md:79`) |
| BC-2.10.004 | `R2c` (`:465`) | `R5, AMB-088` (`BC-2.10.004.md:99`) |
| BC-2.10.006 | `R2c` (`:467`) | `R5, AMB-090` (`BC-2.10.006.md:78`) |
| BC-2.10.007 | `R2c` (`:468`) | `R5, AMB-086` (`BC-2.10.007.md:83`) |
| BC-2.11.001 | `R5` (`:472`) | `R6, DD-008` (`BC-2.11.001.md:89`) |
| BC-2.11.004 | `R5` (`:475`) | `R6, DD-008` (`BC-2.11.004.md:87`) |
| BC-2.13.002 | `R6, R7` (`:482`) | `R6, NFR-007` (`BC-2.13.002.md:77`) |

The same comparison on the `L2 Invariants` column (predicate: `Grep '^\| L2 Domain Invariants \|' …behavioral-contracts` → 47 rows recovered) yields **8 further mismatches**: BC-2.01.009 (RTM `—` vs BC `DI-011`), BC-2.02.003 (`—` vs `DI-011`), BC-2.05.003 (`DI-008` vs `DI-007, DI-008`), BC-2.07.002 (`DI-002` vs `DI-002, DI-003`), BC-2.07.004 (`DI-003` vs `DI-002, DI-003`), BC-2.10.002 (`DI-005, DI-010` vs `DI-010`), BC-2.10.003 (`DI-005` vs `DI-010`), BC-2.14.003 (`—` vs `DI-010, DI-011`).

**Two prd.md changelog entries are self-refuting against this state:**
- `prd.md:816` (v1.1): "**BC-2.07.005: brief requirement corrected R2a → R5**." The BC file says `R5`; RTM `:452` still says `R2a`. The correction was applied to one side only and then recorded as done.
- `prd.md:664` (v1.4, F-028): "Brief Requirement corrected from `R2, AMB-012, AMB-013` → **R2a**" for BC-2.02.002. RTM `:431` still says `R2`.

**Why it is unenforced (POLICY 17).** **Predicate:** `Grep 'BEGIN GENERATED|END GENERATED' /Users/.../.factory/specs/prd.md` → **28 occurrences**, all §2 subsystem tables (14 × 2). The `prd-s7-rtm` markers that `gen-rtm.py:46-47` requires are **absent**. `gen-rtm.py:186-194` handles that by printing a NOTICE, advising "use check-counts.py to detect RTM drift manually," and `return 0` — a silent success. And `check-counts.py:150-165` (`count_prd_rtm_rows`) counts **rows only**, comparing the total against `total_bcs`; it never compares a single cell. So §7 is a hand-maintained derived table with a generator that no-ops and a "drift detector" that checks cardinality.

**Consequence:** the Requirements Traceability Matrix — the artifact whose entire purpose is authoritative brief↔BC traceability — is wrong in 27 cells and no gate can see it. Story decomposition reading §7 assigns BC-2.05.001 to R5 (`--ignore`/`--allow`) and BC-2.07.001 to R2a while the BC bodies say the reverse, so acceptance criteria will be written against the wrong frozen requirement in both directions.

---

### P7-S8-016 — prd.md §7 RTM anchors anchor-table and anchor-resolution contracts to frozen R5 (`--ignore`/`--allow`), and private-IP URL classification to R5; the "R2b → R5" substitution mis-anchored the contracts [HIGH]

Independent of the RTM↔BC divergence in P7-S8-015: several RTM cells are **semantically wrong against the frozen brief regardless of what the BC file says**.

`product-brief.md:46-47` (R5, FROZEN): "`--ignore <glob>` (repeatable) excludes files; `--allow <url-prefix>` (repeatable) exempts external URLs from checking." `product-brief.md:39-40` (R2b): heading anchors, `[x](#setup)`, `[x](a.md#usage)`, GitHub slug algorithm. `product-brief.md:41-43` (R2c): absolute http(s) URLs, HEAD/GET, 10s timeout, `--online`.

RTM cells that mis-anchor:

| RTM row | BC title (prd.md §2) | RTM `Brief Req` | Correct anchor |
|---|---|---|---|
| `prd.md:443` BC-2.05.001 | "Three-Phase Design — Full Anchor Table Before Any Resolution" | `R5` | `R2b` |
| `prd.md:444` BC-2.05.002 | "ATX and Setext Heading Extraction into Anchor Table" | `R5` | `R2b` |
| `prd.md:445` BC-2.05.003 | "HTML `id=` and `name=` Attribute Extraction into Anchor Table" | `R5` | `R2b` (+ D-007 carve-out) |
| `prd.md:456` BC-2.08.001 | "Anchor-Only Link Resolution (`#fragment`)" | `R5` | `R2b` — this is verbatim R2b's `[x](#setup)` |
| `prd.md:457` BC-2.08.002 | "Cross-File Anchor Resolution (`path.md#fragment`)" | `R5` | `R2b` — verbatim R2b's `[x](a.md#usage)` |
| `prd.md:458` BC-2.08.003 | "Fragment Split at First Unescaped `#` Before Percent-Decode" | `R5` | `R2b` |
| `prd.md:471` BC-2.10.010 | "Private-IP and Link-Local URL Classification" | `R5, D-008` | `R2c` |

`prd.md:815` records the substitution as intentional: "BC-2.08 series: DI assignments updated; **"R2b" → "R5" throughout** (brief requirement alignment)." It was not an alignment — R5 is the filter flags. `BC-2.08.002.md:111` and `BC-2.05.003.md:83` were subsequently corrected back to `R2b` (the latter recorded at `BC-2.05.003.md:25` as part of the WS-4-G repair), which confirms `R2b` is the right anchor and that the substitution damaged the anchors.

Two further RTM cells cite non-brief tokens in a column titled `Brief Req`: `prd.md:471` (`D-008` — a human decision) and `prd.md:461`/`:429` mixing. And `prd.md:471` BC-2.10.010's own BC file agrees with the wrong value (`BC-2.10.010.md:94`: `R5, D-008`), so this cell is wrong on both sides.

**Consequence (POLICY 4, CRITICAL-tier mis-anchor semantics).** The RTM is the input to story decomposition. Six of the eight contracts implementing the product's flagship differentiator (KD-001, correct anchor checking — `prd.md:62`) trace to a requirement about glob filtering. A story-writer deriving acceptance criteria from §7 will write `--ignore`/`--allow` assertions for BC-2.08.001/002/003 and no anchor assertions, which is exactly the "builds the wrong thing" outcome. `prd.md:375-382` §6.1 KD-001 correctly attributes all of these to anchor behaviour, so §6.1 and §7 disagree about what BC-2.05.*/BC-2.08.* are for inside the same document.

---

### P7-S8-017 — 7 of the 12 declared active holdouts have no scenario file; the reserved-but-unauthored IDs are withheld from the visible suite while defining nothing [HIGH]

`prd.md:365` §5b declares the canonical pool: "Holdout vectors **(EC-079, EC-093, EC-094, EC-141, EC-147, EC-148, EC-151, EC-156, EC-165, EC-166, EC-167, EC-168)** reserved for holdout evaluation and NOT in the visible test suite — **12 holdouts total**." `test-vectors.md:28-29` repeats "Active holdout pool (12 total)."

**Predicate:** `Glob '*' /Users/.../.factory/holdout-scenarios/wave-scenarios` → 8 entries: `.gitkeep` + `EC-156`, `EC-157`, `EC-158`, `EC-165`, `EC-166`, `EC-167`, `EC-168`. Of these, `EC-157` and `EC-158` are **retired/burned** (`HS-INDEX.md:42-43`, D-020). **Active authored scenarios = 5** (HS-001, HS-004..HS-007).

`HS-INDEX.md:56-67` states the gap outright — a "Reserved IDs — Not Yet Authored" table with `EC-079`, `EC-093`, `EC-094`, `EC-141`, `EC-147`, `EC-148`, `EC-151` each annotated "(scenario not yet specified)" / `not-yet-authored`.

So `12` vs `5` is a live derived-count divergence between `prd.md`/`test-vectors.md` and `HS-INDEX.md`. `check-counts.py:168-176` (`count_active_holdouts`) reads only HS-`HS-\d+` rows from HS-INDEX and, per its docstring (`check-counts.py:15`), compares "active holdout count vs declared" — it does **not** compare against the prd.md §5b bold list, so the 12-vs-5 divergence is unenforced. Meanwhile `check-holdout-boundary.py:53-71` derives its enforcement pool from the **union** of the prd.md 12 and the HS-INDEX actives, so the 7 phantom IDs inflate the pool the checker reports (`:112`, `:181`) and inflate the apparent coverage.

**Consequence:** seven EC IDs are excluded from `test-vectors.md` (see the exclusion notes at `test-vectors.md:173` and `:232`) on the strength of a holdout designation that backs nothing. For each, the behaviour has **neither** a visible vector **nor** a hidden scenario. Concretely: EC-079 is the GET-fallback status set — `test-vectors.md` has TV-078 (405) and TV-080 (501) but **no vector for the 400 / 403 / 404 / 999 fallback branches** that DD-016 (`decisions.md:94`) adds and that R-003 (`risks.md:38`) rates HIGH impact; EC-151 is the `<details>`-block anchor case with no vector at all. The holdout mechanism is being used, unintentionally, as a coverage-gap concealer.

---

### P7-S8-018 — EC-147's complete scenario (input + expected output) is reconstructible from three visible artifacts, after the v1.6 sweep claimed to remove active-holdout citations [HIGH]

EC-147 is an active reserved holdout (`prd.md:365`, `test-vectors.md:28`, `HS-INDEX.md:65` `not-yet-authored`). Three visible artifacts jointly publish it:

1. **What it tests** — `failure-modes.md:84`: `| FM-009 | Output | Parallel scan emits findings in traversal order without sorting → non-deterministic output | DI-001 | **EC-147** |` (the Corpus Fixture column names EC-147 as the fixture for this exact failure).
2. **The input** — `nfr-catalog.md:78-79` (NFR-003), Source: "DI-001, BV-015, **EC-147**, DD-012"; Validation method: "Property test: (1) run twice with identical inputs on the same fixture, diff stdout; (2) diff stdout across `RAYON_NUM_THREADS=1` and `RAYON_NUM_THREADS=4` on the same fixture."
3. **The expected output** — `invariants.md:73-77` (DI-001 Falsifying method): "Run the command twice on the same corpus under differing scheduler conditions (e.g. `RAYON_NUM_THREADS=1` vs `RAYON_NUM_THREADS=16`). Diff the two outputs byte-for-byte … **Any divergence is a violation.**"

Input, procedure, and pass/fail criterion, with EC-147 named as the owning ID in two of the three. Nothing is withheld.

**Partial-fix regression.** `decisions.md:25` (v1.6 changelog) states the sweep's scope: "DD-007 — replaced active holdout EC-141 in Resolves with risk-class description …; DD-009 — replaced active holdout EC-094 …; DD-010 — replaced active holdout EC-093 …". Three rows were swept. **Predicate:** `Grep 'EC-147|EC-141|EC-148|EC-079|EC-093|EC-094|EC-151|EC-156|EC-16[5-8]' /Users/.../.factory/specs` → the following sibling rows in the same architectural layer were **not** swept and still cite active holdouts: `decisions.md:90` (DD-012 Resolves: "BV-015, **EC-147**"), `decisions.md:94` (DD-016 Resolves: "AMB-030, **EC-079**, EC-080"), `failure-modes.md:84` (FM-009), `nfr-catalog.md:79` (NFR-003). Blast radius = 4 → HIGH.

`L2-INDEX.md:24` closes the v1.6 entry with "check-id-resolution and check-holdout-boundary **both at 0**" — true, and false-green, for the reasons in P7-S8-005.

**Consequence:** EC-147 and EC-079 carry zero Phase-4 signal. EC-147 is additionally the *only* declared fixture for FM-009, which is the failure mode guarding DI-001/NFR-003 — so the corpus simultaneously reserves it as hidden and publishes it as the NFR-003 validation method.

---

### P7-S8-019 — TV-146 asserts SIGINT → exit 2 with partial output: uncontracted, unimplementable under CAP-014, and contradicting a completed removal [HIGH]

`test-vectors.md:260`:
```
| TV-146 | EC-146 | Long-running scan; SIGINT sent | (none) | 2 | partial output; exit 2 |
```

Three independent problems:

1. **No BC covers it.** `prd.md` §2.14 (`:281-290`) lists four exit-code BCs, none about signals. `interface-definitions.md:83-91` §3 enumerates every exit-2 trigger — "Unrecognized flag, invalid flag value, nonexistent PATH argument, unreadable `.md` file, or internal unexpected error" — and closes with "**No other exit codes are produced.**" SIGINT is absent.
2. **`prd.md:632` records the deliberate removal of exactly this**: "F-016 … **SIGINT/panic sentences deleted from §3.**" `test-vectors.md` retains the vector the removal was meant to orphan.
3. **It is unimplementable under CAP-014's stated exit function.** `capabilities.md:233-243`: exit code is "a **pure function of three inputs**: the verdict multiset (`findings`), the I/O error list (`io_errors`), and the configuration error flag (`config_error`)" and exit 2 requires "`io_errors` is non-empty … OR `config_error = true`". SIGINT produces neither. A default-disposition SIGINT terminates the process at 130 (128+2), never 2; producing 2 requires an installed signal handler that CAP-014 does not admit. And "partial output" contradicts DI-001 (`invariants.md:61-66`), which requires the full finding set to be sorted before emission — a partial, unsorted flush is precisely the FM-009 failure.

**Consequence:** a test-writer implementing TV-146 adds a signal handler and a partial-flush path to satisfy a vector no BC authorises, introducing a nondeterministic output path into the one module (`reporter`) whose determinism is the NFR-003 guarantee. `check-counts.py`'s EC-registry logic (`:382-393`) counts EC-146 as legitimately registered, so nothing flags the orphan.

---

### P7-S8-020 — `gene-transfusion-assessment.md:117` instructs the implementer to KEEP Unicode combining marks; DI-012 requires them STRIPPED [HIGH]

`gene-transfusion-assessment.md:113-117`, under "The Rust implementation **MUST**":
> 3. Keep exactly the characters satisfying: `char::is_alphanumeric() || c == '_' || c == '-' || c == ' '`. … Note: for full Unicode `\p{Word}` fidelity, **Unicode combining marks (category `M*`) should also be kept** — verify with the `unicode-properties` or equivalent approach … If gaps exist, use the `unicode-general-category` crate.

`invariants.md:313-322` (DI-012 Normalization rule, adjudicated per v1.7 / ADR-008):
> The slug algorithm does NOT normalize input to NFC or NFD … **Consequence: NFD combining diacritical marks (U+0300..U+036F, `\p{Mn}`) are not `\p{Word}` characters and are stripped in step 3.** NFC accented characters (e.g., U+00E9 `é`) are `\p{L}` characters and are retained. **On macOS (where HFS+/APFS stores filenames in NFD), a heading written in NFD form and a link pointing to its NFC equivalent will produce different anchor keys and result in `broken`/`anchor-not-found` — this is a known asymmetry documented in ADR-008, not a product bug.**

The two documents prescribe opposite behaviour for the same codepoint class, and the disagreement is load-bearing on the sole target platform: macOS stores NFD. Keeping `M*` marks makes NFD `Café` slug to `café`; stripping them makes it slug to `cafe`. `TV-052` (`test-vectors.md:137`) asserts `## Café` → `#café` clean, and DEC-004 (`edge-cases.md:113-121`) asserts the NFD/NFC *filename* case resolves clean, so a reader has ample reason to believe "keep the marks" is right — and DI-012 says it is not.

`gene-transfusion-assessment.md` is frontmatter version `"1.0"` with no changelog (`:1-17`), i.e. it has never been swept, while `invariants.md` is at v1.10 and DI-012's normalization rule was only adjudicated at v1.7.

**Consequence:** the slug module is CRITICAL-tier with a ≥95% mutation-kill target (`module-criticality.md:75`) and is the product's #1 differentiator. The one document that gives the implementer a concrete Rust character-class expression, in a section headed **MUST**, contradicts the invariant that governs it, on the highest-risk correctness surface, for the only platform in scope. VP-026's differential oracle would eventually catch it, but only after the wrong keep-set is written and only if `github-slugger@2.0.0`'s own NFD behaviour is captured in the committed fixture.

---

### P7-S8-021 — `gene-transfusion-assessment.md:109` anchors the slug algorithm to DI-002 (path comparison); the governing invariants are DI-012/DI-013 [HIGH]

`gene-transfusion-assessment.md:109`, §1.3 Justification for the slug transfusion:
> "Algorithm is the product's #1 differentiator (**DI-002**, CAP-006, R-001)."

DI-002 (`invariants.md:85-101`) is "Case-Sensitive NFC-Normalized **Path** Comparison" — filesystem entry matching, owned by CAP-007/`path_resolver`. The slug invariants are DI-012 (slug computation fidelity) and DI-013 (anchor-key uniqueness), created by DD-027 precisely to close this governance gap (`decisions.md:79`; `invariants.md:34` v1.5 changelog).

This is the identical defect class that `module-criticality.md:22` (v1.5 changelog) records fixing in its sibling: "Rationale updated to cite VP-026 and **DI-012/DI-013 (replaces stale DI-003 reference — DI-003 is the fragment invariant; slug invariants are DI-012 and DI-013 per DD-027)**." The sweep hit `module-criticality.md` and missed `gene-transfusion-assessment.md`.

**Predicate:** `Grep 'DI-012|DI-013' /Users/.../.factory/specs` → **18 files**. `gene-transfusion-assessment.md` and `domain-spec/differentiators.md` — the two documents whose subject *is* slug/anchor fidelity — are **not** among them. (differentiators.md filed separately at P7-S8-028.)

**Consequence:** POLICY 4 mis-anchor. §1 is the section an implementer reads before writing `slug.rs`. It points them at the path-comparison invariant, so DI-012's seven enumerated rules — the exact list of what every incumbent gets wrong (`invariants.md:294-311`) — are never surfaced at the point of implementation. Combined with P7-S8-020 (same file, same section, contradicting DI-012 outright), §1.4 is actively hostile to DI-012 compliance.

---

### P7-S8-022 — `dtu-assessment.md` prescribes a loopback IP as the `dns-failure` test fixture; that fixture produces `indeterminate(private-ip)`, the opposite verdict [HIGH]

`dtu-assessment.md:165`:
```
| DNS failure → `broken` (reason: `dns-failure`) | Use a non-routable domain (e.g., `http://127.0.0.255:1/`) |
```
Repeated as the Phase-3 coverage recipe at `dtu-assessment.md:247`:
```
| CAP-010 | DNS failure | URL → `http://127.0.0.255:1/` (non-routable); assert `broken`, reason `dns-failure` |
```

`127.0.0.255` is a **literal IPv4 address**, not a domain — no name resolution occurs, so `dns-failure` ("External URL hostname could not be resolved by DNS", `error-taxonomy.md:81`) is unreachable by construction. Worse, `127.0.0.0/8` is loopback, and BC-2.10.010 (`prd.md:236`, "Private-IP and Link-Local URL Classification (Indeterminate, No Outbound Request)") mandates the opposite outcome: `error-taxonomy.md:85` — `http-indeterminate` triggers include "target IP is private/link-local (**private-ip** sub-reason, **no outbound request sent**, BC-2.10.010)". So the prescribed fixture yields `indeterminate` / `http-indeterminate` / `sub_reason: private-ip` / exit 0, against an asserted `broken` / `dns-failure` / exit 1.

The correct fixture is an unresolvable *name* — `test-vectors.md:187` (TV-088) already has it: `https://nx-domain-xyz.invalid/` with "DNS NXDOMAIN".

**Consequence:** `dns-failure` is one of the ten `broken` codes and one of the two whose classification was contested (`decisions.md`/DD-004 vs the "indeterminate" reading, resolved at `prd.md:603`). `dtu-assessment.md:213-215` declares itself "the **primary output** of the DTU assessment" and the authoritative hermetic-test specification. A test-writer following it writes a test that either fails for the wrong reason or — if they "fix" it by asserting whatever the tool emits — silently pins `dns-failure` to `indeterminate`, re-opening the exact DFT-001/F-001 taxonomy dispute. `check-adr-consistency.py` cannot see this file (P7-S8-006).

---

## Medium Findings

### P7-S8-023 — `prd.md:314` presents a fabricated excerpt as a quote from the frozen brief [MEDIUM]

`prd.md:313-314`: "The frozen brief (R6) states output **"may be formatted as an array"**. This is superseded by D-017 …"

`product-brief.md:48-49` (R6, FROZEN) actually states: "Output: human-readable text (default) listing file:line, link target, and failure reason; `--format json` **emits** a machine-readable array of the same."

The brief is prescriptive ("emits … array"); the PRD's quoted paraphrase is permissive ("may be formatted as"), which understates what D-017 is overriding. `decisions.md:75` (DD-023) quotes it correctly ("machine-readable **array** of the same") and `capabilities.md:226` quotes it correctly. POLICY 5 (creators justify anchors against the source-of-truth artifact) — a quoted excerpt that does not appear in the source.

**Predicate:** `Grep 'may be formatted as' /Users/.../.factory/specs/product-brief.md` → 0 matches.

**Consequence:** the binding-interpretation note reads as a clarification of a permissive brief rather than an override of a prescriptive one, weakening the record of a decision that deviates from a frozen requirement.

### P7-S8-024 — DD-016's widening of frozen R2c has no L3 binding-interpretation note, and the widened set is restated without 429 in two places [MEDIUM]

`product-brief.md:41-42` (R2c, FROZEN): "HEAD request (**GET fallback on 405**), 10s timeout." `decisions.md:94` (DD-016) overrides it: "HEAD→GET fallback on: `{400, 403, 404, 405, 501, 999}` plus transport-level failures … **Also fall back to GET on 429** … Brief's 'GET fallback on 405 only' is too narrow."

Two defects:
1. **No L3 record of the deviation.** R6's override got an explicit human ruling (DD-023) *and* a "Binding Interpretation Note — R6 / D-017" in `prd.md:313-314`. R2c's override is a **PO-level** decision (`decisions.md:81`: DD-007–DD-016 are PO decisions, not human/binding) recorded only at L2. `prd.md` §3 (`:294-314`) never mentions the GET-fallback set at all. A frozen requirement is narrowed-then-widened by a revisable decision with no L3 surface.
2. **Derived-set drift.** `capabilities.md:170,180` correctly delegates ("GET fallback on DD-016 status codes … Fallback set widened by DD-016") rather than restating. But two restatements drop 429: `events.md:104` ("On status in `{400, 403, 404, 405, 501, 999}` or transport failure → GET fallback") and `risks.md:38` (R-003 mitigation: "DD-016 widens fallback to `{400, 403, 404, 405, 501, 999}` plus transport failures"). `dtu-assessment.md:240` also restates the six-element set.

**Consequence:** an implementer building Stage 5 from `events.md` omits the 429→GET branch, which is the branch DD-016 flags as needing special handling ("but don't immediately retry — pause the host and honor `Retry-After`") and which BC-2.10.004 contracts. Separately, the R2c deviation is invisible to anyone reviewing brief fidelity at L3.

### P7-S8-025 — `test-vectors.md` uses `alive` in the link-verdict column at four rows, the exact conflation DD-022 was created to eliminate [MEDIUM]

`decisions.md:74` (DD-022): "`alive` is NOT a fourth verdict." `entities.md:51`: "`alive` does NOT appear in report output (the report emits `clean`)." `error-taxonomy.md:48`: "The positive external URL link verdict is `clean`."

Four rows in the `Verdict` column (which is the link verdict — every other row uses `clean`/`broken`/`indeterminate`):
- `test-vectors.md:189` TV-090: `alive ×50 (one fetch, not emitted)`
- `test-vectors.md:190` TV-091: `alive (allowed, not emitted)`
- `test-vectors.md:193` TV-150: `alive ×2 (not emitted); 2 HTTP requests`
- `test-vectors.md:191` TV-092 header row context — the `--allow` boundary row correctly uses `broken`.

TV-091 is wrong twice: `--allow` exempts the URL from liveness checking entirely (`capabilities.md:194`: "A match by either path exempts the URL from **syntax and liveness** checks"), so no liveness outcome is produced at all and the verdict is `clean` directly. `dtu-assessment.md:249` gets this right: "`--allow` exempts URL | … assert **`clean`** (no probe made); verify zero mock requests."

**Partial-fix regression.** `prd.md:679` enumerates the DD-022 sweep's targets: "Fixed BC-2.10.001, BC-2.10.003, BC-2.10.007 … Fixed BC-2.10.002 … Rewrote error-taxonomy.md §1." `test-vectors.md` is absent from the list. Blast radius 4 rows in one unswept sibling.

**Consequence:** golden-file tests written from these rows assert a `verdict` value that BC-2.13.001 PC3 (`BC-2.13.001.md:51`: "`verdict` in `results` is one of `"broken"` or `"indeterminate"`. Never `"clean"`") and `interface-definitions.md:192` ("Never `"alive"` or `"clean"`") both forbid.

### P7-S8-026 — three `test-vectors.md` section headers declare EC ranges that overlap each other or contradict their own exclusion clause [MEDIUM]

- `test-vectors.md:173`: `## §4. External URLs (R2c) — **EC-077 through EC-150** (excluding EC-079, EC-093, EC-094, EC-147, EC-148)`. Its actual rows are EC-077, 078, 080–092, 149, 150. The declared range **swallows §5's and §6's entire ranges**.
- `test-vectors.md:197`: `## §5. Parsing Scope (R3, R4) — EC-095 through EC-123` — inside §4's declared range.
- `test-vectors.md:232`: `## §6. Flags, Output, Exit Codes (R5, R6, R7) — EC-124 through **EC-148** (excluding EC-141, EC-147, **EC-148**)` — declares a range whose upper bound it then excludes; actual rows end at EC-146. Also inside §4's declared range.
- `test-vectors.md:124`: `## §3. Anchors (R2b) — EC-043 through EC-076` — but the section also contains EC-152..155, EC-157, EC-158, EC-182, EC-183 (`:162-169`).

**Why unenforced:** `check-counts.py:437-456` parses the §4 header range and flags only "IDs that are **PRESENT in the table but OUTSIDE** the declared range" (comment at `:445-447`). An over-wide declared range produces zero out-of-range IDs, so the overlap is invisible by construction.

**Consequence:** a reader (or generator) using the section headers as the EC-range registry concludes EC-095–EC-148 are owned by §4, and cannot determine which section owns a given ID. Directly undermines the POL-16 EC-injectivity work whose whole premise (`test-vectors.md:353-355`) is that each EC has exactly one registration site.

### P7-S8-027 — `test-vectors.md` §8 claims every trap has a vector while listing T16 as not-covered, and `prd.md:365` claims all 16 traps were converted [MEDIUM]

`test-vectors.md:291`: "Each trap from market-intelligence §4.3 has **at least one test vector above**." Contradicted eighteen lines later by its own table:
- `test-vectors.md:310` T16: "**not-covered** — TV-076 is broken because the target file does not exist …, not because of scan-root boundary enforcement. TV-024 establishes there is no scan-root boundary for relative links. A root-relative path (starting with `/`) with `..` traversal above git root on an existing file (per BC-2.07.002) has no dedicated vector; **boundary enforcement for root-relative paths is untested**."
- `test-vectors.md:307` T13: "**retired (D-043, platform-obsolete)**."

`prd.md:365` §5b compounds it: "**16 correctness traps (T1–T16) converted to executable test vectors**." That is false on both counts — T13 is retired (so the population is 15, per `risks.md:37` "T1–T12, T14–T16" and `differentiators.md:39` "T9–T12, T14–T15") and T16 is not covered.

`prd.md:766-767` (v1.7, P3-032) records the T16 honesty fix in test-vectors.md but did not propagate the count to §5b.

**Consequence:** §5b is the summary a gate reviewer reads. It asserts complete trap coverage over a trap set that has one retired member and one uncovered member, and the uncovered member is an *untested security-relevant boundary* (path traversal above the git root via root-relative links, BC-2.07.002).

### P7-S8-028 — `differentiators.md:39` attributes the github-slugger-fidelity differentiator to DI-003/DI-008 and cites no slug-fidelity invariant [MEDIUM]

`differentiators.md:39`:
```
| **Correct** anchor checking (github-slugger v2 fidelity, percent-decode, two-pass) | … | CAP-005, CAP-006, CAP-008 | DI-003, DI-008 | … |
```
"Key Invariants" for a row whose subject is *slug fidelity* names DI-003 (fragment split) and DI-008 (anchor-table ordering) and omits **DI-012** (slug computation fidelity) and **DI-013** (anchor-key uniqueness) — the two invariants DD-027 created for exactly this (`decisions.md:79`).

`L2-INDEX.md:113` was updated ("R2b (heading anchors) | CAP-005, CAP-006, CAP-008 | DI-003, DI-007, DI-008, **DI-012, DI-013**"); `capabilities.md:119-124` (CAP-006) was updated; `failure-modes.md:76-78` was re-anchored. `differentiators.md` (v1.1, `:5`) was not. **Predicate:** `Grep 'DI-012|DI-013' /Users/.../.factory/specs` → 18 files; `domain-spec/differentiators.md` not among them.

Row `:38` in the same table cites DI-007 for "Strict anchor checking, on by default," which is also loose (DI-007 is the HTML-attribute carve-out, not anchor checking generally).

**Consequence:** POLICY 4. The document whose purpose is tracing competitive claims to enforceable invariants fails to trace the flagship claim to the invariants that enforce it, so the DI→VP coverage argument for KD-001 cannot be assembled from it.

### P7-S8-029 — "two-pass" survives at five sites after the corpus-wide "three-phase" rename, and canonical-facts FACT-3 binds only two files [MEDIUM]

`prd.md:682` (D-015/DD-022): BC-2.05.001's title was corrected from "Two-Pass Design" to "Three-Phase Design"; `ARCH-INDEX.md:22` and `module-criticality.md:19` record the P4-003 sweep of four more occurrences. `canonical-facts.toml:99-102` establishes **FACT-3**: `description = "Pipeline is three-phase (Pass 1 → Pass 1.5 → Pass 2), not two-pass"`, `canonical_value = "Pass 1.5"`.

**Predicate:** `Grep 'two-pass|Two-Pass|two pass' /Users/.../.factory/specs` → 22 occurrence lines. Excluding changelog/history lines and the VP-015 filename (an immutable slug per POLICY 1), the live body survivors in or adjacent to shard-8 scope are:
- `differentiators.md:39` — "(github-slugger v2 fidelity, percent-decode, **two-pass**)"
- `gene-transfusion-assessment.md:27` — "3 (**two-pass** anchor index; …)"
- `gene-transfusion-assessment.md:145` — "T15 (**two-pass**, same-file)"
- `gene-transfusion-assessment.md:193` — "### 3.1 **Two-Pass** Anchor Index"
- `gene-transfusion-assessment.md:293` — "**Two-pass** anchor index pattern (remark-validate-links, lychee)"

**Why unenforced:** `canonical-facts.toml:105-115` gives FACT-3 exactly **two** bindings — `domain-spec/entities.md` and `prd.md`. `differentiators.md` and `gene-transfusion-assessment.md` are not bound, so `check-canonical-facts.py` cannot see them. The mechanism is a positive binding list with no exhaustiveness assertion: nothing greps the corpus for the anti-value `two-pass` and requires every occurrence to be either a declared binding or a historical changelog line. This is the same shape as P7-S8-005/006 — a checker that exists, has a fact for precisely this drift class, and misses it by scope.

**Consequence:** the "two-pass" framing omits Pass 1.5, which is the phase that makes DI-006 hold for `.gitignore`d / dot-directory / out-of-root anchor targets (`invariants.md:179-194`). §3.1 of gene-transfusion-assessment.md is presented as the *provenance record for DI-008* (`:199`), so an implementer reading it builds a two-pass pipeline and reproduces exactly the DI-006 false-positive class.

**Tag:** [process-gap]

### P7-S8-030 — `entities.md:118-123` (AllowRule) omits the raw-string fallback that DD-025 made mandatory [MEDIUM]

`entities.md:120-123`: "A **normalized URL prefix** (scheme + authority + path) against which external URL destinations are tested. … Prefix matching uses **normalized URL components**, NOT naive byte comparison (prevents `example.com.evil.tld` bypass — **DD-013**)."

`decisions.md:77` (DD-025, human ruling D-019) supersedes DD-013's algorithm with a two-step form: "Step 2b (**normalization failed** — URL is syntactically malformed): fall back to **raw-string prefix match** at a component boundary. … Resolves P2-M08: the prior 'normalize-then-match' algorithm made `--allow` **structurally unable to exempt malformed URLs** from syntax checking."

`entities.md` (v1.2, `:5`) still describes only the normalize path and still cites DD-013. `capabilities.md:190-197` (CAP-011) and `interface-definitions.md:56` were updated; the entity was not. `interface-definitions.md:56` is also incomplete on this point ("Exempt external URLs whose **normalized form** starts with URL_PREFIX") though its §8 row (`:235`) is neutral.

**Consequence:** an implementer modelling `AllowRule` from `entities.md` builds normalize-only matching, reintroducing P2-M08 — `--allow` cannot exempt a malformed URL, so `TV-131`/`EC-131` ("allowed (suppresses syntax validation too)", `test-vectors.md:244`) fails for any URL that fails WHATWG parse.

### P7-S8-031 — `gene-transfusion-assessment.md:119` keys the duplicate counter on "original slugs"; DI-013 requires the computed slug [MEDIUM]

`gene-transfusion-assessment.md:119`, in the MUST list: "Maintain a per-file duplicate counter keyed on **original slugs**. First occurrence: no suffix. Second: `-1`. Third: `-2`."

`invariants.md:355-356` (DI-013): "The counter key is the ***computed slug*** after DD-015 steps 1–4, **not the raw heading text**." `capabilities.md:117-118` and BC-2.06.001 PC3 (per `prd.md:666`, F-029: "PC3 added: duplicate counter keyed on computed slug string, not heading text") say the same.

"original slugs" is ambiguous between "the pre-suffix base slug" (correct) and "the original heading text" (wrong). The suffix behaviour it states is correct, so the error is confined to the key.

**Consequence:** the wrong reading is exactly the failure `TV-158` (`test-vectors.md:168`) is built to catch: `## 🚀 Foo` then `## Foo` — keyed on raw text these are distinct, no collision is detected, `foo-1` is never assigned, and `[second](#foo-1)` reports a false `anchor-not-found`. The vector's own note spells this out. In a MUST list, in the document that gives the only concrete implementation recipe, the ambiguity is worth removing.

### P7-S8-032 — `gene-transfusion-assessment.md:236` recommends a concurrency ceiling of 8–16; AMB-040/BC-2.10.008 fix it at 32 global / 4 per-host [MEDIUM]

`gene-transfusion-assessment.md:236`, anti-gene rationale: "Simple rayon thread pool with a reasonably low ceiling (**e.g., 8–16** for network work) is sufficient."

`prd.md:306` (AMB-040): "Per-host concurrency cap: **4** connections; global cap: **32**; no explicit politeness delay." `prd.md:234` BC-2.10.008 title: "Concurrency — Dedicated Pool, **32 Global / 4 Per-Host** Request Limits." `capabilities.md` and BC-2.10.008 agree.

**Consequence:** a low-severity but concrete contradiction between an architecture-input document and an adjudicated L3 default. An implementer taking 8–16 fails BC-2.10.008's test vectors, which `prd.md:638` states "assert observable concurrent connections."

### P7-S8-033 — `gene-transfusion-assessment.md:146` maps a file-handle-exhaustion fixture to DI-009 (scan termination) [MEDIUM]

`gene-transfusion-assessment.md:146`: lychee #1709 — "Resource exhaustion: local fragment checks open file handles without closing, producing 'too many open files' on large repos … | **DI-009 (termination invariant)**".

DI-009 (`invariants.md:235-262`) is "Scan Terminates for Any Input" — symlink cycles, overlapping arguments, Pass 1.5 read bounds. File-descriptor exhaustion is a *resource* concern; the corpus already has the right anchors: NFR-005 (`nfr-catalog.md:99-109`, peak RSS) and R-009 (`risks.md:44`, "Memory budget corpus-shape-dependent … all anchor tables … held in memory simultaneously during Pass 2"). Neither is cited.

**Consequence:** POLICY 4. The fixture `corpus/lychee-1709-open-files.md` is one of the 13 named acceptance-corpus fixtures (`:156`), so it will be authored; anchoring it to DI-009 means it will be written as a termination test rather than a descriptor-lifetime test, and the actual failure class stays unfixtured. R-009 is rated MEDIUM impact and has no fixture of its own.

### P7-S8-034 — `manifest.json` cannot express `sub_reason`, and the corpus pass criterion is stated two incompatible ways [MEDIUM]

`interface-definitions.md:303`: "Finding object fields: identical to the `--format json` finding object (§6.2): `file`, `line`, `column`, `link_target`, `verdict`, `reason` — **all required**." `interface-definitions.md:305`: "Pass criterion: **Set equality over the six-field tuple** `(file, line, column, link_target, verdict, reason)`."

But §6.2 (`:194`) defines a **seventh** field, `sub_reason`, carrying the `private-ip` (BC-2.10.010) and `https-downgrade` (BC-2.10.007) diagnostics. The manifest schema (`:280-293`) has no slot for it, and the `jq` projection in the pass criterion drops it. So no corpus fixture can assert a `sub_reason` value, and the two BCs that produce it have no corpus coverage path.

Separately, `test-vectors.md:347` §9.2 states a **different** criterion for the same comparison: "JSON output matches `tests/corpus/manifest.json` exactly (**modulo ordering, which must itself match the sorted order**)" — ordering-sensitive, versus §10.2's set equality. And §10.2's `sort_by(.file,.line,.column)` is three-field where DI-001 is four-field (P7-S8-012).

**Consequence:** the acceptance corpus is the primary success criterion (`product-brief.md:60-62`, `assumptions.md:44` ASM-007 "HIGH — primary success criterion … cannot be evaluated"). Two conflicting pass criteria means two possible verdicts on the same run, and `sub_reason` — the only machine-readable signal distinguishing a private-IP skip from a genuine timeout — is unassertable.

### P7-S8-035 — `BC-2.13.001` PC2 states an exhaustive finding-field list that excludes the `sub_reason` field D-016 added [MEDIUM]

`BC-2.13.001.md:49-50` PC2: "Each finding object in `results` has fields in **this order**: `file`, `line`, `column`, `link_target`, `verdict`, `reason`."

`interface-definitions.md:194` defines `sub_reason` as an optional seventh field; `:198` gives the stable key order including it; `error-taxonomy.md:115-128` §3b defines its two values; `prd.md:684-685` records D-016 adding it.

PC2 reads as an exhaustive enumeration ("has fields in this order"), so a finding carrying `sub_reason` violates it. The BC was updated for `errors[]` (PC7, Inv 6/7 — `prd.md:654`) but not for `sub_reason`.

**Consequence:** the two artifacts disagree on whether a seven-field finding object is conformant. Since BC-2.13.001 is the contract a story will be written against, `sub_reason` may never be implemented — losing the diagnostic that distinguishes BC-2.10.010's no-request private-IP classification from a real network indeterminate. (Noted here because the *primary subject* is the interface/PRD-supplement schema question raised in intake item 8; the BC-side edit belongs to the SS-13 shard.)

### P7-S8-036 — DD-017 cites a nonexistent `prd.md §320` and still names the retired ID EC-102 in its Decision text [MEDIUM]

`decisions.md:69` (DD-017): "the `mdlinkcheck BRIEF.md` → exit 0 scenario (DEC-006, code-span-extraction vector **EC-102**) is de-designated … All other EC-NNN entries reserved in **prd.md §320** remain hidden."

Two problems:
1. **`prd.md §320` does not exist.** prd.md's sections are §1–§8 (`prd.md:31`–`:490`); the holdout list is §5b (`prd.md:361-365`). "§320" is a line number rendered as a section reference. It is propagated: `HS-INDEX.md:53,58-67` cites "prd.md:332" as the reservation site — a *third*, also-wrong value (the list is at line 365). Neither reference resolves.
2. **EC-102 is retired and still named.** `prd.md:365`: "ID 102 is **retired**"; `test-vectors.md:30-31`: "EC-102 was formerly on this list; it has been replaced by EC-151." `decisions.md:25` (v1.6) claims "also removed the retired-scenario ID from **Resolves** (superseded by BV-013)" — true for the Resolves column, but the Decision text still carries it. **Predicate:** `Grep 'EC-102' /Users/.../.factory/specs` → 3 occurrences: `decisions.md:69`, `test-vectors.md:30`, `test-vectors.md:31`. The two in test-vectors.md are explicitly retirement notices; `decisions.md:69` presents it as a live identifier.

**Consequence:** DD-017 is the decision governing the holdout pool's membership, and its pointer to that pool does not resolve in any of its three published forms. Anyone auditing "which EC IDs are reserved" cannot follow the citation. Partial-fix: the Resolves column was swept, the Decision text was not.

### P7-S8-037 — TV-021 is declared deterministic in a changelog while its fixture is inherently racy [MEDIUM]

`test-vectors.md:92`:
```
| TV-021 | EC-021 | File modified while scan is in flight (concurrent write) | (none) | 2 | `target-unreadable` | Any I/O failure during read yields exit 2 … (Verdict chosen: target-unreadable/exit-2 is the only valid deterministic outcome — "clean" would require the race to be undetectable, which is implementation-defined.) |
```
`prd.md:652` records: "**F-012 (non-deterministic test vectors): TV-021 → deterministic: `2 / target-unreadable`**."

Declaring a verdict does not make the fixture deterministic. "File modified while scan is in flight" does not reliably cause a read failure — on APFS an in-place rewrite during a `read_to_string` normally succeeds and yields either the old or new bytes. The vector's own parenthetical concedes the alternative is "implementation-defined," which is the definition of nondeterminism. The fixture as described has no mechanism that forces the I/O error.

**Consequence:** a self-refuting remediation claim. The vector will be flaky in CI, and because `prd.md:652` records it as fixed, the flake will be attributed to the implementation rather than the vector. A deterministic replacement exists and is already in the file — TV-013 (`:83`, mode `000`) forces the error. TV-021 either needs a forcing mechanism (truncate-to-invalid-UTF-8 mid-read via a controlled harness) or should be marked as a non-vector observation.

### P7-S8-038 — `test-vectors.md` §9.1 known-good corpus has a pass criterion that is either vacuous or externally unstable [MEDIUM]

`test-vectors.md:318-331`: Corpus = "Rust standard library documentation (`std` crate from `rust-lang/rust`), specifically the `library/std/src/` Markdown files." Setup = `git clone --depth=1 https://github.com/rust-lang/rust.git /tmp/rust-corpus; mdlinkcheck /tmp/rust-corpus/library/std/src/`. Expected = "Zero `broken` findings, zero `broken-symlink` findings." Pass criterion = "**Exit 0**."

Two failure modes, both real:
1. **Vacuous.** `library/std/src/` is predominantly `.rs`. If it contains zero `.md` files, BC-2.01.008 ("Zero Markdown Files Found Yields Exit 0 with Stderr Message", `prd.md:112`) makes the run exit 0 unconditionally — the gate passes while checking nothing.
2. **Externally unstable.** If it does contain `.md` files, the criterion asserts a property of a third-party repository at `HEAD`. Any upstream commit that renames a heading or moves a file turns the gate red with no local cause. `assumptions.md` records no assumption covering this, and there is no pinned revision (`--depth=1` on the default branch is explicitly unpinned).

**Consequence:** a merge-relevant acceptance criterion that either verifies nothing or fails for reasons outside the repository. Contrast §9.2 (`:333-347`), which uses a committed synthetic corpus. If §9.1 is retained it needs a pinned commit SHA and a non-zero `.md`-file-count assertion — the POL-11 positive-coverage pattern.

### P7-S8-039 — EC-125 and EC-192 register the identical scenario under two EC IDs [MEDIUM]

`test-vectors.md:238`: `| TV-125 | EC-125 | All files matched by `*.md` | `--ignore '*.md'` | 0 | warning on stderr; no findings |`
`test-vectors.md:427`: `| TV-192 | EC-192 | `--ignore '*.md'` — glob excludes all .md source files; 0 files scanned | BC-2.11.001 | `--ignore '*.md'` | 0 | no findings | Formerly EC-072; EC-072 owned by TV-072 …|`

Same flag, same input condition, same exit code, same finding set. Two EC IDs, two TVs. EC-192 was allocated during the pass-4 collision-remapping (`test-vectors.md:411-415`) to displace a colliding EC-072 reference in BC-2.11.001 — but the scenario it describes was already registered as EC-125, so the remap created a duplicate rather than resolving a collision.

The two rows also *differ* on expected stderr: EC-125 says "warning on stderr", EC-192 says nothing about a warning. So they are not even identical assertions.

**Consequence:** POL-16 EC injectivity is violated in the direction the checker does not test — `check-ec-injectivity` guards against one EC mapping to multiple scenarios; this is one scenario mapping to two ECs, which inflates the EC registry count (feeding P7-S8-042's derived-count problem) and leaves ambiguous whether the stderr warning is required.

### P7-S8-040 — `prd.md:606` records the BC-INDEX DI-007 coverage note as pointing at BC-2.05.001; DI-007 is enforced by BC-2.05.003 [MEDIUM]

`prd.md:605-606` (INC-009 remediation): "Updated DI-007 entry in BC-INDEX from '[reserved — no enforcement BC needed]' to an accurate coverage note referencing VP-020 and **BC-2.05.001**."

DI-007 (`invariants.md:209-213`) is "HTML Anchor Extraction Scope Is Narrow — Only `id=` and `name=` attributes … are extracted." The BC that contracts that behaviour is **BC-2.05.003** ("HTML `id=` and `name=` Attribute Extraction into Anchor Table", `prd.md:165`). Three artifacts agree: `BC-2.05.003.md:82` lists `DI-007, DI-008`; `VP-INDEX.md:180` maps `BC-2.05.003 | HTML id=/name= extraction | VP-020 | DI-007 narrow-scope integration`; `verification-architecture.md:97` maps VP-020 to `DI-007, BC-2.05.003`. **Predicate:** `Grep '\bDI-007\b' /Users/.../.factory/specs` → 21 occurrences; `BC-INDEX.md:212` is the only one naming BC-2.05.001.

`BC-2.05.001.md:118` lists `DI-006, DI-008` — it does not cite DI-007 back, so the reference is unreciprocated.

**Consequence:** POLICY 4 / POLICY 2 scope mismatch. Anyone tracing DI-007's enforcement from BC-INDEX lands on the three-phase-ordering contract instead of the HTML-attribute contract, and the "accurate coverage note" recorded as the INC-009 fix is itself the mis-anchor. (Reported here because `prd.md:606` is the record of the decision; the BC-INDEX cell edit belongs to the BC-index shard.)

### P7-S8-041 — POLICY 19's hook computes the closed-set size at runtime but never asserts it equals 13 [MEDIUM]

`check-adr-consistency.py:142-147`:
```python
valid_codes = extract_closed_reason_codes(ERROR_TAX)
if not valid_codes:
    print(f"ERROR: Could not extract reason codes from {ERROR_TAX}")
    return 2
print(f"Closed reason code set ({len(valid_codes)} codes): {sorted(valid_codes)}")
```
The only guard is non-emptiness. There is no `assert len(valid_codes) == 13`. `error-taxonomy.md:99` ("13-code closed set"), `error-taxonomy.md:176` ("The closed taxonomy remains 13 codes"), `prd.md:594` ("the canonical taxonomy has exactly 13 codes"), and `failure-modes.md:125` ("all **13** reason codes") all state the cardinality — none is machine-checked.

Related: the hardcoded exemption set at `:125-129` includes `"http-indeterminate"`, which **is** a legitimate member of the closed set. Listing a valid code among "codes that are clearly not reason codes" is either dead or masks an extraction failure for that code.

**Consequence:** if a row is dropped from `error-taxonomy.md` §2 (or the `## 2.` / `### 2.x` heading structure changes so that `extract_closed_reason_codes`'s state machine at `:43-48` closes early), the "closed set" silently shrinks and the checker keeps passing — the codes that vanished become unenforced rather than reported. This is the POL-11 pattern: the count is runtime-computed and printed, but never compared to the declared invariant.

**Tag:** [process-gap]

### P7-S8-042 — `prd.md:748` states a BC→VP count over a VP range that has since grown, and no check recomputes it [MEDIUM]

`prd.md:748`: "**BC→VP count (post-v1.5):** 66 BCs total; 33 with a real VP (**VP-001..VP-024**); 33 test-sufficient."

VP-025 and VP-026 now exist. **Predicate:** `Glob '*' /Users/.../.factory` returned `verification-properties/vp-025-anchor-resolver-totality.md` and `verification-properties/vp-026-slug-differential-fidelity.md`; `module-criticality.md:80` cites "VP-025 (proptest totality+correctness)" and `:75` cites "differential oracle VP-026"; `invariants.md:329-331` and `failure-modes.md:93` make VP-026 load-bearing for DI-012/DI-013/FM-002. So the "VP-001..VP-024" range and the 33/33 split are both stale, and prd.md states no current figure anywhere.

**Predicate on the summed VP counts:** `module-criticality.md:75-91` VP Count column sums to 26 (6+2+2+1+3+1+3+2+1+2+1+1+0+1+0+0+0), consistent with VP-001..VP-026 — confirming two VPs were added after the prd.md:748 snapshot.

`check-counts.py`'s docstring (`:5-17`) enumerates what it recomputes; the BC→VP split is not among them. POLICY 17: hand-maintained derived statistic, no generator, no checker.

**Consequence:** the count is inside a `### v1.5` changelog block so it is arguably snapshot-scoped, but it is the only BC→VP tally in prd.md and is phrased as a standing figure. A gate reviewer computing verification coverage from it undercounts by two and works from a closed VP range that is no longer closed.

### P7-S8-043 — `module-criticality.md:59` describes `url_classifier`'s output set without the `Malformed` variant that VP-023 exists to prove [MEDIUM]

`module-criticality.md:59`: "**url_classifier** — classifies link destination as file-path / mailto / anchor / http / https".

`prd.md:743` (VP-023, an architect-designated elevation): "`url_classifier::classify_url` **totality** — empty destination string returns **`Malformed(_)`**, never `NonHttp`; method: proptest. Rationale: empty string through WHATWG URL parse is a real panic class; **misclassification risk is `NonHttp` → no exit-1 contribution**." `module-criticality.md:85` itself cites "VP-023 (proptest totality)" for this module.

The inventory line's enumeration omits `Malformed` entirely, and lists `mailto` as a peer of `http`/`https` rather than the `NonHttp` class DD-009 defines (`decisions.md:87`).

**Consequence:** POLICY 4. `module-criticality.md:127-130` declares itself "the authoritative source of truth for module criticality tier assignments," and its Module Inventory is the module-purpose reference. An implementer enumerating `LinkKind`/`UrlClass` from it omits `Malformed`, which routes an empty destination to `NonHttp` → verdict `clean` → **no exit 1** — precisely the silent false negative VP-023 was elevated to prevent, and the behaviour `TV-031`/`BC-2.07.007` forbid.

---

## Low Findings

### P7-S8-044 — `events.md:41` attributes no-fail-fast to DI-011 rather than DD-007 [LOW]

`events.md:41`, Stage 1 Failure: "Nonexistent path argument → I/O error recorded; continue (**DI-011**)." DI-011 (`invariants.md:278-285`) is exit-code *precedence* (2 beats 1). The "scan continues" rule is DD-007 (`decisions.md:85`: "**No fail-fast** — scan continues after I/O errors"), and 22 other citations use DD-007 for it (P7-S8-003 predicate). DI-011's own text does mention non-abortion, so the citation is defensible but imprecise. Same at `events.md:53` and `:67`.

### P7-S8-045 — `failure-modes.md:51` claims all 13 codes appear in both text and JSON output; `target-unreadable` appears in neither findings stream [LOW]

`failure-modes.md:51`: "**All are emitted in both text and JSON output** (DD-011)." Contradicted 14 lines later by the `target-unreadable` row (`:65`): "Reported as I/O diagnostic on **stderr**, not a link verdict," and by `:121` ("Both appear on stderr as a diagnostic, not in the findings list"). Per `interface-definitions.md:200-206` and `BC-2.13.001.md:56-58`, `target-unreadable` goes to the JSON `errors[]` array — never to `results[]`, never to the stdout text report. So the blanket claim is false for 1 of 13. Also cites the superseded DD-011 (P7-S8-011).

### P7-S8-046 — `module-criticality.md` classification percentages sum to 101%, and the section labels are stale by one version [LOW]

`module-criticality.md:117-123`: CRITICAL 47% + HIGH 24% + MEDIUM 12% + LOW 18% = **101%**, against a `**Total** | **17** | **100%**` row. Module counts are correct (8/4/2/3 = 17, verified against the 17 rows at `:75-91`); the percentages are individually correctly rounded, so the `100%` total is the wrong cell — it should be `~100%` or the percentages should be shown to one decimal.

Separately, `:19` (v1.6 changelog) records "(4) Section labels (v1.3) updated to (v1.5) (P4-033)", and `:182-183` now read "**CRITICAL modules (v1.5)**" / "**HIGH modules (v1.5)**" while the document is at version `"1.6"` (`:4`). The label re-drifted immediately. This pattern — embedding a version number in a section label — guarantees recurrence; the labels should carry no version.

### P7-S8-047 — `gene-transfusion-assessment.md:292` says "5 tools"; the table lists 6 [LOW]

`:292`: "Incumbent bug reports (**11 bugs, 5 tools**)". The Tool column at `:144-154` names: lychee (×3), markdown-link-check/mlc (×2), Sphinx (×2), mkdocs-htmlproofer, MkDocs (×2), markdownlint MD051 = **6 distinct tools**. The bug count (11) and fixture count (13) at `:156` and `:28` are both correct; only the tool count is wrong.

### P7-S8-048 — `gene-transfusion-assessment.md` is version 1.0 with no changelog, yet `prd.md:612` directed an edit to it [LOW] (pending intent verification)

`prd.md:611-612` (v1.2, INC-010): "gene-transfusion-assessment.md uses '**valid**' for the positive external URL verdict at lines 211 and 286. This file is not in product-owner scope but is flagged here for the spec-steward: 'valid' must be replaced with '**alive**' in that document."

Current state: `:211` is `### 3.3 Three-Outcome Classification — Indeterminate (from linkinator)` and `:286` is `## Transfusion Summary Table` — neither contains "valid". The surviving "valid" occurrences (`:234`, "Accepting 429 as **valid** … lychee troubleshooting page (\"last resort: accept 429 as valid\")") are a *quotation of lychee's own wording* in an anti-gene row, which is legitimate. The frontmatter is `version: "1.0"` with no `changelog:` or `modified:` field (`:1-17`).

So either (a) the edit was made and the version was not bumped and no changelog entry was added — a provenance gap, or (b) the edit was never made and INC-010's line references were wrong from the start (the two cited lines have shifted, which is consistent with an intervening edit). I cannot adjudicate which without history. Flagging per the intent-adjudication rule: if (a), the file needs a version bump and changelog entry recording the INC-010 fix; if (b), `prd.md:612` should record INC-010 as withdrawn.

### P7-S8-049 — `test-vectors.md:110` (TV-032) asserts a broken verdict with no reason code [LOW]

`| TV-032 | EC-032 | `a.md` | `[x](   )` | — | 1 | broken | Whitespace-only destination malformed |`

Every sibling broken-verdict row in §2 names a code — `:109` TV-031 `broken (`malformed-url`)`, `:112` TV-034 `broken (`file-not-found`)`, `:114` TV-036 `broken (`file-not-found`)`. TV-032's note says "malformed" but no code. By BC-2.07.007 (`prd.md:192`, "Empty Link Destination → Malformed URL") and TV-031's precedent it should be `broken (malformed-url)`. Since `NFR-007` asserts zero unrecognized reason strings and TV-134a (`:247`) claims to enumerate all six offline broken codes, an unspecified code here is a small hole in the reason-code coverage argument.

---

## Observations

- **POLICY 2 (`lift_invariants_to_bcs`) is CLEAN.** **Predicate:** `Grep '^\| L2 Domain Invariants \|' /Users/.../.factory/specs/behavioral-contracts` → 47 rows. Every DI-001..DI-013 is cited by at least one BC: DI-001 (`BC-2.12.001.md:79`, `BC-2.13.001.md:98`), DI-002 (`BC-2.07.003.md:93` +3), DI-003 (`BC-2.08.003.md:81` +4), DI-004 (`BC-2.04.001.md:84` +5), DI-005 (`BC-2.03.001.md:81` +6), DI-006 (`BC-2.01.003.md:80` +4), **DI-007** (`BC-2.05.003.md:82`), DI-008 (`BC-2.05.001.md:118` +5), DI-009 (`BC-2.01.001.md:81` +3), DI-010 (`BC-2.10.002.md:167` +5), DI-011 (`BC-2.02.003.md:74` +4), **DI-012** (`BC-2.06.001.md:121`), **DI-013** (`BC-2.06.002.md:100`). Zero orphan invariants. The DD-027 additions propagated correctly to the BC layer even though they failed to reach `differentiators.md` and `gene-transfusion-assessment.md` (P7-S8-021, P7-S8-028).

- **The `L2-INDEX.md` ID Registry counts are internally consistent.** `L2-INDEX.md:147-155` declares CAP 14, DI 13, DEC 9, ASM 10, R 9, FM 10, DD 27. Spot-verified against the shards: `edge-cases.md` has DEC-001..DEC-009 (9 `## DEC-` headings), `assumptions.md:38-47` has ASM-001..ASM-010 (10 rows), `risks.md:36-44` has R-001..R-009 (9 rows), `failure-modes.md:76-85` has FM-001..FM-010 (10 rows), `invariants.md` has 13 `## DI-` headings. `check-counts.py:179-187` recomputes the DD count against L2-INDEX; the other five are unchecked but currently correct.

- **`error-taxonomy.md` and `failure-modes.md` agree exactly on the 13-code set and their verdict/exit-code assignments.** I compared `error-taxonomy.md:62-91` against `failure-modes.md:53-67` code-by-code: identical membership, identical verdict class, identical exit code, including the two contested ones (`dns-failure` and `tls-error` both `broken`/1) and the D-018 400-after-GET reclassification. The taxonomy itself is sound; every taxonomy defect in this report is a *citation* defect elsewhere (P7-S8-007) or a *coverage* gap (P7-S8-008).

- **The D-043 macOS-only sweep is unusually thorough.** `Grep -i 'linux|windows|ubuntu-latest'` across the shard-8 files surfaces only retirement notices and changelog records (`nfr-catalog.md:90-94`, `risks.md:19`, `differentiators.md:19`, `test-vectors.md:477`, `failure-modes.md:19-22`, `edge-cases.md:19`, `invariants.md:22-25`). No live multi-platform claim survives in my scope. The CV5-001 follow-up passes appear to have closed that class. This contrasts sharply with the DD-022 verdict-layer sweep (P7-S8-025), the DD-023 envelope sweep (P7-S8-010, P7-S8-011), the DI-001 four-field sweep (P7-S8-012), and the three-phase rename (P7-S8-029) — all of which have 4+ live survivors. The difference: D-043 got a `canonical-facts.toml` FACT with bindings *plus* explicit per-file changelog entries in every affected shard; the others got neither, or got a FACT with an incomplete binding list.

- **[process-gap] Three of the four false-green findings in this report share one root cause: enforcement scope is expressed as a positive list with no exhaustiveness assertion.** `check-holdout-boundary.py:149` (table rows only), `check-adr-consistency.py:156` (ADR files only), `canonical-facts.toml:105-115` (two bindings for FACT-3). In each case the checker runs, exits 0, and prints a count — satisfying POL-11's *shape* — while the property it names is unverified over most of the corpus. The `SUPPRESSION_PATTERN` guard cannot detect any of them because none is a named set. The generalisable fix is an **anti-value exhaustiveness predicate**: for each canonical fact and each closed vocabulary, grep the whole corpus for the forbidden value and require every occurrence to be either (i) a declared binding site, (ii) inside a changelog region (per the positional predicate in P7-S8-001c), or (iii) an explicit violation. That converts every one of these checks from "N sites verified" to "M occurrences found, N accounted for, M−N violations" — which is the only form that cannot silently under-cover.

- **[process-gap] `gen-rtm.py` and `gen-prd-sections.py` are asymmetrically adopted, and the unadopted one is the one that matters more.** `Grep 'BEGIN GENERATED|END GENERATED' prd.md` → 28 occurrences, all `prd-s2-ss-NN` (§2 title tables, POLICY 13, backed by `check-title-sync.py`). Zero `prd-s7-rtm` markers. §2 is a 3-column table of BC IDs, titles, and priorities; §7 is a 6-column traceability matrix joining BC IDs to capabilities, invariants, frozen brief requirements, priorities, and test types. The higher-fanout, higher-join-arity table is the hand-maintained one, and its generator returns 0 with a NOTICE when the markers are missing (`gen-rtm.py:186-194`). P7-S8-015's 27 drifted cells are the predictable result. A generator that soft-fails on missing markers cannot enforce adoption; it should exit non-zero (or the marker-insertion should be a one-time migration).

- **[process-gap] `check-holdout-boundary.py:53-71` derives its enforcement pool from the union of prd.md §5b and HS-INDEX actives, which means an unauthored reservation *inflates* the reported pool size.** The success line prints `(pool: {len(holdout_ids)} IDs)` — currently 12 — while only 5 scenarios exist (P7-S8-017). A reviewer reading the checker output sees stronger holdout coverage than exists. The pool used for *enforcement* should be the union (correct — you want to catch leaks of reserved IDs), but the *reported* figure should distinguish authored from reserved-unauthored, and `check-counts.py` should assert prd.md §5b's declared list equals HS-INDEX's active + not-yet-authored rows so the 12-vs-5 divergence surfaces.

---

## Novelty Assessment

**Novelty: HIGH.** These are not refinements. Five findings are structural verification failures — two gates (POL-18, POL-19) that report PASS while the properties they name are unverified over most of the corpus, each with a live corpus instance (P7-S8-004 leaks a full holdout scenario in prose; P7-S8-007 carries a phantom reason code). One finding (P7-S8-008) is an unsatisfiable contract: the mandatory JSON `errors[]` array has no conformant `reason` value for the nonexistent-PATH case, which is a first-day CLI input.

The highest-fanout finding is P7-S8-015/016: prd.md §7 RTM — the requirements traceability matrix — disagrees with the BC files at 19 of 66 `Brief Req` cells and 8 `L2 Invariants` cells, and two prd.md changelog entries record fixes that were applied to one side only. The generator for that table no-ops with exit 0 and the "drift detector" checks row cardinality. Six of the eight contracts implementing the flagship anchor-checking differentiator trace to R5 (`--ignore`/`--allow`).

The JSON envelope contract is stated four incompatible ways across DD-011/DD-023, `events.md` Stage 6, `interface-definitions.md` §6.1, and `BC-2.13.001` PC1 — including the two most-cited test vectors (TV-BV013, described in-file as "the single most important correctness proof," and TV-133) both asserting the non-conformant shape.

Two documents never previously in a shard-8-shaped scope (`gene-transfusion-assessment.md` at version 1.0 with no changelog, `dtu-assessment.md`) contain direct contradictions of adjudicated invariants in **MUST** sections: instructions to keep Unicode combining marks that DI-012 requires stripped, the slug algorithm anchored to the path-comparison invariant, and a `dns-failure` test fixture that is a loopback IP and therefore produces `indeterminate(private-ip)` — the opposite verdict.

Three axes came back clean and are worth recording so future passes can spend their budget elsewhere: POLICY 2 (all 13 DIs BC-covered), the 13-code taxonomy's internal agreement between `error-taxonomy.md` and `failure-modes.md`, and the D-043 platform sweep (zero live survivors in scope).

**Spec has NOT converged.** The 3-clean-pass streak remains at ZERO. The dominant remaining pattern is not content error — it is that seven distinct corpus-wide sweeps (DD-022 verdict layers, DD-023 envelope, DI-001 four-field key, three-phase rename, DD-025 `--allow` fallback, DD-027 slug invariants, active-holdout de-citation) each have 4+ live survivors, in every case because enforcement was expressed as a positive list of sites rather than an exhaustiveness predicate over the forbidden value. Fixing the 49 findings individually will not stop the eighth sweep from behaving the same way.