# readme-updates - Testing Plan
**Task**: 91 (bugfix)

## Task Reference
- **Task ID**: internal-91
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/91-readme-updates
- **Template Version**: 2.1

## Goal
Verify all 5 README changes are correct and nothing stale remains.

## Test Strategy
- **Static**: grep-based checks on README.md — no test harness needed for doc edits
- **Regression**: `prove t/` and `cwf-manage validate` (README changes don't touch scripts)

---

## Test Cases

### TC-1: Install URL updated
- **When**: `grep "mattkeenan" README.md`
- **Then**: no matches

### TC-2: v2.1 workflow commands present
- **When**: `grep "cwf-implementation-exec\|cwf-testing-exec" README.md`
- **Then**: both match

### TC-3: No stale v2.0 references
- **When**: `grep "v2\.0" README.md`
- **Then**: no matches

### TC-4: All 10 workflow skills listed
- **When**: `grep "/cwf-" README.md | grep -v "#\|init\|new-task\|subtask\|status\|extract\|config\|security"`
- **Then**: 10 workflow command lines present (task-plan through retrospective)

### TC-5: Task type phase counts correct
- **When**: read Task Types section
- **Then**: feature=10, bugfix=7, hotfix=7, chore=6 phases listed

### TC-6: Semver convention present
- **When**: `grep "task_num" README.md`
- **Then**: match found

### TC-7: `cwf-manage list-releases` mentioned
- **When**: `grep "list-releases" README.md`
- **Then**: match found

### TC-8: GitHub issues URL present
- **When**: `grep "CodingWithFiles/coding-with-files/issues" README.md`
- **Then**: match found

### TC-9: `cwf-manage validate` passes
- **When**: `.cwf/scripts/cwf-manage validate`
- **Then**: OK

### TC-10: `prove t/` — no regressions
- **When**: `prove t/`
- **Then**: all 173 tests pass

---

## Validation Criteria
- [ ] TC-1 through TC-8: all grep checks pass
- [ ] TC-9: validate OK
- [ ] TC-10: prove clean

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 91
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
10/10 TCs passed. TC-3 identified the unplanned Features section fix before it could ship.

## Lessons Learned
Absence-greps (TC-1, TC-3) are as valuable as presence-greps — they catch overlooked stale content.
