# justfile — local task runner for mdlinkcheck
#
# Provides local equivalents for CI jobs.  `just ci` runs the blocking gates
# (fmt-check, lint, test, build-release, purity) plus spec-lint in advisory mode.
# With no remote, `just ci` IS the canonical gate for blocking checks.
# Not covered by `just ci` (separate recipes exist): msrv-check, vef-selftest,
# verify-evidence-figures.  ci.yml has 9 jobs; `just ci` covers the 5 blocking ones.
#
# Usage:
#   just <recipe>       run a single recipe
#   just --list         list all recipes
#   just ci             run blocking CI gates + advisory spec-lint
#   just hardening      run Phase-6 hardening checks locally
#
# Prerequisites (install with `just install-tools`):
#   cargo-nextest    0.9.98    cargo install cargo-nextest --locked --version 0.9.98
#   cargo-audit      0.21.2    cargo install cargo-audit --locked --version 0.21.2
#   cargo-deny       0.19.0    cargo install cargo-deny --locked --version 0.19.0
#   cargo-mutants    24.11.2   cargo install cargo-mutants --locked --version 24.11.2
#   cargo-fuzz       0.13.2    cargo +nightly install cargo-fuzz --version 0.13.2 (no --locked; see install-tools)
#   kani-verifier    0.67.0    cargo install kani-verifier --version 0.67.0 --locked
#   semgrep          1.75.0+   pip install semgrep==1.75.0
#   hyperfine                  brew install hyperfine / cargo install hyperfine
# Note: D-260 (operator ruling) — CI-verified pins above take precedence over
# tooling-selection.md:36-45 spec values for 5 of 6 tools; do NOT "correct" toward spec.

set shell := ["bash", "-euo", "pipefail", "-c"]
set windows-shell := ["powershell.exe", "-NoLogo", "-Command"]

# ─────────────────────────────────────────────────────────────────
# Default: list available recipes
# ─────────────────────────────────────────────────────────────────
default:
    @just --list

# ─────────────────────────────────────────────────────────────────
# fmt — auto-format all crates
# ─────────────────────────────────────────────────────────────────
fmt:
    cargo fmt --all

# ─────────────────────────────────────────────────────────────────
# fmt-check — check formatting without modifying files (CI gate)
# ─────────────────────────────────────────────────────────────────
fmt-check:
    cargo fmt --all --check

# ─────────────────────────────────────────────────────────────────
# lint — clippy with deny-warnings (matches CI lint job)
# ─────────────────────────────────────────────────────────────────
lint:
    cargo clippy --locked --all-targets --all-features -- -D warnings

# ─────────────────────────────────────────────────────────────────
# test — run full test suite with nextest (matches CI test job)
#
# Cross-platform correctness (D-006): path case-sensitivity and NFC
# normalization must be verified on macOS (case-insensitive) and
# Linux (case-sensitive).  Run on Windows via WSL or native.
# ─────────────────────────────────────────────────────────────────
test:
    #!/usr/bin/env bash
    set -euo pipefail
    cargo nextest run --locked --all-targets
    # POL-11: positive-coverage assertion (ci_positive_coverage_assertion).
    # Prevents a silent false-green where a test binary drops out of the run
    # without any compile error (harness = false, wrong path, etc.).
    # See architecture spec tooling-selection.md:155-160 (POL-11).
    #
    # NOTE: The frozen spec's literal counting command is:
    #   cargo nextest list | grep -c '^tests::'
    # That returns 0 in this project — nextest's output uses the format
    # "crate::binary test_name" (0.9.129+) or an indented form (0.9.98);
    # neither uses "^tests::" prefix.  The commands below implement the
    # spec's INTENT using empirically-verified patterns that work for both
    # nextest output formats.
    # Raise POL11_TEST_FLOOR / POL11_BIN_FLOOR when new tests or binaries are added.
    # Verified baseline: 44 tests across 6 binaries (2026-08-11).
    POL11_TEST_FLOOR=44
    POL11_BIN_FLOOR=6
    test_count=$(cargo nextest list --locked --all-targets 2>/dev/null | { grep -cE '[[:space:]]+test_' || true; })
    bin_count=$(cargo nextest list --locked --all-targets --list-type binaries-only 2>/dev/null | wc -l | tr -d ' ')
    if [ "${test_count}" -lt "${POL11_TEST_FLOOR}" ]; then
        echo "POL-11 FAIL: test count ${test_count} is below floor ${POL11_TEST_FLOOR}"
        echo "  A test binary may have silently dropped out of the run."
        echo "  Raise POL11_TEST_FLOOR in justfile and ci.yml when new tests are added."
        exit 1
    fi
    if [ "${bin_count}" -lt "${POL11_BIN_FLOOR}" ]; then
        echo "POL-11 FAIL: binary count ${bin_count} is below floor ${POL11_BIN_FLOOR}"
        echo "  A test binary may have been lost."
        echo "  Raise POL11_BIN_FLOOR in justfile and ci.yml when new binaries are added."
        exit 1
    fi
    echo "POL-11 PASS: ${test_count} tests across ${bin_count} binaries (floors: ${POL11_TEST_FLOOR}/${POL11_BIN_FLOOR})"

# ─────────────────────────────────────────────────────────────────
# build — debug build
# ─────────────────────────────────────────────────────────────────
build:
    cargo build

# ─────────────────────────────────────────────────────────────────
# build-release — release build (matches CI build-release job)
# ─────────────────────────────────────────────────────────────────
build-release:
    cargo build --locked --release

# ─────────────────────────────────────────────────────────────────
# ci — blocking CI gates + advisory spec-lint
#
# Gate order: fmt-check and lint must pass before test/build so slow
# jobs don't run on obviously broken code.  purity is a hard gate
# (ADR-001 boundary enforcement for the 7 downstream stories).
#
# spec-lint is ADVISORY (matches ci.yml treatment): check-ec-injectivity
# exits 1 by design per operator ruling D-246 (39 SCENARIO-MISMATCH are
# expected on develop), so spec-lint cannot be a blocking prerequisite.
# ─────────────────────────────────────────────────────────────────
ci: fmt-check lint test build-release purity
    #!/usr/bin/env bash
    set -euo pipefail
    # Run spec-lint advisory — output is visible and clearly labelled ADVISORY.
    # Failure here does NOT block the pipeline (matches ci.yml: spec-lint is not
    # a required status check).  Fix spec violations before Phase 1 gate.
    echo ""
    echo "── spec-lint (ADVISORY — not a blocking gate; matches ci.yml treatment) ──"
    spec_exit=0
    just spec-lint || spec_exit=$?
    if [ "${spec_exit}" -ne 0 ]; then
        echo ""
        echo "spec-lint: ADVISORY FAIL (exit ${spec_exit})"
        echo "  Expected on develop per D-246. Fix before Phase 1 gate but does not block just ci."
    else
        echo ""
        echo "spec-lint: ADVISORY PASS"
    fi
    echo ""
    echo "CI pipeline passed."

# ─────────────────────────────────────────────────────────────────
# audit — cargo-audit vulnerability scan (hardening)
# ─────────────────────────────────────────────────────────────────
audit:
    cargo audit

# ─────────────────────────────────────────────────────────────────
# deny — cargo-deny license / ban / advisory check (hardening)
# ─────────────────────────────────────────────────────────────────
deny:
    cargo deny --locked check

# ─────────────────────────────────────────────────────────────────
# semgrep — static analysis with auto rules (hardening)
# ─────────────────────────────────────────────────────────────────
semgrep:
    semgrep --config=auto --error --metrics=off .

# ─────────────────────────────────────────────────────────────────
# mutants — mutation smoke run (hardening, ~10 min)
#
# --test-tool nextest: use the same test runner as every per-PR gate
#   (cargo nextest), so a regression manifesting under one runner
#   but not the other is not invisible for up to a week.
# --cargo-arg=--locked: matches the --locked flag on all other gates
#   so dependency resolution cannot silently re-resolve.
# ─────────────────────────────────────────────────────────────────
mutants:
    cargo mutants --test-tool nextest --no-shuffle -j2 --timeout 30 --cargo-arg=--locked -- --all-targets

# ─────────────────────────────────────────────────────────────────
# fuzz-smoke — fuzz each target for 30 seconds (hardening, needs nightly)
# ─────────────────────────────────────────────────────────────────
fuzz-smoke:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ ! -d fuzz ]; then
        echo "No fuzz/ directory found — nothing to do."
        exit 0
    fi
    for target in $(cargo +nightly fuzz list 2>/dev/null); do
        echo "Fuzzing ${target} for 30s..."
        cargo +nightly fuzz run "${target}" -- -max_total_time=30 -max_len=65536
    done

# ─────────────────────────────────────────────────────────────────
# kani — bounded model checking (hardening)
# ─────────────────────────────────────────────────────────────────
kani:
    #!/usr/bin/env bash
    set -euo pipefail
    harness_count=$(grep -rl '#\[kani::proof\]' . --include='*.rs' 2>/dev/null || true)
    harness_count=$(echo "${harness_count}" | grep -c . || true)
    if [ "${harness_count}" -eq 0 ]; then
        echo "No Kani proof harnesses found — nothing to do."
        exit 0
    fi
    echo "Found ${harness_count} file(s) containing Kani proof harnesses — running cargo kani."
    cargo kani --locked

# ─────────────────────────────────────────────────────────────────
# hardening — run all Phase-6 gates locally
#
# Distinguishes EXECUTED (had real inputs) from NO-OP (nothing to run)
# so the aggregate line is truthful rather than asserting six checks
# passed when two structurally had no inputs.
# ─────────────────────────────────────────────────────────────────
hardening: audit deny semgrep mutants fuzz-smoke kani
    #!/usr/bin/env bash
    set -euo pipefail
    executed="audit deny semgrep mutants"
    noop=""
    if [ ! -d fuzz ]; then
        noop="${noop} fuzz-smoke"
    else
        executed="${executed} fuzz-smoke"
    fi
    # Fix (Finding 4): the previous form was:
    #   harness_files=$(grep ... | wc -l | tr -d ' ' || echo "0")
    # Under pipefail, grep exits 1 on no matches; wc and tr still ran and
    # emitted "0"; then "|| echo 0" fired too, yielding "0\n0" — a two-line
    # string that failed integer comparison and forced the EXECUTED branch.
    # Fix mirrors the kani recipe: put '|| true' on the grep itself so the
    # pipeline always exits 0 and wc receives clean input.
    harness_files=$({ grep -rl '#\[kani::proof\]' . --include='*.rs' 2>/dev/null || true; } | wc -l | tr -d ' ')
    if [ "${harness_files}" -eq 0 ]; then
        noop="${noop} kani"
    else
        executed="${executed} kani"
    fi
    echo ""
    echo "Hardening complete."
    echo "  EXECUTED: ${executed}"
    if [ -n "${noop}" ]; then
        echo "  NO-OP (no inputs):${noop}"
    fi

# ─────────────────────────────────────────────────────────────────
# bench — R8 performance budget check
#
# R8: checking a repo with 500 md files and no external URLs must
# complete in under 5 seconds on a developer laptop.
#
# Usage:
#   just bench PATH=/path/to/docs-repo
#   just bench            (defaults to current directory)
# ─────────────────────────────────────────────────────────────────
bench PATH=".":
    #!/usr/bin/env bash
    set -euo pipefail
    if ! command -v hyperfine &>/dev/null; then
        echo "hyperfine not found. Install with: brew install hyperfine"
        exit 1
    fi
    cargo build --release 2>/dev/null
    echo "Running R8 performance benchmark against: {{ PATH }}"
    hyperfine \
        --warmup 3 \
        --runs 10 \
        --export-markdown bench-results.md \
        --export-json bench-results.json \
        "./target/release/mdlinkcheck {{ PATH }}"
    echo ""
    echo "R8 budget: < 5s on 500 md files.  See bench-results.md for details."

# ─────────────────────────────────────────────────────────────────
# check — fast compilation check (no binary produced)
# ─────────────────────────────────────────────────────────────────
check:
    cargo check --all-targets

# ─────────────────────────────────────────────────────────────────
# msrv-check — verify the workspace compiles on the declared MSRV
#
# Declared MSRV: 1.88 (operator-authorized deviation from frozen spec
# value of 1.85 — see D-205; globset 0.4.20 and ignore 0.4.33 both
# require rustc 1.88, and downgrading would invalidate F-A1/F-P2-01
# correctness arguments grounded in ignore 0.4.33 behavior).
#
# Toolchain 1.88 must be installed: rustup toolchain install 1.88
# ─────────────────────────────────────────────────────────────────
msrv-check:
    cargo +1.88 check --all-targets --locked

# ─────────────────────────────────────────────────────────────────
# doc — build documentation
# ─────────────────────────────────────────────────────────────────
doc:
    cargo doc --no-deps --open

# ─────────────────────────────────────────────────────────────────
# clean — remove build artifacts
# ─────────────────────────────────────────────────────────────────
clean:
    cargo clean

# ─────────────────────────────────────────────────────────────────
# purity — ADR-001 boundary check: mdlinkcheck-core must not import I/O or RNG
#
# Scans crates/mdlinkcheck-core/src/ for forbidden path-fragments.
# Detects direct imports, grouped imports, AND fully-qualified calls.
# Not a branch-protection required check — run on every PR via ci.yml
# as an erosion gate for the 7 downstream stories.
# ─────────────────────────────────────────────────────────────────
purity:
    #!/usr/bin/env bash
    set -euo pipefail
    CORE_SRC="crates/mdlinkcheck-core/src"
    # ADR-001 forbidden-path detector (broadened from original six-pattern form).
    #
    # Detects ALL of: direct imports, grouped imports, and fully-qualified calls.
    #   Direct:       "use std::fs;"            → matches "std::fs"
    #   Grouped:      "use std::{fs, path};"    → matches "std::\{[^}]*\bfs\b"
    #   Fully-qual:   "std::fs::read_to_string" → matches "std::fs"
    #
    # The previous form required "use " prefix — "use std::{fs, path::PathBuf};"
    # plus fs::metadata() bypassed it silently (orchestrator-verified bypass).
    # Discrimination verified: grouped form, fully-qualified form, and clean tree
    # all produce the correct gate result (report in finding P15-F2).
    #
    # Comment-only lines (// and //!) are excluded — they describe the rule
    # without being executable (types.rs:7-8 is one such doc-comment).
    FORBIDDEN_RE='(std::fs|std::\{[^}]*\bfs\b|std::net|std::\{[^}]*\bnet\b|std::io::stdout|std::io::\{[^}]*\bstdout\b|std::time::Instant|std::time::\{[^}]*\bInstant\b|\buse rand\b|rand::|extern crate rand)'

    # ── Self-check (L-87 remedy) ──────────────────────────────────────────────
    # Plant a grouped-import + fully-qualified violation; assert detector fires;
    # remove plant; then scan the real tree.  A gate that has never fired is not
    # verified (lesson L-87: the previous gate passed with a live fs call present).
    SELFTEST=$(mktemp /tmp/purity-selftest-XXXXX.rs)
    trap 'rm -f "${SELFTEST}"' EXIT
    printf 'fn _planted() { use std::{fs as _f, path::PathBuf}; let _ = std::fs::read_to_string("x"); }\n' > "${SELFTEST}"
    if ! grep -qE "${FORBIDDEN_RE}" "${SELFTEST}" 2>/dev/null; then
        echo "PURITY SELF-CHECK FAILED: detector blind to grouped-import or fully-qualified violation"
        echo "  Gate infrastructure is broken — this is NOT a clean-tree result."
        exit 1
    fi
    echo "purity self-check: PASS (detector fires on grouped-import and fully-qualified forms)"
    rm -f "${SELFTEST}"
    trap - EXIT

    # ── Fail closed ──────────────────────────────────────────────────────────
    # An empty source directory means the gate is scanning nothing.
    file_count=$(find "${CORE_SRC}" -name '*.rs' 2>/dev/null | wc -l | tr -d ' ')
    if [ "${file_count}" -eq 0 ]; then
        echo "FAIL: ${CORE_SRC} contains no .rs files — gate is scanning nothing (fail-closed per POL-11)"
        exit 1
    fi

    # ── Scan for forbidden patterns, excluding comment-only lines ─────────────
    violation_output=$(grep -rn -E "${FORBIDDEN_RE}" "${CORE_SRC}" --include='*.rs' 2>/dev/null | grep -vE '^[^:]+:[0-9]+:[[:space:]]*//' || true)
    violations=$(echo "${violation_output}" | { grep -c . || true; })

    echo "purity: ${file_count} file(s) in ${CORE_SRC} scanned, ${violations} forbidden-path match(es) found"
    echo "  Patterns: std::fs, std::net, std::io::stdout, std::time::Instant, use rand, rand::"
    echo "  Both grouped (use std::{fs,...}) and fully-qualified (std::fs::fn()) forms detected."
    if [ "${violations}" -gt 0 ]; then
        echo "${violation_output}"
        echo "FAIL: ADR-001 purity boundary violated in mdlinkcheck-core."
        echo "  Remove or move I/O and RNG code to the effectful crate (mdlinkcheck)."
        exit 1
    fi
    echo "PASS: ${file_count} .rs file(s) checked; no forbidden I/O or RNG path-fragments found (ADR-001)."
    echo "  Note: both non-grouped and grouped import forms were checked."

# ─────────────────────────────────────────────────────────────────
# spec-lint — run all spec integrity validators (no Cargo required)
#
# Validates cross-references, ID uniqueness, counts, placeholder
# removal, holdout boundaries, and index integrity across the
# .factory/specs/ artifact package.
#
# Worktree-aware: when run from a story worktree (.worktrees/<name>/),
# .factory/specs/ is absent from the worktree tree.  The recipe detects
# this and either sets SPEC_LINT_REPO_OVERRIDE automatically (main
# checkout two levels up) or emits a LOUD-SKIP that cannot be misread
# as nine spec violations.
#
# All validators must exit 0 before Phase 1 gate passes.
# ─────────────────────────────────────────────────────────────────
spec-lint:
    #!/usr/bin/env bash
    set -euo pipefail

    # Finding 7: Worktree-awareness for spec corpus location.
    # In a story worktree (.worktrees/<name>/), .factory/specs/ does not exist
    # as a real directory — git worktrees do not share the main tree's
    # .factory/ content (it lives on the factory-artifacts orphan branch).
    # The spec-lint primitives honour SPEC_LINT_REPO_OVERRIDE; derive it
    # automatically rather than crashing with misleading "9 spec failures"
    # that are purely environmental, not real spec defects.
    if [ ! -d ".factory/specs" ]; then
        CANDIDATE_ROOT="$(cd ../../ 2>/dev/null && pwd || echo "")"
        if [ -n "${CANDIDATE_ROOT}" ] && [ -d "${CANDIDATE_ROOT}/.factory/specs" ]; then
            export SPEC_LINT_REPO_OVERRIDE="${CANDIDATE_ROOT}"
            echo "[spec-lint] Worktree detected: using SPEC_LINT_REPO_OVERRIDE=${SPEC_LINT_REPO_OVERRIDE}"
        else
            echo ""
            echo "LOUD-SKIP: spec corpus (.factory/specs/) is not reachable from '$(pwd)'"
            echo "  and was not found at '${CANDIDATE_ROOT:-../..}/.factory/specs' either."
            echo "  This is NOT nine spec failures — the corpus is unavailable in this location."
            echo "  Set SPEC_LINT_REPO_OVERRIDE manually to the main checkout path to run spec-lint."
            echo ""
            echo "spec-lint SKIPPED (corpus unavailable) — not a failure, not a pass."
            exit 0
        fi
    fi

    CHECKS=(
        "check-title-sync"
        "check-ec-injectivity"
        "check-id-resolution"
        "check-counts"
        "check-placeholders"
        "check-holdout-boundary"
        "check-adr-consistency"
        "check-index-integrity"
        "check-canonical-facts"
    )
    FAILURES=0
    for check in "${CHECKS[@]}"; do
        echo "── ${check} ──"
        ret=0
        python3 "scripts/spec-lint/${check}.py" || ret=$?
        case $ret in
            0) echo "  PASS" ;;
            2) echo "  ERROR (infrastructure — required input files missing)"
               FAILURES=$((FAILURES + 1)) ;;
            *) echo "  FAIL (spec violation found)"
               FAILURES=$((FAILURES + 1)) ;;
        esac
        echo ""
    done
    if [ "${FAILURES}" -gt 0 ]; then
        echo "spec-lint FAILED: ${FAILURES}/${#CHECKS[@]} checks failed"
        exit 1
    fi
    echo "spec-lint passed: all ${#CHECKS[@]} checks clean"

# ─────────────────────────────────────────────────────────────────
# spec-lint-selftest — prove each checker can actually detect defects
#
# Injects known-bad fixtures and asserts each checker exits non-zero.
# A checker that has never been observed failing provides no guarantee.
# ─────────────────────────────────────────────────────────────────
spec-lint-selftest:
    #!/usr/bin/env bash
    set -euo pipefail
    bash scripts/spec-lint/selftest/run-selftests.sh

# ─────────────────────────────────────────────────────────────────
# spec-gen — regenerate derived spec artifacts from sources
#
# Generators are idempotent. Run after hotfixes to ensure derived
# content stays in sync with authoritative sources.
#
# NOTE: generators use BEGIN/END GENERATED markers. Add markers
# to target files first (see each generator's docstring).
# ─────────────────────────────────────────────────────────────────
spec-gen:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "── gen-ec-registry ──"
    python3 scripts/spec-lint/gen-ec-registry.py
    echo ""
    echo "── gen-bc-index ──"
    python3 scripts/spec-lint/gen-bc-index.py
    echo ""
    echo "── gen-prd-sections ──"
    python3 scripts/spec-lint/gen-prd-sections.py
    echo ""
    echo "── gen-rtm ──"
    python3 scripts/spec-lint/gen-rtm.py
    echo ""
    echo "spec-gen complete"

# ─────────────────────────────────────────────────────────────────
# install-tools — install all required dev tools
# ─────────────────────────────────────────────────────────────────
install-tools:
    # Tool versions are CI-verified pins per D-260 (operator ruling 2026-08-11).
    # tooling-selection.md:36-45 names different versions for 5 of 6 tools
    # (spec: cargo-fuzz 0.13.1, cargo-mutants 27.0.0, cargo-nextest 0.9.129,
    # semgrep 1.56.0, hyperfine 2.0.0); the CI-tested values below take
    # precedence.  Do NOT "correct" toward spec values without a new operator ruling.
    #
    # cargo-fuzz: --locked is intentionally absent.
    # Verified: `cargo fuzz run` does not accept --locked (exits "unexpected argument
    # '--locked' found").  The --locked sweep at f24ad3e covered deny/mutants/kani
    # but not fuzz — that absence is correct, not an oversight.
    cargo install cargo-nextest --locked --version 0.9.98
    cargo install cargo-audit --locked --version 0.21.2
    cargo install cargo-deny --locked --version 0.19.0
    cargo install cargo-mutants --locked --version 24.11.2
    # SEC-2 fix: pinned to exact version to prevent supply-chain substitution (matches hardening.yml:229).
    cargo +nightly install cargo-fuzz --version 0.13.2
    # SEC-1 fix: required for `just hardening` kani recipe (matches hardening.yml:275).
    cargo install kani-verifier --version 0.67.0 --locked
    @echo ""
    @echo "Install semgrep separately: pip install semgrep==1.75.0"
    @echo "Install hyperfine separately: brew install hyperfine"
    @echo ""
    @echo "All Cargo tools installed (nextest, audit, deny, mutants, cargo-fuzz, kani-verifier)."
