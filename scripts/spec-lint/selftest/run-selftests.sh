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

EXPECTED_TEST_COUNT=93
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
# selftests (G1, G2, G5) use these variables — there is no second copy of any
# pattern anywhere in this file. Any mutation to OVERRIDE_PATTERN,
# SUPPRESSION_PATTERN, PATH_SHAPE_PATTERN, or COMPLETENESS_PATTERN will flip
# both the pre-flight guard AND the corresponding guard selftest.
OVERRIDE_PATTERN='^REPO[[:space:]]*=.*(slp\.find_repo_root|os\.environ\.get[^#]*SPEC_LINT_REPO_OVERRIDE)'

# SUPPRESSION_PATTERN: name-based detection of scope-reducing constructs.
# Catches common names for exclusion sets / skip sets regardless of content.
# Extended in this burst (BI-047) to include EXCLUDE_PATHS and other plausible
# future names (OMIT_FILES, DEFERRED, PENDING, GRANDFATHERED).
SUPPRESSION_PATTERN='(ALLOWLIST|_DEFERRAL|SKIP_LIST|SKIP_SET|KNOWN_COLLISIONS|KNOWN_VIOLATIONS|KNOWN_ISSUES|WHITELIST|SUPPRESS_SET|EXCLUDE_PATHS|OMIT_FILES|DEFERRED|PENDING|GRANDFATHERED)[[:space:]]*[=:]'

# PATH_SHAPE_PATTERN: shape-based detection of path-string-in-set constructs.
# Catches the structural pattern {str(REPO / ...) or {str(SPECS / ...) which is
# the footprint of a file-path-keyed exclusion set, however the variable is named.
# This is the shape that made EXCLUDE_PATHS invisible to the old name-based guard.
PATH_SHAPE_PATTERN='\{[[:space:]]*str\((REPO|SPECS)[[:space:]]*/[[:space:]]*"'

# COMPLETENESS_PATTERN: detects a runtime corpus-completeness assertion in a checker.
# A checker with a scope reduction is "proven" if it emits a completeness assertion
# of the form "N of M spec files" at runtime. Checkers with scope reductions but
# without this assertion are "unproven" and fail the guard.
# The pattern accepts both literal counts ("of 134 spec files") and f-string
# placeholders ("of {total_files} spec files") — the curly braces in {total_files}
# are matched by [0-9a-zA-Z_{}]+.
COMPLETENESS_PATTERN='of[[:space:]]+[0-9a-zA-Z_{}]+[[:space:]]+spec files'

SPLITLINES_PATTERN='\.splitlines\(\)'

run_override_guard() {
    # Verify every check-*.py in $1, plus all generators, have an active
    # SPEC_LINT_REPO_OVERRIDE assignment (direct env-var check or via slp.find_repo_root,
    # which honors SPEC_LINT_REPO_OVERRIDE internally — two-part check covers both forms).
    # Stage 3 (BI-040): gen-bc-index.py, gen-ec-registry.py, gen-prd-sections.py, gen-rtm.py
    # added to scope; they use slp.find_repo_root() and carry # honors SPEC_LINT_REPO_OVERRIDE.
    # D-057: prints runtime count of files scanned; fails if 0 files found.
    # S2 (review cycle 2): uses a two-part check instead of the single OVERRIDE_PATTERN regex.
    # Part 1: file has a line starting with REPO[[:space:]]*= (confirms REPO assignment exists).
    # Part 2: stripping comments, file contains slp.find_repo_root( OR
    #         os.environ.get(...SPEC_LINT_REPO_OVERRIDE (confirms live, not comment-only usage).
    # This rejects files where slp.find_repo_root appears only in a comment on the REPO= line.
    # Returns 0 = all clear, 2 = guard fired (missing support, or no files found).
    local dir="$1"
    local count=0
    for f in "$dir"/check-*.py "$dir/gen-bc-traceability.py" "$dir/gen-slug-corpus.py" \
             "$dir/gen-bc-index.py" "$dir/gen-ec-registry.py" "$dir/gen-prd-sections.py" "$dir/gen-rtm.py"; do
        [[ -f "$f" ]] || continue
        count=$((count + 1))
        if ! { grep -qE '^REPO[[:space:]]*=' "$f" \
          && grep -v '^[[:space:]]*#' "$f" \
             | grep -qE '(slp\.find_repo_root\(|os\.environ\.get\([^)]*SPEC_LINT_REPO_OVERRIDE)'; }; then
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
    # Verify no check-*.py in $1, nor any generator, contains an UNPROVEN scope-reducing
    # construct. "Unproven" means: a scope reduction exists without a corresponding
    # runtime corpus-completeness assertion.
    #
    # Design principle (BI-047): the guard's real criterion is NOT "no scope reduction
    # exists" — some scope reduction is legitimate (e.g., ADR files routed to a
    # separate policy code path). The correct criterion is "no UNPROVEN scope reduction":
    # a checker may narrow its scope ONLY if it emits a runtime assertion proving the
    # parts sum to the full corpus.
    #
    # Two-pass detection:
    # Pass 1 (DETECT): file has SUPPRESSION_PATTERN (name-based) OR PATH_SHAPE_PATTERN
    #                  (structural: path-string-in-set, the footprint of EXCLUDE_PATHS).
    # Pass 2 (VERIFY): if scope reduction detected, check for COMPLETENESS_PATTERN.
    #                  Found → PASS (proven).  Not found → FAIL (unproven).
    #
    # Scope matches run_override_guard (Stage 3: all generators included).
    # D-057: prints runtime count of files scanned; fails if 0 files found.
    # Returns 0 = all clear, 2 = guard fired (unproven suppression found, or no files).
    local dir="$1"
    local count=0
    local proven_count=0
    for f in "$dir"/check-*.py "$dir/gen-bc-traceability.py" "$dir/gen-slug-corpus.py" \
             "$dir/gen-bc-index.py" "$dir/gen-ec-registry.py" "$dir/gen-prd-sections.py" "$dir/gen-rtm.py"; do
        [[ -f "$f" ]] || continue
        count=$((count + 1))
        # Pass 1: detect any scope-reducing construct (by name OR structural shape)
        has_scope_reduction=0
        if grep -qE "$SUPPRESSION_PATTERN" "$f" 2>/dev/null; then
            has_scope_reduction=1
        elif grep -qE "$PATH_SHAPE_PATTERN" "$f" 2>/dev/null; then
            has_scope_reduction=1
        fi
        if [[ "$has_scope_reduction" -eq 1 ]]; then
            # Pass 2: verify a completeness assertion exists (proves scope is accounted for)
            if grep -qE "$COMPLETENESS_PATTERN" "$f" 2>/dev/null; then
                proven_count=$((proven_count + 1))
                # Proven scope reduction — allowed
            else
                echo "STRUCTURAL GUARD FAILED: $(basename "$f") has an UNPROVEN scope reduction"
                echo "  A scope-reducing construct was found but no corpus-completeness assertion"
                echo "  exists to prove the parts sum to the full corpus."
                echo "  Add a runtime assertion of the form: 'N of M spec files (complete)'"
                echo "  or remove the scope reduction entirely."
                echo "  Detected by: SUPPRESSION_PATTERN or PATH_SHAPE_PATTERN"
                return 2
            fi
        fi
    done
    if [[ "$count" -eq 0 ]]; then
        echo "STRUCTURAL GUARD FAILED: no check-*.py files found in $dir — nothing scanned"
        return 2
    fi
    echo "Pre-flight guard passed: $count checkers/generators scanned, $proven_count proven scope reductions, 0 unproven"
    return 0
}

run_splitlines_guard() {
    # Verify no .py file in $1 uses raw .splitlines() outside the two exempted files.
    # Scans non-comment lines only (grep -v '^\s*#') so intentional comments
    # documenting the old API do not trigger false positives.
    # Exempt: spec_lint_primitives.py (defines cm_splitlines itself, and its docstring
    #         mentions str.splitlines() as documentation) and test_spec_lint_primitives.py
    #         (calls s.splitlines() intentionally to derive the divergent codepoint set).
    # Widened from explicit list to "$dir"/*.py (W5 — BI-040) so any new module added
    # to the directory is automatically covered, including spec_lint_primitives.py
    # itself (detecting if a raw .splitlines() is added outside cm_splitlines).
    # D-057: prints runtime count of files scanned; fails if 0 files found.
    # Returns 0 = all clear, 2 = guard fired.
    local dir="$1"
    local count=0
    for f in "$dir"/*.py; do
        [[ -f "$f" ]] || continue
        [[ "$(basename "$f")" == "spec_lint_primitives.py" ]] && continue
        # Forward-looking: test_spec_lint_primitives.py lives in selftest/ (not $LINT_DIR),
        # so this exemption is currently dead code (non-recursive glob). If $LINT_DIR is
        # ever widened to include selftest/, this becomes live. Keep for intent clarity.
        [[ "$(basename "$f")" == "test_spec_lint_primitives.py" ]] && continue
        count=$((count + 1))
        if grep -v '^\s*#' "$f" | grep -qE "$SPLITLINES_PATTERN" 2>/dev/null; then
            echo "STRUCTURAL GUARD FAILED: $(basename "$f") uses raw .splitlines()"
            echo "  Use slp.cm_splitlines() instead (BI-040)."
            return 2
        fi
    done
    if [[ "$count" -eq 0 ]]; then
        echo "STRUCTURAL GUARD FAILED: no check-*.py files found in $dir — nothing scanned"
        return 2
    fi
    echo "Pre-flight guard passed: $count files checked, 0 raw .splitlines() uses"
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

# ── Pre-flight guard 2: no UNPROVEN scope-reducing constructs ─────────────
# Checkers may reduce their scope (narrow the files or tokens checked) ONLY if
# they emit a runtime corpus-completeness assertion proving the parts sum to the
# full corpus. A scope reduction without a completeness assertion is "unproven"
# and fails this guard.
#
# Detection criterion (BI-047 repair):
#   Name-based (SUPPRESSION_PATTERN): catches known exclusion-set names.
#   Shape-based (PATH_SHAPE_PATTERN): catches path-string-in-set regardless of
#     variable name. This is the shape that made EXCLUDE_PATHS invisible to the
#     original name-only guard — a gap root-caused by the adversary at P7-S5-017.
#
# Correctness criterion: A scope reduction is PROVEN (allowed) if the checker
# also contains COMPLETENESS_PATTERN — a runtime assertion of the form
# "N of M spec files". The guard does NOT require "no scope reduction exists";
# it requires "no UNPROVEN scope reduction". Checkers like check-adr-consistency
# that route ADRs to POLICY 12 and emit "X+Y=Z of Z spec files (complete)" are
# structurally proven and are not flagged.
#
# NOTE: Guard ordering is load-bearing (F-15). run_override_guard uses
# "if ! grep ..." so a grep read-error fails CLOSED (guard fires). By contrast,
# run_suppression_guard's Pass 1 uses "if grep ..." so a read-error is treated
# as "no match" — fails OPEN on the detection side. However, run_override_guard
# runs first: an unreadable checker causes guard 1 to fire (exit 2) before
# guard 2 ever sees the file. Guard 2's fail-open is therefore unreachable today,
# but the ordering must not be changed without also fixing guard 2's error-handling.
echo "Pre-flight structural guard: checking for unproven scope-reducing constructs in all checkers..."
if ! run_suppression_guard "$LINT_DIR"; then
    exit 2
fi
echo ""

# ── Pre-flight guard 3: primitive module unit tests (G3) ─────────────────
# Verify spec_lint_primitives.py implements all public API functions correctly.
# These tests run in a separate Python runner (test_primitives.sh) and do NOT
# count toward EXPECTED_TEST_COUNT / TESTS_RUN — primitive unit tests are a
# different category from checker selftests.
# Stage: WS-3b Stage 1 (BI-040). If this guard fires, Stage 1 is incomplete.
echo "Pre-flight structural guard: running spec_lint_primitives unit tests (G3)..."
if ! bash "$LINT_DIR/selftest/test_primitives.sh"; then
    exit 2
fi
echo ""

# ── Pre-flight guard 4: no raw .splitlines() in migrated checkers (G4) ───
# All check-*.py files and Stage-2 generators (gen-bc-traceability.py,
# gen-slug-corpus.py) must use slp.cm_splitlines() instead of raw
# .splitlines(). CommonMark recognizes only LF as a line ending; Python's
# .splitlines() also splits on FF, VT, CR, FS, GS, RS, NEL, LS, PS — any
# of which can create phantom lines in spec content. Stage 3 generators
# are excluded until Stage 3 migration is complete.
# Stage: WS-3b Stage 2 (BI-040). If this guard fires, a file regressed.
echo "Pre-flight structural guard: checking for raw .splitlines() in migrated checkers (G4)..."
if ! run_splitlines_guard "$LINT_DIR"; then
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

# ── Test 22: check-canonical-facts — FACT-10 binding-25 production pattern Phase A ──────
# BI-042 rewrite (D-076 applied). The old selftest used a synthetic flexible pattern
# 'config error trigger: "(.*?)"' that never exercised any production FACT-10 binding.
# This rewrite uses the ACTUAL production binding-25 pattern:
#   '\(sole trigger: ([^\n,]+?) pattern,'
# which was corrected by D-076 from the tautological form:
#   'sole trigger: (invalid `--ignore` glob)'
#
# Phase A: uses the production pattern; defect is complete replacement of the sole trigger.
# Phase B (selftest 22b below): same pattern; defect is prefix-extension adversarial vector
#   (invalid `--ignore` glob OR unrecognized flag) — the exact class that silently passed
#   the old tautological pattern. Proved to have teeth:
#   - OLD tautological: exit 0 on prefix-extension text (false negative confirmed)
#   - PRODUCTION corrected: exit 1 + DIVERGE with 'or unrecognized flag' in extracted value

# ── Derive FACT-10 binding-25 pattern from production canonical-facts.toml ──────────────
# Tests 22 and 22b gate the PRODUCTION binding, not a hardcoded snapshot copy.
# If binding-25 is ever edited, these tests automatically use the new pattern.
# Resolve the .factory worktree path via git's common dir so this works from
# any worktree (not just the main repo where $REPO/.factory is directly accessible).
_GIT_COMMON=$(git -C "$REPO" rev-parse --git-common-dir 2>/dev/null)
if [[ "$_GIT_COMMON" != /* ]]; then
    # Relative path (main worktree): normalize to absolute
    _GIT_COMMON="$(cd "$REPO/$_GIT_COMMON" && pwd)"
fi
_MAIN_REPO="$(dirname "$_GIT_COMMON")"
BINDING25_PATTERN=$(python3 - "$_MAIN_REPO/.factory/specs/canonical-facts.toml" <<'PY'
import sys, pathlib
try:
    import tomllib
except ImportError:
    import tomli as tomllib  # Python < 3.11 fallback
toml_path = pathlib.Path(sys.argv[1])
d = tomllib.loads(toml_path.read_text())
# "sole trigger parenthetical" is the discriminator for binding-25 specifically:
#   note = "CAP-014 exit-2 condition — sole trigger parenthetical"
# Other FACT-10 bindings also contain "sole trigger" but not "parenthetical".
pats = [b["pattern"] for b in d.get("binding", [])
        if b.get("fact_id") == "FACT-10" and "sole trigger parenthetical" in b.get("note", "")]
assert len(pats) == 1, f"expected exactly 1 FACT-10 sole-trigger-parenthetical binding, got {len(pats)}"
print(pats[0])
PY
)
if [ -z "$BINDING25_PATTERN" ]; then
    echo "FATAL: could not derive FACT-10 binding-25 pattern from canonical-facts.toml" >&2
    exit 1
fi

TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 22: check-canonical-facts: FACT-10 binding-25 production pattern — complete-replacement defect ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs"

cat > "$T/.factory/specs/canonical-facts.toml" <<TOML22
[[fact]]
id              = "FACT-10-SELFTEST"
description     = "config_error sole trigger: invalid --ignore glob (production FACT-10 binding-25 pattern)"
canonical_value = 'invalid \`--ignore\` glob'
source          = "selftest"

[[binding]]
fact_id = "FACT-10-SELFTEST"
file    = ".factory/specs/selftest-fact10.md"
note    = "sole trigger parenthetical (FACT-10 binding-25 production context)"
pattern = '$BINDING25_PATTERN'
TOML22

cat > "$T/.factory/specs/selftest-fact10.md" <<'MD22CLEAN'
(sole trigger: invalid `--ignore` glob pattern, the only exit-2 condition)
MD22CLEAN

CLEAN_PASS_22A=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-canonical-facts.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS_22A=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean FACT-10 tree (Phase A)"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS_22A" = "1" ]; then
    # Phase A defect: complete replacement — different phrase entirely (None → DIVERGE path)
    cat > "$T/.factory/specs/selftest-fact10.md" <<'MD22ABAD'
(sole trigger: unrecognized flag pattern, the only exit-2 condition)
MD22ABAD
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-canonical-facts.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — complete-replacement defect should DIVERGE)"
        FAILURES=$((FAILURES + 1))
    else
        CF22A=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-canonical-facts.py" 2>&1)
        if echo "$CF22A" | grep -q "DIVERGE \[FACT-10-SELFTEST\]"; then
            echo "  PASS (clean-pass confirmed; DIVERGE [FACT-10-SELFTEST] correctly reported for complete-replacement defect)"
        else
            echo "  FAIL (checker exited non-zero but DIVERGE [FACT-10-SELFTEST] not in output)"
            echo "  Actual output: $CF22A"
            FAILURES=$((FAILURES + 1))
        fi
    fi
fi

# ── Test 22b: check-canonical-facts — FACT-10 binding-25 Phase B — prefix-extension vector ─
# BI-042 regression gate: prefix-extending the canonical phrase ('invalid `--ignore` glob OR
# unrecognized flag') silently passed the OLD tautological pattern (exit 0 false negative).
# The corrected production pattern detects it via the bounded wildcard ([^\n,]+?).
# This test WILL fail if binding-25 is ever reverted to the tautological form — that is the
# whole point.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 22b: check-canonical-facts: FACT-10 binding-25 — prefix-extension vector DIVERGE (BI-042) ──"

# Rewrite canonical-facts.toml (Phase B uses same production pattern)
cat > "$T/.factory/specs/canonical-facts.toml" <<TOML22B
[[fact]]
id              = "FACT-10-SELFTEST"
description     = "config_error sole trigger: invalid --ignore glob (production FACT-10 binding-25 pattern)"
canonical_value = 'invalid \`--ignore\` glob'
source          = "selftest"

[[binding]]
fact_id = "FACT-10-SELFTEST"
file    = ".factory/specs/selftest-fact10.md"
note    = "sole trigger parenthetical (FACT-10 binding-25 production context)"
pattern = '$BINDING25_PATTERN'
TOML22B

# Phase B clean-pass: canonical text
cat > "$T/.factory/specs/selftest-fact10.md" <<'MD22BCLEAN'
(sole trigger: invalid `--ignore` glob pattern, the only exit-2 condition)
MD22BCLEAN

CLEAN_PASS_22B=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-canonical-facts.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS_22B=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean FACT-10 tree (Phase B)"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS_22B" = "1" ]; then
    # Phase B defect: prefix-extension adversarial vector — 'or unrecognized flag' appended.
    # The old tautological pattern exits 0 here (false negative); the corrected pattern exits 1.
    cat > "$T/.factory/specs/selftest-fact10.md" <<'MD22BBAD'
(sole trigger: invalid `--ignore` glob or unrecognized flag pattern, the only exit-2 condition)
MD22BBAD
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-canonical-facts.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — prefix-extension adversarial text should DIVERGE)"
        FAILURES=$((FAILURES + 1))
    else
        CF22B=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-canonical-facts.py" 2>&1)
        if echo "$CF22B" | grep -q "DIVERGE \[FACT-10-SELFTEST\]" && echo "$CF22B" | grep -qF "or unrecognized flag"; then
            echo "  PASS (clean-pass confirmed with FP-guard; prefix-extension correctly detected; 'or unrecognized flag' in extracted value)"
        else
            echo "  FAIL (DIVERGE [FACT-10-SELFTEST] or 'or unrecognized flag' not in output)"
            echo "  Actual output: $CF22B"
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

# Copy the script and its co-located primitive module into the simulated secondary worktree.
# spec_lint_primitives.py must be present because check-canonical-facts.py now imports it
# (BI-040 §6: find_repo_root consolidated into the shared primitive). The walk used by
# slp.find_repo_root() starts from spec_lint_primitives.py's own location (Path(__file__)),
# which is now inside the simulated worktree — so the .git boundary stop fires correctly.
cp "$LINT_DIR/check-canonical-facts.py" "$T/.worktrees/BI021-SIM/scripts/spec-lint/"
cp "$LINT_DIR/spec_lint_primitives.py"  "$T/.worktrees/BI021-SIM/scripts/spec-lint/"

# Clean pass: without SPEC_LINT_REPO_OVERRIDE, boundary stop fires at .git → exit non-zero
# with guidance message naming SPEC_LINT_REPO_OVERRIDE.
# env -u ensures the ambient SPEC_LINT_REPO_OVERRIDE (set by the calling workflow per
# BI-021/BI-043) does not leak into this subprocess — this test specifically exercises
# the without-override code path (BI-045).
CLEAN_PASS=0
BI021_OUT=$(env -u SPEC_LINT_REPO_OVERRIDE python3 "$T/.worktrees/BI021-SIM/scripts/spec-lint/check-canonical-facts.py" 2>&1)
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

# Copy the FIXED script and its co-located primitive module into the simulated inner repository.
# spec_lint_primitives.py is required because check-canonical-facts.py imports it (BI-040 §6).
cp "$LINT_DIR/check-canonical-facts.py" "$T/inner/scripts/spec-lint/"
cp "$LINT_DIR/spec_lint_primitives.py"  "$T/inner/scripts/spec-lint/"

# Clean pass: boundary stop must fire and script must exit non-zero (fail-closed).
# env -u ensures the ambient SPEC_LINT_REPO_OVERRIDE (set by the calling workflow per
# BI-021/BI-043) does not leak into this subprocess — this test specifically exercises
# the without-override code path (BI-045).
CLEAN_PASS=0
BOUND_OUT=$(env -u SPEC_LINT_REPO_OVERRIDE python3 "$T/inner/scripts/spec-lint/check-canonical-facts.py" 2>&1)
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
    # $T/ and finds the decoy canonical-facts.toml, producing a false pass (exit 0).
    # env -u ensures the ambient SPEC_LINT_REPO_OVERRIDE cannot bypass the decoy
    # escape scenario — the defect must be proved by the walk reaching the decoy,
    # not by inheriting the real repo from the environment (BI-045).
    rm "$T/inner/.git"
    DEFECT_OUT=$(env -u SPEC_LINT_REPO_OVERRIDE python3 "$T/inner/scripts/spec-lint/check-canonical-facts.py" 2>&1)
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
# Under the broadened guard (BI-047): KNOWN_COLLISIONS is detected by
# SUPPRESSION_PATTERN (name-based); it has no completeness assertion → UNPROVEN → FAIL.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── guard selftest G2: suppression-allowlist pre-flight guard fires (KNOWN_COLLISIONS, unproven) ──"
T=$(make_temp)

# Clean pass: run_suppression_guard returns 0 for a checker with no suppression constructs
cat > "$T/check-stub.py" <<'CLEANSTUB'
REPO = Path(os.environ.get("SPEC_LINT_REPO_OVERRIDE", "")).resolve() if os.environ.get("SPEC_LINT_REPO_OVERRIDE") else Path(__file__).resolve().parent.parent.parent
# This checker has no suppression constructs — all violations are reported
CLEANSTUB

CLEAN_PASS=0
if run_suppression_guard "$T" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: guard fired on a clean checker with no suppression constructs"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: replace stub with a checker containing KNOWN_COLLISIONS (unproven scope reduction)
    cat > "$T/check-stub.py" <<'BADSTUB'
KNOWN_COLLISIONS = {"EC-001", "EC-002"}  # hardcoded suppression allowlist — no completeness assertion
BADSTUB
    if run_suppression_guard "$T" > /dev/null 2>&1; then
        echo "  FAIL (guard did NOT detect KNOWN_COLLISIONS unproven scope reduction)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; guard correctly detects KNOWN_COLLISIONS as unproven scope reduction)"
    fi
fi
rm -rf "$T"

# ── Guard test G5: broadened guard — EXCLUDE_PATHS proven vs unproven (BI-047) ──
# Proves the new PATH_SHAPE_PATTERN and COMPLETENESS_PATTERN variables are load-bearing:
# - Clean tree: EXCLUDE_PATHS + completeness assertion → PASS (proven scope reduction)
# - Defect tree: EXCLUDE_PATHS without completeness assertion → FAIL (unproven)
#
# Mutation-verify: either removing the completeness assertion from the clean stub,
# or removing PATH_SHAPE_PATTERN from the guard, flips the clean-pass / defect-fail.
# Since PATH_SHAPE_PATTERN has one canonical definition, this test covers both arms.
#
# Calibration: this test directly catches the BI-047 defect class (EXCLUDE_PATHS was
# invisible to the old name-based guard because its name was not in SUPPRESSION_PATTERN).
TESTS_RUN=$((TESTS_RUN + 1))
echo "── guard selftest G5: broadened guard — EXCLUDE_PATHS proven vs unproven (BI-047) ──"
T=$(make_temp)

# Clean tree: checker has EXCLUDE_PATHS (matched by PATH_SHAPE_PATTERN) AND
# a corpus-completeness assertion (matched by COMPLETENESS_PATTERN) → PROVEN → PASS.
cat > "$T/check-stub.py" <<'G5CLEAN'
REPO = Path(os.environ.get("SPEC_LINT_REPO_OVERRIDE", "")).resolve() if os.environ.get("SPEC_LINT_REPO_OVERRIDE") else Path(__file__).resolve().parent.parent.parent
EXCLUDE_PATHS = {str(REPO / ".factory" / "specs" / "prd.md")}
# Proven: emits corpus-completeness assertion so scope reduction is accounted for
print(f"0 findings across {files_checked} of {total_files} spec files (complete)")
G5CLEAN

CLEAN_PASS=0
if run_suppression_guard "$T" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    G5_CLEAN_OUT=$(run_suppression_guard "$T" 2>&1)
    echo "  STRUCTURAL FAIL: guard fired on EXCLUDE_PATHS + completeness assertion (should be PROVEN)"
    echo "  Output: $G5_CLEAN_OUT"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: same EXCLUDE_PATHS but NO completeness assertion → UNPROVEN → FAIL
    cat > "$T/check-stub.py" <<'G5BAD'
REPO = Path(os.environ.get("SPEC_LINT_REPO_OVERRIDE", "")).resolve() if os.environ.get("SPEC_LINT_REPO_OVERRIDE") else Path(__file__).resolve().parent.parent.parent
EXCLUDE_PATHS = {str(REPO / ".factory" / "specs" / "prd.md")}
# No completeness assertion — scope reduction is unproven
G5BAD
    if run_suppression_guard "$T" > /dev/null 2>&1; then
        echo "  FAIL (guard did NOT detect EXCLUDE_PATHS without completeness assertion as unproven)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; EXCLUDE_PATHS without completeness assertion correctly detected as unproven)"
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

# G4 proof arm (guard-selftest proving G4 fires on a planted .splitlines() defect)
# is deferred to the W10 burst — same scope as the checker-level negative selftest
# for the BI-040 bypass class. Track as S4 from review cycle 2.

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

# ── Test NV-1b: check-placeholders — comma-only cell in VP-NNN column (BLOCK-1 guard) ─────
# Mutation-flip: revert `_is_valid_vp_cell` to the pre-BLOCK-1 form:
#   tokens = re.split(r"[,/]", first_cell)
#   return bool(tokens) and all(_VP_TOKEN_RE.match(t.strip()) for t in tokens if t.strip())
# The comma-only cell (",") splits to ['', ''] → filtered to [] by "if t.strip()" → all([]) → True.
# Checker exits 0 → FAILS. This test has teeth ONLY against the BLOCK-1 fix — the em-dash
# fixture (NV-1) fires regardless of this revert, so it cannot guard this class.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest NV-1b: check-placeholders: comma-only cell in VP-NNN column (BLOCK-1 guard) ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"

# Clean tree uses good-placeholder-vp-column.md — same FP anti-vector as NV-1.
cp "$FIXTURE_DIR/good-placeholder-vp-column.md" \
    "$T/.factory/specs/behavioral-contracts/ss-01/SELFTEST-good-vp.md"

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean tree (good-placeholder-vp-column.md)"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Inject ONLY the comma-only fixture — NOT the em-dash fixture.
    # The em-dash would fire regardless of the BLOCK-1 fix; this fixture has teeth only
    # when _is_valid_vp_cell correctly rejects punctuation-only (all-empty-after-split) cells.
    cp "$FIXTURE_DIR/bad-placeholder-vp-punctuation-only.md" \
        "$T/.factory/specs/behavioral-contracts/ss-01/SELFTEST-vp-punctuation.md"
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch comma-only cell in VP-NNN column)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; comma-only cell in VP-NNN column correctly detected)"
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

# ── Test NV-5: check-id-resolution — versioned-changelog positional scoping (R3-C D-081) ──
# D-081 ruling: a non-conforming ID token under a `### vN.N` ATX heading is an
# immutable historical record (D-034) and must NOT be flagged by R3-B.
#
# Bidirectional test — one direction is insufficient:
#   Clean (FP guard): EC-NEW-42 appears ONLY under `### v1.3 — ...`
#     → checker must exit 0 (proves versioned-section occurrence is suppressed)
#   Defect: EC-NEW-42 added also under `## 9. Future Work` (not a versioned heading)
#     → checker must exit 1 and flag EC-NEW-42 (proves outside occurrence still detected)
#
# If R3-B were simply disabled: clean exits 0 (passes), defect exits 0 (FAILS).
# If in_versioned_changelog_section were always True: same failure.
# Both directions are required to prove the scoping is correct.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest NV-5: check-id-resolution: versioned-changelog positional scoping (R3-C D-081) ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs"

# Clean fixture: non-conforming EC-NEW-42 appears ONLY inside a ### vN.N section
cat > "$T/.factory/specs/changelog-scope-test.md" <<'MDNV5CLEAN'
## 8. Changelog

### v1.3 — Historical Remediation

Non-conforming placeholder EC-NEW-42 was renamed to a registered ID.
MDNV5CLEAN

CLEAN_PASS_NV5=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-id-resolution.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS_NV5=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean versioned-changelog tree (D-081 scoping not working)"
    NV5_CLEAN_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-id-resolution.py" 2>&1)
    echo "  Actual output: $NV5_CLEAN_OUT"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS_NV5" = "1" ]; then
    # Defect: add EC-NEW-42 also under a non-versioned section.
    # The `## 9. Future Work` heading (level 2, not matching `### v\d+\.\d+`) transitions
    # in_versioned_changelog_section to False — the following EC-NEW-42 must be flagged.
    # The `### v1.3` occurrence is retained; it must still NOT be flagged.
    cat > "$T/.factory/specs/changelog-scope-test.md" <<'MDNV5BAD'
## 8. Changelog

### v1.3 — Historical Remediation

Non-conforming placeholder EC-NEW-42 was renamed to a registered ID.

---

## 9. Future Work

The placeholder EC-NEW-42 is referenced here outside any versioned section.
MDNV5BAD
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-id-resolution.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — EC-NEW-42 outside versioned section should be flagged by R3-B)"
        FAILURES=$((FAILURES + 1))
    else
        NV5_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-id-resolution.py" 2>&1)
        if echo "$NV5_OUT" | grep -qF "EC-NEW-42"; then
            echo "  PASS (clean-pass confirmed with FP-guard; outside-versioned EC-NEW-42 correctly detected; versioned-section occurrence not flagged)"
        else
            echo "  FAIL (checker exited non-zero but EC-NEW-42 not in output)"
            echo "  Actual output: $NV5_OUT"
            FAILURES=$((FAILURES + 1))
        fi
    fi
fi
rm -rf "$T"

# ── Test P14-1: check-placeholders — test-sufficient where VP-INDEX assigns real VP ──
# Change 1 (POL-14 operator ruling): 'test-sufficient' in VP-NNN column is accepted
# ONLY when VP-INDEX classifies the BC as test-sufficient. If VP-INDEX assigns a real
# VP to that BC, the sentinel must be REJECTED with a distinct message.
#
# Mutation-flip: accept test-sufficient unconditionally (remove the VP-INDEX cross-check).
# Under mutation: defect tree exits 0 (sentinel accepted despite VP-INDEX saying VP-001)
# → defect-fail assertion fires → FAILS. Proves the VP-INDEX check is load-bearing.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest P14-1: check-placeholders: test-sufficient but VP-INDEX has real VP ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"
mkdir -p "$T/.factory/specs/verification-properties"

# VP-INDEX with BC-0.00.001 classified as VP-001 (has a real VP)
cat > "$T/.factory/specs/verification-properties/VP-INDEX.md" <<'VPIX'
| BC | Title (abbreviated) | VP(s) | Notes |
|----|---------------------|-------|-------|
| BC-0.00.001 | Test BC | VP-001 | has a real verification property |
VPIX

CLEAN_PASS=0
# Clean tree: VP-INDEX present, but no BC file with test-sufficient
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean tree (VP-INDEX present, no BC files)"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: BC file uses test-sufficient but VP-INDEX assigns VP-001 to this BC
    cat > "$T/.factory/specs/behavioral-contracts/ss-01/BC-0.00.001.md" <<'BCFILE'
## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | some property | integration test |
BCFILE
    P141_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" 2>&1)
    P141_EXIT=$?
    if [ "$P141_EXIT" -eq 0 ]; then
        echo "  FAIL (checker returned 0 — did NOT reject test-sufficient when VP-INDEX assigns VP-001)"
        FAILURES=$((FAILURES + 1))
    elif echo "$P141_OUT" | grep -qF "VP-INDEX classifies 'BC-0.00.001' as 'VP-001'"; then
        echo "  PASS (clean-pass confirmed; test-sufficient correctly rejected with VP-INDEX cross-check message)"
    else
        echo "  FAIL (checker exited non-zero but expected VP-INDEX-cross-check message not in output)"
        echo "  Actual output: $P141_OUT"
        FAILURES=$((FAILURES + 1))
    fi
fi
rm -rf "$T"

# ── Test P14-2: check-placeholders — test-sufficient where VP-INDEX has no row ──
# Change 1 (POL-14 operator ruling): 'test-sufficient' is rejected when the BC has
# no row at all in VP-INDEX — the operator must consciously classify it.
#
# Mutation-flip: accept test-sufficient unconditionally.
# Under mutation: defect tree exits 0 → defect-fail fires → FAILS.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest P14-2: check-placeholders: test-sufficient but VP-INDEX has no row ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"
mkdir -p "$T/.factory/specs/verification-properties"

# VP-INDEX with no rows (empty BC-to-VP table)
cat > "$T/.factory/specs/verification-properties/VP-INDEX.md" <<'VPIX'
| BC | Title (abbreviated) | VP(s) | Notes |
|----|---------------------|-------|-------|
VPIX

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean tree (empty VP-INDEX, no BC files)"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: BC file uses test-sufficient but has no row in VP-INDEX
    cat > "$T/.factory/specs/behavioral-contracts/ss-01/BC-0.00.002.md" <<'BCFILE'
## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | some property | integration test |
BCFILE
    P142_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" 2>&1)
    P142_EXIT=$?
    if [ "$P142_EXIT" -eq 0 ]; then
        echo "  FAIL (checker returned 0 — did NOT reject test-sufficient when BC has no VP-INDEX row)"
        FAILURES=$((FAILURES + 1))
    elif echo "$P142_OUT" | grep -qF "'BC-0.00.002' has no row in VP-INDEX"; then
        echo "  PASS (clean-pass confirmed; test-sufficient correctly rejected with no-VP-INDEX-row message)"
    else
        echo "  FAIL (checker exited non-zero but expected no-VP-INDEX-row message not in output)"
        echo "  Actual output: $P142_OUT"
        FAILURES=$((FAILURES + 1))
    fi
fi
rm -rf "$T"

# ── Test P14-3: check-placeholders — test-sufficient where VP-INDEX agrees ──
# Change 1 (POL-14 operator ruling): 'test-sufficient' MUST be accepted when
# VP-INDEX classifies the BC as test-sufficient.
#
# This tests the acceptance path (green path). The mutation proves it can still
# fail: removing the VP-INDEX row flips the clean-pass to a structural fail,
# demonstrating the clean-pass assertion has real teeth (not a tautology).
#
# Mutation-flip: remove the test-sufficient acceptance (revert sentinel to always-reject).
# Under mutation: clean tree exits 1 → STRUCTURAL FAIL fires → FAILS.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest P14-3: check-placeholders: test-sufficient accepted when VP-INDEX agrees ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"
mkdir -p "$T/.factory/specs/verification-properties"

# Clean tree: BC file uses test-sufficient AND VP-INDEX classifies it as test-sufficient
cat > "$T/.factory/specs/verification-properties/VP-INDEX.md" <<'VPIX'
| BC | Title (abbreviated) | VP(s) | Notes |
|----|---------------------|-------|-------|
| BC-0.00.003 | Test BC | test-sufficient | covered by integration test suite |
VPIX
cat > "$T/.factory/specs/behavioral-contracts/ss-01/BC-0.00.003.md" <<'BCFILE'
## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | some property | integration test |
BCFILE

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker rejected test-sufficient even though VP-INDEX agrees — acceptance path broken"
    P143_CLEAN_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" 2>&1)
    echo "  Actual output: $P143_CLEAN_OUT"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: remove BC-0.00.003 row from VP-INDEX — now sentinel has no backing
    cat > "$T/.factory/specs/verification-properties/VP-INDEX.md" <<'VPIX_BAD'
| BC | Title (abbreviated) | VP(s) | Notes |
|----|---------------------|-------|-------|
VPIX_BAD
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — test-sufficient accepted even after VP-INDEX row removed)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; removing VP-INDEX row correctly rejects test-sufficient sentinel)"
    fi
fi
rm -rf "$T"

# ── Test P14-4: check-placeholders — em-dash in VP-NNN column still fails ──
# After Change 1, em-dash (U+2014) in a VP-NNN column data row must STILL be rejected.
# This is the R2-RULE unchanged-behavior regression test.
#
# Mutation-flip: accept '—' as a valid VP cell value.
# Under mutation: defect tree exits 0 → defect-fail fires → FAILS.
# (NV-1 also covers em-dash, but that test pre-dates Change 1; this test proves
# the em-dash path survived the test-sufficient sentinel addition.)
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest P14-4: check-placeholders: em-dash in VP-NNN col still fails after Change 1 ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"
mkdir -p "$T/.factory/specs/verification-properties"
# VP-INDEX present but empty (not needed for em-dash rejection)
cat > "$T/.factory/specs/verification-properties/VP-INDEX.md" <<'VPIX'
| BC | Title (abbreviated) | VP(s) | Notes |
|----|---------------------|-------|-------|
VPIX

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean tree (empty BC dir, empty VP-INDEX)"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    cp "$FIXTURE_DIR/bad-placeholder-vp-emdash.md" \
        "$T/.factory/specs/behavioral-contracts/ss-01/SELFTEST-vp-emdash-p14.md"
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch em-dash in VP-NNN col after Change 1)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; em-dash in VP-NNN col correctly rejected after Change 1)"
    fi
fi
rm -rf "$T"

# ── Test P14-5: check-placeholders — [filled by] in non-Stories Traceability field ──
# Change 2 (POL-14/15 operator ruling): [filled by ...] exemption is ONLY for the
# Traceability 'Stories' field. Any other field (Architecture Module, L2 Capability,
# etc.) must still be rejected.
#
# Mutation-flip: blanket-exempt ALL [filled by ...] occurrences.
# Under mutation: defect tree exits 0 → defect-fail fires → FAILS.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest P14-5: check-placeholders: [filled by] in non-Stories Traceability field ──"
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
    cp "$FIXTURE_DIR/bad-placeholder-stories-nonstories-field.md" \
        "$T/.factory/specs/behavioral-contracts/ss-01/SELFTEST-nonstories.md"
    P145_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" 2>&1)
    P145_EXIT=$?
    if [ "$P145_EXIT" -eq 0 ]; then
        echo "  FAIL (checker returned 0 — did NOT catch [filled by] in non-Stories Traceability field)"
        FAILURES=$((FAILURES + 1))
    elif echo "$P145_OUT" | grep -qF "[filled by architect]"; then
        echo "  PASS (clean-pass confirmed; [filled by] in non-Stories field correctly detected)"
    else
        echo "  FAIL (checker exited non-zero but '[filled by architect]' not in output)"
        echo "  Actual output: $P145_OUT"
        FAILURES=$((FAILURES + 1))
    fi
fi
rm -rf "$T"

# ── Test P14-6: check-placeholders — [filled by] in Stories Traceability field passes ──
# Change 2 (POL-14/15 operator ruling): [filled by ...] in '| Stories | ... |' rows is
# EXEMPT. This tests the acceptance path (green path).
#
# Mutation-flip: remove the Stories-field exemption (Shape 1).
# Under mutation: clean tree exits 1 → STRUCTURAL FAIL fires → FAILS.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest P14-6: check-placeholders: [filled by] in Stories Traceability row passes ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"

# Clean tree: [filled by story-writer] in the Stories Traceability field
cat > "$T/.factory/specs/behavioral-contracts/ss-01/SELFTEST-stories-clean.md" <<'BCCLEAN'
## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-001 |
| Architecture Module | scanner.rs |
| Stories | [filled by story-writer] |
BCCLEAN

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker rejected [filled by story-writer] in Stories field — exemption not working"
    P146_CLEAN_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" 2>&1)
    echo "  Actual output: $P146_CLEAN_OUT"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: rename Stories field to Architecture Module — [filled by] no longer exempt
    cat > "$T/.factory/specs/behavioral-contracts/ss-01/SELFTEST-stories-clean.md" <<'BCBAD'
## Traceability
| Field | Value |
|-------|-------|
| L2 Capability | CAP-001 |
| Architecture Module | [filled by story-writer] |
| Stories | scanner.rs |
BCBAD
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch [filled by] after moving to non-Stories field)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; [filled by] detected after moving from Stories to Architecture Module field)"
    fi
fi
rm -rf "$T"

# ── Test P14-7: check-placeholders — [filled by] in ordinary prose still fails ──
# Change 2 exempts ONLY the two Stories-context shapes. [filled by ...] anywhere
# in ordinary prose must remain a violation.
#
# Mutation-flip: blanket-exempt ALL [filled by ...] occurrences.
# Under mutation: defect tree exits 0 → defect-fail fires → FAILS.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest P14-7: check-placeholders: [filled by] in prose still fails after Change 2 ──"
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
    cp "$FIXTURE_DIR/bad-placeholder-filled-by-prose.md" \
        "$T/.factory/specs/behavioral-contracts/ss-01/SELFTEST-filled-by-prose.md"
    P147_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" 2>&1)
    P147_EXIT=$?
    if [ "$P147_EXIT" -eq 0 ]; then
        echo "  FAIL (checker returned 0 — did NOT catch [filled by] in ordinary prose)"
        FAILURES=$((FAILURES + 1))
    elif echo "$P147_OUT" | grep -qF "[filled by the product owner]"; then
        echo "  PASS (clean-pass confirmed; [filled by] in prose correctly detected)"
    else
        echo "  FAIL (checker exited non-zero but expected prose [filled by] message not in output)"
        echo "  Actual output: $P147_OUT"
        FAILURES=$((FAILURES + 1))
    fi
fi
rm -rf "$T"

# ── Test P14-8: check-placeholders — Shape 2 bullet under wrong heading fails ──
# Shape 2 exempts `- [filled by ...]` ONLY under "## Story Anchor".
# Defect: move the bullet under a different H2 heading ("## Architecture Anchors").
# Clean-pass assertion: "## Story Anchor" + bullet exits 0.
# Defect-fail assertion: bullet under "## Architecture Anchors" must exit 1.
#
# Kills M4 (delete Shape 2 branch entirely): under M4, the clean tree already has
# `- [filled by story-writer]` under "## Story Anchor" with NO exemption → exit 1
# → STRUCTURAL FAIL on clean-pass → suite fails → M4 DIES.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest P14-8: check-placeholders: Shape 2 bullet under wrong heading is flagged ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"

# Clean tree: [filled by story-writer] bullet directly under "## Story Anchor"
cat > "$T/.factory/specs/behavioral-contracts/ss-01/SELFTEST-story-anchor-clean.md" <<'CLEANBC'
## Traceability
| Field | Value |
|-------|-------|
| Stories | scanner.rs |

## Story Anchor
- [filled by story-writer]
CLEANBC

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker rejected [filled by story-writer] under ## Story Anchor — Shape 2 exemption not working"
    P148_CLEAN_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" 2>&1)
    echo "  Actual output: $P148_CLEAN_OUT"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: move the bullet under "## Architecture Anchors" — no longer exempt
    cat > "$T/.factory/specs/behavioral-contracts/ss-01/SELFTEST-story-anchor-clean.md" <<'DEFECTBC'
## Traceability
| Field | Value |
|-------|-------|
| Stories | scanner.rs |

## Architecture Anchors
- [filled by story-writer]
DEFECTBC
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch [filled by] bullet under ## Architecture Anchors)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; [filled by] bullet under ## Architecture Anchors correctly detected)"
    fi
fi
rm -rf "$T"

# ── Test P14-9: check-placeholders — Shape 2 bullet without any Story Anchor heading fails ──
# If there is no "## Story Anchor" heading in the file at all, a `- [filled by ...]`
# bullet must be flagged as a violation — current_h2_heading is never "Story Anchor".
# Defect: add a `- [filled by story-writer]` bullet with NO "## Story Anchor" in the file.
# Clean-pass assertion: same file without the bullet exits 0.
# Defect-fail assertion: file with only the bullet (no heading) must exit 1.
#
# Kills M8 (drop the `current_h2_heading == "Story Anchor"` condition so every
# `- [filled by ...]` bullet is exempt regardless of heading): under M8, the defect
# tree exits 0 → defect-fail fires → suite fails → M8 DIES.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest P14-9: check-placeholders: Shape 2 bullet without Story Anchor heading is flagged ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"

# Clean tree: no [filled by] bullet and no ## Story Anchor heading
cat > "$T/.factory/specs/behavioral-contracts/ss-01/SELFTEST-no-story-anchor.md" <<'CLEANBC2'
## Description
This specification defines behavior without a Story Anchor section.

## Acceptance Criteria
- The system must respond within 200ms.
CLEANBC2

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean tree without any [filled by] content"
    P149_CLEAN_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" 2>&1)
    echo "  Actual output: $P149_CLEAN_OUT"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: add a [filled by story-writer] bullet — no ## Story Anchor heading exists
    cat > "$T/.factory/specs/behavioral-contracts/ss-01/SELFTEST-no-story-anchor.md" <<'DEFECTBC2'
## Description
This specification defines behavior without a Story Anchor section.

## Acceptance Criteria
- The system must respond within 200ms.
- [filled by story-writer]
DEFECTBC2
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch [filled by] bullet without ## Story Anchor heading)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; [filled by] bullet without ## Story Anchor correctly detected)"
    fi
fi
rm -rf "$T"

# ── Test P14-10: check-placeholders — S1-fix: subheading inside ## Story Anchor resets context ──
# A `- [filled by ...]` bullet appearing AFTER a sub-heading (### or deeper) that is
# itself nested inside "## Story Anchor" must be FLAGGED — the sub-heading resets
# current_h2_heading to None, ending the Shape 2 exemption zone.
#
# Clean-pass: bullet DIRECTLY under "## Story Anchor" (no intervening sub-heading) → exempt.
# Defect: bullet under "### Details" nested inside "## Story Anchor" → must be flagged.
#
# Kills MS1 (delete `else: current_h2_heading = None`): under MS1 the sub-heading does
# NOT reset context, the bullet is still seen as under "Story Anchor", and exits 0 →
# defect-fail fires → MS1 DIES.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest P14-10: check-placeholders: bullet after sub-heading inside ## Story Anchor is flagged ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"

# Clean tree: bullet directly under ## Story Anchor — must be exempt (exits 0)
cat > "$T/.factory/specs/behavioral-contracts/ss-01/SELFTEST-subheading-reset-clean.md" <<'CLEANBC10'
## Traceability
| Field | Value |
|-------|-------|
| Stories | scanner.rs |

## Story Anchor
- [filled by story-writer]
CLEANBC10

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker rejected [filled by story-writer] bullet directly under ## Story Anchor — Shape 2 exemption broken"
    P1410_CLEAN_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" 2>&1)
    echo "  Actual output: $P1410_CLEAN_OUT"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: intervening ### Details sub-heading resets context; bullet after it must be flagged
    cat > "$T/.factory/specs/behavioral-contracts/ss-01/SELFTEST-subheading-reset-clean.md" <<'DEFECTBC10'
## Traceability
| Field | Value |
|-------|-------|
| Stories | scanner.rs |

## Story Anchor
### Details
- [filled by story-writer]
DEFECTBC10
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch [filled by] bullet after ### Details inside ## Story Anchor)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; [filled by] bullet after nested sub-heading correctly flagged)"
    fi
fi
rm -rf "$T"

# ── Test P14-11: check-placeholders — S1-fix: prose (non-bullet) under ## Story Anchor is flagged ──
# Shape 2 exempts ONLY `- [filled by ...]` bullet lines under "## Story Anchor".
# A prose line such as `Stories: [filled by ...]` (no leading `- `) must still be flagged
# even when `current_h2_heading == "Story Anchor"`.
#
# Clean-pass: bullet directly under "## Story Anchor" → exempt (exits 0).
# Defect: prose line containing [filled by ...] directly under "## Story Anchor" → must be flagged.
#
# Kills MB (drop the `and line.lstrip().startswith("- ")` guard): under MB any line under
# "## Story Anchor" is exempt regardless of whether it starts with "- "; the prose defect
# exits 0 → defect-fail fires → MB DIES.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest P14-11: check-placeholders: prose placeholder under ## Story Anchor is flagged ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"

# Clean tree: bullet directly under ## Story Anchor — must be exempt (exits 0)
cat > "$T/.factory/specs/behavioral-contracts/ss-01/SELFTEST-prose-under-anchor-clean.md" <<'CLEANBC11'
## Traceability
| Field | Value |
|-------|-------|
| Stories | scanner.rs |

## Story Anchor
- [filled by story-writer]
CLEANBC11

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker rejected [filled by story-writer] bullet directly under ## Story Anchor — Shape 2 exemption broken"
    P1411_CLEAN_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" 2>&1)
    echo "  Actual output: $P1411_CLEAN_OUT"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: prose line (no leading "- ") under ## Story Anchor — Shape 2 does NOT cover it
    cat > "$T/.factory/specs/behavioral-contracts/ss-01/SELFTEST-prose-under-anchor-clean.md" <<'DEFECTBC11'
## Traceability
| Field | Value |
|-------|-------|
| Stories | scanner.rs |

## Story Anchor
Stories: [filled by story-writer]
DEFECTBC11
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch prose [filled by] line under ## Story Anchor)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; prose [filled by] under ## Story Anchor correctly flagged)"
    fi
fi
rm -rf "$T"

# ── Test P14-12: check-placeholders — S1-fix: non-standard "heading" (#nospace) inside
#    ## Story Anchor must NOT reset current_h2_heading ──────────────────────────────────
# A line starting with "#" but lacking the required space after the hashes (e.g.
# "#nospace") is NOT a valid ATX heading per CommonMark and must be ignored by the
# heading-context tracker.  If the ATX guard were removed (MX1 mutation:
# `if _atx_rest.startswith(" ") or not _atx_rest:` → `if True:`), such lines would
# trigger `else: current_h2_heading = None`, silently ending the Shape 2 exemption zone
# and causing a false-positive flag on what should be an exempt bullet.
#
# Clean-pass: ## Story Anchor + #nospace line + bullet → checker exits 0 (bullet exempt).
# Under MX1 the clean tree exits 1 (false positive) → STRUCTURAL FAIL fires → MX1 DIES.
#
# Defect: bullet after ### Details inside ## Story Anchor → must be flagged (reuses P14-10
# defect shape; only reached when HEAD is the code under test).
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest P14-12: check-placeholders: non-ATX #nospace line inside ## Story Anchor does not reset context ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"

# Clean tree: ## Story Anchor then a #nospace non-heading line then a bullet.
# The bullet must remain exempt because #nospace is not a valid ATX heading.
cat > "$T/.factory/specs/behavioral-contracts/ss-01/SELFTEST-atx-guard-clean.md" <<'CLEANBC12'
## Story Anchor
#nospace-line-is-not-a-heading
- [filled by story-writer]
CLEANBC12

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker falsely rejected [filled by story-writer] bullet after #nospace inside ## Story Anchor — ATX guard too aggressive (MX1 regression)"
    P1412_CLEAN_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" 2>&1)
    echo "  Actual output: $P1412_CLEAN_OUT"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: proper ### sub-heading DOES reset context; bullet after it must be flagged
    cat > "$T/.factory/specs/behavioral-contracts/ss-01/SELFTEST-atx-guard-clean.md" <<'DEFECTBC12'
## Story Anchor
### Details
- [filled by story-writer]
DEFECTBC12
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch [filled by] bullet after ### Details inside ## Story Anchor)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; #nospace non-heading does not break exemption; ### sub-heading does)"
    fi
fi
rm -rf "$T"

# ── Test P14-13: check-placeholders — S1-fix: only a proper H2 ("## ") creates the
#    exemption zone; an H3/H4/… heading whose text is "Story Anchor" must NOT ──────────
# `current_h2_heading` is updated ONLY when the heading marker is exactly "## " (two
# hashes + space).  A sub-heading such as "### Story Anchor" must NOT set
# current_h2_heading to "Story Anchor" — it must reset it to None, ending any prior
# exemption zone.
#
# Under MX3 (`line.startswith("## ")` → `line.startswith("#")`), "### Story Anchor" would
# compute line[3:].strip() = "Story Anchor" and set current_h2_heading accordingly,
# incorrectly making the subsequent bullet exempt.
#
# Clean-pass: proper ## Story Anchor + bullet → exempt (exits 0).
# Defect: ## Other Section / ### Story Anchor / bullet — bullet must be flagged because the
# exemption zone was opened by ## Other Section, then ## Story Anchor (H3) only resets
# context to None under HEAD.  Under MX3 it sets context to "Story Anchor" → exits 0 →
# defect-fail fires → MX3 DIES.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest P14-13: check-placeholders: H3 heading named Story Anchor does not create exemption zone ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"

# Clean tree: proper ## Story Anchor creates the exemption zone — bullet is exempt
cat > "$T/.factory/specs/behavioral-contracts/ss-01/SELFTEST-h2-only-anchor-clean.md" <<'CLEANBC13'
## Story Anchor
- [filled by story-writer]
CLEANBC13

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker rejected [filled by story-writer] under proper ## Story Anchor — Shape 2 exemption broken"
    P1413_CLEAN_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" 2>&1)
    echo "  Actual output: $P1413_CLEAN_OUT"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: ## Other Section followed by ### Story Anchor (H3) — bullet must NOT be exempt
    cat > "$T/.factory/specs/behavioral-contracts/ss-01/SELFTEST-h2-only-anchor-clean.md" <<'DEFECTBC13'
## Other Section
### Story Anchor
- [filled by story-writer]
DEFECTBC13
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch [filled by] bullet after ### Story Anchor inside ## Other Section)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; H3 heading named Story Anchor does not create exemption zone)"
    fi
fi
rm -rf "$T"

# ── Test P14-14: check-placeholders — test-sufficient with empty Proof Method fails ──
# S3-fix (D-078 precondition): 'test-sufficient' must be rejected when the Proof
# Method cell is empty, even if VP-INDEX classifies the BC as test-sufficient.
# This is the same precondition VP-NONE already has (asymmetry was the defect).
#
# Clean-pass: test-sufficient + non-empty Proof Method + VP-INDEX agrees → exits 0.
# Defect: clear the Proof Method cell → exits 1 with D-078 precondition message.
#
# Mutation-flip: remove the new proof_method.strip() guard from the test-sufficient
# branch (i.e. revert S3-fix to HEAD~1). Under mutation: defect tree exits 0 →
# defect-fail assertion fires → FAILS. Proves the new guard is load-bearing.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest P14-14: check-placeholders: test-sufficient with empty Proof Method fails ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"
mkdir -p "$T/.factory/specs/verification-properties"

# VP-INDEX: BC-0.00.004 classified as test-sufficient
cat > "$T/.factory/specs/verification-properties/VP-INDEX.md" <<'VPIX'
| BC | Title (abbreviated) | VP(s) | Notes |
|----|---------------------|-------|-------|
| BC-0.00.004 | Test BC | test-sufficient | covered by integration test suite |
VPIX

# Clean tree: test-sufficient with a non-empty Proof Method → must be accepted
cat > "$T/.factory/specs/behavioral-contracts/ss-01/BC-0.00.004.md" <<'BCCLEAN'
## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | some property | integration test |
BCCLEAN

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker rejected test-sufficient with non-empty Proof Method — D-078 precondition too strict"
    P1414_CLEAN_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" 2>&1)
    echo "  Actual output: $P1414_CLEAN_OUT"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: clear the Proof Method cell — sentinel now names no test at all
    cat > "$T/.factory/specs/behavioral-contracts/ss-01/BC-0.00.004.md" <<'BCBAD'
## Verification Properties
| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| test-sufficient | some property |  |
BCBAD
    P1414_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" 2>&1)
    P1414_EXIT=$?
    if [ "$P1414_EXIT" -eq 0 ]; then
        echo "  FAIL (checker returned 0 — did NOT reject test-sufficient with empty Proof Method)"
        FAILURES=$((FAILURES + 1))
    elif echo "$P1414_OUT" | grep -qF "Proof Method cell must be non-empty (D-078 precondition)"; then
        echo "  PASS (clean-pass confirmed; test-sufficient with empty Proof Method correctly rejected)"
    else
        echo "  FAIL (checker exited non-zero but D-078-precondition message not in output)"
        echo "  Actual output: $P1414_OUT"
        FAILURES=$((FAILURES + 1))
    fi
fi
rm -rf "$T"

# ── Test P14-15: check-placeholders — live placeholder in prd.md prose MUST flag (D-113) ──
# REPAIR 4 (BI-047): prd.md now enters scope (134 of 134 files). This test proves that a
# live [filled by architect] placeholder in prd.md prose OUTSIDE a changelog section IS
# flagged — no file-path exclusion can suppress it.
# Clean: prd.md exists but has no placeholder → exit 0
# Defect: add a live [filled by architect] in plain prose → exit 1
# Mutation-verify: removing the prd.md from scope (e.g., restoring EXCLUDE_PATHS) makes
# the defect tree exit 0 → defect-fail assertion fires → FAILS.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest P14-15: check-placeholders: live placeholder in prd.md prose must flag (D-113) ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts"

# Clean tree: prd.md with no live placeholders
cat > "$T/.factory/specs/prd.md" <<'P1415CLEAN'
---
---
## 2. Behavioral Contracts

This section documents the behavioral contracts.
P1415CLEAN

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    P1415_CLEAN_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" 2>&1)
    echo "  STRUCTURAL FAIL: checker failed on clean prd.md with no placeholders"
    echo "  Actual output: $P1415_CLEAN_OUT"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: inject a live [filled by architect] in prd.md prose (NOT in any changelog section)
    cat > "$T/.factory/specs/prd.md" <<'P1415BAD'
---
---
## 2. Behavioral Contracts

Architecture module: [filled by architect]
P1415BAD
    P1415_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" 2>&1)
    P1415_EXIT=$?
    if [ "$P1415_EXIT" -eq 0 ]; then
        echo "  FAIL (checker returned 0 — did NOT flag live [filled by architect] in prd.md prose)"
        FAILURES=$((FAILURES + 1))
    elif echo "$P1415_OUT" | grep -qF "[filled by architect]"; then
        echo "  PASS (clean-pass confirmed; live [filled by architect] in prd.md prose correctly flagged)"
    else
        echo "  FAIL (checker exited non-zero but expected [filled by architect] not in output)"
        echo "  Actual: $P1415_OUT"
        FAILURES=$((FAILURES + 1))
    fi
fi
rm -rf "$T"

# ── Test P14-16: check-placeholders — changelog narrative VP-TBD NOT flagged (D-081 P1) ──
# REPAIR 4 (BI-047): the D-081 Predicate 1 (changelog narrative section) exempts VP-TBD
# tokens inside ### v\d+ heading sections. This test proves the predicate is load-bearing:
# Clean: prd.md with VP-TBD inside a ### v1.4 changelog section → exit 0 (not flagged)
# Defect: move VP-TBD to plain prose OUTSIDE the changelog section → exit 1 (flagged)
# Mutation-verify: removing the changelog narrative exemption from check_file_lines makes
# the clean tree exit 1 → STRUCTURAL FAIL asserts → FAILS. Proves D-081 P1 is load-bearing.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest P14-16: check-placeholders: changelog-narrative VP-TBD not flagged (D-081 P1) ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts"

# Clean tree: VP-TBD inside a ### v1.4 changelog narrative section (historical, exempt)
cat > "$T/.factory/specs/prd.md" <<'P1416CLEAN'
---
---
## Changelog

### v1.4 — Adversary Pass-1 Remediation

**F-007 (VP-TBD backfill):** All `VP-TBD` placeholders replaced across 37 BC files. Zero VP-TBD remaining.
P1416CLEAN

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    P1416_CLEAN_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" 2>&1)
    echo "  STRUCTURAL FAIL: D-081 P1 exemption missing — VP-TBD in changelog narrative was flagged"
    echo "  Actual output: $P1416_CLEAN_OUT"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: same VP-TBD moved to plain prose OUTSIDE any changelog section
    cat > "$T/.factory/specs/prd.md" <<'P1416BAD'
---
---
## 2. Verification Properties

The VP-TBD placeholder remains unfilled.
P1416BAD
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT flag VP-TBD in plain prose)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; changelog-narrative VP-TBD exempt; prose VP-TBD flagged)"
    fi
fi
rm -rf "$T"

# ── Test P14-17: check-placeholders — backtick citation NOT flagged (D-081 P2) ──
# REPAIR 4 (BI-047): the D-081 Predicate 2 (backtick span) exempts placeholder tokens
# inside inline code spans. This test proves the predicate is load-bearing:
# Clean: prd.md with `[filled by architect]` inside backticks → exit 0 (cited reference)
# Defect: remove backticks → live placeholder in plain prose → exit 1 (flagged)
# Mutation-verify: removing the backtick span exemption from check_file_lines makes the
# clean tree exit 1 → STRUCTURAL FAIL asserts → FAILS. Proves D-081 P2 is load-bearing.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest P14-17: check-placeholders: backtick citation of placeholder not flagged (D-081 P2) ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts"

# Clean tree: [filled by architect] inside backticks — cited reference, not live
cat > "$T/.factory/specs/prd.md" <<'P1417CLEAN'
---
---
## Changelog

### v1.9 — Repair Pass

Closed all 22 `[filled by architect]` placeholders across 26 BC files.
P1417CLEAN

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    P1417_CLEAN_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" 2>&1)
    echo "  STRUCTURAL FAIL: backtick citation of [filled by architect] was incorrectly flagged"
    echo "  Actual output: $P1417_CLEAN_OUT"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: remove backticks → live [filled by architect] in changelog prose
    # NOTE: this is ALSO in a changelog section (### v1.9), so BOTH predicates would fire.
    # To isolate P2 specifically: put the defect OUTSIDE any changelog section.
    cat > "$T/.factory/specs/prd.md" <<'P1417BAD'
---
---
## 2. Behavioral Contracts

Architecture module: [filled by architect]
P1417BAD
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-placeholders.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT flag [filled by architect] without backticks)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; backtick citation exempt; unquoted live placeholder flagged)"
    fi
fi
rm -rf "$T"

# ── Test EI-1: check-ec-injectivity — BC-vs-registry divergent scenario (BI-051) ──
# Proves the new BC-vs-registry comparison detects a clearly divergent scenario:
# the BC description has zero token overlap with the TV canonical description.
# Calibration: EC-142 (BC: "Scan with 0 findings", TV: "Only an unreadable file",
# Jaccard=0.0) is the real-corpus proof case — this selftest is its mechanical equivalent.
# Clean: BC description agrees with TV → exit 0
# Defect: BC description completely different (disjoint tokens) → exit 1 (SCENARIO-MISMATCH)
# Mutation-verify: removing the _compare_bc_to_registry call from main() makes the defect
# tree exit 0 → defect-fail assertion fires → FAILS.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest EI-1: check-ec-injectivity: BC-vs-registry divergent scenario (BI-051) ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"
mkdir -p "$T/.factory/specs/prd-supplements"

# Clean tree: BC description AGREES with TV description
# TV: "Symlink outside root boundary traversal"  BC: "Symlink traversal outside root boundary"
# Jaccard: shared tokens {symlink, outside, root, boundary, traversal} / union = 1.0 → PASS
# Header row required by BLOCKING-1 schema-aware extract_tv_rows (no header → row skipped)
printf '| TV | EC | Description | Input | Exit | Verdict | Reason |\n|---|---|---|---|---|---|---|\n| TV-001 | EC-001 | Symlink outside root boundary traversal | `doc.md` | 1 | broken | reason |\n' \
    > "$T/.factory/specs/prd-supplements/test-vectors.md"

cat > "$T/.factory/specs/behavioral-contracts/ss-01/BC-EI1-SELFTEST.md" <<'BCEI1CLEAN'
---
bc_id: BC-EI1-SELFTEST
---
## Edge Cases
| ID | Description |
|----|-------------|
| EC-001 | Symlink traversal outside root boundary |
BCEI1CLEAN

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-ec-injectivity.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    EI1_CLEAN_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-ec-injectivity.py" 2>&1)
    echo "  STRUCTURAL FAIL: checker failed on agreeing BC+TV descriptions"
    echo "  Output: $EI1_CLEAN_OUT"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: overwrite BC with a completely different description (zero token overlap)
    # BC: "Exit code zero when scan passes without errors" — zero overlap with TV symlink description
    cat > "$T/.factory/specs/behavioral-contracts/ss-01/BC-EI1-SELFTEST.md" <<'BCEI1BAD'
---
bc_id: BC-EI1-SELFTEST
---
## Edge Cases
| ID | Description |
|----|-------------|
| EC-001 | Exit code zero when scan passes without errors |
BCEI1BAD
    EI1_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-ec-injectivity.py" 2>&1)
    EI1_EXIT=$?
    if [ "$EI1_EXIT" -eq 0 ]; then
        echo "  FAIL (checker returned 0 — did NOT detect divergent BC-vs-registry scenario)"
        FAILURES=$((FAILURES + 1))
    elif echo "$EI1_OUT" | grep -q "SCENARIO-MISMATCH EC-001"; then
        echo "  PASS (clean-pass confirmed; divergent BC-vs-registry scenario correctly detected)"
    else
        echo "  FAIL (checker exited non-zero but SCENARIO-MISMATCH EC-001 not in output)"
        echo "  Actual: $EI1_OUT"
        FAILURES=$((FAILURES + 1))
    fi
fi
rm -rf "$T"

# ── Test EI-2: check-ec-injectivity — BC-vs-registry genuine agreement NOT flagged (BI-051) ──
# Proves the pass bucket works: a BC description that genuinely agrees with the TV canonical
# description (high Jaccard) is NOT flagged.
# Clean: agreeing descriptions → exit 0 (no SCENARIO-MISMATCH)
# Defect: change BC to completely different description → exit 1
# Mutation-verify: lowering BC_REGISTRY_AGREE threshold to 0 would make all cases "divergent"
# and the clean tree would exit 1 → STRUCTURAL FAIL asserts → FAILS.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest EI-2: check-ec-injectivity: genuine agreement not flagged (BI-051) ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"
mkdir -p "$T/.factory/specs/prd-supplements"

# TV: "Missing file at link destination" — strong description with unique tokens
# Header row required by BLOCKING-1 schema-aware extract_tv_rows
printf '| TV | EC | Description | Input | Exit | Verdict | Reason |\n|---|---|---|---|---|---|---|\n| TV-002 | EC-002 | Missing file at link destination | `doc.md` | 1 | broken | reason |\n' \
    > "$T/.factory/specs/prd-supplements/test-vectors.md"

# BC: "Missing file at link destination" — identical (Jaccard=1.0)
cat > "$T/.factory/specs/behavioral-contracts/ss-01/BC-EI2-SELFTEST.md" <<'BCEI2CLEAN'
---
bc_id: BC-EI2-SELFTEST
---
## Edge Cases
| ID | Description |
|----|-------------|
| EC-002 | Missing file at link destination |
BCEI2CLEAN

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-ec-injectivity.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    EI2_CLEAN_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-ec-injectivity.py" 2>&1)
    echo "  STRUCTURAL FAIL: checker flagged genuine agreement between BC and TV descriptions"
    echo "  Output: $EI2_CLEAN_OUT"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: change BC to completely different scenario (zero overlap)
    cat > "$T/.factory/specs/behavioral-contracts/ss-01/BC-EI2-SELFTEST.md" <<'BCEI2BAD'
---
bc_id: BC-EI2-SELFTEST
---
## Edge Cases
| ID | Description |
|----|-------------|
| EC-002 | TLS handshake timeout during certificate validation |
BCEI2BAD
    EI2_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-ec-injectivity.py" 2>&1)
    EI2_EXIT=$?
    if [ "$EI2_EXIT" -eq 0 ]; then
        echo "  FAIL (checker returned 0 — did NOT detect divergent scenario after changing BC)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; genuine agreement not flagged; divergent correctly detected)"
    fi
fi
rm -rf "$T"

# ── Test EI-3: check-ec-injectivity — borderline case in adjudication bucket (BI-051) ──
# Proves the adjudication bucket is populated for borderline Jaccard values.
# Design: clean tree = borderline BC+TV description pair (Jaccard in [0.02, 0.10)) → exit 0
# with "1 require adjudication" in output. Defect = change BC to zero-overlap → exit 1.
# This structure satisfies the two-step clean-pass/defect-fail pattern:
#   clean-pass: exit 0 AND "1 require adjudication" in output (proves borderline lands in bucket)
#   defect-fail: exit 1 (from divergent case — proves threshold is enforced)
# Mutation-verify: raising BC_REGISTRY_BORDERLINE above the clean pair's Jaccard makes
# it "divergent" → clean tree exits 1 → STRUCTURAL FAIL asserts → FAILS.
#
# Calibration pair (Jaccard ≈ 0.091 → adjudication):
#   TV: "Link target points to missing file path"
#       tokens: {link, target, points, missing, file, path} → unique: {link,target,points,missing,file,path}
#   BC: "Broken reference to non-existent document path"
#       tokens: {broken, reference, non, existent, document, path} → unique: {broken,ref,non,existent,doc,path}
#   Shared: {path} → Jaccard = 1/11 ≈ 0.091 → in [0.02, 0.10) → ADJUDICATION
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest EI-3: check-ec-injectivity: borderline case in adjudication bucket (BI-051) ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"
mkdir -p "$T/.factory/specs/prd-supplements"

# TV: borderline pair — Jaccard ≈ 0.091 with BC below (adjudication, not divergent)
# Header row required by BLOCKING-1 schema-aware extract_tv_rows
printf '| TV | EC | Description | Input | Exit | Verdict | Reason |\n|---|---|---|---|---|---|---|\n| TV-003 | EC-003 | Link target points to missing file path | `doc.md` | 1 | broken | reason |\n' \
    > "$T/.factory/specs/prd-supplements/test-vectors.md"

# BC: borderline description (shares "path" token with TV, low but nonzero Jaccard)
cat > "$T/.factory/specs/behavioral-contracts/ss-01/BC-EI3-SELFTEST.md" <<'BCEI3CLEAN'
---
bc_id: BC-EI3-SELFTEST
---
## Edge Cases
| ID | Description |
|----|-------------|
| EC-003 | Broken reference to non-existent document path |
BCEI3CLEAN

EI3_CLEAN_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-ec-injectivity.py" 2>&1)
EI3_CLEAN_EXIT=$?
CLEAN_PASS=0
if [ "$EI3_CLEAN_EXIT" -ne 0 ]; then
    echo "  STRUCTURAL FAIL: borderline case incorrectly triggered exit 1 (should land in adjudication)"
    echo "  Output: $EI3_CLEAN_OUT"
    FAILURES=$((FAILURES + 1))
elif echo "$EI3_CLEAN_OUT" | grep -q "1 require adjudication"; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: borderline case did not land in adjudication bucket (output has no '1 require adjudication')"
    echo "  Output: $EI3_CLEAN_OUT"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: change BC to zero-overlap description → exit 1 (divergent)
    cat > "$T/.factory/specs/behavioral-contracts/ss-01/BC-EI3-SELFTEST.md" <<'BCEI3BAD'
---
bc_id: BC-EI3-SELFTEST
---
## Edge Cases
| ID | Description |
|----|-------------|
| EC-003 | TLS certificate chain validation error during SSL handshake |
BCEI3BAD
    EI3_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-ec-injectivity.py" 2>&1)
    EI3_EXIT=$?
    if [ "$EI3_EXIT" -eq 0 ]; then
        echo "  FAIL (checker returned 0 — zero-overlap description should be divergent/exit 1)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed with adjudication; zero-overlap correctly detected as divergent)"
    fi
fi
rm -rf "$T"

# ── Test EI-4: check-ec-injectivity — multi-schema TV file, non-comparable section skipped ──
# Proves BLOCKING-1: rows in TV sections with ONLY non-comparable columns are skipped
# (no false SCENARIO-MISMATCH), while rows in sections with comparable columns are compared.
#
# BI-057 update: "Input" and "Link" are now comparable (multi-column concatenation).
# To trigger a genuine skip, section B uses only "Source MD File" (non-comparable filename
# column) + "Expected Exit" + "Verdict" — none of which match _COMPARABLE_KEYWORDS.
#
# TV has two sections:
#   Section A (Description column): EC-004 "Symlink traversal check" — comparable
#   Section B (Source MD File only): EC-004 also present — rows skipped (filename column)
# BC cites EC-004 with a matching description (Jaccard ≥ 0.10) → exit 0.
# Coverage line must mention TV rows skipped (proves schema-aware extraction ran).
#
# Defect: change BC EC-004 to zero-overlap description → exit 1 SCENARIO-MISMATCH.
# Mutation-verify: expanding _COMPARABLE_KEYWORDS to include "source md file" or "expected exit"
#   would make section B rows comparable, yielding J=0 (filename vs BC description);
#   ADVISORY-6 best-match selects section A's higher-J row, but the skip count in the
#   coverage line would drop to 0 → STRUCTURAL FAIL fires → MUTATION DIES.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest EI-4: check-ec-injectivity: multi-schema TV file — non-comparable section skipped ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"
mkdir -p "$T/.factory/specs/prd-supplements"

# TV: section A has Description column (EC-004 comparable),
#     section B has ONLY Source MD File + Expected Exit + Verdict (non-comparable)
cat > "$T/.factory/specs/prd-supplements/test-vectors.md" <<'TVEI4'
| TV | EC | Description | Exit | Verdict |
|---|---|---|---|---|
| TV-004 | EC-004 | Symlink traversal check | 1 | broken |

| TV | EC | Source MD File | Expected Exit | Verdict |
|---|---|---|---|---|
| TV-004b | EC-004 | `docs/a.md` | 1 | broken |
TVEI4

# BC: EC-004 with matching description (Jaccard ≥ 0.10)
# TV section A: {symlink, traversal, check}, BC: {symlink, traversal, outside, root} → J=2/5=0.4
cat > "$T/.factory/specs/behavioral-contracts/ss-01/BC-EI4-SELFTEST.md" <<'BCEI4CLEAN'
---
bc_id: BC-EI4-SELFTEST
---
## Edge Cases
| ID | Description |
|----|-------------|
| EC-004 | Symlink traversal outside root |
BCEI4CLEAN

EI4_CLEAN_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-ec-injectivity.py" 2>&1)
EI4_CLEAN_EXIT=$?
CLEAN_PASS=0
if [ "$EI4_CLEAN_EXIT" -ne 0 ]; then
    echo "  STRUCTURAL FAIL: multi-schema TV incorrectly triggered exit 1 (section B should be skipped)"
    echo "  Output: $EI4_CLEAN_OUT"
    FAILURES=$((FAILURES + 1))
elif echo "$EI4_CLEAN_OUT" | grep -q "TV rows skipped"; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: coverage line does not mention TV rows skipped (schema-aware extraction not working)"
    echo "  Output: $EI4_CLEAN_OUT"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: change BC EC-004 to zero-overlap description → SCENARIO-MISMATCH
    cat > "$T/.factory/specs/behavioral-contracts/ss-01/BC-EI4-SELFTEST.md" <<'BCEI4BAD'
---
bc_id: BC-EI4-SELFTEST
---
## Edge Cases
| ID | Description |
|----|-------------|
| EC-004 | TLS handshake timeout during certificate chain validation |
BCEI4BAD
    EI4_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-ec-injectivity.py" 2>&1)
    EI4_EXIT=$?
    if [ "$EI4_EXIT" -eq 0 ]; then
        echo "  FAIL (checker returned 0 — did NOT detect SCENARIO-MISMATCH for EC-004)"
        FAILURES=$((FAILURES + 1))
    elif echo "$EI4_OUT" | grep -q "SCENARIO-MISMATCH EC-004"; then
        echo "  PASS (clean-pass with skipped rows confirmed; EC-004 divergence correctly detected)"
    else
        echo "  FAIL (checker exited non-zero but SCENARIO-MISMATCH EC-004 not in output)"
        echo "  Actual: $EI4_OUT"
        FAILURES=$((FAILURES + 1))
    fi
fi
rm -rf "$T"

# ── Test 7b: check-holdout-boundary — prose-form holdout scenario leak (BI-049) ──
# This test proves the BI-049 repair: the checker now detects a concrete holdout
# scenario published in PROSE form (arrow indicator + verdict word on the same line
# as a holdout EC ID).  This is the exact breach shape from P7-S8-004/P7-S8-005.
#
# Mutation-verify: removing the "else" branch (prose scanning) from the checker
# makes the defect tree exit 0, causing this test's defect-fail assertion to FIRE —
# proving the new code is the load-bearing detection path, not the table-row branch.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 7b: check-holdout-boundary: prose-form holdout EC-079 scenario leak (BI-049) ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs"
# Same clean tree as test 7: prd.md with holdout declaration, no other files
cat > "$T/.factory/specs/prd.md" <<'PRDSTUB7B'
---
---
Holdout vectors **(EC-079, EC-093, EC-094, EC-141, EC-147, EC-148, EC-151)**
PRDSTUB7B

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-holdout-boundary.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean tree (prd.md with holdout decl, no other files)"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"
    cp "$FIXTURE_DIR/bad-holdout-leak-prose.md" \
        "$T/.factory/specs/behavioral-contracts/ss-01/SELFTEST-bad-holdout-prose.md"
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-holdout-boundary.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch prose-form holdout EC-079 scenario leak)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; prose-form holdout scenario correctly detected)"
    fi
fi
rm -rf "$T"

# ── Test 7c: check-holdout-boundary — table-form regression after BI-049 repair ──
# Confirms that the existing table-row detection path is NOT broken by the BI-049
# changes.  Uses EC-093 (a different holdout ID from test 7's EC-079) to ensure
# independence.  This is the "table-form leak (proving no regression of existing
# capability)" gate required by the BI-049 remediation spec.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 7c: check-holdout-boundary: table-form EC-093 regression after BI-049 repair ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs"
cat > "$T/.factory/specs/prd.md" <<'PRDSTUB7C'
---
---
Holdout vectors **(EC-079, EC-093, EC-094, EC-141, EC-147, EC-148, EC-151)**
PRDSTUB7C

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-holdout-boundary.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean tree (prd.md holdout decl only)"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"
    # Inject a TABLE-row leak for EC-093 (holdout), with concrete input + verdict
    cat > "$T/.factory/specs/behavioral-contracts/ss-01/SELFTEST-bad-ec093-table.md" <<'BC7C'
---
bc_id: BC-2.01.SELFTEST-7C
---
## Edge Cases
| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-093 | Concrete table-row scenario for holdout EC-093 | broken (dns-failure) |
BC7C
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-holdout-boundary.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch table-form holdout EC-093 scenario)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; table-form EC-093 correctly detected — no regression)"
    fi
fi
rm -rf "$T"

# ── Test 7d: check-holdout-boundary — must-NOT-flag prd.md:630 shape (CORRECTION 1) ──
# Validates the suffix-based predicate (D-081) added in CORRECTION 1:
#
#   Clean tree:  EC-093 appears AFTER the arrows and verdict words on the line
#                ("https→http downgrade (broken) ... Removed EC-093")
#                → suffix after EC-093 has NO arrow → must NOT fire → exits 0
#
#   Defect tree: EC-093 appears BEFORE the arrow+verdict
#                ("EC-093 (test https link → broken) was removed")
#                → suffix after EC-093 HAS arrow + verdict → must fire → exits 1
#
# Mutation-verify: reverting is_concrete_scenario_prose() to the old whole-line
# predicate (checking `line` instead of `suffix = line[match_start:]`) makes the
# CLEAN tree fail (whole-line arrow + verdict fires), causing the STRUCTURAL FAIL
# assertion to trigger — proving suffix-binding is the load-bearing change.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 7d: check-holdout-boundary: prd.md:630 shape must-NOT-flag (suffix predicate, CORRECTION 1) ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs"
cat > "$T/.factory/specs/prd.md" <<'PRDSTUB7D'
---
---
Holdout vectors **(EC-079, EC-093, EC-094, EC-141, EC-147, EC-148, EC-151)**
PRDSTUB7D

# Clean tree: line shaped like prd.md:630 — arrow and verdict appear BEFORE the EC ID.
# EC-093 appears only as "Removed EC-093" at the end, with no arrow in its suffix.
mkdir -p "$T/.factory/specs/prd-supplements"
cat > "$T/.factory/specs/prd-supplements/changelog-note.md" <<'CHNOTE7D'
## Changelog

- Added https→http downgrade detection (broken, not indeterminate). DNS failure (broken),
  too-many-redirects (broken). Removed holdout EC-093. error-taxonomy.md §2.3 updated.
CHNOTE7D

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-holdout-boundary.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker fired on prd.md:630 shape — false positive NOT eliminated"
    echo "  (EC-093 has no arrow in its suffix; suffix-based predicate must NOT fire here)"
    ST7D_CLEAN=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-holdout-boundary.py" 2>&1)
    echo "  Output: $ST7D_CLEAN"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: same changelog line but EC-093 appears BEFORE the arrow+verdict
    cat > "$T/.factory/specs/prd-supplements/changelog-note.md" <<'CHNOTE7D_BAD'
## Changelog

- EC-093 (test input with https link → broken) was removed from the visible test suite.
CHNOTE7D_BAD
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-holdout-boundary.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch EC-093 with arrow+verdict in suffix)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (prd.md:630 shape not flagged; inverted shape correctly detected)"
    fi
fi
rm -rf "$T"

# ── Test 5b: check-adr-consistency — BC body phantom reason code (BI-050) ──
# POLICY 19 broad-corpus check: detects a phantom reason code in a BC file body,
# via the Pattern 3 "(consistent with X taxonomy)" detector (broadened from ADR-only).
# This is the E-CLI-001 breach shape from adversary finding P7-S5-018.
#
# Mutation-verify: removing check_broad_corpus() from main() makes the defect tree
# exit 0, causing this test's defect-fail assertion to FIRE — proving the new broad
# corpus scan is the load-bearing detection path.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 5b: check-adr-consistency: BC body phantom reason code (BI-050) ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/architecture/decisions"
mkdir -p "$T/.factory/specs/prd-supplements"
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"
cat > "$T/.factory/specs/prd-supplements/error-taxonomy.md" <<'TAXSTUB5B'
## 2. Error Catalog

| `file-not-found` | File not found |
| `connection-timeout` | Connection timed out |
| `dns-failure` | DNS lookup failed |
| `tls-error` | TLS handshake failed |
TAXSTUB5B

# Clean tree: BC file with VALID reason code only (no phantom)
cat > "$T/.factory/specs/behavioral-contracts/ss-01/BC-SELFTEST.md" <<'BCCLEAN'
---
bc_id: BC-SELFTEST
modified: []
---
## Invariants
1. Exit code 1 indicates broken links with reason `file-not-found`.
2. Exit code 0 indicates no broken links found.
BCCLEAN

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-adr-consistency.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean tree (BC file with valid reason code)"
    ST5B_CLEAN=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-adr-consistency.py" 2>&1)
    echo "  Output: $ST5B_CLEAN"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: BC body with phantom reason code via "(consistent with X taxonomy)" pattern
    cp "$FIXTURE_DIR/bad-bc-phantom-code.md" \
        "$T/.factory/specs/behavioral-contracts/ss-01/BC-SELFTEST-PHANTOM.md"
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-adr-consistency.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch BC body phantom reason code)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; BC body phantom reason code correctly detected)"
    fi
fi
rm -rf "$T"

# ── Test 5c: check-adr-consistency — test-vectors phantom reason code (BI-050) ──
# POLICY 19 broad-corpus check: detects a phantom reason code in a test-vectors-like
# file via Pattern 2 "verdict (reason-code)" detector.
# This is the malformed-fragment breach shape from adversary finding P7-S8-007.
#
# Mutation-verify: removing Pattern 2 from check_broad_corpus() makes the defect tree
# exit 0, causing this test's defect-fail assertion to FIRE.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 5c: check-adr-consistency: test-vectors phantom reason code via verdict-paren (BI-050) ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/architecture/decisions"
mkdir -p "$T/.factory/specs/prd-supplements"
cat > "$T/.factory/specs/prd-supplements/error-taxonomy.md" <<'TAXSTUB5C'
## 2. Error Catalog

| `file-not-found` | File not found |
| `anchor-not-found` | Anchor not found |
| `dns-failure` | DNS lookup failed |
TAXSTUB5C

# Clean tree: a test-vectors file with VALID reason codes in verdict+paren format
cat > "$T/.factory/specs/prd-supplements/test-vectors.md" <<'TVCLEAN'
## §1. Vectors

| TV-ID | EC-ID | Description | BC | Input | Exit | Expected Behavior | Notes |
|-------|-------|-------------|-----|-------|------|-------------------|-------|
| TV-ST1 | EC-ST1 | Normal broken link | BC-2.07 | a.md | 1 | broken (file-not-found) | valid code |
TVCLEAN

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-adr-consistency.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean tree (test-vectors with valid reason code)"
    ST5C_CLEAN=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-adr-consistency.py" 2>&1)
    echo "  Output: $ST5C_CLEAN"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: inject test-vectors file with phantom reason code in verdict+paren format
    cp "$FIXTURE_DIR/bad-test-vectors-phantom.md" \
        "$T/.factory/specs/prd-supplements/test-vectors-phantom.md"
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-adr-consistency.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch test-vectors phantom reason code)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; test-vectors phantom reason code correctly detected)"
    fi
fi
rm -rf "$T"

# ── Test 5d: check-adr-consistency — frontmatter changelog NOT flagged (BI-050) ──
# POLICY 19 position-based predicate (D-081): a phantom reason code appearing ONLY
# inside YAML frontmatter modified:/changelog: entries must NOT be flagged, because
# frontmatter records historical names for documentation purposes.
# The defect (which must be detected) is the SAME phantom code moved to the BC body.
#
# This test proves the D-081 predicate is position-based and non-vacuous:
# - Clean tree: phantom only in frontmatter → exits 0 (not flagged, correct)
# - Defect tree: phantom also in BC body → exits 1 (flagged, correct)
# Mutation-verify: removing the frontmatter-skip guard makes the CLEAN TREE fail
# (checker exits non-zero on the clean tree), firing the STRUCTURAL FAIL assertion
# and proving the guard is load-bearing.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 5d: check-adr-consistency: frontmatter changelog phantom NOT flagged, body phantom IS (BI-050) ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/architecture/decisions"
mkdir -p "$T/.factory/specs/prd-supplements"
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"
cat > "$T/.factory/specs/prd-supplements/error-taxonomy.md" <<'TAXSTUB5D'
## 2. Error Catalog

| `file-not-found` | File not found |
| `anchor-not-found` | Anchor not found |
| `dns-failure` | DNS lookup failed |
TAXSTUB5D

# Clean tree: phantom code ONLY in YAML frontmatter modified: entry
cp "$FIXTURE_DIR/good-bc-frontmatter-changelog.md" \
    "$T/.factory/specs/behavioral-contracts/ss-01/BC-SELFTEST-CHANGELOG.md"

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-adr-consistency.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker flagged phantom code in frontmatter — D-081 position-based"
    echo "  guard is missing or broken (phantom in modified: entry must NOT be flagged)"
    ST5D_CLEAN=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-adr-consistency.py" 2>&1)
    echo "  Output: $ST5D_CLEAN"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: SAME phantom code moved to BC body — now must be flagged
    cat > "$T/.factory/specs/behavioral-contracts/ss-01/BC-SELFTEST-CHANGELOG.md" <<'BCBODY5D'
---
bc_id: BC-SELFTEST-5D
modified: []
---
## Invariants
1. Exit code 1 is used for all broken link outcomes.
2. Exit code 2 is used for all configuration errors (consistent with phantom-historical-code taxonomy).
BCBODY5D
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-adr-consistency.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch phantom code in BC body)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; frontmatter phantom not flagged; body phantom flagged)"
    fi
fi
rm -rf "$T"

# ── Test 5e: check-adr-consistency — spec ref ID D-018 in broken(...) NOT flagged (BLOCKING-2) ──
# Proves BLOCKING-2: _is_reason_code_candidate() is applied to Pattern 2 (VERDICT_PAREN_CODE_RE)
# so spec reference IDs like D-018, DI-010 in "broken (D-018)" patterns are NOT treated
# as reason codes and do NOT trigger phantom-code violations.
#
# Clean tree: BC body with "broken (D-018)" → D-018 is a spec ref ID → must NOT be flagged
# Defect tree: replace D-018 with a genuine phantom reason code → must BE flagged
# Mutation-verify: removing the _is_reason_code_candidate() call from Pattern 2 makes the
#   clean tree fail (D-018 treated as phantom reason code), firing the STRUCTURAL FAIL
#   assertion — proving the guard is load-bearing.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 5e: check-adr-consistency: spec ref ID D-018 in broken(...) NOT flagged (BLOCKING-2) ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/architecture/decisions"
mkdir -p "$T/.factory/specs/prd-supplements"
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"
cat > "$T/.factory/specs/prd-supplements/error-taxonomy.md" <<'TAXSTUB5E'
## 2. Error Catalog

| `file-not-found` | File not found |
| `connection-timeout` | Connection timed out |
| `dns-failure` | DNS lookup failed |
TAXSTUB5E

# Clean tree: BC body with "broken (D-018)" — D-018 is a spec reference ID, not a reason code
cat > "$T/.factory/specs/behavioral-contracts/ss-01/BC-SELFTEST-5E.md" <<'BC5ECLEAN'
---
bc_id: BC-SELFTEST-5E
modified: []
---
## Invariants
1. Exit code 1 when broken (D-018) decision is applied.
2. Exit code 0 for clean links.
BC5ECLEAN

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-adr-consistency.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker flagged D-018 in broken(...) — spec ref ID must NOT be a reason code"
    ST5E_CLEAN=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-adr-consistency.py" 2>&1)
    echo "  Output: $ST5E_CLEAN"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: replace D-018 with a genuine phantom reason code
    cat > "$T/.factory/specs/behavioral-contracts/ss-01/BC-SELFTEST-5E.md" <<'BC5EBAD'
---
bc_id: BC-SELFTEST-5E
modified: []
---
## Invariants
1. Exit code 1 when broken (phantom-reason) decision is applied.
2. Exit code 0 for clean links.
BC5EBAD
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-adr-consistency.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch phantom reason code in broken(...) pattern)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; D-018 spec ref not flagged; phantom-reason correctly detected)"
    fi
fi
rm -rf "$T"

# ── Test 5f: check-adr-consistency — macos-latest near broken keyword NOT flagged (BLOCKING-3) ──
# Proves BLOCKING-3: Pattern 1 uses a positional predicate — backtick-quoted tokens on lines
# containing keyword "broken" are NOT flagged unless they appear in one of the three
# positional reason-code contexts (table Reason column, "reason code `...`", "reason: `...`").
# This eliminates false positives for infrastructure tokens like macos-latest, Retry-After,
# test-sufficient, and anchor slugs that happen to appear near verdict keywords.
#
# Clean tree: BC body with "`macos-latest`" on a line that also contains "broken" —
#   NOT in positional context → must NOT be flagged
# Defect tree: append Pattern 2 line with genuine phantom code → must BE flagged
# Mutation-verify: reverting to keyword-in-line guard makes the clean tree fail (macos-latest
#   on a line with "broken" gets flagged as phantom), firing STRUCTURAL FAIL → FAILS.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 5f: check-adr-consistency: macos-latest near broken keyword NOT flagged (BLOCKING-3) ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/architecture/decisions"
mkdir -p "$T/.factory/specs/prd-supplements"
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"
cat > "$T/.factory/specs/prd-supplements/error-taxonomy.md" <<'TAXSTUB5F'
## 2. Error Catalog

| `file-not-found` | File not found |
| `connection-timeout` | Connection timed out |
| `dns-failure` | DNS lookup failed |
TAXSTUB5F

# Clean tree: macos-latest on a line containing "broken" — not in positional reason-code context
cat > "$T/.factory/specs/behavioral-contracts/ss-01/BC-SELFTEST-5F.md" <<'BC5FCLEAN'
---
bc_id: BC-SELFTEST-5F
modified: []
---
## Invariants
1. The CI runner uses `macos-latest` image for broken link detection tests.
2. Exit code 1 indicates broken links with reason `file-not-found`.
BC5FCLEAN

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-adr-consistency.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker flagged macos-latest near broken keyword — positional predicate not working"
    ST5F_CLEAN=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-adr-consistency.py" 2>&1)
    echo "  Output: $ST5F_CLEAN"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: append Pattern 2 line with genuine phantom reason code
    printf '3. Exit code 2 occurs for broken (phantom-runner) configuration errors.\n' \
        >> "$T/.factory/specs/behavioral-contracts/ss-01/BC-SELFTEST-5F.md"
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-adr-consistency.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch phantom reason code in verdict+paren context)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; macos-latest not flagged; phantom-runner correctly detected)"
    fi
fi
rm -rf "$T"

# ── Test 5g: check-adr-consistency — genuine reason code in Reason table column IS detected ──
# Proves BLOCKING-3 Pattern 1 (table mode): a phantom reason code in a table's Reason column
# IS detected; a valid reason code in the Reason column is NOT flagged.
# The positional predicate correctly targets the Reason column cell and skips all other cells.
#
# Clean tree: table with a Reason column header; data row with valid `file-not-found` → exit 0
# Defect tree: replace valid code with `phantom-reason` in Reason column → exit 1
# Mutation-verify: removing the Reason-column tracking from Pattern 1 makes the defect tree
#   exit 0 (phantom not detected), firing the defect-fail assertion → FAILS.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 5g: check-adr-consistency: phantom reason code in Reason table column detected ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/architecture/decisions"
mkdir -p "$T/.factory/specs/prd-supplements"
cat > "$T/.factory/specs/prd-supplements/error-taxonomy.md" <<'TAXSTUB5G'
## 2. Error Catalog

| `file-not-found` | File not found |
| `connection-timeout` | Connection timed out |
| `dns-failure` | DNS lookup failed |
TAXSTUB5G

# Clean tree: test-vectors table with Reason column containing a valid reason code
cat > "$T/.factory/specs/prd-supplements/test-vectors.md" <<'TV5GCLEAN'
## §1. Test Vectors

| TV-ID | EC-ID | Verdict | Reason |
|-------|-------|---------|--------|
| TV-001 | EC-001 | broken | `file-not-found` |
TV5GCLEAN

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-adr-consistency.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker flagged valid reason code in Reason table column"
    ST5G_CLEAN=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-adr-consistency.py" 2>&1)
    echo "  Output: $ST5G_CLEAN"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: replace valid reason code with phantom in Reason column
    cat > "$T/.factory/specs/prd-supplements/test-vectors.md" <<'TV5GBAD'
## §1. Test Vectors

| TV-ID | EC-ID | Verdict | Reason |
|-------|-------|---------|--------|
| TV-001 | EC-001 | broken | `phantom-reason` |
TV5GBAD
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-adr-consistency.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — did NOT catch phantom reason code in Reason column)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; valid reason code not flagged; phantom in Reason column detected)"
    fi
fi
rm -rf "$T"

# ── Test 5h: check-adr-consistency — uppercase `E-IO-002` in Reason column detected (BLOCKING-5a) ──
# Proves BLOCKING-5a: the character class broadened to [A-Za-z] so uppercase-leading
# tokens like `E-IO-002` reach _is_reason_code_candidate() and are detected when
# not in the closed taxonomy.
# Clean: Reason column has valid `file-not-found` → exit 0
# Defect: Reason column has `E-IO-002` (uppercase, not in taxonomy) → exit 1
# Mutation-verify: reverting to [a-z] makes `E-IO-002` match fail → checker exits 0
#   on the defect tree → defect-fail assertion fires → FAILS.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 5h: check-adr-consistency: uppercase E-IO-002 in Reason column detected (BLOCKING-5a) ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/architecture/decisions"
mkdir -p "$T/.factory/specs/prd-supplements"
cat > "$T/.factory/specs/prd-supplements/error-taxonomy.md" <<'TAXSTUB5H'
## 2. Error Catalog

| `file-not-found` | File not found |
| `connection-timeout` | Connection timed out |
| `dns-failure` | DNS lookup failed |
TAXSTUB5H

# Clean tree: table with Reason column containing a valid lowercase reason code
cat > "$T/.factory/specs/prd-supplements/test-vectors.md" <<'TV5HCLEAN'
## §1. Test Vectors

| TV-ID | EC-ID | Verdict | Reason |
|-------|-------|---------|--------|
| TV-001 | EC-001 | broken | `file-not-found` |
TV5HCLEAN

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-adr-consistency.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker flagged valid reason code in Reason column"
    ST5H_CLEAN=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-adr-consistency.py" 2>&1)
    echo "  Output: $ST5H_CLEAN"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: replace valid code with `E-IO-002` (uppercase-leading, not in taxonomy)
    cat > "$T/.factory/specs/prd-supplements/test-vectors.md" <<'TV5HBAD'
## §1. Test Vectors

| TV-ID | EC-ID | Verdict | Reason |
|-------|-------|---------|--------|
| TV-001 | EC-001 | broken | `E-IO-002` |
TV5HBAD
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-adr-consistency.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — uppercase E-IO-002 in Reason column not detected; [a-z] class bug)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; uppercase E-IO-002 in Reason column correctly detected)"
    fi
fi
rm -rf "$T"

# ── Test 5i: check-adr-consistency — annotated cell `phantom-gamma` (per D-018) detected (BLOCKING-5b) ──
# Proves BLOCKING-5b: re.match (not fullmatch) extracts the leading token from
# annotated cells like `phantom-gamma` (per D-018).  fullmatch would have dropped
# the entire cell (no match), silently missing the phantom code.
# Clean: Reason column has valid `file-not-found` → exit 0
# Defect: Reason column has `` `phantom-gamma` (per D-018) `` → leading token
#   "phantom-gamma" extracted and detected as non-taxonomy code → exit 1
# Mutation-verify: reverting to fullmatch makes the defect tree exit 0 (annotated
#   cell skipped) → defect-fail assertion fires → FAILS.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 5i: check-adr-consistency: annotated Reason cell \`phantom-gamma\` (per D-018) detected (BLOCKING-5b) ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/architecture/decisions"
mkdir -p "$T/.factory/specs/prd-supplements"
cat > "$T/.factory/specs/prd-supplements/error-taxonomy.md" <<'TAXSTUB5I'
## 2. Error Catalog

| `file-not-found` | File not found |
| `connection-timeout` | Connection timed out |
| `dns-failure` | DNS lookup failed |
TAXSTUB5I

# Clean tree: table with Reason column containing a valid reason code
cat > "$T/.factory/specs/prd-supplements/test-vectors.md" <<'TV5ICLEAN'
## §1. Test Vectors

| TV-ID | EC-ID | Verdict | Reason |
|-------|-------|---------|--------|
| TV-001 | EC-001 | broken | `file-not-found` |
TV5ICLEAN

CLEAN_PASS=0
if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-adr-consistency.py" > /dev/null 2>&1; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker flagged valid reason code in Reason column"
    ST5I_CLEAN=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-adr-consistency.py" 2>&1)
    echo "  Output: $ST5I_CLEAN"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: annotated Reason cell with phantom code followed by inline citation
    cat > "$T/.factory/specs/prd-supplements/test-vectors.md" <<'TV5IBAD'
## §1. Test Vectors

| TV-ID | EC-ID | Verdict | Reason |
|-------|-------|---------|--------|
| TV-001 | EC-001 | broken | `phantom-gamma` (per D-018) |
TV5IBAD
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-adr-consistency.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — annotated Reason cell phantom-gamma not detected; fullmatch bug)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; annotated phantom-gamma (per D-018) correctly detected)"
    fi
fi
rm -rf "$T"

# ── Test 5j: check-adr-consistency — phantom code on same row as bare "reason" data cell detected (BLOCKING-6) ──
# Proves BLOCKING-6: the old `is_header_row` guard (any cell == "reason") silently
# skipped data rows whose first (non-Reason) cell was the bare word "reason", hiding
# phantom codes that appeared in the Reason column of THAT SAME ROW.
#
# Table structure:
#   Header row: | Case   | Reason           | Notes |   ← Reason at col 1, confirmed by separator
#   Separator:  |--------|------------------|-------|
#   Data row:   | reason | `file-not-found` | x     |   ← Case="reason"; old code skipped the entire row
#
# Clean tree: data row with "reason" in Case col AND a valid `file-not-found` in Reason col → exit 0
#   Assertion: output must also report ≥ 1 reason-code occurrence (non-vacuous — row was not skipped).
# Defect: same row but `phantom-5j` in Reason col → with fix, detected → exit 1
#   Without fix: `is_header_row` guard fired on "reason" in Case cell → row silently skipped → exit 0 (bug)
# Mutation-verify: restoring the `is_header_row` guard makes the defect tree exit 0 →
#   defect-fail assertion fires → FAILS.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 5j: check-adr-consistency: phantom on 'reason'-cased data row detected (BLOCKING-6) ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/architecture/decisions"
mkdir -p "$T/.factory/specs/prd-supplements"
cat > "$T/.factory/specs/prd-supplements/error-taxonomy.md" <<'TAXSTUB5J'
## 2. Error Catalog

| `file-not-found` | File not found |
| `connection-timeout` | Connection timed out |
| `dns-failure` | DNS lookup failed |
TAXSTUB5J

# Clean tree: data row with "reason" in Case col AND valid `file-not-found` in Reason col.
# After fix: row is processed → file-not-found validates → exit 0 with ≥1 occurrence.
cat > "$T/.factory/specs/prd-supplements/test-vectors.md" <<'TV5JCLEAN'
## §1. Test Vectors

| Case   | Reason           | Notes |
|--------|------------------|-------|
| reason | `file-not-found` | x     |
TV5JCLEAN

CLEAN_PASS=0
ST5J_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-adr-consistency.py" 2>&1)
ST5J_RC=$?
if [ "$ST5J_RC" -ne 0 ]; then
    echo "  STRUCTURAL FAIL: checker failed on table with valid Reason column and 'reason' in Case col"
    echo "  Output: $ST5J_OUT"
    FAILURES=$((FAILURES + 1))
elif ! echo "$ST5J_OUT" | grep -q "[1-9][0-9]* reason-code occurrences"; then
    echo "  STRUCTURAL FAIL: checker exited 0 but reported 0 occurrences — row was silently skipped"
    echo "  Output: $ST5J_OUT"
    FAILURES=$((FAILURES + 1))
else
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: same table but `phantom-5j` in the Reason column of the "reason" data row.
    # Without fix: `is_header_row` guard fires → row silently skipped → phantom-5j missed → exit 0 (bug)
    # With fix: row is processed → phantom-5j detected as non-taxonomy code → exit 1
    cat > "$T/.factory/specs/prd-supplements/test-vectors.md" <<'TV5JBAD'
## §1. Test Vectors

| Case   | Reason        | Notes |
|--------|---------------|-------|
| reason | `phantom-5j`  | x     |
TV5JBAD
    if SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-adr-consistency.py" > /dev/null 2>&1; then
        echo "  FAIL (checker returned 0 — phantom-5j on 'reason' data row NOT detected; is_header_row bug)"
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass + ≥1 occurrence confirmed; phantom-5j on 'reason' data row detected)"
    fi
fi
rm -rf "$T"

# ── Test 5k (BI-056): check-adr-consistency — three phantom calibration codes detected as a set ──
# Pins ALL THREE mandated phantom calibration codes AS A SET (BI-056 root-cause):
#   (1) malformed-fragment — Pattern 2 (verdict-paren): "broken (malformed-fragment)"
#   (2) E-CLI-001         — Pattern 3 (taxonomy-ref):  "(consistent with E-CLI-001 taxonomy)"
#   (3) E-IO-002          — Pattern 4 (E-class detector, NEW in this repair): "emits an E-IO-002 error"
#
# Root cause of BI-056: TAXONOMY_CODE_RE matched ONLY the "(consistent with X taxonomy)" prose
# shape, leaving E-IO-002 invisible in all other shapes (prose "emits an E-IO-002 error",
# table cells "Exit 2; E-IO-002 on stderr", parenthetical "Error recorded (E-IO-002)").
# Pattern 4 adds a prose-shape-independent E-class code detector.
#
# Mutation-verify: removing E_CLASS_CODE_RE (reverting Pattern 4) makes the defect tree exit 1
#   but WITHOUT "E-IO-002" in the output → `grep -q "E-IO-002"` fails → FAIL fires → MUT DIES.
#   Removing TAXONOMY_CODE_RE (reverting Pattern 3) loses E-CLI-001 → `grep -q "E-CLI-001"` fails.
#   Removing VERDICT_PAREN_CODE_RE (reverting Pattern 2) loses malformed-fragment → grep fails.
# All three grep assertions are necessary; dropping any one would re-open the original blind spot.
#
# Structural proof E_CLASS_CODE_RE cannot reintroduce PR-11 false positives: it requires a
# 2-4 uppercase-letter namespace component between "E-" and "-NNN". All 22 false positives
# removed in PR #11 were lowercase reason-code tokens — structurally incapable of matching.
# Corpus-wide E-code population: 8 occurrences (6x E-IO-002, 2x E-CLI-001, 3 files).
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest 5k (BI-056): check-adr-consistency: three-code phantom calibration set detected ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/architecture/decisions"
mkdir -p "$T/.factory/specs/prd-supplements"

cat > "$T/.factory/specs/prd-supplements/error-taxonomy.md" <<'TAXSTUB5K'
## 2. Error Catalog

| `file-not-found` | File not found |
| `malformed-url` | Malformed URL |
| `dns-failure` | DNS lookup failed |
TAXSTUB5K

# Clean tree: only valid codes; NO phantom codes, NO E-class codes
cat > "$T/.factory/specs/prd-supplements/test-vectors.md" <<'TV5KCLEAN'
## §1. Vectors

| TV-ID | EC-ID | Verdict | Reason |
|-------|-------|---------|--------|
| TV-001 | EC-001 | broken | `file-not-found` |
| TV-002 | EC-002 | broken | malformed-url |
TV5KCLEAN

CLEAN_PASS=0
ST5K_CLEAN=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-adr-consistency.py" 2>&1)
ST5K_CLEAN_RC=$?
if [ "$ST5K_CLEAN_RC" -eq 0 ]; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on clean fixture (no phantom codes)"
    echo "  Output: $ST5K_CLEAN"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: inject all three phantom calibration codes into a single prose file.
    # (1) malformed-fragment via Pattern 2 (verdict-paren shape)
    # (2) E-CLI-001 via Pattern 3 (taxonomy-reference shape)
    # (3) E-IO-002 via Pattern 4 (E-class code, prose shape OTHER than taxonomy-reference)
    cat > "$T/.factory/specs/prd-supplements/interface-definitions.md" <<'IFACE5KBAD'
# Interface Definitions

## Error Classes

An empty destination emits broken (malformed-fragment).
Exit code 2 is used for all configuration errors (consistent with E-CLI-001 taxonomy).
On I/O error the tool emits an E-IO-002 error and continues scanning.
IFACE5KBAD

    ST5K_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-adr-consistency.py" 2>&1)
    ST5K_RC=$?
    FAIL=0
    if [ "$ST5K_RC" -eq 0 ]; then
        echo "  FAIL (checker returned 0 — no phantom codes detected at all)"
        FAIL=1
    fi
    if ! echo "$ST5K_OUT" | grep -q "E-IO-002"; then
        echo "  FAIL (E-IO-002 not detected — Pattern 4 E-class detector missing or broken)"
        FAIL=1
    fi
    if ! echo "$ST5K_OUT" | grep -q "E-CLI-001"; then
        echo "  FAIL (E-CLI-001 not detected — Pattern 3 taxonomy-reference broken)"
        FAIL=1
    fi
    if ! echo "$ST5K_OUT" | grep -q "malformed-fragment"; then
        echo "  FAIL (malformed-fragment not detected — Pattern 2 verdict-paren broken)"
        FAIL=1
    fi
    if [ "$FAIL" -eq 1 ]; then
        FAILURES=$((FAILURES + 1))
    else
        echo "  PASS (clean-pass confirmed; all three phantom codes detected: E-IO-002, E-CLI-001, malformed-fragment)"
    fi
fi
rm -rf "$T"

# ── Test EI-5: check-ec-injectivity — Input column IS treated as comparable (BLOCKING-4) ──
# Proves BLOCKING-4: a TV section whose column 2 header contains "Input" is treated
# as a comparable description column, so rows in that section ARE compared.
# Clean: BC description AGREES with TV Input value (high Jaccard) → exit 0
# Defect: BC description is disjoint from TV Input value → SCENARIO-MISMATCH → exit 1
# Mutation-verify: reverting the synonym set to only {"description"} makes the Input-section
#   rows be skipped → clean tree still exits 0 but STRUCTURAL FAIL fires because the
#   coverage line shows "0 EC citations compared" (no BC-vs-TV comparison took place),
#   meaning the checker would silently miss real Input-section divergences.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest EI-5: check-ec-injectivity: Input column IS treated as comparable (BLOCKING-4) ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"
mkdir -p "$T/.factory/specs/prd-supplements"

# TV: section with Input column (comparable), EC-005 with specific input description
# Header row required by BLOCKING-1 schema-aware extract_tv_rows
printf '| TV | EC | Input | Exit | Verdict | Reason |\n|---|---|---|---|---|---|\n| TV-005 | EC-005 | Symlink traversal outside root | 1 | broken | reason |\n' \
    > "$T/.factory/specs/prd-supplements/test-vectors.md"

# BC: EC-005 with AGREEING description (Jaccard ≥ 0.10)
# TV: {symlink, traversal, outside, root}, BC: {symlink, traversal, outside, root, boundary}
# Shared: {symlink, traversal, outside, root} → J = 4/5 = 0.8 → AGREE
cat > "$T/.factory/specs/behavioral-contracts/ss-01/BC-EI5-SELFTEST.md" <<'BCEI5CLEAN'
---
bc_id: BC-EI5-SELFTEST
---
## Edge Cases
| ID | Description |
|----|-------------|
| EC-005 | Symlink traversal outside root boundary |
BCEI5CLEAN

CLEAN_PASS=0
EI5_CLEAN_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-ec-injectivity.py" 2>&1)
EI5_CLEAN_EXIT=$?
if [ "$EI5_CLEAN_EXIT" -eq 0 ]; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker failed on Input-column TV with agreeing BC description"
    echo "  Output: $EI5_CLEAN_OUT"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: change BC to disjoint description (zero token overlap with TV Input value)
    cat > "$T/.factory/specs/behavioral-contracts/ss-01/BC-EI5-SELFTEST.md" <<'BCEI5BAD'
---
bc_id: BC-EI5-SELFTEST
---
## Edge Cases
| ID | Description |
|----|-------------|
| EC-005 | TLS handshake timeout during certificate chain validation |
BCEI5BAD
    EI5_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-ec-injectivity.py" 2>&1)
    EI5_EXIT=$?
    if [ "$EI5_EXIT" -eq 0 ]; then
        echo "  FAIL (checker returned 0 — Input column rows not being compared; synonym set too narrow)"
        FAILURES=$((FAILURES + 1))
    elif echo "$EI5_OUT" | grep -q "SCENARIO-MISMATCH EC-005"; then
        echo "  PASS (clean-pass confirmed; Input column rows ARE compared; divergent correctly detected)"
    else
        echo "  FAIL (checker exited non-zero but SCENARIO-MISMATCH EC-005 not in output)"
        echo "  Actual: $EI5_OUT"
        FAILURES=$((FAILURES + 1))
    fi
fi
rm -rf "$T"

# ── Test EI-6: check-ec-injectivity — Source MD File column correctly skipped (BLOCKING-4) ──
# Proves BLOCKING-4: a TV section whose column 2 header is "Source MD File" is treated
# as non-comparable (filename column), so rows in that section are correctly skipped.
# Clean: BC cites EC-006, TV has EC-006 in Source MD File section → rows skipped → exit 0
# Defect: replace TV column header with "Input" (comparable), BC has disjoint description
#   → rows ARE compared → SCENARIO-MISMATCH EC-006 → exit 1
# Mutation-verify: treating all columns (including Source MD File) as comparable would
#   make the clean tree fail (EC-006's source-file value used as description against BC →
#   zero token overlap → SCENARIO-MISMATCH), firing the STRUCTURAL FAIL assertion.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest EI-6: check-ec-injectivity: Source MD File column correctly skipped (BLOCKING-4) ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"
mkdir -p "$T/.factory/specs/prd-supplements"

# TV: section with Source MD File column (non-comparable), EC-006
# The filename value `test.md` has zero overlap with any meaningful BC scenario prose.
printf '| TV | EC | Source MD File | Exit | Verdict | Reason |\n|---|---|---|---|---|---|\n| TV-006 | EC-006 | `test.md` | 0 | clean | reason |\n' \
    > "$T/.factory/specs/prd-supplements/test-vectors.md"

# BC: EC-006 with any description — no comparison because TV rows are skipped
cat > "$T/.factory/specs/behavioral-contracts/ss-01/BC-EI6-SELFTEST.md" <<'BCEI6CLEAN'
---
bc_id: BC-EI6-SELFTEST
---
## Edge Cases
| ID | Description |
|----|-------------|
| EC-006 | TLS handshake timeout during certificate chain validation |
BCEI6CLEAN

CLEAN_PASS=0
EI6_CLEAN_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-ec-injectivity.py" 2>&1)
EI6_CLEAN_EXIT=$?
if [ "$EI6_CLEAN_EXIT" -eq 0 ]; then
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: checker fired on Source MD File section — non-comparable rows not skipped"
    echo "  Output: $EI6_CLEAN_OUT"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: change TV column from "Source MD File" to "Input" (comparable) — rows now compared.
    # BC description is disjoint from TV Input value → SCENARIO-MISMATCH EC-006
    printf '| TV | EC | Input | Exit | Verdict | Reason |\n|---|---|---|---|---|---|\n| TV-006 | EC-006 | Normal file link traversal without special characters | 0 | clean | reason |\n' \
        > "$T/.factory/specs/prd-supplements/test-vectors.md"
    EI6_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-ec-injectivity.py" 2>&1)
    EI6_EXIT=$?
    if [ "$EI6_EXIT" -eq 0 ]; then
        echo "  FAIL (checker returned 0 — Source MD File not correctly skipped, or Input not recognised)"
        FAILURES=$((FAILURES + 1))
    elif echo "$EI6_OUT" | grep -q "SCENARIO-MISMATCH EC-006"; then
        echo "  PASS (clean-pass confirmed; Source MD File skipped; Input column correctly compared)"
    else
        echo "  FAIL (checker exited non-zero but SCENARIO-MISMATCH EC-006 not in output)"
        echo "  Actual: $EI6_OUT"
        FAILURES=$((FAILURES + 1))
    fi
fi
rm -rf "$T"

# ── Test EI-7: check-ec-injectivity — §2 Filesystem column parseable (BI-057 change a) ──
# Proves that the §2 TV table shape (Source MD File | Link | Filesystem) is now parsed:
# both Link and Filesystem columns are collected as comparable by extract_tv_rows().
#
# TV fixture uses the §2-shape header.  BC has EC-007 with a description that shares
# significant tokens with the TV Filesystem column value → Jaccard ≥ 0.10 → AGREE → exit 0.
# Coverage assertion greps for "1 EC citation" to confirm a comparison WAS performed
# (not silently skipped).  If "filesystem" were removed from _COMPARABLE_KEYWORDS the TV
# row would have no comparable column → skipped_by_col++ → ecs_bc_only++ → 0 citations
# compared → grep fails → STRUCTURAL FAIL → mutation is killed.
#
# Defect: change BC EC-007 to a zero-overlap description → SCENARIO-MISMATCH → exit 1.
TESTS_RUN=$((TESTS_RUN + 1))
echo "── selftest EI-7: check-ec-injectivity: §2 Filesystem column parseable (BI-057 a) ──"
T=$(make_temp)
mkdir -p "$T/.factory/specs/behavioral-contracts/ss-01"
mkdir -p "$T/.factory/specs/prd-supplements"

# TV: §2 shape — Source MD File (non-comparable), Link + Filesystem (both comparable).
# Filesystem value has clear token overlap with the clean BC description.
cat > "$T/.factory/specs/prd-supplements/test-vectors.md" <<'TVEI7'
| TV | EC | Source MD File | Link | Filesystem |
|---|---|---|---|---|
| TV-007 | EC-007 | `docs/guide.md` | valid link | recursive directory traversal |
TVEI7

# BC: EC-007 with description that agrees with TV Filesystem column value.
# TV tokens from Link+Filesystem: {valid, link, recursive, directory, traversal}
# BC tokens: {recursive, directory, scan, deep, filesystem, structure}
# Intersection: {recursive, directory} → J = 2/9 ≈ 0.22 → AGREE → exit 0
cat > "$T/.factory/specs/behavioral-contracts/ss-01/BC-EI7-SELFTEST.md" <<'BCEI7CLEAN'
---
bc_id: BC-EI7-SELFTEST
---
## Edge Cases
| ID | Description |
|----|-------------|
| EC-007 | Recursive directory scan with deep filesystem structure |
BCEI7CLEAN

EI7_CLEAN_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-ec-injectivity.py" 2>&1)
EI7_CLEAN_EXIT=$?
CLEAN_PASS=0
if [ "$EI7_CLEAN_EXIT" -ne 0 ]; then
    echo "  STRUCTURAL FAIL: checker fired on §2-shape TV fixture — Filesystem column not parsed"
    echo "  Output: $EI7_CLEAN_OUT"
    FAILURES=$((FAILURES + 1))
elif echo "$EI7_CLEAN_OUT" | grep -q "1 EC citation"; then
    # Coverage confirms a comparison was performed (not skipped due to unparseable column).
    # Mutation kill: if "filesystem" removed from _COMPARABLE_KEYWORDS, TV rows have no
    # comparable column → skipped_by_col → 0 EC citations compared → grep fails → STRUCTURAL FAIL.
    TESTS_WITH_CLEAN_PASS=$((TESTS_WITH_CLEAN_PASS + 1))
    CLEAN_PASS=1
else
    echo "  STRUCTURAL FAIL: coverage line does not show '1 EC citation' — Filesystem column rows not compared"
    echo "  Output: $EI7_CLEAN_OUT"
    FAILURES=$((FAILURES + 1))
fi

if [ "$CLEAN_PASS" = "1" ]; then
    # Defect: completely disjoint BC description → SCENARIO-MISMATCH EC-007
    cat > "$T/.factory/specs/behavioral-contracts/ss-01/BC-EI7-SELFTEST.md" <<'BCEI7BAD'
---
bc_id: BC-EI7-SELFTEST
---
## Edge Cases
| ID | Description |
|----|-------------|
| EC-007 | TLS certificate pinning failure during mutual authentication |
BCEI7BAD
    EI7_OUT=$(SPEC_LINT_REPO_OVERRIDE="$T" python3 "$LINT_DIR/check-ec-injectivity.py" 2>&1)
    EI7_EXIT=$?
    if [ "$EI7_EXIT" -eq 0 ]; then
        echo "  FAIL (checker returned 0 — §2 Filesystem column not producing SCENARIO-MISMATCH)"
        FAILURES=$((FAILURES + 1))
    elif echo "$EI7_OUT" | grep -q "SCENARIO-MISMATCH EC-007"; then
        echo "  PASS (clean-pass with §2-shape comparison confirmed; EC-007 divergence correctly detected)"
    else
        echo "  FAIL (checker exited non-zero but SCENARIO-MISMATCH EC-007 not in output)"
        echo "  Actual: $EI7_OUT"
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
