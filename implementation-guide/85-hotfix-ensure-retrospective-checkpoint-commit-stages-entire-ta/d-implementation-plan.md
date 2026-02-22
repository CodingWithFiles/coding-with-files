# Ensure retrospective checkpoint commit stages entire task directory - Implementation Plan
**Task**: 85 (hotfix)

## Task Reference
- **Task ID**: internal-85
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/85-ensure-retrospective-checkpoint-commit-stages-entire-ta
- **Template Version**: 2.1

## Goal
Add an explicit retrospective checkpoint commit section to `retrospective-extras.md`
that stages the entire task directory, overriding the generic single-file staging
instruction in `checkpoint-commit.md`.

## Files to Modify
### Primary Changes
- `.cwf/docs/skills/retrospective-extras.md` — add new "Retrospective Checkpoint Commit"
  section between "Verify Task Status" and "CHANGELOG.md and BACKLOG.md Update"

## Implementation Steps
- [ ] Insert new `## Retrospective Checkpoint Commit` section after "Verify Task Status (Step 7)"
- [ ] Section instructs: stage entire task directory with `git add implementation-guide/<task-dir>/`
- [ ] Section notes this overrides the generic `checkpoint-commit.md` single-file staging
- [ ] Section includes the standard commit and validate commands

## Before / After

### Before (retrospective-extras.md, after "Verify Task Status")
```markdown
## CHANGELOG.md and BACKLOG.md Update (Step 9)
```

### After
```markdown
## Retrospective Checkpoint Commit

After completing j-retrospective.md, stage and commit the entire task directory —
not just j-retrospective.md. Status corrections made during Step 7 must be included:

    git add implementation-guide/<task-dir>/
    git commit -m "Task N: Complete retrospective — <one-line summary>"

This overrides the single-file staging in checkpoint-commit.md, which applies to
all other phases. Validate after committing:

    .cwf/scripts/cwf-manage validate

## CHANGELOG.md and BACKLOG.md Update (Step 9)
```

Also update "Verify Task Status (Step 7)" to:
- Use `.cwf/scripts/command-helpers/workflow-manager status <task_num> --workflow`
  to check overall task completion
- Individual wf steps must be in a terminal status (Finished, Skipped, Cancelled) —
  the check is that the overall task reports 100% ("Finished")
- The overall task reaching 100% is the norm; leaving it below 100% is the exception
  and the user must be explicitly informed if that is the case

## Validation Criteria
**See e-testing-plan.md**

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 85
**Blockers**: None

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
