#!/usr/bin/env bash
# test_primitives.sh — runner for spec_lint_primitives unit tests (G3 guard)
# ============================================================================
# Called from run-selftests.sh as the G3 pre-flight structural guard before
# the main 55-case selftest suite. Runs test_spec_lint_primitives.py and
# asserts exit 0.
#
# These primitive tests are SEPARATE from the run-selftests.sh test count:
# they do not increment TESTS_RUN or TESTS_WITH_CLEAN_PASS, and do not affect
# EXPECTED_TEST_COUNT (which counts checker selftests, not primitive unit tests).
#
# Stage: WS-3b Stage 1 (BI-040)
# Exit: 0 if all primitive tests pass
#       2 if the runner itself fails (file not found) or tests fail
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PRIMITIVE_TEST="$SCRIPT_DIR/test_spec_lint_primitives.py"

if [[ ! -f "$PRIMITIVE_TEST" ]]; then
    echo "STRUCTURAL GUARD FAILED: primitive test file not found: $PRIMITIVE_TEST" >&2
    exit 2
fi

if ! python3 "$PRIMITIVE_TEST"; then
    echo "G3 primitive tests FAILED — see output above" >&2
    exit 2
fi
exit 0
