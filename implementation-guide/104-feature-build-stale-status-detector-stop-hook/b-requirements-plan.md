# Build Stale Status Detector Stop Hook - Requirements
**Task**: 104 (feature)

## Task Reference
- **Task ID**: internal-104
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/104-build-stale-status-detector-stop-hook
- **Template Version**: 2.1

## Goal
Define what the stale status detector must do, how it must perform, and how we verify it works.

## Functional Requirements

- **FR1**: Detect modified wf files — find wf files changed since last commit, filtered to `implementation-guide/*/[a-j]-*.md`
- **FR2**: Detect staleness — for each changed wf file, extract `**Status**:` value and warn if it is "Backlog"
- **FR3**: Emit structured warning — output valid JSON with `systemMessage` containing one warning line per stale file, capped at 3 files (with "+ N more" if more exist)
- **FR4**: Silent on clean state — produce no output when no stale status detected, consuming zero tokens

## Non-Functional Requirements

- **NFR1**: Token budget — ~20 tokens per stale file, capped at 3 reported (~60 tokens max); 0 tokens when clean
- **NFR2**: Robustness — script must exit 0 on all code paths (non-zero causes error display). No `set -e` — handle errors explicitly
- **NFR3**: No side effects — read-only (no file writes, no git operations beyond diff)

## Constraints
- Stop hooks fire on every stop including `/clear`, resume, compact — not just task completion
- Hook stdout goes into system reminders — tokens consumed on every subsequent turn
- Must not duplicate `cwf-manage validate` (structural integrity) or `cwf-status` (progress tracking)
- Script must work from the git root directory (hooks run from project root)

## Acceptance Criteria
- [ ] AC1: Script detects stale "Backlog" status on modified wf files
- [ ] AC2: Script produces no output when no stale status detected
- [ ] AC3: Script exits 0 in all cases
- [ ] AC4: Hook registered in settings.local.json and fires on Stop events

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 104
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
