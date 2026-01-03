# Remove old v1.0 templates and files - Plan

## Task Reference
- **Task ID**: internal-10
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/10-remove-old-v1.0-templates-and-files
- **Template Version**: 2.0

## Goal
Remove 18 legacy v1.0 template files that are superseded by v2.0 symlink-based templates.

## Success Criteria
- [ ] All 18 v1.0 template files deleted
- [ ] All v2.0 symlinks remain functional
- [ ] `/cig-new-task` still creates tasks correctly
- [ ] No references to deleted files remain in codebase

## Original Estimate
**Effort**: <1 hour
**Complexity**: Low
**Dependencies**: None - standalone cleanup

## Major Milestones
1. **Identify files**: Locate all v1.0 template files (completed in planning)
2. **Delete files**: Remove 18 files across 4 directories
3. **Verify**: Confirm v2.0 system still works

## Risk Assessment
### Low Priority Risks
- **Accidental deletion of v2.0 files**: Could break task creation
  - **Mitigation**: Only delete files WITHOUT letter prefixes (a-h)

## Dependencies
- None

## Constraints
- Must preserve all v2.0 symlinks
- Must preserve historic task records in implementation-guide/

## Decomposition Check
- [x] **Time**: <1 hour - No decomposition needed
- [x] **People**: Single developer - No decomposition needed
- [x] **Complexity**: Simple file deletion - No decomposition needed
- [x] **Risk**: Low risk - No decomposition needed
- [x] **Independence**: N/A - No decomposition needed

**Decision**: Keep as single task

## Files to Delete (18 total)
### `.cig/templates/feature/` (7 files)
- design.md.template, implementation.md.template, maintenance.md.template
- plan.md.template, requirements.md.template, rollout.md.template, testing.md.template

### `.cig/templates/bugfix/` (4 files)
- implementation.md.template, plan.md.template, rollout.md.template, testing.md.template

### `.cig/templates/chore/` (4 files)
- implementation.md.template, maintenance.md.template, plan.md.template, validation.md.template

### `.cig/templates/hotfix/` (3 files)
- implementation.md.template, plan.md.template, rollout.md.template

## Status
**Status**: Finished
**Next Action**: N/A
**Blockers**: None

## Actual Results
Successfully identified and planned removal of 18 v1.0 template files. Exploration agent found all files coexisting with v2.0 symlinks. Pattern-based identification (absence of a-h letter prefix) made deletion criteria unambiguous.

## Lessons Learned
Thorough exploration before deletion prevented accidental omissions. Clear deletion pattern (no letter prefix = v1.0) eliminated ambiguity and risk.
