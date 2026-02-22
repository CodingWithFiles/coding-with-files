# Ensure retrospective checkpoint commit stages entire task directory - Testing Plan
**Task**: 85 (hotfix)

## Task Reference
- **Task ID**: internal-85
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/85-ensure-retrospective-checkpoint-commit-stages-entire-ta
- **Template Version**: 2.1

## Goal
Validate that the new "Retrospective Checkpoint Commit" section in
`retrospective-extras.md` is correctly placed, clearly worded, and complete.

## Test Strategy
Manual doc review — no automated tests apply to a markdown documentation change.

## Test Cases

- **TC-1**: Section exists in correct location
  - **Given**: `retrospective-extras.md` has been edited
  - **When**: The file is read
  - **Then**: A "Retrospective Checkpoint Commit" section appears between
    "Verify Task Status" and "CHANGELOG.md and BACKLOG.md Update"

- **TC-2**: Section contains `git add` of task directory
  - **Given**: The new section
  - **When**: The `git add` command is read
  - **Then**: It stages `implementation-guide/<task-dir>/` (the whole directory),
    not just `j-retrospective.md`

- **TC-3**: Section notes the override of `checkpoint-commit.md`
  - **Given**: The new section
  - **When**: The rationale text is read
  - **Then**: It explains this overrides the generic single-file staging instruction

- **TC-4**: "Verify Task Status" uses `workflow-manager status` command
  - **Given**: The updated "Verify Task Status" section
  - **When**: The verification command is read
  - **Then**: It references `.cwf/scripts/command-helpers/workflow-manager status <task_num> --workflow`

- **TC-5**: "Verify Task Status" uses correct terminal-status framing
  - **Given**: The updated "Verify Task Status" section
  - **When**: The guidance text is read
  - **Then**: It states that individual wf steps must be in a terminal status
    (Finished, Skipped, Cancelled), the overall task must report 100% ("Finished"),
    this is the norm, and the user must be explicitly informed if it is not

- **TC-6**: `cwf-manage validate` passes
  - **Given**: The edited file is committed
  - **When**: `.cwf/scripts/cwf-manage validate` is run
  - **Then**: Exit 0, `[CWF] validate: OK`

## Validation Criteria
- [ ] TC-1 passes: section in correct position
- [ ] TC-2 passes: `git add <task-dir>/` present
- [ ] TC-3 passes: override rationale present
- [ ] TC-4 passes: `workflow-manager status` command referenced
- [ ] TC-5 passes: non-100% framed as exception
- [ ] TC-6 passes: `cwf-manage validate` clean

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 85
**Blockers**: None

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
