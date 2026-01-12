# verify task git branch at each workflow step - Testing

## Task Reference
- **Task ID**: internal-13
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/13-verify-task-git-branch-at-each-workflow-step
- **Template Version**: 2.0

## Goal
Validate git branch verification functionality across all 8 CIG workflow commands through comprehensive manual testing covering correct operation, error conditions, edge cases, and backward compatibility.

## Test Strategy

### Test Levels
- **Unit Tests (Manual)**: Verify branch verification logic in isolation across different scenarios
- **Integration Tests (Manual)**: Validate branch verification integrates correctly with existing workflow steps
- **System Tests (Manual)**: Test end-to-end workflow execution with branch verification active
- **Acceptance Tests (Manual)**: Confirm branch verification meets success criteria from planning phase

### Test Coverage Targets
- **Overall Coverage**: 100% of branch verification scenarios
- **Critical Paths**: Branch mismatch detection and warning display (100%)
- **Edge Cases**: Non-git repos, detached HEAD, missing Branch field, empty values (100%)
- **Regression**: All 8 workflow commands continue functioning normally (100%)
- **Performance**: Branch verification overhead measured for all commands (<100ms target)

### Testing Approach
- **Manual execution**: All tests executed manually by invoking workflow commands
- **Test environment**: Real CIG repository with task 13 and existing tasks
- **Test data**: Task 13 (this task) + existing tasks (1-12) for regression
- **Validation method**: Visual inspection of command output and warning messages

## Test Cases

### Phase 1: Unit Tests - Branch Verification Logic

#### TC-1: Correct Branch - Silent Success
- **Given**: User is on branch `bugfix/13-verify-task-git-branch-at-each-workflow-step`
- **When**: Execute `/cig-plan 13`
- **Then**:
  - No warning message displayed
  - Workflow proceeds to Step 2 (Load Parent Context)
  - No performance degradation observed

#### TC-2: Wrong Branch - Warning Displayed
- **Given**: User is on branch `main` (not the correct branch)
- **When**: Execute `/cig-plan 13`
- **Then**:
  - Warning message displayed with format:
    ```
    ⚠️  Branch Mismatch Warning
    Expected: bugfix/13-verify-task-git-branch-at-each-workflow-step
    Current:  main

    Suggested: git checkout bugfix/13-verify-task-git-branch-at-each-workflow-step

    Continuing with workflow on current branch...
    ```
  - Workflow continues to Step 2 (non-blocking)
  - Warning is clear and actionable

#### TC-3: Non-Git Directory - Graceful Degradation
- **Given**: Execute workflow command in directory that is not a git repository
- **When**: Execute workflow command (simulated by temporarily moving .git)
- **Then**:
  - No warning message displayed (git command fails gracefully)
  - No error messages from git commands
  - Workflow proceeds normally
  - Performance not impacted

#### TC-4: Detached HEAD - Appropriate Warning
- **Given**: User is in detached HEAD state (e.g., `git checkout HEAD~1`)
- **When**: Execute `/cig-plan 13`
- **Then**:
  - Warning message displayed showing:
    ```
    Expected: bugfix/13-verify-task-git-branch-at-each-workflow-step
    Current:  HEAD
    ```
  - Workflow continues (non-blocking)
  - Suggested checkout command displayed

#### TC-5: Missing Branch Field - Graceful Degradation
- **Given**: Task's a-plan.md does not have Branch field in Task Reference
- **When**: Execute workflow command on task with missing Branch field
- **Then**:
  - No warning displayed (graceful skip)
  - No error messages
  - Workflow proceeds normally
  - Backward compatibility maintained

### Phase 2: Integration Tests - Workflow Command Consistency

#### TC-6: All 8 Commands Show Consistent Warnings
- **Given**: User is on `main` branch (wrong branch for task 13)
- **When**: Execute each of the 8 workflow commands:
  - `/cig-plan 13`
  - `/cig-requirements 13`
  - `/cig-design 13`
  - `/cig-implementation 13`
  - `/cig-testing 13`
  - `/cig-rollout 13`
  - `/cig-maintenance 13`
  - `/cig-retrospective 13`
- **Then**:
  - All 8 commands show identical warning format
  - All warnings display correct expected branch
  - All warnings display correct current branch
  - All workflows continue after warning (non-blocking)

#### TC-7: Warning Non-Blocking Behavior
- **Given**: User is on wrong branch (`main` instead of task branch)
- **When**: Execute complete workflow sequence: plan → design → implementation
- **Then**:
  - Each command shows warning
  - Each command proceeds with workflow execution
  - User can complete full workflow despite warnings
  - No workflow functionality is blocked

#### TC-8: Correct Branch - No Warnings Across Workflow
- **Given**: User is on correct branch `bugfix/13-verify-task-git-branch-at-each-workflow-step`
- **When**: Execute complete workflow sequence: plan → design → implementation → testing
- **Then**:
  - No warnings displayed at any step
  - All workflow steps execute cleanly
  - User experience is uninterrupted

#### TC-9: Branch Switch Mid-Workflow
- **Given**: User starts on `main` (sees warning), then switches to correct branch
- **When**:
  1. Execute `/cig-plan 13` on main (sees warning)
  2. Execute `git checkout bugfix/13-verify-task-git-branch-at-each-workflow-step`
  3. Execute `/cig-design 13` on correct branch
- **Then**:
  - First command shows warning
  - Second command (after switch) shows no warning
  - Branch verification detects the change correctly

### Phase 3: Regression Tests - Existing Functionality

#### TC-10: Existing Workflow Functionality Unchanged
- **Given**: Branch verification implemented in all 8 commands
- **When**: Execute each workflow command's primary functionality
- **Then**:
  - All workflow steps execute as before
  - Step 2 (Load Parent Context) works correctly
  - Step 6 (Execute Workflow) works correctly
  - No functional regressions introduced

#### TC-11: Step 2+ Execute Correctly After Step 1.5
- **Given**: Branch verification (Step 1.5) is inserted between Step 1 and Step 2
- **When**: Execute workflow command and observe step execution order
- **Then**:
  - Step 1: Resolve Task Directory (executes first)
  - Step 1.5: Verify Git Branch (executes second)
  - Step 2: Load Parent Context (executes third)
  - All subsequent steps execute in correct order

#### TC-12: Backward Compatibility with Old Tasks
- **Given**: Existing tasks (1-12) created before branch verification feature
- **When**: Execute workflow commands on tasks 1-12
- **Then**:
  - Commands work normally (no errors)
  - If Branch field missing, no warnings (graceful degradation)
  - If Branch field present, verification works
  - No breaking changes to existing tasks

### Phase 4: Non-Functional Tests

#### TC-13: Performance Overhead Measurement
- **Given**: Branch verification adds Step 1.5 to workflow
- **When**: Execute workflow command and measure total execution time
- **Then**:
  - Step 1.5 overhead is <100ms
  - Total workflow execution time acceptable
  - No noticeable performance impact to user
  - Git commands execute quickly

#### TC-14: Security - No Command Injection
- **Given**: Branch names are read from a-plan.md files
- **When**: Branch name contains special characters (e.g., `bugfix/test-$(whoami)`)
- **Then**:
  - No command injection occurs
  - Branch name treated as literal string
  - Comparison works correctly
  - No security vulnerabilities introduced

#### TC-15: Usability - Clear Error Messages
- **Given**: User encounters branch mismatch warning
- **When**: User reads the warning message
- **Then**:
  - Warning clearly identifies the problem
  - Expected branch is clearly shown
  - Current branch is clearly shown
  - Suggested action (checkout command) is provided
  - User understands what to do next

## Test Environment

### Setup Requirements
- **Repository**: CIG repository with task 13 created and configured
- **Git setup**: Working git repository with multiple branches (main, task branches)
- **Test branches**:
  - `main` - for testing wrong branch scenarios
  - `bugfix/13-verify-task-git-branch-at-each-workflow-step` - for testing correct branch
  - Detached HEAD state - for testing edge cases
- **Test tasks**:
  - Task 13 (this task) - primary test subject
  - Tasks 1-12 - for regression testing
- **Required commands**: All 8 workflow commands installed in `.claude/commands/`

### Test Data
- **Task 13 files**:
  - `a-plan.md` with Branch field populated
  - `c-design.md` for testing design workflow
  - `d-implementation.md` for testing implementation workflow
  - `e-testing.md` (this file) for testing testing workflow
- **Existing task files**: Tasks 1-12 for backward compatibility testing

### Automation
- **Test approach**: Manual testing (no automation framework required)
- **Test execution**: Execute workflow commands via Claude Code CLI
- **Result validation**: Visual inspection of command output
- **Performance measurement**: Use `time` command or manual timing
- **CI/CD integration**: Not applicable for this phase (manual testing only)

## Validation Criteria

### Implementation Validation
- [ ] All 8 workflow command files updated with `Bash(git:*)` in allowed-tools
- [ ] All 8 workflow command files have Step 1.5 inserted after Step 1
- [ ] Step 1.5 implementation identical across all 8 files
- [ ] No syntax errors in workflow command files

### Functional Validation
- [ ] TC-1: Correct branch shows no warning ✓
- [ ] TC-2: Wrong branch shows warning ✓
- [ ] TC-3: Non-git directory gracefully skips ✓
- [ ] TC-4: Detached HEAD shows appropriate warning ✓
- [ ] TC-5: Missing Branch field gracefully skips ✓
- [ ] TC-6: All 8 commands show consistent warnings ✓
- [ ] TC-7: Warnings are non-blocking ✓
- [ ] TC-8: Correct branch has clean workflow ✓
- [ ] TC-9: Branch switch detected correctly ✓

### Regression Validation
- [ ] TC-10: Existing workflow functionality unchanged ✓
- [ ] TC-11: Step execution order correct ✓
- [ ] TC-12: Backward compatibility maintained ✓

### Non-Functional Validation
- [ ] TC-13: Performance overhead <100ms ✓
- [ ] TC-14: No command injection vulnerabilities ✓
- [ ] TC-15: Error messages clear and actionable ✓

### Success Criteria
- [ ] All 15 test cases passing
- [ ] 100% coverage of branch verification scenarios achieved
- [ ] No regressions in existing functionality
- [ ] Performance target met (<100ms overhead)
- [ ] Security validation passed
- [ ] Usability validation passed (clear warnings)

## Status
**Status**: Finished
**Next Action**: Testing plan complete - checkpoint commit created - ready to execute implementation
**Blockers**: None identified

## Recommended Workflow
Following the pattern from c-design.md:
1. ✅ Define implementation plan (d-implementation.md)
2. ✅ Define testing regime (this document)
3. ✅ Create checkpoint commit (save planning work)
4. ⏳ Execute implementation (modify 8 workflow command files)
5. ⏳ Execute testing (run 15 test cases, update this file with results)

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
