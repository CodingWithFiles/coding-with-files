# Rename cwf-subtask skill to cwf-new-subtask - Plan
**Task**: 106 (chore)

## Task Reference
- **Task ID**: internal-106
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/106-rename-cwf-subtask-skill-to-cwf-new-subtask
- **Template Version**: 2.1

## Goal
Rename `/cwf-subtask` to `/cwf-new-subtask` so the skill name mirrors `/cwf-new-task` and the agent doesn't confuse it with a task-info or task-navigation command.

## Success Criteria
- [ ] Skill directory renamed from `.claude/skills/cwf-subtask/` to `.claude/skills/cwf-new-subtask/`
- [ ] All live documentation references updated (CLAUDE.md, README.md, BACKLOG.md, decomposition-guide, other skills)
- [ ] Historical implementation-guide files left unchanged (they are records)
- [ ] `/cwf-new-subtask` invocable and working identically to old `/cwf-subtask`

## Original Estimate
**Effort**: <1 day
**Complexity**: Low
**Dependencies**: None

## Major Milestones
1. **Rename skill directory**: `.claude/skills/cwf-subtask/` → `.claude/skills/cwf-new-subtask/`
2. **Update references**: All live docs and skills that reference `/cwf-subtask`
3. **Verify**: Skill invocable under new name, no stale references in live files

## Risk Assessment
### Medium Priority Risks
- **Stale references**: Grep may miss references if they use variant forms (e.g. `cwf_subtask`, backtick-wrapped)
  - **Mitigation**: Search for both `cwf-subtask` and `cwf_subtask`; post-rename grep to confirm zero live hits

## Dependencies
- None

## Constraints
- Historical implementation-guide files must not be edited (they document what happened at the time)
- CHANGELOG.md entries are historical records — do not alter existing entries

## Decomposition Check
- [x] **Time**: No — under 1 hour
- [x] **People**: No — single person
- [x] **Complexity**: No — mechanical rename
- [x] **Risk**: No — low risk
- [x] **Independence**: No — single concern

No decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 106
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
