---
document_type: adr
adr_id: ADR-007
status: accepted
date: 2026-08-05
version: "1.3"
subsystems_affected: [SS-08, SS-09, SS-10, SS-11, SS-14]
supersedes: null
superseded_by: null
---

# ADR-007: Two-Layer Verdict Model — clean / broken / indeterminate

## Context

`--online` mode checks external URLs for reachability. External HTTP requests can
fail for reasons other than the link being broken: network timeouts, 429 rate
limits, 503 temporary maintenance. If these transient failures are reported as
`broken`, users waste time investigating links that are actually alive — destroying
CI trust and causing teams to disable the tool. This is the anti-false-positive
requirement captured in DI-010.

The simplest model is binary: alive or broken. But this forces a choice between
two bad options: (a) report transient failures as broken (false positives), or
(b) ignore them (false negatives for genuinely broken links that return 503).

**Scope note on DNS and TLS:** Unlike 429 or 5xx (which signal a live server
refusing automation), DNS resolution failure and TLS handshake failure indicate
that the resource is definitively unreachable — either the hostname does not exist
or the certificate is invalid. These are `broken` conditions, not transient ones.
This distinction is critical: classifying them as `indeterminate` would create
false negatives for genuinely broken external links.

## Decision

Use a two-layer verdict model with a closed 13-code reason taxonomy:

**Layer 1 — Link Verdict** (the per-link result the tool reports; drives exit codes):
- **`clean`** — the link is valid: target exists and any anchor is present, OR an
  external URL liveness check returned `alive`. `clean` findings are NOT emitted in output.
- **`broken`** — the link is definitively broken; exit code 1 applies.
- **`indeterminate`** — the check could not produce a definitive verdict (transient
  server-side conditions, connection errors, private-IP access, https-downgrade, or
  400 after GET fallback per D-018); does NOT trigger exit 1.

**Layer 2 — URL Liveness Outcome** (`--online` HTTP checks only; intermediate value,
never reported in output):
- **`alive`** — external URL responded with success status (2xx after any redirects).
  Maps to link verdict **`clean`**.
- **`broken`** — external URL is definitively unreachable. Maps to link verdict **`broken`**.
- **`indeterminate`** — liveness check was inconclusive. Maps to link verdict **`indeterminate`**.

`alive` is an HTTP-layer liveness outcome. It is NOT a fourth link verdict and NEVER
appears in report output or JSON. The JSON `verdict` field contains only `"broken"` or
`"indeterminate"` — `clean` findings are suppressed; `alive` is internal only (DI-005;
DD-022 two-layer ruling). `indeterminate` findings are surfaced in output but do not
trigger a CI failure (anti-false-positive design).

**Exit codes (canonical definition — R7, DD-006, DI-011, BC-2.14.002):**
- **0** — no `broken` findings, no I/O errors
- **1** — at least one `broken` finding
- **2** — at least one I/O error (takes precedence over exit 1)

VP-005 and VP-006 Kani-prove this mapping for the `verdict` module.

The **13 closed reason codes** (authoritative source: `prd-supplements/error-taxonomy.md`)
map to verdicts and exit codes as follows:

`broken` (exit 1):
- `file-not-found` — resolved destination path does not exist or fails case-sensitive comparison
- `target-is-directory` — destination resolves to a directory and a fragment is present
- `broken-symlink` — destination is a dangling symlink
- `anchor-not-found` — fragment does not match any entry in the target file's anchor table
- `undefined-reference-definition` — reference label has no corresponding definition
- `malformed-url` — external URL fails WHATWG URL parse
- `http-error` — 404 or 410 after HEAD+GET fallback (400 after GET fallback is `indeterminate` per D-018, not `broken`)
- `dns-failure` — hostname could not be resolved by DNS
- `tls-error` — TLS handshake failed (expired cert, self-signed, hostname mismatch)
- `too-many-redirects` — redirect chain exceeded 10 hops

`indeterminate` (no exit 1, information-only):
- `http-timeout` — request exceeded 10-second per-URL timeout
- `http-indeterminate` — 429, 5xx, or bot-blocking 403/999 after GET fallback; OR 400 after
  GET fallback (D-018 ruling); OR connection reset before any response; OR target IP is
  private/link-local (no outbound request sent, BC-2.10.010); OR https→http downgrade in
  redirect chain (BC-2.10.007)

I/O error (exit 2, not a link verdict):
- `target-unreadable` — source `.md` file exists but cannot be read

`clean` and `alive` carry no reason code.

## Rationale

**False positives are worse than false negatives for CI gates:** A CI job that
fails on a 429 from GitHub's rate limiter blocks deployment without user action.
This destroys trust in the tool and causes teams to disable it. `indeterminate`
gives the user information without forcing a false failure.

**DNS failure and TLS error are `broken`, not `indeterminate`:** A DNS resolution
failure means the hostname does not exist in the public DNS — the link is broken.
A TLS handshake failure means the server's certificate is invalid — the link is
broken in any normal browser context. These are NOT transient server-side
rejections of automation; they are objective reachability failures. This mirrors
the taxonomy in `error-taxonomy.md` and `failure-modes.md`.

**Closed taxonomy prevents vendor lock-in:** Using a closed set of 13 reason codes
means the JSON schema is stable. Tools consuming mdlinkcheck output (scripts, CI
parsers, VS Code extensions) can write exhaustive switch statements. Any unmapped
HTTP status or error condition maps to `indeterminate` — a safe default.

**Two-layer verdict model enables future `--strict-indeterminate` flag:** If users want
`indeterminate` to count as broken (for paranoid CI environments), they can pass
`--strict-indeterminate` (DD-016). The two-layer model makes this future flag
straightforward; a binary model would require re-architecting.

## Consequences

### Positive
- Anti-false-positive invariant (DI-010) is architecturally enforced
- VP-005 and VP-006 Kani proofs verify the exit-code mapping; VP-007 Kani proof verifies `http_verdict::classify_response` correctness (HTTP-layer verdict classification)
- JSON schema is stable and versioned
- CI environments never fail spuriously on rate limits or transient network errors
- Future `--strict-indeterminate` flag is additive, not a breaking change

### Negative / Trade-offs
- Three-way enum requires exhaustive pattern matching throughout the codebase
- Users may initially be confused by `indeterminate` verdict in output
- 5xx responses from a server that is genuinely down produce `indeterminate`, not `broken`
  (acceptable: the server may come back up; rerun the checker after the outage)

### Status as of 2026-08-05

Accepted. Verdict model not yet implemented (Phase 3 scope). The 13 reason codes
are defined in prd-supplements/error-taxonomy.md and must not be modified without
an ADR update.

## Alternatives Considered

- **Binary model (alive/broken):** Simpler but forces false positives on transient
  failures. Rejected per DI-010 anti-false-positive requirement.
- **Retry-before-verdict:** Automatically retry 429 and 5xx N times before reporting
  indeterminate. Increases latency significantly for large repos with many external
  links. Rejected as too expensive by default; retry is a user-facing flag (DD-016).
- **Warning vs error distinction:** Use exit code 1 for warnings, 2 for errors.
  Rejected: POSIX exit codes are simpler; `indeterminate` in JSON provides the
  same information.

## Changelog

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.3 | 2026-08-05 | architect | P3-001/P3-002 hotfix: rewrote Decision section to two-layer model (DD-022); H1 corrected to `clean / broken / indeterminate`; `http-error` broken list corrected (400 removed per D-018 ruling; only 404 and 410 are broken); `http-indeterminate` expanded with 400-after-GET, connection-reset, private-ip (BC-2.10.010), https-downgrade (BC-2.10.007); erroneous `alive`-appears-in-output claim removed; I/O error labeled not-a-link-verdict; VP-007 Consequences corrected; Source updated with D-018, DD-022, BC-2.10.007, BC-2.10.010; subsystems_affected sorted |
| 1.2 | 2026-08-05 | architect | REGRESSION-006 remediation: replaced all three references to DD-015 with DD-016 (correct decision ID for GET fallback and retry behavior) |
| 1.1 | 2026-08-05 | architect | SR-032/SR-033 remediation: corrected exit codes (1=broken, not 2); replaced five invented reason codes with the 13 canonical codes from error-taxonomy.md; moved dns-failure and tls-error from indeterminate to broken per BC-2.10.005/006 and error-taxonomy.md; updated terminology (alive not valid; 13 codes not 9) |
| 1.0 | 2026-08-05 | architect | Initial draft |

## Source / Origin

- DI-010: Anti-false-positive invariant; two-layer verdict model mandate
- DI-011: Exit code specification (1=broken, 2=I/O error, 0=no broken)
- DI-005: Exactly one verdict per link; `alive` is URL-liveness outcome, not a link verdict
- R7 (BRIEF), DD-006, BC-2.14.002: Frozen exit-code semantics
- DD-022: Two-layer verdict model ruling; `alive` is URL-liveness outcome, not a link verdict; `clean` is the positive link-level verdict
- D-018: HTTP 400 after GET fallback is `indeterminate`, not `broken` (binding human ruling)
- prd-supplements/error-taxonomy.md: Closed 13-reason taxonomy (authoritative)
- domain-spec/failure-modes.md: Failure mode classification (broken vs indeterminate)
- VP-005, VP-006: Kani proofs for exit-code correctness in the `verdict` module
- VP-007: Kani totality proof for `http_verdict::classify_response`
- DD-016: GET fallback and retry behavior
- BC-2.10.005: DNS resolution failure → broken verdict
- BC-2.10.006: TLS handshake failure → broken verdict
- BC-2.10.007: https→http downgrade in redirect chain → `http-indeterminate` (sub-reason)
- BC-2.10.010: Private-IP / link-local URL → `http-indeterminate` (no outbound request)
