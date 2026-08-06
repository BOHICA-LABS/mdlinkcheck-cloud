---
document_type: adversarial-review
level: ops
version: "1.0"
status: final
producer: adversary
phase: phase-1d
pass: 1
timestamp: "2026-08-05T00:00:00Z"
inputs:
  - .factory/specs/prd.md
  - .factory/specs/prd-supplements/
  - .factory/specs/behavioral-contracts/
  - .factory/specs/architecture/
  - .factory/specs/domain-spec/
  - .factory/specs/verification-properties/
  - .factory/specs/invariants.md
  - .factory/specs/assumptions.md
  - .factory/specs/nfr-catalog.md
  - .factory/BRIEF.md
traces_to: ""
---

## Provenance

The adversary agent authored these findings using a fresh-context, read-only tool
profile (`Read`, `Grep`, `Glob` only; `Write`, `Edit`, and `Bash` denied). It
reviewed the spec package without access to any prior review pass, session history,
or implementation artifacts. The spec-steward agent persisted this output verbatim
without editorial change — no findings were reworded, reordered, softened, or
summarised. This document is an evidence artifact for the Phase 1d convergence loop.

---

# Adversarial Spec Review — mdlinkcheck — Pass 1

## CRITICAL Findings

### F-001 — ADR-007 is an accepted ADR that contradicts frozen-brief R7, invents 5 reason codes, and inverts two verdict classes
**Files:** `.factory/specs/architecture/decisions/ADR-007-three-verdict-model.md:40-48, 57, 30-38, 5-6, 64, 94, 104`
**Confidence: HIGH**

`ADR-007` has `status: accepted` and is the architectural source of truth for the verdict model. It is wrong on five independent axes:

1. **Line 47:** `"DI-011 specifies exit code 2 for broken findings; exit code 0 when all findings are alive or indeterminate."` The frozen brief R7 (`BRIEF.md:29-30`), DD-006 (`decisions.md:35`, binding human decision), `DI-011` (`invariants.md:143-150`), and `BC-2.14.003` (`ss-14/BC-2.14.003.md:31,45`) all specify exit **1** for broken links. ADR-007 also never mentions exit 1 at all.
2. **Lines 42-45:** reason codes `http-client-error`, `http-server-error`, `http-rate-limited`, `dns-resolution-failure`, `ssl-tls-error`. **None of these five exist** in the closed taxonomy (`error-taxonomy.md:83`, `failure-modes.md:28-42`), which uses `http-error`, `http-indeterminate`, `dns-failure`, `tls-error`. Line 85 then says these codes `"must not be modified without an ADR update"`.
3. **Line 34/45:** DNS failure and TLS error are placed in **`indeterminate`**. `BC-2.10.005:44-50` states `"Verdict: broken. Reason: dns-failure"` and `"DNS failure is broken, not indeterminate (unlike timeout or 5xx)"`; `error-taxonomy.md:62-63` assigns both to `broken`/exit 1.
4. **Lines 40, 57, 84:** `"nine closed reason codes"` — the taxonomy has 13. ADR-007's enumeration silently drops `malformed-url` (DD-010, the only P0 offline URL behavior), `too-many-redirects`, `target-is-directory`, `broken-symlink`, `target-unreadable`.
5. **Line 36:** `"All three verdicts appear in JSON output"` — `BC-2.13.001:45,52` and `interface-definitions.md:183` state `verdict` is `"broken"|"indeterminate"`, **never** `clean`/`alive`.

Additional mis-anchors in the same file: `subsystems_affected: [SS-08, SS-09, SS-11]` (line 6) — the verdict model belongs to SS-10 and SS-14; SS-11 is Filter Application. `VP-007` is cited three times (lines 48, 71, 104) as proving the *exit-code* mapping — `vp-007-http-verdict-total.md:35` proves `classify_response(status, attempt)` totality and never touches exit codes (that is VP-005/VP-006). `DD-015` is cited twice (lines 64, 105) as the source of `--strict-indeterminate` and retry flags — DD-015 is the github-slugger algorithm decision (`decisions.md:49`).

**Failure scenario:** An implementer building SS-10/SS-14 from the accepted ADR ships `mdlinkcheck` returning **exit 2 for broken links** and emitting `reason: "dns-resolution-failure"`. Every CI integration that distinguishes 1 from 2 breaks, NFR-007 (closed-taxonomy conformance) fails, and DNS/TLS failures stop failing the build at all. Because ADR-007 is `accepted`, it outranks the BCs in an architecture-first reading.
**Owner:** architect (rewrite ADR-007 against `error-taxonomy.md` + R7); spec-steward (add a BC↔ADR verdict/exit-code consistency check).

---

### F-002 — BC-2.07.003's own canonical test vector contradicts its Invariant 2, DI-002, DEC-004, TV-037, FM-007, and ADR-006
**Files:** `.factory/specs/behavioral-contracts/ss-07/BC-2.07.003.md:47, 67` vs `:46, 51`; `domain-spec/edge-cases.md:66-74`; `prd-supplements/test-vectors.md:98`; `domain-spec/failure-modes.md:57`; `architecture/decisions/ADR-006-strict-path-model.md:55-58`
**Confidence: HIGH**

`BC-2.07.003:51` (Invariant 2): *"NFC normalization is applied to both sides: the link destination AND the directory entry names."* Under that rule, an NFD destination and an NFC directory entry both normalize to the same NFC string and must match.

But `BC-2.07.003:67` (Canonical Test Vectors, row 4) states:

```
| `cafe\u{301}.md` (NFD) | `café.md` (NFC on disk) | broken (file-not-found) on case-sensitive comparison |
```

and PC4 (`:47`) hedges: *"succeeds ONLY if directory entry is NFC-identical."* Every other artifact says the opposite:
- `edge-cases.md:71-72` DEC-004: *"NFC-normalize both the destination and the real directory entry before comparison. Must resolve `clean` on all platforms."*
- `test-vectors.md:98` TV-037: NFC link → NFD disk → **exit 0, clean**.
- `failure-modes.md:57` FM-007 lists *"NFC/NFD mismatch: macOS-created file fails on Linux"* as a **failure mode violating DI-002**.
- `ADR-006:55-58`: *"A link `résumé.md` stored as NFC and an anchor stored as NFD are the same logical path. Without NFC normalization, these would compare unequal."*

The row's justification ("on case-sensitive comparison") conflates case-sensitivity with normalization form — they are orthogonal. Note also that BC-2.07.003 and TV-037 test **opposite directions** (NFC→NFD vs NFD→NFC), so the two are not even symmetric.

**Failure scenario:** A test-writer generating unit tests from BC-2.07.003's canonical vector table asserts `broken` for `[x](cafe\u{301}.md)` → `café.md`. TV-037 asserts `clean` for the mirror case. Both land in the suite; the implementation cannot satisfy both, and whichever is written first hard-codes FM-007 — the exact macOS→Linux CI divergence the product's KD-004/differentiator claim eliminates.
**Owner:** product-owner (fix BC-2.07.003 row 4 and PC4 to `clean`, add the mirror-direction vector).

---

### F-003 — BC-2.08.002 PC4 and BC-2.07.006 assign opposite verdicts to `[x](notes.txt#section)`
**Files:** `.factory/specs/behavioral-contracts/ss-08/BC-2.08.002.md:48` vs `ss-07/BC-2.07.006.md:49-51`
**Confidence: HIGH**

`BC-2.08.002:48` (PC4): *"If resolved path exists as a file but the fragment is not in its anchor table: broken (`anchor-not-found`)."* No carve-out for non-Markdown targets.

`BC-2.07.006:49-51` (PC1-3): *"Verdict: `clean`. The fragment (if any) is silently ignored... `anchor_resolver.rs` (SS-08) is never called for this link."*

`[x](notes.txt#section)` satisfies **both** BCs' preconditions (BC-2.08.002 PC1 "classified as cross-file-anchor"; BC-2.07.006 PC1-3 "exists as a regular file, extension not .md"). BC-2.08.002 entails `broken`; BC-2.07.006 entails `clean`. This violates DI-005 (one verdict per link) at the *specification* level.

Ground truth is `clean`: `edge-cases.md:117-125` DEC-008 (T10), `test-vectors.md:139-140` TV-072/TV-073.

`BC-2.07.006:97` claims *"BC-2.08.002 — depends on this (cross-file anchor links to non-.md targets are handled HERE, not in BC-2.08.002)"* — but BC-2.08.002 was never amended. This is a **partial-fix propagation gap from PRD v1.1 SF-002**: SF-002 created BC-2.07.006 and rewrote BC-2.07.005 but left the sibling BC-2.08.002 untouched. The same gap applies to directory targets: `BC-2.07.005:58,61-62` says *"anchor_resolver.rs is NEVER called for a directory target"* and *"path_resolver.rs is the sole decision point for directory targets"*, while `BC-2.08.002:47` (PC3) assigns the `target-is-directory` verdict inside SS-08.

**Failure scenario:** Story-writer generates an SS-08 story from BC-2.08.002 and an SS-07 story from BC-2.07.006. The SS-08 story's acceptance test asserts `anchor-not-found` for `notes.txt#section`; the SS-07 story asserts `clean`. Both stories pass their own gates, and integration produces the T10 false positive (`prevents false anchor-not-found on links to code files, images, PDFs`) that KD-001 is sold on.
**Owner:** product-owner (add non-.md and directory carve-outs to BC-2.08.002 PC3/PC4 pointing at BC-2.07.005/006).

---

### F-004 — PRD §2.9–§2.14 BC titles are wholly drifted from the BC file H1s; the drift hides at least five uncontracted behaviors
**Files:** `.factory/specs/prd.md:188-250` vs `behavioral-contracts/BC-INDEX.md:121-181` and the BC files themselves
**Confidence: HIGH**

PRD v1.1's SF-002 fix (`prd.md:453-464`) corrected §2.5 and §2.8 titles to match BC H1s. **It did not touch §2.9–§2.14.** BC H1 is authoritative per `BC-INDEX.md:21-22` (`bc_h1_is_title_source_of_truth`). Verified mismatches:

| BC | PRD §2 title | Actual H1 (verified) |
|----|--------------|----------------------|
| BC-2.10.005 | `URL deduplication: fetch once, report at every occurrence` | `DNS Resolution Failure Yields broken Verdict` (`ss-10/BC-2.10.005.md:31`) |
| BC-2.10.006 | `Redirect following: max 10 hops, loop detection, downgrade warning` | `TLS Handshake Failure Behavior` (BC-INDEX:139) |
| BC-2.10.007 | `Concurrency: 32 global / 4 per-host` | `Redirect Chain Handling (Max 10 Hops)` (BC-INDEX:140) |
| BC-2.10.008 | `Private/loopback IP ranges and TLS errors classified appropriately` | `Concurrency — 32 Global / 4 Per-Host Request Limits` (`ss-10/BC-2.10.008.md:31`) |
| BC-2.12.002 | `Stdout (findings) / stderr (diagnostics + summary) separation` | `Terminal Color Output with NO_COLOR / CLICOLOR / CLICOLOR_FORCE` (`ss-12/BC-2.12.002.md:31`) |
| BC-2.12.003 | `ANSI color suppression: non-TTY, NO_COLOR, CLICOLOR=0` | `Stderr Summary Line (Unless --quiet)` (BC-INDEX:161) |
| BC-2.12.004 | `Summary line on stderr: N broken link(s) in M file(s).` | `--format text Explicit Alias Is Accepted` (BC-INDEX:162) |
| BC-2.13.002 | `Empty result: {...results: []}. Indeterminate findings included.` | `JSON Schema Stability Contract` (BC-INDEX:171) |
| BC-2.14.001 | `Exit code 0/1/2 as pure function of verdict multiset and I/O error state` | `Exit Code 0 — No Broken Links` (`ss-14/BC-2.14.001.md:31`) |
| BC-2.14.003 | `--help and --version exit 0 without scanning` | `Exit Code 1 — At Least One Broken Link Found` (`ss-14/BC-2.14.003.md:31`) |
| BC-2.09.002 | `Fragment on external URL ignored; --allow suppresses validation` | `--allow Suppresses External URL Checks` (`ss-09/BC-2.09.002.md:31`) |
| BC-2.11.003 | `Flag edge cases: explicit path vs --ignore, repeated --ignore, invalid glob` | `--ignore on Explicit PATH Argument` (`ss-11/BC-2.11.003.md:31`) |

This is not cosmetic. It conceals real coverage holes — I grepped the entire `behavioral-contracts/` tree and **no BC exists** for:
- **URL deduplication** (fetch once, report at every occurrence) — required by TV-090/EC-090 (`test-vectors.md:162`, 50 occurrences → one fetch). Grep for `dedup` in `behavioral-contracts/` returns only BC-2.01.002/007 (*path* dedup) — nothing for URLs.
- **Private/loopback IP classification** — TV-089 (`test-vectors.md:161`) expects `indeterminate (private IP)`; no BC, and no reason code in the closed set covers it.
- **stdout/stderr separation for the `text` format.** `interface-definitions.md:100-103` calls this an **Invariant** and DD-014 (`decisions.md:48`) says *"never mix"*. Only `BC-2.13.001:54` covers it, and only for JSON.
- **`--help`/`--version` exit 0 without scanning** — PRD §2.14 assigns it to BC-2.14.003, but BC-2.14.003 is the exit-1 contract. TV-138/TV-138b (`test-vectors.md:222-223`) have no BC.
- **Invalid `--ignore` glob → exit 2** — PRD §2.11.003 claims it; BC-2.11.003 covers only explicit-PATH interaction. No test vector either.
- **Fragment on an external URL is ignored** — PRD §2.09.002 claims it; BC-2.09.002 does not mention fragments.

**Failure scenario:** Story-writer builds the wave plan from PRD §2 (the index document, per `prd.md:25-27`). It creates a story "BC-2.10.005 — URL deduplication" and finds a BC file about DNS. It creates "BC-2.14.003 — --help/--version" and finds the exit-1 contract. Either the story is unbuildable, or the writer implements from the PRD title and produces a BC-less feature with no acceptance criteria. Meanwhile `--online` re-fetches the same URL 50×, and `mdlinkcheck --format json > report.json` has no contract preventing diagnostics on stdout.
**Owner:** product-owner (regenerate PRD §2.9–§2.14 from BC H1s; author the 6 missing BCs); spec-steward — `[process-gap]` the PRD-§2↔BC-H1 sync check should be automated, since SF-002 fixed two of eight drifted sections and the remaining six survived a full revision cycle.

---

### F-005 — BC-2.05.001's two-pass design is circular, and anchor targets outside the scan set get no anchor table (DI-006 covers only `--ignore`)
**Files:** `.factory/specs/behavioral-contracts/ss-05/BC-2.05.001.md:43, 45-46, 51`; `domain-spec/invariants.md:85-93`; `test-vectors.md:57`
**Confidence: HIGH**

`BC-2.05.001:43` (PC1): *"After Pass 1: every file in the scan set **plus any files referenced as anchor targets that are readable** has a complete anchor table in memory."*
`BC-2.05.001:45-46` (PC3/PC4): *"No link validation occurs during Pass 1. No anchor table construction occurs during Pass 2."*
`BC-2.05.001:51` (Inv 3): *"The two passes are strictly sequenced; they do not interleave."*

These are mutually unsatisfiable. You cannot know which files are "referenced as anchor targets" without extracting links — and link extraction is validation-adjacent work whose results are only available after Pass 1 completes. PC1 requires an on-demand table build for out-of-scan-set targets; PC4 and Inv 3 forbid any table construction after Pass 1. The design as specified needs three phases (discover → extract links + headings → resolve), and no BC or ADR describes that.

Worse, **DI-006 (`invariants.md:85-93`) is scoped to `--ignore` only.** Files excluded by other mechanisms are not covered:
- `.gitignore`/`.ignore` exclusion (BC-2.01.003) — `test-vectors.md:57` TV-002 puts 1000 `.md` files in `node_modules/` behind `.gitignore`.
- Dot-directory skip (BC-2.01.004) without `--hidden`.
- Files whose extension is not `.md`/`.markdown` but which *are* Markdown.

**Failure scenario:** `README.md` contains `[usage](node_modules/somepkg/README.md#usage)`. `node_modules/` is `.gitignore`d, so it is not in the scan set. If the implementer honors PC4/Inv 3 (no table construction in Pass 2), no anchor table exists for the target, and `BC-2.08.002:48` (PC4) yields `broken (anchor-not-found)` → **exit 1**. This is a false positive of precisely the DI-006/FM-010 class ("the opposite of the user's intent"), it is not caught by any test vector, and it fires on any repo that links into vendored or generated docs. There is no vector anywhere in `test-vectors.md` for a cross-file anchor into a `.gitignore`d or dot-dir target.
**Owner:** business-analyst (widen DI-006 from `--ignore` to *all* source-exclusion mechanisms); architect (specify the actual phase structure and resolve the PC1/PC4 circularity); product-owner (add test vectors for anchors into `.gitignore`d and dot-dir targets).

Secondary: `BC-2.05.001:57` cites **EC-049** as *"Large file scanned in parallel"*. EC-049 is the reserved **holdout** duplicate-heading collision case (`prd.md:320`, `edge-cases.md:29-38` DEC-001, `test-vectors.md:107` "excluding EC-049").

---

### F-006 — BC-2.10.002 claims verdict exhaustiveness but does not partition the status space; VP-007 is true by construction
**Files:** `.factory/specs/behavioral-contracts/ss-10/BC-2.10.002.md:43-54`; `error-taxonomy.md:61`; `verification-properties/vp-007-http-verdict-total.md:39, 64-71`; `test-vectors.md:155, 158, 161`
**Confidence: HIGH**

`BC-2.10.002:54` (Inv 3): *"The three verdicts are exhaustive — every HTTP outcome maps to exactly one."* `:53` (Inv 2): *"Only 404 and 410 (after fallback) are definitively broken HTTP responses."* But the postconditions (`:43-49`) map only 2xx, 404, 410, 429, 5xx, timeout. Unmapped, with a concrete conflicting vector for each:

| Outcome | Conflicting source | Verdict per BC-2.10.002 |
|---|---|---|
| **400 after GET fallback** | `error-taxonomy.md:61` says `http-error` = **broken** ("404, 410, or **400 after GET fallback**") | Inv 2 forbids it being broken → **undefined** |
| **401** | `test-vectors.md:155` TV-083 expects `indeterminate` | no reason code exists (`http-indeterminate` = "429, 5xx, or bot-blocking 403/999") → **undefined** |
| **Private/loopback IP** | `test-vectors.md:161` TV-089 expects `indeterminate (private IP)` | no PC, no reason code |
| **https→http downgrade** | `test-vectors.md:158` TV-086 expects `indeterminate (downgrade warning)`; AMB-037 (`prd.md:265`) | no PC, no reason code |
| **`--insecure` TLS skip** | `BC-2.10.002:49` PC7 says `indeterminate`; AMB-042 (`prd.md:268`) | no reason code |
| **Connection reset before response** | `error-taxonomy.md:66` folds it into `http-indeterminate` | `BC-2.10.002:47` PC5 defers to "BC-2.10.007" which is *Redirect Chain Handling* → no owner |

`VP-007` is supposed to close this. It does not. `vp-007:64-71`:

```rust
match &verdict.kind {
    VerdictKind::Alive => {},
    VerdictKind::Broken(_) => {},
    VerdictKind::Indeterminate(_) => {},
}
```

This assertion is **guaranteed by Rust's type system** — a function returning `Verdict` cannot return anything else, and a `match` with a catch-all arm cannot panic. VP-007 proves nothing about *which* verdict any status maps to. It is unfalsifiable: no implementation satisfying the type signature can fail it. It also carries F-001's error (`:39` "closed 9-reason-code taxonomy" — there are 13) and mis-anchors its source BC title (`:43` "BC-2.10.002 — HTTP Response Classification"; actual H1 is "Three-Verdict Model (alive/broken/indeterminate)"), and contradicts itself on bounds (`:39` restricts to `0..=999`; `:59` says "No assumption needed — must be total for ALL u16 values").

**Failure scenario:** An implementer writes `classify_response` with `_ => Indeterminate(HttpIndeterminate)`. VP-007 passes. A genuinely dead link returning `400` after GET fallback is reported `indeterminate` → **exit 0** → the CI gate silently stops catching a whole class of broken links, while NFR-007's parsing test still passes because `http-indeterminate` is in the closed set. The one Kani proof allegedly guarding this is inert.
**Owner:** product-owner (make BC-2.10.002's PCs a total partition of `0..=599` plus transport outcomes; add reason codes for private-IP, downgrade, and `--insecure`, or explicitly reuse `http-indeterminate` with documented triggers); architect (rewrite VP-007 to assert the *mapping*, e.g. `status==400 && attempt==GET ==> matches!(v, Broken(HttpError))`, not variant membership).

---

## MAJOR Findings

### F-007 — Every one of the 59 BC files has `VP-TBD` placeholders; the BC↔VP linkage does not exist in either direction
**Files:** all 59 files in `.factory/specs/behavioral-contracts/`; `verification-properties/VP-INDEX.md`
**Confidence: HIGH**

`grep -c VP-TBD` across `behavioral-contracts/` returns **99 occurrences across 59 files** — i.e. 100% of BCs. Phase 1b produced 20 real VPs (`VP-INDEX.md:37-56`) with `source_bc` frontmatter, but no BC file was back-filled. `VP-INDEX.md` has a "DI Coverage Summary" (`:60-74`) and a "Per-Module VP Count" (`:78-90`) but **no BC coverage table**, so the VP→BC direction is only discoverable by opening 20 files, and the BC→VP direction is entirely absent. 39 of 59 BCs have no VP at all.

**Failure scenario:** Story-writer opens `BC-2.06.001.md:90-95` to derive verification obligations and finds three `VP-TBD` rows. It either invents ad-hoc properties (diverging from VP-001/002/003/012/018, which actually exist for the `slug` module) or emits none. The Phase 6 proof record — differentiator #3 in `prd.md:53-54` — cannot be assembled because no BC declares which VP discharges it.
**Owner:** architect (back-fill real VP IDs into all 59 BC Verification Properties tables; add a BC→VP coverage table to VP-INDEX); spec-steward — `[process-gap]` no gate rejects a BC with `VP-TBD` after Phase 1b completes.

---

### F-008 — Systematic `EC-NNN` mis-anchoring across BC files, plus holdout leakage into visible artifacts
**Files:** BC files across ss-05/06/07/09/12/13/14 vs `test-vectors.md`; `prd.md:320`; `domain-spec/assumptions.md:44`
**Confidence: HIGH**

BC files cite `EC-NNN` IDs that mean something entirely different in the canonical list. Verified collisions:

| BC file:line | EC cited | BC's meaning | Canonical meaning (test-vectors.md) |
|---|---|---|---|
| `ss-07/BC-2.07.003.md:57-59` | EC-029/030/031 | case mismatch / NFC-NFD / Unicode case | `[x](docs/)` / `[x](docs)` / `[x]()` (`:91-93`) |
| `ss-06/BC-2.06.001.md:74-79` | EC-043..048 | Hello World / C++ / 日本語 / bold / two-space / empty | AI & Automation ×2, hyphens, colon+parens, Setup×2, Setup×3 (`:111-116`) |
| `ss-06/BC-2.06.002.md:60-63` | EC-055..058 | Setup×2 / Setup+Setup 1 / Setup×3 / A×4 | `## Done ✅` / bold / code / link-in-heading (`:122-125`) |
| `ss-09/BC-2.09.002.md:57-59` | EC-090/091/092 | allow-match / evil.tld / exact match | URL ×50 dedup / allow-match / evil.tld (`:162-164`) — off by one |
| `ss-12/BC-2.12.002.md:57-59` | EC-126/127/128 | piped / NO_COLOR / CLICOLOR_FORCE | `--ignore README.md` / repeated `--ignore` / `!keep.md` (`:210-212`) |
| `ss-13/BC-2.13.001.md:60-62` | EC-138/139/140 | no findings / piped JSON / mixed verdicts | `--help` / `-- -weird-name.md` / flag-after-positional (`:222-225`) |
| `ss-14/BC-2.14.001.md:56-58` | EC-142, EC-009 | 0 findings; empty dir | EC-142 = **only an unreadable file → exit 2** (`:226`); empty dir is EC-011 (`:66`) |
| `ss-14/BC-2.14.003.md:57-59` | EC-144/145/146 | 1 broken / 100 broken / indeterminate | piped-no-ANSI / NO_COLOR / **SIGINT** (`:228-230`) |
| `ss-11/BC-2.11.003.md:56` | EC-073b | `--ignore` on explicit PATH | EC-073 = `src/main.rs#L42-L50` (`:140`) |
| `ss-10/BC-2.10.002.md:59-61` | EC-087/088/089 | 429 / 503 / 410 | 401-auth / 5xx / redirect-12-hops region (`:155-157`) |
| `ss-10/BC-2.10.005.md:56` | EC-081 | NXDOMAIN | EC-081 = **500 → indeterminate** (`:153`) |

`BC-2.14.001:56` is the sharpest: it asserts **EC-142 → exit 0**, while `test-vectors.md:226` asserts **EC-142 → exit 2** and `decisions.md:41` (DD-007) cites EC-142 as an exit-precedence case. The same EC ID carries opposite expected exit codes.

**Holdout leakage.** `prd.md:320` reserves EC-036, EC-049, EC-074, EC-079, EC-093, EC-094, EC-102, EC-141, EC-147, EC-148 as holdout, *"NOT in the visible test suite."* Yet:
- `BC-2.07.003.md:64` gives the full EC-036 vector (`readme.md` vs `README.md` → broken), and `edge-cases.md:129-139` DEC-009 spells it out verbatim while tagging itself `[HOLDOUT]`.
- `BC-2.12.001.md:59-60` cites EC-147 and EC-148 as edge cases.
- `BC-2.05.001.md:56`, `BC-2.08.002.md:62`, `BC-2.08.004.md:57` all give the full EC-074 vector.
- `BC-2.10.002.md:62` gives EC-093 (bot-blocking 403).
- **`test-vectors.md:34-48` §0 TV-BV013 *is* DEC-006 = EC-102 = EC-148**, and says *"It must be in the standard test suite"* — directly contradicting `prd.md:320` and `edge-cases.md:100`.
- `assumptions.md:44`: *"Holdout candidates (ASM-005, ASM-008) must NOT be visible in the standard test suite"* — but ASM-008's validation method is the DD-015 worked examples, which are fully enumerated in `test-vectors.md:238-256` (16 vectors) and mandated by NFR-006 to run *"on every commit"* (`nfr-catalog.md:121`).

**Failure scenario (mis-anchor):** Test-writer generates a fixture for "BC-2.14.001 EC-142: scan with 0 findings → exit 0" and another for "TV-142 EC-142: only an unreadable file → exit 2". Two fixtures, same ID, opposite assertions — one silently overwrites the other in the corpus manifest keyed by EC ID.
**Failure scenario (holdout):** The pilot's holdout evaluation is the mechanism for measuring whether VSDD produced correct behavior without teaching to the test. Since 6 of 10 holdout ECs are fully specified in visible BCs and one is the headline visible vector, the holdout measurement is invalid — a passing holdout score proves nothing.
**Owner:** spec-steward (re-anchor every `EC-NNN` in BC files to the canonical list, or renumber BC-local cases as `BC-EC-*`); product-owner (decide whether TV-BV013/DEC-006 is holdout or visible — it cannot be both; strip holdout content from BC-2.07.003, BC-2.12.001, BC-2.05.001, BC-2.08.002/004, BC-2.10.002, and reconcile ASM-005/ASM-008). `[process-gap]` — nothing validates that a BC's cited edge-case IDs exist and mean the same thing in the canonical list, and nothing enforces the holdout boundary.

---

### F-009 — BC-2.06.002's stated collision rule is false for one ordering, and its counter semantics contradict DD-015
**Files:** `.factory/specs/behavioral-contracts/ss-06/BC-2.06.002.md:36-38, 45-50, 42` vs `domain-spec/decisions.md:49` (DD-015)
**Confidence: HIGH**

**(a) "wherever it appears" is wrong.** `BC-2.06.002:50` (PC3): *"`## Setup 1` (**wherever it appears in document order**) → `setup-1-1`."* This contradicts Inv 3 (`:56` "Processing order is document order") and is false when `## Setup 1` comes first. Tracing github-slugger v2 with `## Setup 1`, `## Setup`, `## Setup`: `Setup 1`→`setup-1`; `Setup`→`setup`; second `Setup`→ candidate `setup-1` is taken → bumps to **`setup-2`**. Result is `setup-1, setup, setup-2` — no `setup-1-1` anywhere. The slug set is order-dependent; the BC asserts it is not.

**(b) Counter test is containment vs value.** DD-015 (`decisions.md:49`) mandates *"0-based per-file duplicate counter via `while(occurrences contains result)` loop"* — a **key-containment** test, with keys initialized to 0. `BC-2.06.002:45-46` (PC1/PC2) instead specifies a **value** test: *"If `occurrences[slug]` is 0: use slug as-is; set `occurrences[slug] = 1`... If `occurrences[slug]` >= 1: try `{slug}-{count}`... update occurrences for both the original and the candidate."* Under containment semantics a slug stored with value 0 **is** present and must bump; under BC-2.06.002's value semantics a slug stored as 0 is treated as unused. PC2's *"update occurrences for both"* never says by what value, so the third-duplicate index is undefined.

**Failure scenario:** An implementer follows BC-2.06.002 PC1/PC2 literally and initializes to 1. The canonical `## Setup`×2 + `## Setup 1` case still passes (it is the only vector), but any file where a heading's slug was seeded at 0 by a *different* heading (see F-029) silently mis-numbers — reproducing **FM-002** (`failure-modes.md:52`, "counter is 1-based instead of 0-based"), the failure mode this BC exists to prevent. No vector in `test-vectors.md:238-256` exercises the `## Setup 1`-first ordering.
**Owner:** product-owner (delete "wherever it appears", add the `Setup 1`-first vector with `setup-1/setup/setup-2`, and restate PC1/PC2 as DD-015's containment loop with keys initialized to 0).

---

### F-010 — BC-2.10.008 PC1 (32 in-flight) contradicts its own Invariant 3 on every machine with fewer than 32 cores
**Files:** `.factory/specs/behavioral-contracts/ss-10/BC-2.10.008.md:43, 51, 62-63`; `ADR-004:33-34`; `ADR-005:50-52`; `nfr-catalog.md:57`
**Confidence: HIGH**

`BC-2.10.008:43` (PC1): *"At most 32 HTTP requests are in-flight simultaneously across all hosts."*
`BC-2.10.008:51` (Inv 3): *"Total parallelism does not exceed available rayon thread count."*

ureq is **synchronous** (`ADR-004:26`), so an in-flight request occupies a thread for its whole duration. rayon's default pool is `num_cpus`. On NFR-002's baseline — *"Standard 2-core x86_64 Linux CI runner"* (`nfr-catalog.md:57`) — Inv 3 caps in-flight requests at **2**, not 32. Inv 3 and PC1 cannot both hold. The canonical test vector `BC-2.10.008:63` (*"40 URLs to 40 different hosts | Max 32 simultaneous globally"*) is unachievable there.

Both ADRs specify a **dedicated** 32-thread pool (`ADR-004:33-34` `ThreadPoolBuilder::new().num_threads(32)`; `ADR-005:50-52` *"a dedicated rayon thread pool (separate from the file-scan pool) sized at 32 threads"*), which resolves the tension — but BC-2.10.008 never mentions a dedicated pool, and Inv 3's "available rayon thread count" reads as the global pool.

**Failure scenario:** An implementer honors Inv 3 by wrapping HTTP dispatch in the default global rayon pool. On `ubuntu-latest` (2 vCPU) `--online` runs at 2× concurrency; a repo with 800 external URLs at up to 10s each (`BC-2.10.003`) takes ~66 minutes instead of ~4. The CI job times out, and no test detects it because the concurrency vectors cannot be asserted on the CI runner.
**Owner:** architect (add the dedicated-pool requirement to BC-2.10.008 and delete or restate Inv 3; make the concurrency vectors runnable on a 2-core runner by asserting *observed max concurrent connections at the mock server* rather than thread counts).

---

### F-011 — 12 BCs (all of SS-11..SS-14) still carry `subsystem: "SS-TBD"` after Phase 1b
**Files:** `ss-11/BC-2.11.001-003.md:18`, `ss-12/BC-2.12.001-004.md:18`, `ss-13/BC-2.13.001-002.md:18`, `ss-14/BC-2.14.001-003.md:18`
**Confidence: HIGH**

`prd.md:92-93` says *"Subsystem IDs (SS-NN) are provisional — architect will confirm in Phase 1b."* Phase 1b completed (`VP-INDEX.md:8` `phase: 1b`), `BC-INDEX.md:15` declares `subsystems: 14`, and the files live in `ss-11/`..`ss-14/` — yet the authoritative frontmatter field is unresolved in exactly 12 files. Note the split is clean by subsystem: SS-01..SS-10 are all filled in (verified `ss-10/BC-2.10.002.md:18` = `"SS-10"`), SS-11..SS-14 are all `SS-TBD`.

**Failure scenario:** Any tooling that groups BCs by `subsystem:` frontmatter (wave planning, subsystem-scoped story dispatch, ARCH-INDEX cross-checks) collapses 12 output/exit-code BCs into a single phantom subsystem `SS-TBD`, or drops them. The exit-code contracts — R7, all P0 — are the ones that go missing.
**Owner:** architect (set `subsystem:` to SS-11/12/13/14); spec-steward — `[process-gap]` no gate rejects `SS-TBD` at the Phase 1b exit.

---

### F-012 — Six test vectors have non-deterministic, self-contradictory, or unsatisfiable expected results
**Files:** `.factory/specs/prd-supplements/test-vectors.md:76, 86, 93, 96, 218, 230`
**Confidence: HIGH**

| TV | Line | Problem |
|---|---|---|
| TV-024 | `:86` | `Expected Exit 1` but `Expected Verdict: broken OR clean`. If the verdict is `clean` the exit is 0. The row asserts both. |
| TV-021 | `:76` | `Expected Exit: 0 or 2`, `Verdict: clean or target-unreadable`. Not a test. |
| TV-031 | `:93` | `[x]()` → `malformed-url` **or** `file-not-found`. Violates DI-005 (`invariants.md:75-81`) at spec level; no BC covers an empty destination. |
| TV-034 | `:96` | `[x](a.md/)` where `a.md` is a file → `target-is-directory` **or** `file-not-found`. No BC covers a trailing slash on a regular file. |
| TV-134 | `:218` | Flags are `--format json` only (no `--online`), yet expects *"JSON with all 10 `broken` reason codes"*. Four of the ten (`http-error`, `dns-failure`, `tls-error`, `too-many-redirects`) are unreachable without `--online` (`BC-2.10.001` onward). **Unsatisfiable.** |
| TV-146 | `:230` | SIGINT → exit 2 with partial output. No BC in SS-14 covers signals; contradicts F-016. |

**Failure scenario:** These become golden tests. TV-031/TV-034 are written with whichever reason the implementer chose; a later refactor flips it and the "or" clause means the reviewer cannot tell whether the change is a regression. TV-134 fails on first run and gets `#[ignore]`d — deleting the only coverage of the complete `broken` reason enumeration, which is NFR-007's whole point.
**Owner:** product-owner (pick one verdict per vector and add the missing BCs for empty destination and trailing-slash-on-file; split TV-134 into offline and `--online` halves).

---

### F-013 — `target-unreadable` cannot be represented in JSON output, yet two test vectors assert it as a verdict
**Files:** `BC-2.13.001.md:45`; `interface-definitions.md:183`; `error-taxonomy.md:35, 72`; `prd.md:310`; `test-vectors.md:68-69`
**Confidence: HIGH**

`BC-2.13.001:45` (PC3) and `interface-definitions.md:183`: `verdict` is *"One of: `"broken"`, `"indeterminate"`. Never `"clean"`."* `target-unreadable` has verdict `"— (I/O error)"` (`error-taxonomy.md:72`, `prd.md:310`) — it is none of the three, so no finding object can carry it. `error-taxonomy.md:35` and DD-014 route it to stderr as a diagnostic.

But `test-vectors.md:68-69` TV-013/TV-014 list `target-unreadable` in the **"Expected Verdict"** column for `--format`-agnostic runs, and `test-vectors.md:226` TV-142 asserts exit 2 with no output contract.

**Failure scenario:** The CI Engineer persona (`prd.md:70`, *"needs machine-readable output"*) runs `mdlinkcheck --format json`. A permission-denied file yields exit 2 and `{"schema_version":1,"results":[]}` — a JSON payload indistinguishable from a clean run. The only signal is unstructured English on stderr, which `error-taxonomy.md:93` explicitly declares unstable (*"Test automation must use reason codes, not message strings"*). The primary persona has no stable way to learn *which* file failed to read.
**Owner:** product-owner (add an `errors: [...]` array to the JSON schema, or a fourth `verdict` value; bump nothing since `schema_version: 1` is pre-1.0 per `interface-definitions.md:192`; fix TV-013/TV-014's verdict column).

---

### F-014 — `tests/corpus/manifest.json` schema cannot express the output it is required to match exactly
**Files:** `interface-definitions.md:255-274` vs `:177-188`; `test-vectors.md:317`; `assumptions.md:34` (ASM-007)
**Confidence: HIGH**

`test-vectors.md:317` pass criterion: *"JSON output matches `tests/corpus/manifest.json` **exactly** (modulo ordering...)."* But the manifest's `expected_findings` objects (`interface-definitions.md:261-268`) carry only `line`, `link_target`, `verdict`, `reason` — no `file`, no **`column`**. The tool's finding objects (`:177-188`) require all six, with `column` mandatory.

Consequences: (a) the two shapes can never be `==`, so "matches exactly" is undefined; (b) `test-vectors.md:199` TV-123 (*"Two broken links on same source line... Two findings; different columns"*) is inexpressible in the manifest — two entries would be byte-identical; (c) the sort order the pass criterion invokes (*"which must itself match the sorted order"*) is keyed on `(path, line, column)` (DI-001), and `column` is absent from the manifest.

**Failure scenario:** This is the frozen brief's primary success criterion (`BRIEF.md:39-41`, *"correctly classifies the acceptance corpus"*) and ASM-007's HIGH-impact deliverable. The corpus story is written, the comparison harness cannot be implemented as specified, and the implementer invents a lenient subset-match — at which point false positives on unlisted columns stop being detected, defeating `interface-definitions.md:274` (*"any extra finding is a false positive"*).
**Owner:** product-owner (add `file` and `column` to the manifest `expected_findings` schema and define the exact comparison as a set equality over the six-field tuple).

---

### F-015 — Four CLI flags (`--quiet`, `--offline`, `--insecure`, `--hidden`) have zero BC and zero test vector
**Files:** `interface-definitions.md:46, 62, 63, 71`; `prd.md:258`; `BC-INDEX.md` (no matching entry); `test-vectors.md:205-230`
**Confidence: HIGH**

All four are fully specified in `interface-definitions.md` §2 and listed in `prd.md:258`, but:
- **No BC.** `BC-INDEX.md` SS-11..SS-14 contains no contract for any of them. `BC-2.12.003` ("Stderr Summary Line (Unless `--quiet`)") mentions `--quiet` only as a condition on the summary line.
- **No test vector.** `test-vectors.md` §6 (`:205-230`) covers `--ignore`, `--allow`, `--format`, `--help`, `--version`, `--unknown-flag`, `--` — none of these four.
- **`--hidden` inverts a P0 BC.** `BC-2.01.004` is *"Dot-Directory Skip and Directory-Symlink Non-Following"*; `interface-definitions.md:71` makes that skip conditional and carves out `.git/` unconditionally. That interaction is uncontracted, and `test-vectors.md:58-59` TV-003/TV-004 test only the default.
- **`--insecure` needs a reason code that does not exist.** `interface-definitions.md:63` and AMB-042 (`prd.md:268`) require `indeterminate`; the closed set has no code for "TLS verification skipped" (see F-006).
- None appear in `BRIEF.md` R1–R8 (R5 lists only `--ignore` and `--allow`), and `prd.md:73-86` Out of Scope does not mention them — so this is undocumented scope expansion.

**Failure scenario:** `--insecure` ships. A corporate-CA user passes it; the TLS error path returns `broken`/`tls-error` (per `BC-2.10.006`, since no BC says otherwise) instead of `indeterminate`, and CI fails on every internal HTTPS link — the opposite of the flag's purpose. No test catches it. Alternatively `--hidden` ships and walks `.git/`, scanning `COMMIT_EDITMSG`-style files (the exact case TV-004 guards against by default).
**Owner:** product-owner (author BCs for all four flags and add §6 test vectors, or move them to Out of Scope for v1.0).

---

### F-016 — Exit-code determination is not total: fail-fast, SIGINT, and panic paths contradict SS-14 and DD-007
**Files:** `interface-definitions.md:92, 222` vs `BC-2.14.002.md:49`, `decisions.md:41` (DD-007), `ADR-005:27-28`
**Confidence: HIGH**

**(a) Fail-fast contradiction.** `interface-definitions.md:222`: *"Nonexistent PATH | Exit 2 **immediately before scanning begins**."* `BC-2.14.002:49` (Inv 2) and DD-007 (`decisions.md:41`): *"**No fail-fast** — scan continues after I/O errors; findings from successfully scanned files are still reported."* For `mdlinkcheck docs /does/not/exist`, one source says abort before scanning `docs`, the other says scan it and report. `test-vectors.md:67` TV-012 only covers a single nonexistent path, so the combination is untested. This is precisely the "is every combination total?" hole: the tuple (unreadable file, broken link, indeterminate URL, nonexistent PATH arg) has no single authority.

**(b) SIGINT/panic are outside the exit-code function.** `interface-definitions.md:92`: *"Rust panics are caught at the top level and translated to exit 2. SIGINT/SIGTERM: emit partial output collected so far, then exit 2."* No BC in SS-14 mentions signals or panics; `BC-2.14.001/002/003` define exit code purely over the verdict multiset plus I/O and usage errors, and `prd.md:365` (KD-005) claims *"Exit code is a pure function of verdict multiset — no hidden state."* Signals are hidden state. Also: *"emit partial output"* violates `ADR-005:27-28` (*"This sort is a mandatory pipeline stage — **no finding may bypass it**"*) and NFR-003 determinism, since partial output is by definition unsorted with respect to the complete finding set. Separately, top-level `catch_unwind` does not work under `panic = "abort"`, and no ADR pins the release panic strategy.

**Failure scenario:** `mdlinkcheck docs typo-path/` in CI. Under the interface-definitions reading, the tool exits 2 without scanning `docs` at all — a user with a typo'd second argument gets zero link checking and a generic error, and CI treats exit 2 as an infrastructure problem rather than reporting the real broken links that DD-007 promises would still be reported.
**Owner:** product-owner (reconcile §8 with DD-007 — nonexistent PATH should record a usage error and continue); architect (contract SIGINT and panic behavior in a BC, or delete those sentences from interface-definitions; pin `panic` strategy in ADR-002).

---

### F-017 — `--allow` requires WHATWG normalization to match but simultaneously suppresses syntax validation; and two BCs in different subsystems own the same rule
**Files:** `BC-2.09.002.md:45, 49-52` and `:31`; `BC-INDEX.md:150` (BC-2.11.002); `test-vectors.md:215` TV-131; `interface-definitions.md:218`; `VP-INDEX.md:46` (VP-010)
**Confidence: HIGH**

**(a) Circular ordering.** `BC-2.09.002:45` (PC1): *"The URL is normalized (WHATWG) before prefix comparison."* `test-vectors.md:215` TV-131 and `interface-definitions.md:218`: `--allow` in offline mode *"suppresses syntax validation for matching URLs."* For a malformed URL such as `https://exa mple.com/x` with `--allow https://example.com`: to decide whether the allow-prefix matches you must normalize, but normalization *is* the syntax validation (`BC-2.09.001`, DD-010 → `broken`/`malformed-url`). If validation is suppressed you cannot normalize; if you normalize, the malformed verdict has already been produced. The spec never says which happens, and there is no vector for `--allow` + malformed URL.

**(b) Duplicate ownership.** `BC-2.09.002:31` ("`--allow` Suppresses External URL Checks", subsystem SS-09, CAP-009) and `BC-INDEX.md:150` BC-2.11.002 ("`--allow` URL Prefix Exemption with Component-Boundary Safety", SS-11, CAP-011) both own prefix matching with component-boundary safety. `VP-INDEX.md:46` assigns VP-010 (`allow-component-boundary`) to module **`filter`** — i.e. SS-11 — leaving BC-2.09.002's SS-09/CAP-009 anchor semantically wrong.

Mis-anchors in BC-2.09.002: `:79` cites `DD-010` (URL syntax validation semantics) — `--allow` semantics are **DD-013** (`decisions.md:47`); `:79` cites `R6` — `--allow` is **R5** (`BRIEF.md:25-26`); `:71` cites *"trap T16"* — T16 is *"Path above scan root"* (`test-vectors.md:280`).

**Failure scenario:** Two stories (one SS-09, one SS-11) each implement `--allow` prefix matching. One enforces the component boundary, the other does not (it is a "suppression" contract, not a "matching" contract). Whichever runs first wins, and if it is the naive one, `--allow https://example.com` matches `https://example.com.evil.tld` — the EC-092 security hazard that DD-013 (`decisions.md:47`) exists to close, and that VP-010 is meant to prove.
**Owner:** product-owner (collapse `--allow` into one BC under SS-11/CAP-011, make BC-2.09.002 a pointer, and specify the parse→allow ordering explicitly: normalize first, and if normalization fails the URL cannot match any allow prefix → `malformed-url`).

---

### F-018 — VP-001's Kani harness is not feasible as written and does not deliver its stated coverage
**Files:** `vp-001-slug-total.md:39, 50, 54-71, 77-80`; `BC-2.06.002.md:42`
**Confidence: MEDIUM**

`vp-001:54-71` runs 64 symbolic bytes through `str::from_utf8`, then `compute_slug`, which per `BC-2.06.001:47-49` performs full Unicode `to_lowercase()` and `\p{Word}` classification and returns a heap-allocated `String`. Three feasibility problems the assessment (`:77-80`, *"Function is a character-classification loop... CBMC model is small... < 30s"*) does not acknowledge:
1. `str::to_lowercase()` and `\p{Word}` are table-driven over the full Unicode range; unrolling them over 64 symbolic bytes is a known CBMC blow-up, not a "small model".
2. `compute_slug` takes `&mut DuplicateCounter`, which `BC-2.06.002:42` defines as a `HashMap<String, u32>`. Kani models `std::collections::HashMap` poorly (`RandomState`/SipHash), and it introduces unbounded heap allocation inside the proof.
3. `:50` claims coverage includes *"`DuplicateCounter` counter value up to 10"*, but `:66` constructs `DuplicateCounter::new()` — always empty. The counter is never non-zero, so the collision-bump path (the FM-002 risk) is not covered by VP-001 at all.

**Failure scenario:** The formal-verifier attempts VP-001, CBMC does not terminate within the CI budget, and the VP is downgraded to proptest or marked `feasibility: infeasible`. That silently drops one of the 7 Kani proofs that `prd.md:53-54` sells as differentiator #3, and it happens in Phase 6 — after all stories are built — with no earlier signal.
**Owner:** architect (restructure `compute_slug` so the Kani-provable core is `fn slugify(&str) -> String` with no counter and an ASCII-or-bounded-scalar input, move the counter into a separately verified pure function keyed on `BTreeMap`, and reduce the byte bound; correct the coverage claim at `:50`).

---

### F-019 — ADR-006 states macOS normalizes to NFC (it is NFD), asserts VP-008 is a Kani proof (VP-INDEX says proptest), and mis-anchors DD-013/R5/T12
**Files:** `ADR-006-strict-path-model.md:17, 19, 33, 44, 66, 74, 101-104` vs `VP-INDEX.md:44`, `verification-coverage-matrix.md:32`, `decisions.md:47`, `BRIEF.md:25-26`, `test-vectors.md:276`
**Confidence: HIGH**

1. **`:17`:** *"macOS: HFS+/APFS — case-insensitive but case-preserving by default; **NFC-normalized by default**"* and `:19` lists Windows NTFS as *"NFC-normalized by default"*. HFS+ normalizes filenames to **NFD**. This is the premise of DEC-004 (`edge-cases.md:68`, *"File on disk is `Café.md` in NFD normalization (**macOS-created**)"*), FM-007 (`failure-modes.md:57`), and TV-037 (`test-vectors.md:98`). ADR-006's Context inverts the fact that motivates the entire decision.
2. **VP-008 method contradiction.** `:44` *"This function is Kani-provable (VP-008)"*, `:74` *"VP-008 Kani proof verifies pure path comparison directly"*, `:104` *"VP-008: Kani proof harness for path comparison"*. `VP-INDEX.md:44` (authoritative) and `verification-coverage-matrix.md:32` both say VP-008 is **proptest, P1**. Three assertions in an accepted ADR contradict the VP registry.
3. **`:33` and `:102` cite DD-013** as the cross-platform path-normalization decision. DD-013 (`decisions.md:47`) is the `--ignore` glob dialect / `--allow` prefix decision. The path-comparison decision is **DD-002** (`decisions.md:31`).
4. **`:66` and `:103` cite "product-brief.md R5: macOS/Linux/Windows cross-platform matrix".** `BRIEF.md:25-26` R5 is `--ignore`/`--allow`. No R1–R8 requirement mentions a platform matrix; that obligation is NFR-004 / D-006.
5. **`:59, 68, 102` cite T12** as the NFD/NFC trap. `test-vectors.md:276` defines T12 as *"Case-sensitive filename"*.
6. **`:41` signature `pub fn files_match(a: &OsStr, b: &OsStr) -> bool`.** `unicode-normalization` operates on `&str`. `OsStr` on Unix is arbitrary bytes (possibly invalid UTF-8) and on Windows is potentially ill-formed UTF-16. NFC-normalizing an `OsStr` requires a failable conversion, and **nothing in the spec package says what verdict a non-UTF-8 directory entry name produces** — there is no reason code, no BC, and no test vector for it. DI-002 is therefore unimplementable for that input class as specified.

**Failure scenario (2):** The formal-verifier's Phase 6 worklist is built from ADR-006 and includes a Kani harness for `files_match`. VP-INDEX schedules a proptest at Phase 3. Either duplicated effort, or the Phase 3 proptest is skipped in favour of the ADR's Kani plan and DI-002 goes unverified until Phase 6.
**Failure scenario (6):** A Linux repo contains a file with a Latin-1 byte in its name. `files_match` either panics on the conversion (violating VP-008's totality) or silently returns false, producing `file-not-found` for a link that resolves fine — an unreportable false positive with no diagnostic.
**Owner:** architect (fix the NFC/NFD statement, align the VP-008 method with VP-INDEX, re-anchor DD-013→DD-002 / R5→NFR-004+D-006 / T12, and specify the non-UTF-8 filename behavior with an explicit verdict).

---

### F-020 — BC-INDEX contradicts the PRD and the frozen brief on invariant coverage, differentiator identity, requirement labels, and priority counts
**Files:** `BC-INDEX.md:190-191, 199-209, 213-222, 226-232` vs `prd.md:58-64, 373-433`, `invariants.md:97-127`, `BRIEF.md:25-30`, `VP-INDEX.md:56`
**Confidence: HIGH**

**(a) DI-007 declared an orphan invariant.** `BC-INDEX.md:205`: `| DI-007 | [reserved — no enforcement BC needed] | — |`. But `invariants.md:97-106` DI-007 is a live invariant (*"Expanding this reopens the HTML-parsing scope and manufactures false negatives"*), `VP-INDEX.md:56` assigns **VP-020** (`html-anchor-narrow-scope`) to DI-007, `VP-INDEX.md:68` claims DI-007 coverage, and `BC-2.05.003` implements it. BC-INDEX asserts no BC is needed for an invariant that has both a BC and a VP. Per my orphan-detection axis this is MEDIUM as a lone orphan, but it is HIGH because it *contradicts VP-INDEX in the same repo*.

**(b) DI-009 restated as a different invariant.** `BC-INDEX.md:207`: *"`.git/` never traversed; dir symlinks never followed."* `invariants.md:120-127` DI-009 is *"Scan Terminates for Any Input"* (the DoS guard), and `VP-INDEX.md:53` maps VP-017 (`scan-terminates`) to DI-009. BC-INDEX substitutes a mechanism for the property, so the enforcing-BC list (`BC-2.01.004, BC-2.01.001`) omits BC-2.01.007 (dedup) and the symlink-cycle case entirely.

**(c) KD-001..005 mean five different things in two documents.**

| ID | `prd.md:58-64` | `BC-INDEX.md:226-232` |
|---|---|---|
| KD-001 | Correct anchor checking, on by default | Structural code exclusion (DI-004) |
| KD-002 | Offline-by-default | github-slugger v2 anchor fidelity |
| KD-003 | Source-level `file:line` reporting | NFC case-sensitive path comparison |
| KD-004 | Case-correct path resolution | Three-verdict model |
| KD-005 | Deterministic exit codes | Deterministic output |

`prd.md:326-368` §6 builds five traceability tables on the PRD definitions. Any reader who resolves "KD-002" via BC-INDEX gets the wrong differentiator.

**(d) R5/R6 relabelled against the frozen brief, and the error propagated into ~every BC.** `BC-INDEX.md:219-220`: *"R5 — Link validation (file, anchor, URL)"*, *"R6 — Filters and output"*. `BRIEF.md:25-30`: **R5 = `--ignore`/`--allow`**, **R6 = output formats**, and link validation is **R2a/R2b/R2c**. This mislabel is baked into the BC files' `Brief Requirement` fields: `BC-2.06.001.md:103` `R5`, `BC-2.06.002.md:83` `R5`, `BC-2.05.001.md:76` `R5`, `BC-2.07.003.md:81` `R5, R6`, `BC-2.07.005.md:93` `R5`, `BC-2.07.006.md:90` `R5`, `BC-2.08.002.md:83` `R5, R6`, `BC-2.10.002.md:87` `R5`, `BC-2.10.005.md:73` `R5`, `BC-2.10.008.md:76` `R5, R8`, `BC-2.09.002.md:79` `R6`, `BC-2.11.003.md:73` `R6`, `BC-2.12.002.md:79` `R6`. `prd.md:373-433` §7 RTM disagrees with all of them (it assigns R2b to BC-2.06.001, R2a to BC-2.07.003, R2c to BC-2.10.*). So brief-requirement traceability is broken in both directions.

**(e) Priority counts.** `BC-INDEX.md:190-191`: P0 = 45, P1 = 14. Summing `prd.md:97-250` gives **P0 = 37, P1 = 22** (all of SS-09, SS-10, SS-11, SS-13 are P1 in the PRD and mostly P0 in BC-INDEX; BC-2.01.006, BC-2.01.008, BC-2.03.006, BC-2.12.002, BC-2.13.001 also flip).

**Failure scenario:** Wave planning is priority-driven. Under BC-INDEX all 8 SS-10 BCs are P0 and land in the v1.0 must-have wave; under the PRD they are all P1 and deferrable. The two documents produce incompatible release scopes, and the `--online` subsystem — the most expensive and least brief-critical (R2c is explicitly opt-in) — is either over- or under-prioritised depending on which index the planner opened.
**Owner:** spec-steward (make BC-INDEX derived-not-authored for DI/KD/R/priority sections, or reconcile all four against `invariants.md`, `prd.md` §1.3, `BRIEF.md`, and VP-INDEX); business-analyst (correct the `Brief Requirement` field in the ~13 affected BC files to R2a/R2b/R2c). `[process-gap]` — nothing cross-validates BC-INDEX's derived tables against their sources.

---

### F-021 — `target-is-directory` triggers were not updated after SF-002; three documents still say plain directory links are broken
**Files:** `error-taxonomy.md:46`; `failure-modes.md:31`; `prd.md:301` vs `BC-2.07.005.md:53-54, 64, 78-79`; `test-vectors.md:91-92`
**Confidence: HIGH**

PRD v1.1 SF-002 (`prd.md:457-459`) corrected BC-2.07.005 so a plain directory link is `clean`. The downstream trigger definitions were not updated:
- `error-taxonomy.md:46`: *"Destination resolves to a directory (only when directory links are disallowed — **today always broken unless `docs/` trailing-slash form**)"*. Two errors: it says always broken, and it implies the trailing-slash form is the exception. `test-vectors.md:92` TV-030 makes `[x](docs)` **without** a trailing slash `clean`, and `BC-2.07.005:79` agrees.
- `failure-modes.md:31`: *"Destination resolves to a directory and directory links are not allowed"* → broken. There is no "not allowed" mode in the CLI surface; the condition is undefined.
- `prd.md:301`: `| target-is-directory | broken | 1 |` with no fragment qualifier.

None of the three mentions the actual discriminator from `BC-2.07.005:54` — **fragment presence**.

**Failure scenario (partial-fix regression, blast radius 3):** A test-writer working from `error-taxonomy.md` — the document `:17` designates for `primary_consumers: [implementer, test-writer]` — writes a fixture asserting `[x](docs)` → `broken`/`target-is-directory`. TV-030 asserts `clean`. Directory links are extremely common in READMEs, so this produces mass false positives on the tool's own acceptance corpus.
**Owner:** product-owner (update `error-taxonomy.md:46`, `failure-modes.md:31`, and `prd.md:301` to "directory target **with a fragment**"; delete the phantom "directory links not allowed" mode).

---

### F-022 — VP-INDEX's own arithmetic invariant is violated, and the phase column cannot be reconciled with verification-coverage-matrix
**Files:** `VP-INDEX.md:16-17, 31, 37-56` vs `verification-coverage-matrix.md:23-44`
**Confidence: HIGH**

`VP-INDEX.md:31` declares: *"**Arithmetic invariant:** total_vps (20) = kani (7) + proptest (5) + fuzz (2) + integration (5) + unit (1) = 20. **Check before editing.**"* The method counts do hold. The **phase** counts do not:
- `:16` `p1_count: 8`. Counting `Phase = P1` in the table (`:44-49, 55`): VP-008, 009, 010, 011, 012, 013, 019 = **7**.
- `:17` `test_sufficient_count: 5`. Counting `Phase = test-sufficient` (`:50-54, 56`): VP-014, 015, 016, 017, 018, 020 = **6**.

`p0(7) + p1(8) + test_sufficient(5) = 20` by coincidence — the two errors cancel.

Separately, `VP-INDEX.md:25-29` mandates that phase tier *"MUST propagate to verification-coverage-matrix.md"*. But that file's `Phase` column (`verification-coverage-matrix.md:23-44`) contains **`3` and `6`** — pipeline phase numbers, not P0/P1/test-sufficient. VP-018 is `test-sufficient` in VP-INDEX and `3` in the matrix; VP-012 is `P1` and `6`. The two columns share a name and no domain, so the mandated propagation check is impossible to perform.

**Failure scenario:** A future VP retirement or re-tiering is validated against `p1_count`/`test_sufficient_count`, both of which are already wrong, so the validator either passes a bad edit or fails a good one. Meanwhile no reviewer can answer "is VP-018 P0, P1, or test-sufficient?" from the architecture docs.
**Owner:** architect (fix `p1_count: 7`, `test_sufficient_count: 6`; rename the matrix column to `Pipeline Phase` and add a separate `Tier (P0/P1/test-sufficient)` column mirroring VP-INDEX).

---

### F-023 — BC-2.13.001's sort key drops NFC normalization while claiming identical ordering to text output
**Files:** `BC-2.13.001.md:46` vs `BC-2.12.001.md:47, 51`; `invariants.md:27-31`; `interface-definitions.md:186`
**Confidence: HIGH**

`BC-2.12.001:47, 51`: *"Findings are sorted by (**NFC** file path asc, line asc, column asc)"* / *"The sort is by NFC-normalized path (same NFC normalization as DI-002)."*
`BC-2.13.001:46`: *"`results` is sorted by (**file**, line, column) ascending — **same order as text output**."* No NFC. `interface-definitions.md:186` repeats the weaker key.

DI-001 (`invariants.md:29`) mandates the NFC key. For a corpus containing both an NFC-named and an NFD-named file, byte-ordering the raw paths and NFC-ordering them can differ (NFD `e`+U+0301 sorts before NFC U+00E9). The two formats would then emit different orders, contradicting BC-2.13.001's own "same order as text output" clause and DI-001.

**Failure scenario (sibling drift, blast radius 1):** A repo with `café.md` (NFC) and `cafe\u{301}.md` (NFD) — exactly the DEC-004 fixture the corpus is required to contain — produces `--format text` and `--format json` outputs in different orders. The golden-file JSON test and the golden-file text test cannot both be generated from one run, and `NFR-003` byte-identical determinism holds per-format but the DI-001 invariant is violated across formats.
**Owner:** product-owner (change `BC-2.13.001:46` and `interface-definitions.md:186` to the NFC-normalized key).

---

### F-024 — BC-2.14.001 mis-cites DI-011 instead of DI-010, PRD §6.5 attributes a contract to it that it does not contain, and T-number citations are systematically wrong across BC files
**Files:** `BC-2.14.001.md:78, 45` ; `prd.md:365, 246, 431`; and T-citations in `BC-2.06.001.md:103`, `BC-2.06.002.md:83`, `BC-2.07.003.md:81`, `BC-2.08.002.md:83`, `BC-2.09.002.md:79`, `BC-2.10.002.md:87`, `BC-2.10.005.md:73`, `BC-2.12.001.md:80`, `BC-2.13.001.md:83` vs `test-vectors.md:265-280`
**Confidence: HIGH**

**(a)** `BC-2.14.001:78` lists `L2 Domain Invariants | DI-011`. DI-011 is exit-2-beats-exit-1 — irrelevant to an exit-0 contract. The invariant BC-2.14.001 actually enforces is **DI-010** (`:45`, *"Indeterminate findings... do NOT cause exit 1 or 2"*). `prd.md:431` RTM correctly lists `DI-010, DI-011`; the BC file omits DI-010.

**(b)** `prd.md:365` (KD-005) and `prd.md:246` both attribute *"Exit code is a pure function of verdict multiset"* to BC-2.14.001. `BC-2.14.001:31` is scoped to exit 0 only. No BC contracts the total function; F-004 covers the title drift, but the differentiator claim is separately unbacked.

**(c) T-number mis-citations.** Against `test-vectors.md:265-280`, which is the authoritative T1–T16 map:

| BC | Cites | T actually is |
|---|---|---|
| `BC-2.06.001.md:103` | T1, T2, T3 | code fences / CommonMark autolinks / raw HTML |
| `BC-2.06.001.md:94-95` | "trap T1", "trap T2" | same |
| `BC-2.06.002.md:83` | T3 | raw HTML out of scope |
| `BC-2.07.003.md:81` | T8 | angle-bracket destinations (should be **T12**) |
| `BC-2.08.002.md:83` | T10 | fragments on dirs/non-MD — this BC is the *cross-file anchor* contract |
| `BC-2.09.002.md:71,79` | T16 | path above scan root |
| `BC-2.10.002.md:87` | T13 | Windows path separators |
| `BC-2.10.005.md:73` | T14 | heading with link syntax |
| `BC-2.12.001.md:71,80` | T15 | forward heading reference (should be a determinism trap; there isn't one) |
| `BC-2.13.001.md:83` | T15 | forward heading reference |

Zero of the ten sampled T-citations resolve correctly. Combined with F-008 (EC IDs) and F-020(d) (R numbers), the BC traceability fields are unreliable as a class.

**Failure scenario:** A test-writer instructed to ensure every correctness trap has a home follows `BC-2.07.003 → T8` and writes an angle-bracket-destination test in the path-comparison story, while T12 (case-sensitive filename, the actual subject and a declared holdout) gets no owner. `test-vectors.md:276` already records T12 as `holdout` with no visible coverage, so the trap ends up with neither a BC anchor nor a visible test.
**Owner:** business-analyst (re-anchor all `T*` and `DI-*` citations in BC Traceability fields against `test-vectors.md` §8 and `invariants.md`); product-owner (fix `prd.md:365`). `[process-gap]` — BC Traceability fields carry EC/T/R/DD/DI/AMB references that no validator resolves; three independent ID families are all systematically wrong, which meets the 3+-recurrence bar for a process gap.

---

### F-025 — ASM-005 and ASM-008 are declared holdout candidates while their validation content is fully in the visible suite
**Files:** `assumptions.md:32, 35, 44`; `nfr-catalog.md:119-123`; `test-vectors.md:238-256`; `prd.md:286`
**Confidence: HIGH**

`assumptions.md:44`: *"Holdout candidates (ASM-005, ASM-008) must NOT be visible in the standard test suite — they belong in the hidden holdout evaluation phase."*

- **ASM-008** (`:35`) is *"GitHub's slug algorithm has not changed since github-slugger v2.0.0"*, validation method *"Run test fixtures from DD-015 worked examples... compare slugs."* Those fixtures are `test-vectors.md:238-256` (TV-S001..TV-S016) — all visible — and `nfr-catalog.md:119-123` NFR-006 mandates they *"run on every commit"*, echoed by `prd.md:286`.
- **ASM-005** (`:32`) is the R8/5s achievability assumption, validated by `hyperfine` in `benches/` — visible per `prd.md:281` (`"hyperfine benchmark in benches/"`).

**Failure scenario:** Compounding F-008, the holdout set is contaminated from two directions: reserved EC vectors are exposed in visible BCs, and the two holdout-candidate assumptions have their validation harnesses in the standard suite. The pilot's headline claim — that VSDD produces correct behavior measurable against unseen cases — becomes unfalsifiable. This is a pilot-integrity defect, not a code defect, and it cannot be fixed after implementation begins.
**Owner:** product-owner (decide the holdout boundary explicitly and remove holdout content from visible artifacts, or drop the holdout designation and record that the pilot has no holdout arm — either is acceptable; the current both-ways state is not).

---

### F-026 — NFR-007 exists in the catalog but is absent from the PRD's NFR index
**Files:** `nfr-catalog.md:127-138` vs `prd.md:279-288`
**Confidence: HIGH**

`nfr-catalog.md:127-138` defines NFR-007 (*"No Undefined Reason Codes"*, status `active`, validation: parse JSON output against the enumerated set). `prd.md:279-288` §4 lists NFR-001..NFR-006 only. `prd.md:277` calls the catalog a supplement to the PRD table, so a reader working from the PRD never learns NFR-007 exists.

This matters because NFR-007 is the only mechanism that would catch F-001 (ADR-007's five invented reason codes) and F-006 (unmapped statuses defaulting to an out-of-set reason). It is also the only NFR without a VP: `VP-INDEX.md:60-74` covers DI-001..DI-011 and cites NFR-003/NFR-006, never NFR-007.

**Failure scenario:** Wave planning derives the NFR verification workload from PRD §4. NFR-007 is never scheduled, no parsing test is written, and the closed-set invariant (`error-taxonomy.md:78-85`) has zero enforcement — so ADR-007's `dns-resolution-failure` ships undetected.
**Owner:** product-owner (add NFR-007 to `prd.md` §4); architect (add a VP for NFR-007, or record it as test-sufficient in VP-INDEX).

---

### F-027 — `.markdown` and `.MD` discovery is scope expansion beyond frozen-brief R1 with no recorded delta
**Files:** `BRIEF.md:14-15`; `BC-INDEX.md:36` (BC-2.01.005); `test-vectors.md:60-61`; `BC-2.07.006.md:46`
**Confidence: MEDIUM**

`BRIEF.md:14-15` R1: *"scans the given files/directories (default `.`) for `*.md` files."* The spec package extends this to case-insensitive `.md` **and `.markdown`** (`BC-INDEX.md:36`, `test-vectors.md:60-61` TV-005/TV-006), and propagates the wider definition into `BC-2.07.006.md:46` ("`.md` or `.markdown` (case-insensitive)") which governs the anchor-resolution carve-out.

Internally consistent, but the frozen brief says `*.md`, and I found no delta record: `prd.md:73-86` Out of Scope does not mention it, `decisions.md` has no DD for it, and `assumptions.md` has no ASM. `test-vectors.md:61` TV-006 also asserts `.mdx` is out of scope, which is a second undocumented boundary decision.

**Failure scenario:** A repo contains `CHANGELOG.markdown` with broken links. Per the spec, exit 1; per the frozen brief, that file is not in scope and exit is 0. At the Phase 1 human gate the reviewer compares deliverables to R1–R8 and cannot tell whether this was an intended interpretation or drift. It also changes NFR-001's "500 markdown files" corpus definition. **(pending intent verification)** — this may be a deliberate, sensible reading of R1; the defect is the absence of a record, not necessarily the decision.
**Owner:** product-owner (add a DD or an explicit R1-interpretation note covering `.markdown`, case-insensitive extension matching, and the `.mdx` exclusion).

---

## MINOR Findings

### F-028 — Reported line/column offsets are unspecified relative to BOM stripping and CRLF normalization
**Files:** `BC-INDEX.md:49` (BC-2.02.002, "Shell-Side"); `interface-definitions.md:229`; `test-vectors.md:70-71`
**Confidence: MEDIUM**

`interface-definitions.md:229`: *"Column is the 1-based **byte offset** of the opening `[` within the source line."* Per SF-001 (`prd.md:446-451`), `scanner.rs` strips the UTF-8 BOM and normalizes CRLF→LF **before** handing the string to the pure core, so byte offsets are computed on the transformed buffer. Nothing says whether reported columns refer to on-disk bytes or post-transformation bytes. On a BOM'd file, line 1 columns are off by 3; on a CRLF file, a multi-line construct's byte offsets diverge cumulatively. TV-015/TV-016 (`test-vectors.md:70-71`) assert only verdicts and *"Line numbers same as LF equivalent"* — never columns.
**Failure scenario:** An editor integration consuming `--format json` jumps to `file:1:5` on a BOM'd README and lands 3 bytes off, or `mdlinkcheck` and `rustc`-style tooling disagree on the same file.
**Owner:** product-owner (state that line/column are relative to the BOM-stripped, LF-normalized buffer, and add a column assertion to TV-015).

### F-029 — Empty slugs and slug collisions between *distinct* headings are unspecified; BC-2.06.001 PC2 is self-contradictory
**Files:** `BC-2.06.001.md:51, 79, 88`; `BC-2.06.002.md:42`; `edge-cases.md:104-113` (DEC-007); `BC-2.08.001`
**Confidence: MEDIUM**

`BC-2.06.001:51` (PC2): *"The slug is **always a valid non-empty string** for any non-empty heading (**may be empty string** if heading has only punctuation — in that case, empty anchor is added)."* Self-contradictory in one sentence, and it says nothing about what an "empty anchor" collides with: DEC-007 (`edge-cases.md:104-113`) and BC-2.08.001 define `[x](#)` as the top-of-page convention returning `clean`. If a punctuation-only heading also registers the empty string as an anchor key, the two mechanisms overlap silently.

Unaddressed by any BC or vector:
- Two distinct headings that slugify identically. `## Done ✅` and `## Done 🎉` both slugify to `done-` (per TV-055/TV-S016, `test-vectors.md:122, 255`); the second becomes `done--1` under `BC-2.06.002:42`'s slug-keyed counter. Correct per github-slugger, but nowhere stated, and `test-vectors.md:238-256` has no vector for it — so an implementer keying the counter on *heading text* instead of *slug* passes every existing vector and produces two `done-` entries.
- Two emoji-only headings (`## ✅`, `## 🎉`) → `""` and `"-1"`, making `[x](#-1)` a valid anchor. Unspecified.
- `BC-2.06.001:79` claims EC-048 is `##` (empty heading) → `""`; CommonMark treats a bare `##` as a valid empty ATX heading, so this interacts with the empty-anchor rule above.

**Owner:** product-owner (rewrite PC2 unambiguously, state the counter is keyed on the computed slug, add vectors for emoji-differentiated collisions and punctuation-only headings, and state whether an empty slug is registered as an anchor key).

### F-030 — Two unverifiable/inconsistent NFR details
**Files:** `prd.md:285`; `nfr-catalog.md:107, 120`; `BC-2.06.001.md:82-88`; `test-vectors.md:238-256`
**Confidence: MEDIUM**

(a) `prd.md:285` gives NFR-005's sole validation method as `hyperfine --profile-mem`. No such hyperfine flag exists; `nfr-catalog.md:107` hedges with *"or `/usr/bin/time -v`"*, but the PRD-level statement is unexecutable, making NFR-005 unverifiable as indexed.
(b) DD-015 worked-example count is given three ways: `nfr-catalog.md:120` *"all **10** worked examples + DEC-001"*; `BC-2.06.001.md:82-88` lists **5** ("DD-015 #1".."#5"); `test-vectors.md:238-256` enumerates **16**. NFR-006's 100% target is therefore not measurable against a fixed denominator.
**Owner:** product-owner (replace `--profile-mem` with `/usr/bin/time -v` in `prd.md:285`; fix the worked-example count to match `test-vectors.md` §7).

### F-031 — error-taxonomy §6 cross-reference maps `undefined-reference-definition` to the wrong failure mode and omits five reason codes
**Files:** `error-taxonomy.md:105-116` vs `failure-modes.md:54`
**Confidence: HIGH**

`error-taxonomy.md:110`: `| undefined-reference-definition | FM-004 (code-span extraction incorrect) | BC-2.03.003 |`. FM-004 (`failure-modes.md:54`) is *"Links inside fenced code blocks extracted → false positive on every code example"* — a DI-004 code-context failure with no relationship to reference-definition resolution. The §6 table also omits `target-is-directory`, `tls-error`, `too-many-redirects`, and `http-indeterminate`'s connection-reset trigger, and lists no BC for `target-is-directory` at all.
**Failure scenario:** The FM→fixture mapping in `failure-modes.md:49` (*"Each maps to one or more corpus fixtures"*) is the basis for ASM-007's one-fixture-per-failure-class corpus. FM-004's fixture gets filed under reference-definitions, and `target-is-directory` gets no fixture.
**Owner:** product-owner (correct the FM-004 row and add the five missing rows).

### F-032 — Non-UTF-8 file content and permission-denied share one reason code, conflating a decode error with an I/O error
**Files:** `error-taxonomy.md:72`; `BC-INDEX.md:50` (BC-2.02.003); `test-vectors.md:68-69`; `interface-definitions.md:88`
**Confidence: MEDIUM**

`error-taxonomy.md:72` gives `target-unreadable` the trigger *"permission denied, **non-UTF-8 content**, unexpected read error"*, and TV-013/TV-014 (`test-vectors.md:68-69`) both expect `target-unreadable`. But these are different conditions with different user remedies: permission-denied is environmental; invalid UTF-8 in a `.md` file is a content defect the author must fix. Collapsing them means the JSON/stderr output cannot distinguish "fix your CI permissions" from "your file is Latin-1", and `interface-definitions.md:88` folds a third case (*"internal unexpected error"*) into the same exit code with no reason code at all. Separately, `BC-2.02.003`'s per-file continue semantics sit in tension with `interface-definitions.md:222`'s fail-fast wording (see F-016).

Related unstated assumption: nothing in the package specifies a **maximum file size**. `test-vectors.md:73` TV-018 asserts a 50 MB file completes without OOM, and NFR-005 caps peak RSS at 512 MB, but the design reads whole files into memory (BOM/CRLF normalization is buffer-wide per SF-001) and builds all anchor tables for all files in memory before Pass 2 (`BC-2.05.001:43`). For 500 files the budget holds; for a repo with a few hundred large generated `.md` files it may not, and no BC bounds it.
**Owner:** product-owner (split `target-unreadable` into `target-unreadable` and `invalid-utf8`, or document the conflation explicitly); architect (state the memory model and any file-size bound, or record explicitly that none exists and NFR-005 is corpus-shape-dependent).

---

## Observations

- `[process-gap]` The BC Traceability block is the single highest-defect-density structure in the package. Three independent ID families — `EC-NNN` (F-008), `T*` (F-024c), and `R*` (F-020d) — are systematically mis-anchored across the same files, and `VP-NNN` is 100% placeholder (F-007). Fixing the instances without adding resolution validation guarantees recurrence.
- `[process-gap]` PRD v1.1's SF-002 revision fixed §2.5 and §2.8 titles but left §2.9–§2.14 drifted (F-004), left `error-taxonomy.md`/`failure-modes.md` directory triggers stale (F-021), and left the sibling BC-2.08.002 uncorrected (F-003). A single revision touched the primary artifact and none of its three propagation targets — the partial-fix pattern, three times in one changelog entry.
- The two `verdict` vocabularies (`alive` per D-008/DD-004/BC-2.10.002/ADR-007 vs `clean` per error-taxonomy/BC-2.13.001/JSON schema) coexist throughout. `BC-2.10.002:43` writes `"alive → clean"` to bridge them. This is tolerable but it is the mechanism by which ADR-007 drifted into asserting `alive` appears in JSON (F-001.5); a single normative term with one documented alias would remove the failure mode.
- `ADR-002-workspace-layout.md`, `ADR-001-pure-core-effectful-shell.md`, `ADR-003-pulldown-cmark.md`, `architecture/system-overview.md`, `module-decomposition.md`, `api-surface.md`, `tooling-selection.md`, `verification-architecture.md`, `feasibility-review.md`, `module-criticality.md`, `dtu-assessment.md`, `gene-transfusion-assessment.md`, `domain-spec/{capabilities,entities,events,event-flow,risks,differentiators,L2-INDEX}.md`, and 14 of the 20 VP files were **not reviewed** (context budget). In particular `verification-architecture.md`'s Provable Properties Catalog was not cross-checked against VP-INDEX, so the VP-INDEX→verification-architecture leg of the coherence axis is unverified; given that the VP-INDEX→coverage-matrix leg already fails (F-022), pass 2 should start there. `domain-spec/capabilities.md` was also not read, so every BC's `L2 Capability` quotation and `Capability Anchor Justification` is unverified — and given F-020/F-024, those quotations should be treated as suspect until checked.

## Novelty Assessment

**Novelty: HIGH.** This is pass 1 with no prior-pass context. Six findings are structural and would each independently produce wrong runtime behavior or an unbuildable story: an accepted ADR that inverts the frozen brief's exit codes and invents a reason-code vocabulary (F-001); a BC whose canonical vector contradicts its own invariant and four other artifacts (F-002); two BCs that assign opposite verdicts to the same input (F-003); an index document whose second half no longer describes the contracts it indexes, concealing six uncontracted behaviors (F-004); a two-pass design that is circular as specified and leaves a whole class of anchor targets tableless (F-005); and a totality invariant with six unmapped cases guarded by a proof that is true by construction (F-006).

The package has **not** converged. None of these are refinements or wording issues. The density of mis-anchoring — 100% of sampled `T*` citations wrong, 11 verified `EC-NNN` collisions, 12 BCs with unresolved `subsystem:`, 99 `VP-TBD` placeholders, 6 holdout vectors exposed in visible artifacts — indicates the traceability layer was generated but never validated against its targets. Per the mis-anchoring rule, F-002, F-003, F-008, F-019, F-020, and F-024 block convergence regardless of severity negotiation.

Recommended pass-2 focus: `verification-architecture.md` vs VP-INDEX; `domain-spec/capabilities.md` vs all 59 BC `L2 Capability` quotations; the remaining 14 VP files for Kani feasibility (F-018 suggests the pattern is not isolated); and `ADR-001`/`module-decomposition.md` against the SS-07/SS-08 routing ownership conflict in F-003.

FINDINGS: 6 critical, 21 major, 5 minor
NOVEL_FINDINGS: 32
