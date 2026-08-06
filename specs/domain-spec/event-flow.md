---
document_type: domain-spec-section
level: L2
section: event-flow
version: "1.0"
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
---

# Section 10: Domain Event Flow

> **Sharded L2 section (DF-021).** Navigate via `L2-INDEX.md`.

End-to-end scan lifecycle as domain-level state transitions. This is a reference
narrative; the normative processing stage definitions are in `events.md`.

## Scan Lifecycle

```
┌──────────────┐
│  CLI Invoked │
└──────┬───────┘
       │ argv + env
       ▼
┌──────────────────────────────────────────────────────────┐
│  Stage 1: Input Validation                               │
│  • Parse flags; validate paths; compile IgnoreRules,     │
│    AllowRules                                            │
│  ─ Invalid flag ──────────────────────────── exit 2 ──► │
└──────┬───────────────────────────────────────────────────┘
       │ validated path list
       ▼
┌──────────────────────────────────────────────────────────┐
│  Stage 2: File Discovery                                 │
│  • Recursive walk; .gitignore; extension filter;         │
│    deduplicate; skip dot-dirs; terminate symlink cycles  │
│  ─ Unreadable directory ──── I/O error (mark exit-2)    │
└──────┬───────────────────────────────────────────────────┘
       │ file list
       ▼
┌──────────────────────────────────────────────────────────┐
│  Stage 3: Parse + Anchor Table Construction (parallel)   │
│  • AST parse; extract links with byte offsets;           │
│    build anchor table per file                           │
│  ─ Non-UTF-8 ──────────────── I/O error (mark exit-2)   │
│  ─ ALL anchor tables must complete before Stage 4 ──►   │
│    (three-phase design Pass 1→1.5→2 per DI-008)          │
└──────┬───────────────────────────────────────────────────┘
       │ links + anchor tables
       ▼
┌──────────────────────────────────────────────────────────┐
│  Stage 4: Link Resolution                                │
│  • By link kind: file path check, anchor lookup,         │
│    URL syntax validation, --ignore/--allow filters;      │
│    external URLs → Stage 5 if --online                   │
└──────┬───────────────────────────────────────────────────┘
       │ initial verdicts
       ▼
┌──────────────────────────────────────────────────────────┐
│  Stage 5: External URL Liveness (--online only)          │
│  • Deduplicated ExternalUrl set; HEAD→GET fallback;      │
│    per-host rate limiting; Retry-After; 10 s timeout     │
│  • Verdict: alive / broken / indeterminate               │
└──────┬───────────────────────────────────────────────────┘
       │ final verdicts
       ▼
┌──────────────────────────────────────────────────────────┐
│  Stage 6: Report Assembly                                │
│  • Sort by (path, line, col) (DI-001)                    │
│  • Format as text or JSON (DD-014, DD-011)               │
└──────┬───────────────────────────────────────────────────┘
       │ stdout report + stderr diagnostics
       ▼
┌──────────────────────────────────────────────────────────┐
│  Stage 7: Exit Code Determination                        │
│  • I/O error → exit 2  (highest priority, DI-011)        │
│  • any broken → exit 1                                   │
│  • all clean / indeterminate only → exit 0               │
└──────────────────────────────────────────────────────────┘
```

## Key State Transitions

| From State | Event | To State | Invariant |
|-----------|-------|----------|-----------|
| discovering | unreadable dir | I/O error pending | DI-011 |
| parsing | non-UTF-8 | I/O error pending | DI-011 |
| anchor tables partial | link validated | FORBIDDEN | DI-008 |
| verdict=clean | second verdict assigned | FORBIDDEN | DI-005 |
| verdict=indeterminate | exit code = 1 | FORBIDDEN | DI-010 |
| any broken AND I/O error | exit code = 1 | FORBIDDEN (must be 2) | DI-011 |
| Stage 3 parallel | finding emitted before sort | FORBIDDEN | DI-001 |

## Three-Phase Design Detail

The three-phase design (Pass 1 → Pass 1.5 → Pass 2) per DI-008 is the most architecturally significant domain rule.
It means:

1. **Pass 1:** Parse all files in the scan set; build ALL anchor tables.
2. **Pass 1.5:** (Implicit gate) All anchor tables must be complete before any cross-file anchor lookup.
3. **Pass 2:** Resolve all links (can now look up any anchor table safely).

These passes may be interleaved at the file level (i.e., parse file A and build its
anchor table, then immediately start parsing file B) AS LONG AS no anchor lookup
into any file occurs until that file's anchor table is complete. A cross-file anchor
`[x](B.md#section)` must wait until B.md's anchor table is fully built.

In practice: build all anchor tables first (can be done in parallel), then resolve
all links (can also be done in parallel).
