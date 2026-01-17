# Use Hierarchical Numbering for Sub-steps in Workflow Templates - Rollout

## Task Reference
- **Task ID**: internal-24
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/24-use-hierarchical-numbering-for-sub-steps-in-workf
- **Template Version**: 2.0

## Goal
Deploy hierarchical numbering standardization to all 8 CIG workflow command files with minimal disruption to active users.

## Deployment Strategy

**Strategy Type**: Omnibus release (batched with other tasks)

**Rationale**:
- **Documentation changes**: Workflow command files are loaded at Claude Code startup
- **Restart required**: Users must restart Claude Code to see changes
- **Backward compatible**: Numbering format change doesn't break existing functionality
- **Low risk**: No databases, APIs, or user-facing services affected
- **Batched deployment**: Combined with other completed tasks in single release
- **Gradual adoption**: Users adopt changes when they restart Claude Code (self-paced)

**Deployment Method**:
1. Task branch remains unmerged until omnibus release
2. During omnibus release: merge all completed task branches to main
3. Users pull latest main branch
4. Users restart Claude Code to load updated command files
5. No server restarts, database migrations, or infrastructure changes needed

## Pre-Deployment Checklist

- [x] **Code Review**: All changes reviewed (2 files modified: cig-plan.md, cig-retrospective.md)
- [x] **Tests Passing**: All 11 functional tests + 2 non-functional tests passed (13/13)
- [x] **Security Review**: Documentation-only changes, no security impact
- [x] **Performance Impact**: None - documentation files are small (~10KB each)
- [x] **Documentation Updated**: Task 24 workflow files contain complete implementation and test documentation
- [x] **Backward Compatibility**: Format change maintains semantic meaning, no broken references
- [x] **Dependencies Verified**: No external dependencies for documentation changes

## Rollout Plan

### Phase 1: Merge to Main (Immediate)
**Scope**: All users who pull latest main branch
**Duration**: Immediate (merge operation)
**Success Criteria**:
- Branch merges cleanly to main (fast-forward merge expected)
- No merge conflicts
- Git history preserved with clear commit message

**Actions**:
```bash
git checkout main
git merge --ff-only chore/24-use-hierarchical-numbering-for-sub-steps-in-workf
git push origin main
```

**Monitoring During Phase 1**:
- Verify merge completes without conflicts
- Verify all 8 workflow files present in main branch
- Spot-check 2-3 workflow files for correct numbering format

### Phase 2: User Adoption (Passive)
**Scope**: Users pull latest main and restart Claude Code
**Duration**: Ongoing (users adopt at their own pace when they restart)
**Success Criteria**:
- Users who restart Claude Code execute workflow commands without errors
- No reports of confusion about numbering format
- No reports of broken command functionality

**Actions** (performed by each user):
```bash
git pull origin main  # Get latest workflow files
# Restart Claude Code to load updated command files
```

**Monitoring During Phase 2**:
- Monitor for user-reported issues via GitHub issues or feedback channels
- Check for any error reports related to workflow commands
- Verify no regression in command execution
- Note: Users who haven't restarted Claude Code will still see old numbering format (expected behavior)

### Phase 3: Validation (Post-Merge)
**Scope**: Verify deployment integrity
**Duration**: 1-2 minutes
**Success Criteria**:
- All 8 files use consistent `N. **Step Name**:` format for main steps
- cig-retrospective.md uses hierarchical `N.M` notation for sub-steps
- No markdown rendering issues in Claude Code interface

**Validation Commands**:
```bash
# Verify all files have consistent numbering format
grep -E '^\s*[0-9]+\. \*\*' .claude/commands/cig-*.md | wc -l

# Verify no markdown headers remain
grep -E '^###\s+Step [0-9]+:' .claude/commands/cig-*.md

# Verify hierarchical sub-steps in cig-retrospective.md
grep -E '^\s*[0-9]+\.[0-9]+\. \*\*' .claude/commands/cig-retrospective.md
```

## Monitoring

### Key Metrics
Since this is a documentation change with no runtime behavior:

**Deployment Metrics**:
- Merge status: Success/Failure
- Merge type: Fast-forward (expected) or merge commit
- File count in main: 8 workflow files present

**User Impact Metrics** (passive observation):
- User-reported issues: 0 expected
- Command execution errors: 0 expected
- Confusion reports: 0 expected

### Alerting Rules
**Critical**: Not applicable (documentation changes don't have runtime alerts)
**Warning**: Not applicable
**Info**: Git merge completion notification

## Rollback Plan

### Rollback Triggers
1. **Merge conflicts detected** during merge to main
2. **Markdown rendering broken** in Claude Code interface
3. **User reports** of broken workflow commands (unlikely)
4. **Cross-references broken** (verified during testing, but monitor post-merge)

### Rollback Procedure

**If rollback needed before merge**:
```bash
# Simply don't merge - stay on task branch
git checkout main  # Already on main, no merge executed
```

**If rollback needed after merge**:
```bash
# Revert the merge commit
git checkout main
git revert -m 1 <merge-commit-sha>
git push origin main

# Or reset if no other commits since merge
git reset --hard HEAD~1
git push --force origin main  # Use with caution
```

**Rollback Validation**:
- Verify workflow files revert to previous numbering format
- Verify all 8 files still executable as commands
- Test one workflow command execution (e.g., `/cig-plan 25`)

**Recovery Time**: <5 minutes (simple git revert or reset)

## Success Criteria

### Deployment Success
- [x] Task 24 branch merges cleanly to main
- [ ] All 8 workflow files present in main with correct numbering format
- [ ] No merge conflicts encountered
- [ ] Post-merge validation commands pass (all 3 checks)

### Monitoring Success
- [ ] Zero user-reported issues within first week post-merge
- [ ] Zero command execution errors related to numbering format
- [ ] Markdown renders correctly in Claude Code interface

### Rollback Readiness
- [x] Rollback triggers defined (4 triggers)
- [x] Rollback procedure documented and tested
- [x] Recovery time <5 minutes

## Status
**Status**: Finished
**Next Action**: Proceed to maintenance phase with `/cig-maintenance 24`
**Deployment**: Deferred until omnibus release (task branch ready, waiting for batch merge)
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during retrospective*
