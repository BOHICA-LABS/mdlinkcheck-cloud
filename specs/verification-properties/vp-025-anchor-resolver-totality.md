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
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/purity-boundary-map.md
input-hash: "a942180"
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
modified:
  - version: "1.1"
    date: 2026-08-06
    change: "P4 remediation: (P4-002) rewrote entire harness against declared API — AnchorTable is HashSet<String> in anchor_table.rs (not HashMap<String,usize> in types.rs); resolve_anchor returns Verdict {Clean, Broken(FailureReason), Indeterminate(FailureReason)} not AnchorVerdict {Hit,Miss}; updated Kani infeasibility rationale to reference HashSet, not HashMap; (P4-002) property 4 rewritten from 'Closed enum: Hit or Miss only' to 'Indeterminate never returned — the genuinely valuable property'; import path corrected from types.rs to anchor_table.rs; AnchorTable::from_map() removed (not in declared API); proptest::collection::hash_set used instead of hash_map; (P4-029) removed false '5 decimal digits' justification — real guarantee is uppercase ABSENT_ prefix; removed dead prop_assume! from case-sensitivity harness (strategy [a-z]{2,12} always produces uppercase-distinct output); (P4-014) test file path corrected: tests/proptest/anchor_resolver.rs → tests/proptest_anchor_resolver.rs (flat Cargo-discoverable layout); INC-MAP-001 re-opened — prior closure was against a non-compiling harness with wrong types."
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

`anchor_resolver::resolve_anchor(fragment: &str, table: &AnchorTable) -> Verdict`
is total and correct for all `(fragment, table)` inputs:

1. **Totality**: For any `fragment` string and any `AnchorTable` (including the empty
   table), `resolve_anchor` terminates without panicking.

2. **Hit correctness**: If `fragment` is exactly equal to a key present in `table`,
   `resolve_anchor` returns `Verdict::Clean`. A matching fragment that is NOT
   reported as `Clean` is a false negative — a silent broken-link claim against an
   anchor that actually exists.

3. **Miss correctness**: If `fragment` is not equal to any key in `table`,
   `resolve_anchor` returns `Verdict::Broken(_)` (reason `anchor-not-found`). A
   non-matching fragment that is NOT reported as `Broken` is a false positive — a
   silent pass for an anchor link that does not exist.

4. **Indeterminate never returned**: For any `(fragment, table)` pair,
   `resolve_anchor` NEVER returns `Verdict::Indeterminate`. Anchor resolution is a
   pure `HashSet` membership test — no network round-trip, no timeout, no external
   dependency — so there is no code path that could produce an indeterminate
   outcome. An `Indeterminate` return from the anchor resolver is an implementation
   bug. This is the property that distinguishes anchor resolution from HTTP liveness
   checks (`Verdict::Indeterminate` is legitimate for HTTP).

5. **Case sensitivity**: A table containing key `"foo"` and a fragment `"Foo"` returns
   `Broken`. Anchor table keys are NFC-normalized slugs produced by CAP-006; the
   lookup must be byte-exact. Case-folded matching is a correctness bug (the slug
   algorithm already normalizes both the stored key and the incoming fragment; the
   resolver must not re-fold).

6. **Empty fragment**: `resolve_anchor("", table)` returns `Clean` if and only if `""`
   is a key in `table` (which can occur for HTML anchors with `name=""`), and
   `Broken` otherwise. A bare `#` link yields an empty fragment after split; the
   resolver must not panic on it.

These properties directly address why all surveyed incumbents have open bugs on anchor
resolution (lychee #1457/#1613/#1709, markdown-link-check #304/#91, Sphinx
#13620/#11542): their resolvers either panic on edge-case fragments, perform
case-insensitive matching, or conflate empty-fragment with "no anchor".

## Source Contracts

- **BC-2.08.001** — Anchor-only link (`#fragment`): `resolve_anchor` is called for
  same-file anchors after the three-phase design ensures the table is complete (DI-008).
- **BC-2.08.002** — Cross-file anchor resolution: `resolve_anchor` is called for
  cross-file anchors using the target file's AnchorTable.
- **BC-2.08.004** — Cross-file anchor into ignored file: `resolve_anchor` is called
  with AnchorTables built via Pass 1.5 for out-of-scan files.
- **Postcondition**: For all three BCs, the correctness of the resolution step is
  entirely determined by `resolve_anchor`'s lookup semantics — given a correctly
  built table (VP-015, VP-016) and a correctly split fragment (VP-004), the resolver
  must return `Clean` or `Broken` with no false positives and no false negatives,
  and must never return `Indeterminate`.

## Proof Method

| Method | Tool | Bounded? | Coverage |
|--------|------|----------|----------|
| proptest | proptest 1.6.x | no — property-based, 10 000 samples × 5 properties | Arbitrary `(fragment, &AnchorTable)` pairs; slug-character keys; empty string; uppercase/lowercase pairs; empty table; 0–4 entries |

## Kani Infeasibility — Why proptest

`AnchorTable` is a `HashSet<String>` (per `api-surface.md:80`). Kani's CBMC
backend must model all possible internal heap states of Rust data structures. For a
`HashSet` with symbolic string keys, CBMC must exhaustively explore all possible
bucket layouts, load factors, and hash collision chains for the symbolic key bytes.
This creates unbounded state space even for a one-entry table: the hash function
(SipHash-1-3, the default for `HashSet`) introduces dozens of rounds of bit mixing,
and CBMC must track all paths through those operations for every symbolic byte,
producing exponential blowup.

An alternative Kani harness that uses an array-based mock table instead of the
real `HashSet<String>` would verify the wrong abstraction — it would not test
`resolve_anchor` against its actual `&AnchorTable` input type, defeating the purpose.

proptest generates concrete (not symbolic) `AnchorTable` values with
arbitrary-but-realistic configurations. Each of the 10,000 runs per property tests a
specific `(fragment, table)` pair drawn from a rich strategy. The correctness
properties (`Clean` when present, `Broken` when absent) are falsifiable against both
the totality and the key-lookup semantics of the real function.

**Bound justification**: table size 0..=4 entries covers empty table (`Broken` always),
single-entry table (the classic hit/miss partition), and multi-entry table
(no collision confusion). Key length 1..=24 chars covers single-char anchors,
typical `slug-like-heading` keys, and anchors with numbers. Fragment length 0..=24
chars includes the empty-string edge case. The slug-character strategy (`[a-z0-9-_]+`)
mirrors the actual slug output of `slug::compute_slug`, ensuring generated keys are
drawn from the realistic domain — not random Unicode that would never appear in a
real `AnchorTable` key.

## Proof Harness Skeleton

```rust
// tests/proptest_anchor_resolver.rs  (Phase 3 — flat layout per tooling-selection.md §Test Target Layout)
// VP-025: anchor_resolver::resolve_anchor Totality and Correctness

use proptest::prelude::*;
use proptest::collection::hash_set;
use mdlinkcheck_core::anchor_resolver::resolve_anchor;
use mdlinkcheck_core::anchor_table::AnchorTable;
use mdlinkcheck_core::types::Verdict;

/// Strategy: generate slug-like strings that could plausibly appear as anchor keys.
/// These mirror the actual output of slug::compute_slug — lowercase alphanumeric, hyphens, underscores.
fn slug_string() -> impl Strategy<Value = String> {
    "[a-z0-9][a-z0-9\\-_]{0,23}"
}

proptest! {
    // ── P1: totality ────────────────────────────────────────────────────────
    //
    // A wrong implementation that panics on any (fragment, table) pair fails here.
    // This includes: panic on empty table, panic on empty fragment, panic on
    // non-ASCII fragment, panic on fragment longer than any key.
    //
    // Also enforces P4: Indeterminate MUST NOT be returned from anchor resolver.
    #[test]
    fn vp025_resolve_anchor_total(
        // table: 0..=4 entries with slug-like keys
        table_entries in hash_set(slug_string(), 0..=4usize),
        // fragment: arbitrary UTF-8, 0..=24 chars
        frag in ".{0,24}"
    ) {
        let anchor_table = AnchorTable(table_entries);

        // Must not panic:
        let result = resolve_anchor(&frag, &anchor_table);

        // P4: Indeterminate is never a valid return — anchor resolver is a pure HashSet
        // membership test with no network path or timeout.
        prop_assert!(
            !matches!(result, Verdict::Indeterminate(_)),
            "VP-025 P4: Indeterminate returned from resolve_anchor({:?}, table) — \
             anchor resolver has no network path; this is an implementation bug",
            frag
        );
    }

    // ── P2: hit correctness ─────────────────────────────────────────────────
    //
    // A wrong implementation that always returns Broken fails here.
    // proptest generates a key, inserts it, then queries with that same key.
    // The resolver MUST report Clean.
    #[test]
    fn vp025_hit_when_present(
        key in slug_string(),
        // Extra entries to prevent always-return-Clean-for-single-entry optimisation
        extra in hash_set(slug_string(), 0..=3usize),
    ) {
        let mut entries = extra;
        entries.insert(key.clone());
        let anchor_table = AnchorTable(entries);

        let result = resolve_anchor(&key, &anchor_table);

        prop_assert!(
            matches!(result, Verdict::Clean),
            "Expected Clean for fragment {:?} which IS in table, got {:?}",
            key, result
        );
    }

    // ── P3: miss correctness ────────────────────────────────────────────────
    //
    // A wrong implementation that always returns Clean fails here.
    // The sentinel key starts with uppercase "ABSENT_" — slug_string() only generates
    // lowercase alphanumeric + hyphen + underscore, so no slug_string() key can ever
    // start with an uppercase letter. The uppercase prefix is the real exclusion
    // guarantee; the 5-digit suffix simply makes the fragment more distinguishable
    // in failure messages.
    #[test]
    fn vp025_miss_when_absent(
        table_entries in hash_set(slug_string(), 0..=4usize),
        suffix in "[0-9]{5}"
    ) {
        let absent_frag = format!("ABSENT_{}", suffix);
        let anchor_table = AnchorTable(table_entries);

        let result = resolve_anchor(&absent_frag, &anchor_table);

        prop_assert!(
            matches!(result, Verdict::Broken(_)),
            "Expected Broken for fragment {:?} which is NOT in table, got {:?}",
            absent_frag, result
        );
    }

    // ── P4: case sensitivity ────────────────────────────────────────────────
    //
    // A wrong implementation with case-insensitive lookup fails here.
    // Table has a lowercase key; query uses the uppercase version of that key.
    // The resolver must return Broken (not Clean) because slugs are case-sensitive.
    // Note: no prop_assume! guard needed — "[a-z]{2,12}" always produces ASCII
    // lowercase letters, and to_uppercase() on ASCII lowercase always differs.
    #[test]
    fn vp025_case_sensitive_lookup(
        key_lower in "[a-z]{2,12}",
    ) {
        let key_upper = key_lower.to_uppercase();

        let mut entries = std::collections::HashSet::new();
        entries.insert(key_lower.clone());
        let anchor_table = AnchorTable(entries);

        // Querying with the uppercase fragment must return Broken:
        // the table has "foo", not "FOO" — lookup is byte-exact.
        let result = resolve_anchor(&key_upper, &anchor_table);

        prop_assert!(
            matches!(result, Verdict::Broken(_)),
            "Case-insensitive bug: {:?} (uppercase) matched key {:?} (lowercase) in table",
            key_upper, key_lower
        );
    }

    // ── P5: empty fragment ──────────────────────────────────────────────────
    //
    // A bare '#' link (same-file, no anchor name) produces an empty fragment.
    // The resolver must handle it without panic. If "" is a key (HTML name=""),
    // it returns Clean; otherwise Broken.
    #[test]
    fn vp025_empty_fragment_no_panic(
        include_empty_key in any::<bool>(),
        other_entries in hash_set(slug_string(), 0..=3usize),
    ) {
        let mut entries = other_entries;
        if include_empty_key {
            entries.insert("".to_string());
        }
        let anchor_table = AnchorTable(entries);

        // Must not panic:
        let result = resolve_anchor("", &anchor_table);

        if include_empty_key {
            prop_assert!(
                matches!(result, Verdict::Clean),
                "Expected Clean for empty fragment when '' is a key in table, got {:?}",
                result
            );
        } else {
            prop_assert!(
                matches!(result, Verdict::Broken(_)),
                "Expected Broken for empty fragment when '' is not a key in table, got {:?}",
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
| Always returns Broken | vp025_hit_when_present (P2) | key is in table; Broken returned → assertion fails |
| Always returns Clean | vp025_miss_when_absent (P3) | fragment has ABSENT_ prefix → unique, not in table; Clean returned → assertion fails |
| Case-insensitive lookup | vp025_case_sensitive_lookup (P4) | "foo" in table, query "FOO" → Clean returned → assertion fails |
| Panics on empty fragment | vp025_empty_fragment_no_panic (P5) | proptest calls resolve_anchor("", table) → panic → test failure |
| Returns Indeterminate | vp025_resolve_anchor_total (P1) | Indeterminate returned → prop_assert! fails |

The hit/miss correctness assertions require a correct bidirectional mapping: every
`Clean` must correspond to a key present in the table, and every `Broken` must
correspond to a key absent from the table. A null implementation cannot satisfy both
simultaneously when proptest generates a non-empty table (P2 always includes the
query key in the table).

## Feasibility Assessment

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Input space size | Property-based | proptest generates arbitrary (fragment, table) pairs; slug strategy is realistic |
| Proof complexity | Low | `resolve_anchor` is a pure HashSet lookup; no loops, no allocation, no recursion |
| Tool support | Full | `proptest 1.6.x`; HashSet strategy via `proptest::collection::hash_set` |
| Estimated proof time | < 5s per run (Phase 3 CI) | 10,000 samples × 5 properties; `cargo nextest` |
| Kani feasibility | Not feasible | HashSet<String> + symbolic strings → unbounded CBMC state (see §Why proptest) |

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-06 | architect |
| v1.1 — P4 remediation: API corrected to HashSet<String>/Verdict, prop_assume! removed | 2026-08-06 | architect |
| Proof harness committed | — | formal-verifier |
| Proof first passed | — | formal-verifier |
| Locked (VERIFIED) | — | formal-verifier |
