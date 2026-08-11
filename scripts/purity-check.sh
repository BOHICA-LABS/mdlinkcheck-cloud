#!/usr/bin/env bash
#
# ADR-001 purity gate for mdlinkcheck-core — forbidden I/O and RNG detector.
#
# WHY THIS IS A SCRIPT AND NOT INLINE (BI-090)
# ---------------------------------------------
# This logic previously existed as two hand-maintained copies: one inline in the
# `purity` job of .github/workflows/ci.yml, one inline in the `purity` recipe of
# the justfile.  Keeping two copies byte-identical was a standing obligation that
# produced defects in THREE consecutive adversarial review rounds (BI-081, then
# P22-01/P23-01/P24-01, then P24-02).  Both call sites now invoke this single
# file, so the duplication class is closed by construction rather than by
# discipline.  Do not re-inline it.
#
# WHAT ADR-001 ACTUALLY REQUIRES
# -------------------------------
# ADR-001-pure-core-effectful-shell.md states:
#
#   "No function in `mdlinkcheck-core` may call `std::fs`, `std::net`,
#    `std::io::stdout`, `std::time::Instant::now`, random-number generators,
#    or any other I/O primitive."
#
# Note the closing catch-all — "or any other I/O primitive".  ADR-001 does NOT
# merely enumerate four path fragments; it enumerates four and then generalises.
# This matters, and getting it wrong has already caused harm: a prior review pass
# found the macro-I/O gap (`println!` writes to stdout) and DECLINED to file it,
# on the stated grounds that "ADR-001's text enumerates path-fragments, not
# macros".  That justification was false, it had been committed into this gate's
# own output, and a reviewer relied on it (findings P23-02 / P24-03).
#
# So the scope boundary below is an admission about what grep can enforce, NOT a
# claim that ADR-001 permits what is unenforced.  See the SCOPE section.
#
# TWO-PHASE DETECTION
# -------------------
# Phase A is line-oriented.  It catches call sites and fully-qualified paths and
# yields precise file:line locations.
#
# Phase B is statement-scoped over a newline-collapsed stream.  It exists because
# `grep` is line-oriented and therefore structurally blind to a grouped `use`
# statement split across lines — which is the shape `rustfmt` PRODUCES once the
# statement exceeds max_width, and `cargo fmt --all --check` is a required gate.
# Phase B is scoped with [^;]* (to the statement terminator) rather than [^}]*
# (to the first closing brace), so it also spans sibling-nested groups such as
#   use std::{collections::{BTreeMap, BTreeSet}, fs};
# where a brace-scoped class cannot reach `fs` without crossing the inner `}`.
#
# The arms deliberately OVERLAP: several single-line shapes are caught by both
# phases.  That is defence in depth and is intentional.  The self-check below
# therefore asserts a property that is actually true — that every enumerated
# evasion shape is caught by the detector AS A WHOLE — and does NOT claim that
# each individual alternation arm is independently load-bearing, because it is
# not, and claiming so was itself finding P24-02.
#
# Usage:  scripts/purity-check.sh [core-src-dir]
# Exit:   0 = clean, 1 = violation found or gate infrastructure broken.

set -euo pipefail

CORE_SRC="${1:-crates/mdlinkcheck-core/src}"

# ── Phase A: call sites and fully-qualified paths (line-oriented) ─────────────
# `io::stdout` has no leading \b so that intermediate-module aliasing is caught:
# `use std::io as _i; _i::stdout()` — a leading \b would fail after the word
# character in `_i`.  Same reasoning omits a leading \b nowhere else.
LINE_RE='(\bfs::|\bnet::|io::stdout|\bstdout[[:space:]]*\(|\bInstant::|time::Instant|\buse rand\b|rand::|extern crate rand)'

# ── Phase B: `use std::...` import statements of ANY shape ────────────────────
# Statement-scoped, applied to a newline-collapsed stream: single-line, grouped,
# nested, and multi-line forms all reduce to the same match.
STMT_RE='use[[:space:]]+std::(\{[^;]*\b(fs|net|stdout|Instant)\b|fs\b|net\b|io::\{[^;]*\bstdout\b|io::stdout\b|time::\{[^;]*\bInstant\b|time::Instant\b)'

# Comment-only lines (// and //!) are excluded: they describe the rule rather
# than executing it (mdlinkcheck-core/src/types.rs has such a doc block naming
# all four forbidden fragments).  Trailing comments on a code line are NOT
# stripped — a forbidden fragment inside one would be reported.  Accepted.
strip_comments() { grep -vE '^[[:space:]]*//' "$1" || true; }

# Detect in one file. Prints "file:line:text" hits (Phase A) and/or a
# file-scoped note (Phase B). Returns 0 if anything was found.
detect_in_file() {
    local f="$1" hits normalized
    hits="$(strip_comments "$f" | grep -nE "$LINE_RE" | sed "s|^|${f}:|" || true)"
    normalized="$(strip_comments "$f" | tr '\n' ' ')"
    if printf '%s' "$normalized" | grep -qE "$STMT_RE"; then
        # Phase B has no line number: the match may span lines by construction.
        hits="${hits:+${hits}
}${f}: forbidden std import detected by statement scan (may span multiple lines)"
    fi
    [ -n "$hits" ] && { printf '%s\n' "$hits"; return 0; }
    return 1
}

# ── Self-check: assert the detector fires on each enumerated evasion shape ────
#
# Each plant is written to its own file and asserted INDIVIDUALLY, so a plant
# cannot be satisfied by a sibling plant.  (It may still be satisfied by a
# sibling ARM — see the note above; that is intentional overlap, not a claim of
# per-arm isolation.)
#
# Plants 17-21 are the multi-line and sibling-nested shapes that the pre-BI-090
# single-phase detector was blind to.  They are the reason Phase B exists; do not
# remove them, and do not collapse them onto one line.
PLANTS=(
    'fn _p01() { use std::fs; let _ = fs::metadata("x"); }'
    'fn _p02() { use std::{fs, path::PathBuf}; let _: Option<PathBuf> = None; }'
    'fn _p03() { let _ = std::fs::read_to_string("x"); }'
    'fn _p04() { use std::net::TcpStream; let _: Option<TcpStream> = None; }'
    'fn _p05() { use std::{net::TcpStream}; let _: Option<TcpStream> = None; }'
    'fn _p06() { use std::io::{stdout, Write}; let mut o = stdout(); let _ = o.flush(); }'
    'fn _p07() { use std::{io::stdout, fmt::Debug}; let _: Option<&dyn Debug> = None; }'
    'fn _p08() { use std::io::{self, Write}; let _ = io::stdout(); }'
    'fn _p09() { use std::io as _i; let _ = _i::stdout(); }'
    'fn _p10() { use std::time::{Duration, Instant}; let _ = Duration::from_secs(1); }'
    'fn _p11() { use std::{time::Instant}; let _ = 1; }'
    'fn _p12() { use std::time::{self}; let _ = time::Instant::now(); }'
    'fn _p13() { use std::time as _t; let _ = _t::Instant::now(); }'
    'fn _p14() { let _ = rand::random::<u8>(); }'
    'fn _p15() { use rand; }'
    'fn _p16() { extern crate rand; }'
    'use std::{\n    collections::{BTreeMap, BTreeSet},\n    fs,\n};\nfn _p17() { let _: Option<BTreeSet<u8>> = None; }'
    'use std::io::{\n    stdout,\n    Write,\n};\nfn _p18() { let _ = 1; }'
    'use std::{\n    collections::BTreeMap,\n    net::TcpStream,\n};\nfn _p19() { let _: Option<BTreeMap<u8, u8>> = None; }'
    'use std::time::{\n    Duration,\n    Instant,\n};\nfn _p20() { let _ = Duration::from_secs(1); }'
    'use std::{collections::{BTreeMap, BTreeSet}, fs};\nfn _p21() { let _: Option<BTreeSet<u8>> = None; }'
)

# Negative controls.  Without these, a detector that matched EVERYTHING would
# pass every plant above and make the clean-tree PASS meaningless.  _n5 is the
# multi-line form of mdlinkcheck-core's real import block.
CLEAN=(
    'fn _n1() { use std::collections::BTreeMap; let _: BTreeMap<u8, u8> = BTreeMap::new(); }'
    'fn _n2() { use std::{fmt::Debug, cmp::Ordering}; let _ = Ordering::Equal; }'
    'fn _n3() { use std::time::Duration; let _ = Duration::from_secs(1); }'
    'fn _n4() { use std::path::Path; let _ = Path::new("x"); }'
    'use std::{\n    collections::{HashMap, HashSet},\n    ffi::OsString,\n    path::PathBuf,\n};\nfn _n5() { let _ = 1; }'
    'fn _n6() { fn randomize() {} randomize(); }'
)

# Trailing X's are REQUIRED.  BSD/macOS mktemp only substitutes TRAILING X's; a
# template like `purity-selftest-XXXXX.rs` (X's followed by a suffix) is returned
# LITERALLY and unsubstituted, so the name is a constant.  The first call creates
# it and every concurrent call then fails "File exists", and any ungraceful exit
# before the trap leaves the gate unrunnable until the file is removed by hand
# (finding P22-02, confirmed by execution on darwin).
SELFTEST="$(mktemp "${TMPDIR:-/tmp}/purity-selftest-XXXXXXXX")"
trap 'rm -f "${SELFTEST}"' EXIT

for plant in "${PLANTS[@]}"; do
    printf '%b\n' "${plant}" > "${SELFTEST}"
    if ! detect_in_file "${SELFTEST}" >/dev/null; then
        echo "PURITY SELF-CHECK FAILED: detector blind to this evasion shape:"
        printf '%b\n' "    ${plant}"
        echo "  Gate infrastructure is broken — this is NOT a clean-tree result."
        exit 1
    fi
done

for clean in "${CLEAN[@]}"; do
    printf '%b\n' "${clean}" > "${SELFTEST}"
    if detect_in_file "${SELFTEST}" >/dev/null; then
        echo "PURITY SELF-CHECK FAILED: detector matches a CLEAN sample (false positive):"
        printf '%b\n' "    ${clean}"
        echo "  A detector that matches everything makes the PASS below meaningless."
        exit 1
    fi
done

echo "purity self-check: PASS (${#PLANTS[@]} evasion shapes each detected; ${#CLEAN[@]} clean samples each not matched)"
rm -f "${SELFTEST}"
trap - EXIT

# ── Fail closed: an empty source tree means the gate checked nothing ──────────
file_count="$(find "${CORE_SRC}" -name '*.rs' 2>/dev/null | wc -l | tr -d ' ')"
if [ "${file_count}" -eq 0 ]; then
    echo "FAIL: ${CORE_SRC} contains no .rs files — gate is scanning nothing (fail-closed per POL-11)"
    exit 1
fi

# ── Scan the real tree ───────────────────────────────────────────────────────
violations=0
violation_output=""
while IFS= read -r f; do
    if out="$(detect_in_file "$f")"; then
        violation_output="${violation_output:+${violation_output}
}${out}"
        violations=$((violations + 1))
    fi
done < <(find "${CORE_SRC}" -name '*.rs' 2>/dev/null)

echo "purity: ${file_count} file(s) in ${CORE_SRC} scanned, ${violations} file(s) with forbidden-path matches"
echo "  Forbidden paths: std::fs, std::net, std::io::stdout, std::time::Instant, RNG (rand)."
if [ "${violations}" -gt 0 ]; then
    printf '%s\n' "${violation_output}"
    echo "FAIL: ADR-001 purity boundary violated in mdlinkcheck-core."
    echo "  Remove or move I/O and RNG code to the effectful crate (mdlinkcheck)."
    exit 1
fi

echo "PASS: ${file_count} .rs file(s) checked; no forbidden I/O or RNG path-fragments found (ADR-001)."
# ── SCOPE: state exactly what was and was not checked ────────────────────────
# This block must never assert coverage broader than the detector provides, and
# must never attribute its own scope limits to ADR-001. Both errors have shipped
# here before (BI-081, then P23-02/P24-03).
echo "  COVERED, for all four forbidden std paths, in any import shape:"
echo "    non-grouped, grouped (brace after std:: or after the submodule),"
echo "    sibling-nested, MULTI-LINE (rustfmt-split), leaf-aliased (as _x),"
echo "    intermediate-module-aliased (use std::io as _i), and call sites."
echo "  NOT COVERED — grep cannot enforce these, and ADR-001 DOES forbid them:"
echo "    macro-generated I/O (println!/print!/eprintln!/write!) and other"
echo "    I/O primitives not in ADR-001's explicit four (io::stdin, io::stderr,"
echo "    std::process, std::env, SystemTime::now)."
echo "    ADR-001 enumerates four paths and then generalises: 'or any other I/O"
echo "    primitive'. The gap above is a limit of THIS CHECK, not a permission"
echo "    granted by ADR-001. Extending it is an operator decision."
