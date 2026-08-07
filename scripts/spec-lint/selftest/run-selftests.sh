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

EXPECTED_TEST_COUNT=52
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
    # Verify every check-*.py in $1, plus the two new generators introduced by this PR
    # (gen-bc-traceability.py and gen-slug-corpus.py), have an active
    # SPEC_LINT_REPO_OVERRIDE assignment. The two generators are listed explicitly
    # rather than using gen-*.py because the pre-existing generators (gen-bc-index.py,
    # gen-ec-registry.py, etc.) predate the isolated-tree testing model and are tracked
    # separately. The two new generators share the same override pattern and must be
    # included so they cannot regress without this guard firing.
    # D-057: prints runtime count of files scanned; fails if 0 files found.
    # Returns 0 = all clear, 2 = guard fired (missing support, or no files found).
    local dir="$1"
    local count=0
    for f in "$dir"/check-*.py "$dir/gen-bc-traceability.py" "$dir/gen-slug-corpus.py"; do
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
    echo "Pre-flight guard passed: $count checkers/generators support SPEC_LINT_REPO_OVERRIDE"
    return 0
}

run_suppression_guard() {
    # Verify no check-*.py in $1, nor the two new generators (gen-bc-traceability.py,
    # gen-slug-corpus.py), contain a hardcoded suppression allowlist construct.
    # Same scoping rationale as run_override_guard: pre-existing generators are tracked
    # separately; the two new generators are explicitly included.
    # D-057: prints runtime count of files scanned; fails if 0 files found.
    # Returns 0 = all clear, 2 = guard fired (suppression found, or no files found).
    local dir="$1"
    local count=0
    for f in "$dir"/check-*.py "$dir/gen-bc-traceability.py" "$dir/gen-slug-corpus.py"; do
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
    echo "Pre-flight guard passed: $count checkers/generators scanned, 0 suppression constructs found"
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

# ── Test 18: check-canonical-facts — binding site divergence ──────────────
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 18: check-canonical-facts: binding site value divergence ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs"

# Clean tree: one fact with one binding whose FLEXIBLE pattern captures the value.
# Using a flexible pattern (not literal canonical) means the defect hits the
# m.group(1) != canonical branch — the specific branch mutation-verify targets.
cat > "$T/.factory/specs/canonical-facts.toml" <<'TOMLCLEAN'
[[fact]]
id              = "FACT-ST18"
description     = "selftest fact — canonical value is selftest-canonical"
canonical_value = "selftest-canonical"
source          = "selftest"

[[binding]]
fact_id = "FACT-ST18"
file    = ".factory/specs/selftest-binding.md"
note    = "selftest binding"
pattern = "canonical value: ([a-z-]+)"
TOMLCLEAN

cat > "$T/.factory/specs/selftest-binding.md" <<'MDCLEAN'
# Selftest Binding File
The canonical value: selftest-canonical
MDCLEAN

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-canonical-facts.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean tree (fact and binding match)"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: overwrite binding file with a DIFFERENT value that the flexible pattern
    # still matches — this forces the m.group(1) != canonical comparison branch to fire.
    # (Using a literal pattern would test "pattern did not match" instead — not the != branch.)
    cat > "$T/.factory/specs/selftest-binding.md" <<'MDBAD'
# Selftest Binding File (defect — wrong value)
The canonical value: wrong-diverging
MDBAD
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-canonical-facts.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch canonical-facts value divergence)"
        FAILURES=$((FAILURES + 1))
    else
        # D-040: assert on specific violation message, not just exit code
        CF_OUTPUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-canonical-facts.py" 2>&1)
        if echo "$CF_OUTPUT" | grep -q "DIVERGE \[FACT-ST18\]"; then
            echo "  PASS (clean-pass confirmed; DIVERGE [FACT-ST18] correctly reported for value mismatch)"
        else
            echo "  FAIL (checker exited non-zero but expected 'DIVERGE [FACT-ST18]' not in output)"
            echo "  Actual output: $CF_OUTPUT"
            FAILURES=$((FAILURES + 1))
        fi
    fi
fi
rm -rf "$T"

# ── Test 19: check-canonical-facts — FACT-7 negative (macOS-only platform matrix) ───────
# BI-035: FACT-7 canonical_value = "macOS". Negative vector: "macOS and Linux"
# (the multi-platform claim D-043 ruled out). Pattern captures content between
# quotes so the != branch fires — not the "pattern did not match" branch.
# Mutation-verify: neutralizing != flips this test to FAIL.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 19: check-canonical-facts: FACT-7 negative — macOS and Linux fails ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs"

cat > "$T/.factory/specs/canonical-facts.toml" <<'TOML19'
[[fact]]
id              = "FACT-7-NEG"
description     = "platform matrix is macOS-only (D-043)"
canonical_value = "macOS"
source          = "selftest"

[[binding]]
fact_id = "FACT-7-NEG"
file    = ".factory/specs/selftest-fact7.md"
note    = "platform matrix declaration"
pattern = 'platform matrix: "(.*?)"'
TOML19

cat > "$T/.factory/specs/selftest-fact7.md" <<'MD19CLEAN'
**Platform Matrix Section**
platform matrix: "macOS"
MD19CLEAN

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-canonical-facts.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean FACT-7 tree"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Negative vector: "macOS and Linux" — the multi-platform claim D-043 ruled out.
    # The flexible pattern captures this, forcing the m.group(1) != canonical branch.
    cat > "$T/.factory/specs/selftest-fact7.md" <<'MD19BAD'
**Platform Matrix Section**
platform matrix: "macOS and Linux"
MD19BAD
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-canonical-facts.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — 'macOS and Linux' should DIVERGE from 'macOS')"
        FAILURES=$((FAILURES + 1))
    else
        CF_OUTPUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-canonical-facts.py" 2>&1)
        if echo "$CF_OUTPUT" | grep -q "DIVERGE \[FACT-7-NEG\]"; then
            echo "  PASS (clean-pass confirmed; DIVERGE [FACT-7-NEG] correctly reported for 'macOS and Linux')"
        else
            echo "  FAIL (checker exited non-zero but expected 'DIVERGE [FACT-7-NEG]' not in output)"
            echo "  Actual output: $CF_OUTPUT"
            FAILURES=$((FAILURES + 1))
        fi
    fi
fi
rm -rf "$T"

# ── Test 20: check-canonical-facts — FACT-8 negative (ASM-004 macOS only) ───────────────
# BI-035: FACT-8 canonical_value = "macOS only". Negative vector: "macOS and Windows"
# (a multi-platform phrasing that could appear in an undisciplined ASM-004 restatement).
# Pattern captures content between quotes so the != branch fires.
# Mutation-verify: neutralizing != flips this test to FAIL.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 20: check-canonical-facts: FACT-8 negative — macOS and Windows fails ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs"

cat > "$T/.factory/specs/canonical-facts.toml" <<'TOML20'
[[fact]]
id              = "FACT-8-NEG"
description     = "ASM-004 platform restatement is macOS only (D-043)"
canonical_value = "macOS only"
source          = "selftest"

[[binding]]
fact_id = "FACT-8-NEG"
file    = ".factory/specs/selftest-fact8.md"
note    = "ASM-004 platform restatement"
pattern = 'platform restatement: "(.*?)"'
TOML20

cat > "$T/.factory/specs/selftest-fact8.md" <<'MD20CLEAN'
ASM-004 details:
platform restatement: "macOS only"
MD20CLEAN

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-canonical-facts.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean FACT-8 tree"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Negative vector: "macOS and Windows" — a spurious multi-platform restatement.
    cat > "$T/.factory/specs/selftest-fact8.md" <<'MD20BAD'
ASM-004 details:
platform restatement: "macOS and Windows"
MD20BAD
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-canonical-facts.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — 'macOS and Windows' should DIVERGE from 'macOS only')"
        FAILURES=$((FAILURES + 1))
    else
        CF_OUTPUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-canonical-facts.py" 2>&1)
        if echo "$CF_OUTPUT" | grep -q "DIVERGE \[FACT-8-NEG\]"; then
            echo "  PASS (clean-pass confirmed; DIVERGE [FACT-8-NEG] correctly reported for 'macOS and Windows')"
        else
            echo "  FAIL (checker exited non-zero but expected 'DIVERGE [FACT-8-NEG]' not in output)"
            echo "  Actual output: $CF_OUTPUT"
            FAILURES=$((FAILURES + 1))
        fi
    fi
fi
rm -rf "$T"

# ── Test 21: check-canonical-facts — FACT-9 negative (DirIndex narrow scope) ───────────
# BI-035: FACT-9 canonical_value = "every extracted link destination".
# Negative vector: "missing-.md file destinations only" — the narrow D-061-rejected reading
# that limits DirIndex to missing-.md targets only, ignoring non-.md and directory links.
# This is the exact claim D-061 ruled out (BROAD scope, all link types).
# Pattern uses flexible quotes-capture so the != branch fires.
# Mutation-verify: neutralizing != flips this test to FAIL.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 21: check-canonical-facts: FACT-9 negative — narrow DirIndex scope fails ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs"

cat > "$T/.factory/specs/canonical-facts.toml" <<'TOML21'
[[fact]]
id              = "FACT-9-NEG"
description     = "DirIndex covers every extracted link destination (D-061 BROAD)"
canonical_value = "every extracted link destination"
source          = "selftest"

[[binding]]
fact_id = "FACT-9-NEG"
file    = ".factory/specs/selftest-fact9.md"
note    = "DirIndex scope declaration"
pattern = 'DirIndex scope: "(.*?)"'
TOML21

cat > "$T/.factory/specs/selftest-fact9.md" <<'MD21CLEAN'
Pass 1.5 builds:
DirIndex scope: "every extracted link destination"
MD21CLEAN

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-canonical-facts.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean FACT-9 tree"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Negative vector: "missing-.md file destinations only" — the narrow D-061-rejected reading.
    # An author who writes this believes DirIndex is only for missing-.md link checking,
    # ignoring non-.md links and directory links — exactly the claim D-061 ruled out.
    cat > "$T/.factory/specs/selftest-fact9.md" <<'MD21BAD'
Pass 1.5 builds:
DirIndex scope: "missing-.md file destinations only"
MD21BAD
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-canonical-facts.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — narrow scope should DIVERGE from broad scope)"
        FAILURES=$((FAILURES + 1))
    else
        CF_OUTPUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-canonical-facts.py" 2>&1)
        if echo "$CF_OUTPUT" | grep -q "DIVERGE \[FACT-9-NEG\]"; then
            echo "  PASS (clean-pass confirmed; DIVERGE [FACT-9-NEG] correctly reported for narrow DirIndex scope)"
        else
            echo "  FAIL (checker exited non-zero but expected 'DIVERGE [FACT-9-NEG]' not in output)"
            echo "  Actual output: $CF_OUTPUT"
            FAILURES=$((FAILURES + 1))
        fi
    fi
fi
rm -rf "$T"

# ── Test 22: check-canonical-facts — FACT-10 negative (second config_error trigger) ─────
# BI-035: FACT-10 canonical_value = 'invalid `--ignore` glob'.
# Negative vector: 'invalid `--ignore` glob or unrecognized flag' — adds a second spurious
# trigger, which D-062 explicitly ruled out (unrecognized flags are handled by clap before
# app::run(); they never reach verdict::exit_code). Exactly one trigger exists.
# Pattern uses flexible quotes-capture so the != branch fires even with backtick content.
# Mutation-verify: neutralizing != flips this test to FAIL.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 22: check-canonical-facts: FACT-10 negative — second config_error trigger fails ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs"

cat > "$T/.factory/specs/canonical-facts.toml" <<'TOML22'
[[fact]]
id              = "FACT-10-NEG"
description     = "config_error has exactly one trigger: invalid --ignore glob (D-062)"
canonical_value = 'invalid `--ignore` glob'
source          = "selftest"

[[binding]]
fact_id = "FACT-10-NEG"
file    = ".factory/specs/selftest-fact10.md"
note    = "sole trigger declaration"
pattern = 'config error trigger: "(.*?)"'
TOML22

cat > "$T/.factory/specs/selftest-fact10.md" <<'MD22CLEAN'
Exit-2 conditions:
config error trigger: "invalid `--ignore` glob"
MD22CLEAN

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-canonical-facts.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean FACT-10 tree"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Negative vector: adds unrecognized flag as a second spurious trigger (D-062 rejected).
    # Clap handles unrecognized flags before app::run(); they never reach verdict::exit_code.
    cat > "$T/.factory/specs/selftest-fact10.md" <<'MD22BAD'
Exit-2 conditions:
config error trigger: "invalid `--ignore` glob or unrecognized flag"
MD22BAD
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-canonical-facts.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — two-trigger claim should DIVERGE from sole-trigger canonical)"
        FAILURES=$((FAILURES + 1))
    else
        CF_OUTPUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-canonical-facts.py" 2>&1)
        if echo "$CF_OUTPUT" | grep -q "DIVERGE \[FACT-10-NEG\]"; then
            echo "  PASS (clean-pass confirmed; DIVERGE [FACT-10-NEG] correctly reported for second trigger)"
        else
            echo "  FAIL (checker exited non-zero but expected 'DIVERGE [FACT-10-NEG]' not in output)"
            echo "  Actual output: $CF_OUTPUT"
            FAILURES=$((FAILURES + 1))
        fi
    fi
fi
rm -rf "$T"

# ── Test 23: gen-bc-traceability --check detects Architecture Module mismatch ────────────
# Operator-endorsed landing gate (Task 2). Uses a pre-populated isolated temp tree:
# the BC file already contains the correct @GENERATED block with the expected generated
# value (computed from the generator's format_arch_module_value logic for this fixture).
# Write mode is fail-closed (BI-041 guard), so normal-mode setup is not used.
# Clean pass: --check exits 0 (fixture already matches generated output).
# Defect:     corrupt the Architecture Module value → --check exits 1.
# Confirms --check is read-only w.r.t. canonical-facts.toml (not in temp tree).
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 23: gen-bc-traceability --check: detects Architecture Module mismatch ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/architecture"
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-99"

# Minimal bc-module-map.md: BC-2.99.001, test-mod, Pure, CRITICAL, ADR-999
cat > "$T/.factory/specs/architecture/bc-module-map.md" <<'BCMAP'
| BC ID | Primary Module | Secondary | P/E | Tier | Key ADRs | Formal VPs |
|-------|----------------|-----------|-----|------|----------|------------|
| BC-2.99.001 | `test-mod` | — | Pure | CRITICAL | ADR-999 | — |
BCMAP

# BC file pre-populated with correct @GENERATED content.
# Expected value (from format_arch_module_value with no ADR title files):
#   `test-mod.rs` (SS-99, pure core, CRITICAL tier) — ADR-999
# No ADR decisions/ dir → adr_titles empty → ADR-999 appears without title.
cat > "$T/.factory/specs/behavioral-contracts/ss-99/BC-2.99.001.md" <<'BCFILE'
# BC-2.99.001: Selftest BC

## Traceability
<!-- @GENERATED:BEGIN bc-arch-module -->
| Architecture Module | `test-mod.rs` (SS-99, pure core, CRITICAL tier) — ADR-999 |
<!-- @GENERATED:END bc-arch-module -->
BCFILE

# Clean pass: --check exits 0 (fixture matches generated output)
CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/gen-bc-traceability.py" --check > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: --check failed on pre-populated correct fixture"
    CHECK_ERR=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/gen-bc-traceability.py" --check 2>&1)
    echo "  Output: $CHECK_ERR"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: corrupt the generated Architecture Module value in the BC file
    BC_FILE="$T/.factory/specs/behavioral-contracts/ss-99/BC-2.99.001.md"
    sed -i.bak 's/Architecture Module | .*/Architecture Module | corrupted-stale-value |/' "$BC_FILE"
    CHECK_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/gen-bc-traceability.py" --check 2>&1)
    if [ $? -eq 0 ]; then
        echo "  FAIL (--check returned 0 — did NOT detect Architecture Module mismatch)"
        FAILURES=$((FAILURES + 1))
    else
        if echo "$CHECK_OUT" | grep -q "FAIL"; then
            echo "  PASS (clean-pass confirmed; --check correctly detects Architecture Module mismatch)"
        else
            echo "  FAIL (--check exited non-zero but expected 'FAIL' not in output)"
            echo "  Actual output: $CHECK_OUT"
            FAILURES=$((FAILURES + 1))
        fi
    fi
fi
rm -rf "$T"

# ── Test 24: gen-slug-corpus --check detects SLUG_CORPUS content mismatch ────────────────
# Operator-endorsed landing gate (Task 2). Uses isolated temp tree: run generator with
# --write to establish a known-good state, verify --check exits 0 (clean pass),
# then corrupt the generated corpus block and verify --check exits 1 (defect pass).
# Confirms --check is read-only w.r.t. canonical-facts.toml (not in temp tree).
# Setup uses --write (explicit opt-in) because the concurrency guard (selftest 28)
# prevents bare invocation from writing.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 24: gen-slug-corpus --check: detects SLUG_CORPUS mismatch ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/prd-supplements"
mkdir -p "$T/.factory/specs/verification-properties"

# Minimal test-vectors.md with one TV-S entry in §7
cat > "$T/.factory/specs/prd-supplements/test-vectors.md" <<'TVFILE'
# Test Vectors

## §7. Slug Test Vectors (TV-S)

| TV-ID | Heading Text | Expected Slug | Source |
|-------|-------------|---------------|--------|
| TV-S999 | `Hello World` | `hello-world` | DD-001 |

---
TVFILE

# Minimal vp-018 with SLUG_CORPUS array ready for insertion (no markers yet)
cat > "$T/.factory/specs/verification-properties/vp-018-slug-worked-examples.md" <<'VP018FILE'
# VP-018 Selftest Fixture

```rust
const SLUG_CORPUS: &[(&str, &str)] = &[
];
```
VP018FILE

# Clean pass: run generator with --write first, then --check on the result.
CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/gen-slug-corpus.py" --write > /dev/null 2>&1; then
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/gen-slug-corpus.py" --check > /dev/null 2>&1; then
        TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
        CLEAN_PASS=1
    else
        echo "  STRUCTURAL FAIL: --check failed immediately after --write run (should be identical)"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "  STRUCTURAL FAIL: generator --write run failed on minimal VP-018 fixture"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: corrupt the generated SLUG_CORPUS entry (change expected slug)
    VP018="$T/.factory/specs/verification-properties/vp-018-slug-worked-examples.md"
    sed -i.bak 's/"hello-world"/"hello_world"/g' "$VP018"
    CHECK_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/gen-slug-corpus.py" --check 2>&1)
    if [ $? -eq 0 ]; then
        echo "  FAIL (--check returned 0 — did NOT detect SLUG_CORPUS mismatch)"
        FAILURES=$((FAILURES + 1))
    else
        if echo "$CHECK_OUT" | grep -q "FAIL"; then
            echo "  PASS (clean-pass confirmed; --check correctly detects SLUG_CORPUS mismatch)"
        else
            echo "  FAIL (--check exited non-zero but expected 'FAIL' not in output)"
            echo "  Actual output: $CHECK_OUT"
            FAILURES=$((FAILURES + 1))
        fi
    fi
fi
rm -rf "$T"

# ── Test 25: check-canonical-facts — linked-worktree refusal + SPEC_LINT_REPO_OVERRIDE ──
# Documents the REAL behavior from a secondary git worktree. BI-021 (open): from a linked
# worktree, the .git boundary stop fires before the walk reaches the main checkout's
# .factory/ — the checker exits 1 with guidance to set SPEC_LINT_REPO_OVERRIDE.
# This IS the correct, expected behavior (fail-closed). SPEC_LINT_REPO_OVERRIDE is the
# supported path from secondary worktrees.
#
# Fixture: .worktrees/BI021-SIM/.git is a FILE (pointer, as in a real git linked worktree).
# canonical-facts.toml is at the temp root (accessible via SPEC_LINT_REPO_OVERRIDE).
#
# Clean pass: without SPEC_LINT_REPO_OVERRIDE, boundary stop fires → exit 1 with
#             SPEC_LINT_REPO_OVERRIDE mentioned in output.
# Defect:     SPEC_LINT_REPO_OVERRIDE set to repo root → exits 0 (override is effective).
#
# Mutation-verify: removing the .git boundary stop allows the walk to escape past .git to
# $T/, find canonical-facts.toml, and exit 0 without SPEC_LINT_REPO_OVERRIDE — flipping
# the clean-pass assertion (which expects exit non-zero) to FAIL.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 25: check-canonical-facts: linked-worktree refusal + SPEC_LINT_REPO_OVERRIDE override ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs"
mkdir -p "$T/.worktrees/BI021-SIM/scripts/spec-lint"

# canonical-facts.toml at the repo root — reachable only via SPEC_LINT_REPO_OVERRIDE
cat > "$T/.factory/specs/canonical-facts.toml" <<'TOML25'
[[fact]]
id              = "FACT-BI021"
description     = "BI-021 worktree path resolution selftest"
canonical_value = "bi021-pass"
source          = "selftest"

[[binding]]
fact_id = "FACT-BI021"
file    = ".factory/specs/selftest-bi021.md"
note    = "worktree resolution binding"
pattern = 'bi021 value: (bi021-pass)'
TOML25

cat > "$T/.factory/specs/selftest-bi021.md" <<'MD25'
# BI-021 Selftest Binding
bi021 value: bi021-pass
MD25

# .git FILE at the worktree root — simulates a real git linked worktree
printf "gitdir: ../../.git/worktrees/BI021-SIM\n" > "$T/.worktrees/BI021-SIM/.git"

# Copy the script into the simulated secondary worktree
cp "$LINT_DIR/check-canonical-facts.py" "$T/.worktrees/BI021-SIM/scripts/spec-lint/"

# Clean pass: without SPEC_LINT_REPO_OVERRIDE, boundary stop fires at .git → exit non-zero
# with guidance message naming SPEC_LINT_REPO_OVERRIDE.
CLEAN_PASS=0
BI021_OUT=$(python3 "$T/.worktrees/BI021-SIM/scripts/spec-lint/check-canonical-facts.py" 2>&1)
BI021_EXIT=$?
if [ "$BI021_EXIT" -ne 0 ] && echo "$BI021_OUT" | grep -q "SPEC_LINT_REPO_OVERRIDE"; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
elif [ "$BI021_EXIT" -eq 0 ]; then
    echo "  STRUCTURAL FAIL: script exited 0 without SPEC_LINT_REPO_OVERRIDE (false pass — boundary stop missing)"
    echo "  Output: $BI021_OUT"
    FAILURES=$((FAILURES + 1))
else
    echo "  STRUCTURAL FAIL: script exited $BI021_EXIT but output did not name SPEC_LINT_REPO_OVERRIDE"
    echo "  Output: $BI021_OUT"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: SPEC_LINT_REPO_OVERRIDE=$T → override bypasses boundary stop, exits 0 (correct)
    OVERRIDE_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" \
        python3 "$T/.worktrees/BI021-SIM/scripts/spec-lint/check-canonical-facts.py" 2>&1)
    OVERRIDE_EXIT=$?
    if [ "$OVERRIDE_EXIT" -eq 0 ]; then
        echo "  PASS (clean-pass confirmed; linked-worktree refusal correct; SPEC_LINT_REPO_OVERRIDE override effective)"
    else
        echo "  FAIL (SPEC_LINT_REPO_OVERRIDE set but checker still exited non-zero — override not effective)"
        echo "  Output: $OVERRIDE_OUT"
        FAILURES=$((FAILURES + 1))
    fi
fi
rm -rf "$T"

# ── Test 26: gen-bc-traceability write mode is fail-closed (BI-041 guard) ────────────────
# The generator's model destroys hand-authored INC-MAP annotations in Architecture Module
# rows. Write mode must unconditionally refuse until BI-041 is adjudicated.
# --dry-run and --check modes must remain unblocked (they never write files).
#
# Clean pass: generator with --dry-run exits 0 on a valid BC fixture.
# Defect:     generator with --write exits non-zero with BI-041 guard message.
#             (--write is the explicit opt-in that passes the concurrency gate, Gate 1,
#              but must still be refused by the BI-041 gate, Gate 2 — two independent gates.)
#
# Mutation-verify status: NOT independently verifiable. Removing only Gate 2 does not
# flip this test to FAIL: --write then hits the function-level RuntimeError in
# update_bc_file, whose message also contains "BI-041" — the grep still matches and
# the suite stays green. Both Gate 2 AND the function-level guard must be removed
# simultaneously for --write to succeed and for exit code to become 0.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 26: gen-bc-traceability: write mode fail-closed (BI-041 guard) ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/architecture"
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-99"

# Minimal valid BC fixture (same as test 23)
cat > "$T/.factory/specs/architecture/bc-module-map.md" <<'BCMAP26'
| BC ID | Primary Module | Secondary | P/E | Tier | Key ADRs | Formal VPs |
|-------|----------------|-----------|-----|------|----------|------------|
| BC-2.99.001 | `test-mod` | — | Pure | CRITICAL | — | — |
BCMAP26

cat > "$T/.factory/specs/behavioral-contracts/ss-99/BC-2.99.001.md" <<'BCFILE26'
# BC-2.99.001: Selftest BC

## Traceability
| Architecture Module | existing-value |
BCFILE26

# Clean pass: --dry-run must exit 0 (non-destructive modes are not blocked)
CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/gen-bc-traceability.py" --dry-run > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: --dry-run unexpectedly failed (should be unblocked by BI-041 guard)"
    DR_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/gen-bc-traceability.py" --dry-run 2>&1)
    echo "  Output: $DR_OUT"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: --write passes the concurrency gate (Gate 1) but must still exit non-zero
    # with the BI-041 guard message from Gate 2.
    GUARD_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/gen-bc-traceability.py" --write 2>&1)
    GUARD_EXIT=$?
    if [ "$GUARD_EXIT" -eq 0 ]; then
        echo "  FAIL (--write returned 0 — BI-041 guard (Gate 2) not active; BC files could be corrupted)"
        FAILURES=$((FAILURES + 1))
    else
        # D-040: assert on specific guard message, not just exit code
        if echo "$GUARD_OUT" | grep -q "BI-041"; then
            echo "  PASS (clean-pass confirmed; --write correctly blocked by BI-041 guard (Gate 2))"
        else
            echo "  FAIL (--write exited non-zero but expected 'BI-041' not in output)"
            echo "  Actual output: $GUARD_OUT"
            FAILURES=$((FAILURES + 1))
        fi
    fi
fi
rm -rf "$T"

# ── Test 27: gen-bc-traceability bare invocation is fail-safe (concurrency gate) ─────────
# Verifies that Gate 1 (concurrency safety gate) refuses bare invocation and does not
# write any BC file. Uses --dry-run for the clean pass (proves the fixture is valid).
#
# Clean pass: --dry-run exits 0 (non-destructive, unblocked by either gate).
# Defect:     bare invocation exits non-zero (Gate 1 fires) AND BC file is byte-identical
#             (no write occurred before the guard refused).
#
# Mutation note: removing ONLY Gate 1 does not flip this test. --write is not
# passed in the defect step so Gate 2 is irrelevant; the byte-identical assertion
# passes because the function-level RuntimeError in update_bc_file prevents any
# write. Only removing Gate 1 AND that RuntimeError simultaneously allows writes.
# Full isolation of Gate 1 requires removing BOTH gates — tested jointly.
# For an independently mutation-verifiable bare-invocation test, see selftest 28
# (gen-slug-corpus, which has no Gate 2 analogue).
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 27: gen-bc-traceability: bare invocation is fail-safe (concurrency gate) ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/architecture"
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-99"

cat > "$T/.factory/specs/architecture/bc-module-map.md" <<'BCMAP27'
| BC ID | Primary Module | Secondary | P/E | Tier | Key ADRs | Formal VPs |
|-------|----------------|-----------|-----|------|----------|------------|
| BC-2.99.001 | `test-mod` | — | Pure | CRITICAL | — | — |
BCMAP27

cat > "$T/.factory/specs/behavioral-contracts/ss-99/BC-2.99.001.md" <<'BCFILE27'
# BC-2.99.001: Selftest BC (concurrency gate fixture)

## Traceability
| Architecture Module | existing-value |
BCFILE27

BC27="$T/.factory/specs/behavioral-contracts/ss-99/BC-2.99.001.md"

# Clean pass: --dry-run must exit 0 (non-destructive modes are never gated)
CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/gen-bc-traceability.py" --dry-run > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: --dry-run unexpectedly failed (should not be gated)"
    DR27_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/gen-bc-traceability.py" --dry-run 2>&1)
    echo "  Output: $DR27_OUT"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    BEFORE27=$(cat "$BC27")
    # Defect: bare invocation must exit non-zero (concurrency gate fires)
    BARE27_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/gen-bc-traceability.py" 2>&1)
    BARE27_EXIT=$?
    if [ "$BARE27_EXIT" -eq 0 ]; then
        echo "  FAIL (bare invocation returned 0 — concurrency gate not active)"
        FAILURES=$((FAILURES + 1))
    else
        # Confirm BC file was not modified (no write occurred)
        AFTER27=$(cat "$BC27")
        if [ "$BEFORE27" = "$AFTER27" ]; then
            echo "  PASS (clean-pass confirmed; bare invocation refused and BC file byte-identical after)"
        else
            echo "  FAIL (gate refused but BC file was still modified — write occurred before gate check)"
            FAILURES=$((FAILURES + 1))
        fi
    fi
fi
rm -rf "$T"

# ── Test 28: gen-slug-corpus bare invocation is fail-safe (concurrency gate) ────────────
# Verifies that the concurrency gate refuses bare invocation and VP-018 is byte-identical
# after refusal. This test IS fully mutation-verifiable: removing the gate causes bare
# invocation to write VP-018, flipping the file-identical assertion to FAIL.
#
# Clean pass: --dry-run exits 0 on an unpopulated VP-018 fixture (proves fixture is valid).
# Defect:     bare invocation exits non-zero (concurrency gate fires) AND VP-018 is
#             byte-identical (no write occurred).
#
# Mutation-verify: removing the concurrency guard block in gen-slug-corpus.py causes bare
# invocation to write VP-018 (inserting the corpus block), the BEFORE/AFTER comparison
# fails, and this test's defect-fail assertion flips to FAIL.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 28: gen-slug-corpus: bare invocation is fail-safe (concurrency gate) ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/prd-supplements"
mkdir -p "$T/.factory/specs/verification-properties"

cat > "$T/.factory/specs/prd-supplements/test-vectors.md" <<'TVFILE28'
# Test Vectors

## §7. Slug Test Vectors (TV-S)

| TV-ID | Heading Text | Expected Slug | Source |
|-------|-------------|---------------|--------|
| TV-S998 | `Bare Guard` | `bare-guard` | selftest-28 |

---
TVFILE28

# VP-018 with no @GENERATED markers yet — generator WOULD insert corpus block if not gated
cat > "$T/.factory/specs/verification-properties/vp-018-slug-worked-examples.md" <<'VP018_28'
# VP-018 Selftest Fixture (test 28)

```rust
const SLUG_CORPUS: &[(&str, &str)] = &[
];
```
VP018_28

VP28="$T/.factory/specs/verification-properties/vp-018-slug-worked-examples.md"

# Clean pass: --dry-run must exit 0 (non-destructive, not gated)
CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/gen-slug-corpus.py" --dry-run > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: --dry-run unexpectedly failed (should not be gated)"
    DR28_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/gen-slug-corpus.py" --dry-run 2>&1)
    echo "  Output: $DR28_OUT"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    BEFORE28=$(cat "$VP28")
    # Defect: bare invocation must exit non-zero (concurrency gate fires)
    BARE28_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/gen-slug-corpus.py" 2>&1)
    BARE28_EXIT=$?
    if [ "$BARE28_EXIT" -eq 0 ]; then
        echo "  FAIL (bare invocation returned 0 — concurrency gate not active; VP-018 may have been written)"
        FAILURES=$((FAILURES + 1))
    else
        # Confirm VP-018 was not modified (no write occurred before the gate refused)
        AFTER28=$(cat "$VP28")
        if [ "$BEFORE28" = "$AFTER28" ]; then
            echo "  PASS (clean-pass confirmed; bare invocation refused and VP-018 byte-identical after)"
        else
            echo "  FAIL (gate refused but VP-018 was still modified — write occurred before gate check)"
            FAILURES=$((FAILURES + 1))
        fi
    fi
fi
rm -rf "$T"

# ── Test 29: meta-guard — every check-*.py on disk is in the ACTIVE CHECKS array ─────────
# BLOCKING-1 meta-guard. The guard must grade against what bash ACTUALLY EXECUTES, not
# what appears anywhere in the file text. A commented-out entry (`# "check-name"`) passes
# a grep-based text search but IS NOT EXECUTED — commenting out is the ordinary way a
# check gets disabled. The guard must not be defeated by it.
#
# Implementation: extract CHECKS=(...) array content from each runner file via awk, drop
# blank lines and lines starting with '#', strip quotes, and compare the derived live list
# against check-*.py on disk. This proves semantic presence, not textual presence.
#
# Clean pass: all check-*.py on disk appear in the ACTIVE (non-commented) CHECKS arrays
#             of BOTH ci.yml and justfile.
# Defect A:   temp ci.yml with "check-canonical-facts" COMMENTED OUT → detected (ci arm).
# Defect B:   temp justfile with "check-canonical-facts" COMMENTED OUT → detected (just arm).
# Both arms verified independently. Mutation-verify: replacing the awk extraction with a
# simple grep (not stripping comments) causes both defects to pass undetected, flipping
# both assertions to FAIL.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 29: meta-guard: every check-*.py is in the active CHECKS array (both runners) ──"

# Extract non-commented entries from the CHECKS=( ... ) block in a runner file.
# Returns one name per line, without surrounding quotes.
# FAILS LOUDLY (exit 1, message to stderr) if the file contains more than one
# CHECKS=( block: a second block would make it ambiguous which entries bash
# actually executes; silently unioning both could include demoted checkers as
# if still active.  If more than one block is found, the guard's assumption has
# been invalidated — update the guard to name the authoritative array.
_get_active_checks() {
    local file="$1"
    local block_count
    block_count=$(awk '/CHECKS=\(/{c++} END{print c+0}' "$file")
    if [ "$block_count" -ne 1 ]; then
        echo "META-GUARD ERROR: $file contains $block_count CHECKS=( block(s) — expected exactly 1." >&2
        echo "  The guard's assumption (one authoritative array per runner file) has been invalidated." >&2
        echo "  Update the guard to name the authoritative array before proceeding." >&2
        return 1
    fi
    awk '
        /CHECKS=\(/ { in_array=1; next }
        in_array && /\)/ { in_array=0 }
        in_array {
            sub(/^[[:space:]]+/, "")
            if ($0 == "" || substr($0, 1, 1) == "#") next
            gsub(/"/, "")
            if ($0 != "") print $0
        }
    ' "$file"
}

RUNNER_MISSING=0
MISSING_IN_CI=()
MISSING_IN_JUST=()
CI_ACTIVE=$(_get_active_checks "$REPO/.github/workflows/ci.yml")
JUST_ACTIVE=$(_get_active_checks "$REPO/justfile")

for py_file in "$LINT_DIR"/check-*.py; do
    [[ -f "$py_file" ]] || continue
    name=$(basename "$py_file" .py)
    if ! echo "$CI_ACTIVE" | grep -qx "$name"; then
        MISSING_IN_CI+=("$name")
        RUNNER_MISSING=1
    fi
    if ! echo "$JUST_ACTIVE" | grep -qx "$name"; then
        MISSING_IN_JUST+=("$name")
        RUNNER_MISSING=1
    fi
done

CLEAN_PASS=0
if [ "$RUNNER_MISSING" -eq 0 ]; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL (clean-pass): checker(s) absent from active CHECKS array:"
    for m in "${MISSING_IN_CI[@]+"${MISSING_IN_CI[@]}"}"; do echo "    MISSING from ci.yml active array: $m"; done
    for m in "${MISSING_IN_JUST[@]+"${MISSING_IN_JUST[@]}"}"; do echo "    MISSING from justfile active array: $m"; done
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    T=$(make_temp)
    ALL_ARM_DEFECTS_DETECTED=1

    # Defect A: ci.yml arm — COMMENT OUT (not delete) the check-canonical-facts entry
    sed 's/"check-canonical-facts"/# "check-canonical-facts"/' \
        "$REPO/.github/workflows/ci.yml" > "$T/ci-defect.yml"
    CI_DEFECT=$(_get_active_checks "$T/ci-defect.yml")
    CI_ARM_MISSED=0
    for py_file in "$LINT_DIR"/check-*.py; do
        [[ -f "$py_file" ]] || continue
        name=$(basename "$py_file" .py)
        if ! echo "$CI_DEFECT" | grep -qx "$name"; then
            CI_ARM_MISSED=1
        fi
    done
    if [ "$CI_ARM_MISSED" -eq 0 ]; then
        echo "  FAIL (ci.yml arm: commented-out entry NOT detected — guard is defeated by comments)"
        FAILURES=$((FAILURES + 1))
        ALL_ARM_DEFECTS_DETECTED=0
    fi

    # Defect B: justfile arm — COMMENT OUT the check-canonical-facts entry
    sed 's/"check-canonical-facts"/# "check-canonical-facts"/' \
        "$REPO/justfile" > "$T/justfile-defect"
    JUST_DEFECT=$(_get_active_checks "$T/justfile-defect")
    JUST_ARM_MISSED=0
    for py_file in "$LINT_DIR"/check-*.py; do
        [[ -f "$py_file" ]] || continue
        name=$(basename "$py_file" .py)
        if ! echo "$JUST_DEFECT" | grep -qx "$name"; then
            JUST_ARM_MISSED=1
        fi
    done
    if [ "$JUST_ARM_MISSED" -eq 0 ]; then
        echo "  FAIL (justfile arm: commented-out entry NOT detected — guard is defeated by comments)"
        FAILURES=$((FAILURES + 1))
        ALL_ARM_DEFECTS_DETECTED=0
    fi

    # Defect C: two-array fixture — guard must reject files with multiple CHECKS=( blocks.
    # Mutation-verify: removing the block_count check from _get_active_checks causes
    # _get_active_checks to return 0 (success) instead of 1 (failure), flipping this
    # arm's defect-detected assertion to FAIL.
    cat > "$T/ci-twoarray.yml" <<'TWOARRAY_EOF'
CHECKS=(
  "check-first"
  "check-second"
)
# Advisory checks (not yet blocking)
CHECKS=(
  "check-advisory"
)
TWOARRAY_EOF
    if _get_active_checks "$T/ci-twoarray.yml" >/dev/null 2>&1; then
        echo "  FAIL (two-array fixture: guard did NOT reject file with two CHECKS=( blocks)"
        FAILURES=$((FAILURES + 1))
        ALL_ARM_DEFECTS_DETECTED=0
    fi

    if [ "$ALL_ARM_DEFECTS_DETECTED" -eq 1 ]; then
        echo "  PASS (clean-pass confirmed; ci.yml and justfile arms detect commented-out entry; two-array fixture rejected)"
    fi
    rm -rf "$T"
fi

# ── Test 30: check-canonical-facts — boundary stop prevents ancestor escape (MAJOR-2) ───
# The .git boundary stop in _find_repo_root() prevents the walk from escaping the current
# repository when .factory/ is unmounted (or when running from a linked worktree). Without
# the stop, the walk exits the inner repository, binds a decoy canonical-facts.toml from
# an ancestor, and exits 0 (false pass). With the stop, it exits 1 (fail-closed, correct).
#
# Test structure:
#   $T/
#     .factory/specs/canonical-facts.toml  — decoy (in ancestor, must NOT be found)
#     .factory/specs/decoy-binding.md       — binding file that matches the decoy
#     inner/
#       .git                                — FILE, simulates a linked worktree
#       scripts/spec-lint/
#         check-canonical-facts.py          — copy of fixed script
#
# Clean pass: boundary stop fires at inner/.git; no canonical-facts.toml found within
#             the inner repository → script exits non-zero (fail-closed, correct).
# Defect:     remove inner/.git; walk now escapes to $T/, finds decoy canonical-facts.toml,
#             binds it, all bindings match → script exits 0 (false pass — defect confirmed).
#
# Mutation-verify: removing `if (candidate / ".git").exists(): return None` from
# _find_repo_root() causes the walk to escape past inner/.git even when it exists,
# finds the decoy, and exits 0 — flipping the clean-pass assertion to FAIL.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 30: check-canonical-facts: boundary stop prevents ancestor escape ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs"
mkdir -p "$T/inner/scripts/spec-lint"

# Decoy canonical-facts.toml in ancestor — must NEVER be reached by the inner script
cat > "$T/.factory/specs/canonical-facts.toml" <<'CF30'
[[fact]]
id = "FACT-DECOY30"
description = "Decoy — inner-repo script must not bind this"
canonical_value = "decoy-pass"
source = "selftest-30"

[[binding]]
fact_id = "FACT-DECOY30"
file = ".factory/specs/decoy-binding.md"
note = "decoy binding for boundary stop test"
pattern = 'decoy: (decoy-pass)'
CF30

cat > "$T/.factory/specs/decoy-binding.md" <<'DB30'
# Decoy Binding (boundary stop test — selftest 30)
decoy: decoy-pass
DB30

# inner/.git is a FILE (simulates git linked worktree — .git is a pointer file in worktrees)
printf "gitdir: ../../.git/worktrees/inner\n" > "$T/inner/.git"

# Copy the FIXED script into the simulated inner repository
cp "$LINT_DIR/check-canonical-facts.py" "$T/inner/scripts/spec-lint/"

# Clean pass: boundary stop must fire and script must exit non-zero (fail-closed)
CLEAN_PASS=0
BOUND_OUT=$(python3 "$T/inner/scripts/spec-lint/check-canonical-facts.py" 2>&1)
BOUND_EXIT=$?
if [ "$BOUND_EXIT" -ne 0 ]; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: boundary stop did not fire — script exited 0 (false pass against decoy)"
    echo "  Output: $BOUND_OUT"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: remove inner/.git — the boundary stop no longer fires; walk escapes to
    # $T/ and finds the decoy canonical-facts.toml, producing a false pass (exit 0)
    rm "$T/inner/.git"
    DEFECT_OUT=$(python3 "$T/inner/scripts/spec-lint/check-canonical-facts.py" 2>&1)
    DEFECT_EXIT=$?
    if [ "$DEFECT_EXIT" -eq 0 ]; then
        echo "  PASS (clean-pass confirmed; boundary stop prevents false pass; without .git, decoy is found)"
    else
        echo "  FAIL (without .git boundary marker, script still exited non-zero — walk did not escape to decoy)"
        echo "  Output: $DEFECT_OUT"
        FAILURES=$((FAILURES + 1))
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
# uncounted. After the BLOCKING-2 fix, all pre-separator rows are buffered without
# any shape gate.
#
# D-069 MINOR-1 note: _is_column_header() is applied ONLY to pending_pre_sep[-1]
# (the last buffered row). The column header "| HS ID | ... |" is the last row
# before the separator; it is recognised and placed in the column_header bucket.
# The bold "| **HS-042** | EC-999 | ... |" row is first in the buffer; it goes to
# data_row via _classify(); "**HS-042**" does not match any HS pattern (** defeats
# the anchored regex); the row is added to unclassified_lines; B-9 fires.
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

# ── Test B4: check-index-integrity — phantom data row in column-header position ─
# D-068 residual exploit: when the ONLY pre-separator row is a real data row
# (e.g., "| HS-099 | EC-999 | Phantom |"), the prior unconditional positional
# discard (pending[-1]) silently dropped it. EC-999 was never forward-checked;
# the checker exited 0 — a false pass.
#
# Fix: _is_column_header() positive recognition. The phantom row's first cell
# is "HS-099", not "hs id" / "hs-id" / "hs_id", so _is_column_header() returns
# False → the row is counted → forward check sees EC-999 has no wave-scenarios
# file → checker exits 1.
#
# Mutation-flip: restore the unconditional `pending[:-1]` positional discard.
# The phantom row is again silently dropped; EC-999 is never checked; checker
# exits 0 on the defect tree → B4 FAILS.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest B4: check-index-integrity: phantom data row in column-header position (D-068 residual) ──"
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
# Clean tree: single valid entry, column header, separator, data row — all in order.
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
    # Defect: exactly the coordinator's exploit fixture. The phantom data row
    # "| HS-099 | EC-999 | Phantom |" is the ONLY pre-separator row — no real
    # column header precedes it. With the D-068 residual (pending[-1] discard),
    # this row is silently dropped; EC-999 is never checked; exit 0 (false pass).
    # With the _is_column_header() fix, "HS-099" is not in _HEADER_FIRST_CELLS;
    # the row is counted; the forward check fires on missing EC-999; exit 1.
    cat > "$T/.factory/holdout-scenarios/HS-INDEX.md" <<'HSIX_DEFECT'
## Authored Scenarios

| HS-099 | EC-999 | Phantom | phantom | BC-9.99.999 | active |
|-------|-------|-------|-------|-----|--------|
| HS-001 | EC-156 | Selftest scenario | Notes | BC-2.01.001 | active |
HSIX_DEFECT
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-index-integrity.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — phantom data row in column-header position not detected — D-068 residual not closed)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; phantom data row in column-header position correctly detected)"
    fi
fi
rm -rf "$T"

# ── D-069 property test ────────────────────────────────────────────────────────
# D-069 structural property: for every generated HS-INDEX input, the conservation
# law total_candidates == sum(bucket_counts) holds.  No non-blank line may vanish
# from the accounting regardless of structural variety (heading levels, fenced
# blocks, pseudo-headings, adjacent-pipe rows, pre-separator rows, decorated IDs).
#
# Generator: stdlib random.Random(42), 300 deterministic cases covering:
#   heading levels 1-6, #-runs without space (#2/#TODO/#note), 4-space-indented ##,
#   fenced code blocks with heading-like / table-like internals, adjacent pipes (||),
#   pipeless spaced rows, strikethrough + bold decoration, pre-separator data rows,
#   empty/dash first cells, h3+ sub-sections, non-HS sections (## Reserved IDs).
#
# Mutation: if _flush_pending() omitted the pending_pre_sep[:-1] loop, pre-separator
# rows would go unbucketed → total_candidates > sum(buckets) → assertion fires →
# property test FAILS.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── D-069 property test: conservation law for 300 generated inputs ──"

CLEAN_PASS=0
if python3 "$LINT_DIR/check-index-integrity.py" --property-test 1 > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: property test failed even on minimal (1-case) run"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    if python3 "$LINT_DIR/check-index-integrity.py" --property-test 300; then
        echo "  PASS (300 generated cases all verified conservation law)"
    else
        echo "  FAIL (conservation law violated on at least one generated case)"
        FAILURES=$((FAILURES + 1))
    fi
fi

# ── Test D-069-A: #2 pseudo-heading kills section scope (BLOCKING-1 regression A) ──
# The prior startswith("#") + level <= 2 check matched '#2 below: wave-2 candidates'
# (level == 1), set in_authored_scenarios=False, and silently dropped every
# subsequent row. CommonMark requires space or EOL after the #-run (§4.2); '#2'
# has no space after '#', so it is not a heading — it is prose. With the D-069
# _CM_HEADING_RE fix, '#2 below' becomes prose, section scope is unchanged, and
# the phantom rows after it are counted and caught.
#
# Mutation-flip: replace _CM_HEADING_RE.match with re.match(r'^#+', line).
# '#2 below' matches, level==1, in_authored_scenarios=False; all subsequent rows
# are prose-bucketed (out of scope); B-9 doesn't fire; checker exits 0 → FAILS.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest D-069-A: #2 pseudo-heading kills section scope (fixture A) ──"
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
    # Defect: insert '#2 below: wave-2 candidates' (not a CommonMark heading)
    # between two tables. The checker must NOT treat this as a section boundary.
    # HS-099 → EC-999 (no wave-scenarios file) and near-miss hs_098 must be caught.
    cat > "$T/.factory/holdout-scenarios/HS-INDEX.md" <<'HSIX_DEFECT'
## Authored Scenarios

| HS ID | EC ID | Title | Notes | BCs | Status |
|-------|-------|-------|-------|-----|--------|
| HS-001 | EC-156 | Selftest scenario | Notes | BC-2.01.001 | active |

#2 below: wave-2 candidates

| HS ID | EC ID | Title | Notes | BCs | Status |
|-------|-------|-------|-------|-----|--------|
| HS-099 | EC-999 | PHANTOM — no wave-scenarios file | Notes | BC | active |
| hs_098 | EC-998 | Near-miss ID — also phantom | Notes | BC | active |
HSIX_DEFECT
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-index-integrity.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — #2 pseudo-heading killed section scope — D-069-A not fixed)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; #2 pseudo-heading treated as prose; phantom rows detected)"
    fi
fi
rm -rf "$T"

# ── Test D-069-A2: fenced-code heading kills section scope (fixture A2) ──────
# A line like '# Example heading' inside a ``` fence is not a CommonMark ATX
# heading — it is code content. The prior code did not track fenced code blocks,
# so it set in_authored_scenarios=False on the fenced heading and silently
# dropped all subsequent rows. After the D-069 _FENCE_RE fix, lines inside a
# fenced block land in the fenced_code bucket and never affect section scope.
#
# Mutation-flip: remove the fenced-code block tracking (_FENCE_RE / in_fenced_code).
# The '# heading inside fence' line is treated as an h1 boundary;
# in_authored_scenarios=False; phantom rows after the fence are prose-bucketed;
# checker exits 0 → FAILS.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest D-069-A2: fenced-code heading kills section scope (fixture A2) ──"
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
    # Defect: fenced code block containing '# Example heading'. The heading is inside
    # the fence so it must NOT be treated as a section boundary. Phantom rows after
    # the fence must be caught.
    cat > "$T/.factory/holdout-scenarios/HS-INDEX.md" <<'HSIX_DEFECT'
## Authored Scenarios

| HS ID | EC ID | Title | Notes | BCs | Status |
|-------|-------|-------|-------|-----|--------|
| HS-001 | EC-156 | Selftest scenario | Notes | BC-2.01.001 | active |

```
# Example heading inside fenced code block
```

| HS ID | EC ID | Title | Notes | BCs | Status |
|-------|-------|-------|-------|-----|--------|
| HS-099 | EC-999 | PHANTOM after fenced heading | Notes | BC | active |
HSIX_DEFECT
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-index-integrity.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — fenced '# heading' killed section scope — D-069-A2 not fixed)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; fenced heading treated as code content; phantom rows detected)"
    fi
fi
rm -rf "$T"

# ── Test D-069-A3: 4-space-indented ## kills section scope (fixture A3) ──────
# A line like '    ## foo' is an indented code block in CommonMark, not a heading.
# The prior strip() normalised away the 4-space indent before the startswith("#")
# check, so '    ## foo' appeared as '## foo' and set in_authored_scenarios=False.
# After the D-069 fix, the raw line is checked for 4+ spaces of indent before
# testing _CM_HEADING_RE; indented lines land in the prose bucket.
#
# Mutation-flip: remove the `not raw.startswith("    ")` guard.  The stripped
# line '## foo' is a heading at level 2; in_authored_scenarios=False; phantom
# rows after the indented line are prose-bucketed; checker exits 0 → FAILS.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest D-069-A3: 4-space-indented ## kills section scope (fixture A3) ──"
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
    # Defect: 4-space-indented '    ## indented' (a code block in CommonMark, not a
    # heading). Must NOT set in_authored_scenarios=False. Phantom rows after it
    # must be caught.
    cat > "$T/.factory/holdout-scenarios/HS-INDEX.md" <<'HSIX_DEFECT'
## Authored Scenarios

| HS ID | EC ID | Title | Notes | BCs | Status |
|-------|-------|-------|-------|-----|--------|
| HS-001 | EC-156 | Selftest scenario | Notes | BC-2.01.001 | active |

    ## 4-space-indented: code block, not a heading

| HS ID | EC ID | Title | Notes | BCs | Status |
|-------|-------|-------|-------|-----|--------|
| HS-099 | EC-999 | PHANTOM after indented pseudo-heading | Notes | BC | active |
HSIX_DEFECT
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-index-integrity.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — 4-space indent killed section scope — D-069-A3 not fixed)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; 4-space indented ## treated as prose; phantom rows detected)"
    fi
fi
rm -rf "$T"

# ── Test D-069-B: adjacent-pipe pipeless row uncounted (fixture B / MAJOR-1) ─
# 'HS-099||EC-999' renders as a real GFM table row (verified on GitHub's renderer:
# <td>HS-099</td><td></td><td>EC-999</td>). The prior gate
# re.search(r"[^|]\|[^|]", line) required a non-pipe on BOTH sides of some pipe;
# adjacent '||' has no non-pipe flanking any pipe, so the row was not counted.
# After the D-069 fix, the regex gate is removed entirely: any in-scope non-pipe
# line containing at least one '|' is counted as a data_row candidate; B-9 fires.
#
# Note: this fixture is distinct from B3 (which tests 'HS-042 | EC-999 | ...'
# with spaced pipes — those DO pass the old gate). This test specifically isolates
# the adjacent-pipe gap.
#
# Mutation-flip: re-introduce the re.search(r"[^|]\|[^|]") gate on the pipeless
# path. 'HS-099||EC-999' fails the gate; row not counted; invariant holds;
# checker exits 0 → D-069-B FAILS.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest D-069-B: adjacent-pipe pipeless row uncounted (fixture B) ──"
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
    # Defect: append a pipeless adjacent-pipe row 'HS-099||EC-999'. No EC-999 file.
    # GFM renders this as a real table row. The checker must count it and fire B-9.
    printf 'HS-099||EC-999\n' >> "$T/.factory/holdout-scenarios/HS-INDEX.md"
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-index-integrity.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — adjacent-pipe row 'HS-099||EC-999' dropped uncounted — D-069-B not fixed)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; adjacent-pipe pipeless row correctly counted and detected)"
    fi
fi
rm -rf "$T"

# ── Test D-069-C: unbounded column-header exemption (fixture C / MINOR-1) ────
# The prior _is_column_header() was called on EVERY pending_pre_sep row, not just
# the last. Two consecutive pre-separator rows both with first cell 'HS ID' were
# both silently exempted — including a phantom data row carrying EC-999.
# After the D-069 MINOR-1 fix, only pending_pre_sep[-1] is tested; all earlier
# pending rows go to data_row + _classify(), and B-9 fires on them.
# Note: GFM renders the second '| HS ID | EC-999 |' row as <thead>, not <td>,
# so this is MINOR (blast radius bounded), but it is a measurable regression.
#
# Mutation-flip: call _is_column_header() on ALL pending_pre_sep rows (not just
# [-1]). Both '| HS ID | ... |' rows are exempted; EC-999 is not forward-checked;
# checker exits 0 → D-069-C FAILS.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest D-069-C: unbounded column-header exemption (fixture C / MINOR-1) ──"
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
    # Defect: two consecutive pre-separator rows both with first cell 'HS ID'.
    # The first is a phantom carrying EC-999 (no wave-scenarios file); the second
    # is the real column header. With the MINOR-1 fix, only [-1] (the real header)
    # is exempted; the first goes to data_row and B-9 fires.
    cat > "$T/.factory/holdout-scenarios/HS-INDEX.md" <<'HSIX_DEFECT'
## Authored Scenarios

| HS ID | EC ID | Title | Notes | BCs | Status |
| HS ID | EC-999 | PHANTOM in pre-separator position with HS ID first cell | Notes | BC | active |
|-------|-------|-------|-------|-----|--------|
| HS-001 | EC-156 | Selftest scenario | Notes | BC-2.01.001 | active |
HSIX_DEFECT
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-index-integrity.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — two HS ID pre-separator rows both exempted — D-069-C not fixed)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; only last pre-separator row exempted; phantom row detected)"
    fi
fi
rm -rf "$T"

# ── Test D-070-A: tab-indented heading bypass ─────────────────────────────────
# '\t## X' has a tab as leading whitespace.  CommonMark §2.1 expands tabs at
# 4-column stops, so '\t## X' has 4 columns of indent — the code-block threshold.
# It is NOT an ATX heading.  The prior raw.startswith("    ") check missed this
# because a literal tab is not four ASCII spaces.
# After the D-070 fix, _leading_columns(raw) < 4 catches the tab case:
# _leading_columns("\t## X") == 4, which is NOT < 4, so the line goes to prose.
# Section scope is unchanged; phantom rows after the tab-indented line are caught.
#
# Mutation-flip: replace _leading_columns(raw) < 4 with the old
# not raw.startswith("    ") guard.  '\t## X' passes the startswith test
# (tab != four spaces); _CM_HEADING_RE matches; in_authored_scenarios=False;
# phantom rows after the tab-indented line are prose-bucketed; checker exits 0 -> FAILS.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest D-070-A: tab-indented heading bypass (D-070 regression) ──"
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
    # Defect: tab-indented '\t## heading' before phantom HS-099.
    # Without D-070 fix: startswith("    ") -> False (tab != spaces) ->
    #   _CM_HEADING_RE matches "## ..." -> in_authored_scenarios=False -> HS-099 missed.
    # With D-070 fix: _leading_columns("\t## ...") = 4 -> NOT < 4 -> prose ->
    #   scope stays True -> HS-099 caught; checker exits 1 (phantom EC-999).
    {
        cat <<'HSIX_PART1'
## Authored Scenarios

| HS ID | EC ID | Title | Notes | BCs | Status |
|-------|-------|-------|-------|-----|--------|
| HS-001 | EC-156 | Selftest scenario | Notes | BC-2.01.001 | active |

HSIX_PART1
        printf '\t## tab-indented: code block not heading\n'
        cat <<'HSIX_PART2'

| HS ID | EC ID | Title | Notes | BCs | Status |
|-------|-------|-------|-------|-----|--------|
| HS-099 | EC-999 | PHANTOM after tab-indented heading | Notes | BC | active |
HSIX_PART2
    } > "$T/.factory/holdout-scenarios/HS-INDEX.md"
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-index-integrity.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — tab-indented heading killed section scope — D-070-A not fixed)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; tab-indented heading treated as prose; phantom row detected)"
    fi
fi
rm -rf "$T"

# ── Test D-070-B: indented-fence bypass ───────────────────────────────────────
# A fence indented 4+ spaces is an indented code block per CommonMark §4.5,
# NOT a fenced-code-block delimiter.  The prior code did not check indent before
# applying _FENCE_RE, so '      ```' (6 spaces) opened a fenced_code sink
# unbounded.  Lines after the indented fence were bucketed as fenced_code and
# never seen as HS candidates; B-9 did not fire; the checker exited 0.
# After the D-070 fix, _leading_columns(raw) < 4 guards the fence check:
# _leading_columns("      ```") == 6, NOT < 4, so the line goes to prose.
# Subsequent HS rows are processed normally; phantom EC-999 is caught.
#
# Mutation-flip: remove the _leading_columns guard from the _FENCE_RE check.
# '      ```' passes _FENCE_RE; in_fenced_code=True; HS-099 bucketed as
# fenced_code; never in hs_rows_seen; B-9 does not fire; checker exits 0 -> FAILS.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest D-070-B: indented-fence bypass (D-070 regression) ──"
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
    # Defect: 6-space-indented ``` before phantom HS-099.
    # CommonMark §4.5: 4+ columns of indent = indented code block, not a fence.
    # Without D-070 fix: _FENCE_RE matches stripped "```" -> in_fenced_code=True ->
    #   HS-099 bucketed as fenced_code -> never in hs_rows_seen -> B-9 silent ->
    #   checker exits 0 (phantom missed).
    # With D-070 fix: _leading_columns("      ```") = 6 -> NOT < 4 -> prose ->
    #   HS-099 is a post-separator data_row -> caught; checker exits 1.
    cat > "$T/.factory/holdout-scenarios/HS-INDEX.md" <<'HSIX_DEFECT'
## Authored Scenarios

| HS ID | EC ID | Title | Notes | BCs | Status |
|-------|-------|-------|-------|-----|--------|
| HS-001 | EC-156 | Selftest scenario | Notes | BC-2.01.001 | active |

      ```

| HS ID | EC ID | Title | Notes | BCs | Status |
|-------|-------|-------|-------|-----|--------|
| HS-099 | EC-999 | PHANTOM inside indented fake fence | Notes | BC | active |

      ```
HSIX_DEFECT
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-index-integrity.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — indented fence opened fenced_code sink — D-070-B not fixed)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; indented fence treated as prose; phantom row detected)"
    fi
fi
rm -rf "$T"

# ── Test NV-1: check-placeholders — em-dash in VP-NNN column (R2-RULE) ────────
# The old TEST_SUFFICIENT_IN_VP_COL predicate was a value-blacklist anchored on
# one literal spelling ("test-sufficient") — a class that was already dead (0
# occurrences in live tree) while em-dash U+2014 (55 occurrences) sailed through.
# R2-RULE inverts the predicate to a shape-whitelist: any first cell in a VP-NNN-
# headed table that is NOT a VP-\d{3} or VP-NONE sentinel is a POL-14 violation.
#
# Clean tree contains good-placeholder-vp-column.md — the NV-2 FP anti-vector —
# so the clean-pass step simultaneously proves:
#   (a) the em-dash defect is not in the clean tree, AND
#   (b) legitimate em-dashes (prose, non-VP tables, multi-VP cells, fenced template)
#       are NOT flagged — the false-positive guard (NV-2) is part of the clean step.
#
# Mutation-flip: revert R2-RULE to TEST_SUFFICIENT_IN_VP_COL. The em-dash in
# bad-placeholder-vp-emdash.md passes the old predicate; checker exits 0 → FAILS.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest NV-1: check-placeholders: em-dash in VP-NNN column (R2-RULE) ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"

# Clean tree uses good-placeholder-vp-column.md (the NV-2 FP anti-vector):
# legitimate em-dash in prose + Property column, multi-VP cell, non-VP table
# em-dashes, and a fenced-block template — all must remain unflagged.
cp "$FIXTURE_DIR/good-placeholder-vp-column.md" \
    "$T/.factory/specs/behavioral-contracts/ss-01/SELFTEST-good-vp.md"

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean tree (good-placeholder-vp-column.md)"
    echo "  This file contains ONLY legitimate em-dash uses; R2-RULE must not flag them."
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Inject the defect: VP-NNN table data row with em-dash as first cell
    cp "$FIXTURE_DIR/bad-placeholder-vp-emdash.md" \
        "$T/.factory/specs/behavioral-contracts/ss-01/SELFTEST-vp-emdash.md"
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch em-dash in VP-NNN column)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed with FP-guard; em-dash in VP-NNN column correctly detected)"
    fi
fi
rm -rf "$T"

# ── Test NV-3: check-id-resolution — non-conforming EC ID shape (R3-A) ────────
# EC-NEW-1 in an Edge Cases table first cell was invisible to the checker because
# r"\bEC-(\d+)([a-z]?)\b" requires digits immediately after EC-, and "N" is not
# a digit. The entire token was lexically absent from the match set.
# R3-A (positional): first cell of EC/ID-column table must match ^~?~?EC-\d{1,4}[a-z]?~?~?$.
#
# Clean tree uses good-ec-historical-changelog.md (the NV-5 FP anti-vector):
# historical changelog EC-NEW-3 (R3-C scoped out), metasyntax (EC-NNN, VP-NNN etc.),
# BC-to / VP-to / BC-H1 prose compounds — all must remain unflagged.
#
# Mutation-flip: revert R3-A (remove EC/ID-column table tracking). EC-NEW-1 is
# invisible to the existing r"\bEC-(\d+)([a-z]?)\b" scanner; checker exits 0 → FAILS.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest NV-3: check-id-resolution: non-conforming EC ID in ID column (R3-A) ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/prd-supplements"
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"
# EC-001 must be registered so that conforming rows in the defect fixture do not fire
printf '| TV-001 | EC-001 | `a.md` | clean | 0 | clean | no-reason |\n' \
    > "$T/.factory/specs/prd-supplements/test-vectors.md"

# Clean tree: good-ec-historical-changelog.md — the NV-5 FP anti-vector.
# Contains: historical EC-NEW-3 in changelog (must NOT fire R3-B via R3-C),
# metasyntax tokens (EC-NNN, VP-NNN, DD-NNN), prose compounds (BC-H1, BC-to),
# and a conforming EC-001 table row.  All must exit 0.
cp "$FIXTURE_DIR/good-ec-historical-changelog.md" \
    "$T/.factory/specs/behavioral-contracts/ss-01/SELFTEST-good-ec.md"

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-id-resolution.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean tree (good-ec-historical-changelog.md)"
    echo "  This file contains ONLY conforming/historical EC references; none must be flagged."
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Inject the defect: EC-NEW-1 in the first cell of an EC-column table row
    cp "$FIXTURE_DIR/bad-ec-nonconforming-shape.md" \
        "$T/.factory/specs/behavioral-contracts/ss-01/SELFTEST-ec-shape.md"
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-id-resolution.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch EC-NEW-1 in ID column)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed with FP-guard; non-conforming EC-NEW-1 correctly detected)"
    fi
fi
rm -rf "$T"

# ── Test NV-4: check-id-resolution — class-level non-conforming ID shapes (R3-B) ─
# D-069 class-closure vector. NV-3 alone could be satisfied by a checker hardcoding
# "EC-NEW-". This test uses EC-DRAFT-7 and DI-PENDING-2 — tokens absent from the
# entire repo — so a hardcoded "EC-NEW-" check exits 0 and the test FAILS (correctly).
# R3-B grammar: \b(CAP|...|EC)-[A-Za-z][A-Za-z0-9]*-\d+\b — no mention of "NEW".
#
# Two findings are required:
#   1. non-conforming EC ID in ID column 'EC-DRAFT-7'  (R3-A, table-positional)
#   2. non-conforming DI ID shape 'DI-PENDING-2'        (R3-B, prose-lexical)
# Both messages must be present; checking only exit code would admit a single-family
# hardcode that catches one but not the other.
#
# Mutation-flip: revert R3-B to only EC family. DI-PENDING-2 is not caught; only
# one message emitted; the DI-PENDING-2 assertion fails → NV-4 FAILS (correctly).
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest NV-4: check-id-resolution: class-level non-conforming ID shapes (R3-B) ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/prd-supplements"
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"
printf '| TV-001 | EC-001 | `a.md` | clean | 0 | clean | no-reason |\n' \
    > "$T/.factory/specs/prd-supplements/test-vectors.md"

# Clean tree: same FP anti-vector as NV-3 (good-ec-historical-changelog.md)
cp "$FIXTURE_DIR/good-ec-historical-changelog.md" \
    "$T/.factory/specs/behavioral-contracts/ss-01/SELFTEST-good-ec.md"

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-id-resolution.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean tree (good-ec-historical-changelog.md)"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Inject generic defect: EC-DRAFT-7 (EC-column first cell) + DI-PENDING-2 (prose)
    cp "$FIXTURE_DIR/bad-ec-nonconforming-shape-generic.md" \
        "$T/.factory/specs/behavioral-contracts/ss-01/SELFTEST-ec-generic.md"
    NV4_OUTPUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-id-resolution.py" 2>&1)
    NV4_EXIT=$?
    if [ "$NV4_EXIT" -eq 0 ]; then
        echo "  FAIL (checker returned 0 — did NOT detect any non-conforming ID shapes)"
        FAILURES=$((FAILURES + 1))
    elif echo "$NV4_OUTPUT" | grep -qF "EC-DRAFT-7" && echo "$NV4_OUTPUT" | grep -qF "DI-PENDING-2"; then
        echo "  PASS (clean-pass confirmed; both EC-DRAFT-7 and DI-PENDING-2 non-conforming shapes detected)"
    else
        echo "  FAIL (checker exited non-zero but expected both EC-DRAFT-7 and DI-PENDING-2 in output)"
        echo "  Actual output:"
        echo "$NV4_OUTPUT" | sed 's/^/    /'
        FAILURES=$((FAILURES + 1))
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
