# fix-deferred-docs-and-avoid-future-deferrals - Plan

## Task Reference
- **Task ID**: internal-38
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/38-fix-deferred-docs-and-avoid-future-deferrals
- **Template Version**: 2.1

## Goal
Complete Task 37's deferred documentation and prevent future tasks from deferring implementation scope.

## Success Criteria
- [ ] `.cig/docs/context/state-tracking.md` updated with Task 37's new inference output format
- [ ] `.cig/docs/context/state-tracking.md` refactored to be significantly more compact
- [ ] `d-implementation-plan.md` template updated with strong guidance against deferring implementation
- [ ] `f-implementation-exec.md` template updated to prompt user feedback if work must be deferred
- [ ] Templates emphasize completing all planned implementation before marking task finished

## Original Estimate
**Effort**: 2-3 hours (documentation update + template improvements)
**Complexity**: Low (documentation and template updates, no code changes)
**Dependencies**: Task 37 (provides the new output format to document)

## Major Milestones
1. **Update state-tracking.md**: Document new inference output format and refactor for compactness
2. **Update implementation templates**: Add strong guidance against deferring work
3. **Test and validate**: Verify documentation clarity and template effectiveness

## Risk Assessment
### Medium Priority Risks
- **Documentation becomes outdated again**: state-tracking.md could diverge from implementation over time
  - **Mitigation**: Add automated tests that verify documented output format matches actual TaskContextInference.pm output
- **Template guidance too prescriptive**: Overly strict guidance might reduce flexibility for edge cases
  - **Mitigation**: Use "strongly advise" language with "get user feedback if..." clause for legitimate deferrals
- **Refactoring state-tracking.md loses important details**: Making it more compact might remove useful information
  - **Mitigation**: Review current content carefully, preserve essential technical details

### Low Priority Risks
- **Templates not followed**: Developers might ignore the new guidance
  - **Mitigation**: Clear rationale explanation (Task 37 example) shows why this matters

## Dependencies
- **Task 37**: Provides the new inference output format that needs documenting
- **No blocking dependencies**: Can proceed immediately

## Constraints
- **Backward compatibility**: Documentation must describe both old and new behavior during migration period
- **Compact format**: state-tracking.md refactor must significantly reduce verbosity while preserving accuracy
- **Template scope**: Changes limited to d-implementation-plan.md and f-implementation-exec.md templates only

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **No** - Estimated 2-3 hours total
- [ ] **People**: Does this need >2 people working on different parts? **No** - Single developer task
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **No** - 2 concerns (docs update, template update)
- [ ] **Risk**: Are there high-risk components that need isolation? **No** - Low risk documentation changes
- [ ] **Independence**: Can parts be worked on separately? **No** - Both parts are small and closely related

**Analysis**: 0/5 signals triggered. Task is appropriately scoped as a single bugfix. The two parts (documentation and templates) are tightly coupled (both address the same underlying issue from Task 37) and small enough to complete together.

## Status
**Status**: Finished
**Next Action**: Move to design planning → `/cig-design-plan 38`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
