# task-tracking-path-cleanup-and-extension - Plan

## Task Reference
- **Task ID**: internal-33
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/33-task-tracking-path-cleanup-and-extension
- **Template Version**: 2.1

## Goal
Extend CIG::TaskPath with orthogonal resolution functions (resolve_num, resolve_branch, resolve_path), lifecycle-aware validation, format converters, and worktree-aware base directory defaults.

## Success Criteria
- [ ] All three resolution functions (resolve_num, resolve_branch, resolve_path) return identical hashref structure
- [ ] Lifecycle validation functions distinguish between task existence checks and creation availability checks
- [ ] Format converters bidirectionally handle filesystem dirname and git branch formats
- [ ] Base directory defaults to current worktree's git root when not specified
- [ ] Backward compatibility maintained - resolve() works as alias for resolve_num()
- [ ] All existing CIG commands continue to work without modification

## Original Estimate
**Effort**: 3-4 days
**Complexity**: Medium
**Dependencies**:
- CIG::TaskPath module (existing, will be extended)
- Task 32 context inference system (consumer of these APIs)
- BACKLOG task "Implement Current Task Tracking" (will use these functions)

## Major Milestones
1. **Orthogonal Resolution API**: Implement resolve_num, resolve_branch, resolve_path with identical output structure
2. **Lifecycle Validation**: Add validate_exists, validate_free, validate_branch_exists, validate_branch_free functions
3. **Format Converters**: Add format_dirname, parse_dirname, format_branch, parse_branch functions
4. **Worktree-Aware Defaults**: Update all functions to default base_dir to git root
5. **Testing & Documentation**: Verify backward compatibility and document new API

## Risk Assessment
### High Priority Risks
- **Backward Compatibility Break**: Changing resolve() behavior could break existing commands
  - **Mitigation**: Make resolve() an alias, not replacement. Add new functions alongside existing ones. Test all existing commands.

- **Regex Parsing Fragility**: Format parsing relies on regex patterns for dirname/branch formats
  - **Mitigation**: Use well-tested patterns from existing code. Add comprehensive test cases for edge cases (dots in slugs, special characters, nested tasks).

### Medium Priority Risks
- **Worktree Edge Cases**: Different worktree configurations might break base_dir detection
  - **Mitigation**: Test in main worktree, separate worktree, and bare repo scenarios. Fallback to relative paths if git command fails.

- **API Discoverability**: Users might not know which resolve_* function to use
  - **Mitigation**: Clear documentation with usage examples. Naming convention makes input type obvious (num vs branch vs path).

## Dependencies
- **CIG::TaskPath module**: Existing module that will be extended (not replaced)
- **Git worktree support**: Requires git rev-parse --show-toplevel to work correctly
- **Existing helper scripts**: hierarchy-resolver, task-context-inference will consume new APIs
- **BACKLOG task**: "Implement Current Task Tracking" depends on these functions

## Constraints
- **Backward compatibility required**: Cannot break existing commands or scripts
- **Perl 5.x**: Must work with existing Perl version used by CIG system
- **No external dependencies**: Can only use core Perl modules already in use
- **Filesystem as ground truth**: Directory existence is authoritative, not git branches

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **No** - Estimated 3-4 days
- [x] **People**: Does this need >2 people working on different parts? **No** - Single developer task
- [x] **Complexity**: Does this involve 3+ distinct concerns? **Yes** - Three distinct areas: resolution functions, validation, format converters
- [ ] **Risk**: Are there high-risk components that need isolation? **No** - Risks are mitigated through testing
- [x] **Independence**: Can parts be worked on separately? **Yes** - Could separate resolution, validation, and formatting concerns

**Analysis**: 2/5 signals triggered (Complexity, Independence). However, these concerns are tightly coupled within the same module and share common patterns. The three areas all operate on the same data structures and are best implemented together for consistency. Breaking into subtasks would create artificial boundaries and require more coordination overhead than benefit.

**Decision**: Proceed as single task. The tight coupling and shared patterns make unified implementation more efficient than decomposition.

## Status
**Status**: In Progress
**Next Action**: Begin requirements analysis - `/cig-requirements-plan 33`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
