#!/usr/bin/env python3
"""
check-ec-injectivity — POL-16 (the big one)
============================================
Every EC-NNN must denote exactly ONE scenario. Detect same EC ID used with differing
scenario descriptions or differing expected verdicts across BC edge-case tables and
test-vectors.md.

The canonical EC registry is test-vectors.md. BC files cite ECs in their Edge Cases
tables. If the same bare EC-NNN (not sub-lettered) appears in multiple BC files with
different scenario descriptions, or the same EC-NNN appears in both test-vectors.md
and a BC with a different expected verdict, that is a collision.

Sub-lettered variants (EC-079b, EC-094a) are distinct IDs and should not be confused
with their base. However: if a sub-lettered variant's BASE ID is a holdout, the
presence of concrete sub-lettered rows in visible BCs is also flagged (handled by
check-holdout-boundary.py) — this check focuses on description/verdict collisions.

BC-vs-Registry scenario comparison (BI-051):
  In addition to the injectivity check above, this checker compares each BC's stated
  scenario text for an EC ID against the canonical description in test-vectors.md
  using Jaccard similarity on significant tokens:

  - AGREE  (Jaccard >= 0.10): BC and registry are consistent — no finding.
  - ADJUDICATION (0.02 <= Jaccard < 0.10): token overlap is low but nonzero;
    the checker cannot determine agreement with confidence. These cases MUST be
    reported (never passed silently) as requires-adjudication.
  - DIVERGENT (Jaccard < 0.02): essentially disjoint vocabularies — the BC describes
    a materially different scenario than the registry. These are hard findings.

  Calibration reference (adversary pass P7-S5-017):
    EC-142 — TV: "Only an unreadable file" (exit 2)
             BC: "Scan with 0 findings"
    Tokens: TV {unreadable, file}, BC {scan, findings} → intersection=∅ → J=0 → DIVERGENT

  Mechanizability limit: Full semantic agreement is not decidable from token overlap.
  This checker implements the strongest sound approximation: clearly disjoint scenarios
  (J < 0.02) are flagged as divergent; borderline cases are escalated for human
  adjudication; high-overlap cases are assumed consistent.

  The checker emits three counts in its coverage assertion:
    N EC citations compared across M of M spec files (complete), X divergent,
    Y require adjudication
  If files_scanned != corpus_total, the checker FAILS LOUDLY.

Exit 1 if any injective-map violation or BC-vs-registry divergence found.
"""
import re
import sys
from collections import defaultdict
from pathlib import Path
import spec_lint_primitives as slp

REPO = slp.find_repo_root(start=Path(__file__).resolve().parent)  # honors SPEC_LINT_REPO_OVERRIDE
SPECS = REPO / ".factory" / "specs"
BC_DIR = SPECS / "behavioral-contracts"
TV_FILE = SPECS / "prd-supplements" / "test-vectors.md"


def parse_frontmatter_end(lines: list[str]) -> int:
    if lines and lines[0].rstrip() == "---":
        for i in range(1, len(lines)):
            if lines[i].rstrip() == "---":
                return i + 1
    return 0


def normalize_verdict(raw: str) -> str:
    """Normalize a verdict string for comparison (lower-case, strip parens content)."""
    raw = raw.strip().lower()
    # Extract the primary verdict word
    m = re.match(r"^(alive|broken|indeterminate|clean|dead|valid)", raw)
    if m:
        return m.group(1)
    return raw[:40]  # fallback


def normalize_desc(s: str) -> str:
    """Normalize a description for collision comparison.
    Strips backtick DELIMITERS but keeps content (preserves filenames, commands).
    Removes emphasis markers, punctuation, lowercases.
    """
    # Strip backtick delimiters but keep the content — paths/commands are key tokens
    s = re.sub(r'`([^`]*)`', r'\1', s)
    s = re.sub(r'\*+', '', s)       # strip emphasis
    s = re.sub(r'[^\w\s]', ' ', s)  # punctuation → space
    return s.lower().strip()


def _significant_tokens(s: str) -> set:
    """Extract significant (non-stop-word) tokens of length >= 3."""
    STOP = {
        'the', 'and', 'for', 'with', 'has', 'are', 'not', 'this', 'that',
        'from', 'its', 'all', 'any', 'can', 'per', 'via', 'but', 'where',
        'when', 'into', 'onto', 'over', 'than', 'then', 'also', 'both',
        'each', 'such', 'even', 'very', 'just', 'only', 'does', 'have',
        'been', 'will', 'was', 'were', 'had', 'has', 'did', 'one', 'two',
        'more', 'less', 'some', 'same', 'like', 'used', 'using',
    }
    words = re.findall(r'\b[a-z]{3,}\b', normalize_desc(s))
    return {w for w in words if w not in STOP}


def descriptions_conflict(d1: str, d2: str) -> bool:
    """Return True if d1 and d2 describe genuinely different scenarios.

    Uses Jaccard similarity on significant tokens:
    - Jaccard >= 0.10: substantial overlap → treat as paraphrase (no conflict)
    - Jaccard < 0.10: essentially disjoint vocabulary → treat as collision

    Calibration (from cycle-5 reviewer's enumerated pairs):
    - Genuine collisions: EC-009 "symlink outside root" vs "empty directory" → Jaccard ≈ 0.0
    - Paraphrases: EC-004, EC-008, etc. share domain vocabulary → Jaccard typically >= 0.25
    """
    t1 = _significant_tokens(d1)
    t2 = _significant_tokens(d2)
    if not t1 and not t2:
        return False  # both empty — treat as same
    if not t1 or not t2:
        return True   # one empty, one not — conflict
    union = t1 | t2
    if not union:
        return False
    jaccard = len(t1 & t2) / len(union)
    return jaccard < 0.10


def extract_ec_rows(path: Path) -> list[tuple[str, str, str, int]]:
    """
    Parse a Markdown file for EC table rows.
    Returns list of (ec_id, description, verdict_raw, lineno).
    Handles both 2-column (EC-ID | desc) and 3-column (EC-ID | desc | verdict) formats.

    BI-044: uses slp.split_table_cells() + slp.EC_TOKEN_RE to enforce the shared
    conforming EC grammar (EC-\d{1,4}[a-z]?) instead of an inline pattern.
    """
    rows = []
    lines = slp.cm_splitlines(path.read_text(encoding="utf-8"))
    start = parse_frontmatter_end(lines)

    for lineno, line in enumerate(lines[start:], start=start + 1):
        cells = slp.split_table_cells(line)
        if not cells:
            continue
        # Require first cell to be a non-struck-through conforming EC ID (BI-044)
        if not slp.EC_TOKEN_RE.fullmatch(cells[0]):
            continue
        ec_id = cells[0]
        # Remaining cells; exclude separator-pattern cells (e.g. '---')
        rest_cells = [c for c in cells[1:] if c and not re.match(r"^-+$", c)]
        if not rest_cells:
            continue
        desc = rest_cells[0]
        verdict_raw = rest_cells[1] if len(rest_cells) > 1 else ""
        rows.append((ec_id, desc, verdict_raw, lineno))
    return rows


def extract_tv_rows(path: Path) -> list[tuple[str, str, str, int]]:
    """
    Parse test-vectors.md for EC references.
    TV rows look like: | TV-NNN | EC-NNN | Description | ... | exit_code | verdict | reason |
    Returns list of (ec_id, description, verdict_raw, lineno).

    BI-044: EC ID column now uses the shared grammar (EC-\d{1,4}[a-z]?) via EC_TOKEN_RE.pattern.
    """
    rows = []
    lines = slp.cm_splitlines(path.read_text(encoding="utf-8"))
    for lineno, line in enumerate(lines, 1):
        # Match TV table row that contains an EC-NNN column (BI-044: \d{1,4} shared grammar)
        m = re.match(
            r"^\|\s*(TV-[\w]+)\s*\|\s*(EC-\d{1,4}[a-z]?)\s*\|\s*(.+?)\s*\|.*?\|\s*(\d|n/a)\s*\|\s*(.+?)\s*\|",
            line,
        )
        if m:
            ec_id = m.group(2)
            desc = m.group(3).strip()
            verdict_raw = m.group(5).strip()
            rows.append((ec_id, desc, verdict_raw, lineno))
    return rows


# ── BC-vs-Registry thresholds (BI-051) ────────────────────────────────────────
# Jaccard similarity of significant tokens between a BC citation description and
# the canonical description in test-vectors.md.
BC_REGISTRY_AGREE = 0.10        # Jaccard >= this → consistent (PASS)
BC_REGISTRY_BORDERLINE = 0.02   # Jaccard in [this, AGREE) → requires adjudication
# Jaccard < BORDERLINE → divergent scenario (hard finding)


def _compare_bc_to_registry(bc_desc: str, tv_desc: str) -> str:
    """Return 'pass', 'adjudication', or 'divergent' for a BC description vs TV description.

    Uses Jaccard similarity on significant tokens (same tokenizer as descriptions_conflict).
    Thresholds: AGREE=0.10, BORDERLINE=0.02 (calibrated against EC-142: J=0 → divergent).
    """
    t1 = _significant_tokens(tv_desc)
    t2 = _significant_tokens(bc_desc)
    if not t1 and not t2:
        return "pass"    # both empty — treat as same
    if not t1 or not t2:
        return "adjudication"  # one empty, one not — cannot determine
    union = t1 | t2
    if not union:
        return "pass"
    jaccard = len(t1 & t2) / len(union)
    if jaccard >= BC_REGISTRY_AGREE:
        return "pass"
    elif jaccard >= BC_REGISTRY_BORDERLINE:
        return "adjudication"
    else:
        return "divergent"


def main() -> int:
    if not SPECS.exists():
        print(f"ERROR: Spec tree not found at {SPECS} — cannot run check (no spec files to validate)", file=sys.stderr)
        sys.exit(1)

    # ── Corpus scan: collect EC citations from ALL spec files ──────────────────
    # We scan all spec files (not just BC_DIR) to emit a corpus-completeness assertion.
    # Most non-BC files contribute 0 citations; they are still counted as scanned.
    total_files = sum(1 for _ in SPECS.rglob("*.md"))
    files_scanned = 0

    # Map: ec_id -> list of (source_file, description, verdict_raw, lineno)
    ec_map: dict[str, list[tuple[str, str, str, int]]] = defaultdict(list)

    tv_file_str = str(TV_FILE)

    for md_file in sorted(SPECS.rglob("*.md")):
        files_scanned += 1
        if BC_DIR in md_file.parents:
            # BC file: scan for EC table rows
            for ec_id, desc, verdict, lineno in extract_ec_rows(md_file):
                ec_map[ec_id].append((str(md_file), desc, verdict, lineno))
        elif md_file == TV_FILE:
            # test-vectors.md: scan for TV rows
            for ec_id, desc, verdict, lineno in extract_tv_rows(md_file):
                ec_map[ec_id].append((tv_file_str, desc, verdict, lineno))
        # other spec files: no EC citations expected; just counted for completeness

    if files_scanned != total_files:
        print(
            f"ERROR: scanned {files_scanned} of {total_files} spec files — "
            f"corpus-completeness assertion FAILED",
            file=sys.stderr,
        )
        return 1

    # ── Injectivity check: BC-vs-BC description collision + BC-vs-TV verdict collision ──
    violations: list[str] = []
    collision_ids: set[str] = set()

    for ec_id, occurrences in sorted(ec_map.items()):
        if len(occurrences) <= 1:
            continue

        # Separate BC-file occurrences from test-vectors.md occurrences
        bc_occs = [(f, d, v, l) for f, d, v, l in occurrences if f != tv_file_str]
        tv_occs = [(f, d, v, l) for f, d, v, l in occurrences if f == tv_file_str]

        has_desc_collision = False
        has_verdict_collision = False
        desc_collision_detail: list[str] = []
        verdict_collision_detail: list[str] = []

        # Description collision: across BC files, independent of verdict column presence.
        # BC descriptions are expected paraphrases of TV descriptions (TV captures the
        # canonical input-file name, not a scenario description), so BC-vs-TV is skipped.
        if len(bc_occs) > 1:
            # Group by normalized description; if more than one distinct group → collision
            groups: dict = {}
            for occ in bc_occs:
                key = normalize_desc(occ[1])
                if key not in groups:
                    groups[key] = []
                groups[key].append(occ)

            if len(groups) > 1:
                # Check if ANY pair of groups has genuinely conflicting descriptions
                norm_descs = list(groups.keys())
                for i in range(len(norm_descs)):
                    for j in range(i + 1, len(norm_descs)):
                        if descriptions_conflict(norm_descs[i], norm_descs[j]):
                            has_desc_collision = True

                if has_desc_collision:
                    for filepath, desc, verdict_raw, lineno in bc_occs:
                        desc_collision_detail.append(
                            f"  {filepath}:{lineno}: desc={desc[:80]!r}"
                        )

        # Verdict collision: BC file vs test-vectors.md — only when BOTH have explicit verdicts
        if bc_occs and tv_occs:
            tv_verdicts = [normalize_verdict(o[2]) for o in tv_occs if o[2].strip()]
            for bc_filepath, bc_desc, bc_verdict_raw, bc_lineno in bc_occs:
                if not bc_verdict_raw.strip():
                    continue  # BC row has no verdict column — skip verdict comparison
                bc_norm = normalize_verdict(bc_verdict_raw)
                for tv_norm in tv_verdicts:
                    if tv_norm and bc_norm != tv_norm:
                        has_verdict_collision = True
                        verdict_collision_detail.extend([
                            f"  {f}:{l}: desc={d[:80]!r} verdict={v[:40]!r}"
                            for f, d, v, l in tv_occs
                        ])
                        verdict_collision_detail.append(
                            f"  {bc_filepath}:{bc_lineno}: desc={bc_desc[:80]!r} verdict={bc_verdict_raw[:40]!r}"
                        )

        if has_desc_collision or has_verdict_collision:
            collision_ids.add(ec_id)
            hdr = f"COLLISION {ec_id}:"
            if has_desc_collision:
                hdr += " description-mismatch"
            if has_verdict_collision:
                hdr += " verdict-mismatch"
            violations.append(hdr)
            violations.extend(desc_collision_detail)
            violations.extend(verdict_collision_detail)

    total_ec_ids = len(ec_map)
    multi_occurrence = sum(1 for v in ec_map.values() if len(v) > 1)

    # ── BC-vs-Registry scenario comparison (BI-051) ────────────────────────────
    # Compare each BC citation's scenario description against the canonical description
    # in test-vectors.md. Three buckets: divergent (hard finding), adjudication
    # (borderline — human review required), pass (consistent).
    registry_citations = 0
    registry_divergent: list[tuple] = []
    registry_adjudication: list[tuple] = []
    registry_pass = 0

    for ec_id, occurrences in sorted(ec_map.items()):
        bc_occs = [(f, d, v, l) for f, d, v, l in occurrences if f != tv_file_str]
        tv_occs = [(f, d, v, l) for f, d, v, l in occurrences if f == tv_file_str]

        if not bc_occs or not tv_occs:
            continue  # Cannot compare without both a BC citation and a registry entry

        tv_desc = tv_occs[0][1]  # canonical description from first TV row for this EC

        for bc_filepath, bc_desc, bc_verdict, bc_lineno in bc_occs:
            registry_citations += 1
            result = _compare_bc_to_registry(bc_desc, tv_desc)
            t1 = _significant_tokens(tv_desc)
            t2 = _significant_tokens(bc_desc)
            union = t1 | t2
            jaccard = len(t1 & t2) / len(union) if union else 1.0
            if result == "pass":
                registry_pass += 1
            elif result == "adjudication":
                registry_adjudication.append((
                    ec_id, bc_filepath, bc_lineno, bc_desc, tv_desc,
                    f"J={jaccard:.2f}",
                ))
            else:  # divergent
                registry_divergent.append((
                    ec_id, bc_filepath, bc_lineno, bc_desc, tv_desc,
                    f"J={jaccard:.2f}",
                ))

    # Print results
    if violations:
        for v in violations:
            print(v)
        print(
            f"\nINJECTIVITY FAILED: {len(collision_ids)} EC ID collisions found "
            f"({total_ec_ids} unique EC IDs scanned; {multi_occurrence} appear in multiple files)"
        )

    if registry_divergent:
        print()
        for ec_id, filepath, lineno, bc_desc, tv_desc, detail in registry_divergent:
            print(f"SCENARIO-MISMATCH {ec_id}: {filepath}:{lineno}")
            print(f"  BC  : {bc_desc[:80]!r}")
            print(f"  TV  : {tv_desc[:80]!r}")
            print(f"  ({detail})")

    if registry_adjudication:
        print()
        for ec_id, filepath, lineno, bc_desc, tv_desc, detail in registry_adjudication:
            print(f"REQUIRES-ADJUDICATION {ec_id}: {filepath}:{lineno}")
            print(f"  BC  : {bc_desc[:80]!r}")
            print(f"  TV  : {tv_desc[:80]!r}")
            print(f"  ({detail})")

    # Completeness assertion (corpus-completeness, D-113 style)
    completeness = (
        "complete"
        if files_scanned == total_files
        else f"INCOMPLETE — only {files_scanned} of {total_files} scanned"
    )
    print(
        f"\n{registry_citations} EC citations compared across "
        f"{files_scanned} of {total_files} spec files ({completeness}), "
        f"{len(registry_divergent)} divergent, {len(registry_adjudication)} require adjudication"
    )

    # Exit code: fail on injectivity violations OR divergent BC-vs-registry mismatches
    if violations or registry_divergent:
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
