# Migrate Old Tasks to v2.0 - Plan

## Task Reference
- **Task ID**: internal-5
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/5-migrate-old-tasks-to-v2.0
- **Template Version**: 2.0

## Goal
Update tasks 1-3 from v1.0 format to v2.0 format so status aggregation tools show correct completion status

## Success Criteria
- [ ] All "Completed" status values changed to "Finished" in tasks 1-2
- [ ] All placeholder `<status-type>` values removed from task 3
- [ ] `/cig-status` shows 100% completion for all finished tasks (1-3)
- [ ] Status aggregation runs without warnings for tasks 1-3
- [ ] All migrated tasks continue to display correctly in task hierarchy

## Original Estimate
**Effort**: 0.5 days
**Complexity**: Low
**Dependencies**: None - tasks 1-3 already exist with v2.0 structure from migration script

## Major Milestones
1. **Status Value Updates**: Replace "Completed" with "Finished" across all workflow files in tasks 1-2
2. **Placeholder Removal**: Replace `<status-type>` placeholders with actual "Finished" status in task 3
3. **Verification**: Run status-aggregator.sh to confirm 100% completion showing correctly

## Risk Assessment
### High Priority Risks
- **Breaking Git History**: Editing historical commits could disrupt repository integrity
  - **Mitigation**: Edit files directly on current HEAD, do not rewrite git history

### Medium Priority Risks
- **Missing Status Fields**: Some files might have non-standard status field formats
  - **Mitigation**: Use grep to find all status patterns before bulk editing

## Dependencies
- Tasks 1-3 must exist in v2.0 structure (already complete via task 4 migration)
- status-aggregator.sh must be working (already operational)

## Constraints
- Cannot rewrite git history - must work with current file state
- Must preserve all other content in workflow files
- Must use valid status values from cig-project.json (Finished = 100%)

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **No** - estimated 0.5 days
- [ ] **People**: Does this need >2 people working on different parts? **No** - single-person text replacement
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **No** - simple status value replacement
- [ ] **Risk**: Are there high-risk components that need isolation? **No** - low-risk text edits
- [ ] **Independence**: Can parts be worked on separately? **No** - all status updates interdependent

**Analysis**: 0/5 signals triggered. Task is straightforward and does not require decomposition.

## Status
**Status**: Finished
**Next Action**: Move to implementation (`/cig-implementation 5`)
**Blockers**: None

## Actual Results
Task completed within estimate (0.5 days). Migrated 20 files successfully:
- 13 files: "Completed" → "Finished" (tasks 1-2)
- 2 files: Added missing status sections (task 1)
- 2 files: "Not Started" → "Finished" (task 2)
- 5 files: Fixed documentation placeholders (task 3)

Status aggregation now shows 85.7% project completion with zero warnings.

## Lessons Learned
- Initial file discovery missed edge cases (missing sections, "Not Started" values)
- Documentation code examples can trigger status parsing if using exact field syntax
- Using production tools (status-aggregator.sh) for validation is more reliable than manual grep
