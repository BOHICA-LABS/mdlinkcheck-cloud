## Review Cycle 1 Triage — CHECKER-COMPLETENESS-GATE35

**Cycle:** 1
**SHA reviewed:** 879efff417106c05597e4edf8d005c9136c56a67
**Reviewer verdict:** REQUEST_CHANGES

---

### Blocking Findings

| ID | Category | Routed To | Status |
|----|----------|-----------|--------|
| BLOCKING-1 | Test infrastructure (EI-4 vacuous assertion) | OPERATOR — touches `check-ec-injectivity.py` output string | AWAITING OPERATOR |
| BLOCKING-2 | Checker logic (`"link"` in `_COMPARABLE_KEYWORDS` reduces finding surface) | OPERATOR — substantive detection change per D-122 | AWAITING OPERATOR |

**BLOCKING-1 summary:** Selftest EI-4's structural assertion was relaxed from `grep -q "non-comparable TV rows skipped"` to `grep -q "TV rows skipped"`. The zero-skip branch emits `"0 TV rows skipped"` which contains the substring `"TV rows skipped"`, so EI-4 can no longer distinguish a section-was-skipped run from a nothing-was-skipped run. The reviewer independently applied the documented kill mutation (adding `"expected exit"` to `_COMPARABLE_KEYWORDS`) and the suite reported `93/93 green` — the guard is completely vacuous. Fix requires changing the zero-skip branch in `check-ec-injectivity.py` from `"0 TV rows skipped"` to `"no TV rows skipped"` (or similar) and tightening EI-4's grep to `grep -qE "[1-9][0-9]* TV rows skipped"`. This touches a checker file, so routing to operator per constraint 6.

**BLOCKING-2 summary:** The reviewer built a variant reverting only `"link"` back to `_NON_COMPARABLE` and compared live corpus runs. Result: coverage is **identical** (174 citations either way — the 110→174 widening comes entirely from `"filesystem"`, `"heading"`, `"mock server"`, and change c). BUT making `"link"` comparable reduces the finding surface: 11 EC IDs lose all findings (`EC-069, EC-072, EC-073, EC-077, EC-081, EC-082, EC-083, EC-084, EC-089, EC-091, EC-149`), -13 finding lines total. No selftest pins this behavior (reverting `"link"` leaves the suite 93/93). Per D-122, a 20% finding-surface reduction inside a completeness-gate PR requires explicit proof. Routing to operator per constraint 6.

---

### Non-Blocking Findings — Disposition

| ID | Category | Disposition |
|----|----------|-------------|
| WARNING-1 | E-code whitelist unreachable for P2/P3 shapes | DEFERRED — whitelist is currently empty; zero practical impact today. Track as future work when content-remediation workstream registers E-codes. |
| WARNING-2 | `extract_valid_e_class_codes()` reads wrong §1 heading | DEFERRED — returns empty set, same functional result as documented; no false positives or false negatives today. Latent: track as hardening item. |
| WARNING-3 | `total_tv_skipped_no_tv_id` computed but never printed; TV extraction has no completeness assertion | DEFERRED — D-132 is partial in this PR by design; next-step workstream will add full TV assertions. |
| WARNING-4 | D-132 pairing line double-counts (58 single-occurrence ECs appear twice) | DEFERRED — output cosmetic; assertion above is sound. |
| WARNING-5 | Change (d) hard short-circuit blocks all output if `ec-registry.md` ever generated | DEFERRED — `ec-registry.md` absent today; track as pre-condition for generator enablement. |
| WARNING-6 | Changes (c) and (d) have no selftest | DEFERRED — no clean-pass/defect-fail pair for state-reset fix or invariant. |
| WARNING-7 | 5k's E-CLI-001 assertion doesn't independently pin Pattern 3 | DEFERRED — Pattern 3 is independently covered by selftest 5d; risk low. |
| WARNING-8 | BC-row parsing duplicated inline (diverges from shared-primitive direction) | DEFERRED — BI-040 direction; tracked as refactor item. |
| NIT-1 | `E_CLASS_CODE_RE` grammar undocumented | ACKNOWLEDGED — NIT; no action. |
| NIT-2 | EI-7 mutation-kill rationale inaccurate | ACKNOWLEDGED — NIT; no action. |
| NIT-3 | PR description/evidence metadata drift (head SHA, rollback snippet, traceability table) | FIXED — PR description updated with correct head SHA 879efff, updated rollback snippet, corrected traceability. |
| NIT-4 | Diff size exceeds 500-line flag | ACKNOWLEDGED — majority is demo-evidence text; no action. |
| NIT-5 | Selftest 5j relaxed grep is sound | CONFIRMED — no action. |

---

### Next Steps

Cycle 1 is BLOCKED on operator decision for BLOCKING-1 and BLOCKING-2.
- BLOCKING-1 fix is a string wording change + selftest assertion tightening; operator confirmation needed before modifying `check-ec-injectivity.py`.
- BLOCKING-2 fix (drop `"link"` from `_COMPARABLE_KEYWORDS`) is a detection-surface change; operator must decide whether to accept the finding-surface reduction or add a calibration selftest.
