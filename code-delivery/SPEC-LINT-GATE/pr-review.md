# PR Review — Cycle 3 (final convergence check)

**PR:** #2 `feature/spec-lint-tooling` → `develop`
**Head reviewed:** `35cd3085`
**Verdict:** REQUEST_CHANGES

I re-reviewed all 24 changed files at the current head and **executed** the validators,
the generators' code paths, and the selftest suite rather than reading them only. Every
finding below was reproduced empirically; each one lists the exact probe input.

First, credit where the fix commits landed. I verified these work:

| Claimed fix | Verified how | Result |
|---|---|---|
| #2 ARCH-INDEX shard check wired in | injected `stray-shard-probe.md` into an isolated tree copy | CONFIRMED flags it |
| #3 HS-INDEX duplicate check wired in | appended a duplicate `HS-001` row to an isolated copy | CONFIRMED flags it |
| #4 T-NN inversion fixed | injected `T-17` | CONFIRMED flags out-of-range |
| #9 check-title-sync selftest via override | ran selftest 9 | CONFIRMED sound (0 → 1 transition, correct message) |
| #12 `SPEC_LINT_REPO_OVERRIDE` | check-counts + check-title-sync | CONFIRMED present |
| #19 CI factory-artifacts checkout | read CI job log for run 31105970034 | CONFIRMED — spec tree present, 7/8 checks PASS in CI |
| #7/#8 cp + spec-tree guards | read `run-selftests.sh:27-33, 52-57` | CONFIRMED present |

`bash scripts/spec-lint/selftest/run-selftests.sh` does return **11/11 PASS**. The
problem is that 3 of those 11 assert nothing, and 3 checkers are vacuous in ways no
test covers. Details below.

---

## BLOCKING

### B1. `check-ec-injectivity.py` cannot fire — POL-16 EC injectivity is unenforced

**File:** `scripts/spec-lint/check-ec-injectivity.py:62`

```python
m = re.match(r"^\|\s*(EC-(\d+[a-z]?))\s*\|\s*(.+?)\s*\|\s*(.+?)\s*\|", line)
```

This requires **three** pipe-delimited content columns. Every real BC `## Edge Cases`
table in this corpus has **two**:

```
| EC-003 | `.github/PULL_REQUEST_TEMPLATE.md` |
| EC-004 | `.git/` directory |
```

Measured on the tree:

```
$ grep -rh '^| EC-[0-9]' .factory/specs/behavioral-contracts/ | awk -F'|' '{print NF}' | sort | uniq -c
 179 4          # NF=4 => 2 content columns; the regex needs NF>=5
$ grep -rh '^| EC-[0-9]' .factory/specs/behavioral-contracts/ | awk -F'|' 'NF>=5' | wc -l
       0
```

So `ec_map` is populated **exclusively** from `test-vectors.md`, where each EC appears
once. `multi_occurrence` is structurally always 0 — the checker's own success line
admits it:

```
Check passed: 141 EC IDs validated — all injective (0 appear in multiple files but are consistent)
```

The stated purpose ("same EC-NNN in multiple BC files with different scenario
descriptions, or in both test-vectors.md and a BC with a different expected verdict")
can never trigger. Probe: a BC file containing `| EC-001 | TOTALLY DIFFERENT SCENARIO |`
in real 2-column format is **not** flagged; only an artificial 3-column row is.

Compounding this, the selftest fixture was authored to the regex rather than to the
corpus: `selftest/fixtures/bad-ec-injectivity.md` uses a 3-column
`| ID | Description | Expected Behavior |` table that no real BC file uses. The green
selftest therefore certifies the vacuity.

**Fix:** accept 2-column BC edge-case tables (description-collision detection), handle
the `test-vectors.md` verdict columns separately, add a hard vacuity assertion (fail if
0 BC rows were extracted corpus-wide), and re-author the fixture in real 2-column format.

### B2. `check-holdout-boundary.py` — three bypasses leak reserved holdout scenarios

**File:** `scripts/spec-lint/check-holdout-boundary.py:70-82, 138`

POL-18 exists so Phase 4 holdout evaluation stays blind. I planted five rows for
reserved holdout IDs in `prd-supplements/` (isolated tree copy) and only the control
was caught:

| Probe row (all for IDs in the active holdout pool) | Result |
|---|---|
| `\| TV-900 \| EC-079 \| README.md line 4 has [x](https://expired.example.invalid/p); DNS NXDOMAIN \| --online \| 1 \| broken (dns-failure) \|` | **caught** (control) |
| identical content, **one leading space** before the pipe, EC-093 | **NOT caught** |
| `... \| 1 \| 1 finding, reason \`tls-error\` \|` (reason-code verdict form), EC-094 | **NOT caught** |

Three independent causes:

1. **`:138` `if line.startswith("|")`** — a single leading space defeats the entire
   check. Use `line.lstrip().startswith("|")`.
2. **`:79` regex `exit\s+[012]|exit-[012]`** — the docstring (`:74-76`) says a row is
   concrete if it has a verdict *or an expected exit code*, but a bare numeric column
   `| 1 |` never matches. That is exactly the `test-vectors.md` row shape
   (`| TV | EC | desc | args | exit | verdict | reason |`).
3. Canonical reason codes are not a concreteness signal, so
   `1 finding, reason \`dns-failure\`` — a complete expected output — reads as harmless.

Rows 2 and 3 are full input+expected-output specifications for reserved IDs, including
the sub-lettered `EC-094a` pattern the docstring specifically calls out at `:13-16`.
A leak here silently invalidates holdout evaluation, and nothing downstream would notice.

### B3. Selftest 2 passes because `check-counts.py` **crashes**, not because it detects anything

**Files:** `scripts/spec-lint/check-counts.py:120, 207`; `selftest/run-selftests.sh:90-132`

`check-counts.py` has exactly one existence guard — line 207, for `BC-INDEX.md` — while
performing 12 unguarded `read_text()` calls. Selftest 2's temp tree does not create
`module-criticality.md`, so:

```
Traceback (most recent call last):
  File "scripts/spec-lint/check-counts.py", line 289, in main
    mc_vp = count_module_criticality_vp()
  File "scripts/spec-lint/check-counts.py", line 120, in count_module_criticality_vp
    for line in mc.read_text(encoding="utf-8").splitlines():
FileNotFoundError: .../module-criticality.md
EXIT=1
```

The harness only asserts a non-zero exit, so the crash reads as PASS. **Proof the test
is vacuous:** I removed the injected defect entirely (`total_bcs: 0` against 0 rows, so
no mismatch exists) and the checker still exits 1 — the test would report PASS with no
defect present. `check-counts.py` (479 lines, 37 checks), one of the three checkers
D-027 names as false-passing, therefore has **zero** effective negative-test coverage.

**Fix:** guard every required input in `check-counts.py` (return 2, per W4), and make
selftest 2 assert on the violation *message* (`grep -q 'total_bcs mismatch'`), not the
exit code.

### B4. Selftests 3 and 4 assert nothing — `check-placeholders.py` already fails on the clean tree

**File:** `selftest/run-selftests.sh:134-144`

```
$ python3 scripts/spec-lint/check-placeholders.py ; echo $?
Check FAILED: 25 placeholder occurrences found (132 files checked)
1
```

Both tests inject a fixture into the live tree and assert a non-zero exit from a checker
that is **already** non-zero (25 known `[filled by ...]` markers deferred to Phase 2,
also visible in the CI log). They report PASS with no fixture at all. `check-placeholders.py`
— also named in D-027 — has zero effective negative-test coverage.

**Root cause shared by B3 and B4:** `run_test` (`:61`) asserts only
`if python3 checker; then FAIL else PASS`. That cannot distinguish "detected my planted
defect" from "was already failing" or "crashed". This is structurally the same false-pass
class as D-027, relocated into the test harness. **Fix:** capture the baseline exit code
before injection and require a `0 → non-zero` transition, plus match the injected path in
the checker's output.

### B5. `check-id-resolution.py` does not validate the R-ID form the specs actually use

**File:** `scripts/spec-lint/check-id-resolution.py:174-182, 276`

`:276` is `re.finditer(r"\bR-?(\d{1,2}[a-c]?)\b", line)` — at most **two** digits. The
specs use the three-digit form:

```
$ grep -rohE '\bR-[0-9]{3}\b' .factory/specs/ | sort | uniq -c
  37 R-001   18 R-002   6 R-003   4 R-004   5 R-005   6 R-006   5 R-007   8 R-008   4 R-009
```

Proof it is unchecked — planted in `.factory/specs/`:

```
This satisfies R-777 and R-999 (nonexistent 3-digit requirement IDs).
→ Check passed: 134 files checked — all ID references resolve      (exit 0)

This satisfies R-77 (nonexistent 2-digit requirement ID).
→ SELFTEST-probe-r2.md:3: unresolvable R requirement reference 'R-77'   (exit 1)
```

Two further defects hide behind that regex gap:

- **Wrong source of truth.** `build_valid_r_ids()` reads `product-brief.md`, and the
  docstring (`:24`) says `R-NN -> product-brief.md`. But `L2-INDEX.md:150` declares
  `| R-NNN | 9 (R-001–R-009) | risks.md |` — the R-NNN family is *risk* IDs defined in
  `domain-spec/risks.md`. Two distinct families (`R1..R8` brief requirements vs
  `R-001..R-009` risks) are conflated onto one registry pointed at the wrong file.
- **Hardcoded whitelist already stale.** `:176-177` hardcodes `R-001`..`R-008`;
  `R-009` is missing, is used 4× in `risks.md`, and is not derivable from
  `product-brief.md` (the brief-scan regex at `:180` has no optional hyphen, so it never
  picks up hyphenated forms). I simulated widening the regex to `\d{1,3}`: `R-009`
  immediately produces 4 false violations.

So fix #1 ("VALID_R now used… R-NN references validated") is half-delivered: the
dominant form is silently skipped, and the fixture (`bad-r-ref-unregistered.md`, `R-99`)
tests a 2-digit form that appears nowhere in the corpus.

**Fix:** widen to `\d{1,3}`, derive the registry from `risks.md` for `R-\d{3}` and from
`product-brief.md` for `R\d+`, delete the hardcoded whitelist, resolve `R-009`, and add a
3-digit fixture.

### B6. `check-adr-consistency.py` — dominant corpus phrasing bypasses the exit-code check

**File:** `scripts/spec-lint/check-adr-consistency.py:61, 84, 95`

- **`:95`** `re.compile(r"broken[^.]*exit\s+2")` cannot match `exit code 2`, even though
  the docstring at `:9` explicitly claims it handles `"exit 0/1/2" or "exit code 0/1/2"`.
  Probed in an isolated copy:
  - `A broken link finding produces exit 2 from the CLI.` → **caught**
  - `A broken link finding produces exit code 2 from the CLI.` → **NOT caught**

  `exit code N` is live phrasing in this corpus (`grep -rhoE 'exit (code )?[012]'
  .factory/specs/architecture/` → 2× `exit code 1`). `[^.]*` also stops at any period, so
  splitting the claim across two sentences evades it. The fixture `bad-adr-exit-code.md`
  uses the bare `exit 2` form, so the selftest only exercises the branch that works.
- **`:61`** `EXIT_CODE_MEANING` is defined and **never referenced** anywhere in the file
  (`grep -n EXIT_CODE_MEANING` → single hit, the definition). Docstring check #1
  ("only exit 0/1/2 **with correct semantics**") has no implementation. This is the same
  build-a-set-and-never-use-it pattern D-027 was raised for (`VALID_EC` in
  check-id-resolution).
- **`:84`** `if "|" in line and ("1.1" in line or "1.0" in line or ...): return False`
  — a substring match on version numbers exempts **any** table row containing `1.0`/`1.1`
  from the dns/tls-indeterminate check. `| dns-failure | indeterminate | v1.0 |` passes.
  Replace with explicit changelog-section boundary tracking (the pattern
  `extract_closed_reason_codes` already uses correctly).

### B7. `gen-rtm.py` / `gen-bc-index.py` will silently wipe a source-of-truth spec file, then report success with a false count

**Files:** `scripts/spec-lint/gen-rtm.py:150, 210, 213`; `scripts/spec-lint/gen-bc-index.py:158`

Neither generator guards against `rows == 0`. If `BC_DIR.rglob("BC-*.md")` returns
nothing (BC dir renamed, an `ss-*` reorg mid-flight, a partial worktree), `gen-rtm.py`
emits header + separator + `*0 BCs in traceability matrix.*` and writes it —
**destroying all 66 hand-curated RTM rows in `prd.md` §7**. `gen-bc-index.py` likewise
writes `total_bcs: 0`, `subsystems: 0` over the real summary block and exits 0.

Worse, `gen-rtm.py:213` reports `len(priorities)` (read from BC-INDEX) rather than
`len(rows)` (what it actually wrote), so the operator sees a plausible non-zero count
after a total wipe:

```
Updated: .../prd.md
  §7 RTM regenerated from BC frontmatter + traceability sections
  2 BCs included          <-- it wrote 0 rows
```

`gen-ec-registry.py:116-118` already implements the correct guard
(`ERROR: No EC rows found` → exit 2) — the pattern exists in this very PR and simply was
not applied to the two destructive writers. Currently latent only because `prd.md` §7
has no `BEGIN GENERATED` marker yet; `gen-rtm.py:180-188` prints instructions telling the
operator to add it, which arms the wipe.

**Fix:** copy the `gen-ec-registry.py:116-118` guard into `gen-rtm.py:150` and
`gen-bc-index.py:158`; report `len(rows)`.

---

## WARNING

### W1. The selftest harness overwrites live spec paths with no pre-existence check
`run-selftests.sh:52` does `cp "$fixture_src" "$fixture_dst"` then `:68` `rm -f
"$fixture_dst"` — against the **live** tree. Test 8 targets
`.factory/specs/behavioral-contracts/ss-01/BC-2.01.999.md`, test 5 targets
`architecture/decisions/ADR-SELFTEST-bad-exit.md`. If a real artifact ever occupies one
of those paths, the harness silently overwrites and then deletes it. Add
`if [ -e "$fixture_dst" ]; then echo "ERROR: refusing to overwrite $fixture_dst"; exit 1; fi`.

### W2. The negative-test suite never runs in CI
`grep -rn selftest .github/` → no matches. `justfile:76` `ci:` includes `spec-lint` but
not `spec-lint-selftest`. The suite is the only evidence the validators work, yet it is
manual-only — a future regression that re-vacuums a checker would not be caught. Add it
to the `spec-lint` job.

### W3. `just ci` is now permanently red
`justfile:76` adds `spec-lint` to `ci`, and `just spec-lint` exits 1 on the 25 known
Phase 2 placeholders. The justfile header calls `just ci` "the canonical CI gate" with no
remote. This contradicts D-029's advisory intent and trains the team to ignore the local
gate. Either hold `spec-lint` out of `ci` until Phase 2, or split advisory vs strict.

### W4. Exit-code-2 convention applied to only 2 of 8 checkers
`check-adr-consistency` and `check-holdout-boundary` return 2 for infrastructure errors;
`check-counts`, `check-id-resolution`, `check-placeholders`, `check-index-integrity`, and
`check-title-sync` return 1 — and `check-counts` can also die with a traceback (also 1).
So `ci.yml:250-259`'s `case 2)` branch distinguishes a quarter of the suite, and for the
rest "required input missing" is indistinguishable from "spec violation found". This
ambiguity is precisely what made B3 vacuous. Standardize on 2.

### W5. `SPEC_LINT_REPO_OVERRIDE` in 2 of 8 checkers and 0 of 4 generators
`check-id-resolution`, `check-placeholders`, and `check-index-integrity` pin `REPO` from
`__file__`, which is why tests 3/4 must inject into the live tree (causing B4 and W1). All
four generators hardcode it too (`gen-bc-index.py:33`, `gen-ec-registry.py:25`,
`gen-prd-sections.py:29`, `gen-rtm.py:40`), so they cannot be pointed at a fixture tree —
this is the root cause of W6. Adding the override everywhere is the highest-leverage
testability fix in the PR.

### W6. The four generators have zero test coverage
No test, fixture, or CI step invokes any `gen-*.py`. `justfile:243` has no dry-run
pre-pass, no `git diff --exit-code` post-check, and no clean-worktree precondition —
for tooling that writes directly to the spec source of truth. Ordering compounds it:
`gen-bc-index` writes priorities that `gen-prd-sections` and `gen-rtm` then read as
authoritative, so one defect propagates into three files in a single `just spec-gen`.

### W7. No vacuity guards on the "0 items checked" path
`check-ec-injectivity` prints `Check passed: 0 EC IDs validated` and exits 0 if `BC_DIR`
or `TV_FILE` is renamed. `check-adr-consistency` exits 0 with `Check passed: 0 ADRs
checked` on an empty ADR dir. A directory rename silently disables both checks.

### W8. Unescaped `re.sub` replacement corrupts real data — the "LOW" classification looks wrong
Listed as known/accepted, so **not blocking**, but the evidence contradicts the severity,
so flagging for re-triage rather than overriding the decision. `gen-ec-registry.py:124-129`
escapes the *pattern* but passes the generated block as an unescaped *replacement*, where
Python interprets backslash templates. Minimal reproduction using content already in
`test-vectors.md:85`:

```
input row : | EC-015 | `utf8bom.md` with UTF-8 BOM followed by `## Setup\n[x](#setup)` | (clean) |
after re.sub: | EC-015 | `utf8bom.md` with UTF-8 BOM followed by `## Setup
              [x](#setup)` | (clean) |            <- table row split, markdown broken
```

The corruption appears on the **second** run (first run takes the plain-concat path) and
is permanent — run 3 reports "already up to date". And `test-vectors.md:120` contains
`C:\docs\a.md`, which yields `re.error: bad escape \d` — `just spec-gen` crashes. Same
defect at `gen-bc-index.py:150-151`, `gen-prd-sections.py:130-131`, `gen-rtm.py:170-171`.
One-line fix per site: pass a callable, `lambda _: replacement`.

### W9. Further generator data-loss paths (no test coverage on any of them)
- **`gen-bc-index.py:75-78, 95, 217`** — priorities are parsed out of `BC-INDEX.md`
  itself, defaulted to `"P0"` on a regex miss, then written back. An escaped pipe in a
  title (legal GFM; `test-vectors.md:219` shows the project writes `a\|b.md`) silently
  downgrades P1/P2 → P0 in the source of truth. Same defaulting at
  `gen-prd-sections.py:82,99` and `gen-rtm.py:95,147`.
- **`gen-bc-index.py:89-90`, `gen-prd-sections.py:96-98`** — a BC file with a
  malformed/absent H1 is `continue`d with no warning and exit 0: the row disappears and
  `total_bcs` is decremented while the table still lists it. The generator manufactures
  exactly the desync `check-counts.py` exists to catch.
- **`gen-ec-registry.py:130-133`** — if the markers are stripped, `re.sub` matches
  nothing and it prints "No changes needed … already up to date. Registry contains 141
  canonical EC definitions" while writing nothing. The registry can be arbitrarily stale
  and report green. `gen-rtm.py:180-198` gets this right (explicit marker check, exit 2 on
  START-without-END) — apply that shape to the other three.
- **Duplicated markers** → the table is emitted twice, exit 0. **Nested markers** →
  non-greedy `BEGIN.*?END` matches the inner END, deleting inner content and stranding an
  orphan `END` permanently.
- **`gen-rtm.py:101-113, 148`** — `get_existing_test_types()` requires the exact current
  6-column shape; any deviation drops the BC from the map and `test_types.get(bc_id,
  "unit")` silently overwrites hand-curated `integration` / `kani-proof` values, despite
  `:28-31` advertising that column as preserved.

### W10. The two newly-wired index checks have no negative test
I confirmed the ARCH-shard and HS-duplicate checks work, but neither has a selftest
fixture — test 8 only covers "unlisted BC file". They are one refactor away from
regressing silently.

---

## NIT

- `check-placeholders.py:10` docstring says `(73 remain per audit)`; the actual count is 25.
- `.gitignore` has no `__pycache__/` or `*.pyc` entry. This PR adds the repo's first
  Python, and running the validators leaves an untracked `scripts/spec-lint/__pycache__/`.
- `check-index-integrity.py:162` `in_sections` assigned but never used;
  `get_actual_hs_files()` defined but never called.
- `check-holdout-boundary.py:85-93` — the `holdout-scenarios` / `cycles` / `planning`
  guards are unreachable: the walk at `:117` is `SPECS.rglob("*.md")`, which contains none
  of those. `:70` `ec_id` parameter is unused.
- `check-ec-injectivity.py:44` `normalize_verdict` accepts `valid` as a legitimate verdict
  token, contradicting ADR-007 and `check-adr-consistency`'s own rule that `valid` is not
  a verdict.
- `gen-bc-index.py:59-65` `get_bc_priority` is dead code returning a hardcoded `"P0"`;
  `:179-184` builds an `ss_pattern` regex that is never used; `:20-22` claims it "will ADD
  [markers] on first run", which it does not.
- `gen-ec-registry.py:49` claims `ec-registry.md` is "for use by check-ec-injectivity.py",
  but `grep -rn ec-registry scripts/` matches only the generator. The artifact has no consumer.
- PR body is stale in two places: the Test Evidence table still describes tests 2 and 3 as
  running against the "real spec tree" (the fix commits moved them to an injected temp
  tree / fixture), and the row "Advisory spec-lint CI (missing spec tree in CI)" no longer
  holds — CI now checks out `factory-artifacts` successfully and fails only on the 25
  placeholders.
- Six commit subjects exceed 72 characters.

---

## Checklist

| # | Item | Result |
|---|---|---|
| 1 | Diff coherence | PASS — 24 files, all spec-lint tooling; the single deletion is the `justfile` `ci:` line, replaced in place |
| 2 | Description accuracy | PARTIAL — mermaid diagrams and policy mapping accurate; two stale Test Evidence rows (see NIT) |
| 3 | Test coverage | **FAIL** — 3 of 11 negative tests vacuous (B3, B4); `check-counts` and `check-placeholders` effectively uncovered; `check-ec-injectivity` / `check-holdout-boundary` / `check-adr-consistency` tested with fixtures that do not match corpus formatting (B1, B2, B6); 0 tests for 4 generators (W6) |
| 4 | Demo evidence | `docs/demo-evidence/` absent. Not blocking: scripts-only tooling with no runtime surface, and the selftest transcript in the PR body is the appropriate evidence form. Worth adding the transcript verbatim. |
| 5 | Commit quality | PASS — 13 commits, all conventional with scope; subject-length nit only |
| 6 | Diff size | 3,330 insertions / 24 files, well over the 500-line flag. Justified as one cohesive tooling drop, but it is why three vacuous checkers survived two review cycles. |
| 7 | Missing changes | R-NNN validation (B5); selftest in CI (W2); generator guards (B7) |
| 8 | Dependency status | PASS — no upstream story deps; base `develop`; MERGEABLE |

**CI:** all 8 required checks pass (fmt, clippy, test ×3, build-release ×3, GitGuardian).
The advisory `Spec lint` job fails on 25 `[filled by ...]` placeholders only — 7 of 8
validators PASS in CI and the `factory-artifacts` checkout works. Consistent with D-029/D-032.

---

## Summary

The fix commits genuinely closed a lot: the ARCH-shard and HS-duplicate wiring, the T-NN
inversion, the CI spec-tree checkout, and the title-sync selftest are all verified working.
But the cycle-2 verdict was about a specific failure class — validators that look like they
check something and cannot — and that class is still present in three checkers that were not
in the fix list:

- `check-ec-injectivity` cannot extract a single row from any real BC file (B1)
- `check-holdout-boundary` lets complete holdout specs through on whitespace or phrasing (B2)
- `check-adr-consistency` misses the dominant `exit code N` phrasing and never uses
  `EXIT_CODE_MEANING` at all (B6)

And for the two checkers the fix list *did* target, the negative tests that are supposed to
prove the fixes worked assert nothing: selftest 2 passes on a `FileNotFoundError` traceback
(B3) and selftests 3/4 pass because the checker was already red (B4). I verified both by
removing the planted defect and watching the tests still report PASS.

The single highest-leverage change is to `run_test`: require a `0 → non-zero` transition and
match the injected path in the checker's output. That one change turns the suite from
"the checker exited non-zero for some reason" into a real assertion, and it would have
caught B1, B2, and B6 on its own.

Happy to re-review promptly on the next push.
