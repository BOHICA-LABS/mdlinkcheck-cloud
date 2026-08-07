---
document_type: product-brief
level: L1
version: "1.1"
status: approved
producer: human
timestamp: 2026-08-05T00:00:00Z
phase: 1a
inputs:
  - BRIEF.md
input-hash: "53940c2"
traces_to: ""
changelog:
  - version: "1.1"
    date: 2026-08-06
    change: "CV5-001 / D-043 (macOS-only platform directive): Platform matrix constraint corrected from 'macOS, Linux, Windows' to 'macOS'. This was the L1 root of the traceability chain and the last site asserting a three-platform claim. Decision reference updated from '(human decision)' to '(human decision D-043)' to make the narrowing decision explicit."
  - version: "1.0"
    date: 2026-08-05
    change: "Initial draft"
---

# Product brief: mdlinkcheck

A fast, offline-first markdown link checker CLI, written in Rust.

## Problem
Documentation repos rot: files move, headings get renamed, external sites die.
CI needs a deterministic, fast tool that fails the build when links break,
without false positives that train people to ignore it.

## Users
Engineers running it locally and in CI on repos containing Markdown.

## Functional requirements
R1. `mdlinkcheck [PATH]...` scans the given files/directories (default `.`)
    for `*.md` files and checks every link in them.
R2. Link kinds checked:
    a. Relative file links (`[x](docs/a.md)`, `[x](../b.md)`) — target must exist.
    b. Intra- and cross-file heading anchors (`[x](#setup)`, `[x](a.md#usage)`) —
       anchor must match a heading in the target file using GitHub's slug algorithm.
    c. Absolute http(s) URLs — HEAD request (GET fallback on 405), 10s timeout,
       checked ONLY when `--online` is passed. Default is offline: external URLs
       are syntax-validated but not fetched.
R3. Reference-style links and images are checked the same as inline ones.
R4. Links inside fenced code blocks and inline code spans are IGNORED.
R5. `--ignore <glob>` (repeatable) excludes files; `--allow <url-prefix>`
    (repeatable) exempts external URLs from checking.
R6. Output: human-readable text (default) listing file:line, link target, and
    failure reason; `--format json` emits a machine-readable array of the same.
R7. Exit codes: 0 = no broken links; 1 = at least one broken link; 2 = usage or
    I/O error (unreadable path, invalid flag).
R8. Performance: checking a repo with 500 markdown files and no external URLs
    completes in under 5 seconds on a developer laptop.

## Non-goals
No link rewriting/fixing, no HTML parsing, no JavaScript rendering, no config
file (flags only), no watch mode.

## Success criteria
Passes its own test suite; correctly classifies the acceptance corpus (planted
broken links found, valid-link traps not flagged); runs clean on this repo's
own README.

<!-- Template compliance sections — body above is VERBATIM from BRIEF.md (frozen) -->

## What Is This?

N/A — covered verbatim by the untitled overview line and `## Problem` above.
Brief uses non-canonical heading names; content is unchanged. Section mapping:
`overview line + ## Problem` ↔ `## What Is This?`.

## Who Is It For?

N/A — covered verbatim by `## Users` above.
Section mapping: `## Users` ↔ `## Who Is It For?`.

## Scope

N/A — covered verbatim by `## Functional requirements` (in-scope) and
`## Non-goals` (out-of-scope) above.
Section mapping: `## Functional requirements` + `## Non-goals` ↔ `## Scope`.

## Constraints & Integration Points

Captured here per template requirement; absent from frozen BRIEF.md body (BV-016).
Populated from human decisions made during Phase 1 planning:

- **Language:** Rust, MSRV 1.85 (human decision D-004; required by clap 4.6.x and ureq 3.3.0)
- **Platform matrix:** macOS (human decision D-043; drives path-handling model)
- **No config file:** flags only (stated non-goal in brief)
- **No inline suppression directives:** explicitly out of scope (human decision D-009)
- **No GFM bare-URL autolinks:** out of scope; pulldown-cmark 0.13.4 does not support them (D-009)
- **Distribution:** TBD — `cargo install` + GitHub release binaries (deferred to architecture phase)
- **JSON schema stability:** pre-1.0; unstable until v1.0 release (BV-019)
