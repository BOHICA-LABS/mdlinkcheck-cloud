---
document_type: adversarial-review
level: ops
version: "1.0"
status: final
producer: adversary
phase: phase-1d
pass: 4
frozen_head: d08021e4af055885fdd4b1898ce4dc9a426fa393
verdict: FINDINGS_REMAIN
findings_total: 37
findings_critical: 3
findings_major: 19
findings_minor: 15
project: mdlinkcheck-cloud
---

I have enough evidence. One note before the report: my tool profile is read-only, so I could not write to `.factory/cycles/phase-1d/adversary-pass-4.md` — the full report follows for the orchestrator to persist.

---

# Adversarial Review — Phase 1d — PASS 4

**Frozen HEAD reviewed:** `d08021e4af055885fdd4b1898ce4dc9a426fa393` (`factory-artifacts`)
**Perimeter:** whole-spec-package (Phase-1 spec review)
**Policy registry read:** `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/policies.yaml` — all 19 policies confirmed present (POL-1..POL-19), applied below.
**Seven mechanically-enforced classes:** deliberately skipped. Zero findings below are title-sync, EC-injectivity, ID-resolution, count/tally, holdout-leakage, ADR-exit-code, or index-bidirectionality. Two findings touch validator *behaviour* rather than these classes and are marked `[process-gap]`.

---

## Critical Findings

### P4-001 — CRITICAL — `## \`code\` <em>text</em>`: BC-2.06.001 says the HTML element's text is DISCARDED; DI-012 and both new BI-005 golden vectors say it is RETAINED. Three artifacts, two irreconcilable expected outputs, on the product's headline differentiator.

**Files / lines:**
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-06/BC-2.06.001.md:73-76`
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/invariants.md:259-263`
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-018-slug-worked-examples.md:109-116`
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-026-slug-differential-fidelity.md:132`, `:140-150`

**Defect.** BC-2.06.001 Invariant 2 states:

> **HTML elements:** NEITHER the tag markup NOR the text content inside HTML elements contributes to the rendered text. A heading `## <kbd>Ctrl+C</kbd>` yields rendered text `""` (empty).

BC-2.06.001's own v1.1 changelog (line 23) makes this deliberate: *"clarified Invariant 2 — code-span TEXT is included in rendered text; HTML element text is NOT included."*

DI-012 rule 1 (`invariants.md:260-263`) states the opposite:

> Inline-code spans contribute their text content. HTML tags contribute nothing (tag tokens are stripped; **their visible text content, if any, is retained**).

Both vectors landed in this burst assume RETAINED:
- VP-018:109-116 — source `## \`code\` <em>text</em>` → rendered `"code text"` → expected `"code-text"`.
- VP-026:132 / :144-146 — source `## \`config\` API <em>new</em>` → rendered `"config api new"` → expected `"config-api-new"`.

Under BC-2.06.001 Invariant 2 the same inputs yield rendered `"code "` → slug `"code-"` and rendered `"config API "` → slug `"config-api-"`. **Divergent expected outputs for the same input**, and BC-2.06.001 is the declared `source_bc` of *both* VPs (`vp-018:15`, `vp-026:14`). Applying DI-012 rule 1 to BC-2.06.001's own worked example gives `## <kbd>Ctrl+C</kbd>` → `"ctrlc"`, not `""`.

**Why it matters.** GitHub-fidelity slug generation is the product's stated headline differentiator (`module-criticality.md:50`, R-001/R-002). An implementer building `slug`/`anchor_table` from the BC produces one algorithm; the test-writer building VP-018/VP-026 golden vectors produces the opposite oracle. Phase 3 stalls with a test suite that cannot pass against a BC-conformant implementation. Worse, whichever side wins, the losing behaviour becomes a permanent false-positive/false-negative class on every heading containing inline HTML — a very common pattern (`<kbd>`, `<em>`, `<sup>`, `<a name=...>`). Note that `test-vectors.md:284` (TV-S015, `## Foo <a name="bar"></a>` → `foo-`) does **not** adjudicate this: that element has no text content, so it is consistent with both readings. There is no vector anywhere in the canonical registry that discriminates.

**Recommended fix.** Adjudicate against the actual pipeline. Under ADR-003 (pulldown-cmark), `## \`code\` <em>text</em>` emits `Code("code")`, `Text(" ")`, `InlineHtml("<em>")`, `Text("text")`, `InlineHtml("</em>")` — so "retain visible text, drop tag tokens" (DI-012) is the cheap, natural implementation and matches rehype-slug/HAST behaviour. Recommend: (a) amend BC-2.06.001 Invariant 2 to match DI-012 rule 1 verbatim, replacing the `## <kbd>Ctrl+C</kbd>` → `""` example with `## <kbd>Ctrl+C</kbd>` → `"ctrlc"`; (b) add the discriminating vector to `test-vectors.md` §7 as a new TV-S row (see P4-017); (c) record the adjudication as a DD entry so a future pass cannot silently re-flip it.

---

### P4-002 — CRITICAL — VP-025 was authored against an imaginary API: `AnchorTable` type, `resolve_anchor` return type, and its central "closed enum" property all contradict `api-surface.md`. The harness cannot compile and the property it proves is false against the declared API.

**Files / lines:**
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/api-surface.md:77`, `:92`, `:120`
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-025-anchor-resolver-totality.md:39`, `:55-56`, `:94`, `:133-134`, `:155`, `:161-163`
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/bc-module-map.md:391`
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/module-criticality.md:52`

**Defect.** Four mutually incompatible declarations of the same CRITICAL-tier type and function:

| Artifact | `AnchorTable` | `resolve_anchor` returns |
|---|---|---|
| `api-surface.md:77`, `:92`, `:120` | `pub struct AnchorTable(HashSet<String>)` in `anchor_table.rs` | `Verdict` = `{ Clean, Broken(FailureReason), Indeterminate(FailureReason) }` |
| `vp-025.md:94`, `:39`, `:134` | `HashMap<String, usize>` (slug → line number) in `types.rs` | `AnchorVerdict` |
| `bc-module-map.md:391` | `HashMap<String, usize>` | — |
| `module-criticality.md:52` | "heading-slug to **line-number** lookup" | — |

VP-025's property 4 (lines 55-56) is the load-bearing claim:

> **Closed enum**: Every result is exactly Hit or Miss. There is no Indeterminate or panic exit path.

Against `api-surface.md:92`+`:120`, `resolve_anchor` returns the three-variant `Verdict`, which **does** include `Indeterminate`. VP-025's totality harness (lines 161-163) is:

```rust
match result {
    AnchorVerdict::Hit | AnchorVerdict::Miss => {},
}
```

— a non-exhaustive `match` on a three-variant enum: `error[E0004]`. `AnchorVerdict`, `Hit`, `Miss`, and `AnchorTable::from_map` appear nowhere in `api-surface.md`. VP-025:127-129 waves this off ("*replace ... with the actual names from types.rs once the implementer finalises the API*") — but `api-surface.md` **is** the finalised API (v1.3, listed in `ARCH-INDEX.md:33` as the source for test-writer and implementer). Additionally `AnchorTable` is declared in `anchor_table.rs`, not `types.rs` as VP-025:134 imports it.

Finally, VP-025's entire Kani-infeasibility rationale (lines 92-101) — the justification for rejecting formal proof on a CRITICAL-tier module — is built on `AnchorTable` being a `HashMap` with SipHash-1-3 bucket layouts. If it is `HashSet<String>` per `api-surface.md:77`, the stated premise is factually wrong.

**Why it matters.** VP-025 exists solely to close INC-MAP-001 ("anchor_resolver has 0 formal VPs despite CRITICAL tier"), and `bc-module-map.md:386` marks that gap **RESOLVED**. The gap was closed with a specification that (a) will not compile, (b) asserts a closed two-variant enum against a declared three-variant return type, and (c) justifies skipping Kani on a type the architecture does not declare. `anchor_resolver` is the direct consumer of the anchor table for *every* heading link — the exact surface where lychee #1457/#1613/#1709 and Sphinx #13620 have open bugs (VP-025:68-71). Furthermore, if `AnchorTable` genuinely is `HashSet<String>`, then `module-criticality.md:52`'s "heading-slug to line-number lookup" is unimplementable and nothing in the system can report *where* a duplicate/missing heading is.

**Recommended fix.** Architect must adjudicate the type in `api-surface.md` (the source of truth) and decide whether the anchor table carries line numbers. Then: rewrite VP-025's Property Statement, §Kani Infeasibility, and harness against the adjudicated signature; if `resolve_anchor` returns the three-variant `Verdict`, replace VP-025 property 4 with an explicit assertion that `Indeterminate` is **never** returned from anchor resolution (which is the genuinely valuable property, and is currently unverified anywhere). Re-open INC-MAP-001 until this lands.

---

### P4-003 — CRITICAL — `ARCH-INDEX.md` and `module-criticality.md` still describe a **two-pass** pipeline. The architecture is three-phase (Pass 1 → Pass 1.5 → Pass 2), and Pass 1.5 is the sole mechanism preventing the product's headline false-positive class.

**Files / lines:**
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/ARCH-INDEX.md:30`
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/module-criticality.md:52`, `:63`, `:98`, `:107`
- Contradicted by: `architecture/system-overview.md:31`, `:79-81`, `:100-140`; `domain-spec/invariants.md:126-183` (DI-006); `domain-spec/entities.md:54`; `prd.md:610`, `:654`

**Defect.** `system-overview.md:31` records the change explicitly: *"two-pass pipeline extended to three phases (Pass 1 -> Pass 1.5 -> Pass 2)"*, and `:79-81` states *"The three passes..."*. `prd.md:654` records the downstream correction: *"BC-2.05.001 H1 title corrected from 'Two-Pass Design' to 'Three-Phase Design'... DI-008 label in BC-INDEX updated from 'Two-pass:' to 'Three-phase (Pass 1 → Pass 1.5 → Pass 2)'."* `entities.md:54` adds Pass 1.5 to the glossary and points at "*system-overview.md §Three-Phase Pipeline*".

That propagation stopped short of the two documents story-writers and implementers read to scope work:

- `ARCH-INDEX.md:30` — `| System Overview | system-overview.md | all agents | Architecture vision, **two-pass pipeline**, concurrency |`
- `module-criticality.md:63` — `**app** — effectful: **two-pass** pipeline orchestration; coordinates scanner and http_client`
- `module-criticality.md:107` — `` `app` | MEDIUM | medium | none | medium (**two-pass** orchestration) | P2 ``
- `module-criticality.md:52` — `**anchor_table** — ... **two-pass** anchor table construction`
- `module-criticality.md:98` — `` `anchor_table` | CRITICAL | ... | high (HTML id/name, **two-pass** timing) | P0 ``

`module-criticality.md` was revised to **v1.5 in this very burst** (2026-08-06) and these four lines were not touched.

**Why it matters.** ARCH-INDEX is the mandated entry point for *all agents* (`ARCH-INDEX.md:23-24`: "*Agents load ONLY the section files they need*"), and its Document Map is the only description of `system-overview.md` many agents will see. An implementer scoping the `app` module from `module-criticality.md:63`/`:107` builds two passes and omits Pass 1.5 entirely. Per DI-006 (`invariants.md:173-178`), omitting Pass 1.5 causes *every* `[x](file.md#section)` link into a `.gitignore`d file, a dot-directory, or a path above the scan root to manufacture a false-positive `anchor-not-found` — **"the exact false-positive class the product exists to prevent."** Three canonical test vectors (`test-vectors.md:163-165`, TV-153/154/155) exist solely to catch this. Per the semantic-anchoring rubric this is CRITICAL: the mis-anchor would mislead an implementer into building the wrong thing.

**Recommended fix.** `ARCH-INDEX.md:30` → "three-phase pipeline (Pass 1 → Pass 1.5 → Pass 2)". `module-criticality.md:63`/`:107` → "three-phase pipeline orchestration (Pass 1 → Pass 1.5 → Pass 2)"; `:52`/`:98` → "three-phase". Add `app`'s Pass 1.5 responsibility to its Rationale cell explicitly, since `app` is the module that owns it (`system-overview.md:100`, `purity-boundary-map.md:77`). Secondary loci to sweep in the same commit: `domain-spec/event-flow.md:102-104` ("Two-Pass Constraint Detail" / "The two-pass constraint (DI-008)") and `gene-transfusion-assessment.md:199`, which quotes DI-008's title as *"Anchor Table Built Two-Pass"* — DI-008's actual title (`invariants.md:198`) is "Anchor Table Built Before Any Incoming Link Is Validated".

---

## Important Findings

### P4-004 — MAJOR — ADR-005's four-field sort key (`dest` tie-break) propagated to **zero** downstream artifacts. Five artifacts still specify the three-field key, and `dest` is not a field of `Finding`.

**Files / lines:**
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/decisions/ADR-005-rayon-sort-before-emit.md:13`, `:34-39`, `:62-63`, `:83-87`
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/invariants.md:50-51`
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/system-overview.md:150`, `:165-166`
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/api-surface.md:138`, `:117-119`
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-011-sort-deterministic.md:41`

**Defect.** ADR-005 v1.2 (2026-08-05) changelog line 13: *"made DI-001 sort key total by adding `dest` as 4th tie-break field — removes dependency on the unproven full-pipeline DI-005 guarantee."* ADR-005:34-39 and :62-63 mandate `(nfc_normalize(path), line, column, dest)` with `sort_unstable_by`.

Every other artifact still specifies three fields:

| Artifact | Line | Sort key |
|---|---|---|
| `invariants.md` (DI-001) | 50-51 | `(NFC-normalized file path, line number, column number)` |
| `system-overview.md` | 150 | `sort_unstable_by(NFC-path, line, col)` |
| `system-overview.md` | 165-166 | `(nfc_normalize(path), line, column)` |
| `api-surface.md` | 138 | `(NFC-file, line, column)` |
| `vp-011.md` | 41 | `sort_unstable_by_key(|f| (nfc_normalize(&f.path), f.line, f.col))` |

Additionally, `api-surface.md:117-119` declares `pub struct Finding { pub path, pub line, pub col, pub link_target, pub verdict, pub reason }`. **There is no `dest` field on `Finding`** — `dest` belongs to `ExtractedLink` (`api-surface.md:122`). ADR-005's normative sort key references a field on the wrong type.

**Why it matters.** `sort_unstable_by` is an *unstable* sort: for elements comparing equal, the resulting order is unspecified and can vary with input permutation, which under rayon varies with thread scheduling. DI-001 is the invariant with the only zero-tolerance target in the spec set (`nfr-catalog.md:77`: "100% — zero tolerance for nondeterminism"). ADR-005's whole reason for adding `dest` was to remove a soundness dependency; that change now exists in exactly one document, while the formal-verifier builds VP-011 from a three-field key and the implementer builds the pipeline from `system-overview.md:150`'s three-field key. Whichever they build, the *other* is wrong, and nobody is verifying the version ADR-005 accepted. POL-3/POL-4/POL-17 propagation failure with blast radius 5 → HIGH.

**Recommended fix.** Single commit: (a) rename the tie-break field in ADR-005 from `dest` to `link_target` to match `api-surface.md:117-119`; (b) update DI-001 (`invariants.md:50-51`) to the four-field key — it is the L2 authority and must lead; (c) update `system-overview.md:150` and `:165-166`, `api-surface.md:138`; (d) update VP-011's Property Statement (line 41) and both proptest harnesses to the four-field key.

---

### P4-005 — MAJOR — ADR-005's sort-key-totality argument rests on a BC-2.03.002 postcondition that does not exist; ADR-005 itself records this as an open action item while carrying `status: accepted`.

**Files / lines:**
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/decisions/ADR-005-rayon-sort-before-emit.md:4`, `:38-39`, `:83-85`, `:109`
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-03/BC-2.03.002.md:45-51`, `:22-24`

**Defect.** ADR-005:38-39: *"`sort_unstable_by` is safe because no two distinct findings can share all four fields when findings are reported at use-site positions (see BC-2.03.002 postcondition)."* ADR-005:83-85 repeats the dependency. ADR-005:109 then admits the postcondition is not written:

> BC-2.03.002: Reference-style link extraction — use-site finding position is required for sort key totality (**product-owner scope: add postcondition that findings are at use-site positions**)

BC-2.03.002's postconditions (lines 45-51) contain no use-site-position requirement; its invariants (53-56) do not either. Its modification log (lines 22-24) shows only `v1.1` VP-TBD backfill and `v1.2` Architecture-Module fill — the postcondition was never added.

**Why it matters.** This is the load-bearing soundness premise for DI-001 under an unstable sort. Reference-style, collapsed, and shortcut links (`[text][label]`, `[text][]`, `[text]`) are exactly the forms where an implementer may naturally attribute the finding to the `[label]: url` *definition* line rather than the *use* site — and BC-2.03.002 PC1-PC5 describe definition-table lookup without ever constraining the reported position. If two uses of the same label are reported at the definition site, all four sort fields collide and the emission order of those findings is unspecified. `status: accepted` on an ADR whose correctness argument cites a nonexistent postcondition means the Phase 1 gate signed off on an unclosed dependency. POL-16 (BC/ADR traceability resolution) — the reference resolves to a real BC, so `check-id-resolution` passes; the *claim about* that BC is false. This is precisely the routed item-3 class.

**Recommended fix.** Product-owner adds to BC-2.03.002 Postconditions: *"PC7. For all reference forms (full, collapsed, shortcut), the reported `Finding` position is the **use site** (the byte offset of the `[text]` span), never the `[label]: url` definition site."* Add a matching invariant and a canonical test vector (two uses of one label on different lines → two findings at distinct line numbers). Then delete the open action item from ADR-005:109 and add the closure to ADR-005's changelog.

---

### P4-006 — MAJOR — No harness anywhere implements DI-001's own falsifying method. VP-011's binary-output test compares two runs at the **same** thread count, and NFR-003 mandates an "identical environment" — which forbids the variation DI-001 requires.

**Files / lines:**
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-011-sort-deterministic.md:103-141` (esp. `:108`, `:118-119`, `:128`, `:138-139`)
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/invariants.md:56-60`
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/prd-supplements/nfr-catalog.md:76`, `:78`

**Defect.** DI-001's falsifying method (`invariants.md:56-60`) is explicit and prescriptive:

> Run the command twice on the same corpus under **differing** scheduler conditions (e.g. `RAYON_NUM_THREADS=1` vs `RAYON_NUM_THREADS=16`). Diff the two outputs byte-for-byte...

VP-011's `vp011_binary_output_stable_text` (lines 103-121) does something structurally different:

```rust
for threads in &["1", "4", "16"] {
    let run1 = ... .env("RAYON_NUM_THREADS", threads) ...;
    let run2 = ... .env("RAYON_NUM_THREADS", threads) ...;
    assert_eq!(run1.stdout, run2.stdout, "... with RAYON_NUM_THREADS={}", threads);
}
```

Both runs in every iteration use the **same** `threads` value. `run1@1` is never compared to `run1@16`. `vp011_binary_output_stable_json` (lines 123-141) has the identical structure. VP-011's own coverage note (lines 48-53) claims this harness "*provides the falsifying test for DI-001 by running the binary twice under different thread counts*" — it does not.

NFR-003 (`nfr-catalog.md:76`, `:78`) compounds it: Requirement = *"Two invocations ... with identical inputs, flags, and **environment**"*; Validation = *"run twice with identical inputs, diff stdout."* `RAYON_NUM_THREADS` is environment; NFR-003 as written **excludes** the varying-scheduler case entirely, while citing DI-001 as its Source.

**Why it matters.** Any implementation whose output order is a deterministic function *of thread count* — the single most likely nondeterminism shape (findings emitted in rayon completion order, or a partially-total sort key resolved differently by different chunk splits) — passes all four VP-011 harnesses and satisfies NFR-003, while violating DI-001. Combined with P4-004 (the sort key is disputed across five artifacts) and P4-005 (its totality premise is unwritten), DI-001 is a zero-tolerance invariant with no falsifying test. This is a POL-11-shaped false-green in the verification layer rather than in CI.

**Recommended fix.** Restructure both harnesses to capture a baseline and compare *across* thread counts:

```rust
let baseline = run_with("1");
for threads in &["2", "4", "16"] {
    assert_eq!(baseline.stdout, run_with(threads).stdout,
        "DI-001: stdout at RAYON_NUM_THREADS={} differs from RAYON_NUM_THREADS=1", threads);
}
```

Amend NFR-003's Requirement to *"...identical inputs and flags, under any thread-scheduling environment"* and its Validation method to name the cross-thread-count diff. Also replace `std::process::Command::new("cargo").args(&["run", ...])` with `env!("CARGO_BIN_EXE_mdlinkcheck")` — invoking `cargo` from inside a `cargo test` can block on the build lock. Finally, add a `--online` variant: `RAYON_NUM_THREADS` does not affect the 32-thread dedicated HTTP pool (`ADR-005:71-72`: "*fixed and does not scale with CPU count*"), so `--online` output determinism is currently unexercised by any knob any harness turns.

---

### P4-007 — MAJOR — DI-012 and DI-013 are orphan invariants: cited by **zero** BCs. BC-2.06.001 and BC-2.06.002 both cite DI-008, an invariant belonging to a different subsystem.

**Files / lines:**
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-06/BC-2.06.001.md:114`
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-06/BC-2.06.002.md:97`
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/invariants.md:253-330`

**Defect.** Grepping `DI-012|DI-013` across `.factory/specs/` returns 11 files: `module-criticality.md`, `invariants.md`, `failure-modes.md`, `verification-architecture.md`, `VP-INDEX.md`, `verification-coverage-matrix.md`, `vp-018`, `vp-026`, `L2-INDEX.md`, `decisions.md`, `capabilities.md`. **No behavioral contract file appears.** Both slug BCs' Traceability rows read:

- `BC-2.06.001.md:114` — `| L2 Domain Invariants | DI-008 |`
- `BC-2.06.002.md:97` — `| L2 Domain Invariants | DI-008 |`

DI-008 (`invariants.md:198`) is "Anchor Table Built Before Any Incoming Link Is Validated" — a Pass-1/Pass-1.5 ordering invariant owned by SS-05, correctly cited by BC-2.05.001/002/003 and BC-2.08.001/002/004. It has nothing to do with character-level slug transformation or duplicate-counter numbering. Meanwhile:

- DI-012 "Slug Computation Fidelity" (`invariants.md:253-290`) is *exactly* BC-2.06.001's subject.
- DI-013 "Anchor-Key Uniqueness within a File" (`invariants.md:294-330`) is *exactly* BC-2.06.002's subject ("Duplicate Heading Disambiguation").

The bidirectional check also fails: DI-012's and DI-013's "Why invariant" paragraphs (`:289`, `:330`) cite only `CAP-006, CAP-005. DD-027` — no BC names them either.

**Why it matters.** Two violations at once. (1) POL-2 (`lift_invariants_to_bcs`, MEDIUM): *"Every domain invariant (DI-NNN) must be cited by at least one BC's Traceability L2 Invariants field. Orphan invariants are drift."* Two orphans, both governing the product's highest-risk correctness surface — the invariants are invisible to story decomposition, so no Phase-2 story will carry a DI-012 or DI-013 acceptance criterion. (2) POL-4 (`semantic_anchoring_integrity`): the cited DI-008 *resolves*, so `check-id-resolution` passes, but the anchor is semantically wrong — the routed item-3 class exactly, and the same defect shape as the `module-criticality.md` DI-003 mis-citation already fixed this burst. This is a partial-fix regression: `invariants.md` was amended twice (v1.5 adding DI-012/013, v1.6 updating their falsifying methods) and the sibling BC Traceability rows were never touched in either commit.

**Recommended fix.** `BC-2.06.001.md:114` → `| L2 Domain Invariants | DI-012 (slug computation fidelity — all 7 rules) |`. `BC-2.06.002.md:97` → `| L2 Domain Invariants | DI-013 (anchor-key uniqueness; 0-based duplicate counter) |`. Add reciprocal BC citations to `invariants.md` DI-012 (`:289`) and DI-013 (`:330`). If DI-008 is genuinely relevant to either (it is not, but if the author intends the "slug must exist before resolution" chain), state it as a secondary citation with justification rather than as the sole entry.

---

### P4-008 — MAJOR — The slug module — the product's headline differentiator, CRITICAL tier, 6 VPs — has **no ADR**. Six artifacts anchor it to ADR-006, an ADR about filesystem path comparison whose body never mentions slugs.

**Files / lines:**
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/decisions/ADR-006-strict-path-model.md:7`, `:19`, `:42-65`, `:141-147`
- `/Users/jmagead/...` → `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-06/BC-2.06.001.md:116`
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-06/BC-2.06.002.md:99`
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/bc-module-map.md:156`, `:160-161`, `:143`, `:149`
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-05/BC-2.05.003.md:82`
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/ARCH-INDEX.md:81`

**Defect.** ADR-006's frontmatter claims `subsystems_affected: [SS-05, SS-06, SS-07]`, and `ARCH-INDEX.md:81` repeats it. But ADR-006's entire body — Context (23-40), Decision (42-65), Rationale (66-92), Non-UTF-8 section (94-110), Consequences (112-130), Alternatives (132-139), Source/Origin (141-147) — is about **path comparison only**: NFC normalization of filenames, `files_match(a: &str, b: &str) -> bool`, `DirEntries` populated by `scanner`, macOS NFD storage, case-sensitive `readme.md` vs `README.md`. It contains **zero** content about heading slug computation (SS-06) and zero content about anchor-table construction (SS-05).

The mis-anchor is then repeated verbatim, complete with the non-sequitur parenthetical:

- `BC-2.06.001.md:116` — `` `slug.rs` (SS-06, pure core, CRITICAL tier) — ADR-006 (NFC strict path model; slug algorithm is the primary differentiator) ``
- `BC-2.06.002.md:99` — identical string
- `bc-module-map.md:156` (§SS-06 header) — `Key ADRs: ADR-006 (NFC strict path model; slug algorithm is the primary differentiator).`
- `bc-module-map.md:160-161` — both slug BC rows list `ADR-006` in Key ADRs
- `BC-2.05.003.md:82` — `` `anchor_table.rs` ... — ADR-006 (NFC strict path model; HTML id/name anchor extraction) ``

The parenthetical structure — correct ADR title, then an unrelated claim — is the tell: someone needed *an* ADR and reached for the nearest one.

**Why it matters.** The seven ADRs are ADR-001 (pure core), ADR-002 (workspace), ADR-003 (pulldown-cmark), ADR-004 (ureq), ADR-005 (rayon/sort), ADR-006 (path model), ADR-007 (verdict model). **None covers the slug algorithm.** Yet `slug` is the sole basis of R-001/R-002, is CRITICAL tier with the highest VP count of any module (6, per `module-criticality.md:72`), carries the DD-015 algorithm pin, and its `github-slugger@2.0.0` version pin is the single most consequential unvalidated assumption in the project (`assumptions.md:50`, ASM-008: *"if GitHub's algorithm has diverged from github-slugger v2, every anchor check is wrong"*). An implementer following `BC-2.06.001.md:116` opens ADR-006 for slug guidance and finds a path-comparison document. There is no recorded decision for: why a clean-room reimplementation instead of an FFI/port; why v2.0.0 specifically; what the upgrade protocol is; how the NFC/NFD question in P4-009 is resolved. POL-4 + POL-5 (`creators_justify_anchors`: *"Agents creating anchors must justify each choice against the source-of-truth artifact. Stop and ask rather than guess."*) — this is a guessed anchor replicated six times.

**Recommended fix.** Author **ADR-008: Clean-Room github-slugger v2 Reimplementation** with `subsystems_affected: [SS-05, SS-06]`, capturing: the DD-015 pin and its rationale; why clean-room over FFI/port; the ASM-008 divergence-detection protocol (VP-026's oracle); the HTML-text adjudication from P4-001; and the NFC/NFD normalization decision from P4-009. Then re-anchor `BC-2.06.001:116`, `BC-2.06.002:99`, `bc-module-map.md:156`/`:160`/`:161` to ADR-008, and remove SS-06 (and SS-05 unless justified) from `ADR-006` frontmatter line 7 and `ARCH-INDEX.md:81`. Fix `BC-2.05.003.md:82` to cite the ADR that actually governs HTML `id`/`name` extraction (DI-007's owner) rather than the path model.

---

### P4-009 — MAJOR — VP-026's `heading_text_strategy()` is dead code. Rules 5 and 6, the NFC/NFD pair, and empty/whitespace inputs have **no** proptest arm, yet VP-026's coverage table and `verification-architecture.md` both claim they do.

**Files / lines:**
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-026-slug-differential-fidelity.md:280-305`, `:307-372`, `:136-137`, `:46-48`, `:127-128`, `:424`
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/verification-architecture.md:73`

**Defect.** VP-026 defines `fn heading_text_strategy() -> impl Strategy<Value = String>` at lines 280-305 with ten `prop_oneof!` arms covering: word characters (rules 2/4/5/6), multi-space (rule 3), non-word-flanked-by-spaces, leading/trailing whitespace (rule 5), emoji (rule 7), NFC `"résumé"`, NFD `"re\u{0301}sume\u{0301}"`, empty `""`, whitespace-only `"   "`, and a repeated heading.

**`heading_text_strategy` is never called.** The `proptest!` block (lines 307-372) contains exactly four tests, each with its own inline regex strategy:
- `prop_vp026_rule2_unicode_lowercase(heading in "[\\p{Lu}]{1,20}")`
- `prop_vp026_rule3_space_to_hyphen_1to1(prefix in "[a-z]{1,6}", spaces in " {2,5}", suffix in "[a-z]{1,6}")`
- `prop_vp026_rule4_underscore_retained(a in "[a-z]{1,8}", b in "[a-z]{1,8}")`
- `prop_vp026_rule7_emoji_stripped(prefix in "[a-z]{1,8}", emoji in "[\u{1F300}-\u{1F9FF}]{1,3}")`

Consequences: (a) rules 5 and 6 have zero proptest coverage, contradicting VP-026's own DI-012 Rule Coverage table, which claims `Rule 5 | ... | Oracle R-006; **proptest leading/trailing-space strategy**` (line 136) and `Rule 6 | ... | Oracle R-007; **proptest Unicode retained-class strategy**` (line 137); (b) the NFC/NFD pair — flagged in Feasibility as a "Known asymmetry" requiring coverage (line 424) — is never generated; (c) empty and whitespace-only inputs are never exercised; (d) in Rust, an uncalled private `fn` triggers `dead_code`, which fails any build using `#![deny(warnings)]`.

`verification-architecture.md:73` propagates the overclaim: *"proptest generator covers Unicode, emoji, **NFC/NFD**, **leading/trailing whitespace**, inline-code+HTML pre-rendered text"* — three of five named axes are not covered by any enabled arm.

**Defect (compounding) — no precedence rule between oracle and proptest.** All four proptest arms assert *derived DI-012 prose properties* (`!has_emoji`, `hyphen_run == space_count`, `slug.contains('_')`) rather than oracle parity, while the corpus test asserts byte-equality against real `github-slugger@2.0.0` output. Where the DI-012 prose is wrong about the library, these two components assert **contradictory** requirements and VP-026 becomes unsatisfiable. The concrete risk case is `prop_vp026_rule7_emoji_stripped`, which hardcodes "every codepoint in U+1F300..U+1F9FF is stripped" across a ~1,800-codepoint range containing unassigned planes; github-slugger v2's removal regex is a generated character class, and its astral-plane behaviour is a property of the library, not of DI-012's prose. VP-026 nowhere states which component wins.

**Why it matters.** VP-026 is the artifact that closed BI-005 and is declared by `invariants.md:280-282` to be *"the authoritative coverage vehicle for DI-012"* covering *"all 7 rules independently."* Two of seven rules are covered by the oracle corpus alone, so any regression outside the eight committed corpus runs is undetected — precisely the gap VP-026's own §Proof Method (line 187) says the proptest component exists to close: *"Catches regressions not in the committed corpus."*

**Recommended fix.** (a) Add two proptest arms:
```rust
#[test] fn prop_vp026_rule5_leading_trailing_retained(
    lead in " {1,3}", body in "[a-z]{1,10}", trail in " {0,3}") { /* assert slug starts/ends with matching hyphen runs */ }
#[test] fn prop_vp026_rule6_unicode_word_retained(
    s in "[\\p{Han}\\p{Cyrillic}]{1,10}") { /* assert every input char present in slug */ }
```
(b) Either wire `heading_text_strategy()` into an oracle-free totality arm or delete it — do not leave it dead. (c) Add a normative precedence clause to §Oracle Definition: *"Where a proptest structural assertion conflicts with the committed oracle corpus, the oracle wins; the DI-012 prose is corrected to match the library and the proptest arm is amended in the same commit."* (d) Correct `verification-architecture.md:73` to name only the axes actually covered, or land (a) first so the claim becomes true.

---

### P4-010 — MAJOR — VP-026 has no enabled falsifying clause for DI-012 Rule 1. The oracle bypasses heading rendering on **both** sides, and the only real Rule-1 test is commented out.

**Files / lines:**
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-026-slug-differential-fidelity.md:132`, `:140-150`, `:374-393`, `:46-48`, `:127-128`
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-018-slug-worked-examples.md:109-116`, `:172-196`

**Defect.** DI-012 Rule 1 is the *rendering* rule: "Input is rendered text content — inline code → text; HTML tags stripped, visible text retained; the heading text is taken after AST rendering, not from raw source bytes." VP-026 claims to cover it via oracle run R-003 (line 132). But lines 148-150 state:

> The generator script passes the **pre-rendered text** to `github-slugger`. The integration of the full pipeline (raw heading → AST rendering → `compute_slug`) is an obligation recorded in the Phase 3 section below.

So the generator feeds `"config api new"` to github-slugger, and the Rust test feeds the same `"config api new"` string to `compute_slug`. **The rendering step — the entire substance of Rule 1 — is bypassed on both sides.** What R-003 actually tests is `slug("config api new") == "config-api-new"`: a plain space→hyphen check already covered by R-002. The only test that exercises rendering is `vp026_di012_rule1_inline_code_html_end_to_end` at lines 374-393, which is **commented out** and deferred to Phase 3. VP-018 has the identical structure: corpus row `("code text", "code-text")` at line 116 is pre-rendered, and `vp018_di012_rule1_end_to_end` (lines 172-196) is commented out.

**Why it matters.** VP-026's Property Statement (lines 46-48) and §DI-012 Rule Coverage preamble (127-128) both assert: *"All seven DI-012 rules are covered independently — each has a falsifying clause that a compliant implementation passes and a non-compliant one fails."* This is false for Rule 1. An implementation that reads heading text from **raw source bytes** — yielding `` `config` API <em>new</em> `` and therefore slug `config-api-emnewem` — passes every enabled clause in VP-026 and VP-018. Raw-source-byte extraction is not a hypothetical: it is the failure mode DI-012 Rule 1 exists to prohibit, and market-intelligence T1/T14 document it in incumbents. Combined with P4-001 (the two vectors these VPs *do* carry contradict BC-2.06.001), Rule 1 is currently the least-verified and most-contested rule of the seven.

**Recommended fix.** Rule 1 cannot be verified by a slug-level oracle — it is an `anchor_table` obligation. Either (a) reassign Rule-1 coverage to a VP on the `anchor_table` module (VP-015/VP-016/VP-020 are the natural home) and delete the Rule-1 row from VP-026's coverage table, or (b) split VP-026's Rule-1 row into "Rule 1a: pre-rendered slug (oracle R-003, covered)" and "Rule 1b: rendering fidelity (integration, **NOT covered until Phase 3**)". Either way, amend the Property Statement at lines 46-48 to say "six of seven rules have an enabled falsifying clause; Rule 1's rendering half is a Phase 3 obligation" and add a matching gap note to `verification-architecture.md:146`, which currently asserts DI-012 coverage is closed.

---

### P4-011 — MAJOR — VP-026's oracle-freshness CI check is self-contradictory: the fixture embeds a generation timestamp, so `just regen-slug-vectors && git diff --exit-code` can never be a no-op.

**Files / lines:** `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-026-slug-differential-fidelity.md:82-89`, `:114-118`, `:120-123`, `:407-408`

**Defect.** The fixture's mandated provenance block (lines 82-89) is:

```json
"provenance": {
  "github_slugger_version": "2.0.0",
  "generator_script": "tools/gen-slug-oracle.js",
  "generator_script_sha256": "<sha256 of gen-slug-oracle.js at generation time>",
  "generated_at": "YYYY-MM-DDTHH:MM:SSZ",
  "node_version": "22.x"
}
```

and lines 114-118 / 407 mandate the CI check:

> A CI check runs the generator and asserts `git diff --exit-code tests/fixtures/slug-oracle-vectors.json` is a no-op, ensuring the corpus stays current with the committed generator version.

`generated_at` is a fresh wall-clock timestamp on every regeneration. Therefore `git diff` is **always** non-empty and the check **always** fails. `node_version: "22.x"` is a second, weaker instance (it changes with the runner's Node minor).

**Why it matters.** This lands as one of two failure modes, both bad. (1) The job is permanently red, so it gets marked `continue-on-error` or deleted — and the ASM-008 divergence tripwire, the *only* automated mechanism that would detect GitHub changing its slug algorithm (`assumptions.md:42`, `:50`: HIGH impact, "*all anchor resolution results are wrong if GitHub diverged*"), is gone. (2) Someone "fixes" it by diffing only `.runs` and excluding `.provenance` — which also excludes `github_slugger_version` from drift detection, so an unreviewed `github-slugger` upgrade regenerates the corpus, the corpus becomes self-consistent with the new library, the harness's `assert_eq!(corpus.provenance.github_slugger_version, "2.0.0")` (lines 240-245) is the only thing left, and it fails loudly — but only because someone hardcoded the string, not because the check works. Either way the design as written cannot be implemented as specified. POL-11.

**Recommended fix.** Make the diff target deterministic. Concretely: (a) move `generated_at` and `node_version` out of the committed fixture into a separate uncommitted/`.gitignore`d sidecar, **or** (b) specify that the generator writes `generated_at` only when `.runs` or `generator_script_sha256` actually change (read-modify-write), **or** (c) change the CI assertion to `jq -S '{runs, provenance: {github_slugger_version, generator_script_sha256}}'` on both the regenerated and committed files and diff *that* — and state explicitly in the Phase 3 obligation table that `github_slugger_version` and `generator_script_sha256` MUST be inside the diff scope. Add the chosen mechanism to the obligation table at line 407 so a Phase 3 implementer cannot pick the version that drops version-drift detection.

---

### P4-012 — MAJOR — VP-026's oracle corpus test passes vacuously on an empty or truncated corpus: no positive-coverage assertion, and the R-001..R-008 requirement is prose-only.

**Files / lines:** `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-026-slug-differential-fidelity.md:231-260`, `:410-411`, `:414`

**Defect.** `vp026_oracle_corpus_exact_match` (lines 231-260) is:

```rust
for run in &corpus.runs {
    let mut counter = DuplicateCounter::new();
    for entry in &run.entries {
        let actual = compute_slug(&entry.heading, &mut counter);
        assert_eq!(actual, entry.expected, "...");
    }
}
```

With `"runs": []`, or with any subset of the eight required runs, the loop body never executes for the missing runs and the test **passes**. The only non-vacuous assertion in the function is the version pin at lines 240-245. Meanwhile the coverage requirements exist only as prose: line 410 (*"Runs R-001 through R-008 ... each run contains ≥1 entry"*), line 411 (*"Run R-001 MUST contain ≥3 entries with identical base heading"*), and line 414's `oracle_runs_required` list. Nothing in the harness enforces any of them.

**Why it matters.** POL-11 (`ci_positive_coverage_assertion`) verification step: *"verify the job's log contains a positive-coverage assertion of the form 'Check passed: N items validated'"*, and *"Reject CI jobs whose only success indicator is exit-0."* VP-026's oracle test is exactly the rejected shape. The realistic failure: a Phase 3 implementer generates the corpus, the generator script has a bug and emits only R-001 and R-002, the test goes green, and VP-026 is recorded as passing — satisfying the Phase 6 gate (line 409: *"VP-026 must pass (green) before Phase 6 formal hardening can proceed"*) while five of seven DI-012 rules have no oracle coverage at all. This is a false-green on the gate for the product's headline differentiator. The one saving grace is `vp026_fm002_discriminator_0_based_counter` (lines 264-276), which hardcodes the FM-002 values independently of the corpus — so FM-002 specifically survives an empty corpus. Rules 1-7 do not.

**Recommended fix.** Add a positive-coverage block to `vp026_oracle_corpus_exact_match`:

```rust
let mut entries_checked = 0usize;
// ... existing loops, incrementing entries_checked ...
let ids: std::collections::HashSet<&str> = corpus.runs.iter().map(|r| r.id.as_str()).collect();
for required in ["R-001","R-002","R-003","R-004","R-005","R-006","R-007","R-008"] {
    assert!(ids.contains(required),
        "Oracle corpus missing required run {} — regenerate with `just regen-slug-vectors`", required);
}
let r001 = corpus.runs.iter().find(|r| r.id == "R-001").unwrap();
assert!(r001.entries.len() >= 3,
    "FM-002 discriminator requires >=3 entries in R-001; found {}", r001.entries.len());
assert!(entries_checked >= 8, "Oracle corpus validated only {} entries", entries_checked);
eprintln!("VP-026 oracle: {} runs, {} entries validated against github-slugger@{}",
    corpus.runs.len(), entries_checked, corpus.provenance.github_slugger_version);
```

Record this assertion block as a line item in the Phase 3 Implementation Obligation table so it cannot be dropped.

---

### P4-013 — MAJOR — VP-026's Feasibility section requires an NFC/NFD oracle run; its normative `oracle_runs_required` list and Phase 3 obligation table omit it. An implementer satisfying the obligation table violates the feasibility requirement.

**Files / lines:** `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-026-slug-differential-fidelity.md:424`, `:410`, `:414`, `:294-298`

**Defect.** Feasibility Assessment line 424:

> | NFC/NFD edge case | Known asymmetry | NFD combining diacritics (\p{Mn}) are stripped by github-slugger v2; NFC accented chars (\p{L}) are retained; **the oracle corpus must include both forms with their respective expected outputs**; see provenance note |

But the two normative enumerations of required runs contain no NFC/NFD run:
- Line 410 — `| **Oracle coverage** | Runs R-001 through R-008 (one per DI-012 rule, plus FM-002 discriminator); each run contains ≥1 entry |`
- Line 414 — `**oracle_runs_required:** R-001 (FM-002), R-002 (rule 3), R-003 (rule 1), R-004 (rule 2), R-005 (rule 4), R-006 (rule 5), R-007 (rule 6), R-008 (rule 7).`

And the NFC/NFD pair in the proptest strategy (lines 294-298) is dead code per P4-009. So the requirement is stated in one place and contradicted by the two places a Phase 3 implementer will actually read.

**Defect (compounding) — the NFD claim is itself an unadjudicated behavioural assertion.** VP-026:296-298 asserts NFD `"re\u{0301}sume\u{0301}"` → `"resume"` (diacritics stripped). VP-018:97 asserts `("résumé", "résumé")` with the comment `// Accented preserved (**NFC normalization**)`. If the implementation NFC-normalizes heading text before slugging, NFD input composes to `résumé` and the slug is `résumé`, **not** `resume` — VP-026's assertion is then wrong. If it does not normalize, VP-018's parenthetical is misleading. Nothing adjudicates: DI-012's seven rules (`invariants.md:259-273`) never mention normalization of heading text; DI-002 and ADR-006 mandate NFC strictly for **path** comparison; VP-009 tests NFC idempotence for **paths** (`vp-009.md:15` `module: path_resolver`, `:42` `source_bc: BC-2.07.003`). Whether the anchor/slug path normalizes is unspecified.

**Why it matters.** macOS HFS+/APFS stores filenames in NFD (`ADR-006:25-27`), and NFD-authored heading text is common in editors on macOS. A heading `## Résumé` written in NFD and a link `[x](#résumé)` written in NFC must resolve to the same anchor key or the tool emits a false-positive `anchor-not-found` on a valid link — the product's core promise. That behaviour is currently undefined, has no oracle run, has no proptest arm, and its two mentions in the spec set contradict each other.

**Recommended fix.** (a) Adjudicate: state explicitly in DI-012 whether heading text is NFC-normalized before step (b) of the DD-015 algorithm, and record the decision in the new ADR-008 from P4-008. `github-slugger` does **not** normalize, so matching it byte-for-byte (the stated goal) means no normalization — in which case DI-012 needs an eighth rule and a `broken`/`clean` decision for the NFD-heading + NFC-link case. (b) Add `R-009` (NFC form) and `R-010` (NFD form) to line 410, line 414, and the `oracle_runs_required` list, with expected outputs derived from the adjudication. (c) Correct or delete the `// Accented preserved (NFC normalization)` comment at `vp-018.md:97` so the two VPs agree.

---

### P4-014 — MAJOR — Ten VP harnesses are specified at `tests/<subdir>/<name>.rs`, which Cargo does **not** auto-discover as test targets. As specified, none of them would ever run.

**Files / lines:**
- `vp-011-sort-deterministic.md:99` — `// tests/integration/determinism.rs  (Phase 3)`
- `vp-014-code-context-exclusion.md:67` — `// tests/integration/link_extractor_code_exclusion.rs`
- `vp-015-two-pass-anchor-complete.md:57` — `// tests/integration/two_pass_anchor.rs`
- `vp-016-ignored-files-anchor-targets.md:66` — `// tests/integration/ignored_file_anchor.rs`
- `vp-017-scan-terminates.md:57` — `// tests/integration/scan_termination.rs`
- `vp-018-slug-worked-examples.md:69` — `// tests/unit/slug_corpus.rs`
- `vp-020-html-anchor-narrow-scope.md:62` — `// tests/integration/html_anchor_scope.rs`
- `vp-025-anchor-resolver-totality.md:125` — `// tests/proptest/anchor_resolver.rs`
- `vp-026-slug-differential-fidelity.md:193`, `:404` — `tests/proptest/slug_differential.rs`
- Contrast: `architecture/tooling-selection.md:70-80` (fuzz targets, correct), `:53-56` (Kani harnesses in `src/`, correct)

**Defect.** Cargo's integration-test auto-discovery accepts `tests/*.rs` and `tests/<dir>/main.rs`. A file at `tests/proptest/slug_differential.rs` or `tests/unit/slug_corpus.rs` matches neither: it is not compiled at all unless (a) a sibling `tests/<dir>/main.rs` declares `mod slug_differential;`, or (b) the crate's `Cargo.toml` declares an explicit `[[test]] name = "..." path = "tests/proptest/slug_differential.rs"` target. Neither mechanism is specified anywhere. `tooling-selection.md`'s Verification Toolchain and Test Dependencies sections say nothing about test-target layout; `ADR-002-workspace-layout.md` covers crates and `[profile.release]` only; `api-surface.md` covers the public API. The fuzz layout (`tooling-selection.md:70-80`, `fuzz/fuzz_targets/*.rs`) is correct because `cargo-fuzz` generates `[[bin]]` entries — which is exactly the mechanism absent for the ten test files above.

**Why it matters.** This is the highest-leverage false-green in the package: ten VP harnesses, including VP-018 (the NFR-006 vehicle), VP-011 (the DI-001 vehicle), VP-025 (the anchor_resolver vehicle), and VP-026 (the BI-005 closure), silently compile to nothing. `cargo test` reports `0 passed` for those targets and exits 0. The Phase 6 gate (`vp-026:409`) checks that VP-026 "passes (green)" — a non-existent target is trivially green. Because the pattern is identical across ten files in four verification categories, it is a systemic convention defect, not ten independent typos → HIGH with pattern flag.

**Recommended fix.** Pick one convention and record it in `tooling-selection.md` as a new "Test Target Layout" section, then update all ten VP path comments to match. Recommended (least ceremony, works with `cargo nextest`): flatten to `tests/<category>_<name>.rs` — `tests/proptest_slug_differential.rs`, `tests/unit_slug_corpus.rs`, `tests/integration_determinism.rs`. Alternative: keep the directories and mandate `tests/proptest/main.rs`, `tests/unit/main.rs`, `tests/integration/main.rs` aggregator files with `mod` declarations, and state that requirement in `tooling-selection.md` plus each affected VP's Phase 3 obligation. Add a CI positive-coverage assertion per POL-11: `cargo nextest list | wc -l` must be ≥ the expected harness count.

---

### P4-015 — MAJOR — BC-2.10.004 handles only the delta-seconds form of `Retry-After`; `events.md` mandates both forms. Date-form, negative, and malformed values have no specified behaviour, and the pause has no upper bound — with no NFR bounding `--online` wall-clock at all.

**Files / lines:**
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-10/BC-2.10.004.md:37-38`, `:41-45`, `:46-51`, `:58-63`, `:65-69`
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/events.md:110`
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/dtu-assessment.md:289`
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/prd-supplements/nfr-catalog.md:34-35`, `:56`

**Defect A — date-form is mandated at L2 and absent at L3.** `events.md:110` (L2 domain spec): *"Per-host rate limiting; honor `Retry-After` header (**delay-seconds or HTTP-date**)."* RFC 9110 §10.2.3 permits both. BC-2.10.004 — the sole normative implementation contract — specifies only seconds:
- `:37-38` — *"for the duration specified in the `Retry-After` response header (or a default 60 seconds if the header is absent)"*
- `:49` — PC3: *"Pause duration = Retry-After header value **in seconds**, or 60 seconds if absent."*

Its Edge Cases (`:58-63`) are EC-087 (`Retry-After: 30`), EC-087b (absent), EC-087c (all URLs same host) — no date form. Its Canonical Test Vectors (`:65-69`) are `Retry-After: 5` and absent. `dtu-assessment.md:289` explicitly flags the gap as an open recommendation — *"Real-world 429 `Retry-After` **date-form** parsing edge cases | Low | Add date-form `Retry-After` test to the fixture suite"* — and no BC absorbed it.

**Defect B — no behaviour for malformed values.** BC-2.10.004 has no precondition or postcondition for `Retry-After: -1`, `Retry-After: abc`, `Retry-After:` (empty), or `Retry-After: 99999999999999999999`. An implementer writing `header.parse::<u64>()` gets `Err` and must invent behaviour: `unwrap()` → panic on a hostile header (crash, exit 101, not in the 0/1/2 contract); `unwrap_or(0)` → zero pause and immediate re-hammering of a rate-limited host; `unwrap_or(60)` → silent swallow of a parse failure (SOUL.md #4 violation). None of these is specified, so all three will appear in review as "reasonable".

**Defect C — the pause is unbounded, and nothing forbids it.** No cap on the honored value appears anywhere in the spec set (grep over `.factory/specs` for `Retry-After` returns 21 hits; none states a maximum). `Retry-After: 86400` pauses the host for 24 hours. Crucially, the natural guard rail does **not** apply: NFR-001 measures *"500 `.md` files with **offline checks only**"* with *"**zero external URLs**"* (`nfr-catalog.md:34-35`) and NFR-002 the *"same 500-file corpus, **offline checks only**"* (`:56`). So a 24-hour hang violates **no NFR** — there is no wall-clock requirement covering `--online` at all. The 10-second per-URL timeout (`BC-2.10.003:36-38`) is per-request and does not bound the pause.

**Why it matters.** `mdlinkcheck` targets CI (`ARCH-INDEX`, NFR-002 Linux CI runner, NFR-008 merge-blocking gate). A single misconfigured or hostile server on any `--online` run wedges the pipeline until the CI job's own timeout kills it — indistinguishable from a hang, with no output, no findings, and no exit code. DI-009 exists precisely because *"Non-termination is a denial-of-service against CI pipelines"* (`invariants.md:223`) — but DI-009 scopes only filesystem traversal, so the `--online` path is outside its protection. Defect A is a straight L2→L3 refinement gap (POL-16-adjacent: the BC contradicts the authoritative L2 entry it derives from); Defect B is a missing-error-handling gap on a P0 BC; Defect C is a resource-exhaustion vector with no governing requirement.

**Recommended fix.** Amend BC-2.10.004: (a) PC3 → *"Pause duration is derived from `Retry-After` per RFC 9110 §10.2.3: if the value is delta-seconds, that many seconds; if it is an HTTP-date, `max(0, date − now)`; if the header is absent, unparseable, negative, or non-numeric-non-date, 60 seconds AND a `[warn]` diagnostic naming the raw header value is emitted to stderr."* (b) New PC6: *"The honored pause is clamped to `min(computed, 120s)`. A `Retry-After` exceeding the clamp is honored at the clamp and a `[warn]` diagnostic is emitted."* (Choose the constant deliberately; 120s is a suggestion.) (c) New Invariant 4: *"Total pause time accumulated across all hosts in one invocation is bounded; no `--online` run can be delayed indefinitely by server-controlled headers."* (d) Add edge cases EC-087d (HTTP-date form), EC-087e (malformed value), EC-087f (`Retry-After: 86400` → clamped) with canonical vectors, and add matching rows to `test-vectors.md` §4. (e) Add **NFR-009: `--online` wall-clock bound** to `nfr-catalog.md` so a future regression has a requirement to violate.

---

### P4-016 — MAJOR — Four BCs label `cli.rs` as subsystem SS-11. SS-11 is "Filter Application | filter"; `cli` is not an implementing module of any registered subsystem.

**Files / lines:**
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-14/BC-2.14.004.md:82`
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-11/BC-2.11.004.md:85`
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-12/BC-2.12.002.md:81`
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-12/BC-2.12.004.md:80`
- Authority: `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/ARCH-INDEX.md:50-70`

**Defect.** `ARCH-INDEX.md:52-53` declares itself *"**Source of truth** for subsystem names"* with an Implementing Modules column. Line 67 reads `| SS-11 | Filter Application | filter | Phase 1 |` — `filter` only. Yet:

- `BC-2.14.004.md:82` — `` `cli.rs` (**SS-11**, effectful shell, LOW tier) — ADR-007 (--help/--version are cli module concerns) ``
- `BC-2.11.004.md:85` — `` `cli.rs` (**SS-11**, effectful shell, LOW tier) primary; `verdict.rs` (SS-14 ...) secondary ``
- `BC-2.12.002.md:81` — `` `reporter.rs` (SS-12 ...) primary; `cli.rs` (**SS-11**, effectful, LOW tier) secondary ``
- `BC-2.12.004.md:80` — `` `cli.rs` (**SS-11**, effectful shell, LOW tier) primary; `reporter.rs` (SS-12 ...) secondary ``

`cli`, `app`, `main`, and `types` appear in `module-criticality.md`'s inventory (lines 64-66) and in `bc-module-map.md`'s ownership summary (lines 350-353) but in no ARCH-INDEX subsystem row. Note that the analogous cases are **not** defects: `link_extractor` labelled SS-03 and SS-04, `fragment` labelled SS-07 and SS-08, `reporter` labelled SS-12 and SS-13 are all sanctioned by ARCH-INDEX rows 58-69, which assign those modules to multiple subsystems. `cli`→SS-11 is the only unsanctioned label.

**Why it matters.** POL-6 (`architecture_is_subsystem_name_source_of_truth`, severity **HIGH**): *"ARCH-INDEX Subsystem Registry is the canonical source for subsystem names. All references must match verbatim."* Blast radius 4 files. Phase 2 story decomposition consumes the `Architecture Module` row to route work; a story-writer reading `BC-2.14.004` will file a `--help`/`--version` story under "SS-11 Filter Application", where it will be grouped with glob-matching work and reviewed by the wrong subsystem owner. The mislabel is invisible to `check-id-resolution` because SS-11 exists — the routed item-3 class. `BC-2.14.004.md:82`'s parenthetical is separately fabricated: it attributes *"--help/--version are cli module concerns"* to ADR-007, which is the three-verdict/verdict-model ADR and says nothing about `--help` or `--version`.

**Recommended fix.** Either (a) add `cli`, `app`, `main`, `types` to the ARCH-INDEX Subsystem Registry — the cleanest option is a new row `| SS-15 | CLI & Orchestration | cli, app, main, types | Phase 1 |`, then relabel the four BC rows — or (b) drop the `(SS-NN)` annotation from `cli.rs` in all four BCs, writing `` `cli.rs` (effectful shell, LOW tier; not subsystem-owned — see module-criticality.md) `` as `BC-2.05.001.md:119` already does for `app.rs`. Separately, remove the fabricated ADR-007 parenthetical from `BC-2.14.004.md:82`. Option (a) is preferable: four BCs currently have primary ownership by an unregistered module, which will recur every time a BC touches `cli`.

---

### P4-017 — MAJOR — NFR-006 names `test-vectors.md` §7 (16 canonical slug vectors) as its test inputs; VP-018, its only verification vehicle, implements a near-disjoint 15-row corpus. Overlap is 2 of 16.

**Files / lines:**
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/prd-supplements/nfr-catalog.md:119-123`
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/prd-supplements/test-vectors.md:264-285`
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-018-slug-worked-examples.md:73-117`

**Defect.** NFR-006 (`nfr-catalog.md:119-123`): Requirement *"All worked examples from DD-015 (market-intelligence §4.1) pass as unit tests in the slug module"*; Target *"100% — all 16 worked examples + DEC-001 collision case pass"*; Test inputs *"See test-vectors.md §7 (slug algorithm vectors)"*. §7 contains exactly 16 rows, TV-S001..TV-S016.

VP-018 is NFR-006's declared vehicle (`vp-018.md:57`: *"NFR-006 — clean-room reimplementation matches github-slugger v2 on all reference corpus inputs"*; `verification-architecture.md:90`). Its `SLUG_CORPUS` (lines 73-117) has 15 rows. Comparing the two sets, **only two inputs appear in both**: `Hello, World!` (TV-S004 / VP-018:78) and `AI & Automation` (TV-S011 / VP-018:104).

Canonical vectors in §7 with **no** test in VP-018, VP-026's `oracle_runs_required`, or anywhere else:

| TV | Input | Expected | Rule exercised |
|---|---|---|---|
| TV-S001/2/3 | `Foo` ×3 | `foo`, `foo-1`, `foo-2` | duplicate counter (covered by VP-018's separate `Setup` test, different input) |
| TV-S005 | `Hello,  World!` | `hello--world` | 1:1 space with punctuation removal |
| TV-S006 | `Привет non-latin 你好` | `привет-non-latin-你好` | mixed-script |
| TV-S007 | `😄 emoji` | `-emoji` | **leading** hyphen from stripped emoji |
| TV-S009 | `C++ / C#` | `c--c` | multi-symbol strip |
| TV-S010 | `` `--online` flag `` | `--online-flag` | backtick strip, leading hyphens retained |
| TV-S013 | fenced-block `## setup` | only real heading | DI-004 × slug interaction |
| TV-S014 | `## Use \`--online\` **now**` | `use---online-now` | inline code + bold rendering |
| TV-S015 | `## Foo <a name="bar"></a>` | `foo-` | HTML element rendering |
| TV-S016 | `## Done ✅` | `done-` | trailing hyphen not trimmed |

Conversely, 13 of VP-018's 15 rows are not in §7 at all. And neither of the two Rule-1 vectors added in this burst (VP-018:116 `("code text","code-text")`; VP-026:132 `"config api new"`) was added to §7 — the registry NFR-006 points at.

**Why it matters.** NFR-006 is the acceptance requirement for the product's headline differentiator, its Target is a hard 100%, and its validation runs *"on every commit"* (`nfr-catalog.md:121`). As specified it is **unsatisfiable**: the vehicle does not test the named inputs. TV-S007 (`😄 emoji` → `-emoji`, a *leading* hyphen) and TV-S010 (`` `--online` flag `` → `--online-flag`, leading hyphens from a code span) are the two hardest cases in the registry — the shape that FM-001-style hyphen-collapsing/trimming bugs actually take — and neither has a test. TV-S013 and TV-S015 are the two vectors that would have adjudicated P4-001. This is a semantic-anchoring defect of the routed item-3 class: §7 resolves, so the citation is "valid", but the vehicle tests a different corpus.

**Recommended fix.** Make `test-vectors.md` §7 the single source of truth and derive VP-018 from it. Concretely: (a) merge VP-018's 13 unique rows into §7 as TV-S017..TV-S029 (append-only per POL-1); (b) rewrite VP-018's `SLUG_CORPUS` as a one-to-one transcription of §7, ordered by TV-S ID, with each row commented with its TV-S ID so drift is visible in review; (c) add the P4-001 adjudicated Rule-1 vector to §7; (d) update NFR-006's Target from *"all 16 worked examples"* to *"all TV-S vectors in test-vectors.md §7 (currently N)"* so the target tracks the registry instead of a frozen count; (e) add a positive-coverage assertion to `vp018_slug_corpus_exact_match` — `assert_eq!(SLUG_CORPUS.len(), <N>, "VP-018 corpus drifted from test-vectors.md §7")` — per POL-11.

---

### P4-018 — MAJOR — `tooling-selection.md` provisions none of VP-026's toolchain (Node.js, `github-slugger@2.0.0`, `serde_json`, `serde`) nor `unicode-normalization`, and its proptest VP list and `module-criticality.md` version citation are stale.

**Files / lines:** `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/tooling-selection.md:5`, `:27-34`, `:36-42`, `:41`, `:65`; cross-ref `vp-026:406-408`, `:423`; `ADR-006:46`, `:129-130`; `module-criticality.md:4`

**Defect A — VP-026's toolchain is unprovisioned.** VP-026's Phase 3 obligation table (`:406-408`) requires a Node.js generator script with a pinned `github-slugger@2.0.0`, and its Feasibility row (`:423`) requires *"`serde_json` for fixture loading"* (plus `serde` for the four `#[derive(Deserialize)]` structs at `vp-026:204-227`). `tooling-selection.md`'s Verification Toolchain table (lines 27-34) lists Kani, cargo-fuzz, cargo-mutants, cargo-nextest, semgrep, hyperfine — no Node.js. Its Test Dependencies table (lines 38-42) lists `httpmock`, `proptest`, `tempfile` — no `serde_json`, no `serde`. `tooling-selection.md` is v1.1 dated 2026-08-05; VP-026 landed 2026-08-06 and the architecture's tooling document was not updated.

**Defect B — `unicode-normalization` is unpinned and unprovisioned.** `ADR-006:46` specifies *"`unicode-normalization` crate, `0.1.x` **or** `1.x`"* — two incompatible major-version ranges — and `ADR-006:129-130` defers: *"`unicode-normalization` crate version must be pinned when workspace `Cargo.toml` is written."* The crate appears nowhere in `tooling-selection.md`. It is load-bearing for DI-002, DI-001's sort key, VP-008, and VP-009.

**Defect C — stale proptest VP list.** `tooling-selection.md:41` — `` | `proptest` | **1.6.x** | Property-based testing: VP-008..011, VP-019 | ``. Per VP frontmatter, the proptest VPs now also include VP-023 (`vp-023:16`), VP-024, VP-025 (`vp-025:17`), and VP-026 (`vp-026:17`). The list is missing four VPs, two added this burst.

**Defect D — stale cross-document version citation.** `tooling-selection.md:65` — *"Per module-criticality.md **v1.2**: slug, fragment, anchor_table, link_extractor, path_resolver, anchor_resolver, verdict, http_verdict are CRITICAL."* `module-criticality.md` is v1.5 (`:4`). The CRITICAL list happens to still be correct, but the citation pins a superseded revision — and `module-criticality.md:179-180` compounds it by labelling its own lists *"CRITICAL modules (**v1.3**)"* inside a v1.5 document.

**Why it matters.** `tooling-selection.md` is the document the dx-engineer and formal-verifier build the environment from (`ARCH-INDEX.md:36`). Phase 3 starts, `just regen-slug-vectors` is run, and there is no Node.js in the container and no `github-slugger` in any manifest — VP-026 is blocked at the first step, and the natural resolution under time pressure is to hand-write the fixture, which silently converts the differential oracle into a second hand-curated corpus with no provenance and no divergence detection (defeating VP-026's entire purpose and re-opening ASM-008). Defect B is worse in kind: `0.1.x or 1.x` is not a pin, and NFR-004 requires identical behaviour on macOS/Linux/Windows across a crate whose major version is undetermined.

**Recommended fix.** `tooling-selection.md` v1.2: (a) add to Verification Toolchain — `| **Node.js** | 22.x LTS | Oracle-corpus generation for VP-026 (generation time only, never test time) | 3 | tools/gen-slug-oracle.js |` and `| **github-slugger** | 2.0.0 (npm, exact pin) | Differential oracle reference for VP-026 / DI-012 | 3 | tools/package.json + package-lock.json committed |`; (b) add to Test Dependencies — `serde` 1.x (derive), `serde_json` 1.x; (c) add a new "Runtime Dependencies" table pinning `unicode-normalization` to one exact version and amend `ADR-006:46` and `:129-130` to match; (d) correct line 41's VP list to `VP-008..011, VP-019, VP-023..026`; (e) correct line 65's citation to v1.5 and fix `module-criticality.md:179-180`'s `(v1.3)` labels to `(v1.5)`.

---

### P4-019 — MAJOR — The mandatory DI-001 sort stage is owned by `app`, which has zero primary BCs and MEDIUM tier, while VP-011 is filed against `reporter`.

**Files / lines:**
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/system-overview.md:150`, `:164-167`
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/decisions/ADR-005-rayon-sort-before-emit.md:34-39`
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-011-sort-deterministic.md:15`
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/module-criticality.md:81`, `:85`
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/bc-module-map.md:351`, `:373`

**Defect.** `system-overview.md:150` places the sort explicitly in `app`:

> `Sort:   sort_unstable_by(NFC-path, line, col) — enforces DI-001 determinism (app)`

and `:164-167` confirms it is a stage *between* Pass 2 collection and the stdout write, *before* the reporter. ADR-005:34-39 agrees: *"After Pass 2 collects all `Finding` objects, sort the `Vec<Finding>` ... **before passing to the reporter**."*

But `vp-011.md:15` declares `module: reporter`, and `module-criticality.md:81` credits reporter: *"`reporter` | HIGH | Output format correctness; **sort determines VP-011 determinism guarantee**; VP-011, VP-021 | >= 90% | 2"*. Meanwhile `app` is MEDIUM tier with a ≥80% kill-rate target (`module-criticality.md:85`), and `bc-module-map.md:351`/`:373` record `app` with **0 primary BCs** (only BC-2.05.001 as secondary).

**Why it matters.** The result is an ownership hole around the only pipeline stage the architecture calls mandatory (`ADR-005:39`: *"This sort is a mandatory pipeline stage — no finding may bypass it"*): the code lives in `app`; no BC owns `app` as primary, so no Phase-2 story will be generated with the sort as its acceptance criterion; `app`'s mutation kill-rate target is the second-weakest in the project; and the VP that verifies the sort is filed against a different module (`reporter`), so `cargo-mutants` run against `reporter` will find no sort code to mutate and report a clean HIGH-tier result while the actual sort in `app` is mutated at the MEDIUM threshold. Compounded with P4-004 (five artifacts disagree on the sort key), P4-005 (the totality premise is unwritten), and P4-006 (no harness implements DI-001's falsifying method), the zero-tolerance invariant is unowned, under-tiered, and unverified.

**Recommended fix.** Adjudicate ownership. Preferred: move `sort_findings` into `mdlinkcheck-core` as a pure function (it is pure — `Vec<Finding>` in, sorted `Vec<Finding>` out) owned by `reporter` or a new `sort` module, so that (a) `vp-011.md:15`'s `module: reporter` becomes correct, (b) it inherits the HIGH/CRITICAL kill-rate target, and (c) it is Kani/proptest reachable in the library crate. Update `system-overview.md:150` from `(app)` to the chosen owner. If instead the sort stays in `app`: raise `app` to CRITICAL in `module-criticality.md:85`/`:107` with a rationale naming DI-001, change `vp-011.md:15` to `module: app`, update `verification-coverage-matrix.md`'s VP-011 module row, and add a BC that owns the sort stage as primary so a Phase-2 story exists.

---

### P4-020 — MAJOR — BC-2.10.009 specifies `alive` as a reported output verdict, violating DI-005 — the invariant it cites in its own Traceability row.

**Files / lines:**
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-10/BC-2.10.009.md:52-54`, `:71-72`, `:117`, `:85`
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/invariants.md:108-119`

**Defect.** DI-005 (`invariants.md:112-118`), reinforced by orchestrator ruling DD-022 (`invariants.md:28`), is unambiguous:

> **`alive` is NOT a fourth verdict.** ... `alive` is a *URL liveness outcome*; it maps to the link-level verdict `clean`. ... `clean` is the domain verdict that appears in report output and determines exit codes; `alive` is an internal HTTP-layer classification that **never appears in report output**.

BC-2.10.009 uses `alive` as a report-output verdict in three places:
- `:52-53` — PC2: *"The single verdict (**`alive`**, `broken`, or `indeterminate` per BC-2.10.002) is **reported** for every occurrence."*
- `:71-72` — Invariant 4: *"every occurrence produces an **output line** (if the verdict is **non-`alive`**)."*
- `:85` — Canonical Test Vector: *"Same URL **alive** at 3 locations | 1 HTTP request; 0 output findings"*

PC3 (`:54`) confirms "reported" means report output: *"Each occurrence is reported with its own correct source `file:line:column` in **text and JSON output**."* And `:117` — `| L2 Domain Invariants | DI-005 |` — cites the very invariant these postconditions contradict.

**Why it matters.** POL-12 verification step: *"Verify verdict labels: external URLs use alive/broken/indeterminate; internal links use clean/broken/indeterminate."* `alive` is legitimate at the HTTP layer — the defect is BC-2.10.009 carrying it across the layer boundary into the report/output vocabulary that DI-005 and DD-022 closed. An implementer coding PC2 literally emits `"verdict": "alive"` in JSON, which breaks the `api-surface.md:120` `Verdict` enum (`{Clean, Broken, Indeterminate}` — no `Alive` variant), breaks the `api-surface.md:128-134` JSON schema, and breaks NFR-007's closed-taxonomy parse test. Invariant 4's "non-`alive`" gate is also the wrong predicate for suppressing output lines: the correct rule is "verdict is not `clean`", which differs whenever a URL is `--allow`-suppressed or resolves clean by a non-HTTP path. `check-adr-consistency` (POL-12/POL-19's lint hook) scopes ADRs and reason codes, not BC verdict-label layering — so this survives the mechanical gate.

**Recommended fix.** `BC-2.10.009.md:52-53` → *"PC2. The single HTTP-layer liveness outcome (`alive`, `broken`, or `indeterminate` per BC-2.10.002) is memoized; the resulting link-level verdict (`clean` when the outcome is `alive`, otherwise `broken`/`indeterminate` per DI-005/DD-022) is reported for every occurrence."* `:71-72` → *"every occurrence whose link-level verdict is not `clean` produces an output line."* `:85` → *"Same URL `alive` at 3 locations (link verdict `clean`) | 1 HTTP request; 0 output findings."* Sweep sibling SS-10 BCs for the same layer leak in the same commit (`BC-2.10.001`, `BC-2.10.002`, `BC-2.10.004`, `BC-2.10.010` all discuss the HTTP layer and reporting together).

---

### P4-021 — MAJOR — `[process-gap]` — `check-index-integrity.py` advertises an HS-INDEX bidirectional check it does not perform; `get_actual_hs_files()` is dead code. (Includes the answer to routed item 1.)

**File / lines:** `/Users/jmagady/Dev/mdlinkcheck-cloud/scripts/spec-lint/check-index-integrity.py:5-11`, `:146-155`, `:315-334`, `:342`

**Routed item 1 — REFUTED that any ordering dependency exists; the diagnosis is confirmed as data-dependence.** I traced the `checks` counter. All intermediate collections are `set` or `dict`; every violation emission iterates via `sorted()`; the single unsorted iteration (`for bc_id, rel_path in bc_entries.items()` at line 232) affects only the *order* of appended violation strings, never the count, and Python dict insertion order is deterministic in file-line order. The counter is:

```
checks = 2 (BC phantom/unlisted) + len(bc_entries)      # line 234, inside the per-BC loop
       + 2 (VP) + 2 (ADR) + 2 (arch shard) + 2 (L2 shard)
       + 1 (HS duplicate, if HS-INDEX exists)
       = 11 + len(bc_entries)
```

`checks` is therefore a pure function of `len(get_bc_index_entries())`. The observed 74 → 75 transition corresponds **exactly** to `len(bc_entries)` changing by 1 (63 → 64), i.e. one BC-INDEX table row becoming regex-matchable. That is consistent with reading BC-INDEX.md mid-write and is **not** validator nondeterminism. **Confirmed.** Two follow-ups worth noting: (i) because `checks` is dominated by `len(bc_entries)`, the headline number is a *BC-INDEX row count* wearing the label "bidirectional checks", which is misleading — the actual distinct bidirectional checks are 10; (ii) `11 + len(bc_entries) = 75` implies `len(bc_entries) = 64`, not 66, so two BC-INDEX rows are not matching the line-30 regex (which requires a `[text](path)` markdown link in the row). Worth a one-line diagnostic, though it is count-class and I am not reporting it as a finding.

**Defect.** The module docstring (lines 5-11) advertises five bidirectional checks, including:

> `HS-INDEX   <-> holdout scenario files (no phantom entries, no unlisted files)`

That check does not exist. Lines 316-317 state: *"Full bidirectional HS-INDEX <-> wave-scenarios file check requires EC<->HS format mapping not yet implemented — **deferred to Phase 2**."* What actually runs (lines 319-334) is a duplicate-HS-ID scan. `get_actual_hs_files()` (lines 146-155) is defined and **never called** — dead code. Nothing verifies that an HS-INDEX entry has a scenario file, or that a scenario file is indexed.

**Why it matters.** POL-11's anti-pattern list includes jobs whose success signal over-claims what was validated. Line 342 prints `Check passed: {checks} bidirectional index checks passed` — a reviewer who read the docstring reasonably concludes holdout scenarios were bidirectionally validated. Holdout integrity is POL-18 territem (severity HIGH) and is the one class that *cannot be fixed retroactively* (`policies.yaml:324`: *"This check must pass before Phase 2 story decomposition begins — contamination cannot be fixed retroactively"*). A phantom HS-INDEX entry, or an unindexed scenario file sitting in `wave-scenarios/`, currently passes silently. Given that the stated deferral target is *Phase 2* and Phase 2 is the deadline this policy protects, the deferral is self-defeating.

**Recommended fix.** (a) Amend the docstring to state precisely what runs: `HS-INDEX <-> duplicate-ID scan only (bidirectional file check NOT implemented — see line 316)`. (b) Either delete `get_actual_hs_files()` or wire it up — the EC↔HS mapping is derivable: HS-INDEX links HS-NNN to EC-NNN, and scenario filenames start with `EC-NNN`, so extract the EC-NNN from each HS row and assert a `wave-scenarios/EC-NNN*.md` exists, plus the reverse. (c) Replace line 342 with a per-category breakdown so the number cannot be misread: `Check passed: 10 bidirectional checks over {len(bc_entries)} BCs, {len(vp_entries)} VPs, {len(adr_entries)} ADRs, {len(arch_docs)} arch shards, {len(l2_sections)} L2 shards`. Minor robustness note in the same pass: `get_l2_index_sections()` line 167's `if m and lineno < 60` is a hardcoded frontmatter boundary that will silently stop collecting declared shards once L2-INDEX's monotonically-growing changelog pushes the `sections:` list past line 60 — replace with an explicit `---` fence scan.

---

### P4-022 — MAJOR — `format_text` returns a single `String`, so the API surface cannot deliver the stdout-findings / stderr-summary split that three BCs and `bc-module-map` require.

**Files / lines:**
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/api-surface.md:107`, `:58-59`
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-12/BC-2.12.003.md:83`
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-12/BC-2.12.005.md:86`
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/bc-module-map.md:301`, `:303`

**Defect.** `api-surface.md:58-59` states the stream contract: *"Findings go to stdout only. Diagnostics, progress, and the summary line go to stderr only."* Three artifacts assign both strings to `reporter`:

- `BC-2.12.003.md:83` — `` `reporter.rs` ... primary; `main.rs` ... secondary — routes summary string to stderr; **reporter::format_text produces it** ``
- `BC-2.12.005.md:86` — `` ... secondary — writes findings to stdout; writes summary to stderr; **reporter produces both strings** ``
- `bc-module-map.md:301`, `:303` — same wording

But the declared signature (`api-surface.md:107`) is:

```rust
pub fn format_text(findings: &[Finding], opts: TextReportOpts) -> String;
```

One `String`. There is no second return value, no out-parameter, and no separate `format_summary` function anywhere in the Library API section (lines 61-112). `main` cannot route "the summary string to stderr" because no API produces it separately from the findings block.

**Why it matters.** The implementer has three bad options and will pick one silently: (a) concatenate summary into the returned `String` → the summary lands on **stdout**, violating `api-surface.md:58-59` and breaking `mdlinkcheck --format json > out.json` pipeability and the NFR-007 JSON parse test; (b) have `main` re-derive the summary by counting findings → business logic in the LOW-tier `main` module (≥70% kill rate), violating ADR-001's pure-core placement and `module-criticality.md:87` ("Thin glue; no business logic"); (c) invent an undeclared second function → API drift from the source-of-truth document. Note the JSON side is fine (`format_json` legitimately returns one document); the gap is text-format only.

**Recommended fix.** Add to `api-surface.md`'s reporter block:

```rust
// reporter.rs — CAP-012, CAP-013, pure
pub fn format_text(findings: &[Finding], opts: TextReportOpts) -> String;   // stdout body
pub fn format_summary(findings: &[Finding], io_errors: &[IoError]) -> String; // stderr summary line
pub fn format_json(findings: &[Finding]) -> String;  // schema_version: 1
```

or change `format_text`'s return to a `TextReport { pub findings: String, pub summary: String }` struct. Then update `BC-2.12.003.md:83` and `BC-2.12.005.md:86` to name the specific function that produces the summary, and add the same to `bc-module-map.md:301`/`:303`. Also confirm which BC owns the summary's *content* — BC-2.12.003 is the natural home and should carry a postcondition enumerating the summary line's fields.

---

## Observations

Grouped; each is grounded but below the MAJOR bar.

**P4-023 — MINOR — VP-026's Proof Method table names a JavaScript library as the Rust test tool.** `vp-026:179` — `| proptest | **fast-check** + serde_json oracle loader | ... |`. `fast-check` is a JS/TypeScript property-testing library. `vp-026:423` in the same document says `proptest 1.x`. Per the mis-anchoring rubric this contradicts elsewhere in the same document (HIGH class) but sits in a Tool column an implementer would immediately sanity-check. Fix: `| proptest | proptest 1.6.x + serde_json 1.x | ... |`.

**P4-024 — MINOR — VP-026 mixes github-slugger's stateless and stateful oracle APIs.** `vp-026:78-79` mandates each run be *"processed through a single fresh `Slugger` instance in order"* (the stateful class, correct for R-001's counter). `vp-026:146` and `:420` instead write `github-slugger@2.0.0.slug("config api new")` — the stateless export, which has no counter. For multi-entry runs the two APIs give different answers. Fix: state normatively in §Oracle Corpus Format that the generator MUST use `new GithubSlugger()` per run and call `.slug()` on that instance, and rewrite lines 146/420 to that form.

**P4-025 — MINOR — VP-026 states R-003's rendered text in lowercase.** `vp-026:132` and `:145` give the DI-012-rule-1 rendered text of `` ## `config` API <em>new</em> `` as `"config api new"`. The rendered text is `"config API new"` — lowercasing is step (b) of the slug algorithm, not part of rendering. Since the `heading` field of an oracle entry is what gets fed to `compute_slug`, encoding it pre-lowercased silently removes the case-folding step from R-003. Fix: `"config API new"` in both places.

**P4-026 — MINOR — `kani.toml`'s `default-unwind` is below the stated loop bound.** `tooling-selection.md:49` — `default-unwind = 8        # sufficient for slug duplicate counter (bound 10)` — and `:55` sets `heading count ≤ 10`. An unwind bound of 8 cannot unroll a 10-iteration loop; CBMC reports an unwinding-assertion failure. VP-003's own harness 2 (`vp-003:119`) assumes `n > 1 && n <= 10`, and its harness 3 (`vp-003:140`) needs an explicit `#[kani::unwind(32)]` override — evidence the default is known-insufficient. Fix: `default-unwind = 12` (bound + 2), and reconcile the trailing comment.

**P4-027 — MINOR — retired type name `DirEntries` survives in two files.** `module-criticality.md`'s own v1.2 changelog (`:28`) records *"fixed types inventory to list DirIndex/DirEntryInfo/EntryKind instead of stale DirEntries"* — and fixed line 66 only. `module-criticality.md:55` still reads *"**path_resolver** — pure NFC case-sensitive file existence check against pre-read **DirEntries**"*, and `ADR-006:63` (v1.2, 2026-08-05) still reads *"`DirEntries` are pre-populated by `scanner`"*. Superseded by `api-surface.md:87` (`pub type DirIndex = HashMap<PathBuf, Vec<DirEntryInfo>>`) and `purity-boundary-map.md:61`. Partial-fix regression, blast radius 2. Fix both to `DirIndex`.

**P4-028 — MINOR — `purity-boundary-map.md`'s changelog contradicts its own body and ADR-006's correction.** `purity-boundary-map.md:21` — *"**scanner** now feeds DirIndex via Pass 1.5 in app"* — while its body at `:77` and `:104` says `app` builds DirIndex, and `ADR-006:13`/`:98-99` (P2-M12 remediation) explicitly corrected this: *"'app' (not 'scanner') performs Pass 1.5 directory reads."* The same fix landed in `api-surface.md:19`/`:85` but not here. Fix: `"app now builds DirIndex via Pass 1.5 (scanner traverses only the scan root in Pass 1)"`.

**P4-029 — MINOR — two VP-025 harness rationales are factually wrong.** (a) `vp-025:194-195` and `:199` justify P3's sentinel with *"a unique suffix that cannot be any slug_string() key"* / *"5 decimal digits — no slug_string() ends with 5 digits"*. `slug_string()` is `"[a-z0-9][a-z0-9\\-_]{0,23}"`, which readily generates `a12345`. The property is nonetheless sound — the real guarantee is the uppercase `ABSENT_` prefix, correctly identified at `:202` — so the two comments contradict each other. (b) `vp-025:222` generates `key_lower in "[a-z]{2,12}"`, then `:226-227` guards *"If upper and lower are the same (e.g. all digits), skip"* — the strategy cannot produce digits, so the `prop_assume!` is unreachable; and *"at least 2 chars so toUpperCase() differs"* is wrong reasoning (one ASCII letter also differs). Fix: delete the false justifications at `:194-195`/`:199` and keep `:202`; delete the dead `prop_assume!` and its comment or widen the strategy to `[a-z0-9]{2,12}` so the guard is live.

**P4-030 — MINOR — `test-vectors.md` §7 and §8 both claim the T1–T16 range.** `:264` — `## §7. Slug Algorithm Vectors (**T1–T16** / DD-015 Worked Examples)`; `:289` — `## §8. Correctness Traps (**T1–T16**)`. §8's table maps T1..T16 to TV-NNN vectors drawn from §1–§6; **none** maps to a TV-S row. So §7's heading claim is simply wrong. This matters because POL-16's verification step pins the canonical trap map to *"test-vectors.md section 8 T1-T16"* — a BC citing "T3" is currently ambiguous between two sections. Fix: `## §7. Slug Algorithm Vectors (DD-015 Worked Examples)`.

**P4-031 — MINOR — `[process-gap]` — three of seven ADRs lack the `version:`/`changelog:` frontmatter the other four carry.** ADR-004 (v1.1), ADR-005 (v1.2), ADR-006 (v1.2), ADR-007 (v1.3) have both fields. ADR-001, ADR-002, ADR-003 have neither (`ADR-001:3-4`, `ADR-002:3-9`, `ADR-003:3-4`). Any future amendment to the pure-core boundary, the workspace layout, or the parser choice will be untracked and invisible to propagation audits — and ADR-001/ADR-002 are declared universal (`bc-module-map.md:43-45`: *"apply to every module and every BC"*), so they have the largest blast radius of the seven. Fix: add `version: "1.0"` and a `changelog:` stub with the initial-draft entry to all three; consider a schema check in `scripts/spec-lint/`.

**P4-032 — MINOR — VP-018's harness has no imports.** `vp-018:73-128` uses `compute_slug` and `DuplicateCounter::new()` with no `use` statement, unlike `vp-026:198` (`use mdlinkcheck_core::slug::{compute_slug, DuplicateCounter};`). As an integration test at `tests/unit/slug_corpus.rs` it cannot resolve either path. Fix: add the matching `use`. (See also P4-014 on the path itself.)

**P4-033 — MINOR — `module-criticality.md` labels its own summary lists with a superseded version.** `:179-180` — *"**CRITICAL modules (v1.3):** ..."* / *"**HIGH modules (v1.3):** ..."* in a document at `version: "1.5"` (`:4`). The membership is correct; only the label is stale. Related to P4-018 Defect D. Fix: `(v1.5)`, or drop the version qualifier so it cannot drift again.

**P4-034 — MINOR — the 10-second HTTP timeout is described as configurable in one BC, fixed in another, and has no CLI flag.** `BC-2.10.002:99` — *"Timeout (no response within **configured window**)"*; `BC-2.10.003:36`/`:46`/`:60` — a fixed *"total timeout of 10 seconds"* / *"10-second timeout applies per-URL total"*; `api-surface.md:41-51` declares no `--timeout` option. "Configured window" invites an implementer to add a flag (scope creep past the D-011 non-goal set) or to read an undocumented env var. Fix: `BC-2.10.002:99` → *"Timeout (no response within the fixed 10-second per-URL window per BC-2.10.003)"*.

**P4-035 — MINOR — the concurrency caps are "an architectural constant" in one ADR and "advisory defaults" in the system overview.** `ADR-005:71-72` — *"The 32-thread HTTP pool size is fixed and does not scale with CPU count; this is an **architectural constant, not a heuristic**"*, echoed by `ADR-004:85` (*"always sized at exactly 32"*). `system-overview.md:171` — *"Both limits are **advisory defaults**, not configurable in v1.0 (BC-2.10.008)."* "Advisory" implies non-binding, which contradicts BC-2.10.008's caps and ADR-004:87-88's *"at most 32 HTTP requests are in-flight at any instant."* Fix: `system-overview.md:171` → *"Both limits are hard caps, not configurable in v1.0 (BC-2.10.008, ADR-004)."*

**P4-036 — MINOR — DI-008's title is misquoted, and two documents still call it a two-pass constraint.** `gene-transfusion-assessment.md:199` — *"DI-008 (\"Anchor Table Built **Two-Pass**\") is already a domain invariant"*; DI-008's actual title (`invariants.md:198`) is "Anchor Table Built Before Any Incoming Link Is Validated". `event-flow.md:102-104` — *"## Two-Pass Constraint Detail / The **two-pass** constraint (DI-008)..."*, and `:55` — *"(two-pass constraint DI-008)"*. POL-17 verification step: *"For each DI-NNN entry ..., verify description matches domain-spec/invariants.md."* Secondary loci for the P4-003 sweep; separated here because these are description/label drift rather than an implementer-facing pipeline-shape claim.

**P4-037 — MINOR — `[process-gap]` — accepted ADRs carry unresolved action items directed at other artifacts.** `ADR-005:109` (`status: accepted`) embeds *"**product-owner scope: add postcondition** that findings are at use-site positions"* — still open, and load-bearing for the ADR's own soundness (see P4-005). `ADR-004:86-88` embeds *"BC-2.10.008 **should state**: 'A dedicated rayon thread pool of size 32...'"* — that one was satisfied (`prd.md:610`) but the directive was never removed, so the two cases are indistinguishable on inspection. Because `status: accepted` is what the Phase 1 gate keys on, an ADR can be accepted with its correctness argument depending on unwritten content elsewhere. Recommend a rule: an ADR may not carry `status: accepted` while its body contains an unresolved directive at another artifact; such items move to a tracked `open_dependencies:` frontmatter list that the gate checks, and are deleted from the body on closure. Candidate for a ninth validator: flag `status: accepted` ADRs containing `should state`, `scope: add`, `TODO`, or `not yet` in the body.

**P4-038 — OBSERVATION (no action) — two self-declared coverage gaps in `test-vectors.md` §8 are correctly recorded and I am not counting them as findings.** `:310` T16 *"not-covered — ... boundary enforcement for root-relative paths is untested"* with full rationale, and `:307` T13 Windows path separators *"partially covered"* by TV-042 alone despite `nfr-catalog.md:94`'s explicit portability note. Both are honestly labelled. Flagging only so a future pass does not re-derive them as new: T13's thinness is worth a vector before Phase 3, since NFR-004 requires a 100% Windows pass.

---

## Prior-Pass Regression Audit (Partial-Fix Discipline)

I cannot see passes 1–3, so I audited the fix *traces* embedded in changelogs and re-verified each against the files. Results:

| Prior fix (per changelog) | Propagated? | Evidence |
|---|---|---|
| `module-criticality.md` v1.5: slug row DI-003 → DI-012/DI-013 | **Primary fixed; siblings not** | `:19`/`:72` correct. But DI-012/DI-013 reached **no BC** → P4-007. Routed item 2 answer below. |
| `invariants.md` v1.5/v1.6: DI-012/DI-013 added, falsifying methods updated | **No** | BC-2.06.001:114 / BC-2.06.002:97 still cite DI-008 → P4-007 |
| ADR-005 v1.2: `dest` 4th sort field | **No** | 5 artifacts still 3-field → P4-004 |
| `module-criticality.md` v1.2 (INC-008): `DirEntries` → `DirIndex/DirEntryInfo/EntryKind` | **Partial** | `:66` fixed, `:55` not; `ADR-006:63` not → P4-027 |
| ADR-006 v1.2 / api-surface v1.3 (P2-M12): scanner → app for Pass 1.5 | **Partial** | `purity-boundary-map.md:21` not → P4-028 |
| `system-overview.md`: two-pass → three-phase; `prd.md:654` BC H1 + BC-INDEX | **Partial** | ARCH-INDEX:30, module-criticality ×4 not → P4-003 |
| VP-018 v1.2 / VP-026 v1.0 (BI-005) Rule-1 vectors | **Not to source BC, not to registry** | BC-2.06.001:73-76 contradicts → P4-001; not added to test-vectors §7 → P4-017 |
| VP-025 (INC-MAP-001 closure) | **Marked RESOLVED on a broken spec** | `bc-module-map.md:386` vs `api-surface.md:77`/`:92`/`:120` → P4-002 |
| VP-011 v1.1 (P2-M16): DI-001 binary-output harness added | **Added but does not implement DI-001's falsifying method** | `vp-011:108`, `:128` same-thread-count only → P4-006 |
| ADR-004 v1.1 / ADR-005 v1.1 (F-010): dedicated 32-thread pool | **Yes — verified clean** | `ADR-004:38-48`, `:85-88`; `ADR-005:66-72`; `BC-2.10.008` per `prd.md:610`. No finding. |
| `assumptions.md` (DD-021): ASM-005/ASM-008 holdout designation removed | **Yes — verified clean** | `:19`, `:49-51`. POL-18 step 4 concern resolved; no finding. |
| VP-026/VP-025 → verification-architecture + VCM (POL-9) | **Yes — verified clean** | `verification-architecture.md:72-73`, `:143-148`; `verification-coverage-matrix.md:74-75`, `:101`, `:108`. One overclaim inherited from VP-026 → P4-009. |

**The dominant regression pattern is unambiguous: 8 of 12 audited fixes were applied to the primary artifact and not to its siblings or dependents.** Not one of the 8 is a content error in the fix itself.

---

## Routed Items — Direct Answers

**1. `check-index-integrity.py` — ordering dependency?** **REFUTED; original diagnosis CONFIRMED.** No ordering dependency exists. Full derivation in P4-021. `checks = 11 + len(get_bc_index_entries())`; every collection is a `set`/`dict`, every emission is `sorted()`, the one unsorted iteration affects only violation ordering, and dict order is deterministic in file-line order. The 74→75 delta is exactly one BC-INDEX row becoming regex-matchable — consistent with a read against an in-flight write. I did find a *different* defect in that file (dead `get_actual_hs_files()`, docstring over-claim on the HS-INDEX bidirectional check) — reported as P4-021.

**2. Other wrong DI ids in `module-criticality.md`?** **NO — the file is clean on this axis.** I checked all 17 rows of the Module Classification table (`:72-88`) against `invariants.md`: `slug`→DI-012/DI-013 ✓ (`:72`); `verdict`→DI-010/DI-011 ✓ (`:74`); `path_resolver`→DI-002 ✓ (`:78`); `scanner`→DI-009 ✓ (`:83`). Rows citing no DI (`fragment`, `http_verdict`, `anchor_table`, `anchor_resolver`, `link_extractor`, `filter`, `reporter`, `url_classifier`, `http_client`, `app`, `cli`, `main`, `types`) cite only VPs, which resolve correctly. Two adjacent observations: `fragment` (`:73`) omits DI-003, its governing invariant, though DI-003 is correctly cited by BC-2.07.001/002/004 and BC-2.08.001/003; and `reporter` (`:81`) omits DI-001 while `:81` claims *"sort determines VP-011 determinism guarantee"* — folded into P4-019, which is the substantive version of that problem. **The DI-003 mis-citation was an isolated instance, not a pattern.**

**3. Citations that resolve but are semantically wrong.** This was the highest-yield axis, as predicted — **8 of the 22 findings at MAJOR or above** are in this class, invisible to all 8 validators:

| Finding | Cited (resolves) | Should be | Why the checker misses it |
|---|---|---|---|
| P4-007 | DI-008 in BC-2.06.001/002 | DI-012 / DI-013 | DI-008 exists; POL-2's orphan check is unautomated (`lint_hook: null`) |
| P4-008 | ADR-006 for `slug` (×6 loci) | a slug ADR (none exists) | ADR-006 exists and is in `subsystems_affected: [SS-06]` |
| P4-005 | "BC-2.03.002 postcondition" | a postcondition that isn't written | BC-2.03.002 exists; no checker validates *claims about* a BC's content |
| P4-016 | SS-11 for `cli.rs` (×4) | unregistered module | SS-11 exists in ARCH-INDEX |
| P4-004 | `dest` in ADR-005's sort key | `link_target` | struct-field references aren't in any ID family |
| P4-017 | test-vectors §7 as NFR-006 inputs | a corpus VP-018 doesn't implement | §7 exists; no checker diffs a VP corpus against a registry |
| P4-036 | DI-008 titled "Anchor Table Built Two-Pass" | actual DI-008 title | ID resolves; POL-17's description-match step is unautomated |
| P4-030 | "T1–T16" in §7's heading | §8's range | no ID resolution involved — a heading label |

The structural driver: `check-id-resolution` validates that `X` exists; nothing validates that *the sentence containing X is true about X*. The one durable fix is to stop hand-writing these cells — see the verdict.

---

## Novelty Assessment

**Novelty: HIGH — and that is bad news.** These are not rewordings. Three findings are CRITICAL (an irreconcilable slug-rendering contradiction on the headline differentiator; a VP written against an API that does not exist; the architecture index describing the wrong pipeline shape). Nineteen more are MAJOR. Not one falls in the seven mechanically-enforced classes.

The findings cluster in exactly the unread perimeter the dispatch predicted:
- **VP bodies (never read before this pass):** 9 findings (P4-002, P4-006, P4-009 – P4-013, P4-023 – P4-026, P4-029, P4-032)
- **Architecture shards (8 never read):** 6 findings (P4-002, P4-003, P4-014, P4-018, P4-019, P4-022)
- **ADR bodies (5 never read):** 3 findings (P4-005, P4-008, P4-031, P4-037)
- **Cross-document interaction clusters:** 4 findings (P4-004+P4-005+P4-006+P4-019 form one chain around DI-001; P4-015 and P4-020 in the HTTP cluster)
- **Semantically-wrong-but-resolving citations:** 8 findings

On the specific new work I was asked to attack hard: **VP-026 does *not* fully close FM-002 in the way it claims.** The narrow FM-002 question — 0-based vs 1-based counter — *is* genuinely closed, and closed twice over, by `vp026_fm002_discriminator_0_based_counter` (`vp-026:264-276`) and `vp018_duplicate_heading_counter_0_based()` (`vp-018:150-169`), both of which hardcode the expected values independently of the corpus and therefore survive corpus truncation. That is good, defensible work. But the surrounding claim — *"All seven DI-012 rules are covered independently"* (`vp-026:46-48`, `:127-128`) — is false on four counts: Rule 1 has no enabled falsifying clause (P4-010); Rules 5 and 6 have no proptest arm because the strategy function is dead code (P4-009); the corpus test passes vacuously on a truncated corpus (P4-012); and the harness file would not be compiled by Cargo at all (P4-014). The pinned-corpus oracle approach is architecturally sound — a committed fixture with an embedded version pin and a regeneration check is the right design — but its provenance mechanism is self-defeating as specified (P4-011), and the toolchain it needs is unprovisioned (P4-018).

**Did mechanical enforcement bend the novelty curve? Partially — it bent the *composition* decisively and the *magnitude* not at all.**

The curve reads 32 → 34 → 39 → **22 at MAJOR+ (37 total)**. Do not read that as improvement; the drop is my raised severity bar, not a reduced defect population.

What enforcement unambiguously achieved: **it eliminated an entire noise floor.** Zero of my 37 findings are title drift, EC collisions, dangling IDs, arithmetic, holdout leakage, ADR exit codes, or index integrity. I spot-checked several of these opportunistically and the validators are genuinely holding — VP-026 propagated correctly to both architecture anchor documents (POL-9), the ASM-005/ASM-008 holdout designations are correctly resolved (POL-18), and the ADR/BC ID graph resolves. That is real, and it is why this pass could spend its entire budget in the semantic perimeter. Prior passes could not.

What enforcement did **not** touch: **the defect-generation mechanism.** This spec set restates the same fact in many hand-maintained places. Six examples from this pass alone:

| Fact | Restated in | Consistent? |
|---|---|---|
| The DI-001 sort key | DI-001, ADR-005, system-overview ×2, api-surface, VP-011 | **No** — 3-field vs 4-field, and a nonexistent struct field |
| `AnchorTable`'s type | api-surface, VP-025 ×2, bc-module-map, module-criticality | **No** — 3 incompatible answers |
| The pipeline's pass count | ARCH-INDEX, module-criticality ×4, system-overview, DI-006/008/009, entities, event-flow ×3, BC-2.05.001, bc-module-map | **No** — two-pass vs three-phase |
| Module → subsystem | ARCH-INDEX registry, ~50 BC "Architecture Module" rows, bc-module-map | **No** — `cli`→SS-11 ×4 |
| Module → ADR | ARCH-INDEX, ~50 BC rows, bc-module-map ×14 headers | **No** — slug→ADR-006 ×6 |
| Slug golden vectors | test-vectors §7, VP-018 corpus, VP-026 oracle, BC-2.06.001 vectors, DI-012 falsifying cases | **No** — 2/16 overlap |

Eight validators cannot fix this, and adding a ninth, tenth, and eleventh will not either — the checks required are of the form "is this English sentence a true statement about that artifact," which is unbounded. Passes 1–3 escalated because the reviewer sampled a wide surface and found many instances of a few underlying causes; this pass read deeply and found the causes. The 8-of-12 partial-fix rate in the regression audit is the same phenomenon measured from the other end: **every fix must be applied N times, and N is unknown to the fixer.**

The structural conclusion, stated plainly for the orchestrator: **the remaining defect mass is not a spec-quality problem, it is a spec-topology problem.** The correct next move is not pass 5 with the same topology. It is to **generate the derived cells** — exactly the pattern `bc-module-map.md` already establishes for BC→module and `VP-INDEX` for VP→module. Concretely, three generators would structurally eliminate five of the six rows above and, by my count, **11 of my 22 MAJOR+ findings** (P4-003, P4-004, P4-007, P4-008, P4-016, P4-017, P4-019, P4-022, P4-027, P4-028, P4-036):

1. **`gen-bc-traceability.py`** — emit each BC's `Architecture Module`, `Key ADRs`, `L2 Domain Invariants`, and `Verification Properties` rows from ARCH-INDEX + bc-module-map + invariants + VP-INDEX. Kills P4-007, P4-008, P4-016, plus the `cli`→SS-11 and slug→ADR-006 classes permanently.
2. **`gen-slug-corpus.py`** — emit VP-018's `SLUG_CORPUS` from `test-vectors.md` §7. Kills P4-017 and makes P4-001's adjudication propagate automatically.
3. **A single canonical-facts block** (sort key, `AnchorTable`/`Finding` field names, pass count, `Verdict` variants) declared once in `api-surface.md` + `invariants.md`, with a checker that greps for divergent restatements. Kills P4-002, P4-003, P4-004, P4-019, P4-022, P4-027, P4-028, P4-036.

Two findings should be treated as gating regardless of topology work, because they invalidate verification *results* rather than spec text: **P4-014** (ten VP harnesses at Cargo-undiscoverable paths — every one of them would report green while never executing) and **P4-012** (VP-026's oracle test passes on an empty corpus). Ship neither Phase 3 nor the Phase 6 gate criteria until both are closed. **P4-001** is the single highest-value item to adjudicate first, because two Phase-3 golden vectors and the source BC currently demand opposite behaviour from the product's differentiating algorithm, and every day it stays open is a day someone might build against the wrong one.

---

## Verdict

**FINDINGS_REMAIN**

| Severity | Count |
|---|---|
| CRITICAL | 3 |
| MAJOR | 19 |
| MINOR | 15 |
| **Total** | **37** |

Process-gap tagged: 3 (P4-021, P4-031, P4-037). Content defects: 34.

**Did mechanical enforcement bend the novelty curve?** It bent the composition, not the magnitude. Enforcement removed the seven classes completely and permanently — that is a real, verified win and it is what made this pass's depth possible. It did not reduce the defect population, because the defect *source* is that ~15 documents hand-maintain restatements of the same facts with no generated source of truth. **The 32→34→39 escalation was not a spec-quality failure; it was passes 1–3 sampling many instances of a few topological causes. The causes are now named.** Recommendation: do not run pass 5 against the current topology. Land the three generators plus the canonical-facts block, adjudicate P4-001, close P4-014 and P4-012, then run pass 5 — at which point the semantic perimeter is small enough that novelty should genuinely decay.