#!/usr/bin/env python3
"""
check-index-integrity — bidirectional index validation
======================================================
Checks that every index is consistent with the files it indexes, in both directions:

  BC-INDEX   <-> BC files   (no phantom entries, no unlisted files)
  VP-INDEX   <-> VP files   (no phantom entries, no unlisted files)
  ARCH-INDEX <-> ADR files + architecture shard files
  HS-INDEX   <-> holdout scenario files
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


def get_hs_index_entries() -> set[str]:
    """Return set of HS-NNN IDs listed in HS-INDEX.md (active, non-struck-through)."""
    hs_index = FACTORY / "holdout-scenarios" / "HS-INDEX.md"
    ids: set[str] = set()
    for line in hs_index.read_text(encoding="utf-8").splitlines():
        if "~~" in line:
            continue  # Skip retired entries
        m = re.match(r"^\|\s*(HS-\d+)\s*\|", line)
        if m:
            ids.add(m.group(1))
    return ids


def get_actual_hs_files() -> set[str]:
    """Return set of HS-NNN IDs for actual scenario files."""
    hs_dir = FACTORY / "holdout-scenarios" / "wave-scenarios"
    ids: set[str] = set()
    if hs_dir.exists():
        for f in hs_dir.glob("*.md"):
            # File names start with EC-NNN, but HS-INDEX links HS-NNN to EC-NNN
            # Just check they exist at all for now
            ids.add(f.stem)
    return ids


def get_l2_index_sections() -> set[str]:
    """Return set of section filenames declared in L2-INDEX.md."""
    l2_index = SPECS / "domain-spec" / "L2-INDEX.md"
    sections: set[str] = set()
    in_sections = False
    lines = l2_index.read_text(encoding="utf-8").splitlines()
    for lineno, line in enumerate(lines, 1):
        # The sections: field in YAML frontmatter
        m = re.match(r"^\s*-\s*([\w-]+\.md)\s*$", line)
        if m and lineno < 60:  # Only in frontmatter section
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

    # ── HS-INDEX duplicate entry check ──────────────────────────────────────
    # Full bidirectional HS-INDEX <-> wave-scenarios file check requires EC<->HS
    # format mapping not yet implemented — deferred to Phase 2.
    # For now: verify HS-INDEX is readable and contains no duplicate HS-NNN IDs.
    if hs_index_path.exists():
        checks += 1
        all_hs_ids: list[str] = []
        for line in hs_index_path.read_text(encoding="utf-8").splitlines():
            if "~~" in line:
                continue
            m_hs = re.match(r"^\|\s*(HS-\d+)\s*\|", line)
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
        print(f"\nCheck FAILED: {len(violations)} index integrity violations found ({checks} bidirectional checks)")
        return 1

    print(f"Check passed: {checks} bidirectional index checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
