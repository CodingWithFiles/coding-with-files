# Make cwf-manage update handle a dirty working tree - Testing Execution
**Task**: 116 (bugfix)

## Task Reference
- **Task ID**: internal-116
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/116-make-cwf-manage-update-handle-a-dirty-working-tree
- **Template Version**: 2.1

## Goal
Execute every test case in e-testing-plan.md and record results.

## Test Environment
- Working tree: `bugfix/116-make-cwf-manage-update-handle-a-dirty-working-tree` at f-impl-exec checkpoint `d92c9a7`.
- Perl: system Perl with `PERL5OPT=-CDSL` (preserves Task 115 boy-scout fix).
- Locale: `LANG=C.UTF-8`.
- Test fixtures: per-subtest `tempdir(CLEANUP => 1)` + `git init` baseline (helper `make_baseline_repo` in the test file). End-to-end smokes: `mktemp -d` + `git init` shell fixtures, torn down after each scenario.

## Test Results

### Functional Tests — Unit (`t/cwf-manage-check-clean-tree.t`)

Run: `prove t/cwf-manage-check-clean-tree.t` (and full `prove t/`)

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-1 | clean tree → returns | `$@` empty | matches | **PASS** |
| TC-2 | dirty (tracked + untracked) → dies; lists both paths; recipe present | `$@` matches `qr{Working tree has uncommitted changes}` AND `qr{\.cwf/version}` AND `qr{notes\.md}` AND `qr{git stash}` | all 4 assertions match | **PASS** |
| TC-3 | git status fails → dies with check-failure message | `$@` matches `qr{Failed to check working tree status}` | matches (git emits its own `fatal: cannot change to '/nonexistent/path'` to STDERR before our die catches `$? != 0`; expected and harmless) | **PASS** |

### Functional Tests — End-to-end smokes

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-4 | Clean tree, env override — `CWF_SOURCE=file:///tmp/cwf-nonexistent cwf-manage update` against fixture | `Cloning CWF source from file:///tmp/cwf-nonexistent (from: CWF_SOURCE env var)...` log + clone failure; **no** dirty error | exact match: `[CWF] Updating CWF (method: copy, ref: latest)` then `[CWF] Cloning CWF source from file:///tmp/cwf-nonexistent (from: CWF_SOURCE env var)...` then git clone error then `[CWF] ERROR: Failed to clone file:///tmp/cwf-nonexistent`. Exit 1. | **PASS** |
| TC-5 | Dirty `.cwf/`, env override (load-bearing — the bug being fixed) — `echo dirt > .cwf/foo.txt; CWF_SOURCE=file:///tmp/cwf-nonexistent cwf-manage update` | Dirty error + recipe; **no** clone attempt; exit 1 | exact match — see detail below | **PASS** |
| TC-6 | Dirty file outside scope — `echo more >> README.md; cwf-manage update` (with `.cwf/` clean) | **No** dirty error; update proceeds to `Cloning CWF source...` | proceeded as expected; `[CWF] Updating CWF (method: copy, ref: latest)` then `[CWF] Cloning CWF source from file:///tmp/cwf-nonexistent (from: CWF_SOURCE env var)...` then unrelated clone failure. No dirty error appeared. | **PASS** |

#### TC-5 detail (load-bearing)

**Setup**: tempdir test repo with `.cwf/version` baseline committed; then `echo dirt > .cwf/foo.txt` to introduce an untracked file inside `.cwf/`.

**Action**: `CWF_SOURCE=file:///tmp/cwf-nonexistent cwf-manage update`

**Output** (verbatim):
```
[CWF] ERROR: Working tree has uncommitted changes under .cwf, .cwf-skills:
  ?? .cwf/foo.txt
Stash or commit them, then re-run:
  git stash
  cwf-manage update [ref]
  git stash pop
```

**Exit code**: 1

**Critical assertion**: **NO** `[CWF] Cloning CWF source...` log line appears. The dirty check fires before `tempdir`/`git clone`, exactly as c-design Decision 4 specified.

#### TC-6 detail — fixture footnote

First attempt failed because `git stash` (without `-u`) does not stash untracked files, so `.cwf/foo.txt` from TC-5's setup persisted into TC-6 and tripped the check. Re-ran with a fresh fixture (no carry-over) — PASS.

This is a g-testing-exec fixture issue, not a product bug. The behaviour under test (dirty file outside scope = no error) is the documented intent and is now confirmed.

### Non-Functional Tests

| Aspect | Test | Result | Status |
|--------|------|--------|--------|
| **Usability — error wording** | TC-5 output | Recipe is exactly `git stash` / `cwf-manage update [ref]` / `git stash pop` (copy-pasteable); identifies which paths are dirty | **PASS** |
| **Usability — help text** | `cwf-manage help` after change | Output includes the `Notes:` section between `Environment:` and `Examples:`, with the documented wording | **PASS** |
| **Reliability — no destructive op on dirty** | TC-5 | No `Cloning CWF source...` log; check fires before `tempdir`/`git clone` | **PASS** |
| **Reliability — defensive on git failure** | TC-3 (unit) | Non-zero `$?` from `git status` does **not** silently proceed | **PASS** |
| **Backwards compatibility** | TC-4 + full `prove t/` | Clean-tree update path unchanged from Task 115; existing 235 tests still pass | **PASS** |
| **Convention — script-hash integrity** | `cwf-manage validate` after re-hash | exits 0; sha256 in `.cwf/security/script-hashes.json` matches modified script | **PASS** |
| **Inheritance — `cmd_rollback` delegation** | Code review of `cwf-manage:288–294` | `cmd_rollback` calls `cmd_update($git_root, $ref)` unconditionally — dirty check inherited | **PASS** |

Performance and security testing not relevant: helper is one `git status` invocation + a list comparison; no new network or auth surface.

## Test Failures
None.

## Coverage Report
- **`check_clean_tree`**: 100% branch coverage of the contracted paths (clean / dirty / status-fail) via TC-1..TC-3. Spawn-fail (open `'-|'` returns false) — covered by code review only; not feasibly trigger-able in a sandbox.
- **`cmd_update` call site**: smoke-tested by TC-5 (dirty path) and TC-4 (clean-passthrough path). Exhaustive — only one new line.
- **`cmd_rollback`**: code-review confirmed (lines 288–294 unchanged; delegates to `cmd_update`).
- **Full suite**: `prove t/` — 25 files, **238 tests, all PASS**, no regressions vs Task 115's 235 baseline.

## Validation Criteria — closed-loop check from e-testing-plan
- [x] `prove t/cwf-manage-check-clean-tree.t` — all three subtests pass
- [x] TC-4 clean-tree+env smoke shows preserved Task 115 logging and no dirty error
- [x] TC-5 (load-bearing) dirty-tree+env smoke shows the exact recipe and no clone attempt; exit 1
- [x] TC-6 dirty-outside-scope smoke shows no dirty error
- [x] Full `prove t/` passes — 235 → 238
- [x] `cwf-manage validate` exits 0 after `.cwf/security/script-hashes.json` re-hash
- [x] `cwf-manage help` output contains the new `Notes:` block
- [x] `cmd_rollback` delegation confirmed by code review (no runtime smoke needed)

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 116
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*
