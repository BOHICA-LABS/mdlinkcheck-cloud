---
document_type: prd-supplement
supplement_type: error-taxonomy
level: L3
version: "1.6"
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
traces_to: .factory/specs/prd.md
primary_consumers: [implementer, test-writer]
---

# Error Taxonomy: mdlinkcheck

> Primary consumers: implementer, test-writer.
> This is the CLOSED set of failure reasons. Nothing may fail with a reason outside this set.
> Reason codes are stable machine-readable strings. Human messages may vary across versions.

---

## 1. Verdict Classes (Two-Layer Model — DD-022)

**Layer 1 — Link Verdict** (the per-link result the tool reports; drives exit codes):

| Verdict | Applies To | Description | Affects Exit Code |
|---------|------------|-------------|------------------|
| `clean` | all links (internal + external) | The link is valid — the target exists, the anchor (if specified) is present, OR an external URL liveness check returned `alive`. `clean` links are NOT emitted in output. | No |
| `broken` | all links | The link is definitively broken — the target does not exist, is malformed, or definitively returned an error. | Yes → exit 1 |
| `indeterminate` | external URLs | The tool could not determine whether the link is broken (transient server error, rate limiting, timeout). The link may or may not work. | No → does not set exit 1 |

Note: The JSON output `verdict` field contains only `"broken"` or `"indeterminate"` — `clean` (positive) links are not emitted.

**Layer 2 — URL Liveness Outcome** (intermediate value produced only during `--online` HTTP checks; NOT a link verdict):

| Liveness Outcome | Description | Maps to Link Verdict |
|-----------------|-------------|---------------------|
| `alive` | The external URL responded with a success status (2xx after any redirects). | → `clean` |
| `broken` | The external URL is definitively unreachable (DNS failure, 404/410, TLS failure, redirect overflow). | → `broken` |
| `indeterminate` | The liveness check was inconclusive (timeout, 429, 5xx, auth walls). | → `indeterminate` |

`alive` is the URL liveness outcome — it is NOT a fourth link verdict. The positive external URL link verdict is `clean` (derived from liveness `alive` per DD-022). The positive internal link verdict is also `clean`. The term `alive` appears in SS-10 BC documentation to distinguish the HTTP-layer result from the final link verdict.

**I/O errors** (not a link verdict):

| Class | Applies To | Description | Affects Exit Code |
|-------|------------|-------------|------------------|
| I/O error | source files | The source `.md` file could not be read. Not a link verdict — sets exit 2. | Yes → exit 2 (beats exit 1) |

---

## 2. Full Reason Code Catalog

### 2.1 File/Path Errors (broken)

| Code | Category | Severity | Exit Code | Trigger | Human Message Template |
|------|----------|----------|-----------|---------|----------------------|
| `file-not-found` | path | broken | 1 | Resolved destination path does not exist on the filesystem, OR exists but fails exact-case directory-entry comparison | `file not found: <dest>` |
| `target-is-directory` | path | broken | 1 | Destination resolves to a directory AND a fragment is appended to the link (e.g., `[x](docs/#setup)`) — a bare directory link with NO fragment yields `clean` verdict (see BC-2.07.005 v1.1) | `target is a directory: <dest>` |
| `broken-symlink` | path | broken | 1 | Destination is a symlink whose target does not exist (dangling symlink) | `broken symlink: <dest>` |

### 2.2 Anchor Errors (broken)

| Code | Category | Severity | Exit Code | Trigger | Human Message Template |
|------|----------|----------|-----------|---------|----------------------|
| `anchor-not-found` | anchor | broken | 1 | Fragment does not match any entry in the target file's anchor table (headings + HTML id/name) | `anchor not found: #<fragment> in <target>` |
| `undefined-reference-definition` | parsing | broken | 1 | Reference label `[text][label]` or `[label]` has no corresponding `[label]: url` definition in the file | `undefined reference definition: [<label>]` |

### 2.3 URL / External Errors

| Code | Category | Verdict | Exit Code | Trigger | Human Message Template |
|------|----------|---------|-----------|---------|----------------------|
| `malformed-url` | url | broken | 1 | External URL fails WHATWG URL parse (not a valid URL) | `malformed URL: <url>` |
| `http-error` | http | broken | 1 | External URL returned a definitive HTTP error: 404 or 410 (after HEAD + any GET fallback). Note: 400 after GET fallback is `indeterminate` (D-018 ruling), not `broken`. | `HTTP error <status>: <url>` |
| `dns-failure` | http | broken | 1 | External URL hostname could not be resolved by DNS | `DNS resolution failed: <host>` |
| `tls-error` | http | broken | 1 | TLS handshake failed (expired certificate, self-signed, hostname mismatch). `--insecure` is a non-goal (D-011); TLS failures are always broken. | `TLS error: <url>` |
| `too-many-redirects` | http | broken | 1 | Redirect chain exceeded 10 hops | `too many redirects (>10): <url>` |
| `http-timeout` | http | indeterminate | 0 | Request to external URL exceeded 10-second per-URL total timeout | `timeout after 10s: <url>` |
| `http-indeterminate` | http | indeterminate | 0 | External URL returned 429, 5xx, or bot-blocking 403/999 after GET fallback; OR connection was reset before any response; OR target IP is private/link-local (private-ip sub-reason, no outbound request sent, BC-2.10.010); OR https→http protocol downgrade in redirect chain (https-downgrade sub-reason, BC-2.10.007) | `indeterminate (server error or rate limit): <url>` |

### 2.4 I/O Errors (not a link verdict)

| Code | Category | Verdict | Exit Code | Trigger | Human Message Template |
|------|----------|---------|-----------|---------|----------------------|
| `target-unreadable` | io | — (I/O error) | 2 | Source `.md` file cannot be accessed: does not exist (nonexistent PATH argument at startup), OR exists but cannot be read (permission denied, non-UTF-8 content, unexpected read error) | `cannot read file: <path>: <os_error>` |

---

## 3. Closed-Set Invariant

The following invariant MUST hold at all times (NFR-007):

> Every verdict-producing event emits exactly one reason code from the **13-code closed set**:
> `{file-not-found, target-is-directory, broken-symlink, anchor-not-found,
> undefined-reference-definition, malformed-url, http-error, dns-failure,
> tls-error, too-many-redirects, http-timeout, http-indeterminate, target-unreadable}`.

Any code path that emits a verdict with a reason outside this set is a bug.

**Verdict disambiguation for http codes:**
- `dns-failure`: verdict `broken`, exit 1 (DNS failure is definitively broken, not transient)
- `tls-error`: verdict `broken`, exit 1 (TLS failure is definitively broken; `--insecure` is a non-goal per D-011 — no bypass exists)
- `too-many-redirects`: verdict `broken`, exit 1 (redirect chain exceeded the limit — definitively unresolvable)
- `http-timeout`: verdict `indeterminate`, exit 0 (timeout is transient)
- `http-indeterminate`: verdict `indeterminate`, exit 0 (429, 5xx, bot-403, connection-reset, private-ip, https-downgrade are transient or security-policy outcomes)

---

## 3b. Optional `sub_reason` Field (D-016)

Certain `http-indeterminate` findings carry additional diagnostic context in an optional
`sub_reason` string field on the JSON finding object. This field is NOT part of the 13-code
closed `reason` taxonomy — VP-021 does NOT check `sub_reason` values.

| `sub_reason` Value | Condition | Associated BC |
|-------------------|-----------|---------------|
| `https-downgrade` | `https://` redirect chain includes a downgrade to `http://` | BC-2.10.007 |
| `private-ip` | Link target resolves to a private/link-local IP address; no outbound request sent | BC-2.10.010 |

`sub_reason` is additive (pre-1.0 schema) and may be extended in future versions without a
`schema_version` increment. Consumers that do not recognize a `sub_reason` value MUST ignore it.
The `reason` field always contains a value from the closed 13-code set regardless of `sub_reason`.

---

## 4. Reason Code Stability

Reason codes in the `reason` field of JSON output are stable across minor versions. Breaking changes (adding/removing/renaming) require a `schema_version` increment.

Human-readable message strings (emitted in text output) are NOT stable across minor versions — they may improve in wording. Test automation must use reason codes, not message strings.

---

## 5. Non-HTTP Scheme Handling

Non-http(s) schemes (`mailto:`, `ftp:`, `tel:`, `data:`, `vscode:`, protocol-relative `//host`) are **silently skipped** — verdict `clean` — with no reason code emitted. This is not a failure; it is a deliberate scope boundary (DD-009).

---

## 6. Reason Code to Failure Mode Cross-Reference

| Reason Code | Related FM | BC |
|-------------|------------|-----|
| `file-not-found` | FM-006 (case mismatch), FM-007 (NFC/NFD) | BC-2.07.003 |
| `target-is-directory` | — (directory link with fragment is definitively broken) | BC-2.07.005 |
| `broken-symlink` | — | BC-2.01.006 |
| `anchor-not-found` | FM-001 (slug), FM-002 (counter), FM-010 (ignore-target) | BC-2.06.*, BC-2.08.002 |
| `undefined-reference-definition` | — (reference-definition parsing failure; FM-004 is code-span extraction — different failure mode) | BC-2.03.003 |
| `malformed-url` | — | BC-2.09.001, BC-2.07.007 |
| `http-error` | FM-008 (5xx misclassified) | BC-2.10.002 |
| `dns-failure` | — (DNS resolution failed; classified as broken not indeterminate per DD-004) | BC-2.10.005 |
| `tls-error` | — (TLS handshake failed; always broken per D-011; no --insecure override) | BC-2.10.006 |
| `too-many-redirects` | — (redirect chain exceeded 10 hops; definitively unresolvable) | BC-2.10.007 |
| `http-timeout` | — | BC-2.10.003 |
| `http-indeterminate` | FM-008 (5xx/429 transient); also covers connection-reset, private-ip (BC-2.10.010), https-downgrade (BC-2.10.007) | BC-2.10.002 |
| `target-unreadable` | — (see §6.1 note on conflation) | BC-2.02.003, BC-2.01.009 |

### 6.1 target-unreadable Conflation Note (F-032)

`target-unreadable` covers three distinct conditions: (a) **does not exist** — a PATH argument supplied on the command line does not exist at startup (I/O error; fix: correct the path); (b) **permission denied** — the file exists but the process lacks read permission (environmental; fix: check CI permissions); (c) **invalid UTF-8 content** — the file exists and is readable but contains non-UTF-8 bytes (content defect; fix: re-encode the file).

These are **deliberately conflated into one reason code** for v1.0. Rationale:
- Both prevent the tool from processing the file
- Both produce exit 2 (I/O error precedence)
- Both route to the `errors` array in JSON output (not `results`)
- The user's immediate remedy ("file cannot be scanned") is the same in both cases
- The OS error string in the `message` field provides enough context to distinguish them
- A future version (v2.0) with a `schema_version` increment may split into `target-unreadable` (permission) and `invalid-utf8` (encoding)

**NFR-007 note:** The closed taxonomy remains 13 codes. Splitting would add additional codes and require a `schema_version` increment, which is deferred to v2.0. The three-condition conflation was established in v1.6 (spec-lint GATE-58 CLOSED-WORLD remediation; phantom code retired per D-117, citations corrected to `target-unreadable`).
