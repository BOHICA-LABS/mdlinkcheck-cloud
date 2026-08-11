# justfile — local task runner for mdlinkcheck
#
# Mirrors CI exactly so `just ci` reproduces the full pipeline locally.
# With no remote, `just ci` IS the canonical CI gate.
#
# Usage:
#   just <recipe>       run a single recipe
#   just --list         list all recipes
#   just ci             run full CI pipeline (fmt-check + lint + test + build-release)
#   just hardening      run Phase-6 hardening checks locally
#
# Prerequisites (install with `just install-tools`):
#   cargo-nextest   0.9.98+    cargo install cargo-nextest --locked
#   cargo-audit     0.21.2+    cargo install cargo-audit --locked
#   cargo-deny      0.19.0+    cargo install cargo-deny --locked
#   cargo-mutants   24.11.2+   cargo install cargo-mutants --locked
#   cargo-fuzz                 cargo install cargo-fuzz --locked (needs nightly)
#   semgrep         1.75.0+    pip install semgrep
#   hyperfine                  brew install hyperfine / cargo install hyperfine

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
    cargo nextest run --locked --all-targets

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
# ci — full pipeline, matching CI job order
#
# Gate order matters: fmt-check and lint must pass before test/build
# so slow jobs don't run on obviously broken code.
# ─────────────────────────────────────────────────────────────────
ci: fmt-check lint test build-release spec-lint purity
    @echo ""
    @echo "CI pipeline passed."

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
    harness_files=$(grep -rl '#\[kani::proof\]' . --include='*.rs' 2>/dev/null | wc -l | tr -d ' ' || echo "0")
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
# Scans crates/mdlinkcheck-core/src/ for forbidden import patterns.
# Emits a runtime-computed coverage line and exits non-zero on any hit.
# Not a branch-protection required check — run on every PR via ci.yml
# as an erosion gate for the 7 downstream stories.
# ─────────────────────────────────────────────────────────────────
purity:
    #!/usr/bin/env bash
    set -euo pipefail
    CORE_SRC="crates/mdlinkcheck-core/src"
    # ADR-001 forbidden import patterns for mdlinkcheck-core
    PATTERNS=(
        'use std::fs'
        'use std::net'
        'use std::io::stdout'
        'use std::time::Instant'
        'use rand'
        'extern crate rand'
    )
    file_count=$(find "${CORE_SRC}" -name '*.rs' | wc -l | tr -d ' ')
    violations=0
    for pat in "${PATTERNS[@]}"; do
        if grep -rn "${pat}" "${CORE_SRC}" --include='*.rs' 2>/dev/null; then
            violations=$((violations + 1))
        fi
    done
    echo "purity: ${file_count} file(s) in ${CORE_SRC} scanned, ${violations} forbidden-pattern(s) found"
    if [ "${violations}" -gt 0 ]; then
        echo "FAIL: ADR-001 purity boundary violated in mdlinkcheck-core — remove the imports above"
        exit 1
    fi
    echo "PASS: mdlinkcheck-core is free of forbidden I/O and RNG imports (ADR-001)"

# ─────────────────────────────────────────────────────────────────
# spec-lint — run all spec integrity validators (no Cargo required)
#
# Validates cross-references, ID uniqueness, counts, placeholder
# removal, holdout boundaries, and index integrity across the
# .factory/specs/ artifact package.
#
# All validators must exit 0 before Phase 1 gate passes.
# ─────────────────────────────────────────────────────────────────
spec-lint:
    #!/usr/bin/env bash
    set -euo pipefail
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
        if python3 "scripts/spec-lint/${check}.py"; then
            echo "  PASS"
        else
            echo "  FAIL"
            FAILURES=$((FAILURES + 1))
        fi
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
    cargo install cargo-nextest --locked --version 0.9.98
    cargo install cargo-audit --locked --version 0.21.2
    cargo install cargo-deny --locked --version 0.19.0
    cargo install cargo-mutants --locked --version 24.11.2
    cargo +nightly install cargo-fuzz --locked
    @echo ""
    @echo "Install semgrep separately: pip install semgrep==1.75.0"
    @echo "Install hyperfine separately: brew install hyperfine"
    @echo ""
    @echo "All Cargo tools installed."
