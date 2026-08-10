---
document_type: behavioral-contract
level: L3
version: "1.8"
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
subsystem: "SS-11"
capability: "CAP-011"
lifecycle_status: active
introduced: v1.0.0
modified:
  - v1.8: "(GATE-58/POL-14) VP-NNN column bare em-dash is non-conforming per POL-14; replaced with VP-NONE (D-078) — proof method is pending, so VP-NONE is accepted."
  - v1.7: "(D-205/BI-052 remediation) VP-010 rows updated to reflect two-path algorithm (D-019). VP-010 proptest harness covers Path A (normalized URL component boundary). Path B (raw-string fallback for malformed URLs) requires AllowPrefix API path that exposes the WHATWG-failure branch; that harness is pending that API extension."
  - v1.6: "WS-4 Shard E: proof-method join repair — VP-010 proof method corrected to 'proptest' (was 'unit test') per VP-INDEX authority."
  - v1.3: "F-017 — this is now the CANONICAL --allow contract (owned by SS-11/CAP-011). BC-2.09.002 is a pointer to this BC. Added explicit normalize-then-prefix-match ordering in description and postconditions."
  - v1.4: "D-019/P2-M08 — added WHATWG-fail fallback to raw-string prefix match at component boundary for malformed URLs. P2-M09 — renamed EC-090/091/092 to EC-161/162/163 (deduplicated from BC-2.10.002's legitimate HTTP block use of those IDs). P2-m05 — fixed L2 Capability title; corrected Brief Requirement from R6 to R5."
  - "v1.5: (INC-MAP) Architecture Module field added per bc-module-map.md (architect, Phase 1b)"
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.11.002: `--allow` URL Prefix Exemption with Component-Boundary Safety

## Description
**Canonical `--allow` contract** (per F-017; BC-2.09.002 is a pointer to this BC).

The `--allow <URL_PREFIX>` flag exempts external URLs from both syntax validation and liveness
checking. The matching algorithm handles both well-formed and malformed URLs:

**Algorithm (D-019):**
1. **Attempt WHATWG normalization** of the URL.
2. **If normalization succeeds:** prefix-match the normalized URL against the allow prefix, then
   verify the **component boundary** — the character immediately after the prefix must be `/`,
   `?`, `#`, or end-of-string.
3. **If normalization fails** (the URL is malformed and WHATWG cannot parse it): fall back to
   **raw-string prefix match at a component boundary** using the same boundary rule applied to
   the raw string. This allows `--allow` to exempt malformed intranet URLs
   (e.g., `https://build_server/status`) that users most want to skip.

The component-boundary requirement in both paths prevents `--allow https://example.com` from
matching `https://example.com.evil.tld`. A naive `starts_with` is never used.

## Preconditions
1. One or more `--allow URL_PREFIX` flags are provided.
2. A link has been classified as `external-http`.

## Postconditions
1. **Step 1 — Normalize attempt:** WHATWG normalization is attempted on the URL.
2. **Step 2 (success path) — Normalized prefix-match:** The normalized URL is checked against
   each allow prefix in order; component boundary applies.
3. **Step 2 (fallback path) — Raw-string prefix-match:** If normalization failed, the raw URL
   string is checked against each allow prefix with the same component boundary rule.
4. **Step 3 — Boundary check (both paths):** The character immediately following the prefix
   (if any) must be `/`, `?`, `#`, or end-of-string. If this check fails, the prefix does NOT
   match (prevents `example.com.evil.tld` bypass).
5. **Match:** first `--allow` prefix that passes steps 2/3 → verdict `clean`; not emitted
   in output.
6. **No match:** proceed with normal validation (offline syntax check or online liveness check).
7. `--allow` applies in both offline and `--online` modes.

## Invariants
1. Component boundary: next char after prefix must be `/`, `?`, `#`, or end-of-string. This
   applies in both the normalized and raw-string fallback paths.
2. `--allow` is not a glob; it is a literal URL prefix (normalized or raw depending on path).
3. Multiple `--allow` flags are OR'd: a URL matching ANY of them is exempted.

## Edge Cases
| EC | Description |
|----|-------------|
| EC-161 | `--allow https://example.com`; URL = `https://example.com/path` |
| EC-162 | `--allow https://example.com`; URL = `https://example.com.evil.tld/` |
| EC-163 | `--allow https://example.com`; URL = `https://example.comX/path` |

## Canonical Test Vectors
| Prefix | URL | Boundary OK? | Expected |
|--------|-----|-------------|---------|
| `https://example.com` | `https://example.com/a` | yes (`/`) | exempt |
| `https://example.com` | `https://example.com` | yes (end) | exempt |
| `https://example.com` | `https://example.comX` | no | not exempt |
| `https://example.com` | `https://example.com.bad.tld/` | no | not exempt |
| `https://build_server` | `https://build_server/status` (WHATWG fails) | yes (`/`) — raw-string fallback | exempt |

## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-010 | Component boundary prevents bypass Path A normalized (trap T16); exact match is exempt | proptest |
| VP-NONE | Path B raw-string fallback for malformed URLs — pending AllowPrefix API extension to expose WHATWG-failure branch; same boundary rule applies but harness cannot be written against current declared API | pending |

## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-011 ("Filter Application") per capabilities.md §CAP-011 |
| Capability Anchor Justification | CAP-011 ("Filter Application") per capabilities.md §CAP-011 — --allow prefix exemption IS the filter application contract |
| Brief Requirement | R5, DD-010, T16 |
| Architecture Module | `filter.rs` (SS-11, pure core, HIGH tier) — ADR-007 (verdict model — filtering suppresses findings) |

## Related BCs
- BC-2.09.002 — pointer (BC-2.09.002 is a cross-reference to this canonical BC)
- BC-2.11.001 — sibling (--ignore glob exclusion)
- BC-2.11.003 — sibling (--ignore glob exclusion advanced)
