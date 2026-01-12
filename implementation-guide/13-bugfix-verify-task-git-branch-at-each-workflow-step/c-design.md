# verify task git branch at each workflow step - Design

## Task Reference
- **Task ID**: internal-13
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/13-verify-task-git-branch-at-each-workflow-step
- **Template Version**: 2.0

## Goal
Design a lightweight, non-intrusive branch verification system that checks git branch status at the start of each workflow command and provides clear guidance when branch mismatch occurs.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions

### Architecture Choice
- **Decision**: Inject branch verification as new "Step 1.5" between task resolution and parent context loading
- **Rationale**:
  - Occurs after we know the task directory (Step 1) so we can read Task Reference
  - Occurs before substantive workflow operations (Step 2+) so user gets early feedback
  - Maintains existing step numbering structure (insert between existing steps)
  - Consistent injection point across all 8 workflow commands
- **Trade-offs**:
  - **Benefit**: Early detection prevents wasted effort on wrong branch
  - **Benefit**: Minimal code duplication (same pattern in 8 files)
  - **Drawback**: Adds ~100-200ms overhead per workflow command invocation
  - **Drawback**: Requires all task files to have Branch field in Task Reference

### Implementation Approach
- **Decision**: Use inline bash commands within allowed-tools constraints
- **Rationale**:
  - Allowed-tools already permits `Bash(egrep:*)` and `Bash(echo:*)`
  - Git commands can be added to allowed-tools: `Bash(git:*)`
  - No new helper scripts needed, keeping system simple
  - Easy to test and debug inline
- **Trade-offs**:
  - **Benefit**: No new dependencies, works within existing security model
  - **Benefit**: Easier to understand (inline vs external script)
  - **Drawback**: Duplicated code across 8 files (but it's simple code)

### Error Handling Strategy
- **Decision**: Non-blocking warnings initially, with option for strict mode later
- **Rationale**:
  - Prevents breaking existing workflows during rollout
  - Users can continue working if they understand the risk
  - Future enhancement can make it blocking via config flag
- **Trade-offs**:
  - **Benefit**: Safe, gradual rollout without disruption
  - **Benefit**: Users can override for edge cases (detached HEAD, etc.)
  - **Drawback**: Users might ignore warnings

## System Design

### Component Overview
1. **Branch Extractor**: Reads Branch field from task's a-plan.md Task Reference section
2. **Git Branch Checker**: Calls `git rev-parse --abbrev-ref HEAD` to get current branch
3. **Branch Comparator**: Compares expected vs actual branch
4. **Warning Display**: Shows clear message with suggested `git checkout` command if mismatch

### Data Flow
1. Workflow command invoked with task path (e.g., `/cig-plan 13`)
2. **Step 1**: Task directory resolved via hierarchy-resolver.pl → get task_dir
3. **Step 1.5 - NEW BRANCH VERIFICATION**:
   a. Extract expected branch from `${task_dir}/a-plan.md` Task Reference section
   b. Get current branch via `git rev-parse --abbrev-ref HEAD 2>/dev/null`
   c. Compare branches (case-sensitive)
   d. If mismatch or git error:
      - Display warning with expected branch name
      - Show suggested checkout command
      - Continue execution (non-blocking)
4. **Step 2+**: Existing workflow steps continue normally

### Branch Extraction Logic
Extract branch from Task Reference section using egrep:
```bash
expected_branch=$(egrep '^\- \*\*Branch\*\*:' "${task_dir}/a-plan.md" | sed 's/^- \*\*Branch\*\*: //' | tr -d '`')
```

Pattern matches:
- `- **Branch**: bugfix/13-verify-task-git-branch-at-each-workflow-step`
- `- **Branch**: \`bugfix/13-verify-task-git-branch-at-each-workflow-step\``

### Current Branch Detection
```bash
current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
git_exit_code=$?
```

Handles:
- Normal branches: Returns branch name
- Not a git repo: Returns empty, exit code 128
- Detached HEAD: Returns "HEAD"
- Git not installed: Returns empty, exit code 127

## Interface Design

### Workflow Command Integration
Add new step to all 8 workflow commands after Step 1 (Resolve Task Directory):

```markdown
### Step 1.5: Verify Git Branch (NEW)
Check if user is on the correct git branch for this task:
- Extract expected branch from task's a-plan.md Task Reference
- Get current branch via `git rev-parse --abbrev-ref HEAD`
- If branches don't match, display warning:
  ```
  ⚠️  Branch Mismatch Warning
  Expected: bugfix/13-verify-task-git-branch-at-each-workflow-step
  Current:  main

  Suggested: git checkout bugfix/13-verify-task-git-branch-at-each-workflow-step

  Continuing with workflow on current branch...
  ```
- Continue execution (non-blocking warning)
```

### Files to Modify
All 8 workflow command files in `.claude/commands/`:
1. `cig-plan.md`
2. `cig-requirements.md`
3. `cig-design.md`
4. `cig-implementation.md`
5. `cig-testing.md`
6. `cig-rollout.md`
7. `cig-maintenance.md`
8. `cig-retrospective.md`

Each file needs:
- Add `Bash(git:*)` to allowed-tools
- Insert Step 1.5 after Step 1 (Resolve Task Directory)
- Renumber subsequent steps (Step 2 → Step 2, etc. - no change needed as they're already numbered correctly)

## Constraints

### Technical Constraints
1. **Allowed-tools restrictions**: Must add `Bash(git:*)` to allowed-tools for each command
2. **No external helper script**: Keep logic inline to minimize complexity
3. **Performance**: Branch check must complete in <100ms to avoid workflow slowdown
4. **Git availability**: Must gracefully handle cases where git is not available
5. **File format dependency**: Relies on Task Reference section format in a-plan.md

### Design Constraints
1. **Non-breaking**: Must not break existing workflows or tasks
2. **Backward compatible**: Tasks without Branch field should skip verification
3. **Consistent messaging**: Same warning format across all 8 commands
4. **Simple bypass**: Users can continue despite warnings (future: add strict mode)

### Security Constraints
1. **No command injection**: Branch names are read from files, not user input
2. **Safe git commands**: Use `git rev-parse --abbrev-ref HEAD` (read-only operation)
3. **Error handling**: Fail gracefully if git commands error

## Recommended Implementation Workflow

To minimize risk and ensure proper checkpointing, workflow commands should guide users through this sequence:

### Implementation and Testing Workflow

1. **cig-implementation** - Define the implementation plan
   - Document files to modify, implementation steps, code changes
   - **Next step suggestion**: `/cig-testing <task>` to define test strategy

2. **cig-testing** - Define the testing regime
   - Document test strategy, test cases, validation criteria
   - **Next step suggestion**: Create checkpoint commit on task branch before executing implementation

3. **Checkpoint Commit** - Save planning work
   - User creates checkpoint commit with planning files (d-implementation.md, e-testing.md, etc.)
   - Commit message should indicate "(WIP - planning complete, implementation pending)"
   - Ensures safe rollback point before making code changes

4. **Execute Implementation** - Make the code changes
   - User implements changes defined in d-implementation.md
   - Follows test-driven approach with test cases from e-testing.md

5. **Execute Testing** - Validate the implementation
   - User runs test cases defined in e-testing.md
   - Updates e-testing.md with actual results
   - Ensures all validation criteria pass

This pattern ensures test strategy is defined before code is written (test-driven), planning work is checkpointed before risky implementation, and provides a safe rollback point if issues arise.

## Validation

- [x] Design review completed
- [x] Architecture choice considers testability (inline bash is easy to test)
- [x] Design maintains consistency across all 8 commands
- [x] Design satisfies simplicity priority (no new scripts, minimal code)
- [x] Design supports reversibility (can be removed easily if needed)
- [ ] Integration points verified with actual workflow command execution
- [ ] Performance validated (<100ms overhead)

## Status
**Status**: Finished
**Next Action**: Design complete - moved to implementation planning
**Blockers**: None identified

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
