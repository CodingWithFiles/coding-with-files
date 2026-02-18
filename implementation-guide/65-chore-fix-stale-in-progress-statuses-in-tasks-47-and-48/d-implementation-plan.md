# Fix stale In Progress statuses in tasks 47 and 48 - Implementation Plan
**Task**: 65 (chore)

## Task Reference
- **Task ID**: internal-65
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/65-fix-stale-in-progress-statuses-in-tasks-47-and-48
- **Template Version**: 2.1

## Goal
Edit 10 workflow files to correct stale status fields.

## Files to Modify

| File | Current Status | Correct Status |
|------|---------------|----------------|
| `implementation-guide/47-.../a-task-plan.md` | In Progress | Finished |
| `implementation-guide/47-.../c-design-plan.md` | In Progress | Finished |
| `implementation-guide/47-.../d-implementation-plan.md` | In Progress | Finished |
| `implementation-guide/47-.../e-testing-plan.md` | In Progress | Finished |
| `implementation-guide/47-.../f-implementation-exec.md` | Implemented | Finished |
| `implementation-guide/48-.../a-task-plan.md` | In Progress | Finished |
| `implementation-guide/48-.../c-design-plan.md` | In Progress | Finished |
| `implementation-guide/48-.../d-implementation-plan.md` | In Progress | Finished |
| `implementation-guide/48-.../e-testing-plan.md` | In Progress | Finished |
| `implementation-guide/48-.../f-implementation-exec.md` | Implemented | Finished |

## Implementation Steps

- [ ] In each of the 10 files above, change `**Status**: In Progress` or `**Status**: Implemented` to `**Status**: Finished`
- [ ] Run `cwf-manage validate` — expect OK
- [ ] Verify `status-aggregator-v2.1 47 --workflow` and `48 --workflow` both show 100%
- [ ] Verify `task-context-inference` no longer lists 47 or 48 as candidates

## Validation Criteria
- `cwf-manage validate` exits 0
- `status-aggregator-v2.1 47` and `48` both show 100%
- `task-context-inference` no longer lists 47 or 48

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 65
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 10 files updated as planned.

## Lessons Learned
See j-retrospective.md.
