---
document_type: adversarial-findings
level: ops
version: "1.0"
status: final
producer: adversary
phase: phase-1d
pass: 5
shard: 6
cycle: phase-1d
frozen_head: 1d3ed17
scope: "ADR-001/002/003/004/007 + dependency-graph.md + tooling-selection.md + feasibility-review.md + bc-module-map.md — all 9 read in full"
counts: 2 CRITICAL / 19 HIGH / 11 MEDIUM = 32
findings_total: 32
findings_critical: 2
findings_high: 19
findings_medium: 11
verdict: "ADR-004 only PARTIALLY resolves the two-pool starvation hazard ADR-005 defers to it — NO on adequacy"
project: mdlinkcheck-cloud
---

# Adversarial Findings — Phase 1d — Pass 5 — Shard 6 / 8

> **ERRATUM (operator ruling, gate #27 / PG-011):** This document's title says "Pass 5". Per the operator's ID-space-is-truth ruling, this perimeter sweep IS **pass 6** — matching the `P6-S*` finding IDs used throughout. The title is preserved unedited per D-034 spirit; this note is the correction. The separate `P5-*` finding population (36/37 findings, record only partially recoverable — see `adversary-pass-5.md`) is pass 5. The next adversary pass after remediation is **pass 7**.

**Frozen HEAD reviewed:** `1d3ed17` (`factory-artifacts`)
**Perimeter:** ADR-001/002/003/004/007 + dependency-graph.md + tooling-selection.md + feasibility-review.md + bc-module-map.md — all 9 read in full
**Shard:** 6 of 8 (perimeter-closing sweep)
**Counts:** 2 CRITICAL / 19 HIGH / 11 MEDIUM = 32 findings
**ADR-004 starvation verdict:** PARTIALLY ADEQUATE — NO on full adequacy

---

## CRITICAL

### P6-S6-001 (POLICY 4/16) — ADR-001 still carries the retired seam design as live specification

ADR-001:52-54,:66-67 still specifies the RETIRED seam design and is the last live artifact carrying it. Every load-bearing claim is false: type `DirEntries` (actual `DirIndex`, api-surface.md:90); `Vec<OsString>` (actual `HashMap<PathBuf, Vec<DirEntryInfo>>`, :90-92); produced by `scanner` (actual `app` in Pass 1.5, :88 + purity-boundary-map.md:80,96); scanner reads eagerly for EVERY file (actual: only immediate parents of link destinations, once per distinct dir, system-overview.md:126-128). The SR-016 remediation propagated to api-surface v1.1, module-decomposition v1.1, purity-boundary-map v1.2, module-criticality v1.2 and even ADR-006 (P4-027) — ADR-001 was NEVER revised (still version 1.0, status accepted, one changelog entry) despite being the RATIONALE document for the entire pure-core architecture with subsystems_affected SS-01..SS-14. Second-order harm: it tells an implementer that Vec<OsString> (OS-native, non-UTF-8-safe) is the sanctioned type crossing into the pure core and that a SINGLE-directory listing suffices — precisely the design spec-review-second-opinion.md:411 declared a GATE BLOCKER ("cannot resolve multi-component paths, carries no file type"). An implementer reading only the ADRs would rebuild the blocked design. NOTE system-overview.md:85's DirEntries mention is legitimate history and is NOT a defect.

### P6-S6-002 (POLICY 4/16/2) — ADR-001 anchors slug algorithm to the wrong invariant and closes the DI range before DI-012/DI-013

ADR-001:26-27 anchors the slug algorithm to DI-003 — which is the FRAGMENT-SPLIT invariant — citing the same id for two different functions in one sentence. The slug algorithm's invariants are DI-012 and DI-013, added by DD-027 specifically because the slug algorithm had no invariant. ADR-001:45-46 calls the slug algorithm "the product's primary differentiator" then anchors it to an unrelated invariant. Compounding: ADR-001:86 Source/Origin says "DI-001..011: invariants that must be formally verifiable" — a CLOSED RANGE excluding DI-012/DI-013, i.e. the one ADR whose purpose is "make the provable things provable" omits the two invariants covering the product's highest-risk correctness surface.

---

## HIGH

**P6-S6-003** — ADR-004:82-89's "authoritative architectural contract / BC-2.10.008 must be updated (product-owner scope)" was DISCHARGED three BC revisions ago — BC-2.10.008 v1.3 already specifies the dedicated 32-thread pool verbatim; ADR-004 v1.1 added the demand AFTER the BC complied.

**P6-S6-004** — ADR-004 does not model RETRIES at all (zero mentions of retry/backoff/Retry-After in 110 lines), so its thread-occupancy bound ("up to 10 seconds per BC-2.10.003") is understated ~3x against CAP-010's mandated "2 retries with backoff" — and a backoff sleep occupies a pool thread doing zero work, a worse utilization profile than a blocking request. The 32-thread sizing is therefore justified against a workload model that does not match the specified product. BC-2.10.003 also never says whether the 10s budget is per-attempt or across all 3 attempts.

**P6-S6-005** — ADR-004:64-66 prescribes `Arc<Mutex<HashMap<String,u32>>>` as a "semaphore" — it is a counter with no wait/notify, so it cannot satisfy BC-2.10.008 PC3 ("when a slot frees up, the next queued request begins immediately"). In BC-2.10.008's own EC-088b (100 URLs to one host) 28 of 32 threads have no legal work and must spin, burning CPU — regenerating the exact starvation ADR-004:42-48 claims to prevent. A dedicated pool isolates BLOCKING I/O; it does not isolate SPINNING.

**P6-S6-006** — The two pools' INTERACTION is unspecified and two documents disagree on when HTTP dispatch occurs: ADR-005:59-60 puts par_iter over the extracted-link list in Pass 2 (where --online checks live per system-overview.md:151-156), while system-overview.md:165 puts dispatch BETWEEN Pass 2 and Sort. If the former, a file-scan-pool worker must block awaiting an HTTP-pool result (ThreadPool::install/join from inside another pool blocks the caller) — the identical starvation failure on the opposite side of the boundary. ADR-005:22 defers this to ADR-004 and ADR-004:48 defers back; the interaction falls through the gap between the two cross-references.

**P6-S6-007** — ADR-007:142-144 REJECTS retry-before-verdict as "too expensive by default; retry is a user-facing flag (DD-016)" — but CAP-010 and events.md:109 make 2-retries-with-backoff DEFAULT MANDATORY L2 behaviour, and api-surface.md:44-53's closed CLI contract has NO retry flag. An `accepted` ADR rejecting a required capability is a direct L3-vs-L2 contradiction; story-writers reading ADR-007 will drop retry.

**P6-S6-008 (POLICY 12/19/4)** — `sub_reason` is part of the public --format json contract per BC-2.10.002.md:52-55 (D-016) but appears ZERO times in ADR-007 — the document that declares itself authoritative for the verdict/reason model — and is absent from api-surface.md:121-123's Finding struct and from the JSON schema at :131-139. BC-2.10.002:55 has to pre-emptively state "VP-021 does NOT check sub_reason values" precisely because the schema does not know about it. CORROBORATES shard 5 P6-S5-002 and pass-5 P5-012.

**P6-S6-009** — ADR-003:47-50's DECISIVE rationale for rejecting comrak (the *Unknown LinkType variants surfacing undefined references) depends on a parser constructor ADR-003 never names, and the two documents that do specify it DISAGREE: feasibility-review.md:181 says `Parser::new()`, purity-boundary-map.md:104 says `Parser::new_with_broken_links()`. If Parser::new() is built, BC-2.03.003 and the `undefined-reference-definition` reason code are UNIMPLEMENTABLE and the comrak rejection loses its basis. CORROBORATES shard 2 P6-S2-001.

**P6-S6-010 (POLICY 11/4)** — ADR-001:38-40 claims purity-boundary violations are "detectable by code review and by `cargo deny` rules". deny.toml has exactly four sections ([licenses],[advisories],[bans],[sources]) all operating on the DEPENDENCY GRAPH; cargo-deny cannot inspect first-party source for std::fs calls. The purity boundary — which system-overview.md:51-53 calls the constraint "every design decision subordinates itself to" — has ZERO automated enforcement while the ADR asserts it has some. The inverse is also actionable: deny.toml:88-94 bans only openssl-sys, while ADR-004:32 makes "do NOT introduce tokio" a load-bearing prohibition (the entire reason ureq beat reqwest and httpmock beat wiremock) — tokio, reqwest and hyper are NOT banned. The one prohibition cargo-deny CAN mechanize is absent; the one it cannot is claimed.

**P6-S6-011** — feasibility-review.md:56-62 lists NFR-004 as an ACTIVE cross-cutting NFR ten lines above :67 declaring it retired — the D-043 remediation APPENDED the retirement paragraph without editing the enumeration it contradicts, so the section rendering "NFR coherence: PASS" does so over a set containing a retired NFR. Separately NFR-008 (CI Performance Regression Gate, MERGE-BLOCKING, verified by VP-022) appears NOWHERE in feasibility-review — never assessed for architectural feasibility. Contrast tooling-selection.md:65-72 which handled the identical sweep correctly.

**P6-S6-012 (POLICY 2/4/9)** — feasibility-review.md:98-104 certifies "Verifiability: PASS" over "all 11 domain invariants (DI-001..011) ... 20 VPs total". Ground truth is 13 invariants and 26 VPs. The closed range excludes EXACTLY the two invariants DD-027 created to close the P3-010 slug-fidelity governance gap, so the architecture's formal verifiability certification has never been rendered over DI-012/DI-013 or VP-023..VP-026. Same stale range at ADR-001:86.

**P6-S6-013 (POLICY 4/16)** — feasibility-review.md:77-85 grounds "Integration feasibility: PASS" on a seam type `HashMap<PathBuf,(AnchorTable,Vec<ExtractedLink>)>` that EXISTS NOWHERE (actual: two separate maps AnchorIndex and LinkMap, system-overview.md:106-107) — same defect class as INC-MAP-001/BI-010 which was rated CRITICAL; on "produced entirely in Pass 1" which is false (AnchorIndex is EXTENDED by Pass 1.5, and DirIndex — which path_resolver cannot function without — is produced ONLY in Pass 1.5; DirIndex appears ZERO times in feasibility-review); and on the retired "two-pass" framing that P4-003 canonicalized to three-phase everywhere else. The L4 document that gate-approved the 14-subsystem grouping certified feasibility for a pipeline shape and seam type that no longer exist.

**P6-S6-014 (POLICY 4)** — feasibility-review SF-002:196 cites BC-2.08.003 with a title that EXISTS ON NO BC ("Empty fragment, non-Markdown targets, and directories pass"); BC-2.08.003's actual H1 is "Fragment Split at First Unescaped # Before Percent-Decode". The split it demands ALREADY SHIPPED as BC-2.07.005 and BC-2.07.006. Actively harmful: a story-writer obeying SF-002 would attempt to split the FRAGMENT-SPLIT contract into path-resolution tasks.

**P6-S6-015 (POLICY 4/13)** — feasibility-review N-004:324 attributes a retired title to the wrong BC (BC-2.05.003's actual H1 is "HTML id= and name= Attribute Extraction"; the DI-008 half now lives on BC-2.05.001) and cites the wrong VPs (bc-module-map maps BC-2.05.003 -> VP-020, and VP-016 is never mapped to any SS-05 BC). Its entire premise describes a title already decomposed.

**P6-S6-016 [process-gap]** — ALL THREE SHOULD-FIX items and the NOTEs in feasibility-review are stale (SF-001 discharged by BC-2.02.002 v1.3; SF-002 discharged+mis-titled; N-001 incomplete; N-004 mis-anchored) yet the doc is status:accepted with Summary/Approval still saying "Three SHOULD-FIX items require story-writer attention", frontmatter prd_version 1.0, and ARCH-INDEX.md:45 routing product-owner+architect here for the authoritative feasibility verdict. An `accepted` L4 review report is a POINT-IN-TIME artifact with no revision trigger when its own findings are discharged, but it is indexed and consumed as CURRENT guidance. RECOMMEND per-finding status: fields with a sweep obligation, or marking the doc superseded-by-remediation once its SHOULD-FIX set closes.

**P6-S6-017** — bc-module-map.md:42-45,:462-490 demands a "single pass through all 66 BC files" for a POL-14 defect with ZERO remaining occurrences — `test-sufficient` occurs 3 times in behavioral-contracts/ and NONE is in a VP-NNN column (two are frontmatter history recording the fix, one is BC-INDEX prose). ARCH-INDEX.md:46 amplifies the stale flag. Cost if acted on: a 66-file sweep correcting nothing, with real risk of REVERTING BC-2.07.007/008's deliberate elevation to VP-023/VP-024. Also internally incoherent: "55 BCs" vs "all 33 test-sufficient BCs" in adjacent sentences (the map has 32 `none` rows).

**P6-S6-018 (POLICY 4/17)** — bc-module-map's Module Ownership Summary contradicts its own detail rows and Table 2 SUMS TO 70 against a declared Total of 66, silently reverting the v1.2 http_client 8->7 fix. Recomputing primaries from the 66 detail rows gives scanner 13, link_extractor 8, path_resolver 6, anchor_table 3, filter 4, reporter 6, http_client 7, http_verdict 3, anchor_resolver 3, url_classifier 3, slug 2, fragment 2, verdict 3, cli 3 = 66; four rows are wrong and `types` is missing from Table 2 entirely. Table 1 also lists BC-2.12.002 twice, omits BC-2.12.004, and INVERTS cli's primary/secondary on BC-2.12.002/004. ARCH-INDEX.md:46 designates this file as the CANONICAL BC->module routing for Phase 2, so a story-writer sizing waves off Table 2 gets four wrong module loads and a 70-BC universe.

**P6-S6-019 (POLICY 4/6)** — dependency-graph.md's binary-crate table OMITS pulldown-cmark, which its own :92 says scanner requires — a Cargo.toml generated from these tables will not compile scanner.rs. The event seam type is also UNOWNED (types is declared dependency-free at :71 yet link_extractor consumes "pulldown-cmark events" at :76) and DUAL-NAMED: `OffsetEvent` (api-surface.md:85) vs `PcEvent` (module-decomposition.md:52,90), neither resolving to a declaring module.

**P6-S6-020** — ADR-005's frontmatter `open_dependencies: DEP-001 status: open` was DISCHARGED by BC-2.03.002 v1.3, which delivered MORE than asked (PC7, Invariant 4, EC-202, a canonical vector). Three body cross-references still read as open, so DI-001's sort-key totality argument — the basis for sort_unstable_by safety — reads as conditional on an unmet precondition. CORROBORATES pass-5 P5-008.

**P6-S6-021 (POLICY 11)** — tooling-selection.md:155-160's POL-11 positive-coverage assertion is ITSELF a false-signal generator: `cargo nextest list | grep -c '^tests::'` returns 0 on EVERY run (nextest emits per-binary headers then INDENTED test names; nothing starts with `tests::` at column 0); `<expected_harness_count>` is an unfilled literal placeholder making the command unrunnable and a hardcoded count a POL-11 violation in itself; there is no --color=never guard (the same defect class as the prism PR #127 precedent cited in POL-11's own origin note); and the failure mode is a permanent false-fail that will be "fixed" by relaxing to `-ge 0`, i.e. a permanent no-op. The prescription meant to SATISFY POL-11 is the exact anti-pattern POL-11 exists to catch.

---

## MEDIUM

**P6-S6-022** — tooling-selection's Test Target Layout misfiles VP-011 as integration (VP-INDEX says proptest/reporter), places VP-017 under the core crate though its module `scanner` is in the BINARY crate, and omits VP-021 and VP-022 entirely (VP-022 being the merge-blocking gate harness).

**P6-S6-023** — bc-module-map applies three different labels to ADR-007 ("three-verdict model" at :235 — the framing DD-022 replaced, in the SS-10 section header story-writers read — vs the canonical "two-layer verdict model" at :202,:328) plus "three-pass pipeline" at :153 where canonical is "three-phase".

**P6-S6-024** — bc-module-map:464-466 MIS-DESCRIBES POLICY 14, which is `no_vp_tbd_after_phase_1b` (origin F-007, 99 VP-TBD occurrences) and says nothing about `test-sufficient`.

**P6-S6-025** — bc-module-map's SS-05 section header still cites ADR-006 after the v1.3 fix corrected the row beneath it, so header contradicts row; and ADR-008 (scoped by ARCH-INDEX to SS-05+SS-06) is absent from EVERY SS-05 row including BC-2.05.002 whose secondary module IS `slug`.

**P6-S6-026** — feasibility-review N-001's SS-10 story-assignment range BC-2.10.001,003..008 omits BC-2.10.009 and BC-2.10.010, both active and both assigned by bc-module-map — and BC-2.10.009's ownership needed a dedicated P3-027 adjudication.

**P6-S6-027** — dependency-graph's `app` line omits `anchor_table` (and `types`), which app requires to execute Pass 1.5; the Build Order for Phase 3 inherits the omission, landing app in step 6 with no stated dependency on the step-4 module it must call.

**P6-S6-028** — ADR-002:58-59 attributes `resolver = "2"` to "edition 2024 dependencies" — resolver 2 is the edition-2021 default and edition 2024 defaults to resolver 3; the stated reason is inverted and ADR-002 never states the workspace edition.

**P6-S6-029** — ADR-002:55-56 claims workspace membership lets fuzz targets reference "internal types" (it confers no visibility privileges — this invites pub leaks that erode the api-surface contract), and contradicts purity-boundary-map.md:125 on whether fuzz targets live under the core or binary crate; ADR-002 also describes a three-member workspace as two.

**P6-S6-030 (pending intent verification)** — rust-toolchain.toml:4 still installs x86_64-unknown-linux-musl and x86_64-unknown-linux-gnu under the D-043 macOS-only matrix, while dependency-graph.md:56 cites that file as the authoritative toolchain pin — either dead weight or Linux cross-compilation is still intended (in which case NFR-004's retirement as "vacuous" is premature).

**P6-S6-031** — BC-2.10.003.md:77 cites retired T13 as a live Brief Requirement alongside a likely-wrong R5. CORROBORATES shard 8 P6-S8-016.

**P6-S6-032 (POLICY 6)** — nfr-catalog.md:122 names module `slug_compute`, which does not exist (module is `slug`; the function is `compute_slug`). CORROBORATES pass-5 P5-036.

---

## OBSERVATIONS

dependency-graph.md is the ONLY architecture section file with no changelog (version 1.1, no record of what changed), which is why the pulldown-cmark omission has no fix trail; ADR-007 is the only ADR keeping its changelog as a body table so frontmatter-driven validators see it as changelog-less. ADR-007 PASSES the checks it was flagged for — no two-variant model, exit codes match error-taxonomy and R7 exactly, all 13 reason codes verbatim, dns-failure/tls-error correctly in broken, anchor-not-found correctly broken, no Indeterminate from anchor resolution; the v1.1/v1.3 F-001 remediation is genuinely COMPLETE. tooling-selection.md is the STRONGEST file in the shard on the D-043 axis (:65-72 re-grounds all four obligations on determinism rather than portability; :168-182 Phase 3 CI Obligations is a genuinely good defensive artifact that pre-empts a devops-engineer silently picking ubuntu-latest and states the negative-existence check it rests on). ADR-004's rustls/no-native-tls choice IS enforced by deny.toml's openssl-sys ban — the one place claim and tooling agree, and the model for the recommended tokio ban. feasibility-review.md:359 says "58 existing BCs" where the count is 66. feasibility-review.md:61-62 maps NFR-007 reason codes to SS-11 (Filter Application, which emits no reason codes); range should start at SS-12.

---

## ADR-004 STARVATION VERDICT — PARTIALLY, NOT ADEQUATELY

What ADR-004 DOES discharge cleanly: :42-48 names the hazard, mechanism, cause and mitigation with precision (ureq's synchronous blocking occupies a rayon thread for the full request duration; 32 such threads on the shared pool would "starve the CPU-bound Pass 1 and Pass 2 work — effectively serializing a parallel file scan behind network I/O"), names the construction, states the additive OS-thread cost honestly in Negative, and the reciprocal ADR-005 reference is present and consistent. CONCURRENCY NUMBERS AGREE ACROSS THE ENTIRE PACKAGE — no document prescribes a different pool size; ADR-004:38,86 / ADR-005:79-84 / BC-2.10.008 / system-overview / tooling-selection / bc-module-map / CAP-010 all say fixed 32 global + 4 per-host. NO substantive disagreement on sizing exists.

WHY INADEQUATE — three residual hazards in ADR-004's own subject matter, none addressed anywhere: (1) pool INTERACTION unspecified (P6-S6-006) — the deferral was about pool interaction and ADR-004 answered only the pool-membership half; (2) the prescribed per-host gate cannot enforce the cap without spinning (P6-S6-005), so the mitigation can regenerate the hazard it mitigates; (3) occupancy understated ~3x plus backoff (P6-S6-004), so the 32 constant is justified against the wrong workload model.

RECOMMEND ADR-004 v1.2 adding: an explicit ownership/join contract with an affirmative prohibition on nested install/join from a file-scan worker; a real per-host blocking primitive (Condvar or per-host queue) sufficient for BC-2.10.008 PC3 without spinning; retry/backoff semantics per CAP-010 with a re-derived thread-occupancy bound and re-justified 32; and deletion of the discharged :82-89 directive. ADR-005:52-53 and system-overview.md:165 must be reconciled to a single dispatch ordering in the same change.

---

## SKIP-LIST BLIND SPOTS

(a) "ADR exit-code/verdict consistency" is validated per-ADR against error-taxonomy and R7, never ADR-vs-L2-CAPABILITY — so a rejected alternative that is actually a required capability (P6-S6-007) and a schema-visible field absent from the authoritative ADR (P6-S6-008) are both undetectable.

(b) Counts validation covers index summary blocks, not in-document derived tables (P6-S6-018's 70-vs-66).

(c) NOTHING validates that a discharged directive gets closed — four independent instances here (P6-S6-003, 017, 020, 014-016); recommend requiring every `status: open` / "must be updated" / "requires reconciliation" / "action required" string to carry a machine-checkable target reference, failing when the target's version has advanced past the flag.

(d) Type-name and module-name resolution is entirely unchecked — four instances (DirEntries/Vec<OsString>, the phantom tuple-map seam, PcEvent/OffsetEvent dual-named and unowned, slug_compute).

(e) Crate-dependency tables are not cross-checked against module-dependency lines in the same file.

(f) Cross-document ORDERING claims are unvalidated (P6-S6-006).
