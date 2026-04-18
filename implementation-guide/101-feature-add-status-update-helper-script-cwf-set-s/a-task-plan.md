# Add Status Update Helper Script (cwf-set-status) - Plan
**Task**: 101 (feature)

## Task Reference
- **Task ID**: internal-101
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/101-add-status-update-helper-script-cwf-set-s
- **Template Version**: 2.1

## Goal
Create a helper script that validates and updates the `**Status**:` field in workflow files, replacing the manual regex replacement agents currently perform on every checkpoint commit across all ~10 workflow skills.

## Success Criteria
- [ ] Script accepts `(file-path, new-status)` and updates the status field in-place
- [ ] Script rejects invalid status values with a clear error listing valid options
- [ ] Valid status values read from `cwf-project.json`, not hardcoded
- [ ] Script is idempotent (setting the same status twice produces no change)
- [ ] All existing workflow skills can delegate status updates to this script
- [ ] Script follows existing helper script conventions (Perl, `u+rx`, SHA256 tracked)

## Original Estimate
**Effort**: 1 day
**Complexity**: Low
**Dependencies**: None — all prerequisite infrastructure exists

## Major Milestones
1. **Script created**: `cwf-set-status` in `.cwf/scripts/command-helpers/` with validation and in-place update
2. **Tests passing**: Unit tests covering valid updates, invalid status rejection, idempotency, and edge cases
3. **Integrated**: Security hashes updated, `cwf-manage validate` passes

## Risk Assessment
### Medium Priority Risks
- **Regex fragility**: The `**Status**: <value>` pattern could appear in non-status contexts
  - **Mitigation**: First-match strategy is sufficient — every wf file has exactly one `**Status**:` line

## Constraints
- Perl 5.14+, core modules only (JSON::PP)
- Relative path to `cwf-project.json` (skills always run from repo root)

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [x] **Time**: Will this take >1 week? **No** — estimated 1 day
- [x] **People**: Does this need >2 people? **No** — single author
- [x] **Complexity**: Does this involve 3+ distinct concerns? **No** — one script, one job
- [x] **Risk**: Are there high-risk components? **No** — additive change, nothing removed
- [x] **Independence**: Can parts be worked on separately? **No** — single deliverable

**Result**: 0/5 signals triggered. No decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan 101
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
