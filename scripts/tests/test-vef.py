#!/usr/bin/env python3
"""Mutation-verified selftest suite for scripts/verify-evidence-figures.py.

29 test cases (T01-T29, non-sequential numbering).  Each proves:
  DEFECT PRESENT  -- verifier exits non-zero (failure / refused)
  DEFECT ABSENT   -- verifier exits 0 (clean default fixture passes)

T17 (gh field contract) exercises the REAL gh CLI, not an env stub.
  If gh is unavailable: LOUD SKIP (counted and printed, not a silent pass).
  If gh is available:  defect=bad field name → gh exits non-zero; clean=
  correct field names → gh does not emit "Unknown JSON field" error.

Test isolation: _VEF_TEST_* env vars redirect all file I/O and subprocess
calls to a temp directory.  The real repo is used for git commands (which
the verifier routes through _SCRIPT_REPO regardless of _VEF_TEST_REPO),
but provenance stamp verification is skipped in test mode.

Run:  python3 scripts/tests/test-vef.py
Reports: N/N tests verified (each proved clean-pass + defect-fail)
"""

import os, re, shutil, subprocess, sys, tempfile
from pathlib import Path

REPO       = Path(__file__).resolve().parent.parent.parent
VERIFIER   = REPO / "scripts" / "verify-evidence-figures.py"
# B-4 fix: decouple from GATE35 slug; use a generic test slug.
TEST_SLUG  = "VEF-TEST-FIXTURE"
EV_DIR_REL = f"docs/demo-evidence/{TEST_SLUG}"

# Single source of truth: extract the exact JSON fields the verifier requests.
# Reading from the verifier source makes a divergent copy structurally impossible.
# Uses re.findall to assert exactly one match — refuses ambiguously if multiple
# call sites exist, rather than silently picking the first.
_GH_FIELD_CANDIDATES = re.findall(
    r'"gh",\s*"pr",\s*"view",\s*"--json",\s*"([^"]+)"',
    VERIFIER.read_text(),
)
assert len(_GH_FIELD_CANDIDATES) == 1, (
    f"T17/T18: expected exactly 1 gh --json field site in verifier, "
    f"found {len(_GH_FIELD_CANDIDATES)}: {_GH_FIELD_CANDIDATES!r}"
)
GH_PR_FIELDS = _GH_FIELD_CANDIDATES[0]

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
#   EI cmp_found:  STANDARD(3)+BOLD_REV(2)+TRANSITION(1)+SINGLE_CMP(1)+EV_CMP(4) = 11 >= MIN 9
#   EI div_found:  STANDARD(3)+BOLD_REV(2)+TRANSITION(1)+EV_DIV(4)               = 10 >= MIN 9
#   EI adj_found:  STANDARD(3)+BOLD_REV(2)+TRANSITION(1)+EV_ADJ(3)               =  9 >= MIN 8
#   PREV_LABEL lines in EV: exactly 2
#   Novel-spelling (ADR): all combined 78+reason-code+6+E-class on same line
#                          are covered by RC_EC_PAT -- no novel-spelling fires
#   Novel-spelling (EI):  all 174/42/22 near EI-CTX are within a pattern span;
#     9 divergent and 5 adjudication in baseline table row are declared via
#     EI_NOVEL_DECLARED (B-1 residual fix) -- S-7 stale-detection satisfied
#     because the fragment '110 of 190 TV rows' is present in that row.
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

## Baseline comparison

| Checker | Previous (post-gate34) | After This PR | Notes |
|---------|------------------------|---------------|-------|
| check-ec-injectivity | 9 divergent, 5 adjudication; 110 of 190 TV rows (80 skipped) | **42 DIVERGENT + 22 ADJUDICATION; 174 of 174 TV rows compared** | Unchanged |

## check-ec-injectivity

ec-injectivity now compares 174 of 174 citations (17 EC-less skipped).
174 citations compared (17 legitimately-EC-less skipped), 42 divergent, 22 adjudication.
→174 ec-injectivity comparisons; →42 divergent; →22 adjudication

## E-class Site Validation

(6 E-class code occurrences validated).  Detection confirmed at:
`BC-2.01.009.md:44,52,71,73`, `interface-definitions.md:237`, `BC-2.11.004.md:61`.
E-class code E-CLI-001 confirmed at BC-2.11.004.md:61.

## Rollback

```
git revert {MOCK_HEAD_7} 72db558 b4bbbc3 ca8c1c0 f6dfa58 aaaa111 bbbb222 cccc333 dddd444 eeee555 ffff666 fedcba1
```

Rollback reverts all 12 commits.
"""

# EV_FIXTURE satisfies every verifier check that reads evidence-report.md.
# Exactly 2 "Previous (post-gate34)" lines -- SUGGESTION-9 assertion.
# EI lines (no_prev): four lines giving the correct counts for all patterns.
EV_FIXTURE = f"""\
# Evidence Report -- CHECKER-COMPLETENESS-GATE35

**Captured at SHA:** {MOCK_HEAD_7}

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
        pr_dir = root / f".factory/code-delivery/{TEST_SLUG}"
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
        # B-4 fix: mock branch SHAs for check7 (rollback set) and check9
        # (captured-SHA on-branch).  MOCK_HEAD plus four others; all appear in
        # PR_FIXTURE's rollback list so the clean case passes without mutation.
        self.branch_shas = f"{MOCK_HEAD} aaaa111 bbbb222 cccc333 dddd444"
        # PR-resolution mocks
        self.pr_num          = "13"   # mock PR number (any value works in test mode)
        self.no_open_pr      = False  # simulate no-PR-found → REFUSED (exit 2)
        self.gh_body_overrides: dict = {}  # {pr_num_str: Path} per-PR body routing
        # B2-1 exit-code split mocks
        self.gh_not_found    = False  # simulate 'gh' not in PATH → exit 3
        self.check8_auth_fail = False  # simulate check8 gh auth failure → exit 5

    def run(self):
        """Run the verifier under _VEF_TEST_* overrides; return (rc, combined output)."""
        env = {
            **os.environ,
            "_VEF_TEST_REPO"        : str(self.root),
            "_VEF_TEST_ADR_FILE"    : str(self.adr_file),
            "_VEF_TEST_EI_FILE"     : str(self.ei_file),
            "_VEF_TEST_ST_FILE"     : str(self.st_file),
            "_VEF_TEST_N_AHEAD"     : self.n_ahead,
            "_VEF_TEST_HEAD"        : MOCK_HEAD,
            "_VEF_TEST_GH_BODY"     : str(self.gh_file),
            "_VEF_TEST_PR_NUM"      : self.pr_num,
            "_VEF_TEST_BRANCH_SHAS" : self.branch_shas,
        }
        if self.no_open_pr:
            env["_VEF_TEST_NO_OPEN_PR"] = "1"
        if self.gh_not_found:
            # Remove PR_NUM override so the gh resolution path is reached,
            # then simulate gh not being in PATH (exit 3).
            del env["_VEF_TEST_PR_NUM"]
            env["_VEF_TEST_GH_NOT_FOUND"] = "1"
        if self.check8_auth_fail:
            # Remove the gh body override so check 8 reaches the real gh path,
            # then simulate an auth failure (check8 → loud SKIP → exit 5).
            del env["_VEF_TEST_GH_BODY"]
            env["_VEF_TEST_CHECK8_AUTH_FAIL"] = "1"
        # Per-PR-number body routing: _VEF_TEST_GH_BODY_<N>
        for num, path in self.gh_body_overrides.items():
            env[f"_VEF_TEST_GH_BODY_{num}"] = str(path)
        r = subprocess.run(
            [sys.executable, str(VERIFIER)],
            capture_output=True, text=True, env=env,
            cwd=str(REPO),   # real repo as cwd so git operations have valid history
        )
        return r.returncode, r.stdout + r.stderr

    def cleanup(self):
        shutil.rmtree(self._tmpdir, ignore_errors=True)


def _gh_is_authenticated() -> bool:
    """Return True iff gh is available and has a valid auth token.

    T17/T18 rely on gh validating JSON field names, which only happens after
    successful auth.  In CI without GH_TOKEN, gh returns an auth error for all
    calls — including ones with invalid field names — so T17/T18 cannot
    distinguish a bad field from an auth failure.  When unauthenticated,
    both tests loud-skip (same as if gh were absent from PATH).
    """
    r = subprocess.run(
        ["gh", "auth", "status"],
        capture_output=True, text=True, cwd=str(REPO), timeout=15,
    )
    return r.returncode == 0


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
    """B-4/check9: **Captured at SHA:** absent from ev -> anchor_check fail."""
    def defect(env):
        text = re.sub(r"\*\*Captured at SHA:\*\*.*\n", "", env.ev_path.read_text())
        env.ev_path.write_text(text)
    return run_test("T03 captured-sha-ev-absent [check9]", defect)


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


def t22_adr_novel_wrong_rc():
    """B-1 Case B: wrong rc figure in ADR novel prose -> adr-consistency/novel-spelling fail.

    Before B-1 fix: old code gated on `live_rc in _line`; '77' (not '78') was
    never examined -> silent PASS (defect).
    After fix: context-word key catches the combined reason-code+E-class line
    regardless of which rc integer appears on it.
    """
    def defect(env):
        # live rc=78; injecting 77 (wrong) with novel spelling that has no '+' connector
        novel = "Post-fix: 77 reason-code detections, 6 E-class occurrences found.\n"
        new_pr = env.pr_path.read_text() + novel
        env.pr_path.write_text(new_pr)
        env.gh_file.write_text(new_pr)
    return run_test("T22 adr-novel-wrong-rc [B-1 Case-B]", defect)


def t23_adr_novel_wrong_rc_ec():
    """B-1 Case C: wrong rc+ec figures in ADR novel prose -> adr-consistency/novel-spelling fail.

    Both rc and ec are wrong (55 and 9 instead of 78 and 6); neither appears
    in the line, so the old `live_rc in _line` gate skipped it entirely.
    """
    def defect(env):
        # live rc=78 ec=6; injecting 55 and 9 (both wrong), novel spelling
        novel = "Post-fix: 55 reason-code detections and 9 E-class occurrences found.\n"
        new_pr = env.pr_path.read_text() + novel
        env.pr_path.write_text(new_pr)
        env.gh_file.write_text(new_pr)
    return run_test("T23 adr-novel-wrong-rc-ec [B-1 Case-C]", defect)


def t24_ei_novel_wrong_div():
    """B-1 Case D: wrong divergent figure in EI novel prose -> ec-injectivity/novel-spelling/div fail.

    Before B-1 fix: old EI scan searched for re.escape('42') (live ldiv);
    '99 divergent' contains no '42' -> silent PASS (defect).
    After fix: per-metric context scan finds 'N divergent', extracts 99,
    compares to ldiv=42 -> detected.
    """
    def defect(env):
        # live ldiv=42; injecting 99 (wrong) in novel EI prose
        novel = "Summary: injectivity run gave 99 divergent citations after adjudication.\n"
        new_pr = env.pr_path.read_text() + novel
        env.pr_path.write_text(new_pr)
        env.gh_file.write_text(new_pr)
    return run_test("T24 ei-novel-wrong-div [B-1 Case-D]", defect)


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


def t14_no_open_pr():
    """T14 (c): no open PR for branch -> REFUSED (exit 2).

    Defect: _VEF_TEST_NO_OPEN_PR=1 simulates gh returning no PR for branch.
    Clean:  default pr_num='13' — verifier proceeds normally.
    """
    def defect(env):
        env.no_open_pr = True
    return run_test("T14 no-open-pr [exit-2]", defect, expect_rc=2)


def t15_artifact_head_mismatch():
    """T15 (b): pr-description.md HEAD SHA != current HEAD -> REFUSED (exit 2).

    Artifact auto-discovery scans for '**Head SHA:** {HEAD}' in pr-description.md.
    When the file was written for a different commit, the scan finds 0 candidates
    and the verifier exits 2 (REFUSED) before running any figure checks.

    Defect: pr-description.md contains wrong HEAD SHA -> 0 scan candidates.
    Clean:  default fixture has **Head SHA:** {MOCK_HEAD} -> 1 candidate found.
    """
    WRONG_HEAD = "a" * 40  # all-'a' SHA -- guaranteed != MOCK_HEAD
    def defect(env):
        text = env.pr_path.read_text().replace(
            f"**Head SHA:** {MOCK_HEAD}",
            f"**Head SHA:** {WRONG_HEAD}",
        )
        env.pr_path.write_text(text)
    return run_test("T15 artifact-head-mismatch [exit-2]", defect, expect_rc=2)


def t16_correct_pr_number_routing():
    """T16 (a): gh body fetched for the resolved PR number, not a hardcoded default.

    Per-PR routing: _VEF_TEST_GH_BODY_<N> takes precedence over _VEF_TEST_GH_BODY.
    PR 77 is used (not 12).  The fallback (_VEF_TEST_GH_BODY) is set to diverged
    content in the clean case -- old code relying on the fallback would fail check 8;
    new code reads _VEF_TEST_GH_BODY_77 (correct) and passes.

    Defect: _VEF_TEST_GH_BODY_77 = diverged body -> check8/live-pr-body/sync fails.
    Clean:  _VEF_TEST_GH_BODY_77 = correct body, fallback = diverged -> passes
            (proves verifier uses the per-PR override, not the fallback).
    """
    _DIVERGED = "# diverged body — must not match pr-description.md\n"

    def defect(env):
        env.pr_num = "77"
        div_file = env.root / "mock-gh-77-div.txt"
        div_file.write_text(_DIVERGED)
        env.gh_body_overrides["77"] = div_file

    def clean(env):
        env.pr_num = "77"
        ok_file = env.root / "mock-gh-77-ok.txt"
        ok_file.write_text(env.pr_path.read_text())  # correct body = pr_path
        env.gh_body_overrides["77"] = ok_file
        # Set fallback to diverged: proves verifier uses gh_77, not the fallback.
        # Old code that ignored _VEF_TEST_PR_NUM and used fallback would fail here.
        env.gh_file.write_text(_DIVERGED)

    return run_test("T16 correct-pr-number-routing [check8]", defect, clean)


def t17_gh_field_contract():
    """T17: REAL gh CLI invocation uses valid field names (not an env stub).

    This test exercises the actual gh binary, bypassing all _VEF_TEST_* mocks.
    It proves that the exact JSON fields requested by the verifier are accepted
    by gh -- catching typos like 'headSha' (invalid) vs 'headRefOid' (valid).

    If gh is unavailable in the environment: LOUD SKIP -- counted in output.

    Defect present: gh pr view --json number,headShaBROKEN exits non-zero and
                    stderr contains "Unknown JSON field" (invalid field name).
    Defect absent:  gh pr view --json {GH_PR_FIELDS} does NOT produce
                    "Unknown JSON field" in stderr (field names are valid).
                    Note: gh may still exit 1 if no PR exists for the current
                    branch -- that is OK; we are testing field validity only.
    """
    import shutil as _shutil
    if not _shutil.which("gh"):
        print("  SKIP  T17 gh-field-contract [gh unavailable]"
              "  **** LOUD SKIP — not a pass ****")
        return None  # distinct from True (pass) and False (fail)
    if not _gh_is_authenticated():
        # gh validates auth BEFORE field names when unauthenticated — so an
        # invalid field and a valid field both return the same auth error.
        # The field-contract signal ("Unknown JSON field") is unreachable
        # without auth.  Loud-skip rather than false-fail.
        print("  SKIP  T17 gh-field-contract [gh unauthenticated — "
              "field validation requires auth]  **** LOUD SKIP — not a pass ****")
        return None

    # Defect present: request a field that does not exist in gh's schema.
    r_bad = subprocess.run(
        ["gh", "pr", "view", "--json", "number,headShaBROKEN"],
        capture_output=True, text=True,
        cwd=str(REPO), timeout=30,
    )
    defect_ok = (r_bad.returncode != 0
                 and "Unknown JSON field" in r_bad.stderr)
    if not defect_ok:
        print(f"    FAIL T17 [defect-present]: expected non-zero + 'Unknown JSON field'")
        print(f"      rc={r_bad.returncode}  stderr={r_bad.stderr[:200]!r}")

    # Defect absent: the fields the verifier actually requests are accepted by gh.
    # "Unknown JSON field" in stderr is the discriminating signal for a bad field.
    # gh may still exit 1 for branch-has-no-pr -- that is a distinct condition.
    r_ok = subprocess.run(
        ["gh", "pr", "view", "--json", GH_PR_FIELDS],
        capture_output=True, text=True,
        cwd=str(REPO), timeout=30,
    )
    clean_ok = "Unknown JSON field" not in r_ok.stderr
    if not clean_ok:
        print(f"    FAIL T17 [clean]: 'Unknown JSON field' in stderr for {GH_PR_FIELDS!r}")
        print(f"      rc={r_ok.returncode}  stderr={r_ok.stderr[:200]!r}")

    passed = defect_ok and clean_ok
    print(f"  {'PASS' if passed else 'FAIL'}  T17 gh-field-contract [real-gh-path]")
    return passed


def t18_gh_real_path_field_contract():
    """T18: verifier's REAL gh resolution path uses the correct field name.

    Runs the verifier with _VEF_TEST_N_AHEAD set (to ensure the n_ahead guard
    does not fire before reaching gh) but WITHOUT _VEF_TEST_PR_NUM or
    _VEF_TEST_NO_OPEN_PR, so PR resolution goes through the actual gh binary
    at verify-evidence-figures.py:247.

    Defect case: a temporary copy of the verifier with 'headSha' (invalid field)
      produces 'possible bad JSON field name in verifier' (exit 2 via line ~261).
    Clean case: the real verifier with 'headRefOid' does NOT produce that message.

    Both mutations are distinguishable regardless of whether a PR exists for the
    current branch: gh validates field names before the API call, so an invalid
    field always yields 'Unknown JSON field' even with no open PR.

    If gh is unavailable or unauthenticated: LOUD SKIP (counted, not a pass).
    T18 is vacuous when gh is absent or unauthenticated — without auth, gh
    returns an auth error for all calls (including ones with bad field names),
    so the verifier exits 3 (env failure) instead of 4 (verifier bug) on the
    mutated field name, making T18's defect signal unreachable.
    """
    import shutil as _shutil
    if not _shutil.which("gh"):
        print("  SKIP  T18 gh-real-path-field-contract [gh unavailable]"
              "  **** LOUD SKIP — not a pass ****")
        return None  # distinct from True (pass) and False (fail)
    if not _gh_is_authenticated():
        print("  SKIP  T18 gh-real-path-field-contract [gh unauthenticated — "
              "field validation requires auth]  **** LOUD SKIP — not a pass ****")
        return None

    # Base env: all non-_VEF_TEST_ vars, plus _VEF_TEST_N_AHEAD so the pre-flight
    # guard does not fire before we reach the gh call.
    # _VEF_TEST_PR_NUM and _VEF_TEST_NO_OPEN_PR are deliberately excluded.
    base_env = {
        k: v for k, v in os.environ.items()
        if not k.startswith("_VEF_TEST_")
    }
    base_env["_VEF_TEST_N_AHEAD"] = "12"

    # ── Defect present: temp copy of verifier with headSha ────────────────────
    # Soft FAIL (not hard assert) when injection cannot land: the verifier may
    # already be broken (headSha in place), in which case the clean case below
    # independently catches the regression too.
    original_src = VERIFIER.read_text()
    defect_src = original_src.replace('"number,headRefOid"', '"number,headSha"', 1)

    defect_ok = False
    if defect_src == original_src:
        print("    FAIL T18 [defect-inject]: could not inject headSha defect — "
              "'\"number,headRefOid\"' not found in verifier source "
              "(verifier may already use an incorrect field name)")
    else:
        fd, defect_path = tempfile.mkstemp(suffix='.py', dir='/tmp')
        defect_verifier = Path(defect_path)
        try:
            defect_verifier.write_text(defect_src)
            os.close(fd)
            r_bad = subprocess.run(
                [sys.executable, str(defect_verifier)],
                capture_output=True, text=True, env=base_env,
                cwd=str(REPO), timeout=30,
            )
            combined_bad = r_bad.stdout + r_bad.stderr
            # B2-1 exit-code split: verifier self-diagnosed bug → exit 4 (was 2).
            defect_ok = (
                r_bad.returncode == 4
                and "possible bad JSON field name in verifier" in combined_bad
            )
            if not defect_ok:
                print(f"    FAIL T18 [defect-present]: expected rc=4 + bad-field msg, "
                      f"got rc={r_bad.returncode}")
                print(f"      output: {combined_bad[:400]!r}")
        finally:
            defect_verifier.unlink(missing_ok=True)

    # ── Defect absent: real verifier with headRefOid ───────────────────────────
    # May exit non-zero for unrelated reasons (no matching artifacts, coherence
    # check fails, etc.) — we only assert the specific message is absent.
    r_ok = subprocess.run(
        [sys.executable, str(VERIFIER)],
        capture_output=True, text=True, env=base_env,
        cwd=str(REPO), timeout=30,
    )
    combined_ok = r_ok.stdout + r_ok.stderr
    clean_ok = "possible bad JSON field name in verifier" not in combined_ok
    if not clean_ok:
        print(f"    FAIL T18 [clean]: bad-field-name msg appeared unexpectedly")
        print(f"      rc={r_ok.returncode}  output: {combined_ok[:400]!r}")

    passed = defect_ok and clean_ok
    print(f"  {'PASS' if passed else 'FAIL'}  T18 gh-real-path-field-contract "
          f"[real-gh-path]")
    return passed


def t19_rollback_missing_branch_commit():
    """T19 (B-4): branch commit absent from rollback list -> rollback/missing-commits.

    Tests the git-derived SHA set check that replaces the hardcoded '39efec2'.

    Defect: one mock branch SHA (cccc333) is removed from the rollback list; the
            verifier should detect it as missing.
    Clean:  default fixture retains all mock branch SHAs (MOCK_HEAD, aaaa111,
            bbbb222, cccc333, dddd444) — none missing → PASS.

    Per lesson 61: the defect case proves the check would catch a genuinely missing
    commit, not just verify that a self-consistent fixture passes vacuously.
    """
    def defect(env):
        # Remove cccc333 from rollback list; branch_shas still requires it.
        new_pr = env.pr_path.read_text().replace(" cccc333", "")
        env.pr_path.write_text(new_pr)
        env.gh_file.write_text(new_pr)
    return run_test("T19 rollback-missing-branch-commit [check7/B-4]", defect)


def t20_rollback_count_claim_missing():
    """T20 (B-4 / lesson-60): count-claim anchor absent -> rollback/count-claim-missing.

    Previously the bare 'if count_m:' meant a missing count-claim silently passed.
    The 'else: fail()' addition makes absence a detected failure.

    Defect: 'Rollback reverts all N commits' line removed from pr-description.md.
    Clean:  default fixture has the count-claim present → PASS.
    """
    def defect(env):
        new_pr = re.sub(r"Rollback reverts all \d+ commits.*\n", "",
                        env.pr_path.read_text())
        env.pr_path.write_text(new_pr)
        env.gh_file.write_text(new_pr)
    return run_test("T20 rollback-count-claim-missing [check7/else-fail]", defect)


def t21_captured_sha_not_on_branch():
    """T21 (B-4 / check9 redesign): captured SHA not in branch commits -> fails.

    The redesigned check9 verifies that the SHA in '**Captured at SHA:**' is a
    commit on this branch (git rev-list develop..HEAD).  This distinguishes a
    legitimate on-branch capture from a SHA borrowed from a different PR or branch.

    Defect: '**Captured at SHA:**' contains 'deadaa1' — a 7-char SHA NOT in
            _VEF_TEST_BRANCH_SHAS (which provides MOCK_HEAD, aaaa111, ...).
    Clean:  default fixture uses MOCK_HEAD_7 = 'deadbee' which IS in branch_shas.
    """
    def defect(env):
        # Replace the captured SHA with one that is NOT in branch_shas.
        text = env.ev_path.read_text().replace(
            f"**Captured at SHA:** {MOCK_HEAD_7}",
            "**Captured at SHA:** deadaa1",
        )
        env.ev_path.write_text(text)
    return run_test("T21 captured-sha-not-on-branch [check9/B-4]", defect)


def t25_ac002_no_nofm_token():
    """T25 (B-3 ATTACK-A): AC-002 file present but filename has no NofM token -> caught.

    ATTACK-A scenario from B-3 review: if the artifact filename carries no NofM
    token (e.g. AC-002-selftest.txt), the OLD code silently passed (sfx_m is None,
    check body skips comparison, but anchor_check() already registered the key).

    B-3 fix: absent NofM is a fail("evidence-report/ac002-suffix-unparseable"),
    AND record_comparison() is never called, so the REQUIRED_CHECKS gate also fires.

    Defect: rename AC-002-selftest-99of99.txt -> AC-002-selftest.txt (no NofM).
    Clean:  default fixture keeps 99of99 in the name -> comparison runs, passes.
    """
    def defect(env):
        old = env.ev_dir / "AC-002-selftest-99of99.txt"
        new = env.ev_dir / "AC-002-selftest.txt"
        old.rename(new)
    return run_test("T25 ac002-no-nofm-token [B-3/ATTACK-A]", defect)


def t26_ac002_nofm_mismatch():
    """T26 (B-3 CONTROL): AC-002 has NofM in filename; ev cites different NofM -> caught.

    CONTROL scenario from B-3 review: AC-002-selftest-99of99.txt exists (NofM present),
    but evidence-report.md references a DIFFERENT NofM value (77of77).  This should
    be caught as evidence-report/ac002-suffix.

    Defect: ev explicitly references 77of77 where the filename has 99of99.
    Clean:  default fixture: filename=99of99, ev references 99of99 -> PASS.
    """
    def defect(env):
        # Inject a wrong NofM reference into ev (77of77 != 99of99 in filename).
        ev_text = env.ev_path.read_text()
        ev_text += "\nSee AC-002-selftest-77of77.txt for confirmation.\n"
        env.ev_path.write_text(ev_text)
    return run_test("T26 ac002-nofm-mismatch [B-3/CONTROL]", defect)


def t27_gh_not_found_exit_3():
    """T27 (B2-1): 'gh' not in PATH during PR resolution → exit 3 (env failure).

    Before B2-1 fix: gh not found → exit 2 (benign, "not a failure") —
    indistinguishable from a post-merge context.  CI wrapper mapped exit 2 to
    success, so a missing gh was silently reported as a non-failure.

    After fix: gh not found → exit 3 (environment failure).  CI wrapper maps
    exit 3 to a genuine failure, so the broken environment is visible.

    Defect: _VEF_TEST_GH_NOT_FOUND=1 (simulates FileNotFoundError for gh).
            _VEF_TEST_PR_NUM removed so the gh resolution path is exercised.
    Clean:  default TestEnv with _VEF_TEST_PR_NUM set (bypasses gh entirely).
    """
    def defect(env):
        env.gh_not_found = True
    return run_test("T27 gh-not-found-env-fail [B2-1/exit-3]", defect, expect_rc=3)


def t28_check8_auth_skip():
    """T28 (B2-1): check8 gh auth failure → loud SKIP → exit 5 (PARTIAL).

    Before B2-1 fix: when running with --pr N (bypassing PR resolution) check 8
    would still call gh and fail; the failure either cascaded to exit 1 (FAIL) or
    collapsed into the REQUIRED_CHECKS gate.  Neither distinguished "check ran and
    found a mismatch" from "check could not run due to env constraints".

    After fix: auth failure for check 8 → loud SKIP recorded to checks_skipped.
    The REQUIRED_CHECKS gate excludes checks_skipped so no double-failure.
    At the final report: exits 5 (PARTIAL) because checks_skipped is non-empty
    and fails is empty.

    Defect: _VEF_TEST_CHECK8_AUTH_FAIL=1 (simulates gh auth failure for body
            fetch) and _VEF_TEST_GH_BODY removed (so check 8 reaches the gh
            path).  All other checks pass → exit 5.
    Clean:  default TestEnv has _VEF_TEST_GH_BODY set to correct content →
            check 8 runs and passes → exit 0.
    """
    def defect(env):
        env.check8_auth_fail = True
    return run_test("T28 check8-auth-skip-exit5 [B2-1/exit-5]", defect, expect_rc=5)


def t29_ecli001_absent_from_pr():
    """T29 (B2-2 ATTACK-A): E-CLI-001 in live output but absent from PR -> check2a fails.

    Before B2-2 fix: ATTACK-A relocated from check4a-ac002-suffix (cycle 1) to
    check2a-e-cli-001.  anchor_check() returned True (E-CLI-001 in adr_out), the
    inner re.search(r"E-CLI-001.*?test-vectors", pr) returned None (no such phrase),
    so the comparison body was skipped, but record_comparison() was called
    unconditionally after the if-block.  check2a registered with zero comparison.
    The run exits 0 — ATTACK-A succeeds silently.

    After fix: check2a first looks for E-CLI-001 in the PR document.  If absent,
    fail("traceability/e-cli-001-in-pr") is called and record_comparison is NOT
    called; the REQUIRED_CHECKS gate fires as a second signal.  Structurally:
    record_comparison(doc_value=_pr_ecli_m) requires a non-None doc_value, so a
    check that found nothing in the PR cannot reach a registered state.

    Defect: E-CLI-001 removed from pr-description.md (still in adr live output).
            Before fix: exits 0 (PASS — attack succeeds silently).
            After fix:  exits 1 (FAIL — traceability/e-cli-001-in-pr + gate).
    Control: default fixture retains E-CLI-001 in PR -> check2a compares and passes.
    """
    def defect(env):
        # Remove E-CLI-001 from PR fixture; keep it in adr output (anchor present).
        # This simulates the production-path attack: MOCK_ADR_OUT has E-CLI-001
        # at BC-2.11.004.md:61, but pr-description.md does not acknowledge it.
        text = env.pr_path.read_text().replace("E-CLI-001", "E-CLI-XXX")
        env.pr_path.write_text(text)
        env.gh_file.write_text(text)
    return run_test("T29 e-cli-001-absent-from-pr [B2-2/ATTACK-A]", defect)


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
    t22_adr_novel_wrong_rc,
    t23_adr_novel_wrong_rc_ec,
    t24_ei_novel_wrong_div,
    t09_adr_unparseable,
    t10_ledger_examined_wrong,
    t11_ledger_min_count,
    t12_prev_label_drift,
    t13_enumerated_site_missing,
    t14_no_open_pr,
    t15_artifact_head_mismatch,
    t16_correct_pr_number_routing,
    t17_gh_field_contract,
    t18_gh_real_path_field_contract,
    t19_rollback_missing_branch_commit,
    t20_rollback_count_claim_missing,
    t21_captured_sha_not_on_branch,
    t25_ac002_no_nofm_token,     # B-3 ATTACK-A
    t26_ac002_nofm_mismatch,     # B-3 CONTROL
    t27_gh_not_found_exit_3,     # B2-1 exit-3 (env failure)
    t28_check8_auth_skip,        # B2-1 exit-5 (PARTIAL, check8 loud-skip)
    t29_ecli001_absent_from_pr,  # B2-2 ATTACK-A (register-without-comparing class)
]


def main():
    print(f"\ntest-vef.py -- verify-evidence-figures.py selftest suite")
    print("=" * 60)
    results = [fn() for fn in TESTS]
    n_pass = sum(1 for r in results if r is True)
    n_skip = sum(1 for r in results if r is None)
    n_fail = sum(1 for r in results if r is False)
    n_total = len(results)
    print("=" * 60)
    if n_fail == 0 and n_skip == 0:
        print(f"PASS  {n_pass}/{n_total} tests verified "
              f"(each proved clean-pass + defect-fail)")
        sys.exit(0)
    elif n_fail == 0:
        # N2-2 fix: loud-skips are NOT verified — exiting 0 would misrepresent
        # the suite as fully confirmed.  Exit 5 (PARTIAL) is the honest result.
        print(f"PASS  {n_pass}/{n_total} tests verified  ({n_skip} loud-skip)")
        print("NOTE: loud-skipped tests are not verified — "
              "run with gh available for a complete suite.  Exit 5 (PARTIAL).")
        sys.exit(5)
    else:
        print(f"FAIL  {n_pass}/{n_total} tests passed  "
              f"({n_fail} failed, {n_skip} loud-skipped)")
        sys.exit(1)


if __name__ == "__main__":
    main()
