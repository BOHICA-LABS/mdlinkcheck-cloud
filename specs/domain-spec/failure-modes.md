---
document_type: domain-spec-section
level: L2
section: failure-modes
version: "1.4"
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
  - version: "1.4"
    date: 2026-08-06
    change: "P3-010 governance gap closure (DD-027): FM-001 and FM-003 Invariant Violated updated from '— (no governing DI; DD-015)' to DI-012 (slug computation fidelity); FM-002 updated to DI-013 (anchor-key uniqueness). Notes section first bullet updated to reflect closed gap; recommendation for a DI removed now that DI-012/DI-013 exist."
  - version: "1.3"
    date: 2026-08-06
    change: "Mechanical spec remediation (adversary P3-010): FM-001/002/003 — corrected Invariant Violated column from DI-001 (output ordering — wrong) to '— (no governing DI; DD-015)'. DI-001 is about deterministic output ordering; slug algorithm fidelity has no governing domain invariant. The normative authority is DD-015 (github-slugger v2). Note added to Notes section flagging this governance gap. FM-004 — removed dangling retired-holdout-scenario corpus fixture citation (the scenario was superseded by BV-013; DEC-006 is the visible fixture reference and is sufficient)."
  - version: "1.2"
    date: 2026-08-05
    change: "D-018/DD-024 ruling: HTTP 400 after GET fallback reclassified from `http-error` (broken) to `http-indeterminate` (indeterminate). Trigger updated in both rows. Rationale: 400 after GET means the server rejects the method, not the resource — treating it as broken produces false positives. P2-C03."
  - version: "1.1"
    date: 2026-08-05
    change: "Phase 1d gate remediation: F-032 (domain half) — target-unreadable trigger widened to explicitly include both OS read error (permission denied) and encoding error (invalid UTF-8 content); decision is ONE failure mode (rationale: same domain observable, same exit code, same remediation class). F-021 (domain half) — target-is-directory trigger corrected to require fragment presence (plain directory link without fragment is clean per BC-2.07.005 SF-002). Canonical verdict class verification: all 13 reason codes confirmed consistent with alive/broken/indeterminate/— taxonomy after all churn."
  - version: "1.0"
    date: 2026-08-05
    change: "Initial draft"
---

# Section 8: Failure Modes

> **Sharded L2 section (DF-021).** Navigate via `L2-INDEX.md`.

## Closed Failure Reason Taxonomy

The following reason codes form the **closed** taxonomy for link verdicts. Machine
reason codes are stable contract; human-readable messages may vary. All are emitted
in both text and JSON output (DD-011).

| Code | Verdict | Trigger | Exit Code |
|------|---------|---------|-----------|
| `file-not-found` | broken | Target file does not exist (including case mismatch on any OS) | 1 |
| `target-is-directory` | broken | Destination resolves to a directory AND a fragment is present (a plain directory link without a fragment is `clean` — BC-2.07.005 SF-002) | 1 |
| `broken-symlink` | broken | Symlink target does not exist (dangling symlink) | 1 |
| `anchor-not-found` | broken | Fragment does not match any anchor in the target file | 1 |
| `undefined-reference-definition` | broken | Reference label `[foo]` has no definition in the file | 1 |
| `malformed-url` | broken | External URL fails WHATWG URL parse | 1 |
| `http-error` | broken | External URL returned definitive error (404 or 410); 400 after GET fallback is `indeterminate`, not `broken` (D-018/DD-024) | 1 |
| `dns-failure` | broken | External URL host could not be resolved | 1 |
| `tls-error` | broken | TLS handshake failed (expired/self-signed/hostname mismatch) | 1 |
| `too-many-redirects` | broken | Redirect chain exceeded maximum hop count (10) | 1 |
| `target-unreadable` | — | File exists but cannot be processed: OS read error (permission denied, I/O failure) OR invalid UTF-8 content. **Decision (F-032): one failure mode, not two.** Both conditions share the same domain observable (file content unavailable), exit code (2), and remediation class (author must fix). Reported as I/O diagnostic on stderr, not a link verdict. | 2 |
| `http-timeout` | indeterminate | Request exceeded 10-second total timeout | 0 |
| `http-indeterminate` | indeterminate | 429, 5xx, bot-blocking 403/999 (after GET fallback), or 400 after GET fallback (D-018/DD-024 — server rejects method, not resource) | 0 |

## Runtime Failure Modes (FM-NNN)

Failure modes are implementation-level risks that produce wrong verdicts. Each maps
to one or more corpus fixtures.

| FM | Subsystem | Description | Invariant Violated | Corpus Fixture |
|----|-----------|-------------|-------------------|---------------|
| FM-001 | Slug computation | Hyphen-run collapsing (v1 behavior) applied instead of 1:1 substitution (v2): `AI & Automation` → `ai-automation` instead of `ai--automation` | DI-012 | EC-043, EC-044 |
| FM-002 | Slug computation | Duplicate-heading counter is 1-based instead of 0-based: second `## Setup` → `setup-2` instead of `setup-1` | DI-013 | EC-047, EC-048 |
| FM-003 | Slug computation | Underscore stripped instead of retained: `my_heading` → `my-heading` | DI-012 | EC-050, EC-051 |
| FM-004 | Parsing | Links inside fenced code blocks extracted → false positive on every code example | DI-004 | DEC-006 |
| FM-005 | Fragment handling | Fragment split AFTER percent-decode: `a%23b.md` treated as file `a` with fragment `b.md` | DI-003 | DEC-005, EC-053 |
| FM-006 | Path resolution | Case-insensitive OS delegation: `README.MD` passes on macOS silently | DI-002 | DEC-009, EC-036 |
| FM-007 | Path resolution | NFC/NFD mismatch: macOS-created file fails on Linux | DI-002 | DEC-004, EC-037 |
| FM-008 | Online checking | 5xx response classified as `broken` → CI false positive | DI-010 | EC-081 |
| FM-009 | Output | Parallel scan emits findings in traversal order without sorting → non-deterministic output | DI-001 | EC-147 |
| FM-010 | Filter | `--ignore` applied to anchor *targets*: ignored file's anchor table not built → false `anchor-not-found` | DI-006 | DEC-003, EC-074 |

## Notes

- FM-001 through FM-003 are all slug-algorithm compliance failures. FM-001 and FM-003
  are character-level transformation failures governed by DI-012 (slug computation
  fidelity). FM-002 is a duplicate-counter failure governed by DI-013 (anchor-key
  uniqueness). Their shared mitigation is unit tests against all DD-015 worked examples
  run as part of CAP-006's story. See DD-027 for the two-invariant model rationale.
- FM-004 (code-span extraction) is the highest-probability false-positive source;
  DEC-006 (BRIEF.md self-test) catches it trivially.
- FM-005 (fragment-before-decode) is the subtlest correctness trap — it only
  manifests with percent-encoded `%23` in destinations, which is rare but real.
- FM-006 and FM-007 both require the exact-case directory-entry comparison in CAP-007.
  No other surveyed tool implements this check (T12).

## F-032 Decision Record: target-unreadable Is One Failure Mode

**Decision:** `target-unreadable` remains a single reason code covering both OS read
errors (permission denied, I/O failure) and encoding errors (file content is not valid
UTF-8). The product-owner may split these into `target-unreadable` and `invalid-utf8`
at the L3 (BC/error-taxonomy) level if the distinct user-facing messages warrant it.

**Rationale (domain level):**
1. Both conditions have the same domain observable: the file's Markdown content cannot
   be processed by the tool.
2. Both route to the same exit code (2) via the same I/O error collection path in the
   architecture (see system-overview.md §Error Handling Strategy).
3. Both appear on stderr as a diagnostic, not in the findings list — neither is a
   link verdict (broken/indeterminate/clean).
4. The distinction matters for the user's fix action (fix CI permissions vs. re-encode
   the file) but not for the domain invariant (scan continues, exit 2 if any I/O error).

**Impact on verdict class consistency:** Confirmed — after all Phase 1d changes, all 13
reason codes continue to map to the canonical verdict classes: `broken` (exit 1),
`indeterminate` (exit 0), and `—` I/O error (exit 2). No code changed verdict class.
The `target-is-directory` fix (fragment discriminator) does not affect the verdict class
(`broken` remains correct when a fragment IS present); it narrows the trigger condition.
