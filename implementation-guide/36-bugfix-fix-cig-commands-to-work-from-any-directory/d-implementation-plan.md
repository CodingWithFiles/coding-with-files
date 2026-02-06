# Fix CIG Commands to Work from Any Directory - Implementation

## Task Reference
- **Task ID**: internal-36
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/36-fix-cig-commands-to-work-from-any-directory
- **Template Version**: 2.1

## Goal
Implement Fix CIG Commands to Work from Any Directory following the approved design and requirements.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes (17 command files)
**Workflow Commands (10 files)**:
- `.claude/commands/cig-task-plan.md` - Add git root detection
- `.claude/commands/cig-requirements-plan.md` - Add git root detection
- `.claude/commands/cig-design-plan.md` - Add git root detection
- `.claude/commands/cig-implementation-plan.md` - Add git root detection
- `.claude/commands/cig-testing-plan.md` - Add git root detection
- `.claude/commands/cig-implementation-exec.md` - Add git root detection
- `.claude/commands/cig-testing-exec.md` - Add git root detection
- `.claude/commands/cig-rollout.md` - Add git root detection
- `.claude/commands/cig-maintenance.md` - Add git root detection
- `.claude/commands/cig-retrospective.md` - Add git root detection

**Utility Commands (7 files)**:
- `.claude/commands/cig-new-task.md` - Add git root detection
- `.claude/commands/cig-subtask.md` - Add git root detection
- `.claude/commands/cig-status.md` - Add git root detection
- `.claude/commands/cig-extract.md` - Add git root detection
- `.claude/commands/cig-config.md` - Add git root detection
- `.claude/commands/cig-init.md` - Add git root detection
- `.claude/commands/cig-security-check.md` - Add git root detection

### Supporting Changes
None - this is a self-contained fix to command files only

## Implementation Steps

### Step 1: Identify Insertion Point in Command Files
- [ ] Read cig-new-task.md to understand current structure
- [ ] Identify insertion point: After frontmatter/metadata, before "## Your task" section
- [ ] Document the exact pattern for consistent application across all files

### Step 2: Create Git Root Detection Snippet
- [ ] Define the 4-line bash snippet to be inserted:
  ```bash
  GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
  if [ -z "$GIT_ROOT" ]; then
      echo "Error: Not in a git repository. CIG commands must be run from within a git repository."
      exit 1
  fi

  cd "$GIT_ROOT"
  echo "Working directory: $GIT_ROOT"
  ```

### Step 3: Update Workflow Commands (Batch 1: 10 files)
- [ ] Update cig-task-plan.md
- [ ] Update cig-requirements-plan.md
- [ ] Update cig-design-plan.md
- [ ] Update cig-implementation-plan.md
- [ ] Update cig-testing-plan.md
- [ ] Update cig-implementation-exec.md
- [ ] Update cig-testing-exec.md
- [ ] Update cig-rollout.md
- [ ] Update cig-maintenance.md
- [ ] Update cig-retrospective.md

### Step 4: Update Utility Commands (Batch 2: 7 files)
- [ ] Update cig-new-task.md
- [ ] Update cig-subtask.md
- [ ] Update cig-status.md
- [ ] Update cig-extract.md
- [ ] Update cig-config.md
- [ ] Update cig-init.md
- [ ] Update cig-security-check.md

### Step 5: Verification
- [ ] Grep for "GIT_ROOT" in all 17 files - should find 17 matches
- [ ] Verify insertion point is consistent across all files
- [ ] Review git diff to confirm only expected changes made

## Code Changes

### Before (Example from cig-new-task.md)
```markdown
---
description: Create categorised implementation guide (v2.0 - hierarchical)
---

## Context
- Project config: !`.cig/scripts/command-helpers/cig-load-project-config`

## Your task
Create new hierarchical implementation guide for: **$ARGUMENTS**
```

### After (with git root detection)
```markdown
---
description: Create categorised implementation guide (v2.0 - hierarchical)
---

## Context
- Project config: !`.cig/scripts/command-helpers/cig-load-project-config`

## Your task
Create new hierarchical implementation guide for: **$ARGUMENTS**

**Implementation**: First ensure we're in git repository root:

!{bash}
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$GIT_ROOT" ]; then
    echo "Error: Not in a git repository. CIG commands must be run from within a git repository."
    exit 1
fi

cd "$GIT_ROOT"
echo "Working directory: $GIT_ROOT"
```

## Test Coverage
**See e-testing.md for complete test plan**

## Validation Criteria
**See e-testing.md for validation criteria and test results**

## Status
**Status**: Finished
**Next Action**: Move to testing planning → `/cig-testing-plan 36`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
