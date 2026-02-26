# Fix bare workflow-manager path in all wf step skills — Design
**Task**: 95 (bugfix)

## Task Reference
- **Task ID**: internal-95
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/95-fix-bare-workflow-manager-path-in-wf-step-skills
- **Template Version**: 2.1

## Key Decision
### Change scope
- **Decision**: String replacement in the "If blocked or finished" line of all 10 wf step SKILL.md files
- **Rationale**: The bare command `workflow-manager` is not on PATH in any CWF installation. The script lives at `.cwf/scripts/command-helpers/workflow-manager`. Models follow the skill literally and fail when they can't find the command.
- **Trade-offs**: None — pure documentation fix, no logic change.

### Path format
- **Decision**: Repo-relative path `.cwf/scripts/command-helpers/workflow-manager`
- **Rationale**: Consistent with how all other command-helper scripts are referenced in the skills (e.g. `context-manager`, `task-context-inference`, `task-workflow`). Absolute paths would break across different user environments.

## Change Pattern

```
# Before (all 10 skills)
workflow-manager control --current-step=<step> --task-path=<path>

# After (all 10 skills)
.cwf/scripts/command-helpers/workflow-manager control --current-step=<step> --task-path=<path>
```

## Affected Files
All 10 wf step skills under `.claude/skills/`:
- `cwf-task-plan/SKILL.md`
- `cwf-requirements-plan/SKILL.md`
- `cwf-design-plan/SKILL.md`
- `cwf-implementation-plan/SKILL.md`
- `cwf-implementation-exec/SKILL.md`
- `cwf-testing-plan/SKILL.md`
- `cwf-testing-exec/SKILL.md`
- `cwf-rollout/SKILL.md`
- `cwf-maintenance/SKILL.md`
- `cwf-retrospective/SKILL.md`

## Constraints
- Path must remain repo-relative, not absolute
- Only the "If blocked or finished" line changes — no other content touched
- The `control` subcommand and its arguments are correct; only the script path prefix changes

## Decomposition Check
- [ ] **Time**: No
- [ ] **People**: No
- [ ] **Complexity**: No — one pattern across 10 files
- [ ] **Risk**: No
- [ ] **Independence**: No

No decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 95
**Blockers**: None

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
