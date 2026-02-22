# Remove decomposition checks from non-planning workflow steps - Plan
**Task**: 86 (hotfix)

## Task Reference
- **Task ID**: internal-86
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/86-remove-decomposition-checks-from-non-planning-workflo
- **Template Version**: 2.1

## Goal
Remove "Step 7: Check decomposition signals" from `cwf-rollout` and `cwf-maintenance`
skill files, where it adds cognitive load without being actionable.

## Success Criteria
- [ ] Step 7 decomposition check removed from `cwf-rollout/SKILL.md`
- [ ] Step 7 decomposition check removed from `cwf-maintenance/SKILL.md`
- [ ] Remaining step numbers renumbered correctly in both files
- [ ] All `*-plan` skills unchanged
- [ ] `cwf-manage validate` passes

## Original Estimate
**Effort**: <1 hour
**Complexity**: Low
**Dependencies**: None

## Major Milestones
1. Remove Step 7 from `cwf-rollout/SKILL.md`, renumber
2. Remove Step 7 from `cwf-maintenance/SKILL.md`, renumber
3. Validate and commit

## Risk Assessment
### Low Priority Risks
- **Off-by-one in renumbering**: Step numbers in subsequent steps drift
  - **Mitigation**: Read each file fully before editing, verify after

## Dependencies
- None

## Constraints
- Do not touch any `*-plan` skill files

## Decomposition Check
- [x] **Time**: No — <1 hour, two small file edits
- [x] **People**: No
- [x] **Complexity**: No — identical change in two files
- [x] **Risk**: No
- [x] **Independence**: N/A

No decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 86
**Blockers**: None

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
