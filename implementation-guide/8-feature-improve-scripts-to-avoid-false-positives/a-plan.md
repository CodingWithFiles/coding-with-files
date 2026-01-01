# Improve scripts to avoid false positives - Plan

## Task Reference
- **Task ID**: internal-8
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/8-improve-scripts-to-avoid-false-positives
- **Template Version**: 2.0

## Goal
Migrate all CIG helper scripts to Perl with a shared library to eliminate false positives and code duplication.

## Success Criteria
- [ ] Shared library created at `.cig/lib/CIG/` with 3 modules
- [ ] All 4 helper scripts rewritten in Perl using shared lib
- [ ] False positives in status extraction eliminated
- [ ] ~40% code duplication eliminated
- [ ] All existing tasks report correct status values
- [ ] Backward compatibility maintained (v1.0/v2.0 formats)

## Original Estimate
**Effort**: 2-3 days
**Complexity**: Medium
**Dependencies**: None - self-contained refactoring

## Major Milestones
1. **Shared Library**: Create `.cig/lib/CIG/` with MarkdownParser, TaskPath, WorkflowFiles modules
2. **Script Migration**: Rewrite all 4 scripts as thin wrappers using shared lib
3. **Validation**: Test all commands, update security hashes, remove old .sh files

## Risk Assessment
### Medium Priority Risks
- **Regression bugs**: Scripts may behave differently after rewrite
  - **Mitigation**: Keep .sh backups, comprehensive testing on all existing tasks
- **Breaking CLI interface**: Output format changes could break callers
  - **Mitigation**: Maintain exact same CLI interfaces and output formats

## Dependencies
- No external dependencies
- No CPAN modules (core Perl only)

## Constraints
- Must maintain exact CLI interfaces for all scripts
- Must maintain backward compatibility with v1.0 and v2.0 task formats
- Must update security hashes after script changes

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [x] **Time**: Will this take >1 week? **No** - estimated 2-3 days
- [x] **People**: Does this need >2 people? **No** - single developer task
- [x] **Complexity**: Does this involve 3+ distinct concerns? **Yes** - 3 modules + 4 scripts
- [x] **Risk**: Are there high-risk components that need isolation? **No** - low risk with rollback
- [x] **Independence**: Can parts be worked on separately? **Yes** - modules are independent

**Decision**: Keep as single task. Work sequentially: lib modules → scripts → testing. Manageable scope.

## Status
**Status**: Finished
**Next Action**: Update requirements and design for expanded scope
**Blockers**: None identified

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
