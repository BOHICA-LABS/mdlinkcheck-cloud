# D-028 Fresh-Eyes Review — PR #6 @ `a642d24`

**Head SHA verified:** `a642d241e108760e4199242d2ba4e5905c851fde` — matches mandate, no drift.
**Base:** `develop` @ `651ee3a`. **Diff:** 4 files, +1770/−1.
**`Spec lint` CI FAILURE treated as ADVISORY** per D-029/D-032 (25 `[filled by story-writer]` placeholders — independently counted: 25).

## Verdict

REQUEST_CHANGES

One blocking item, cheap and local to files this PR already owns. The write gates are genuinely
sound — I could not reach a write through any CLI path — and nothing regressed. But the
headline deliverable, `check-canonical-facts.py`, is wired into **no runner at all**, and
BI-035 is only half-discharged: for FACT-9 and FACT-10 the production binding patterns cannot
detect the very readings D-061 and D-062 forbid. I verified that empirically, not by reading.

---

## 1. BI-035 per-fact verification

Two things must both hold for BI-035 to be discharged for a fact: (a) the checker engine can
reach the VALUE-MISMATCH branch, and (b) the *production* binding pattern in
`canonical-facts.toml` actually rejects the forbidden reading. The selftests establish (a).
I tested (b) separately, because the selftests do not: tests 19–22 each define their **own
synthetic** fact and a synthetic pattern of shape `'... "(.*?)"'`, not the production pattern.

| Fact | Negative vector in selftest | Branch the test fires on | Production pattern | Production pattern rejects that vector? |
|---|---|---|---|---|
| FACT-7 | `"macOS and Linux"` | **VALUE-MISMATCH** (`m.group(1) != canonical`) | `\*\*Platform matrix:\*\* (.*?) \(` | **YES** — captures `macOS and Linux` ≠ `macOS` |
| FACT-8 | `"macOS and Windows"` | **VALUE-MISMATCH** | `ASM-004 \| Platform matrix is (.*?) \(` | **YES** — captures `macOS and Windows` ≠ `macOS only` |
| FACT-9 | `"missing-.md file destinations only"` | **VALUE-MISMATCH** | `directories from (every extracted link destination)` | **NO** — capture group is a literal; only "pattern did not match" is reachable, and an *appended narrowing qualifier* passes outright |
| FACT-10 | `"invalid \`--ignore\` glob or unrecognized flag"` | **VALUE-MISMATCH** | `sole trigger: (invalid \`--ignore\` glob)` | **NO** — **the exact selftest-22 vector PASSES** |

Verified on the VALUE-MISMATCH branch, not a fallback: mutation **M2** neuters the
`if not m:` ("pattern did not match") branch. Tests 19–22 all still **PASS** under M2; only
test 25 flips. Mutation **M1** neuters `elif m.group(1) != canonical:` and flips exactly
18, 19, 20, 21, 22. So the four tests are non-vacuous *with respect to the checker engine* —
they genuinely exercise the value-comparison branch.

**D-057 — positive count: SATISFIED.** Live run: `canonical-facts: OK — all 31 bindings match
canonical values (11 facts)`. The checker also fails closed on zero facts or zero bindings
(`check-canonical-facts.py:70–75`).

### The FACT-9 / FACT-10 gap, demonstrated

17 of 31 bindings bake the canonical value into the regex as a literal, making the capture
group tautological — `m.group(1)` can only ever equal `canonical_value`, so VALUE-MISMATCH is
structurally unreachable and the binding degrades to a bare presence check. That covers
**all 6 FACT-9 bindings and all 7 FACT-10 bindings** (plus 2 FACT-1, FACT-6a, FACT-6b).

Because a presence check is a prefix match with no right-hand terminator, appending text
after the canonical phrase still matches:

```
FACT-10 b1  'sole trigger: (invalid `--ignore` glob)'
  input : "sole trigger: invalid `--ignore` glob or unrecognized flag or bad --output"
  result: PASSES  (group(1) == canonical) -> checker exits 0

FACT-9  b2  'build DirIndex for (every extracted link destination)'
  input : "build DirIndex for every extracted link destination, restricted to .md files only"
  result: PASSES -> checker exits 0

FACT-1  b1  'sort_unstable_by_key[^;]*(link_target)'
  input : "sort_unstable_by_key(|f| (f.path, f.line, link_target))  // col dropped"
  result: PASSES -> three-field sort key accepted
```

The first case is the D-062-forbidden second `config_error` trigger. The second is the
D-061-rejected narrow DirIndex reading. Both slip through silently. The
`canonical-facts.toml` header comments assert "Adversarial validation (ALL PASS)" for FACT-9
and FACT-10, listing only *substitution* vectors; no *appended-qualifier* vector was tried,
and that is the class that defeats a prefix presence check.

`canonical-facts.toml` is not in this PR's diff and lives under `.factory/specs/` (held by a
concurrent editor, D-058), so this cannot be fixed here. It must not be closed as discharged.

---

## 2. Write-gate attack results

All experiments ran against isolated temp trees seeded with a copy of `.factory/specs`
(140 files) under `SPEC_LINT_REPO_OVERRIDE`. Verification after every invocation was a full
recursive `shasum` manifest diff, not an eyeball. The real `.factory/specs/` was never a
write target. **No CLI invocation of either generator reached a write without an explicit
`--write` token.**

### Fixture

```
SB=$(mktemp -d); mkdir -p "$SB/tree/.factory"
cp -R .factory/specs "$SB/tree/.factory/specs"
snap(){ (cd "$SB/tree" && find . -type f -print0 | xargs -0 shasum | sort); }
```

### `gen-bc-traceability` — no argv reaches a write, at all

| argv | rc | tree | gate that fired |
|---|---|---|---|
| *(bare)* | 1 | CLEAN | Gate 1 (concurrency) |
| `--check` | 1 | CLEAN | ran, 786 diff lines |
| `--dry-run` | 0 | CLEAN | preview only |
| `--write` | 1 | CLEAN | Gate 2 (BI-041) |
| `--check --write` | 1 | CLEAN | Gate 2 |
| `--write --check` | 1 | CLEAN | Gate 2 |
| `--dry-run --write` | 1 | CLEAN | Gate 2 |
| `--write --dry-run` | 1 | CLEAN | Gate 2 |
| `--write --write` | 1 | CLEAN | Gate 2 |
| `--dry-run --check --write` | 1 | CLEAN | Gate 2 |
| `--check --dry-run` | 1 | CLEAN | check ran |
| `--write extra-positional` | 1 | CLEAN | Gate 2 |
| `-- --write` | 1 | CLEAN | Gate 2 |
| `--WRITE` / `-w` / `--write=1` / `--write=true` / `--no-write` / `"--write "` | 1 | CLEAN | Gate 1 |

### `gen-slug-corpus` — writes only on a literal `--write`

| argv | rc | tree |
|---|---|---|
| *(bare)* | 1 | CLEAN |
| `--check` | 1 | CLEAN |
| `--dry-run` | 0 | CLEAN |
| `--check --write` / `--write --check` | 1 | CLEAN (non-destructive `--check` wins) |
| `--dry-run --write` / `--write --dry-run` | 0 | CLEAN (`dry_run` wins the `if/elif`) |
| `--WRITE` / `-w` / `--write=1` / `--write=true` / `--no-write` / `"--write "` | 1 | CLEAN |
| `--write` | 0 | **WROTE** (intended opt-in) |
| `--write --write`, `--write extra-positional`, `-- --write` | 0 | **WROTE** (explicit `--write` present — correct) |

### Env-var attack — all refused, tree clean

`SPEC_LINT_WRITE=1`, `SPEC_LINT_FORCE=1`, `SPEC_LINT_ALLOW_WRITE=1`, `GEN_WRITE=1`,
`WRITE=1`, `FORCE=1` — each with no `--write`: rc=1, TREE-CLEAN. No environment variable
influences the gate. `SPEC_LINT_REPO_OVERRIDE` pointed at a fully writable tree does **not**
bypass the opt-in.

### `--check` has no write side effect

Confirmed for both generators: `--check` builds content in memory only
(`compute_new_bc_content` is pure; `gen-slug-corpus` compares `new_content == content`).
Manifest unchanged after every `--check` run. No helper writes as a side effect of `--check`.

### Gate independence — CONFIRMED, and stronger than the PR body claims

- Remove **Gate 1 only** (mutation M5) → bare invocation of `gen-bc-traceability` falls through
  Gate 2 (`if write_mode:` is False) into the write loop with `dry_run=False` and **writes**.
  Selftest 27 flips to FAIL.
- Remove **Gate 2 only** (mutation M4) → `--write` reaches the write loop and **writes**.
  Selftest 26 flips to FAIL.

Neither gate can be satisfied by the other: passing Gate 1 requires one of
`--check`/`--dry-run`/`--write`, and `--write` immediately trips Gate 2. Both are load-bearing
and both are independently mutation-verifiable. The PR body's claim that "Gate 2 prevents full
independent mutation-verify of Gate 1 alone" is **incorrect in the conservative direction** —
Gate 1 *is* independently verifiable (see MINOR-5).

### The one reachable write path (not CLI)

`gen-bc-traceability.update_bc_file(path, value, dry_run=False)` is a module-level function
that writes with **zero gate evaluation** — both gates live only in `main()`. Confirmed:

```python
spec.loader.exec_module(m)                       # no write at import time (good)
m.update_bc_file(f, v, dry_run=False)            # -> True, file written, no gate consulted
```

This requires deliberately importing the module and calling its writer, so it is outside the
stated threat model (accidental bare invocation) and I am not treating it as blocking. It is a
defense-in-depth gap worth closing (MINOR-3).

---

## 3. BI-021 assessment — `_find_repo_root()`

`check-canonical-facts.py:31–48`. Three questions, three tests.

**Can it walk out of the intended repo? YES — and it reports success.**

```
/tmp/outer/.factory/specs/canonical-facts.toml   <- UNRELATED repo's facts (FACT-ALIEN)
/tmp/outer/inner-repo/scripts/spec-lint/check-canonical-facts.py   <- no .factory here

$ cd /tmp/outer/inner-repo && python3 scripts/spec-lint/check-canonical-facts.py
canonical-facts: OK — all 1 bindings match canonical values (1 facts)
rc=0
bound REPO = /private/tmp/bi021.Ya6jFa      <- the unrelated ancestor
```

The walk has no repo-boundary stop condition — it never checks for `.git`. With `.factory/`
absent from the checkout (its normal state: `.factory/` is a **separate git worktree on the
`factory-artifacts` orphan branch**, per `git worktree list`), the walk escapes and validates a
**foreign repo's** facts, then prints OK and exits 0. The superseded
`parent.parent.parent` heuristic **failed closed** in this scenario (looked for
`inner-repo/.factory/...`, not found, exit 1). So the BI-021 fix converts a fail-closed miss
into a fail-open false GREEN. That inversion is the concerning part, not the path arithmetic.

Reachability is currently limited: `ci.yml` mounts the orphan branch at `path: .factory`, so CI
resolves correctly, and the local dev worktree is mounted too. The exposure is nested clones
and any runner variant that does not mount `.factory`. Latent, not live — hence MAJOR, not
blocking.

**Does it fail closed when nothing is found? YES.**
```
ERROR: canonical-facts.toml not found at /private/tmp/.../r/.factory/specs/canonical-facts.toml
rc=1
```

**Is 8 levels arbitrary in a way that breaks deep worktrees? Mildly.**
A root 9 levels above `scripts/spec-lint` is missed; it fails closed (rc=1) but the error
message names the `parent.parent.parent` fallback path rather than the real root, which will
mislead whoever debugs it. `scripts/spec-lint` needs 3, `.worktrees/STORY-N/scripts/spec-lint`
needs 5, so 8 is adequate today. A `.git`-boundary stop would make the number irrelevant.

**Is the same bug still in other checkers? YES — worse than reported.** `parent.parent.parent`
survives in **8** other checkers (mandate said 7) and in **both generators this PR adds**:

```
check-adr-consistency.py:26   check-counts.py:26        check-id-resolution.py:35
check-ec-injectivity.py:27    check-holdout-boundary.py:34  check-index-integrity.py:20
check-placeholders.py:39      check-title-sync.py:17
gen-bc-traceability.py:50     gen-slug-corpus.py:52     (+ 4 pre-existing gen-*.py)
```

BI-021 is fixed in 1 of 9 checkers and 0 of 6 generators. The PR body is honest about this
("No changes to any other checker"), so this is scope, not misrepresentation — but the two
generators are *new in this PR* and shipped with the known-bad heuristic.

---

## 4. Cherry-pick integrity — my own count

I did not accept the reported numbers. Counting `TESTS_RUN=$((TESTS_RUN + 1))` occurrences:

| ref | increments | `EXPECTED_TEST_COUNT` | consistent? |
|---|---|---|---|
| `78ef3a4` (stale branch tip) | 18 | 18 | yes |
| `01736e7` (cherry-pick) | 37 | 36 | **NO** |
| `651ee3a` (develop) | 36 | 36 | yes |
| `a642d24` (PR HEAD) | **47** | **47** | yes |

**47/47 confirmed** by execution, twice — once in-tree, once from an independent copy at a
different path: `Selftest passed: 47/47 negative tests verified`, rc=0, 47 `PASS` lines,
0 `FAIL` lines.

**Nothing lost resolving the `run-selftests.sh` conflict.** Diffing develop's version against
HEAD's, exactly **one** line is removed:

```
$ diff <(git show 651ee3a:.../run-selftests.sh) <(git show a642d24:.../run-selftests.sh) | grep '^<'
< EXPECTED_TEST_COUNT=36
```

That is it. All 36 of develop's increments survive; the set difference of test headers is
additive-only (Tests 18–28 added, none removed). Develop's 36 → 47 is honest; note the PR body
says "17 → 47", which is the *stale branch's* baseline, not develop's (MINOR-5).

**`check-index-integrity.py` conflict resolved correctly.** HEAD is byte-identical to develop
(`0035ab6922ea`, 1070 lines), **not** the stale branch's regressed 413-line version
(`029ee3d79d09`). The 11-cycle-reviewed version was preserved.

**Pre-flight guard refactor preserved, not reverted.** Lines 1–135 of `run-selftests.sh` are
byte-identical to develop except `EXPECTED_TEST_COUNT`. `run_override_guard` and
`run_suppression_guard` remain the glob-based (`for f in "$dir"/check-*.py`) versions with
their D-057 runtime counts and zero-files fail-closed branches. The cherry-pick's inline loop
did not come back.

**New checker is auto-detected by both guards.** `check-canonical-facts.py` matches the
`check-*.py` glob and its line 51 satisfies `OVERRIDE_PATTERN`
(`^REPO[[:space:]]*=.*SPEC_LINT_REPO_OVERRIDE`). Live guard output confirms 9 checkers scanned.
The two new `gen-*.py` files fall outside the glob (MINOR-2).

---

## 5. Mutation results per new test (D-040 / D-050)

Each mutation applied to a pristine copy of `scripts/`, then the **full** suite run, recording
which tests flipped. Every one of the 11 new tests is load-bearing, and no mutation flipped a
test it should not have.

| # | Mutation (guard/fix reverted) | Expected to flip | Actually flipped | Load-bearing |
|---|---|---|---|---|
| M1 | `elif m.group(1) != canonical:` → `elif False:` | 18–22 | **18, 19, 20, 21, 22** | YES |
| M2 | `if not m:` → `if False:` (no-match branch) | 25 only | **25** only | YES — proves 19–22 are on the `!=` branch |
| M3 | `_find_repo_root()` → `parent.parent.parent` | 25 | **25** (rc=2) | YES |
| M4 | delete `gen-bc-traceability` Gate 2 (BI-041) | 26 | **26** | YES |
| M5 | delete `gen-bc-traceability` Gate 1 (concurrency) | 27 | **27** | YES (contra PR body) |
| M6 | delete `gen-slug-corpus` Gate 1 (concurrency) | 28 | **28** | YES |
| M7 | `gen-bc-traceability --check` always reports OK | 23 | **23** | YES |
| M8 | `gen-slug-corpus --check` always reports OK | 24 | **24** | YES |

**The guard tests are load-bearing, not advisory.** Test 27 and test 28 both assert
file-byte-identity after refusal, and both flip when their guard is removed. Tests 26/27/28
each cause a non-zero suite exit when flipped, so they gate the suite rather than merely
reporting.

---

## 6. Docstring accuracy

Applying check-index-integrity-grade scrutiny. No overclaim rises to MAJOR, but there are
three real gaps and one description of code that can never execute.

| Claim | Location | Verdict |
|---|---|---|
| "This checker has NO bypass mechanism… no `--force` flag, no skip environment variable, no allowlist file. Every binding is always checked." | `check-canonical-facts.py:12–14` | **ACCURATE** — verified by env-var attack and D-039 scan |
| Write mode is gated, and why | `gen-bc-traceability.py:23–31`, `41–42` | **ACCURATE** — names both gates and their ordering |
| `gen-bc-traceability` is lossy | `gen-bc-traceability.py:288–310` | **ACCURATE but understates scope** — names 3 INC-MAP annotations; actual blast radius is ~20+ annotated Architecture Module rows (MINOR-4) |
| "The three hand-authored functions… and the Phase-3 integration skeleton are NEVER touched." | `gen-slug-corpus.py:23–25` | **ACCURATE** — surgery is marker-bounded; confirmed by the 2-line `--check` diff |
| "`--check` … exits 1 with a unified diff if different" | both generators | **MECHANISM ACCURATE, STATUS OMITTED** — neither docstring says `--check` **currently FAILS** against the live tree (786 lines / 2 lines). A reader assumes green. (MINOR-1) |
| MARKER STRATEGY: "On first run (no markers)… On re-runs (markers exist)…" | `gen-bc-traceability.py:13–19` | **DESCRIBES UNREACHABLE CODE** — no CLI argv reaches the write path, so neither branch can execute. Reads as operational. (MINOR-1) |
| `_find_repo_root` docstring | `check-canonical-facts.py:32–42` | **INCOMPLETE** — documents the fallback but not that the walk can bind an unrelated ancestor and report OK. Folded into MAJOR-2. |

---

## 7. D-039 compliance

**PASS.** No allowlist, skip-list, deferral set, known-issues collection, exemption set, or
bypass flag in any of the three new files — including disguised forms. Greps for
`allowlist|whitelist|skip_list|skip_set|deferral|known_(collisions|violations|issues)|suppress|exempt|EXCLUDE|BYPASS|--force|phase.?2.?defer`
return only D-039 *compliance prose* in comments. No uppercase collection literals
(`^\s*[A-Z_]{4,}\s*[=:]\s*[\{\[\(]`) exist in any of the three. Applying the suite's own
`SUPPRESSION_PATTERN` directly to all three files: clean.

No checker gained an exemption set. Agreed that a **write gate is not a suppression
construct** — it gates a destructive action and hides no defect; both gates print their
rationale to stderr and return non-zero rather than silently continuing. The BI-041 gate is
also correctly implemented with **no bypass flag**, which is the D-039-critical property.

---

## 8. Regressions

| Check | Result |
|---|---|
| `check-index-integrity.py` unmodified | **PASS** — absent from diff; SHA identical to develop |
| All checkers clean on live tree | **PASS** — 8/9 rc=0; only `check-placeholders` rc=1 |
| `check-placeholders` = 25 known placeholders | **PASS** — `25 placeholder occurrences found (133 files checked)` |
| `git status` clean | **PASS** — empty |
| Nothing under `.factory/specs/` modified (D-058) | **PASS** — `.factory` worktree shows only `logs/*.jsonl` and `sidecar-learning.md` |
| Nothing under `.factory/holdout-scenarios/` modified | **PASS** |
| `gen-slug-corpus` divergence is cosmetic-only | **CONFIRMED independently** — exactly 2 lines, both whitespace: `// @GENERATED:END slug-corpus` loses its 4-space indent, and one `assert_eq!` message loses 2 spaces of padding. No corpus entry added or removed; no assertion logic changed. |
| BI-041 premise (write mode is lossy) | **CONFIRMED, broader than stated** — see MINOR-4 |

BI-041 spot-check in the sandbox: `gen-bc-traceability` write on `BC-2.03.002.md` replaced
`— ADR-003 (pulldown-cmark event stream)` with `— ADR-003 (pulldown-cmark 0.13.4 as the
Markdown Parser)`. Across the tree, `format_arch_module_value()` emits only
`` `mod.rs` (SS-NN, pe, TIER tier) — ADRs[; secondary: x.rs] `` and therefore cannot reproduce
~20+ rows carrying hand-authored semantics — e.g. `BC-2.11.004.md:86` (INC-MAP-003),
`BC-2.03.005.md:78` (INC-MAP-002), `BC-2.01.003.md:81` (INC-MAP-004), plus rows like
"NO_COLOR / CLICOLOR env vars read by cli", "`--ignore`'d files still have anchor tables
built", "`anchor_resolver.rs` (SS-08) never called for directory targets". **Gate 2 is
justified**, and its premise is stronger than the PR body states. Not re-raised as blocking.

---

## Findings

### BLOCKING-1 — `check-canonical-facts.py` is wired into no runner; it never gates anything
**File:** `.github/workflows/ci.yml:227–239` and `justfile` `spec-lint:` recipe
**Category:** missing / enforcement

The new checker appears **only** inside `selftest/run-selftests.sh`. It is absent from the CI
`CHECKS=(...)` array and from the `just spec-lint` recipe. It is the **only** `check-*.py` on
disk that is not in either list:

```
$ comm -23 <(ls scripts/spec-lint/check-*.py | xargs -n1 basename | sed 's/.py$//' | sort) \
           <(sed -n '/CHECKS=(/,/)/p' .github/workflows/ci.yml | grep -oE '"check-[a-z-]+"' | tr -d '"' | sort)
check-canonical-facts
```

**Failure scenario:** an author edits `product-brief.md` to say
`**Platform matrix:** macOS and Linux (…)`, reversing D-043 at the L1 root of the traceability
chain. `check-canonical-facts.py` detects this correctly (FACT-7's pattern reaches
VALUE-MISMATCH — verified above). But no CI job and no `just` target ever invokes it, so the
`Spec lint` check-run stays green, the PR merges, and the divergence class BI-012 exists to
close recurs undetected across all 31 bindings. The suite proves the checker *can* fail; nothing
ever gives it the chance.

**Fix:** add `"check-canonical-facts"` to the `CHECKS` array in both `.github/workflows/ci.yml`
and `justfile`. Neither file is under `.factory/specs/`, so this is in scope for this PR and
does not touch the held spec tree. Consider replacing both hardcoded arrays with a glob over
`scripts/spec-lint/check-*.py`, matching the pre-flight guards' auto-detection — that closes the
class rather than this instance.

### MAJOR-1 — BI-035 is not discharged for FACT-9 or FACT-10; selftests 21/22 assert a branch the production bindings cannot reach
**File:** `scripts/spec-lint/selftest/run-selftests.sh:1014` (test 21), `:1078` (test 22)
**Category:** coverage / vacuous-by-proxy

Tests 21 and 22 define synthetic patterns of shape `'DirIndex scope: "(.*?)"'` and
`'config error trigger: "(.*?)"'`. The production FACT-9 and FACT-10 bindings are literal-baked
(`'directories from (every extracted link destination)'`,
`'sole trigger: (invalid \`--ignore\` glob)'`) and are therefore prefix presence checks whose
capture group is tautological.

**Failure scenario:** an author writes into `capabilities.md`
`sole trigger: invalid \`--ignore\` glob or unrecognized flag` — the exact string selftest 22
declares must be rejected, and exactly what D-062 forbids. The production pattern matches,
`group(1) == 'invalid \`--ignore\` glob'`, and the checker prints
`canonical-facts: OK — all 31 bindings match` and exits 0. Symmetrically for FACT-9:
`build DirIndex for every extracted link destination, restricted to .md files only` passes,
re-admitting the narrow reading D-061 rejected. Test 22 stays green throughout, because it never
exercises the production pattern.

**Fix:** cannot be done in this PR — requires editing `canonical-facts.toml` under
`.factory/specs/`. Raise a new blocker for architect adjudication: anchor the 17 literal-baked
patterns with a right-hand terminator (e.g.
`'sole trigger: (invalid \`--ignore\` glob) pattern\.'`), or move the canonical value out of the
regex and into a flexible capture so the VALUE-MISMATCH branch becomes reachable. Separately,
consider a structural guard that rejects any binding whose capture group is a literal equal to
its `canonical_value` — that closes the class. **BI-035 must not be marked discharged for
FACT-9 / FACT-10.**

### MAJOR-2 — `_find_repo_root()` fails OPEN: escapes the repo, binds an unrelated ancestor, reports exit 0
**File:** `scripts/spec-lint/check-canonical-facts.py:43–48`
**Category:** correctness / fail-safety

```python
candidate = Path(__file__).resolve().parent
for _ in range(8):
    if (candidate / ".factory" / "specs" / "canonical-facts.toml").exists():
        return candidate
    candidate = candidate.parent
```

No repo-boundary stop condition.

**Failure scenario:** a developer clones this repo into a subdirectory of another factory
project, or runs the checker in an environment where `.factory/` is not mounted (its default
state — `.factory/` is a separate worktree on the `factory-artifacts` orphan branch). The walk
ascends past the repo root and binds to the *outer* project's
`.factory/specs/canonical-facts.toml`. Demonstrated above: exit 0,
`canonical-facts: OK — all 1 bindings match canonical values`, `REPO` bound to
`/private/tmp/bi021.Ya6jFa` — a completely unrelated tree. The superseded
`parent.parent.parent` heuristic **failed closed** here. The fix therefore replaced a
fail-closed miss with a fail-open false GREEN in a checker whose entire value is fail-closed
enforcement.

**Fix:** stop the walk at the repo boundary, and keep failing closed:
```python
for _ in range(8):
    if (candidate / ".factory" / "specs" / "canonical-facts.toml").exists():
        return candidate
    if (candidate / ".git").exists():   # file or dir — covers worktrees
        break
    candidate = candidate.parent
```
Also update the docstring, which documents the fallback but not the escape.

### MAJOR-3 — `parent.parent.parent` survives in 8 other checkers and in both generators this PR adds
**Files:** `check-adr-consistency.py:26`, `check-counts.py:26`, `check-id-resolution.py:35`,
`check-ec-injectivity.py:27`, `check-holdout-boundary.py:34`, `check-index-integrity.py:20`,
`check-placeholders.py:39`, `check-title-sync.py:17`, `gen-bc-traceability.py:50`,
`gen-slug-corpus.py:52`
**Category:** missing

Confirmed true, and one checker worse than the mandate reported (8, not 7). Additionally, the
two generators **introduced by this PR** ship with the known-bad heuristic rather than the fix.

**Failure scenario:** running `just spec-lint` from `.worktrees/STORY-NNN/` — the BI-021
scenario — leaves 8 of 9 checkers resolving `REPO` to the worktree root, which has no
`.factory/`. They exit 1 with "file not found", indistinguishable from a genuine spec defect,
and BI-021 recurs for every checker except the one that was fixed. **Fix:** extract
`_find_repo_root()` (with the MAJOR-2 boundary guard) into a shared helper imported by all
checkers and generators; add a pre-flight guard asserting no `check-*.py` or `gen-*.py`
contains a bare `parent.parent.parent` fallback.

### MINOR-1 — Generator docstrings omit live `--check` status and describe unreachable write behavior
**File:** `gen-bc-traceability.py:13–19`, `:35–37`; `gen-slug-corpus.py:38–40`
Neither docstring records that `--check` **currently FAILS** against the live tree (786 diff
lines / 2 diff lines), nor that the `gen-slug-corpus` divergence is cosmetic-only. The MARKER
STRATEGY section narrates "On first run… On re-runs…" write behavior that no CLI argv can reach.
**Failure scenario:** a maintainer reads the docstring, assumes `--check` is green, wires it into
CI as a required gate, and the build fails immediately with 786 unexplained diff lines. Add two
sentences recording current status, BI-041, and the cosmetic-only verdict.

### MINOR-2 — Pre-flight structural guards glob `check-*.py` only; the two new generators are unguarded
**File:** `scripts/spec-lint/selftest/run-selftests.sh:57`, `:81`
Both guards iterate `"$dir"/check-*.py`, so neither the `SPEC_LINT_REPO_OVERRIDE` guard nor the
D-039 `SUPPRESSION_PATTERN` guard ever inspects `gen-*.py`. **Failure scenario:** a future edit
adds `KNOWN_ISSUES = {...}` to `gen-bc-traceability.py` to skip BC files that fail to parse; the
D-039 suppression guard passes because it never reads the file, and the suppression ships. The
gap pre-dates this PR (4 generators already existed) but this PR adds 2 more. Extend both globs
to `{check,gen}-*.py`.

### MINOR-3 — Module-level write helpers bypass both gates
**File:** `gen-bc-traceability.py:237–258` (`update_bc_file`), `gen-slug-corpus.py:484`
Both gates live in `main()`; `update_bc_file(path, value, dry_run=False)` writes with no gate
consulted (demonstrated above). **Failure scenario:** a future helper script or `python -c`
one-liner imports the module to reuse `format_arch_module_value()`, calls `update_bc_file`, and
destroys INC-MAP annotations with Gate 2 never evaluated. Move the BI-041 refusal into
`update_bc_file` itself, or gate on a module-level flag that only `main()` sets.

### MINOR-4 — BI-041 comment understates the blast radius
**File:** `gen-bc-traceability.py:296–300`
Names INC-MAP-002/003/004 "and any future hand-authored annotations". The actual count of
Architecture Module rows carrying hand-authored semantics that `format_arch_module_value()`
cannot reproduce is ~20+. Understating the loss in the comment that *justifies* the gate risks
a future reader concluding the gate is cheap to lift. Record the real count.

### MINOR-5 — PR body inaccurate in two places (both conservative)
**File:** PR #6 description
1. "Selftest count: 17 → 22" and "count: 17 → 47" — `17` is the **stale branch's** baseline.
   Develop's is **36**; the honest figure is 36 → 47. Understates work landed.
2. "Gate 2 prevents full independent mutation-verify of Gate 1 alone (both gates prevent
   writing)" — **false**. Mutation M5 (Gate 1 removed, Gate 2 intact) makes bare invocation
   write and flips selftest 27. Gate 1 *is* independently mutation-verified. Understates rigor.

All 8 test-plan checkboxes verified accurate. The `gen-slug-corpus` cosmetic-only verdict is
accurate.

### MINOR-6 — Intermediate commit `01736e7` fails its own selftest
**File:** `scripts/spec-lint/selftest/run-selftests.sh:27` at `01736e7`
37 increments vs `EXPECTED_TEST_COUNT=36` → the post-test invariant fires:
```
STRUCTURAL GUARD FAILED: expected 36 tests, ran 37
rc=2
```
**Failure scenario:** `git bisect` across this range lands on `01736e7`, the suite exits 2, and
the bisect records a false "bad" unrelated to the defect being hunted. Harmless under
squash-merge; note it if the merge preserves history.

### MINOR-7 — Dead `insertion` variable is the root cause of the END-marker indent divergence
**File:** `gen-slug-corpus.py:360`
```python
insertion = f"\n    {corpus_block.replace(chr(10), chr(10) + '    ')}"   # computed, never used
return content[:insert_at] + "\n" + corpus_block + content[insert_at:]   # unindented
```
The indented form is built and discarded, so the generator emits `// @GENERATED:END
slug-corpus` flush-left inside an indented Rust array — which is exactly diff line 1 of the
2-line live divergence. The generator cannot reproduce its own committed artifact. Cosmetic, but
it means `--check` can never go green without either fixing this or accepting a de-indent.

---

## What remains open after this PR

1. **BLOCKING-1** — wire `check-canonical-facts` into `ci.yml` + `justfile`. Fixable here.
2. **MAJOR-2** — add the `.git` boundary stop to `_find_repo_root()`. Fixable here.
3. **MAJOR-1 / new blocker** — 17 literal-baked binding patterns, including all of FACT-9 and
   FACT-10, cannot reject their forbidden readings. Requires `.factory/specs/` edits →
   architect adjudication. **BI-035 must not be closed as discharged for FACT-9/FACT-10.**
4. **BI-041** (accepted, not re-raised) — write mode remains fail-closed; premise confirmed and
   broader than documented. Architect adjudication.
5. **Live `--check` divergence** (accepted, not re-raised) — 786 lines for
   `gen-bc-traceability`, 2 cosmetic lines for `gen-slug-corpus`. Neither generator has been run
   against `.factory/specs/`.
6. **MAJOR-3** — BI-021 unfixed in 8 checkers and 6 generators.

## What I verified and found sound

- Write gates: no CLI argv, env var, repeated flag, or `SPEC_LINT_REPO_OVERRIDE` redirection
  reaches a write without an explicit `--write`. Both gates independent, both load-bearing,
  both mutation-verified. `--check` and `--dry-run` are ungated and provably non-destructive.
- All 11 new selftests are load-bearing: 8 mutations, each flipping exactly the intended tests.
- Tests 19–22 fire on the VALUE-MISMATCH branch, not the no-match fallback (proved via M2).
- 47/47 confirmed by execution from two independent paths; develop's 36 all preserved; exactly
  one line removed in the conflict resolution.
- `check-index-integrity.py` byte-identical to develop; the 11-cycle work was not clobbered.
- Pre-flight guard refactor preserved; the new checker is auto-detected.
- D-039: clean, including disguised forms. D-057: positive count reported.
- `git status` clean; `.factory/specs/` and `.factory/holdout-scenarios/` untouched (D-058).

*Note: `gh pr review` is unsatisfiable on this PR (BI-039 — GraphQL "Can not request changes on
your own pull request", root cause D-021). Posted via `gh pr comment` as pre-authorized.*
