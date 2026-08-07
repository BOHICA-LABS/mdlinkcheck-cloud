#!/usr/bin/env bash
# run-selftests.sh — negative-test suite for all 8 spec-lint checkers
#
# Every test uses an ISOLATED temp tree (never the real spec tree) and
# asserts BOTH:
#   (a) clean-pass: checker exits 0 on the clean fixture tree
#   (b) defect-fail: checker exits non-zero after injecting the defect
#
# This two-step pattern makes a vacuous test case structurally impossible:
# a test cannot satisfy (a) unless the clean tree is genuinely clean,
# and cannot satisfy (b) unless the injected defect is actually detected.
# Note: this property applies per test case. It does not by itself guarantee
# coverage of every checker branch; missing branches are vacuous by omission.
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

EXPECTED_TEST_COUNT=27
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

# ── Guard patterns (single canonical definitions) ─────────────────────────
# Each pattern is defined ONCE here. Both the pre-flight checks and the guard
# selftests (G1, G2) use these variables — there is no second copy of either
# pattern anywhere in this file. This means any mutation to OVERRIDE_PATTERN
# or SUPPRESSION_PATTERN will make both the pre-flight guard AND G1/G2 flip.
OVERRIDE_PATTERN='^REPO[[:space:]]*=.*SPEC_LINT_REPO_OVERRIDE'
SUPPRESSION_PATTERN='(ALLOWLIST|_DEFERRAL|SKIP_LIST|SKIP_SET|KNOWN_COLLISIONS|KNOWN_VIOLATIONS|KNOWN_ISSUES|WHITELIST|SUPPRESS_SET)[[:space:]]*[=:]'

run_override_guard() {
    # Verify every check-*.py in $1 has an active SPEC_LINT_REPO_OVERRIDE assignment.
    # D-057: prints runtime count of files scanned; fails if 0 files found.
    # Returns 0 = all clear, 2 = guard fired (missing support, or no files found).
    local dir="$1"
    local count=0
    for f in "$dir"/check-*.py; do
        [[ -f "$f" ]] || continue
        count=$((count + 1))
        if ! grep -qE "$OVERRIDE_PATTERN" "$f" 2>/dev/null; then
            echo "STRUCTURAL GUARD FAILED: $(basename "$f") lacks SPEC_LINT_REPO_OVERRIDE support"
            echo "  Add the standard REPO= line so tests can use isolated temp trees."
            echo "  Pattern: REPO = Path(os.environ.get(\"SPEC_LINT_REPO_OVERRIDE\", \"\")).resolve() if ..."
            return 2
        fi
    done
    if [[ "$count" -eq 0 ]]; then
        echo "STRUCTURAL GUARD FAILED: no check-*.py files found in $dir — nothing scanned"
        return 2
    fi
    echo "Pre-flight guard passed: $count checkers support SPEC_LINT_REPO_OVERRIDE"
    return 0
}

run_suppression_guard() {
    # Verify no check-*.py in $1 contains a hardcoded suppression allowlist construct.
    # D-057: prints runtime count of files scanned; fails if 0 files found.
    # Returns 0 = all clear, 2 = guard fired (suppression found, or no files found).
    local dir="$1"
    local count=0
    for f in "$dir"/check-*.py; do
        [[ -f "$f" ]] || continue
        count=$((count + 1))
        if grep -qE "$SUPPRESSION_PATTERN" "$f" 2>/dev/null; then
            echo "STRUCTURAL GUARD FAILED: $(basename "$f") contains a hardcoded suppression allowlist"
            echo "  Checkers must not silently suppress real findings via allowlists, skip-lists,"
            echo "  deferral sets, or known-issues collections — fix the spec, not the checker."
            echo "  Remove any variable matching: $SUPPRESSION_PATTERN"
            return 2
        fi
    done
    if [[ "$count" -eq 0 ]]; then
        echo "STRUCTURAL GUARD FAILED: no check-*.py files found in $dir — nothing scanned"
        return 2
    fi
    echo "Pre-flight guard passed: $count checkers scanned, 0 suppression constructs found"
    return 0
}

# ── Pre-flight structural guard 1: SPEC_LINT_REPO_OVERRIDE ────────────────
# Every checker must have an active REPO= assignment referencing
# SPEC_LINT_REPO_OVERRIDE, or isolated-tree tests are impossible to write —
# vacuous tests reappear the moment one checker loses override support.
echo "Pre-flight structural guard: checking SPEC_LINT_REPO_OVERRIDE in all checkers..."
if ! run_override_guard "$LINT_DIR"; then
    exit 2
fi
echo ""

# ── Pre-flight guard 2: no hardcoded suppression allowlists ───────────────
# Checkers must not contain allowlists, skip-lists, or deferral sets that
# silently suppress real findings. The same Phase-2-deferral defect caught in
# P4-021 (check-index-integrity) re-emerged in check-ec-injectivity; this
# guard closes the class structurally. See SUPPRESSION_PATTERN definition above.
#
# NOTE: Guard ordering is load-bearing (F-15). run_override_guard uses
# "if ! grep ..." so a grep read-error fails CLOSED (guard fires). By contrast,
# run_suppression_guard uses "if grep ..." so a read-error is treated as "no
# match" and fails OPEN. However, run_override_guard runs first: an unreadable
# checker causes guard 1 to fire (exit 2) before guard 2 ever sees the file.
# Guard 2's fail-open is therefore unreachable today, but the ordering must not
# be changed without also fixing guard 2's error-handling.
echo "Pre-flight structural guard: checking for hardcoded suppression allowlists in all checkers..."
if ! run_suppression_guard "$LINT_DIR"; then
    exit 2
fi
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
    # Defect: change total_bcs to 99 (mismatch with 0 actual rows).
    # subsystems stays 0 (matching actual) so ONLY the total_bcs check fires —
    # prevents over-determination via the subsystems check.
    cat > "$T/.factory/specs/behavioral-contracts/BC-INDEX.md" <<'BCIX_BAD'
---
total_bcs: 99
subsystems: 0
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
    # Overwrite BC file with a WRONG H1 (different from BC-INDEX title).
    # Also update prd.md §2 to match the new H1 so ONLY the BC-INDEX check fires —
    # prevents over-determination via the PRD §2 title check.
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
    # prd.md updated to match the bad H1 so the PRD check does NOT fire
    cat > "$T/.factory/specs/prd.md" <<'PRDFILE_BAD'
---
---
## 2. Behavioral Contracts

### 2.1 File Discovery

| BC-2.01.001 | Wrong Title That Differs From Index | P0 |
PRDFILE_BAD
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-title-sync.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch H1 vs BC-INDEX title mismatch)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; H1 title mismatch correctly detected)"
    fi
fi
rm -rf "$T"

# ── Test 10: check-index-integrity — HS entry with no wave-scenarios file ──
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 10: check-index-integrity: HS entry with no wave-scenarios file ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"
mkdir -p "$T/.factory/specs/verification-properties"
mkdir -p "$T/.factory/specs/architecture/decisions"
mkdir -p "$T/.factory/specs/domain-spec"
mkdir -p "$T/.factory/holdout-scenarios/wave-scenarios"

# Clean tree: BC-INDEX, VP-INDEX, ARCH-INDEX, L2-INDEX all consistent;
# HS-INDEX has one active entry (HS-001→EC-156) with a matching wave-scenarios file.
# The ## Authored Scenarios heading + separator row scope the parser correctly.
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
cat > "$T/.factory/holdout-scenarios/HS-INDEX.md" <<'HSIX'
## Authored Scenarios

| HS ID | EC ID | Title | Notes | BCs | Status |
|-------|-------|-------|-------|-----|--------|
| HS-001 | EC-156 | Selftest scenario | Notes | BC-2.01.001 | active |
HSIX
touch "$T/.factory/holdout-scenarios/wave-scenarios/EC-156-selftest-scenario.md"

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-index-integrity.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean tree (HS-INDEX and wave-scenarios in sync)"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: add HS-002 → EC-999 with no corresponding wave-scenarios file
    printf '| HS-002 | EC-999 | Orphan entry with no wave-scenarios file | Notes | BC-2.01.001 | active |\n' \
        >> "$T/.factory/holdout-scenarios/HS-INDEX.md"
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-index-integrity.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch HS entry with no wave-scenarios file)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; orphan HS entry (HS-002→EC-999) correctly detected)"
    fi
fi
rm -rf "$T"

# ── Test 10b: check-index-integrity — wave-scenarios file with no HS entry ──
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 10b: check-index-integrity: wave-scenarios file with no HS-INDEX entry ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"
mkdir -p "$T/.factory/specs/verification-properties"
mkdir -p "$T/.factory/specs/architecture/decisions"
mkdir -p "$T/.factory/specs/domain-spec"
mkdir -p "$T/.factory/holdout-scenarios/wave-scenarios"

# Clean tree: HS-INDEX with HS-001→EC-156, matching wave-scenarios file
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
cat > "$T/.factory/holdout-scenarios/HS-INDEX.md" <<'HSIX'
## Authored Scenarios

| HS ID | EC ID | Title | Notes | BCs | Status |
|-------|-------|-------|-------|-----|--------|
| HS-001 | EC-156 | Selftest scenario | Notes | BC-2.01.001 | active |
HSIX
touch "$T/.factory/holdout-scenarios/wave-scenarios/EC-156-selftest-scenario.md"

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-index-integrity.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean tree (HS-INDEX and wave-scenarios in sync)"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: add wave-scenarios file with no corresponding HS-INDEX entry
    touch "$T/.factory/holdout-scenarios/wave-scenarios/EC-998-orphan-no-hs-entry.md"
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-index-integrity.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch wave-scenarios file with no HS entry)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; orphan wave-scenarios file EC-998 correctly detected)"
    fi
fi
rm -rf "$T"

# ── Test 10c: check-index-integrity — duplicate HS-NNN ID in HS-INDEX ──────
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 10c: check-index-integrity: duplicate HS-NNN ID in HS-INDEX ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"
mkdir -p "$T/.factory/specs/verification-properties"
mkdir -p "$T/.factory/specs/architecture/decisions"
mkdir -p "$T/.factory/specs/domain-spec"
mkdir -p "$T/.factory/holdout-scenarios/wave-scenarios"

# Clean tree: HS-INDEX with unique HS-001→EC-156
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
cat > "$T/.factory/holdout-scenarios/HS-INDEX.md" <<'HSIX'
## Authored Scenarios

| HS ID | EC ID | Title | Notes | BCs | Status |
|-------|-------|-------|-------|-----|--------|
| HS-001 | EC-156 | Selftest scenario | Notes | BC-2.01.001 | active |
HSIX
touch "$T/.factory/holdout-scenarios/wave-scenarios/EC-156-selftest-scenario.md"

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-index-integrity.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean tree (unique HS-INDEX IDs)"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: append duplicate HS-001 entry with SAME EC — only the duplicate-ID check fires,
    # not the reverse check (EC-156 file still exists and HS-001 still maps to it).
    printf '| HS-001 | EC-156 | Duplicate HS-001 entry (same EC) | Notes | BC-2.01.001 | active |\n' \
        >> "$T/.factory/holdout-scenarios/HS-INDEX.md"
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-index-integrity.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch duplicate HS-001 ID (same-EC defect))"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; duplicate HS-001 ID (same-EC defect) correctly detected)"
    fi
fi
rm -rf "$T"

# ── Test 10d: check-index-integrity — malformed EC cell in HS-INDEX ─────────
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 10d: check-index-integrity: HS entry with malformed EC cell ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"
mkdir -p "$T/.factory/specs/verification-properties"
mkdir -p "$T/.factory/specs/architecture/decisions"
mkdir -p "$T/.factory/specs/domain-spec"
mkdir -p "$T/.factory/holdout-scenarios/wave-scenarios"

# Clean tree: HS-INDEX with valid HS-001→EC-156, matching wave-scenarios file
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
cat > "$T/.factory/holdout-scenarios/HS-INDEX.md" <<'HSIX'
## Authored Scenarios

| HS ID | EC ID | Title | Notes | BCs | Status |
|-------|-------|-------|-------|-----|--------|
| HS-001 | EC-156 | Valid entry | Notes | BC-2.01.001 | active |
HSIX
touch "$T/.factory/holdout-scenarios/wave-scenarios/EC-156-selftest-scenario.md"

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-index-integrity.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean tree (valid HS-INDEX)"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: append HS-002 with partial/malformed EC cell (~~EC-169~~ without matching HS ~~)
    printf '| HS-002 | ~~EC-169~~ | Partial strikethrough — malformed row | Notes | BC-2.01.001 | active |\n' \
        >> "$T/.factory/holdout-scenarios/HS-INDEX.md"
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-index-integrity.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch malformed EC cell in HS-002)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; malformed EC cell in HS-002 correctly detected)"
    fi
fi
rm -rf "$T"

# ── Guard test G1: run_override_guard fires on a checker lacking SPEC_LINT_REPO_OVERRIDE ──
# D-040 applies recursively: run_override_guard must itself be proven to fire.
# This test calls the REAL function (defined above). OVERRIDE_PATTERN has one
# canonical definition; any mutation to it will flip this test. There is no
# duplicate pattern copy here — that was the original B-7 defect class.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── guard selftest G1: SPEC_LINT_REPO_OVERRIDE pre-flight guard fires ──"
T=$(make_temp)

# Clean pass: run_override_guard returns 0 for a valid checker stub
cat > "$T/check-stub.py" <<'GOODSTUB'
REPO = Path(os.environ.get("SPEC_LINT_REPO_OVERRIDE", "")).resolve() if os.environ.get("SPEC_LINT_REPO_OVERRIDE") else Path(__file__).resolve().parent.parent.parent
GOODSTUB

CLEAN_PASS=0
if run_override_guard "$T" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: guard fired on a valid SPEC_LINT_REPO_OVERRIDE assignment"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: replace stub with a checker lacking SPEC_LINT_REPO_OVERRIDE entirely
    cat > "$T/check-stub.py" <<'BADSTUB'
REPO = Path("/hardcoded/path/without/override")
BADSTUB
    if run_override_guard "$T" > /dev/null 2>&1; then
        echo "  FAIL (guard did NOT detect missing SPEC_LINT_REPO_OVERRIDE in bad checker)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; guard correctly detects checker lacking SPEC_LINT_REPO_OVERRIDE)"
    fi
fi
rm -rf "$T"

# ── Guard test G2: run_suppression_guard fires on a checker with KNOWN_COLLISIONS ──
# D-040 applies recursively: run_suppression_guard must itself be proven to fire.
# This test calls the REAL function (defined above). SUPPRESSION_PATTERN has one
# canonical definition; any mutation to it will flip this test. There is no
# duplicate pattern copy here — that was the original B-7 defect class.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── guard selftest G2: suppression-allowlist pre-flight guard fires ──"
T=$(make_temp)

# Clean pass: run_suppression_guard returns 0 for a checker with no suppression allowlists
cat > "$T/check-stub.py" <<'CLEANSTUB'
REPO = Path(os.environ.get("SPEC_LINT_REPO_OVERRIDE", "")).resolve() if os.environ.get("SPEC_LINT_REPO_OVERRIDE") else Path(__file__).resolve().parent.parent.parent
# This checker has no suppression allowlists — all violations are reported
CLEANSTUB

CLEAN_PASS=0
if run_suppression_guard "$T" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: guard fired on a clean checker with no suppression allowlists"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: replace stub with a checker containing KNOWN_COLLISIONS (D-039 violation)
    cat > "$T/check-stub.py" <<'BADSTUB'
KNOWN_COLLISIONS = {"EC-001", "EC-002"}  # hardcoded suppression allowlist
BADSTUB
    if run_suppression_guard "$T" > /dev/null 2>&1; then
        echo "  FAIL (guard did NOT detect KNOWN_COLLISIONS suppression allowlist)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; guard correctly detects KNOWN_COLLISIONS suppression allowlist)"
    fi
fi
rm -rf "$T"

# ── Test 10e: check-index-integrity — near-miss HS ID in HS-INDEX ─────────
# B-10: covers the near-miss capture and violation-emission paths.
# Mutation for emission loop (MUT-3 equivalent): neuter the near-miss violation
# emission loop → checker exits 0 on defect tree → 10e FAILS.
# Note on MUT-1 (neuter near-miss capture): the accounting invariant detects the
# unaccounted row (hs_rows_seen=2, classified=1) and exits 1. 10e continues to
# PASS — the accounting invariant is a stronger backstop that subsumes MUT-1.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 10e: check-index-integrity: near-miss HS ID in HS-INDEX ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"
mkdir -p "$T/.factory/specs/verification-properties"
mkdir -p "$T/.factory/specs/architecture/decisions"
mkdir -p "$T/.factory/specs/domain-spec"
mkdir -p "$T/.factory/holdout-scenarios/wave-scenarios"

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
cat > "$T/.factory/holdout-scenarios/HS-INDEX.md" <<'HSIX'
## Authored Scenarios

| HS ID | EC ID | Title | Notes | BCs | Status |
|-------|-------|-------|-------|-----|--------|
| HS-001 | EC-156 | Selftest scenario | Notes | BC-2.01.001 | active |
HSIX
touch "$T/.factory/holdout-scenarios/wave-scenarios/EC-156-selftest-scenario.md"

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-index-integrity.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean tree (valid HS-INDEX)"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: append a near-miss row (lowercase 'hs-002' — non-canonical ID)
    # No EC-157 wave-scenarios file, so only the near-miss violation fires.
    printf '| hs-002 | EC-157 | Near-miss: lowercase hs prefix | Notes | BC-2.01.001 | active |\n' \
        >> "$T/.factory/holdout-scenarios/HS-INDEX.md"
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-index-integrity.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch near-miss ID 'hs-002')"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; near-miss ID 'hs-002' correctly detected)"
    fi
fi
rm -rf "$T"

# ── Test 10f: check-index-integrity — accounting invariant (unaccounted rows) ─
# B-10 / B-9: covers the D-057 accounting invariant.
# The clean tree has one parseable row; the defect replaces HS-INDEX with a row
# that is counted by cell-splitting but matches no parser pattern, so
# hs_rows_seen (1) != hs_canonical (0) + hs_nonconforming (0). Invariant fires.
# Mutation (MUT-2 equivalent): neuter the accounting invariant check → checker
# exits 0 on the defect tree → 10f FAILS.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 10f: check-index-integrity: accounting invariant (unaccounted rows) ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"
mkdir -p "$T/.factory/specs/verification-properties"
mkdir -p "$T/.factory/specs/architecture/decisions"
mkdir -p "$T/.factory/specs/domain-spec"
mkdir -p "$T/.factory/holdout-scenarios/wave-scenarios"

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
cat > "$T/.factory/holdout-scenarios/HS-INDEX.md" <<'HSIX'
## Authored Scenarios

| HS ID | EC ID | Title | Notes | BCs | Status |
|-------|-------|-------|-------|-----|--------|
| HS-001 | EC-156 | Selftest scenario | Notes | BC-2.01.001 | active |
HSIX
touch "$T/.factory/holdout-scenarios/wave-scenarios/EC-156-selftest-scenario.md"

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-index-integrity.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean tree (valid HS-INDEX)"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: replace HS-INDEX with a row that cell-splitting counts as a data row
    # but no parser pattern matches (first cell 'GARBAGE-001' is not HS-like at all).
    # Remove EC-156 file so the reverse check does not fire independently.
    rm "$T/.factory/holdout-scenarios/wave-scenarios/EC-156-selftest-scenario.md"
    cat > "$T/.factory/holdout-scenarios/HS-INDEX.md" <<'HSIX_BAD'
## Authored Scenarios

| HS ID | EC ID | Title | Notes | BCs | Status |
|-------|-------|-------|-------|-----|--------|
| GARBAGE-001 | EC-156 | Row counted by cell-split but matches no HS pattern | none | none | active |
HSIX_BAD
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-index-integrity.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch unaccounted data row via accounting invariant)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; unaccounted data row correctly detected by accounting invariant)"
    fi
fi
rm -rf "$T"

# ── Test 10g: check-index-integrity — leading-whitespace bypass (V-9 scenario) ─
# B-9 / B-10: covers the raw.strip() whitespace normalisation.
# Reproduces the reviewer's exact V-9 scenario: one flush-left HS row +
# two rows with a single leading space pointing at nonexistent EC files.
# Without stripping, the indented rows are silently skipped and the checker
# exits 0. With stripping they are parsed and the forward check fires.
# Mutation: change 'line = raw.strip()' to 'line = raw' →
#   indented rows not counted by hs_rows_seen either (same anchor) →
#   invariant holds, forward check not run → checker exits 0 → 10g FAILS.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 10g: check-index-integrity: leading-whitespace bypass (B-9 / V-9) ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"
mkdir -p "$T/.factory/specs/verification-properties"
mkdir -p "$T/.factory/specs/architecture/decisions"
mkdir -p "$T/.factory/specs/domain-spec"
mkdir -p "$T/.factory/holdout-scenarios/wave-scenarios"

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
cat > "$T/.factory/holdout-scenarios/HS-INDEX.md" <<'HSIX'
## Authored Scenarios

| HS ID | EC ID | Title | Notes | BCs | Status |
|-------|-------|-------|-------|-----|--------|
| HS-001 | EC-156 | Flush-left valid row | Notes | BC-2.01.001 | active |
HSIX
touch "$T/.factory/holdout-scenarios/wave-scenarios/EC-156-selftest-scenario.md"

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-index-integrity.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean tree (valid flush-left HS-INDEX)"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: append two rows with a SINGLE LEADING SPACE pointing at EC files
    # that do NOT exist in wave-scenarios/. With stripping, these are parsed and
    # the forward check reports violations. Without stripping, they are silently
    # skipped and the checker exits 0 (the V-9 false-pass reproduced here).
    printf ' | HS-004 | EC-165 | One leading space — nonexistent EC | Notes | BC | active |\n' \
        >> "$T/.factory/holdout-scenarios/HS-INDEX.md"
    printf ' | HS-005 | EC-166 | One leading space — nonexistent EC | Notes | BC | active |\n' \
        >> "$T/.factory/holdout-scenarios/HS-INDEX.md"
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-index-integrity.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — leading-space rows bypassed parser — V-9 false-pass not fixed)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; leading-space HS rows correctly parsed and forward-checked)"
    fi
fi
rm -rf "$T"

# ── Guard test G3: both guards fail closed on empty checker directory ─────────
# B-10 / D-057: covers the count-eq-0 fail-closed branches in both guards.
# Mutation (MUT-4 equivalent): delete both 'if [[ $count -eq 0 ]]' blocks →
# guards return 0 on empty dir → G3 FAILS.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── guard selftest G3: guards fail closed when no check-*.py files found ──"
T=$(make_temp)

# Clean pass: both guards return 0 for a valid checker directory
cat > "$T/check-stub.py" <<'GOODSTUB'
REPO = Path(os.environ.get("SPEC_LINT_REPO_OVERRIDE", "")).resolve() if os.environ.get("SPEC_LINT_REPO_OVERRIDE") else Path(__file__).resolve().parent.parent.parent
GOODSTUB

CLEAN_PASS=0
if run_override_guard "$T" > /dev/null 2>&1 && run_suppression_guard "$T" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: a guard fired on a valid checker dir (clean pass failed)"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: remove all check-*.py files (empty directory)
    rm "$T/check-stub.py"
    OG_RETURNED_ZERO=0
    SG_RETURNED_ZERO=0
    run_override_guard    "$T" > /dev/null 2>&1 && OG_RETURNED_ZERO=1
    run_suppression_guard "$T" > /dev/null 2>&1 && SG_RETURNED_ZERO=1
    if [ "$OG_RETURNED_ZERO" = "1" ] || [ "$SG_RETURNED_ZERO" = "1" ]; then
        [ "$OG_RETURNED_ZERO" = "1" ] && echo "  FAIL (run_override_guard returned 0 on empty dir — did not fail closed)"
        [ "$SG_RETURNED_ZERO" = "1" ] && echo "  FAIL (run_suppression_guard returned 0 on empty dir — did not fail closed)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; both guards fail closed on empty checker directory)"
    fi
fi
rm -rf "$T"

# ── Test A1: check-index-integrity — data row placed ABOVE the |---| separator ─
# B-11: regression introduced by the F-12 scoping fix at 031ca5b.
# A row like "| HS-042 | EC-999 | …" placed before the |---| separator was
# silently skipped (found_separator=False gate). After the B-11 fix, HS-like
# pre-separator rows fall through the modified filter-5 and are classified by
# the canonical parser; the forward check then catches EC-999.
#
# Mutation-flip: revert filter 5 to `if not found_separator: continue`
# (unconditional pre-separator skip). A1 exits 0 again — forward check never
# reached for the pre-separator row. A2a/A2b are unaffected (they appear after
# the separator where found_separator is already True).
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest A1: check-index-integrity: data row above |---| separator (B-11 regression) ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"
mkdir -p "$T/.factory/specs/verification-properties"
mkdir -p "$T/.factory/specs/architecture/decisions"
mkdir -p "$T/.factory/specs/domain-spec"
mkdir -p "$T/.factory/holdout-scenarios/wave-scenarios"

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
cat > "$T/.factory/holdout-scenarios/HS-INDEX.md" <<'HSIX'
## Authored Scenarios

| HS ID | EC ID | Title | Notes | BCs | Status |
|-------|-------|-------|-------|-----|--------|
| HS-001 | EC-156 | Selftest scenario | Notes | BC-2.01.001 | active |
HSIX
touch "$T/.factory/holdout-scenarios/wave-scenarios/EC-156-selftest-scenario.md"

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-index-integrity.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean tree (valid HS-INDEX)"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: rewrite HS-INDEX with HS-042 placed BEFORE the |---| separator.
    # No wave-scenarios/EC-999-*.md file — the forward check must fire even
    # though the row appears before the header separator.
    cat > "$T/.factory/holdout-scenarios/HS-INDEX.md" <<'HSIX_DEFECT'
## Authored Scenarios

| HS ID | EC ID | Title | Notes | BCs | Status |
| HS-042 | EC-999 | Bogus row above separator — no wave-scenarios file | Notes | BC | active |
|-------|-------|-------|-------|-----|--------|
| HS-001 | EC-156 | Selftest scenario | Notes | BC-2.01.001 | active |
HSIX_DEFECT
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-index-integrity.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch HS-042 placed above separator)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; pre-separator HS-042→EC-999 correctly detected)"
    fi
fi
rm -rf "$T"

# ── Test A2a: check-index-integrity — empty first cell bypasses separator check ─
# B-11: `set("") <= set("-: ")` is True (empty set is subset of everything), so
# a row with a blank ID cell was misclassified as a separator row and silently
# skipped. After the B-11 fix the `first_cell and` guard prevents the empty set
# vacuous-truth bypass; the row falls through, is counted by hs_rows_seen, matches
# no parser pattern, and the accounting invariant fires.
#
# Mutation-flip for A2a (independent of A2b): replace `first_cell and all(…)` with
# `(not first_cell) or (first_cell and all(…))` — empty cells are re-classified as
# separators. A2a exits 0 again. A2b is unaffected (its first cell is non-empty).
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest A2a: check-index-integrity: empty first cell bypasses separator check (B-11) ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"
mkdir -p "$T/.factory/specs/verification-properties"
mkdir -p "$T/.factory/specs/architecture/decisions"
mkdir -p "$T/.factory/specs/domain-spec"
mkdir -p "$T/.factory/holdout-scenarios/wave-scenarios"

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
cat > "$T/.factory/holdout-scenarios/HS-INDEX.md" <<'HSIX'
## Authored Scenarios

| HS ID | EC ID | Title | Notes | BCs | Status |
|-------|-------|-------|-------|-----|--------|
| HS-001 | EC-156 | Selftest scenario | Notes | BC-2.01.001 | active |
HSIX
touch "$T/.factory/holdout-scenarios/wave-scenarios/EC-156-selftest-scenario.md"

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-index-integrity.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean tree (valid HS-INDEX)"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: append a row with an EMPTY first cell pointing at EC-999 (no file).
    # The empty first cell must NOT be misclassified as a separator row.
    printf '|  | EC-999 | Empty ID cell | Notes | BC | active |\n' \
        >> "$T/.factory/holdout-scenarios/HS-INDEX.md"
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-index-integrity.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — empty first cell bypassed separator check)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; empty first cell row correctly detected via accounting invariant)"
    fi
fi
rm -rf "$T"

# ── Test A2b: check-index-integrity — dash-only first cell bypasses separator ──
# B-11: `set("-") <= set("-: ")` is True, so a row like "| - | EC-999 | … |"
# (dash-only first cell, real data in other cells) was misclassified as a
# separator row and silently skipped. After the B-11 fix the `all(set(c) <= …)`
# requirement checks ALL non-empty cells, not just the first; "EC-999" fails the
# check so the row falls through, is counted, and the invariant fires.
#
# Mutation-flip for A2b (independent of A2a): revert to first-cell-only check:
# `if first_cell and set(first_cell) <= set("-: ")`. A2b (first_cell="-") exits
# 0 again. A2a is unaffected (first_cell="" is guarded by `first_cell and`).
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest A2b: check-index-integrity: dash-only first cell bypasses separator check (B-11) ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"
mkdir -p "$T/.factory/specs/verification-properties"
mkdir -p "$T/.factory/specs/architecture/decisions"
mkdir -p "$T/.factory/specs/domain-spec"
mkdir -p "$T/.factory/holdout-scenarios/wave-scenarios"

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
cat > "$T/.factory/holdout-scenarios/HS-INDEX.md" <<'HSIX'
## Authored Scenarios

| HS ID | EC ID | Title | Notes | BCs | Status |
|-------|-------|-------|-------|-----|--------|
| HS-001 | EC-156 | Selftest scenario | Notes | BC-2.01.001 | active |
HSIX
touch "$T/.factory/holdout-scenarios/wave-scenarios/EC-156-selftest-scenario.md"

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-index-integrity.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean tree (valid HS-INDEX)"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: append a row with a SINGLE DASH first cell pointing at EC-999.
    # The dash-only first cell with data in other cells must NOT be misclassified
    # as a separator row (the all()-cells check prevents this).
    printf '| - | EC-999 | Dash ID cell | Notes | BC | active |\n' \
        >> "$T/.factory/holdout-scenarios/HS-INDEX.md"
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-index-integrity.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — dash-only first cell bypassed separator check)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; dash-only first cell row correctly detected via accounting invariant)"
    fi
fi
rm -rf "$T"

# ── Test B1: check-index-integrity — h3 subheading silently drops rows (BLOCKING-1) ─
# BLOCKING-1: prior startswith("##") also matched "###" and "####".  Any h3
# subheading inside ## Authored Scenarios set in_authored_scenarios=False,
# causing all subsequent rows to be dropped uncounted before the denominator.
# After the BLOCKING-1 fix, only h1/h2 headings delimit sections; h3+
# subheadings stay in scope with fresh separator tracking per sub-table.
# This encodes Proof A from the D-068 ruling exactly.
#
# Mutation-flip: revert heading detection to startswith("##") (without the
# level <= 2 check). The h3 heading resets in_authored_scenarios=False.
# Rows behind ### Wave 2 are dropped before the counter; the checker exits 0
# on the defect tree → B1 FAILS.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest B1: check-index-integrity: h3 subheading drops rows (BLOCKING-1) ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"
mkdir -p "$T/.factory/specs/verification-properties"
mkdir -p "$T/.factory/specs/architecture/decisions"
mkdir -p "$T/.factory/specs/domain-spec"
mkdir -p "$T/.factory/holdout-scenarios/wave-scenarios"

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
cat > "$T/.factory/holdout-scenarios/HS-INDEX.md" <<'HSIX'
## Authored Scenarios

| HS ID | EC ID | Title | Notes | BCs | Status |
|-------|-------|-------|-------|-----|--------|
| HS-001 | EC-156 | Selftest scenario | Notes | BC-2.01.001 | active |
HSIX
touch "$T/.factory/holdout-scenarios/wave-scenarios/EC-156-selftest-scenario.md"

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-index-integrity.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean tree"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: add ### Wave 2 subheading inside ## Authored Scenarios, then a
    # second table with orphan rows. No EC-999 or EC-998 wave-scenarios files.
    # Without BLOCKING-1 fix: ### Wave 2 resets scope to False; orphan rows are
    # invisible; checker exits 0. With fix: h3 stays in scope; orphan rows are
    # caught.
    cat > "$T/.factory/holdout-scenarios/HS-INDEX.md" <<'HSIX_DEFECT'
## Authored Scenarios

| HS ID | EC ID | Title | Notes | BCs | Status |
|-------|-------|-------|-------|-----|--------|
| HS-001 | EC-156 | Selftest scenario | Notes | BC-2.01.001 | active |

### Wave 2

| HS ID | EC ID | Title | Notes | BCs | Status |
|-------|-------|-------|-------|-----|--------|
| HS-042 | EC-999 | Orphan behind h3 subheading — no wave-scenarios file | Notes | BC | active |
| hs_043 | ~~EC-998~~ | Near-miss ID behind h3 | Notes | BC | active |
HSIX_DEFECT
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-index-integrity.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — h3 subheading hid orphan rows — BLOCKING-1 not fixed)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; orphan rows behind h3 subheading correctly detected)"
    fi
fi
rm -rf "$T"

# ── Test B2: check-index-integrity — bold HS ID above separator (BLOCKING-2) ─
# BLOCKING-2: the prior shape-regex gate (r"^\|\s*(?:~~)?(?:HS-\d+|[Hh][Ss][-_])")
# was a D-039-forbidden allowlist in disguised form: only rows whose first cell
# matched the HS-shape pattern were passed through before the separator; all
# other pre-separator rows (including bold/link/decorated IDs) were dropped
# uncounted. After the BLOCKING-2 fix, all pre-separator rows are buffered; the
# last is discarded positionally as the column header; earlier rows are counted.
# The accounting invariant detects the displaced column header as unclassified.
# This encodes Proof B (C4 probe) from the D-068 ruling exactly.
#
# Mutation-flip: restore the shape-regex gate (re-introduce
# `if not re.match(r"^\|\s*(?:~~)?(?:HS-\d+|[Hh][Ss][-_])", line): continue`
# before the pending_pre_sep.append). The column header row is dropped before
# the buffer; bold **HS-042** is also dropped (** defeats the regex); hs_rows_seen
# reflects only HS-001; invariant holds vacuously → checker exits 0 → B2 FAILS.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest B2: check-index-integrity: bold HS ID above separator (BLOCKING-2) ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"
mkdir -p "$T/.factory/specs/verification-properties"
mkdir -p "$T/.factory/specs/architecture/decisions"
mkdir -p "$T/.factory/specs/domain-spec"
mkdir -p "$T/.factory/holdout-scenarios/wave-scenarios"

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
cat > "$T/.factory/holdout-scenarios/HS-INDEX.md" <<'HSIX'
## Authored Scenarios

| HS ID | EC ID | Title | Notes | BCs | Status |
|-------|-------|-------|-------|-----|--------|
| HS-001 | EC-156 | Selftest scenario | Notes | BC-2.01.001 | active |
HSIX
touch "$T/.factory/holdout-scenarios/wave-scenarios/EC-156-selftest-scenario.md"

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-index-integrity.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean tree"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: insert a bold-decorated HS row ABOVE the separator. No EC-999 file.
    # The bold ** prefix defeats the old shape-regex; with positional buffering
    # the actual column header ("| HS ID |...") becomes a pre-separator row that
    # is counted and unclassified → accounting invariant fires.
    cat > "$T/.factory/holdout-scenarios/HS-INDEX.md" <<'HSIX_DEFECT'
## Authored Scenarios

| HS ID | EC ID | Title | Notes | BCs | Status |
| **HS-042** | EC-999 | Bold-decorated ID above separator — no wave-scenarios file | Notes | BC | active |
|-------|-------|-------|-------|-----|--------|
| HS-001 | EC-156 | Selftest scenario | Notes | BC-2.01.001 | active |
HSIX_DEFECT
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-index-integrity.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — bold HS-042 above separator not detected — BLOCKING-2 not fixed)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; bold HS ID above separator detected via accounting invariant)"
    fi
fi
rm -rf "$T"

# ── Test B3: check-index-integrity — pipeless GFM row counted (MAJOR-1) ─────
# MAJOR-1: GFM allows leading/trailing pipes to be omitted on table rows.
# A pipeless row like "HS-042 | EC-999 | ..." was previously dropped uncounted
# because `not line.startswith("|")` triggered a continue before the denominator.
# After the MAJOR-1 fix, in-scope pipeless lines containing cell delimiters
# increment hs_rows_seen; none of the pipe-anchored classifier patterns match,
# so the accounting invariant fires.
#
# Mutation-flip: remove the MAJOR-1 counting branch (the `hs_rows_seen += 1`
# inside the `if not line.startswith("|"):` block). The pipeless row is not
# counted; hs_rows_seen equals the post-separator pipe row count alone;
# invariant holds → checker exits 0 → B3 FAILS.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest B3: check-index-integrity: pipeless GFM row counted (MAJOR-1) ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"
mkdir -p "$T/.factory/specs/verification-properties"
mkdir -p "$T/.factory/specs/architecture/decisions"
mkdir -p "$T/.factory/specs/domain-spec"
mkdir -p "$T/.factory/holdout-scenarios/wave-scenarios"

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
cat > "$T/.factory/holdout-scenarios/HS-INDEX.md" <<'HSIX'
## Authored Scenarios

| HS ID | EC ID | Title | Notes | BCs | Status |
|-------|-------|-------|-------|-----|--------|
| HS-001 | EC-156 | Selftest scenario | Notes | BC-2.01.001 | active |
HSIX
touch "$T/.factory/holdout-scenarios/wave-scenarios/EC-156-selftest-scenario.md"

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-index-integrity.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean tree"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: append a pipeless row (no leading |) pointing at EC-999. No file.
    # GFM allows omitting leading/trailing pipes. The checker must count this row.
    printf 'HS-042 | EC-999 | Pipeless row — no wave-scenarios file | Notes | BC | active\n' \
        >> "$T/.factory/holdout-scenarios/HS-INDEX.md"
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-index-integrity.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — pipeless row dropped uncounted — MAJOR-1 not fixed)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; pipeless GFM row correctly counted and detected)"
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
