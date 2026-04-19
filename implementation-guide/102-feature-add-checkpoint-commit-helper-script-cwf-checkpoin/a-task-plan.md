# Add Checkpoint Commit Helper Script (cwf-checkpoint-commit) - Plan
**Task**: 102 (feature)

## Task Reference
- **Task ID**: internal-102
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/102-add-checkpoint-commit-helper-script-cwf-checkpoin
- **Template Version**: 2.1

## Goal
Bundle the checkpoint commit procedure into a single atomic helper script, eliminating the most common agent errors during workflow phase transitions (forgetting to stage, wrong message format, skipping validation).

## Success Criteria
- [ ] `cwf-checkpoint-commit` script exists in `.cwf/scripts/command-helpers/` with u+rx permissions
- [ ] Script takes `(task-path, phase-letter, why-message)` and performs status update, staging, and commit atomically
- [ ] `checkpoint-commit.md` updated to document the script (skills already reference this doc)
- [ ] SHA256 hash registered in `.cwf/security/script-hashes.json`

## Original Estimate
**Effort**: 1 day
**Complexity**: Medium
**Dependencies**: `cwf-set-status` (Task 101, completed), `cwf-manage validate`, existing checkpoint-commit.md documentation

## Major Milestones
1. **Script implementation**: Working `cwf-checkpoint-commit` helper script
2. **Doc update**: `checkpoint-commit.md` documents the script as primary method
3. **Validation**: End-to-end test through a real workflow phase

## Risk Assessment
### Medium Priority Risks
- **Risk: Partial failure**: Script sets status to Finished but git commit fails, leaving status updated without a commit
  - **Mitigation**: Acceptable — status field is easily re-set; document recovery in checkpoint-commit.md

## Dependencies
- `cwf-set-status` / `CWF::TaskState::status_set` (Task 101 — complete)
- `CWF::TaskPath::resolve` (existing — task directory resolution)

## Constraints
- Must follow existing helper script patterns (Perl, FindBin, `use lib`)
- List-form `system()` for git calls (no shell interpolation)

## Decomposition Check
- [x] **Time**: No — estimated 1 day
- [x] **People**: No — single developer
- [x] **Complexity**: No — single concern (orchestrating existing tools)
- [x] **Risk**: No — low blast radius, existing primitives
- [x] **Independence**: No — all parts tightly coupled

**Result**: 0/5 signals triggered. No decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan 102
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
