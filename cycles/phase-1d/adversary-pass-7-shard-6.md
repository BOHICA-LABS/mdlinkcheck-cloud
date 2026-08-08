---
document_type: adversarial-review
level: ops
version: "1.0"
status: final
producer: adversary
timestamp: 2026-08-08T00:00:00Z
cycle: phase-1d
pass: 7
shard: 6
frozen_develop_head: f8ee4eb024b8b4a300139ef803d248e8fe40f2fc
frozen_specs_tree: ace1745871122cd1fa2c46cf27c5493cc1083411
frozen_spec_lint_tree: f2392b456c3bd669e3efbe86b3e6eae62e302ed1
severity_vocabulary: "CRITICAL/HIGH/MEDIUM/LOW (single vocabulary per PG-012 ruling)"
findings_total_self_declared: 27
inputs: []
input-hash: "ace1745"
traces_to: STATE.md
---
# Pass 7 — Shard 6: 8 ADRs + 11 architecture documents

```
scope: "8 ADRs + 11 architecture docs = 19 documents read in full"
files_read_in_full:
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/decisions/ADR-001-pure-core-effectful-shell.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/decisions/ADR-002-workspace-layout.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/decisions/ADR-003-pulldown-cmark.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/decisions/ADR-004-ureq-sync-http.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/decisions/ADR-005-rayon-sort-before-emit.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/decisions/ADR-006-strict-path-model.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/decisions/ADR-007-three-verdict-model.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/decisions/ADR-008-slug-clean-room-reimplementation.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/ARCH-INDEX.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/system-overview.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/module-decomposition.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/api-surface.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/purity-boundary-map.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/dependency-graph.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/bc-module-map.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/feasibility-review.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/tooling-selection.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/verification-architecture.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/verification-coverage-matrix.md
reference_files_read (for claim-checking, not in scope for findings):
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/prd-supplements/error-taxonomy.md (full)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/VP-INDEX.md (full)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-007-http-verdict-total.md (full)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-025-anchor-resolver-totality.md (full)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-03/BC-2.03.002.md (full)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-06/BC-2.06.001.md (full)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-10/BC-2.10.008.md (full)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/decisions.md (partial: lines 59-98)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/invariants.md (partial: DI-001, DI-012)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/product-brief.md (partial: R1-R8)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/planning/market-intelligence.md (partial: §4.3 traps table)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/scripts/spec-lint/check-placeholders.py (full)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/scripts/spec-lint/check-adr-consistency.py (full)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/scripts/spec-lint/check-counts.py (full)
findings_total: 27
severity_counts: CRITICAL 3 / HIGH 12 / MEDIUM 8 / LOW 4
verdict: NOT CONVERGED — three CRITICAL defects, including an architecture directive that would break the spec-lint gate on 33 BC files, an authoritative API surface that makes the sole DNS/TLS verification property unprovable, and an ADR whose decisive parser rationale is factually wrong about pulldown-cmark.
```

---

## STALE-DIRECTIVE ROSTER

Predicate: `must be updated|status: open|action required|TBD|to be decided|pending|outstanding|not yet|HANDOFF|under review|deferred|open dependency|OPEN` (case-insensitive) over `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/` → **37 matching lines across 12 files**. Rows below are the substantive directives (changelog-only recitations of past remediation are excluded; "Status as of / not yet implemented (Phase 3 scope)" boilerplate is collapsed into a single row).

| file:line | directive text | already done? | still outstanding? | would mislead a story-writer? |
|---|---|---|---|---|
| bc-module-map.md:42-45 | "**Product-owner action required (POL-14):** … 55 BC files currently place `test-sufficient` in the `VP-NNN` column, which violates POL-14. That string belongs in the `Proof Method` column only. Use the 'VP-NNN Column Value' column … as the authoritative correction source." | No — and the underlying policy has been **inverted** | No | **YES — actively harmful.** `test-sufficient` is now a *legal* sentinel (check-placeholders.py:31-36, 177-205); `none` is explicitly non-conforming (check-placeholders.py:172, 219). Acting on this breaks the gate. See P7-S6-001 |
| bc-module-map.md:462-490 | "§POL-14 Defect Report … For each BC where the 'VP-NNN col value' column … shows `none`, the product-owner should update the BC file's Verification Properties table to `\| none \| … \|`" | No | No | **YES — same as above; this is the executable half of the directive** |
| bc-module-map.md:487-490 | "The checker (`scripts/spec-lint/check-placeholders.py`) reported 55 BCs with `test-sufficient` in the VP-NNN column." | Stale magnitude | — | YES — 53 rows / 33 files by predicate; "55" matches neither |
| ADR-004:82-89 | "`BC-2.10.008` Invariant 3 must NOT reference 'available rayon thread count' … BC-2.10.008 must be updated to match (product-owner scope)." | **YES** — BC-2.10.008 v1.3 Invariant 3 already reads "dedicated rayon thread pool of fixed size 32" (BC-2.10.008.md:57-59) | No | YES — dispatches a product-owner to a no-op and implies an open contract gap. See P7-S6-019 |
| ADR-005:10-15 (frontmatter `open_dependencies: … status: open`) | "DEP-001 / BC-2.03.002 / requirement: Add postcondition PC7: for all reference forms, the reported Finding position is the use site … Required for sort key totality argument" | **YES** — BC-2.03.002 v1.3 already carries PC7 (BC-2.03.002.md:54-57) *and* Invariant 4 (lines 63-66) | No | YES — machine-readable `status: open`; a consumer concludes DI-001 sort-key totality is undischarged, and a product-owner would add a duplicate PC8. See P7-S6-006 |
| ADR-005:49, :97, :122 | "see BC-2.03.002 postcondition — tracked as open dependency DEP-001 in frontmatter" ×3 | YES (same as above) | No | YES — same defect propagated to three body sites |
| ADR-008:73-75 | "**BC-2.06.001 Invariant 2** currently states the opposite (text DISCARDED) — this is a BC-level error. See product-owner handoff item …: BC-2.06.001 Invariant 2 must be corrected to match DI-012 rule 1." | **YES** — BC-2.06.001 v1.4 already retains HTML text (BC-2.06.001.md:75-81) | No | **YES — harmful.** The claim "currently states the opposite" is false; an auditor trusting the ADR could "restore" the DISCARDED wording and regress the headline differentiator. See P7-S6-007 |
| ADR-006:174 | "D-006: Case-sensitive NFC path comparison requirement (not portability — that is NFR-004 scope, **now under review for macOS-only**)" | YES — NFR-004 is RETIRED (nfr-catalog.md:83 `## NFR-004: Platform Portability — RETIRED (D-043)`; feasibility-review.md:67-73; tooling-selection.md:65) | No | Mildly — implies an open D-043 review that closed. See P7-S6-023 |
| bc-module-map.md:390-412 | "INC-MAP-001 … Status: SPEC-RESOLVED / IMPL-PENDING … *Implementation obligation (NOT yet discharged, BI-010):* Phase 3 must implement `anchor_resolver`, make VP-025 green" | Spec half: yes | **Yes — genuinely outstanding** (no Rust workspace exists) | No — correctly scoped and correctly labelled |
| tooling-selection.md:168-182 | "Phase 3 CI Obligations … The following CI jobs do not yet exist (confirmed: no `perf-gate`, `NFR-008`, `hyperfine`, or `bench` entry in `.github/workflows/`) … BOTH MUST be configured on `macos-latest`" | No | **Yes — genuinely outstanding** | No — **claim verified TRUE**: predicate `perf\|bench\|hyperfine\|NFR-008\|macos\|runs-on` (-i) over `.github/workflows/` returns 26 lines, **zero** of which are a perf/bench/hyperfine job |
| verification-architecture.md:79 | "Rule 1 rendering fidelity (inline-code+HTML) is a Phase 3 integration obligation (Rule 1b …)" | No | Yes — genuinely outstanding | No |
| ADR-001:70-73, ADR-002:74-77, ADR-003:71-73, ADR-004:91-93, ADR-005:104-106, ADR-006:151-157, ADR-007:132-136, ADR-008:151-153 | "Accepted. … not yet implemented (Phase 3 scope)." ×8 | No | Yes — genuinely outstanding | No — correct Phase-1b status boilerplate |
| ADR-001:68 / ADR-003:55 / ADR-008:145 | "Adding I/O to a pure-core module requires an ADR update" / "record this in a future ADR superseding ADR-003" / "the clean-room implementation must be updated manually" | n/a — conditional future policies | n/a | No |
| feasibility-review.md:337 | "No action required on the PRD." | n/a | n/a | No |

**ADR status audit (accepted-while-superseded trap):** all 8 ADRs carry `superseded_by: null` and none has been wholesale retired. However **ADR-001 is `status: accepted`, `version: "1.0"`, with no changelog, while the design element it names as "the key constraint" was retired by SR-016** — see P7-S6-004. That is the closest instance of the accepted-but-superseded trap in this shard.

---

## UNDEFINED-TYPE ROSTER

Definition predicate executed: `(enum|struct|type)\s+(PathVerdict|OffsetEvent|PcEvent|FailureReason|LinkKind|TextReportOpts|ReportOpts|AllowPrefix|IoError|HttpResult|CliArgs|Attempt|Prefix|Link)\b` over `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs` → **0 matches**.
Usage predicate executed: `PathVerdict|OffsetEvent|PcEvent|FailureReason|LinkKind|TextReportOpts|ReportOpts|AllowPrefix|IoError|HttpResult|CliArgs|NormalizedUrl` over the same tree → **72 occurrences across 22 files**.
Supplementary predicate: `HttpError|VerdictKind|AnchorIndex|LinkMap|classify_response_with_error|build_with_html` over the same tree → 70 lines; `HttpError`, `VerdictKind`, `classify_response_with_error` occur **only** in `vp-007-http-verdict-total.md`.

| type name | cited at file:line | defined anywhere? (predicate) |
|---|---|---|
| `PathVerdict` | api-surface.md:89 (`resolve_path → PathVerdict`); module-decomposition.md:53; purity-boundary-map.md:58; system-overview.md:170; **vp-024:43,44,99,100,103,118** | **NO** — 0 matches. Not in api-surface.md "Key Shared Types" (lines 120-127) |
| `FailureReason` | api-surface.md:123,124 (`Broken(FailureReason)`); vp-024:43,44,99,100; entities.md:69,111 | **NO** — 0 matches. Variant names `FileNotFound`/`TargetIsDirectory` used in vp-024 with no declared mapping from the 13 kebab-case reason codes |
| `IoError` | api-surface.md:111,115; module-decomposition.md:59,136; purity-boundary-map.md:64; system-overview.md:179,253,272,273; vp-005:41; vp-006:73; vp-016:321,324 | **NO** — 0 matches |
| `OffsetEvent` | api-surface.md:85; purity-boundary-map.md:93 | **NO** — 0 matches |
| `PcEvent` | module-decomposition.md:52 | **NO** — 0 matches (and it is a second name for `OffsetEvent`) |
| `TextReportOpts` | api-surface.md:110 | **NO** — 0 matches |
| `ReportOpts` | module-decomposition.md:58 | **NO** — 0 matches (second name for `TextReportOpts`) |
| `AllowPrefix` | api-surface.md:107 | **NO** — 0 matches |
| `Prefix` | module-decomposition.md:57 | **NO** — 0 matches (second name for `AllowPrefix`) |
| `LinkKind` | api-surface.md:126 (`ExtractedLink.kind`) | **NO** — 0 matches |
| `Attempt` | module-decomposition.md:56; bc-module-map.md:243,244,257 | **NO** — 0 matches (second name for `HttpAttempt`) |
| `HttpResult` | purity-boundary-map.md:81; module-decomposition.md:80 | **NO** — 0 matches |
| `CliArgs` | module-decomposition.md:78; purity-boundary-map.md:82; bc-module-map.md:306 | **NO** — 0 matches |
| `Link` | module-decomposition.md:60 (`types` module key types); entities.md:67 | **NO** — 0 matches for a Rust declaration; `Link` exists only as a prose domain entity (entities.md §Link) |
| `HttpError` | vp-007:133,138,143,169 | **NO** — occurs only inside VP-007's harness |
| `VerdictKind` (incl. `VerdictKind::Alive`) | vp-007:88,98,105,115,120,134,139,144,159,161 | **NO** — contradicts api-surface.md:124 `enum Verdict { Clean, Broken(..), Indeterminate(..) }`, which has no `.kind` field and no `Alive` variant |
| `classify_response_with_error` | vp-007:133,138,143,166,169 | **NO** — not on api-surface.md's declared surface (predicate `^pub fn ` over api-surface.md → 12 `pub fn` lines, none named this) |
| `AnchorIndex` | system-overview.md:109,144-165; module-decomposition.md:114; BC-2.05.001:45-91; BC-2.14.004:58 | **Described inline** (`HashMap<PathBuf, AnchorTable>`) but **never declared** in api-surface.md — contrast `pub type DirIndex` at api-surface.md:90 |
| `LinkMap` | system-overview.md:110,119,139,146; module-decomposition.md:115,118 | **Described inline** but never declared in api-surface.md |
| `build_with_html` | api-surface.md:82 | Declared but **orphan** — appears nowhere else in the corpus (module-decomposition, bc-module-map, BC-2.05.003, VP-020 all omit it) |

---

## Findings

### P7-S6-001 — bc-module-map's POL-14 Defect Report prescribes exactly the value the POL-14 checker rejects, across 33 BC files [CRITICAL]

`bc-module-map.md:42-45` and `bc-module-map.md:462-490` instruct the product-owner to replace `test-sufficient` in every BC's `VP-NNN` column with the literal `none`:

```
bc-module-map.md:476-480
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| none | [property description] | integration / acceptance test |
```

The POL-14 checker is `scripts/spec-lint/check-placeholders.py`. Reading it (D-057 — no skip-list assumption):

- `check-placeholders.py:31-36` and `:161-205`: `test-sufficient` in the `VP-NNN` column is an **operator-ruled legal sentinel**, admitted when (a) VP-INDEX classifies that BC as `test-sufficient` (runtime JOIN, D-039) and (b) the `Proof Method` cell is non-empty (D-078).
- `check-placeholders.py:172` and `:219`: "Everything else (em-dash, en-dash, TBD, **none**, empty, etc.) is non-conforming" → `return False, f"non-conforming VP-NNN column value '{first_cell}' (POL-14)"`.

So `none` is an explicit POL-14 violation and `test-sufficient` is the required value. The directive is inverted. `ARCH-INDEX.md:46` advertises this document as carrying "POL-14 defect guidance", giving the inverted directive index-level authority.

Positive-coverage evidence that the checker actually runs over these shapes: `check-placeholders.py:409` emits `Check passed: {files_checked} spec files checked — no VP-TBD, SS-TBD, [filled by], or non-conforming VP-NNN column values`, with `files_checked` computed at `:385` from the actual `rglob("*.md")` walk — a runtime-computed count over the shapes present.

**Predicate:** `^\| test-sufficient \|` over `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts` → **53 occurrences across 33 files**. `\| none \|$` over `bc-module-map.md` → **33 occurrences** (the map's prescribed replacements). The document's own magnitude claim at `:44` and `:487` is "55 BC files" / "55 BCs", which matches neither 53 (rows) nor 33 (files).

**Consequence:** A product-owner executing this documented, index-endorsed remediation converts 53 conforming rows in 33 BC files into 53 POL-14 violations and red-lights the spec-lint gate for the whole corpus. Additionally the stale "55" magnitude makes the remediation unverifiable (no predicate can confirm completion).

**Tag:** [process-gap] — the root cause is that a policy inversion landed in the checker (commit `d4e76fa` "feat(pol14): test-sufficient VP sentinel") with no propagation step to the architecture document that carries the POL-14 remediation instructions.

---

### P7-S6-002 — api-surface.md provides no representation for transport-level failures or the ADR-007 Layer-2 outcome, making VP-007's DNS/TLS assertions unprovable [CRITICAL]

`api-surface.md:102-103` declares the entire http_verdict surface:

```
pub fn classify_response(status: u16, attempt: HttpAttempt) -> Verdict;
pub enum HttpAttempt { Head, GetFallback }
```

and `api-surface.md:124` declares `pub enum Verdict { Clean, Broken(FailureReason), Indeterminate(FailureReason) }`.

Against that surface:

1. **DNS failure and TLS failure have no representable input.** A DNS resolution failure and a TLS handshake failure produce *no HTTP status code*. `status: u16` is non-optional and `HttpAttempt` has exactly two variants, neither of which encodes a transport error. Yet `verification-architecture.md:65` states VP-007 proves "`dns-failure` and `tls-error` produce `broken`", and VP-INDEX assigns **VP-007 as the sole VP for BC-2.10.005 (DNS→broken) and BC-2.10.006 (TLS→broken)** (VP-INDEX.md:226-227).
2. **ADR-007's Layer 2 has no type.** ADR-007:46-51 defines a Layer-2 URL Liveness Outcome (`alive`/`broken`/`indeterminate`) distinct from the Layer-1 link verdict, and ADR-007:53 states `alive` "is NOT a fourth link verdict". No architecture document declares any type for Layer 2 — `purity-boundary-map.md:61`, `module-decomposition.md:56` and `api-surface.md:102` all give `classify_response` the Layer-1 `Verdict` return type. The two-layer model of an accepted ADR is therefore unrepresentable on the authoritative API surface.
3. **The verification artifact confirms the hole rather than resolving it.** VP-007's harness invents four symbols that exist nowhere in the corpus: `classify_response_with_error` (vp-007:133,138,143), `HttpError::{DnsFailure,TlsError,Timeout}` (vp-007:133,138,143), `VerdictKind::Alive|Broken|Indeterminate` with a `.kind` field (vp-007:87-88, 98, 105, 115, 120, 159-161), and `HttpAttempt::Get` (vp-007:158 — api-surface declares `GetFallback`, not `Get`). VP-007:166-172 openly defers the question: "The exact API signature for network-error verdicts … depends on whether the implementation uses a combined `(u16, HttpAttempt)` type with error-encoding status codes, or a separate `classify_error(HttpError) -> Verdict` function."
4. **bc-module-map.md contradicts the declared type.** `bc-module-map.md:243` and `:244` annotate BC-2.10.005/006 as: http_client "detects DNS failure; encodes it into **Attempt enum** for http_verdict". No `Attempt` enum exists (see UNDEFINED-TYPE ROSTER), and `HttpAttempt` as declared cannot carry that encoding.

**Predicate:** `HttpError|VerdictKind|classify_response_with_error` over `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs` → occurrences confined to `vp-007-http-verdict-total.md` only; `(enum|struct|type)\s+(…|Attempt|…)\b` over the same tree → **0 matches**. `^pub fn ` over api-surface.md → **12** declarations, none named `classify_response_with_error` or `classify_error`.

**Consequence:** False-green of the highest-value kind. VP-007 is the only verification property covering the DNS→broken and TLS→broken rulings that ADR-007's Rationale calls "critical" ("classifying them as `indeterminate` would create false negatives for genuinely broken external links", ADR-007:31-32). Because the DNS/TLS assertions cannot be expressed against the declared API, the harness will either fail to compile (E0433/E0599 on `HttpError`, `VerdictKind`, `.kind`, `HttpAttempt::Get`) or — worse — be silently "adapted" per vp-007:170-172 into a version that only exercises `(u16, HttpAttempt)` and therefore proves nothing about DNS or TLS. This is the identical failure mode as INC-MAP-001/BI-010 (a VP written against a non-existent API), but on a **P0 Kani** proof and undetected: `bc-module-map.md:385-458` logs four INC-MAP notes and none of them is this one.

---

### P7-S6-003 — ADR-003's decisive undefined-reference rationale is factually wrong about pulldown-cmark, and the two architecture docs disagree on the parser constructor [CRITICAL]

ADR-003 rests on three stated constraints (ADR-003:21-24), the third being undefined-reference detection. Its rationale (ADR-003:47-50):

> "`LinkType::ReferenceUnknown`, `CollapsedUnknown`, and `ShortcutUnknown` variants surface undefined references directly in the event stream. This enables BC-2.03.003's `undefined-reference-definition` reason code **without post-processing**."

This is false as stated. In `pulldown-cmark`, those `LinkType::*Unknown` variants are produced **only** when a broken-link callback is installed on the parser and that callback returns `Some((url, title))`. With a plainly-constructed parser, an unresolvable reference is emitted as literal text and **no `Tag::Link` event is generated at all**. ADR-003 — the decision record that owns the parser choice — never mentions a callback anywhere in its 92 lines. `tooling-selection.md:116` repeats the same incomplete claim ("`LinkType::*Unknown` variants make undefined references a distinct failure class") in its ADR-003 summary.

The two architecture documents in this shard then disagree on the constructor that decides the matter:

- `purity-boundary-map.md:107` — "Running `pulldown-cmark::Parser::new_with_broken_links()` (pure-ish)"
- `feasibility-review.md:181` — "The string passed to `pulldown-cmark::Parser::new()` must already be BOM-free and LF-normalized."

`Parser::new()` is the constructor that cannot produce `*Unknown` variants. `new_with_broken_links()` is additionally not a real pulldown-cmark API name (the 0.13 constructor is `Parser::new_with_broken_link_callback`); BC-2.03.003:45-46 hedges this with "(or the equivalent API that installs a `broken_link_callback`)", but `purity-boundary-map.md:107` states the phantom name unhedged.

**Predicate:** `ENABLE_|Options::|Parser::new|new_with_broken|broken_link_callback` over `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs` → **8 matching lines**: `Parser::new()` at feasibility-review.md:181, BC-2.02.002:43, BC-2.02.002:58, BC-2.03.003:60; `new_with_broken_links` at purity-boundary-map.md:107, prd.md:597, BC-2.03.003:45; `broken_link_callback` at prd.md:597, BC-2.03.003:46. **Zero** occurrences of `ENABLE_` or `Options::` anywhere (see P7-S6-016).

**Consequence:** An implementer following `feasibility-review.md:181` (a document whose declared primary consumers are product-owner and architect, and whose SF-001 is a *"Required action for story-writer"*) constructs `Parser::new()`. Undefined references then never generate a link event, `undefined-reference-definition` becomes unreachable, and every `[x][missing]` in the corpus is silently reported as clean — a false negative in exactly the class the product exists to eliminate (SOUL #4 silent failure). ADR-003's rejection of comrak is partly predicated on this rationale ("`comrak` would require a separate pass over the AST", ADR-003:50); with the callback requirement made explicit, the asserted asymmetry between the two parsers shrinks and the ADR's decisive comparison is unsound as written.

---

### P7-S6-004 — ADR-001 (accepted, all 14 subsystems, no changelog) still mandates the retired `DirEntries`/`Vec<OsString>` design that SR-016 proved incorrect [HIGH]

`ADR-001:52-54`:

> "The `DirEntries` design is the key constraint: `path_resolver` receives a pre-populated `Vec<OsString>` from `scanner` instead of calling `fs::read_dir` itself. This single choice makes the case-sensitive NFC comparison formally verifiable (VP-008)."

and `ADR-001:66-67` under Negative/Trade-offs:

> "Scanner must eagerly read `DirEntries` for every file even when path resolution turns out not to need them"

Every other document retired this type and this producer:

- `system-overview.md:88-89` — "SR-016 revealed that a single-directory `DirEntries` type **could not resolve multi-component paths or detect file-vs-directory**."
- `api-surface.md:28` (v1.1) — "replaced DirEntries=Vec<OsString> with DirIndex=HashMap<PathBuf,Vec<DirEntryInfo>>"
- `module-decomposition.md:22` (v1.1) — "replaced DirEntries with DirIndex type"
- `purity-boundary-map.md:27,67` — DirIndex, built by **`app`** in Pass 1.5, not by `scanner`
- `ADR-006:16` (v1.3) — "Fixed DirEntries → DirIndex at line 63 body reference (stale type name superseded by api-surface.md and purity-boundary-map.md)"
- `module-criticality.md:31` — "fixed types inventory to list DirIndex/DirEntryInfo/EntryKind instead of stale DirEntries"

ADR-001 remains `version: "1.0"`, `status: accepted`, `changelog: [Initial draft]`, `subsystems_affected: [SS-01 … SS-14]`. Its Rationale also attributes the DirIndex production to `scanner`, which `api-surface.md:22` (v1.3) and `ADR-006:19` (v1.2) both explicitly corrected to `app`.

**Predicate:** `DirEntries` over `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs` → **8 occurrences across 7 files**. Of these, exactly **2 are live body prescriptions and both are in ADR-001** (`:52`, `:66`); 1 is a historical narrative reference (system-overview.md:88); 5 are changelog entries recording the DirEntries→DirIndex fix in other files.

**Consequence:** ADR-001 is the root architectural decision, cited by ADR-002 as the constraint it enforces and marked as universal in `bc-module-map.md:47-51` ("ADR-001 … applies to every module and every BC"). An implementer or stub-architect reading it builds `Vec<OsString>` in `scanner`, which cannot resolve `docs/sub/a.md` from `docs/guide.md` and cannot produce `target-is-directory` or `broken-symlink` (the two reason codes that `purity-boundary-map.md:69-71` says `EntryKind` exists to enable). This is a partial-fix regression with blast radius 1 file and 2 sites, in the highest-authority document of the set.

---

### P7-S6-005 — ADR-006's changelog claims it "corrected T12 cross-reference to T8"; T8 is the wrong trap, and the original T12 reference was correct [HIGH]

`ADR-006:22` (v1.1 changelog): "corrected T12 cross-reference to T8 (case-sensitive filename)".
`ADR-006:105-107` (body, the result of that "correction"):

> "**Case-sensitive filename trap (T8):** market-intelligence §4.3 T8 identifies the `readme.md` vs `README.md` case mismatch as a common real-world trap."

The source says otherwise.

**Predicate:** `T8|T12` over `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/planning/market-intelligence.md` → 6 matching lines. §4.3 is the "Correctness traps" table (market-intelligence.md:321). Within it:

- `market-intelligence.md:335` — "**T8** | Angle-bracket destination with spaces `[x](<a b.md>)` | Valid; destination is `a b.md`. The angle brackets are stripped by the parser…"
- `market-intelligence.md:339` — "**T12** | Case-insensitive macOS APFS vs case-sensitive Linux | `[x](docs/Setup.md)` pointing at `docs/setup.md` **passes on a dev Mac and 404s on GitHub**. Mitigation: after `Path::exists()` succeeds, read the parent directory and confirm an **exact byte-for-byte** filename match."

T12 *is* the case-sensitive-filename trap and is the direct source of ADR-006's entire Decision. T8 is an unrelated angle-bracket-destination trap. The "correction" replaced a correct anchor with an incorrect one and then recorded the substitution as a fix.

**Consequence:** Two compounding harms. (a) A story-writer or test-writer following `ADR-006:105` to market-intelligence §4.3 T8 lands on angle-bracket destination handling and finds no case-mismatch guidance — and the acceptance-corpus fixture for the product's stated differentiator ("the research found no tool doing it", market-intelligence.md:339) may be built against the wrong trap. (b) The changelog entry defeats future audits: any reviewer who greps for stale T-references sees a documented remediation and moves on. `market-intelligence.md:424` and `:442` independently confirm T12 as the case-sensitivity item ("Exact-case filename verification (T12)"), so the misattribution is unambiguous.

---

### P7-S6-006 — ADR-005's `open_dependencies: DEP-001 status: open` is stale; BC-2.03.002 already carries the required PC7 [HIGH]

`ADR-005:10-15` frontmatter:

```yaml
open_dependencies:
  - id: DEP-001
    artifact: BC-2.03.002
    requirement: "Add postcondition PC7: for all reference forms, the reported Finding position is the use site (byte offset of [text] span), never the [label]: url definition site. Required for sort key totality argument…"
    status: open
    tracking: "product-owner handoff item P4-005"
```

BC-2.03.002 v1.3 already discharges it, verbatim:

- `BC-2.03.002.md:54-57` — "7. For all reference forms (full, collapsed, shortcut), the reported `Finding` position is the **use site** (the byte offset of the `[text]` span), never the `[label]: url` definition site. Two uses of the same label at different source lines produce two findings with distinct `line` values."
- `BC-2.03.002.md:63-66` — Invariant 4: "Attributing a finding to the definition site … is FORBIDDEN."
- `BC-2.03.002.md:25` — modified: "v1.3: (P4-005) Added PC7 (use-site finding position); Invariant 4 …; EC-202 … with canonical test vector."
- `BC-2.03.002.md:76,84` — EC-202 and its canonical test vector are present.

The stale flag is echoed in three body sites: `ADR-005:48-49` ("see BC-2.03.002 postcondition — tracked as open dependency DEP-001 in frontmatter"), `ADR-005:97` and `ADR-005:122`.

**Predicate:** `status: open` over `.factory/specs/architecture/` → **1 occurrence** (ADR-005:14); `open dependency` → 2 occurrences (ADR-005:49, :122); `open_dependencies` → 2 (ADR-005:10, :97).

**Consequence:** DI-001 determinism is the product's sort-key contract and `ADR-005:47-50` makes `sort_unstable_by` safety conditional on this postcondition. With `status: open` in machine-readable frontmatter, any consumer (state-manager, dashboard, or a Phase-2 story-writer scanning for open dependencies) concludes the totality argument is undischarged and that `sort_unstable_by` is not yet justified — and a product-owner dispatched on the tracking item would add a duplicate PC8 to BC-2.03.002, violating the append-only postcondition discipline. Note that the same v1.3 changelog entry (`ADR-005:19`) claims credit for moving the directive to frontmatter "(P4-037 process-gap)" while leaving the status field unflipped: the *process* fix landed, the *state* fix did not.

---

### P7-S6-007 — ADR-008 asserts BC-2.06.001 Invariant 2 "currently states the opposite"; it does not, and acting on the directive would regress the headline differentiator [HIGH]

`ADR-008:73-75`:

> "**BC-2.06.001 Invariant 2** currently states the opposite (text DISCARDED) — this is a BC-level error. See product-owner handoff item in the P4 remediation report: BC-2.06.001 Invariant 2 must be corrected to match DI-012 rule 1."

BC-2.06.001 v1.4 already states the ADR-008 ruling, and cites ADR-008 while doing so:

- `BC-2.06.001.md:75-81` — "**HTML elements:** Tag markup tokens (e.g., `<kbd>`, `</kbd>`) are stripped; the visible TEXT CONTENT between the tags **IS retained**. A heading `## <kbd>Ctrl+C</kbd>` yields rendered text `"ctrlc"` → slug `"ctrlc"`. This matches pulldown-cmark's InlineHtml event model (ADR-003)… DI-012 rule 1: 'HTML tags contribute nothing (tag tokens are stripped; their visible text content, if any, is retained).'"
- `BC-2.06.001.md:26` — modified: "v1.4: (P4-001) Corrected Invariant 2: HTML element visible text IS retained (ADR-008 §HTML-Text Rendering Adjudication, DI-012 rule 1). **Supersedes v1.1 Invariant-2 entry which stated the opposite.**"

ADR-008's own quotation of DI-012 rule 1 is accurate (`invariants.md:296-301` matches verbatim) — so the ruling is right and only the "currently states the opposite" claim is wrong.

**Consequence:** This is the harmful direction of a stale directive. ADR-008 is `status: accepted` and is the Key ADR for SS-06 in `bc-module-map.md:162,166,167`. A reader trusting the ADR concludes BC-2.06.001 is defective; the cheapest way to make the BC "match the ADR's description of it" is to flip Invariant 2 back to DISCARDED, which inverts the discriminating example ADR-008:69-71 gives (`"code text"` → `code-text` vs `"code "` → `code-`) and produces a systematic slug divergence from `github-slugger@2.0.0` on every heading containing inline HTML — i.e. a direct DI-012/NFR-006 violation on the product's primary differentiator. Minimum fix: replace the false present-tense claim with a discharged-reference to BC-2.06.001 v1.4.

---

### P7-S6-008 — ADR-007's self-declared "canonical" exit-code definition omits the usage/config-error half of frozen brief R7 [HIGH]

`ADR-007:59-62`:

```
**Exit codes (canonical definition — R7, DD-006, DI-011, BC-2.14.002):**
- **0** — no `broken` findings, no I/O errors
- **1** — at least one `broken` finding
- **2** — at least one I/O error (takes precedence over exit 1)
```

Frozen brief R7 (`product-brief.md:50-51`): "Exit codes: 0 = no broken links; 1 = at least one broken link; **2 = usage or I/O error** (unreadable path, invalid flag)."

Every other artifact carries the usage half explicitly:

- `api-surface.md:59` — "`2` — at least one I/O **or usage** error (takes precedence over exit 1)"
- `api-surface.md:115`, `module-decomposition.md:59,136`, `purity-boundary-map.md:64` — `exit_code(findings, io_errors, **config_error: bool**) -> u8`
- `system-overview.md:256-263` — `app` sets `config_error = true` and calls `verdict::exit_code([], [], true)` → 2, routed *through* verdict so "`verdict::exit_code` remains the single authority for every exit code and VP-005's Kani proof covers this path"
- `purity-boundary-map.md:125` — P0 Kani target list includes "**config-error-exits-2**"
- `verification-architecture.md:127-128` — the VP-005 harness asserts `if has_io_error || config_error { assert_eq!(exit, 2); }`

ADR-007 mentions neither `config_error` nor usage errors anywhere in its 175 lines, while claiming canonicity for the mapping and while its v1.3 changelog (`ADR-007:153`) claims a complete Decision-section rewrite. ADR-007 is the Key ADR for SS-14 (`bc-module-map.md:328`) and for BC-2.11.004 (`bc-module-map.md:290`) — the invalid-`--ignore`-glob → exit 2 contract that *is* the config-error path.

**Predicate:** `config_error` over `.factory/specs/architecture/decisions/` → **0 occurrences**; over `.factory/specs/architecture/` → present in api-surface.md, module-decomposition.md, purity-boundary-map.md, system-overview.md, bc-module-map.md, verification-architecture.md.

**Consequence:** An implementer taking ADR-007 at its word ("canonical definition") writes the two-argument `exit_code(findings, io_errors)` that `purity-boundary-map.md:24` records as already having been corrected once. BC-2.11.004's exit 2 then has no route through `verdict::exit_code`, forcing a `process::exit` bypass — precisely the design `system-overview.md:260-262` prohibits, and one that puts an exit-code path outside VP-005's proof envelope. POLICY 12 axis: the ADR's exit-2 clause is narrower than R7 and than the taxonomy-consistent surface in api-surface.md. Note the POL-12 checker (`check-adr-consistency.py:84-93`) only detects exit-2-applied-to-*broken*; an *omission* is invisible to it, so nothing enforces this.

---

### P7-S6-009 — bc-module-map's "Primary ownership count per module" table sums to 70 while declaring Total 66, and four cells are individually wrong [HIGH]

`bc-module-map.md:361-381` presents a derived table titled "**Primary ownership count per module (deduped — each BC counted once by its primary module)**" with a bolded `| **Total** | **66** | — |` row.

Summing the column as printed (`bc-module-map.md:365-380`): scanner 13 + link_extractor 9 + path_resolver 6 + anchor_table 4 + filter 4 + reporter 6 + http_client 8 + http_verdict 3 + anchor_resolver 3 + url_classifier 3 + slug 2 + fragment 2 + verdict 3 + cli 4 + app 0 + main 0 = **70**. The declared total is 66. A table whose stated invariant is "each BC counted once" cannot sum to 70 over 66 BCs.

Recomputing each cell from this file's own per-subsystem detail tables (the Primary Module column of the SS-01..SS-14 tables at `:73-336`) yields: scanner 13, link_extractor **8** (BC-2.03.001/002/003/004/006 — BC-2.03.005's primary is `url_classifier` per `:119` — plus BC-2.04.001/002/003), anchor_table **3** (BC-2.05.001/002/003; BC-2.04.003's anchor_table role is *Secondary* per `:139`), slug 2, path_resolver 6, fragment 2, anchor_resolver 3, url_classifier 3, filter 4, http_client **7** (BC-2.10.001/003/004/007/008/009/010), http_verdict 3, reporter 6, verdict 3, cli **3** (BC-2.11.004, BC-2.12.004, BC-2.14.004 — BC-2.12.002's primary is `reporter` per `:306`), app 0, main 0. That corrected distribution sums to exactly **66**. The four defective cells are link_extractor (9→8), anchor_table (4→3), http_client (8→7), cli (4→3).

This is also a partial-fix regression: `bc-module-map.md:27` (v1.2) records "Updated BC Count values: app 2→1, path_resolver 8→7, url_classifier 5→4, **http_client 8→7**". The http_client correction landed in the Module Ownership Summary (`:352` reads 7) but **not** in the Primary ownership table 20 lines below (`:371` still reads 8).

**Predicate:** magnitude established by per-cell arithmetic on the quoted cell contents of `bc-module-map.md:365-380` and on the Primary Module column of `bc-module-map.md:73-336` — not by corpus-wide counting. Checker coverage predicate: `bc-module-map` over `/Users/jmagady/Dev/mdlinkcheck-cloud/scripts/spec-lint/check-counts.py` → **0 matches**; the checker's docstring (`check-counts.py:5-18`) enumerates 9 artifacts and bc-module-map.md is not among them.

**Consequence:** This table is the routing input for Phase-2 story decomposition (`ARCH-INDEX.md:46`: "Primary Consumer: story-writer, product-owner"). Four modules receive inflated BC ownership, and the +1 on link_extractor/anchor_table/cli each corresponds to a specific BC (BC-2.03.005, BC-2.04.003, BC-2.12.002) whose *actual* primary module the table's own detail rows assign elsewhere — so story decomposition can route the same BC to two modules while the aggregate "66" masks the double-count. POLICY 17 violation with no lint coverage.

**Tag:** [process-gap] — POLICY 17's declared lint_hook (`check-counts.py`) validates VP-INDEX↔coverage-matrix totals (`check-counts.py:348-372`) but has no bc-module-map coverage at all, so every hand-maintained count in the 66-row BC↔module map is unenforced.

---

### P7-S6-010 — module-decomposition.md's module table disagrees with api-surface.md on function and type names for 10 of 11 pure-core modules [HIGH]

`ARCH-INDEX.md:40` designates `api-surface.md` as the document for "CLI interface, library public API" consumed by test-writer and implementer. `purity-boundary-map.md:52-64` uses api-surface's names throughout. `module-decomposition.md:47-60` — consumed by "story-writer, implementer" (`ARCH-INDEX.md:38`) — uses a different set:

| module-decomposition.md | api-surface.md | divergence |
|---|---|---|
| :49 `fn compute(text, counter: &mut DuplicateCounter)` | :71-72 `slugify(text)` + `compute_slug(text, counter)` | name wrong; **`slugify` — the VP-001 Kani target — is absent entirely** |
| :50 `fn split(raw_dest)` | :77 `split_fragment(raw_dest)` | name |
| :51 `fn build(events: &ParsedHeading) -> AnchorTable` | :81 `build_anchor_table(headings: &[ParsedHeading])` | name, parameter name (`events` vs `headings`), **and arity: single `&ParsedHeading` vs `&[ParsedHeading]`**; :82 `build_with_html` absent |
| :52 `fn extract(events: &[PcEvent])` | :85 `extract_links(events: &[OffsetEvent])` | name + type name |
| :53 `fn resolve(dest, src_dir, index)` | :89 `resolve_path(dest, src_dir, index)` | name |
| :54 `fn resolve(fragment, table)` | :95 `resolve_anchor(fragment, table)` | name (and collides with :53's `resolve`) |
| :55 `fn classify(dest)` | :98 `classify_url(dest)` | name |
| :56 `classify_response(status, attempt: Attempt)` | :102 `classify_response(status, attempt: HttpAttempt)` | type name |
| :57 `ignore_match(path, gs: &GlobSet)`, `allow_match(url, prefixes: &[Prefix])` | :106-107 `should_ignore(path, patterns)`, `should_allow(url, prefixes: &[AllowPrefix])` | 2 names + type name |
| :58 `format_text(findings, opts: ReportOpts)`, `format_json` | :110-112 `format_text(findings, opts: TextReportOpts)`, `format_summary`, `format_json` | type name; **`format_summary` absent** despite api-surface v1.4 adding it for BC-2.12.003/005 |
| :59 `exit_code(findings, io_errors, config_error) -> u8` | :115 identical | **only matching row** |

**Predicate:** `^pub fn \|^pub type \|^pub enum \|^pub struct ` over `api-surface.md` → **27 declarations** (lines 71-126, of which 12 are `pub fn`); the module-decomposition signatures are the 12 table cells at `module-decomposition.md:49-60`. Comparison is 10 divergent rows / 11 non-`types` rows, established cell-by-cell above.

**Consequence:** Two of three architecture documents (api-surface, purity-boundary-map) agree; module-decomposition is the outlier, and it is the one story-writers use for module assignment. Worse, the two omissions are load-bearing: `slugify` is the function VP-001 proves total (`verification-architecture.md:59,107-119`) and whose separation from `compute_slug` was a deliberate P4 correction (`purity-boundary-map.md:24,123`); `format_summary` is the function BC-2.12.003/005 need to keep the summary line off stdout. A story generated from module-decomposition would stub neither, and `dependency-graph.md:101-108` ("Stories MUST implement modules in dependency order to satisfy the Red Gate") makes the stub set the Red Gate input.

---

### P7-S6-011 — 14 types and 3 symbols named in api-surface.md/module-decomposition.md signatures have no definition anywhere in the corpus; three VP harnesses depend on them [HIGH]

See the UNDEFINED-TYPE ROSTER above for the full enumeration. The load-bearing cases:

- **`PathVerdict`** — the return type of `resolve_path` (`api-surface.md:89`), the CRITICAL-tier path-resolution surface. `api-surface.md`'s "Key Shared Types" block (`:120-127`) defines `Finding`, `Verdict`, `ParsedHeading`, `ExtractedLink` and *not* `PathVerdict`. VP-024 — a P1 proptest and the sole VP for BC-2.07.008 (`VP-INDEX.md:200`) — pattern-matches on `PathVerdict::Broken(FailureReason::FileNotFound)`, `PathVerdict::Broken(FailureReason::TargetIsDirectory)` and `PathVerdict::Clean` (vp-024:43,44,99,100,103,118). Neither the enum nor its variants exist. The relationship between `PathVerdict` and the defined `Verdict` (`api-surface.md:124`) is never stated — they are structurally near-identical, so an implementer cannot tell whether one is an alias, a subset, or a distinct type.
- **`FailureReason`** — carried by both `Verdict::Broken`/`Indeterminate` and `Finding.reason` (`api-surface.md:121-124`). No declaration, and no mapping is given anywhere from its CamelCase variants to the 13 kebab-case reason codes in `error-taxonomy.md:99-102`. VP-021 asserts "every emitted `reason` field is in the closed taxonomy set" (`verification-architecture.md:98`) against a type whose variants are undeclared.
- **`IoError`** — the second parameter of `verdict::exit_code`, the function VP-005 and VP-006 (two of the seven P0 Kani proofs) target. `vp-006:73` writes `let io_errors: Vec<IoError> = Vec::new();`.
- **Name-pair splits:** `OffsetEvent`/`PcEvent`, `HttpAttempt`/`Attempt`, `TextReportOpts`/`ReportOpts`, `AllowPrefix`/`Prefix` — four types each carrying two names across the two documents, none defined, so a reader cannot even determine whether they are one type or two.
- **`AnchorIndex` / `LinkMap`** — used pervasively in pipeline prose and in BC-2.05.001's postconditions and BC-2.14.004's Invariant 4, but never declared as `pub type` in api-surface.md, in contrast to `pub type DirIndex` at `api-surface.md:90`.

**Predicate:** `(enum|struct|type)\s+(PathVerdict|OffsetEvent|PcEvent|FailureReason|LinkKind|TextReportOpts|ReportOpts|AllowPrefix|IoError|HttpResult|CliArgs|Attempt|Prefix|Link)\b` over `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs` → **0 matches**, against **72 usage occurrences across 22 files** (usage predicate in the roster header).

**Consequence:** VP-024, VP-005 and VP-006 harnesses cannot compile as written; VP-024 is the only verification for BC-2.07.008 and VP-005/006 are P0 Kani. This is the same defect class as INC-MAP-001 (logged at `bc-module-map.md:390-412` as CRITICAL BI-010) generalised across the type surface — and unlike INC-MAP-001, it is unlogged. `api-surface.md` is designated authoritative for exactly this content; the gap cannot be closed by an implementer's judgement because the `PathVerdict`-vs-`Verdict` distinction is a semantic choice, not a naming one.

---

### P7-S6-012 — DI-005's "Partial" coverage qualifier is dropped in both derived architecture documents, which then assert 13/13 full coverage [HIGH]

`VP-INDEX.md:92` (the POLICY 9 source of truth) records:

> "| DI-005 | Exactly one verdict per link | VP-019 | proptest | **Partial** — VP-019 proves extract_links is duplicate-free within one file (extraction precondition); full pipeline guarantee (no-verdict and two-verdict cases, e.g. path_resolver AND anchor_resolver both firing on the same link) **requires a Phase 3 integration test**"

Neither derived document carries the qualifier:

- `verification-architecture.md:142` — "| DI-005 | Exactly one verdict per link | VP-019 | P1 |" with no partial marker, while the same matrix carries explicit multi-line coverage notes for DI-012 and DI-013 (`:152-154`) and had DI-012/DI-013 "Gap notes removed" per `:24`. The asymmetry reads as a deliberate statement that DI-005 has no gap.
- `verification-coverage-matrix.md:111` — "**All 13 DIs have VP coverage (13/13).** DI-012 covered by … DI-013 covered by … FM-002 closed by VP-026." DI-005 is silently folded into the 13/13.

The gap is architecturally real and this shard's own documents depend on it: `ADR-005:65-70,95-100` deliberately added the `link_target` tie-break specifically because DI-005 is not proven end-to-end ("The total key **removes any dependency on DI-005** (one-verdict-per-link)… VP-019 covers extraction deduplication only"). So the architecture knows DI-005 is unproven at the pipeline level, and the coverage documents assert it is covered.

**Predicate:** `DI-005` over `.factory/specs/architecture/` → 5 occurrences (verification-architecture.md:142; verification-coverage-matrix.md — via the 13/13 prose at :111; ADR-005:66,99; ADR-007:162). None carries the Partial qualifier. Checker coverage: `check-counts.py:348-372` validates the coverage matrix's **Totals row** against VP-INDEX per-tool counts only; predicate `DI Coverage\|All Covered` over `check-counts.py` → 0 matches, so no per-DI coverage claim is machine-checked.

**Consequence:** False-green. `verification-coverage-matrix.md`'s declared primary consumer is the consistency-validator (`ARCH-INDEX.md:44`) and `verification-architecture.md`'s is the formal-verifier (`ARCH-INDEX.md:41`). Both are told DI-005 is fully covered; the Phase-3 integration test that VP-INDEX says is required is therefore never commissioned, and the two-verdict case (path_resolver and anchor_resolver both firing on one link) ships unverified. That case is exactly the one whose absence `ADR-005` compensates for in the *ordering* proof but which nothing checks in the *verdict* domain.

---

### P7-S6-013 — verification-architecture.md's VP-025 row still describes the retired `Hit`/`Miss` enum that VP-025 v1.1 removed as non-existent [HIGH]

`verification-architecture.md:78`:

> "| VP-025 | `anchor_resolver::resolve_anchor` totality and correctness — no panic on any `(fragment, table)` pair; **fragment present in table → Hit; fragment absent → Miss**; case-sensitive byte-exact lookup; empty fragment handled | anchor_resolver | BC-2.08.001/002/004 |"

VP-025 v1.1 exists precisely to delete that vocabulary:

- `vp-025:27` — "rewrote entire harness against declared API … `resolve_anchor` returns `Verdict {Clean, Broken(FailureReason), Indeterminate(FailureReason)}` **not `AnchorVerdict {Hit,Miss}`**; … property 4 rewritten from 'Closed enum: Hit or Miss only'"
- `vp-025:48-56` — Hit/Miss correctness restated as `Verdict::Clean` / `Verdict::Broken(_)`; the harness at `vp-025:198,223,251,278,284` matches only on `Verdict::Clean` and `Verdict::Broken(_)`.
- `bc-module-map.md:396-401` records the corresponding INC-MAP-001 discharge: "Return type: `Verdict` — three variants … (was `AnchorVerdict`, a **non-existent** two-variant enum)".

The same document's v1.6 changelog (`verification-architecture.md:30`) also states the proptest rationale as "because **AnchorTable is a HashMap** — CBMC state explosion for symbolic HashMap keys", whereas `api-surface.md:80` declares `pub struct AnchorTable(HashSet<String>)` and `vp-025:104` explicitly corrects it ("`AnchorTable` is a `HashSet<String>` (per `api-surface.md:80`)"). The v1.9/v1.10 changelog entries (`:18-21`) record P4-004 and P4-009 propagation but not P4-002 — the P4-002 fix reached VP-025, VP-INDEX and bc-module-map and stopped there.

**Predicate:** `Hit\|Miss\|AnchorVerdict` over `.factory/specs/architecture/` → 1 live occurrence, `verification-architecture.md:78`. `AnchorVerdict` over `.factory/specs` → occurrences confined to vp-025's changelog and bc-module-map's INC-MAP-001 narrative (both describing it as removed/non-existent).

**Consequence:** `verification-architecture.md` is the formal-verifier's primary document (`ARCH-INDEX.md:41`) and its Provable Properties Catalog is the P0/P1 work order. A formal-verifier implementing VP-025 from that row writes `AnchorVerdict::{Hit,Miss}`, reproducing verbatim the non-compiling harness that BI-010 was raised as CRITICAL for — an E0004/E0433 against the real `Verdict` — and losing property 4 ("Indeterminate never returned"), which `vp-025:58-64` identifies as "the genuinely valuable property". Partial-fix regression, blast radius 1 file, in the document with the most direct downstream execution.

---

### P7-S6-014 — the per-host cap inside a blocking 32-thread pool creates cross-host head-of-line blocking that contradicts BC-2.10.008 PC3; ADR-004's mitigation is asserted, not established [HIGH]

ADR-004 and ADR-005 jointly specify: one dedicated rayon pool of exactly 32 threads for all HTTP dispatch (`ADR-004:38-40`, `ADR-005:78-84`), with `ureq` blocking a thread for the whole request (`ADR-004:39-40`, up to 10 s per `BC-2.10.003`), and a per-host cap of 4 enforced by an in-pool counter — `ADR-004:64-66`: "A semaphore-style `Arc<Mutex<HashMap<String, u32>>>` tracking active-request counts per host implements BC-2.10.008's 4-per-host cap. **This is trivial with sync code**"; `ADR-005:80-81`: "Within that dedicated pool, per-host semaphores enforce the 4-per-host cap".

The ADR analyses one starvation hazard (HTTP threads starving CPU-bound Pass 1/Pass 2, `ADR-004:42-48`) and asserts it is resolved: "The dedicated pool means HTTP threads only compete with each other, not with CPU work" (`ADR-004:47-48`). It does not analyse the hazard the fix introduces. Because a rayon worker that blocks on a mutex/semaphore does not yield or steal other tasks, the realistic corpus shape — most external links pointing at one or two hosts — leads to all 32 workers holding host-A tasks, 4 of which proceed and 28 of which sit blocked on the per-host counter. A single host-B URL sitting in the work queue cannot start until a worker is released, i.e. up to `ceil(host_A_tasks / 4) × timeout` later.

That directly violates the contract this design is cited as implementing — `BC-2.10.008.md:51` PC3: "**When a slot frees up, the next queued request begins immediately.**" It also degrades PC1 (`BC-2.10.008.md:49`, "At most 32 HTTP requests are in-flight") from a cap into an unreachable ceiling: observed global concurrency collapses to 4 whenever one host dominates, which the canonical test vector at `BC-2.10.008.md:75` ("40 URLs to 40 different mock servers | … global total ≤ 32") is shaped to *not* detect, and no VP covers (`bc-module-map.md:246`: BC-2.10.008 Formal VPs = `—`; `VP-INDEX.md:229`: test-sufficient).

No admission-control or queueing design is specified anywhere: predicate `semaphore\|admission\|queue\|backpressure\|head-of-line` over `.factory/specs/architecture/` returns only the four "per-host semaphore(s)" assertions (ADR-004:64, ADR-005:80, system-overview.md:195-197, bc-module-map.md:261) and no mechanism.

**Consequence:** Spec rework required before SS-10 implementation. As specified, the tool's `--online` wall-clock on a single-host-dominant repo is `O(N/4 × timeout)` rather than `O(N/32 × timeout)` — an 8× regression against the design's own throughput premise ("bounded, embarrassingly-parallel batch", `ADR-004:37-38`) — and PC3 is unsatisfiable. The correct shape (host-partitioned queues with non-blocking admission, or a dispatcher that only schedules a task once its host slot is acquired) is a different architecture from "32 threads + in-thread mutex", so this cannot be deferred to the implementer.

---

### P7-S6-015 — VP-INDEX's subsystem section headings deviate from the ARCH-INDEX Subsystem Registry in 13 of 14 cases (POLICY 6) [HIGH]

`ARCH-INDEX.md:57-77` declares itself the source of truth: "**Source of truth** for subsystem names. BC frontmatter `subsystem:`, BC-INDEX, and story `subsystems:` MUST use exact names from this table."

**Predicate:** `^#{2,4} SS-\d\d` over `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs` → **42 headings across 3 files**. `bc-module-map.md:68-325` — 14/14 verbatim ✓. `BC-INDEX.md:28-181` — 14/14 verbatim ✓. `VP-INDEX.md:132-259` — 1/14 verbatim (SS-01 "File Discovery"); the other 13 deviate:

| VP-INDEX | ARCH-INDEX registry (canonical) |
|---|---|
| :146 SS-02: **Parser** | Markdown Parsing |
| :155 SS-03: **Link Extractor** | Link Extraction |
| :166 SS-04: **Code Context** | Code Context Exclusion |
| :174 SS-05: **Anchor Table Builder** | Anchor Table Construction |
| :182 SS-06: **Slug** | Heading Slug Computation |
| :189 SS-07: **Path Resolver** | Relative Path Resolution |
| :202 SS-08: **Anchor Resolver** | Anchor Resolution |
| :211 SS-09: **URL Classifier** | External URL Syntax Validation |
| :218 SS-10: **HTTP Checker** | External URL Liveness Checking |
| :233 SS-11: **Filter** | Filter Application |
| :242 SS-12: **Text Reporter** | Text Report Generation |
| :252 SS-13: **JSON Reporter** | JSON Report Generation |
| :259 SS-14: **Exit Code** | Exit Code Determination |

Every deviation substitutes the *module* name for the *subsystem* name — the exact conflation ARCH-INDEX's registry keeps separate via its distinct "Name" and "Implementing Modules" columns.

**Consequence:** POLICY 6 is HIGH-severity with `lint_hook: null` (nothing enforces it). VP-INDEX is the artifact a story-writer joins against for VP assignment; using module names as subsystem labels makes a mechanical SS-name join impossible and invites story `subsystems:` fields populated with module names. Remediation belongs in VP-INDEX (or, if the short forms are intentional, ARCH-INDEX must sanction them explicitly — currently it forbids them).

---

### P7-S6-016 — the pulldown-cmark `Options` bitmask is unspecified in the entire corpus, while three BCs depend on which extensions are enabled [MEDIUM]

**Predicate:** `ENABLE_|Options::` over `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs` → **0 matches**. No `Options` value, no flag name, and no `Parser::new_ext` reference exists anywhere. ADR-003 — the decision that selects the parser — never mentions parser options in its 92 lines; neither does `dependency-graph.md:28`, `api-surface.md`, nor `purity-boundary-map.md:105-108`.

The nearest specification is prose in a BC body: `BC-2.02.001.md:50` — "GFM extensions (tables, strikethrough, task lists) are enabled; footnotes are recognized but treated as non-links" — and `BC-2.02.001.md:38` "with CommonMark 0.31.2 + GFM options enabled". Three contracts depend on the resolution:

- `BC-2.02.001` (P0 per `prd.md:123`) requires GFM. `Parser::new()` is CommonMark-only; GFM requires an explicit `Options` bitmask, so the constructor named at `feasibility-review.md:181` cannot satisfy it (compounding P7-S6-003).
- `BC-2.03.006` ("Footnote References Excluded") asserts at `:51` "No special-case footnote filtering code is needed" — true only if footnote parsing is enabled. Without it, `[^1]` parses as a shortcut reference; combined with a broken-link callback that returns `Some` (required for BC-2.03.003's `undefined-reference-definition` to be reachable at all), every footnote reference becomes `broken(undefined-reference-definition)`. The Options set and the callback's return value are therefore *jointly* load-bearing and neither is specified at the architecture layer.
- `TV-113` (`test-vectors.md:218`, "Link inside a GFM table cell … Tables scanned") is only satisfiable with table parsing enabled.

**Consequence:** The one configuration value that determines whether three BCs pass is recorded nowhere an implementer of `scanner.rs` would look, and is stated only as English prose with no flag names. The interaction with the broken-link callback (footnote-vs-undefined-reference) is a live false-positive generator that no VP covers (`BC-2.03.006` and `BC-2.03.003` are both `test-sufficient` per `VP-INDEX.md:161,164`). Minimum fix: state the exact `Options` bitmask and the callback contract in ADR-003 (the owning decision) and mirror it in `purity-boundary-map.md:105-108`.

---

### P7-S6-017 — ADR-002's `resolver = "2"` rationale is factually wrong for an edition-2024 / MSRV-1.85 workspace [MEDIUM]

`ADR-002:58-59`:

> "The `resolver = \"2\"` setting is **required by** `clap` 4.6.5 and `ureq` 3.3.0 (edition 2024 dependencies). Setting it at workspace level ensures consistent resolution."

Both halves of the causal claim are wrong. Resolver 2 has been the default for edition-2021 crates since Rust 1.51 and is not something an edition-2024 dependency can require. The resolver associated with edition 2024 is **resolver 3** (MSRV-aware resolution, stabilised in Rust 1.84 and the default for edition 2024) — and MSRV-aware resolution is exactly what a project pinning `rust-version = 1.85` with a 1.97.0 toolchain (`dependency-graph.md:56`) wants, since it makes Cargo respect `rust-version` when selecting dependency versions. `ADR-002:35` and `module-decomposition.md:34-36` both hard-code `resolver = "2"`.

**Consequence:** The workspace loses MSRV-aware dependency resolution, so the MSRV-1.85 pin that `dependency-graph.md:55-56` describes as load-bearing for `clap` 4.6.5 and `ureq` 3.3.0 is unenforced during resolution — a transitive bump can silently raise the required Rust version and break the pinned toolchain contract. The stated rationale also cannot be verified by any reader, so the wrong value survives review. Note this class is invisible to every checker: predicate `resolver` over `/Users/jmagady/Dev/mdlinkcheck-cloud/scripts/spec-lint/` → 0 matches.

---

### P7-S6-018 — four documents give four different answers for the `fuzz/` crate's workspace membership and target crate [MEDIUM]

- `ADR-002:40-42` — "A **third implicit member** `fuzz/` is added as a workspace member for `cargo-fuzz` targets targeting `mdlinkcheck-core`." `ADR-002:54-56` — "fuzz targets must live in a `fuzz/` workspace member … Without the workspace, fuzz targets cannot reference `mdlinkcheck-core`'s internal types."
- `module-decomposition.md:33-36` — the authoritative workspace declaration lists exactly two members: `members = ["crates/mdlinkcheck-core", "crates/mdlinkcheck"]`. No `fuzz`.
- `purity-boundary-map.md:128` — "Fuzz targets (VP-012, VP-013) live in `fuzz/fuzz_targets/` **under the binary crate**."
- `tooling-selection.md:110` — "Fuzz targets compile against `mdlinkcheck-core` directly (**no binary crate needed**)."

`purity-boundary-map.md:128` contradicts both ADR-002 and tooling-selection on the parent crate; `module-decomposition.md:34` contradicts ADR-002 on membership. (Separately, `ADR-002:56`'s claim that workspace membership grants access to "`mdlinkcheck-core`'s **internal** types" is wrong — workspace membership does not bypass `pub` visibility; only the public API is reachable, which is the whole point of ADR-002's own Rationale at `:50-52`.)

**Consequence:** `cargo-fuzz` requires a real workspace member with a correct `Cargo.toml` path. An implementer following `module-decomposition.md:34` produces a workspace where `fuzz/` is not a member (cargo errors on an un-excluded, un-included directory containing a manifest); one following `purity-boundary-map.md:128` places the fuzz crate under the binary crate, where VP-012/VP-013 cannot target `mdlinkcheck-core`'s pure functions without re-exporting them through the shell — breaking ADR-001's boundary. Two of the seven fuzz/Kani deliverables are gated on this.

---

### P7-S6-019 — ADR-004's "BC-2.10.008 must be updated to match" directive is stale; the BC already matches [MEDIUM]

`ADR-004:82-89` (§Architectural contract):

> "`BC-2.10.008` Invariant 3 must NOT reference 'available rayon thread count' as a cap. … BC-2.10.008 should state: 'A dedicated rayon thread pool of size 32 (separate from the file-scan pool) is created at `--online` startup; at most 32 HTTP requests are in-flight at any instant.' This is the authoritative architectural contract; **BC-2.10.008 must be updated to match (product-owner scope)**."

BC-2.10.008 v1.3 already says exactly that:

- `BC-2.10.008.md:57-59` — Invariant 3: "URL checking uses a **dedicated rayon thread pool of fixed size 32**, not the rayon global pool. This isolates network I/O parallelism from file-system traversal and anchor-parsing parallelism."
- `BC-2.10.008.md:49` — PC1: "At most 32 HTTP requests are in-flight simultaneously across all hosts."
- `BC-2.10.008.md:23` — modified: "v1.3: Architect required change: Invariant 3 now specifies dedicated rayon thread pool of size 32 (not general rayon worker pool)."

The phrase "available rayon thread count" no longer occurs in the BC (predicate: `available rayon` over `.factory/specs/behavioral-contracts/` → 0 matches).

**Consequence:** An open product-owner directive in an accepted ADR that resolves to a no-op edit, plus a false implication that the SS-10 concurrency contract is still misaligned. Under a naive reading ("Invariant 3 must NOT reference…"), a product-owner could also read the prescribed replacement text as *additional* wording and duplicate Invariant 3. Convert to a discharged reference to BC-2.10.008 v1.3.

---

### P7-S6-020 — feasibility-review.md (status: accepted, outcome: APPROVE) rests on six stale derived claims, including an NFR set and DI/VP counts that no longer exist [MEDIUM]

The document is `status: accepted`, `outcome: APPROVE`, `version: 1.3`, and its APPROVE verdict is computed over the following, all now wrong:

1. `:56` — "All **7** NFRs from nfr-catalog.md are either: Cross-cutting (NFR-001/002 …, NFR-003 …, NFR-004 portability, NFR-005 …) or Module-scoped (NFR-006 …, NFR-007 …)". **Predicate:** `^## NFR-` over `nfr-catalog.md` → **8** (`:27,49,69,83,99,113,128,142`). **NFR-008 (CI Performance Regression Gate) is absent from the enumeration and from the coherence assessment**, even though this same document's N-003 (`:302-318`) and `tooling-selection.md:176-179` make NFR-008/VP-022 a Phase-3 CI obligation. The "NFR coherence: PASS" verdict was therefore never evaluated against NFR-008. It also still lists NFR-004 as a live cross-cutting NFR at `:57-58` while `:67-73` of the same document declares it retired.
2. `:98-99` — "All **11** domain invariants (DI-001..011) have at least one VP (VP-INDEX.md, **20 VPs total**)." Actual: 13 DIs (DI-012, DI-013 added per `invariants.md:289,343`) and 26 VPs (`VP-INDEX.md:9` `total_vps: 26`). Both counts are wrong, and DI-012/DI-013 — governing the product's highest-risk surface per `decisions.md:79` DD-027 — are outside the verifiability assessment that returned PASS.
3. `:110` — "All subsystem constraints derive from the ADR set (**ADR-001..007**)". ADR-008 exists and is the Key ADR for SS-06 (`ARCH-INDEX.md:90`, `bc-module-map.md:162`).
4. `:359` — "without invalidating the **58** existing BCs". Actual 66 (`bc-module-map.md:39`, `VP-INDEX.md:272`).
5. `:77` — "The **two-pass** pipeline design (DI-008) requires: 1. Pass 1 … 2. Pass 2 …" — Pass 1.5 is absent, though `ARCH-INDEX.md:22` records P4-003 as having converted "two-pass" to "three-phase" elsewhere and `module-criticality.md:19` records four such conversions in that file.
6. `:83-85` — "The data hand-off between passes is the `HashMap<PathBuf, (AnchorTable, Vec<ExtractedLink>)>` seam type, produced entirely in Pass 1. This seam supports clean subsystem integration". Superseded: the seam is three separate products — `AnchorIndex`, `LinkMap` (Pass 1) and `DirIndex` (Pass 1.5, `module-decomposition.md:96,114-123`). The claim "produced entirely in Pass 1" is the pre-SR-016 model that `system-overview.md:86-95` retired.

**Consequence:** The Phase-1b APPROVE gate — the artifact that authorises "the architecture proceeds to Phase 2 story decomposition" (`:370`) — is a stale snapshot. Its three SHOULD-FIX items are addressed to story-writers as "Required action", so the document is read downstream; the two-pass framing and the obsolete seam type in it directly contradict the pipeline story-writers must decompose against. Item 1 is the substantive one: NFR-008 has never been through a feasibility assessment.

---

### P7-S6-021 — bc-module-map's Module Ownership Summary counts disagree with its own enumerations in 5 rows, lists BC-2.12.002 as both primary and secondary for `reporter`, and labels BC-2.04.003 "joint primary" against its own detail table [MEDIUM]

`bc-module-map.md:341-359`. Per-row arithmetic on the quoted cell contents (distinct from P7-S6-009, which concerns the *Primary ownership* table at `:361-381`):

| row | stated count | enumerated BCs in the same cell | count |
|---|---|---|---|
| :344 `link_extractor` | **12** | BC-2.03.001–006 (6), BC-2.04.001–003 (3), BC-2.02.001 (1) | **10** |
| :345 `anchor_table` | **5** | BC-2.05.001–003 (3), BC-2.04.003 (1) | **4** |
| :348 `fragment` | **3** | BC-2.07.004, BC-2.08.003 (2) | **2** |
| :349 `anchor_resolver` | **4** | BC-2.08.001–002, BC-2.08.004 (3) | **3** |
| :353 `http_verdict` | **5** | BC-2.10.002, BC-2.10.005–006 (3) | **3** |
| :354 `reporter` | 8 | "BC-2.12.001–003, BC-2.12.005, BC-2.13.001–002 (primary), **BC-2.12.002 (secondary)**" | BC-2.12.002 appears twice — once inside the primary range and once as secondary |

Two further label defects:

- `:345` labels BC-2.04.003's anchor_table role "**joint primary**", but the SS-04 detail table at `:139` assigns BC-2.04.003 Primary = `link_extractor`, Secondary = `anchor_table`. Summary contradicts detail.
- `:354`'s duplicate is precisely the defect class `:27` (v1.2) claims to have eliminated: "Ownership consistency pass: **corrected 4 summary-vs-detail contradictions** … BC-2.10.001 removed from http_client secondary (it is primary per SS-10, was **self-contradictory**)". The identical self-contradiction remains for BC-2.12.002/reporter.

**Predicate:** magnitude established by per-row arithmetic on the quoted cell contents of `bc-module-map.md:344-358` and against the Primary/Secondary columns of `bc-module-map.md:73-336` — not by corpus-wide counting.

**Consequence:** Both summary tables in this file are unreliable and disagree with each other and with the detail tables (`fragment` = 3 here vs 2 in the Primary table; `anchor_resolver` = 4 vs 3; `http_verdict` = 5 vs 3). A story-writer sizing module workload from either summary gets the wrong number for 5-6 modules, and the "joint primary" label for BC-2.04.003 routes one BC to two owning stories. The v1.2 remediation is a partial fix: it corrected 4 named rows and left the same pattern in 6 others.

---

### P7-S6-022 — dependency-graph.md omits `unicode-normalization` from `reporter`, the module that owns the NFC sort key [MEDIUM]

`dependency-graph.md:83` — "`reporter ← types, serde_json`".

But `reporter` owns the NFC-normalising sort:

- `system-overview.md:176` — "Sort: `sort_unstable_by(NFC-path, line, col, link_target)` — enforces DI-001 determinism (**reporter**)" (ownership corrected from `app` to `reporter` per `system-overview.md:28`, P4-019)
- `module-decomposition.md:134` — "Sort: `findings.sort_unstable_by_key(|f| (nfc(&f.path), f.line, f.col, f.link_target))` [pure]"
- `VP-INDEX.md:67` / `verification-coverage-matrix.md:63` — VP-011 (sort determinism) module = **reporter**
- `tooling-selection.md:67-72` — the `unicode-normalization 0.1.24` pin is load-bearing for "**DI-001 sort key**: NFC-normalized path as the first sort field"

Only `path_resolver` is given the dependency (`dependency-graph.md:78`).

**Predicate:** `unicode-normalization` over `dependency-graph.md` → 3 occurrences (`:32` crate table, `:78` path_resolver dep line, and the header context); `reporter ←` → 1 occurrence (`:83`), listing `types, serde_json` only.

**Consequence:** `dependency-graph.md`'s "Build Order for Phase 3 Story Decomposition" (`:99-108`) is declared mandatory ("Stories MUST implement modules in dependency order to satisfy the Red Gate"). A `reporter` story scaffolded from `:83` has no `unicode-normalization` in scope, so the implementer either fails to compile `nfc()` or relocates the NFC call out of `reporter` — silently invalidating VP-011, whose property statement (`verification-architecture.md:74`) is about the `nfc_path` key computed in that module.

---

### P7-S6-023 — ADR-006's Source/Origin still describes NFR-004 as "now under review" after D-043 retired it [MEDIUM]

`ADR-006:174` — "D-006: Case-sensitive NFC path comparison requirement (not portability — that is NFR-004 scope, **now under review for macOS-only**)".

D-043 closed that review and NFR-004 is retired:

- `nfr-catalog.md:83` — "## NFR-004: Platform Portability — **RETIRED (D-043)**"
- `feasibility-review.md:67-73` — "**D-043 decision — NFR-004 retired:** … retired as vacuous under the macOS-only platform directive (recorded per POL-1; not deleted)"; its v1.3 changelog (`:22`) records the transition from "under review for retirement" to "retired as vacuous"
- `tooling-selection.md:65-72` — "**NFR-004 retired (D-043)**"

ADR-006 v1.4 is the revision that applied D-043 to this file (`ADR-006:12-13`) and correctly hardened the pin's rationale in three places (`:51-56`, `:137-140`, `:153-157`) — it just missed the Source/Origin line.

**Predicate:** `under review` over `.factory/specs/architecture/` → 3 occurrences: ADR-006:174 (live body text) and two historical changelog recitations (tooling-selection.md:20, feasibility-review.md:25). ADR-006:174 is the only live one.

**Consequence:** A reader of the ADR's Source/Origin — the section that establishes which upstream artifacts are authoritative — is told an NFR whose disposition is final is still open, and may re-open a settled D-043 decision or treat the `unicode-normalization 0.1.24` pin as contingent on that review's outcome. The rest of ADR-006 v1.4 explicitly guards against exactly that reading ("This pin **must survive any retirement of NFR-004**", `:53-56`), so the residue is a one-line propagation miss with a wide misreading radius.

---

### P7-S6-024 — ADR-005's Rationale states DI-001 specifies a three-field sort key; DI-001 specifies four [LOW]

`ADR-005:62-65` — "DI-001 specifies the primary sort key `(NFC-normalized file path, line number, column number)`; a `link_target` field … **is added** as a final fourth tie-break to make the key total." Same framing at `:95-100`.

`invariants.md:63-71` now declares the four-field key directly: "All findings are sorted by `(NFC-normalized file path, line number, column number, **link target**)` … The fourth field `link_target` … is the tie-break that makes the key total … (see ADR-005 for totality argument)."

**Consequence:** Cosmetic drift in a resolved direction — the invariant absorbed the ADR's addition and the ADR still presents it as an ADR-local extension of a narrower invariant. Harmless to implementation (both documents state the same 4-field key), but it makes the DI-001↔ADR-005 relationship read as a divergence rather than an alignment, and `DD-012` (`decisions.md:90`) still records the original three-field decision without an update note.

---

### P7-S6-025 — ARCH-INDEX's Subsystem Registry "Phase" column reads "Phase 1" for all 14 subsystems, colliding with the Pass-1/Pass-2 vocabulary used elsewhere [LOW]

`ARCH-INDEX.md:62-77` — every row of the canonical Subsystem Registry ends `| Phase 1 |`, including SS-14 (Exit Code Determination), which executes after everything else.

Adjacent documents use "Pass 1 / Pass 1.5 / Pass 2" for pipeline position and assign SS-07..SS-14 to Pass 2: `feasibility-review.md:78-81` ("1. Pass 1: SS-01 … SS-06 (slugify); 2. Pass 2: SS-07/SS-08 … SS-14 (exit code)") and `:123-126`.

**Consequence:** A uniform column conveys no information and invites the wrong reading. A story-writer interpreting "Phase 1" as pipeline position concludes SS-14 runs in Pass 1, contradicting `feasibility-review.md:81` and `system-overview.md:96-180`. Either rename the column (e.g. "VSDD Phase") or drop it.

---

### P7-S6-026 — ADR-001's proptest VP enumeration is stale (5 of 9 proptest VPs) [LOW]

`ADR-001:49-50` — "Proptest strategies (**VP-008..011, VP-019**) operate on pure functions". `ADR-001:44` — "Phase 6 Kani proofs (VP-001..007)" ✓ correct; `:62` — "Fuzz targets (VP-012, VP-013)" ✓ correct.

**Predicate:** `VP-INDEX.md:11` `proptest_count: 9`; the proptest VPs are VP-008, 009, 010, 011, 019, 023, 024, 025, 026 (`VP-INDEX.md:64-82`). ADR-001 names 5 and omits VP-023..026, all of which target pure-core modules (`url_classifier`, `path_resolver`, `anchor_resolver`, `slug`) and therefore *strengthen* ADR-001's rationale.

**Consequence:** Understates the ADR's own justification. Harmless to implementation; noted because ADR-001 carries no changelog and version 1.0, so this is one more marker that the file has not been revisited since initial draft (cf. P7-S6-004, which is the serious instance of the same root cause).

---

### P7-S6-027 — ADR-007 has no frontmatter `changelog:`, diverging from the other seven ADRs [LOW]

`ADR-007:1-10` frontmatter declares `version: "1.3"` with no `changelog:` key; the history lives in a body table at `ADR-007:149-156`. The other seven ADRs all carry frontmatter `changelog:` lists (ADR-001:10-13, ADR-002:10-13, ADR-003:10-13, ADR-004:10-13, ADR-005:16-25, ADR-006:10-22, ADR-008:10-13), and `ARCH-INDEX.md:22` records establishing that convention ("Version/changelog added to ADR-001/002/003 frontmatter").

**Consequence:** Any machine consumer that reads ADR history from frontmatter (as `check-counts.py:31-59` reads frontmatter generically) sees ADR-007 as having no revision history, and ADR-007 is the ADR with the most consequential revisions — v1.1 corrected inverted exit codes and five invented reason codes, v1.3 rewrote the Decision to the two-layer model. Editorial, but it is the one ADR where losing the changelog to a non-machine-readable location matters most.

---

## Novelty Assessment

Findings are substantive, not editorial: 15 of 27 are CRITICAL/HIGH and each rests on a file:line contradiction or an executed predicate. Three defect *classes* dominate and are, on the evidence in the documents themselves, new to this pass:

1. **Directive-vs-checker inversion** (P7-S6-001). No prior remediation note in any of the 19 documents mentions the POL-14 policy inversion, and `bc-module-map.md` v1.4 (the most recent revision, 2026-08-06) still carries the pre-inversion instruction. The checker change is in git history (`d4e76fa`, `f8ee4eb`) with no spec-side propagation.
2. **Unrepresentable verification** (P7-S6-002, P7-S6-011). `bc-module-map.md:385-458` logs four INC-MAP notes; INC-MAP-001 caught exactly this class for VP-025 and was escalated to CRITICAL BI-010. The same class on VP-007 (a P0 Kani proof, sole VP for two BCs) and across 14 undefined types in `api-surface.md` is unlogged anywhere.
3. **Third-party library semantics** (P7-S6-003, P7-S6-016, P7-S6-017, P7-S6-014). Four independent factual errors about pulldown-cmark's broken-link callback, its `Options` bitmask, Cargo's resolver-3/edition-2024 relationship, and rayon's non-yielding blocking behaviour. By construction no checker can reach these (`check-adr-consistency.py` only pattern-matches exit codes, verdict words and reason codes; `check-counts.py` only recomputes counts), and none of the 19 documents' changelogs records a prior library-semantics review.

Partial-fix regression discipline yielded four findings where a named remediation landed in one file and not its siblings: P4-002 (VP-025 API) reached VP-025/VP-INDEX/bc-module-map but not `verification-architecture.md:78,30`; SR-016 (DirEntries→DirIndex) reached five files but not ADR-001; v1.2's http_client 8→7 reached one bc-module-map table but not the other 20 lines below; D-043's NFR-004 retirement reached three files but not ADR-006's Source/Origin line.

Two whole-document staleness clusters (feasibility-review.md, P7-S6-020; bc-module-map.md's two summary tables, P7-S6-009/021) indicate that `status: accepted` / bolded-Total artifacts are not being re-derived when their inputs change — POLICY 17 with no lint coverage for either file.

**Novelty: HIGH — this pass surfaced three CRITICAL defects, including one (P7-S6-001) that would break the spec-lint gate if executed and one (P7-S6-002) that renders a P0 Kani proof unprovable. The spec corpus has NOT converged. Streak remains at ZERO.**