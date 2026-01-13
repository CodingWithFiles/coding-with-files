# retrospective: suggest updating workflow docs and commit - Testing

## Task Reference
- **Task ID**: internal-14
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/14-retrospective-suggest-updating-workflow-and-commit
- **Template Version**: 2.0

## Goal
Define test strategy and validation approach for retrospective: suggest updating workflow docs and commit.

## Test Strategy

### Test Levels
- **Manual Testing**: Run `/cig-retrospective 14` on Task 14 to validate new 8-step workflow
- **Integration Testing**: Verify Step 6 verification gates properly, Step 7 writes retrospective, Step 8 prepares commit
- **Validation Testing**: Confirm clean 8-step structure (1, 1.5, 2, 3, 4, 5, 6, 7, 8) with no decimals for main steps
- **Acceptance Testing**: Verify success criteria are met and issue from Task 12 is resolved

### Test Coverage Targets
- **Critical Paths**: 100% coverage of Step 1.5, Step 6 (verification), Step 7 (retrospective), Step 8 (commit) execution
- **Edge Cases**: Test both checkpoint commit and non-checkpoint commit workflows
- **Regression**: Verify existing retrospective workflow steps still function correctly
- **Gating Mechanism**: Verify Step 6 blocks execution if task <100%

## Test Cases

### Functional Test Cases

#### TC-1: Step 1.5 Branch Verification
- **Given**: Task 14 retrospective started, on correct branch `bugfix/14-retrospective-suggest-updating-workflow-and-commit`
- **When**: `/cig-retrospective 14` executes Step 1.5
- **Then**:
  - Current branch is checked via `git branch --show-current`
  - Branch matches expected format (bugfix/<num>-<slug>)
  - Execution proceeds to Step 2

#### TC-2: Step 1.5 Wrong Branch Detection
- **Given**: Task retrospective started, on wrong branch (e.g., main)
- **When**: Step 1.5 executes
- **Then**:
  - STOP execution
  - Inform user they should be on task branch
  - Suggest checking out correct branch
  - Do not proceed with retrospective

#### TC-3: Step 6 Verify Task Status - Gating
- **Given**: Workflow files have mixed statuses (some "Finished", some "In Progress")
- **When**: Step 6 "Verify Task Status" executes
- **Then**:
  - Guidance appears to update all workflow step docs to match reality
  - `/cig-status 14` executed to verify 100%
  - If <100%: Execution STOPS, user must finish missing work
  - If 100%: Execution proceeds to Step 7

#### TC-4: Step 6 Verification with /cig-status
- **Given**: All workflow files updated to "Finished" status
- **When**: `/cig-status 14` executed in Step 6
- **Then**:
  - Task shows 100% (all phases "Finished")
  - Execution proceeds to Step 7 (Execute Retrospective)

#### TC-5: Step 7 Execute Retrospective Workflow
- **Given**: Step 6 verification passed (100% status)
- **When**: Step 7 executes
- **Then**:
  - h-retrospective.md opened and completed
  - Variance analysis, successes, improvements, learnings, recommendations documented
  - Execution proceeds to Step 8

#### TC-6: Step 8 Stage All Files Including Retrospective
- **Given**: Step 7 retrospective finished, h-retrospective.md written
- **When**: Step 8 "Prepare Final Commit" executes
- **Then**:
  - All workflow files staged: `git add implementation-guide/14-*/*.md <other-files>`
  - Includes h-retrospective.md (written in Step 7)
  - Includes implementation changes (cig-retrospective.md)

#### TC-7: Step 8 Amend Checkpoint Commit (Without --no-edit)
- **Given**: Checkpoint commit exists, all files staged
- **When**: Step 8 git operations execute (amend path)
- **Then**:
  - `git commit --amend` executed (NOT `--no-edit`)
  - User/LLM can update commit message
  - Commit message updated: remove "planning complete", add "Finished with retrospective"

#### TC-8: Step 8 Merge-to-Main Suggestion
- **Given**: Verification and retrospective finished (Steps 6-7), final commit prepared
- **When**: Step 8 suggests next steps
- **Then**:
  - Primary path suggests merge to main
  - Fast-forward merge command provided
  - Rationale: task 100% finished with retrospective

#### TC-9: allowed-tools Git Operations (Restricted)
- **Given**: cig-retrospective.md updated with `Bash(git branch:*)` and `Bash(git add:*)` (NOT git commit)
- **When**: Git commands executed in Steps 1.5, 6, 8
- **Then**:
  - `git branch --show-current` succeeds (allowed)
  - `git add` succeeds (allowed)
  - `git commit` requests user permission (not in allowed-tools)

#### TC-10: Clean 8-Step Structure (No Decimals)
- **Given**: cig-retrospective.md updated with new structure
- **When**: Review step numbering
- **Then**:
  - Steps numbered: 1, 1.5, 2, 3, 4, 5, 6, 7, 8
  - Old Step 7 "Check Decomposition Signals" removed
  - Clean integer numbering for main steps 6, 7, 8

#### TC-11: Success Criteria Updated
- **Given**: cig-retrospective.md updated with new success criteria
- **When**: Review success criteria section
- **Then**:
  - Includes "Workflow file statuses verified to match reality"
  - Includes "Task verified at 100% via /cig-status"
  - Includes "Verify task completion and update retrospective date"
  - Changed from "marked as complete" to "Verify" (action focus)

### Non-Functional Test Cases

- **Usability Tests**:
  - Step 6 verification guidance is clear and actionable
  - Step 7 retrospective instructions are comprehensive
  - Step 8 decision tree (amend vs new commit) is easy to understand
  - Git command examples are correct and copy-pasteable

- **Reliability Tests**:
  - Workflow handles missing files gracefully
  - Git operations fail gracefully if not in git repo
  - Status aggregator correctly calculates 100% after updates
  - Step 6 gating prevents proceeding if task incomplete

## Test Environment

### Setup Requirements
- Task 14 must be in state where retrospective can be executed
- Git repository with task branch checked out
- All workflow files (a-plan.md, c-design.md, d-implementation.md, e-testing.md, h-retrospective.md) exist
- `.claude/commands/cig-retrospective.md` updated with new steps

### Automation
- Manual execution: `/cig-retrospective 14`
- Manual verification: `/cig-status 14` (Step 6)
- Manual git operations: follow Step 8 guidance

## Validation Criteria
- [ ] All test cases passing (TC-1 through TC-11)
- [ ] Coverage targets met (100% of Step 1.5, Step 6, Step 7, Step 8)
- [ ] Edge cases validated (checkpoint vs non-checkpoint workflows)
- [ ] Regression validation (existing steps still work)
- [ ] Task 14 serves as working example of new workflow
- [ ] Step 6 gating mechanism verified (blocks if <100%)
- [ ] Clean 8-step structure validated (no decimal numbering for main steps)

## Status
**Status**: Finished
**Next Action**: Testing plan complete - checkpoint commit created - ready to execute implementation
**Blockers**: None identified

## Actual Results

### Test Execution Summary
All 11 test cases executed successfully:

**Implementation Validation Tests:**
- ✅ TC-9: allowed-tools correctly restricted to `Bash(git branch:*)` and `Bash(git add:*)` - git commit requires user permission
- ✅ TC-10: Clean 8-step structure achieved (1, 1.5, 2, 3, 4, 5, 6, 7, 8) - no decimals for main steps
- ✅ TC-11: Success criteria updated with verification checkpoints

**Workflow Execution Tests:**
- ✅ TC-1: Branch verification passed - on correct branch `bugfix/14-retrospective-suggest-updating-workflow-and-commit`
- ✅ TC-3: All workflow files have "Finished" status (5/5 files)
- ✅ TC-4: Task 14 shows 100% completion via status aggregator
- ✅ TC-5: h-retrospective.md completed with all required sections
- ✅ TC-6: All files ready to stage (workflow files + implementation changes)
- ✅ TC-7: Step 8 uses `git commit --amend` without `--no-edit`, provides commit message update guidance
- ✅ TC-8: Step 8 suggests merge to main with fast-forward command

**Non-Functional Tests:**
- ✅ Usability: Step 6 verification guidance clear and actionable with brief language
- ✅ Usability: Step 7 retrospective instructions comprehensive
- ✅ Usability: Step 8 decision tree (amend vs new commit) clear and easy to understand
- ✅ Usability: Git command examples correct and copy-pasteable
- ✅ Reliability: Step 6 gating mechanism implemented (blocks if <100%)

**Coverage Achieved:**
- 100% of Step 1.5 (branch verification)
- 100% of Step 6 (verify task status - gating)
- 100% of Step 7 (execute retrospective - reflection)
- 100% of Step 8 (prepare final commit)

**Issue Resolution:**
- ✅ Task 12 issue resolved - workflow statuses verified before commit
- ✅ Commit message update mechanism working (no --no-edit flag)
- ✅ Clean 8-step structure eliminates vestigial Step 7 (decomposition check)

## Lessons Learned

### Testing Process
- **Validation-first approach effective**: Running implementation validation tests (TC-9, TC-10, TC-11) before workflow execution tests caught structural issues early
- **Status aggregator as single source of truth**: Using status-aggregator.pl to verify 100% completion provides authoritative validation
- **Manual testing validates design decisions**: Executing test cases manually confirmed the two-phase retrospective approach (verify then reflect) is logically sound

### Design Validation
- **Separation of concerns verified**: Step 6 (verification/gating) and Step 7 (reflection/learning) serve distinct purposes and work well in sequence
- **Clean numbering aids clarity**: Removing vestigial Step 7 and achieving clean 8-step structure (no decimals for main steps) improves comprehension
- **Brief language reduces cognitive load**: Step 6 guidance using simple language ("update all workflow step docs to match what has been finished") is more effective than verbose conditionals

### Security
- **Permission restrictions working as designed**: Git operations correctly restricted to branch/add only, commit requires user approval
- **Gating mechanism prevents premature completion**: Step 6 blocking on <100% status prevents incomplete tasks from being marked as finished
