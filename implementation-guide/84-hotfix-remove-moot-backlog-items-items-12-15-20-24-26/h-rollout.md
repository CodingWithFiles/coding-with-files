# Remove moot backlog items: items 12, 15, 20, 24, 26 - Rollout
**Task**: 84 (hotfix)

## Task Reference
- **Task ID**: internal-84
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/84-remove-moot-backlog-items-items-12-15-20-24-26
- **Template Version**: 2.1

## Goal
Merge the BACKLOG.md cleanup to main.

## Deployment Strategy
- **Strategy**: Direct merge to main (documentation-only change, no code risk)
- **Rationale**: BACKLOG.md edits are fully reversible via git revert; no runtime impact
- **Rollback Plan**: `git revert <merge-sha>` restores removed items instantly

## Pre-Deployment Checklist
- [x] All 6 test cases passing
- [x] `cwf-manage validate` OK
- [x] No scripts, hashes, or executable files modified
- [x] Each removal documented with rationale in HTML comment

## Rollout Plan
Single step — merge branch to main. No phased rollout needed for a documentation edit.

## Rollback Plan
### Triggers
- A removed item turns out to still be needed

### Procedure
1. `git revert <merge-sha>` to restore all removed blocks
2. Re-evaluate which items to keep before re-applying

## Success Criteria
- [x] Branch merged to main
- [x] `cwf-manage validate` passes on main

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 84
**Blockers**: None

## Actual Results
Branch merged to main via `git branch -f main <sha>` per project convention.
