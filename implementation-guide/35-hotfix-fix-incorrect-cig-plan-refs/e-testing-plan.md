# fix-incorrect-cig-plan-refs - Testing

## Task Reference
- **Task ID**: internal-35
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/35-fix-incorrect-cig-plan-refs
- **Template Version**: 2.1

## Goal
Define test strategy and validation approach for fix-incorrect-cig-plan-refs.

## Test Strategy
### Test Levels
- **Manual Verification**: This hotfix requires manual verification only (no automated tests needed)
- **Regression**: Verify no unintended changes to historical references

### Test Coverage Targets
- **File Changes**: Exactly 2 files modified (cig-new-task.md, cig-subtask.md)
- **Line Changes**: Exactly 2 lines modified (one per file)
- **Historical Preservation**: All 35 historical references in implementation-guide/ unchanged

## Test Cases
### Functional Test Cases

**TC-1**: Verify cig-new-task.md reference updated
  - **Given**: `.claude/commands/cig-new-task.md` exists with `/cig-plan` reference at line 98
  - **When**: Edit is applied to line 98
  - **Then**: Line 98 contains `/cig-task-plan <num>` instead of `/cig-plan <num>`

**TC-2**: Verify cig-subtask.md reference updated
  - **Given**: `.claude/commands/cig-subtask.md` exists with `/cig-plan` reference at line 74
  - **When**: Edit is applied to line 74
  - **Then**: Line 74 contains `/cig-task-plan <num>` instead of `/cig-plan <num>`

**TC-3**: Verify no references remain in command files
  - **Given**: Both command files have been updated
  - **When**: Grep for `/cig-plan` in `.claude/commands/` directory
  - **Then**: Zero matches found

**TC-4**: Verify historical references preserved
  - **Given**: Implementation guide files contain historical `/cig-plan` references
  - **When**: Grep for `/cig-plan` in `implementation-guide/` directory
  - **Then**: Exactly 35 matches found (unchanged from baseline)

**TC-5**: Verify git diff scope
  - **Given**: Changes have been made to command files
  - **When**: Run `git diff --stat`
  - **Then**: Shows exactly 2 files changed, 2 insertions, 2 deletions

### Non-Functional Test Cases
- **Readability**: Updated lines maintain markdown formatting and sentence structure
- **Consistency**: Both files use identical updated command format

## Test Environment
### Setup Requirements
- Working directory: `/home/matt/repo/code-implementation-guide`
- Git branch: `hotfix/35-fix-incorrect-cig-plan-refs`
- Baseline count established: 35 historical references in implementation-guide/

### Automation
- Manual execution via grep and git commands
- No CI/CD integration required for this hotfix
- Validation through bash commands in testing execution phase

## Validation Criteria
- [ ] TC-1: cig-new-task.md line 98 updated to `/cig-task-plan`
- [ ] TC-2: cig-subtask.md line 74 updated to `/cig-task-plan`
- [ ] TC-3: Zero `/cig-plan` matches in `.claude/commands/` directory
- [ ] TC-4: Exactly 35 `/cig-plan` matches remain in `implementation-guide/`
- [ ] TC-5: Git diff shows exactly 2 files, 2 lines changed

## Status
**Status**: Finished
**Next Action**: Move to implementation execution → `/cig-implementation-exec 35`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
