---
document_type: dtu-assessment
level: L3
version: "1.0"
status: draft
producer: architect
timestamp: 2026-08-05T00:00:00Z
phase: 1b
inputs:
  - BRIEF.md
  - .factory/specs/domain-spec/capabilities.md
  - .factory/specs/domain-spec/decisions.md
  - .factory/planning/market-intelligence.md
input-hash: "d00a454"
traces_to: .factory/specs/architecture/ARCH-INDEX.md
---

# DTU Assessment: mdlinkcheck

## DTU Verdict

**`DTU_REQUIRED: false`**

`mdlinkcheck`'s only external surface is generic HTTP(S) probing to arbitrary URLs
(`--online` mode, CAP-010). There is no specific third-party service API to clone —
the product talks to whatever URLs appear in the user's Markdown files. Every
behavior the verdict logic depends on (HTTP status codes, `Retry-After` headers,
redirect chains, transport-level failures) is fully controllable with an in-process
mock HTTP server. No containerized behavioral clone is warranted.

---

## Summary

| Metric | Value |
|--------|-------|
| External dependencies identified | 1 (generic HTTP/HTTPS probe surface, `--online` mode only) |
| DTU clones recommended | 0 |
| Total clone story points | 0 |
| Estimated Wave 1 DTU capacity needed | 0 points |
| Alternative strategy | `httpmock` 0.8.3 in-process mock server (verified crates.io 2026-08-05) |
| Phase 3 hermetic? | Yes — localhost only, no network |
| Phase 4 holdout hermetic? | Yes — deterministic fixture scripts, no real URLs |

---

## Integration Surface Inventory (MANDATORY — all categories required)

### Inbound Data Sources (External → Product)

None identified — rationale: `mdlinkcheck` does not poll any API, consume any feed,
or receive webhooks. It reads local Markdown files from the filesystem. The
`--online` probe to external URLs is initiated by the product (outbound probe),
not inbound data pushed to the product.

| # | Service | Protocol | Fidelity | DTU? | Justification |
|---|---------|----------|----------|------|---------------|
| — | None | — | — | No | Pure local input (filesystem) |

### Outbound Operations (Product → External)

The `--online` HTTP probe surface. When `--online` is passed (R2c, CAP-010), the
tool issues HEAD (then GET fallback) requests to each unique external http(s) URL
found in the scanned Markdown files to determine liveness. This is a read-only
probe — it does not create, update, or delete any remote resource.

The product makes no other outbound calls. There are no notifications, no ticketing,
no payment, no command execution.

| # | Service | Protocol | Fidelity | DTU? | Justification |
|---|---------|----------|----------|------|---------------|
| 1 | Generic HTTP/HTTPS endpoints (arbitrary user URLs) | HTTP/1.1 + HTTPS | L2 (Stateful — response codes, headers, redirect sequences) | **No** | All response patterns (status codes, headers, redirect chains, transport failures) are fully programmable via `httpmock` 0.8.3. No specific service API to clone — see detailed analysis below. |

### Identity & Access (Bidirectional — auth flow)

None identified — rationale: `mdlinkcheck` is a CLI tool with no authentication
layer. It makes unauthenticated HTTP probes. No OAuth, no API keys, no credential
stores, no SSO. The `--online` mode does not support authenticated requests (out of
scope per the brief's non-goals).

| # | Service | Protocol | Fidelity | DTU? | Justification |
|---|---------|----------|----------|------|---------------|
| — | None | — | — | No | No auth surface; all probes are unauthenticated |

### Persistence & State (Product ↔ Storage)

None identified — rationale: `mdlinkcheck` is a stateless CLI. No external database,
cache, object store, or message queue. There is no URL cache or run-history storage
(explicitly excluded from non-goals in the brief).

| # | Service | Protocol | Fidelity | DTU? | Justification |
|---|---------|----------|----------|------|---------------|
| — | None | — | — | No | Stateless CLI; no external persistence |

### Observability & Export (Product → Monitoring)

None identified — rationale: `mdlinkcheck` writes findings to stdout and diagnostics
to stderr. There is no telemetry emission, no metrics push, no log aggregator, no
tracing backend. It is a local CLI tool.

| # | Service | Protocol | Fidelity | DTU? | Justification |
|---|---------|----------|----------|------|---------------|
| — | None | — | — | No | Stdout/stderr only; no observability endpoints |

### Enrichment & Lookup (External → Product, on-demand)

None identified — rationale: `mdlinkcheck` does not consult any enrichment service.
It does not look up threat intelligence, DNS blocklists, CDN metadata, or any
third-party data to augment its verdicts. The DNS resolution that occurs as part of
an HTTP connection is OS-level, not a service integration.

| # | Service | Protocol | Fidelity | DTU? | Justification |
|---|---------|----------|----------|------|---------------|
| — | None | — | — | No | No enrichment surface |

---

## Dependency Summary

| # | Service | Category | Fidelity | DTU? | Points | Justification |
|---|---------|----------|----------|------|--------|---------------|
| 1 | Generic HTTP/HTTPS endpoints (`--online` probe) | Outbound Operations | L2 | **No** | 0 | In-process `httpmock` 0.8.3 fully discharges the test risk; see hermetic strategy below |

---

## Services NOT Requiring DTU

| # | Surface | Reason |
|---|---------|--------|
| 1 | Generic HTTP/HTTPS (`--online` probe) | The verdict logic (CAP-010, DD-004, DD-016) is defined entirely in terms of HTTP response codes, headers, and transport events — not in terms of any specific third-party service's behavior. Every required response pattern is programmable via an in-process `httpmock` 0.8.3 server binding to a random localhost port. No real CDN, no real GitHub, no real LinkedIn is needed to exercise the full behavioral surface. |

---

## Detailed Analysis: Why In-Process Mock Is Sufficient for `--online`

### The fundamental distinction

A DTU clone is warranted when the product integrates with a **specific third-party
service API** whose behavior must be faithfully reproduced for tests to be meaningful
— for example, cloning Stripe's payment flow, GitHub's REST API, or an OAuth
provider's token exchange. The clone must reproduce service-specific semantics that
cannot be captured by a generic HTTP mock.

`mdlinkcheck --online` probes **arbitrary URLs** specified by the user in their
Markdown files. The product has no relationship with any specific external service.
Its verdict logic is a function of standard HTTP semantics only:

| Behavior | How tested with in-process mock |
|----------|---------------------------------|
| HEAD → 200 → `alive` | Mock: `HEAD /url → 200` |
| HEAD → 404 → GET → 404 → `broken` (reason: `http-error`) | Mock: `HEAD → 404`, `GET → 404` |
| HEAD → 403 → GET → 200 → `alive` | Mock: `HEAD → 403`, `GET → 200` |
| HEAD → 403 → GET → 403 → `indeterminate` (bot-blocking) | Mock: `HEAD → 403`, `GET → 403` |
| HEAD → 405 → GET → 200 → `alive` | Mock: `HEAD → 405`, `GET → 200` |
| HEAD → 400 → GET → 200 → `alive` | Mock: `HEAD → 400`, `GET → 200` |
| HEAD → 501 → GET → 200 → `alive` | Mock: `HEAD → 501`, `GET → 200` |
| HEAD → 999 → GET → 200 → `alive` (LinkedIn pattern) | Mock: `HEAD → 999`, `GET → 200` |
| HEAD → 999 → GET → 999 → `indeterminate` | Mock: `HEAD → 999`, `GET → 999` |
| HEAD → 429 + `Retry-After: N` → host paused → retry → 200 → `alive` | Mock: `HEAD → 429` + header, then `HEAD → 200` |
| 5xx response → `indeterminate` | Mock: `GET → 503` |
| Timeout (10 s exceeded) → `indeterminate` | Mock: slow-response fixture (delay > 10 s) |
| Transport failure on HEAD → GET fallback | Hand-rolled `TcpListener`: accept + immediate close |
| Redirect chain (≤10 hops) → `alive` | Mock: chain of `301 → 301 → ... → 200` |
| Redirect chain (>10 hops) → `broken` (reason: `too-many-redirects`) | Mock: chain of 11+ `301` responses |
| DNS failure → `broken` (reason: `dns-failure`) | Use a non-routable domain (e.g., `http://127.0.0.255:1/`) |

### Real-world server behaviors considered and found unnecessary to clone

**GitHub 429 behavior**: GitHub's anti-abuse layer returns 429 (or 403) to CI
runners sharing an outbound IP. The spec assigns this to `indeterminate` (DD-004,
DI-010). The test requirement is: does the tool correctly classify 429 as
`indeterminate` and pause the host? A mock returning `HTTP 429 Retry-After: 5` fully
exercises this path. Reproducing GitHub's actual rate-limit algorithm is not required
— GitHub's behavior is the *input stimulus*, and an in-process mock provides the
same stimulus.

**LinkedIn 999 / CDN bot-blocking**: These are the `http-indeterminate` reason code
cases. The detection criterion per the spec is purely response-code based: 403/999
after the GET fallback. A mock server returning those exact codes exercises the
classification logic completely. Reproducing Cloudflare's actual bot-fingerprinting
or LinkedIn's actual WAF is irrelevant — the tool is not expected to bypass them.

**Redirect semantics**: `ureq` 3.3.0 handles redirects internally. Testing redirect
handling means configuring a mock to issue 3xx chains and verifying the final
verdict. No CDN-specific redirect behavior is required.

### Crate selection and MSRV compatibility

`httpmock` 0.8.3 (released 2026-02-04, verified crates.io 2026-08-05) is the
recommended test crate for all `--online` behavioral tests.

| Property | Value |
|----------|-------|
| Crate | `httpmock` |
| Version | 0.8.3 |
| Released | 2026-02-04 |
| License | MIT |
| MSRV compatibility | Compatible with Rust 1.85 (project MSRV per DD-001) |
| Async requirement | None for basic use — can be used with blocking test style matching `ureq` / `rayon` architecture |
| Key features | Random localhost port binding, arbitrary status codes and headers, redirect mocking, HTTPS support, HTTP/2 support, `Retry-After` header support, sequence-based response chaining |

`wiremock` 0.6.5 (2025-08-24) was considered and rejected: it requires a tokio
runtime (`#[tokio::test]`), which conflicts with the project's synchronous
`ureq`-based architecture. Adding tokio as a dev-dependency for mocking only would
pull in a heavy async runtime and complicate the test stack unnecessarily.

For transport-level failure scenarios (connection reset, premature close on HEAD),
no crate is required — a hand-rolled `TcpListener` fixture in a few lines of stdlib
Rust is sufficient and has no additional dependencies.

---

## Hermetic Test Strategy for `--online` (Phase 3 and Phase 4)

This section is the primary output of the DTU assessment since `DTU_REQUIRED: false`.
It specifies concretely how `--online` behavioral correctness is tested without
network access.

### Phase 3 (TDD implementation)

**Pattern**: Each `--online` behavioral contract in CAP-010 gets a dedicated
integration test that:

1. Spawns an `httpmock::MockServer::start()` on a random free localhost port (fully
   in-process, no Docker, no network).
2. Registers the required response sequence on the mock (e.g., HEAD → 429,
   then HEAD → 200 with timing assertions).
3. Creates a temporary Markdown fixture file containing a URL pointing to
   `http://127.0.0.1:{mock_port}/path`.
4. Invokes the `mdlinkcheck` binary (or its core library under test) with `--online`.
5. Asserts the JSON output verdict, reason code, and exit code against expectations.
6. Verifies mock expectations (e.g., that exactly 2 requests were made — 1 HEAD
   and 1 GET fallback).

**Scope of coverage** (BCs that this strategy discharges):

| BC | Behavior | Mock setup |
|----|----------|-----------|
| CAP-010 / DD-004 | 429 → host pause → honor `Retry-After` | HEAD → 429 + `Retry-After: 2`, then HEAD → 200; assert ~2 s elapsed |
| CAP-010 / DD-016 | HEAD fallback on {400,403,404,405,501,999} | HEAD → N, GET → 200; assert `alive` |
| CAP-010 / DD-016 | HEAD fallback on transport close | `TcpListener` accept-then-close; GET → 200; assert `alive` |
| CAP-010 / DD-004 | Bot-403 detection | HEAD → 403, GET → 403; assert `indeterminate` |
| CAP-010 / DD-004 | 5xx → `indeterminate` | GET → 503; assert `indeterminate`, exit 0 |
| CAP-010 / DD-004 | Timeout → `indeterminate` | Mock delay fixture > 10 s; assert `indeterminate`, exit 0 |
| CAP-010 / decisions.md | Redirect chain ≤ 10 hops | Mock chain of 10 × 301 → 200; assert `alive` |
| CAP-010 / decisions.md | Redirect chain > 10 hops | Mock chain of 11 × 301; assert `broken`, reason `too-many-redirects` |
| CAP-010 | DNS failure | URL → `http://127.0.0.255:1/` (non-routable); assert `broken`, reason `dns-failure` |
| CAP-009 | Malformed URL syntax | No network needed; in-process WHATWG parse; assert `broken`, reason `malformed-url` |
| CAP-011 | `--allow` exempts URL | URL matches prefix; assert `clean` (no probe made); verify zero mock requests |

**Per-host concurrency**: Tests that exercise the per-host 429 pausing behavior
must run requests concurrently against the same mock host. Use a rayon scope or
multiple threads pointing at the same mock port to verify that only one thread
dispatches retries after the backoff window.

### Phase 4 (Holdout Evaluation)

Phase 4 holdout scenarios involving `--online` must be hermetic:

1. **Fixture Markdown files** are pre-authored with URLs in the form
   `http://127.0.0.1:{FIXTURE_PORT}/...` where `FIXTURE_PORT` is a deterministic
   constant assigned to the holdout scenario.
2. **Response scripts** for each fixture port are pre-authored as `httpmock`
   configuration files (or inline Rust test code), specifying the exact response
   sequence for each path.
3. The holdout evaluator spawns fixture mock servers before invoking
   `mdlinkcheck --online` and tears them down after.
4. No real network calls are made during holdout evaluation. The entire
   `--online` surface is exercised against localhost.
5. Scenarios are deterministic and reproducible across machines, CI environments,
   and time.

**Explicit flag**: The holdout evaluator MUST NOT use real external URLs in
`--online` scenarios. Any test that would require hitting `https://github.com`,
`https://linkedin.com`, or any real host is **disqualified** as a holdout scenario
for `--online`. Offline-mode scenarios (file paths, anchors) have no such
restriction and are already network-independent by design.

---

## Risk Residual

After adopting `httpmock` in-process mocking, the following residual risks remain.
None warrants a DTU clone.

| Risk | Residual | Mitigation |
|------|----------|-----------|
| Real CDN bot-detection is more complex than 403/999 | Low — spec assigns all bot-blocking to `indeterminate`; tool is not expected to distinguish CDN providers | Document as accepted limitation; `--allow` is the user escape hatch |
| Real-world 429 `Retry-After` date-form parsing edge cases | Low — testable with mock returning RFC 1123 date strings | Add date-form `Retry-After` test to the fixture suite |
| `ureq` 3.3.0 redirect handling edge cases (protocol downgrade, cross-origin) | Low — ureq handles redirects; spec defers details to L3 | Cover with mock redirect chains including HTTP→HTTP cross-path redirects |
| Transport failure injection completeness | Medium — `httpmock` supports error simulation but TcpListener fixtures are more direct for raw TCP | Use stdlib `TcpListener` for connection-reset and premature-close scenarios; no crate gap |

---

## Conclusion

`DTU_REQUIRED: false`. All six integration surface categories are empty or reduce to
a single generic HTTP probe surface (`--online` mode) that is fully covered by
`httpmock` 0.8.3 in-process mocking. The product has no specific third-party service
dependency, no auth surface, no persistence layer, and no telemetry export. Phase 3
and Phase 4 `--online` tests are hermetic by construction: they bind to random
localhost ports, require no network, produce deterministic verdicts, and leave no
flakiness vectors from real CDN rate-limiting or bot-protection policies.
