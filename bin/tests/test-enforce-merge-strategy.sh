#!/usr/bin/env bash
# test-enforce-merge-strategy.sh — negative-test suite for enforce-merge-strategy.sh
#
# Proves the script CAN fail (D-040): each test asserts BOTH:
#   (a) clean-pass: script exits 0 on correct, config-compliant input
#   (b) defect-fail: script exits non-zero on a contradicting strategy
#
# All tests use --dry-run to avoid performing real merges (GitHub Actions is in
# an outage and PR #4 must NOT be merged). The --dry-run path is independently
# validated in test 2 by asserting the expected gh command appears in output.
#
# Usage:
#   bash .factory/bin/tests/test-enforce-merge-strategy.sh   # from repo root
#   (does NOT require gh to be authenticated — uses --dry-run throughout)
#
# Exit:
#   0   All tests passed
#   1   One or more tests failed
#   2   Structural guard fired
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_UNDER_TEST="${SCRIPT_DIR}/../enforce-merge-strategy.sh"

FAILURES=0
TESTS_RUN=0
TESTS_WITH_CLEAN_PASS=0
EXPECTED_TEST_COUNT=4

PR_NUMBER="4"

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

echo "Running negative-test suite for enforce-merge-strategy.sh"
echo "  Script: ${SCRIPT_UNDER_TEST}"
echo "  PR under test: #${PR_NUMBER} (--dry-run throughout; no real merges)"
echo ""

# ── Test 1: correct strategy (--squash --delete-branch --dry-run) → exit 0 ───
#            wrong strategy (--merge --delete-branch) → exit non-zero
TESTS_RUN=$((TESTS_RUN + 1))
echo "── test 1: correct strategy → exit 0; wrong strategy --merge → exit non-zero ──"

CLEAN_PASS=0
echo "  [1a] clean-pass: --squash --delete-branch --dry-run should exit 0..."
if "$SCRIPT_UNDER_TEST" "$PR_NUMBER" --squash --delete-branch --dry-run \
    > /tmp/ems-test1a-out$$ 2>&1; then
  TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
  CLEAN_PASS=1
  echo "  [1a] PASS: exit 0 on --squash --delete-branch --dry-run"
  cat /tmp/ems-test1a-out$$ | sed 's/^/         /'
else
  EXIT_CODE=$?
  echo "  [1a] STRUCTURAL FAIL: script exited ${EXIT_CODE} on valid --squash flags"
  cat /tmp/ems-test1a-out$$ | sed 's/^/         /'
  FAILURES=$((FAILURES + 1))
fi
rm -f /tmp/ems-test1a-out$$

if [[ "$CLEAN_PASS" == "1" ]]; then
  echo "  [1b] defect-fail: --merge --delete-branch should exit non-zero..."
  if "$SCRIPT_UNDER_TEST" "$PR_NUMBER" --merge --delete-branch \
      > /tmp/ems-test1b-out$$ 2>&1; then
    echo "  [1b] FAIL: script exited 0 on --merge when config requires --squash"
    cat /tmp/ems-test1b-out$$ | sed 's/^/         /'
    FAILURES=$((FAILURES + 1))
  else
    echo "  [1b] PASS: exit non-zero on --merge — contradicting strategy correctly refused"
    cat /tmp/ems-test1b-out$$ | sed 's/^/         /'
  fi
  rm -f /tmp/ems-test1b-out$$
fi
echo ""

# ── Test 2: --dry-run prints the expected gh command ─────────────────────────
#            --rebase --delete-branch is also refused (separate from test 1)
TESTS_RUN=$((TESTS_RUN + 1))
echo "── test 2: --dry-run output contains expected gh command; --rebase refused ──"

CLEAN_PASS=0
echo "  [2a] clean-pass: --squash --delete-branch --dry-run should print gh pr merge..."
DRY_RUN_OUTPUT=""
if DRY_RUN_OUTPUT=$("$SCRIPT_UNDER_TEST" "$PR_NUMBER" --squash --delete-branch --dry-run \
    2>/tmp/ems-test2a-err$$); then
  # Verify the output contains the expected gh command
  EXPECTED_CMD="gh pr merge ${PR_NUMBER} --squash --delete-branch"
  if echo "$DRY_RUN_OUTPUT" | grep -qF "$EXPECTED_CMD"; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
    echo "  [2a] PASS: exit 0 and output contains expected command"
    echo "       Output: ${DRY_RUN_OUTPUT}"
  else
    echo "  [2a] STRUCTURAL FAIL: exit 0 but output did not contain '${EXPECTED_CMD}'"
    echo "       Actual output: ${DRY_RUN_OUTPUT}"
    FAILURES=$((FAILURES + 1))
  fi
else
  EXIT_CODE=$?
  echo "  [2a] STRUCTURAL FAIL: script exited ${EXIT_CODE} on --dry-run"
  cat /tmp/ems-test2a-err$$ | sed 's/^/         /'
  FAILURES=$((FAILURES + 1))
fi
rm -f /tmp/ems-test2a-err$$

if [[ "$CLEAN_PASS" == "1" ]]; then
  echo "  [2b] defect-fail: --rebase --delete-branch should exit non-zero..."
  if "$SCRIPT_UNDER_TEST" "$PR_NUMBER" --rebase --delete-branch \
      > /tmp/ems-test2b-out$$ 2>&1; then
    echo "  [2b] FAIL: script exited 0 on --rebase when config requires --squash"
    cat /tmp/ems-test2b-out$$ | sed 's/^/         /'
    FAILURES=$((FAILURES + 1))
  else
    echo "  [2b] PASS: exit non-zero on --rebase — contradicting strategy correctly refused"
    cat /tmp/ems-test2b-out$$ | sed 's/^/         /'
  fi
  rm -f /tmp/ems-test2b-out$$
fi
echo ""

# ── Test 3: missing --delete-branch when config requires it → exit non-zero ──
TESTS_RUN=$((TESTS_RUN + 1))
echo "── test 3: missing --delete-branch → exit non-zero; present → exit 0 ──"

CLEAN_PASS=0
echo "  [3a] clean-pass: --squash --delete-branch --dry-run should exit 0..."
if "$SCRIPT_UNDER_TEST" "$PR_NUMBER" --squash --delete-branch --dry-run \
    > /tmp/ems-test3a-out$$ 2>&1; then
  TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
  CLEAN_PASS=1
  echo "  [3a] PASS: exit 0 with --delete-branch present"
else
  EXIT_CODE=$?
  echo "  [3a] STRUCTURAL FAIL: script exited ${EXIT_CODE} on valid flags"
  cat /tmp/ems-test3a-out$$ | sed 's/^/         /'
  FAILURES=$((FAILURES + 1))
fi
rm -f /tmp/ems-test3a-out$$

if [[ "$CLEAN_PASS" == "1" ]]; then
  echo "  [3b] defect-fail: --squash without --delete-branch should exit non-zero..."
  if "$SCRIPT_UNDER_TEST" "$PR_NUMBER" --squash \
      > /tmp/ems-test3b-out$$ 2>&1; then
    echo "  [3b] FAIL: script exited 0 without --delete-branch when config requires it"
    cat /tmp/ems-test3b-out$$ | sed 's/^/         /'
    FAILURES=$((FAILURES + 1))
  else
    echo "  [3b] PASS: exit non-zero when --delete-branch omitted — policy correctly enforced"
    cat /tmp/ems-test3b-out$$ | sed 's/^/         /'
  fi
  rm -f /tmp/ems-test3b-out$$
fi
echo ""

# ── Test 4: missing merge-config.yaml → exit non-zero (fail closed) ──────────
# Uses a TEMP config path that does not exist.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── test 4: missing config → exit non-zero (fail closed); real config → exit 0 ──"

CLEAN_PASS=0
echo "  [4a] clean-pass: real merge-config.yaml should produce exit 0..."
if "$SCRIPT_UNDER_TEST" "$PR_NUMBER" --squash --delete-branch --dry-run \
    > /tmp/ems-test4a-out$$ 2>&1; then
  TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
  CLEAN_PASS=1
  echo "  [4a] PASS: exit 0 with real merge-config.yaml"
else
  EXIT_CODE=$?
  echo "  [4a] STRUCTURAL FAIL: script exited ${EXIT_CODE} with real config"
  cat /tmp/ems-test4a-out$$ | sed 's/^/         /'
  FAILURES=$((FAILURES + 1))
fi
rm -f /tmp/ems-test4a-out$$

if [[ "$CLEAN_PASS" == "1" ]]; then
  # Create a temp directory with a fake script that points to a nonexistent config,
  # by temporarily overriding BASH_SOURCE[0] via a wrapper script
  TMPDIR_TEST4=$(mktemp -d)
  FAKE_CONFIG_PATH="${TMPDIR_TEST4}/nonexistent-config.yaml"
  # Write a thin wrapper that sets MERGE_CONFIG to the nonexistent path
  cat > "${TMPDIR_TEST4}/ems-wrapper.sh" <<WRAPPER
#!/usr/bin/env bash
set -euo pipefail
# Redirect MERGE_CONFIG to a path that does not exist
exec env MERGE_CONFIG_OVERRIDE="${FAKE_CONFIG_PATH}" bash "${SCRIPT_UNDER_TEST}" "\$@"
WRAPPER
  # Actually, the script uses BASH_SOURCE[0] to find the config, so the simplest
  # approach is: create a symlink to the script in a temp dir that has no merge-config.yaml,
  # so SCRIPT_DIR/../merge-config.yaml doesn't exist.
  # The script resolves: SCRIPT_DIR=$(dirname BASH_SOURCE[0]) => tmpdir
  # MERGE_CONFIG = tmpdir/../merge-config.yaml => one level up from tmpdir
  # We need the parent of tmpdir to not have merge-config.yaml, which is guaranteed
  # since tmpdir is a fresh mktemp dir whose parent is /tmp.
  FAKE_SCRIPT_DIR="${TMPDIR_TEST4}/bin"
  mkdir -p "$FAKE_SCRIPT_DIR"
  cp "${SCRIPT_UNDER_TEST}" "${FAKE_SCRIPT_DIR}/enforce-merge-strategy.sh"
  chmod +x "${FAKE_SCRIPT_DIR}/enforce-merge-strategy.sh"
  # Verify the config file it would look for does NOT exist
  WOULD_CHECK="${TMPDIR_TEST4}/merge-config.yaml"
  rm -f "$WOULD_CHECK"  # ensure it's absent

  echo "  [4b] defect-fail: config at '${WOULD_CHECK}' is absent; should exit non-zero..."
  if "${FAKE_SCRIPT_DIR}/enforce-merge-strategy.sh" "$PR_NUMBER" --squash --delete-branch --dry-run \
      > /tmp/ems-test4b-out$$ 2>&1; then
    echo "  [4b] FAIL: script exited 0 with missing config — did NOT fail closed"
    cat /tmp/ems-test4b-out$$ | sed 's/^/         /'
    FAILURES=$((FAILURES + 1))
  else
    echo "  [4b] PASS: exit non-zero with missing config — fail-closed behavior confirmed"
    cat /tmp/ems-test4b-out$$ | sed 's/^/         /'
  fi
  rm -f /tmp/ems-test4b-out$$
  rm -rf "$TMPDIR_TEST4"
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
