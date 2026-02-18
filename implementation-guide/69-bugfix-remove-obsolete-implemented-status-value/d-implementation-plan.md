# Remove obsolete Implemented status value - Implementation Plan
**Task**: 69 (bugfix)

## Task Reference
- **Task ID**: internal-69
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/69-remove-obsolete-implemented-status-value
- **Template Version**: 2.1

## Goal
Remove `Implemented` from all 5 locations: cwf-project.json, TaskState.pm (4 spots), workflow-steps.md, script-hashes.json, and retire the BACKLOG workaround item.

## Files to Modify

| File | Change |
|------|--------|
| `implementation-guide/cwf-project.json` | Remove `"Implemented": 50` line |
| `.cwf/lib/CWF/TaskState.pm` | 4 edits (DEFAULT_STATUS_MAP, `_is_active_work`, comment line 122, POD line 169) |
| `.cwf/docs/workflow/workflow-steps.md` | Remove `Implemented` bullet from Status Values |
| `.cwf/security/script-hashes.json` | Regenerate SHA256 for TaskState.pm |
| `BACKLOG.md` | Retire "Add Status Field Review to Pre-Retrospective Checklist" |

## Implementation Steps

### Step 1: `cwf-project.json` — remove `Implemented`
```json
// Remove this line:
"Implemented": 50,
```

### Step 2: `TaskState.pm` — 4 edits

**Edit 1**: `%DEFAULT_STATUS_MAP` — remove entry:
```perl
# Remove:
'Implemented' => 50,
```

**Edit 2**: `_is_active_work` — remove from predicate:
```perl
# Before:
return ($status eq 'In Progress' || $status eq 'Testing' || $status eq 'Implemented');
# After:
return ($status eq 'In Progress' || $status eq 'Testing');
```

**Edit 3**: POD comment (line ~169) — remove from default mappings list:
```
# Remove: "Implemented: 50%" from Default mappings bullet
```

**Edit 4**: `state_achievable` POD (line ~122) — remove from Active rule description:
```
# Before: Active (has In Progress/Testing/Implemented) → completion (linear ramp)
# After:  Active (has In Progress/Testing) → completion (linear ramp)
```

### Step 3: `workflow-steps.md` — remove bullet
```markdown
# Remove:
- **Implemented** (50%): Code complete, not yet tested
```

### Step 4: Regenerate script hash for TaskState.pm
```bash
perl -I.cwf/lib .cwf/scripts/cwf-manage validate
# If hash mismatch, update .cwf/security/script-hashes.json
sha256sum .cwf/lib/CWF/TaskState.pm
```

### Step 5: Retire BACKLOG item
Remove "Add Status Field Review to Pre-Retrospective Checklist" entry, replace with completed HTML comment.

## Validation Criteria
- `grep "Implemented" implementation-guide/cwf-project.json` → no matches
- `grep "Implemented" .cwf/lib/CWF/TaskState.pm` → no matches (except this task's own workflow files)
- `grep "Implemented" .cwf/docs/workflow/workflow-steps.md` → no matches
- `cwf-manage validate` exits 0

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 69
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during retrospective*
