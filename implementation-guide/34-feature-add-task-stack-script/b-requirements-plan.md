# add-task-stack-script - Requirements

## Task Reference
- **Task ID**: internal-34
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/34-add-task-stack-script
- **Template Version**: 2.1

## Goal
Define functional and non-functional specifications for task stack management system with operations, output formats, security controls, and integration requirements.

## Functional Requirements

### Core Stack Operations
- **FR1**: Push operation adds task to stack in dirname format
  - **Input**: Task number (e.g., "34")
  - **Process**: Resolve task number to full dirname via CIG::TaskPath::resolve_num() and format_dirname()
  - **Output**: Confirmation message with task info
  - **Storage**: Append dirname to `.cig/current-task` file with newline
  - **Criteria**: Task must exist in implementation-guide/, dirname must be valid format

- **FR2**: Pop operation removes and returns top task from stack
  - **Process**: Read file, remove last line, truncate file, return popped dirname
  - **Output**: Confirmation message with parsed task info
  - **Criteria**: Stack must not be empty, file must remain valid after pop

- **FR3**: Peek operation shows current task without modification
  - **Process**: Read file, return last line
  - **Output**: Just the dirname (for scripting) or parsed info (for humans)
  - **Criteria**: Stack must not be empty

- **FR4**: List operation shows last 5 tasks with metadata
  - **Output Format**:
    - Line 1: `{rel_path}/task-stack: list task stack (use --help for options)`
    - Line 2: `{rel_path}/task-stack: showing N of M total tasks, most recent last`
    - Lines 3+: Raw dirnames (oldest to newest)
  - **Criteria**: Shows up to 5 most recent, indicates total count, scriptable with `tail -n 1`

- **FR5**: Clear operation empties the stack
  - **Process**: Delete `.cig/current-task` file
  - **Output**: Confirmation message
  - **Criteria**: Operation succeeds even if file doesn't exist (idempotent)

- **FR6**: Size operation returns task count
  - **Output**: Integer count only (for scripting)
  - **Criteria**: Returns 0 if file doesn't exist

### User Interface
- **FR7**: `/cig-current-task` skill provides user-friendly interface
  - `/cig-current-task` → calls `task-stack list`
  - `/cig-current-task push <num>` → calls `task-stack push <num>`
  - `/cig-current-task pop` → calls `task-stack pop`
  - `/cig-current-task clear` → calls `task-stack clear`
  - **Criteria**: Skill is thin wrapper around script, no logic duplication

### Security Controls
- **FR8**: PreToolUse hook prevents direct file editing
  - **Trigger**: Edit or Write tool with file_path matching `.cig/current-task`
  - **Action**: Block operation, explain error, suggest using `/cig-current-task` instead
  - **Criteria**: Hook is advisory (documents intent), script validates format on read

### Integration
- **FR9**: Task 32 inference reads stack as signal
  - **Input**: Last 5 entries from `.cig/current-task`
  - **Process**: Parse dirnames to extract task numbers
  - **Output**: Primary candidate (top of stack) + context (all 5)
  - **Signal Weight**: High confidence (score 100) when stack exists
  - **Criteria**: Inference works with or without stack (optional signal)

### Cleanup
- **FR10**: Remove obsolete `/cig-current` command if it exists
  - **Check**: `.claude/commands/cig-current.md` or `.claude/plugins/*/skills/cig-current/`
  - **Action**: Delete old command/skill files
  - **Rationale**: Prevent confusion between old and new interface
  - **Criteria**: No references to `/cig-current` remain in codebase

### User Stories
- **As a developer** I want to push the current task onto a stack **so that** I can context-switch to another task and return later
- **As a developer** I want to pop tasks from the stack **so that** I can return to previous work after handling interruptions
- **As a script** I want to read the current task with `tail -n 1` **so that** I can programmatically detect the active task
- **As an agent** I want to see the script path in output **so that** I can learn where tools are located and execute them
- **As an agent** I want to see `--help` hint **so that** I know how to discover additional options

## Non-Functional Requirements

### Performance (NFR1)
- **Response time**: All operations complete in < 100ms for stacks up to 1000 entries
- **File I/O**: Single read/write per operation (no repeated file access)
- **Memory usage**: < 1MB for typical usage (< 100 stack entries)
- **Concurrency**: Operations are atomic via flock() - no race conditions

### Usability (NFR2)
- **Learning curve**: Output format self-documents usage (shows script path, --help hint)
- **Error messages**: Include script path, operation attempted, actionable suggestion
  - Example: `.cig/scripts/command-helpers/task-stack: error: task 99 not found`
- **Consistency**: Follows CIG helper script patterns (Perl, hierarchy-resolver style)
- **Scriptability**: Output parseable by both agents and shell pipelines

### Maintainability (NFR3)
- **Code clarity**: Functions named after operations (push_task, pop_task, list_stack)
- **Modularity**: Single script with clear operation dispatch (similar to git-style commands)
- **Testability**: Each operation testable independently via command-line invocation
- **Documentation**: Inline comments explain file format, locking strategy, output format

### Security (NFR4)
- **File permissions**: `.cig/current-task` created with user-only access (0600)
- **Input validation**: Task numbers validated via CIG::TaskPath::resolve_num()
- **Path traversal prevention**: No user-provided paths, only validated task numbers
- **Atomic operations**: flock(LOCK_EX) prevents corruption from concurrent access
- **Advisory hook**: PreToolUse hook documents intent but doesn't enforce (script validates on read)

### Reliability (NFR5)
- **Availability**: Always available (no external dependencies, pure Perl)
- **Error handling**: Graceful degradation when stack empty or file missing
- **Data integrity**:
  - Atomic write (flock prevents partial writes)
  - Format validation on read (parse_dirname handles corruption)
  - Idempotent operations (clear succeeds on empty stack)
- **Backward compatibility**: Works with or without Task 32 integration

## Constraints

### Technical Constraints
- **Perl 5.x only**: No external CPAN modules, core modules only (Fcntl, FindBin)
- **Git repository required**: Relative path display uses `git rev-parse --show-toplevel`
- **File-based storage**: Single file `.cig/current-task`, one dirname per line
- **Dirname format**: Must store full dirname format (not just task numbers) for context preservation

### Integration Constraints
- **Task 33 dependency**: Requires CIG::TaskPath.pm functions (resolve_num, format_dirname, parse_dirname)
- **Task 32 optional**: Inference integration is optional - system works standalone
- **Backward compatible**: Must not break existing Task 32 functionality when stack doesn't exist
- **Hook availability**: PreToolUse hook may not be available in all Claude Code versions

### Resource Constraints
- **User-specific state**: Stack is per-developer workspace, not shared via git
- **No centralization**: No server-side coordination, purely local file
- **Manual cleanup**: Old entries never auto-expire (user must manage stack)

## Acceptance Criteria

### Functional Acceptance
- [ ] AC1: Push operation resolves task 34 and stores `34-feature-add-task-stack-script` in file
- [ ] AC2: Pop operation removes last entry and returns it, file has N-1 lines
- [ ] AC3: Peek operation returns last entry without modifying file
- [ ] AC4: List shows correct header with script path and `--help` hint
- [ ] AC5: List output works with `tail -n 1` to get current task
- [ ] AC6: Clear operation deletes file and succeeds idempotently
- [ ] AC7: Size returns correct count (0 for missing file)

### Non-Functional Acceptance
- [ ] AC8: All operations complete in < 100ms on stacks with 100 entries
- [ ] AC9: Concurrent operations (2 pushes simultaneously) don't corrupt file
- [ ] AC10: Error messages include script path and actionable guidance
- [ ] AC11: Invalid task number (99999) produces clear error, doesn't create file

### Integration Acceptance
- [ ] AC12: `/cig-current-task` skill successfully wraps task-stack operations
- [ ] AC13: PreToolUse hook blocks Edit to `.cig/current-task` with helpful message
- [ ] AC14: Task 32 inference reads stack and uses top entry as primary candidate
- [ ] AC15: Task 32 inference still works when `.cig/current-task` doesn't exist

### Security Acceptance
- [ ] AC16: File created with 0600 permissions (user-only access)
- [ ] AC17: flock prevents partial writes during concurrent access
- [ ] AC18: Invalid dirname formats in file don't crash script (graceful degradation)

### Cleanup Acceptance
- [ ] AC19: Old `/cig-current` command/skill files removed if they exist
- [ ] AC20: Grep for `/cig-current` returns no matches (except `/cig-current-task`)

## Status
**Status**: Finished
**Next Action**: Proceed to design phase → `/cig-design-plan 34`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
