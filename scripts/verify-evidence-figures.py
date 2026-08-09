#!/usr/bin/env python3
"""Verify documentation figures in CHECKER-COMPLETENESS-GATE35 artifacts.

Derives expected values from live tool runs and git state — never from the
documents being checked. Exit non-zero with per-mismatch report on failure.

Usage:  python3 scripts/verify-evidence-figures.py
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

fails = []

def fail(label, expected, got):
    fails.append(f"  [{label}]\n    expected : {expected}\n    got      : {got}")

def sh(*cmd, timeout=180):
    r = subprocess.run(cmd, capture_output=True, text=True, cwd=REPO, timeout=timeout)
    return (r.stdout + r.stderr).strip()

# ── Derive expected values from live runs (independent probes) ────────────────
print("Running selftest suite (~65 s) …", flush=True)
st_out  = sh("bash", "scripts/spec-lint/selftest/run-selftests.sh")
print("Running check-adr-consistency …", flush=True)
adr_out = sh("python3", "scripts/spec-lint/check-adr-consistency.py")
print("Running check-ec-injectivity …", flush=True)
ei_out  = sh("python3", "scripts/spec-lint/check-ec-injectivity.py")
head              = sh("git", "rev-parse", "HEAD")
n_branch_commits  = len(sh("git", "log", "--format=%h", "develop..HEAD").splitlines())

pr  = PR_DESC.read_text()
ev  = EV_RPT.read_text()

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

# ── Check 2: check-adr-consistency figures ────────────────────────────────────
am = re.search(r"(\d+) violations found \((\d+) reason-code occurrences \+ (\d+) E-class code", adr_out)
if am:
    live_rc, live_ec = am.group(2), am.group(3)
    pm = re.search(r"(\d+) reason-code \+ (\d+) E-class (?:code )?occurrences validated", pr)
    if not pm:
        fail("adr-consistency/pr-claim", f"rc={live_rc} ec={live_ec}", "pattern not found in pr-description.md")
    else:
        if pm.group(1) != live_rc: fail("adr-consistency/reason-code", live_rc, pm.group(1))
        if pm.group(2) != live_ec: fail("adr-consistency/e-class",     live_ec, pm.group(2))

# ── Check 3: E-class ledger triple + invariant ────────────────────────────────
pop_m = re.search(r"population=(\d+), examined=(\d+), skipped=(\d+)", adr_out)
if pop_m:
    lpop, lexam, lskip = pop_m.group(1), pop_m.group(2), pop_m.group(3)
    if int(lpop) != int(lexam) + int(lskip):
        fail("e-class-ledger/invariant", f"{lpop}=={lexam}+{lskip}", str(int(lexam) + int(lskip)))
    # PR body may use abbreviated "pop=" or full "population="
    dm = re.search(r"pop(?:ulation)?=(\d+), examined=(\d+), skipped=(\d+)", pr)
    if not dm:
        fail("e-class-ledger/pr-claim", f"pop={lpop} exam={lexam} skip={lskip}",
             "not found in pr-description.md")
    else:
        if dm.group(1) != lpop:  fail("e-class-ledger/population", lpop,  dm.group(1))
        if dm.group(2) != lexam: fail("e-class-ledger/examined",   lexam, dm.group(2))
        if dm.group(3) != lskip: fail("e-class-ledger/skipped",    lskip, dm.group(3))

# ── Check 4: check-ec-injectivity figures ─────────────────────────────────────
eim = re.search(r"(\d+) EC citations compared.*?(\d+) divergent, (\d+) require adjudication", ei_out)
if eim:
    lcmp, ldiv, ladj = eim.group(1), eim.group(2), eim.group(3)
    epm = re.search(r"(\d+) citations compared.*?(\d+) divergent.*?(\d+) adjudication", pr)
    if not epm:
        fail("ec-injectivity/pr-claim", f"{lcmp}/{ldiv}/{ladj}", "not found in pr-description.md")
    else:
        if epm.group(1) != lcmp: fail("ec-injectivity/citations",    lcmp, epm.group(1))
        if epm.group(2) != ldiv: fail("ec-injectivity/divergent",    ldiv, epm.group(2))
        if epm.group(3) != ladj: fail("ec-injectivity/adjudication", ladj, epm.group(3))

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
    # Completeness: every live E-class detection site must appear in val_sites
    live_e_sites = re.findall(r"([\w./-]+\.md):(\d+): E-class code", adr_out)
    for fpath, ln in live_e_sites:
        bname = f"{Path(fpath).name}:{ln}"
        if not any(f"{Path(s.split(':')[0]).name}:{s.rsplit(':', 1)[-1]}" == bname
                   for s in val_sites):
            fail("enumerated-sites/completeness",
                 f"{bname} present in validated enumeration",
                 f"{bname} missing from 'Detection confirmed at:' list")
    # Bucket-overlap: no site should appear in both validated enumeration and excluded text
    for m in re.finditer(r"`([\w./-]+\.md):(\d+(?:,\d+)*)`", excl_text):
        for ln in m.group(2).split(","):
            site = f"{m.group(1)}:{ln.strip()}"
            if site in val_sites:
                fail("enumerated-sites/bucket-overlap",
                     f"{site} in exactly one bucket",
                     f"{site} appears in both validated and excluded parts")

# ── Check 7: Provenance stamps (BLOCKING-C) ───────────────────────────────────
# A stamp is valid if it names any commit that has ever touched the artifact file.
# Using the full git log (not just -1) means this stays correct after a stamp-correction
# commit: the correction commit appears in the log alongside the original capture commit.
for ac_path in STAMPED:
    content  = ac_path.read_text()
    stamp_m  = re.search(r"Captured at: ([0-9a-f]{40})", content)
    file_log = sh("git", "log", "--format=%H", "--", str(ac_path)).splitlines()
    if not stamp_m:
        fail(f"provenance-stamp/{ac_path.name}",
             "Captured at: <sha> line present",
             "stamp not found in artifact")
    elif stamp_m.group(1) not in file_log:
        # Report the most recent real commit for orientation
        recent = file_log[0][:7] if file_log else "none"
        fail(f"provenance-stamp/{ac_path.name}",
             f"stamp commit in file history (recent={recent})",
             f"stamp={stamp_m.group(1)[:7]} not in git log for this file")

# ── SUGGESTION-2: E-CLI-001 location in traceability must be file:line ─────────
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

# ── NIT-C: rollback command must include 39efec2 and internal count must match ─
# (The rollback need not include documentation-only fix commits made after 39efec2;
#  checking branch-commit count would create a bootstrapping problem each patch cycle.)
revert_m = re.search(r"git revert((?:\s+[0-9a-f]{7,40})+)", pr)
if revert_m:
    listed = revert_m.group(1).split()
    # The evidence-rename commit omitted in the prior pass must now be present
    if not any(s == "39efec2" or "39efec2".startswith(s) for s in listed):
        fail("rollback/missing-39efec2",
             "39efec2 in rollback list",
             "39efec2 missing from git revert command")
    # Internal consistency: claimed count in body text must match listed SHAs
    count_m = re.search(r"Rollback reverts all (\d+) commits", pr)
    if count_m and int(count_m.group(1)) != len(listed):
        fail("rollback/count-claim",
             f"body claims {count_m.group(1)} commits, list has {len(listed)}",
             f"counts disagree")

# ── NIT-D: "Head SHA:" in evidence-report must equal git HEAD or be relabeled ──
head_sha_m = re.search(r"\*\*Head SHA:\*\*\s+([0-9a-f]{7,40})", ev)
if head_sha_m and not head.startswith(head_sha_m.group(1)):
    fail("evidence-report/head-sha-label",
         f"field renamed to '**Captured at SHA:**' (value {head_sha_m.group(1)} ≠ HEAD {head[:7]})",
         "field still labeled '**Head SHA:**' with non-HEAD value")

# ── Final report ──────────────────────────────────────────────────────────────
if fails:
    print(f"\nFAIL — {len(fails)} check(s) failed:\n")
    for f in fails:
        print(f)
    sys.exit(1)
print("\nPASS — all figure checks match live output and git state")
