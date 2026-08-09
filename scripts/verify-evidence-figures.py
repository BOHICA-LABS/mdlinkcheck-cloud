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
}
checks_ran: set = set()

fails = []

def fail(label, expected, got):
    fails.append(f"  [{label}]\n    expected : {expected}\n    got      : {got}")

# Allowed return codes per command (keyed on cmd[-1]).
# Default {0, 1}: checkers exit 0 (clean) or 1 (violations found).
# Anything else signals a crash — surface it as a failure.
ALLOWED_RC: dict = {}

def sh(*cmd, timeout=180):
    r = subprocess.run(cmd, capture_output=True, text=True, cwd=REPO, timeout=timeout)
    allowed = ALLOWED_RC.get(cmd[-1], {0, 1})
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
# Combined corpus for multi-occurrence checks (S-5)
docs = pr + "\n" + ev

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
# S-5 fix: re.finditer checks EVERY restatement of the figure across pr + ev.
am = re.search(r"(\d+) violations found \((\d+) reason-code occurrences \+ (\d+) E-class code",
               adr_out)
if not am:
    fail("adr-consistency/live",
         "violations-found summary line",
         "not parseable from live output")
else:
    live_rc, live_ec = am.group(2), am.group(3)
    rc_matches = list(re.finditer(
        r"(\d+) reason-code \+ (\d+) E-class (?:code )?occurrences", docs))
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

# ── Check 4: check-ec-injectivity figures (ALL occurrences — S-5) ─────────────
# BLOCKING-D fix: else-branch required; unparseable summary is a failure.
# S-5 fix: re.finditer checks EVERY restatement of the figure across pr.
# Note: we scan `pr` only (not `docs`/ev) because the evidence-report contains
# an intentional "Previous (post-gate34): 110 citations compared ... 9 divergent
# ... 5 adjudication" line whose old figures must not trigger a false failure.
eim = re.search(r"(\d+) EC citations compared.*?(\d+) divergent, (\d+) require adjudication",
                ei_out)
if not eim:
    fail("ec-injectivity/live",
         "EC citations compared summary line",
         "not parseable from live output")
else:
    lcmp, ldiv, ladj = eim.group(1), eim.group(2), eim.group(3)
    ei_matches = list(re.finditer(
        r"(\d+) citations compared.*?(\d+) divergent.*?(\d+) adjudication", pr))
    if not ei_matches:
        fail("ec-injectivity/pr-claim",
             f"{lcmp}/{ldiv}/{ladj}",
             "not found in pr-description.md or evidence-report.md")
    else:
        print(f"    ec-injectivity figures: {len(ei_matches)} occurrence(s) compared",
              flush=True)
        for idx, m in enumerate(ei_matches, 1):
            if m.group(1) != lcmp:
                fail(f"ec-injectivity/citations[{idx}/{len(ei_matches)}]",    lcmp, m.group(1))
            if m.group(2) != ldiv:
                fail(f"ec-injectivity/divergent[{idx}/{len(ei_matches)}]",    ldiv, m.group(2))
            if m.group(3) != ladj:
                fail(f"ec-injectivity/adjudication[{idx}/{len(ei_matches)}]", ladj, m.group(3))
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
