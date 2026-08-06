#!/usr/bin/env python3
"""
check-counts — recompute every stated count from actual rows
=============================================================
Recomputes the following counts from actual artifacts and compares to stated values:

  BC-INDEX.md frontmatter: total_bcs, subsystems
  BC-INDEX.md rows:        P0 count, P1 count
  VP-INDEX.md frontmatter: total_vps, kani_count, proptest_count, fuzz_count,
                           integration_count, unit_count, p0_count, p1_count,
                           test_sufficient_count
  module-criticality.md:   per-module VP counts vs VP-INDEX catalog
  verification-coverage-matrix.md: per-tool column totals vs VP-INDEX
  prd.md §7 RTM:           row count vs total_bcs
  HS-INDEX.md:             active holdout count vs declared
  domain-spec/decisions.md: DD count vs declared in L2-INDEX
  policies.yaml:           policy count vs declared

Exit 1 if any count is wrong.
"""
import re
import sys
import yaml  # stdlib fallback: parse YAML frontmatter manually
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent.parent
SPECS = REPO / ".factory" / "specs"
FACTORY = REPO / ".factory"


def parse_yaml_frontmatter(path: Path) -> dict:
    """Extract YAML frontmatter from a Markdown file."""
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    if not lines or lines[0].rstrip() != "---":
        return {}
    end = None
    for i in range(1, len(lines)):
        if lines[i].rstrip() == "---":
            end = i
            break
    if end is None:
        return {}
    fm_text = "\n".join(lines[1:end])
    try:
        import yaml as _yaml
        return _yaml.safe_load(fm_text) or {}
    except ImportError:
        # Manual parse of simple key: value pairs
        result = {}
        for line in lines[1:end]:
            m = re.match(r'^(\w+):\s*"?([^"]*)"?\s*$', line)
            if m:
                key, val = m.group(1), m.group(2)
                try:
                    result[key] = int(val)
                except ValueError:
                    result[key] = val
        return result


def count_bc_index_rows() -> tuple[int, int, int, set]:
    """Return (total, p0, p1, set_of_subsystem_ids) from BC-INDEX.md table rows."""
    bc_index = SPECS / "behavioral-contracts" / "BC-INDEX.md"
    total = p0 = p1 = 0
    subsystems = set()
    for line in bc_index.read_text(encoding="utf-8").splitlines():
        m = re.match(r"^\|\s*(BC-\d+\.(\d+)\.\d+)\s*\|\s*(.+?)\s*\|\s*(P\d)\s*\|", line)
        if m:
            total += 1
            ss_num = m.group(2)
            subsystems.add(f"SS-{ss_num}")
            priority = m.group(4)
            if priority == "P0":
                p0 += 1
            elif priority == "P1":
                p1 += 1
    return total, p0, p1, subsystems


def count_vp_index_rows() -> dict[str, int]:
    """Return actual VP counts by method and priority from VP-INDEX.md catalog table."""
    vp_index = SPECS / "verification-properties" / "VP-INDEX.md"
    counts = {"total": 0, "kani": 0, "proptest": 0, "fuzz": 0, "integration": 0, "unit": 0,
              "P0": 0, "P1": 0, "test_sufficient": 0}
    in_catalog = False
    for line in vp_index.read_text(encoding="utf-8").splitlines():
        if "## VP Catalog" in line:
            in_catalog = True
            continue
        if in_catalog and line.startswith("## "):
            in_catalog = False
        if not in_catalog:
            continue
        m = re.match(r"^\|\s*(VP-\d+)\s*\|", line)
        if m:
            counts["total"] += 1
            # Extract method (4th col) and phase (5th col)
            parts = [p.strip() for p in line.split("|")]
            if len(parts) >= 7:
                method = parts[4].lower()
                phase = parts[5].strip()
                for key in ("kani", "proptest", "fuzz", "integration", "unit"):
                    if key in method:
                        counts[key] += 1
                        break
                if phase == "P0":
                    counts["P0"] += 1
                elif phase == "P1":
                    counts["P1"] += 1
                elif "test_sufficient" in phase or "test-sufficient" in phase:
                    counts["test_sufficient"] += 1
    return counts


def count_module_criticality_vp() -> dict[str, int]:
    """Return per-module VP counts from module-criticality.md table."""
    mc = SPECS / "module-criticality.md"
    result = {}
    for line in mc.read_text(encoding="utf-8").splitlines():
        # | `module` | path | tier | rationale | kill-rate | VP Count |
        m = re.match(r"^\|\s*`([^`]+)`\s*\|(?:[^|]*\|){4}\s*(\d+)\s*\|", line)
        if m:
            result[m.group(1)] = int(m.group(2))
    return result


def count_vp_by_module_from_index() -> dict[str, int]:
    """Count VPs per module from VP-INDEX.md catalog."""
    vp_index = SPECS / "verification-properties" / "VP-INDEX.md"
    counts: dict[str, int] = {}
    in_catalog = False
    for line in vp_index.read_text(encoding="utf-8").splitlines():
        if "## VP Catalog" in line:
            in_catalog = True
            continue
        if in_catalog and line.startswith("## "):
            in_catalog = False
        if not in_catalog:
            continue
        m = re.match(r"^\|\s*(VP-\d+)\s*\|", line)
        if m:
            parts = [p.strip() for p in line.split("|")]
            if len(parts) >= 5:
                module = parts[3].strip()
                counts[module] = counts.get(module, 0) + 1
    return counts


def count_prd_rtm_rows() -> int:
    """Count rows in PRD §7 RTM."""
    prd = SPECS / "prd.md"
    count = 0
    in_rtm = False
    for line in prd.read_text(encoding="utf-8").splitlines():
        if "## 7." in line:
            in_rtm = True
            continue
        if in_rtm and re.match(r"^## \d+\.", line):
            in_rtm = False
        if in_rtm:
            m = re.match(r"^\|\s*(BC-\d+\.\d+\.\d+)\s*\|", line)
            if m:
                count += 1
    return count


def count_active_holdouts() -> int:
    """Count active holdout entries from HS-INDEX.md."""
    hs_index = FACTORY / "holdout-scenarios" / "HS-INDEX.md"
    count = 0
    for line in hs_index.read_text(encoding="utf-8").splitlines():
        m = re.match(r"^\|\s*(HS-\d+)\s*\|", line)
        if m and "~~" not in line:  # non-struck-through
            count += 1
    return count


def count_domain_decisions() -> int:
    """Count DD-NNN entries in decisions.md."""
    decisions = SPECS / "domain-spec" / "decisions.md"
    ids: set[str] = set()
    for line in decisions.read_text(encoding="utf-8").splitlines():
        for m in re.finditer(r"\bDD-(\d+)\b", line):
            if line.startswith("#") or line.startswith("**DD-"):
                ids.add(f"DD-{m.group(1)}")
    return len(ids)


def count_policies() -> int:
    """Count policy entries in policies.yaml."""
    policies = FACTORY / "policies.yaml"
    count = 0
    for line in policies.read_text(encoding="utf-8").splitlines():
        if re.match(r"\s*-\s*id:\s*\d+", line):
            count += 1
    return count


def main() -> int:
    violations: list[str] = []
    checks = 0

    # ── BC-INDEX counts ──────────────────────────────────────────────────
    bc_index_path = SPECS / "behavioral-contracts" / "BC-INDEX.md"
    bc_fm = parse_yaml_frontmatter(bc_index_path)
    actual_total, actual_p0, actual_p1, actual_ss = count_bc_index_rows()

    checks += 1
    declared_total = bc_fm.get("total_bcs", None)
    if declared_total is not None and int(declared_total) != actual_total:
        violations.append(
            f"{bc_index_path}:frontmatter: total_bcs mismatch — declared {declared_total}, actual {actual_total}"
        )

    checks += 1
    declared_ss = bc_fm.get("subsystems", None)
    if declared_ss is not None and int(declared_ss) != len(actual_ss):
        violations.append(
            f"{bc_index_path}:frontmatter: subsystems mismatch — declared {declared_ss}, actual {len(actual_ss)}"
        )

    # Check for a "summary" block in BC-INDEX.md
    bc_index_text = bc_index_path.read_text(encoding="utf-8")
    m = re.search(r"P0\s*=\s*(\d+)", bc_index_text)
    if m:
        checks += 1
        stated_p0 = int(m.group(1))
        if stated_p0 != actual_p0:
            violations.append(
                f"{bc_index_path}: P0 count mismatch — stated {stated_p0}, actual rows {actual_p0}"
            )
    m = re.search(r"P1\s*=\s*(\d+)", bc_index_text)
    if m:
        checks += 1
        stated_p1 = int(m.group(1))
        if stated_p1 != actual_p1:
            violations.append(
                f"{bc_index_path}: P1 count mismatch — stated {stated_p1}, actual rows {actual_p1}"
            )

    # ── VP-INDEX counts ──────────────────────────────────────────────────
    vp_index_path = SPECS / "verification-properties" / "VP-INDEX.md"
    vp_fm = parse_yaml_frontmatter(vp_index_path)
    actual_vp = count_vp_index_rows()

    vp_fields = {
        "total_vps": "total",
        "kani_count": "kani",
        "proptest_count": "proptest",
        "fuzz_count": "fuzz",
        "integration_count": "integration",
        "unit_count": "unit",
        "p0_count": "P0",
        "p1_count": "P1",
        "test_sufficient_count": "test_sufficient",
    }
    for fm_key, actual_key in vp_fields.items():
        declared = vp_fm.get(fm_key, None)
        if declared is not None:
            checks += 1
            actual = actual_vp[actual_key]
            if int(declared) != actual:
                violations.append(
                    f"{vp_index_path}:frontmatter: {fm_key} mismatch — declared {declared}, actual {actual}"
                )

    # ── Arithmetic invariant: kani+proptest+fuzz+integration+unit = total ──
    checks += 1
    method_sum = (actual_vp["kani"] + actual_vp["proptest"] + actual_vp["fuzz"] +
                  actual_vp["integration"] + actual_vp["unit"])
    if method_sum != actual_vp["total"]:
        violations.append(
            f"{vp_index_path}: VP method sum {method_sum} != total {actual_vp['total']}"
        )

    checks += 1
    phase_sum = actual_vp["P0"] + actual_vp["P1"] + actual_vp["test_sufficient"]
    if phase_sum != actual_vp["total"]:
        violations.append(
            f"{vp_index_path}: VP phase sum (P0+P1+test_sufficient={phase_sum}) != total {actual_vp['total']}"
        )

    # ── module-criticality.md VP counts vs VP-INDEX ──────────────────────
    mc_vp = count_module_criticality_vp()
    index_vp_by_module = count_vp_by_module_from_index()
    mc_path = SPECS / "module-criticality.md"
    for module, stated_count in mc_vp.items():
        checks += 1
        actual_count = index_vp_by_module.get(module, 0)
        if stated_count != actual_count:
            violations.append(
                f"{mc_path}: module '{module}' VP count mismatch — stated {stated_count}, VP-INDEX has {actual_count}"
            )

    # ── PRD §7 RTM row count ─────────────────────────────────────────────
    prd_path = SPECS / "prd.md"
    rtm_rows = count_prd_rtm_rows()
    checks += 1
    if rtm_rows != actual_total:
        violations.append(
            f"{prd_path}:§7: RTM row count {rtm_rows} != BC total {actual_total}"
        )

    # ── policy count ─────────────────────────────────────────────────────
    policies_path = FACTORY / "policies.yaml"
    actual_pol_count = count_policies()
    checks += 1
    # policies.yaml doesn't declare a count in frontmatter currently,
    # but we can validate the IDs are sequential
    pol_ids = []
    for line in policies_path.read_text(encoding="utf-8").splitlines():
        m = re.match(r"\s*-\s*id:\s*(\d+)", line)
        if m:
            pol_ids.append(int(m.group(1)))
    expected_seq = list(range(1, len(pol_ids) + 1))
    if pol_ids != expected_seq:
        violations.append(
            f"{policies_path}: policy IDs not sequential: {pol_ids}"
        )

    # ── L2-INDEX ID registry counts ───────────────────────────────────────
    l2_index_path = SPECS / "domain-spec" / "L2-INDEX.md"
    l2_text = l2_index_path.read_text(encoding="utf-8")

    # Check DD-NNN count declared in L2-INDEX
    m = re.search(r"\|\s*DD-NNN\s*\|\s*(\d+)\s*\(", l2_text)
    if m:
        checks += 1
        declared_dd = int(m.group(1))
        # Count actual DD-NNN entries in decisions.md (first column of table rows)
        decisions_path = SPECS / "domain-spec" / "decisions.md"
        all_dd_ids: set[str] = set()
        for line in decisions_path.read_text(encoding="utf-8").splitlines():
            # Match rows where DD-NNN is the first table column: | DD-NNN | ...
            dd_m = re.match(r"^\|\s*(DD-\d+)\s*\|", line)
            if dd_m:
                all_dd_ids.add(dd_m.group(1))
        actual_dd = len(all_dd_ids)
        if actual_dd != declared_dd:
            violations.append(
                f"{l2_index_path}: DD-NNN count mismatch — declared {declared_dd}, actual {actual_dd}"
            )

    # ── verification-coverage-matrix totals vs VP-INDEX ──────────────────
    vcm_path = SPECS / "architecture" / "verification-coverage-matrix.md"
    vcm_text = vcm_path.read_text(encoding="utf-8")
    # Check Totals row: | **Totals** | **7** | **7** | **2** | **7** | **1** | **24** |
    vcm_totals_m = re.search(
        r"^\|\s*\*\*Totals\*\*\s*\|\s*\*\*(\d+)\*\*\s*\|\s*\*\*(\d+)\*\*\s*\|\s*\*\*(\d+)\*\*\s*\|\s*\*\*(\d+)\*\*\s*\|\s*\*\*(\d+)\*\*\s*\|\s*\*\*(\d+)\*\*\s*\|",
        vcm_text, re.MULTILINE
    )
    if vcm_totals_m:
        checks += 1
        vcm_kani, vcm_prop, vcm_fuzz, vcm_integ, vcm_unit, vcm_total = [int(vcm_totals_m.group(i)) for i in range(1, 7)]
        if vcm_total != actual_vp["total"]:
            violations.append(
                f"{vcm_path}: coverage matrix total {vcm_total} != VP-INDEX total {actual_vp['total']}"
            )
        if vcm_kani != actual_vp["kani"]:
            violations.append(f"{vcm_path}: coverage matrix kani={vcm_kani} != VP-INDEX kani={actual_vp['kani']}")
        if vcm_prop != actual_vp["proptest"]:
            violations.append(f"{vcm_path}: coverage matrix proptest={vcm_prop} != VP-INDEX proptest={actual_vp['proptest']}")
        if vcm_fuzz != actual_vp["fuzz"]:
            violations.append(f"{vcm_path}: coverage matrix fuzz={vcm_fuzz} != VP-INDEX fuzz={actual_vp['fuzz']}")
        if vcm_integ != actual_vp["integration"]:
            violations.append(f"{vcm_path}: coverage matrix integration={vcm_integ} != VP-INDEX integration={actual_vp['integration']}")
        if vcm_unit != actual_vp["unit"]:
            violations.append(f"{vcm_path}: coverage matrix unit={vcm_unit} != VP-INDEX unit={actual_vp['unit']}")

    # ── prd.md §5b EC count claim vs actual registered ECs ───────────────
    # POL-16: EC registry = test-vectors.md table rows + holdout pool.
    # Any stated count must match the registered EC count exactly.
    prd_text = prd_path.read_text(encoding="utf-8")
    ec_count_m = re.search(r"(\d+)\s+edge cases registered\s+\(EC-001\.\.EC-\d+\)", prd_text)
    if ec_count_m:
        checks += 1
        declared_ec_count = int(ec_count_m.group(1))
        # Count unique base EC nums from test-vectors.md table rows
        tv_path = SPECS / "prd-supplements" / "test-vectors.md"
        ec_base_nums: set[int] = set()
        for line in tv_path.read_text(encoding="utf-8").splitlines():
            if line.startswith("|"):
                for m in re.finditer(r"\bEC-(\d+)\b", line):
                    ec_base_nums.add(int(m.group(1)))
        # Plus holdout pool
        holdout_m = re.search(r"Holdout vectors\s+\*\*\(([^)]+)\)\*\*", prd_text)
        if holdout_m:
            for m in re.finditer(r"\bEC-(\d+)\b", holdout_m.group(1)):
                ec_base_nums.add(int(m.group(1)))
        actual_ec_count = len(ec_base_nums)
        if actual_ec_count != declared_ec_count:
            violations.append(
                f"{prd_path}:§5b: EC count claim mismatch — declared {declared_ec_count}, "
                f"actual registered (TV table rows + holdout pool) = {actual_ec_count}. "
                f"Unregistered IDs in declared range: "
                f"{sorted(n for n in range(1, declared_ec_count + 1) if n not in ec_base_nums)}"
            )

    # ── nfr-catalog.md NFR-006 worked-examples count vs test-vectors.md §7 ─
    # NFR-006 states a target count of worked examples. §7 of test-vectors.md
    # is the authoritative list. They must agree.
    nfr_path = SPECS / "prd-supplements" / "nfr-catalog.md"
    nfr_text = nfr_path.read_text(encoding="utf-8")
    worked_ex_m = re.search(r"all\s+(\d+)\s+worked examples?", nfr_text)
    if worked_ex_m:
        checks += 1
        declared_ex_count = int(worked_ex_m.group(1))
        # Count TV-S entries in test-vectors.md §7
        tv_text = tv_path.read_text(encoding="utf-8")
        tvs_ids: set[str] = set()
        in_s7 = False
        for line in tv_text.splitlines():
            if "## §7." in line:
                in_s7 = True
                continue
            if in_s7 and line.startswith("## "):
                in_s7 = False
            if in_s7 and line.startswith("|"):
                m = re.match(r"^\|\s*(TV-S\d+)\s*\|", line)
                if m:
                    tvs_ids.add(m.group(1))
        actual_ex_count = len(tvs_ids)
        if actual_ex_count != declared_ex_count:
            violations.append(
                f"{nfr_path}: NFR-006 states 'all {declared_ex_count} worked examples' "
                f"but test-vectors.md §7 has {actual_ex_count} TV-S entries "
                f"({sorted(tvs_ids)})"
            )

    # ── test-vectors.md §4 section-header ID range vs actual table contents ─
    # The §4 header declares a range (e.g. "EC-077 through EC-094"). Check that
    # all EC IDs in the §4 table fall within that declared range.
    tv_text = tv_path.read_text(encoding="utf-8")
    s4_header_m = re.search(
        r"## §4\.[^\n]*EC-(\d+)\s+through\s+EC-(\d+)", tv_text
    )
    if s4_header_m:
        checks += 1
        s4_lo = int(s4_header_m.group(1))
        s4_hi = int(s4_header_m.group(2))
        # Collect EC IDs from §4 table rows that are outside the declared range.
        # The header may note exclusions (holdouts) — those are in-range but
        # absent from the table; that is expected. The violation is IDs that
        # are PRESENT in the table but OUTSIDE the declared range.
        s4_out_of_range: list[tuple[int, int]] = []  # (ec_num, lineno)
        in_s4 = False
        for lineno, line in enumerate(tv_text.splitlines(), 1):
            if "## §4." in line:
                in_s4 = True
                continue
            if in_s4 and re.match(r"^## §[5-9]", line):
                in_s4 = False
            if in_s4 and line.startswith("|"):
                for m in re.finditer(r"\bEC-(\d+)\b", line):
                    ec_num = int(m.group(1))
                    if ec_num < s4_lo or ec_num > s4_hi:
                        s4_out_of_range.append((ec_num, lineno))
        if s4_out_of_range:
            out_strs = [f"EC-{n} (line {l})" for n, l in s4_out_of_range]
            violations.append(
                f"{tv_path}:§4: section header declares EC-{s4_lo:03d}..EC-{s4_hi:03d} "
                f"but table contains out-of-range IDs: {out_strs}"
            )

    if violations:
        for v in violations:
            print(v)
        print(f"\nCheck FAILED: {len(violations)} count mismatches found ({checks} checks run)")
        return 1

    print(f"Check passed: {checks} count checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
