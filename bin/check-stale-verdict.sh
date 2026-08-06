#!/usr/bin/env bash
# check-stale-verdict.sh — refuse to merge a SHA that was never reviewed
#
# A review verdict covers a specific commit. If new commits land after the
# review, the verdict is stale and must not be used to authorize a merge.
#
# Usage:
#   check-stale-verdict.sh <pr-number> <covered-sha>
#
# Arguments:
#   <pr-number>   GitHub PR number (e.g. 4)
#   <covered-sha> Full 40-character SHA that the review covered
#
# Exit:
#   0   Covered SHA exactly matches the PR's current HEAD — verdict is FRESH
#   1   SHA mismatch, API failure, missing args, or any other error (FAIL CLOSED)
#
# Governance:
#   D-039: no bypass flags (--force, --skip, allowlists) are permitted.
#   D-040: negative tests must prove this script CAN fail (see tests/ directory).
#
# Design — FAIL CLOSED:
#   Any error (gh not authenticated, PR not found, unexpected API response)
#   causes exit 1. The script never passes on ambiguity.
set -euo pipefail

# ── Argument validation ──────────────────────────────────────────────────────
if [[ $# -ne 2 ]]; then
  echo "ERROR: wrong number of arguments (got $#, expected 2)" >&2
  echo "Usage: $(basename "$0") <pr-number> <covered-sha>" >&2
  exit 1
fi

PR_NUMBER="$1"
COVERED_SHA="$2"

# Validate PR number is a positive integer
if [[ ! "$PR_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "ERROR: <pr-number> must be a positive integer, got: '${PR_NUMBER}'" >&2
  exit 1
fi

# Validate covered SHA is a full 40-char lowercase hex string
if [[ ! "$COVERED_SHA" =~ ^[0-9a-f]{40}$ ]]; then
  echo "ERROR: <covered-sha> must be a full 40-character lowercase hex SHA" >&2
  echo "  Got: '${COVERED_SHA}' (${#COVERED_SHA} chars)" >&2
  exit 1
fi

# ── Fetch live HEAD — fail closed on any error ───────────────────────────────
LIVE_HEAD=""
GH_STDERR=""

# Capture both stdout and stderr; treat any non-zero gh exit as a hard failure
if ! LIVE_HEAD=$(gh pr view "$PR_NUMBER" --json headRefOid -q .headRefOid 2>/tmp/check-stale-gh-err$$); then
  GH_STDERR=$(cat /tmp/check-stale-gh-err$$ 2>/dev/null || true)
  rm -f /tmp/check-stale-gh-err$$
  echo "ERROR: gh failed while fetching PR #${PR_NUMBER} HEAD SHA" >&2
  echo "  This may mean: gh is not authenticated, the PR does not exist, or a network error." >&2
  if [[ -n "$GH_STDERR" ]]; then
    echo "  gh error output: ${GH_STDERR}" >&2
  fi
  echo "FAIL CLOSED: cannot verify verdict freshness without the live HEAD SHA." >&2
  exit 1
fi
rm -f /tmp/check-stale-gh-err$$

# Strip any trailing whitespace/newlines that gh might produce
LIVE_HEAD="${LIVE_HEAD//[$'\t\r\n ']}"

# Validate that gh returned a 40-char SHA (guards against empty string, error text, etc.)
if [[ ! "$LIVE_HEAD" =~ ^[0-9a-f]{40}$ ]]; then
  echo "ERROR: gh returned an unexpected value for PR #${PR_NUMBER} HEAD" >&2
  echo "  Expected a 40-character hex SHA; got: '${LIVE_HEAD}'" >&2
  echo "FAIL CLOSED: cannot verify verdict freshness with a malformed SHA." >&2
  exit 1
fi

# ── Compare SHAs ─────────────────────────────────────────────────────────────
if [[ "$LIVE_HEAD" != "$COVERED_SHA" ]]; then
  echo "ERROR: verdict is STALE — the review did not cover the current HEAD" >&2
  echo "  Covered SHA (reviewed): ${COVERED_SHA}" >&2
  echo "  Live HEAD  (current):   ${LIVE_HEAD}" >&2
  echo "" >&2
  echo "Action required: re-run the PR review against HEAD ${LIVE_HEAD} before merging." >&2
  exit 1
fi

echo "OK: verdict is FRESH — covered SHA matches live HEAD"
echo "  PR #${PR_NUMBER}: ${LIVE_HEAD}"
exit 0
