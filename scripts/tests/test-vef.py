#!/usr/bin/env python3
"""Mutation-verified selftest suite for scripts/verify-evidence-figures.py.

13 test cases (T01-T13).  Each proves:
  DEFECT PRESENT  -- verifier exits non-zero (failure / refused)
  DEFECT ABSENT   -- verifier exits 0 (clean default fixture passes)

Test isolation: _VEF_TEST_* env vars redirect all file I/O and subprocess
calls to a temp directory.  The real repo is used for git commands (which
the verifier routes through _SCRIPT_REPO regardless of _VEF_TEST_REPO),
but provenance stamp verification is skipped in test mode.

Run:  python3 scripts/tests/test-vef.py
Reports: N/N tests verified (each proved clean-pass + defect-fail)
"""

import os, re, shutil, subprocess, sys, tempfile
from pathlib import Path

REPO     = Path(__file__).resolve().parent.parent.parent
VERIFIER = REPO / "scripts" / "verify-evidence-figures.py"
EV_DIR_REL = "docs/demo-evidence/CHECKER-COMPLETENESS-GATE35"

# ── Mock tool outputs ─────────────────────────────────────────────────────────
# MOCK_HEAD chosen to contain no live EI figures (174/42/22) or combined
# rc+ec digits that would trigger the novel-spelling scans.
MOCK_HEAD   = "deadbeef0011feedface0011deadbeef00110011"   # 40 chars
MOCK_HEAD_7 = MOCK_HEAD[:7]    # "deadbee"

MOCK_ADR_OUT = (
    "adr-consistency: check complete\n"
    "9 violations found (78 reason-code occurrences + 6 E-class code occurrences)\n"
    "E-class population: population=8, examined=6, skipped=2\n"
    "  BC-2.01.009.md:44: E-class code 'E-IO-002'\n"
    "  BC-2.01.009.md:52: E-class code 'E-IO-002'\n"
    "  BC-2.01.009.md:71: E-class code 'E-IO-002'\n"
    "  BC-2.01.009.md:73: E-class code 'E-IO-002'\n"
    "  interface-definitions.md:237: E-class code 'E-IO-002'\n"
    "  BC-2.11.004.md:61: E-class code 'E-CLI-001'\n"
)

# EI summary must be on ONE LINE -- STANDARD_PAT runs without re.DOTALL.
MOCK_EI_OUT = (
    "ec-injectivity: check complete\n"
    "174 EC citations compared (17 legitimately-EC-less skipped), "
    "42 divergent, 22 require adjudication\n"
)

MOCK_ST_OUT = "Selftest passed: 99/99\n"

# ── Fixtures ──────────────────────────────────────────────────────────────────
# PR_FIXTURE satisfies every verifier check in one self-consistent document.
#
# Coverage accounting (for clean-pass guarantee):
#   RC_EC_PAT matches in docs (PR+EV):  3 (PR) + 3 (EV) = 6  >= MIN 5
#   Ledger triples in pr+ev:            1 (PR) + 2 (EV) = 3  == MIN 3
#   EI cmp_found:  STANDARD(3)+BOLD_REV(1)+TRANSITION(1)+SINGLE_CMP(1)+EV_CMP(4) = 10 >= MIN 9
#   EI div_found:  STANDARD(3)+BOLD_REV(1)+TRANSITION(1)+EV_DIV(4)               =  9 >= MIN 9
#   EI adj_found:  STANDARD(3)+BOLD_REV(1)+TRANSITION(1)+EV_ADJ(3)               =  8 >= MIN 8
#   PREV_LABEL lines in EV: exactly 2
#   Novel-spelling (ADR): all combined 78+reason-code+6+E-class on same line
#                          are covered by RC_EC_PAT -- no novel-spelling fires
#   Novel-spelling (EI):  all 174/42/22 near EI-CTX are within a pattern span
PR_FIXTURE = f"""\
# PR: CHECKER-COMPLETENESS-GATE35

**Head SHA:** {MOCK_HEAD}

[![selftests-99%2F99](https://img.shields.io/badge/selftests-99%2F99-green)](AC-002)

## check-adr-consistency

9 violations (78 reason-code + 6 E-class occ); ADR gap disclosed.
78 reason-code occurrences + 6 E-class code occurrences confirmed.
E-class population: pop=8, examined=6, skipped=2

| Check | Before | After |
|-------|--------|-------|
| ec-injectivity | 110 cmp, 9 div, 5 adj | **42 DIVERGENT + 22 ADJUDICATION; 174 of 174 TV rows compared** |
| adr-consistency | 4 violations | 9 violations (78 reason-code + 6 E-class occ) |

## check-ec-injectivity

ec-injectivity now compares 174 of 174 citations (17 EC-less skipped).
174 citations compared (17 legitimately-EC-less skipped), 42 divergent, 22 adjudication.
→174 ec-injectivity comparisons; →42 divergent; →22 adjudication

## E-class Site Validation

(6 E-class code occurrences validated).  Detection confirmed at:
`BC-2.01.009.md:44,52,71,73`, `interface-definitions.md:237`, `BC-2.11.004.md:61`.

## Rollback

```
git revert 39efec2 72db558 b4bbbc3 ca8c1c0 f6dfa58 aaaa111 bbbb222 cccc333 dddd444 eeee555 ffff666 fedcba1
```

Rollback reverts all 12 commits.
"""

# EV_FIXTURE satisfies every verifier check that reads evidence-report.md.
# Exactly 2 "Previous (post-gate34)" lines -- SUGGESTION-9 assertion.
# EI lines (no_prev): four lines giving the correct counts for all patterns.
EV_FIXTURE = f"""\
# Evidence Report -- CHECKER-COMPLETENESS-GATE35

**Head SHA:** {MOCK_HEAD_7}

## Summary

| AC | Description | Status |
|----|-------------|--------|
| AC-1 | Pre-flight guard: 0 unproven scope reductions; 10/10 primitives | PASS |
| AC-2 | Full selftest suite: 99/99 pass | PASS |
| AC-5 | check-adr-consistency live corpus: 9 violations (78 reason-code + 6 E-class code occ) | PASS |
| AC-6 | check-ec-injectivity live corpus: 174 citations compared | PASS |

## Evidence Files

- `AC-001-preflight.txt` -- pre-flight guard output
- `AC-002-selftest-99of99.txt` -- full selftest run confirming 99/99
- `AC-005-adr-consistency-live.txt` -- live corpus run
- `AC-006-ec-injectivity-live.txt` -- live corpus run

## Key Baselines

### check-adr-consistency

- Previous (post-gate34): 4 violations, 0 E-class detections
- After this PR: 9 violations (78 reason-code occurrences + 6 E-class code occ)
- 78 reason-code occurrences + 6 E-class code occ confirmed
- E-class population: population=8, examined=6, skipped=2
- See AC-007. population=8, examined=6, skipped=2

### check-ec-injectivity

- Previous (post-gate34): 110 citations compared (80 skipped), 9 divergent, 5 adjudication
- After this PR: **174 citations compared** (17 skipped), **42 divergent**, **22 adjudication**
- 174 citations compared (17 skipped), 42 divergent, 22 adjudication
- 174 citations compared; 42 divergent
- 42 divergent, 22 adjudication

## Selftest Run (99/99 confirmed)

See `AC-002-selftest-99of99.txt`.
"""


# ── Test environment ──────────────────────────────────────────────────────────
class TestEnv:
    """Isolated temp directory with pre-written fixtures and mock outputs."""

    def __init__(self):
        self._tmpdir = tempfile.mkdtemp(prefix="vef-test-")
        root = Path(self._tmpdir)

        # Directory skeleton expected by verifier
        ev_dir = root / EV_DIR_REL
        ev_dir.mkdir(parents=True)
        pr_dir = root / ".factory/code-delivery/CHECKER-COMPLETENESS-GATE35"
        pr_dir.mkdir(parents=True)

        # Fixture documents
        self.pr_path = pr_dir / "pr-description.md"
        self.ev_path = ev_dir / "evidence-report.md"
        self.pr_path.write_text(PR_FIXTURE)
        self.ev_path.write_text(EV_FIXTURE)

        # Mock tool output files (pointed to by _VEF_TEST_*_FILE vars)
        self.adr_file = root / "mock-adr.txt"
        self.ei_file  = root / "mock-ei.txt"
        self.st_file  = root / "mock-st.txt"
        self.gh_file  = root / "mock-gh.txt"
        self.adr_file.write_text(MOCK_ADR_OUT)
        self.ei_file.write_text(MOCK_EI_OUT)
        self.st_file.write_text(MOCK_ST_OUT)
        self.gh_file.write_text(PR_FIXTURE)   # live PR body == pr_path (in sync)

        # AC-002 stub required by check4a-ac002-suffix glob
        (ev_dir / "AC-002-selftest-99of99.txt").write_text("selftest run: 99/99\n")

        self.root    = root
        self.ev_dir  = ev_dir
        self.n_ahead = "12"   # default: feature branch with 12 commits

    def run(self):
        """Run the verifier under _VEF_TEST_* overrides; return (rc, combined output)."""
        env = {
            **os.environ,
            "_VEF_TEST_REPO"    : str(self.root),
            "_VEF_TEST_ADR_FILE": str(self.adr_file),
            "_VEF_TEST_EI_FILE" : str(self.ei_file),
            "_VEF_TEST_ST_FILE" : str(self.st_file),
            "_VEF_TEST_N_AHEAD" : self.n_ahead,
            "_VEF_TEST_HEAD"    : MOCK_HEAD,
            "_VEF_TEST_GH_BODY" : str(self.gh_file),
        }
        r = subprocess.run(
            [sys.executable, str(VERIFIER)],
            capture_output=True, text=True, env=env,
            cwd=str(REPO),   # real repo as cwd so git operations have valid history
        )
        return r.returncode, r.stdout + r.stderr

    def cleanup(self):
        shutil.rmtree(self._tmpdir, ignore_errors=True)


def run_test(name, defect_fn, clean_fn=None, expect_rc=None):
    """Execute defect-present and defect-absent cases; return True if both pass.

    defect_fn(env)  -- mutates the env so the target check should fail
    clean_fn(env)   -- optional; applies any clean-state setup (default: no mutation)
    expect_rc       -- expected rc for defect case (default: != 0, i.e., any failure)
    """
    results = []

    # Defect present
    env_d = TestEnv()
    try:
        defect_fn(env_d)
        rc_d, out_d = env_d.run()
        if expect_rc is not None:
            defect_ok = (rc_d == expect_rc)
        else:
            defect_ok = (rc_d != 0)
        if not defect_ok:
            marker = f"rc=={expect_rc}" if expect_rc is not None else "rc!=0"
            print(f"    FAIL {name} [defect-present]: expected {marker}, got rc={rc_d}")
            print(f"      output: {out_d[:400]!r}")
        results.append(defect_ok)
    finally:
        env_d.cleanup()

    # Defect absent (clean)
    env_c = TestEnv()
    try:
        if clean_fn:
            clean_fn(env_c)
        rc_c, out_c = env_c.run()
        clean_ok = (rc_c == 0)
        if not clean_ok:
            print(f"    FAIL {name} [clean]: expected rc=0, got rc={rc_c}")
            print(f"      output: {out_c[:600]!r}")
        results.append(clean_ok)
    finally:
        env_c.cleanup()

    passed = all(results)
    print(f"  {'PASS' if passed else 'FAIL'}  {name}")
    return passed


# ── Test cases ────────────────────────────────────────────────────────────────

def t01_post_merge_context():
    """Item 0: n_ahead=0 triggers REFUSED (exit 2)."""
    def defect(env): env.n_ahead = "0"
    return run_test("T01 post-merge-context [exit-2]", defect, expect_rc=2)


def t02_rollback_removed():
    """SUGGESTION-8 check7-rollback: git revert absent -> anchor_check fail + REQUIRED_CHECKS gate."""
    def defect(env):
        text = re.sub(r"git revert .*\n", "# rollback omitted\n", env.pr_path.read_text())
        env.pr_path.write_text(text)
        env.gh_file.write_text(text)
    return run_test("T02 rollback-removed [check7-rollback]", defect)


def t03_head_sha_ev_absent():
    """SUGGESTION-8 check9-head-sha-ev: **Head SHA:** absent from ev -> anchor_check fail."""
    def defect(env):
        text = re.sub(r"\*\*Head SHA:\*\*.*\n", "", env.ev_path.read_text())
        env.ev_path.write_text(text)
    return run_test("T03 head-sha-ev-absent [check9]", defect)


def t04_ecli001_absent():
    """SUGGESTION-8 check2a-e-cli-001: E-CLI-001 absent from live adr output -> anchor_check fail."""
    def defect(env):
        text = env.adr_file.read_text().replace("E-CLI-001", "E-CLI-XXX")
        env.adr_file.write_text(text)
    return run_test("T04 e-cli-001-absent [check2a]", defect)


def t05_ac002_absent():
    """SUGGESTION-8 check4a-ac002-suffix: AC-002 file absent -> anchor_check fail."""
    def defect(env):
        for f in env.ev_dir.glob("AC-002*.txt"):
            f.unlink()
    return run_test("T05 ac002-absent [check4a]", defect)


def t06_prev_label_replaced():
    """SUGGESTION-9: 'Previous (post-gate34)' replaced -> ev-baseline/prev-lines fails."""
    def defect(env):
        text = env.ev_path.read_text().replace("Previous (post-gate34)", "Previous (legacy)")
        env.ev_path.write_text(text)
    return run_test("T06 prev-label-replaced [SUGGESTION-9]", defect)


def t07_ei_novel_spelling():
    """SUGGESTION-10 EI: 174 near 'divergent' not covered by any pattern -> novel-spelling fail."""
    # '174 citations found' has 'found' not 'compared' -- no STANDARD_PAT match.
    # '42 divergent' is also present -- EI_CTX fires on '174' (divergent within window).
    def defect(env):
        novel = "Post-review: 174 citations found, 42 divergent, 22 adjudication cases.\n"
        new_pr = env.pr_path.read_text() + novel
        env.pr_path.write_text(new_pr)
        env.gh_file.write_text(new_pr)
    return run_test("T07 ei-novel-spelling [SUGGESTION-10]", defect)


def t08_adr_novel_spelling():
    """SUGGESTION-10 ADR: combined 78+reason-code+6+E-class without '+' connector -> novel-spelling fail."""
    # RC_EC_PAT requires 'reason-code...+...E-class'; 'detections, ...E-class' has no '+'.
    def defect(env):
        novel = "Post-fix: 78 reason-code detections, 6 E-class occurrences found.\n"
        new_pr = env.pr_path.read_text() + novel
        env.pr_path.write_text(new_pr)
        env.gh_file.write_text(new_pr)
    return run_test("T08 adr-novel-spelling [SUGGESTION-10]", defect)


def t09_adr_unparseable():
    """BLOCKING-D: unparseable adr output -> check2/check3/check6/check2a never register -> gate fires."""
    def defect(env):
        env.adr_file.write_text("adr-consistency: no violations found\n")
    return run_test("T09 adr-unparseable [BLOCKING-D]", defect)


def t10_ledger_examined_wrong():
    """SUGGESTION-11 per-match validation: wrong examined value in ev -> ledger/examined fail."""
    def defect(env):
        # Corrupt first ledger triple in ev (examined=9 instead of 6)
        text = env.ev_path.read_text().replace(
            "population=8, examined=6, skipped=2",
            "population=8, examined=9, skipped=2",
            1,
        )
        env.ev_path.write_text(text)
    return run_test("T10 ledger-examined-wrong [SUGGESTION-11]", defect)


def t11_ledger_min_count():
    """SUGGESTION-11 MIN_LEDGER_COUNT: ledger triples removed from ev -> count < 3."""
    def defect(env):
        text = re.sub(
            r".*(?:pop(?:ulation)?=8, examined=6, skipped=2).*\n",
            "",
            env.ev_path.read_text(),
        )
        env.ev_path.write_text(text)
    return run_test("T11 ledger-min-count [SUGGESTION-11]", defect)


def t12_prev_label_drift():
    """SUGGESTION-9 drift: extra 'Previous (post-gate34)' line -> count != 2."""
    def defect(env):
        extra = "- Previous (post-gate34): 99 violations (stale baseline row)\n"
        env.ev_path.write_text(env.ev_path.read_text() + extra)
    return run_test("T12 prev-label-drift [SUGGESTION-9]", defect)


def t13_enumerated_site_missing():
    """Check 6 completeness: live site absent from 'Detection confirmed at:' block."""
    def defect(env):
        new_pr = env.pr_path.read_text().replace(", `BC-2.11.004.md:61`", "")
        env.pr_path.write_text(new_pr)
        env.gh_file.write_text(new_pr)
    return run_test("T13 enumerated-site-missing [check6]", defect)


# ── Runner ────────────────────────────────────────────────────────────────────
TESTS = [
    t01_post_merge_context,
    t02_rollback_removed,
    t03_head_sha_ev_absent,
    t04_ecli001_absent,
    t05_ac002_absent,
    t06_prev_label_replaced,
    t07_ei_novel_spelling,
    t08_adr_novel_spelling,
    t09_adr_unparseable,
    t10_ledger_examined_wrong,
    t11_ledger_min_count,
    t12_prev_label_drift,
    t13_enumerated_site_missing,
]


def main():
    print(f"\ntest-vef.py -- verify-evidence-figures.py selftest suite")
    print("=" * 60)
    results = [fn() for fn in TESTS]
    n_pass  = sum(results)
    n_total = len(results)
    print("=" * 60)
    if n_pass == n_total:
        print(f"PASS  {n_pass}/{n_total} tests verified "
              "(each proved clean-pass + defect-fail)")
        sys.exit(0)
    else:
        print(f"FAIL  {n_pass}/{n_total} tests passed  "
              f"({n_total - n_pass} failed)")
        sys.exit(1)


if __name__ == "__main__":
    main()
