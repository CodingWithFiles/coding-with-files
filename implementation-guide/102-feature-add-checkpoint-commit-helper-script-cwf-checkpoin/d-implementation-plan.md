# Add Checkpoint Commit Helper Script (cwf-checkpoint-commit) - Implementation Plan
**Task**: 102 (feature)

## Task Reference
- **Task ID**: internal-102
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/102-add-checkpoint-commit-helper-script-cwf-checkpoin
- **Template Version**: 2.1

## Goal
Implement the `cwf-checkpoint-commit` helper script and update `checkpoint-commit.md`.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify

### Create
- `.cwf/scripts/command-helpers/cwf-checkpoint-commit` — New helper script (~30 lines Perl)

### Modify
- `.cwf/docs/skills/checkpoint-commit.md` — Document script as primary method
- `.cwf/security/script-hashes.json` — Register SHA256 hash

## Implementation Steps

### Step 1: Write the script
- [ ] Create script following `cwf-set-status` pattern (args → resolve → act → report)
- [ ] Validate 3 args, resolve task, glob wf file, status_set, git add, git commit -m, cwf-manage validate (warn only)
- [ ] Set permissions 0700

### Step 2: Register security hash
- [ ] Add SHA256 to `.cwf/security/script-hashes.json`

### Step 3: Update checkpoint-commit.md
- [ ] Add script usage as primary method
- [ ] Keep existing manual steps as reference

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
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
