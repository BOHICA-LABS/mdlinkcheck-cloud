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
