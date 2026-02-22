# Refactor workflow docs for efficiency - Plan
**Task**: 88 (bugfix)

## Task Reference
- **Task ID**: internal-88
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/88-refactor-workflow-docs-for-efficiency
- **Template Version**: 2.1

## Goal
Eliminate duplicated content and off-piste file-edit instructions from CWF workflow docs, replacing them with canonical references (progressive disclosure), to reduce token consumption and enforce skill-based methodology.

## Success Criteria
- [ ] No `perl -I` in `checkpoint-commit.md`; all placeholder variables use `{}` not `<>` in both skill docs
- [ ] Each of 8 phases in `workflow-steps.md` references `checkpoint-commit.md` instead of repeating the commit block
- [ ] No `**Typical Structure**` headings in `workflow-steps.md`; each phase references the template pool
- [ ] No `jq -r` blocks in `workflow-steps.md`
- [ ] All Reversion Guidance sections in `blocker-patterns.md` use `/cwf-` skill calls, not file-edit instructions
- [ ] Decomposition Signals section in `blocker-patterns.md` references `decomposition-guide.md` (not duplicated)
- [ ] No `.claude/commands/` references in `blocker-patterns.md`
- [ ] `cwf-manage validate` passes

## Original Estimate
**Effort**: 0.5 days
**Complexity**: Low
**Dependencies**: None — all changes are to documentation files

## Major Milestones
1. **Milestone 1**: Fix placeholder syntax and stale command in skill docs (`checkpoint-commit.md`, `retrospective-extras.md`)
2. **Milestone 2**: Simplify `workflow-steps.md` (checkpoint blocks → references, structure sections → references, jq blocks removed)
3. **Milestone 3**: Simplify `blocker-patterns.md` (boilerplate removed, file-edits → skill calls, decomposition reference, stale refs removed)
4. **Milestone 4**: Simplify `decomposition-guide.md` (context inheritance section → reference)
5. **Milestone 5**: All tests pass, `cwf-manage validate` passes

## Risk Assessment
### High Priority Risks
- **Risk**: Accidental removal of content with no replacement reference
  - **Mitigation**: Plan specifies exact replacement text for every removal; tests verify reference chains

### Medium Priority Risks
- **Risk**: `workflow-steps.md` phase references to checkpoint-commit.md break if that file moves
  - **Mitigation**: File is stable; path is relative and consistent with existing doc conventions

## Dependencies
- None external

## Constraints
- Removed content must be replaced by a reference (progressive disclosure preserved)
- `cwf-manage validate` must pass after changes

## Decomposition Check
- [ ] **Time**: No — half day or less
- [ ] **People**: No — single author
- [ ] **Complexity**: No — mechanical find-and-replace with clear spec; no distinct concerns that need isolation
- [ ] **Risk**: No — documentation only, no code changes
- [ ] **Independence**: N/A

No decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 88
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
