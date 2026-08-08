---
document_type: adversarial-review
level: ops
version: "1.0"
status: final
producer: adversary
timestamp: 2026-08-08T00:00:00Z
cycle: phase-1d
pass: 7
shard: 5
frozen_develop_head: f8ee4eb024b8b4a300139ef803d248e8fe40f2fc
frozen_specs_tree: ace1745871122cd1fa2c46cf27c5493cc1083411
frozen_spec_lint_tree: f2392b456c3bd669e3efbe86b3e6eae62e302ed1
severity_vocabulary: "CRITICAL/HIGH/MEDIUM/LOW (single vocabulary per PG-012 ruling)"
findings_total_self_declared: 30
heading_level_variance: "shard 5 used ## for finding headings where other shards used ###; parse regex must tolerate both"
inputs: []
input-hash: "ace1745"
traces_to: STATE.md
---
# Pass 7 — Shard 5: SS-11 + SS-12 + SS-13 + SS-14 (15 BC bodies)

```
scope: "SS-11 (4) + SS-12 (5) + SS-13 (2) + SS-14 (4) = 15 bodies read in full"
files_read_in_full:
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-11/BC-2.11.001.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-11/BC-2.11.002.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-11/BC-2.11.003.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-11/BC-2.11.004.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-12/BC-2.12.001.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-12/BC-2.12.002.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-12/BC-2.12.003.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-12/BC-2.12.004.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-12/BC-2.12.005.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-13/BC-2.13.001.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-13/BC-2.13.002.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-14/BC-2.14.001.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-14/BC-2.14.002.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-14/BC-2.14.003.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-14/BC-2.14.004.md
reference_files_read_in_full:
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/product-brief.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/capabilities.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/domain-spec/invariants.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/prd-supplements/interface-definitions.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/prd-supplements/error-taxonomy.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/prd-supplements/nfr-catalog.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/VP-INDEX.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-005-exit-code-io-error.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-006-exit-code-clean.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-010-allow-component-boundary.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-011-sort-deterministic.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-016-ignored-files-anchor-targets.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/verification-properties/vp-021-no-undefined-reason-codes.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-09/BC-2.09.001.md
  - /Users/jmagady/Dev/mdlinkcheck-cloud/scripts/spec-lint/check-ec-injectivity.py
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/prd-supplements/test-vectors.md (§6, §10, lines 150-160, 220-290, 351-476)
  - /Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/BC-INDEX.md (BC-2.1x rows, DI table, R-map)
findings_total: 30
severity_counts: CRITICAL 7 / HIGH 10 / MEDIUM 11 / LOW 2
verdict: NOT CLEAN — the shard's edge-case ID layer is systematically de-anchored from the canonical EC registry (19 of 36 EC rows resolve to a different scenario, one of them an outright exit-0-vs-exit-2 contradiction), the JSON contract cannot carry a field the corpus requires, four VP-table rows claim coverage their VP bodies do not assert, and BC-2.11.001 PC4 states the exact opposite of the --ignore-wins rule the sibling BC exists to specify.
```

---

## EXIT-CODE DOMAIN TABLE

Model: `verdict::exit_code(findings, io_errors, config_error) -> u8`. `config_error` has exactly one trigger (invalid `--ignore` glob) per BC-2.14.001:48, BC-2.14.002:51, BC-2.14.003:46, capabilities.md:249-250.

| broken? | indeterminate? | I/O error? | files discovered? | exit code per spec | source file:line | defined? |
|---|---|---|---|---|---|---|
| no | no | no | yes (>0) | 0 | BC-2.14.001:51 PC1; capabilities.md:238 | YES |
| no | no | no | no (0 files) | 0 | BC-2.14.001:58 Inv3 (EC-184); BC-2.14.001:73 CTV | YES |
| no | yes | no | yes | 0 | BC-2.14.001:52 PC2, :57 Inv2 | YES |
| yes | no | no | yes | 1 | BC-2.14.003:49 PC1; BC-2.14.002:44 | YES |
| yes | yes | no | yes | 1 | BC-2.14.003:53-54 Inv1; BC-2.14.002:61 Inv3 | YES |
| no | no | yes | yes | 2 | BC-2.14.002:73 CTV row 3; :44 | YES |
| no | yes | yes | yes | 2 | BC-2.14.002:61 Inv3 (io_errors non-empty → 2) | YES |
| yes | no | yes | yes | 2 | BC-2.14.002:59 Inv1 (DI-011); :71 CTV row 1 | YES |
| yes | yes | yes | yes | 2 | BC-2.14.002:61 Inv3 | YES |
| no | no | yes (nonexistent PATH) | partially | 2 | BC-2.14.002:51 PC2; :75 CTV row 5; interface-definitions.md:237 | YES |
| yes | any | yes (nonexistent PATH) | partially | 2 | BC-2.14.002:75 CTV row 5 | YES |
| n/a (no scan) | n/a | n/a | n/a — traversal never starts | 2 (`config_error=true`, invalid `--ignore` glob) | BC-2.11.004:52 PC1; BC-2.14.002:51 | YES |
| n/a | n/a | n/a | n/a — clap intercepts | 0 (`--help` / `--version`) | BC-2.14.004:48-49; interface-definitions.md:85 | YES |
| n/a (PATH also present) | n/a | n/a | n/a | 0 (`--version` wins over PATH) | BC-2.14.004:65 EC-213 | YES |
| n/a (no scan) | n/a | n/a | n/a | 2 (invalid `--format` **value**) | BC-2.12.004:47 PC3; interface-definitions.md:87 | YES — but NOT via `verdict::exit_code`; no SS-14 BC owns it (BC-2.14.002:51, BC-2.14.003:46 explicitly scope-exclude it) |
| n/a (no scan) | n/a | n/a | n/a | 2 (**unrecognized flag**, e.g. `--bogus`) | ONLY interface-definitions.md:238; TV-137 test-vectors.md:251 | **BC-ORPHAN** — no BC assigns it; all three SS-14 BCs explicitly exclude it (see P7-S5-016) |
| any | any | any | any | 2 (**"internal unexpected error"**) | ONLY interface-definitions.md:87 | **NO** — unrepresentable in the 3-input model; no BC; Rust default panic exit is 101, contradicting interface-definitions.md:91 "No other exit codes are produced" (see P7-S5-016) |
| partial | any | any | partial | 2 (**SIGINT during scan**) | ONLY test-vectors.md:260 (TV-146) | **NO** — unrepresentable in the 3-input model; no BC; prd.md:632 records that SIGINT/panic sentences were *deleted* from interface-definitions §3, yet TV-146 still asserts exit 2 (see P7-S5-016) |
| no | no | no | yes, but empty PATH set given (`mdlinkcheck` with no args) | 0 (default PATH = `.`) | product-brief.md:35 (R1); interface-definitions.md:33 | YES |

Precedence between exit 1 and exit 2 IS stated (BC-2.14.002:59 Inv1, :61 Inv3; DI-011 invariants.md:278-285; interface-definitions.md:89). No doubly-assigned combination among the eleven states the 3-input model can express. The three unassigned/orphan states are consolidated in P7-S5-016.

---

## P7-S5-001 — BC-2.11.001 PC4 states the exact opposite of the `--ignore`-wins rule, in the same sentence as the note that cites it [CRITICAL]

`/Users/jmagady/Dev/mdlinkcheck-cloud/.factory/specs/behavioral-contracts/ss-11/BC-2.11.001.md:51`:

```
4. `--ignore` does NOT affect files passed as explicit PATH arguments. [AMB-108: --ignore wins over explicit PATH per interface-definitions.md §8]
```

The normative clause and its own bracketed justification assert opposite behaviours. The bracketed note is correct; the postcondition is wrong. Authoritative sources:
- `interface-definitions.md:234` — "`--ignore GLOB` on an explicitly-passed PATH | `--ignore` wins — the file is excluded as a link source even if passed explicitly (BC-2.11.003)"
- `BC-2.11.003.md:52` — "`--ignore` wins over explicit PATH. Always."
- `BC-2.11.003.md:66` CTV — `mdlinkcheck vendor/lib.md --ignore 'vendor/**'` → "Exit 0; no findings"

BC-2.11.001 is the P0 canonical `--ignore` contract (BC-INDEX.md:153). An implementer building `filter.rs` from its Postconditions section will special-case explicit PATH arguments out of glob filtering — inverting BC-2.11.003 entirely and turning `mdlinkcheck vendor/lib.md --ignore 'vendor/**'` from exit 0 into exit 1.

**Predicate:** `Grep '\-\-ignore.*explicit' .factory/specs/behavioral-contracts` — BC-2.11.001:51 is the single site asserting the negative; BC-2.11.003:38, :45-46, :52 and interface-definitions.md:234 all assert the positive (4 sites vs 1).
**Consequence:** Two P0 BCs in the same subsystem specify mutually exclusive behaviour for the same input. Whichever an implementer reads first determines the product behaviour; the acceptance test derived from the other BC fails.

---

## P7-S5-002 — 19 of 36 edge-case IDs in this shard resolve to a *different scenario* in the canonical EC registry; EC-142 is a direct exit-0-vs-exit-2 contradiction [CRITICAL]

`test-vectors.md` is the canonical EC registry (`check-ec-injectivity.py:9` — "The canonical EC registry is test-vectors.md"). §6 (`test-vectors.md:232`, "Flags, Output, Exit Codes (R5, R6, R7) — EC-124 through EC-148") owns exactly the ID band that SS-12/SS-13/SS-14 cite. The bands are systematically de-anchored:

| EC | Registry scenario (test-vectors.md) | This shard's scenario |
|---|---|---|
| EC-071 | `:156` `[x](#setup )` trailing space in fragment trimmed → clean | BC-2.11.001:67 `--ignore 'vendor/**'` excludes all files under `vendor/` |
| EC-124 | `:236` `--ignore 'docs/**'` → exit 0, no findings | BC-2.12.001:60 "Multiple findings in same file" |
| EC-126 | `:239` `README.md --ignore README.md` → exit 0 | BC-2.12.002:60 "Piped stdout without CLICOLOR_FORCE" |
| EC-127 | `:240` `--ignore a.md --ignore b.md` → exit 0 | BC-2.12.002:61 "NO_COLOR=1 set" |
| EC-128 | `:241` `--ignore '!keep.md'` → exit 1 | BC-2.12.002:62 "CLICOLOR_FORCE=1" |
| EC-130 | `:243` `--allow example.com` (no scheme) → exit 1 broken | BC-2.12.003:62 "3 broken links in 2 files" |
| EC-131 | `:244` `--allow https://example.com` offline → exit 0 | BC-2.12.003:63 "0 broken, 2 indeterminate" |
| EC-132 | `:245` `--format xml` → exit 2 usage error | BC-2.12.003:64 "0 broken, 0 indeterminate" |
| EC-134 | `:247` one of each offline reason code, `--format json` → exit 1, 6 entries | BC-2.12.004:57 "`--format text`" |
| EC-135 | `:249` broken link + diagnostic → stdout pure JSON | BC-2.12.004:58 "`--format xml`" |
| EC-136 | `:250` `--format json --format text` → last wins | BC-2.12.004:59 "`--format TEXT` (uppercase)" |
| EC-137 | `:251` `--unknown-flag` → exit 2 | BC-2.12.004:60 "`--format json --format text`" |
| EC-138 | `:252` `--help` → exit 0, help on stdout | BC-2.13.001:75 "No findings, no errors" |
| EC-139 | `:254` `-- -weird-name.md` | BC-2.13.001:76 "JSON piped to file" |
| EC-140 | `:255` `docs --format json` → exit 1 | BC-2.13.001:77 "Mixed broken + indeterminate findings" |
| **EC-142** | **`:256` "Only an unreadable file" → exit 2** | **BC-2.14.001:64 "Scan with 0 findings" → exit 0** |
| EC-144 | `:258` broken link, piped → no ANSI codes | BC-2.14.003:61 "1 broken link, 0 I/O errors" |
| EC-145 | `:259` broken link, `NO_COLOR=1` → no ANSI codes | BC-2.14.003:62 "100 broken links, 0 I/O errors" |
| EC-146 | `:260` long-running scan, SIGINT sent → exit 2, partial output | BC-2.14.003:63 "0 broken links, 1 indeterminate" |

EC-142 is the worst: BC-2.14.001 (the exit-**0** contract) claims an EC ID the registry assigns to "only an unreadable file → exit **2**". A test-writer resolving EC-142 from either direction builds a fixture that the other document declares wrong.

EC-071 is a partial-fix survivor: BC-2.11.001 v1.2 (`:27`) remapped EC-072→EC-192 and EC-073→EC-193 for exactly this collision class, but left the third row of the same three-row table (EC-071) pointing at TV-071.

**Predicate:** `Grep -c '^\| EC-\d' --glob '*BC-2.1[1-4]*' .factory/specs/behavioral-contracts` → 36 rows across 15 files. Cross-joined against `test-vectors.md` rows for the same IDs (greps: `EC-071`, `EC-12[4678]|EC-13[0-9]|EC-14[0-6]|EC-170`, `EC-19[23]|EC-20[789]|EC-21[0-3]|EC-16[19]|EC-18[4]`): 19 IDs mismatched, 16 consistent, 1 unregistered (EC-073b, see P7-S5-019). 19+16+1 = 36.
**Consequence:** The edge-case layer of four subsystems is unusable for test derivation. Phase-3 test-writers working from BC bodies and Phase-3 test-writers working from test-vectors.md will produce contradictory fixtures. POLICY 1 (append_only_numbering) and POLICY 16 (bc_traceability_id_resolution) are both violated at scale.

---

## P7-S5-003 — BC-2.13.001 defines the JSON finding object as exactly six fields; `sub_reason` becomes unemittable, breaking BC-2.10.002 [CRITICAL]

`BC-2.13.001.md:49-50` PC2: "Each finding object in `results` has fields in this order: `file`, `line`, `column`, `link_target`, `verdict`, `reason`." No mention of `sub_reason` anywhere in BC-2.13.001 or BC-2.13.002.

The corpus requires a seventh field:
- `interface-definitions.md:194` — `sub_reason` | string | no (optional) | ... Current values: `"https-downgrade"` ... and `"private-ip"`
- `interface-definitions.md:198` — "Stable key order in each object: `file`, `line`, `column`, `link_target`, `verdict`, `reason`, `sub_reason`"
- `error-taxonomy.md:115-128` §3b
- `BC-2.10.002.md:53-56`, `:74`, `:110`, `:151-152` — postconditions requiring `sub_reason: https-downgrade` and `sub_reason: private-ip`
- `prd.md:684-685` D-016

BC-2.13.001/BC-2.13.002 are the *only* BCs owning the JSON serializer (`reporter.rs`, SS-13 — BC-2.13.001:100). BC-2.13.002:47 PC2 additionally freezes the set: "All field names in `results` objects are stable" — with `sub_reason` absent from that set.

**Predicate:** `Grep 'sub_reason' .factory/specs` → 15 hits across 5 files: prd.md (2), error-taxonomy.md (8), interface-definitions.md (2), BC-2.10.002.md (7 lines). **Zero hits in `.factory/specs/behavioral-contracts/ss-13/`.**
**Consequence:** An implementer building `reporter.rs` JSON serialization from SS-13 emits a 6-field object. BC-2.10.002's private-IP and HTTPS-downgrade diagnostics are silently dropped from machine-readable output — the exact "silent diagnostic loss" failure mode the `errors[]`/`sub_reason` split was introduced to prevent. The corpus manifest comparison (`interface-definitions.md:305`) projects onto six fields, so no acceptance test catches the omission.

---

## P7-S5-004 — BC-2.13.001 claims VP-011 proves "JSON output is valid and parseable"; VP-011 asserts only sort determinism [CRITICAL]

`BC-2.13.001.md:89`:
```
| VP-011 | JSON output is valid and parseable | proptest (P1) |
```

`vp-011-sort-deterministic.md` asserts nothing about JSON validity or parseability:
- `:40` H1 — "VP-011: Sort Order Is Deterministic — Same Vec<Finding> Always Produces Same Permutation"
- `:44` Property Statement — total order on `Vec<Finding>` under `sort_unstable_by_key`
- `:49` Source Contract Postcondition/Invariant — "DI-001 — output ordering is deterministic"
- `:140-153` `vp011_binary_output_stable_json` — byte-**compares** two stdout buffers with `assert_eq!`; it never parses them. No `serde_json`, no `jq`, no `from_str` anywhere in the file.

BC-2.13.001:66 Invariant 5 states "JSON is machine-parseable: `mdlinkcheck --format json | jq` must work" and the VP table attributes that invariant to VP-011. VP-011 passes on any implementation whose `--format json` output is deterministic garbage.

**Predicate:** `Grep 'serde_json|jq|from_str|parse' vp-011-sort-deterministic.md` → 0 matches. `Grep 'valid|parseable' vp-011-sort-deterministic.md` → 0 matches.
**Consequence:** False-green. The single P0 verification obligation for JSON well-formedness — the primary CI-engineer consumption contract — is discharged by a proof that cannot fail on malformed JSON.

---

## P7-S5-005 — VP-021 is cited for three properties it does not assert, across BC-2.12.001 and BC-2.13.001 [CRITICAL]

`vp-021-no-undefined-reason-codes.md` asserts exactly one property: set-membership of `reason` strings in the 13-code closed set (`:41-46` Property Statement; `:86-143` harness — a `HashSet` `contains` check plus `total_checked > 0`). It contains no assertion about output suppression, ANSI escape codes, or field ordering.

Three BC rows claim otherwise:
1. `BC-2.12.001.md:72` — `| VP-021 | Clean links produce no output | integration |`. VP-021 never counts findings and never asserts that a clean link is absent from output. A reporter that emitted every clean link with `reason: "file-not-found"` passes VP-021.
2. `BC-2.13.001.md:90` — `| VP-021 | No ANSI codes in JSON output | integration (test-sufficient) |`. VP-021 does not inspect for `\x1b`.
3. `BC-2.13.001.md:91` — `| VP-021 | Field order consistent | integration (test-sufficient) |`. VP-021 parses with `serde_json::Value` (`:106`), which is order-agnostic by construction — it *cannot* observe key order.

**Predicate:** `Grep 'ANSI|\\x1b|escape|field order|key order|clean' vp-021-no-undefined-reason-codes.md` → 0 matches.
**Consequence:** False-green ×3. Row 3 is structurally unfalsifiable (the harness's own data structure discards the property under test) — this is the same defeat pattern as the em-dash-defeated `VP-TBD` grep and the table-only holdout checker.

---

## P7-S5-006 — BC-2.11.001 claims VP-016 verifies the globset `**` dialect; VP-016 never exercises a `**` pattern [CRITICAL]

`BC-2.11.001.md:81`:
```
| VP-016 | globset dialect: ** crosses directories | integration |
```

`vp-016-ignored-files-anchor-targets.md` has one `--ignore` fixture, and its pattern is a bare literal filename:
- `:96` — `ignore_patterns: vec!["ignored.md"],`

No `**`, no `*`, no directory-crossing pattern appears anywhere in the file. VP-016's Property Statement (`:47`) and Source Contract (`:64-65`) are exclusively about DI-006 anchor-target survival. VP-INDEX.md:237 confirms the intended scope: "BC-2.11.001 | --ignore glob exclusion (source files only) | VP-016 | anchor tables built for --ignore'd files."

BC-2.11.001:55 Invariant 2 ("Glob matching uses `globset 0.4.20` dialect: `*` does not cross `/`, `**` does") and its CTV row 1 (`:74`, `vendor/**`) are the highest-risk semantics in SS-11, and they carry a VP citation that verifies nothing about them.

**Predicate:** `Grep '\*\*' vp-016-ignored-files-anchor-targets.md` → 0 matches outside prose emphasis markers; `Grep 'ignore_patterns' vp-016-ignored-files-anchor-targets.md` → 1 match (`:96`, literal `"ignored.md"`).
**Consequence:** False-green. VP-016 passes on an implementation that treats `--ignore` patterns as literal path equality — which would break the CTV at BC-2.11.001:74 and every `--ignore 'vendor/**'` invocation in the product's primary CI use case.

---

## P7-S5-007 — VP-010's Property Statement forbids the raw-string prefix match that BC-2.11.002 D-019 mandates [CRITICAL]

`BC-2.11.002.md:47-51` PC3 (`:63-65`) requires, when WHATWG normalization fails, a **raw-string prefix match at a component boundary**, with CTV row 5 (`:94`): `--allow https://build_server` against `https://build_server/status` (WHATWG fails) → **exempt**.

VP-010 — the only VP for this BC (VP-INDEX.md:238) — asserts the opposite:

`vp-010-allow-component-boundary.md:38`: "The allow-match logic compares full URL components (scheme + host), **never raw byte prefixes**."

Its harness (`:65`) constructs prefixes via `AllowPrefix::parse(&allowed_prefix).unwrap()` and generates only well-formed hosts (`host in "[a-z]{3,8}\\.[a-z]{2,4}"`, `:57`) — there is no malformed-URL generator and no fallback branch. VP-010 is v1.0 with `modified: []` (`:4`, `:23`); BC-2.11.002 v1.4 (`:25`) introduced the D-019 fallback and the change never propagated.

**Predicate:** `Grep 'raw|fallback|malformed|WHATWG|normaliz' vp-010-allow-component-boundary.md` → 1 match, `:38` "never raw byte prefixes" — the negation of the required behaviour. 0 matches for `fallback`, `malformed`, `build_server`.
**Consequence:** False-green *and* actively misleading. An implementer following VP-010 rejects the raw-string fallback, making BC-2.11.002 CTV row 5 fail; an implementer following BC-2.11.002 implements it, and VP-010's stated property ("never raw byte prefixes") is falsified by their own code. The `--allow` mechanism is also a security boundary (trap T16, `BC-2.11.002.md:99`), so the fallback path — the one that bypasses WHATWG parsing entirely — is precisely the path with the highest bypass risk and it has zero verification.

---

## P7-S5-008 — BC-2.11.002 claims VP-010 proves the end-of-string boundary case; VP-010's generator cannot produce it [HIGH]

`BC-2.11.002.md:100`:
```
| VP-010 | Exact match (no trailing /) is exempt | proptest |
```
This corresponds to BC-2.11.002 CTV row 2 (`:91`): prefix `https://example.com`, URL `https://example.com` → "yes (end)" → exempt, and to Invariant 1 (`:75`) which names end-of-string as one of the four legal boundary characters.

VP-010's generator (`vp-010-allow-component-boundary.md:59`) is `path in "/[a-z/]{0,20}"` — the leading `/` is mandatory in the regex, so `allowed_url = format!("https://{}{}", host, path)` (`:62`) **always** has a `/` immediately after the prefix. The end-of-string boundary is never sampled, in any run, at any proptest case count.

**Predicate:** `Grep 'path in' vp-010-allow-component-boundary.md` → 1 match, `:59` `path in "/[a-z/]{0,20}"` (leading `/` outside the quantified class).
**Consequence:** One of the four boundary characters in the security-critical boundary rule (end-of-string) is unverified while the BC's VP table reports it proven by proptest. An implementation that requires a trailing `/` — rejecting the bare `https://example.com` exemption — passes VP-010 and fails BC-2.11.002 CTV row 2.

---

## P7-S5-009 — BC-2.11.001 EC-192 (and TV-192) assert `*.md` excludes all `.md` files, contradicting the same BC's globset invariant [HIGH]

`BC-2.11.001.md:68`:
```
| EC-192 | `--ignore '*.md'` excludes all .md files |
```
`BC-2.11.001.md:55` Invariant 2: "`*` does not cross `/`". Under globset with a CWD-anchored pattern (`:41`, `:56`), `*.md` matches `README.md` but **not** `docs/a.md`. "Excludes all .md files" is therefore false for any corpus with a subdirectory — which is every realistic corpus and the entire point of the tool.

The error has propagated into the executable registry: `test-vectors.md:427` — "TV-192 | EC-192 | `--ignore '*.md'` — glob excludes all .md source files; **0 files scanned** | BC-2.11.001 | `--ignore '*.md'` | 0 | no findings". A test-writer building TV-192 on a nested fixture gets a nonzero scan set and a failing vector.

The BC's own CTV row 2 (`:75`) happens to be correct only because the fixture contains a single top-level file (`README.md`); it silently masks the contradiction.

Related non-injectivity: `test-vectors.md:238` TV-125 also owns `--ignore '*.md'` ("All files matched by `*.md`"), so two distinct EC IDs (EC-125, EC-192) claim the same scenario, and TV-125 additionally asserts an unspecified "warning on stderr" that no BC in this shard defines.

**Predicate:** `Grep "\-\-ignore '\*\.md'" .factory/specs` → 4 sites: BC-2.11.001.md:68, :75; test-vectors.md:238, :427. Sites consistent with globset `*`-does-not-cross-`/` semantics: 0 of 4 state the restriction.
**Consequence:** POLICY 4 mis-anchoring that contradicts elsewhere in the same document (HIGH by rubric). The defect has already crossed from the BC into the canonical test-vector registry, so both derivation paths are poisoned.

---

## P7-S5-010 — BC-2.14.002's sole edge case (EC-169) is unsatisfiable and contradicts its own Precondition 2 [HIGH]

`BC-2.14.002.md:66` — the only row in the Edge Cases table:
```
| EC-169 | 1 broken link + invalid `--format` flag |
```
`BC-2.14.002.md:51` PC2 states the exit-2 triggers are `io_errors` non-empty OR `config_error = true`, and that "The sole trigger for `config_error = true` is an invalid `--ignore` glob pattern ... unrecognized flags are handled by clap before `app::run()` and do NOT set `config_error`." `capabilities.md:251-252` says the same: flag-parsing failures "never reach `verdict::exit_code`." `BC-2.12.004.md:52` Invariant 2: an invalid `--format` value "triggers exit 2 **immediately, before any scanning begins**."

Therefore the state "1 broken link + invalid `--format`" cannot occur: clap exits before traversal, so no broken link is ever discovered. The vector cannot demonstrate the precedence property (DI-011) it is filed under. The v1.3 changelog (`:24`) records that this BC's `config_error` description was tightened to the sole trigger; the edge case was not revisited.

Propagated: `test-vectors.md:385` — "TV-169 | EC-169 | 1 broken link + invalid `--format` flag | `--format bad` | 2 | exit 2 (**config error** beats broken) | Exit 2 beats exit 1 (DI-011); see BC-2.14.002" — which mislabels a clap value-parser rejection as a `config_error`, directly contradicting BC-2.14.002:51 and capabilities.md:250.

**Predicate:** `Grep 'EC-169' .factory/specs` → 2 sites (BC-2.14.002.md:66, test-vectors.md:385). Sites consistent with the canonical `config_error` sole-trigger ruling: 0 of 2.
**Consequence:** BC-2.14.002 is the sole owner of DI-011 precedence (BC-INDEX.md:216, VP-INDEX.md:264). Its only edge case is unbuildable, and the registry entry teaches the implementer a false `config_error` membership that three other BCs and CAP-014 explicitly retracted.

---

## P7-S5-011 — BC-2.12.003's unqualified "summary is ALWAYS written" is contradicted by BC-2.14.004 PC5 and left undefined by BC-2.11.004 [HIGH]

`BC-2.12.003.md:54` Invariant 1: "The summary line is ALWAYS written to stderr, never stdout."
`BC-2.12.003.md:57` Invariant 4: "No flag suppresses the summary line (D-011: `--quiet` is a non-goal)."

Two in-scope BCs contradict this:
1. `BC-2.14.004.md:52` PC5 — "Stderr is empty (no summary line is emitted — there are no results)." `--help`/`--version` are flags, and they suppress the summary. Invariant 4 says no flag does.
2. `BC-2.11.004.md:53-57` — the invalid-glob path enumerates stderr as `error: invalid --ignore glob '<pattern>': <reason>` (PC2) and stdout as empty (PC5), and is silent on the summary. BC-2.12.003 has no scope qualifier excluding the config-error path, so `mdlinkcheck . --ignore '[abc'` must, per BC-2.12.003 Invariant 1, print "No broken links found." after an error that aborted before traversal.

BC-2.12.003's only guard is Precondition 1 (`:45`, "All scanning and reporting is complete"), which is not a scope exclusion — BC-2.14.004 also satisfies "no scanning to complete" and reaches the opposite conclusion.

**Predicate:** `Grep -n 'ALWAYS written|no flag suppresses|Stderr is empty' .factory/specs/behavioral-contracts` → BC-2.12.003.md:54, :57 (unqualified universal) vs BC-2.14.004.md:52 (counterexample). BC-2.11.004 stderr enumeration: `Grep -n 'Stderr' BC-2.11.004.md` → 1 hit (`:53`), summary not mentioned.
**Consequence:** Three BCs give three different answers for stderr content on a non-scanning exit. Integration tests asserting exact stderr (BC-2.12.005:78-79 asserts stderr contents by pattern) will disagree with whichever BC the implementer followed.

---

## P7-S5-012 — BC-2.12.002 leaves NO_COLOR vs CLICOLOR_FORCE precedence undefined; PC3/PC4 and PC5 both fire unconditionally [HIGH]

`BC-2.12.002.md:46-50`:
```
3. If NO_COLOR is set to any value: no color codes.
4. If CLICOLOR=0: no color codes.
5. If CLICOLOR_FORCE=1: color codes applied regardless of TTY status.
```
PC3 and PC5 are both unconditional and both apply to the state `NO_COLOR=1 && CLICOLOR_FORCE=1`, with opposite outcomes. Same for `CLICOLOR=0 && CLICOLOR_FORCE=1` (PC4 vs PC5). PC1 (`:46`) conditions only on stdout-TTY and does not resolve precedence; PC5's qualifier is "regardless of **TTY status**", which is silent on the suppression variables.

The Edge Cases table (`:59-62`, EC-126/127/128) tests each variable in isolation; no combination row exists. `interface-definitions.md:216-220` §7 lists all three variables with no precedence statement either. This is a doubly-assigned combination in the env-var input domain.

**Predicate:** `Grep -n 'CLICOLOR_FORCE' .factory/specs` → 6 sites (BC-2.12.002.md:38, :50, :62, :69; interface-definitions.md:127, :220). Sites stating precedence against NO_COLOR: 0 of 6.
**Consequence:** Two conforming implementations differ observably on the same environment. Because BC-2.12.002 Invariant 1 (`:53`) says color is "purely cosmetic — only ANSI escape codes differ", the divergence lands directly in stdout bytes, colliding with NFR-003 / DI-001 byte-identical-stdout (BC-2.12.001:55).

---

## P7-S5-013 — Three sites disagree on whether the JSON `errors` key is mandatory [HIGH]

- `BC-2.13.001.md:47-48` PC1 — "Both `results` and `errors` are **always present**; each may be an empty array." Invariant 3 (`:64`) — empty scan produces `{"schema_version":1,"results":[],"errors":[]}`.
- `interface-definitions.md:174` — "`errors` is **omitted** (or an empty array `[]`) when no I/O errors occurred." `:182` §6.1 — "Empty array `[]` **or omitted** when no I/O errors."
- `test-vectors.md:246` TV-133 — expected output for a clean run with `--format json` is `{"schema_version":1,"results":[]}` — **`errors` absent**.

A consumer written against BC-2.13.001 (`.errors[]` unconditionally) crashes on output written against interface-definitions.md or TV-133. VP-021's harness relies on the key existing (`vp-021-no-undefined-reason-codes.md:122`, `json["errors"].as_array().unwrap_or(&vec![])` — it degrades silently rather than failing, so the ambiguity is invisible to verification).

Note that TV-133's EC-133 is also orphaned: BC-2.12.003 v1.3 (`:24`) removed EC-133, and no BC in the corpus claims it, so the wrong exemplar has no BC owner to correct it.

**Predicate:** `Grep -n '"errors"' .factory/specs` → BC-2.13.001.md:47, :64, :82, :83, :84; interface-definitions.md:164, :174, :182; test-vectors.md:246. Of the three normative statements about presence, 1 says mandatory, 2 permit omission.
**Consequence:** The mandatory-vs-optional split lands on the exact field introduced (F-013) to let the CI-engineer persona distinguish broken links from scan failures. `jq '.errors | length'` on a clean run either returns 0 or errors out, depending on which document the implementer read.

---

## P7-S5-014 — BC-2.12.005 PC5 closes the stderr content set in a way that excludes I/O error messages and progress output, contradicting its own Description [HIGH]

`BC-2.12.005.md:54` PC5: "stderr contains **only** the summary line (and any error messages from configuration failures)."

Contradicted by:
- Its own Description, `:38-39`: "Progress indicators (if any) are written to stderr."
- `interface-definitions.md:100` §4 — stderr carries "progress messages (if any), warnings, informational messages (e.g., 'No markdown files found'), **error messages for I/O errors**, and the trailing summary line."
- `BC-2.01.009.md:52` — for a nonexistent PATH, "an error message is emitted on stderr"; `:71`, `:73` — `E-IO-002 on stderr`.
- `BC-2.12.005.md:60` Invariant 3 — "A caller can redirect ... `>/dev/null` to get **only the summary** on stderr", which is false whenever an I/O error or progress line was emitted.

PC5 names only *configuration* failures, not I/O failures. Since this BC is the CI-engineer persona's core stream contract (P0, BC-INDEX.md:168), an implementer resolving the conflict in favour of PC5 has one place left to put I/O error text — stdout — which would break `interface-definitions.md:102` ("stdout is pure findings") and corrupt `mdlinkcheck --format json > report.json`.

**Predicate:** `Grep -n 'stderr' BC-2.12.005.md` → 8 sites; `:38` (progress → stderr) and `:54` (stderr contains only summary + config errors) are mutually exclusive. `Grep -n 'error messages for I/O' interface-definitions.md` → `:100`.
**Consequence:** The one contract whose violation the shard directive designates CRITICAL (findings/diagnostics stream separation) is specified with a closed enumeration that omits the largest diagnostic class, and the resolution an implementer may pick routes diagnostics onto stdout.

---

## P7-S5-015 — BC-2.11.001 and BC-2.11.004 cite Brief Requirement R6 for `--ignore`; R6 is output formats. Sibling fix not propagated [HIGH]

`product-brief.md:46-49` (frozen, authoritative):
```
R5. `--ignore <glob>` (repeatable) excludes files; `--allow <url-prefix>` ... exempts external URLs
R6. Output: human-readable text (default) ...; `--format json` emits a machine-readable array of the same.
R7. Exit codes: 0 = ...; 1 = ...; 2 = usage or I/O error
```
`BC-INDEX.md:234-236` confirms: "R5 — --ignore/--allow filters | BC-2.11.001..BC-2.11.004"; "R6 — Output formats | BC-2.12.001..BC-2.13.002"; "R7 — Exit codes | BC-2.14.001..BC-2.14.004".

Yet:
- `BC-2.11.001.md:89` — `| Brief Requirement | R6, DD-008 |`
- `BC-2.11.004.md:87` — `| Brief Requirement | R6, DD-008 |` (this BC is about **exit 2**, so it should cite R5 **and R7**, never R6)

This is a documented partial fix: `BC-2.11.002.md:25` v1.4 records "P2-m05 — ... corrected Brief Requirement from R6 to R5", and `BC-2.11.003.md:78` correctly says R5. Two of four SS-11 siblings were left behind.

**Predicate:** `Grep -n 'Brief Requirement \| R6' .factory/specs/behavioral-contracts` → 9 hits. Of those, the 2 in `ss-11/` (BC-2.11.001.md:89, BC-2.11.004.md:87) are mis-cites; the 7 in `ss-12/`/`ss-13/` are correct output-format BCs.
**Consequence:** Blast radius 2 files → HIGH per partial-fix regression discipline. The RTM (`gen-rtm.py`) and BC-INDEX R-map now disagree on which brief requirement two P0 BCs trace to; R5's BC coverage is understated by two and R6's overstated by two.

---

## P7-S5-016 — Three exit-2 input states are asserted in the corpus but are unrepresentable in the 3-input model and owned by no BC [HIGH]

`interface-definitions.md:87` assigns exit 2 to: "Unrecognized flag, invalid flag value, nonexistent PATH argument, unreadable `.md` file, **or internal unexpected error**", and `:91` asserts "**No other exit codes are produced.**"

`verdict::exit_code(findings, io_errors, config_error)` (BC-2.14.001:41, BC-2.14.002:42, BC-2.14.003:45, capabilities.md:235) has exactly three inputs. Three asserted exit-2 states have no representation and no owning BC:

1. **"internal unexpected error"** — no input, no BC, no VP. Rust's default abort/panic exit code is 101, not 2, and no catch-unwind boundary is specified anywhere. `prd.md:632` records that F-016 deliberately **deleted** the "SIGINT/panic sentences ... from §3" — but the exit-code table row at `:87` still names the trigger it was deleting. Residue.
2. **SIGINT during scan → exit 2 with partial output** — `test-vectors.md:260` (TV-146) is a registered executable vector. POSIX shells report SIGINT termination as 130. No BC, no mechanism, and it directly conflicts with `:91` "No other exit codes are produced". It also conflicts with prd.md:632's deletion of SIGINT specification.
3. **Unrecognized flag (e.g. `--bogus`) → exit 2** — asserted only at `interface-definitions.md:238` and `test-vectors.md:251` (TV-137). All three SS-14 BCs *explicitly scope-exclude* it (BC-2.14.001:48, BC-2.14.002:51, BC-2.14.003:46) and BC-2.14.004 covers only `--help`/`--version`. It is a BC-orphan: the exit code depends entirely on clap's undocumented default rather than on a contract.

**Predicate:** `Grep -n 'internal unexpected error|SIGINT|catch_unwind' .factory/specs` → `interface-definitions.md:87` (1), `test-vectors.md:260` (1), `prd.md:632` (1, recording deletion); 0 hits in `.factory/specs/behavioral-contracts/` and 0 in `.factory/specs/verification-properties/`.
**Consequence:** VP-005 (`vp-005-exit-code-io-error.md:56`) proves totality over exactly 8 symbolic combinations of `(has_broken, has_io_error, config_error)`. Any exit-code state outside that cube — panic, SIGINT, clap-level rejection — is outside the Kani proof's universe while `interface-definitions.md:91` claims the exit-code set is closed. That is a false closure claim over the product's most CI-load-bearing contract.

---

## P7-S5-017 — `check-ec-injectivity.py` structurally cannot detect BC↔registry scenario mismatch, which is why P7-S5-002 survived [HIGH] **Tag:** [process-gap]

POLICY 16's lint hook is `check-id-resolution.py` and EC injectivity is nominally covered by `check-ec-injectivity.py` (self-described `:3` as "POL-16 (the big one)"). Reading the checker (per D-057, no skip list):

1. **BC-vs-registry description comparison is explicitly disabled.** `check-ec-injectivity.py:191-194`:
```python
# Description collision: across BC files, independent of verdict column presence.
# BC descriptions are expected paraphrases of TV descriptions (TV captures the
# canonical input-file name, not a scenario description), so BC-vs-TV is skipped.
if len(bc_occs) > 1:
```
The `bc_occs` filter (`:183`) removes test-vectors.md, so an EC ID appearing in exactly one BC and once in the registry (`len(bc_occs) == 1`) is never description-compared at all. That is the shape of **all 19** mismatches in P7-S5-002.

2. **Verdict comparison requires the BC row to have a verdict cell.** `:221-222`:
```python
if not bc_verdict_raw.strip():
    continue  # BC row has no verdict column — skip verdict comparison
```
Every mismatched BC in this shard uses a 2-column `| EC | Description |` table (BC-2.12.001:58, BC-2.12.002:58, BC-2.12.003:60, BC-2.12.004:55, BC-2.13.001:73, BC-2.13.002:57, BC-2.14.001:62, BC-2.14.002:64, BC-2.14.003:59, BC-2.14.004:61), so `rest_cells[1]` is absent (`:127`) and the branch short-circuits. The exit-0-vs-exit-2 EC-142 contradiction is invisible for exactly this reason.

3. **The positive-coverage line is a false green.** `:258-261` prints "Check passed: {total_ec_ids} EC IDs validated — all injective ({multi_occurrence} appear in multiple files but are consistent)". The count is runtime-computed, so POL-11's arithmetic requirement is met — but the phrase "**are consistent**" is asserted over a population that was never compared. A high `multi_occurrence` figure reads as strong coverage while the comparison that would justify it was skipped by `:194` and `:222`.

**Predicate:** `Grep -n 'bc_occs|verdict_raw.strip' check-ec-injectivity.py` → `:183, :194, :212, :218, :220, :221`. Number of BC edge-case tables in this shard with a 3rd (verdict/expected) column: 3 of 15 (BC-2.11.004:64, BC-2.12.005:63, and — 2-column — none other; verified by `Grep -c '^| EC |.*|.*|' `). So 12 of 15 in-scope BCs are wholly exempt from verdict comparison, and all 15 are exempt from BC-vs-registry description comparison.
**Consequence:** 19 mis-anchored EC IDs, one of them an outright exit-code contradiction, passed every prior converged pass. The claim "all injective" in the checker's success line is not supported by the comparisons the checker performs. Recommended repair: enable BC-vs-TV description comparison with the same Jaccard rule already implemented at `:77-98`, and treat a BC row's *Expected* cell as a verdict source when present.

---

## P7-S5-018 — BC-2.11.004 Invariant 3 cites a taxonomy identifier (`E-CLI-001`) that was retired and exists nowhere in the corpus [MEDIUM]

`BC-2.11.004.md:61`: "Exit code 2 is used for all configuration errors (consistent with **E-CLI-001** taxonomy)."

`error-taxonomy.md` contains no `E-*` identifiers at all — its closed set is the 13 reason codes (`:99-102`). The only other mention of `E-CLI-001` in the corpus is its own retirement record: `BC-2.01.009.md:23` — "Error class changed from E-CLI-001 to E-IO-002." `E-IO-002` is registered (`interface-definitions.md:237`, `BC-2.01.009.md:52`, `:71`, `:73`), but it is the *nonexistent-PATH* class, not the invalid-glob class — and no `E-*` identifier exists for the invalid-`--ignore`-glob trigger BC-2.11.004 owns.

**Predicate:** `Grep -n 'E-CLI-00|E-IO-00' .factory/specs` → 7 hits: 6 for `E-IO-002` (BC-2.01.009 ×5, interface-definitions.md ×1), 1 for `E-CLI-001` (BC-2.11.004.md:61) plus the BC-2.01.009:23 changelog documenting its removal. Live references to `E-CLI-001`: 1 of 1 is dangling.
**Consequence:** POLICY 16 dangling ID in a normative Invariant of the BC that owns the sole `config_error` trigger. It is in an Invariants bullet, not a Traceability table row, so `check-id-resolution.py`'s table-row scope does not reach it — the same blind spot as the holdout-boundary checker's prose gap. An implementer looking up E-CLI-001 finds a retirement note pointing at an unrelated error class.

---

## P7-S5-019 — BC-2.11.003's only edge case, `EC-073b`, is unregistered and reuses a colliding base ID that a sibling BC already remapped [MEDIUM]

`BC-2.11.003.md:61`: `| EC-073b | `mdlinkcheck vendor/lib.md --ignore vendor/**` |`

It appears nowhere else in the corpus. `EC-073`'s canonical owner is `test-vectors.md:158` TV-073 (line-range anchor `[x](src/main.rs#L42-L50)` → clean), a completely unrelated SS-07 scenario. `BC-2.11.001.md:27` v1.2 remapped exactly this collision for its own table ("EC-073→EC-193 (EC-073 canonical owner is test-vectors.md TV-073)") and its sibling BC-2.11.003 was not touched. `check-ec-injectivity.py:14-16` treats sub-lettered variants as distinct IDs, so `EC-073b` is not compared against TV-073 — but it is also absent from the registry, meaning BC-2.11.003 has zero registered edge-case coverage.

**Predicate:** `Grep -n 'EC-073b' .factory/specs` → 1 hit (BC-2.11.003.md:61). `Grep -n 'EC-073b' .factory/specs/prd-supplements/test-vectors.md` → 0 hits. Registered ECs in BC-2.11.003: 0 of 1.
**Consequence:** Partial-fix propagation gap (blast radius 1 → MEDIUM). BC-2.11.003 is the only BC specifying the `--ignore`-beats-explicit-PATH rule and has no registered vector, so P7-S5-001's contradiction has no executable arbiter.

---

## P7-S5-020 — 6 of 15 BCs omit the `L2 Domain Invariants` Traceability row entirely; BC-2.11.003 cites DI-006 in its body but has no row [MEDIUM]

POLICY 2 (`lift_invariants_to_bcs`, lint_hook: null) requires every DI-NNN to be cited by at least one BC's L2 Invariants field, and the BC template evidently expects the row (three in-scope BCs render it explicitly as `—`: BC-2.11.004:86, BC-2.12.005:86, BC-2.14.004:84).

Missing entirely: BC-2.11.002, BC-2.11.003, BC-2.12.002, BC-2.12.003, BC-2.12.004, BC-2.13.002.

The substantive case is **BC-2.11.003**: its PC3 (`:48`, "The file's anchor table IS built (DI-006)") and Invariant 3 (`:54-56`, "`--ignore` exclusion (even over explicit PATH) is DI-006 case 1") make DI-006 load-bearing, yet DI-006 does not appear in any Traceability field of that file. Correspondingly `BC-INDEX.md:211` lists DI-006's enforcers as "BC-2.01.003, BC-2.05.001, BC-2.08.004, BC-2.11.001" — BC-2.11.003 absent from both directions of the join.

**Predicate:** `Grep -c '^\| L2 Domain Invariants \|' --glob '*BC-2.1[1-4]*'` → 9 hits across 9 files (BC-2.11.001, BC-2.11.004, BC-2.12.001, BC-2.12.005, BC-2.13.001, BC-2.14.001, BC-2.14.002, BC-2.14.003, BC-2.14.004). 15 − 9 = 6 files with no row.
**Consequence:** The DI→BC coverage join (POLICY 2, no lint hook) undercounts DI-006's enforcers, and a reader auditing the six row-less BCs cannot distinguish "no DI applies" from "the row was dropped".

---

## P7-S5-021 — BC-INDEX's DI-010/DI-011 reverse map omits in-scope BCs and misdescribes DI-010 using the Layer-2 term `alive` [MEDIUM]

`BC-INDEX.md:215-216`:
```
| DI-010 | Three-verdict model: alive/broken/indeterminate (429/5xx/timeout → indeterminate) | BC-2.10.002, BC-2.14.003 |
| DI-011 | Exit 2 beats exit 1; no fail-fast | BC-2.01.009, BC-2.02.003, BC-2.14.002 |
```

Two defects:
1. **`alive` presented as a link verdict.** DI-010's actual content is "Indeterminate Does Not Cause Exit 1" (`invariants.md:266`). `invariants.md:135` and `error-taxonomy.md:48` both state explicitly that "`alive` is NOT a fourth link verdict" — it is a Layer-2 URL liveness outcome. The DI-010 row conflates the two layers and misstates the invariant's subject.
2. **Reverse-map omissions.** `BC-2.14.001.md:86` cites `DI-010, DI-011`; `BC-2.14.003.md:83` cites `DI-010, DI-011`. Neither appears in the DI-010/DI-011 rows for the relevant invariant (BC-2.14.001 is absent from both; BC-2.14.003 is absent from DI-011).

**Predicate:** `Grep -n 'DI-01[01]' .factory/specs/behavioral-contracts` → L2-Invariants-row citations of DI-010: BC-2.10.002:167, BC-2.10.003:78, BC-2.10.004:98, BC-2.10.010:93, BC-2.14.001:86, BC-2.14.003:83 = 6 BCs; BC-INDEX.md:215 lists 2. DI-011: BC-2.01.009:85, BC-2.02.003:74, BC-2.14.001:86, BC-2.14.002:88, BC-2.14.003:83 = 5 BCs; BC-INDEX.md:216 lists 3.
**Consequence:** POLICY 17 derived-table drift plus a POLICY 4 semantic mis-anchor on the two-layer verdict vocabulary. The DI→BC table is the artifact a reviewer uses to confirm invariant coverage; it understates DI-010 coverage by 4 BCs and DI-011 by 2, and teaches the reader that `alive` is a link verdict.

---

## P7-S5-022 — BC-2.12.004 asserts repeated-`--format` last-wins only in its VP table; no postcondition or invariant states it, and EC-137 has no expected outcome [MEDIUM]

`BC-2.12.004.md:74`: `| test-sufficient | Last --format wins when repeated | unit test |`

Nothing in the BC's Postconditions (`:44-48`) or Invariants (`:50-52`) specifies repeat behaviour. Invariant 1 states "Exactly two valid values" — which is silent on multiplicity. The Edge Cases table (`:54-60`) is 2-column with no Expected column, so EC-137 (`--format json --format text`, `:60`) has no stated outcome anywhere in the BC. The behaviour exists only outside this shard, at `interface-definitions.md:47` ("`--format` repeated: last value wins") and `:233`.

**Predicate:** `Grep -n 'last.*wins|repeated' BC-2.12.004.md` → 1 hit (`:74`, the VP row). Postconditions/Invariants mentioning repetition: 0.
**Consequence:** BC-2.12.004 is the sole owner of the `--format` CLI surface (BC-INDEX.md:167). A verification obligation is declared for a property the contract never states, so the test-writer must derive the assertion from a non-BC document — and the corresponding edge case is untestable as written.

---

## P7-S5-023 — BC-2.12.005 Precondition 1 references a phantom flag `--json` [MEDIUM]

`BC-2.12.005.md:45`: "Text output format is active (default; **not `--json`**)."

There is no `--json` flag. The flag is `--format json` (`interface-definitions.md:45` §2.1; BC-2.12.004:46 PC2; BC-2.13.001:41 PC1; BC-2.12.002:54 Invariant 2 correctly writes `--format json`). Given that `--quiet`, `--offline`, `--insecure` and `--hidden` are explicit dropped non-goals (`interface-definitions.md:49`, `:64`, `:70`; D-011), a BC precondition keyed on a flag name that does not exist in the CLI surface is a scope hazard: an implementer or CLI-surface reviewer reading BC-2.12.005 may add `--json` as an alias, silently expanding the frozen flag set.

**Predicate:** `Grep -n -- '--json' .factory/specs` → 1 hit, `BC-2.12.005.md:45`. `Grep -n -- '--format json' .factory/specs/prd-supplements/interface-definitions.md` → `:45`, `:102`, `:305`. So the phantom form appears exactly once, against a fully-established canonical form.
**Consequence:** The precondition of a P0 stream-separation contract keys on a nonexistent flag, so it cannot be evaluated literally. POLICY 4 semantic anchoring: the anchor is syntactically flag-shaped and semantically unresolvable.

---

## P7-S5-024 — BC-2.11.003 frontmatter `version: "1.2"` while its changelog documents a v1.3 change, and it retains the `c3e82ce` input-hash that was declared drifted [MEDIUM]

`BC-2.11.003.md:4` — `version: "1.2"`; `:23` — `- v1.3: "DI-006 four-mechanism note added to Invariants."`. The top changelog entry names a version higher than the declared version, and no entry documents v1.2's own change. (Contrast BC-2.11.001, whose sibling v1.3 entry at `:24` is accompanied by `version: "1.6"`.)

`BC-2.11.003.md:14` — `input-hash: "c3e82ce"`. `BC-2.12.005.md:23` v1.6 records: "input-hash corrected to 07d983a (**was c3e82ce, hash drift**)", and `test-vectors.md:476` v1.10 records "input-hash corrected to 07d983a". The same correction was applied to 13 of the 14 other in-scope BCs but not to BC-2.11.003.

**Predicate:** `Grep -n 'c3e82ce' .factory/specs` → 13 sites: 11 BC files (BC-2.01.006/007/008, BC-2.02.001/003/004, BC-2.03.006, BC-2.05.001, BC-2.10.009/010, **BC-2.11.003**), BC-INDEX.md:12, plus BC-2.12.005.md:23's changelog declaring the value drifted. In-scope (SS-11..14) files still carrying it: 1 of 15 — BC-2.11.003.
**Consequence:** POLICY 1 (append-only numbering / version discipline) violation. `version` is the field consumers use to detect staleness; a file whose changelog is one version ahead of its declared version defeats every downstream drift check, and the drifted input-hash makes the input-provenance chain unverifiable for this BC.

---

## P7-S5-025 — Two `Related BCs` cross-references describe the wrong contract [MEDIUM]

1. `BC-2.11.004.md:92`: `- BC-2.14.003 — sibling (nonexistent PATH → exit 2 pattern)`. BC-2.14.003's H1 is "**Exit Code 1** — At Least One Broken Link Found" (`BC-2.14.003.md:35`; BC-INDEX.md:187). Nonexistent-PATH-→-exit-2 is owned by BC-2.01.009 (`BC-2.01.009.md:52`) and the precedence rule by BC-2.14.002. The reference points a reader at the exit-**1** contract while describing the exit-**2** pattern — the exact conflation BC-2.14.002's whole existence guards against.
2. `BC-2.11.002.md:113`: `- BC-2.11.003 — sibling (--ignore glob exclusion advanced)`. BC-2.11.003's H1 is "`--ignore` on Explicit PATH Argument" (`:33`; BC-INDEX.md:155). "advanced" is not a description of anything; the same line at `:112` already labels BC-2.11.001 as "--ignore glob exclusion", so both siblings carry the same gloss with an uninformative differentiator.

**Predicate:** `Grep -n '^- BC-2\.' .factory/specs/behavioral-contracts/ss-1[1-4]` → 11 Related-BCs entries across the shard; 2 have glosses that do not match the target's H1 (BC-2.11.004:92, BC-2.11.002:113); the remaining 9 match.
**Consequence:** POLICY 4 mis-anchoring. A reader following BC-2.11.004's "nonexistent PATH → exit 2" pointer lands in the exit-1 contract, whose Precondition 3 (`BC-2.14.003.md:45`) explicitly requires *no* nonexistent PATH — the opposite of what the pointer promised.

---

## P7-S5-026 — Three VP files carry invented BC titles in their Source Contract field; the fix applied to VP-011 was not propagated to siblings [MEDIUM]

POLICY 7: the BC H1 is the title source of truth. Three VPs joined to my BCs violate it:

| VP | Source Contract title | Actual BC H1 |
|---|---|---|
| `vp-005-exit-code-io-error.md:49` | "BC-2.14.002 — I/O Error Exit Code Precedence" | "Exit Code 2 Takes Precedence Over Exit Code 1" (BC-2.14.002:35) |
| `vp-006-exit-code-clean.md:52` | "BC-2.14.001 — Exit Code 0 for Clean / Indeterminate Run" | "Exit Code 0 — No Broken Links" (BC-2.14.001:36) |
| `vp-010-allow-component-boundary.md:42` | "BC-2.11.002 — Allow-List Component Boundary" | "`--allow` URL Prefix Exemption with Component-Boundary Safety" (BC-2.11.002:35) |

This exact defect class was repaired for VP-011 and VP-016: `vp-011-sort-deterministic.md:29` — "corrected source BC title from **invented** 'BC-2.12.001 — Deterministic Output Ordering' to actual H1"; `vp-016-ignored-files-anchor-targets.md:32` — "corrected Source Contract title from **invented** 'BC-2.08.004 — Ignored File Anchor Resolution' to actual BC-2.08.004 H1". VP-005 and VP-006 were both edited in v1.1 for the `config_error` model without the title being touched; VP-010 has `modified: []`.

**Predicate:** `Grep -c 'Source Contract' .factory/specs/verification-properties` → 30 occurrences across 26 files. Of the 6 VPs joined to this shard's BCs (VP-005, VP-006, VP-010, VP-011, VP-016, VP-021), 3 carry non-verbatim invented titles and 3 carry corrected/abbreviated-but-derived titles.
**Consequence:** Blast radius 3 files → HIGH by the partial-fix table, held at MEDIUM here because none of the three mis-titles changes the *identity* of the joined BC (the BC-NNN ID is correct in all three). POLICY 7 has `check-title-sync.py` as its hook, but the hook evidently does not reach VP `Source Contract` lines, since three violations are live at frozen HEAD.

---

## P7-S5-027 — BC-2.13.001 PC5 makes the trailing newline optional inside a byte-exact output contract [MEDIUM]

`BC-2.13.001.md:54` PC5: "The JSON is compact; **no trailing newline required but acceptable**."

The same BC's Invariant 4 (`:65`) and the sibling text contract (BC-2.12.001:55, "Two runs with identical inputs produce byte-identical stdout (NFR-003)") make stdout a byte-level contract. `interface-definitions.md:149` §6 specifies "compact (no pretty-printing)" and is silent on the trailing newline. NFR-003 (`nfr-catalog.md:76`) is a *within-implementation* determinism requirement, so PC5 does not break it — but it leaves the output bytes underdetermined for any *cross-artifact* comparison, and the corpus pass criterion (`interface-definitions.md:305`) routes through `jq`, which normalizes the difference away and therefore cannot pin it.

**Predicate:** `Grep -n 'trailing newline' .factory/specs` → 1 hit, BC-2.13.001.md:54. Sites specifying the JSON trailing-newline byte: 1 of 1, and it declines to specify.
**Consequence:** A test-writer building a golden-file assertion (`assert_eq!(stdout, include_str!("expected.json"))`) has a 50% chance of encoding the wrong byte count, and the failure surfaces only in Phase 3. Either mandate the newline or forbid it.

---

## P7-S5-028 — CAP-012's sort key is 3-field while DI-001 (its authority) and both reporter BCs are 4-field [MEDIUM]

`capabilities.md:206-207` (CAP-012, the L2 capability anchor for all five SS-12 BCs): "Emit findings on stdout in human-readable text, sorted by **(NFC-normalized file path, line number, column number)** per DI-001."

DI-001 was widened to four fields: `invariants.md:63-64` — "(NFC-normalized file path, line number, column number, **link target**)"; `:69-71` — "The fourth field `link_target` ... is the tie-break that makes the key total". `invariants.md:27` v1.7 records: "DI-001 sort key updated to four-field ... DI-001 is the L2 authority and must lead."

Both BCs implement 4 fields (BC-2.12.001:49 PC5, `:38`; BC-2.13.001:52 PC4), as does VP-011 (`:44`, `:49`, corrected in v1.2 per `:26` "sort key updated from 3-field to 4-field") and `interface-definitions.md:125`, `:196`. CAP-012 is the one surviving 3-field site, and it is the artifact both SS-12 BCs cite as their capability anchor.

**Predicate:** `Grep -n 'line number, column number' .factory/specs` → `capabilities.md:206` (3-field, no link_target), `invariants.md:63` (4-field). Sites still 3-field after the v1.7 widening: 1 — the CAP-012 body.
**Consequence:** POLICY 5 anchoring gap. BC-2.12.001's Capability Anchor Justification points at a capability description that specifies a *different, non-total* sort key than the BC and DI-001. With a 3-field key, `sort_unstable_by` is not deterministic for findings sharing (path, line, column) — the exact totality argument DI-001:69-71 exists to establish, so an implementer anchoring on CAP-012 reintroduces the DI-001 nondeterminism.

---

## P7-S5-029 — A run that scanned nothing still prints "No broken links found." on stderr [LOW] *(pending intent verification)*

`BC-2.12.003.md:50` PC2: "If N == 0: stderr: `No broken links found.`", with `:41` "Indeterminate findings do NOT count toward N" and no carve-out for I/O failures. Combined with `BC-2.14.002.md:73` CTV row 3 ("1 unreadable file, no broken links | 2"), the specified stderr for a run in which *every* file was unreadable is `No broken links found.` plus exit 2.

For the primary CI-engineer persona, stderr is the human-facing channel and this message is affirmatively reassuring about a scan that produced no coverage. `interface-definitions.md:139-143` §5 contains the same unconditional rule, so the corpus is internally consistent — this may be deliberate (exit code carries the truth; the summary reports only the broken count). Flagged for adjudication rather than asserted as a defect.

**Predicate:** `Grep -n 'No broken links found' .factory/specs` → 8 sites (BC-2.12.003.md:39, :50, :56, :70, :71; BC-2.12.005.md:52, :65, :72; BC-2.14.001.md:53; interface-definitions.md:142). Sites qualifying the message on scan completeness or `io_errors`: 0 of 8.
**Consequence:** If unintended, a one-clause fix (e.g. `No broken links found (M file(s) could not be scanned).`) is needed in BC-2.12.003 PC2 and interface-definitions §5. If intended, BC-2.12.003 should say so explicitly so a future pass does not re-raise it.

---

## P7-S5-030 — BC-2.14.003's EC-146 row and CTV row 3 both violate its own Precondition 2, unlabelled [LOW]

`BC-2.14.003.md:45` Precondition 2: "At least one link received verdict `broken`." Two rows in the same file describe states in which that precondition is false:
- `:63` — `| EC-146 | 0 broken links, 1 indeterminate |`
- `:70` — `| 1 indeterminate only | 0 |` in the Canonical Test Vectors table, whose header is "Expected Exit"

Both are legitimate *contrast* cases for Invariant 1 (`:54`, "Only `broken` verdict links trigger exit 1"), but neither is marked as a negative/non-triggering vector, and BC-2.14.001 already owns the same scenario (`:65` EC-143, `:73` CTV "All links indeterminate | 0"). Sibling BCs in the corpus do label vector category — e.g. `BC-2.01.009.md:71`, `:73` use an explicit `happy-path` / `distinguishing` column, and `BC-2.09.001.md:66` uses a `Category` column.

**Predicate:** `Grep -n 'happy-path|distinguishing|Category' .factory/specs/behavioral-contracts/ss-1[1-4]` → 0 hits across all 15 in-scope BCs; the same grep against `ss-01`, `ss-09` → BC-2.01.009.md:69-73, BC-2.09.001.md:65-69. So 0 of 15 shard BCs carry a vector-category column while sibling subsystems do.
**Consequence:** A test-writer generating cases from BC-2.14.003's tables can read `1 indeterminate only → 0` as an exit-1 assertion, and the duplicate coverage with BC-2.14.001 EC-143 produces two fixtures for one scenario. Editorial, no rework.

---

## Coverage notes (checks performed that produced NO finding)

- **POLICY 7 / 13 (BC H1 ↔ BC-INDEX title sync):** all 15 in-scope H1 titles match `BC-INDEX.md:153-156, 164-168, 176-177, 185-188` **verbatim**, including backticks and the JSON-literal in BC-2.13.001. 15/15 clean.
- **POLICY 5 (quoted-excerpt substantiation):** all 15 `L2 Capability` / `Capability Anchor Justification` quotes verified verbatim against `capabilities.md` section headings — CAP-011 "Filter Application" (`:184`), CAP-012 "Text Report Generation" (`:204`), CAP-013 "JSON Report Generation" (`:216`), CAP-014 "Exit Code Determination" (`:231`). 30 quoted excerpts, 0 fabrications. Glosses are correctly outside the quote marks in all cases.
- **POLICY 6 (subsystem labels):** `subsystem:` frontmatter values `SS-11`/`SS-12`/`SS-13`/`SS-14` and inline module labels (`filter.rs` SS-11, `reporter.rs` SS-12/SS-13, `verdict.rs` SS-14, `cli.rs`/`main.rs` unlabelled shell) are internally consistent; the historical `cli.rs`-mislabelled-SS-11 defect is recorded as fixed at BC-2.11.004:26, BC-2.12.002:25, BC-2.12.004:25, BC-2.14.004:25 and I found no surviving instance.
- **POLICY 9 (VP-INDEX proof-method join):** every VP row's *method label* in all 15 BCs matches VP-INDEX (VP-005 kani, VP-006 kani, VP-010 proptest, VP-011 proptest/P1, VP-016 integration, VP-021 integration/test-sufficient). All 8 `test-sufficient` sentinels (BC-2.11.003, BC-2.11.004, BC-2.12.002, BC-2.12.003, BC-2.12.004, BC-2.12.005, BC-2.13.002, BC-2.14.004) match VP-INDEX.md:239-240, 247-250, 257, 266 exactly — no BC claims `test-sufficient` where a real VP exists, and no BC claims a VP where VP-INDEX says `test-sufficient`. The failures I found are all in the *property claimed* column, not the method or sentinel columns (P7-S5-004/005/006). No subsystem-wide uniform downgrade of a formal proof was found.
- **POLICY 19 (reason-code closure):** every reason code appearing in the 15 bodies — `file-not-found` (BC-2.12.001:65, BC-2.13.001:82, BC-2.14.003:68), `anchor-not-found` (BC-2.14.003:69), `target-unreadable` (BC-2.13.001:56, :59, :67, :84), `malformed-url` (none in shard) — is verbatim in the 13-code closed set at `error-taxonomy.md:99-102`. Zero phantom reason codes. (`E-CLI-001` at BC-2.11.004:61 is an *error-class* identifier, not a `reason` value, and is reported separately as P7-S5-018.)
- **Two-layer verdict vocabulary:** all 15 bodies use `clean` for the positive link verdict and never `alive`. BC-2.11.002:69 PC5 correctly says "verdict `clean`"; BC-2.13.001:51 PC3 and BC-2.13.002:54 Invariant 3 correctly close `verdict` to `broken`/`indeterminate`. `Grep -n 'alive' .factory/specs/behavioral-contracts/ss-1[1-4]` → 0 hits. The only Layer-1/Layer-2 conflation I found is in BC-INDEX (P7-S5-021), not in the BC bodies.
- **Dropped non-goal flags:** `Grep -n -- '\-\-quiet|\-\-offline|\-\-insecure|\-\-hidden' .factory/specs/behavioral-contracts/ss-1[1-4]` → 4 hits, all *negative* (BC-2.12.003:41, :57 and BC-2.14.001:53 correctly cite `--quiet` as a D-011 non-goal; BC-2.12.003:24 changelog records its removal). Zero scope creep. The related phantom flag `--json` is reported as P7-S5-023.
- **NFR budgets:** no in-scope BC states a numeric performance ceiling or names a CI runner platform. The two NFR citations present are non-numeric and correct: BC-2.12.001:55 → NFR-003 (output determinism, `nfr-catalog.md:69-79`), BC-2.13.002:77 → NFR-007 (no undefined reason codes, `:128-138`). Note for the orchestrator: the dispatch brief's "p95 15s on Linux CI" figure is stale relative to the frozen corpus — `nfr-catalog.md:49-65` retargeted NFR-002 to macOS CI at 10s p95 under D-043, retired NFR-004, and moved NFR-008's ~500ms gate to `macos-latest` (`:152`). No shard-5 artifact asserts the obsolete Linux/15s figures.
- **Code fences:** the 15 bodies contain no code fences. All type references in prose (`verdict::exit_code(findings, io_errors, config_error) → u8`, `Vec<IoError>`, `DirIndex`, `AnchorIndex`, `Vec<Finding>`, `config_error: bool`, `globset::GlobBuilder::new(pattern).build()`) resolve consistently across BC-2.11.004:88, BC-2.14.001:59, BC-2.14.002:42, BC-2.14.003:45, BC-2.14.004:58 and against `vp-005-exit-code-io-error.md:73`. No undefined type found.
- **BC-2.11.002 fallback reachability:** I checked whether the D-019 raw-string fallback is unreachable given Precondition 2 ("classified as `external-http`"). It is reachable — `BC-2.09.001.md:41` uses the identical precondition and its PC2 (`:46`) handles WHATWG-parse *failure*, so `external-http` classification precedes WHATWG validation. No finding.

---

## Novelty Assessment

Novelty: **HIGH**. This is not a converging document set.

The dominant finding (P7-S5-002, 19 mis-anchored EC IDs including an exit-0-vs-exit-2 contradiction) is exactly the class the corpus's own gate is designed to catch, and I traced *why* it survived to two specific `continue`/scope statements in `check-ec-injectivity.py` (`:194`, `:221-222`) — a structural blindness, not a tuning miss. Per D-057 I read the checker rather than assuming coverage, and the checker's success line ("all injective ... but are consistent") actively asserts a conclusion its comparisons do not support. That makes P7-S5-017 a false-green generator of the same family as the previously-falsified em-dash `VP-TBD` grep and the table-only holdout checker.

Four VP-table rows (P7-S5-004/005/006, plus the harness-domain gap P7-S5-008) claim verification of properties the VP bodies provably do not assert. Two of them are *unfalsifiable* by construction: VP-021's `serde_json::Value` parse discards key order, so BC-2.13.001's "Field order consistent" row can never fail; and VP-010's generator's mandatory leading `/` means the end-of-string boundary case is never sampled. Neither is detectable by reading either document alone — only the join surfaces them, which is why the fresh-context join sweep still pays at pass 7.

P7-S5-007 (VP-010's Property Statement negating the D-019 fallback it is supposed to verify) and P7-S5-001 (BC-2.11.001 PC4 negating its own bracketed citation) are both *self-negating* single-sentence defects — the kind a pass anchored to its own prior conclusions reads past because the surrounding paragraph is correct.

Six findings are partial-fix propagation gaps where the corpus documents the repair and skipped a sibling: P7-S5-015 (BC-2.11.002 v1.4 fixed R6→R5, siblings BC-2.11.001/004 not), P7-S5-019 (BC-2.11.001 v1.2 remapped EC-072/073, BC-2.11.003's EC-073b not), P7-S5-002's EC-071 (same table, third row missed), P7-S5-024 (13 of 14 files got the input-hash correction), P7-S5-026 (VP-011/VP-016 title repairs not propagated to VP-005/006/010), P7-S5-018 (BC-2.01.009 retired E-CLI-001, BC-2.11.004 still cites it). That density says the fix loop is applying repairs site-by-site rather than by predicate sweep — the highest-leverage process change available.

Nothing in this pass is a rewording of a wording nitpick. Every CRITICAL and HIGH has a file:line contradiction or a demonstrable false-green. This shard has **not** converged; a clean-pass streak cannot start here.