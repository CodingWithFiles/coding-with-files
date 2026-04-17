# Add PreToolUse hook for rule re-injection - Rollout
**Task**: 99 (feature)

## Task Reference
- **Task ID**: internal-99
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/99-add-pretooluse-hook-for-rule-re-injection
- **Template Version**: 2.1

## Goal
Deploy the rules injection hook and updated install pipeline.

## Deployment Strategy
### Release Type
- **Strategy**: Direct merge — single-developer project, no staged rollout needed
- **Rationale**: Internal tooling with one user; changes are immediately testable
- **Rollback Plan**: `git revert` the squash commit on main

### Pre-Deployment Checklist
- [x] All tests passing (8/8 in g-testing-exec.md)
- [x] `cwf-manage validate` passes
- [x] install.bash syntax valid (`bash -n`)
- [x] Simplify review completed — no quality issues remaining
- [x] Documentation updated (glossary: hook, rules injection)

## Rollout Plan
### Phase 1: Merge to Main
- Squash commits on task branch
- Fast-forward main to squash commit
- Tag release

### Phase 2: Verify in Next Session
- Confirm hook fires on user messages (rules appear as system reminder)
- Confirm rules survive context compaction in long sessions

## Rollback Plan
### Triggers
- Hook causes errors or blocks tool use
- Rules content is incorrect or misleading
- Token cost is higher than expected

### Procedure
1. Remove hook from `.claude/settings.json` (immediate relief)
2. `git revert` the squash commit on main if needed
3. No downstream consumers — rollback is self-contained

## Status
**Status**: Finished
**Next Action**: /cwf-maintenance 99
**Blockers**: None

## Actual Results
Pre-deployment checklist complete. Ready for merge after retrospective.

## Lessons Learned
- Direct merge strategy is appropriate for single-developer internal tooling
