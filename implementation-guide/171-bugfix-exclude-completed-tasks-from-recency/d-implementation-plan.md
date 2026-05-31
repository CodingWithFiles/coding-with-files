# exclude-completed-tasks-from-recency - Implementation Plan
**Task**: 171 (bugfix)

## Task Reference
- **Task ID**: internal-171
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/171-exclude-completed-tasks-from-recency
- **Template Version**: 2.1

## Goal
Implement exclude-completed-tasks-from-recency following the approved design and requirements.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `.cwf/lib/CWF/TaskContextInference.pm` — **one edit**: add a completed-task
  skip in the `_get_recency_signal` mtime-collection loop (`:393-396`), calling
  `CWF::TaskState::state_done` **fully-qualified**.
  - The import line (`:11`) is **not** touched. The module already calls its
    `TaskState` import fully-qualified at `:519`
    (`CWF::TaskState::state_achievable(...)`); the `qw(state_achievable)` import is
    unused as a bareword. Matching that precedent (fully-qualified call, no import
    edit) keeps the diff to one line and avoids adding a second unused import.

### Supporting Changes
- `.cwf/security/script-hashes.json` — refresh the `sha256` for
  `CWF::TaskContextInference` in the **same commit** (hash-updates convention).
  `.pm` module → no `permissions` key, so only the digest changes.
- `t/taskcontextinference.t` — add a regression subtest (full spec authored in
  the next phase, e-testing-plan.md). **Critical fixture requirement**: the
  completed task in the fixture must contain real `**Status**: Finished` phase
  files so `state_done == 100`. Every existing fixture writes bare `"x"` files
  (`state_done == 0`), so a copy-paste fixture would pass *even without the fix* —
  the test must write genuine status markers to actually reproduce the leak.
  `.t` files are not hash-tracked.

`CWF::TaskState.pm` is **not** modified (only consulted), so its hash entry is untouched.

## Implementation Steps
### Step 1: Setup
- [ ] Confirm on branch `bugfix/171-...`; re-read c-design-plan.md Decisions 1–3.
- [ ] `git log --oneline <last-hash-set-commit>..HEAD -- .cwf/lib/CWF/TaskContextInference.pm` to confirm no unrecorded drift before refreshing (pre-refresh verification).

### Step 2: Core Implementation
- [ ] Add the guard line in `_get_recency_signal`'s loop with an explanatory comment (see Code Changes), calling `CWF::TaskState::state_done` fully-qualified. Do **not** edit the import line.
- [ ] No other signal, helper, or the D3 correlation logic touched.

### Step 3: Testing
- [ ] Add regression subtest (e-testing-plan.md) reproducing the recently-touched-completed-task leak.
- [ ] Run `prove -v t/taskcontextinference.t` — new test passes, TC-1..TC-8b green.
- [ ] Run the full suite (`prove -r t/`) to confirm no regressions.

### Step 4: Documentation
- [ ] Inline comment on the guard is the only doc change. No user-facing/API docs (internal helper, no interface change).

### Step 5: Validation
- [ ] `sha256sum .cwf/lib/CWF/TaskContextInference.pm` → update manifest entry.
- [ ] `.cwf/scripts/cwf-manage validate` → clean.

## Code Changes
Import line (`:11`) unchanged. Only the `_get_recency_signal` loop changes.

### Before (`.cwf/lib/CWF/TaskContextInference.pm`)
```perl
    my %task_mtimes;
    for my $task (@tasks) {
        my $max_mtime = _get_dir_max_mtime($task->{full_path});
        $task_mtimes{$task->{num}} = $max_mtime if $max_mtime;
    }
```

### After
```perl
    my %task_mtimes;
    for my $task (@tasks) {
        # Completed tasks have no live work, but their dirs keep getting touched
        # by merges, commits and hash refreshes — which would let a finished task
        # win recency and disagree with branch/progress (false uncorrelated).
        # Gate via the same CWF::TaskState framework progress relies on. (Task 171)
        next if CWF::TaskState::state_done($task->{full_path}) >= 100;
        my $max_mtime = _get_dir_max_mtime($task->{full_path});
        $task_mtimes{$task->{num}} = $max_mtime if $max_mtime;
    }
```

The `>= 100` (not `== 100`) and fail-open-on-parse-error properties are inherited
from `state_done` per c-design-plan.md; no extra handling needed here.

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Executed exactly as planned in commit `eb139c5`: single guard line in
`_get_recency_signal`, no import edit, same-commit `script-hashes.json` digest
refresh, `cwf-manage validate: OK`.

## Lessons Learned
The plan's "load-bearing fixture" warning (bare `"x"` files yield `state_done == 0`
and would pass without the fix) was correct and became the `_write_status` helper
in g-testing-exec.
