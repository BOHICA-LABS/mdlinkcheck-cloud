---
document_type: adr
adr_id: ADR-006
status: accepted
date: 2026-08-05
version: "1.3"
subsystems_affected: [SS-05, SS-07]
supersedes: null
superseded_by: null
changelog:
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

`mdlinkcheck` operates across three OS families:
- macOS: HFS+/APFS — case-insensitive but case-preserving by default; **NFD-normalized by default**
  (HFS+ applies Unicode NFD decomposition to all filenames at write time; a file named `cafe.md`
  with a composed accent character in NFC is stored on disk in NFD form. This is the root cause
  of the macOS-to-Linux false-positive class documented in DEC-004 and FM-007.)
- Linux: ext4/btrfs — case-sensitive; no automatic normalization (bytes stored as-is)
- Windows: NTFS — case-insensitive; stores filenames as UTF-16 without applying Unicode
  normalization (no automatic NFC or NFD; OS comparison uses Unicode case-folding internally)

A naive path comparison (byte-level) will produce false positives on macOS when an NFC-encoded
link destination is compared against an NFD directory entry — they are the same logical path but
differ byte-for-byte. Conversely, a "case-fold everything" model will produce false negatives on
Linux (e.g., `foo.md#Heading-One` vs `foo.md#heading-one` — different anchors on a
case-sensitive FS).

DI-002 requires that path comparison be case-sensitive and NFC-normalized on ALL platforms.
This invariant is property-tested (VP-008 — proptest, P1) and applies uniformly regardless
of host OS. NFR-004 and D-006 establish the cross-platform requirement.

## Decision

All path comparisons in `mdlinkcheck-core` use a two-step normalization:

1. **NFC Unicode normalization** (via `unicode-normalization` crate, `0.1.x` or `1.x`)
   applied to both sides of any comparison. This is the canonical form for cross-OS
   consistency (DD-002: cross-platform path comparison decision).
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

**Case-sensitive is correct for cross-platform consistency:** If we accept the
invariant that a broken link is one where no file with that exact NFC-normalized
path exists in the file tree, then case-sensitivity is the right model. A link
`[img](./Images/photo.png)` on a Linux system fails if the file is `images/photo.png` —
the user must fix the link. This is the correct behavior (NFR-004, D-006).

**NFC normalization removes false positives from macOS NFD storage:** macOS HFS+/APFS
stores filenames in NFD (decomposed) form. A link destination in NFC form written in a
Markdown file will be compared against the NFD directory entry that macOS created.
Without NFC normalization, these byte-sequences differ and the comparison would return
`broken` — a false positive (NFR-004, D-006, DEC-004, FM-007). Applying NFC to both
sides before comparing makes the match succeed correctly.

**Avoiding OS-specific case-folding:** We do NOT call `to_lowercase()` or any
case-folding function. This means on macOS/Windows, a link `../Images/photo.png`
pointing to a file named `../images/photo.png` will produce a BROKEN finding. This
is intentional: the link is technically broken even if the OS happens to resolve it,
because the same repo deployed to Linux would fail. Tool behavior must be consistent
across OSes (NFR-004, D-006).

**Case-sensitive filename trap (T8):** market-intelligence §4.3 T8 identifies the
`readme.md` vs `README.md` case mismatch as a common real-world trap. Our model
reports it as broken (correct per DI-002 case-sensitivity). The macOS NFD/NFC
false-positive trap (DEC-004, FM-007) is a distinct issue resolved by NFC
normalization above.

## Non-UTF-8 Filename Verdict

A directory entry whose name is not valid UTF-8 (possible on Linux — `OsStr` is
arbitrary bytes on Unix) cannot be NFC-normalized. When `app` encounters such
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
- Consistent behavior on macOS/Linux/Windows
- macOS NFD false-positive eliminated (DEC-004, FM-007)

### Negative / Trade-offs
- Users on macOS/Windows may be surprised when a "works locally" link shows as broken
  after a Linux CI run — but this is the correct behavior and worth documenting
- `unicode-normalization` is an additional dependency (~10ms startup cost, negligible)
- Non-UTF-8 directory entries produce `file-not-found` rather than a distinct reason code;
  this is a known limitation acceptable for v1.0

### Status as of 2026-08-05

Accepted. Path model not yet implemented (Phase 3 scope). `unicode-normalization`
crate version must be pinned when workspace `Cargo.toml` is written.

## Alternatives Considered

- **Case-insensitive comparison (OS-aware):** Detect the host OS at runtime and apply
  case-folding on macOS/Windows. Rejected: behavior would differ by OS; CI would
  produce different results than local runs; untestable portably.
- **NFC + case-fold always:** Always lowercase after NFC. Rejected: produces false
  negatives on case-sensitive filesystems (DI-002 violation).
- **OsStr byte equality only:** Simplest. Rejected: fails NFD/NFC mismatch (DEC-004, FM-007).

## Source / Origin

- DI-002: Case-sensitive NFC path comparison invariant
- DD-002: Cross-platform path comparison decision (not DD-013; DD-013 is --allow prefix / --ignore glob dialect)
- NFR-004 + D-006: Cross-platform path comparison requirement (not R5; R5 is --ignore/--allow)
- VP-008: proptest harness for path NFC comparison (P1 — not Kani)
- DEC-004, FM-007: macOS NFD false-positive documentation
