# Add status update instruction to wf step skills before checkpoint commit - Rollout
**Task**: 83 (hotfix)

## Task Reference
- **Task ID**: internal-83
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/83-add-status-update-instruction-to-wf-step-skills-befor
- **Template Version**: 2.1

## Goal
Merge `checkpoint-commit.md` change to main so all future workflow step skills automatically include the status-update instruction.

## Deployment Strategy
### Release Type
- **Strategy**: Direct merge — documentation-only change, no runtime risk
- **Rationale**: Single markdown file edit; no code, no scripts, no hashes affected
- **Rollback Plan**: `git revert` the squash commit if the wording causes confusion

### Pre-Deployment Checklist
- [x] 3/3 TCs pass
- [x] `cwf-manage validate` passes (no script changes)
- [x] Change is additive — existing steps preserved, just renumbered

## Rollout Plan
### Phase 1: Merge to main
- Squash task branch → merge via `git branch -f main <squash-sha>`
- All future skill invocations will read the updated `checkpoint-commit.md`

### Monitoring
- Observe next task execution to confirm LLM follows the new step 1

## Rollback Plan
### Triggers
- New instruction causes unexpected LLM behaviour in subsequent tasks

### Procedure
1. `git revert <squash-sha>` on main
2. Push revert

## Success Criteria
- [x] `checkpoint-commit.md` updated with status-update step as step 1
- [x] All existing steps preserved and renumbered correctly
- [x] Ready to merge to main

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 83
**Blockers**: None

## Actual Results
Documentation-only deploy. No runtime concerns. Ready to merge.

## Lessons Learned
*To be captured during retrospective*

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
