# Fix stale repo URL in install.bash — Testing Plan
**Task**: 94 (bugfix)

## Task Reference
- **Task ID**: internal-94
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/94-fix-stale-repo-url-in-install-bash
- **Template Version**: 2.1

## Test Strategy
Static verification (grep) + URL reachability check. No unit tests required — the change is a string literal with no logic.

## Test Cases

### TC-1: Primary fix applied
- **Given**: `scripts/install.bash` has been edited
- **When**: Grep for `mattkeenan` in `scripts/install.bash`
- **Then**: Zero matches

### TC-2: Correct URL present
- **Given**: `scripts/install.bash` has been edited
- **When**: Grep for `CodingWithFiles/coding-with-files.git` in `scripts/install.bash`
- **Then**: Exactly one match on the `CWF_SOURCE` line

### TC-3: Codebase-wide audit
- **Given**: Full repo checkout
- **When**: `grep -r mattkeenan .` (excluding `.git`)
- **Then**: Zero matches anywhere in the codebase

### TC-4: URL reachable
- **Given**: Network access available
- **When**: `curl -sI https://github.com/CodingWithFiles/coding-with-files.git`
- **Then**: HTTP 200 or 301 (not 404)

### TC-5: Env-var override still works
- **Given**: Corrected `install.bash`
- **When**: Read the `CWF_SOURCE` variable declaration
- **Then**: `${CWF_SOURCE:-...}` pattern is intact (override remains possible)

## Validation Criteria
- [ ] TC-1 passes — no `mattkeenan` in install.bash
- [ ] TC-2 passes — correct URL present
- [ ] TC-3 passes — no `mattkeenan` anywhere in repo
- [ ] TC-4 passes — URL resolves
- [ ] TC-5 passes — env-var override pattern preserved

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 94
**Blockers**: None

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
