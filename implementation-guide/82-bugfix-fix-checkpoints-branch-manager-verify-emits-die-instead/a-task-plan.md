# Fix checkpoints-branch-manager verify emits die instead of warn on SIGPIPE - Plan
**Task**: 82 (bugfix)

## Task Reference
- **Task ID**: internal-82
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/82-fix-checkpoints-branch-manager-verify-emits-die-instead
- **Template Version**: 2.1

## Goal
Replace the fatal `die` in `verify_checkpoints_branch()` with a non-fatal `warn` so that SIGPIPE or other transient `git log` failures produce a warning rather than aborting the caller.

## Success Criteria
- [ ] `verify_checkpoints_branch()` emits a warning (not a fatal error) when `git log` exits non-zero
- [ ] Callers that previously received a fatal error now receive a non-zero exit code they can handle
- [ ] Existing `create` and `show-history` subcommands are unaffected
- [ ] Script hash in `.cwf/security/script-hashes.json` updated to match changed file

## Original Estimate
**Effort**: < 1 hour
**Complexity**: Low
**Dependencies**: None

## Major Milestones
1. **Fix**: Change `die` → `warn` in `verify_checkpoints_branch()`, add explicit `exit 1`
2. **Update hash**: Regenerate SHA256 in `script-hashes.json`
3. **Verify**: Confirm behaviour via manual test and security check

## Risk Assessment
### High Priority Risks
- None identified for a one-line change

### Medium Priority Risks
- **Hash drift**: Changing the script without updating `script-hashes.json` will fail `/cwf-security-check`
  - **Mitigation**: Update hash as part of the same commit

## Dependencies
- None external

## Constraints
- Change must not alter behaviour for non-error paths (branch exists, `git log` succeeds)

## Decomposition Check
- [x] **Time**: No — under 1 hour
- [x] **People**: No — single author
- [x] **Complexity**: No — single concern, one file
- [x] **Risk**: No — trivial change, no architectural impact
- [x] **Independence**: N/A

No decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 82
**Blockers**: None identified

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
