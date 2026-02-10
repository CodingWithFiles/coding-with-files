# add-new-skipped-wf-step-status - Testing Plan
**Task**: 50 (feature)

## Task Reference
- **Task ID**: internal-50
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/50-add-new-skipped-wf-step-status
- **Template Version**: 2.1

## Goal
Validate "Skipped" status implementation through comprehensive functional, integration, and regression testing. Verify null-value sentinel pattern works correctly across v2.1 format while v2.0 remains unchanged.

## Test Strategy

### Test Levels

**Unit Tests**: Component-level testing with isolated dependencies
- TaskState::status_percent() with null config value
- TaskState::state_done() with filtered percentages
- Focus: Verify null handling and filter logic

**Integration Tests**: Component interaction and data flow validation
- Config → status_percent → state_done → display pipeline
- Verify end-to-end flow from JSON null to "N/A" display
- Focus: Component interaction correctness

**System Tests**: End-to-end functionality with real tasks
- v2.1 task with "Skipped" phase shows correct progress
- v2.0 task unchanged (no "Skipped" support)
- cig-status --workflow displays "Skipped (N/A)"
- Focus: Real-world behavior validation

**Acceptance Tests**: Business requirement validation
- All 10 acceptance criteria from b-requirements-plan.md
- User story validation (developers, LLM agents, maintainers)
- Focus: Requirements satisfaction

### Test Coverage Targets

- **Overall Coverage**: Manual testing sufficient (no automated test framework for CIG system)
- **Critical Paths**: 100% coverage - config load, status mapping, progress calculation, display
- **Edge Cases**: All handled - empty array after filtering, unknown statuses, null values, v2.0/v2.1 format differences
- **Regression**: All existing v2.0 and v2.1 tasks validated (no breaking changes)

## Test Cases

### Functional Test Cases

**TC-F1: Configuration accepts null value**
- **Given**: cig-project.json workflow.status-values object
- **When**: Add `"Skipped": null` entry
- **Then**: JSON remains valid, `jq '.workflow["status-values"]["Skipped"]'` returns `null` (not string "null")

**TC-F2: status_percent returns undef for null config value**
- **Given**: Config loaded with `"Skipped": null`
- **When**: Call `TaskState::status_percent("Skipped")`
- **Then**: Returns Perl `undef` (not 0, not defined value)

**TC-F3: state_done filters undefined percentages**
- **Given**: Task with statuses ["Finished", "Skipped", "Finished"] mapping to [100, undef, 100]
- **When**: Call `TaskState::state_done($task_dir)`
- **Then**: Filters to [100, 100], calculates MIN(100, 100) = 100%, returns 100

**TC-F4: v2.1 task with 1 skipped phase shows 100% when others finished**
- **Given**: v2.1 task with 9 phases "Finished", 1 phase "Skipped" (i-maintenance)
- **When**: Run status-aggregator-v2.1 on task
- **Then**: Shows 100% progress (9/9 = 100%, not 9/10 = 90%)

**TC-F5: v2.1 task with multiple skipped phases**
- **Given**: v2.1 task with 7 phases "Finished", 3 phases "Skipped"
- **When**: Run status-aggregator-v2.1 on task
- **Then**: Shows 100% progress (7/7 = 100%, not 7/10 = 70%)

**TC-F6: v2.1 task with all phases skipped**
- **Given**: v2.1 task with all 10 phases "Skipped"
- **When**: Run status-aggregator-v2.1 on task
- **Then**: Shows 0% progress (empty array after filtering, returns 0)

**TC-F7: v2.1 task without Skipped status (regression)**
- **Given**: v2.1 task with existing status values (Backlog, In Progress, Finished)
- **When**: Run status-aggregator-v2.1 on task
- **Then**: Shows same progress as before (no regression, backward compatible)

**TC-F8: v2.0 task unchanged (no Skipped support)**
- **Given**: v2.0 task with existing status values
- **When**: Run status-aggregator-v2.0 on task
- **Then**: Behaves identically to before (v2.0 format unchanged, no "Skipped" support)

**TC-F9: Display shows "Skipped (N/A)" not percentage**
- **Given**: v2.1 task with i-maintenance marked "Skipped"
- **When**: Run `cig-status <task> --workflow`
- **Then**: Output shows "i-maintenance: Skipped (N/A)" not "Skipped (0%)" or percentage

**TC-F10: Display distinguishes Skipped from Backlog**
- **Given**: v2.1 task with one phase "Skipped", one phase "Backlog"
- **When**: Run `cig-status <task> --workflow`
- **Then**: Shows "Phase1: Skipped (N/A)" and "Phase2: Backlog (0%)" distinctly

**TC-F11: Unknown status still defaults to 0%**
- **Given**: Task with status "UnknownFoo" (not in config)
- **When**: Run status-aggregator
- **Then**: Returns 0% for unknown status (existing backward-compatible behavior)

**TC-F12: Documentation includes Skipped status**
- **Given**: workflow-steps.md Status Values section
- **When**: Read documentation
- **Then**: "Skipped" listed with "(N/A)" and v2.1 requirement noted, usage guidance provided

### Non-Functional Test Cases

**TC-NFR1: Performance - No degradation with Skipped phases**
- **Test**: Run status-aggregator-v2.1 on task with 3 skipped phases, measure execution time
- **Expected**: <100ms (same performance as before, grep/filter adds negligible overhead)
- **Metric**: Compare with baseline execution time on task without "Skipped"

**TC-NFR2: Performance - Config caching works correctly**
- **Test**: Run status_percent() multiple times in same invocation
- **Expected**: Config loaded once and cached, subsequent calls use cached map
- **Metric**: Verify cache variable populated after first call

**TC-NFR3: Usability - "N/A" display is clear for LLMs**
- **Test**: Review --workflow output with "Skipped" phases
- **Expected**: "Skipped (N/A)" format distinguishes from numeric percentages, no ambiguity with incomplete work
- **Metric**: LLM can correctly interpret "Skipped" as "not applicable" not "not started"

**TC-NFR4: Usability - Documentation clarity**
- **Test**: Read workflow-steps.md "Skipped" documentation
- **Expected**: Clear guidance on when to use, examples provided, per-task vs task-type distinction noted, v2.1 requirement prominent
- **Metric**: Developers can understand when to use "Skipped" without additional explanation

**TC-NFR5: Reliability - Graceful handling of edge cases**
- **Test**: Test edge cases (all skipped, none skipped, mixed statuses)
- **Expected**: No errors, correct progress calculation in all cases
- **Metric**: All edge cases handled without warnings or failures

**TC-NFR6: Reliability - Backward compatibility preserved**
- **Test**: Run on existing v2.0 and v2.1 tasks
- **Expected**: No changes to existing task progress calculations, no new warnings
- **Metric**: Compare before/after progress values for sample of existing tasks

**TC-NFR7: Security - Script hashes updated**
- **Test**: Run `/cig-security-check verify`
- **Expected**: All hash verifications pass, no warnings
- **Metric**: Exit code 0, no error output

## Test Environment

### Setup Requirements

**Test Data**:
- Create test v2.1 task directory with various "Skipped" phase combinations
- Use existing v2.0 and v2.1 tasks for regression testing
- Preserve original task states (no modifications to production task directories)

**Test Task Structure** (temporary):
```
implementation-guide/test-50-skipped-status/
  a-task-plan.md           (Status: Finished)
  b-requirements-plan.md   (Status: Finished)
  c-design-plan.md         (Status: Finished)
  d-implementation-plan.md (Status: Finished)
  e-testing-plan.md        (Status: Finished)
  f-implementation-exec.md (Status: Finished)
  g-testing-exec.md        (Status: Finished)
  h-rollout.md             (Status: Finished)
  i-maintenance.md         (Status: Skipped)  ← Test case
  j-retrospective.md       (Status: Finished)
```

**Environment Dependencies**:
- Perl 5.x with JSON::PP module (already present)
- jq for JSON validation (already installed)
- CIG helper scripts in `.cig/scripts/command-helpers/`
- Access to implementation-guide/ directory structure

**No Mock Services**: All components are local, no external dependencies

### Automation

**Test Framework**: Manual testing (CIG system has no automated test framework)

**Test Execution**:
1. Implementation phase: Make code changes
2. Testing phase: Run manual test cases sequentially
3. Document results in g-testing-exec.md

**No CI/CD Integration**: CIG is documentation system, changes validated manually

**Test Sequence**:
1. Unit tests (TC-F1, TC-F2, TC-F3): Verify core logic
2. Integration tests (TC-F4-F7): Verify component interaction
3. System tests (TC-F8-F10): Verify end-to-end behavior
4. Non-functional tests (TC-NFR1-NFR7): Verify quality attributes
5. Regression tests: Verify no breaking changes

## Validation Criteria

### Functional Validation
- [ ] **TC-F1-F12**: All 12 functional test cases passing
- [ ] **AC1**: Config returns null for "Skipped" status
- [ ] **AC2**: v2.1 task with 1 skipped + 9 finished shows 100%
- [ ] **AC3**: v2.0 tasks unchanged (no "Skipped" support)
- [ ] **AC4**: Display shows "Skipped (N/A)" not percentage
- [ ] **AC5**: Documentation complete with v2.1 requirement

### Non-Functional Validation
- [ ] **TC-NFR1-NFR7**: All 7 non-functional test cases passing
- [ ] **AC6**: Backward compatibility - existing v2.0 and v2.1 tasks show correct progress
- [ ] **AC7**: Performance - status aggregation <100ms
- [ ] **AC8**: Security - script hashes verified

### Integration Validation
- [ ] **AC9**: Format isolation - v2.0 unchanged, v2.1 handles "Skipped"
- [ ] **AC10**: BACKLOG resolution - developers can mark any workflow step as "Skipped"

### Coverage Validation
- [ ] Critical paths tested: config load → status_percent → state_done → display
- [ ] Edge cases tested: all skipped, none skipped, mixed statuses, empty array
- [ ] Regression tested: Existing v2.0 and v2.1 tasks (sample of 5+ tasks)

### Success Criteria Summary
- **Must Pass**: All 12 functional tests (TC-F1-F12)
- **Must Pass**: All 7 non-functional tests (TC-NFR1-NFR7)
- **Must Pass**: All 10 acceptance criteria (AC1-AC10)
- **Must Pass**: Zero regressions on existing tasks
- **Must Pass**: Security verification passes

**Definition of Done**: All validation criteria checked, no failures, ready for implementation execution and rollout.

## Status
**Status**: Finished
**Next Action**: /cig-implementation-exec 50
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
