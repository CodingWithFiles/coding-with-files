# Remove decomposition checks from non-planning workflow steps - Rollout
**Task**: 86 (hotfix)

## Task Reference
- **Task ID**: internal-86
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/86-remove-decomposition-checks-from-non-planning-workflo
- **Template Version**: 2.1

## Deployment Strategy

Documentation-only change. Rollout is a squash commit merged to main via fast-forward.

### Pre-Deployment Checklist
- [x] All 6 test cases pass
- [x] `cwf-manage validate` clean
- [x] Both SKILL.md files reviewed end-to-end

## Rollout Plan

Single step: squash task branch commits and merge to main.

```bash
checkpoints-branch-manager create
checkpoints-branch-manager show-history   # find base commit
git reset --soft <base>
git commit -m "Task 86: ..."
git checkout main && git merge --ff-only hotfix/86-...
```

## Rollback Plan

Revert both SKILL.md files to previous content via `git revert` or by restoring
from the checkpoints branch. No runtime impact — documentation only.

## Actual Results

Rollout deferred to retrospective step (squash + merge performed there).

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 86
**Blockers**: None
