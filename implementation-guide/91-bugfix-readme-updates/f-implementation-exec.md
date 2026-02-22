# readme-updates - Implementation Execution
**Task**: 91 (bugfix)

## Task Reference
- **Task ID**: internal-91
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/91-readme-updates
- **Template Version**: 2.1

## Goal
Execute the 5 planned README.md edits per d-implementation-plan.md.

## Implementation Steps

### Step 1: Fix install URL
- **Planned**: Replace `mattkeenan/coding-with-files` with `CodingWithFiles/coding-with-files` in GitHub curl command
- **Actual**: Applied. Line 59 updated.
- **Deviations**: None

### Step 2: Replace `## Commands` section
- **Planned**: Remove v2.0 labels, add `/cwf-implementation-exec` and `/cwf-testing-exec`, keep Core/Utility subsections
- **Actual**: Applied. Full 10-command v2.1 list with "plan first, execute separately" note added.
- **Deviations**: None

### Step 3: Replace `## Task Types` section
- **Planned**: Accurate v2.1 phase counts with feature/bugfix/hotfix/chore sequences; note about planning+execution split
- **Actual**: Applied. Counts: feature=10, bugfix=7, hotfix=7, chore=6; phase sequences listed for each.
- **Deviations**: None

### Step 4: Replace `## Version Information` section
- **Planned**: `v{major}.{minor}.{task_num}` convention; `cwf-manage list-releases`; keep `git describe`
- **Actual**: Applied. All three elements present.
- **Deviations**: None

### Step 5: Replace support section body
- **Planned**: Replace generic `cwf-project.json` reference with direct GitHub issues URL
- **Actual**: Applied. URL: `https://github.com/CodingWithFiles/coding-with-files/issues`
- **Deviations**: None

### Step 6: Fix stale v2.0 reference in Features section (discovered during TC-3)
- **Planned**: Not in original plan — found during TC-3 grep check
- **Actual**: Changed `### v2.0 - Hierarchical Workflow System` → `### Hierarchical Workflow System`; `8-Step Workflow` → `10-Phase Workflow`; `Commands` → `Skills` in that section's bullet
- **Deviations**: Unplanned but necessary to pass TC-3 (`grep "v2\.0" README.md` → no matches)

## Blockers Encountered

None.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met
- [x] All design guidance in c-design-plan.md followed
- [x] No planned work deferred without user approval

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec 91
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
TC-3 caught the unplanned Features section fix. "Should be absent" greps should be run at design time.
