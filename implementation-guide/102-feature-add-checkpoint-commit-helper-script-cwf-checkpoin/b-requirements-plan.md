# Add Checkpoint Commit Helper Script (cwf-checkpoint-commit) - Requirements
**Task**: 102 (feature)

## Task Reference
- **Task ID**: internal-102
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/102-add-checkpoint-commit-helper-script-cwf-checkpoin
- **Template Version**: 2.1

## Goal
Define what `cwf-checkpoint-commit` must do, how well, and how we verify it.

## Functional Requirements

- **FR1**: Accept three arguments: `<task-path>`, `<phase-letter>` (a-j), `<why-message>`
- **FR2**: Resolve wf file from task-path + phase-letter (glob `{letter}-*.md` — version-agnostic)
- **FR3**: Set status to "Finished", stage the wf file, create a formatted commit with trailer
- **FR4**: Exit 0 on success, non-zero on failure with actionable stderr

## Non-Functional Requirements

- **NFR1**: Reuse `CWF::TaskPath::resolve` and `CWF::TaskState::status_set` — no duplication
- **NFR2**: List-form `system()` for all git calls — no shell interpolation of user input
- **NFR3**: SHA256 hash registered, u+rx permissions

## Acceptance Criteria
- [ ] AC1: `cwf-checkpoint-commit 102 a "Define goals and risks"` produces a correctly formatted commit with status Finished
- [ ] AC2: Script exits non-zero with clear message on invalid input or missing wf file
- [ ] AC3: `checkpoint-commit.md` updated — skills already reference it, no SKILL.md edits needed

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 102
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
