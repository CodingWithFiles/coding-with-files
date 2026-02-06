# fix-incorrect-cig-plan-refs - Implementation

## Task Reference
- **Task ID**: internal-35
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/35-fix-incorrect-cig-plan-refs
- **Template Version**: 2.1

## Goal
Implement fix-incorrect-cig-plan-refs following the approved design and requirements.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `.claude/commands/cig-new-task.md` (line 98) - Update `/cig-plan <num>` to `/cig-task-plan <num>`
- `.claude/commands/cig-subtask.md` (line 74) - Update `/cig-plan <num>` to `/cig-task-plan <num>`

### Historical References (DO NOT MODIFY)
- 35 references in `implementation-guide/` directory - These are historical documentation and must be preserved

## Implementation Steps
### Step 1: Verify Current References
- [ ] Read `.claude/commands/cig-new-task.md:98` to confirm current text
- [ ] Read `.claude/commands/cig-subtask.md:74` to confirm current text
- [ ] Document exact text to be replaced

### Step 2: Update Command Files
- [ ] Edit `.claude/commands/cig-new-task.md:98` - Replace `/cig-plan` with `/cig-task-plan`
- [ ] Edit `.claude/commands/cig-subtask.md:74` - Replace `/cig-plan` with `/cig-task-plan`

### Step 3: Verification
- [ ] Grep for `/cig-plan` in `.claude/commands/` directory - Should find 0 matches
- [ ] Grep for `/cig-task-plan` in updated lines - Should find 2 matches
- [ ] Verify historical references in `implementation-guide/` are unchanged - Should still be 35 references

### Step 4: Validation
- [ ] Review git diff to confirm only 2 lines changed
- [ ] Verify both command files still reference correct skill
- [ ] Confirm no unintended changes to other files

## Code Changes
### Before
`.claude/commands/cig-new-task.md:98`:
```markdown
- Next action: `/cig-plan <num>` to begin planning phase
```

`.claude/commands/cig-subtask.md:74`:
```markdown
- Next action: `/cig-plan <num>` to begin planning phase
```

### After
`.claude/commands/cig-new-task.md:98`:
```markdown
- Next action: `/cig-task-plan <num>` to begin planning phase
```

`.claude/commands/cig-subtask.md:74`:
```markdown
- Next action: `/cig-task-plan <num>` to begin planning phase
```

## Test Coverage
**See e-testing.md for complete test plan**

## Validation Criteria
**See e-testing.md for validation criteria and test results**

## Status
**Status**: Finished
**Next Action**: Move to testing planning → `/cig-testing-plan 35`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
