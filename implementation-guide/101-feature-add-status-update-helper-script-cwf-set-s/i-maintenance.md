# Add Status Update Helper Script (cwf-set-status) - Maintenance
**Task**: 101 (feature)

## Task Reference
- **Task ID**: internal-101
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/101-add-status-update-helper-script-cwf-set-s
- **Template Version**: 2.1

## Goal
Define ongoing maintenance, monitoring, and support requirements for Add Status Update Helper Script (cwf-set-status).

## Scheduled Maintenance

NONE — no scheduled maintenance required. The script and library functions are stateless; `cwf-manage validate` covers hash integrity on every commit.

## Reactive Maintenance

- **IF** a new status value is added to `cwf-project.json` **THEN** no script changes needed (read from config at runtime)
- **IF** the `## Status` section format changes in wf templates **THEN** update `_find_status_line` in `CWF::TaskState` (single location)
- **IF** `cwf-manage validate` reports hash mismatch for `cwf-set-status` **THEN** recompute: `sha256sum .cwf/scripts/command-helpers/cwf-set-status` and update `script-hashes.json`

## Deprecation Trigger

Remove if CWF moves away from markdown-based status tracking.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 101
**Blockers**: None
