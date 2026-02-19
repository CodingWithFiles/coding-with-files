# Add missing checkpoint commit instructions to cwf-requirements-plan and cwf-maintenance - Implementation Plan
**Task**: 71 (hotfix)

## Task Reference
- **Task ID**: internal-71
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/71-fix-checkpoint-steps
- **Template Version**: 2.1

## Goal
Add the missing Step 8 checkpoint commit instruction to two skill files, renumbering their current Step 8 (Next Steps) to Step 9.

## Files to Modify

### Primary Changes
- `.claude/skills/cwf-requirements-plan/SKILL.md` — insert checkpoint commit step, renumber Next Steps 8→9
- `.claude/skills/cwf-maintenance/SKILL.md` — insert checkpoint commit step, renumber Next Steps 8→9

## Implementation Steps

### Step 1: Update cwf-requirements-plan/SKILL.md

Replace:
```
**Step 8 (Next Steps)**:
- **Primary**: Move to design → `/cwf-design-plan <task-path>`
- **Alt**: Return to planning if requirements reveal scope issues
- **Alt**: Create subtasks if complexity signals triggered
```

With:
```
**Step 8**: Checkpoint commit. See `.cwf/docs/skills/checkpoint-commit.md`. Stage: `b-requirements-plan.md`

**Step 9 (Next Steps)**:
- **Primary**: Move to design → `/cwf-design-plan <task-path>`
- **Alt**: Return to planning if requirements reveal scope issues
- **Alt**: Create subtasks if complexity signals triggered
```

### Step 2: Update cwf-maintenance/SKILL.md

Replace:
```
**Step 8 (Next Steps)**:
- **Primary**: Task complete, ready for retrospective → `/cwf-retrospective <task-path>`
- **Alt**: Create follow-up tasks for identified improvements
```

With:
```
**Step 8**: Checkpoint commit. See `.cwf/docs/skills/checkpoint-commit.md`. Stage: `i-maintenance.md`

**Step 9 (Next Steps)**:
- **Primary**: Task complete, ready for retrospective → `/cwf-retrospective <task-path>`
- **Alt**: Create follow-up tasks for identified improvements
```

## Validation Criteria

**See e-testing-plan.md for complete test plan**

Quick sanity checks after editing:
- Both files contain `checkpoint-commit.md` reference in Step 8
- `cwf-requirements-plan` Step 8 stages `b-requirements-plan.md`
- `cwf-maintenance` Step 8 stages `i-maintenance.md`
- Both files have Next Steps as Step 9
- `cwf-manage validate` exits 0

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 71
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during retrospective*
