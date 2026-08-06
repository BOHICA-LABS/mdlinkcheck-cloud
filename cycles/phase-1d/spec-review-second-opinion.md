---
document_type: spec-review
review_type: constructive-second-opinion
level: L3
version: "1.0"
status: complete
producer: vsdd-factory:spec-reviewer
timestamp: 2026-08-05T00:00:00Z
phase: 1d
step: phase-1d-spec-review
pass: 1
reviewed_artifacts:
  - /Users/jmagady/Dev/mdlinkcheck-cloud/BRIEF.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/prd.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/ (12 shards)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ (59 BCs, 14 subsystems)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/prd-supplements/ (4)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/ (9 shards + 7 ADRs)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/ (20 VPs)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/module-criticality.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/dtu-assessment.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/gene-transfusion-assessment.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/planning/brief-validation.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/planning/market-intelligence.md
finding_count: 34
verdict: READY-WITH-CHANGES
---

# Phase 1d Spec Review — Constructive Second Opinion

**Lens:** Is this spec package a good, buildable, well-shaped design — and is it the
right size? Not defect-hunting (adversary's job), not document-agreement checking
(consistency-validator's job). Design quality and proportionality.

**Scope read:** 119 spec files / 12,394 lines, all 59 BCs in full, all 20 VPs in full,
all 12 domain shards, all 9 architecture shards, all 7 ADRs, both planning docs.

**Binding constraints honored:** D-006, D-007, D-008, D-009 and R7's 0/1/2 exit codes are
treated as settled. Findings below address *implementation quality* of those decisions only.

---

## Executive summary

The package is **well-shaped in its bones and mis-allocated in its mass.**

The core architectural idea — a pure `mdlinkcheck-core` crate holding slug, fragment,
path comparison, filters, verdict and exit-code logic, with a thin effectful shell — is
exactly right for this product, and it is the reason the Phase 6 story is credible at all.
The 148-vector EC register in `test-vectors.md` is the single best artifact in the package
and materially de-risks Phase 3. Traceability is dense and, where I sampled it, correct.
All four binding human decisions are traced from L2 through to VPs.

But the volume is in the wrong places. Roughly 22% of the BCs (13 of 59) carry no
independent obligation and exist to fill the subsystem taxonomy, and they are concentrated
in the cheapest subsystems (SS-11..SS-14: 12 BCs, ~950 lines, covering one `max()` and one
`format!`). Meanwhile the four things that will actually decide whether this product is
correct are all thin:

1. The `DirEntries = Vec<OsString>` seam **cannot resolve `docs/sub/a.md`** — it carries
   one directory's names, and every multi-component test vector in BC-2.07.001 needs more.
2. The crown jewel — duplicate-slug collision bumping — is **proven by nothing**. VP-003
   repeats one string; the `Setup`/`Setup`/`Setup 1` → `setup-1-1` case that DEC-001 and
   lychee #1613 are about has no VP and no fixture.
3. **ADR-007 states the frozen R7 exit codes backwards** (2 = broken, 0 = broken-free) —
   inside the ADR governing the CRITICAL `verdict` module, and it is exactly the inversion
   that R-006 exists to prevent.
4. The **acceptance corpus** — the brief's own success criterion and R-002's only named
   mitigation — is in scope by D-009, out of scope by `prd.md` §Non-Goals, owned by nobody,
   and its manifest schema is structurally incompatible with the CLI JSON it is compared to.

None of this requires re-running Phase 1. It requires ~4 targeted spec edits and one small,
well-determined architecture change. Hence READY-WITH-CHANGES rather than NOT-READY.

**Counts:** 5 SHOULD-CHANGE gate blockers, 12 SHOULD-CHANGE non-blocking, 12 CONSIDER,
5 QUESTION-FOR-HUMAN, 8 STRENGTH.

---

# Q1. Proportionality

## SR-001 — Volume is roughly right; allocation is wrong · CONSIDER

**Location:** package-wide (119 files, 12,394 lines, 59 BCs, 14 SS, 20 VPs)

The instinct to call 119 files for a 300-word brief "over-engineered" is half right and it
leads to the wrong remedy. I measured the distribution rather than the total:

| Subsystem group | BCs | Approx. lines | Implementation reality |
|---|---|---|---|
| SS-06 (slug) | 2 | 193 | The product differentiator; R-001/R-002 HIGH; ASM-008 "most consequential unvalidated assumption" |
| SS-07 (paths) | 6 | 520 | D-006; the seam that does not work (SR-010) |
| SS-10 (HTTP) | 8 | 635 | 6 of 8 have no fixture strategy (SR-021) |
| SS-11..SS-14 (filters, reports, exit) | 12 | ~950 | One `max()`, two `format!` calls, two clap declarations |

SS-11..SS-14 receive ~1.5× the specification mass of SS-06+SS-07 combined and represent
perhaps 8% of the implementation risk. That is the shape of the problem: not "too much
spec" but "spec mass uncorrelated with risk."

The tell is mechanical. All 59 BC files fall in a **73–108 line band**, and the five above
88 lines are exactly the five that were hand-revised in v1.1. An information-driven spec
would vary by an order of magnitude — BC-2.06.001 (slug) should be 300 lines with a full
character-class table, and BC-2.12.004 (`--format text` is accepted) should be eight.
Uniform length is the signature of template-fill, not of content.

**Recommendation:** do not cut 30%. Move ~20% of the mass from SS-11..SS-14 into SS-06,
SS-07 and SS-10 by (a) collapsing the ceremony BCs in SR-002, and (b) spending the
recovered budget on the concrete gaps in SR-010, SR-016 and SR-021.

## SR-002 — 13 BCs are ceremony; collapsing them removes ~10 Phase 2 stories · SHOULD-CHANGE

**Location:** the BCs named below

Each of these can be folded into a named sibling with zero information loss. I read every
one in full; these are not judgment calls about style, they are duplicated obligations.

| BC | Fold into | Evidence |
|---|---|---|
| BC-2.11.002 (`--allow` component boundary) | **BC-2.09.002** | Near-verbatim clone. Same ECs (EC-090/091/092), same trap T16, same two VP rows word-for-word, same traceability row. The worst duplicate in the set — and it sits in a *different subsystem*, so it will produce two stories in two waves for one predicate. |
| BC-2.01.007 (path dedup) | **BC-2.01.002** | BC-2.01.002 Inv 1 "Deduplication is by canonicalized real path" ≡ BC-2.01.007 Post 3 "Deduplication is based on the canonicalized real path". |
| BC-2.02.004 (explicit non-`.md` arg parsed) | **BC-2.01.002** | Third statement of one rule; BC-2.01.005 Post 4 is the second. All three share EC-007. |
| BC-2.11.003 (`--ignore` vs explicit PATH) | **BC-2.11.001** | Post 1–4 restate BC-2.11.001 Post 1–3 plus the `[AMB-108]` bracket already embedded there. Inv 2 is not an invariant: "This is a deliberate design decision for script-friendly behavior." |
| BC-2.14.001, BC-2.14.003 | **BC-2.14.002** | BC-2.14.002 Inv 3 already states the whole rule as one formula: "the final exit code is the maximum of (0, any 1-triggering events, any 2-triggering events)". Three files, one `max()`. |
| BC-2.10.003 (10s timeout) | **BC-2.10.001** | Already fully stated in BC-2.10.001 Post 1 + Inv 2 and BC-2.10.002 Post 6. Post 3 duplicates its own Inv 1. |
| BC-2.08.004 (anchor into ignored file) | **BC-2.05.001** | DI-006 is contracted **five times** (BC-2.05.001 Inv 2, BC-2.08.004, BC-2.11.001 Post 3, BC-2.08.002 Inv 3, BC-2.01.003 Inv 2), all sharing EC-074. BC-2.08.004's EC row literally reads "See above". |
| BC-2.12.004 (`--format text` alias) | a new CLI-surface BC (SR-008) | Half restates BC-2.12.001 Pre 2; the rest is clap `ValueEnum` declaration. Only EC-137 (`--format json --format text` → last wins) is real, and it belongs with the other flag-precedence rules. |
| BC-2.13.002 (JSON schema stability) | **delete** | Not a behavior of the SUT. Post 2/Post 4/Inv 2 are statements about future releases and about *consumers*. Its sole EC is EC-141b "Future version changes schema → schema_version incremented" — untestable by construction. The two real claims are already BC-2.13.001 Inv 1 and Post 3. |
| BC-2.03.006 (footnotes/escaped brackets) | keep as a **regression test**, not a BC | Its own Inv 1 concedes: "pulldown-cmark handles both cases by construction; this BC documents the expected behavior." Inv 2: "No special-case footnote filtering code is needed." An obligation whose implementation is "write nothing" is a test, not a contract. |
| BC-2.01.001 (recursive discovery) | keep, but rewrite | Inv 1–4 are all pointers to BC-2.01.003/BC-2.01.004; Post 1 cross-references them too. As written it is a table of contents dressed as a contract. |

Net: 59 → ~47 BCs, and — more valuable than the file count — it removes the cross-subsystem
duplicate pairs (`--allow` in SS-09 *and* SS-11; fragment-split in SS-07 *and* SS-08 per
SR-003) that would otherwise generate the same function twice in two different waves.

## SR-003 — `fragment` split-before-decode is contracted twice in two subsystems · SHOULD-CHANGE

**Location:** BC-2.07.004, BC-2.08.003, `architecture/dependency-graph.md`

DI-003 (split at first unescaped `#` before percent-decode) is contracted by **both**
BC-2.07.004 (SS-07) and BC-2.08.003 (SS-08). They share EC-035 verbatim, and BC-2.07.004
Post 1 ≡ BC-2.08.003 Inv 1. The architecture confirms one module: `fragment.rs`, listed as
a dependency of `path_resolver` in `dependency-graph.md`.

This is worse than the other duplicates because the two BCs sit in subsystems that will
land in **different waves**, so one `split_fragment` function gets two stories and two
test suites with a real chance of divergent expectations. It also breaks the
feasibility-review's verifiability claim — see SR-007.

**Recommendation:** make BC-2.08.003 the sole owner of DI-003 (it has VP-004 and VP-013),
and reduce BC-2.07.004 to percent-*decoding* of the path component only, explicitly
delegating the split.

## SR-004 — Under-specified: 5 `prd.md` behaviors have no BC at all · SHOULD-CHANGE (blocker for 1 of 5)

**Location:** `prd.md` §3 / AMB-037, AMB-043; `prd-supplements/interface-definitions.md`

Grepped the full BC corpus for each. These behaviors are stated in the PRD and contracted
nowhere:

| Behavior | PRD source | Status |
|---|---|---|
| **URL deduplication** ("fetch once, report at every occurrence") | `prd.md` §2.10 line 205 | **NOT CONTRACTED — and load-bearing.** BC-2.10.007 Inv 3 depends on it ("if a redirect target is the same as a URL already in the chain, break immediately") and AMB-037 says loops are detected *"by URL deduplication"*. The mechanism a surviving BC relies on was deleted. Only *path* dedup exists (BC-2.01.002/007), a different mechanism over canonical filesystem paths. |
| **Private/loopback IP ranges** | `prd.md` §2.10 line 208 | NOT CONTRACTED. No BC mentions loopback, RFC1918, `127.0.0.1`, `169.254`, or SSRF. The only nearby text is BC-2.09.001 EC-083 `https://[::1]:8080/path → clean`, which *permits* a loopback fetch with no policy. In `--online` mode this is an unreviewed SSRF surface. |
| **Proxy env vars** (`HTTP_PROXY`/`HTTPS_PROXY`/`NO_PROXY`) | AMB-043, rationale *"required for corporate CI"* | NOT CONTRACTED. Zero occurrences of `proxy` in any BC, ADR, or module. `decisions.md` §Open Questions escalated it and `feasibility-review.md` §Constraint Mapping then declared "No architectural constraints requiring mapping to external systems were identified." |
| **`--help` / `--version` exit 0 without scanning** | `prd.md` §2.14 line 248 | NOT CONTRACTED. BC-2.03.004 Inv 2 *assumes* `--help` exists ("the limitation is documented in the `--help` output"), and R-006's mitigation is "Document the divergence prominently in README and `--help`" — a mitigation resting on an uncontracted surface. |
| **`--offline` flag** | `prd.md` §3, `interface-definitions.md` | NOT CONTRACTED as a flag. Zero occurrences of the literal `--offline` in any BC. BCs contract offline *mode as the default* only. Does the flag exist? Is it a no-op? Does `--online --offline` error, or last-wins as `--format` does per EC-137? Unanswerable. |

**Gate blocker: URL deduplication only** (it breaks BC-2.10.007). The other four are
SHOULD-CHANGE: add three sentences to a new CLI BC (SR-008) plus one BC for URL dedup, or
explicitly move loopback/proxy to Non-Goals with a stated rationale.

## SR-005 — STRENGTH: the 148-vector EC register is the best artifact in the package

**Location:** `prd-supplements/test-vectors.md`

`test-vectors.md` is the canonical EC register: 148 unique EC IDs, each bound to a TV row
with source fixture, link target, filesystem/flag state, **expected exit code**, and
expected verdict. I verified that every EC ID referenced anywhere in the 59 BCs (128 unique)
exists in the register — zero dangling references.

This is what makes the package buildable despite the defects elsewhere. A test-writer who
is handed only `test-vectors.md` can produce a large, correct, deterministic suite. Keep it,
keep it authoritative, and route acceptance criteria through it in Phase 2.

## SR-006 — BC files misattribute at least 6 EC IDs against that register · SHOULD-CHANGE

**Location:** BC-2.07.003, BC-2.11.001, BC-2.11.003, BC-2.01.008, BC-2.14.001, BC-2.10.002, BC-2.10.004

The register is right; several BCs cite the wrong IDs. Verified directly:

| EC | Register (`test-vectors.md`) says | BC using it says |
|---|---|---|
| EC-029 | TV-029: `[x](docs/)`, dir exists → exit 0, clean | BC-2.07.003: "`[x](readme.md)` but file is `README.md` → broken" |
| EC-030 | TV-030: `[x](docs)`, dir exists → exit 0, clean | BC-2.07.003: "NFC vs NFD normalization in filename" |
| EC-072 | TV-072: `[x](notes.txt#section)` → clean, anchor skipped | BC-2.11.001: `--ignore '*.md'` |
| EC-073 | TV-073: `[x](src/main.rs#L42-L50)` → clean | BC-2.11.001 / BC-2.11.003: `--ignore 'docs/a.md'` |
| EC-009 | TV-009: dir symlink not followed | BC-2.01.008 / BC-2.14.001: zero `.md` files found |
| EC-087 | TV-087: self-signed cert → exit 1, broken(`tls-error`) | BC-2.10.002: 429 → indeterminate; BC-2.10.004: 429 with `Retry-After: 30` |

BC-2.07.003 is the worst case: it is the sole BC implementing D-006 (the binding
case-sensitivity decision), and **both** of its edge-case IDs point at directory-link
vectors. Its four canonical test vectors are correct, so the behavior survives — but in
Phase 2 the story-writer will trace ACs to EC-029/EC-030 and land on the wrong tests.

**Recommendation:** one pass reconciling every BC §Edge Cases row against `test-vectors.md`,
with `test-vectors.md` authoritative. Mechanical, ~1 hour, prevents a whole class of
Phase 2 AC drift.

## SR-007 — `prd.md` §2 has drifted from the BC files in 3 of 14 subsystems · SHOULD-CHANGE

**Location:** `prd.md` §2.9–2.14 and §7 RTM vs the actual BC H1 titles

`BC-INDEX.md` matches the files. `prd.md` §2 does not, and `prd.md` looks the more
authoritative of the two. SS-10 has drifted by one slot from `.005` onward and SS-12 by one
from `.002`:

| ID | `prd.md` §2 says | Actual H1 |
|---|---|---|
| BC-2.10.005 | URL deduplication | DNS Resolution Failure Yields `broken` Verdict |
| BC-2.10.006 | Redirect following, max 10 hops | TLS Handshake Failure Behavior |
| BC-2.10.007 | Concurrency 32/4; proxy env vars honored | Redirect Chain Handling (Max 10 Hops) |
| BC-2.10.008 | Private/loopback IP ranges | Concurrency — 32 Global / 4 Per-Host |
| BC-2.12.002 | Stdout/stderr separation | Terminal Color Output with NO_COLOR/CLICOLOR |
| BC-2.12.003 | ANSI color suppression | Stderr Summary Line (Unless `--quiet`) |
| BC-2.12.004 | Summary line `N broken link(s)…` | `--format text` Explicit Alias Is Accepted |
| BC-2.14.003 | `--help`/`--version` exit 0 without scanning | Exit Code 1 — At Least One Broken Link Found |

`prd.md` §7's RTM still carries the stale IDs, and `prd.md` line 480's N-001 guidance
("storywriter must assign BC-2.10.002 to `http_verdict.rs`") happens to survive only
because `.002` did not shift. Priorities also disagree (BC-2.01.006 P0 in PRD / P1 in index;
SS-09 and SS-10 wholesale P1 in PRD / P0 in index), which will corrupt wave scheduling.

Note this is *how* the four uncontracted behaviors in SR-004 were lost: they were dropped
from the middle of the SS-10 and SS-12 sequences and everything shifted up.

**Recommendation:** regenerate `prd.md` §2 and §7 mechanically from `BC-INDEX.md`, and add
the `bc_h1_is_title_source_of_truth` check to the consistency pass so it cannot recur.

## SR-008 — CONSIDER: add one CLI-surface BC group; no subsystem owns the CLI

There is no BC anywhere for the CLI surface as such. Homeless behaviors: `--offline`,
`--help`, `--version`/`-V`, `--format` precedence (EC-137 last-wins), invalid-flag → exit 2,
the `--quiet` × zero-files interaction, and the DD-014 stdout/stderr split at the `main`
boundary. `cli.rs` and `main.rs` map to no subsystem (SR-009).

Folding BC-2.12.004 here plus the four items from SR-004 gives one coherent 3-BC group and
removes four scattered orphans. This is the rare place where the package needs *more* BCs.

---

# Q2. Subsystem decomposition quality

## SR-009 — Two modules holding the most load-bearing invariants have no subsystem · SHOULD-CHANGE

**Location:** `architecture/module-decomposition.md`, `ARCH-INDEX.md` §Subsystem Registry

Mapping SS-01..SS-14 onto the 17 modules:

| SS | Owning module(s) | Note |
|---|---|---|
| SS-01 | `scanner` | clean |
| SS-02 | `scanner` + `link_extractor` | split |
| SS-03 | `link_extractor` | clean |
| SS-04 | `link_extractor` + `anchor_table` | split (SF-003 admits it) |
| SS-05 | `anchor_table` | clean |
| SS-06 | `slug` | clean |
| SS-07 | `path_resolver` + `fragment` | split (SR-003) |
| SS-08 | `anchor_resolver` + `fragment` | split (SR-003) |
| SS-09 | `url_classifier` | clean, but duplicates SS-11 (SR-002) |
| SS-10 | `http_client` + `http_verdict` | split — **the one justified split** (ADR-004 / N-001) |
| SS-11 | `filter` | clean |
| SS-12 | `reporter` | shares a module with SS-13 |
| SS-13 | `reporter` | shares a module with SS-12 |
| SS-14 | `verdict` | clean |

**No subsystem owns `types`, `cli`, `app`, or `main` — 4 of 17 modules.** `types` and `main`
are fine as unowned. `cli` is SR-008. **`app` is the real gap**, and it is serious:

- `app` executes DI-001's mandatory sort. `system-overview.md`: *"This is a mandatory
  late-pipeline step; **no finding may bypass it**."* `module-decomposition.md` places the
  `sort_unstable_by_key` in `app`.
- `app` orchestrates DI-008's two-pass ordering.
- `module-criticality.md` gives `app` **MEDIUM** tier and **VP Count: 0**.
- VP-011 (sort determinism) is attributed to `reporter` — a module that does not perform
  the sort.

So the single strongest invariant statement in the architecture ("no finding may bypass it")
is asserted about a module with no subsystem, no BC, no VP, and a MEDIUM mutation-kill
target. In Phase 2 no story will own it, because story decomposition routes through BCs and
BCs route through subsystems.

**Recommendation:** add **SS-15 Pipeline Orchestration** (`app`: two-pass sequencing, the
DI-001 sort-before-emit gate, I/O-error aggregation) and **SS-16 CLI Surface** (`cli`/`main`,
per SR-008). Promote `app` to CRITICAL. This is not taxonomy hygiene — it is the difference
between DI-001 being tested and not.

## SR-010 — SS-12 and SS-13 should be one subsystem · SHOULD-CHANGE

**Location:** `prd.md` §2.12–2.13, BC-INDEX SS-12/SS-13, `module-decomposition.md`

SS-12 (Text Report Generation, 4 BCs) and SS-13 (JSON Report Generation, 2 BCs) both map to
`reporter.rs`, whose entire surface is two sibling functions over the same input:

```
fn format_text(findings: &[Finding], opts: ReportOpts) -> String
fn format_json(findings: &[Finding]) -> String
```

They share the `Finding` type, the sort order, the reason-code taxonomy, and the
stdout/stderr contract. "Text" and "JSON" are two words, not two responsibilities. This is
the clearest case in the package of a subsystem boundary existing to fill the taxonomy: it
guarantees at least two stories, two test files and two waves for one 2-function module,
and it splits the reason-code rendering rule (SR-019) across a boundary where it then
becomes inconsistent.

**Recommendation:** merge into **SS-12 Report Generation** (6 BCs → 4 after SR-002's
folds). Judged by the stated test — "could a story be delivered against it independently" —
SS-13 fails: you cannot deliver JSON output without the `Finding` sort and the reason
taxonomy that SS-12 owns.

## SR-011 — SS-09 and SS-11 overlap; SS-09 does not survive the independence test · CONSIDER

SS-09 (External URL Syntax Validation, 2 BCs → `url_classifier`) contains BC-2.09.002
`--allow Suppresses External URL Checks`, which is a near-verbatim clone of BC-2.11.002 in
SS-11 (SR-002). Strip the duplicate and SS-09 is one BC: "parse with `url 2.5`, malformed →
broken". That is a legitimate module but a thin subsystem, and the `--allow` predicate
genuinely belongs to `filter` (SS-11) since that is where `should_allow` lives per
`purity-boundary-map.md`.

**Recommendation:** keep SS-09 as a one-BC subsystem (defensible — `url_classifier` is a
real module with a real dependency on the `url` crate), delete BC-2.09.002, and let SS-11
own `--allow` end-to-end. Alternatively merge SS-09 into SS-11 as "URL classification and
filtering". Either is better than the current double-contract.

## SR-012 — SS-10 hides two responsibilities and the taxonomy does not admit it · CONSIDER

SS-10 splits across `http_verdict` (pure, Kani-provable, VP-007) and `http_client`
(effectful, network). `feasibility-review.md` N-001 identifies this correctly and instructs
the story-writer to partition the BCs by hand:

> "BC-2.10.002 … story touches `http_verdict.rs` (pure); BC-2.10.001, BC-2.10.003..008:
> stories touch `http_client.rs` (effectful). Do not implement HTTP classification logic
> inside `http_client.rs` — it must be split to preserve Kani provability of VP-007."

That is the correct design decision recorded in the wrong place. A purity boundary this
important should be visible in the subsystem taxonomy, not in a review note that a
story-writer may not read.

**Recommendation:** split into **SS-10a External URL Verdict Classification** (pure,
`http_verdict`, BC-2.10.002) and **SS-10b External URL Liveness Fetching** (effectful,
`http_client`, the rest). This makes the ADR-001 boundary self-enforcing at the story level:
a story assigned to SS-10a physically cannot acquire an I/O dependency.

## SR-013 — STRENGTH: 10 of 14 subsystems map 1:1 to a coherent module

SS-01, SS-03, SS-05, SS-06, SS-09, SS-11, SS-12, SS-13, SS-14 each map to exactly one
module, and the module boundaries follow the data flow rather than the requirement text.
`slug`, `fragment`, `filter`, `verdict` and `http_verdict` are each a small pure function
with a single reason to change. For a 14-subsystem decomposition of a CLI, that hit rate is
good — the four splits (SS-02, SS-04, SS-07, SS-08) are all narrow and three of the four are
the *same* underlying issue (`fragment` co-ownership, SR-003).

## SR-014 — Two conflicting build orders, neither marked authoritative · SHOULD-CHANGE

**Location:** `architecture/dependency-graph.md` vs `module-criticality.md`

Both documents publish a module build order for Phase 2. They disagree in three places:

1. `module-criticality.md` puts `anchor_resolver.rs` on the **same tier** as `anchor_table.rs`;
   `dependency-graph.md` correctly has `anchor_resolver ← types, anchor_table` (step 3 → 4).
   The `module-criticality.md` ASCII graph is wrong on its face.
2. `link_extractor` is step 3 in one, row 4 / priority 8 in the other.
3. `cli` before `app` in one, after in the other.

`ARCH-INDEX.md` §Document Map lists `dependency-graph.md` for "story-writer, implementer".
`module-criticality.md` **is not in the Document Map at all**, yet it carries a competing
17-step "Implementation Priority Order". Story decomposition will read whichever it opens
first, and `dependency-graph.md` asserts *"Stories MUST implement modules in dependency
order to satisfy the Red Gate"* without saying which order the Red Gate checks.

**Recommendation:** mark `dependency-graph.md` authoritative, delete the build order from
`module-criticality.md` (leave it the criticality tiers and mutation targets it is for),
and add `module-criticality.md` to the ARCH-INDEX Document Map.

---

# Q3. Purity boundary quality

## SR-015 — STRENGTH: the boundary is drawn in the right place, and for the right reason

ADR-001's boundary is well-chosen. Every function it places in the pure core is genuinely a
total function over data with a provable property worth having:

- `slug::compute` — the differentiator; must be Kani-targetable or the pilot has no Phase 6 story
- `fragment::split` — DI-003; a pure string scan
- `verdict::exit_code` — DI-010/DI-011; a pure fold over a slice
- `http_verdict::classify_response` — the D-008 three-verdict decision, correctly severed from `ureq`
- `filter::{should_ignore, should_allow}` — pure predicates
- `reporter::format_*` — returns `String`, does not print

And the crate split (`mdlinkcheck-core` lib + `mdlinkcheck` bin) is the right *mechanism*:
it makes the boundary type-level and reviewable rather than advisory. ADR-001's rejection of
trait-based DI in favour of a data-passing seam is well-argued and correct for this size of
product — trait objects would have bought testability the seam already provides, at the cost
of dynamic dispatch and proof complexity.

`reporter` sitting in the pure crate while marked "Kani-targetable? No" is also correct and
worth noting as good judgment: purity and proof-worthiness are different questions, and the
package distinguishes them.

## SR-016 — `DirEntries` leaks in three distinct ways; SS-07 is not implementable as specified · SHOULD-CHANGE (GATE BLOCKER)

**Location:** `architecture/api-surface.md:71-72`, ADR-001:47-49, `purity-boundary-map.md:47-50`, `module-decomposition.md:56-58,82-83`, BC-2.07.001, BC-2.07.005

The type, quoted from the only place it is defined (`api-surface.md`):

```rust
pub fn resolve_path(dest: &str, src_dir: &Path, dir_entries: &DirEntries) -> PathVerdict;
pub type DirEntries = Vec<OsString>;  // populated by scanner, passed as data
```

and the seam, from `module-decomposition.md`:

> "The `DirEntries` for **a file's containing directory** are populated once by `scanner`
> during Pass 1 and passed as immutable data to `path_resolver` during Pass 2."

**Does it work? No — three independent leaks.**

**(a) It cannot resolve multi-component paths.** `DirEntries` is *one* directory's names, and
it is the **source** file's directory. Every multi-component vector in BC-2.07.001 needs a
different directory's entries:

> BC-2.07.001 EC-024: "`[x](sub/nested.md)` → Resolves to `docs/sub/nested.md`"
> BC-2.07.001 TV: source `docs/guide.md`, dest `../api/ref.md` → "file existence check"

Resolving `sub/nested.md` from `docs/guide.md` needs the entries of `docs/sub/`. Resolving
`../api/ref.md` needs the entries of `api/`. Neither is in the seam. BC-2.07.003 Pre 2
states the requirement without the mechanism — *"The resolved path's parent directory is
readable"* — the **target's** parent, which `path_resolver` is never handed. And because
D-006 requires exact-case comparison per component, you cannot shortcut this: you need
entries for every intermediate directory, not just the last.

BC-2.07.001 Inv 3 resolves the contradiction the wrong way:

> "3. The resolved path is then existence-checked using filesystem APIs."

That puts `fs` inside `path_resolver`, which `purity-boundary-map.md` asserts *"never
touches the filesystem"* and which BC-2.07.003 Inv 1 forbids for the match decision. One of
the two must go, and nothing in the package adjudicates it. If Inv 3 wins, ADR-001's entire
stated rationale evaporates ("This single choice makes the case-sensitive NFC comparison
formally verifiable (VP-008)").

**(b) It carries no file type, so two reason codes can never be emitted.** `Vec<OsString>`
is names only; `fs::read_dir` yields `DirEntry` with `file_type()` and the spec explicitly
discards it. Therefore:

- `target-is-directory` (broken, exit 1) — BC-2.07.005 Pre 2 says *"The resolved path exists
  on the filesystem and is a directory"*. Undecidable from names.
- `broken-symlink` (broken, exit 1) — a dangling symlink appears in `Vec<OsString>`
  identically to a healthy file. `path_resolver` will report "exists" for every dangling
  symlink. **This reason code can never be produced**, which also makes NFR-007's closed-set
  assertion vacuous for it.

**(c) The scan set does not supply the directories that links point into.** `scanner`
populates `dir_entries` only for directories it visits, via `ignore::WalkBuilder`, which
skips dot-directories and respects `.gitignore`. So:

- `[img](assets/logo.png)` where `assets/` holds no markdown — never enumerated, existence
  unknowable, silent wrong verdict either way.
- `[x](../vendor/README.md)` where `vendor/` is `.gitignore`d — same.
- `mdlinkcheck docs/` with `[x](../README.md)` — target above the scan root.

There is no fallback rule, no "if no DirEntries available then…" clause, and no
`indeterminate` escape hatch for unknowable local paths (ADR-007 reserves `indeterminate`
exclusively for HTTP conditions).

Note also that **VP-008 does not exercise any of this.** It proves `files_match(a, b)`
reflexivity/symmetry over two strings; it never touches `resolve_path` or `DirEntries`. The
proof would pass over a resolver that cannot resolve anything.

`feasibility-review.md` missed this: its Integration Feasibility section declares PASS on a
Pass-1→Pass-2 seam typed `HashMap<PathBuf, (AnchorTable, Vec<ExtractedLink>)>` — a type that
carries **no `DirEntries` at all**.

**Recommendation — and this is my single highest-value one, see the closing section.**
Preserve ADR-001; change the seam and add one shell phase:

```rust
// core::types
pub enum EntryKind { File, Dir, Symlink { dangling: bool } }
pub struct DirEntryInfo { pub name: OsString, pub kind: EntryKind }
pub type DirIndex = HashMap<PathBuf, Vec<DirEntryInfo>>;   // keyed by directory

pub fn resolve_path(dest: &str, src_dir: &Path, index: &DirIndex) -> PathVerdict;
```

and a three-phase pipeline:

```
Pass 1  (shell + pure) : discover, read, parse, extract links, build anchor tables
Pass 1.5 (shell only)  : from all extracted links, compute the set of
                         (a) target directories along every path, and
                         (b) target .md files not already in the scan set;
                         read_dir each directory (with file types), parse each extra .md
Pass 2  (pure only)    : resolve every link against DirIndex + AnchorIndex
Sort / emit / exit
```

Pass 1.5 is pure bookkeeping in the shell and costs one extra `read_dir` per distinct target
directory. It fixes (a), (b) and (c) at once, it fixes the two-pass bootstrapping hole in
SR-024, and it makes `path_resolver` genuinely pure so ADR-001's rationale holds. `resolve_path`
becomes *more* Kani-provable, not less, because `DirIndex` is still plain data.

## SR-017 — Pure logic wrongly left in the shell: BOM/CRLF, line mapping, color decision · SHOULD-CHANGE

**Location:** BC-2.02.002, `feasibility-review.md` SF-001, `purity-boundary-map.md:66-73`, BC-2.12.002

Three pure functions are stranded in the effectful shell, and two of them are things you
would most want to test:

1. **BOM stripping and CRLF normalization.** SF-001 assigns both to `scanner.rs` (shell).
   But `strip_bom(&[u8]) -> &[u8]` and `normalize_line_endings(&str) -> Cow<str>` are pure.
   SF-001 even notices — *"The story must distinguish detection (effectful shell) from
   stripping (could be pure helper). Recommend: scanner detects and strips in one step
   during file read"* — and then recommends the less testable option. Read the bytes in the
   shell; normalize in the core.

2. **`link_line_map` (byte-offset → line).** `ParsedFile` declares
   `pub link_line_map: Vec<usize>,  // byte-offset → line mapping (precomputed)` — computed
   in `scanner`. This is a pure fold over a `&str`, and it is the function KD-003
   (source-level `file:line` reporting, a stated differentiator) entirely depends on. Its
   interaction with CRLF is exactly where off-by-one line numbers come from. It belongs in
   the core with a proptest asserting `line_of(offset)` is monotonic and 1-based.

3. **The color decision.** `cli` correctly reads `NO_COLOR`/`CLICOLOR` env vars in the shell,
   but BC-2.12.002's *decision* logic — the precedence among TTY-ness, `NO_COLOR`,
   `CLICOLOR=0`, `CLICOLOR_FORCE` — is unassigned. It should be
   `fn should_colorize(is_tty: bool, no_color: bool, clicolor: Option<&str>, force: bool) -> bool`
   in the core, which also gives BC-2.12.002 the testable observable it currently lacks
   (SR-022).

## SR-018 — CONSIDER: the boundary rule needs a mechanical enforcement hook

ADR-001 says *"Violations are detectable by code review and by `cargo deny` rules"*, but
`cargo deny` checks dependency licences and advisories — it cannot detect `std::fs` usage
inside a module. The available mechanisms are `#![forbid(...)]`-style lints, a `clippy.toml`
disallowed-methods list, or (most robustly) simply not adding `std::fs`-using dependencies to
`mdlinkcheck-core`'s `Cargo.toml` at all — which the two-crate split already mostly achieves
for `net`/`ureq` but not for `std::fs`.

**Recommendation:** name the actual mechanism in ADR-001 — a `clippy.toml`
`disallowed-methods` entry for `std::fs::*`, `std::net::*`, `std::time::Instant::now`,
`std::process::*` scoped to the core crate, enforced in CI. One file, and it converts an
advisory boundary into a checked one. Without it, Phase 3's first convenient `fs::metadata`
call silently invalidates the Phase 6 proof story.

---

# Q4. Verification strategy quality

## SR-019 — VP-003 does not assert injectivity; the crown jewel is unverified · SHOULD-CHANGE (GATE BLOCKER)

**Location:** `verification-properties/vp-003-slug-duplicate-uniqueness.md`, BC-2.06.002, `verification-architecture.md:27`

The property, verbatim:

> "Given a sequence of N **identical** heading strings `s` (N bounded to 10), each processed
> through `compute_slug(s, &mut counter)` with a shared `DuplicateCounter`, no two calls
> return the same `String`."

The harness quantifies over exactly **one** symbolic string, repeated:

```rust
for _ in 0..n {
    results.push(compute_slug(s, &mut counter));   // same `s` every iteration
}
```

This is strictly weaker than injectivity and it misses the only hard case. BC-2.06.002's own
Description defines that case:

> "when `## Setup` appears twice AND `## Setup 1` also appears, the second `## Setup`
> produces `setup-1` which collides with the slug for `## Setup 1`; thus `## Setup 1` gets
> bumped to `setup-1-1`."

With `s` fixed, github-slugger's `while` collision-bump branch is **unreachable in this
harness**. The behavior that DEC-001, TV-S012 and lychee #1613 are all about is proven by
nothing. It is also fixtured by nothing: VP-018 has no shared-counter case at all, despite
NFR-006 explicitly requiring "all 10 worked examples **+ DEC-001 collision case**".

`verification-architecture.md:27` then over-claims what VP-003 delivers:

> "| VP-003 | `DuplicateCounter` uniqueness — no two **headings** collide after dedup (bound 10) |"

"No two headings collide" is an injectivity claim. The VP body supports only "no two calls
with the same heading collide."

Secondary defect: the statement's second sentence ("calls 2..N return `slug-{n}` where
`n = count - 1`") is **not asserted anywhere** — only pairwise `assert_ne!`. A wrong-but-unique
suffix scheme (`slug-0`, `slug-1`, …) passes VP-003.

**Recommendation (cheap and high-yield):** add a proptest over a `Vec` of *distinct* heading
strings asserting set-size equality —

```rust
proptest!(|(headings: Vec<String>)| {
    let mut c = DuplicateCounter::new();
    let slugs: Vec<String> = headings.iter().map(|h| compute_slug(h, &mut c)).collect();
    prop_assert_eq!(slugs.len(), slugs.iter().collect::<HashSet<_>>().len());
});
```

— which is unbounded-ish, runs in milliseconds, and finds the collision-bump bug on
essentially the first shrink. Then add the DEC-001 / TV-S012 triple to VP-018 as an explicit
fixture. Optionally strengthen VP-003 to two independent symbolic strings; the proptest is
the higher-value half.

## SR-020 — VP-018's golden table contains two provably wrong rows · SHOULD-CHANGE (GATE BLOCKER)

**Location:** `verification-properties/vp-018-slug-worked-examples.md`

VP-018 is the *sole* guard on the primary product differentiator, and two of its 13 rows are
wrong against the normative algorithm in BC-2.06.001:

```rust
("Hello, World!",         "hello-world-1"),   // WRONG
("  Leading spaces  ",    "leading-spaces"),  // WRONG — comment says "trimmed"
```

1. `("Hello, World!", "hello-world-1")` — the harness allocates
   `DuplicateCounter::new()` *inside* the loop, so no dedup can occur. Expected is
   `hello-world`, which is what BC-2.06.001 PC3 and TV-S004 say.
2. `("  Leading spaces  ", "leading-spaces")` contradicts BC-2.06.001 PC1(d): *"Each U+0020
   space is replaced with `-` (1:1 mapping; **no run collapsing; no trimming**)."* The
   verbatim github-slugger source (market-intelligence §4.1) is
   `value.replace(regex,'').replace(/ /g,'-')` — no `trim()`. Correct output is
   `--leading-spaces--`. TV-S015 (`## Foo <a name="bar"></a>` → `foo-`) independently proves
   non-trimming.

Also: rows 1 and 3 are byte-identical duplicates, inflating the "13".

This is the most dangerous defect class in the package, because the failure mode is not a red
test — it is an implementer "fixing" the implementation to match a wrong golden file and
dragging the differentiator off-spec permanently. And the worked-example count is stated
three different ways: VP-018 says 13, NFR-006 says "10 + DEC-001 collision case" (=11),
`test-vectors.md` §7 has 16 (TV-S001..TV-S016).

**Recommendation:** replace VP-018's inline table with `test-vectors.md` §7's 16 vectors as
the single source, fix the two wrong rows, add the DEC-001 shared-counter triple, and add the
five highest-signal omitted vectors (TV-S005 `hello--world`, TV-S007/S016 emoji,
TV-S010 backticks, TV-S014 `use---online-now`, TV-S015 HTML text excluded) — these are
exactly where a clean-room reimplementation drifts.

## SR-021 — No differential oracle against real github-slugger; ASM-008 is unmitigated · SHOULD-CHANGE

**Location:** ASM-008, NFR-006, VP-018, `verification-architecture.md`

`assumptions.md` calls ASM-008 *"the most consequential unvalidated assumption: if GitHub's
algorithm has diverged from github-slugger v2, **every anchor check is wrong**"* — HIGH impact,
Medium confidence. Its stated validation is *"Run test fixtures from DD-015 worked examples
against live GitHub-rendered pages; compare slugs"*, and it is marked "Holdout candidate: yes",
i.e. deliberately routed away from the VP set.

The result: the entire fidelity guarantee for a clean-room reimplementation rests on
hand-typed tuples authored from the same mental model as the implementation — a
self-referential test. Grepping for `differential|oracle|golden|github-slugger` across
`verification-properties/` and `verification-architecture.md` returns nothing.

**Recommendation:** add a **generated** vector file. A ~15-line committed Node script that
`require('github-slugger')` and emits `slug-vectors.json` over a few thousand inputs
(the 16 hand vectors + ASCII punctuation sweep + a Unicode/emoji sample + duplicate
sequences), with the output committed and a `just regen-slug-vectors` target plus a CI check
that regeneration is a no-op. This converts "we believe we match github-slugger v2" into "we
verify it, and we detect the day it changes." It is the cheapest large risk reduction
available in this package, and it does not require network access at test time (unlike the
live-GitHub validation, which `dtu-assessment.md` disqualifies anyway).

## SR-022 — VP-007 proves totality but asserts nothing about correctness; D-008's thesis has no VP · SHOULD-CHANGE

**Location:** `verification-properties/vp-007-http-verdict-total.md`, BC-2.10.002

VP-007 is Kani, exhaustive over `u16 × {HEAD, GET}` (131,072 combinations) — genuinely the
right use of a model checker for a small closed domain, and a STRENGTH in method choice.
But it asserts only that `classify_response` does not panic and returns one of three
variants. **A function returning `Alive` for 404 passes VP-007.**

Meanwhile BC-2.10.002's two substantive rows are both `VP-TBD`:

> `| VP-TBD | 429/5xx/timeout never produces broken verdict |`
> `| VP-TBD | 404/410 produce broken (after fallback) |`

The first is the entire anti-false-positive thesis of the product — D-008, ADR-007, KD-002,
the reason the brief's "without false positives that train people to ignore it" is
achievable — and it has **no verification property at all**.

**Recommendation:** this is a two-line addition to the harness VP-007 already has, and it is
the highest-ROI verification change in the package:

```rust
let v = classify_response(status, attempt);
if (500..600).contains(&status) || status == 429 || status == 999 {
    assert!(!matches!(v, Verdict::Broken(_)), "transient status must never be broken");
}
if status == 404 || status == 410 {
    assert!(matches!(v, Verdict::Broken(_)));
}
```

Exhaustive over all `u16`, no new tooling, no new bound. Do this before the gate.

## SR-023 — Over-powered Kani: VP-002, VP-005, VP-006 spend the proof budget badly · CONSIDER

Three of the seven Kani proofs are poor value, and their budget is exactly what SR-019 and
SR-022 need.

- **VP-002 (slug determinism) is nearly unfalsifiable by Kani.** CBMC evaluates a pure
  function twice over the same symbolic input; `assert_eq!(slug1, slug2)` can only fail if
  the function reads state CBMC models as nondeterministic. The risks the VP names —
  *"hidden global state, thread-local state, or random element"* — are precisely what CBMC is
  worst at seeing (`Instant::now`, `HashMap` with `RandomState`, thread-locals are typically
  stubbed or unsupported). The proof will pass whether or not the property holds in
  production. A `clippy.toml` disallowed-methods rule (SR-018) plus VP-018's fixtures carry
  the same information for a fraction of the cost.
- **VP-005 / VP-006** reduce to a 3-bool and a 1-bool truth table — the VPs state it
  themselves: "state space = 8", "state space = 2". Two Kani harnesses, two undefined helper
  functions (`build_symbolic_findings`, `build_symbolic_io_errors`), and CBMC tuning to cover
  ten states that one table-driven unit test covers exactly and with no modeling risk.
  BC-2.14.002 already prescribes `unit test`. Worse, as written they prove a property of a
  *model* of `exit_code` rather than of `exit_code` over real `&[Finding]` —
  `verification-architecture.md`'s sketch is explicit about this, proving
  `compute_exit_code_symbolic(has_broken, has_io_error)`, **a different function than the one
  under contract**.

**Recommendation:** demote VP-002, VP-005 and VP-006 to unit/fixture tests. Kani budget goes
from 7 → 4 (slug totality, fragment split, http_verdict exhaustive, and a new
two-independent-strings slug harness if desired). Reinvest in SR-019's proptest, SR-021's
oracle, and SR-022's assertions. Fewer, sharper proofs — and a Phase 6 that stays green
rather than fighting CBMC timeouts on harnesses that prove nothing.

## SR-024 — Under-powered where it matters: VP-008, VP-015, VP-017 · SHOULD-CHANGE

- **VP-008 (D-006 path comparison) does not test what it claims, and its third property is
  copy-paste debris.** The test is named `vp008_percent23_not_split` (copied from VP-004) and
  its strategy is `"[a-z/\\.]+%23[a-z/\\.]*"` — an ASCII percent-encoding generator being used
  to test NFC/NFD equivalence. `to_nfd` of an ASCII string is the identity, so
  `nfc == nfc_normalize(&nfd)` is trivially true and property 3 degenerates into a duplicate
  of property 1. **The NFC/NFD path-equivalence claim in VP-008's own property statement is
  tested by none of its three harnesses.** And D-006's case-sensitivity half — DI-002's *"No
  case-folding is applied"* — has **no assertion at all**; reflexivity and symmetry are both
  satisfied by a case-*insensitive* comparator. Add
  `prop_assert!(!files_match(OsStr::new("README.md"), OsStr::new("readme.md")))` and a real
  NFC/NFD strategy over accented characters. This is the binding human decision's only
  property test.
- **VP-015 (two-pass completeness, DI-008) rests on 2 fixtures and observes only the
  symptom.** "Zero broken findings on a 2-file tree" is passed by a single-pass
  implementation that happens to process `b.md` first. Add a structural assertion — a
  `sealed: bool` on `AnchorIndex` with a `debug_assert!(index.sealed)` at every lookup site —
  which actually verifies the invariant rather than a consequence of it.
- **VP-017 (scan termination) downgrades its own BC's prescribed method** and asserts on the
  wall clock: `assert!(elapsed < Duration::from_secs(5))`. BC-2.01.004 asks for
  `proptest`. A timing assertion on a two-node symlink-cycle fixture is a smoke test and a
  flaky-CI generator. Make it a proptest over generated directory graphs with a visited-set
  assertion, and drop the timing bound.
- **VP-019's oracle is its own strategy.** `arb_markdown_with_links()` is generated from the
  same mental model as the extractor, and the VP concedes the property "holds by construction
  if `into_offset_iter` yields each event once" — so it tests `pulldown-cmark`, not
  `link_extractor`. Low value; keep only if free.

## SR-025 — 99 `VP-TBD` rows advertise obligations that do not exist · SHOULD-CHANGE

**Location:** all 59 BC files; `verification-coverage-matrix.md`

`VP-TBD` appears **99 times** across the BC corpus. Every BC carries a "Verification
Properties" table and 99 of those rows point at a VP that was never created. Twenty VPs
exist. Independently checked, **44 of 59 BCs have no VP at all** — including all of SS-13,
seven of eight SS-10 BCs, BC-2.05.002 (slug-dependent anchor table construction), and
BC-2.14.003 (exit 1, the R7 case that actually fires in CI).

`verification-coverage-matrix.md` does not track this: it has no BC-level coverage section,
only VP-to-module and per-module tables, and its "DI Coverage Summary" reports 11/11 and
stops.

To be clear, 44 uncovered BCs is **not** automatically a problem — not every BC needs a
formal property, and the 148-vector EC register plus integration tests are the right coverage
mechanism for most of them. The problem is the *advertisement*: a story-writer reading the BC
files sees 99 verification obligations and will either invent 79 VPs (Phase 2 explosion) or
silently drop them (coverage theatre).

**Recommendation:** rename the BC column from `VP-NNN` to `Verification` and put the actual
method there (`unit`, `integration`, `TV-nnn`, or a real `VP-NNN`). Add a BC→VP coverage
section to `verification-coverage-matrix.md` stating explicitly which BCs are
test-sufficient by design. Also fix VP-INDEX's frontmatter arithmetic (`p1_count: 8` vs 7
rows; `test_sufficient_count: 5` vs 6 rows).

## SR-026 — STRENGTH: the bounded-proof → unbounded-fuzz escalation ladder is well designed

VP-001 (Kani, `[u8; 64]`) → VP-012 (fuzz, unbounded UTF-8, 1M executions) and VP-004
(Kani, `[u8; 32]` ASCII) → VP-013 (fuzz, unbounded) is exactly the right pattern, and VP-012
states the rationale correctly: *"This extends VP-001's Kani-bounded proof to unbounded input
lengths and adversarial UTF-8 constructions."* No VP claims a proof over unbounded Unicode
(which would be infeasible) — every string harness is byte-bounded and the fuzzers carry the
unbounded case. This is the most sophisticated part of the verification design.

Two bookkeeping fixes: `verification-architecture.md`'s VP-001/002 sketch uses
`assume(len <= 16)` while VP-001 uses 64 and VP-002 uses 32 — three bounds for two proofs
across two authoritative docs. And VP-007 self-contradicts on its own bound (statement says
"0..=999", method table says "exhaustive over u16"; the harness is the stronger and correct
one).

---

# Q5. Buildability for Phase 2 / Phase 3

## SR-027 — BC-2.03.003 rests on a false premise about pulldown-cmark · SHOULD-CHANGE (GATE BLOCKER)

**Location:** `behavioral-contracts/ss-03/BC-2.03.003.md`

> "When a reference link's label has no corresponding definition in the file, pulldown-cmark
> emits a `LinkType::ReferenceUnknown`, `CollapsedUnknown`, or `ShortcutUnknown` event."

pulldown-cmark emits the `*Unknown` variants **only when a `broken_link_callback` is
installed on the parser**. With a plain `Parser::new()`, an undefined `[x]` is emitted as
plain text and no link event exists at all. Invariant 2 doubles down: *"pulldown-cmark's
`*Unknown` variants make this distinction automatic and reliable."*

The architecture already knows this — `purity-boundary-map.md` line 78 says the scanner runs
`pulldown-cmark::Parser::new_with_broken_links()`. The BC does not, and `broken_link_callback`
appears nowhere in the BC corpus.

**Consequence for Phase 3:** a test-writer produces BC-2.03.002's shortcut-reference vector
(`[x]` with no definition → `undefined-reference-definition`) as a test that can never pass,
and the implementer has to reverse-engineer the callback. This is exactly the "test-writer
could not turn this into a failing test" case you asked me to look for — except worse: they
*can* write the test, and it will fail forever for the wrong reason.

**Recommendation:** add to BC-2.03.003 Preconditions: *"`scanner.rs` constructs the parser
via `Parser::new_with_broken_links(text, opts, Some(&mut callback))`; the callback returns
`None` so the destination is empty and the link is retained as `*Unknown` for classification."*
Two sentences, and it unblocks SS-03.

## SR-028 — Six of eight SS-10 BCs have no fixture strategy · SHOULD-CHANGE

**Location:** BC-2.10.004, .005, .006, .007, .008 (and .003 by inheritance)

A test-writer cannot produce a deterministic failing test from any of these:

| BC | Blocking gap |
|---|---|
| BC-2.10.004 (429 pause-host) | The observable is a **timing side effect** with no assertion hook. "Pause host 60 seconds" needs an injectable clock — none is specified anywhere. Post 4 ("After the pause elapses, requests resume") names no output string, counter, or log line. A literal test sleeps 60s. |
| BC-2.10.005 (DNS failure) | EC-081 names a **live network dependency** (`https://this-domain-does-not-exist-xyz-123.com`) while the VP row says "mock DNS resolver". No injection seam exists. And Inv 2 defers the decision to the coder: *"A resolver connectivity failure MAY be indeterminate; implementer judgement — default to broken."* You cannot assert on implementer judgement. |
| BC-2.10.006 (TLS) | Needs expired, self-signed and hostname-mismatch certs. No local TLS server, no cert-generation fixture, no `badssl.com`. Post 2 also requires distinguishing "succeeded *because* verification was skipped" from "would have succeeded anyway" with no mechanism given. |
| BC-2.10.007 (redirects) | 11-hop chain and HTTPS→HTTP downgrade need a controlled server. And AMB-037 says the downgrade produces *"an `indeterminate` warning **appended to finding**"* — the warning string is nowhere, so the assertion target is unknown. |
| BC-2.10.008 (concurrency 32/4) | No way to observe in-flight count. Inv 3 is unassertable: *"Total parallelism does not exceed available rayon thread count"* — on a 4-core box this conflicts with the 32-global claim and the BC does not say which wins. |

`dtu-assessment.md` *does* contain the answer (httpmock, per-fallback-code mocks, a
rayon-scope pattern for the 429 case) — but it is not referenced from any SS-10 BC, so a
test-writer working from the BCs will not find it.

**Recommendation:** add one shared "Test Harness" precondition to all SS-10 BCs naming
`httpmock` as the fixture mechanism and an injectable `Clock` trait (or a
`pause_duration_override` test hook) for BC-2.10.004. Cross-reference `dtu-assessment.md`
from BC-INDEX §SS-10. Also close BC-2.10.005 Inv 2's "implementer judgement" with a decision.

## SR-029 — Three smaller items an implementer must guess · SHOULD-CHANGE

1. **`canonicalize_logical()` does not exist.** BC-2.07.001 Post 1: *"The resolved path =
   `source_dir.join(destination_path).canonicalize_logical()`."* Not a Rust std function and
   defined nowhere in the package. Define it: lexical `..`/`.` resolution with no filesystem
   access, no symlink following.
2. **Is `<reason>` in text output a machine code or prose?** BC-2.12.001's format is
   `<file>:<line>: <link_target> — <reason>` and its test vector is
   `a.md:5: missing.md — file-not-found` (machine code). BC-2.13.002 Post 4 says *"Human-readable
   message strings (text output) are NOT stable"* (prose). A test-writer cannot author the
   golden text output. Pick the machine code — it matches the vector, it keeps SS-12/SS-13
   consistent, and it makes text output greppable in CI.
3. **BC-2.12.002 gives no ANSI sequences.** "broken findings in red, indeterminate in yellow,
   file path in bold" — `\x1b[31m` or `\x1b[1;31m`? And Inv 3 (*"stderr diagnostic messages
   **may also** use color"*) is not testable. Name the exact sequences, or specify the crate
   (`anstyle`/`owo-colors`) and its exact output.

## SR-030 — Zero BCs (bar one) have an Acceptance Criteria section · CONSIDER

Only BC-2.04.003 has an §Acceptance Criteria section (2 rows). The other 58 have
preconditions/postconditions/invariants/edge-cases/test-vectors but nothing labelled AC.
Also: the `Architecture Module` field is **absent entirely from 37 of 59 BCs** (all of SS-05
through SS-14 except the four hand-patched files), a further 18 carry the unfilled
`[filled by architect]` placeholder, and only **4 of 59** are actually routed to a module.
`subsystem: "SS-TBD"` remains in the frontmatter of all 13 SS-11..SS-14 BCs.

This is survivable — postconditions plus test vectors are a perfectly good AC source, and the
story-writer can derive ACs mechanically — but it means the story-writer must do the routing
work that the architect was supposed to do, for 55 of 59 BCs, using two conflicting build
orders (SR-014).

**Recommendation:** before Phase 2, run one mechanical pass filling `Architecture Module` and
`subsystem` from `BC-INDEX.md` + `module-decomposition.md`. This is ~30 minutes of scripted
edits and it removes the single largest source of Phase 2 guesswork.

---

# Q6. Risk concentration — where this design is most likely to be wrong in a way tests won't catch

Ranked by (probability of being wrong) × (probability tests miss it) × (cost).

## SR-031 — Top 5 concrete risks · CONSIDER (all)

**1. Slug divergence from GitHub (ASM-008, R-001).**
*Why tests miss it:* every slug test expectation is hand-authored from the same reading of
the same source as the implementation. A shared misreading is invisible — the tests and the
code agree and both are wrong. Two of the 13 golden rows are *already* wrong (SR-020), which
demonstrates the failure mode is live, not hypothetical.
*De-risk:* SR-021's generated oracle. Highest value per hour in the package.

**2. Path resolution silently wrong for targets outside the scan set (SR-016c).**
*Why tests miss it:* every fixture in `tests/corpus/` will live *inside* the corpus, so the
DirEntries will always happen to be available. The failure only appears against a real repo
with a `.gitignore`d `vendor/`, an `assets/` directory holding no markdown, or a `docs/`-only
invocation. Self-consistent fixtures cannot detect a scan-set-boundary bug.
*De-risk:* three mandatory corpus fixtures with defined expected verdicts — (a) link into a
`.gitignore`d file, (b) link to a non-markdown file in a markdown-free directory, (c)
`mdlinkcheck docs/` with a `../README.md` link. Plus the BV-013 self-test already in the
package (`mdlinkcheck BRIEF.md` → exit 0) extended to `mdlinkcheck .` on this repo, which
has exactly this shape.

**3. Findings bypass the DI-001 sort under a different thread count (SR-009).**
*Why tests miss it:* VP-011 proves the *comparator* is a total order, in a module that does
not perform the sort. NFR-003's check is "run twice with identical inputs, diff stdout" — on
the same machine, with the same core count, where rayon's work-stealing will very likely
produce the same traversal order twice. The bug surfaces on a CI runner with a different core
count, i.e. in someone else's build.
*De-risk:* (a) `debug_assert!(findings.is_sorted_by_key(...))` immediately before emit;
(b) run the determinism test under `RAYON_NUM_THREADS=1` **and** `=16` and diff across both.
Both are one-liners.

**4. The "closed" reason-code taxonomy has two incompatible definitions (SR-032).**
*Why tests miss it:* NFR-007 ("zero unrecognized reason strings") is the test, and it is
vacuous while two closed sets exist — whichever set the implementer encodes, the test passes
against itself. Verified: `failure-modes.md` lists **13** codes; ADR-007 says *"The nine
closed reason codes"* three times. Worse, ADR-007 assigns `dns-resolution-failure` and
`ssl-tls-error` to **indeterminate**, while `failure-modes.md` assigns `dns-failure` and
`tls-error` to **broken / exit 1** — same conditions, opposite verdicts, opposite exit codes,
different spellings. `test-vectors.md` TV-087 sides with `failure-modes.md`
(self-signed → exit 1, `tls-error`), as does `dtu-assessment.md`. And the positive verdict is
`alive` in ADR-007/CAP-010/`events.md`/`dtu-assessment.md` but `clean` in `api-surface.md`'s
enum, DI-005, `entities.md`, and the JSON schema.
*De-risk:* make `error-taxonomy.md` the single source with exactly one table (13 codes,
one verdict + one exit code each), pick `clean` (it is in the shipped JSON), delete the
competing lists from ADR-007 and `module-criticality.md`, and generate the Rust enum from it.

**5. ADR-007 states the frozen R7 exit codes backwards (SR-033).**
*Why tests miss it:* the test vectors say 1, so a vector-driven suite would catch it — but
ADR-007 is what an implementer reads for *rationale*, and it is the ADR governing the
CRITICAL `verdict` module and its Kani proof. Verified verbatim at ADR-007 line 47:

> "DI-011 specifies exit code 2 for `broken` findings; exit code 0 when all findings are
> `alive` or `indeterminate`. VP-007 Kani-proves this mapping."

DI-011, CAP-014, `api-surface.md`, `events.md` Stage 7, DD-006, and R7 all say **1** = broken,
**2** = usage/IO. This is precisely the lychee inversion that **R-006 exists to reject** and
that the gene-transfusion anti-gene table lists as a thing not to copy — reproduced inside the
governing ADR. (VP-005/VP-006 as written do encode the correct 0/1/2 mapping, so the proofs
and the ADR they cite disagree.)
*De-risk:* one-line edit to ADR-007. Do it before the gate.

**Runner-up (6).** The 429/5xx→indeterminate rule — D-008's whole point — has no VP (SR-022)
and integration-only coverage against an unspecified mock (SR-028). Two lines in the existing
VP-007 harness closes it.

## SR-032 — Reason taxonomy: 13 vs 9, and dns/tls verdicts inverted · SHOULD-CHANGE (GATE BLOCKER)

See risk 4 above for the evidence. Flagging separately because it is a gate blocker in its own
right: NFR-007 is one of only seven NFRs and it is currently untestable.

## SR-033 — ADR-007 inverts the frozen R7 exit codes · SHOULD-CHANGE (GATE BLOCKER)

See risk 5 above. One-line fix; blocker because R7 is frozen and this is the ADR an
implementer reads.

---

# Q7. Missing perspectives

## SR-034 — Two-pass bootstrapping order is undocumented for non-`--ignore` exclusions · SHOULD-CHANGE

**Location:** `system-overview.md:43-67`, `event-flow.md:102-116`

The two-pass order *is* documented, and for the `--ignore` case it is genuinely well
resolved: Pass 1's domain is *"each discovered .md file (ALL files, including ignored)"*, DI-006
scopes `--ignore` to sources only, and VP-016 tests it. Clean design, correctly reasoned.

But Pass 1's domain is the **discovery set**, and three classes of anchor target fall outside
it with no handling and no mention anywhere in the package:

1. **`.gitignore`d markdown.** Traversal must "respect `.gitignore`", so `vendor/api.md` is
   never discovered → no anchor table → `[x](vendor/api.md#auth)` yields a **false
   `anchor-not-found`**. This is precisely the false-positive class DI-006 exists to prevent,
   reproduced on a different exclusion axis. The two axes are never reconciled in any BC, ADR,
   or VP.
2. **Markdown above the scan root.** `mdlinkcheck docs/` with `[x](../CONTRIBUTING.md#style)`.
3. **Dot-directory markdown.** `.github/PULL_REQUEST_TEMPLATE.md`.

There is no third pass, no lazy load, no on-demand read anywhere in the package (I grepped for
all four). So the fix is forced: either widen Pass 1's discovery domain (which changes SS-01
semantics and DI-009's termination reasoning) or add a shell phase between the passes. The
latter is SR-016's Pass 1.5, which solves this and the DirEntries problem with one mechanism —
Pass 1.5 reads both the target directories *and* the target `.md` files not already indexed.

**Decide this before SS-01/SS-05/SS-08 stories are written.**

## SR-035 — `tests/corpus/` is in scope, out of scope, unowned, and schema-incompatible · SHOULD-CHANGE (GATE BLOCKER)

**Location:** DD-005/D-009, ASM-007, `interface-definitions.md` §10, `test-vectors.md` §9, `prd.md:86`, `edge-cases.md`

*What exists, and it is better than most packages achieve:* a directory layout and a manifest
schema in `interface-definitions.md` §10, a golden-file pass criterion in `test-vectors.md`
§9.2, a known-good differential run against `rust-lang/rust` docs in §9.1, and 13 named
incumbent-bug fixtures in `gene-transfusion-assessment.md` §2.1. That is real planning.

*Four things break it:*

1. **Ownership contradiction.** DD-005 (binding human decision) and ASM-007 make it *"a
   first-class story deliverable"* with HIGH impact. `prd.md:86` §Non-Goals then excludes
   *"Tests/corpus authorship beyond the defined `tests/corpus/` manifest structure"* — schema
   in, content out. R-002 (Medium × HIGH, the top risk) names the corpus as its **only**
   mitigation, so R-002 is effectively unmitigated. So is ASM-007.
2. **The manifest schema cannot be compared to the CLI output.** Manifest:
   `{schema_version, fixtures: [{file, expected_findings: [{line, link_target, verdict, reason}]}]}`
   — nested by fixture, **no `column`**. CLI JSON:
   `{schema_version, results: [{file, line, column, link_target, verdict, reason}]}` — flat,
   with `column`. `test-vectors.md`'s pass criterion (*"JSON output matches manifest.json
   exactly (modulo ordering)"*) is unsatisfiable: different top-level key, different nesting,
   different field set. And because `column` is absent, the corpus cannot verify
   `interface-definitions.md` §9's column rule at all. A test-writer will invent a transform —
   exactly the undocumented decision that produces a wrong golden file.
3. **The holdout set must be simultaneously in and out.** ASM-007 requires *"one trap per
   false-positive class (see DEC-NNN)"* in the corpus; `edge-cases.md` requires DEC-003,
   DEC-006 and DEC-009 to be `[HOLDOUT]` and *"must NOT appear in the visible test vectors"*.
   DEC-006 is labelled both "Canonical test vector" **and** `[HOLDOUT]`. Three of nine DEC
   cases cannot satisfy both documents.
4. **Two fixture naming conventions.** §10 uses `fixtures/broken-links/…`; gene-transfusion
   names its 13 as `corpus/lychee-1457-anchor-false-negative.md`. Unreconciled.

**Recommendation:** (a) resolve ownership — remove the Non-Goals line, since D-009 is binding
and outranks it; (b) redefine the manifest as `{schema_version, expected: [<CLI result
object>], }` so the pass criterion becomes a literal JSON diff against `--format json`
output, with `column` included; (c) split the corpus into `fixtures/` (visible) and a
separately-held holdout set so DEC-003/006/009 live in exactly one place; (d) name one owner
and one story.

## SR-036 — NFR-001/002: numbers are plausible but ~2 orders of magnitude loose; measurement contract is sound with three fixable defects · QUESTION-FOR-HUMAN

**Location:** `nfr-catalog.md` NFR-001/NFR-002/NFR-005, `system-overview.md:85-94`, ASM-005

**Are the numbers plausible?** Yes — and they are so loose they will not protect anything.
The corpus is 500 files × ~20 links × ~15 headings = 10,000 links and 7,500 headings, i.e.
roughly 2.5 MB of markdown. pulldown-cmark parses markdown at well over 100 MB/s; the slug
algorithm is a single pass per heading; NFC comparison is a few hundred nanoseconds. Warm
cache, 500 `read` calls. A realistic release-build figure is **50–200 ms**, so NFR-001's 5 s
carries 25–100× headroom and NFR-002's 15 s carries more. NFR-005's 512 MB for 2.5 MB of
input is ~200× loose and has no derivation at all.

Consequence: NFR-001/002/005 will pass on day one and every day after, including the day
someone accidentally makes the tool 20× slower. They are acceptance ceilings, not regression
gates.

**Is the measurement contract sound?** Mostly yes, and better than typical — p95, 10 runs,
`--warmup 2`, warm cache, `--release` with `lto = "thin"`, process-start-to-exit scope, and
`hyperfine` as the harness are all specified. Three defects:

1. **The corpus is not reproducible.** "500 `.md` files; avg 20 links/file, avg 15
   headings/file" is a distribution, not an artifact. Two people generate two different
   corpora and get incomparable numbers. Needs a **seeded generator script** committed under
   `benches/`.
2. **Tier A can never be a gate.** "Apple Silicon M-series developer laptop" spans an M1 Air
   to an M4 Max — a ~3× spread — and no CI runner can reproduce it. NFR-001 is unenforceable
   by construction.
3. **Harness pinning contradicts itself.** `nfr-catalog.md` says *"`hyperfine`
   (version-pinned in `benches/README.md`)"*; `tooling-selection.md` says
   `| **hyperfine** | latest |`.

Also note: `risks.md` contains **no performance risk** at all. R-001..R-007 are slug drift,
anchor false positives, GET fallback, case-sensitivity UX, "why not lychee", exit-code
inversion, and bus factor. Performance exists only as ASM-005 (Medium confidence, MEDIUM
impact), so `nfr-catalog.md` §NFR Risk Sources traces two NFRs to an assumption rather than a
risk, and nothing triggers risk-driven mitigation. The single competitor datapoint doing all
the load-bearing work (*"htmltest achieves 2000 HTML files in 8.6s in Go"*) is a weak analogue:
different language, different input (rendered HTML, not markdown AST), different work, unstated
hardware. There is zero throughput math anywhere — no files/sec, no MB/s, no parse-cost-per-KB.

**Questions for you:**
- Confirm 5 s / 15 s as **R8 acceptance ceilings**, and separately set a **tight internal
  regression budget** (I suggest p95 ≤ 500 ms Tier A, ≤ 2 s Tier B) as the number CI actually
  gates on. Or convert to a machine-comparable **throughput** metric (files/sec, links/sec),
  which sidesteps the hardware-tier problem entirely.
- Confirm 512 MB for NFR-005 or tighten it (64 MB would still be generous and would actually
  catch a leak).
- Approve committing a seeded corpus generator as part of the NFR-001 story.

## SR-037 — Missing artifacts a reviewer would expect · CONSIDER

Beyond the corpus and bootstrapping items above, these are absent from a package that
otherwise plans thoroughly:

- **No concurrency invariants exist.** No `CI-NNN` identifier appears anywhere in `.factory/`;
  `L2-INDEX.md`'s ID registry has no concurrency class. Concurrency lives only as prose, and
  `system-overview.md` calls the 4-per-host / 32-global caps *"advisory defaults"* — which makes
  them non-invariants by construction while BC-2.10.008 is a contract a story must test.
  `module-criticality.md` gives `http_client` **VP Count: 0**. Nothing asserts "at most 4 in
  flight per host". Separately, gene-transfusion recommends *"8–16 for network work"* against
  the chosen 32, unreconciled; and two thread pools (`num_cpus` file-scan + 32 HTTP) are
  unbounded in combination against NFR-005's RSS budget.
- **No `benches/` story** though NFR-001/002/005 all reference `benches/perf.sh` and
  `benches/README.md`.
- **No README story** though D-009 puts the README explicitly in scope and R-006's *only*
  mitigation is *"Document the divergence prominently in README and `--help`"* — neither of
  which is contracted (SR-004).
- **No diagnostic/observability surface.** For a CI tool whose entire value proposition is
  "no false positives", there is no way for a user to ask *why* a link was judged broken — no
  `--verbose`, no `--explain`, no `RUST_LOG`. When someone files "this is a false positive",
  there is no supported way to get the resolution trace. Worth one small story.
- **`build_with_html(headings, html_anchors)` has no producer.** `api-surface.md` exposes the
  consumer for D-007's HTML `id=`/`name=` carve-out, but `ParsedFile` has no `html_anchors`
  field and no module is assigned to scrape `Event::Html`/`Event::InlineHtml` attributes.
  D-007 is the weakest-implemented of the four binding decisions: a consumer with no producer.
  VP-020 also has no test case for `name=` — half the contract title.
- **Smaller:** fuzz targets are "under the binary crate" (`purity-boundary-map.md`) vs a
  separate workspace member (`tooling-selection.md`, ADR-002), and `module-decomposition.md`'s
  `members = [...]` omits `fuzz`. ADR-002 justifies `resolver = "2"` by citing "edition 2024
  dependencies" (edition 2024 implies resolver 3). ADR-006 leaves `unicode-normalization`
  unpinned after `dependency-graph.md` pinned it at 0.1.24.

## SR-038 — STRENGTH: implementation quality of the four binding decisions

Judging only *how well implemented*, not the decisions themselves:

| Decision | Implementation quality |
|---|---|
| **D-006** (case-sensitive + NFC, all platforms) | **Best-traced decision in the package.** DD-002 → DI-002 → ADR-006 (dedicated ADR, alternatives documented, trap T12 cited) → `path_resolver` CRITICAL/≥95% → BC-2.07.003/004/006 → VP-008/009 → DEC-004/DEC-009 [HOLDOUT] → FM-006/007 → KD-004. Two defects: the DirEntries mechanism cannot deliver it (SR-016), and VP-008 does not assert case-sensitivity (SR-024). Fix those two and D-006 is exemplary. |
| **D-007** (narrow HTML `id`/`name`) | **Weakest.** Decision recorded (DD-003 → DI-007 → CAP-005 → VP-020) but the producer is missing (SR-037), `name=` is untested, and BC-2.05.003 Inv 3 asserts *"Malformed HTML that pulldown-cmark cannot parse as inline HTML yields no anchor entries"* — pulldown-cmark does not parse HTML, it passes `Event::Html` text through. No BC says whether to write an attribute parser, a regex, or pull in a crate, and there is no vector for multi-attribute, single-quoted, or unquoted values. |
| **D-008** (three verdicts) | **Well-motivated ADR, badly executed detail.** ADR-007 is a good ADR — alternatives considered, future `--strict-indeterminate` noted, and the ADR-004/N-001 split of pure classification from effectful I/O is exactly right. But it inverts the exit codes (SR-033), miscounts the taxonomy (SR-032), and the model's central claim has no VP (SR-022). All three are small edits. |
| **D-009** (README + corpus in, suppression/GFM-autolinks out) | The out-of-scope half is clean and consistently applied (`prd.md` §1.5, BC-2.03.004 documents the GFM limitation explicitly — good). The in-scope half is broken four ways (SR-035) and the README has no story (SR-037). |

---

# Overall verdict

## READY-WITH-CHANGES

This package should go to the human gate **with five conditions**, not be sent back for
re-work. The reasoning: the architecture's central idea is sound and well-argued, the EC
register makes Phase 3 tractable, traceability is dense and largely correct, and all four
binding decisions are traced end to end. The blockers are few, localized, and each has an
obvious correct answer already present somewhere in the package — this is a package that needs
editing, not rethinking.

**Gate conditions (must clear before Phase 2):**

| # | Finding | Fix size |
|---|---|---|
| 1 | **SR-016** — `DirEntries` cannot resolve multi-component paths, carries no file type, and misses out-of-scan-set targets. Adopt `DirIndex` + Pass 1.5. Also closes **SR-034**. | Architecture change: ~2 documents, 1 new pipeline phase |
| 2 | **SR-033 + SR-032** — ADR-007 inverts the frozen R7 exit codes; the "closed" taxonomy has 9 vs 13 codes with `dns`/`tls` verdicts inverted and `alive` vs `clean` split. | 1 line + 1 table consolidation |
| 3 | **SR-019 + SR-020 + SR-022** — the slug collision bump is proven by nothing, VP-018's golden table has two wrong rows, and the 429/5xx→indeterminate thesis has no VP. | 1 proptest + 2 table rows + 4 assertions |
| 4 | **SR-027** — BC-2.03.003's pulldown-cmark premise is false; `broken_link_callback` is unnamed. | 2 sentences |
| 5 | **SR-035** — the acceptance corpus is in scope and out of scope, unowned, and its manifest schema cannot be diffed against the CLI output. | 1 decision + 1 schema edit |

**Strongly recommended before Phase 2 (not gate blockers):** SR-002 (collapse 13 ceremony
BCs), SR-006 + SR-007 (reconcile EC IDs and regenerate `prd.md` §2 from `BC-INDEX.md`),
SR-009 + SR-010 + SR-014 (add SS-15/SS-16, merge SS-12+SS-13, mark one build order
authoritative), SR-030 (fill `Architecture Module`/`subsystem` mechanically), SR-021
(generated slug oracle), SR-028 (name the SS-10 fixture harness).

## Single highest-value recommendation

**Replace `DirEntries = Vec<OsString>` with a typed, directory-keyed `DirIndex`, and insert a
Pass 1.5 shell phase that reads every directory and every out-of-scan-set `.md` file that the
Pass 1 links actually point at.**

```rust
pub enum EntryKind { File, Dir, Symlink { dangling: bool } }
pub struct DirEntryInfo { pub name: OsString, pub kind: EntryKind }
pub type DirIndex = HashMap<PathBuf, Vec<DirEntryInfo>>;
pub fn resolve_path(dest: &str, src_dir: &Path, index: &DirIndex) -> PathVerdict;
```

```
Pass 1   (shell+pure) : discover → read → parse → extract links → build anchor tables
Pass 1.5 (shell only) : from the extracted links, collect every target directory along
                        every path and every target .md not yet indexed; read_dir each
                        (capturing file type); parse the extra .md files
Pass 2   (pure only)  : resolve every link against DirIndex + AnchorIndex
```

I am picking this over the slug oracle (the close runner-up) because it is the only finding
whose late discovery costs an architecture rewrite mid-Phase-3, and because one change resolves
six separate problems:

1. Multi-component path resolution becomes possible (SR-016a) — the thing every BC-2.07.001
   test vector requires today and cannot get.
2. `target-is-directory` and `broken-symlink` become emittable (SR-016b) — two closed reason
   codes that are currently unreachable.
3. Anchor targets in `.gitignore`d files, above the scan root, and in dot-directories get
   correct verdicts (SR-016c / SR-034) — closing the same false-positive class DI-006 exists to
   prevent, on the three axes nobody examined.
4. The two-pass bootstrapping circularity in BC-2.05.001 Post 1 (*"plus any files referenced as
   anchor targets that are readable"*) gets a mechanism instead of a wish.
5. BC-2.07.001 Inv 3's filesystem call disappears, so ADR-001 and `purity-boundary-map.md`
   stop contradicting each other and ADR-001's stated rationale actually holds.
6. `path_resolver` becomes **more** Kani-provable, not less — `DirIndex` is still plain data,
   and VP-008 can finally be strengthened to exercise `resolve_path` rather than a two-string
   helper that would pass over a resolver which resolves nothing.

Cost: one `read_dir` per distinct target directory (a few dozen on a real repo), one struct
change, one new pipeline phase, edits to ADR-001, `api-surface.md`, `purity-boundary-map.md`,
`module-decomposition.md`, `system-overview.md`, and BC-2.07.001/003/005.

---

# The strongest case that this package is OVER-specified

You asked for this argument tested rather than dismissed, so here it is at full strength,
followed by why I nonetheless reject it.

## The case

**1. The ratio is indefensible on its face.** 12,394 lines of specification and 119 files for a
~300-word brief. That is a 40:1 file-to-requirement ratio. The likely implementation is
2,500–3,500 lines of Rust — so the spec is roughly **4× the size of the artifact it
describes**, before a single story is written. And `prd.md` §1.2 concedes the product itself is
not novel: lychee 0.24.2 *"covers a superset of R1–R8"*. We have written four times more
specification than code, for a tool that already exists.

**2. Uniform BC length proves the template drove the content, not the reverse.** All 59 BCs sit
in a 73–108 line band, and the five above 88 lines are exactly the five that were hand-revised
in v1.1. If specification effort tracked information, that band would span an order of
magnitude. It does not, which means ~59 × ~80 = ~4,700 lines were produced by filling a form
rather than by thinking about behavior. The BC that needs 300 lines got 107; the BC that needs 8
got 78.

**3. 22% of the BCs are provably empty.** Not stylistically thin — *provably*. BC-2.11.002 is a
near-verbatim clone of BC-2.09.002 down to shared EC IDs and identical VP rows. DI-006 is
contracted five times, all sharing EC-074, and BC-2.08.004's edge-case row literally reads
"See above". Three BCs restate one `max()`. BC-2.03.006's own invariant says *"No special-case
footnote filtering code is needed"* — an obligation whose implementation is to write nothing.
BC-2.13.002's sole edge case is *"Future version changes schema → schema_version incremented"*.
That is thirteen files, ~1,050 lines, that no implementer will ever consult.

**4. The taxonomy has more granularity than the code and still fails to cover it.** Fourteen
subsystems for seventeen modules — and four modules (`types`, `cli`, `app`, `main`) map to no
subsystem at all, including the one holding the two most load-bearing invariants. SS-12 and
SS-13 exist because "text" and "json" are two words, not because `format_text` and `format_json`
are two responsibilities. The classification scheme was elaborated past the point where it
tracked the design, and then it stopped tracking the design.

**5. Two of seven Kani proofs are theatre.** VP-005 covers a state space the VP itself measures
at 8; VP-006 covers 2. The full lifecycle cost of a Kani harness — author it, tune `--unwind`,
keep it green, debug CBMC timeouts on every refactor — vastly exceeds a ten-line table test,
and BC-2.14.002 already prescribed `unit test`. VP-002 cannot fail for the reasons it claims to
rule out. Three of seven proofs bought nothing, while the property that would have mattered
(slug injectivity) went unproven.

**6. And the decisive point: the spec is large enough to be self-defeating.** Count the
identifiers a human or agent must hold consistent: 148 ECs + 154 TVs + 128 EC references from
BCs + 99 `VP-TBD` rows + 59 BCs + 20 VPs + 14 SS + 14 CAPs + 11 DIs + 13 FMs + 10 ASMs + 9 DECs
+ 7 Rs + 7 ADRs + 6 DDs + 5 KDs + 16 traps. That is **~600 cross-referenced identifiers**
maintained by hand.

Now look at what this review actually found. `prd.md` §2 drifted from the BC files in three
subsystems, dropping five behaviors out of the middle of a renumbered list. ADR-007 states the
frozen exit codes backwards. The closed taxonomy has two sizes and two verdicts for
`dns`/`tls`. The positive verdict has two names. Two build orders disagree. Six BCs cite the
wrong EC IDs. Two golden-file rows are wrong.

**None of these are accidents. They are the expected defect yield of a 600-identifier manual
cross-reference graph.** Over-specification did not merely cost Phase 2 and Phase 3 time — it
*manufactured* the inconsistencies that Phase 1d then had to spend three review passes finding.
A 25-BC, 8-subsystem, 10-VP package with 148 test vectors would have carried the same behavioral
information with a quarter of the identifier graph, and most of this review's findings would not
exist because there would have been nothing to drift *from*. The package's size is not neutral;
it is a defect generator.

## Why I reject it anyway

The argument is right about mechanism and wrong about remedy, because **the over-specification
is not uniform** — and that asymmetry breaks premises 1, 2 and 6.

Look at where the mass sits. SS-11 through SS-14 hold 12 BCs and ~950 lines covering one
`max()`, two `format!` calls and two clap declarations. SS-06 (the differentiator, R-001/R-002
HIGH, ASM-008 "every anchor check is wrong" if false) holds **2 BCs and 193 lines** — and no
injectivity property, no oracle, and two wrong golden rows. SS-07 holds 6 BCs whose central
mechanism *cannot work*. Six of eight SS-10 BCs have no fixture strategy at all.

A uniformly over-specified package would be merely wasteful, and "cut 30%" would be the right
call. This one is wasteful **and thin exactly where being thin is expensive**. Cutting 30%
uniformly would delete ceremony and substance in proportion and leave every one of the five gate
blockers untouched. Meanwhile the parts that *are* long are long for good reasons: the 148-vector
EC register is the reason a test-writer can work at all, the seven ADRs each record a real
decision with real alternatives, and the pure/effectful split is what makes Phase 6 possible.

Premise 6 also proves less than it appears to. The defects it predicts are real, but every one
of them was **found**, by this pass, cheaply, precisely *because* the redundant cross-references
exist — `test-vectors.md` is what let me prove BC-2.07.003's EC IDs wrong; `failure-modes.md` is
what let me prove ADR-007 wrong; `BC-INDEX.md` is what let me prove `prd.md` §2 stale. A leaner
package would have had fewer contradictions and also fewer ways to detect the ones it had. Dense
redundant traceability is a *detector*, and its false-positive cost is review time, which is the
cheapest resource in this pipeline.

And premise 1's framing cuts the other way: `ASM-003` states plainly that this is a **VSDD
factory pilot on a deliberately well-understood problem shape**, and that differentiation
against lychee is not a product goal. The specification volume is partly the deliverable —
exercising the pipeline at scale on a problem where the right answer is knowable is the point.
Judging that volume by product-value-per-line is the wrong yardstick.

**The correct action is therefore not "cut 30%" but "move 20%":** collapse the 13 ceremony BCs
(SR-002), merge SS-12+SS-13 (SR-010), demote three Kani proofs to unit tests (SR-023), and spend
every hour recovered on the five gate blockers. Total mass stays roughly constant; the
correlation between mass and risk goes from near-zero to strong. That is a better package than
either the current one or a uniformly smaller one.

---

## Findings index

| ID | Class | Title |
|----|-------|-------|
| SR-001 | CONSIDER | Volume roughly right; allocation uncorrelated with risk |
| SR-002 | SHOULD-CHANGE | 13 ceremony BCs; collapsing removes ~10 Phase 2 stories |
| SR-003 | SHOULD-CHANGE | `fragment` split-before-decode contracted in SS-07 and SS-08 |
| SR-004 | SHOULD-CHANGE | 5 `prd.md` behaviors uncontracted; URL dedup is load-bearing |
| SR-005 | STRENGTH | 148-vector EC register is the best artifact in the package |
| SR-006 | SHOULD-CHANGE | ≥6 BCs misattribute EC IDs against the register |
| SR-007 | SHOULD-CHANGE | `prd.md` §2 drifted from BC files in 3 of 14 subsystems |
| SR-008 | CONSIDER | No BC group and no subsystem owns the CLI surface |
| SR-009 | SHOULD-CHANGE | `app` and `cli` map to no subsystem; DI-001 sort untested |
| SR-010 | SHOULD-CHANGE | SS-12 and SS-13 are one module and should be one subsystem |
| SR-011 | CONSIDER | SS-09/SS-11 overlap; SS-09 fails the independence test |
| SR-012 | CONSIDER | SS-10 hides a purity boundary the taxonomy does not admit |
| SR-013 | STRENGTH | 10 of 14 subsystems map 1:1 to a coherent module |
| SR-014 | SHOULD-CHANGE | Two conflicting build orders, neither authoritative |
| SR-015 | STRENGTH | Purity boundary is drawn in the right place, for the right reason |
| SR-016 | **BLOCKER** | `DirEntries` leaks three ways; SS-07 not implementable |
| SR-017 | SHOULD-CHANGE | BOM/CRLF, line mapping, color decision are pure but in the shell |
| SR-018 | CONSIDER | Boundary rule needs a real enforcement hook (`cargo deny` can't) |
| SR-019 | **BLOCKER** | VP-003 does not assert injectivity; collision bump unverified |
| SR-020 | **BLOCKER** | VP-018 golden table has two provably wrong rows |
| SR-021 | SHOULD-CHANGE | No differential oracle vs real github-slugger; ASM-008 unmitigated |
| SR-022 | **BLOCKER** | VP-007 proves totality only; D-008's thesis has no VP |
| SR-023 | CONSIDER | VP-002/005/006 are over-powered Kani; reallocate the budget |
| SR-024 | SHOULD-CHANGE | VP-008/015/017 under-powered; VP-008 tests the wrong thing |
| SR-025 | SHOULD-CHANGE | 99 `VP-TBD` rows advertise non-existent obligations |
| SR-026 | STRENGTH | Bounded-proof → unbounded-fuzz escalation ladder is well designed |
| SR-027 | **BLOCKER** | BC-2.03.003's pulldown-cmark premise is false |
| SR-028 | SHOULD-CHANGE | 6 of 8 SS-10 BCs have no fixture strategy |
| SR-029 | SHOULD-CHANGE | `canonicalize_logical()`, reason-string format, ANSI codes undefined |
| SR-030 | CONSIDER | 58 of 59 BCs lack ACs; 55 of 59 lack module routing |
| SR-031 | CONSIDER | Top 5 risks tests will not catch, with de-risking actions |
| SR-032 | **BLOCKER** | Reason taxonomy: 13 vs 9 codes; `dns`/`tls` verdicts inverted |
| SR-033 | **BLOCKER** | ADR-007 inverts the frozen R7 exit codes |
| SR-034 | SHOULD-CHANGE | Two-pass bootstrapping undefined for non-`--ignore` exclusions |
| SR-035 | **BLOCKER** | Corpus in scope + out of scope + unowned + schema-incompatible |
| SR-036 | QUESTION-FOR-HUMAN | NFR-001/002 plausible but ~100× loose; contract sound, 3 defects |
| SR-037 | CONSIDER | Missing: CI-NNN, benches story, README story, diagnostics, D-007 producer |
| SR-038 | STRENGTH | Implementation quality of D-006/007/008/009, graded |

_Reviewed 2026-08-05 by vsdd-factory:spec-reviewer (Phase 1d, pass 1, constructive second
opinion). No spec file was modified._
