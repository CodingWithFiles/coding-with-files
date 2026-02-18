# fix var use in commands to avoid bash issues - Testing Plan
**Task**: 47 (bugfix)

## Task Reference
- **Task ID**: internal-47
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/47-fix-var-use-in-commands-to-avoid-bash-issues
- **Template Version**: 2.1

## Goal
Define validation strategy to verify all 17 CIG command files use `{placeholder}` syntax exclusively and execute without triggering permission prompts for helper script calls.

## Test Strategy
### Test Approach
**Manual validation** (no automated test infrastructure for documentation-only changes)

**Test Levels**:
- **Verification Tests**: Grep-based pattern verification (automated via bash)
- **Functional Tests**: Manual command execution to verify no permission prompts
- **Regression Tests**: Git diff review to ensure no logic changes

### Test Coverage Targets
- **File Coverage**: 100% (all 17 command files verified)
- **Pattern Coverage**: 100% (`$VARIABLE` and `<placeholder>` patterns eliminated)
- **Command Coverage**: Representative sample (3-5 commands covering different types)
- **Regression Coverage**: Git diff review of all modified files

## Test Cases
### Verification Test Cases (Grep-Based)
**TC-1: Verify $VARIABLE patterns eliminated**
- **Given**: All 17 command files have been modified
- **When**: Run `grep -n '\$[A-Z_]*' .claude/commands/cig-*.md`
- **Then**: Zero matches returned (or only legitimate bash examples with clear context)

**TC-2: Verify <placeholder> patterns eliminated from argument-hint**
- **Given**: All frontmatter argument-hint fields modified
- **When**: Run `grep -n 'argument-hint:.*<' .claude/commands/cig-*.md`
- **Then**: Zero matches returned

**TC-3: Verify file modification count**
- **Given**: Implementation complete
- **When**: Run `git diff --name-only main | grep 'cig-.*.md' | wc -l`
- **Then**: Exactly 17 files modified

**TC-4: Verify {placeholder} syntax adoption**
- **Given**: All replacements complete
- **When**: Run `grep -n '{[a-z-]*}' .claude/commands/cig-*.md | wc -l`
- **Then**: Multiple matches found (confirming new syntax adopted)

### Functional Test Cases (Manual Execution)
**TC-5: High-traffic command - Task creation**
- **Given**: On Task 47 branch with all changes committed
- **When**: Execute `/cig-new-task 99 feature "test validation"`
- **Then**:
  - Task 99 directory created successfully
  - No permission prompts appear during execution
  - Command completes without errors

**TC-6: Workflow command - Planning**
- **Given**: Test task 99 exists from TC-5
- **When**: Execute `/cig-task-plan 99`
- **Then**:
  - Planning file opens successfully
  - No permission prompts for helper script calls
  - Command completes without errors

**TC-7: Utility command - Status**
- **Given**: Repository with multiple tasks including test task 99
- **When**: Execute `/cig-status`
- **Then**:
  - Status display shows task hierarchy
  - No permission prompts for status-aggregator script
  - Command completes without errors

### Regression Test Cases
**TC-8: Git diff review - No logic changes**
- **Given**: All replacements complete
- **When**: Review `git diff main` for all 17 files
- **Then**:
  - Only placeholder syntax changed (`$VAR` → `{var}`, `<placeholder>` → `{placeholder}`)
  - No changes to command logic, structure, or behavior
  - No changes to frontmatter permissions or descriptions

**TC-9: Cleanup test artifacts**
- **Given**: TC-5, TC-6, TC-7 completed successfully
- **When**: Run `rm -rf implementation-guide/99-feature-test-validation && git checkout bugfix/47-fix-var-use-in-commands-to-avoid-bash-issues`
- **Then**: Test task 99 removed, branch clean for final commit

## Test Environment
### Setup Requirements
**Minimal setup** (documentation-only changes):
- Git repository with Task 47 branch checked out
- All 17 command files modified with placeholder replacements
- Grep and git commands available (standard development environment)

**No additional dependencies**:
- No test frameworks needed
- No mock services required
- No database or external services involved

### Automation Approach
**Semi-automated verification**:
- **Automated**: Grep verification tests (TC-1 through TC-4) via bash commands
- **Manual**: Command execution tests (TC-5 through TC-7) via interactive testing
- **Manual**: Git diff review (TC-8) via visual inspection

**Why not fully automated**:
- Documentation changes don't require unit test infrastructure
- Permission prompt detection requires interactive session observation
- Git diff review benefits from human judgment on logic preservation

## Validation Criteria
### Must-Pass Criteria (Blockers for Completion)
- [ ] **TC-1 PASS**: Zero `$VARIABLE` patterns remaining (grep verification)
- [ ] **TC-2 PASS**: Zero `<placeholder>` patterns in argument-hint (grep verification)
- [ ] **TC-3 PASS**: Exactly 17 files modified (file count verification)
- [ ] **TC-5 PASS**: `/cig-new-task` executes without permission prompts
- [ ] **TC-6 PASS**: `/cig-task-plan` executes without permission prompts
- [ ] **TC-7 PASS**: `/cig-status` executes without permission prompts
- [ ] **TC-8 PASS**: Git diff shows only placeholder syntax changes (no logic modifications)

### Nice-to-Have Criteria (Non-Blocking)
- [ ] **TC-4 PASS**: Multiple `{placeholder}` patterns found (confirms adoption)
- [ ] **TC-9 PASS**: Test artifacts cleaned up successfully

### Success Threshold
**100% of must-pass criteria** (7/7 tests) required for task completion

## Status
**Status**: Finished
**Next Action**: /cig-implementation-exec 47 (bugfix workflow: testing-plan → implementation-exec → testing-exec)
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
