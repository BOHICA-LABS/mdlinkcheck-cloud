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

# ── CommonMark ATX heading and fenced-code-block regexes (D-069 / D-070) ──────
# _CM_HEADING_RE: matches #{1,6} followed by space or EOL (CommonMark §4.2).
# Does NOT match #2, #TODO, #!note, etc.  Used in get_hs_data() to classify
# heading lines.  Combined with a _leading_columns(raw) < 4 guard (D-070), this
# NARROWS the pseudo-heading / fenced-code bypass class (fixtures A/A2/A3 plus
# the tab variant closed by D-070).  The class is NARROWED, not closed; see D-070.
_CM_HEADING_RE = re.compile(r'^(#{1,6})(?:\s|$)')
# _FENCE_RE: matches the start/end of a CommonMark fenced code block (stripped line).
# A fence is 3+ identical backticks or tildes.  CommonMark §4.5 allows 0-3 columns
# of indent; 4+ columns → indented code block (not a fence).  The indent guard is
# applied in get_hs_data() via _leading_columns(raw) < 4 (D-070).
_FENCE_RE = re.compile(r'^(`{3,}|~{3,})')


def _leading_columns(raw: str) -> int:
    """Return the column width of the leading whitespace of ``raw``.

    Expands tabs at 4-column stops per CommonMark §2.1.  A tab at column N
    advances to the next multiple of 4:

        ''       -> 0
        '   '    -> 3   (three spaces)
        '    '   -> 4   (CommonMark code-block threshold)
        '\\t'     -> 4   (tab at column 0 -> next stop = column 4)
        ' \\t'    -> 4   (space at col 1, tab advances to col 4)
        '\\t '    -> 5   (tab -> col 4, then one space)
        '\\t\\t'   -> 8   (two tabs: col 0->4, col 4->8)

    Used by get_hs_data() to guard BOTH the heading test and the fence test
    against the tab-as-indent bypass (D-070).

    NOTE: ``raw.startswith("    ")`` misses ``\\t## X`` because a literal tab is
    not four ASCII spaces even though both occupy 4 columns.  This helper
    closes that gap.
    """
    col = 0
    for ch in raw:
        if ch == ' ':
            col += 1
        elif ch == '\t':
            col = (col // 4 + 1) * 4
        else:
            break
    return col

# ── Column-header positive recognition ────────────────────────────────────────
# _is_column_header() is the ONLY gate that exempts a pre-separator row from
# count_and_classify().  Its failure mode is COUNTING, not skipping — the inverse
# of a D-039 allowlist.
#
# D-069 MINOR-1 fix: the exemption is applied only to pending_pre_sep[-1] (the
# last pre-separator row), not to every pre-separator row that matches.  This
# bounds the exemption to at most one row per table, matching GFM's single-header-
# per-table semantics and restoring the positional safety of the earlier fix while
# retaining the positive-recognition approach.
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

    The asymmetry is load-bearing.  It means every recognition gap produces a
    visible lint error rather than a silent false-pass.

    D-069 MINOR-1: this function is called only on pending_pre_sep[-1] (the last
    pre-separator row).  All earlier pre-separator rows bypass this function and go
    directly to count_and_classify(), regardless of their first-cell content.  A
    hit exempts only that one row; a miss counts and classifies it.  Two consecutive
    pre-separator rows both matching _HEADER_FIRST_CELLS will cause the first to be
    counted and unclassified (B-9 fires), not both silently exempted.
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


def get_hs_data(
    hs_index_path: "Path | None" = None,
) -> "tuple[dict[str, str], int, list[str], int, dict[str, int], list[tuple[int, str]]]":
    """Return (mapping, hs_rows_seen, near_misses, total_candidates, buckets, unclassified).

    D-069 property-based restructure — count first, classify second, universally.

    Every non-blank line increments total_candidates before any predicate examines
    it.  Classification is then exhaustive: each counted line lands in exactly one
    bucket.  The conservation law asserts total_candidates == sum(buckets.values()).

    Bucket inventory
    ────────────────
    heading       CommonMark ATX headings (#{1,6} + space/EOL); < 4 columns of indent;
                  not inside a fenced code block.  D-070: _leading_columns() guard
                  extends the indent check to tab-expanded indent (not just spaces).
    fenced_code   Lines inside or delimiting CommonMark fenced code blocks.  UNBOUNDED
                  SINK: any row that falls inside a fenced block is classified here
                  and is invisible to HS validation, even if it looks like an HS row.
                  Only fences with < 4 columns of indent open this sink (D-070).
    separator     GFM table separator rows: first_cell non-empty, every non-empty cell
                  ⊆ {'-', ':', ' '}.
    column_header Pre-separator pipe row positively recognised by _is_column_header().
                  D-069 MINOR-1 fix: applied ONLY to pending_pre_sep[-1] — at most one
                  row per table is eligible, matching GFM single-header semantics.
    prose         UNBOUNDED SINK: all remaining non-candidate lines — out-of-scope pipe
                  rows, non-pipe in-scope lines without '|', lines in other sections,
                  tab-indented code blocks, indented fences, etc.  A line that lands
                  here is accounted for but invisible to HS validation.
    data_row      In-scope HS candidate rows.  data_row == hs_rows_seen (invariant).

    Conservation law (D-069):
        total_candidates == sum(buckets.values())
    Asserted internally.  A violation signals a parser bug: a line was lost from
    accounting entirely.  This guarantees NO LINE VANISHES from the count, but does
    NOT guarantee correct classification.  A phantom HS row routed to 'prose' or
    'fenced_code' is accounted for but invisible to HS validation — the conservation
    law does not prevent this.  The bypass class is NARROWED (D-069 + D-070), not
    closed; see the D-070 ruling for the residual and the tracking story.
    Tested by the property test (--property-test mode, seed=42 fixed; the generator
    covers structural variety but NOT exhaustive input space — the seed is a
    reproducibility aid, not a completeness proof).

    B-9 accounting invariant (preserved, load-bearing):
        hs_rows_seen == hs_canonical + hs_nonconforming
    Checked in main().  Neutering this check causes multiple selftests to fail.
    unclassified_lines enhances the B-9 violation message with the offending lines.

    Fixes applied in D-069
    ──────────────────────
    BLOCKING-1 / A / A2 / A3 (pseudo-heading / fenced-code bypass) — D-069:
      CommonMark-correct heading detection replaces the prior startswith("#").
      Fix: _CM_HEADING_RE requires space or EOL after the #-run.  4-space-indented
      lines excluded via raw-line check (before strip).  Fenced code blocks tracked
      via _FENCE_RE: lines inside fences are never headings.
      Result: '#2 below', '    ## indented', fenced '# heading' are now prose.

    Tab and indented-fence variants — D-070:
      D-069 used raw.startswith("    ") for the heading indent check: this missed
      '\t## X' because a literal tab is not four ASCII spaces even though CommonMark
      §2.1 expands it to 4 columns.  Similarly, the fence check had no indent guard,
      so '      ```' (6 spaces) opened a fenced_code sink unbounded.
      Fix: _leading_columns(raw) helper expands tabs at 4-column stops; both the
      heading test and the fence test now use _leading_columns(raw) < 4.
      Result: '\t## X' and '      ```' are now prose, never scope-killers or sinks.
      The class is NARROWED by D-069 + D-070, not closed; residual tracked separately.

    MAJOR-1 / B (adjacent-pipe pipeless bypass):
      Prior gate re.search(r"[^|]\\|[^|]") excluded 'HS-099||EC-999' (adjacent
      pipes — no non-pipe on both sides of any single pipe).  Removed entirely.
      New: any in-scope non-pipe line that contains at least one '|' is counted
      as a data_row candidate.  _classify() adds it to unclassified_lines; B-9
      invariant fires.

    MINOR-1 / C (unbounded column-header exemption):
      Prior code called _is_column_header() on every pending_pre_sep row, so two
      consecutive '| HS ID | ... |' rows were both silently exempted.
      Fix: only pending_pre_sep[-1] is passed to _is_column_header(); all earlier
      pending rows always go to count_and_classify() regardless of content.
      Fixture C (two HS-ID pre-separator rows) now exits 1.

    in_authored_scenarios RETAINED (premise verified for D-069):
      The live HS-INDEX contains non-HS pipe rows in ## Reserved IDs (first cell
      EC-NNN, not HS-NNN).  Removing section scope would route those to data_row
      and fire B-9 incorrectly.  Premise verified: no HS-shaped rows (first cell
      matching HS-NNN or near-miss) appear outside ## Authored Scenarios in the
      live file.  With D-069 + D-070 fixes, the heading-detection bypass class that
      enabled section-scope attacks is NARROWED (not closed); see D-070 ruling.
    """
    if hs_index_path is None:
        hs_index_path = FACTORY / "holdout-scenarios" / "HS-INDEX.md"

    mapping: dict[str, str] = {}
    near_misses: list[str] = []
    hs_rows_seen = 0
    total_candidates = 0
    # Bucket counts: every non-blank line maps to exactly one bucket.
    # Conservation law: total_candidates == sum(buckets.values()).
    buckets: dict[str, int] = {
        "heading":       0,
        "fenced_code":   0,
        "separator":     0,
        "column_header": 0,
        "prose":         0,
        "data_row":      0,  # alias: hs_rows_seen
    }
    # Lines counted in data_row but matched no classifier pattern.
    # These cause the B-9 invariant to fire; their line numbers are reported.
    unclassified_lines: list[tuple[int, str]] = []

    in_fenced_code = False
    # Default True so fixtures without ## headings are processed in full
    # (backward compatibility for selftests that omit section headings).
    in_authored_scenarios = True
    found_separator = False
    pending_pre_sep: list[str] = []   # deferred pre-separator pipe rows
    pending_linenos: list[int] = []   # 1-based line numbers for pending rows

    def _classify(l: str, lineno: int) -> None:
        """Classify one in-scope candidate row already counted in data_row.

        Counts first (caller increments hs_rows_seen/data_row before calling),
        classifies second.  A row that matches no pattern is added to
        unclassified_lines; its entry in hs_rows_seen makes B-9 fire:
            hs_rows_seen > hs_canonical + hs_nonconforming.
        This makes every recognition gap loud rather than silent.
        """
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
        # separator, annotation, trailing junk, etc.).
        m = re.match(r"^\|\s*(?:~~)?([Hh][Ss][-_]\S[^\|]*?)(?:~~)?\s*\|", l)
        if m:
            raw_id = m.group(1).strip().rstrip("~").strip()
            near_misses.append(raw_id)
            return
        # Fallthrough: counted in data_row but matched no classifier.
        # Record the (lineno, line) so main() can report WHICH line caused the
        # B-9 mismatch, not just the count delta.
        unclassified_lines.append((lineno, l))

    def _flush_pending() -> None:
        """Flush deferred pre-separator rows into their final buckets.

        D-069 MINOR-1 fix: only pending_pre_sep[-1] is tested by _is_column_header().
        All earlier rows go directly to data_row + _classify(), regardless of their
        first-cell content.  This bounds the column_header exemption to at most one
        row per table.

        Conservation law: each flushed row was already counted in total_candidates
        when first encountered; this function assigns its bucket, keeping the law.
        """
        nonlocal hs_rows_seen
        if not pending_pre_sep:
            return
        # All but the last: always data_row
        for p, ln in zip(pending_pre_sep[:-1], pending_linenos[:-1]):
            hs_rows_seen += 1
            buckets["data_row"] += 1
            _classify(p, ln)
        # Last row: column_header if positively recognised, else data_row
        last_p = pending_pre_sep[-1]
        last_ln = pending_linenos[-1]
        if _is_column_header(last_p):
            buckets["column_header"] += 1
        else:
            hs_rows_seen += 1
            buckets["data_row"] += 1
            _classify(last_p, last_ln)
        pending_pre_sep.clear()
        pending_linenos.clear()

    for lineno, raw in enumerate(
        hs_index_path.read_text(encoding="utf-8").splitlines(), start=1
    ):
        # B-9 fix: strip leading/trailing whitespace before pipe-row matching.
        # A single leading space is semantically neutral in Markdown but defeated
        # all ^\| anchors.
        line = raw.strip()
        if not line:
            continue  # blank lines are not counted
        total_candidates += 1

        # ── Fenced code block (CommonMark §4.5) ──────────────────────────────
        # A fence is 3+ identical backticks or tildes with 0-3 columns of indent.
        # _leading_columns(raw) < 4 enforces the indent bound on the RAW line
        # (before strip).  4+ columns of indent (spaces or tab) → indented code
        # block, NOT a fenced-code-block delimiter (D-070: unguarded-indented-fence
        # bypass closed here).  All lines inside a fenced block land in fenced_code
        # and are never headings, separators, or data rows (fixture A2).
        if _leading_columns(raw) < 4 and _FENCE_RE.match(line):
            in_fenced_code = not in_fenced_code
            buckets["fenced_code"] += 1
            continue
        if in_fenced_code:
            buckets["fenced_code"] += 1
            continue

        # ── CommonMark ATX heading (§4.2) ─────────────────────────────────────
        # A heading is #{1,6} followed by space or EOL; NOT any line starting
        # with '#'.  Excluded cases (all → prose, not heading):
        #   - 4+ COLUMNS of leading indent: _leading_columns(raw) < 4 checked on
        #     the RAW line (before strip), expanding tabs at 4-column stops so both
        #     "    ## foo" (spaces) and "\t## foo" (tab) are excluded (D-070 fix;
        #     the prior raw.startswith("    ") missed the tab case — fixture A3+tab).
        #   - No space after #-run: '#2 below', '#TODO', '#note' (fixture A).
        #   - Inside a fenced code block (handled above, fixture A2).
        if _leading_columns(raw) < 4 and _CM_HEADING_RE.match(line):
            m_h = _CM_HEADING_RE.match(line)
            level = len(m_h.group(1))  # type: ignore[union-attr]
            _flush_pending()
            if level <= 2:
                # h1/h2: section boundary.
                in_authored_scenarios = "Authored Scenarios" in line
                found_separator = False
            else:
                # h3+: sub-heading within section. Stay in scope; reset separator
                # tracking so each sub-table gets fresh pre-separator buffering.
                found_separator = False
            buckets["heading"] += 1
            continue

        # ── Out-of-scope lines → prose ────────────────────────────────────────
        if not in_authored_scenarios:
            buckets["prose"] += 1
            continue

        # ── In-scope non-pipe lines ───────────────────────────────────────────
        if not line.startswith("|"):
            # D-069 MAJOR-1 fix: the prior gate re.search(r"[^|]\|[^|]", line)
            # required a non-pipe character on BOTH sides of some pipe.
            # 'HS-099||EC-999' (adjacent pipes) has no such pair — no non-pipe
            # flanks any single pipe — so it slipped through uncounted.
            # Fix: remove the regex entirely.  Any in-scope non-pipe line that
            # contains at least one '|' is a GFM pipeless-row candidate and goes
            # to data_row.  _classify() will add it to unclassified_lines (none
            # of the four pipe-anchored patterns can match a pipeless line); B-9
            # invariant fires in main().
            if "|" in line:
                hs_rows_seen += 1
                buckets["data_row"] += 1
                _classify(line, lineno)
            else:
                buckets["prose"] += 1
            continue

        # ── Pipe row: detect separator ────────────────────────────────────────
        cells = [c.strip() for c in line.strip("|").split("|")]
        first_cell = cells[0].strip("~").strip()
        # B-11 fix (A2a): require non-empty first_cell — set("") is a subset of
        # everything, so the vacuous True for blank ID cells misclassified them
        # as separator rows. B-11 fix (A2b): require ALL non-empty cells to pass,
        # not just first — "| - | EC-999 |" has a separator-like first cell but
        # real data in other cells; it is not a separator row.
        if first_cell and all(set(c) <= set("-: ") for c in cells if c):
            _flush_pending()
            found_separator = True
            buckets["separator"] += 1
            continue

        # ── Pre-separator pipe row: defer ─────────────────────────────────────
        # All in-scope pre-separator rows are buffered without a shape-based gate.
        # D-039 forbids allowlists; a regex deciding row eligibility is a D-039
        # violation in disguised form.  Bucket assignment is deferred to _flush_pending().
        # total_candidates has already been incremented; conservation law holds at EOF.
        if not found_separator:
            pending_pre_sep.append(line)
            pending_linenos.append(lineno)
            continue

        # ── Post-separator data row ───────────────────────────────────────────
        hs_rows_seen += 1
        buckets["data_row"] += 1
        _classify(line, lineno)

    # EOF flush: process any remaining buffered pre-separator rows.
    _flush_pending()

    # Internal consistency checks (programming-error guards, not input checks).
    assert buckets["data_row"] == hs_rows_seen, (
        f"internal: data_row bucket ({buckets['data_row']}) != hs_rows_seen ({hs_rows_seen})"
    )
    bucket_sum = sum(buckets.values())
    assert total_candidates == bucket_sum, (
        f"D-069 conservation law violated internally: "
        f"total_candidates={total_candidates} != sum(buckets)={bucket_sum}; "
        f"buckets={buckets}"
    )

    return mapping, hs_rows_seen, near_misses, total_candidates, buckets, unclassified_lines


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
    hs_rows_seen = 0  # D-057: data rows seen (denominator of B-9 invariant)
    if hs_index_path.exists():
        (hs_mapping, hs_rows_seen, near_misses,
         total_candidates, hs_buckets, unclassified_lines) = get_hs_data()
        wave_ec_ids = get_actual_wave_scenario_ec_ids()

        # Malformed-cell / near-miss-ID check: HS rows whose ID or EC column is
        # unrecognized. Kept in its own checks+=1 block so a mutation targeting
        # ONLY this block makes test 10d flip independently of the forward check.
        checks += 1
        for real_id in near_misses:
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

        # D-057 / B-9 accounting invariant.
        # hs_rows_seen is incremented BEFORE _classify() runs (count first, classify
        # second), so a row that matches no pattern still appears in the denominator.
        # This invariant fires when any data_row line was not matched by any of the
        # four classifier patterns.
        #
        # Rows NOT in the data_row bucket (not passed to _classify()):
        #   - Heading lines (CommonMark §4.2: #{1,6} + space/EOL, with < 4 COLUMNS
        #     of leading indent — checked via _leading_columns(raw), which expands tabs
        #     at 4-column stops per CommonMark §2.1 so '\t## X' is correctly treated as
        #     4 columns, NOT a heading; the prior raw.startswith("    ") missed this —
        #     D-070 fix).  Also excluded: inside a fenced code block.  D-069 + D-070
        #     NARROW the A/A2/A3/tab bypass class; the class is NARROWED, not closed.
        #     Known residual: Python's str.splitlines() treats \f (form feed) and \v
        #     (vertical tab) as line boundaries; CommonMark does not. '\f## X' and
        #     '\v## X' therefore reach this branch and can kill section scope — verified
        #     at this head. Do NOT fix here (different root cause from indent; ad-hoc
        #     changes opened new holes in three of the prior four rounds). Tracked to a
        #     separate story as a named landing gate.
        #   - Fenced code block lines (D-069 + D-070: tracked via _FENCE_RE with
        #     _leading_columns(raw) < 4 guard; lines inside 0-3-column-indented fences
        #     are fenced_code bucket.  NARROWS the A2 bypass; class is NARROWED, not
        #     closed — 'fenced_code' remains an unbounded sink for any line inside a
        #     fence, including phantom HS rows.)
        #   - Out-of-scope rows (after h1/h2 section change; h3+ subheadings stay in scope)
        #   - Separator rows (|---|--- rows, explicitly excluded)
        #   - The last pre-separator pipe row positively recognised by _is_column_header()
        #     (D-069 MINOR-1: only pending[-1] is eligible — narrows C bypass)
        #   - In-scope non-pipe lines without '|' (prose bucket — unbounded sink)
        #
        # D-069 changes to this invariant:
        #   - Adjacent-pipe pipeless rows ('HS-099||EC-999') now reach data_row and
        #     fire B-9 (prior re.search gate removed — narrows B bypass)
        #   - unclassified_lines detail added to violation message for diagnostics
        #     (does not change the invariant condition — B-9 remains load-bearing)
        hs_canonical = sum(1 for v in hs_mapping.values() if v != "MALFORMED")
        hs_nonconforming = (
            len(near_misses) + sum(1 for v in hs_mapping.values() if v == "MALFORMED")
        )
        if hs_rows_seen != hs_canonical + hs_nonconforming:
            # Include specific unclassified lines in the message for diagnostics.
            detail = ""
            if unclassified_lines:
                items = "; ".join(
                    f"line {ln}: {txt[:50]!r}" for ln, txt in unclassified_lines[:5]
                )
                detail = f" — unclassified: [{items}]"
            violations.append(
                f"{hs_index_path}: {hs_rows_seen} data row(s) seen in Authored Scenarios "
                f"table but only {hs_canonical + hs_nonconforming} classified "
                f"({hs_rows_seen - hs_canonical - hs_nonconforming} row(s) unaccounted for"
                f" — parser or whitespace-normalisation mismatch){detail}"
            )

        # Forward check: each authored (non-malformed) HS entry's EC-NNN must have
        # a corresponding wave-scenarios file.
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


# ── D-069 property test ───────────────────────────────────────────────────────

def _gen_hs_index(rng: "random.Random") -> str:  # type: ignore[name-defined]
    """Generate a diverse HS-INDEX-like markdown document for property testing.

    Varies: heading levels 1-6, pseudo-headings (#run without space), 4-space
    indented '##' (code block), fenced code blocks (``` and ~~~) with heading-
    like and table-like internal lines, pipe arrangements including adjacent pipes
    (||), pipeless rows, strikethrough decoration, bold decoration, empty cells,
    rows above/below/without separators, and out-of-scope sections.
    """
    parts: list[str] = []

    COL_HEADER = "| HS ID | EC ID | Title | Notes | BCs | Status |"
    SEPARATOR  = "|-------|-------|-------|-------|-----|--------|"

    def hs_row(n: int, ec: int) -> str:
        return f"| HS-{n:03d} | EC-{ec:03d} | Title | Notes | BC | active |"

    def retired_row(n: int, ec: int) -> str:
        return f"| ~~HS-{n:03d}~~ | ~~EC-{ec:03d}~~ | Retired | Notes | BC | retired |"

    def near_miss(n: int) -> str:
        return f"| hs_{n:03d} | EC-100 | Near-miss | Notes | BC | active |"

    def pipeless_spaced(n: int, ec: int) -> str:
        return f"HS-{n:03d} | EC-{ec:03d} | Pipeless spaced"

    def pipeless_adjacent(n: int, ec: int) -> str:
        return f"HS-{n:03d}||EC-{ec:03d}"

    pseudo_headings = ["#2 below: wave-2 candidates", "#TODO", "#note", "#1 priority"]
    prose_lines = [
        "Some introductory prose.",
        "This file governs all holdout scenarios.",
        "Notes about the table structure.",
    ]
    fenced_internals = [
        "# heading inside fence",
        "## h2 inside fence",
        "### h3 inside fence",
        f"| HS-{rng.randint(1,9):03d} | EC-{rng.randint(100,199):03d} | Inside fence |",
        "|---|---|---|",
        "plain text inside fence",
    ]

    # Optional h1 title
    if rng.random() < 0.4:
        parts.append(f"# Holdout Scenario Index")

    # Optional prose
    if rng.random() < 0.3:
        parts.append(rng.choice(prose_lines))

    # Main authored scenarios section
    parts.append("")
    parts.append("## Authored Scenarios")
    parts.append("")

    # Optional pseudo-heading (should NOT kill section scope after D-069 fix)
    if rng.random() < 0.5:
        parts.append(rng.choice(pseudo_headings))
        parts.append("")

    # Optional fenced code block (lines inside should be fenced_code, not heading)
    if rng.random() < 0.4:
        fence = rng.choice(["```", "~~~"])
        parts.append(fence)
        for _ in range(rng.randint(1, 3)):
            parts.append(rng.choice(fenced_internals))
        parts.append(fence)
        parts.append("")

    # Optional 4-space indented pseudo-heading (code block, not heading)
    if rng.random() < 0.3:
        parts.append(f"    ## indented-pseudo-heading level-2")
        parts.append("")

    # Column header + optional pre-separator rows + separator
    parts.append(COL_HEADER)
    n_pre = rng.randint(0, 2)
    for _ in range(n_pre):
        choice = rng.randint(0, 3)
        if choice == 0:
            parts.append(hs_row(rng.randint(50, 79), rng.randint(900, 950)))
        elif choice == 1:
            parts.append(f"| **HS-{rng.randint(40,49):03d}** | EC-{rng.randint(900,950):03d} | Bold ID |")
        elif choice == 2:
            parts.append(f"| HS ID | EC-{rng.randint(900,950):03d} | Second header row |")
        else:
            parts.append(f"|  | EC-{rng.randint(900,950):03d} | Empty first cell above sep |")
    parts.append(SEPARATOR)

    # Data rows
    for _ in range(rng.randint(0, 4)):
        choice = rng.randint(0, 6)
        n, ec = rng.randint(1, 20), rng.randint(100, 199)
        if choice == 0:
            parts.append(hs_row(n, ec))
        elif choice == 1:
            parts.append(retired_row(n, ec))
        elif choice == 2:
            parts.append(near_miss(n))
        elif choice == 3:
            parts.append(pipeless_spaced(n, ec))
        elif choice == 4:
            parts.append(pipeless_adjacent(n, ec))
        elif choice == 5:
            parts.append(f"| HS-{n:03d} | MALFORMED-EC | Malformed cell |")
        else:
            parts.append(f"| HS-{n:03d} | EC-{ec:03d} | ~~partially-decorated~~ |")

    # Optional h3 sub-section (stay in scope)
    if rng.random() < 0.3:
        parts.append("")
        h_level = rng.randint(3, 6)
        parts.append("#" * h_level + " Sub-section")
        parts.append("")
        parts.append(COL_HEADER)
        parts.append(SEPARATOR)
        for _ in range(rng.randint(0, 2)):
            parts.append(hs_row(rng.randint(80, 99), rng.randint(500, 599)))

    # Optional non-authored section (out-of-scope pipe rows go to prose)
    if rng.random() < 0.5:
        parts.append("")
        parts.append("## Reserved IDs")
        parts.append("")
        parts.append("| EC ID | Reserved Since | Notes | Status |")
        parts.append("|-------|---------------|-------|--------|")
        parts.append("| EC-079 | prd.md:332 | TBD | not-yet-authored |")

    # Optional additional h2 that re-enters authored scenarios
    if rng.random() < 0.2:
        parts.append("")
        parts.append("## Authored Scenarios")
        parts.append("")
        parts.append(COL_HEADER)
        parts.append(SEPARATOR)
        parts.append(hs_row(rng.randint(90, 99), rng.randint(600, 699)))

    # Optional heading levels 4-6 to exercise level detection
    if rng.random() < 0.2:
        parts.append("")
        level = rng.randint(4, 6)
        parts.append("#" * level + " Deep sub-heading")

    return "\n".join(parts)


def run_property_test(n_cases: int = 300) -> int:
    """D-069 property test: assert conservation law for n_cases generated inputs.

    For every generated HS-INDEX-like document:
        total_candidates == sum(buckets.values())
    where both values are returned by get_hs_data().

    This property asserts that no non-blank line vanishes from the accounting,
    regardless of the structural variety of the input.  A violation means a line
    was counted in total_candidates but not assigned to any bucket — a parser bug.

    Generator: stdlib random.Random(seed=42), deterministic and reproducible.
    Does not require wave-scenarios files to exist; get_hs_data() is called with
    an explicit hs_index_path so the full checker tree is not needed.

    Reports: cases generated, pass/fail per failure, final result.
    """
    import random
    import tempfile

    rng = random.Random(42)
    failures = 0

    print(f"D-069 property test: generating {n_cases} cases (seed=42)...")
    for case_num in range(1, n_cases + 1):
        content = _gen_hs_index(rng)
        # Write to a temp file and call get_hs_data() with explicit path.
        # We only need get_hs_data() to parse the text; the forward/reverse
        # checks are not exercised here (wave-scenarios files don't exist).
        with tempfile.NamedTemporaryFile(
            suffix=".md", mode="w", encoding="utf-8", delete=False
        ) as fh:
            fh.write(content)
            tmppath = Path(fh.name)
        try:
            _, hs_rows_seen, _, total_candidates, buckets, _ = get_hs_data(tmppath)
            bucket_sum = sum(buckets.values())
            if total_candidates != bucket_sum:
                # The internal assert in get_hs_data() would have fired first;
                # this branch is a belt-and-suspenders check.
                print(
                    f"  PROPERTY FAIL case {case_num}: "
                    f"total_candidates={total_candidates} != sum(buckets)={bucket_sum} "
                    f"buckets={buckets}"
                )
                print(f"  Content excerpt: {content[:300]!r}")
                failures += 1
            elif hs_rows_seen != buckets["data_row"]:
                print(
                    f"  PROPERTY FAIL case {case_num}: "
                    f"hs_rows_seen={hs_rows_seen} != buckets['data_row']={buckets['data_row']}"
                )
                failures += 1
        except AssertionError as exc:
            print(f"  PROPERTY FAIL case {case_num}: internal assert fired: {exc}")
            print(f"  Content excerpt: {content[:300]!r}")
            failures += 1
        finally:
            tmppath.unlink(missing_ok=True)

    if failures:
        print(
            f"\nProperty test FAILED: {failures}/{n_cases} cases violated the conservation law"
        )
        return 1
    print(
        f"Property test passed: {n_cases}/{n_cases} cases verified "
        f"(total_candidates == sum(buckets) for all inputs, seed=42)"
    )
    return 0


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--property-test":
        n = int(sys.argv[2]) if len(sys.argv) > 2 else 300
        sys.exit(run_property_test(n))
    sys.exit(main())
