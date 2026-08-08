---
document_type: adversarial-review
level: ops
version: "1.0"
status: final
producer: adversary
timestamp: 2026-08-08T00:00:00Z
cycle: phase-1d
pass: 7
shard: 9
frozen_develop_head: f8ee4eb024b8b4a300139ef803d248e8fe40f2fc
frozen_specs_tree: ace1745871122cd1fa2c46cf27c5493cc1083411
frozen_spec_lint_tree: f2392b456c3bd669e3efbe86b3e6eae62e302ed1
severity_vocabulary: "CRITICAL/HIGH/MEDIUM/LOW (single vocabulary per PG-012 ruling)"
findings_total_self_declared: 27
inputs: []
input-hash: "ace1745"
traces_to: STATE.md
---
# Pass 7 — Shard 9: never-read BC bodies (SS-05, SS-06 BC-2.06.001, SS-10 ×7)

```
scope: "BC-2.05.001, BC-2.05.002, BC-2.05.003, BC-2.06.001, BC-2.10.002, BC-2.10.003, BC-2.10.004, BC-2.10.007, BC-2.10.008, BC-2.10.009, BC-2.10.010 = 11 bodies read in full"
files_read_in_full:
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-05/BC-2.05.001.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-05/BC-2.05.002.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-05/BC-2.05.003.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-06/BC-2.06.001.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-10/BC-2.10.002.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-10/BC-2.10.003.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-10/BC-2.10.004.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-10/BC-2.10.007.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-10/BC-2.10.008.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-10/BC-2.10.009.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-10/BC-2.10.010.md
reference_files_read_in_full:
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/product-brief.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/prd-supplements/error-taxonomy.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/VP-INDEX.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-002-slug-deterministic.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-007-http-verdict-total.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-015-two-pass-anchor-complete.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-016-ignored-files-anchor-targets.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-020-html-anchor-narrow-scope.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/capabilities.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/invariants.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/decisions.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/decisions/ADR-006-strict-path-model.md (lines 1-70)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/scripts/spec-lint/check-id-resolution.py
  - /Users/jmagady/Dev/mdlinkcheck-cloud/scripts/spec-lint/check-ec-injectivity.py
findings_total: 27
severity_counts: CRITICAL 2 / HIGH 11 / MEDIUM 10 / LOW 4
verdict: NOT CONVERGED — the never-read shard contains two false-green verification defects (a Kani proof claimed for properties it does not assert; a "total partition" with a 400-value hole covering the spec's own HTTP-999 case) plus a 20-row EC-registry mis-anchoring cluster that the EC-injectivity checker is structurally unable to detect.
```

**Disclosure (information-asymmetry hygiene):** one exploratory `Grep` over `.factory` for `AMB-037|AMB-086|AMB-088` returned four incidental matched lines from `.factory/cycles/phase-1d/*`. I did not open those files and no finding below derives from that output; every finding was re-derived from the frozen spec corpus and the checker sources. The leak is reported for transparency.

---

### P7-S9-001 — BC-2.06.001 claims a Kani P0 proof for two properties VP-002 does not assert (false-green) [CRITICAL]

`BC-2.06.001.md:107-114` Verification Properties table:

```
| VP-002 | Space→hyphen is 1:1 (trap T1) | kani |
| VP-002 | Unicode word chars preserved (trap T2) | kani |
```

VP-002's authoritative property is **determinism**, not either of these. `vp-002-slug-deterministic.md:35` H1 = "VP-002: slug::compute_slug is Deterministic — Same Input Produces Same Output"; `:39` Property Statement = "two calls to `compute_slug(s, &mut counter)` with equivalent initial states return byte-identical `String` values"; the entire harness assertion is `assert_eq!(slug1, slug2)` (`vp-002-slug-deterministic.md:75`). `VP-INDEX.md:58` records VP-002 as `slug | kani | P0 | — (CAP-006, NFR-003)`.

An implementation that collapses hyphen runs (`ai-automation` instead of `ai--automation` — the exact DI-012 rule-3 failure class at `invariants.md:304-306`) and one that strips Unicode word characters (DI-012 rule 6, `invariants.md:310`) are both perfectly deterministic and therefore **pass VP-002**. BC-2.06.001 nonetheless presents both as `kani`-verified. The two highest-risk DI-012 rules are marked formally proved and are not.

Corroborating: VP-002's own Source Contract (`vp-002-slug-deterministic.md:44`) anchors to "PC2 — `compute_slug` is deterministic", but BC-2.06.001 PC2 (`BC-2.06.001.md:57-58`) is "For any heading with at least one character surviving steps (b)–(d), the slug is a non-empty string" — not determinism. The BC↔VP anchor is wrong in both directions.

Same table additionally **omits VP-012**, which `VP-INDEX.md:186` assigns to BC-2.06.001 (`VP-001, VP-002, VP-012, VP-018, VP-026`). `vp-012-slug-fuzz.md:42` names BC-2.06.001 as its source contract. POLICY 9 requires VP-INDEX changes to propagate.

**Predicate:** `Grep '^- \*\*BC:\*\*' /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties` → 26 matches; 5 name BC-2.06.001 (vp-001:55, vp-002:43, vp-012:42, vp-018:59, vp-026:61). `Grep '^\| VP-' BC-2.06.001.md` → 5 rows for 4 distinct VP ids (VP-002 duplicated), VP-012 absent.

**Consequence:** the formal-verification gate reports P0 Kani coverage for space→hyphen 1:1 and Unicode-word retention. When VP-002 passes, the DI-012 rule-3 and rule-6 obligations are recorded as discharged although no harness exercises them. VP-012 (fuzz) is silently unscheduled for the module it was minted for.

---

### P7-S9-002 — BC-2.10.002 "Total Partition" leaves HTTP 600..=999 unassigned, including the spec's own HTTP-999 bot-block case [CRITICAL]

`BC-2.10.002.md:47-48` — "The postconditions below form a **total partition**: every possible HTTP status code value and every transport-layer outcome maps to exactly one liveness outcome. No HTTP outcome is unspecified." `:119-122` Invariant 3 repeats "every HTTP status code value ... maps to exactly one".

The enumerated postconditions cover only: `0..=99` and `1xx` (PC0, `:66-68`), `2xx` (PC1, `:69`), `3xx` (PC2, `:70-75`), `400..=499` (PC3/3b/4/5/6/7/8/9/10, `:76-96`), `500..=599` (PC11, `:97`). Nothing covers `600..=999`. PC0 — the postcondition explicitly labelled "This is the catch-all for any status code not explicitly enumerated below" — is scoped in its own title to `0..=99 and 1xx (100–199)`, so it does not reach 999.

HTTP 999 is not hypothetical in this corpus. It is a first-class member of the DD-016 GET-fallback trigger set and an explicitly named `http-indeterminate` trigger:
- `decisions.md:94` DD-016 — fallback on `{400, 403, 404, 405, 501, 999}`
- `error-taxonomy.md:85` — "bot-blocking 403/999 after GET fallback" → `http-indeterminate`
- `architecture/decisions/ADR-007-three-verdict-model.md:83` — same
- `domain-spec/failure-modes.md:67`, `domain-spec/events.md:104`, `domain-spec/risks.md:38` (R-003)
- `BC-2.10.001.md:39, :52, :60, :83, :89` — five sites

So a HEAD→999 must trigger a GET, and a GET→999 must produce a final verdict. BC-2.10.002 — the definitive total-partition contract per its own Capability Anchor Justification (`:166`) — supplies no rule, and none of its 16 canonical test vectors (`:137-155`) covers 999.

This is a **false-green**, not merely a gap. `vp-007-http-verdict-total.md:45` states the property over "the range 0..=999" and the harness (`:78-90`) ranges over all `u16`, but its only assertions are non-panic plus "verdict must be one of the three valid variants". The correctness harnesses (`:92-163`) pin 429, 5xx, 404, 410, dns, tls, timeout, and 400-after-GET — **not 999**. An implementation returning `broken(http-error)` for 999 satisfies VP-007 (Kani P0) in full while contradicting `error-taxonomy.md:85`, and produces exactly the LinkedIn/CDN bot-block false positive the product exists to prevent (`risks.md:38` R-003).

**Predicate:** `Grep '999' /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs` → 17 matching lines across 12 files; **zero** in `BC-2.10.002.md`. `Grep '999' BC-2.10.002.md` → No matches found.

**Consequence:** the SS-10 verdict classifier ships with an unspecified 400-code range; the P0 Kani gate passes regardless of what the implementer chooses; the reason code recorded for 999 may be outside the sanctioned mapping while `VP-021` (closed-set check) still passes because `http-error` is a legal member of the 13-code set.

---

### P7-S9-003 — BC-2.10.002 Invariant 1 and PC13 assign two contradictory verdicts to a DNS timeout [HIGH]

`BC-2.10.002.md:114` Invariant 1 — "429, 5xx, and **timeouts are NEVER mapped to `broken`**. (DI-010)".
`BC-2.10.002.md:102-103` PC13 — "**DNS resolution failure:** `broken` (`dns-failure`) → exit 1. DNS failure is definitively broken — the hostname does not exist."

A DNS lookup that times out (resolver unreachable, SERVFAIL, air-gapped CI runner) is simultaneously a *timeout* and a *DNS resolution failure*. Invariant 1 forbids `broken`; PC13 mandates it. The overlap is made explicit by `BC-2.10.003.md:54` Invariant 3 — "DNS resolution time counts within the 10-second budget" — which means a resolver hang consuming the full budget lands in PC12 (`:101`, timeout → `indeterminate (http-timeout)`) **and** PC13 (broken) at once.

PC13's stated justification ("the hostname does not exist") is true only for NXDOMAIN. It is false for SERVFAIL, resolver-unreachable, and timeout, all of which the postcondition's wording ("DNS resolution failure") captures.

This also falsifies Invariant 3 (`:119-122`), which asserts the outcomes are "exhaustive and **mutually exclusive** — every HTTP status code value and every transport outcome maps to exactly one", and violates DI-005 (`invariants.md:131-132`: "A link cannot have two verdicts or no verdict").

**Predicate:** magnitude not established by predicate — this is a two-site logical contradiction, cited exhaustively above.

**Consequence:** on any runner without DNS egress every external URL becomes `broken(dns-failure)` → exit 1, which is the false-positive class the brief's Problem statement names ("without false positives that train people to ignore it", `product-brief.md:28-29`). VP-007's harness pins `HttpError::DnsFailure` → broken and `HttpError::Timeout` → not-broken (`vp-007-http-verdict-total.md:133-145`) with no rule for the intersection, so the Kani gate cannot adjudicate it either.

---

### P7-S9-004 — 3xx response with absent/empty/unparseable `Location` header has no verdict in either the partition or the redirect BC [HIGH]

`BC-2.10.002.md:70-75` PC2 — "**3xx (redirect):** follow redirects up to the configured limit. — Final response after redirect: apply this partition recursively to the final status." The postcondition presumes a followable target.

`BC-2.10.007.md:47-51` PC1-PC4 — "Follow up to 10 redirects; take the final response for verdict determination" — same presumption. Neither BC states what happens when a `3xx` arrives with no `Location` header (304 Not Modified, 300 Multiple Choices with no preferred variant, or a malformed/relative-unparseable `Location`). There is no "final response" and no next hop.

`BC-2.10.007.md:53-56` Invariants 1-3 cover hop count, downgrade, and loop detection — not a missing header. `BC-2.10.007.md:58-63` edge cases cover 11 hops, HTTP→HTTPS, HTTPS→HTTP only.

**Predicate:** `Grep 'Location|304|600|999|3xx' /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/architecture/decisions/ADR-007-three-verdict-model.md` → 1 match (line 83, the `http-indeterminate` trigger list), which does not mention `Location` or 304. The condition is unadjudicated in the verdict ADR as well.

**Consequence:** a second hole in a partition asserted to be total (`BC-2.10.002.md:47-48`) and covered by a P0 Kani proof. `classify_response(304, attempt)` is reachable and unspecified; the implementer's choice is unconstrained and unreviewable.

---

### P7-S9-005 — BC-2.05.003 restricts HTML anchor extraction to *inline* HTML, contradicting DI-007, CAP-005, and its own verifying VP-020 fixture [HIGH]

BC-2.05.003 narrows the scope to inline HTML in three places:
- `BC-2.05.003.md:38-39` Description — "anchors from HTML `id=` and `name=` attributes **in inline HTML spans**"
- `BC-2.05.003.md:45` Precondition 2 — "The file contains **inline HTML** with `id=` or `name=` attributes"
- `BC-2.05.003.md:56` Invariant 3 — "Malformed HTML that pulldown-cmark **cannot parse as inline HTML** yields no anchor entries from that element"

But its own PC2 (`:49`) requires block-level HTML to work: "`<div id="bar">` and `<span id="baz">` add `"bar"` and `"baz"` respectively." A `<div id="bar">` at the start of a line is an HTML **block** in CommonMark — pulldown-cmark emits `Event::Html`, not `Event::InlineHtml`.

The authorities are broader than the BC:
- `invariants.md:210-211` DI-007 — "Only `id=` and `name=` attributes from **inline/raw** HTML elements are extracted"
- `capabilities.md:101-102` CAP-005 — "extract `id` and `name` attributes from **inline/raw HTML** elements"
- `vp-020-html-anchor-narrow-scope.md:44` — "extracts anchors ONLY from `id=` and `name=` attributes of HTML elements within **`Event::Html` events (block HTML)** and `Event::InlineHtml` events (inline HTML)"
- `vp-020-html-anchor-narrow-scope.md:68-79` fixture `vp020_id_attribute_extracted` uses `<div id="section-marker">Content</div>` on its own line — a block HTML event — and asserts the anchor IS extracted.

VP-020 is the sole VP assigned to BC-2.05.003 (`VP-INDEX.md:180`) and names BC-2.05.003 as its source contract (`vp-020-html-anchor-narrow-scope.md:14, :53`).

**Predicate:** magnitude not established by predicate — three narrowing statements and one contradicting postcondition, all cited by line above.

**Consequence:** an implementer working from BC-2.05.003 (the L3 contract, which is the implementation input) handles only `Event::InlineHtml`, satisfies the Description/Precondition/Invariant 3, fails PC2 and VP-020 fixture 1, and produces false `anchor-not-found` verdicts for the extremely common `<div id="...">`/`<h2 id="...">` documentation pattern — a KD-001 differentiator regression (`prd.md:245`).

---

### P7-S9-006 — BC-2.10.010 emits `private-ip` as a `reason`, violating the closed 13-code taxonomy; D-016 sub_reason propagation skipped this file [HIGH]

`BC-2.10.010.md:38-39` Description — "the URL is classified as `indeterminate` with **reason `private-ip`**".
`BC-2.10.010.md:56` PC1 — "Verdict: `indeterminate` (`http-indeterminate`, **reason: `private-ip`**)."
`BC-2.10.010.md:76-79` — four canonical test-vector rows read `indeterminate (private-ip)`, in the same column position where `BC-2.10.003.md:64` writes `indeterminate (http-timeout)` — i.e. the position that carries the reason code.

`private-ip` is a **sub_reason**, explicitly excluded from the reason taxonomy by every other authority:
- `error-taxonomy.md:115-124` §3b — "This field is NOT part of the 13-code closed `reason` taxonomy"; table row `| private-ip | ... | BC-2.10.010 |`
- `error-taxonomy.md:99-102` — the closed 13-code set does not contain `private-ip`
- `interface-definitions.md:194` — "`sub_reason` ... `"private-ip"` ... NOT part of the closed 13-code reason taxonomy"
- `BC-2.10.002.md:53-56` — "`sub_reason` is NOT a member of the 13-code closed `reason` taxonomy"
- `BC-2.10.002.md:110` and `:152` — correctly write "`http-indeterminate`; `sub_reason`: `private-ip`"

BC-2.10.010's changelog (`:22-24`) records only v1.4 (F-007) and v1.5 (INC-MAP). The D-016 sub_reason ruling was propagated to error-taxonomy §3b, interface-definitions §6.2, prd.md, and BC-2.10.002 (`prd.md:685` names exactly those four sites) and **never reached BC-2.10.010** — the owning BC.

**Predicate:** `Grep 'reason.*private-ip|private-ip.*reason' /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs` → 6 matching lines across 5 files. Exactly one uses `private-ip` as a reason: `behavioral-contracts/ss-10/BC-2.10.010.md:56`. The other five (interface-definitions.md:194, prd.md:685, error-taxonomy.md:85, BC-2.10.002.md:110, BC-2.10.002.md:152) all say sub-reason/sub_reason.

**Consequence:** POLICY 19 violation. An implementer reading the owning BC emits `reason: "private-ip"` in the JSON `reason` field, breaking NFR-007's closed-set invariant (`error-taxonomy.md:97-104`) and the `schema_version: 1` stability contract. VP-021 (no-undefined-reason-codes) would fail at implementation time — cost is paid downstream instead of here.

---

### P7-S9-007 — 20 of the 44 EC rows in this shard denote scenarios entirely different from the canonical test-vectors.md registry; check-ec-injectivity.py is structurally blind to the pattern [HIGH]

`test-vectors.md` is the canonical EC registry (`check-ec-injectivity.py:9` — "The canonical EC registry is test-vectors.md"). Twenty EC rows in this shard cite IDs whose canonical scenario is unrelated:

**BC-2.05.002** (`:57-63`) — 4 of 4 rows collide:

| BC row | canonical registry row |
|---|---|
| `:60` EC-050 "File with three `## Setup` headings" | `test-vectors.md:135` TV-050 EC-050 = `## my_heading` + `[x](#my_heading)` → clean, "Underscore retained" |
| `:61` EC-051 "`# Hello World`" | `:136` TV-051 = `## my_heading` + `[x](#my-heading)` → **broken** |
| `:62` EC-052 "`## C++ API`" | `:137` TV-052 = `## Café` + `[x](#café)` → clean |
| `:63` EC-053 "`## 日本語 heading`" | `:138` TV-053 = `## Café` + `[x](#caf%C3%A9)` → clean |

**BC-2.05.003** (`:58-64`) — 4 of 4 rows collide:

| `:61` EC-066 "`<a name="custom-anchor">`" | `:151` TV-066 = YAML front matter `title: Foo` + `[x](#foo)` → broken |
| `:62` EC-067 "`<span id="api-reference">`" | `:152` TV-067 = `## setup` + `[x](#Setup)` → broken, case-sensitive |
| `:63` EC-068 "`id=""` empty value" | `:153` TV-068 = `[x](#)` empty anchor → clean |
| `:64` EC-069 "`[x](#custom-anchor)` targeting `<a name="custom-anchor">`" | `:154` TV-069 = `[x](a.md#)` cross-file empty anchor → clean |

**BC-2.06.001** (`:84-94`) — 7 of 8 rows collide (EC-190 at `:94` is correct per `test-vectors.md:425`):

| `:87` EC-043 "`## Hello World`" | `:128` TV-043 = `## AI & Automation` + `[x](#ai--automation)` → clean |
| `:88` EC-044 "`## C++ Guide`" | `:129` TV-044 = `## AI & Automation` + `[x](#ai-automation)` → broken |
| `:89` EC-045 "`## 日本語`" | `:130` TV-045 = `## Integrations - Growth` triple hyphen |
| `:90` EC-046 "`## **Bold** Heading`" | `:131` TV-046 = `## Phase 1: MVP (128 Features)` |
| `:91` EC-047 "`## A  B` (two spaces)" | `:132` TV-047 = `## Setup` ×2 → 0-based counter |
| `:92` EC-048 "`##` (empty heading)" | `:133` TV-048 = `## Setup` ×3 → `#setup-2` |
| `:93` EC-059 "`## 🦀Rust`" | `:144` TV-059 = `Setext Title\n=====` → "Setext headings recognized" |

**BC-2.10.002** (`:126-135`) — 4 of 7 rows collide (EC-087/EC-198/EC-201 are correct):

| `:131` EC-088 "HTTP 503" | `:187` TV-088 = `https://nx-domain-xyz.invalid/` DNS NXDOMAIN → **broken(dns-failure)** |
| `:132` EC-089 "HTTP 410 Gone" | `:188` TV-089 = `http://localhost:3000/docs` → **indeterminate (private IP)** |
| `:134` EC-091 "https://example.com redirects to http://example.com" | `:190` TV-091 = `https://example.com/x` with `--allow` → **alive (allowed, not emitted)**; also collides with `BC-2.09.002.md:63` EC-091 = `--allow` evil.tld case |
| `:135` EC-092 "Connection to private IP `http://10.0.0.1/`" | `:191` TV-092 = `https://example.com.evil.tld/x` with `--allow` → **broken (prefix boundary)**; `decisions.md:91` DD-013 confirms "the `evil.tld` prefix hazard is documented in EC-092" |

**BC-2.10.010** (`:68`) — EC-092 again, "`http://192.168.1.1/` (RFC 1918 private)", same collision with TV-092.

Additionally 11 sub-lettered IDs have no registry row at all and resolve only through the base-ID loophole (`check-id-resolution.py:159-161`), attaching to semantically unrelated bases: EC-087b–f (`BC-2.10.004.md:72-76`, 429 Retry-After) and EC-087g (`BC-2.10.007.md:63`, HTTPS→HTTP downgrade) hang off EC-087 = self-signed TLS; EC-088b/c (`BC-2.10.008.md:64-65`, concurrency) off EC-088 = DNS NXDOMAIN; EC-092b/c/d (`BC-2.10.010.md:69-71`, private IP) off EC-092 = `--allow` prefix boundary. The v1.7/v1.4 EC-collision repairs (`BC-2.10.002.md:27`, `BC-2.10.007.md:26`) renumbered the bare IDs EC-087→EC-198/EC-199, EC-090→EC-201, EC-087e→EC-203, EC-087f→EC-204 and left the remaining sub-letters attached to the wrong bases — a partial fix.

**Why the checker cannot see this:** `check-ec-injectivity.py:191-194` gates description-collision detection on `if len(bc_occs) > 1` and lines 192-193 explicitly disable BC-vs-test-vectors description comparison ("BC-vs-TV is skipped"). All of EC-043..048, EC-050..053, EC-059, EC-066..069, EC-088, EC-089 appear in exactly **one** BC file each, so the branch never runs. The verdict-collision branch (`:217-233`) requires the BC row to carry a verdict column — every table above is 2-column `| EC | Description |`, so `:221-222` `continue`s. For the two IDs that *do* appear in two BCs, the Jaccard threshold of 0.10 (`:77-98`) is far too permissive: EC-092's two BC descriptions share `{http, private}` out of a 4-token union → 0.50; EC-091's share `{https, example, com}` out of 9 → 0.33. Both pass. The job then prints `Check passed: N EC IDs validated — all injective` (`:258-261`).

**Predicate:** `Grep '^\| EC-' <11 shard files>` → 44 total occurrences across 11 files (BC-2.06.001 8, BC-2.10.002 7, BC-2.10.004 6, BC-2.05.002 4, BC-2.05.003 4, BC-2.10.010 4, BC-2.10.009 3, BC-2.10.007 3, BC-2.10.008 2, BC-2.05.001 2, BC-2.10.003 1). `Grep '^\| EC-0(43|44|45|46|47|48|50|51|52|53|59|66|67|68|69|88|89|90|91|92) \|' .factory/specs/behavioral-contracts` → 23 matching rows across 7 BC files; 20 of them are in this shard and collide as tabulated. Verified-correct rows: EC-195/196 (`test-vectors.md:430-431`), EC-190 (`:425`), EC-087/198/201 (`:186, :433, :436`), EC-171 (`:387`), EC-199 (`:434`), EC-203/204 (`:438-439`), EC-090/149/150 (`:189, :192, :193`) = 13.

**Consequence:** the test-writer generating cases from BC edge-case tables and the test-writer generating from `test-vectors.md` produce two disjoint corpora under identical IDs. Traceability from BC → EC → TV is broken for 45% of this shard's edge cases; several collisions invert the expected verdict (BC EC-051 "`# Hello World`" vs TV-051 → broken; BC EC-088 "HTTP 503" → indeterminate vs TV-088 → broken(dns-failure)), so a golden-file suite keyed on EC ID will assert the wrong outcome.
**Tag:** [process-gap]

---

### P7-S9-008 — AMB-086 and AMB-088 are unresolvable IDs; check-id-resolution.py has no AMB family despite POLICY 16 naming it [HIGH]

`BC-2.10.007.md:83` — `| Brief Requirement | R5, AMB-086 |`
`BC-2.10.004.md:99` — `| Brief Requirement | R5, AMB-088 |`

Neither ID exists. The AMB registry is `.factory/planning/brief-validation.md`, which enumerates AMB-001..AMB-071 (rows at `:211-301`) plus a single stray AMB-094 at `:662`. There is no AMB-086 and no AMB-088 anywhere in the repository.

`check-id-resolution.py` enumerates its ID families at `:8-26` and implements resolution loops at `:378-452` for CAP, DI, DD, VP, NFR, BC, ADR, HS, POL, R, EC, and T. **AMB is absent from both the docstring and the code.** POLICY 16 explicitly lists AMB-* in scope ("all ID references in BC Traceability (EC-*, T-*, R-*, DD-*, DI-*, AMB-*, CAP-*, VP-*, ADR-*, NFR-*) must resolve to real registry entries"), and the checker is POLICY 16's declared `lint_hook`. The AMB family is therefore entirely unenforced, and the job still prints `Check passed: {files_checked} files checked — all ID references resolve` (`:511`).

**Predicate:** `Grep 'AMB-086|AMB-088' /Users/jmagady/Dev/mdlinkcheck-cloud/.factory` → 2 matching lines, both the citations themselves (`BC-2.10.004.md:99`, `BC-2.10.007.md:83`); zero registry definitions. `Grep 'AMB-0[0-9][0-9]' .factory/planning/brief-validation.md -o` → 84 occurrences, max ID AMB-094, registry block AMB-001..AMB-071. `Grep 'AMB' scripts/spec-lint/check-id-resolution.py` → the string does not appear.

**Consequence:** two BC Traceability anchors point at nothing, and the mechanism that is supposed to prevent that class has never covered it. Any AMB citation in any of the 66 BCs is unvalidated. The false-green is compounded by the positive-coverage line counting *files*, not resolved references — a corpus in which every AMB reference is fabricated would still print "all ID references resolve".
**Tag:** [process-gap]

---

### P7-S9-009 — BC-2.10.004 Invariant 4 asserts a bounded total pause that PC6 does not establish [HIGH]

`BC-2.10.004.md:65-66` Invariant 4 — "Total pause time accumulated across all hosts in one invocation is bounded; **no `--online` run can be delayed indefinitely** by server-controlled headers (120s clamp per PC6)."

PC6 (`:58-59`) clamps **each** honored pause: "The honored pause is clamped to `min(computed, 120s)`." Nothing bounds the number of pauses. Two independent unbounded dimensions remain:

1. **Across hosts.** With H distinct 429-returning hosts, total pause is up to H × 120s. H is corpus-controlled and unbounded.
2. **Within one host.** PC4-PC5 (`:56-57`) — "After the pause elapses, requests to that host resume. Resumed requests produce their own verdicts" — a resumed request that returns 429 again re-enters PC2/PC3 and pauses another 120s. No postcondition caps pause *cycles* per host, so a single hostile or misconfigured host delays the run indefinitely, which is exactly what Invariant 4 forbids.

Nothing in the BC's other invariants closes this: Invariant 2 (`:63`) scopes the pause per-host, Invariant 3 (`:64`) says other hosts are unaffected — both make dimension 1 worse, not better.

**Predicate:** magnitude not established by predicate — the claim is that PC1-PC6 (`BC-2.10.004.md:48-59`) contain no cycle bound and no cross-host aggregate bound; the six postconditions are enumerated in full at the cited lines.

**Consequence:** an invariant stated as an absolute product guarantee is not entailed by the contract's own postconditions, so no implementation or test can be written against it and no VP can falsify it (BC-2.10.004's VP column is `test-sufficient` ×2, `:90-91`). Operationally this is a remote-controlled CI hang: the brief's R8 5-second ceiling (`product-brief.md:52-53`) and NFR-001/NFR-002 acceptance gates (`decisions.md:72` DD-020) can be violated by a server response header.

---

### P7-S9-010 — All 8 VP Source Contract rows citing this shard's BCs use invented titles; the POLICY 7 fix landed on one sibling only [HIGH]

POLICY 7: the BC file H1 is the authoritative BC title. Every VP that anchors to one of this shard's BCs states a different title:

| VP file:line | title asserted | authoritative H1 |
|---|---|---|
| `vp-015-two-pass-anchor-complete.md:53` | "BC-2.05.001 — Two-Pass Anchor Table Construction" | `BC-2.05.001.md:35` "Three-Phase Design — Full Anchor Table Before Any Resolution" |
| `vp-020-html-anchor-narrow-scope.md:53` | "BC-2.05.003 — HTML Anchor Extraction Scope" | `BC-2.05.003.md:35` "HTML \`id=\` and \`name=\` Attribute Extraction into Anchor Table" |
| `vp-001-slug-total.md:55` | "BC-2.06.001 — Slug Computation Algorithm" | `BC-2.06.001.md:36` "github-slugger v2 Core Algorithm" |
| `vp-002-slug-deterministic.md:43` | same invented title | same |
| `vp-012-slug-fuzz.md:42` | same invented title | same |
| `vp-018-slug-worked-examples.md:59` | same invented title + "(corpus parity requirement)" | same |
| `vp-026-slug-differential-fidelity.md:61` | same invented title + "(parity with github-slugger v2)" | same |
| `vp-007-http-verdict-total.md:64` | "BC-2.10.002 — HTTP Response Classification" | `BC-2.10.002.md:37` "Three-Verdict Model (alive/broken/indeterminate) — Total Partition" |

This is a documented partial fix. `vp-016-ignored-files-anchor-targets.md:32` records: "P2-M05 + P2-M14 remediation: corrected Source Contract title from invented 'BC-2.08.004 — Ignored File Anchor Resolution' to actual BC-2.08.004 H1 'Cross-file anchor into ignored file'." The identical defect in eight sibling VP files in the same architectural layer was not swept. Note that BC-2.05.001's H1 was itself corrected in a prior burst ("REGRESSION-001: BC-2.05.001 title corrected from 'Two-Pass Design' to 'Three-Phase Design'", `BC-INDEX.md:253`) and propagated to BC-INDEX and prd.md §6.1 (`prd.md:681-682`) but not to VP-015, which still carries the retired title.

**Predicate:** `Grep '^- \*\*BC:\*\*' .factory/specs/verification-properties` → 26 matching lines; 8 of them cite one of this shard's 4 VP-bearing BCs; 8 of 8 differ from the H1. Authoritative H1s confirmed against `BC-INDEX.md:82-84, :92, :137-145` (all 11 BC-INDEX titles match their H1s exactly) and `prd.md:163-165, :175, :228-236`.

**Consequence:** a formal-verifier opening VP-015 sees "Two-Pass Anchor Table Construction" and can build a two-pass harness for a three-phase contract (Pass 1.5 is where three of the four DI-006 mechanisms live, `BC-2.05.001.md:88-91`). VP-007's "HTTP Response Classification" hides that BC-2.10.002 asserts a *total partition*, which is precisely the property VP-007 is supposed to discharge (see P7-S9-002). Fix site is the VP files; ground truth is this shard's H1s.

---

### P7-S9-011 — ADR-006 (path model) is cited as the governing ADR for the three-phase pipeline and for slug computation; ADR-006 v1.3 explicitly de-scoped slug [HIGH]

`BC-2.05.001.md:120` — "`anchor_table.rs` ... primary; `app.rs` ... secondary — three-pass pipeline (app) ensures anchor_table is complete before any resolution — **ADR-006**"
`BC-2.05.002.md:83` — "`anchor_table.rs` ... primary; `slug.rs` (SS-06, CRITICAL tier) secondary — ATX/Setext headings require slug computation to build anchor key — **ADR-006**"

ADR-006 is "Case-Sensitive NFC Strict Path Model" (`ADR-006-strict-path-model.md:25`). Its Context (`:27-45`) is APFS NFD storage and DI-002; its Decision (`:47-59`) is two-step NFC-normalize-then-byte-compare for path comparison; its pure-core signature is `pub fn files_match(a: &str, b: &str) -> bool` (`:64`). It contains nothing about pipeline phasing, pass ordering, or slug computation.

For BC-2.05.002 the citation directly contradicts ADR-006's own scoping decision. `ADR-006-strict-path-model.md:16` (v1.3 changelog): "removed SS-06 (slug) from `subsystems_affected` — **SS-06 is governed by ADR-008 (slug algorithm); ADR-006 covers path model only (SS-05, SS-07)**." BC-2.05.002's cited *secondary* module is `slug.rs` (SS-06) and the cited justification is slug computation — the exact thing ADR-006 disclaims. The correct ADR is ADR-008 (`ADR-008-slug-clean-room-reimplementation.md`), which BC-2.06.001 cites correctly (`BC-2.06.001.md:123`).

For BC-2.05.001 the pipeline/purity split between `app` (effectful) and `anchor_table` (pure) is ADR-001's subject (`ADR-001-pure-core-effectful-shell.md`), which BC-2.10.009 cites correctly for the analogous reason (`BC-2.10.009.md:105`).

Propagation root: `architecture/bc-module-map.md:149` — "Key ADRs: ADR-006 (NFC strict path model — anchor slug comparison)" for SS-05, and `:153-154` assign ADR-006 to BC-2.05.001 and BC-2.05.002. Both BC bodies faithfully copied a map row that was already wrong.

**Predicate:** `Glob .factory/specs/architecture/decisions/*.md` → 8 ADRs: ADR-001 pure-core-effectful-shell, ADR-002 workspace-layout, ADR-003 pulldown-cmark, ADR-004 ureq-sync-http, ADR-005 rayon-sort-before-emit, ADR-006 strict-path-model, ADR-007 three-verdict-model, ADR-008 slug-clean-room-reimplementation. `Grep 'ADR-006|ADR-001' architecture/bc-module-map.md` → ADR-006 assigned at lines 149, 153, 154, 175, 179-186; ADR-001 named as universally-applicable at `:49, :62`.

**Consequence:** POLICY 4/5 mis-anchoring. An implementer following BC-2.05.002's ADR pointer to understand slug-key construction reads a document about NFC filename comparison and finds nothing; the actual normative constraint (ADR-008's clean-room byte-for-byte parity requirement, and its explicit "no NFC/NFD normalization before slugging" rule at `invariants.md:313-322`) is not reachable from the BC. Given that the slug algorithm is named the primary differentiator (`BC-2.06.001.md:123`), a wrong ADR pointer on the BC that *builds the anchor key* is a live correctness risk.

---

### P7-S9-012 — Five of eleven bodies anchor to brief requirement R5, which does not cover their behavior; BC-2.05.001 anchors to BV-009, which is unrelated [HIGH]

`product-brief.md:46-47` R5 — "`--ignore <glob>` (repeatable) excludes files; `--allow <url-prefix>` (repeatable) exempts external URLs from checking." R5 is exclusively about the two filter flags.

Five shard BCs anchor to it for behavior R5 does not describe:

| site | behavior | correct brief anchor |
|---|---|---|
| `BC-2.05.002.md:82` `\| Brief Requirement \| R5 \|` | ATX/Setext heading extraction and slug computation | R2b (`product-brief.md:39-40` "anchor must match a heading in the target file using GitHub's slug algorithm") |
| `BC-2.10.003.md:79` `\| Brief Requirement \| R5 \|` | per-URL 10-second timeout | R2c (`product-brief.md:41-43` "HEAD request (GET fallback on 405), **10s timeout**, checked ONLY when `--online` is passed") |
| `BC-2.10.004.md:99` `R5, AMB-088` | 429 rate-limit host pausing | R2c |
| `BC-2.10.007.md:83` `R5, AMB-086` | redirect chain, max 10 hops | R2c |
| `BC-2.10.010.md:94` `R5, D-008` | private-IP classification | R2c (pre-flight guard in the `--online` liveness pipeline, per its own Capability Anchor Justification at `:92`) |

`prd.md` §7 RTM independently assigns R2c to four of these five (`:464` BC-2.10.003 R2c, `:465` BC-2.10.004 R2c, `:468` BC-2.10.007 R2c, and `:463` BC-2.10.002 R2c,R7), confirming R2c is the intended anchor and the BC bodies are the drifted side for those rows.

Separately, `BC-2.05.001.md:119` — `| Brief Requirement | R2b, BV-009 |`. BV-009 is "**No inline suppression mechanism, and no config file (non-goal).** Every real-world exception must become a CLI flag. Large repos will hit `--ignore`/`--allow` sprawl in CI invocations" (`brief-validation.md:186`; corroborated at `:78` and `:684`). It has no relation to three-phase anchor-table construction. `decisions.md:67` DD-005 resolves BV-009 to the "inline suppression directives out of scope" ruling.

**Predicate:** `Grep '^\| Brief Requirement \| R5' .factory/specs/behavioral-contracts` → 19 matching lines across 19 BC files; 5 are in this shard (BC-2.05.002:82, BC-2.10.003:79, BC-2.10.004:99, BC-2.10.007:83, BC-2.10.010:94). Of the other 14, several are legitimately R5 (BC-2.09.002:85 `--allow`, BC-2.11.002:107 `--allow`, BC-2.11.003:78 `--ignore`, BC-2.08.004:82 `--ignore`); the remainder are outside this shard's scope. `Grep 'BV-009' .factory/planning/brief-validation.md` → 3 matching lines (78, 186, 684), all about flag sprawl / no-config-file.

**Consequence:** POLICY 5 (creators_justify_anchors). R5 is being used as a default value rather than a justified anchor, which breaks R→BC requirement traceability for 5 of 11 bodies and makes the RTM's R-column unverifiable. `check-id-resolution.py:213-256` validates only that the token `R5` exists in the brief (it does); the docstring's own caveat about semantic relevance is scoped to T-NN only (`:21-23`), so R-NN topical correctness is unenforced by construction.

---

### P7-S9-013 — prd.md §7 RTM rows for 8 of the 11 shard BCs drift from the BC bodies on Brief Requirement, Domain Invariant, or Method [HIGH]

`prd.md:443-471` is the RTM. Comparing each row against its BC body (the H1-and-Traceability source of truth):

| RTM row | RTM value | BC body value |
|---|---|---|
| `:443` BC-2.05.001 Brief Req | R5 | `BC-2.05.001.md:119` R2b, BV-009 |
| `:445` BC-2.05.003 Brief Req | R5 | `BC-2.05.003.md:83` R2b, D-007 |
| `:445` BC-2.05.003 DI | DI-008 | `BC-2.05.003.md:82` DI-007, DI-008 (DI-007 dropped) |
| `:445` BC-2.05.003 Method | unit | `BC-2.05.003.md:75` VP-020 = **integration**; `VP-INDEX.md:76` integration |
| `:446` BC-2.06.001 Method | unit/property | `VP-INDEX.md:186` VP-001/VP-002 **kani P0** + VP-012 fuzz + VP-018 unit + VP-026 proptest |
| `:463` BC-2.10.002 DI | DI-005, DI-010 | `BC-2.10.002.md:167` DI-010 only |
| `:463` BC-2.10.002 Method | integration | `BC-2.10.002.md:160` VP-007 = **kani (P0)**; `VP-INDEX.md:63` kani P0 |
| `:464` BC-2.10.003 DI | DI-005 | `BC-2.10.003.md:78` DI-010 |
| `:469` BC-2.10.008 DI | DI-010 | BC body has **no** L2 Domain Invariants row (see P7-S9-014) |
| `:471` BC-2.10.010 Method | unit | `VP-INDEX.md:231` "integration test: mock DNS returning private IP" |

The two Method rows for BC-2.10.002 and BC-2.06.001 are the consequential ones: the RTM reports the verification method for the corpus's two P0 Kani-proved behaviors as `integration` and `unit/property`. Anyone reading the RTM to plan the verification phase would not schedule a Kani harness for the HTTP verdict classifier.

`scripts/spec-lint/gen-rtm.py` exists, so §7 is a derived table under POLICY 17; its lint hook is `check-counts.py`, which validates counts, not cell contents.

**Predicate:** `Grep 'BC-2\.05\.00[123]|BC-2\.06\.001|BC-2\.10\.(002|003|004|007|008|009|010)' .factory/specs/prd.md` → RTM rows at 443-446 and 463-471; 8 of the 11 shard rows differ from the BC body in at least one column as tabulated (matching rows: `:444` BC-2.05.002, `:466`/`:470` BC-2.10.009, `:465` BC-2.10.004 DI/Method). `Glob scripts/spec-lint/**` confirms `gen-rtm.py` present.

**Consequence:** the RTM is the phase-2 planning input. Verification-method drift on the two P0 formal proofs causes under-scheduling of the only two Kani harnesses that gate SS-06 and SS-10. Fix site is prd.md §7 (regenerate); ground truth is this shard's bodies.

---

### P7-S9-014 — BC-2.10.007 and BC-2.10.008 have no `L2 Domain Invariants` Traceability row; DI-010 is uncited by both [MEDIUM]

`BC-2.10.007.md:78-84` Traceability contains L2 Capability, Capability Anchor Justification, Brief Requirement, Architecture Module — no `L2 Domain Invariants` row. Same at `BC-2.10.008.md:84-90`.

Both BCs make DI-010 assertions in their bodies. `BC-2.10.007.md:50` PC3 "If the chain includes an HTTPS→HTTP downgrade: indeterminate" and `:55` Invariant 2 "HTTPS→HTTP downgrade is always indeterminate (never clean)" are DI-010 claims ("Indeterminate Does Not Cause Exit 1", `invariants.md:266-274`). `BC-2.10.008.md:56` Invariant 2 "A 429-paused host has 0 in-flight requests during the pause period" ties to DI-010 via BC-2.10.004.

`prd.md:469` RTM assigns DI-010 to BC-2.10.008, so the intended value is known and simply absent from the body. `prd.md:468` records "—" for BC-2.10.007, i.e. the omission is consistent between PRD and BC — but it leaves a real invariant unanchored in the redirect contract.

POLICY 2 requires every DI to be cited by at least one BC's L2 Invariants field; this is the reciprocal direction (a BC that enforces a DI must cite it back), which POLICY 2 item 4 classifies as scope mismatch.

**Predicate:** `Grep '^\| L2 Domain Invariants \|' <11 shard files>` → 9 matching lines. Missing: `behavioral-contracts/ss-10/BC-2.10.007.md`, `behavioral-contracts/ss-10/BC-2.10.008.md`.

**Consequence:** DI-010 → BC coverage is understated by two BCs, so the invariant-to-BC coverage audit reports coverage from BC-2.10.002/003/004/010 only. The redirect-downgrade path — the one place where a security-motivated `indeterminate` is minted — has no invariant anchor at all.

---

### P7-S9-015 — BC-2.10.004 PC3 is unsatisfiable for the absent-header case and contradicts its own canonical test vector [MEDIUM]

`BC-2.10.004.md:51-55` PC3 — "if the header is **absent**, unparseable, negative, or non-numeric-non-date, 60 seconds AND a `[warn]` diagnostic **naming the raw header value** is emitted to stderr."

When the header is absent there is no raw header value to name, so the postcondition cannot be satisfied for one of its four enumerated triggers.

The BC's own test vectors disagree with PC3 on the same point:
- `:82` "Host returns 429 (no Retry-After) | indeterminate; host paused 60s (default)" — **no `[warn]`**
- `:83` "Host returns 429 with `Retry-After: abc` (malformed) | indeterminate; host paused 60s; `[warn]` diagnostic emitted"

So the canonical vectors treat absent-vs-malformed as distinguishable on diagnostic emission while PC3 lumps them into one rule that mandates emission for both. Similarly, `:71` EC-199 and `:72` EC-087b are separate edge cases for the two conditions but the postcondition provides one merged rule.

**Predicate:** magnitude not established by predicate — one postcondition and two test-vector rows, cited in full above.

**Consequence:** two defensible implementations (warn on absent / don't warn on absent) both claim conformance; the golden-file stderr assertion for EC-087b is undetermined. Since this BC's VP column is `test-sufficient` ×2 (`:90-91`) with no formal property, the test is the only arbiter and the spec does not tell it what to assert.

---

### P7-S9-016 — BC-2.05.002 PC3 cites BC-2.06.001 for duplicate-counter semantics; the authority is BC-2.06.002 [MEDIUM]

`BC-2.05.002.md:49` PC3 — "Duplicate headings get suffixed slugs per github-slugger v2 counter semantics (**BC-2.06.001**)."

BC-2.06.001 is the core algorithm and explicitly defers the counter: `BC-2.06.001.md:54` PC1e — "Per-file duplicate counter applied (**see BC-2.06.002**)." The duplicate counter is BC-2.06.002's contract (`VP-INDEX.md:187` "BC-2.06.002 | Duplicate-heading counter"; `invariants.md:380` "DI-013 ... **Enforced by:** BC-2.06.002").

BC-2.05.002's own Related BCs section gets it right (`:86-87`): "BC-2.06.001 — composes with (slug algorithm); BC-2.06.002 — composes with (duplicate suffix counters)". The postcondition body was not updated to match — the classic POLICY 8 body/anchor divergence.

**Predicate:** magnitude not established by predicate — single-site mis-citation, cited above.

**Consequence:** POLICY 4 mis-anchoring. An implementer resolving PC3 opens BC-2.06.001 and is redirected again; the 0-based-vs-1-based rule that FM-002 turns on (`invariants.md:351-353`) is two hops away from the postcondition that depends on it.

---

### P7-S9-017 — BC-2.06.001 Invariant 2 states the rendered text of `## <kbd>Ctrl+C</kbd>` is `"ctrlc"`; it is `"Ctrl+C"` [MEDIUM]

`BC-2.06.001.md:75-77` — "A heading `## <kbd>Ctrl+C</kbd>` yields rendered text `"ctrlc"` → slug `"ctrlc"`."

The rendered text content is `"Ctrl+C"`. `"ctrlc"` is the *slug* — the result of applying steps (b) lowercase and (c) remove-non-`\p{Word}`. The invariant's job is to define the *input* to the slug function (`:68` "The slug input is the heading's **rendered text content**"), and here it substitutes the output.

The sibling example in the same invariant is stated correctly: `:73-74` — "A heading `` ## `foo` bar `` yields rendered text `"foo bar"` → slug `"foo-bar"`" — where the arrow genuinely separates render from slug. The `<kbd>` row makes the two sides identical by pre-applying steps (b)-(c) to the left-hand side.

**Predicate:** magnitude not established by predicate — single-site error; the correct rendering follows from `invariants.md:297-301` DI-012 rule 1 ("tag tokens are stripped; their visible text content, if any, is retained") which this very invariant quotes verbatim at `BC-2.06.001.md:80-81`.

**Consequence:** an implementer transcribing Invariant 2 as the render-stage contract may strip `+` (and by extension all non-word characters) during AST text collection rather than in step (c). That is behaviorally silent for `Ctrl+C` but not in general: stripping at render time before the counter key is computed would change collision behavior for headings differing only in punctuation, breaking DI-013 injectivity predictability (`invariants.md:355-356` "The counter key is the *computed slug* after DD-015 steps 1–4").

---

### P7-S9-018 — BC-2.06.001 cites "DD-015 #1..#5" worked examples that do not exist; DD-015's numbered items are algorithm steps [MEDIUM]

`BC-2.06.001.md:96-103` Canonical Test Vectors, Source column:

```
| "Hello World"      | "hello-world"   | DD-015 #1 |
| "C++ Guide"        | "c-guide"       | DD-015 #2 |
| "日本語 heading"    | "日本語-heading" | DD-015 #3 |
| "A  B" (2 spaces)  | "a--b"          | DD-015 #4 |
| "" (empty)         | ""              | DD-015 #5 |
```

DD-015 (`decisions.md:93`) contains no worked examples. Its numbered items (1)-(5) are the **algorithm steps**: "(1) rendered text content as input, (2) full Unicode `to_lowercase()`, (3) remove non-`\p{Word}`, non-hyphen, non-space chars, (4) 1:1 space→hyphen replacement (NO run collapsing, NO leading/trailing trim), (5) 0-based per-file duplicate counter via `while(occurrences contains result)` loop". So "DD-015 #1" resolves to "rendered text content as input", not to the `Hello World` vector; "#2" resolves to lowercasing, not `C++ Guide`.

`BC-2.06.001.md:113` compounds it: "VP-018 | **All DD-015 worked examples** produce correct slugs | unit". VP-018's corpus is defined in `VP-INDEX.md:99` as "15 worked examples incl. AI & Automation rule-3 and emoji rule-7 falsifying cases" and lives in `test-vectors.md` / `vp-018-slug-worked-examples.md` — not in DD-015.

Note none of these five vectors carries an EC or TV id, and the closest canonical registry rows are held by different scenarios (see P7-S9-007): `test-vectors.md:128` TV-043 is `## AI & Automation`, not `## Hello World`.

**Predicate:** `Grep 'hello-world|Hello World|C\+\+ Guide|worked example' .factory/specs/domain-spec/decisions.md` → 1 matching line, `:73` (the DD-021 row, which merely uses the phrase "DD-015 worked examples"). Zero matches on `:93`, the DD-015 row itself. `Grep 'DD-015 (#|worked)' .factory/specs` → 12 matching lines: 6 uses of the idiom "DD-015 worked examples" in other files (assumptions.md:45, assumptions.md:53, invariants.md:324, risks.md:36, ADR-008:172, prd.md:329) and 6 in BC-2.06.001 (`:99-103, :113`) — the only file using the numbered `DD-015 #N` form.

**Consequence:** five canonical test vectors have no resolvable source. The numbered form is worse than the idiom because it appears to resolve — "DD-015 #4" points to a real numbered item in DD-015 that says something else. A test-writer chasing the citation lands on the algorithm step and cannot confirm the expected slug. The phantom-referent idiom in the other six files should be swept in the same pass.

---

### P7-S9-019 — Six of eleven bodies carry a frontmatter `version` with no matching changelog entry; the most recent edit to each is unrecorded [MEDIUM]

| file | frontmatter `version` | highest `modified:` entry |
|---|---|---|
| `BC-2.10.003.md:4` | "1.5" | `:26` v1.4 |
| `BC-2.10.004.md:4` | "1.5" | `:26` v1.4 |
| `BC-2.10.007.md:4` | "1.6" | `:27` v1.5 |
| `BC-2.10.008.md:4` | "1.7" | `:26` v1.6 |
| `BC-2.10.009.md:4` | "1.4" | `:25` v1.3 |
| `BC-2.10.010.md:4` | "1.6" | `:24` v1.5 |

BC-2.10.008 additionally has no v1.1/v1.2 entries (its list starts at `:23` v1.3); BC-2.10.010's starts at `:23` v1.4.

Clean by contrast: BC-2.05.001 (1.6 / v1.6 at `:26`), BC-2.05.002 (1.3 / v1.3 at `:25`), BC-2.05.003 (1.4 / v1.4 at `:26`), BC-2.06.001 (1.5 / v1.5 at `:27`), BC-2.10.002 (1.8 / v1.8 at `:28`).

**Predicate:** `Grep '^version:|^  - "?v1\.[0-9]' .factory/specs/behavioral-contracts/ss-10 -o` (glob `*{002,003,004,007,008,009,010}*.md`) → highest changelog entry per file: BC-2.10.002 v1.8, BC-2.10.003 v1.4, BC-2.10.004 v1.4, BC-2.10.007 v1.5, BC-2.10.008 v1.6, BC-2.10.009 v1.3, BC-2.10.010 v1.5. Frontmatter `version` values read from the full-file reads: 1.8, 1.5, 1.5, 1.6, 1.7, 1.4, 1.6 respectively. Count of files with version > highest entry = 6 across the 11 (all 6 in SS-10).

**Consequence:** the partial-fix regression axis is unrunnable for these six files. The most recent edit to each — in a corpus where the last several bursts were exactly the EC-collision, quotation-authority, and proof-method-join repairs at issue in P7-S9-001/007/010 — leaves no record of what changed or which finding it closed. Reviewers cannot distinguish "fix applied and body updated" from "version bumped, body not touched".

---

### P7-S9-020 — BC-2.10.010's mandatory pre-flight DNS resolution sits outside BC-2.10.003's 10-second window, falsifying BC-2.10.003 Invariant 3 [MEDIUM]

`BC-2.10.010.md:52` Precondition 2 requires resolution to have already happened: "DNS resolution (or literal IP parsing) has produced an IP address for the URL's hostname." `:61` Invariant 1 makes it mandatory and pre-request: "The private-IP check is performed BEFORE any HTTP request is dispatched." `:36-37` Description: "**Before sending any HTTP request**, mdlinkcheck resolves the URL's hostname to an IP address."

BC-2.10.003 defines the timeout window as starting at request dispatch: `BC-2.10.003.md:38-39` — "a total timeout of 10 seconds (**wall clock from request start to response completion**)"; `:44` Precondition 1 — "An HTTP request is being made for an external URL."

So the pre-flight resolution BC-2.10.010 mandates occurs before "request start" and is therefore ungoverned by any timeout. That directly falsifies `BC-2.10.003.md:54` Invariant 3 — "DNS resolution time counts within the 10-second budget" — for the resolution that actually gates the request, and leaves a resolver hang unbounded.

The architecture makes the double-resolution concrete: ADR-004 selects ureq (`ADR-004-ureq-sync-http.md`, cited at `BC-2.10.003.md:80` and `BC-2.10.010.md:95`), which resolves DNS internally as part of the request. BC-2.10.010's pre-flight lookup is therefore a *second*, separate resolution, opening a TOCTOU window in which the pre-flight answer (public IP → proceed) and ureq's answer (private IP → SSRF target reached) differ. `BC-2.10.010.md:39-40` names SSRF prevention as the purpose.

**Predicate:** magnitude not established by predicate — a two-BC boundary mismatch, cited at the four lines above.

**Consequence:** (a) the 10s per-URL guarantee (`BC-2.10.003.md:52` Invariant 1, "Timeout is 10 seconds total per-URL. This cannot be configured in v1.0") does not hold, threatening NFR-001/NFR-002; (b) the stated SSRF guard is bypassable by DNS rebinding because no postcondition requires the pre-flight resolution result to be the address actually connected to.

---

### P7-S9-021 — BC-2.10.002's GET-fallback annotations are inconsistent with DD-016, and DD-016's "fall back to GET on 429" appears in neither BC-2.10.002 PC9 nor BC-2.10.004 [MEDIUM]

DD-016 (`decisions.md:94`) sets the fallback trigger set to `{400, 403, 404, 405, 501, 999}` plus transport-level failures, and adds: "**Also fall back to GET on 429** (but don't immediately retry — pause the host and honor `Retry-After`)."

BC-2.10.002 annotates fallback inconsistently across those triggers:
- 404 (`:86`) and 410 (`:91`) — "after HEAD + any GET fallback"
- 405 (`:87-90`) — "triggers GET fallback (see BC-2.10.001)"
- 400 (`:76-81`) — two postconditions about post-fallback behavior
- **403** (`:84-85`) — a DD-016 trigger, no fallback mention at all
- **501** — folded silently into "5xx (500–599)" (`:97`) with no fallback mention
- **999** — absent entirely (see P7-S9-002)
- **429** (`:92-93`) — "`indeterminate` (`http-indeterminate`). Also triggers host back-off per BC-2.10.004." No GET fallback.

BC-2.10.004 likewise never mentions a GET: PC1 (`:49`) "The 429-triggering URL receives verdict `indeterminate`", PC2-PC6 cover pause/resume only. So DD-016's 429-fallback rule is unrepresented in both the classification BC and the 429 BC.

**Predicate:** `Grep '999' .factory/specs` → BC-2.10.001 carries the full DD-016 set at `:39, :52, :60, :83, :89`; `Grep '999' BC-2.10.002.md` → No matches found. The 403/501/429 annotation asymmetry is enumerated by line above.

**Consequence:** the verdict for "HEAD 429 → GET 200" is undetermined. Under DD-016 the URL is `alive` → `clean`; under BC-2.10.002 PC9 and BC-2.10.004 PC1 it is `indeterminate`. That flips the emitted-vs-suppressed decision for the single most common rate-limited-CDN case, and `VP-007`'s harness pins only `classify_response(429, attempt)` → not-broken (`vp-007-http-verdict-total.md:96-99`), so it cannot arbitrate.

---

### P7-S9-022 — BC-2.06.001 asserts DI-013 duplicate-counter outcomes without citing DI-013 [MEDIUM]

`BC-2.06.001.md:121` — `| L2 Domain Invariants | DI-012 (slug computation fidelity — all 7 rules) |`. DI-013 is not cited.

The body nevertheless makes DI-013 assertions:
- `:54-55` PC1e — "Per-file duplicate counter applied ... **The counter is keyed on the result of steps (b)–(d)** — the computed slug string, NOT the original heading text." That is verbatim DI-013's counter-key rule (`invariants.md:355-356`).
- `:105` canonical test vector — `| "🦀Rust" then "🎯Rust" | "rust", "rust-1" | EC-190 — emoji-collision; counter keyed on "rust" |`. `rust`/`rust-1` is the 0-based-counter assertion DI-013 exists to protect (`invariants.md:350-353`, FM-002 discriminator).
- `:114` VP table includes VP-026, whose DI coverage per `VP-INDEX.md:82` is "DI-012, **DI-013**, FM-002 (BC-2.06.001/002)".

CAP-006 — the capability this BC anchors to — names both: `capabilities.md:119-124` "governed by DI-012 (slug computation fidelity); the file-global injectivity ... is governed by DI-013 (anchor-key uniqueness within a file). ... Governed by DI-012, DI-013."

`invariants.md:380` scopes DI-013's enforcer to BC-2.06.002, so the omission is arguable; per the intent-adjudication rule this difference is reported rather than silently skipped. However VP-026 — listed in *this* BC's VP table — is the vehicle that discharges DI-013, so DI-013 coverage is being claimed here by VP assignment while withheld in Traceability.

**Predicate:** `Grep '^\| L2 Domain Invariants \|' <11 shard files>` → BC-2.06.001 at `:121` cites DI-012 only. `VP-INDEX.md:82, :100` assign VP-026 to DI-012 + DI-013 and to BC-2.06.001/002.

**Consequence:** the DI-013 → BC coverage audit sees one enforcer (BC-2.06.002) while two BCs assert its outcomes and share its verifying VP. If BC-2.06.002 is ever re-scoped, DI-013's counter-key rule silently loses its second anchor.

---

### P7-S9-023 — BC-2.10.007 reason-code discipline: loop detection emits `too-many-redirects` whose taxonomy trigger it does not satisfy; PC3 supplies no reason code at all [MEDIUM]

Two related reason-code defects in the same BC:

**(a) Loop detection.** `BC-2.10.007.md:56` Invariant 3 — "Loop detection: if a redirect target is the same as a URL already in the chain, break immediately → **too-many-redirects**." `error-taxonomy.md:83` defines the code's trigger as "Redirect chain exceeded 10 hops" with human message template `too many redirects (>10): <url>`, and `error-taxonomy.md:159` repeats "redirect chain exceeded 10 hops". A 2-hop A→B→A loop breaks immediately, has not exceeded 10 hops, and would emit the message "too many redirects (>10)" — false on its face. This also contradicts the BC's own PC2 (`:49`, "**If redirect count exceeds 10**: broken (`too-many-redirects`)") and Invariant 1 (`:54`, "Max 10 hops is absolute").

**(b) Downgrade reason code.** `BC-2.10.007.md:50` PC3 — "If the chain includes an HTTPS→HTTP downgrade: **indeterminate (security warning)**." No reason code and no `sub_reason`. The authorities require both: `BC-2.10.002.md:73-75` "`indeterminate` (`http-indeterminate`; `sub_reason`: `https-downgrade`)"; `error-taxonomy.md:123` and `interface-definitions.md:194` assign `https-downgrade` to BC-2.10.007. "security warning" is not a member of the closed set and is not a defined output construct anywhere in the corpus. `:70` CV row is equally bare: "HTTPS → HTTP downgrade | indeterminate".

**Predicate:** `Grep 'sub_reason|private-ip|https-downgrade' .factory/specs/prd-supplements/interface-definitions.md` → 2 matching lines (`:194`, `:198`), both assigning `https-downgrade` to BC-2.10.007. `Grep 'sub_reason' BC-2.10.007.md` → the string does not appear in the file.

**Consequence:** (a) either a real loop is reported with a factually wrong reason and message, or loop detection silently produces no verdict — and `BC-2.10.007.md:75-76` shows both of this BC's properties are `test-sufficient` with no VP, so nothing catches it. (b) The owning BC for the `https-downgrade` sub_reason never names it, so an implementer working from BC-2.10.007 emits `http-indeterminate` with no `sub_reason` and the JSON diagnostic field D-016 was created for is never populated.

---

### P7-S9-024 — BC-2.10.009 carries a live `[filled after VP creation]` placeholder and duplicates its architecture anchors in two competing sections [LOW]

`BC-2.10.009.md:113-114`:

```
## VP Anchors
- [filled after VP creation]
```

The BC's VP column is `test-sufficient` (`:96`) and `VP-INDEX.md:230` confirms BC-2.10.009 is test-sufficient by design ("httpmock integration tests"). No VP is coming, so the placeholder asserts a pending artifact that will never exist. `:110-111` `## Story Anchor — [filled by story-writer]` and `:124` `| Stories | [filled by story-writer] |` are the sanctioned D-078/POL-14 Stories exemption; the VP Anchors placeholder is not covered by it.

Structurally BC-2.10.009 is also the only one of the eleven with a standalone `## Architecture Anchors` section (`:104-108`) *in addition to* the `| Architecture Module |` Traceability row (`:123`). The two carry overlapping but not identical content — `:105` says "primary owner per ADR-001 purity boundary" while `:123` says "ADR-004 ... ADR-005 ... per ADR-001". Two sources for one anchor.

**Predicate:** `Grep '^\| VP-NNN' / VP tables` — BC-2.10.009's VP table at `:93-96` contains one `test-sufficient` row; `VP-INDEX.md:230` records test-sufficient. Structural comparison across the 11 bodies: only BC-2.10.009 has `## Architecture Anchors`, `## Story Anchor`, and `## VP Anchors` sections (read in full; the other ten end at `## Traceability` / `## Related BCs`).

**Consequence:** a stale placeholder in a converged BC will read as an open action item at story-writing time, and a reviewer applying POLICY 14 must special-case it. The duplicated architecture anchor creates two places to update when the module map changes.

---

### P7-S9-025 — Empty-anchor asymmetry between BC-2.06.001 PC3 and BC-2.05.003 PC4 is undocumented [LOW] (pending intent verification)

`BC-2.06.001.md:58-61` PC3 — "For headings whose text yields an empty string after steps (b)–(d) (e.g., headings containing ONLY punctuation such as `## !!!`): the slug is `""` (empty string); **an empty-string anchor entry IS added** to the anchor table for compatibility with github-slugger v2 behavior."

`BC-2.05.003.md:51` PC4 — "Empty id/name values (`id=""`) are **NOT added** to the anchor table."

Both postconditions govern insertion of the same key (`""`) into the same structure. One mandates insertion, the other prohibits it, depending on the anchor's source. Neither BC acknowledges the other's rule, and no decision record adjudicates the asymmetry. `capabilities.md:143-145` CAP-008 notes "Pass empty fragments without check (DEC-007)", which makes both entries unreachable by resolution — so the asymmetry is probably harmless — but that reasoning appears in neither BC.

**Predicate:** magnitude not established by predicate — two postconditions, cited above.

**Consequence:** if the anchor table is a single map (per `BC-2.05.002.md:53` Invariant 1) the two rules interact on a shared key, and an implementer must infer that the difference is intentional. Low behavioral risk given DEC-007, but the reasoning should be recorded in one of the two BCs.

---

### P7-S9-026 — BC-2.10.002 Invariant 2 classifies `too-many-redirects` as a transport outcome, contradicting its own partition [LOW]

`BC-2.10.002.md:115-118` Invariant 2 — "Among **transport outcomes**: DNS failure (`dns-failure`), TLS failure (`tls-error`), and too-many-redirects (`too-many-redirects`) are also definitively `broken`."

The postconditions place `too-many-redirects` under the HTTP status partition, in PC2 "3xx (redirect)" (`:72`), not in the "Transport / Pre-HTTP Partition" section (`:99-111`, PC12-PC16), which contains only timeout, DNS failure, TLS failure, connection reset, and private-IP. `error-taxonomy.md:83` categorises `too-many-redirects` as `http`, not transport.

**Predicate:** `BC-2.10.002.md:99` is the `### Transport / Pre-HTTP Partition` heading; the section spans `:100-111` and contains PC12-PC16 with no redirect entry. `too-many-redirects` appears in the file only at `:72`, `:117`, and `:153`.

**Consequence:** cosmetic mislabelling within an invariant that is otherwise the authoritative broken-set enumeration. A reader auditing "which transport outcomes are broken" against the partition finds a fourth member that is not there.

---

### P7-S9-027 — BC-2.05.002 Invariant 1 models the anchor table as slug → list of line numbers, in tension with DI-013 injectivity [LOW] (pending intent verification)

`BC-2.05.002.md:53` Invariant 1 — "The anchor table is a HashMap from slug string to **list of line numbers** (for error messaging)."

DI-013 (`invariants.md:343-347`) requires the heading→anchor-key mapping to be injective within a file, so heading-derived keys each have exactly one line. A `Vec` value is only necessary if keys can repeat. The two legitimate repeat sources are HTML `id=`/`name=` values (BC-2.05.003 PC3, `:50`, "used verbatim (not slugged)" — no counter applied, so an id may collide with a heading slug) and the empty-string entry (P7-S9-025). Neither BC states which of these motivates the `Vec`, and neither states what happens when an HTML `id=` collides with an existing heading slug — append, overwrite, or apply a counter.

`module-decomposition.md:51` declares the module signature as `fn build(events: &ParsedHeading) -> AnchorTable`, which does not resolve the value type.

**Predicate:** `Grep 'anchor_table\.rs|slug\.rs|http_verdict\.rs|http_client\.rs' architecture/module-decomposition.md` → 4 matching lines (`:49, :51, :56, :80`); none specifies the `AnchorTable` value shape.

**Consequence:** low behavioral risk (resolution needs only key membership per `capabilities.md:139-145`), but the collision rule between heading slugs and verbatim HTML ids is unspecified and the container choice is unexplained, which will surface as a design question during SS-05 implementation.

---

## Novelty Assessment

**Novelty: HIGH.** This shard was previously unexamined and yields two CRITICAL false-green defects that no index-level or count-level check can surface:

1. **P7-S9-001** — a P0 Kani proof cited for two properties its harness does not assert. Detectable only by opening the VP body and reading the assertion, which is exactly the cross-check this shard's brief mandated.
2. **P7-S9-002** — a 400-value hole (`600..=999`) in a partition that declares itself total, covering HTTP 999, which appears in twelve other spec files and is a DD-016 fallback trigger. The Kani harness ranges over the hole but asserts only non-panic, so the gate passes either way.

Three findings falsify the assumption that existing checkers cover their declared policy scope, per D-057:

- **P7-S9-007** — `check-ec-injectivity.py:191-194` disables BC-vs-registry description comparison by design and gates the BC-vs-BC path on `len(bc_occs) > 1`; the verdict path requires a verdict column that 2-column BC edge-case tables do not have; the Jaccard threshold of 0.10 lets genuinely disjoint scenarios through on shared URL boilerplate (measured 0.33 and 0.50 for the two multi-BC cases). Twenty colliding rows survive while the job prints "all injective".
- **P7-S9-008** — `check-id-resolution.py` has no AMB family at all, despite POLICY 16 naming AMB-* in scope. Two fabricated AMB IDs sit in BC Traceability rows. The positive-coverage line counts *files*, not resolved references, so the assertion cannot distinguish "all IDs resolve" from "one whole ID family is never inspected" (POL-11 violation).
- **P7-S9-012** — R-NN resolution validates token existence only; the checker's own docstring scopes the "semantic correctness is not automatable" caveat to T-NN, leaving the R-family's topical correctness silently unenforced. R5 is functioning as a default value on 5 of 11 shard BCs.

Three findings are partial-fix regressions where a repair landed on one artifact and not its siblings — the axis that requires explicit verification after pass 1:

- **P7-S9-010** — the invented-BC-title fix is recorded in `vp-016:32` for BC-2.08.004 and was not applied to 8 sibling VP files; VP-015 still carries the "Two-Pass Design" title that `prd.md:681-682` retired.
- **P7-S9-006** — D-016 propagated to four named sites (`prd.md:685`) and skipped BC-2.10.010, the owning BC, which is now the sole artifact in the corpus treating `private-ip` as a reason code.
- **P7-S9-007** (sub-letter half) — the EC-collision sweep renumbered the bare IDs and left EC-087b–g, EC-088b/c, EC-092b/d attached to unrelated bases.

Scope items fully discharged with clean results: **code fences** (`Grep '```' <11 shard files>` → 0 occurrences across 0 files, so no undefined types can be introduced); **quoted-excerpt substantiation** (every `per <file> §<ID> ("quoted")` excerpt in the 11 bodies verified verbatim — CAP-005 at `capabilities.md:98`, CAP-006 at `:114`, CAP-010 at `:167`, DI-012 rule 1 at `invariants.md:297-298`, and AMB-037's "detect loops by URL deduplication" at `prd.md:305`; **zero fabrications found**, notably including BC-2.10.009's AMB-037 quote which is genuine); **BC H1 ↔ BC-INDEX ↔ PRD §2.x title sync** (all 11 match character-for-character at `BC-INDEX.md:82-84, :92, :137-145` and `prd.md:163-165, :175, :228-236`); **module-name resolution** (`anchor_table.rs`, `slug.rs`, `http_verdict.rs`, `http_client.rs` all present at `module-decomposition.md:49, :51, :56, :80`).

Not reviewed (out of shard): SS-05/SS-06/SS-10 siblings BC-2.05.* cross-references into SS-08, BC-2.06.002, BC-2.10.001/005/006, and the corpus-wide sweep of the R5-as-default pattern (14 further BCs at the P7-S9-012 predicate) and of the "DD-015 worked examples" phantom idiom (6 further files at the P7-S9-018 predicate). Both patterns are flagged here so the owning shards can size them.

The three-clean-pass streak cannot advance on this pass.