---
document_type: domain-spec-section
level: L2
section: invariants
version: "1.10"
status: draft
producer: business-analyst
timestamp: 2026-08-05T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/planning/brief-validation.md
  - .factory/planning/market-intelligence.md
input-hash: "62dc24f"
traces_to: L2-INDEX.md
changelog:
  - version: "1.10"
    date: 2026-08-06
    change: "DirIndex-scope ruling: DI-009 Pass 1.5 termination argument re-derived for broad DirIndex population (all link destination types, not only missing-.md targets). Bound restated as O(unique parent dirs of all link destinations) with explicit derivation: LinkMap is fixed after Pass 1, DirIndex scope = all scan-set source link destinations, each unique parent dir visited at most once, no recursion. Removed stale 'out-of-scan-set' qualifier from termination text."
  - version: "1.9"
    date: 2026-08-06
    change: "CV5-001 / D-043 survivor fix: introductory paragraph 'ALL platforms' narrowed to 'the macOS platform'. The phrase 'ALL platforms' in the section preamble was a residual multi-platform claim that survived the D-043 sweep applied to DI-002 and DI-009 in v1.8."
  - version: "1.8"
    date: 2026-08-06
    change: "D-043 macOS-only platform directive: DI-002 platform list narrowed from 'macOS, Linux, Windows' to 'macOS' (the only target platform). Rationale restated on determinism grounds per ADR-006 v1.4 canonical wording — the invariant is stronger under macOS-only because APFS NFD storage is the only filesystem in scope. DI-009: removed Windows reference from fs::canonicalize note."
  - version: "1.7"
    date: 2026-08-06
    change: "P4 remediation: (1) DI-001 sort key updated to four-field (NFC path, line, col, link_target) — ADR-005 v1.2 added link_target as 4th tie-break to make key total; DI-001 is the L2 authority and must lead. (2) DI-012 rule 1 NFC/NFD normalization adjudicated — no normalization before slugging; NFD combining diacritics stripped as non-word chars; macOS NFD scenario documented. (3) DI-012 and DI-013 'Why invariant' sections updated with reciprocal BC citations (BC-2.06.001 and BC-2.06.002 respectively)."
  - version: "1.6"
    date: 2026-08-06
    change: "BI-005 spec-level closure: DI-012 Falsifying method updated to reference VP-026 (differential proptest oracle, all 7 rules) in addition to VP-018. DI-013 Falsifying method updated to reference VP-026 oracle R-001 (≥3-entry repeat run closes FM-002 gap that VP-003 injectivity cannot close). Both DIs now have full VP coverage."
  - version: "1.5"
    date: 2026-08-06
    change: "P3-010 governance gap closure (DD-027): added DI-012 (slug computation fidelity — per-heading character-level transformation must be exact per DD-015) and DI-013 (anchor-key uniqueness — per-file duplicate-counter must produce an injective mapping). Two invariants rather than one because they are logically independent (a wrong counter violates DI-013 without violating DI-012, and vice versa) and have different proof obligations (individual transformation vs. global injectivity). FM-001/003 now cite DI-012; FM-002 now cites DI-013."
  - version: "1.4"
    date: 2026-08-05
    change: "Pass-2 adversarial remediation: DI-001 — added falsifying method (byte-identical comparison without pre-normalization, vary thread count); P2-M16. DI-002 — removed concrete EC-036 `[x](README.MD)` example per P2-C07 holdout sweep (EC-036 is burned per D-020/DD-026; the rule is generalised and DEC-009 cross-reference added). DI-006 — added Pass 1.5 missing-target rule: missing target = normal broken verdict, no IoError recorded; P2-C05. DI-009 — updated deduplication key description to 'NFC-normalized, lexically-normalized, not fs::canonicalize' consistent with P2-M13 architect key-form requirement."
  - version: "1.3"
    date: 2026-08-05
    change: "Orchestrator ruling DD-022: DI-005 augmented with explicit note that `alive` is a URL-liveness outcome at the HTTP layer, not a fourth link verdict. The three-value verdict set remains closed. Resolves adversary P2-C01 and INCONSISTENCY-001/002."
  - version: "1.2"
    date: 2026-08-05
    change: "Phase 1d gate remediation: DI-006 item 3 corrected — removed 'unless --hidden is passed'; dot-directory skip is now unconditional per DD-018/D-011 (--hidden is a dropped non-goal). Matches system-overview.md v1.2 Pass 1 description."
  - version: "1.1"
    date: 2026-08-05
    change: "Phase 1d F-005 remediation: DI-006 widened from --ignore-only to all four source-exclusion mechanisms; DI-008 and DI-009 cross-references added to reflect Pass 1.5 scope"
  - version: "1.0"
    date: 2026-08-05
    change: "Initial draft"
---

# Section 3: Domain Invariants

> **Sharded L2 section (DF-021).** Navigate via `L2-INDEX.md`.

Domain invariants are business rules that must hold for ALL inputs, on the macOS platform,
and ALL time. Violation of any DI-NNN is a bug, not a configuration option.

---

## DI-001: Deterministic Output Ordering

All findings are sorted by `(NFC-normalized file path, line number, column number,
link target)` before emission, regardless of the parallelism order in which files
were scanned. Two runs over the same inputs and flags — under any thread scheduling —
produce byte-identical stdout.

The fourth field `link_target` (the raw link destination string, a field on
`Finding`) is the tie-break that makes the key total: no two distinct findings
can share all four fields when findings are reported at use-site positions (see
ADR-005 for totality argument). `sort_unstable_by` is safe given totality.

**Falsifying method:** Run the command twice on the same corpus under differing scheduler
conditions (e.g. `RAYON_NUM_THREADS=1` vs `RAYON_NUM_THREADS=16`). Diff the two outputs
byte-for-byte without pre-normalization or sorting of the comparison inputs. Any
divergence is a violation. Acceptance-corpus comparisons that sort or normalize outputs
before comparing do NOT test this invariant — they destroy the property under test.

**Why invariant:** R7 ("deterministic") + R8 (parallel scanning) create a mandatory
tension. Ordering resolves it: parallelism is an implementation choice; deterministic
output is the observable contract. Resolves BV-015. Decision DD-012.

---

## DI-002: Case-Sensitive NFC-Normalized Path Comparison

Link target resolution always compares the decoded, NFC-normalized destination against
the actual NFC-normalized directory entries — case-sensitively — on macOS (the only
target platform). A link whose filename differs from the on-disk entry only in
case must produce a `broken` verdict, regardless of what macOS APFS resolves at
runtime (APFS is case-insensitive). No case-folding is applied at any stage of path
comparison.

**Why invariant (D-043 determinism rationale):** Verdicts must be a function of
repository content, not of the host filesystem's case-folding or Unicode normalization
behaviour. macOS APFS is case-insensitive and stores filenames in NFD; adopting native
filesystem semantics would make verdicts a function of the filesystem rather than of
the repository content, which would break DI-001 determinism and NFR-003
reproducibility. This holds on a macOS-only matrix and is not contingent on
cross-platform parity. D-006. BV-006. ADR-006. Concrete corpus scenarios: DEC-004
(NFC/NFD mismatch), DEC-009 (case-mismatched filename).

---

## DI-003: Fragment Split Before Percent-Decode

The fragment component is split from a link destination at the **first unescaped `#`**
in the raw (undecoded) destination string. `%23` is never treated as a fragment
separator. After splitting, each component is percent-decoded independently.

**Why invariant:** Reversing the order causes `a%23b.md` to be misread as file `a`
with fragment `b.md`. This is the documented root cause of Sphinx bug #13620.
Market-intelligence T9.

---

## DI-004: Code Context Yields No Links

No link is ever extracted from a code context (fenced code block, inline code span,
indented code block, HTML `<pre>`/`<code>`, HTML comment). Exclusion is structural
(AST event matching), not heuristic.

**Why invariant:** R4 is an absolute exclusion. BRIEF.md itself contains
`[x](docs/a.md)` inside inline code spans — if this invariant fails,
`mdlinkcheck BRIEF.md` exits nonzero on its own specification document. BV-013.

---

## DI-005: One Verdict Per Link

Each extracted link is assigned exactly one verdict (`clean`, `broken`, or
`indeterminate`). A link cannot have two verdicts or no verdict. The verdict set
is closed and has exactly three values.

**`alive` is NOT a fourth verdict.** When `--online` is active, the HTTP-layer
liveness check produces an intermediate outcome at a different conceptual layer:
`alive` (2xx), `broken`, or `indeterminate`. `alive` is a *URL liveness outcome*;
it maps to the link-level verdict `clean`. The two terms operate at different layers
and must not be conflated: `clean` is the domain verdict that appears in report output
and determines exit codes; `alive` is an internal HTTP-layer classification that never
appears in report output. See entities.md Ubiquitous Language and DD-022 for the
full layer diagram and mapping.

**Why invariant:** The exit code is a pure function of the verdict multiset (DI-011).
An undefined or dual verdict makes the exit code undefined. D-008.

---

## DI-006: Scan-Set Membership Is Independent of Anchor-Target Universe Membership

Membership in the **scan set** (files for which the tool produces findings) is
independent of membership in the **anchor-target universe** (files whose anchor tables
are built to validate incoming cross-file anchor links).

A `.md` file may be absent from the scan set because of any of the following
source-exclusion mechanisms:

1. **`--ignore <glob>`** — explicit user exclusion via globset pattern match
2. **`.gitignore` / `.ignore` patterns** — automatic traversal exclusion enforced by
   the `ignore` crate's WalkBuilder
3. **Dot-directory unconditional skip** — directories prefixed with `.` (e.g., `.github/`,
   `.vitepress/`) are always skipped; there is no `--hidden` flag to override this
   (DD-018, D-011: `--hidden` is an explicit non-goal)
4. **Scan-root boundary** — files located above or outside the scan root path arguments
   are never enumerated by the main traversal

In all four cases, if any in-scan-set link points directly at the excluded `.md` file,
its anchor table is still fully constructed before Pass 2 resolves any cross-file anchor
into it. DI-008's requirement (anchor table complete before validation) is hereby
extended to cover out-of-scan-set anchor targets.

**Bound on the anchor-target universe:** Anchor tables are built only for `.md` files
that are DIRECTLY referenced as link destinations by in-scan-set links — one level, not
transitively. Links found inside out-of-scan-set files are never followed. This bound
keeps the anchor-target universe finite for any finite input corpus, preserves DI-009
(scan terminates), and bounds the Pass 1.5 performance cost to the cardinality of the
in-scan-set link graph rather than the total accessible filesystem.

**Mechanism by exclusion type:**
- Case 1 (`--ignore`): Pass 1 traverses and parses ALL discovered `.md` files,
  including `--ignore`d ones. Anchor tables exist in AnchorIndex when Pass 2 begins.
  Pass 2 simply skips `--ignore`d files as link *sources*.
- Cases 2, 3, 4 (`.gitignore`, dot-dir, outside root): Not discovered by the main
  traversal; absent from AnchorIndex after Pass 1. Pass 1.5 identifies these by
  cross-referencing link destinations against AnchorIndex and builds anchor tables for
  any `.md` target that is missing from it.

  **Pass 1.5 missing-target rule (P2-C05):** If a Pass 1.5 target path does not exist,
  is not a regular file, or cannot be read, no AnchorIndex entry is created, no
  `IoError` is recorded, and no diagnostic is emitted at this stage. Pass 2 then
  produces an ordinary `broken` verdict (`file-not-found`, `broken-symlink`, or
  `target-is-directory`) for any link to that target. Only read failures on files **in
  the scan set** (reached by Pass 1 traversal) contribute to `io_errors` and the
  exit-2 path. This ensures a nonexistent `.md` link target always exits 1, never 2.

**Why invariant:** Without this, any `[x](file.md#section)` link where `file.md` is
`.gitignore`d, in a dot-directory, above the scan root, or matched by `--ignore`
manufactures a false-positive `anchor-not-found` verdict — the exact false-positive
class the product exists to prevent. The previous DI-006 addressed only case 1 (`--ignore`);
cases 2–4 were uncontrolled and silently produced false positives on `.gitignore`d vendor
docs, hidden config directories, and super-root references.

Resolves AMB-063, EC-074. Supersedes DD-008 (DD-008 widened — see decisions.md v1.1).
Architecture satisfiability: Pass 1.5 as specified in system-overview.md v1.1 covers all
four exclusion mechanisms. See also DI-008 (ordering guarantee) and DI-009 (termination).

---

## DI-007: HTML Anchor Extraction Scope Is Narrow

Only `id=` and `name=` attributes from inline/raw HTML elements are extracted into
the anchor table. No DOM construction, no HTML link following, no tree building.
Raw HTML link destinations are NOT extracted.

**Why invariant:** The brief states "no HTML parsing" as a non-goal. D-007 grants a
narrow carve-out: anchor *sources* only. Expanding this reopens the HTML-parsing
scope and manufactures false negatives for HTML link destinations.

---

## DI-008: Anchor Table Built Before Any Incoming Link Is Validated

The anchor table for a file is fully constructed before any link *into* that file
is validated. This holds for every file in the anchor-target universe, including
out-of-scan-set files covered by DI-006. A link pointing to a heading that appears
later in the same file (forward reference) must resolve correctly.

**Why invariant:** Single-pass designs produce false negatives for forward heading
references. Documented real-world failure class in markdown-link-check. Market-intel T15.
Pass 1.5 (system-overview.md v1.1) satisfies this for out-of-scan-set targets by
completing all anchor-table construction before Pass 2 begins.

---

## DI-009: Scan Terminates for Any Input

File traversal terminates for any directory tree, including trees with directory
symlink cycles, overlapping path arguments, zero markdown files, or paths escaping
the scan root.

Pass 1.5 directory reads also terminate. The termination argument is derived as follows:

1. **Fixed input set.** `LinkMap` is written in Pass 1 and never modified in Pass 1.5.
   Pass 1.5 derives its directory set entirely from `LinkMap`; it cannot add new entries
   to `LinkMap` as a side-effect.
2. **Broad scope, deduplication.** Pass 1.5a reads parent directories of **every
   extracted link destination from scan-set sources** — all link types (.md, non-.md,
   directory references). Each unique directory is visited at most once, enforced by a
   visited set deduplicated by NFC-normalized, lexically-normalized (`.`/`..` collapsed),
   NOT-`fs::canonicalize` key. (`fs::canonicalize` case-folds on macOS APFS, which would
   conflict with DI-002; the non-canonicalizing key form is mandatory.) The second encounter
   of any key is skipped.
3. **No recursion.** Only the immediate parent directory of each link destination is read
   (DI-006 one-level, non-transitive rule). Pass 1.5a never reads sub-directories of the
   parent directories it visits.
4. **Finite bound.** The number of `fs::read_dir` calls is bounded by
   O(|unique parent directories of all scan-set link destinations|) ≤ O(|all scan-set links|),
   which is finite for any finite `LinkMap`. This bound holds regardless of whether link
   destinations are .md files, non-.md files, or directory references.

**Why invariant:** Non-termination is a denial-of-service against CI pipelines.
AMB-007 (symlink cycles), AMB-008 (overlapping args), AMB-009 (empty results).

---

## DI-010: Indeterminate Does Not Cause Exit 1

An `indeterminate` verdict appears in report output (and JSON) but does NOT set the
exit code to 1. Only a `broken` verdict sets exit code 1. Only an I/O or usage
error sets exit code 2.

**Why invariant:** The brief's anti-false-positive premise: 429, 5xx, and
bot-blocking are transient server conditions, not link breakage. D-008.
Resolves AMB-036, AMB-034.

---

## DI-011: Exit Code 2 Takes Precedence Over Exit Code 1

When a run produces both a `broken` link verdict and an I/O error, the exit code is
2. The run is not aborted by the I/O error — remaining files are scanned and
reported — but the final exit code reflects the most severe condition.

**Why invariant:** An I/O error means the scan was incomplete; reporting exit 1 would
overstate coverage. R7 defines exit codes by condition type. BV-005. Decision DD-007.

---

## DI-012: Slug Computation Fidelity

The slug computed for any heading by CAP-006 is the exact output of the DD-015
github-slugger v2 algorithm applied to the heading's rendered text content. The
following properties must all hold — they are the failure classes every incumbent
tool gets wrong (market-intelligence T1–T9):

1. **Input is rendered text content.** Inline-code spans contribute their text
   content. HTML tags contribute nothing (tag tokens are stripped; their visible
   text content, if any, is retained). The heading text is taken after AST
   rendering, not from raw source bytes. See ADR-008 for the pulldown-cmark
   event model rationale: `InlineHtml` events carry raw tag bytes only; text
   nodes between HTML tags arrive as `Text` events and are collected normally.
2. **Full Unicode `to_lowercase()`.** Not ASCII-only case folding. Cyrillic, Greek,
   and accented Latin characters are correctly lowercased.
3. **1:1 space→hyphen substitution.** Each space character becomes exactly one `-`.
   Runs of spaces become runs of hyphens. Hyphen runs are NEVER collapsed.
   (`AI & Automation` → `ai--automation`, not `ai-automation`.)
4. **`_` is retained.** Underscore is a `\p{Word}` character and passes through
   unchanged. (`my_heading` → `my_heading`, not `my-heading`.)
5. **Leading and trailing hyphens are retained.** There is no trim step.
6. **CJK, Cyrillic, and accented Latin characters are retained** (all `\p{Word}`).
7. **Emoji are stripped** (not `\p{Word}`, not `-`, not space; removed in step 3).

**Normalization rule (ADR-008):** The slug algorithm does NOT normalize input to
NFC or NFD before processing. Input is processed byte-for-byte as received from
the AST renderer, matching `github-slugger@2.0.0` behavior (byte-for-byte parity
is the stated goal per DD-015/ASM-008). Consequence: NFD combining diacritical
marks (U+0300..U+036F, `\p{Mn}`) are not `\p{Word}` characters and are stripped
in step 3. NFC accented characters (e.g., U+00E9 `é`) are `\p{L}` characters and
are retained. On macOS (where HFS+/APFS stores filenames in NFD), a heading
written in NFD form and a link pointing to its NFC equivalent will produce
different anchor keys and result in `broken`/`anchor-not-found` — this is a known
asymmetry documented in ADR-008, not a product bug.

**Falsifying method:** Apply CAP-006 to any of the DD-015 worked examples (VP-018
corpus) or the VP-026 differential oracle corpus. Any heading-to-slug mapping that
diverges from the expected output is a violation. Minimum falsifying cases:
`AI & Automation` → `ai--automation` (rule 3 — now in VP-018 v1.2 corpus);
`my_heading` → `my_heading` (rule 4); any emoji-containing heading → emoji stripped
(rule 7 — now in VP-018 v1.2 corpus). VP-026 (proptest differential oracle,
`github-slugger@2.0.0`) covers all 7 rules independently with a committed corpus
and proptest generator; it is the authoritative coverage vehicle for DI-012.

**Why invariant:** A wrong slug produces a wrong anchor key, which produces either a
false `anchor-not-found` verdict (false positive on a valid link) or a missed broken
anchor (false negative). DD-015 is the normative *decision* (which algorithm to use);
DI-012 is the *invariant* (the property that must hold for every input on every run).
Without this invariant the DI→VP coverage matrix has no requirement to demand
verification of the product's highest-risk correctness surface. CAP-006, CAP-005.
DD-027. **Enforced by:** BC-2.06.001 (slug computation algorithm).

---

## DI-013: Anchor-Key Uniqueness within a File

For any file, the mapping from heading occurrences to anchor keys produced by CAP-006
is injective: no two headings in the same file share an anchor key. When the base
slug (DD-015 steps 1–4) of two or more headings is identical, the duplicate-counter
mechanism must produce a unique key for each:

- The **first** occurrence of any base slug takes the slug with no suffix.
- The **second** occurrence takes suffix `-1` (0-based counter: the first duplicate
  slot is numbered 1, NOT 2 — the FM-002 bug is off-by-one here).
- The **N-th** occurrence (N ≥ 2) takes suffix `-(N−1)`.
- The counter is **per-base-slug** and **per-file** (not global across files).
- The counter key is the *computed slug* after DD-015 steps 1–4, not the raw heading
  text.

Specifically: three consecutive `## Setup` headings in a single file must produce
anchor keys `setup`, `setup-1`, `setup-2` in order.

**Falsifying method:** Create a file with two headings producing identical base slugs
(e.g., two `## Setup` headings). The anchor keys must be `setup` and `setup-1`. If
the second key is `setup-2`, the counter is 1-based (FM-002 violation). VP-003
(Kani injectivity proof) proves no two outputs are equal but CANNOT detect the
1-based vs 0-based counter bug — injectivity is satisfied by both
(`setup`, `setup-1`, `setup-2`) and (`setup`, `setup-2`, `setup-3`). VP-026
oracle R-001 (≥3-entry repeat heading run, committed `github-slugger@2.0.0` fixture)
closes this gap: the oracle's expected values for entries 2 and 3 are `setup-1`
and `setup-2`; a 1-based counter fails the comparison. VP-018 v1.2
`vp018_duplicate_heading_counter_0_based()` provides defense-in-depth with an
explicit three-repeat golden vector.

**Why invariant:** Injectivity ensures every incoming link like `[text](#setup-1)` has
a unique, predictable anchor to match against. Without it, two valid headings may
produce the same key (one unreachable → false positive on every link targeting it),
or a broken link collides with a valid anchor (false negative). This is a distinct
proof obligation from DI-012: a tool can compute each individual slug correctly
(DI-012 satisfied) while using a 1-based counter (DI-013 violated), and vice versa.
VP-003 (Kani injectivity) directly targets DI-013. CAP-006, CAP-005. DD-027.
**Enforced by:** BC-2.06.002 (duplicate heading disambiguation).
