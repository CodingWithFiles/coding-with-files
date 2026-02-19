# Add missing checkpoint commit instructions to cwf-requirements-plan and cwf-maintenance - Rollout
**Task**: 71 (hotfix)

## Task Reference
- **Task ID**: internal-71
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/71-fix-checkpoint-steps
- **Template Version**: 2.1

## Goal
Merge task 71 to main. Two skill instruction files changed — no staged deployment needed.

## Deployment Strategy

### Release Type
- **Strategy**: Direct merge to main
- **Rationale**: Two skill instruction files, no runtime services, no data migration. Rollback is a single `git revert`.
- **Rollback Plan**: `git revert <squash-commit-sha>` on main

### Pre-Deployment Checklist
- [x] 6/6 tests pass
- [x] `cwf-manage validate` exits 0
- [x] No breaking changes — adds a step, doesn't remove or rename anything
- [ ] Squash checkpoint commits → single commit on task branch
- [ ] Merge to main

## Rollout Plan

### Phase 1: Squash and Merge
Squash all checkpoint commits, merge to main. Takes effect immediately on next `cwf-requirements-plan` or `cwf-maintenance` skill invocation.

## Rollback Plan

### Triggers
- `cwf-requirements-plan` or `cwf-maintenance` behaves unexpectedly after the change

### Procedure
1. `git revert <squash-commit-sha>` on main

## Success Criteria
- [x] 6/6 tests pass
- [ ] Squash commit created
- [ ] Merged to main

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 71
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon merge*

## Lessons Learned
*To be captured during retrospective*
