# task-tracking-using-inference-scoring - Design

## Task Reference
- **Task ID**: internal-32
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/32-task-tracking-using-inference-scoring
- **Template Version**: 2.1

## Goal
Define implementation architecture for signal-based inference system with library-based design: task-context-inference helper script, two skills for LLM access, and mechanical command integration.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions

### Architecture Choice: Library-Based with Skills Abstraction

- **Decision**: Single-source-of-truth library (task-context-inference Perl script) with thin skill wrappers for LLM access
- **Rationale**:
  - All scoring/correlation logic in one testable script
  - Skills are <10 line wrappers (no logic duplication)
  - Commands are mechanical updates (~15 lines each) that reference skill output
  - Aligns with stated commands→skills migration strategy
  - Enables independent testing: library first, then integration
- **Trade-offs**:
  - ✅ **Pro**: Testability (library is pure logic, easily unit-testable)
  - ✅ **Pro**: Maintainability (single source of truth for all inference)
  - ✅ **Pro**: Performance (script runs once, skills just format output)
  - ✅ **Pro**: Simplicity (no logic in LLM prompts, clear separation)
  - ❌ **Con**: Adds skills layer (but very thin, minimal overhead)
  - ❌ **Con**: Commands depend on skill execution (mitigated: skills are fast <200ms)

### Technology Stack

- **Scripting Language**: Perl 5.x (matches existing helper scripts)
  - Rationale: Consistency with hierarchy-resolver, status-aggregator, format-detector
  - use strict; use warnings; exit codes (0=success, 1=uncorrelated, 2=error, 3=no signals)
  - File::Find for directory traversal, Git commands via system()
- **Skills**: Claude Code skill format (.md files in .claude/skills/)
  - Rationale: Native integration with Claude Code, context injection
  - Simple ! syntax for command execution
- **Command Format**: Claude Code command format (.md files in .claude/commands/)
  - Rationale: Existing CIG commands use this format
  - Skill references via `/skill-name` in context section

## System Design

### Component Overview

**Architecture**: Library + Thin Wrapper Pattern
- Library contains all business logic (testable, reusable)
- Wrapper handles CLI concerns (arg parsing, output, exit codes)
- Skills and commands only interact with wrapper script

#### Component 0: TaskState.pm (Shared State Library) - **ADDED DURING IMPLEMENTATION**
**Location**: `.cig/lib/TaskState.pm`

**Purpose**: Shared library for task state measurements - both retrospective (completion) and prospective (work potential)

**Responsibilities**:
- Provide state_done() for retrospective completion (MIN bottleneck formula)
- Provide state_achievable() for prospective work potential (cliff function)
- Extract and map status values from workflow files
- Eliminate duplicate code between status-aggregator and TaskContextInference

**Naming Convention**: MSB (Most Significant Byte) ordering
- Category-first: `state_*` for measurements, `status_*` for utilities
- Noun forms (present perfect gerund): measurements are states, not actions
- Examples: state_done (what's been accomplished), state_achievable (what could be accomplished)

**Public API** (exported functions):
```perl
package TaskState;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(
    state_done
    state_achievable
    status_percent
    status_extract
);

# Retrospective: completion measurement (0-100%)
sub state_done {
    my ($task_dir) = @_;
    # MIN bottleneck formula (for status-aggregator)
    # Returns: MAX(MIN(all statuses), base 25%)
}

# Prospective: work potential measurement (0-100%)
sub state_achievable {
    my ($task_dir) = @_;
    # Cliff function (for inference)
    # Returns: Linear ramp with cliff at 100%
    # - 100% complete → 0 (CLIFF: no work left)
    # - Blocked → 0 (can't progress)
    # - Fresh (0%, no active) → 10 (baseline)
    # - Active → completion % (linear ramp)
}

# Utility: Map status string to percentage
sub status_percent {
    my ($status) = @_;
    # Returns: 0-100 based on status value
}

# Utility: Extract status from workflow file
sub status_extract {
    my ($file_path) = @_;
    # Returns: Status string or 'Unknown'
}
```

**Design Rationale**:
- Discovered during Phase 1: progress serves two distinct purposes
- status-aggregator needs "where are we?" (retrospective)
- task-context-inference needs "where should we work?" (prospective)
- Cliff function: "the closer a task is to complete, the more we want to complete it"
- MSB naming: category-first aids autocomplete and clarity

#### Component 1a: TaskContextInference.pm (Core Library)
**Location**: `.cig/lib/TaskContextInference.pm`

**Purpose**: Core inference logic - all signal collection, scoring, and correlation

**Responsibilities**:
- Collect 5 task signals (branch, worktree, state, recency, progress) - Status signal removed during implementation
- Collect 3 workflow step signals (step status, step recency, workflow sequence)
- Score each signal returning top-5 candidates
- Perform correlation check (all non-null top results agree?)
- Format output (simple vs verbose)
- Pure library: no CLI concerns, no I/O (returns data structures)

**Note**: Status signal was originally planned as 6th task signal but removed during Phase 1 implementation testing. Analysis showed Status to be lower quality (manual, can be stale) while heavily correlating with Progress signal (mechanical calculation). Completed tasks ("Finished" status = 100 pts) dominated current task ("In Progress" = 80 pts), causing false negatives. Status signal retained only for workflow step inference.

**Public API** (exported functions):
```perl
package TaskContextInference;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(
    infer_task_context
    get_all_signals
    correlate_signals
    format_output
);

# Main entry point
# Returns: { task_num => 32, task_slug => '...', workflow_step => '...',
#            confidence => 'correlated|uncorrelated|no_signals',
#            signals => [...] }
sub infer_task_context {
    my %opts = @_;  # verbose => 0|1
    # ... implementation
}

# Signal collection (returns array of signal result hashes)
sub get_all_signals { }

# Correlation check (returns correlation hash)
sub correlate_signals {
    my @signals = @_;
    # Extract top task from each non-null signal
    # Check if all agree
    # Return { correlated => 0|1, top_tasks => [...], chosen => N }
}

# Format output (simple or verbose)
sub format_output {
    my ($context, $verbose) = @_;
    # Returns string ready to print
}
```

**Internal Functions** (not exported):
```perl
# Signal collection - Task signals (5)
sub _get_branch_signal { }      # Parse git branch name
sub _get_worktree_signal { }    # Detect worktree path
sub _get_state_file_signal { }  # Read .cig/current-task
sub _get_recency_signal { }     # Scan task dirs for mtime
sub _get_progress_signal { }    # Calculate completion %
# sub _get_status_signal { }    # REMOVED - Low quality signal, correlates with Progress

# Signal collection - Workflow step signals (3)
sub _get_step_status_signal { } # Check Status: markers (workflow only, not task)
sub _get_step_recency_signal { }# Find newest workflow file
sub _get_step_sequence_signal { }# Predict next after Finished

# Scoring algorithms
sub _score_recency { }          # Exponential decay
sub _score_progress { }         # Linear scoring (cliff function) - UPDATED from bell curve
# sub _score_status { }         # REMOVED - Only needed for workflow step inference
```

**Note**: _score_progress() updated during implementation from bell curve to linear scoring. Progress signal now uses TaskState::state_achievable() which implements cliff function. Linear scoring: higher work potential = higher score (0% → 0 pts, 25% → 15 pts, 75% → 45 pts).

#### Component 1b: task-context-inference (CLI Wrapper)
**Location**: `.cig/scripts/command-helpers/task-context-inference`

**Purpose**: Thin CLI wrapper over library - handle args, print output, exit codes

**Responsibilities**:
- Parse command line arguments (--verbose flag)
- Call library function `infer_task_context()`
- Print formatted output to STDOUT
- Set appropriate exit code
- Handle errors/exceptions from library

**Implementation** (~50-100 lines):
```perl
#!/usr/bin/env perl
use strict;
use warnings;
use lib "$ENV{HOME}/repo/code-implementation-guide/.cig/lib";  # Or use FindBin
use TaskContextInference qw(infer_task_context);

# Parse args
my $verbose = 0;
$verbose = 1 if grep { $_ eq '--verbose' } @ARGV;

# Call library
my $context = infer_task_context(verbose => $verbose);

# Print output
print $context->{output};

# Exit with appropriate code
exit 0 if $context->{confidence} eq 'correlated';
exit 1 if $context->{confidence} eq 'uncorrelated';
exit 3 if $context->{confidence} eq 'no_signals';
exit 2;  # Error
```

**Exit Codes**:
- 0: Success (correlated, inference complete)
- 1: Uncorrelated (signals disagree, user prompt shown)
- 2: Error (malformed data, permissions issue)
- 3: No signals (cannot infer, no data available)

#### Component 2: /current-task-wf (Simple Skill)
**Location**: `.claude/skills/current-task-wf.md`

**Purpose**: Provide simple inference output to LLM context

**Implementation**:
```markdown
---
description: Infer current task and workflow step (simple output)
---

Current task and workflow step (inferred from environmental signals):

!`.cig/scripts/command-helpers/task-context-inference 2>/dev/null || echo "Unable to infer context"`
```

**Output Format** (injected into LLM context):
```
task_num: 32
task_slug: feature-task-tracking-using-inference-scoring
workflow_step: c-design-plan
```

**Performance**: <200ms (script execution + formatting)

#### Component 3: /current-task-wf-verbose (Debugging Skill)
**Location**: `.claude/skills/current-task-wf-verbose.md`

**Purpose**: Provide full signal breakdown for debugging

**Implementation**:
```markdown
---
description: Infer current task with verbose signal breakdown
---

Current task inference (verbose debugging mode):

!`.cig/scripts/command-helpers/task-context-inference --verbose 2>/dev/null || echo "Unable to infer context"`
```

**Output Format** (injected into LLM context):
```
task_num: 32
task_slug: feature-task-tracking-using-inference-scoring
workflow_step: c-design-plan

Signal Breakdown:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Task Signals (all correlated):
  branch:100     ✓ feature/32-task-tracking-using-inference-scoring
  recency:90     ✓ modified 2 minutes ago (top of 5)
  progress:58    ✓ 45% complete (top of 5)
  ...

Correlation: ALL SIGNALS AGREE
```

#### Component 4: Workflow Command Updates (10 commands)
**Locations**: `.claude/commands/cig-*.md`

**Purpose**: Support argument-optional invocation via skill reference

**Commands to Update**:
1. cig-task-plan.md
2. cig-requirements-plan.md
3. cig-design-plan.md
4. cig-implementation-plan.md
5. cig-testing-plan.md
6. cig-implementation-exec.md
7. cig-testing-exec.md
8. cig-rollout.md
9. cig-maintenance.md
10. cig-retrospective.md

**Implementation Pattern** (per command):
```markdown
## Context
- Current task/workflow (if available): !/current-task-wf

## Your task
Guide user through [phase] for task [number].

**CRITICAL - Argument Parsing**:
- Extract task path from arguments
- If no argument AND /current-task-wf succeeded: use task_num from skill output
- If no argument AND skill failed: error with helpful message
- If explicit argument: use it (explicit wins over inference)

**Steps**:
1. **Get Task Path**:
   - Check if argument provided
   - If no arg: read task_num from /current-task-wf skill output above
   - If neither: error "Please specify task number or ensure context is inferrable"
```

**Change Per Command**: ~15 lines (add context reference, update argument handling logic)

### Data Flow

**Scenario 1: User invokes command with explicit task**
```
User: /cig-design-plan 32
  ↓
Command receives arg "32"
  ↓
Use explicit argument (inference skipped)
  ↓
Proceed with task 32 workflow
```

**Scenario 2: User invokes command without argument (inference succeeds)**
```
User: /cig-design-plan
  ↓
Command has no arg
  ↓
Check /current-task-wf skill in context
  ↓
Skill executed: task-context-inference runs
  ↓
Library collects signals: branch=32, recency=32, progress=32 (correlated)
  ↓
Library outputs: task_num:32, task_slug:..., workflow_step:c-design-plan
  ↓
Skill injects output into LLM context
  ↓
Command reads task_num from skill output
  ↓
Proceed with task 32 workflow
```

**Scenario 3: User invokes command without argument (inference fails - uncorrelated)**
```
User: /cig-design-plan
  ↓
Command has no arg
  ↓
Check /current-task-wf skill in context
  ↓
Skill executed: task-context-inference runs
  ↓
Library collects signals: branch=32, recency=31 (uncorrelated!)
  ↓
Library prompts user: "Signals disagree. Choose: 32 (branch) or 31 (recency)?"
  ↓
Skill shows prompt to LLM
  ↓
LLM asks user to clarify or provide explicit task number
```

**Scenario 4: Verbose debugging**
```
User: /current-task-wf-verbose
  ↓
Skill executed with --verbose flag
  ↓
Library runs full signal collection
  ↓
Library outputs detailed breakdown (all signals, scores, correlation analysis)
  ↓
LLM receives verbose output in context
  ↓
User can see exactly why task X was chosen (or why signals disagree)
```

## Interface Design

### Script Interface: task-context-inference

**Command Line Interface**:
```bash
# Default mode (simple output)
$ .cig/scripts/command-helpers/task-context-inference
task_num: 32
task_slug: feature-task-tracking-using-inference-scoring
workflow_step: c-design-plan

# Verbose mode (debugging)
$ .cig/scripts/command-helpers/task-context-inference --verbose
[Simple output PLUS full signal breakdown]

# Exit codes
$ echo $?
0  # Success (correlated)
1  # Uncorrelated (user prompt shown)
2  # Error (file permissions, malformed data)
3  # No signals (cannot infer)
```

**Environment Dependencies**:
- CWD must be git repository root
- Assumes implementation-guide/ directory exists
- Reads .cig/current-task if present (optional)
- Requires git command available in PATH

**Performance Contract**:
- Must complete in <500ms
- No full repository scans (only implementation-guide/)
- Minimal disk I/O (targeted file reads)

### Data Models

**Signal Result Structure** (Perl hash):
```perl
# Top-5 candidates with scores
my %signal_result = (
    name => 'recency',          # Signal identifier
    weight => 90,               # Max weight for this signal
    candidates => [
        { task => 32, score => 90 },
        { task => 31, score => 85 },
        { task => 30, score => 70 },
        { task => 29, score => 50 },
        { task => 28, score => 30 },
    ],
    top => 32,                  # Top candidate (for correlation)
    null => 0,                  # 1 if signal unavailable
);
```

**Task Context Structure** (output):
```perl
my %task_context = (
    task_num => 32,
    task_slug => 'feature-task-tracking-using-inference-scoring',
    workflow_step => 'c-design-plan',
    confidence => 'correlated',  # or 'uncorrelated' or 'no_signals'
);
```

**Correlation State**:
```perl
my %correlation = (
    signals_checked => ['branch', 'worktree', 'recency', 'progress'],  # 5 signals (status removed)
    null_signals => ['state'],  # State file doesn't exist
    top_tasks => [32, 32, 32, 32],  # All agree
    correlated => 1,            # Boolean: all non-null agree?
    chosen_task => 32,          # Final decision
);
```

### Skill Interface

**Skill: /current-task-wf**
- **Input**: None (skill invoked by LLM or command context)
- **Output**: 3 lines in LLM context (task_num, task_slug, workflow_step)
- **Error Handling**: Fallback message "Unable to infer context" on failure
- **Caching**: None (executes fresh each invocation)

**Skill: /current-task-wf-verbose**
- **Input**: None
- **Output**: 3 lines + full signal breakdown (30-50 lines)
- **Use Case**: Debugging, troubleshooting inference errors
- **Performance**: <500ms (includes all signal collection + formatting)

### Command Integration Interface

**Pattern for Command Updates**:
```markdown
## Context
- Current task/workflow (if available): !/current-task-wf

## Your task
...

1. **Get Task Path**:
   ```
   TASK_PATH=""
   if [ -n "$ARGUMENTS" ]; then
       # Explicit argument provided
       TASK_PATH=$(echo "$ARGUMENTS" | awk '{print $1}')
   else
       # Try inference via skill
       TASK_PATH=$(grep "^task_num:" <<< "$SKILL_OUTPUT" | cut -d: -f2 | tr -d ' ')
       if [ -z "$TASK_PATH" ]; then
           echo "Error: Cannot determine task. Specify task number or ensure context is inferrable."
           exit 1
       fi
   fi
   ```
```

**Mechanical Change Per Command**:
1. Add context line: `- Current task/workflow (if available): !/current-task-wf`
2. Update step 1 logic to check skill output if no argument
3. No changes to remaining workflow logic (task path is same either way)

**Validation**:
- If inference disagrees with explicit arg → warn user but use explicit
- If inference succeeds but validation fails → show validation error
- If no arg and no inference → clear error message

## Constraints

### Technical Constraints (from Requirements)

**C1: Perl-based Implementation**
- Design Impact: Use Perl 5.x features, File::Find module, git system calls
- Benefit: Consistency with existing helpers (easier maintenance)
- Limitation: Not as ergonomic as Python/Ruby for complex data structures

**C2: Stateless Execution**
- Design Impact: No persistent daemon, no cache between invocations
- Benefit: Simple debugging, no state corruption issues
- Limitation: Cannot optimize via warm cache (mitigated: <500ms is still fast)

**C3: Git Worktree Compatibility**
- Design Impact: No shared state files (each worktree independent)
- Benefit: Parallel development on multiple tasks
- Limitation: Cannot use .cig/current-task reliably (but branch/worktree signals work)

**C4: Fixed Output Format**
- Design Impact: `task_num: X\ntask_slug: Y\nworkflow_step: Z\n` (3 lines, parseable)
- Benefit: Stable contract for skills and commands
- Limitation: Cannot change format without breaking consumers

### Performance Constraints

**P1: <500ms Total Execution Time**
- Design Strategy:
  - Collect fast signals first (branch, worktree, state) → O(1)
  - Scan only implementation-guide/ directory → O(n tasks)
  - Skip full repo scans (no git log --all, no recursive find /)
  - Use -mtime optimization for recency (file metadata, not content)

**P2: Minimal Disk I/O**
- Design Strategy:
  - Read workflow files selectively (only Status: lines, not full files)
  - Cache directory listings in memory during single invocation
  - Use git commands sparingly (branch name, worktree list)

### Security Constraints

**S1: Input Validation**
- Design: Sanitize branch names (strip special chars before regex match)
- Design: Validate task paths (digits and dots only)
- Design: Validate state file content (reject non-numeric values)

**S2: Minimal Privileges**
- Design: Read-only operations (no writes, no git commits)
- Design: No network access
- Design: Runs as user (no sudo, no privilege escalation)

**S3: Hash Verification**
- Design: Add script to `.cig/security/script-hashes.json`
- Design: Generate SHA256 hash for integrity checking via /cig-security-check

### Design Constraints (from Requirements)

**D1: Correlation = All Agree (not thresholds)**
- Design Impact: Simple boolean check, no weighted averaging
- Benefit: Easy to understand, conservative (ask user when uncertain)
- Trade-off: May prompt user more often than threshold approach

**D2: Top-N Scoring (not winner-takes-all)**
- Design Impact: Each signal returns array of 5 candidates
- Benefit: Richer data for correlation check
- Trade-off: More computation per signal

**D3: Library-Based Architecture (single source of truth)**
- Design Impact: Skills and commands are thin wrappers
- Benefit: Testability, maintainability
- Trade-off: Extra layer (skills), but minimal overhead

## Critical Design Decisions

### Decision 1: Why Perl Instead of Bash?
- **Choice**: Perl 5.x for task-context-inference script
- **Alternatives Considered**:
  - Bash: Simpler for command execution, but poor data structures (no hashes/arrays)
  - Python: Better data structures, but breaks consistency with existing helpers
- **Rationale**: Perl strikes balance - existing helper scripts use it, has proper data structures (hashes for signal results), mature git/file handling
- **Trade-off**: Less ergonomic than Python, but maintains consistency

### Decision 2: Skills vs Direct Script Calls in Commands?
- **Choice**: Commands reference skills (!/current-task-wf), not direct script calls
- **Alternatives Considered**:
  - Direct: Commands call task-context-inference directly via Bash tool
  - Skills: Commands reference skill output in context
- **Rationale**: Skills-first aligns with stated migration strategy, enables future caching/optimization at skill layer, cleaner separation (commands don't execute, just consume)
- **Trade-off**: Extra indirection, but future-proof and cleaner

### Decision 3: Correlation Check vs Threshold Scoring?
- **Choice**: Correlation check (all non-null signals agree on top task)
- **Alternatives Considered**:
  - Threshold: Sum scores, require >400 points for confidence
  - Weighted average: Average scores with weights, pick highest
  - Voting: Each signal votes, majority wins
- **Rationale**: Correlation is conservative (when uncertain, ask user), simple to understand, avoids false positives
- **Trade-off**: May prompt user more often, but safer (no silent wrong guesses)

### Decision 4: Why Top-5 Instead of Top-1?
- **Choice**: Each signal returns top 5 candidates with scores
- **Alternatives Considered**:
  - Top-1: Each signal returns single best guess
  - Top-N configurable: Let user choose N
- **Rationale**: Top-5 provides richer data for correlation without overwhelming (20+ tasks → 5 is manageable), enables fallback prompts (show top candidates when uncorrelated)
- **Trade-off**: More computation, but not significant (<500ms still achievable)

### Decision 5: Script Architecture (Library + Thin Wrapper)
- **Choice**: Separate library module + thin CLI wrapper script
  - Library: `.cig/lib/TaskContextInference.pm` (all logic, 500-700 lines)
  - Script: `.cig/scripts/command-helpers/task-context-inference` (CLI wrapper, 50-100 lines)
- **Alternatives Considered**:
  - Monolithic: Single script with all logic inline (harder to test)
  - Object-oriented: Signal classes with inheritance (over-engineered for this use case)
- **Rationale**:
  - Library is independently testable (`use TaskContextInference; test_signals();`)
  - Script is just plumbing (arg parsing, call library, print output, exit codes)
  - Clean separation: business logic vs CLI interface
  - Library functions could be reused by other scripts if needed
- **Trade-off**: Requires PERL5LIB setup (mitigated: use `use lib` in script to find .cig/lib/)

## Validation
- [ ] Design review completed with user (library-based approach approved)
- [ ] Architecture aligns with requirements (FR1-FR5, NFR1-NFR5)
- [ ] Integration points verified (skills, commands, exit codes)
- [ ] Performance estimates validated (<500ms achievable)
- [ ] Security considerations addressed (input validation, hash verification)

## Testing Strategy (Overview)

**Library Testing Benefits**:
- Library functions are pure: input data structures → output data structures
- No I/O mocking needed: pass test data directly to functions
- Can test signals independently: `my $result = _get_branch_signal('feature/32-foo');`
- Can test scoring algorithms: `my $score = _score_recency(300); # 5 minutes ago`
- Fast tests: no subprocess execution, no file I/O

**Unit Testing** (library functions):
- Branch parsing: Test with various branch formats (feature/32-slug, chore/31-slug, main)
- Worktree detection: Test with worktree paths, non-worktree
- Recency scoring: Test exponential decay formula with mocked timestamps
- Progress scoring: Test bell curve (0%, 25%, 50%, 75%, 100%)
- Status scoring: Test linear mapping (Backlog→0, In Progress→80, Finished→100)
- Each test: `use TaskContextInference; my $result = _function(test_data); assert($result);`

**Integration Testing** (correlation):
- All agree → verify returns correct task
- Disagree → verify prompts user with candidates
- No signals → verify error message
- Null signals excluded → verify correlation works with subset

**Performance Testing**:
- Time script execution across 1, 10, 20, 30 tasks
- Verify <500ms on standard hardware
- Profile slow operations (file scans, git commands)

**Command Integration Testing**:
- Test each command with explicit arg (should work as before)
- Test each command without arg (should use inference)
- Test with uncorrelated signals (should prompt user)

## Critical Files to Create

**New Files**:
1. `.cig/lib/TaskContextInference.pm` - Core library (500-700 lines)
2. `.cig/scripts/command-helpers/task-context-inference` - CLI wrapper (50-100 lines)
3. `.claude/skills/current-task-wf.md` - Simple skill (~10 lines)
4. `.claude/skills/current-task-wf-verbose.md` - Verbose skill (~10 lines)

**Files to Modify** (10 commands, ~15 lines each):
5. `.claude/commands/cig-task-plan.md`
6. `.claude/commands/cig-requirements-plan.md`
7. `.claude/commands/cig-design-plan.md`
8. `.claude/commands/cig-implementation-plan.md`
9. `.claude/commands/cig-testing-plan.md`
10. `.claude/commands/cig-implementation-exec.md`
11. `.claude/commands/cig-testing-exec.md`
12. `.claude/commands/cig-rollout.md`
13. `.claude/commands/cig-maintenance.md`
14. `.claude/commands/cig-retrospective.md`

**Security Updates**:
15. `.cig/security/script-hashes.json` - Add hash for task-context-inference wrapper

**Total**: 4 new files + 10 modified commands + 1 security update

## Status
**Status**: Finished
**Next Action**: Proceed to implementation planning (/cig-implementation-plan 32)
**Blockers**: None identified

**Note**: This design builds on comprehensive requirements (FR1-FR5, NFR1-NFR5) and existing design document at `.cig/docs/context/state-tracking.md`. Implementation planning should focus on step-by-step coding sequence: (1) library with unit tests, (2) wrapper script, (3) skills, (4) command updates.

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
