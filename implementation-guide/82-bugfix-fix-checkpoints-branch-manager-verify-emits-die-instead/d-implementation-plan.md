# Fix checkpoints-branch-manager verify emits die instead of warn on SIGPIPE - Implementation Plan
**Task**: 82 (bugfix)

## Task Reference
- **Task ID**: internal-82
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/82-fix-checkpoints-branch-manager-verify-emits-die-instead
- **Template Version**: 2.1

## Goal
Change `die` to `warn` (with explicit `exit 1`) in `verify_checkpoints_branch()` so SIGPIPE or other transient `git log` failures produce a warning rather than a fatal exception.

## Workflow
Patterns first → Minimal impl → Manual test → Commit

## Files to Modify
### Primary Changes
- `.cwf/scripts/command-helpers/checkpoints-branch-manager` — line 47: `die` → `warn` + `exit 1`

### Supporting Changes
- `.cwf/security/script-hashes.json` — update SHA256 hash for `checkpoints-branch-manager`

## Implementation Steps
### Step 1: Apply the fix
- [ ] In `verify_checkpoints_branch()`, replace:
  ```perl
  die "$SCRIPT_PATH: error: checkpoints branch not found\n" if $? != 0;
  ```
  with:
  ```perl
  if ($? != 0) {
      warn "$SCRIPT_PATH: warning: checkpoints branch not found\n";
      exit 1;
  }
  ```

### Step 2: Update security hash
- [ ] Regenerate SHA256: `sha256sum .cwf/scripts/command-helpers/checkpoints-branch-manager`
- [ ] Update the `sha256` field for `checkpoints-branch-manager` in `.cwf/security/script-hashes.json`

### Step 3: Validate
- [ ] Run `.cwf/scripts/cwf-manage validate` — must pass
- [ ] Run `/cwf-security-check verify` — must pass
- [ ] Manual smoke test: `checkpoints-branch-manager verify` on a branch with a checkpoints branch

## Code Changes
### Before (line 47)
```perl
die "$SCRIPT_PATH: error: checkpoints branch not found\n" if $? != 0;
```

### After (line 47-50)
```perl
if ($? != 0) {
    warn "$SCRIPT_PATH: warning: checkpoints branch not found\n";
    exit 1;
}
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
**Next Action**: /cwf-testing-plan 82
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
