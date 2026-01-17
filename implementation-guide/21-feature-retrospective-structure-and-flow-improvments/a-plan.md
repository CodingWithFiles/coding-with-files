# retrospective-structure-and-flow-improvments - Plan

## Task Reference
- **Task ID**: internal-21
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/21-retrospective-structure-and-flow-improvments
- **Template Version**: 2.0

## Goal
Improve retrospective workflow step structure and completeness by renumbering steps sequentially, adding BACKLOG.md synchronization, and providing commit message guidance.

## Success Criteria
- [ ] All steps in cig-retrospective.md renumbered sequentially (no fractional steps like 1.5, 7.5)
- [ ] BACKLOG.md update step added to workflow (mark completed items, add new items from retrospective)
- [ ] Commit message guidelines added to final commit step (brief, prefer "why" over "what")
- [ ] Documentation updated to reflect new step numbers in all references
- [ ] Workflow tested with example task to verify completeness

## Original Estimate
**Effort**: 2-3 hours
**Complexity**: Low - primarily documentation updates with clear requirements
**Dependencies**: None - self-contained documentation improvement

## Major Milestones
1. **Step renumbering complete**: All steps numbered 1-9 sequentially without fractional numbers
2. **BACKLOG.md integration added**: New step for synchronizing BACKLOG.md with task completion and retrospective findings
3. **Commit guidance documented**: Clear instructions for writing meaningful commit messages in final step

## Risk Assessment
### High Priority Risks
None - low-risk documentation improvement task

### Medium Priority Risks
- **Step reference inconsistency**: Changing step numbers could break references in other documentation or user habits
  - **Mitigation**: Search codebase for references to "Step 1.5" or "Step 7.5" and update all references
- **BACKLOG.md workflow unclear**: Users might not understand when/how to update BACKLOG.md
  - **Mitigation**: Provide clear examples in documentation with both scenarios (completing items, adding items)

## Dependencies
- Task 20 should be merged to main first (contains BACKLOG.md with item we'll reference in testing)
- No external tool dependencies - only documentation changes

## Planning Constraints
- Must maintain backward compatibility with existing tasks (old tasks won't have BACKLOG.md updates, that's fine)
- Step numbering change is breaking for user habits but necessary for clarity
- Must preserve all existing functionality while improving structure

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **No** - estimated 2-3 hours
- [ ] **People**: Does this need >2 people working on different parts? **No** - single documentation file update
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **No** - three related improvements to same file (renumber, add step, enhance step)
- [ ] **Risk**: Are there high-risk components that need isolation? **No** - low-risk documentation changes
- [ ] **Independence**: Can parts be worked on separately? **No** - all changes to same workflow file, better done atomically

**Decomposition Decision**: No subtasks needed - simple, focused documentation improvement

## Status
**Status**: Finished
**Next Action**: Proceed to requirements
**Blockers**: None identified

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
