#!/usr/bin/env bash
# run-selftests.sh — negative-test suite for all 8 spec-lint checkers
#
# Every test uses an ISOLATED temp tree (never the real spec tree) and
# asserts BOTH:
#   (a) clean-pass: checker exits 0 on the clean fixture tree
#   (b) defect-fail: checker exits non-zero after injecting the defect
#
# This two-step pattern makes vacuous tests STRUCTURALLY IMPOSSIBLE:
# a test cannot satisfy (a) unless the clean tree is genuinely clean,
# and cannot satisfy (b) unless the injected defect is actually detected.
#
# Usage:
#   bash scripts/spec-lint/selftest/run-selftests.sh   # from repo root
#
# Exit: 0 if all tests pass (clean-pass + defect-fail for every test)
#       1 if any test fails
#       2 if a structural guard fires (pre-flight or post-test invariant)
set -uo pipefail

REPO="$(cd "$(dirname "$0")/../../.." && pwd)"
LINT_DIR="$REPO/scripts/spec-lint"
FIXTURE_DIR="$LINT_DIR/selftest/fixtures"

EXPECTED_TEST_COUNT=11
FAILURES=0
TESTS_RUN=0
TESTS_WITH_CLEAN_PASS=0

# Temp-dir registry for cleanup on early exit
TEMP_DIRS=()
cleanup_all() {
    local d
    for d in "${TEMP_DIRS[@]+"${TEMP_DIRS[@]}"}"; do
        rm -rf "$d" 2>/dev/null || true
    done
}
trap cleanup_all EXIT INT TERM

# ── Pre-flight structural guard ────────────────────────────────────────────
# Every checker must have an active REPO= assignment referencing
# SPEC_LINT_REPO_OVERRIDE, or isolated-tree tests are impossible to write —
# vacuous tests reappear the moment one checker loses override support.
echo "Pre-flight structural guard: checking SPEC_LINT_REPO_OVERRIDE in all checkers..."
CHECKER_COUNT=0
for checker in check-adr-consistency check-counts check-ec-injectivity \
               check-holdout-boundary check-id-resolution check-index-integrity \
               check-placeholders check-title-sync; do
    CHECKER_COUNT=$((CHECKER_COUNT + 1))
    # Require an active (non-comment) REPO= assignment referencing SPEC_LINT_REPO_OVERRIDE
    if ! grep -qE "^REPO[[:space:]]*=.*SPEC_LINT_REPO_OVERRIDE" "$LINT_DIR/$checker.py" 2>/dev/null; then
        echo ""
        echo "STRUCTURAL GUARD FAILED: $checker.py lacks SPEC_LINT_REPO_OVERRIDE support"
        echo "  Add the standard REPO= line so tests can use isolated temp trees."
        echo "  Pattern: REPO = Path(os.environ.get(\"SPEC_LINT_REPO_OVERRIDE\", \"\")).resolve() if ..."
        exit 2
    fi
done
echo "Pre-flight guard passed: all $CHECKER_COUNT checkers support SPEC_LINT_REPO_OVERRIDE"
echo ""

# ── Pre-flight guard 2: no hardcoded suppression allowlists ───────────────
# Checkers must not contain allowlists, skip-lists, or deferral sets that
# silently suppress real findings. The same Phase-2-deferral defect caught in
# P4-021 (check-index-integrity) re-emerged in check-ec-injectivity; this
# guard closes the class structurally. Suppression-pattern keywords below are
# chosen to match common names for these constructs (ALLOWLIST, DEFERRAL,
# SKIP_LIST, KNOWN_COLLISIONS, etc.) when used as variable assignments.
echo "Pre-flight structural guard: checking for hardcoded suppression allowlists in all checkers..."
SUPPRESSION_PATTERN='(ALLOWLIST|_DEFERRAL|SKIP_LIST|SKIP_SET|KNOWN_COLLISIONS|KNOWN_VIOLATIONS|KNOWN_ISSUES|WHITELIST|SUPPRESS_SET)[[:space:]]*[=:]'
for checker in check-adr-consistency check-counts check-ec-injectivity \
               check-holdout-boundary check-id-resolution check-index-integrity \
               check-placeholders check-title-sync; do
    if grep -qE "$SUPPRESSION_PATTERN" "$LINT_DIR/$checker.py" 2>/dev/null; then
        echo ""
        echo "STRUCTURAL GUARD FAILED: $checker.py contains a hardcoded suppression allowlist"
        echo "  Checkers must not silently suppress real findings via allowlists, skip-lists,"
        echo "  deferral sets, or known-issues collections — fix the spec, not the checker."
        echo "  Remove any variable matching: ALLOWLIST | _DEFERRAL | SKIP_LIST | SKIP_SET |"
        echo "    KNOWN_COLLISIONS | KNOWN_VIOLATIONS | KNOWN_ISSUES | WHITELIST | SUPPRESS_SET"
        exit 2
    fi
done
echo "Pre-flight guard passed: no suppression allowlists found in any checker"
echo ""

# ── Helper: make_temp ──────────────────────────────────────────────────────
make_temp() {
    local d
    d=$(mktemp -d)
    TEMP_DIRS+=("$d")
    echo "$d"
}

# ── Test 1: check-id-resolution — unregistered EC reference ───────────────
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 1: check-id-resolution: unregistered EC-999 reference ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/prd-supplements"
# Register EC-001 so test 1b is specific to the T-17 violation (not unregistered EC)
printf '| TV-001 | EC-001 | `a.md` | clean | 0 | clean | no-reason |\n' \
    > "$T/.factory/specs/prd-supplements/test-vectors.md"

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-id-resolution.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean tree (only test-vectors.md stub present)"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    cp "$FIXTURE_DIR/bad-ec-unregistered.md" "$T/.factory/specs/SELFTEST-bad-ec.md"
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-id-resolution.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch unregistered EC-999)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; unregistered EC-999 correctly detected)"
    fi
fi
rm -rf "$T"

# ── Test 1b: check-id-resolution — out-of-range trap reference ────────────
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 1b: check-id-resolution: out-of-range T-17 trap reference ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/prd-supplements"
printf '| TV-001 | EC-001 | `a.md` | clean | 0 | clean | no-reason |\n' \
    > "$T/.factory/specs/prd-supplements/test-vectors.md"

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-id-resolution.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean tree"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    cp "$FIXTURE_DIR/bad-trap-ref.md" "$T/.factory/specs/SELFTEST-bad-trap-ref.md"
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-id-resolution.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch out-of-range T-17 trap reference)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; out-of-range T-17 correctly detected)"
    fi
fi
rm -rf "$T"

# ── Test 1c: check-id-resolution — unregistered R requirement reference ───
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 1c: check-id-resolution: unregistered R-99 requirement reference ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/prd-supplements"
printf '| TV-001 | EC-001 | `a.md` | clean | 0 | clean | no-reason |\n' \
    > "$T/.factory/specs/prd-supplements/test-vectors.md"

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-id-resolution.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean tree"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    cp "$FIXTURE_DIR/bad-r-ref-unregistered.md" "$T/.factory/specs/SELFTEST-bad-r-ref.md"
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-id-resolution.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch unregistered R-99 requirement reference)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; unregistered R-99 correctly detected)"
    fi
fi
rm -rf "$T"

# ── Test 2: check-counts — BC count mismatch ──────────────────────────────
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 2: check-counts: BC frontmatter count mismatch ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts"
mkdir -p "$T/.factory/specs/prd-supplements"
mkdir -p "$T/.factory/specs/verification-properties"
mkdir -p "$T/.factory/specs/architecture"
mkdir -p "$T/.factory/specs/domain-spec"
mkdir -p "$T/.factory"

# Clean tree: total_bcs: 0, 0 rows, RTM = 0 — all consistent
cat > "$T/.factory/specs/behavioral-contracts/BC-INDEX.md" <<'BCIX'
---
total_bcs: 0
subsystems: 0
---
| BC ID | Title | Priority | File |
|-------|-------|----------|------|
BCIX
touch "$T/.factory/specs/verification-properties/VP-INDEX.md"
touch "$T/.factory/specs/prd-supplements/nfr-catalog.md"
touch "$T/.factory/specs/prd-supplements/test-vectors.md"
touch "$T/.factory/specs/domain-spec/L2-INDEX.md"
touch "$T/.factory/specs/domain-spec/decisions.md"
touch "$T/.factory/specs/architecture/verification-coverage-matrix.md"
touch "$T/.factory/specs/architecture/ARCH-INDEX.md"
touch "$T/.factory/specs/module-criticality.md"
cat > "$T/.factory/specs/prd.md" <<'PRDSTUB'
---
---
## 7. Requirements Traceability Matrix

PRDSTUB
cat > "$T/.factory/policies.yaml" <<'POLSTUB'
policies: []
POLSTUB

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-counts.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean tree (total_bcs: 0, 0 rows)"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: change total_bcs to 99 (mismatch with 0 actual rows)
    cat > "$T/.factory/specs/behavioral-contracts/BC-INDEX.md" <<'BCIX_BAD'
---
total_bcs: 99
subsystems: 1
---
| BC ID | Title | Priority | File |
|-------|-------|----------|------|
BCIX_BAD
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-counts.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch BC count mismatch)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; BC count mismatch correctly detected)"
    fi
fi
rm -rf "$T"

# ── Test 3: check-placeholders — test-sufficient in VP-NNN column ─────────
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 3: check-placeholders: test-sufficient in VP-NNN col ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean tree (empty ss-01 dir)"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    cp "$FIXTURE_DIR/bad-placeholder-test-sufficient.md" \
        "$T/.factory/specs/behavioral-contracts/ss-01/SELFTEST-placeholder-ts.md"
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch test-sufficient in VP-NNN col)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; test-sufficient in VP-NNN col correctly detected)"
    fi
fi
rm -rf "$T"

# ── Test 4: check-placeholders — live VP-TBD in table row ─────────────────
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 4: check-placeholders: live VP-TBD in table row ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean tree (empty ss-01 dir)"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    cp "$FIXTURE_DIR/bad-live-vp-tbd.md" \
        "$T/.factory/specs/behavioral-contracts/ss-01/SELFTEST-vp-tbd.md"
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch VP-TBD in live table row)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; VP-TBD in live table row correctly detected)"
    fi
fi
rm -rf "$T"

# ── Test 5: check-adr-consistency — wrong exit code semantics ─────────────
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 5: check-adr-consistency: exit 2 for broken-link outcome ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/architecture/decisions"
mkdir -p "$T/.factory/specs/prd-supplements"
# Minimal error-taxonomy.md: must have section "## 2." with at least one reason code
cat > "$T/.factory/specs/prd-supplements/error-taxonomy.md" <<'TAXSTUB'
## 2. Error Catalog

| `file-not-found` | File not found |
| `connection-timeout` | Connection timed out |
| `dns-failure` | DNS lookup failed |
| `tls-error` | TLS handshake failed |
TAXSTUB

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-adr-consistency.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean tree (empty decisions dir, valid taxonomy)"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    cp "$FIXTURE_DIR/bad-adr-exit-code.md" \
        "$T/.factory/specs/architecture/decisions/ADR-SELFTEST-bad-exit.md"
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-adr-consistency.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch exit 2 for broken-link outcome)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; exit 2 for broken link correctly detected)"
    fi
fi
rm -rf "$T"

# ── Test 6: check-ec-injectivity — EC description collision (2-column) ────
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 6: check-ec-injectivity: 2-column EC description collision ──"
T=$(make_temp)
INJECT_BC_DIR="$T/.factory/specs/behavioral-contracts/ss-01"
mkdir -p "$INJECT_BC_DIR"
mkdir -p "$T/.factory/specs/prd-supplements"
# Register EC-001 in test-vectors.md so the checker recognizes it
printf '| TV-001 | EC-001 | `a.md` | clean | 0 | clean | no-reason |\n' \
    > "$T/.factory/specs/prd-supplements/test-vectors.md"
# ONE BC with EC-001: no collision possible
cat > "$INJECT_BC_DIR/BC-SELFTEST-001.md" <<'BC1'
---
bc_id: BC-SELFTEST-001
---
## Edge Cases
| ID | Description |
|----|-------------|
| EC-001 | Symlink target outside root directory traversal boundary |
BC1

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-ec-injectivity.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean tree (single BC with EC-001)"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Second BC with same EC-001 but completely disjoint description (zero token overlap)
    cat > "$INJECT_BC_DIR/BC-SELFTEST-002.md" <<'BC2'
---
bc_id: BC-SELFTEST-002
---
## Edge Cases
| ID | Description |
|----|-------------|
| EC-001 | Binary garbage injected into stdin while TLS handshake pending |
BC2
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-ec-injectivity.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch 2-column EC description collision)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; EC-001 description collision correctly detected)"
    fi
fi
rm -rf "$T"

# ── Test 7: check-holdout-boundary — concrete holdout scenario leaked ──────
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 7: check-holdout-boundary: leaked holdout EC-079 concrete scenario ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs"
# Minimal prd.md with holdout pool declaration (needed by parse_active_holdout_ec_ids)
cat > "$T/.factory/specs/prd.md" <<'PRDSTUB'
---
---
Holdout vectors **(EC-079, EC-093, EC-094, EC-141, EC-147, EC-148, EC-151)**
PRDSTUB

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-holdout-boundary.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean tree (prd.md with holdout decl, no BC files)"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"
    cp "$FIXTURE_DIR/bad-holdout-leak.md" \
        "$T/.factory/specs/behavioral-contracts/ss-01/SELFTEST-bad-holdout.md"
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-holdout-boundary.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch concrete holdout EC-079 in visible artifact)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; leaked holdout scenario correctly detected)"
    fi
fi
rm -rf "$T"

# ── Test 8: check-index-integrity — unlisted BC file ──────────────────────
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 8: check-index-integrity: unlisted BC file ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"
mkdir -p "$T/.factory/specs/verification-properties"
mkdir -p "$T/.factory/specs/architecture/decisions"
mkdir -p "$T/.factory/specs/domain-spec"

# Clean tree: all required index files exist, BC-INDEX has 0 entries, no BC files on disk
cat > "$T/.factory/specs/behavioral-contracts/BC-INDEX.md" <<'BCIX'
---
total_bcs: 0
subsystems: 0
---
| BC ID | Title | Priority | File |
|-------|-------|----------|------|
BCIX
touch "$T/.factory/specs/verification-properties/VP-INDEX.md"
cat > "$T/.factory/specs/architecture/ARCH-INDEX.md" <<'ARCHIX'
---
---
ARCHIX
touch "$T/.factory/specs/domain-spec/L2-INDEX.md"

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-index-integrity.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean tree (consistent empty index files)"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Inject a BC file that exists on disk but is NOT listed in BC-INDEX
    cp "$FIXTURE_DIR/bad-unlisted-bc.md" \
        "$T/.factory/specs/behavioral-contracts/ss-01/BC-2.01.999.md"
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-index-integrity.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch unlisted BC file)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; unlisted BC file correctly detected)"
    fi
fi
rm -rf "$T"

# ── Test 9: check-title-sync — H1 title mismatch ──────────────────────────
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 9: check-title-sync: BC-INDEX title vs H1 mismatch ──"
T=$(make_temp)
TITLE_BC_DIR="$T/.factory/specs/behavioral-contracts/ss-01"
mkdir -p "$TITLE_BC_DIR"

cat > "$T/.factory/specs/behavioral-contracts/BC-INDEX.md" <<'BCINDEX'
---
total_bcs: 1
subsystems: 1
---
| BC ID | Title | Priority | File |
|-------|-------|----------|------|
| BC-2.01.001 | Correct Title In Index | P0 | [ss-01/BC-2.01.001.md](ss-01/BC-2.01.001.md) |
BCINDEX

# Clean tree: BC file H1 MATCHES BC-INDEX title
cat > "$TITLE_BC_DIR/BC-2.01.001.md" <<'BCFILE_CLEAN'
---
bc_id: BC-2.01.001
title: "Correct Title In Index"
lifecycle_status: active
introduced: v0.0.0
modified: []
deprecated: null
---

# BC-2.01.001: Correct Title In Index

## Description

Title intentionally matches BC-INDEX for the clean-pass assertion.
BCFILE_CLEAN

mkdir -p "$T/.factory/specs"
cat > "$T/.factory/specs/prd.md" <<'PRDFILE'
---
---
## 2. Behavioral Contracts

### 2.1 File Discovery

| BC-2.01.001 | Correct Title In Index | P0 |
PRDFILE

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-title-sync.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean tree (BC H1 matches index title)"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Overwrite BC file with a WRONG H1 (different from BC-INDEX title)
    cat > "$TITLE_BC_DIR/BC-2.01.001.md" <<'BCFILE_BAD'
---
bc_id: BC-2.01.001
title: "Selftest BC"
lifecycle_status: active
introduced: v0.0.0
modified: []
deprecated: null
---

# BC-2.01.001: Wrong Title That Differs From Index

## Description

This title intentionally mismatches BC-INDEX to trigger check-title-sync.
BCFILE_BAD
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-title-sync.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch H1 vs BC-INDEX title mismatch)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; H1 title mismatch correctly detected)"
    fi
fi
rm -rf "$T"

# ── Post-test structural guards ────────────────────────────────────────────
echo ""
if [ "$TESTS_RUN" -ne "$EXPECTED_TEST_COUNT" ]; then
    echo "STRUCTURAL GUARD FAILED: expected $EXPECTED_TEST_COUNT tests, ran $TESTS_RUN"
    echo "  Update EXPECTED_TEST_COUNT when adding or removing tests."
    exit 2
fi

if [ "$TESTS_WITH_CLEAN_PASS" -ne "$TESTS_RUN" ]; then
    echo "STRUCTURAL GUARD FAILED: only $TESTS_WITH_CLEAN_PASS/$TESTS_RUN tests had a clean-pass assertion"
    echo "  Every test must assert the checker exits 0 on the clean tree BEFORE injecting the defect."
    echo "  A test without a clean-pass assertion is structurally vacuous."
    exit 2
fi

# ── Summary ────────────────────────────────────────────────────────────────
if [ "$FAILURES" -gt 0 ]; then
    echo "Selftest FAILED: $FAILURES/$TESTS_RUN negative tests failed"
    echo "(A failed negative test means the checker silently passed on a known defect,"
    echo " or the clean-pass assertion failed — indicating a polluted fixture tree)"
    exit 1
fi
echo "Selftest passed: $TESTS_RUN/$EXPECTED_TEST_COUNT negative tests verified (each proved clean-pass + defect-fail)"
exit 0
