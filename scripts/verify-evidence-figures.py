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
  2  — REFUSED (benign): context not applicable — on develop/post-merge,
       no open PR found (but auth succeeded), resolved PR head ≠ local HEAD,
       or no matching pr-description.md found for current HEAD.
  3  — REFUSED (environment failure): 'gh' not in PATH, or gh returned an
       authentication/token error that prevented PR resolution.
  4  — REFUSED (verifier bug): gh reported an unknown JSON field name —
       this indicates a bug in verify-evidence-figures.py, not a user error.
  5  — PARTIAL: all runnable checks passed but one or more checks were
       loudly skipped due to missing environment capabilities (e.g.
       check8-live-pr-body requires gh API authentication not available).

CI wrapper contract (used in .github/workflows/ci.yml):
  exit 0          → PASS (step succeeds)
  exit 2          → REFUSED-BENIGN (not a failure)
  exit 3 or 4     → FAIL and exit non-zero (genuine CI failure)
  exit 5          → PARTIAL (not a full pass — step fails, job
                    continues when continue-on-error: true)
  any other exit  → FAIL and exit non-zero

Structural guarantee (BLOCKING-D, B-3, B2-2):
  Every check that performs a live-vs-document comparison MUST call
  record_comparison(key, doc_value=<found_value>) on the code path where
  the comparison runs.  The PASS gate asserts REQUIRED_CHECKS == checks_ran;
  a key in REQUIRED_CHECKS that never calls record_comparison() produces a
  failure.

  anchor_check() guards ENTRY only: it asserts the anchor was found and
  returns True/False.  It does NOT register the key.  Callers MUST call
  record_comparison(key, doc_value=) at the actual comparison point.

  Structural guarantee (B2-2, closes register-without-comparing class):
  record_comparison() requires a keyword-only doc_value argument with no
  default.  A call site that omits doc_value raises TypeError at runtime;
  a call site that passes doc_value=None raises AssertionError.  A check
  that found nothing in the document cannot produce a non-None doc_value,
  so it cannot reach a registered state.  This holds for every future check
  added, not just the ones audited today — the API enforces it, not review.

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
  _VEF_TEST_GH_NOT_FOUND    — any non-empty string; simulate 'gh' not in
                              PATH during PR resolution → exit 3.
  _VEF_TEST_CHECK8_AUTH_FAIL — any non-empty string; simulate gh auth
                              failure during check8 body fetch → loud SKIP
                              and exit 5 (PARTIAL).
  _VEF_TEST_STAMP_SHA   — 40-hex string; mock "verified stamp SHA" for check9
                          stamp-equality assertion.  Used when check7 is skipped
                          (normal test mode) but T30/similar tests need check9 to
                          enforce stamp equality.  Takes effect only when check7
                          was skipped (_verified_stamp_sha is None).
  _VEF_TEST_STAMP_REPO  — filesystem path to a git repo; when set, check7 runs
                          git show against this repo instead of _SCRIPT_REPO.
                          Also disables the _TEST_MODE skip of check7.
                          Used by T31 (throwaway-repo coverage).

  Git commands (git show for provenance stamps) run against _SCRIPT_REPO by
  default; _VEF_TEST_STAMP_REPO overrides this for check7 specifically.
"""
import argparse, json as _json, os, re, subprocess, sys
from pathlib import Path

# Real script location — used for git operations so they always run in a valid
# git worktree, even when _VEF_TEST_REPO points to a temp directory.
_SCRIPT_REPO = Path(__file__).resolve().parent.parent

# ── Test-mode overrides ────────────────────────────────────────────────────────
_TEST_REPO             = os.environ.get("_VEF_TEST_REPO")
_TEST_ADR_FILE         = os.environ.get("_VEF_TEST_ADR_FILE")
_TEST_EI_FILE          = os.environ.get("_VEF_TEST_EI_FILE")
_TEST_ST_FILE          = os.environ.get("_VEF_TEST_ST_FILE")
_TEST_N_AHEAD          = os.environ.get("_VEF_TEST_N_AHEAD")
_TEST_HEAD             = os.environ.get("_VEF_TEST_HEAD")
_TEST_GH_BODY          = os.environ.get("_VEF_TEST_GH_BODY")
_TEST_PR_NUM           = os.environ.get("_VEF_TEST_PR_NUM")
_TEST_NO_OPEN_PR       = os.environ.get("_VEF_TEST_NO_OPEN_PR")
_TEST_BRANCH_SHAS      = os.environ.get("_VEF_TEST_BRANCH_SHAS")
_TEST_GH_NOT_FOUND     = os.environ.get("_VEF_TEST_GH_NOT_FOUND")
_TEST_CHECK8_AUTH_FAIL = os.environ.get("_VEF_TEST_CHECK8_AUTH_FAIL")
# B2-4 / check9: mock stamp SHA (replaces check7-derived _verified_stamp_sha).
_TEST_STAMP_SHA        = os.environ.get("_VEF_TEST_STAMP_SHA")
# S2-1 / check7: throwaway git repo for stamp git-show verification.
# NOT included in _TEST_MODE — it is a targeted override, not a mode switch.
_TEST_STAMP_REPO       = os.environ.get("_VEF_TEST_STAMP_REPO")
_TEST_MODE             = any([_TEST_REPO, _TEST_ADR_FILE, _TEST_EI_FILE, _TEST_ST_FILE,
                               _TEST_N_AHEAD, _TEST_HEAD, _TEST_GH_BODY,
                               _TEST_PR_NUM, _TEST_NO_OPEN_PR, _TEST_BRANCH_SHAS,
                               _TEST_GH_NOT_FOUND, _TEST_CHECK8_AUTH_FAIL])

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
# B-3 structural fix: anchor_check() no longer registers to checks_ran.
# B2-2 structural fix: record_comparison(key, doc_value=) requires a non-None
# doc_value argument (keyword-only, no default).  A call site that omits
# doc_value raises TypeError; one that passes doc_value=None raises
# AssertionError.  A check that found nothing in the document cannot produce
# a non-None doc_value, so it cannot reach a registered state.  This closes
# the register-without-comparing class for all current sites AND future sites
# without requiring per-site audit.
# Registration is EXCLUSIVELY via record_comparison(key, doc_value=), called
# only on the code path where the comparison executes AND a document value
# was found.
#
# S-1 coverage: check1 and check5 added (previously unregistered but
# fail-closed).  Sites deliberately left unregistered this pass:
#   - check7-provenance-stamps: skipped in test mode unless _VEF_TEST_STAMP_REPO
#     is provided; T31 covers it via a throwaway git repo (positive + negative).
#   - ADR/EI novel-spelling sub-scans: sub-scans of check2/check4 respectively;
#     parent registration covers them
REQUIRED_CHECKS = {
    "check1-selftest-count",    # B-3/S-1: was unregistered
    "check2-adr-figures",
    "check2a-e-cli-001",        # SUGGESTION-8: was unregistered
    "check3-ledger-triple",
    "check4-ei-figures",
    "check4a-ac002-suffix",     # SUGGESTION-8/B-3: comparison now required
    "check5-head-sha-pr",       # B-3/S-1: was unregistered
    "check6-completeness",
    "check7-rollback",          # SUGGESTION-8: was unregistered
    "check8-live-pr-body",
    "check9-head-sha-ev",       # SUGGESTION-8: was unregistered
}
checks_ran:     set = set()
checks_skipped: set = set()  # B2-1: loudly-skipped checks (not run, not passed)

fails: list = []


def fail(label: str, expected: str, got: str) -> None:
    fails.append(f"  [{label}]\n    expected : {expected}\n    got      : {got}")


def anchor_check(key: str, m, fail_label: str, fail_expected: str) -> bool:
    """Guard entry: assert anchor was found.  Does NOT register the key.

    Called immediately before the comparison body to gate execution.
    If anchor is falsy:  records a failure and returns False.
                         key is NOT added to checks_ran.
    If anchor is truthy: returns True.
                         Caller MUST call record_comparison(key, doc_value=)
                         at the actual comparison point — NOT here.

    Separating entry-guard from comparison-registration makes "anchor found
    but comparison skipped" structurally detectable: if the comparison
    body is never reached or its inner guard prevents it from running,
    record_comparison() is never called and the REQUIRED_CHECKS gate fires.
    """
    if not m:
        fail(fail_label, fail_expected, "anchor not found — check cannot run")
        return False
    return True


def record_comparison(key: str, *, doc_value: object) -> None:
    """Register that a live-vs-document comparison was performed for `key`.

    `doc_value` MUST be the actual value (or evidence of the value) retrieved
    from the document during comparison.  It cannot be None — a None doc_value
    means the document token was absent and no comparison was possible.  In
    that case, call fail() and do NOT call record_comparison().

    Structural guarantee (closes register-without-comparing class, B2-2):
    This function requires a keyword-only `doc_value` argument with no default.
    Any call site that omits doc_value raises TypeError at the call site.
    Any call site that passes doc_value=None raises AssertionError here.
    A check that performed no document lookup cannot produce a non-None
    doc_value, so it cannot call this function successfully.  The class is
    closed by the API signature, not by per-site audit — every current site
    AND every future site is constrained without anyone having to remember.

    Canonical usage:
        if anchor_check(key, anchor, ...):   # guards whether comparison can run
            doc_val = re.search(pattern, document)
            if not doc_val:
                fail(label, expected, "not found in document")
            else:
                ...validate doc_val vs live value...
                record_comparison(key, doc_value=doc_val)

    A key in REQUIRED_CHECKS that never calls record_comparison() causes the
    PASS gate to fire — "anchor present but comparison skipped" is detectable.
    """
    if doc_value is None:
        raise AssertionError(
            f"record_comparison({key!r}): doc_value=None is not allowed — "
            "this means the comparison code ran but found nothing in the document. "
            "If the document token is absent, call fail() instead of "
            "record_comparison().  Passing doc_value=None is a programming error."
        )
    checks_ran.add(key)


def _is_auth_error(stderr: str) -> bool:
    """True when gh's stderr indicates an authentication/token issue.

    Distinguishes auth failures (exit 3 — environment failure) from genuine
    'no PR' responses (exit 2 — benign).  Checks for the three main gh error
    forms: GH_TOKEN mention, the Actions onboarding message, or authentication.
    """
    s = stderr.lower()
    return "gh_token" in s or "to use github cli" in s or "authenticat" in s


_SEP_CELL_PAT = re.compile(r'^\s*:?-+:?\s*$')


def _strip_prev_col(text: str, label: str) -> "tuple[str, dict]":
    """Strip the Markdown table column whose header contains `label`.

    B2-3 fix (option 1): pr-description.md uses the PREV_LABEL string as a
    column header; historical figures (9 divergent, 5 adjudication) live in
    column cells on subsequent rows, NOT on the header row itself.  A simple
    line-level filter (as used for evidence-report.md) would only strip the
    header row and leave the data rows — specifically the historical figures —
    intact in docs_no_prev.  A column-aware filter blanks out only the cell
    at the matching column index in each data row, leaving all other columns
    (including "After This PR") unchanged.

    Returns (filtered_text, stats) where:
      stats["tables"]  — number of header rows where the label column was found
      stats["rows"]    — number of data rows whose cell was blanked

    Structural guarantee: callers MUST assert stats["tables"] >= 1 and
    stats["rows"] >= 1 so the filter cannot silently become a no-op if the
    baseline table is removed or renamed.
    """
    lines = text.splitlines()
    out: list = []
    col_idx: "int | None" = None
    tables = 0
    rows = 0
    for ln in lines:
        stripped = ln.strip()
        is_table_row = stripped.startswith('|') and stripped.endswith('|')
        if is_table_row and col_idx is None and label in ln:
            # Header row — determine column index and begin tracking this table.
            cells = ln.split('|')
            col_idx = next((i for i, c in enumerate(cells) if label in c), None)
            if col_idx is not None:
                tables += 1
            out.append(ln)  # header row kept as-is
        elif is_table_row and col_idx is not None:
            cells = ln.split('|')
            inner = cells[1:-1]   # exclude leading/trailing empty strings from split
            if all(_SEP_CELL_PAT.match(c) for c in inner):
                out.append(ln)    # separator row (|---|---|) — kept unchanged
            elif len(cells) > col_idx:
                cells[col_idx] = ' '   # blank out the historical-column cell
                out.append('|'.join(cells))
                rows += 1
            else:
                out.append(ln)    # row too short — structural anomaly, kept as-is
        else:
            if col_idx is not None and not is_table_row:
                col_idx = None    # end of current table
            out.append(ln)
    return '\n'.join(out), {"tables": tables, "rows": rows}


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
    # B2-1 exit-code split: distinct codes for benign (2), env-failure (3),
    # and verifier-bug (4) rather than collapsing everything into exit 2.
    try:
        if _TEST_GH_NOT_FOUND:
            raise FileNotFoundError("simulated by _VEF_TEST_GH_NOT_FOUND")
        _gh_r = subprocess.run(
            ["gh", "pr", "view", "--json", "number,headRefOid"],
            capture_output=True, text=True,
            cwd=str(_SCRIPT_REPO), timeout=30,
        )
    except FileNotFoundError:
        print("\nREFUSED — 'gh' CLI not found in PATH.", flush=True)
        print("  Install from https://cli.github.com/ or pass --pr N explicitly.",
              flush=True)
        sys.exit(3)  # exit 3: environment failure (tool unavailable)
    if _gh_r.returncode != 0:
        _gh_err = _gh_r.stderr.strip()
        if "Unknown JSON field" in _gh_r.stderr or "unknown field" in _gh_r.stderr.lower():
            # Verifier requested a field that gh does not recognise — this is a
            # bug in the verifier's field list, not a user or environment issue.
            print(f"\nREFUSED — gh query returned an unexpected error "
                  f"(possible bad JSON field name in verifier).", flush=True)
            print(f"  (gh said: {_gh_err[:200]})", flush=True)
            print(f"  This is a bug in verify-evidence-figures.py. "
                  f"Please file an issue.", flush=True)
            sys.exit(4)  # exit 4: verifier self-diagnosed bug
        elif _is_auth_error(_gh_r.stderr):
            # Auth/token failure — environment constraint, not a benign condition.
            print(f"\nREFUSED — gh authentication failed; cannot resolve PR.", flush=True)
            print(f"  Set GH_TOKEN or pass --pr N explicitly.", flush=True)
            if _gh_err:
                print(f"  (gh said: {_gh_err[:200]})", flush=True)
            sys.exit(3)  # exit 3: environment failure (auth unavailable)
        else:
            # No PR found for this branch — benign (no PR exists yet, or was merged).
            print("\nREFUSED — no open pull request found for current branch.",
                  flush=True)
            print("  Create a PR first, or pass --pr N explicitly.", flush=True)
            if _gh_err:
                print(f"  (gh said: {_gh_err[:120]})", flush=True)
            sys.exit(2)  # exit 2: benign (no PR for this branch)
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
        sys.exit(3)  # exit 3: environment failure (unexpected gh output format)
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
# S2-1 fix: AC-002 and AC-007 added to STAMPED so check7 verifies their
# provenance stamps via git show, and check9 binds **Captured at SHA:** to
# the same verified SHA (not merely an on-branch membership check).
STAMPED = [
    EV_DIR / "AC-001-preflight.txt",
    EV_DIR / "AC-002-selftest-99of99.txt",
    EV_DIR / "AC-005-adr-consistency-live.txt",
    EV_DIR / "AC-006-ec-injectivity-live.txt",
    EV_DIR / "AC-007-vef-selftest.txt",
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

# B2-3 fix (option 1): column-aware filter for pr-description.md.
# ev uses line-level filtering because every historical line starts with PREV_LABEL.
# pr uses column-level filtering because PREV_LABEL is a table column HEADER;
# historical figures ("9 divergent, 5 adjudication; 110 of 190 TV rows") appear
# in column cells on subsequent DATA rows — not on the same line as the header.
# A line-level filter on pr would only remove the header row, leaving the data
# rows (and their historical wrong figures) visible to the novel-spelling scans.
# _strip_prev_col blanks out only the matching column cell in each data row.
pr_no_prev, _prev_col_stats = _strip_prev_col(pr, PREV_LABEL)
if _prev_col_stats["tables"] == 0:
    fail("pr-baseline/prev-column-header",
         f"at least one table with '{PREV_LABEL}' column header in pr-description.md",
         "header row not found — column filter is a no-op; "
         "add the baseline comparison table or check PREV_LABEL spelling")
if _prev_col_stats["rows"] == 0:
    fail("pr-baseline/prev-column-rows",
         "at least 1 data row stripped from the prev-column baseline table",
         "header found but no data rows processed — "
         "table may be empty or its column count may have changed")

docs         = pr + "\n" + ev             # used for Check 2 (no historical rc/ec in ev)
docs_no_prev = pr_no_prev + "\n" + ev_no_prev  # both pr and ev filtered

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
    record_comparison("check1-selftest-count", doc_value=live_st)

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
    record_comparison("check2-adr-figures", doc_value=rc_matches)

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
if am:  # only run if live figures were parseable
    _ADR_RC_CTX = re.compile(r'\breason-code\b', re.IGNORECASE)
    _ADR_EC_CTX = re.compile(r'\bE-class\b', re.IGNORECASE)
    _NUM = re.compile(r'\b(\d+)\b')
    # Build covered spans from structured RC_EC_PAT matches.
    # Used by the per-metric scans below (B2-3 fix: P-A, P-A2, P-B).
    _adr_covered = [(m.start(), m.end()) for m in rc_matches]
    for _line in docs.splitlines():
        # B-1 fix: key on context words, not on the live figure value.
        # Old code gated on `live_rc in _line`, so a wrong-value restatement
        # (e.g. "77 reason-code ... E-class") was silently skipped — the line
        # never reached the scan.  New code keys on the semantic markers: a
        # line is a combined rc+ec claim if it mentions BOTH "reason-code" AND
        # "E-class", regardless of which integers appear on it.
        # Structural guarantee: an uncovered combined context line always fails.
        # Declaration channel removed (B2-3); the unconditional fail() is the only path.
        if not (_ADR_RC_CTX.search(_line) and _ADR_EC_CTX.search(_line)):
            continue
        if RC_EC_PAT.search(_line):
            continue  # covered by the structured pattern
        # Uncovered combined rc+ec context line — always fail.
        # Declaration channel removed (B2-3); uncovered site fails unconditionally.
        _wrong = [_m.group(1) for _m in _NUM.finditer(_line)
                  if _m.group(1) not in (live_rc, live_ec)]
        if _wrong:
            fail("adr-consistency/novel-spelling",
                 f"rc={live_rc} ec={live_ec}",
                 f"uncovered figure(s) {_wrong!r} on line: {_line[:100]!r}")
        else:
            fail("adr-consistency/novel-spelling",
                 "combined rc+ec mention matched by RC_EC_PAT",
                 f"uncovered combined mention on line: {_line[:100]!r}")
    # Per-metric ADR scans (B2-3 fix: P-A, P-A2).
    # The combined scan above requires BOTH 'reason-code' AND 'E-class' on the same
    # line — a standalone 'reason-code' mention with a wrong rc figure (P-A shape)
    # and a standalone 'E-class' mention with a wrong ec figure (P-A2 shape) were
    # never examined.  These per-metric scans close that gap (analogue of the EI
    # per-metric scan on the EI side).
    _ADR_RC_NOVEL_PAT = re.compile(r'\b(\d+)\s+reason-code\b', re.IGNORECASE)
    _ADR_EC_NOVEL_PAT = re.compile(
        r'\b(\d+)\s+E-class(?:\s+code)?\s+occ(?:urrences?)?\b', re.IGNORECASE
    )
    for _adr_live, _adr_metric, _adr_pat in [
        (live_rc, "rc", _ADR_RC_NOVEL_PAT),
        (live_ec, "ec", _ADR_EC_NOVEL_PAT),
    ]:
        for _nm in _adr_pat.finditer(docs):
            if any(_s <= _nm.start() < _e for _s, _e in _adr_covered):
                continue  # within a structured RC_EC_PAT span — already validated
            if _nm.group(1) == _adr_live:
                continue  # correct value
            _site_ctx = docs[max(0, _nm.start()-40):_nm.end()+40].strip()
            # Declaration channel removed (B2-3); uncovered wrong figure always fails.
            fail(f"adr-consistency/novel-spelling/{_adr_metric}",
                 f"{_adr_metric}={_adr_live}",
                 f"uncovered wrong {_adr_metric} figure {_nm.group(1)!r} "
                 f"near: ...{_site_ctx!r}...")

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
    record_comparison("check3-ledger-triple", doc_value=ledger_matches)

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

    record_comparison("check4-ei-figures", doc_value=eim)

    # ── SUGGESTION-10 (Check 4 side): novel-spelling scan for ei figures ──────
    # After all five patterns have run, scan docs_no_prev for any occurrence of
    # a live figure adjacent to an ec-injectivity context keyword that is NOT
    # covered by an existing pattern match span.  Uncovered occurrences fail
    # unconditionally — the declaration channel was removed (B2-3 fix).
    # Historical baseline figures were handled by column filtering (_strip_prev_col)
    # rather than by fragment exemptions; EI_NOVEL_DECLARED has been deleted.
    _EI_CTX = re.compile(
        r'\b(?:citations?\s+(?:compared|with|examined|analyzed)'
        r'|divergen(?:t|ces?)'
        r'|adjudications?'
        r'|injectivity'
        r'|EC\s+citations?)\b',
        re.IGNORECASE,
    )
    # Build covered-spans: character ranges in docs_no_prev covered by any pattern.
    # ev-specific patterns (E) run on ev_no_prev; offset into docs_no_prev.
    # B2-3 fix: docs_no_prev uses pr_no_prev (not pr), so ev starts at
    # len(pr_no_prev)+1, not len(pr)+1.
    _ev_offset = len(pr_no_prev) + 1  # +1 for the "\n" separator
    _ei_covered: list = []
    for _pat in [STANDARD_PAT, BOLD_REV_PAT, TRANSITION_PAT, SINGLE_CMP_PAT]:
        for _pm in _pat.finditer(docs_no_prev):
            _ei_covered.append((_pm.start(), _pm.end()))
    for _pat in [EV_CMP_PAT, EV_DIV_PAT, EV_ADJ_PAT]:
        for _pm in _pat.finditer(ev_no_prev):
            _ei_covered.append((_pm.start() + _ev_offset, _pm.end() + _ev_offset))

    for _fig, _fig_label in [(lcmp, "cmp"), (ldiv, "div"), (ladj, "adj")]:
        for _fm in re.finditer(re.escape(_fig), docs_no_prev):
            _window = docs_no_prev[max(0, _fm.start()-80):_fm.end()+80]
            if not _EI_CTX.search(_window):
                continue  # not figure-adjacent
            if any(_s <= _fm.start() < _e for _s, _e in _ei_covered):
                continue  # already covered by an existing pattern
            _site_ctx = docs_no_prev[max(0, _fm.start()-40):_fm.end()+40].strip()
            # Declaration channel removed (B2-3); uncovered mention always fails.
            fail(f"ec-injectivity/novel-spelling/{_fig_label}",
                 "figure-adjacent occurrence matched by an existing pattern",
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
    # B2-3 fix (P-C, P-C2): expanded per-metric patterns.
    # P-C: old DIV pattern only matched 'N divergent'; 'divergence count came to N'
    #       (context-first form) was never examined.  Add a context-first pattern.
    # P-C2: old CMP pattern only matched 'compared'; 'examined'/'analyzed' synonyms
    #        were never examined.  Expand the alternation.
    # P-D: handled by _strip_prev_col (option 1) — historical figures stripped from
    #       docs_no_prev before scans run; declaration channel deleted entirely.
    _EI_DIV_NOVEL_PAT = re.compile(r'(\d+)\s+diverg(?:ent|ences?)\b', re.IGNORECASE)
    _EI_DIV_CTX_FIRST_PAT = re.compile(
        r'\bdiverg(?:ent|ences?)\b'        # context word (divergent/divergence/s)
        r'(?:\s+\w+){0,4}'                 # 0-4 intervening qualifier words
        r'\s+(?:is|was|were|came\s+to|=|:)\s*'  # linking verb or separator
        r'(\d+)',                           # captured figure (group 1)
        re.IGNORECASE,
    )
    _EI_ADJ_NOVEL_PAT = re.compile(r'(\d+)\s+(?:require\s+)?adjudications?\b',
                                    re.IGNORECASE)
    _EI_CMP_NOVEL_PAT = re.compile(
        r'(\d+)\s+(?:EC\s+)?citations?\s+(?:compared|examined|analyzed)\b',
        re.IGNORECASE,
    )
    _ei_metric_scans = [
        (ldiv, "div", _EI_DIV_NOVEL_PAT),
        (ldiv, "div", _EI_DIV_CTX_FIRST_PAT),   # context-before-number form (P-C)
        (ladj, "adj", _EI_ADJ_NOVEL_PAT),
        (lcmp, "cmp", _EI_CMP_NOVEL_PAT),
    ]
    for _live_val, _fig_label, _novel_pat in _ei_metric_scans:
        for _nm in _novel_pat.finditer(docs_no_prev):
            if any(_s <= _nm.start() < _e for _s, _e in _ei_covered):
                continue  # covered by existing structured pattern
            if _nm.group(1) == _live_val:
                continue  # correct value — existing per-figure scan handles it
            # Wrong integer in metric context, not covered by any structured pattern.
            # Declaration channel removed (B2-3); uncovered wrong figure always fails.
            _site_ctx = docs_no_prev[max(0, _nm.start()-40):_nm.end()+40].strip()
            fail(f"ec-injectivity/novel-spelling/{_fig_label}",
                 f"{_fig_label}={_live_val}",
                 f"uncovered wrong figure {_nm.group(1)!r} near: ...{_site_ctx!r}...")

# ── Check 5: Head SHA ─────────────────────────────────────────────────────────
sha_m = re.search(r"\*\*Head SHA:\*\*\s+([0-9a-f]{40})", pr)
if not sha_m:
    fail("head-sha/pr-description", head[:7], "**Head SHA:** not found in pr-description.md")
else:
    if sha_m.group(1) != head:
        fail("head-sha/pr-description", head, sha_m.group(1))
    record_comparison("check5-head-sha-pr", doc_value=sha_m)

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
        record_comparison("check6-completeness", doc_value=live_e_sites)
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

# _verified_stamp_sha: the stamp SHA that check7 verified against git objects.
# Used by check9 (stamp-equality assertion).  Set to None if check7 is skipped.
_verified_stamp_sha: "str | None" = None

# S2-1 fix: skip ONLY when in test mode AND no throwaway repo was provided.
# When _TEST_STAMP_REPO is set the check runs against that repo instead of
# _SCRIPT_REPO, giving T31 full git-show coverage without touching real history.
if _TEST_MODE and not _TEST_STAMP_REPO:
    # Provenance stamp verification requires the AC files to exist at their
    # captured-at commit in the git history.  In standard test mode the temp
    # directory contains synthetic AC files whose stamps don't match any real
    # commit; skipping avoids false failures.  T31 supplies _TEST_STAMP_REPO
    # so the check runs against a throwaway repo with committed content.
    print("  [provenance-stamps] SKIPPED — test mode (no _VEF_TEST_STAMP_REPO)",
          flush=True)
else:
    # Use the throwaway repo if provided; otherwise the real script repo.
    _stamp_git_cwd = Path(_TEST_STAMP_REPO) if _TEST_STAMP_REPO else _SCRIPT_REPO
    _stamp_shas: set = set()
    for ac_path in STAMPED:
        content = ac_path.read_text()
        stamp_m = re.search(r"Captured at: ([0-9a-f]{40})", content)
        if not stamp_m:
            fail(f"provenance-stamp/{ac_path.name}",
                 "Captured at: <sha> line present",
                 "stamp not found in artifact")
        else:
            stamp    = stamp_m.group(1)
            rel_path = str(ac_path.relative_to(REPO))
            # Run git show directly so we can target _stamp_git_cwd rather than
            # _SCRIPT_REPO (sh() always routes git to _SCRIPT_REPO).
            _r = subprocess.run(
                ["git", "show", f"{stamp}:{rel_path}"],
                capture_output=True, text=True,
                cwd=str(_stamp_git_cwd), timeout=30,
            )
            if _r.returncode != 0:
                fail(f"provenance-stamp/{ac_path.name}",
                     f"git show {stamp[:7]}:{rel_path} exits 0",
                     f"exit {_r.returncode}: {_r.stderr.strip()[:200]}")
            else:
                blob = (_r.stdout + _r.stderr).strip()
                if _normalise_stamp(blob) != _normalise_stamp(content):
                    fail(f"provenance-stamp/{ac_path.name}",
                         "stamp names a commit whose normalised content matches "
                         "current artifact",
                         f"content at {stamp[:7]} differs — artifact was not "
                         f"captured there")
                else:
                    _stamp_shas.add(stamp)
    if len(_stamp_shas) > 1:
        fail("provenance-stamp/inconsistent-shas",
             "all STAMPED artifacts carry the same Captured-at SHA",
             f"found {len(_stamp_shas)} distinct SHAs: "
             f"{sorted(s[:7] for s in _stamp_shas)}")
    elif _stamp_shas:
        _verified_stamp_sha = next(iter(_stamp_shas))

# ── SUGGESTION-2 / check2a-e-cli-001: E-CLI-001 location ─────────────────────
# SUGGESTION-8 fix: register via anchor_check() + fail when anchor absent.
# B-3 fix: record_comparison() called only at comparison point.
# B2-2 fix (ATTACK-A class closure): redesigned as a positive assertion.
#   Before: the inner re.search(..., pr) was conditional — if the PR had no
#   E-CLI-001 at all the body was skipped but record_comparison() was called
#   unconditionally.  This is ATTACK-A: anchor present in live output, no
#   comparison against the document, check registered as passing.
#   After: E-CLI-001 absent from PR is an explicit failure
#   (traceability/e-cli-001-in-pr).  record_comparison(doc_value=_pr_ecli_m)
#   enforces the class invariant structurally: doc_value must be non-None, so
#   a check that found nothing in the document cannot reach a registered state.
_ecli_m = re.search(r"E-CLI-001", adr_out)
if anchor_check("check2a-e-cli-001", _ecli_m,
                "traceability/e-cli-001-in-live",
                "E-CLI-001 detection in live adr-consistency output"):
    _pr_ecli_m = re.search(r"E-CLI-001", pr)
    if not _pr_ecli_m:
        fail("traceability/e-cli-001-in-pr",
             "E-CLI-001 mentioned in pr-description.md "
             "(traceability: detected E-class code must be acknowledged in PR)",
             "E-CLI-001 not found in pr-description.md")
        # record_comparison NOT called: document token absent, no comparison ran.
        # The REQUIRED_CHECKS gate fires as a second signal.
    else:
        if re.search(r"E-CLI-001.*?test-vectors|test-vectors.*?E-CLI-001", pr):
            ecli_live = re.search(r"([\w./-]+\.md:\d+): E-class code 'E-CLI-001'", adr_out)
            live_loc  = Path(ecli_live.group(1)).name if ecli_live \
                        else "BC-2.11.004.md:61 (from live run)"
            fail("traceability/e-cli-001-location",
                 live_loc,
                 "pr-description.md attributes E-CLI-001 ×1 to 'test-vectors'")
        record_comparison("check2a-e-cli-001", doc_value=_pr_ecli_m)

# ── SUGGESTION-4 / check4a-ac002-suffix: AC-002 filename suffix ───────────────
# SUGGESTION-8 fix: register via anchor_check() + fail when AC-002 is absent.
# B-3 fix: absent NofM token in filename is a failure (not a silent pass);
#          record_comparison() called only in the comparison branch, so
#          "file present but no comparison ran" is structurally caught by gate.
_ac002 = next(EV_DIR.glob("AC-002*.txt"), None)
if anchor_check("check4a-ac002-suffix", _ac002,
                "evidence-report/ac002-missing",
                "AC-002*.txt artifact in evidence directory"):
    sfx_m = re.search(r"(\d+of\d+)", _ac002.name)
    if not sfx_m:
        fail("evidence-report/ac002-suffix-unparseable",
             "AC-002 artifact filename carrying an NofM suffix",
             f"{_ac002.name!r} has no NofM token — suffix cross-check cannot run")
        # record_comparison NOT called: REQUIRED_CHECKS gate fires as a
        # structural second signal that the comparison was not completed.
    else:
        correct_sfx = sfx_m.group(1)
        _ev_sfx = list(re.finditer(r"\d+of\d+", ev))
        if not _ev_sfx:
            fail("evidence-report/ac002-suffix-uncited",
                 f"evidence-report.md cites the artifact suffix {correct_sfx}",
                 "no NofM token found in evidence-report.md — nothing compared")
        for m in _ev_sfx:
            if m.group(0) != correct_sfx:
                fail("evidence-report/ac002-suffix", correct_sfx,
                     f"evidence-report.md references '{m.group(0)}'")
                break
        record_comparison("check4a-ac002-suffix", doc_value=sfx_m)

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
    record_comparison("check7-rollback", doc_value=_revert_m)

# ── B-4 / check9: captured-SHA verified against provenance stamps ─────────────
# SUGGESTION-8 fix: register via anchor_check() + fail when anchor absent.
# B2-4 fix (S2-1 closes enabling condition): require **Captured at SHA:** to
# EQUAL the stamp SHA that check7 independently verified against git objects.
# On-branch membership is kept as a necessary condition but is no longer
# sufficient — a wrong-but-on-branch SHA (e.g. 3dc681b while stamps say
# 16b3513) MUST fail.
#
# Design (non-circular):
#   - evidence-report.md says '**Captured at SHA:** X'
#   - X must be on this branch (git rev-list develop..HEAD) — necessary
#   - X must equal the Captured-at SHA that check7 verified via git show
#     for every STAMPED artifact — sufficient and non-circular
#   - check7's stamp SHA is derived from git history, not from this document,
#     so binding check9 to it removes the circularity
#
# Stamp SHA source (priority):
#   1. _verified_stamp_sha — set by check7 when it ran (production or T31).
#   2. _TEST_STAMP_SHA     — test-mode mock; used when check7 was skipped.
#   If neither is available, the equality assertion is not enforced (graceful
#   degradation for test fixtures that do not populate STAMPED files).
_cap_sha_m = re.search(r"\*\*Captured at SHA:\*\*\s+([0-9a-f]{7,40})", ev)
if anchor_check("check9-head-sha-ev", _cap_sha_m,
                "evidence-report/captured-sha-missing",
                "**Captured at SHA:** field in evidence-report.md"):
    _ev_sha7 = _cap_sha_m.group(1)[:7]
    # Necessary: SHA is on this branch.
    if _ev_sha7 not in _branch_sha_set:
        fail("evidence-report/captured-sha-not-on-branch",
             f"SHA {_ev_sha7} in git rev-list develop..HEAD "
             f"({len(_branch_sha_set)} commits: {sorted(_branch_sha_set)})",
             f"SHA {_ev_sha7} not found on this branch — evidence may be "
             f"from a different PR or borrowed from another branch")
    # Sufficient: SHA equals the stamp verified by check7.
    # Priority: check7-verified (_verified_stamp_sha) > test mock (_TEST_STAMP_SHA)
    #
    # Invariant: in production (_TEST_MODE is False), check7 ALWAYS runs.
    # Therefore _verified_stamp_sha is set unless check7 itself recorded a
    # provenance-stamp/* failure.  If we arrive here in production with
    # _expected_stamp_sha7 still None, check7 ran but set _verified_stamp_sha
    # to None without recording a failure — an impossible state that is itself
    # a failure.  We record it explicitly so the sufficiency assertion is never
    # silently absent (D-180, lesson: "graceful degradation" is the euphemism
    # that produced five consecutive fail-open rounds).
    #
    # In test mode, _TEST_STAMP_SHA is the mock; if neither source is set, the
    # caller deliberately omitted stamp coverage (T01-T29 do not populate
    # STAMPED, and that is by design — they test other checks).
    _expected_stamp_sha7: "str | None" = None
    if _verified_stamp_sha:
        _expected_stamp_sha7 = _verified_stamp_sha[:7]
    elif _TEST_STAMP_SHA:
        _expected_stamp_sha7 = _TEST_STAMP_SHA[:7]
    if not _TEST_MODE and _expected_stamp_sha7 is None:
        fail("evidence-report/stamp-sha-unavailable",
             "a verified stamp SHA from check7 (production runs always execute check7)",
             "no verified stamp SHA available — check7 must have failed or been "
             "bypassed; audit the provenance-stamp/* failures above")
    if _expected_stamp_sha7 is not None and _ev_sha7 != _expected_stamp_sha7:
        fail("evidence-report/captured-sha-stamp-mismatch",
             f"**Captured at SHA:** {_expected_stamp_sha7} "
             f"(consistent with provenance stamps verified by check7)",
             f"**Captured at SHA:** {_ev_sha7} — does not match stamp "
             f"{_expected_stamp_sha7} (on-branch is necessary but not sufficient)")
    record_comparison("check9-head-sha-ev", doc_value=_cap_sha_m)

# ── Check 8: Live PR body must match pr-description.md (FINDING 2) ────────────
# B2-1 fix: Check 8 requires gh API authentication (GH_TOKEN).  When running
# in CI without a token (operator's deliberate design: checks 1-7,9 run; check
# 8 SKIPS loudly), or when gh returns an auth error, this check is recorded to
# checks_skipped — not a failure, not a pass.  A run with any loud-skips exits
# 5 (PARTIAL).  The output explicitly names the skipped check and the reason,
# so a log reader can tell which checks ran and which did not (D-039, lesson-61).
#
# Loud-skip criteria: gh returns non-zero AND _is_auth_error(stderr) is True.
# Any other gh failure is recorded as an ordinary fail.
# Test-mode: _VEF_TEST_GH_BODY_<N>, _VEF_TEST_GH_BODY — mock body (unchanged).
#            _VEF_TEST_CHECK8_AUTH_FAIL=1 — simulate auth failure for check 8.
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
elif _TEST_CHECK8_AUTH_FAIL:
    # Test-mode: simulate gh auth failure for check 8.
    _live_pr_body_raw = None
    print("\nCHECK 8 SKIP — gh authentication unavailable "
          "(simulated by _VEF_TEST_CHECK8_AUTH_FAIL).", flush=True)
    print("  check8-live-pr-body requires GH_TOKEN; skipping loudly.", flush=True)
    checks_skipped.add("check8-live-pr-body")
else:
    _live_pr_body_raw = None
    try:
        _gh8_r = subprocess.run(
            ["gh", "pr", "view", str(pr_number),
             "--json", "body", "--jq", ".body"],
            capture_output=True, text=True, cwd=str(_SCRIPT_REPO), timeout=30,
        )
        if _gh8_r.returncode == 0:
            _live_pr_body_raw = _gh8_r.stdout.strip()
        elif _is_auth_error(_gh8_r.stderr):
            # Auth failure: skip loudly.  This is NOT a FAIL and NOT a PASS.
            # D-039: skip is enumerated in output; cannot be mistaken for a pass.
            print("\nCHECK 8 SKIP — gh API authentication not available.", flush=True)
            print("  check8-live-pr-body requires GH_TOKEN to fetch the live "
                  "PR body; skipping loudly.", flush=True)
            print(f"  (gh said: {_gh8_r.stderr.strip()[:200]})", flush=True)
            checks_skipped.add("check8-live-pr-body")
        else:
            fail("live-pr-body/gh-error",
                 "gh pr view exit 0",
                 f"gh exited {_gh8_r.returncode}: "
                 f"{_gh8_r.stderr.strip()[:120]}")
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
    record_comparison("check8-live-pr-body", doc_value=_live_pr_body_raw)

# ── BLOCKING-D: required-checks gate ─────────────────────────────────────────
# B-3: checks_ran is populated exclusively by record_comparison(key) calls.
# A missing key means record_comparison() was never called on the comparison
# path — either anchor absent (per-site fail already recorded above) or
# comparison body bypassed (structural gap caught here).
# B2-1 fix: checks_skipped are intentionally not run (loud skip, not pass).
# Excluded from the gate so they do not trigger a double-failure.
# Any check that is neither in checks_ran NOR in checks_skipped fires the gate.
missing_checks = REQUIRED_CHECKS - checks_ran - checks_skipped
for key in sorted(missing_checks):
    fail(f"required-check/{key}",
         "record_comparison(key) called on the comparison code path",
         "comparison never registered — check body may have been bypassed")

# ── Final report ──────────────────────────────────────────────────────────────
if fails:
    print(f"\nFAIL — {len(fails)} check(s) failed:\n")
    for f in fails:
        print(f)
    sys.exit(1)
if checks_skipped:
    # exit 5: PARTIAL — all runnable checks passed but at least one was
    # loudly skipped due to environment constraints.  This is NOT a full pass.
    print(f"\nPARTIAL — {len(checks_skipped)} check(s) skipped (not a full pass):")
    for _sk in sorted(checks_skipped):
        print(f"  SKIP  {_sk} — gh API authentication not available")
    print("  All other checks passed.  Run with GH_TOKEN to perform a full check.")
    sys.exit(5)
print("\nPASS — all figure checks match live output and git state")
