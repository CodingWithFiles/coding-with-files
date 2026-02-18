# Fix stale statuses in tasks 46 and 49 - Retrospective
**Task**: 67 (chore)

## Task Reference
- **Task ID**: internal-67
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/67-fix-stale-statuses-in-tasks-46-and-49
- **Template Version**: 2.1
- **Retrospective Date**: 2026-02-18

## Executive Summary
- **Duration**: <1 session (trivial — as estimated)
- **Scope**: 7 status field edits across 2 tasks
- **Outcome**: Full success. Tasks 46 and 49 both at 100%. task-context-inference no longer treats them as active.

## Variance Analysis

### Time and Effort
- **Estimated**: Trivial
- **Actual**: Trivial — 7 in-place substitutions, 6 test cases, done
- **Variance**: None

### Scope Changes
- **Additions**: None
- **Removals**: None

## What Went Well
- Mechanical, risk-free fix. No surprises.
- Pattern well-understood from task 65.

## What Could Be Improved
- This is the third time we've done this cleanup (65 fixed 47+48, now 67 fixes 46+49). The root cause — retrospective skills not requiring all preceding files be set to Finished — is still not fixed. The recommendation from task 65's retrospective has not been acted on.

## Key Learnings
- **The recommendation from task 65 still stands**: The `cwf-retrospective` skill should include an explicit mandatory checklist item: "Set all preceding workflow files (a through g) to Finished before marking j-retrospective.md Finished." Until that is added, stale status cleanups will keep recurring.

## Recommendations
- **Action required**: Add the mandatory checklist item to `.cwf/docs/skills/retrospective-extras.md`. This has now been recommended twice (tasks 65 and 67). Create a chore task to implement it if it hasn't been done yet.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None
**Completion Date**: 2026-02-18

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Tasks fixed: `implementation-guide/46-...`, `implementation-guide/49-...`
