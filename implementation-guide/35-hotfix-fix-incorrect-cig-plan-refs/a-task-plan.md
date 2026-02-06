# fix-incorrect-cig-plan-refs - Plan

## Task Reference
- **Task ID**: internal-35
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/35-fix-incorrect-cig-plan-refs
- **Template Version**: 2.1

## Goal
Fix 2 incorrect `/cig-plan` references in command files to reference `/cig-task-plan` instead.

## Success Criteria
- [ ] `.claude/commands/cig-new-task.md:98` updated to reference `/cig-task-plan`
- [ ] `.claude/commands/cig-subtask.md:74` updated to reference `/cig-task-plan`
- [ ] Historical references in implementation guides remain unchanged

## Original Estimate
**Effort**: 15 minutes
**Complexity**: Low
**Dependencies**: None

## Major Milestones
1. **Locate References**: Identify the 2 incorrect references
2. **Fix References**: Update both command files
3. **Verify**: Confirm no other non-historical references exist

## Risk Assessment
### Low Priority Risks
- **Risk: Breaking historical documentation**: Accidentally changing historical references in implementation guides
  - **Mitigation**: Only update `.claude/commands/` files, explicitly preserve implementation guide references

## Dependencies
None - simple text replacement in 2 files

## Constraints
- Must preserve historical references in `implementation-guide/` directory
- Only update active command definition files in `.claude/commands/`

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **No** - 15 minutes
- [ ] **People**: Does this need >2 people working on different parts? **No** - single developer
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **No** - simple text replacement
- [ ] **Risk**: Are there high-risk components that need isolation? **No** - low risk
- [ ] **Independence**: Can parts be worked on separately? **No** - two related edits

**Analysis**: 0/5 signals triggered. This is a simple hotfix that should remain as a single task.

## Status
**Status**: Finished
**Next Action**: Proceed directly to implementation → `/cig-implementation-plan 35` (hotfix skips requirements/design)
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
