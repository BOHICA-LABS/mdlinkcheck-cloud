---
document_type: adversarial-review
level: ops
version: "1.0"
status: final
producer: adversary
timestamp: 2026-08-08T00:00:00Z
cycle: phase-1d
pass: 7
shard: 7
frozen_develop_head: f8ee4eb024b8b4a300139ef803d248e8fe40f2fc
frozen_specs_tree: ace1745871122cd1fa2c46cf27c5493cc1083411
frozen_spec_lint_tree: f2392b456c3bd669e3efbe86b3e6eae62e302ed1
severity_vocabulary: "CRITICAL/HIGH/MEDIUM/LOW (single vocabulary per PG-012 ruling)"
findings_total_self_declared: 38
inputs: []
input-hash: "ace1745"
traces_to: STATE.md
---
# Pass 7 — Shard 7: verification layer (all 26 VP bodies + VP-INDEX)

```
scope: "26 VP bodies + VP-INDEX.md read in full"
files_read_in_full:
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/VP-INDEX.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-001-slug-total.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-002-slug-deterministic.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-003-slug-duplicate-uniqueness.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-004-fragment-split.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-005-exit-code-io-error.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-006-exit-code-clean.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-007-http-verdict-total.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-008-path-nfc-comparison.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-009-nfc-idempotent.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-010-allow-component-boundary.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-011-sort-deterministic.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-012-slug-fuzz.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-013-fragment-fuzz.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-014-code-context-exclusion.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-015-two-pass-anchor-complete.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-016-ignored-files-anchor-targets.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-017-scan-terminates.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-018-slug-worked-examples.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-019-one-verdict-per-link.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-020-html-anchor-narrow-scope.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-021-no-undefined-reason-codes.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-022-regression-gate.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-023-url-classifier-totality.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-024-path-resolver-trailing-slash.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-025-anchor-resolver-totality.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-026-slug-differential-fidelity.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/invariants.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/api-surface.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/module-decomposition.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/verification-architecture.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/verification-coverage-matrix.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/prd-supplements/nfr-catalog.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/decisions/ADR-006-strict-path-model.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/scripts/spec-lint/check-counts.py
partially_read (targeted): architecture/tooling-selection.md:30-179, prd-supplements/test-vectors.md:255-299,
  prd-supplements/error-taxonomy.md (reason-code tables), behavioral-contracts/ss-06/BC-2.06.001.md:100-128,
  behavioral-contracts/ss-10/BC-2.10.002.md (alive occurrences), .factory/planning/market-intelligence.md:180-229,
  scripts/spec-lint/check-placeholders.py (test-sufficient join)
findings_total: 38
severity_counts: CRITICAL 4 / HIGH 12 / MEDIUM 14 / LOW 8
verdict: The verification layer is structurally real but semantically porous — four false-green paths let a Phase-6 gate pass with the property unverified; the 2026-08-07 BI-025 vacuity-repair burst never propagated to VP-INDEX or either architecture anchor doc; and 11 symbols/types named inside `rust` fences are declared nowhere in the workspace.
```

---

## VACUITY ROSTER

"Vacuous?" answers the posed question literally: *could an empty body or a constant-returning function satisfy the property as written?*

| VP id | sole coverage for | vacuous? | proof method in body | tool in VP-INDEX | agree? |
|---|---|---|---|---|---|
| VP-001 | CAP-006 PC1 (totality) — no DI | yes (by design: panic-freedom) | kani (Kani 0.67.0), vp-001:64 | kani | yes |
| VP-002 | NFR-003 (per VP-INDEX:58 / vcm:54) | **yes — unfalsifiable** (see 002) | kani, vp-002:50 | kani | yes |
| VP-003 | DI-013 (with VP-026) | no | kani, vp-003:71 | kani | yes |
| VP-004 | DI-003 (with VP-013) | no | kani, vp-004:57 | kani | yes |
| VP-005 | DI-011 | no | kani, vp-005:56 | kani | yes |
| VP-006 | DI-010 | no | kani, vp-006:59 | kani | yes |
| VP-007 | BC-2.10.002 / .005 / .006 | no (but cannot compile — 003) | kani, vp-007:72 | kani | yes |
| VP-008 | DI-002 (with VP-009) | no | proptest 1.6.0, vp-008:57 | proptest | yes |
| VP-009 | DI-002 (with VP-008) | **yes — identity fn passes** | proptest 1.6.0, vp-009:54 | proptest | yes |
| VP-010 | DD-013, BC-2.11.002 | no | proptest 1.6.0, vp-010:49 | proptest | yes |
| VP-011 | **DI-001 (sole)** | partial — harness 1 vacuous; sort-key order never asserted (017) | proptest 1.6.0, vp-011:62 | proptest | yes |
| VP-012 | R-001/R-002 | yes (by design: fuzz no-panic) | fuzz cargo-fuzz 0.13.1, vp-012:49 | fuzz | yes |
| VP-013 | DI-003 (with VP-004) | yes (by design; + dead assertion 033) | fuzz cargo-fuzz 0.13.1, vp-013:49 | fuzz | yes |
| VP-014 | **DI-004 (sole)** | no — but 2 of 5 contexts unfixtured (004) | integration nextest 0.9.129, vp-014:65 | integration | yes |
| VP-015 | **DI-008 (sole)** | no (v1.3 repair) | integration nextest 0.9.129, vp-015:60 | integration | yes |
| VP-016 | **DI-006 (sole)** | no (v1.3 repair) | integration nextest 0.9.129, vp-016:71 | integration | yes |
| VP-017 | **DI-009 (sole)** | no (v1.4 repair) | integration nextest 0.9.129, vp-017:69 | integration | yes |
| VP-018 | DI-012 partial, NFR-006 | no | unit nextest 0.9.129, vp-018:67 | unit | yes |
| VP-019 | **DI-005 (sole, Partial)** | no (v1.2 repair) | proptest 1.6.0, vp-019:63 | proptest | yes |
| VP-020 | **DI-007 (sole)** | no | integration nextest 0.9.129, vp-020:60 | integration | yes |
| VP-021 | **NFR-007 (sole)** | no (`total_checked > 0`, vp-021:137) | integration cargo nextest, vp-021:79 | integration | yes |
| VP-022 | **NFR-008 / D-013 (sole)** | **yes — threshold uncommitted, wrong metric** (012) | integration cargo bench/hyperfine, vp-022:98 | integration | yes |
| VP-023 | BC-2.07.007 | no (v1.1 repair) | proptest 1.6.0, vp-023:79 | proptest | yes |
| VP-024 | BC-2.07.008 | no | proptest 1.6.0, vp-024:66 | proptest | yes |
| VP-025 | BC-2.08.001/002/004 | no (cannot compile — 011) | proptest 1.6.x, vp-025:100 | proptest | yes |
| VP-026 | DI-012, DI-013, FM-002 | no (freshness gate inoperative — 006) | proptest 1.6.x + serde_json 1.x, vp-026:226 | proptest | yes |

**Proof-method/tool join result:** 26 of 26 VP bodies agree with the `tool` column in VP-INDEX.md:57-82. No proof-method degradation found in any VP body. **Predicate:** each VP body's `proof_method:` frontmatter field and its "Proof Method" table `Method` cell were read individually against VP-INDEX.md:57-82; zero divergences. The proof-method disagreements all live one level out — in BC bodies (findings 001, 010, 015, 016) and in `verification-architecture.md` (008, 009).

---

### P7-S7-001 — BC-2.06.001 attributes DI-012 rules 3 and 6 to VP-002, which proves neither [CRITICAL]

`/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-06/BC-2.06.001.md:111-112`:

```
| VP-002 | Space→hyphen is 1:1 (trap T1) | kani |
| VP-002 | Unicode word chars preserved (trap T2) | kani |
```

VP-002's entire property is determinism. `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-002-slug-deterministic.md:39` — "two calls to `compute_slug(s, &mut counter)` with equivalent initial states return byte-identical `String` values" — and the harness (vp-002:71-75) is `let slug1 = compute_slug(...); let slug2 = compute_slug(...); assert_eq!(slug1, slug2);`. There is no assertion anywhere in VP-002 about spaces, hyphens, or Unicode word characters. VP-INDEX.md:58 correctly assigns VP-002 no DI at all (`— (CAP-006, NFR-003)`).

DI-012 rule 3 (invariants.md:304-306) is the FM-001 hyphen-collapse shape — the single highest-risk slug defect in the corpus, per `market-intelligence.md` T1. DI-012 rule 6 (invariants.md:310) is Unicode retention. BC-2.06.001 tells a Phase-6 formal-verifier that both are discharged by a P0 Kani proof.

**Predicate:** `grep -n "VP-0[0-9][0-9]|test-sufficient" .factory/specs/behavioral-contracts/` → 181 occurrences across 67 files; BC-2.06.001's Verification Properties table contains exactly 5 rows (BC-2.06.001.md:110-114), two of which are the VP-002 rows above.

**Consequence:** A `slugify` implementation that collapses hyphen runs (`ai-automation` instead of `ai--automation`) and ASCII-folds Cyrillic satisfies VP-002's harness perfectly. If VP-026's oracle fixture is truncated or its freshness gate is inoperative (finding 006), rules 3 and 6 pass Phase 6 entirely unverified while BC-2.06.001 records them as kani-proven.

---

### P7-S7-002 — VP-002 is an unfalsifiable P0 Kani proof: no compiling implementation can fail it [CRITICAL]

`/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-002-slug-deterministic.md:56-76`. The harness constructs two counters from the same concrete `count`, calls `compute_slug(s, ...)` twice on the same `s`, and asserts the results are equal.

CBMC/Kani models Rust execution deterministically. For any pure function of `(&str, &mut DuplicateCounter)` — which `compute_slug` is required to be (`module-decomposition.md:49` marks `slug` pure; `api-surface.md:69` "pure, Kani target") — `f(x) == f(x)` is a tautology under the model. `fn slugify(_: &str) -> String { String::new() }` passes. `fn compute_slug(_,_) -> String { "x".into() }` passes.

The property statement over-claims what the harness can establish: vp-002:39 asserts "There is no hidden global state, thread-local state, or random element in the computation." No assertion in the harness observes global or thread-local state, and Kani cannot express a second thread here.

The one thing a determinism proof could genuinely catch — `HashMap`/`RandomState` iteration-order nondeterminism — is already structurally excluded: `api-surface.md:73` declares `pub struct DuplicateCounter(BTreeMap<String, u32>)`.

**Predicate:** VP-INDEX.md frontmatter `p0_count: 7` (VP-INDEX.md:15); VP-002 is one of the 7 P0 Kani rows (VP-INDEX.md:58). `grep -c "assert" vp-002-slug-deterministic.md` → the sole assertion is line 75, `assert_eq!(slug1, slug2)`.

**Consequence:** 1 of 7 P0 formal-proof slots is consumed by a tautology, and it is the declared discharger of NFR-003 (finding 005). The Phase-6 "MUST prove" gate reports 7/7 green with 6 real proofs.

---

### P7-S7-003 — VP-007's harness references five types/functions that exist nowhere; the dns/tls encoding is explicitly "TBD by implementer" [CRITICAL]

`/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-007-http-verdict-total.md` uses, inside `#[kani::proof]` fences:

- `verdict.kind` (vp-007:87, 98, 105, 115, 120, 134, 139, 144, 159, 161) — `api-surface.md:124` declares `pub enum Verdict { Clean, Broken(FailureReason), Indeterminate(FailureReason) }`. No `kind` field.
- `VerdictKind::Alive | VerdictKind::Broken(_) | VerdictKind::Indeterminate(_)` (vp-007:88) — no `VerdictKind` type exists, and `Alive` as a *verdict* variant is what VP-006 v1.1 (vp-006:26) and DD-022 (invariants.md:135-142) explicitly forbid.
- `classify_response_with_error(...)` (vp-007:133, 138, 143) — not in `api-surface.md`, not in `module-decomposition.md`.
- `HttpError::DnsFailure | ::TlsError | ::Timeout` (vp-007:133, 138, 143) — no `HttpError` enum anywhere.
- `HttpAttempt::Get` (vp-007:158) — `api-surface.md:103` declares `pub enum HttpAttempt { Head, GetFallback }`. `Get` is not a variant.

vp-007:126-129 concedes: "*implementation detail: e.g. status=0 + attempt=DnsFailure variant, or via a dedicated HttpAttempt variant — exact encoding TBD by implementer*", and vp-007:166-172 leaves the whole network-error signature undecided.

**Predicate:** `grep -rn "enum PathVerdict|struct IoError|enum IoError|enum FailureReason|enum ReasonCode|struct AllowPrefix|enum HttpError|enum VerdictKind|fn files_match|fn nfc_normalize|fn sort_findings|fn run_offline|fn with_count" .factory/specs` → **1** match total (`ADR-006-strict-path-model.md:64: pub fn files_match(a: &str, b: &str) -> bool`). `HttpError` and `VerdictKind` have zero declarations.

**Consequence:** VP-007 is the sole VP for BC-2.10.002, BC-2.10.005 and BC-2.10.006 (VP-INDEX.md:223, 226, 227). Three BC bodies record its dns-failure/tls-error obligations as `kani (P0)` (BC-2.10.005.md:69, BC-2.10.006.md:71, BC-2.10.002.md:160). A harness whose target function signature is deferred to the implementer cannot be written in Phase 6 against a locked API — the most likely outcome is that the two network-error harnesses are silently dropped and only `verify_vp007_http_verdict_total` is committed, at which point `dns-failure → broken` and `tls-error → broken` (both DI-010 carve-outs per ADR-007 v1.1) go unverified while three BCs claim P0 Kani coverage. The `match &verdict.kind { A | B | C => {} }` "totality" assertion (vp-007:87-89) is additionally a no-op — an exhaustive match over a closed enum compiles to nothing.

---

### P7-S7-004 — DI-004 is reported "All Covered? Yes" but VP-014 has no fixture for indented code blocks and none for the `anchor_table` side, which BC-2.04.003 itself states is uncovered [CRITICAL]

VP-INDEX.md:91 — `| DI-004 | Code context exclusion structural | VP-014 | integration | Yes |`. `verification-coverage-matrix.md:111` — "All 13 DIs have VP coverage (13/13)". VP-014 is the sole VP.

`vp-014-code-context-exclusion.md:49-54` enumerates five excluded contexts; case 3 is "**Indented code blocks** — 4-space indented paragraphs". The harness (vp-014:71-113) contains exactly four `#[test]` functions: `vp014_fenced_code_no_links`, `vp014_inline_code_no_links`, `vp014_html_pre_block_no_links`, `vp014_html_comment_no_links`. **There is no indented-code fixture.** Yet `BC-2.04.002.md:69` records `| VP-014 | Indented code blocks yield no links | integration |`.

Worse, `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-04/BC-2.04.003.md:50` states in plain prose:

> "VP-014 covers the `link_extractor.rs` side. No current VP covers the `anchor_table.rs` side;"

and BC-2.04.003.md:96 records `| VP-014 | anchor_table::build produces no entry for heading-like lines inside fenced code | integration (anchor_table.rs) — new test required in this story |`. VP-014's `module:` frontmatter is `link_extractor` (vp-014:15) and every fixture calls `extract_links`. No fixture touches `build_anchor_table`.

vp-014:65 and :120 further claim "Corpus of 13+ Markdown fixtures" / "13 corpus fixtures from gene-transfusion-assessment.md" while presenting 4.

**Predicate:** `grep -n "fn vp014" vp-014-code-context-exclusion.md` → 4 matches (lines 72, 90, 98, 107). `grep -rn "indented" vp-014-code-context-exclusion.md` → 2 matches, both prose (lines 52, 65); zero in the harness.

**Consequence:** A heading-like line inside a fenced code block that leaks into the anchor table manufactures a *false-negative* (a genuinely broken `#anchor` link silently resolves against the phantom anchor) — the exact class DI-004 exists to prevent. Both this and the indented-code path pass Phase 6 with DI-004 marked fully covered. The gap is documented inside a BC and invisible to every index.

---

### P7-S7-005 — NFR-003 (output determinism) is discharged to VP-002; the harness that actually implements NFR-003's stated validation method is uncredited [HIGH]

`VP-INDEX.md:58` DI-Covered cell: `— (CAP-006, NFR-003)`. `verification-coverage-matrix.md:54`: `| VP-002 | slug | kani | 6 | P0 | NFR-003 |`. `verification-architecture.md:60` Invariant column: `CAP-006, NFR-003`.

`nfr-catalog.md:76-78` defines NFR-003 as: "Two invocations of `mdlinkcheck` with identical inputs and flags, under any thread-scheduling environment, produce byte-identical **stdout**" with validation method "(2) diff stdout across `RAYON_NUM_THREADS=1` and `RAYON_NUM_THREADS=4` on the same fixture."

VP-002 proves nothing about stdout, invocations, or thread scheduling. The harness that *does* implement exactly NFR-003's stated method is `vp011_binary_output_stable_text` / `_json` (`vp-011-sort-deterministic.md:120-153`), which runs the binary at `RAYON_NUM_THREADS` 1/2/4/8/16 and byte-compares stdout. VP-011's DI-Covered cell is `DI-001` only (VP-INDEX.md:67) — NFR-003 is not credited to it anywhere.

**Predicate:** `grep -rn "NFR-003" .factory/specs/verification-properties/` → **1** occurrence: `VP-INDEX.md:58`. The string NFR-003 does not appear in `vp-002-slug-deterministic.md` at all, nor in `vp-011-sort-deterministic.md`.

**Consequence:** POLICY 4 semantic mis-anchor. NFR-003 is a zero-tolerance correctness NFR (`nfr-catalog.md:77` "100% — zero tolerance for nondeterminism") whose sole declared discharger is an unfalsifiable Kani tautology on a different function at a different layer. If VP-011's integration harness is deprioritised in Phase 3 (it is tagged `test-sufficient`-adjacent and lives outside VP-011's `proptest` tool assignment), NFR-003 has no verification at all.

---

### P7-S7-006 — VP-026's oracle-freshness CI check diffs the fixture against itself via a file that is never created [HIGH]

`/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-026-slug-differential-fidelity.md:145-154`:

```sh
just regen-slug-vectors
jq -S '{runs, provenance: {github_slugger_version, generator_script_sha256}}' \
    tests/fixtures/slug-oracle-vectors.json > /tmp/new.json
jq -S '{runs, provenance: {github_slugger_version, generator_script_sha256}}' \
    tests/fixtures/slug-oracle-vectors.json.committed > /tmp/committed.json
diff /tmp/new.json /tmp/committed.json
```

`just regen-slug-vectors` overwrites `tests/fixtures/slug-oracle-vectors.json` (vp-026:141, :501). Nothing in this VP, in `tooling-selection.md:129-147`, or in the Phase 3 Obligation table (vp-026:498-510) ever creates `tests/fixtures/slug-oracle-vectors.json.committed`. Under GitHub Actions' default `bash -e`, `jq` on a nonexistent path exits non-zero and the step fails unconditionally; if a stale `.committed` copy ever exists, the diff compares regenerated output against an arbitrary snapshot. Either way the gate produces a signal uncorrelated with fixture freshness.

vp-026:156-158 asserts the security purpose plainly: "`github_slugger_version` and `generator_script_sha256` MUST remain inside the diff scope so an unreviewed `github-slugger` upgrade or generator script change is detected." That protection does not function.

The VP-026 v1.1 changelog (vp-026:27, item P4-011) records this as a *fix*: "replaced git diff with jq diff excluding generated_at and node_version" — the replacement introduced the defect.

**Predicate:** `grep -rn "slug-oracle-vectors.json.committed" .factory/specs` → **1** occurrence, `vp-026-slug-differential-fidelity.md:152`. No creating step exists.

**Consequence:** VP-026 is the sole artifact that upgrades DI-012 and DI-013 from "Partial" to "Yes" (VP-INDEX.md:99-100, verification-architecture.md:152-154) and the sole closure for FM-002. Its correctness rests entirely on a committed fixture whose provenance-pin freshness check is inoperative. A `github-slugger` upgrade to v3 with different hyphen semantics would leave a stale v2.0.0 fixture in place, `vp026_oracle_corpus_exact_match` would still pass (it asserts the *recorded* version string equals "2.0.0", vp-026:287-292 — a self-consistent tautology once the fixture is stale), and DI-012 would be silently unverified against the real reference. POLICY 11: this is a security-critical regression detector emitting a signal that is not a function of the thing it claims to detect.

---

### P7-S7-007 — The 2026-08-07 BI-025 vacuity-repair burst did not propagate to VP-INDEX or either architecture anchor document [HIGH]

Five VP bodies carry `2026-08-07` BI-025 vacuity-repair changelog entries that materially changed their properties and harnesses:

- `vp-015-two-pass-anchor-complete.md:24-26` (v1.3, control broken links added to all 3 fixtures)
- `vp-016-ignored-files-anchor-targets.md:24-26` (v1.3, + new Fixture 5 for the DI-006 Pass 1.5 missing-target rule)
- `vp-017-scan-terminates.md:24-26` (v1.4, + new Fixture 3)
- `vp-019-one-verdict-per-link.md:24-26` (v1.2, + new completeness property P2)
- `vp-023-url-classifier-totality.md:24-26` (v1.1, + three new correctness properties P4/P5/P6)

`VP-INDEX.md` is version `1.6` dated `2026-08-06` (VP-INDEX.md:4, :21) with no BI-025 entry. `verification-architecture.md` is v1.10 dated 2026-08-06 (lines 5, 17). `verification-coverage-matrix.md` is v1.8 dated 2026-08-06 (lines 5, 17). VP-INDEX.md:5 preamble states these are mandatory propagation targets: "Any change to VP count, module assignment, **proof method**, or phase tier MUST propagate to..." — and the note columns encode proof content, e.g. VP-INDEX.md:79 still describes VP-023 as only "url_classifier totality proptest; empty string returns Malformed(_), never NonHttp", omitting the three correctness properties that are now the VP's primary anti-vacuity content; `verification-architecture.md:76` likewise.

**Predicate:** `grep -rl "BI-025" .factory/specs` → **5** files, all under `verification-properties/`: vp-015, vp-016, vp-017, vp-019, vp-023. Zero matches in VP-INDEX.md, verification-architecture.md, verification-coverage-matrix.md.

`check-counts.py` (read in full) validates VP-INDEX frontmatter counts, the two arithmetic invariants (lines 272-286), and `verification-coverage-matrix.md`'s Totals row (lines 348-372). It **never opens `verification-architecture.md`**, and it never reads any VP body. POSITIVE-COVERAGE EVIDENCE: the checker's output is `Check passed: {checks} count checks passed` (check-counts.py:474) where `checks` counts only count-comparisons; no shape in that checker inspects VP note text, DI-Coverage "All Covered?" cells, or the Provable Properties Catalog. This defect class is unenforced.

**Consequence:** POLICY 9 violation with blast radius 3 documents × 5 VPs. Downstream consumers (product-owner back-filling BC VP columns per VP-INDEX.md:126-128; formal-verifier reading the Provable Properties Catalog) work from descriptions that predate the vacuity repairs. Findings 008 and 009 are the concrete damage.

**Tag:** [process-gap]

---

### P7-S7-008 — VP-025 is described in the retired `Hit`/`Miss` vocabulary in four files after v1.1 deleted that type [HIGH]

`vp-025-anchor-resolver-totality.md:27` (v1.1, 2026-08-06) records: "`resolve_anchor` returns `Verdict {Clean, Broken(FailureReason), Indeterminate(FailureReason)}` **not** `AnchorVerdict {Hit,Miss}`". The body was fully rewritten; `Hit`/`Miss` appear nowhere in VP-025's properties or harness.

Four downstream artifacts still use the deleted vocabulary:

- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/verification-architecture.md:78` — "fragment present in table → **Hit**; fragment absent → **Miss**"
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-08/BC-2.08.001.md:78` — "Anchor-resolver totality (every input resolves to **Hit** or non-panic outcome)"
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-08/BC-2.08.002.md:103` — identical wording
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-08/BC-2.08.004.md:74` — identical wording

The three BC rows are additionally *weaker* than VP-025: "resolves to Hit or non-panic outcome" is a disjunction satisfied by any non-panicking implementation — it drops VP-025's hit-correctness (P2), miss-correctness (P3), case-sensitivity (P4) and never-Indeterminate properties entirely. `verification-architecture.md:30` (v1.6 changelog) additionally still says "AnchorTable is a HashMap", contradicting vp-025:104 ("`AnchorTable` is a `HashSet<String>` (per `api-surface.md:80`)") and api-surface.md:80.

**Consequence:** Blast radius 4 files → HIGH per partial-fix regression discipline. A test-writer implementing BC-2.08.001's verification row would write a no-panic smoke test and consider the row discharged, losing the false-positive/false-negative correctness properties that are the entire point of VP-025 (vp-025:77-80 cites lychee #1457/#1613/#1709 and markdown-link-check #304/#91 as the incumbent bugs these properties exist to prevent).

---

### P7-S7-009 — verification-architecture.md claims VP-019 discharges DI-005 in full; the missing half is registered as a VP nowhere [HIGH]

`verification-architecture.md:75`: `| VP-019 | Each link in extract_links output has exactly one verdict path | link_extractor | DI-005, BC-2.03.001 |` and `verification-architecture.md:142`: `| DI-005 | Exactly one verdict per link | VP-019 | P1 |` — no qualifier.

VP-019 v1.1 explicitly retired that claim. `vp-019-one-verdict-per-link.md:29`: "retitled from 'Single Verdict per Link' (invented BC title) to what the VP actually proves — extract_links is duplicate-free". vp-019:50 states the residual gap precisely:

> "DI-005 requires that each extracted link is assigned exactly ONE verdict downstream (no-verdict and two-verdict cases are the real risk — e.g. `[x](missing.md#anchor)` generating both `file-not-found` from `path_resolver` AND `anchor-not-found` from `anchor_resolver`) ... The complete DI-005 guarantee requires a Phase 3 pipeline integration test"

VP-INDEX.md:92 does carry the qualifier ("Partial — ... requires a Phase 3 integration test"), and `verification-coverage-matrix.md:71` carries none (`| VP-019 | link_extractor | proptest | 3 | P1 | DI-005 |`), while vcm:111 asserts "All 13 DIs have VP coverage (13/13)". The required Phase-3 pipeline test has no VP ID, no row in VP-INDEX's catalog, and no entry in `tooling-selection.md:129-147` Test Target Layout.

**Predicate:** `grep -rn "DI-005" .factory/specs/verification-properties/` → occurrences in VP-INDEX.md:92 (qualified) and vp-019 lines 29, 50, 57 (all describing the gap). No VP file claims the downstream half.

**Consequence:** DI-005 is the invariant that makes the exit code well-defined (`invariants.md:144` — "The exit code is a pure function of the verdict multiset (DI-011). An undefined or dual verdict makes the exit code undefined"). Two of three coverage documents report it fully discharged. The double-verdict case named in vp-019:50 — a link to a missing `.md` file *with* a fragment — is the single most common broken-link shape in the product's domain, and nothing verifies that it yields one finding rather than two.

---

### P7-S7-010 — BC-2.03.002 attributes reference-definition semantics to VP-019, whose generators emit only inline links [HIGH]

`/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-03/BC-2.03.002.md:89-90`:

```
| VP-019 | Reference definitions at EOF are resolved for uses at line 1 | proptest |
| VP-019 | Label matching is case-insensitive | proptest |
```

BC-2.03.002 is "Reference-style links". VP-019's two strategies are `arb_markdown_with_links()` (vp-019:149-152) and the inline `dests` collection (vp-019:122); both build markdown exclusively from `arb_inline_link()` (vp-019:155-161), which emits `format!("[{}]({}.md)", text, dest)` — inline links only. No reference definition (`[label]: url`), no reference use (`[text][label]`), and no case variation is ever generated. VP-019's own scope note (vp-019:48) confines it to "one file at a time" `(dest, line, col)` deduplication.

VP-INDEX.md:160 compounds this: `| BC-2.03.002 | Reference-style links | VP-019 | one-verdict property covers all extraction forms |` — "all extraction forms" is false for a generator that emits one form.

BC-2.03.001.md:73 has the same defect in narrower form: `| VP-019 | Every Tag::Link/Tag::Image outside code context is extracted | proptest |` — `arb_inline_link` never produces an image (`![alt](x.png)`), so the `Tag::Image` half of BC-2.03.001's own H1 ("Inline link/image extraction") is unverified.

**Consequence:** VP-019 is the only real VP on BC-2.03.002 (VP-INDEX.md:160). Forward-reference resolution of reference definitions is a documented incumbent failure class (`invariants.md:228-229`, market-intel T4/T15) and case-insensitive label matching is a CommonMark requirement. Both are recorded as proptest-verified and neither is generated.

---

### P7-S7-011 — VP-025's harness constructs `AnchorTable(entries)`, a private tuple field, from an integration-test crate; v1.1 deleted the only constructor [HIGH]

`vp-025-anchor-resolver-totality.md` builds the table by tuple-struct construction at lines 165, 193, 244, 271: `let anchor_table = AnchorTable(table_entries);`. The harness file is `tests/proptest_anchor_resolver.rs` (vp-025:135) — a separate integration-test crate importing `mdlinkcheck_core::anchor_table::AnchorTable` (vp-025:141).

`api-surface.md:80` declares `pub struct AnchorTable(HashSet<String>);` — the field is **not** `pub`. Tuple-struct construction from outside the defining module is E0603/E0451. `api-surface.md:81-82` exposes only `build_anchor_table(headings: &[ParsedHeading])` and `build_with_html(...)`; there is no `From<HashSet<String>>`, no `new`, no `insert`.

vp-025:27 records the removal as deliberate: "`AnchorTable::from_map()` removed (not in declared API)". The v1.1 remediation removed the constructor without supplying a replacement, leaving all five harnesses unbuildable.

The same changelog line concedes the precedent: "INC-MAP-001 re-opened — prior closure was against a non-compiling harness with wrong types." This is the second non-compiling revision of the same harness.

**Consequence:** VP-025 is the sole VP for the `anchor_resolver` module (`verification-coverage-matrix.md:95`, :104) and is cited by BC-2.08.001, BC-2.08.002 and BC-2.08.004. Phase 3 cannot land it without either an API change (adding a `pub` constructor, which must propagate to api-surface.md and purity-boundary-map.md) or relocating the harness into `src/` as a unit test — an unresolved decision that blocks the story.

---

### P7-S7-012 — VP-022 contradicts its own Metric section, contradicts NFR-008's run count and harness, and depends on a tool absent from tooling-selection.md [HIGH]

Four mutually inconsistent statements inside `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-022-regression-gate.md`:

1. **Library call vs process wall-clock.** vp-022:86-90 — "**process wall-clock p95 over 10 warm runs** ... This is **NOT library call latency**, NOT CPU time, NOT mean ... Process wall-clock from `main()` entry to exit ... Includes startup". The harness (vp-022:110-117) benchmarks `mdlinkcheck_core::run_offline(&corpus_path)` — a library call inside `criterion`'s `b.iter()`, which by construction excludes process startup, arg parsing, and emit-to-stdout.
2. **Mean vs p95.** vp-022:130 — `# Fail if p95 > 500ms (criterion reports mean; CI uses 2x mean as p95 proxy)` — after line 87 states the metric is "NOT mean". `--threshold-ms 500` is passed without specifying whether the comparison is against mean or 2×mean.
3. **Run count.** vp-022:86 says "10 warm runs"; vp-022:149-151 calibration says "20 warm `hyperfine` passes ... `--runs 20`"; `nfr-catalog.md:155` says "p95 over 5 runs (`hyperfine --warmup 1 --runs 5`)". Three values for one statistic. (p95 of 5 samples is the maximum, not a percentile.)
4. **Harness tool.** `nfr-catalog.md:156` — "Harness | `hyperfine` in CI benchmark job". VP-022's harness is `criterion`. `criterion` appears in neither `tooling-selection.md`'s Verification Toolchain table (lines 36-45) nor its Test Dependencies table (lines 49-55), so it is unpinned.

Additionally the corpus is contradicted: `nfr-catalog.md:149,151` fixes it at "100 `.md` files ... 1/5 the size" of NFR-001's corpus; vp-022:52-57 says the Tier A composition "is defined when the benchmark is first authored (Phase 3)" and never states 100.

**Predicate:** `grep -n "Kani 0\.67|proptest 1\.6|cargo-fuzz 0\.13|nextest 0\.9\.129|criterion|hyperfine|unicode-normalization" .factory/specs/architecture/tooling-selection.md` → matches for hyperfine (lines 17, 20, 26, 43, 171) and unicode-normalization (61, 63, 66); **zero matches for `criterion`**.

**Consequence:** VP-022 is the sole verification of NFR-008, a merge-blocking gate (`nfr-catalog.md:157` "Blocking gate | Yes"). As written it measures the wrong quantity (library latency, not process wall-clock), against the wrong statistic (2× mean as a p95 proxy), with an uncommitted threshold (vp-022:141 "~500ms is a placeholder"), using an unpinned tool. A gate in this state either blocks all merges or blocks none; neither state detects a performance regression.

---

### P7-S7-013 — `PathVerdict` is a return type in four documents and is pattern-matched on three variants by VP-024, but the enum is never defined [HIGH]

`PathVerdict` appears as the return type of `resolve_path`/`path_resolver::resolve` in `api-surface.md:89`, `module-decomposition.md:53, 99, 129`, and `purity-boundary-map.md:58`. `vp-024-path-resolver-trailing-slash.md` matches on three of its variants at lines 43-44, 99, 100, 103, 118: `PathVerdict::Broken(FailureReason::FileNotFound)`, `PathVerdict::Broken(FailureReason::TargetIsDirectory)`, `PathVerdict::Clean`, plus a catch-all `other`.

Neither `PathVerdict` nor `FailureReason` is declared anywhere. `api-surface.md:118-127` "Key Shared Types" lists `Finding`, `Verdict`, `ParsedHeading`, `ExtractedLink` — `FailureReason` is referenced inside `Verdict`'s variants but never defined; `PathVerdict` is absent entirely. `module-decomposition.md:60` lists the `types` module contents as `Link, ExtractedLink, Finding, Verdict, AnchorTable, DirIndex, DirEntryInfo, EntryKind` — no `PathVerdict`, no `FailureReason`, no `IoError`, no `ReasonCode`.

**Predicate:** `grep -rn "PathVerdict" .factory/specs` → 11 occurrences across 4 files, all as a *usage*; `grep -rn "enum PathVerdict" .factory/specs` → **0** matches. Same predicate for `enum FailureReason`, `enum ReasonCode`, `struct IoError`/`enum IoError` → **0** matches each.

**Consequence:** VP-024's harness pins the precise `FileNotFound` vs `TargetIsDirectory` discrimination that BC-2.07.008 exists to protect ("easy to swap under refactor", vp-024:133). It cannot be written until someone invents the enum, and whoever invents it is unconstrained — including on whether `PathVerdict::Clean` exists at all (vp-024:118 asserts it does; `api-surface.md`'s `Verdict::Clean` is a *different* type). `IoError` is likewise a parameter of `exit_code` (api-surface.md:115) that VP-005 and VP-006 construct symbolically (vp-005:71, vp-006:73) without a definition.

---

### P7-S7-014 — Three BC↔VP-INDEX assignment-set mismatches; the checker's join is one-directional [HIGH]

VP-INDEX.md:126-128 declares itself the authority the product-owner uses to back-fill BC VP columns. Three sets disagree:

| BC | VP-INDEX row | BC body Verification Properties table | drift |
|---|---|---|---|
| BC-2.06.001 | `VP-001, VP-002, VP-012, VP-018, VP-026` (VP-INDEX.md:186) | VP-001, VP-002, VP-002, VP-018, VP-026 (BC-2.06.001.md:110-114) | **VP-012 absent from body** |
| BC-2.01.004 | `VP-017` (VP-INDEX.md:139) | VP-017, VP-016 (BC-2.01.004.md:79-80) | **VP-016 absent from index row** |
| BC-2.05.001 | `VP-015` (VP-INDEX.md:178) | VP-015, VP-016 (BC-2.05.001.md:110-111) | **VP-016 absent from index row** |

`vp-012-slug-fuzz.md:14` declares `source_bc: BC-2.06.001`, so the fuzz target's own anchor points at a BC that does not list it — POLICY 8 (bc array changes propagate to body).

D-057 check on enforcement: `scripts/spec-lint/check-placeholders.py` **does** implement a genuine runtime JOIN against VP-INDEX for the `test-sufficient` sentinel (lines 99-147, 177-202: rejected "if VP-INDEX assigns a real VP or has no row for the BC"). POSITIVE-COVERAGE NOTE: that join fires **only** when `first_cell == "test-sufficient"` (check-placeholders.py:178). A BC row whose first cell is a real `VP-NNN` is never joined back against VP-INDEX, so all three mismatches above are structurally outside the checker's reach.

**Consequence:** Blast radius 3 files → HIGH. `verification-coverage-matrix.md:84` credits `slug` with 1 fuzz VP and BC-2.06.001 is the only slug BC in scope for it; a test-writer working from BC-2.06.001's body will not author the `fuzz_slug` target, and the VP-INDEX→body direction has no mechanical guard.

---

### P7-S7-015 — BC-2.05.002's sole VP (VP-018) never parses a heading; ATX/Setext extraction is unverified [HIGH]

`/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-05/BC-2.05.002.md:74` — `| VP-018 | github-slugger v2 worked examples all pass | unit |`. VP-INDEX.md:179 — `| BC-2.05.002 | ATX/Setext heading extraction | VP-018 | slug worked examples unit test |`. VP-018 is the only VP listed.

VP-018's harness is a `&[(&str, &str)]` table fed directly to `compute_slug` (`vp-018-slug-worked-examples.md:77-152`). It never invokes a Markdown parser, never constructs a `ParsedHeading`, and never distinguishes ATX (`## X`) from Setext (`X\n---`). BC-2.05.002's subject — that both heading syntaxes are recognised and their text extracted — has zero coverage. VP-018's own end-to-end skeleton for the rendering step is commented out and deferred (vp-018:231-247, "It cannot run until `anchor_table::build_for_test()` exists (Phase 3)").

**Consequence:** POLICY 4 semantic mis-anchor on a sole-coverage assignment. Setext heading extraction is a real omission class (a Setext heading missed entirely produces `anchor-not-found` false positives on every link into it), and BC-2.05.002 records it as unit-verified.

---

### P7-S7-016 — BC-2.13.001 and BC-2.12.001 attribute four properties to VP-021/VP-011 that neither VP asserts [HIGH]

| Citation | Claim | What the VP actually asserts |
|---|---|---|
| `BC-2.13.001.md:90` | `VP-021` — "No ANSI codes in JSON output" | vp-021:89-142 checks only that every `reason` string is in a 13-element `HashSet`. No ANSI check. |
| `BC-2.13.001.md:91` | `VP-021` — "Field order consistent" | same; no field-order assertion. |
| `BC-2.12.001.md:72` | `VP-021` — "Clean links produce no output" | same; VP-021 never counts findings or asserts absence. |
| `BC-2.13.001.md:89` | `VP-011` — "JSON output is valid and parseable" | vp-011:67-96 sorts `Vec<Finding>`; vp-011:140-153 byte-compares binary stdout. Neither parses JSON. |

`BC-2.12.001.md:71` additionally records VP-011's proof method as "proptest: run twice, diff stdout" — conflating the proptest harnesses (which never invoke the binary) with the separate integration harness, and contradicting VP-INDEX's `proptest` tool assignment for the described activity.

The BC changelogs show the *method* column was mechanically reconciled to VP-INDEX in the WS-4 burst (BC-2.13.001.md:25, BC-2.12.001.md:23) while the *property* column — the semantic content — was left untouched.

**Consequence:** Four properties are recorded as VP-verified with no verifying assertion anywhere in the corpus. Multiple instances across the same reporter/JSON layer → HIGH with pattern flag. ANSI-escape leakage into piped JSON is the exact defect BC-2.12.002 and BC-2.13.001 jointly exist to prevent, and it is credited to a reason-code set-membership test.

---

### P7-S7-017 — VP-011 is sole coverage for DI-001 but never asserts the 4-field sort key, and its sort-key closure cannot compile [MEDIUM]

DI-001 (`invariants.md:61-71`) requires findings "sorted by `(NFC-normalized file path, line number, column number, link target)`". VP-011 is the sole VP (VP-INDEX.md:88, `All Covered? Yes`).

Neither proptest harness asserts ordering. `vp011_sort_deterministic` (vp-011:68-80) sorts two identical clones and compares them — satisfied by `fn sort_findings(_: &mut Vec<Finding>) {}`. `vp011_sort_order_independent` (vp-011:82-95) is genuinely non-vacuous but is satisfied by *any* deterministic total order, including sorting by `link_target` alone or by insertion hash. No harness checks that consecutive elements are non-decreasing under the DI-001 key. The integration harness (vp-011:120-153) byte-compares stdout across thread counts — also satisfied by a wrong-but-stable order.

Separately, the sort key in the Property Statement will not compile. vp-011:44:

```rust
sort_unstable_by_key(|f| (nfc_normalize(&f.path), f.line, f.col, &f.link_target))
```

`sort_unstable_by_key` requires the closure's return type to be independent of the element's borrow; returning `&f.link_target` produces the well-known E0521/lifetime rejection. `invariants.md:71` says "`sort_unstable_by` is safe given totality" (the `_by` variant, not `_by_key`) and `module-decomposition.md:134` repeats the `_by_key` form. Also `nfc_normalize(&f.path)` passes `&PathBuf` where vp-009:62 passes `&String` — the function has no declared signature (finding 018).

**Consequence:** DI-001's ordering *specification* — as opposed to its determinism — has no verification. A build that emits findings sorted by `(line, path)` instead of `(path, line)` is stable across thread counts, passes both proptests and both integration tests, and violates DI-001 on every run.

---

### P7-S7-018 — VP-009 is vacuous: an identity `nfc_normalize` passes; the function has no declared signature [MEDIUM]

`vp-009-nfc-idempotent.md:59-67` is a single assertion: `nfc_normalize(nfc_normalize(s)) == nfc_normalize(s)`. `fn nfc_normalize(s: &str) -> String { s.to_string() }` — i.e. no normalization at all — satisfies it for every input. So does any idempotent transformation, correct or not. vp-009:74 concedes the property is a library guarantee: "The `unicode-normalization 0.1.24` crate guarantees idempotency; this test verifies our wrapper preserves it" — but an omitted-call wrapper is exactly the failure mode ADR-006 warns about (`ADR-006:139-140`: "there is no cross-platform CI run that would incidentally catch a **missing normalization call**"), and VP-009 cannot see it.

`nfc_normalize` is also undeclared. It appears in `system-overview.md:192`, `ADR-005:44,75,95`, `vp-008:44`, `vp-009:41,62,63`, `vp-011:44` — never as a declaration in `api-surface.md`'s Library API (lines 64-116) or `module-decomposition.md`'s module table.

**Predicate:** `grep -rn "nfc_normalize" .factory/specs` → 9 occurrences across 6 files; `grep -rn "fn nfc_normalize" .factory/specs` → **0** matches.

**Consequence:** DI-002 is reported as covered by two proptest VPs (VP-INDEX.md:89, "proptest x 2, Yes"). One of the two is inert. The real DI-002 coverage is VP-008 property 3 alone (vp-008:95-104). ADR-006:70-71 and `tooling-selection.md:70-71` both list VP-009 as one of four load-bearing justifications for the `unicode-normalization 0.1.24` pin — a justification an identity function satisfies.

---

### P7-S7-019 — VP-018's corpus is 28 rows; the VP says 15, VP-INDEX says 15, and two inputs are duplicated [MEDIUM]

`vp-018-slug-worked-examples.md:254` Feasibility: "Corpus items (15) + DEC-001 triple + FM-002 discriminator". `VP-INDEX.md:99`: "VP-018 (15 worked examples incl. AI & Automation rule-3 and emoji rule-7 falsifying cases)".

**Predicate:** `grep -c "^    \(" .factory/specs/verification-properties/vp-018-slug-worked-examples.md` → **28**. (15 hand-curated rows, vp-018:79-125; 13 generated rows inside the `@GENERATED:BEGIN slug-corpus` block, vp-018:127-139.)

Two inputs are duplicated across the boundary: `("Hello, World!", "hello-world")` at vp-018:82 and again at vp-018:128 (TV-S004); `("AI & Automation", "ai--automation")` at vp-018:111 and again at vp-018:135 (TV-S011). VP-018 v1.1 (vp-018:33, item 3) explicitly "removed duplicate Hello World row"; the generated block re-introduced the duplication.

Note on what is *not* a defect: NFR-006's "all 16 worked examples" (`nfr-catalog.md:121`) is mechanically joined against `test-vectors.md` §7's TV-S entry count by `check-counts.py:402-431`, and §7 contains exactly TV-S001..TV-S016 (`test-vectors.md:270-285`). That count is correct and enforced. The unenforced drift is VP-018's own self-description and VP-INDEX's note cell — `check-counts.py` never reads a VP body.

**Consequence:** POLICY 17. The stated corpus size is used by VP-INDEX:99 as evidence that DI-012 is fully covered; a reader reconciling "15" against `test-vectors.md` §7's 16 or the file's 28 cannot tell which number is authoritative or whether a vector was dropped.

---

### P7-S7-020 — VP-018's TV-S013 row does not test TV-S013, and four generated rows silently bypass the rendering step [MEDIUM]

`test-vectors.md:282` defines TV-S013 as: `## setup` (with inline code `## setup` inside fenced block) → "Only `setup` from the real heading" (EC-065). The assertion is *cardinality*: exactly one anchor, with no phantom from the fenced block.

VP-018's generated row (vp-018:136) is `("setup", "setup"), // TV-S013` — a bare `compute_slug("setup") == "setup"`, which is true of any implementation that lowercases nothing and strips nothing. TV-S013's actual property is unexpressible at the slug-function layer; it requires the parser plus `build_anchor_table`, i.e. the coverage VP-014/BC-2.04.003 is missing (finding 004).

Three further generated rows silently substitute pre-rendered text for the raw heading TV-S specifies, without the NOTE that vp-018:122-124 attaches only to the `("code text", "code-text")` row:

- TV-S010: spec heading `` `--online` flag `` (backticks) → VP-018 row `("--online flag", ...)` (vp-018:134)
- TV-S014: spec heading ``## Use `--online` **now**`` → VP-018 row `("Use --online now", ...)` (vp-018:137)
- TV-S015: spec heading `## Foo <a name="bar"></a>` → VP-018 row `("Foo ", ...)` (vp-018:138)

Each of these three is a **rendering** vector per `market-intelligence.md:181-186` and `test-vectors.md:283-284`; converting them to pre-rendered literals removes the property under test (DI-012 rule 1b) and leaves only rule-1a, which vp-026:173 and vp-018:122-124 already record as deferred to Phase 3.

**Consequence:** NFR-006 requires "All worked examples from DD-015 ... pass as unit tests" at 100% (`nfr-catalog.md:120-121`). Four of the sixteen TV-S vectors are represented by tests that do not test them. The `@GENERATED` provenance makes this look machine-derived and therefore trustworthy.

---

### P7-S7-021 — BC-2.06.001's own golden-vector table appears in zero VP file, including the EC-190 emoji-collision discriminator [MEDIUM]

`/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-06/BC-2.06.001.md:100-105` lists six golden vectors:

```
| "C++ Guide"          | "c-guide"          | DD-015 #2 |
| "日本語 heading"      | "日本語-heading"     | DD-015 #3 |
| "A  B" (2 spaces)    | "a--b"             | DD-015 #4 |
| "" (empty)           | ""                 | DD-015 #5 |
| "🦀Rust"              | "rust"             | EC-059 |
| "🦀Rust" then "🎯Rust" | "rust", "rust-1"   | EC-190 |
```

**Predicate:** `grep -c "🦀|C\+\+ Guide|日本語 heading|A  B" .factory/specs/verification-properties/` → **0 matches across 0 files**.

EC-190 is a distinct discriminator not reachable by any existing VP: two *different* emoji prefixes collapsing to the same base slug, exercising the counter keyed on the post-strip slug rather than the raw heading (`invariants.md:355-356` — "The counter key is the *computed slug* after DD-015 steps 1–4, not the raw heading text"). VP-026's `oracle_runs_required` (vp-026:512) lists R-001..OR-010; none is an emoji-collision run. VP-003's collision-bump fixture uses `"Init"/"Init"/"Init 1"` (vp-003:162-173), which exercises the `while`-bump but not the strip-then-key path. The empty-string vector (`""` → `""`) is likewise absent from VP-018's 28 rows.

**Consequence:** DI-013's counter-key rule ("keyed on the computed slug, not raw text") has no falsifying vector anywhere in the verification layer, even though BC-2.06.001 records one as a golden vector. An implementation keying the counter on raw heading text passes VP-003 (both slugs distinct: `rust`, `rust`… no — it would emit `rust` twice and fail injectivity) or, more subtly, keying on raw text with a separate collision check passes VP-026's R-001 while mishandling EC-190.

---

### P7-S7-022 — VP-026's Rule-2 and Rule-6 proptest strategies are over-broad and will fail a correct implementation [MEDIUM]

Two arms generate inputs outside the domain of the property they assert.

**Rule 2** (`vp-026-slug-differential-fidelity.md:355-364`): `heading in "[\\p{Lu}]{1,20}"`, asserting `slug.chars().all(|c| !c.is_uppercase())`. `\p{Lu}` includes uppercase letters with no Unicode lowercase mapping — e.g. U+2102 DOUBLE-STRUCK CAPITAL C (ℂ), U+2115 (ℕ), U+210B (ℋ). These are `\p{L}`, therefore `\p{Word}`, therefore retained by DI-012 rule 6; `to_lowercase()` leaves them unchanged; `char::is_uppercase()` returns true for them. A byte-perfect github-slugger reimplementation fails this assertion.

**Rule 6** (vp-026:431-450): `s in "[\\p{Han}\\p{Cyrillic}]{1,10}"`, asserting `slug.contains(&lowercased)` where `lowercased` is the full lowercased input. The `Cyrillic` *script* property includes non-letter codepoints — U+0482 CYRILLIC THOUSANDS SIGN (`So`), U+0488/U+0489 COMBINING CYRILLIC HUNDRED THOUSANDS / MILLIONS SIGN (`Me`). Per DI-012 rule 7 (`invariants.md:311`, "not `\p{Word}`, not `-`, not space; removed in step 3") a symbol like U+0482 is stripped, so the lowercased input is not a substring of the slug and the assertion fails on a correct implementation.

The "oracle-wins precedence clause" (vp-026:129-135) does not rescue these: it governs conflicts between DI-012 prose and the *committed oracle corpus*, not between a proptest generator's domain and the asserted structural property. vp-026:135 even anticipates the class ("prevents VP-026 from becoming unsatisfiable if DI-012's prose is imprecise for any of the ~1,800 codepoints in emoji range") without narrowing the two strategies above.

**Consequence:** False-red. A correct implementation fails VP-026 on a shrunk counterexample that looks like a slug bug. The likely Phase-3 response is to loosen the assertion or narrow the strategy under time pressure, which is how Rule 2 and Rule 6 coverage gets silently deleted from the only comprehensive DI-012 vehicle.

---

### P7-S7-023 — api-surface.md's JSON schema omits the `errors[]` array that VP-021's harness iterates [MEDIUM]

`api-surface.md:129-142` presents the CAP-013 JSON output schema as `{ "schema_version": 1, "results": [ ... ] }` — a two-key envelope with no `errors` array.

Every other authority includes it: `vp-021-no-undefined-reason-codes.md:55-59` ("The JSON envelope is `{schema_version, results[], errors[]}`") and its harness iterates `json["errors"]` (vp-021:122-132); `BC-2.13.001.md:34, 47, 64, 82-84`; `prd.md:273, 654, 688` (D-017: "JSON output is an object envelope `{schema_version, results[], errors[]}` per D-017, superseding the R6 'array' wording"); `interface-definitions.md:164`; `L2-INDEX.md:139` (DD-023); `BC-INDEX.md:176`.

**Predicate:** `grep -rn "errors\[|errors\"|\"errors" .factory/specs` → 22 occurrences across 9 files. `api-surface.md` is not among them.

**Consequence:** VP-021's `errors[]` iteration is the half of the harness that catches `target-unreadable` (vp-021:57-59: "checking only `results` silently ignores `target-unreadable` occurrences"). An implementer building the reporter from `api-surface.md` — the document `api-surface.md:66` designates for exactly that purpose ("These are the surfaces that test-writer and implementer drive directly") — omits the `errors` array, `json["errors"].as_array()` returns `None`, `unwrap_or(&vec![])` swallows it, and the `target-unreadable` branch of VP-021 becomes a silent no-op that still increments no counter and still passes `total_checked > 0` from the `results` side alone.

---

### P7-S7-024 — Fuzz target filenames are reversed between tooling-selection.md and VP-012/VP-013 [MEDIUM]

`tooling-selection.md:106-107`:
```
    slug_fuzz.rs         (VP-012: ...)
    fragment_fuzz.rs     (VP-013: ...)
```
`vp-012-slug-fuzz.md:54`: `// fuzz/fuzz_targets/fuzz_slug.rs`
`vp-013-fragment-fuzz.md:54`: `// fuzz/fuzz_targets/fuzz_fragment.rs`

**Predicate:** `grep -rn "fuzz_slug|slug_fuzz|fuzz_fragment|fragment_fuzz" .factory/specs` → exactly 4 occurrences: tooling-selection.md:106, :107 (noun-first) and vp-012:54, vp-013:54 (verb-first).

This is a residue of the P4-014 flat-layout sweep, which corrected nine `tests/` paths across VP-011/014/015/016/017/018/020/025/026 (see the P4-014 entries in each of those changelogs) and did not touch the two fuzz targets. Blast radius 2 → MEDIUM per partial-fix regression discipline.

**Consequence:** `cargo fuzz` generates a `[[bin]]` per file in `fuzz/fuzz_targets/`; the target name is the filename. A CI job invoking `cargo fuzz run slug_fuzz` against a file named `fuzz_slug.rs` fails to find the target. Because VP-012/VP-013 are Phase-6 P1 fuzz targets with a 30-min/15-min CI budget (vp-012:76, vp-013:83), a name mismatch reads as an infrastructure error rather than a missing property.

---

### P7-S7-025 — VP-021 and VP-022 are absent from the Test Target Layout; VP-021 states no harness path at all [MEDIUM]

`tooling-selection.md:129-147` is the P4-014 canonical layout and lists exactly nine harness files (VP-011, 014, 015, 016, 017, 018, 020, 025, 026) plus the VP-026 fixture. VP-021 and VP-022 are both `integration` VPs with committed harness code and neither appears.

VP-021 is worse than omitted: its harness fence (`vp-021-no-undefined-reason-codes.md:83-143`) opens with `// Integration test: parse all acceptance corpus JSON outputs` and gives **no path**. Every other VP with a harness received an explicit `// tests/<name>.rs` header during the P4-014 sweep. VP-022 names `benches/regression_gate.rs` (vp-022:103), which is a `benches/` target and correctly outside the `tests/` convention — but it is also absent from the layout section and from any `[[bench]]` declaration.

`tooling-selection.md:149-153` explains precisely why this matters: "A file at `tests/proptest/slug_differential.rs` is NOT discovered unless a sibling `tests/proptest/main.rs` declares `mod slug_differential;`... The flat convention avoids both requirements."

**Consequence:** VP-021 is the sole verification of NFR-007 (`verification-coverage-matrix.md:73`). A harness with no declared path is the exact scenario the POL-11 assertion at tooling-selection.md:155-160 exists to catch — and that assertion is itself non-functional (finding 026), so a VP-021 harness placed at a non-discoverable path compiles to nothing and reports green.

---

### P7-S7-026 — The POL-11 nextest positive-coverage assertion cannot function as written [MEDIUM]

`/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/tooling-selection.md:155-160`:

```
**CI positive-coverage assertion (POL-11):** After `cargo nextest run`, assert:
cargo nextest list | grep -c '^tests::' | xargs -I{} test {} -ge <expected_harness_count>
```

Three defects:

1. **`<expected_harness_count>` is an unresolved placeholder.** No number is committed anywhere. The assertion has no threshold.
2. **The `^tests::` anchor does not match `cargo nextest list` output.** `nextest list`'s default human format emits a binary-header line (`mdlinkcheck-core::integration_determinism:`) followed by *indented* test names — no line begins with `tests::`. `grep -c` returns `0` and exits 1.
3. **Exit-status confusion.** With `grep -c` returning 0 and exiting 1, under GH Actions' default `bash -e` (no `pipefail`) the pipeline status is `xargs`'s; `xargs` receives `0` on stdin and runs `test 0 -ge <placeholder>`, which fails. Either path makes the step unconditionally red — which in practice means it will be deleted or `|| true`'d rather than fixed.

The stated intent is explicit and correct (tooling-selection.md:159-160): "This prevents a situation where a test target at the wrong path silently compiles to nothing and reports `0 passed` as green." The assertion is the only guard over all nine flat-layout harness files, and it is inert.

**Consequence:** POLICY 11. The single mechanism protecting the entire Phase-3 verification suite against the "0 passed = green" failure mode is a shell one-liner with an unresolved placeholder and a regex that matches nothing. This is the same META-GAP shape as prism PR #127's `perimeter-compile-fail` job.

**Tag:** [process-gap]

---

### P7-S7-027 — VP-025's property numbering contradicts its own harness labels and its own property count [MEDIUM]

`vp-025-anchor-resolver-totality.md:45-75` numbers six properties: 1 totality, 2 hit correctness, 3 miss correctness, **4 Indeterminate never returned**, 5 case sensitivity, 6 empty fragment.

The harness relabels them: `P1` totality "(Also enforces P4: Indeterminate...)" (vp-025:157), `P2` hit, `P3` miss, **`P4` case sensitivity** (vp-025:229), `P5` empty fragment (vp-025:257). So "P4" denotes property 4 in the statement and property 5 in the harness, and the harness's own P1 comment cross-references "P4" meaning the statement's numbering — inside a block where P4 means something else.

Counts disagree too: vp-025:100 Proof Method — "10 000 samples × **5** properties"; vp-025:318 Feasibility — "10,000 samples × **5** properties"; the Non-Vacuousness table (vp-025:295) — "**Five** wrong implementations". Six properties are stated and five harnesses exist.

**Consequence:** A test-writer implementing "VP-025 P4" writes one of two different tests depending on which section they read. Per the mis-anchoring severity table this is a contradiction internal to a single document.

---

### P7-S7-028 — VP-015/016/017 use `Finding` members that do not exist, and VP-016's field is one VP-019 explicitly says is not a field [MEDIUM]

`api-surface.md:121-123` declares `pub struct Finding { pub path: PathBuf, pub line: u32, pub col: u32, pub link_target: String, pub verdict: Verdict, pub reason: FailureReason }`.

- **`f.is_broken()`** — called at vp-015:90, 101, 124, 135, 164, 173; vp-016:102, 111, 119, 150, 158, 168, 197, 206, 215, 249, 257, 267, 291; vp-017:124, 167. No method is declared on `Finding` anywhere in `api-surface.md` or `module-decomposition.md`.
- **`f.source_file`** — used at vp-016:110, 118, 157, 167, 205, 215, 257, 267. The field is `path`. Worse, `vp-019-one-verdict-per-link.md:48` states the opposite directly: "`source_file` is the implicit caller context, **not a field** on each event" — and vp-019:29 records that v1.1 had "Fixed harness key to include source_file" before v1.2 reversed it. VP-016 v1.3 (2026-08-07) added eight new `source_file` references *after* that reversal.
- `f.source_file.contains(".hidden")` (vp-016:215) additionally calls `contains` on what would be a `PathBuf`, which has no such method.

**Predicate:** `grep -c "source_file" .factory/specs/verification-properties/vp-016-ignored-files-anchor-targets.md` → part of the 17 combined hits recorded for vp-016 in the undefined-symbol sweep; `grep -rn "fn is_broken|is_broken" api-surface.md module-decomposition.md` → 0.

**Consequence:** VP-016's "source-not-scanned" assertions — the entire v1.3 anti-vacuity addition proving that excluded files are excluded *as sources* — are written against a nonexistent field. They will be rewritten by hand in Phase 3 with no spec constraint on what replaces them.

---

### P7-S7-029 — VP-023 P6 generates `ftp:x` where the property says `ftp://`; VP-010 never generates the exact-match case BC-2.11.002 attributes to it [MEDIUM]

**VP-023.** `vp-023-url-classifier-totality.md:59-62` states property 5 as "Any string beginning with `mailto:`, `ftp://`, `ssh://`, or other non-http/https schemes must return `UrlKind::NonHttp`". The P6 harness (vp-023:194-198) builds `format!("{}:{}", scheme, local)` with `scheme in "(mailto|ftp|ssh|git|file)"` — producing `ftp:abc`, `ssh:abc`, `file:abc`, `git:abc`. The authority-form (`ftp://host/path`) that the property statement names, and that appears in real Markdown, is never generated. `file:` and `git:` are also not in the stated property's enumeration.

**VP-010.** `BC-2.11.002.md:100` records `| VP-010 | Exact match (no trailing /) is exempt | proptest |`. VP-010's single harness (vp-010:56-75) generates `path in "/[a-z/]{0,20}"` — a regex whose every match begins with `/`. `allowed_url` is therefore always `https://{host}/…`, never the bare `https://{host}` exact-prefix case. The property BC-2.11.002 attributes to VP-010 is not reachable by VP-010's generator.

**Consequence:** VP-023 is the sole VP for BC-2.07.007 and the sole non-acceptance coverage for `url_classifier` (`verification-coverage-matrix.md:96, 105`); the `scheme://authority` form of non-http classification is untested. VP-010 is the sole VP for BC-2.11.002 and BC-2.09.002 (VP-INDEX.md:216, 238); a `should_allow` implementation that rejects an exact prefix match (`--allow https://a.com` not matching `https://a.com`) passes VP-010 and breaks the flag's documented behaviour.

---

### P7-S7-030 — VP H1s and property statements name module-decomposition function names while their harnesses use api-surface names [MEDIUM]

Four VPs are internally split between two incompatible naming systems:

| VP | H1 / property statement | harness | api-surface declares |
|---|---|---|---|
| VP-004 | `fragment::split` (vp-004:37, :42) | `split_fragment(s)` (vp-004:71) | `split_fragment` (api-surface.md:77) |
| VP-013 | `fragment::split` (vp-013:34) | `split_fragment(s)` (vp-013:62) | `split_fragment` |
| VP-014 | `link_extractor::extract(events)` (vp-014:46, :59) | `extract_links(&events)` (vp-014:83) | `extract_links` (api-surface.md:85) |
| VP-020 | `anchor_table::build` (vp-020:44) | `build_anchor_table_from_md(md)` (vp-020:76) | `build_anchor_table` (api-surface.md:81) |

The root cause is upstream: `module-decomposition.md:49-59` names these `slug::compute`, `fragment::split`, `anchor_table::build`, `link_extractor::extract`, `path_resolver::resolve`, `anchor_resolver::resolve`, `url_classifier::classify`, `filter::ignore_match`/`allow_match`, while `api-surface.md:71-115` names them `compute_slug`, `split_fragment`, `build_anchor_table`, `extract_links`, `resolve_path`, `resolve_anchor`, `classify_url`, `should_ignore`/`should_allow`. Both are L3 architecture sections; neither is marked subordinate. VP bodies inherited both.

`module-decomposition.md:56` also declares `classify_response(status: u16, attempt: Attempt)` where api-surface.md:103 declares `HttpAttempt` — the type VP-007 imports.

**Consequence:** Every VP harness is a symbol-resolution coin-flip for the implementer. The two documents were never reconciled, so "resolvable from api-surface.md / module-decomposition.md" is satisfiable by both spellings and by neither consistently — which is how `HttpAttempt::Get` (finding 003) and `AnchorTable(entries)` (finding 011) survived multiple remediation passes.

---

### P7-S7-031 — VP-007's coverage cell claims exhaustive `u16` while its property statement bounds status to 0..=999 [LOW]

`vp-007-http-verdict-total.md:45` — "For all valid HTTP status codes `status` in the range **0..=999**". `vp-007:72` Coverage cell — "All **65536** × 2 input combinations". `vp-007:178` — "65536 × 2 = 131072 combinations". The harness (vp-007:79-81) applies no range assumption at all ("No range assumption — must be total for ALL u16 values"), so the harness matches the coverage cell and contradicts the property statement.

**Consequence:** Minor, but it determines whether `classify_response(65535, Head)` is in-contract. If the property statement is authoritative, the harness needs `kani::assume(status <= 999)` and the 65536 claim is wrong; if the harness is authoritative, the statement's bound is wrong. A formal-verifier locking the proof will pick one arbitrarily.

---

### P7-S7-032 — VP-018 presents a paraphrase of market-intelligence §4.1 rule 4 inside quotation marks [LOW]

`vp-018-slug-worked-examples.md:95-96`:

```
// market-intelligence §4.1 rule 4: "Replace each space with a hyphen —
//   1:1 per-character, no run collapsing, leading/trailing hyphens never trimmed"
```

Actual source, `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/planning/market-intelligence.md:198-200`:

> "4. **Replace each space with a hyphen.** Note: this is a **1:1 per-character** replacement (`/ /g`), **not** run collapsing. Two consecutive spaces → two hyphens. Runs of hyphens are **never** collapsed and leading/trailing hyphens are **never** trimmed."

**Predicate:** `grep -rn "Replace each space with a hyphen" .factory` → 3 occurrences: market-intelligence.md:198, gene-transfusion-assessment.md:118, vp-018:95.

The paraphrase is **semantically faithful** — no drift in meaning — but it is not verbatim, and POLICY 5 quoted excerpts are not mechanically checked (`lint_hook: null`). Reported at LOW because the substance is correct; the defect is the quotation marks, not the content.

---

### P7-S7-033 — VP-013's structural assertion contains a dead escape clause and its stated reconstruction invariant is never asserted [LOW]

`vp-013-fragment-fuzz.md:69-70`:
```rust
assert!(!s.contains('#') || s.is_empty(),
    "no fragment but # present");
```
`s.is_empty()` can never rescue this branch: an empty string cannot contain `'#'`, so the disjunct is unreachable and the assertion is equivalent to `assert!(!s.contains('#'))`. Harmless, but it signals the author was uncertain about the contract — and VP-004's P1 (vp-004:73-79) is the authoritative statement that a literal `#` *must* yield `Some`.

vp-013:63 comments "Invariant: path + optional fragment reconstruct the input" and then discards both values: `let _ = (path, frag);` (vp-013:66). No reconstruction is checked. VP-004's P4 (vp-004:91-96) does assert strict reconstruction, so the fuzz extension to unbounded lengths — VP-013's stated reason to exist (vp-013:43, "fuzz extends VP-004's bounded Kani proof to unbounded inputs") — loses the reconstruction property at exactly the input sizes VP-004 cannot reach.

---

### P7-S7-034 — VP-001's stated rationale for excluding the counter cites a container type that api-surface replaced [LOW]

`vp-001-slug-total.md:106`: "`DuplicateCounter` uses `HashMap<String, u32>` internally; Kani models `RandomState`/SipHash poorly. VP-001 proves `slugify` only. VP-003 proves the counter using `BTreeMap<String, u32>` which Kani handles correctly."

There is one `DuplicateCounter` type, and `api-surface.md:73` declares it `pub struct DuplicateCounter(BTreeMap<String, u32>);  // BTreeMap required for Kani feasibility (VP-003)` — a change recorded in api-surface v1.2 (api-surface.md:25, "F-018 remediation: DuplicateCounter now BTreeMap<String,u32>"). VP-001 v1.1 is the same F-018 remediation (vp-001:27) and updated the harness but left the rationale describing two different backing stores for one type.

**Consequence:** The stated justification for splitting VP-001 from VP-003 ("Kani models RandomState/SipHash poorly") no longer applies, since no `HashMap` is in scope. The split is still defensible on bound-size grounds, but the recorded reason is false — and a future pass may re-merge them on the strength of the correction.

---

### P7-S7-035 — verification-architecture.md's VP-005 and VP-003 catalog rows omit content their own file carries [LOW]

- `verification-architecture.md:63`: "`verdict::exit_code` returns 2 when any `IoError` present — regardless of findings". VP-005 v1.1 added `config_error` as a co-equal trigger (vp-005:26, :41-45) and the arch doc's own harness example at line 127-128 includes it (`if has_io_error || config_error`). The catalog row omits the usage-error half of exit 2 (R7).
- `verification-architecture.md:61`: VP-003's Invariant column is `BC-2.06.002` only, while VP-INDEX.md:59 and verification-coverage-matrix.md:55 both carry `DI-013`, and verification-architecture.md's own DI→VP matrix at line 150 lists DI-013 → VP-003.

---

### P7-S7-036 — proptest version pin cited as exact `1.6.0` in seven VPs and `1.6.x` in three places [LOW]

`tooling-selection.md:52` pins `proptest` at `**1.6.x**`. VP-008:57, VP-009:54, VP-010:49, VP-011:62, VP-019:63, VP-023:79, VP-024:66 all cite "proptest 1.6.0" (exact). VP-025:100 and VP-026:226 cite "1.6.x". VP-008:130 additionally cites "`unicode-normalization 0.1.24` test helpers" as a proptest dependency, while tooling-selection.md:61 lists it as a *runtime* dependency only.

**Consequence:** Cosmetic unless a 1.6.1 patch changes shrinking behaviour, at which point seven VPs claim a pin the workspace does not have.

---

### P7-S7-037 — VP-026's Feasibility fixture-size estimate predates the R-009/OR-010 additions [LOW]

`vp-026-slug-differential-fidelity.md:519`: "Committed fixture size | Small (~5-10 KB) | **8 runs** × ~5 entries average". The same file's positive-coverage assertion requires ten runs — `["R-001","R-002","R-003","R-004","R-005","R-006","R-007","R-008","R-009","OR-010"]` (vp-026:299-300) — and the Phase 3 obligation table says "Runs R-001 through OR-010" (vp-026:506). R-009 and OR-010 were added in v1.1 (vp-026:27, item P4-013); the Feasibility row was not updated.

---

### P7-S7-038 — VP-014 and VP-020 nest unescaped triple-backtick fences inside `rust` fences, breaking rendering [LOW]

`vp-014-code-context-exclusion.md`: the harness fence opens at line 69 (` ```rust `) and line 76 emits ` ```markdown ` inside a Rust raw string. In Markdown, a three-backtick line closes the enclosing three-backtick fence, so everything from line 76 onward renders as prose and the closing fence at line 114 opens a new block.

`vp-020-html-anchor-narrow-scope.md:105` and `:107` have the identical defect (` ```html ` inside the ` ```rust ` fence opened at line 64).

Both are the *only* fixtures in their respective VPs that exercise fenced-code exclusion, so the reader most likely to need them is the one who cannot read them.

---

## Novelty Assessment

Fresh derivation, no prior-pass artifacts consulted. Findings cluster into four mechanisms, three of which are structural rather than editorial:

1. **The VP↔BC join is one-directional and semantically unchecked.** The WS-4 burst reconciled BC VP-table *Proof Method* cells to VP-INDEX (visible in ~20 BC changelogs) and `check-placeholders.py` enforces the `test-sufficient` sentinel via a genuine runtime join. Neither touches the *Property* cell. Findings 001, 010, 015, 016 are all the same mechanism: a BC asserts a property, names a VP, gets the tool column right, and the VP proves something else. Four instances across four subsystems → this is a process gap, not four content defects.

2. **`verification-architecture.md` is outside every checker.** `check-counts.py` (read in full) validates VP-INDEX frontmatter, both arithmetic invariants, and `verification-coverage-matrix.md`'s Totals row — and never opens `verification-architecture.md`. That document is where VP-025's retired `Hit`/`Miss` vocabulary and VP-019's unqualified DI-005 claim survive (008, 009). POLICY 9 names it as propagation target #1.

3. **A whole remediation burst didn't propagate.** The five 2026-08-07 BI-025 vacuity repairs materially strengthened VP-015/016/017/019/023 and are recorded in zero index (007). Predicate: `grep -rl BI-025` → 5 files, all VP bodies.

4. **Eleven undeclared symbols.** `PathVerdict`, `FailureReason`, `ReasonCode`, `IoError`, `HttpError`, `VerdictKind`, `AllowPrefix`, `nfc_normalize`, `sort_findings`, `run_offline`, `with_count`, plus `Finding::is_broken`/`source_file` and a private-field `AnchorTable` construction. The `api-surface.md` ↔ `module-decomposition.md` naming schism (030) is why: two L3 documents, neither subordinate, so "resolvable from either" resolves nothing.

Two findings that a count-based pass would flag are **not** defects and I verified them mechanically before discarding: NFR-006's "16 worked examples" is correct and enforced by `check-counts.py:402-431` against `test-vectors.md` §7's TV-S001..TV-S016; the `test-sufficient` sentinel is a real VP-INDEX join, not an allowlist (`check-placeholders.py:99-147, 177-202`). VP-021's 13-code taxonomy matches `error-taxonomy.md` §3 exactly. All 26 proof-method/tool joins agree.

Novelty: **HIGH.** The four CRITICAL findings are false-green paths — three of the four (001, 002, 004) let a Phase-6 gate report a DI or DI-012 rule as discharged with zero verifying assertion, and one (003) is a P0 Kani proof against a type system that does not exist. This shard has not converged. Clean-pass streak remains ZERO.