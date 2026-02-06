# Fix CIG Commands to Work from Any Directory - Plan

## Task Reference
- **Task ID**: internal-36
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/36-fix-cig-commands-to-work-from-any-directory
- **Template Version**: 2.1

## Goal
Fix all CIG commands to work from any directory by adding git root detection, preventing workflow interruptions when Claude's working directory changes.

## Success Criteria
- [ ] All 17 CIG commands work from repository root (baseline - already works)
- [ ] All 17 CIG commands work from task subdirectories (e.g., `implementation-guide/36-bugfix-...`)
- [ ] Commands fail gracefully with clear error when run outside git repository
- [ ] Working directory changes are communicated to user/LLM
- [ ] No regression in existing command functionality

## Original Estimate
**Effort**: 2-3 hours
**Complexity**: Low
**Dependencies**: None (self-contained fix)

## Major Milestones
1. **Design Approach**: Decide between Option A (dynamic paths) vs Option B (cd to root)
2. **Update Commands**: Apply git root detection to all 17 command files
3. **Test & Validate**: Verify commands work from multiple directory contexts

## Risk Assessment
### Low Priority Risks
- **Risk: Breaking existing workflows**: Commands currently work from root, changes could introduce regressions
  - **Mitigation**: Test from repository root first to ensure baseline works, then test from subdirectories

- **Risk: LLM confusion from directory changes**: If using cd approach, LLM might lose track of working directory
  - **Mitigation**: Echo new working directory clearly: "Working directory: /path/to/repo"

## Dependencies
- None - all commands are self-contained
- Git must be available (already required for CIG)

## Constraints
- Must maintain backward compatibility (commands work from root)
- Must not require changes to helper scripts
- Should communicate directory changes to user/LLM clearly
- Git-only assumption acceptable (CIG already requires git)

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **No** - 2-3 hours estimated
- [ ] **People**: Does this need >2 people working on different parts? **No** - single developer task
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **No** - single concern (working directory handling)
- [ ] **Risk**: Are there high-risk components that need isolation? **No** - low risk, easily testable
- [ ] **Independence**: Can parts be worked on separately? **No** - all commands need same fix

**Analysis**: 0/5 signals triggered. This is a straightforward bugfix that should remain as a single task.

## Status
**Status**: Finished
**Next Action**: Move to design planning → `/cig-design-plan 36`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
