#!/usr/bin/env python3
"""
check-canonical-facts — verify every binding site matches its canonical value
==============================================================================
Loads .factory/specs/canonical-facts.toml, locates every [[binding]], extracts
the restated value via the binding's regex pattern, and compares it against the
[[fact]] canonical_value.

Exit 0  — all bindings match
Exit 1  — one or more divergences found (reports each one)

IMPORTANT — D-039 compliance:
  This checker has NO bypass mechanism. There is no --force flag, no skip
  environment variable, and no allowlist file. Every binding is always checked.

Usage:
  python3 check-canonical-facts.py
  SPEC_LINT_REPO_OVERRIDE=/path/to/repo python3 check-canonical-facts.py

SPEC_LINT_REPO_OVERRIDE:
  When set, the checker uses the given path as the repository root instead of
  inferring it from the script's location. Used by the selftest suite to run
  against isolated temporary trees.
"""
import os
import re
import sys
import tomllib
from pathlib import Path

def _find_repo_root() -> "Path | None":
    """
    Locate the repository root by walking up from this script's location until a
    directory containing `.factory/specs/canonical-facts.toml` is found.

    Returns None (never a Path) if:
      - A `.git` entry is found before canonical-facts.toml is found (repository
        boundary stop — prevents escaping to an unrelated ancestor repository or
        binding a decoy canonical-facts.toml from a different project). Note:
        `.git` is a FILE in linked worktrees and a DIRECTORY in main checkouts;
        `.exists()` correctly detects both.
      - The 8-level walk limit is reached with no match.

    FAIL-CLOSED design: returning None causes the caller to exit 1 with an
    error message rather than silently binding wrong data. The old fallback to
    `parent.parent.parent` failed CLOSED from secondary worktrees (correct).
    The old _find_repo_root() walk with no boundary stop could escape to an
    unrelated ancestor and fail OPEN when `.factory/` is unmounted (MAJOR-2
    regression). This version fails CLOSED in both cases.

    The BI-021 secondary-worktree scenario is handled correctly in the selftest
    tree (which has no `.git` file) and in production via SPEC_LINT_REPO_OVERRIDE.
    """
    candidate = Path(__file__).resolve().parent
    for _ in range(8):
        if (candidate / ".factory" / "specs" / "canonical-facts.toml").exists():
            return candidate
        # Repository boundary stop: .git is a file in linked worktrees,
        # a directory in main checkouts — exists() catches both.
        if (candidate / ".git").exists():
            return None
        candidate = candidate.parent
    return None


REPO = Path(os.environ.get("SPEC_LINT_REPO_OVERRIDE", "")).resolve() if os.environ.get("SPEC_LINT_REPO_OVERRIDE") else _find_repo_root()

# Fail CLOSED if _find_repo_root() returned None (boundary hit or 8-level limit).
# SPEC_LINT_REPO_OVERRIDE always produces a non-None Path, so the None case only
# arises when auto-detection is used and the walk cannot find canonical-facts.toml
# within the repository boundary.
if REPO is None:
    print(
        "check-canonical-facts: REPO root not found — no ancestor of this script\n"
        "  contains .factory/specs/canonical-facts.toml within the repository\n"
        "  boundary (walk stopped at .git or exceeded 8-level limit).\n"
        "  If .factory/ is a separate worktree, ensure it is mounted.\n"
        "  Set SPEC_LINT_REPO_OVERRIDE to the repo root to override path resolution.",
        file=sys.stderr,
    )
    sys.exit(1)

FACTS_FILE = REPO / ".factory" / "specs" / "canonical-facts.toml"


def main() -> int:
    if not FACTS_FILE.exists():
        print(
            f"ERROR: canonical-facts.toml not found at {FACTS_FILE}",
            file=sys.stderr,
        )
        return 1

    with FACTS_FILE.open("rb") as fh:
        data = tomllib.load(fh)

    facts: dict[str, dict] = {f["id"]: f for f in data.get("fact", [])}
    bindings: list[dict] = data.get("binding", [])

    if not facts:
        print("ERROR: canonical-facts.toml contains no [[fact]] entries", file=sys.stderr)
        return 1
    if not bindings:
        print("ERROR: canonical-facts.toml contains no [[binding]] entries", file=sys.stderr)
        return 1

    findings: list[str] = []

    for binding in bindings:
        fact_id = binding.get("fact_id", "")
        rel_path = binding.get("file", "")
        pattern = binding.get("pattern", "")
        note = binding.get("note", "")

        if fact_id not in facts:
            findings.append(
                f"CONFIG-ERROR: binding references unknown fact_id '{fact_id}' "
                f"(file: {rel_path})"
            )
            continue

        fact = facts[fact_id]
        canonical = fact["canonical_value"]
        file_path = REPO / rel_path

        if not file_path.exists():
            findings.append(
                f"MISSING [{fact_id}] {rel_path}: file not found on disk"
            )
            continue

        try:
            content = file_path.read_text(encoding="utf-8")
        except OSError as exc:
            findings.append(
                f"IO-ERROR [{fact_id}] {rel_path}: {exc}"
            )
            continue

        try:
            m = re.search(pattern, content, re.DOTALL)
        except re.error as exc:
            findings.append(
                f"PATTERN-ERROR [{fact_id}] {rel_path}: invalid regex '{pattern}': {exc}"
            )
            continue

        if not m:
            findings.append(
                f"DIVERGE [{fact_id}] {rel_path}"
                + (f" ({note})" if note else "")
                + f": pattern did not match (expected canonical_value='{canonical}')"
            )
        elif m.group(1) != canonical:
            findings.append(
                f"DIVERGE [{fact_id}] {rel_path}"
                + (f" ({note})" if note else "")
                + f": extracted '{m.group(1)}', expected '{canonical}'"
            )

    if findings:
        print(
            f"canonical-facts: {len(findings)} divergence(s) found "
            f"(checked {len(bindings)} bindings across {len(facts)} facts):"
        )
        for f in findings:
            print(f"  {f}")
        return 1

    print(
        f"canonical-facts: OK — all {len(bindings)} bindings match canonical values "
        f"({len(facts)} facts)"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
