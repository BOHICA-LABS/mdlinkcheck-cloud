---
document_type: adr
adr_id: ADR-006
status: accepted
date: 2026-08-05
version: "1.4"
subsystems_affected: [SS-05, SS-07]
supersedes: null
superseded_by: null
changelog:
  - version: "1.4"
    date: 2026-08-06
    change: "D-043 macOS-only platform directive: (1) Context section rewritten — removed Linux/Windows OS entries, restated on determinism grounds (macOS APFS is the only target filesystem). (2) Rationale replaced with canonical D-043 determinism wording verbatim. (3) unicode-normalization pinned from '0.1.x or 1.x' to exactly '0.1.24' per P4-018; added NFR-004-retirement note — pin is load-bearing for DI-001/DI-002/VP-008/VP-009 on determinism grounds, not portability. (4) Consequences updated: removed cross-platform consistency entry, added macOS-APFS-is-the-only-filesystem note (ADR-006 is MORE load-bearing, not less). (5) Alternatives and Source sections updated for macOS-only."
  - version: "1.3"
    date: 2026-08-06
    change: "P4 remediation: (1) removed SS-06 (slug) from subsystems_affected — SS-06 is governed by ADR-008 (slug algorithm); ADR-006 covers path model only (SS-05, SS-07). (2) Fixed DirEntries → DirIndex at line 63 body reference (stale type name superseded by api-surface.md and purity-boundary-map.md)."
  - version: "1.2"
    date: 2026-08-05
    change: "P2-M02 + P2-M12 remediation: updated Consequences to state VP-008 verifies both NFC normalization AND case-sensitivity (not just NFC); fixed Non-UTF-8 section to say 'app' (not 'scanner') performs Pass 1.5 directory reads — scanner traverses the scan root only, app opens out-of-scan targets in Pass 1.5"
  - version: "1.1"
    date: 2026-08-05
    change: "Phase 1d F-019 remediation: corrected macOS normalization form (NFD not NFC); aligned VP-008 proof method with VP-INDEX (proptest, not Kani); re-anchored DD-013->DD-002 and R5->NFR-004+D-006; corrected T12 cross-reference to T8 (case-sensitive filename); added Non-UTF-8 Filename Verdict section; removed OsStr from pure-core signature"
---

# ADR-006: Case-Sensitive NFC Strict Path Model

## Context

`mdlinkcheck` targets **macOS only** (MSRV 1.85 / `aarch64-apple-darwin`).

macOS APFS (and the older HFS+) is case-insensitive but case-preserving. APFS stores
filenames in **NFD-normalized form** at write time: a file named `café.md` with a
composed NFC accent character (U+00E9) is stored on disk with the decomposed NFD
sequence (`e` + U+0301). This is the root cause of the false-positive class documented
in DEC-004 and FM-007: a Markdown link written in NFC form is compared against the APFS
directory entry in NFD form, and a naive byte-equal comparison reports `broken` on a
perfectly valid link.

A naive path comparison (byte-level) will produce false positives on macOS when an
NFC-encoded link destination is compared against an NFD directory entry — they are the
same logical path but differ byte-for-byte.

DI-002 requires that path comparison be case-sensitive and NFC-normalized. This
invariant is property-tested (VP-008 — proptest, P1). D-006, NFR-003 (determinism),
and D-043 (macOS-only platform directive) establish the requirement.

## Decision

All path comparisons in `mdlinkcheck-core` use a two-step normalization:

1. **NFC Unicode normalization** (via `unicode-normalization` crate, **exactly `0.1.24`**
   — see tooling-selection.md §Runtime Dependencies; `0.1.x` and `1.x` are
   API-incompatible major versions; `0.1.x` is the correct branch. This pin **must
   survive any retirement of NFR-004**: it is load-bearing for DI-001 sort key,
   DI-002 path comparison, VP-008, and VP-009 on **determinism grounds** — not
   portability grounds.)
   Applied to both sides of any comparison. This is the canonical form for
   determinism (DD-002: path comparison decision; D-043: macOS-only rationale).
2. **Byte-level equality** after NFC normalization. No case-folding.

The `path_resolver` module's pure core function signature is:

```rust
pub fn files_match(a: &str, b: &str) -> bool
```

The signature takes `&str` (not `&OsStr`) because NFC normalization via
`unicode-normalization` operates on valid UTF-8 strings. The effectful shell (`scanner`)
is responsible for converting `OsStr` directory entries to `&str` before handing them
to `path_resolver`. See the **Non-UTF-8 Filename Verdict** section below for the
handling of non-convertible entries.

`DirIndex` is pre-populated by `app` (Pass 1.5, effectful shell) before passing
to `path_resolver`. The pure core receives only `&str` slices — no I/O. (Note:
scanner traverses the scan root in Pass 1; app opens out-of-scan targets in
Pass 1.5. See system-overview.md §Three-Phase Pipeline.)

## Rationale

**Determinism rationale (D-043 canonical wording — verbatim):** Strict case-sensitive +
NFC path comparison is retained on determinism grounds, independent of the platform
matrix. The tool must produce byte-identical output for byte-identical repository
content, and must not let the host filesystem's case-folding or Unicode normalization
behaviour influence link verdicts. macOS APFS is case-insensitive and stores filenames
in NFD; adopting native filesystem semantics would make verdicts a function of the
filesystem rather than of the repository content, which would break DI-001 determinism
and NFR-003 reproducibility. This holds on a macOS-only matrix and is not contingent
on cross-platform parity.

**NFC normalization removes false positives from macOS APFS NFD storage:** A link
destination in NFC form written in a Markdown file is compared against the NFD
directory entry that APFS stores on disk. Without NFC normalization, these
byte-sequences differ and the comparison returns `broken` — a false positive (DEC-004,
FM-007). Applying NFC to both sides before comparing makes the match succeed correctly.
On a macOS-only matrix this is the *only* filesystem, making this layer more critical,
not less.

**Avoiding macOS APFS case-folding:** We do NOT call `to_lowercase()` or any
case-folding function. APFS is case-insensitive, so it will resolve `Images/photo.png`
when the actual entry is `images/photo.png` — but the tool must NOT accept that as
clean. The tool must report it as BROKEN so the author fixes the link. Tool behavior
is a function of repository content (D-006, DI-001, NFR-003), not of what the host
filesystem happens to resolve at runtime.

**Case-sensitive filename trap (T8):** market-intelligence §4.3 T8 identifies the
`readme.md` vs `README.md` case mismatch as a common real-world trap. Our model
reports it as broken (correct per DI-002 case-sensitivity). The macOS NFD/NFC
false-positive trap (DEC-004, FM-007) is a distinct issue resolved by NFC
normalization above.

## Non-UTF-8 Filename Verdict

A directory entry whose name is not valid UTF-8 (`OsStr` is arbitrary bytes on any
Unix platform, including macOS — although APFS enforces UTF-8 at the volume level,
the Rust type system does not) cannot be NFC-normalized. When `app` encounters such
an entry during Pass 1.5 directory reads (scanner traverses only the scan root
in Pass 1; app opens out-of-scan target directories directly in Pass 1.5), it is
silently skipped in the comparison
pool for that directory. Any link whose destination would match that entry produces
**`broken` (reason: `file-not-found`)** — the same verdict as a genuinely absent file.

This is the correct conservative choice: we cannot verify the match without UTF-8,
and producing a false negative (reporting `clean` on an unmatchable path) would be
worse than a false positive. An additional diagnostic line is emitted to stderr
(`[warn] non-UTF-8 directory entry skipped: <parent-dir>`) to surface the condition
without failing the run. The exit code is not raised to 2 solely by a non-UTF-8
entry skipped in a directory listing; only a genuine I/O read error raises exit
code 2 (DI-011).

## Consequences

### Positive
- VP-008 proptest verifies both NFC normalization and case-sensitivity: real NFD/NFC combining-character pairs must match, and `files_match(s, s.to_uppercase())` must be false (D-006)
- DI-002 case-sensitive invariant is enforceable
- Verdicts are a function of repository content, not of macOS APFS filesystem behavior (DI-001, NFR-003)
- macOS APFS NFD false-positive eliminated (DEC-004, FM-007)
- **On a macOS-only matrix, macOS APFS is the only target filesystem. The
  `unicode-normalization` layer is the sole thing standing between repository content
  and verdict — there is no cross-platform CI run that would incidentally catch a
  missing normalization call. This makes ADR-006 more load-bearing, not less.**

### Negative / Trade-offs
- Users on macOS may be surprised when a "works locally" link shows as broken — APFS
  case-insensitivity means `Images/photo.png` resolves locally while the tool correctly
  reports BROKEN. This is the intended behavior: the link is incorrect per repository
  content, and the author must fix it (D-006, DI-001).
- `unicode-normalization` is an additional dependency (~10ms startup cost, negligible)
- Non-UTF-8 directory entries produce `file-not-found` rather than a distinct reason code;
  this is a known limitation acceptable for v1.0

### Status as of 2026-08-06

Accepted. Path model not yet implemented (Phase 3 scope). `unicode-normalization 0.1.24`
pinned in tooling-selection.md §Runtime Dependencies. This pin must survive any
retirement of NFR-004 (cross-platform portability): it is load-bearing for DI-001 sort
key, DI-002 path comparison, VP-008, and VP-009 on **determinism grounds** — not
portability grounds.

## Alternatives Considered

- **Case-insensitive comparison (APFS-aware):** Delegate case comparison to APFS at
  runtime (e.g., case-insensitive directory reads or `to_lowercase()`). Rejected:
  behavior would be a function of the filesystem, not repository content; violates
  DI-001 determinism and NFR-003 reproducibility. A link that "works on this machine"
  because APFS is case-insensitive is still a broken link per repository content.
- **NFC + case-fold always:** Always lowercase after NFC. Rejected: produces false
  negatives (links where case differs would be silently accepted); DI-002 violation.
- **OsStr byte equality only:** Simplest. Rejected: fails NFD/NFC mismatch (DEC-004, FM-007).

## Source / Origin

- DI-002: Case-sensitive NFC path comparison invariant
- DD-002: Path comparison decision (not DD-013; DD-013 is --allow prefix / --ignore glob dialect)
- D-006: Case-sensitive NFC path comparison requirement (not portability — that is NFR-004 scope, now under review for macOS-only)
- NFR-003: Output determinism — NFC comparison is required for byte-identical output (DI-001)
- D-043: macOS-only platform directive — rationale restated on determinism grounds
- VP-008: proptest harness for path NFC comparison (P1 — not Kani)
- DEC-004, FM-007: macOS APFS NFD false-positive documentation
