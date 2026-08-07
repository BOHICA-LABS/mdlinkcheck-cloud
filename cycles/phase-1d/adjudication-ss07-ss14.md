---
document_type: adjudication-package
cycle: phase-1d
blocks: [SS-07-DirIndex-scope, SS-14-exit-code-input-domain]
status: awaiting-operator-ruling
produced_by: architect
timestamp: 2026-08-06
purpose: >
  Operator ruling required on two subsystem-level contradictions before any
  SS-07 or SS-14 spec file may be edited. Each block below contains: the
  contradiction (exact quotes with file:line), 2-3 viable options, a
  recommendation, a blast radius, and open questions.
---

# Adjudication Package: SS-07 and SS-14 Blocking Questions

**CRITICAL NOTE — Verification Protocol:** Every claim in this document has been
verified against the artifact bodies. Changelog entries are treated as history,
not as current truth. Where a changelog claims a fix, the body was checked to
confirm presence or absence. All quoted text is exact; file:line citations are
verified. Two active defects were discovered during preparation and are reported
in their respective blocks.

---

## BLOCK (a): SS-07 — DirIndex Population Scope

### The Contradiction

Two architecture documents describe how `DirIndex` is populated in Pass 1.5,
and they are directly contradictory in scope:

**purity-boundary-map.md, lines 107–110** (body text, not changelog):

> `` `app` builds `DirIndex` in Pass 1.5 by: ``
> `1. Collecting all unique parent directories from every extracted link destination`
> `2. Calling `fs::read_dir` on each (one I/O call per distinct directory)`
> `3. Storing `DirEntryInfo { name, kind }` keyed by directory PathBuf`

**system-overview.md, lines 125–128** (within the Pass 1.5 loop):

> `  For each .md destination path (from scan-set sources) not in AnchorIndex:`
> `  a. Collect unique parent directories of all such missing paths`
> `  b. fs::read_dir each parent directory -> Vec<DirEntryInfo { name: OsString, kind: EntryKind }>`
> `     EntryKind distinguishes File / Dir / Symlink { dangling: bool }`

**Stated plainly:** purity-boundary-map.md says DirIndex is built from **every
extracted link destination** (all link types: .md in-scan-set, .md missing, non-.md,
directory links). system-overview.md says DirIndex is built only from parent
directories of **.md files NOT already in AnchorIndex** (out-of-scan .md targets only).

These cannot both be correct. The scope of DirIndex is either broad (all link
destination parent dirs) or narrow (only missing .md target parent dirs).

### Why This Matters for the Five Dependent Artifacts

**BC-2.07.002 POSTCONDITIONS** — Root-relative link resolution uses
`git_repo_root.join(...)` to produce a resolved path, then hands it to
`path_resolver` for NFC case-sensitive lookup. Under the narrow DirIndex (SO),
the parent directory of a root-relative link target may not be in DirIndex — for
example, if the target is an in-scan-set .md file, or a non-.md file. In that case,
the postcondition chain breaks: postcondition 1 produces a resolved path, but
BC-2.07.003 cannot execute its comparison because no DirIndex entry exists for
that directory. Postconditions 1–4 as written make no claims about DirIndex
completeness, and this silence is only safe under the broad DirIndex (PBM).

Under broad DirIndex: postconditions are fully supportable. path_resolver always
has the DirIndex entries it needs for any resolved path.

**BC-2.07.003 PRECONDITIONS** — Precondition 2 states: "The resolved path's parent
directory is readable." In the pure-core model, path_resolver has no I/O access;
"readable" is operationalized as "present in DirIndex." Under narrow DirIndex (SO),
precondition 2 is NOT guaranteed for:
- Links to .md files already in AnchorIndex (their parent dirs are not collected)
- Links to non-.md files (not scoped into Pass 1.5 at all)
- Links to directories

This makes precondition 2 unverifiable at runtime for those cases. Under broad
DirIndex (PBM), precondition 2 is guaranteed for every resolved link — DirIndex
covers all link destination parent dirs.

**VP-008/VP-009 regression note (active defect, REPORT):** BC-2.07.003 v1.3
(line 83) lists VP-008's proof method as "integration test (macOS only per
D-043)". The VP-INDEX (authoritative source of truth, line 64) lists VP-008 as
"proptest". The vp-008 file (frontmatter `proof_method: proptest`) confirms
proptest. The v1.3 changelog says "VP-008 proof method updated to macOS-only"
but that edit changed the PLATFORM SCOPE, not the proof method. BC-2.07.003 now
has a stale/incorrect proof method in its own VP table. VP-INDEX and vp-008 file
are authoritative; BC-2.07.003's VP table is wrong and must be corrected to
"proptest (macOS only per D-043)". This is not contingent on the DirIndex
ruling — it is an independent defect that exists now.

**BC-2.07.005 and BC-2.07.006 ROUTING** — Both BCs require path_resolver to
determine EntryKind (File, Dir, Symlink) for the resolved target. This is the
mechanism by which path_resolver routes to "clean" (directory, no fragment),
"broken(target-is-directory)" (directory + fragment), "clean" (non-.md file,
exists), or "broken(file-not-found)" (not found). This EntryKind comes exclusively
from DirIndex.

Under narrow DirIndex: for a link to `docs/image.png` (non-.md), `docs/` is not
in DirIndex → path_resolver cannot determine whether `image.png` is a File, Dir,
or Symlink → routing decision in BC-2.07.005 and BC-2.07.006 is undefined. For
a link to `docs/guide.md` where `guide.md` IS in the scan set, `docs/` may not be
in DirIndex → same problem.

Under broad DirIndex: `docs/` is always in DirIndex for any link to something
inside it → routing decisions are always resolvable.

**DI-009 TERMINATION BOUND** — DI-009 says "each directory is visited at most
once (deduplicated by NFC-normalized, lexically-normalized key)." Under narrow
DirIndex, the dedup set spans only parent dirs of missing .md targets — the visited
set is smaller and the O(|links|) bound in DI-006 overstates the actual scope.
Under broad DirIndex, the dedup set spans ALL link destination parent dirs. The
termination argument is sound under both options (dedup still works), but the
spec text claiming "O(|links|)" as the bound is only tight under broad DirIndex.
Under narrow DirIndex, the bound is O(|missing_md_parent_dirs|) — a smaller number.
This is technically correct but the spec does not distinguish. If narrow is chosen,
DI-009 must be updated to state the narrow bound explicitly so future readers
don't add non-.md link directories expecting them to be covered.

### Options

**Option A: Adopt purity-boundary-map.md — DirIndex covers ALL link destination parent directories.**

Pass 1.5 is restructured into two phases:
1. Collect unique parent dirs of ALL extracted link destinations (any type); call
   `fs::read_dir` on each; populate DirIndex. Dedup by NFC-normalized lexically-
   normalized key as currently specified.
2. For each .md destination NOT in AnchorIndex: use the now-complete DirIndex to
   determine if the file exists and is readable; if so, parse and add to AnchorIndex.

Artifacts that must change:
- system-overview.md Pass 1.5 section: rewrite steps to explicitly separate DirIndex
  population (all link types) from AnchorIndex extension (missing .md only). The
  "For each .md destination path not in AnchorIndex" loop must be scoped to
  AnchorIndex extension only; DirIndex population precedes it.
- BC-2.07.002 postconditions: add postcondition 5 — "DirIndex is fully populated for
  the parent directory of the resolved path before path_resolver is called."
- BC-2.07.003 preconditions: clarify that precondition 2 ("parent directory is
  readable") is satisfied by DirIndex presence, guaranteed under Option A for all
  link types.
- BC-2.07.005 precondition 2: "exists on the filesystem and is a directory" must
  note EntryKind comes from DirIndex, populated in Pass 1.5 for all link types.
- BC-2.07.006 precondition 2: same — "exists as a regular file" is verified via
  DirIndex EntryKind.
- DI-009: update bound to "at most O(|unique_parent_dirs_across_all_link_destinations|)"
  instead of the current "O(|links|)" which is an over-bound.

What breaks: nothing in the existing BC logic. Strictly additive: Pass 1.5 does more
`fs::read_dir` calls (covering non-.md link destination parent dirs), but all are
deduped and all are bounded by the link count.

Phase 2 story decomposition impact: the Pass 1.5 story must implement a two-step
structure. The first step is the DirIndex population sweep (all link types); the
second step is the AnchorIndex extension step (missing .md only). These are separate
loops or sub-phases within Pass 1.5.

Phase 6 formal hardening impact: VP-017 (termination) must test that the dedup
key works for non-.md link destination parent dirs, not just .md ones. VP-008/
VP-009 proofs are unaffected (proptest generates arbitrary path strings; DirIndex
completeness is an integration concern, not a pure function concern).

**Option B: Adopt system-overview.md — narrow DirIndex, add a fallback for non-covered paths.**

DirIndex covers only parent dirs of missing .md targets. path_resolver is given a
fallback for paths whose parent directory is not in DirIndex. Possible fallbacks:
(a) `Path::exists()` — VIOLATES DI-002: APFS case-insensitive semantics would
    produce incorrect verdicts for case-mismatched links.
(b) A second `fs::read_dir` call at resolution time in path_resolver — VIOLATES
    the pure-core boundary: path_resolver would need I/O access, invalidating
    Kani proof harnesses.
(c) A sentinel value in DirIndex ("directory not present" entry) — requires
    fundamentally different data structure and still leaves case-sensitive
    comparison undefined for in-scan-set files.

None of (a), (b), (c) is viable without violating DI-002 or the purity boundary.
Option B is NOT RECOMMENDED. It is listed for completeness but cannot be made
internally consistent without breaking two foundational invariants.

**Option C: Retain purity-boundary-map.md scope for DirIndex, extend system-overview.md to distinguish the two loops explicitly.**

Functionally identical to Option A. The key clarification: system-overview.md
currently describes Pass 1.5 as a single loop "for each .md destination not in
AnchorIndex" but the actual DirIndex population must happen BEFORE or as a
separate pass. Option C formalizes this by showing Pass 1.5 as two sub-phases:
- Pass 1.5a: DirIndex build (all link destination parent dirs, any type)
- Pass 1.5b: AnchorIndex extension (missing .md files only, using DirIndex from 1.5a)

Blast radius is identical to Option A.

### Recommendation

**Option A (= Option C — they differ only in presentation).**

Rationale: purity-boundary-map.md's statement is architecturally necessary. For
path_resolver to be purely DirIndex-driven (no I/O, Kani-provable), DirIndex must
have entries for every directory that any link target lives in — not just out-of-scan
.md directories. Option B has no viable fallback that preserves DI-002 and the
purity boundary simultaneously. The additional `fs::read_dir` calls under Option A
are bounded by O(unique parent dirs of all links), which is no worse than O(|links|)
and typically much smaller due to directory reuse.

What would change this recommendation: a proposal for how path_resolver could
determine EntryKind for non-.md targets and in-scan-set .md targets WITHOUT using
DirIndex and WITHOUT I/O. No such mechanism exists in the current spec.

### Blast Radius (Option A)

Files requiring edits:
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/system-overview.md` — Pass 1.5 restructuring (two sub-phases)
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-07/BC-2.07.002.md` — add postcondition 5 (DirIndex populated for resolved path's parent dir)
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-07/BC-2.07.003.md` — clarify precondition 2; also **fix VP-008 proof method in VP table** (independent defect: "integration test" → "proptest")
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-07/BC-2.07.005.md` — precondition 2 note on EntryKind source
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-07/BC-2.07.006.md` — precondition 2 note on EntryKind source
- `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/invariants.md` — DI-009 bound restatement

Files NOT changed (existing logic remains correct): purity-boundary-map.md (already correct under Option A), VP-INDEX, VP-008 file, BC-2.07.001, BC-2.07.004.

### Open Questions for the Operator

None that are blocking for Option A. The VP-008 regression in BC-2.07.003 is
a confirmed defect independent of this ruling; it should be fixed in the same
edit wave as Option A.

---

## BLOCK (b): SS-14 — Exit Code Input Domain

### Sub-question 1: io_errors vs. config_error for a Nonexistent PATH Argument

#### The Contradiction

**CAP-014 (capabilities.md, lines 233–234)**:

> `2 = any I/O error OR any usage error (malformed flag,`
> `nonexistent PATH argument, invalid --ignore glob, unrecognized flag)`

CAP-014 places "nonexistent PATH argument" under the "usage error" label.

All three SS-14 BCs, BC-2.01.009, and system-overview.md consistently say the
OPPOSITE — nonexistent PATH is an io_error, not a config_error:

**BC-2.14.001, Precondition 3 (line 45)**:
> `Note: a nonexistent PATH argument is an I/O error, NOT a startup configuration`
> `error; it goes into io_errors, not config_error.`

**BC-2.14.002, Precondition 2 (line 44)**:
> `io_errors is non-empty (I/O error during scan OR a nonexistent PATH argument —`
> `both are recorded into Vec<IoError>)`

**BC-2.14.003, Precondition 3 (line 43)**:
> `A nonexistent PATH argument is an I/O error, not a startup config error.`

**BC-2.01.009 description (line 38)**:
> `A nonexistent PATH argument is NOT a startup configuration error — it does not`
> `exit before traversal begins.`

**system-overview.md error table (line 254)**:
> `Non-existent or unreadable PATH argument | Startup or first access |`
> `Record into Vec<IoError>; scan continues with valid paths | DD-007 no-fail-fast`

**BC-2.14.002 canonical test vector (line 68–69)**:
> ``mdlinkcheck good_dir/ nonexistent_dir/` — good_dir has 1 broken link;``
> `nonexistent_dir does not exist → 2 (good_dir IS fully scanned and its broken`
> `finding IS reported)`

This test vector is only consistent with the io_errors path (scan continues).
Under the config_error=true path, scanning would halt immediately and good_dir's
broken link would NOT be reported.

The behavior distinction is material:
- **io_errors path**: record E-IO-002; scan all remaining valid paths; call
  `verdict::exit_code(findings, [E-IO-002], false)` → returns 2 after scanning.
- **config_error=true path**: halt immediately, call `verdict::exit_code([], [], true)` → exit 2 with no findings emitted.

#### Options

**Option 1: Nonexistent PATH = io_errors (adopt BC alignment, fix CAP-014).**
Remove "nonexistent PATH argument" from CAP-014's "usage error" list. Reclassify
it explicitly as an "I/O error" in CAP-014. No BC changes needed; BCs, BC-2.01.009,
system-overview.md, and interface-definitions.md are already aligned.

Changes: CAP-014 line ~234 only.
Blast radius: capabilities.md.

**Option 2: Nonexistent PATH = config_error=true (adopt CAP-014, rewrite BCs).**
Nonexistent PATH causes immediate exit 2 before scanning. Must change:
- BC-2.14.001/002/003 preconditions to remove the "scanning continues" language
- BC-2.01.009 description and test vectors
- system-overview.md error table
- interface-definitions.md §8 Flag Interaction Rules
- interface-definitions.md §3 Exit Codes
This contradicts DD-007 (no-fail-fast) which is cited in BC-2.01.009 v1.1 as the
authoritative decision. If operator overrides DD-007 here, DD-007 must be amended.

**Option 3: Nonexistent PATH is always exit 2 but via io_errors (current BCs), and CAP-014 label is imprecise but exit-code-correct.**
Declare CAP-014 correct about the exit code (2) but wrong about the category label.
Fix CAP-014's label from "usage error" to "I/O error" for nonexistent PATH.
Behaviorally identical to Option 1.

#### Recommendation

**Option 1** (= Option 3 in substance).

Rationale: Six artifacts (all three SS-14 BCs, BC-2.01.009, system-overview.md,
interface-definitions.md) are mutually aligned that nonexistent PATH = io_errors
with scanning continuing. The BC-2.14.002 distinguishing test vector (`good_dir/ +
nonexistent_dir/`) is the explicit falsifying case that proves the intent. DD-007
(no-fail-fast, cited four times) is the governing decision. CAP-014 mislabels the
category. The fix is one line in capabilities.md.

What would change this recommendation: an operator ruling that DD-007's no-fail-fast
scope excludes startup-time PATH validation and that nonexistent PATH should
immediately abort. This would require amending DD-007 and rewriting six artifacts.

#### Blast Radius (Option 1)

Files requiring edits: `capabilities.md` only (CAP-014, one label correction).

---

### Sub-question 2: Canonical config_error Membership List

#### The Three Enumerations (side-by-side diff)

| Source | Members listed as "config_error=true / usage error" |
|--------|-----------------------------------------------------|
| **CAP-014** (capabilities.md ~234) | malformed flag, **nonexistent PATH argument**, invalid --ignore glob, unrecognized flag |
| **BC-2.14.001 PC4 + BC-2.14.003 PC4** | unrecognized flags, invalid --ignore glob pattern |
| **system-overview.md error table** (~251–255) | invalid --ignore glob ONLY (with "Exit 2 immediately" and "before any traversal") |

The three lists do not agree on which items belong in config_error. The disagreement
involves three specific items:

**Item A: "nonexistent PATH argument"** — covered in Sub-question 1 above.
Verdict: io_errors, not config_error. Removed from the canonical list.

**Item B: "unrecognized flags" / "malformed flag" / "unrecognized flag"** — present
in CAP-014 and the BCs but NOT in system-overview.md's "immediate exit" row.
The critical question: does an unrecognized flag reach `verdict::exit_code` with
`config_error=true`, or does clap handle it via `process::exit(2)` before
`verdict::exit_code` is ever called?

VP-005's Kani harness proves `exit_code(findings, io_errors, config_error=true) → 2`
at the function level. But if clap intercepts unrecognized flags before the app
runs, config_error is never set to true in that code path and the Kani proof tests
a state that is unreachable via the normal CLI entry point.

**Item C: "invalid --ignore glob"** — present in all three sources. The behavioral
description in system-overview.md says "exits immediately with code 2 … before any
traversal." This is consistent with clap running, parsing flags, app running
globset compilation, detecting a bad glob, setting config_error=true, calling
`verdict::exit_code([], [], true)` → 2, and exiting. OR it could mean a
`process::exit(2)` call in cli.rs before verdict::exit_code. The current spec is
ambiguous on whether the invalid-glob path goes THROUGH verdict::exit_code or bypasses it.

#### Options

**Option 1: config_error = {invalid --ignore glob ONLY}. Unrecognized flags handled by clap before app::run().**

Under this model:
- clap handles unrecognized flags via its own error mechanism (process::exit(2)),
  never reaching app::run()
- app::run() detects invalid --ignore glob AFTER clap parsing succeeds; sets
  config_error=true; calls verdict::exit_code([], [], true) → 2
- config_error is a live parameter, but its only trigger is the invalid glob case
- VP-005's harness is correct as a unit test of the pure function; in integration,
  only the invalid-glob path actually sets config_error=true

Changes: CAP-014 (remove unrecognized flags from config_error list), BC-2.14.001
PC4 and BC-2.14.003 PC4 (remove "unrecognized flags" from config_error description),
BC-2.14.004 (add invariant about clap handling —help/--version before verdict::exit_code).

**Option 2: config_error = {invalid --ignore glob, invalid flag value (e.g., --format xyz)}. Unrecognized flags still handled by clap.**

This widens config_error to include any flag VALUE that passes clap's type check
but fails application validation (e.g., a future `--format xyz` where clap accepts
the string but app rejects the value). Currently the only such case is `--format`
with invalid value (clap's `value_parser` likely handles this before app); this may
be a phantom expansion. Same boundary as Option 1 in practice.

**Option 3: config_error = {invalid --ignore glob, unrecognized flags, malformed flag values}. Clap error passes through to verdict::exit_code.**

Under this model, clap is configured to NOT call `process::exit` on unrecognized
flags; instead the error is propagated to app, which sets config_error=true. This
requires non-default clap configuration (clap's `ErrorKind::UnknownArgument` must
return `Err` rather than calling `process::exit(2)`).

This is feasible but not the idiomatic clap usage pattern. It would require
deliberate implementation decisions to thread clap errors through to verdict::exit_code.

#### Recommendation

**Option 1: config_error = {invalid --ignore glob ONLY}.**

Rationale: This is the only item that demonstrably goes through a code path where
config_error could be passed to verdict::exit_code as a live parameter. Unrecognized
flags and --help/--version are handled by clap before app::run() — the standard
clap behavior. The "exits immediately" language in system-overview.md for invalid
--ignore glob is consistent with config_error being set inside app and passed to
verdict::exit_code (which then returns 2 before any traversal starts), or with
process::exit(2) directly. Option 1 is consistent with both interpretations.

What would change this recommendation: a deliberate design decision to configure
clap in error-return mode (not exit mode) so that unrecognized flags propagate to
app as Err, enabling config_error=true for them. This would need an explicit ADR.

**Open question for operator:** Does the invalid --ignore glob detection happen
INSIDE app (passes config_error=true to verdict::exit_code) or in a short-circuit
before verdict::exit_code is called (direct process::exit)? This determines whether
config_error is a live parameter or a modeling artifact. The answer affects:
- Whether the Kani proof for VP-005 tests a reachable code path or an abstract
  function property
- Whether the standalone exit-2 case (Sub-question 4) via config_error is
  reachable in integration tests

#### Blast Radius (Option 1)

- `capabilities.md` — CAP-014: remove "unrecognized flag" and "malformed flag" from
  usage-error list; narrow to "invalid --ignore glob"
- `BC-2.14.001.md` — PC4: remove "no unrecognized flags" from config_error description
- `BC-2.14.003.md` — PC4: same as BC-2.14.001
- `BC-2.14.004.md` — add invariant 4: "clap handles --help/--version before
  app::run(); verdict::exit_code is never called for these invocations"
- No changes to BC-2.14.002, VP-005, or VP-INDEX

---

### Sub-question 3: --help/--version Precedence AND Its Enforcement Point

#### The Gap

BC-2.14.004 v1.5 (current) specifies:
- Precondition 1: "--help or --version is present in the command-line arguments"
- Postconditions 1–5: correct behavior (help text/version string printed, exit 0,
  no file traversal)
- Architecture Module: `cli.rs (effectful shell, LOW tier)`

What BC-2.14.004 does NOT state:
1. That clap intercepts these flags BEFORE app::run() is called — meaning the
   enforcement point is in cli.rs via clap's built-in handler, not in app logic.
2. That `verdict::exit_code` is NEVER called for --help/--version invocations.
   (There are no findings, no io_errors, no config_error — but this is not stated.)
3. That `config_error` and `io_errors` are definitionally irrelevant for
   --help/--version (since no scanning occurs).

The consequence: a future implementer reading only BC-2.14.004 and the SS-14 BCs
could reasonably write code that calls verdict::exit_code([], [], false) → 0 for
--help/--version, which would technically produce the right exit code but would
also perform unnecessary processing.

More critically: because verdict::exit_code takes no fourth input, enforcement of
the "exit 0 without scanning" contract CANNOT live in verdict.rs. It must live in
cli.rs. BC-2.14.004 places it in cli.rs but does not make the enforcement mechanism
(clap's built-in --help/--version handling) explicit. This is an underdetermined
contract.

#### Options

**Option 1: Add an explicit enforcement-point invariant to BC-2.14.004.**

Add Invariant 4: "Enforcement point: clap's built-in --help/--version flag
handling intercepts these flags before app::run() is called. verdict::exit_code
is never invoked. No DirIndex, AnchorIndex, or Vec<Finding> is ever constructed.
This behavior is a property of clap's default flag-handling pipeline and does not
require custom app logic."

This makes the contract complete and eliminates the ambiguity about enforcement.

BC: BC-2.14.004.
No changes to other BCs or VPs.

**Option 2: Add a note to BC-2.14.002/003 that --help/--version are excluded from their precondition scope.**

BC-2.14.002 and BC-2.14.003 have preconditions that say "all scanning and reporting
is complete." For --help/--version, scanning never starts. Adding an exclusion note
("does not apply when --help or --version terminates the run") makes the scope of
those BCs explicit.

This is additive to Option 1 and together they form a complete picture.

**Option 3: Status quo — accept the implicit enforcement.**

The existing VP-INDEX note for BC-2.14.004 (line 266) says: "clap library intercepts
before app::run(); integration test verifies exit 0." The enforcement point is
documented in VP-INDEX but not in the BC itself. This is architecturally correct
but leaves a gap between the contract and the implementation specification.

#### Recommendation

**Option 1 + Option 2 combined.**

Rationale: The BC is the authoritative behavioral contract. An implementer reading
BC-2.14.004 in isolation should not need to read VP-INDEX to understand the
enforcement point. The invariant is both technically correct (clap does this by
default) and important for Phase 2 story scoping (the story for --help/--version
must use clap's built-in mechanism, not custom exit logic).

What would change this: if the implementation plan calls for a custom --help/
--version handler that goes through app logic (e.g., for structured output). That
would require a different enforcement point.

#### Blast Radius

- `BC-2.14.004.md` — add Invariant 4 (clap enforcement point; verdict::exit_code not called)
- `BC-2.14.002.md` — add scope note to Precondition 1 or a new Invariant 4 excluding --help/--version
- `BC-2.14.003.md` — same scope note
- No changes to VP-005, VP-006, VP-INDEX, or capabilities.md

---

### Sub-question 4: An Owner for Standalone Exit 2 (No Concurrent Broken Links)

#### The Gap — Verified Against Artifacts

Standalone exit 2 is: `io_errors` non-empty OR `config_error=true`, with zero
`broken` findings. Example: `mdlinkcheck /nonexistent/path` produces one E-IO-002,
zero findings, and should exit 2.

Check all four SS-14 BCs for satisfiable preconditions on this case:

**BC-2.14.001**: Precondition 3 requires `io_errors = []`; Precondition 4 requires
`config_error = false`. FAILS for standalone exit 2 (io_errors non-empty).

**BC-2.14.002**: Precondition 3 (line 45) states: "At least one broken link was
also found (would independently set exit 1)." FAILS for standalone exit 2 (no
broken links). **Confirmed present in body.**

**BC-2.14.002 internal inconsistency (active defect)**: The canonical test vectors
table (line 66–69) includes: `1 unreadable file, no broken links → 2`. This test
vector does NOT satisfy Precondition 3. The BC's body is internally inconsistent:
its preconditions exclude the very test vector it claims to govern.

**BC-2.14.003**: Precondition 3 requires `io_errors = []`; Precondition 4 requires
`config_error = false`. FAILS for standalone exit 2.

**BC-2.14.004**: Governs --help/--version only. Not applicable.

**VP-005 covers it at function level**: VP-005 Kani harness (line 76–78):
```
if has_io_error {
    assert_eq!(code, 2u8, "Expected exit 2 when io_errors non-empty");
}
```
This proves verdict::exit_code correctly returns 2 for standalone exit 2 regardless
of findings. The pure function is correct. But no BC governs the pipeline path
from CLI input to this state.

Exit 2 standalone is therefore:
- Correctly implemented per VP-005's proof target
- Orphaned at the behavioral contract level
- Claimed by BC-2.14.002 test vectors but excluded by BC-2.14.002 preconditions

#### Is Exit 2 Standalone Reachable At All?

Yes, definitively. `mdlinkcheck /does/not/exist` is the canonical case (BC-2.01.009
EC-012). It produces zero broken findings, one E-IO-002 error, and must exit 2.
The behavior is specified by BC-2.01.009 at the SS-01 level. The gap is that no
SS-14 BC formally owns the "exit code is 2" determination for this case at the
exit-code-subsystem level.

#### Options

**Option 1: Widen BC-2.14.002 — remove Precondition 3 ("at least one broken link").**

BC-2.14.002 becomes: "exit 2 whenever io_errors is non-empty OR config_error=true,
regardless of broken-link count (including zero broken links)."

Precondition 3 (the broken-link requirement) is removed. The new preconditions are:
1. All scanning and reporting is complete.
2. At least one exit-2-triggering condition occurred: io_errors non-empty OR
   config_error=true.
(Precondition 3 REMOVED.)

Postconditions become:
1. Process exit code: 2.
2. All findings (broken and indeterminate) from successfully scanned paths are
   reported. (zero findings is valid if no paths were successfully scanned.)
3. The summary line on stderr reflects the broken count (0 if no broken links found).

This aligns BC-2.14.002 with VP-005's actual proof (which already handles the
zero-broken-findings case). The internal inconsistency (precondition vs. test vector)
is resolved by removing the precondition, retaining the test vector.

Changes: BC-2.14.002 only.

**Option 2: Create BC-2.14.005 — standalone exit 2 (no broken links).**

Add a new BC for the standalone case:
- Preconditions: (1) all scanning complete; (2) io_errors non-empty OR
  config_error=true; (3) no broken findings.
- Postconditions: exit 2; zero or more clean/indeterminate findings reported;
  summary "No broken links found." on stderr.
- Verification Properties: VP-005 (Kani, already proves this case).

BC-2.14.002 retains its current framing ("exit 2 beats exit 1") with Precondition 3.

This creates two BCs for exit 2 (one for "exit 2 with broken links", one for "exit 2
without broken links"), which preserves the exact structure of BC-2.14.002 at the
cost of a fourth BC in the subsystem.

Changes: new BC-2.14.005.md; VP-INDEX update; verification-coverage-matrix update.

**Option 3: Keep BC-2.14.002 as-is; remove the inconsistent test vector; accept that BC-2.01.009 governs standalone exit 2.**

The argument: BC-2.01.009 (SS-01) already specifies "nonexistent PATH → exit 2"
with the no-fail-fast behavior. The SS-14 BCs govern the exit-code-determination
subsystem, and DI-011 plus VP-005 prove the underlying function is correct. The
"missing" BC in SS-14 is covered at the SS-01 level.

Problem: this leave SS-14 with an untracked test case in BC-2.14.002 (the
inconsistent test vector) and makes it impossible to decompose a story for "standalone
exit 2" in Phase 2 without either inventing a BC or pointing to a cross-subsystem
contract. VP-005 is tagged to BC-2.14.002 in VP-INDEX (line 62); if Precondition 3
excludes standalone exit 2, then VP-005 is overclaiming its source BC.

#### Recommendation

**Option 1: Widen BC-2.14.002 by removing Precondition 3.**

Rationale: The defining property of BC-2.14.002 is "exit 2 dominates all other
outcomes" — this is DI-011, which says nothing about whether broken links are
present. Precondition 3 ("at least one broken link also found") was added to give
BC-2.14.002 a sub-case structure (the "exit-2-beats-exit-1" scenario), but it
inadvertently excluded the standalone exit-2 case. VP-005's harness already proves
the complete property (io_error → exit 2 regardless of findings). Widening BC-2.14.002
to match VP-005's actual coverage is the minimal, internally consistent fix. The
inconsistent test vector ("1 unreadable file, no broken links → 2") is then
consistent with the preconditions and remains.

What would change this recommendation: a strong architectural reason to treat
"exit 2 with broken links" and "exit 2 without broken links" as fundamentally
different behaviors requiring separate BCs (Option 2). No such reason exists in the
current spec.

#### Blast Radius (Option 1)

- `BC-2.14.002.md` — remove Precondition 3; update description to make "standalone
  exit 2" explicit; no changes to postconditions (already correct)
- No changes to VP-005, VP-INDEX, verification-coverage-matrix (VP-005 is already
  correctly tagged to BC-2.14.002)
- No changes to other BCs

---

## Summary Table (for Operator Ruling)

| Block | Sub-Q | Contradiction (one line) | Recommended Option | Blocking Unknown |
|-------|-------|------------------------|-------------------|-----------------|
| (a) | — | purity-boundary-map.md: DirIndex covers ALL link destination parent dirs; system-overview.md: DirIndex covers only missing-.md-target parent dirs | Option A: broad DirIndex (PBM is correct) | None — Option B has no viable fallback |
| (b) | 1 | CAP-014 puts nonexistent PATH in "usage error"; all three SS-14 BCs and BC-2.01.009 put it in io_errors with scanning continuing | Fix CAP-014: nonexistent PATH → io_errors | None |
| (b) | 2 | config_error membership enumerated 3 ways: CAP-014 (4 items), BCs (2 items), system-overview.md (1 item) | Canonical list = {invalid --ignore glob} only | Whether invalid --ignore glob exits via config_error→verdict::exit_code or via direct process::exit(2) |
| (b) | 3 | BC-2.14.004 places enforcement in cli.rs but no invariant states verdict::exit_code is never called for --help/--version | Add Invariant 4 to BC-2.14.004; add scope notes to BC-2.14.002/003 | None |
| (b) | 4 | BC-2.14.002 Precondition 3 requires broken links to be present, making standalone exit 2 ungoverned; test vector in same BC contradicts precondition | Widen BC-2.14.002: remove Precondition 3 | None |

## Independent Defects Found During Preparation (No Ruling Required — Fix on Next Edit Wave)

**Defect D-1: VP-008 proof method wrong in BC-2.07.003.**
- BC-2.07.003 v1.3 VP table line 83: `VP-008 | ... | integration test (macOS only per D-043)`
- VP-INDEX line 64 (authoritative): `VP-008 | ... | proptest`
- vp-008 frontmatter: `proof_method: proptest`
- Root cause: BC-2.07.003 v1.3 changelog says "VP-008 proof method updated to
  macOS-only" but the actual change was to the platform SCOPE, not the proof METHOD.
  BC-2.07.003's own VP table was erroneously updated to "integration test".
- Fix: correct BC-2.07.003 VP table to "proptest (macOS only per D-043)".

**Defect D-2: BC-2.14.002 internal inconsistency (test vector violates precondition).**
- BC-2.14.002 Precondition 3 (line 45): "At least one broken link was also found."
- BC-2.14.002 canonical test vector (line 68): "1 unreadable file, no broken links → 2"
- The test vector does not satisfy Precondition 3.
- Resolution: sub-question 4 Option 1 (remove Precondition 3) resolves this defect
  as a consequence of the ruling. No separate fix needed if Option 1 is adopted.
