---
document_type: verification-property
level: L4
version: "1.2"
status: draft
producer: architect
timestamp: 2026-08-05T20:00:00Z
phase: 1b
inputs:
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/architecture/module-decomposition.md
input-hash: "012887b"
traces_to: .factory/specs/architecture/ARCH-INDEX.md
source_bc: BC-2.06.002
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
    change: "SR-019 remediation: restated property as genuine injectivity (two independent symbolic inputs); added collision-bump case for DEC-001 triple (Setup/Setup/Setup 1); corrected: previous harness used one repeated string so the collision-bump while-loop branch was unreachable"
  - version: "1.2"
    date: 2026-08-05
    change: "P2-m08 remediation: renamed verify_vp003_injectivity → verify_vp003_output_uniqueness_across_distinct_inputs; removed vacuous kani::assume(s1 != s2) (property holds for all pairs regardless; removing the assume gives Kani full coverage); added termination property harness; replaced DEC-001 'Setup/Setup/Setup 1' unit fixture with 'Init/Init/Init 1' to avoid leaking acceptance holdout vectors."
deprecated: null
deprecated_by: null
replacement: null
retired: null
withdrawn: null
withdrawal_reason: null
removed: null
removal_reason: null
---

# VP-003: DuplicateCounter Injectivity — No Two Distinct Slugs After Dedup

## Property Statement

**Primary property (output uniqueness):** For ANY two calls to `compute_slug` with a
shared `DuplicateCounter` — regardless of whether the input strings are equal or not —
the two returned slugs are distinct. The counter's deduplication mechanism ensures this
holds for equal inputs (producing `"foo"` then `"foo-1"`) as well as distinct inputs.

**Secondary property (same-heading uniqueness):** For any heading string `s` processed N
times (N bounded to 10) through a shared `DuplicateCounter`, no two of the N resulting
slugs are equal.

**Collision-bump case:** Given headings `"Init"`, `"Init"`, `"Init 1"` processed in that
order through a shared counter, the results are `"init"`, `"init-1"`, `"init-1-1"`.
The third heading's base slug (`"init-1"`) collides with the second result before the
counter for `"init-1"` increments — this is the critical `while` branch in
github-slugger that the same-string harness cannot reach.

**Termination property:** `compute_slug` always returns; the `while`-loop in the
collision-bump path always terminates within the CBMC bound.

## Source Contract

- **BC:** BC-2.06.002 — Duplicate Heading Disambiguation
- **Postcondition/Invariant:** PC1 — Duplicate headings produce unique slugs via `-N` suffix injection.

## Proof Method

| Method | Tool | Bounded? | Coverage |
|--------|------|----------|----------|
| kani | Kani 0.67.0 | yes — string lengths bounded to 16 bytes; heading count bounded to 10 | Two independent symbolic strings; all valid UTF-8 up to 16 bytes |

## Proof Harness Skeleton

```rust
// Harness 1: output uniqueness across ALL pairs (P2-m08: kani::assume removed)
// The property holds for any two inputs — including equal inputs (which produce
// "foo" + "foo-1" due to the counter), so restricting to s1 != s2 was unnecessary.
#[kani::proof]
fn verify_vp003_output_uniqueness_across_distinct_inputs() {
    let bytes1: [u8; 16] = kani::any();
    let bytes2: [u8; 16] = kani::any();
    let len1: usize = kani::any();
    let len2: usize = kani::any();
    kani::assume(len1 > 0 && len1 <= 16);
    kani::assume(len2 > 0 && len2 <= 16);

    let s1 = match std::str::from_utf8(&bytes1[..len1]) {
        Ok(s) => s,
        Err(_) => return,
    };
    let s2 = match std::str::from_utf8(&bytes2[..len2]) {
        Ok(s) => s,
        Err(_) => return,
    };
    // No kani::assume(s1 != s2) — the counter deduplicates equal inputs too,
    // so the property holds for all (s1, s2) pairs without restriction.

    let mut counter = DuplicateCounter::new();
    let slug1 = compute_slug(s1, &mut counter);
    let slug2 = compute_slug(s2, &mut counter);

    assert_ne!(slug1, slug2,
        "Any two calls to compute_slug with a shared counter must produce distinct slugs; \
         got identical slug {:?} for inputs {:?} and {:?}", slug1, s1, s2);
}

// Harness 2: same-string uniqueness (original behaviour, preserved)
#[kani::proof]
fn verify_vp003_same_heading_uniqueness() {
    let bytes: [u8; 16] = kani::any();
    let len: usize = kani::any();
    kani::assume(len > 0 && len <= 16);
    let s = match std::str::from_utf8(&bytes[..len]) {
        Ok(s) => s,
        Err(_) => return,
    };
    let n: usize = kani::any();
    kani::assume(n > 1 && n <= 10);

    let mut counter = DuplicateCounter::new();
    let mut results: Vec<String> = Vec::new();
    for _ in 0..n {
        results.push(compute_slug(s, &mut counter));
    }

    for i in 0..results.len() {
        for j in (i + 1)..results.len() {
            assert_ne!(results[i], results[j],
                "Duplicate slugs at positions {} and {}: {:?}", i, j, results[i]);
        }
    }
}

// Harness 3: termination property
// compute_slug must always return (no infinite loop in the while-bump branch).
// Kani proves this by bounded exploration — if the while-loop does not terminate
// within the CBMC bound it reports a verification failure.
#[kani::proof]
#[kani::unwind(32)]  // generous bound for the -N suffix while-loop
fn verify_vp003_terminates() {
    let bytes: [u8; 16] = kani::any();
    let len: usize = kani::any();
    kani::assume(len > 0 && len <= 16);
    let s = match std::str::from_utf8(&bytes[..len]) {
        Ok(s) => s,
        Err(_) => return,
    };

    let mut counter = DuplicateCounter::new();
    // Call twice to exercise the counter increment path
    let _ = compute_slug(s, &mut counter);
    let _ = compute_slug(s, &mut counter);
    // If we reach here, compute_slug terminated — no assertion needed
}
```

**Collision-bump fixture (unit test — also add to VP-018):**

```rust
#[test]
fn vp003_collision_bump() {
    // Collision-bump: "Init", "Init", "Init 1" exercises the while-loop branch
    // in the github-slugger duplicate counter (same structure as DEC-001 but
    // uses generic headings rather than acceptance test vectors).
    // "Init" → "init"; second "Init" → "init-1";
    // "Init 1" base slug is "init-1" which collides with the previous result,
    // so the counter bumps it to "init-1-1".
    let mut counter = DuplicateCounter::new();
    assert_eq!(compute_slug("Init", &mut counter), "init");
    assert_eq!(compute_slug("Init", &mut counter), "init-1");
    assert_eq!(compute_slug("Init 1", &mut counter), "init-1-1");
}
```

## Feasibility Assessment

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Input space size | Bounded | Two strings ≤ 16 bytes each; or N ≤ 10 repeats |
| Proof complexity | Medium | Harness 1 requires CBMC to track two independent symbolic strings through slug computation; collision detection in CBMC is straightforward |
| Tool support | Partial | `Vec` in Kani requires `kani::vec::any_vec` or manual bounded array; harnesses may need array-based results storage |
| Estimated proof time | < 180s | Two-string harness has larger state space than single-string; acceptable within P0 Phase 6 budget |

## Feasibility Note: SR-021 Generated Oracle (Phase 3 Recommendation)

SR-021 recommends a generated differential oracle: a committed Node.js script that runs
`require('github-slugger')` over a sweep of inputs and emits `slug-vectors.json`, with a CI
check that regeneration is a no-op. This converts "we believe we match github-slugger v2"
into "we verify it, and detect the day it changes." This is the highest-value risk reduction
available for slug fidelity (R-001, R-002) and is recommended as a Phase 3 deliverable
separate from these Kani proofs. It requires Node.js tooling at vector-generation time (not
at test time) and a `just regen-slug-vectors` target. **Not implemented in this VP spec
because it is a Phase 3 story task, not a Phase 1 architecture decision.**

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-05 | architect |
| v1.1 — injectivity restatement | 2026-08-05 | architect |
| Proof harness committed | — | formal-verifier |
| Proof first passed | — | formal-verifier |
| Locked (VERIFIED) | — | formal-verifier |
