---
document_type: wave-schedule
level: ops
version: "1.0"
status: draft
producer: story-writer
timestamp: 2026-08-10T00:00:00Z
phase: 2
inputs:
  - .factory/stories/STORY-INDEX.md
  - .factory/stories/dependency-graph.md
traces_to: .factory/stories/STORY-INDEX.md
---

# Wave Schedule: mdlinkcheck

## Summary

| Metric | Value |
|--------|-------|
| Total stories | 24 |
| Total waves | 7 |
| Max parallelism (groups per wave) | 3 (waves 2 and 3) |
| Estimated agent spawns | 14 |
| Total story points | 152 |
| Total estimated days | 31 |

## Wave Gate Note — Wave 1

**Wave 1 is the DEV-11 "Run A" endpoint.** After wave 1 lands, the operator is asked to stop or continue. This is intentional: wave 1 proves the full TDD → PR → demo → gate machinery end-to-end (workspace scaffold, core file discovery, Cargo workspace, shared types) before any additional waves are committed. Wave 1 is a single story precisely to minimise sunk cost if the operator chooses to stop.

---

## Wave Plan

### Wave 1 — Foundation (no dependencies)

| Group | Stories | Points | Complexity | Agent Scope |
|-------|---------|--------|------------|-------------|
| A | S-1.01 | 8 | L | 1 story/agent |

**Wave total:** 1 story, 8 points

---

### Wave 2 — Core Infrastructure (depends on Wave 1)

| Group | Stories | Points | Complexity | Agent Scope |
|-------|---------|--------|------------|-------------|
| A | S-1.02, S-6.01, S-7.02 | 8, 8, 8 | L, L, L | 1 story/agent each |
| B | S-1.03, S-3.01, S-5.02 | 5, 5, 5 | M, M, M | 2–3 stories/agent |
| C | S-3.03 | 3 | S | 1 story/agent |

**Wave total:** 7 stories, 42 points

---

### Wave 3 — Link Extraction, Exit Logic, JSON Report (depends on Wave 2)

| Group | Stories | Points | Complexity | Agent Scope |
|-------|---------|--------|------------|-------------|
| A | S-2.01, S-7.01, S-7.03 | 5, 5, 5 | M, M, M | 2–3 stories/agent |
| B | S-6.02 | 8 | L | 1 story/agent |
| C | S-1.04 | 3 | S | 1 story/agent |

**Wave total:** 5 stories, 26 points

---

### Wave 4 — Link Variants, Anchor Table, URL/Filter Wiring (depends on Wave 3)

| Group | Stories | Points | Complexity | Agent Scope |
|-------|---------|--------|------------|-------------|
| A | S-2.02, S-2.03, S-5.01 | 5, 5, 5 | M, M, M | 2–3 stories/agent |
| B | S-3.02, S-4.02 | 8, 8 | L, L | 1–2 stories/agent |

**Wave total:** 5 stories, 31 points

---

### Wave 5 — Anchor Resolution, DirIndex, HTTP Client Protocol (depends on Wave 4)

| Group | Stories | Points | Complexity | Agent Scope |
|-------|---------|--------|------------|-------------|
| A | S-3.04, S-5.03 | 8, 8 | L, L | 1–2 stories/agent |
| B | S-4.01 | 5 | M | 1 story/agent |

**Wave total:** 3 stories, 21 points

---

### Wave 6 — Path Resolver, HTTP Transport Hardening (depends on Wave 5)

| Group | Stories | Points | Complexity | Agent Scope |
|-------|---------|--------|------------|-------------|
| A | S-4.03 | 13 | XL | 1 story/agent |
| B | S-5.04 | 8 | L | 1 story/agent |

**Wave total:** 2 stories, 21 points

---

### Wave 7 — CLI Integration and Main Routing (depends on Wave 6)

| Group | Stories | Points | Complexity | Agent Scope |
|-------|---------|--------|------------|-------------|
| A | S-7.04 | 3 | S | 1 story/agent |

**Wave total:** 1 story, 3 points

---

## Per-Wave Summary

| Wave | Stories | Points | Notes |
|------|---------|--------|-------|
| 1 | 1 | 8 | DEV-11 Run A gate — operator stop/continue |
| 2 | 7 | 42 | Core infrastructure, max parallelism |
| 3 | 5 | 26 | Link extraction, exit logic, JSON report |
| 4 | 5 | 31 | Link variants, anchor table, URL/filter wiring |
| 5 | 3 | 21 | Anchor resolution, DirIndex, HTTP client protocol |
| 6 | 2 | 21 | Path resolver, HTTP transport hardening |
| 7 | 1 | 3 | CLI integration and main routing |
| **Total** | **24** | **152** | 7 waves |

---

## Critical Path

The longest dependency chain from root to leaf:

```
S-1.01 → S-1.03 → S-2.01 → S-3.02 → S-4.01 → S-4.03 → S-7.04
```

| Story | Points | Wave |
|-------|--------|------|
| S-1.01 | 8 | 1 |
| S-1.03 | 5 | 2 |
| S-2.01 | 5 | 3 |
| S-3.02 | 8 | 4 |
| S-4.01 | 5 | 5 |
| S-4.03 | 13 | 6 |
| S-7.04 | 3 | 7 |
| **Total** | **47** | — |

**Critical path total: 47 points across all 7 waves.**

The critical path runs through every wave of the schedule; there is no opportunity to compress the schedule by reordering these stories.

---

## BC Co-Implementation Note (BC-2.07.001, BC-2.07.002, BC-2.07.003)

These three behavioral contracts are each implemented across multiple E-4 stories. A BC is only fully satisfied once every contributing story has landed.

| BC | Contributing Stories | Waves | Completed After Wave |
|----|---------------------|-------|----------------------|
| BC-2.07.001 | S-4.02 (fragment split, empty-dest), S-4.01 (pass-1.5 DirIndex), S-4.03 (path resolver) | 4, 5, 6 | **Wave 6** |
| BC-2.07.002 | S-4.01 (pass-1.5 DirIndex), S-4.03 (path resolver) | 5, 6 | **Wave 6** |
| BC-2.07.003 | S-4.01 (pass-1.5 DirIndex), S-4.03 (path resolver) | 5, 6 | **Wave 6** |

All three BCs reach full satisfaction at the wave 6 gate.

---

## Pipeline Overlap Plan

| Parallel Activity | When |
|-------------------|------|
| Wave 2 stubs | Start when Wave 1 PR merges |
| Wave 3 stubs | Start when Wave 2 types are available |
| Wave N+1 test scaffolds | Start when Wave N stubs compile |
| Wave N+1 implementation | Start after Wave N+1 Red Gate verified |
