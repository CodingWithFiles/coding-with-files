# Remove v1.0 category subdirectories from cwf-init - Implementation Plan
**Task**: 68 (hotfix)

## Task Reference
- **Task ID**: internal-68
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/68-remove-v1-0-category-subdirectories-from-cwf-init
- **Template Version**: 2.1

## Goal
Remove the obsolete category-subdir instruction from cwf-init SKILL.md and update README.md Project Structure to reflect v2.1 layout.

## Files to Modify

| File | Change |
|------|--------|
| `.claude/skills/cwf-init/SKILL.md` | Remove line 27: `- Category subdirectories: \`feature/\`, \`bugfix/\`, \`hotfix/\`, \`chore/\`` |
| `README.md` | Replace stale v1.0 Project Structure block with v2.1 layout |
| `BACKLOG.md` | Remove two duplicate entries covering this issue (task 63 High + task 60 Medium) |

## Implementation Steps

### Step 1: Fix SKILL.md
Remove the single bullet from the "Create Directory Structure" section:
```
- Category subdirectories: `feature/`, `bugfix/`, `hotfix/`, `chore/`
```
Leave the `implementation-guide/` bullet intact.

### Step 2: Update README.md Project Structure
Replace the v1.0 block (lines 121-151) with a v2.1 block:

```
implementation-guide/
├── cwf-project.json
├── 1-feature-task-name/
│   ├── a-task-plan.md
│   ├── b-requirements-plan.md
│   └── ...
├── 1.1-chore-subtask/
│   └── ...
└── 2-bugfix-another-task/

.cwf/
├── autoload.yaml
├── lib/
│   └── CWF/              # Perl library modules
├── scripts/
│   └── command-helpers/  # Helper scripts for compound operations
├── security/
│   └── script-hashes.json
└── templates/
    └── pool/             # Template source files (task-type symlinks alongside)
```

Also update any stale prose in that section that references the v1.0 category layout.

### Step 3: Remove BACKLOG entries
Remove both entries that cover this issue:
- "Task: Remove v1.0 Category Subdirectories from /cwf-init" (High, task 63)
- "Task: Audit /cwf-init for Obsolete Category Subdirectories" (Medium, task 60)

## Validation Criteria
- `cwf-init/SKILL.md` "Create Directory Structure" section has no mention of category subdirs
- `README.md` Project Structure block shows v2.1 number-prefixed layout
- Both BACKLOG entries removed
- `cwf-manage validate` exits 0

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 68
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during retrospective*
