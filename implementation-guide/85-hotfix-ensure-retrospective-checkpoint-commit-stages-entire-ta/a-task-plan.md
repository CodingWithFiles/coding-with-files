# Ensure retrospective checkpoint commit stages entire task directory - Plan
**Task**: 85 (hotfix)

## Task Reference
- **Task ID**: internal-85
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/85-ensure-retrospective-checkpoint-commit-stages-entire-ta
- **Template Version**: 2.1

## Goal
Add an explicit `git add <task-dir>/` step to the retrospective checkpoint commit
procedure so that status corrections made during Step 7 are always included in
the retrospective commit, preventing stale statuses from persisting in the squash.

## Success Criteria
- [ ] `checkpoint-commit.md` or `retrospective-extras.md` contains an explicit `git add <task-dir>/` step as part of the retrospective commit procedure
- [ ] The step is positioned correctly — after status verification (Step 7), before the commit
- [ ] `cwf-manage validate` passes
- [ ] `/cwf-status 85` reports 100%

## Original Estimate
**Effort**: <1 hour
**Complexity**: Low
**Dependencies**: None

## Major Milestones
1. **Identify correct file**: Determine whether the fix belongs in `checkpoint-commit.md` (generic) or `retrospective-extras.md` (retrospective-specific)
2. **Edit**: Add the staging step in the right place
3. **Validate and commit**

## Risk Assessment
### Medium Priority Risks
- **Wrong file or location**: Putting the instruction in the wrong doc reduces discoverability
  - **Mitigation**: The step is retrospective-specific (other phases stage only their own file), so it belongs in `retrospective-extras.md`, not `checkpoint-commit.md`

## Dependencies
- None

## Constraints
- Do not change the generic `checkpoint-commit.md` procedure — it is correct for all non-retrospective phases

## Decomposition Check
- [x] **Time**: No — <1 hour
- [x] **People**: No — single file edit
- [x] **Complexity**: No — one targeted change
- [x] **Risk**: No — low risk doc edit
- [x] **Independence**: N/A

No decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 85
**Blockers**: None identified

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
