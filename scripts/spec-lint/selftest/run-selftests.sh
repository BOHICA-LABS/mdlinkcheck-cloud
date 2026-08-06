#!/usr/bin/env bash
# run-selftests.sh — negative-test suite for all 8 spec-lint checkers
#
# Each test injects a known-bad fixture into the spec tree, asserts the
# relevant checker exits 1 (FAIL), then removes the fixture. A checker
# that has never been observed failing provides no safety guarantee.
#
# Usage:
#   bash scripts/spec-lint/selftest/run-selftests.sh   # from repo root
#
# Exit: 0 if all negative tests pass (checkers correctly catch injected defects)
#       1 if any negative test fails (checker silently passes on a known defect)
set -uo pipefail

REPO="$(cd "$(dirname "$0")/../../.." && pwd)"
LINT_DIR="$REPO/scripts/spec-lint"
FIXTURE_DIR="$LINT_DIR/selftest/fixtures"
SPECS="$REPO/.factory/specs"
BC_DIR="$SPECS/behavioral-contracts/ss-01"
ADR_DIR="$SPECS/architecture/decisions"

FAILURES=0
TESTS_RUN=0
INJECTED_FILES=()

cleanup() {
    local f
    for f in "${INJECTED_FILES[@]:-}"; do
        rm -f "$f" 2>/dev/null || true
    done
}
trap cleanup EXIT INT TERM

run_test() {
    local name="$1"
    local checker="$2"
    local fixture_src="$3"
    local fixture_dst="$4"
    TESTS_RUN=$((TESTS_RUN + 1))

    cp "$fixture_src" "$fixture_dst"
    INJECTED_FILES+=("$fixture_dst")

    echo "── selftest: $name ──"
    if python3 "$LINT_DIR/$checker.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch the injected defect)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (checker correctly returned non-zero on injected defect)"
    fi

    rm -f "$fixture_dst"
    # Remove from array (bash doesn't have easy array delete, so just let cleanup handle it)
}

# ── 1. check-id-resolution: unregistered EC reference ─────────────────────
run_test "check-id-resolution: unregistered EC-999" \
    "check-id-resolution" \
    "$FIXTURE_DIR/bad-ec-unregistered.md" \
    "$BC_DIR/SELFTEST-bad-ec.md"

# ── 1b. check-id-resolution: out-of-range T reference ─────────────────────
run_test "check-id-resolution: out-of-range T-17 reference" \
    "check-id-resolution" \
    "$FIXTURE_DIR/bad-trap-ref.md" \
    "$BC_DIR/SELFTEST-bad-trap-ref.md"

# ── 2. check-counts: prd.md EC count mismatch ─────────────────────────────
# The prd.md §5b EC count claim is live in the real tree; we verify the
# checker already detects it (it reports "168 declared, 161 actual").
# We confirm the checker exits 1 on the unmodified tree:
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest: check-counts: prd.md §5b EC count mismatch (real-tree) ──"
echo "  NOTE: This selftest relies on known-bad real-tree state."
echo "  It will need replacement with injection fixture when §5b is fixed in Phase 2."
if python3 "$LINT_DIR/check-counts.py" > /dev/null 2>&1; then
    echo "  FAIL (checker returned 0 — did NOT catch EC count mismatch in prd.md §5b)"
    FAILURES=$((FAILURES + 1))
else
    echo "  PASS (checker correctly returns non-zero on EC count mismatch)"
fi

# ── 3. check-placeholders: test-sufficient in VP-NNN column (injected) ──────
run_test "check-placeholders: test-sufficient in VP-NNN col (injected)" \
    "check-placeholders" \
    "$FIXTURE_DIR/bad-placeholder-test-sufficient.md" \
    "$BC_DIR/SELFTEST-bad-placeholder-ts.md"

# ── 4. check-placeholders: injected VP-TBD in a live table row ────────────
run_test "check-placeholders: injected live VP-TBD" \
    "check-placeholders" \
    "$FIXTURE_DIR/bad-live-vp-tbd.md" \
    "$BC_DIR/SELFTEST-bad-vp-tbd.md"

# ── 5. check-adr-consistency: wrong exit code semantics ───────────────────
run_test "check-adr-consistency: exit 2 for broken link" \
    "check-adr-consistency" \
    "$FIXTURE_DIR/bad-adr-exit-code.md" \
    "$ADR_DIR/ADR-SELFTEST-bad-exit.md"

# ── 6. check-ec-injectivity: same EC ID with conflicting verdicts ──────────
# Inject a BC file that uses an EC ID already in the tree with a different verdict
run_test "check-ec-injectivity: EC verdict collision" \
    "check-ec-injectivity" \
    "$FIXTURE_DIR/bad-ec-injectivity.md" \
    "$BC_DIR/SELFTEST-bad-ec-injectivity.md"

# ── 7. check-holdout-boundary: concrete holdout scenario leaked ───────────
run_test "check-holdout-boundary: leaked holdout EC-079 concrete scenario" \
    "check-holdout-boundary" \
    "$FIXTURE_DIR/bad-holdout-leak.md" \
    "$BC_DIR/SELFTEST-bad-holdout.md"

# ── 8. check-index-integrity: phantom BC in index ─────────────────────────
# Inject a real-looking BC file (numeric ID that passes the filename pattern)
# that is NOT listed in BC-INDEX, making it an "unlisted" file.
run_test "check-index-integrity: unlisted BC file" \
    "check-index-integrity" \
    "$FIXTURE_DIR/bad-unlisted-bc.md" \
    "$SPECS/behavioral-contracts/ss-01/BC-2.01.999.md"

# ── Summary ────────────────────────────────────────────────────────────────
echo ""
if [ "$FAILURES" -gt 0 ]; then
    echo "spec-lint selftest FAILED: $FAILURES/$TESTS_RUN negative tests failed"
    echo "(A failed negative test means the checker silently passed on a known defect)"
    exit 1
fi
echo "spec-lint selftest PASSED: all $TESTS_RUN negative tests confirmed checkers can detect defects"
exit 0
