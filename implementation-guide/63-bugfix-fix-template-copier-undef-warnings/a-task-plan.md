# Fix template-copier undef warnings for unresolved variables - Plan
**Task**: 63 (bugfix)

## Task Reference
- **Task ID**: internal-63
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/63-fix-template-copier-undef-warnings
- **Template Version**: 2.1

## Goal
Eliminate undef warnings in template-copier-v2.1 when template variables (`$branch`, `$value`) are unavailable at copy time, and add a sparse-checkout bootstrap sequence to README/INSTALL.md so agents can install CWF from just a git URL.

## Success Criteria
- [ ] Zero Perl warnings when running `/cwf-new-task` (no "Use of uninitialized value" messages)
- [ ] `$branch` variable populated by inferring from task type/num/slug rather than requiring an existing git branch
- [ ] Undef variable values in `substitute_variables()` handled gracefully (empty string or placeholder retained)
- [ ] Existing template variable substitution still works correctly for all defined variables
- [ ] perlcritic --stern passes on template-copier-v2.1
- [ ] README.md and INSTALL.md contain sparse-checkout bootstrap sequence for agent install

## Original Estimate
**Effort**: 1 session
**Complexity**: Low
**Dependencies**: None — template-copier-v2.1 is self-contained

## Major Milestones
1. **Fix `$branch` undef**: Ensure branch name is computed from config pattern + task params, defaulting to empty string if pattern is missing
2. **Fix `$value` undef in substitute_variables()**: Guard against undef values in the substitution loop
3. **Sparse-checkout bootstrap**: Add agent-friendly install instructions to README.md and INSTALL.md
4. **Verify**: No warnings on `/cwf-new-task`, all existing substitutions still work

## Risk Assessment
### Low Priority Risks
- **Masking real bugs**: Silently substituting empty string for undef could hide legitimate missing data
  - **Mitigation**: Use `// ''` (defined-or empty string) rather than suppressing warnings. The template will show blank fields which are visible and fixable during the task plan step.

## Dependencies
- None

## Constraints
- template-copier-v2.1 is used by task-workflow which is called by `/cwf-new-task` and `/cwf-subtask` — changes must not break either path
- Core Perl only (no CPAN)

## Decomposition Check
- [x] **Time**: No
- [x] **People**: No
- [x] **Complexity**: No — two related fixes in one file
- [x] **Risk**: No
- [x] **Independence**: No

Zero signals. No decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 63
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Completed in 1 session as estimated. Scope expanded: added sparse-checkout bootstrap docs, fixed 3 perlcritic violations, and guarded a fatal array deref found during external testing.

## Lessons Learned
Grep for ALL undef-unsafe patterns in a file in one pass when fixing undef safety. Cascade design changes to implementation/testing plans immediately.
