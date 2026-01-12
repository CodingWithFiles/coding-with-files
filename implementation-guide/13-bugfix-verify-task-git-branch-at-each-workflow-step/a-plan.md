# verify task git branch at each workflow step - Plan

## Task Reference
- **Task ID**: internal-13
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/13-verify-task-git-branch-at-each-workflow-step
- **Template Version**: 2.0

## Goal
Ensure each CIG workflow step command verifies the user is on the correct git branch for the task before proceeding with workflow operations.

## Success Criteria
- [ ] All 8 workflow commands (plan, requirements, design, implementation, testing, rollout, maintenance, retrospective) check git branch before executing
- [ ] Branch verification uses the task's defined branch name from Task Reference section
- [ ] User receives clear warning if on wrong branch with suggested checkout command
- [ ] Branch check can be bypassed with explicit flag if needed (e.g., --skip-branch-check for exceptional cases)
- [ ] Changes tested across multiple task scenarios to ensure no regression

## Original Estimate
**Effort**: 3-4 hours
**Complexity**: Low-Medium
**Dependencies**:
- Git must be available in environment
- Task Reference section must contain branch name in all workflow files
- Understanding of current workflow command structure

## Major Milestones
1. **Design branch verification approach**: Determine where and how to inject branch check in workflow commands
2. **Implement verification logic**: Add branch checking to all 8 workflow commands
3. **Test verification across workflows**: Validate branch checks work correctly for various scenarios
4. **Document bypass mechanism**: Ensure users can override if necessary for edge cases

## Risk Assessment
### High Priority Risks
- **Breaking existing workflows**: Adding verification might interrupt users mid-task
  - **Mitigation**: Make verification informative but not blocking initially; test thoroughly before making it strict

### Medium Priority Risks
- **Git commands fail in non-git environments**: Some users might run CIG outside git repos
  - **Mitigation**: Check if directory is git repo first, gracefully skip if not
- **Branch name format variations**: Different tasks might have different branch naming conventions
  - **Mitigation**: Extract branch name from Task Reference section dynamically, don't hardcode format

## Dependencies
- Git must be installed and accessible via command line
- All workflow files must have Task Reference section with Branch field populated
- Tasks must be created using cig-new-task which populates branch names

## Constraints
- Must not break backward compatibility with existing tasks
- Must work within allowed-tools restrictions for each workflow command (currently allows Bash with limited commands)
- Should be fast (<100ms overhead) to not slow down workflow commands

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **No** - Estimated 3-4 hours
- [ ] **People**: Does this need >2 people working on different parts? **No** - Single developer task
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **No** - Single concern: branch verification across commands
- [ ] **Risk**: Are there high-risk components that need isolation? **No** - Low risk, non-breaking change
- [ ] **Independence**: Can parts be worked on separately? **No** - All 8 commands need consistent implementation

**Decomposition Decision**: No decomposition needed. This is a cohesive, small-scope bugfix that should be implemented atomically.

## Status
**Status**: Finished
**Next Action**: Planning complete - moved to design phase
**Blockers**: None identified

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
