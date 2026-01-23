# Update cig-status to Use --workflow Flag - Plan

## Task Reference
- **Task ID**: internal-26
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/26-update-cig-status-to-use-workflow-flag
- **Template Version**: 2.1

## Goal
Add `--workflow` flag to cig-status command to display detailed workflow phase breakdown for single-task queries.

## Success Criteria
- [ ] cig-status command updated to use `status-aggregator --workflow <task-path>` for single-task queries
- [ ] Workflow phase status displayed showing completion state of each phase (a-plan through j-retrospective)
- [ ] Both hierarchical tree view and detailed workflow breakdown shown for single-task queries
- [ ] Documentation updated with examples showing new --workflow output format
- [ ] Works correctly for both v2.0 (8-phase) and v2.1 (10-phase) tasks

## Original Estimate
**Effort**: 1 day
**Complexity**: Low
**Dependencies**: status-aggregator script already supports --workflow flag (implemented in Task 25)

## Major Milestones
1. **Command Updated**: cig-status.md modified to call status-aggregator with --workflow flag
2. **Output Format Verified**: Tested with both v2.0 and v2.1 tasks to confirm correct display
3. **Documentation Complete**: Examples added showing workflow phase breakdown

## Risk Assessment
### High Priority Risks
- **Backward compatibility**: Changes to cig-status output might break user expectations
  - **Mitigation**: Add workflow detail below existing tree view (additive change only), don't modify existing output format

### Medium Priority Risks
- **v2.0 vs v2.1 detection**: Workflow display must adapt to 8-phase vs 10-phase tasks
  - **Mitigation**: status-aggregator already handles version detection via WorkflowFiles::V20/V21 modules

## Dependencies
- status-aggregator script with --workflow flag support (COMPLETE - implemented in Task 25)
- Task 25 merged to main branch (for access to updated status-aggregator)

## Constraints
- Must maintain existing cig-status behavior (hierarchical tree view)
- Output must be readable in terminal (consider width constraints)
- Should work for both commands (current) and skills (future migration)

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **No** - estimated 1 day
- [ ] **People**: Does this need >2 people working on different parts? **No** - single developer task
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **No** - single concern: enhance cig-status output
- [ ] **Risk**: Are there high-risk components that need isolation? **No** - low risk, additive change
- [ ] **Independence**: Can parts be worked on separately? **No** - single cohesive change to one command file

**Decomposition Analysis**: 0/5 signals triggered

**Recommendation**: Task should proceed as single unit

**Decision**: No decomposition needed. This is a straightforward enhancement to a single command file.

## Status
**Status**: Finished
**Next Action**: Proceed to requirements phase with `/cig-requirements-plan 26`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
