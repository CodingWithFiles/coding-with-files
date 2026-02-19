# Add missing checkpoint commit instructions to cwf-requirements-plan and cwf-maintenance - Plan
**Task**: 71 (hotfix)

## Task Reference
- **Task ID**: internal-71
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/71-fix-checkpoint-steps
- **Template Version**: 2.1

## Goal
Add the missing Step 8 checkpoint commit instruction to `cwf-requirements-plan/SKILL.md` and `cwf-maintenance/SKILL.md` so agents commit their workflow files at the end of each phase.

## Success Criteria
- [ ] `cwf-requirements-plan/SKILL.md` contains a checkpoint commit step (Stage: `b-requirements-plan.md`)
- [ ] `cwf-maintenance/SKILL.md` contains a checkpoint commit step (Stage: `i-maintenance.md`)
- [ ] Both steps reference `.cwf/docs/skills/checkpoint-commit.md` consistent with other wf step skills
- [ ] `cwf-manage validate` exits 0

## Original Estimate
**Effort**: Trivial (<1 session)
**Complexity**: Low
**Dependencies**: None

## Major Milestones
1. Both SKILL.md files updated with checkpoint commit steps
2. Tests pass

## Risk Assessment
### Low Priority Risks
- **Step numbering conflict**: The existing Step 8 in each skill may need to become Step 9 (or the checkpoint step may need to slot in before Next Steps)
  - **Mitigation**: Read each skill's current step structure before editing to find the right insertion point

## Dependencies
- None

## Constraints
- Changes to `cwf-requirements-plan/SKILL.md` and `cwf-maintenance/SKILL.md` only
- Checkpoint commit step must match the pattern used by all other wf step skills

## Decomposition Check
- [ ] **Time**: >1 week? — No
- [ ] **People**: >2? — No
- [ ] **Complexity**: 3+ concerns? — No (two identical edits)
- [ ] **Risk**: High-risk? — No
- [ ] **Independence**: Separable? — No benefit to splitting

No decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 71
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during retrospective*
