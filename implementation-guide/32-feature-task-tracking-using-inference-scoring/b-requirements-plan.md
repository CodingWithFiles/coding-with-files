# task-tracking-using-inference-scoring - Requirements

## Task Reference
- **Task ID**: internal-32
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/32-task-tracking-using-inference-scoring
- **Template Version**: 2.1

## Goal
Define functional and non-functional specifications for a signal-based inference system that automatically determines current task and workflow step by correlating multiple environmental signals.

## Functional Requirements

### FR1: Signal Collection and Scoring
The task-context-inference helper script MUST collect and score signals from 5 sources (updated from 6 during implementation):

**Task Inference Signals:**
- **FR1.1**: Git branch name parsing (weight: 100) - extract task number from `<type>/<num>-<slug>` format
  - AC: Returns task 31 when branch is `chore/31-update-backlog-and-changelog`
  - AC: Returns null when on main/master branch
- **FR1.2**: Worktree context detection (weight: 95) - detect task from worktree directory path
  - AC: Returns task 31 when worktree path contains `/cig-task-31/` or similar pattern
  - AC: Returns null when not in worktree
- **FR1.3**: State file reading (weight: 85) - read `.cig/current-task` if exists
  - AC: Returns task number from file if present and valid
  - AC: Returns null if file doesn't exist or is malformed
- **FR1.4**: File recency scoring (weight: 0-90) - exponential decay based on modification time
  - AC: Returns top 5 tasks ranked by most recently modified workflow files
  - AC: Score = 90 at 5 min ago, decays exponentially over time
- **FR1.5**: ~~Workflow status scoring~~ - **REMOVED DURING IMPLEMENTATION**
  - **Rationale**: Implementation testing revealed this signal to be lower quality (manual, can be stale) while heavily correlating with Progress signal (mechanical calculation). Completed tasks ("Finished" status = 100 points) dominated current task ("In Progress" = 80 points), causing false negatives. Status signal is retained only for workflow step inference, not task inference.
- **FR1.6**: Task progress scoring (weight: 0-60) - **UPDATED TO CLIFF FUNCTION DURING IMPLEMENTATION**
  - Original design: Bell curve with peak at 50% complete
  - Implemented design: Linear cliff function ("the closer a task is to complete, the more we want to complete it")
  - AC: Returns top 5 tasks ranked by work potential (state_achievable)
  - AC: Score increases linearly with completion (0% = 0 pts, 25% = 15 pts, 75% = 45 pts)
  - AC: Cliff at 100% complete = 0 points (no work left)
  - AC: Blocked tasks score 0 (no work possible)
  - Rationale: Progress signal should measure "work potential" (prospective) not "completion" (retrospective). Uses TaskState::state_achievable() instead of binary "Finished" count.

**Workflow Step Inference Signals:**
- **FR1.7**: Step status detection (weight: 100) - identify "In Progress" workflow file
  - AC: Returns workflow step with "Status: In Progress" marker
  - AC: Returns null if no step is "In Progress"
- **FR1.8**: Step recency (weight: 0-90) - most recently modified workflow file
  - AC: Returns workflow step based on newest file modification time
- **FR1.9**: Workflow sequence (weight: 70) - predict next step after last "Finished"
  - AC: Returns next step in sequence after last "Status: Finished" step
  - AC: Respects task type workflow order (feature: a→b→c→d→e→f→g→h→i→j)

### FR2: Top-N Scoring Per Signal
Each signal MUST return its top 5 candidates with scores (not winner-takes-all):

- **FR2.1**: Each signal returns array of up to 5 task candidates with scores
  - AC: Recency signal returns `[(31,90), (32,85), (30,70), (29,50), (28,30)]`
  - AC: Progress signal returns `[(31,60), (32,58), (30,55), (29,45), (28,10)]`
- **FR2.2**: Scores MUST be proportional/linear as specified in design
  - AC: Recency uses exponential decay formula
  - AC: Progress uses bell curve formula
  - AC: Status uses linear mapping

### FR3: Correlation Logic
System MUST implement correlation check to determine confidence:

- **FR3.1**: Extract top task number from each non-null signal
  - AC: Collects top result from branch, worktree, state, recency, progress (5 signals)
  - AC: Skips null signals (e.g., no branch on main, no state file)
- **FR3.2**: Check if all non-null top results agree on same task number
  - AC: If all point to task 31 → correlated, return task 31
  - AC: If branch=31, recency=32, state=31 → uncorrelated (disagreement)
- **FR3.3**: When correlated, return task_num, task_slug, workflow_step
  - AC: Output format: `task_num: 31\ntask_slug: chore-update-backlog\nworkflow_step: d-implementation-plan\n`
- **FR3.4**: When uncorrelated, prompt user with top candidates
  - AC: Show top 3-5 candidates with signal breakdown
  - AC: Ask user to choose or clarify context
- **FR3.5**: When all signals null, return error
  - AC: Output: "Error: Cannot infer current task (no signals detected)"

### FR4: Skills for LLM Access
Two skills MUST be created for LLM consumption of inference results:

- **FR4.1**: /current-task-wf skill - simple output
  - AC: Calls `task-context-inference` (default mode)
  - AC: Returns 3-line output in context: task_num, task_slug, workflow_step
  - AC: Fast execution (<200ms including script execution)
- **FR4.2**: /current-task-wf-verbose skill - debugging output
  - AC: Calls `task-context-inference --verbose`
  - AC: Returns full signal breakdown with all scores
  - AC: Shows correlation analysis and decision reasoning

### FR5: Workflow Command Integration
All 8 workflow commands MUST support argument-optional invocation:

- **FR5.1**: Commands check for explicit task argument first
  - AC: `/cig-task-plan 32` uses task 32 (explicit wins)
  - AC: `/cig-task-plan` falls back to inference
- **FR5.2**: When no argument, commands reference /current-task-wf skill output
  - AC: LLM reads task_num from skill context
  - AC: Command proceeds with inferred task number
- **FR5.3**: Commands affected: cig-task-plan, cig-requirements-plan, cig-design-plan, cig-implementation-plan, cig-testing-plan, cig-implementation-exec, cig-testing-exec, cig-rollout, cig-maintenance, cig-retrospective
  - AC: All 10 workflow commands work without arguments when context is clear

### FR6: Shared State Library
A shared TaskState library MUST provide both retrospective and prospective state calculations:

- **FR6.1**: Library provides state measurement functions with MSB naming
  - AC: `TaskState::state_done()` returns 0-100% completion (retrospective - MIN bottleneck formula)
  - AC: `TaskState::state_achievable()` returns 0-100% work potential (prospective - cliff function)
  - AC: `TaskState::status_percent()` maps status strings to percentages
  - AC: `TaskState::status_extract()` extracts status from workflow files
- **FR6.2**: status-aggregator uses state_done() for completion reporting
  - AC: status-aggregator-v2.0 and v2.1 refactored to use shared library
  - AC: Behavior unchanged (still reports MIN bottleneck)
  - AC: Eliminates ~200 lines of duplicate code
- **FR6.3**: task-context-inference uses state_achievable() for work potential
  - AC: TaskContextInference::_calculate_task_progress() calls TaskState::state_achievable()
  - AC: Cliff function correctly identifies blocked (0%) vs active (completion%) tasks
  - AC: Linear scoring replaces bell curve (higher completion = higher score)
- **FR6.4**: Naming follows MSB (Most Significant Byte) convention
  - AC: Functions prefixed by category: `state_*` for measurements, `status_*` for utilities
  - AC: Noun forms (present perfect gerund): "state done", "state achievable"
  - Rationale: Library functions are measurements (nouns), orchestration scripts communicate intent (verbs)

### User Stories
- **As a** CIG user **I want** workflow commands to infer my current task automatically **so that** I don't have to repeatedly type task numbers
- **As a** developer using git worktrees **I want** task inference to work per-worktree **so that** I can work on multiple tasks in parallel
- **As a** user troubleshooting inference **I want** verbose mode to show all signal scores **so that** I can understand why a specific task was chosen
- **As a** user with multiple in-progress tasks **I want** to be prompted when signals disagree **so that** I don't accidentally work on the wrong task

## Non-Functional Requirements

### Performance (NFR1)
- **NFR1.1**: Signal collection MUST complete in <500ms total
  - AC: Time all 6 task signals + 3 workflow signals
  - AC: Total execution time <500ms on standard development machine
  - Rationale: Commands should feel instant, not sluggish
- **NFR1.2**: Script execution MUST NOT scan entire repository
  - AC: Only read task directories (implementation-guide/*), not entire codebase
  - AC: Use targeted file reads, not recursive find operations
- **NFR1.3**: Caching strategy SHOULD be considered for repeated invocations
  - AC: Document cache invalidation strategy if implemented
  - Note: Nice-to-have, not blocking

### Usability (NFR2)
- **NFR2.1**: Default output MUST be minimal and parseable
  - AC: 3 lines: task_num, task_slug, workflow_step
  - AC: No extra formatting, no explanations, just data
- **NFR2.2**: Verbose output MUST be human-readable with clear visual hierarchy
  - AC: Uses box-drawing characters, clear sections, aligned columns
  - AC: Follows design document format example
- **NFR2.3**: Error messages MUST be actionable
  - AC: "Cannot infer current task (no signals detected)" tells user what's wrong
  - AC: Uncorrelated prompt shows top candidates and asks user to choose
- **NFR2.4**: Users SHOULD NOT need to understand inference internals for normal use
  - AC: Default mode just works, verbose mode is opt-in for debugging

### Maintainability (NFR3)
- **NFR3.1**: All inference logic MUST be in task-context-inference script (single source of truth)
  - AC: Skills are <10 line wrappers that call script
  - AC: Commands are <15 line updates that reference skill output
  - AC: No duplication of scoring/correlation logic
- **NFR3.2**: Each signal MUST be independently testable
  - AC: Can test branch parsing without running other signals
  - AC: Can test recency scoring with mocked file timestamps
- **NFR3.3**: Signal weights MUST be configurable constants at top of script
  - AC: WEIGHT_BRANCH=100, WEIGHT_WORKTREE=95, etc. defined in config section
  - AC: Easy to adjust weights without hunting through code
- **NFR3.4**: Script MUST follow existing helper script conventions
  - AC: Perl implementation (matches hierarchy-resolver, status-aggregator)
  - AC: Exit codes: 0=success, 1=uncorrelated, 2=error, 3=no signals
  - AC: Uses strict/warnings pragmas

### Security (NFR4)
- **NFR4.1**: Script MUST validate all external inputs
  - AC: Branch names sanitized (no command injection via malicious branch names)
  - AC: File paths validated (no directory traversal)
  - AC: State file content validated (only accept valid task numbers)
- **NFR4.2**: Script MUST run with minimal privileges
  - AC: No write operations (read-only git/filesystem access)
  - AC: No network access required
- **NFR4.3**: Script MUST be included in security hash verification
  - AC: Add task-context-inference to `.cig/security/script-hashes.json`
  - AC: Generate SHA256 hash for integrity checking

### Reliability (NFR5)
- **NFR5.1**: System MUST gracefully handle missing/stale signals
  - AC: Missing branch (on main) → null, not error
  - AC: Stale timestamps (>24h old) → low scores, not excluded
  - AC: Malformed state file → null signal, warning to stderr
- **NFR5.2**: System MUST work with git worktrees without shared state
  - AC: Each worktree infers independently (no shared .cig/current-task)
  - AC: Worktree path signal provides isolation
- **NFR5.3**: System MUST handle edge cases conservatively
  - AC: When uncertain (uncorrelated) → ask user, don't guess
  - AC: When no signals → clear error, don't fabricate answer
- **NFR5.4**: Inference accuracy MUST be ≥95% when signals are present
  - AC: Test with 20 realistic scenarios (various task states)
  - AC: ≥19/20 correct inferences when signals are correlated

## Constraints

### Technical Constraints
- **C1**: Must integrate with existing Perl-based helper script architecture
  - Cannot introduce new language/runtime (no Python, no Node.js)
  - Must follow existing patterns (strict/warnings, exit codes, stderr for warnings)
- **C2**: Must be stateless (no persistent daemon processes)
  - Each invocation is independent, no memory between calls
  - Enables simple debugging and testing
- **C3**: Must handle git worktree scenarios
  - Cannot rely on shared state files that conflict across worktrees
  - Each worktree context is isolated
- **C4**: Output format is fixed and cannot be changed
  - `task_num: X\ntask_slug: Y\nworkflow_step: Z\n` (3 lines exactly)
  - Parseable by both LLM context and shell scripts

### Design Constraints
- **C5**: Correlation logic is defined: all non-null top signals must agree
  - Cannot use threshold-based confidence scores
  - Cannot use weighted averaging or voting
  - Simple boolean: all agree → return, else → ask user
- **C6**: Top-N scoring mandated: each signal returns top 5 candidates
  - Cannot be winner-takes-all (single result per signal)
  - Enables better correlation checking across signals
- **C7**: Signal weights are specified in design document
  - Branch: 100, Worktree: 95, State: 85, Recency: 0-90, Status: 0-80, Progress: 0-60
  - Cannot arbitrarily change without updating design doc

### Scope Constraints
- **C8**: Does NOT implement optional state file management
  - This task only reads `.cig/current-task` if exists
  - Does not create, update, or manage state file lifecycle
  - State file management is separate BACKLOG item
- **C9**: Focus is correlation accuracy, not UI polish
  - Verbose output is debugging tool, not primary interface
  - No fancy formatting beyond box-drawing characters
- **C10**: Library-based architecture is mandatory
  - Skills are thin wrappers (no inline logic)
  - Commands reference skill output (no direct script calls from LLM prompts)
  - Single source of truth in task-context-inference script

## Acceptance Criteria

### Library Implementation (task-context-inference)
- [ ] AC1: All 5 task signals implemented and returning top-5 candidates with scores (Status signal removed during implementation)
- [ ] AC2: All 3 workflow step signals implemented and returning results
- [ ] AC3: Correlation logic correctly identifies correlated vs uncorrelated signals
- [ ] AC4: Default mode outputs exactly 3 lines: task_num, task_slug, workflow_step
- [ ] AC5: --verbose flag outputs full signal breakdown with scores and correlation analysis
- [ ] AC6: Script completes in <500ms for typical repository with 20-30 tasks
- [ ] AC7: Script handles edge cases gracefully (no branch, no state file, stale signals)
- [ ] AC8: Exit codes: 0=success, 1=uncorrelated, 2=error, 3=no signals

### Skills Implementation
- [ ] AC9: /current-task-wf skill calls task-context-inference and returns simple output
- [ ] AC10: /current-task-wf-verbose skill calls task-context-inference --verbose
- [ ] AC11: Both skills execute successfully and provide output to LLM context

### Command Integration
- [ ] AC12: All 10 workflow commands (cig-task-plan, cig-requirements-plan, cig-design-plan, cig-implementation-plan, cig-testing-plan, cig-implementation-exec, cig-testing-exec, cig-rollout, cig-maintenance, cig-retrospective) work without task arguments
- [ ] AC13: Commands prioritize explicit arguments over inference (explicit wins)
- [ ] AC14: Commands reference /current-task-wf skill output when no argument provided
- [ ] AC15: No inline logic duplication (commands are mechanical updates)

### Testing and Validation
- [ ] AC16: Unit tests for each signal (branch, worktree, state, recency, progress) - Status signal removed
- [ ] AC17: Integration test with 20 realistic scenarios achieving ≥95% accuracy
- [ ] AC18: Edge case tests (main branch, no state file, multiple in-progress tasks, worktrees)
- [ ] AC19: Performance test confirming <500ms execution time

### Documentation
- [ ] AC20: Usage examples documented (default mode, verbose mode, troubleshooting)
- [ ] AC21: Signal weights and scoring formulas documented
- [ ] AC22: Correlation logic clearly explained with examples
- [ ] AC23: Script added to security hash verification system

## Status
**Status**: Finished
**Next Action**: Proceed to design phase (/cig-design-plan 32)
**Blockers**: None identified

**Note**: Design document at `.cig/docs/context/state-tracking.md` already exists and is comprehensive. Design phase should reference this document and focus on implementation architecture (script structure, function signatures, data structures).

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
