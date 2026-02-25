# Fix stale repo URL in install.bash — Plan
**Task**: 94 (bugfix)

## Task Reference
- **Task ID**: internal-94
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/94-fix-stale-repo-url-in-install-bash
- **Template Version**: 2.1

## Goal
Replace the hardcoded `mattkeenan/coding-with-files` GitHub URL in `scripts/install.bash` with the current `CodingWithFiles/coding-with-files` URL so that installs from the default source work correctly.

## Success Criteria
- [ ] `scripts/install.bash` references `CodingWithFiles/coding-with-files.git`, not `mattkeenan/coding-with-files.git`
- [ ] No other files contain the stale `mattkeenan` org reference
- [ ] Install script smoke-tested to confirm the URL resolves

## Original Estimate
**Effort**: < 1 hour
**Complexity**: Low
**Dependencies**: None

## Major Milestones
1. **Fix**: Update the single line in `scripts/install.bash`
2. **Audit**: Grep codebase for any other `mattkeenan` references
3. **Verify**: Confirm corrected URL is reachable

## Risk Assessment
### Medium Priority Risks
- **Other stale references**: The `mattkeenan` org name may appear elsewhere (docs, README, other scripts)
  - **Mitigation**: Full codebase grep before closing task

## Dependencies
- None

## Constraints
- URL must remain HTTPS (not SSH) — install.bash is run by end users who may not have SSH keys configured

## Decomposition Check
- [ ] **Time**: No — < 1 hour
- [ ] **People**: No — single change
- [ ] **Complexity**: No — one concern
- [ ] **Risk**: No — low risk
- [ ] **Independence**: No — atomic change

No decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 94
**Blockers**: None

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
