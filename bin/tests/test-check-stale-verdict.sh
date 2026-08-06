#!/usr/bin/env bash
# test-check-stale-verdict.sh — negative-test suite for check-stale-verdict.sh
#
# Proves the script CAN fail (D-040): each test asserts BOTH:
#   (a) clean-pass: script exits 0 on correct input
#   (b) defect-fail: script exits non-zero on bad input
#
# A test that can only pass is the vacuous-test defect class this project
# actively eliminates. The structural guard at the end enforces every test
# exercised both branches.
#
# Usage:
#   bash .factory/bin/tests/test-check-stale-verdict.sh   # from repo root
#   (requires gh to be authenticated; makes real API calls to PR #4)
#
# Exit:
#   0   All tests passed
#   1   One or more tests failed
#   2   Structural guard fired
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_UNDER_TEST="${SCRIPT_DIR}/../check-stale-verdict.sh"

FAILURES=0
TESTS_RUN=0
TESTS_WITH_CLEAN_PASS=0
EXPECTED_TEST_COUNT=4

# PR 4 live head as of 2026-08-06 (D-043 PR, sha confirmed via gh pr view).
# If this SHA becomes stale (new commits pushed to PR 4), update it here.
PR4_CORRECT_SHA="6503d3baacaa7aef2b9e6fe44f27aadb13d239ae"
PR4_WRONG_SHA="0000000000000000000000000000000000000000"
PR4_NUMBER="4"

# ── Pre-flight: confirm the script exists and is executable ──────────────────
if [[ ! -f "$SCRIPT_UNDER_TEST" ]]; then
  echo "STRUCTURAL GUARD FAILED: script not found at: ${SCRIPT_UNDER_TEST}" >&2
  exit 2
fi
if [[ ! -x "$SCRIPT_UNDER_TEST" ]]; then
  echo "STRUCTURAL GUARD FAILED: script is not executable: ${SCRIPT_UNDER_TEST}" >&2
  echo "  Fix: chmod +x ${SCRIPT_UNDER_TEST}" >&2
  exit 2
fi

# ── Pre-flight: confirm gh is available ──────────────────────────────────────
if ! command -v gh > /dev/null 2>&1; then
  echo "STRUCTURAL GUARD FAILED: 'gh' not found in PATH; cannot run live API tests" >&2
  exit 2
fi

echo "Running negative-test suite for check-stale-verdict.sh"
echo "  Script: ${SCRIPT_UNDER_TEST}"
echo "  PR under test: #${PR4_NUMBER}"
echo ""

# ── Test 1: correct SHA → exit 0 (clean-pass) + wrong SHA → exit non-zero ────
TESTS_RUN=$((TESTS_RUN + 1))
echo "── test 1: SHA match → exit 0; SHA mismatch → exit non-zero ──"

CLEAN_PASS=0
echo "  [1a] clean-pass: correct SHA should exit 0..."
if "$SCRIPT_UNDER_TEST" "$PR4_NUMBER" "$PR4_CORRECT_SHA" > /tmp/csv-test1a-out$$ 2>&1; then
  TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
  CLEAN_PASS=1
  echo "  [1a] PASS: exit 0 on correct SHA"
  cat /tmp/csv-test1a-out$$
else
  EXIT_CODE=$?
  echo "  [1a] STRUCTURAL FAIL: script exited ${EXIT_CODE} on correct SHA (${PR4_CORRECT_SHA})"
  echo "       Output:"
  cat /tmp/csv-test1a-out$$ | sed 's/^/         /'
  FAILURES=$((FAILURES + 1))
fi
rm -f /tmp/csv-test1a-out$$

if [[ "$CLEAN_PASS" == "1" ]]; then
  echo "  [1b] defect-fail: wrong SHA should exit non-zero..."
  if "$SCRIPT_UNDER_TEST" "$PR4_NUMBER" "$PR4_WRONG_SHA" > /tmp/csv-test1b-out$$ 2>&1; then
    echo "  [1b] FAIL: script exited 0 on wrong SHA — did NOT detect stale verdict"
    echo "       Output:"
    cat /tmp/csv-test1b-out$$ | sed 's/^/         /'
    FAILURES=$((FAILURES + 1))
  else
    echo "  [1b] PASS: exit non-zero on wrong SHA — stale verdict correctly detected"
    cat /tmp/csv-test1b-out$$ | sed 's/^/         /'
  fi
  rm -f /tmp/csv-test1b-out$$
fi
echo ""

# ── Test 2: missing arguments → exit non-zero ────────────────────────────────
TESTS_RUN=$((TESTS_RUN + 1))
echo "── test 2: missing args → exit non-zero; correct args → exit 0 ──"

CLEAN_PASS=0
echo "  [2a] clean-pass: two valid arguments should exit 0..."
if "$SCRIPT_UNDER_TEST" "$PR4_NUMBER" "$PR4_CORRECT_SHA" > /tmp/csv-test2a-out$$ 2>&1; then
  TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
  CLEAN_PASS=1
  echo "  [2a] PASS: exit 0 on two valid arguments"
else
  EXIT_CODE=$?
  echo "  [2a] STRUCTURAL FAIL: script exited ${EXIT_CODE} on valid arguments"
  cat /tmp/csv-test2a-out$$ | sed 's/^/         /'
  FAILURES=$((FAILURES + 1))
fi
rm -f /tmp/csv-test2a-out$$

if [[ "$CLEAN_PASS" == "1" ]]; then
  echo "  [2b] defect-fail: zero arguments should exit non-zero..."
  if "$SCRIPT_UNDER_TEST" > /tmp/csv-test2b-out$$ 2>&1; then
    echo "  [2b] FAIL: script exited 0 with no arguments"
    cat /tmp/csv-test2b-out$$ | sed 's/^/         /'
    FAILURES=$((FAILURES + 1))
  else
    echo "  [2b] PASS: exit non-zero with zero arguments (missing args correctly rejected)"
    cat /tmp/csv-test2b-out$$ | sed 's/^/         /'
  fi
  rm -f /tmp/csv-test2b-out$$
fi
echo ""

# ── Test 3: malformed SHA (not 40 hex chars) → exit non-zero ─────────────────
TESTS_RUN=$((TESTS_RUN + 1))
echo "── test 3: malformed SHA → exit non-zero; full 40-char SHA → exit 0 ──"

CLEAN_PASS=0
echo "  [3a] clean-pass: full 40-char SHA should exit 0..."
if "$SCRIPT_UNDER_TEST" "$PR4_NUMBER" "$PR4_CORRECT_SHA" > /tmp/csv-test3a-out$$ 2>&1; then
  TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
  CLEAN_PASS=1
  echo "  [3a] PASS: exit 0 on full 40-char SHA"
else
  EXIT_CODE=$?
  echo "  [3a] STRUCTURAL FAIL: script exited ${EXIT_CODE} on full 40-char SHA"
  cat /tmp/csv-test3a-out$$ | sed 's/^/         /'
  FAILURES=$((FAILURES + 1))
fi
rm -f /tmp/csv-test3a-out$$

if [[ "$CLEAN_PASS" == "1" ]]; then
  echo "  [3b] defect-fail: short/malformed SHA 'abc123' should exit non-zero..."
  if "$SCRIPT_UNDER_TEST" "$PR4_NUMBER" "abc123" > /tmp/csv-test3b-out$$ 2>&1; then
    echo "  [3b] FAIL: script exited 0 on malformed SHA 'abc123'"
    cat /tmp/csv-test3b-out$$ | sed 's/^/         /'
    FAILURES=$((FAILURES + 1))
  else
    echo "  [3b] PASS: exit non-zero on malformed SHA 'abc123'"
    cat /tmp/csv-test3b-out$$ | sed 's/^/         /'
  fi
  rm -f /tmp/csv-test3b-out$$
fi
echo ""

# ── Test 4: nonexistent PR → exit non-zero (fail closed) ─────────────────────
# Uses PR #99999 which does not exist; gh should return an error.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── test 4: nonexistent PR → exit non-zero (fail closed); real PR → exit 0 ──"

CLEAN_PASS=0
echo "  [4a] clean-pass: real PR #${PR4_NUMBER} should exit 0..."
if "$SCRIPT_UNDER_TEST" "$PR4_NUMBER" "$PR4_CORRECT_SHA" > /tmp/csv-test4a-out$$ 2>&1; then
  TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
  CLEAN_PASS=1
  echo "  [4a] PASS: exit 0 on real PR"
else
  EXIT_CODE=$?
  echo "  [4a] STRUCTURAL FAIL: script exited ${EXIT_CODE} on real PR"
  cat /tmp/csv-test4a-out$$ | sed 's/^/         /'
  FAILURES=$((FAILURES + 1))
fi
rm -f /tmp/csv-test4a-out$$

if [[ "$CLEAN_PASS" == "1" ]]; then
  echo "  [4b] defect-fail: nonexistent PR #99999 should exit non-zero..."
  if "$SCRIPT_UNDER_TEST" "99999" "$PR4_CORRECT_SHA" > /tmp/csv-test4b-out$$ 2>&1; then
    echo "  [4b] FAIL: script exited 0 on nonexistent PR — did NOT fail closed"
    cat /tmp/csv-test4b-out$$ | sed 's/^/         /'
    FAILURES=$((FAILURES + 1))
  else
    echo "  [4b] PASS: exit non-zero on nonexistent PR — fail-closed behavior confirmed"
    cat /tmp/csv-test4b-out$$ | sed 's/^/         /'
  fi
  rm -f /tmp/csv-test4b-out$$
fi
echo ""

# ── Post-test structural guards ───────────────────────────────────────────────
if [[ "$TESTS_RUN" -ne "$EXPECTED_TEST_COUNT" ]]; then
  echo "STRUCTURAL GUARD FAILED: expected ${EXPECTED_TEST_COUNT} tests, ran ${TESTS_RUN}" >&2
  echo "  Update EXPECTED_TEST_COUNT when adding or removing tests." >&2
  exit 2
fi

if [[ "$TESTS_WITH_CLEAN_PASS" -ne "$TESTS_RUN" ]]; then
  echo "STRUCTURAL GUARD FAILED: only ${TESTS_WITH_CLEAN_PASS}/${TESTS_RUN} tests had a clean-pass assertion" >&2
  echo "  Every test must assert exit 0 on good input BEFORE testing the failure case." >&2
  echo "  A test without a clean-pass assertion is structurally vacuous." >&2
  exit 2
fi

# ── Summary ──────────────────────────────────────────────────────────────────
if [[ "$FAILURES" -gt 0 ]]; then
  echo "FAILED: ${FAILURES}/${TESTS_RUN} tests failed"
  echo "(A failed negative test means the script silently passed on a known bad input,"
  echo " or the clean-pass assertion failed — indicating the script is broken on good input)"
  exit 1
fi
echo "PASSED: ${TESTS_RUN}/${EXPECTED_TEST_COUNT} tests verified (each proved clean-pass + defect-fail)"
exit 0
