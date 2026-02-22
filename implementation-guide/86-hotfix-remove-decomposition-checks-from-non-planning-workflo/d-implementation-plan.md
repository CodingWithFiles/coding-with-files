# Remove decomposition checks from non-planning workflow steps - Implementation Plan
**Task**: 86 (hotfix)

## Task Reference
- **Task ID**: internal-86
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/86-remove-decomposition-checks-from-non-planning-workflo
- **Template Version**: 2.1

## Goal
Remove Step 7 (decomposition check) from `cwf-rollout` and `cwf-maintenance` skill
files, and renumber the remaining steps accordingly.

## Files to Modify
- `.claude/skills/cwf-rollout/SKILL.md` — remove Step 7, renumber Steps 8→7, 9→8
- `.claude/skills/cwf-maintenance/SKILL.md` — remove Step 7, renumber Steps 8→7, 9→8

## Implementation Steps
- [ ] `cwf-rollout/SKILL.md`: delete `**Step 7**: Check decomposition signals...` line
- [ ] `cwf-rollout/SKILL.md`: rename `**Step 8**` → `**Step 7**` (checkpoint commit)
- [ ] `cwf-rollout/SKILL.md`: rename `**Step 9**` → `**Step 8**` (next steps)
- [ ] `cwf-maintenance/SKILL.md`: delete `**Step 7**: Check decomposition signals...` line
- [ ] `cwf-maintenance/SKILL.md`: rename `**Step 8**` → `**Step 7**` (checkpoint commit)
- [ ] `cwf-maintenance/SKILL.md`: rename `**Step 9**` → `**Step 8**` (next steps)

## Validation Criteria
**See e-testing-plan.md**

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 86
**Blockers**: None

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
