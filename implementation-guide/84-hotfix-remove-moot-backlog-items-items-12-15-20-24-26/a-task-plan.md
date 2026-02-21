# Remove moot backlog items: items 12, 15, 20, 24, 26 - Plan
**Task**: 84 (hotfix)

## Task Reference
- **Task ID**: internal-84
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/84-remove-moot-backlog-items-items-12-15-20-24-26
- **Template Version**: 2.1

## Goal
Replace 8 moot/completed backlog items with HTML comments in BACKLOG.md, and correct the scope of one mis-specified item, to keep the backlog accurate and actionable.

## Success Criteria
- [x] Items 12, 15, 20, 24, 26 replaced with HTML removal comments (original plan)
- [x] Items "Automated Test Harness", "Security Review Bash Invocations", "Standardize Script Naming" replaced with HTML removal comments (extended scope)
- [x] Item "Remove Decomposition Checks" updated to correct scope (planning steps retain check; rollout/maintenance do not)
- [x] `grep -c "^## Task:\|^## Bug:" BACKLOG.md` reduced from 41 to 33
- [x] `cwf-manage validate` passes

## Original Estimate
**Effort**: 1 hour
**Complexity**: Low
**Dependencies**: None

## Major Milestones
1. **Identify**: Audit each questioned item against codebase reality
2. **Remove/Update**: Edit BACKLOG.md with HTML comments or corrected text
3. **Verify**: Validate counts and cwf-manage validate

## Risk Assessment
### Medium Priority Risks
- **Incorrect removal**: Removing an item that turns out to still be needed
  - **Mitigation**: Each removal documented with rationale in HTML comment; easy to restore from git

## Dependencies
- None

## Constraints
- Only remove items that are genuinely moot, completed, or superseded — not just low priority

## Decomposition Check
- [ ] **Time**: Will this take >1 week? No
- [ ] **People**: Does this need >2 people? No
- [ ] **Complexity**: Does this involve 3+ distinct concerns? No
- [ ] **Risk**: High-risk components? No
- [ ] **Independence**: Can parts be worked on separately? No

No decomposition needed.

## Status
**Status**: Finished
**Next Action**: Complete
**Blockers**: None

## Actual Results
Removed 8 moot items; corrected scope of 1 item. Backlog reduced from 41 to 33 open items.

## Lessons Learned
- Backlog should be audited periodically as architecture evolves; items accumulate faster than they're retired
- Plan mode should explicitly call for workflow skill invocations, not just list skill names as prose
