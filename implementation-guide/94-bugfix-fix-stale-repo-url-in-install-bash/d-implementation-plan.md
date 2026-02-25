# Fix stale repo URL in install.bash — Implementation Plan
**Task**: 94 (bugfix)

## Task Reference
- **Task ID**: internal-94
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/94-fix-stale-repo-url-in-install-bash
- **Template Version**: 2.1

## Files to Modify
### Primary Changes
- `scripts/install.bash:24` — Replace `mattkeenan/coding-with-files.git` with `CodingWithFiles/coding-with-files.git`

## Implementation Steps
- [ ] Grep codebase for all `mattkeenan` occurrences to establish full audit scope
- [ ] Apply the one-line fix in `scripts/install.bash`
- [ ] Fix any other `mattkeenan` references found in the audit
- [ ] Verify corrected URL is reachable (`curl -sI` or `git ls-remote`)

## Code Changes
### Before
```bash
readonly CWF_SOURCE="${CWF_SOURCE:-https://github.com/mattkeenan/coding-with-files.git}"
```

### After
```bash
readonly CWF_SOURCE="${CWF_SOURCE:-https://github.com/CodingWithFiles/coding-with-files.git}"
```

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 94
**Blockers**: None

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
