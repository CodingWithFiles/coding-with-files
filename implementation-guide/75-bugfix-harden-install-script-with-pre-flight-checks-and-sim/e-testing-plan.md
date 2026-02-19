# Harden Install Script with Pre-Flight Checks and Simplify Bootstrap - Testing Plan
**Task**: 75 (bugfix)

## Task Reference
- **Task ID**: internal-75
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/75-harden-install-script-preflight-checks
- **Template Version**: 2.1

## Goal
Verify that `install.bash` correctly rejects repos with no commits (subtree method only)
and that README.md/INSTALL.md show clean one-liner bootstrap blocks.

## Test Strategy
- **Manual functional**: Source `install.bash` functions directly to test guard clause
  without running the full install; inspect docs for correct content
- **Code review**: Confirm guard is method-conditional, exit code and message correct
- **Regression**: `cwf-manage validate` passes; copy method unaffected

## Test Cases

### TC-1: Guard fires on empty repo (subtree method)
- **Given**: Fix applied; temp dir with `git init` but no commits; `CWF_METHOD=subtree`
- **When**: Source `install.bash` and call `check_prerequisites()` from that dir
- **Then**: Exits non-zero; stderr contains "no commits" and "initial commit"

### TC-2: Guard does not fire when repo has commits (subtree method)
- **Given**: Fix applied; temp dir with `git init` + one commit; `CWF_METHOD=subtree`
- **When**: Source `install.bash` and call `check_prerequisites()` from that dir
  (stop before cloning — stop after prerequisites pass)
- **Then**: `check_prerequisites` returns 0; no "no commits" message on stderr

### TC-3: Guard does not fire for copy method on empty repo
- **Given**: Fix applied; temp dir with `git init` but no commits; `CWF_METHOD=copy`
- **When**: Source `install.bash` and call `check_prerequisites()` from that dir
- **Then**: `check_prerequisites` returns 0; guard is skipped entirely

### TC-4: README.md one-liner block correct
- **Given**: Fix applied
- **When**: Read README.md Installation section
- **Then**: No 4-line sparse-checkout block; contains `git archive --remote` one-liner
  for non-GitHub and `curl` one-liner for GitHub

### TC-5: INSTALL.md one-liner block correct
- **Given**: Fix applied
- **When**: Read INSTALL.md Quick Install section
- **Then**: No sparse-checkout block; `### GitHub` section has `curl` one-liner;
  `### GitLab, Gitea, Forgejo, self-hosted` section has `git archive --remote` one-liner

### TC-6: `cwf-manage validate` passes
- **Given**: Security hash updated after fix
- **When**: `.cwf/scripts/cwf-manage validate`
- **Then**: `validate: OK`; exit 0

## Test Environment
- Bash sourcing of `install.bash` with a stub `die()` function to capture exit
- Temp git repos created with `mktemp -d` + `git init`
- For TC-2: one empty commit via `git commit --allow-empty -m "init"`

## Validation Criteria
- [ ] TC-1: Guard fires correctly on empty repo (subtree)
- [ ] TC-2: Guard does not fire when commits exist (subtree)
- [ ] TC-3: Guard does not fire for copy method
- [ ] TC-4: README.md has correct one-liner blocks
- [ ] TC-5: INSTALL.md has correct one-liner blocks
- [ ] TC-6: `cwf-manage validate` passes

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 75
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 6 test cases passed first time. Subshell sourcing of install.bash was an effective
test method for the guard clause.

## Lessons Learned
Sourcing a bash script in a subshell and calling individual functions is a clean way
to unit-test shell functions without running the full network-dependent workflow.
