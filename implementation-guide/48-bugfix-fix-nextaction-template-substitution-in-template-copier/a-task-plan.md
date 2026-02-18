# fix nextAction template substitution in template-copier - Plan
**Task**: 48 (bugfix)

## Task Reference
- **Task ID**: internal-48
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/48-fix-nextaction-template-substitution-in-template-copier
- **Template Version**: 2.1

## Goal
Fix template-copier-v2.1 to derive command names from template symlink filenames instead of using hardcoded %PHASE_COMMANDS mapping, establishing directory structure as single source of truth for workflow routing.

## Success Criteria
- [ ] `compute_next_action()` derives command name from next template filename (removes phase prefix, strips .md.template extension, prepends /cig-)
- [ ] Hardcoded `%PHASE_COMMANDS` mapping removed (lines 243-254 in template-copier-v2.1)
- [ ] Create test bugfix task: g-testing-exec.md shows "Next Action: /cig-retrospective 48" (not "/cig-rollout")
- [ ] All 5 task types tested: feature, bugfix, hotfix, chore, discovery workflows generate correct nextAction in all phases
- [ ] No regression: Template copying still works for all task types (variables substituted, permissions set)

## Original Estimate
**Effort**: 2-3 hours (modify compute_next_action(), remove hardcoded mapping, test 5 task types)
**Complexity**: Low (single function change, existing infrastructure already works)
**Dependencies**:
- Task 47 must be merged first (we're fixing the bug it discovered)
- Template symlink structure must remain stable during testing

## Major Milestones
1. **Algorithm implemented**: `compute_next_action()` derives command from filename (strip phase prefix + extension, prepend /cig-)
2. **Hardcoded mapping removed**: `%PHASE_COMMANDS` deleted, single source of truth established
3. **All task types tested**: 5 workflow types verified to generate correct nextAction in all phases

## Risk Assessment
### High Priority Risks
- **Breaking template creation for all task types**: Incorrect filename parsing could break task creation workflow entirely
  - **Mitigation**: Test all 5 task types after change, verify both nextAction substitution AND overall template copying still works

### Medium Priority Risks
- **Incorrect regex patterns**: Filename transformation regex could fail on edge cases or future filename changes
  - **Mitigation**: Use simple, clear regex patterns (`s/^[a-j]-//` and `s/\.md\.template$//`), add comments explaining transformation
- **Last phase handling**: j-retrospective.md is last phase, needs special handling (no next action or return retrospective)
  - **Mitigation**: Check if current_idx >= $#sequence before accessing next element, return appropriate message

## Dependencies
- **Task 47**: Must be merged first (this fixes the bug Task 47 discovered during rollout)
- **Template structure stability**: Symlink structure in `.cig/templates/{type}/` must remain stable during testing
- **Existing infrastructure**: `get_phase_sequence()` (lines 219-240) already works correctly, no changes needed

## Constraints
- **Backward compatibility**: Must not break existing task creation workflow (all template variables must still substitute correctly)
- **Filename convention**: Solution depends on stable naming convention (phase-letter prefix + descriptive name + .md.template)
- **Scope limitation**: Only fix `compute_next_action()`, don't refactor other parts of template-copier-v2.1

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **NO** - Estimated 2-3 hours
- [ ] **People**: Does this need >2 people working on different parts? **NO** - Single person, single function change
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **NO** - Single concern: derive command from filename
- [ ] **Risk**: Are there high-risk components that need isolation? **NO** - Low risk, testable change
- [ ] **Independence**: Can parts be worked on separately? **NO** - Atomic change to one function

**Decision**: No decomposition needed (0/5 signals triggered)

## Status
**Status**: Finished
**Next Action**: /cig-design-plan 48 (bugfix workflow: planning → design → implementation)
**Blockers**: Task 47 should be merged first (not blocking planning, but blocking implementation)

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
