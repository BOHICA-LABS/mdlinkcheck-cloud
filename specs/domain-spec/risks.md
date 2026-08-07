---
document_type: domain-spec-section
level: L2
section: risks
version: "1.2"
status: draft
producer: business-analyst
timestamp: 2026-08-05T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/planning/brief-validation.md
  - .factory/planning/market-intelligence.md
input-hash: "62dc24f"
traces_to: L2-INDEX.md
changelog:
  - version: "1.2"
    date: 2026-08-06
    change: "CV5-001 / D-043 survivor fixes: (1) R-002 trap range T1–T16 → T1–T12, T14–T16 (T13 retired by D-043); (2) R-008 NFR-002 reference corrected from '15s p95, Linux CI' to '10s p95, macos-latest' (NFR-002 was retargeted by D-043 macOS-only directive)."
  - version: "1.1"
    date: 2026-08-05
    change: "Phase 1d gate remediation: added R-008 (performance acceptance ceiling too loose to detect regression — flagged by spec-reviewer and architect, substantiated by D-013 two-tier model and system-overview.md §Performance Architecture) and R-009 (memory budget corpus-shape-dependent — flagged by F-032 / system-overview.md §Memory Model); updated Risk-to-Capability Tracing table."
  - version: "1.0"
    date: 2026-08-05
    change: "Initial draft"
---

# Section 7: Risk Register

> **Sharded L2 section (DF-021).** Navigate via `L2-INDEX.md`.

All risks start as `open`. NFR candidates and security-focus items are flagged.

| R | Title | Likelihood | Impact | Category | Status | Mitigation |
|---|-------|-----------|--------|----------|--------|-----------|
| R-001 | **Anchor slug fidelity drift** — GitHub changes its heading-anchor algorithm after ship; all anchor checks produce wrong results | Low | HIGH | reliability | open | Pin algorithm in an isolated module (one function, exhaustive unit tests against DD-015 worked examples). Track github-slugger releases. ASM-008. **NFR candidate: yes** |
| R-002 | **False positives in anchor checking** — the primary differentiator is also the highest-risk surface; every surveyed competitor has anchor bugs | Medium | HIGH | reliability | open | Acceptance corpus carries a fixture for every trap T1–T12, T14–T16 (market-intel §4.3; T13 retired by D-043) and every DEC-NNN. Adversarial review specifically targets anchor resolution. **NFR candidate: yes** |
| R-003 | **`--online` GET fallback too narrow** — brief says "GET fallback on 405 only"; real servers reject HEAD with 400/403/404/501/999; a narrow fallback produces exactly the CI false positives the brief exists to prevent | Low (mitigated by DD-016) | HIGH | reliability | open | Decision DD-016 widens fallback to `{400, 403, 404, 405, 501, 999}` plus transport failures. Indeterminate verdict (D-008) absorbs the remainder. **NFR candidate: yes** |
| R-004 | **Case-sensitivity check (T12) surprises users** — no surveyed tool performs exact-case filename verification; macOS users will encounter `broken` verdicts that the OS itself would not catch | Medium | MEDIUM | reliability | open | DI-002 is non-negotiable (it is the "deterministic" promise). Mitigate UX impact with a distinct reason string `file-not-found` (case mismatch detectable by human) and documentation. |
| R-005 | **"Why not just use lychee?"** — lychee 0.24.2 is a feature superset of mdlinkcheck R1–R8 with ~169k crates.io downloads; downstream agents or reviewers may question scope | High | MEDIUM | business | open | ASM-003 records the pilot rationale explicitly. Honest differentiators: (1) anchor checking correct and on by default (lychee has three open anchor bugs), (2) pilot scope. State in PRD introduction. **Security focus: no** |
| R-006 | **Exit code semantics inverted vs. lychee** — lychee: 2=link failures, 1=runtime; mdlinkcheck R7: 1=broken, 2=I/O. Anyone switching tools will misread CI status | Medium | MEDIUM | reliability | open | Brief R7 is frozen. Document the divergence prominently in README and `--help`. Cannot change. |
| R-007 | **Maintenance bus factor** — category littered with abandoned tools (liche deprecated, remark-validate-links archived 2026-06-04); a pilot tool with no maintainer plan joins them | Low | LOW | business | open | Accept explicitly for pilot scope. Note in PRD. Not a blocker. |
| R-008 | **Performance acceptance ceiling too loose to detect regression** — NFR-001 (5s p95, Apple Silicon) and NFR-002 (10s p95, macos-latest) are ~25–100× looser than the realistic baseline: 500 `.md` files ≈ 2.5 MB, a typical release-profile offline run completes in ~50–200 ms. Any algorithmic regression that keeps wall-clock under 5s passes the acceptance gate undetected and can compound silently across releases | Medium | HIGH | performance | open | Two-tier model (D-013): the Tier 2 regression gate (~500ms p95 on Tier A CI corpus, enforced by VP-022 on every commit) is calibrated to catch regressions that the acceptance ceiling cannot see. NFR-001/002 remain the release-gate ceilings. **NFR candidate: yes** |
| R-009 | **Memory budget corpus-shape-dependent** — NFR-005 (512 MB peak RSS) is valid for the 500-file reference corpus but is not a universal guarantee: each `.md` file is read entirely into memory before parse (BOM/CRLF normalization is buffer-wide), and all anchor tables across the anchor-target universe are held in memory simultaneously during Pass 2. A repo containing a small number of very large generated `.md` files (e.g., auto-generated API reference, hundreds of MB each) may breach NFR-005 without warning | Low | MEDIUM | reliability | open | Documented scope limitation: the tool targets source documentation repos (small files, many files), not generated output repos (few files, enormous each). No explicit per-file size bound is enforced in v1.0. Migration path: pulldown-cmark incremental/streaming parse. NFR-005 ceiling must be interpreted as corpus-shape-dependent. **NFR candidate: yes** |

## Risk-to-Capability Tracing

| Risk | Affected Capabilities | Rationale |
|------|--------------------|-----------|
| R-001 | CAP-006 | Slug computation is the only capability affected by algorithm drift |
| R-002 | CAP-005, CAP-006, CAP-008 | All three anchor-related capabilities are in scope for false positives |
| R-003 | CAP-010 | Liveness checking is where the narrow fallback manifests |
| R-004 | CAP-007 | Path resolution performs the case-sensitive directory-entry lookup |
| R-005 | ALL | Business risk applies to the full product surface |
| R-006 | CAP-014 | Exit code determination is the only affected capability |
| R-007 | ALL | Maintenance risk applies to the full product |
| R-008 | — (system-wide) | Performance regression risk applies to all pipeline passes; no single capability owns it. Regression gate monitors end-to-end latency (D-013 / VP-022) |
| R-009 | CAP-002, CAP-005 | Markdown parsing (CAP-002) buffers each file whole; anchor table construction (CAP-005) holds all tables in memory through Pass 2 — these are the dominant RSS contributors |
