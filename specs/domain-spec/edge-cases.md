---
document_type: domain-spec-section
level: L2
section: edge-cases
version: "1.5"
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
  - version: "1.5"
    date: 2026-08-06
    change: "D-043 (macOS-only platform directive): DEC-004 'on all platforms' narrowed to 'on macOS'; DEC-009 cross-platform framing removed — 'uniquely cross-platform' rationale replaced with macOS APFS determinism framing per D-043 canonical D-006 rationale; 'on **all** platforms — including macOS' replaced with 'on macOS'; 'fails in Linux CI (case-sensitive ext4)' removed."
  - version: "1.4"
    date: 2026-08-06
    change: "Mechanical spec remediation: DEC-006 — removed dangling retired-holdout-scenario citation (the ID was superseded by BV-013 and no longer resolves; BV-013 is now the sole authoritative source) and removed erroneous citation of a different, still-active holdout scenario that does not cover the code-span-in-BRIEF.md case (its inclusion was a mis-citation in the original DD-017 text, resolved per adversary P3-022). Source line now reads BV-013 only."
  - version: "1.3"
    date: 2026-08-05
    change: "D-020/DD-026 burned-holdout ruling: DEC-001 (EC-049), DEC-003 (EC-074), DEC-009 (EC-036) — [HOLDOUT] tags removed; concrete scenario detail restored (they are now standard visible corpus fixtures). Preamble updated to record standing rule for future holdouts. P2-C07 holdout sweep complete."
  - version: "1.2"
    date: 2026-08-05
    change: "POL-18 holdout leak remediation: DEC-001 (EC-049) — removed concrete heading names, slug values, and expected verdicts; replaced with risk-class description naming the collision failure mode. DEC-003 (EC-074) — removed concrete file paths, link text, and expected verdict; replaced with risk-class description; title widened from 'Ignored' to 'Source-Excluded'. DEC-009 (EC-036) — removed specific filename example and expected reason code; replaced with risk-class description. No scenario files for EC-049 or EC-074 exist under .factory/holdout-scenarios/wave-scenarios/ — these must be authored separately."
  - version: "1.1"
    date: 2026-08-05
    change: "Phase 1d gate remediation: D-010 — DEC-006 de-designated from holdout (BRIEF.md → exit 0 vector is now in the standard visible suite, DD-017); DEC-001 — added [HOLDOUT] tag consistent with EC-049 holdout reservation (omission corrected); F-032 / F-021 scope verified — no DEC is affected by target-unreadable or target-is-directory taxonomy fixes."
  - version: "1.0"
    date: 2026-08-05
    change: "Initial draft"
---

# Section 5: Domain Edge Cases

> **Sharded L2 section (DF-021).** Navigate via `L2-INDEX.md`.

Domain-level edge cases that define invariant behavior. These are the cases most
likely to produce wrong verdicts and are grounded in real-world tool failures. Each
maps to a required corpus fixture.

**Standing holdout rule (DD-026):** Any case designated `[HOLDOUT]` must NOT carry
concrete scenario detail (specific inputs + expected outputs) in this file while that
designation is active — the full scenario belongs in `.factory/holdout-scenarios/`.
Only the failure class and EC-ID may appear here. DEC-001, DEC-003, and DEC-009 were
formerly `[HOLDOUT]`; their designation was retired per D-020/DD-026 (the scenarios
were burned). They are now standard visible corpus fixtures with full concrete detail.

---

## DEC-001: Duplicate Heading Collision

**Scenario:** A file contains headings `Foo`, `Foo`, `Foo-1` in sequence. The GitHub
slug algorithm assigns: first `Foo` → `foo`; second `Foo` collides → `foo-1`; `Foo-1`
also normalizes to `foo-1`, which is already taken, so it advances to `foo-1-1`. Links
`[a](#foo)`, `[b](#foo-1)`, `[c](#foo-1-1)` must all resolve `clean`. (EC-049)

**Why difficult:** A correct simple-duplicate handler (two `## Setup` → `setup`,
`setup-1`) may still fail here because `Foo-1`'s raw slug `foo-1` collides with the
counter-appended form already assigned to the second `Foo`. The disambiguation loop must
continue iterating past that secondary collision. Implementations using a 1-based
counter, or that do not re-enter the `while` loop on the secondary collision, produce
wrong slugs for the third link.

**Domain rule:** Apply the `while(occurrences contains result)` disambiguation loop
from github-slugger v2 exactly (DD-015). Every link into a heading collision cluster
must resolve to its correct, unambiguous slug — no two headings in a cluster may share
a resolved slug, and none may produce a spurious `anchor-not-found` verdict.

**Corpus fixture required.** Source: AMB-052, EC-049, market-intelligence §4.1.

---

## DEC-002: Forward Heading Reference

**Scenario:** `[x](#conclusion)` appears on line 5 but heading `## Conclusion`
appears on line 80 of the same file.

**Domain rule:** DI-008 — anchor tables are fully built before any link is validated.
This must always resolve `clean`. Single-pass designs fail this case.

**Corpus fixture required.** Source: T15.

---

## DEC-003: Cross-File Anchor Into Source-Excluded File

**Scenario:** `README.md` contains link `[x](vendor.md#section)`. `vendor.md` is
matched by `--ignore`, and heading `## Section` exists in `vendor.md`. The link must
resolve `clean`. (EC-074) A tool that treats `--ignore` as suppressing both link-source
scanning AND anchor-table construction produces a false `anchor-not-found`.

**Why difficult:** Pass 1 traverses all `.md` files including `--ignore`d ones, so the
anchor table for `vendor.md` IS built when Pass 2 begins — for this `--ignore` case.
However, for `.gitignore`d files or files in dot-directories (not discovered by Pass 1;
handled by Pass 1.5), an implementation that skips anchor-table construction for any
excluded file produces false negatives on valid cross-file links.

**Domain rule:** DI-006 — source exclusion (`--ignore`, `.gitignore`, dot-directory
skip, scan-root boundary) applies to link *sources* only. If any in-scan-set link
references a source-excluded `.md` file, that file's anchor table must still be built
(Pass 1 for `--ignore` targets; Pass 1.5 for all others). The link verdict depends
solely on whether the referenced anchor exists — not on whether the target file is in
the scan set.

**Corpus fixture required.** Source: AMB-063, EC-074.

---

## DEC-004: NFC/NFD Filename Mismatch

**Scenario:** File on disk is `Café.md` in NFD normalization (macOS-created). Link
references `[x](Café.md)` in NFC form.

**Domain rule:** DI-002 — NFC-normalize both the destination and the real directory
entry before comparison. Must resolve `clean` on macOS (where APFS stores filenames in NFD;
NFC-normalizing both sides ensures verdicts depend on repository content rather than filesystem
normalization behaviour).

**Corpus fixture required.** Source: EC-037, BV-006.

---

## DEC-005: Percent-Encoded Fragment Comparison

**Scenario:** Link destination is `README.md#caf%C3%A9` and the heading is
`## Café`. The slug is `café`.

**Domain rule:** DI-003 (split at first raw `#`) + CAP-008 (percent-decode fragment
before slug comparison). The decoded fragment `café` must match slug `café`.
This is the documented root cause of Sphinx bug #13620.

**Corpus fixture required.** Source: AMB-055, EC-053, T9.

---

## DEC-006: Code-Span Links in the Brief Itself

**Scenario:** `BRIEF.md` lines 18–19 contain `[x](docs/a.md)`, `[x](../b.md)`,
`[x](#setup)`, `[x](a.md#usage)` inside inline code spans.

**Domain rule:** DI-004 — code context yields no links. `mdlinkcheck BRIEF.md`
**must** exit 0. If this fails, the tool reports false positives on its own
specification document.

**Canonical test vector.** Source: BV-013. (DD-017: de-designated from holdout per D-010 — this vector is now in the standard visible suite.)

---

## DEC-007: Empty Fragment

**Scenario:** Link destination is `[x](#)` (bare hash, no fragment text) or
`[x](a.md#)` (cross-file bare hash).

**Domain rule:** Treat as "no fragment" — validate only the file existence (or accept
as self-link for bare `#`). Verdict: `clean`. Failing here is a guaranteed false
positive (T11, AMB-066).

**Corpus fixture required.** Source: EC-068, EC-069, T11.

---

## DEC-008: Fragment on a Non-Markdown Target

**Scenario:** Link is `[x](notes.txt#section)` and `notes.txt` exists on disk.

**Domain rule:** The file exists → path check passes. Tool cannot extract headings
from a non-Markdown file → skip the anchor check. Verdict: `clean`. Failing here
is a guaranteed false positive (T10, AMB-064).

**Corpus fixture required.** Source: EC-072, T10.

---

## DEC-009: Case-Mismatched Filename

**Scenario:** Link `[x](README.MD)` in a source file where the only on-disk entry is
`README.md` (lowercase extension). On macOS APFS, `std::fs::exists("README.MD")`
returns `true`; the OS silently accepts the case mismatch. Per DI-002, the tool must
produce `broken(file-not-found)` on macOS — by performing explicit case-sensitive
directory-entry enumeration rather than delegating to the OS path-existence syscall.
(EC-036)

**Why difficult:** The only reliable way to detect the mismatch on macOS APFS (a
case-insensitive filesystem) is to `read_dir` the parent directory and compare the
link destination against the actual on-disk names, case-sensitively. No surveyed
competitive tool performs this check (T12). On macOS APFS, `std::fs::exists("README.MD")`
returns `true`, producing a silent false negative; explicit directory-entry enumeration
is the only correct approach.

**Domain rule (D-043 canonical D-006 rationale):** Strict case-sensitive + NFC path
comparison is retained on determinism grounds, independent of the platform matrix.
The tool must produce byte-identical output for byte-identical repository content, and
must not let macOS APFS case-folding or Unicode normalization behaviour influence link
verdicts. macOS APFS is case-insensitive and stores filenames in NFD; adopting native
filesystem semantics would make verdicts a function of the filesystem rather than of
the repository content, which would break DI-001 determinism and NFR-003
reproducibility. This holds on a macOS-only matrix and is not contingent on
cross-platform parity. DI-002 — a link whose destination filename does not exactly
match an on-disk entry must produce a `broken` verdict with reason `file-not-found`.

**Corpus fixture required.** Source: D-006, BV-006, EC-036, T12.
