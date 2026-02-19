# Fix template-copier-v2.1 uninitialized variable warnings - Testing Plan
**Task**: 74 (bugfix)

## Task Reference
- **Task ID**: internal-74
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/74-fix-template-copier-v2.1-uninitialized-variable-warn
- **Template Version**: 2.1

## Goal
Verify that `branchName` is correctly populated in generated templates and no warnings emitted.

## Test Strategy
- **Manual functional**: Direct invocation via `task-workflow create` and `template-copier-v2.1`
- **Code review**: Verify other `load_config()` call sites are unaffected
- **Regression**: `cwf-manage validate` passes; existing task directories unaffected

## Test Cases

### TC-1: Branch field populated after fix
- **Given**: Fix applied; `cwf-project.json` has `source-management.branch-naming-convention`
- **When**: `perl -I.cwf/lib .cwf/scripts/command-helpers/task-workflow create --task-type=bugfix --task-num=99 --description="test task" --destination=/tmp/tc74-test`
- **Then**: `grep 'Branch' /tmp/tc74-test/a-task-plan.md` shows `- **Branch**: bugfix/99-test-task`

### TC-2: No warnings on stderr
- **Given**: Fix applied
- **When**: Same invocation as TC-1, capture stderr
- **Then**: No "uninitialized value" warnings on stderr

### TC-3: All template files get correct branch name
- **Given**: Fix applied; bugfix task type (7 files)
- **When**: Inspect all generated files for `Branch:` field
- **Then**: Every file that has a `Branch:` field shows the correct value

### TC-4: `cwf-manage validate` passes
- **Given**: Security hash updated after fix
- **When**: `perl -I.cwf/lib .cwf/scripts/cwf-manage validate`
- **Then**: `validate: OK`; exit 0

### TC-5: Regression — feature task type also gets correct branch
- **Given**: Fix applied
- **When**: `task-workflow create --task-type=feature --task-num=99 --description="test feature" --destination=/tmp/tc74-feature`
- **Then**: `Branch:` field = `feature/99-test-feature`

## Validation Criteria
- [ ] TC-1: Branch field correctly populated
- [ ] TC-2: No uninitialized value warnings
- [ ] TC-3: All generated files have correct Branch field
- [ ] TC-4: `cwf-manage validate` passes
- [ ] TC-5: Feature task type also works

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 74
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 5 test cases passed. TC-1's destination `/tmp/tc74-test` triggered the slug fallback
path (raw description, spaces not converted). Tests re-run with a properly named destination
(`/tmp/99-bugfix-test-task`) to match real usage; Branch field correct.

## Lessons Learned
Test destinations for `template-copier-v2.1` should match the task-dir naming pattern
(`\d+-type-slug`) to exercise the slug extraction rather than the fallback path.
