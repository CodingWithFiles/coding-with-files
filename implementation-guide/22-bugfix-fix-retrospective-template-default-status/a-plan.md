# fix-retrospective-template-default-status - Plan

## Task Reference
- **Task ID**: internal-22
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/22-fix-retrospective-template-default-status
- **Template Version**: 2.0

## Goal
Fix h-retrospective.md template to use "Backlog" default status instead of "Finished", preventing false 100% completion reports.

## Success Criteria
- [ ] Template status changed from "Finished" to "Backlog"
- [ ] Template includes "Next Action" and "Blockers" fields consistent with other templates
- [ ] Template substitution verified to work correctly
- [ ] New tasks created from template show "Backlog" status by default
- [ ] status-aggregator.pl correctly reports 0% for new tasks until retrospective is complete

## Original Estimate
**Effort**: <1 hour (simple template file edit)
**Complexity**: Low - single file change with clear solution
**Dependencies**: None - self-contained template fix

## Major Milestones
1. **Template file identified and edited**: Change status default in `.cig/templates/pool/h-retrospective.md.template`
2. **Verification complete**: Confirm template substitution works and new tasks show correct default

## Risk Assessment
### High Priority Risks
None - low-risk template fix

### Medium Priority Risks
- **Template substitution break**: Changing status field format might break template variable substitution
  - **Mitigation**: Review template-copier.pl to ensure status field is not substituted, verify with test task creation

## Dependencies
- None - template file is self-contained
- No coordination needed with other tasks

## Constraints
- Must maintain template format compatibility with template-copier.pl
- Must not break existing tasks that already use the template
- Change only affects new tasks created after the fix

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **No** - estimated <1 hour
- [ ] **People**: Does this need >2 people working on different parts? **No** - single file edit
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **No** - one concern (template status default)
- [ ] **Risk**: Are there high-risk components that need isolation? **No** - low-risk template change
- [ ] **Independence**: Can parts be worked on separately? **No** - atomic change to one file

**Decomposition Decision**: No subtasks needed - simple, focused bugfix

## Status
**Status**: Finished
**Next Action**: Skip to design phase (bugfix workflow: plan → design → implementation → testing → retrospective)
**Blockers**: None identified

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
