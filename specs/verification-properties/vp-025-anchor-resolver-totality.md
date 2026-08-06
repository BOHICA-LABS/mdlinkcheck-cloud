---
document_type: verification-property
level: L4
version: "1.0"
status: draft
producer: architect
timestamp: 2026-08-06T00:00:00Z
phase: 1b
inputs:
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/purity-boundary-map.md
input-hash: "585d4f8"
traces_to: .factory/specs/architecture/ARCH-INDEX.md
source_bc: BC-2.08.001
module: anchor_resolver
proof_method: proptest
feasibility: feasible
verification_lock: false
proof_completed_date: null
proof_file_hash: null
lifecycle_status: active
introduced: v0.1.0
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
withdrawn: null
withdrawal_reason: null
removed: null
removal_reason: null
---

# VP-025: anchor_resolver::resolve_anchor Totality and Correctness

## Property Statement

`anchor_resolver::resolve_anchor(fragment: &str, table: &AnchorTable) → AnchorVerdict`
is total and correct for all `(fragment, table)` inputs:

1. **Totality**: For any `fragment` string and any `AnchorTable` (including the empty
   table), `resolve_anchor` terminates without panicking.

2. **Hit correctness**: If `fragment` is exactly equal to a key present in `table`,
   `resolve_anchor` returns `AnchorVerdict::Hit` (or the equivalent alive/clean
   verdict). A matching fragment that is NOT reported as Hit is a false negative —
   a silent broken-link claim against an anchor that actually exists.

3. **Miss correctness**: If `fragment` is not equal to any key in `table`,
   `resolve_anchor` returns `AnchorVerdict::Miss` (or the equivalent broken verdict
   with reason `anchor-not-found`). A non-matching fragment that is NOT reported as
   Miss is a false positive — a silent pass for an anchor link that does not exist.

4. **Closed enum**: Every result is exactly Hit or Miss. There is no Indeterminate
   or panic exit path.

5. **Case sensitivity**: A table containing key `"foo"` and a fragment `"Foo"` returns
   Miss. Anchor table keys are NFC-normalized slugs; the lookup must be byte-exact.
   Case-folded matching is a correctness bug (the slug algorithm already normalizes
   both the stored key and the incoming fragment; the resolver must not re-fold).

6. **Empty fragment**: `resolve_anchor("", table)` returns Hit if and only if `""` is
   a key in `table` (which can occur for HTML anchors with `name=""`), and Miss
   otherwise. A bare `#` link yields an empty fragment after split; the resolver must
   not panic on it.

These properties directly address why all surveyed incumbents have open bugs on anchor
resolution (lychee #1457/#1613/#1709, markdown-link-check #304/#91, Sphinx
#13620/#11542): their resolvers either panic on edge-case fragments, perform
case-insensitive matching, or conflate empty-fragment with "no anchor".

## Source Contracts

- **BC-2.08.001** — Anchor-only link (`#fragment`): `resolve_anchor` is called for
  same-file anchors after the two-pass design ensures the table is complete.
- **BC-2.08.002** — Cross-file anchor resolution: `resolve_anchor` is called for
  cross-file anchors using the target file's AnchorTable.
- **BC-2.08.004** — Cross-file anchor into ignored file: `resolve_anchor` is called
  with AnchorTables built via Pass 1.5 for out-of-scan files.
- **Postcondition**: For all three BCs, the correctness of the resolution step is
  entirely determined by `resolve_anchor`'s lookup semantics — given a correctly
  built table (VP-015, VP-016) and a correctly split fragment (VP-004), the resolver
  must return exactly Hit or Miss with no false positives and no false negatives.

## Proof Method

| Method | Tool | Bounded? | Coverage |
|--------|------|----------|----------|
| proptest | proptest 1.6.0 | no — property-based, 10 000 samples × 5 properties | Arbitrary `(fragment, &AnchorTable)` pairs; slug-character keys; empty string; uppercase/lowercase pairs; empty table; 0–4 entries |

## Kani Infeasibility — Why proptest

`AnchorTable` is a `HashMap<String, usize>` (slug → line number). Kani's CBMC
backend models all possible internal heap states of Rust data structures. For a
HashMap with symbolic string keys, CBMC must exhaustively explore all possible
bucket layouts, load factors, and hash collision chains for the symbolic key bytes.
This creates unbounded state space even for a one-entry table: the hash function
(SipHash-1-3) introduces dozens of rounds of bit mixing, and CBMC must track all
paths through those operations for every symbolic byte, producing exponential
blowup.

An alternative Kani harness that uses an array-based mock table instead of the
real HashMap would verify the wrong abstraction — it would not test `resolve_anchor`
against its actual `&AnchorTable` input type, defeating the purpose.

proptest generates concrete (not symbolic) AnchorTables with arbitrary-but-realistic
configurations. Each of the 10,000 runs per property tests a specific
(fragment, table) pair drawn from a rich strategy. The correctness properties (Hit
when present, Miss when absent) are falsifiable against both the totality and the
key-lookup semantics of the real function.

**Bound justification**: table size 0..=4 entries covers empty table (Miss always),
single-entry table (the classic hit/miss partition), and multi-entry table
(no collision confusion). Key length 1..=24 chars covers single-char anchors,
typical `slug-like-heading` keys, and anchors with numbers. Fragment length 0..=24
chars includes the empty-string edge case. The slug-character strategy (`[a-z0-9-_]+`)
mirrors the actual slug output of `slug::compute_slug`, ensuring generated keys are
drawn from the realistic domain — not random Unicode that would never appear in a
real AnchorTable key.

## Proof Harness Skeleton

```rust
// tests/proptest/anchor_resolver.rs
//
// Note on type names: replace `AnchorTable`, `AnchorVerdict`, `Hit`, `Miss`
// with the actual names from types.rs once the implementer finalises the API.
// The semantic assertions are correct regardless of naming.

use proptest::prelude::*;
use proptest::collection::hash_map;
use mdlinkcheck_core::anchor_resolver::resolve_anchor;
use mdlinkcheck_core::types::{AnchorTable, AnchorVerdict};

/// Strategy: generate slug-like strings that could plausibly appear as anchor keys.
/// Mixed with arbitrary strings (via `".*"`) in other harnesses.
fn slug_string() -> impl Strategy<Value = String> {
    "[a-z0-9][a-z0-9\\-_]{0,23}".prop_map(|s| s)
}

proptest! {
    // ── P1: totality ────────────────────────────────────────────────────────
    //
    // A wrong implementation that panics on any (fragment, table) pair fails here.
    // This includes: panic on empty table, panic on empty fragment, panic on
    // non-ASCII fragment, panic on fragment longer than any key.
    #[test]
    fn vp025_resolve_anchor_total(
        // table: 0..=4 entries with slug-like keys
        table_entries in hash_map(slug_string(), 1usize..=99999usize, 0..=4usize),
        // fragment: arbitrary UTF-8, 0..=24 chars
        frag in "(.{0,24})"
    ) {
        let anchor_table = AnchorTable::from_map(table_entries.clone());

        // Must not panic:
        let result = resolve_anchor(&frag, &anchor_table);

        // Closed enum — Hit or Miss only (no Indeterminate, no Error variant):
        match result {
            AnchorVerdict::Hit | AnchorVerdict::Miss => {},
        }
    }

    // ── P2: hit correctness ─────────────────────────────────────────────────
    //
    // A wrong implementation that always returns Miss fails here.
    // proptest generates a key, inserts it, then queries with that same key.
    // The resolver MUST report Hit.
    #[test]
    fn vp025_hit_when_present(
        key in slug_string(),
        line in 1usize..=99999usize,
        // Extra entries to prevent always-return-Hit-for-single-entry optimisation
        extra in hash_map(slug_string(), 1usize..=99999usize, 0..=3usize),
    ) {
        let mut entries = extra;
        entries.insert(key.clone(), line);
        let anchor_table = AnchorTable::from_map(entries);

        let result = resolve_anchor(&key, &anchor_table);

        prop_assert!(
            matches!(result, AnchorVerdict::Hit),
            "Expected Hit for fragment {:?} which IS in table, got {:?}",
            key, result
        );
    }

    // ── P3: miss correctness ────────────────────────────────────────────────
    //
    // A wrong implementation that always returns Hit fails here.
    // A fragment with a unique suffix that cannot be any slug_string() key
    // is guaranteed absent from any generated table.
    #[test]
    fn vp025_miss_when_absent(
        table_entries in hash_map(slug_string(), 1usize..=99999usize, 0..=4usize),
        // Unique suffix: 5 decimal digits — no slug_string() ends with 5 digits
        suffix in "[0-9]{5}"
    ) {
        // The sentinel key contains uppercase "ABSENT_" which slug keys never have
        let absent_frag = format!("ABSENT_{}", suffix);
        let anchor_table = AnchorTable::from_map(table_entries);

        let result = resolve_anchor(&absent_frag, &anchor_table);

        prop_assert!(
            matches!(result, AnchorVerdict::Miss),
            "Expected Miss for fragment {:?} which is NOT in table, got {:?}",
            absent_frag, result
        );
    }

    // ── P4: case sensitivity ────────────────────────────────────────────────
    //
    // A wrong implementation with case-insensitive lookup fails here.
    // Table has a lowercase key; query uses the uppercase version of that key.
    // The resolver must return Miss (not Hit) because slugs are case-sensitive.
    #[test]
    fn vp025_case_sensitive_lookup(
        key_lower in "[a-z]{2,12}", // at least 2 chars so toUpperCase() differs
    ) {
        let key_upper = key_lower.to_uppercase();

        // If upper and lower are the same (e.g. all digits), skip — not a useful test.
        prop_assume!(key_upper != key_lower);

        let mut entries = std::collections::HashMap::new();
        entries.insert(key_lower.clone(), 1usize);
        let anchor_table = AnchorTable::from_map(entries);

        // Querying with the uppercase fragment must return Miss:
        // the table has "foo", not "FOO" — lookup is byte-exact.
        let result = resolve_anchor(&key_upper, &anchor_table);

        prop_assert!(
            matches!(result, AnchorVerdict::Miss),
            "Case-insensitive bug: {:?} (uppercase) matched key {:?} (lowercase) in table",
            key_upper, key_lower
        );
    }

    // ── P5: empty fragment ──────────────────────────────────────────────────
    //
    // A bare '#' link (same-file, no anchor name) produces an empty fragment.
    // The resolver must handle it without panic. If "" is a key (HTML name=""),
    // it returns Hit; otherwise Miss.
    #[test]
    fn vp025_empty_fragment_no_panic(
        include_empty_key in any::<bool>(),
        other_entries in hash_map(slug_string(), 1usize..=99999usize, 0..=3usize),
    ) {
        let mut entries = other_entries;
        if include_empty_key {
            entries.insert("".to_string(), 1usize);
        }
        let anchor_table = AnchorTable::from_map(entries);

        // Must not panic:
        let result = resolve_anchor("", &anchor_table);

        if include_empty_key {
            prop_assert!(
                matches!(result, AnchorVerdict::Hit),
                "Expected Hit for empty fragment when '' is a key in table, got {:?}",
                result
            );
        } else {
            prop_assert!(
                matches!(result, AnchorVerdict::Miss),
                "Expected Miss for empty fragment when '' is not a key in table, got {:?}",
                result
            );
        }
    }
}
```

## Non-Vacuousness Analysis

Five wrong implementations are falsified by different harnesses in this VP:

| Wrong Implementation | Falsifying Harness | Failure Mode |
|----------------------|-------------------|--------------|
| Always returns Miss | vp025_hit_when_present (P2) | key is in table; Miss is returned → assertion fails |
| Always returns Hit | vp025_miss_when_absent (P3) | fragment has ABSENT_ prefix → unique, not in table; Hit is returned → assertion fails |
| Case-insensitive lookup | vp025_case_sensitive_lookup (P4) | "foo" in table, query "FOO" → Hit returned → assertion fails |
| Panics on empty fragment | vp025_empty_fragment_no_panic (P5) | proptest calls resolve_anchor("", table) → panic → test failure |
| Panics on empty table | vp025_resolve_anchor_total (P1) | hash_map strategy with 0..=4 generates 0-entry tables → panic → test failure |

This differs structurally from VP-004 (which could be passed by returning `(s, None)` always) and VP-007 (which only asserted no-panic without asserting which verdict). The hit/miss correctness assertions here require a correct bidirectional mapping: every Hit must correspond to a key present in the table, and every Miss must correspond to a key absent from the table. A null implementation cannot satisfy both simultaneously when proptest generates a non-empty table (P2 harness always includes the query key in the table).

## Feasibility Assessment

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Input space size | Property-based | proptest generates arbitrary (fragment, table) pairs; slug strategy is realistic |
| Proof complexity | Low | `resolve_anchor` is a pure HashMap lookup; no loops, no allocation, no recursion |
| Tool support | Full | `proptest 1.6.0`; HashMap strategy via `proptest::collection::hash_map` |
| Estimated proof time | < 5s per run (Phase 3 CI) | 10,000 samples × 5 properties; `cargo nextest` |
| Kani feasibility | Not feasible | HashMap + symbolic strings → unbounded CBMC state (see §Why proptest, Not Kani) |

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-06 | architect |
| Proof harness committed | — | formal-verifier |
| Proof first passed | — | formal-verifier |
| Locked (VERIFIED) | — | formal-verifier |
