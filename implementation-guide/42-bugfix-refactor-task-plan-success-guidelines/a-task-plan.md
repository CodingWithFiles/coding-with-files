# Refactor task plan success guidelines - Plan

## Task Reference
- **Task ID**: internal-42
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/42-refactor-task-plan-success-guidelines
- **Template Version**: 2.1

## Goal
Add simplicity principles to planning phase guidance to prevent scope gaps that miss cleanup work

## Success Criteria
- [ ] Planning phase includes "The best part is no part" principle with explanation
- [ ] Planning phase includes "Reduce, reuse, recycle" principle with explanation
- [ ] Guidance explicitly prompts: "What can be removed? What becomes obsolete?"
- [ ] Updated guidance prevents future Tasks 39/40/41-style failures (tested with retrospective review)
- [ ] Changes integrated into `.cig/docs/workflow/workflow-steps.md`

## Original Estimate
**Effort**: 2 hours
**Complexity**: Low
**Dependencies**: Understanding of Tasks 39/40/41 failures, access to workflow-steps.md

## Major Milestones
1. **Analyze Root Cause**: Document how Tasks 39/40/41 planning failed to identify cleanup work
2. **Draft Guidance**: Add simplicity principles to planning phase section
3. **Validate**: Verify updated guidance would have caught the missed cleanup work

## Risk Assessment
### High Priority Risks
- **Adding complexity instead of simplicity**: New guidance could become a long checklist that obscures the core principle
  - **Mitigation**: Keep it minimal - 2 principles, 3 questions max. Quote attribution only.

### Medium Priority Risks
- **Misinterpreting the principle**: Could be read as "always remove things" rather than "value simplicity"
  - **Mitigation**: Clarify the context: simplicity is the goal, removal is one tool to achieve it
- **Backward compatibility**: Existing tasks might not follow new guidance
  - **Mitigation**: This is guidance, not enforcement. Existing tasks grandfathered in.

## Dependencies
- Tasks 39/40/41 retrospectives (to understand failure pattern)
- `.cig/docs/workflow/workflow-steps.md` (file to be updated)
- No external dependencies

## Constraints
- Must not add complexity to the planning phase
- Must preserve existing workflow structure
- Should be concise (3-5 sentences max for new guidance)
- Principles should be universally applicable, not specific to code cleanup

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **No** - Estimated 2 hours
- [ ] **People**: Does this need >2 people working on different parts? **No** - Single developer
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **No** - Just updating planning guidance
- [ ] **Risk**: Are there high-risk components that need isolation? **No** - Low risk documentation change
- [ ] **Independence**: Can parts be worked on separately? **No** - Cohesive single change

**Decision**: No decomposition needed (0 signals triggered)

## Status
**Status**: Finished
**Next Action**: Planning complete, moved through all phases
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
