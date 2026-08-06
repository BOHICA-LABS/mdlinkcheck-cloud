---
document_type: domain-spec-section
level: L2
section: decisions
version: "1.8"
status: draft
producer: business-analyst
timestamp: 2026-08-05T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/planning/brief-validation.md
  - .factory/planning/market-intelligence.md
input-hash: "20e96e1"
traces_to: L2-INDEX.md
changelog:
  - version: "1.8"
    date: 2026-08-06
    change: "D-043 (macOS-only platform directive): DD-002 Decision column updated with canonical D-006 determinism rationale (see D-043 Rationale Update section below); DD-020 NFR-002 reference updated to macOS CI runner (10s p95) per retarget."
  - version: "1.7"
    date: 2026-08-06
    change: "P3-010 governance gap closure: added DD-027 (two-invariant model for CAP-006 — DI-012 slug computation fidelity + DI-013 anchor-key uniqueness). Updated preamble to reference DD-027 and Human Decisions section header to DD-001–DD-006, DD-017–DD-027."
  - version: "1.6"
    date: 2026-08-06
    change: "Mechanical spec remediation (check-holdout-boundary): DD-017 — removed erroneous still-active holdout citation from Decision text and Resolves (it covers a different scenario, not the BV-013 code-span-extraction case; per adversary P3-022 resolution); also removed the retired-scenario ID from Resolves (superseded by BV-013). DD-007 — replaced active holdout EC-141 in Resolves with risk-class description (exit-code-conflict scenario class; DD-026 compliance). DD-009 — replaced active holdout EC-094 in Resolves with risk-class description (non-http-scheme scenario class). DD-010 — replaced active holdout EC-093 in Resolves with risk-class description (malformed-URL scenario class). Decision rationale text in all rows preserved intact — only the Resolves cross-reference column was changed."
  - version: "1.5"
    date: 2026-08-05
    change: "Pass-2 adversarial remediation: added DD-023 (D-017 — JSON object envelope is the authoritative R6 interpretation; P2-M11), DD-024 (D-018 — HTTP 400 after GET fallback is indeterminate; P2-C03), DD-025 (D-019 — --allow WHATWG-normalize-then-prefix-match with raw-string fallback at component boundary when normalization fails; P2-M08), DD-026 (D-020 — EC-036/049/074/157/158 holdout burn; standing rule for future holdouts; P2-C07). Updated preamble and Human Decisions header range to DD-001–DD-026."
  - version: "1.4"
    date: 2026-08-05
    change: "Orchestrator ruling DD-022: added DD-022 (two-layer verdict model — link verdict vs. URL liveness outcome; `alive` is not a fourth verdict). Updated section preamble and Human Decisions header range to DD-001–DD-022."
  - version: "1.3"
    date: 2026-08-05
    change: "Orchestrator ruling: added DD-021 (holdout de-designation of ASM-005 and ASM-008; governing holdout policy). Updated section preamble and Human Decisions header."
  - version: "1.2"
    date: 2026-08-05
    change: "Phase 1d gate remediation: added DD-017 (D-010 holdout de-designation of BRIEF.md vector), DD-018 (D-011 dropped flags; unconditional dot-dir skip), DD-019 (D-012 .md-only case-sensitive extension — resolves F-027 ambiguity), DD-020 (D-013 two-tier performance model confirmation)."
  - version: "1.1"
    date: 2026-08-05
    change: "Phase 1d F-005 remediation: DD-008 widened from --ignore-only to all four source-exclusion mechanisms (--ignore, .gitignore, dot-directory skip, scan-root boundary)"
  - version: "1.0"
    date: 2026-08-05
    change: "Initial draft"
---

# Section 11: Domain Decisions Register

> **Sharded L2 section (DF-021).** Navigate via `L2-INDEX.md`.

One row per resolved AMB-*/BV-* item. Decisions DD-001–DD-006 and DD-017–DD-027 are
from human/orchestrator decisions (binding). DD-007–DD-016 resolve the [PO]-tagged open
questions from brief-validation.md. DD-017–DD-020 were recorded during Phase 1d gate
remediation (D-010 through D-013). DD-021 is an orchestrator ruling on holdout governance.
DD-022 is an orchestrator ruling on verdict vocabulary (two-layer model). DD-023–DD-026
are human rulings from Phase 1d adversarial pass-2 remediation. DD-027 is a
business-analyst governance decision closing the P3-010 slug-fidelity governance gap
(two-invariant model for CAP-006: DI-012 + DI-013).

## Human Decisions (Binding — DD-001–DD-006, DD-017–DD-027)

| DD | Source | Decision | Resolves | Domain Artifact |
|----|--------|----------|----------|----------------|
| DD-001 | D-004 (Human) | Language: Rust, MSRV 1.85 | BV-016 (no constraints section) | ASM-001 |
| DD-002 | D-006 (Human) | Path comparison: case-sensitive, NFC-normalized; `[x](README.MD)` against `README.md` is broken. **D-043 rationale (canonical):** Strict case-sensitive + NFC path comparison is retained on determinism grounds, independent of the platform matrix. The tool must produce byte-identical output for byte-identical repository content, and must not let the host filesystem's case-folding or Unicode normalization behaviour influence link verdicts. macOS APFS is case-insensitive and stores filenames in NFD; adopting native filesystem semantics would make verdicts a function of the filesystem rather than of the repository content, which would break DI-001 determinism and NFR-003 reproducibility. This holds on a macOS-only matrix and is not contingent on cross-platform parity. | BV-006, AMB-052/053/055 | DI-002 |
| DD-003 | D-007 (Human) | HTML anchors: extract `id=` and `name=` attributes only from inline/raw HTML; no DOM construction, no HTML links followed | BV-008, AMB-059 | DI-007 |
| DD-004 | D-008 (Human) | Online verdicts: three outcomes — `alive`, `broken`, `indeterminate`; 429/403-bot/all-5xx/timeout → `indeterminate`; indeterminate does NOT cause exit 1 | AMB-036, AMB-034 | DI-010 |
| DD-005 | D-009 (Human) | In scope: factory README.md + `tests/corpus/` as first-class deliverable. Out of scope: inline suppression directives, GFM bare-URL autolinks | BV-009, BV-011, BV-012 | ASM-003, ASM-006, ASM-007, ASM-009, ASM-010 |
| DD-006 | D-004 (Human) | Exit codes stay exactly as R7 states: 0/1/2 (NOT lychee's inverted 0/2/1/3 taxonomy) | R-006 | DI-011 |
| DD-017 | D-010 (Human, Phase 1d gate) | Holdout boundary update: the `mdlinkcheck BRIEF.md` → exit 0 scenario (DEC-006, code-span-extraction vector EC-102) is de-designated from holdout and is now a standard visible test vector (BV-013). All other EC-NNN entries reserved in prd.md §320 remain hidden. | BV-013 | DEC-006 |
| DD-018 | D-011 (Human, Phase 1d gate) | Dropped non-goal flags: `--quiet`, `--offline`, `--insecure`, `--hidden` are explicit non-goals for v1.0. No BC, no test vector, no CLI surface. Consequence: dot-directory skip is now UNCONDITIONAL — there is no `--hidden` override. All domain artifacts referencing `--hidden` as an optional flag are incorrect and must be fixed. | — | DI-006 item 3, CAP-001 |
| DD-019 | D-012 (Human, Phase 1d gate) | Discovery extension scope: `.md` files only, case-sensitive. The frozen brief's "`*.md`" means exactly the lowercase string `.md`. `.MD`, `.markdown`, and `.mdx` are explicit non-goals with no BC and no test vector. Resolves F-027 — the `is .markdown intentional?` ambiguity is now a documented non-goal. | BRIEF.md R1, F-027 | CAP-001, MarkdownFile entity |
| DD-020 | D-013 (Human, Phase 1d gate) | Two-tier performance model confirmed: (1) Acceptance ceilings — NFR-001 (5s p95, Apple Silicon, 500 `.md` files offline) and NFR-002 (retargeted per D-043: 10s p95, macOS CI runner `macos-latest`) from frozen brief R8; these are pass/fail gates at release. (2) CI regression gate — ~500ms p95 on `macos-latest` CI corpus enforced by VP-022 on every commit. The acceptance ceilings are too loose (~25–100×) to catch algorithmic regressions (see R-008); the regression gate serves that function. | BRIEF.md R8, NFR-001/002, R-008 | ASM-005 |
| DD-021 | Orchestrator ruling (pipeline governance) | Holdout de-designation of ASM-005 and ASM-008. Neither the performance baseline (ASM-005, validated by NFR-008/VP-022 enforced in `benches/`) nor the slug-fidelity assumption (ASM-008, validated by DD-015 worked examples enforced via NFR-006/VP-018 in prd-supplements/test-vectors.md) qualifies as a holdout candidate. Their validation vectors are present in the visible, continuously-enforced standard suite. Holdout value requires vectors that are hidden from the standard suite; designating continuously-enforced behavior as holdout trades permanent regression coverage for a one-time Phase 4 signal, which is a bad trade. Governing holdout policy: an assumption may be designated holdout only if no visible artifact contains its validation vectors, and any designation must name the specific hidden edge cases or benchmark scenarios carrying the evaluation signal. Corrects the stale false assertion at assumptions.md Notes §4 (was: "must NOT be visible in the standard test suite"). | ASM-005, ASM-008 | assumptions.md |
| DD-022 | Orchestrator ruling (verdict vocabulary) | Two-layer verdict model. **Layer 1 — Link verdict** (the per-link result the tool reports; the only thing exit codes depend on): exactly `clean` \| `broken` \| `indeterminate`. This is the closed three-value set (DI-005, D-008). **Layer 2 — URL liveness outcome** (an intermediate value, produced only for external http(s) URLs in `--online` mode): `alive` \| `broken` \| `indeterminate`. Mapping: liveness `alive` → link verdict `clean`; liveness `broken` → link verdict `broken`; liveness `indeterminate` → link verdict `indeterminate`. `alive` is NOT a fourth verdict. Root cause of the pre-existing confusion: `prd-supplements/error-taxonomy.md` §1 flattened two-layer concepts into one four-value set and incorrectly asserted "`clean` is NOT used for external URL verdicts." That file is out of scope here and must be corrected separately. The ubiquitous language in entities.md now separates the layers with explicit entries for `clean` and `alive`. Resolves adversary finding P2-C01 and INCONSISTENCY-001/002. | P2-C01, INCONSISTENCY-001/002 | DI-005, entities.md, CAP-010 |
| DD-023 | D-017 (Human ruling, pass-2 remediation) | **JSON output envelope.** BRIEF.md R6 ("machine-readable **array** of the same") is satisfied by the `results` array inside a versioned object envelope. The authoritative shape is `{schema_version: 1, results: [...], errors: [...]}`. A bare JSON array cannot carry a `schema_version` field; the envelope design (which originated in interface-definitions.md and prd.md) is therefore the correct binding interpretation of R6. CAP-013 is corrected to reflect this shape. A JSON array literal is NOT a conforming implementation. | P2-M11 | CAP-013 |
| DD-024 | D-018 (Human ruling, pass-2 remediation) | **HTTP 400 after GET fallback is `indeterminate`, not `broken`.** When the HEAD→GET fallback sequence has already been completed and the GET response is 400, the server is rejecting the HTTP method, not the resource. Classifying this as `broken` produces false positives (the resource may well exist). The correct verdict is `indeterminate` with reason code `http-indeterminate`. `http-error` (`broken`) is reserved for 404 and 410 — unambiguous resource-does-not-exist responses. Resolves P2-C03 and the BC-2.10.002/error-taxonomy.md conflict. | P2-C03 | CAP-010, failure-modes.md |
| DD-025 | D-019 (Human ruling, pass-2 remediation) | **`--allow` two-step matching algorithm.** Step 1: attempt WHATWG normalization of the candidate URL. Step 2a (normalization succeeded): perform component-boundary prefix match against the normalized URL. Step 2b (normalization failed — URL is syntactically malformed): fall back to raw-string prefix match at a component boundary. A match by either path exempts the URL from syntax and liveness checks. The component-boundary requirement is mandatory in **both** paths: `--allow https://example.com` must NOT match `https://example.com.evil.tld`. This is the `example.com.evil.tld` defence — do not weaken it. Resolves P2-M08: the prior "normalize-then-match" algorithm made `--allow` structurally unable to exempt malformed URLs from syntax checking. The raw-string fallback closes that gap. | P2-M08 | CAP-011 |
| DD-026 | D-020 (Human ruling, pass-2 remediation) | **Holdout burn ruling.** EC-036, EC-049, EC-074, EC-157, EC-158 are formally retired as holdout vectors. Full scenario content (input + expected output) for all five appeared in visible artifacts before implementation began, destroying their Phase 4 evaluation signal. DEC-001 (EC-049), DEC-003 (EC-074), and DEC-009 (EC-036) in `edge-cases.md` are restored to the visible corpus with full concrete detail. EC-157 and EC-158 are in `prd.md` (product-owner scope). **Standing rule:** No domain-spec shard may carry concrete scenario content (specific inputs + expected outputs) for any *newly* designated holdout EC ID while that holdout designation is active. Holdout entries in `edge-cases.md` must describe only the failure class and cite the hidden scenario file under `.factory/holdout-scenarios/`. Resolves P2-C07 for the domain-spec layer. | P2-C07, POL-18 | edge-cases.md, invariants.md |
| DD-027 | Business-analyst governance (P3-010 closure) | **Two-invariant model for CAP-006 slug correctness.** DI-012 governs per-heading slug computation fidelity (each individual character-level transformation is exact per DD-015 steps 1–4). DI-013 governs per-file anchor-key uniqueness (the duplicate-counter produces an injective mapping of headings to anchor keys within a file). The two invariants are separated because they can fail independently — a correct character-level transformation with a 1-based counter satisfies DI-012 and violates DI-013; a correct counter with underscore-stripping violates DI-012 and satisfies DI-013 — and they have different proof obligations (individual transformation function vs. global injectivity property). FM-001 and FM-003 (character-level mistakes) are re-anchored to DI-012; FM-002 (1-based vs. 0-based counter) is re-anchored to DI-013. Closes the governance gap identified in adversary pass P3-010: the product's highest-risk correctness surface is now governed at the invariant layer, not only at the decision layer (DD-015). | P3-010, FM-001, FM-002, FM-003 | DI-012, DI-013, CAP-006 |

## PO Decisions — Resolved [PO] Questions (DD-007–DD-016)

| DD | Brief-Val Question | Decision | Rationale | Resolves | Domain Artifact |
|----|-------------------|----------|-----------|----------|----------------|
| DD-007 | Q6 — Exit-code precedence and fail-fast | Exit code 2 wins over exit code 1 when both conditions occur in the same run. **No fail-fast** — scan continues after I/O errors; findings from successfully scanned files are still reported | An I/O error means the scan was incomplete; reporting exit 1 would overstate coverage | BV-005, EC-142, mixed-exit-condition scenario class | DI-011 |
| DD-008 | Q7 — Source-exclusion mechanisms and anchor targets (widened in Phase 1d) | ALL source-exclusion mechanisms exclude files as link *sources* only; they do NOT remove a file from the anchor-target universe. Specifically: (1) `--ignore <glob>` — Pass 1 scans all traversed `.md` files including `--ignore`d ones; Pass 2 skips them as sources. (2) `.gitignore`/`.ignore` exclusion, (3) dot-directory skip, (4) scan-root boundary — files excluded by these are not reached by Pass 1; Pass 1.5 builds their anchor tables on demand when in-scan-set links reference them. Original v1.0 decision covered `--ignore` only; widened by Phase 1d adversarial review (F-005, business-analyst owner) to close the false-positive gap for all exclusion mechanisms. | Without this, any `[x](file.md#section)` where `file.md` is `.gitignore`d, in a dot-directory, above the scan root, or `--ignore`d manufactures a false `anchor-not-found` verdict. The v1.0 fix addressed `--ignore` but left the other three mechanisms silently broken; any repo that links into `node_modules/`, `.github/`, or a parent directory would produce false positives. | AMB-063, EC-074 | DI-006 |
| DD-009 | Q9 — Non-http(s) schemes and autolink forms | Non-http(s) schemes (`mailto:`, `ftp:`, `tel:`, `data:`, `vscode:`, protocol-relative `//host`) are **silently skipped** (verdict: `clean`). CommonMark autolinks `<https://x>` are in scope as external URLs. GFM bare-URL autolinks (`https://x.com` in plain prose) are **out of scope** (pulldown-cmark does not support them; document as limitation) | Non-http schemes are not link rot; GFM bare-URL exclusion is forced by parser choice | non-http-scheme scenario class, AMB-047 | ASM-009, CAP-009 |
| DD-010 | Q10 — URL syntax validation semantics | WHATWG URL grammar is the parser. A syntax failure is a **broken link** (exit 1) with reason `malformed-url`. Syntax validation runs in both offline (default) and online mode | WHATWG URL is the browser-authoritative grammar; treating a malformed URL as "clean" would be a silent false negative | AMB-048, malformed-URL scenario class | CAP-009 |
| DD-011 | Q11 — JSON schema and closed failure-reason taxonomy | JSON output includes a top-level `schema_version: 1` field. Output is an array of finding objects with fields: `{file, line, column, link_target, verdict, reason}`. Indeterminate findings ARE included in JSON output. Compact JSON (not pretty-printed by default). Failure reason codes are the closed set in `failure-modes.md` | Schema stability needed for golden-file tests; `schema_version` enables future evolution | BV-004, EC-134 | CAP-013 |
| DD-012 | Q14 — Output ordering invariant | All findings sorted by `(NFC-normalized file path, line number, column number)` before emission, regardless of parallel scan order | R8 requires parallel scanning; the brief's "deterministic" promise requires stable output. These are reconciled by sorting | BV-015, EC-147 | DI-001 |
| DD-013 | Q17 — `--ignore` glob dialect and `--allow` prefix semantics | `--ignore`: globset dialect (BurntSushi, powers ripgrep); patterns matched against CWD-relative paths; `**` crosses directory boundaries. `--allow`: normalized URL prefix (scheme + authority + path components); NOT naive byte comparison — `--allow https://example.com` does NOT match `https://example.com.evil.tld` (domain suffix boundary enforced) | globset is already a dependency for `--ignore`; the `evil.tld` prefix hazard is documented in EC-092 and must be fixed at the domain level | EC-124..EC-131, EC-092 | CAP-011 |
| DD-014 | Q18 — Color/TTY and stdout/stderr contract | ANSI color suppressed when: output is not a TTY, or `NO_COLOR` is set, or `CLICOLOR=0`. `CLICOLOR_FORCE=1` overrides. **Findings go to stdout; diagnostics and progress go to stderr** (never mix) | Stdout purity is required for `mdlinkcheck --format json > report.json` piping; ANSI in CI logs is a real defect class | BV-010, BV-018, EC-135, EC-144, EC-145 | CAP-012, CAP-013 |
| DD-015 | Q4 — GitHub slug algorithm authority | The normative algorithm is **github-slugger v2**, verbatim as quoted in market-intelligence §4.1. Implement exactly in order: (1) rendered text content as input, (2) full Unicode `to_lowercase()`, (3) remove non-`\p{Word}`, non-hyphen, non-space chars, (4) 1:1 space→hyphen replacement (NO run collapsing, NO leading/trailing trim), (5) 0-based per-file duplicate counter via `while(occurrences contains result)` loop. Underscores retained. Emoji stripped. Known divergences from GitHub HTML pipeline: U+200C/U+200D ignored (acceptable per github-slugger #56) | Market-intelligence §4.1 quotes github-slugger v2 `index.js` verbatim; this is the reference algorithm used by markdownlint MD051 and remark | BV-002, AMB-051, AMB-052, AMB-054, AMB-056 | CAP-006 |
| DD-016 | §6 item 1 — GET fallback trigger set | HEAD→GET fallback on: `{400, 403, 404, 405, 501, 999}` plus transport-level failures (connection reset/closed on HEAD). Also fall back to GET on 429 (but don't immediately retry — pause the host and honor `Retry-After`). Brief's "GET fallback on 405 only" is too narrow and WILL produce false positives in practice | Market-intelligence §4.4 documents real-world servers that reject HEAD with 400/403/404/501; htmltest uses GET+Range as the recommended approach | AMB-030, EC-079, EC-080 | CAP-010 |

## Open Questions (Escalated to PRD)

The following AMB-* items cannot be resolved at L2 and are deferred to the PRD:

| Item | Brief-Val Ref | Why Deferred |
|------|--------------|-------------|
| Root-relative link resolution base (git root vs. scan root vs. CWD) | AMB-018 | Depends on git repo detection strategy — architecture decision |
| Redirect behavior details (max hops, downgrade policy, loop detection) | AMB-037 | Implementation detail; 10-hop max is an acceptable L3 default |
| Per-host concurrency caps and politeness delay for `--online` | AMB-040 | NFR/performance decision; default of 4 per host is an L3 default |
| User-Agent string format | AMB-041 | L3 implementation detail |
| `--insecure` flag and custom CA bundle | AMB-042 | L3 feature decision |
| Proxy support (`HTTP_PROXY`/`HTTPS_PROXY`) | AMB-043 | L3 implementation detail; honor env vars is the default |
| `--format text` as explicit name for default format | R5 ambiguities | L3 behavioral contract |
| Summary line format (trailing "N broken links across M files") | R6/R7 | L3 golden-file decision |
| R8 hardware baseline, corpus shape, build profile, statistic | BV-003 | Human decision required (Q12 from brief-validation.md) |
