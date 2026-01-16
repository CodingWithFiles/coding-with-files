# Add --workflow Option to status-aggregator - Testing

## Task Reference
- **Task ID**: internal-18
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/18-add-workflow-option-to-status-aggregator
- **Template Version**: 2.0

## Goal
Define test strategy and validation approach for enhanced status-aggregator.pl with comprehensive coverage of all new features and backward compatibility.

## Test Strategy

### Test Approach
- **Manual testing** via command-line execution (status-aggregator.pl is a CLI script)
- **Systematic validation** of all 6 functional requirements (FR1-FR6) and FR7 (ASCII indicators)
- **Performance measurement** using `time` command
- **Output validation** via visual inspection and programmatic checks (grep, wc, etc.)
- **Backward compatibility** testing with existing usage patterns

### Test Levels
- **Component Tests**: Individual function testing (get_workflow_status, natural_sort, get_task_timestamps)
- **Integration Tests**: CIG::Options integration, CIG module interactions
- **System Tests**: End-to-end command execution with various option combinations
- **Regression Tests**: Existing usage patterns produce expected results

### Test Coverage Targets
- **Functional**: 100% coverage of all 7 functional requirements
- **Options**: All option combinations tested (help, workflow, depth, sort, format)
- **Edge Cases**: Invalid inputs, missing files, empty repositories
- **Regression**: All existing test scenarios from pre-enhancement script
- **Performance**: < 500ms for --depth=0, < 2s for --depth=-1

## Test Cases

### FR1: Help Display with Short Option Support

**TC1: --help displays usage information**
- **Given**: status-aggregator.pl is installed and executable
- **When**: `status-aggregator.pl --help`
- **Then**:
  - Exits with code 0
  - Displays description, usage, options, arguments
  - Shows all 5 options (help, workflow, depth, sort, format)
  - Shows optional positional argument (task-path)

**TC2: -h short option works**
- **Given**: status-aggregator.pl is installed
- **When**: `status-aggregator.pl -h`
- **Then**: Same output as TC1 (--help)

**TC3: Unknown option error**
- **Given**: status-aggregator.pl is installed
- **When**: `status-aggregator.pl --unknown`
- **Then**:
  - Exits with code 1
  - Error message: "Error: Unknown option: --unknown"
  - Suggestion: "Use --help for usage information"

**TC4: Short option bundling**
- **Given**: status-aggregator.pl is installed
- **When**: `status-aggregator.pl -wh`
- **Then**: Displays help (--help takes precedence)

### FR2: Workflow Step Visibility

**TC5: --workflow shows individual files**
- **Given**: Repository with Task 18 (feature with 8 workflow files)
- **When**: `status-aggregator.pl 18 --workflow`
- **Then**:
  - Shows task line: `+ 18 (feature): add-workflow-option	25%`
  - Shows 8 workflow files with 2-space indent
  - Each file shows: indicator, name, tab, status, tab, percentage
  - Files ordered a-h

**TC6: -w short option works**
- **Given**: Same as TC5
- **When**: `status-aggregator.pl 18 -w`
- **Then**: Same output as TC5

**TC7: Workflow files tab-aligned**
- **Given**: Same as TC5
- **When**: Run TC5 command, pipe to `cat -A` to see tabs
- **Then**: Status and percentage columns aligned with tabs (not spaces)

**TC8: Task type with fewer files**
- **Given**: Repository with bugfix task (5 files: a,c,d,e,h)
- **When**: `status-aggregator.pl <bugfix-task> --workflow`
- **Then**: Shows only 5 workflow files (not all 8)

### FR3: Hierarchy Depth Control

**TC9: --depth=0 shows top-level only**
- **Given**: Repository with tasks at multiple levels (1, 1.1, 2, 2.1, etc.)
- **When**: `status-aggregator.pl --depth=0`
- **Then**: Shows only top-level tasks (1, 2, 3, ...)

**TC10: --depth=1 shows one level deep**
- **Given**: Repository with tasks 1, 1.1, 1.1.1
- **When**: `status-aggregator.pl 1 --depth=1`
- **Then**: Shows task 1 and 1.1 (not 1.1.1)

**TC11: --depth=-1 shows full hierarchy**
- **Given**: Repository with deeply nested tasks
- **When**: `status-aggregator.pl --depth=-1`
- **Then**: Shows all tasks regardless of depth

**TC12: Positional arg enables unlimited depth**
- **Given**: Repository with task 18 and potential subtasks
- **When**: `status-aggregator.pl 18`
- **Then**: Shows task 18 and all descendants (depth=-1 implied)

### FR4: Task Sorting Options

**TC13: --sort=numeric (default)**
- **Given**: Repository with tasks 1, 2, 10, 2.1, 2.10, 2.2
- **When**: `status-aggregator.pl --depth=-1 --sort=numeric`
- **Then**: Tasks ordered: 1, 2, 2.1, 2.2, 2.10, 10 (natural sort)

**TC14: --sort=date orders by creation**
- **Given**: Tasks with known creation order (check git log)
- **When**: `status-aggregator.pl --sort=date --depth=0`
- **Then**: Tasks ordered oldest to newest creation date

**TC15: --sort=modified orders by modification**
- **Given**: Tasks with known modification times
- **When**: `status-aggregator.pl --sort=modified --depth=0`
- **Then**: Tasks ordered oldest to newest modification

**TC16: Git fallback to filesystem mtime**
- **Given**: Repository with uncommitted workflow files
- **When**: `status-aggregator.pl 18 --sort=date`
- **Then**: Uses filesystem mtime, no errors

### FR5: CIG::Options Integration

**TC17: Multiple options work together**
- **Given**: Repository with nested tasks
- **When**: `status-aggregator.pl --depth=2 --workflow --sort=date`
- **Then**: Shows depth=2, workflow files displayed, sorted by date

**TC18: Invalid depth value**
- **Given**: status-aggregator.pl is installed
- **When**: `status-aggregator.pl --depth=abc`
- **Then**: Error from CIG::Options about invalid value

**TC19: Invalid sort value**
- **Given**: status-aggregator.pl is installed
- **When**: `status-aggregator.pl --sort=invalid`
- **Then**: Error message about supported sort modes

### FR6 & FR7: Backward Compatibility & ASCII Indicators

**TC20: No args shows top-level (changed behavior)**
- **Given**: Repository with multiple tasks
- **When**: `status-aggregator.pl`
- **Then**: Shows only top-level tasks (depth=0 default)

**TC21: Positional arg shows subtree**
- **Given**: Repository with task 18
- **When**: `status-aggregator.pl 18`
- **Then**: Shows task 18 and all descendants (depth=-1 implied)

**TC22: --format=json produces valid JSON**
- **Given**: Repository with tasks
- **When**: `status-aggregator.pl --format=json --depth=0`
- **Then**: Valid JSON output, parseable by jq

**TC23: ASCII indicators correct**
- **Given**: Tasks at different completion levels
- **When**: `status-aggregator.pl --depth=-1`
- **Then**:
  - `*` for 100% complete tasks
  - `+` for 1-99% tasks (in progress)
  - `-` for 0% tasks (not started)

**TC24: Exit codes unchanged**
- **Given**: Various command scenarios
- **When**: Run commands and check `echo $?`
- **Then**:
  - 0 for success
  - 1 for invalid arguments
  - 2 for task not found

### Non-Functional Test Cases

**PT1: Performance - --depth=0**
- **Given**: Repository with 18+ tasks
- **When**: `time status-aggregator.pl --depth=0`
- **Then**: Completes in < 500ms

**PT2: Performance - --depth=-1**
- **Given**: Repository with 18+ tasks at multiple levels
- **When**: `time status-aggregator.pl --depth=-1`
- **Then**: Completes in < 2s

**PT3: Performance - --sort=date overhead**
- **Given**: Repository with tasks
- **When**: Compare `time status-aggregator.pl` vs `time status-aggregator.pl --sort=date`
- **Then**: Difference < 200ms

**PT4: Performance - --workflow overhead**
- **Given**: Repository with tasks
- **When**: Compare `time status-aggregator.pl 18` vs `time status-aggregator.pl 18 --workflow`
- **Then**: Difference < 100ms

**UT1: Usability - Help text clarity**
- **Given**: New user reading help
- **When**: `status-aggregator.pl --help`
- **Then**: Help text scannable, examples clear, < 2 min to understand

**UT2: Usability - Error messages**
- **Given**: User makes mistake
- **When**: Various invalid inputs
- **Then**: Error messages specific, actionable, include --help suggestion

**RT1: Reliability - Missing task directory**
- **Given**: Non-existent task number
- **When**: `status-aggregator.pl 999`
- **Then**: Exit code 2, clear error message

**RT2: Reliability - Empty repository**
- **Given**: implementation-guide/ directory with no tasks
- **When**: `status-aggregator.pl`
- **Then**: No output or empty list, exit code 0

**RT3: Reliability - Deeply nested tasks**
- **Given**: Tasks nested 5+ levels deep
- **When**: `status-aggregator.pl --depth=-1`
- **Then**: No crashes, all tasks displayed

## Test Environment

### Setup Requirements
- **Repository State**: code-implementation-guide repository with 18+ tasks
- **Git**: Committed workflow files for timestamp testing (--sort=date/modified)
- **Perl**: 5.30.3+ with CIG modules installed
- **Dependencies**: CIG::Options, CIG::WorkflowFiles, CIG::MarkdownParser, CIG::TaskPath
- **Test Data**:
  - Task 18 with 8 workflow files at various completion states
  - Tasks at multiple hierarchy levels (1, 1.1, 2, 2.1, etc.)
  - At least one bugfix/hotfix task (5 files instead of 8)
  - Mix of completion states (Finished=100%, In Progress=25-75%, Backlog=0%)

### Automation
- **Test Framework**: Manual execution with shell scripts
- **Test Script**: Create `test-status-aggregator.sh` for automated test execution
- **Validation**: Use `diff` to compare output against expected results
- **Performance**: Use `time` command for benchmarking
- **CI/CD**: Not applicable (manual testing during development)
- **Test Report**: Document pass/fail for all 24 functional + 7 non-functional tests

### Test Execution Order
1. Run all FR1 tests (help, options) - TC1-TC4
2. Run all FR2 tests (workflow display) - TC5-TC8
3. Run all FR3 tests (depth limiting) - TC9-TC12
4. Run all FR4 tests (sorting) - TC13-TC16
5. Run all FR5 tests (CIG::Options) - TC17-TC19
6. Run all FR6/FR7 tests (backward compat, ASCII) - TC20-TC24
7. Run all performance tests - PT1-PT4
8. Run all usability tests - UT1-UT2
9. Run all reliability tests - RT1-RT3

## Validation Criteria

### Test Completion
- [ ] All 24 functional test cases executed and documented
- [ ] All 4 performance tests executed with measurements
- [ ] All 2 usability tests executed with observations
- [ ] All 3 reliability tests executed and passing

### Coverage Targets
- [ ] 100% of functional requirements tested (FR1-FR7)
- [ ] All 16 acceptance criteria validated (AC1-AC16)
- [ ] All option combinations tested (help, workflow, depth, sort, format)
- [ ] Edge cases covered (invalid inputs, missing files, empty repos)

### Performance Benchmarks
- [ ] --depth=0 completes in < 500ms
- [ ] --depth=-1 completes in < 2s
- [ ] --sort=date overhead < 200ms
- [ ] --workflow overhead < 100ms

### Quality Gates
- [ ] All test cases pass (31 total)
- [ ] No regressions detected
- [ ] Error messages clear and actionable
- [ ] Help text comprehensive and scannable
- [ ] Tab alignment correct in all output modes
- [ ] ASCII indicators display correctly (*, +, -)

### Documentation
- [ ] Test results documented in "Actual Results" section
- [ ] Any test failures investigated and root cause identified
- [ ] Lessons learned captured for retrospective

## Status
**Status**: Finished
**Next Action**: Execute tests during implementation, then proceed to rollout
**Blockers**: None identified

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
