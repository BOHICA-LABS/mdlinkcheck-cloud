#!/usr/bin/env python3
"""Verify documentation figures in CHECKER-COMPLETENESS-GATE35 artifacts.

Derives expected values from live tool runs and git state — never from the
documents being checked. Exit non-zero with per-mismatch report on failure.

Usage:  python3 scripts/verify-evidence-figures.py

Structural guarantee (BLOCKING-D):
  Every check that performs a live-vs-document comparison MUST register itself
  in `checks_ran`.  The PASS gate asserts REQUIRED_CHECKS == checks_ran, so a
  future check added without an else-fail AND without the registry call still
  cannot produce a false PASS.
"""
import re, subprocess, sys
from pathlib import Path

REPO    = Path(__file__).resolve().parent.parent
PR_DESC = REPO / ".factory/code-delivery/CHECKER-COMPLETENESS-GATE35/pr-description.md"
EV_RPT  = REPO / "docs/demo-evidence/CHECKER-COMPLETENESS-GATE35/evidence-report.md"
EV_DIR  = REPO / "docs/demo-evidence/CHECKER-COMPLETENESS-GATE35"
STAMPED = [
    EV_DIR / "AC-001-preflight.txt",
    EV_DIR / "AC-005-adr-consistency-live.txt",
    EV_DIR / "AC-006-ec-injectivity-live.txt",
]

# ── Required-checks registry (BLOCKING-D structural guarantee) ────────────────
# Every check listed here MUST call checks_ran.add(key) after performing at
# least one live-vs-document comparison.  The PASS gate at the bottom asserts
# this set is fully populated.  A future check that forgets the else-branch AND
# the registry call will still be caught here.
REQUIRED_CHECKS = {
    "check2-adr-figures",
    "check3-ledger-triple",
    "check4-ei-figures",
    "check6-completeness",
    "check8-live-pr-body",
}
checks_ran: set = set()

fails = []

def fail(label, expected, got):
    fails.append(f"  [{label}]\n    expected : {expected}\n    got      : {got}")

# Allowed return codes per command (keyed on cmd[-1]).
# Default {0, 1}: checkers exit 0 (clean) or 1 (violations found).
# Anything else signals a crash — surface it as a failure.
ALLOWED_RC: dict = {}

def sh(*cmd, timeout=180, allowed_rc=None):
    r = subprocess.run(cmd, capture_output=True, text=True, cwd=REPO, timeout=timeout)
    allowed = allowed_rc if allowed_rc is not None else ALLOWED_RC.get(cmd[-1], {0, 1})
    if r.returncode not in allowed:
        fail(f"live-run/{cmd[-1]!r}",
             f"exit code in {allowed}",
             f"exit {r.returncode}")
    # Return merged stdout+stderr: the RC check above catches crashes; the
    # merged output gives maximum context for diagnostics.
    return (r.stdout + r.stderr).strip()

# ── Derive expected values from live runs (independent probes) ────────────────
print("Running selftest suite (~65 s) …", flush=True)
st_out  = sh("bash", "scripts/spec-lint/selftest/run-selftests.sh")
print("Running check-adr-consistency …", flush=True)
adr_out = sh("python3", "scripts/spec-lint/check-adr-consistency.py")
print("Running check-ec-injectivity …", flush=True)
ei_out  = sh("python3", "scripts/spec-lint/check-ec-injectivity.py")
head             = sh("git", "rev-parse", "HEAD")
n_branch_commits = len(sh("git", "log", "--format=%h", "develop..HEAD").splitlines())

pr  = PR_DESC.read_text()
ev  = EV_RPT.read_text()
# Combined corpus for multi-occurrence checks (S-5).
# ev_no_prev strips the "Previous (post-gate34):" baseline line so historical
# ec-injectivity figures (9/5/110) from that line do not cause false failures
# when scanning for the current figures (42/22/174).
ev_no_prev   = "\n".join(l for l in ev.splitlines() if "Previous" not in l)
docs         = pr + "\n" + ev            # used for Check 2 (no historical rc/ec figures in ev)
docs_no_prev = pr + "\n" + ev_no_prev   # used for Check 4 (has historical ec-injectivity figures)

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

# ── Check 3: E-class ledger triple + invariant ────────────────────────────────
# BLOCKING-D fix: else-branch required; unparseable ledger line is a failure.
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
    # PR body may use abbreviated "pop=" or full "population="
    dm = re.search(r"pop(?:ulation)?=(\d+), examined=(\d+), skipped=(\d+)", pr)
    if not dm:
        fail("e-class-ledger/pr-claim", f"pop={lpop} exam={lexam} skip={lskip}",
             "not found in pr-description.md")
    else:
        if dm.group(1) != lpop:  fail("e-class-ledger/population", lpop,  dm.group(1))
        if dm.group(2) != lexam: fail("e-class-ledger/examined",   lexam, dm.group(2))
        if dm.group(3) != lskip: fail("e-class-ledger/skipped",    lskip, dm.group(3))
    checks_ran.add("check3-ledger-triple")

# ── Check 4: check-ec-injectivity figures (ALL occurrences — S-5 complete) ────
# BLOCKING-D fix: else-branch required; unparseable summary is a failure.
# S-5 fix (complete): multiple patterns anchored on figure keywords ("citations
# compared/with", "divergent", "adjudication") catch all restatement forms:
#
#   STANDARD_TRIPLE  — "N citations compared/with … M divergent … P adjudication"
#                       in docs_no_prev (pr + ev minus "Previous" baseline line)
#   BOLD_REV_TRIPLE  — "**M DIVERGENT + P ADJUDICATION; N of K TV rows compared**"
#                       (pr:207 bold current-state column; excludes non-bold old column)
#   TRANSITION_TRIPLE — "→N ec-injectivity comparisons; →M divergent; →P adjudication"
#                        (pr:381 transition arrows — no spaces around →)
#   SINGLE_CMP       — "compares N of K citations" narrative form (pr:24, cmp only)
#   EV_CMP/DIV/ADJ   — individual figure patterns in evidence-report (ev_no_prev)
#                       for mentions that lack a co-located triple
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
    # Bold marker excludes the adjacent non-bold old-value column (9 DIVERGENT + 5 ADJUDICATION).
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
    # Uses → without surrounding spaces to distinguish from " → " (space-arrow-space)
    # used in table rows that are already caught by STANDARD_PAT.
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
    # ev:17 has "174 citations compared; 42 divergent" (no adjudication on that line).
    # ev:25 has "42 divergent, 22 adjudication" (no citations on that line).
    # ev:37 has all three and is also caught by STANDARD_PAT (intentional double-check).
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

# ── Check 5: Head SHA ─────────────────────────────────────────────────────────
sha_m = re.search(r"\*\*Head SHA:\*\*\s+([0-9a-f]{40})", pr)
if not sha_m:
    fail("head-sha/pr-description", head[:7], "**Head SHA:** not found in pr-description.md")
elif sha_m.group(1) != head:
    fail("head-sha/pr-description", head, sha_m.group(1))

# ── Check 6: Enumerated-site consistency (BLOCKING-B) ────────────────────────
# Find block: "N E-class occurrences validated ... Detection confirmed at: <sites sentence>"
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
    # Isolate the validated-sites sentence: ends at the first period that is
    # followed by a newline or space+capital (excludes periods inside filenames).
    sent_m = re.search(r"\.\s*(?:\n|(?=[A-Z]))", block)
    if sent_m:
        val_text  = block[:sent_m.start() + 1]   # include the terminating period
        excl_text = block[sent_m.end():]
    else:
        val_text, excl_text = block, ""
    # Expand comma-separated file:line refs in validated text
    val_sites = []
    for m in re.finditer(r"`([\w./-]+\.md):(\d+(?:,\d+)*)`", val_text):
        for ln in m.group(2).split(","):
            val_sites.append(f"{m.group(1)}:{ln.strip()}")
    # Count check
    if len(val_sites) != claimed_n:
        fail("enumerated-sites/count",
             f"{claimed_n} sites for claimed {claimed_n} validated occurrences",
             f"{len(val_sites)} sites found: {val_sites}")
    # Completeness: every live E-class detection site must appear in val_sites.
    # BLOCKING-D fix: an empty live_e_sites set means the completeness loop never
    # runs — that is a failure, not a vacuous pass.
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
    # Bucket-overlap: no site should appear in both validated enumeration and excluded text
    for m in re.finditer(r"`([\w./-]+\.md):(\d+(?:,\d+)*)`", excl_text):
        for ln in m.group(2).split(","):
            site = f"{m.group(1)}:{ln.strip()}"
            if site in val_sites:
                fail("enumerated-sites/bucket-overlap",
                     f"{site} in exactly one bucket",
                     f"{site} appears in both validated and excluded parts")

# ── Check 7: Provenance stamps — content-obtainable-at-SHA (BLOCKING-E) ───────
# BLOCKING-E fix: replaced git-log presence check with git-show content
# comparison.  A stamp is valid only if the artifact's content at that commit,
# normalised to remove the stamp line itself, matches the current normalised
# content.  This rejects a stamp that names any commit where the figures differed
# (e.g. 879efff, where AC-005 recorded "79 reason-code + 5 E-class" instead of
# "78 + 6") while still accepting a stamp-correction commit (the commit that only
# changed the stamp line compares equal after normalisation).

def _normalise_stamp(text: str) -> str:
    """Strip 'Captured at: <sha>' lines and outer blank lines for comparison.

    The outer strip() reconciles the asymmetry between sh() (which always
    strips the captured output) and read_text() (which preserves leading
    newlines that some artifacts have).  Internal blank lines are preserved
    so any middle-of-file divergence is still caught.
    """
    filtered = "\n".join(
        line for line in text.splitlines()
        if not re.match(r"Captured at: [0-9a-f]{40}\s*$", line)
    )
    return filtered.strip()

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
        # sh() calls fail() if git show exits unexpectedly (RC not in {0,1}).
        # RC=128 means the SHA or path did not exist — that is itself a failure.
        blob = sh("git", "show", f"{stamp}:{rel_path}")
        if _normalise_stamp(blob) != _normalise_stamp(content):
            fail(f"provenance-stamp/{ac_path.name}",
                 f"stamp names a commit whose normalised content matches current artifact",
                 f"content at {stamp[:7]} differs — artifact was not captured there")

# ── SUGGESTION-2: E-CLI-001 location in traceability must be file:line ────────
if re.search(r"E-CLI-001.*?test-vectors|test-vectors.*?E-CLI-001", pr):
    ecli_live = re.search(r"([\w./-]+\.md:\d+): E-class code 'E-CLI-001'", adr_out)
    live_loc  = Path(ecli_live.group(1)).name if ecli_live else "BC-2.11.004.md:61 (from live run)"
    fail("traceability/e-cli-001-location",
         live_loc,
         "pr-description.md attributes E-CLI-001 ×1 to 'test-vectors'")

# ── SUGGESTION-4: evidence-report AC-002 filename suffix must be current ───────
ac002 = next(EV_DIR.glob("AC-002*.txt"), None)
if ac002:
    sfx_m = re.search(r"(\d+of\d+)", ac002.name)
    if sfx_m:
        correct_sfx = sfx_m.group(1)          # e.g. "99of99"
        for m in re.finditer(r"\d+of\d+", ev):
            if m.group(0) != correct_sfx:
                fail("evidence-report/ac002-suffix",
                     correct_sfx,
                     f"evidence-report.md references '{m.group(0)}'")
                break

# ── NIT-C / S-7: rollback command must be complete and internally consistent ───
# S-7 fix: the claimed commit count and the listed SHA count are both checked
# against the LIVE `git rev-list --count develop..HEAD` (n_branch_commits),
# not against each other.  Internal consistency checking disguised the bug where
# both numbers were wrong by the same amount.
revert_m = re.search(r"git revert((?:\s+[0-9a-f]{7,40})+)", pr)
if revert_m:
    listed = revert_m.group(1).split()
    # The evidence-rename commit omitted in the prior pass must be present
    if not any(s == "39efec2" or "39efec2".startswith(s) for s in listed):
        fail("rollback/missing-39efec2",
             "39efec2 in rollback list",
             "39efec2 missing from git revert command")
    # Claimed prose count must equal live branch-commit count
    count_m = re.search(r"Rollback reverts all (\d+) commits", pr)
    if count_m:
        claimed = int(count_m.group(1))
        if claimed != n_branch_commits:
            fail("rollback/count-claim",
                 f"body claims {claimed} commits; git rev-list --count develop..HEAD = {n_branch_commits}",
                 "counts disagree")
    # Listed SHA count must also equal live branch-commit count
    if len(listed) != n_branch_commits:
        fail("rollback/sha-count",
             f"rollback SHA list has {len(listed)} entries; "
             f"git rev-list --count develop..HEAD = {n_branch_commits}",
             "counts disagree")

# ── NIT-D: "Head SHA:" in evidence-report must equal git HEAD or be relabeled ──
head_sha_m = re.search(r"\*\*Head SHA:\*\*\s+([0-9a-f]{7,40})", ev)
if head_sha_m and not head.startswith(head_sha_m.group(1)):
    fail("evidence-report/head-sha-label",
         f"field renamed to '**Captured at SHA:**' (value {head_sha_m.group(1)} ≠ HEAD {head[:7]})",
         "field still labeled '**Head SHA:**' with non-HEAD value")

# ── Check 8: Live PR body must match pr-description.md (FINDING 2) ────────────
# Fail closed (D-039): gh unavailable or non-zero exit is treated as a failure,
# never as a skip.  allowed_rc={0} — only success is acceptable.
# Normalisation: strip trailing whitespace from each line and overall so that
# GitHub's trailing-newline handling doesn't produce a spurious mismatch.
def _norm_body(t: str) -> str:
    return "\n".join(l.rstrip() for l in t.splitlines()).strip()

print("Fetching live PR body via gh …", flush=True)
live_pr_body = sh("gh", "pr", "view", "12", "--json", "body", "--jq", ".body",
                  allowed_rc={0})
if _norm_body(live_pr_body) != _norm_body(pr):
    fail("live-pr-body/sync",
         "live PR body matches pr-description.md (normalised)",
         "live PR body has diverged from pr-description.md — "
         "run: gh pr edit 12 --body-file .factory/code-delivery/"
         "CHECKER-COMPLETENESS-GATE35/pr-description.md")
checks_ran.add("check8-live-pr-body")

# ── BLOCKING-D: required-checks gate ─────────────────────────────────────────
# Every check in REQUIRED_CHECKS must have registered itself.  If any is absent
# the check either never ran (live output unparseable) or was added without a
# proper else-branch.  This is the structural guarantee that PASS requires
# evidence, not just silence.
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
