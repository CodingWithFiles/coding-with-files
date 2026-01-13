# retrospective: suggest updating workflow docs and commit - Plan

## Task Reference
- **Task ID**: internal-14
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/14-retrospective-suggest-updating-workflow-and-commit
- **Template Version**: 2.0

## Goal
Update cig-retrospective workflow command to suggest updating completed workflow document statuses and amending checkpoint commit before proceeding to final commit.

## Success Criteria
- [ ] cig-retrospective command guides user to update all workflow file statuses to "Finished"
- [ ] cig-retrospective suggests amending checkpoint commit with retrospective + status updates
- [ ] Workflow pattern documented: retrospective → update statuses → amend commit → merge
- [ ] Changes tested with task 12 as example
- [ ] Documentation clear and actionable

## Original Estimate
**Effort**: 2-3 hours
**Complexity**: Low-Medium
**Dependencies**:
- Understanding of existing cig-retrospective command structure
- Task 12 retrospective as reference example
- Git workflow for amending commits

## Major Milestones
1. **Analyze current gap**: Review task 12 retrospective workflow and identify where status updates were missed
2. **Design workflow enhancement**: Define where and how to inject status update guidance in cig-retrospective
3. **Update cig-retrospective command**: Add step guidance for updating workflow statuses and amending commit
4. **Test with example**: Validate workflow makes sense with task 12 as test case

## Risk Assessment
### High Priority Risks
- **Complexity creep**: Adding too many steps might make retrospective workflow confusing
  - **Mitigation**: Keep guidance simple and actionable, use clear step-by-step format

### Medium Priority Risks
- **Workflow confusion**: Users might not understand when to amend vs create new commit
  - **Mitigation**: Provide clear decision tree: checkpoint commit exists → amend, otherwise → new commit
- **Status aggregator dependency**: Assumes status-aggregator.pl is the validation tool
  - **Mitigation**: Document that users can verify with `/cig-status <task>` command

## Dependencies
- Existing cig-retrospective.md command file structure
- Understanding of recommended workflow pattern from task 13 design
- Git amend workflow for updating commits

## Constraints
- Must not break existing retrospective workflow for users who don't use checkpoint commits
- Should be opt-in guidance, not mandatory steps
- Must work within allowed-tools constraints for cig-retrospective command

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **No** - Estimated 2-3 hours
- [ ] **People**: Does this need >2 people working on different parts? **No** - Single developer task
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **No** - Single concern: enhance retrospective workflow guidance
- [ ] **Risk**: Are there high-risk components that need isolation? **No** - Low risk, documentation change
- [ ] **Independence**: Can parts be worked on separately? **No** - Cohesive workflow enhancement

**Decomposition Decision**: No decomposition needed. This is a straightforward enhancement to add workflow guidance to cig-retrospective command.

## Status
**Status**: Finished
**Next Action**: Planning complete - move to design phase
**Blockers**: None identified

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
