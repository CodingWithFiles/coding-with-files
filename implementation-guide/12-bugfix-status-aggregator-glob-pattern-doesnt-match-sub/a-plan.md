# Status-aggregator.pl glob pattern fix - Plan

## Task Reference
- **Task ID**: internal-12
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/12-status-aggregator-glob-pattern-doesnt-match-sub
- **Template Version**: 2.0

## Goal
Fix status-aggregator.pl glob pattern to correctly match subtasks with hierarchical numbering (e.g., 1.1, 1.2.3).

## Success Criteria
- [x] status-aggregator.pl correctly identifies subtask directories using hierarchical patterns
- [x] All subtasks (1.1, 2.3.1, etc.) are included in status aggregation output
- [x] Existing top-level task matching continues to work (regression test)
- [x] Script tested with real task hierarchy containing multiple nesting levels

## Original Estimate
**Effort**: 2-4 hours
**Complexity**: Low
**Dependencies**: Understanding of glob patterns in Perl, existing task directory structure

## Major Milestones
1. **Analyse current glob pattern**: Identify why `${task_num}-*-*` doesn't match subtasks
2. **Design new pattern**: Create glob pattern that matches both top-level and subtask directories
3. **Implement and test**: Update script, verify with existing task hierarchy

## Risk Assessment
### Medium Priority Risks
- **Breaking existing functionality**: New glob pattern might not match current top-level tasks
  - **Mitigation**: Test with existing tasks (1-12), ensure backward compatibility

- **Performance degradation**: More complex pattern might slow down directory scanning
  - **Mitigation**: Profile before/after, ensure performance is acceptable for typical task counts

## Dependencies
- Perl glob/file matching capabilities
- Existing task directory structure in `implementation-guide/`
- Current status-aggregator.pl script implementation

## Constraints
- Must maintain backward compatibility with existing top-level task directories
- Must work with unlimited nesting depth (1.1.1.1... etc.)
- Glob pattern must be readable and maintainable

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [x] **Time**: Will this take >1 week? **No** - 2-4 hours estimated
- [x] **People**: Does this need >2 people working on different parts? **No** - single script change
- [x] **Complexity**: Does this involve 3+ distinct concerns? **No** - focused glob pattern fix
- [x] **Risk**: Are there high-risk components that need isolation? **No** - medium risk, well-mitigated
- [x] **Independence**: Can parts be worked on separately? **No** - single cohesive change

**Decision**: Keep as single task. Simple, focused bugfix with clear scope.

## Status
**Status**: Finished
**Next Action**: Task complete - retrospective documented in h-retrospective.md
**Blockers**: None

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
