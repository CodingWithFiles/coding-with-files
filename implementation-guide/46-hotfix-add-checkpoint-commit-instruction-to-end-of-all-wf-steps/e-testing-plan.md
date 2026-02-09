# add checkpoint commit instruction to end of all wf steps - Testing Plan
**Task**: 46 (hotfix)

## Task Reference
- **Task ID**: internal-46
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/46-add-checkpoint-commit-instruction-to-end-of-all-wf-steps
- **Template Version**: 2.1

## Goal
Define test strategy and validation approach for add checkpoint commit instruction to end of all wf steps.

## Test Strategy
### Test Levels
- **Manual Validation**: Verify documentation content is correct, clear, and complete across all 7 files
- **Integration Tests**: Test that checkpoint commit instructions work in actual workflow execution (will validate naturally in Task 46 execution)
- **Regression Tests**: Verify existing command structure and step numbering not broken

### Test Coverage Targets
- **Overall Coverage**: All 7 workflow commands must have checkpoint commit step
- **Critical Paths**: Frontmatter permissions (git add, git commit), Step 9 placement, workflow-steps.md reference
- **Edge Cases**: Step renumbering (Suggest Next Steps becomes Step 10), consistent format across commands
- **Regression**: Existing steps (1-8) remain unchanged, no permission conflicts

## Test Cases
### Functional Test Cases
- **TC-1**: Verify all 7 commands have checkpoint commit step
  - **Given**: Modified command files
  - **When**: Reading each command file
  - **Then**: Each file has new Step 9 "Create Checkpoint Commit" before "Suggest Next Steps"

- **TC-2**: Verify frontmatter permissions updated
  - **Given**: Modified command files
  - **When**: Reading frontmatter allowed-tools
  - **Then**: All files include `Bash(git add:*)` and `Bash(git commit:*)` in allowed-tools

- **TC-3**: Verify checkpoint step references workflow-steps.md
  - **Given**: Step 9 content in each command
  - **When**: Reading checkpoint instructions
  - **Then**: Instructions reference `.cig/docs/workflow/workflow-steps.md#<phase>` for canonical format

- **TC-4**: Verify step renumbering consistency
  - **Given**: Modified command files
  - **When**: Checking step numbers after adding Step 9
  - **Then**: "Suggest Next Steps" renumbered to Step 10 in all 7 files

- **TC-5**: Verify checkpoint commit template correctness
  - **Given**: Step 9 content in each command
  - **When**: Reading git commit command template
  - **Then**: Template includes: git add <file>, git commit with message format, Co-developed-by trailer, rationale

- **TC-6**: Verify phase-specific file paths
  - **Given**: Step 9 content in each command
  - **When**: Reading git add command
  - **Then**: Each command references correct workflow file (a-task-plan.md, c-design-plan.md, etc.)

- **TC-7**: Integration test - Execute workflow with checkpoint commits
  - **Given**: Task 46 implementation complete
  - **When**: Following workflow phases (planning → impl-plan → testing-plan → impl-exec → testing-exec → rollout)
  - **Then**: Checkpoint commit created after each phase, checkpoints branch has all commits, squashing works

### Non-Functional Test Cases
- **Clarity Tests**: Instructions clear enough that agents will execute checkpoint commits without confusion
- **Consistency Tests**: All 7 commands use identical Step 9 structure (only file paths differ)
- **Regression Tests**: Existing steps (1-8) unchanged, no frontmatter conflicts
- **Usability Tests**: Rationale explains "why" (retrospective squashing workflow)

## Test Environment
### Setup Requirements
- Working git repository with CIG system installed
- All 7 workflow command files in `.claude/commands/` directory
- Task 46 branch checked out
- workflow-steps.md documentation present for reference validation

### Automation
- Manual validation: Read each modified file to verify structure
- Integration test: Execute Task 46 workflow phases and verify checkpoint commits created
- Validation: Use `git log` to confirm checkpoint commits exist, use `git branch` to verify checkpoints branch created

## Validation Criteria
- [ ] TC-1: All 7 commands have Step 9 checkpoint commit
- [ ] TC-2: Frontmatter includes git add and git commit permissions
- [ ] TC-3: Step 9 references workflow-steps.md for format
- [ ] TC-4: "Suggest Next Steps" renumbered to Step 10 consistently
- [ ] TC-5: Checkpoint commit template complete (add, commit, message, Co-developed-by, rationale)
- [ ] TC-6: Phase-specific file paths correct (a-task-plan.md, c-design-plan.md, etc.)
- [ ] TC-7: Integration test successful (checkpoint commits created during Task 46 execution)
- [ ] Clarity: Instructions unambiguous
- [ ] Consistency: Identical Step 9 structure across all commands
- [ ] Regression: Existing steps unchanged

## Status
**Status**: Finished
**Next Action**: Move to implementation execution → `/cig-implementation-exec 46`
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
