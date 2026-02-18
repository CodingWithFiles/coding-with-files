# Fix stale statuses in tasks 46 and 49 - Plan
**Task**: 67 (chore)

## Task Reference
- **Task ID**: internal-67
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/67-fix-stale-statuses-in-tasks-46-and-49
- **Template Version**: 2.1

## Goal
Update stale workflow file statuses in tasks 46 and 49 so that status-aggregator reports both at 100% and task-context-inference no longer treats them as active.

## Background
Same pattern as task 65 (fixed 47 and 48). Retrospectives completed but intermediate files left stale:
- **Task 46**: `f-implementation-exec.md` and `g-testing-exec.md` stuck at `Backlog`
- **Task 49**: `a`, `c`, `d`, `e` stuck at `In Progress`; `f` stuck at `Implemented`

Total: 7 status field edits.

## Success Criteria
- [ ] Task 46 shows 100% in status-aggregator
- [ ] Task 49 shows 100% in status-aggregator
- [ ] `task-context-inference` no longer lists 46 or 49 as candidates
- [ ] `cwf-manage validate` exits 0

## Original Estimate
**Effort**: Trivial (<1 session)
**Complexity**: Low
**Dependencies**: None

## Major Milestones
1. Update 7 status fields across tasks 46 and 49
2. Verify both tasks at 100%

## Risk Assessment
### Low Priority Risks
- **Wrong line numbers**: Status fields may have moved since last read
  - **Mitigation**: Grep for exact `**Status**:` pattern before editing

## Dependencies
- None

## Constraints
- Status field edits only — no logic changes

## Decomposition Check
- [ ] **Time**: >1 week? — No
- [ ] **People**: >2 people? — No
- [ ] **Complexity**: 3+ distinct concerns? — No
- [ ] **Risk**: High-risk components? — No
- [ ] **Independence**: Parts separable? — No

No decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 67
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during retrospective*
