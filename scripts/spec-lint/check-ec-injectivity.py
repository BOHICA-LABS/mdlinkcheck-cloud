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


def extract_tv_rows(
    path: Path,
) -> tuple[list[tuple[str, str, str, int]], dict[str, int], int, int]:
    """
    Parse test-vectors.md for EC references.
    Multi-column schema-aware: collects ALL comparable columns per section and
    concatenates them to form the scenario description.

    Returns (rows, skipped_by_col, skipped_no_tv_id, skipped_no_ec):
      rows: list of (ec_id, description, verdict_raw, lineno)
      skipped_by_col: dict mapping non-comparable column name (or
        "no-description-column") to count of EC-valid TV rows skipped (D-132).
      skipped_no_tv_id: count of table rows that failed the TV-NNN ID gate
        (e.g. unrecognized rows in sections with no TV/EC header).
      skipped_no_ec: count of TV-NNN rows where the second cell is not a valid
        EC token (e.g. TV-BV013, TV-S001..TV-S016 — legitimately EC-less rows).

    BI-057 change (a): multi-column concatenation replaces single-column election.
      Now parses all three previously-skipped TV table shapes:
        §2 (Source MD File | Link | Filesystem): scenario = Filesystem + Link cols
        §3 (Source MD | Heading | Link):         scenario = Heading + Link cols
        §4 (Link | Mock Server / Setup):         scenario = Link + Mock Server cols
      Columns "Source MD File" and "Source MD" remain non-comparable (filenames).

    BI-057 change (c): non-table lines reset section parser state to prevent stale
      column indices from §N bleeding into §N+1 when an unrecognised header appears.
      Any row whose first cell is "TV" but whose second cell is not "EC" is also
      explicitly treated as an unrecognised header and resets state.

    BI-044: EC ID column uses the shared grammar (EC-\d{1,4}[a-z]?) via EC_TOKEN_RE.
    BLOCKING-1: schema-aware column extraction.
    BLOCKING-4: expanded synonym set — Input and Source MD Content are comparable;
      Source MD File and Source MD are non-comparable (filename columns).
      "Link", "Filesystem", "Heading", "Mock Server" are now comparable (BI-057 a).
    """
    rows: list[tuple[str, str, str, int]] = []
    skipped_by_col: dict[str, int] = {}
    skipped_no_tv_id = 0
    skipped_no_ec = 0
    lines = slp.cm_splitlines(path.read_text(encoding="utf-8"))

    # BI-057 change (a): multi-column desc extraction replaces single-column election.
    current_desc_cols: list[int] = []   # comparable column indices for current section
    current_skip_col_name: str | None = None  # first non-comparable col (for audit)

    # Non-comparable column names (exact match after strip+lower) — filenames/paths
    # that are NOT useful scenario prose on their own.
    _NON_COMPARABLE = {"source md file", "source md"}

    # Comparable scenario-prose keywords (case-insensitive substring match).
    # BI-057 change (a): "filesystem", "heading", "mock server" added so the
    # §2/§3/§4 table shapes in test-vectors.md are parsed rather than skipped.
    # "link" is NOT in this list: link-target columns (URLs / relative paths) are
    # filenames/destinations, not scenario prose.  Making them comparable inflates
    # Jaccard and suppresses findings without adding coverage (row counts are unchanged
    # whether "link" is comparable or not — §2/§3/§4 coverage comes from "filesystem",
    # "heading", and "mock server").  Decision B authorized by orchestrator (gate #35).
    _COMPARABLE_KEYWORDS = [
        "description", "input", "source md content", "scenario",
        "filesystem", "heading", "mock server",
    ]

    for lineno, line in enumerate(lines, 1):
        cells = slp.split_table_cells(line)

        # BI-057 change (c): reset section state on any non-table line (blank, prose, HR).
        # This prevents a section's column indices from bleeding into the next section
        # when an unrecognised header appears (e.g. §7 "TV | Heading Text" carries
        # stale desc_col from §6 without this guard).
        if not cells:
            current_desc_cols = []
            current_skip_col_name = None
            continue

        # Separator row: no state change
        if slp.is_table_separator_row(cells):
            continue

        first = cells[0].strip()

        # Header row detection: first cell is "TV" (header text, not a TV-NNN data ID).
        if first.upper() in ("TV", "TV ID", "TV-ID") and len(cells) >= 2:
            if cells[1].strip().upper() in ("EC", "EC ID", "EC-ID"):
                # Recognised TV-section header: collect ALL comparable columns.
                current_desc_cols = []
                current_skip_col_name = None
                for i, cell in enumerate(cells):
                    h = cell.strip().lower()
                    if h in _NON_COMPARABLE:
                        # Track first non-comparable col for audit if no comparable found
                        if current_skip_col_name is None and not current_desc_cols:
                            current_skip_col_name = cell.strip()
                        continue
                    if any(kw in h for kw in _COMPARABLE_KEYWORDS):
                        current_desc_cols.append(i)
            else:
                # BI-057 change (c): unrecognised TV-headed row (e.g. "TV | Heading Text")
                # — reset state to prevent stale column inheritance.
                current_desc_cols = []
                current_skip_col_name = None
            continue

        # Data row: first cell must match TV-NNN identifier pattern.
        # Rows that fail this gate are not TV data rows (e.g. non-TV table headers,
        # prose rows within table blocks).
        if not re.match(r'^TV-[\w]+$', first):
            skipped_no_tv_id += 1
            continue

        # EC ID must be in second cell (BI-044: shared EC grammar).
        # TV-BV013, TV-S001..TV-S016 legitimately have no EC token — counted separately.
        if len(cells) < 2 or not slp.EC_TOKEN_RE.fullmatch(cells[1]):
            skipped_no_ec += 1
            continue

        ec_id = cells[1]

        # Skip rows in sections with no comparable columns (D-132: explicit counting).
        if not current_desc_cols:
            skip_key = current_skip_col_name if current_skip_col_name else "no-description-column"
            skipped_by_col[skip_key] = skipped_by_col.get(skip_key, 0) + 1
            continue

        # BI-057 change (a): concatenate all comparable columns for the scenario description.
        # Columns that are out-of-range or empty are silently skipped.
        # Do NOT include Expected Exit, Expected Verdict/Verdict, or Flags — they are
        # single-token/enumerated values that inflate Jaccard similarity artificially.
        desc_parts = []
        for col_idx in current_desc_cols:
            if col_idx < len(cells):
                part = cells[col_idx].strip()
                if part:
                    desc_parts.append(part)
        desc = " ".join(desc_parts)

        # Extract verdict: scan cells from right to left for a verdict-like value.
        verdict_raw = ""
        for cell in reversed(cells):
            cell_stripped = cell.strip()
            if re.match(r'^(alive|broken|indeterminate|clean|dead|valid)\b',
                        cell_stripped, re.IGNORECASE):
                verdict_raw = cell_stripped
                break

        rows.append((ec_id, desc, verdict_raw, lineno))

    return rows, skipped_by_col, skipped_no_tv_id, skipped_no_ec


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
    # D-132: we track skip counts at every granularity where the checker can skip,
    # so parts provably sum to the whole.
    total_files = sum(1 for _ in SPECS.rglob("*.md"))
    files_scanned = 0

    # Map: ec_id -> list of (source_file, description, verdict_raw, lineno)
    ec_map: dict[str, list[tuple[str, str, str, int]]] = defaultdict(list)

    tv_file_str = str(TV_FILE)

    # D-132 skip counters — TV extraction granularity
    total_tv_skipped_by_col: dict[str, int] = {}   # col_name → rows skipped (no comparable col)
    total_tv_skipped_no_tv_id = 0                   # rows that failed TV-NNN ID gate
    total_tv_skipped_no_ec = 0                      # TV-NNN rows with no valid EC token (TV-BV013, TV-S001..S016)

    # D-132 skip counters — BC extraction granularity
    total_bc_rows_scanned = 0    # total table rows seen in BC files (excluding separators)
    total_bc_rows_parsed = 0     # rows that produced a valid (ec_id, desc) tuple
    total_bc_skipped_no_ec = 0   # rows where first cell was not a valid EC token
    total_bc_skipped_empty = 0   # EC rows where rest_cells was empty

    # BI-057 change (d): checked invariant for other spec files.
    # The "other spec files: no EC citations expected" comment was an unverified
    # assumption.  We now assert it at runtime: any other spec file that produces
    # a parseable EC row is an unexpected citation and fails the checker.
    other_spec_ec_violations: list[str] = []

    for md_file in sorted(SPECS.rglob("*.md")):
        files_scanned += 1
        if BC_DIR in md_file.parents:
            # BC file: scan for EC table rows — track all skip sites (D-132)
            raw_rows = slp.cm_splitlines(md_file.read_text(encoding="utf-8"))
            start = parse_frontmatter_end(raw_rows)
            for raw_lineno, raw_line in enumerate(raw_rows[start:], start=start + 1):
                cells = slp.split_table_cells(raw_line)
                if not cells:
                    continue
                if slp.is_table_separator_row(cells):
                    continue
                # Count every non-separator table row as "scanned"
                total_bc_rows_scanned += 1
                if not slp.EC_TOKEN_RE.fullmatch(cells[0]):
                    total_bc_skipped_no_ec += 1
                    continue
                rest_cells = [c for c in cells[1:] if c and not re.match(r"^-+$", c)]
                if not rest_cells:
                    total_bc_skipped_empty += 1
                    continue
                total_bc_rows_parsed += 1
                ec_id = cells[0]
                desc = rest_cells[0]
                verdict_raw = rest_cells[1] if len(rest_cells) > 1 else ""
                ec_map[ec_id].append((str(md_file), desc, verdict_raw, raw_lineno))
        elif md_file == TV_FILE:
            # test-vectors.md: schema-aware multi-column extraction (BI-057 a/c)
            tv_rows, tv_skipped_by_col, tv_no_id, tv_no_ec = extract_tv_rows(md_file)
            for col_name, cnt in tv_skipped_by_col.items():
                total_tv_skipped_by_col[col_name] = total_tv_skipped_by_col.get(col_name, 0) + cnt
            total_tv_skipped_no_tv_id += tv_no_id
            total_tv_skipped_no_ec += tv_no_ec
            for ec_id, desc, verdict, lineno in tv_rows:
                ec_map[ec_id].append((tv_file_str, desc, verdict, lineno))
        else:
            # BI-057 change (d): assert no parseable EC rows in other spec files.
            # This converts the previous silent assumption into a checked invariant.
            for other_ec_id, other_desc, other_verdict, other_lineno in extract_ec_rows(md_file):
                other_spec_ec_violations.append(
                    f"UNEXPECTED-EC-CITATION {other_ec_id}: {md_file}:{other_lineno} "
                    f"(only BC_DIR and TV_FILE should contain EC rows; "
                    f"add this file to BC_DIR or TV_FILE scope)"
                )

    if files_scanned != total_files:
        print(
            f"ERROR: scanned {files_scanned} of {total_files} spec files — "
            f"corpus-completeness assertion FAILED",
            file=sys.stderr,
        )
        return 1

    if other_spec_ec_violations:
        for msg in other_spec_ec_violations:
            print(msg)
        print(
            f"\nERROR: {len(other_spec_ec_violations)} EC row(s) found in files outside "
            f"BC_DIR and TV_FILE — checked invariant violated (BI-057 change d)"
        )
        return 1

    # D-132 completeness assertion — TV extraction
    total_tv_parsed = sum(1 for occs in ec_map.values() for f, _, _, _ in occs if f == tv_file_str)
    total_tv_skipped_col = sum(total_tv_skipped_by_col.values())
    # Note: total_tv_skipped_no_tv_id counts table rows that are NOT TV-NNN data rows at all
    # (unrecognised rows, non-TV header rows within TV-section tables). These do not contribute
    # EC rows by definition, so they are reported for transparency but not summed into EC totals.

    # D-132 completeness assertion — BC extraction
    bc_check = total_bc_rows_parsed + total_bc_skipped_no_ec + total_bc_skipped_empty
    if bc_check != total_bc_rows_scanned:
        print(
            f"ERROR: D-132 BC-row completeness broken — "
            f"parsed={total_bc_rows_parsed} + skipped_no_ec={total_bc_skipped_no_ec} + "
            f"skipped_empty={total_bc_skipped_empty} = {bc_check} "
            f"!= scanned={total_bc_rows_scanned}",
            file=sys.stderr,
        )
        return 1

    # ── Injectivity check: BC-vs-BC description collision + BC-vs-TV verdict collision ──
    violations: list[str] = []
    collision_ids: set[str] = set()

    # D-132: track how many EC IDs were actually tested for collision (vs single-occurrence skip)
    ecs_tested_collision = 0
    ecs_single_occurrence = 0

    # D-132: track verdict comparison counts
    verdict_comparisons_performed = 0
    verdict_comparisons_skipped_no_bc_verdict = 0

    for ec_id, occurrences in sorted(ec_map.items()):
        if len(occurrences) <= 1:
            ecs_single_occurrence += 1
            continue

        ecs_tested_collision += 1

        # Separate BC-file occurrences from test-vectors.md occurrences
        bc_occs = [(f, d, v, l) for f, d, v, l in occurrences if f != tv_file_str]
        tv_occs = [(f, d, v, l) for f, d, v, l in occurrences if f == tv_file_str]

        has_desc_collision = False
        has_verdict_collision = False
        desc_collision_detail: list[str] = []
        verdict_collision_detail: list[str] = []

        # Description collision: across BC files, independent of verdict column presence.
        if len(bc_occs) > 1:
            groups: dict = {}
            for occ in bc_occs:
                key = normalize_desc(occ[1])
                if key not in groups:
                    groups[key] = []
                groups[key].append(occ)

            if len(groups) > 1:
                norm_descs = list(groups.keys())
                for i in range(len(norm_descs)):
                    if has_desc_collision:
                        break
                    for j in range(i + 1, len(norm_descs)):
                        if descriptions_conflict(norm_descs[i], norm_descs[j]):
                            has_desc_collision = True
                            break

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
                    verdict_comparisons_skipped_no_bc_verdict += 1
                    continue  # BC row has no verdict column — skip verdict comparison
                verdict_comparisons_performed += 1
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
    registry_citations = 0
    registry_divergent: list[tuple] = []
    registry_adjudication: list[tuple] = []
    registry_pass = 0

    # D-132: track per-EC pairing skip (largest blind spot — BI-057 change b)
    ecs_bc_only = 0    # ECs with BC citation(s) but no TV row
    ecs_tv_only = 0    # ECs with TV row(s) but no BC citation
    ecs_compared = 0   # ECs that had both BC and TV rows → entered comparison

    for ec_id, occurrences in sorted(ec_map.items()):
        bc_occs = [(f, d, v, l) for f, d, v, l in occurrences if f != tv_file_str]
        tv_occs = [(f, d, v, l) for f, d, v, l in occurrences if f == tv_file_str]

        if not bc_occs and not tv_occs:
            # Cannot happen (would not be in ec_map), but guard for safety
            continue
        if not bc_occs:
            ecs_tv_only += 1
            continue
        if not tv_occs:
            ecs_bc_only += 1
            continue

        ecs_compared += 1

        for bc_filepath, bc_desc, bc_verdict, bc_lineno in bc_occs:
            # ADVISORY-6: compare against ALL TV rows and take the best (highest-Jaccard) match.
            best_tv_desc = tv_occs[0][1]  # fallback
            best_jaccard_for_tv = -1.0
            for _, tv_desc_cand, _, _ in tv_occs:
                t1_cand = _significant_tokens(tv_desc_cand)
                t2_cand = _significant_tokens(bc_desc)
                union_cand = t1_cand | t2_cand
                j_cand = len(t1_cand & t2_cand) / len(union_cand) if union_cand else 1.0
                if j_cand > best_jaccard_for_tv:
                    best_jaccard_for_tv = j_cand
                    best_tv_desc = tv_desc_cand
            tv_desc = best_tv_desc
            registry_citations += 1
            result = _compare_bc_to_registry(bc_desc, tv_desc)
            t1 = _significant_tokens(tv_desc)
            t2 = _significant_tokens(bc_desc)
            union = t1 | t2
            jaccard = len(t1 & t2) / len(union) if union else 1.0

            # Known tokenizer artifact (BI-057): _significant_tokens() drops punctuation
            # and sub-3-char tokens, so EC-031 ("[x]()" → tokens={}) vs any BC description
            # scores J=0 despite being semantically identical. Route to adjudication rather
            # than divergent so the case is disclosed but not treated as a hard finding.
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

    # D-132 completeness assertion — per-EC pairing
    ecs_paired_total = ecs_bc_only + ecs_tv_only + ecs_compared
    if ecs_paired_total != total_ec_ids:
        print(
            f"ERROR: D-132 per-EC pairing completeness broken — "
            f"bc_only={ecs_bc_only} + tv_only={ecs_tv_only} + compared={ecs_compared} "
            f"= {ecs_paired_total} != total_ec_ids={total_ec_ids}",
            file=sys.stderr,
        )
        return 1

    # D-132 completeness assertion — collision test
    collision_total = ecs_single_occurrence + ecs_tested_collision
    if collision_total != total_ec_ids:
        print(
            f"ERROR: D-132 collision-test completeness broken — "
            f"single_occurrence={ecs_single_occurrence} + tested={ecs_tested_collision} "
            f"= {collision_total} != total_ec_ids={total_ec_ids}",
            file=sys.stderr,
        )
        return 1

    # ── Print results ──────────────────────────────────────────────────────────
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

    # Completeness assertion (corpus-completeness + D-132 multi-granularity)
    completeness = (
        "complete"
        if files_scanned == total_files
        else f"INCOMPLETE — only {files_scanned} of {total_files} scanned"
    )
    total_tv_skipped = total_tv_skipped_col + total_tv_skipped_no_ec
    # Build TV skip detail message (D-132)
    skip_detail_parts = []
    if total_tv_skipped_by_col:
        skip_detail_parts.append(", ".join(
            f"{name} \xd7{cnt}"
            for name, cnt in sorted(total_tv_skipped_by_col.items())
        ))
    if total_tv_skipped_no_ec:
        skip_detail_parts.append(
            f"legitimately-EC-less \xd7{total_tv_skipped_no_ec} "
            f"(TV-BV013 + TV-S001..TV-S016)"
        )
    skip_msg = (
        f"{total_tv_skipped} TV rows skipped "
        f"({'; '.join(skip_detail_parts)})"
        if skip_detail_parts else "no TV rows skipped"
    )

    # D-132 per-EC pairing disclosure
    pairing_msg = (
        f"{ecs_compared} EC IDs compared "
        f"({ecs_bc_only} BC-only, {ecs_tv_only} TV-only, "
        f"{ecs_single_occurrence} single-occurrence skipped)"
    )

    # D-132 verdict and collision disclosure
    verdict_msg = (
        f"{verdict_comparisons_performed} verdict comparisons performed "
        f"({verdict_comparisons_skipped_no_bc_verdict} skipped — no BC verdict column)"
    )
    collision_msg = (
        f"{ecs_tested_collision} EC IDs tested for collision "
        f"({ecs_single_occurrence} single-occurrence not tested)"
    )

    # D-132 BC-row disclosure
    bc_row_msg = (
        f"BC rows: {total_bc_rows_parsed} parsed, "
        f"{total_bc_skipped_no_ec} skipped-no-ec, "
        f"{total_bc_skipped_empty} skipped-empty "
        f"(= {total_bc_rows_scanned} scanned)"
    )

    print(
        f"\n{registry_citations} EC citations compared "
        f"({skip_msg}) "
        f"across {files_scanned} of {total_files} spec files ({completeness}), "
        f"{len(registry_divergent)} divergent, {len(registry_adjudication)} require adjudication"
    )
    print(f"D-132: {pairing_msg}")
    print(f"D-132: {verdict_msg}")
    print(f"D-132: {collision_msg}")
    print(f"D-132: {bc_row_msg}")

    # Exit code: fail on injectivity violations OR divergent BC-vs-registry mismatches
    if violations or registry_divergent:
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
