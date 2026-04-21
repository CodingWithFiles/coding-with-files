# Rename cwf-subtask skill to cwf-new-subtask - Implementation Plan
**Task**: 106 (chore)

## Task Reference
- **Task ID**: internal-106
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/106-rename-cwf-subtask-skill-to-cwf-new-subtask
- **Template Version**: 2.1

## Goal
Rename `/cwf-subtask` skill to `/cwf-new-subtask` and update all live references.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify

### Primary Changes
- `.claude/skills/cwf-subtask/` → Rename directory to `.claude/skills/cwf-new-subtask/`
- `.claude/skills/cwf-new-subtask/SKILL.md` → Update `name:` field from `cwf-subtask` to `cwf-new-subtask`

### Reference Updates (live docs)
- `CLAUDE.md:27` — `/cwf-subtask` → `/cwf-new-subtask`
- `README.md:110` — `/cwf-subtask` → `/cwf-new-subtask`
- `.cwf/docs/workflow/decomposition-guide.md:67,70,73` — `/cwf-subtask` → `/cwf-new-subtask`
- `.claude/skills/cwf-task-plan/SKILL.md:43` — `/cwf-subtask` → `/cwf-new-subtask`
- `BACKLOG.md:78,122,127` — `cwf-subtask` → `cwf-new-subtask` (active backlog items only)
- `scratchpad.md` — `/cwf-subtask` → `/cwf-new-subtask` (ephemeral file, many references)

### Do NOT Touch (historical records)
- `CHANGELOG.md` — historical entries
- `implementation-guide/63-*`, `71-*`, `91-*`, `96-*`, `100-*` — completed task docs

## Implementation Steps

### Step 1: Rename skill directory
- [ ] `git mv .claude/skills/cwf-subtask .claude/skills/cwf-new-subtask`
- [ ] Update `name:` field in SKILL.md

### Step 2: Update live references
- [ ] CLAUDE.md
- [ ] README.md
- [ ] decomposition-guide.md
- [ ] cwf-task-plan SKILL.md
- [ ] BACKLOG.md (active items only)
- [ ] scratchpad.md

### Step 3: Verify
- [ ] `grep -r 'cwf-subtask' --include='*.md'` in live files shows zero hits outside historical/implementation-guide files
- [ ] `/cwf-new-subtask` appears in skill listing

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 106
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
