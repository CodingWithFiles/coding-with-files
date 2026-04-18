# Add Status Update Helper Script (cwf-set-status) - Implementation Plan
**Task**: 101 (feature)

## Task Reference
- **Task ID**: internal-101
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/101-add-status-update-helper-script-cwf-set-s
- **Template Version**: 2.1

## Goal
Implement Add Status Update Helper Script (cwf-set-status) following the approved design and requirements.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify

### Create
- `.cwf/scripts/command-helpers/cwf-set-status` — The helper script itself

### Modify
- `.cwf/security/script-hashes.json` — Add SHA256 hash and permissions entry for new script

## Implementation Steps

### Step 1: Write the Script
- [ ] Create `.cwf/scripts/command-helpers/cwf-set-status` (Perl, ~45 lines)
- [ ] Argument parsing: exactly 2 positional args, usage message on wrong count
- [ ] Read config via relative path, extract valid status names
- [ ] Validate new-status against valid set
- [ ] Slurp file, regex match, idempotency check, replace, write back
- [ ] `chmod 0755`

### Step 2: Update Security Hashes
- [ ] Compute SHA256: `sha256sum .cwf/scripts/command-helpers/cwf-set-status`
- [ ] Add entry to `.cwf/security/script-hashes.json`
- [ ] Run `cwf-manage validate` to confirm

### Step 3: Manual Smoke Test
- [ ] Test on a real wf file: update Backlog → In Progress
- [ ] Verify idempotent re-run
- [ ] Verify invalid status rejection
- [ ] Verify file-not-found error
- [ ] Revert the test file changes

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
**Next Action**: /cwf-testing-plan 101
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
