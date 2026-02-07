# reduce permission prompts from git root detection - Plan

## Task Reference
- **Task ID**: internal-39
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/39-reduce-permission-prompts-from-git-root-detection
- **Template Version**: 2.1

## Goal
Eliminate permission prompts from git root detection by simplifying the pattern and adding git rev-parse to allowed commands.

## Success Criteria
- [ ] Replace `cd "$GIT_ROOT"` pattern with simpler `echo "Git repo root: \"$(git rev-parse --show-toplevel)\""` in all CIG command files
- [ ] Add `git rev-parse` to allowed bash commands in frontmatter for all CIG commands/skills
- [ ] Update cig-new-task command documentation to clarify that template-copier creates directories AND copies workflow files
- [ ] Zero permission prompts for git root detection after changes
- [ ] All CIG commands still function correctly with new pattern

## Original Estimate
**Effort**: 1-2 hours (documentation updates across ~17+ command files)
**Complexity**: Low (straightforward find-replace operation with verification)
**Dependencies**: None - can proceed immediately

## Major Milestones
1. **Update git root detection pattern**: Replace cd pattern with echo pattern in all command files
2. **Update frontmatter permissions**: Add git rev-parse to allowed commands list
3. **Update cig-new-task documentation**: Clarify template-copier behavior to prevent unnecessary mkdir calls
4. **Validation**: Verify no permission prompts and all commands work correctly

## Risk Assessment
### Medium Priority Risks
- **Breaking existing workflows**: Changing git root detection pattern might break commands that depend on current directory
  - **Mitigation**: Review each command to ensure absolute paths are used (not relative to working directory)
- **Missing files**: Might miss some command files in update sweep
  - **Mitigation**: Use grep to find all files with git root detection pattern, verify count matches expected

### Low Priority Risks
- **Inconsistent frontmatter format**: Different commands might have different frontmatter structures
  - **Mitigation**: Check 2-3 sample files first to understand variations, adjust approach accordingly

## Dependencies
- **No external dependencies**: All changes are internal to CIG command files
- **No blocking dependencies**: Can proceed immediately

## Constraints
- **Backward compatibility**: Must maintain functionality for all CIG commands
- **Pattern consistency**: All commands should use same git root detection approach
- **Documentation accuracy**: cig-new-task documentation must accurately reflect template-copier behavior

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **No** - Estimated 1-2 hours total
- [ ] **People**: Does this need >2 people working on different parts? **No** - Single person task
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **No** - Two related concerns (pattern update + documentation)
- [ ] **Risk**: Are there high-risk components that need isolation? **No** - Low risk documentation changes
- [ ] **Independence**: Can parts be worked on separately? **No** - Small scope, closely related changes

**Analysis**: 0/5 signals triggered. Task is appropriately scoped as single bugfix.

## Status
**Status**: Finished
**Next Action**: Move to design planning → `/cig-design-plan 39`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
