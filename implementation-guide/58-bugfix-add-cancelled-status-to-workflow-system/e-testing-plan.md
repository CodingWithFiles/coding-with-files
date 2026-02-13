# Add Cancelled status to workflow system - Testing Plan
**Task**: 58 (bugfix)

## Task Reference
- **Task ID**: internal-58
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/58-add-cancelled-status-to-workflow-system
- **Template Version**: 2.1

## Goal
Validate that Cancelled integrates correctly across config, library, aggregators, documentation, and Task 11 application.

## Test Strategy

### Test Levels
- **Unit**: Verify `status_percent`, `_is_terminal`, `state_done`, `state_achievable` handle Cancelled
- **Integration**: Verify aggregators consume Cancelled without warnings and produce correct output
- **Acceptance**: Verify Task 11 reports 0% after cancellation

### Test Coverage Targets
- **Critical Paths**: 100% — every code change has a corresponding test case
- **Regression**: Verify existing status values still work correctly

## Test Cases

### Functional Test Cases

- **TC-1**: Config contains Cancelled
  - **Given**: `cig-project.json` updated
  - **When**: `jq '.workflow["status-values"]["Cancelled"]' implementation-guide/cig-project.json`
  - **Then**: Returns `0`

- **TC-2**: status_percent maps Cancelled to 0
  - **Given**: TaskState.pm updated, config contains Cancelled
  - **When**: `perl -I.cig/lib -MTaskState -e 'print TaskState::status_percent("Cancelled"), "\n"'`
  - **Then**: Prints `0`

- **TC-3**: _is_terminal recognises Cancelled
  - **Given**: TaskState.pm updated with renamed function
  - **When**: `perl -I.cig/lib -MTaskState -e 'print TaskState::_is_terminal("Cancelled") ? "yes" : "no"'`
  - **Then**: Prints `yes`

- **TC-4**: _is_terminal still recognises Blocked and Finished
  - **Given**: TaskState.pm updated
  - **When**: Test `_is_terminal("Blocked")` and `_is_terminal("Finished")`
  - **Then**: Both return true (regression check)

- **TC-5**: state_achievable returns 0 for all-Cancelled task
  - **Given**: Task 11 with all files set to Cancelled
  - **When**: `perl -I.cig/lib -MTaskState -e 'print TaskState::state_achievable("implementation-guide/11-bugfix-only-pass-needed-args-to-scripts"), "\n"'`
  - **Then**: Returns `0` (terminal — no work potential)

- **TC-6**: state_done returns 0 for all-Cancelled task
  - **Given**: Task 11 with all files set to Cancelled
  - **When**: `perl -I.cig/lib -MTaskState -e 'print TaskState::state_done("implementation-guide/11-bugfix-only-pass-needed-args-to-scripts"), "\n"'`
  - **Then**: Returns `0`

- **TC-7**: v2.0 aggregator — no warnings for Cancelled
  - **Given**: All changes applied
  - **When**: `.cig/scripts/command-helpers/status-aggregator-v2.0 11 --workflow 2>&1`
  - **Then**: No "Warning: Unknown status" on stderr; output shows `0%`

- **TC-8**: v2.1 aggregator — no warnings for Cancelled
  - **Given**: All changes applied
  - **When**: `.cig/scripts/command-helpers/status-aggregator-v2.1 58 --workflow 2>&1`
  - **Then**: No "Warning: Unknown status" on stderr

- **TC-9**: Task 11 shows 0% (was 25%)
  - **Given**: Task 11 files all set to Cancelled
  - **When**: `.cig/scripts/command-helpers/status-aggregator-v2.0 11`
  - **Then**: Output contains `0%` (previously showed 25%)

- **TC-10**: Documentation includes Cancelled
  - **Given**: workflow-steps.md updated
  - **When**: `grep -c 'Cancelled' .cig/docs/workflow/workflow-steps.md`
  - **Then**: At least 1 match in the Valid Status Values section

### Regression Test Cases

- **TC-R1**: Existing statuses unaffected
  - **Given**: All changes applied
  - **When**: `perl -I.cig/lib -MTaskState -e 'for my $s (qw(Finished Testing Implemented In\ Progress Blocked To-Do Backlog)) { printf "%s: %s\n", $s, TaskState::status_percent($s) // "undef" }'`
  - **Then**: All return expected percentages (100, 75, 50, 25, 15, 0, 0)

- **TC-R2**: Full status report no warnings
  - **Given**: All changes applied
  - **When**: `.cig/scripts/command-helpers/status-aggregator-v2.0 2>&1 | grep -c Warning`
  - **Then**: Returns `0` (no warnings)

## Test Environment

### Setup Requirements
- All implementation steps (1-5) must be complete before testing
- No external dependencies — all tests use local Perl and shell

### Automation
- All test cases are manual CLI commands executed during g-testing-exec
- No CI/CD integration needed (internal tooling)

## Validation Criteria
- [ ] All 10 functional test cases pass
- [ ] Both regression test cases pass
- [ ] No warnings emitted by either aggregator
- [ ] Task 11 reports 0% (not 25%)

## Status
**Status**: Finished
**Next Action**: /cig-implementation-exec 58
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
