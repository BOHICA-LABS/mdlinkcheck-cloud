---
document_type: adversarial-review
level: ops
version: "1.0"
status: final
producer: adversary
timestamp: 2026-08-08T00:00:00Z
cycle: phase-1d
pass: 7
shard: 1
frozen_develop_head: f8ee4eb024b8b4a300139ef803d248e8fe40f2fc
frozen_specs_tree: ace1745871122cd1fa2c46cf27c5493cc1083411
frozen_spec_lint_tree: f2392b456c3bd669e3efbe86b3e6eae62e302ed1
severity_vocabulary: "CRITICAL/HIGH/MEDIUM/LOW (single vocabulary per PG-012 ruling)"
findings_total_self_declared: 31
inputs: []
input-hash: "ace1745"
traces_to: STATE.md
---
# Pass 7 — Shard 1: SS-01 + SS-02 (13 BC bodies)

```
scope: "SS-01 (9) + SS-02 (4) = 13 bodies read in full"
files_read_in_full:
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-01/BC-2.01.001.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-01/BC-2.01.002.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-01/BC-2.01.003.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-01/BC-2.01.004.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-01/BC-2.01.005.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-01/BC-2.01.006.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-01/BC-2.01.007.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-01/BC-2.01.008.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-01/BC-2.01.009.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-02/BC-2.02.001.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-02/BC-2.02.002.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-02/BC-2.02.003.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-02/BC-2.02.004.md
reference_material_read:
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/product-brief.md (full)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/capabilities.md (full)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/invariants.md (full)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/prd-supplements/error-taxonomy.md (full)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/prd-supplements/test-vectors.md (full)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/VP-INDEX.md (full)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-005-exit-code-io-error.md (full)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-016-ignored-files-anchor-targets.md (full)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-017-scan-terminates.md (full)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/decisions/ADR-006-strict-path-model.md (full)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/system-overview.md (§Three-Phase Pipeline, lines 100-219)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/bc-module-map.md (rows 75-103, 343-460)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/prd-supplements/interface-definitions.md (§8, §9, §10)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/scripts/spec-lint/check-id-resolution.py (EC registry logic, lines 8-196, 431-434)
findings_total: 31
severity_counts: CRITICAL 3 / HIGH 11 / MEDIUM 14 / LOW 3
verdict: NOT converged — three CRITICAL contradictions (fs::canonicalize mandate, Parser::new() mandate that makes a closed-taxonomy reason code unreachable, phantom E-IO-002 error code) plus eleven HIGH contradictions/coverage gaps in the discovery and parsing perimeter.
```

---

### P7-S1-001 — SS-01 dedup mandates `fs::canonicalize`, which the path model forbids [CRITICAL]

Two BCs mandate a symlink-resolving canonical real path as the deduplication key:

- `.factory/specs/behavioral-contracts/ss-01/BC-2.01.002.md:52` — "Deduplication is by canonicalized real path (resolves `.`, `..`, symlinks to files)."
- `.factory/specs/behavioral-contracts/ss-01/BC-2.01.007.md:46` — "Deduplication is based on the canonicalized real path (resolves `.`, `..`, symlinks)."
- reinforced at `BC-2.01.007.md:41` ("resolve … to the same canonical file path"), `:44` ("Each canonical file path appears in the scan set exactly once"), `:65` ("Scan set is a proper set of canonical paths").

"Canonicalized real path … resolves symlinks" is the definition of `std::fs::canonicalize`/`realpath(3)`. The authoritative key form forbids exactly this:

- `.factory/specs/domain-spec/invariants.md:249-252` (DI-009 step 2) — "enforced by a visited set deduplicated by NFC-normalized, lexically-normalized (`.`/`..` collapsed), **NOT-`fs::canonicalize`** key. (`fs::canonicalize` case-folds on macOS APFS, which would conflict with DI-002; **the non-canonicalizing key form is mandatory**.)"
- `.factory/specs/architecture/system-overview.md:133-135` — "Deduplication key: NFC-normalized, lexically-normalized (`.`/`..` collapsed), **NON-canonicalized (no `fs::canonicalize` — canonicalize case-folds on macOS APFS, violating D-006 case-sensitivity and DI-001 determinism)**, scan-root-relative `PathBuf`."
- `system-overview.md:142` — "This key form is **the same canonical key form used throughout the pipeline**."
- `ADR-006-strict-path-model.md:98-103` — "We do NOT call `to_lowercase()` or any case-folding function."

BC-2.01.002 cites `DI-009` in its own Traceability row (`:79`) while contradicting DI-009's mandatory clause. Neither BC mentions NFC normalization at all, so the dedup key as specified is also missing the NFC leg required by DI-002/ADR-006.

**Predicate:** `Grep 'canonicaliz'` over `.factory/specs/behavioral-contracts/ss-01/` → **2 matches** (BC-2.01.007:46, BC-2.01.002:52). `Grep 'canonicalize|canonical'` over `.factory/specs` → prohibition sites at `invariants.md:250-251` and `system-overview.md:134`.

**Consequence:** An implementer following BC-2.01.002/BC-2.01.007 calls `fs::canonicalize` on the scan-set key. On macOS APFS this case-folds, so `docs/A.md` and `docs/a.md` collapse to one key — silently deleting a scan-set member and destroying the DI-002 case-sensitivity guarantee at the *discovery* layer, upstream of and invisible to VP-008 (which tests `path_resolver::files_match`, not the scanner key). This is the exact false-negative class KD-004/TV-036 exists to prevent, and it will pass every verification gate in the plan.

---

### P7-S1-002 — BC-2.02.002 mandates `Parser::new()`, making `undefined-reference-definition` unreachable [CRITICAL]

`.factory/specs/behavioral-contracts/ss-02/BC-2.02.002.md:58` (Postcondition 3) — "The string is passed as-is to `pulldown_cmark::Parser::new()`."
`.factory/specs/behavioral-contracts/ss-02/BC-2.02.002.md:43` (shell-side obligation, normative for the story writer) — "The string passed to `pulldown_cmark::Parser::new()` must already be BOM-free and LF-only."

The authoritative constructor requirement is the opposite:

- `.factory/specs/behavioral-contracts/ss-03/BC-2.03.003.md:45` — "**`scanner.rs` MUST construct the pulldown-cmark parser via `Parser::new_with_broken_links()`**"
- `.factory/specs/behavioral-contracts/ss-03/BC-2.03.003.md:60` — "**A plain `Parser::new()` emits them as** [plain text] … `broken_link_callback` is registered on the parser."
- `.factory/specs/prd.md:597` — "Revised BC-2.03.003 preconditions to state that `scanner.rs` MUST construct the parser via `Parser::new_with_broken_links()` … **Without this callback, undefined reference links are emitted as plain text (no link event), making the `undefined-reference-definition` verdict unreachable.**"
- `.factory/specs/architecture/purity-boundary-map.md:107` — "Running `pulldown-cmark::Parser::new_with_broken_links()`"

BC-2.02.002 is the BC that *owns the scanner-side string handoff* (its Architecture Module row, `:104`, is `scanner.rs` (SS-02, effectful shell) — BOM/CRLF only), so its PC3 is the site an implementer reads when writing the parser-construction call. There is no cross-reference in BC-2.02.002 to BC-2.03.003.

**Predicate:** `Grep 'ENABLE_|footnote|Footnote|into_offset_iter|Parser::new'` over `.factory/specs` → `Parser::new()` asserted at BC-2.02.002:43, BC-2.02.002:58, feasibility-review.md:181; `new_with_broken_links` required at purity-boundary-map.md:107, BC-2.03.003:45, prd.md:597.

**Consequence:** An implementer implementing BC-2.02.002 literally constructs `Parser::new()`. `undefined-reference-definition` — one of the 13 codes in the closed taxonomy (`error-taxonomy.md:73`, `:100-102`) — becomes unreachable. TV-096/EC-096 (`test-vectors.md:202`) then fails, and VP-021's closed-set check passes vacuously because the code is simply never emitted.

---

### P7-S1-003 — `E-IO-002` is a phantom error code; nonexistent-PATH has no code in the closed 13-code set [CRITICAL]

`.factory/specs/behavioral-contracts/ss-01/BC-2.01.009.md` asserts `E-IO-002` as an observable output token at four sites:
- `:44` — "emits an E-IO-002 error for `nonexistent_dir/`"
- `:52` (PC1) — "an `E-IO-002` error is recorded; an error message is emitted on stderr"
- `:71` (test vector) — "Exit 2; **E-IO-002 on stderr**; no findings on stdout"
- `:73` (test vector) — "**E-IO-002 for nonexistent_dir on stderr**"

`E-IO-002` is defined nowhere. `.factory/specs/prd-supplements/error-taxonomy.md` is the declared CLOSED set (`:23` "This is the CLOSED set of failure reasons. Nothing may fail with a reason outside this set."; `:99-102` enumerates the 13 codes). `E-IO-002` is not among them, and the only I/O code — `target-unreadable` (`error-taxonomy.md:91`) — has trigger "Source `.md` file **exists** but cannot be read (permission denied, non-UTF-8 content, unexpected read error)", which a *nonexistent* PATH argument does not satisfy. `error-taxonomy.md:166` (§6.1) restates the two conditions `target-unreadable` covers: permission-denied and invalid-UTF-8. Neither is "path absent".

`.factory/specs/domain-spec/capabilities.md:246-248` (CAP-014) confirms nonexistent PATH goes into `io_errors` but assigns it no reason code. `.factory/specs/prd-supplements/test-vectors.md:82` (TV-012) says only "Exit 2 with reason indicating path not found" — no code named. So the closed taxonomy has a genuine hole and BC-2.01.009 filled it with an invented identifier.

`E-IO-002` also does not belong to any POLICY-16 registered family (`EC-*, T-*, R-*, DD-*, DI-*, AMB-*, CAP-*, VP-*, ADR-*, NFR-*`), so `check-id-resolution.py` cannot see it.

**Predicate:** `Grep 'E-IO-002|E-CLI-001|E-IO-'` over `.factory/specs` → **6 matches / 3 files**: BC-2.01.009.md:23, :44, :52, :71, :73 (5) and interface-definitions.md:237 (1); plus BC-2.11.004.md:61 for `E-CLI-001`. Zero definition sites; zero occurrences in error-taxonomy.md.

**Consequence:** A test-writer implementing BC-2.01.009's test vectors asserts the literal string `E-IO-002` on stderr; an implementer emits whatever string they choose. VP-021 (`vp-021-no-undefined-reason-codes.md:49,90`) validates only the 13-code list against `results`, so an out-of-set stderr token passes the NFR-007 gate undetected. Either the closed set must gain a 14th code (schema_version consequence per `error-taxonomy.md:176`) or BC-2.01.009 must be re-anchored — both are spec-level decisions that cannot be made during implementation.

---

### P7-S1-004 — BC-2.01.004 claims VP-016, unauthorized by both VP-INDEX and bc-module-map [HIGH]

`.factory/specs/behavioral-contracts/ss-01/BC-2.01.004.md:79-80` declares two VP rows:
```
| VP-017 | Scan terminates for any directory tree with symlink cycles | integration |
| VP-016 | Dot-dir .md files remain valid anchor targets (DI-006 case 3) | integration |
```
The two source-of-truth tables assign BC-2.01.004 **only** VP-017:
- `.factory/specs/verification-properties/VP-INDEX.md:139` — "| BC-2.01.004 | Dot-directory skip (unconditional, D-011) | **VP-017** | termination includes symlink non-following |"
- `.factory/specs/architecture/bc-module-map.md:78` — "| BC-2.01.004 | `scanner` | — | Effectful | HIGH | ADR-005 | **VP-017** | VP-017 |"

VP-016's own frontmatter (`vp-016-ignored-files-anchor-targets.md:14`) has `source_bc: BC-2.08.004`, and VP-INDEX's VP-016 row (`:72`) assigns the module `anchor_table`, not `scanner`. POLICY 9 makes VP-INDEX the VP-catalog source of truth.

**Predicate:** `Grep 'BC-2\.01\.|BC-2\.02\.'` over `bc-module-map.md` → row `:78` lists VP-017 only for BC-2.01.004; `Grep 'SS-01|SS-02'` + full read of `VP-INDEX.md:132-153` → BC-2.01.004 row lists VP-017 only.

**Consequence:** Whichever direction is wrong, the VP-to-BC join is not a function. If VP-INDEX is right, BC-2.01.004 over-claims coverage for its DI-006 case-3 carve-out (`:42-45`, `:58-59`) — the load-bearing behavior of the whole dot-dir contract — and a converged gate will report it verified when no assigned VP covers it. If BC-2.01.004 is right, VP-INDEX's coverage arithmetic and `check-counts.py` totals are stale.

---

### P7-S1-005 — BC-2.01.003's VP-016 row states a property VP-016 does not assert; architecture records it as a KNOWN GAP [HIGH]

`.factory/specs/behavioral-contracts/ss-01/BC-2.01.003.md:73`:
```
| VP-016 | Files matching .gitignore patterns are never in the scan set | integration test |
```
VP-016 asserts something else. `vp-016-ignored-files-anchor-targets.md:43` (H1) — "Ignored Files Have Anchor Tables — Cross-File Anchors into Ignored Files Resolve"; `:47` (Property Statement) — "All four source-exclusion mechanisms in DI-006 exclude files as SOURCES only. **The excluded file remains a valid anchor target**, and links pointing TO it … must not produce false positives." Its DI coverage is DI-006 (`VP-INDEX.md:72`, `:93`), not scan-set exclusion.

The architecture records this mismatch explicitly as an unclosed gap:
- `.factory/specs/architecture/bc-module-map.md:430` — "### INC-MAP-004: BC-2.01.003 VP belongs to anchor_table, not scanner — **KNOWN GAP** (disposition recorded)"
- `bc-module-map.md:436-437` — "**This leaves a gap: no VP directly verifies that scanner *excludes* gitignored files as link sources** (i.e., links within .gitignore'd files are not reported as findings)."
- `bc-module-map.md:452-454` — the gap is closed "at the integration test level" by the **acceptance corpus**, not by VP-016.

VP-016 v1.3 added a per-fixture `source-not-scanned` assertion (`vp-016…md:165-171`) for one hard-coded fixture file, which is not the universal property BC-2.01.003's row states. BC-2.01.003's own Traceability row half-acknowledges the problem (`:82` — "note: VP-016 formal assignment is to `anchor_table` module (INC-MAP-004)") without correcting the property text.

**Predicate:** Full read of `vp-016-ignored-files-anchor-targets.md` — the string "scan set" appears in the property statement only as "not in the scan set" describing the *fixture setup* (`:52`), never as an asserted postcondition; `Read bc-module-map.md:425-460` → INC-MAP-004 verbatim.

**Consequence:** BC-2.01.003 is the only BC governing `.gitignore` exclusion (the R8 performance guard, `:38-40`). Its single VP row presents scan-set exclusion as VP-verified. A gate reading only the BC concludes the property is covered; the architecture's own disposition says it is not. This is a false-green on the one behavior that keeps `node_modules/` (TV-002, 1000 files) out of the scan.

---

### P7-S1-006 — BC-2.01.009's sole VP does not cover its no-fail-fast postconditions [HIGH]

`.factory/specs/behavioral-contracts/ss-01/BC-2.01.009.md:78`:
```
| VP-005 | Exit 2 when any I/O error occurs; exit 2 beats exit 1 | kani |
```
VP-005 is a pure-function proof over `verdict::exit_code`: `vp-005-exit-code-io-error.md:41-45` — "For all possible combinations of `findings`, `io_errors`, and `config_error`, if `io_errors` is non-empty OR `config_error` is true, then `exit_code(...)` returns `2`." Its harness (`:61-91`) takes three symbolic booleans and never models traversal. Its `source_bc` is `BC-2.14.002` (`:14`), and VP-INDEX:264 assigns it to BC-2.14.002.

The distinguishing content of BC-2.01.009 — the entire reason v1.1/v1.2 were written — is **not** the exit code but the no-fail-fast behavior:
- `:52` (PC1) — "scanning **continues for all remaining valid PATH arguments** (DD-007 no-fail-fast)"
- `:53` (PC2) — "scan continues for all other files"
- `:54` (PC3) — "Findings from successfully scanned files are still emitted in output"
- `:73` (EC-185 distinguishing vector) — "good_dir **fully scanned**"
- `:24` (changelog v1.2) — "Added mixed-case test vector (EC-014) that **distinguishes the two readings**"

VP-005 cannot falsify a fail-fast implementation: an implementation that aborts on the first nonexistent PATH still returns 2 from `exit_code` and passes VP-005 in full. BC-2.01.009 carries no second VP row and no `test-sufficient` row for the continuation property. VP-INDEX:144 lists BC-2.01.009 → VP-005 with no supplementary note.

**Predicate:** Full read of `vp-005-exit-code-io-error.md` — the strings "scan", "traversal", "continue" appear **0 times** in its Property Statement and harness. `Grep 'EC-185'` over `.factory/specs` → `test-vectors.md:420` (TV-185, no VP reference) and BC-2.01.009 only.

**Consequence:** The one behavior BC-2.01.009 exists to pin — that `mdlinkcheck good_dir/ nonexistent_dir/` fully scans `good_dir/` and emits its findings — has zero declared verification vehicle. A fail-fast implementation satisfies BC-2.01.009's VP table, VP-INDEX's coverage claim, and CAP-014, while silently dropping every finding after the first bad PATH argument.

---

### P7-S1-007 — BC-2.01.003 PC3 makes the scan set a function of the developer's home directory [HIGH]

`.factory/specs/behavioral-contracts/ss-01/BC-2.01.003.md:49` (Postcondition 3):
> "The global git ignore file (`~/.gitignore_global`, `core.excludesFile`) is respected when available."

This is unilateral and un-anchored:

1. **Contradicts the governing determinism rationale.** `ADR-006-strict-path-model.md:80-88` (D-043 canonical wording, verbatim-pinned) — "The tool must produce byte-identical output for byte-identical repository content, and **must not let the host filesystem's … behaviour influence link verdicts** … adopting native filesystem semantics would make verdicts **a function of the filesystem rather than of the repository content**." A per-user `core.excludesFile` is precisely a host-state input. `ADR-006:135` — "Verdicts are a function of repository content, not of macOS APFS filesystem behavior (DI-001, NFR-003)."
2. **Contradicts DI-006's enumeration.** `invariants.md:159-160` (DI-006 case 2) defines the mechanism as "`.gitignore` / `.ignore` patterns — automatic traversal exclusion enforced by the `ignore` crate's WalkBuilder". No global/`core.excludesFile` leg.
3. **Exceeds the resolution of the AMB it cites.** BC-2.01.003 Traceability (`:81`) cites `AMB-003`. `.factory/planning/brief-validation.md:213` states AMB-003 verbatim — "Is **`.gitignore` respected**? … What about `.ignore`, nested `.gitignore`, **global gitignore**?" with suggested resolution "**Respect `.gitignore` + nested**; `--no-ignore-vcs` to disable". The global-gitignore sub-question was raised and the suggested resolution deliberately did *not* include it. BC-2.01.003 PC3 answers it "yes" with no decision record.
4. **Unfalsifiable as written.** "when available" makes the postcondition's truth conditional on state outside the repository; there is no test vector for it in `test-vectors.md` (§1 EC-001..EC-021 contains no global-gitignore row).

**Predicate:** `Grep 'excludesFile|gitignore_global|global git'` over `.factory/specs` → **1 match, 1 file**: `BC-2.01.003.md:49`. No other spec artifact mentions it.

**Consequence:** The same repository yields different scan sets — and therefore different exit codes — on a developer laptop with `core.excludesFile` set versus in CI where it is unset. This is the identical local-vs-CI divergence class that D-043/ADR-006 were written to eliminate, reintroduced through the discovery layer where no VP looks.

---

### P7-S1-008 — BC-2.01.006 Invariant 1 endorses `Path::exists()`, an explicitly forbidden API, and drops DI-002's NFC leg [HIGH]

`.factory/specs/behavioral-contracts/ss-01/BC-2.01.006.md:48` (Invariant 1):
> "`Path::exists()` follows symlinks; after confirming existence, **exact-case** directory-entry comparison is still applied (DI-002)."

Two defects in one sentence.

**(a) Forbidden API.** `.factory/specs/prd-supplements/test-vectors.md:114` (TV-036, the KD-004 flagship differentiator) — "`std::fs::exists(\"README.MD\")` returns `true` on macOS APFS but **MUST NOT be used** — tool must enumerate the parent directory and compare entries exactly … An `std::fs::exists()`-based implementation silently accepts the case mismatch on macOS APFS, producing a false negative invisible on a macOS-only matrix." The architecture routes existence through `DirIndex`, not a filesystem probe: `purity-boundary-map.md:58` — "**DirIndex is input data, never calls any fs::* function** … each entry carries EntryKind so file/dir/symlink is distinguishable without I/O"; `system-overview.md:159-160` — "Parent directory listings are already in DirIndex from Pass 1.5a; **no additional directory reads are needed to determine file existence or EntryKind**."

**(b) Dropped qualifier.** DI-002's title and text are "Case-Sensitive **NFC-Normalized** Path Comparison" (`invariants.md:85-88`): "compares the decoded, **NFC-normalized** destination against the actual **NFC-normalized** directory entries — case-sensitively". CAP-007 restates it as "case-sensitive **NFC-normalized** directory-entry comparison (DI-002)" (`capabilities.md:132-133`). BC-2.01.006 renders it as "exact-case directory-entry comparison (DI-002)" — the NFC leg is gone. NFC normalization is the *only* thing preventing the DEC-004/FM-007 false-positive class on APFS-stored NFD filenames (`ADR-006:31-37`, `:90-96`). BC-2.01.006 has no `L2 Domain Invariants` row (see P7-S1-016), so this truncated in-body citation is the BC's sole DI-002 anchor.

**Predicate:** `Grep 'canonicalize|canonical'` and full read of `ADR-006` + `invariants.md` DI-002 → both spell out NFC. `Grep 'symlink'` over `.factory/specs` → `purity-boundary-map.md:58` and `:70-71` confirm the DirIndex/EntryKind mechanism with no `fs::exists` path.

**Consequence:** An implementer reads BC-2.01.006 Invariant 1 as license to call `Path::exists()` in the symlink path, which on APFS case-folds — reintroducing exactly the TV-036 false negative that TV-036 exists to catch, in the one code path (symlink targets) that TV-036's fixture does not exercise. The dropped NFC qualifier independently permits a byte-equal comparison that reports `broken` on every valid NFD-stored accented filename.

---

### P7-S1-009 — BC-2.02.004 Precondition 2 reintroduces `.markdown` as a Markdown extension; REGRESSION-002 not propagated [HIGH]

`.factory/specs/behavioral-contracts/ss-02/BC-2.02.004.md:41` (Precondition 2):
> "The file does not have a `.md` or `.markdown` extension."

This treats `.markdown` as a Markdown extension co-equal with `.md`, which D-012/DD-019 abolished. `decisions.md:71` (DD-019) — "Discovery extension scope: `.md` files only, case-sensitive … `.MD`, `.markdown`, and `.mdx` are **explicit non-goals with no BC and no test vector**." Every sibling BC states it as an *excluded* extension: `BC-2.01.001.md:38`, `BC-2.01.002.md:46`, `BC-2.01.005.md:38,53,59`, `BC-2.02.001.md:43`.

Two concrete consequences:
1. **Precondition hole.** An explicitly-passed `notes.markdown` fails BC-2.02.004's PC2, so BC-2.02.004 does not govern it — yet `BC-2.01.002.md:47` (PC2) says "For each PATH that is an existing file: that file is included **regardless of extension**". The two BCs disagree on whether an explicit `.markdown` argument is parsed.
2. **Partial-fix propagation.** REGRESSION-002 removed the `.markdown` reference from four siblings and recorded it in their changelogs — `BC-2.01.001.md:23`, `BC-2.01.002.md:23`, `BC-2.01.008.md:23`, `BC-2.02.001.md:24` — but BC-2.02.004 (v1.3, changelog `:23-25`) never received the sweep. Blast radius from the original fix is now 1 unfixed file inside SS-02.

**Predicate:** `Grep '\.markdown'` over `.factory/specs/behavioral-contracts` → **15 matches / 8 files**. Of these, exactly **one** treats `.markdown` as a Markdown extension in a normative clause: `BC-2.02.004.md:41`. (`BC-2.07.006.md:38,50` also reference `.md` or `.markdown` — outside this shard.) Four REGRESSION-002 changelog entries confirm the sweep pattern.

**Consequence:** Explicit `mdlinkcheck notes.markdown` has two contradictory readings (parsed per BC-2.01.002 PC2; ungoverned per BC-2.02.004 PC2). There is no test vector — `test-vectors.md:76` (TV-006) covers `notes.markdown` only via *traversal*, not as an explicit argument — so whichever reading is implemented will never be checked.

---

### P7-S1-010 — Explicit PATH argument that is a directory symlink has two contradictory verdicts and no resolution [HIGH]

`.factory/specs/behavioral-contracts/ss-01/BC-2.01.002.md:46` (PC1) — "For each PATH that is **an existing directory**: all `.md` files under it are included, subject to traversal rules".
`.factory/specs/behavioral-contracts/ss-01/BC-2.01.004.md:52` (PC2) — "If the entry is a symlink pointing to a directory: **skip (do not follow)**."
`.factory/specs/behavioral-contracts/ss-01/BC-2.01.004.md:57` (Invariant 2) — "Directory symlinks are **never** followed (DI-009 — prevents infinite cycles)."

`mdlinkcheck symlink_to_docs/` satisfies both antecedents: the PATH *is* an existing directory (`Path::is_dir()` follows symlinks) and it *is* a directory symlink. BC-2.01.002 PC1 says traverse it; BC-2.01.004 Invariant 2 says never follow it. Nothing distinguishes "encountered during traversal" from "supplied as a scan root": BC-2.01.004's preconditions are "Traversal encounters a directory entry" (`:45`), and a root argument is not a traversal-encountered entry — so BC-2.01.004 arguably does not apply, leaving BC-2.01.002 PC1 alone and contradicting Invariant 2's "never".

`.factory/specs/prd-supplements/test-vectors.md:79` (TV-009/EC-009) covers only the traversal case — "Symlink `docs -> ../shared-docs` pointing outside root … Dir symlinks not followed" with no flags column, i.e. default root. `BC-2.01.004.md:67` cites EC-009 for the same traversal scenario. No visible artifact covers `mdlinkcheck <dir-symlink>` as an argument.

**Predicate:** `Grep 'symlink'` over `.factory/specs` excluding `behavioral-contracts/ss-01/` → 45 results returned (paginated; full-corpus magnitude not established by predicate). None of the returned rows — including `test-vectors.md:78,79,116`, `invariants.md:238,262`, `system-overview.md:155`, `module-decomposition.md:69-70,124`, `purity-boundary-map.md:58,70-71`, all of `vp-017-scan-terminates.md` — states any rule for a PATH argument that is itself a directory symlink.

**Consequence:** A verdict/exit-code totality hole in the CLI's front door. `mdlinkcheck docs/` where `docs` is a symlink (a routine monorepo layout) either scans the tree (exit 0/1 with findings) or scans nothing (exit 0, or exit 0 + "No markdown files found." per BC-2.01.008). Both are defensible under the current specs, and the difference is a silent false negative on an entire documentation tree.

---

### P7-S1-011 — BC-2.01.008 EC-125 contradicts TV-125 and emits a factually false message [HIGH]

`.factory/specs/behavioral-contracts/ss-01/BC-2.01.008.md:59` lists edge case:
```
| EC-125 | `--ignore '*.md'` excludes all files |
```
under a BC whose PC3 (`:48`) is "Stderr contains an informational message: `No markdown files found.`" and whose Invariant 2 (`:52`) is "The stderr message is always emitted; there is no `--quiet` flag (D-011). **The message is informational, not a warning.**"

The registry says the opposite for EC-125. `.factory/specs/prd-supplements/test-vectors.md:238` (TV-125) — "| TV-125 | EC-125 | All files matched by `*.md` | `--ignore '*.md'` | 0 | **warning on stderr**; no findings |". "not a warning" vs "warning on stderr" is a direct contradiction on the observable output.

The message is also factually false in this scenario. `.factory/specs/domain-spec/invariants.md:180-182` (DI-006 case 1) — "Pass 1 traverses and parses **ALL** discovered `.md` files, including `--ignore`d ones. Anchor tables exist in AnchorIndex when Pass 2 begins." Markdown files were found, read, parsed, and indexed; only the source-scan step skipped them. And the registry assigns this scenario a *different* EC owned by a *different* BC: `test-vectors.md:427` (TV-192/EC-192) — "`--ignore '*.md'` — glob excludes all .md source files; 0 files scanned | **BC-2.11.001** | 0 | no findings".

**Predicate:** `Grep 'No markdown files found'` over `.factory/specs` → **6 matches / 4 files**: BC-2.01.008.md:48, :63; BC-2.01.001.md:68; test-vectors.md:81 (TV-011, empty directory); interface-definitions.md:100. Zero of these associate the message with `--ignore`. TV-125 (`test-vectors.md:238`) says "warning", not "No markdown files found."

**Consequence:** Three-way divergence on one input. A test-writer implementing TV-125 asserts a warning; an implementer following BC-2.01.008 emits "No markdown files found."; EC-192 says the case belongs to BC-2.11.001 entirely. The user-visible outcome is a message asserting no Markdown exists in a repository full of Markdown — a diagnosis that sends the user hunting for missing files instead of at their `--ignore` glob.

---

### P7-S1-012 — BC-2.02.001 PC4 is the corpus's only parser-Options specification and is under-specified on footnotes [HIGH]

`.factory/specs/behavioral-contracts/ss-02/BC-2.02.001.md:50` (PC4):
> "GFM extensions (tables, strikethrough, task lists) are enabled; footnotes are recognized but treated as non-links."

"Recognized" is not "enabled", and the two readings produce different verdicts for a footnote:

- **Footnotes enabled** (`Options::ENABLE_FOOTNOTES`): `[^1]` yields `FootnoteReference` events, which are not `Tag::Link`, so no finding. Matches `test-vectors.md:225` (TV-120/EC-120 — "`[^1]` footnote + `[^1]: text` definition | 0 | none | Not a reference link") and `BC-2.03.006.md:45`.
- **Footnotes disabled** (pulldown-cmark default): `[^1]` parses as a shortcut reference link with label `^1` and no matching definition. Combined with the mandatory `Parser::new_with_broken_links()` + callback (`BC-2.03.003.md:45`), the undefined label routes to `undefined-reference-definition` → **broken, exit 1** (`BC-2.03.003`, `error-taxonomy.md:73`). This flips TV-120 from exit 0 to exit 1.

BC-2.03.006's mechanism assumes the first reading without saying so: `BC-2.03.006.md:51` (Invariant 2) — "No special-case footnote filtering code is needed" — which is only true if the extension is enabled. Nothing in the corpus states the Options bitflag set. `ADR-003-pulldown-cmark.md` does not enumerate Options anywhere (its only extension content is the GFM bare-URL *limitation*, `:52-55`, `:67`).

**Predicate:** `Grep 'ENABLE_|footnote|Footnote|into_offset_iter|Parser::new'` over `.factory/specs` → **0 matches for `ENABLE_`** anywhere in the spec corpus (22 matches total, all for the other alternatives). BC-2.02.001.md:50 is therefore the sole specification of which parser options are set.

**Consequence:** The reachability of a closed-taxonomy reason code and the expected exit code of TV-120 both turn on an unstated bitflag. An implementer who reads "footnotes are recognized" as "no action needed" ships default Options and TV-120 fails with exit 1. There is no VP: `VP-INDEX.md:150` marks BC-2.02.001 `test-sufficient`, and `VP-INDEX.md:164` marks BC-2.03.006 `test-sufficient` — so nothing pins the option set at any tier.

---

### P7-S1-013 — BC-2.02.002 cites EC-015b; the registry already reallocated that scenario to EC-178 [HIGH]

`.factory/specs/behavioral-contracts/ss-02/BC-2.02.002.md:83`:
```
| EC-015b | BOM file: `[x](missing.md)` is the first link on line 1 |
```
and `:89` — "| BOM + `[x](missing.md)\n` | Exit 1; line 1, **column 1** … | edge-case (TV-015b) |".

The registry allocated a distinct EC-NNN for exactly this scenario, precisely to eliminate the sub-lettered form:
- `.factory/specs/prd-supplements/test-vectors.md:86` — "| TV-015b | **EC-178** | `utf8bom.md` with UTF-8 BOM, then `[x](missing.md)` on line 1 | (none) | 1 | broken; file=utf8bom.md, line=1, **column=1** | … See F-028. |"
- `.factory/specs/prd-supplements/test-vectors.md:404` (§10.5, "Disambiguation IDs for Multi-Variant Test Vectors", introduced "to resolve EC injectivity collisions (POL-16)") — "| **EC-178** | TV-015b (§1) | Disambiguates TV-015 (clean) vs TV-015b (broken) |"

`EC-015b` appears nowhere in test-vectors.md. This is a stale reference to the pre-remediation ID: the EC-178 allocation landed in test-vectors.md v1.8 (`test-vectors.md:478` — "POL-16 EC injectivity remediation … §10 collision-remapping registry") and BC-2.02.002 (v1.3, changelog stops at v1.2) was never updated. The identical class of fix *was* applied elsewhere in this shard — `BC-2.01.008.md:25` ("EC-009 renamed to EC-184") and `BC-2.01.009.md:26` ("EC-014 renamed to EC-185") — so the sweep skipped SS-02.

`check-id-resolution.py` cannot catch it: lines 159-161 and 193-196 auto-register `EC-NNNa..EC-NNNz` for every registered base, so `EC-015b` resolves because `EC-015` exists.

**Predicate:** `Grep 'EC-006a|EC-006b|EC-015b|EC-028b|EC-011\b'` over `.factory/specs` → **5 matches**: test-vectors.md:81 (EC-011), BC-2.02.002.md:83 (EC-015b), BC-2.01.006.md:55 (EC-028b), BC-2.01.005.md:66 (EC-006a), BC-2.01.005.md:67 (EC-006b). Zero occurrences of EC-015b in test-vectors.md.

**Consequence:** A test-writer resolving BC-2.02.002's edge-case table searches test-vectors.md for `EC-015b`, finds nothing, and either invents a vector or drops it. The F-028 column-1-not-column-4 assertion — the only guard against BOM bytes leaking into reported column numbers — is the one at risk, and it is `test-sufficient` (`VP-INDEX.md:151`), so no VP backstops it.

---

### P7-S1-014 — `target-unreadable` is specified as a "finding" on stdout; it is not a verdict and belongs in `errors` [HIGH]

Two sites in this shard classify an I/O error as a finding:
- `.factory/specs/behavioral-contracts/ss-02/BC-2.02.003.md:45` (PC2) — "A `target-unreadable` **finding** is emitted for the file."
- `.factory/specs/behavioral-contracts/ss-01/BC-2.01.009.md:72` (test vector) — "Exit 2; broken finding + **unreadable finding on stdout**/stderr"

The authoritative classification is the opposite:
- `.factory/specs/prd-supplements/error-taxonomy.md:50-54` — "**I/O errors** (not a link verdict) … Not a link verdict — sets exit 2."
- `error-taxonomy.md:91` — `target-unreadable` | Verdict column = "**— (I/O error)**"
- `error-taxonomy.md:171` (§6.1) — "Both route to the **`errors` array** in JSON output (**not `results`**)"
- `.factory/specs/prd-supplements/test-vectors.md:83` (TV-013) — "`errors:[{file:\"docs/secret.md\",reason:\"target-unreadable\"}]` in JSON `--format json` output; **NOT a `verdict` field (I/O errors go in the `errors` array, not `results`)**"
- `.factory/specs/domain-spec/capabilities.md:218-223` (CAP-013) — `results` = "array of finding objects", `errors` = "array of I/O diagnostic objects"; each `results` element carries `verdict` and `reason`.
- `.factory/specs/domain-spec/invariants.md:130-132` (DI-005) — "Each extracted link is assigned exactly one verdict (`clean`, `broken`, or `indeterminate`)". A file-level I/O error is not an extracted link and has no verdict.

BC-2.01.009 gets it right in its postconditions (`:52-53` — "recorded", "I/O error") and wrong in its test vector; BC-2.02.003 gets it wrong in the postcondition itself, which is the normative clause.

**Predicate:** Full read of `error-taxonomy.md` — `target-unreadable`'s Verdict cell is literally `—`; §6.1 states the `errors`-array routing. `Grep 'AMB-'`-adjacent full read of `test-vectors.md:83` confirms the "NOT a `verdict` field" guard.

**Consequence:** An implementer following BC-2.02.003 PC2 pushes `target-unreadable` into `results` with some invented verdict value. That breaks the JSON schema (`schema_version` 1, `capabilities.md:218-223`), makes TV-013's negative assertion fail, and puts a non-verdict value into the multiset that `verdict::exit_code` consumes — which VP-005's symbolic model (three booleans, `vp-005…md:64-71`) does not represent and therefore cannot falsify.

---

### P7-S1-015 — BC-2.01.001 invents a scanner proptest for a property VP-017 already owns [MEDIUM]

`.factory/specs/behavioral-contracts/ss-01/BC-2.01.001.md:74`:
```
| test-sufficient | Scan always terminates for finite inputs | proptest (bounded depth + symlink cycle) |
```
This is BC-2.01.001's PC3 verbatim (`:50` — "The scan completes (terminates) for any finite directory tree"), which is DI-009 (`invariants.md:235-262`), which is owned by VP-017 — `VP-INDEX.md:73` ("| VP-017 | vp-017-scan-terminates.md | scanner | integration | test-sufficient | DI-009 |") and `VP-INDEX.md:96` ("| DI-009 | Scan terminates for any input | VP-017 | integration | Yes |"). `BC-INDEX.md:214` names BC-2.01.001 as a DI-009 enforcer.

The named vehicle does not exist. `VP-INDEX.md:118` (Per-Module VP Count) — "| scanner | 0 | **0** | 0 | 1 | 0 | 1 |" — the scanner module has **zero** proptest VPs, and all 9 proptest VPs are enumerated at `VP-INDEX.md:64-67,75,79-82` (path_resolver ×3, filter, reporter, link_extractor, url_classifier, anchor_resolver, slug). `bc-module-map.md:75` assigns BC-2.01.001 no VP at all ("| BC-2.01.001 | `scanner` | — | Effectful | HIGH | ADR-005 | — | none |"), and `bc-module-map.md:441` explains why: "`scanner` is effectful (binary crate). Kani is not applicable."

**Predicate:** `Read VP-INDEX.md` in full → per-module table row `scanner` proptest column = 0; the 9 proptest VPs are VP-008, VP-009, VP-010, VP-011, VP-019, VP-023, VP-024, VP-025, VP-026 — none assigned to scanner. `Grep 'BC-2\.01\.'` over `bc-module-map.md` → row `:75` VP columns are `—` / `none`.

**Consequence:** BC-2.01.001's verification row names a test vehicle (a scanner proptest with bounded-depth and symlink-cycle generators) that no architecture document plans, budgets, or assigns a module. Either it is dead text — in which case a story writer may build a redundant second termination harness alongside VP-017's three fixtures — or VP-INDEX's proptest arithmetic (`:50-51`) is wrong.

---

### P7-S1-016 — 6 of 13 BCs have no `L2 Domain Invariants` row; two cite DIs in the body that the Traceability table omits [MEDIUM]

Missing `L2 Domain Invariants` Traceability row: BC-2.01.005, BC-2.01.006, BC-2.01.007, BC-2.02.001, BC-2.02.002, BC-2.02.004.

Two are POLICY-2 scope mismatches — the body cites a DI that the Traceability table then omits:
- `.factory/specs/behavioral-contracts/ss-01/BC-2.01.006.md:48` cites **DI-002** in Invariant 1; Traceability (`:69-75`) has no DI row. DI-002 is the strict path model — the product's flagship differentiator (`test-vectors.md:114`, KD-004).
- `.factory/specs/behavioral-contracts/ss-02/BC-2.02.001.md:54` cites **DI-004** in Invariant 2 ("no heuristic needed to satisfy DI-004"); Traceability (`:76-82`) has no DI row.

One is a substantive omission: `.factory/specs/behavioral-contracts/ss-01/BC-2.01.007.md` is the path-deduplication BC. DI-009 explicitly covers "overlapping path arguments" (`invariants.md:238-239`) and prescribes the mandatory dedup key form (`invariants.md:249-252`). BC-2.01.007 declares no DI, which is the structural reason the `fs::canonicalize` contradiction in P7-S1-001 has no anchor pulling it back to DI-009.

`BC-2.01.001.md:81` declares `DI-009` only, while its Invariant 1 (`:53`) also cites `DI-006 case 3`.

**Predicate:** `Grep 'L2 Domain Invariants'` over `.factory/specs/behavioral-contracts/ss-01/` → **6 matches / 6 files** (of 9 BCs): BC-2.01.001:81, .002:79, .003:80, .004:87, .008:75, .009:85 → missing in .005, .006, .007. `Grep 'L2 Domain Invariants'` over `ss-02/` → **1 match / 1 file** (of 4 BCs): BC-2.02.003:74 → missing in .001, .002, .004. Total **6 of 13** in scope lack the row.

**Consequence:** `gen-bc-traceability.py`-derived DI→BC coverage tables under-report enforcement for DI-002 and DI-004, and BC-2.01.007's silence on DI-009 removed the only in-document guard against the canonicalize contradiction. POLICY 2 has `lint_hook: null`, so nothing detects it mechanically.

---

### P7-S1-017 — BC-INDEX DI-enforcer lists do not match the DI declarations in these BCs [MEDIUM]

`.factory/specs/behavioral-contracts/BC-INDEX.md:214` — "| DI-009 | Scan Terminates for Any Input … | **BC-2.01.004, BC-2.01.001, BC-2.05.001** (Pass 1.5 termination) |"

But five BCs in this shard declare DI-009 in their `L2 Domain Invariants` row: BC-2.01.001:81, BC-2.01.002:79, BC-2.01.003:80, BC-2.01.004:87, BC-2.01.008:75. Three of the five (.002, .003, .008) are absent from BC-INDEX's enforcer list.

`.factory/specs/behavioral-contracts/BC-INDEX.md:211` — "| DI-006 | **`--ignore` is source-only; anchor tables built for ignored files** | BC-2.01.003, BC-2.05.001, BC-2.08.004, BC-2.11.001 |"

Two problems: (a) `BC-2.01.004.md:87` declares DI-006 and is omitted, even though BC-2.01.004 is the authoritative statement of DI-006 **case 3** (`:42-45`, `:58-59`) and VP-016 Case 3 (`vp-016…md:53`, `:182-219`) tests exactly that carve-out; (b) the summary text is the pre-widening description. `invariants.md:46` (changelog v1.1) records "DI-006 widened from --ignore-only to all four source-exclusion mechanisms", and DI-006's actual heading is "Scan-Set Membership Is Independent of Anchor-Target Universe Membership" (`invariants.md:149`). BC-INDEX still describes it as `--ignore`-only.

**Predicate:** `Grep 'DI-009|DI-006'` over `.factory/specs/behavioral-contracts` → **53 occurrences / 11 files**. `Grep 'BC-2\.01\.|BC-2\.02\.|DI-00[269]|DI-011|DI-002|DI-004'` over `BC-INDEX.md` → DI-006 row `:211` lists 4 BCs (BC-2.01.004 absent); DI-009 row `:214` lists 3 BCs (BC-2.01.002/.003/.008 absent).

**Consequence:** The DI→BC coverage table an auditor reads under-counts DI-009 enforcement by three BCs and omits the BC that owns DI-006 case 3. Combined with P7-S1-016, the invariant-to-BC join in this shard is inaccurate in both directions.

---

### P7-S1-018 — BC-2.01.001 Invariant 1 mis-anchors the dot-dir/anchor-target rule to DI-009 [MEDIUM]

`.factory/specs/behavioral-contracts/ss-01/BC-2.01.001.md:53` (Invariant 1):
> "ALL dot-directories (including `.git/`) are unconditionally skipped … `.md` files inside dot-directories remain valid anchor targets (DI-006 case 3). **(DI-009)**"

DI-009 is "Scan Terminates for Any Input" (`invariants.md:235`). It says nothing about dot-directories or anchor targets. The governing invariant for both halves of this sentence is DI-006: `invariants.md:161-163` (case 3, dot-directory unconditional skip) and `invariants.md:167-170` (excluded files remain anchor targets). The sentence even names DI-006 case 3 mid-clause and then closes with a trailing `(DI-009)` attribution.

Compare the correctly-anchored sibling: `BC-2.01.001.md:55` (Invariant 3) — "Symlinked directories are NOT followed. (BC-2.01.004, DI-009)" — where DI-009 (termination) genuinely is the rationale.

The Traceability row (`:81`) compounds it: `L2 Domain Invariants | DI-009` only, with DI-006 absent despite being cited in the body.

**Predicate:** Full read of `invariants.md` DI-006 (lines 149-205) and DI-009 (lines 235-262) — DI-009 contains **0** occurrences of "dot-director", "anchor target", or "AnchorIndex"; DI-006 contains all three.

**Consequence:** A reader tracing why dot-directory `.md` files remain anchor targets is routed to the termination invariant, which does not support the claim. POLICY 4 mis-anchoring; blocks convergence.

---

### P7-S1-019 — BC-2.01.005 falsely claims D-012 is recorded in the frozen product brief [MEDIUM]

`.factory/specs/behavioral-contracts/ss-01/BC-2.01.005.md:43`:
> "This decision is recorded as D-012 in the product brief."

The frozen brief contains no D-012. `.factory/specs/product-brief.md` (read in full, 95 lines) records decisions D-004, D-009, D-043 and validation IDs BV-016, BV-019 at lines 88-95 — there is no D-011, no D-012, and no decision register. D-012 is recorded in the L2 decision log: `.factory/specs/domain-spec/decisions.md:71` — "| DD-019 | **D-012 (Human, Phase 1d gate)** | Discovery extension scope: `.md` files only, case-sensitive … | BRIEF.md R1, F-027 | CAP-001, MarkdownFile entity |". Note DD-019's own Source column cites "BRIEF.md R1" — i.e. the brief supports R1's `*.md`; the *decision* to read that as case-sensitive `.md`-only is a Phase-1d human decision recorded downstream, not in the brief.

The same BC's Traceability row compounds it: `BC-2.01.005.md:89` — "| Brief Requirement | R1, **D-012** |". D-012 is a decision ID, not a brief requirement; the brief's requirement set is exactly R1–R8 (`product-brief.md:35-53`).

**Predicate:** `Grep '^\*\*R[0-9]|R2a|R2b|R2c|^### R|D-011|D-012'` over `.factory/specs/product-brief.md` → **"No matches found"** (0 occurrences of D-011 and D-012 in the frozen brief). `Grep 'D-012|D-011'` over `decisions.md` → D-012 recorded at `:37` and `:71` as the source decision for DD-019.

**Consequence:** The frozen brief is the immovable authority for this project ("A spec contradicting the brief is a defect in the spec"). BC-2.01.005 attributes to it a decision it does not contain, which makes the D-012 provenance chain unauditable and invites a future reviewer to "correct" the brief. Cross-checking `BC-2.01.005.md:87-89` also shows the Brief Requirement row is polluted with a decision ID.

---

### P7-S1-020 — BC-2.01.005's Capability Anchor Justification row contains no justification [MEDIUM]

`.factory/specs/behavioral-contracts/ss-01/BC-2.01.005.md:87-88`:
```
| L2 Capability | CAP-001 ("File Discovery") per capabilities.md §CAP-001 — extension match is case-sensitive; .md only (D-012) |
| Capability Anchor Justification | CAP-001 ("File Discovery") per capabilities.md §CAP-001 |
```
The two cells' contents are inverted relative to every sibling in SS-01. The convention: L2 Capability = bare citation; Capability Anchor Justification = citation **plus** the reason this BC belongs under that capability. Siblings: `BC-2.01.001.md:79-80`, `BC-2.01.002.md:77-78`, `BC-2.01.003.md:78-79`, `BC-2.01.004.md:85-86`, `BC-2.01.006.md:71-72`, `BC-2.01.009.md:83-84` all follow it (e.g. BC-2.01.004:86 — "… — dot-dir policy and symlink safety are traversal constraints").

The result is that BC-2.01.005 — the BC that narrows discovery to exact-lowercase `.md`, i.e. the BC most likely to be challenged — carries **no** justification for its capability anchor, while the L2 Capability cell carries a descriptive clause that is not part of any capabilities.md text. POLICY 5 requires creators to justify anchors against the source-of-truth artifact.

**Predicate:** `Grep 'L2 Capability'`-adjacent full reads of all 9 SS-01 BC Traceability tables → 8 of 9 place the justification prose in the Justification row; **1 of 9** (BC-2.01.005) places it in the L2 Capability row and leaves the Justification row bare. BC-2.01.007:70-71 and BC-2.01.008:73-74 also carry bare citations in both cells (no justification prose at all).

**Consequence:** A reviewer auditing capability anchoring for the extension-filter contract finds an empty justification. Combined with BC-2.01.007 and BC-2.01.008 (both bare), 3 of 9 SS-01 BCs provide no anchor justification — POLICY 5 has `lint_hook: null`, so nothing detects it.

---

### P7-S1-021 — BC-2.02.001 uses two different quoted excerpts for CAP-002 in adjacent Traceability rows [MEDIUM]

`.factory/specs/behavioral-contracts/ss-02/BC-2.02.001.md:78-79`:
```
| L2 Capability | CAP-002 ("Parse each discovered Markdown file into a structured AST event stream using the CommonMark 0.31.2 + GFM grammar") per capabilities.md §CAP-002 |
| Capability Anchor Justification | CAP-002 ("Markdown Parsing") per capabilities.md §CAP-002 — this BC is the central parsing contract |
```
Both quotes are substantiated — `capabilities.md:62` is the H1 "## CAP-002: Markdown Parsing" and `capabilities.md:64-65` is "Parse each discovered Markdown file into a structured AST event stream using the / CommonMark 0.31.2 + GFM grammar (AST-based, not regex; pulldown-cmark 0.13.4)." (line-wrap collapsed; verbatim). Neither is fabricated. The defect is that the same anchor is quoted two different ways inside one document, and the long form violates the corpus's own settled convention.

That convention was set by a remediation the five SS-01 BCs received and SS-02 did not. Each of `BC-2.01.001.md:25`, `BC-2.01.002.md:25`, `BC-2.01.003.md:25`, `BC-2.01.004.md:25`, `BC-2.01.005.md:25` records verbatim: "v1.x: (WS-4/POLICY-5) L2 Capability citation-fidelity repair — fabricated quoted excerpt replaced with **verbatim CAP-001 heading** 'File Discovery' per capabilities.md §CAP-001." BC-2.02.001's changelog (`:23-25`) has no WS-4/POLICY-5 entry. The other three SS-02 BCs happen to already use the heading form (`BC-2.02.002.md:101`, `BC-2.02.003.md:72`, `BC-2.02.004.md:71`), leaving BC-2.02.001 as the sole non-conforming file.

**Predicate:** `Grep '\.markdown'`-adjacent reads of all 13 changelogs → the WS-4/POLICY-5 repair entry appears in **5 files**, all SS-01 (BC-2.01.001/.002/.003/.004/.005), **0 files** in SS-02. `Grep 'CAP-002'` across ss-02 → 8 citations; 7 use `("Markdown Parsing")`, **1** (BC-2.02.001:78) uses the body-prose excerpt.

**Consequence:** Partial-fix propagation gap: the WS-4/POLICY-5 sweep stopped at the subsystem boundary. `check-title-sync.py` (POLICY 7/13) validates BC H1 ↔ BC-INDEX ↔ PRD titles, not capability-excerpt form, so the inconsistency is unlinted. A future POLICY-5 audit will re-flag this file.

---

### P7-S1-022 — Scan-set disposition of a dangling `*.md` symlink is undefined; exit 1 vs exit 2 turns on it [MEDIUM]

`.factory/specs/behavioral-contracts/ss-01/BC-2.01.006.md:44-45` (Postconditions):
```
1. If the symlink target exists: the file is included in the scan set and processed normally.
2. If the symlink target does not exist (dangling): any Markdown link to this path receives verdict `broken` with reason `broken-symlink`.
```
PC2 specifies only the *link-resolution* outcome. It says nothing about what happens to the dangling symlink itself when traversal encounters it as a candidate scan-set member — the case PC1's structure implies. Two dispositions are available and they differ in exit code:

- **Silent skip** (non-regular file). Precedent: `test-vectors.md:91` (TV-020/EC-020) — "FIFO named `pipe.md` in the tree | (none) | 0 | none | **Non-regular files skipped silently**". Result: exit 1 from the broken link only.
- **Scan-set read failure.** `BC-2.01.009.md:53` (PC2) — "For an unreadable file encountered during scan: a `target-unreadable` I/O error is recorded … final exit code is 2". `invariants.md:192-194` — "**only** read failures on files **in the scan set** (reached by Pass 1 traversal) contribute to `io_errors` and the exit-2 path." A dangling symlink named `foo.md` matches the extension filter, so whether it is "in the scan set" decides whether opening it produces an `io_errors` entry.

`.factory/specs/prd-supplements/test-vectors.md:116` (TV-038/EC-038) covers only the link-target direction (`[x](link.md)` where `link.md` dangles → exit 1, `broken-symlink`), never a dangling symlink present in the tree as a discovery candidate. BC-2.01.006's own edge-case table (`:53-55`) cites only EC-038 and EC-028b.

**Predicate:** `Grep 'symlink'` over `.factory/specs` excluding `ss-01/` → 45 results returned (paginated; full-corpus magnitude not established by predicate). None of the returned rows specifies scan-set membership for a dangling symlink whose name matches the `.md` filter; `invariants.md:191` mentions `broken-symlink` only as a Pass-1.5 *target* verdict.

**Consequence:** A repository containing one dangling `docs/legacy.md` symlink and one genuinely broken link exits **1** under the skip reading and **2** under the read-failure reading. Exit 2 means "the scan was incomplete" (`invariants.md:284-285`) and in CI is often wired differently from exit 1, so the two readings produce different pipeline behavior for identical repository content.

---

### P7-S1-023 — BC-2.02.002 PC5/Invariant 5 describe column as a buffer-global offset; §9 and its own test vector say line-relative [MEDIUM]

`.factory/specs/behavioral-contracts/ss-02/BC-2.02.002.md:62-63` (PC5):
> "Column numbers reported in findings are **measured from position 0 of the BOM-stripped, LF-normalized string buffer** — NOT from raw byte offset 0."

`.factory/specs/behavioral-contracts/ss-02/BC-2.02.002.md:73-74` (Invariant 5):
> "**Column counting starts at 1 from the first character in the buffer** (after BOM removal)."

Both formulations describe a whole-buffer offset. The authoritative definition is line-relative: `.factory/specs/prd-supplements/interface-definitions.md:244` (§9 Column Reporting) — "Column is the 1-based byte offset of the opening `[` **within the source line**." `BC-2.02.001.md:55` agrees — "columns are 1-based byte-offset **within the line**."

BC-2.02.002's own first test vector proves the intended reading and contradicts its normative text: `:88` — "BOM + `## Setup\n[x](#setup)` | Exit 0; clean; **line 2, column 1** (BOM stripped; buffer starts at `#`)". Under PC5 read literally, that `[` sits at buffer byte offset 9, so column would be 10, not 1. The two clauses are only equivalent for findings on line 1 — which is the only case PC5's illustration and both of BC-2.02.002's BOM vectors exercise.

**Predicate:** `Read interface-definitions.md:242-252` → §9 defines column as "within the source line"; F-028 buffer note at `:246-249` scopes the *buffer choice*, not the *offset origin*. BC-2.02.002 lines 62-63 and 73-74 contain **0** occurrences of "line" as the offset frame.

**Consequence:** An implementer following PC5/Invariant 5 literally emits buffer-global byte offsets in the `column` field. Every finding after line 1 gets a wrong column. That corrupts the DI-001 four-field sort key (`invariants.md:63-64` — "(NFC-normalized file path, line number, **column number**, link target)"), so VP-011's determinism proptest still passes (the key is still total) while `tests/corpus/manifest.json` diffs fail on every multi-line fixture (`interface-definitions.md:275-278` — "**direct comparison** … the same `column` field is present").

---

### P7-S1-024 — EC-028b and EC-006b name scenarios absent from the registry; the ID checker is structurally blind to sub-letters [MEDIUM]

Two unregistered sub-lettered EC IDs, distinct from P7-S1-013:

**`EC-028b`** — `.factory/specs/behavioral-contracts/ss-01/BC-2.01.006.md:55` — "| EC-028b | Symlink to valid file |". Its base is semantically unrelated: `test-vectors.md:106` (TV-028/EC-028) is "`[x](a.md \"Some title\")`, `[x](a.md 'title')`, `[x](a.md (title))` … Titles stripped; all three forms". There is no registered vector anywhere for "symlink to a valid file", so BC-2.01.006's second canonical test vector (`:61` — "`link.md` is symlink to valid `target.md` | Exit 0; clean") is unregistered.

**`EC-006b`** — `.factory/specs/behavioral-contracts/ss-01/BC-2.01.005.md:67` — "| EC-006b | `notes.mdown` **or** `notes.mdx` |". Two problems: (a) one EC ID naming two alternative scenarios is the injectivity defect POL-16 targets; (b) `.mdown` appears nowhere in the registry — `test-vectors.md:76` (TV-006) covers only `notes.markdown` and `notes.mdx`, and DD-019 (`decisions.md:71`) enumerates only `.MD`, `.markdown`, `.mdx` as non-goals. `EC-006a` (`BC-2.01.005.md:66`) splits TV-006's single row without registry authorization.

`check-id-resolution.py` cannot detect any of these. Lines 159-161: "Sub-lettered variants EC-NNNx (e.g. EC-015b, EC-094a) are valid **if their base EC-NNN is registered**." Lines 193-196 pre-populate `EC-NNNa` through `EC-NNNz` for every registered base. So `EC-028b` resolves because `EC-028` (titles) exists, and `EC-006b` resolves because `EC-006` exists — regardless of whether the sub-lettered scenario is registered or even semantically related.

**Predicate:** `Grep 'EC-006a|EC-006b|EC-015b|EC-028b|EC-011\b'` over `.factory/specs` → **5 matches**; EC-006a, EC-006b, EC-028b appear **only** in the BC files (BC-2.01.005.md:66,67; BC-2.01.006.md:55) and **zero** times in `test-vectors.md`. `Grep 'AMB|EC-|PREFIX|prefix|REGISTR|registr'` over `scripts/spec-lint/check-id-resolution.py` → sub-letter auto-registration at lines 159-161, 193-196.

**Consequence:** Three edge cases in this shard have no registered vector, so the test-writer has nothing to build from, and POLICY 16's checker reports them resolved. The checker's sub-letter whitelist is a false-green generator for any BC that invents `EC-NNNx` on top of an unrelated base — exactly the D-057 pattern ("an ID resolver silently skipping non-conforming shapes").

**Tag:** [process-gap]

---

### P7-S1-025 — BC-2.01.003 Invariant 3 is an unresolved deferral in a frozen phase-1d spec [MEDIUM]

`.factory/specs/behavioral-contracts/ss-01/BC-2.01.003.md:57` (Invariant 3):
> "`--no-ignore-vcs` (**not a planned flag in v1.0 — defer to architecture**) would override this behavior; today the behavior is always-on."

Three problems:
1. **The deferral never resolved.** The architecture phase completed (this BC's own v1.6 entry records the Phase-1b architect pass, `:24`). `--no-ignore-vcs` appears nowhere in `interface-definitions.md`'s CLI surface, and it is absent from D-011's dropped-flag list — `VP-INDEX.md:275` — "Dropped flags (D-011): `--quiet`, `--offline`, `--insecure`, `--hidden`"; `decisions.md:70` (DD-018) lists the same four. So the flag is neither adopted nor formally dropped.
2. **Not an invariant.** An invariant states a property that holds for all inputs. This states a counterfactual about a flag that does not exist. Contrast BC-2.01.004's Invariant 1 (`:56`), which converts the same situation into a real invariant: "ALL dot-directories are unconditionally excluded. **No flag overrides this** (D-011: `--hidden` is a non-goal)."
3. **Provenance.** `.factory/planning/brief-validation.md:213` shows `--no-ignore-vcs` was AMB-003's suggested resolution ("Respect `.gitignore` + nested; `--no-ignore-vcs` to disable"). BC-2.01.003 carried the suggestion forward as an open item instead of resolving it.

**Predicate:** `Grep 'AMB-'`-driven read of `brief-validation.md:213` (AMB-003 verbatim) and `VP-INDEX.md:275` + `decisions.md:70` (D-011 dropped-flag list = 4 flags, `--no-ignore-vcs` not among them).

**Consequence:** A story writer reading BC-2.01.003 sees an unresolved flag question at the moment of implementation. The correct D-011-style treatment ("no flag overrides this") is available in a sibling BC and was not applied here, so the `.gitignore` behavior lacks the "unconditional, no override" guarantee its dot-dir counterpart has.

---

### P7-S1-026 — BC-2.01.003 EC-002 fixture size diverges from the registry by 5× [MEDIUM]

`.factory/specs/behavioral-contracts/ss-01/BC-2.01.003.md:62`:
```
| EC-002 | `node_modules/**/*.md` (5000 files) |
```
`.factory/specs/prd-supplements/test-vectors.md:72` (TV-002/EC-002) — "Directory with `node_modules/foo/bar.md` (**1000** `.md` files inside node_modules) | (none) | 0 | (clean) | `node_modules` is excluded via `.gitignore`".

test-vectors.md is the EC registry (`check-id-resolution.py:16` — "EC-NNN -> prd-supplements/test-vectors.md (TABLE ROWS only)") and is authoritative for the fixture. 5000 also sits oddly against the R8 budget the BC invokes at `:38-40` ("blowing the R8 performance budget"): R8 is "500 markdown files … under 5 seconds" (`product-brief.md:52-53`), and NFR-001/NFR-002 are calibrated to 500 files (`system-overview.md:204-206`).

**Predicate:** `Read test-vectors.md` in full → TV-002 row states 1000. `Grep 'EC-002'`-adjacent read of BC-2.01.003.md:62 → states 5000. Divergence: 1 site, 5× magnitude.

**Consequence:** A test-writer generating the EC-002 fixture from the BC builds 5000 files; from the registry, 1000. The fixture is the `.gitignore`-performance guard for BC-2.01.003, so the size determines whether the test is a meaningful R8 exercise or a 5× overrun of the stated NFR calibration point.

---

### P7-S1-027 — Which path is reported for a followed file symlink is undefined, and it feeds the DI-001 sort key [MEDIUM]

`.factory/specs/behavioral-contracts/ss-01/BC-2.01.004.md:53` (PC3) — "If the entry is a symlink pointing to a file: follow and include **the target file** if it matches extension rules."
`.factory/specs/behavioral-contracts/ss-01/BC-2.01.006.md:44` (PC1) — "If the symlink target exists: **the file** is included in the scan set and processed normally."

Neither says (a) whether the extension filter applies to the symlink name or the target name, nor (b) which path is recorded on the resulting `Finding`. Both matter:

- **(a)** `link.md -> notes.txt` and `link.txt -> notes.md` get opposite dispositions under the two readings. BC-2.01.005's rule is stated over "a file path … evaluated for inclusion" (`:48-49`) without disambiguating symlink vs target.
- **(b)** The reported path is the primary field of the DI-001 sort key — `invariants.md:63` — "sorted by `(NFC-normalized file path, line number, column number, link target)`" — and the `file` field of every text and JSON finding (`capabilities.md:222`, `interface-definitions.md:285`). It interacts directly with P7-S1-001: BC-2.01.007's dedup key "resolves … symlinks" (`:46`), so a symlink and its target collapse to one scan-set entry whose *reported* path is then undetermined.

`.factory/specs/prd-supplements/test-vectors.md` has no vector for a `.md` symlink discovered during traversal — TV-038 (`:116`) is a dangling *link target*; TV-009 (`:79`) is a directory symlink; EC-028b is unregistered (P7-S1-024).

**Predicate:** `Grep 'symlink'` over `.factory/specs` excluding `ss-01/` → 45 results returned (paginated; full-corpus magnitude not established by predicate). None specifies the reported path for a followed file symlink; `module-decomposition.md:69-70` and `purity-boundary-map.md:58` define `EntryKind::Symlink { dangling: bool }` for *resolution*, not for scan-set path recording.

**Consequence:** Two runs of the same repository on two checkouts (one with symlinked docs, one with copies) produce different `file` values in output for the same content — a reproducibility gap in the field DI-001 sorts on. VP-011 (`VP-INDEX.md:67`) proves the sort is deterministic given a key; it cannot detect that the key's first field is under-specified.

---

### P7-S1-028 — test-vectors.md cites a BC-2.02.002 version that does not exist [MEDIUM]

`.factory/specs/prd-supplements/test-vectors.md:62-65` (Column offset note, F-028):
> "All `column` values in this file refer to the 1-based byte offset within the **BOM-stripped, LF-normalized** buffer … See **BC-2.02.002 Invariant (added v1.4)**."

BC-2.02.002 is at **v1.3** (`BC-2.02.002.md:4` — `version: "1.3"`) and its changelog records the F-028 change at **v1.2**: `BC-2.02.002.md:24` — "v1.2: (F-028) added PC5 and Invariant 5 — both line AND column numbers are relative to the BOM-stripped, LF-normalized buffer". `.factory/specs/prd.md:664` corroborates the correct version — "**F-028** (column relative to BOM-stripped buffer): **BC-2.02.002 v1.2** — PC5 and Invariant 5 added".

So the pointer that governs the interpretation of *every* `column` value in the test-vector registry names a nonexistent BC revision, and does so two versions off.

**Predicate:** `Read BC-2.02.002.md` in full → `version: "1.3"`, F-028 recorded at v1.2 (`:24`), no v1.4 entry. `Grep 'AMB-'` over `prd.md` → `:664` states v1.2. `Read test-vectors.md:62-65` → states v1.4.

**Consequence:** A reader validating that the column convention is actually specified follows the citation, finds BC-2.02.002 at v1.3, cannot locate a "v1.4 Invariant", and cannot confirm whether the F-028 fix landed. Given that BC-2.02.002's PC5/Invariant 5 text is itself ambiguous (P7-S1-023), a stale pointer removes the one cross-check that would surface the ambiguity.

---

### P7-S1-029 — BC-2.01.002's Related-BC relation is reversed and misuses lifecycle vocabulary [LOW]

`.factory/specs/behavioral-contracts/ss-01/BC-2.01.002.md:85`:
```
- BC-2.01.001 — superseded by (explicit PATH overrides default root)
```
Read in the section's own grammar ("`<target>` — `<relation>`"), this asserts *BC-2.01.002 is superseded by BC-2.01.001* — the reverse of the parenthetical. The reciprocal entry in BC-2.01.001 uses a different relation for the same pair: `BC-2.01.001.md:87` — "BC-2.01.002 — depends on (explicit PATH overrides this default)".

Separately, "superseded by" is BC lifecycle vocabulary (`BC-2.01.001.md:26-31` frontmatter has `deprecated_by`, `replacement`; BC-2.01.001's `lifecycle_status` is `active`, `:20`). BC-2.01.001 is not superseded by anything — the relation being described is a runtime precedence (explicit PATH wins over default root), not a lifecycle supersession. POLICY 1 keeps retired/superseded status in the indexes; `BC-INDEX.md:32` lists BC-2.01.001 as active P0.

**Predicate:** `Grep 'BC-2\.01\.'` over `BC-INDEX.md` → `:32` lists BC-2.01.001 active P0, no supersession. Reciprocal relation labels differ: BC-2.01.001:87 "depends on" vs BC-2.01.002:85 "superseded by" for the same pair.

**Consequence:** Editorial, but it puts lifecycle-supersession language on an active P0 contract. An automated relation-graph extraction would record BC-2.01.002 as superseded.

---

### P7-S1-030 — BC-2.01.005's extension rule is stated two incompatible ways; a file named `.md` is classified differently by each [LOW]

`.factory/specs/behavioral-contracts/ss-01/BC-2.01.005.md:39-40` (Description) — "Extension matching uses a case-sensitive byte comparison of **the final suffix after the last `.`** in the filename."
`.factory/specs/behavioral-contracts/ss-01/BC-2.01.005.md:58` (Invariant 1) — "Extension matching is case-sensitive byte comparison of **the exact string `.md`**."

The two disagree on whether the dot is part of the compared string ("md" vs ".md"), and they diverge on a real input: a file named literally `.md`. Under the Description's rule the final suffix after the last `.` is `md` → **included**. Under Rust's `Path::extension()` — the natural implementation of "the exact string `.md`" — a leading-dot-only filename has no extension → **excluded**. Nothing else covers it: `.md` is a hidden *file*, not a dot-directory, so BC-2.01.004's unconditional dot-dir skip (`:51`, `:56`) does not apply, and no BC in SS-01 addresses hidden files.

`.factory/specs/behavioral-contracts/ss-01/BC-2.01.005.md:45` adds a third formulation — "The `ignore` crate's WalkBuilder is configured with a case-sensitive filter for the exact string `.md`" — without stating whether the filter matches on `Path::extension()` or on a filename suffix.

**Predicate:** `Grep '\.markdown'` over `behavioral-contracts` → BC-2.01.005 is the extension-rule owner (5 matches: `:23`, `:38`, `:43`, `:53`, `:59`); `Read BC-2.01.005.md` in full → three non-identical formulations of the matching rule at `:39-40`, `:45`, `:58`. No test vector for a file named `.md` in `test-vectors.md` §1.

**Consequence:** Narrow, and an implementer would likely recover from the test vectors (`:73-77`, which cover `README.MD`, `notes.mdx`, `notes.markdown`, `README.md`). But the rule that defines the entire scan set is stated three ways in one document, and the one input where the readings diverge has no vector.

---

### P7-S1-031 — BC-2.02.001's CRLF test vector diverges from the EC-016 scenario it cites [LOW]

`.factory/specs/behavioral-contracts/ss-02/BC-2.02.001.md:60` cites edge case "| EC-016 | CRLF file |", and its canonical test vector at `:68` reads "| CRLF file with link on **line 5** | Reported at line 5, same as LF | edge-case |".

The registry's EC-016 scenario places the elements differently: `.factory/specs/prd-supplements/test-vectors.md:87` (TV-016/EC-016) — "CRLF-only file with `## Heading` on **line 5**, `[x](#heading)` on **line 10** | (none) | 0 | (clean) | Line numbers same as LF equivalent". The sibling BC's vector matches the registry's structure more closely by using its own explicit fixture (`BC-2.02.002.md:82` — "| EC-016 | CRLF file; link on line 10 |").

**Predicate:** `Read test-vectors.md:87` → EC-016 places the link on line 10 and the heading on line 5, expected exit 0 (clean). `BC-2.02.001.md:68` places the link on line 5 with no heading and no exit code.

**Consequence:** Editorial. A test-writer reconciling BC-2.02.001's vector against TV-016 must decide whether they are the same test; the BC's version also omits the expected exit code that TV-016 specifies.

---

## Notes on coverage and what was checked clean

- **POLICY 7 / 13 (title sync):** All 13 H1 headings match `BC-INDEX.md:32-40` and `:48-51` character-for-character. Clean.
- **POLICY 6 (subsystem names):** `ARCH-INDEX.md:64-65` registers SS-01 = "File Discovery" (module `scanner`) and SS-02 = "Markdown Parsing" (modules `scanner`, `link_extractor`). All 13 `subsystem:` frontmatter values and all `scanner.rs (SS-0x …)` Architecture Module labels are consistent with the registry — the shared `scanner` module across two subsystems is authorized. Clean.
- **POLICY 18 (holdout boundary):** Active holdout pool is EC-079, EC-093, EC-094, EC-141, EC-147, EC-148, EC-151, EC-156, EC-165, EC-166, EC-167, EC-168 (`test-vectors.md:28-29`). **Predicate:** none of these IDs appears in any of the 13 bodies (the only EC IDs cited are EC-001..EC-016, EC-038, EC-125, EC-184, EC-185, plus the four unregistered sub-lettered IDs in P7-S1-013/024). Clean.
- **POLICY 19 (reason codes) — the in-taxonomy ones:** `broken-symlink` (BC-2.01.006:45, :60) and `target-unreadable` (BC-2.01.009:53, :59; BC-2.02.003:45, :50, :62) are verbatim members of the 13-code closed set (`error-taxonomy.md:100-102`). `file-not-found` (BC-2.01.006:49) is verbatim. The only phantom code is `E-IO-002` (P7-S1-003).
- **Quoted-excerpt substantiation (POLICY 5):** All `per capabilities.md §CAP-00N ("…")` excerpts in the 13 bodies were opened and verified. `CAP-001 ("File Discovery")` matches `capabilities.md:49` verbatim (9 sites). `CAP-002 ("Markdown Parsing")` matches `capabilities.md:62` verbatim (7 sites). The long CAP-002 excerpt at `BC-2.02.001.md:78` matches `capabilities.md:64-65` verbatim modulo line-wrap. **No fabricated excerpts found in this shard**; the only excerpt defect is the intra-document inconsistency in P7-S1-021.
- **Code fences:** Zero ```rust fences appear in any of the 13 bodies. **Predicate:** no fenced code blocks present. The symbol references in prose (`Vec<IoError>`, `pulldown_cmark::Parser::new()`, `Parser::into_offset_iter()`, `verdict::exit_code`, `AnchorIndex`, `DirIndex`, `Path::exists()`) were each checked against `api-surface.md`, `module-decomposition.md`, `purity-boundary-map.md`, and `system-overview.md`; the two that fail are `Parser::new()` (P7-S1-002) and `Path::exists()` (P7-S1-008).
- **`.md`-only discovery scope (hunt item 3):** No BC in this shard widens or narrows the `.md`-only, case-sensitive rule *for traversal*. The one leak is `.markdown` reintroduced as a Markdown extension in BC-2.02.004's precondition (P7-S1-009).
- **Not established by predicate:** the corpus-wide resolvability of the AMB-* family. `Grep 'AMB-'` over `.factory/specs` → 57 occurrences / 29 files, of which 24 are BC files across every subsystem; the register itself lives at `.factory/planning/brief-validation.md` (AMB-002/003/006/007/008/009/010/011/028 all confirmed present there at lines 212-243), which is outside the frozen spec-corpus root but is a declared `inputs:` entry of every BC. Because the pattern spans all shards rather than SS-01/SS-02, its primary subject is outside this shard and it is not filed as a finding here.