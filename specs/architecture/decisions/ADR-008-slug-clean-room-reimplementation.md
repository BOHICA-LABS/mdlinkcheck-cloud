---
document_type: adr
adr_id: ADR-008
status: accepted
date: 2026-08-06
version: "1.0"
subsystems_affected: [SS-05, SS-06]
supersedes: null
superseded_by: null
changelog:
  - version: "1.0"
    date: 2026-08-06
    change: "Initial draft — records the clean-room github-slugger v2 reimplementation decision, HTML-text rendering adjudication (P4-001), NFC/NFD normalization ruling (P4-013), and ASM-008 divergence-detection protocol. Authored as P4-008 remediation to provide the missing ADR for the product's headline differentiator (SS-06 slug module)."
---

# ADR-008: Clean-Room github-slugger v2 Reimplementation

## Context

The product's headline differentiator is byte-for-byte parity with GitHub's heading
anchor algorithm as implemented by `github-slugger@2.0.0` (DD-015). Three
implementation strategies exist for achieving this parity in a Rust CLI:

1. **FFI / WASM bridge:** Embed the Node.js `github-slugger` library via Napi-rs or
   wasmer and call it at runtime.
2. **Port (gene transfusion):** Translate the JavaScript implementation into Rust
   line-by-line.
3. **Clean-room reimplementation:** Independently re-derive the algorithm from its
   behavioral specification (DD-015, market-intelligence §4.1) and verify against a
   pinned oracle corpus.

The slug module is the product's highest-risk correctness surface: six verification
properties (VP-001..003, VP-012, VP-018, VP-026), CRITICAL tier, the only module with
differential oracle testing. It is also a pure function target for Kani proofs (VP-001:
totality; VP-002: determinism; VP-003: injectivity).

`github-slugger@2.0.0` is a 47-line JavaScript file. Its behavior is fully specified
by the seven rules in DI-012 plus the duplicate-counter semantics in DI-013. There is
no complex state machine, no external API, and no external dependencies.

## Decision

Use a **clean-room Rust reimplementation** of the github-slugger v2 algorithm in
`crates/mdlinkcheck-core/src/slug.rs`. The implementation is derived from DI-012 and
DI-013 and verified against the VP-026 differential oracle (committed corpus of
`github-slugger@2.0.0` outputs).

The algorithm pin is `github-slugger@2.0.0` (exact version, npm), as specified by
DD-015. No other version is authoritative.

### HTML-Text Rendering Adjudication (P4-001)

**Ruling (confidence: HIGH):** Inline HTML tags in headings do NOT suppress the
surrounding text. The text between HTML tags IS retained as rendered text content.

Evidence:
1. **pulldown-cmark event model (ADR-003):** For `## \`code\` <em>text</em>`, the
   event stream is: `Code("code")`, `Text(" ")`, `InlineHtml("<em>")`,
   `Text("text")`, `InlineHtml("</em>")`. `InlineHtml` events carry only the raw
   tag bytes (e.g., `<em>`); the text "text" between the tags arrives as a separate
   `Text` event. An implementer collecting `Code` and `Text` events naturally
   retains "text". Only the tag markup itself is discarded — not the text content.
2. **rehype-slug / HAST behavior:** rehype-slug uses `hast-util-to-string` which
   returns the text content of the HAST tree. In HAST, `<em>text</em>` has a child
   text node "text"; `toString()` returns "text". This is the same as DI-012 rule 1.
3. **DI-012 rule 1:** "HTML tags contribute nothing (tag tokens are stripped; their
   visible text content, if any, is retained)" is the correct statement.

**Discriminating example:** `## \`code\` <em>text</em>`
- Rendered text (correct): `"code text"` → slug `"code-text"`
- Rendered text (wrong, text discarded): `"code "` → slug `"code-"`

**BC-2.06.001 Invariant 2** currently states the opposite (text DISCARDED) — this
is a BC-level error. See product-owner handoff item in the P4 remediation report:
BC-2.06.001 Invariant 2 must be corrected to match DI-012 rule 1.

### NFC/NFD Normalization Ruling (P4-013)

**Ruling:** The slug algorithm does **not** normalize heading text to NFC or NFD
before processing. Input is processed byte-for-byte as received from the pulldown-cmark
AST renderer. This matches `github-slugger@2.0.0` behavior.

**Consequence:** NFC and NFD representations of the same logical character produce
different slugs:
- NFC `"résumé"` (U+00E9 = single codepoint, `\p{L}`) → retained → `"résumé"`
- NFD `"re\u{0301}sume\u{0301}"` (combining acute U+0301 = `\p{Mn}`) → U+0301
  stripped as non-word character → `"resume"`

**macOS asymmetry:** On macOS HFS+/APFS, headings may be stored in NFD. A markdown
editor writing `## Résumé` in NFD and a link author writing `[x](#résumé)` in NFC
will produce anchor key `"resume"` and fragment `"résumé"` respectively — these
will not match, producing `anchor-not-found`. This is a known asymmetry documented
in DI-012 (Normalization rule); it is not a product bug given the byte-for-byte
parity constraint.

VP-026 oracle MUST include both NFC (R-009) and NFD (OR-010) runs with their
respective expected outputs to verify the implementation handles each form correctly.

### ASM-008 Divergence-Detection Protocol

`github-slugger@2.0.0` is the oracle. If GitHub ever changes its algorithm, the
oracle becomes stale. VP-026's committed oracle corpus with the CI freshness check
(`just regen-slug-vectors`) is the divergence tripwire:

1. The oracle fixture embeds `github_slugger_version: "2.0.0"` and the generator
   script SHA-256.
2. The CI freshness check regenerates the oracle from the committed `tools/package.json`
   (pinned `github-slugger@2.0.0 exact`) and asserts the diff is a no-op (excluding
   the `generated_at` timestamp field — see VP-026 §CI check for the exact `jq` diff
   command).
3. Any upgrade of `github-slugger` requires regenerating the corpus, reviewing the
   diff for changed expected values (= the algorithm changed), and updating DD-015.

## Rationale

**Clean-room over FFI:** An FFI bridge to Node.js adds a runtime dependency on Node.js
(not acceptable for a CLI distributed as a single binary), a WASM binary embedded in
the Rust binary (large, slow initialization), or a spawned subprocess (latency and
portability issues). For a 47-line algorithm fully specified by 7 rules, a clean-room
implementation is faster, more maintainable, and fully verifiable by Kani (FFI calls
cannot be formally proven).

**Clean-room over direct port:** A line-by-line port of the JavaScript produces code
that is hard to read as Rust, may carry JavaScript idioms that perform differently
under the Unicode normalization assumptions of the Rust regex engine, and forecloses
independent formal verification. A spec-derived implementation using Rust's
`\p{Word}` Unicode character class produces clean, idiomatic Rust that Kani can prove.

**Version pin (v2.0.0):** github-slugger v1.x used different hyphen-collapse behavior
(FM-001 shape). v2.0.0 is the version deployed on GitHub.com as of DD-015's recording
date. Only v2.0.0 is authoritative.

## Consequences

### Positive
- `slug.rs` is a pure Rust function with no runtime dependencies
- Kani proofs (VP-001: totality, VP-002: determinism, VP-003: injectivity) are
  feasible against a pure function
- VP-026 differential oracle provides divergence detection if GitHub changes the
  algorithm
- Single binary artifact — no Node.js or WASM runtime required

### Negative / Trade-offs
- If `github-slugger` behavior changes (algorithm update), the clean-room
  implementation must be updated manually — the CI oracle check (ASM-008 tripwire)
  catches this
- Implementer must understand the Unicode character properties used by the original
  (`\p{Word}`, `\p{Mn}`, etc.) — DI-012 rule set and the VP-026 oracle corpus are
  the specification

### Status as of 2026-08-06

Accepted. Not yet implemented (Phase 3 scope). VP-026 oracle corpus not yet generated.

## Alternatives Considered

- **FFI bridge to Node.js `github-slugger`:** Rejected. Adds Node.js runtime
  dependency; incompatible with single-binary distribution goal (NFR-004); FFI calls
  are opaque to Kani formal proofs.
- **WASM port of `github-slugger`:** Rejected. WASM embedding adds ~200KB binary
  size; initialization latency on every run; complex Cargo build graph.
- **Depend on `unicode-slug` crate:** No Rust crate exactly matches `github-slugger
  v2` behavior — specifically the 1:1 space→hyphen rule (rule 3, DI-012) differs from
  most slug libraries which collapse runs.

## Source / Origin

- DD-015: Algorithm pin decision — `github-slugger@2.0.0` is the canonical reference
- DI-012: Slug computation fidelity invariant (all 7 rules)
- DI-013: Anchor-key uniqueness invariant (0-based duplicate counter)
- ASM-008: Divergence risk — if GitHub's algorithm changes, all anchor checks are wrong
- VP-018: DD-015 worked examples corpus
- VP-026: Differential oracle against `github-slugger@2.0.0`
- market-intelligence.md §4.1: Primary reference for DI-012 rule derivation
- gene-transfusion-assessment.md: Clean-room vs. port decision for slug module
