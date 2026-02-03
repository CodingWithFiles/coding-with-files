# add-task-stack-script - Testing Plan

## Task Reference
- **Task ID**: internal-34
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/34-add-task-stack-script
- **Template Version**: 2.1

## Goal
Validate task stack management system through comprehensive testing of all 6 operations, integrations, and 22 acceptance criteria.

## Test Strategy

### Test Levels
- **Unit Tests**: Script operations (push/pop/peek/list/clear/size) tested independently
- **Integration Tests**: Task 32 inference, /cig-init skill, CIG::TaskPath integration
- **System Tests**: End-to-end workflows via /cig-current-task skill
- **Acceptance Tests**: All 22 AC from requirements validated

### Test Coverage Targets
- **Overall Coverage**: 100% of implemented functions (6 operations + helpers)
- **Critical Paths**: 100% coverage - push, pop, list (core operations)
- **Edge Cases**: Empty stack, invalid tasks, concurrent access, missing file
- **Regression**: Task 32 inference works with and without stack file

## Test Cases

### Functional Test Cases (AC1-AC7)

**TC-F1: Push Operation**
- **Given**: Task 34 exists in implementation-guide/
- **When**: Run `./cig/scripts/command-helpers/task-stack push 34`
- **Then**:
  - File `.cig/task-stack` created
  - Contains `34-feature-add-task-stack-script`
  - Output: `.cig/scripts/.../task-stack: pushed 34-feature-add-task-stack-script`
- **Acceptance**: AC1

**TC-F2: Pop Operation**
- **Given**: Stack contains 2 entries (33, 34)
- **When**: Run `task-stack pop`
- **Then**:
  - Returns `34-feature-add-task-stack-script`
  - File now contains only 33 entry
  - File has N-1 lines
- **Acceptance**: AC2

**TC-F3: Peek Operation**
- **Given**: Stack contains 3 entries
- **When**: Run `task-stack peek`
- **Then**:
  - Returns last entry (top of stack)
  - File unchanged (same line count)
- **Acceptance**: AC3

**TC-F4: List Operation - Output Format**
- **Given**: Stack contains 3 tasks
- **When**: Run `task-stack list`
- **Then**: Output format matches:
  ```
  .cig/scripts/command-helpers/task-stack: list task stack (use --help for options)
  .cig/scripts/command-helpers/task-stack: showing 3 of 3 total tasks, most recent last
  32-feature-task-tracking-using-inference-scoring
  33-feature-task-tracking-path-cleanup-and-extension
  34-feature-add-task-stack-script
  ```
- **Acceptance**: AC4

**TC-F5: List Operation - Scriptability**
- **Given**: Stack contains 3 tasks
- **When**: Run `task-stack list | tail -n 1`
- **Then**: Returns `34-feature-add-task-stack-script` (current task)
- **Acceptance**: AC5

**TC-F6: Clear Operation**
- **Given**: Stack contains entries
- **When**: Run `task-stack clear` twice
- **Then**:
  - First call: Deletes file, outputs success
  - Second call: Still succeeds (idempotent), outputs success
- **Acceptance**: AC6

**TC-F7: Size Operation**
- **Given**: Stack has 3 entries
- **When**: Run `task-stack size`
- **Then**: Outputs `3`
- **Given**: Stack is empty or file missing
- **When**: Run `task-stack size`
- **Then**: Outputs `0`
- **Acceptance**: AC7

### Non-Functional Test Cases (AC8-AC11)

**TC-NF1: Performance**
- **Given**: Stack with 100 entries
- **When**: Run each operation (push, pop, peek, list, clear, size)
- **Then**: Each completes in < 100ms
- **Acceptance**: AC8

**TC-NF2: Concurrent Access**
- **Given**: Empty stack
- **When**: Run 2 concurrent pushes (Task 33, Task 34) from different terminals
- **Then**:
  - File contains both entries (no corruption)
  - Both operations succeed
  - File has exactly 2 lines
- **Acceptance**: AC9

**TC-NF3: Error Messages**
- **Given**: Error condition (empty stack pop, invalid task)
- **When**: Operation fails
- **Then**: Error message includes:
  - Script relative path
  - Operation attempted
  - Actionable guidance
- **Example**: `.cig/scripts/.../task-stack: error: task 99999 not found`
- **Acceptance**: AC10

**TC-NF4: Invalid Task Handling**
- **Given**: Task 99999 doesn't exist
- **When**: Run `task-stack push 99999`
- **Then**:
  - Operation fails with clear error
  - File NOT created
  - Exit code non-zero
- **Acceptance**: AC11

### Integration Test Cases (AC12-AC15)

**TC-I1: Skill Wrapper**
- **Given**: Stack is empty
- **When**: Run `/cig-current-task push 34` via skill
- **Then**: Skill delegates to script, displays output
- **When**: Run `/cig-current-task` with no args
- **Then**: Skill calls `task-stack list`, displays result
- **Acceptance**: AC12

**TC-I2: PreToolUse Hook**
- **Given**: PreToolUse hook configured
- **When**: Agent attempts `Edit` on `.cig/task-stack`
- **Then**:
  - Operation blocked
  - Message: "Use `/cig-current-task` instead"
  - Explanation provided
- **Acceptance**: AC13

**TC-I3: Task 32 Inference Integration**
- **Given**: Stack contains task 34 (top) and tasks 30-33
- **When**: Run `task-context-inference`
- **Then**:
  - Returns task 34 as primary candidate
  - Context includes tasks 30-34
  - Score: 100 (high confidence)
  - Source: state_file
- **Acceptance**: AC14

**TC-I4: Task 32 Graceful Degradation**
- **Given**: `.cig/task-stack` file doesn't exist
- **When**: Run `task-context-inference`
- **Then**:
  - Inference still works (uses other signals)
  - No errors about missing file
  - Stack signal omitted from results
- **Acceptance**: AC15

### Security Test Cases (AC16-AC18)

**TC-S1: File Permissions**
- **Given**: Push creates new file
- **When**: Check file permissions
- **Then**: Permissions are 0600 (user-only access)
- **Acceptance**: AC16

**TC-S2: flock Prevents Corruption**
- **Given**: Concurrent operations scenario
- **When**: Two processes modify stack simultaneously
- **Then**:
  - flock serializes access
  - No partial writes
  - File remains valid (parse-able dirnames)
- **Acceptance**: AC17

**TC-S3: Format Validation**
- **Given**: Manual corruption - invalid dirname in file
- **When**: Run `task-stack list`
- **Then**:
  - Script doesn't crash
  - Shows raw dirname (graceful degradation)
  - No perl errors
- **Acceptance**: AC18

### Cleanup Test Cases (AC19-AC20)

**TC-C1: Old Command Removal**
- **Given**: Task 34 implementation complete
- **When**: Check for `.claude/commands/cig-current.md`
- **Then**: File doesn't exist (deleted if it was present)
- **Acceptance**: AC19

**TC-C2: Reference Cleanup**
- **Given**: Implementation complete
- **When**: Run `grep -r "/cig-current[^-]" .claude/`
- **Then**: No matches (except `/cig-current-task`)
- **Acceptance**: AC20

### Initialization Test Cases (AC21-AC22)

**TC-IN1: cig-init Integration**
- **Given**: Fresh repository without `.gitignore`
- **When**: Run `/cig-init`
- **Then**: `.gitignore` contains `.cig/task-stack` entry
- **Acceptance**: AC21

**TC-IN2: cig-init Idempotency**
- **Given**: `.gitignore` already contains `.cig/task-stack`
- **When**: Run `/cig-init` again
- **Then**:
  - No duplicate entries added
  - Operation succeeds
  - `.gitignore` still valid
- **Acceptance**: AC22

## Test Environment

### Setup Requirements
- **CIG system installed**: Task 33 (CIG::TaskPath) must be available
- **Git repository**: Required for relative path calculation
- **Perl 5.x**: With core modules (Fcntl, FindBin)
- **Test fixtures**:
  - Multiple test tasks in implementation-guide/ (for push testing)
  - Empty `.cig/task-stack` for baseline tests

### Test Data
- **Valid tasks**: 32, 33, 34 (known to exist)
- **Invalid task**: 99999 (known not to exist)
- **Concurrent test**: Two terminal sessions for race condition testing

### Automation
- **Manual execution**: Bash script invoking each operation
- **Test script location**: Can create `.cig/scripts/test-task-stack.sh` for automation
- **CI/CD**: Not applicable (internal tool, manual validation sufficient)
- **Regression**: Run before any future modifications to task-stack script

## Validation Criteria

### Functional Validation
- [ ] All 7 functional test cases pass (TC-F1 through TC-F7)
- [ ] All 6 operations work correctly (push/pop/peek/list/clear/size)
- [ ] Output format matches design specification

### Non-Functional Validation
- [ ] All 4 non-functional test cases pass (TC-NF1 through TC-NF4)
- [ ] Performance: All operations < 100ms
- [ ] Concurrency: flock prevents corruption
- [ ] Error handling: Clear, actionable messages

### Integration Validation
- [ ] All 4 integration test cases pass (TC-I1 through TC-I4)
- [ ] Skill wrapper works correctly
- [ ] Task 32 integration functional
- [ ] Graceful degradation when stack absent

### Security Validation
- [ ] All 3 security test cases pass (TC-S1 through TC-S3)
- [ ] File permissions correct (0600)
- [ ] flock prevents race conditions
- [ ] Invalid format handling graceful

### Cleanup Validation
- [ ] All 2 cleanup test cases pass (TC-C1 through TC-C2)
- [ ] Old `/cig-current` removed
- [ ] No stray references remain

### Initialization Validation
- [ ] All 2 initialization test cases pass (TC-IN1 through TC-IN2)
- [ ] `/cig-init` adds `.gitignore` entry
- [ ] Idempotent operation

### Overall Success
- [ ] All 22 test cases pass
- [ ] All 22 acceptance criteria validated (AC1-AC22)
- [ ] No regressions detected
- [ ] System ready for rollout

## Status
**Status**: Finished
**Next Action**: Move to implementation execution → `/cig-implementation-exec 34`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled during testing execution*

## Lessons Learned
*To be captured during testing execution*
