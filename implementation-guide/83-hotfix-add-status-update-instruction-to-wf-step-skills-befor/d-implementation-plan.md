# Add status update instruction to wf step skills before checkpoint commit - Implementation Plan
**Task**: 83 (hotfix)

## Task Reference
- **Task ID**: internal-83
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/83-add-status-update-instruction-to-wf-step-skills-befor
- **Template Version**: 2.1

## Goal
Prepend a "set Status: Finished" step to `checkpoint-commit.md` so every workflow step skill prompts the LLM to update the current file's status before staging.

## Files to Modify
### Primary Changes
- `.cwf/docs/skills/checkpoint-commit.md` — add step 1: set `**Status**: Finished` in the current phase file before staging

### Supporting Changes
- None

## Implementation Steps
### Step 1: Edit checkpoint-commit.md
- [ ] Insert new step before the existing "Stage" step:
  ```
  1. **Update status** in the current phase's workflow file:
     Set `**Status**: Finished` (and update `**Next Action**` if needed)
     before staging — this keeps `cwf-status` accurate throughout the task.
  ```
- [ ] Renumber existing steps 1→2, 2→3, 3→4, 4→5

## Document Changes
### Before (steps 1-4)
```
1. **Stage** the workflow file …
2. **Commit** with a "why"-focused message …
3. **Rationale** …
4. **Validate** …
```

### After (steps 1-5)
```
1. **Update status** in the current phase's workflow file …
2. **Stage** the workflow file …
3. **Commit** with a "why"-focused message …
4. **Rationale** …
5. **Validate** …
```

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

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
**Next Action**: /cwf-testing-plan 83
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
