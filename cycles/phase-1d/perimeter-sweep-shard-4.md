---
document_type: adversarial-findings
level: ops
version: "1.0"
status: final
producer: adversary
timestamp: 2026-08-07T03:00:00Z
cycle: phase-1d
shard: 4
frozen_head: 1d3ed17
scope: "SS-08 (4) + SS-09 (2) + BC-2.10.001/005/006 = 9 BC bodies read in full"
counts:
  critical: 7
  high: 8
  medium: 13
  low: 4
  total: 32
verdict: "DI-005 is NOT airtight — breached in four independent places in this shard alone"
inputs:
  - .factory/specs/behavioral-contracts/ss-08/
  - .factory/specs/behavioral-contracts/ss-09/
  - .factory/specs/behavioral-contracts/ss-10/BC-2.10.001.md
  - .factory/specs/behavioral-contracts/ss-10/BC-2.10.005.md
  - .factory/specs/behavioral-contracts/ss-10/BC-2.10.006.md
traces_to: cycles/phase-1d/perimeter-sweep-synthesis.md
project: mdlinkcheck-cloud
---

# Adversarial Findings — Perimeter Sweep Shard 4

**Scope:** SS-08 (4 BC bodies) + SS-09 (2 BC bodies) + BC-2.10.001/005/006 = 9 BC bodies read in full
**Frozen HEAD:** `1d3ed17`
**Finding counts:** 7 CRITICAL / 8 HIGH / 13 MEDIUM / 4 LOW = **32 findings**
**Verdict:** DI-005 is NOT airtight — breached in four independent places in this shard alone

---

## CRITICAL

### P6-S4-001 — Fragment percent-decoding contradiction

BC-2.08.001.md:46,:55 and BC-2.07.004.md:49 say the fragment is used VERBATIM (not decoded), contradicting CAP-008 (capabilities.md:139 "percent-decode the fragment before comparison"), DI-003 (invariants.md:101-103 "each component is percent-decoded independently") and CAP-007 (:130); BC-2.07.004.md:79 even quotes CAP-007 correctly in the same table it contradicts. `[Café](#caf%C3%A9)` vs `## Café` yields a false anchor-not-found. DI-003's decode clause has NO enforcing postcondition anywhere in SS-08.

### P6-S4-002 — Nine mis-anchored EC citations across 4 BCs

Nine EC citations in four BCs all resolve and all are non-colliding, so both skip-listed checkers pass, yet every cited EC is misaligned with its canonical row: BC-2.08.001 EC-061 (canonical = no-space-after-# not a heading), EC-062 (canonical = `<a name>` carve-out, CLEAN not broken); BC-2.08.002 EC-063 (canonical = `<h2 id>` carve-out), EC-064 (canonical = `{#custom}`, CLEAN); BC-2.09.001 EC-077 (canonical = HEAD 200 online), EC-078 (canonical = 405→GET 200, CLEAN not malformed-url); BC-2.10.001 EC-080 (canonical = 501→GET), EC-085 (canonical = 12-hop redirect → too-many-redirects), EC-086 (canonical = 301 downgrade → INDETERMINATE). All three of BC-2.08.002's and all three of BC-2.10.001's ECs are defective; in four cases the verdict CLASS inverts. Root cause: the v1.2/v1.5/v1.7 EC-collision passes only remapped IDs the INJECTIVITY checker flagged; nothing ever verified that RETAINED IDs match their canonical rows.

### P6-S4-003 — BC-2.09.001 scopes URL syntax validation to OFFLINE ONLY

BC-2.09.001.md:41,:47,:52 scopes URL syntax validation to OFFLINE ONLY, contradicting CAP-009 (capabilities.md:156-157 "applied in BOTH offline and online mode") and DD-010 (decisions.md:88). BC-2.10.001.md:51 then makes "syntactically valid (BC-2.09.001)" a PRECONDITION of the online path — which nothing establishes — so a malformed URL under --online falls between both BCs and gets NO VERDICT. Its Traceability at :79 also fabricates a CAP-009 quote that inverts the emphasis, which is what makes the offline-only precondition look sanctioned.

### P6-S4-004 — Empty fragment gets two contradictory verdicts from one postcondition set

BC-2.08.001.md:49 PC4 (not found → broken) and :50 PC5 (bare `#` → clean) both fire on `[x](#)`; identical at BC-2.08.002.md:65 vs :68. capabilities.md:142 shows the intent is a GUARD that PRECEDES the lookup ("pass empty fragments without check", DEC-007); the BCs express it as a peer postcondition.

### P6-S4-005 — DNS failure has two contradictory successors

BC-2.10.001.md:37-39,:51 invents a DNS-level trigger for GET fallback and attributes it to DD-016, but decisions.md:94 DD-016 lists only {400,403,404,405,501,999} plus connection reset/closed. BC-2.10.005.md:46-47 and BC-2.10.002.md:101-102 terminate immediately as `broken(dns-failure)`. Retrying GET after NXDOMAIN is also incoherent, and under the GET branch the URL lands in PC4-PC7 which have no DNS case → unverdicted.

### P6-S4-006 — Entire hermetic --online strategy is unexecutable

BC-2.10.010.md:43-44,:56-61 blocks 127.0.0.0/8 and ::1/128 BEFORE any request with no test carve-out, while dtu-assessment.md:230,:260-262 builds every fixture on 127.0.0.1. Kills all five BC-2.10.001 vectors, all three BC-2.10.006 TLS vectors, BC-2.10.005's sole vector, the 11-row Phase-3 coverage table, and the DTU_REQUIRED:false conclusion resting on it. Worst-case outcome: an implementer "fixes" it by weakening the private-IP guard, silently removing the SSRF protection. CORROBORATES pass-5 P5-001.

### P6-S4-007 — BC-2.10.001 response classification is NON-TOTAL with no catch-all

BC-2.10.001's response classification has no catch-all and NO reference to BC-2.10.002 (it has no Related BCs section at all). Unmapped → no verdict: GET returning 999 (a code in its OWN trigger set); HEAD returning 410/401/429/5xx-other-than-501/402/406-409/411-499; HEAD timeout (PC7 covers only GET timeouts); 1xx; 0..99; 600..65535. VP-007 is a Kani totality proof over all 65,536 u16 values, so the implementation must be total while the spec is not — each gap is an implementer coin-flip.

---

## HIGH

### P6-S4-008 — Phantom reason code `malformed-fragment` at TV-197

test-vectors.md:432 (TV-197) asserts `malformed-fragment`, a code not in the 13-code set and nowhere else in `.factory/`; its named owner BC-2.08.003.md:53,:67 says double-`#` is WELL-FORMED (fragment `#double`), so the vector asserts a different failure mode with an unemittable code.

### P6-S4-009 — BC-2.10.005 DNS fixture performs no DNS

BC-2.10.005's prescribed DNS fixture 127.0.0.255 performs NO DNS (literal IP → connection-refused → indeterminate per BC-2.10.002 PC15) AND is inside 127.0.0.0/8 (private-ip short-circuit); the alternative at BC-2.10.005.md:58 uses a real domain, contradicting the hermetic requirement at dtu-assessment.md:43,:273. `dns-failure` therefore has no valid EC, no executable fixture, and no correct proof method.

### P6-S4-010 — Connection reset/refused has three specified behaviours and no owner

BC-2.10.002.md:106-107 PC15 says terminal indeterminate "see BC-2.10.006", BC-2.10.006 is exclusively about TLS and never mentions it, error-taxonomy.md:161 routes it back to BC-2.10.002, and BC-2.10.001.md:51 makes it trigger a GET retry.

### P6-S4-011 — Proof-method contradictions in 7 of 9 BCs

VP-007 described as "unit test with mock DNS resolver"/"mock TLS server" where VP-INDEX says kani P0 over a PURE function — a Kani harness cannot host a mock; VP-004 kani→unit; VP-013 fuzz→unit; VP-015 integration→unit; VP-010 proptest→unit; VP-025 proptest→Kani. BC-2.10.002.md:25 records "P2-M15 corrected VP-007 proof method to kani" — landed in one file, never propagated to the two siblings.

### P6-S4-012 — VP-015 mis-anchored in BC-2.08.001

BC-2.08.001.md:75-76 anchors VP-015 to "anchor-only links resolved in same-file table" and "case mismatch → anchor-not-found"; VP-015 is the two-pass anchor-table-COMPLETENESS integration property (DI-008). A developer writes two unit tests, marks VP-015 discharged, and the Pass-1.5 completeness test (mitigation for trap T15) is never written.

### P6-S4-013 — R5 mis-citations in 5 BCs and T-map mis-citations in 2

T11 "empty fragment" on an external-URL-syntax BC; T12 "case-sensitive filename" on the HEAD/GET fallback BC. In-scope siblings BC-2.08.002.md:110 and BC-2.10.005.md:75 cite correctly, so the fix reached 2 of 7.

### P6-S4-014 — BC-2.08.002 specifies PCs for inputs its own preconditions exclude

BC-2.08.002 specifies PCs, an EC, and two vectors for inputs its own Precondition 1 and Invariant 4 EXCLUDE (directory and non-.md targets), and the vector rows themselves say "not this BC"; the EC-collision remediation then assigned EC-072 canonical ownership to the BC that disclaims it.

### P6-S4-015 — BC-2.10.005 makes broken/indeterminate verdict "implementer judgement"

BC-2.10.005.md:53 Invariant 2 makes a broken/indeterminate verdict "implementer judgement", so one build exits 1 and another exits 0 on the same corpus — the exit code stops being a function of the input.

---

## MEDIUM

### P6-S4-016 — DD-016's 429-GET-fallback clause contradicted by both SS-10 BCs
decisions.md:94 DD-016 429-GET-fallback clause contradicted by BC-2.10.001 and BC-2.10.002; landed nowhere.

### P6-S4-017 — BC-2.10.001 PC1 contradicts Invariant 2
BC-2.10.001 PC1 (10s per HEAD) contradicts its own Invariant 2 (10s per-URL TOTAL), leaving GET zero budget and PC7 unreachable.

### P6-S4-018 — Four of nine BCs omit L2 Domain Invariants row; DI-005 cited by NO BC in SS-08/09/10 liveness path

### P6-S4-019 — CAP-010 "2 retries with backoff" has no postcondition in any BC

### P6-S4-020 — BC-2.08.002.md:107 quotes CAP-008 as "built in Pass 1", contradicting its own :47-49,:72-73 ("guaranteed by Pass 1.5")

### P6-S4-021 — BC-2.10.002.md:173 names BC-2.10.003 as the HEAD→GET owner (it is the timeout BC)
owner is BC-2.10.001, absent from Related BCs entirely; :25 claims "P2-m06 fixed Related BCs swap" — same class at BC-2.10.010.md:100.

### P6-S4-022 — BC-2.08.004.md:4 version 1.2 with v1.5 changelog entry listed BEFORE v1.1/v1.2 — non-monotonic

### P6-S4-023 — BC-2.08.004.md:81 anchors to DD-008 which invariants.md:197 records as SUPERSEDED

### P6-S4-024 — BC-2.08.002.md:37-39 conflates filesystem case (DI-002) with fragment-string case, inviting a whole-destination case-fold

### P6-S4-025 — AMB-053's second half ("flag as a likely-typo reason") has no code in the 13-code set and no BC implements it

### P6-S4-026 — BC-2.09.001.md:73-74 and BC-2.10.001.md:82-83 have ZERO real VP ids (all `—`)
Two verdict-producing BCs including the HEAD/GET protocol have no VP coverage at all.

### P6-S4-027 — BC-2.10.006.md:77 cites AMB-090 which exists nowhere in .factory/

---

## LOW

### P6-S4-028 — BC-2.09.002 is mis-filed
Subsystem SS-09 but primary module filter.rs (SS-11), spec owned by BC-2.11.002, sole VP owned by SS-11 tests.

### P6-S4-029 — BC-2.09.002.md:68 Expected column reads "normal SS-09 validation" — a process, not a verdict

### P6-S4-030 — BC-2.10.006.md:63,:65 vectors have no EC ids; BC-2.08.001.md:62 EC-062 has no row in the BC's own vector table; VP-015 listed twice at :75-76

### P6-S4-031 — BC-2.08.003.md:33,:45 defines "unescaped" as only "not %23", leaving backslash escaping and angle-bracket destinations unspecified

### P6-S4-032 — decisions.md:90 DD-012 still carries the 3-field sort key
(The step NUMBERING was verified internally consistent — earlier suspicion not borne out.)
