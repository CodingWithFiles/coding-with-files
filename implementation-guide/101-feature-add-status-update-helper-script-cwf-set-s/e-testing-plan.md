# Add Status Update Helper Script (cwf-set-status) - Testing Plan
**Task**: 101 (feature)

## Task Reference
- **Task ID**: internal-101
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/101-add-status-update-helper-script-cwf-set-s
- **Template Version**: 2.1

## Goal
Define test strategy and validation approach for Add Status Update Helper Script (cwf-set-status).

## Test Strategy

### Test Levels
- **Script-level tests**: Invoke `cwf-set-status` as a subprocess and verify stdout, stderr, exit code, and file modifications
- **Integration**: Run against real wf files in a temp directory with a real `cwf-project.json`
- **Regression**: Run existing `cwf-manage validate` to ensure no breakage

### Test Coverage Targets
- Both exit codes exercised (0, 1)
- Happy path, idempotency, and all error paths tested

## Test Cases

### Functional Test Cases

- **TC-F1**: Successful status update
  - **Given**: A wf file with `**Status**: Backlog`
  - **When**: `cwf-set-status <file> "In Progress"`
  - **Then**: File updated to `**Status**: In Progress`, exit 0

- **TC-F2**: Idempotent no-op
  - **Given**: A wf file with `**Status**: Finished`
  - **When**: `cwf-set-status <file> "Finished"`
  - **Then**: File unchanged, exit 0

- **TC-F3**: Invalid status value
  - **Given**: A wf file with any status
  - **When**: `cwf-set-status <file> "Done"`
  - **Then**: File unchanged, stderr lists valid values, exit 1

- **TC-F4**: File not found
  - **Given**: A path to a non-existent file
  - **When**: `cwf-set-status /tmp/no-such-file.md "Finished"`
  - **Then**: Stderr reports file not found, exit 1

- **TC-F5**: Missing arguments
  - **Given**: No arguments or only one argument
  - **When**: `cwf-set-status` or `cwf-set-status <file>`
  - **Then**: Stderr prints usage, exit 1

### Non-Functional Test Cases

- **TC-N1**: Security — script permissions and hash
  - **Given**: Script exists in `.cwf/scripts/command-helpers/`
  - **When**: `cwf-manage validate`
  - **Then**: Passes with no violations

## Test Environment

### Setup
- Temp directory with a minimal `implementation-guide/cwf-project.json` containing `workflow.status-values`
- Temp wf file with a `**Status**: Backlog` line

### Test File: `t/cwf-set-status.t`
- Uses `Test::More`, creates temp fixtures per subtest, invokes script as subprocess

## Validation Criteria
- [ ] All TC-F1 through TC-F5 passing
- [ ] TC-N1 passing (`cwf-manage validate` clean)
- [ ] No regressions in existing test suite (`prove t/`)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 101
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
