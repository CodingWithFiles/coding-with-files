# Ensure retrospective checkpoint commit stages entire task directory - Rollout
**Task**: 85 (hotfix)

## Task Reference
- **Task ID**: internal-85
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/85-ensure-retrospective-checkpoint-commit-stages-entire-ta
- **Template Version**: 2.1

## Deployment Strategy

Documentation-only change. Rollout is a squash commit merged to main via fast-forward.

### Pre-Deployment Checklist
- [x] All 6 test cases pass
- [x] `cwf-manage validate` clean
- [x] `retrospective-extras.md` reviewed end-to-end

## Rollout Plan

Single step: squash task branch commits and merge to main.

```bash
checkpoints-branch-manager create
checkpoints-branch-manager show-history   # find base commit
git reset --soft <base>
git commit -m "Task 85: ..."
git checkout main && git merge --ff-only hotfix/85-...
```

## Rollback Plan

Revert `retrospective-extras.md` to the previous content via `git revert` or by
restoring from the checkpoints branch. No runtime impact — documentation only.

## Actual Results

Rollout deferred to retrospective step (squash + merge performed there).

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 85
**Blockers**: None
