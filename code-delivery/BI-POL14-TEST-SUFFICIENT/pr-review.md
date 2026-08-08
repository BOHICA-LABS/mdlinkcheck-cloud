# PR Review — PR #9 @ `87cefbf00342b583840c3c11a7c530d9548a4b5c`

**Recommendation: CHANGES-NEEDED** (recommendation only — merge decision belongs to the human operator; BI-046 open).

Reviewed independently: diff re-read, all claimed figures re-run, 8 mutations applied (3 claimed + 5 reviewer-added), and 13 behavioural boundary probes executed against isolated temp trees. No spec files were modified (D-041 honoured — all mutation work done on copies/snapshots).

---

## 1. Is the VP-INDEX cross-check a genuine JOIN or an allowlist in disguise?

**Verdict: genuine runtime JOIN. Not an allowlist.** Evidence a human can re-run:

| Claim | Verified how | Result |
|---|---|---|
| No BC id hardcoded | `grep -n 'BC-' check-placeholders.py` | Only `_BC_ID_RE = ^BC-\d+\.\d+\.\d+$` plus docstring examples. Zero concrete BC ids in logic. |
| Map parsed at runtime | `_load_vp_index_classifications()` called once in `main()`; parses all 66 BC rows, 33 classified `test-sufficient` | Matches the operator's "33 of 34" framing exactly. |
| Reclassification changes behaviour with **no code edit** | On a snapshot where all em-dash cells were replaced by the sentinel (0 findings), edited **only** VP-INDEX: `BC-2.13.002 test-sufficient → VP-999` | 0 → 2 findings, message (iii). Restoring the row → back to 0. |
| Path (ii) distinct | Dropped that BC's VP-INDEX row | 2 findings, message (ii): `'BC-2.13.002' has no row in VP-INDEX` |
| Path (i) distinct | Sentinel in a non-BC-named file | `sentinel requires a BC filename (BC-S.SS.NNN) and VP-INDEX context` |
| **Fails CLOSED** when VP-INDEX absent | Tree with no `verification-properties/` dir at all | Sentinel **rejected**, exit 1 |
| No suppression construct | `grep -Ei '(ALLOWLIST\|WHITELIST\|SKIP_LIST\|SKIP_SET\|KNOWN_\|SUPPRESS\|_DEFERRAL)'` | No matches in code (only prose in comments). Suite's own `SUPPRESSION_PATTERN` pre-flight guard still covers this file. |

All three rejection paths are also **individually** mutation-killed (M5→test 3; M6→P14-2, P14-3; M7→P14-1). This is stronger than the PR body claimed.

## 2. Is the Stories exemption narrow? — partly

**Shape 1 (`| Stories |` table row): narrow enough, minor scope creep.** Probes confirm `| Architecture Module | [filled by architect] |` FAILS, prose `[filled by ...]` FAILS, lowercase `| stories |` FAILS. But the row is exempt **anywhere** in a file, not only under `## Traceability`, and it is exempt **inside fenced code blocks**. D-093 as written says "inside a Traceability row".

**Shape 2 (`## Story Anchor` bullet): broader than the ruling, and untested.** It is *heading*-anchored, not field-anchored, and the heading is never reset by `#` or `###`:

| Probe | Result |
|---|---|
| `- [filled by story-writer]` under `## Story Anchor` | EXEMPT (intended) |
| `- [filled by story-writer]` under `## Some Other Heading` | FLAGGED (good) |
| non-bullet prose under `## Story Anchor` | FLAGGED (good) |
| `- Architecture Module: [filled by architect]` under `## Story Anchor` | **EXEMPT** — any bullet, not just the Stories field |
| bullet after `## Story Anchor` → `### Subsection` | **EXEMPT** — `###` does not reset |
| bullet after `## Story Anchor` → `# Different H1` | **EXEMPT** — `#` does not reset |

Current blast radius is zero: `BC-2.10.009` is the only file with `## Story Anchor`, and it holds exactly one bullet before `## VP Anchors` resets the state.

---

## Findings

### BLOCKING

**B1 — Shape 2 is entirely uncovered by the selftest suite; two mutations survive.** `scripts/spec-lint/check-placeholders.py:346-351` (and heading tracking at `:277-278`).

Using a *verified non-vacuous* harness (control run: exit 0, 62/62, all 7 P14 headers reached — my first harness attempt was itself vacuous, aborting at selftest 22 before ever reaching the P14 tests, so treat bare exit codes with suspicion here):

- **M4** — delete the Shape 2 branch entirely → suite **62/62, exit 0. SURVIVED.**
- **M8** — drop the `current_h2_heading == "Story Anchor"` condition, so **every** `- [filled by ...]` bullet in every spec file becomes exempt → suite **62/62, exit 0. SURVIVED.**

M8 is exactly the blanket-weakening class D-093 forbids, and nothing in the suite defends against it. The PR's mutation table only exercises Shape 1 (M2) and the sentinel (M1, M3), so this gap is invisible in the PR's own evidence. The suite header already concedes the mechanism: *"missing branches are vacuous by omission."*

Suggested remediation — two tests, then re-run M4/M8 to confirm both now die:
```
P14-8  clean: '## Story Anchor' + '- [filled by story-writer]'  -> exit 0
       defect: move that bullet under '## Architecture Anchors'  -> must exit 1   (kills M4)
P14-9  clean: file with no '## Story Anchor'
       defect: add '- [filled by story-writer]' bullet, no such heading -> must exit 1  (kills M8)
```

### SUGGESTION

**S1 — Shape 2 should be field-anchored and heading-bounded.** `:277-278`, `:347-351`. Reset `current_h2_heading` on an ATX heading of *any* level, and/or require the bullet to name the Stories field, so `- Architecture Module: [filled by architect]` under `## Story Anchor` is not silently exempt.

**S2 — Shape 1 should require the Traceability context and exclude fenced blocks.** `:342-345`. Add `current_h2_heading == "Traceability"` and `not in_fenced_code` to match D-093's wording.

**S3 — `test-sufficient` accepts an EMPTY Proof Method; `VP-NONE` does not.** `:178-198` vs `:201-204`. Verified: `| test-sufficient | p |  |` passes, `| VP-NONE | p |  |` fails (D-078). A row asserting "tests are sufficient" can currently name no test at all. Consider applying the same non-empty precondition.

**S4 — the join reads the VP(s) column positionally.** `:143-145` takes `cells[2]` after validating only that the header's first cell is `"BC"`. Today's header is `| BC | Title (abbreviated) | VP(s) | Notes |` so this is correct, but inserting a column would silently retarget the join. Fails closed in the likely cases; still an unvalidated structural assumption. Assert `cells[2] == "VP(s)"` on the header row.

**S5 — no demo evidence.** PR #8 (`c2e5cf1`) shipped `docs/demo-evidence/BI-040/evidence-report.md` plus four AC `.txt` files. PR #9 touches nothing under `docs/`, breaking a convention set one PR earlier.

### NIT

**N1 — duplicate VP-INDEX BC rows silently last-win** (`:145`). None today (66 unique of 66 rows).
**N2 — misleading fail-closed message.** With VP-INDEX entirely absent, the operator is told `'BC-x' has no row in VP-INDEX; ... add a 'test-sufficient' row to VP-INDEX` — the file does not exist. Distinguish missing-file from missing-row.
**N3 — diff is 565+/22− = 587 lines,** over the 500 guideline; 329 lines are selftest code, which mitigates.
**N4 — PR body quotes absolute baselines, not deltas** (see below).

---

## Expected vs observed — every figure

| Figure | PR claim | Observed | Verdict |
|---|---|---|---|
| Selftests | 62/62 | 62/62, exit 0, `EXPECTED_TEST_COUNT=62` | ✅ |
| Primitive tests | 10/10 | 10/10 | ✅ |
| `check-id-resolution` | 10 findings / 134 files | 10 findings / 134 files | ✅ |
| `[filled by ...]` | 25 → 0 | 25 → 0 | ✅ |
| VP-column em-dash | unchanged | unchanged | ✅ |
| Total (first run) | 80 → 55 | 80 → 55, 133 files | ✅ |
| Total (later run) | — | **78 → 53** | ⚠️ see N4 |
| M1 unconditional sentinel | kills test 3, P14-1/2/3 | exactly those 4 | ✅ |
| M2 remove Shape 1 | kills P14-6 structural-fail | exactly that, suite exit 2 | ✅ |
| M3 blanket-exempt | kills P14-5, P14-6, P14-7 | exactly those 3 | ✅ |

**N4 detail:** the *deltas* reproduce exactly, but the absolutes moved mid-review (80→78, 55→53) because `.factory/specs` is being edited concurrently by other agents (D-041) — `git status` on the factory worktree shows `BC-2.10.002`, `BC-2.07.006`, `BC-2.11.004`, `BC-2.12.005`, `BC-2.14.004` modified. Not a PR defect, but the PR body should quote deltas rather than absolutes, which are a moving target.

**The "known-good residual of 2" is already stale — in the good direction.** `BC-2.10.002` now carries `| VP-007 |` rather than em-dash rows. On a frozen snapshot with every em-dash first cell replaced by the sentinel (58 rows / 34 files substituted), the checker reports **`Check passed` — 0 findings**, not 2. Nothing to fix.

## Also verified clean

- Not one pre-existing selftest was removed or weakened — all 22 deleted lines are signature/docstring changes plus the `EXPECTED_TEST_COUNT` bump.
- `spec_lint_primitives.py` is byte-identical to `develop`; the diff is confined to `check-placeholders.py` and the selftests.
- Both new fixtures are content-based defects, not file/line allowlists.
- Commit message: conventional format with story ID. Branch is 0 commits behind `develop`.

## CI — 4 required checks on `develop` (macOS-only per D-043)

| Required context | Status |
|---|---|
| Format check | ✅ pass |
| Clippy (deny warnings) | ✅ pass |
| Test (macos-latest) | ✅ pass |
| Build release (macos-latest) | ✅ pass |

All 4 green. `Spec lint` is ❌ failing (the 53 known em-dash findings) but is **not** a required context — worth noting against the D-029/D-032 intent that spec-lint be REQUIRED at the Phase-1 gate; branch protection does not yet list it. `GitGuardian` passes. No CI was re-triggered (SHA untouched).

---

*Review covers head `87cefbf00342b583840c3c11a7c530d9548a4b5c` only. Posted as a COMMENT, not an approval — self-review, and BI-046 (independent reviewer identity) remains an open prerequisite.*
