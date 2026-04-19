# Build Stale Status Detector Stop Hook - Plan
**Task**: 104 (feature)

## Task Reference
- **Task ID**: internal-104
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/104-build-stale-status-detector-stop-hook
- **Template Version**: 2.1

## Goal
Build a Stop event hook shell script that detects wf files modified during the session whose `**Status**:` field is still "Backlog", and emits a one-line warning per stale file as a system reminder.

## Success Criteria
- [ ] SC1: Shell script exists at `.cwf/scripts/hooks/stop-stale-status-detector` and exits cleanly
- [ ] SC2: Hook outputs valid JSON with `systemMessage` containing warnings when stale status detected
- [ ] SC3: Hook produces no output when no stale status detected (zero tokens on clean stops)
- [ ] SC4: Hook registered in `.claude/settings.local.json` under `hooks.Stop`
- [ ] SC5: Total output stays within ~40-60 tokens when warnings present

## Original Estimate
**Effort**: 1 session
**Complexity**: Low
**Dependencies**: Task 103 (framework document — completed)

## Major Milestones
1. **Script**: Shell script that detects stale status fields via `git diff` + grep
2. **Hook registration**: Stop hook configured in settings.local.json
3. **Verification**: Hook fires on stop and produces correct output

## Risk Assessment
### Medium Priority Risks
- **Risk 1**: Stop hooks fire on `/clear`, resume, compact — not just task completion. Script must handle cases where there's no active task or no implementation-guide changes.
  - **Mitigation**: Exit cleanly with no output when `git diff --name-only` returns nothing relevant
- **Risk 2**: `git diff` without a base ref may not capture all session changes (only unstaged vs HEAD)
  - **Mitigation**: Design phase should determine the right git diff invocation (HEAD, staged, working tree)

## Dependencies
- Task 103 framework document (`.cwf/docs/workflow/stop-hooks-framework.md`) — completed
- Claude Code Stop hook mechanics (stdin JSON, stdout JSON, systemMessage field)

## Constraints
- Output goes into system reminders — tokens consumed on every subsequent turn until compaction
- Must not duplicate `cwf-manage validate` (structural integrity) or `cwf-status` (progress tracking)
- Target ~40-60 tokens when warnings present; 0 tokens when clean

## Decomposition Check
- [x] **Time**: No — 1 session estimate
- [x] **People**: No — single developer
- [x] **Complexity**: No — 2 concerns (script + hook config), below threshold of 3
- [x] **Risk**: No — low risk, easily reversible (remove hook entry)
- [x] **Independence**: No — script and config are tightly coupled

**Result**: 0/5 signals triggered. No decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan 104
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
