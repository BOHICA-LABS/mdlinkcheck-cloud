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
"""
import os
import re
import sys
from pathlib import Path

REPO = Path(os.environ.get("SPEC_LINT_REPO_OVERRIDE", "")).resolve() if os.environ.get("SPEC_LINT_REPO_OVERRIDE") else Path(__file__).resolve().parent.parent.parent
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
        for ec_m in re.finditer(r"EC-(\d+)", raw):
            holdout_ids.add(f"EC-{ec_m.group(1)}")

    # Also cross-check HS-INDEX for active entries
    if HS_INDEX.exists():
        for line in HS_INDEX.read_text(encoding="utf-8").splitlines():
            # Active rows (not struck-through)
            if "~~" not in line:
                ec_m = re.search(r"\|\s*(EC-(\d+))\s*\|", line)
                if ec_m:
                    holdout_ids.add(f"EC-{ec_m.group(2)}")

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
    holdout_base_nums = {re.match(r"EC-(\d+)", h).group(1) for h in holdout_ids if re.match(r"EC-(\d+)", h)}
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
        lines = md_file.read_text(encoding="utf-8").splitlines()

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

            # Check bare holdout IDs in concrete table rows
            if re.match(r"^\s*\|", line):
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

    if violations:
        for v in violations:
            print(v)
        print(
            f"\nCheck FAILED: {len(violations)} holdout boundary violations found "
            f"({files_checked} files checked, {len(holdout_ids)} active holdout IDs)"
        )
        return 1

    print(
        f"Check passed: {files_checked} visible artifact files checked — "
        f"no concrete holdout scenarios leaked (pool: {len(holdout_ids)} IDs)"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
