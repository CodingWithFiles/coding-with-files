# Fix stale repo URL in install.bash — Implementation Execution
**Task**: 94 (bugfix)

## Task Reference
- **Task ID**: internal-94
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/94-fix-stale-repo-url-in-install-bash
- **Template Version**: 2.1

## Actual Results

### Step 1: Codebase audit
- **Planned**: Grep for all `mattkeenan` occurrences
- **Actual**: Found 2 live stale references beyond task docs and historical wf records:
  - `scripts/install.bash:24` — `CWF_SOURCE` default (primary fix)
  - `INSTALL.md:12` — quick-install curl command (additional fix)
- **Deviations**: Plan identified one file; audit revealed a second (`INSTALL.md`). Fixed both.

### Step 2: Fix `scripts/install.bash:24`
- **Planned**: Replace `mattkeenan/coding-with-files.git` with `CodingWithFiles/coding-with-files.git`
- **Actual**: Done. `readonly CWF_SOURCE` now points to `CodingWithFiles`.

### Step 3: Fix `INSTALL.md:12`
- **Planned**: Not in original plan (discovered by audit)
- **Actual**: Replaced `raw.githubusercontent.com/mattkeenan/...` with `raw.githubusercontent.com/CodingWithFiles/...`
- **Deviation**: Scope expansion — justified, same class of defect, same fix.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met (including "no other files")
- [x] Design guidance in c-design-plan.md followed (HTTPS, env-var override preserved)
- [x] No planned work deferred

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec 94
**Blockers**: None

## Lessons Learned
*To be captured during retrospective*
