# Add status update instruction to wf step skills before checkpoint commit - Plan
**Task**: 83 (hotfix)

## Task Reference
- **Task ID**: internal-83
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/83-add-status-update-instruction-to-wf-step-skills-befor
- **Template Version**: 2.1

## Goal
Add a "set Status: Finished" instruction to `checkpoint-commit.md` so all workflow step skills consistently update the current file's status before staging and committing.

## Success Criteria
- [ ] `checkpoint-commit.md` has an explicit step to set `**Status**: Finished` before staging
- [ ] The instruction is positioned as the first step (before `git add`)
- [ ] All workflow step skills that reference `checkpoint-commit.md` inherit the fix automatically (no per-skill edits needed)

## Original Estimate
**Effort**: < 30 minutes
**Complexity**: Low
**Dependencies**: None

## Major Milestones
1. **Fix**: Add status-update step to `checkpoint-commit.md`
2. **Verify**: Confirm wording is clear and consistent with existing doc style

## Risk Assessment
### High Priority Risks
- None — single doc edit, no code changes

### Medium Priority Risks
- **Wording ambiguity**: Instruction could be misread as applying to files other than the current workflow file
  - **Mitigation**: Be explicit — "set `**Status**: Finished` in the current phase's workflow file"

## Dependencies
- None

## Constraints
- Must not require edits to individual skill files — the fix must flow from `checkpoint-commit.md` alone

## Decomposition Check
- [x] **Time**: No — under 30 minutes
- [x] **People**: No — single author
- [x] **Complexity**: No — one doc, one addition
- [x] **Risk**: No — documentation only
- [x] **Independence**: N/A

No decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 83
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
