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
