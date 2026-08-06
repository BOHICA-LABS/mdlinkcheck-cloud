---
document_type: adversarial-review
level: ops
version: "1.0"
status: final
producer: adversary
phase: phase-1d
pass: 2
timestamp: "2026-08-05T00:00:00Z"
inputs:
  - .factory/specs/verification-properties/  (all 24 VP files, full read)
  - .factory/specs/architecture/verification-architecture.md
  - .factory/specs/architecture/verification-coverage-matrix.md
  - .factory/specs/verification-properties/VP-INDEX.md
  - .factory/specs/domain-spec/capabilities.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/domain-spec/edge-cases.md
  - .factory/specs/prd-supplements/error-taxonomy.md
  - .factory/specs/prd-supplements/interface-definitions.md
  - .factory/specs/architecture/system-overview.md
  - .factory/specs/architecture/decisions/ADR-006-strict-path-model.md  (partial)
  - .factory/BRIEF.md
  - .factory/specs/prd.md  (§5/§5b/§6 + changelog)
  - .factory/specs/behavioral-contracts/ss-05/BC-2.05.001.md
  - .factory/specs/behavioral-contracts/ss-07/BC-2.07.005.md
  - .factory/specs/behavioral-contracts/ss-07/BC-2.07.008.md
  - .factory/specs/behavioral-contracts/ss-10/BC-2.10.002.md
  - .factory/specs/behavioral-contracts/ss-11/BC-2.11.002.md
  - "(targeted greps across all 130 spec files)"
input-hash: "bef00f2"
traces_to: .factory/cycles/phase-1d/adversary-pass-1.md
previous_review: .factory/cycles/phase-1d/adversary-pass-1.md
---

## Provenance

The adversary agent authored these findings using a fresh-context, read-only tool
profile (`Read`, `Grep`, `Glob` only; `Write`, `Edit`, and `Bash` denied). It
reviewed the spec package without access to any prior review pass, session history,
or implementation artifacts. The spec-steward agent persisted this output verbatim
without editorial change — no findings were reworded, reordered, softened, or
summarised. This document is an evidence artifact for the Phase 1d convergence loop.
Pass 2 focused on the verification-property layer (all 24 VP files) and the
behavioral contracts most relevant to verdict classification and Pass 1.5.
`input-hash` is the factory-artifacts branch HEAD at time of persistence (bef00f2).

---

# Adversarial Spec Review — Phase 1d, Pass 2

## Finding ID Convention

This pass uses the adversary's native prefix scheme: `P2-C##` (Critical), `P2-M##` (Major), `P2-m##` (minor). These IDs are preserved verbatim; they do not follow the `ADV-P2-NNN` template convention. All downstream routing and fix-tracking uses the `P2-*` IDs as-is.

## Part A — Fix Verification (pass >= 2 only)

The adversary operated with full information asymmetry and did not have access to pass-1 findings during review. No explicit fix-verification table was produced. Pass-1 findings (F-001 through F-029) that overlap with pass-2 findings are flagged in the routing table produced by the spec-steward. Formal fix-verification should be performed as a discrete step before pass-3 is initiated.

## Part B — New Findings (or all findings for pass 1)

Perimeter coverage: all 24 VP files (full read), verification-architecture.md, verification-coverage-matrix.md, VP-INDEX, capabilities.md, invariants.md, edge-cases.md, error-taxonomy.md, interface-definitions.md, system-overview.md, ADR-006 (partial), BRIEF.md, prd.md (§5/§5b/§6 + changelog), BC-2.05.001, BC-2.07.005, BC-2.07.008, BC-2.10.002, BC-2.11.002, plus targeted greps across all 130 spec files. Not reached: listed at the end.

---

## CRITICAL

### P2-C01 — The verdict domain is stated as three values in one place and four in another; DI-005 (the totality invariant) omits `alive`
**Files:** `.factory/specs/domain-spec/invariants.md:85-91` (DI-005) · `.factory/specs/prd-supplements/error-taxonomy.md:30-38` · `.factory/specs/architecture/system-overview.md:202` · `.factory/specs/domain-spec/capabilities.md:151,201` · `.factory/specs/architecture/verification-architecture.md:43` · `.factory/specs/prd-supplements/interface-definitions.md:85`

error-taxonomy.md §1 is the only document that gets this right, and it defines **four** verdict classes, explicitly non-interchangeable: line 38 — *"The positive external URL verdict is `alive` (never `valid`). The positive internal link verdict is `clean`. **`clean` is NOT used for external URL verdicts.**"*

Every other artifact enumerates three:
- DI-005: *"exactly one verdict (`clean`, `broken`, or `indeterminate`)"* — no `alive`.
- system-overview.md:202: *"Every verdict is one of `broken`, `indeterminate`, `clean`"* — no `alive`.
- interface-definitions.md:85 (exit-code-0 trigger): *"All extracted links have `clean` or `indeterminate` verdict"* — no `alive`.
- verification-architecture.md:43 (VP-006 row): *"`clean` or `indeterminate`"* — while the VP-006 file itself says *"alive or indeterminate"*.
- BC-2.10.002:36 writes *"alive (clean)"*, equating the two, which error-taxonomy.md:38 forbids.

**Failure scenario:** `mdlinkcheck --online docs/` where every external URL returns 200. Each such link's verdict is `alive`. Under DI-005 as written, `alive` is not a member of the verdict set, so DI-005 is violated by a correct run. Under interface-definitions.md §3, no rule maps `alive` to exit 0. VP-019 is designated as the sole discharge of DI-005 and cannot detect this because it never inspects verdict values. Worse, VP-007's Kani harness matches on `VerdictKind::{Alive, Broken, Indeterminate}` — a 3-variant enum — while VP-024 matches `PathVerdict::Clean`. The implementer will build two incompatible enums or collapse `alive` into `clean` and silently invalidate error-taxonomy.md §1.

**Fix:** pick one model and propagate. Either (a) DI-005, system-overview.md:202, interface-definitions.md:85, and verification-architecture.md:43 all enumerate `{alive, clean, broken, indeterminate}`; or (b) error-taxonomy.md §1 collapses `alive`/`clean` into one name and D-008's wording is recorded as a naming-only decision. Do not leave both.
**Owner:** business-analyst (DI-005) + product-owner (error-taxonomy/interface-definitions) + architect (verification-architecture)

---

### P2-C02 — VP-021, the sole enforcement of NFR-007's closed-taxonomy guarantee, has the wrong closed set and reads the wrong JSON node
**Files:** `.factory/specs/verification-properties/vp-021-no-undefined-reason-codes.md:44-49, 77-82, 87-88` vs `.factory/specs/prd-supplements/error-taxonomy.md:83-86` and `.factory/specs/prd-supplements/interface-definitions.md:164-174, 199-205`

Two independent defects in the same harness:

1. **The whitelist is 12 codes; the taxonomy is 13.** VP-021 enumerates `file-not-found, target-is-directory, broken-symlink, target-unreadable, anchor-not-found, malformed-url, too-many-redirects, http-error, http-indeterminate, dns-failure, tls-error, undefined-reference-definition`. error-taxonomy.md:83-86 and prd.md:310-324 both list 13. **`http-timeout` is missing from VP-021.** VP-007's own changelog even records *"corrected '9-reason-code' to '13-reason-code'"* — the fix reached VP-007 and never reached VP-021.

2. **The harness only iterates `json["results"]`** (line 88). But error-taxonomy.md §6.1 (line 138) states `target-unreadable` routes to *"the `errors` array in JSON output (not `results`)"*, and interface-definitions.md §6.2b confirms `errors[].reason` is *"Always `target-unreadable`"*. So `target-unreadable` — a member of the closed set — is structurally unreachable by VP-021, while `http-timeout` is in the JSON but not in the whitelist.

**Failure scenario:** a corpus fixture exercises BC-2.10.003 (10s timeout → `http-timeout`). VP-021 asserts `known_codes.contains("http-timeout")` → false → the test fails on correct behavior. A test-writer "fixes" it by adding the code to the whitelist without checking the taxonomy, and NFR-007's closed-set guarantee degrades into "whatever the code happens to emit" — the exact false-green class POL-11 exists to catch. Meanwhile a genuinely undefined code emitted into `errors` is never checked at all.

**Fix:** derive the whitelist from a single source (ideally assert `ReasonCode::VARIANTS` equals a parsed list from error-taxonomy.md §3 rather than a hand-copied array), iterate both `results[].reason` and `errors[].reason`, and add a positive-coverage assertion (`"Checked N reason-code occurrences across M fixtures"` with runtime-computed N, M — currently the test passes vacuously if `corpus_fixtures()` is empty or every fixture yields zero findings).
**Owner:** architect
**Tag:** `[process-gap]` — no artifact cross-checks a VP's hardcoded enumeration against the taxonomy it claims to enforce.

---

### P2-C03 — HTTP 400 after GET fallback is `broken` in error-taxonomy.md and `indeterminate` in BC-2.10.002
**Files:** `.factory/specs/prd-supplements/error-taxonomy.md:64` vs `.factory/specs/behavioral-contracts/ss-10/BC-2.10.002.md:60-62, 93-96`

- error-taxonomy.md:64, `http-error` trigger: *"External URL returned a definitive HTTP error: 404, 410, **or 400 after GET fallback**"* → verdict `broken`, exit 1.
- BC-2.10.002 PC3: *"**400 (after HEAD→GET fallback)** ... `indeterminate` (`http-indeterminate`). The server rejects the method, not the resource."* → exit 0.
- BC-2.10.002 Invariant 2 compounds it: *"Among HTTP status codes: **only 404 and 410** ... are definitively `broken`"* — which contradicts error-taxonomy.md:64 within the same package.

**Failure scenario:** a doc links to a host whose HEAD returns 405 and whose GET returns 400. Following error-taxonomy.md the implementer emits `broken`/`http-error` → CI exits 1. Following BC-2.10.002 the implementer emits `indeterminate` → CI exits 0. Both artifacts are `primary_consumers: [implementer, test-writer]`-class. The acceptance corpus vector for this case cannot be authored, and VP-007's Kani correctness harness cannot be written (it asserts `!matches!(Broken)` only for 429/5xx — 400 is silently outside its assertions, so neither reading is caught).
**Owner:** product-owner

---

### P2-C04 — interface-definitions.md states TLS failures produce `indeterminate`; five other artifacts state `broken`
**File:** `.factory/specs/prd-supplements/interface-definitions.md:64`

> *"TLS certificate verification is always enforced; TLS failures produce **`indeterminate`** verdict (BC-2.10.002)."*

Contradicted by: error-taxonomy.md:66 and :92 (`tls-error` → broken, exit 1); BC-2.10.002 PC14 (*"`broken` (`tls-error`) → exit 1. TLS failures are definitively broken"*); BC-2.10.006 v1.3; capabilities.md CAP-010:151 (*"TLS handshake failure (`tls-error`) are classified as **`broken`** and cause exit 1"*); VP-007:50 (*"`dns-failure` and `tls-error` **ALWAYS** produce `broken`"*).

This is a partial-fix residue: the D-011 sweep edited this line to delete `--insecure` and left the pre-ADR-007-v1.1 verdict in place. interface-definitions.md is the implementer/test-writer-facing contract, so it wins in practice.

**Failure scenario:** implementer follows interface-definitions.md §2.3 → expired-certificate URL yields `indeterminate` → exit 0 on a genuinely dead HTTPS link (the tool's headline job). Then VP-007's third Kani harness (`verify_vp007_correctness_dns_tls_broken`) fails at Phase 6 with no obvious spec authority to appeal to.
**Owner:** product-owner (spec-steward for the D-011 sweep audit)

---

### P2-C05 — Pass 1.5 has no specified behavior when a target does not exist; BC-2.05.001 PC2 is unsatisfiable and the natural reading makes every broken `.md` link exit 2
**Files:** `.factory/specs/behavioral-contracts/ss-05/BC-2.05.001.md:58-62` · `.factory/specs/architecture/system-overview.md:105-110, 203-217` · `.factory/specs/domain-spec/invariants.md:129-132`

BC-2.05.001 PC2: *"**every** `.md` destination that appeared in the LinkMap but was ABSENT from AnchorIndex after Pass 1 ... **now has a complete anchor table in AnchorIndex**."*

This postcondition is unsatisfiable for the product's primary use case. `[x](missing.md#section)` where `missing.md` does not exist: `missing.md` is absent from AnchorIndex, so Pass 1.5 must give it an anchor table — impossible. system-overview.md:105-109 specifies the mechanics (`fs::read_dir` the parent, then *"Parse each missing .md file for its anchor table"*) with no failure branch. Nothing anywhere states what happens when the read fails.

The only governing rule available to an implementer is system-overview.md:203-204 and :217: *"Runtime I/O error (unreadable file, non-UTF-8) | During scan | Collect into `Vec<IoError>`; scan continues"*. Feed that into `exit_code(&findings, &io_errors)` — DI-011, VP-005, interface-definitions.md §3 — and **`io_errors` non-empty ⇒ exit 2**.

**Failure scenario:** the acceptance corpus contains `fixtures/broken-links/file-not-found.md` with `[x](missing.md)` (interface-definitions.md §10.2's own worked example). Pass 1.5 attempts `fs::read_dir` / read on a nonexistent path, records an IoError, exit code becomes **2** instead of 1. Additionally interface-definitions.md §10.2 line 304 requires *"`errors` MUST be empty in a passing corpus run"* — so the acceptance corpus is unpassable. Every planted broken `.md` link in the corpus inverts R7.

Two sub-gaps in the same area:
- `fs::read_dir` on a nonexistent *parent* directory (`[x](nowhere/a.md#x)`) has the same problem.
- system-overview.md:114 keys the visited-set by *"absolute **canonical** path"*; `fs::canonicalize` **errors** on a path whose parent does not exist, so the dedup key cannot be computed for exactly the failing cases.

**Fix:** add a BC-2.05.001 postcondition: *"If a Pass 1.5 target path does not exist, is not a regular file, or cannot be read, no AnchorIndex entry is created, **no `IoError` is recorded**, and no diagnostic is emitted. Pass 2 produces the ordinary `broken(file-not-found)` / `broken(broken-symlink)` / `broken(target-is-directory)` verdict for links to it. Only failures reading files that are **in the scan set** contribute to `io_errors`."* Mirror it in system-overview.md Pass 1.5 step (b)/(c) and in DI-006.
**Owner:** architect (system-overview + Pass 1.5 contract) + product-owner (BC-2.05.001 PC)

---

### P2-C06 — A nonexistent PATH argument exits immediately in system-overview.md and continues scanning in interface-definitions.md
**Files:** `.factory/specs/architecture/system-overview.md:207-216` vs `.factory/specs/prd-supplements/interface-definitions.md:236`

- system-overview.md v1.3: *"**Startup configuration errors ... are NOT subject to no-fail-fast.** If the tool detects ... a `PATH` argument that does not exist or is unreadable (BC-2.01.009) — it **exits immediately** with code 2 ... **No file traversal occurs.** These are **`E-CLI-001`** usage errors, not runtime I/O errors."*
- interface-definitions.md §8: *"Nonexistent PATH argument | Error recorded (**`E-IO-002`**); **scanning continues for remaining valid PATH arguments; exit 2 after all scanning completes** (DD-007 no-fail-fast)"*

These disagree on (a) whether any output is produced at all, (b) whether traversal happens, (c) the error class ID. system-overview.md v1.3's changelog says it was edited specifically to reconcile BC-2.11.004 and it explicitly names BC-2.01.009 — but interface-definitions.md was not touched.

**Failure scenario:** `mdlinkcheck docs/ typo-dir/` where `docs/` contains three broken links. Under system-overview.md: stdout empty, exit 2. Under interface-definitions.md: three findings on stdout, exit 2. A test vector asserting stdout content will pass against one implementation and fail against the other. Downstream, VP-INDEX:127 maps BC-2.01.009 → VP-005 (*"exit-code-io-error Kani proof"*) — but under system-overview.md v1.3 this path exits before `exit_code(findings, io_errors)` is ever called, so VP-005 does not cover BC-2.01.009 at all and that VP-INDEX row is false.
**Owner:** product-owner (interface-definitions §8 + BC-2.01.009) + architect (confirm which side BC-2.11.004's reconciliation intended)

---

### P2-C07 — POL-18 holdout boundary is breached in at least five visible artifacts, including all three newly-designated replacement holdouts
**Files:** `.factory/specs/domain-spec/edge-cases.md:36-45, 61-69, 136-146` · `.factory/specs/domain-spec/invariants.md:53-54` · `.factory/specs/verification-properties/vp-003-slug-duplicate-uniqueness.md:49-52, 127-140` · `.factory/specs/prd.md:345, 572-574` · `.factory/specs/prd-supplements/test-vectors.md:155`

Reserved holdout IDs (prd.md:332): EC-036, EC-049, EC-074, EC-079, EC-093, EC-094, EC-141, EC-147, EC-148, EC-151, EC-156, EC-157, EC-158. POL-18 (policies.yaml:307-308): *"No visible artifact may contain the full scenario specification (input + expected output) for a reserved holdout EC ID."*

Verified independently — the leaks are not in BC bodies (those were swept), they are in the **L2 source, the invariants, the VP files, and prd.md's own changelog**:

| Holdout | Visible artifact | Leak |
|---|---|---|
| EC-049 | `edge-cases.md:36-45` (DEC-001, self-tagged `[HOLDOUT]`) | Full vector: *"Headings `Foo`, `Foo`, `Foo-1` ... Slugs are `foo`, `foo-1`, `foo-1-1`. All three links must resolve `clean`."* |
| EC-049 | `prd.md:345` | *"BC-2.06.002 \| 0-based collision-bumping handles the `Foo/Foo/Foo-1` pattern correctly"* |
| EC-049 | `vp-003:49-52, 127-140` | Publishes the isomorphic triple (`"Setup"`,`"Setup"`,`"Setup 1"` → `setup`,`setup-1`,`setup-1-1`) **and instructs it be committed as a unit test, "also add to VP-018"** — actively migrating the holdout into the visible suite |
| EC-074 | `edge-cases.md:61-69` (DEC-003, `[HOLDOUT]`) | Full vector: `[x](vendor.md#section)` in `README.md`, `vendor.md` `--ignore`d, `## Section` exists → *"must resolve `clean`"* |
| EC-036 | `edge-cases.md:136-146` (DEC-009, `[HOLDOUT]`) + `invariants.md:53-54` | Full vector: `[x](README.MD)` vs on-disk `README.md` → *"`broken` with reason `file-not-found`"*, stated twice |
| EC-157 | `prd.md:573` | Full vector: *"(`other.md#caf%C3%A9` where `other.md` has `## Café`)"* — and it is near-identical to **visible** DEC-005 / EC-053 (`edge-cases.md:85-94`), differing only same-file vs cross-file |
| EC-158 | `prd.md:574` | Full vector **and expected output**: *"(`## 🚀 Foo` + `## Foo` both slug to `foo`; second gets `foo-1`)"* |
| EC-156 | `test-vectors.md:155` (TV-153/EC-153, visible) | prd.md:572 designates EC-156 as *".gitignore × cross-file anchor ... tests DI-006 case 2"*; TV-153 is exactly that scenario with expected `0 / clean`, already a **required visible vector** |

Note also `.factory/holdout-scenarios/wave-scenarios/EC-158-emoji-heading-collision.md:124` refers to *"The **visible** EC-049 holdout"* — the holdout scenario file itself documents the contradiction.

**Failure scenario:** Phase 4 holdout evaluation is the mechanism by which this pilot claims VSDD produces correct behavior on unseen cases. Of 13 reserved IDs, at least 5 (EC-036, EC-049, EC-074, EC-157, EC-158) have complete input+expected-output in visible artifacts, and a 6th (EC-156) is already a mandatory visible test vector. A passing holdout score proves nothing. This is unrecoverable after implementation begins.

**Fix:** (a) strip the scenario bodies from edge-cases.md DEC-001/DEC-003/DEC-009 and invariants.md:53-54, replacing with the domain rule only and a pointer to `.factory/holdout-scenarios/`; (b) delete the DEC-001 triple from VP-003 (the injectivity harness does not need it — and see P2-m08); (c) rewrite prd.md:572-574 to name the IDs and mechanisms without inputs or expected outputs; (d) re-designate EC-156 and EC-157 — both are duplicates of visible vectors and carry no signal.
**Owner:** product-owner (holdout boundary owner per DD-021) + business-analyst (edge-cases.md, invariants.md)
**Tag:** `[process-gap]` — POL-18's audit procedure (policies.yaml:316-319) greps prd.md and assumptions.md only. It does not grep `domain-spec/edge-cases.md`, `domain-spec/invariants.md`, `verification-properties/`, or prd.md's own changelog narrative. The leak class recurred *because the sweep's scope was narrower than the artifact set*.

---

## MAJOR

### P2-M01 — BC-2.10.002's "total partition of 0..=599" is not total, and three documents state three different ranges
**File:** `.factory/specs/behavioral-contracts/ss-10/BC-2.10.002.md:41-42, 51-76, 97-98` · `.factory/specs/verification-properties/vp-007-http-verdict-total.md:42, 67, 76-84, 156`

Unmapped status regions:
- **1xx (100, 101, 103) and 0..=99 entirely absent.** The partition starts at 2xx. A server emitting `103 Early Hints` on HEAD, or a client encoding "no response" as status 0, has no postcondition. Invariant 3's claim of exhaustiveness over `0..=599` is false.
- **Bare HEAD 400 with no GET fallback.** PC3 covers only *"400 (after HEAD→GET fallback)"*. PC10's "other 4xx" is enumerated as `402, 406–409, 411–428, 430–499` — which **excludes 400**. So HEAD→400 (no fallback triggered) is unmapped.
- **GET also returns 405.** PC7 says 405 *"triggers GET fallback ... apply this partition to the GET response"*. If the GET response is also 405, the rule recurses with no base case.

Range claims: BC-2.10.002 says `0..=599`; VP-007's Property Statement (line 42) says *"in the range 0..=999"*; VP-007's harness (line 76) says *"No range assumption — must be total for ALL u16 values"* and its feasibility table (line 156) says `65536 × 2`. Kani will prove totality over `0..=65535` against a BC that partitions `0..=599` — so `classify_response(60000, _)` must return *something*, and no artifact says what.

**Failure scenario:** VP-007's `verify_vp007_http_verdict_total` fails at Phase 6 on a `match` with no arm for 1xx (or the implementer adds a catch-all `_ => Indeterminate` that silently swallows 1xx, defeating the "total partition" claim BC-2.10.002 exists to make). Neither outcome is traceable to a spec decision.
**Fix:** add PC entries for `0..=99`, `1xx`, bare-HEAD-`400`, and GET-also-405; align all three range statements to a single value; state the catch-all arm explicitly rather than by omission.
**Owner:** product-owner (BC) + architect (VP-007)

### P2-M02 — VP-008 never asserts case-sensitivity, and its only NFC test is vacuous by construction; DI-002's binding half is unverified
**File:** `.factory/specs/verification-properties/vp-008-path-nfc-comparison.md:38, 53-83` · over-claimed at `.factory/specs/architecture/decisions/ADR-006-strict-path-model.md:110`

VP-008's Property Statement promises both halves of DI-002/D-006: *"For paths where `nfc_normalize(a) != nfc_normalize(b)` (different paths **regardless of case**), `files_match` returns `false`. **No case-folding is applied.**"*

The harness contains three properties, none of which tests that:
1. `vp008_nfc_reflexive` — `files_match(s, s)` is true. Passes for byte-equality **and** for case-folding.
2. `vp008_nfc_symmetric` — symmetry. Passes for byte-equality **and** for case-folding.
3. `vp008_percent23_not_split` — strategy is `"[a-z/\\.]+%23[a-z/\\.]*"`. This generates only lowercase ASCII, `/`, `.`, and `%23`. **No such string contains a combining character**, so `to_nfd(&s) == s` always and the assertion reduces to `files_match(s, s)` — identical to property 1. The test name and strategy are copy-pasted from a fragment-split (`%23`) test; the comment claims it tests *"NFC-equality over pre-known NFD/NFC pairs"*. It cannot generate an NFD/NFC pair.

So an implementation of `files_match` that calls `to_lowercase()` on both sides passes VP-008 in full. VP-009 does not help — it verifies `nfc(nfc(s)) == nfc(s)`, a library property of `unicode-normalization` that its own feasibility table concedes (*"The `unicode-normalization` crate guarantees idempotency"*). **DI-002 is claimed "All Covered? Yes" by VP-008 + VP-009 (VP-INDEX:75, verification-architecture.md:115) and its case-sensitivity half has zero falsifying test.** ADR-006:110 asserts *"VP-008 proptest verifies NFC normalization is applied in path comparison (no stubs needed)"* — an over-claim.

Note VP-008 is at `version: "1.0"`, `modified: []` — it has never been revised, so this is not a re-report of a fixed finding.

**Fix:** replace property 3 with (a) a real NFD/NFC pair strategy over a curated combining-character set (`é`/`e+U+0301`, `ñ`, `ガ`) asserting `files_match == true`; and (b) a **new** case-differing property: for any `s` containing at least one ASCII letter, `files_match(s, s.to_uppercase()) == false`. Without (b), D-006 is unverified.
**Owner:** architect

### P2-M03 — VP-004 never asserts the forward direction; a `split_fragment` that always returns `None` passes every assertion
**File:** `.factory/specs/verification-properties/vp-004-fragment-split.md:38-41, 58-85`

Property Statement item 1: *"If `s` contains a literal `#`, `split_fragment(s)` returns `(path, Some(fragment))`."*

The harness asserts only the converse and a conditional:
- P1: `if !s.contains('#') { assert!(fragment.is_none()) }`
- P2: `if s.contains("%23") && !s.contains('#') { assert!(fragment.is_none()) }` — logically subsumed by P1.
- P3: `if let Some(frag) = fragment { ... }` — vacuous when `fragment` is always `None`.

`fn split_fragment(s: &str) -> (&str, Option<&str>) { (s, None) }` satisfies all three. This is the P0 Kani proof designated as the primary discharge of DI-003 (the Sphinx-#13620 root-cause invariant) and it cannot detect a fragment-splitter that never splits.
**Fix:** add `if s.contains('#') { assert!(fragment.is_some()); assert_eq!(path.len(), s.find('#').unwrap()); }`. Tighten P3 from `s.starts_with(&reconstructed) || reconstructed == s` to `reconstructed == s` (the disjunction admits a splitter that truncates the fragment).
**Owner:** architect

### P2-M04 — VP-019 is mis-anchored to a BC title that does not exist and proves a strictly weaker property than DI-005
**File:** `.factory/specs/verification-properties/vp-019-one-verdict-per-link.md:14, 38, 43, 85`

- `source_bc: BC-2.03.001`; Source Contract line 43 names it *"BC-2.03.001 — **Single Verdict per Link**"*. Per VP-INDEX:142, BC-2.03.001 is *"Inline link/image extraction"*. The title is invented.
- The property proved is *"each unique `(source_file, dest, line, col)` tuple appears at most once in the output of `extract_links`"* — i.e. **no duplicate extraction**. DI-005 is *"Each extracted link is assigned exactly one verdict... A link cannot have two verdicts **or no verdict**."* The VP establishes neither existence (at-least-one verdict) nor uniqueness of *verdict assignment* downstream of extraction. The real DI-005 risk is a link like `[x](missing.md#anchor)` producing both a `file-not-found` finding from `path_resolver` and an `anchor-not-found` finding from `anchor_resolver` — the exact hazard BC-2.07.005 Invariant 1 and BC-2.08.002's carve-outs exist to prevent. VP-019 is structurally incapable of detecting it.
- The harness key is `(link.dest, link.line, link.col)` — it drops `source_file`, contradicting the stated tuple.
- Feasibility line 85 concedes vacuity: *"the property holds by construction if `into_offset_iter` yields each event once"* — and `arb_markdown_with_links()` is undefined, so no falsifying input is specified.

**Fix:** retitle to what it proves (`extract_links` is duplicate-free) and mark DI-005 as **not covered**; then add a real DI-005 VP: for an arbitrary corpus, `findings.len() == links.iter().filter(broken_or_indeterminate).count()` and no two findings share `(file, line, column)`. Correct the Source Contract to BC-2.03.001's actual title.
**Owner:** architect + product-owner (VP-INDEX DI-005 row)

### P2-M05 — Systematic BC-title invention across VP files, plus an unpropagated VP-001 fix in verification-architecture.md
**Files:** `vp-011-sort-deterministic.md:42` · `vp-017-scan-terminates.md:42` · `vp-019-one-verdict-per-link.md:43` · `vp-016-ignored-files-anchor-targets.md:42` · `.factory/specs/architecture/verification-architecture.md:38-39`

Four VP files name their source BC with a title that does not appear in BC-INDEX/VP-INDEX:

| VP | VP file's claimed BC title | Actual title (VP-INDEX) |
|---|---|---|
| VP-011 | "BC-2.12.001 — Deterministic Output Ordering" | "Text report format — one finding per line" |
| VP-017 | "BC-2.01.004 — Scan Termination with Symlink Cycle Handling" | "Dot-directory skip (unconditional, D-011)" |
| VP-019 | "BC-2.03.001 — Single Verdict per Link" | "Inline link/image extraction" |
| VP-016 | "BC-2.08.004 — Ignored File Anchor Resolution" | "Cross-file anchor into ignored file" |

VP-017 is the worst: it anchors a *termination* property to a BC about *dot-directory skipping*, so DI-009's discharge points at a contract that does not govern it. A formal-verifier reading VP-017 → BC-2.01.004 finds no termination postcondition to prove against.

Separately, **verification-architecture.md's Provable Properties Catalog was only half-fixed.** Its v1.2 changelog claims *"corrected P0 harness example for VP-001 (slugify not compute_slug)"* — the code block at lines 84-96 is indeed correct. But the **table row at line 38 was not updated**: *"VP-001 | `slug::compute_slug` is total — no panic for **any `&str` input**"*. VP-001 v1.1 was deliberately restructured (F-018) to target `slugify()` and bounded to **ASCII, ≤16 bytes**. Line 39 (VP-002) has the same stale `compute_slug` reference. Classic frontmatter/body-style partial fix: the illustrative code was fixed, the normative table row was not, and the table over-claims unbounded `&str` totality that no harness establishes.
**Fix:** correct the four Source Contract titles from BC-INDEX; correct verification-architecture.md lines 38-39 to `slugify`, ASCII, ≤16 bytes.
**Owner:** architect

### P2-M06 — VP-024's harness is unrunnable: the control test contradicts BC-2.07.002 root-relative resolution
**File:** `.factory/specs/verification-properties/vp-024-path-resolver-trailing-slash.md:70-112`

`arb_dir_index_with_file()` builds `dir = PathBuf::from("/tmp/test")` and returns `file_path = dir.join(&name)`. Both harnesses then pass `dest = file_path.to_str()` — i.e. a **leading-slash absolute string** `/tmp/test/foo.md` — into `resolve_path(&dest, src_dir, &index)`.

Per BC-2.07.002 ("Root-relative link resolution") and CAP-007 (*"root-relative: against git repo root or scan root"*), a destination beginning with `/` is resolved **root-relative**, not filesystem-absolute. So:
- `vp024_no_trailing_slash_on_file_is_clean` (the control) asserts `PathVerdict::Clean` for a dest that resolves to `<scan-root>/tmp/test/foo.md`, which is not in `index` → the control **fails** on a correct implementation.
- `vp024_trailing_slash_on_file_is_file_not_found` then passes for the **wrong reason**: `FileNotFound` because the path isn't in the index at all, not because a trailing slash was applied to a `File` entry. The property is true by construction and the `TargetIsDirectory` arm is unreachable — which is precisely the regression VP-024 exists to catch (its own feasibility table: *"a single conditional on `EntryKind`; easy to swap under refactor"*).

**Fix:** make `dest` relative (`format!("{}/", name)`) with `src_dir = dir`, and key `index` on `dir`. Or state explicitly that `resolve_path` takes pre-resolved absolute paths and that root-relative expansion happens upstream — but nothing currently says that, and api-surface.md's `resolve_path(dest, src_dir, &index)` signature implies otherwise.
**Owner:** architect

### P2-M07 — CAP-008 says skip the anchor check for directory targets; BC-2.07.005 PC2 says directory+fragment is `broken`
**Files:** `.factory/specs/domain-spec/capabilities.md:122-129` (CAP-008) vs `.factory/specs/behavioral-contracts/ss-07/BC-2.07.005.md:42-44, 56-57, 63-64, 73, 80`

CAP-008: *"Skip the anchor check for non-Markdown targets (DEC-008) **and plain directory targets** (anchor tables cannot be built for directories)."* No fragment-present qualifier — so `[x](docs#section)` skips the check and yields `clean`.

BC-2.07.005 v1.1 PC2: *"If the link has **a fragment**: verdict is `broken`, reason `target-is-directory`."* Its changelog records this case as newly *added* in v1.1, and error-taxonomy.md:49 agrees (`target-is-directory` trigger = *"Destination resolves to a directory AND a fragment is appended"*).

The v1.1 BC edit and the taxonomy edit propagated; **CAP-008 — the L2 capability the BC traces to — did not.** capabilities.md is at v1.2, edited the same day, and its changelog mentions CAP-008 only for a DEC-009 reference removal.

**Failure scenario:** implementer works from CAP-008 (L2 is the authority for "what the system does") and routes directory+fragment to `clean`. Corpus vector `docs#section → broken(target-is-directory)` (BC-2.07.005:80) fails, and `target-is-directory` becomes a dead reason code — silently violating the closed-taxonomy completeness that VP-021 is meant to guard.
**Fix:** CAP-008 → *"Skip the anchor check for non-Markdown targets (DEC-008). For directory targets, `path_resolver` decides: no fragment → `clean`; fragment present → `broken(target-is-directory)`; `anchor_resolver` is never called (BC-2.07.005)."*
**Owner:** business-analyst

### P2-M08 — `--allow` promises exemption from syntax validation, but its normalize-then-match algorithm makes that unreachable for exactly the URLs that fail syntax validation
**Files:** `.factory/specs/behavioral-contracts/ss-11/BC-2.11.002.md:37-41, 50-57` · `.factory/specs/domain-spec/capabilities.md:166-168` (CAP-011) · `.factory/specs/prd-supplements/interface-definitions.md:56, 234`

BC-2.11.002 (the canonical `--allow` contract per F-017) states the flag *"exempts external URLs from **both syntax validation** and liveness checking"*, then specifies PC1: *"**Step 1 — Normalize:** The URL is WHATWG-normalized **before any comparison occurs**."* PC5: *"No match: proceed with normal validation (offline syntax check ...)."*

A URL that fails WHATWG parse cannot be WHATWG-normalized. Step 1 cannot complete → no prefix can match → PC5 fires → `broken(malformed-url)`. **`--allow` can never exempt a malformed URL from syntax validation.** The promise is unsatisfiable for its only relevant input class. interface-definitions.md §8 repeats the unreachable promise (*"`--allow PREFIX` in offline mode | Suppresses syntax validation for matching URLs"*), as does CAP-011.

**Failure scenario:** a repo documents an intranet URL with a space or an underscore-in-host (`https://build_server/status`) that WHATWG rejects. The CI engineer adds `--allow https://build_server` to unblock the build. Exit code stays 1 with `malformed-url`, and there is no flag combination that fixes it — the user's only recourse is `--ignore` on the entire source file, losing all other link checking in it. This is the false-positive class the product exists to eliminate.

**Fix:** decide and state one of: (a) if WHATWG normalization fails, fall back to raw-string prefix match with the same component-boundary rule (PC3 applied to the raw string), then exempt; or (b) `--allow` exempts **liveness only**; syntax validation always applies — and remove the "syntax" promise from BC-2.11.002, CAP-011, and interface-definitions.md §2.2/§8. Add the corresponding test vector either way.
**Owner:** product-owner

### P2-M09 — EC-090/091/092 are assigned to two different scenarios in two BCs, and the EC registry has drifted past its declared bounds
**Files:** `.factory/specs/behavioral-contracts/ss-10/BC-2.10.002.md:108-110` vs `.factory/specs/behavioral-contracts/ss-11/BC-2.11.002.md:68-70` · `.factory/specs/prd.md:332` · `.factory/specs/behavioral-contracts/ss-07/BC-2.07.005.md:73` · `.factory/specs/behavioral-contracts/ss-08/BC-2.08.004.md:23`

| ID | BC-2.10.002 | BC-2.11.002 |
|---|---|---|
| EC-090 | HTTP 401 on GitHub raw content → indeterminate | `--allow https://example.com`; URL `.../path` → exempt |
| EC-091 | https→http redirect → indeterminate | `--allow`; `example.com.evil.tld` → NOT exempt |
| EC-092 | Private IP `http://10.0.0.1/` → indeterminate | `--allow`; `example.comX/path` → NOT exempt |

One of these BCs is citing three IDs that mean something entirely different. This block sits **immediately adjacent to reserved holdouts EC-093 and EC-094**, and BC-2.10.002's changelog records *"Removed holdout EC-093"* — so its numbering was drawn from the EC-087..EC-094 HTTP block, making BC-2.11.002's EC-090..092 the likely fabrications. POL-16 (`bc_traceability_id_resolution`) and POL-18 both depend on EC IDs being a unique registry; a collision one ID away from two holdouts means a holdout could be silently un-reserved by renumbering.

Registry drift, same root cause:
- prd.md:332 declares *"155 edge cases (EC-001..EC-158)"*. BC-2.08.004 v1.5 introduced **EC-159 and EC-160**; the declared upper bound is stale.
- BC-2.07.005:73 uses **`EC-NEW-3`** — a non-conforming ID outside the numeric registry entirely.
- 155 vs the 158-wide range implies 3 unexplained gaps, unreconciled anywhere.

**Fix:** adjudicate EC-090/091/092 against test-vectors.md, renumber the loser, extend prd.md:332's declared range to EC-160, replace `EC-NEW-3` with a registry ID, and reconcile the 155 count.
**Owner:** product-owner
**Tag:** `[process-gap]` — nothing validates EC-ID uniqueness across BC files; POL-16 covers resolution (does the ID exist?) but not injectivity (is it used for one scenario only?).

### P2-M10 — BC-2.01.001 still gates dot-directory skip on `--hidden` and carves out `.git/`
**File:** `.factory/specs/behavioral-contracts/ss-01/BC-2.01.001.md:50`

> *"Dot-directories other than `.git/` are skipped **unless `--hidden` is passed**. (BC-2.01.004)"*

Two defects in one line, both contradicting the artifact it cites:
1. `--hidden` is a dropped non-goal (D-011/DD-018). BC-2.01.004:54 (v1.3): *"ALL dot-directories are unconditionally excluded. **No flag overrides this**."*
2. *"other than `.git/`"* implies `.git/` is **not** skipped — inverting DI-006 item 3, capabilities.md CAP-001, and system-overview.md:82-84, all of which say every `.`-prefixed directory is always skipped.

The D-011 sweep reached BC-2.01.004, BC-2.10.006, BC-2.12.003, invariants.md, capabilities.md, api-surface.md, and interface-definitions.md — and missed BC-2.01.001, a sibling in the same subsystem. Per the sibling-propagation axis this is HIGH.

**Failure scenario:** implementer reads BC-2.01.001 (the *first* BC in SS-01, the natural entry point) and adds a `--hidden` clap flag plus a `.git/`-specific traversal branch. Both are scope creep against a frozen human decision, and `mdlinkcheck .` in any git repo begins traversing `.git/` — scanning `.git/COMMIT_EDITMSG`-adjacent markdown and blowing the NFR-001 budget.
**Owner:** product-owner (spec-steward for a completeness re-sweep of D-011 across all 66 BCs)

### P2-M11 — JSON output is an object in L3 and an array in the frozen L1 brief; CAP-013 states an impossible shape
**Files:** `BRIEF.md:28` (R6, FROZEN) · `.factory/specs/domain-spec/capabilities.md:187-194` (CAP-013) · `.factory/specs/prd-supplements/interface-definitions.md:45, 149-183` · `.factory/specs/prd.md:268`

- BRIEF R6 (frozen): *"`--format json` emits a machine-readable **array** of the same."*
- CAP-013: *"emit findings on stdout as a **JSON array** with a `schema_version` field"* — **a JSON array cannot have a named field.** The L2 capability is internally impossible.
- interface-definitions.md §2.1 and §6: *"a JSON **object**"* with `schema_version`, `results`, `errors`.
- prd.md:268: `{schema_version: 1, results: [...]}` — object, and it omits `errors`, which interface-definitions.md v1.4 added.

The object shape is the better design (it carries `schema_version` and separates `errors` per F-013), but it is a **deviation from a frozen requirement that is nowhere recorded as an accepted interpretation** — and the L2 layer in between is self-contradictory, so nothing traces cleanly from R6 to §6.

**Failure scenario:** a test-writer authoring the R6 acceptance vector reads CAP-013, asserts `serde_json::from_str::<Vec<Finding>>(stdout)`, and the test fails against the §6 object. Separately, VP-021's harness reads `json["results"]` (object form) — so if anyone implements the array form, VP-021 panics on `as_array().unwrap()` of a null and NFR-007 loses its enforcement entirely.
**Fix:** correct CAP-013 to *"a JSON object with `schema_version`, `results`, and `errors`"*; add an explicit R6-interpretation note in prd.md §2 recording that "array" is satisfied by the `results` array inside a versioned envelope; sync prd.md:268 to include `errors`.
**Owner:** business-analyst (CAP-013) + product-owner (prd.md R6 interpretation record)

### P2-M12 — Pass 1.5's owning module is stated three ways
**Files:** `.factory/specs/architecture/system-overview.md:94` · `.factory/specs/architecture/purity-boundary-map.md:74, 101` · `.factory/specs/architecture/module-decomposition.md:78, 114` vs `.factory/specs/architecture/api-surface.md:82` · `.factory/specs/architecture/decisions/ADR-006-strict-path-model.md:94-95`

- system-overview.md:94: *"Pass 1.5 (shell only, sequential — **app**)"*; purity-boundary-map.md:74: *"`app` ... builds DirIndex via Pass 1.5 (`fs::read_dir`)"*; module-decomposition.md:78: *"`app` | `app.rs` | Three-phase pipeline orchestration ... builds DirIndex"*.
- api-surface.md:82: *"DirIndex populated by **scanner** Pass 1.5 — never by path_resolver itself"*.
- ADR-006:94-95: *"When **`scanner`** encounters such an entry during Pass 1.5 directory reads..."*

This is not cosmetic. It determines (a) which file the code lives in, (b) which mutation-kill tier applies — `app` is MEDIUM/≥80%, `scanner` is HIGH/≥90% (verification-coverage-matrix.md:101-102), and (c) which module owns ADR-006's non-UTF-8-entry skip + stderr warning. An ADR is the highest-authority artifact for the path model and it names the wrong module.
**Fix:** pick `app` (consistent with the majority and with the purity boundary: `scanner` is described as traversal+read, `app` as orchestration) and correct api-surface.md:82 and ADR-006:94-95.
**Owner:** architect

### P2-M13 — Pass 1.5's bootstrapping order is circular as specified, and the AnchorIndex/DirIndex key form is never defined
**Files:** `.factory/specs/architecture/system-overview.md:73-76, 94-118` · `.factory/specs/behavioral-contracts/ss-05/BC-2.05.001.md:46-48, 58-62` · `.factory/specs/domain-spec/invariants.md:176-180`

The bootstrapping invariant states *"**No link resolution occurs during Pass 1 or Pass 1.5.**"* But Pass 1.5's identification mechanism is *"it collects every `.md` destination from LinkMap that is **NOT already a key in AnchorIndex**"* — AnchorIndex is `HashMap<PathBuf, AnchorTable>`, and link destinations in LinkMap are **raw strings** (`link_target` is *"the raw link destination as written in source (before any percent-decoding)"*, interface-definitions.md §6.2). Converting `"../docs/a.md#x"` into a `PathBuf` key requires: fragment split (DI-003), percent-decode, relative/root-relative join (BC-2.07.001/002), and NFC normalization (DI-002) — **that is link resolution**, and DI-002's case-sensitive form of it requires comparison against real directory entries, which is what DirIndex provides and what Pass 1.5 is building. The dependency is circular.

Compounding it, **no artifact defines the canonical key form** for AnchorIndex or DirIndex. Pass 1's keys come from WalkBuilder traversal; Pass 1.5's would come from lexical join. If the two spellings differ in NFC form, in `.`/`..` retention, or in canonicalization, the membership test yields **false negatives** — Pass 1.5 re-reads and re-parses files already indexed and inserts a *second* AnchorIndex entry under an alternate spelling, after which Pass 2's lookup may hit either. Silent wrong verdicts, non-deterministic across platforms.

Third: system-approach conflict on the dedup key. system-overview.md:114 says *"each directory is visited by its **absolute canonical path**"*; invariants.md:177-178 says *"each directory is visited at most once (**path-identity** deduplication)"*. These differ exactly on symlinks — the case DI-009's cycle-safety argument rests on. And `fs::canonicalize` **case-normalizes** on macOS/APFS and Windows, directly at odds with system-overview.md:221-224 and ADR-006:78-83 (*"We do NOT call `to_lowercase()` or any case-folding function"*): a `[x](DOCS/a.md#x)` link would canonicalize to the on-disk `docs/`, succeed the read_dir, and lose the case-mismatch signal that D-006 mandates.

Fourth: invariants.md DI-009 describes Pass 1.5 as *"only the immediate parent directory of each link destination is read"* — a **DirIndex** operation — while DI-006 and BC-2.05.001 describe it as **building anchor tables** (which requires reading and parsing the target *file*, step (c) in system-overview.md:109). The termination argument only bounds the directory reads, not the file parses.

**Fix:** (a) define the canonical key form once — recommend "NFC-normalized, lexically-normalized (`.`/`..` collapsed), non-canonicalized, scan-root-relative `PathBuf`" and state it in module-decomposition.md and api-surface.md; (b) amend the bootstrapping invariant to *"no link **verdict** is produced during Pass 1 or Pass 1.5; destination-to-path **key derivation** (fragment split + percent-decode + lexical join + NFC) is permitted and is not case-sensitivity-checked at this stage"*; (c) replace "canonical path" at system-overview.md:114 with the same non-canonicalizing key form and align invariants.md:177; (d) DI-009 must bound both directory reads and file parses.
**Owner:** architect

### P2-M14 — Three integration VPs are credited with coverage their harnesses do not provide (DI-006, DI-004, BC-2.04.003, Pass 1.5)
**Files:** `vp-016:38, 49, 53-81` · `vp-014:38, 49, 56-79` · `vp-015:38, 49, 53-81` · claimed at `VP-INDEX.md:77, 79, 81, 121, 153-155` and `verification-architecture.md:69-71, 117, 119, 121`

- **DI-006:** VP-INDEX:79 and verification-architecture.md:71 assert VP-016 covers *"all 4 exclusion mechanisms"* / *"--ignore'd, .gitignore'd, dot-dir, and outside-root files"*. VP-016's Property Statement covers only `--ignore` (*"excluded from scanning via `--ignore` patterns"*), and its single fixture sets `ignore_patterns: vec!["ignored.md"]`. Cases 2, 3, 4 — the three that go through the **Pass 1.5 code path**, structurally different from case 1 — have **no fixture**. VP-INDEX:121 separately credits VP-016 with BC-2.01.003 (*.gitignore exclusion*), which VP-016 does not test.
- **DI-004:** invariants.md DI-004 and CAP-004 both enumerate **five** code contexts (fenced, inline span, indented, HTML `<pre>`/`<code>`, HTML comment). VP-014's Property Statement lists **three** (omits HTML `<pre>`/`<code>` and HTML comments) and shows two fixtures. VP-INDEX:154 nonetheless credits VP-014 with BC-2.04.002 (*"Indented code/**HTML comments** yield no links"*).
- **BC-2.04.003** (*"ATX headings in fenced blocks no anchor"*) is credited to VP-014 (VP-INDEX:155). VP-014's module is `link_extractor` and it asserts only on `extract_links` output. Whether a `# Heading` inside a fence enters the **anchor table** is an `anchor_table` concern that VP-014 never touches. Zero coverage.
- **Pass 1.5 / DI-008:** VP-INDEX:81 and verification-architecture.md:121 credit VP-015 with *"two-pass **+ Pass 1.5**"*. VP-015's two fixtures are both in-scan files in the same tempdir; there is **no out-of-scan target fixture**, so Pass 1.5 is untested. Worse, `vp015_reverse_reference_resolves` is vacuous: `a.md` (lexicographically first) defines the heading and `b.md` links back to it, so a broken **single-pass** implementation passes it. Only the forward test discriminates.

**Failure scenario:** the Phase 1 gate reads "DI-006 Covered? Yes" and closes. A `.gitignore`d anchor target regression ships undetected because the *only* code path with a test is `--ignore` (case 1), which does not use Pass 1.5 at all. This is exactly the risk HS-001/EC-156 was designated to cover — and per P2-C07 that holdout is itself compromised, so the gap has **no** guard.
**Fix:** add fixtures to VP-016 for `.gitignore`, dot-directory, and outside-root targets (test-vectors.md TV-153/154/155 supply the vectors); add HTML-comment and `<pre>` fixtures to VP-014 or narrow DI-004's claimed coverage and open a new VP; move BC-2.04.003 to a new `anchor_table` VP or mark it test-sufficient with a named fixture; add an out-of-scan-target fixture to VP-015 and replace the vacuous reverse test with one where the target file sorts *after* the source.
**Owner:** architect

### P2-M15 — BC-2.10.002 declares VP-007's proof method as "unit test" and attributes two properties VP-007 cannot prove
**File:** `.factory/specs/behavioral-contracts/ss-10/BC-2.10.002.md:130-136`

The Verification Properties table lists four VP-007 rows, all with `Proof Method: unit test` / `unit test with mock HTTP`. VP-007 is `proof_method: kani`, P0, Phase 6 (VP-INDEX:51, verification-coverage-matrix.md:44). The BC declares the wrong method for its own designated VP.

Two of the four rows are properties VP-007 does not and cannot establish:
- *"https→http downgrade produces indeterminate and blocks request"* — VP-007's harness (lines 72-141) contains no downgrade assertion.
- *"private-IP target never sends outbound request"* — VP-007 is a Kani proof over a **pure** function `classify_response(u16, HttpAttempt)`. "No outbound request is sent" is a statement about I/O in the effectful shell; a pure-core Kani harness is structurally incapable of proving it. VP-INDEX:214 correctly routes BC-2.10.010 to `test-sufficient` with *"assert no socket opened"* — so the BC's attribution contradicts VP-INDEX.

**Failure scenario:** the formal-verifier, working the P0 Kani list, reads BC-2.10.002 and attempts to encode "no socket opened" in Kani, fails, and either stubs it (a false VERIFIED lock) or blocks. Meanwhile the integration test that *can* assert it is never written, because the BC says VP-007 has it covered.
**Fix:** correct the method column to `kani`, delete the two rows VP-007 cannot prove, and add explicit `test-sufficient` rows pointing at BC-2.10.007 (downgrade) and BC-2.10.010 (private-IP) integration tests.
**Owner:** product-owner

### P2-M16 — DI-001 ("two runs produce byte-identical output") has no falsifying test anywhere in the package
**Files:** `.factory/specs/domain-spec/invariants.md:37-45` (DI-001) · `vp-011-sort-deterministic.md:53-83` · `.factory/specs/prd-supplements/interface-definitions.md:304`

DI-001's observable contract is *"Two runs over the same inputs with the same flags produce byte-identical output."* The two artifacts that claim to establish it do not:

- **VP-011** has two harnesses. `vp011_sort_deterministic` clones a `Vec`, sorts both copies identically, and compares — **tautological for any deterministic sort function**, which every Rust sort is. It cannot fail. `vp011_sort_order_independent` reverses before sorting, which can only expose instability when two elements share a full sort key; `arb_finding()` generates arbitrary paths/lines/cols, so proptest will effectively never produce a key collision. Neither harness ever invokes the pipeline, so **rayon scheduling order — the actual source of nondeterminism DI-001 exists to neutralize — is never exercised.**
- **The acceptance corpus deliberately discards ordering.** interface-definitions.md §10.2's pass criterion pipes both sides through `sort_by(.file,.line,.column)` before comparing. Any ordering defect is normalized away.

So no artifact runs the binary twice and diffs stdout. DI-001 is currently unfalsifiable.
**Fix:** add a test-sufficient VP (or an AC on VP-022's corpus): run the binary twice on the Tier A corpus, assert `stdout_run1 == stdout_run2` byte-for-byte in both `text` and `json` formats, and repeat with `RAYON_NUM_THREADS` set to 1 and to 16 to force different scheduling. Also assert the sorted output equals the sort of a shuffled input *of the same findings*.
**Owner:** architect

### P2-M17 — The `private-ip` and `https-downgrade` sub-reasons have no field to live in: either NFR-007 is violated or the information is unrepresentable
**Files:** `.factory/specs/prd-supplements/error-taxonomy.md:69, 95, 143` · `.factory/specs/behavioral-contracts/ss-10/BC-2.10.002.md:57-58, 88, 126-127` · `.factory/specs/prd-supplements/interface-definitions.md:184-197` · `.factory/specs/domain-spec/capabilities.md:191`

BC-2.10.002 PC2 writes: *"`indeterminate` (`http-indeterminate`, **reason: https-downgrade**)"*, and PC16: *"(`http-indeterminate`, **reason: private-ip**)"*. Its Canonical Test Vectors table (lines 126-127) records the expected verdict as *"indeterminate (http-indeterminate, https-downgrade)"* and *"(http-indeterminate, private-ip)"* — i.e. a two-part reason.

But error-taxonomy.md:143 insists *"The closed taxonomy remains 13 codes"*, and `private-ip` / `https-downgrade` are not among them. The finding object schema (interface-definitions.md §6.2; CAP-013:191) is exactly `{file, line, column, link_target, verdict, reason}` — **there is no `sub_reason` field**.

So either (a) the sub-reason is emitted in `reason` → VP-021's assertion fails and NFR-007's closed-set guarantee is violated on a *correct* run; or (b) the sub-reason is dropped → the test vectors at BC-2.10.002:126-127 are unassertable, and the acceptance corpus cannot distinguish a private-IP indeterminate from a 503 indeterminate (a real diagnostic loss, since one is a security-policy outcome and the other is transient).

**Failure scenario:** test-writer authors the BC-2.10.002:127 vector by asserting `reason == "private-ip"`. It fails. They change it to `reason == "http-indeterminate"` and the private-IP behavior (BC-2.10.010, the "no socket opened" security property) becomes indistinguishable from a generic 5xx — silently untestable.
**Fix:** add an optional `sub_reason` string field to the finding object (additive under the pre-1.0 policy per §6.3), enumerate its closed set (`private-ip`, `https-downgrade`, `connection-reset`, `bot-403`), and state explicitly that `sub_reason` is **not** a member of the 13-code `reason` taxonomy so VP-021 does not check it. Or state that sub-reasons appear only in the human message and remove them from BC-2.10.002's canonical vectors.
**Owner:** product-owner

### P2-M18 — LinkMap's contents are stated two ways, and under the architecture reading `--ignore` fails to suppress an ignored file's effect on the exit code
**Files:** `.factory/specs/behavioral-contracts/ss-05/BC-2.05.001.md:55-57` vs `.factory/specs/architecture/system-overview.md:79-92, 94-110, 120`

- BC-2.05.001 PC1: *"The LinkMap contains all extracted links from **scan-set** files."* `--ignore`d files are excluded from the scan set (they are skipped as sources, BC-2.11.001).
- system-overview.md Pass 1: scope is *"ALL .md files reachable by the WalkBuilder traversal, **INCLUDING `--ignore`'d files**"*, and step (c) extracts links for *"each discovered .md file"*, producing LinkMap. So LinkMap **includes** `--ignore`d files' links.

Under the architecture reading, Pass 1.5 iterates LinkMap — including destinations referenced **only** by `--ignore`d files. Combined with P2-C05, an ignored file's broken `.md` link drives a Pass 1.5 read failure and therefore an `IoError` and exit 2, while producing **zero findings** (Pass 2 skips ignored sources).

**Failure scenario:** `mdlinkcheck --ignore 'vendor/**' .` where `vendor/x.md` contains `[x](vendor/deleted.md#api)`. stdout is empty, the stderr summary says *"No broken links found."* (BC-2.12.003 / interface-definitions.md §5), and the process exits **2**. The user has explicitly excluded `vendor/` and cannot make CI green. `--ignore` is the primary escape hatch for third-party docs; this makes it non-functional.
**Fix:** state explicitly that Pass 1.5's destination set is derived from **scan-set** links only (align system-overview.md Pass 1 with BC-2.05.001 PC1, or vice versa — but state which), and land P2-C05's no-IoError rule.
**Owner:** architect + product-owner

### P2-M19 — Exit code 2 for *usage* errors is unmodeled in `exit_code()` and unverified anywhere; the `cli` module has zero VPs
**Files:** `.factory/specs/domain-spec/capabilities.md:198-206` (CAP-014) · `.factory/specs/domain-spec/invariants.md:189-198` (DI-010) · `vp-005:38, 53-79` · `vp-006:53-69` · `.factory/specs/architecture/verification-coverage-matrix.md:80, 103` · `VP-INDEX.md:127, 223, 249`

R7 (frozen) defines exit 2 as *"usage **or** I/O error"*. CAP-014 claims the exit code is *"a pure function of the verdict multiset **and I/O error state**"* — a two-input function — then asserts *"2 = any I/O **or usage** error"*. Usage errors are a **third input** that the stated signature cannot carry, and by system-overview.md:207-216 they occur before any verdict exists.

VP-005 and VP-006 both prove properties of `exit_code(&findings, &io_errors)` — a two-argument function with no usage-error parameter. So:
- **No VP covers the usage-error half of R7.** BC-2.11.004 (invalid `--ignore` glob → exit 2 before scanning), BC-2.14.004 (`--help`/`--version` → exit 0 without scanning), unknown-flag → exit 2 (interface-definitions.md §8), and invalid `--format` value → exit 2 (§2.1) are all `test-sufficient` with no VP.
- The owning module `cli` has **0 VPs of any kind** (verification-coverage-matrix.md:80) and sits in the **LOW** mutation tier at ≥70% kill (line 103) — the weakest guard in the package, on a frozen requirement.
- VP-INDEX:127 maps BC-2.01.009 (nonexistent PATH → exit 2) to VP-005. Per P2-C06 this path may exit before `exit_code` is called at all, in which case the mapping is false (see also P2-C06).

**Failure scenario:** `mdlinkcheck --format xml docs/` returns exit **1** (clap error mishandled, or the error is folded into `io_errors` and coincidentally yields 2 — but nothing pins it). No Kani proof, no proptest, and no listed integration test covers it; the corpus (interface-definitions.md §10) contains only link fixtures, not CLI-misuse fixtures. R7 is one-third unverified.
**Fix:** either extend the modeled function to `exit_code(findings, io_errors, config_error: Option<UsageError>)` and widen VP-005 to a three-boolean symbolic proof covering all 8 combinations including usage-error dominance, or add an explicit `test-sufficient` VP enumerating the usage-error matrix (unknown flag, bad `--format` value, invalid glob, nonexistent PATH, `--help`, `--version`) with asserted exit codes. Correct CAP-014's "pure function of two things" wording. Correct VP-INDEX:127.
**Owner:** architect (VP) + business-analyst (CAP-014)

---

## MINOR

### P2-m01 — VP-020 contains a schema typo, a factually wrong pulldown-cmark claim, and an event-type restriction that excludes the primary D-007 use case
**File:** `.factory/specs/verification-properties/vp-020-html-anchor-narrow-scope.md:31, 38, 40, 74-82`
1. Frontmatter line 31 is `removal_range: null` — should be `removal_reason: null`. The field `removal_reason` is absent; every other VP has it.
2. Line 40: *"HTML inside fenced code blocks (which produce **`Event::Code`**, not `Event::Html`)"*. Factually wrong: pulldown-cmark emits `Start(Tag::CodeBlock)` + `Text` + `End` for fenced blocks; `Event::Code` is **inline** code spans. An implementer filtering on `Event::Code` to exclude fenced content will not exclude it.
3. Line 38 restricts extraction to *"attributes of HTML elements within **`Event::Html`** events"*. In pulldown-cmark 0.13, inline HTML is `Event::InlineHtml` — a distinct variant. The single most common real-world HTML anchor, `<a name="x"></a>` written mid-paragraph, is `InlineHtml` and would be excluded, manufacturing the exact `anchor-not-found` false negative that D-007's carve-out exists to prevent (and that prd.md:343 credits BC-2.05.003 with preventing). VP-020's own fixture 2 (`<span class=...>text</span>`, line 76) is inline HTML, so the harness silently depends on `InlineHtml` being in scope while the property statement excludes it.
**Fix:** `removal_reason: null`; correct the fenced-block event description to `Tag::CodeBlock`; change the property statement to *"`Event::Html` **or `Event::InlineHtml`**"* and add a fixture for inline `<a name="x"></a>`.
**Owner:** architect

### P2-m02 — VP-022's threshold is self-calibrating and its metric is not the one it claims
**File:** `.factory/specs/verification-properties/vp-022-regression-gate.md:14, 38, 62, 76-101, 111`
- `source_bc: ""` (empty) — the only VP with no source contract.
- The property is *"p95 wall-clock ≤ **~500ms**"* (approximate) and line 111 says *"~500ms is a target; exact value is set when Tier A corpus is first defined and **the baseline measured on the CI runner**"*. A gate whose threshold is derived from the measured baseline cannot detect the regression present at baseline-measurement time.
- The metric is not p95: the CI snippet comments *"criterion reports mean; CI uses 2x mean as p95 proxy"* then invokes `--threshold-ms 500` without stating whether 500 applies to the mean or to `2 × mean`. Under the latter the effective mean budget is 250ms — a 2× difference in strictness, undecidable from the spec.
- The harness measures `mdlinkcheck_core::run_offline(&corpus_path)` inside `b.iter()` — a **library call**, not process wall-clock. The Property Statement says *"The **end-to-end** offline scan ... p95 **wall-clock**"* and lists *"Emit"* in scope. Process startup, clap parsing, and stdout write are excluded.
**Fix:** set `source_bc` (or `nfr: NFR-001` explicitly); replace "~500ms" with a committed number plus a documented recalibration procedure; state the exact statistic the threshold applies to; use `hyperfine` on the binary if wall-clock is the intent, or narrow the Property Statement to library-internal time.
**Owner:** architect

### P2-m03 — `exit_code` vs `compute_exit_code`, and `clean` used where the VP file says `alive`
**Files:** `vp-005:34, 38, 65` and `vp-006:34, 38, 64` (`verdict::exit_code`) vs `.factory/specs/architecture/verification-architecture.md:42-43, 103` (`verdict::compute_exit_code`, `compute_exit_code_symbolic`) · `.factory/specs/architecture/system-overview.md:131` (`verdict::exit_code`)
The function name differs between the VP files (2 uses each) and the architecture catalog. verification-architecture.md:43 additionally describes VP-006 as *"returns 0 when all findings are `clean` or `indeterminate`"* while the VP-006 file says *"alive or indeterminate"* (see P2-C01).
**Fix:** pin one name in api-surface.md and propagate.
**Owner:** architect

### P2-m04 — BC-2.01.008 still references `--quiet`, and states the condition backwards
**File:** `.factory/specs/behavioral-contracts/ss-01/BC-2.01.008.md:49`
> *"The stderr message is emitted even if `--quiet` is not set (it is informational, not a warning)."*

`--quiet` is a dropped non-goal (D-011). The sentence is also logically inverted — "emitted even if `--quiet` is **not** set" is the trivial case; the pre-D-011 intent was "even if `--quiet` **is** set."
**Fix:** *"The stderr message is always emitted; no flag suppresses it (D-011)."* — matching BC-2.12.003:54's already-corrected wording.
**Owner:** product-owner

### P2-m05 — Capability titles invented in BC traceability rows, contradicted one line later in the same table
**Files:** `.factory/specs/behavioral-contracts/ss-10/BC-2.10.002.md:141-142` · `.factory/specs/behavioral-contracts/ss-11/BC-2.11.002.md:89-91` · `.factory/specs/behavioral-contracts/ss-05/BC-2.05.001.md:106-107` · `.factory/specs/behavioral-contracts/ss-07/BC-2.07.008.md:78-79`

Each BC's `L2 Capability` row quotes a fabricated capability title and the very next row (`Capability Anchor Justification`) quotes the real one:

| BC | `L2 Capability` row | `Capability Anchor Justification` row | capabilities.md actual |
|---|---|---|---|
| BC-2.10.002 | "Three-verdict model: alive (clean), broken, indeterminate — ..." | "External URL Liveness Checking" | External URL Liveness Checking |
| BC-2.11.002 | "--allow URL prefix with component-boundary safety" | "Filter Application" | Filter Application |
| BC-2.05.001 | "Build and cache a per-file anchor table" | "Anchor Table Construction" | Anchor Table Construction |
| BC-2.07.008 | "Relative Path Resolution Against Source File's Directory" | "Relative Path Resolution" | Relative Path Resolution |

Per the semantic-anchoring axis this is HIGH severity (*"mis-anchor contradicts elsewhere in the same document"*), but the actual anchor target is correct in every case so the practical blast radius is reader confusion and broken title-sync validation. Also BC-2.11.002:91 records `Brief Requirement | R6` — `--allow` is **R5** (R6 is output format), which capabilities.md CAP-011 gets right.
**Fix:** make the `L2 Capability` row quote the capability H2 title verbatim in all four BCs; sweep the remaining 62. Correct BC-2.11.002's brief requirement to R5.
**Owner:** product-owner
**Tag:** `[process-gap]` — 4-of-5 sampled BCs exhibit it; the pattern threshold is met and no validator checks BC capability-title strings against capabilities.md H2 headings.

### P2-m06 — BC-2.10.002's Related BCs list swaps BC-2.10.006 and BC-2.10.007
**File:** `.factory/specs/behavioral-contracts/ss-10/BC-2.10.002.md:150-151`
> *"BC-2.10.006 — dependency (**connection reset** handling)"* / *"BC-2.10.007 — dependency (**TLS failure** handling)"*

Per VP-INDEX:210-211, BC-2.10.006 is *"TLS handshake failure behavior"* and BC-2.10.007 is *"Redirect chain max 10 hops"*. The postconditions in the same file get it right (PC2 cites BC-2.10.007 for redirects/downgrade; PC14 cites BC-2.10.006 for TLS) — so the Related BCs section alone is wrong, and neither BC covers "connection reset" as its title subject (PC15 also routes connection-reset to BC-2.10.006, which is the TLS BC).
**Fix:** correct the two descriptions; route connection-reset to whichever BC actually owns it (or note it is owned by BC-2.10.002 itself).
**Owner:** product-owner

### P2-m07 — verification-coverage-matrix.md credits VP-014 with url_classifier coverage
**File:** `.factory/specs/architecture/verification-coverage-matrix.md:88`
> *"`url_classifier`: VP-023 (proptest totality); additional coverage via `link_extractor` integration tests (**VP-014**) + BC-2.09.001 tests"*

VP-014 is code-context exclusion (`DI-004`) and has nothing to do with URL classification. Mis-anchor.
**Fix:** delete the VP-014 reference or replace it with the BC-2.09.001 acceptance-corpus reference alone.
**Owner:** architect

### P2-m08 — VP-003's "injectivity" property is subsumed by its own secondary property, and the `assume(s1 != s2)` guard is a no-op
**File:** `.factory/specs/verification-properties/vp-003-slug-duplicate-uniqueness.md:41-52, 68-97`
`DuplicateCounter` guarantees that no slug it has ever returned is returned again, so **any two calls on a shared counter yield distinct results regardless of whether the inputs differ**. `kani::assume(s1 != s2)` therefore excludes nothing that would falsify the assertion, and `verify_vp003_injectivity` proves a strictly weaker statement than `verify_vp003_same_heading_uniqueness` (which covers N ≤ 10 calls, including the N = 2 distinct-input case implicitly). The v1.1 changelog frames this as *"restated property as genuine injectivity"*, but function injectivity is not what a stateful counter has; the correct name is output-uniqueness. Meanwhile the property that *would* be worth proving — that the counter's `while` loop terminates for adversarial inputs, and that `compute_slug` output never collides with a **later** heading's base slug — is only spot-checked by the (holdout-leaking, see P2-C07) DEC-001 unit test.
**Fix:** rename harness 1 to `verify_vp003_output_uniqueness_across_distinct_inputs`, drop the vacuous `assume`, and add the property that actually needs Kani: for a bounded sequence of ≤ 4 symbolic headings, the counter's `while` loop terminates and the output set has cardinality equal to the input count.
**Owner:** architect

---

## Scope check against R1–R8

No scope creep detected in the flag surface (D-011 removals are complete in the CLI table; residue is documentation-only, P2-M10/P2-m04). Two silent scope **losses** and one silent **deviation**:
- **R6 deviation** — frozen brief says "array", the shipped design is an object envelope, and the L2 capability is impossible (P2-M11). The deviation is defensible but unrecorded.
- **R7 partial loss** — the *usage-error* half of exit 2 has no VP, no owning module VP coverage, and the lowest mutation tier (P2-M19); and the exit-code behavior for a nonexistent PATH is specified two incompatible ways (P2-C06).
- **R2b partial loss** — DI-006 cases 2/3/4 (the Pass 1.5 path) have no verification fixture (P2-M14), and the holdout designated to cover the gap duplicates a visible vector (P2-C07).

## Novelty Assessment

**HIGH.** The three highest-value clusters are structural, not cosmetic, and none is a restatement of a formatting concern:
1. **The VP layer does not verify what the indices claim it verifies.** VP-004, VP-008, VP-011, VP-019, VP-024 are individually vacuous or unrunnable; VP-014, VP-015, VP-016 are credited with 4–5× the coverage their harnesses contain; VP-021's whitelist is wrong. This layer had the least prior scrutiny and it is the layer the Phase 1 gate trusts most.
2. **Pass 1.5 is under-specified in exactly the way that inverts R7.** The missing "target does not exist" branch (P2-C05) plus the `--ignore` × exit-2 leak (P2-M18) plus the circular key-derivation bootstrap (P2-M13) are one defect family introduced by the v1.1→v1.3 three-phase rewrite.
3. **The holdout arm is compromised at the source-of-truth layer**, and the previous sweep's scope (BC bodies) was structurally narrower than the leak surface (L2 edge-cases, L2 invariants, VP files, prd.md changelog) — including all three brand-new replacement holdouts (P2-C07).

Novelty is **not** decaying. Do not treat pass 2 as converging.

---

## Perimeter NOT reached — start pass 3 here

Fully unread:
- `.factory/specs/prd-supplements/test-vectors.md` (read only 3 lines via grep) — **highest priority**: it is the arbiter for P2-M09 (EC-090/091/092 collision), the 155/EC-001..EC-158 count, and whether the 13 holdout IDs appear in the visible vector table.
- `.factory/specs/prd-supplements/nfr-catalog.md` — NFR-001..008 not audited; NFR-007's closed-taxonomy wording unverified against P2-C02, NFR-004/005/006 unread.
- `.factory/specs/behavioral-contracts/BC-INDEX.md` — title-sync and subsystem-label axes not run (only line 214 seen via grep).
- **56 of 66 BC files.** Read in full: BC-2.05.001, BC-2.07.005, BC-2.07.008, BC-2.10.002, BC-2.11.002. All of SS-01 (except greps), SS-02, SS-03, SS-04, SS-06, SS-08, SS-09, SS-12, SS-13, SS-14 unread — in particular **BC-2.01.009** (needed to adjudicate P2-C06), **BC-2.02.003** (non-UTF-8 → I/O error, interacts with P2-C05), **BC-2.08.002** (cross-file anchor carve-outs, interacts with P2-M07), **BC-2.10.009** (URL dedup × per-occurrence reporting), **BC-2.13.001/002** (JSON schema, interacts with P2-M11/P2-M17).
- `architecture/module-decomposition.md`, `api-surface.md`, `dependency-graph.md`, `tooling-selection.md`, `feasibility-review.md`, `ARCH-INDEX.md` — read only via grep. `api-surface.md` is needed to settle P2-m03 (`exit_code` naming), P2-M13 (key form), and VP-023's `UrlKind` variant set (whether relative paths have a variant, or fall into `Malformed`).
- ADRs 001, 002, 003, 004, 005, 007 unread; ADR-006 read lines 70-119 only. **ADR-004** (32-thread HTTP pool vs rayon scan pool vs DI-001) and **ADR-007** (three-verdict model — likely decisive for P2-C01) are the priorities.
- `.factory/specs/domain-spec/`: `decisions.md`, `entities.md`, `events.md`, `event-flow.md`, `differentiators.md`, `assumptions.md`, `failure-modes.md`, `L2-INDEX.md` — read only via grep. **`failure-modes.md`** is the declared source of prd.md §5's taxonomy and was not opened.
- `dtu-assessment.md`, `gene-transfusion-assessment.md`, `module-criticality.md` — unread. module-criticality.md is the declared source of truth for verification-coverage-matrix.md:100-103; I could not verify the tier table (notably `path_resolver` = CRITICAL, `fragment` = CRITICAL).
- `.factory/policies.yaml` — read only POL-18's block (lines 307-321). POL-12..POL-17, POL-19 unaudited.
- `prd.md` — read §5, §5b, §6.1-6.3, and changelog excerpts. §1-§4, §7+, and the AMB resolution table (only AMB-042 seen) unread.
- **Interaction gaps I did not get to:** duplicate-slug counting × emoji/stripped-character collisions; the 32-thread HTTP pool × rayon scan pool × DI-001; URL dedup (BC-2.10.009) × per-occurrence file:line reporting × 429 host pausing. All three were on the hunt list and all three need the unread BC-2.10.008/009 and ADR-004.

---

`FINDINGS: 7 critical, 19 major, 8 minor`
`NOVEL_FINDINGS: 34`

---

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 7 |
| MAJOR (HIGH) | 19 |
| MINOR (LOW) | 8 |
| **Total** | **34** |

**Overall Assessment:** block
**Convergence:** findings remain — iterate (novelty is HIGH, not decaying)
**Readiness:** requires revision before Phase 2
