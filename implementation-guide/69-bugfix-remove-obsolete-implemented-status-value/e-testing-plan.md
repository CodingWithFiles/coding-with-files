# Remove obsolete Implemented status value - Testing Plan
**Task**: 69 (bugfix)

## Task Reference
- **Task ID**: internal-69
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/69-remove-obsolete-implemented-status-value
- **Template Version**: 2.1

## Goal
Verify `Implemented` is fully removed and the system behaves correctly without it.

## Test Strategy
Mix of grep verifications (absence checks) and runtime behavioural tests via `status-aggregator-v2.1` and `cwf-manage validate`. No unit test framework — Perl module tested via existing aggregator tooling.

## Test Cases

| ID | Test | Method | Expected |
|----|------|--------|----------|
| TC-1 | `Implemented` absent from cwf-project.json | `grep "Implemented" implementation-guide/cwf-project.json` | No matches |
| TC-2 | `Implemented` absent from TaskState.pm | `grep "Implemented" .cwf/lib/CWF/TaskState.pm` | No matches |
| TC-3 | `Implemented` absent from workflow-steps.md | `grep "Implemented" .cwf/docs/workflow/workflow-steps.md` | No matches |
| TC-4 | `status_percent('Implemented')` returns 0 (unknown, not old 50) | `perl -I.cwf/lib -MCWF::TaskState=status_percent -e 'my $v=status_percent("Implemented"); print $v==0 ? "PASS" : "FAIL ($v)"'` | `PASS` |
| TC-5 | `status_percent('Finished')` still returns 100 | `perl -I.cwf/lib -MCWF::TaskState=status_percent -e 'print status_percent("Finished")'` | `100` |
| TC-6 | `status_percent('Testing')` still returns 75 | `perl -I.cwf/lib -MCWF::TaskState=status_percent -e 'print status_percent("Testing")'` | `75` |
| TC-7 | `cwf-manage validate` exits 0 (hashes updated) | `perl -I.cwf/lib .cwf/scripts/cwf-manage validate` | `OK` |
| TC-8 | BACKLOG workaround item retired | `grep "^## Task.*Status Field Review" BACKLOG.md` | No matches |

## Validation Criteria
- All 8 tests pass
- No `Implemented` references remain in config, library, or docs
- All other status values continue to function correctly

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 69
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during retrospective*
