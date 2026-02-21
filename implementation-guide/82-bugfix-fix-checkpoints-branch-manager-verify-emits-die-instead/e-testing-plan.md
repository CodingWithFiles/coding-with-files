# Fix checkpoints-branch-manager verify emits die instead of warn on SIGPIPE - Testing Plan
**Task**: 82 (bugfix)

## Task Reference
- **Task ID**: internal-82
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/82-fix-checkpoints-branch-manager-verify-emits-die-instead
- **Template Version**: 2.1

## Goal
Validate that `verify_checkpoints_branch()` now emits a warning (not a fatal exception) on failure, that the exit code is still non-zero, and that the happy path is unaffected.

## Test Strategy
### Test Levels
- **Manual integration**: invoke the script directly against real git state — sufficient for a one-line change
- No unit test harness exists for helper scripts; manual CLI testing is the established pattern

### Test Coverage Targets
- **Critical Paths**: 100% — error path and success path both exercised
- **Regression**: `create` and `show-history` subcommands verified unaffected
- **Security**: `cwf-manage validate` and `/cwf-security-check verify` must pass after hash update

## Test Cases
### Functional Test Cases

- **TC-1**: verify on a branch with a checkpoints branch (happy path)
  - **Given**: On a branch that has a `<branch>-checkpoints` branch
  - **When**: `.cwf/scripts/command-helpers/checkpoints-branch-manager verify`
  - **Then**: Exits 0, prints commit log to stdout, no warning emitted

- **TC-2**: verify on a branch without a checkpoints branch (error path)
  - **Given**: On a branch that has NO `<branch>-checkpoints` branch
  - **When**: `.cwf/scripts/command-helpers/checkpoints-branch-manager verify`
  - **Then**: Exits non-zero, emits `warning: checkpoints branch not found` to stderr, does **not** throw a fatal Perl exception (no `Died at …` stack trace)

- **TC-3**: create subcommand unaffected
  - **Given**: On a branch without a checkpoints branch
  - **When**: `.cwf/scripts/command-helpers/checkpoints-branch-manager create`
  - **Then**: Creates branch, exits 0 — same behaviour as before

- **TC-4**: security hash valid after change
  - **Given**: Script edited and hash updated in `script-hashes.json`
  - **When**: `perl -I.cwf/lib .cwf/scripts/cwf-manage validate`
  - **Then**: Exits 0 with `[CWF] validate: OK`

### Non-Functional Test Cases
- **Usability**: TC-2 error message says "warning" not "error", making it clear the caller can decide whether to act on it

## Test Environment
### Setup Requirements
- Existing git repo with at least one branch that has a checkpoints branch (current task branch satisfies TC-1 after `create`)
- A branch without a checkpoints branch for TC-2 (use a temp branch or the main branch)

### Automation
- No automated harness; manual execution and visual inspection

## Validation Criteria
- [ ] TC-1 passes: exits 0, log printed, no warning
- [ ] TC-2 passes: exits non-zero, warning on stderr, no Perl exception trace
- [ ] TC-3 passes: create still works
- [ ] TC-4 passes: `cwf-manage validate` OK

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 82
**Blockers**: None identified

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
