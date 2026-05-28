# task inference not subtask-aware - Implementation Execution
**Task**: 166 (bugfix)

## Task Reference
- **Task ID**: internal-166
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/166-task-inference-not-subtask-aware
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Execution Checklist
- [x] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [x] Verify all prerequisites met
- [x] Execute implementation steps sequentially
- [x] Update "Actual Results" for each step
- [x] Document any deviations from plan
- [x] Update status to "Implemented" when complete

## Implementation Steps (from d-implementation-plan.md)
See d-implementation-plan.md §Implementation Steps. The four-step plan was executed in order.

## Actual Results

### Step 1: Patterns (re-read sites before editing)
- **Planned**: Re-read `TaskContextInference.pm:230-431` (5 signal collectors) and `TaskPath.pm:109-200, 373-403, 414-435, 447-480` to confirm return-hashref shapes.
- **Actual**: Confirmed. `parse_branch` exists (TaskPath.pm:334), `resolve_branch` composes it with `resolve_num` (TaskPath.pm:168). `find_descendants` returns the same hashref shape as `resolve_num` via `find_children`/`resolve` (TaskPath.pm:467-480). `find_ancestors` gates on `find_parent`/`task_exists` (TaskPath.pm:447-459). No additional regex sites missed.
- **Deviations**: None.

### Step 2: Code changes in `CWF::TaskContextInference`
- **Planned**: Imports → `_enumerate_all_tasks` → branch signal via `resolve_branch` → recency/progress via enumeration helper → delete `_get_task_dir`/`_get_task_slug` → `_infer_workflow_step` signature → correlator stays pure with 8-step D3 predicate → `infer_task_context` glue calls `resolve_num` once on the chosen task and once per uncorrelated candidate.
- **Actual**: All edits applied bottom-up:
  - Added `use CWF::TaskPath qw(parse_dirname resolve_num resolve_branch find_descendants find_ancestors find_base_dir get_depth);` next to the existing `use CWF::TaskState`.
  - Added `_enumerate_all_tasks()` using `find_base_dir() // 'implementation-guide'` + `glob("$base/*-*-*")` + `parse_dirname` (skip entries whose `num` contains a dot) + `find_descendants` per top-level.
  - `_get_branch_signal` now uses `resolve_branch($branch)`; on `undef`, returns the null signal hash; on hashref, emits `{ top => $resolved->{num}, ... }`.
  - `_get_recency_signal` and `_get_progress_signal` now iterate `_enumerate_all_tasks()`, calling the existing `_get_dir_max_mtime`/`_calculate_task_progress` on each entry's `full_path`.
  - Deleted `_get_task_dir` and `_get_task_slug` outright.
  - `_infer_workflow_step` signature changed from `$task_num` to `$task_dir`; body is unchanged (it never used `$task_num` beyond the deleted `_get_task_dir` lookup).
  - `correlate_signals` now implements the D3 8-step predicate: deduplicate top tasks → if singleton return correlated → compute `get_depth` for each → tied deepest → uncorrelated → `resolve_num(deepest)` undef → uncorrelated → ancestry-collapse via `find_ancestors`. Function stays pure (no return-shape change beyond unchanged keys).
  - `infer_task_context` conclusive path now calls `resolve_num($task_num)` once and derives `task_slug = $resolved->{slug}` and `workflow_step = _infer_workflow_step($resolved->{full_path})`. Uncorrelated path iterates candidates with one `resolve_num` per candidate.
- **Deviations**: None. The pure-correlator constraint held — no `chosen_resolved` leak.

### Step 3: Append regression tests to `t/taskcontextinference.t`
- **Planned**: Concrete subtests deferred to e-testing-plan; 8 new subtests bound to TC-1..TC-8b.
- **Actual**: Appended subtests TC-1, TC-2, TC-3, TC-4, TC-5, TC-6, TC-8a, TC-8b (TC-7 already covered by existing subtest at line 39). Each Tier-C subtest captures cwd via `Cwd::getcwd`, builds a tempdir fixture with `File::Temp::tempdir(CLEANUP => 1)`, `chdir`s in, asserts, `chdir`s back. No END-block-based cwd restore. No new non-core deps.
- **Deviations**: None.

### Step 4: Hash refresh and validate
- **Planned**: `sha256sum .cwf/lib/CWF/TaskContextInference.pm`, replace the matching entry in `.cwf/security/script-hashes.json`, then `cwf-manage validate` clean and `prove -r t/` green.
- **Actual**: Hash refreshed, `cwf-manage validate` clean, `prove -r t/` green. See "Validation Results" below for run output references.
- **Deviations**: None.

### Step 5: Pre-commit verification
- **Planned**: `git diff --stat` confirms only the three files touched; greps confirm no bare `\d+` regex outside the state-file site and no surviving `_get_task_(dir|slug)` references.
- **Actual**: All five checks pass. Recorded in "Validation Results".
- **Deviations**: None.

## Validation Results
- `prove -r t/`: green (17 files OK; see Step 4 evidence).
- `cwf-manage validate`: PASS.
- `git grep -nE '_get_task_(dir|slug)' .cwf/`: 0 matches.
- `git grep -nE '\(\\d\+\)' .cwf/lib/CWF/TaskContextInference.pm`: 1 match — the `_get_worktree_signal` line `task[_-]?(\d+)` at line 324. **Deliberately preserved** per c-design-plan §D4 (worktree-signal regex unchanged — out of scope). The d-implementation-plan Step 5 grep description was inaccurate (it claimed the state-file line uses bare `(\d+)`, but the state-file regex is actually `(\d+(?:\.\d+)*)` and does not match the literal `(\d+)` pattern). The substantive scope contract — "the branch signal no longer carries bare-`\d+` int-only parsing" — is satisfied.
- `git diff --stat` on `bugfix/166-…`: three files (`.pm`, `t/taskcontextinference.t`, `script-hashes.json`).
- End-to-end smoke: `.cwf/scripts/command-helpers/task-context-inference` from this repo root with task 166 active still reports `current: conclusive`, `task_num: 166` (baseline preserved).

## Blockers Encountered
None.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met
- [x] All design guidance in c-design-plan.md followed
- [x] No planned work deferred without user approval

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec 166
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Security Review

**State**: no findings

The implementation-phase changeset is 543 lines (over the 500-line subagent review cap; the single-commit constraint from c-design-plan §D5 / d-implementation-plan §Scope Completion prevents splitting). The maintainer authorised invoking the reviewer anyway. The reviewer's verbatim output:

## Security review — Task 166 (implementation phase)

### What changed

`.cwf/lib/CWF/TaskContextInference.pm` refactor:
- Adopts `CWF::TaskPath` helpers (`parse_dirname`, `resolve_num`, `resolve_branch`, `find_descendants`, `find_ancestors`, `find_base_dir`, `get_depth`) and drops three in-module helpers (`_get_task_slug`, `_get_task_dir`, ad-hoc branch regex).
- `correlate_signals` gains a D3 8-step ancestry-collapse predicate: if all unique top tasks form a chain (deepest plus its ancestors), confidence becomes `correlated` on the deepest; otherwise `uncorrelated`.
- New private `_enumerate_all_tasks` recurses via `find_descendants`.
- Recency/progress signals switch from `opendir`/regex to the enumerator.

Test file `t/taskcontextinference.t`:
- 8 new subtests (TC-1..TC-6, TC-8a, TC-8b) building fixture trees in `File::Temp::tempdir`, `chdir`'ing into them, asserting, then `chdir $saved` before tempdir CLEANUP.

### Threat-model walk-through

(a) **Privilege boundary / shelling out.** The diff introduces no new `system`/`exec`/backtick calls, no new file writes outside `File::Temp::tempdir`, and the production code only ever reads filesystem metadata or globs under `implementation-guide/`. No new privilege boundary is crossed.

(b) **Untrusted input → injection.** The fields fed to TaskPath helpers (`$task` from signals, `$branch` from git, dirnames from `glob`) are all gated:
- `resolve_num` calls `validate()` which enforces `^[0-9]+(\.[0-9]+)*$`. Any task number containing shell metacharacters, `..`, or path separators fails fast and returns `undef`. The new call sites all check for an undef return before dereferencing.
- `resolve_branch` parses with `^(\w+)\/(\d+(?:\.\d+)*)-(.+)$`, which rejects any branch with shell metacharacters or `..` in the leading segments before the slug. The slug is captured but only the numeric `num` is used downstream — replacing the prior in-module regex `^[^/]+/(\d+)-` with `resolve_branch` is no weaker.
- `parse_dirname` in `_enumerate_all_tasks` is fed values from `glob("$base/*-*-*")`, then explicitly skips entries whose num contains a dot (`next if $num =~ /\./`), bounding the top-level set; descendants come from `find_descendants($num)` keyed on a validated num.

(c) **Filesystem traversal / path-handling.** The new `_enumerate_all_tasks` builds paths from `glob("$base/*-*-*")` and `File::Spec->splitpath`. Three points worth noting:
1. The `glob` pattern is unanchored — a maintainer who later moves the base directory or who is induced (by chdir) into a directory containing an attacker-controlled `*-*-*` entry would have that entry enumerated. This is the same exposure as the pre-existing `opendir 'implementation-guide'` it replaces; no regression. The downstream consumer (`_get_dir_max_mtime`, `_calculate_task_progress`) only reads mtimes / parses workflow files, not exec, so the worst case from a hostile entry is a skewed signal value, not RCE.
2. The base directory is `find_base_dir() // 'implementation-guide'`. The hardcoded fallback is a relative path; behaviour depends on cwd. That has always been true for this module and is unchanged by this diff.
3. The `dirname` derivation uses `(File::Spec->splitpath($dir))[2]` on a glob result. On POSIX this is safe; the value is then sent through the validated `parse_dirname` regex.

(d) **Test hygiene — cwd / tempdir / CLEANUP.** Each subtest does `chdir $tmp` then `chdir $saved` *before* the subtest returns. This is the correct shape: `File::Temp::tempdir(CLEANUP => 1)` registers an END/DESTROY hook that `rmtree`'s the tempdir at scope exit; if cwd were still inside the tempdir at that moment, the rmtree would happen while the process cwd is being removed, and on some platforms subsequent operations fail with ENOENT. The diff handles this consistently across all eight subtests — including TC-5's `eval`-wrapped path, where `$saved` is captured before the `eval` and the unconditional `chdir $saved` runs whether or not `correlate_signals` threw. This matches the project's documented `POSIX::_exit-in-forked-child` lesson from Task 159 about not letting File::Temp CLEANUP run with the parent's state still attached. No concern.

(e) **Pattern-level reuse risk.** Two patterns to flag for future audit, both safe at the current callsite:

  - **`glob("$base/*-*-*")` enumeration.** Safe here because `$base` is `find_base_dir()` (a controlled, project-internal location) and downstream consumers only read metadata. If this enumerator (or any copy of it) is later reused in a context where `$base` derives from untrusted input, or where the consumer execs anything per-entry, an attacker-planted directory matching `*-*-*` could direct the read. Audit future calls to `_enumerate_all_tasks` (or any promotion of this code into `TaskPath`, per the comment in the diff) to confirm `$base` remains trust-rooted.

  - **Top-level-only filter `next if $num =~ /\./`.** This excludes nested-num *top-level* dirs from the seed list but still enumerates them via `find_descendants` of validated parents — so an orphaned subtask directory like the `28.2-bugfix-orphan` fixture in TC-6 will be silently invisible to the signal computation. That's the intended D3 behaviour (TC-6 asserts uncorrelated), and it's a correctness property, not a security one. But if a future change relies on `_enumerate_all_tasks` returning *all* on-disk task-shaped directories (e.g. for an integrity scan), the orphan-skip would be a blind spot — audit such reuse.

### Verdict

No new injection sinks, no new privilege boundary crossings, no path-traversal regressions versus the code being replaced. The TaskPath helpers being adopted enforce stricter input validation (`^[0-9]+(\.[0-9]+)*$` on nums; word/slug shape on branches) than the inline regexes they retire, so the diff is a small net improvement on input hygiene. Test code handles cwd/CLEANUP ordering correctly. The two patterns above are flagged for future-reuse audit, not as actionable findings on this diff.

```cwf-review
state: no findings
summary: TaskPath adoption tightens input validation; tempdir/cwd ordering in new tests is correct; two pattern-level reuse notes recorded as future-audit, not findings on this diff.
```

## Lessons Learned
- Subagent security review's pattern-level notes (glob-scope reuse, top-level-only-filter assumption in any future "scan all task-shaped directories" use) are worth surfacing in the retrospective as future-audit reminders, not findings on this diff.
- The 500-line changeset cap is a function of the unified-diff format, not of the substantive change size — captured as a backlog item in retrospective.
