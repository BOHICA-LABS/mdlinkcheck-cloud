#!/usr/bin/env python3
"""
check-id-resolution — POL-16
==============================
Every ID reference in any .factory/specs/ file must resolve to a definition
in its source of truth. Unresolvable references are reported.

ID families and their registries:
  CAP-NNN   -> domain-spec/capabilities.md (## CAP-NNN headings)
  DI-NNN    -> domain-spec/invariants.md (## DI-NNN headings)
  DD-NNN    -> domain-spec/decisions.md (## DD-NNN headings)
  BC-S.SS.NNN -> behavioral-contracts/ss-SS/BC-S.SS.NNN.md (file existence)
  VP-NNN    -> verification-properties/VP-INDEX.md (| VP-NNN |)
  ADR-NNN   -> architecture/decisions/ADR-NNN-*.md (file existence by prefix)
  NFR-NNN   -> prd-supplements/nfr-catalog.md (| NFR-NNN | headings)
  EC-NNN    -> prd-supplements/test-vectors.md (TABLE ROWS only) OR holdout pool
              Sub-lettered EC-NNNx valid if base EC-NNN is registered.
              NOTE: prose/changelog mentions of EC IDs in test-vectors.md or
              prd.md are NOT registrations — only table rows count.
  T-NN      -> prd-supplements/test-vectors.md (section 8 T1-T16 trap map)
              NOTE: existence check only. Semantic correctness (whether the
              cited trap is topically relevant to the citing row) is NOT
              mechanically automatable — requires human review.
  R-NN      -> product-brief.md (R1..R8 requirement IDs)
  HS-NNN    -> holdout-scenarios/HS-INDEX.md (| HS-NNN |)
  POL-NN    -> .factory/policies.yaml (- id: NN)

Exit 1 if any unresolvable reference found.
"""
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent.parent
SPECS = REPO / ".factory" / "specs"
FACTORY = REPO / ".factory"

# Source-of-truth files
CAPABILITIES = SPECS / "domain-spec" / "capabilities.md"
INVARIANTS = SPECS / "domain-spec" / "invariants.md"
DECISIONS = SPECS / "domain-spec" / "decisions.md"
VP_INDEX = SPECS / "verification-properties" / "VP-INDEX.md"
NFR_CATALOG = SPECS / "prd-supplements" / "nfr-catalog.md"
TEST_VECTORS = SPECS / "prd-supplements" / "test-vectors.md"
BRIEF = SPECS / "product-brief.md"
HS_INDEX = FACTORY / "holdout-scenarios" / "HS-INDEX.md"
POLICIES = FACTORY / "policies.yaml"
ADR_DIR = SPECS / "architecture" / "decisions"
BC_DIR = SPECS / "behavioral-contracts"


def build_heading_ids(path: Path, pattern: str) -> set[str]:
    """Extract IDs from # headings matching `pattern` (e.g. 'CAP-\\d+')."""
    if not path.exists():
        return set()
    ids: set[str] = set()
    for line in path.read_text(encoding="utf-8").splitlines():
        m = re.search(pattern, line)
        if m and line.startswith("#"):
            ids.add(m.group(0))
    return ids


def build_table_ids(path: Path, pattern: str) -> set[str]:
    """Extract IDs from Markdown table rows matching `pattern`."""
    if not path.exists():
        return set()
    ids: set[str] = set()
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.startswith("|"):
            continue
        for m in re.finditer(pattern, line):
            ids.add(m.group(0))
    return ids


def build_file_ids(directory: Path, pattern: str) -> set[str]:
    """Extract IDs by scanning filenames in a directory for `pattern`."""
    if not directory.exists():
        return set()
    ids: set[str] = set()
    for p in directory.iterdir():
        m = re.search(pattern, p.name)
        if m:
            ids.add(m.group(0))
    return ids


def build_yaml_ids(path: Path, pattern: str) -> set[str]:
    """Extract IDs from a YAML file (plain text scan)."""
    if not path.exists():
        return set()
    ids: set[str] = set()
    for line in path.read_text(encoding="utf-8").splitlines():
        for m in re.finditer(pattern, line):
            ids.add(m.group(0))
    return ids


def build_valid_bc_ids() -> set[str]:
    """Return all BC-S.SS.NNN IDs for which a file exists."""
    ids: set[str] = set()
    for f in BC_DIR.rglob("BC-*.md"):
        if f.name.startswith("BC-INDEX"):
            continue
        m = re.match(r"(BC-\d+\.\d+\.\d+)\.md", f.name)
        if m:
            ids.add(m.group(1))
    return ids


def build_valid_ec_ids() -> set[str]:
    """Return all registered EC-NNN and EC-NNNx IDs.

    POL-16: the EC registry is test-vectors.md TABLE ROWS only.
    Prose mentions in test-vectors.md or prd.md (e.g. changelog entries
    like 'EC-102 was replaced by EC-151') are NOT registrations.

    Sub-lettered variants EC-NNNx (e.g. EC-015b, EC-094a) are valid if
    their base EC-NNN is registered. This matches how test-vectors.md
    references them: TV-015b → EC-015 (not EC-015b).

    The holdout pool declared in prd.md §5b is also a valid source:
    those IDs are registered even though they have no visible TV row.
    """
    base_nums: set[int] = set()  # numeric parts of registered base IDs

    # From test-vectors.md: scan TABLE ROWS ONLY (lines starting with |).
    # Any EC-NNN that appears in a table row is registered.
    if TEST_VECTORS.exists():
        for line in TEST_VECTORS.read_text(encoding="utf-8").splitlines():
            if not line.startswith("|"):
                continue  # skip prose, blockquotes, section headers
            for m in re.finditer(r"\bEC-(\d+)\b", line):
                base_nums.add(int(m.group(1)))

    # From prd.md: holdout pool only — the canonical declaration line.
    # Pattern: "Holdout vectors **(EC-079, EC-093, ...)**"
    prd = SPECS / "prd.md"
    if prd.exists():
        text = prd.read_text(encoding="utf-8")
        holdout_m = re.search(r"Holdout vectors\s+\*\*\(([^)]+)\)\*\*", text)
        if holdout_m:
            for m in re.finditer(r"\bEC-(\d+)\b", holdout_m.group(1)):
                base_nums.add(int(m.group(1)))

    # Build the full valid set: base IDs + sub-lettered variants
    ids: set[str] = set()
    for n in base_nums:
        base = f"EC-{n:03d}" if n < 1000 else f"EC-{n}"
        # Also accept zero-padded and unpadded forms
        ids.add(f"EC-{n}")
        ids.add(f"EC-{n:03d}")
        # Sub-lettered: EC-NNNa through EC-NNNz
        for c in "abcdefghijklmnopqrstuvwxyz":
            ids.add(f"EC-{n}{c}")
            ids.add(f"EC-{n:03d}{c}")

    return ids


def build_valid_adr_ids() -> set[str]:
    """Return ADR-NNN IDs from ADR filenames."""
    if not ADR_DIR.exists():
        return set()
    ids: set[str] = set()
    for f in ADR_DIR.iterdir():
        m = re.match(r"(ADR-\d+)", f.name)
        if m:
            ids.add(m.group(1))
    return ids


def build_valid_r_ids() -> set[str]:
    """Return R-NN requirement IDs from product-brief.md."""
    ids = {"R1", "R2", "R2a", "R2b", "R2c", "R3", "R4", "R5", "R6", "R7", "R8",
           "R-001", "R-002", "R-003", "R-004", "R-005", "R-006", "R-007", "R-008"}
    if BRIEF.exists():
        for line in BRIEF.read_text(encoding="utf-8").splitlines():
            for m in re.finditer(r"\bR(\d+[a-c]?)\b", line):
                ids.add(f"R{m.group(1)}")
    return ids


def build_valid_pol_ids() -> set[str]:
    """Return POL-NN IDs from policies.yaml."""
    ids: set[str] = set()
    if POLICIES.exists():
        for line in POLICIES.read_text(encoding="utf-8").splitlines():
            m = re.match(r"\s*-\s*id:\s*(\d+)", line)
            if m:
                ids.add(f"POL-{int(m.group(1))}")
    return ids


# Build all registries
VALID_CAP = build_heading_ids(CAPABILITIES, r"CAP-\d+")
VALID_DI = build_heading_ids(INVARIANTS, r"DI-\d+")
# DD entries are in table rows in decisions.md (| DD-NNN | ... ), not headings
VALID_DD = build_table_ids(DECISIONS, r"DD-\d+")
VALID_VP = build_table_ids(VP_INDEX, r"VP-\d+")
VALID_NFR = build_table_ids(NFR_CATALOG, r"NFR-\d+")
VALID_HS = build_table_ids(HS_INDEX, r"HS-\d+")
VALID_BC = build_valid_bc_ids()
VALID_EC = build_valid_ec_ids()
VALID_ADR = build_valid_adr_ids()
VALID_R = build_valid_r_ids()
VALID_POL = build_valid_pol_ids()
# T-NN trap map: T1..T16 per test-vectors.md section 8
# Both "T1" and "T-1" forms are accepted (both appear in specs).
VALID_T = {f"T-{i}" for i in range(1, 17)} | {f"T{i}" for i in range(1, 17)}

# Files to skip (the registries themselves to avoid circular validation)
REGISTRY_FILES = {
    str(CAPABILITIES), str(INVARIANTS), str(DECISIONS),
    str(VP_INDEX), str(NFR_CATALOG), str(TEST_VECTORS),
    str(BRIEF), str(HS_INDEX), str(POLICIES),
}


def check_file(path: Path) -> list[str]:
    violations = []
    if str(path) in REGISTRY_FILES:
        return violations
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()

    def v(lineno, ref, family, valid_set):
        if ref not in valid_set:
            violations.append(
                f"{path}:{lineno}: unresolvable {family} reference '{ref}'"
            )

    for lineno, line in enumerate(lines, 1):
        for m in re.finditer(r"\bCAP-(\d+)\b", line):
            ref = f"CAP-{m.group(1)}"
            v(lineno, ref, "CAP", VALID_CAP)

        for m in re.finditer(r"\bDI-(\d+)\b", line):
            ref = f"DI-{m.group(1)}"
            v(lineno, ref, "DI", VALID_DI)

        for m in re.finditer(r"\bDD-(\d+)\b", line):
            ref = f"DD-{m.group(1)}"
            v(lineno, ref, "DD", VALID_DD)

        for m in re.finditer(r"\bVP-(\d+)\b", line):
            ref = f"VP-{m.group(1)}"
            if ref != "VP-TBD":
                v(lineno, ref, "VP", VALID_VP)

        for m in re.finditer(r"\bNFR-(\d+)\b", line):
            ref = f"NFR-{m.group(1)}"
            v(lineno, ref, "NFR", VALID_NFR)

        for m in re.finditer(r"\b(BC-\d+\.\d+\.\d+)\b", line):
            ref = m.group(1)
            if ref not in VALID_BC:
                violations.append(
                    f"{path}:{lineno}: unresolvable BC reference '{ref}'"
                )

        for m in re.finditer(r"\b(ADR-\d+)\b", line):
            ref = m.group(1)
            v(lineno, ref, "ADR", VALID_ADR)

        for m in re.finditer(r"\b(HS-\d+)\b", line):
            ref = m.group(1)
            v(lineno, ref, "HS", VALID_HS)

        for m in re.finditer(r"\b(POL-\d+)\b", line):
            ref = m.group(1)
            v(lineno, ref, "POL", VALID_POL)

        # EC-NNN and EC-NNNx: must be registered in test-vectors.md table rows
        # or holdout pool. Prose mentions and changelog entries are NOT registrations.
        for m in re.finditer(r"\bEC-(\d+)([a-z]?)\b", line):
            ref = f"EC-{m.group(1)}{m.group(2)}"
            if ref not in VALID_EC:
                violations.append(
                    f"{path}:{lineno}: unresolvable EC reference '{ref}' "
                    f"(not in test-vectors.md table rows or holdout pool)"
                )

        # T-NN trap citations: existence check only (T1..T16).
        # NOTE: semantic correctness (whether the cited trap is topically relevant
        # to the citing row) is NOT mechanically automatable and requires human review.
        for m in re.finditer(r"\bT-?(\d{1,2})\b", line):
            num = int(m.group(1))
            if 1 <= num <= 16:
                ref = m.group(0)  # T1 or T-1 form as written
                if ref not in VALID_T:
                    violations.append(
                        f"{path}:{lineno}: trap reference '{ref}' not in T1..T16 range"
                    )
            # T numbers > 16 are not trap IDs — skip silently

    return violations


def main() -> int:
    all_violations: list[str] = []
    files_checked = 0

    # Check all .md files under .factory/specs/
    for md_file in sorted(SPECS.rglob("*.md")):
        violations = check_file(md_file)
        all_violations.extend(violations)
        files_checked += 1

    # Also check .factory/policies.yaml and other yaml
    for yaml_file in sorted(FACTORY.glob("*.yaml")):
        violations = check_file(yaml_file)
        all_violations.extend(violations)

    if all_violations:
        for v in all_violations:
            print(v)
        print(
            f"\nCheck FAILED: {len(all_violations)} unresolvable ID references found "
            f"({files_checked} files checked)"
        )
        return 1

    print(f"Check passed: {files_checked} files checked — all ID references resolve")
    return 0


if __name__ == "__main__":
    sys.exit(main())
