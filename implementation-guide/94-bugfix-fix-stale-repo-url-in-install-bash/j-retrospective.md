# Fix stale repo URL in install.bash — Retrospective
**Task**: 94 (bugfix)

## Task Reference
- **Task ID**: internal-94
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/94-fix-stale-repo-url-in-install-bash
- **Template Version**: 2.1
- **Retrospective Date**: 2026-02-25

## Executive Summary
- **Duration**: < 1 session (estimated < 1 hour, actual < 1 hour)
- **Scope**: Planned 1 file; audit revealed 2 live stale references (`scripts/install.bash` + `INSTALL.md`)
- **Outcome**: Complete. Both stale URLs corrected; all 5 test cases pass.

## Variance Analysis
### Scope Changes
- **Additions**: `INSTALL.md:12` quick-install curl command was also stale — fixed in same pass
- **Removals**: None
- **Impact**: Minimal — same class of defect, same one-line fix pattern

### Quality Metrics
- **Test Coverage**: 5/5 test cases defined and passing
- **Defect Rate**: 0 regressions

## What Went Well
- Codebase audit caught a second stale reference (`INSTALL.md`) that wasn't in the original scope — the planned audit step did its job
- Clear design upfront (HTTPS, env-var override preserved) meant implementation was unambiguous
- All 5 tests passed first run with no iteration needed

## What Could Be Improved
- Task 91 (`README.md` updates) had already fixed the README install URL but missed `INSTALL.md` and `install.bash`. A codebase-wide grep for `mattkeenan` at that time would have caught both.

## Key Learnings
### Process Learnings
- After any org rename or rebrand task, the smoke-test should be a **codebase-wide grep** for the old name across all user-facing files, not just the files explicitly targeted. This is consistent with the existing MEMORY.md principle: "Rebrands need output-level smoke-test."

## Recommendations
### Future Work
- None. No follow-up tasks required.

## Status
**Status**: Finished
**Next Action**: Task complete — suggest merge to main
**Blockers**: None
**Completion Date**: 2026-02-25

## Archived Materials
- `implementation-guide/94-bugfix-fix-stale-repo-url-in-install-bash/`
