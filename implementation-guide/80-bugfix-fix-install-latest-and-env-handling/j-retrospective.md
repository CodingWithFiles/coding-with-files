# fix install script latest tag resolution and local dev UX - Retrospective
**Task**: 80 (bugfix)

## Task Reference
- **Task ID**: internal-80
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/80-fix-install-latest-and-env-handling
- **Template Version**: 2.1
- **Retrospective Date**: 2026-02-21

## Executive Summary
- **Duration**: <1 session (estimated: <1 session — on target)
- **Scope**: Exactly as planned — 4-line bash guard + 16-line INSTALL.md section
- **Outcome**: Complete success. The original bug (fatal subtree error when installing
  from file:// with no CWF_REF) is fixed and verified by live end-to-end install.

## Variance Analysis
### Time and Effort
- **Estimated**: <1 session
- **Actual**: <1 session
- **Variance**: 0% — straightforward, well-scoped fix

### Scope Changes
- **Additions**: None
- **Removals**: None
- **Impact**: None

### Quality Metrics
- **Test Coverage**: 5/5 TCs, including 2 live end-to-end installs into temp repos
- **Defect Rate**: 0
- **Performance**: N/A

## What Went Well
- Root cause was clear from the bug report: `resolve_ref()` has no source-type awareness
- The fix location and approach were obvious once the root cause was identified
- Live end-to-end TC-1 reproduced the original failure scenario exactly and confirmed
  the fix — much stronger signal than a grep check alone
- The before/after diff in d-implementation-plan.md made execution mechanical

## What Could Be Improved
- The `subtree split` progress output (`1/131 (0) [0]...`) is very noisy in the logs.
  This is a pre-existing cosmetic issue in install.bash, not introduced here.

## Key Learnings
### Technical Insights
- Bash `[[ "$VAR" == prefix* ]]` glob matching is clean for URL scheme detection —
  no need for `grep` or `=~` regex
- `CWF_SOURCE` is set `readonly` at script top, so it's available throughout all
  functions without passing as an argument

### Process Learnings
- For install script bugs, a live end-to-end integration TC in a fresh temp repo is
  the most valuable test: it catches the full install path including git operations
  that static checks cannot simulate
- Including exact before/after diffs in the implementation plan pays off — execution
  is a direct apply rather than an interpretation exercise

### Risk Mitigation Strategies
- The guard condition `"$CWF_SOURCE" == file://*` is intentionally narrow: only
  matches `file://` scheme, leaving `https://`, `git://`, `ssh://` unaffected.
  Verified via code inspection (TC-3) before running live tests.

## Recommendations
### Process Improvements
- For install script tasks, always include at least one live end-to-end TC with a
  temp repo — add this to the testing plan template notes

### Future Work
- The `subtree split` progress output is noisy; a follow-up could suppress or redirect
  it (Low priority — cosmetic only)

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None
**Completion Date**: 2026-02-21
**Sign-off**: CWF workflow (task 80)

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: `implementation-guide/80-bugfix-.../a-task-plan.md`
- Implementation plan: `implementation-guide/80-bugfix-.../d-implementation-plan.md`
- Testing plan: `implementation-guide/80-bugfix-.../e-testing-plan.md`
- Implementation execution: `implementation-guide/80-bugfix-.../f-implementation-exec.md`
- Testing execution: `implementation-guide/80-bugfix-.../g-testing-exec.md`
