---
document_type: blocking-issues-resolved
level: ops
version: "1.0"
status: archive
producer: state-manager
timestamp: 2026-08-05T22:00:00Z
cycle: phase-1d
inputs: [STATE.md]
input-hash: "[live-state]"
traces_to: STATE.md
---

# Resolved Blocking Issues — phase-1d

<!-- Blocking issues that were resolved and archived from STATE.md.
     Open blocking issues remain in STATE.md. -->

| ID | Issue | Severity | Blocked Phase | Owner | Resolution | Resolved Date |
|----|-------|----------|--------------|-------|------------|---------------|
| BI-001 | No `origin` remote; PR-based quality gates unavailable | MEDIUM | Phase 3 | human | Operator created `https://github.com/BOHICA-LABS/mdlinkcheck-cloud` (private). `origin` configured; `main`/`develop`/`factory-artifacts` exist remotely. Branch protection live with 8 required status checks + linear history + enforce_admins=true on main. PR #1 merged CI workflows (78a9f77, 17/17 checks green). D-021/D-022/D-023 recorded; D-002 (local-only) superseded by D-021. Full pr-manager 9-step + pr-reviewer diff review restored for every story. | 2026-08-05 |
| BI-003 | 4 spec decisions await human ruling (HTTP 400-after-GET-fallback; holdout pool adjudication; `--allow` for malformed URLs; frozen-R6 "array" vs shipped object envelope) | HIGH | phase-1 gate | human | All 4 decisions ruled: (1) JSON object envelope accepted over frozen-R6 "array" — PRD v1.7 reconciled; (2) HTTP 400-after-GET-fallback verdict = `indeterminate`; (3) `--allow` uses normalize-then-match with raw-string component-boundary fallback (D-024); (4) 5 leaked holdouts (EC-036/049/074/157/158) burned to visible tests, replaced by EC-165..168 (HS-004..HS-007). PRD updated to v1.7. HS-INDEX.md updated. | 2026-08-05 |
| BI-004 | Adversary pass 2 did not reach 56 of 66 BC files, nfr-catalog.md, test-vectors.md, BC-INDEX.md, ADRs 001–005/007, policies.yaml — coverage gap | MEDIUM | phase-1 gate | orchestrator | Pass 3 covered the unreached perimeter: ADR-007, BC-INDEX.md, BC-2.10.004.md, test-vectors.md, prd.md, HS-INDEX.md, policies.yaml, VP-INDEX.md, verification-coverage-matrix.md, ARCH-INDEX.md, error-taxonomy.md, failure-modes.md. Coverage gap closed. | 2026-08-06 |
| BI-006 | PR #2 (`feature/spec-lint-tooling`) open and unmerged; `spec-lint` CI job advisory only (D-029, NOT in 8 required status checks) | MEDIUM | phase-2 | pr-manager | PR #2 squash-merged to `develop` as `2290cb0` after a 7-cycle pr-manager review lifecycle under D-028/D-031 level-4 autonomy. 9/9 required checks green; advisory `spec-lint` fails as designed per D-029/D-032. Branch deleted. | 2026-08-06 |
| BI-008 | P4-014: TEN VP harnesses specified at `tests/<subdir>/<name>.rs` — Cargo does NOT auto-discover that path; VP-011, VP-014..018, VP-020, VP-025, VP-026 would compile to nothing and report green | CRITICAL | phase-3/phase-6 gate | architect | All ten VP harness paths flattened to Cargo-discoverable `tests/<category>_<name>.rs`; 'Test Target Layout' section added to `architecture/tooling-selection.md`. Orchestrator independently confirmed Cargo discovers `tests/*.rs` and `tests/<dir>/main.rs` only. | 2026-08-06 |
| BI-009 | P4-001: BC-2.06.001 Invariant 2 says HTML element TEXT is DISCARDED (`## <kbd>Ctrl+C</kbd>` → `""`); DI-012 rule 1 and both new BI-005 golden vectors (VP-018, VP-026) say it is RETAINED — irreconcilable expected outputs on the product's headline differentiator | CRITICAL | phase-2 (blocks story decomposition) | architect | Architect adjudicated in ADR-008 + DI-012 rule 1: HTML tag tokens stripped, visible text RETAINED. `BC-2.06.001` Invariant 2 amended and its `<kbd>Ctrl+C</kbd>` worked example corrected; discriminating vector added to `test-vectors.md` §7. | 2026-08-06 |
| BI-011 | P4-012: VP-026's oracle corpus test passes VACUOUSLY on an empty or truncated corpus — no positive-coverage assertion and the R-001..R-008 requirement is prose-only | HIGH | phase-6 gate | architect | VP-026 oracle test now asserts required run ids R-001..R-008/R-009/OR-010 present, R-001 >=3 entries, entries_checked >=10, plus a POL-11 positive-coverage line. | 2026-08-06 |
| BI-013 | `check-ec-injectivity` was FALSE-PASSING: it scanned 141 of 183 EC IDs and reported ZERO multi-file appearances when 110 existed. Hardened on PR #2, it surfaced 13 genuine EC-ID collisions (semantically different edge cases sharing one ID) — the D-026 class recurring. All 13 remediated by append-only reallocation to EC-184..EC-204 with 21 new registry entries; checker now passes at 205 EC IDs all injective. CONSEQUENCE: adversary pass 4 was instructed to SKIP the EC-injectivity class on the false premise it was enforced. | RESOLVED (content) / recorded (process) | phase-1d | orchestrator | Content fixed. Process rule recorded as D-040. | 2026-08-06 |
