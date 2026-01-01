# CIG Commands Need Reference to Script Dir - Implementation

## Task Reference
- **Task ID**: internal-6
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/6-cig-commands-need-reference-to-script-dir
- **Template Version**: 2.0

## Goal
Add explicit helper scripts directory reference to all 14 CIG command files to prevent LLM path hallucination.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

**Application**: This is a documentation update, so the workflow is:
1. Identify exact insertion points (patterns from existing files)
2. Define exact text to insert (minimal implementation)
3. Verify formatting consistency (validation)

## Files to Modify
### Primary Changes (14 CIG command files)
All files in `.claude/commands/` directory:

1. `.claude/commands/cig-status.md` - Add helper scripts location after line 11
2. `.claude/commands/cig-new-task.md` - Add helper scripts location after line 13
3. `.claude/commands/cig-plan.md` - Add helper scripts location after line 13
4. `.claude/commands/cig-design.md` - Add helper scripts location after line 13
5. `.claude/commands/cig-implementation.md` - Add helper scripts location after line 13
6. `.claude/commands/cig-testing.md` - Add helper scripts location after line 13
7. `.claude/commands/cig-rollout.md` - Add helper scripts location after line 13
8. `.claude/commands/cig-maintenance.md` - Add helper scripts location after line 13
9. `.claude/commands/cig-retrospective.md` - Add helper scripts location after line 13
10. `.claude/commands/cig-requirements.md` - Add helper scripts location after line 13
11. `.claude/commands/cig-subtask.md` - Add helper scripts location after line 15
12. `.claude/commands/cig-extract.md` - Add helper scripts location after line 14
13. `.claude/commands/cig-config.md` - Add helper scripts location (check structure first)
14. `.claude/commands/cig-security-check.md` - Add helper scripts location (check structure first)

### Supporting Changes
None - this is a pure documentation update with no code or test changes required.

## Implementation Steps
### Step 1: Verify Insertion Points
- [x] Read cig-config.md to determine correct insertion point
- [x] Read cig-security-check.md to determine correct insertion point
- [x] Confirm all other files match design document placement rules

### Step 2: Update Command Files (Batch 1: Standard Workflow Commands)
- [x] Update cig-plan.md (line 16)
- [x] Update cig-design.md (line 16)
- [x] Update cig-implementation.md (line 16)
- [x] Update cig-testing.md (line 16)
- [x] Update cig-rollout.md (line 16)
- [x] Update cig-maintenance.md (line 16)
- [x] Update cig-retrospective.md (line 16)
- [x] Update cig-requirements.md (line 16)

### Step 3: Update Command Files (Batch 2: Utility Commands)
- [x] Update cig-status.md (line 13)
- [x] Update cig-new-task.md (line 13)
- [x] Update cig-subtask.md (line 17)
- [x] Update cig-extract.md (line 13)
- [x] Update cig-config.md (line 15)
- [x] Update cig-security-check.md (line 16)

### Step 4: Validation
- [x] Verify all 14 files updated
- [x] Verify consistent formatting across all files
- [x] Verify no markdown structure disruption
- [x] Check git diff for unexpected changes

## Code Changes
### Before (Example: cig-status.md lines 10-13)
```markdown
## Your task
Analyze completion status for: **$ARGUMENTS** (or all tasks if no path specified)

**Arguments**:
- task-path (optional): Specific task number to show
```

### After (Example: cig-status.md lines 10-15)
```markdown
## Your task
Analyze completion status for: **$ARGUMENTS** (or all tasks if no path specified)

**Helper scripts location**: `.cig/scripts/command-helpers/`

**Arguments**:
- task-path (optional): Specific task number to show
```

### Exact Text to Insert
**Format**: Bold markdown with inline code
**Content**: `**Helper scripts location**: `.cig/scripts/command-helpers/``
**Placement**: After task description paragraph, before next section (Arguments/Steps/etc.)
**Spacing**: Blank line before and blank line after

## Test Coverage
This is a documentation change with manual validation:

- **Manual Testing**: Invoke a CIG command and verify LLM uses correct script path
- **Visual Inspection**: Review git diff to confirm consistent formatting
- **Regression Testing**: Verify existing CIG command functionality still works

No automated tests required for markdown documentation updates.

## Validation Criteria
- [x] All 14 files contain the helper scripts location line
- [x] Format is consistent: `**Helper scripts location**: `.cig/scripts/command-helpers/``
- [x] Placement is consistent (after task description, before arguments/steps)
- [x] No disruption to existing markdown structure
- [x] Git diff shows only the expected single-line additions per file (14 files, 28 insertions)
- [ ] Manual test: Run `/cig-status` and verify no path hallucination (to be tested in testing phase)

## Status
**Status**: Finished
**Next Action**: Move to testing phase (`/cig-testing 6`)
**Blockers**: None

## Actual Results
Successfully updated all 14 CIG command files with helper scripts location reference:

**Files Updated** (14 total):
1. cig-plan.md - Added at line 16
2. cig-design.md - Added at line 16
3. cig-implementation.md - Added at line 16
4. cig-testing.md - Added at line 16
5. cig-rollout.md - Added at line 16
6. cig-maintenance.md - Added at line 16
7. cig-retrospective.md - Added at line 16
8. cig-requirements.md - Added at line 16
9. cig-status.md - Added at line 13
10. cig-new-task.md - Added at line 13
11. cig-subtask.md - Added at line 17
12. cig-extract.md - Added at line 13
13. cig-config.md - Added at line 15
14. cig-security-check.md - Added at line 16

**Git Diff Stats**: 14 files changed, 28 insertions (+) - exactly 2 lines per file as expected

**Format Consistency**: All files use identical format: `**Helper scripts location**: `.cig/scripts/command-helpers/``

**Placement Consistency**: All files have the line inserted after task description, before arguments/steps/workflow sections

**No Regressions**: Markdown structure preserved, no unexpected changes

## Lessons Learned
*To be captured during implementation*
