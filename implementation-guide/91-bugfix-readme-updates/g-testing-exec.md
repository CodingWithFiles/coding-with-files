# readme-updates - Testing Execution
**Task**: 91 (bugfix)

## Task Reference
- **Task ID**: internal-91
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/91-readme-updates
- **Template Version**: 2.1

## Goal
Execute the 10 test cases from e-testing-plan.md and verify the 6 README.md edits.

## Test Results

| TC | Description | Command | Expected | Status |
|----|-------------|---------|----------|--------|
| TC-1 | Install URL updated | `grep "mattkeenan" README.md` | no matches | PASS |
| TC-2 | v2.1 workflow commands present | `grep "cwf-implementation-exec\|cwf-testing-exec" README.md` | both match | PASS |
| TC-3 | No stale v2.0 references | `grep "v2\.0" README.md` | no matches | PASS |
| TC-4 | All 10 workflow skills listed | grep + exclusion filter | 10 lines | PASS |
| TC-5 | Task type phase counts correct | read Task Types section | feature=10, bugfix=7, hotfix=7, chore=6 | PASS |
| TC-6 | Semver convention present | `grep "task_num" README.md` | match | PASS |
| TC-7 | `cwf-manage list-releases` mentioned | `grep "list-releases" README.md` | match | PASS |
| TC-8 | GitHub issues URL present | `grep "CodingWithFiles/coding-with-files/issues" README.md` | match | PASS |
| TC-9 | `cwf-manage validate` passes | `.cwf/scripts/cwf-manage validate` | OK | PASS |
| TC-10 | `prove t/` — no regressions | `prove t/` | 173 tests pass | PASS |

## Test Failures

None.

## Notes

- TC-4: grep returned 12 lines (10 workflow skills + 2 `cwf-project.json` config references). The 10 workflow skills are all present and correct.
- TC-3 required an unplanned fix to the Features section heading (`v2.0 - Hierarchical Workflow System` → `Hierarchical Workflow System`), documented in f-implementation-exec.md Step 6.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 91
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
All 10 TCs passed first run. Absence-grep pattern (TC-1, TC-3) effectively catches overlooked stale content.
