---
document_type: adversarial-review
level: ops
version: "1.0"
status: final
producer: adversary
timestamp: 2026-08-08T00:00:00Z
cycle: phase-1d
pass: 7
shard: 4
frozen_develop_head: f8ee4eb024b8b4a300139ef803d248e8fe40f2fc
frozen_specs_tree: ace1745871122cd1fa2c46cf27c5493cc1083411
frozen_spec_lint_tree: f2392b456c3bd669e3efbe86b3e6eae62e302ed1
severity_vocabulary: "CRITICAL/HIGH/MEDIUM/LOW (single vocabulary per PG-012 ruling)"
findings_total_self_declared: 25
inputs: []
input-hash: "ace1745"
traces_to: STATE.md
---
# Pass 7 — Shard 4: SS-08 + SS-09 + BC-2.10.001/005/006 (9 BC bodies)

```
scope: "SS-08 (4) + SS-09 (2) + BC-2.10.001/005/006 = 9 bodies read in full"
files_read_in_full:
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-08/BC-2.08.001.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-08/BC-2.08.002.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-08/BC-2.08.003.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-08/BC-2.08.004.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-09/BC-2.09.001.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-09/BC-2.09.002.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-10/BC-2.10.001.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-10/BC-2.10.005.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-10/BC-2.10.006.md
  # reference material read in full to substantiate claims:
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/prd-supplements/error-taxonomy.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/capabilities.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/invariants.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/product-brief.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/VP-INDEX.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-007-http-verdict-total.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-010-allow-component-boundary.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-015-two-pass-anchor-complete.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-016-ignored-files-anchor-targets.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-025-anchor-resolver-totality.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-10/BC-2.10.002.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/scripts/spec-lint/check-ec-injectivity.py
  - /Users/jmagady/Dev/mdlinkcheck-cloud/scripts/spec-lint/check-id-resolution.py
  - /Users/jmagady/Dev/mdlinkcheck-cloud/scripts/spec-lint/check-adr-consistency.py
findings_total: 25
severity_counts: CRITICAL 6 / HIGH 10 / MEDIUM 8 / LOW 1
verdict: NOT CONVERGED — six false-green/no-verdict CRITICALs including a systemic edge-case-registry mis-anchoring block (16 of 24 EC citations in this shard denote a different scenario than the canonical registry) and a phantom reason code invisible to the only POLICY 19 hook.
```

---

### P7-S4-001 — Under `--online` a malformed URL receives NO verdict: syntax validation is scoped offline-only, contradicting DD-010 and CAP-009 [CRITICAL]

`BC-2.09.001.md:33` H1 is "External URL Syntax Validation (**Offline**)". Precondition 2 (`BC-2.09.001.md:42`): "The tool is in offline mode (no `--online` flag)." Invariant 3 (`:53`): "Syntax validation is the ONLY check performed **in offline mode** for external URLs."

The L2 sources say the opposite:
- `capabilities.md:160` (CAP-009): "**Applied in both offline (default) and online mode.**"
- `decisions.md:88` (DD-010, a binding PO decision): "Syntax validation runs in **both offline (default) and online mode**."

`BC-2.10.001.md:45` then makes "The URL is syntactically valid (BC-2.09.001)" a **precondition** of the online path. Under `--online`: BC-2.09.001's preconditions are unsatisfied (not offline mode) so it yields no verdict, and BC-2.10.001's precondition 3 is unestablished so it yields no verdict either. A malformed URL under `--online` falls between both contracts. This violates DI-005 (`invariants.md:129-133`, "A link cannot have two verdicts or **no verdict**").

**Predicate:** `Grep "malformed-url"` over `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs` → 33 matches across 20 files. The only two BC bodies that assign `malformed-url` are `ss-09/BC-2.09.001.md` (lines 38, 46, 68, 69, 74 — all offline-scoped) and `ss-07/BC-2.07.007.md` (lines 37, 46, 53, 65, 66 — empty-destination only). **Zero** BC bodies assign `malformed-url` on the `--online` path.

**Consequence:** A malformed external URL in a repo checked with `--online` is silently dropped (or, at implementer discretion, treated as clean) — a silent false negative on exactly the class DD-010 exists to prevent. The implementer has no contract to code against and no test vector will catch it.

---

### P7-S4-002 — BC-2.08.001 explicitly FORBIDS percent-decoding the fragment, contradicting DI-003, CAP-008, prd.md and TV-157 [CRITICAL]

`BC-2.08.001.md:47` PC1: "The fragment = `destination.strip_prefix('#')`, **verbatim (no additional decoding** or lowercasing)." `:56` Invariant 3: "fragment is used **verbatim from source (not decoded)**".

Every authority says decode:
- `invariants.md:105-109` (DI-003 — cited by BC-2.08.001's own L2 Domain Invariants row at `:85`): "After splitting, **each component is percent-decoded independently**."
- `capabilities.md:141-142` (CAP-008 — the capability BC-2.08.001 anchors to at `:83`): "**Percent-decode the fragment before comparison.**"
- `prd.md:380`: "BC-2.08.002 | **Percent-decode before slug comparison** catches `#caf%C3%A9` correctly"
- `prd.md:760`: "**TV-157 / TV-157b** (EC-157): Percent-encoded fragment in cross-file link — `[Guide](other.md#caf%C3%A9)` where `other.md` has `## Café`. Positive: **exit 0 clean**."

An implementer following BC-2.08.001 PC1/Invariant 3 compares `caf%C3%A9` against the anchor key `café` → `broken (anchor-not-found)` → exit 1, failing TV-157.

**Predicate:** magnitude not claimed; four cited authority sites above, each with a line number.

**Consequence:** False-positive `anchor-not-found` on every percent-encoded fragment. Since BC-2.08.001 is the anchor-only contract and `anchor_resolver.rs` is shared with BC-2.08.002 (`bc-module-map.md:206`, `:349`), the "no decode" rule propagates into the cross-file path and breaks TV-157 as well.

---

### P7-S4-003 — 16 of 24 edge-case citations in this shard denote a DIFFERENT scenario than their canonical test-vectors.md registry row; several are verdict-inverted [CRITICAL]

`check-ec-injectivity.py:9` states the authority: "The canonical EC registry is test-vectors.md." Joining every EC row in the 9 in-scope bodies against its TV row:

| EC | BC body says | test-vectors.md registry row says | status |
|----|--------------|-----------------------------------|--------|
| EC-061 | `BC-2.08.001.md:62` `[x](#Setup)` where `## Setup` exists | `:146` TV-061 `#NoSpace` (no space after `#`), "Not a heading per CommonMark" | different scenario |
| EC-062 | `BC-2.08.001.md:63` `[x](#no-such-anchor)` | `:147` TV-062 `<a name="legacy"></a>`, `[x](#legacy)`, **clean** (HTML name= carve-out) | different + verdict-inverted |
| EC-063 | `BC-2.08.002.md:84` `[x](docs/api.md#overview)` | `:148` TV-063 `<h2 id="custom">T</h2>`, `[x](#custom)` | different scenario |
| EC-064 | `BC-2.08.002.md:85` `[x](docs/api.md#nope)` (no such heading) | `:149` TV-064 `## Title {#custom}` → `[x](#title-custom)`, **clean** | different + verdict-inverted |
| EC-032 | `BC-2.08.003.md:59` `a%23b.md` | `:110` TV-032 `[x](   )` whitespace-only destination malformed | different scenario |
| EC-035 | `BC-2.08.003.md:60` `a%20b.md#section` | `:113` TV-035 `[x](./a.md)`, `[x](././a.md)`, `[x](dir/../a.md)` path normalization, clean ×3 | different scenario |
| EC-077 | `BC-2.09.001.md:58` `https://example.com/path?q=1&r=2#frag` (offline syntax) | `:177` TV-077 `https://example.com/ok`, 200 to HEAD, `--online` | different scenario |
| EC-078 | `BC-2.09.001.md:59` `http://` (no host) → **broken** | `:178` TV-078 `https://example.com/head-405`, 405→GET 200, **clean** | different + verdict-inverted |
| EC-082 | `BC-2.09.001.md:60` `https://user:pass@host.com/path` | `:181` TV-082 `https://example.com/rate-limit`, 429, indeterminate | different scenario |
| EC-083 | `BC-2.09.001.md:61` `https://[::1]:8080/path` (IPv6) | `:182` TV-083 401 to HEAD and GET, indeterminate | different scenario |
| EC-084 | `BC-2.09.001.md:62` `https://xn--nxasmq6b.com` (Punycode) | `:183` TV-084 hangs 30s, indeterminate (`http-timeout`) | different scenario |
| EC-091 | `BC-2.09.002.md:63` `--allow https://example.com`; URL `https://example.com.evil.tld/` → NOT allowed | `:190` TV-091 `https://example.com/x` with `--allow` → **allowed, not emitted** | different + verdict-inverted |
| EC-080 | `BC-2.10.001.md:67` HEAD returns **403** | `:179` TV-080 `https://example.com/head-501`, **501**→GET 200 | different scenario |
| EC-085 | `BC-2.10.001.md:68` HEAD succeeds (200) → alive | `:184` TV-085 redirect chain of 12 hops → **broken (`too-many-redirects`)** | different + verdict-inverted |
| EC-086 | `BC-2.10.001.md:69` Both HEAD and GET return 404 → **broken** | `:185` TV-086 `301 → http://a.com/page → 200` → **indeterminate (downgrade)** | different + verdict-inverted |
| EC-081 | `BC-2.10.005.md:59` non-existent hostname → **broken (`dns-failure`)** | `:180` TV-081 `https://example.com/server-error`, returns 500 → **indeterminate** | different + verdict-inverted |

Correctly anchored (7): EC-072 (`BC-2.08.002.md:86` ↔ `:157` TV-072), EC-159/EC-160 (`BC-2.08.004.md:61-62` ↔ `:361-362`), EC-172 (`BC-2.10.006.md:59` ↔ `:388`), EC-191 (`BC-2.08.001.md:61` ↔ `:426`), EC-194 (`BC-2.08.001.md:64` ↔ `:429`), EC-200 (`BC-2.09.002.md:62` ↔ `:435`). EC-197 is a verdict-only conflict — see P7-S4-006.

**Predicate:** (a) `Grep "^\| (EC-032|EC-035|EC-061|EC-062|EC-063|EC-064|EC-072|EC-077|EC-078|EC-080|EC-081|EC-082|EC-083|EC-084|EC-085|EC-086|EC-091|EC-159|EC-160|EC-172|EC-191|EC-194|EC-197|EC-200) "` over `.factory/specs` → the 9 in-scope bodies contribute exactly **24** EC rows (BC-2.08.001: 4; BC-2.08.002: 3; BC-2.08.003: 3; BC-2.08.004: 2; BC-2.09.001: 5; BC-2.09.002: 2; BC-2.10.001: 3; BC-2.10.005: 1; BC-2.10.006: 1). (b) `Grep "EC-(159|160|191|194|197|200|080|085|086|081|172|061|062|063|064|077|078|082|083|084|032|035)\b"` over `test-vectors.md` → the TV rows quoted above; (c) `Grep "EC-091"` over `.factory/specs` → 3 hits (`test-vectors.md:190`, `BC-2.10.002.md:134`, `BC-2.09.002.md:63`); (d) `Grep "EC-072"` over `test-vectors.md` → `:157`, `:427`. Result: **16 of 24** scenario mismatches, 7 matches, 1 verdict-only mismatch.

**Consequence:** The test-writer builds vectors from EC IDs. Six of the sixteen are verdict-inverted: an implementer reading `BC-2.10.005.md:59` EC-081 builds an NXDOMAIN fixture expecting exit 1, while the registry row TV-081 for the same ID is a 500 expecting exit 0. Either the acceptance corpus is built to the wrong scenarios or the two sets silently diverge and the traceability chain BC→EC→TV is worthless. `BC-2.09.001` is fully mis-anchored (5/5 rows).

---

### P7-S4-004 — BC-2.08.001 attributes anchor-only resolution and case-mismatch to VP-015, whose three fixtures are all cross-file; Invariant 1 has no VP at all [CRITICAL]

`BC-2.08.001.md:76-77` Verification Properties:
```
| VP-015 | Anchor-only links resolved in same-file table | integration |
| VP-015 | Case mismatch → anchor-not-found | integration |
```
`vp-015-two-pass-anchor-complete.md` has `source_bc: BC-2.05.001` (`:14`) and exactly three fixtures (`:60`): `vp015_forward_reference_resolves` (`:76`, `a_source.md` → `./z_target.md#target-heading`), `vp015_backward_reference_resolves` (`:115`, `z_source.md` → `./a_target.md#my-heading`), `vp015_out_of_scan_target_anchor_resolves` (`:150`, `source.md` → `../outside.md#external-heading`). **All three are cross-file links.** There is no `#fragment`-only (same-file) fixture and no case-mismatch fixture anywhere in the file. VP-015's Non-Vacuousness table (`:184-188`) falsifies only: no-op scanner, single-pass scanner, missing Pass 1.5 — none of which is an anchor-only or case-folding bug.

Separately, `BC-2.08.001.md:55` Invariant 1 ("Anchor lookup is in the **SOURCE** file's table (not another file's table)") has no VP row at all. VP-025 cannot cover it: its signature is `resolve_anchor(fragment: &str, table: &AnchorTable)` (`vp-025:42`) — the table is supplied by the caller, so the property "the caller selected the source file's table" is outside VP-025's reach by construction.

**Predicate:** `Grep`-free structural read of `vp-015-two-pass-anchor-complete.md` in full: three `#[test]` functions at lines 76, 115, 150; the string `#` appears in fixture link targets only as `z_target.md#…`, `a_target.md#…`, `../outside.md#…`.

**Consequence:** False-green. A resolver that looks up anchor-only fragments in the *wrong* file's table, or that case-folds anchor-only lookups, passes VP-015's three fixtures and passes VP-025 (which is fed the correct table by the harness). The BC's two headline behaviours are unverified while the BC's VP table claims integration coverage.

---

### P7-S4-005 — BC-2.09.002 cites VP-010 for "component boundary prevents bypass", but VP-010 asserts "never raw byte prefixes" — the opposite of CAP-011's mandated raw-string fallback — and exercises only well-formed URLs [CRITICAL]

`BC-2.09.002.md:77`:
```
| VP-010 | Component boundary prevents bypass — see BC-2.11.002 | proptest |
```
`vp-010-allow-component-boundary.md:38` Property Statement: "The allow-match logic compares full URL components (scheme + host), **never raw byte prefixes**."

`capabilities.md:190-197` (CAP-011) mandates the opposite for the malformed case: "(3) if WHATWG normalization fails (URL is syntactically malformed), **fall back to raw-string prefix match at a component boundary**. … The component-boundary requirement — `example.com` must NOT match `example.com.evil.tld` — is **mandatory in both the normalized and raw-string paths**."

VP-010's harness (`:56-75`) generates only well-formed hosts (`host in "[a-z]{3,8}\\.[a-z]{2,4}"`) and calls `AllowPrefix::parse(&allowed_prefix).unwrap()` — an unwrap that presupposes successful parse. The raw-string fallback path is never entered, so its boundary rule is never falsified.

**Consequence:** Double defect. (a) False-green: the security-relevant path — a *malformed* URL matched against an `--allow` prefix by raw-string comparison, where a naive `starts_with` lets `https://example.com.evil.tld` bypass `https://example.com` — is the one path VP-010 provably does not reach, yet `BC-2.09.002.md:77` presents VP-010 as covering "Component boundary prevents bypass". (b) VP-010's normative sentence "never raw byte prefixes" directly contradicts CAP-011; an implementer reading VP-010 will omit the fallback entirely, at which point malformed allowed URLs are never exempted and `BC-2.09.002.md:51` PC1 is unimplementable.

---

### P7-S4-006 — TV-197, the canonical vector for EC-197 cited by BC-2.08.003, emits the phantom reason code `malformed-fragment` and contradicts BC-2.08.003's own split contract [CRITICAL]

`BC-2.08.003.md:61` cites `EC-197 | a.md##double-hash`. Its own Invariant 3 (`:54`) — "Subsequent `#` after the fragment start are part of the fragment (not another split point)" — and its own canonical vector (`:68`) — `` `a.md##double` | `a.md` | `#double` `` — specify a **clean, well-formed split**.

The registry row for that EC says the opposite verdict and an off-taxonomy code:

`test-vectors.md:432`
```
| TV-197 | EC-197 | `[x](a.md##double-hash)` — malformed fragment with double `#` | BC-2.08.003 | (none) | 1 | broken (malformed-fragment) | Formerly EC-076 in BC-2.08.003; double-`#` is syntactically malformed |
```

`malformed-fragment` is not a member of the closed set enumerated at `error-taxonomy.md:99-102` (`{file-not-found, target-is-directory, broken-symlink, anchor-not-found, undefined-reference-definition, malformed-url, http-error, dns-failure, tls-error, too-many-redirects, http-timeout, http-indeterminate, target-unreadable}`), which `error-taxonomy.md:23` declares closed ("Nothing may fail with a reason outside this set") and `:104` declares a bug ("Any code path that emits a verdict with a reason outside this set is a bug").

**Predicate:** `Grep "malformed-fragment|malformed_fragment"` over `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs` → **1 match**: `prd-supplements/test-vectors.md:432`. The code exists nowhere else — not in error-taxonomy.md, not in failure-modes.md, not in ADR-007, not in `vp-021-no-undefined-reason-codes.md:50,91`.

**Consequence:** POLICY 19 violation. Two mutually exclusive outcomes are specified for the same input: BC-2.08.003 says `a.md##double-hash` splits to path `a.md` + fragment `#double-hash` (then resolves normally), TV-197 says exit 1 broken with a code that does not exist. VP-021 (`:91`) validates emitted reasons against the 13-code list, so an implementer who codes TV-197 fails VP-021 — and an implementer who codes BC-2.08.003 fails TV-197. The acceptance corpus and the formal reason-code gate are in direct conflict.

---

### P7-S4-007 — BC-2.09.001 lacks the `--allow` exemption precondition its sibling BC-2.10.001 carries; an allowed-but-malformed URL gets two contradictory verdicts [HIGH]

`BC-2.09.001.md:41-42` Preconditions are only: (1) classified `external-http`; (2) offline mode. `:46` PC2 then mandates: "If WHATWG parse fails: verdict `broken`, reason `malformed-url`."

`BC-2.09.002.md:51-52` PC1 mandates: "If the URL matches an allow prefix … verdict `clean`; URL is **not validated** and not emitted in output."

Because CAP-011 (`capabilities.md:193-195`) requires the raw-string fallback to match *malformed* URLs, the overlap is non-empty: a malformed URL matched by an `--allow` prefix satisfies BC-2.09.001's preconditions (external-http, offline) → `broken(malformed-url)`, and BC-2.09.002's preconditions → `clean`. DI-005 (`invariants.md:129-131`) forbids two verdicts.

The correct guard exists on the sibling: `BC-2.10.001.md:46` Precondition 4 — "The URL has not been exempted by `--allow` (BC-2.09.002)." It was never added to BC-2.09.001. This is a partial-fix propagation gap within the same subsystem pair (SS-09 ↔ SS-10).

**Consequence:** `--allow` is unreliable for the exact case it is most needed (internal/intranet URLs that WHATWG rejects). Implementer choice decides whether exit code is 0 or 1.

---

### P7-S4-008 — BC-2.10.001's post-GET partition is not total: GET-999, GET-1xx, GET-3xx, codes ≥600, and ALL transport failures on GET have no postcondition [HIGH]

`BC-2.10.001.md:52-57`:
- PC3: fallback triggers on `{400,403,404,405,501,999}` **or transport failure**.
- PC4: GET 200-299 → alive. PC5: GET 404/410 → broken. PC6: GET "4xx (not 404/410) **or** 5xx" → indeterminate. PC7: GET times out → indeterminate.

Unassigned after GET: **999** (neither 4xx nor 5xx — and 999 is explicitly *in* the trigger set at `:52`, so LinkedIn's HEAD-999/GET-999 pattern is a first-class expected case: `dtu-assessment.md:157` names it "the LinkedIn pattern"); **1xx**; **3xx**; anything ≥600; and every **transport failure on the GET attempt** (connection reset, DNS, TLS) — PC3 lists transport failure as a *trigger* but no postcondition classifies a transport failure *result*.

Also unassigned on the HEAD leg: HEAD statuses outside the trigger set that are not 2xx/3xx (401, 410, 429, 5xx) receive no verdict, because Invariant 1 (`:60`) forbids GET fallback for them ("Not for all non-2xx") and PC4-PC7 are all GET-conditioned. HEAD **timeout** is likewise unassigned.

The sibling BC-2.10.002 does provide a total partition (`BC-2.10.002.md:64-111`, Invariant 3 at `:119-122`) — but BC-2.10.001 is the contract that *owns* the two-attempt protocol, and it never defers the residue to BC-2.10.002 (its Traceability has no Related BCs section at all; contrast `BC-2.10.006.md:81-85`).

**Predicate:** magnitude not established by predicate; the gap is derived from the literal text of PC2-PC7 at `BC-2.10.001.md:51-57`.

**Consequence:** DI-005 no-verdict violation for the LinkedIn 999 case and for every GET-leg network failure. `http_verdict.rs` is CRITICAL-tier (`module-criticality.md:78`); an implementer coding only BC-2.10.001 produces a non-total `classify_response`, which then fails VP-007's totality harness (`vp-007:78-90`) with no spec text to guide the repair.

---

### P7-S4-009 — BC-2.10.001 PC3 makes a "DNS-level error" a GET-fallback trigger, contradicting BC-2.10.005 Invariant 1 and BC-2.10.002 PC13 [HIGH]

`BC-2.10.001.md:39-40` (Description) and `:52` (PC3) both make transport failure "(connection reset, **DNS-level error**)" a trigger for a second, GET request.

`BC-2.10.005.md:46-48` PC1/PC2: DNS resolution failure → verdict `broken`, reason `dns-failure`, immediately; `:53` Invariant 1: "DNS failure is `broken`, **not** `indeterminate`". `BC-2.10.002.md:102-103` PC13: "DNS resolution failure: `broken` (`dns-failure`) → exit 1." `vp-007:132-135` asserts it as a Kani P0 obligation: `classify_response_with_error(HttpError::DnsFailure)` MUST be `Broken`.

None of these three admit a retry-with-GET step. And per P7-S4-008, BC-2.10.001 has no postcondition for the outcome of a GET issued after a transport failure, so if an implementer follows PC3 the resulting state is unclassified.

**Consequence:** Either a wasted second request per dead hostname (a measurable cost on the R8 5-second budget with `--online`), or — worse — an implementer treats the DNS retry as "transport indeterminate" and NXDOMAIN silently becomes exit 0, inverting the product's flagship broken-link case.

---

### P7-S4-010 — BC-2.10.005 Invariant 2 delegates resolver-connectivity classification to "implementer judgement", contradicting the closed taxonomy, the total partition, and VP-007 [HIGH]

`BC-2.10.005.md:54`:
> "A resolver connectivity failure (can't reach resolver) **MAY be indeterminate; implementer judgement** — default to broken."

Three conflicts:
1. `error-taxonomy.md:23` — the reason set is closed. If the implementer chooses `indeterminate`, which of the 13 codes is emitted? `http-indeterminate`'s trigger list (`error-taxonomy.md:85`) enumerates "429, 5xx, or bot-blocking 403/999 after GET fallback; OR connection was reset before any response; OR target IP is private/link-local …; OR https→http protocol downgrade" — resolver-unreachable is not among them. Any choice emits a code whose documented trigger does not cover the condition.
2. `BC-2.10.002.md:99-111` claims a **total partition** ("every possible HTTP status code value and every transport-layer outcome maps to **exactly one** liveness outcome", `:47-48`) and contains no resolver-unreachable case — so the partition is not in fact total, and where it is silent BC-2.10.005 authorises two answers.
3. `vp-007:53` asserts "`dns-failure` and `tls-error` **ALWAYS** produce `broken`". An implementation exercising the sanctioned "MAY be indeterminate" branch fails the Kani P0 proof.

Also: `invariants.md:56-57` — "Violation of any DI-NNN is a bug, **not a configuration option**" — and NFR-003 reproducibility require verdicts be a function of repository content. A verdict that varies by implementer choice is not reproducible.

**Consequence:** A CI runner behind a flaky DNS resolver either fails the build (exit 1) or passes it (exit 0) depending on an unrecorded implementation decision, and the emitted reason code is off-taxonomy either way. Also makes VP-007's P0 proof unlockable without a spec change.

---

### P7-S4-011 — BC-2.10.006 does not specify connection-reset behaviour although BC-2.10.002 names it as the owner in two places [HIGH]

`BC-2.10.002.md:107-108` PC15: "**Connection reset / refused:** `indeterminate` (`http-indeterminate`). Transient network error; the resource may be temporarily unreachable. **See BC-2.10.006.**"
`BC-2.10.002.md:175` Related BCs: "BC-2.10.006 — dependency (TLS failure handling; **also covers connection reset per PC15**)."

`BC-2.10.006.md` in full (lines 35-85) concerns only TLS handshake failure. The strings "connection", "reset" and "refused" appear nowhere in it: Description `:37-41` (TLS), Preconditions `:44-46` (TLS handshake fails), Postconditions `:49-50`, Invariants `:53-54`, Edge Cases `:59` (self-signed cert), Test Vectors `:64-66` (expired / self-signed / hostname mismatch), Related BCs `:82-84`.

**Predicate:** `Grep`-free full read of BC-2.10.006.md (85 lines); no occurrence of "connection", "reset", or "refused".

**Consequence:** Dangling delegation. Connection-reset is the outcome that separates a genuinely dead host from a transient CI network blip, and it is the residue-catcher for BC-2.10.001 PC3's transport-failure trigger (P7-S4-008). Neither BC specifies it, so it has no owning contract, no test vector, and no invariant — while BC-2.10.002 asserts it does.

---

### P7-S4-012 — Empty-fragment verdict is self-contradictory inside BC-2.08.001 and BC-2.08.002 (postconditions are unordered) [HIGH]

`BC-2.08.001.md:47-51`:
```
1. The fragment = destination.strip_prefix('#'), verbatim …
2. The fragment is looked up in the source file's own anchor table.
3. If found: clean.
4. If not found: broken (anchor-not-found).
5. Empty anchor `#` (bare hash): clean …
```
For destination `#`: PC1 yields `""`; PC2 looks `""` up; PC4 yields `broken`; PC5 yields `clean`. Postconditions carry no precedence marker, so both fire.

Same defect at `BC-2.08.002.md:66-69`: PC5 "fragment is NOT in its anchor table: broken (`anchor-not-found`)" vs PC7 "Empty fragment `path.md#` → clean".

`capabilities.md:145` (CAP-008) resolves it — "**Pass empty fragments without check** (DEC-007)" — i.e. the resolver must not be invoked at all. Neither BC states the bypass; both state a lookup followed by a contradicting exception.

The cited VP takes the other branch: `vp-025:72-75` — "`resolve_anchor("", table)` returns `Clean` **if and only if** `""` is a key in `table`… and `Broken` otherwise" — with the harness asserting `Broken` when `""` is absent (`vp-025:283-288`).

**Consequence:** `[x](#)` — an extremely common "back to top" idiom — is specified as both clean and broken. `test-vectors.md:429` TV-194 requires exit 0; an implementer who reads PC1→PC4 literally (as PC1 explicitly forbids any pre-processing) ships exit 1 and fails on the tool's own README, the failure class `invariants.md:123-125` (DI-004 rationale) calls out as unacceptable.

---

### P7-S4-013 — EC-091 has two conflicting owners in BC bodies and matches neither the registry; the injectivity checker is structurally blind to it [HIGH]

Three incompatible meanings for one ID:
- `test-vectors.md:190` TV-091 (canonical): `https://example.com/x` with `--allow https://example.com --online` → exit 0, "alive (allowed, not emitted)".
- `BC-2.09.002.md:63`: "`--allow https://example.com`; URL `https://example.com.evil.tld/`" — the *bypass-must-fail* case.
- `BC-2.10.002.md:134`: "https://example.com redirects to http://example.com" — the https-downgrade case.

This is a POLICY 1 / POLICY 4 violation and a partial-fix survivor: `BC-2.11.002.md:25` records "P2-M09 — renamed EC-090/091/092 to EC-161/162/163 (**deduplicated from BC-2.10.002's legitimate HTTP block use of those IDs**)" and `BC-2.09.002.md:26` records "EC-090→EC-200 (EC-090 canonical owner is BC-2.10.009 …)". BC-2.11.002 remapped all three; BC-2.09.002 remapped only 090 and left 091 colliding with the very file the note calls the legitimate owner.

Separately, TV-091's verdict cell reads "**alive** (allowed, not emitted)" — an `--allow`-exempt URL is never fetched, so no liveness outcome is produced. Per `error-taxonomy.md:48` and `invariants.md:135-141`, `alive` is an HTTP-layer outcome only; the correct value is `clean`, which is what `BC-2.09.002.md:51` PC1 says. TV-091 flattens Layer 2 into Layer 1.

**Predicate:** `Grep "EC-091"` over `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs` → **3** matches (the three sites above).

Why it survived: `check-ec-injectivity.py:77-98` gates description collisions on Jaccard < 0.10. Significant tokens (`_significant_tokens`, `:63-74`, `[a-z]{3,}` minus stop-words) for the two BC descriptions are `{allow, https, example, com, url, evil, tld}` and `{https, example, com, redirects, http}` → intersection 3, union 9, **Jaccard = 0.333 ≥ 0.10** → not flagged. Shared URL vocabulary defeats the threshold for any two URL scenarios.

**Consequence:** Anyone resolving EC-091 gets a different scenario depending on which file they open, and the security-critical allow-bypass negative case has no distinct registered ID or TV row.

---

### P7-S4-014 — Brief-Requirement mis-anchoring: BC-2.09.001, BC-2.10.001 and BC-2.10.006 cite R5 (`--ignore`/`--allow`) instead of R2c; BC-2.10.005 is the correct sibling [HIGH]

`product-brief.md:46-47` R5 is: "`--ignore <glob>` (repeatable) excludes files; `--allow <url-prefix>` (repeatable) exempts external URLs from checking." `:41-43` R2c is: "Absolute http(s) URLs — HEAD request (GET fallback on 405), 10s timeout, checked ONLY when `--online` is passed. Default is offline: external URLs are syntax-validated but not fetched."

The capabilities these BCs anchor to ground in R2c, not R5: `capabilities.md:162` (CAP-009 Grounding: 'R2c — "external URLs are syntax-validated but not fetched."'), `capabilities.md:179-180` (CAP-010 Grounding: 'R2c — "HEAD request (GET fallback on 405), 10s timeout…"').

Yet:
- `BC-2.09.001.md:82`: `Brief Requirement | R5, R6, T11` — external-URL syntax validation has nothing to do with `--ignore`/`--allow` (R5) or output format (R6).
- `BC-2.10.001.md:91`: `Brief Requirement | R5, DD-016, T12`
- `BC-2.10.006.md:78`: `Brief Requirement | R5, AMB-090`
- `BC-2.10.005.md:76`: `Brief Requirement | R2c` ← the one sibling that is right.

`prd.md`'s derived traceability table agrees with R2c and therefore contradicts the four bodies: `:460` BC-2.09.001 → `R2c`; `:462` BC-2.10.001 → `R2c`; `:467` BC-2.10.006 → `R2c`. The reverse drift also exists at `:457` (BC-2.08.002 → `R5`) where the body says `R2b` (`BC-2.08.002.md:111`, correctly matching CAP-008's R2b grounding at `capabilities.md:151`).

**Predicate:** `Grep "Brief Requirement"` over `.factory/specs/behavioral-contracts` → 69 rows across the corpus; within the 9 in-scope bodies the values are BC-2.08.001 `R5, AMB-053` (`:86`), BC-2.08.002 `R2b` (`:111`), BC-2.08.003 `R5, T9` (`:82`), BC-2.08.004 `R5, DD-008` (`:82`), BC-2.09.001 `R5, R6, T11` (`:82`), BC-2.09.002 `R5` (`:85`), BC-2.10.001 `R5, DD-016, T12` (`:91`), BC-2.10.005 `R2c` (`:76`), BC-2.10.006 `R5, AMB-090` (`:78`). Cross-joined against `prd.md:456-467` → **4 divergences** (BC-2.08.002, BC-2.09.001, BC-2.10.001, BC-2.10.006).

**Consequence:** POLICY 5 anchor-justification failure and POLICY 17 derived-table drift. The requirements-traceability matrix cannot be regenerated deterministically — `gen-rtm.py` reads the BC body row (`gen-rtm.py:13,138`), so the RTM will show R5 while prd.md shows R2c. R2c's coverage (the offline/online split) appears satisfied by BC-2.10.005 alone.

---

### P7-S4-015 — [process-gap] check-adr-consistency.py, the sole POLICY 19 hook, scans ONLY ADR files: 0 of 66 BC bodies, 0 prd-supplements [HIGH]

`check-adr-consistency.py:156`: `for adr_file in sorted(ADR_DIR.glob("ADR-*.md")):` where `ADR_DIR = SPECS / "architecture" / "decisions"` (`:28`). Its success line (`:170-173`) reads "Check passed: {adrs_checked} ADRs checked — all exit codes and reason codes consistent with error-taxonomy.md" — a positive-coverage assertion whose N counts **ADR files only**.

POLICY 19 is `closed_taxonomy_enforcement`, and the closed-set invariant at `error-taxonomy.md:97-104` binds "every verdict-producing event" — which lives in BC postconditions, BC test-vector tables, and test-vectors.md TV rows. None are in scope. Compounding it, the code-extraction regex `re.finditer(r"`([a-z][a-z0-9-]{3,})`", line)` (`:121`) requires **backtick delimiters**; `test-vectors.md:432`'s `broken (malformed-fragment)` is unbacktick'd, so even if the file were in scope the phantom code would not match.

This is why P7-S4-006 survived: the phantom `malformed-fragment` is doubly invisible — wrong directory *and* wrong delimiter.

**Predicate:** `Read` of `check-adr-consistency.py` in full (179 lines). Exactly one glob at `:156`, rooted at `ADR_DIR`. No reference to `BC_DIR` or `TEST_VECTORS` anywhere in the file.

**Consequence:** Every adversarial pass that treats POLICY 19 as lint-enforced is relying on a checker that has never inspected a single BC or test vector. Per D-057 this class must be treated as fully manual.

---

### P7-S4-016 — [process-gap] check-ec-injectivity.py performs neither description nor verdict comparison for the 2-column BC edge-case tables that all 9 in-scope bodies use [HIGH]

Two independent blind spots make the checker inert over this shard:

1. **BC-vs-registry description comparison is switched off by design.** `check-ec-injectivity.py:191-193`: "BC descriptions are expected paraphrases of TV descriptions (TV captures the canonical input-file name, not a scenario description), so **BC-vs-TV is skipped**." The collision loop at `:194` is gated on `if len(bc_occs) > 1` — only BC-vs-BC. This is precisely why P7-S4-003's 16 mismatches survive: each mismatch is BC-vs-TV, never BC-vs-BC.
2. **Verdict comparison never fires for 2-column tables.** `:220-222`: `if not bc_verdict_raw.strip(): continue  # BC row has no verdict column — skip verdict comparison`. `extract_ec_rows` (`:126-127`) sets `verdict_raw` from the *second* remaining cell. All 24 EC rows in the 9 in-scope bodies are 2-column `| EC | Description |` (`BC-2.08.001.md:59-64`, `BC-2.08.002.md:82-86`, `BC-2.08.003.md:57-61`, `BC-2.08.004.md:59-62`, `BC-2.09.001.md:56-62`, `BC-2.09.002.md:60-63`, `BC-2.10.001.md:65-69`, `BC-2.10.005.md:57-59`, `BC-2.10.006.md:57-59`) → `verdict_raw == ""` → `continue` on every row.

Its success line (`:258-261`) reports "Check passed: {total_ec_ids} EC IDs validated — all injective ({multi_occurrence} appear in multiple files but are consistent)" — the parenthetical asserts consistency that was never tested for these shapes.

Related: `check-id-resolution.py:20-23,441-452` documents its own limit — trap citations get an existence-only check, "Semantic correctness (whether the cited trap is topically relevant to the citing row) is **NOT** mechanically automatable" — which is why P7-S4-017 survives.

**Predicate:** `Read` of `check-ec-injectivity.py` in full (267 lines); `Grep "^\| (EC-…)"` established the 24 in-scope EC rows and their 2-column shape.

**Consequence:** The POLICY 16 EC-injectivity gate emits a green positive-coverage line while performing zero comparisons against the canonical registry for the shape that the entire BC corpus actually uses. Recommend: (a) enable BC-vs-TV description comparison with a token-overlap floor calibrated on URL-vocabulary pairs (see the 0.333 Jaccard in P7-S4-013), (b) log the count of rows for which verdict comparison was **skipped** as a separate non-zero metric, so an all-skipped run cannot present as covered.

---

### P7-S4-017 — Trap mis-citation: BC-2.10.001 cites T12 (case-sensitive filename); BC-2.09.001 cites T11 (empty fragment) [MEDIUM]

`test-vectors.md:289` declares the trap map "§8. Correctness Traps (T1–T16)". Authoritative labels:
- `:306` — "T12: **Case-sensitive filename** | TV-036 | covered — DI-002/D-006/KD-004: explicit case-sensitive `read_dir` comparison; macOS APFS false-pass eliminated"
- `:305` — "T11: **Empty fragment** | TV-068, TV-069 | covered"
- `:303` — "T9: **Percent-encoding order** | TV-053, TV-025 | covered"

`BC-2.10.001.md:91` (HEAD-then-GET Fallback Protocol) cites **T12** — a filesystem case-sensitivity trap with no relationship to HTTP method fallback. `BC-2.09.001.md:82` (External URL Syntax Validation) cites **T11** — an anchor-fragment trap owned by BC-2.08.001's `#` case. By contrast `BC-2.08.003.md:82` cites **T9** (percent-encoding order) and BC-2.08.003 *is* the "split before percent-decode" contract — correct. So the in-shard pattern is: the one topically-correct trap citation sits in SS-08 while both SS-09/SS-10 citations are wrong.

Note also that neither T11 nor T12 has any bearing on the HTTP fallback set; the actual grounding for DD-016 is `risks.md:38` (R-003) — not a T-trap at all.

**Consequence:** POLICY 4 semantic mis-anchoring. `check-id-resolution.py:441-452` accepts any T1..T16, so these will never be caught mechanically. A test-writer following BC-2.10.001's trap citation builds a case-sensitivity fixture for a HEAD/GET fallback contract.

---

### P7-S4-018 — Four of nine in-scope BCs have no `L2 Domain Invariants` Traceability row, and prd.md asserts DI-005 for two of them [MEDIUM]

`BC-2.09.001.md:77-83`, `BC-2.10.001.md:86-92`, `BC-2.10.005.md:71-77`, `BC-2.10.006.md:73-79` — each Traceability table jumps from `Capability Anchor Justification` straight to `Brief Requirement`; the `L2 Domain Invariants` row is absent (not "—", absent). The five others carry it: `BC-2.08.001.md:85`, `BC-2.08.002.md:110`, `BC-2.08.003.md:81`, `BC-2.08.004.md:81`, `BC-2.09.002.md:84`.

`prd.md:419` "L2 Invariants" column asserts a value for two of the four: `:460` BC-2.09.001 → `DI-005`; `:462` BC-2.10.001 → `DI-005`. So the derived table claims DI-005 coverage that the BC bodies do not carry — and `gen-rtm.py:138` reads `tr.get("L2 Domain Invariants", "—")`, so the RTM will silently substitute "—" and the DI-005 linkage vanishes.

**Predicate:** `Grep "Domain Invariants"` over `.factory/specs/behavioral-contracts` → 49 occurrences across **46** files (of 66 BC files); the four listed above are absent from the match list.

**Consequence:** POLICY 2 orphan risk. DI-005 ("exactly one verdict per link; `alive` is not a fourth verdict") is the invariant most at risk in SS-09/SS-10, and the two BCs prd.md nominates as its enforcers do not cite it. Also blocks POLICY 17 regeneration: prd.md and the RTM will disagree.

---

### P7-S4-019 — BC-2.10.006 cites AMB-090, which is unresolvable anywhere in the spec corpus [MEDIUM]

`BC-2.10.006.md:78`: `| Brief Requirement | R5, AMB-090 |`

**Predicate:** `Grep "\bAMB-(053|090)\b"` over `/Users/jmagady/Dev/mdlinkcheck-cloud/.factory` → AMB-053 resolves to `.factory/planning/brief-validation.md:278` and `:482`; **AMB-090 resolves to nothing** — its only non-review occurrence in the entire `.factory` tree is the citing line `BC-2.10.006.md:78` itself.

`check-id-resolution.py:8-26` enumerates the ID families it validates (CAP, DI, DD, BC, VP, ADR, NFR, EC, T, R, HS, POL). **AMB is not among them** — so no lint hook resolves AMB citations at all, in any file.

**Consequence:** A dangling anchor in the sole traceability field of a P0 BC (`prd.md:232`). The reader cannot determine what ambiguity BC-2.10.006 was authored to resolve. Since AMB-* live outside `.factory/specs`, adding AMB to `check-id-resolution.py` (or replacing the citation with the correct in-corpus reference — `D-011` per `BC-2.10.006.md:23,50,54`) is required.

---

### P7-S4-020 — BC-2.10.001 PC1 gives HEAD its own 10-second timeout, contradicting its own Invariant 2 (10 s is per-URL total) [MEDIUM]

`BC-2.10.001.md:50` PC1: "HEAD request is sent **with 10-second timeout**."
`BC-2.10.001.md:61` Invariant 2: "10-second timeout applies **per-URL total (not per-request)**."

Under PC1, HEAD gets 10 s and the PC3 GET fallback gets its own budget → 20 s per URL, breaking Invariant 2. Corroborating authorities take Invariant 2's side: `capabilities.md:170` (CAP-010) "10-second per-URL **total** timeout, 2 retries with backoff"; `BC-2.10.002.md:101` PC12 "no response within the **fixed 10-second per-URL window** per BC-2.10.003".

Related silence: CAP-010's "2 retries with backoff for transient failures" (`capabilities.md:170-171`) appears nowhere in BC-2.10.001, which is the BC that owns the request-attempt protocol — so the interaction between 2 retries, HEAD, GET fallback and one shared 10 s budget is unspecified.

**Consequence:** Worst-case wall-clock per URL is either 10 s or 20 s+ depending on which sentence the implementer follows. With `--online` over a large corpus this is the difference between meeting and blowing the R8 budget, and BC-2.10.003's timeout tests will disagree with BC-2.10.001's implementation.

---

### P7-S4-021 — BC-2.09.002's enumeration of what BC-2.11.002 specifies omits the raw-string fallback, and its Invariant 1 states only the normalized path [MEDIUM]

`BC-2.09.002.md:38-40`: "Read that BC for the full **normalize-then-prefix-match algorithm, component-boundary safety rule, and multiple-flag semantics**."
`BC-2.09.002.md:56-57` Invariant 1: "The matching algorithm (**normalize-then-prefix-match with component-boundary check**) is specified exclusively in BC-2.11.002."

CAP-011 (`capabilities.md:190-197`) specifies **three** steps, the third of which is the WHATWG-fail raw-string fallback, and states the boundary rule is "mandatory in **both** the normalized and raw-string paths". `BC-2.11.002.md:25` confirms the fallback is part of that contract ("D-019/P2-M08 — added WHATWG-fail fallback to raw-string prefix match at component boundary for malformed URLs").

A pointer BC that enumerates the delegated contents must enumerate them completely, or the reader who trusts the pointer's summary (and skips BC-2.11.002) implements only the normalized path. This is the reader-side companion to P7-S4-005 and P7-S4-007.

**Consequence:** MEDIUM rather than higher because BC-2.11.002 is correctly named as canonical; but combined with VP-010's "never raw byte prefixes" (P7-S4-005), an implementer has two in-scope documents both describing a one-path algorithm and only `capabilities.md` describing two.

---

### P7-S4-022 — BC-2.09.001 and BC-2.10.001 carry version numbers with no corresponding `modified:` changelog entry [MEDIUM]

`BC-2.09.001.md:4` `version: "1.3"`; the newest entry in `modified:` is `"v1.2: (WS-4/Shard-C) POLICY-5 citation repair…"` (`:23`), followed by `v1.1` (`:24`). No v1.3 entry exists.

`BC-2.10.001.md:4` `version: "1.5"`; `modified:` entries run v1.1 (`:23`) through v1.4 (`:26`). No v1.5 entry exists.

Both files bear a `phase: 1a` / `input-hash: "07d983a"` frontmatter identical to their siblings, so the bump was a content edit, not a mechanical re-stamp.

**Predicate:** magnitude across the shard not established by predicate; the two sites above were established by full reads of both files (version field line 4 vs. maximum `modified:` version).

**Consequence:** POLICY 1 audit-trail gap. Whatever change bumped BC-2.09.001 to 1.3 and BC-2.10.001 to 1.5 is unrecorded, so a future pass cannot tell whether the offline-only scoping (P7-S4-001) or the T12 trap citation (P7-S4-017) was introduced or *deliberately reaffirmed* by that edit. This blocks the partial-fix regression axis for exactly the two BCs carrying the shard's most severe findings.

---

### P7-S4-023 — VP-007, the sole verification vehicle for BC-2.10.005 and BC-2.10.006, leaves the dns/tls error encoding "TBD by implementer" [MEDIUM]

`BC-2.10.005.md:69` and `BC-2.10.006.md:71` each list exactly one VP row: `VP-007 | … | kani (P0)`. VP-INDEX (`:63`, `:226-227`) confirms VP-007 is their only assignment.

`vp-007:126-130`:
> "dns-failure and tls-error are encoded as sentinel status values (implementation detail: e.g. status=0 + attempt=DnsFailure variant, or via a dedicated HttpAttempt variant — **exact encoding TBD by implementer**)."

and `:166-172`: "The exact API signature for network-error verdicts (dns-failure, tls-error, timeout) depends on whether the implementation uses a combined `(u16, HttpAttempt)` type … or a separate `classify_error(HttpError) -> Verdict`. **The harness above assumes the latter.** If the implementer uses the former, the harness must be adapted."

The harness body calls `classify_response_with_error(HttpError::DnsFailure)` (`:133`) — a function name that appears nowhere in an interface document.

**Consequence:** A P0 Kani harness that does not compile against a determined API cannot be locked (`vp-007:189-191` — "Proof harness committed | — ", "Locked (VERIFIED) | — "). Both BC-2.10.005 and BC-2.10.006 stake 100% of their verification on it, and the harness explicitly authorises the implementer to reshape the API such that the harness must be rewritten — at which point the "kani (P0)" claim in both BC bodies is aspirational, not verified. Note this is the same VP whose "ALWAYS broken" assertion BC-2.10.005 Invariant 2 undermines (P7-S4-010).

---

### P7-S4-024 — prd.md's derived "Test Type" column contradicts the BC bodies' VP proof methods for 4 of the 9 in-scope BCs [MEDIUM]

`prd.md:419` header: `| BC ID | Source (L2 CAP) | L2 Invariants | Brief Req | Priority | Test Type |`

| BC | prd.md Test Type | BC body VP proof methods | VP-INDEX |
|----|------------------|--------------------------|----------|
| BC-2.08.001 | `unit` (`prd.md:456`) | integration, integration, proptest (`BC-2.08.001.md:76-78`) | VP-015 integration, VP-025 proptest (`VP-INDEX.md:71,81`) |
| BC-2.08.003 | `unit/property` (`prd.md:458`) | kani, fuzz (`BC-2.08.003.md:73-74`) | VP-004 kani, VP-013 fuzz (`VP-INDEX.md:60,69`) |
| BC-2.10.005 | `integration` (`prd.md:466`) | kani (P0) (`BC-2.10.005.md:69`) | VP-007 kani P0 (`VP-INDEX.md:63`) |
| BC-2.10.006 | `integration` (`prd.md:467`) | kani (P0) (`BC-2.10.006.md:71`) | VP-007 kani P0 (`VP-INDEX.md:63`) |

Agreeing rows: BC-2.08.002 `unit/integration` vs integration+proptest (partial), BC-2.08.004 `integration` ✓, BC-2.09.001 `unit` ✓ (test-sufficient/unit test), BC-2.09.002 `unit` vs proptest (drift), BC-2.10.001 `integration` vs "unit test with mock HTTP".

**Predicate:** `Grep "BC-2\.0(8|9)\.00[1-4]|BC-2\.10\.00[156]"` over `prd.md` → rows `:456`-`:467`; header established by `Read prd.md:418-431`. Joined against the VP tables read in full in the 9 bodies and `VP-INDEX.md` lines 57-82. **4 of 9** hard contradictions (kani-vs-unit / kani-vs-integration).

**Consequence:** POLICY 17 derived-table drift. Test-planning off prd.md schedules integration tests for BC-2.10.005/006 whose actual obligation is a Kani P0 proof (the highest-cost, longest-lead verification in the plan) and schedules only unit tests for BC-2.08.003 whose obligation is a Kani proof plus a fuzz target. The two highest-cost verification commitments in SS-10 are invisible in the planning view.

---

### P7-S4-025 — BC-2.08.003's canonical test-vector table puts a post-decode value in the "Path Component" column, contradicting its own PC4 [LOW]

`BC-2.08.003.md:49` PC4: "`%23` in the path component is **left as-is until percent-decoding** (where it becomes `#`)."
`BC-2.08.003.md:64-67`:
```
| Destination | Path Component | Fragment |
| `a%23b.md`  | `a#b.md` (after decode) | none |
```
The column is labelled "Path Component" — which per PC4 is `a%23b.md` at the point the fragment split produces it — but the cell holds the post-decode string, annotated in-cell. The other two rows (`docs/a.md#intro`, `a.md##double`) are pre-decode values, so the column mixes two representations.

**Consequence:** Cosmetic; a test-writer asserting on the split function's return value would compare against `a#b.md` and fail, but the parenthetical is enough to recover. Cleanest fix is a fourth column (`Path Component (raw)` / `Path Component (decoded)`).

---

## Coverage notes and disclosures

**Reviewed in full:** all 9 in-scope BC bodies (frontmatter, every precondition, postcondition, invariant, edge-case row, canonical-test-vector row, VP row, Traceability row, Related-BCs row). Every VP cited by those 9 bodies was joined against both `VP-INDEX.md` and the individual VP body: VP-004, VP-007, VP-010, VP-013 (VP-INDEX row only), VP-015, VP-016, VP-025, plus both `test-sufficient` sentinels (BC-2.09.001, BC-2.10.001 — both confirmed against `VP-INDEX.md:215,222`). Every `L2 Capability`/`Capability Anchor Justification` quoted excerpt in the 9 bodies was verified verbatim against `capabilities.md`: CAP-008 `:139`, CAP-009 `:155`, CAP-010 `:167` — **all three quoted section titles are verbatim-correct**; the WS-4/Shard-C POLICY-5 repairs recorded in the frontmatter changelogs did land, and no fabricated quotation was found in this shard. The `sub_reason` field for `private-ip`/`https-downgrade` is correctly carried in the JSON schema (`interface-definitions.md:194`, `:198`) — no defect. `ADR-007`'s H1 is "Two-Layer Verdict Model" (`ADR-007-three-verdict-model.md:12`), so the `(two-layer verdict model)` glosses in `BC-2.08.001.md:87`, `BC-2.08.002.md:112`, `BC-2.08.004.md:83` are correct (the stale token is the filename, not the BCs). `bc-module-map.md:206,227,228,239` corroborates every Architecture Module row in this shard — no POLICY 6 defect found.

**VP-013 body not read** (only its VP-INDEX row at `:69`) — the BC-2.08.003 fuzz claim is joined at index level only.

**Not reviewed** (other shards): the seven remaining SS-10 bodies, all of SS-01..SS-07 and SS-11..SS-14. Findings whose primary subject is `test-vectors.md`, `prd.md` or a VP body are reported here only where an in-scope BC row is the load-bearing citation.

**Incidental exposure disclosure:** one broad predicate (`Grep "\bAMB-(053|090)\b"` scoped to `.factory` rather than `.factory/specs`) returned two path+title lines from prior review artifacts under `.factory/cycles/phase-1d/`. I did **not** open those files and no prior-pass content informed any finding above; every finding was derived independently from the primary artifacts. The exposure indicates P7-S4-019 (AMB-090) is likely non-novel; it is retained because it is a real unresolved defect. All subsequent predicates were re-scoped to `.factory/specs`.