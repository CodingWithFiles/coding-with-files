# Ensure retrospective checkpoint commit stages entire task directory - Implementation Execution
**Task**: 85 (hotfix)

## Task Reference
- **Task ID**: internal-85
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/85-ensure-retrospective-checkpoint-commit-stages-entire-ta
- **Template Version**: 2.1

## Implementation Steps

- [x] Updated "Verify Task Status (Step 7)" in `retrospective-extras.md`:
  - Now uses `workflow-manager status <task_num> --workflow` to check completion
  - Clarifies that every wf step must be in a terminal status (Finished, Skipped, Cancelled)
  - States 100% is the norm; user must be explicitly informed if task cannot reach 100%
- [x] Inserted new "Retrospective Checkpoint Commit" section between "Verify Task Status"
  and "CHANGELOG.md and BACKLOG.md Update":
  - `git add implementation-guide/<task-dir>/` to stage entire task directory
  - Standard commit with Co-developed-by trailer
  - `.cwf/scripts/cwf-manage validate` (no `perl -I.cwf/lib` prefix)
  - Rationale: overrides `checkpoint-commit.md` single-file staging for this phase only

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met
- [x] No planned work deferred

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec 85
**Blockers**: None
