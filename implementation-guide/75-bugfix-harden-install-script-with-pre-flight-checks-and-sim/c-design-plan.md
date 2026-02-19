# Harden Install Script with Pre-Flight Checks and Simplify Bootstrap - Design
**Task**: 75 (bugfix)

## Task Reference
- **Task ID**: internal-75
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/75-harden-install-script-preflight-checks
- **Template Version**: 2.1

## Goal
Document the minimal fixes for the two issues identified in Task 63 external testing.

## Key Decisions

### Fix 1: Initial-commit guard in `check_prerequisites()`

- **Placement**: After the "Must be at git root" check, before the "Check for existing
  install" block (line ~64). Only applies to `subtree` method — `copy` method makes
  no git commits on the target repo and works fine without an initial commit.
- **Detection**: `git rev-parse HEAD` exits non-zero when no commits exist. More
  reliable than `git log --oneline | head -1` which can be confused by encoding.
  Alternatively: `git rev-list --count HEAD 2>/dev/null` returns 0 or fails.
- **Chosen command**: `git rev-parse HEAD >/dev/null 2>&1` — standard, fast,
  already used elsewhere in the CWF ecosystem.
- **Guard condition**: Only emit error when `CWF_METHOD == subtree` (the default).
  `copy` method is unaffected.
- **Error message**: `"Repository has no commits. Create an initial commit before
  installing CWF (subtree method requires at least one commit)."`
- **Exit code**: `exit 1` (consistent with other `die` calls in the script).

### Fix 2: Bootstrap one-liner replacement in README.md and INSTALL.md

- **Current**: 4-line sparse-checkout sequence (clone, sparse-checkout set, run, rm):
  ```
  git clone --depth 1 --filter=blob:none --sparse <url> /tmp/cwf-bootstrap
  git -C /tmp/cwf-bootstrap sparse-checkout set scripts
  CWF_SOURCE=<url> bash /tmp/cwf-bootstrap/scripts/install.bash
  rm -rf /tmp/cwf-bootstrap
  ```
- **Replacement** (non-GitHub hosts):
  ```
  git archive --remote=<cwf-repo-url> HEAD scripts/install.bash | tar -xO | bash
  ```
  Works for GitLab, Gitea, Forgejo, and self-hosted git servers. Does not require
  a temporary directory or cleanup.
- **GitHub**: `git archive --remote` is blocked by GitHub. Keep existing `curl` one-liner.
- **Structure**: Two clearly labelled blocks — "GitHub" and "Other git hosts" — so
  readers can find the right one-liner for their host.

### No changes to `install_copy()`
`copy` method does no `git subtree add` and does not require an initial commit.
The guard is conditional on `CWF_METHOD == subtree`.

## Decomposition Check
- [ ] **Time**: No
- [ ] **People**: No
- [ ] **Complexity**: No — two independent line-level changes
- [ ] **Risk**: No
- [ ] **Independence**: No

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 75
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Design was accurate. Guard placed exactly as designed; one-liner format confirmed correct
by testing via subshell sourcing.

## Lessons Learned
`git rev-parse HEAD` is the idiomatic "has at least one commit" check in bash — fast,
exits non-zero cleanly, consistent with existing patterns in the script.
