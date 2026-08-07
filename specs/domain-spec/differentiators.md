---
document_type: domain-spec-section
level: L2
section: differentiators
version: "1.1"
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
  - version: "1.1"
    date: 2026-08-06
    change: "CV5-001 / D-043 survivor fix: 'Correct' anchor checking row — trap range T9–T15 → T9–T12, T14–T15 (T13 retired by D-043 macOS-only platform directive). Range sweep silently included the retired T13; now enumerated to exclude it."
  - version: "1.0"
    date: 2026-08-05
    change: "Initial draft"
---

# Section 9: Competitive Differentiator Traceability

> **Sharded L2 section (DF-021).** Navigate via `L2-INDEX.md`.

Grounded in market-intelligence §3. All differentiators traced to supporting
capabilities and invariants. See ASM-003: differentiation vs. lychee is explicitly
out of scope as a product goal — this section documents what is genuinely
differentiated, not what the product claims to be.

## Differentiator Map

| Differentiator | Competitive Verdict | Supporting CAPs | Key Invariants | Source |
|---|---|---|---|---|
| Strict anchor checking, **on by default** | **Genuinely differentiated** — every competitor either lacks anchor checking, gates it behind a flag, or has open false-positive/negative bugs | CAP-005, CAP-006, CAP-008 | DI-003, DI-007, DI-008 | Market-intel §1.3, §3 |
| **Correct** anchor checking (github-slugger v2 fidelity, percent-decode, two-pass) | **Genuinely differentiated** — lychee #1457/#1613/#1709, markdown-link-check #304, Sphinx #13620, markdownlint #945 all show broken anchor behavior | CAP-005, CAP-006, CAP-008 | DI-003, DI-008 | Market-intel §1.3, T9–T12, T14–T15 |
| Offline-by-default | **Differentiated as a default** (not a capability) — lychee, lint-roller can run offline but don't default to it; only remark-validate-links makes it the default | CAP-009 (offline validation), CAP-010 (online opt-in) | DI-010 (indeterminate) | Market-intel §3 |
| Source-level `file:line` reporting on the `.md` source | **Differentiated vs. post-render half of the field** — htmltest/muffet/Sphinx/mkdocs-plugins point at generated HTML | CAP-012, CAP-013 | DI-001 (ordering) | Market-intel §3 |
| Case-correct path resolution (exact-case directory-entry check) | **Potentially differentiated** — no surveyed tool performs exact-case verification; macOS users encounter silent false negatives | CAP-007 | DI-002 | Market-intel T12 |
| Deterministic exit codes | **Table stakes in principle, differentiated in practice** — most competitors don't document their exit codes; lychee already does this well but with inverted 1/2 | CAP-014 | DI-011 | Market-intel §1.2 |
| Single static Rust binary, no runtime | **Shared with lychee/liche/muffet/htmltest** — only differentiates against Node/Python/Ruby tools | ALL (implementation constraint) | — | Market-intel §3 |
| Speed | **Not a differentiator** — htmltest: 2000 files in 8.6 s; R8 (500 files, 5 s) is a floor, not a moat | CAP-001 (traversal), CAP-002 (parsing) | DI-001 (parallel+sort) | Market-intel §3 |

## Sharpest Defensible Claim

From market-intelligence §3:

> "Correct GitHub-compatible anchor checking, on by default, offline, reported at
> `file:line` in the Markdown source, with a non-flaky exit code."

Note: speed is **not** in this claim.

## Pilot Scope Reminder

The factory pilot justification for building mdlinkcheck despite lychee's existence:

1. **Pilot purpose:** exercise the VSDD factory pipeline on a bounded,
   correctness-intensive domain with a known-good answer key.
2. **Anchor correctness gap:** lychee has three open anchor-checking bugs
   (#1457, #1613, #1709) as of 2026-08-05. A narrower tool can be proved more
   correct.
3. **Narrow surface:** a smaller codebase is easier to subject to formal hardening
   (Phase 6: Kani, fuzzing, mutation testing).

This rationale must appear explicitly in the PRD introduction (R-005 mitigation).
