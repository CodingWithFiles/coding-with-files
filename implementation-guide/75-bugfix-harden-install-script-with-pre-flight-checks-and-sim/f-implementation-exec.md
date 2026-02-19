# Harden Install Script with Pre-Flight Checks and Simplify Bootstrap - Implementation Execution
**Task**: 75 (bugfix)

## Task Reference
- **Task ID**: internal-75
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/75-harden-install-script-preflight-checks
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md.

## Execution Checklist
- [x] Read d-implementation-plan.md thoroughly
- [x] Verify all prerequisites met
- [x] Execute implementation steps sequentially
- [x] Update "Actual Results" for each step
- [x] Update status to "Finished" when complete

## Implementation Steps

### Step 1: Add initial-commit guard to `install.bash`
- **Planned**: Insert guard block after git-root check, before "existing install" check
- **Actual**: Inserted exactly as planned. Block checks `CWF_METHOD == subtree` then
  `git rev-parse HEAD` and calls `die` with a clear message if no commits found.
- **Deviations**: None

### Step 2: Update README.md bootstrap block
- **Planned**: Replace 4-line sparse-checkout block with two one-liner blocks (GitHub / non-GitHub)
- **Actual**: Applied as planned. Heading changed from "Quick Install (Any Git Host)"
  to "Quick Install"; two sub-blocks added with GitHub curl and `git archive --remote`
  for other hosts.
- **Deviations**: None

### Step 3: Update INSTALL.md bootstrap block
- **Planned**: Replace sparse-checkout section; relabel GitHub section
- **Actual**: Applied as planned. Removed "Any Git Host (Sparse Checkout)" section and
  its 4-line block; renamed "GitHub (curl one-liner)" to "GitHub"; added new
  "GitLab, Gitea, Forgejo, self-hosted" section with `git archive --remote` one-liner.
- **Deviations**: None

### Step 4: Update security hash
- **Planned**: Update SHA256 in `.cwf/security/script-hashes.json`
- **Actual**: `install.bash` is in `scripts/` (not `.cwf/scripts/`) and is not tracked
  in `script-hashes.json`. No hash update needed.
- **Deviations**: Plan step not needed — `cwf-manage validate` confirms no tracked
  files were affected; passes clean.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed (step 4 N/A — script not tracked)
- [x] All success criteria from a-task-plan.md met
- [x] Design guidance in c-design-plan.md followed
- [x] No planned work deferred

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec 75
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Three edits applied: guard clause in `install.bash`, one-liner bootstrap in README.md,
one-liner bootstrap in INSTALL.md. `install.bash` is not hash-tracked; `cwf-manage validate`
passes.

## Lessons Learned
Check hash-tracking status before writing hash-update steps into the plan. The
distinction between `scripts/` (untracked) and `.cwf/scripts/` (tracked) is
intentional and should be verified, not assumed.
