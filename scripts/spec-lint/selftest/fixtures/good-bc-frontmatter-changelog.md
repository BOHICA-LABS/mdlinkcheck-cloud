---
bc_id: BC-2.99.SELFTEST-GOOD
title: "Selftest fixture: phantom code in frontmatter changelog only"
lifecycle_status: active
introduced: v0.0.0
modified:
  - "v1.1: historical note — error class changed from phantom-historical-code to file-not-found."
deprecated: null
---

# BC-2.99.SELFTEST-GOOD: Selftest — Phantom Code in Frontmatter Only (BI-050)

This file is a CLEAN selftest fixture for check-adr-consistency POLICY 19
broad-corpus check.  The string `phantom-historical-code` appears ONLY in the
YAML frontmatter `modified:` changelog entry (a historical record).  The
position-based frontmatter exclusion (D-081) must NOT flag this as a violation.

## Invariants

1. Exit code 1 indicates broken links with reason `file-not-found`.
2. Exit code 0 indicates no broken links found.
