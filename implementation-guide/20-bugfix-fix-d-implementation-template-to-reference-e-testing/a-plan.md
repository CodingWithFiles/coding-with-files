# fix-d-implementation-template-to-reference-e-testing - Plan

## Task Reference
- **Task ID**: internal-20
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/20-fix-d-implementation-template-to-reference-e-testing
- **Template Version**: 2.0

## Goal
Remove duplicate "Test Coverage" and "Validation Criteria" sections from d-implementation.md template to establish e-testing.md as single source of truth for testing.

## Success Criteria
- [ ] Lines 67-70 (Test Coverage section) replaced with reference to e-testing.md
- [ ] Lines 72-76 (Validation Criteria section) replaced with reference to e-testing.md
- [ ] Template change verified not to break template substitution
- [ ] Only template modified (no migration of existing 20 tasks)

## Original Estimate
**Effort**: < 1 hour
**Complexity**: Low
**Dependencies**: None - simple template text replacement

## Major Milestones
1. **Identify duplicate sections**: Locate lines 67-70 and 72-76 in d-implementation.md.template
2. **Replace with references**: Update with static text pointing to e-testing.md
3. **Verify template integrity**: Confirm template substitution still works

## Risk Assessment
### High Priority Risks
None - extremely low-risk template text change

### Medium Priority Risks
- **Template substitution breaks**: Replacement text could interfere with {{variable}} substitution
  - **Mitigation**: Use plain text references, no template variables in replacement

### Low Priority Risks
- **Confusion about testing location**: Users might expect tests in d-implementation.md
  - **Mitigation**: Clear references pointing to e-testing.md, maintain Step 3: Testing reference

## Dependencies
- All 5 task types must use e-testing.md.template (already verified in backlog)
- No external dependencies

## Constraints
- Must NOT modify existing 20 tasks (only affect future task creation)
- Must maintain template variable substitution compatibility
- Must preserve "Implementation Steps" structure (Steps 3 and 5 reference e-testing.md)
- Only modify `.cig/templates/pool/d-implementation.md.template`

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **No** - estimated < 1 hour
- [ ] **People**: Does this need >2 people working on different parts? **No** - single file edit
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **No** - two section replacements in one file
- [ ] **Risk**: Are there high-risk components that need isolation? **No** - low risk template change
- [ ] **Independence**: Can parts be worked on separately? **No** - atomic change to one file

**Decomposition Decision**: No subtasks needed - simple template maintenance bugfix

## Status
**Status**: Finished
**Next Action**: Proceed to retrospective
**Blockers**: None

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
