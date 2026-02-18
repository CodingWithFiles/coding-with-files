# Remove v1.0 category subdirectories from cwf-init - Testing Plan
**Task**: 68 (hotfix)

## Task Reference
- **Task ID**: internal-68
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/68-remove-v1-0-category-subdirectories-from-cwf-init
- **Template Version**: 2.1

## Goal
Verify that the category-subdir instruction is gone from cwf-init, README reflects v2.1 layout, and BACKLOG entries are retired.

## Test Strategy
Documentation-only change — all tests are grep/read verifications. No runtime behaviour changes; no performance or security concerns.

## Test Cases

| ID | Test | Method |
|----|------|--------|
| TC-1 | `cwf-init/SKILL.md` has no category subdir bullet | `grep -c "Category subdirectories" .claude/skills/cwf-init/SKILL.md` → 0 |
| TC-2 | README.md Project Structure shows v2.1 number-prefixed tasks | `grep -c "feature/" README.md` in project-structure block → 0 |
| TC-3 | Both BACKLOG entries retired | `grep "^## Task.*Category Subdirector" BACKLOG.md` → no matches (HTML comment is acceptable) |
| TC-4 | `cwf-manage validate` exits 0 | `perl -I.cwf/lib .cwf/scripts/cwf-manage validate` |

## Validation Criteria
- All 4 test cases pass
- No remaining v1.0 category-subdir references in SKILL.md or README.md Project Structure

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 68
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during retrospective*
