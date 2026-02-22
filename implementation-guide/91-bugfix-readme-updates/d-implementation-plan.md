# readme-updates - Implementation Plan
**Task**: 91 (bugfix)

## Task Reference
- **Task ID**: internal-91
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/91-readme-updates
- **Template Version**: 2.1

## Goal
Apply 5 targeted edits to README.md per c-design-plan.md. Single file, no logic changes.

## Files to Modify
- `README.md` — all 5 changes

## Implementation Steps

### Step 1: Fix install URL (line ~59)
- [ ] Replace `mattkeenan/coding-with-files` with `CodingWithFiles/coding-with-files`
  in the GitHub curl install command

### Step 2: Replace `## Commands` section (lines ~70–101)
- [ ] Remove v2.0 labels and "Breaking change" callouts
- [ ] Replace workflow command list with full 10-command v2.1 list including
  `/cwf-implementation-exec` and `/cwf-testing-exec`
- [ ] Keep Core and Utility command subsections

### Step 3: Replace `## Task Types` section (lines ~104–121)
- [ ] Replace old phase counts with authoritative v2.1 phase lists from
  `.cwf/templates/<type>/`
- [ ] Add note that phases split into planning + execution steps
- [ ] Show phase sequence for each type (feature/bugfix/hotfix/chore)

### Step 4: Replace `## Version Information` section (lines ~181–189)
- [ ] Replace `git describe` format description with `v{major}.{minor}.{task_num}` convention
- [ ] Add `cwf-manage list-releases` for upgrade discovery
- [ ] Keep `git describe` as working-tree version command

### Step 5: Replace support section body (line ~210)
- [ ] Replace generic `cwf-project.json` reference with direct GitHub issues URL

## Validation Criteria
- `grep "mattkeenan" README.md` → no matches
- `grep "v2\.0" README.md` → no matches
- `grep "cwf-implementation-exec\|cwf-testing-exec" README.md` → matches
- `grep "CodingWithFiles/coding-with-files/issues" README.md` → match
- `grep "task_num" README.md` → match
- `cwf-manage validate` → OK

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 91
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
5 planned steps executed plus 1 unplanned fix (Features section v2.0 heading). All validation criteria met.

## Lessons Learned
No process issues in execution. Unplanned fix was minor and self-contained.
