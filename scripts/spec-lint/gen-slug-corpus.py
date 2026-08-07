#!/usr/bin/env python3
"""
gen-slug-corpus — regenerate VP-018's SLUG_CORPUS from test-vectors.md §7
==========================================================================
Reads all 16 TV-S slug algorithm vectors from test-vectors.md §7 and emits
the corresponding entries into vp-018-slug-worked-examples.md between:

  // @GENERATED:BEGIN slug-corpus
  // @GENERATED:END slug-corpus

On first run (markers absent): inserts the block just before the closing "];".
On re-runs (markers present): replaces content between the markers.

Additionally generates two test functions between:

  // @GENERATED:BEGIN slug-sequence-tests
  // @GENERATED:END slug-sequence-tests

Covering:
  vp018_tv_s001_s002_s003_foo_sequence  — TV-S001/S002/S003 (shared counter)
  vp018_tv_s012_foo_collision           — TV-S012 (collision-bumping, DEC-001)

The three hand-authored functions (vp018_slug_corpus_exact_match,
vp018_dec001_collision_bump, vp018_duplicate_heading_counter_0_based) and the
Phase-3 integration skeleton are NEVER touched.

READ-ONLY with respect to canonical-facts.toml — never writes to that file.

DEFAULT-SAFE POLICY (concurrency gate):
  Bare invocation with no arguments does NOT write. A concurrent editor may
  hold .factory/specs/ at any time, and an accidental bare invocation is a
  realistic failure mode. Explicit opt-in required: use --write to enable
  write mode. --check and --dry-run are always available without opt-in.

Usage:
  python3 gen-slug-corpus.py [--check] [--dry-run] [--write]

--check mode: regenerates VP-018 content in memory, compares byte-for-byte
  against the committed artifact, exits 0 if identical, exits 1 with a
  unified diff if different. Never writes.
  NOTE: --check currently returns FAIL on the live tree with 2 cosmetic diffs
  (whitespace alignment on the END marker; no content dropped). This divergence
  is safe to regenerate when the concurrency gate is lifted.

--dry-run mode: previews what would be written without modifying VP-018.

--write mode: explicit opt-in for write mode.
"""
import difflib
import re
import sys
from pathlib import Path
import spec_lint_primitives as slp

REPO = slp.find_repo_root(start=Path(__file__).resolve().parent)  # honors SPEC_LINT_REPO_OVERRIDE
SPECS = REPO / ".factory" / "specs"
TV_FILE = SPECS / "prd-supplements" / "test-vectors.md"
VP_018 = SPECS / "verification-properties" / "vp-018-slug-worked-examples.md"

BEGIN_CORPUS = "// @GENERATED:BEGIN slug-corpus"
END_CORPUS = "// @GENERATED:END slug-corpus"
BEGIN_TESTS = "// @GENERATED:BEGIN slug-sequence-tests"
END_TESTS = "// @GENERATED:END slug-sequence-tests"


# ──────────────────────────────────────────────────────────────────────────────
# TV-S parsing helpers
# ──────────────────────────────────────────────────────────────────────────────

def strip_cell(cell: str) -> str:
    """Remove surrounding whitespace from a Markdown table cell."""
    return cell.strip()


def extract_tv_section(tv_path: Path) -> str:
    """Return the text of §7 up to the next '---' separator."""
    text = tv_path.read_text(encoding="utf-8")
    m = re.search(r"^## §7\.", text, re.MULTILINE)
    if not m:
        print("ERROR: §7 not found in test-vectors.md", file=sys.stderr)
        sys.exit(1)
    section = text[m.end():]
    end = section.find("\n---")
    if end != -1:
        section = section[:end]
    return section


def parse_tv_s_entries(tv_path: Path) -> list[dict]:
    """
    Parse §7 rows.  Returns a list of dicts:
      {id, heading_raw, slug_raw, source_raw}
    """
    section = extract_tv_section(tv_path)
    entries: list[dict] = []
    for line in slp.cm_splitlines(section):
        m = re.match(r"^\|\s*(TV-S\d+)\s*\|([^|]+)\|([^|]+)\|([^|]+)\|", line)
        if not m:
            continue
        entries.append({
            "id":          m.group(1).strip(),
            "heading_raw": m.group(2).strip(),
            "slug_raw":    m.group(3).strip(),
            "source_raw":  m.group(4).strip(),
        })
    return entries


# ──────────────────────────────────────────────────────────────────────────────
# Entry classification
# ──────────────────────────────────────────────────────────────────────────────

def classify_entry(entry: dict) -> str:
    """
    Returns one of:
      "fresh"     — goes into SLUG_CORPUS (fresh DuplicateCounter per row)
      "sequence"  — goes into the foo-sequence test function only
      "collision" — goes into the foo-collision test function only
    """
    hr = entry["heading_raw"]
    if re.search(r"second occurrence|third occurrence", hr, re.IGNORECASE):
        return "sequence"
    if re.search(r"\(collision\)", hr, re.IGNORECASE):
        return "collision"
    return "fresh"


def extract_heading_text(entry: dict) -> str:
    """
    Returns the heading text string to use as input for compute_slug.
    Handles:
      - double-backtick cells (TV-S010): ``content``  → content
      - rendered-text note: '(rendered text: `X`)' → X
      - 'Only `X` from...' expected slug → X as heading input
      - normal single-backtick: `content`  → content
      - parenthetical notes stripped
    """
    hr = entry["heading_raw"]
    sr = entry["slug_raw"]

    # Double-backtick Markdown cell (e.g. `` `--online` flag ``)
    m = re.match(r"^``(.+?)``$", hr)
    if m:
        inner = m.group(1).strip()
        # inner is e.g. "`--online` flag" — a code span inside heading
        # The rendered text of a code span keeps the text: strip the backtick marks
        rendered = re.sub(r"`([^`]+)`", r"\1", inner).strip()
        return rendered

    # Rendered text override: '(rendered text: `X`)'
    m = re.search(r"\(rendered text:\s*`([^`]+)`\)", hr)
    if m:
        return m.group(1)

    # 'Only `X` from ...' expected slug: heading text is X
    m = re.match(r"^Only `([^`]+)` from\b", sr)
    if m:
        # The heading text cell gives us the markdown heading text; the expected
        # slug note tells us the result. Extract the HEADING TEXT from first backtick.
        first_bt = re.match(r"`([^`]+)`", hr)
        if first_bt:
            # e.g. `## setup` → heading text is "setup" (strip the ## marker)
            raw = first_bt.group(1)
            # If it looks like a markdown heading (## ...), strip the hashes
            raw = re.sub(r"^#+\s*", "", raw).strip()
            return raw

    # Normal first backtick-wrapped content with optional trailing note
    m = re.match(r"`([^`]+)`", hr)
    if m:
        text = m.group(1)
        # Some cells include the full heading syntax (e.g. `## Done ✅`).
        # Strip leading markdown heading markers so we get the heading TEXT.
        text = re.sub(r"^#+\s+", "", text)
        return text

    # Collision: multiple backtick items — return the first
    m = re.search(r"`([^`]+)`", hr)
    if m:
        return m.group(1)

    return hr


def extract_expected_slug(entry: dict) -> str:
    """
    Returns the expected slug string.
    Handles:
      - 'Only `X` from ...'  → X
      - normal backtick:  `X`  → X
    """
    sr = entry["slug_raw"]
    m = re.match(r"^Only `([^`]+)` from\b", sr)
    if m:
        return m.group(1)
    m = re.match(r"`([^`]+)`", sr)
    if m:
        return m.group(1)
    return sr


def collision_triple(entries: list[dict]) -> tuple[str, list[tuple[str, str]]]:
    """Return (tv_id, [(heading, slug), ...]) for TV-S012."""
    for e in entries:
        if classify_entry(e) == "collision":
            tv_id = e["id"]
            hr = e["heading_raw"]
            sr = e["slug_raw"]
            # e.g.: `Foo`, `Foo`, `Foo-1` (collision)
            headings = [m.group(1) for m in re.finditer(r"`([^`]+)`", hr)]
            slugs    = [m.group(1) for m in re.finditer(r"`([^`]+)`", sr)]
            return tv_id, list(zip(headings, slugs))
    return "", []


def sequence_triple(entries: list[dict]) -> tuple[list[str], list[str], list[str]]:
    """
    Return ([tv_ids], [heading_texts], [expected_slugs]) for TV-S001/S002/S003.
    Includes TV-S001 (first occurrence) plus shared-counter siblings.
    """
    ids: list[str] = []
    texts: list[str] = []
    slugs: list[str] = []
    for e in entries:
        tid = e["id"]
        cls = classify_entry(e)
        if cls == "fresh" and tid == "TV-S001":
            ids.append(tid)
            texts.append(extract_heading_text(e))
            slugs.append(extract_expected_slug(e))
        elif cls == "sequence":
            ids.append(tid)
            texts.append(extract_heading_text(e))
            slugs.append(extract_expected_slug(e))
    return ids, texts, slugs


# ──────────────────────────────────────────────────────────────────────────────
# Code generation
# ──────────────────────────────────────────────────────────────────────────────

def align(s: str, width: int) -> str:
    return s.ljust(width)


def _rust_str(s: str) -> str:
    """Escape a string for use as a Rust double-quoted string literal."""
    return s.replace("\\", "\\\\").replace('"', '\\"')


def gen_corpus_block(entries: list[dict]) -> str:
    """
    Generate the // @GENERATED:BEGIN slug-corpus ... // @GENERATED:END block.
    Only fresh-counter entries.
    """
    rows = []
    for e in entries:
        if classify_entry(e) != "fresh":
            continue
        tv_id = e["id"]
        heading = extract_heading_text(e)
        expected = extract_expected_slug(e)
        # Build the source note comment
        source = e["source_raw"].split()[0]   # first token (DD-015, DEC-001, etc.)
        rows.append((tv_id, heading, expected, source))

    if not rows:
        return f"{BEGIN_CORPUS}\n{END_CORPUS}"

    # Compute alignment widths
    max_h = max(len(f'"{_rust_str(h)}"') for _, h, _, _ in rows)
    max_e = max(len(f'"{_rust_str(e)}"') for _, _, e, _ in rows)
    col_h = max(max_h, 20)
    col_e = max(max_e, 12)

    lines = [BEGIN_CORPUS]
    for tv_id, heading, expected, source in rows:
        h_lit = f'"{_rust_str(heading)}"'
        e_lit = f'"{_rust_str(expected)}"'
        line = f"    ({align(h_lit, col_h)}, {align(e_lit, col_e)}),  // {tv_id}"
        lines.append(line)
    lines.append(END_CORPUS)
    return "\n".join(lines)


def gen_sequence_tests(seq_ids: list[str], seq_texts: list[str], seq_slugs: list[str]) -> str:
    """
    Generate the @GENERATED:BEGIN slug-sequence-tests block.
    Contains vp018_tv_s001_s002_s003_foo_sequence and vp018_tv_s012_foo_collision.
    """
    ids_str = "/".join(seq_ids)
    tv_s012_id = "TV-S012"

    # Heading text for the sequence (all three should be the same base, e.g., "Foo")
    base_text = seq_texts[0] if seq_texts else "Foo"

    assertions_seq = []
    for tv_id, text, slug in zip(seq_ids, seq_texts, seq_slugs):
        msg = f"{tv_id}: {'1st' if tv_id == seq_ids[0] else ('2nd' if seq_ids.index(tv_id) == 1 else '3rd')} {text}"
        assertions_seq.append(
            f'    assert_eq!(compute_slug("{_rust_str(text)}", &mut counter), "{_rust_str(slug)}", "{msg}");'
        )
    seq_body = "\n".join(assertions_seq)

    block = f"""\
{BEGIN_TESTS}

/// {ids_str}: three occurrences of "{base_text}" with shared counter (TV-S002 needs -1, TV-S003 needs -2)
#[test]
fn vp018_tv_s001_s002_s003_foo_sequence() {{
    let mut counter = DuplicateCounter::new();
{seq_body}
}}

/// {tv_s012_id}: Foo / Foo / Foo-1 collision with shared counter (DEC-001 / dd-015)
/// The 3rd heading "Foo-1" has base slug "foo-1"; "foo-1" is already taken by the
/// 2nd "Foo" → while-loop bumps to "foo-1-1".
#[test]
fn vp018_tv_s012_foo_collision() {{
    let mut counter = DuplicateCounter::new();
    assert_eq!(compute_slug("Foo",   &mut counter), "foo",     "{tv_s012_id}.1: first Foo");
    assert_eq!(compute_slug("Foo",   &mut counter), "foo-1",   "{tv_s012_id}.2: second Foo");
    assert_eq!(compute_slug("Foo-1", &mut counter), "foo-1-1", "{tv_s012_id}.3: Foo-1 collides");
}}

{END_TESTS}"""
    return block


# ──────────────────────────────────────────────────────────────────────────────
# VP-018 surgery
# ──────────────────────────────────────────────────────────────────────────────

def update_corpus_in_vp018(content: str, corpus_block: str) -> str:
    """
    Insert or replace the @GENERATED slug-corpus block inside the SLUG_CORPUS array.
    Locates the closing `];` of the SLUG_CORPUS and places the block just before it.
    """
    begin_pat = re.compile(re.escape(BEGIN_CORPUS) + r".*?" + re.escape(END_CORPUS), re.DOTALL)

    if BEGIN_CORPUS in content:
        # Replace existing block
        new_content, n = begin_pat.subn(corpus_block, content)
        if n == 0:
            print("  WARNING: slug-corpus markers found but replacement failed", file=sys.stderr)
        return new_content

    # No markers — insert just before the closing `];` of SLUG_CORPUS
    # Find the const SLUG_CORPUS declaration
    corpus_decl = re.search(r"const SLUG_CORPUS.*?&\[", content, re.DOTALL)
    if not corpus_decl:
        print("  ERROR: SLUG_CORPUS not found in VP-018", file=sys.stderr)
        return content

    # Find `];` after the declaration
    after_decl = content[corpus_decl.end():]
    close = re.search(r"\n\];", after_decl)
    if not close:
        print("  ERROR: closing `];` of SLUG_CORPUS not found", file=sys.stderr)
        return content

    insert_at = corpus_decl.end() + close.start()
    insertion = f"\n    {corpus_block.replace(chr(10), chr(10) + '    ')}"
    return content[:insert_at] + "\n" + corpus_block + content[insert_at:]


def update_tests_in_vp018(content: str, tests_block: str) -> str:
    """
    Insert or replace the @GENERATED slug-sequence-tests block.

    Placement strategy (in order of preference):
    1. Replace between existing markers.
    2. Insert after vp018_dec001_collision_bump closing brace (before the next ```).
    3. Insert after the closing ``` of the first rust block.
    """
    begin_pat = re.compile(re.escape(BEGIN_TESTS) + r".*?" + re.escape(END_TESTS), re.DOTALL)

    if BEGIN_TESTS in content:
        new_content, n = begin_pat.subn(tests_block, content)
        if n == 0:
            print("  WARNING: slug-sequence-tests markers found but replacement failed", file=sys.stderr)
        return new_content

    # Find vp018_dec001_collision_bump closing brace
    dec001_end = re.search(r"fn vp018_dec001_collision_bump\b.*?\n\}", content, re.DOTALL)
    if dec001_end:
        insert_at = dec001_end.end()
        return content[:insert_at] + "\n\n" + tests_block + "\n" + content[insert_at:]

    # Fallback: after the first closing ``` of the proof harness block
    proof_block = re.search(r"## Proof Harness Skeleton.*?^```\s*$", content, re.DOTALL | re.MULTILINE)
    if proof_block:
        insert_at = proof_block.end()
        return content[:insert_at] + "\n\n" + tests_block + "\n" + content[insert_at:]

    print("  WARNING: could not find insertion point for sequence tests", file=sys.stderr)
    return content


# ──────────────────────────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────────────────────────

def main() -> int:
    check_mode = "--check" in sys.argv
    dry_run = "--dry-run" in sys.argv
    write_mode = "--write" in sys.argv

    # ── CONCURRENCY SAFETY GATE (bare-invocation default-safe) ────────────────
    # Bare invocation must not write. A concurrent editor may hold .factory/specs/
    # at any time; an accidental bare invocation is a realistic failure mode.
    # Explicit --write opt-in required to proceed to write mode. --check and
    # --dry-run are always available without opt-in (D-039: no bypass flag).
    #
    # Mutation-verify: removing this block causes bare invocation to write VP-018,
    # flipping selftest 28's file-identical assertion to FAIL.
    if not check_mode and not dry_run and not write_mode:
        print(
            "gen-slug-corpus: bare invocation does not write.\n"
            "  A concurrent editor may hold .factory/specs/ and accidental bare\n"
            "  invocation is a realistic failure mode. Explicit opt-in required.\n"
            "  Use --write to enable write mode.\n"
            "  Use --check to verify without writing (non-destructive).\n"
            "  Use --dry-run to preview without writing.",
            file=sys.stderr,
        )
        return 1

    if not TV_FILE.exists():
        print(f"ERROR: test-vectors.md not found at {TV_FILE}", file=sys.stderr)
        sys.exit(1)
    if not VP_018.exists():
        print(f"ERROR: VP-018 not found at {VP_018}", file=sys.stderr)
        sys.exit(1)

    entries = parse_tv_s_entries(TV_FILE)
    if not entries:
        print("ERROR: no TV-S entries parsed from test-vectors.md §7", file=sys.stderr)
        sys.exit(1)

    corpus_block = gen_corpus_block(entries)
    seq_ids, seq_texts, seq_slugs = sequence_triple(entries)
    tests_block = gen_sequence_tests(seq_ids, seq_texts, seq_slugs)

    content = VP_018.read_text(encoding="utf-8")
    new_content = update_corpus_in_vp018(content, corpus_block)
    new_content = update_tests_in_vp018(new_content, tests_block)

    if check_mode:
        # Compare byte-for-byte; never write.
        if new_content == content:
            rel = str(VP_018.relative_to(REPO))
            print(f"gen-slug-corpus --check: OK — {rel} matches generated output")
            return 0
        rel = str(VP_018.relative_to(REPO))
        diff_lines = list(difflib.unified_diff(
            content.splitlines(keepends=True),
            new_content.splitlines(keepends=True),
            fromfile=rel,
            tofile=f"{rel} (generated)",
        ))
        print(f"gen-slug-corpus --check: FAIL — {rel} differs from generated output")
        sys.stdout.writelines(diff_lines)
        return 1

    if new_content == content:
        fresh = [e for e in entries if classify_entry(e) == "fresh"]
        print(f"Parsed {len(entries)} TV-S entries from test-vectors.md §7")
        print(f"  {len(fresh)} fresh-counter entries → SLUG_CORPUS")
        print(f"  {len([e for e in entries if classify_entry(e) == 'sequence'])} sequence entries → foo-sequence test")
        print(f"  {len([e for e in entries if classify_entry(e) == 'collision'])} collision entries → foo-collision test")
        print("VP-018 already up to date — no changes needed")
        return 0

    fresh = [e for e in entries if classify_entry(e) == "fresh"]
    print(f"Parsed {len(entries)} TV-S entries from test-vectors.md §7")
    print(f"  {len(fresh)} fresh-counter entries → SLUG_CORPUS")
    print(f"  {len([e for e in entries if classify_entry(e) == 'sequence'])} sequence entries → foo-sequence test")
    print(f"  {len([e for e in entries if classify_entry(e) == 'collision'])} collision entries → foo-collision test")

    if not seq_ids:
        print("WARNING: no sequence entries found for TV-S001/S002/S003", file=sys.stderr)

    if dry_run:
        print("DRY-RUN: would update VP-018 (no file written)")
    elif write_mode:
        VP_018.write_text(new_content, encoding="utf-8")
        print(f"Updated {VP_018}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
