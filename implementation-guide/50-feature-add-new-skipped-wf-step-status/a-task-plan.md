# add-new-skipped-wf-step-status - Plan
**Task**: 50 (feature)

## Task Reference
- **Task ID**: internal-50
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/50-add-new-skipped-wf-step-status
- **Template Version**: 2.1

## Goal
Add "Skipped" status for workflow phases that aren't applicable to specific tasks, excluding them from progress calculation and displaying as "N/A" for clarity.

## Success Criteria
- [ ] "Skipped" status added to `cig-project.json` status-values with null value (excluded from calculation)
- [ ] `status-aggregator` updated to exclude "Skipped" phases from progress denominator
- [ ] `--workflow` output displays "Skipped" phases as "Skipped (N/A)" not percentages
- [ ] Progress calculation accurate: 9/9 applicable phases = 100% (skipped phases don't penalize)
- [ ] Documentation updated explaining when to use "Skipped" status
- [ ] BACKLOG item "Clarify Maintenance Phase Applicability" resolved

## Original Estimate
**Effort**: 1-2 days (8-16 hours)
**Complexity**: Medium (touches core status aggregation system, needs comprehensive testing)
**Dependencies**: Understanding of status-aggregator architecture (v2.0 and v2.1 formats)

## Major Milestones
1. **Configuration Update**: Add "Skipped" status to `cig-project.json` with null value
2. **Status Aggregator Update**: Modify v2.0 and v2.1 status aggregators to exclude "Skipped" from calculation
3. **Display Format Update**: Change `--workflow` output to show "Skipped (N/A)" instead of percentage
4. **Documentation**: Update workflow-steps.md explaining when to use "Skipped"
5. **Testing & Validation**: Verify progress calculation with skipped phases, test all task types

## Risk Assessment
### High Priority Risks
- **Breaking existing progress calculations**: Changing status aggregator logic could break existing tasks
  - **Mitigation**: Comprehensive testing with existing tasks (v2.0 and v2.1), verify backward compatibility
- **Inconsistent display across tools**: Different tools might display "Skipped" differently
  - **Mitigation**: Document display format standard, update all tools that show status (cig-status, workflow-manager)

### Medium Priority Risks
- **User confusion about when to use "Skipped"**: Users might overuse or misuse the new status
  - **Mitigation**: Clear documentation with examples, guidance on maintenance phase specifically
- **Mixed v2.0/v2.1 format handling**: Status aggregators for both formats need consistent behavior
  - **Mitigation**: Update both v2.0 and v2.1 aggregators identically, test mixed-version projects

## Dependencies
- Understanding `status-aggregator-v2.0` and `status-aggregator-v2.1` architecture
- Access to `cig-project.json` configuration format
- Knowledge of `--workflow` output format in status display
- BACKLOG context: "Clarify Maintenance Phase Applicability" from Task 44

## Constraints
- Must maintain backward compatibility: existing tasks with Backlog/Finished statuses must still work
- Cannot break existing progress calculations for tasks in flight
- Must work consistently across v2.0 and v2.1 formats
- Display format must be clear for both LLM and human readers
- Null value in JSON must be handled correctly by Perl status aggregator

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **NO** - estimated 1-2 days
- [ ] **People**: Does this need >2 people working on different parts? **NO** - single developer task
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **YES** - config update, status aggregator logic, display format, documentation (4 concerns)
- [ ] **Risk**: Are there high-risk components that need isolation? **MAYBE** - status aggregator changes affect core system, but testing can mitigate
- [ ] **Independence**: Can parts be worked on separately? **NO** - config, aggregator, and display must work together

**Decomposition Decision**: No decomposition needed. While complexity signal triggers (4 concerns), they're tightly coupled and must be implemented together atomically. The changes are straightforward enough to handle in a single task with good testing. Breaking it apart would add coordination overhead without benefit.

## Status
**Status**: Finished
**Next Action**: /cig-retrospective 50
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
