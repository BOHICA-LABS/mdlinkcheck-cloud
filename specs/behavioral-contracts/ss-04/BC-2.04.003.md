---
document_type: behavioral-contract
level: L3
version: "1.5"
status: draft
producer: vsdd-factory:product-owner
timestamp: 2026-08-10T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/specs/domain-spec/L2-INDEX.md
  - .factory/planning/brief-validation.md
  - .factory/planning/market-intelligence.md
input-hash: "07d983a"
traces_to: .factory/specs/domain-spec/L2-INDEX.md
origin: greenfield
extracted_from: null
subsystem: "SS-04"
capability: "CAP-004"
lifecycle_status: active
introduced: v1.0.0
modified:
  - "v1.1: added explicit acceptance criteria for both link_extractor.rs and anchor_table.rs per SF-003 in architecture feasibility-review.md; clarified cross-module testing obligation"
  - "v1.2: (F-007) VP-TBD backfill from VP-INDEX v1.1"
  - "v1.4: (BI-052 remediation P7-S3-002) VP table row 2 corrected: anchor_table.rs side was attributed to VP-014 but VP-014 only covers link_extractor.rs code-context exclusion. The anchor_table::build property has no current VP; integration test required in story. Row 2 changed from VP-014 to bare dash."
  - "v1.5: (GATE-58/POL-14) VP-NNN column bare em-dash is non-conforming per POL-14; replaced with VP-NONE (D-078) — proof method is integration, so VP-NONE is accepted."
  - "v1.3: (WS-4-B) Proof-method join repair: both VP-014 rows 'unit test (...)' → 'integration' (VP-INDEX authority); contextual annotations preserved."
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.04.003: ATX Headings Inside Fenced Blocks Do Not Create Anchor Entries

## Description
Lines that look like ATX headings (`# Title`) inside fenced code blocks must NOT be extracted
as headings and must NOT create entries in the anchor table. R4 covers link extraction from code;
this BC covers heading extraction from code. This is a cross-module concern: the pulldown-cmark
event model prevents `Tag::Heading` events inside `Tag::CodeBlock` by construction, but BOTH
`link_extractor.rs` (which never extracts links from code blocks) AND `anchor_table.rs` (which
never adds entries for content inside code blocks) must be verified independently.

**Story-writer note (SF-003):** The story implementing this BC MUST include acceptance criteria
in BOTH modules:
- `link_extractor.rs`: heading-like lines inside fenced code do not produce links (see BC-2.04.001)
- `anchor_table.rs`: `anchor_table::build` receives no `Tag::Heading` events for content inside
  `Tag::CodeBlock`; verified by a dedicated unit test on `anchor_table::build` directly

VP-014 covers the `link_extractor.rs` side. No current VP covers the `anchor_table.rs` side;
the story must add an integration test asserting `anchor_table::build` produces no entry for
heading-like lines inside fenced code.

## Preconditions
1. A fenced code block contains a line that starts with `#` (one to six hashes).
2. The file has been parsed by pulldown-cmark into an AST event stream.

## Postconditions
1. **link_extractor.rs side:** The heading-like line inside the code block produces no link
   in the extracted link list (by construction: it is `Event::Text` inside `Tag::CodeBlock`,
   not a link or heading event). Covered by BC-2.04.001.
2. **anchor_table.rs side:** `anchor_table::build` receives no `Tag::Heading` event for the
   heading-like line (pulldown-cmark emits it as `Event::Text` inside `Tag::CodeBlock`). No
   anchor table entry is added for that line.
3. A link in the same file referencing the slug of the heading-like line receives `anchor-not-found`.

## Invariants
1. pulldown-cmark's AST never emits `Tag::Heading` events for content inside `Tag::CodeBlock`.
   This BC relies on this structural guarantee — it is free by construction but must be
   explicitly verified in both modules.
2. `anchor_table::build` consumes only `Tag::Heading` events; since none are emitted for
   code block content, exclusion is automatic and testable.
3. This BC is the anchor-side complement to BC-2.04.001 (link-extraction side).

## Edge Cases
| EC | Description |
|----|-------------|
| EC-065 | Fenced block with `# Fake Heading` + `[x](#fake-heading)` |

## Canonical Test Vectors
| Input | Expected Output | Category |
|-------|----------------|----------|
| Fenced block with `# Fake Heading` followed by `[x](#fake-heading)` | Exit 1; anchor-not-found | happy-path |

## Acceptance Criteria (story-writer routing)

| Module | Acceptance Criterion | Test Method |
|--------|---------------------|-------------|
| `link_extractor.rs` | No links extracted from fenced code block containing heading-like lines | Unit test (covered by BC-2.04.001 story) |
| `anchor_table.rs` | `anchor_table::build(events)` produces zero entries for a file whose only heading-like content is inside a fenced code block | **Dedicated unit test** on `anchor_table::build` directly — do NOT rely solely on integration test |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-014 | Heading-like lines in code blocks not extracted as links | integration (link_extractor.rs) |
| VP-NONE | anchor_table::build produces no entry for heading-like lines inside fenced code — no current VP; integration test required in story | integration |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-004 ("Code Context Exclusion") per capabilities.md §CAP-004 |
| Capability Anchor Justification | CAP-004 ("Code Context Exclusion") per capabilities.md §CAP-004 — structural AST exclusion applies equally to link extraction and anchor table construction |
| L2 Domain Invariants | DI-004 |
| Brief Requirement | R4, AMB-061 |
| Architecture Module | `link_extractor.rs` (SS-04) + `anchor_table.rs` (SS-05) — joint ownership; see Acceptance Criteria above |
| Stories | [filled by story-writer] |

## Related BCs
- BC-2.05.002 — sibling (heading extraction into anchor table; this BC is the code-block exclusion complement)
- BC-2.04.001 — composes with (link-extraction side of the same fenced code block exclusion guarantee)
