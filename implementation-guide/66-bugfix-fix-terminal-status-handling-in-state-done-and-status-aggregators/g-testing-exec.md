# Fix terminal status handling in state_done and status aggregators - Testing Execution
**Task**: 66 (bugfix)

## Task Reference
- **Task ID**: internal-66
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/66-fix-terminal-status-handling-in-state-done-and-status-aggregators
- **Template Version**: 2.1

## Test Results

| ID | Test | Result | Notes |
|----|------|--------|-------|
| TC-1 | `status_percent('Skipped')` = 100 | PASS | Required fix to `cwf-project.json` — see below |
| TC-2 | `status_percent('Cancelled')` = 0 (unchanged) | PASS | |
| TC-3 | `state_done(all Cancelled)` = 100 | PASS | |
| TC-4 | `state_done(all Skipped)` = 100 | PASS | |
| TC-5 | `state_done(Finished+Cancelled+Skipped)` = 100 | PASS | |
| TC-6 | `state_done(Finished+In Progress)` = 25 | PASS | No regression |
| TC-7 | `state_done(all Blocked)` = 15 | PASS | No regression |
| TC-8 | `state_achievable(all Cancelled)` = 0 via CLIFF | PASS | |
| TC-9 | `state_achievable(all Blocked)` > 0 via DORMANT | PASS | Returns 4 |
| TC-10 | `state_achievable(active task)` > 0 | PASS | Returns 25 |
| TC-11 | Task 11 (all Cancelled) shows 100% in aggregator | PASS | `* 11 ... 100%` |
| TC-12 | Task 66 (active) shows non-100% in aggregator | PASS | `+ 66 ... 25%` |
| TC-13 | `cwf-manage validate` exits 0 | PASS | |
| TC-14 | `perlcritic --stern TaskState.pm` passes | PASS | |

## Test Failures
None. TC-1 initially failed — see deviation below.

## Deviation: `cwf-project.json` had `"Skipped": null`

TC-1 failed on first run: `status_percent('Skipped')` returned undef. Root cause: `cwf-project.json` has a `workflow.status-values` map that overrides `%DEFAULT_STATUS_MAP`, and it had `"Skipped": null`. The fix to `%DEFAULT_STATUS_MAP` in `TaskState.pm` alone was insufficient — the config is the live source of truth.

**Fix**: Updated `cwf-project.json` `"Skipped": null` → `"Skipped": 100`. This was a missing piece not identified during implementation planning but consistent with the design intent.

## Coverage
14/14 test cases pass. All new code paths covered:
- `_is_closed` exercised via TC-3/4/5/8
- Blocked-as-DORMANT path exercised via TC-9
- No-regression cases covered by TC-6/7/10

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 66
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
14/14 test cases pass.

## Lessons Learned
See j-retrospective.md.
