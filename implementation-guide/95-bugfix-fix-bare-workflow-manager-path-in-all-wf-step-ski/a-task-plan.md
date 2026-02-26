# Fix bare workflow-manager path in all wf step skills — Plan
**Task**: 95 (bugfix)

## Task Reference
- **Task ID**: internal-95
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/95-fix-bare-workflow-manager-path-in-wf-step-skills
- **Template Version**: 2.1

## Goal
Replace the bare `workflow-manager control` reference in all 10 wf step skill SKILL.md files with the full repo-relative path `.cwf/scripts/command-helpers/workflow-manager control` so that models following the skills can locate the script without guessing.

## Success Criteria
- [ ] All 10 wf step SKILL.md files updated with the full path
- [ ] No remaining bare `workflow-manager control` references in `.claude/skills/`
- [ ] The corrected path resolves correctly from the git repo root

## Original Estimate
**Effort**: < 1 hour
**Complexity**: Low
**Dependencies**: None

## Major Milestones
1. **Audit**: Confirm all 10 affected skill files and exact line content
2. **Fix**: Apply path correction to all 10 files
3. **Verify**: Grep confirms no bare references remain

## Risk Assessment
### Low Priority Risks
- **Missing occurrences**: A skill file could be missed if the grep pattern doesn't match exactly
  - **Mitigation**: Grep both before and after; count must go from 10 to 0

## Dependencies
- None

## Constraints
- Path must be repo-relative (`.cwf/scripts/command-helpers/workflow-manager`), not absolute
- Do not change any other content in the skill files

## Decomposition Check
- [ ] **Time**: No — < 1 hour
- [ ] **People**: No
- [ ] **Complexity**: No — one concern, one pattern, 10 files
- [ ] **Risk**: No
- [ ] **Independence**: No

No decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 95
**Blockers**: None

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
