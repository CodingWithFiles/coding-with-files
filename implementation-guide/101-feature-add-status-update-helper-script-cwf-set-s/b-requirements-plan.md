# Add Status Update Helper Script (cwf-set-status) - Requirements
**Task**: 101 (feature)

## Task Reference
- **Task ID**: internal-101
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/101-add-status-update-helper-script-cwf-set-s
- **Template Version**: 2.1

## Goal
Define functional and non-functional specifications for Add Status Update Helper Script (cwf-set-status).

## Functional Requirements

### Core Features
- **FR1**: Script accepts `(file-path, new-status)` as positional arguments and updates the `**Status**: <value>` line in the target file in-place
- **FR2**: Script reads valid status values from `cwf-project.json` (`workflow.status-values` key) — not hardcoded
- **FR3**: Script rejects invalid status values with non-zero exit and error message listing all valid options
- **FR4**: Script is idempotent — setting a status that already matches produces no file modification and exits 0

### User Stories
- **As a** workflow skill **I want** a single script call to update a wf file's status **so that** I don't perform error-prone regex replacements by hand
- **As a** future `cwf-checkpoint-commit` script **I want** `cwf-set-status` as a building block **so that** the checkpoint procedure is composable

## Non-Functional Requirements

### Usability (NFR1)
- Error messages include the invalid value, the file path, and the full list of valid status values

### Maintainability (NFR2)
- Single-file script, no new library modules
- Reads config with core `JSON::PP` via relative path (matching `cwf-load-project-config` convention)

### Security (NFR3)
- File permissions: 0755, SHA256 tracked in `script-hashes.json`
- No shell metacharacter exposure — arguments used as literals only

### Reliability (NFR4)
- Exit codes: 0 = success, 1 = any failure (stderr explains what went wrong)

## Acceptance Criteria
- [ ] AC1: `cwf-set-status path/to/f-implementation-exec.md "In Progress"` updates the status field, exits 0
- [ ] AC2: `cwf-set-status path/to/file.md "Done"` exits 1 with error listing valid values
- [ ] AC3: `cwf-set-status path/to/file.md "Finished"` when already Finished exits 0 with no file modification
- [ ] AC4: `cwf-manage validate` passes after script is added to the repo

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 101
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
