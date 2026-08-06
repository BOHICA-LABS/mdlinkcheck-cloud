---
document_type: domain-spec-section
level: L2
section: invariants
version: "1.4"
status: draft
producer: business-analyst
timestamp: 2026-08-05T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/planning/brief-validation.md
  - .factory/planning/market-intelligence.md
input-hash: "20e96e1"
traces_to: L2-INDEX.md
changelog:
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

Domain invariants are business rules that must hold for ALL inputs, ALL platforms,
and ALL time. Violation of any DI-NNN is a bug, not a configuration option.

---

## DI-001: Deterministic Output Ordering

All findings are sorted by `(NFC-normalized file path, line number, column number)`
before emission, regardless of the parallelism order in which files were scanned.
Two runs over the same inputs and flags — under any thread scheduling — produce
byte-identical stdout.

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
the actual NFC-normalized directory entries — case-sensitively — on ALL platforms
(macOS, Linux, Windows). A link whose filename differs from the on-disk entry only in
case must produce a `broken` verdict on all platforms, regardless of host OS filesystem
behavior. No case-folding is applied at any stage of path comparison.

**Why invariant:** Without this, the same link passes on a dev Mac and fails in CI,
violating the brief's "deterministic" and "no false positives" promises. D-006. BV-006.
Concrete corpus scenarios: DEC-004 (NFC/NFD mismatch), DEC-009 (case-mismatched filename).

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
the scan root. Pass 1.5's out-of-scan-set directory reads also terminate: each directory is visited at
most once (deduplicated by NFC-normalized, lexically-normalized key — NOT
`fs::canonicalize`, which case-normalizes on macOS/APFS and would conflict with DI-002;
the architect's key-form specification defines the exact form), and no recursion into
sub-directories occurs — only the immediate parent directory of each link destination is
read (bounded by the DI-006 one-level, non-transitive rule).

**Why invariant:** Non-termination is a denial-of-service against CI pipelines.
AMB-007 (symlink cycles), AMB-008 (overlapping args), AMB-009 (empty results).
The DI-006 bound on the anchor-target universe ensures Pass 1.5 adds at most O(|links|)
directory reads, preserving the termination guarantee under the widened invariant.

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
