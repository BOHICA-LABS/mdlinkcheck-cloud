#!/usr/bin/env python3
"""
check-holdout-boundary — POL-18
================================
No visible artifact may contain the full scenario specification (input + expected
output) for a reserved holdout EC ID.

Active holdout pool is read from prd.md §5b (the canonical list) — NOT hardcoded.

Rules:
  - A bare mention of a holdout EC ID (e.g. "EC-079 was removed") is PERMITTED.
  - A FULL scenario row in a table (concrete input + expected verdict + exit code)
    for a holdout-reserved ID is a VIOLATION.
  - A FULL scenario in PROSE (arrow indicator + verdict word on same line as holdout
    EC ID, e.g. "EC-151 ... input → broken") is a VIOLATION (BI-049 repair).
  - Sub-lettered aliases (EC-079b, EC-094a, EC-141b) whose BASE ID is a holdout
    ARE violations when they appear in visible artifact edge-case tables with concrete
    inputs and expected outputs (finding P3-021).

Visible artifacts scoped:
  .factory/specs/prd.md (excluding §5b holdout declaration itself)
  .factory/specs/behavioral-contracts/**
  .factory/specs/prd-supplements/** (but NOT test-vectors.md holdout WARNING block)
  .factory/specs/domain-spec/**

Holdout-only artifacts (NOT checked):
  .factory/holdout-scenarios/**

Exit 1 if any violation found.

POSITIVE-COVERAGE (D-057 / POLICY 11): emits on every run:
  "N reserved holdout EC IDs checked across M files, K non-conforming"
"""
import re
import sys
from pathlib import Path
import spec_lint_primitives as slp

REPO = slp.find_repo_root(start=Path(__file__).resolve().parent)  # honors SPEC_LINT_REPO_OVERRIDE
SPECS = REPO / ".factory" / "specs"
FACTORY = REPO / ".factory"
PRD = SPECS / "prd.md"
HS_INDEX = FACTORY / "holdout-scenarios" / "HS-INDEX.md"


def parse_active_holdout_ec_ids() -> set[str]:
    """
    Read the active holdout pool from prd.md §5b.
    Returns bare EC IDs (e.g. 'EC-079', not 'EC-079b').
    """
    holdout_ids: set[str] = set()
    if not PRD.exists():
        return holdout_ids

    text = PRD.read_text(encoding="utf-8")
    # The canonical holdout list is declared in the bold sentence in §5b:
    # "Holdout vectors **(EC-079, EC-093, ...)**"
    m = re.search(r"Holdout vectors\s+\*\*\(([^)]+)\)\*\*", text)
    if m:
        raw = m.group(1)
        # BI-044: use shared EC grammar (EC_TOKEN_RE) instead of digits-only r"EC-(\d+)"
        for ec_m in slp.EC_TOKEN_RE.finditer(raw):
            holdout_ids.add(f"EC-{ec_m.group(1)}")

    # Also cross-check HS-INDEX for active entries
    if HS_INDEX.exists():
        for line in slp.cm_splitlines(HS_INDEX.read_text(encoding="utf-8")):
            # Active rows (not struck-through)
            if "~~" not in line:
                # BI-044: use split_table_cells + EC_TOKEN_RE instead of digits-only search
                cells = slp.split_table_cells(line)
                for c in cells:
                    ec_m = slp.EC_TOKEN_RE.fullmatch(c)
                    if ec_m:
                        holdout_ids.add(f"EC-{ec_m.group(1)}")
                        break

    return holdout_ids


def is_concrete_scenario_row(line: str, ec_id: str) -> bool:
    """
    Determine if a table row containing ec_id has concrete scenario details.
    A row is concrete if it has:
      - An expected verdict (alive/broken/indeterminate/clean)
      - OR an expected exit code (0, 1, 2)
    in addition to an EC ID.
    """
    verdict_pattern = re.compile(
        r"\b(alive|broken|indeterminate|clean|exit\s+code\s+[012]|exit\s+[012]|exit-[012])\b"
        r"|\b(dns-failure|tls-error|file-not-found|connection-timeout|cert-error|redirect-loop"
        r"|too-many-redirects|blocked-by-robots|http-error|private-ip|malformed-url"
        r"|scheme-not-supported|io-error)\b"
        r"|\breason[-:]",
        re.IGNORECASE,
    )
    return bool(verdict_pattern.search(line))


def is_concrete_scenario_prose(line: str) -> bool:
    """
    Determine if a non-table prose/bullet/code-fence line expresses a concrete
    scenario specification for a holdout EC ID.

    Requires BOTH of:
      1. A scenario-arrow indicator (→, ->, =>) — present in "input → expected-output"
         narrative constructions.
      2. A verdict or exit-code word that names the expected output.

    This two-part predicate is characteristic of prose scenario descriptions and
    differs meaningfully from mere discussion (e.g. "EC-079 was removed" has no
    arrow; "links that break → various outcomes" has no specific EC ID and would
    not be checked here anyway).  The combination avoids flagging bare narrative
    mentions of holdout IDs while catching the exact breach pattern documented in
    adversary findings P7-S8-004 / P7-S8-005 (BI-049).
    """
    # Part 1: scenario arrow (input→output mapping indicator)
    has_arrow = bool(re.search(r'→|->|=>', line))
    if not has_arrow:
        return False
    # Part 2: verdict or exit-code word (the expected-output side)
    verdict_pattern = re.compile(
        r"\b(alive|broken|indeterminate|clean|exit\s+code\s+[012]|exit\s+[012]|exit-[012])\b",
        re.IGNORECASE,
    )
    return bool(verdict_pattern.search(line))


def should_check_file(path: Path) -> bool:
    s = str(path)
    # Skip holdout-scenarios directory (those are allowed to contain scenario details)
    if "holdout-scenarios" in s:
        return False
    # Skip cycle logs and planning
    if "/.factory/cycles/" in s or "/.factory/planning/" in s:
        return False
    return True


def main() -> int:
    holdout_ids = parse_active_holdout_ec_ids()
    if not holdout_ids:
        print("ERROR: Could not parse holdout pool from prd.md — check §5b format")
        return 2

    print(f"Active holdout pool: {sorted(holdout_ids)}")

    violations: list[str] = []
    files_checked = 0

    # Build sub-letter patterns for holdout base IDs
    # e.g. EC-079 is holdout -> also check EC-079a, EC-079b, EC-079c etc.
    # BI-044: use shared EC_TOKEN_RE instead of digits-only r"EC-(\d+)"
    holdout_base_nums = {slp.EC_TOKEN_RE.match(h).group(1) for h in holdout_ids if slp.EC_TOKEN_RE.match(h)}
    sub_letter_pattern = re.compile(
        r"\bEC-(" + "|".join(holdout_base_nums) + r")([a-z])\b"
    )
    bare_holdout_pattern = re.compile(
        r"\bEC-(" + "|".join(holdout_base_nums) + r")\b"
    )

    for md_file in sorted(SPECS.rglob("*.md")):
        if not should_check_file(md_file):
            continue
        files_checked += 1
        lines = slp.cm_splitlines(md_file.read_text(encoding="utf-8"))

        # For prd.md, skip lines in the §5b holdout declaration block
        is_prd = (md_file == PRD)

        for lineno, line in enumerate(lines, 1):
            # Skip the prd.md holdout declaration line itself
            if is_prd and "Holdout vectors" in line:
                continue
            # Skip struck-through text (retired entries)
            if "~~EC-" in line:
                continue
            # Skip the test-vectors.md HOLDOUT WARNING block header
            if "HOLDOUT WARNING" in line:
                continue

            if re.match(r"^\s*\|", line):
                # ── TABLE ROW: existing detection ──────────────────────────
                # Check bare holdout IDs
                for m in bare_holdout_pattern.finditer(line):
                    ec_id = f"EC-{m.group(1)}"
                    if ec_id in holdout_ids and is_concrete_scenario_row(line, ec_id):
                        violations.append(
                            f"{md_file}:{lineno}: holdout {ec_id} has concrete scenario in visible artifact\n"
                            f"  {line.strip()[:120]}"
                        )

                # Check sub-lettered variants of holdout base IDs
                for m in sub_letter_pattern.finditer(line):
                    ec_id_sub = f"EC-{m.group(1)}{m.group(2)}"
                    base_id = f"EC-{m.group(1)}"
                    if is_concrete_scenario_row(line, ec_id_sub):
                        violations.append(
                            f"{md_file}:{lineno}: sub-lettered alias {ec_id_sub} (base={base_id} is holdout) "
                            f"has concrete scenario in visible artifact [P3-021 pattern]\n"
                            f"  {line.strip()[:120]}"
                        )

            else:
                # ── PROSE / BULLET / CODE-FENCE: BI-049 broadened detection ──
                # Detects the exact breach shape from P7-S8-004/P7-S8-005:
                # a prose line that names a holdout EC ID AND contains an
                # arrow indicator + verdict word (concrete input→output narrative).
                # Bare narrative mentions (no arrow, no verdict) are NOT flagged.
                for m in bare_holdout_pattern.finditer(line):
                    ec_id = f"EC-{m.group(1)}"
                    if ec_id in holdout_ids and is_concrete_scenario_prose(line):
                        violations.append(
                            f"{md_file}:{lineno}: holdout {ec_id} has concrete prose scenario "
                            f"in visible artifact (BI-049)\n"
                            f"  {line.strip()[:120]}"
                        )

                # Sub-lettered aliases in prose
                for m in sub_letter_pattern.finditer(line):
                    ec_id_sub = f"EC-{m.group(1)}{m.group(2)}"
                    base_id = f"EC-{m.group(1)}"
                    if is_concrete_scenario_prose(line):
                        violations.append(
                            f"{md_file}:{lineno}: sub-lettered alias {ec_id_sub} (base={base_id} is holdout) "
                            f"has concrete prose scenario in visible artifact [P3-021 pattern, BI-049]\n"
                            f"  {line.strip()[:120]}"
                        )

    if violations:
        for v in violations:
            print(v)
        print(
            f"\nCheck FAILED: {len(violations)} holdout boundary violations found "
            f"({len(holdout_ids)} reserved holdout EC IDs checked across {files_checked} files, "
            f"{len(violations)} non-conforming)"
        )
        return 1

    print(
        f"Check passed: {len(holdout_ids)} reserved holdout EC IDs checked across "
        f"{files_checked} files, 0 non-conforming"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
