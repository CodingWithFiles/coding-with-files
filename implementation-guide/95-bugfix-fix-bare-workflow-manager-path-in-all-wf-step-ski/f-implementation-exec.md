# Fix bare workflow-manager path in all wf step skills — Implementation Execution
**Task**: 95 (bugfix)

## Task Reference
- **Task ID**: internal-95
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/95-fix-bare-workflow-manager-path-in-wf-step-skills
- **Template Version**: 2.1

## Actual Results

### Step 1: Pre-edit audit
- **Planned**: Grep `.claude/skills/` for `workflow-manager control` to confirm all occurrences
- **Actual**: 10 matches, all on line 16 of the respective SKILL.md, one per skill
- **Deviations**: None

### Step 2: Apply path fix to all 10 SKILL.md files
- **Planned**: Prepend `.cwf/scripts/command-helpers/` to `workflow-manager control` in each file
- **Actual**: All 10 files updated in parallel via Edit tool
  - `cwf-task-plan/SKILL.md` — a-task-plan
  - `cwf-requirements-plan/SKILL.md` — b-requirements-plan
  - `cwf-design-plan/SKILL.md` — c-design-plan
  - `cwf-implementation-plan/SKILL.md` — d-implementation-plan
  - `cwf-implementation-exec/SKILL.md` — f-implementation-exec
  - `cwf-testing-plan/SKILL.md` — e-testing-plan
  - `cwf-testing-exec/SKILL.md` — g-testing-exec
  - `cwf-rollout/SKILL.md` — h-rollout
  - `cwf-maintenance/SKILL.md` — i-maintenance
  - `cwf-retrospective/SKILL.md` — j-retrospective
- **Deviations**: None

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met
- [x] Design guidance in c-design-plan.md followed
- [x] No planned work deferred

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec 95
**Blockers**: None

## Lessons Learned
*To be captured during retrospective*
