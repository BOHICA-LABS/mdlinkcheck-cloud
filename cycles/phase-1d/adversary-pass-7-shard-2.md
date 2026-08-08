---
document_type: adversarial-review
level: ops
version: "1.0"
status: final
producer: adversary
timestamp: 2026-08-08T00:00:00Z
cycle: phase-1d
pass: 7
shard: 2
frozen_develop_head: f8ee4eb024b8b4a300139ef803d248e8fe40f2fc
frozen_specs_tree: ace1745871122cd1fa2c46cf27c5493cc1083411
frozen_spec_lint_tree: f2392b456c3bd669e3efbe86b3e6eae62e302ed1
severity_vocabulary: "CRITICAL/HIGH/MEDIUM/LOW (single vocabulary per PG-012 ruling)"
findings_total_self_declared: 21
findings_total_disputed: "self-declared 21 / predicate-parsed 23; CRITICAL self-declared 9 / predicate-parsed 10 — unadjudicated, PG-012 class"
inputs: []
input-hash: "ace1745"
traces_to: STATE.md
---
# Pass 7 — Shard 2: SS-03 + SS-04 + SS-06 (11 BC bodies)

```
scope: "SS-03 (6) + SS-04 (3) + SS-06 (2) = 11 bodies read in full"
files_read_in_full:
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-03/BC-2.03.001.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-03/BC-2.03.002.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-03/BC-2.03.003.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-03/BC-2.03.004.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-03/BC-2.03.005.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-03/BC-2.03.006.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-04/BC-2.04.001.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-04/BC-2.04.002.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-04/BC-2.04.003.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-06/BC-2.06.001.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-06/BC-2.06.002.md
reference_read (partial or full, for claim verification):
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/product-brief.md (full)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/capabilities.md (full)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/invariants.md (full)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/decisions.md (DD-007..DD-027)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/entities.md (grep)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/prd-supplements/error-taxonomy.md (full)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/prd-supplements/test-vectors.md (§2 §3 §5 §10.4 + greps)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/VP-INDEX.md (full)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-001-slug-total.md (full)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-002-slug-deterministic.md (full)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-003-slug-duplicate-uniqueness.md (full)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-012-slug-fuzz.md (full)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-014-code-context-exclusion.md (full)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-018-slug-worked-examples.md (full)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-019-one-verdict-per-link.md (full)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-026-slug-differential-fidelity.md (full)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/api-surface.md (§Library API + §Key Shared Types)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/module-decomposition.md (§Pure/Effectful Seam)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/feasibility-review.md (§SF-003)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/prd.md (§2.3/2.4/2.6 tables, RTM lines 420-459, remediation log)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/scripts/spec-lint/check-ec-injectivity.py (full)
findings_total: 21
severity_counts: CRITICAL 9 / HIGH 5 / MEDIUM 5 / LOW 2
verdict: NOT CLEAN — nine CRITICAL defects, including three false-green VP tables (BC-2.03.002, BC-2.06.001, BC-2.06.002) that name formal Kani/proptest proofs for properties those proofs explicitly disclaim, an inverted pulldown-cmark broken-link-callback contract that makes `undefined-reference-definition` unreachable, a non-total link-kind classification rule, and 11 of 12 SS-06 edge-case IDs mis-anchored against the canonical test-vector registry.
```

---

### P7-S2-001 — BC-2.03.001 PC3 link-kind classification rule is not total; `mailto:`, protocol-relative, and empty destinations are misclassified as `relative-file` [CRITICAL]

`BC-2.03.001.md:48` is the normative classification rule:

> `3. Link kind is determined by the destination string: starts with http:// or https:// → external; starts with # → anchor-only; contains # after a path component → cross-file-anchor; otherwise → relative-file.`

Four branches, with `relative-file` as the catch-all. But the closed `LinkKind` set has **six** members — `domain-spec/entities.md:37`: "`relative-file`, `anchor-only`, `cross-file-anchor`, `external-http`, `non-http` (skipped), `undefined-reference`" — and `capabilities.md:76-78` (CAP-003, the BC's own anchor) enumerates the same six. BC-2.03.001's own Description at `:38-39` names five of them, including "`non-http` (silently skipped)".

So PC3, the only normative rule in the BC, **cannot produce `non-http` or `undefined-reference` at all**, and routes them into `relative-file`. Concrete consequences against registered vectors:

- `mailto:a@b.com` (EC-173, `test-vectors.md:389`, expected exit 0 / no findings) → PC3 yields `relative-file` → path resolution → `file-not-found` → exit 1. Same for EC-174 `ftp://x/y`, EC-175 `tel:+15551234`, EC-176 `javascript:void(0)`, EC-177 `//example.com/x` (`test-vectors.md:389-393`). All five are BC-2.03.005's own edge cases.
- `[x]()` (EC-031, `test-vectors.md:109`, expected `broken(malformed-url)` per BC-2.07.007) → PC3 yields `relative-file`, not `malformed-url`.
- `//example.com/x` additionally reaches the "otherwise" branch even though `error-taxonomy.md:142` lists protocol-relative `//host` in the silently-skipped set.

The BC never says PC3's `relative-file` result is provisional pending `url_classifier::classify_url`. `api-surface.md:98-99` shows `classify_url(dest) -> UrlKind { HttpS(Url), NonHttp, Malformed(String) }` exists as a separate stage, and BC-2.03.005's Architecture Module row (`BC-2.03.005.md:79`) confirms the non-http verdict is "`url_classifier` classification" — but nothing in BC-2.03.001 defers to it. As written, PC3 is a complete, wrong function.

**Predicate:** `Grep "relative-file|anchor-only|cross-file-anchor|external-http|non-http|undefined-reference" .factory/specs/domain-spec/entities.md` → 2 matching lines (`:37` enumerating 6 variants, `:84` `kind | LinkKind`). `Grep "LinkKind|OffsetEvent|anchor_table::build\b|build_anchor_table" .factory/specs` → 12 matches across 5 files; `LinkKind` is **referenced** at `api-surface.md:126` and `entities.md:84` and **defined nowhere** as a Rust enum (no `enum LinkKind` in `api-surface.md` §Key Shared Types, lines 120-127).

**Consequence:** An implementer following the extraction contract literally emits `broken(file-not-found)` and exit 1 for every `mailto:`/`ftp:`/`tel:` link in a repo — the exact false-positive class the product exists to eliminate (`product-brief.md:28-29`). Five registered TV rows fail. `LinkKind` also has no authoritative variant definition anywhere in the architecture, so a story-writer cannot construct the type.

---

### P7-S2-002 — BC-2.03.001 Invariant 1 states the inverse of the pulldown-cmark fact it uses as its premise [HIGH]

`BC-2.03.001.md:52`:

> `1. Code context links are NEVER extracted (DI-004). Since pulldown-cmark's event model nests links inside Tag::CodeBlock and Event::Code never produces a nested Tag::Link, matching only Tag::Link/Tag::Image satisfies this by construction.`

The premise "pulldown-cmark's event model **nests links inside** `Tag::CodeBlock`" asserts exactly the opposite of the required fact and, if true, would falsify the conclusion. The correct formulation is present in the sibling BC — `BC-2.04.001.md:39-41`: "code block content arrives as `Event::Text` inside `Tag::CodeBlock`, and inline code arrives as `Event::Code` — **neither ever produces a `Tag::Link` event**." VP-014's Property Statement (`vp-014-code-context-exclusion.md:47`) also states it correctly.

This is a library-semantics claim under the extraction module and is the sole stated justification for DI-004 holding "by construction" in the primary extraction BC.

**Predicate:** magnitude not established by predicate — single-site defect, cited by line.

**Consequence:** The by-construction argument for DI-004 in the BC that owns inline extraction is unsound as written. An implementer who reads the premise at face value concludes a runtime code-context guard is required in `link_extractor.rs`, reintroducing the heuristic exclusion that DI-004 (`invariants.md:117-121`) and CAP-004 (`capabilities.md:90`) forbid ("Exclusion is structural (AST event matching), not heuristic").

---

### P7-S2-003 — BC-2.03.001 PC2 requires a `source file` field that `ExtractedLink` does not have [MEDIUM]

`BC-2.03.001.md:47`: "Each extracted link has: **source file**, line, column, destination string (raw), link kind."

`api-surface.md:126` defines the type: `pub struct ExtractedLink { pub dest: String, pub kind: LinkKind, pub line: u32, pub col: u32 }` — four fields, no `source_file`. `api-surface.md:85`: `pub fn extract_links(events: &[OffsetEvent]) -> Vec<ExtractedLink>` — the function has no path parameter, so it *cannot* populate one.

This was already adjudicated on the VP side and never propagated back: `vp-019-one-verdict-per-link.md:48` — "**Scope note:** `extract_links` processes one file at a time; `source_file` is the implicit caller context, **not a field on each event**." VP-019's v1.1 changelog (`:29`) records "Fixed harness key to include source_file"; v1.2 (`:26`) walked it back to the `(dest, line, col)` key. BC-2.03.001's PC2 still carries the pre-walkback wording.

**Predicate:** magnitude not established by predicate — single-site defect, cited by line.

**Consequence:** Partial-fix propagation gap (POLICY 8). An implementer adding a `source_file: PathBuf` to `ExtractedLink` to satisfy PC2 diverges from `api-surface.md:126`; one who does not, fails PC2. Also inflates per-link memory across the `LinkMap` (`module-decomposition.md:115`).

---

### P7-S2-004 — BC-2.03.001 VP-019 row claims image coverage VP-019's harness cannot provide [MEDIUM]

`BC-2.03.001.md:73`: `| VP-019 | Every Tag::Link/Tag::Image outside code context is extracted | proptest |`

VP-019's completeness harness generates only inline **links**: `vp-019-one-verdict-per-link.md:126-131` builds `format!("[link{}]({})", i, d)`, and the deduplication strategy `arb_inline_link()` at `:155-161` emits `format!("[{}]({}.md)", text, dest)`. Neither produces a `!`-prefixed image, so `Tag::Image` is never in the generated input space and the assertion `links.len() == n` at `:137-143` never exercises the image path.

R3 (`product-brief.md:44`) — "Reference-style links **and images** are checked the same as inline ones" — and BC-2.03.001 PC4 (`:49`) make image parity a first-class requirement. VP-INDEX assigns BC-2.03.001 `VP-019, VP-014` (`VP-INDEX.md:159`); neither VP body generates an image.

**Predicate:** `Grep "Tag::Image|!\[" .factory/specs/verification-properties/vp-019-one-verdict-per-link.md` → 0 matches for image syntax in any strategy or harness body (the only `Tag::Image` reference in the whole corpus's VP files for link_extractor is absent).

**Consequence:** The image half of R3 has no falsifying vehicle in any named VP. An extractor that matches `Tag::Link` and silently drops `Tag::Image` passes VP-019 and VP-014 green while failing EC-040 (`test-vectors.md:118`, `![alt](missing.png)` → exit 1) and EC-101 (`:207`). VP-019's own Non-Vacuousness Analysis table (`:168-173`) does not list "extractor ignores images" as a falsified wrong implementation.

---

### P7-S2-005 — BC-2.03.002's entire Verification Properties table is false-green; VP-019 proves neither cited property, and PC7/EC-202 has no VP row at all [CRITICAL]

`BC-2.03.002.md:86-90`:

```
| VP-NNN | Property | Proof Method |
| VP-019 | Reference definitions at EOF are resolved for uses at line 1 | proptest |
| VP-019 | Label matching is case-insensitive | proptest |
```

VP-019 (`vp-019-one-verdict-per-link.md`) proves exactly two things, per its own Property Statement at `:44-46`: (a) each `(dest, line, col)` tuple appears at most once, and (b) N **inline** links yield N entries. Its title is "extract_links Output Is Duplicate-Free — No Position Extracted Twice". Neither harness (`:81-104`, `:121-144`) contains a reference definition, a `[label]: url` line, an EOF-definition fixture, or any case-varied label. `source_bc: BC-2.03.001` (`:14`). Nothing in VP-019 can fail if reference resolution is broken or if label matching is case-**sensitive**.

This was made worse, not better, by remediation. BC-2.03.002's v1.4 changelog (`:26`) reads: "(WS-4-B) Proof-method join repair: both VP-019 rows 'unit test' → 'proptest' (VP-INDEX authority)." The repair changed the *method label* from an honest "unit test" to "proptest" without reading VP-019's Property Statement, converting a vague claim into a specific, false claim of property-based coverage.

Separately, PC7 (`:54-57`, use-site finding position) and Invariant 4 (`:63-66`, definition-site attribution FORBIDDEN — "silently swallows one broken link") were added in v1.3, together with EC-202 (`:76`) and its canonical vector (`:84`). The Verification Properties table was **not** extended: no row covers use-site position. `test-vectors.md:437` registers TV-202 with VP column "(none)".

**Predicate:** `Grep "^\| VP-" .factory/specs/behavioral-contracts/ss-03/BC-2.03.002.md` → 2 rows, both VP-019. `Grep "ref\]:|reference definition|case-insensitiv|EOF" .factory/specs/verification-properties/vp-019-one-verdict-per-link.md` → 0 matches.

**Consequence:** Three high-value properties of the reference-style extraction contract — whole-document definition resolution (EC-095, `test-vectors.md:201`), case-insensitive label matching (EC-098, `:204`), and use-site position (EC-202, `:437`, whose own Invariant 4 says violation "silently swallows one broken link") — are all unverified while the BC presents two of them as covered by a named proptest VP. A verification gate reading this table reports green for properties nothing checks.

---

### P7-S2-006 — BC-2.03.002 Invariant 2 mandates ASCII case folding for label matching; CommonMark 0.31.2 (pinned by CAP-002/DD-006) mandates Unicode case fold [MEDIUM]

`BC-2.03.002.md:61`: "2. Label matching is not locale-dependent; it follows CommonMark **ASCII** case folding."

CAP-002 (`capabilities.md:64-65`) pins the grammar: "the CommonMark **0.31.2** + GFM grammar (AST-based, not regex; pulldown-cmark 0.13.4)". CommonMark 0.31.2's link-label matching rule specifies **Unicode** case fold, not ASCII case fold, after whitespace stripping and internal-whitespace collapse. PC4 at `:51` states the whitespace half correctly ("internal whitespace normalized to single space, leading/trailing stripped") but says only "case-insensitive", so Invariant 2 is the sole normative statement of the folding rule — and it narrows it.

The corpus takes Unicode folding seriously everywhere else (DI-002 NFC handling, `invariants.md:85-102`; DI-012 rule 2 "Full Unicode `to_lowercase()`. **Not ASCII-only case folding**", `invariants.md:301-303`), which makes this narrowing an outlier rather than a deliberate scope decision — there is no DD/D-number attached to it.

**Predicate:** `Grep "ASCII case fold|ascii case fold" .factory/specs` → 1 match, `BC-2.03.002.md:61`. No decision record cites it.

**Consequence:** Labels differing only in non-ASCII case (`[Привет]` vs `[привет]`, `[STRASSE]` vs `[straße]`) would be treated as distinct labels, producing `undefined-reference-definition` (exit 1) on a document GitHub renders as a valid link. Confidence MEDIUM: the CommonMark-spec wording is asserted from knowledge of the spec, not from a corpus artifact quoting it — no artifact in `.factory/specs` states the folding rule independently, which is itself the reason this survived.

---

### P7-S2-007 — BC-2.03.003 inverts the pulldown-cmark broken-link-callback contract: a callback returning `None` makes the `undefined-reference-definition` verdict unreachable, which is the exact failure the precondition claims to prevent [CRITICAL]

`BC-2.03.003.md:45-49` (Precondition 3) and `:59-62` (Invariant 2):

> `3. **scanner.rs MUST construct the pulldown-cmark parser via Parser::new_with_broken_links()** (or the equivalent API that installs a broken_link_callback). The callback MUST return None so that the link destination is left empty and the event is retained as a *Unknown variant for classification. Without this callback, pulldown-cmark emits undefined reference links as plain text (no link event at all), making this verdict unreachable.`

Two factual errors about `pulldown-cmark`, both load-bearing:

1. **The callback's `None`/`Some` semantics are inverted.** `pulldown-cmark`'s `BrokenLinkCallback` is `FnMut(BrokenLink) -> Option<(CowStr, CowStr)>`. Returning `Some((url, title))` is what causes the parser to emit a link event — carrying `LinkType::ReferenceUnknown` / `CollapsedUnknown` / `ShortcutUnknown` precisely to mark that the destination came from the callback rather than a definition. Returning `None` tells the parser *not* to treat the span as a link, i.e. it is emitted as text. So the mandated `MUST return None` produces exactly the "plain text (no link event at all), making this verdict unreachable" outcome the precondition was written to avoid. Invariant 2's first clause (`*Unknown` variants require a registered callback) is correct; the `MUST return None` requirement contradicts it.

2. **`Parser::new_with_broken_links()` does not exist.** The real constructor is `Parser::new_with_broken_link_callback(text, options, callback)`. The BC hedges with "(or the equivalent API…)", but names a non-existent function inside a bolded **MUST**.

This is not an isolated slip — the same inverted claim is the *authored remediation text* in the PRD and is already propagated into the architecture:
- `prd.md:597` (SR-027 remediation record): "…with a `broken_link_callback` that returns `None`. Without this callback, undefined reference links are emitted as plain text…"
- `architecture/purity-boundary-map.md:107`: "Running `pulldown-cmark::Parser::new_with_broken_links()` (pure-ish)"

**Predicate:** `Grep "broken_link|BrokenLink|new_with_broken" .factory/specs` → 8 matches across 4 files; 3 in `vp-017-scan-terminates.md` are unrelated ("broken links" prose), the other 5 are `BC-2.03.003.md:45,46,60`, `prd.md:597`, `purity-boundary-map.md:107`. `Grep "new_with_broken_link_callback" .factory/specs` → 0 matches. No spec artifact anywhere names the real API.

**Consequence:** An implementer who follows PC3 exactly registers a callback returning `None`, gets no link event for `[text][nope]`, emits zero findings, and exits 0. EC-096 / TV-096 (`test-vectors.md:202`, "`[text][nope]` — label never defined | 1 | broken (`undefined-reference-definition`)") fails. `undefined-reference-definition` is one of the 13 closed reason codes (`error-taxonomy.md:73, 102`) and is the *only* code in the taxonomy owned by BC-2.03.003 (`error-taxonomy.md:154`) — so an entire reason code becomes dead. Because this BC is `test-sufficient` in VP-INDEX (`:161`) with no VP body, nothing independent contradicts the wrong claim. The defect must be fixed in three files, not one.

---

### P7-S2-008 — BC-2.03.005 has no `L2 Domain Invariants` Traceability row; it is the only body in the shard missing it, and it assigns a `clean` verdict with no DI anchor [MEDIUM]

`BC-2.03.005.md:73-80` — the Traceability table runs `L2 Capability` → `Capability Anchor Justification` → `Brief Requirement` → `Architecture Module` → `Stories`. The `L2 Domain Invariants` row is absent.

Every sibling in the shard has it, including the two that make the *same* kind of verdict assignment: BC-2.03.004 (`:78`, `DI-005`) also assigns `clean` to `non-http` (`BC-2.03.004.md:48`) and cites DI-005; BC-2.03.003 (`:86`, `DI-005`). BC-2.03.005 PC3 (`:47`) states "Effective verdict: `clean`" — a DI-005 verdict assignment (`invariants.md:129-133`, "Each extracted link is assigned exactly one verdict") — with nothing to trace it to.

PRD's RTM row confirms the gap rather than contradicting it: `prd.md:438` — `| BC-2.03.005 | CAP-003 | — | R2c | P0 | unit |`.

**Predicate:** `Grep "^\| L2 Domain Invariants \|" .factory/specs/behavioral-contracts` → 46 files of 66 BC files. Within this shard: 10 of 11 present; the single absentee is `ss-03/BC-2.03.005.md`.

**Consequence:** POLICY 2 coverage gap. The only BC in SS-03 that specifies *silent* behaviour (PC2 `:46`: "The link is NOT emitted in output (neither text nor JSON)") has no invariant anchor, so no DI→VP coverage obligation flows from it. `error-taxonomy.md:142` confirms non-http emits no reason code at all, making this the one path in SS-03 where "no output" and "no verdict" are indistinguishable in the report — precisely the DI-005 no-verdict case that DI-005's own coverage note flags as uncovered (`VP-INDEX.md:92`).

---

### P7-S2-009 — BC-2.03.006's footnote exclusion depends on a `pulldown-cmark` `Options` flag that no spec artifact pins; under the option set BC-2.02.001 actually enumerates, the BC's own test vector fails with exit 1 via BC-2.03.003 [CRITICAL]

`BC-2.03.006.md:49-51` (Invariants) and `:62` (canonical vector):

> `1. pulldown-cmark handles both cases by construction; this BC documents the expected behavior.`
> `2. No special-case footnote filtering code is needed.`
> `| See [^1] for details.\n\n[^1]: Source text. | Exit 0; no findings | happy-path |`

`pulldown-cmark` recognises footnote syntax **only** when `Options::ENABLE_FOOTNOTES` (or `ENABLE_OLD_FOOTNOTES`) is set. `Options::empty()` is the default, and under it:

- `[^1]: Source text.` is parsed as a link reference definition attempt with label `^1`; `Source` becomes the destination and `text.` is not a valid title, so the definition is invalid and the line stays a paragraph.
- `[^1]` in the preceding paragraph is therefore an **undefined shortcut reference**.
- With the `broken_link_callback` that BC-2.03.003 PC3 (`:45-49`) mandates on the parser, that becomes a `LinkType::ShortcutUnknown` event → BC-2.03.003 PC1/PC2 (`:52-53`): verdict `broken`, reason `undefined-reference-definition` → **exit 1**.

The corpus's only statement about which extensions are enabled *excludes* footnotes, and self-contradicts in the same sentence — `BC-2.02.001.md:50`: "GFM extensions (**tables, strikethrough, task lists**) are enabled; footnotes are **recognized** but treated as non-links." Footnotes cannot be "recognized" without being enabled, and they are not in the enabled list.

BC-2.03.006 contains no precondition on the option set, no `Related BCs` section, and no cross-reference to BC-2.03.003 — which is where the conflict lives.

**Predicate:** `Grep "ENABLE_FOOTNOTES|ENABLE_TABLES|pulldown_cmark::Options|Options::empty|Options::ENABLE" .factory/specs` → **0 matches, 0 files**. (An earlier broader `Grep "ENABLE_|Options::|Options\b"` returned 4 hits, all English prose: `gene-transfusion-assessment.md:266,271,277` and `interface-definitions.md:34`.) `Grep "footnote|Footnote|FOOTNOTE" .factory/specs` → 12 matches across 6 files; the only one describing parser configuration is `BC-2.02.001.md:50`.

**Consequence:** The exit code for the footnote input is **undetermined by the spec corpus**, and the language default yields the wrong one. BC-2.03.006's canonical vector and TV-120 (`test-vectors.md:225`, exit 0 / none) both fail; BC-2.03.006 and BC-2.03.003 issue contradictory verdicts for the same bytes; and Invariant 2 ("No special-case footnote filtering code is needed") is false. Because the whole parser `Options` bitmask is unpinned, this is also an unbounded risk surface for EC-113 (GFM table, `test-vectors.md:218`) and EC-114 (escaped pipe, `:219`), whose behaviour likewise depends on `ENABLE_TABLES`. There is no artifact an implementer can consult to construct the parser.

---

### P7-S2-010 — BC-2.04.002 PC3 claims HTML `<code>` elements yield no link extraction; this is false under CommonMark HTML-block start conditions and has neither an EC nor a VP [CRITICAL]

`BC-2.04.002.md:47`: "3. `<pre>` and `<code>` HTML elements also yield no link extraction." Invariant 1 (`:50`) asserts "pulldown-cmark handles this correctly."

`<pre>` is correct: it is a **type-1** CommonMark HTML-block start condition (`<pre`, `<script`, `<style`, `<textarea>`), so `<pre>[x](missing.md)</pre>` becomes raw `Event::Html` and the link is never parsed. EC-111 / TV-111 (`test-vectors.md:216`) tests exactly this case.

`<code>` is **not** in any HTML-block start-condition list. It is not type 1, and it is absent from the type-6 block-level tag-name list (which contains `p`, `div`, `table`, `li`, `h1`-`h6`, etc., but not `code` — `code` is an inline element). Therefore `<code>[x](missing.md)</code>` on its own line is a **paragraph** containing an inline raw-HTML token `<code>`, followed by ordinary inline content. `[x](missing.md)` is parsed as an inline link, `Tag::Link` is emitted, and the link **is** extracted → `broken(file-not-found)` → exit 1.

VP-014 corroborates the gap by omission. `vp-014-code-context-exclusion.md:49-54` enumerates "The five excluded contexts": fenced blocks, inline code spans, indented code blocks, "**HTML `<pre>` blocks**", HTML comments. `<code>` is not among them, and none of the four harnesses at `:72-113` exercises it. There is no EC for `<code>` in BC-2.04.002's table (`:56-58`: EC-106, EC-110, EC-111 only) and none in `test-vectors.md` §5.

The false claim originates upstream in CAP-004 (`capabilities.md:89`: "indented code blocks (4-space), HTML `<pre>`/`<code>`, HTML comments") and DI-004 (`invariants.md:120`: "HTML `<pre>`/`<code>`") and was copied into BC-2.04.002 verbatim — including into the L2 Capability quote at `:75`.

**Predicate:** `Grep "^\| EC-" .factory/specs/behavioral-contracts/ss-04/BC-2.04.002.md` → 3 rows (EC-106, EC-110, EC-111); none names `<code>`. `Grep "<code>" .factory/specs/verification-properties/vp-014-code-context-exclusion.md` → 0 matches.

**Consequence:** A postcondition of a CRITICAL-tier pure-core module is factually wrong about the parser, and it is stated as free-by-construction so no implementer will guard it. Any repository documenting inline API names as `<code>href="x.md"</code>`-style HTML produces false-positive broken links. Because VP-014's five-context list silently omits `<code>`, the integration suite reports green for "all code contexts excluded" while never testing the one context the BC gets wrong — a false-green in the DI-004 gate.

---

### P7-S2-011 — BC-2.04.003's `anchor_table::build` model contradicts both architecture documents, and the dedicated unit test it mandates is structurally vacuous [CRITICAL]

BC-2.04.003 asserts, in six places, that `anchor_table::build` consumes a `Tag::Heading` **event stream**:

- `:47-48` "`anchor_table::build` receives no `Tag::Heading` events for content inside `Tag::CodeBlock`; verified by a dedicated unit test on `anchor_table::build` directly"
- `:62` "`anchor_table::build` receives no `Tag::Heading` event for the heading-like line"
- `:71-72` Invariant 2 — "`anchor_table::build` **consumes only `Tag::Heading` events**; since none are emitted for code block content, exclusion is automatic and testable"
- `:90` Acceptance Criterion — "`anchor_table::build(events)` produces zero entries … | **Dedicated unit test** on `anchor_table::build` directly — do NOT rely solely on integration test"

Both architecture documents say otherwise:

- `api-surface.md:81`: `pub fn build_anchor_table(headings: &[ParsedHeading]) -> AnchorTable;` with `ParsedHeading { pub text: String, pub level: u8 }` (`:125`).
- `module-decomposition.md:90-94`: `scanner (Pass 1) → ParsedFile { …, headings: Vec<ParsedHeading>, … }` then `anchor_table::build(&headings) → AnchorTable [pure]`.

So the function takes a pre-extracted `&[ParsedHeading]` slice. It never sees a `Tag::Heading` event, never sees a `Tag::CodeBlock`, and cannot perform code-context exclusion. **The exclusion is enforced by `scanner.rs` when it populates `headings: Vec<ParsedHeading>`** — a module BC-2.04.003 never mentions.

Consequently the mandated test is vacuous: to call `build_anchor_table(&[ParsedHeading])` the test must construct the slice itself, so passing an empty slice and asserting zero entries validates the test's own fixture, not the product. It cannot fail no matter how badly `scanner.rs` mishandles code blocks. Two further defects follow: the symbol `anchor_table::build` does not exist in `api-surface.md` (which names `build_anchor_table` / `build_with_html`), and the argument at `:90` is `(events)` where both architecture docs say `(&headings)`.

The upstream source got this right and BC-2.04.003 dropped the qualifier. `feasibility-review.md:227-229`: "Preventing headings inside code blocks from entering the anchor table requires that `anchor_table::build` also filters on event context — **or more precisely, that the event stream fed to `anchor_table` correctly marks code-block events so headings inside them are not processed**." BC-2.04.003's v1.1 changelog (`:23`) claims to have implemented SF-003; the "more precisely" clause — the only part that locates the real defect surface — was not carried over.

**Predicate:** `Grep "anchor_table::build\b|build_anchor_table" .factory/specs` → 13 matches across 5 files: `api-surface.md:81` and `purity-boundary-map.md:56` use `build_anchor_table(headings)`; `module-decomposition.md:94,113` use `anchor_table::build(&headings)`; `feasibility-review.md:227,233,241` and `BC-2.04.003.md:47,48,51,62,71,90,96` use `anchor_table::build`. Zero occurrences pass events. `Grep '```rust' .factory/specs/behavioral-contracts` → **0 matches**, so none of these symbols appears inside a fenced block where a type-checker or reader would notice the signature mismatch.

**Consequence:** BC-2.04.003 is the sole normative contract for a P0 cross-module concern, and it mandates a test that cannot detect the regression it targets, against a function signature that does not exist, while the module that can actually regress (`scanner.rs` heading collection) receives no acceptance criterion in the Acceptance Criteria table at `:87-90`. A story built from this BC ships green with EC-065 / TV-065 (`test-vectors.md:150`, fenced `# Fake Heading` → exit 1 broken) unprotected.

---

### P7-S2-012 — BC-2.04.003's VP table attributes the anchor_table property to VP-014, contradicting the BC's own Description and VP-014's Property Statement [CRITICAL]

`BC-2.04.003.md:92-96`:

```
| VP-NNN | Property | Proof Method |
| VP-014 | Heading-like lines in code blocks not extracted as links | integration (link_extractor.rs) |
| VP-014 | anchor_table::build produces no entry for heading-like lines inside fenced code | integration (anchor_table.rs) — new test required in this story |
```

Row 2 places `VP-014` in the VP-NNN column for a property VP-014 does not cover. The same document says so at `:50-52`: "VP-014 covers the `link_extractor.rs` side. **No current VP covers the `anchor_table.rs` side**; the story must add an integration test…". `feasibility-review.md:238-239` agrees: "VP-014 covers link extraction; **no VP currently covers the anchor_table exclusion**."

VP-014's own body confirms: `source_bc: BC-2.04.001` (`vp-014-code-context-exclusion.md:14`), `module: link_extractor` (`:15`), Property Statement scoped entirely to `link_extractor::extract(events)` (`:45`), and all four harnesses (`:72-113`) assert on `extract_links(&events)`. There is no reference to `anchor_table`, `AnchorTable`, or `ParsedHeading` anywhere in the file. VP-INDEX assigns VP-014 to module `link_extractor` (`VP-INDEX.md:70`).

**Predicate:** `Grep "anchor_table|AnchorTable|ParsedHeading" .factory/specs/verification-properties/vp-014-code-context-exclusion.md` → 0 matches.

**Consequence:** Textbook false-green. The Verification Properties table is the machine-readable coverage claim; a gate joining BC VP tables against VP-INDEX sees BC-2.04.003 fully VP-covered and marks it done, while the anchor-side property the BC itself declares uncovered has no vehicle. The "new test required in this story" caveat is prose in a table cell that no gate parses. Combined with P7-S2-011 (the test it *does* mandate is vacuous), the anchor_table side of BC-2.04.003 has zero effective coverage under two independent claims of coverage.

---

### P7-S2-013 — BC-2.06.001 claims Kani VP-002 proves DI-012 traps T1 and T2; VP-002 proves determinism only and passes trivially for an implementation that collapses hyphen runs [CRITICAL]

`BC-2.06.001.md:111-112`:

```
| VP-002 | Space→hyphen is 1:1 (trap T1) | kani |
| VP-002 | Unicode word chars preserved (trap T2) | kani |
```

VP-002 is `# VP-002: slug::compute_slug is Deterministic — Same Input Produces Same Output` (`vp-002-slug-deterministic.md:35`). Its Property Statement (`:39`): "two calls to `compute_slug(s, &mut counter)` with equivalent initial states return byte-identical `String` values." Its only assertion (`:75`) is `assert_eq!(slug1, slug2)`. A `slugify` that collapses hyphen runs, strips CJK, or lowercases ASCII-only is **perfectly deterministic** and satisfies VP-002 with no failure.

VP-INDEX agrees VP-002 does not touch DI-012: `VP-INDEX.md:58` — `| VP-002 | vp-002-slug-deterministic.md | slug | kani | P0 | — (CAP-006, NFR-003) |`, DI column empty. DI-012's coverage row (`VP-INDEX.md:99`) assigns it to **VP-018 + VP-026** only. `invariants.md:324-331` names VP-018 and VP-026 as DI-012's falsifying vehicles; VP-002 is not mentioned.

The two properties BC-2.06.001 mis-assigns are the two highest-risk traps in the product. Trap T1 is DI-012 rule 3 (`invariants.md:304-306`) — the `AI & Automation` → `ai--automation` case whose 1-hyphen failure is FM-001 and is registered as the flagship differentiator TV-043/TV-044 (`test-vectors.md:128-129`, "v2 proof: single hyphen is WRONG slug"). Trap T2 is DI-012 rule 6 (`invariants.md:310`). Their real vehicles are VP-026 oracle R-002 / proptest `prop_vp026_rule3_space_to_hyphen_1to1` and R-007 / `prop_vp026_rule6_unicode_word_retained` (`vp-026-slug-differential-fidelity.md:175, 178, 369-386, 431-450`).

This was introduced by remediation. BC-2.06.001's v1.5 changelog (`:27`): "Proof-method join: … VP-002 rows 'unit test' → 'kani' … (all per VP-INDEX authority)". The join copied VP-002's *method* from VP-INDEX without reading VP-002's *property*, upgrading an honest "unit test" label into a claim of P0 formal proof.

**Predicate:** `Grep "hyphen|1:1|Unicode|\\\\p\{" .factory/specs/verification-properties/vp-002-slug-deterministic.md` → 0 matches. The file's only postcondition is `assert_eq!(slug1, slug2)` at `:75`.

**Consequence:** The two highest-risk correctness properties of the product's stated primary differentiator (`BC-2.06.001.md:123`, "slug algorithm is the primary differentiator") are marked as discharged by a **P0 Kani proof** that cannot detect either failure. A verification gate joining BC VP tables against VP-INDEX sees `VP-002 | kani | P0` and reports formal coverage. If VP-026 slips (it is P1, `VP-INDEX.md:82`, with Phase-3 oracle-fixture obligations at `vp-026:492-510`), FM-001 and DI-012 rules 3 and 6 ship unverified behind a green P0 signal.

---

### P7-S2-014 — BC-2.06.001's VP-001 row drops the ASCII/16-byte bound, and the BC has no postcondition for the totality and determinism that VP-001/VP-002 claim to discharge [HIGH]

Two halves of one broken bidirectional anchor.

**BC → VP overclaim.** `BC-2.06.001.md:110`: `| VP-001 | Slug function is total — terminates without panic for **any input** | kani |`. VP-001's actual scope is explicit and narrow: title "`# VP-001: slug::slugify is Total — No Panic for Any **ASCII** &str Input`" (`vp-001-slug-total.md:38`); Property Statement "For all **ASCII** string inputs `s` of length **0..=16 bytes**" (`:42`); Proof Method "bounded — input length 0..=16 bytes, **ASCII only**" (`:64`); with an explicit rationale for the restriction at `:66-74` ("Symbolic execution over arbitrary UTF-8 … causes CBMC model-count explosion") that defers Unicode coverage to VP-012. The BC's phrasing "for any input" deletes both qualifiers — and non-ASCII input is not incidental here: PC6 (`:64`) requires `## 日本語` → `"日本語"`, and EC-045 (`:89`) is a CJK heading.

**VP → BC dangling anchor.** VP-001's Source Contract (`:56`) cites "**PC1** — `compute_slug` is a total function defined for all `&str` inputs; it never panics." VP-002's (`:44`) cites "**PC2** — `compute_slug` is deterministic; CAP-006 requires slug stability across runs." Neither postcondition exists in BC-2.06.001. Its PC1 (`:49-56`) is the five-step algorithm; its PC2 (`:57-58`) is "For any heading with at least one character surviving steps (b)–(d), the slug is a non-empty string." The BC contains **no** totality postcondition and **no** determinism postcondition anywhere.

**Predicate:** `Grep "ASCII|0\.\.=16|bounded" .factory/specs/verification-properties/vp-001-slug-total.md` → the ASCII/16-byte bound is stated at `:38`, `:42`, `:64`, `:66-74`, `:81-87`, `:102`. `Grep "total|panic|determinis" .factory/specs/behavioral-contracts/ss-06/BC-2.06.001.md` → 1 match, the VP-row text at `:110`; zero in the Postconditions or Invariants sections.

**Consequence:** Both P0 Kani proofs for the product's highest-risk module hang off postcondition IDs that do not exist, so no gate can validate the join in either direction (POLICY 4/5). The BC simultaneously overstates VP-001's reach to unbounded Unicode — which matters because the VP that *does* cover unbounded Unicode (VP-012) is missing from the BC entirely (see P7-S2-015). Net effect: BC-2.06.001 claims unbounded-input totality while listing only a proof bounded to 16 ASCII bytes.

---

### P7-S2-015 — BC-2.06.001 omits VP-012, which both VP-INDEX and VP-012's own frontmatter assign to it [HIGH]

`BC-2.06.001.md:107-114` lists five rows: VP-001, VP-002 ×2, VP-018, VP-026. **VP-012 is absent.**

VP-INDEX assigns it: `VP-INDEX.md:186` — `| BC-2.06.001 | github-slugger v2 core algorithm | VP-001, VP-002, VP-012, VP-018, VP-026 | totality + determinism + **fuzz** + worked examples + differential oracle |`. VP-012's own body agrees: `source_bc: BC-2.06.001` (`vp-012-slug-fuzz.md:14`), `module: slug`, `proof_method: fuzz`, Source Contract "**BC:** BC-2.06.001 — Slug Computation Algorithm" (`:42`). VP-012 is the unbounded-Unicode complement to VP-001 by design: `vp-001-slug-total.md:73-74` — "Extended Unicode coverage is provided by **VP-012** (cargo-fuzz)"; `vp-012:38` — "This extends VP-001's Kani-bounded proof to unbounded input lengths and adversarial UTF-8 constructions."

The v1.5 remediation touched this exact table and missed it. `BC-2.06.001.md:27` claims a "Proof-method join … (all per VP-INDEX authority)" — it corrected four methods but did not add the fifth row VP-INDEX lists.

**Predicate:** `Grep "^\| VP-" .factory/specs/behavioral-contracts/ss-06/BC-2.06.001.md` → 5 rows: VP-001, VP-002, VP-002, VP-018, VP-026. `Grep "VP-012" .factory/specs/behavioral-contracts` → 0 matches in any BC file. VP-INDEX per-module count for `slug` includes Fuzz=1 (`VP-INDEX.md:108`), so the fuzz target is counted in the totals but claimed by no BC.

**Consequence:** POLICY 9 propagation failure with a live coverage hole. Story-writers back-fill acceptance criteria from the BC body, not VP-INDEX (`VP-INDEX.md:126-127` states the product-owner uses the BC-to-VP table "to back-fill the VP columns in BC files" — one direction only). With VP-012 unlisted, no story commissions `fuzz/fuzz_targets/fuzz_slug.rs` (`vp-012:54`), so the only unbounded-Unicode/adversarial-UTF-8 vehicle for the CRITICAL-tier `slug.rs` module is never built — while BC-2.06.001's VP-001 row (P7-S2-014) simultaneously advertises unbounded totality coverage.

---

### P7-S2-016 — 11 of the 12 edge-case IDs cited by the two SS-06 BCs denote entirely different scenarios in the canonical test-vector registry [CRITICAL]

`test-vectors.md` is the canonical EC registry (asserted by `check-ec-injectivity.py:9` and by BC-2.06.001's own v1.4 changelog, `:26`, "canonical owner … per test-vectors.md registry"). Every EC ID in the SS-06 Edge Cases tables was joined against it:

| Cited in | BC's description | `test-vectors.md` says | |
|---|---|---|---|
| `BC-2.06.001.md:87` EC-043 | `## Hello World` | `:128` TV-043 = `## AI & Automation` → `#ai--automation`, clean | ✗ |
| `:88` EC-044 | `## C++ Guide` | `:129` TV-044 = `## AI & Automation` → `#ai-automation`, **broken** | ✗ |
| `:89` EC-045 | `## 日本語` | `:130` TV-045 = `## Integrations - Growth` (triple hyphen) | ✗ |
| `:90` EC-046 | `## **Bold** Heading` | `:131` TV-046 = `## Phase 1: MVP (128 Features)` | ✗ |
| `:91` EC-047 | `## A  B` (two spaces) | `:132` TV-047 = `## Setup` ×2, 0-based counter | ✗ |
| `:92` EC-048 | `##` (empty heading) | `:133` TV-048 = `## Setup` ×3 → `-2` | ✗ |
| `:93` EC-059 | `## 🦀Rust` (emoji adjacent) | `:144` TV-059 = `Setext Title\n=====` | ✗ |
| `:94` EC-190 | `## 🦀Rust` then `## 🎯Rust` | `:425` TV-190 = same | ✓ |
| `BC-2.06.002.md:76` EC-055 | `## Setup` × 2 | `:140` TV-055 = `## Done ✅` (emoji stripped) | ✗ |
| `:77` EC-056 | `## Setup` ×2 + `## Setup 1` | `:141` TV-056 = `## **Bold** Heading` | ✗ |
| `:78` EC-057 | `## Setup` × 3 | `:142` TV-057 = `` ## `code` heading `` | ✗ |
| `:79` EC-058 | `## A` × 4 | `:143` TV-058 = `## [Link](x.md) heading` | ✗ |

The BCs' *intended* scenarios do exist in the registry, under different IDs: BC-2.06.002's EC-055/056/057 content corresponds to TV-047 (`## Setup` ×2), TV-049 (`Foo` ×2 then `Foo-1`, DEC-001), and TV-048 (`## Setup` ×3). This is a wholesale off-by-N ID drift, consistent with a registry renumbering that never propagated to the SS-06 BC bodies (POLICY 1).

The contrast with the rest of the shard is total: all 30 EC references in SS-03 and SS-04 join correctly (EC-039/040/113/115; EC-095/098/099/100/101/202; EC-096/097; EC-116/117; EC-173-177; EC-120/112; EC-103/104/105/108/109; EC-106/110/111; EC-065 — verified against `test-vectors.md:117,118,218,220,201,204,205,206,207,437,202,203,221,222,389,390,391,392,393,225,217,208,209,210,213,214,211,215,216,150`).

**Predicate:** `Grep "^\| EC-" .factory/specs/behavioral-contracts/ss-06` → 12 rows total (8 in `BC-2.06.001.md`, 4 in `BC-2.06.002.md`). Each of the 12 was joined to its `test-vectors.md` row by direct read of lines 128-145 and 425. Result: 1 match (EC-190), 11 mismatches.

**Consequence:** Every SS-06 edge case except one points a test-writer at the wrong scenario. Most damaging: BC-2.06.001, the BC that owns the slug algorithm, labels the FM-001 flagship differentiator pair (TV-043/TV-044, `## AI & Automation` → `ai--automation` vs the WRONG `ai-automation`) as "`## Hello World`" and "`## C++ Guide`". A story built from BC-2.06.001's Edge Cases table therefore never writes the hyphen-run test — which, combined with P7-S2-013 (VP-002 falsely credited with trap T1) and P7-S2-015 (VP-012 missing), leaves DI-012 rule 3 with **no** coverage reachable from the BC body. Symmetrically, BC-2.06.002's four EC IDs all point at slug-character vectors rather than the duplicate-counter vectors it contracts, so the 0-based-counter FM-002 discriminator (`invariants.md:361-371`) is unreachable from the BC that owns it.

---

### P7-S2-017 — BC-2.06.001's v1.4 changelog records a false canonical owner for EC-060, and that false rationale is why the sibling EC-059 collision was not caught [MEDIUM]

`BC-2.06.001.md:26` (v1.4): "(EC-collision) EC-060→EC-190 (**EC-060 canonical owner is BC-2.08.001** per test-vectors.md registry)."

The registry says otherwise. `test-vectors.md:145`: `| TV-060 | EC-060 | a.md | ####### seven hashes | [x](#seven-hashes) | 1 | broken | 7 hashes is not a heading (CommonMark: ATX must be 1-6) |` — a heading-recognition vector in SS-05 (`anchor_table` / ATX heading extraction, BC-2.05.002), not an anchor-resolution vector in SS-08. The registry's own TV-190 note contradicts the changelog directly: `test-vectors.md:425` — "Formerly EC-060 in BC-2.06.001; **EC-060 owned by TV-060 (7-hash non-heading)**".

The remediation therefore fixed one ID by citing the registry incorrectly, and did not re-scan the sibling rows in the same table — leaving EC-059 (also collided, with TV-059's Setext-heading vector) and five more (see P7-S2-016) in place.

**Predicate:** `Grep "EC-060" .factory/specs` → 3 matches: `BC-2.06.001.md:26` (claims BC-2.08.001), `test-vectors.md:145` (TV-060 = 7-hash), `test-vectors.md:425` (says TV-060). Zero occurrences of EC-060 in any SS-08 BC.

**Consequence:** The changelog is the audit record a subsequent reviewer or the orchestrator reads to confirm a fix landed. Recording a false canonical owner makes the fix look verified against the registry when it was not, and it is the direct process cause of P7-S2-016's survival — the same remediation pass had the registry open and would have seen EC-059/EC-055-058 had the join been real. Partial-fix propagation defect (hunt item 8): the primary fix landed, the sibling scan did not, and the rationale that would have triggered the sibling scan is wrong.

---

### P7-S2-018 — BC-2.06.002 claims Kani VP-003 proves "correct slugs", the exact exact-value property DI-013 and VP-026 state VP-003 cannot prove [CRITICAL]

`BC-2.06.002.md:91`: `| VP-003 | Canonical triple-collision case produces **correct slugs** | kani |`

VP-003 proves distinctness, never values. Its three Kani harnesses (`vp-003-slug-duplicate-uniqueness.md:80-155`) assert only `assert_ne!` (`:103`, `:129`) and termination (`:141-155`). Its title is "DuplicateCounter Injectivity — No Two Distinct Slugs After Dedup" (`:40`). The only exact-value fixture in the file is a plain `#[test]` unit test at `:161-173`, not a Kani proof — and its v1.2 changelog (`:29`) records that the Setup/Setup/Setup-1 triple was deliberately **replaced** with `Init/Init/Init 1` "to avoid leaking acceptance holdout vectors", so VP-003 does not even contain the canonical triple BC-2.06.002 names.

Three independent artifacts state the impossibility explicitly:
- `invariants.md:363-366` (DI-013 Falsifying method): "**VP-003 (Kani injectivity proof) proves no two outputs are equal but CANNOT detect the 1-based vs 0-based counter bug** — injectivity is satisfied by both (`setup`, `setup-1`, `setup-2`) and (`setup`, `setup-2`, `setup-3`)."
- `vp-026-slug-differential-fidelity.md:54-57` and `:215-220`: "**Why VP-003 cannot close FM-002** … Only an oracle comparison with the exact expected values catches the off-by-one."
- `vp-018-slug-worked-examples.md:181-185`: "WHY THIS TEST CLOSES FM-002 WHEN VP-003 CANNOT."

"Produces correct slugs" is precisely the exact-value claim. As with P7-S2-013, this was introduced by the v1.4 join repair (`BC-2.06.002.md:26`: "both VP-003 rows 'unit test' → 'kani' … per VP-INDEX authority"), which copied the method column without reading the property.

**Predicate:** `Grep "assert_eq!|assert_ne!" .factory/specs/verification-properties/vp-003-slug-duplicate-uniqueness.md` → `assert_ne!` at `:103`, `:129` (both inside `#[kani::proof]`); `assert_eq!` at `:170`, `:171`, `:172` (all inside the non-Kani `#[test] fn vp003_collision_bump`). No `assert_eq!` appears in any Kani harness.

**Consequence:** FM-002 (the 1-based/0-based counter off-by-one) is the single failure mode this corpus identifies as invisible to injectivity, and BC-2.06.002's VP table asserts a **P0 Kani proof** covers it. A gate joining BC VP tables against VP-INDEX (`VP-INDEX.md:187` correctly qualifies it as "Kani injectivity + proptest 0-based counter oracle") sees `VP-003 | kani | P0` and reports formal coverage of the collision case. The only artifact that can actually catch FM-002 is VP-026, which is P1 with unbuilt Phase-3 oracle fixtures (`vp-026:492-510`). If VP-026 slips, `## Setup`/`## Setup`/`## Setup 1` can ship producing `setup`/`setup-2`/`setup-2-1` behind a green P0 signal, failing EC-056 and TV-049 (`test-vectors.md:134`).

---

### P7-S2-019 — BC-2.06.002 Invariant 1 (per-file counter reset) is claimed as Kani-proved by VP-003, which never models it; no VP, EC, or TV covers it anywhere in the corpus [HIGH]

`BC-2.06.002.md:92`: `| VP-003 | Counter reset between files | kani |`, backing Invariant 1 at `:69`: "The counter is per-file; it resets for each new file."

VP-003 contains nothing about files. All three harnesses (`vp-003:80-155`) construct a single `DuplicateCounter::new()` and call `compute_slug` within one scope; none models two files, two counters, or a reset. Nor could it: `api-surface.md:72-74` shows `compute_slug(text: &str, counter: &mut DuplicateCounter)` and `DuplicateCounter::new()` take no path, so per-file lifecycle is entirely the **caller's** responsibility — `module-decomposition.md:109-114` shows the per-file loop in Pass 1. It is an `anchor_table`/`app` property, not a `slug` property, so no `module: slug` VP can carry it.

Nothing else in the corpus covers it either. There is no EC, no TV row, and no VP-026 oracle run for cross-file counter isolation — VP-026's oracle groups entries into "runs" that "model the per-file duplicate-counter lifecycle" (`vp-026:82`, `:311`) but every run starts a fresh counter by construction, so it can never observe a *leak* between runs.

**Predicate:** `Grep -i "counter (is )?per-file|per-file counter|counter reset|resets for each|reset between files" .factory/specs` → 4 matches across 3 files: `entities.md:41` (glossary gloss "0-based per-file counter"), `vp-026:311` (a code comment), and `BC-2.06.002.md:69` + `:92` — i.e. the invariant and its own coverage claim are the only substantive occurrences in the entire corpus.

**Consequence:** A real, testable invariant with a direct false-positive failure mode — a counter leaking across files makes the first `## Setup` in file B slug to `setup-1`, so every `[x](b.md#setup)` in the repo reports `anchor-not-found` — is claimed as discharged by a P0 Kani proof that does not model it, and has no other vehicle. The property is architecturally unprovable at the `slug` module, so the claim can never be honoured without relocating it; meanwhile the coverage table reports it green.

---

### P7-S2-020 — PRD RTM Proof Method column is stale against VP-INDEX for all 11 rows in this shard [MEDIUM]

`prd.md:434-447` carries a "Proof Method"-style final column for each BC. Joined against VP-INDEX for the 11 bodies in scope:

| PRD row | PRD says | VP-INDEX / BC body says |
|---|---|---|
| `:434` BC-2.03.001 | `unit` | VP-019 proptest P1 + VP-014 integration (`VP-INDEX.md:75,70,159`; BC `:73-74`) |
| `:435` BC-2.03.002 | `unit` | VP-019 proptest (`VP-INDEX.md:160`; BC `:89-90`) |
| `:436-439` BC-2.03.003/004/005/006 | `unit` | test-sufficient (`VP-INDEX.md:161-164`) |
| `:440` BC-2.04.001 | `unit/property` | VP-014 **integration** (`VP-INDEX.md:70,170`; BC `:76-77`) |
| `:441` BC-2.04.002 | `unit` | VP-014 integration (`VP-INDEX.md:171`; BC `:69-70`) |
| `:442` BC-2.04.003 | `unit` | VP-014 integration (`VP-INDEX.md:172`; BC `:95-96`) |
| `:446` BC-2.06.001 | `unit/property` | VP-001 **kani** + VP-002 **kani** + VP-012 **fuzz** + VP-018 unit + VP-026 proptest (`VP-INDEX.md:186`) |
| `:447` BC-2.06.002 | `unit` | VP-003 **kani** + VP-026 proptest (`VP-INDEX.md:187`) |

The WS-4-B sweep repaired the BC-side method labels (recorded in the v1.3/v1.4/v1.5 changelogs of BC-2.03.001, .002, BC-2.04.001, .002, .003, BC-2.06.001, .002) but did not propagate to the PRD's RTM. `VP-INDEX.md:42-48` declares that any change to proof method "MUST propagate to" three architecture targets; `prd.md` is not on that list, which is why the drift survives.

**Predicate:** 11 of 11 rows in scope diverge from VP-INDEX; 0 agree. Verified by direct read of `prd.md:434-447` against `VP-INDEX.md:57-82` and `:159-187`.

**Consequence:** POLICY 9/17 drift. The PRD RTM is the highest-level traceability surface and understates the verification tier for every BC in this shard — most consequentially BC-2.06.001, whose two P0 Kani proofs and one fuzz target are summarised as "unit/property". A reader planning Phase-6 formal-verification effort from the PRD sees no Kani obligation in SS-06 at all. Primary artifact is `prd.md`, but the defect is only visible by joining the 11 shard-2 BC VP tables against it.

---

### P7-S2-021 — `check-ec-injectivity.py` structurally cannot detect BC↔registry scenario divergence, yet emits a positive-coverage "all injective" assertion [HIGH]

`check-ec-injectivity.py` is the declared enforcement for EC injectivity ("POL-16 (the big one)", `:3`; "The canonical EC registry is test-vectors.md", `:9`). It cannot detect P7-S2-016, for two independent reasons:

1. **BC-vs-registry description comparison is explicitly skipped.** `:191-194`:
   ```python
   # Description collision: across BC files, independent of verdict column presence.
   # BC descriptions are expected paraphrases of TV descriptions (TV captures the
   # canonical input-file name, not a scenario description), so BC-vs-TV is skipped.
   if len(bc_occs) > 1:
   ```
   `bc_occs` excludes `test-vectors.md` (`:183`). Each SS-06 EC ID appears in exactly **one** BC file plus the registry, so `len(bc_occs) == 1` and the entire description-collision block (`:194-215`) never executes. The check only ever compares BCs to each other.

2. **The verdict-collision branch is dead for BC Edge Cases tables.** `:221-222` skips any BC row whose verdict cell is empty. BC-2.06.001 and BC-2.06.002 use 2-column tables (`| EC | Description |`, `:86` / `:74`), so `rest_cells` has length 1 and `verdict_raw = ""` (`:126-127`). BC-2.04.001 has a 3-column table (`| EC | Description | Notes |`, `:58`) but all five Notes cells are empty and empty cells are filtered at `:123`, again yielding `verdict_raw = ""`. So verdict comparison is skipped for every Edge Cases table in this shard.

With both branches unreachable, the script reaches `:258-261` and prints `Check passed: {total_ec_ids} EC IDs validated — all injective ({multi_occurrence} appear in multiple files but are consistent)`. The count is runtime-computed, so it satisfies POLICY 11's arithmetic form — but it counts **IDs scanned**, not comparisons performed. The parenthetical "**but are consistent**" is an affirmative claim about exactly the pairs the code never compares.

**Predicate:** `Grep "^\| EC-" .factory/specs/behavioral-contracts/ss-06` → 12 rows, each appearing in exactly 1 BC file → `len(bc_occs) == 1` for all 12 → branch at `:194` never taken. All 12 rows are in 2-column tables → `verdict_raw == ""` → branch at `:222` `continue` for all 12. Zero of the 11 mismatches in P7-S2-016 are reachable by this checker.

**Consequence:** The single highest-yield mis-anchoring class in this corpus — a BC citing a real, resolvable EC ID that denotes a different scenario in the canonical registry — has an enforcement script that reports green while being structurally blind to it. This is the D-057 pattern falsified twice before on this project (the `VP-TBD` grep defeated by an em-dash; the ID resolver silently skipping non-conforming shapes), recurring a third time: the check exists, has a self-test fixture (`selftest/fixtures/bad-ec-injectivity.md`), and passes — but the shape actually present in the corpus (1 BC + 1 registry row, 2-column table) hits neither code path. Any pass that treats EC anchoring as checker-covered will miss all 11 defects.

**Tag:** [process-gap]

---

## Lower-severity items

### P7-S2-022 — BC-2.04.001 v1.4 removed the TV-BV013 row but left the Notes column added solely to hold it, and the changelog is out of chronological order [LOW]

`BC-2.04.001.md:26` (v1.3): "Edge Cases table: added Notes column header to accommodate pre-existing TV-BV013 3-cell row". `:23` (v1.4): "TV-BV013 row removed from Edge Cases table". The Notes column survives with five empty cells (`:58-64`), which is also what defeats the verdict branch of `check-ec-injectivity.py` for this file (see P7-S2-021). Separately, the `modified:` list is out of order — v1.4 at `:23` precedes v1.1/v1.2/v1.3 at `:24-26`, whereas every other body in the shard is chronological.

**Predicate:** `Grep "TV-BV013" .factory/specs/behavioral-contracts/ss-04/BC-2.04.001.md` → 1 match, in the changelog at `:26`; 0 in the Edge Cases table.

**Consequence:** Residual partial-fix artifact. The vestigial column is what makes the row shape unparseable by the verdict branch of the injectivity checker; the out-of-order changelog undermines the changelog as an audit trail.

### P7-S2-023 — Both SS-06 bodies omit the `Stories` Traceability row that all nine SS-03/SS-04 bodies carry [LOW] (pending intent verification)

`BC-2.06.001.md:116-123` and `BC-2.06.002.md:95-102` end their Traceability tables at `Architecture Module`. All six SS-03 and all three SS-04 bodies carry `| Stories | [filled by story-writer] |` (e.g. `BC-2.03.001.md:84`, `BC-2.04.003.md:106`).

**Predicate:** `Grep "^\| Stories \|" .factory/specs/behavioral-contracts` → 24 of 66 BC files. Within this shard: 9 of 11 present (all SS-03 + all SS-04); the 2 absentees are both SS-06 bodies. Corpus-wide the majority (42/66) lack the row, so absence may be the intended convention and SS-03/SS-04 the outliers.

**Consequence:** Within-shard template inconsistency. Since the recent `d4e76fa` commit introduced a "Stories-field `[filled by]` exemption" in the placeholder checker, the intended convention is ambiguous and cannot be adjudicated by the adversary. Tagged pending intent verification per the partial-fix discipline rule; the orchestrator should rule on whether the row is required.

---

## Verified clean in this shard (negative results, for the record)

- **Reason-code closure (POLICY 19):** all reason codes cited in the 11 bodies — `undefined-reference-definition` (`BC-2.03.003.md:53`, `:73`; `BC-2.03.002.md:83`), `file-not-found` (`BC-2.03.001.md:67`; `BC-2.03.003.md:58`), `anchor-not-found` (`BC-2.04.003.md:65`, `:83`) — appear verbatim in the closed 13-code set at `error-taxonomy.md:99-102`. **No phantom codes.** Predicate: 3 distinct codes cited, 3 present verbatim in the closed set.
- **POLICY 13 (PRD §2.x title ↔ BC H1):** all 11 titles match character-for-character. `prd.md:136-141` vs BC H1s at `BC-2.03.001.md:34`, `.002:35`, `.003:34`, `.004:34`, `.005:34`, `.006:33`; `prd.md:151-153` vs `BC-2.04.001.md:35`, `.002:34`, `.003:34`; `prd.md:175-176` vs `BC-2.06.001.md:36`, `.002:35`. 11/11 exact.
- **POLICY 5 (quoted-excerpt substantiation):** every quoted Traceability excerpt in the 11 bodies verified verbatim against source. `BC-2.03.001.md:79` "extract all links (inline, reference-style, collapsed, shortcut, image) that fall outside code contexts" = `capabilities.md:75-76` exact. `BC-2.03.002.md:95` = verbatim prefix of same. `BC-2.04.002.md:75` "indented code blocks (4-space), HTML \`<pre>\`/\`<code>\`, HTML comments" = `capabilities.md:88-89` exact, backticks preserved. `BC-2.06.001.md:80` DI-012 rule 1 quote "HTML tags contribute nothing (tag tokens are stripped; their visible text content, if any, is retained)." = `invariants.md:297-299` exact. All `("Link Extraction")` / `("Code Context Exclusion")` / `("Heading Slug Computation")` title quotes = `capabilities.md:73, 85, 114` exact. Glosses are correctly outside quotation marks in every case. **Zero fabrications found** — the WS-4-B citation-authority repairs recorded in the v1.3/v1.5 changelogs of BC-2.03.003/.004/.005, BC-2.04.001, BC-2.06.001/.002 did land correctly. Predicate: 22 quoted excerpts across 11 bodies, all 22 verified verbatim.
- **SS-03/SS-04 EC anchoring:** 30 of 30 EC references join correctly to `test-vectors.md` (enumerated in P7-S2-016).
- **BC-2.06.002 postcondition arithmetic:** PC1-PC4 (`:50-66`) hand-traced against DD-015 step 5 (`decisions.md:93`) and DI-013 (`invariants.md:343-359`) for all three document orders. All three produce the stated slugs. `## Setup` ×3 → `setup`/`setup-1`/`setup-2`; Setup×2+Setup-1 → `setup`/`setup-1`/`setup-1-1`; Setup-1-first → `setup-1`/`setup`/`setup-2`. Internally sound and consistent with `test-vectors.md:134` (TV-049) and `vp-018:159-169`.
- **BC-2.03.004 library claims:** `LinkType::Autolink` / `LinkType::Email` are real pulldown-cmark enum variants; the GFM bare-URL non-support claim is corroborated at `ADR-003-pulldown-cmark.md:52,67`, `tooling-selection.md:118`, `decisions.md:87` (DD-009), and `product-brief.md:92`. Consistent throughout; no defect found.
- **Code fences (hunt item 7):** `Grep '```rust' .factory/specs/behavioral-contracts` → **0 matches across 0 files**. No BC in the corpus contains a Rust fence, so there are no fenced-symbol resolution defects; the symbol defects found (P7-S2-011) are in prose and Acceptance-Criteria table cells instead, which is why they escaped notice.

## Novelty Assessment

Findings are substantive, not refinements. The dominant new pattern is a **systematic false-green class introduced by the WS-4-B "proof-method join repair"**: five separate VP-table rows across BC-2.03.002 (×2), BC-2.06.001 (×2), and BC-2.06.002 (×2) had their Proof Method column upgraded from an honest "unit test" to a named formal tool (`proptest` / `kani`) by copying VP-INDEX's *method* column without reading the target VP's *Property Statement*. In four of those cases the target VP explicitly disclaims the property in its own body, and in two cases (`invariants.md:363-366`, `vp-026:54-57`) a third artifact states the impossibility in so many words. That class of defect is invisible to `check-counts.py` (methods agree with VP-INDEX) and to any ID-resolution check (all VP IDs resolve) — it is only reachable by reading each VP body in full and comparing semantics, which is what this shard's assignment mandated.

The second new pattern is **unpinned third-party configuration**: the corpus makes eleven distinct behavioural claims about `pulldown-cmark` across SS-03/SS-04 while never once naming an `Options` flag (0 grep matches), and two of those claims (BC-2.03.003's callback contract, BC-2.03.006's footnote exclusion) are inverted or option-dependent in ways that flip an exit code. No checker can reach this class, and the inverted callback claim has already propagated into `prd.md` and `purity-boundary-map.md`, so it will not be fixed by a single-file edit.

Third, the EC mis-anchoring in SS-06 (11 of 12) is a large, mechanical, high-blast-radius defect that has an enforcement script pointed directly at it (`check-ec-injectivity.py`) which is structurally blind to the shape present. That the same shard is clean at 30/30 for SS-03/SS-04 confirms this is localised drift rather than a global convention question — and confirms the checker gap is what let it persist.

Novelty: **HIGH** — nine CRITICAL findings, at least four of which (P7-S2-013, P7-S2-018, P7-S2-016, P7-S2-021) could not be reached by any prior axis that did not read every cited VP body in full and join every EC ID against the registry. This pass does **not** count toward a clean-pass streak.