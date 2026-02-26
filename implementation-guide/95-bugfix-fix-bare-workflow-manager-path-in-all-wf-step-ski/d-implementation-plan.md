# Fix bare workflow-manager path in all wf step skills — Implementation Plan
**Task**: 95 (bugfix)

## Task Reference
- **Task ID**: internal-95
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/95-fix-bare-workflow-manager-path-in-wf-step-skills
- **Template Version**: 2.1

## Files to Modify
- `.claude/skills/cwf-task-plan/SKILL.md`
- `.claude/skills/cwf-requirements-plan/SKILL.md`
- `.claude/skills/cwf-design-plan/SKILL.md`
- `.claude/skills/cwf-implementation-plan/SKILL.md`
- `.claude/skills/cwf-implementation-exec/SKILL.md`
- `.claude/skills/cwf-testing-plan/SKILL.md`
- `.claude/skills/cwf-testing-exec/SKILL.md`
- `.claude/skills/cwf-rollout/SKILL.md`
- `.claude/skills/cwf-maintenance/SKILL.md`
- `.claude/skills/cwf-retrospective/SKILL.md`

## Implementation Steps
- [ ] Grep `.claude/skills/` for `workflow-manager control` to confirm all 10 occurrences
- [ ] Apply `replace_all` edit to each SKILL.md: prepend `.cwf/scripts/command-helpers/` to `workflow-manager control`
- [ ] Grep again to confirm 0 bare `workflow-manager control` references remain

## Change Pattern

### Before
```
workflow-manager control --current-step=<step> --task-path=<path>
```

### After
```
.cwf/scripts/command-helpers/workflow-manager control --current-step=<step> --task-path=<path>
```

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 95
**Blockers**: None

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
