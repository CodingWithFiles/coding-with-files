# task inference not subtask-aware - Testing Plan
**Task**: 166 (bugfix)

## Task Reference
- **Task ID**: internal-166
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/166-task-inference-not-subtask-aware
- **Template Version**: 2.1

## Goal
Bind every c-design-plan §Validation bullet to a concrete test case, identify which existing subtest already covers each baseline behaviour, and define the fixture discipline so f-implementation-exec can mechanically execute.

## Test Strategy

### Test Levels
- **Tier A (pure-function)**: existing `correlate_signals` and `format_output` subtests in `t/taskcontextinference.t` — no filesystem, exercise the legacy single-unique-top path. **No new Tier A tests in this task** — every new D3 case requires `find_ancestors`, which is filesystem-driven (see Robustness review F1/2/6 for the resolved contradiction).
- **Tier C (filesystem-driven)**: new subtests build a tempdir fixture with the right `implementation-guide/<n>-…/<n>.<m>-…/` shape, `chdir` in, exercise `correlate_signals` (or `infer_task_context` for the integration cases), `chdir` back. Tempdir cleaned by `File::Temp::tempdir(CLEANUP => 1)`.

### Test Coverage Targets
- **Every c-design-plan §Validation test-level bullet → at least one new or existing subtest** (mapping below in §Test Cases).
- **All existing subtests in `t/taskcontextinference.t` remain green** — Tier A coverage is the regression floor.
- **Full `prove -r t/` green** — sibling tests unaffected.
- **No subtest skips, no `xfail`, no `TODO` markers** — the work either lands fully or doesn't land.

## Test Cases

### Mapping: c-design-plan §Validation → concrete subtests

Each row binds a validation bullet to (a) an existing subtest if any already covers the baseline, or (b) a new subtest with its Given/When/Then.

| # | Validation bullet | Subtest |
|---|-------------------|---------|
| 1 | Single-chain conclusive `{28, 28.2}` → `28.2` | **NEW**: `correlate_signals — single-chain collapses to deepest` |
| 2 | Multi-level chain `{28, 28.2, 28.2.1}` → `28.2.1` | **NEW**: `correlate_signals — multi-level chain collapses to deepest` |
| 3 | Tied deepest disjoint `{28.2, 28.3}` → uncorrelated | **NEW**: `correlate_signals — tied deepest on disjoint branches stays uncorrelated` |
| 4 | Disjoint chains `{28.2, 20}` → uncorrelated | **NEW**: `correlate_signals — fully disjoint chains stay uncorrelated` |
| 5 | Stale deepest (resolve_num undef) → uncorrelated, no exception | **NEW**: `correlate_signals — stale deepest falls back to uncorrelated` |
| 6 | Orphaned subtask (parent dir missing) → uncorrelated | **NEW**: `correlate_signals — orphaned subtask without parent dir stays uncorrelated` |
| 7 | Top-level-only baseline (existing repo) | **EXISTING**: `correlate_signals — all signals agree → correlated` (line 39 of `t/taskcontextinference.t`) + Tier-C smoke that exec-time `task-context-inference` from this repo's main still resolves `task_num: <current-top-level>` conclusively (covered by the end-to-end run in g-testing-exec, not a new unit test). |
| 8 | Descendants enumerated (recency/progress include subtasks) | **NEW**: `_enumerate_all_tasks — subtask dirs appear in candidate list` (exercises the helper directly) + `get_all_signals — recency includes subtask candidates` (exercises through-signal). |

### Functional Test Cases (new subtests, Given/When/Then)

**TC-1: single-chain collapse**
- **Given**: Tempdir fixture with `implementation-guide/28-feature-parent/` and `implementation-guide/28-feature-parent/28.2-bugfix-child/` (each contains a placeholder `*.md` file so `resolve_num` parses dirnames cleanly). `chdir` into the tempdir.
- **When**: `correlate_signals([{name=>'branch', null=>0, top=>'28', candidates=>[{task=>'28',score=>100}]}, {name=>'recency', null=>0, top=>'28.2', candidates=>[{task=>'28.2',score=>80}]}])`.
- **Then**: `confidence eq 'correlated'`, `chosen_task eq '28.2'`.

**TC-2: multi-level chain collapse**
- **Given**: Fixture with `28-feature-p/`, `28-feature-p/28.2-bugfix-c/`, `28-feature-p/28.2-bugfix-c/28.2.1-chore-gc/`.
- **When**: `correlate_signals` with three signals topping `28`, `28.2`, `28.2.1`.
- **Then**: `chosen_task eq '28.2.1'`.

**TC-3: tied deepest disjoint**
- **Given**: Fixture with `28-feature-p/`, `28-feature-p/28.2-bugfix-a/`, `28-feature-p/28.3-bugfix-b/`.
- **When**: `correlate_signals` with two signals topping `28.2` and `28.3` (equal depth, neither ancestor of the other).
- **Then**: `confidence eq 'uncorrelated'`.

**TC-4: disjoint chains**
- **Given**: Fixture with `20-feature-a/` and `28-feature-b/28.2-bugfix-c/`.
- **When**: `correlate_signals` with two signals topping `28.2` and `20`.
- **Then**: `confidence eq 'uncorrelated'`.

**TC-5: stale deepest**
- **Given**: Fixture with `28-feature-p/` only (no `28.2` dir).
- **When**: `correlate_signals` with signals topping `28` and `28.2` (the latter referencing a directory that does not exist).
- **Then**: `confidence eq 'uncorrelated'`, no exception thrown. (`resolve_num('28.2')` returns undef → D3 step 5 short-circuits to uncorrelated.)

**TC-6: orphaned subtask**
- **Given**: Fixture with **only** `implementation-guide/28-feature-p/28.2-bugfix-c/` (no `28-feature-p/` *contents* visible to `resolve_num` because the parent's `*.md` is absent — but the directory itself exists so `find_ancestors` will still see the parent dir). To exercise the orphaned-subtask edge case proper: create `implementation-guide/28.2-bugfix-orphan/` as a top-level dir whose num implies a parent that does not exist anywhere.
- **When**: `correlate_signals` with signals topping `28` and `28.2` where `28` has no on-disk directory.
- **Then**: `confidence eq 'uncorrelated'` (D3 step 7 fails: `28` not in `find_ancestors(28.2)` since the ancestor's directory is missing).

**TC-7: top-level baseline regression** — covered by existing subtest `correlate_signals — all signals agree → correlated` (line 39 of current `t/taskcontextinference.t`). No new code needed. End-to-end repo-level smoke is covered in g-testing-exec.

**TC-8a: `_enumerate_all_tasks` includes descendants**
- **Given**: Fixture with `28-feature-p/`, `28-feature-p/28.2-bugfix-c/`, `30-chore-x/`.
- **When**: Call `_enumerate_all_tasks()`.
- **Then**: Returned list contains entries with `num` ∈ {`28`, `28.2`, `30`} (set comparison; order not asserted).

**TC-8b: `get_all_signals` recency surfaces subtask**
- **Given**: Same fixture as TC-8a, with `28-feature-p/28.2-bugfix-c/x.md` touched to be the most-recently-modified file across all task dirs.
- **When**: Call `get_all_signals()`, find the `recency` signal.
- **Then**: `$recency->{top} eq '28.2'`.

### Non-Functional Test Cases

- **Performance**: Not benchmarked. Per c-design-plan §D2 trade-offs the cost increase is bounded by descendant count × depth and is acceptable per the priority order (correctness > maintainability > performance). If a future measurement shows it dominates, the optimisation is a separate task.
- **Security**: Inherits from c-design-plan §Verified Assumption 5 (hash refresh in same commit, working perms unchanged). The security-review subagent on this design pass returned "no actionable findings". Re-verified post-implementation by `cwf-manage validate` in d-implementation-plan Step 4.
- **Usability**: Output schema unchanged (c-design-plan §Interface Design). No new error paths exposed to the user. The existing "Cannot determine task" error from the workflow preamble continues to surface uncorrelated cases.
- **Reliability**: D3 edge cases (TC-5, TC-6) verify graceful degradation: a malformed or stale signal does not throw — it falls back to uncorrelated.

## Test Environment

### Setup Requirements
- Perl ≥ 5.16 (matches existing `t/` suite floor; no new version requirement).
- Core modules only: `Test::More`, `File::Temp`, `Cwd`, `FindBin`, `File::Basename`, `File::Spec`. All already imported by the existing test file or universally available. **No CPAN deps** ([[feedback-perl-core-only]]).
- POSIX filesystem with `mkdir`/`glob`/`stat` semantics. macOS and Linux verified parity throughout the existing suite.

### Test Isolation Discipline
Per d-implementation-plan Step 3, every Tier-C subtest:
1. Builds its fixture via `File::Temp::tempdir(CLEANUP => 1)`.
2. Captures cwd: `my $saved = Cwd::getcwd();`.
3. `chdir $tmpdir` to make `find_base_dir`'s relative fallback resolve to the fixture.
4. Runs the assertion.
5. **`chdir $saved` before `done_testing()`** — restores cwd so `CLEANUP` doesn't fire `rmtree` warnings on some platforms.

No END-block-based cwd restore. No globals. No state leakage between subtests.

### Automation
- Test framework: `Test::More` via `prove`.
- Execution: `prove -v t/taskcontextinference.t` (focused) and `prove -r t/` (full sweep) — both must be green before f-implementation-exec is marked complete.
- No CI changes required (existing `prove -r t/` invocation suffices).

## Validation Criteria
- [ ] Every row in §Mapping has a passing subtest (existing or new).
- [ ] `prove -v t/taskcontextinference.t` green.
- [ ] `prove -r t/` green (no sibling-test regressions).
- [ ] `cwf-manage validate` green (hash refresh applied per d-implementation-plan Step 4).
- [ ] End-to-end repo smoke: `.cwf/scripts/command-helpers/task-context-inference` invoked at the repo root with task 166 active returns `current: conclusive`, `task_num: 166` (preserves the baseline observed at plan time). Recorded in g-testing-exec.

## Decomposition Check
- [x] Time: bounded by 8 new subtests, well under 1 day → no.
- [x] People: solo → no.
- [x] Complexity: a single test file → no.
- [x] Risk: tests *are* the risk-mitigation — they don't have separable risk of their own → no.
- [x] Independence: tests land with the implementation in one commit (per d-implementation-plan §Scope Completion) → no.
→ No subtasks.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 166
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 8 mapped subtests (TC-1..TC-6, TC-8a, TC-8b) implemented as specified and pass on first run; TC-7 covered by the existing baseline subtest plus end-to-end smoke on the live repo. Tempdir + cwd-restore discipline followed in every Tier-C subtest, including TC-5's `eval`-wrapped path (cwd captured before the `eval`, restored unconditionally).

## Lessons Learned
- Binding §Mapping rows to TC-IDs in e-testing-plan turned the f-exec test-writing into a transliteration step: each TC had a Given/When/Then to copy. No improvisation, no missing coverage.
- `File::Temp::tempdir(CLEANUP => 1)` works as documented when cwd is restored before scope exit. The discipline isn't optional — it's load-bearing for cross-platform reliability.
