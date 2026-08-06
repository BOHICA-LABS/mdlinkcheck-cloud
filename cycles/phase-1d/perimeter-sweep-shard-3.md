---
document_type: adversarial-findings
cycle: phase-1d
shard: 3
frozen_head: 1d3ed17
scope: "SS-07 path resolution, all 8 BC bodies read in full"
counts:
  critical: 7
  high: 12
  medium: 9
  total: 28
verdict: "SS-07 NOT adequately specified for macOS-only/APFS; must NOT enter Phase 2 story decomposition"
produced: 2026-08-07
producer: adversary
---

# Adversarial Findings — Perimeter Sweep Shard 3

**Scope:** SS-07 path resolution — all 8 BC bodies read in full
**Frozen HEAD:** `1d3ed17`
**Finding counts:** 7 CRITICAL / 12 HIGH / 9 MEDIUM = 28
**Verdict:** SS-07 NOT adequately specified for macOS-only/APFS; must NOT enter Phase 2 story decomposition

---

## CRITICAL

### P6-S3-001 (POLICY 4/16) — DirIndex population scope CONTRADICTORY; no SS-07 BC constrains it

purity-boundary-map.md:107-110 defines DirIndex as parents of EVERY extracted link destination; system-overview.md:126-128 defines it as only parents of .md targets NOT in AnchorIndex. Since `path_resolver` never calls `fs::*` (purity-boundary-map.md:55) and takes only `(dest, src_dir, index)` (api-surface.md:89), the narrow reading makes these all false `broken(file-not-found)`:

- `[x](../README.md)` where README.md WAS scanned — breaks TV-022 and nearly every happy-path relative link, leaving BC-2.07.003 nothing to compare against so DI-002/VP-008 go inert
- `[x](logo.png)`, `[x](notes.txt#s)` — breaks BC-2.07.006, TV-039/072/073
- `[x](docs/)` — breaks BC-2.07.005, TV-029/030

NONE of the 8 SS-07 BCs mentions DirIndex/DirEntryInfo/EntryKind (grep-verified; only ss-05/BC-2.05.001.md:47 mentions DirIndex at all). Nearest is BC-2.07.003.md:49 "parent directory is READABLE" — an fs property, not the actual precondition ("parent is present as a key in DirIndex"). Broad reading also breaks DI-009's termination argument, which is derived from the .md one-level bound (invariants.md:236-238).

**CORROBORATES** pass-5 P5-003. **REQUIRES ARCHITECT/HUMAN ADJUDICATION BEFORE ANY OTHER SS-07 FIX** — BC-2.07.002 postconditions, BC-2.07.003 preconditions, BC-2.07.005/006 routing and DI-009's bound all depend on the answer.

---

### P6-S3-002 (POLICY 4) — BC-2.07.001 Invariant 3 mandates fs::* inside the pure core

BC-2.07.001.md:52 Invariant 3 mandates existence-checking "using filesystem APIs" INSIDE the pure core, contradicting purity-boundary-map.md:55, BC-2.07.003.md:60 ("NEVER uses Path::exists() alone") and api-surface.md:89. purity-boundary-map.md:45: violating the boundary "invalidates Kani proof harnesses" — destroys VP-008, the sole macOS gatekeeper. Anti-pattern already has precedent at ss-01/BC-2.01.006.md:48.

---

### P6-S3-003 (POLICY 16/19) — BC-2.07.004 fragment decode contradicts DI-003/CAP-008

BC-2.07.004.md:38-39,:49 asserts the fragment is NOT percent-decoded and cites DI-003 as authority — but DI-003 (invariants.md:103) says "each component IS percent-decoded independently", CAP-008 (capabilities.md:139) says "percent-decode the fragment before comparison", CAP-007 (:130) says "fragment split BEFORE decode".

Live defect: `[x](a.md#caf%C3%A9)` vs a `## Café` heading = clean under DI-003/CAP-008, false `broken(anchor-not-found)` under BC-2.07.004.

---

### P6-S3-004 (POLICY 16) — BC-2.07.001 test vector invents scan-root boundary denied by TV-024

BC-2.07.001.md:67 test vector invents a scan-root boundary ("path escapes root -> broken") that the canonical registry explicitly denies: test-vectors.md:102 TV-024 states relative resolution "has NO scan-root boundary / no path-above-scan-root enforcement" and expects clean. DI-006 case 4 (invariants.md:158-159) treats above-root targets as legitimate. Vector is also underivable from the BC's own postconditions.

---

### P6-S3-005 (POLICY 16) — BC-2.07.002 root-relative rule and TV-041 mutually unsatisfiable

BC-2.07.002.md:41,:45 (leading `/` -> `git_root.join(strip_prefix)`) and test-vectors.md:119 TV-041 (`[x](/dev/null)` -> clean) are mutually unsatisfiable; under the BC, `/dev/null` becomes `<git_root>/dev/null` -> broken. No BC carves out a genuine absolute path that exists. No VP covers either.

---

### P6-S3-006 (POLICY 4) — BC-2.07.006 Description stale after D-012 precondition change

BC-2.07.006.md:34-35 Description says non-.md "or .markdown (case-insensitive)" gets existence-only, while its own Precondition 3 (:46-48) says extension must be NOT exactly `.md` CASE-SENSITIVE and explicitly lists `.MD`/`.Md`/`.markdown` as falling INTO this contract. decisions.md:71 (DD-019/D-012) matches the Precondition. prd.md:609 records only "Precondition 3 updated" — the D-012 remediation left the Description prose behind; every sibling BC recorded the fix in prose.

---

### P6-S3-007 (POLICY 4/9) — BC-2.07.001 mis-anchors VP-008 to two wrong properties

BC-2.07.001.md:72-73 mis-anchors VP-008 to TWO properties that are not VP-008 ("fragment stripped before path resolution", ".. resolution is logical") with proof method "unit test". VP-INDEX.md:64 = `vp-008-path-nfc-comparison`, module `path_resolver`, PROPTEST, P1, DI-002; fragment-split is VP-004 (kani, module fragment).

**DIRECTLY LOAD-BEARING under D-045:** a story implementing this VP table writes two fragment/.. unit tests, marks VP-008 satisfied, and the NFC + case-sensitivity proptest is NEVER WRITTEN.

---

## HIGH

### P6-S3-008 — BC-2.07.002 demands git subprocess inside declared pure core

BC-2.07.002.md:35-36,:53 requires `git rev-parse --show-toplevel` from a module declared "pure core, CRITICAL tier" (:80); purity-boundary-map.md:40-41 forbids `process::*` in the pure core; `resolve_path` has NO repo-root parameter, so root-relative resolution is unimplementable at the specified seam. No git subprocess appears in the effectful-shell inventory (purity-boundary-map.md:77-81) — git is an undeclared runtime dependency owned by no module.

---

### P6-S3-009 — BC-2.07.002 silent git fallback makes verdicts host-dependent

BC-2.07.002.md:53 "if git is not in PATH, falls back SILENTLY" makes root-relative verdicts a function of the host, contradicting DI-002's rationale (invariants.md:89-93) and ADR-006:80-88. git absent / not-a-repo / corrupt / `safe.directory` refusal all silently flip every root-relative link to a different root with no diagnostic. Invariant asserts determinism but the mechanism guarantees only intra-run consistency, not the cross-environment reproducibility NFR-003/DI-001 demand. Also: resolving `git` from PATH is untrusted-binary execution in CI, addressed nowhere.

---

### P6-S3-010 (POLICY 16) — BC-2.07.002 non-git fallback contradicts AMB-018

BC-2.07.002.md:37-38,:46,:52 non-git fallback = "deepest common ancestor of all PATH arguments"; prd.md:302 AMB-018 authoritatively says "the FIRST PATH argument (or CWD)". For `mdlinkcheck docs/ other/` these differ (`.` vs `docs/`). Also undefined for a single FILE argument.

---

### P6-S3-011 (POLICY 4) — BC-2.07.002 precondition has no scheme exclusions; conflicts with ss-03

BC-2.07.002.md:41 precondition (starts with `/`) has NO scheme/classification exclusions, so `[x](//example.com/x)` satisfies both it and ss-03/BC-2.03.005.md:37,:59 (protocol-relative -> silently skipped, clean) with no precedence rule -> TWO VERDICTS, violating DI-005. BC-2.07.001.md:40 DOES carry the exclusion list; BC-2.07.002 is the unswept sibling.

---

### P6-S3-012 (POLICY 4, security) — No BC bounds `..`/root-relative traversal; APFS leaks existence

No SS-07 BC bounds `..`/root-relative traversal. test-vectors.md:310 T16 states the gap: "boundary enforcement for root-relative paths is UNTESTED". BC-2.07.002 PC1 does `git_root.join(strip_prefix)` with no normalization or containment check; system-overview.md:128 then `fs::read_dir`s the parent of each destination. A hostile markdown file in an untrusted PR (`[x](/../../../../Users/victim/.ssh/id_rsa)`) drives `read_dir` outside the repo and the report output leaks per-path EXISTENCE into CI logs. TV-024 affirmatively blesses `/etc/passwd` as clean.

---

### P6-S3-013 (POLICY 2/4/19) — Symlinks essentially absent from SS-07; broken-symlink has no SS-07 contract

"symlink" appears once in SS-07 (BC-2.07.006.md:45); that precondition is UNDECIDABLE at the pure seam because `EntryKind` is `File|Dir|Symlink{dangling}` (purity-boundary-map.md:98), so `Symlink{dangling:false}` does not distinguish file- from directory-target. Consequences:

- (a) symlink-to-directory with a fragment matches NEITHER BC-2.07.005 (requires Dir) nor BC-2.07.006 (requires regular file) -> NO VERDICT -> DI-005 violation
- (b) `broken-symlink` is assigned to `path_resolver` by purity-boundary-map.md:66-68 and expected from Pass 2 by ss-05/BC-2.05.001.md:70, yet error-taxonomy.md:152 anchors it to BC-2.01.006, a traversal contract in the effectful shell whose mechanism is `Path::exists()`. No SS-07 BC specifies `Symlink{dangling:true}` -> `broken(broken-symlink)`.

One of the 13 closed reason codes has no contract in the subsystem that architecturally produces it.

---

### P6-S3-014 (POLICY 16) — Brief-Requirement mis-citation in 5 of 8 SS-07 BCs

BC-2.07.001.md:81 (R5,R6,T7), .002:79 (R5), .004:82 (R5,R6,T9), .005:94 (R5), .006:92 (R5) — but BRIEF.md:25 R5 is `--ignore`/`--allow` and :27 R6 is output format; CAP-007's grounding is R2a (capabilities.md:132). BC-2.07.003/.007/.008 correctly cite R2a. POLICY 16's verification step names this verbatim ("link validation is R2a/R2b/R2c, not R5/R6", origin F-020) — fix landed on 3 siblings, missed 5.

---

### P6-S3-015 (POLICY 16) — Query-string stripping specified in no BC; TV-033 unbacked

Query-string stripping is specified in NO BC anywhere. test-vectors.md:111 TV-033 (`[x](a.md?raw=1)` -> clean, "query stripped before resolution") is unbacked; grep for `query` across all specs returns only TV-033. DI-003 covers only the `#` split. An implementer building from the 8 SS-07 contracts resolves a filename literally containing `?raw=1` -> false broken on a very common real-world pattern.

---

### P6-S3-016 (POLICY 16/4) — Five mis-anchored EC citations with wrong-description ids

FIVE mis-anchored EC citations whose descriptions are not those ids' canonical scenarios: BC-2.07.001 EC-023 (canonical = root-relative, belongs to BC-2.07.002), EC-024 (canonical = `../../../../etc/passwd` -> clean), EC-025 (canonical = percent-decode, belongs to BC-2.07.004); BC-2.07.004 EC-033 (canonical = `a.md?raw=1` query stripped), EC-035 (canonical = path normalization). BC-2.07.003/.005 v1.2 EC-collision sweeps fixed the COLLIDING ids and left the silently WRONG-DESCRIPTION ids.

---

### P6-S3-017 (POLICY 9/4) — VP proof-method/property drift in three BCs; VP-008 regressed by D-043 edit

BC-2.07.003.md:83 claims VP-008 is "integration test (macOS only per D-043)" vs VP-INDEX proptest P1 — its own v1.3 changelog records "VP-008 proof method UPDATED to macOS-only", i.e. the D-043 edit REGRESSED it, undoing ADR-006 v1.1's explicit remediation. BC-2.07.003.md:84 describes VP-009 as "NFC-normalized comparison is applied" which is VP-008's property, not idempotency, so VP-009 has NO BC describing what it actually proves. BC-2.07.004.md:73-74 claims VP-004 as unit test x2 vs VP-INDEX kani P0.

---

### P6-S3-018 (POLICY 2/4) — ADR-006 non-UTF-8 behaviour has NO enforcing BC; OsString seam broken

ADR-006:111-128's complete non-UTF-8 directory-entry behaviour (skip from comparison pool, `broken(file-not-found)`, stderr `[warn] non-UTF-8 directory entry skipped`, exit code NOT raised to 2) has NO enforcing BC — zero hits for non-UTF-8/OsStr/that warning across ss-07/. Compounding: ADR-006:68-74 requires the pure core receive only `&str` with the shell converting, but api-surface.md:92 and purity-boundary-map.md:99 both define `DirEntryInfo{name: OsString}`, so the conversion point is unreachable while purity-boundary-map.md:55 assigns NFC comparison on entry names to `path_resolver` — which per ADR-006's own reasoning cannot NFC-normalize an `OsString`. On macOS-only this is the seam where the ONLY NFD->NFC normalization happens.

---

### P6-S3-019 (POLICY 2/16) — `canonicalize_logical()` is a PHANTOM API; DI-009's warning uncited in SS-07

`canonicalize_logical()` at BC-2.07.001.md:44 is a PHANTOM API (1 hit corpus-wide, absent from api-surface.md). DI-009's explicit "NOT `fs::canonicalize`, which case-normalizes on macOS APFS and would conflict with DI-002" (invariants.md:234-236) is cited by ZERO SS-07 BCs (BC-INDEX.md:214 maps DI-009 only to BC-2.01.001/004 and BC-2.05.001) — yet SS-07 is where `./..` normalization happens. An implementer handed an undefined helper and no warning reaches for `std::fs::canonicalize`, silently case-folding on APFS and destroying DI-002, with VP-008 possibly never built (P6-S3-007).

---

## MEDIUM

### P6-S3-020 — BC-2.07.007 H1/CAP mis-citation; api-surface mismatch

BC-2.07.007.md:75 quotes BC-2.07.001's H1 as CAP-007's title (capabilities.md:125 title is "Relative Path Resolution"); line 76 of the same file gives the correct title. Also asserts CAP-007 for a `url_classifier.rs` contract whose VP is vp-023 and whose PC4 says `path_resolver` is NOT called; api-surface.md:98 assigns `url_classifier` to CAP-009.

---

### P6-S3-021 — BC-2.07.001 cites trap T7 (extraction concern) for path-resolution BC; T16 uncovered

BC-2.07.001.md:81 cites trap T7 = "nested brackets" (market-intelligence.md:334), an SS-03 extraction concern. Path-resolution traps are T12 (case-sensitive filename) and T16 (path above scan root); T16 is formally not-covered and cited by no SS-07 BC.

---

### P6-S3-022 — ADR-006 v1.1 changelog INTRODUCED T8/T12 cross-reference error

ADR-006:105-106 calls T8 "case-sensitive filename trap" but market-intelligence.md:335 T8 = "angle-bracket destination with spaces"; T12 is the case-sensitivity trap. ADR-006's v1.1 changelog records this as a FIX ("corrected T12 cross-reference to T8") — the remediation INTRODUCED the error, on the very trap that motivates the macOS-only gatekeeper.

---

### P6-S3-023 (POLICY 2) — BC-2.07.005 missing "L2 Domain Invariants" row; BC-2.07.006 has "—"

BC-2.07.005.md:90-95 has NO "L2 Domain Invariants" row at all (only one of 8 missing the field); BC-2.07.006.md:91 has "—". Both produce verdicts and are the sole routing decision point, so both are governed by DI-005; BC-2.07.005 also by DI-002.

---

### P6-S3-024 — BC-2.07.004 non-deterministic postcondition; partial-invalid-percent scope ambiguous

BC-2.07.004.md:54 uses non-deterministic language ("likely produce file-not-found") as a postcondition, and leaves partial-invalid-percent scope ambiguous for `My%20A%GG.md` (whole-string-raw vs per-sequence best-effort = opposite verdicts, no vector, no VP). Also unstated whether `%2F` may introduce a path separator (traversal-adjacent).

---

### P6-S3-025 (POLICY 16) — BC-2.07.006 retains non-conforming `EC-NEW-1`/`EC-NEW-2` ids; malformed table

BC-2.07.006.md:69-70 retains non-conforming `EC-NEW-1`/`EC-NEW-2` ids that its sibling BC-2.07.005 fixed in v1.2 (P2-M09 replaced EC-NEW-3 with EC-164, corroborated prd.md:712). Both rows also carry a third cell in a declared 2-column table, so verdict text renders outside the table.

---

### P6-S3-026 (POLICY 17) — BC-2.07.006 version 1.0 with empty modified; D-012 change unrecorded

BC-2.07.006 is version 1.0 with `modified: []` despite prd.md:609 recording a D-012 precondition change. Every sibling recorded theirs. The missing provenance is why the stale Description (P6-S3-006) stayed invisible.

---

### P6-S3-027 (POLICY 19/4) — Unreadable/absent TARGET parent directory has no verdict home

An unreadable or absent TARGET parent directory has NO reason-code home: BC-2.07.003.md:49 states readability as a PRECONDITION so violation is undefined; error-taxonomy.md:91 scopes target-unreadable to SOURCE .md files that EXIST; DI-006's Pass 1.5 rule covers an unreadable target FILE but not a `read_dir` failure on the target's parent. DI-005 requires exactly one verdict; the spec supplies none.

---

### P6-S3-028 — Path NFC symmetry (BC-2.07.003) vs anchor NFD-asymmetry (DI-012) unreconciled on APFS

BC-2.07.003.md:77-78 makes NFC path matching SYMMETRIC (NFD<->NFC both clean) while DI-012 (invariants.md:294-303) makes anchor matching NFD-ASYMMETRIC by design. For `[x](café.md#café)` on an APFS repo the path half is clean and the anchor half broken from the same NFD/NFC difference. Documented in neither BC-2.07.003, BC-2.07.004, nor any cross-reference — the first composite an APFS user hits.

---

## OBSERVATIONS

- **Zero VP coverage for root-relative resolution:** BC-2.07.002.md:70-71, .005:86-87, .006:83-84 all use bare `—`, though BC-2.07.007/.008 were elevated to real VPs (VP-023/024) in v1.5, so the convention exists and these three were unswept. BC-2.07.002 carries six of this shard's findings and is the least-verified, most-contradicted contract in the subsystem.

- **THREE different `path_resolver` entry-point names across architecture docs:** `resolve_path(dest, src_dir, index)` (api-surface.md:89), `path_resolver::resolve(dest, src_dir, &dir_index)` (system-overview.md:153), `files_match(a: &str, b: &str) -> bool` (ADR-006:64). `files_match` appears in no other artifact corpus-wide, yet ADR-006:133 states VP-008's proof obligation in terms of it — the sole macOS gatekeeper's obligation is written against a function absent from the API surface.

- **ADR-006 internally split on who converts OsStr:** :68 says `scanner`, :73/:117 say `app`. Its v1.2 changelog claims this was fixed; it fixed :117 and left :68.

- **[process-gap] POLICY 16 has an automated hook (`check-id-resolution.py`) yet its verification steps name the exact two defects found live here** (R5/R6-instead-of-R2a in 5 BCs; EC-description-mismatch in 5 ECs). The hook validates ID EXISTENCE, not ID SEMANTICS, so POLICY 16's R-family and EC-description checks are UNENFORCED despite `codified_at D-472`. The registry's `lint_hook` field over-claims coverage for POLICY 16.

- **[process-gap] No validator compares a BC's VP-table Proof Method against VP-INDEX's tool column** (three instances: P6-S3-007, P6-S3-017). POLICY 9's hook is `check-counts.py`, which checks arithmetic. This is a mechanical, greppable check that would have caught the VP-008 regression the moment BC-2.07.003 v1.3 was written.

---

## SKIP-LIST SOUNDNESS — ESCALATE

Shard 3 recommends REMOVING "ID resolution" from the adversarial skip list, or narrowing it to "ID EXISTENCE". Two whole defect families (5 mis-anchored ECs, 5 mis-cited brief requirements) live inside a class the adversary was told to skip. Additionally, non-conforming ids (`EC-NEW-1`, `EC-034b`, `EC-031b`) do not match an `EC-\d+` regex and are therefore SILENTLY UNVALIDATED rather than rejected — an injectivity checker sees them as absent, not as violations. Also: `canonical-facts.toml` does NOT include DirIndex population scope, the single most load-bearing undecided fact in SS-07.
