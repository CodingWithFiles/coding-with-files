# Build uncommitted changes warning Stop hook - Requirements
**Task**: 113 (feature)

## Task Reference
- **Task ID**: internal-113
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/113-build-uncommitted-changes-warning-stop-hook
- **Template Version**: 2.1

## Goal
Define what the uncommitted-changes warning hook must do, how it must perform, and how we verify it works.

## Functional Requirements

- **FR1**: Detect dirty wf file entries — run `git status --porcelain` filtered to `implementation-guide/*/[a-j]-*.md` and collect every entry, including staged, unstaged, untracked (`??`), and conflict states (`UU`, `AA`, `DD`, etc.). Throughout this document "uncommitted" is used inclusively to mean any of these states.
- **FR2**: Emit structured warning — output valid JSON with `systemMessage` listing the uncommitted wf file basenames, capped at 3 files (with "+ N more" if more exist)
- **FR3**: Distinguish state in message — the warning text must begin with an unambiguous "Uncommitted:" label so the user can distinguish this hook's output from the Task 104 stale-status detector's output on the same Stop event
- **FR4**: Silent on clean state — produce no output (no JSON, no stdout) when no dirty wf files detected, consuming zero tokens. Mirrors Task 104's pattern.
- **FR5**: Coexist with Task 104 hook — both hooks must be able to fire on the same Stop event without interfering; a wf file that is both uncommitted AND has stale status is allowed to appear in both warnings (the two conditions are legitimately distinct)

## Non-Functional Requirements

- **NFR1**: Token budget — ~20-30 tokens when warnings present (cap at 3 reported files); 0 tokens when clean. Lower than Task 104's ~60-token budget because this hook reports basenames only, no per-file status values.
- **NFR2**: Robustness — script must exit 0 on all code paths (non-zero causes error display to user). Wrap logic in `eval` (Perl) or equivalent; no `set -e` shortcut behaviour
- **NFR3**: No side effects — read-only (no file writes, no git state changes, no index mutation)
- **NFR4**: Performance — complete within the 5-second hook timeout (matching Task 104's `timeout: 5` setting); `git status --porcelain` on this repo is sub-100ms so ample headroom
- **NFR5**: Consistency — follow Task 104 script conventions (location under `.cwf/scripts/hooks/`, Perl with `use strict; use warnings`, exit-0 discipline via `eval`, executable permission 0500)

## Constraints
- Stop hooks fire on every stop including `/clear`, resume, compact, natural pauses — not just task completion
- Hook stdout goes into system reminders — tokens consumed on every subsequent turn until compaction
- Must not duplicate `cwf-manage validate` (structural integrity), `cwf-status` (progress tracking), or the Task 104 stale-status detector (different failure mode: committed-but-stale vs uncommitted)
- Script must work from the git root directory (hooks run from project root)
- Untracked wf files created by `/cwf-new-task` within the same session will be flagged — this is the intended behaviour: they are legitimately uncommitted and the user should be aware when the agent stops
- During merge/rebase with conflicts, the hook reports conflict-state wf files (`UU`, `AA`, `DD`) as uncommitted. This is intended: those files are in an inconsistent state and the user should see them

## Acceptance Criteria
- [ ] AC1: Script detects dirty entries of every porcelain class — staged (first column M/A/D/R/C), unstaged (second column M/D), untracked (`??`), and conflict (`UU`/`AA`/`DD`/etc.) — under `implementation-guide/*/[a-j]-*.md`
- [ ] AC2: Warning message begins with "Uncommitted:" (FR3 label) so it is visually distinguishable from the stale-status detector's output
- [ ] AC3: Script produces no output (no stdout at all) when no uncommitted wf files are present
- [ ] AC4: Script exits 0 in all cases, including: non-git cwd, missing git binary, permissions errors, merge/rebase conflict states
- [ ] AC5: Hook registered in `.claude/settings.local.json` as an additional command object within the existing `hooks.Stop[0].hooks` array (alongside `.cwf/scripts/hooks/stop-stale-status-detector`), with `timeout: 5`
- [ ] AC6: Both Stop hooks fire successfully on the same event without either blocking the other (verified end-to-end by creating an uncommitted, Backlog-status wf file and observing both warnings)

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 113
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
