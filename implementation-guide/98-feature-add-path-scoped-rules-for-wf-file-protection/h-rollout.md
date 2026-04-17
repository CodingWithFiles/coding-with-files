# Add path-scoped rules for wf file protection - Rollout
**Task**: 98 (feature)

## Task Reference
- **Task ID**: internal-98
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/98-add-path-scoped-rules-for-wf-file-protection
- **Template Version**: 2.1

## Goal
Deploy path-scoped rules and updated install pipeline.

## Deployment Strategy
### Release Type
- **Strategy**: Direct merge — single-developer project, no staged rollout needed
- **Rationale**: Internal tooling with one user; rule file is advisory only
- **Rollback Plan**: `git revert` the squash commit on main, or delete `.claude/rules/cwf-workflow-files.md`

### Pre-Deployment Checklist
- [x] All tests passing (11/11 in g-testing-exec.md)
- [x] `cwf-manage validate` passes
- [x] install.bash syntax valid (`bash -n`)
- [x] Documentation updated (glossary: cwf- prefix, rule)
- [x] cwf-init updated with step 6b for rules directory

## Rollout Plan
### Phase 1: Merge to Main
- Squash commits on task branch
- Fast-forward main to squash commit
- Tag release

### Phase 2: Verify in Next Session
- Confirm rule auto-loads when agent touches wf step files
- Confirm rule text appears in system reminders

## Rollback Plan
### Triggers
- Rule causes agent to enter infinite skill-invocation loop
- Rule text is incorrect or misleading
- Glob pattern matches unintended files

### Procedure
1. Delete the symlink: `rm .claude/rules/cwf-workflow-files.md` (immediate relief)
2. `git revert` the squash commit on main if needed
3. No downstream consumers — rollback is self-contained

## Status
**Status**: Finished
**Next Action**: /cwf-maintenance 98
**Blockers**: None

## Actual Results
Pre-deployment checklist complete. Ready for merge after retrospective.

## Lessons Learned
Closing phases (h,i,j) were delayed because Task 99 was started before Task 98 was closed. Complete tasks sequentially to avoid context-switching overhead.
