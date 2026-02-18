# Fix stale statuses in tasks 46 and 49 - Implementation Plan
**Task**: 67 (chore)

## Task Reference
- **Task ID**: internal-67
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/67-fix-stale-statuses-in-tasks-46-and-49
- **Template Version**: 2.1

## Goal
Execute 7 in-place status field updates across tasks 46 and 49.

## Files to Modify

| Task | File | Current | Correct |
|------|------|---------|---------|
| 46 | `f-implementation-exec.md` | Backlog | Finished |
| 46 | `g-testing-exec.md` | Backlog | Finished |
| 49 | `a-task-plan.md` | In Progress | Finished |
| 49 | `c-design-plan.md` | In Progress | Finished |
| 49 | `d-implementation-plan.md` | In Progress | Finished |
| 49 | `e-testing-plan.md` | In Progress | Finished |
| 49 | `f-implementation-exec.md` | Implemented | Finished |

## Implementation Steps

### Step 1: Update task 46 — 2 files Backlog → Finished
```bash
perl -i -pe 's/^\*\*Status\*\*: Backlog/**Status**: Finished/' \
  implementation-guide/46-hotfix-add-checkpoint-commit-instruction-to-end-of-all-wf-steps/f-implementation-exec.md \
  implementation-guide/46-hotfix-add-checkpoint-commit-instruction-to-end-of-all-wf-steps/g-testing-exec.md
```

### Step 2: Update task 49 — 4 files In Progress → Finished
```bash
perl -i -pe 's/^\*\*Status\*\*: In Progress/**Status**: Finished/' \
  implementation-guide/49-bugfix-fix-checkpoints-branch-perms-issue-with-script/a-task-plan.md \
  implementation-guide/49-bugfix-fix-checkpoints-branch-perms-issue-with-script/c-design-plan.md \
  implementation-guide/49-bugfix-fix-checkpoints-branch-perms-issue-with-script/d-implementation-plan.md \
  implementation-guide/49-bugfix-fix-checkpoints-branch-perms-issue-with-script/e-testing-plan.md
```

### Step 3: Update task 49 — f Implemented → Finished
```bash
perl -i -pe 's/^\*\*Status\*\*: Implemented/**Status**: Finished/' \
  implementation-guide/49-bugfix-fix-checkpoints-branch-perms-issue-with-script/f-implementation-exec.md
```

### Step 4: Verify
```bash
grep "^\*\*Status\*\*:" implementation-guide/46-*/f-*.md implementation-guide/46-*/g-*.md
grep "^\*\*Status\*\*:" implementation-guide/49-*/{a,c,d,e,f}-*.md
```

## Validation Criteria
- All 7 files show `**Status**: Finished`
- `status-aggregator-v2.1 46` shows 100%
- `status-aggregator-v2.1 49` shows 100%
- `cwf-manage validate` exits 0

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 67
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during retrospective*
