# Remove obsolete Implemented status value - Design
**Task**: 69 (bugfix)

## Task Reference
- **Task ID**: internal-69
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/69-remove-obsolete-implemented-status-value
- **Template Version**: 2.1

## Goal
Define the precise removal points for `Implemented` across config, library, and docs.

## Affected Components

### 1. `implementation-guide/cwf-project.json`
Remove `"Implemented": 50` from `workflow.status-values`. This is the authoritative config consumed by `status_percent()` — removing it here makes `Implemented` unknown to the system immediately.

### 2. `.cwf/lib/CWF/TaskState.pm`
Four locations:
- **`%DEFAULT_STATUS_MAP`** (line 25): Remove `'Implemented' => 50`
- **`_is_active_work`** (line 311): Remove `|| $status eq 'Implemented'` — only `In Progress` and `Testing` represent active work in v2.1
- **Comment line 122**: Remove `Implemented` from the DORMANT/Active examples
- **POD line 169**: Remove `Implemented: 50%` from Default mappings documentation

### 3. `.cwf/docs/workflow/workflow-steps.md`
Remove `- **Implemented** (50%): Code complete, not yet tested` from the Status Values list.

### 4. `.cwf/security/script-hashes.json`
Regenerate SHA256 for `TaskState.pm` after edits.

### 5. `BACKLOG.md`
Retire "Add Status Field Review to Pre-Retrospective Checklist" (Task 35 retrospective, Low priority) — that item was a symptom workaround (check for stale `Implemented` before retrospective). This task fixes the root cause, making the workaround unnecessary.

## Design Decisions

### Why not keep Implemented as a transitional state?
In v2.0 a single file tracked both implementation and testing. `Implemented` meant "code done, tests pending". In v2.1 `f-implementation-exec.md` and `g-testing-exec.md` are separate files — `f` is either `In Progress` or `Finished`; there is no state where `f` should be partially done. `Implemented` has no valid meaning in v2.1.

### Why not deprecate instead of remove?
No existing workflow files use `Implemented` (pre-confirmed). Deprecation would leave a confusing status in the list that agents continue to misuse. Clean removal is correct.

### Is `Testing` (75%) the same problem?
No. `Testing` legitimately represents `g-testing-exec.md` mid-execution (tests running, not all passed). `Implemented` has no equivalent use — `f` has no valid intermediate state between `In Progress` and `Finished`.

### `_is_active_work` after removal
```perl
# Before:
return ($status eq 'In Progress' || $status eq 'Testing' || $status eq 'Implemented');
# After:
return ($status eq 'In Progress' || $status eq 'Testing');
```
Correct: only `In Progress` and `Testing` indicate a file with active ongoing work.

## Decomposition Check
- [ ] **Time**: >1 week? — No
- [ ] **People**: >2 people? — No
- [ ] **Complexity**: 3+ distinct concerns? — No
- [ ] **Risk**: High-risk? — No
- [ ] **Independence**: Separable? — No

No decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 69
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during retrospective*
