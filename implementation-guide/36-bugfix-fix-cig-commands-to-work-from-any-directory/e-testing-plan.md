# Fix CIG Commands to Work from Any Directory - Testing

## Task Reference
- **Task ID**: internal-36
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/36-fix-cig-commands-to-work-from-any-directory
- **Template Version**: 2.1

## Goal
Define test strategy and validation approach for Fix CIG Commands to Work from Any Directory.

## Test Strategy
### Test Levels
- **Manual Integration Tests**: Test commands from different directory contexts
- **Regression Tests**: Verify existing functionality still works from repo root

### Test Coverage Targets
- **Overall Coverage**: 100% of 17 command files tested
- **Critical Paths**: All 3 directory contexts tested (root, subdirectory, outside repo)
- **Edge Cases**: Error messaging when not in git repository
- **Regression**: All commands work from repo root (baseline)

## Test Cases

### Functional Test Cases

**TC-1**: Commands work from repository root (regression baseline)
  - **Given**: Current working directory is repository root `/home/matt/repo/code-implementation-guide`
  - **When**: Execute `/cig-new-task 37 feature "test task"`
  - **Then**:
    - Command succeeds
    - Working directory echoed: "Working directory: /home/matt/repo/code-implementation-guide"
    - Task created successfully

**TC-2**: Commands work from task subdirectory (primary fix)
  - **Given**: Current working directory is `implementation-guide/36-bugfix-fix-cig-commands-to-work-from-any-directory/`
  - **When**: Execute `/cig-status 36`
  - **Then**:
    - Command succeeds
    - Working directory echoed: "Working directory: /home/matt/repo/code-implementation-guide"
    - Status displayed correctly

**TC-3**: Commands work from nested subdirectory
  - **Given**: Current working directory is `.cig/scripts/command-helpers/`
  - **When**: Execute `/cig-config list`
  - **Then**:
    - Command succeeds
    - Working directory echoed correctly
    - Config displayed successfully

**TC-4**: Commands fail gracefully outside git repository
  - **Given**: Current working directory is `/tmp` (not a git repository)
  - **When**: Execute `/cig-new-task 38 feature "test"`
  - **Then**:
    - Command fails with exit code 1
    - Clear error message: "Error: Not in a git repository. CIG commands must be run from within a git repository."
    - No task created

**TC-5**: All 17 commands updated correctly
  - **Given**: All command files have been modified
  - **When**: Grep for "GIT_ROOT" in `.claude/commands/cig-*.md`
  - **Then**: Exactly 17 matches found (one per command file)

**TC-6**: Insertion point is consistent
  - **Given**: All command files have been modified
  - **When**: Review git diff for all files
  - **Then**: Git root detection snippet appears after frontmatter, before "## Your task" in all files

**TC-7**: Sample of command types tested
  - **Test 7a - Workflow command**: `/cig-task-plan 36` from subdirectory
  - **Test 7b - Utility command**: `/cig-subtask 36 36.1 chore "test"` from subdirectory
  - **Test 7c - Status command**: `/cig-status` from subdirectory
  - **Expected**: All succeed and echo working directory

### Non-Functional Test Cases

**Usability**: Clear error messages
  - Error message is clear and actionable when not in git repository
  - Working directory change is communicated to user/LLM

**Reliability**: No regressions
  - All commands that worked from root before still work from root
  - Helper script invocations unchanged (relative paths still valid after cd)

## Test Environment

### Setup Requirements
- Working directory: `/home/matt/repo/code-implementation-guide` (or any git repository)
- Git must be available in PATH
- Branch: `bugfix/36-fix-cig-commands-to-work-from-any-directory`

### Directory Contexts for Testing
1. **Repository root**: `/home/matt/repo/code-implementation-guide`
2. **Task subdirectory**: `implementation-guide/36-bugfix-fix-cig-commands-to-work-from-any-directory/`
3. **Helper scripts directory**: `.cig/scripts/command-helpers/`
4. **Outside repository**: `/tmp` (negative test)

### Automation
- Manual execution via bash commands
- No CI/CD integration required for this bugfix
- Validation through command execution in different directories

## Validation Criteria
- [ ] TC-1: Commands work from repository root (baseline regression)
- [ ] TC-2: Commands work from task subdirectory (primary success criterion)
- [ ] TC-3: Commands work from nested subdirectory
- [ ] TC-4: Commands fail gracefully outside git repository
- [ ] TC-5: All 17 command files updated (grep verification)
- [ ] TC-6: Insertion point consistent across all files
- [ ] TC-7: Sample of different command types tested successfully

## Status
**Status**: Finished
**Next Action**: Move to implementation execution → `/cig-implementation-exec 36`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
