# Build Stale Status Detector Stop Hook - Implementation Plan
**Task**: 104 (feature)

## Task Reference
- **Task ID**: internal-104
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/104-build-stale-status-detector-stop-hook
- **Template Version**: 2.1

## Goal
Create the hook script and register it in settings.

## Files to Create
- `.cwf/scripts/hooks/stop-stale-status-detector` — the hook shell script

## Files to Modify
- `.claude/settings.local.json` — add `hooks.Stop` entry pointing to the script

## Implementation Steps

### Step 1: Create hooks directory and script
- [ ] Create `.cwf/scripts/hooks/` directory
- [ ] Write `stop-stale-status-detector` per c-design-plan Data Flow
  - `set -u` only (no `set -e`, no `pipefail`)
  - `git diff HEAD --name-only -- 'implementation-guide/*/[a-j]-*.md'` (pathspec, no separate grep)
  - For each file: grep for `**Status**:.*Backlog`
  - Cap at 3 stale files reported
  - Always exit 0
- [ ] `chmod u+rx`

### Step 2: Register hook in settings
- [ ] Add `hooks.Stop` to `.claude/settings.local.json` — merge with existing content
- [ ] Command: `.cwf/scripts/hooks/stop-stale-status-detector`

### Step 3: Validate
- [ ] `jq -e . .claude/settings.local.json` (valid JSON)
- [ ] Pipe-test: `echo '{}' | .cwf/scripts/hooks/stop-stale-status-detector` (no output on clean state)
- [ ] `cwf-manage validate`

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 104
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
