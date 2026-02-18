# Remove v1.0 category subdirectories from cwf-init - Plan
**Task**: 68 (hotfix)

## Task Reference
- **Task ID**: internal-68
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/68-remove-v1-0-category-subdirectories-from-cwf-init
- **Template Version**: 2.1

## Goal
Remove the obsolete v1.0 instruction to create `feature/`, `bugfix/`, `hotfix/`, `chore/` subdirectories inside `implementation-guide/` during `/cwf-init`, and update README.md Project Structure to reflect the current v2.1 layout.

## Success Criteria
- [ ] `cwf-init/SKILL.md` no longer instructs creation of category subdirectories under `implementation-guide/`
- [ ] `README.md` Project Structure block shows v2.1 layout (tasks directly under `implementation-guide/` with number prefixes)
- [ ] Both backlog entries for this issue removed (task 63 High + task 60 Medium)
- [ ] `cwf-manage validate` exits 0

## Original Estimate
**Effort**: Trivial (<1 session)
**Complexity**: Low
**Dependencies**: None

## Major Milestones
1. Remove category subdir instruction from SKILL.md
2. Update README.md Project Structure block
3. Remove both duplicate BACKLOG entries

## Risk Assessment
### Low Priority Risks
- **README Project Structure drift**: The block may be stale in other ways beyond category dirs
  - **Mitigation**: Read surrounding context and update only category-subdir references; flag other stale content as separate backlog item if found

## Dependencies
- None

## Constraints
- Skill file edit only (no logic changes to scripts)
- Do not touch `.cwf/templates/feature|bugfix|etc.` — those are legitimate template symlink dirs, not the v1.0 issue

## Decomposition Check
- [ ] **Time**: >1 week? — No
- [ ] **People**: >2 people? — No
- [ ] **Complexity**: 3+ distinct concerns? — No
- [ ] **Risk**: High-risk components? — No
- [ ] **Independence**: Parts separable? — No

No decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 68
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during retrospective*
