# add-task-stack-script - Plan

## Task Reference
- **Task ID**: internal-34
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/34-add-task-stack-script
- **Template Version**: 2.1

## Goal
Implement task stack management system with `.cig/current-task` file handler, user-facing skill, security hooks, and integration with Task 32 inference to enable context-aware task switching.

## Success Criteria
- [ ] `task-stack` script implements push/pop/peek/list/clear/size operations with file locking
- [ ] Output format suitable for agents, humans, and scripts (self-documenting with relative path)
- [ ] `/cig-current-task` skill provides user-friendly interface to task stack
- [ ] PreToolUse hook prevents direct Edit/Write to `.cig/current-task` file
- [ ] Task 32 inference reads top 5 tasks from stack for context-aware detection
- [ ] All operations work with dirname format (e.g., `34-feature-add-task-stack-script`)
- [ ] `.cig/current-task` added to `.gitignore` (user-specific workspace state)

## Original Estimate
**Effort**: 1-2 days (6-12 hours)
**Complexity**: Medium
**Dependencies**:
- Task 33 (CIG::TaskPath.pm) - provides `resolve_num()`, `format_dirname()`, `parse_dirname()`
- Task 32 (inference system) - will integrate stack as additional signal
- Perl file I/O with flock for atomic operations
- Hook system (PreToolUse) in Claude Code

## Major Milestones
1. **Core Stack Script**: Implement `task-stack` with all 6 operations (push/pop/peek/list/clear/size)
2. **User Skill**: Create `/cig-current-task` skill for user-facing management
3. **Security Integration**: Add PreToolUse hook to block direct file editing
4. **Inference Integration**: Update Task 32 to read stack as high-confidence signal
5. **Testing & Documentation**: Verify all operations, document usage patterns

## Risk Assessment
### High Priority Risks
- **Race Conditions in Stack Operations**: Multiple concurrent push/pop operations could corrupt the stack file
  - **Mitigation**: Use `flock(LOCK_EX)` for exclusive locking on all read-modify-write operations. Test concurrent access scenarios.

- **Integration Breaking Task 32**: Modifying inference system could break existing functionality
  - **Mitigation**: Make stack signal optional - inference works if stack doesn't exist. Add integration tests before modifying Task 32 code.

### Medium Priority Risks
- **Hook Not Preventing Direct Edits**: PreToolUse hook might not fire or be bypassed
  - **Mitigation**: Document that hook is advisory, not enforcement. Stack script validates file format on read and repairs corruption if possible.

- **Dirname Format Changes**: If Task 33's format changes, stack entries become invalid
  - **Mitigation**: Use Task 33's `parse_dirname()` which handles format variations. Script degrades gracefully with unparseable entries (shows raw dirname).

- **Performance with Large Stacks**: Reading/writing entire file on every operation could be slow with 1000+ entries
  - **Mitigation**: Current design limits display to last 5 entries. If performance becomes issue, could add index file or use different storage (unlikely with typical usage <100 entries).

## Dependencies
- **Task 33 (CIG::TaskPath.pm)**: Required for `resolve_num()`, `format_dirname()`, `parse_dirname()` functions
- **Task 32 (TaskContextInference.pm)**: Will be modified to read stack as additional signal
- **Git working directory**: Script uses `git rev-parse --show-toplevel` for relative path display
- **Perl 5.x with Fcntl**: Core module for file locking (flock, LOCK_EX, O_APPEND)
- **Claude Code hooks system**: PreToolUse hook for security (advisory, not blocking if unavailable)

## Constraints
- **Backward Compatibility**: Must not break existing Task 32 inference when stack doesn't exist
- **Atomic Operations**: All stack modifications must be atomic (flock-protected) to prevent corruption
- **Scriptable Output**: Output format must be parseable by both agents and shell scripts (`tail -n 1`)
- **No External Dependencies**: Pure Perl with core modules only (Fcntl, FindBin)
- **Dirname Format Only**: Stack stores full dirname format, not just task numbers (preserves context)
- **User-Specific State**: `.cig/current-task` is workspace-specific (gitignored), not shared between developers

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **No** - Estimated 1-2 days (6-12 hours)
- [ ] **People**: Does this need >2 people working on different parts? **No** - Single developer task
- [x] **Complexity**: Does this involve 3+ distinct concerns? **Yes** - Has 4 components (script, command, hook, integration)
- [ ] **Risk**: Are there high-risk components that need isolation? **No** - Risks are mitigated through testing
- [x] **Independence**: Can parts be worked on separately? **Yes** - Could separate script, command, hook, integration

**Analysis**: 2/5 signals triggered (Complexity, Independence). However, these components are tightly coupled:
- Command wraps script (thin wrapper pattern)
- Hook protects script's file (security layer)
- Integration uses script's output (consumer relationship)

All four components work on the same data structure (stack file) and share the same format contract (dirname format). Implementing together ensures:
- Consistent output format across all interfaces
- Single test suite validates entire system
- Atomic delivery of complete feature
- Reduced coordination overhead

**Decision**: Proceed as single task. The components are small individually and tightly coupled functionally. Total estimated effort (6-12 hours) is well within single-task scope.

## Status
**Status**: Finished
**Next Action**: Proceed to requirements phase → `/cig-requirements-plan 34`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
