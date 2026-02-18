# Fix terminal status handling in state_done and status aggregators - Testing Plan
**Task**: 66 (bugfix)

## Task Reference
- **Task ID**: internal-66
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/66-fix-terminal-status-handling-in-state-done-and-status-aggregators
- **Template Version**: 2.1

## Goal
Verify that closed terminal states (Finished, Cancelled, Skipped) score 100% in `state_done`, that `state_achievable` correctly handles Blocked tasks via DORMANT, and that no regressions are introduced for active tasks.

## Test Strategy

### Test Levels
- **Unit**: `status_percent`, `_is_closed`, `state_done`, `state_achievable` in isolation using temp directories with stub workflow files
- **Integration**: `status-aggregator-v2.1` and `status-aggregator-v2.0` end-to-end against task 11 and a synthetic all-Skipped task
- **Regression**: Active tasks (In Progress, mixed) score unchanged; `cwf-manage validate` exits 0

### Test Coverage Targets
- All new code paths in `state_done` and `state_achievable`: 100%
- All three closed terminal states (Finished, Cancelled, Skipped): covered
- Blocked behaviour change: explicitly verified
- No regression on active/mixed tasks: verified

## Test Cases

### Unit: `status_percent`

- **TC-1**: `status_percent('Skipped')` returns 100
  - **Given**: Default status map
  - **When**: `status_percent('Skipped')` called
  - **Then**: Returns 100

- **TC-2**: `status_percent('Cancelled')` still returns 0
  - **Given**: Default status map
  - **When**: `status_percent('Cancelled')` called
  - **Then**: Returns 0 (raw map unchanged)

### Unit: `state_done`

- **TC-3**: All-Cancelled task scores 100%
  - **Given**: Task dir with all workflow files at `**Status**: Cancelled`
  - **When**: `state_done($task_dir)` called
  - **Then**: Returns 100

- **TC-4**: All-Skipped task scores 100%
  - **Given**: Task dir with all workflow files at `**Status**: Skipped`
  - **When**: `state_done($task_dir)` called
  - **Then**: Returns 100

- **TC-5**: Mixed Finished + Cancelled + Skipped scores 100%
  - **Given**: Task dir with files split across Finished, Cancelled, Skipped
  - **When**: `state_done($task_dir)` called
  - **Then**: Returns 100

- **TC-6**: Finished + In Progress scores at In Progress level (no regression)
  - **Given**: Task dir with one Finished file and one In Progress file
  - **When**: `state_done($task_dir)` called
  - **Then**: Returns 25 (In Progress = 25, not dragged down by anything)

- **TC-7**: All-Blocked scores 15 (no regression)
  - **Given**: Task dir with all workflow files at `**Status**: Blocked`
  - **When**: `state_done($task_dir)` called
  - **Then**: Returns 15 (Blocked still bottlenecks active tasks)

### Unit: `state_achievable`

- **TC-8**: All-Cancelled task returns 0 via CLIFF
  - **Given**: Task dir with all Cancelled files (`state_done` returns 100)
  - **When**: `state_achievable($task_dir)` called
  - **Then**: Returns 0 (CLIFF: completion >= 100)

- **TC-9**: All-Blocked task returns non-zero via DORMANT
  - **Given**: Task dir with all Blocked files (`state_done` returns 15)
  - **When**: `state_achievable($task_dir)` called
  - **Then**: Returns > 0 (DORMANT: int(15 × 0.3) = 4)
  - **Note**: Previously returned 0 via the now-removed `!$is_workable` branch

- **TC-10**: Active task (In Progress) returns completion score (no regression)
  - **Given**: Task dir with mix of Finished and In Progress files
  - **When**: `state_achievable($task_dir)` called
  - **Then**: Returns completion % (ACTIVE branch)

### Integration: status-aggregator

- **TC-11**: Task 11 (all Cancelled, v2.0 format) shows 100% in status-aggregator
  - **Given**: Existing task 11 directory unchanged
  - **When**: `status-aggregator-v2.1 11` run
  - **Then**: Output shows `* 11 ... 100%`

- **TC-12**: Task 66 (active task) shows non-100% in status-aggregator
  - **Given**: Task 66 in progress
  - **When**: `status-aggregator-v2.1 66` run
  - **Then**: Output shows `+ 66 ...` (not 100%, not 0%)

- **TC-13**: `cwf-manage validate` exits 0
  - **Given**: All script hashes updated in script-hashes.json
  - **When**: `perl -I.cwf/lib .cwf/scripts/cwf-manage validate` run
  - **Then**: Exits 0, prints `[CWF] validate: OK`

### Regression: `perlcritic`

- **TC-14**: `perlcritic --stern TaskState.pm` passes
  - **Given**: Modified TaskState.pm
  - **When**: `perlcritic --stern .cwf/lib/CWF/TaskState.pm` run
  - **Then**: Exits 0, no violations

## Test Environment

- All unit tests use temporary directories with stub markdown files containing `**Status**: <value>` lines
- Integration tests use live repo (task 11 already exists with all-Cancelled files)
- Manual execution via Bash tool — no test framework required for this task

## Validation Criteria
- [ ] TC-1 through TC-14 all PASS
- [ ] Task 11 shows 100% (primary bug fixed)
- [ ] No active task scores change unexpectedly
- [ ] `cwf-manage validate` clean

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 66
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during retrospective*
