---
document_type: domain-spec-section
level: L2
section: assumptions
version: "1.2"
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
  - version: "1.2"
    date: 2026-08-06
    change: "D-043 (macOS-only platform directive): ASM-004 updated — platform matrix narrowed to macOS-only; Linux and Windows removed; Status changed to 'updated (D-043)'; validation method updated. ASM-005 validation method updated — 'macOS and Linux CI runners' narrowed to 'macOS CI runner (macos-latest)'."
  - version: "1.1"
    date: 2026-08-05
    change: "Orchestrator ruling DD-021: removed Holdout candidate designation from ASM-005 (performance baseline enforced by NFR-008/VP-022 in benches/) and ASM-008 (slug fidelity enforced by NFR-006/VP-018 via DD-015 vectors). Corrected stale line-44 note; replaced false assertion with the governing holdout policy."
  - version: "1.0"
    date: 2026-08-05
    change: "Initial draft"
---

# Section 6: Assumptions

> **Sharded L2 section (DF-021).** Navigate via `L2-INDEX.md`.

Each assumption has a Status, Confidence, Impact-if-Wrong, and Validation Method.
Holdout candidates (Confidence=Low or Impact-if-Wrong=HIGH and unvalidated) are
flagged. All assumptions start as `unvalidated`.

| ASM | Title | Status | Confidence | Impact-if-Wrong | Validation Method |
|-----|-------|--------|-----------|----------------|------------------|
| ASM-001 | Rust MSRV 1.85 is sufficient for the dependency stack | unvalidated | High | HIGH — build failure in CI | Run `cargo build` in CI with `rust-version = "1.85"` in Cargo.toml; verify clap 4.6.x and ureq 3.3.0 pass |
| ASM-002 | pulldown-cmark 0.13.4 correctly implements CommonMark 0.31.2 + GFM for link/heading extraction | unvalidated | High | HIGH — incorrect link extraction and false positives | Run pulldown-cmark against the CommonMark spec test suite; compare link extraction output against reference |
| ASM-003 | This is a factory pilot; differentiation vs. lychee is explicitly out of scope | confirmed (human) | Confirmed | LOW — no engineering impact | N/A — human decision recorded |
| ASM-004 | Platform matrix is macOS only (`macos-latest`) | updated (D-043) | Confirmed | LOW — platform matrix is now macOS-only; Linux and Windows are out of scope | macOS CI runner (`macos-latest`) only; previous assumption of macOS + Linux + Windows superseded by D-043 |
| ASM-005 | R8 5-second target is achievable in release build on a modern laptop with warm filesystem cache for 500 `.md` files with offline checks only | unvalidated | Medium | MEDIUM — R8 becomes unmeasurable NFR | Build acceptance corpus of 500 `.md` files; run `hyperfine` in release mode on macOS CI runner (`macos-latest`); report p95 over 10 runs. |
| ASM-006 | A `README.md` will be created as a tracked deliverable before acceptance testing | confirmed (human via D-009) | Confirmed | MEDIUM — acceptance criterion "runs clean on this repo's own README" is unsatisfiable without it | Create README.md as an explicit story deliverable; run `mdlinkcheck README.md` as a CI gate |
| ASM-007 | `tests/corpus/` with an expected-classification manifest is a first-class story deliverable | confirmed (human via D-009) | Confirmed | HIGH — primary success criterion ("correctly classifies the acceptance corpus") cannot be evaluated | Corpus story specifies: one fixture per failure class (see FM-NNN), one trap per false-positive class (see DEC-NNN), and machine-readable manifest |
| ASM-008 | GitHub's heading slug algorithm has not changed since github-slugger v2.0.0 (2023) and the verbatim rules in market-intelligence §4.1 are current | unvalidated | Medium | HIGH — all anchor resolution results are wrong if GitHub diverged | Run test fixtures from DD-015 worked examples against live GitHub-rendered pages; compare slugs. |
| ASM-009 | GFM bare-URL autolinks (plain `https://x.com` in prose) are NOT in scope for this release | confirmed (D-009) | Confirmed | LOW — minor feature gap vs. comrak | N/A — explicit scope decision; document limitation in README |
| ASM-010 | Inline suppression directives are NOT in scope for this release | confirmed (D-009) | Confirmed | LOW — users with unavoidable false positives must use `--ignore`/`--allow` flags | N/A — explicit scope decision recorded in BV-009 |

## Notes

- ASM-001 and ASM-002 are validated by the standard TDD story cycle (first compile + first test pass).
- ASM-005 requires a performance benchmark story; R8 cannot become a Verification Property (VP) without the hardware/corpus/statistic specification — those are open questions escalated to the PRD (BV-003). ASM-005 is NOT a holdout: its validation is enforced continuously by the NFR-008 regression gate / VP-022 in `benches/` (DD-021).
- ASM-008 is the most consequential unvalidated assumption: if GitHub's algorithm has diverged from github-slugger v2, every anchor check is wrong. Mitigate by isolating the slug algorithm in a single module with worked examples as unit tests (R-001). ASM-008 is NOT a holdout: its DD-015 worked examples are enforced on every commit via prd-supplements/test-vectors.md (NFR-006 / VP-018, DD-021).
- **Holdout policy (DD-021):** An assumption may be designated a holdout candidate only if no visible artifact (prd.md, behavioral-contracts/, prd-supplements/, benches/) contains its validation vectors. Any designation must name the specific hidden edge cases or benchmark scenarios that carry the evaluation signal. Designating a scenario that is already continuously enforced in the visible suite provides no holdout value and wastes Phase 4 evaluation capacity.
