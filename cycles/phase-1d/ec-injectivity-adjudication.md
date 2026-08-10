---
document_type: adjudication-ledger
level: ops
version: "1.0"
status: adjudicated-accepted-not-fixed
phase: phase-1d
producer: vsdd-factory:state-manager
timestamp: "2026-08-10T20:00:00Z"
---

# EC-Injectivity Adjudication Ledger

**Checker:** `scripts/spec-lint/check-ec-injectivity.py`
**Total SCENARIO-MISMATCH items:** 39
**Disposition:** ADJUDICATED-ACCEPTED-NOT-FIXED, all 39 items.
**Authority:** D-244 (gate #58 closed-world condition) + D-246 (follow-on ruling).

---

## Mismatch Table

All 39 items transcribed verbatim from `check-ec-injectivity.py` output (Jaccard J values as reported).

| EC id | BC file:line | BC scenario (documented) | Registry EC scenario (different) | J |
|-------|-------------|--------------------------|----------------------------------|---|
| EC-023 | specs/behavioral-contracts/ss-07/BC-2.07.001.md:62 | `[x](./same-dir.md)` | `docs/b.md` exists (git repo) | 0.00 |
| EC-024 | specs/behavioral-contracts/ss-07/BC-2.07.001.md:63 | `[x](sub/nested.md)` | `/etc/passwd` exists | 0.00 |
| EC-025 | specs/behavioral-contracts/ss-07/BC-2.07.001.md:64 | `[x](../../above-root.md)` | `docs/my file.md` exists | 0.00 |
| EC-033 | specs/behavioral-contracts/ss-07/BC-2.07.004.md:66 | `[x](My%20File.md)` where file is `My File.md` | `a.md` exists | 0.00 |
| EC-035 | specs/behavioral-contracts/ss-07/BC-2.07.004.md:68 | `[x](a%20b.md#section)` | `a.md` exists | 0.00 |
| EC-035 | specs/behavioral-contracts/ss-08/BC-2.08.003.md:60 | `a%20b.md#section` | `a.md` exists | 0.00 |
| EC-043 | specs/behavioral-contracts/ss-06/BC-2.06.001.md:88 | `## Hello World` | `## AI & Automation` | 0.00 |
| EC-044 | specs/behavioral-contracts/ss-06/BC-2.06.001.md:89 | `## C++ Guide` | `## AI & Automation` | 0.00 |
| EC-046 | specs/behavioral-contracts/ss-06/BC-2.06.001.md:91 | `## **Bold** Heading` | `## Phase 1: MVP (128 Features)` | 0.00 |
| EC-047 | specs/behavioral-contracts/ss-06/BC-2.06.001.md:92 | `## A  B` (two spaces) | `## Setup` (×2) | 0.00 |
| EC-048 | specs/behavioral-contracts/ss-06/BC-2.06.001.md:93 | `##` (empty heading) | `## Setup` (×3) | 0.00 |
| EC-055 | specs/behavioral-contracts/ss-06/BC-2.06.002.md:77 | `## Setup` × 2 | `## Done ✅` | 0.00 |
| EC-056 | specs/behavioral-contracts/ss-06/BC-2.06.002.md:78 | `## Setup` × 2 + `## Setup 1` | `## **Bold** Heading` | 0.00 |
| EC-057 | specs/behavioral-contracts/ss-06/BC-2.06.002.md:79 | `## Setup` × 3 | `` ## `code` heading `` | 0.00 |
| EC-059 | specs/behavioral-contracts/ss-06/BC-2.06.001.md:94 | `## 🦀Rust` (emoji directly adjacent to word) | `Setext Title\n=====` | 0.00 |
| EC-061 | specs/behavioral-contracts/ss-08/BC-2.08.001.md:66 | `[x](#Setup)` where `## Setup` exists | `#NoSpace` (no space after `#`) | 0.00 |
| EC-062 | specs/behavioral-contracts/ss-08/BC-2.08.001.md:67 | `[x](#no-such-anchor)` | `<a name="legacy"></a>` | 0.00 |
| EC-063 | specs/behavioral-contracts/ss-08/BC-2.08.002.md:84 | `[x](docs/api.md#overview)` where `docs/api.md` has `## Overview` | `<h2 id="custom">T</h2>` | 0.00 |
| EC-064 | specs/behavioral-contracts/ss-08/BC-2.08.002.md:85 | `[x](docs/api.md#nope)` where `docs/api.md` has no such heading | `## Title {#custom}` | 0.00 |
| EC-066 | specs/behavioral-contracts/ss-05/BC-2.05.003.md:61 | `<a name="custom-anchor">` | YAML front matter `title: Foo` + `[x](#foo)` | 0.00 |
| EC-067 | specs/behavioral-contracts/ss-05/BC-2.05.003.md:62 | `<span id="api-reference">` | `## setup` | 0.00 |
| EC-071 | specs/behavioral-contracts/ss-11/BC-2.11.001.md:69 | `--ignore 'vendor/**'` excludes all files under `vendor/` | `## setup` | 0.00 |
| EC-077 | specs/behavioral-contracts/ss-09/BC-2.09.001.md:58 | `https://example.com/path?q=1&r=2#frag` | Returns 200 to HEAD | 0.00 |
| EC-078 | specs/behavioral-contracts/ss-09/BC-2.09.001.md:59 | `http://` (no host) | Returns 405 to HEAD, 200 to GET | 0.00 |
| EC-081 | specs/behavioral-contracts/ss-10/BC-2.10.005.md:61 | URL to non-existent hostname `https://this-domain-does-not-exist-xyz-123.com` | Returns 500 | 0.00 |
| EC-082 | specs/behavioral-contracts/ss-09/BC-2.09.001.md:60 | `https://user:pass@host.com/path` | Returns 429 with `Retry-After: 60` | 0.00 |
| EC-083 | specs/behavioral-contracts/ss-09/BC-2.09.001.md:61 | `https://[::1]:8080/path` (IPv6) | Returns 401 to HEAD, 401 to GET | 0.00 |
| EC-084 | specs/behavioral-contracts/ss-09/BC-2.09.001.md:62 | `https://xn--nxasmq6b.com` (Punycode) | Hangs 30s | 0.00 |
| EC-085 | specs/behavioral-contracts/ss-10/BC-2.10.001.md:68 | HEAD succeeds (200) | Redirect chain of 12 hops | 0.00 |
| EC-086 | specs/behavioral-contracts/ss-10/BC-2.10.001.md:69 | Both HEAD and GET return 404 | 301 → `http://a.com/page` → 200 | 0.00 |
| EC-088 | specs/behavioral-contracts/ss-10/BC-2.10.002.md:133 | HTTP 503 | DNS NXDOMAIN | 0.00 |
| EC-124 | specs/behavioral-contracts/ss-12/BC-2.12.001.md:62 | Multiple findings in same file | `docs/a.md` exists; broken link inside | 0.00 |
| EC-126 | specs/behavioral-contracts/ss-12/BC-2.12.002.md:60 | Piped stdout without CLICOLOR_FORCE | `README.md` with broken link | 0.00 |
| EC-127 | specs/behavioral-contracts/ss-12/BC-2.12.002.md:61 | NO_COLOR=1 set | `a.md` and `b.md` both broken | 0.00 |
| EC-130 | specs/behavioral-contracts/ss-12/BC-2.12.003.md:62 | 3 broken links in 2 files | `[x](https://example.com/x)` | 0.00 |
| EC-131 | specs/behavioral-contracts/ss-12/BC-2.12.003.md:63 | 0 broken, 2 indeterminate | `[x](https://example.com/x)` (offline) | 0.00 |
| EC-134 | specs/behavioral-contracts/ss-12/BC-2.12.004.md:57 | `--format text` | One of each OFFLINE reason type: file-not-found, target-is-directory, broken-sym | 0.00 |
| EC-135 | specs/behavioral-contracts/ss-12/BC-2.12.004.md:58 | `--format xml` | Broken link found; diagnostic also occurs | 0.00 |
| EC-142 | specs/behavioral-contracts/ss-14/BC-2.14.001.md:64 | Scan with 0 findings | Only an unreadable file | 0.00 |

---

## Disposition

**ADJUDICATED-ACCEPTED-NOT-FIXED, all 39 items.** Authority: operator ruling at gate #58 (D-244 closed-world condition) plus the follow-on ruling recorded as D-246. These are NOT behavioral-contract defects. Each listed BC documents a genuine, correct edge case; the EC REGISTRY (`specs/prd-supplements/test-vectors.md`) simply has no entry for that scenario, so the BC's EC citation points at an unrelated vector. The remedy is registry ADDITIONS, which the operator ruled out of scope for this run.

---

## Why re-pointing cannot fix most of these

For many items the semantically-correct registry EC is ALREADY cited by a DIFFERENT BC for a DIFFERENT scenario, so re-pointing would merely relocate the collision. Documented instances: EC-077 (correct for BC-2.10.001's "HEAD succeeds (200)") is held by BC-2.09.001; EC-088 (correct for BC-2.10.005's NXDOMAIN) is held by BC-2.10.002; EC-124 (closest to BC-2.11.001's recursive `--ignore` glob) is held by BC-2.12.001; EC-144 and EC-145 (correct for BC-2.12.002's piped-output and NO_COLOR rows) are held by BC-2.14.003; EC-132 (correct for BC-2.12.004's `--format xml`) is held by BC-2.12.003. **The EC id space is therefore non-injective across BCs — the defect the checker is named for exists in the registry itself, not only in the citations.**

---

## Required registry additions — backlog

Closing this properly needs roughly 39 new EC entries with real test vectors. The 13 explicitly identified for ss-10..ss-14 are:

1. HEAD succeeds (200) in the HEAD-then-GET protocol (independent of EC-077 which is held by BC-2.09.001)
2. Both HEAD and GET return 404 → broken
3. HTTP 503 → indeterminate
4. URL to NXDOMAIN hostname (independent of EC-088 which is held by BC-2.10.002)
5. `--ignore 'vendor/**'` recursive glob exclusion (independent of EC-124 which is held by BC-2.12.001)
6. Multiple findings in one file with deterministic sort order
7. Piped stdout → no ANSI colour (independent of EC-144 which is held by BC-2.14.003)
8. NO_COLOR=1 suppresses colour (independent of EC-145 which is held by BC-2.14.003)
9. N broken links in M files summary line
10. 0 broken plus N indeterminate summary line
11. `--format text` explicit alias accepted
12. `--format xml` → exit 2 usage error (independent of EC-132 which is held by BC-2.12.003)
13. Scan with 0 findings → exit 0

The ss-05..ss-09 set needs comparable entries covering: baseline space-to-hyphen slugging, `+` character stripping, inline-bold stripping, consecutive-space slugging, empty-heading slug, emoji adjacent to a word, the 0-based collision counter at 2 and 3 duplicates, `./` current-dir and `sub/` forward relative paths, above-root traversal to a missing target, `%20` in a bare filename, percent-encoded path combined with a fragment, self-file case-sensitive anchor mismatch, self-file anchor-not-found, cross-file anchor found and not-found, and the offline URL forms: query-plus-fragment, scheme-without-host, auth credentials in URL, IPv6 literal, and Punycode/IDN domain.

---

## Residual risk — read this before Phase 2

**A story or test writer who follows an EC citation in any of these 39 BC rows will land on a test vector that tests something else.** Mitigation, binding for Phase 2 and Phase 3: **the BC's own scenario text is AUTHORITATIVE; the cited EC id in these rows is NOT.** Trace acceptance criteria from the BC row's scenario text, never from the cited EC.

Also note that `check-ec-injectivity.py`'s count is a LOWER BOUND (D-126, Jaccard buckets surface ~40% where semantic review found ~64%), so 39 is a floor, not a total.
