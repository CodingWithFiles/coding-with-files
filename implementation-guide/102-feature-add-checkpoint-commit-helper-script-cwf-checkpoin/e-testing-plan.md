# Add Checkpoint Commit Helper Script (cwf-checkpoint-commit) - Testing Plan
**Task**: 102 (feature)

## Task Reference
- **Task ID**: internal-102
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/102-add-checkpoint-commit-helper-script-cwf-checkpoin
- **Template Version**: 2.1

## Goal
Define test cases for the `cwf-checkpoint-commit` script.

## Test Strategy
Manual CLI tests on this branch. Use the script for an actual checkpoint commit during this task's own workflow as the primary integration test.

## Test Cases

### Functional

- **TC-F1**: Happy path — valid checkpoint commit (use special chars in why-message to also cover shell safety)
  - **When**: `cwf-checkpoint-commit 102 d 'Plan implementation — test $HOME and "quotes"'`
  - **Then**: Status set to Finished, file staged and committed, commit message matches format, special chars appear literally

- **TC-F2**: Phase name derivation
  - **Then**: `a-task-plan.md` → "task plan", `f-implementation-exec.md` → "implementation exec", `j-retrospective.md` → "retrospective"

### Error Paths

- **TC-E1**: Wrong argument count → exit 1 with usage message
- **TC-E2**: Invalid task-path (`"foo"`) → exit 1
- **TC-E3**: Invalid phase-letter (`z`) → exit 1
- **TC-E4**: Non-existent task (`9999`) → exit 1, task not found
- **TC-E5**: Phase letter with no wf file (chore task, letter `b`) → exit 1, no wf file

### Security

- **TC-S1**: `cwf-manage validate` shows no violations for the new script

### Integration

- **TC-I1**: `checkpoint-commit.md` documents the script as primary method

## Test Environment
- Run on `feature/102-*` branch against real task directories, no mocks
- TC-F1 tested live during this task's own workflow

## Validation Criteria
- [ ] TC-F1, TC-F2 pass
- [ ] TC-E1 through TC-E5 pass
- [ ] TC-S1 passes
- [ ] TC-I1 confirmed

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
