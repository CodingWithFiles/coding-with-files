# fix nextAction template substitution in template-copier - Testing Plan
**Task**: 48 (bugfix)

## Task Reference
- **Task ID**: internal-48
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/48-fix-nextaction-template-substitution-in-template-copier
- **Template Version**: 2.1

## Goal
Validate that `compute_next_action()` correctly derives command names from template filenames for all 5 task types and handles all edge cases, with zero regression in existing template functionality.

## Test Strategy
### Test Levels
- **Integration Tests**: Primary focus - test `task-workflow create` end-to-end for all 5 task types
- **Regression Tests**: Verify existing template copying functionality unchanged
- **Edge Case Tests**: Last phase, invalid inputs, missing templates

### Test Coverage Targets
- **Critical Paths**: 100% - All 5 task types (bugfix, feature, hotfix, chore, discovery) must generate correct nextAction
- **Edge Cases**: 100% - Last phase, invalid phase, missing template file
- **Regression**: 100% - All template variables must still substitute correctly, permissions must remain 0600

## Test Cases

### Must-Pass Tests (7/7 required for task completion)

#### TC-1: Bugfix Task - g-testing-exec.md nextAction
- **Given**: Created bugfix task (sequence: a→c→d→e→f→g→j)
- **When**: Read g-testing-exec.md file
- **Then**: "Next Action" field shows "/cig-retrospective" (NOT "/cig-rollout")
- **Priority**: CRITICAL - This is the original bug we're fixing

#### TC-2: Feature Task - All phases have correct nextAction
- **Given**: Created feature task (sequence: a→b→c→d→e→f→g→h→i→j)
- **When**: Read all 10 workflow files
- **Then**: Each file's nextAction matches next file in sequence
  - a-task-plan.md → /cig-requirements-plan
  - b-requirements-plan.md → /cig-design-plan
  - c-design-plan.md → /cig-implementation-plan
  - d-implementation-plan.md → /cig-testing-plan
  - e-testing-plan.md → /cig-implementation-exec
  - f-implementation-exec.md → /cig-testing-exec
  - g-testing-exec.md → /cig-rollout
  - h-rollout.md → /cig-maintenance
  - i-maintenance.md → /cig-retrospective
  - j-retrospective.md → "Task complete"

#### TC-3: Hotfix Task - Correct sequence
- **Given**: Created hotfix task (sequence: a→d→f→h→j)
- **When**: Read all 5 workflow files
- **Then**: Each file's nextAction matches hotfix sequence
  - a-task-plan.md → /cig-implementation-plan
  - d-implementation-plan.md → /cig-implementation-exec
  - f-implementation-exec.md → /cig-rollout
  - h-rollout.md → /cig-retrospective
  - j-retrospective.md → "Task complete"

#### TC-4: Chore Task - Correct sequence
- **Given**: Created chore task (sequence: a→d→e→j)
- **When**: Read all 4 workflow files
- **Then**: Each file's nextAction matches chore sequence
  - a-task-plan.md → /cig-implementation-plan
  - d-implementation-plan.md → /cig-testing-plan
  - e-testing-plan.md → /cig-retrospective
  - j-retrospective.md → "Task complete"

#### TC-5: Discovery Task - Correct sequence
- **Given**: Created discovery task (sequence: a→b→c→d→e→j)
- **When**: Read all 6 workflow files
- **Then**: Each file's nextAction matches discovery sequence
  - a-task-plan.md → /cig-requirements-plan
  - b-requirements-plan.md → /cig-design-plan
  - c-design-plan.md → /cig-implementation-plan
  - d-implementation-plan.md → /cig-testing-plan
  - e-testing-plan.md → /cig-retrospective
  - j-retrospective.md → "Task complete"

#### TC-6: Regression - All template variables substitute correctly
- **Given**: Created test bugfix task
- **When**: Read a-task-plan.md
- **Then**: Verify all variables substituted:
  - `{{description}}` → actual description
  - `{{taskId}}` → "internal-99"
  - `{{taskUrl}}` → "N/A (internal task)"
  - `{{branchName}}` → "bugfix/99-test-description"
  - `{{parentTask}}` → "N/A"

#### TC-7: Regression - File permissions remain 0600
- **Given**: Created test bugfix task
- **When**: Check file permissions with `stat -c %a`
- **Then**: All 7 workflow files have 0600 permissions

### Optional Tests (Nice-to-have)

#### TC-8: Edge Case - Last phase returns "Task complete"
- **Given**: j-retrospective.md is last phase in sequence
- **When**: Read j-retrospective.md nextAction field
- **Then**: Shows "Task complete" (no next command)

#### TC-9: Cleanup - Test directories removed
- **Given**: Created 5 test tasks in /tmp/
- **When**: Tests complete
- **Then**: All test directories deleted successfully

### Non-Functional Test Cases
- **Performance**: Task creation time unchanged (< 1 second per task)
- **Maintainability**: Code simpler (14 lines shorter, zero hardcoded mapping)
- **Reliability**: Clear error messages if template filename doesn't match pattern

## Test Environment
### Setup Requirements
- **Test directory**: `/tmp/cig-test-48/` for creating temporary test tasks
- **Prerequisites**:
  - Task 47 merged to main (provides clean baseline)
  - `.cig/templates/{type}/` symlinks intact
  - `template-copier-v2.1` script modified with fix
- **Test data**: Create 5 test tasks (one per task type: bugfix, feature, hotfix, chore, discovery)

### Test Execution
- **Manual testing**: Create tasks using `task-workflow create`, manually verify nextAction fields
- **No automation needed**: Simple integration test, manual verification sufficient
- **Validation approach**: Read workflow files with grep/Read tool, compare actual vs expected nextAction

## Validation Criteria

**100% of must-pass criteria** (7/7 tests) required for task completion

### Must-Pass Criteria
- [ ] TC-1: Bugfix g-testing-exec.md shows "/cig-retrospective" (NOT "/cig-rollout")
- [ ] TC-2: Feature task (10 files) all have correct nextAction
- [ ] TC-3: Hotfix task (5 files) all have correct nextAction
- [ ] TC-4: Chore task (4 files) all have correct nextAction
- [ ] TC-5: Discovery task (6 files) all have correct nextAction
- [ ] TC-6: All template variables still substitute correctly (no regression)
- [ ] TC-7: File permissions remain 0600 (no regression)

### Optional Criteria
- [ ] TC-8: Last phase (j-retrospective.md) shows "Task complete"
- [ ] TC-9: Test directories cleaned up

### Success Threshold
- **Minimum**: 7/7 must-pass tests (100%)
- **Target**: 9/9 total tests (100% including optional tests)

## Status
**Status**: In Progress
**Next Action**: /cig-implementation-exec 48 (bugfix workflow: testing-plan → implementation-exec → testing-exec)
**Blockers**: Task 47 must be merged before implementation execution

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
