# Refactor command-helper scripts to clean architecture - Plan

## Task Reference
- **Task ID**: internal-41
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/41-refactor-command-helper-scripts-to-clean-architecture
- **Template Version**: 2.1

## Goal
Implement Task 39's original 2-layer architecture pattern by extracting duplicated code to shared libraries and clarifying layer responsibilities

## Success Criteria
- [ ] Zero code duplication (detect_version and PERL5OPT check exist only in shared libraries)
- [ ] All modules follow consistent pattern (simple, version-routing via library, or direct implementation)
- [ ] Backward compatible (Tasks 1-40 continue working, all /cig-* commands functional)
- [ ] Zero permission prompts maintained (wildcard pattern preserved)
- [ ] All 17 automated tests from Task 40 pass
- [ ] Code reduction achieved (220+ lines of duplication eliminated)

## Original Estimate
**Effort**: 7 hours
**Complexity**: Medium
**Dependencies**: Task 40 complete, all CIG commands using trampoline pattern

## Major Milestones
1. **Create Shared Libraries**: CIG::VersionRouter and CIG::Common with comprehensive POD documentation
2. **Refactor Modules**: Convert 7 modules to use shared libraries (inheritance, status, create, location, hierarchy, version, control)
3. **Validate Integration**: All 17 automated tests pass, zero permission prompts, backward compatibility verified

## Risk Assessment
### High Priority Risks
- **Breaking Permission Model**: Refactoring could inadvertently break the wildcard pattern or introduce new permission prompts
  - **Mitigation**: Test after each module refactor, verify wildcard pattern works, incremental commits
- **Regression in Tasks 35-40**: Changes could break functionality in recently completed tasks
  - **Mitigation**: Run backward compatibility tests before retrospective, test each /cig-* command

### Medium Priority Risks
- **Version Routing Logic Errors**: CIG::VersionRouter might incorrectly detect v2.0 vs v2.1 tasks
  - **Mitigation**: Unit test CIG::VersionRouter with both v2.0 and v2.1 tasks
- **Argument Parsing Extraction**: Moving arg parsing from status module to status-aggregator scripts could break functionality
  - **Mitigation**: Test status-aggregator-v2.0 and status-aggregator-v2.1 independently after extraction
- **Time Overrun**: Refactoring might take longer than 7 hours estimated
  - **Mitigation**: Incremental commits allow stopping at any phase if needed

## Dependencies
- Task 40 complete (trampoline architecture implemented)
- All CIG commands using trampoline pattern
- Existing test suite from Task 40 (17 automated tests)
- CIG::TaskPath.pm as reference for shared library structure

## Constraints
- **Backward Compatibility**: Must not break existing Tasks 1-40 or any /cig-* commands
- **Zero Permission Prompts**: Wildcard pattern must remain functional
- **Functionality Preservation**: No changes to behavior, only refactoring structure
- **Incremental Approach**: Each module refactoring must be independently testable
- **Version Support**: Must support both v2.0 and v2.1 task formats

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **No** - Estimated 7 hours
- [ ] **People**: Does this need >2 people working on different parts? **No** - Single developer task
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **Partial** - 3 concerns (libraries, modules, testing) but tightly coupled
- [ ] **Risk**: Are there high-risk components that need isolation? **No** - Risks mitigated by incremental approach with tests
- [ ] **Independence**: Can parts be worked on separately? **No** - Modules depend on libraries being created first

**Decision**: No decomposition needed (0-1 signals triggered). Task is cohesive and incremental approach with tests after each step provides sufficient risk mitigation.

## Status
**Status**: Finished
**Next Action**: Move to retrospective (complete)
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
