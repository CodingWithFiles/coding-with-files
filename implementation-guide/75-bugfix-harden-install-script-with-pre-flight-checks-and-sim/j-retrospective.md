# Harden Install Script with Pre-Flight Checks and Simplify Bootstrap - Retrospective
**Task**: 75 (bugfix)

## Task Reference
- **Task ID**: internal-75
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/75-harden-install-script-preflight-checks
- **Template Version**: 2.1
- **Retrospective Date**: 2026-02-19

## Executive Summary
- **Duration**: <1 session (estimated: trivial <1 session, variance: 0%)
- **Scope**: Exactly as planned — one guard clause, two doc edits
- **Outcome**: Full success. Empty-repo installs now fail with a clear message;
  bootstrap docs are clean one-liners.

## Variance Analysis

### Time and Effort
- **Estimated**: Trivial (<1 session)
- **Actual**: <1 session
- **Variance**: None

### Scope Changes
- **Additions**: None
- **Removals**: Security hash update (Step 4) — `install.bash` is not tracked in
  `script-hashes.json` (it lives in `scripts/`, not `.cwf/scripts/`). Step was N/A.
- **Impact**: Minor — one less step, validate still passes cleanly.

### Quality Metrics
- **Test Coverage**: 6/6 planned test cases executed and passed
- **Defect Rate**: 0 post-fix
- **Performance**: N/A — string comparison and shell check only

## What Went Well
- Root cause was fully understood before implementation — no surprises
- Guard clause placement was obvious from reading the function structure
- Testing via `source install.bash` + subshell was clean and reliable
- TC-2 and TC-3 naturally exercised the "passes guard, proceeds to clone" path

## What Could Be Improved
- Implementation plan included a hash-update step (Step 4) without first verifying
  whether `install.bash` is actually tracked. A quick grep before planning would have
  avoided the N/A deviation. For future tasks touching files in `scripts/` vs `.cwf/scripts/`,
  check hash tracking upfront.

## Key Learnings

### Technical Insights
- `install.bash` lives in `scripts/` and is intentionally outside the CWF security
  hash registry — only `.cwf/` scripts are tracked. This is correct by design (the
  install script is the bootstrap, not part of the installed system).
- `git rev-parse HEAD` is the idiomatic check for "repo has at least one commit" —
  fast, exits non-zero cleanly, and consistent with other git-rev-parse usage in the script.
- Sourcing `install.bash` in a subshell is an effective way to unit-test individual
  bash functions without mocking the entire network stack.

### Process Learnings
- When an implementation plan step involves a hash registry update, verify the file is
  actually tracked before writing the step.

## Recommendations

### Future Work
- The `git archive --remote` one-liner in docs uses `<cwf-repo-url>` as a placeholder.
  If/when the CWF repo URL is finalised, consider making this a concrete example URL
  (like the GitHub curl one-liner already is).

## Status
**Status**: Finished
**Next Action**: Squash and close
**Blockers**: None
**Completion Date**: 2026-02-19
**Sign-off**: Task 75 complete

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Implementation: `scripts/install.bash` (lines 64-70), `README.md`, `INSTALL.md`
- Checkpoint commits: `bugfix/75-harden-install-script-preflight-checks-checkpoints`
