# Improve CWF skill initialisation in cwf-init - Rollout
**Task**: 70 (feature)

## Task Reference
- **Task ID**: internal-70
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/70-improve-cwf-skill-initialisation-in-cwf-init
- **Template Version**: 2.1

## Goal
Merge task 70 to main. Rollout is a standard branch merge — no staged deployment needed.

## Deployment Strategy

### Release Type
- **Strategy**: Direct merge to main
- **Rationale**: Single file change to a skill instruction. No running services, no data migration, no user impact beyond future `cwf-init` runs. Rollback is a single `git revert`.
- **Rollback Plan**: `git revert <squash-commit-sha>` on main

### Pre-Deployment Checklist
- [x] All tests passing — 9/9 PASS (g-testing-exec.md)
- [x] `cwf-manage validate` exits 0
- [x] Single file change — no migration, no breaking changes to existing projects
- [x] Existing `cwf-init` invocations on already-initialised projects: idempotency checks prevent duplication
- [ ] Squash checkpoint commits → single commit on task branch
- [ ] Merge task branch to main

## Rollout Plan

### Phase 1: Squash and Merge
- Squash all checkpoint commits on `feature/70-improve-cwf-skill-initialisation-in-cwf-init` into one
- Merge to `main`

### Phase 2: Done
- No monitoring period needed — change takes effect the next time `cwf-init` is invoked on a fresh project
- Existing projects are unaffected

## Rollback Plan

### Triggers
- `cwf-init` step 4 or step 6 behaves unexpectedly on a fresh project

### Procedure
1. `git revert <squash-commit-sha>` on main
2. Re-examine the failing step and file a new bugfix task

## Success Criteria
- [x] 9/9 tests pass
- [ ] Squash commit created
- [ ] Merged to main

## Status
**Status**: Finished
**Next Action**: /cwf-maintenance 70
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon merge*

## Lessons Learned
*To be captured during retrospective*
