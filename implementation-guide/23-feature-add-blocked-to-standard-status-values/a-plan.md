# Add "Blocked" to Standard Status Values - Plan

## Task Reference
- **Task ID**: internal-23
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/23-add-blocked-to-standard-status-values
- **Template Version**: 2.0

## Goal
Add "Blocked" as a standard status value to the CIG workflow system to better represent tasks stopped due to dependencies or external blockers.

## Success Criteria
- [ ] "Blocked" status added to valid status values in `.cig/docs/workflow/workflow-steps.md`
- [ ] `status-aggregator.pl` updated to handle "Blocked" status with appropriate completion percentage
- [ ] All 8 workflow command files updated to reference "Blocked" as valid status
- [ ] Workflow templates updated with guidance on when to use "Blocked" status
- [ ] Documentation clearly defines "Blocked" semantics (work started but cannot proceed)

## Original Estimate
**Effort**: 2-3 hours
**Complexity**: Low-Medium
**Dependencies**: Understanding current status aggregator logic, workflow documentation structure

## Major Milestones
1. **Define Semantics**: Establish clear definition of "Blocked" status and completion percentage
2. **Update Core Documentation**: Add "Blocked" to workflow-steps.md status values section
3. **Update Scripts**: Modify status-aggregator.pl to handle "Blocked" status
4. **Update Commands**: Update all 8 workflow command files with "Blocked" reference
5. **Update Templates**: Add guidance to workflow templates on when to use "Blocked"

## Risk Assessment
### High Priority Risks
- **Breaking Changes to Status Aggregator**: Modifying status-aggregator.pl could break existing percentage calculations
  - **Mitigation**: Review existing logic carefully, maintain backward compatibility, test with existing tasks

### Medium Priority Risks
- **Inconsistent Status Semantics**: "Blocked" might overlap with "Backlog" or "In Progress" causing confusion
  - **Mitigation**: Define clear semantics - "Blocked" means work started but stopped by external factors
- **Template Update Consistency**: Missing updates in some workflow files could cause inconsistency
  - **Mitigation**: Create checklist of all 8 workflow command files to ensure complete coverage

## Dependencies
- Current status values documented in `.cig/docs/workflow/workflow-steps.md`
- Status aggregator implementation in `.cig/scripts/command-helpers/status-aggregator.pl`
- All 8 workflow command files for consistent updates

## Constraints
- Must maintain backward compatibility with existing tasks using current status values
- Status percentage must fit within existing 0-100% range
- Documentation updates must follow existing format and style

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **No** - estimated 2-3 hours
- [ ] **People**: Does this need >2 people working on different parts? **No** - single developer task
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **No** - focused on adding one status value
- [ ] **Risk**: Are there high-risk components that need isolation? **No** - low-medium risk
- [ ] **Independence**: Can parts be worked on separately? **No** - tightly coupled changes

**Result**: 0/5 signals triggered - no decomposition needed

## Status
**Status**: Finished
**Next Action**: Proceed to requirements phase with `/cig-requirements 23`
**Blockers**: None identified

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
