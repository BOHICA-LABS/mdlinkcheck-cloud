# PR Review — Cycle 7 (convergence)

**PR:** #2 — `feat: spec-integrity validator and generator tooling (Phase 1 gate)`
**Base → Head:** `develop` ← `feature/spec-lint-tooling`
**Reviewed SHA:** `73334c7dd0a7af250fd8833d01c811078b6beb0e`
**Verdict:** **APPROVE** — no blocking findings. 4 suggestions + 3 nits, all non-blocking.

---

## Verdict rationale

Every cycle-6 blocking item is fixed, and I verified each one by execution rather than by
reading the diff. The cycle-7 delta is 4 files / 48 insertions and is surgical: three
one-line `SPEC_LINT_REPO_OVERRIDE` additions plus the R-ID scraper rewrite. I found no
new false-pass (D-027-class) defect in any *checker*. I did find two genuine
discrimination weaknesses in the *selftest harness* and one source-of-truth mismatch in
`check-id-resolution`. All three are recorded as suggestions because none produces a wrong
result on today's tree, none blocks the advisory `Spec lint` job, and each has a small
well-scoped fix that belongs with the Phase 2 harness follow-up.

---

## Verification performed

Everything below was executed against the reviewed SHA with the factory worktree mounted.

### 1. `SPEC_LINT_REPO_OVERRIDE` in all 8 checkers — CONFIRMED

All 8 checkers carry the identical single-line form:

```python
REPO = Path(os.environ.get("SPEC_LINT_REPO_OVERRIDE", "")).resolve() if os.environ.get("SPEC_LINT_REPO_OVERRIDE") else Path(__file__).resolve().parent.parent.parent
```

Reading that line is not sufficient evidence that the override is *honoured* — a checker
could still resolve some paths from the real repo and silently contaminate an isolated
test. So I pointed every checker at an empty temp directory. All 8 fail closed, and all 8
name the *temp* path in the error, proving no leakage to the live tree:

| Checker | exit (empty override) | Message names temp path |
|---|---|---|
| check-adr-consistency | 2 | yes |
| check-holdout-boundary | 2 | yes (prd.md §5b) |
| check-index-integrity | 1 | yes |
| check-id-resolution | 1 | yes |
| check-counts | 1 | yes |
| check-placeholders | 1 | yes |
| check-title-sync | 1 | yes |
| check-ec-injectivity | 1 | yes |

Empty-string handling is correct: `SPEC_LINT_REPO_OVERRIDE=""` is falsy and falls through
to the `__file__`-derived default rather than resolving to CWD.

### 2. `check-id-resolution` on the real tree — CONFIRMED exit 0

```
Check passed: 134 files checked — all ID references resolve
```

No `R-010`-class false violations remain. Full 8-checker baseline on the real tree:

| Checker | exit | Result |
|---|---|---|
| check-adr-consistency | 0 | 8 ADRs, exit codes + reason codes consistent |
| check-counts | 0 | 37 count checks |
| check-holdout-boundary | 0 | 134 files, pool of 12 IDs, no leaks |
| check-id-resolution | 0 | 134 files, all refs resolve |
| check-index-integrity | 0 | 77 bidirectional checks |
| check-title-sync | 0 | 66 BC titles |
| check-ec-injectivity | 1 | 13 EC ID collisions — known/accepted, genuine POL-16 defects |
| check-placeholders | 1 | 25 placeholders — known/accepted, deferred Phase 2 |

### 3. Clean baselines for the 11 selftests — CONFIRMED, with one caveat (S-2)

`bash scripts/spec-lint/selftest/run-selftests.sh` → **11/11 PASS, exit 0**.

The harness never asserts a clean pre-injection baseline (a known/accepted deferred item),
so I supplied the missing control by hand for every test.

**Real-tree injection tests (1, 1b, 1c, 5, 7, 8).** Sound. The four checkers they exercise
— `check-id-resolution`, `check-adr-consistency`, `check-holdout-boundary`,
`check-index-integrity` — all exit 0 on the untouched tree (table above). A clean baseline
plus a non-zero exit after injection means the injected fixture is provably the sole cause.
No residue afterwards: `git status` clean in both the main tree and the `.factory`
worktree.

**Isolated temp-tree tests (2, 3, 4, 6, 9).** I rebuilt each temp tree with the defect
*removed* and re-ran the checker:

| Test | Checker | Positive control (defect removed) | Discriminating? |
|---|---|---|---|
| 3 | check-placeholders | exit 0 — "no VP-TBD, SS-TBD, [filled by], or test-sufficient" | yes |
| 4 | check-placeholders | exit 0 | yes |
| 6 | check-ec-injectivity | exit 0 — "1 EC IDs validated — all injective" | yes |
| 9 | check-title-sync | exit 0 — "1 BC titles validated" | yes |
| 2 | check-counts | **exit 1** — fails on an unrelated second mismatch | **no** — see S-2 |

### 4. No new D-027 issues — CONFIRMED for checkers

The cycle-7 delta introduces no new false-pass path in any checker. Two D-027-*class*
weaknesses do exist — in the harness (S-2, S-3) and in the R-ID registry choice (S-1) —
and each is documented below with the counterfactual that exposes it.

---

## Findings

### S-2 — SUGGESTION / test-discrimination — `scripts/spec-lint/selftest/run-selftests.sh:102-134`

**Selftest 2 passes for the wrong reason, and would keep passing if the check it covers
regressed to a no-op.**

The temp tree declares `total_bcs: 99` (the intended defect) *and* `subsystems: 1` while
creating zero subsystem directories (an incidental second defect). The harness only
asserts "exit != 0", so either mismatch satisfies it. Proven by isolating the variables:

| `total_bcs` | `subsystems` | exit | Reported mismatches |
|---|---|---|---|
| 0 | 0 | 0 | none — clean baseline |
| 99 | 0 | 1 | `total_bcs mismatch — declared 99, actual 0` (only) |
| 99 | 1 (as shipped) | 1 | **both** `total_bcs` *and* `subsystems` |

Failure scenario: delete the `total_bcs` comparison from `check-counts.py` entirely and
selftest 2 still reports PASS, because the `subsystems` mismatch alone drives the exit
code. The negative test therefore provides no regression guarantee for the check it is
named after. The checker itself is fine — row 2 shows the `total_bcs` comparison working
in isolation.

Fix — one character in the heredoc at line 105:

```diff
 ---
 total_bcs: 99
-subsystems: 1
+subsystems: 0
 ---
```

That makes the injected `total_bcs` mismatch the sole cause of failure, and the
positive-control row above confirms the tree is otherwise clean.

### S-1 — SUGGESTION / correctness — `scripts/spec-lint/check-id-resolution.py:176-220`

**The `R-NNN` family is validated against the wrong registry, and the hardcoded seed
covers the entire live range — so the in-range check cannot fail.**

`build_valid_r_ids()` treats `.factory/specs/product-brief.md` as the source of truth, and
the error message calls these "R requirement reference"s. The brief defines only
`R1`–`R8`. But the corpus registry for the `R-NNN` shape is `domain-spec/risks.md`, which
`L2-INDEX.md:150` records as `| R-NNN | 9 (R-001–R-009) | risks.md |`. A third, unrelated
namespace also exists: `vp-026` uses `R-001..R-009`/`OR-010` as *oracle run* labels. The
checker collapses all three into one flat allowlist.

I removed the hardcoded seed and re-ran against the real tree to see what it masks — 67
references become unresolvable:

| Masked ID | Refs | Legitimate? |
|---|---|---|
| `R2a` / `R2b` / `R2c` | 55 | **Yes** — `product-brief.md:31-36` really does define R2 sub-items `a.`/`b.`/`c.`; the scraper regex cannot see them because they sit on continuation lines. The hardcode is a reasonable workaround for a scraper limitation. |
| `R-009` | 12 | **Registry mismatch** — `R-009` is a *risk* defined at `risks.md:41` ("Memory budget corpus-shape-dependent"), not a brief requirement. |

Two consequences:

1. The in-code justification is factually wrong. The comment says `R-009` "is retained
   here because spec files legitimately cite it as an oracle-run label (VP-026)". It is
   actually retained because it is a risk ID from a registry the function never reads. A
   future maintainer will act on the wrong mental model.
2. Because the seed spans `R-001`–`R-009` in all four forms and `risks.md` contains
   exactly 9 risks, the seed already covers the whole live registry. Failure scenario:
   trim `risks.md` to `R-001`–`R-005` and every reference to `R-006`–`R-009` still
   resolves — the checker reports "all ID references resolve" without ever consulting the
   registry. Only out-of-range refs (like the `R-99` in selftest 1c) are caught.

Suggested direction — scrape the registry that owns the shape, and keep the families apart
rather than merging them:

```python
# Risks (R-NNN) come from risks.md, which L2-INDEX names as their registry.
for line in RISKS.read_text(encoding="utf-8").splitlines():
    for m in re.finditer(r"^\|\s*(R-\d{3})\s*\|", line):
        ids.add(m.group(1))
```

and keep the brief scraper for the `R1`–`R8` requirement shape, retaining the `R2a/b/c`
hardcode with a comment stating the real reason (multi-line sub-items defeat the regex).
This is not a merge blocker — it produces no wrong result on today's tree — but it is the
same "asserts a property it does not verify" pattern that D-027 exists to eliminate, so it
should not be left undocumented.

### S-3 — SUGGESTION / test-discrimination — `scripts/spec-lint/selftest/run-selftests.sh:61-66`

**`run_test` treats any non-zero exit as success, conflating "detected the defect" (1) with
"crashed on missing input" (2).**

```bash
if python3 "$LINT_DIR/$checker.py" > /dev/null 2>&1; then
    echo "  FAIL (checker returned 0 ...)"
```

The checkers deliberately distinguish these — exit 2 is documented as "infrastructure
error, required input missing", and the CI job switches on it
(`case $ret in 2) ERROR ...` in `.github/workflows/ci.yml`). The harness throws that
distinction away. Failure scenario: a future refactor renames `error-taxonomy.md`;
`check-adr-consistency` then exits 2 on every invocation, selftest 5 reports PASS, and the
suite claims the checker "can detect defects" when it can no longer read its inputs at
all.

Two changes make the suite self-validating, and would have caught S-2 automatically:

```bash
# assert the specific detection exit code
python3 "$LINT_DIR/$checker.py" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 1 ] || echo "  FAIL (expected exit 1, got $rc)"
```

plus a pre-injection baseline assertion (`rc == 0` before `cp`), which is the already-agreed
positive-control work.

### S-4 — SUGGESTION / test-coverage — `gen-bc-index.py:33`, `gen-ec-registry.py:25`, `gen-prd-sections.py:29`, `gen-rtm.py:40`

**All 4 generators still hardcode `REPO` and have zero selftest coverage.**

```python
REPO = Path(__file__).resolve().parent.parent.parent
```

The 8 checkers are now override-able and therefore testable in isolation; the generators
are not — and they are the components that *write* to `.factory/specs/`. Failure scenario:
a regression in `gen-bc-index.py`'s row emitter can only be discovered by running it
against the live spec tree and inspecting the damage, because there is no isolated tree to
exercise it in, so it cannot be given a negative test. Adding the same one-line override
to the 4 generators is mechanical and would unblock generator selftests; it also composes
with the already-tracked non-atomic-write item, since a temp-tree harness is the natural
place to prove atomicity.

The PR body correctly claims 8/8 *validator* coverage and does not overclaim generator
coverage, so this is a gap to track rather than a description defect.

### N-1 — NIT — `scripts/spec-lint/check-id-resolution.py:206-218`

Unreachable exception handler. `re.match(r"^(\d+)", num_str)` guarantees the captured group
is all digits, so `int(numeric_part.group(1))` cannot raise `ValueError`. The
`try`/`except ValueError: pass` wrapper is dead code that implies a failure mode the
function does not have. Drop the wrapper.

### N-2 — NIT — `.gitignore`

The repo now ships Python tooling but `.gitignore` has no `__pycache__/` entry. Running
`just spec-lint` or the selftests leaves `scripts/spec-lint/__pycache__/` as untracked
files, dirtying `git status` and risking committed `.pyc` artifacts. Add:

```
# ── Python bytecode ───────────────────────────────────────────────────────────
__pycache__/
*.pyc
```

### N-3 — NIT — PR description

Stale baseline pass/fail counts for `check-id-resolution` in the body (now 134 files
checked, exit 0). Editorial only; already acknowledged.

---

## Checklist

| # | Item | Result |
|---|---|---|
| 1 | Diff coherence | PASS — 23 files, all spec-lint tooling, CI job, justfile recipes. No unrelated changes. |
| 2 | Description accuracy | PASS with N-3 — selftest count, validator count, and advisory-CI rationale (D-029/D-032) all match the diff. Only stale baseline counts. |
| 3 | Test coverage | PASS — 8/8 validators have a negative test; 11/11 pass; discrimination verified per test (S-2 the one exception). Generators uncovered (S-4). |
| 4 | Demo evidence | N/A — pre-story developer tooling with no user-facing surface. Executable evidence (`just spec-lint-selftest`, reproduced above) is the appropriate substitute. |
| 5 | Commit quality | PASS — 18 commits, conventional `fix(spec-lint):` / `feat:` format, scoped subjects. |
| 6 | Diff size | ACCEPTED — ~3.7k lines, but 12 standalone single-purpose scripts + 9 fixtures + 1 harness; not meaningfully splittable, and the cycle-7 delta is only 48 lines. |
| 7 | Missing changes | PASS — all 4 cycle-6 blocking items present and verified by execution. |
| 8 | Dependency status | PASS — no upstream PR dependencies. |

## Merge precondition (not a code finding)

`mergeStateStatus` is `BLOCKED`. The cause is a **GitHub infrastructure flake, not a code
defect**: on the `pull_request` run (`31115465194`) the `Build release (ubuntu-latest)` job
never reached the build — it died in *Set up job* with
`Failed to resolve action download info. Error: Bad Gateway` after two retries. The same
job passed in 7 seconds on the `push` run (`31115467187`) for the identical SHA `73334c7`.
Re-run that one job to clear the block. All other required checks are green (Format,
Clippy, Test ×3, Build release macOS/Windows, GitGuardian). The `Spec lint` failure is
expected and advisory per D-029 (25 placeholders + 13 EC collisions).
