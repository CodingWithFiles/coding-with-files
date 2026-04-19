# Build Stale Status Detector Stop Hook - Testing Plan
**Task**: 104 (feature)

## Task Reference
- **Task ID**: internal-104
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/104-build-stale-status-detector-stop-hook
- **Template Version**: 2.1

## Goal
Define test cases for the stale status detector script and hook registration.

## Test Strategy
Manual pipe-testing of the script with controlled git state. No automated test framework — the script is a ~30-line bash pipeline. Tests simulate the hook's stdin and verify stdout.

## Test Cases

| ID | Description | Method | Criterion |
|----|-------------|--------|-----------|
| TC-1 | No wf files in diff → no output | Clean state or only non-wf files modified | Exit 0, empty stdout |
| TC-2 | Stale "Backlog" status → valid JSON warning | Modify wf file without changing status, pipe to `jq -e .` | Exit 0, JSON with `systemMessage` containing file name |
| TC-3 | Updated status → no output | Modify wf file and set status to "In Progress" | Exit 0, empty stdout |
| TC-4 | Multiple stale files → multiple warnings | Modify 2+ wf files without updating status | `systemMessage` contains both file names |
| TC-5 | Non-git directory → exit 0 | Run from /tmp | Exit 0, no output |
| TC-6 | Hook registered in settings | Read `.claude/settings.local.json` | `hooks.Stop` entry with correct command path |
| TC-S1 | `cwf-manage validate` clean | Run validate | Exit 0 |

## Validation Criteria
- [ ] All 7 test cases pass
- [ ] Script permissions are u+rx

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 104
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
