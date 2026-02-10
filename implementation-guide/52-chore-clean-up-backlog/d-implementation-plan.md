# clean-up-backlog - Implementation Plan
**Task**: 52 (chore)

## Task Reference
- **Task ID**: internal-52
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/52-clean-up-backlog
- **Template Version**: 2.1

## Goal
Remove 3 obsolete BACKLOG items that have already been completed in previous tasks.

## Workflow
Locate items → Remove with Edit tool → Verify formatting → Commit

## Files to Modify
### Primary Changes
- `BACKLOG.md` - Remove 3 completed items

### Supporting Changes
None - single file change

## Implementation Steps

### Step 1: Locate Obsolete Items
- [ ] Find "Update cig-status to Use --workflow Flag" in BACKLOG.md
- [ ] Find "Update Task 32 Tests for New Inference Output Format" in BACKLOG.md
- [ ] Find "Add 'Create Task Branch' Step to Implementation Execution" in BACKLOG.md
- [ ] Note line numbers for each item

### Step 2: Remove Items
- [ ] Remove "Update cig-status to Use --workflow Flag" (including separator)
  - Reason: cig-status already uses workflow-manager status with auto --workflow
- [ ] Remove "Update Task 32 Tests for New Inference Output Format" (including separator)
  - Reason: Task 32 tests already verify new structured format (task_num, task_slug)
- [ ] Remove "Add 'Create Task Branch' Step to Implementation Execution" (including separator)
  - Reason: /cig-new-task already creates branch automatically

### Step 3: Verify BACKLOG Integrity
- [ ] Check BACKLOG.md still has proper markdown structure
- [ ] Verify no orphaned separators (---)
- [ ] Ensure remaining items are properly formatted

### Step 4: Commit Changes
- [ ] Stage BACKLOG.md
- [ ] Create commit with "why" explanation (BACKLOG had obsolete completed items)

## Code Changes

### Item 1: "Update cig-status to Use --workflow Flag"

**Evidence of Completion**:
```bash
# From .claude/commands/cig-status.md line 36:
- **With task argument**: Calls `workflow-manager status [task-path]` (auto-enables --workflow)
```

**Action**: Remove entire section including separator

### Item 2: "Update Task 32 Tests for New Inference Output Format"

**Evidence of Completion**:
```bash
# From Task 32 g-testing-exec.md line 48:
| TC-I1 | Default mode | task_num: 32
task_slug: task-tracking-using-inference-scoring
workflow_step: a-task-plan | PASS |
```

**Action**: Remove entire section including separator

### Item 3: "Add 'Create Task Branch' Step to Implementation Execution"

**Evidence of Completion**:
```bash
# From .claude/commands/cig-new-task.md Step 6:
### 6. Create Git Branch
After template copier succeeds, automatically create and checkout the branch:
git checkout -b "{branch-name}"
```

**Action**: Remove entire section including separator

## Test Coverage
**See e-testing-plan.md for complete test plan**

No code tests needed - documentation-only change.
Validation will verify:
- BACKLOG.md structure is valid markdown
- No duplicate items
- Remaining items are properly formatted

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

**Quick Validation**:
- [ ] 3 items removed from BACKLOG.md
- [ ] BACKLOG.md renders correctly as markdown
- [ ] grep confirms items no longer in file
- [ ] No orphaned separators or formatting issues

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cig-testing-plan 52
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
