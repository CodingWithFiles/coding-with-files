# Add discovery workflow - Plan

## Task Reference
- **Task ID**: internal-9
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/9-add-discovery-workflow
- **Template Version**: 2.0

## Goal
Add "discovery" as a new supported task type for analysis, research, and exploratory tasks that don't require deployment phases.

## Success Criteria
- [ ] `discovery` added to supported-task-types in cig-project.json
- [ ] `.cig/templates/discovery/` directory created with 6 symlinks
- [ ] `/cig-new-task` command updated to accept discovery type
- [ ] Documentation updated
- [ ] Can successfully run `/cig-new-task 1 discovery "test task"`

## Original Estimate
**Effort**: <1 day
**Complexity**: Low
**Dependencies**: None - additive change

## Major Milestones
1. **Configuration**: Add discovery to cig-project.json
2. **Templates**: Create discovery template directory with symlinks
3. **Commands**: Update cig-new-task to recognise discovery type
4. **Documentation**: Update workflow docs

## Risk Assessment
### Low Priority Risks
- **Risk 1**: Missing template symlinks
  - **Mitigation**: Use lensman as reference for correct file set

## Dependencies
- Reference implementation in /home/matt/repo/lensman

## Constraints
- Must follow existing template symlink pattern
- Must skip rollout (f) and maintenance (g) phases

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [x] **Time**: Will this take >1 week? No
- [x] **People**: Does this need >2 people? No
- [x] **Complexity**: Does this involve 3+ distinct concerns? No
- [x] **Risk**: Are there high-risk components? No
- [x] **Independence**: Can parts be worked on separately? N/A

**Decision**: Keep as single task - simple additive change.

## Status
**Status**: Finished
**Next Action**: Implement changes
**Blockers**: None

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
