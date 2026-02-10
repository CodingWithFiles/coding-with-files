# dead-code-removal - Plan
**Task**: 51 (bugfix)

## Task Reference
- **Task ID**: internal-51
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/51-dead-code-removal
- **Template Version**: 2.1

## Goal
Remove 4 confirmed dead functions (~160 lines) from CIG Perl library modules to improve maintainability and reduce confusion.

## Success Criteria
- [ ] All 4 dead functions removed from codebase (TaskContextInference, WorkflowFiles, Common)
- [ ] No references to removed functions remain in documentation or comments
- [ ] All tests pass after removal (verify no hidden dependencies)
- [ ] Security hashes updated for modified library files
- [ ] CHANGELOG.md updated documenting cleanup

## Original Estimate
**Effort**: 1-2 hours
**Complexity**: Low
**Dependencies**: None (dead code has zero dependencies by definition)

## Major Milestones
1. **Audit Confirmation**: Verify dead code audit findings (functions truly unused)
2. **Code Removal**: Remove 4 functions from 3 library files (~160 lines)
3. **Validation**: Confirm no hidden dependencies, all tests pass
4. **Documentation**: Update security hashes and CHANGELOG

## Risk Assessment
### High Priority Risks
None identified - dead code removal is inherently low-risk

### Medium Priority Risks
- **Risk 1**: Audit missed hidden usage (function called indirectly via eval, dynamic dispatch)
  - **Mitigation**: Comprehensive grep search before removal, run full test suite after
- **Risk 2**: Documentation references removed functions (POD, comments, examples)
  - **Mitigation**: Search for function names in all files (*.md, *.pm, *.pl)

## Dependencies
- Dead code audit completed (confirmed 4 functions unused via codebase search)
- No external dependencies (internal cleanup only)

## Constraints
- Must preserve module APIs (only remove unexported internal functions or exported-but-unused functions)
- Cannot remove functions if POD documents them as public API (even if unused internally)

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [x] **Time**: Will this take >1 week? **NO** - estimated 1-2 hours
- [x] **People**: Does this need >2 people working on different parts? **NO** - single developer task
- [x] **Complexity**: Does this involve 3+ distinct concerns? **NO** - single concern (remove unused code)
- [x] **Risk**: Are there high-risk components that need isolation? **NO** - very low risk (unused code)
- [x] **Independence**: Can parts be worked on separately? **NO** - atomic removal task

**Decomposition Decision**: No decomposition needed. All signals negative. Simple, low-risk cleanup task that can be completed atomically in 1-2 hours.

## Status
**Status**: Finished
**Next Action**: /cig-design-plan 51
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
