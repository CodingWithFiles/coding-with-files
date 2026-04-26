# Build uncommitted changes warning Stop hook - Rollout
**Task**: 113 (feature)

## Task Reference
- **Task ID**: internal-113
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/113-build-uncommitted-changes-warning-stop-hook
- **Template Version**: 2.1

## Deployment Strategy

**Strategy**: Immediate — single-developer internal tool, no phased rollout needed. Mirrors Task 104's rollout pattern.

**Deployment**:
- Script (`.cwf/scripts/hooks/stop-uncommitted-changes-warning`) is committed to the repo and deployed via merge to main
- Hook registration (`.claude/settings.local.json`) is developer-local and already active in the current session
- Conventions doc (`docs/conventions/perl-git-paths.md`) is already committed and informs future hook authors

**Rollback**: Remove the second command object from `hooks.Stop[0].hooks` in `.claude/settings.local.json` (the entry pointing at `stop-uncommitted-changes-warning`). The script remains in the repo but is inert without the hook registration. Task 104's hook is unaffected.

## Pre-Deployment Checklist
- [x] 13/14 tests passing (TC-8 conflict-state deferred — backlog item added)
- [x] `cwf-manage validate` clean
- [x] Script permissions verified (mode 0500)
- [x] Hook fires correctly across all four primary porcelain classes (untracked, unstaged, staged-modify, staged-add)
- [x] Both Stop hooks (104 + 113) coexist and emit distinct, non-conflicting warnings (TC-11)
- [x] Conventions doc updated with `use utf8;` gotcha learned during exec
- [x] BACKLOG.md follow-up item added for deferred conflict test

## Monitoring
- The hook's `systemMessage` output appears as a system reminder on the next turn after each Stop event — any false positives, misfires, or mojibake will be immediately visible during normal CWF use
- The hook is *already* firing live in this session against the task's own untracked wf files; output has been observed correct on every checkpoint commit since the implementation phase
- No separate monitoring infrastructure needed

## Status
**Status**: Finished
**Next Action**: /cwf-maintenance 113
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**
