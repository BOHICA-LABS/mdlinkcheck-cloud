---
document_type: adversarial-findings
level: ops
version: "1.0"
status: final
producer: adversary
timestamp: 2026-08-07T01:00:00Z
cycle: phase-1d
shard: 2
frozen_head: 1d3ed17
scope: "SS-03 (6) + SS-04 (3) + BC-2.06.002 = 10 BC bodies read in full"
counts: "4 CRITICAL / 7 HIGH / 13 MEDIUM = 24"
inputs:
  - .factory/specs/behavioral-contracts/ss-03/
  - .factory/specs/behavioral-contracts/ss-04/
  - .factory/specs/behavioral-contracts/ss-06/BC-2.06.002.md
input-hash: "43040b3"
traces_to: cycles/phase-1d/perimeter-sweep-synthesis.md
---

# Adversarial Findings — Perimeter Sweep Shard 2

**Scope:** SS-03 (6 BC bodies) + SS-04 (3 BC bodies) + BC-2.06.002 = 10 BC bodies read in full.
**Frozen HEAD:** `1d3ed17`
**Counts:** 4 CRITICAL / 7 HIGH / 13 MEDIUM = **24 findings**

---

## CRITICAL Findings

### P6-S2-001 (POLICY 4/19/16)

**Location:** BC-2.03.003.md:44-48,:58-61
**Title:** `broken_link_callback` return semantics INVERTED — sole owner of a closed-taxonomy reason code has ZERO VP coverage

Precondition 3 says the callback MUST return `None`; in pulldown-cmark returning None means DO NOT RESOLVE, so the reference is emitted as plain text and NO link event is created. `LinkType::{ReferenceUnknown,CollapsedUnknown,ShortcutUnknown}` exist ONLY when the callback returns `Some((dest,title))`. An implementer following PC3 verbatim reproduces exactly the failure PC3 claims to prevent: zero link events, zero findings, Exit 0. Test vector :72 is unexecutable.

`undefined-reference-definition` is one of the 13 closed codes and error-taxonomy.md:154 names BC-2.03.003 as its SOLE owner; combined with that BC having ZERO VP coverage, nothing in the spec set can detect this — the product ships a silently dead reason code. Propagated verbatim into prd.md:586 and purity-boundary-map.md:104 (blast radius 3).

**Fix:** return `Some((CowStr::Borrowed(""),CowStr::Borrowed("")))` and plumb the label from `BrokenLink.reference` (NOT `dest_url`, which the callback just emptied).

---

### P6-S2-002 (POLICY 4/19)

**Location:** BC-2.03.006.md:49-51
**Title:** Footnote exclusion "free by construction" is FALSE — footnotes are off by default; composition with broken-link callback creates 2 findings on a clean footnote

BC-2.03.006.md:49-51 claims footnote exclusion is "free by construction" and "no special-case filtering needed". FALSE: pulldown-cmark parses `[^1]` as a footnote ONLY with `Options::ENABLE_FOOTNOTES`, which is OFF by default — and `ENABLE_FOOTNOTES`/`Options::`/`ENABLE_GFM` appear ZERO times anywhere in the spec corpus (no artifact specifies the parser Options bitmask). With footnotes off plus BC-2.03.003's MANDATORY broken-link callback, `See [^1]` becomes a shortcut reference with label `^1` -> undefined -> Exit 1, and `[^1]: Source text.` is not a valid link reference definition so it parses as a paragraph producing a SECOND finding. BC-2.03.006's vector :62 demands Exit 0/no findings; the composition yields Exit 1 with 2 findings. Direct sibling contradiction; neither BC cites the other; invisible to checkers because both are individually well-formed.

---

### P6-S2-003 (POLICY 4/19)

**Location:** BC-2.03.001.md:47
**Title:** PC3 kind-classification enumerates only FOUR kinds with `otherwise -> relative-file` catch-all; non-http schemes manufacture false positives on every `mailto:` link

PC3's kind-classification enumerates only FOUR kinds with an `otherwise -> relative-file` catch-all, while its own Description :38 names five and capabilities.md:74-75 names six. `non-http` has no branch, so `mailto:/ftp:/tel:/data:/vscode:/javascript:` and protocol-relative `//host/path` all classify as `relative-file` -> filesystem lookup -> file-not-found -> Exit 1. Contradicts BC-2.03.005:44-46 (clean, not emitted), BC-2.03.004:47, error-taxonomy.md:142. BC-2.03.001 is the P0 CRITICAL-tier primary extraction contract and PC3 is the only place in the BC corpus stating the kind-decision algorithm — an implementer manufactures a false positive on every `mailto:` link.

---

### P6-S2-004 (POLICY 4)

**Location:** BC-2.04.002.md:46
**Title:** PC3 asserts `<pre>` and `<code>` yield no extraction but supplies NO MECHANISM; inline position produces false positives forbidden by the spec

PC3 asserts `<pre>` and `<code>` yield no extraction but supplies NO MECHANISM. Invariant 2 justifies only HTML comments; Invariant 1 only 4-space indents; EC-111 tests only `<pre>` at line-start (which works because `pre` is a CommonMark HTML-block type-1 start condition). For INLINE position — `Some text <code>[x](missing.md)</code>` — pulldown-cmark emits `InlineHtml` and the link parses as ordinary inline content producing a real `Tag::Link` -> extracted -> false positive. `code` is not one of the four type-1 block tags (pre, script, style, textarea) so it NEVER opens an HTML block; same for `<pre>` mid-line. Suppressing it requires heuristic open/close tracking across `InlineHtml` events, which BC-2.04.001.md:51 Invariant 1 explicitly FORBIDS and capabilities.md:87 says exclusion is "structural, not heuristic". DI-004 enumerates HTML `<code>` as in-scope. No EC, no vector, no VP for the inline case anywhere in SS-04.

---

## HIGH Findings

### P6-S2-005 (POLICY 4/9/16)

**Location:** BC-2.06.002.md:90-91
**Title:** VP-003 mis-anchored to "collision-bump produces CORRECT slugs" — invariants.md explicitly states VP-003 CANNOT detect the 0-based vs 1-based counter bug (FM-002 blind spot re-opened)

BC-2.06.002.md:90-91 mis-anchors VP-003 to "canonical triple-collision produces CORRECT slugs" and "counter reset between files", labelled "unit test". VP-INDEX.md:59 = kani P0, output-uniqueness. invariants.md:345-348 states explicitly that VP-003 "CANNOT detect the 1-based vs 0-based counter bug — injectivity is satisfied by both (setup,setup-1,setup-2) and (setup,setup-2,setup-3)". So the BC attributes to VP-003 precisely the obligation invariants.md says it cannot discharge, RE-OPENING the FM-002 blind spot for the headline differentiator: a Phase-3 reader trusting this table concludes VP-003 discharges the 0-based obligation and may drop VP-026 oracle row R-001 as redundant.

---

### P6-S2-006 (POLICY 5/4)

**Location:** BC-2.06.002.md:97
**Title:** FABRICATED quotation attributed to capabilities.md §CAP-006 — drops "0-based" and the while-loop form, the only capability-level guards against FM-002

BC-2.06.002.md:97 FABRICATES a quotation attributed to capabilities.md §CAP-006. The quoted string does not exist; grep of capabilities.md for `Setup`, `collision-bump`, `suffix counter` returns ZERO. Real CAP-006 says "0-based per-file duplicate disambiguation via the while(occurrences contains result) loop". The invented text DROPS the two load-bearing terms — "0-based" and the while-loop form — which are the only capability-level guards against FM-002. ID resolution passes because CAP-006 exists.

---

### P6-S2-007 (POLICY 4/9)

**Location:** BC-2.04.003.md:49-51,:95,:89
**Title:** BC-2.04.003 contradicts itself THREE ways on anchor_table.rs verification; :95 re-commits an error the coverage-matrix already corrected

BC-2.04.003 contradicts itself THREE ways on anchor_table.rs verification: :49-51 "no current VP covers the anchor_table.rs side; the story must add an INTEGRATION test"; :95 VP table says VP-014 covers it as a UNIT test; :89 says "dedicated UNIT test ... do NOT rely solely on integration test". VP-INDEX.md:70 and verification-coverage-matrix.md:66 assign VP-014's module as `link_extractor`, and coverage-matrix:30 records a prior remediation that REMOVED an erroneous VP-014 reference for exactly this reason — :95 re-commits the scrubbed error.

---

### P6-S2-008 (POLICY 4/9/16)

**Location:** BC-2.03.002.md:88-89, BC-2.03.001.md:72
**Title:** VP-019 mis-anchored across four rows; EOF resolution, case-insensitive label folding, and extraction completeness end up with NO verification vehicle

VP-019 mis-anchored at BC-2.03.002.md:88-89 (EOF reference resolution; case-insensitive label matching) and BC-2.03.001.md:72 (extraction completeness). VP-INDEX.md:75 = vp-019-one-verdict-per-link, proptest P1, DI-005; :92 narrows it to "duplicate-free within one file". Three of four rows describe properties VP-019 does not establish, all re-labelled as unit/property test. EOF resolution, case-insensitive label folding, and extraction completeness end up with NO verification vehicle.

---

### P6-S2-009 (POLICY 4)

**Location:** BC-2.03.001.md:51
**Title:** DI-004 "by construction" proof sketch asserts the OPPOSITE of what it needs; over-claims: covers only fenced + inline code while DI-004 also requires indented blocks, HTML pre/code, HTML comments

BC-2.03.001.md:51's DI-004 "by construction" proof sketch asserts the OPPOSITE of what it needs: it says pulldown-cmark's event model "nests links inside `Tag::CodeBlock`", which if true would REQUIRE a filter. Correct formulation is in the sibling BC-2.04.001.md:37-39. Also over-claims: covers only fenced + inline code while claiming DI-004 satisfied in full (DI-004 also requires indented blocks, HTML pre/code, HTML comments). This is the only stated proof of DI-004 in the CRITICAL-tier extraction BC; an implementer takes the premise literally and writes the heuristic filter capabilities.md:87 forbids.

---

### P6-S2-010 (POLICY 4)

**Location:** BC-2.03.002.md:82
**Title:** Shortcut-reference vector requires BC-2.03.003's callback precondition which BC-2.03.002 does not carry; vector yields Exit 0 forever with plain Parser::new()

BC-2.03.002.md:82's shortcut-reference vector requires BC-2.03.003's callback precondition, which BC-2.03.002 does not carry and never references (its Related BCs section was dropped in v1.3). With plain `Parser::new()` the vector yields Exit 0 forever. The remediation landed only in BC-2.03.003.

---

### P6-S2-011 (POLICY 4)

**Location:** BC-2.04.003.md:82
**Title:** Only BC vector ambiguous inside-vs-after fence — two clauses of same spec produce opposite verdicts on the same input

BC-2.04.003.md:82 vector says fenced block with `# Fake Heading` "FOLLOWED BY" `[x](#fake-heading)` -> Exit 1. Ambiguous whether the link is inside or after the fence; if inside, BC-2.04.001 PC1 mandates zero extraction -> Exit 0, the opposite verdict. test-vectors.md:150 TV-065 disambiguates via SEPARATE COLUMNS (link outside the fence); the BC collapsed two columns into one prose phrase and lost the distinction. It is the BC's only vector and the acceptance gate for the anchor_table side.

---

## MEDIUM Findings

**P6-S2-012** BC-2.03.003.md:44 places a mandatory obligation on scanner.rs but the BC owns only link_extractor.rs and bc-module-map.md:117 records no secondary module and no VP — obligation unowned by any story.

**P6-S2-013** BC-2.03.005.md:72-79 missing the entire `L2 Domain Invariants` row (all 8 siblings have it); asserts a DI-005 clean verdict and a no-diagnostic guarantee, citing neither; a missing ROW is invisible to ID checkers.

**P6-S2-014** BC-2.03.002.md:62-65 asserts DI-001's sort-key totality without citing DI-001, while DI-001 reciprocally depends on this BC's PC7 use-site rule; citation absent in both directions.

**P6-S2-015** BC-2.03.002.md:53-56 PC7 specifies position as "byte offset of the [text] span" (document-global) but interface-definitions.md:189-190,:244 define column as the 1-based byte offset WITHIN THE SOURCE LINE on the BOM-stripped LF-normalized buffer — different number, and DI-001 sorts on column.

**P6-S2-016** BC-2.03.003.md:53 overloads `link_target` with reference-label text, contradicting interface-definitions.md:191 (raw destination as written) and DI-001's 4th sort field; error-taxonomy.md:73 routes the label into the human MESSAGE instead, and finding objects have no message field.

**P6-S2-017** BC-2.04.001.md:63 has a THREE-cell row in a two-column table (third cell dropped on render), holds a test-vector id in the EC column, and cites "BRIEF.md lines 18-19" when the links are on lines 17-18 (line 19 has no link); same wrong range at test-vectors.md:51 which labels TV-BV013 the single most important correctness proof for R4.

**P6-S2-018** BC-2.03.004.md:36-38 Description calls `mailto:` autolinks "in scope as external URLs" while its own PC2 :47 classifies them `non-http`/silently-skipped.

**P6-S2-019** BC-2.03.004.md:52 imposes a `--help` documentation obligation absent from its upstream ASM-009 (which says README only), owned by no BC, with no EC/vector/VP — unfalsifiable.

**P6-S2-020** BC-2.06.002.md:67-71 Invariant 1 (per-file counter reset) is established by NO postcondition and owned by no module (slug.rs is pure core so a caller must reset, but no BC/VP covers it); Invariant 2's "unbounded counter" termination argument contradicts Precondition 2's `HashMap<String,u32>`.

**P6-S2-021** BC-2.03.001.md:65-67 canonical vectors assert filesystem verdicts (file-not-found) that a pure-core extraction BC cannot produce, with no cross-module note — while the two sibling BCs with the same shape both got explicit routing notes (INC-MAP-002, SF-003).

**P6-S2-022** (POLICY 14) Four of six SS-03 BCs carry `—` in the VP-NNN column = zero verification obligations, undetectable by check-placeholders.py which greps the literal `VP-TBD`; BC-2.03.003 is the aggravating case (sole owner of a closed-taxonomy code, carries the CRITICAL P6-S2-001, zero VP).

**P6-S2-023** BC-2.06.001.md:75-76 conflates rendered text with slug ("yields rendered text ctrlc"; it yields "Ctrl+C" — lowercasing and +-stripping are slug steps); BC-2.06.002 PC1 consumes that raw slug, so double-applied steps would mask genuine DI-012 rule-2/rule-7 divergences from the VP-026 oracle.

**P6-S2-024** BC-2.03.001.md:47 PC3's fragment test says "contains #" while DI-003 requires the FIRST UNESCAPED # in the raw undecoded string with `%23` never a separator — so `docs/a\#b.md` misclassifies as `cross-file-anchor`, the documented Sphinx #13620 root cause; DI-003 not cited.

---

## Note on BC-2.06.002 Arithmetic

BC-2.06.002's collision-bump ARITHMETIC was hand-verified CLEAN against github-slugger@2.0.0 for all three canonical vectors plus the uncovered `Setup/Setup 1/Setup` ordering — the BC's init=1/use-then-increment is exactly equivalent to github-slugger's init=0/increment-then-use. The FM-002 risk here is NOT arithmetic; it is P6-S2-005 and P6-S2-006, both attacks on the PROOF, which is precisely how FM-002 survives an injectivity check.
