# fix var use in commands to avoid bash issues - Plan
**Task**: 47 (bugfix)

## Task Reference
- **Task ID**: internal-47
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/47-fix-var-use-in-commands-to-avoid-bash-issues
- **Template Version**: 2.1

## Goal
Standardize placeholder syntax to `{placeholder}` style across all 17 CIG command files by replacing `$VARIABLE` and `<placeholder>` patterns to prevent LLM from creating unnecessary bash wrappers that trigger permission prompts.

## Success Criteria
- [ ] All 17 command files use `{placeholder}` style consistently (zero `$VARIABLE` or `<placeholder>` patterns remaining)
- [ ] Frontmatter `argument-hint` fields updated: `<task-path>` → `{task-path}`, `<num>` → `{num}`, etc.
- [ ] No prose/notes inside bash code blocks (all explanatory text moved outside)
- [ ] Manual validation: Execute 3-5 representative commands without permission prompts for helper script calls
- [ ] Documentation updated: Add placeholder syntax convention to `.cig/docs/conventions/` (if needed)
- [ ] BACKLOG item "Fix Command Bash Snippets and Argument Placeholders" marked complete

## Original Estimate
**Effort**: 2-3 hours (mechanical find-replace across 17 files + validation)
**Complexity**: Low (pattern replacement, no logic changes)
**Dependencies**:
- None (pure refactoring, no functional changes)
- All 17 CIG command files accessible and editable

## Major Milestones
1. **Audit complete**: All 17 command files audited for `$VARIABLE` and `<placeholder>` usage patterns
2. **Replacements done**: All `$VARIABLE` → `{placeholder}` and `<placeholder>` → `{placeholder}` replacements completed, prose removed from bash blocks
3. **Validation passed**: Manual testing confirms no permission prompts for helper script calls

## Risk Assessment
### High Priority Risks
- **Breaking existing commands**: Incorrect placeholder syntax could break command execution
  - **Mitigation**: Test 3-5 representative commands after changes, verify commands still parse correctly

### Medium Priority Risks
- **Missed edge cases**: Some `$VAR` usage might be legitimate bash (e.g., in actual bash examples showing variable expansion)
  - **Mitigation**: Manual review of each replacement, preserve legitimate bash examples with clear documentation
- **Inconsistent application**: Missing some files or patterns during replacement
  - **Mitigation**: Use Grep to find ALL `$VARIABLE` patterns before starting, verify zero matches after completion

## Dependencies
- None (self-contained refactoring task)
- No external APIs, services, or team coordination required

## Constraints
- **Backward compatibility**: Must preserve existing command functionality (no behavior changes)
- **Scope limitation**: Only change placeholder syntax, don't refactor command logic or structure
- **Documentation clarity**: Replacement syntax must be obvious to LLMs (clear that `{placeholder}` indicates substitution point)

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **NO** - Estimated 2-3 hours
- [ ] **People**: Does this need >2 people working on different parts? **NO** - Single person mechanical refactoring
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **NO** - Single concern: placeholder syntax standardization
- [ ] **Risk**: Are there high-risk components that need isolation? **NO** - Low risk, testable changes
- [ ] **Independence**: Can parts be worked on separately? **NO** - Better done atomically for consistency

**Decision**: No decomposition needed (0/5 signals triggered)

## Status
**Status**: Finished
**Next Action**: /cig-design-plan 47 (bugfix workflow: planning → design → implementation)
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
