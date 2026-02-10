# fix-checkpoints-branch-perms-issue-with-script - Testing Plan
**Task**: 49 (bugfix)

## Task Reference
- **Task ID**: internal-49
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/49-fix-checkpoints-branch-perms-issue-with-script
- **Template Version**: 2.1

## Goal
Validate `checkpoints-branch-manager` script eliminates Step 10 permission prompts and handles all edge cases correctly.

## Test Strategy
### Test Levels
- **Unit Tests**: Manual testing of each subcommand in isolation
- **Integration Tests**: Script execution from Step 10 instructions (permission validation)
- **System Tests**: End-to-end retrospective workflow with script
- **Acceptance Tests**: Verify success criteria from a-task-plan.md

### Test Coverage Targets
- **Critical Paths**: 100% - All three subcommands (create, show-history, verify)
- **Edge Cases**: 100% - All error conditions (detached HEAD, branch exists, not in repo, missing branch)
- **Regression**: Verify existing Step 10 workflow still works with direct git commands
- **Security**: Script permissions (0500), hash validation

## Test Cases
### Functional Test Cases

#### TC-1: Create Checkpoints Branch (Happy Path)
- **Given**: On task branch `bugfix/49-fix-checkpoints-branch-perms-issue-with-script`, checkpoints branch doesn't exist
- **When**: Execute `checkpoints-branch-manager create`
- **Then**:
  - Branch `bugfix/49-fix-checkpoints-branch-perms-issue-with-script-checkpoints` created
  - Exit code 0
  - Output: "created branch bugfix/49-fix-checkpoints-branch-perms-issue-with-script-checkpoints"

#### TC-2: Create Checkpoints Branch - Already Exists
- **Given**: Checkpoints branch already exists
- **When**: Execute `checkpoints-branch-manager create`
- **Then**:
  - Exit code 1
  - Error message: "error: failed to create branch <name> (already exists)"
  - No duplicate branch created

#### TC-3: Create Checkpoints Branch - Detached HEAD
- **Given**: In detached HEAD state (e.g., `git checkout HEAD~1`)
- **When**: Execute `checkpoints-branch-manager create`
- **Then**:
  - Exit code 1
  - Error message: "error: not on a branch"

#### TC-4: Show History (Default Count)
- **Given**: On task branch with commit history
- **When**: Execute `checkpoints-branch-manager show-history`
- **Then**:
  - Exit code 0
  - Displays last 20 commits in `git log --oneline --graph` format
  - Output includes graph, hashes, commit messages

#### TC-5: Show History (Custom Count)
- **Given**: On task branch with commit history
- **When**: Execute `checkpoints-branch-manager show-history 10`
- **Then**:
  - Exit code 0
  - Displays last 10 commits in graph format

#### TC-6: Verify Checkpoints Branch (Happy Path)
- **Given**: Checkpoints branch exists with commits
- **When**: Execute `checkpoints-branch-manager verify`
- **Then**:
  - Exit code 0
  - Displays commits from checkpoints branch in `--oneline` format

#### TC-7: Verify Checkpoints Branch - Doesn't Exist
- **Given**: Checkpoints branch doesn't exist
- **When**: Execute `checkpoints-branch-manager verify`
- **Then**:
  - Exit code 1
  - Error message: "error: checkpoints branch not found"

#### TC-8: Invalid Subcommand
- **Given**: Script exists and is executable
- **When**: Execute `checkpoints-branch-manager invalid`
- **Then**:
  - Exit code 1
  - Error message: "Unknown subcommand: invalid"
  - Usage message displayed

#### TC-9: No Subcommand
- **Given**: Script exists and is executable
- **When**: Execute `checkpoints-branch-manager` (no arguments)
- **Then**:
  - Exit code 1
  - Usage message: "Usage: checkpoints-branch-manager <create|show-history|verify>"

### Non-Functional Test Cases

#### TC-10: Permission Validation (CRITICAL)
- **Given**: Script installed in `.cig/scripts/command-helpers/`, frontmatter allows `.cig/scripts/command-helpers/*:*`
- **When**: Execute all three subcommands from cig-retrospective context
- **Then**:
  - No permission prompts triggered
  - All commands execute successfully
  - User not interrupted for approval

#### TC-11: File Permissions (Security)
- **Given**: Script file exists at `.cig/scripts/command-helpers/checkpoints-branch-manager`
- **When**: Check file permissions with `stat -c '%a' checkpoints-branch-manager`
- **Then**:
  - Permissions are 500 (u+rx,go-rwx)
  - Script is executable by owner only
  - Follows CIG security model

#### TC-12: Security Hash Validation
- **Given**: Script hash recorded in `.cig/security/script-hashes.json`
- **When**: Run `/cig-security-check verify`
- **Then**:
  - Hash matches current script content
  - No integrity violations reported
  - Script verified as authentic

#### TC-13: Error Message Clarity (Usability)
- **Given**: Various error conditions (detached HEAD, branch exists, etc.)
- **When**: Trigger each error condition
- **Then**:
  - Error messages are clear and actionable
  - Messages include script path prefix for context
  - Users understand what went wrong and how to fix it

#### TC-14: Backward Compatibility (Regression)
- **Given**: Step 10 instructions updated with script commands
- **When**: User manually runs original git commands instead of script
- **Then**:
  - Original commands still work
  - No breaking changes to existing workflow
  - Users can choose script or direct git approach

## Test Environment
### Setup Requirements
- **Git repository**: Valid git repo with commit history
- **Branch setup**: Clean task branch (not detached HEAD)
- **CIG environment**: Script installed in `.cig/scripts/command-helpers/`
- **Permissions**: Test both with and without Claude Code permission system
- **Test branches**: Create/delete test branches as needed

### Test Data
- **Branches**: `bugfix/49-*` (current task branch)
- **Commits**: Multiple checkpoint commits for history testing
- **Checkpoints branch**: Create/delete for testing create/verify

### Automation
- **Manual testing**: All test cases executed manually during g-testing-exec
- **Validation script**: Optional bash script to run TC-1 through TC-14 sequentially
- **CI/CD**: Not applicable (CIG infrastructure testing)

## Validation Criteria
- [ ] TC-1 through TC-9: All functional test cases passing (100%)
- [ ] TC-10 (CRITICAL): No permission prompts when executing from Step 10
- [ ] TC-11: File permissions correct (500)
- [ ] TC-12: Security hash validated
- [ ] TC-13: Error messages clear and helpful
- [ ] TC-14: Backward compatibility maintained
- [ ] All success criteria from a-task-plan.md satisfied

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **NO** - manual testing ~1 hour
- [ ] **People**: Does this need >2 people working on different parts? **NO** - single tester
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **NO** - single concern (validate script works)
- [ ] **Risk**: Are there high-risk components that need isolation? **NO** - low-risk testing
- [ ] **Independence**: Can parts be worked on separately? **NO** - test cases build on each other

**Decomposition Decision**: No decomposition needed.

## Status
**Status**: In Progress
**Next Action**: /cig-implementation-exec
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
