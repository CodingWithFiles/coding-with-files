# Fix format detector for v2.1 format - Plan

## Task Reference
- **Task ID**: internal-30
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/30-fix-format-detector-for-v2.1-format
- **Template Version**: 2.1

## Goal
Fix format detection logic to correctly identify v2.1 (10-phase) tasks instead of misreporting them as v1.0.

## Success Criteria
- [ ] v2.1 tasks correctly detected as "v2.1" (not "v1.0" or "v2.0")
- [ ] Detection logic checks for v2.1 indicators (e-testing-plan.md or f-implementation-exec.md)
- [ ] v2.0 tasks still correctly detected as "v2.0" (no regressions)
- [ ] v1.0 tasks still correctly detected as "v1.0" (no regressions)
- [ ] All scripts using format detection consolidated to use CIG::TaskPath library
- [ ] Trampoline scripts (status-aggregator, context-inheritance) use centralized detection
- [ ] hierarchy-resolver reports correct format for Task 26 and Task 30 (both v2.1)
- [ ] Duplicate detection logic eliminated (DRY principle)

## Original Estimate
**Effort**: 1-1.5 days
**Complexity**: Medium-High (detection logic + template updates + task migration)
**Dependencies**: None (isolated bug fix, but expanded scope)

## Major Milestones
1. **Phase 1: Core Detection**: Update TaskPath.pm with header-based detection + consolidate trampolines
2. **Phase 2: Template Headers**: Update 10 template files to emit "Template Version: 2.1"
3. **Phase 3: Task Migration**: Update headers in Tasks 26 and 30 (14 workflow files total)
4. **Phase 4: Validation**: Test all version detection scenarios with warning verification

## Risk Assessment
### High Priority Risks
- **Risk 1: Breaking v2.0 or v1.0 detection**
  - **Impact**: High - existing tasks would be misidentified
  - **Mitigation**: Test with known v1.0, v2.0, and v2.1 tasks before committing

### Medium Priority Risks
- **Risk 2: Missing scripts that use format detection**
  - **Impact**: Medium - some scripts might still report wrong format
  - **Mitigation**: Grep for format detection usage across all helper scripts

- **Risk 3: Edge cases in detection logic**
  - **Impact**: Medium - partial v2.1 tasks (missing files) might be misidentified
  - **Mitigation**: Use multiple v2.1 indicators (check for both e-testing-plan.md AND f-implementation-exec.md)

## Dependencies
- CIG::WorkflowFiles module (primary detection logic)
- hierarchy-resolver (consumer of format detection)
- format-detector script (standalone tool)
- Any other scripts that detect format versions

## Constraints
- Must maintain backward compatibility with v1.0 and v2.0 detection
- Detection must be fast (no complex file parsing)
- Must work with partial task directories (not all files present)
- Detection should prefer file presence over template version header (since v2.1 uses "2.0" in header)

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **No** - estimated 0.5-1 day
- [ ] **People**: Does this need >2 people working on different parts? **No** - single developer
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **No** - single concern: format detection
- [ ] **Risk**: Are there high-risk components that need isolation? **No** - low-risk bug fix with clear mitigation
- [ ] **Independence**: Can parts be worked on separately? **No** - detection logic must be updated atomically

**Decomposition Decision**: No decomposition needed. This is a focused bug fix affecting format detection logic only.

## Status
**Status**: Finished
**Next Action**: Task complete with retrospective
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
