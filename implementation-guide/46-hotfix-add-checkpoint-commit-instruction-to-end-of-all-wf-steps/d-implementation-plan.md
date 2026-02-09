# add checkpoint commit instruction to end of all wf steps - Implementation Plan
**Task**: 46 (hotfix)

## Task Reference
- **Task ID**: internal-46
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/46-add-checkpoint-commit-instruction-to-end-of-all-wf-steps
- **Template Version**: 2.1

## Goal
Implement add checkpoint commit instruction to end of all wf steps following the approved design and requirements.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `.claude/commands/cig-task-plan.md` - Add checkpoint commit step and frontmatter permissions
- `.claude/commands/cig-design-plan.md` - Add checkpoint commit step and frontmatter permissions
- `.claude/commands/cig-implementation-plan.md` - Add checkpoint commit step and frontmatter permissions
- `.claude/commands/cig-testing-plan.md` - Add checkpoint commit step and frontmatter permissions
- `.claude/commands/cig-implementation-exec.md` - Add checkpoint commit step and frontmatter permissions
- `.claude/commands/cig-testing-exec.md` - Add checkpoint commit step and frontmatter permissions
- `.claude/commands/cig-rollout.md` - Add checkpoint commit step and frontmatter permissions

### Supporting Changes
None - pure documentation update

## Implementation Steps
### Step 1: Audit Frontmatter Permissions
- [ ] Check each of the 7 command files' frontmatter for `Bash(git add:*)` and `Bash(git commit:*)`
- [ ] Identify which commands are missing these permissions
- [ ] Document current state for before/after comparison

### Step 2: Add Checkpoint Commit Step to Each Command
For each of the 7 workflow commands, add checkpoint commit instructions as a new numbered step before "Suggest Next Steps":

- [ ] `cig-task-plan.md` - Add Step 9: Checkpoint Commit after planning complete
- [ ] `cig-design-plan.md` - Add Step 9: Checkpoint Commit after design complete
- [ ] `cig-implementation-plan.md` - Add Step 9: Checkpoint Commit after impl planning complete
- [ ] `cig-testing-plan.md` - Add Step 9: Checkpoint Commit after test planning complete
- [ ] `cig-implementation-exec.md` - Add Step 9: Checkpoint Commit after implementation complete
- [ ] `cig-testing-exec.md` - Add Step 9: Checkpoint Commit after testing complete
- [ ] `cig-rollout.md` - Add Step 9: Checkpoint Commit after rollout complete

Each step should:
- Be numbered consistently (Step 9 in the workflow sequence)
- Reference `.cig/docs/workflow/workflow-steps.md` for commit message format
- Use template: `git add <phase-file>` then `git commit -m "Task N: Complete <phase> phase\n\n<why>\n\nCo-developed-by: Claude Sonnet 4.5 <noreply@anthropic.com>"`
- Be placed right before the "Suggest Next Steps" section

### Step 3: Update Frontmatter Permissions
- [ ] Add `Bash(git add:*)` to frontmatter if missing (likely already present in most)
- [ ] Add `Bash(git commit:*)` to frontmatter if missing (likely missing in most)
- [ ] Verify no other git commands are needed for checkpoint commits

### Step 4: Verification
- [ ] Read each modified file to confirm checkpoint step added correctly
- [ ] Verify step numbering is consistent across all commands
- [ ] Verify frontmatter includes necessary git permissions
- [ ] Confirm instructions reference workflow-steps.md rather than duplicating format

## Code Changes
### Before
Current state: Commands end with "Suggest Next Steps" section, no checkpoint commit instructions

Example from `cig-task-plan.md`:
```markdown
8. **Suggest Next Steps with Reasoning**:

Analyze the planning outcome and suggest the next step:

**Primary Next Step** (if planning is complete and approved):
- Move to requirements phase: `/cig-requirements <task-path>`
- Rationale: Planning establishes goals, requirements define specifics

## Success Criteria
- [ ] Task directory resolved successfully
...
```

**Problems**:
- No instruction to commit after phase complete
- Agents don't create checkpoint commits
- Retrospective Step 10 expects commits to squash, but they don't exist

### After
New Step 9 added before "Suggest Next Steps":

```markdown
9. **Create Checkpoint Commit**:

After completing the planning phase, create a checkpoint commit to preserve progress:

```bash
git add implementation-guide/<task-dir>/a-task-plan.md
git commit -m "Task N: Complete planning phase

<Brief explanation of why - what problem does this solve>

Co-developed-by: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

**Rationale**: Checkpoint commits preserve incremental progress and enable retrospective squashing workflow (Step 10 in cig-retrospective).

See `.cig/docs/workflow/workflow-steps.md#planning` for detailed checkpoint commit guidance.

10. **Suggest Next Steps with Reasoning**:
...
```

**Improvements**:
- Explicit checkpoint commit instruction after phase complete
- References workflow-steps.md for canonical format
- Explains "why" (retrospective squashing)
- "Suggest Next Steps" becomes Step 10 (renumbered)

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
**Next Action**: Move to testing planning → `/cig-testing-plan 46`
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
