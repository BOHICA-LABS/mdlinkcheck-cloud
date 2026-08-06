---
document_type: adversarial-findings
level: ops
version: "1.0"
status: final
producer: adversary
timestamp: 2026-08-07T03:00:00Z
cycle: phase-1d
shard: 7
frozen_head: 1d3ed17
scope: "21 unread VP bodies (VP-001..007,010,012..017,019..025) read in full"
counts:
  critical: 6
  high: 13
  medium: 25
  total: 44
verdict: "5 VPs are OUTRIGHT VACUOUS and are the sole coverage for 4 domain invariants that VP-INDEX reports as fully covered"
traces_to: cycles/phase-1d/perimeter-sweep-synthesis.md
project: mdlinkcheck-cloud
---

# Adversarial Findings — Perimeter Sweep Shard 7

**Scope:** 21 unread VP bodies (VP-001..007, VP-010, VP-012..017, VP-019..025) read in full
**Frozen HEAD:** `1d3ed17`
**Finding counts:** 6 CRITICAL / 13 HIGH / 25 MEDIUM = **44 findings**
**Verdict:** 5 VPs are OUTRIGHT VACUOUS and are the sole coverage for 4 domain invariants that VP-INDEX reports as fully covered

---

## *** THE SINGLE MOST IMPORTANT FINDING OF THE SESSION ***

### VACUOUSNESS VERDICT — per-VP analysis

**Question: does a no-op / constant / identity implementation satisfy EVERY assertion?**

**OUTRIGHT VACUOUS (5):**
- **VP-015** — `run_scan(_) -> vec![]` passes all 3 fixtures
- **VP-016** — same, passes all 4 fixtures; cycle detection can be fully DISABLED and still pass because dir symlinks are never followed
- **VP-017** — `scan(_,_) -> Ok(vec![])` passes both fixtures; AND cycle detection can be fully DISABLED and still pass
- **VP-019** — `extract_links(_) -> vec![]` — empty output is trivially duplicate-free
- **VP-023** — `classify_url(_) -> Malformed(String::new())` passes all 3 — that implementation marks EVERY https URL malformed, i.e. every external link broken

**THESE FIVE ARE THE SOLE VP COVERAGE FOR DI-008, DI-006, DI-009 AND DI-005 RESPECTIVELY.**
VP-INDEX:93-96 marks the first three "All Covered? Yes". **FOUR OF THIRTEEN DOMAIN INVARIANTS ARE EFFECTIVELY UNVERIFIED WHILE REPORTED AS COVERED.**

**Consequence:** The Phase 6 formal-hardening gate, as currently specified, could pass while four domain invariants remain unverified. This is the same defect class as the four over-determined selftests found earlier today (D-050), one layer up — found the same way, by asking "what is the weakest implementation that passes?"

**Recommended fixes:**
- (a) Extend POLICY 11's positive-coverage requirement from scope [ci-workflow] to [vp] — every VP harness must contain at least one assertion that FAILS on empty/constant output
- (b) Make VP-025's `## Non-Vacuousness Analysis` a REQUIRED section in the VP template
- (c) A grep-level heuristic flags all five instantly — a harness whose every assertion is negated or `is_empty()`

**VACUOUS-BY-DESIGN with mis-attributed compensating controls (3):** VP-001, VP-002, VP-012

**PARTIALLY VACUOUS (3):**
- **VP-013** — a LAST-# splitter passes every assertion; the declared reconstruction invariant is written in a comment then discarded via `let _ = (path, frag)`
- **VP-021** — floor is `total_checked > 0` against a 13-code closed set (one code from one fixture passes); errors[] loop iterates a key `format_json` cannot produce, so target-unreadable is never checked
- **VP-022** — CI snippet runs `cargo bench | tee` under `bash -e` WITHOUT `pipefail`, so a non-compiling bench yields tee's exit 0 and the threshold script parses an empty file — a permanent false-green on the only merge-blocking perf gate

**NON-VACUOUS (9):** VP-004, VP-005, VP-006, VP-010, VP-014, VP-020, VP-024, VP-025, and VP-003 via its unit fixture. VP-025 is the best-constructed VP in the package and its `## Non-Vacuousness Analysis` section should become a REQUIRED VP-template section.

---

## CRITICAL

### P6-S7-001 — VP-001 instructs implementer to build the wrong slug algorithm

VP-001:48-49,:73 describes the slug algorithm as "collapse hyphens" — DI-012 rule 3 (invariants.md:285-287) states hyphen runs are NEVER collapsed ("AI & Automation" → "ai--automation"). VP-001 is the P0 Kani spec an implementer reads first for slugify, so it instructs them to build FM-001 / trap T1, the highest-risk defect in the product.

### P6-S7-002 — VP-007 harness references five non-existent symbols; revised twice without fixing

VP-007's harness is written against `VerdictKind`, `.kind`, `Alive` and `HttpAttempt::Get`, NONE of which exist (api-surface.md declares `Verdict{Clean,Broken,Indeterminate}` and `HttpAttempt{Head,GetFallback}`); all five harnesses fail to compile. VP-007 was revised TWICE after VP-006 and VP-025 applied the same DD-022 Alive→Clean fix.

*(P6-S7-003 through P6-S7-006 are the vacuousness findings for VP-015/016/017/019/023 documented in the vacuousness section above.)*

---

## HIGH

### P6-S7-007 — VP-010 property statement contradicts BC-2.11.002's D-019 raw-string fallback path

VP-010's property statement ("never raw byte prefixes") contradicts BC-2.11.002's D-019 raw-string fallback path, so an implementer builds host-equality matching and REJECTS the BC's canonical vector.

### P6-S7-008 — VP-010 strategies cannot generate four important paths

VP-010's strategies cannot generate EC-163 (the harder bypass), the end-of-string boundary, the underscore-host WHATWG-fail path, or the `?`/`#` boundary chars.

### P6-S7-009 — VP-021 iterates a JSON errors[] array that format_json(findings) cannot produce

### P6-S7-010 — VP-021 closed set is a hand-copied literal; uses wrong type name

VP-021's closed set is a hand-copied literal, so a code added to the enum and the literal but NOT to error-taxonomy.md passes — the exact drift NFR-007 exists to prevent. Also uses `ReasonCode` where the type is `FailureReason`.

### P6-S7-011 — SYSTEMATIC BC→VP mis-description: ≥12 BC VP-table rows attribute properties the cited VP provably lacks

VP-002 credited with DI-012 rules 3 and 6 though it only asserts slug1==slug2; VP-003 credited with per-file counter reset though it has no file concept, leaving DI-013's per-file requirement verified by NO VP; VP-013 credited with "first # is split point" though a last-# splitter passes; VP-004 credited with %20 decoding though split_fragment returns borrowed slices and structurally cannot decode; VP-021 credited with "clean links produce no output", "no ANSI in JSON", "field order"; VP-005 with reporting behaviour; VP-006 with a file count it has no model for; VP-019 with EOF resolution and case-insensitive labels; VP-014 with indented-code though it has no such fixture; VP-015 with same-file and case-mismatch though all three fixtures are cross-file; VP-016 with `**` globs though no `**` pattern appears. Plus 30+ rows declaring the wrong Proof Method.

### P6-S7-012 — VP-025 v1.1 API correction never reached verification-architecture.md:78

verification-architecture.md:78 still specifies the RETIRED Hit/Miss model and HashMap rationale, and omits VP-025's most valuable property (P4 Indeterminate-never).

### P6-S7-013 — DI-005's "Partial" qualifier absent from verification-architecture.md

The "Partial" qualifier is in VP-INDEX:92 but absent from verification-architecture.md:75,:142, so that doc over-claims DI-005 as proven.

### P6-S7-014 — VP-014 covers 3 of 6 DI-004 code contexts; BC-2.04.003 has zero coverage

VP-014 drops HTML `<code>` entirely, has no indented-code fixture, while DI-004 is marked covered; BC-2.04.003 is mapped to VP-014 but no VP-014 fixture asserts on an anchor table, so BC-2.04.003 has zero coverage.

### P6-S7-015 — VP-017 verifies NONE of BC-2.01.004's three postconditions

No dot-directory fixture, no file-symlink fixture, no dir-symlink-exclusion assertion; the BC's own canonical vector is absent.

### P6-S7-016 — DI-009 marked covered but VP-017 tests 2 of 5 conditions and ZERO Pass 1.5 requirements

The Pass 1.5 dedup key-form (which interacts with DI-002 on APFS) has no vehicle anywhere in the 26-VP catalog.

### P6-S7-017 — Four types undefined anywhere; five harnesses assert against undeclared constructors

Types with NO definitions: `PathVerdict`, `FailureReason`, `IoError`, `AllowPrefix`. Undeclared constructors: `DuplicateCounter::with_count` (semantically incoherent for a per-slug map and an unfiled API request), `AllowPrefix::parse`, `AnchorTable(entries)` against a PRIVATE field from a separate test crate.

### P6-S7-018 — VP-014/019/020 cite one function name in prose and a different one in the harness

api-surface.md and module-decomposition.md disagree on three function names; the VPs propagated the disagreement.

### P6-S7-019 — VP-020's property is unenforceable as specified

`build_with_html` takes `html_anchors` already extracted as `&[String]`, so `anchor_table` never observes an `Event::Html` and DI-007's narrow-scope boundary is not in the module VP-020 is anchored to.

---

## MEDIUM

### P6-S7-020 — VP-007 totality assertion is a compile-time tautology

VP-007's totality assertion is an exhaustive match over an enum — checked by rustc, not Kani; it does not actually prove anything Kani-specific.

### P6-S7-021 — VP-007 constrains only 429/5xx/404/410/400-after-GET; 403 and 999 are UNASSERTED

For the rest of u16, the "totality" proof permits returning Broken — the exact false-positive class the product exists to prevent.

### P6-S7-022 — D-018's 400-after-GET → indeterminate has no reason code in the closed set

400 is absent from http-indeterminate's trigger list.

### P6-S7-023 — VP-022 criterion measures in-process library latency, not process wall-clock

VP-022's metric section mandates process wall-clock INCLUDING startup and forbids mean; CI line uses 2x mean as a p95 proxy, making the effective gate mean≤250ms.

### P6-S7-024 — VP-022 contradicts NFR-008 on run count, threshold-pin location, and corpus size

(5 vs 10 vs 20 runs; different threshold locations; different corpus sizes.)

### P6-S7-026 — VP-012 is a bare no-op fuzz target; credits R-001/R-002 correctness which it cannot verify

Also claims surrogate-adjacent coverage which is impossible through `from_utf8`.

### P6-S7-028 — VP-002 keeps full-UTF-8 32-byte symbolic input that VP-001 v1.1 documented as CBMC-infeasible

VP-002 is the only slug Kani VP never revised.

### P6-S7-029 — VP-002 credited with NFR-003; NFR-003 has no VP that actually verifies process-level stdout determinism

NFR-003 is process-level stdout determinism owned by VP-011 — NFR-003 has no VP that runs the process twice and diffs stdout under varying thread counts.

### P6-S7-030 — VP-025 harness P-numbering collision and off-by-one

P4 denotes two different properties; numbering is off-by-one against its own statement list.

### P6-S7-031 — VP-024 strategy always generates EntryKind::File, never Dir or Symlink

The directory contrast its rationale rests on is untested.

### P6-S7-033 — VP-025 P3 asserts Broken(_) with wildcard; anchor-not-found verified NOWHERE

`Broken(_)` wildcard means the specific reason code `anchor-not-found` is never asserted anywhere in the 26-VP catalog.

### P6-S7-034 — VP-025 strategies are pure-ASCII; NFC/byte-exactness claims never exercised

Under macOS-only matrix nothing else would catch a resolver that re-folds.

### P6-S7-036 — VP-016 case 2 writes .gitignore into a temp dir with no git repo

WalkBuilder likely never excludes the target and `broken.is_empty()` holds for the WRONG reason — Pass 1.5, the mechanism under test, is never entered.

### P6-S7-037 — VP-016 cases 2-4 lack case 1's counterpart assertion that the out-of-scan target did not join the scan set

The characteristic over-reach defect is invisible.

### P6-S7-038 — DI-006's Pass 1.5 missing-target rule (exit 1 never 2) has no VP coverage while DI-006 is marked covered

### P6-S7-039 — VP-006 harness 2 duplicates VP-005 verbatim and verifies BC-2.14.002 rather than its own source BC

VP-006 contributes nothing VP-005 does not already prove.

### P6-S7-040 — VP-005/006 claim quantification over all &[Finding] but quantify over 4 booleans via two helpers declared nowhere

verification-architecture.md:127 adds a THIRD signature variant.

### P6-S7-044 — VP-003 0-based collision discriminator contradicts invariants.md:344-346's claim

invariants.md:344-346 claims VP-003 CANNOT detect the 1-based bug; the fixture is headed "also add to VP-018" so it belongs to no VP's declared method and no Phase-3 story will schedule it.
