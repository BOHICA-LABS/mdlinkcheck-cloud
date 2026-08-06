---
document_type: verification-property
level: L4
version: "1.1"
status: draft
producer: architect
timestamp: 2026-08-05T20:00:00Z
phase: 1b
inputs:
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/behavioral-contracts/ss-06/BC-2.06.001.md
  - .factory/specs/architecture/module-decomposition.md
input-hash: "33f55c3"
traces_to: .factory/specs/architecture/ARCH-INDEX.md
source_bc: BC-2.06.001
module: slug
proof_method: kani
feasibility: feasible
verification_lock: false
proof_completed_date: null
proof_file_hash: null
lifecycle_status: active
introduced: v0.1.0
modified:
  - version: "1.1"
    date: 2026-08-05
    change: "Phase 1d F-018 remediation: restructured harness to target pure slugify() function (no DuplicateCounter/HashMap); reduced input bound from 64 to 16 bytes of ASCII-only input; removed over-claimed DuplicateCounter coverage statement; updated feasibility assessment to justify bounded ASCII"
deprecated: null
deprecated_by: null
replacement: null
retired: null
withdrawn: null
withdrawal_reason: null
removed: null
removal_reason: null
---

# VP-001: slug::slugify is Total — No Panic for Any ASCII &str Input

## Property Statement

For all ASCII string inputs `s` of length 0..=16 bytes, `slug::slugify(s)` terminates
and returns a `String` without panicking, unwrapping, or indexing out of bounds. The
slug may be the empty string for inputs that contain only stripped characters (e.g.,
punctuation-only headings).

`slugify` is the Kani-provable pure core: it takes `&str`, applies the github-slugger
v2 algorithm (lowercase, strip non-word characters, collapse hyphens), and returns a
`String`. It does NOT take a `DuplicateCounter`. The duplicate-counting layer
(`compute_slug`) wraps `slugify` and is separately verified by VP-003 using a
`BTreeMap`-keyed counter (Kani-friendly, no `RandomState` hashing).

## Source Contract

- **BC:** BC-2.06.001 — Slug Computation Algorithm
- **Postcondition/Invariant:** PC1 — `compute_slug` is a total function defined for all
  `&str` inputs; it never panics. VP-001 proves the inner `slugify` core; VP-003 proves
  the counter layer.

## Proof Method

| Method | Tool | Bounded? | Coverage |
|--------|------|----------|----------|
| kani | Kani 0.67.0 | yes — input length 0..=16 bytes, ASCII only | All ASCII byte sequences up to 16 bytes (128^16 reachable values, explored symbolically via CBMC bitvector model); covers empty input, all-punctuation, mixed word/non-word, all-lowercase, all-uppercase branches |

**Why ASCII only:** `to_lowercase()` and `\p{Word}` character classification are
table-driven over the full Unicode range. Symbolic execution over arbitrary UTF-8
(e.g., 64 symbolic bytes) causes CBMC model-count explosion on the unicode table
lookups — a well-known CBMC blow-up pattern. Restricting to ASCII bytes means the
`to_lowercase()` and word-character checks reduce to simple range comparisons
(`a..=z`, `A..=Z`, `0..=9`, `_`), which CBMC handles in bounded time. The bound
still covers all structurally interesting branches: empty output, non-empty output,
hyphen-collapse, all-stripped (empty-slug) path. Extended Unicode coverage is
provided by VP-012 (cargo-fuzz).

## Proof Harness Skeleton

```rust
#[kani::proof]
fn verify_vp001_slug_total() {
    // Precondition: arbitrary ASCII byte sequence up to 16 bytes
    let len: usize = kani::any();
    kani::assume(len <= 16);
    let bytes: [u8; 16] = kani::any();
    // Restrict to ASCII (0x00..=0x7F) — no Unicode table lookups
    for i in 0..len {
        kani::assume(bytes[i] < 128u8);
    }
    // Valid UTF-8 is guaranteed for ASCII bytes
    let s = std::str::from_utf8(&bytes[..len]).expect("ASCII is valid UTF-8");
    // Execute — must not panic
    let slug = slugify(s);
    // Postcondition: result is a valid String (implicit — no panic means success)
    let _ = slug;
}
```

## Feasibility Assessment

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Input space size | Bounded | 16-byte ASCII bound; CBMC explores the symbolic space via bitvector arithmetic |
| Proof complexity | Low | With ASCII input, `to_lowercase()` reduces to `+32` if in A-Z range; `\p{Word}` reduces to `a-z || A-Z || 0-9 || _`; no Unicode table lookups |
| Tool support | Full | Kani 0.67.0 supports bounded byte arrays and `assume`; no HashMap/RandomState in proof scope |
| Estimated proof time | < 30s | ASCII-only character loop unrolls cleanly; CBMC model is small |
| Separation from counter | Required | `DuplicateCounter` uses `HashMap<String, u32>` internally; Kani models `RandomState`/SipHash poorly. VP-001 proves `slugify` only. VP-003 proves the counter using `BTreeMap<String, u32>` which Kani handles correctly. |

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-05 | architect |
| Revised (F-018 remediation) | 2026-08-05 | architect |
| Proof harness committed | — | formal-verifier |
| Proof first passed | — | formal-verifier |
| Locked (VERIFIED) | — | formal-verifier |
