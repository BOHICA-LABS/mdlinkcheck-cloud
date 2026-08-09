#!/usr/bin/env python3
"""Verify evidence-figure consistency for any open-PR delivery artifact set.

Derives expected values from live tool runs and git state — never from the
documents being checked. Exit non-zero with per-mismatch report on failure.

Usage:
  python3 scripts/verify-evidence-figures.py
  python3 scripts/verify-evidence-figures.py --pr N
  python3 scripts/verify-evidence-figures.py --pr-desc PATH
  python3 scripts/verify-evidence-figures.py --pr N --pr-desc PATH \\
          --evidence-dir PATH

By default the PR number is derived from the current branch via:
  gh pr view --json number,headRefOid
and artifact paths are discovered by scanning
  .factory/code-delivery/*/pr-description.md
for the file containing '**Head SHA:** <current-HEAD>'.

Context requirement (Item 0):
  Must be run on a feature branch with commits ahead of 'develop'.
  When HEAD has no commits ahead of develop (e.g. on develop itself, or
  immediately after a merge), the branch-dependent checks — head-SHA,
  rollback count, live-PR-body — are undefined and would produce misleading
  failures rather than meaningful verification.
  In that context the script exits with code 2 (REFUSED) with a clear
  diagnostic.  This is fail-closed by design: an ambiguous context cannot
  produce a meaningful PASS.

Exit codes:
  0  — PASS: all figure checks match live output and git state.
  1  — FAIL: one or more figure mismatches detected.
  2  — REFUSED: context not applicable (post-merge, no open PR, or
       incoherent state — resolved PR head ≠ local HEAD, or no matching
       pr-description.md found for current HEAD).

Structural guarantee (BLOCKING-D):
  Every check that performs a live-vs-document comparison MUST call
  anchor_check() or checks_ran.add(key) after performing the comparison.
  The PASS gate asserts REQUIRED_CHECKS == checks_ran, so a check added
  without anchor_check() AND without checks_ran.add() cannot produce a
  false PASS.

  The anchor_check() helper enforces this structurally: calling it IS the
  registration.  No separate checks_ran.add() needed — making omission
  mechanically detectable by the REQUIRED_CHECKS gate.

  Note: checks_ran.add() placed unconditionally (at module scope, not inside
  a comparison body) still tricks the registry.  anchor_check() catches this
  by only registering when the anchor is present, so the comparison IS
  guaranteed to have run.

Test-mode overrides (_VEF_TEST_* environment variables):
  EXCLUSIVELY for scripts/tests/test-vef.py.  Never set in CI or production.
  When active, a WARNING is printed and the run is identified as non-production.
  _VEF_TEST_REPO        — override repo root for file reads (temp dir for fixtures)
  _VEF_TEST_ADR_FILE    — path to file containing mock adr-consistency output
  _VEF_TEST_EI_FILE     — path to file containing mock ec-injectivity output
  _VEF_TEST_ST_FILE     — path to file containing mock selftest output
  _VEF_TEST_N_AHEAD     — integer string, override git rev-list --count result
  _VEF_TEST_HEAD        — mock git HEAD sha (40 hex chars)
  _VEF_TEST_PR_NUM      — integer string; mock PR number (bypasses gh pr view)
  _VEF_TEST_NO_OPEN_PR  — any non-empty string; simulate no-PR-found → REFUSED
  _VEF_TEST_GH_BODY_N   — path to mock gh body for PR number N (per-PR routing)
  _VEF_TEST_GH_BODY     — path to file containing mock gh pr body text (fallback)
  _VEF_TEST_BRANCH_SHAS — space-separated list of mock branch SHAs for check7
                          (rollback set comparison) and check9 (captured-SHA
                          on-branch verification).  In production these are
                          derived from git rev-list develop..HEAD.

  Git commands (git show for provenance stamps) always run against the real
  git repo (_SCRIPT_REPO), not the test tmpdir, so stamp verification remains
  live even in test mode.
"""
import argparse, json as _json, os, re, subprocess, sys
from pathlib import Path

# Real script location — used for git operations so they always run in a valid
# git worktree, even when _VEF_TEST_REPO points to a temp directory.
_SCRIPT_REPO = Path(__file__).resolve().parent.parent

# ── Test-mode overrides ────────────────────────────────────────────────────────
_TEST_REPO        = os.environ.get("_VEF_TEST_REPO")
_TEST_ADR_FILE    = os.environ.get("_VEF_TEST_ADR_FILE")
_TEST_EI_FILE     = os.environ.get("_VEF_TEST_EI_FILE")
_TEST_ST_FILE     = os.environ.get("_VEF_TEST_ST_FILE")
_TEST_N_AHEAD     = os.environ.get("_VEF_TEST_N_AHEAD")
_TEST_HEAD        = os.environ.get("_VEF_TEST_HEAD")
_TEST_GH_BODY     = os.environ.get("_VEF_TEST_GH_BODY")
_TEST_PR_NUM      = os.environ.get("_VEF_TEST_PR_NUM")
_TEST_NO_OPEN_PR  = os.environ.get("_VEF_TEST_NO_OPEN_PR")
_TEST_BRANCH_SHAS = os.environ.get("_VEF_TEST_BRANCH_SHAS")
_TEST_MODE        = any([_TEST_REPO, _TEST_ADR_FILE, _TEST_EI_FILE, _TEST_ST_FILE,
                         _TEST_N_AHEAD, _TEST_HEAD, _TEST_GH_BODY,
                         _TEST_PR_NUM, _TEST_NO_OPEN_PR, _TEST_BRANCH_SHAS])

if _TEST_MODE:
    print("WARNING: _VEF_TEST_* env vars active — non-production test run", flush=True)

# REPO: used for file reads (PR_DESC, EV_RPT, AC files).
# In test mode this is the temp fixture directory.
# PR_DESC / EV_RPT / EV_DIR / STAMPED are resolved later (after PR/artifact discovery).
REPO = Path(_TEST_REPO) if _TEST_REPO else _SCRIPT_REPO

# ── CLI arguments ──────────────────────────────────────────────────────────────
_ap = argparse.ArgumentParser(
    description="Verify evidence figures for an open-PR delivery artifact set.",
)
_ap.add_argument(
    "--pr", type=int, default=None, metavar="N",
    help="PR number override (default: derive from current branch via gh)",
)
_ap.add_argument(
    "--pr-desc", type=Path, default=None, dest="pr_desc", metavar="PATH",
    help="Path to pr-description.md (default: auto-discover by HEAD SHA)",
)
_ap.add_argument(
    "--evidence-dir", type=Path, default=None, dest="evidence_dir", metavar="PATH",
    help="Path to evidence directory (default: derived from --pr-desc slug)",
)
args = _ap.parse_args()

# ── Required-checks registry (BLOCKING-D structural guarantee) ────────────────
# Every check listed here MUST register itself via anchor_check() (or
# checks_ran.add(key) for legacy checks that predate anchor_check()).
# The PASS gate at the bottom asserts this set is fully populated.
#
# anchor_check() is the canonical registration mechanism — see its docstring.
# Legacy checks (check2, check3, check4, check6, check8) call checks_ran.add()
# directly inside their else-fail branches; both patterns are equivalent.
REQUIRED_CHECKS = {
    "check2-adr-figures",
    "check3-ledger-triple",
    "check4-ei-figures",
    "check6-completeness",
    "check7-rollback",          # SUGGESTION-8: was unregistered
    "check8-live-pr-body",
    "check9-head-sha-ev",       # SUGGESTION-8: was unregistered
    "check2a-e-cli-001",        # SUGGESTION-8: was unregistered
    "check4a-ac002-suffix",     # SUGGESTION-8: was unregistered
}
checks_ran: set = set()

fails: list = []


def fail(label: str, expected: str, got: str) -> None:
    fails.append(f"  [{label}]\n    expected : {expected}\n    got      : {got}")


def anchor_check(key: str, m, fail_label: str, fail_expected: str) -> bool:
    """Assert anchor was found; register check key if so.

    Called immediately after re.search / re.findall / next(glob(), None).
    If anchor is falsy:  records a failure and returns False.
                         key is NOT added to checks_ran — REQUIRED_CHECKS
                         gate independently catches the omission.
    If anchor is truthy: adds key to checks_ran and returns True.

    This is the CANONICAL way to add a check key to REQUIRED_CHECKS.
    Calling anchor_check() IS the registration — no separate
    checks_ran.add(key) needed.  Adding a key to REQUIRED_CHECKS without
    pairing it with anchor_check() will be caught by the gate: mechanically
    impossible to have a false PASS from a forgotten registration.
    """
    if not m:
        fail(fail_label, fail_expected, "anchor not found — check cannot run")
        return False
    checks_ran.add(key)
    return True


# Allowed return codes per command (keyed on cmd[-1]).
# Default {0, 1}: checkers exit 0 (clean) or 1 (violations found).
# Anything else signals a crash — surface it as a failure.
ALLOWED_RC: dict = {}


def sh(*cmd, timeout=180, allowed_rc=None):
    # Git commands must run in a valid git worktree.  In test mode REPO may
    # be a temp dir without git history, so use _SCRIPT_REPO for git.
    _cwd = _SCRIPT_REPO if cmd[0] == "git" else REPO
    r = subprocess.run(cmd, capture_output=True, text=True, cwd=_cwd, timeout=timeout)
    allowed = allowed_rc if allowed_rc is not None else ALLOWED_RC.get(cmd[-1], {0, 1})
    if r.returncode not in allowed:
        fail(f"live-run/{cmd[-1]!r}",
             f"exit code in {allowed}",
             f"exit {r.returncode}")
    # Return merged stdout+stderr: the RC check above catches crashes; the
    # merged output gives maximum context for diagnostics.
    return (r.stdout + r.stderr).strip()


# ── Item 0: Context detection — refuse post-merge / no-branch-commits runs ────
# Must run BEFORE any document reads or live subprocess calls so that a
# meaningless context produces REFUSED (exit 2), not confusing figure
# mismatches that could be dismissed as noise.
# NIT-F fix: use git rev-list --count (single-integer stdout) instead of
# git log --format=%h piped through len(splitlines()), which counted any
# stderr lines in the commit count.
if _TEST_N_AHEAD is not None:
    _n_ahead_raw = _TEST_N_AHEAD.strip()
else:
    _n_ahead_raw = sh("git", "rev-list", "--count", "develop..HEAD", allowed_rc={0})

try:
    n_ahead = int(_n_ahead_raw)
except ValueError:
    print(f"\nFATAL — could not parse branch commit count: {_n_ahead_raw!r}", flush=True)
    sys.exit(1)

if n_ahead == 0:
    _branch = ("(test-mode)" if _TEST_HEAD else
               sh("git", "rev-parse", "--abbrev-ref", "HEAD", allowed_rc={0}))
    print("\nREFUSED — cannot run in this context.", flush=True)
    print(f"  Current branch : {_branch!r}", flush=True)
    print(f"  Commits ahead of develop : {n_ahead}", flush=True)
    print(flush=True)
    print("This verifier requires a feature branch with commits ahead of 'develop'.", flush=True)
    print("When HEAD is on develop (or all branch commits have been merged), the", flush=True)
    print("branch-dependent checks (head-SHA, rollback count, live-PR-body) are", flush=True)
    print("undefined and would produce misleading failures rather than meaningful", flush=True)
    print("verification.", flush=True)
    print(flush=True)
    print("Re-run from an open feature branch: git checkout <your-branch>", flush=True)
    sys.exit(2)

n_branch_commits = n_ahead   # n_ahead is the branch commit count

# ── HEAD SHA ───────────────────────────────────────────────────────────────────
# Resolved before PR resolution and artifact discovery so both can use it.
if _TEST_HEAD:
    head = _TEST_HEAD.strip()
else:
    head = sh("git", "rev-parse", "HEAD", allowed_rc={0})

# ── PR resolution ──────────────────────────────────────────────────────────────
# Derive the target PR number from the current branch.
# Priority: (1) --pr CLI arg, (2) _VEF_TEST_PR_NUM, (3) gh pr view auto-detect.
# No-open-PR and head-SHA coherence failures are REFUSED (exit 2), not FAIL.
if args.pr is not None:
    pr_number = args.pr
elif _TEST_NO_OPEN_PR:
    print("\nREFUSED — no open pull request found for current branch "
          "(simulated by _VEF_TEST_NO_OPEN_PR).", flush=True)
    sys.exit(2)
elif _TEST_PR_NUM is not None:
    pr_number = int(_TEST_PR_NUM.strip())
else:
    # Auto-resolve PR from current branch via gh.
    try:
        _gh_r = subprocess.run(
            ["gh", "pr", "view", "--json", "number,headRefOid"],
            capture_output=True, text=True,
            cwd=str(_SCRIPT_REPO), timeout=30,
        )
    except FileNotFoundError:
        print("\nREFUSED — 'gh' CLI not found in PATH.", flush=True)
        print("  Install from https://cli.github.com/ or pass --pr N explicitly.",
              flush=True)
        sys.exit(2)
    if _gh_r.returncode != 0:
        # Distinguish a malformed gh query from a genuine no-PR condition.
        # "Unknown JSON field" means the requested field does not exist in gh's
        # schema — that is a verifier bug, not a user condition.
        if "Unknown JSON field" in _gh_r.stderr or "unknown field" in _gh_r.stderr.lower():
            print(f"\nREFUSED — gh query returned an unexpected error "
                  f"(possible bad JSON field name in verifier).", flush=True)
            print(f"  (gh said: {_gh_r.stderr.strip()[:200]})", flush=True)
            print(f"  This is a bug in verify-evidence-figures.py. "
                  f"Please file an issue.", flush=True)
        else:
            print("\nREFUSED — no open pull request found for current branch.",
                  flush=True)
            print("  Create a PR first, or pass --pr N explicitly.", flush=True)
            if _gh_r.stderr.strip():
                print(f"  (gh said: {_gh_r.stderr.strip()[:120]})", flush=True)
        sys.exit(2)
    if not _gh_r.stdout.strip():
        print("\nREFUSED — no open pull request found for current branch.", flush=True)
        print("  Create a PR first, or pass --pr N explicitly.", flush=True)
        sys.exit(2)
    try:
        _gh_meta  = _json.loads(_gh_r.stdout.strip())
        pr_number = _gh_meta["number"]
        _gh_head  = _gh_meta.get("headRefOid", "")
    except (_json.JSONDecodeError, KeyError) as _e:
        print(f"\nREFUSED — could not parse PR metadata from gh: {_e}", flush=True)
        sys.exit(2)
    # Coherence: PR head SHA on GitHub must match local HEAD.
    if _gh_head and _gh_head != head:
        print(f"\nREFUSED — PR #{pr_number} head SHA from GitHub ({_gh_head[:7]})"
              f" ≠ local HEAD ({head[:7]}).", flush=True)
        print("  The local branch is ahead of (or behind) the pushed PR.", flush=True)
        print("  Have you run 'git push'?", flush=True)
        sys.exit(2)

# ── Artifact discovery ─────────────────────────────────────────────────────────
# Locate pr-description.md and derive evidence paths.
# Auto-discovery uses HEAD SHA so the wrong artifact set is structurally
# rejected (fail-closed) rather than silently producing misleading failures.
if args.pr_desc is not None:
    PR_DESC = args.pr_desc.resolve()
    SLUG    = PR_DESC.parent.name
else:
    _factory_delivery = REPO / ".factory/code-delivery"
    _candidates = (list(_factory_delivery.glob("*/pr-description.md"))
                   if _factory_delivery.exists() else [])
    _matching = [p for p in _candidates
                 if f"**Head SHA:** {head}" in p.read_text()]
    if len(_matching) == 0:
        print(f"\nREFUSED — no pr-description.md found containing", flush=True)
        print(f"  '**Head SHA:** {head}'", flush=True)
        print(f"  Scanned {len(_candidates)} file(s) in {_factory_delivery}",
              flush=True)
        print(f"  Ensure pr-description.md is written for the current commit,",
              flush=True)
        print(f"  or pass --pr-desc PATH to specify it explicitly.", flush=True)
        sys.exit(2)
    if len(_matching) > 1:
        print(f"\nREFUSED — ambiguous: {len(_matching)} pr-description.md files match"
              f" HEAD {head[:7]}:", flush=True)
        for _p in _matching:
            print(f"  {_p}", flush=True)
        print(f"  Use --pr-desc PATH to specify which one.", flush=True)
        sys.exit(2)
    PR_DESC = _matching[0]
    SLUG    = PR_DESC.parent.name

if args.evidence_dir is not None:
    EV_DIR = args.evidence_dir.resolve()
else:
    EV_DIR = REPO / f"docs/demo-evidence/{SLUG}"
    if not EV_DIR.exists():
        print(f"\nREFUSED — evidence directory not found: {EV_DIR}", flush=True)
        print(f"  Expected at docs/demo-evidence/{SLUG}/", flush=True)
        print(f"  Use --evidence-dir PATH to specify an alternate location.",
              flush=True)
        sys.exit(2)

EV_RPT  = EV_DIR / "evidence-report.md"
STAMPED = [
    EV_DIR / "AC-001-preflight.txt",
    EV_DIR / "AC-005-adr-consistency-live.txt",
    EV_DIR / "AC-006-ec-injectivity-live.txt",
]

# ── Derive expected values from live runs (independent probes) ────────────────
if _TEST_ST_FILE:
    st_out = Path(_TEST_ST_FILE).read_text().strip()
else:
    print("Running selftest suite (~65 s) …", flush=True)
    st_out = sh("bash", "scripts/spec-lint/selftest/run-selftests.sh")

if _TEST_ADR_FILE:
    adr_out = Path(_TEST_ADR_FILE).read_text().strip()
else:
    print("Running check-adr-consistency …", flush=True)
    adr_out = sh("python3", "scripts/spec-lint/check-adr-consistency.py")

if _TEST_EI_FILE:
    ei_out = Path(_TEST_EI_FILE).read_text().strip()
else:
    print("Running check-ec-injectivity …", flush=True)
    ei_out = sh("python3", "scripts/spec-lint/check-ec-injectivity.py")

pr  = PR_DESC.read_text()
ev  = EV_RPT.read_text()

# ── SUGGESTION-9: ev_no_prev — anchor on the actual baseline label ────────────
# Previous filter must use the EXACT baseline label, not the bare substring
# "Previous" which would also filter "Previously", "Previously-skipped", etc.
# An assertion on the expected count of baseline lines ensures the exclusion
# set cannot silently widen (which would let wrong current-state figures pass).
PREV_LABEL = "Previous (post-gate34)"
prev_lines = [ln for ln in ev.splitlines() if PREV_LABEL in ln]
if len(prev_lines) != 2:
    fail("ev-baseline/prev-lines",
         f"exactly 2 '{PREV_LABEL}' baseline lines in evidence-report.md",
         f"{len(prev_lines)} found — exclusion set has drifted")
ev_no_prev = "\n".join(ln for ln in ev.splitlines() if PREV_LABEL not in ln)

docs         = pr + "\n" + ev            # used for Check 2 (no historical rc/ec in ev)
docs_no_prev = pr + "\n" + ev_no_prev   # used for Check 4 (has historical ec-injectivity)

# ── Check 1: Selftest count ───────────────────────────────────────────────────
sm = re.search(r"Selftest passed: (\d+)/(\d+)", st_out)
if not sm:
    fail("selftest-count/live", "Selftest passed: N/N", "line not found in runner output")
else:
    live_st = f"{sm.group(1)}/{sm.group(2)}"
    bm = re.search(r"selftests-(\d+)%2F(\d+)", pr)
    if not bm or f"{bm.group(1)}/{bm.group(2)}" != live_st:
        fail("selftest-count/pr-badge", live_st,
             f"{bm.group(1)}/{bm.group(2)}" if bm else "badge not found")
    hm = re.search(r"## Selftest Run \((\d+)/(\d+) confirmed\)", ev)
    if not hm or f"{hm.group(1)}/{hm.group(2)}" != live_st:
        fail("selftest-count/evidence-heading", live_st,
             f"{hm.group(1)}/{hm.group(2)}" if hm else "heading not found")

# ── Check 2: check-adr-consistency figures (ALL occurrences — S-5) ────────────
# BLOCKING-D fix: else-branch ensures unparseable live output is a failure, not
# a silent skip.
# S-5 fix (complete): widened pattern anchored on figure keywords catches all
# five restatement forms (abbreviated "occ", full "occurrences", different word
# order in evidence-report) across both pr-description.md and evidence-report.md.
# MIN_RC_EC_COUNT: assert at least this many restatements exist; fails if any
# site is silently removed from the documents.
MIN_RC_EC_COUNT = 5
am = re.search(r"(\d+) violations found \((\d+) reason-code occurrences \+ (\d+) E-class code",
               adr_out)
if not am:
    fail("adr-consistency/live",
         "violations-found summary line",
         "not parseable from live output")
else:
    live_rc, live_ec = am.group(2), am.group(3)
    # Widened pattern: anchor on "reason-code" + "E-class", tolerating:
    #   "78 reason-code + 6 E-class occurrences"          (pr:74, pr:223)
    #   "78 reason-code + 6 E-class occ"                  (pr:206, ev:16)
    #   "78 reason-code occurrences + 6 E-class code occurrences" (ev:32)
    RC_EC_PAT = re.compile(
        r"(\d+)\s+reason-code(?:\s+occurrences?)?\s*\+\s*(\d+)\s+E-class"
        r"(?:\s+code)?\s+occ(?:urrences?)?",
        re.IGNORECASE,
    )
    rc_matches = list(RC_EC_PAT.finditer(docs))
    if not rc_matches:
        fail("adr-consistency/pr-claim",
             f"rc={live_rc} ec={live_ec}",
             "pattern not found in pr-description.md or evidence-report.md")
    else:
        print(f"    adr-consistency figures: {len(rc_matches)} occurrence(s) compared",
              flush=True)
        for idx, m in enumerate(rc_matches, 1):
            if m.group(1) != live_rc:
                fail(f"adr-consistency/reason-code[{idx}/{len(rc_matches)}]",
                     live_rc, m.group(1))
            if m.group(2) != live_ec:
                fail(f"adr-consistency/e-class[{idx}/{len(rc_matches)}]",
                     live_ec, m.group(2))
        if len(rc_matches) < MIN_RC_EC_COUNT:
            fail("adr-consistency/min-restatements",
                 f">= {MIN_RC_EC_COUNT} restatements of the rc/ec figure pair",
                 f"only {len(rc_matches)} found — a restatement site may have been removed")
    checks_ran.add("check2-adr-figures")

# ── SUGGESTION-10 (Check 2 side): novel-spelling scan for rc/ec figure pair ───
# After all RC_EC_PAT matches are collected, scan for any LINE that states
# BOTH the rc figure near "reason-code" AND the ec figure near "E-class" yet
# is NOT covered by RC_EC_PAT.  This catches combined restatements in novel
# prose (e.g. "78 reason-code findings and 6 E-class detections found").
#
# Combined-pair scan (not per-figure): avoids false positives for the ec
# figure ("6") which appears in the enumerated-sites block and other contexts
# where it is NOT a paired rc/ec restatement.
#
# D-039 disclosure: every declared entry is printed in the output.
# An entry here is a DISCLOSURE, not a suppression — the site is auditable.
ADR_NOVEL_DECLARED: list = [
    # (identifying_fragment, justification)
    # Empty: no uncovered sites in current documents.
    # When a new novel-spelling site is added, declare it here with justification.
    # Every declared entry is enumerated in the output per D-039.
]
if am:  # only run if live figures were parseable
    _ADR_RC_CTX = re.compile(r'\breason-code\b', re.IGNORECASE)
    _ADR_EC_CTX = re.compile(r'\bE-class\b', re.IGNORECASE)
    _NUM = re.compile(r'\b(\d+)\b')
    _novel_rc_count = 0
    _adr_decl_seen: set = set()
    for _line in docs.splitlines():
        # B-1 fix: key on context words, not on the live figure value.
        # Old code gated on `live_rc in _line`, so a wrong-value restatement
        # (e.g. "77 reason-code ... E-class") was silently skipped — the line
        # never reached the scan.  New code keys on the semantic markers: a
        # line is a combined rc+ec claim if it mentions BOTH "reason-code" AND
        # "E-class", regardless of which integers appear on it.
        # Structural guarantee: "figure present but unvalidated" is
        # unrepresentable — an uncovered combined context line always fails.
        if not (_ADR_RC_CTX.search(_line) and _ADR_EC_CTX.search(_line)):
            continue
        if RC_EC_PAT.search(_line):
            continue  # covered by the structured pattern
        # Uncovered combined rc+ec context line.  Fail unless declared.
        _decl = next((d for d in ADR_NOVEL_DECLARED if d[0] in _line), None)
        if _decl:
            if _line not in _adr_decl_seen:
                _adr_decl_seen.add(_line)
                _novel_rc_count += 1
                print(f"  DECLARED novel-spelling [adr]: {_decl[1]!r}", flush=True)
                print(f"    context: ...{_line[:100]}...", flush=True)
        else:
            # Extract wrong integers for the diagnostic; always fail on uncovered lines.
            _wrong = [_m.group(1) for _m in _NUM.finditer(_line)
                      if _m.group(1) not in (live_rc, live_ec)]
            if _wrong:
                fail("adr-consistency/novel-spelling",
                     f"rc={live_rc} ec={live_ec} (or a declared exemption)",
                     f"uncovered figure(s) {_wrong!r} on line: {_line[:100]!r}")
            else:
                fail("adr-consistency/novel-spelling",
                     "combined rc+ec mention matched by RC_EC_PAT or declared "
                     "in ADR_NOVEL_DECLARED",
                     f"uncovered combined mention on line: {_line[:100]!r}")
    if _novel_rc_count:
        print(f"  adr-consistency: {_novel_rc_count} declared novel-spelling site(s) "
              "(enumerated above per D-039)", flush=True)
    # S-7: stale-declaration detection — every declared entry must match >= 1 live site.
    for _de in ADR_NOVEL_DECLARED:
        if not any(
            _ADR_RC_CTX.search(_ln) and _ADR_EC_CTX.search(_ln)
            and not RC_EC_PAT.search(_ln) and _de[0] in _ln
            for _ln in docs.splitlines()
        ):
            fail("adr-consistency/stale-novel-declaration",
                 f"declared exemption {_de[0]!r} must match >= 1 uncovered site",
                 "no matching uncovered combined rc+ec line found — declaration is stale")

# ── Check 3: E-class ledger triple + invariant (SUGGESTION-11) ────────────────
# BLOCKING-D fix: else-branch required; unparseable ledger line is a failure.
# SUGGESTION-11 fix: upgrade from re.search (first match only, pr-only) to
# re.finditer over pr + ev, with a minimum count and per-match validation.
# This brings Check 3 to parity with Checks 2 and 4 (both of which were fixed
# for the same defect class in a prior cycle).
pop_m = re.search(r"population=(\d+), examined=(\d+), skipped=(\d+)", adr_out)
if not pop_m:
    fail("e-class-ledger/live",
         "population=N, examined=N, skipped=N summary line",
         "not parseable from live output")
else:
    lpop, lexam, lskip = pop_m.group(1), pop_m.group(2), pop_m.group(3)
    if int(lpop) != int(lexam) + int(lskip):
        fail("e-class-ledger/invariant", f"{lpop}=={lexam}+{lskip}",
             str(int(lexam) + int(lskip)))
    # SUGGESTION-11: all-occurrence validation across pr + ev (not pr-only, not first-only).
    # PR body may use abbreviated "pop=" or full "population="
    MIN_LEDGER_COUNT = 3
    ledger_matches = list(re.finditer(
        r"pop(?:ulation)?=(\d+), examined=(\d+), skipped=(\d+)",
        pr + "\n" + ev
    ))
    if not ledger_matches:
        fail("e-class-ledger/pr-claim", f"pop={lpop} exam={lexam} skip={lskip}",
             "not found in pr-description.md or evidence-report.md")
    else:
        print(f"    e-class-ledger triple: {len(ledger_matches)} occurrence(s) compared",
              flush=True)
        for idx, dm in enumerate(ledger_matches, 1):
            if dm.group(1) != lpop:
                fail(f"e-class-ledger/population[{idx}/{len(ledger_matches)}]",
                     lpop, dm.group(1))
            if dm.group(2) != lexam:
                fail(f"e-class-ledger/examined[{idx}/{len(ledger_matches)}]",
                     lexam, dm.group(2))
            if dm.group(3) != lskip:
                fail(f"e-class-ledger/skipped[{idx}/{len(ledger_matches)}]",
                     lskip, dm.group(3))
        if len(ledger_matches) < MIN_LEDGER_COUNT:
            fail("e-class-ledger/min-count",
                 f">= {MIN_LEDGER_COUNT} ledger-triple assertions",
                 f"only {len(ledger_matches)} found — a restatement site may have been removed")
    checks_ran.add("check3-ledger-triple")

# ── Check 4: check-ec-injectivity figures (ALL occurrences — S-5 complete) ────
# BLOCKING-D fix: else-branch required; unparseable summary is a failure.
# S-5 fix (complete): multiple patterns anchored on figure keywords ("citations
# compared/with", "divergent", "adjudication") catch all restatement forms.
#
# Per-figure minimum counts assert that no restatement site is silently deleted.
MIN_CMP_COUNT = 9   # citations-compared occurrences validated
MIN_DIV_COUNT = 9   # divergent occurrences validated
MIN_ADJ_COUNT = 8   # adjudication occurrences validated

eim = re.search(r"(\d+) EC citations compared.*?(\d+) divergent, (\d+) require adjudication",
                ei_out)
if not eim:
    fail("ec-injectivity/live",
         "EC citations compared summary line",
         "not parseable from live output")
else:
    lcmp, ldiv, ladj = eim.group(1), eim.group(2), eim.group(3)

    # Collect all per-figure assertions as (value, label) pairs.
    cmp_found: list = []
    div_found: list = []
    adj_found: list = []

    # ── Pattern A: standard triple (citations compared/with + divergent + adjudication)
    STANDARD_PAT = re.compile(
        r"(\d+)\s+(?:EC\s+)?citations?\s+(?:compared|with)\b.*?"
        r"(\d+)\s+(?:DIVERGENT|divergent)\b.*?"
        r"(\d+)\s+(?:ADJUDICATION|adjudication|require\s+adjudication)\b"
    )
    for i, m in enumerate(STANDARD_PAT.finditer(docs_no_prev), 1):
        cmp_found.append((m.group(1), f"ec-injectivity/std-triple[{i}]"))
        div_found.append((m.group(2), f"ec-injectivity/std-triple[{i}]"))
        adj_found.append((m.group(3), f"ec-injectivity/std-triple[{i}]"))

    # ── Pattern B: bold reversed triple (pr:207 — "**M DIVERGENT + P ADJUDICATION; N TV rows**")
    BOLD_REV_PAT = re.compile(
        r"\*\*(\d+)\s+(?:DIVERGENT|divergent)[^|]*?"
        r"(\d+)\s+(?:ADJUDICATION|adjudication)[^|]*?"
        r"(\d+)\s+of\s+\d+\s+TV\s+rows\s+compared\*\*"
    )
    for i, m in enumerate(BOLD_REV_PAT.finditer(pr), 1):
        div_found.append((m.group(1), f"ec-injectivity/bold-rev-triple[{i}]"))
        adj_found.append((m.group(2), f"ec-injectivity/bold-rev-triple[{i}]"))
        cmp_found.append((m.group(3), f"ec-injectivity/bold-rev-triple[{i}]"))

    # ── Pattern C: transition triple (pr:381 — "→N ec-injectivity; →M divergent; →P adjudication")
    TRANSITION_PAT = re.compile(
        r"→(\d+)\s+ec-injectivity\s+comparisons?[^→\n]*?"
        r"→(\d+)\s+divergent[^→\n]*?"
        r"→(\d+)\s+adjudication"
    )
    for i, m in enumerate(TRANSITION_PAT.finditer(pr), 1):
        cmp_found.append((m.group(1), f"ec-injectivity/transition-triple[{i}]"))
        div_found.append((m.group(2), f"ec-injectivity/transition-triple[{i}]"))
        adj_found.append((m.group(3), f"ec-injectivity/transition-triple[{i}]"))

    # ── Pattern D: single citations figure (pr:24 — "compares N of K citations", cmp only)
    SINGLE_CMP_PAT = re.compile(r"compares?\s+(\d+)\s+of\s+\d+\s+citations?")
    for i, m in enumerate(SINGLE_CMP_PAT.finditer(pr), 1):
        cmp_found.append((m.group(1), f"ec-injectivity/cmp-only[{i}]"))

    # ── Pattern E: per-figure in evidence-report (ev_no_prev — catches partial triples)
    EV_CMP_PAT = re.compile(r"(\d+)\s+(?:EC\s+)?citations?\s+compared\b")
    EV_DIV_PAT = re.compile(r"(\d+)\s+divergent\b")
    EV_ADJ_PAT = re.compile(r"(\d+)\s+(?:require\s+)?adjudication\b")
    for i, m in enumerate(EV_CMP_PAT.finditer(ev_no_prev), 1):
        cmp_found.append((m.group(1), f"ec-injectivity/ev-cmp[{i}]"))
    for i, m in enumerate(EV_DIV_PAT.finditer(ev_no_prev), 1):
        div_found.append((m.group(1), f"ec-injectivity/ev-div[{i}]"))
    for i, m in enumerate(EV_ADJ_PAT.finditer(ev_no_prev), 1):
        adj_found.append((m.group(1), f"ec-injectivity/ev-adj[{i}]"))

    # ── Validate all collected assertions against live output
    if not cmp_found:
        fail("ec-injectivity/citations-found", ">= 1 citation assertion in docs",
             "0 found — pattern broken?")
    if not div_found:
        fail("ec-injectivity/divergent-found", ">= 1 divergent assertion in docs",
             "0 found — pattern broken?")
    if not adj_found:
        fail("ec-injectivity/adjudication-found", ">= 1 adjudication assertion in docs",
             "0 found — pattern broken?")

    for val, label in cmp_found:
        if val != lcmp:
            fail(label, lcmp, val)
    for val, label in div_found:
        if val != ldiv:
            fail(label, ldiv, val)
    for val, label in adj_found:
        if val != ladj:
            fail(label, ladj, val)

    # ── Per-figure count reporting + minimum assertions
    print(f"    ec-injectivity citations-compared: {len(cmp_found)} occurrence(s) validated",
          flush=True)
    print(f"    ec-injectivity divergent:          {len(div_found)} occurrence(s) validated",
          flush=True)
    print(f"    ec-injectivity adjudication:       {len(adj_found)} occurrence(s) validated",
          flush=True)

    if len(cmp_found) < MIN_CMP_COUNT:
        fail("ec-injectivity/min-cmp",
             f">= {MIN_CMP_COUNT} citations-compared assertions",
             f"only {len(cmp_found)} found — a restatement site may have been removed")
    if len(div_found) < MIN_DIV_COUNT:
        fail("ec-injectivity/min-div",
             f">= {MIN_DIV_COUNT} divergent assertions",
             f"only {len(div_found)} found — a restatement site may have been removed")
    if len(adj_found) < MIN_ADJ_COUNT:
        fail("ec-injectivity/min-adj",
             f">= {MIN_ADJ_COUNT} adjudication assertions",
             f"only {len(adj_found)} found — a restatement site may have been removed")

    checks_ran.add("check4-ei-figures")

    # ── SUGGESTION-10 (Check 4 side): novel-spelling scan for ei figures ──────
    # After all five patterns have run, scan docs_no_prev for any occurrence of
    # a live figure adjacent to an ec-injectivity context keyword that is NOT
    # covered by an existing pattern match span.  Uncovered occurrences must be
    # declared in EI_NOVEL_DECLARED or the check fails — inverting the default
    # from "unmatched text is invisible" to "unmatched text must be declared".
    #
    # D-039 disclosure: every declared entry is printed in the output.
    EI_NOVEL_DECLARED: list = [
        # (identifying_fragment, justification)
        # Empty: no uncovered sites in current documents.
        # When a new novel-spelling site is added, declare it here with justification.
        # Every declared entry is enumerated in the output per D-039.
    ]
    _EI_CTX = re.compile(
        r'\b(?:citations?\s+(?:compared|with)|divergent|adjudication|'
        r'injectivity|EC\s+citations?)\b',
        re.IGNORECASE,
    )
    # Build covered-spans: character ranges in docs_no_prev covered by any pattern.
    # ev-specific patterns (E) run on ev_no_prev; offset into docs_no_prev.
    _ev_offset = len(pr) + 1  # +1 for the "\n" separator
    _ei_covered: list = []
    for _pat in [STANDARD_PAT, BOLD_REV_PAT, TRANSITION_PAT, SINGLE_CMP_PAT]:
        for _pm in _pat.finditer(docs_no_prev):
            _ei_covered.append((_pm.start(), _pm.end()))
    for _pat in [EV_CMP_PAT, EV_DIV_PAT, EV_ADJ_PAT]:
        for _pm in _pat.finditer(ev_no_prev):
            _ei_covered.append((_pm.start() + _ev_offset, _pm.end() + _ev_offset))

    _novel_ei_count = 0
    for _fig, _fig_label in [(lcmp, "cmp"), (ldiv, "div"), (ladj, "adj")]:
        for _fm in re.finditer(re.escape(_fig), docs_no_prev):
            _window = docs_no_prev[max(0, _fm.start()-80):_fm.end()+80]
            if not _EI_CTX.search(_window):
                continue  # not figure-adjacent
            if any(_s <= _fm.start() < _e for _s, _e in _ei_covered):
                continue  # already covered by an existing pattern
            _site_ctx = docs_no_prev[max(0, _fm.start()-40):_fm.end()+40].strip()
            _decl = next((d for d in EI_NOVEL_DECLARED if d[0] in _site_ctx), None)
            if _decl:
                _novel_ei_count += 1
                print(f"  DECLARED novel-spelling [ei/{_fig_label}]: {_decl[1]!r}", flush=True)
                print(f"    context: ...{_site_ctx}...", flush=True)
            else:
                fail(f"ec-injectivity/novel-spelling/{_fig_label}",
                     "figure-adjacent occurrence matched by an existing pattern or "
                     "declared in EI_NOVEL_DECLARED",
                     f"uncovered mention of '{_fig}' near: ...{_site_ctx!r}...")
    # B-1 fix: per-metric context scan to catch WRONG figures in novel prose.
    # The existing scan above (keyed on live figure values) catches correct-value
    # novel spellings (e.g. T07: "174 citations found, 42 divergent").  This scan
    # inverts the key: it locates metric context words first, then extracts whatever
    # integer is adjacent, and fails if that integer differs from the live value.
    # A wrong figure was previously invisible because it never matched
    # re.escape(live_figure).
    # Structural guarantee: a wrong figure adjacent to a metric context word cannot
    # silently pass — it is unrepresentable as "correct" because the scan compares
    # to the live value, not to a pattern keyed on the correct answer.
    _EI_DIV_NOVEL_PAT = re.compile(r'(\d+)\s+divergent\b', re.IGNORECASE)
    _EI_ADJ_NOVEL_PAT = re.compile(r'(\d+)\s+(?:require\s+)?adjudication\b',
                                    re.IGNORECASE)
    _EI_CMP_NOVEL_PAT = re.compile(r'(\d+)\s+(?:EC\s+)?citations?\s+compared\b',
                                    re.IGNORECASE)
    _ei_metric_scans = [
        (ldiv, "div", _EI_DIV_NOVEL_PAT),
        (ladj, "adj", _EI_ADJ_NOVEL_PAT),
        (lcmp, "cmp", _EI_CMP_NOVEL_PAT),
    ]
    _ei_novel_wrong_seen: set = set()
    for _live_val, _fig_label, _novel_pat in _ei_metric_scans:
        for _nm in _novel_pat.finditer(docs_no_prev):
            if any(_s <= _nm.start() < _e for _s, _e in _ei_covered):
                continue  # covered by existing structured pattern
            if _nm.group(1) == _live_val:
                continue  # correct value — existing per-figure scan handles it
            # Wrong integer in metric context, not covered by any structured pattern.
            _site_ctx = docs_no_prev[max(0, _nm.start()-40):_nm.end()+40].strip()
            _decl = next((d for d in EI_NOVEL_DECLARED if d[0] in _site_ctx), None)
            _key = (_fig_label, _nm.start())
            if _decl:
                if _key not in _ei_novel_wrong_seen:
                    _ei_novel_wrong_seen.add(_key)
                    _novel_ei_count += 1
                    print(f"  DECLARED novel-spelling [ei/{_fig_label}]: {_decl[1]!r}",
                          flush=True)
                    print(f"    context: ...{_site_ctx}...", flush=True)
            else:
                fail(f"ec-injectivity/novel-spelling/{_fig_label}",
                     f"{_fig_label}={_live_val} (or a declared exemption)",
                     f"uncovered wrong figure {_nm.group(1)!r} near: ...{_site_ctx!r}...")
    if _novel_ei_count:
        print(f"  ec-injectivity: {_novel_ei_count} declared novel-spelling site(s) "
              "(enumerated above per D-039)", flush=True)
    # S-7: stale-declaration detection for EI — every declared entry must match >= 1
    # live uncovered site (either in the original per-figure scan or the new
    # per-metric context scan).
    for _de in EI_NOVEL_DECLARED:
        _frag = _de[0]
        _live_orig = any(
            _EI_CTX.search(docs_no_prev[max(0, _fm.start()-80):_fm.end()+80])
            and not any(_s <= _fm.start() < _e for _s, _e in _ei_covered)
            and _frag in docs_no_prev[max(0, _fm.start()-40):_fm.end()+40]
            for _fig in (lcmp, ldiv, ladj)
            for _fm in re.finditer(re.escape(_fig), docs_no_prev)
        )
        _live_new = any(
            not any(_s <= _nm.start() < _e for _s, _e in _ei_covered)
            and _frag in docs_no_prev[max(0, _nm.start()-40):_nm.end()+40]
            for _live_val, _, _npat in _ei_metric_scans
            for _nm in _npat.finditer(docs_no_prev)
        )
        if not (_live_orig or _live_new):
            fail("ec-injectivity/stale-novel-declaration",
                 f"declared exemption {_frag!r} must match >= 1 uncovered site",
                 "no matching uncovered ei-context mention found — declaration is stale")

# ── Check 5: Head SHA ─────────────────────────────────────────────────────────
sha_m = re.search(r"\*\*Head SHA:\*\*\s+([0-9a-f]{40})", pr)
if not sha_m:
    fail("head-sha/pr-description", head[:7], "**Head SHA:** not found in pr-description.md")
elif sha_m.group(1) != head:
    fail("head-sha/pr-description", head, sha_m.group(1))

# ── Check 6: Enumerated-site consistency (BLOCKING-B) ────────────────────────
det_m = re.search(
    r"(\d+) E-class (?:code )?occurrences validated\)\.?\s*Detection confirmed at:\n"
    r"(.*?)(?=New selftest|\n\n|\Z)",
    pr, re.DOTALL,
)
if not det_m:
    fail("enumerated-sites/block", "Detection confirmed at: block", "not found in pr-description.md")
else:
    claimed_n = int(det_m.group(1))
    block     = det_m.group(2)
    sent_m = re.search(r"\.\s*(?:\n|(?=[A-Z]))", block)
    if sent_m:
        val_text  = block[:sent_m.start() + 1]
        excl_text = block[sent_m.end():]
    else:
        val_text, excl_text = block, ""
    val_sites = []
    for m in re.finditer(r"`([\w./-]+\.md):(\d+(?:,\d+)*)`", val_text):
        for ln in m.group(2).split(","):
            val_sites.append(f"{m.group(1)}:{ln.strip()}")
    if len(val_sites) != claimed_n:
        fail("enumerated-sites/count",
             f"{claimed_n} sites for claimed {claimed_n} validated occurrences",
             f"{len(val_sites)} sites found: {val_sites}")
    live_e_sites = re.findall(r"([\w./-]+\.md):(\d+): E-class code", adr_out)
    if not live_e_sites:
        fail("enumerated-sites/completeness",
             "at least one live E-class detection site from checker output",
             "live_e_sites is empty — completeness loop would never run "
             "(adr_out unparseable or checker found no E-class codes)")
    else:
        for fpath, ln in live_e_sites:
            bname = f"{Path(fpath).name}:{ln}"
            if not any(f"{Path(s.split(':')[0]).name}:{s.rsplit(':', 1)[-1]}" == bname
                       for s in val_sites):
                fail("enumerated-sites/completeness",
                     f"{bname} present in validated enumeration",
                     f"{bname} missing from 'Detection confirmed at:' list")
        checks_ran.add("check6-completeness")
    for m in re.finditer(r"`([\w./-]+\.md):(\d+(?:,\d+)*)`", excl_text):
        for ln in m.group(2).split(","):
            site = f"{m.group(1)}:{ln.strip()}"
            if site in val_sites:
                fail("enumerated-sites/bucket-overlap",
                     f"{site} in exactly one bucket",
                     f"{site} appears in both validated and excluded parts")

# ── Check 7: Provenance stamps — content-obtainable-at-SHA (BLOCKING-E) ───────
def _normalise_stamp(text: str) -> str:
    """Strip 'Captured at: <sha>' lines and outer blank lines for comparison."""
    filtered = "\n".join(
        line for line in text.splitlines()
        if not re.match(r"Captured at: [0-9a-f]{40}\s*$", line)
    )
    return filtered.strip()

if _TEST_MODE:
    # Provenance stamp verification requires the AC files to exist at their
    # captured-at commit in the real git history.  In test mode, the temp
    # directory may contain synthetic AC files whose stamps don't match the
    # current worktree; skipping avoids false failures while preserving the
    # check for all non-test runs (CI and manual invocations).
    print("  [provenance-stamps] SKIPPED — test mode (_VEF_TEST_* vars active)",
          flush=True)
else:
    for ac_path in STAMPED:
        content = ac_path.read_text()
        stamp_m = re.search(r"Captured at: ([0-9a-f]{40})", content)
        if not stamp_m:
            fail(f"provenance-stamp/{ac_path.name}",
                 "Captured at: <sha> line present",
                 "stamp not found in artifact")
        else:
            stamp    = stamp_m.group(1)
            # rel_path is computed relative to REPO (test tmpdir or real repo).
            # The path structure is identical in both, so git show with this
            # relative path against _SCRIPT_REPO (via sh()) is correct.
            rel_path = str(ac_path.relative_to(REPO))
            blob = sh("git", "show", f"{stamp}:{rel_path}")
            if _normalise_stamp(blob) != _normalise_stamp(content):
                fail(f"provenance-stamp/{ac_path.name}",
                     f"stamp names a commit whose normalised content matches current artifact",
                     f"content at {stamp[:7]} differs — artifact was not captured there")

# ── SUGGESTION-2 / check2a-e-cli-001: E-CLI-001 location ─────────────────────
# SUGGESTION-8 fix: register via anchor_check() + fail when anchor absent.
_ecli_m = re.search(r"E-CLI-001", adr_out)
if anchor_check("check2a-e-cli-001", _ecli_m,
                "traceability/e-cli-001-in-live",
                "E-CLI-001 detection in live adr-consistency output"):
    if re.search(r"E-CLI-001.*?test-vectors|test-vectors.*?E-CLI-001", pr):
        ecli_live = re.search(r"([\w./-]+\.md:\d+): E-class code 'E-CLI-001'", adr_out)
        live_loc  = Path(ecli_live.group(1)).name if ecli_live \
                    else "BC-2.11.004.md:61 (from live run)"
        fail("traceability/e-cli-001-location",
             live_loc,
             "pr-description.md attributes E-CLI-001 ×1 to 'test-vectors'")

# ── SUGGESTION-4 / check4a-ac002-suffix: AC-002 filename suffix ───────────────
# SUGGESTION-8 fix: register via anchor_check() + fail when AC-002 is absent.
_ac002 = next(EV_DIR.glob("AC-002*.txt"), None)
if anchor_check("check4a-ac002-suffix", _ac002,
                "evidence-report/ac002-missing",
                "AC-002*.txt artifact in evidence directory"):
    sfx_m = re.search(r"(\d+of\d+)", _ac002.name)
    if sfx_m:
        correct_sfx = sfx_m.group(1)
        for m in re.finditer(r"\d+of\d+", ev):
            if m.group(0) != correct_sfx:
                fail("evidence-report/ac002-suffix",
                     correct_sfx,
                     f"evidence-report.md references '{m.group(0)}'")
                break

# ── B-4 / check7+check9: derive branch SHA set from git (not a literal) ──────
# Used by both check7 (rollback completeness) and check9 (captured-SHA on-branch).
# LESSON-60 guard: if the result is empty the checks would be vacuous (any
# rollback list would pass; any captured SHA would pass).  We record a failure
# and keep an empty set so subsequent checks still run and collect their own
# failures rather than crashing.
if _TEST_BRANCH_SHAS is not None:
    _branch_shas_raw = _TEST_BRANCH_SHAS.split()
else:
    # develop..HEAD was already validated at module top (n_ahead > 0 guard),
    # so this call should always succeed in production.
    _branch_shas_raw = sh("git", "rev-list", "develop..HEAD", allowed_rc={0}).split()
if not _branch_shas_raw:
    fail("rollback/develop-resolution",
         "at least one commit from git rev-list develop..HEAD",
         "empty result — develop may be unresolvable; rollback/captured-SHA "
         "checks cannot verify completeness (fail-closed, not skipped)")
_branch_sha_set = {s[:7] for s in _branch_shas_raw}

# ── NIT-C / S-7 / check7-rollback: rollback command ──────────────────────────
# SUGGESTION-8 fix: register via anchor_check() + fail when anchor absent.
# B-4 fix: derive required SHA set from git rev-list (not a hardcoded literal).
#   Subsumes the old len(listed) != n_branch_commits count check — set
#   comparison catches both count mismatches and specific missing SHAs.
# LESSON-60 fix: bare 'if count_m:' → add else: fail() so absent count anchor
#   is a failure, not a silent pass.
_revert_m = re.search(r"git revert((?:\s+[0-9a-f]{7,40})+)", pr)
if anchor_check("check7-rollback", _revert_m,
                "rollback/block",
                "a `git revert <sha> …` command listing every branch commit — "
                "no explicit SHA list found in pr-description.md"):
    listed = _revert_m.group(1).split()
    _listed_short = {s[:7] for s in listed}
    _missing = _branch_sha_set - _listed_short
    if _missing:
        fail("rollback/missing-commits",
             f"every branch commit in the revert list ({len(_branch_sha_set)} total)",
             f"missing: {sorted(_missing)}")
    count_m = re.search(r"Rollback reverts all (\d+) commits", pr)
    if count_m:
        claimed = int(count_m.group(1))
        if claimed != n_branch_commits:
            fail("rollback/count-claim",
                 f"body claims {claimed} commits; "
                 f"git rev-list --count develop..HEAD = {n_branch_commits}",
                 "counts disagree")
    else:
        fail("rollback/count-claim-missing",
             "Rollback reverts all N commits",
             "count-claim anchor absent — check cannot verify commit count")

# ── B-4 / check9: captured-SHA on-branch (replaces circular head-SHA check) ───
# SUGGESTION-8 fix: register via anchor_check() + fail when anchor absent.
#
# Old design (circular): evidence-report.md said '**Head SHA:** X' and required
# X == HEAD.  Since evidence-report.md is committed to the code branch,
# committing it changes HEAD, making the captured SHA immediately stale.
#
# New design (non-circular): evidence-report.md says '**Captured at SHA:** X'
# where X is any commit on this branch (git rev-list develop..HEAD).
# This is git-derivable and provably non-circular:
#   - Evidence is captured at commit A (a prior branch commit)
#   - evidence-report.md is committed as commit B
#   - X = A, which is an ancestor of B (and hence of HEAD)
#   - A ∈ git rev-list develop..HEAD ✓ — non-circular, on-branch guarantee
#
# The check distinguishes a legitimate on-branch SHA from an off-branch or
# unrelated SHA: git rev-list develop..HEAD is the discriminating predicate.
_cap_sha_m = re.search(r"\*\*Captured at SHA:\*\*\s+([0-9a-f]{7,40})", ev)
if anchor_check("check9-head-sha-ev", _cap_sha_m,
                "evidence-report/captured-sha-missing",
                "**Captured at SHA:** field in evidence-report.md"):
    _ev_sha7 = _cap_sha_m.group(1)[:7]
    if _ev_sha7 not in _branch_sha_set:
        fail("evidence-report/captured-sha-not-on-branch",
             f"SHA {_ev_sha7} in git rev-list develop..HEAD "
             f"({len(_branch_sha_set)} commits: {sorted(_branch_sha_set)})",
             f"SHA {_ev_sha7} not found on this branch — evidence may be "
             f"from a different PR or borrowed from another branch")

# ── Check 8: Live PR body must match pr-description.md (FINDING 2) ────────────
# NIT-G fix: wrap gh invocation to produce a diagnostic rather than a traceback
# when the gh binary is not found.
def _norm_body(t: str) -> str:
    return "\n".join(l.rstrip() for l in t.splitlines()).strip()

print("Fetching live PR body via gh …", flush=True)
# Per-PR-number routing: _VEF_TEST_GH_BODY_<pr_number> takes precedence over
# the generic _VEF_TEST_GH_BODY fallback.  This lets tests prove the correct PR
# number is used (not a hardcoded default).
_gh_body_per_pr = os.environ.get(f"_VEF_TEST_GH_BODY_{pr_number}")
if _gh_body_per_pr:
    _live_pr_body_raw: str | None = Path(_gh_body_per_pr).read_text()
elif _TEST_GH_BODY:
    _live_pr_body_raw = Path(_TEST_GH_BODY).read_text()
else:
    _live_pr_body_raw = None
    try:
        _live_pr_body_raw = sh("gh", "pr", "view", str(pr_number),
                                "--json", "body", "--jq", ".body",
                                allowed_rc={0})
    except FileNotFoundError:
        fail("live-pr-body/gh-unavailable",
             "gh CLI available in PATH",
             "gh not found — install gh (https://cli.github.com/) to enable "
             "live PR body sync check")

if _live_pr_body_raw is not None:
    if _norm_body(_live_pr_body_raw) != _norm_body(pr):
        fail("live-pr-body/sync",
             "live PR body matches pr-description.md (normalised)",
             f"live PR body has diverged from pr-description.md — "
             f"run: gh pr edit {pr_number} --body-file {PR_DESC}")
checks_ran.add("check8-live-pr-body")

# ── BLOCKING-D: required-checks gate ─────────────────────────────────────────
missing_checks = REQUIRED_CHECKS - checks_ran
for key in sorted(missing_checks):
    fail(f"required-check/{key}",
         "check registered a live comparison",
         "check never ran (live output unparseable or empty)")

# ── Final report ──────────────────────────────────────────────────────────────
if fails:
    print(f"\nFAIL — {len(fails)} check(s) failed:\n")
    for f in fails:
        print(f)
    sys.exit(1)
print("\nPASS — all figure checks match live output and git state")
