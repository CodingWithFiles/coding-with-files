# reduce permission prompts from git root detection - Testing

## Task Reference
- **Task ID**: internal-39
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/39-reduce-permission-prompts-from-git-root-detection
- **Template Version**: 2.1

## Goal
Validate that the trampoline/module architecture eliminates permission prompts while maintaining functionality.

## Test Strategy
### Test Levels
- **Validation Tests**: Grep-based verification that all files updated correctly
- **Functional Tests**: Manual testing that CIG commands still work
- **Regression Tests**: Verify no permission prompts triggered
- **Usability Tests**: Confirm error messages still clear

### Test Coverage Targets
- **Script Coverage**: 100% of new scripts created and executable (2 scripts)
- **File Coverage**: 100% of 17 CIG command files verified
- **Pattern Coverage**: 100% of old inline bash replaced with `context-manager location`
- **Functional Coverage**: Sample test of 3-5 representative commands
- **Regression Coverage**: Zero permission prompts during command execution

## Test Cases
### Functional Test Cases

#### TC-1: context-manager Script Creation
- **Given**: No context-manager script exists
- **When**: Trampoline script created
- **Then**:
  - File exists: `.cig/scripts/command-helpers/context-manager`
  - File is executable (u+x permission)
  - File has Perl shebang (`#!/usr/bin/env perl`)
  - File has no extension (Unix convention)

#### TC-2: location Module Creation
- **Given**: No location module exists
- **When**: Module script created
- **Then**:
  - Directory exists: `.cig/scripts/command-helpers/context-manager.d/`
  - File exists: `.cig/scripts/command-helpers/context-manager.d/location`
  - File is executable (u+x permission)
  - File has Perl shebang (`#!/usr/bin/env perl`)
  - File has no extension (Unix convention)

#### TC-3: Trampoline Dispatch Logic
- **Given**: context-manager trampoline exists
- **When**: Called with `location` subcommand
- **Then**:
  - Executes `context-manager.d/location` module
  - Passes through any additional arguments
  - Exits with appropriate error for unknown subcommands

#### TC-4: Pattern Replacement Verification
- **Given**: 17 CIG command files with old 7-line inline bash
- **When**: Pattern replacement implemented
- **Then**:
  - All 17 files contain `context-manager location` call
  - All 17 files do NOT contain old 7-line inline bash
  - Grep count for old pattern = 0
  - Grep count for `context-manager location` = 17

#### TC-5: cig-new-task Documentation Update
- **Given**: cig-new-task Step 5 without clarifying note
- **When**: Documentation updated
- **Then**:
  - Step 5 contains note about template-copier creating directories
  - Note mentions "automatically" and "no need to create it with mkdir"
  - Note appears after code block

#### TC-6: location Module Functionality
- **Given**: location module created and executable
- **When**: Module executed from git repository root
- **Then**:
  - Outputs git repository root path
  - Outputs current working directory
  - Output format includes both paths clearly labeled
  - No permission prompts triggered

#### TC-7: location Module Error Handling
- **Given**: location module created and executable
- **When**: Module executed from non-git directory
- **Then**:
  - git rev-parse error is shown: "fatal: not a git repository"
  - Current directory is still shown
  - Module exits cleanly (doesn't crash)

#### TC-8: Zero Permission Prompts (Critical)
- **Given**: Updated CIG commands with `context-manager location` call
- **When**: Command executed (e.g., `/cig-status`)
- **Then**:
  - Zero permission prompts appear
  - Command executes without interruption
  - No "Allow bash?" prompts (permission granted at trampoline level)

#### TC-9: Command Functionality Unchanged
- **Given**: Updated CIG commands
- **When**: Sample commands executed (cig-status, cig-new-task, cig-task-plan)
- **Then**:
  - Commands produce expected output
  - No regressions in functionality
  - Helper scripts still resolve correctly
  - Git root information displayed correctly

### Non-Functional Test Cases

#### TC-U1: Usability - Error Message Clarity
- **Given**: location module running outside git repository
- **When**: User runs command outside git repository
- **Then**:
  - Error message clearly indicates problem (not in git repo)
  - Error comes from git (standard, well-known message)
  - Current directory still shown for context
  - User knows how to fix (cd to git repo)

#### TC-U2: Usability - Documentation Clarity
- **Given**: Updated cig-new-task documentation
- **When**: LLM reads Step 5
- **Then**:
  - LLM understands template-copier creates directories
  - LLM doesn't attempt mkdir separately
  - Guidance is clear and unambiguous

#### TC-U3: Usability - Trampoline Pattern
- **Given**: context-manager trampoline architecture
- **When**: Developer wants to add new subcommand
- **Then**:
  - Pattern is clear and easy to follow
  - Simple to add new module in context-manager.d/
  - Dispatcher logic is straightforward

#### TC-R1: Reliability - Backward Compatibility
- **Given**: Existing workflows using CIG commands
- **When**: Commands updated with context-manager pattern
- **Then**:
  - All existing workflows continue to work
  - No breaking changes to command behavior
  - Helper scripts resolve paths identically
  - Output includes same information (git root, cwd)

#### TC-R2: Reliability - Script Permissions
- **Given**: context-manager and location scripts
- **When**: Scripts created with proper permissions
- **Then**:
  - Both scripts have u+x (executable) permission
  - Scripts use proper Perl shebang
  - Scripts follow Unix conventions (no extensions)

## Test Environment
### Setup Requirements
- **Git repository**: Current CIG repository with updated command files
- **Test directory**: Temporary non-git directory for error case testing
- **Command samples**: Select 3-5 representative CIG commands for functional testing
- **Grep utility**: For pattern verification
- **Perl interpreter**: Required for new scripts (already present on system)

### Test Execution Method
- **Script verification**: Check file existence, permissions, shebang
- **Module testing**: Direct execution of context-manager and location scripts
- **Validation**: Grep-based counts and pattern matching
- **Functional**: Manual execution of sample CIG commands
- **Regression**: Monitor for permission prompts during execution
- **Usability**: Review error messages and documentation

### Automation
- **Script verification**: Automated checks for existence, permissions, format
- **Grep verification**: Automated pattern counting
- **Manual testing**: One-time verification (script/documentation changes don't need CI/CD)
- **No unit test framework needed**: Changes are scripts and documentation only

## Validation Criteria
- [ ] **TC-1**: context-manager script created and executable
- [ ] **TC-2**: location module created and executable
- [ ] **TC-3**: Trampoline dispatch logic works correctly
- [ ] **TC-4**: All 17 files have `context-manager location`, 0 have old inline bash
- [ ] **TC-5**: cig-new-task has template-copier clarification
- [ ] **TC-6**: location module shows git root and cwd correctly
- [ ] **TC-7**: location module handles non-git directory gracefully
- [ ] **TC-8**: Zero permission prompts during command execution (CRITICAL)
- [ ] **TC-9**: Sample commands work identically to before
- [ ] **TC-U1, TC-U2, TC-U3**: Usability tests pass
- [ ] **TC-R1, TC-R2**: Reliability tests pass (backward compatibility, permissions)
- [ ] **Success Criteria**: All 5 from a-task-plan.md verified

## Decomposition Check
Review these signals to determine if testing should be broken into subtasks:
- [ ] **Time**: Will testing take >1 week? **No** - Estimated 30 minutes for verification
- [ ] **People**: Does testing need >2 people? **No** - Single person can validate
- [ ] **Complexity**: Does testing involve 3+ distinct concerns? **No** - Simple grep + manual testing
- [ ] **Risk**: Are there high-risk tests? **No** - Low risk documentation verification
- [ ] **Independence**: Can test groups run separately? **No** - Quick sequential testing

**Analysis**: 0/5 signals triggered. Testing appropriately scoped as single phase.

## Status
**Status**: Finished
**Next Action**: Move to implementation execution → `/cig-implementation-exec 39`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
