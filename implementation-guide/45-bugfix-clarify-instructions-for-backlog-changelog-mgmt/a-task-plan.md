# clarify instructions for backlog changelog mgmt - Plan
**Task**: 45 (bugfix)

## Task Reference
- **Task ID**: internal-45
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/45-clarify-instructions-for-backlog-changelog-mgmt
- **Template Version**: 2.1

## Goal
Fix retrospective workflow instructions to clearly document when and how to update BACKLOG.md and CHANGELOG.md

## Success Criteria
- [ ] Retrospective instructions explicitly state when to update CHANGELOG.md (what phase/step)
- [ ] BACKLOG.md cleanup instructions clarify what "mark items complete" means (move to CHANGELOG vs delete vs status update)
- [ ] Instructions prevent LLM from skipping BACKLOG/CHANGELOG updates during retrospective
- [ ] Example showing completed BACKLOG item being moved to CHANGELOG included

## Original Estimate
**Effort**: 1-2 hours
**Complexity**: Low (documentation fix)
**Dependencies**: Task 44 retrospective completion (identified the issue)

## Major Milestones
1. **Identify Gaps**: Review current retrospective instructions and identify what's missing or unclear
2. **Design Fix**: Determine correct workflow for BACKLOG/CHANGELOG updates
3. **Update Instructions**: Modify cig-retrospective.md with clear, unambiguous guidance
4. **Validate**: Test that instructions prevent future skipped updates

## Risk Assessment
### High Priority Risks
- **Incorrect Workflow**: Documenting the wrong workflow could institutionalize bad practices
  - **Mitigation**: Confirm correct workflow with user before documenting, review existing tasks (40, 43, 44) to see what patterns work

### Medium Priority Risks
- **Instructions Still Ambiguous**: New instructions might still be unclear and LLM continues skipping updates
  - **Mitigation**: Use explicit step numbers, clear examples, and test with actual retrospective execution

## Dependencies
- User clarification on correct BACKLOG/CHANGELOG workflow
- Review of CHANGELOG.md format to understand expected structure
- Review of past task retrospectives (40, 43, 44) to see actual patterns

## Constraints
- Must work within existing retrospective workflow phase structure
- Instructions must be clear enough that LLM follows them reliably
- Cannot require manual intervention or external tools
- Must preserve backward compatibility with existing tasks

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **No** - estimated 1-2 hours
- [ ] **People**: Does this need >2 people working on different parts? **No** - single documentation update
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **No** - single retrospective instruction fix
- [ ] **Risk**: Are there high-risk components that need isolation? **No** - low risk documentation change
- [ ] **Independence**: Can parts be worked on separately? **No** - cohesive instruction update

**Decomposition Decision**: Not needed - simple, focused bugfix with low complexity and minimal time requirement

## Status
**Status**: Finished
**Next Action**: Task complete, ready for retrospective
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
