# add checkpoint commit instruction to end of all wf steps - Plan
**Task**: 46 (hotfix)

## Task Reference
- **Task ID**: internal-46
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/46-add-checkpoint-commit-instruction-to-end-of-all-wf-steps
- **Template Version**: 2.1

## Goal
Add checkpoint commit instructions to all 7 workflow step commands so agents create commits after completing each phase

## Success Criteria
- [ ] All 7 workflow commands (cig-task-plan, cig-design-plan, cig-implementation-plan, cig-testing-plan, cig-implementation-exec, cig-testing-exec, cig-rollout) include checkpoint commit instructions
- [ ] Checkpoint instructions reference workflow-steps.md documentation for commit message format
- [ ] Git commit commands added to frontmatter allowed-tools (if not already present)
- [ ] Instructions clearly state this is Step 9 or final step before "Suggest Next Steps"

## Original Estimate
**Effort**: 1-2 hours
**Complexity**: Low (documentation update across 7 files)
**Dependencies**: Task 45 complete (understanding of retrospective checkpoint squashing workflow)

## Major Milestones
1. **Audit Phase**: Identify which commands are missing checkpoint instructions and what frontmatter permissions are needed
2. **Implementation Phase**: Add consistent checkpoint commit step to all 7 workflow commands
3. **Validation Phase**: Verify instructions are clear and frontmatter permissions allow git commit

## Risk Assessment
### High Priority Risks
- **Inconsistent Instructions**: Adding checkpoint instructions differently across commands creates confusion
  - **Mitigation**: Use consistent template/format for all 7 commands, reference workflow-steps.md for canonical commit message format

### Medium Priority Risks
- **Frontmatter Permission Gaps**: Git commit commands might trigger permission prompts if not in allowed-tools
  - **Mitigation**: Audit frontmatter for each command, add Bash(git add:*) and Bash(git commit:*) if missing

- **Unclear Timing**: Instructions might not clearly indicate WHEN to make checkpoint commit (before or after suggesting next steps)
  - **Mitigation**: Number the checkpoint step explicitly (e.g., "Step 9") and place before "Suggest Next Steps" section

## Dependencies
- Task 45 retrospective workflow understanding (checkpoint branch → squash pattern)
- workflow-steps.md documentation (defines checkpoint commit format)
- Git branching conventions (all workflow commands assume task branch exists)

## Constraints
- Must preserve existing step numbering/ordering in commands
- Must not break existing frontmatter permission patterns
- Must reference workflow-steps.md rather than duplicating commit message format
- Commands are executed by LLM agents, so instructions must be unambiguous

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [x] **Time**: Will this take >1 week? **No** - estimated 1-2 hours
- [x] **People**: Does this need >2 people working on different parts? **No** - single agent can update all 7 files
- [x] **Complexity**: Does this involve 3+ distinct concerns? **No** - single concern (add checkpoint commit instructions)
- [x] **Risk**: Are there high-risk components that need isolation? **No** - low-risk documentation changes
- [x] **Independence**: Can parts be worked on separately? **No** - all commands need consistent format, better done atomically

**Decomposition Decision**: Not needed - straightforward hotfix to add missing instructions across 7 command files with consistent format

## Status
**Status**: Finished
**Next Action**: Move to implementation planning → `/cig-implementation-plan 46`
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
