---
document_type: adversarial-findings
level: ops
version: "1.0"
status: final
producer: adversary
timestamp: 2026-08-07T03:00:00Z
cycle: phase-1d
shard: 8
frozen_head: 1d3ed17
scope: "11 domain-spec shards + product-brief + prd §2-§8 + test-vectors non-§7, all read in full"
counts:
  critical: 6
  high: 11
  medium: 20
  low: 3
  total: 40
verdict: "R5 brief-requirement anchoring is NOT semantically defensible — 16 of 20 citations indefensible, and the two genuine R5 contracts are inverted to R6"
traces_to: cycles/phase-1d/perimeter-sweep-synthesis.md
project: mdlinkcheck-cloud
---

# Adversarial Findings — Perimeter Sweep Shard 8

**Scope:** 11 domain-spec shards + product-brief + prd §2-§8 + test-vectors non-§7, all read in full
**Frozen HEAD:** `1d3ed17`
**Finding counts:** 6 CRITICAL / 11 HIGH / 20 MEDIUM / 3 LOW = **40 findings**
**Verdict:** R5 brief-requirement anchoring is NOT semantically defensible — 16 of 20 citations indefensible, and the two genuine R5 contracts are inverted to R6

---

## CRITICAL

### P6-S8-001 — product-brief.md:82 still declares "macOS, Linux, Windows" (L1 ROOT)

product-brief.md:82 still declares "macOS, Linux, Windows" — the L1 ROOT of the trace chain, editable per its own line 78, missed by a sweep that reached 13+ downstream files. CONFIRMS CV5-001.

### P6-S8-002 — Phantom `malformed-fragment` in test-vectors.md:432

test-vectors.md:432 (TV-197) contains `malformed-fragment`, contradicting DI-003 and its own sibling TV-070 which classifies the same shape as `anchor-not-found`. CORROBORATES P6-S4-008.

### P6-S8-003 — events.md is normative but has NO Pass 1.5 stage

events.md (self-declared NORMATIVE per event-flow.md:23) has NO Pass 1.5 stage at all and labels Stage 3 "two-pass constraint"; event-flow.md:107-109 reduces Pass 1.5 to an ordering barrier doing no work. An implementer reading the normative stage definitions builds a two-pass pipeline and reproduces FM-010/DEC-003 — false `anchor-not-found` on every link into a gitignored/dot-dir/out-of-root file, which invariants.md:190-195 calls "the exact false-positive class the product exists to prevent." events.md is v1.1 and event-flow.md v1.0; neither was bumped for the DI-006 widening, the three-phase rename, or DD-023.

### P6-S8-004 — R5 catch-all scramble across 18 BCs; prd.md §7 RTM diverges on 16 rows

prd.md:804-805 documents the pivot as deliberate ("'R2b' → 'R5' throughout"), and prd.md:647's claim that F-020 fixed it is false. The two contracts that genuinely ARE R5 (BC-2.11.001, BC-2.11.004 — `--ignore` glob exclusion) are labelled R6 (output), so the frozen brief's filtering requirement has NO BC claiming it and R2c has almost none.

### P6-S8-005 — DD-015 step 3 and DI-012 are mutually contradictory under UTS#18

DD-015 step 3 ("remove non-`\p{Word}`") and DI-012's claim that `\p{Mn}` is "not a `\p{Word}` character" are mutually contradictory under UTS#18 — `\p{Mn}` ⊂ `\p{gc=Mark}` ⊂ `\p{word}`, and Rust's regex implements UTS#18 — so the literal DD-015 step RETAINS NFD combining marks, the opposite of DI-012's stated consequence, failing VP-026 OR-010. vp-026:130's "the oracle wins" clause papers over it by deferring to a fixture that does not exist yet. Also: github-slugger's actual mechanism is a punctuation/symbol BLOCKLIST, not a `\p{Word}` complement, so DD-015 mis-describes the algorithm it claims to quote verbatim. CORROBORATES pass-5 P5-002.

### P6-S8-006 — prd.md:35-39 lists item (c) — APFS case-insensitivity producing "silent false NEGATIVES" — inside a list enumerating FALSE POSITIVES

Introduced BY the D-043 edit (prd.md:545). Mis-frames KD-004, the flagship differentiator, and demotes the actual false-positive drivers below an off-thesis example.

---

## HIGH

### P6-S8-007 — risks.md:40 R-008 still says "NFR-002 (15s p95, Linux CI)"

Surviving Linux reference AND stale value (now 10s/macos-latest); risks.md is v1.1 and was absent from the D-043 shard-bump list.

### P6-S8-008 — ASM-008 is STRUCTURALLY UNFALSIFIABLE

ASM-008 — "GitHub's slug algorithm has not changed since github-slugger v2.0.0", the assumption whose failure invalidates every anchor check — is STRUCTURALLY UNFALSIFIABLE: every named vehicle (TV-S001..016, VP-018, VP-026's pinned committed oracle, NFR-006) tests conformance to github-slugger v2, i.e. the assumption's PREMISE, and NO artifact anywhere compares against GitHub. DD-021 de-designated it from holdout on the ground that its validation vectors are in the visible suite — but those are the premise restated, not the claim. R-001's mitigation reduces to "track github-slugger releases": a human process with no artifact, no owner, no gate.

### P6-S8-009 — entities.md:64 and events.md:52 specify CANONICALIZED path dedup, which DI-009 and system-overview.md:143 explicitly forbid

`fs::canonicalize` case-folds on APFS, defeating DI-002/KD-004. CORROBORATES shard-1 P6-S1-002 and shard-3 P6-S3-019.

### P6-S8-010 — DI-001's four-field sort key never reached DD-012, CAP-012, events.md:118, or event-flow.md:77

Under the still-published 3-field key, `sort_unstable_by` is unstable on a non-total key.

### P6-S8-011 — ACTIVE holdout EC-147 cited by bare ID in THREE visible artifacts while check-holdout-boundary reports 0

decisions.md:90, failure-modes.md:81 (calls it a "corpus fixture"), nfr-catalog.md:79 all cite EC-147. decisions.md:25's v1.6 changelog shows the same remediation applied to EC-141/EC-094/EC-093, skipping this one.

### P6-S8-012 — TV-130 asserts exit 1 for an --allow non-match with NO --online flag

Offline behaviour is clean/exit 0; its sibling TV-131 annotates "(offline)" and expects 0. TV-130 enforces a catastrophic false-positive bug.

### P6-S8-013 — DI-007 is an ORPHAN with three artifacts naming three different (or no) enforcers

The claimed enforcer BC-2.05.003 cites DI-008 instead. DI-007 governs the only carve-out from the frozen "no HTML parsing" non-goal. CORROBORATES pass-5 P5-004.

### P6-S8-014 — risks.md:34 and test-vectors.md:291 both assert full T1-T16 trap coverage while T13 is retired and T16 is "not-covered"

R-002 (HIGH-impact false-positive risk) is mitigated by a provably false assertion; T16 is the SOLE traversal control since TV-024 blesses `../../../../etc/passwd` as clean.

### P6-S8-015 — TV-146 asserts SIGINT behaviour deliberately DELETED from the interface spec

prd.md:621 F-016 deleted SIGINT behaviour; TV-146 has an unreachable exit code (POSIX reports 130) and "partial output" contradicting DI-001.

### P6-S8-016 — Retired T13 cited as live at BC-2.10.003.md:77; T12/T16 cited on unrelated contracts

Range citations "T1-T16" and "T9-T15" sweep in retired T13.

### P6-S8-017 — events.md:119 specifies the pre-DD-023 bare-array JSON output

DD-023 explicitly rules this "NOT a conforming implementation."

---

## MEDIUM

### P6-S8-018 — BC-2.05.003 cites DD-007 for the HTML carve-out (correct is DD-003/D-007) twice; invents a CAP-005 title

### P6-S8-019 — DD-022 carries a LIVE directive to correct error-taxonomy.md §1 that has already landed

A stale binding order that could cause a future pass to "re-fix" the file back toward the wrong model.

### P6-S8-020 — L2-INDEX mis-anchors DI-009 twice; R8 performance left with NO capability

One label reads "(determinism)" though DI-009 is termination.

### P6-S8-021 — CAP-002 attributes the CommonMark grammar pin to DD-006 (exit codes)

### P6-S8-022 — events.md:66-67 specifies non-UTF-8 handling as "decoded lossily OR reported as I/O error"

Mutually exclusive outcomes with different exit codes, resolved unambiguously by the F-032 record.

### P6-S8-023 — errors[] is "three top-level fields" in CAP-013 but "omitted or empty" in interface-definitions

No byte-exact serialization exists under NFR-003.

### P6-S8-024 — `alive` called a verdict in events.md:100 and event-flow.md:71

The exact conflation DD-022 exists to kill.

### P6-S8-025 — differentiators.md omits DI-012/DI-013 from the rows describing the headline differentiator

### P6-S8-026 — No Finding entity in the entity model; Link's nine attributes diverge from ExtractedLink's four

### P6-S8-027 — test-vectors §4's declared range EC-077..EC-150 SWALLOWS all of §5 and §6

Introduced by the "fix" at prd.md:563.

### P6-S8-028 — Five vectors have non-determinate expected exit codes

(0/1, "depends on links", "0 or 1", two conditional) — the class F-012 claims to have fixed for four other vectors.

### P6-S8-029 — TV-066 (YAML front matter) and TV-020 (FIFO) assert behaviour no capability, BC, or invariant contracts

### P6-S8-031 — CAP-013's errors[] is unproducible from format_json(findings)

### P6-S8-032 — Nonexistent PATH is an I/O error in events.md:41 and a usage error in CAP-014

### P6-S8-033 — R-009 (memory) is asserted-and-unverified

NFR-005 measures the opposite corpus shape; the largest single-file vector is an order of magnitude below R-009's trigger; the "documented scope limitation" is documented nowhere.

### P6-S8-034 — `alive` used as an Expected Verdict in §4 where the report emits nothing at all

### P6-S8-035 — prd.md:402 ("on ALL platforms") and prd.md:746 ("fails in Linux CI") survive D-043

:746 is the only place still asserting a Linux-CI falsification mechanism that no longer exists.

### P6-S8-036 — invariants.md:50 "ALL platforms" and failure-modes.md:52 "on any OS" survive inside the closed reason taxonomy table

### P6-S8-037 — prd.md:502,:545 both cite "§1.2 Problem statement" — §1.1 is the Problem Statement

A reviewer verifying the D-043 sweep reads the wrong section.

---

## LOW

### P6-S8-038 — (P6-S8-016 severity tail) Bare range "T1-T16" in risks.md:34 — see HIGH entry above

### P6-S8-039 — (P6-S8-019 severity tail) Stale DD-022 directive — see MEDIUM entry above

### P6-S8-040 — NFR-004: every reference correctly marked retired — NO surviving live citation (informational)

Out-of-scope Linux references in tooling-selection/vp-022/feasibility-review/test-vectors/nfr-catalog are LEGITIMATE negative constraints ("must NOT run on Linux") and must NOT be edited.

---

## COMPLETE D-043 SURVIVOR LIST (exhaustive grep, shard 8)

Six sites bearing Linux/Windows/retired-T13 references that must be fixed:

1. **product-brief.md:82** — "macOS, Linux, Windows" — CRITICAL L1 root; editable per own line 78
2. **risks.md:40** — "NFR-002 (15s p95, Linux CI)" — surviving Linux reference AND stale value
3. **prd.md:746** — "fails in Linux CI" — only remaining Linux-CI falsification mechanism
4. **prd.md:402** — "on ALL platforms" — platform-universal claim surviving D-043
5. **BC-2.10.003.md:77** — T13 cited as LIVE (T13 retired by D-043)
6. **risks.md:34** — "T1-T16" + **differentiators.md:32** — "T9-T15" — both sweep in retired T13

**Weaker residuals** (non-breaking): invariants.md:50 "ALL platforms", failure-modes.md:52 "on any OS".

**Legitimate negative constraints (DO NOT EDIT):** Linux references in tooling-selection, vp-022, feasibility-review, test-vectors, nfr-catalog that constrain the product to NOT run on Linux.
