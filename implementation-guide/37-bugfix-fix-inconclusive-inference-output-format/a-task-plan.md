# fix inconclusive inference output format - Plan

## Task Reference
- **Task ID**: internal-37
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/37-fix-inconclusive-inference-output-format
- **Template Version**: 2.1

## Goal
Standardize task context inference to always output structured, parseable format for both conclusive and inconclusive scenarios.

## Success Criteria
- [ ] TaskContextInference.pm outputs structured format for conclusive, inconclusive, and no-signals scenarios
- [ ] Inconclusive output uses plural fields (`task_nums`, `task_slugs`, `workflow_steps`) with comma-separated values
- [ ] Inconclusive output includes `reasons` field showing which signals contributed
- [ ] Commands and skills can programmatically parse output in all scenarios
- [ ] Tests validate structured output format across all scenarios
- [ ] Documentation updated with complete output format specification

## Original Estimate
**Effort**: 4-6 hours (Perl module updates, wrapper script, tests, documentation)
**Complexity**: Medium (multi-file changes, backward compatibility considerations)
**Dependencies**: Task 32 (TaskContextInference.pm implementation)

## Major Milestones
1. **Update output format spec**: Define improved format with plural fields and reasons
2. **Modify TaskContextInference.pm**: Implement structured output for all scenarios
3. **Update wrapper and skills**: Ensure structured format propagates to commands
4. **Test and validate**: Verify parseable output across all test cases

## Risk Assessment
### Medium Priority Risks
- **Breaking existing command parsing**: Commands currently expect conclusive format only
  - **Mitigation**: Commands already check exit codes; add "current" field check for backward compatibility
- **Test suite updates**: Existing tests expect human-readable inconclusive output
  - **Mitigation**: Update TC-I2, TC-I3, TC-I4 test expectations; validate programmatic parsing

### Low Priority Risks
- **Performance impact**: Additional field generation for inconclusive cases
  - **Mitigation**: Minimal - just string concatenation, negligible overhead

## Dependencies
- **Task 32**: TaskContextInference.pm module (already implemented)
- **Test infrastructure**: Existing test cases in Task 32 need updates
- **Skills system**: `/current-task-wf` skill must propagate structured format

## Constraints
- **Backward compatibility**: Exit codes must remain unchanged (0=conclusive, 1=uncorrelated, 3=no_signals)
- **Parseable format**: Output must be key:value format parseable by simple regex or split
- **Consistency**: Field names must be self-documenting (singular for single, plural for multiple)

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **No** - 4-6 hours estimated
- [ ] **People**: Does this need >2 people working on different parts? **No** - single developer task
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **No** - 2 concerns (output format, tests)
- [ ] **Risk**: Are there high-risk components that need isolation? **No** - medium risk, good test coverage
- [ ] **Independence**: Can parts be worked on separately? **No** - tightly coupled changes

**Analysis**: 0/5 signals triggered. Task is appropriately scoped as single bugfix.

## Status
**Status**: Finished
**Next Action**: Move to design planning → `/cig-design-plan 37`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
