#!/usr/bin/env python3
"""
check-index-integrity — bidirectional index validation
======================================================
Checks that every index is consistent with the files it indexes, in both directions:

  BC-INDEX   <-> BC files   (no phantom entries, no unlisted files)
  VP-INDEX   <-> VP files   (no phantom entries, no unlisted files)
  ARCH-INDEX <-> ADR files + architecture shard files
  HS-INDEX   <-> wave-scenarios/ EC files (bidirectional; active + retired entries)
  L2-INDEX   <-> domain spec shard files

Exit 1 if any phantom index entry or unlisted file found.
"""
import os
import re
import sys
from pathlib import Path

REPO = Path(os.environ.get("SPEC_LINT_REPO_OVERRIDE", "")).resolve() if os.environ.get("SPEC_LINT_REPO_OVERRIDE") else Path(__file__).resolve().parent.parent.parent
SPECS = REPO / ".factory" / "specs"
FACTORY = REPO / ".factory"

# ── Column-header positive recognition ────────────────────────────────────────
# _is_column_header() is the ONLY gate that exempts a pre-separator row from
# count_and_classify().  Its failure mode is COUNTING, not skipping — the inverse
# of a D-039 allowlist.
_HEADER_FIRST_CELLS: frozenset[str] = frozenset({"hs id", "hs-id", "hs_id"})


def _is_column_header(l: str) -> bool:
    """Return True iff row l is positively recognised as the HS-INDEX column header.

    Inspects the first cell of the GFM pipe row.  Comparison is case-insensitive;
    leading/trailing whitespace and strikethrough markers (~~ … ~~) are stripped
    before matching against _HEADER_FIRST_CELLS.

    Fail-toward-counting: False → the row is passed to count_and_classify(), not
    silently discarded.  Failing recognition makes the row MORE visible (accounting
    invariant fires), not less.  This is the inverse of a D-039 allowlist:

      - allowlist failure  → row becomes invisible (D-039 violation)
      - _is_column_header failure → row is counted and reported (NOT a D-039 violation)

    The asymmetry is load-bearing: it means every recognition gap produces a
    visible lint error rather than a silent false-pass.
    """
    cells = [c.strip() for c in l.strip("|").split("|")]
    if not cells:
        return False
    first = cells[0].strip("~").strip().lower()
    return first in _HEADER_FIRST_CELLS


def get_bc_index_entries() -> dict[str, str]:
    """Return {bc_id: file_path_from_link} from BC-INDEX.md."""
    bc_index = SPECS / "behavioral-contracts" / "BC-INDEX.md"
    entries: dict[str, str] = {}
    for line in bc_index.read_text(encoding="utf-8").splitlines():
        # | BC-2.SS.NNN | Title | Priority | [ss-NN/BC-2.SS.NNN.md](ss-NN/BC-2.SS.NNN.md) |
        m = re.match(r"^\|\s*(BC-\d+\.\d+\.\d+)\s*\|.*?\[([^\]]+)\]\(([^\)]+)\)\s*\|", line)
        if m:
            entries[m.group(1)] = m.group(3)
    return entries


def get_actual_bc_files() -> set[str]:
    """Return set of BC-S.SS.NNN IDs for all BC files on disk."""
    bc_dir = SPECS / "behavioral-contracts"
    ids: set[str] = set()
    for f in bc_dir.rglob("BC-*.md"):
        if f.name == "BC-INDEX.md":
            continue
        m = re.match(r"(BC-\d+\.\d+\.\d+)\.md$", f.name)
        if m:
            ids.add(m.group(1))
    return ids


def get_vp_index_entries() -> dict[str, str]:
    """Return {vp_id: filename} from VP-INDEX.md catalog."""
    vp_index = SPECS / "verification-properties" / "VP-INDEX.md"
    entries: dict[str, str] = {}
    in_catalog = False
    for line in vp_index.read_text(encoding="utf-8").splitlines():
        if "## VP Catalog" in line:
            in_catalog = True
            continue
        if in_catalog and line.startswith("## "):
            in_catalog = False
        if not in_catalog:
            continue
        m = re.match(r"^\|\s*(VP-\d+)\s*\|\s*([^\|]+)\s*\|", line)
        if m:
            vp_id = m.group(1)
            filename = m.group(2).strip()
            entries[vp_id] = filename
    return entries


def get_actual_vp_files() -> set[str]:
    """Return set of VP-NNN IDs for all VP files on disk."""
    vp_dir = SPECS / "verification-properties"
    ids: set[str] = set()
    for f in vp_dir.glob("vp-*.md"):
        m = re.match(r"vp-(\d+)-", f.name)
        if m:
            ids.add(f"VP-{m.group(1).zfill(3)}")
    return ids


def get_arch_index_documents() -> set[str]:
    """Return set of document filenames from ARCH-INDEX.md Document Map."""
    arch_index = SPECS / "architecture" / "ARCH-INDEX.md"
    docs: set[str] = set()
    in_doc_map = False
    for line in arch_index.read_text(encoding="utf-8").splitlines():
        if "## Document Map" in line:
            in_doc_map = True
            continue
        if in_doc_map and line.startswith("## "):
            in_doc_map = False
        if not in_doc_map:
            continue
        # Match filenames in table cells
        for m in re.finditer(r"\b([\w-]+\.md)\b", line):
            docs.add(m.group(1))
    return docs


def get_actual_arch_files() -> set[str]:
    """Return set of architecture filenames (excluding ARCH-INDEX itself)."""
    arch_dir = SPECS / "architecture"
    files: set[str] = set()
    for f in arch_dir.glob("*.md"):
        if f.name != "ARCH-INDEX.md":
            files.add(f.name)
    return files


def get_adr_index_entries() -> set[str]:
    """Return set of ADR filenames referenced in ARCH-INDEX.md."""
    arch_index = SPECS / "architecture" / "ARCH-INDEX.md"
    adrs: set[str] = set()
    for line in arch_index.read_text(encoding="utf-8").splitlines():
        # ADR table rows: | ADR-NNN | Title | Subsystems |
        m = re.match(r"^\|\s*(ADR-\d+)\b", line)
        if m:
            adrs.add(m.group(1))
    return adrs


def get_actual_adr_files() -> set[str]:
    """Return set of ADR-NNN IDs from actual ADR files."""
    adr_dir = SPECS / "architecture" / "decisions"
    ids: set[str] = set()
    for f in adr_dir.glob("ADR-*.md"):
        m = re.match(r"(ADR-\d+)", f.name)
        if m:
            ids.add(m.group(1))
    return ids



def get_hs_data() -> tuple[dict[str, str], int, list[str]]:
    """Return (hs_mapping, hs_rows_seen, near_misses) for HS-INDEX.md.

    hs_mapping: {hs_id: ec_id} for canonical HS entries (active + retired).
      ec_id may be the sentinel "MALFORMED" if the EC cell is unrecognized.
      Reserved IDs (not-yet-authored) are NOT included.

    hs_rows_seen: count of candidate rows in the Authored Scenarios table.
      Denominator of the D-057 / B-9 accounting invariant.

      A "candidate row" is counted by count_and_classify() for each:
        - In-scope pipe-prefixed post-separator row (normal data rows).
        - In-scope pipe-prefixed pre-separator row NOT positively recognised as
          the column header by _is_column_header() (BLOCKING-2 + D-068-residual
          fix: fail-toward-counting replaces unconditional positional discard).
          Recognition failure → row is counted and classified as a data row,
          making it visible. This is NOT a D-039 violation: the failure mode
          counts (visible), not skips (invisible).
        - In-scope pipeless line containing cell delimiters (MAJOR-1 fix: GFM
          allows leading/trailing pipes to be omitted; such lines are now
          counted and will fire the accounting invariant since none of the pipe-
          anchored classifier patterns can match them).

      NOT counted: heading lines; out-of-scope rows (outside the current h1/h2
      section boundary); separator rows; pre-separator pipe rows positively
      recognised as the column header by _is_column_header() (first cell
      matches "hs id" / "hs-id" / "hs_id", case-insensitive).

      B-11 fix: rows previously bypassed via separator false-match (A2a: empty
      first cell; A2b: dash-only first cell with data in other cells) or via
      the pre-separator shape gate (A1: HS-NNN row placed before the |---|
      separator) are now counted and reported.

    near_misses: list of raw_id strings for each near-miss row (HS-like but
      non-canonical ID). One entry per row; duplicate rows are preserved so the
      accounting invariant can distinguish them from individually reported rows.
      (F-13 fix: replaces the old NEAR_MISS:-keyed dict that silently discarded
      duplicate near-miss rows via key collision.)

    Sentinel values used as ec_id in hs_mapping:
      "MALFORMED" — canonical HS-NNN ID present but EC cell is unrecognized

    B-9 fix: every raw line is stripped of leading/trailing whitespace before
      any matching. A single leading space is semantically neutral in Markdown
      but defeated all ^\| anchors in the prior implementation (BI-023 / B-9).

    F-12 fix: detection is scoped to the ## Authored Scenarios section.

    BLOCKING-1 fix: only h1/h2 headings delimit sections; h3+ subheadings
      within ## Authored Scenarios remain in scope with independent separator
      tracking per sub-table. Prior implementation used startswith("##") which
      matched h3/h4, causing any sub-heading to set in_authored_scenarios=False
      and silently drop every subsequent row before the counter. Now consistent
      with :59 (VP), :91 (ARCH), :308 (L2) which all use startswith("## ").

    BLOCKING-2 fix: pre-separator rows are buffered rather than gated by a
      shape-regex allowlist. When the separator is seen (or at any flush point),
      each buffered row is exempted from count_and_classify() ONLY on positive
      recognition by _is_column_header(). Fail-toward-counting: rows not
      recognised as the column header are counted and classified as data rows,
      making them visible (accounting invariant fires). This is NOT a D-039
      violation: the failure mode counts, not hides.

      D-068 residual closed: the prior unconditional positional discard of
      pending[-1] has been replaced. A phantom data row in the column-header
      position (e.g., the only pre-separator row is "| HS-099 | EC-999 |...")
      is no longer silently discarded — _is_column_header() returns False for
      it, so it is counted and reported.

      Prior implementation used a regex
      (r"^\\|\\s*(?:~~)?(?:HS-\\d+|[Hh][Ss][-_])") that was a D-039-forbidden
      allowlist in disguised form: only HS-shaped pre-separator rows were seen.
    """
    hs_index = FACTORY / "holdout-scenarios" / "HS-INDEX.md"
    mapping: dict[str, str] = {}
    near_misses: list[str] = []
    hs_rows_seen = 0
    # Default True so fixtures without ## headings are processed in full
    # (backward compat for selftest fixtures that omit section headings).
    in_authored_scenarios = True
    found_separator = False  # True once the table header separator row is seen
    pending_pre_sep: list[str] = []  # BLOCKING-2: buffer pre-separator pipe rows

    def count_and_classify(l: str) -> None:
        """Increment hs_rows_seen and classify one in-scope candidate row.

        Counts first, classifies second: hs_rows_seen is incremented before any
        classifier pattern runs, so an unclassified row always fires the
        accounting invariant regardless of its shape.
        """
        nonlocal hs_rows_seen
        hs_rows_seen += 1
        # Active entry: | HS-001 | EC-156 | ...
        m = re.match(r"^\|\s*(HS-\d+)\s*\|\s*(EC-\d+)\s*\|", l)
        if m:
            mapping[m.group(1)] = m.group(2)
            return
        # Retired entry: | ~~HS-002~~ | ~~EC-157~~ | ...
        m = re.match(r"^\|\s*~~(HS-\d+)~~\s*\|\s*~~(EC-\d+)~~\s*\|", l)
        if m:
            mapping[m.group(1)] = m.group(2)
            return
        # Malformed row: canonical HS-NNN cell but EC cell is unrecognized
        # (partial strikethrough, TBD placeholder, etc.).
        m = re.match(r"^\|\s*(?:~~)?(HS-\d+)(?:~~)?\s*\|", l)
        if m:
            mapping[m.group(1)] = "MALFORMED"
            return
        # Near-miss: HS-like but non-canonical ID (wrong case, underscore
        # separator, annotation, trailing junk, etc.). Capture rather than
        # silently skip (BI-023). Already scoped to Authored Scenarios data rows
        # by the in_authored_scenarios guard above.
        m = re.match(r"^\|\s*(?:~~)?([Hh][Ss][-_]\S[^\|]*?)(?:~~)?\s*\|", l)
        if m:
            raw_id = m.group(1).strip().rstrip("~").strip()
            near_misses.append(raw_id)  # F-13: list, preserves duplicate rows
            return
        # Fallthrough: counted but unclassified → accounting invariant fires.

    for raw in hs_index.read_text(encoding="utf-8").splitlines():
        # B-9 fix: strip leading/trailing whitespace before any pattern matching.
        # A single leading space is semantically neutral in Markdown but defeated
        # all ^\| anchors — normalise here rather than widening the anchor.
        line = raw.strip()

        # BLOCKING-1 fix: gate section scope on heading level, not prefix alone.
        # Level 1 (h1) and level 2 (h2) delimit sections; h3+ subheadings stay
        # in scope. Consistent with :59 (VP), :91 (ARCH), :308 (L2) which all
        # use startswith("## "). Prior startswith("##") matched h3/h4 and
        # silently disabled all rows after any sub-heading inside the section.
        if line.startswith("#"):
            level = len(line) - len(line.lstrip("#"))
            if level <= 2:
                # h1/h2: section boundary. Flush any buffered pre-separator rows
                # (section ended without a separator). Fail-toward-counting:
                # count unless positively recognised as the column header.
                for p in pending_pre_sep:
                    if not _is_column_header(p):
                        count_and_classify(p)
                pending_pre_sep = []
                in_authored_scenarios = "Authored Scenarios" in line
                found_separator = False
            else:
                # h3+: sub-heading within section. Stay in scope but reset
                # separator tracking so each sub-table gets fresh buffering.
                # Flush pending (no separator seen). Fail-toward-counting:
                # count unless positively recognised as the column header.
                for p in pending_pre_sep:
                    if not _is_column_header(p):
                        count_and_classify(p)
                pending_pre_sep = []
                found_separator = False
            continue  # headings are never candidate rows

        if not in_authored_scenarios:
            continue

        # MAJOR-1 fix: in-scope pipeless lines with cell delimiters are
        # candidate rows. GFM allows leading/trailing pipes to be omitted.
        # Count them; none of the pipe-anchored patterns below can classify them,
        # so the accounting invariant fires and reports the row as unaccounted.
        if not line.startswith("|"):
            if "|" in line and re.search(r"[^|]\|[^|]", line):
                hs_rows_seen += 1  # counted; unclassified → accounting invariant fires
            continue

        # Detect separator rows via cell-splitting (independent of regex anchors).
        cells = [c.strip() for c in line.strip("|").split("|")]
        first_cell = cells[0].strip("~").strip()
        # B-11 fix (A2a): require non-empty first_cell — set("") is a subset of
        # everything, so the vacuous True for blank ID cells misclassified them
        # as separator rows. B-11 fix (A2b): require ALL non-empty cells to pass,
        # not just first — "| - | EC-999 |" has a separator-like first cell but
        # real data in other cells; it is not a separator row.
        if first_cell and all(set(c) <= set("-: ") for c in cells if c):
            found_separator = True
            # BLOCKING-2: column-header positive recognition. Exempt a row only
            # when _is_column_header() positively recognises it as the column
            # header. Fail-toward-counting: unrecognised rows are counted and
            # classified as data rows (accounting invariant fires). NOT a D-039
            # violation: failure mode is counting (visible), not skipping.
            # D-068 residual closed: the prior `pending[:-1]` unconditional
            # positional discard is gone — a phantom data row in the header
            # position is now counted and reported.
            for p in pending_pre_sep:
                if not _is_column_header(p):
                    count_and_classify(p)
            pending_pre_sep = []
            continue

        # BLOCKING-2: buffer all in-scope pre-separator pipe rows without a
        # shape-based eligibility gate. D-039 forbids allowlists in any
        # disguised form, including a regex deciding which rows are eligible
        # to enter the accounting denominator.
        if not found_separator:
            pending_pre_sep.append(line)
            continue

        # Post-separator data row: count and classify directly.
        count_and_classify(line)

    # Flush any remaining buffered pre-separator rows (end of file or section
    # ended without a separator). Fail-toward-counting: count unless positively
    # recognised as the column header by _is_column_header().
    for p in pending_pre_sep:
        if not _is_column_header(p):
            count_and_classify(p)

    return mapping, hs_rows_seen, near_misses


def get_actual_wave_scenario_ec_ids() -> set[str]:
    """Return set of EC-NNN IDs extracted from wave-scenarios/*.md filenames."""
    hs_dir = FACTORY / "holdout-scenarios" / "wave-scenarios"
    ids: set[str] = set()
    if hs_dir.exists():
        for f in hs_dir.glob("*.md"):
            m = re.match(r"^(EC-\d+)", f.name)
            if m:
                ids.add(m.group(1))
    return ids


def get_l2_index_sections() -> set[str]:
    """Return set of section filenames declared in L2-INDEX.md.

    Parses YAML frontmatter (between the opening and closing --- fences) for
    list items that name .md files, and also scans the Document Map table for
    backtick-quoted filenames.
    """
    l2_index = SPECS / "domain-spec" / "L2-INDEX.md"
    sections: set[str] = set()
    lines = l2_index.read_text(encoding="utf-8").splitlines()

    # Detect frontmatter end by scanning for the closing --- fence
    frontmatter_end = 0  # line index (0-based) of closing ---; 0 = no frontmatter
    if lines and lines[0].rstrip() == "---":
        for i in range(1, len(lines)):
            if lines[i].rstrip() == "---":
                frontmatter_end = i
                break

    # Parse sections: list items from YAML frontmatter only
    for line in lines[1:frontmatter_end]:
        m = re.match(r"^\s*-\s*([\w-]+\.md)\s*$", line)
        if m:
            sections.add(m.group(1))

    # Also check Document Map table
    in_doc_map = False
    for line in lines:
        if "## Document Map" in line:
            in_doc_map = True
            continue
        if in_doc_map and line.startswith("## "):
            in_doc_map = False
        if not in_doc_map:
            continue
        for m in re.finditer(r"`([\w-]+\.md)`", line):
            sections.add(m.group(1))
    return sections


def get_actual_domain_spec_files() -> set[str]:
    """Return set of filenames in domain-spec/ (excluding L2-INDEX.md)."""
    ds_dir = SPECS / "domain-spec"
    files: set[str] = set()
    for f in ds_dir.glob("*.md"):
        if f.name != "L2-INDEX.md":
            files.add(f.name)
    return files


def main() -> int:
    violations: list[str] = []
    checks = 0

    bc_index_path = SPECS / "behavioral-contracts" / "BC-INDEX.md"
    vp_index_path = SPECS / "verification-properties" / "VP-INDEX.md"
    arch_index_path = SPECS / "architecture" / "ARCH-INDEX.md"
    hs_index_path = FACTORY / "holdout-scenarios" / "HS-INDEX.md"
    l2_index_path = SPECS / "domain-spec" / "L2-INDEX.md"

    # Guard: verify required index files exist before proceeding
    required_files = [bc_index_path, vp_index_path, arch_index_path, l2_index_path]
    missing = [str(f) for f in required_files if not f.exists()]
    if missing:
        for m in missing:
            print(f"ERROR: Required index file not found: {m}", file=sys.stderr)
        return 1

    # ── BC-INDEX <-> BC files ────────────────────────────────────────────
    bc_entries = get_bc_index_entries()
    bc_files = get_actual_bc_files()

    checks += 1
    phantom_bcs = set(bc_entries.keys()) - bc_files
    for bc_id in sorted(phantom_bcs):
        violations.append(
            f"{bc_index_path}: BC-INDEX has phantom entry '{bc_id}' — no corresponding file"
        )

    checks += 1
    unlisted_bcs = bc_files - set(bc_entries.keys())
    for bc_id in sorted(unlisted_bcs):
        violations.append(
            f"{bc_index_path}: BC file '{bc_id}' exists but is NOT listed in BC-INDEX"
        )

    # Check that the BC files referenced in index actually exist
    bc_dir = SPECS / "behavioral-contracts"
    for bc_id, rel_path in bc_entries.items():
        full_path = bc_dir / rel_path
        checks += 1
        if not full_path.exists():
            violations.append(
                f"{bc_index_path}: BC-INDEX links to '{rel_path}' which does not exist"
            )

    # ── VP-INDEX <-> VP files ────────────────────────────────────────────
    vp_entries = get_vp_index_entries()
    vp_files = get_actual_vp_files()
    vp_dir = SPECS / "verification-properties"

    checks += 1
    phantom_vps = set(vp_entries.keys()) - vp_files
    for vp_id in sorted(phantom_vps):
        violations.append(
            f"{vp_index_path}: VP-INDEX has phantom entry '{vp_id}' — file not found"
        )

    checks += 1
    unlisted_vps = vp_files - set(vp_entries.keys())
    for vp_id in sorted(unlisted_vps):
        violations.append(
            f"{vp_index_path}: VP file for '{vp_id}' exists but is NOT listed in VP-INDEX"
        )

    # ── ARCH-INDEX <-> ADR files ─────────────────────────────────────────
    adr_entries = get_adr_index_entries()
    adr_files = get_actual_adr_files()

    checks += 1
    phantom_adrs = adr_entries - adr_files
    for adr_id in sorted(phantom_adrs):
        violations.append(
            f"{arch_index_path}: ARCH-INDEX references '{adr_id}' — no corresponding file"
        )

    checks += 1
    unlisted_adrs = adr_files - adr_entries
    for adr_id in sorted(unlisted_adrs):
        violations.append(
            f"{arch_index_path}: ADR file '{adr_id}' exists but is NOT in ARCH-INDEX"
        )

    # ── ARCH-INDEX <-> architecture shard files ──────────────────────────
    arch_docs = get_arch_index_documents()
    actual_arch = get_actual_arch_files()

    checks += 1
    phantom_arch = arch_docs - actual_arch
    for doc in sorted(phantom_arch):
        # Only report if it looks like a spec shard file (not common words)
        if doc.endswith('.md') and len(doc) > 4:
            violations.append(
                f"{arch_index_path}: ARCH-INDEX Document Map lists '{doc}' — file not found in architecture/"
            )

    checks += 1
    unlisted_arch = actual_arch - arch_docs
    for doc in sorted(unlisted_arch):
        violations.append(
            f"{arch_index_path}: architecture file '{doc}' exists but is NOT in ARCH-INDEX Document Map"
        )

    # ── L2-INDEX <-> domain spec shard files ─────────────────────────────
    l2_sections = get_l2_index_sections()
    ds_files = get_actual_domain_spec_files()

    checks += 1
    phantom_shards = l2_sections - ds_files
    for shard in sorted(phantom_shards):
        violations.append(
            f"{l2_index_path}: L2-INDEX declares shard '{shard}' — file not found"
        )

    checks += 1
    unlisted_shards = ds_files - l2_sections
    for shard in sorted(unlisted_shards):
        violations.append(
            f"{l2_index_path}: domain-spec file '{shard}' exists but is NOT in L2-INDEX"
        )

    # ── HS-INDEX <-> wave-scenarios files (bidirectional) ───────────────────
    hs_validated = 0  # D-057: canonical entries that went through the forward check
    hs_rows_seen = 0  # D-057: data rows seen by cell-splitting (accounting invariant)
    if hs_index_path.exists():
        hs_mapping, hs_rows_seen, near_misses = get_hs_data()
        wave_ec_ids = get_actual_wave_scenario_ec_ids()

        # Malformed-cell / near-miss-ID check: HS rows whose ID or EC column is
        # unrecognized. Kept in its own checks+=1 block so a mutation targeting
        # ONLY this block makes test 10d flip independently of the forward check.
        checks += 1
        for real_id in near_misses:
            # Near-miss: HS-like ID that didn't parse as canonical (BI-023 / F-13 fix)
            violations.append(
                f"{hs_index_path}: HS row with non-canonical ID '{real_id}' "
                f"— expected 'HS-<digits>' or '~~HS-<digits>~~'"
            )
        for hs_id, ec_id in sorted(hs_mapping.items()):
            if ec_id == "MALFORMED":
                violations.append(
                    f"{hs_index_path}: HS entry '{hs_id}' has a malformed or unrecognized EC cell "
                    f"(expected 'EC-NNN' or '~~EC-NNN~~')"
                )

        # D-057 / B-9 accounting invariant: every row counted by hs_rows_seen must
        # be accounted for as either a canonical entry or a nonconforming entry.
        # hs_rows_seen is incremented by count_and_classify() BEFORE any classifier
        # pattern runs (D-068 structural fix: count first, classify second), so any
        # row that reaches count_and_classify() but is not matched by the four
        # parser patterns will cause this invariant to fire.
        # Rows NOT covered by this invariant (not passed to count_and_classify()):
        #   - Heading lines (structural markers, never candidate rows)
        #   - Out-of-scope rows (after an h1/h2 section change, BLOCKING-1 fixed:
        #     h3+ subheadings no longer exit scope)
        #   - Separator rows (|---|--- rows, explicitly excluded)
        #   - Pre-separator pipe rows positively recognised as the column header by
        #     _is_column_header() (BLOCKING-2 fixed: no shape-regex gate; D-068
        #     residual closed: no unconditional positional discard). Recognition
        #     failures fail toward counting — unrecognised rows are passed to
        #     count_and_classify(), making them visible. NOT a D-039 violation:
        #     failure mode counts, not hides.
        # B-11: blank/punctuation-only ID cells (A2a, A2b) and HS-pattern rows
        # placed before the separator (A1) are now counted and reported.
        hs_canonical = sum(1 for v in hs_mapping.values() if v != "MALFORMED")
        hs_nonconforming = len(near_misses) + sum(1 for v in hs_mapping.values() if v == "MALFORMED")
        if hs_rows_seen != hs_canonical + hs_nonconforming:
            violations.append(
                f"{hs_index_path}: {hs_rows_seen} data row(s) seen in Authored Scenarios "
                f"table but only {hs_canonical + hs_nonconforming} classified "
                f"({hs_rows_seen - hs_canonical - hs_nonconforming} row(s) unaccounted for "
                f"— parser or whitespace-normalisation mismatch)"
            )

        # Forward check: each authored (non-malformed) HS entry's EC-NNN must have
        # a corresponding wave-scenarios file. Kept in its own checks+=1 block so
        # a mutation targeting ONLY this block makes test 10 flip independently
        # of test 10d.
        checks += 1
        for hs_id, ec_id in sorted(hs_mapping.items()):
            if ec_id == "MALFORMED":
                continue
            hs_validated += 1
            if ec_id not in wave_ec_ids:
                violations.append(
                    f"{hs_index_path}: HS entry '{hs_id}' maps to '{ec_id}' — "
                    f"no wave-scenarios file found for this EC ID"
                )

        # Reverse check: each wave-scenarios file -> has corresponding HS entry
        checks += 1
        hs_ec_ids = {v for v in hs_mapping.values() if v != "MALFORMED"}
        for ec_id in sorted(wave_ec_ids):
            if ec_id not in hs_ec_ids:
                violations.append(
                    f"{hs_index_path}: wave-scenarios file for '{ec_id}' has no "
                    f"corresponding HS-INDEX entry"
                )

        # Duplicate HS-ID check (scan both active and retired canonical rows).
        # Uses raw.strip() to catch duplicates that differ only in leading whitespace.
        checks += 1
        all_hs_ids: list[str] = []
        for raw in hs_index_path.read_text(encoding="utf-8").splitlines():
            m_hs = re.match(r"^\|\s*(?:~~)?(HS-\d+)(?:~~)?\s*\|", raw.strip())
            if m_hs:
                all_hs_ids.append(m_hs.group(1))
        seen: set[str] = set()
        for hs_id in all_hs_ids:
            if hs_id in seen:
                violations.append(
                    f"{hs_index_path}: duplicate HS-INDEX entry '{hs_id}'"
                )
            seen.add(hs_id)

    if violations:
        for v in violations:
            print(v)
        print(
            f"\nCheck FAILED: {len(violations)} index integrity violations found "
            f"({checks} structural checks)"
        )
        return 1

    print(
        f"Check passed: {checks} structural checks — BC ({len(bc_entries)} entries), "
        f"VP ({len(vp_entries)} entries), ADR, ARCH, L2, "
        f"HS ({hs_validated} validated, 0 non-conforming, {hs_rows_seen} rows seen) all consistent"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
