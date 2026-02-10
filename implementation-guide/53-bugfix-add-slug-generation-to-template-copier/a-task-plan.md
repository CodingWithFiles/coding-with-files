# add slug generation to template-copier - Plan
**Task**: 53 (bugfix)

## Task Reference
- **Task ID**: internal-53
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/53-add-slug-generation-to-template-copier
- **Template Version**: 2.1

## Goal
Eliminate inline bash slug generation and verbose destination parameters by moving slug generation into template-copier and making destination optional.

## Success Criteria
- [ ] Slug generation function added to template-copier (Perl implementation matching existing bash algorithm)
- [ ] `--destination` parameter made optional (auto-constructs from `directory-structure.pattern` config if omitted)
- [ ] Commands simplified: no inline bash, no manual destination construction for normal use
- [ ] `--destination` remains available for testing/debugging/edge cases (backward compatibility maintained)
- [ ] All existing workflows verified (task creation, subtask creation, edge cases)

## Original Estimate
**Effort**: 2-4 hours
**Complexity**: Low-Medium
**Dependencies**: template-copier-v2.1 script, cig-project.json config, cig-new-task/cig-subtask commands

## Major Milestones
1. **Slug Generation Implementation**: Function added to template-copier matching existing algorithm
2. **Optional Destination Logic**: Parameter made optional with pattern-based auto-construction
3. **Command Simplification**: Commands updated to use simplified invocations
4. **Verification Complete**: All workflows tested and working

## Risk Assessment
### High Priority Risks
- **Breaking existing workflows**: Commands/scripts relying on explicit `--destination` parameter
  - **Mitigation**: Keep `--destination` optional but functional, ensure full backward compatibility

### Medium Priority Risks
- **Slug algorithm mismatch**: Perl implementation differs from bash inline version
  - **Mitigation**: Port exact algorithm (tr/sed pipeline), verify with test cases comparing outputs
- **Edge cases in path construction**: Subtasks, special characters, hierarchy levels
  - **Mitigation**: Thorough testing with various task types (top-level, nested subtasks), validate against existing directory patterns

## Dependencies
- **template-copier-v2.1**: Script to be modified with slug generation
- **cig-project.json**: `directory-structure.pattern` config for path construction
- **cig-new-task/cig-subtask**: Commands that will benefit from simplified invocations

## Constraints
- **Backward compatibility required**: Existing scripts using explicit `--destination` must continue working
- **Algorithm exactness**: Slug generation must produce identical output to existing inline bash (lowercase, hyphenated, alphanumeric only, 50 char max)
- **Core workflow impact**: Changes affect task creation workflow, requires careful testing to avoid breaking existing usage

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [x] **Time**: Will this take >1 week? **NO** - 2-4 hours estimated
- [x] **People**: Does this need >2 people working on different parts? **NO** - single developer task
- [x] **Complexity**: Does this involve 3+ distinct concerns? **NO** - cohesive change to one script (slug generation + parameter handling)
- [x] **Risk**: Are there high-risk components that need isolation? **NO** - medium risk, manageable with testing
- [x] **Independence**: Can parts be worked on separately? **NO** - slug generation and optional destination are tightly coupled

**Decomposition Decision**: No decomposition needed. All signals negative. Single cohesive change to template-copier script.

## Status
**Status**: Finished
**Next Action**: /cig-design-plan 53
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
