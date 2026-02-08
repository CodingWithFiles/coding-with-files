# Clean up missed items from 39/40/41 - Testing

## Task Reference
- **Task ID**: internal-43
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/43-clean-up-missed-items-from-39-40-41
- **Template Version**: 2.1

## Goal
Validate that removing 7 obsolete scripts doesn't break any CIG functionality.

## Test Strategy

### Test Levels
- **Pre-removal Verification**: Grep-based validation that scripts are truly obsolete
- **Integration Tests**: Verify CIG commands still work after removal
- **Regression Tests**: Verify Tasks 35-40 functionality unchanged
- **Security Tests**: Verify security check passes with updated hashes

### Test Coverage Targets
- **Critical Paths**: 100% - All CIG commands that previously used old scripts must work
- **Regression**: 100% - Tasks 35-40 commands must remain functional
- **Security**: 100% - All security checks must pass

## Test Cases

### Pre-Removal Verification Tests

#### TC-PRE-1: Verify No Active Command References
- **Given**: 7 obsolete script names
- **When**: Grep `.claude/commands/` for references
- **Then**: Zero matches found (all commands use trampolines now)

#### TC-PRE-2: Verify No Active Script Invocations
- **Given**: 7 obsolete script names
- **When**: Grep `.cig/scripts/` for invocations (excluding historical docs)
- **Then**: Zero matches found (all scripts use trampolines/modules now)

#### TC-PRE-3: Verify Security Check References
- **Given**: `/cig-security-check` command file
- **When**: Check for hardcoded references to 7 scripts
- **Then**: No hardcoded references (uses script-hashes.json dynamically)

### Post-Removal Integration Tests

#### TC-INT-1: Status Aggregation Still Works
- **Given**: Scripts deleted, script-hashes.json updated
- **When**: Run `/cig-status 43` or `workflow-manager status --workflow 43`
- **Then**: Status displays correctly (uses workflow-manager, not old status-aggregator)

#### TC-INT-2: Task Creation Still Works
- **Given**: Scripts deleted, script-hashes.json updated
- **When**: Run test task creation with `task-workflow create`
- **Then**: Task created successfully (uses task-workflow, not old template-copier)

#### TC-INT-3: Context Hierarchy Still Works
- **Given**: Scripts deleted, script-hashes.json updated
- **When**: Run `context-manager hierarchy 43`
- **Then**: Hierarchy resolved correctly (uses context-manager, not old hierarchy-resolver)

#### TC-INT-4: Security Check Passes
- **Given**: Scripts deleted, script-hashes.json updated
- **When**: Run `/cig-security-check verify`
- **Then**: Verification passes with no errors (hashes match remaining scripts)

### Regression Tests

#### TC-REG-1: Task 35 Commands Work
- **Given**: Task 35 used old scripts for git root detection
- **When**: Run commands from Task 35 workflow
- **Then**: All commands execute successfully (now use trampolines)

#### TC-REG-2: Task 36 Commands Work
- **Given**: Task 36 refactored git root detection
- **When**: Run commands from Task 36 workflow
- **Then**: All commands execute successfully

#### TC-REG-3: Tasks 39/40/41 Commands Work
- **Given**: Tasks 39/40/41 created trampoline architecture
- **When**: Run commands that test the new architecture
- **Then**: All trampolines and modules work correctly

### Non-Functional Test Cases

#### TC-NF-1: Rollback Safety
- **Test**: Can changes be safely reverted if issues found?
- **Validation**: Single atomic commit allows `git revert HEAD`
- **Success**: Rollback restores all 7 scripts and hashes

#### TC-NF-2: File System Cleanliness
- **Test**: Are there any orphaned files or broken symlinks?
- **Validation**: `ls -la .cig/scripts/command-helpers/` shows clean state
- **Success**: Only trampolines and modules remain, no broken refs

## Test Environment

### Setup Requirements
- Git repository with Task 43 changes committed
- Access to all CIG commands
- Ability to run bash scripts

### Automation
- **Framework**: Manual grep + bash command execution
- **CI/CD**: N/A - one-time cleanup task
- **Repeatability**: All test commands documented in test cases

## Validation Criteria

### Pre-removal (Must pass before deletion)
- [ ] TC-PRE-1: No command references ✓
- [ ] TC-PRE-2: No script invocations ✓
- [ ] TC-PRE-3: No hardcoded security refs ✓

### Post-removal (Must pass after deletion)
- [ ] TC-INT-1: Status aggregation works ✓
- [ ] TC-INT-2: Task creation works ✓
- [ ] TC-INT-3: Context hierarchy works ✓
- [ ] TC-INT-4: Security check passes ✓
- [ ] TC-REG-1: Task 35 commands work ✓
- [ ] TC-REG-2: Task 36 commands work ✓
- [ ] TC-REG-3: Tasks 39/40/41 work ✓
- [ ] TC-NF-1: Rollback tested ✓
- [ ] TC-NF-2: File system clean ✓

**Total**: 12 test cases (3 pre-removal + 9 post-removal)

## Status
**Status**: Finished
**Next Action**: Move to implementation execution → `/cig-implementation-exec 43`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
