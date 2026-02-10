# fix-checkpoints-branch-perms-issue-with-script - Plan
**Task**: 49 (bugfix)

## Task Reference
- **Task ID**: internal-49
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/49-fix-checkpoints-branch-perms-issue-with-script
- **Template Version**: 2.1

## Goal
Create `checkpoints-branch-manager` script to eliminate permission prompts in retrospective Step 10 by handling compound git commands deterministically.

## Success Criteria
- [ ] Script handles creating checkpoints branch without permission prompts
- [ ] Script shows commit history for identifying base commit
- [ ] Script verifies checkpoints branch preservation
- [ ] All Step 10 commands execute without triggering permission system
- [ ] `.claude/commands/cig-retrospective.md` frontmatter updated to allow script

## Original Estimate
**Effort**: 0.5 days (4 hours)
**Complexity**: Low
**Dependencies**: None (standalone script using existing git commands)

## Major Milestones
1. **Script Creation**: Create `.cig/scripts/command-helpers/checkpoints-branch-manager` with three subcommands
2. **Permission Update**: Update `cig-retrospective.md` frontmatter to allow script execution
3. **Step 10 Refactor**: Update Step 10 instructions to use script instead of direct git commands
4. **Validation**: Verify all Step 10 operations execute without permission prompts

## Risk Assessment
### High Priority Risks
- **Script name inconsistency**: Using "checkpoint" (singular) instead of "checkpoints" (plural)
  - **Mitigation**: Use "checkpoints-branch-manager" to match actual branch naming convention

### Medium Priority Risks
- **Breaking existing workflows**: Changing Step 10 instructions might confuse users mid-task
  - **Mitigation**: Script is additive, old approach still works if users prefer direct git commands
- **Script doesn't handle edge cases**: Empty repository, detached HEAD, missing branches
  - **Mitigation**: Add error handling and clear messages for edge cases

## Dependencies
- Existing `.claude/commands/cig-retrospective.md` frontmatter system
- Git repository context (must be in valid git repo)
- Bash environment with standard git commands

## Constraints
- Script must follow CIG security model (u+rx permissions, SHA256 verification)
- Must maintain backward compatibility with existing Step 10 workflow
- Cannot change frontmatter permission system (work within existing constraints)
- Must preserve checkpoint commit workflow pattern

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **NO** - estimated 0.5 days
- [ ] **People**: Does this need >2 people working on different parts? **NO** - single developer task
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **NO** - single concern (permission handling)
- [ ] **Risk**: Are there high-risk components that need isolation? **NO** - low risk script creation
- [ ] **Independence**: Can parts be worked on separately? **NO** - script, frontmatter, and instructions are tightly coupled

**Decomposition Decision**: No decomposition needed. All signals indicate this is a focused, single-developer task.

## Status
**Status**: In Progress
**Next Action**: /cig-design-plan
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
