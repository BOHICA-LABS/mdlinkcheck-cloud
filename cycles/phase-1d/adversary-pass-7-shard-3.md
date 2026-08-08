---
document_type: adversarial-review
level: ops
version: "1.0"
status: final
producer: adversary
timestamp: 2026-08-08T00:00:00Z
cycle: phase-1d
pass: 7
shard: 3
frozen_develop_head: f8ee4eb024b8b4a300139ef803d248e8fe40f2fc
frozen_specs_tree: ace1745871122cd1fa2c46cf27c5493cc1083411
frozen_spec_lint_tree: f2392b456c3bd669e3efbe86b3e6eae62e302ed1
severity_vocabulary: "CRITICAL/HIGH/MEDIUM/LOW (single vocabulary per PG-012 ruling)"
findings_total_self_declared: 25
inputs: []
input-hash: "ace1745"
traces_to: STATE.md
---
# Pass 7 — Shard 3: SS-07 (8 BC bodies)

```
scope: "SS-07 (8) = 8 bodies read in full"
files_read_in_full:
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-07/BC-2.07.001.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-07/BC-2.07.002.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-07/BC-2.07.003.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-07/BC-2.07.004.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-07/BC-2.07.005.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-07/BC-2.07.006.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-07/BC-2.07.007.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-07/BC-2.07.008.md
reference_read (to substantiate claims):
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/product-brief.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/capabilities.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/invariants.md (L40-199)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/edge-cases.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/events.md (L70-109)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/prd-supplements/error-taxonomy.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/prd-supplements/test-vectors.md (§2, §10.3, §10.6, §10.7)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/VP-INDEX.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-004-fragment-split.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-008-path-nfc-comparison.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-009-nfc-idempotent.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-023-url-classifier-totality.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-024-path-resolver-trailing-slash.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/api-surface.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/purity-boundary-map.md (L50-129)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/system-overview.md (L100-209)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/bc-module-map.md (L165-209)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/decisions/ADR-006-strict-path-model.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/BC-INDEX.md (SS-07 rows + DI map)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/scripts/spec-lint/check-ec-injectivity.py
findings_total: 25
severity_counts: CRITICAL 5 / HIGH 10 / MEDIUM 7 / LOW 3
phase_2_readiness: NOT SAFE — five CRITICAL defects make the subsystem's core behaviour undecidable or false-green: (a) the fragment percent-decode rule is inverted against L2, (b) two BC verification rows claim formal proofs for properties the VP bodies do not assert, (c) BC-2.07.003 anchors an EC whose registry row asserts the opposite verdict on the flagship KD-004 behaviour, and (d) no contract requires intermediate path components to be case/NFC verified, so the DirIndex model delegates directory-component resolution to APFS and defeats ADR-006's own canonical example. Plus three verdict-totality holes (DI-005) and an unconstrained primary input (DirIndex).
verdict: SS-07 is the highest-risk subsystem in the corpus and cannot be decomposed into implementation stories until the fragment-decode inversion, the two false-green VP rows, the EC-187 verdict inversion, the intermediate-path-component hole, and the three DI-005 totality holes are resolved.
```

---

### P7-S3-001 — BC-2.07.004 forbids percent-decoding the fragment, inverting DI-003, CAP-008, events.md and DEC-005 [CRITICAL]

`BC-2.07.004.md:39-41` (Description): "The fragment component is NOT percent-decoded before slug comparison (DI-003)." `BC-2.07.004.md:50` (Postcondition 4): "The fragment component is used verbatim (not decoded) as the anchor lookup key."

The cited authority states the opposite. `invariants.md:109` (DI-003): "After splitting, **each component is percent-decoded independently**." `capabilities.md:141-142` (CAP-008): "Given a fragment split from a link destination, validate it against the target file's anchor table. **Percent-decode the fragment before comparison.**" `events.md:91-92`: "Fragment processing (all kinds): split at first unescaped `#` in raw destination (DI-003), **then percent-decode the fragment**, then compare against anchor table." `entities.md:83`: "fragment-component | Option\<String\> | after first `#`, **percent-decoded**". `edge-cases.md:127-134` (DEC-005) makes it a mandatory corpus fixture: destination `README.md#caf%C3%A9`, heading `## Café`, slug `café` — "The decoded fragment `café` must match slug `café`. This is the documented root cause of Sphinx bug #13620."

Under BC-2.07.004 PC4 as written, `README.md#caf%C3%A9` is looked up as the literal key `caf%C3%A9`, misses the anchor table, and emits `anchor-not-found` — a false positive on a valid link, i.e. the exact defect class the product exists to prevent, and the exact upstream bug the corpus cites as motivation. BC-2.07.004 also mis-attributes the rule to DI-003, which says the reverse. (Propagation sibling, for the fixer's blast radius: `BC-2.08.001.md:56` carries the same inverted claim — "fragment is used verbatim from source (not decoded)".)

**Predicate:** Grep `-i 'percent-decod|percent decod|not decoded|verbatim'` over `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs` → matches in 5 L2/L3 authorities (`invariants.md:109`, `capabilities.md:141`, `events.md:92`, `entities.md:83`, `edge-cases.md:132`) all requiring fragment decode, versus 2 BC bodies (`ss-07/BC-2.07.004.md:41,50`; `ss-08/BC-2.08.001.md:56`) forbidding it.
**Consequence:** Every percent-encoded cross-file or intra-file anchor produces a false `anchor-not-found`. DEC-005's required corpus fixture fails. Implementer receives two mutually exclusive normative rules with no adjudication.

---

### P7-S3-002 — BC-2.07.001 claims VP-008 (proptest) proves fragment-strip ordering and logical `..` resolution; VP-008 asserts neither [CRITICAL]

`BC-2.07.001.md:70-74` Verification Properties table:
```
| VP-008 | Fragment stripped before path resolution | proptest |
| VP-008 | .. resolution is logical, not filesystem readlink | proptest |
```
`vp-008-path-nfc-comparison.md:44` states VP-008's entire property: "For all path strings `a` and `b` where `nfc_normalize(a) == nfc_normalize(b)` ... `path_resolver::files_match(a, b)` returns `true` ... No case-folding is applied. This is DI-002." The harness at `vp-008-path-nfc-comparison.md:76-121` contains exactly four properties: `vp008_nfc_reflexive`, `vp008_nfc_symmetric`, `vp008_nfd_nfc_pair_matches`, `vp008_case_differs_no_match`. None touches fragment splitting; none touches `.`/`..` segment resolution. `VP-INDEX.md:64` records VP-008 as "path_resolver | proptest | P1 | DI-002", and `VP-INDEX.md:193` records BC-2.07.001's coverage note as "NFC comparison proptest" — VP-INDEX makes no fragment or `..` claim either.

Fragment-split ordering is actually covered by VP-004 (`vp-004-fragment-split.md:37-46`, source_bc BC-2.08.003). Logical `.`/`..` resolution is covered by **no VP at all**, yet BC-2.07.001 marks it "proptest".

**Predicate:** Grep `-i 'lexical|logical|\.\./|dot-dot'` over `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties` → 12 matches; 0 assert path-segment (`.`/`..`) normalization. Grep `-i 'percent|%20|decode'` over the same directory → 9 matches, all about the split point / `%23` non-split; 0 assert decoding.
**Consequence:** False-green. A verification gate reading BC-2.07.001 sees two P1 proptest-proved properties; the harness that will actually be written (VP-008) cannot fail on either. The `..`-resolution property — the trap that makes `docs/guide.md` + `../api/ref.md` correct — ships unverified while the spec asserts it is property-tested. Corroborating drift: `prd.md:448` records BC-2.07.001's verification method as "unit", a third distinct value.

---

### P7-S3-003 — BC-2.07.004 claims VP-004 (Kani P0) proves "%20 in path decoded to space"; VP-004 asserts nothing about percent-decoding [CRITICAL]

`BC-2.07.004.md:72-75`:
```
| VP-004 | Fragment split precedes percent-decode (trap T9) | kani |
| VP-004 | %20 in path decoded to space | kani |
```
`vp-004-fragment-split.md:41-46` enumerates VP-004's three properties: literal `#` splits, `%23` never splits, `split_fragment` is total. The Kani harness (`vp-004-fragment-split.md:62-97`) asserts P1 forward-split, P2 backward-no-split, P3 `%23`-never-splits, P4 exact reconstruction. There is **no decode step anywhere in VP-004** — `split_fragment` returns `(&str, Option<&str>)` borrowed slices of the input (`api-surface.md:77`), so it structurally cannot decode. `VP-INDEX.md:196` states the coverage note as "fragment split handles % before decoding" — which is the split property, not the decode property.

The second row therefore claims a **Kani P0 formal proof** for a property (`%20` → space) that no VP in the corpus asserts.

**Predicate:** Grep `-i 'percent|%20|decode'` over `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties` → 9 matches; zero assert `%20` decoding to a space or any decode-correctness property. `VP-INDEX.md:50` per-tool totals show kani=7 (VP-001..VP-007); none is a decode proof.
**Consequence:** False-green on the P1 percent-encoding contract. TV-025/EC-025 (`test-vectors.md:103`: `[x](docs/my%20file.md)` → `docs/my file.md` exists → clean) is the acceptance behaviour, and it will have no formal or property-based backing while the BC declares Kani coverage. An implementer who omits decoding entirely still passes VP-004.

---

### P7-S3-004 — BC-2.07.003 anchors EC-187 to a registry row whose expected verdict is the opposite (`broken`), citing ADR-008 [CRITICAL]

`BC-2.07.003.md:70` Edge Cases: `| EC-187 | NFC vs NFD normalization in filename |`. `BC-2.07.003.md:79-80` Canonical Test Vectors assign that scenario verdict **`clean`** in both directions:
```
| `cafe\u{301}.md` (NFD) | `café.md` (NFC on disk) | clean | ...
| `café.md` (NFC U+00E9) | `cafe\u{301}.md` (NFD, macOS-created) | clean | ... (see TV-037)
```
The canonical EC registry row says the opposite. `test-vectors.md:422`:
```
| TV-187 | EC-187 | NFC vs NFD normalization in filename (macOS APFS stores filenames in NFD) | BC-2.07.003 | (none) | 1 | broken (file-not-found) on mismatched form | Formerly EC-030; ...; ADR-008: no normalization applied |
```
So the registry asserts exit 1 / `broken (file-not-found)` for the very scenario the BC assigns `clean`, and grounds it in "ADR-008: no normalization applied" — ADR-008 is `ADR-008-slug-clean-room-reimplementation.md` (slug algorithm), not the path model; the governing ADR is ADR-006, whose entire Decision (`ADR-006-strict-path-model.md:49-59`) mandates NFC normalization of both sides. `test-vectors.md:115` (TV-037/EC-037) independently records the same NFC/NFD scenario as exit 0 / `clean`, so TV-187 also contradicts TV-037.

This is a partial-fix propagation failure with a documented origin: `prd.md:624` records "F-002 (BC-2.07.003 NFD→NFC verdict wrong): Postcondition 4 corrected ... NFD link → NFC disk = `clean` (not `broken`). Test vector row 4 corrected; mirror vector added." The BC was corrected; TV-187 was not.

**Predicate:** Grep `EC-(164|186|187|188|189|205|206)\b` over `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/prd-supplements/test-vectors.md` → 7 matches (lines 376, 421-424, 445-446). EC-186, EC-188, EC-189, EC-164, EC-205, EC-206 agree with their citing BCs; EC-187 (line 422) is the sole verdict inversion.
**Consequence:** DEC-004 / FM-007 / KD-004 — the flagship differentiator (`prd.md:65`) — has two authoritative, opposite expected verdicts. A test-writer working from test-vectors.md builds a corpus fixture asserting `broken`; an implementer working from BC-2.07.003 builds `clean`. Whichever lands first, the other gate fails, and the mis-cited ADR-008 will mislead the adjudicator.

---

### P7-S3-005 — No SS-07 contract requires intermediate path components to be case/NFC verified; the DirIndex model delegates directory-component resolution to APFS, defeating ADR-006's own canonical example [CRITICAL]

`BC-2.07.003.md:53-54` (Postconditions 1-2) constrain only the final component: "Both the resolved destination **and all actual directory entries** are NFC-normalized before comparison. Comparison is byte-for-byte exact after NFC normalization (case-sensitive)." `BC-2.07.003.md:51` (Precondition 2) requires only that "The resolved path's **parent directory** is present in `DirIndex`." Nothing requires the *path of that parent directory* to itself have been case/NFC-verified against *its* parent's entry list.

That gap is load-bearing because of how `DirIndex` is keyed and built. `system-overview.md:124-138`: "Collect unique **parent directories of every extracted link destination** ... `fs::read_dir` -> Vec<DirEntryInfo> ... **No recursion: only the immediate parent directory of each link destination is read** (DI-006 one-level bound)." The read key is derived from the *link text*, not from verified on-disk names. On APFS (case-insensitive per `ADR-006:31`), `fs::read_dir("Images")` succeeds and returns the contents of the on-disk `images/`. `path_resolver` then finds key `Images` populated, matches entry `photo.png` exactly, and returns `clean`.

That is precisely the case ADR-006 says must be BROKEN. `ADR-006-strict-path-model.md:98-103`: "**Avoiding macOS APFS case-folding:** We do NOT call `to_lowercase()` ... APFS is case-insensitive, so it will resolve `Images/photo.png` when the actual entry is `images/photo.png` — but the tool must **NOT** accept that as clean. The tool must report it as BROKEN." And `BC-2.07.003.md:64` (Invariant 3) asserts the tool "must not let the host filesystem's case-folding or Unicode normalization behaviour influence link verdicts" — an invariant the contract set cannot deliver for any multi-component destination.

The verification layer cannot catch this either: VP-008's subject is `files_match(a: &str, b: &str)` (`vp-008-path-nfc-comparison.md:44`; `ADR-006:64`), a whole-string comparator. It passes while the pipeline that feeds it a filesystem-resolved directory key is wrong. `purity-boundary-map.md:72-73` explicitly relies on this: "Multi-component resolution (`docs/sub/a.md` from `docs/guide.md`) works because DirIndex is keyed by directory path" — with no per-component verification requirement.

**Predicate:** Grep `-i 'symlink|component|intermediate'`-class check: grep `files_match|resolve_path|EntryKind|DirEntryInfo` over `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-07` → 5 matches (BC-2.07.005:23,53; BC-2.07.006:25,48; BC-2.07.008:21); **zero** postconditions in any of the 8 SS-07 BCs constrain per-component verification, DirIndex key derivation, or the case-correctness of directory components.
**Consequence:** KD-004 (`prd.md:65`, "Case-correct path resolution ... No surveyed tool does this") is unimplementable from the SS-07 contracts for any destination containing a directory component with a case or NFC mismatch — the single most common real-world instance of the trap. The defect is a silent false negative and is invisible to VP-008, i.e. a false-green in the verification architecture as well as a spec hole.

---

### P7-S3-006 — Seven EC IDs in BC-2.07.001/002/004 denote different scenarios than the canonical registry [HIGH]

test-vectors.md is the canonical EC registry (declared at `check-ec-injectivity.py:9`, and cited as such by `BC-2.07.004.md:25`: "EC-034 canonical owner is BC-2.07.008 per test-vectors.md registry"). Seven EC citations in this shard point at registry rows describing unrelated scenarios:

| BC citation | BC's stated scenario | Registry row (test-vectors.md) |
|---|---|---|
| `BC-2.07.001.md:59` EC-023 | `[x](./same-dir.md)` | `:101` EC-023 = `[x](/docs/b.md)` root-relative → git root |
| `BC-2.07.001.md:60` EC-024 | `[x](sub/nested.md)` | `:102` EC-024 = `[x](../../../../etc/passwd)` escape → clean |
| `BC-2.07.001.md:61` EC-025 | `[x](../../above-root.md)` | `:103` EC-025 = `[x](docs/my%20file.md)` percent-decode |
| `BC-2.07.002.md:61` EC-026 | `/docs/api.md` in a git repo | `:104` EC-026 = `[x](docs/my file.md)` raw space |
| `BC-2.07.002.md:62` EC-027 | `/docs/api.md` in a non-git directory | `:105` EC-027 = `[x](<docs/my file.md>)` angle-bracket form |
| `BC-2.07.004.md:60` EC-033 | `[x](My%20File.md)` | `:111` EC-033 = `[x](a.md?raw=1)` query stripped |
| `BC-2.07.004.md:62` EC-035 | `[x](a%20b.md#section)` | `:113` EC-035 = `[x](./a.md)`, `[x](././a.md)`, `[x](dir/../a.md)` normalization |

This is a partial-fix propagation failure: `BC-2.07.003.md:26` and `BC-2.07.004.md:25` record v1.2 "(EC-collision)" sweeps that re-pointed EC-029/030/031/034 to fresh IDs (EC-186..189) — and left these seven untouched in sibling files of the same subsystem.

**Predicate:** Grep `EC-0(22|23|24|25|26|27|29|30|31|33|34|35|72|73)\b` over `/Users/jmagean.../test-vectors.md` → 14 matches (lines 100-113, 157-158). Cross-joined against the 8 SS-07 Edge Cases tables: 7 of the 14 diverge (EC-023, 024, 025, 026, 027, 033, 035); 7 agree (EC-022, 029, 030, 031, 034, 072, 073).
**Consequence:** POLICY 4 mis-anchoring at scale. A test-writer wiring BC-2.07.001's Edge Cases to the corpus generates fixtures for root-relative resolution and `/etc/passwd` traversal under a relative-path BC, and the three genuinely-needed cases (`./same-dir.md`, `sub/nested.md`, `../../above-root.md`) get no fixture at all. Corpus coverage silently drops by 7 cases.

---

### P7-S3-007 — BC-2.07.006 Description contradicts its own Precondition 3 and DD-019/D-012 on `.markdown` and case-sensitivity [HIGH]

`BC-2.07.006.md:37-39` (Description): "When a link destination ... resolves to a file whose extension is NOT `.md` **or `.markdown` (case-insensitive)**, the link is checked for file existence only."

`BC-2.07.006.md:49-51` (Precondition 3): "The file's extension is NOT exactly `.md` (**case-sensitive**). Files with extension `.MD`, `.Md`, **`.markdown`**, `.mdx`, or any other non-`.md` extension **fall into this contract** (D-012: only `.md` files receive anchor resolution)."

These are mutually exclusive for `.markdown`, `.MD` and `.Md`: the Description excludes them from the contract (treating them as Markdown, so anchor resolution IS performed); Precondition 3 includes them (so anchor resolution is skipped). The frozen decision resolves in favour of PC3 — `decisions.md:71` (DD-019 / D-012): "Discovery extension scope: `.md` files only, case-sensitive. ... `.MD`, `.markdown`, and `.mdx` are explicit non-goals with no BC and no test vector." `capabilities.md:56-57` (CAP-001) repeats it. `prd.md:620` records the fix that produced PC3: "BC-2.07.006 Precondition 3 updated" — the Description was not propagated.

**Predicate:** Grep `D-012|DD-019` over `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/decisions.md` → 2 matches (lines 37, 71); DD-019 states `.md` only, case-sensitive, `.markdown` a non-goal.
**Consequence:** An implementer following the Description performs anchor-table lookup on `.markdown` and `.MD` targets. Since D-012 means those files are never discovered or parsed in Pass 1 (`BC-2.01.005`), no anchor table exists for them, so every fragment link into a `.markdown` file yields a false `anchor-not-found` — the reverse of this BC's stated purpose ("prevents false `anchor-not-found` verdicts", `BC-2.07.006.md:43-44`).

---

### P7-S3-008 — BC-2.07.006 and BC-2.07.008 assign conflicting verdicts to the same input state (`[x](logo.png/)`) — DI-005 dual verdict [HIGH]

Take destination `logo.png/` where `logo.png` exists as a regular file.

BC-2.07.008 preconditions (`BC-2.07.008.md:41-42`): "1. A link destination has a trailing `/` after path normalization. 2. The resolved base path (stripping the trailing `/`) exists as a **regular file**." → satisfied. Postconditions (`:45-46`): "verdict is `broken`. The reason code is `file-not-found`."

BC-2.07.006 preconditions (`BC-2.07.006.md:47-51`): "1. A link destination's path component has been resolved to an absolute filesystem path. 2. The resolved path exists as a regular file ... via `EntryKind::File` ... 3. The file's extension is NOT exactly `.md`." → all satisfied (`.png` ≠ `.md`). Postcondition (`:54`): "Verdict: `clean`."

Neither BC excludes the other. BC-2.07.008's Related BCs (`:86-88`) lists BC-2.07.005, .001, .007 — not .006. BC-2.07.006's Related BCs (`:100-102`) lists BC-2.07.005, BC-2.08.001, BC-2.08.002 — not .008. By contrast the analogous BC-2.07.005/BC-2.07.008 overlap *is* explicitly reconciled (`BC-2.07.008.md:62,69` EC-034c defers to BC-2.07.005). Only the non-`.md` case was left unreconciled.

**Predicate:** Grep `^\| Brief Requirement \|`-adjacent structural check: grep `broken-symlink` over `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts` → 6 matches, 0 in ss-07; grep `EntryKind` over ss-07 → 5 matches (BC-2.07.005:23,53; BC-2.07.006:25,48; BC-2.07.008:21), none of which carves out the trailing-slash-on-non-`.md`-file case.
**Consequence:** Direct DI-005 violation ("Each extracted link is assigned exactly one verdict ... A link cannot have two verdicts", `invariants.md:131-132`). Verdict for `[x](assets/logo.png/)` is order-of-evaluation dependent: check the extension routing first → exit 0; check the trailing slash first → exit 1. VP-024 (`vp-024-path-resolver-trailing-slash.md:41-44`) asserts `Broken(FileNotFound)`, so an implementation that satisfies BC-2.07.006 fails VP-024 and vice versa.

---

### P7-S3-009 — BC-2.07.001 and BC-2.07.002 preconditions both admit `/`-prefixed destinations; BC-2.07.001's `source_dir.join()` yields the filesystem root, not the git root [HIGH]

`BC-2.07.001.md:41` (Precondition 1): "A link destination has been classified as `relative-file` or `cross-file-anchor` (not `anchor-only`, `external-http`, or `non-http`)." There is no exclusion for destinations beginning with `/`, and no `root-relative` link kind exists in the closed classification set — `capabilities.md:76-78` (CAP-003) enumerates exactly six kinds: `relative-file`, `anchor-only`, `cross-file-anchor`, `external-http`, `non-http`, `undefined-reference`; `events.md:82-89` repeats the same six. A root-relative destination `/docs/api.md` is therefore classified `relative-file`, satisfying BC-2.07.001 PC1.

`BC-2.07.002.md:43` (Precondition 1) also admits it: "A link destination starts with `/` (root-relative)."

The two BCs then prescribe different resolutions:
- `BC-2.07.001.md:45`: "The resolved path = source_dir.join(destination_path).canonicalize_logical()."
- `BC-2.07.002.md:47`: "The resolved path = git_repo_root.join(destination.strip_prefix('/').unwrap())."

Worse, BC-2.07.001's formula is silently wrong in Rust: `Path::join` with an absolute argument *replaces* the base, so `source_dir.join("/docs/api.md")` == `/docs/api.md` — the filesystem root, not the git root and not the source dir. `BC-2.07.001.md:87` compounds the confusion by labelling the relationship "BC-2.07.002 — composes with (root-relative links use git root)"; the relationship is mutually exclusive, not compositional.

**Predicate:** Grep `relative-file` over `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec` → matches at `capabilities.md:78` and `events.md:84`; neither enumerates a `root-relative` kind, so the 6-kind set is closed and BC-2.07.001 PC1 necessarily admits `/`-prefixed destinations.
**Consequence:** DI-005 dual verdict for every root-relative link, plus a concrete resolution bug. An implementer coding BC-2.07.001 literally resolves `[x](/docs/api.md)` against `/` and reports `file-not-found` for a valid repo-root link — TV-023/EC-023 (`test-vectors.md:101`, exit 0 / clean) fails. BC-2.07.001 needs an explicit "destination does not begin with `/`" precondition.

---

### P7-S3-010 — No SS-07 BC covers symlink `EntryKind`s or the `broken-symlink` reason code that `path_resolver` is specified to produce [HIGH]

`purity-boundary-map.md:68-72` assigns the symlink verdicts to `path_resolver` (SS-07): "Each `DirEntryInfo` carries the entry name and an `EntryKind` enum (`File`, `Dir`, `Symlink { dangling: bool }`), so **path_resolver** can distinguish a directory target from a file target and a dangling symlink from a healthy one — **producing `target-is-directory` and `broken-symlink` reason codes correctly**." `broken-symlink` is in the closed 13-code set (`error-taxonomy.md:66,102`) and `test-vectors.md:116` (TV-038/EC-038) makes it an acceptance requirement: `[x](link.md)` where `link.md` is a dangling symlink → exit 1 / `broken-symlink`.

No SS-07 contract specifies it. The only symlink mention in the whole subsystem is a parenthetical in a precondition (`BC-2.07.006.md:48`, "or a file symlink that resolves to a regular file ... `EntryKind::Symlink { dangling: false }`"), and that BC applies only to non-`.md` extensions (`:49`). Consequently:
- `EntryKind::Symlink { dangling: true }` → no SS-07 BC assigns any verdict. The reason code is specified only in `BC-2.01.006.md:45` (SS-01, module `scanner` — a discovery BC, not a resolution BC).
- `EntryKind::Symlink { dangling: false }` on a `.md` target → BC-2.07.006 PC3 excludes it (`.md`), BC-2.07.005 PC2 requires `EntryKind::Dir`, BC-2.07.008 PC2 requires "regular file". No SS-07 BC assigns a verdict, and BC-2.08.002 PC5-PC6 (`BC-2.08.002.md:66-68`) requires the path to have been established as "a **`.md` file**", which `EntryKind::Symlink` is not.

**Predicate:** Grep `-i symlink` over `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-07` → **1** match (`BC-2.07.006.md:48`). Grep `broken-symlink` over `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts` → 6 matches, distributed ss-01 (5) + ss-05 (1), **0** in ss-07.
**Consequence:** DI-005 "no verdict" hole for two of the three `EntryKind` variants. The single most common real symlink case — a valid `.md` symlink target — falls through every SS-07 and SS-08 precondition, so the implementer must invent the rule. TV-038 has no BC backing it in the subsystem that owns the code.

---

### P7-S3-011 — `canonicalize_logical()` is a phantom symbol in a normative postcondition; no SS-07 BC names the real `path_resolver` entry point [HIGH]

`BC-2.07.001.md:45` (Postcondition 1): "The resolved path = source_dir.join(destination_path).**canonicalize_logical()**."

No such function exists anywhere in the corpus. The real path_resolver surface is `resolve_path(dest: &str, src_dir: &Path, index: &DirIndex) -> PathVerdict` (`api-surface.md:89`; `purity-boundary-map.md:58`), aliased as `resolve(...)` in `module-decomposition.md:53`, with `files_match(a: &str, b: &str) -> bool` as the comparison core (`ADR-006-strict-path-model.md:64`). None of those three names appears in any SS-07 BC. The BC's only function-level symbol is the invented one.

The invented name also carries a purity hazard: it reads as a canonicalization primitive, and `BC-2.07.001.md:37` reinforces it ("The result is then canonicalized"). Canonicalization is explicitly forbidden — `system-overview.md:133-135`: "Deduplication key: NFC-normalized, lexically-normalized (`.`/`..` collapsed), **NON-canonicalized (no `fs::canonicalize` — canonicalize case-folds on macOS APFS, violating D-006 case-sensitivity and DI-001 determinism)**"; `invariants.md:250-251` repeats the prohibition. BC-2.07.001's Postcondition 2 and Invariant 2 (`:46,52`) do say resolution is logical, so the BC contradicts its own Description and PC1 wording.

**Predicate:** Grep `canonicalize_logical` over `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs` → **1** match, `behavioral-contracts/ss-07/BC-2.07.001.md:45`. Grep `-i canonicaliz` over the same tree → 12 matches; the two in `system-overview.md:134` and `invariants.md:250` forbid `fs::canonicalize`; none defines `canonicalize_logical`. Grep `files_match|resolve_path` over `ss-07/` → 0 matches.
**Consequence:** The head P0 contract of the subsystem specifies its central operation via an undefined symbol whose name suggests the one filesystem call the architecture prohibits. An implementer reaching for `Path::canonicalize()` reintroduces APFS case-folding and breaks DI-002/DI-001 — the exact failure ADR-006 was written to prevent. There are 0 ```rust fences in SS-07 (predicate: grep `^\`\`\`` over ss-07 → 0 matches), so no fence-level cross-check would have caught this.

---

### P7-S3-012 — `DirIndex`, the subsystem's primary input, is constrained by no behavioral contract [HIGH]

Five of the eight SS-07 BCs make `DirIndex` population a precondition or postcondition and each defers to "Pass 1.5a": `BC-2.07.002.md:51` ("The parent directory of the resolved path is present in `DirIndex` before `path_resolver` is called. Pass 1.5a populates `DirIndex` for every extracted link destination"), `BC-2.07.003.md:51`, `BC-2.07.005.md:53`, `BC-2.07.006.md:48`. `BC-2.07.003.md:51` goes further and makes DirIndex the *definition* of a precondition: "In the pure-core model, `path_resolver` performs no I/O; 'readable' is operationalized as 'present in `DirIndex`.'"

Pass 1.5a exists only in architecture prose and a domain-invariant aside. No BC anywhere in the corpus has a postcondition constraining DirIndex construction — key form, scope, deduplication, or the one-level bound. The nearest BC, BC-2.05.001 (two-pass design), mentions DirIndex only as something Pass 2 consumes (`BC-2.05.001.md:47`: "Pass 2 (parallel): resolves all links against the complete AnchorIndex and DirIndex").

**Predicate:** Grep `Pass 1\.5a` over `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs` → 10 matches: `system-overview.md:19,123,159`, `invariants.md:246,254`, `canonical-facts.toml:268`, and 4 SS-07 BC changelog/precondition lines (BC-2.07.002:24,51; BC-2.07.003:24,51; BC-2.07.005:23; BC-2.07.006:25). Grep `DirIndex` over `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts` → matches in ss-07 (10), ss-05 (1, consumption only), ss-14 (1, negative assertion). **Zero** BC postconditions specify DirIndex construction.
**Consequence:** The entire correctness of SS-07 is conditional on a data product with no contract, no acceptance criteria, no BC-to-story trace, and no VP. Phase-2 story decomposition will produce SS-07 stories whose preconditions cannot be satisfied by any story in the plan, because the work that builds their input is not attached to any contract. This is also the mechanism behind P7-S3-005: with no contract on DirIndex key derivation, nothing forbids keying it on unverified link text.

---

### P7-S3-013 — Brief Requirement mis-anchor in 5 of 8 SS-07 BCs; prd.md records a prior "fix" that moved BC-2.07.005 in the wrong direction [HIGH]

`prd.md:448-455` is the authoritative BC traceability table and assigns **R2a** to all eight SS-07 BCs. Five BC bodies contradict it:

| BC | Body value | prd.md |
|---|---|---|
| `BC-2.07.001.md:82` | `R5, R6, T7` | `:448` R2a |
| `BC-2.07.002.md:82` | `R5, AMB-017` | `:449` R2a |
| `BC-2.07.004.md:83` | `R5, R6, T9` | `:451` R2a |
| `BC-2.07.005.md:95` | `R5, AMB-024` | `:452` R2a |
| `BC-2.07.006.md:95` | `R5, EC-072, EC-073` | `:453` R2a |

The cited requirements are semantically unrelated to path resolution. `product-brief.md:46-47` R5 = "`--ignore <glob>` (repeatable) excludes files; `--allow <url-prefix>` (repeatable) exempts external URLs from checking". `product-brief.md:48-49` R6 = output format ("human-readable text ... `--format json`"). `product-brief.md:38` R2a = "Relative file links (`[x](docs/a.md)`, `[x](../b.md)`) — target must exist" — the actual grounding, and the one `capabilities.md:135` gives CAP-007. BC-2.07.001's `T7` is worse: `test-vectors.md:301` records "T7: Nested brackets", a parser trap with no relation to path resolution (BC-2.07.004's `T9` is correct — the percent-decode ordering trap).

The regression is documented: `prd.md:816` records "BC-2.07.005: brief requirement **corrected R2a → R5**" while `prd.md:452` still says R2a. A prior remediation moved the value away from truth and left the traceability table unpatched. `prd.md:715` shows the correct direction was applied elsewhere ("BC-2.11.002 Brief Requirement corrected from R6 to R5"), so the fix pattern exists but was applied inconsistently across the same layer.

**Predicate:** Grep `^\| Brief Requirement \|` over `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-07` → 8 matches; R2a in 3 (BC-2.07.003:94, .007:79, .008:82), R5 in 5, R6 in 2. Grep `\bT7\b` over `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs` → 3 matches: `test-vectors.md:301` ("T7: Nested brackets"), `gene-transfusion-assessment.md:181,229` (nested brackets), plus `BC-2.07.001.md:82`. (AMB-017 and AMB-024 DO resolve — `planning/brief-validation.md:232,239` — and are semantically correct; only the R5/R6/T7 components are mis-anchored.)
**Consequence:** POLICY 4/5 mis-anchoring, and it blocks convergence. Requirements-traceability tooling (`gen-rtm.py`) will report R5 as satisfied by path-resolution contracts and R2a as covered by only 3 of 8, inverting the coverage picture for the product's primary functional requirement.

---

### P7-S3-014 — BC-2.07.001's test vector asserts "path escapes root → broken", contradicting the registry ruling that relative resolution has no scan-root boundary [HIGH]

`BC-2.07.001.md:68` Canonical Test Vectors:
```
| `docs/guide.md` | `../../escape.md` | path escapes root | broken (file-not-found) |
```
The "Expected Resolved" cell states the cause as *escaping the root*, and the verdict as broken. The registry rules the opposite. `test-vectors.md:102` (TV-024/EC-024): "`docs/a.md` | `[x](../../../../etc/passwd)` | `/etc/passwd` exists | **0** | **clean** | **Relative path resolution has no scan-root boundary.** The resolved absolute path `/etc/passwd` exists → clean. **No path-above-scan-root enforcement for relative links** (that applies only to root-relative links T16). (Verdict chosen: clean — no policy prevents relative traversal outside root.)"

Under the registry ruling, `../../escape.md` is broken only if the resolved path does not exist — the escape is irrelevant. The BC's row states the escape as the reason.

**Predicate:** Grep `scan-root boundary|above-root|escapes root` over `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs` → `test-vectors.md:102` (no boundary for relative links), `invariants.md:164` (scan-root boundary is a *source-exclusion* mechanism, not a resolution rule), and `BC-2.07.001.md:61,68`. Zero authorities support a resolution-time root-boundary check for relative links.
**Consequence:** An implementer reads a normative test vector as licence to implement a scan-root containment check on relative destinations. That check makes TV-024 fail (exit 1 instead of 0) and introduces a false-positive class on every legitimate `../../shared/doc.md` link in a monorepo — the false-positive category the brief's Problem statement (`product-brief.md:27-29`) names as the reason the tool exists.

---

### P7-S3-015 — No SS-07 contract specifies query-string (`?`) handling, which an authoritative test vector requires [HIGH]

`test-vectors.md:111` (TV-033/EC-033): "`a.md` | `[x](a.md?raw=1)` | `a.md` exists | **0** | **clean** | **Query stripped before resolution**."

Nothing in SS-07 specifies this. `BC-2.07.001.md:47` and `BC-2.07.002.md:50` strip only the fragment (DI-003). `BC-2.07.004.md:46-50` covers percent-encoding and fragment ordering; `?` is absent. `capabilities.md:128-135` (CAP-007) is silent. DI-003 (`invariants.md:105-113`) defines only the `#` split point, so the ordering question `a.md?raw=1#frag` — is `?` stripped before or after the `#` split, and is the `?`-suffix part of the path key for `DirIndex` lookup — is unspecified.

**Predicate:** Grep `-i 'quer(y|ies)|\?raw=1'` over `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs` → 9 matches: `test-vectors.md:111` (the requirement), `gene-transfusion-assessment.md:209` and `ss-10/BC-2.10.009.md:47,59` (external-URL memoization keys — explicitly *keep* the query), and 5 unrelated `vp-025` prose hits. **Zero** matches in `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-07/`.
**Consequence:** `[x](a.md?raw=1)` — the standard GitHub raw-content link idiom — resolves to a nonexistent path `a.md?raw=1` and reports a false `file-not-found`, failing TV-033. Because BC-2.10.009 explicitly preserves the query for URL dedup, an implementer has an active counter-precedent pushing them toward *not* stripping it for file paths.

---

### P7-S3-016 — `check-ec-injectivity.py` structurally cannot detect BC-vs-registry EC mismatch for 2-column Edge Cases tables [MEDIUM]

The only checker for EC semantics is blind to both defect shapes reported in P7-S3-004 and P7-S3-006, by design and by table geometry.

Description mismatch: `check-ec-injectivity.py:191-194` — "Description collision: **across BC files** ... BC descriptions are expected paraphrases of TV descriptions ..., so **BC-vs-TV is skipped**." The guard is `if len(bc_occs) > 1:` (line 194). Each of EC-023/024/025/026/027/033/035 appears in exactly one BC file plus test-vectors.md, so `len(bc_occs) == 1` and no description comparison ever runs.

Verdict mismatch: `check-ec-injectivity.py:217-222` compares BC-vs-TV verdicts, but only "when BOTH have explicit verdicts", and skips when `not bc_verdict_raw.strip()`. `extract_ec_rows` (`:126-127`) takes the verdict from the *second* remaining cell of the EC row. The Edge Cases tables in BC-2.07.001 (`:56-61`), BC-2.07.002 (`:59-62`), BC-2.07.003 (`:66-71`) and BC-2.07.004 (`:57-62`) are all 2-column (`| EC | Description |`), so `verdict_raw` is always `""` and every verdict comparison is skipped. BC verdicts live in a separate "Canonical Test Vectors" table whose rows do not begin with an EC ID, so `EC_TOKEN_RE.fullmatch(cells[0])` (`:119`) rejects them.

The job's success line (`:258-261`, "Check passed: {total_ec_ids} EC IDs validated — all injective") is a runtime-computed count, satisfying POLICY 11's letter, but the count measures IDs *scanned*, not scenario-consistency *asserted* — for 2-column BC tables the assertion set is empty.

**Predicate:** Read of `/Users/jmagady/Dev/mdlinkcheck-cloud/scripts/spec-lint/check-ec-injectivity.py` lines 101-129 (row extraction), 191-194 (BC-vs-TV skip), 217-222 (empty-verdict skip). Cross-check: 4 of 8 SS-07 Edge Cases tables are 2-column (BC-2.07.001, .002, .003, .004); 4 are 2-column with no verdict column (BC-2.07.005:71-75, .006:68-73, .007:57-60, .008:58-62) — i.e. 8 of 8 SS-07 BC EC tables produce `verdict_raw == ""`.
**Consequence:** POLICY 4 EC anchoring is unenforced for this corpus's actual table shape, which is why 7 mis-anchored ECs and 1 inverted verdict survived to pass 7. Either the checker must compare BC descriptions against the TV row for single-BC ECs, or the BC template must carry a verdict column in the Edge Cases table.
**Tag:** [process-gap]

---

### P7-S3-017 — Three-way divergence in the DI mapping: BC-2.07.005 has no `L2 Domain Invariants` row; BC-2.07.006's is `—` while BC-INDEX names it the DI-005 enforcer [MEDIUM]

POLICY 2 requires every DI-NNN to be cited by ≥1 BC and the enforcer relationship to be bidirectional. Three inconsistencies inside this shard:

1. `BC-2.07.005.md:90-96` — the Traceability table has L2 Capability, Capability Anchor Justification, Brief Requirement and Architecture Module rows, and **no `L2 Domain Invariants` row at all**. It is the only SS-07 BC missing the field. Its subject (assigning exactly one of `clean` / `broken(target-is-directory)` on a fragment discriminator) is precisely DI-005 territory.
2. `BC-2.07.006.md:94` declares `| L2 Domain Invariants | — |`, while `BC-INDEX.md:210` names BC-2.07.006 as an enforcer of DI-005: "`| DI-005 | Each link receives exactly one verdict | BC-2.03.001, BC-2.03.003, BC-2.07.006 |`" — a scope mismatch in both directions.
3. `BC-2.07.007.md:78` and `BC-2.07.008.md:81` both cite DI-005, but neither appears in BC-INDEX's DI-005 row. Likewise `BC-2.07.001.md:81` and `BC-2.07.002.md:81` cite DI-002/DI-003 but are absent from BC-INDEX's DI-002 row (`:207`, lists only BC-2.07.003, BC-2.07.004), and BC-2.07.002 is absent from the DI-003 row (`:208`). `prd.md:449` and `:451` give yet a third mapping (BC-2.07.002 = DI-002 only; BC-2.07.004 = DI-003 only), disagreeing with both the bodies and BC-INDEX.

**Predicate:** Grep `L2 Domain Invariants` over `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-07` → **7** matches across 7 files (BC-2.07.001:81, .002:81, .003:93, .004:82, .006:94, .007:78, .008:81); BC-2.07.005 has **0**.
**Consequence:** POLICY 2 is unenforceable from any single source. `gen-bc-traceability.py` and `gen-rtm.py` will emit a DI-to-BC map that matches neither BC-INDEX nor the bodies, and the BC that most needs DI-005 (BC-2.07.005, the verdict-discriminator contract) carries no invariant trace at all.

---

### P7-S3-018 — BC-2.07.007's capability anchor CAP-007 is semantically wrong; the document's own Architecture Module places it in SS-09 [MEDIUM]

`BC-2.07.007.md` frontmatter (`:16-19`) declares `subsystem: "SS-07"`, `capability: "CAP-007"`. Its Traceability rows (`:76-77`) claim CAP-007 twice, with the gloss "empty destination rejected at classification, before resolution" and "this BC constrains the path resolution entry point". Its Architecture Module row (`:80`) contradicts both: "`url_classifier.rs` (**SS-09**, pure core, HIGH tier) — ADR-006, ADR-007; VP-023 totality proptest ... (filed in SS-07 because observable during path resolution; classification boundary belongs to url_classifier)".

CAP-007's text (`capabilities.md:128-135`) contains nothing about empty destinations, classification, or `malformed-url`; it is entirely about resolving relative and root-relative destinations. The capability that owns this behaviour is CAP-009 (`capabilities.md:155-163`): "validate it against the WHATWG URL grammar without network access. **Syntax failure produces a `broken` verdict with reason `malformed-url`** and counts toward exit 1." `error-taxonomy.md:155` also maps `malformed-url` jointly to "BC-2.09.001, BC-2.07.007". The BC's own Postcondition 4 (`:48-49`) — "`path_resolver.rs` and `anchor_resolver.rs` are NOT called — the failure is at the classification/validation stage" — confirms no path resolution occurs, contradicting the "constrains the path resolution entry point" justification.

The SS-07 *filing* is ratified by `bc-module-map.md:185,191-195` (Primary Module `url_classifier`, with an explicit ownership note), so the subsystem placement is a deliberate decision. The **capability anchor** is not covered by that ruling and remains semantically wrong.

**Predicate:** Grep `malformed-url` over `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/capabilities.md` → 1 match, `:160`, inside CAP-009. Zero matches inside CAP-007's section (`:128-135`).
**Consequence:** POLICY 4 mis-anchor. CAP-009's coverage appears to be carried by one BC (BC-2.09.001) when two contracts implement it, and an SS-07 story generated from CAP-007 will pull `url_classifier` totality work across a subsystem boundary. Correct value: CAP-009, with the SS-07 filing note retained.

---

### P7-S3-019 — BC-2.07.003's VP-009 row misdescribes VP-009: idempotency is asserted, "NFC comparison is applied" is not [MEDIUM]

`BC-2.07.003.md:86`: `| VP-009 | NFC-normalized comparison is applied | proptest |`.

VP-009 asserts a pure mathematical property of the normalizer, not that the comparison path uses it. `vp-009-nfc-idempotent.md:37` (H1): "NFC Normalization Is Idempotent — nfc(nfc(s)) == nfc(s)". `:41`: "For all path strings `s`, applying NFC normalization twice produces the same result as applying it once". The harness (`:59-67`) is a single property `vp009_nfc_idempotent` over `nfc_normalize`. An implementation of `files_match` that skips NFC entirely still passes VP-009 in full. The property "NFC normalization is actually applied to both sides" belongs to VP-008 property 3 (`vp-008-path-nfc-comparison.md:95-104`: "a byte-equality implementation would fail this test") — already claimed on the preceding row.

**Predicate:** Read of `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-009-nfc-idempotent.md` lines 37-67: 1 property, subject `nfc_normalize`, no reference to `files_match` or to comparison behaviour.
**Consequence:** Overstated coverage. Under review, "VP-009 — NFC comparison is applied — proptest" reads as an independent guarantee, so the row appears to double-cover what only VP-008 property 3 falsifies. Correct row text: "NFC normalization is idempotent — nfc(nfc(s)) == nfc(s)".

---

### P7-S3-020 — BC-2.07.008's `version` field (1.1) is below its own changelog's newest entry (v1.5) [MEDIUM]

`BC-2.07.008.md:4`: `version: "1.1"`. `BC-2.07.008.md:20-22`:
```
modified:
  - v1.5: "Fix 3 (VP elevation): replaced test-sufficient with VP-024 per VP-INDEX v1.2 architect decision. ..."
  - "v1.1: (INC-MAP) Architecture Module field added per bc-module-map.md (architect, Phase 1b)"
```
The v1.5 change *did* land in the body (`:74` carries the VP-024 row), so the content is correct and the version field is stale — the file records itself as being at the pre-v1.5 revision. Its sibling BC-2.07.007, which received the same "Fix 3 (VP elevation)" treatment (`BC-2.07.007.md:22`), correctly reads `version: "1.6"` (`:4`).

**Predicate:** Grep `^version:` across the 8 SS-07 BCs vs their newest `modified` entry: BC-2.07.001 1.2/v1.2 ✓, .002 1.4/v1.3 (also drifted, one minor), .003 1.5/v1.5 ✓, .004 1.3/v1.3 ✓, .005 1.4/v1.3 (drifted), .006 1.4/v1.3 (drifted), .007 1.6/v1.6 ✓, **.008 1.1/v1.5 (regressed by 4 minors)**. 1 of 8 regressed below its changelog; 3 of 8 are ahead of their newest entry.
**Consequence:** POLICY 1 append-only/monotonic versioning is broken. Any tooling or reviewer that diffs against a recorded version, or that decides whether a fix has landed by comparing version fields, reaches the wrong conclusion for BC-2.07.008 — including the partial-fix-propagation audit this pass is required to perform.

---

### P7-S3-021 — No SS-07 BC covers the non-UTF-8 directory-entry verdict rule that ADR-006 specifies normatively [MEDIUM]

`ADR-006-strict-path-model.md:111-128` ("Non-UTF-8 Filename Verdict") is a normative section with three distinct behavioural requirements: the entry "is silently skipped in the comparison pool for that directory"; "Any link whose destination would match that entry produces **`broken` (reason: `file-not-found`)**"; "An additional diagnostic line is emitted to stderr (`[warn] non-UTF-8 directory entry skipped: <parent-dir>`)"; and "The exit code is **not** raised to 2 solely by a non-UTF-8 entry skipped in a directory listing".

None of the three appears in any SS-07 BC. The condition is reachable through the declared types: `DirEntryInfo { pub name: OsString, ... }` (`api-surface.md:92`; `purity-boundary-map.md:102`) carries an `OsString`, while the comparator takes `&str` (`ADR-006:64`), so the UTF-8 conversion decision sits exactly on the SS-07 seam. ADR-006:68-69 assigns the conversion to "`scanner`", which also conflicts with `purity-boundary-map.md:83` and `ADR-006:73-76` assigning Pass 1.5 directory reads to `app`.

**Predicate:** Grep `UTF-8|OsStr|OsString` over `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-07` → **0** matches across 0 files.
**Consequence:** A normative exit-code carve-out (non-UTF-8 entry must NOT raise exit 2) exists only in an ADR, so it has no BC, no acceptance criterion, no test vector and no VP. An implementer who treats the failed `OsString → &str` conversion as an I/O error raises exit 2 and breaks the ADR's explicit rule and DI-011's precedence semantics, with no gate to catch it.

---

### P7-S3-022 — EC-031b, EC-034b and EC-034c are unregistered EC IDs, and two duplicate already-registered scenarios [MEDIUM]

`BC-2.07.007.md:60`: `| EC-031b | [x]( ) whitespace-only (see TV-032, EC-032) |`
`BC-2.07.008.md:61`: `| EC-034b | [x](a.md/) where a.md does NOT exist |`
`BC-2.07.008.md:62`: `| EC-034c | [x](docs/) where docs IS a directory |`

None of the three exists in the canonical EC registry (test-vectors.md). EC-031b is a self-defeating allocation: its own description points at the registry row that already owns the scenario (`test-vectors.md:110`, TV-032/EC-032 = `[x](   )` → broken, whitespace-only destination malformed), so the new ID is a redundant alias. EC-034c likewise duplicates EC-029/EC-030 (`test-vectors.md:107-108`, `[x](docs/)` and `[x](docs)` → clean). EC-034b has no registry counterpart at all.

These are conforming-shape IDs under the shared grammar (`check-ec-injectivity.py:107-108`, `EC_TOKEN_RE` = `EC-\d{1,4}[a-z]?`) and the checker docstring treats sub-lettered variants as "distinct IDs" (`:14`), so they will be scanned as first-class unregistered IDs rather than folded into their bases.

**Predicate:** Grep `EC-031b|EC-034b|EC-034c` over `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs` → **3** matches, all inside the two BC bodies (`ss-07/BC-2.07.007.md:60`, `ss-07/BC-2.07.008.md:61,62`); **0** registry entries in `prd-supplements/test-vectors.md`.
**Consequence:** POLICY 16 — three Traceability/edge-case IDs resolve to nothing. Corpus generation from `gen-ec-registry.py` will not produce fixtures for EC-034b (the "trailing slash on a nonexistent path" case, which is the only place `BC-2.07.008.md:55` Invariant 3 is exercised), and the two duplicate aliases fragment the injectivity map for EC-032/EC-029/EC-030.

---

### P7-S3-023 — BC-2.07.005 and BC-2.07.006 declare `test-sufficient` proof method "unit test" while VP-INDEX records "covered by acceptance corpus" [LOW]

`BC-2.07.005.md:87-88`: both rows `| test-sufficient | ... | unit test |`. `BC-2.07.006.md:86-87`: `unit test (routing verification)` and `unit test (EC-072, EC-073)`. `VP-INDEX.md:197-198` — the POLICY 9 authority — records both as "test-sufficient | **covered by acceptance corpus**". `VP-INDEX.md:16` sets `unit_count: 1` and `:74` identifies the sole unit-method VP as VP-018 (slug worked examples), so "unit test" is not a method the index attributes to path_resolver at all (`:114`: path_resolver = 3 proptest, 0 unit).

**Predicate:** Grep `^\| test-sufficient` over `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-07` → 6 rows: BC-2.07.002:73-74 ("integration test", consistent with "acceptance corpus"), BC-2.07.005:87-88 and BC-2.07.006:86-87 ("unit test", divergent). `VP-INDEX.md:121` Totals row: unit = 1.
**Consequence:** Test-writer ambiguity about the vehicle (in-crate `#[test]` vs acceptance-corpus fixture) for four contract behaviours, and a reader tallying declared unit methods from BC bodies gets 5 where VP-INDEX declares 1.

---

### P7-S3-024 — BC-2.07.007 and BC-2.07.008 changelog entries are YAML mappings, not strings, unlike every sibling entry [LOW]

`BC-2.07.007.md:22`: `  - v1.5: "Fix 3 (VP elevation): replaced test-sufficient with VP-023 ..."`
`BC-2.07.008.md:21`: `  - v1.5: "Fix 3 (VP elevation): replaced test-sufficient with VP-024 ..."`

Every other `modified` item in the shard is a quoted scalar — e.g. `BC-2.07.007.md:21` (`- "v1.6: (WS-4/Shard-C) ..."`), `BC-2.07.008.md:22` (`- "v1.1: (INC-MAP) ..."`). The unquoted-key form parses as a single-key mapping `{v1.5: "..."}` rather than a string, so a single `modified:` list contains two different item types.

**Predicate:** Grep `^  - v[0-9]` over `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-07` → 2 matches (BC-2.07.007.md:22, BC-2.07.008.md:21); all remaining `modified` items across the 8 files use the `- "vN.N: ..."` quoted-string form.
**Consequence:** Any changelog consumer that does `for entry in fm["modified"]: entry.startswith("v")` raises `AttributeError` on a dict, or silently skips the entry — which is the entry recording the VP elevation for both BCs.

---

### P7-S3-025 — BC-2.07.001's Canonical Test Vectors "Verdict" column contains non-verdict values in 2 of 3 rows [LOW]

`BC-2.07.001.md:64-68`:
```
| Source | Destination | Expected Resolved | Verdict |
| `docs/guide.md` | `../api/ref.md` | `api/ref.md` | file existence check |
| `docs/guide.md` | `./same.md` | `docs/same.md` | file existence check |
| `docs/guide.md` | `../../escape.md` | path escapes root | broken (file-not-found) |
```
"file existence check" is a pipeline step, not a member of the closed verdict set `{clean, broken, indeterminate}` (`error-taxonomy.md:32-36`; DI-005 at `invariants.md:131-133`). The expected verdict for both rows is `clean`.

**Predicate:** Grep `file existence check` over `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts` → 2 matches, both `ss-07/BC-2.07.001.md:66-67`; both sit under a column headed `Verdict`.
**Consequence:** The head contract of SS-07 supplies no expected verdict for its two happy-path vectors, so those two rows cannot be mechanically converted into acceptance assertions, and POLICY 12 verdict/exit-code consistency checking has nothing to compare against for the P0 relative-resolution path.

---

## Novelty Assessment

Novelty: **HIGH**. The findings are not refinements — five are CRITICAL and four of those five would be invisible to every existing gate:

- P7-S3-005 (intermediate path components) is a *model-level* hole: VP-008 tests `files_match(&str, &str)` and cannot observe that the DirIndex key handed to it was itself resolved case-insensitively by APFS. It falsifies ADR-006's own worked example (`Images/photo.png`) and the product's flagship differentiator KD-004. No amount of BC-body proofreading surfaces it; it requires joining `system-overview.md:124-138` (key derivation) against `BC-2.07.003.md:51-54` (comparison scope) against `ADR-006:98-103` (the promised behaviour).
- P7-S3-001 (fragment decode inverted) is a five-authorities-versus-two-BCs contradiction on the behaviour the corpus itself names as the root cause of Sphinx #13620.
- P7-S3-002 and P7-S3-003 are textbook false-greens: BC Property columns describing properties the named VP bodies provably do not assert, one of them claiming Kani P0.
- P7-S3-016 supplies the mechanism explaining why P7-S3-004 and P7-S3-006 survived six prior passes: `check-ec-injectivity.py` skips BC-vs-registry description comparison by design (line 193) and skips verdict comparison whenever the BC Edge Cases table is 2-column — which is 8 of 8 SS-07 tables.

Three findings are *partial-fix regressions* where a documented remediation created or left the defect: P7-S3-004 (BC fixed per `prd.md:624`, TV-187 not propagated), P7-S3-006 (v1.2 EC-collision sweep fixed 4 IDs, left 7 in sibling files), P7-S3-013 (`prd.md:816` records a correction applied in the wrong direction while `prd.md:452` retains the right value).

Self-validation: 3 iterations run. Dropped during refinement: a report on `fragment.rs (SS-07)` vs `(SS-08)` labelling (ARCH-INDEX.md:70-71 lists `fragment` under both subsystems — not a defect); a report on dangling AMB-017/AMB-024 (both resolve at `planning/brief-validation.md:232,239` and are semantically correct); a report on `vp-024`'s Coverage cell overclaiming Symlink generation (primary subject is the VP file, out of shard); a report on `prd.md:448-455`'s stale Verification column (primary subject prd.md, out of shard — retained only as corroboration inside P7-S3-002). Merged: EC-023/024/025/026/027/033/035 into one finding rather than seven.

Checked and clean in this shard: reason-code closure (POLICY 19) — all four codes used (`malformed-url`, `file-not-found`, `target-is-directory`, `anchor-not-found`) appear verbatim in the 13-code set at `error-taxonomy.md:99-102`, no phantom codes. Quoted-excerpt substantiation (POLICY 5) — all 16 `CAP-007 ("Relative Path Resolution")` quotations across the 8 bodies match `capabilities.md:128` verbatim; the WS-4/Shard-C repair recorded in the changelogs of BC-2.07.001/002/003/004/006/007 landed correctly in every case (0 fabricated quotes found in this shard, against the ~31% corpus-wide rate). BC H1 ↔ BC-INDEX title sync (POLICY 7) — all 8 exact (`BC-INDEX.md:101-108`). Subsystem label (POLICY 6) — `SS-07 | Relative Path Resolution` verbatim per `ARCH-INDEX.md:70`. Code fences (hunt #9) — 0 ```rust fences exist in SS-07 (predicate: grep `^\`\`\`` over ss-07 → 0), so no undefined-type exposure via fences; the undefined-symbol exposure is instead in prose (P7-S3-011). Anchor/slug/two-pass/HTML-carve-out rules (hunt #3) — SS-07 correctly contains no anchor-table or slug rules and correctly routes all anchor concerns to SS-08 (`BC-2.07.005.md:60`, `BC-2.07.006.md:56`), and no SS-07 BC references HTML parsing, consistent with the brief's non-goal (`product-brief.md:56`).