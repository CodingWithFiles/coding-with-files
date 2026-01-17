# Use Hierarchical Numbering for Sub-steps in Workflow Templates - Plan

## Task Reference
- **Task ID**: internal-24
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/24-use-hierarchical-numbering-for-sub-steps-in-workf
- **Template Version**: 2.0

## Goal
Eliminate numbering ambiguity in CIG workflow command files by: (1) converting sub-step numbering from restarting-at-1 pattern to hierarchical notation (e.g., 9.1, 9.2, 9.3), and (2) standardizing main step format from markdown headers to numbered lists across all files.

## Success Criteria
- [ ] All 8 workflow command files use consistent numbered list format for main steps (not markdown headers)
- [ ] All hierarchical sub-steps use N.M notation (no sub-steps restart at "1.")
- [ ] cig-plan.md converted from `### Step N:` headers to `N. **Step Name**:` numbered lists
- [ ] Document structure unambiguous when scanning workflow steps
- [ ] All sub-step references updated (no broken cross-references)
- [ ] Consistent enumeration pattern across all workflow commands

## Original Estimate
**Effort**: 2-3 hours (manual editing across 8 files)
**Complexity**: Low (mechanical find-and-replace pattern)
**Dependencies**: Understanding current sub-step locations in all workflow commands

## Major Milestones
1. **Audit Current Formats**: Identify all locations where sub-step numbering restarts at "1." and where main steps use markdown headers
2. **Define Conversion Patterns**: Establish systematic approach for (a) converting "1. 2. 3." to "N.1, N.2, N.3" format, and (b) converting `### Step N:` to `N. **Step Name**:`
3. **Update cig-plan.md Format**: Convert markdown headers to numbered list format for consistency
4. **Update cig-retrospective.md**: Apply hierarchical numbering to existing sub-steps
5. **Validate Consistency**: Ensure all 8 files use identical enumeration pattern
6. **Validate References**: Ensure no cross-references to step numbers are broken by numbering changes
7. **Test Readability**: Verify improved clarity when scanning workflow structure

## Risk Assessment
### High Priority Risks
None identified - low-risk documentation change

### Medium Priority Risks
- **Broken Cross-References**: Changing step numbers might break references elsewhere in the command files
  - **Mitigation**: Grep for step number references before changing, update systematically
- **Inconsistent Application**: Missing some sub-steps or applying pattern inconsistently across files
  - **Mitigation**: Create checklist of all 8 files, verify each file individually before marking complete
- **Markdown Rendering Issues**: Some markdown parsers may handle "9.1." differently than "1."
  - **Mitigation**: Test rendered output in Claude Code interface after changes

## Dependencies
- All 8 workflow command files must be accessible for editing
- Understanding of current workflow step structure in each command

## Constraints
- Must maintain backward compatibility with any scripts that reference step numbers (unlikely, but check)
- Cannot change meaning or order of workflow steps, only numbering format
- Must preserve all existing content and formatting except numbering

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **No** - estimated 2-3 hours
- [ ] **People**: Does this need >2 people working on different parts? **No** - single developer can edit all 8 files
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **No** - single concern (numbering format consistency)
- [ ] **Risk**: Are there high-risk components that need isolation? **No** - low-risk documentation changes
- [ ] **Independence**: Can parts be worked on separately? **No** - all 8 files should use same pattern, best done together for consistency

**Result**: 0/5 signals triggered - no decomposition needed

**Rationale**: Mechanical editing task across 8 files with consistent pattern. Better to maintain consistency by doing all changes in one task rather than splitting across subtasks.

## Status
**Status**: Finished
**Next Action**: Proceed to implementation phase with `/cig-implementation 24`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
