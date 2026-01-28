# task-tracking-using-inference-scoring - Implementation

## Task Reference
- **Task ID**: internal-32
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/32-task-tracking-using-inference-scoring
- **Template Version**: 2.1

## Goal
Implement signal-based inference system with library + wrapper architecture: TaskContextInference.pm library (all logic), thin CLI wrapper, two skills, and 10 command updates.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify

### Primary Changes (New Files)

**0. `.cig/lib/TaskState.pm`** (NEW, ~200-300 lines) - **ADDED DURING IMPLEMENTATION**
- Shared state measurement library
- `state_done()` - Retrospective completion (MIN bottleneck, for status-aggregator)
- `state_achievable()` - Prospective work potential (cliff function, for inference)
- `status_percent()` - Map status strings to percentages
- `status_extract()` - Extract status from workflow files
- MSB naming convention (category-first: state_*, status_*)
- Eliminates ~200 lines duplicate code from status-aggregator scripts
- **Note**: Discovered during Phase 1 that progress serves two distinct purposes. Created shared library to provide both retrospective ("where are we?") and prospective ("where should we work?") state measurements.

**1. `.cig/lib/TaskContextInference.pm`** (NEW, ~600-700 lines)
- Core library with all inference logic
- Signal collection functions (8 signals: 5 task + 3 workflow step)
  - **Note**: Originally planned as 9 signals (6 task + 3 workflow), but Status signal removed during Phase 1 implementation. Testing revealed Status to be lower quality (manual, stale) while heavily correlating with Progress signal (mechanical). Completed tasks ("Finished" = 100 pts) dominated current task ("In Progress" = 80 pts), causing false negatives.
- Scoring algorithms (recency decay, progress linear/cliff - **UPDATED from bell curve**)
- Correlation logic (check if all non-null signals agree)
- Output formatting (simple vs verbose)
- Pure functions: returns data structures, no I/O in library
- Uses TaskState::state_achievable() for progress signal

**2. `.cig/scripts/command-helpers/task-context-inference`** (NEW, ~80-100 lines)
- Thin CLI wrapper over library
- Parse --verbose flag
- Call `infer_task_context()` from library
- Print formatted output
- Set exit codes (0=success, 1=uncorrelated, 2=error, 3=no signals)
- Add shebang, make executable (chmod 755)

**3. `.claude/skills/current-task-wf.md`** (NEW, ~10 lines)
- Simple skill: call task-context-inference (default mode)
- Returns 3-line output in LLM context

**4. `.claude/skills/current-task-wf-verbose.md`** (NEW, ~12 lines)
- Verbose skill: call task-context-inference --verbose
- Returns full signal breakdown in LLM context

### Supporting Changes (Modified Files)

**5. `.cig/scripts/command-helpers/status-aggregator-v2.0`** (MODIFIED) - **ADDED DURING IMPLEMENTATION**
- Refactor to use TaskState::state_done()
- Replace calculate_progress() with library call
- Replace status_to_percent() with TaskState::status_percent()
- Replace extract_status() with TaskState::status_extract()
- Eliminates ~100 lines duplicate code
- Behavior unchanged (still uses MIN bottleneck formula)

**6. `.cig/scripts/command-helpers/status-aggregator-v2.1`** (MODIFIED) - **ADDED DURING IMPLEMENTATION**
- Same refactor as v2.0
- Ensures consistent behavior across versions
- Uses shared TaskState library

**7-16. Command Updates** (10 files, ~15 lines each):
- `.claude/commands/cig-task-plan.md`
- `.claude/commands/cig-requirements-plan.md`
- `.claude/commands/cig-design-plan.md`
- `.claude/commands/cig-implementation-plan.md`
- `.claude/commands/cig-testing-plan.md`
- `.claude/commands/cig-implementation-exec.md`
- `.claude/commands/cig-testing-exec.md`
- `.claude/commands/cig-rollout.md`
- `.claude/commands/cig-maintenance.md`
- `.claude/commands/cig-retrospective.md`

**Changes per command**:
  - Add context line: `- Current task/workflow (if available): !/current-task-wf`
  - Update step 1 argument handling to check skill output if no explicit arg
  - No changes to remaining workflow logic

**17. `.cig/security/script-hashes.json`** (MODIFIED)
- Add SHA256 hash for task-context-inference wrapper script
- Entry: `"task-context-inference": "sha256:..."`

### Test Files (New)

**18. `t/task-state.t`** (NEW, ~100-150 lines) - **ADDED DURING IMPLEMENTATION**
- Unit tests for TaskState library functions
- Test state_done() with various status combinations
- Test state_achievable() for blocked, active, complete, fresh tasks
- Test cliff function behavior at 100%
- Test fresh task baseline (10%)
- Test linear ramp for active tasks

**19. `t/task-context-inference.t`** (NEW, ~200-300 lines)
- Unit tests for library functions
- Test each signal independently
- Test scoring algorithms
- Test correlation logic
- Test output formatting

## Implementation Approach

**Phased Implementation with Checkpoint Commits:**

- **Phase 1 (Steps 1-7)**: Library Core Implementation
  - Create TaskContextInference.pm with all signal collection, scoring, correlation, and output logic
  - Checkpoint: Library complete, syntax-checked, ready for wrapper integration
  - Commit message: "Task 32 Phase 1: Implement TaskContextInference library core"

- **Phase 2 (Steps 8-11)**: Integration Layer
  - Create wrapper script, skills, update commands, add security hashes
  - Checkpoint: Full stack integrated, skills and commands functional
  - Commit message: "Task 32 Phase 2: Add wrapper, skills, and command integration"

- **Phase 3 (Steps 12-13)**: Testing & Finalization
  - Integration testing, documentation, cleanup
  - Checkpoint: Tested, documented, ready for testing execution phase
  - Commit message: "Task 32 Phase 3: Integration tests and documentation"

## Implementation Steps

### Phase 1: Library Core Implementation (Steps 1-7)

### Step 1: Create Library Directory and Module Skeleton
- [ ] Create `.cig/lib/` directory if it doesn't exist
- [ ] Create `.cig/lib/TaskContextInference.pm` with package declaration
- [ ] Add strict/warnings pragmas, Exporter setup
- [ ] Define public API: `@EXPORT_OK = qw(infer_task_context get_all_signals correlate_signals format_output)`
- [ ] Add module version and POD skeleton
- [ ] Test: `perl -c .cig/lib/TaskContextInference.pm` (syntax check)

### Step 2: Implement Signal Collection Functions (Task Signals)
- [ ] Implement `_get_branch_signal()` - parse git branch name
  - Use `git rev-parse --abbrev-ref HEAD`
  - Regex match `<type>/<num>-<slug>` pattern
  - Return: `{ name => 'branch', weight => 100, candidates => [{task => N, score => 100}], top => N, null => 0|1 }`
- [ ] Implement `_get_worktree_signal()` - detect worktree context
  - Use `git worktree list` to get all worktrees
  - Check if CWD is in worktree path
  - Extract task number from worktree path pattern
- [ ] Implement `_get_state_file_signal()` - read .cig/current-task
  - Check if file exists, read content
  - Validate content is numeric
  - Return null if missing or malformed
- [ ] Implement `_get_recency_signal()` - scan task directories for recent modifications
  - Find all `implementation-guide/*/` directories
  - Get max mtime of workflow files per task
  - Score top 5 with exponential decay formula
- [ ] Implement `_get_progress_signal()` - calculate task completion percentage
  - For each task, count workflow files and "Finished" status markers
  - Calculate percentage complete
  - Score top 5 with bell curve (peak at 50%)
- [ ] ~~Implement `_get_status_signal()`~~ - **REMOVED DURING IMPLEMENTATION**
  - Reason: Low quality signal (manual, stale) that heavily correlates with Progress signal
  - Completed tasks dominated with 100 pt scores vs current task 80 pts (false negatives)
  - Status signal retained only for workflow step inference, not task inference
- [ ] Test: Create unit tests for each signal function with mock data

### Step 3: Implement Signal Collection Functions (Workflow Step Signals)
- [ ] Implement `_get_step_status_signal()` - find "In Progress" workflow file
  - For given task, scan all workflow files
  - Find file with `Status: In Progress`
  - Return workflow step name (e.g., "d-implementation-plan")
- [ ] Implement `_get_step_recency_signal()` - most recently modified workflow file
  - Get mtime of all workflow files in task directory
  - Return filename of newest file
- [ ] Implement `_get_step_sequence_signal()` - predict next step after "Finished"
  - Scan workflow files for "Status: Finished"
  - Determine workflow order based on task type (feature, bugfix, etc.)
  - Return next step in sequence
- [ ] Test: Unit tests for workflow step signals

### Step 4: Implement Scoring Algorithms
- [ ] Implement `_score_recency($seconds_ago)` - exponential decay
  - Formula: `90 * exp(-seconds_ago / decay_constant)`
  - Peak at 90 points for very recent (5 min)
  - Decay over time (1hr=70, 24hr=20, 1week=5)
- [ ] Implement `_score_progress($percentage)` - bell curve
  - Formula: Gaussian centered at 50%
  - Peak at 60 points for 50% complete
  - Lower scores for 0%, 100% (less likely to be active work)
- [ ] ~~Implement `_score_status($status_value)`~~ - **REMOVED** (Status signal not used for task inference)
- [ ] Test: Unit tests for each scoring function with various inputs

### Step 5: Implement Correlation Logic
- [ ] Implement `get_all_signals()` - collect all signals and return array
  - Call each signal function
  - Return array of signal result hashes
- [ ] Implement `correlate_signals(\@signals)` - check if all non-null signals agree
  - Extract top task from each non-null signal
  - Count unique top tasks
  - If count == 1 → correlated (all agree)
  - If count > 1 → uncorrelated (disagreement)
  - Return correlation hash with decision
- [ ] Implement workflow step correlation (similar logic for step signals)
- [ ] Test: Unit tests for correlation with various signal combinations

### Step 6: Implement Output Formatting
- [ ] Implement `format_output($context, $verbose)` - format result string
  - Simple mode: 3 lines (task_num, task_slug, workflow_step)
  - Verbose mode: simple + full signal breakdown with box-drawing
  - Handle uncorrelated case: show top candidates, prompt user
  - Handle no signals case: error message
- [ ] Implement `_format_verbose_breakdown(\@signals, $correlation)` - detailed output
  - Show all signals with scores
  - Show correlation analysis
  - Use Unicode box-drawing characters
- [ ] Test: Unit tests for output formatting with various scenarios

### Step 7: Implement Main Entry Point
- [ ] Implement `infer_task_context(%opts)` - main public function
  - Call `get_all_signals()`
  - Call `correlate_signals()`
  - Determine task slug from task number (scan directory names)
  - Infer workflow step (call step signals)
  - Build context hash
  - Format output string
  - Return: `{ task_num => N, task_slug => '...', workflow_step => '...', confidence => '...', output => '...' }`
- [ ] Add error handling (try/catch, validate inputs)
- [ ] Test: Integration test calling main function with realistic repository state

### Phase 1.5: Shared State Library (Steps 8-11) - **ADDED DURING IMPLEMENTATION**

**Checkpoint Commit After Phase 1**: Library core complete and syntax-checked

**Discovery**: During testing, found progress signal causes false positives. Progress serves two purposes: retrospective (completion) vs prospective (work potential). Solution: Create shared TaskState library with both measurements.

### Step 8: Create TaskState.pm Library
- [ ] Create `.cig/lib/TaskState.pm` with package declaration
- [ ] Add strict/warnings pragmas, Exporter setup
- [ ] Define public API: `@EXPORT_OK = qw(state_done state_achievable status_percent status_extract)`
- [ ] Implement `state_done()` - MIN bottleneck formula (for status-aggregator)
- [ ] Implement `state_achievable()` - Cliff function (for inference)
  - 100% complete → 0 (CLIFF: no work left)
  - Blocked → 0 (can't progress)
  - Fresh (0%, no active) → 10 (baseline)
  - Active → completion % (linear ramp)
- [ ] Implement `status_percent()` - Map status strings to percentages
- [ ] Implement `status_extract()` - Extract status from workflow files
- [ ] Add private helpers: _get_all_statuses, _is_blocked_or_finished, _is_active_work
- [ ] Test: `perl -c .cig/lib/TaskState.pm` (syntax check)

### Step 9: Refactor status-aggregator-v2.0 to Use TaskState
- [ ] Add `use TaskState qw(state_done status_percent status_extract);` at top
- [ ] Replace `calculate_progress()` function with call to `TaskState::state_done()`
- [ ] Replace `status_to_percent()` function with call to `TaskState::status_percent()`
- [ ] Replace `extract_status()` function with call to `TaskState::status_extract()`
- [ ] Test: Run status-aggregator-v2.0 --workflow 11 to verify unchanged behavior (25%)

### Step 10: Refactor status-aggregator-v2.1 to Use TaskState
- [ ] Same refactor as v2.0
- [ ] Ensure consistent behavior across versions
- [ ] Test: Verify both versions produce identical output

### Step 11: Update TaskContextInference to Use state_achievable
- [ ] Add `use TaskState qw(state_achievable);` at top
- [ ] Replace `_calculate_task_progress()` with call to `TaskState::state_achievable()`
- [ ] Update `_score_progress()` from bell curve to linear scoring:
  ```perl
  sub _score_progress {
      my ($percentage) = @_;
      return 0 unless defined $percentage && $percentage >= 0 && $percentage <= 100;
      # Linear scoring (cliff function)
      my $score = int(($percentage / 100) * WEIGHT_PROGRESS_MAX);
      return $score;
  }
  ```
- [ ] Test: Run task-context-inference --verbose to verify Task 11 scores 0, Task 32 correlates

**Checkpoint Commit After Phase 1.5**: Shared library created, refactoring complete, inference fixed

### Phase 2: Integration Layer (Steps 12-15)

### Step 12: Create CLI Wrapper Script
- [ ] Create `.cig/scripts/command-helpers/task-context-inference`
- [ ] Add shebang: `#!/usr/bin/env perl`
- [ ] Add `use lib` to find `.cig/lib/` directory
- [ ] Parse command line arguments (--verbose flag)
- [ ] Call `infer_task_context(verbose => $verbose)`
- [ ] Print output to STDOUT
- [ ] Set exit codes based on confidence:
  - 0: correlated (success)
  - 1: uncorrelated (user prompt shown)
  - 2: error (exceptions, malformed data)
  - 3: no signals (cannot infer)
- [ ] Make executable: `chmod 755 .cig/scripts/command-helpers/task-context-inference`
- [ ] Test: Run script manually with various repository states

### Step 13: Create Skills
- [ ] Create `.claude/skills/current-task-wf.md`:
  ```markdown
  ---
  description: Infer current task and workflow step (simple output)
  ---

  Current task and workflow step:

  !`.cig/scripts/command-helpers/task-context-inference 2>/dev/null || echo "Unable to infer context"`
  ```
- [ ] Create `.claude/skills/current-task-wf-verbose.md`:
  ```markdown
  ---
  description: Infer current task with verbose signal breakdown
  ---

  Current task inference (verbose):

  !`.cig/scripts/command-helpers/task-context-inference --verbose 2>/dev/null || echo "Unable to infer context"`
  ```
- [ ] Test: Invoke skills manually and verify output

### Step 14: Update Workflow Commands (Sample: cig-task-plan.md)
- [ ] Read existing `.claude/commands/cig-task-plan.md`
- [ ] Add context line under `## Context`:
  ```markdown
  - Current task/workflow (if available): !/current-task-wf
  ```
- [ ] Update step 1 "Get Task Path" logic:
  ```markdown
  1. **Get Task Path**:
     - Check if argument provided in task arguments
     - If no argument: read task_num from /current-task-wf skill output above
     - If neither: error "Cannot determine task. Specify task number or ensure context is inferrable."
  ```
- [ ] Test: Invoke command without argument, verify it uses inference
- [ ] Repeat for all 10 commands (cig-requirements-plan, cig-design-plan, etc.)

### Step 11: Update Security Hashes
- [ ] Generate SHA256 hash for task-context-inference wrapper:
  ```bash
  sha256sum .cig/scripts/command-helpers/task-context-inference
  ```
- [ ] Add entry to `.cig/security/script-hashes.json`:
  ```json
  {
    "task-context-inference": "sha256:abcdef123456..."
  }
  ```
- [ ] Test: Run `/cig-security-check verify` to confirm hash validates

### Phase 3: Testing & Finalization (Steps 12-13)

**Checkpoint Commit After Phase 2**: Wrapper, skills, and commands integrated

### Step 12: Integration Testing
- [ ] Create test scenarios in scratchpad or test environment:
  - Scenario 1: Single task in progress (all signals agree)
  - Scenario 2: Multiple tasks in progress (signals disagree)
  - Scenario 3: On main branch (no branch signal)
  - Scenario 4: In worktree (worktree signal strongest)
  - Scenario 5: No signals (error case)
- [ ] Run script for each scenario, verify output and exit codes
- [ ] Test command invocation without arguments for each scenario
- [ ] Verify performance: time script execution (<500ms requirement)

### Step 13: Documentation and Cleanup
- [ ] Add POD documentation to TaskContextInference.pm (function descriptions)
- [ ] Add usage examples to wrapper script header comments
- [ ] Update `.cig/docs/context/state-tracking.md` if implementation differs from design
- [ ] Remove debug logging/verbose output from production code
- [ ] Final syntax check: `perl -c` for library and wrapper

## Code Changes

### Library Module Structure

**TaskContextInference.pm** (skeleton):
```perl
package TaskContextInference;
use strict;
use warnings;
use Exporter 'import';
use Cwd;
use File::Find;
use File::Basename;

our $VERSION = '1.0';
our @EXPORT_OK = qw(
    infer_task_context
    get_all_signals
    correlate_signals
    format_output
);

# Weight constants
use constant {
    WEIGHT_BRANCH => 100,
    WEIGHT_WORKTREE => 95,
    WEIGHT_STATE => 85,
    WEIGHT_RECENCY_MAX => 90,
    WEIGHT_PROGRESS_MAX => 60,
    WEIGHT_STATUS_MAX => 80,
    WEIGHT_STEP_STATUS => 100,
    WEIGHT_STEP_RECENCY_MAX => 90,
    WEIGHT_STEP_SEQUENCE => 70,
};

# Main entry point
sub infer_task_context {
    my %opts = @_;
    my $verbose = $opts{verbose} || 0;

    my @signals = get_all_signals();
    my $correlation = correlate_signals(\@signals);

    # ... build context, determine slug, infer step

    return {
        task_num => $task_num,
        task_slug => $slug,
        workflow_step => $step,
        confidence => $correlation->{confidence},
        output => format_output(\%context, $verbose),
    };
}

# Signal collection
sub get_all_signals {
    my @signals;
    push @signals, _get_branch_signal();
    push @signals, _get_worktree_signal();
    push @signals, _get_state_file_signal();
    push @signals, _get_recency_signal();
    push @signals, _get_progress_signal();
    push @signals, _get_status_signal();
    return @signals;
}

# Correlation check
sub correlate_signals {
    my ($signals) = @_;

    my @non_null = grep { !$_->{null} } @$signals;
    return { confidence => 'no_signals' } if @non_null == 0;

    my @top_tasks = map { $_->{top} } @non_null;
    my %seen;
    $seen{$_}++ for @top_tasks;
    my @unique = keys %seen;

    if (@unique == 1) {
        return {
            confidence => 'correlated',
            chosen_task => $unique[0],
            signals => $signals,
        };
    } else {
        return {
            confidence => 'uncorrelated',
            candidates => \@unique,
            signals => $signals,
        };
    }
}

# Output formatting
sub format_output {
    my ($context, $verbose) = @_;

    my $output = sprintf(
        "task_num: %s\ntask_slug: %s\nworkflow_step: %s\n",
        $context->{task_num},
        $context->{task_slug},
        $context->{workflow_step}
    );

    if ($verbose) {
        $output .= "\nSignal Breakdown:\n";
        $output .= _format_verbose_breakdown($context->{signals}, $context->{correlation});
    }

    return $output;
}

# Private functions (_get_branch_signal, _score_recency, etc.)
# ...

1;  # End of module
```

### CLI Wrapper Structure

**task-context-inference** (wrapper):
```perl
#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib";  # Find .cig/lib/
use TaskContextInference qw(infer_task_context);

# Parse arguments
my $verbose = 0;
$verbose = 1 if grep { $_ eq '--verbose' } @ARGV;

# Call library
my $context = eval { infer_task_context(verbose => $verbose) };

if ($@) {
    # Exception occurred
    print STDERR "Error: $@\n";
    exit 2;
}

# Print output
print $context->{output};

# Exit with appropriate code
exit 0 if $context->{confidence} eq 'correlated';
exit 1 if $context->{confidence} eq 'uncorrelated';
exit 3 if $context->{confidence} eq 'no_signals';
exit 2;  # Unknown confidence (shouldn't happen)
```

### Skill Example

**current-task-wf.md**:
```markdown
---
description: Infer current task and workflow step (simple output)
---

Current task and workflow step (inferred from environmental signals):

!`.cig/scripts/command-helpers/task-context-inference 2>/dev/null || echo "Unable to infer context"`
```

### Command Update Example

**Before** (cig-task-plan.md - step 1):
```markdown
1. **Resolve Task Directory**:
   - Extract first word from task arguments
   - Validate it matches hierarchical number format (digits and dots only)
   - If valid: call `.cig/scripts/command-helpers/hierarchy-resolver <task-path>` using the Bash tool
   - If invalid: inform user the task path format is invalid, do not invoke script
```

**After** (cig-task-plan.md - step 1):
```markdown
1. **Resolve Task Directory**:
   - **If argument provided**: Extract first word from task arguments, validate format
   - **If no argument**: Check /current-task-wf skill output above for task_num
     - If skill succeeded: use task_num from output
     - If skill failed: error "Cannot determine task. Specify task number or ensure context is inferrable."
   - Validate task path format (digits and dots only)
   - Call `.cig/scripts/command-helpers/hierarchy-resolver <task-path>` using the Bash tool
```

And add to Context section:
```markdown
## Context
- Current task/workflow (if available): !/current-task-wf
```

## Test Coverage
**See e-testing-plan.md for complete test plan**

### Unit Tests (per function)
- Branch signal parsing: 5 test cases (feature/32-slug, chore/31-slug, main, invalid, detached HEAD)
- Worktree signal detection: 4 test cases (in worktree, not in worktree, multiple worktrees, no worktrees)
- State file reading: 3 test cases (valid file, missing file, malformed content)
- Recency scoring: 4 test cases (5min=90, 1hr=70, 24hr=20, 1week=5)
- Progress scoring: 5 test cases (0%=10, 25%=45, 50%=60, 75%=45, 100%=10)
- Status scoring: 4 test cases (In Progress=80, Testing=75, Implemented=50, Backlog=0)
- Correlation logic: 6 test cases (all agree, 2 disagree, 3+ disagree, all null, partial null, edge cases)

### Integration Tests (end-to-end)
- Scenario 1: Single task, all signals correlated → verify task_num, slug, step returned
- Scenario 2: Multiple tasks, signals uncorrelated → verify user prompt with candidates
- Scenario 3: No signals (main branch, no state, no recent activity) → verify error message
- Scenario 4: Worktree scenario → verify worktree signal dominates
- Scenario 5: Command invocation without arg → verify uses inference result

### Performance Tests
- Measure script execution time with 1, 10, 20, 30 tasks
- Target: <500ms for 30 tasks on standard hardware
- Profile slow operations if threshold exceeded

## Validation Criteria

### Functional Validation
- [ ] Library syntax check passes: `perl -c .cig/lib/TaskContextInference.pm`
- [ ] Wrapper syntax check passes: `perl -c .cig/scripts/command-helpers/task-context-inference`
- [ ] All unit tests pass (≥95% pass rate)
- [ ] All integration tests pass (100% pass rate)
- [ ] Manual testing: script returns correct task for current repository state
- [ ] Skills execute successfully and return output in context
- [ ] Commands work without arguments (use inference)
- [ ] Commands work with arguments (explicit wins over inference)

### Non-Functional Validation
- [ ] Performance: Script executes in <500ms (verified via `time` command)
- [ ] Accuracy: ≥95% correct inferences across 20 test scenarios
- [ ] Error handling: Graceful failures with actionable error messages
- [ ] Exit codes: Correct codes (0,1,2,3) for each scenario
- [ ] Security: Hash verification passes for wrapper script

### Integration Validation
- [ ] All 10 commands updated and tested individually
- [ ] Backward compatibility: Commands still work with explicit task arguments
- [ ] No regressions: Existing tasks/workflows unaffected
- [ ] Documentation: POD in library, usage examples in wrapper

### Acceptance Criteria (from requirements)
- [ ] AC1-AC8: Library implementation complete and tested
- [ ] AC9-AC11: Skills created and functional
- [ ] AC12-AC15: Commands integrated without inline logic duplication
- [ ] AC16-AC19: Testing complete with required coverage
- [ ] AC20-AC23: Documentation and security updates complete

## Implementation Notes

### Development Order Rationale
1. **Library first**: All logic in testable module before CLI concerns
2. **Signals incrementally**: Test each signal independently before integration
3. **Correlation separately**: Pure logic function, easy to unit test
4. **Wrapper last**: Thin layer once library is stable
5. **Skills and commands**: Integration layer after core is working

### Key Implementation Principles
- **Test-driven**: Write unit tests as signals are implemented (not after)
- **Mock-friendly**: Library functions accept data structures (no hardcoded file paths)
- **Fail fast**: Validate inputs early, clear error messages
- **Conservative correlation**: When uncertain (uncorrelated), ask user instead of guessing

### Common Pitfalls to Avoid
1. **Don't mix I/O with logic**: Library returns data structures, wrapper handles printing
2. **Don't hardcode paths**: Use parameters or CWD-relative paths
3. **Don't skip null signal handling**: Null signals must be excluded from correlation
4. **Don't optimize prematurely**: Get correctness first, optimize if <500ms not met
5. **Don't forget exit codes**: Wrapper must return correct codes for each scenario

### Dependencies Between Steps
- Steps 1-7: Can be done incrementally (library development)
- Step 8: Requires step 7 complete (wrapper needs library API)
- Step 9: Requires step 8 complete (skills call wrapper)
- Step 10: Requires step 9 complete (commands reference skills)
- Step 11-13: Can be done in parallel (integration, security, docs)

### Estimated Effort Per Step
- Steps 1-4 (signals): ~4-6 hours (core complexity)
- Steps 5-7 (correlation, output): ~2-3 hours
- Step 8 (wrapper): ~1 hour
- Steps 9-10 (skills, commands): ~2-3 hours (10 commands × 15min each)
- Steps 11-13 (testing, security, docs): ~2-3 hours
- **Total**: ~11-15 hours (1.5-2 days focused work)

## Status
**Status**: Finished
**Next Action**: Move to testing planning → `/cig-testing-plan 32`
**Alternative**: Begin implementation execution → `/cig-implementation-exec 32` (skip testing plan if straightforward)
**Blockers**: None identified

**Note**: Implementation plan is comprehensive with 13 detailed steps. Testing plan should define specific test cases, mock data, and validation criteria referenced in this document.

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
