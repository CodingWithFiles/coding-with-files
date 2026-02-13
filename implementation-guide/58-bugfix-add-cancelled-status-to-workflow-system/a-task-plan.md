# Add Cancelled status to workflow system - Plan
**Task**: 58 (bugfix)

## Task Reference
- **Task ID**: internal-58
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/58-add-cancelled-status-to-workflow-system
- **Template Version**: 2.1

## Goal
Add "Cancelled" as a terminal status value for tasks that are abandoned or superseded, so tasks like Task 11 (made moot by Task 57) can be properly marked rather than left in limbo.

## Success Criteria
- [ ] "Cancelled" added to `cig-project.json` status-values at 0%
- [ ] `.cig/docs/workflow/workflow-steps.md` updated with Cancelled documentation
- [ ] Task 11 workflow files updated to Cancelled status with explanation
- [ ] `workflow-manager status` correctly reports Cancelled tasks (0%)

## Original Estimate
**Effort**: <1 hour
**Complexity**: Low
**Dependencies**: None

## Major Milestones
1. **Config + docs**: Add status value and document it
2. **Apply**: Update Task 11 to Cancelled
3. **Verify**: Confirm status-aggregator handles it correctly

## Risk Assessment
### Low Priority Risks
- **Status-aggregator doesn't handle unknown values**: If the aggregator encounters "Cancelled" without config support, it may default to 0% or warn
  - **Mitigation**: The aggregator reads from cig-project.json, so adding the value there should be sufficient. Test to confirm.

## Dependencies
- Task 57 complete (superseded Task 11's blocker)

## Constraints
- Must work with both v2.0 and v2.1 format tasks (Task 11 is v2.0)
- "Cancelled" at 0% — a cancelled task hasn't achieved its goals

## Decomposition Check
- [ ] **Time**: >1 week? **No** — under 1 hour
- [ ] **People**: >2 people? **No**
- [ ] **Complexity**: 3+ concerns? **No** — config, docs, apply
- [ ] **Risk**: High-risk components? **No**
- [ ] **Independence**: Parts separable? **No** — tightly coupled

**Decision**: No decomposition needed (0 signals triggered).

## Status
**Status**: Finished
**Next Action**: /cig-design-plan 58
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
