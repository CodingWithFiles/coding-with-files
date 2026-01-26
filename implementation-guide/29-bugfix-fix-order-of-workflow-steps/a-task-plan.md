# Fix order of workflow steps - Plan

## Task Reference
- **Task ID**: internal-29
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/29-fix-order-of-workflow-steps
- **Template Version**: 2.0

## Goal
Fix v2.1 workflow file naming to place test planning (e-testing-plan.md) before implementation execution (f-implementation-exec.md) and update all "Next Step" references accordingly.

## Success Criteria
- [ ] Template files renamed: e-testing-plan.md, f-implementation-exec.md
- [ ] Template symlinks updated for all task types (feature, bugfix, hotfix, chore, discovery)
- [ ] template-copier creates files with correct names for new v2.1 tasks
- [ ] status-aggregator-v2.1 recognizes all 10 files in correct order
- [ ] All "Next Action" references in templates point to correct next step
- [ ] All workflow commands suggest correct next step
- [ ] Documentation updated to reflect correct order (workflow-steps.md, workflow-overview.md)
- [ ] Existing v2.1 tasks (25, 26) migrated to new naming via script
- [ ] New v2.1 tasks created with correct file order
- [ ] Workflow follows test-first approach: plan tests BEFORE executing implementation

## Original Estimate
**Effort**: 2-3 days
**Complexity**: Medium (file renaming + reference updates across multiple components)
**Dependencies**: None (internal CIG system refactoring)

## Major Milestones
1. **Phase 1: File Renaming**: Rename template files and update all symlinks (~1 day)
2. **Phase 2: Reference Updates**: Fix all "Next Step" references in templates, commands, and docs (~1 day)
3. **Phase 3: Migration**: Create and run migration script for Tasks 25, 26 (~0.5 day)
4. **Phase 4: Validation**: Test new task creation and workflow progression (~0.5 day)

## Risk Assessment
### High Priority Risks
- **Risk 1: Breaking existing v2.1 tasks (Tasks 25, 26)**
  - **Impact**: High - status-aggregator won't find files, workflow broken
  - **Mitigation**: Create migration script, test on Task 25 first, document rollback procedure (git revert)

### Medium Priority Risks
- **Risk 2: Confusion during transition**
  - **Impact**: Medium - users/LLM may reference old file names (e-implementation-exec)
  - **Mitigation**: Clear communication in commit message, update CHANGELOG, add note to workflow docs

- **Risk 3: Internal cross-references break**
  - **Impact**: Medium - workflow files may reference each other by name
  - **Mitigation**: Migration script updates internal references, manual review of all templates

### Low Priority Risks
- **Risk 4: Incomplete reference updates**
  - **Impact**: Low - some docs/comments may still reference old order
  - **Mitigation**: Comprehensive grep for "e-implementation-exec" and "f-testing-plan" before finalizing

## Dependencies
- Task 25 architecture (trampoline pattern, template-copier, status-aggregator-v2.1)
- Existing v2.1 tasks (25, 26) need migration
- No external dependencies or coordination needed

## Constraints
- Must maintain backward compatibility for v2.0 tasks (8-file format unaffected)
- Must not break existing non-v2.1 workflows during transition
- File renaming creates breaking change for in-progress v2.1 tasks (acceptable for 2 tasks)
- Philosophy: Test planning as thinking tool (not traditional TDD)

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **No** - estimated 2-3 days
- [ ] **People**: Does this need >2 people working on different parts? **No** - single developer
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **Yes** - file renaming, reference updates, migration, but all tightly coupled
- [ ] **Risk**: Are there high-risk components that need isolation? **No** - risks are mitigated with migration script and testing
- [ ] **Independence**: Can parts be worked on separately? **No** - phases must be sequential (rename → update refs → migrate)

**Decomposition Decision**: No decomposition needed. While complexity signal is triggered (3 concerns: rename, refs, migrate), the concerns are tightly coupled and must be done sequentially. Total effort is <1 week with single developer. Breaking into subtasks would add overhead without benefit.

## Status
**Status**: Finished
**Next Action**: Task complete, ready for retrospective → `/cig-retrospective 29`
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
