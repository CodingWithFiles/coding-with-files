# task-tracking-using-inference-scoring - Testing

## Task Reference
- **Task ID**: internal-32
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/32-task-tracking-using-inference-scoring
- **Template Version**: 2.1

## Goal
Define comprehensive test strategy for signal-based inference system: library unit tests, wrapper integration tests, skills validation, command integration testing, and performance benchmarks.

## Test Strategy

### Test Levels

**1. Unit Tests (Library Functions)**
- **Scope**: Test TaskContextInference.pm functions in isolation
- **Approach**: Direct function calls with mock data (no file I/O, no subprocess execution)
- **Tools**: Perl Test::More framework
- **Coverage Target**: 90%+ of library code
- **Key Tests**: Signal collection functions, scoring algorithms, correlation logic

**2. Integration Tests (Wrapper Script)**
- **Scope**: Test task-context-inference wrapper calling library
- **Approach**: Execute wrapper script with controlled repository state
- **Tools**: Shell scripts with test fixtures
- **Coverage Target**: All exit codes (0, 1, 2, 3) validated
- **Key Tests**: Arg parsing, library integration, output formatting, error handling

**3. System Tests (Skills and Commands)**
- **Scope**: Test full stack from command invocation to inference result
- **Approach**: Invoke commands without arguments, verify skill execution
- **Tools**: Manual testing with Claude Code
- **Coverage Target**: All 10 commands tested
- **Key Tests**: Skill context injection, command arg handling, backward compatibility

**4. Acceptance Tests (End-to-End Scenarios)**
- **Scope**: Validate requirements (FR1-FR5, NFR1-NFR5) in realistic scenarios
- **Approach**: Real-world usage patterns with multiple tasks
- **Tools**: Scripted scenarios with verification checks
- **Coverage Target**: All 23 acceptance criteria (AC1-AC23)
- **Key Tests**: Correlated signals, uncorrelated prompts, performance, accuracy

### Test Coverage Targets

- **Library Functions**: 90%+ line coverage (critical: 100% for correlation logic)
- **Signal Functions**: 100% (each signal tested independently)
- **Scoring Algorithms**: 100% (mathematical correctness verified)
- **Wrapper Script**: 100% (thin layer, all paths testable)
- **Exit Codes**: 100% (0, 1, 2, 3 validated)
- **Integration**: All 10 commands × 2 scenarios (with/without arg) = 20 tests
- **Performance**: 100% of 30-task repository tested (<500ms target)
- **Accuracy**: ≥95% correct inferences across 20 realistic scenarios

## Test Cases

### Unit Tests (Library Functions)

**Signal Collection Tests:**

- **TC-U1**: Branch signal parsing - feature branch
  - **Given**: Git branch name `feature/32-task-tracking-using-inference-scoring`
  - **When**: `_get_branch_signal()` called
  - **Then**: Returns `{name => 'branch', weight => 100, candidates => [{task => 32, score => 100}], top => 32, null => 0}`

- **TC-U2**: Branch signal parsing - main branch
  - **Given**: Git branch name `main`
  - **When**: `_get_branch_signal()` called
  - **Then**: Returns `{name => 'branch', null => 1}` (no task number extractable)

- **TC-U3**: Worktree signal detection - in worktree
  - **Given**: CWD is `/home/user/cig-task-32/`, git worktree list shows entry
  - **When**: `_get_worktree_signal()` called
  - **Then**: Returns task 32 with score 95

- **TC-U4**: State file reading - valid file
  - **Given**: `.cig/current-task` contains `32\n`
  - **When**: `_get_state_file_signal()` called
  - **Then**: Returns task 32 with score 85

- **TC-U5**: State file reading - missing file
  - **Given**: `.cig/current-task` does not exist
  - **When**: `_get_state_file_signal()` called
  - **Then**: Returns `{null => 1}`

- **TC-U6**: State file reading - malformed content
  - **Given**: `.cig/current-task` contains `invalid\n`
  - **When**: `_get_state_file_signal()` called
  - **Then**: Returns `{null => 1}`, warning to stderr

- **TC-U7**: Recency signal - recently modified task
  - **Given**: Task 32 workflow files modified 5 minutes ago, task 31 modified 1 hour ago
  - **When**: `_get_recency_signal()` called
  - **Then**: Returns top-5 with task 32 scoring ~90, task 31 scoring ~70

**Scoring Algorithm Tests:**

- **TC-U8**: Recency scoring - exponential decay
  - **Given**: Timestamps: 5min (300s), 1hr (3600s), 24hr (86400s), 1week (604800s)
  - **When**: `_score_recency($seconds_ago)` called for each
  - **Then**: Returns: ~90, ~70, ~20, ~5 (exponential decay verified)

- **TC-U9**: Progress scoring - bell curve
  - **Given**: Progress values: 0%, 25%, 50%, 75%, 100%
  - **When**: `_score_progress($percentage)` called for each
  - **Then**: Returns: ~10, ~45, ~60, ~45, ~10 (bell curve peak at 50%)

- **TC-U10**: Status scoring - linear mapping
  - **Given**: Status values: "Backlog", "In Progress", "Testing", "Finished"
  - **When**: `_score_status($status)` called for each
  - **Then**: Returns: 0, 80, 75, 100 (linear mapping verified)

**Correlation Logic Tests:**

- **TC-U11**: Correlation - all signals agree
  - **Given**: Signals: branch→32, worktree→32, state→32, recency top→32, progress top→32
  - **When**: `correlate_signals(\@signals)` called
  - **Then**: Returns `{confidence => 'correlated', chosen_task => 32}`

- **TC-U12**: Correlation - signals disagree
  - **Given**: Signals: branch→32, recency top→31, state→32, progress top→31
  - **When**: `correlate_signals(\@signals)` called
  - **Then**: Returns `{confidence => 'uncorrelated', candidates => [31, 32]}`

- **TC-U13**: Correlation - null signals excluded
  - **Given**: Signals: branch→null, state→null, recency top→32, progress top→32, status top→32
  - **When**: `correlate_signals(\@signals)` called
  - **Then**: Returns `{confidence => 'correlated', chosen_task => 32}` (nulls ignored)

- **TC-U14**: Correlation - all signals null
  - **Given**: All signals return `{null => 1}`
  - **When**: `correlate_signals(\@signals)` called
  - **Then**: Returns `{confidence => 'no_signals'}`

**Output Formatting Tests:**

- **TC-U15**: Format output - simple mode
  - **Given**: Context: task_num=32, task_slug="feature-task-tracking", workflow_step="e-testing-plan", verbose=0
  - **When**: `format_output($context, 0)` called
  - **Then**: Returns exactly 3 lines: `task_num: 32\ntask_slug: feature-task-tracking\nworkflow_step: e-testing-plan\n`

- **TC-U16**: Format output - verbose mode
  - **Given**: Same context, verbose=1
  - **When**: `format_output($context, 1)` called
  - **Then**: Returns 3 lines + signal breakdown with box-drawing characters

### Integration Tests (Wrapper Script)

**Script Execution Tests:**

- **TC-I1**: Wrapper - default mode (correlated)
  - **Given**: Repository state with task 32 active (branch, recent modifications)
  - **When**: `./task-context-inference` executed
  - **Then**: Prints 3 lines (task_num, task_slug, workflow_step), exits 0

- **TC-I2**: Wrapper - verbose mode (correlated)
  - **Given**: Repository state with task 32 active
  - **When**: `./task-context-inference --verbose` executed
  - **Then**: Prints 3 lines + signal breakdown, exits 0

- **TC-I3**: Wrapper - uncorrelated signals
  - **Given**: Repository state with conflicting signals (branch=32, recent=31)
  - **When**: `./task-context-inference` executed
  - **Then**: Prints user prompt with candidates, exits 1

- **TC-I4**: Wrapper - no signals
  - **Given**: Repository state on main branch, no recent activity, no state file
  - **When**: `./task-context-inference` executed
  - **Then**: Prints error "Cannot infer current task (no signals detected)", exits 3

- **TC-I5**: Wrapper - exception handling
  - **Given**: Repository state causes library exception (e.g., corrupted git)
  - **When**: `./task-context-inference` executed
  - **Then**: Prints error to stderr, exits 2

### System Tests (Skills and Commands)

**Skill Execution Tests:**

- **TC-S1**: Skill /current-task-wf - success
  - **Given**: Repository state with task 32 active
  - **When**: `/current-task-wf` skill invoked
  - **Then**: LLM context includes 3-line output (task_num, task_slug, workflow_step)

- **TC-S2**: Skill /current-task-wf - failure fallback
  - **Given**: Repository state with no signals
  - **When**: `/current-task-wf` skill invoked
  - **Then**: LLM context includes "Unable to infer context"

- **TC-S3**: Skill /current-task-wf-verbose - success
  - **Given**: Repository state with task 32 active
  - **When**: `/current-task-wf-verbose` skill invoked
  - **Then**: LLM context includes 3 lines + full signal breakdown

**Command Integration Tests:**

- **TC-C1**: Command with explicit argument (inference skipped)
  - **Given**: Repository state with task 32 active
  - **When**: `/cig-task-plan 31` invoked (explicit arg overrides inference)
  - **Then**: Command proceeds with task 31 (not 32)

- **TC-C2**: Command without argument (inference succeeds)
  - **Given**: Repository state with task 32 active, correlated signals
  - **When**: `/cig-task-plan` invoked (no argument)
  - **Then**: Command reads task_num from skill output, proceeds with task 32

- **TC-C3**: Command without argument (inference fails - uncorrelated)
  - **Given**: Repository state with conflicting signals
  - **When**: `/cig-task-plan` invoked (no argument)
  - **Then**: LLM prompts user to clarify or provide explicit task number

- **TC-C4**: Command without argument (no signals)
  - **Given**: Repository state with no inferrable context
  - **When**: `/cig-task-plan` invoked (no argument)
  - **Then**: Command shows error "Cannot determine task. Specify task number or ensure context is inferrable."

- **TC-C5**: All 10 commands tested
  - **Given**: Repository state with task 32 active
  - **When**: Each of 10 commands invoked without argument
  - **Then**: All commands successfully infer task 32 and proceed with workflow

### Acceptance Tests (End-to-End Scenarios)

**Scenario 1: Single Active Task (Happy Path)**
- **Given**:
  - Branch: `feature/32-task-tracking-using-inference-scoring`
  - Recent modifications: Task 32 files modified 5 minutes ago
  - Status: d-implementation-plan marked "In Progress"
  - State file: `.cig/current-task` contains "32"
- **When**: Script executed
- **Then**:
  - All 5 signals return task 32 as top candidate (correlated)
  - Output: `task_num: 32`, `task_slug: feature-task-tracking-using-inference-scoring`, `workflow_step: d-implementation-plan`
  - Exit code: 0

**Scenario 2: Multiple Tasks (Uncorrelated)**
- **Given**:
  - Branch: `feature/32-task-tracking-using-inference-scoring`
  - Recent modifications: Task 31 modified 2 minutes ago (more recent than task 32)
  - Status: Task 32 "In Progress", Task 31 "In Progress"
  - State file: `.cig/current-task` contains "32"
- **When**: Script executed
- **Then**:
  - Signals disagree (branch=32, recency=31, state=32, status=ambiguous)
  - Output: User prompt with candidates: "Signals disagree. Choose: 32 (branch/state) or 31 (recency)?"
  - Exit code: 1

**Scenario 3: On Main Branch (No Branch Signal)**
- **Given**:
  - Branch: `main`
  - Recent modifications: Task 32 modified recently
  - Status: Task 32 "In Progress"
  - State file: missing
- **When**: Script executed
- **Then**:
  - Branch signal null, but recency+status+progress agree on task 32
  - Output: task 32 inferred (correlation works with null signals)
  - Exit code: 0

**Scenario 4: Git Worktree Isolation**
- **Given**:
  - Worktree path: `/home/user/worktrees/task-32/`
  - Branch: `feature/32-task-tracking`
  - No shared state file (worktree-specific)
- **When**: Script executed from worktree
- **Then**:
  - Worktree signal (95) + branch signal (100) dominate
  - Output: task 32 inferred correctly
  - Exit code: 0

**Scenario 5: No Signals (Error Case)**
- **Given**:
  - Branch: `main`
  - No recent modifications (all tasks >1 week old)
  - No state file
  - No "In Progress" statuses
- **When**: Script executed
- **Then**:
  - All signals return null or very low scores
  - Output: "Error: Cannot infer current task (no signals detected)"
  - Exit code: 3

### Non-Functional Test Cases

**Performance Tests:**

- **TC-P1**: Execution time - small repository (10 tasks)
  - **Given**: Repository with 10 tasks
  - **When**: Script executed 10 times, average measured
  - **Then**: Average execution time <200ms

- **TC-P2**: Execution time - medium repository (20 tasks)
  - **Given**: Repository with 20 tasks
  - **When**: Script executed 10 times, average measured
  - **Then**: Average execution time <350ms

- **TC-P3**: Execution time - large repository (30 tasks)
  - **Given**: Repository with 30 tasks
  - **When**: Script executed 10 times, average measured
  - **Then**: Average execution time <500ms (requirement met)

- **TC-P4**: No full repository scans
  - **Given**: Repository with 1000 files outside implementation-guide/
  - **When**: Script executed with profiling
  - **Then**: Only implementation-guide/ directory scanned, not entire repo

**Security Tests:**

- **TC-SEC1**: Branch name injection
  - **Given**: Malicious branch name with special characters: `feature/32-$(rm -rf /)`
  - **When**: Script parses branch name
  - **Then**: Special characters sanitized, no command execution, safe parsing

- **TC-SEC2**: State file validation
  - **Given**: State file contains malicious content: `32; rm -rf /`
  - **When**: Script reads state file
  - **Then**: Non-numeric content rejected, warning to stderr, null signal returned

- **TC-SEC3**: Script hash verification
  - **Given**: task-context-inference wrapper installed
  - **When**: `/cig-security-check verify` executed
  - **Then**: SHA256 hash matches entry in script-hashes.json, verification passes

**Usability Tests:**

- **TC-USE1**: Error message clarity - no signals
  - **Given**: Repository state with no inferrable context
  - **When**: Script executed
  - **Then**: Error message clearly explains problem and suggests solution

- **TC-USE2**: Uncorrelated prompt clarity
  - **Given**: Signals disagree on task
  - **When**: Script executed
  - **Then**: Prompt shows top candidates with signal sources, asks user to choose

- **TC-USE3**: Verbose output readability
  - **Given**: Repository state with multiple signals
  - **When**: Script executed with --verbose
  - **Then**: Output uses box-drawing, aligned columns, clear sections, easy to scan

**Reliability Tests:**

- **TC-REL1**: Graceful degradation - missing git
  - **Given**: git command not in PATH
  - **When**: Script executed
  - **Then**: Branch/worktree signals null, other signals still work, no crash

- **TC-REL2**: Graceful degradation - corrupted workflow files
  - **Given**: Task 32 workflow file has malformed Status: line
  - **When**: Script scans status signals
  - **Then**: That file skipped, other files processed, warning to stderr

- **TC-REL3**: Concurrent execution safety
  - **Given**: Script executed simultaneously in 2 terminals
  - **When**: Both scripts run concurrently
  - **Then**: No race conditions, no file corruption, both return correct results (stateless design)

## Test Environment

### Setup Requirements

**Unit Testing Environment:**
- **Framework**: Perl Test::More (standard library)
- **Test Files**: `t/task-context-inference.t`
- **Mock Data**: Inline Perl hashes (no external files needed)
- **Dependencies**: None (library is pure Perl)
- **Execution**: `perl t/task-context-inference.t` or `prove t/`

**Integration Testing Environment:**
- **Test Repository**: Controlled git repository with known state
- **Test Fixtures**:
  - `test-fixtures/single-task/` - Repository with 1 active task
  - `test-fixtures/multiple-tasks/` - Repository with 3 conflicting tasks
  - `test-fixtures/worktree/` - Repository with worktree setup
  - `test-fixtures/no-signals/` - Repository on main, no activity
- **Setup Script**: `t/setup-test-fixtures.sh` creates fixture directories
- **Cleanup Script**: `t/cleanup-test-fixtures.sh` removes fixtures after tests

**System Testing Environment:**
- **Tool**: Claude Code (manual invocation)
- **Repository State**: Real implementation-guide/ with Task 32 active
- **Skills**: Installed in `.claude/skills/`
- **Commands**: Installed in `.claude/commands/`
- **Manual Steps**: Documented test procedures for each command

**Performance Testing Environment:**
- **Repository Sizes**: 10, 20, 30 task directories created via script
- **Timing Tool**: `time` command or `Benchmark.pm`
- **Hardware**: Standard development machine (document specs)
- **Runs**: 10 iterations per test, average reported

### Automation

**Unit Tests:**
- **Automation Level**: 100% automated
- **Execution**: `prove t/task-context-inference.t`
- **CI Integration**: Run on every commit to feature branch
- **Pass Criteria**: All tests pass, no warnings

**Integration Tests:**
- **Automation Level**: 90% automated (scripts with verification checks)
- **Execution**: `./t/run-integration-tests.sh`
- **CI Integration**: Run on pull request creation
- **Pass Criteria**: All scenarios return expected exit codes and output

**System Tests:**
- **Automation Level**: 50% automated (command invocation, manual verification)
- **Execution**: `./t/test-command-integration.sh` (invokes commands, checks output)
- **CI Integration**: Manual verification before merge
- **Pass Criteria**: Commands work without arguments, infer correct task

**Acceptance Tests:**
- **Automation Level**: 80% automated (scripted scenarios with checks)
- **Execution**: `./t/run-acceptance-tests.sh`
- **CI Integration**: Run before release/merge to main
- **Pass Criteria**: All 5 scenarios pass, ≥95% accuracy across 20 iterations

**Performance Tests:**
- **Automation Level**: 100% automated
- **Execution**: `./t/run-performance-tests.sh`
- **CI Integration**: Run on pull request, flag if regression >10%
- **Pass Criteria**: <500ms for 30 tasks, no regressions

### Test Execution Schedule

**Pre-Commit**: Unit tests (fast, ~5 seconds)
**Pre-Push**: Unit + integration tests (~30 seconds)
**Pull Request**: All tests except manual system tests (~2 minutes)
**Pre-Merge**: Full test suite including manual verification (~10 minutes)
**Post-Deployment**: Smoke test in production (script execution, verify exit code)

## Validation Criteria

### Test Execution Criteria
- [ ] All 16 unit tests passing (TC-U1 through TC-U16)
- [ ] All 5 integration tests passing (TC-I1 through TC-I5)
- [ ] All 3 skill tests passing (TC-S1 through TC-S3)
- [ ] All 5 command integration tests passing (TC-C1 through TC-C5)
- [ ] All 5 acceptance scenario tests passing (Scenarios 1-5)
- [ ] All 4 performance tests passing (TC-P1 through TC-P4)
- [ ] All 3 security tests passing (TC-SEC1 through TC-SEC3)
- [ ] All 3 usability tests passing (TC-USE1 through TC-USE3)
- [ ] All 3 reliability tests passing (TC-REL1 through TC-REL3)

**Total**: 47 test cases, 100% pass rate required

### Coverage Criteria
- [ ] Library function coverage ≥90% (line coverage via Devel::Cover)
- [ ] Signal collection functions 100% covered (6 task signals + 3 step signals = 9 functions)
- [ ] Scoring algorithms 100% covered (3 algorithms: recency, progress, status)
- [ ] Correlation logic 100% covered (all branches: correlated, uncorrelated, no signals)
- [ ] Wrapper script 100% covered (all exit codes: 0, 1, 2, 3)

### Performance Criteria
- [ ] Execution time <500ms for 30-task repository (TC-P3)
- [ ] No full repository scans verified (TC-P4)
- [ ] Performance regression <10% compared to baseline

### Accuracy Criteria
- [ ] ≥95% correct inferences across 20 realistic test scenarios
- [ ] 0 false positives (never guesses wrong task when signals uncorrelated)
- [ ] All uncorrelated scenarios correctly prompt user (100% detection rate)

### Security Criteria
- [ ] Branch name injection prevented (TC-SEC1)
- [ ] State file content validated (TC-SEC2)
- [ ] Script hash verification passes (TC-SEC3)
- [ ] No command execution vulnerabilities

### Integration Criteria
- [ ] All 10 workflow commands work without arguments (when context inferrable)
- [ ] All 10 workflow commands work with arguments (backward compatibility)
- [ ] No regressions in existing task workflows (Tasks 26, 29, 31 still work)
- [ ] Skills execute successfully in LLM context

### Requirements Traceability
**Functional Requirements (FR1-FR5):**
- [ ] FR1: All 9 signals implemented and tested (AC1-AC2)
- [ ] FR2: Top-5 scoring verified per signal (AC via TC-U7, TC-U11-U14)
- [ ] FR3: Correlation logic correct (AC via TC-U11-U14, Scenarios 1-2)
- [ ] FR4: Both skills created and functional (AC9-AC11 via TC-S1-S3)
- [ ] FR5: All 10 commands integrated (AC12-AC15 via TC-C1-C5)

**Non-Functional Requirements (NFR1-NFR5):**
- [ ] NFR1: Performance <500ms (AC via TC-P1-P4)
- [ ] NFR2: Usability (AC via TC-USE1-USE3)
- [ ] NFR3: Maintainability (AC: library architecture verified, no inline logic duplication)
- [ ] NFR4: Security (AC via TC-SEC1-SEC3)
- [ ] NFR5: Reliability (AC via TC-REL1-REL3, Scenarios 3-5)

**Acceptance Criteria from Requirements (AC1-AC23):**
- [ ] AC1-AC8: Library implementation validated via unit tests
- [ ] AC9-AC11: Skills validated via system tests
- [ ] AC12-AC15: Commands validated via integration tests
- [ ] AC16-AC19: Testing and performance validated via this plan
- [ ] AC20-AC23: Documentation and security validated via manual checks

## Test Execution Order

**Recommended Sequence:**

1. **Unit Tests First** (TC-U1 through TC-U16)
   - Test library functions in isolation as they're implemented
   - Quick feedback loop (seconds per test)
   - Foundation for integration tests

2. **Integration Tests** (TC-I1 through TC-I5)
   - Test wrapper script once library is stable
   - Verify exit codes and output formatting
   - Ensures CLI layer works correctly

3. **System Tests** (TC-S1 through TC-S3, TC-C1 through TC-C5)
   - Test skills and commands after wrapper is working
   - Manual verification with Claude Code
   - Ensures full stack integration

4. **Acceptance Tests** (Scenarios 1-5)
   - End-to-end validation with realistic scenarios
   - Verify requirements are met
   - Final check before considering complete

5. **Non-Functional Tests** (Performance, Security, Usability, Reliability)
   - Performance tests throughout development (regression detection)
   - Security tests before merge
   - Usability and reliability tests during acceptance

## Test Deliverables

**Test Code:**
- `t/task-context-inference.t` - Unit test suite (16 tests)
- `t/run-integration-tests.sh` - Integration test script (5 scenarios)
- `t/run-acceptance-tests.sh` - Acceptance test script (5 scenarios)
- `t/run-performance-tests.sh` - Performance benchmark script (4 tests)
- `t/setup-test-fixtures.sh` - Fixture setup automation
- `t/cleanup-test-fixtures.sh` - Fixture cleanup automation

**Test Documentation:**
- Test results summary (pass/fail counts, coverage report)
- Performance benchmark results (execution times, comparison to baseline)
- Known issues and limitations discovered during testing
- Manual test procedures for system tests (command integration)

**Test Artifacts:**
- Coverage report (HTML from Devel::Cover)
- Performance graphs (execution time vs repository size)
- Security test results (injection attempts, validation checks)

## Status
**Status**: Finished
**Next Action**: Move to implementation execution → `/cig-implementation-exec 32`
**Alternative**: Begin implementation with TDD approach (write tests alongside code)
**Blockers**: None identified

**Note**: Testing plan is comprehensive with 47 test cases across 4 levels (unit, integration, system, acceptance). Implementation execution should follow TDD approach: write unit test, implement function, verify test passes, repeat.

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
